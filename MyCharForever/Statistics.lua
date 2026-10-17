local addonName, MCF = ...
-- Reads the game's own Statistics pane (character page > Statistics). The client keeps lifetime
-- totals there (kills, deaths, quests, gold, damage and healing records ...), so a character gets
-- correct numbers even for the time before the addon was installed. Nothing here needs the
-- combat log. Secret values are never stored; nothing is read during combat.
--
-- db.statistics = {
--   categories = {[id] = {name, parent, stats = {statIDs}}}, names = {[statID] = name}, order = {categoryIDs},
--   baseline = {time, level, values}   -- first read ever
--   levelEnd = {time, level, values}   -- values when the last level was finished
--   current  = {time, level, values}   -- latest read (login, level-up, /mcf stats)
--   byLevel  = {[level] = {[statID] = value}}  -- only what changed during that level
-- }
-- Values are exactly what the game shows (strings such as "1,234"); "--" and empty ones are skipped.

local Readable = MCF.Readable
local LOGIN_DELAY, LEVELUP_DELAY = 12, 5 -- seconds; the pane is slow to fill right after login
local MAX_STATS, MAX_ERRORS = 3000, 5
local API_NAMES = {"GetStatisticsCategoryList", "GetCategoryInfo", "GetCategoryNumAchievements", "GetAchievementInfo", "GetStatistic"}

local function store()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    db.statistics = db.statistics or {}
    local s = db.statistics
    s.categories, s.names, s.order, s.byLevel = s.categories or {}, s.names or {}, s.order or {}, s.byLevel or {}
    return s
end

local function missingApi()
    local missing = {}
    for _, name in ipairs(API_NAMES) do if type(_G[name]) ~= "function" then missing[#missing + 1] = name end end
    return missing
end

-- Reads the whole pane. Returns {categories, order, names, values, stats, secret, errors, missing}.
function MCF:ReadStatistics()
    local res = {categories = {}, order = {}, names = {}, values = {}, stats = 0, secret = 0, errors = {}, missing = missingApi()}
    local function fail(msg) if #res.errors < MAX_ERRORS then res.errors[#res.errors + 1] = tostring(msg) end end
    if #res.missing > 0 then return res end
    local ok, list = pcall(GetStatisticsCategoryList)
    if not ok or type(list) ~= "table" then fail(list); return res end
    for _, rawID in ipairs(list) do
        local catID = Readable(rawID)
        if type(catID) == "number" then
            local okInfo, title, parent = pcall(GetCategoryInfo, catID)
            local cat = {name = okInfo and Readable(title) or nil, parent = okInfo and Readable(parent) or nil, stats = {}}
            res.categories[catID] = cat
            res.order[#res.order + 1] = catID
            local okNum, total = pcall(GetCategoryNumAchievements, catID)
            total = okNum and Readable(total) or 0
            if type(total) ~= "number" then total = 0 end
            for index = 1, total do
                if res.stats >= MAX_STATS then break end
                local okA, id, name = pcall(GetAchievementInfo, catID, index)
                id = okA and Readable(id) or nil
                if type(id) == "number" then
                    res.stats = res.stats + 1
                    cat.stats[#cat.stats + 1] = id
                    res.names[id] = okA and Readable(name) or nil
                    local okS, raw = pcall(GetStatistic, id)
                    if not okS then
                        fail(raw)
                    else
                        local v = Readable(raw)
                        if v == nil then res.secret = res.secret + 1
                        elseif v ~= "" and v ~= "--" then res.values[id] = v end
                    end
                elseif not okA then
                    fail(id)
                end
            end
        end
    end
    return res
end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- Stores a read. `finishedLevel` (level-up) files what changed since the last level under that level.
function MCF:SnapshotStatistics(finishedLevel)
    if inCombat() then return false, "combat" end
    local s = store()
    if not s then return false, "no-db" end
    local res = self:ReadStatistics()
    if res.stats == 0 or next(res.values) == nil then return false, "empty", res end
    local now, level = time(), UnitLevel("player")
    s.categories, s.names, s.order = res.categories, res.names, res.order
    s.current = {time = now, level = level, values = res.values}
    if not s.baseline then
        s.baseline = {time = now, level = level, values = res.values}
        s.levelEnd = {time = now, level = level, values = res.values}
    elseif finishedLevel then
        local changed, before = {}, s.levelEnd and s.levelEnd.values or {}
        for id, v in pairs(res.values) do if before[id] ~= v then changed[id] = v end end
        if next(changed) then s.byLevel[finishedLevel] = changed end
        s.levelEnd = {time = now, level = level, values = res.values}
    end
    return true, nil, res
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local pendingLevel -- finished level whose read was postponed because of combat
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(_, event, arg)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(LOGIN_DELAY, function() pcall(MCF.SnapshotStatistics, MCF, nil) end)
    elseif event == "PLAYER_LEVEL_UP" then
        local finished = (tonumber(arg) or UnitLevel("player")) - 1
        C_Timer.After(LEVELUP_DELAY, function()
            local ok, reason = MCF:SnapshotStatistics(finished)
            if not ok and reason == "combat" then pendingLevel = finished end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" and pendingLevel then
        local finished = pendingLevel
        pendingLevel = nil
        C_Timer.After(2, function() pcall(MCF.SnapshotStatistics, MCF, finished) end)
    end
end)

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------
local function out(msg) print("|cff00ccffMyCharForever|r: " .. msg) end
local function de() return MCF:GetLanguage() == "deDE" end

MCF:AddCommand{group = "main", usage = "/mcf stats", key = "stats",
    de = "Statistik-Seite des Spiels jetzt einlesen und speichern",
    en = "Read and store the game's Statistics pane now",
    run = function()
        local ok, reason, res = MCF:SnapshotStatistics(nil)
        if ok then
            local n = 0
            for _ in pairs(res.values) do n = n + 1 end
            out((de() and "Statistik gespeichert: " or "Statistics stored: ") .. n .. (de() and " Werte in " or " values in ") .. #res.order .. (de() and " Kategorien." or " categories."))
        elseif reason == "combat" then
            out(de() and "Im Kampf nicht möglich, bitte später erneut." or "Not possible during combat, try again later.")
        else
            out((de() and "Statistik nicht lesbar (" or "Statistics not readable (") .. tostring(reason) .. "). /mcf statprobe")
        end
    end}

MCF:AddCommand{group = "debug", usage = "/mcf statprobe [text]", example = "/mcf statprobe damage",
    de = "Statistik-Schnittstelle prüfen; mit Text die passende Kategorie samt Werten auflisten (bitte Ausgabe schicken)",
    en = "Check the statistics interface; with text list the matching category and its values (please send the output)",
    match = function(msg) return msg == "statprobe" or msg:match("^statprobe%s+.+$") ~= nil end,
    run = function(msg)
        local filter = msg:match("^statprobe%s+(.+)$")
        local res = MCF:ReadStatistics()
        if #res.missing > 0 then out((de() and "Fehlende Funktionen: " or "Missing functions: ") .. table.concat(res.missing, ", ")); return end
        local values = 0
        for _ in pairs(res.values) do values = values + 1 end
        out(string.format(de() and "%d Kategorien, %d Statistiken, %d mit Wert, %d geheim, %d Fehler" or "%d categories, %d statistics, %d with a value, %d secret, %d errors",
            #res.order, res.stats, values, res.secret, #res.errors))
        for i = 1, math.min(3, #res.errors) do out("  " .. res.errors[i]) end
        local lines = 0
        for _, catID in ipairs(res.order) do
            local cat = res.categories[catID]
            local name = tostring(cat.name or "?")
            if not filter then
                if lines < 40 then out(string.format("  %s %s (%d)", catID, name, #cat.stats)) end
                lines = lines + 1
            elseif name:lower():find(filter:lower(), 1, true) then
                out("|cffffd200" .. name .. "|r (" .. catID .. ")")
                for _, id in ipairs(cat.stats) do
                    if lines < 60 then out(string.format("  %s = %s", tostring(res.names[id] or id), tostring(res.values[id] or "--"))) end
                    lines = lines + 1
                end
            end
        end
        if lines > 60 or (not filter and lines > 40) then out("  ... (" .. lines .. ")") end
        if filter and lines == 0 then out(de() and "Keine Kategorie mit diesem Text." or "No category matches that text.") end
    end}
