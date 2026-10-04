-- BLib_Account.lua
-- The account store (docs/steward-design.md, section 2): one record per
-- character per kind of data, all under BLib.Data's key ("Realm-First
-- Surname"), each stamped with the server time it was read. It replaces the
-- same facts being read again by every addon under three spellings of a
-- character.
--
-- Collectors are defined here, once, and run only while a loaded addon has
-- asked for them (Account:Need). BLib on its own registers nothing: someone
-- with only Countinghouse records no reputations. What a collector wrote
-- stays either way.
--
-- BLib.Data's tables (inventory, guild banks, professions) stay where they
-- are for now; Account:Get reads them as sections, so readers can move to
-- this API before the tables do.
--
--   BLib.Account:Need(section, who)       start a collector ("gold", "xp"...)
--   BLib.Account:Key()                    this character's key, or nil
--   BLib.Account:Chars()                  key -> { name, realm, class, level, guild, guid, seen, ... }
--   BLib.Account:Get(section, key)        that character's record, or nil
--   BLib.Account:Each(section)            pairs() over key -> record
--   BLib.Account:Age(section, key)        seconds since it was read, or nil
--   BLib.Account:OnChange(section, fn)    fn(section, key, record) after each write
--   BLib.Account:Forget(key)              remove a character from every section
--   BLib.Account:Refresh(section)         read a running collector now
--   BLib.Account:Running(section)         whether someone asked for it
--
-- Depends on: BLib_Core.lua (BLibDB), BLib_Data.lua (the key).

BLib = BLib or {}
BLib.Account = {}
local A = BLib.Account

A.SCHEMA = 1

local IsSecret = issecretvalue or function() return false end

-- ============================================================
-- STORAGE
-- ============================================================

-- BLib.Data's tables, read as sections without moving them.
local VIEWS = { inventory = "inventory", guildBanks = "guildBanks", professions = "professions" }

local function Store()
    if type(BLibDB) ~= "table" then return nil end
    local s = BLibDB.account
    if type(s) ~= "table" then
        s = { schema = A.SCHEMA, chars = {}, sections = {} }
        BLibDB.account = s
    end
    s.chars = s.chars or {}
    s.sections = s.sections or {}
    return s
end

local function Section(name)
    if VIEWS[name] then return BLibDB and BLibDB[VIEWS[name]] end
    local s = Store()
    if not s then return nil end
    s.sections[name] = s.sections[name] or {}
    return s.sections[name]
end

-- This character's key once the game can say who it is; nil before, and a
-- write without one is skipped rather than filed under "?".
function A:Key()
    if not (BLib.Data and BLib.Data.GetPlayerKey) then return nil end
    local ok, key = pcall(BLib.Data.GetPlayerKey, BLib.Data)
    if not ok or type(key) ~= "string" or IsSecret(key) or key:find("%-$") then return nil end
    return key
end

function A:Chars()
    local s = Store()
    return s and s.chars or {}
end

function A:Get(section, key)
    local t = Section(section)
    return t and key and t[key] or nil
end

function A:Each(section)
    return pairs(Section(section) or {})
end

-- Views keep their own time fields: timestamp (seconds, time()).
function A:Age(section, key)
    local rec = self:Get(section, key)
    if not rec then return nil end
    local t = rec.t or rec.timestamp
    return t and (GetServerTime() - t) or nil
end

local listeners = {}

function A:OnChange(section, fn)
    listeners[section] = listeners[section] or {}
    table.insert(listeners[section], fn)
end

local function Fire(section, key, rec)
    for _, fn in ipairs(listeners[section] or {}) do
        local ok, err = pcall(fn, section, key, rec)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end

-- A collector's record for this character: stamped and stored whole.
local function Put(section, rec, version)
    local key = A:Key()
    local t = Section(section)
    if not (key and t and type(rec) == "table") then return end
    rec.t, rec.v = GetServerTime(), version or 1
    t[key] = rec
    Fire(section, key, rec)
end

function A:Forget(key)
    local s = Store()
    if not (s and key) then return false end
    local found = s.chars[key] ~= nil
    s.chars[key] = nil
    for _, t in pairs(s.sections) do
        if t[key] then found = true end
        t[key] = nil
    end
    for _, field in pairs(VIEWS) do
        local t = BLibDB[field]
        if type(t) == "table" and t[key] then
            found = true
            t[key] = nil
        end
    end
    Fire("chars", key, nil)
    return found
end

-- ============================================================
-- COLLECTORS
-- Each: events it listens to, and read(event, ...) returning the section's
-- new record, or nil to leave it as it is. "Soon" work is coalesced.
-- ============================================================

local collectors, running, byEvent = {}, {}, {}
local ready = false          -- two seconds after login: what is read then is settled
local frame = CreateFrame("Frame")

local function Define(name, def)
    def.name = name
    collectors[name] = def
end

local pending = {}
local function Soon(name, delay, fn)
    if pending[name] then return end
    pending[name] = true
    C_Timer.After(delay, function() pending[name] = nil fn() end)
end

local function Run(name, event, ...)
    local def = collectors[name]
    if not (def and ready) then return end
    local ok, rec = pcall(def.read, event, ...)
    if not ok then
        if geterrorhandler then geterrorhandler()(rec) end
        return
    end
    if rec then Put(name, rec, def.version) end
end

local function Start(name)
    local def = collectors[name]
    if not def or running[name] then return end
    running[name] = true
    for _, event in ipairs(def.events or {}) do
        byEvent[event] = byEvent[event] or {}
        byEvent[event][name] = true
        pcall(frame.RegisterEvent, frame, event)
    end
    if ready then Run(name, "START") end
end

local needs = {}

function A:Need(section, who)
    if not collectors[section] then return false end
    needs[section] = needs[section] or {}
    needs[section][who or "?"] = true
    -- The registry comes with anything.
    Start("chars")
    Start(section)
    return true
end

function A:Running(section) return running[section] or false end

-- Read a running collector now, as at login (Steward's /steward scan).
function A:Refresh(section)
    if running[section] then Run(section, "START") end
end

-- ------------------------------------------------ the character registry

local function FullName()
    local first, surname = UnitName("player")
    if surname and surname ~= "" then return first .. " " .. surname end
    return first
end

Define("chars", {
    events = { "PLAYER_LEVEL_UP", "PLAYER_GUILD_UPDATE", "PLAYER_LOGOUT" },
    -- Not a section: the registry itself, merged rather than replaced.
    read = function(event, arg1)
        local key, s = A:Key(), Store()
        if not (key and s) then return nil end
        local c = s.chars[key] or {}
        s.chars[key] = c
        -- Name, class and race are read once a session: Forever flags
        -- UnitName and UnitClass SecretWhenUnitIdentityRestricted.
        if not c.name or event == "START" then
            c.name, c.realm = FullName(), GetRealmName()
            c.class = select(2, UnitClass("player"))
            c.race = select(2, UnitRace("player"))
            c.faction = UnitFactionGroup("player")
            c.guid = UnitGUID("player")
        end
        c.level = (event == "PLAYER_LEVEL_UP" and tonumber(arg1)) or UnitLevel("player")
        c.guild = GetGuildInfo and GetGuildInfo("player") or nil
        c.seen = GetServerTime()
        Fire("chars", key, c)
        return nil
    end,
})

-- ------------------------------------------------ gold

Define("gold", {
    events = { "PLAYER_MONEY" },
    read = function()
        return { copper = GetMoney() }
    end,
})

-- ------------------------------------------------ xp, rested, where

Define("xp", {
    events = { "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP",
        "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED" },
    read = function(event, arg1)
        local xp, xpMax, rested = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion() or 0
        -- An XP maximum of nothing is not a reading (found in the real
        -- saved data, 2026-09-29: every level 13 character had 0 of 0): keep
        -- what the last good reading said and update where the character is.
        local old = A:Get("xp", A:Key())
        if (type(xpMax) ~= "number" or IsSecret(xpMax) or xpMax <= 0) and old and (old.xpMax or 0) > 0 then
            xp, xpMax, rested = old.xp, old.xpMax, old.rested or 0
        end
        local rec = {
            level = (event == "PLAYER_LEVEL_UP" and tonumber(arg1)) or UnitLevel("player"),
            xp = xp, xpMax = xpMax,
            rested = rested, resting = IsResting() and true or false,
            zone = GetRealZoneText(), subzone = GetSubZoneText(), hearth = GetBindLocation(),
            mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil,
        }
        return rec
    end,
})

-- ------------------------------------------------ profession skills
-- Skill and maximum for every slot, at login and when they change. Recipes
-- known stay Forgemaster's harvest (the professions view). Undocumented, but
-- Camelot's professions book walks these seven slots.

Define("skills", {
    events = { "SKILL_LINES_CHANGED" },
    read = function(event)
        if not (GetProfessions and GetProfessionInfo) then return nil end
        local slots, list = { GetProfessions() }, {}
        for i = 1, 7 do
            if slots[i] then
                local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(slots[i])
                if name then list[#list + 1] = { name = name, rank = rank, max = maxRank, line = skillLine } end
            end
        end
        -- The login read can run before the skills are there; an empty list
        -- then is not news, and must not wipe what was known.
        if #list == 0 and event == "START" then
            local old = A:Get("skills", A:Key())
            if old and old.list and #old.list > 0 then return nil end
        end
        return { list = list }
    end,
})

-- ------------------------------------------------ raid and dungeon lockouts
-- RequestRaidInfo asks, UPDATE_INSTANCE_INFO answers. Resets are kept as
-- server times so an alt's count down. Kept while locked or extended, as
-- Blizzard's Raid Info counts them.

Define("lockouts", {
    events = { "UPDATE_INSTANCE_INFO", "BOSS_KILL" },
    read = function(event)
        if event == "BOSS_KILL" or event == "START" then
            Soon("raidinfo", 3, function() if RequestRaidInfo then RequestRaidInfo() end end)
            if event == "BOSS_KILL" then return nil end
        end
        if not (GetNumSavedInstances and GetSavedInstanceInfo) then return nil end
        if event == "START" then return nil end   -- the answer comes as UPDATE_INSTANCE_INFO
        local now, list = GetServerTime(), {}
        for i = 1, GetNumSavedInstances() do
            local name, id, reset, _, locked, extended, _, isRaid, size, difficulty, bosses, killed, _, mapID =
                GetSavedInstanceInfo(i)
            if name and (locked or extended) and not IsSecret(reset) and (reset or 0) > 0 then
                list[#list + 1] = { name = name, id = id, resetAt = now + reset, raid = isRaid, size = size,
                    difficulty = difficulty, bosses = bosses, killed = killed, mapID = mapID }
            end
        end
        return { list = list }
    end,
})

-- ------------------------------------------------ profession cooldowns
-- MEASURED (/steward probe cd, 2026-09-28): GetSpellBaseCooldown gives a
-- recipe's length with no window and no profession (Mooncloth 95 h,
-- Arcanite 47 h, the elemental transmutes 23 h, Iron to Gold and Mithril to
-- Truesilver 1 h); GetRecipeCooldown says nothing with the window shut. So
-- the craft itself is recorded: the player's cast of a cooldown spell, plus
-- its base length, is when it is ready. At login C_Spell.GetSpellCooldown is
-- read for the known ones too, in case it reports a cooldown in progress
-- (unmeasured), which would catch crafts made with this collector off.
-- The Salt Shaker is an item, read by C_Container.GetItemCooldown.

A.COOLDOWN_SPELLS = {
    [18560] = true, [17187] = true, [11479] = true, [11480] = true,
    [17559] = true, [17560] = true, [17561] = true, [17562] = true,
    [17563] = true, [17564] = true, [17565] = true, [17566] = true,
}
A.COOLDOWN_ITEMS = { [15846] = true }   -- Salt Shaker
local LONG = 20 * 3600 * 1000           -- any spell this long is worth a reminder

local function BaseCooldown(spellID)
    if not GetSpellBaseCooldown then return nil end
    local ok, ms = pcall(GetSpellBaseCooldown, spellID)
    if not ok or IsSecret(ms) then return nil end
    return tonumber(ms)
end

local function SpellName(spellID)
    local get = C_Spell and C_Spell.GetSpellInfo
    local ok, info = false, nil
    if get then ok, info = pcall(get, spellID) end
    return ok and type(info) == "table" and info.name or nil
end

local function CooldownRecord()
    local key = A:Key()
    local old = key and A:Get("cooldowns", key)
    local rec = { spells = {}, items = {} }
    if old then
        for id, c in pairs(old.spells or {}) do rec.spells[id] = c end
        for id, c in pairs(old.items or {}) do rec.items[id] = c end
    end
    return rec
end

-- A cooldown still running, from C_Spell.GetSpellCooldown or an item's, as
-- a server time; nil when none is running.
local function ReadyAtFrom(start, duration)
    if IsSecret(start) or IsSecret(duration) then return nil end
    start, duration = tonumber(start) or 0, tonumber(duration) or 0
    if start <= 0 or duration <= 2 then return nil end
    return math.floor(GetServerTime() + (start + duration - GetTime()) + 0.5)
end

Define("cooldowns", {
    events = { "UNIT_SPELLCAST_SUCCEEDED", "BAG_UPDATE_COOLDOWN" },
    read = function(event, unit, _, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if unit ~= "player" or IsSecret(spellID) then return nil end
            spellID = tonumber(spellID)
            if not spellID then return nil end
            local ms = BaseCooldown(spellID)
            if not (A.COOLDOWN_SPELLS[spellID] or (ms and ms >= LONG)) then return nil end
            if not ms or ms <= 0 then return nil end
            local rec = CooldownRecord()
            rec.spells[spellID] = { name = SpellName(spellID), length = ms / 1000,
                readyAt = GetServerTime() + math.floor(ms / 1000), from = "cast" }
            return rec
        end
        -- START and BAG_UPDATE_COOLDOWN: what the client reports as running.
        local rec, changed = CooldownRecord(), event == "START"
        if event == "START" and C_Spell and C_Spell.GetSpellCooldown then
            for id in pairs(A.COOLDOWN_SPELLS) do
                local ok, cd = pcall(C_Spell.GetSpellCooldown, id)
                local at = ok and type(cd) == "table" and ReadyAtFrom(cd.startTime, cd.duration)
                if at then
                    rec.spells[id] = { name = SpellName(id), length = (BaseCooldown(id) or 0) / 1000,
                        readyAt = at, from = "login" }
                end
            end
        end
        if C_Container and C_Container.GetItemCooldown then
            for id in pairs(A.COOLDOWN_ITEMS) do
                local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(id) or 0
                if (tonumber(count) or 0) > 0 then
                    local ok, start, duration = pcall(C_Container.GetItemCooldown, id)
                    local at = ok and ReadyAtFrom(start, duration)
                    local was = rec.items[id]
                    if at and not (was and was.readyAt == at) then
                        rec.items[id] = { readyAt = at, from = "item" }
                        changed = true
                    elseif not was then
                        rec.items[id] = { readyAt = 0, from = "item" }   -- held, and ready
                        changed = true
                    end
                end
            end
        end
        return changed and rec or nil
    end,
})

-- ------------------------------------------------ mail
-- The inbox as it stands while a mailbox is open: what each mail holds, its
-- money, its COD and when it expires (a server time, so an alt's counts
-- down). The same calls Satchel's Mail.lua records with (Forever's own
-- MailFrame.lua uses them; none is in the API dump). Invoices stay
-- Satchel's log. A mailbox holds 50 at a time: `total` is what the server
-- says is waiting, `shown` what could be read, and the gap is mail that will
-- only appear as this is cleared.

local mailboxOpen = false
local MAIL_TYPE = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
local ATTACHMENTS = ATTACHMENTS_MAX_RECEIVE or 16

Define("mail", {
    events = { "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE",
        "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" },
    -- The mailbox opening and closing change what a read may do, so they are
    -- never held back behind (or dropped for) a coalesced inbox update.
    now = { MAIL_SHOW = true, MAIL_CLOSED = true, PLAYER_INTERACTION_MANAGER_FRAME_SHOW = true,
        PLAYER_INTERACTION_MANAGER_FRAME_HIDE = true },
    read = function(event, arg1)
        if event == "MAIL_SHOW" then mailboxOpen = true return nil end
        if event == "MAIL_CLOSED" then mailboxOpen = false return nil end
        if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            if MAIL_TYPE and arg1 == MAIL_TYPE then mailboxOpen = true end
            return nil
        end
        if event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            if MAIL_TYPE and arg1 == MAIL_TYPE then mailboxOpen = false end
            return nil
        end
        -- An inbox update with no mailbox open would read a stale list.
        if not (mailboxOpen and GetInboxNumItems and GetInboxHeaderInfo) then return nil end
        local shown, total = GetInboxNumItems()
        local now, mails = GetServerTime(), {}
        for i = 1, shown or 0 do
            local _, _, sender, subject, money, cod, daysLeft, itemCount, wasRead = GetInboxHeaderInfo(i)
            if not (IsSecret(sender) or IsSecret(daysLeft)) then
                local mail = {
                    sender = sender, subject = subject, money = money or 0, cod = cod or 0,
                    expires = daysLeft and (now + math.floor(daysLeft * 86400)) or nil,
                    read = wasRead and true or false, items = {},
                }
                if GetInboxItem and (itemCount or 0) > 0 then
                    for a = 1, ATTACHMENTS do
                        local _, itemID, _, count, _, _, isCurrency = GetInboxItem(i, a)
                        if itemID and not isCurrency then
                            mail.items[#mail.items + 1] = { id = itemID, count = count or 1 }
                        end
                    end
                end
                mails[#mails + 1] = mail
            end
        end
        return { shown = shown or 0, total = total or shown or 0, mails = mails }
    end,
})

-- ------------------------------------------------ bag space
-- Free and total slots in the bags carried (the backpack, four bags and the
-- reagent bag). The bank's are not read: only its counts are, and only at a
-- bank.

local LAST_BAG = (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 4

Define("space", {
    events = { "BAG_UPDATE_DELAYED" },
    read = function()
        local C = C_Container
        if not (C and C.GetContainerNumSlots and C.GetContainerNumFreeSlots) then return nil end
        local free, total = 0, 0
        for bag = 0, LAST_BAG do
            local slots = C.GetContainerNumSlots(bag)
            if slots and not IsSecret(slots) then
                total = total + slots
                free = free + (C.GetContainerNumFreeSlots(bag) or 0)
            end
        end
        if total == 0 then return nil end     -- bags not loaded yet
        return { free = free, total = total }
    end,
})

-- ============================================================
-- EVENTS
-- ============================================================

-- Mail is coalesced too: taking everything raises an inbox update per mail.
local SOON = { xp = 0.5, gold = 0.5, skills = 2, cooldowns = 1, mail = 0.5, space = 1 }

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Settled two seconds on: rested XP and the rest may not be readable
        -- in the login frame (Steward's measurement, as Muster had it).
        C_Timer.After(2, function()
            ready = true
            -- Nothing asked for: nothing made, not even an empty table.
            if not next(running) then return end
            local s = Store()
            if s then s.schema = A.SCHEMA end
            if running.chars then Run("chars", "START") end
            for name in pairs(running) do
                if name ~= "chars" then Run(name, "START") end
            end
        end)
        if not byEvent.PLAYER_LOGIN then return end
    end
    local names = byEvent[event]
    if not names then return end
    local args = { n = select("#", ...), ... }
    for name in pairs(names) do
        -- A spell cast is read at once (its arguments are the news); the
        -- rest is coalesced, and read fresh when it runs. Logout is read at
        -- once, since nothing runs after it.
        local delay = SOON[name]
        local def = collectors[name]
        if event == "PLAYER_LOGOUT" or event == "UNIT_SPELLCAST_SUCCEEDED" or not delay
            or (def and def.now and def.now[event]) then
            Run(name, event, unpack(args, 1, args.n))
        else
            Soon("run:" .. name, delay, function() Run(name, event, unpack(args, 1, args.n)) end)
        end
    end
end)
