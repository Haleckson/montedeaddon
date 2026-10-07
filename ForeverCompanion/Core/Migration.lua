--[[
  Forever Companion - Core/Migration.lua
  Ordered, idempotent schema upgrades for both SavedVariables tables.

  To change the schema in a future version:
    1. bump C.DB_VERSION (or C.CHAR_DB_VERSION)
    2. add Migration.account[N] = function(db) ... end, where N is the new version
  A migration receives the table at version N-1 and must leave it at version N.
  Migrations run inside SafeCall; on failure the database keeps the last good
  version number and the addon continues with validated data.
]]

local _, FC = ...

local Migration = {}
FC.Migration = Migration


Migration.account = {}
Migration.character = {}

-- Migration_001: establishes the version 1 layout. Databases written before a
-- schema number existed (developer builds) are normalized into it.
Migration.account[1] = function(db)
    db.meta = type(db.meta) == "table" and db.meta or {}
    db.profileKeys = type(db.profileKeys) == "table" and db.profileKeys or {}
    db.profiles = type(db.profiles) == "table" and db.profiles or {}
    db.discoveries = type(db.discoveries) == "table" and db.discoveries or {}
    db.userState = type(db.userState) == "table" and db.userState or {}
    db.tagColors = type(db.tagColors) == "table" and db.tagColors or {}
    db.customThemes = type(db.customThemes) == "table" and db.customThemes or {}
    db.myChars = type(db.myChars) == "table" and db.myChars or {}
    db.sync = type(db.sync) == "table" and db.sync or {}
    db.milestones = type(db.milestones) == "table" and db.milestones or {}
    -- early builds used "entries" instead of "discoveries"
    if type(db.entries) == "table" then
        for id, rec in pairs(db.entries) do
            if db.discoveries[id] == nil then db.discoveries[id] = rec end
        end
        db.entries = nil
    end
end

Migration.character[1] = function(cdb)
    cdb.discovered = type(cdb.discovered) == "table" and cdb.discovered or {}
end

-- The subtitle an automatic NPC entry began its description with, if any:
-- a short title-case phrase before the greeting ("Innkeeper. Welcome ...").
local function leadingSubtitle(text)
    if type(text) ~= "string" then return nil end
    local first = text:match("^(.-)%. ") or text
    if #first > 40 or first:find("[%.!%?,;:]") then return nil end
    for word in first:gmatch("%S+") do
        if word:find("^%l") and word ~= "of" and word ~= "the" then return nil end
    end
    return first
end

local SERVICE_TYPES = { vendor = true, trainer = true, travel = true, rare = true }

-- Migration_002: version 0.2 filed nearly every NPC you talked to as an
-- "unusual NPC" and recorded ordinary falls as drop-down shortcuts. Your own
-- automatic entries of both kinds that you never edited, starred, noted or
-- tagged are withdrawn: private ones are deleted, shared ones become
-- retractions that guild members receive with the next delta sync. NPCs
-- proven ordinary are remembered, so they are not filed again.
Migration.account[2] = function(db)
    for _, key in ipairs({ "discoveries", "userState", "myChars", "profiles", "ordinaryNpcs" }) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    local records, states, mine = db.discoveries, db.userState, db.myChars
    local NPC = FC.NPCDiscovery
    local now = FC.Utils.Now()

    -- what the journal already knows about everyday NPCs
    local questGivers, serviceNpcs = {}, {}
    for _, rec in pairs(records) do
        if type(rec) == "table" and not rec.del then
            if rec.t == "quest" and type(rec.gv) == "string" then questGivers[rec.gv] = true end
            if SERVICE_TYPES[rec.t] and type(rec.npc) == "number" then serviceNpcs[rec.npc] = true end
        end
    end

    local function untouched(id, rec)
        if type(rec.a) ~= "string" or not mine[rec.a] or rec.del or rec.dev then return false end
        if (tonumber(rec.r) or 1) > 1 then return false end
        local state = states[id]
        return not (type(state) == "table" and (state.fav or state.note or state.tags))
    end

    local npcs, shortcuts = 0, 0
    for id, rec in pairs(records) do
        local withdraw = false
        if type(id) == "string" and type(rec) == "table" and untouched(id, rec) then
            if rec.t == "shortcut" and id:find("^u:drop:") then
                withdraw = true
                shortcuts = shortcuts + 1
            elseif NPC.IsUntouchedEntry(rec, states[id])
                and (questGivers[rec.n] or serviceNpcs[rec.npc] or NPC.LooksOrdinary(rec.n, leadingSubtitle(rec.d))) then
                withdraw = true
                npcs = npcs + 1
                if type(rec.npc) == "number" then db.ordinaryNpcs[rec.npc] = true end
            end
        end
        if withdraw then
            if rec.v == "g" then
                records[id] = { id = id, t = rec.t, n = rec.n, a = rec.a, c = rec.c or now, u = now, r = (tonumber(rec.r) or 1) + 1, v = "g", del = true }
            else
                records[id] = nil
            end
            states[id] = nil
        end
    end

    -- the drop-down shortcut detector is gone, and so is its setting
    for _, profile in pairs(db.profiles) do
        if type(profile) == "table" and type(profile.discovery) == "table" then
            profile.discovery.shortcuts = nil
        end
    end

    if npcs + shortcuts > 0 then FC:Print(FC.L.MSG_CLEANED_UP, npcs, shortcuts) end
end

-- Notification kinds that became per-category choices in schema 3.
local OLD_NOTIFY_KINDS = { "rare", "recipe", "secret", "dungeon", "explore", "bestiary" }

-- Migration_003: notifications are chosen per discovery category
-- (Settings > Notifications > What counts as a discovery). A kind someone had
-- switched off stays off for every category that belonged to it, bestiary
-- toasts someone had switched on stay on; everything else takes the new
-- defaults, which leave routine finds such as quests quiet.
Migration.account[3] = function(db)
    for _, profile in pairs(type(db.profiles) == "table" and db.profiles or {}) do
        local notifications = type(profile) == "table" and profile.notifications
        if type(notifications) == "table" and type(notifications.types) == "table" then
            local types = notifications.types
            local categories = type(notifications.categories) == "table" and notifications.categories or {}
            for key, def in pairs(FC.Categories.types) do
                if def.notify ~= "personal" and types[def.notify] == false then categories[key] = false end
            end
            if types.bestiary == true then categories.creature = true end
            for _, kind in ipairs(OLD_NOTIFY_KINDS) do types[kind] = nil end
            notifications.categories = categories
        end
    end
end

-- Gathering nodes of the old world, by the name the game gives them (English
-- clients); other names are cleaned up the next time the node is gathered.
local NODE_NAMES = {}
for name in ([[Peacebloom|Silverleaf|Earthroot|Mageroyal|Briarthorn|Swiftthistle|Stranglekelp|Bruiseweed|Wild Steelbloom|Grave Moss|Kingsblood|Liferoot|Fadeleaf|Goldthorn|Khadgar's Whisker|Wintersbite|Firebloom|Purple Lotus|Wildvine|Arthas' Tears|Sungrass|Blindweed|Ghost Mushroom|Gromsblood|Golden Sansam|Dreamfoil|Mountain Silversage|Plaguebloom|Icecap|Black Lotus|Bloodthistle|Copper Vein|Tin Vein|Silver Vein|Iron Deposit|Gold Vein|Mithril Deposit|Truesilver Deposit|Small Thorium Vein|Rich Thorium Vein|Dark Iron Deposit|Incendicite Mineral Vein|Lesser Bloodstone Deposit|Indurium Mineral Vein|Ooze Covered Silver Vein|Ooze Covered Gold Vein|Ooze Covered Mithril Deposit|Ooze Covered Truesilver Deposit|Ooze Covered Thorium Vein|Ooze Covered Rich Thorium Vein|Hakkari Thorium Vein]]):gmatch("[^|]+") do
    NODE_NAMES[name] = true
end

-- Migration_004: herbs and ore veins that were filed as treasure (or as an
-- "Unknown container", when the client showed no gathering spell) are taken
-- back: yours unless you edited, starred, noted or tagged them; a guild
-- member's copies are hidden here. The objects are remembered as gathering
-- nodes, so they never become treasure again.
Migration.account[4] = function(db)
    for _, key in ipairs({ "discoveries", "userState", "myChars", "gatherObjects" }) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    local records, states, mine = db.discoveries, db.userState, db.myChars
    local unknown = FC.L.AUTO_OBJECT_TITLE
    local now = FC.Utils.Now()
    local removed = 0
    for id, rec in pairs(records) do
        if type(id) == "string" and type(rec) == "table" and rec.t == "treasure" and not rec.del
            and (rec.n == unknown or rec.n == "Unknown container" or NODE_NAMES[rec.n]) then
            local objectID = tonumber(id:match("^u:obj:(%d+):"))
            if objectID then db.gatherObjects[objectID] = db.gatherObjects[objectID] or "node" end
            local state = states[id]
            if type(rec.a) == "string" and mine[rec.a] then
                if not (type(state) == "table" and (state.fav or state.note or state.tags)) then
                    if rec.v == "g" then
                        records[id] = { id = id, t = rec.t, n = rec.n, a = rec.a, c = rec.c or now, u = now, r = (tonumber(rec.r) or 1) + 1, v = "g", del = true }
                    else
                        records[id] = nil
                    end
                    states[id] = nil
                    removed = removed + 1
                end
            else
                states[id] = type(state) == "table" and state or {}
                states[id].hidden = true
                removed = removed + 1
            end
        end
    end
    if removed > 0 then FC:Print(FC.L.MSG_CLEANED_NODES, removed) end
end

-- Migration_005: a long walk inside a building (the Main Hall of an abbey)
-- was filed as a cave, a cave could be filed once for every spot it was
-- entered from, and a treasure taken back left its route behind. Your own
-- automatic entries of these kinds that you never edited, starred, noted or
-- tagged are withdrawn; of a cave filed twice the first one stays, and the
-- marks of who found the other one move to it.
Migration.account[5] = function(db)
    for _, key in ipairs({ "discoveries", "userState", "myChars", "found" }) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    local records, states, mine = db.discoveries, db.userState, db.myChars
    local U, World = FC.Utils, FC.WorldDiscovery
    local now = U.Now()

    local function live(rec) return type(rec) == "table" and not rec.del end
    local function untouched(id, rec)
        if type(rec.a) ~= "string" or not mine[rec.a] or rec.dev then return false end
        if (tonumber(rec.r) or 1) > 1 then return false end
        local state = states[id]
        return not (type(state) == "table" and (state.fav or state.note or state.tags))
    end
    local function withdraw(id, rec)
        if rec.v == "g" then
            records[id] = { id = id, t = rec.t, n = rec.n, a = rec.a, c = rec.c or now, u = now, r = (tonumber(rec.r) or 1) + 1, v = "g", del = true }
        else
            records[id] = nil
            for _, set in pairs(db.found) do
                if type(set) == "table" then set[id] = nil end
            end
        end
        states[id] = nil
    end

    local buildings, twice, routes = 0, 0, 0
    local caves = {}
    for id, rec in pairs(records) do
        if type(id) == "string" and id:find("^u:cave:") and live(rec) and rec.t == "cave" and type(rec.n) == "string" then
            if World:IsBuildingName(rec.n) then
                if untouched(id, rec) then
                    withdraw(id, rec)
                    buildings = buildings + 1
                end
            else
                local key = tostring(rec.m) .. ":" .. U.NormalizeTitle(rec.n)
                caves[key] = caves[key] or {}
                table.insert(caves[key], id)
            end
        end
    end
    local function earlier(p, q)
        local cp, cq = tonumber(records[p].c) or 0, tonumber(records[q].c) or 0
        if cp ~= cq then return cp < cq end
        return p < q
    end
    for _, ids in pairs(caves) do
        table.sort(ids, earlier)
        local keep = ids[1]
        for i = 2, #ids do
            local id = ids[i]
            local rec = records[id]
            if untouched(id, rec) then
                for _, set in pairs(db.found) do
                    if type(set) == "table" and type(set[id]) == "number" then
                        set[keep] = math.min(tonumber(set[keep]) or set[id], set[id])
                    end
                end
                local state = states[id]
                if type(state) == "table" and type(state.seen) == "number" then
                    local kept = type(states[keep]) == "table" and states[keep] or {}
                    kept.seen = math.min(tonumber(kept.seen) or state.seen, state.seen)
                    states[keep] = kept
                end
                withdraw(id, rec)
                twice = twice + 1
            end
        end
    end
    -- routes whose discovery is gone (also the ones of the caves above)
    for id, rec in pairs(records) do
        if type(id) == "string" and id:find("^path:") and live(rec) and rec.t == "path" then
            local target = type(rec.pa) == "string" and rec.pa or id:sub(6)
            if not live(records[target]) and untouched(id, rec) then
                withdraw(id, rec)
                routes = routes + 1
            end
        end
    end
    if buildings + twice + routes > 0 then FC:Print(FC.L.MSG_CLEANED_WORLD, buildings, twice, routes) end
end

-- Migration_006 (0.8.1): everyone starts once in the painted expedition
-- journal, the look the welcome guide no longer asks about. A flat look is
-- one click away again (the palette at the top of the journal); the theme
-- and colors chosen for it are kept.
Migration.account[6] = function(db)
    for _, profile in pairs(type(db.profiles) == "table" and db.profiles or {}) do
        local look = type(profile) == "table" and profile.appearance
        if type(look) == "table" and look.style == "flat" then look.style = "journal" end
    end
    -- players who knew the addon before hear once where the flat themes went
    if db.onboarded and type(db.meta) == "table" then db.meta.lookNotice = true end
end

-- Migration_007 (0.9.0): the completed quests of every character become a
-- list with names (Features/QuestHistory.lua). What can be put right
-- without the game is put right here; the rest follows at login, when the
-- client can be asked (QuestHistory:AfterScan).
--   * quest IDs a file holds as text become numbers, each quest once
--   * an empty quest title (it was shown instead of the real one, which was
--     then never asked for) is dropped, so the title is looked up again
--   * unusual NPC entries of NPCs the reference data knows as quest givers,
--     vendors, trainers or flight masters are withdrawn like in schema 2:
--     a quest giver with nothing to offer at that moment talked like any
--     stranger. Yours unless you edited, starred, noted or tagged them.
Migration.account[7] = function(db)
    for _, key in ipairs({ "discoveries", "userState", "myChars", "ordinaryNpcs", "found" }) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    local fixedIDs, emptyTitles = 0, 0
    for _, char in pairs(type(db.characters) == "table" and db.characters or {}) do
        if type(char) == "table" then
            for _, field in ipairs({ "q", "qd" }) do
                local set = char[field]
                if type(set) == "table" then
                    local moved = {}
                    for id, value in pairs(set) do
                        if type(id) == "string" then moved[id] = value end
                    end
                    for id, value in pairs(moved) do
                        set[id] = nil
                        local number = tonumber(id)
                        if number and set[number] == nil then set[number] = value end
                        fixedIDs = fixedIDs + 1
                    end
                end
            end
        end
    end
    local lore = type(db.questLore) == "table" and db.questLore or {}
    for _, quest in pairs(type(lore.quests) == "table" and lore.quests or {}) do
        if type(quest) == "table" and type(quest.t) == "string" and quest.t:gsub("%s", "") == "" then
            quest.t = nil
            emptyTitles = emptyTitles + 1
        end
    end

    -- everyday NPCs, as the reference data knows them
    local R = FC.ReferenceData or {}
    local everyday = {}
    for _, q in pairs(type(R.quests) == "table" and R.quests or {}) do
        for _, npcID in ipairs(type(q) == "table" and type(q.g) == "table" and q.g or {}) do everyday[npcID] = true end
    end
    for npcID, npc in pairs(type(R.npcs) == "table" and R.npcs or {}) do
        if type(npc) == "table" and type(npc.k) == "string" and npc.k:find("[vtf]") then everyday[npcID] = true end
    end
    local records, states, mine = db.discoveries, db.userState, db.myChars
    local NPC = FC.NPCDiscovery
    local now = FC.Utils.Now()
    local npcs = 0
    for id, rec in pairs(records) do
        if type(id) == "string" and type(rec) == "table" and type(rec.npc) == "number" and everyday[rec.npc]
            and type(rec.a) == "string" and mine[rec.a] and NPC.IsUntouchedEntry(rec, states[id]) then
            db.ordinaryNpcs[rec.npc] = true
            if rec.v == "g" then
                records[id] = { id = id, t = rec.t, n = rec.n, a = rec.a, c = rec.c or now, u = now, r = (tonumber(rec.r) or 1) + 1, v = "g", del = true }
            else
                records[id] = nil
                for _, set in pairs(db.found) do
                    if type(set) == "table" then set[id] = nil end
                end
            end
            states[id] = nil
            npcs = npcs + 1
        end
    end
    FC.Log:Info("Schema 7: %d quest IDs kept as text turned into numbers, %d empty quest titles dropped, %d everyday NPCs withdrawn", fixedIDs, emptyTitles, npcs)
    if npcs > 0 then FC:Print(FC.L.MSG_CLEANED_NPCS, npcs) end
end

local function run(steps, db, target, label)
    local current = tonumber(db.schema) or 0
    if current > target then
        FC.Log:Warn("%s database schema %d is newer than this addon (%d). Data is kept but may be partially ignored.", label, current, target)
        return
    end
    for version = current + 1, target do
        local step = steps[version]
        if step then
            local ok = FC:SafeCall(label .. " migration " .. version, step, db)
            if not ok then return end
            FC.Log:Info("%s database migrated to schema %d", label, version)
        end
        db.schema = version
    end
end

function Migration:RunAccount(db)
    run(self.account, db, FC.C.DB_VERSION, "Account")
end

function Migration:RunCharacter(cdb)
    run(self.character, cdb, FC.C.CHAR_DB_VERSION, "Character")
end
