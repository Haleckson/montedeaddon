local C = _G.Chronicle
local U = {}
C.Util = U

function U.Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

function U.CopyDefaults(target, defaults)
    if type(target) ~= "table" then target = {} end
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = U.CopyDefaults({}, value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            U.CopyDefaults(target[key], value)
        end
    end
    return target
end

function U.PushLimited(list, value, maximum)
    table.insert(list, 1, value)
    while #list > maximum do table.remove(list) end
end

function U.SafeText(value, fallback)
    if value == nil or value == "" then return fallback or "Unbekannt" end
    return tostring(value)
end

function U.Money(copper, plain)
    copper = tonumber(copper) or 0
    local sign = copper < 0 and "-" or ""
    copper = math.floor(math.abs(copper))
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local coins = copper % 100
    if plain then return string.format("%s%dg %ds %dc", sign, gold, silver, coins) end
    local parts = {}
    if gold > 0 then parts[#parts + 1] = "|cffffd700" .. gold .. "g|r" end
    if silver > 0 then parts[#parts + 1] = "|cffc7d1da" .. silver .. "s|r" end
    if coins > 0 or #parts == 0 then parts[#parts + 1] = "|cffb87333" .. coins .. "c|r" end
    return sign .. table.concat(parts, " ")
end

function U.IsLogoutMoneyGlitch(character, entry)
    if type(character) ~= "table" or type(entry) ~= "table" then return false end
    local timestamp = tonumber(entry.time)
    local balance = tonumber(entry.balance)
    local delta = tonumber(entry.delta)
    if not timestamp or balance ~= 0 or not delta or delta >= 0 then return false end
    if timestamp == character.lastLogout or timestamp == character.lastSessionEnd or
        timestamp == character.lastLogoutBeforeUIReload then return true end
    -- Vor der Korrektur am 22.09.2026 meldete Forever beim Logout teils den ganzen Geldbeutel als 0.
    -- Historische Nullbuchungen bleiben gespeichert und sind in der Goldansicht einblendbar.
    return timestamp < 1790083200 and delta <= -1000
end

function U.Date(timestamp, short)
    return date(short and "%d.%m. %H:%M" or "%d.%m.%Y %H:%M", timestamp or time())
end

function U.Count(tableValue)
    local count = 0
    for _ in pairs(tableValue or {}) do count = count + 1 end
    return count
end

function U.IsWorldNPC(row)
    return type(row) == "table" and (type(row.guid) ~= "string" or not row.guid:match("^Pet%-"))
end

function U.IsKnownZone(name)
    return type(name) == "string" and U.Trim(name) ~= "" and name ~= "Unbekannt"
end

function U.SortedPairsByTime(tableValue)
    local rows = {}
    for key, value in pairs(tableValue or {}) do
        rows[#rows + 1] = { key = key, value = value }
    end
    table.sort(rows, function(a, b)
        return (a.value.lastSeen or a.value.updated or 0) > (b.value.lastSeen or b.value.updated or 0)
    end)
    return rows
end

function U.UnitGUIDID(guid)
    if type(guid) ~= "string" then return nil end
    local _, _, _, _, _, id = strsplit("-", guid)
    return tonumber(id)
end

function U.LootVisible(entry)
    if type(entry) ~= "table" then return false end
    if entry.isQuestItem then return true end
    local quality = tonumber(entry.quality)
    if not quality and type(entry.link) == "string" then
        quality = tonumber(entry.link:match("|cnIQ(%d+):"))
    end
    return quality ~= nil and quality >= 2
end

function U.Statistics(character)
    local c = character or {}
    local stats = {
        memories = #(c.events or {}), activeQuests = U.Count(c.activeQuests),
        questCompletions = 0, zones = 0, npcs = 0, merchants = 0,
        rares = U.Count(c.rares), recipes = 0, dungeons = 0, dungeonVisits = 0,
        bosses = 0, bossAttempts = 0, bossKills = 0, loot = 0,
        openGoals = 0, completedGoals = 0, notes = #(c.notes or {}),
        deaths = math.max(tonumber(c.stats and c.stats.deathCount) or 0, #(c.deaths or {})),
    }
    for _, quest in ipairs(c.quests or {}) do
        if quest.status == "completed" then stats.questCompletions = stats.questCompletions + 1 end
    end
    for zone in pairs(c.zones or {}) do
        if U.IsKnownZone(zone) then stats.zones = stats.zones + 1 end
    end
    for _, npc in pairs(c.npcs or {}) do
        if U.IsWorldNPC(npc) then
            stats.npcs = stats.npcs + 1
            if npc.merchant then stats.merchants = stats.merchants + 1 end
        end
    end
    for _, recipes in pairs(c.recipes or {}) do stats.recipes = stats.recipes + U.Count(recipes) end
    for _, dungeon in pairs(c.dungeons or {}) do
        stats.dungeons = stats.dungeons + 1
        stats.dungeonVisits = stats.dungeonVisits + (tonumber(dungeon.entries) or 0)
    end
    for _, boss in pairs(c.bosses or {}) do
        stats.bosses = stats.bosses + 1
        stats.bossAttempts = stats.bossAttempts + (tonumber(boss.attempts) or 0)
        stats.bossKills = stats.bossKills + (tonumber(boss.kills) or 0)
    end
    for _, entry in ipairs(c.loot or {}) do
        if U.LootVisible(entry) then stats.loot = stats.loot + 1 end
    end
    for _, goal in ipairs(c.goals or {}) do
        if goal.done then stats.completedGoals = stats.completedGoals + 1
        else stats.openGoals = stats.openGoals + 1 end
    end
    return stats
end
