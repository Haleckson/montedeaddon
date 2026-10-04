local _, namespace = ...
local FC = namespace.FC

local ESCAPES = { ["%"] = "%25", ["|"] = "%7C", ["\r"] = "%0D", ["\n"] = "%0A", ["\t"] = "%09" }
local UNESCAPES = { ["25"] = "%", ["7C"] = "|", ["0D"] = "\r", ["0A"] = "\n", ["09"] = "\t" }
local importEscaped = false
local function clean(value)
    return tostring(value == nil and "" or value):gsub("[%%|\r\n\t]", function(char) return ESCAPES[char] end)
end

local function appendLine(lines, fields)
    local encoded = {}
    local maximum = 0
    for index in pairs(fields) do
        if type(index) == "number" and index > maximum then
            maximum = index
        end
    end
    for index = 1, maximum do
        encoded[index] = clean(fields[index])
    end
    table.insert(lines, table.concat(encoded, "|"))
end

local function locationFields(location)
    location = location or {}
    return {
        location.mapID or "", location.zone or "", location.subZone or "",
        location.x or "", location.y or "",
    }
end

local function appendLocation(fields, location, firstIndex)
    for index, value in ipairs(locationFields(location)) do
        fields[firstIndex + index - 1] = value
    end
end

local function characterKeyList(characters)
    local keys = {}
    for key, present in pairs(characters or {}) do
        if present then table.insert(keys, tostring(key)) end
    end
    table.sort(keys)
    return table.concat(keys, ";")
end

local function parseCharacterKeyList(value)
    local characters = {}
    for key in tostring(value or ""):gmatch("[^;]+") do
        characters[key] = true
    end
    return characters
end

local function appendScalars(lines, tag, values)
    for key, value in pairs(values or {}) do
        if type(key) == "string" and (type(value) == "string" or type(value) == "number" or type(value) == "boolean") then
            local kind = type(value) == "boolean" and "b" or type(value) == "number" and "n" or "s"
            appendLine(lines, { tag, key, kind, kind == "b" and (value and 1 or 0) or value })
        end
    end
end

local function appendProfile(lines, characterKey, profile)
    appendLine(lines, { "CHARACTER", characterKey })
    appendLine(lines, {
        "PROFILE", profile.identity.name, profile.identity.realm,
        profile.identity.classFile, profile.identity.raceFile, profile.identity.faction,
        profile.identity.level, profile.identity.guid, profile.identity.firstSeen,
        profile.identity.lastSeen,
    })

    appendScalars(lines, "DISCOVERED_CONTINENT", profile.discoveredContinents)
    appendScalars(lines, "DISCOVERED_SUBZONE", profile.discoveredSubZones)
    appendScalars(lines, "PROFILE_STAT", profile.stats)
    appendScalars(lines, "PROFILE_UI", profile.uiState)
    appendScalars(lines, "PROFILE_MAP", profile.mapSettings)
    appendLine(lines, { "DIARY_LENGTH", profile.diaryLength or 4 })
    appendLine(lines, { "LAST_LEVEL", profile.lastState and profile.lastState.level })
    local lastFields = { "LAST_LOCATION" }
    appendLocation(lastFields, profile.lastState and profile.lastState.location, 2)
    appendLine(lines, lastFields)

    for kind, records in pairs(profile.observed or {}) do
        for id, record in pairs(records) do
            local fields = {
                "OBS", kind, id, record.name, record.firstSeen, record.lastSeen,
                record.count, record.unknown and 1 or 0, record.lastSource,
                record.vendor or "", record.quality or "", record.questState or "",
            }
            appendLocation(fields, record.locations and record.locations[#record.locations], 13)
            fields[18] = record.firstSource or ""
            fields[19] = record.npcRole or ""
            fields[20] = record.icon or ""
            fields[21] = record.link or ""
            appendLine(lines, fields)
            if kind == "dungeons" then
                for encounterID, boss in pairs(record.bosses or {}) do
                    appendLine(lines, { "OBS_BOSS", id, encounterID, boss.name,
                        boss.firstDefeated, boss.lastDefeated, boss.victories, boss.difficultyID })
                end
            end
            for _, location in ipairs(record.locations or {}) do
                appendLine(lines, {
                    "OBS_LOC", kind, id, location.mapID, location.continent or "",
                    location.zone or "", location.subZone or "", location.x, location.y,
                    location.source or "", location.firstSeen or "", location.lastSeen or "",
                    location.unitPosition and 1 or 0,
                })
            end
        end
    end

    for _, discovery in ipairs(profile.discoveries or {}) do
        local fields = {
            "DISC", discovery.ts, discovery.kind, discovery.id, discovery.name,
            discovery.source or "", discovery.databaseVersion or "",
        }
        appendLocation(fields, discovery.location, 8)
        appendLine(lines, fields)
    end

    for _, event in ipairs(profile.events or {}) do
        local fields = { "EVENT", event.id, event.ts, event.type, event.title, event.detail or "" }
        appendLocation(fields, event.location, 7)
        fields[12] = event.sessionID or ""
        fields[13] = table.concat(event.companions or {}, ";")
        fields[14] = event.data and event.data.questID or ""
        fields[15] = event.data and event.data.npcID or ""
        fields[16] = event.data and event.data.merchantKey or ""
        fields[17] = event.data and event.data.merchantName or ""
        fields[18] = table.concat(event.data and event.data.vendorCategories or {}, ";")
        if event.type == "BOSS_DEFEATED" then
            local data = event.data or {}
            fields[19] = data.encounterID or ""
            fields[20] = data.encounterName or ""
            fields[21] = data.instanceID or ""
            fields[22] = data.instanceName or ""
            fields[23] = data.instanceType or ""
            fields[24] = data.difficultyID or ""
            fields[25] = data.difficultyName or ""
            fields[26] = table.concat(data.group or {}, ";")
            fields[27] = data.source or ""
        end
        -- Preserve metadata used by the diary, map and statistics for all
        -- recorded event kinds. Older exports simply lack these trailing fields.
        local data = event.data or {}
        fields[28] = data.instanceName or ""
        fields[29] = data.instanceID or ""
        fields[30] = data.instanceType or ""
        fields[31] = data.difficultyID or ""
        fields[32] = data.difficultyName or ""
        fields[33] = data.level or ""
        fields[34] = data.continent or ""
        fields[35] = data.zone or ""
        fields[36] = data.subZone or ""
        fields[37] = data.itemID or ""
        fields[38] = data.nodeID or ""
        fields[39] = event.location and event.location.continent or ""
        appendLine(lines, fields)
    end

    for _, note in ipairs(profile.notes or {}) do
        local fields = { "NOTE", note.id, note.ts, note.text }
        appendLocation(fields, note.location, 5)
        fields[10] = note.remind == false and 0 or 1
        fields[11] = note.archived == true and 1 or 0
        fields[12] = note.archivedAt or ""
        fields[13] = note.mapVisible == false and 0 or 1
        fields[14] = note.updatedAt or note.ts or ""
        appendLine(lines, fields)
    end

    for merchantKey, merchant in pairs(profile.merchants or {}) do
        local categories = {}
        for category in pairs(merchant.categories or {}) do table.insert(categories, category) end
        table.sort(categories)
        local fields = {
            "MERCHANT", merchantKey, merchant.name, merchant.id, merchant.firstSeen,
            merchant.lastSeen, merchant.visits,
        }
        appendLocation(fields, merchant.location, 8)
        fields[13] = table.concat(categories, ";")
        appendLine(lines, fields)
        for _, location in ipairs(merchant.locations or {}) do
        appendLine(lines, {
            "MERCHANT_LOC", merchantKey, location.mapID, location.zone, location.subZone,
            location.x, location.y, location.firstSeen, location.lastSeen, location.continent or "",
            location.unitPosition and 1 or 0, location.source or "",
            })
        end
        for itemID, item in pairs(merchant.items or {}) do
            appendLine(lines, { "MERCHANT_ITEM", merchantKey, itemID, item.name, item.firstSeen, item.lastSeen, item.itemType, item.itemSubType, item.link })
        end
        for itemName, item in pairs(merchant.itemsByName or {}) do
            appendLine(lines, { "MERCHANT_OFFER", merchantKey, itemName, item.firstSeen, item.lastSeen, item.itemSubType })
        end
    end

    for trainerKey, trainer in pairs(profile.trainers or {}) do
        local fields = {
            "TRAINER", trainerKey, trainer.name, trainer.id, trainer.firstSeen,
            trainer.lastSeen, trainer.visits,
        }
        appendLocation(fields, trainer.location, 8)
        appendLine(lines, fields)
        for _, location in ipairs(trainer.locations or {}) do
            appendLine(lines, { "TRAINER_LOC", trainerKey, location.mapID, location.zone, location.subZone,
                location.x, location.y, location.firstSeen or "", location.lastSeen or "", location.continent or "",
                location.unitPosition and 1 or 0, location.source or "" })
        end
        for serviceKey, service in pairs(trainer.services or {}) do
            appendLine(lines, {
                "TRAINER_SERVICE", trainerKey, serviceKey, service.name, service.rank,
                service.category, service.serviceType, service.isLearned and 1 or 0,
                service.icon, service.cost, service.requiredLevel, service.firstSeen, service.lastSeen,
            })
        end
    end

    -- Keep existing companion rows in exports so older chronicle backups
    -- remain lossless. New companion entries are derived from shared events.
    for companionKey, companion in pairs(profile.companions or {}) do
        local fields = {
            "COMPANION", companionKey, companion.name, companion.realm, companion.classFile,
            companion.level, companion.guid, companion.firstSeen, companion.lastSeen, companion.groups,
        }
        appendLocation(fields, companion.locations and companion.locations[#companion.locations], 11)
        appendLine(lines, fields)
        for _, location in ipairs(companion.locations or {}) do
            appendLine(lines, { "COMPANION_LOC", companionKey, location.mapID, location.zone, location.subZone,
                location.x, location.y, location.firstSeen or "", location.lastSeen or "", location.continent or "",
                location.unitPosition and 1 or 0, location.source or "" })
        end
        for dungeonName, dungeon in pairs(companion.dungeons or {}) do
            appendLine(lines, {
                "COMPANION_DUNGEON", companionKey, dungeonName, dungeon.count,
                dungeon.firstSeen, dungeon.lastSeen,
            })
        end
    end

    for professionKey, profession in pairs(profile.professions or {}) do
        appendLine(lines, {
            "PROFESSION", professionKey, profession.id, profession.name, profession.icon,
            profession.skillLevel, profession.maxSkillLevel, profession.firstSeen, profession.lastSeen,
        })
    end

    for _, session in ipairs(profile.sessions or {}) do
        local fields = {
            "SESSION", session.startedAt, session.endedAt, session.startLevel,
            session.endLevel, session.interrupted and 1 or 0,
        }
        appendLocation(fields, session.startLocation, 7)
        appendLocation(fields, session.endLocation, 12)
        fields[17] = session.eventStartID or ""
        fields[18] = session.eventEndID or ""
        fields[19] = session.id or ""
        fields[20] = session.dayKey or ""
        appendLine(lines, fields)
        for family, variant in pairs(session.diaryVariants or {}) do
            if type(variant) == "number" then
                appendLine(lines, { "SESSION_VARIANT", session.id or session.startedAt, family, variant })
            end
        end
    end
    for family, state in pairs(profile.diaryStyle or {}) do
        if type(state) == "table" then
            appendLine(lines, { "DIARY_STYLE", family, state.count, state.cursor, state.cycle,
                state.last, table.concat(state.deck or {}, ";"), table.concat(state.recent or {}, ";") })
        end
    end
    for dayKey, variants in pairs(profile.diaryDayVariants or {}) do
        for family, variant in pairs(variants) do
            if type(variant) == "number" then appendLine(lines, { "DAY_VARIANT", dayKey, family, variant }) end
        end
    end
    for periodKey, variants in pairs(profile.diaryPeriodVariants or {}) do
        for family, variant in pairs(variants) do
            if type(variant) == "number" then appendLine(lines, { "PERIOD_VARIANT", periodKey, family, variant }) end
        end
    end

    for storageType, inventory in pairs({ bags = profile.inventory.bags, bank = profile.inventory.bank }) do
        for itemID, count in pairs(inventory or {}) do
            appendLine(lines, { "INV", storageType, itemID, count })
        end
    end

    appendLine(lines, { "ENDCHAR", #(profile.events or {}), #(profile.discoveries or {}), #(profile.notes or {}) })
end

local function appendAtlas(lines, atlas)
    for id, node in pairs(atlas and atlas.nodes or {}) do
        appendLine(lines, {
            "ATLAS", id, node.kind, node.name, node.icon, node.mapID,
            node.continent or "", node.zone or "", node.subZone or "",
            node.x, node.y, node.firstSeen, node.lastSeen, node.count, node.source or "",
        })
        for itemID, item in pairs(node.lootItems or {}) do
            appendLine(lines, {
                "ATLAS_LOOT", id, itemID, item.name, item.link, item.quality,
                item.icon, item.firstSeen, item.lastSeen, item.count,
            })
        end
        for characterKey, count in pairs(node.characters or {}) do
            appendLine(lines, { "ATLAS_CHAR", id, characterKey, count })
        end
    end
end

local function appendQuestArchive(lines, archive)
    for id, quest in pairs(archive and archive.quests or {}) do
        local latest = quest.locations and quest.locations[#quest.locations] or {}
        appendLine(lines, {
            "QUEST", id, quest.firstCompleted, quest.lastCompleted, quest.count,
            quest.currentName, quest.englishName, quest.locale,
            latest.mapID, latest.continent or "", latest.zone or "", latest.subZone or "",
            latest.x, latest.y, characterKeyList(latest.characters),
        })
        for locale, name in pairs(quest.names or {}) do
            appendLine(lines, { "QUEST_NAME", id, locale, name })
        end
        for _, location in ipairs(quest.locations or {}) do
            appendLine(lines, {
                "QUEST_LOC", id, location.mapID, location.continent or "", location.zone or "",
                location.subZone or "", location.x, location.y, location.firstSeen, location.lastSeen,
                characterKeyList(location.characters),
            })
        end
        for objectiveIndex, objective in pairs(quest.objectives or {}) do
            appendLine(lines, {
                "QUEST_OBJ", id, objectiveIndex, objective.text or "", objective.numFulfilled,
                objective.numRequired, objective.finished and 1 or 0, objective.objectiveType or "",
                quest.objectivesUpdatedAt or "",
            })
        end
        for _, location in ipairs(quest.acceptedLocations or {}) do
            appendLine(lines, {
                "QUEST_ACCEPT_LOC", id, location.mapID, location.continent or "", location.zone or "",
                location.subZone or "", location.x, location.y, location.firstSeen, location.lastSeen,
                characterKeyList(location.characters),
            })
        end
        for characterKey, character in pairs(quest.completedBy or {}) do
            appendLine(lines, {
                "QUEST_CHAR", id, characterKey, character.count, character.firstSeen,
                character.lastSeen, character.locale, character.name,
            })
        end
        for characterKey, character in pairs(quest.acceptedBy or {}) do
            appendLine(lines, {
                "QUEST_ACCEPT_CHAR", id, characterKey, character.count, character.firstSeen,
                character.lastSeen, character.locale, character.name,
            })
        end
    end
end

function FC:BuildExport(characterKey)
    characterKey = characterKey or self.characterKey
    local profile = self.db.characters[characterKey]
    if not profile then
        return ""
    end
    local lines = {}
    appendLine(lines, { "FOREVER_CHRONICLE", self.SCHEMA_VERSION, self.VERSION, "CHARACTER", self:Now(), "ESC" })
    appendLine(lines, { "META", self.db.meta and self.db.meta.revision or 0,
        self.db.meta and self.db.meta.firstEventAt or "", self.db.meta and self.db.meta.lastEventAt or "" })
    appendScalars(lines, "SETTING", self.db.settings)
    appendProfile(lines, characterKey, profile)
    appendAtlas(lines, self.db.atlas)
    appendQuestArchive(lines, self.db.questArchive)
    appendLine(lines, { "END", 1 })
    return table.concat(lines, "\n")
end

function FC:BuildAccountExport()
    local lines = {}
    appendLine(lines, { "FOREVER_CHRONICLE", self.SCHEMA_VERSION, self.VERSION, "ACCOUNT", self:Now(), "ESC" })
    appendLine(lines, { "META", self.db.meta and self.db.meta.revision or 0,
        self.db.meta and self.db.meta.firstEventAt or "", self.db.meta and self.db.meta.lastEventAt or "" })
    appendScalars(lines, "SETTING", self.db.settings)
    local keys = {}
    for characterKey in pairs(self.db.characters or {}) do
        table.insert(keys, characterKey)
    end
    table.sort(keys)
    for _, characterKey in ipairs(keys) do
        appendProfile(lines, characterKey, self.db.characters[characterKey])
    end
    appendAtlas(lines, self.db.atlas)
    appendQuestArchive(lines, self.db.questArchive)
    appendLine(lines, { "END", #keys })
    return table.concat(lines, "\n")
end

local function splitLine(line)
    local fields = {}
    for field in (line .. "|"):gmatch("(.-)|") do
        local decoded = field
        if importEscaped then
            decoded = field:gsub("%%(%x%x)", function(hex)
                return UNESCAPES[string.upper(hex)] or ("%" .. hex)
            end)
        end
        table.insert(fields, decoded)
    end
    return fields
end

local function numberOrNil(value)
    if value == nil or value == "" then
        return nil
    end
    return tonumber(value)
end

-- Imported backups are user-editable text. Keep textual place names when
-- possible, but never let malformed map coordinates become clickable pins.
local function sanitizeLocation(location)
    if type(location) ~= "table" then return nil end
    local mapID = tonumber(location.mapID)
    if not mapID or mapID <= 0 or mapID ~= mapID or mapID % 1 ~= 0 then mapID = nil end
    local hasX = location.x ~= nil and tostring(location.x) ~= ""
    local hasY = location.y ~= nil and tostring(location.y) ~= ""
    local x, y = tonumber(location.x), tonumber(location.y)
    local coordinatesValid = x ~= nil and y ~= nil and x == x and y == y
        and x >= 0 and x <= 100 and y >= 0 and y <= 100
    if (hasX or hasY) and not coordinatesValid then return nil end
    if not mapID then x, y = nil, nil end
    location.mapID, location.x, location.y = mapID, x, y
    if not mapID and not x and (location.zone or "") == "" and (location.subZone or "") == "" then
        return nil
    end
    return location
end

local function locationFrom(fields, startIndex)
    return sanitizeLocation({
        mapID = numberOrNil(fields[startIndex]), zone = fields[startIndex + 1] or "",
        subZone = fields[startIndex + 2] or "", x = fields[startIndex + 3],
        y = fields[startIndex + 4],
    })
end

local function historyLocationFrom(fields)
    return sanitizeLocation({
        mapID = numberOrNil(fields[3]), zone = fields[4] or "", subZone = fields[5] or "",
        x = fields[6], y = fields[7],
        firstSeen = numberOrNil(fields[8]), lastSeen = numberOrNil(fields[9]),
        continent = fields[10] ~= "" and fields[10] or nil,
        unitPosition = fields[11] == "1" or nil,
        source = fields[12] ~= "" and fields[12] or nil,
    })
end

local function mergeHistoryLocation(locations, location)
    if not location.mapID then return false end
    locations = locations or {}
    for _, old in ipairs(locations) do
        if old.mapID == location.mapID and old.zone == location.zone and old.subZone == location.subZone
            and old.x == location.x and old.y == location.y then
            old.firstSeen = math.min(old.firstSeen or location.firstSeen or 0, location.firstSeen or old.firstSeen or 0)
            old.lastSeen = math.max(old.lastSeen or 0, location.lastSeen or 0)
            old.continent = location.continent or old.continent
            old.unitPosition = location.unitPosition or old.unitPosition or nil
            old.source = location.source or old.source
            return false
        end
    end
    table.insert(locations, location)
    return true
end

local function parseScalar(kind, value)
    if kind == "b" then return value == "1" end
    if kind == "n" then return tonumber(value) end
    if kind == "s" then return value end
end

local function ensureProfile(database, characterKey)
    local profile = database.characters[characterKey]
    if type(profile) ~= "table" then
        profile = {
            identity = {}, events = {}, discoveries = {},
            observed = { quests = {}, npcs = {}, enemies = {}, items = {}, zones = {}, dungeons = {}, entrances = {}, rares = {} },
            inventory = { bags = {}, bank = {}, bagsUpdatedAt = 0, bankUpdatedAt = 0 },
            merchants = {}, trainers = {}, companions = {},
            notes = {}, sessions = {}, stats = {}, lastState = {}, nextEventID = 1,
        }
        database.characters[characterKey] = profile
    end
    profile.identity = profile.identity or {}
    profile.discoveredContinents = profile.discoveredContinents or {}
    profile.discoveredSubZones = profile.discoveredSubZones or {}
    profile.events = profile.events or {}
    profile.discoveries = profile.discoveries or {}
    profile.observed = profile.observed or {}
    for _, kind in ipairs({ "quests", "npcs", "enemies", "items", "zones", "dungeons", "entrances", "rares" }) do
        profile.observed[kind] = profile.observed[kind] or {}
    end
    profile.inventory = profile.inventory or { bags = {}, bank = {} }
    profile.inventory.bags = profile.inventory.bags or {}
    profile.inventory.bank = profile.inventory.bank or {}
    profile.merchants = profile.merchants or {}
    profile.trainers = profile.trainers or {}
    profile.companions = profile.companions or {}
    profile.notes = profile.notes or {}
    profile.sessions = profile.sessions or {}
    profile.stats = profile.stats or {}
    profile.lastState = profile.lastState or {}
    profile.uiState = profile.uiState or {}
    profile.mapSettings = profile.mapSettings or {}
    profile.diaryStyle = profile.diaryStyle or {}
    profile.diaryDayVariants = profile.diaryDayVariants or {}
    profile.diaryPeriodVariants = profile.diaryPeriodVariants or {}
    profile.diaryLength = profile.diaryLength or 4
    profile.nextEventID = profile.nextEventID or 1
    return profile
end

local function ensureAtlas(database)
    database.atlas = database.atlas or { nextNodeID = 1, nodes = {}, byContinent = {}, byMap = {} }
    database.atlas.nodes = database.atlas.nodes or {}
    database.atlas.byContinent = database.atlas.byContinent or {}
    database.atlas.byMap = database.atlas.byMap or {}
    database.atlas.nextNodeID = database.atlas.nextNodeID or 1
    return database.atlas
end

local function ensureQuestArchive(database)
    database.questArchive = database.questArchive or { quests = {}, byContinent = {} }
    database.questArchive.quests = database.questArchive.quests or {}
    database.questArchive.byContinent = database.questArchive.byContinent or {}
    return database.questArchive
end

local function hasEntry(list, matcher)
    for _, entry in ipairs(list) do
        if matcher(entry) then
            return true
        end
    end
    return false
end

function FC:ImportExportText(text)
    if type(text) ~= "string" or text == "" then
        return false, 0, self.L.IMPORT_EMPTY
    end
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    if #lines == 0 then
        return false, 0, self.L.IMPORT_EMPTY
    end
    importEscaped = false
    local header = splitLine(lines[1])
    importEscaped = header[6] == "ESC"
    if header[1] ~= "FOREVER_CHRONICLE" then
        return false, 0, self.L.IMPORT_INVALID
    end
    local schema = tonumber(header[2]) or 0
    if schema > self.SCHEMA_VERSION then
        return false, 0, self.L.IMPORT_NEWER
    end

    local currentProfile
    local currentCharacterKey
    local importedCharacterAliases = {}
    if schema <= 1 and header[4] and header[4] ~= "" then
        currentCharacterKey = header[4]
        currentProfile = ensureProfile(self.db, currentCharacterKey)
    end
    local imported = 0
    for index = 2, #lines do
        local fields = splitLine(lines[index])
        local recordType = fields[1]
        if recordType == "SETTING" then
            local key, value = fields[2], parseScalar(fields[3], fields[4])
            if key and key ~= "" and value ~= nil then
                self.db.settings = self.db.settings or {}
                self.db.settings[key] = value
                imported = imported + 1
            end
        elseif recordType == "CHARACTER" and fields[2] and fields[2] ~= "" then
            currentCharacterKey = fields[2]
            currentProfile = ensureProfile(self.db, currentCharacterKey)
        elseif recordType == "ATLAS" then
            local atlas = ensureAtlas(self.db)
            local id = fields[2] and tostring(fields[2])
            if id and id ~= "" then
                local node = atlas.nodes[id] or { id = numberOrNil(id) or id, lootItems = {}, characters = {} }
                if atlas.nodes[id] and self.RemoveAtlasNodeIndex then self:RemoveAtlasNodeIndex(node) end
                node.kind = fields[3] ~= "" and fields[3] or node.kind
                node.name = fields[4] ~= "" and fields[4] or node.name
                node.icon = fields[5] ~= "" and fields[5] or node.icon
                local oldMapID = node.mapID
                local atlasLocation = sanitizeLocation({
                    mapID = numberOrNil(fields[6]), continent = fields[7] or "",
                    zone = fields[8] or "", subZone = fields[9] or "",
                    x = fields[10], y = fields[11],
                })
                if atlasLocation then
                    node.mapID = atlasLocation.mapID or node.mapID
                    node.continent = atlasLocation.continent ~= "" and atlasLocation.continent or node.continent
                    node.zone = atlasLocation.zone ~= "" and atlasLocation.zone or node.zone
                    node.subZone = atlasLocation.subZone ~= "" and atlasLocation.subZone or node.subZone
                    if atlasLocation.x and atlasLocation.y then
                        node.x, node.y = atlasLocation.x, atlasLocation.y
                    elseif atlasLocation.mapID and oldMapID ~= atlasLocation.mapID then
                        node.x, node.y = nil, nil
                    end
                end
                local firstSeen = numberOrNil(fields[12])
                if firstSeen then node.firstSeen = math.min(firstSeen, node.firstSeen or firstSeen) end
                node.lastSeen = math.max(numberOrNil(fields[13]) or 0, node.lastSeen or 0)
                node.count = math.max(numberOrNil(fields[14]) or 0, node.count or 0)
                node.source = fields[15] ~= "" and fields[15] or node.source
                node.lootItems = node.lootItems or {}
                node.characters = node.characters or {}
                atlas.nodes[id] = node
                atlas.nextNodeID = math.max(atlas.nextNodeID, (tonumber(id) or 0) + 1)
                if self.IndexAtlasNode then self:IndexAtlasNode(node) end
                imported = imported + 1
            end
        elseif recordType == "ATLAS_LOOT" then
            local atlas = ensureAtlas(self.db)
            local node = atlas.nodes[tostring(fields[2] or "")]
            local itemID = fields[3] and tostring(fields[3])
            if node and itemID and itemID ~= "" then
                node.lootItems = node.lootItems or {}
                local item = node.lootItems[itemID] or { id = numberOrNil(itemID) or itemID }
                item.name = fields[4] ~= "" and fields[4] or item.name
                item.link = fields[5] ~= "" and fields[5] or item.link
                item.quality = numberOrNil(fields[6]) or item.quality
                item.icon = fields[7] ~= "" and fields[7] or item.icon
                item.firstSeen = numberOrNil(fields[8]) or item.firstSeen
                item.lastSeen = math.max(numberOrNil(fields[9]) or 0, item.lastSeen or 0)
                item.count = math.max(numberOrNil(fields[10]) or 0, item.count or 0)
                node.lootItems[itemID] = item
                imported = imported + 1
            end
        elseif recordType == "ATLAS_CHAR" then
            local atlas = ensureAtlas(self.db)
            local node = atlas.nodes[tostring(fields[2] or "")]
            local characterKey = fields[3]
            if node and characterKey and characterKey ~= "" then
                node.characters = node.characters or {}
                node.characters[characterKey] = math.max(node.characters[characterKey] or 0, numberOrNil(fields[4]) or 0)
                imported = imported + 1
            end
        elseif recordType == "QUEST" then
            local archive = ensureQuestArchive(self.db)
            local id = fields[2] and tostring(fields[2])
            if id and id ~= "" then
                local quest = archive.quests[id] or { id = numberOrNil(id) or id, names = {}, locations = {}, completedBy = {} }
                quest.firstCompleted = math.min(numberOrNil(fields[3]) or 0, quest.firstCompleted or numberOrNil(fields[3]) or 0)
                quest.lastCompleted = math.max(numberOrNil(fields[4]) or 0, quest.lastCompleted or 0)
                quest.count = math.max(numberOrNil(fields[5]) or 0, quest.count or 0)
                quest.currentName = fields[6] ~= "" and fields[6] or quest.currentName
                quest.englishName = fields[7] ~= "" and fields[7] or quest.englishName
                quest.locale = fields[8] ~= "" and fields[8] or quest.locale
                quest.names = quest.names or {}
                quest.locations = quest.locations or {}
                quest.completedBy = quest.completedBy or {}
                local location = sanitizeLocation({
                    mapID = numberOrNil(fields[9]), continent = fields[10] or "", zone = fields[11] or "",
                    subZone = fields[12] or "", x = fields[13], y = fields[14],
                })
                if location and location.mapID then
                    local latest = self:AddObservationLocation(quest, location)
                    if latest then
                        latest.continent = location.continent
                        latest.characters = parseCharacterKeyList(fields[15])
                    end
                end
                archive.quests[id] = quest
                if self.IndexQuestArchive then self:IndexQuestArchive(quest) end
                imported = imported + 1
            end
        elseif recordType == "QUEST_NAME" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            local locale, name = fields[3], fields[4]
            if quest and locale and locale ~= "" and name and name ~= "" then
                quest.names = quest.names or {}
                quest.names[locale] = name
                quest.englishName = quest.names.enUS or quest.names.enGB or quest.englishName
                quest.currentName = quest.currentName or name
                imported = imported + 1
            end
        elseif recordType == "QUEST_LOC" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            if quest and fields[3] and fields[3] ~= "" then
                quest.locations = quest.locations or {}
                local location = sanitizeLocation({
                    mapID = numberOrNil(fields[3]), continent = fields[4] or "", zone = fields[5] or "",
                    subZone = fields[6] or "", x = fields[7], y = fields[8],
                    firstSeen = numberOrNil(fields[9]), lastSeen = numberOrNil(fields[10]),
                    characters = parseCharacterKeyList(fields[11]),
                })
                if not location or not location.mapID then location = nil end
                if location then
                local exists = false
                for _, previous in ipairs(quest.locations) do
                    if previous.mapID == location.mapID and previous.zone == location.zone
                        and (not previous.x or not location.x or math.abs(previous.x - location.x) < 0.2)
                        and (not previous.y or not location.y or math.abs(previous.y - location.y) < 0.2) then
                        exists = true
                        previous.lastSeen = math.max(previous.lastSeen or 0, location.lastSeen or 0)
                        previous.characters = previous.characters or {}
                        for key in pairs(location.characters) do previous.characters[key] = true end
                        break
                    end
                end
                if not exists then table.insert(quest.locations, location) end
                if self.IndexQuestArchive then self:IndexQuestArchive(quest) end
                imported = imported + 1
                end
            end
        elseif recordType == "QUEST_ACCEPT_LOC" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            if quest and fields[3] and fields[3] ~= "" then
                quest.acceptedLocations = quest.acceptedLocations or {}
                local location = sanitizeLocation({
                    mapID = numberOrNil(fields[3]), continent = fields[4] or "", zone = fields[5] or "",
                    subZone = fields[6] or "", x = fields[7], y = fields[8],
                    firstSeen = numberOrNil(fields[9]), lastSeen = numberOrNil(fields[10]),
                    characters = parseCharacterKeyList(fields[11]),
                })
                if not location or not location.mapID then location = nil end
                if location then
                local exists = false
                for _, previous in ipairs(quest.acceptedLocations) do
                    if previous.mapID == location.mapID and previous.zone == location.zone
                        and (not previous.x or not location.x or math.abs(previous.x - location.x) < 0.2)
                        and (not previous.y or not location.y or math.abs(previous.y - location.y) < 0.2) then
                        exists = true
                        previous.lastSeen = math.max(previous.lastSeen or 0, location.lastSeen or 0)
                        previous.characters = previous.characters or {}
                        for key in pairs(location.characters) do previous.characters[key] = true end
                        break
                    end
                end
                if not exists then table.insert(quest.acceptedLocations, location) end
                imported = imported + 1
                end
            end
        elseif recordType == "QUEST_OBJ" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            if quest and fields[3] and fields[3] ~= "" then
                quest.objectives = quest.objectives or {}
                quest.objectives[tonumber(fields[3]) or fields[3]] = {
                    text = fields[4] or "",
                    numFulfilled = numberOrNil(fields[5]) or 0,
                    numRequired = numberOrNil(fields[6]) or 0,
                    finished = fields[7] == "1",
                    objectiveType = fields[8] ~= "" and fields[8] or nil,
                }
                quest.objectivesUpdatedAt = math.max(quest.objectivesUpdatedAt or 0, numberOrNil(fields[9]) or 0)
                imported = imported + 1
            end
        elseif recordType == "QUEST_CHAR" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            local characterKey = fields[3]
            if quest and characterKey and characterKey ~= "" then
                quest.completedBy = quest.completedBy or {}
                local character = quest.completedBy[characterKey] or {}
                character.count = math.max(character.count or 0, numberOrNil(fields[4]) or 0)
                character.firstSeen = math.min(numberOrNil(fields[5]) or 0, character.firstSeen or numberOrNil(fields[5]) or 0)
                character.lastSeen = math.max(numberOrNil(fields[6]) or 0, character.lastSeen or 0)
                character.locale = fields[7] ~= "" and fields[7] or character.locale
                character.name = fields[8] ~= "" and fields[8] or character.name
                quest.completedBy[characterKey] = character
                imported = imported + 1
            end
        elseif recordType == "QUEST_ACCEPT_CHAR" then
            local archive = ensureQuestArchive(self.db)
            local quest = archive.quests[tostring(fields[2] or "")]
            local characterKey = fields[3]
            if quest and characterKey and characterKey ~= "" then
                quest.acceptedBy = quest.acceptedBy or {}
                local character = quest.acceptedBy[characterKey] or { count = 0 }
                character.count = math.max(character.count or 0, numberOrNil(fields[4]) or 0)
                local firstSeen = numberOrNil(fields[5])
                character.firstSeen = math.min(character.firstSeen or firstSeen or 0, firstSeen or character.firstSeen or 0)
                character.lastSeen = math.max(character.lastSeen or 0, numberOrNil(fields[6]) or 0)
                character.locale = fields[7] ~= "" and fields[7] or character.locale
                character.name = fields[8] ~= "" and fields[8] or character.name
                quest.acceptedBy[characterKey] = character
                imported = imported + 1
            end
        elseif currentProfile and recordType == "PROFILE" then
            local identity = currentProfile.identity
            identity.name = fields[2] ~= "" and fields[2] or identity.name
            identity.realm = fields[3] ~= "" and fields[3] or identity.realm
            identity.classFile = fields[4] ~= "" and fields[4] or identity.classFile
            identity.raceFile = fields[5] ~= "" and fields[5] or identity.raceFile
            identity.faction = fields[6] ~= "" and fields[6] or identity.faction
            identity.level = numberOrNil(fields[7]) or identity.level
            identity.guid = fields[8] ~= "" and fields[8] or identity.guid
            identity.firstSeen = numberOrNil(fields[9]) or identity.firstSeen
            identity.lastSeen = math.max(numberOrNil(fields[10]) or 0, identity.lastSeen or 0)
            local guid = identity.guid
            if type(guid) == "string" and guid ~= "" then
                local canonicalKey = "guid:" .. guid
                local importedKey = currentCharacterKey
                if currentCharacterKey and currentCharacterKey ~= canonicalKey then
                    local canonical = self.db.characters[canonicalKey]
                    if not canonical then
                        self.db.characters[canonicalKey] = currentProfile
                        if self.db.characters[currentCharacterKey] == currentProfile then
                            self.db.characters[currentCharacterKey] = nil
                        end
                        currentProfile, currentCharacterKey = currentProfile, canonicalKey
                    elseif canonical ~= currentProfile then
                        -- CHARACTER/PROFILE precede that profile's records in
                        -- the export. A newly-created empty alias can safely
                        -- point at the canonical profile; never discard a
                        -- populated profile when resolving an imported GUID.
                        local hasHistory = #(currentProfile.events or {}) > 0
                            or #(currentProfile.discoveries or {}) > 0
                            or #(currentProfile.notes or {}) > 0
                            or #(currentProfile.sessions or {}) > 0
                        if not hasHistory then
                            if self.db.characters[currentCharacterKey] == currentProfile then
                                self.db.characters[currentCharacterKey] = nil
                            end
                            currentProfile, currentCharacterKey = canonical, canonicalKey
                        else
                            self:RecordError("IMPORT_IDENTITY_CONFLICT", "A populated imported profile shares a GUID with another profile; both were kept.")
                        end
                    end
                    importedCharacterAliases[importedKey] = currentCharacterKey
                end
            end
            imported = imported + 1
        elseif currentProfile and recordType == "DIARY_LENGTH" then
            local length = numberOrNil(fields[2])
            if length and length >= 1 and length <= 4 and length % 1 == 0 then
                currentProfile.diaryLength = length
                imported = imported + 1
            end
        elseif currentProfile and (recordType == "DISCOVERED_CONTINENT" or recordType == "DISCOVERED_SUBZONE") then
            local key, value = fields[2], parseScalar(fields[3], fields[4])
            if key and key ~= "" and value ~= nil then
                local group = recordType == "DISCOVERED_CONTINENT"
                    and currentProfile.discoveredContinents or currentProfile.discoveredSubZones
                group[key] = group[key] or value
                imported = imported + 1
            end
        elseif currentProfile and (recordType == "PROFILE_STAT" or recordType == "PROFILE_UI" or recordType == "PROFILE_MAP") then
            local key, value = fields[2], parseScalar(fields[3], fields[4])
            if key and key ~= "" and value ~= nil then
                local group = recordType == "PROFILE_STAT" and currentProfile.stats
                    or recordType == "PROFILE_UI" and currentProfile.uiState or currentProfile.mapSettings
                if recordType == "PROFILE_STAT" then
                    group[key] = math.max(tonumber(group[key]) or 0, tonumber(value) or 0)
                else
                    group[key] = value
                end
                imported = imported + 1
            end
        elseif currentProfile and recordType == "LAST_LEVEL" then
            currentProfile.lastState.level = numberOrNil(fields[2]) or currentProfile.lastState.level
        elseif currentProfile and recordType == "LAST_LOCATION" then
            local location = locationFrom(fields, 2)
            if location and location.mapID then currentProfile.lastState.location = location end
        elseif currentProfile and recordType == "OBS" then
            local kind, id = fields[2], fields[3]
            if currentProfile.observed[kind] and id and id ~= "" then
                local record = currentProfile.observed[kind][id] or { id = numberOrNil(id) or id, locations = {} }
                record.name = fields[4] ~= "" and fields[4] or record.name
                local importedFirst = numberOrNil(fields[5])
                if importedFirst then
                    record.firstSeen = math.min(importedFirst, record.firstSeen or importedFirst)
                end
                record.lastSeen = math.max(numberOrNil(fields[6]) or 0, record.lastSeen or 0)
                record.count = math.max(numberOrNil(fields[7]) or 0, record.count or 0)
                record.unknown = fields[8] == "1"
                record.lastSource = fields[9] ~= "" and fields[9] or record.lastSource
                record.vendor = fields[10] ~= "" and fields[10] or record.vendor
                record.firstSource = fields[18] ~= "" and fields[18] or record.firstSource
                record.npcRole = fields[19] ~= "" and fields[19] or record.npcRole
                record.icon = fields[20] ~= "" and fields[20] or record.icon
                record.link = fields[21] ~= "" and fields[21] or record.link
                if schema >= 2 then
                    record.quality = numberOrNil(fields[11]) or record.quality
                    record.questState = fields[12] ~= "" and fields[12] or record.questState
                    self:AddObservationLocation(record, locationFrom(fields, 13))
                else
                    self:AddObservationLocation(record, locationFrom(fields, 11))
                end
                currentProfile.observed[kind][id] = record
                imported = imported + 1
            end
        elseif currentProfile and recordType == "OBS_BOSS" then
            local dungeon = currentProfile.observed.dungeons[fields[2]]
            local encounterID = numberOrNil(fields[3])
            if dungeon and encounterID then
                dungeon.bosses = dungeon.bosses or {}
                local key = tostring(encounterID)
                local boss = dungeon.bosses[key] or { encounterID = encounterID }
                boss.name = fields[4] ~= "" and fields[4] or boss.name
                local first = numberOrNil(fields[5])
                if first then boss.firstDefeated = math.min(first, boss.firstDefeated or first) end
                boss.lastDefeated = math.max(numberOrNil(fields[6]) or 0, boss.lastDefeated or 0)
                boss.victories = math.max(numberOrNil(fields[7]) or 0, boss.victories or 0)
                boss.difficultyID = numberOrNil(fields[8]) or boss.difficultyID
                dungeon.bosses[key] = boss
                imported = imported + 1
            end
        elseif currentProfile and recordType == "OBS_LOC" then
            local kind, id = fields[2], fields[3]
            local record = currentProfile.observed[kind] and currentProfile.observed[kind][id]
            local location = {
                mapID = numberOrNil(fields[4]), continent = fields[5] or "",
                zone = fields[6] or "", subZone = fields[7] or "",
                x = fields[8], y = fields[9],
                source = fields[10] ~= "" and fields[10] or nil,
                firstSeen = numberOrNil(fields[11]), lastSeen = numberOrNil(fields[12]),
                unitPosition = fields[13] == "1" or nil,
            }
            if record and location.mapID then
                local merged = self:AddObservationLocation(record, location, location.source)
                if merged then
                    local firstSeen, lastSeen = location.firstSeen, location.lastSeen
                    if firstSeen then merged.firstSeen = math.min(merged.firstSeen or firstSeen, firstSeen) end
                    if lastSeen then merged.lastSeen = math.max(merged.lastSeen or lastSeen, lastSeen) end
                    merged.unitPosition = location.unitPosition or merged.unitPosition or nil
                end
                imported = imported + 1
            end
        elseif currentProfile and recordType == "DISC" then
            local ts, kind, id = numberOrNil(fields[2]), fields[3], fields[4]
            if not hasEntry(currentProfile.discoveries, function(entry)
                return entry.ts == ts and tostring(entry.id) == tostring(id) and entry.kind == kind
            end) then
                table.insert(currentProfile.discoveries, {
                    ts = ts, kind = kind, id = numberOrNil(id) or id, name = fields[5],
                    source = fields[6], databaseVersion = numberOrNil(fields[7]), location = locationFrom(fields, 8),
                })
                imported = imported + 1
            end
        elseif currentProfile and recordType == "EVENT" then
            local eventID, ts, eventType, title = numberOrNil(fields[2]), numberOrNil(fields[3]), fields[4], fields[5]
            if not hasEntry(currentProfile.events, function(entry)
                return entry.ts == ts and entry.type == eventType and entry.title == title
            end) then
                local companions = {}
                for name in ((fields[13] or "") .. ";"):gmatch("(.-);") do
                    if name ~= "" then table.insert(companions, name) end
                end
                local questID = numberOrNil(fields[14])
                local npcID = numberOrNil(fields[15])
                local vendorCategories = {}
                for category in ((fields[18] or "") .. ";"):gmatch("(.-);") do
                    if category ~= "" then table.insert(vendorCategories, category) end
                end
                local eventData = questID and { questID = questID } or nil
                if npcID or (fields[16] or "") ~= "" or (fields[17] or "") ~= "" or #vendorCategories > 0 then
                    eventData = eventData or {}
                    eventData.npcID = npcID
                    eventData.merchantKey = fields[16] ~= "" and fields[16] or nil
                    eventData.merchantName = fields[17] ~= "" and fields[17] or nil
                    eventData.vendorCategories = #vendorCategories > 0 and vendorCategories or nil
                end
                if eventType == "BOSS_DEFEATED" then
                    eventData = eventData or {}
                    eventData.encounterID = numberOrNil(fields[19])
                    eventData.encounterName = fields[20] ~= "" and fields[20] or title
                    eventData.instanceID = numberOrNil(fields[21])
                    eventData.instanceName = fields[22] ~= "" and fields[22] or fields[6]
                    eventData.instanceType = fields[23] ~= "" and fields[23] or nil
                    eventData.difficultyID = numberOrNil(fields[24])
                    eventData.difficultyName = fields[25] ~= "" and fields[25] or nil
                    eventData.group = {}
                    for name in ((fields[26] or "") .. ";"):gmatch("(.-);") do
                        if name ~= "" then table.insert(eventData.group, name) end
                    end
                    eventData.source = fields[27] ~= "" and fields[27] or nil
                end
                local metadata = {
                    instanceName = fields[28] ~= "" and fields[28] or nil,
                    instanceID = numberOrNil(fields[29]),
                    instanceType = fields[30] ~= "" and fields[30] or nil,
                    difficultyID = numberOrNil(fields[31]),
                    difficultyName = fields[32] ~= "" and fields[32] or nil,
                    level = numberOrNil(fields[33]),
                    continent = fields[34] ~= "" and fields[34] or nil,
                    zone = fields[35] ~= "" and fields[35] or nil,
                    subZone = fields[36] ~= "" and fields[36] or nil,
                    itemID = numberOrNil(fields[37]),
                    nodeID = numberOrNil(fields[38]),
                }
                for key, value in pairs(metadata) do
                    eventData = eventData or {}
                    eventData[key] = value
                end
                local eventLocation = locationFrom(fields, 7)
                if eventLocation and fields[39] ~= "" then eventLocation.continent = fields[39] end
                table.insert(currentProfile.events, {
                    id = eventID or currentProfile.nextEventID, ts = ts, type = eventType,
                    title = title, detail = fields[6], location = eventLocation,
                    sessionID = fields[12] ~= "" and fields[12] or nil,
                    companions = #companions > 0 and companions or nil,
                    data = eventData,
                })
                currentProfile.nextEventID = math.max(currentProfile.nextEventID, (eventID or 0) + 1)
                imported = imported + 1
            end
        elseif currentProfile and recordType == "NOTE" then
            local noteID, ts, noteText = numberOrNil(fields[2]), numberOrNil(fields[3]), fields[4]
            local existing
            for _, entry in ipairs(currentProfile.notes) do
                if entry.ts == ts and entry.text == noteText then existing = entry; break end
            end
            local importedUpdate = numberOrNil(fields[14]) or ts or 0
            if existing then
                if importedUpdate > (existing.updatedAt or existing.ts or 0) then
                    existing.remind = not (schema >= 3 and fields[10] == "0")
                    existing.archived = fields[11] == "1"
                    existing.archivedAt = numberOrNil(fields[12])
                    existing.mapVisible = fields[13] ~= "0"
                    existing.updatedAt = importedUpdate
                    imported = imported + 1
                end
            else
                table.insert(currentProfile.notes, {
                    id = noteID or (#currentProfile.notes + 1), ts = ts,
                    text = noteText, location = locationFrom(fields, 5),
                    remind = not (schema >= 3 and fields[10] == "0"),
                    archived = fields[11] == "1",
                    archivedAt = numberOrNil(fields[12]),
                    mapVisible = fields[13] ~= "0",
                    updatedAt = importedUpdate,
                })
                imported = imported + 1
            end
        elseif currentProfile and recordType == "MERCHANT" then
            local key = fields[2]
            if key and key ~= "" then
                local record = currentProfile.merchants[key] or { key = key, items = {} }
                record.name = fields[3] ~= "" and fields[3] or record.name
                record.id = numberOrNil(fields[4]) or record.id
                local firstSeen = numberOrNil(fields[5])
                if firstSeen then record.firstSeen = math.min(firstSeen, record.firstSeen or firstSeen) end
                record.lastSeen = math.max(numberOrNil(fields[6]) or 0, record.lastSeen or 0)
                record.visits = math.max(numberOrNil(fields[7]) or 0, record.visits or 0)
                record.location = locationFrom(fields, 8) or record.location
                record.items = record.items or {}
                record.categories = record.categories or {}
                for category in ((fields[13] or "") .. ";"):gmatch("(.-);") do
                    if category ~= "" then record.categories[category] = true end
                end
                currentProfile.merchants[key] = record
                imported = imported + 1
            end
        elseif currentProfile and recordType == "MERCHANT_ITEM" then
            local merchantKey, itemID = fields[2], fields[3]
            if merchantKey and itemID and currentProfile.merchants[merchantKey] then
                local merchant = currentProfile.merchants[merchantKey]
                merchant.items = merchant.items or {}
                local item = merchant.items[itemID] or { id = numberOrNil(itemID) or itemID }
                item.name = fields[4] ~= "" and fields[4] or item.name
                item.firstSeen = numberOrNil(fields[5]) or item.firstSeen
                item.lastSeen = math.max(numberOrNil(fields[6]) or 0, item.lastSeen or 0)
                item.itemType = fields[7] ~= "" and fields[7] or item.itemType
                item.itemSubType = fields[8] ~= "" and fields[8] or item.itemSubType
                item.link = fields[9] ~= "" and fields[9] or item.link
                merchant.items[itemID] = item
                imported = imported + 1
            end
        elseif currentProfile and recordType == "MERCHANT_OFFER" then
            local merchantKey, itemName = fields[2], fields[3]
            local merchant = merchantKey and currentProfile.merchants[merchantKey]
            if merchant and itemName and itemName ~= "" then
                merchant.itemsByName = merchant.itemsByName or {}
                local offer = merchant.itemsByName[itemName] or { firstSeen = numberOrNil(fields[4]) }
                offer.name = itemName
                offer.firstSeen = math.min(numberOrNil(fields[4]) or offer.firstSeen or 0, offer.firstSeen or numberOrNil(fields[4]) or 0)
                offer.lastSeen = math.max(numberOrNil(fields[5]) or 0, offer.lastSeen or 0)
                offer.itemSubType = fields[6] ~= "" and fields[6] or offer.itemSubType
                merchant.itemsByName[itemName] = offer
                imported = imported + 1
            end
        elseif currentProfile and recordType == "MERCHANT_LOC" then
            local merchantKey = fields[2]
            local merchant = merchantKey and currentProfile.merchants[merchantKey]
            if merchant then
                local location = historyLocationFrom(fields)
                merchant.locations = merchant.locations or {}
                if location and mergeHistoryLocation(merchant.locations, location) then imported = imported + 1 end
            end
        elseif currentProfile and recordType == "TRAINER" then
            local key = fields[2]
            if key and key ~= "" then
                local record = currentProfile.trainers[key] or { key = key, services = {} }
                record.name = fields[3] ~= "" and fields[3] or record.name
                record.id = numberOrNil(fields[4]) or record.id
                local firstSeen = numberOrNil(fields[5])
                if firstSeen then record.firstSeen = math.min(firstSeen, record.firstSeen or firstSeen) end
                record.lastSeen = math.max(numberOrNil(fields[6]) or 0, record.lastSeen or 0)
                record.visits = math.max(numberOrNil(fields[7]) or 0, record.visits or 0)
                record.location = locationFrom(fields, 8) or record.location
                record.services = record.services or {}
                currentProfile.trainers[key] = record
                imported = imported + 1
            end
        elseif currentProfile and recordType == "TRAINER_LOC" then
            local trainer = currentProfile.trainers[fields[2]]
            if trainer then
                trainer.locations = trainer.locations or {}
                local location = historyLocationFrom(fields)
                if location and mergeHistoryLocation(trainer.locations, location) then imported = imported + 1 end
            end
        elseif currentProfile and recordType == "TRAINER_SERVICE" then
            local trainerKey, serviceKey = fields[2], fields[3]
            if trainerKey and serviceKey and currentProfile.trainers[trainerKey] then
                local trainer = currentProfile.trainers[trainerKey]
                trainer.services = trainer.services or {}
                local service = trainer.services[serviceKey] or {}
                service.name = fields[4] ~= "" and fields[4] or service.name
                service.rank = fields[5] ~= "" and fields[5] or service.rank
                service.category = fields[6] ~= "" and fields[6] or service.category
                service.serviceType = fields[7] ~= "" and fields[7] or service.serviceType
                service.isLearned = fields[8] == "1"
                service.icon = numberOrNil(fields[9]) or fields[9] or service.icon
                service.cost = numberOrNil(fields[10]) or service.cost
                service.requiredLevel = numberOrNil(fields[11]) or service.requiredLevel
                service.firstSeen = numberOrNil(fields[12]) or service.firstSeen
                service.lastSeen = math.max(numberOrNil(fields[13]) or 0, service.lastSeen or 0)
                trainer.services[serviceKey] = service
                imported = imported + 1
            end
        elseif currentProfile and recordType == "COMPANION" then
            local key = fields[2]
            if key and key ~= "" then
                local record = currentProfile.companions[key] or { key = key, dungeons = {}, locations = {} }
                record.name = fields[3] ~= "" and fields[3] or record.name
                record.realm = fields[4] ~= "" and fields[4] or record.realm
                record.classFile = fields[5] ~= "" and fields[5] or record.classFile
                record.level = numberOrNil(fields[6]) or record.level
                record.guid = fields[7] ~= "" and fields[7] or record.guid
                local firstSeen = numberOrNil(fields[8])
                if firstSeen then record.firstSeen = math.min(firstSeen, record.firstSeen or firstSeen) end
                record.lastSeen = math.max(numberOrNil(fields[9]) or 0, record.lastSeen or 0)
                record.groups = math.max(numberOrNil(fields[10]) or 0, record.groups or 0)
                record.dungeons = record.dungeons or {}
                record.locations = record.locations or {}
                self:AddObservationLocation(record, locationFrom(fields, 11))
                currentProfile.companions[key] = record
                imported = imported + 1
            end
        elseif currentProfile and recordType == "COMPANION_LOC" then
            local companion = currentProfile.companions[fields[2]]
            if companion then
                companion.locations = companion.locations or {}
                local location = historyLocationFrom(fields)
                if location and mergeHistoryLocation(companion.locations, location) then imported = imported + 1 end
            end
        elseif currentProfile and recordType == "PROFESSION" then
            local key = fields[2]
            if key and key ~= "" then
                currentProfile.professions = currentProfile.professions or {}
                local profession = currentProfile.professions[key] or { id = numberOrNil(fields[3]) or fields[3] }
                profession.name = fields[4] ~= "" and fields[4] or profession.name
                profession.icon = numberOrNil(fields[5]) or fields[5] or profession.icon
                profession.skillLevel = numberOrNil(fields[6]) or profession.skillLevel or 0
                profession.maxSkillLevel = numberOrNil(fields[7]) or profession.maxSkillLevel or 0
                profession.firstSeen = numberOrNil(fields[8]) or profession.firstSeen
                profession.lastSeen = math.max(numberOrNil(fields[9]) or 0, profession.lastSeen or 0)
                currentProfile.professions[key] = profession
                imported = imported + 1
            end
        elseif currentProfile and recordType == "COMPANION_DUNGEON" then
            local companionKey, dungeonName = fields[2], fields[3]
            local companion = companionKey and currentProfile.companions[companionKey]
            if companion and dungeonName and dungeonName ~= "" then
                companion.dungeons = companion.dungeons or {}
                local dungeon = companion.dungeons[dungeonName] or {}
                dungeon.count = math.max(numberOrNil(fields[4]) or 0, dungeon.count or 0)
                dungeon.firstSeen = numberOrNil(fields[5]) or dungeon.firstSeen
                dungeon.lastSeen = math.max(numberOrNil(fields[6]) or 0, dungeon.lastSeen or 0)
                companion.dungeons[dungeonName] = dungeon
                imported = imported + 1
            end
        elseif currentProfile and recordType == "SESSION" then
            local startedAt = numberOrNil(fields[2])
            if startedAt and not hasEntry(currentProfile.sessions, function(entry) return entry.startedAt == startedAt end) then
                table.insert(currentProfile.sessions, {
                    startedAt = startedAt,
                    endedAt = numberOrNil(fields[3]),
                    startLevel = numberOrNil(fields[4]),
                    endLevel = numberOrNil(fields[5]),
                    interrupted = fields[6] == "1",
                    startLocation = locationFrom(fields, 7),
                    endLocation = locationFrom(fields, 12),
                    eventStartID = numberOrNil(fields[17]),
                    eventEndID = numberOrNil(fields[18]),
                    id = fields[19] ~= "" and fields[19] or nil,
                    dayKey = fields[20] ~= "" and fields[20] or nil,
                })
                imported = imported + 1
            end
        elseif currentProfile and recordType == "DIARY_STYLE" then
            local family = fields[2]
            if family and family ~= "" then
                local state = currentProfile.diaryStyle[family] or {}
                state.count = numberOrNil(fields[3]) or state.count
                state.cursor = numberOrNil(fields[4]) or state.cursor
                state.cycle = numberOrNil(fields[5]) or state.cycle
                state.last = numberOrNil(fields[6]) or state.last
                local function parseSequence(value)
                    local sequence = {}
                    for number in tostring(value or ""):gmatch("[^;]+") do
                        local parsed = tonumber(number)
                        if parsed then sequence[#sequence + 1] = parsed end
                    end
                    return sequence
                end
                state.deck = parseSequence(fields[7])
                state.recent = parseSequence(fields[8])
                currentProfile.diaryStyle[family] = state
                imported = imported + 1
            end
        elseif currentProfile and recordType == "SESSION_VARIANT" then
            local key, family, variant = fields[2], fields[3], numberOrNil(fields[4])
            if key and family and variant then
                for _, session in ipairs(currentProfile.sessions) do
                    if tostring(session.id or session.startedAt) == key then
                        session.diaryVariants = session.diaryVariants or {}
                        session.diaryVariants[family] = variant
                        imported = imported + 1
                        break
                    end
                end
            end
        elseif currentProfile and (recordType == "DAY_VARIANT" or recordType == "PERIOD_VARIANT") then
            local key, family, variant = fields[2], fields[3], numberOrNil(fields[4])
            if key and key ~= "" and family and family ~= "" and variant then
                local target = recordType == "DAY_VARIANT" and currentProfile.diaryDayVariants or currentProfile.diaryPeriodVariants
                target[key] = target[key] or {}
                target[key][family] = variant
                imported = imported + 1
            end
        elseif currentProfile and recordType == "INV" then
            local storageType, itemID, count = fields[2], fields[3], numberOrNil(fields[4]) or 0
            if (storageType == "bags" or storageType == "bank") and itemID and itemID ~= "" then
                currentProfile.inventory[storageType][itemID] = math.max(currentProfile.inventory[storageType][itemID] or 0, count)
                imported = imported + 1
            end
        end
    end
    for oldKey, canonicalKey in pairs(importedCharacterAliases) do
        if oldKey ~= "" and canonicalKey ~= oldKey then
            local function remapAttribution(container)
                if type(container) ~= "table" or container[oldKey] == nil then return end
                local old, current = container[oldKey], container[canonicalKey]
                if current == nil then container[canonicalKey] = old
                elseif type(old) == "number" and type(current) == "number" then container[canonicalKey] = math.max(old, current)
                elseif type(old) == "table" and type(current) == "table" then
                    current.count = math.max(tonumber(current.count) or 0, tonumber(old.count) or 0)
                    local firstOld, firstCurrent = tonumber(old.firstSeen), tonumber(current.firstSeen)
                    if firstOld and (not firstCurrent or firstOld < firstCurrent) then current.firstSeen = firstOld end
                    current.lastSeen = math.max(tonumber(current.lastSeen) or 0, tonumber(old.lastSeen) or 0)
                end
                container[oldKey] = nil
            end
            for _, node in pairs(self.db.atlas and self.db.atlas.nodes or {}) do remapAttribution(node.characters) end
            for _, quest in pairs(self.db.questArchive and self.db.questArchive.quests or {}) do
                remapAttribution(quest.completedBy); remapAttribution(quest.acceptedBy)
                for _, location in ipairs(quest.locations or {}) do remapAttribution(location.characters) end
            end
        end
    end
    if self.NormalizeNoteIDs then self:NormalizeNoteIDs() end
    self.profile = self.db.characters[self.characterKey] or self.profile
    self:TouchData("import")
    if self.RefreshUI then
        self:RefreshUI()
    end
    return true, imported, string.format(self.L.IMPORT_SUCCESS, imported)
end
