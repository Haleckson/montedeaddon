--[[
  Forever Companion - Guild/Sync.lua
  Guild discovery protocol on top of Comm.

    H  HELLO     {v, p, n, s, h, reply}   version + watermarks, guild/group or whisper reply
    N  RECORD    {rec}                    new or updated discovery (live)
    R  REQUEST   {s} or {ids}             whisper: send me what changed since s
    B  BATCH     {recs, last}             whisper: response to a request
    V  VERIFY    {id, t}                  sender confirms a discovery
    G  NOTE      {id, t, x}               guild note on a discovery
    O  OBSERVE   {id, k, t}               rare seen alive (s) or dead (d)
    D  RETRACT   {rec}                    author tombstone
    U  SETADD    {id, f, v}               adds a drop or a gathering point to a shared record
    Q  LORE      {f, n, t, p, i}          quest knowledge facts (see Data/QuestLore.lua), live and in catch-up
    P  PING      {t, pong}                diagnostics (/fc sync)

  Delta sync: every client remembers when it was last online. HELLO carries
  that watermark (s) and the newest change it holds (h). A client with newer
  data answers with a whispered HELLO; the joining client picks one responder
  and whispers one REQUEST. The whole database is never broadcast.
]]

local _, FC = ...

local Sync = FC:NewModule("Sync")

local U = FC.Utils
local C = FC.C
local S = C.SYNC
local Comm = FC.Comm
local Compat = FC.Compat
local PRIORITY = Comm.PRIORITY

Sync.peers = {}
Sync.helloReplies = {}
Sync.lastRequestFrom = {}
Sync.lastReplyTo = {}

------------------------------------------------------------------------
-- Settings helpers
------------------------------------------------------------------------

function Sync:Enabled()
    local P = FC.P
    return P.sync.enabled and P.sync.channel ~= "NONE" and Comm:IsAvailable()
end

function Sync:Channel()
    local channel = FC.P.sync.channel
    if channel == "GUILD" then
        return Compat.IsInGuild() and "GUILD" or nil
    elseif channel == "RAID" then
        if Compat.IsInRaid() then return "RAID" end
        if Compat.IsInGroup() then return "PARTY" end
    elseif channel == "PARTY" then
        return Compat.IsInGroup() and "PARTY" or nil
    end
    return nil
end

--- Whether a record may leave this client, and the copy to send.
function Sync:Shareable(rec)
    if not rec or rec.v ~= "g" or rec.dev then return nil end
    local P = FC.P
    if (rec.t == "quest" or rec.t == "questchain") and not P.sync.shareQuests then return nil end
    if rec.t == "note" and not P.sync.shareNotes then return nil end
    if rec.t == "creature" and not P.sync.shareCreatures then return nil end
    if rec.t == "profession" and rec.pts and not P.sync.shareGathering then return nil end
    local copy = U.CopyTable(rec)
    if not P.sync.shareCoords then
        copy.x, copy.y = nil, nil
    end
    return copy
end

local function send(kind, payload, priority, dedupeKey)
    if not Sync:Enabled() then return false end
    local channel = Sync:Channel()
    if not channel then return false end
    return Comm:Send(kind, payload, channel, nil, priority, dedupeKey)
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function Sync:OnEnable()
    Comm:RegisterHandler("H", function(...) self:OnHello(...) end)
    Comm:RegisterHandler("N", function(...) self:OnRecord(...) end)
    Comm:RegisterHandler("R", function(...) self:OnRequest(...) end)
    Comm:RegisterHandler("B", function(...) self:OnBatch(...) end)
    Comm:RegisterHandler("V", function(...) self:OnVerify(...) end)
    Comm:RegisterHandler("G", function(...) self:OnNote(...) end)
    Comm:RegisterHandler("O", function(...) self:OnObservation(...) end)
    Comm:RegisterHandler("D", function(...) self:OnRetract(...) end)
    Comm:RegisterHandler("P", function(...) self:OnPing(...) end)
    Comm:RegisterHandler("U", function(...) self:OnSetAdd(...) end)
    Comm:RegisterHandler("Q", function(...) self:OnLore(...) end)

    -- your own characters are not peers (their echoed messages used to be
    -- taken for another player's on Forever)
    for name in pairs(FC.db.sync.peers) do
        if type(name) ~= "string" or FC.db.myChars[U.CharacterKey(name)] then FC.db.sync.peers[name] = nil end
    end

    local Bus = FC.Bus
    Bus:On("DISCOVERY_ADDED", self, function(_, rec, source) self:OnLocalChange(rec, source, true) end)
    Bus:On("DISCOVERY_UPDATED", self, function(_, rec, source) self:OnLocalChange(rec, source, false) end)
    Bus:On("DISCOVERY_VERIFIED", self, function(_, rec, name, source)
        if source == "local" and name == FC.Store.me and self:Shareable(rec) then
            send("V", { id = rec.id, t = rec.ver and rec.ver[name] or U.Now() }, PRIORITY.NORMAL)
        end
    end)
    Bus:On("DISCOVERY_NOTE", self, function(_, rec, note, source)
        if source == "local" and self:Shareable(rec) then
            send("G", { id = rec.id, t = note.t, x = note.x }, PRIORITY.NORMAL)
        end
    end)
    Bus:On("DISCOVERY_OBSERVATION", self, function(_, rec, kind, ts, source)
        if source == "local" and self:Shareable(rec) then
            send("O", { id = rec.id, k = kind, t = ts }, PRIORITY.BULK)
        end
    end)
    Bus:On("DISCOVERY_SETADD", self, function(_, rec, field, value, source)
        if source == "local" and self:Shareable(rec) then
            send("U", { id = rec.id, f = field, v = value }, PRIORITY.BULK)
        end
    end)
    Bus:On("DISCOVERY_RETRACTED", self, function(_, tombstone)
        if tombstone.v == "g" then send("D", { rec = tombstone }, PRIORITY.NORMAL) end
    end)
    Bus:On("QUEST_LORE_LEARNED", self, function()
        U.Debounce("sync-lore", S.LORE_DELAY, function() FC:SafeCall("Sync:FlushLore", self.FlushLore, self) end)
    end)

    self.helloTimer = C_Timer.NewTimer(S.HELLO_DELAY + math.random(0, 5), function()
        FC:SafeCall("Sync:Hello", self.SendHello, self)
    end)
    FC.Events:Register("GROUP_JOINED", self, function()
        if FC.P.sync.channel ~= "GUILD" then U.Debounce("sync-group-hello", 5, function() self:SendHello() end) end
    end)
    self.onlineTicker = C_Timer.NewTicker(60, function() self:TouchOnline() end)
end

function Sync:OnLogout()
    self:TouchOnline()
end

function Sync:TouchOnline()
    FC.db.sync.lastOnline = U.Now()
end

------------------------------------------------------------------------
-- Outgoing
------------------------------------------------------------------------

-- Only new records and new revisions travel as full records; verifications,
-- notes and observations have their own small messages.
Sync.sentRevision = {}

function Sync:OnLocalChange(rec, source, isNew)
    if source ~= "local" and source ~= "auto" then return end
    if not FC.Store:IsMine(rec) then return end
    if not FC.P.sync.autoShare and source == "auto" then return end
    if not isNew and self.sentRevision[rec.id] == rec.r then return end
    local copy = self:Shareable(rec)
    if copy and send("N", { rec = copy }, PRIORITY.NORMAL, "N:" .. rec.id) then
        self.sentRevision[rec.id] = rec.r
    end
end

--- Manual share from the journal: makes the record shared and sends it.
function Sync:ShareNow(id)
    local rec = FC.Store:Get(id)
    if not rec then return false end
    if FC.Store:IsMine(rec) and rec.v ~= "g" then
        return FC.Store:MakeShared(id) -- the update event sends it
    end
    local copy = self:Shareable(rec)
    if not copy then return false end
    return send("N", { rec = copy }, PRIORITY.NORMAL, "N:" .. id)
end

local function newestShared()
    local newest, count = 0, 0
    for _, rec in pairs(FC.Store.records) do
        if rec.v == "g" then
            if not rec.del then count = count + 1 end
            -- a retraction is a change too: peers must ask for it
            if rec.u > newest then newest = rec.u end
        end
    end
    -- quest knowledge counts as something newer to catch up on
    if Sync:SharesLore() then newest = math.max(newest, FC.QuestLore:Newest()) end
    return newest, count
end

function Sync:SharesLore()
    return FC.P.sync.shareQuestKnowledge
end

--- Sends the quest knowledge learned in the last few seconds.
function Sync:FlushLore()
    local facts = FC.QuestLore:TakeOutbox()
    if #facts == 0 or not self:Enabled() or not self:SharesLore() then return end
    for i = 1, #facts, S.LORE_BATCH do
        local chunk = {}
        for j = i, math.min(i + S.LORE_BATCH - 1, #facts) do chunk[#chunk + 1] = facts[j] end
        send("Q", FC.QuestLore:Pack(chunk), PRIORITY.BULK)
    end
end

function Sync:SendHello(target)
    if not self:Enabled() then return end
    local newest, count = newestShared()
    local payload = {
        v = FC.version,
        p = C.PROTOCOL,
        n = count,
        s = FC.db.sync.lastOnline or 0,
        h = newest,
        reply = target and true or nil,
    }
    if target then
        Comm:Send("H", payload, "WHISPER", target, PRIORITY.CONTROL)
    else
        wipe(self.helloReplies)
        self.helloSentAt = U.Now()
        send("H", payload, PRIORITY.CONTROL, "H")
        C_Timer.After(S.REQUEST_WINDOW, function() FC:SafeCall("Sync:ChooseProvider", self.ChooseProvider, self) end)
    end
end

--- After our HELLO, pick the responder with the newest data and ask it once.
function Sync:ChooseProvider()
    local since = math.max(0, (FC.db.sync.lastOnline or 0) - S.SINCE_MARGIN)
    local best
    for sender, info in pairs(self.helloReplies) do
        if info.h > since and (not best or info.h > best.h) then
            best = { sender = sender, h = info.h }
        end
    end
    if best then
        FC.Log:Debug("Requesting delta since %d from %s", since, best.sender)
        Comm:Send("R", { s = since }, "WHISPER", best.sender, PRIORITY.CONTROL)
        FC.Bus:Emit("SYNC_STATE", "requesting", best.sender)
    else
        FC.Bus:Emit("SYNC_STATE", "idle")
    end
end

------------------------------------------------------------------------
-- Incoming
------------------------------------------------------------------------

local function allowedChannel(channel)
    return channel == "GUILD" or channel == "PARTY" or channel == "RAID" or channel == "WHISPER" or channel == "INSTANCE_CHAT"
end

function Sync:NotePeer(sender, payload)
    local peer = FC.db.sync.peers[sender] or {}
    peer.v = type(payload.v) == "string" and payload.v:sub(1, 24) or peer.v
    peer.seen = U.Now()
    FC.db.sync.peers[sender] = peer
    self.peers[sender] = peer
    if FC.P.sync.notifyVersion and type(payload.v) == "string" and not self.versionNotified and self:IsNewerVersion(payload.v, FC.version) then
        self.versionNotified = true
        FC:Print(FC.L.MSG_NEWER_VERSION, payload.v:sub(1, 24))
    end
end

local function parseVersion(v)
    local a, b, c = tostring(v):match("^(%d+)%.(%d+)%.(%d+)")
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

function Sync:IsNewerVersion(theirs, mine)
    local a1, b1, c1 = parseVersion(theirs)
    local a2, b2, c2 = parseVersion(mine)
    if a1 ~= a2 then return a1 > a2 end
    if b1 ~= b2 then return b1 > b2 end
    return c1 > c2
end

function Sync:OnHello(_, payload, sender, channel)
    if not self:Enabled() or not allowedChannel(channel) then return end
    self:NotePeer(sender, payload)
    local theirSince = tonumber(payload.s) or 0
    local theirNewest = tonumber(payload.h) or 0
    if payload.reply then
        self.helloReplies[sender] = { h = theirNewest }
        return
    end
    -- someone came online: if I hold data newer than their watermark, tell them
    local myNewest = newestShared()
    local now = U.Now()
    if myNewest > theirSince and (not self.lastReplyTo[sender] or now - self.lastReplyTo[sender] > S.PEER_REPLY_COOLDOWN) then
        self.lastReplyTo[sender] = now
        C_Timer.After(math.random(1, 4), function() FC:SafeCall("Sync:HelloReply", self.SendHello, self, sender) end)
    end
    -- and if they hold data newer than mine, remember them as a provider
    if self.helloSentAt and now - self.helloSentAt < S.REQUEST_WINDOW then
        self.helloReplies[sender] = { h = theirNewest }
    end
end

function Sync:OnRecord(_, payload, sender, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.rec) ~= "table" then return end
    local rec, result = FC.Store:Upsert(payload.rec, "sync")
    if rec and result == "added" then
        FC.Bus:Emit("GUILD_DISCOVERY", rec, sender)
    end
end

function Sync:OnRequest(_, payload, sender, channel)
    if not self:Enabled() or channel ~= "WHISPER" then return end
    local now = U.Now()
    if self.lastRequestFrom[sender] and now - self.lastRequestFrom[sender] < S.REQUEST_COOLDOWN then return end
    self.lastRequestFrom[sender] = now

    local list, since = {}, nil
    if type(payload.ids) == "table" then
        for i = 1, math.min(#payload.ids, 20) do
            local id = payload.ids[i]
            local rec = type(id) == "string" and FC.Store:GetRaw(id)
            local copy = rec and (rec.del and rec or self:Shareable(rec))
            if copy then list[#list + 1] = copy end
        end
    else
        since = tonumber(payload.s) or 0
        for _, rec in pairs(FC.Store.records) do
            if rec.u > since and rec.v == "g" then
                local copy = rec.del and rec or self:Shareable(rec)
                if copy then list[#list + 1] = copy end
            end
        end
        table.sort(list, function(a, b) return a.u < b.u end)
        for i = #list, S.RESPONSE_CAP + 1, -1 do list[i] = nil end
    end
    if #list > 0 then
        FC.Log:Debug("Sending %d records to %s", #list, sender)
        for i = 1, #list, S.BATCH_SIZE do
            local batch = {}
            for j = i, math.min(i + S.BATCH_SIZE - 1, #list) do batch[#batch + 1] = list[j] end
            Comm:Send("B", { recs = batch, last = (i + S.BATCH_SIZE > #list) or nil }, "WHISPER", sender, PRIORITY.BULK)
        end
    end
    -- and the quest knowledge that changed in the same time
    if since and self:SharesLore() then
        local facts = FC.QuestLore:FactsSince(since, S.LORE_CAP)
        for i = 1, #facts, S.LORE_BATCH do
            local chunk = {}
            for j = i, math.min(i + S.LORE_BATCH - 1, #facts) do chunk[#chunk + 1] = facts[j] end
            Comm:Send("Q", FC.QuestLore:Pack(chunk), "WHISPER", sender, PRIORITY.BULK)
        end
    end
end

function Sync:OnBatch(_, payload, sender, channel)
    if not self:Enabled() or channel ~= "WHISPER" or type(payload.recs) ~= "table" then return end
    self.batchAdded = self.batchAdded or 0
    for i = 1, math.min(#payload.recs, 20) do
        local _, result = FC.Store:Upsert(payload.recs[i], "sync")
        if result == "added" then self.batchAdded = self.batchAdded + 1 end
    end
    if payload.last then
        if self.batchAdded > 0 then
            FC.Bus:Emit("SYNC_COMPLETE", self.batchAdded, sender)
        end
        self.batchAdded = 0
        self:TouchOnline()
        FC.Bus:Emit("SYNC_STATE", "idle")
    end
end

function Sync:OnLore(_, payload, _, channel)
    if not self:Enabled() or not self:SharesLore() or not allowedChannel(channel) or type(payload) ~= "table" then return end
    FC.QuestLore:ApplyFacts(payload)
end

-- Verifications and guild notes are filed under the sender's journal key,
-- the same form as a discovery's author, so one player is one name.
function Sync:OnVerify(_, payload, sender, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.id) ~= "string" then return end
    FC.Store:AddVerification(payload.id, U.CharacterKey(sender), tonumber(payload.t), "sync")
end

function Sync:OnNote(_, payload, sender, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.id) ~= "string" then return end
    FC.Store:AddGuildNote(payload.id, U.CharacterKey(sender), payload.x, tonumber(payload.t), "sync")
end

function Sync:OnObservation(_, payload, _, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.id) ~= "string" then return end
    FC.Store:AddObservation(payload.id, payload.k, tonumber(payload.t), "sync")
end

function Sync:OnSetAdd(_, payload, _, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.id) ~= "string" then return end
    if payload.f ~= "dr" and payload.f ~= "pts" then return end
    local value = tonumber(payload.v)
    if not value or value < 0 or value > 2147483647 or value ~= math.floor(value) then return end
    FC.Store:AddToSet(payload.id, payload.f, value, "sync")
end

function Sync:OnRetract(_, payload, sender, channel)
    if not self:Enabled() or not allowedChannel(channel) or type(payload.rec) ~= "table" then return end
    if not U.SameCharacter(payload.rec.a, sender) then return end -- only the author can retract
    FC.Store:Upsert(payload.rec, "sync")
end

--- Asks the guild for specific discoveries (e.g. a clicked chat link).
function Sync:RequestIds(ids, target)
    if not self:Enabled() then return false end
    if target then
        return Comm:Send("R", { ids = ids }, "WHISPER", target, PRIORITY.CONTROL)
    end
    return false
end

------------------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------------------

function Sync:Ping()
    if not self:Enabled() then return false end
    self.pingSentAt = GetTime()
    self.pongs = {}
    return send("P", { t = U.Now() }, PRIORITY.CONTROL)
end

function Sync:OnPing(_, payload, sender, channel)
    if payload.pong then
        if self.pongs then
            self.pongs[#self.pongs + 1] = { sender = sender, ms = math.floor((GetTime() - (self.pingSentAt or GetTime())) * 1000) }
        end
        return
    end
    if not self:Enabled() or not allowedChannel(channel) then return end
    Comm:Send("P", { pong = true, v = FC.version }, "WHISPER", sender, PRIORITY.CONTROL)
end

function Sync:Status()
    local online = 0
    local now = U.Now()
    for _, peer in pairs(self.peers) do
        if now - (peer.seen or 0) < 3600 then online = online + 1 end
    end
    return {
        enabled = self:Enabled(),
        channel = self:Channel(),
        peers = online,
        queue = Comm:QueueLength(),
        stats = Comm.stats,
        lastOnline = FC.db.sync.lastOnline,
    }
end

--- Manual resync (/fc sync): announce and request from the best peer.
function Sync:Resync()
    if not self:Enabled() then return false end
    self:SendHello()
    return true
end
