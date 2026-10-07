--[[
  Forever Companion - Data/Biography.lua
  The autobiography of each character: statistics and a timeline of the
  moments that matter, recorded quietly in the background and shown only on
  the Autobiography page of the journal.

    travel     distance in yards (shown in km) on foot, mounted, swimming, on
               flights and as a ghost; per zone; flights taken, hearthstones
    time       online, in combat, dead, AFK, resting, grouped, on flights;
               per zone
    life       deaths (by killer and zone), longest life without dying
    fights     creatures killed (from experience messages: the combat log is
               closed to addons on this client), experience by source
    quests     turned in
    supplies   food, drink, potions, elixirs, flasks, bandages, scrolls
    wealth     money by source and by sink
    items      looted, created, received, first-time items
    trades     herbs, ore, fish, skins gathered; skill milestones
    people     duels won and lost, players grouped with, reputation gained
    misc       jumps, spells cast
    timeline   levels (with the time each took), deaths, first visits, bosses,
               rares, skill milestones, duels, guild changes, first epic item

  Stored per character in ForeverCompanionDB.bio["Name-Realm"]; every map is
  bounded so a long life never grows the SavedVariables without limit.
]]

local _, FC = ...

local Bio = FC:NewModule("Biography")

local U = FC.Utils
local L = FC.L
local Compat = FC.Compat

local TICK = 1                -- seconds between position and time samples
local MAX_STEP = 5            -- a longer gap (loading screen, lag) is not counted
local MAX_SPEED = 80          -- yards per second; anything faster was a teleport
local YARD_KM = 0.0009144
local LIMITS = { zones = 400, killers = 200, killed = 3000, items = 800, seen = 20000, grouped = 2000, rep = 150, timeline = 400 }

Bio.TRAVEL_MODES = { "foot", "mount", "swim", "taxi", "ghost" }
Bio.TIME_KINDS = { "online", "combat", "dead", "afk", "resting", "group", "taxi" }
Bio.SUPPLIES = { "food", "drink", "potion", "elixir", "flask", "bandage", "scroll", "other" }
Bio.MONEY = { "loot", "quest", "sold", "bought", "repair", "trainer", "flights", "mailIn", "mailOut", "auctionIn", "auctionOut", "tradeIn", "tradeOut", "otherIn", "otherOut" }

------------------------------------------------------------------------
-- Storage
------------------------------------------------------------------------

local function counterTable(value, keys)
    local out = {}
    for _, key in ipairs(keys) do out[key] = tonumber(type(value) == "table" and value[key]) or 0 end
    return out
end

--- Keeps only string or number keys with numbers (or tables of numbers), up to a limit.
local function numberMap(value, limit, nested)
    local out, count = {}, 0
    if type(value) ~= "table" then return out end
    for key, v in pairs(value) do
        if count >= limit then break end
        if (type(key) == "string" or type(key) == "number") then
            if nested and type(v) == "table" then
                local inner = {}
                for k2, v2 in pairs(v) do if type(k2) == "string" and type(v2) == "number" then inner[k2] = v2 end end
                out[key] = inner
                count = count + 1
            elseif not nested and (type(v) == "number" or v == true) then
                out[key] = v
                count = count + 1
            end
        end
    end
    return out
end

function Bio:NewStats()
    return self:ValidateStats({ started = U.Now() })
end

function Bio:ValidateStats(s)
    if type(s) ~= "table" then s = {} end
    local out = {
        started = tonumber(s.started) or U.Now(),
        dist = counterTable(s.dist, self.TRAVEL_MODES),
        time = counterTable(s.time, self.TIME_KINDS),
        zones = numberMap(s.zones, LIMITS.zones, true),
        deaths = tonumber(s.deaths) or 0,
        killers = numberMap(s.killers, LIMITS.killers),
        longestLife = tonumber(s.longestLife) or 0,
        lifeStart = tonumber(s.lifeStart) or 0,
        kills = tonumber(s.kills) or 0,
        killed = numberMap(s.killed, LIMITS.killed),
        xp = counterTable(s.xp, { "kill", "quest", "explore" }),
        quests = tonumber(s.quests) or 0,
        supplies = counterTable(s.supplies, self.SUPPLIES),
        supplyItems = numberMap(s.supplyItems, LIMITS.items),
        money = counterTable(s.money, self.MONEY),
        items = counterTable(s.items, { "looted", "created", "received", "unique" }),
        seen = numberMap(s.seen, LIMITS.seen),
        gather = counterTable(s.gather, { "herbalism", "mining", "fishing", "skinning" }),
        flights = tonumber(s.flights) or 0,
        hearths = tonumber(s.hearths) or 0,
        jumps = tonumber(s.jumps) or 0,
        spells = tonumber(s.spells) or 0,
        duels = counterTable(s.duels, { "won", "lost" }),
        grouped = numberMap(s.grouped, LIMITS.grouped),
        rep = numberMap(s.rep, LIMITS.rep),
        levels = numberMap(s.levels, 200, true),
        timeline = {},
    }
    if type(s.timeline) == "table" then
        for _, e in ipairs(s.timeline) do
            if type(e) == "table" and type(e.t) == "number" and type(e.k) == "string" then
                out.timeline[#out.timeline + 1] = { t = e.t, k = e.k:sub(1, 16), v = type(e.v) == "string" and e.v:sub(1, 120) or e.v, z = type(e.z) == "string" and e.z:sub(1, 64) or nil, l = tonumber(e.l) }
            end
            if #out.timeline >= LIMITS.timeline then break end
        end
    end
    return out
end

function Bio:OnInitialize()
    local all = type(FC.db.bio) == "table" and FC.db.bio or {}
    for key, stats in pairs(all) do
        if type(key) ~= "string" then all[key] = nil else all[key] = self:ValidateStats(stats) end
    end
    FC.db.bio = all
end

--- The statistics of a character (the one you play by default).
function Bio:Get(key)
    key = key or FC.Store.me
    local all = FC.db.bio
    if not all[key] then all[key] = self:NewStats() end
    return all[key]
end

--- Sums of every character (account view).
function Bio:Account()
    local total = self:NewStats()
    local oldest = total.started
    for _, stats in pairs(FC.db.bio) do
        oldest = math.min(oldest, stats.started or oldest)
        for _, group in ipairs({ "dist", "time", "xp", "supplies", "money", "items", "gather", "duels" }) do
            for k, v in pairs(stats[group]) do total[group][k] = (total[group][k] or 0) + v end
        end
        for _, field in ipairs({ "deaths", "kills", "quests", "flights", "hearths", "jumps", "spells" }) do
            total[field] = total[field] + (stats[field] or 0)
        end
        total.longestLife = math.max(total.longestLife, stats.longestLife or 0)
        for _, map in ipairs({ "killers", "killed", "supplyItems", "rep" }) do
            for k, v in pairs(stats[map]) do total[map][k] = (total[map][k] or 0) + v end
        end
        for zone, z in pairs(stats.zones) do
            local t = total.zones[zone] or {}
            for k, v in pairs(z) do t[k] = (t[k] or 0) + v end
            total.zones[zone] = t
        end
        for name in pairs(stats.grouped) do total.grouped[name] = true end
        for id in pairs(stats.seen) do total.seen[id] = true end
    end
    total.started = oldest
    total.items.unique = U.Count(total.seen)
    return total
end

-- entries per capped table, counted once and then kept up to date, so a
-- limit check costs nothing on every loot message or kill
local sizes = setmetatable({}, { __mode = "k" })

--- Whether a key may be stored in a capped table: it is already there, or
--- there is room (the caller then stores it).
local function room(map, key, limit)
    if map[key] ~= nil then return true end
    local n = sizes[map] or U.Count(map)
    if n >= limit then
        sizes[map] = n
        return false
    end
    sizes[map] = n + 1
    return true
end

local function bump(map, key, amount, limit)
    if key == nil then return end
    if limit and not room(map, key, limit) then return end
    map[key] = (map[key] or 0) + (amount or 1)
end

local function mergeField(into, field, value)
    local mine = into[field]
    if type(value) == "number" and type(mine) == "number" then
        into[field] = math.max(mine, value)
    elseif field == "timeline" then
        local seen = {}
        for _, e in ipairs(mine) do seen[e.t .. e.k] = true end
        for _, e in ipairs(value) do
            if not seen[e.t .. e.k] then mine[#mine + 1] = e end
        end
        table.sort(mine, function(a, b) return a.t > b.t end)
        for i = #mine, LIMITS.timeline + 1, -1 do mine[i] = nil end
    elseif field == "levels" then
        for level, data in pairs(value) do
            if mine[level] == nil then mine[level] = data end
        end
    elseif type(value) == "table" and type(mine) == "table" then
        local limit = LIMITS[field == "supplyItems" and "items" or field] or 1000
        for k, v in pairs(value) do
            if type(v) == "table" then
                if room(mine, k, limit) then
                    local t = mine[k] or {}
                    for k2, v2 in pairs(v) do t[k2] = math.max(t[k2] or 0, v2) end
                    mine[k] = t
                end
            elseif v == true then
                if room(mine, k, limit) then mine[k] = true end
            elseif type(v) == "number" and (type(mine[k]) == "number" or mine[k] == nil) and room(mine, k, limit) then
                mine[k] = math.max(mine[k] or v, v)
            end
        end
    end
end

--- Merges a character's statistics from a backup: every counter keeps the
--- larger value and lists are joined, so restoring the same backup twice
--- changes nothing and a restore after a reinstall brings the old totals back.
function Bio:Merge(key, from)
    if type(key) ~= "string" or type(from) ~= "table" then return false end
    from = self:ValidateStats(from)
    local into = FC.db.bio[key]
    if not into then
        FC.db.bio[key] = from
        return true
    end
    -- the current life is measured in time online: it follows whichever
    -- side has the longer time online
    local lifeStart = from.time.online > into.time.online and from.lifeStart or into.lifeStart
    local started = math.min(into.started, from.started)
    for field, value in pairs(from) do mergeField(into, field, value) end
    into.started, into.lifeStart = started, lifeStart
    return true
end

--- A character's statistics as they go into a backup: the list of every
--- item ID ever looted stays out (it is only used to count new items).
function Bio:BackupCopy()
    local out = {}
    for key, stats in pairs(FC.db.bio) do
        local copy = U.CopyTable(stats)
        copy.seen = nil
        out[key] = copy
    end
    return out
end

function Bio:Event(kind, value)
    local s = self:Get()
    local zone = Compat.GetZoneTexts()
    table.insert(s.timeline, 1, {
        t = U.Now(), k = kind, v = value,
        z = zone ~= "" and zone or nil,
        l = Compat.SafeCall(_G.UnitLevel, "player"),
    })
    for i = #s.timeline, LIMITS.timeline + 1, -1 do s.timeline[i] = nil end
    FC.Bus:Emit("BIOGRAPHY_EVENT", kind, value)
end

function Bio:Enabled()
    return FC.P.biography.enabled
end

------------------------------------------------------------------------
-- Sampling: travel and time
------------------------------------------------------------------------

local function travelMode()
    if Compat.SafeCall(_G.UnitOnTaxi, "player") then return "taxi" end
    if Compat.SafeCall(_G.UnitIsGhost, "player") then return "ghost" end
    if Compat.SafeCall(_G.IsSwimming) then return "swim" end
    if Compat.SafeCall(_G.IsMounted) then return "mount" end
    return "foot"
end

--- Where the player is, in yards: world coordinates when the client gives
--- them, else map coordinates scaled by the map's size (same map only).
local function position()
    local north, west, instance = Compat.GetPlayerWorldPosition()
    if north then return north, west, "w" .. tostring(instance) end
    local mapID, x, y = Compat.GetPlayerPosition()
    if not mapID then return nil end
    local width, height = Compat.GetMapWorldSize(mapID)
    if x and width then return y * height, x * width, "m" .. mapID end
    return nil
end

function Bio:Sample()
    if not self:Enabled() then return end
    local now = GetTime()
    local elapsed = self.lastSample and (now - self.lastSample) or 0
    self.lastSample = now
    if elapsed <= 0 or elapsed > MAX_STEP then
        self.lastPos = nil
        return
    end
    local s = self:Get()
    local zone = Compat.GetZoneTexts()
    zone = zone ~= "" and zone or nil
    local zoneStats
    if zone then
        zoneStats = s.zones[zone]
        if not zoneStats and room(s.zones, zone, LIMITS.zones) then
            zoneStats = {}
            s.zones[zone] = zoneStats
            self:Event("zone", zone)
        end
    end

    -- time
    local t = s.time
    t.online = t.online + elapsed
    if Compat.InCombat() or Compat.SafeCall(_G.UnitAffectingCombat, "player") then t.combat = t.combat + elapsed end
    if Compat.SafeCall(_G.UnitIsDeadOrGhost, "player") then t.dead = t.dead + elapsed end
    if Compat.SafeCall(_G.UnitIsAFK, "player") then t.afk = t.afk + elapsed end
    if Compat.IsResting() then t.resting = t.resting + elapsed end
    if Compat.IsInGroup() then t.group = t.group + elapsed end
    local onTaxi = Compat.SafeCall(_G.UnitOnTaxi, "player")
    if onTaxi then t.taxi = t.taxi + elapsed end
    if onTaxi and not self.wasOnTaxi then s.flights = s.flights + 1 end
    self.wasOnTaxi = onTaxi and true or false
    if zoneStats then zoneStats.t = (zoneStats.t or 0) + elapsed end

    -- distance
    local north, west, space = position()
    local last = self.lastPos
    self.lastPos = north and { north, west, space } or nil
    if not (north and last and last[3] == space) then return end
    local dn, dw = north - last[1], west - last[2]
    local step = math.sqrt(dn * dn + dw * dw)
    if step < 0.05 or step / elapsed > MAX_SPEED then return end
    local mode = travelMode()
    s.dist[mode] = s.dist[mode] + step
    if zoneStats then zoneStats.d = (zoneStats.d or 0) + step end
end

------------------------------------------------------------------------
-- Life and death, fights, quests, levels
------------------------------------------------------------------------

function Bio:OnDeath()
    local s = self:Get()
    s.deaths = s.deaths + 1
    local life = s.time.online - (s.lifeStart or 0)
    if life > s.longestLife then s.longestLife = life end
    s.lifeStart = s.time.online
    -- the killer: the enemy you are targeting, or the last one you fought
    local target = Compat.GetUnitInfo("target")
    local killer = target and not target.isPlayer and Compat.CanAttack("target") and target.name or nil
    if not killer and self.lastEnemy and GetTime() - self.lastEnemy.at < 30 then killer = self.lastEnemy.name end
    if killer then bump(s.killers, killer, 1, LIMITS.killers) end
    local zone = Compat.GetZoneTexts()
    if zone ~= "" and s.zones[zone] then s.zones[zone].deaths = (s.zones[zone].deaths or 0) + 1 end
    self:Event("death", killer)
end

local patterns

--- All captures of a pattern (nil pattern: no match). `a and s:match(p)`
--- would keep only the first capture.
local function match(text, pattern)
    if not pattern then return nil end
    return text:match(pattern)
end

--- Lua patterns for the client's message templates, anchored at the start
--- and cut after the first number, so every variant of a message matches.
local function prefixPattern(name)
    local template = _G[name]
    if type(template) ~= "string" then return nil end
    local cut = template:find("%%%d?%$?d")
    if cut then
        local rest = template:sub(cut):match("^%%%d?%$?d")
        template = template:sub(1, cut - 1 + #rest)
    end
    template = template:gsub("%%%d?%$?", "%%")
    template = template:gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")
    template = template:gsub("%%s", "(.-)"):gsub("%%d", "(%%d+)")
    return "^" .. template
end

local function buildPatterns()
    patterns = {
        xpKill = { prefixPattern("COMBATLOG_XPGAIN_FIRSTPERSON"), prefixPattern("COMBATLOG_XPGAIN_EXHAUSTION1"), prefixPattern("COMBATLOG_XPGAIN_FIRSTPERSON_GROUP") },
        explored = prefixPattern("ERR_ZONE_EXPLORED_XP"),
        loot = { { prefixPattern("LOOT_ITEM_SELF_MULTIPLE"), "looted" }, { prefixPattern("LOOT_ITEM_SELF"), "looted" },
                 { prefixPattern("LOOT_ITEM_CREATED_SELF_MULTIPLE"), "created" }, { prefixPattern("LOOT_ITEM_CREATED_SELF"), "created" },
                 { prefixPattern("LOOT_ITEM_PUSHED_SELF_MULTIPLE"), "received" }, { prefixPattern("LOOT_ITEM_PUSHED_SELF"), "received" } },
        duelWin = Compat.PatternFromGlobal("DUEL_WINNER_KNOCKOUT"),
        duelRetreat = Compat.PatternFromGlobal("DUEL_WINNER_RETREAT"),
        skill = prefixPattern("SKILL_RANK_UP"),
        rep = prefixPattern("FACTION_STANDING_INCREASED"),
    }
end

function Bio:OnXPMessage(text)
    text = Compat.Safe(text)
    if type(text) ~= "string" then return end
    if not patterns then buildPatterns() end
    for _, pattern in ipairs(patterns.xpKill) do
        local name, xp = match(text, pattern)
        if name then
            local s = self:Get()
            s.kills = s.kills + 1
            s.xp.kill = s.xp.kill + (tonumber(xp) or 0)
            bump(s.killed, name, 1, LIMITS.killed)
            return
        end
    end
end

function Bio:OnSystemMessage(text)
    text = Compat.Safe(text)
    if type(text) ~= "string" then return end
    if not patterns then buildPatterns() end
    local s = self:Get()
    local _, xp = match(text, patterns.explored)
    if xp then s.xp.explore = s.xp.explore + (tonumber(xp) or 0) end
    local winner, loser = match(text, patterns.duelWin)
    if not winner then
        -- "%2$s has fled from %1$s in a duel": the first name printed is the loser
        loser, winner = match(text, patterns.duelRetreat)
    end
    -- the game names you with or without your surname, never by your journal key
    local me, first = Compat.GetUnitDisplayName("player") or U.ShortName(FC.Store.me), Compat.SafeCall(_G.UnitName, "player")
    local function isMe(name) return name ~= nil and (name == me or name == first) end
    if winner and (isMe(winner) or isMe(loser)) then
        local won = isMe(winner)
        s.duels[won and "won" or "lost"] = s.duels[won and "won" or "lost"] + 1
        self:Event(won and "duelWon" or "duelLost", won and loser or winner)
    end
end

function Bio:OnSkillMessage(text)
    text = Compat.Safe(text)
    if type(text) ~= "string" then return end
    if not patterns then buildPatterns() end
    local skill, rank = match(text, patterns.skill)
    rank = tonumber(rank)
    if skill and rank and rank % 75 == 0 then self:Event("skill", skill .. " " .. rank) end
end

function Bio:OnFactionMessage(text)
    text = Compat.Safe(text)
    if type(text) ~= "string" then return end
    if not patterns then buildPatterns() end
    local faction, amount = match(text, patterns.rep)
    if faction then bump(self:Get().rep, faction, tonumber(amount) or 0, LIMITS.rep) end
end

function Bio:OnLootMessage(text)
    text = Compat.Safe(text)
    if type(text) ~= "string" then return end
    if not patterns then buildPatterns() end
    for _, entry in ipairs(patterns.loot) do
        local link, count = match(text, entry[1])
        if link then
            local s = self:Get()
            local amount = tonumber(count) or 1
            s.items[entry[2]] = s.items[entry[2]] + amount
            local itemID = Compat.GetItemIDFromLink(link)
            if itemID and not s.seen[itemID] and room(s.seen, itemID, LIMITS.seen) then
                s.seen[itemID] = true
                s.items.unique = s.items.unique + 1
                local info = Compat.GetItemInfo(itemID)
                if info and (info.quality or 0) >= 4 then self:Event("epic", info.name) end
            end
            return
        end
    end
end

function Bio:OnLevelUp(level)
    level = tonumber(Compat.Safe(level))
    if not level then return end
    local s = self:Get()
    local previous
    for l, data in pairs(s.levels) do
        if tonumber(l) and tonumber(l) < level and (not previous or tonumber(l) > previous.level) then
            previous = { level = tonumber(l), online = data.o }
        end
    end
    local took = previous and previous.online and (s.time.online - previous.online) or nil
    s.levels[level] = { o = s.time.online, at = U.Now(), took = took }
    self:Event("level", took and string.format(L.BIO_LEVEL_TOOK, level, U.FormatLongDuration(took)) or tostring(level))
    if FC.P.biography.screenshots and _G.Screenshot then U.After(1, function() pcall(_G.Screenshot) end) end
end

------------------------------------------------------------------------
-- Supplies: which of the consumables in your bags a spell belongs to
------------------------------------------------------------------------

local SUPPLY_BY_SUBCLASS = { [1] = "potion", [2] = "elixir", [3] = "flask", [4] = "scroll", [5] = "food", [7] = "bandage" }

function Bio:ScanBags()
    local map = {}
    local container = _G.C_Container
    if not (container and container.GetContainerNumSlots and container.GetContainerItemID) then
        self.supplySpells = map
        return
    end
    for bag = 0, 5 do
        for slot = 1, Compat.SafeCall(container.GetContainerNumSlots, bag) or 0 do
            local itemID = Compat.SafeCall(container.GetContainerItemID, bag, slot)
            if itemID and not map[itemID] then
                local instant = Compat.GetItemInfoInstant(itemID)
                if instant and instant.classID == 0 then
                    local getSpell = (C_Item and C_Item.GetItemSpell) or _G.GetItemSpell
                    local _, spellID = Compat.SafeCall(getSpell, itemID)
                    if type(spellID) == "number" then
                        map[spellID] = { itemID = itemID, kind = SUPPLY_BY_SUBCLASS[instant.subClassID] or "other" }
                    end
                end
            end
        end
    end
    self.supplySpells = map
end

local HEARTHSTONE = 8690

function Bio:OnSpellCast(unit, spellID)
    if unit ~= "player" then return end
    spellID = Compat.Safe(spellID)
    if type(spellID) ~= "number" then return end
    local s = self:Get()
    s.spells = s.spells + 1
    if spellID == HEARTHSTONE then s.hearths = s.hearths + 1 end
    local supply = self.supplySpells and self.supplySpells[spellID]
    if supply then
        local kind = supply.kind
        if kind == "food" then
            local name = Compat.GetSpellName(spellID) or ""
            local drink = _G.DRINK or "Drink"
            if name:find(drink, 1, true) then kind = "drink" end
        end
        s.supplies[kind] = s.supplies[kind] + 1
        bump(s.supplyItems, supply.itemID, 1, LIMITS.items)
    end
end

------------------------------------------------------------------------
-- Wealth: every change of money, filed by what was open at the time
------------------------------------------------------------------------

function Bio:OnMoney()
    local money = Compat.SafeCall(_G.GetMoney)
    if type(money) ~= "number" then return end
    local last = self.lastMoney
    self.lastMoney = money
    if not last or money == last then return end
    local delta = money - last
    local m = self:Get().money
    local context = self.moneyContext
    local key
    if self.questMoney and delta > 0 then
        key = "quest"
        self.questMoney = nil
    elseif self.repairing and delta < 0 then
        key = "repair"
        self.repairing = nil
    elseif context == "loot" and delta > 0 then
        key = "loot"
    elseif context == "merchant" then
        key = delta > 0 and "sold" or "bought"
    elseif context == "mail" then
        key = delta > 0 and "mailIn" or "mailOut"
    elseif context == "auction" then
        key = delta > 0 and "auctionIn" or "auctionOut"
    elseif context == "trade" then
        key = delta > 0 and "tradeIn" or "tradeOut"
    elseif context == "trainer" and delta < 0 then
        key = "trainer"
    elseif context == "taxi" and delta < 0 then
        key = "flights"
    else
        key = delta > 0 and "otherIn" or "otherOut"
    end
    m[key] = m[key] + math.abs(delta)
end

local CONTEXTS = {
    LOOT_OPENED = "loot", MERCHANT_SHOW = "merchant", MAIL_SHOW = "mail", AUCTION_HOUSE_SHOW = "auction",
    TRADE_SHOW = "trade", TRAINER_SHOW = "trainer", TAXIMAP_OPENED = "taxi",
}
local CONTEXT_CLOSED = {
    LOOT_CLOSED = "loot", MERCHANT_CLOSED = "merchant", MAIL_CLOSED = "mail", AUCTION_HOUSE_CLOSED = "auction",
    TRADE_CLOSED = "trade", TRAINER_CLOSED = "trainer", TAXIMAP_CLOSED = "taxi",
}

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function Bio:OnEnable()
    local E = FC.Events
    local function on(event, fn)
        E:Register(event, self, function(_, ...)
            if self:Enabled() then fn(...) end
        end)
    end
    self.lastMoney = Compat.SafeCall(_G.GetMoney)
    self.ticker = C_Timer.NewTicker(TICK, function() FC:SafeCall("Biography:Sample", self.Sample, self) end)
    on("PLAYER_DEAD", function() self:OnDeath() end)
    -- remember who you fight, for the death that may follow
    local function noteEnemy()
        local target = Compat.GetUnitInfo("target")
        if target and not target.isPlayer and not target.isDead and Compat.CanAttack("target") and target.name then
            self.lastEnemy = { name = target.name, at = GetTime() }
        end
    end
    on("PLAYER_TARGET_CHANGED", noteEnemy)
    on("PLAYER_REGEN_DISABLED", noteEnemy)
    on("CHAT_MSG_COMBAT_XP_GAIN", function(_, text) self:OnXPMessage(text) end)
    on("CHAT_MSG_SYSTEM", function(_, text) self:OnSystemMessage(text) end)
    on("UI_INFO_MESSAGE", function(_, _, text) self:OnSystemMessage(text) end)
    on("CHAT_MSG_SKILL", function(_, text) self:OnSkillMessage(text) end)
    on("CHAT_MSG_COMBAT_FACTION_CHANGE", function(_, text) self:OnFactionMessage(text) end)
    on("CHAT_MSG_LOOT", function(_, text) self:OnLootMessage(text) end)
    on("PLAYER_LEVEL_UP", function(_, level) self:OnLevelUp(level) end)
    on("QUEST_TURNED_IN", function(_, _, xp, money)
        local s = self:Get()
        s.quests = s.quests + 1
        s.xp.quest = s.xp.quest + (tonumber(Compat.Safe(xp)) or 0)
        if (tonumber(Compat.Safe(money)) or 0) > 0 then self.questMoney = true end
    end)
    on("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID) self:OnSpellCast(unit, spellID) end)
    on("BAG_UPDATE_DELAYED", function() U.Debounce("bio-bags", 1, function() self:ScanBags() end) end)
    on("PLAYER_MONEY", function() self:OnMoney() end)
    for event, context in pairs(CONTEXTS) do on(event, function() self.moneyContext = context end) end
    for event, context in pairs(CONTEXT_CLOSED) do
        on(event, function()
            if self.moneyContext == context then
                -- money from the last loot or sale arrives right after the window closes
                U.After(0.5, function() if self.moneyContext == context then self.moneyContext = nil end end)
            end
        end)
    end
    on("GROUP_ROSTER_UPDATE", function()
        local s = self:Get()
        local prefix = Compat.IsInRaid() and "raid" or "party"
        for i = 1, 40 do
            -- with the surname on Forever: two players may share a first name
            local name = Compat.GetUnitDisplayName(prefix .. i)
            if type(name) == "string" and name ~= "" and not s.grouped[name] and room(s.grouped, name, LIMITS.grouped) then
                s.grouped[name] = true
            end
        end
    end)
    on("PLAYER_GUILD_UPDATE", function()
        local guild = Compat.GetGuildName()
        if guild ~= self.guild then
            if guild and self.guild ~= nil then self:Event("guild", guild) end
            self.guild = guild
        end
    end)
    on("ENCOUNTER_END", function(_, _, name, _, _, success)
        if Compat.Safe(success) == 1 and type(Compat.Safe(name)) == "string" then
            self:Event("boss", name)
            if FC.P.biography.screenshots and _G.Screenshot then U.After(1, function() pcall(_G.Screenshot) end) end
        end
    end)
    FC.Bus:On("RARE_DEFEATED", self, function(_, rec)
        if self:Enabled() then self:Event("rare", rec.n) end
    end)
    FC.Bus:On("FLIGHT_PATH_LEARNED", self, function(_, place)
        if self:Enabled() then self:Event("flightpath", place) end
    end)
    FC.Bus:On("GATHERED", self, function(_, profession)
        local s = self:Get()
        if self:Enabled() and s.gather[profession] then s.gather[profession] = s.gather[profession] + 1 end
    end)
    if _G.hooksecurefunc and _G.JumpOrAscendStart then
        hooksecurefunc("JumpOrAscendStart", function()
            if self:Enabled() then
                local s = self:Get()
                s.jumps = s.jumps + 1
            end
        end)
    end
    if _G.hooksecurefunc and _G.RepairAllItems then
        hooksecurefunc("RepairAllItems", function() self.repairing = true end)
    end
    self.guild = Compat.GetGuildName()
    U.After(3, function() self:ScanBags() end)
end

------------------------------------------------------------------------
-- Reading (for the Autobiography page)
------------------------------------------------------------------------

function Bio.Km(yards)
    return (yards or 0) * YARD_KM
end

--- A map's entries as a list sorted by value, largest first: { { key, value } }.
function Bio.Top(map, count, field)
    local list = {}
    for key, value in pairs(map or {}) do
        local v = field and type(value) == "table" and value[field] or value
        if type(v) == "number" and v > 0 then list[#list + 1] = { key = key, value = v } end
    end
    table.sort(list, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return tostring(a.key) < tostring(b.key)
    end)
    for i = #list, (count or #list) + 1, -1 do list[i] = nil end
    return list
end

--- The quests a character completed (nil: all your characters together).
--- The autobiography counts the quests it saw turned in; the game lists the
--- ones a character completed, also without the addon. The larger number is
--- the truer one, so this page and the Progress page do not disagree after
--- a reinstall.
function Bio:QuestsCompleted(key)
    local chars = FC.db.characters or {}
    local function of(k)
        local stats, char = FC.db.bio[k], chars[k]
        return math.max(stats and stats.quests or 0, char and U.Count(char.q) or 0)
    end
    if key then return of(key) end
    local keys, total = {}, 0
    for k in pairs(FC.db.bio) do keys[k] = true end
    for k in pairs(chars) do keys[k] = true end
    for k in pairs(keys) do total = total + of(k) end
    return total
end

function Bio:TotalDistance(s)
    local total = 0
    for _, v in pairs(s.dist) do total = total + v end
    return total
end
