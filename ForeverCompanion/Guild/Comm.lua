--[[
  Forever Companion - Guild/Comm.lua
  Transport layer for addon messages: framing, chunking, throttling, queues,
  reassembly and incoming rate limits. Knows nothing about discoveries.

  Wire frame (<= 255 bytes):
      <protocol digit><kind letter><msgId base36>:<seq>/<total>:<data>
  <data> is a slice of the serialized payload. Receivers reassemble slices per
  (sender, msgId), drop sets that stay incomplete, and deserialize with limits.

  Sending uses a token bucket (burst + refill) and three priority queues, so
  the addon never produces bursts that trip the client's throttle. When the
  client reports messaging lockdown (restricted content), the queue waits.
]]

local _, FC = ...

local Comm = FC:NewModule("Comm")

local U = FC.Utils
local C = FC.C
local Compat = FC.Compat
local S = C.SYNC

local PRIORITY = { CONTROL = 1, NORMAL = 2, BULK = 3 }
Comm.PRIORITY = PRIORITY

Comm.handlers = {}
Comm.queues = { {}, {}, {} }
Comm.tokens = S.BURST
Comm.partials = {}
Comm.partialCount = 0
Comm.senderWindow = {}
Comm.stats = { sent = 0, received = 0, dropped = 0, bytesOut = 0, bytesIn = 0 }
Comm.nextId = 0

function Comm:OnEnable()
    self.me = U.PlayerFullName()
    self.prefixRegistered = Compat.RegisterAddonPrefix(C.COMM_PREFIX)
    if not self.prefixRegistered then
        FC.Log:Warn("Could not register addon message prefix; guild sync is disabled this session.")
    end
    FC.Events:Register("CHAT_MSG_ADDON", self, self.OnAddonMessage)
    self.lastRefill = GetTime()
end

--- handler(kind, payload, sender, channel)
function Comm:RegisterHandler(kind, handler)
    self.handlers[kind] = handler
end

function Comm:IsAvailable()
    return self.prefixRegistered == true
end

------------------------------------------------------------------------
-- Sending
------------------------------------------------------------------------

local function newMessageId(self)
    self.nextId = (self.nextId + 1) % 46656 -- 3 base36 digits
    return U.ToBase36(self.nextId)
end

--- Queues a payload. channel: "GUILD" | "PARTY" | "RAID" | "WHISPER".
--- dedupeKey (optional) replaces an unsent message with the same key.
function Comm:Send(kind, payload, channel, target, priority, dedupeKey)
    if not self:IsAvailable() then return false end
    if channel == "GUILD" and not Compat.IsInGuild() then return false end
    if (channel == "PARTY" and not Compat.IsInGroup()) or (channel == "RAID" and not Compat.IsInRaid()) then return false end
    local data, err = FC.Serializer:Serialize(payload)
    if not data then
        FC.Log:Error("Cannot encode %s message: %s", kind, tostring(err))
        return false
    end
    local msgId = newMessageId(self)
    local total = math.max(1, math.ceil(#data / S.CHUNK_DATA))
    if total > 999 then
        FC.Log:Warn("Message %s too large (%d bytes), not sent", kind, #data)
        return false
    end
    local frames = {}
    for seq = 1, total do
        local slice = data:sub((seq - 1) * S.CHUNK_DATA + 1, seq * S.CHUNK_DATA)
        frames[seq] = C.PROTOCOL .. kind .. msgId .. ":" .. seq .. "/" .. total .. ":" .. slice
    end
    local queue = self.queues[priority or PRIORITY.NORMAL]
    if dedupeKey then
        for i = #queue, 1, -1 do
            if queue[i].dedupeKey == dedupeKey and queue[i].sent == 0 then
                table.remove(queue, i)
            end
        end
    end
    queue[#queue + 1] = { frames = frames, channel = channel, target = target, sent = 0, dedupeKey = dedupeKey, kind = kind }
    self:StartPump()
    return true
end

function Comm:QueueLength()
    local n = 0
    for _, queue in ipairs(self.queues) do
        for _, item in ipairs(queue) do n = n + (#item.frames - item.sent) end
    end
    return n
end

function Comm:StartPump()
    if self.pump then return end
    self.pump = C_Timer.NewTicker(0.2, function() FC:SafeCall("Comm:Pump", self.Pump, self) end)
end

function Comm:StopPump()
    if self.pump then
        self.pump:Cancel()
        self.pump = nil
    end
end

function Comm:Refill()
    local now = GetTime()
    local elapsed = now - (self.lastRefill or now)
    if elapsed > 0 then
        self.tokens = math.min(S.BURST, self.tokens + elapsed / S.REFILL)
        self.lastRefill = now
    end
end

function Comm:Pump()
    self:Refill()
    if Compat.InMessagingLockdown() then return end
    while self.tokens >= 1 do
        local item, queue
        for _, q in ipairs(self.queues) do
            if q[1] then
                item, queue = q[1], q
                break
            end
        end
        if not item then
            self:StopPump()
            return
        end
        local frame = item.frames[item.sent + 1]
        local ok, reason = Compat.SendAddonMessage(C.COMM_PREFIX, frame, item.channel, item.target)
        if not ok then
            if reason == "throttle" then
                self.tokens = 0
                return
            end
            FC.Log:Debug("Addon message dropped (%s): %s", item.kind, tostring(reason))
            table.remove(queue, 1)
            self.stats.dropped = self.stats.dropped + 1
        else
            self.tokens = self.tokens - 1
            item.sent = item.sent + 1
            self.stats.sent = self.stats.sent + 1
            self.stats.bytesOut = self.stats.bytesOut + #frame
            if item.sent >= #item.frames then table.remove(queue, 1) end
        end
    end
end

------------------------------------------------------------------------
-- Receiving
------------------------------------------------------------------------

local function allowSender(self, sender, now)
    local window = self.senderWindow[sender]
    if not window or now - window.start > 10 then
        window = { start = now, count = 0 }
        self.senderWindow[sender] = window
    end
    window.count = window.count + 1
    return window.count <= S.INCOMING_PER_10S
end

local function prunePartials(self, now)
    for key, partial in pairs(self.partials) do
        if now - partial.time > S.PARTIAL_TIMEOUT then
            self.partials[key] = nil
            self.partialCount = self.partialCount - 1
        end
    end
end

function Comm:OnAddonMessage(_, prefix, text, channel, sender)
    prefix, text, channel, sender = Compat.Safe(prefix), Compat.Safe(text), Compat.Safe(channel), Compat.Safe(sender)
    if prefix ~= C.COMM_PREFIX or type(text) ~= "string" or type(sender) ~= "string" then return end
    sender = U.NormalizeSender(sender)
    -- guild and group messages echo back to their sender. On Forever the
    -- echo names you "First Surname-Realm", not by your journal key.
    if not sender or U.SameCharacter(sender, self.me) then return end
    self:Receive(text, channel, sender)
end

--- Entry point for a raw frame (also used by the developer simulator).
function Comm:Receive(text, channel, sender)
    local now = GetTime()
    if not allowSender(self, sender, now) then
        self.stats.dropped = self.stats.dropped + 1
        return
    end
    local version, kind, msgId, seq, total, data = text:match("^(%d)(%u)(%w+):(%d+)/(%d+):(.*)$")
    if not version then return end
    if tonumber(version) ~= C.PROTOCOL then
        FC.Bus:Emit("SYNC_PROTOCOL_MISMATCH", sender, tonumber(version))
        return
    end
    seq, total = tonumber(seq), tonumber(total)
    if not seq or not total or seq < 1 or total < 1 or seq > total or total > 999 then return end
    self.stats.received = self.stats.received + 1
    self.stats.bytesIn = self.stats.bytesIn + #text

    local payloadString
    if total == 1 then
        payloadString = data
    else
        local key = sender .. ":" .. msgId
        local partial = self.partials[key]
        if not partial then
            prunePartials(self, now)
            if self.partialCount >= S.MAX_PARTIALS then return end
            partial = { time = now, total = total, parts = {}, count = 0 }
            self.partials[key] = partial
            self.partialCount = self.partialCount + 1
        end
        if partial.total ~= total then return end
        if not partial.parts[seq] then
            partial.parts[seq] = data
            partial.count = partial.count + 1
        end
        partial.time = now
        if partial.count < total then return end
        payloadString = table.concat(partial.parts, "", 1, total)
        self.partials[key] = nil
        self.partialCount = self.partialCount - 1
    end

    local ok, payload = FC.Serializer:Deserialize(payloadString, { maxString = 4096, maxNodes = 5000 })
    if not ok or type(payload) ~= "table" then
        FC.Log:Debug("Rejected malformed %s message from %s: %s", kind, sender, tostring(payload))
        return
    end
    local handler = self.handlers[kind]
    if handler then
        FC:SafeCall("Comm:" .. kind, handler, kind, payload, sender, channel)
    end
end
