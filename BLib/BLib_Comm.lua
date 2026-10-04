-- BLib_Comm.lua
-- Addon messages for the whole family: one queue, one listener, one format.
--
-- Raidmaster, Chronicle, Officer's Desk and the rest each want to talk to
-- other clients. Each with its own chunking and throttle would be several
-- queues, every one polite and all of them flooding the client together, so
-- there is one queue here, shared by every prefix, and one listener.
--
--   BLib.Comm:Register(prefix, handler)   handler(payload, sender, channel, fromSelf)
--   BLib.Comm:Send(prefix, payload, channel, target)
--       channel "GUILD", "PARTY", "RAID" or "WHISPER" (target "First Surname")
--
-- A payload is a string, number or boolean, or a table of them, nested as you
-- like. It is serialised here without loadstring: a message from another
-- client is data, and nothing in it is ever run.
--
-- MEASURED ON FOREVER. Addon messages work although
-- AreOutgoingAddonChatMessagesRestricted says true (2026-09-18, a GUILD ping
-- came back); the API dump ties that flag to C_Commentator's sends "on
-- tournament realms", so it is never asked here. The one gate is
-- C_ChatInfo.InChatMessagingLockdown(): while it is on, messages wait in the
-- queue. SendAddonMessage answers with a result code, not an error, so each
-- send is read back: a throttle, or a lockdown that began after the check, is
-- tried again, and a refusal that will not change drops the message.
--
-- Nothing registers a prefix or an event, or sends anything, until an addon
-- calls Register or Send: BLib loads with every addon in the family.
--
--   /blib comm test   whisper yourself three payloads and time the echo

BLib = BLib or {}
BLib.Comm = {}
local C = BLib.Comm

-- Blizzard's own tests for secrets. Absent on a client without secrets.
local IsSecret      = issecretvalue or function(_) return false end
local IsSecretTable = issecrettable or function(_) return false end

-- Between first name and surname: " " on Forever, read from build 70009's
-- Constants on 2026-09-25.
local SEPARATOR = Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
if type(SEPARATOR) ~= "string" or SEPARATOR == "" then SEPARATOR = " " end

-- ============================================================
-- LIMITS
-- ============================================================

-- The first byte of every message. A version this client does not know is
-- dropped rather than guessed at.
local PROTOCOL = "1"

-- SendAddonMessage carries 255 bytes of text. The header takes up to 13, and
-- pieces are cut short enough for a 16-character prefix to fit as well,
-- should the limit count it: that is unmeasured here.
local MAX_PREFIX = 16
local PIECE      = 255 - 13 - (MAX_PREFIX + 1)

-- Fifty messages is most of a minute of the throttle, for one payload.
local MAX_PARTS = 50
local MAX_QUEUE = 400

-- THE THROTTLE: ten at once, then one a second, all prefixes together. The
-- same as Blizzard_CooldownBroadcaster's MessageQueue in Forever's own UI
-- source, which is Blizzard pacing its own addon messages.
local BURST     = 10
local REFILL    = 1      -- messages earned back per second
local TICK      = 0.25   -- how often a queue with anything in it is looked at
local HOLD      = 2      -- seconds of quiet after the client refuses a send
local MAX_TRIES = 3      -- GeneralErrors before a message is given up

-- Half-built payloads are forgotten after this long.
local PARTIAL_LIFE = 60

-- Tables inside tables, this deep and no deeper, both ways.
local MAX_DEPTH = 16

-- From ChatConstantsDocumentation in Forever's API dump; the numbers stand in
-- where Enum lacks the tables.
local RESULT        = (Enum and Enum.SendAddonMessageResult) or {}
local SUCCESS       = RESULT.Success or 0
local GENERAL_ERROR = RESULT.GeneralError or 9
local TRY_LATER     = {
    [RESULT.AddonMessageThrottle or 3]  = true,
    [RESULT.ChannelThrottle or 8]       = true,
    [RESULT.AddOnMessageLockdown or 11] = true,
}
local PREFIX_RESULT  = (Enum and Enum.RegisterAddonMessagePrefixResult) or {}
local PREFIX_REFUSED = {
    [PREFIX_RESULT.InvalidPrefix or 2] = true,
    [PREFIX_RESULT.MaxPrefixes or 3]   = true,
}
local CHAT_RESTRICTION = (Enum and Enum.AddOnRestrictionType
    and Enum.AddOnRestrictionType.Chat) or 5
local RESTRICTION_OFF  = (Enum and Enum.AddOnRestrictionState
    and Enum.AddOnRestrictionState.Inactive) or 0

local CHANNELS = { GUILD = true, PARTY = true, RAID = true, WHISPER = true }

local stats = {
    sent = 0, retried = 0, dropped = 0,
    received = 0, delivered = 0, rejected = 0, otherProtocol = 0, secret = 0,
    handlerErrors = 0,
}

-- ============================================================
-- SERIALISING
--
--   s<length>:<bytes>   a string, counted in bytes, so it needs no escaping
--   n<text>;            a number, as text that reads back to the same number
--   t  f                true, false
--   { key value ... }   a table; keys are strings or numbers
-- ============================================================

-- The shortest text that reads back exactly. Not %d, which goes through a C
-- long -- 32 bits on Windows in stock Lua 5.1 -- and breaks past two billion.
local function NumberText(n)
    local text = string.format("%.14g", n)
    if tonumber(text) ~= n then text = string.format("%.17g", n) end
    return text
end

-- `open` holds the tables on the way down, so one that contains itself is
-- refused instead of recursing until the stack runs out.
local function WriteValue(value, out, depth, open)
    if IsSecret(value) then return false, "a secret value cannot be sent" end
    local kind = type(value)

    if kind == "string" then
        out[#out + 1] = "s" .. #value .. ":" .. value
    elseif kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return false, "numbers must be finite"
        end
        out[#out + 1] = "n" .. NumberText(value) .. ";"
    elseif kind == "boolean" then
        out[#out + 1] = value and "t" or "f"
    elseif kind == "table" then
        if IsSecretTable(value) then return false, "a secret table cannot be sent" end
        if depth >= MAX_DEPTH then return false, "tables nest too deeply" end
        if open[value] then return false, "a table contains itself" end
        open[value] = true
        out[#out + 1] = "{"
        for key, item in pairs(value) do
            if type(key) ~= "string" and type(key) ~= "number" then
                return false, "table keys must be strings or numbers"
            end
            local ok, err = WriteValue(key, out, depth + 1, open)
            if not ok then return false, err end
            ok, err = WriteValue(item, out, depth + 1, open)
            if not ok then return false, err end
        end
        out[#out + 1] = "}"
        open[value] = nil
    else
        return false, "a " .. kind .. " cannot be sent"
    end
    return true
end

-- Read back by hand, a character at a time, never trusting a length it was
-- handed. Returns true, the value and the position after it, or nil.
local function ReadValue(s, pos, depth)
    local tag = string.sub(s, pos, pos)
    if tag == "s" then
        local digits = string.match(s, "^(%d+):", pos + 1)
        if not digits then return nil end
        local first = pos + #digits + 2
        local last  = first + tonumber(digits) - 1
        if last > #s then return nil end
        return true, string.sub(s, first, last), last + 1
    elseif tag == "n" then
        local text = string.match(s, "^([^;]+);", pos + 1)
        local n = text and tonumber(text)
        -- Finite only, as WriteValue sends: a C runtime's strtod, which
        -- tonumber uses, can read "inf" as well as "nan".
        if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
        return true, n, pos + #text + 2
    elseif tag == "t" or tag == "f" then
        return true, tag == "t", pos + 1
    elseif tag == "{" then
        if depth >= MAX_DEPTH then return nil end
        local t = {}
        pos = pos + 1
        while string.sub(s, pos, pos) ~= "}" do
            local okKey, key, afterKey = ReadValue(s, pos, depth + 1)
            if not okKey or (type(key) ~= "string" and type(key) ~= "number") then return nil end
            local okItem, item, afterItem = ReadValue(s, afterKey, depth + 1)
            if not okItem then return nil end
            t[key] = item
            pos = afterItem
        end
        return true, t, pos + 1
    end
    return nil
end

local function Serialize(value)
    local out = {}
    local ok, err = WriteValue(value, out, 0, {})
    if not ok then return nil, err end
    return table.concat(out)
end

-- True and the value, or false. The text must be one value with nothing left
-- over; pcall'd as well, since it is a stranger's.
local function Deserialize(text)
    local called, ok, value, after = pcall(ReadValue, text, 1, 0)
    if not (called and ok) or after ~= #text + 1 then return false end
    return true, value
end

-- ============================================================
-- ON THE WIRE
--
--   <version><id>:<index>:<total>:<piece>     e.g. "1" .. "4711:2:3:" .. piece
--
-- Printable ASCII only: each byte outside space to "}" goes as "~" and two
-- hex digits. That keeps out NUL, which a C string cannot carry, and control
-- characters, "~" and raw UTF-8, whose handling in addon messages has not
-- been measured here. An accented letter costs six bytes instead of two.
-- ============================================================

local function EscapeByte(c) return string.format("~%02X", string.byte(c)) end
local function UnescapeByte(hex) return string.char(tonumber(hex, 16)) end

local function Escape(raw)
    return (string.gsub(raw, "[^ -}]", EscapeByte))
end

-- nil when a "~" does not start an escape, which no sender of this writes.
local function Unescape(wire)
    local _, tildes = string.gsub(wire, "~", "")
    local raw, escapes = string.gsub(wire, "~(%x%x)", UnescapeByte)
    if escapes ~= tildes then return nil end
    return raw
end

-- Starting somewhere random, so a /reload does not reuse the ids of pieces
-- still waiting on the far side.
local lastId
local function NextId()
    lastId = (lastId or math.random(0, 49999)) + 1
    if lastId > 99999 then lastId = 1 end
    return lastId
end

-- ============================================================
-- THE QUEUE
-- ============================================================

local queue      = {}   -- { id, prefix, channel, target, text, tries }, oldest first
local served     = {}   -- [prefix] = true once it has had its turn this round
local tokens     = BURST
local refilledAt = nil
local holdUntil  = 0
local ticker     = nil

-- The only gate. A secret answer counts as locked. An error does not: a gate
-- that errored every time would hold the queue for ever, and the send's own
-- result code still says so if chat really is locked.
local function Locked()
    local lockdown = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    if not lockdown then return false end
    local ok, locked = pcall(lockdown)
    if not ok then return false end
    return IsSecret(locked) or (locked and true or false)
end

-- One piece failing for good takes the rest of its payload with it: they
-- could never be put back together.
local function DropMessage(id)
    for i = #queue, 1, -1 do
        if queue[i].id == id then
            table.remove(queue, i)
            stats.dropped = stats.dropped + 1
        end
    end
end

-- Prefixes take turns: each one with something waiting sends one message a
-- round, its oldest first. Strictly oldest-first, a fifty-message payload on
-- one prefix held every other addon's messages for forty seconds, and a
-- reply that waits that long is no reply.
local function NextIndex()
    for i = 1, #queue do
        if not served[queue[i].prefix] then return i end
    end
    served = {}
    return 1
end

-- Sends what the throttle allows and keeps a ticker going while anything
-- waits. An item leaves the queue BEFORE it is sent and goes back to its
-- place on a retry, so a handler that sends from inside a send cannot
-- scramble the order.
local function Pump()
    local now = GetTime()
    if queue[1] and now >= holdUntil and not Locked() then
        if refilledAt then tokens = math.min(BURST, tokens + (now - refilledAt) * REFILL) end
        refilledAt = now

        while tokens >= 1 and queue[1] do
            local at = NextIndex()
            local item = table.remove(queue, at)
            served[item.prefix] = true
            tokens = tokens - 1
            local ok, result = pcall(C_ChatInfo.SendAddonMessage,
                item.prefix, item.text, item.channel, item.target)
            if ok then stats.lastResult = result else stats.lastResult = "error: " .. tostring(result) end
            stats.lastResultId = item.id

            if ok and (result == SUCCESS or result == nil or result == true) then
                stats.sent = stats.sent + 1
            elseif ok and (TRY_LATER[result]
                or (result == GENERAL_ERROR and item.tries + 1 < MAX_TRIES)) then
                if result == GENERAL_ERROR then item.tries = item.tries + 1 end
                table.insert(queue, math.min(at, #queue + 1), item)
                stats.retried = stats.retried + 1
                tokens, holdUntil = 0, now + HOLD
                break
            else
                stats.dropped = stats.dropped + 1
                stats.lastDropped = stats.lastResult
                DropMessage(item.id)
            end
        end
    end

    if not queue[1] then
        if ticker then ticker:Cancel(); ticker = nil end
    elseif not ticker and C_Timer and C_Timer.NewTicker then
        ticker = C_Timer.NewTicker(TICK, Pump)
    end
end

-- ============================================================
-- RECEIVING
-- ============================================================

local handlers = {}   -- [prefix] = handler
local partials = {}   -- ["prefix:sender:id"] = { parts, have, total, at }

-- The whole wire text once the last piece lands, nil until then. Keyed by
-- sender as well as id, because every client counts its own ids.
local function Assemble(prefix, sender, id, index, total, piece)
    local now = GetTime()
    for oldKey, old in pairs(partials) do
        if now - old.at > PARTIAL_LIFE then partials[oldKey] = nil end
    end

    local key = prefix .. ":" .. sender .. ":" .. id
    local partial = partials[key]
    if not partial or partial.total ~= total then
        partial = { parts = {}, have = 0, total = total }
        partials[key] = partial
    end
    partial.at = now
    if partial.parts[index] == nil then
        partial.parts[index] = piece
        partial.have = partial.have + 1
    end
    if partial.have < total then return nil end

    partials[key] = nil
    return table.concat(partial.parts, "", 1, total)
end

-- id, index, total and piece, or nil if the header is not one of ours.
local function ParseHeader(text)
    local id, index, total, piece = string.match(text, "^(%d+):(%d+):(%d+):(.*)$", 2)
    if not id then return nil end
    index, total = tonumber(index), tonumber(total)
    if total < 1 or total > MAX_PARTS or index < 1 or index > total then return nil end
    return id, index, total, piece
end

-- Whether a sender is this character. CHAT_MSG_ADDON gave "First Surname" on
-- Forever (2026-09-18, before 70009) and gives "Name-Realm" on retail. A bare
-- first name counts too, which on Forever could be somebody else; the probe
-- prints the sender as it arrives, to settle which form 70009 uses.
local function IsMe(sender)
    local first, second = UnitName("player")
    if type(first) ~= "string" or IsSecret(first) then return false end
    if sender == first then return true end
    if type(second) == "string" and second ~= "" and not IsSecret(second)
        and sender == first .. SEPARATOR .. second then
        return true
    end
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    return type(realm) == "string" and realm ~= "" and sender == first .. "-" .. realm
end

-- Every addon's messages pass through here, so a prefix nobody registered
-- with BLib leaves at the first check, and nothing is compared until it is
-- known not to be a secret.
local function OnAddonMessage(prefix, text, channel, sender)
    if IsSecret(prefix) then return end
    local handler = handlers[prefix]
    if not handler then return end
    if IsSecret(text) or IsSecret(channel) or IsSecret(sender) then
        stats.secret = stats.secret + 1
        return
    end
    if type(text) ~= "string" or type(sender) ~= "string" then return end
    stats.received = stats.received + 1

    if string.sub(text, 1, 1) ~= PROTOCOL then
        stats.otherProtocol = stats.otherProtocol + 1
        return
    end
    local id, index, total, piece = ParseHeader(text)
    local wire = id and piece
    if id and total > 1 then
        wire = Assemble(prefix, sender, id, index, total, piece)
        if not wire then return end
    end

    local raw = wire and Unescape(wire)
    local ok, payload
    if raw then ok, payload = Deserialize(raw) end
    if not ok then
        stats.rejected = stats.rejected + 1
        return
    end

    -- A handler that throws must not stop the others, nor vanish: the error
    -- goes to the error handler, where BugSack sees it.
    stats.delivered = stats.delivered + 1
    local called, err = pcall(handler, payload, sender, channel, IsMe(sender))
    if not called then
        stats.handlerErrors = stats.handlerErrors + 1
        stats.lastError = tostring(err)
        local report = geterrorhandler and geterrorhandler()
        if report then report(err) end
    end
end

-- ============================================================
-- EVENTS, REGISTERED ON FIRST USE
-- ============================================================

local frame = nil
local listening, watching = false, false

local function OnEvent(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        -- Fired after a restriction lifts. The ticker would notice within a
        -- quarter of a second anyway; this saves the wait.
        local kind, state = ...
        if IsSecret(kind) or IsSecret(state) then return end
        if kind == CHAT_RESTRICTION and state == RESTRICTION_OFF then Pump() end
    end
end

-- pcall'd like BLib.Data's, so an event one client lacks cannot raise.
local function RegisterEvent(event)
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent)
    end
    pcall(frame.RegisterEvent, frame, event)
end

-- ============================================================
-- API
-- ============================================================

local function IsPrefix(prefix)
    return type(prefix) == "string" and not IsSecret(prefix)
        and prefix ~= "" and #prefix <= MAX_PREFIX
end

-- Registers the prefix with the client and routes its payloads to
-- handler(payload, sender, channel, fromSelf). Anyone can WHISPER you, so a
-- handler that acts on what it hears should check the channel. One handler a
-- prefix. Returns true and RegisterAddonMessagePrefix's result (nil when
-- already registered), or nil and a reason.
function C:Register(prefix, handler)
    if not IsPrefix(prefix) then return nil, "a prefix is 1 to 16 characters" end
    if type(handler) ~= "function" then return nil, "the handler must be a function" end
    if handlers[prefix] == handler then return true end
    if handlers[prefix] then return nil, "that prefix already has a handler" end

    local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
    if not register then return nil, "no C_ChatInfo.RegisterAddonMessagePrefix on this client" end
    local ok, result = pcall(register, prefix)
    if not ok then return nil, tostring(result) end
    if result == false or PREFIX_REFUSED[result] then
        return nil, "the client refused the prefix (" .. tostring(result) .. ")"
    end

    handlers[prefix] = handler
    if not listening then
        listening = true
        RegisterEvent("CHAT_MSG_ADDON")
    end
    return true, result
end

-- Queues a payload and sends what the throttle allows at once. Returns the
-- message id and how many messages it took, or nil and a reason. Guild and
-- group membership are not checked here: the result code decides, and a
-- message that cannot go is dropped and counted (Stats().lastDropped).
function C:Send(prefix, payload, channel, target)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then
        return nil, "no C_ChatInfo.SendAddonMessage on this client"
    end
    if not IsPrefix(prefix) then return nil, "a prefix is 1 to 16 characters" end
    channel = type(channel) == "string" and not IsSecret(channel) and string.upper(channel)
    if not CHANNELS[channel] then return nil, "the channel is GUILD, PARTY, RAID or WHISPER" end
    if channel ~= "WHISPER" then
        target = nil
    elseif type(target) ~= "string" or IsSecret(target) or target == "" then
        return nil, "a WHISPER needs a target"
    end

    local raw, err = Serialize(payload)
    if not raw then return nil, err end
    local wire  = Escape(raw)
    local total = math.ceil(#wire / PIECE)
    if total > MAX_PARTS then
        return nil, string.format("%d bytes on the wire; the most is %d", #wire, MAX_PARTS * PIECE)
    end
    if #queue + total > MAX_QUEUE then return nil, "the send queue is full" end

    local id = NextId()
    for index = 1, total do
        queue[#queue + 1] = {
            id = id, prefix = prefix, channel = channel, target = target, tries = 0,
            text = PROTOCOL .. id .. ":" .. index .. ":" .. total .. ":"
                .. string.sub(wire, (index - 1) * PIECE + 1, index * PIECE),
        }
    end

    if not watching then
        watching = true
        RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
    end
    Pump()
    return id, total
end

-- A copy of the counters, with the queue and the lockdown as they are now.
function C:Stats()
    local copy = {}
    for key, value in pairs(stats) do copy[key] = value end
    copy.queued, copy.lockedDown = #queue, Locked()
    return copy
end

-- The format on its own, for the same shape on disk or through /dump.
function C:Serialize(value) return Serialize(value) end

function C:Deserialize(text)
    if type(text) ~= "string" or IsSecret(text) then return false end
    return Deserialize(text)
end

-- ============================================================
-- THE PROBE: /blib comm test, or /run BLib.Comm:RunProbe()
--
-- Whispers three payloads to yourself, each testing one thing: "short" is
-- one plain message; "escapes" is one message carrying a tilde, a pipe, a
-- newline and an accented letter; "long" is plain but takes several messages.
-- The question: does a WHISPER to yourself arrive on Forever, how fast, with
-- the sender's name in what form, and what do the lockdown calls say? It
-- prints what it sees and draws no conclusions.
-- ============================================================

local PROBE_PREFIX = "BLibProbe"
local PROBE_WAIT   = 10
local probe        = nil   -- the run in progress
local Clock        = GetTimePreciseSec or GetTime

-- Calls fn and describes the answer, whatever it is.
local function Ask(fn, ...)
    if type(fn) ~= "function" then return "missing" end
    local ok, value = pcall(fn, ...)
    if not ok then return "error: " .. tostring(value) end
    return IsSecret(value) and "secret" or tostring(value)
end

-- A result code with its Enum name, where it has one.
local function Describe(code, names)
    for name, value in pairs(names) do
        if value == code then return tostring(code) .. " (" .. name .. ")" end
    end
    return tostring(code)
end

local function Same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do
        if not Same(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function OnProbeMessage(payload, sender, channel, fromSelf)
    local test = probe and type(payload) == "table" and probe[payload.token]
    if not test then return end
    test.copies = test.copies + 1
    if test.copies > 1 then return end
    test.back = true
    BLib.PrintLine(string.format("  %s: back after %.3f s, sender %q, channel %s, fromSelf %s, intact %s",
        test.label, Clock() - test.at, sender, tostring(channel), tostring(fromSelf),
        tostring(Same(payload, test.payload))))
end

function C:RunProbe()
    local chat, line = C_ChatInfo or {}, BLib.PrintLine
    local version, build = "?", "?"
    if GetBuildInfo then version, build = GetBuildInfo() end
    BLib.Print("BLib", "comm test: three payloads by WHISPER to yourself, prefix " .. PROBE_PREFIX)
    line("  client " .. tostring(version) .. " build " .. tostring(build))
    line("  InChatMessagingLockdown: " .. Ask(chat.InChatMessagingLockdown))
    line("  GetAddOnRestrictionState(Chat): " .. Ask(C_RestrictedActions
        and C_RestrictedActions.GetAddOnRestrictionState, CHAT_RESTRICTION))
    line("  AreOutgoingAddonChatMessagesRestricted: " .. Ask(chat.AreOutgoingAddonChatMessagesRestricted))

    local registered, result = self:Register(PROBE_PREFIX, OnProbeMessage)
    line("  Register: " .. (not registered and ("refused, " .. tostring(result))
        or (result == nil and "ok, already registered this session")
        or ("ok, RegisterAddonMessagePrefix returned " .. Describe(result, PREFIX_RESULT))))
    line("  IsAddonMessagePrefixRegistered: " .. Ask(chat.IsAddonMessagePrefixRegistered, PROBE_PREFIX))
    if not registered then return end

    -- "First Surname", the form Blizzard's own chat box whispers where regional
    -- unique names are on (ChatFrameEditBox.lua).
    local first, surname = UnitName("player")
    local target = (NameUtil and NameUtil.GetUnmodifiedUnitFullName
        and NameUtil.GetUnmodifiedUnitFullName("player"))
        or (surname and surname ~= "" and first .. SEPARATOR .. surname) or first
    line(string.format("  target %q", tostring(target)))

    local token, run, order = tostring(math.random(100000, 999999)), {}, {}
    probe = run
    local function Start(label, payload)
        payload.token = token .. label
        local test = { label = label, payload = payload, at = Clock(), copies = 0 }
        run[payload.token], order[#order + 1] = test, test
        local id, parts = self:Send(PROBE_PREFIX, payload, "WHISPER", target)
        local now = self:Stats()
        line(id and string.format("  %s: %d message(s), SendAddonMessage returned %s, queue %d",
                label, parts, now.lastResultId == id and Describe(now.lastResult, RESULT)
                or "nothing yet", now.queued)
            or ("  " .. label .. ": not sent, " .. tostring(parts)))
    end

    Start("short", {})
    -- A tilde, a pipe, a newline, and e-acute as its two UTF-8 bytes.
    Start("escapes", { text = "~|" .. string.char(10) .. "caf" .. string.char(195, 169) })
    Start("long", { body = string.rep("0123456789", 50), list = { "a", "b", 3 },
        n = 1234.5678, big = 2 ^ 40 + 1, yes = true, no = false })

    if not (C_Timer and C_Timer.After) then return end
    C_Timer.After(PROBE_WAIT, function()
        if probe ~= run then return end
        probe = nil
        for _, test in ipairs(order) do
            line(test.back and string.format("  %s: arrived %d time(s)", test.label, test.copies)
                or string.format("  %s: nothing back within %d s", test.label, PROBE_WAIT))
        end
        local now = self:Stats()
        line(string.format("  stats: sent %d, retried %d, dropped %d, queued %d, received %d, "
            .. "rejected %d, lastResult %s, lockedDown %s", now.sent, now.retried, now.dropped,
            now.queued, now.received, now.rejected, Describe(now.lastResult, RESULT),
            tostring(now.lockedDown)))
    end)
end
