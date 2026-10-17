local addonName, MCF = ...
-- Social tracking for the character chronicle: waves/emotes, whispers,
-- resurrections and groups. Event-based, no combat log. Everything coming from
-- the game goes through MCF.Readable (Forever/Midnight can hand out secret values).
--
-- Privacy: other players are only stored as a short one-way hash, to be able to
-- count *different* players. No names are written to the saved variables.

local Readable = MCF.Readable
local DEDUPE_SECONDS = 0.25     -- DoEmote and C_ChatInfo.PerformEmote may both report one emote
local RES_REQUEST_SECONDS = 180 -- an incoming resurrection counts if accepted within this time
local MAX_PENDING_CASTS = 20

local function Social()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    db.social = db.social or {}
    local s = db.social
    s.emotes = s.emotes or {total = 0, byToken = {}}
    s.emotes.byToken = s.emotes.byToken or {}
    s.wave = s.wave or {total = 0, players = 0, seen = {}}
    s.whisper = s.whisper or {sent = 0, received = 0, sentTo = 0, receivedFrom = 0, sentSeen = {}, receivedSeen = {}}
    s.resurrect = s.resurrect or {cast = 0, received = 0}
    s.group = s.group or {joined = 0, mates = 0, seen = {}}
    s.addonUsers = s.addonUsers or {total = 0, seen = {}}
    return s
end

-- "Name-Realm", "Name Realm" (WoW Forever uses a space) and "name" are the same player. Character names never
-- contain a space or a hyphen.
local function BaseName(name)
    return (name:match("^[^%s-]+") or name)
end

local function Hash(name)
    name = BaseName(name):lower()
    local h = 5381
    for i = 1, #name do h = (h * 33 + name:byte(i)) % 4294967296 end
    return string.format("%08x", h)
end

-- Counts `name` once per holder[setKey]; increments holder[counterKey] for new players.
local function Unique(holder, setKey, counterKey, name)
    name = Readable(name)
    if type(name) ~= "string" or name == "" then return end
    holder[setKey] = holder[setKey] or {}
    local h = Hash(name)
    if not holder[setKey][h] then
        holder[setKey][h] = true
        holder[counterKey] = (holder[counterKey] or 0) + 1
    end
end

---------------------------------------------------------------------------
-- Emotes
---------------------------------------------------------------------------
local lastEmote = {}

-- /wave Name passes a name, plain /wave uses the current target.
local function PlayerNameFromEmoteTarget(target)
    target = Readable(target)
    local unit = "target"
    if type(target) == "string" and target ~= "" then
        if UnitExists(target) then unit = target else return target end
    end
    if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
        return Readable(UnitName(unit))
    end
    return nil
end

local function OnEmote(token, target)
    local s = Social()
    token = Readable(token)
    if not s or type(token) ~= "string" then return end
    token = token:upper()
    local now = GetTime()
    if lastEmote.token == token and lastEmote.target == target and now - (lastEmote.time or 0) < DEDUPE_SECONDS then return end
    lastEmote.token, lastEmote.target, lastEmote.time = token, target, now

    s.emotes.total = s.emotes.total + 1
    s.emotes.byToken[token] = (s.emotes.byToken[token] or 0) + 1
    if token == "WAVE" then
        s.wave.total = s.wave.total + 1
        local ok, who = pcall(PlayerNameFromEmoteTarget, target)
        if ok and who then Unique(s.wave, "seen", "players", who) end
    end
end

local function HookEmotes()
    if type(DoEmote) == "function" then hooksecurefunc("DoEmote", OnEmote) end
    if C_ChatInfo and C_ChatInfo.PerformEmote then hooksecurefunc(C_ChatInfo, "PerformEmote", OnEmote) end
end

---------------------------------------------------------------------------
-- Resurrections
---------------------------------------------------------------------------
local pendingCasts = {}   -- castKey -> true while a cast aimed at a dead friendly player is running
local pendingResAt = nil  -- GetTime() of the last incoming resurrection request

local function IsDeadFriendlyPlayer(name)
    local ok, result = pcall(function()
        local unit = "target"
        local targetName = Readable(UnitName("target"))
        if type(targetName) ~= "string" or BaseName(targetName) ~= BaseName(name) then unit = name end
        return UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player")
            and UnitIsFriend("player", unit) and UnitIsDeadOrGhost(unit)
    end)
    return ok and result == true
end

local function CastKey(castGUID, spellID)
    return Readable(castGUID) or ("spell" .. tostring(Readable(spellID) or "?"))
end

local function OnCastSent(unit, target, castGUID, spellID)
    target = Readable(target)
    if unit ~= "player" or type(target) ~= "string" or target == "" then return end
    if BaseName(target) == BaseName(Readable(UnitName("player")) or "") then return end
    if not IsDeadFriendlyPlayer(target) then return end
    local n = 0
    for _ in pairs(pendingCasts) do n = n + 1 end
    if n >= MAX_PENDING_CASTS then wipe(pendingCasts) end
    pendingCasts[CastKey(castGUID, spellID)] = true
end

local function OnCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end
    local key = CastKey(castGUID, spellID)
    if not pendingCasts[key] then return end
    pendingCasts[key] = nil
    local s = Social()
    if s then s.resurrect.cast = s.resurrect.cast + 1 end
end

local function OnCastAborted(unit, castGUID, spellID)
    if unit == "player" then pendingCasts[CastKey(castGUID, spellID)] = nil end
end

---------------------------------------------------------------------------
-- Groups
---------------------------------------------------------------------------
local wasInGroup = nil

local function ScanGroup()
    local s = Social()
    if not s then return end
    local inGroup = IsInGroup() and true or false
    if wasInGroup == nil then
        wasInGroup = inGroup -- first look after login: never count a group we were already in
    elseif inGroup and not wasInGroup then
        s.group.joined = s.group.joined + 1
    end
    wasInGroup = inGroup
    if not inGroup then return end
    local raid = IsInRaid()
    local prefix = raid and "raid" or "party"
    local members = raid and GetNumGroupMembers() or (GetNumGroupMembers() - 1)
    for i = 1, members do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            Unique(s.group, "seen", "mates", UnitName(unit))
        end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- Who the whisper is with: the sender name for normal whispers; for Battle.net whispers the
-- account id (arg13) is stable, the displayed name may be an escaped presence string.
local function WhisperPartner(event, ...)
    if event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM" then
        local id = Readable((select(13, ...)))
        if id ~= nil then return "bn" .. tostring(id) end
    end
    return (select(2, ...))
end

local frame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
                        "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
                        "RESURRECT_REQUEST", "PLAYER_ALIVE", "PLAYER_UNGHOST", "GROUP_ROSTER_UPDATE"}) do
    pcall(function() frame:RegisterEvent(event) end)
end
for _, event in ipairs({"UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
                        "UNIT_SPELLCAST_INTERRUPTED"}) do
    pcall(function() frame:RegisterUnitEvent(event, "player") end)
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        HookEmotes()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if wasInGroup == nil then ScanGroup() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        ScanGroup()
    elseif event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM" then
        -- Battle.net whispers (replying to a friend's name) arrive as their own events.
        local s = Social(); if not s then return end
        s.whisper.sent = s.whisper.sent + 1
        Unique(s.whisper, "sentSeen", "sentTo", WhisperPartner(event, ...))
    elseif event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
        local s = Social(); if not s then return end
        s.whisper.received = s.whisper.received + 1
        Unique(s.whisper, "receivedSeen", "receivedFrom", WhisperPartner(event, ...))
    elseif event == "UNIT_SPELLCAST_SENT" then
        OnCastSent(...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnCastSucceeded(...)
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        OnCastAborted(...)
    elseif event == "RESURRECT_REQUEST" then
        pendingResAt = GetTime()
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        if pendingResAt and GetTime() - pendingResAt <= RES_REQUEST_SECONDS then
            local s = Social()
            if s then s.resurrect.received = s.resurrect.received + 1 end
        end
        pendingResAt = nil
    end
end)

---------------------------------------------------------------------------
-- Other MyCharForever users
--   The addon says hello with a small addon message (no chat text, nothing visible to other players) in
--   PARTY, RAID and GUILD, whichever is available. Other copies answer once by whisper. Every player
--   who sends a hello or an answer is counted once (hashed, see Hash), which feeds the "other users" achievements.
--   Nothing about the character is sent: only the addon version. Setting: presenceEnabled (default on).
--   Every limit lives in MCF.Presence.
---------------------------------------------------------------------------
MCF.Presence = {
    prefix = "MyCharForever",  -- addon message prefix, at most 16 characters
    helloDelay = 20,           -- seconds after login before the first hello
    helloInterval = 300,       -- seconds between hellos while playing
    minGap = 30,               -- hellos are never sent closer together than this
    replyCooldown = 1800,      -- the same player is answered at most this often
    pingWait = 4,              -- /mcf ping lists who answered after this many seconds
    channels = {"PARTY", "RAID", "GUILD"}, -- tried in this order; unavailable ones are skipped (WoW Forever refuses SAY and YELL: InvalidChatType)
    maxRecentNames = 12,       -- names kept in memory (never saved) for /mcf ping
}
local PR = MCF.Presence
PR.lastResult = {}   -- channel -> result of the last send, shown by /mcf ping and the self test
PR.recent = {}       -- names heard this session (memory only)
local repliedAt, lastHello = {}, nil
local MSG_HELLO, MSG_REPLY = "H1:", "R1:"

local function PresenceEnabled()
    local st = MyCharForeverDB and MyCharForeverDB.settings
    return not (st and st.presenceEnabled == false)
end

local function RegisterPrefix()
    if PR.registered then return true end
    local register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
    if not register then return false end
    local ok, result = pcall(register, PR.prefix)
    PR.registered = ok and result ~= false
    return PR.registered
end

local function ChannelAvailable(channel)
    if channel == "PARTY" then return IsInGroup and IsInGroup() end
    if channel == "RAID" then return IsInRaid and IsInRaid() end
    if channel == "GUILD" then return IsInGuild and IsInGuild() end
    return true
end

-- Sends one addon message. Returns a short result text; never raises.
local function SendAddon(channel, text, target)
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return "no API" end
    local ok, result = pcall(send, PR.prefix, text, channel, target)
    if not ok then return "error: " .. tostring(result):sub(1, 80) end
    if result == nil or result == true or result == 0 then return "ok" end
    -- Retail returns Enum.SendAddonMessageResult; name it when possible.
    local name
    if Enum and Enum.SendAddonMessageResult then
        for key, value in pairs(Enum.SendAddonMessageResult) do if value == result then name = key end end
    end
    return "refused: " .. tostring(name or result)
end

-- Sends the hello to every available channel. force skips the minimum gap (used by /mcf ping).
function MCF:SendPresenceHello(force)
    if not PresenceEnabled() then return nil end
    if not RegisterPrefix() then return nil end
    local now = GetTime()
    if not force and lastHello and now - lastHello < PR.minGap then return nil end
    lastHello = now
    local results = {}
    for _, channel in ipairs(PR.channels) do
        if ChannelAvailable(channel) then
            local result = SendAddon(channel, MSG_HELLO .. tostring(MCF.VERSION))
            PR.lastResult[channel] = result
            results[#results + 1] = channel .. ": " .. result
        end
    end
    return results
end

-- Compared by base name, ignoring case and any realm suffix, however the game formats the sender.
local function SenderIsMe(sender)
    local me = UnitName and UnitName("player")
    if not me then return false end
    return BaseName(sender):lower() == BaseName(me):lower()
end

local function RecordAddonUser(sender, version, channel)
    local s = Social()
    if not s then return end
    local before = s.addonUsers.total or 0
    Unique(s.addonUsers, "seen", "total", sender)
    if (s.addonUsers.total or 0) > before then
        MCF:DebugPrint("another MyCharForever user: " .. tostring(version))
        C_Timer.After(1, function() if MCF.CheckAchievements then MCF:CheckAchievements() end end)
    end
    local plain = Ambiguate and Ambiguate(sender, "none") or sender
    -- Shown by /mcf ping and /mcf presence: who was heard, over which channel, with which version (memory only).
    local label = plain .. " [" .. tostring(channel or "?") .. ", " .. tostring(version or "?") .. ", raw " .. tostring(sender) .. "]"
    for _, name in ipairs(PR.recent) do if name == label then return end end
    if #PR.recent < PR.maxRecentNames then PR.recent[#PR.recent + 1] = label end
end

local function OnAddonMessage(prefix, text, channel, sender)
    if prefix ~= PR.prefix or not PresenceEnabled() then return end
    text, sender = Readable(text), Readable(sender)
    if type(text) ~= "string" or type(sender) ~= "string" or sender == "" or SenderIsMe(sender) then return end
    local kind, version = text:match("^([HR])1:(.*)$")
    if not kind then return end
    RecordAddonUser(sender, version, channel)
    if kind == "H" then
        local key = Hash(sender)
        local now = GetTime()
        if not repliedAt[key] or now - repliedAt[key] >= PR.replyCooldown then
            repliedAt[key] = now
            PR.lastResult.WHISPER = SendAddon("WHISPER", MSG_REPLY .. tostring(MCF.VERSION), sender)
        end
    end
end

local presenceFrame = CreateFrame("Frame")
presenceFrame:RegisterEvent("PLAYER_LOGIN")
presenceFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
pcall(function() presenceFrame:RegisterEvent("CHAT_MSG_ADDON") end)
local function PresenceTick()
    MCF:SafeCall("PresenceHello", MCF.SendPresenceHello, MCF)
    C_Timer.After(PR.helloInterval, PresenceTick)
end
presenceFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        RegisterPrefix()
        C_Timer.After(PR.helloDelay, PresenceTick)
    elseif event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(2, function() MCF:SafeCall("PresenceHello", MCF.SendPresenceHello, MCF) end)
    elseif event == "CHAT_MSG_ADDON" then
        MCF:SafeCall("PresenceMessage", OnAddonMessage, ...)
    end
end)

MCF:AddCommand{group="main", usage="/mcf ping", key="ping",
    de="Sagt anderen MyCharForever-Nutzern in deiner Gruppe und Gilde Hallo und zeigt, wer antwortet",
    en="Says hello to other MyCharForever users in your group and guild and shows who answers",
    run=function()
        local de = MCF:GetLanguage() == "deDE"
        local function say(m) print("|cff00ccffMyCharForever|r: " .. m) end
        if not PresenceEnabled() then
            say(de and "Aus: Einstellung „Anderen Nutzern zeigen, dass ich MyCharForever nutze“ ist ausgeschaltet." or "Off: the setting to let other users know you use MyCharForever is switched off.")
            return
        end
        local results = MCF:SendPresenceHello(true)
        if not results then say(de and "Senden nicht möglich (Addon-Nachrichten nicht verfügbar)." or "Cannot send (addon messages not available)."); return end
        say((de and "Hallo gesendet: " or "Hello sent: ") .. table.concat(results, ", "))
        PR.recent = {}
        C_Timer.After(PR.pingWait, function()
            local s = Social()
            local total = s and s.addonUsers.total or 0
            if #PR.recent > 0 then
                say((de and "Antworten: " or "Answers: ") .. table.concat(PR.recent, ", ") .. "  (" .. (de and "insgesamt bekannt: " or "known in total: ") .. total .. ")")
            else
                say((de and "Keine Antwort. Insgesamt bekannt: " or "No answer. Known in total: ") .. total)
            end
        end)
    end}

MCF:AddCommand{group="debug", usage="/mcf presence", key="presence",
    de="Zeigt, welche anderen MyCharForever-Nutzer in dieser Sitzung gehört wurden (Name, Kanal, Version)",
    en="Shows which other MyCharForever users were heard this session (name, channel, version)",
    run=function()
        local de = MCF:GetLanguage() == "deDE"
        local s = Social()
        local total = s and s.addonUsers.total or 0
        print("|cff00ccffMyCharForever|r: " .. (de and "Bekannte Nutzer insgesamt: " or "Known users in total: ") .. total)
        if #PR.recent == 0 then print(de and "  In dieser Sitzung nichts gehört." or "  Nothing heard this session.") end
        for _, line in ipairs(PR.recent) do print("  " .. line) end
        for channel, result in pairs(PR.lastResult) do print("  " .. channel .. ": " .. tostring(result)) end
    end}

MCF:AddCommand{group="debug", usage="/mcf resetpresence", key="resetpresence",
    de="Setzt den Zähler für andere MyCharForever-Nutzer und die drei zugehörigen Erfolge dieses Charakters zurück",
    en="Resets the counter of other MyCharForever users and this character's three related achievements",
    run=function()
        local de = MCF:GetLanguage() == "deDE"
        local s = Social()
        if not s then return end
        s.addonUsers = {total = 0, seen = {}}
        PR.recent = {}
        local store = MyCharForeverDB and MyCharForeverDB.achievements
        local removed = 0
        if store and type(store.unlocked) == "table" then
            for _, id in ipairs({"presence_1", "presence_5", "presence_20"}) do
                if store.unlocked[id] then store.unlocked[id] = nil; removed = removed + 1 end
            end
        end
        print("|cff00ccffMyCharForever|r: " .. (de and "Zurückgesetzt. Entfernte Erfolge: " or "Reset. Achievements removed: ") .. removed)
        if MCF.RefreshUI then MCF:RefreshUI() end
    end}

-- Counts only (no hashed player sets); used by the chronicle export.
function MCF:GetSocialSummary()
    local s = Social()
    if not s then return nil end
    return {
        emotes = {total = s.emotes.total, byToken = s.emotes.byToken},
        wave = {total = s.wave.total, players = s.wave.players},
        whisper = {sent = s.whisper.sent, received = s.whisper.received,
                   sentTo = s.whisper.sentTo, receivedFrom = s.whisper.receivedFrom},
        resurrect = {cast = s.resurrect.cast, received = s.resurrect.received},
        group = {joined = s.group.joined, mates = s.group.mates},
        addonUsers = {total = s.addonUsers.total},
    }
end

MCF:AddCommand{group="debug",usage="/mcf social",key="social",de="Zähler für Flüstern, Winken, Emotes und Gruppen anzeigen",en="Show the whisper, wave, emote and group counters",
    run=function()
        local s = Social()
        if not s then return end
        print("|cff00ccffMyCharForever|r: whisper sent " .. s.whisper.sent .. " (" .. (s.whisper.sentTo or 0) .. " players), received " .. s.whisper.received
            .. " (" .. (s.whisper.receivedFrom or 0) .. "), emotes " .. s.emotes.total .. ", waves " .. s.wave.total .. ", groups " .. s.group.joined)
    end}
