local ADDON_NAME, namespace = ...

local FC = {}
namespace.FC = FC
_G.ForeverChronicle = FC

FC.ADDON_NAME = ADDON_NAME
FC.VERSION = "0.9.5"
FC.SCHEMA_VERSION = 10
FC.DB_GLOBAL = "ForeverChronicleDB_v2"
FC.handlers = {}
FC.pendingErrors = {}
FC.initialized = false

-- Lua's string.lower handles ASCII bytes only. Fold the German UTF-8 letters
-- first so searches and sorting treat e.g. Ä and ä as the same character.
function FC:LowerText(value)
    if issecretvalue and issecretvalue(value) then return "" end
    if value == nil then return "" end
    return string.lower(tostring(value or "")
        :gsub("Ä", "ä"):gsub("Ö", "ö"):gsub("Ü", "ü"):gsub("ẞ", "ß"))
end

local unpack = unpack or table.unpack
local eventFrame = CreateFrame("Frame")
FC.eventFrame = eventFrame

local DEFAULTS = {
    schema = FC.SCHEMA_VERSION,
    databaseVersion = 0,
    settings = {
        enabled = true,
        minimap = true,
        minimapAngle = 180,
        -- These values trigger a one-time heads-up; they never delete records.
        maxEvents = 50000,
        maxDiscoveries = 50000,
        debug = false,
        trackQuests = true,
        trackZones = true,
        trackDungeons = true,
        trackBattlegrounds = true,
        trackNPCs = true,
        trackItems = true,
        trackInventory = true,
        trackTrainers = true,
        trackProfessions = true,
        trackCompanions = true,
        zoneReminders = true,
        showLoginRecap = true,
        mapPinsEnabled = false,
        activeMapFilter = nil,
        mapShowAtlas = false,
        mapShowOre = false,
        mapShowHerbs = false,
        mapShowFishing = false,
        mapShowTreasures = false,
        mapShowQuests = false,
        mapShowNotes = false,
        mapShowRares = false,
        mapShowEnemies = false,
        mapShowNPCs = false,
        mapShowMerchants = false,
        mapShowTrainers = false,
        mapShowItems = false,
        mapShowItemsGreen = false,
        mapShowItemsBlue = false,
        mapShowItemsPurple = false,
        mapShowDungeons = false,
        mapShowEntrances = false,
        mapShowZones = false,
        mapClusterPins = false,
        showTooltips = true,
        recordDeaths = true,
        recordLootQuality = 3,
    },
    meta = {
        revision = 0,
        createdAt = 0,
        lastMutationAt = 0,
        lastSavedAt = 0,
        lastSavedReason = "",
    },
    health = {
        initializedAt = 0,
        validationRuns = 0,
        errorCount = 0,
        errors = {},
    },
    recovery = {
        quarantined = {},
        migrationBackups = {},
    },
    characters = {},
    atlas = {
        nextNodeID = 1,
        nodes = {},
        byContinent = {},
        byMap = {},
    },
    questArchive = {
        quests = {},
        byContinent = {},
    },
}

local function copyDefaults(source, target, quarantine, path)
    path = path or ""
    for key, value in pairs(source) do
        local childPath = path == "" and tostring(key) or (path .. "." .. tostring(key))
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                if target[key] ~= nil and quarantine then quarantine[childPath] = target[key] end
                target[key] = {}
            end
            copyDefaults(value, target[key], quarantine, childPath)
        elseif target[key] == nil then
            target[key] = value
        elseif type(target[key]) ~= type(value) then
            if quarantine then quarantine[childPath] = target[key] end
            target[key] = value
        end
    end
end

local function copyData(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do copy[copyData(key, seen)] = copyData(item, seen) end
    return copy
end

function FC:RegisterEvent(event, handler)
    if type(handler) ~= "function" then
        return false
    end
    self.handlers[event] = self.handlers[event] or {}
    table.insert(self.handlers[event], handler)
    local ok, message = pcall(eventFrame.RegisterEvent, eventFrame, event)
    if not ok then
        local handlers = self.handlers[event]
        if handlers and handlers[#handlers] == handler then
            table.remove(handlers, #handlers)
            if #handlers == 0 then self.handlers[event] = nil end
        end
        if self:IsSecret(event) then event = "UNKNOWN_EVENT" end
        if self:IsSecret(message) then message = "Protected registration error" end
        local errorMessage = tostring(event or "") .. ": " .. tostring(message or "")
        if self.db and self.RecordError then
            self:RecordError("REGISTER_EVENT", errorMessage)
        else
            table.insert(self.pendingErrors, { event = "REGISTER_EVENT", message = errorMessage })
        end
        return false, message
    end
    return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if FC.compatibilityBlocked then return end
    if FC.demoMode and event ~= "PLAYER_LOGOUT" then return end
    if FC.demoMode and event == "PLAYER_LOGOUT" and FC.ExitDemoMode then FC:ExitDemoMode() end
    local handlers = FC.handlers[event]
    if not handlers then
        return
    end

    local args = { ... }
    for _, handler in ipairs(handlers) do
        local function callHandler()
            handler(FC, event, unpack(args))
        end
        local function onError(message)
            local safeEvent = FC:IsSecret(event) and "UNKNOWN_EVENT" or tostring(event or "")
            local safeMessage = FC:IsSecret(message) and "Protected value error" or tostring(message or "")
            if FC.RecordError then
                FC:RecordError(safeEvent, safeMessage)
            end
            if geterrorhandler then
                return geterrorhandler()(safeMessage)
            end
            return safeMessage
        end
        xpcall(callHandler, onError)
    end
end)

function FC:Now()
    return time and time() or 0
end

function FC:IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

function FC:GetPlayerLevel()
    local level = UnitLevel and UnitLevel("player")
    if self:IsSecret(level) or type(level) ~= "number" then return nil end
    return level
end

local function safeStoredValue(self, value, seen, depth)
    if self:IsSecret(value) then return nil end
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then return value end
    if valueType ~= "table" or depth >= 12 then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local copy = {}
    for key, item in pairs(value) do
        if not self:IsSecret(key) then
            local safeKey = safeStoredValue(self, key, seen, depth + 1)
            local safeItem = safeStoredValue(self, item, seen, depth + 1)
            if safeKey ~= nil and safeItem ~= nil then copy[safeKey] = safeItem end
        end
    end
    seen[value] = nil
    return copy
end

function FC:SanitizeStoredValue(value)
    return safeStoredValue(self, value, {}, 0)
end

function FC:GetCharacterKey()
    local guid = UnitGUID and UnitGUID("player")
    if not self:IsSecret(guid) and type(guid) == "string" and guid ~= "" then
        return "guid:" .. guid
    end
    local name = UnitName and UnitName("player")
    if self:IsSecret(name) or type(name) ~= "string" or name == "" or name:lower() == "unknown" or name:lower() == "unbekannt" then
        name = GetUnitName and GetUnitName("player", true)
        if self:IsSecret(name) or type(name) ~= "string" then name = "Unknown"
        else name = name:match("^([^-]+)") or name end
    end
    local realm = GetRealmName and GetRealmName()
    if self:IsSecret(realm) or type(realm) ~= "string" then realm = "UnknownRealm" end
    realm = realm ~= "" and realm or "UnknownRealm"
    return name .. "-" .. realm
end

local function currentCharacterName()
    local name = UnitName and UnitName("player")
    if FC:IsSecret(name) or type(name) ~= "string" or name == "" or name:lower() == "unknown" or name:lower() == "unbekannt" then
        name = GetUnitName and GetUnitName("player", true)
        if FC:IsSecret(name) or type(name) ~= "string" then name = nil
        else name = name:match("^([^-]+)") or name end
    end
    if FC:IsSecret(name) or type(name) ~= "string" or name == "" or name:lower() == "unknown" or name:lower() == "unbekannt" then
        return nil
    end
    return name
end

function FC:RefreshCharacterIdentity()
    if not self.db or not self.profile then return end
    local name = currentCharacterName()
    if not name then return end
    local oldKey = self.characterKey
    local actualKey = self:GetCharacterKey()
    local guid = UnitGUID and UnitGUID("player")
    if self:IsSecret(guid) or type(guid) ~= "string" or guid == "" then guid = nil end
    local profile = self.profile

    -- Name and realm labels can change between clients or after a realm/name
    -- change. Use the character GUID to reconnect an existing profile and its
    -- account-wide attribution instead of silently creating a second history.
    if type(guid) == "string" and guid ~= "" then
        local sourceKey, sourceProfile
        if profile.identity and profile.identity.guid == guid then
            sourceKey, sourceProfile = oldKey, profile
        else
            for key, candidate in pairs(self.db.characters or {}) do
                if type(candidate) == "table" and candidate.identity
                    and candidate.identity.guid == guid then
                    sourceKey, sourceProfile = key, candidate
                    break
                end
            end
        end

        if sourceKey and sourceKey ~= actualKey then
            local target = self.db.characters[actualKey]
            local targetGuid = target and target.identity and target.identity.guid
            if target and target ~= sourceProfile and targetGuid and targetGuid ~= guid then
                local baseKey = actualKey .. "#" .. tostring(guid):sub(-6)
                actualKey = baseKey
                local suffix = 1
                while self.db.characters[actualKey] and self.db.characters[actualKey] ~= sourceProfile
                    and self.db.characters[actualKey].identity
                    and self.db.characters[actualKey].identity.guid ~= guid do
                    suffix = suffix + 1
                    actualKey = baseKey .. "-" .. tostring(suffix)
                end
            end
            if sourceKey ~= actualKey then
                -- On a clean v2 database the GUID key is unique. If there is
                -- already a target profile, never overwrite either history:
                -- retain the older identity key and report the conflict.
                if target and target ~= sourceProfile then
                    self:RecordError("IDENTITY_CONFLICT", "Two profiles share character GUID " .. guid .. "; neither profile was deleted.")
                    actualKey = sourceKey
                else
                    self.db.characters[actualKey] = sourceProfile
                    self.db.characters[sourceKey] = nil

                local function moveAttribution(container)
                    if type(container) ~= "table" or container[sourceKey] == nil then return end
                    if container[actualKey] == nil then
                        container[actualKey] = container[sourceKey]
                    elseif type(container[sourceKey]) == "number" and type(container[actualKey]) == "number" then
                        container[actualKey] = math.max(container[actualKey], container[sourceKey])
                    elseif type(container[sourceKey]) == "table" and type(container[actualKey]) == "table" then
                        local from, to = container[sourceKey], container[actualKey]
                        to.count = math.max(tonumber(to.count) or 0, tonumber(from.count) or 0)
                        if from.firstSeen and (not to.firstSeen or from.firstSeen < to.firstSeen) then to.firstSeen = from.firstSeen end
                        if from.lastSeen and (not to.lastSeen or from.lastSeen > to.lastSeen) then to.lastSeen = from.lastSeen end
                        to.name = to.name or from.name
                        to.locale = to.locale or from.locale
                    end
                    container[sourceKey] = nil
                end

                for _, node in pairs(self.db.atlas and self.db.atlas.nodes or {}) do
                    moveAttribution(node.characters)
                end
                for _, quest in pairs(self.db.questArchive and self.db.questArchive.quests or {}) do
                    moveAttribution(quest.completedBy)
                    moveAttribution(quest.acceptedBy)
                end
                    self.characterKey = actualKey
                    profile = sourceProfile
                    self.profile = profile
                end
            end
        end
    end

    if self.characterKey ~= actualKey and self.db.characters[actualKey] == profile then
        self.characterKey = actualKey
    end
    profile.identity = profile.identity or {}
    profile.identity.name = name
    local realm = GetRealmName and GetRealmName()
    if not self:IsSecret(realm) and type(realm) == "string" then profile.identity.realm = realm end
    profile.identity.guid = guid or profile.identity.guid
    local className, classFile
    if UnitClass then className, classFile = UnitClass("player") end
    if not self:IsSecret(className) and type(className) == "string" then
        profile.identity.className = className
        if not self:IsSecret(classFile) and type(classFile) == "string" then profile.identity.classFile = classFile end
    end
    local level = UnitLevel and UnitLevel("player")
    if not self:IsSecret(level) and type(level) == "number" then profile.identity.level = level end
end

function FC:GetContinentName(mapID)
    if self:IsSecret(mapID) or type(mapID) ~= "number" or not C_Map or not C_Map.GetMapInfo then return "" end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok or self:IsSecret(info) or type(info) ~= "table" then return "" end
    local mapType, name = info.mapType, info.name
    if self:IsSecret(mapType) then mapType = nil end
    if self:IsSecret(name) then name = nil end
    if mapType == 2 and type(name) == "string" then return name end
    local parent = info.parentMapID
    if self:IsSecret(parent) or type(parent) ~= "number" then parent = nil end
    local guard = 0
    while parent and parent ~= 0 and guard < 8 do
        local parentOK, parentInfo = pcall(C_Map.GetMapInfo, parent)
        if not parentOK or type(parentInfo) ~= "table" then break end
        local parentType, parentID, parentName = parentInfo.mapType, parentInfo.parentMapID, parentInfo.name
        if self:IsSecret(parentType) then parentType = nil end
        if self:IsSecret(parentID) then parentID = nil end
        if self:IsSecret(parentName) then parentName = nil end
        if parentType == 2 or not parentID or parentID == 0 then
            return type(parentName) == "string" and parentName or ""
        end
        parent = type(parentID) == "number" and parentID or nil
        guard = guard + 1
    end
    return ""
end

function FC:GetLocation(unitToken)
    -- Most Chronicle events belong to the player. For observations triggered
    -- by a target or mouseover, use that unit's own map position when the
    -- client exposes it; this avoids recording a nearby NPC at the player's
    -- feet and then showing a misleading pin later.
    unitToken = not self:IsSecret(unitToken) and type(unitToken) == "string" and unitToken ~= "" and unitToken or "player"
    local zone = GetRealZoneText and GetRealZoneText()
    local subZone = GetSubZoneText and GetSubZoneText()
    if self:IsSecret(zone) or type(zone) ~= "string" then zone = "" end
    if self:IsSecret(subZone) or type(subZone) ~= "string" then subZone = "" end
    local mapID
    local x
    local y
    local unitPositionResolved = false

    if C_Map and C_Map.GetBestMapForUnit then
        local ok, value = pcall(C_Map.GetBestMapForUnit, unitToken)
        if ok then mapID = value end
        if self:IsSecret(mapID) then mapID = nil end
        if not mapID and unitToken ~= "player" then
            local playerOK, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
            if playerOK then mapID = playerMapID end
        end
        if self:IsSecret(mapID) then
            mapID = nil
        end
        if mapID and C_Map.GetPlayerMapPosition then
            local okPosition, position = pcall(C_Map.GetPlayerMapPosition, mapID, unitToken)
            if okPosition and not self:IsSecret(position) and position then
                if position.GetXY then
                    local okXY, px, py = pcall(position.GetXY, position)
                    if okXY and not self:IsSecret(px) and not self:IsSecret(py) then x, y = px, py; unitPositionResolved = unitToken ~= "player" end
                else
                    local px, py = position.x, position.y
                    if not self:IsSecret(px) and not self:IsSecret(py) then
                        x, y = px, py
                        unitPositionResolved = unitToken ~= "player"
                    end
                end
            end
            -- Older Forever/Classic builds may accept only the player token.
            -- Fall back to the player's position instead of discarding the
            -- observation entirely when that client cannot resolve a unit.
            if (x == nil or y == nil) and unitToken ~= "player" then
                unitPositionResolved = false
                local playerOK, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
                if playerOK and not self:IsSecret(playerMapID) and type(playerMapID) == "number" then
                    mapID = playerMapID
                    local positionOK, playerPosition = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
                    if positionOK and not self:IsSecret(playerPosition) and playerPosition then
                        if playerPosition.GetXY then
                            local okXY, px, py = pcall(playerPosition.GetXY, playerPosition)
                            if okXY and not self:IsSecret(px) and not self:IsSecret(py) then x, y = px, py end
                        else
                            local px, py = playerPosition.x, playerPosition.y
                            if not self:IsSecret(px) and not self:IsSecret(py) then x, y = px, py end
                        end
                    end
                end
            end
        end
    end

    if self:IsSecret(mapID) or type(mapID) ~= "number" or mapID <= 0 or mapID ~= mapID then
        mapID = nil
        x, y = nil, nil
    end


    if self:IsSecret(x) or type(x) ~= "number" or x ~= x or x < 0 or x > 1 then
        x = nil
    end
    if self:IsSecret(y) or type(y) ~= "number" or y ~= y or y < 0 or y > 1 then
        y = nil
    end

    -- Zone text can briefly be empty while the player/map is transitioning.
    -- Use the map's own localized name as a safe label fallback.
    if zone == "" and mapID and C_Map and C_Map.GetMapInfo then
        local okInfo, info = pcall(C_Map.GetMapInfo, mapID)
        if okInfo and not self:IsSecret(info) and type(info) == "table"
            and not self:IsSecret(info.name) and type(info.name) == "string" then
            zone = info.name
        end
    end

    return {
        mapID = mapID,
        continent = self:GetContinentName(mapID),
        zone = zone,
        subZone = subZone,
        x = x ~= nil and math.floor(x * 10000 + 0.5) / 100 or nil,
        y = y ~= nil and math.floor(y * 10000 + 0.5) / 100 or nil,
        unitPosition = unitPositionResolved or nil,
    }
end

function FC:GetInteractedUnitToken()
    if type(UnitGUID) == "function" then
        for _, unit in ipairs({ "npc", "target" }) do
            local ok, guid = pcall(UnitGUID, unit)
            if ok and not self:IsSecret(guid) and guid then return unit end
        end
    end
    return "player"
end

function FC:FormatLocation(location)
    if not location then
        return ""
    end
    local place = (type(location.subZone) == "string" and location.subZone ~= "" and location.subZone) or location.zone or ""
    if location.x and location.y then
        if place ~= "" then
            return string.format("%s (%.1f, %.1f)", place, location.x, location.y)
        end
        return string.format("%.1f, %.1f", location.x, location.y)
    end
    return place
end

function FC:Print(message)
    local prefix = "|cffd9a441Forever Chronicle:|r "
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(message or ""))
    end
end

function FC:Debug(message)
    if self.db and self.db.settings.debug then
        self:Print("|cff999999" .. self.L.DEBUG_PREFIX .. "|r " .. tostring(message))
    end
end

function FC:PrintDiagnostics()
    local profile = self.profile or {}
    local identity = profile.identity or {}
    local location
    if self.GetLocation then
        local ok, result = pcall(self.GetLocation, self, "player")
        if ok then location = result end
    end
    local function value(text)
        return text ~= nil and tostring(text) ~= "" and tostring(text) or "-"
    end
    local observations = 0
    for _, records in pairs(profile.observed or {}) do
        for _ in pairs(records) do observations = observations + 1 end
    end
    local settings = self.GetMapSettings and self:GetMapSettings() or (self.db and self.db.settings) or {}
    local enabledLayers = 0
    for key, enabled in pairs(settings) do
        if type(key) == "string" and key:match("^mapShow") and enabled then enabledLayers = enabledLayers + 1 end
    end
    local characterLabel = identity.name
    if characterLabel and identity.realm and identity.realm ~= "" then characterLabel = characterLabel .. "-" .. identity.realm end
    self:Print(string.format(self.L.DIAG_CHARACTER, value(characterLabel or self.characterKey), value(identity.guid), value(identity.level)))
    self:Print(string.format(self.L.DIAG_LOCATION, value(location and location.mapID),
        value(location and (location.continent or location.zone)), value(location and location.subZone)))
    self:Print(string.format(self.L.DIAG_COORDINATES,
        location and location.x and location.y and string.format("%.1f, %.1f", location.x, location.y) or "-"))
    self:Print(string.format(self.L.DIAG_COUNTS, #(profile.events or {}), #(profile.discoveries or {}), observations, #(profile.notes or {})))
    self:Print(string.format(self.L.DIAG_MAP, settings.mapPinsEnabled and self.L.DEBUG_ON or self.L.DEBUG_OFF, enabledLayers))
    self:Print(string.format(self.L.DIAG_ERRORS, self.db and self.db.health and self.db.health.errorCount or 0))
end

function FC:RecordError(event, message)
    if not self.db then return end
    event = self:SanitizeStoredValue(event)
    message = self:SanitizeStoredValue(message)
    if type(event) ~= "string" then event = "UNKNOWN_EVENT" end
    if type(message) ~= "string" then message = "Unknown error" end
    self.db.health = self.db.health or { errorCount = 0, errors = {} }
    self.db.health.errors = self.db.health.errors or {}
    self.db.health.errorCount = (self.db.health.errorCount or 0) + 1
    table.insert(self.db.health.errors, {
        ts = self:Now(),
        event = tostring(event or ""),
        message = tostring(message or ""),
    })
    while #self.db.health.errors > 20 do
        table.remove(self.db.health.errors, 1)
    end
end

function FC:TouchData(reason)
    if not self.db then return end
    reason = self:SanitizeStoredValue(reason)
    if type(reason) ~= "string" then reason = "update" end
    self.db.meta = self.db.meta or {}
    self.db.meta.revision = (self.db.meta.revision or 0) + 1
    self.db.meta.lastMutationAt = self:Now()
    self.db.meta.lastMutationReason = tostring(reason or "update")
end

function FC:ValidateDatabase()
    if not self.db then return false, "database_missing" end
    -- Isolate malformed individual records while retaining their original
    -- values for recovery. One bad old SavedVariables entry must not prevent
    -- unrelated characters and memories from loading.
    self.db.recovery = type(self.db.recovery) == "table" and self.db.recovery or {}
    self.db.recovery.quarantined = type(self.db.recovery.quarantined) == "table"
        and self.db.recovery.quarantined or {}
    local quarantine = self.db.recovery.quarantined
    local function keepTable(parent, key, path)
        if type(parent[key]) ~= "table" then
            if parent[key] ~= nil then quarantine[path] = parent[key] end
            parent[key] = {}
        end
        return parent[key]
    end
    local function keepRecords(parent, key, path)
        local records = keepTable(parent, key, path)
        for id, record in pairs(records) do
            if type(record) ~= "table" then
                quarantine[path .. "[" .. tostring(id) .. "]"] = record
                records[id] = nil
            end
        end
        return records
    end
    local function keepLocations(record, path)
        if record.locations ~= nil then
            local locations = keepTable(record, "locations", path .. ".locations")
            for index, location in pairs(locations) do
                if type(location) ~= "table" then
                    quarantine[path .. ".locations[" .. tostring(index) .. "]"] = location
                    locations[index] = nil
                end
            end
        end
    end
    local characters = keepTable(self.db, "characters", "characters")
    for characterKey, profile in pairs(characters) do
        local prefix = "characters[" .. tostring(characterKey) .. "]"
        if type(profile) ~= "table" then
            quarantine[prefix] = profile
            characters[characterKey] = nil
        else
            local observed = keepTable(profile, "observed", prefix .. ".observed")
            for kind, records in pairs(observed) do
                local recordPath = prefix .. ".observed[" .. tostring(kind) .. "]"
                if type(records) ~= "table" then
                    quarantine[recordPath] = records
                    observed[kind] = {}
                else
                    for id, record in pairs(records) do
                        local path = recordPath .. "[" .. tostring(id) .. "]"
                        if type(record) ~= "table" then
                            quarantine[path] = record
                            records[id] = nil
                        else
                            keepLocations(record, path)
                        end
                    end
                end
            end
            for _, groupName in ipairs({ "merchants", "trainers", "companions", "professions" }) do
                local records = keepRecords(profile, groupName, prefix .. "." .. groupName)
                for id, record in pairs(records) do
                    local path = prefix .. "." .. groupName .. "[" .. tostring(id) .. "]"
                    keepLocations(record, path)
                    if groupName == "merchants" then
                        keepRecords(record, "items", path .. ".items")
                        keepRecords(record, "itemsByName", path .. ".itemsByName")
                    elseif groupName == "trainers" then
                        keepRecords(record, "services", path .. ".services")
                    end
                end
            end
        end
    end
    local requiredTables = {
        { "characters", {} },
        { "atlas", { nextNodeID = 1, nodes = {}, byContinent = {} } },
        { "questArchive", { quests = {}, byContinent = {} } },
        { "meta", {} },
        { "health", { errors = {} } },
    }
    for _, entry in ipairs(requiredTables) do
        if type(self.db[entry[1]]) ~= "table" then
            self.db[entry[1]] = entry[2]
        end
    end
    self.db.atlas.nodes = type(self.db.atlas.nodes) == "table" and self.db.atlas.nodes or {}
    self.db.atlas.byContinent = type(self.db.atlas.byContinent) == "table" and self.db.atlas.byContinent or {}
    self.db.questArchive.quests = type(self.db.questArchive.quests) == "table" and self.db.questArchive.quests or {}
    self.db.questArchive.byContinent = type(self.db.questArchive.byContinent) == "table" and self.db.questArchive.byContinent or {}
    local atlasNodes = keepRecords(self.db.atlas, "nodes", "atlas.nodes")
    for id, node in pairs(atlasNodes) do
        keepLocations(node, "atlas.nodes[" .. tostring(id) .. "]")
    end
    local quests = keepRecords(self.db.questArchive, "quests", "questArchive.quests")
    for id, quest in pairs(quests) do
        keepLocations(quest, "questArchive.quests[" .. tostring(id) .. "]")
    end
    self.db.health.errors = type(self.db.health.errors) == "table" and self.db.health.errors or {}
    self.db.meta.revision = tonumber(self.db.meta.revision) or 0
    self.db.meta.createdAt = tonumber(self.db.meta.createdAt) or self:Now()
    self.db.meta.lastMutationAt = tonumber(self.db.meta.lastMutationAt) or 0
    self.db.meta.lastSavedAt = tonumber(self.db.meta.lastSavedAt) or 0
    self.db.health.validationRuns = (tonumber(self.db.health.validationRuns) or 0) + 1
    self.db.health.initializedAt = self.db.health.initializedAt or self:Now()
    return true
end

function FC:PrepareSavedVariables(reason)
    if not self.db or self.compatibilityBlocked then return end
    self:ValidateDatabase()
    reason = self:SanitizeStoredValue(reason)
    if type(reason) ~= "string" then reason = "unknown" end
    self.db.meta = self.db.meta or {}
    self.db.meta.lastSavedAt = self:Now()
    self.db.meta.lastSavedReason = tostring(reason or "unknown")
    self.db.meta.lastSavedRevision = self.db.meta.revision or 0
    local migration = self.db.recovery and self.db.recovery.migration
    if migration and migration.status == "complete" then
        migration.checkpointSavedAt = self:Now()
    end
end

function FC:NormalizeNoteIDs()
    if not self.db or type(self.db.characters) ~= "table" then return end
    self.db.meta = self.db.meta or {}
    local characterKeys, maximum = {}, 0
    for characterKey in pairs(self.db.characters) do table.insert(characterKeys, characterKey) end
    table.sort(characterKeys)
    for _, characterKey in ipairs(characterKeys) do
        local profile = self.db.characters[characterKey]
        if type(profile) == "table" and type(profile.notes) ~= "table" then profile.notes = {} end
        if type(profile) == "table" and type(profile.events) ~= "table" then profile.events = {} end
        if type(profile) == "table" then
            for index = #(profile.notes or {}), 1, -1 do
                if type(profile.notes[index]) ~= "table" then
                    self.db.recovery.quarantined["characters[" .. tostring(characterKey) .. "].notes[" .. tostring(index) .. "]"] = profile.notes[index]
                    table.remove(profile.notes, index)
                end
            end
            for index = #(profile.events or {}), 1, -1 do
                if type(profile.events[index]) ~= "table" then
                    self.db.recovery.quarantined["characters[" .. tostring(characterKey) .. "].events[" .. tostring(index) .. "]"] = profile.events[index]
                    table.remove(profile.events, index)
                end
            end
        end
        for _, note in ipairs(type(profile) == "table" and profile.notes or {}) do
            local id = tonumber(note.id)
            if id and id > maximum then maximum = id end
        end
    end
    local used = {}
    local nextID = math.max(tonumber(self.db.meta.nextNoteID) or 1, maximum + 1)
    for _, characterKey in ipairs(characterKeys) do
        local profile = self.db.characters[characterKey]
        local remapped = {}
        for _, note in ipairs(type(profile) == "table" and profile.notes or {}) do
            local id = tonumber(note.id)
            if not id or used[id] then
                while used[nextID] do nextID = nextID + 1 end
                if id then remapped[id] = nextID end
                note.id = nextID
                id = nextID
                nextID = nextID + 1
            end
            used[id] = true
        end
        for _, event in ipairs(type(profile) == "table" and profile.events or {}) do
            local eventData = type(event) == "table" and type(event.data) == "table" and event.data or nil
            local oldID = eventData and tonumber(eventData.noteID)
            if oldID and remapped[oldID] then eventData.noteID = remapped[oldID] end
        end
    end
    self.db.meta.nextNoteID = nextID
end

function FC:GetProfile()
    return self.profile
end

function FC:GetMapSettings()
    local settings = (self.profile and self.profile.mapSettings) or self.db.settings
    for _, key in ipairs({ "mapShowItemsGreen", "mapShowItemsBlue", "mapShowItemsPurple" }) do
        if settings[key] == nil then settings[key] = false end
    end
    return settings
end

local function backfillLocationContinent(self, location)
    if type(location) ~= "table" or (type(location.continent) == "string" and location.continent ~= "") then return end
    if location.mapID then
        local ok, continent = pcall(self.GetContinentName, self, location.mapID)
        if ok and type(continent) == "string" and continent ~= "" then location.continent = continent end
    end
end

local function migrateLocationContinents(self)
    local database = self.db
    for _, profile in pairs(database.characters or {}) do
        if type(profile) == "table" then
            for _, event in ipairs(type(profile.events) == "table" and profile.events or {}) do
                if type(event) == "table" then backfillLocationContinent(self, event.location) end
            end
            for _, discovery in ipairs(type(profile.discoveries) == "table" and profile.discoveries or {}) do
                if type(discovery) == "table" then backfillLocationContinent(self, discovery.location) end
            end
            for _, note in ipairs(type(profile.notes) == "table" and profile.notes or {}) do
                if type(note) == "table" then backfillLocationContinent(self, note.location) end
            end
            for _, session in ipairs(type(profile.sessions) == "table" and profile.sessions or {}) do
                if type(session) == "table" then
                    backfillLocationContinent(self, session.startLocation)
                    backfillLocationContinent(self, session.endLocation)
                end
            end
            for _, records in pairs(profile.observed or {}) do
                if type(records) == "table" then
                    for _, record in pairs(records) do
                        if type(record) == "table" then
                            backfillLocationContinent(self, record.location)
                            for _, location in ipairs(type(record.locations) == "table" and record.locations or {}) do
                                backfillLocationContinent(self, location)
                            end
                        end
                    end
                end
            end
            for _, groupName in ipairs({ "merchants", "trainers", "companions" }) do
                local records = profile[groupName]
                if type(records) == "table" then
                    for _, record in pairs(records) do
                        if type(record) == "table" then
                            backfillLocationContinent(self, record.location)
                            for _, location in ipairs(type(record.locations) == "table" and record.locations or {}) do
                                backfillLocationContinent(self, location)
                            end
                        end
                    end
                end
            end
        end
    end
    for _, quest in pairs(database.questArchive and database.questArchive.quests or {}) do
        if type(quest) == "table" then
            backfillLocationContinent(self, quest.location)
            for _, location in ipairs(type(quest.locations) == "table" and quest.locations or {}) do backfillLocationContinent(self, location) end
        end
    end
    for _, node in pairs(database.atlas and database.atlas.nodes or {}) do
        backfillLocationContinent(self, node)
    end
end

function FC:InitializeDatabase()
    -- v2 starts an empty chronicle on purpose. The previous global remains
    -- declared in the TOC and is left byte-for-byte untouched for rollback.
    local invalidRoot
    if type(ForeverChronicleDB_v2) ~= "table" then
        invalidRoot = ForeverChronicleDB_v2
        ForeverChronicleDB_v2 = {}
    end
    local previousSchema = tonumber(ForeverChronicleDB_v2.schema) or 0
    -- Never let an older addon downgrade and rewrite a database created by a
    -- newer version. It stays read-only until a compatible addon is installed.
    if previousSchema > self.SCHEMA_VERSION then
        self.db = ForeverChronicleDB_v2
        self.compatibilityBlocked = true
        self:Print(self.L.INCOMPATIBLE_DB)
        return
    end
    local oldRecovery = ForeverChronicleDB_v2.recovery
    local recovery = type(oldRecovery) == "table" and oldRecovery or {}
    ForeverChronicleDB_v2.recovery = recovery
    local oldQuarantine = recovery.quarantined
    recovery.quarantined = type(oldQuarantine) == "table" and oldQuarantine or {}
    if oldRecovery ~= nil and type(oldRecovery) ~= "table" then recovery.quarantined.recoveryRoot = oldRecovery end
    if oldQuarantine ~= nil and type(oldQuarantine) ~= "table" then recovery.quarantined.quarantineRoot = oldQuarantine end
    local oldBackups = recovery.migrationBackups
    recovery.migrationBackups = type(oldBackups) == "table" and oldBackups or {}
    if oldBackups ~= nil and type(oldBackups) ~= "table" then recovery.quarantined.migrationBackups = oldBackups end
    if invalidRoot ~= nil then ForeverChronicleDB_v2.recovery.quarantined.root = invalidRoot end

    local migration = recovery.migration
    if type(migration) == "table" and migration.status == "complete" and migration.checkpointSavedAt then
        local snapshot = recovery.migrationBackups.latest
        if type(snapshot) == "table" and tonumber(snapshot.schema) == tonumber(migration.from) then
            recovery.migrationBackups.latest = nil
        end
    end
    if type(migration) == "table" and migration.status == "pending" then
        local snapshot = recovery.migrationBackups.latest
        if type(snapshot) == "table" and tonumber(snapshot.schema) == tonumber(migration.from)
            and type(snapshot.characters) == "table" and type(snapshot.settings) == "table" then
            ForeverChronicleDB_v2.schema = snapshot.schema
            ForeverChronicleDB_v2.databaseVersion = snapshot.databaseVersion or 0
            ForeverChronicleDB_v2.characters = copyData(snapshot.characters)
            ForeverChronicleDB_v2.atlas = copyData(snapshot.atlas or {})
            ForeverChronicleDB_v2.questArchive = copyData(snapshot.questArchive or {})
            ForeverChronicleDB_v2.settings = copyData(snapshot.settings)
            ForeverChronicleDB_v2.meta = copyData(snapshot.meta or {})
            ForeverChronicleDB_v2.health = copyData(snapshot.health or {})
            migration.status = "rolled_back"
            previousSchema = tonumber(snapshot.schema) or previousSchema
        else
            self.db = ForeverChronicleDB_v2
            self.compatibilityBlocked = true
            self:Print(self.L.INCOMPATIBLE_DB)
            return
        end
    end
    copyDefaults(DEFAULTS, ForeverChronicleDB_v2, ForeverChronicleDB_v2.recovery.quarantined)

    self.db = ForeverChronicleDB_v2
    self.compatibilityBlocked = false
    if previousSchema > 0 and previousSchema < self.SCHEMA_VERSION then
        local latestBackup = self.db.recovery.migrationBackups.latest
        if type(latestBackup) ~= "table" or tonumber(latestBackup.schema) ~= previousSchema then
            self.db.recovery.migrationBackups.latest = {
            schema = previousSchema,
            databaseVersion = self.db.databaseVersion,
            createdAt = self:Now(),
            characters = copyData(self.db.characters),
            atlas = copyData(self.db.atlas),
            questArchive = copyData(self.db.questArchive),
            settings = copyData(self.db.settings),
            meta = copyData(self.db.meta),
            health = copyData(self.db.health),
        }
        end
        self.db.recovery.migration = {
            from = previousSchema,
            to = self.SCHEMA_VERSION,
            startedAt = self:Now(),
            status = "pending",
        }
    end
    self.db.meta = self.db.meta or {}
    self.db.meta.createdAt = tonumber(self.db.meta.createdAt) or self:Now()
    self.db.meta.migratedFrom = previousSchema
    self.db.schema = self.SCHEMA_VERSION
    if not self.db.settings.maxEvents or self.db.settings.maxEvents < 50000 then self.db.settings.maxEvents = 50000 end
    if not self.db.settings.maxDiscoveries or self.db.settings.maxDiscoveries < 50000 then self.db.settings.maxDiscoveries = 50000 end
    self.db.atlas = self.db.atlas or { nextNodeID = 1, nodes = {}, byContinent = {}, byMap = {} }
    self.db.atlas.nodes = self.db.atlas.nodes or {}
    self.db.atlas.byContinent = self.db.atlas.byContinent or {}
    self.db.atlas.byMap = self.db.atlas.byMap or {}
    self.db.questArchive = self.db.questArchive or { quests = {}, byContinent = {} }
    self.db.questArchive.quests = self.db.questArchive.quests or {}
    self.db.questArchive.byContinent = self.db.questArchive.byContinent or {}
    self.db.atlas.nextNodeID = self.db.atlas.nextNodeID or 1
    self:ValidateDatabase()
    if previousSchema < 8 then migrateLocationContinents(self) end
    for _, pendingError in ipairs(self.pendingErrors or {}) do
        self:RecordError(pendingError.event, pendingError.message)
    end
    self.pendingErrors = {}
    self:NormalizeNoteIDs()
    self.characterKey = self:GetCharacterKey()

    local profile = self.db.characters[self.characterKey]
    if type(profile) ~= "table" then
        profile = {}
        self.db.characters[self.characterKey] = profile
    end

    copyDefaults({
        identity = {},
        events = {},
        discoveries = {},
        discoveredContinents = {},
        discoveredSubZones = {},
        observed = {
            quests = {},
            npcs = {},
            enemies = {},
            items = {},
            zones = {},
            dungeons = {},
            entrances = {},
            rares = {},
        },
        inventory = {
            bags = {},
            bank = {},
            bagsUpdatedAt = 0,
            bankUpdatedAt = 0,
        },
        merchants = {},
        trainers = {},
        professions = {},
        companions = {},
        notes = {},
        sessions = {},
        stats = {
            questsAccepted = 0,
            questsCompleted = 0,
            zonesDiscovered = 0,
            dungeonsEntered = 0,
            raresSeen = 0,
            deaths = 0,
            itemsObserved = 0,
            merchantsVisited = 0,
            trainersVisited = 0,
            companionsMet = 0,
        },
        lastState = {},
        retentionNotice = {},
        diaryStyle = {},
        diaryPeriodVariants = {},
        diaryDayVariants = {},
        diaryLength = 4,
        nextEventID = 1,
        mapSettings = {},
        uiState = {},
    }, profile, self.db.recovery.quarantined, "characters[" .. tostring(self.characterKey) .. "]")
    local maximumEventID = 0
    for _, event in ipairs(profile.events) do
        local eventID = type(event) == "table" and tonumber(event.id) or nil
        if eventID and eventID > maximumEventID then maximumEventID = eventID end
    end
    profile.nextEventID = math.max(tonumber(profile.nextEventID) or 1, maximumEventID + 1)

    -- Preserve the old account-wide filters for existing installs, then keep
    -- each character's choices independently from this point onward.
    profile.mapSettings = profile.mapSettings or {}
    for key, value in pairs(DEFAULTS.settings) do
        if key:match("^map") and profile.mapSettings[key] == nil then
            local oldValue = self.db.settings[key]
            if oldValue ~= nil then profile.mapSettings[key] = oldValue else profile.mapSettings[key] = value end
        end
    end
    if profile.mapSettings.filterDefaultsVersion == nil then
        local oldDefaults = {
            mapPinsEnabled = true, mapShowAtlas = true, mapShowOre = true,
            mapShowHerbs = true, mapShowFishing = true, mapShowTreasures = true,
            mapShowQuests = true, mapShowNotes = true, mapShowRares = true,
            mapShowNPCs = false, mapShowItems = false, mapShowItemsGreen = false,
            mapShowItemsBlue = false, mapShowItemsPurple = false,
            mapShowDungeons = false, mapShowZones = false, mapClusterPins = false,
            mapShowEntrances = false,
        }
        local wasUnchangedDefault = true
        for key, value in pairs(oldDefaults) do
            if profile.mapSettings[key] ~= value then wasUnchangedDefault = false; break end
        end
        if wasUnchangedDefault then
            profile.mapSettings.mapPinsEnabled = false
            for key in pairs(oldDefaults) do
                if key ~= "mapPinsEnabled" and key ~= "mapClusterPins" then
                    profile.mapSettings[key] = false
                end
            end
        end
        profile.mapSettings.filterDefaultsVersion = 1
    end

    profile.identity.name = currentCharacterName() or profile.identity.name
    local realm = GetRealmName and GetRealmName()
    if not self:IsSecret(realm) and type(realm) == "string" then profile.identity.realm = realm end
    local className, classFile
    if UnitClass then className, classFile = UnitClass("player") end
    if not self:IsSecret(className) and type(className) == "string" then profile.identity.className = className end
    if not self:IsSecret(classFile) and type(classFile) == "string" then profile.identity.classFile = classFile end
    local raceName, raceFile
    if UnitRace then raceName, raceFile = UnitRace("player") end
    if not self:IsSecret(raceName) and type(raceName) == "string" then profile.identity.raceName = raceName end
    if not self:IsSecret(raceFile) and type(raceFile) == "string" then profile.identity.raceFile = raceFile end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if not self:IsSecret(faction) and type(faction) == "string" then profile.identity.faction = faction end
    local playerLevel = self:GetPlayerLevel()
    if playerLevel then profile.identity.level = playerLevel end
    profile.identity.firstSeen = profile.identity.firstSeen or self:Now()
    profile.identity.lastSeen = self:Now()

    if GetBuildInfo then
        local version, build, buildDate, interfaceVersion = GetBuildInfo()
        local client = {}
        if not self:IsSecret(version) and type(version) == "string" then client.version = version end
        if not self:IsSecret(build) and (type(build) == "string" or type(build) == "number") then client.build = build end
        if not self:IsSecret(buildDate) and (type(buildDate) == "string" or type(buildDate) == "number") then client.buildDate = buildDate end
        if not self:IsSecret(interfaceVersion) and (type(interfaceVersion) == "string" or type(interfaceVersion) == "number") then client.interfaceVersion = interfaceVersion end
        if not self:IsSecret(WOW_PROJECT_ID) and type(WOW_PROJECT_ID) == "number" then client.projectID = WOW_PROJECT_ID end
        profile.client = client
    end

    self.profile = profile
    self.initialized = true
    self:RefreshCharacterIdentity()
    if self.RebuildAtlasIndex then self:RebuildAtlasIndex() end
    if self.RebuildQuestArchiveIndex then self:RebuildQuestArchiveIndex() end
    self:TouchData("initialize")
    if invalidRoot ~= nil or next(self.db.recovery.quarantined) ~= nil then
        self:RecordError("DATA_QUARANTINE", "Malformed SavedVariables values were preserved in recovery.quarantined; no automatic discard occurred.")
    end
    if self.db.recovery.migration then
        self.db.recovery.migration.status = "complete"
        self.db.recovery.migration.completedAt = self:Now()
    end
end

function FC:CheckDataGrowth()
    local profile = self.profile
    if not profile then return end
    profile.retentionNotice = profile.retentionNotice or {}
    local checks = {
        { "events", #(profile.events or {}), tonumber(self.db.settings.maxEvents) or 50000 },
        { "discoveries", #(profile.discoveries or {}), tonumber(self.db.settings.maxDiscoveries) or 50000 },
    }
    for _, check in ipairs(checks) do
        local key, count, threshold = check[1], check[2], check[3]
        if count >= threshold and not profile.retentionNotice[key] then
            profile.retentionNotice[key] = self:Now()
            if self.L and self.L.DATA_GROWTH_NOTICE then
                self:Print(string.format(self.L.DATA_GROWTH_NOTICE, key, count))
            end
        end
    end
end

function FC:TrimList(list, maximum)
    maximum = tonumber(maximum) or 0
    if maximum < 1 then
        return
    end
    while #list > maximum do
        table.remove(list, 1)
    end
end

function FC:LogEvent(eventType, title, detail, data)
    if not self.initialized or not self.profile then
        return nil
    end

    if self:IsSecret(eventType) or type(eventType) ~= "string" then eventType = "EVENT" end
    title = self:SanitizeStoredValue(title)
    if type(title) ~= "string" then title = eventType end
    detail = self:SanitizeStoredValue(detail)
    if type(detail) ~= "string" then detail = nil end
    data = self:SanitizeStoredValue(data)
    local event = {
        id = self.profile.nextEventID,
        ts = self:Now(),
        type = eventType or "EVENT",
        title = title or eventType or "Event",
        detail = detail,
        location = data and data.location or self:GetLocation(),
        data = data,
        sessionID = self.activeSession and self.activeSession.id or nil,
    }
    if self.db and self.db.settings and self.db.settings.trackCompanions ~= false
        and (eventType == "QUEST_COMPLETED" or eventType == "DUNGEON")
        and self.currentGroupMembers and #self.currentGroupMembers > 0 then
        event.companions = {}
        for _, name in ipairs(self.currentGroupMembers) do
            if not self:IsSecret(name) and type(name) == "string" and name ~= "" then
                table.insert(event.companions, name)
            end
        end
        if #event.companions == 0 then event.companions = nil end
    end
    self.profile.nextEventID = self.profile.nextEventID + 1
    table.insert(self.profile.events, event)
    self.db.meta = self.db.meta or {}
    self.db.meta.firstEventAt = self.db.meta.firstEventAt or event.ts
    self.db.meta.lastEventAt = event.ts
    self:TouchData("event:" .. tostring(eventType or "EVENT"))
    self:CheckDataGrowth()

    if self.RefreshUI then
        self:RefreshUI()
    end
    return event
end

function FC:StartSession()
    local previous = self.profile.sessions[#self.profile.sessions]
    if previous and not previous.endedAt then
        previous.endedAt = self:Now()
        previous.endLevel = previous.endLevel or self.profile.lastState.level or previous.startLevel
        previous.endLocation = previous.endLocation or self.profile.lastState.location
        previous.interrupted = true
        previous.eventEndID = self.profile.nextEventID - 1
    end

    local statSnapshot = {}
    for key, value in pairs(self.profile.stats or {}) do
        if type(value) == "number" then
            statSnapshot[key] = value
        end
    end
    local startedAt = self:Now()
    local session = {
        id = tostring(startedAt) .. ":" .. tostring(self.profile.nextEventID),
        startedAt = startedAt,
        dayKey = date and date("%Y-%m-%d", startedAt) or tostring(startedAt),
        endedAt = nil,
        startLevel = self:GetPlayerLevel() or self.profile.identity.level,
        endLevel = self:GetPlayerLevel() or self.profile.identity.level,
        startLocation = self:GetLocation(),
        statsStart = statSnapshot,
        eventStartID = self.profile.nextEventID,
    }
    table.insert(self.profile.sessions, session)
    self.activeSession = session
    self:LogEvent("LOGIN", self.L and self.L.SESSION_STARTED or "Journey continued")
end

function FC:EndSession()
    if self.activeSession then
        self.activeSession.endedAt = self:Now()
        self.activeSession.endLevel = self:GetPlayerLevel() or self.activeSession.endLevel or self.profile.identity.level
        self.activeSession.endLocation = self:GetLocation()
        local statSnapshot = {}
        for key, value in pairs(self.profile.stats or {}) do
            if type(value) == "number" then
                statSnapshot[key] = value
            end
        end
        self.activeSession.statsEnd = statSnapshot
        self.activeSession.eventEndID = self.profile.nextEventID - 1
        if self.BuildSessionSummary then
            self.activeSession.summary = self:BuildSessionSummary(self.activeSession)
        end
    end
    if self.profile then
        self.profile.identity.lastSeen = self:Now()
        self.profile.lastState.location = self:GetLocation()
        self.profile.lastState.level = self:GetPlayerLevel() or self.profile.identity.level or self.profile.lastState.level
        self.profile.lastState.loggedOutAt = self:Now()
    end
end

FC:RegisterEvent("ADDON_LOADED", function(self, _, loadedAddon)
    if loadedAddon ~= ADDON_NAME then
        return
    end
    self:InitializeDatabase()
end)

FC:RegisterEvent("PLAYER_LOGIN", function(self)
    if not self.initialized then
        self:InitializeDatabase()
    end
    self:RefreshCharacterIdentity()
    self:StartSession()
    self:Print(string.format(self.L.LOADED_MESSAGE, self.VERSION))
end)

FC:RegisterEvent("PLAYER_LOGOUT", function(self)
    self:EndSession()
    self:PrepareSavedVariables("PLAYER_LOGOUT")
end)

SLASH_FOREVERCHRONICLE1 = "/fc"
SLASH_FOREVERCHRONICLE2 = "/fchronicle"
SlashCmdList.FOREVERCHRONICLE = function(message)
    message = tostring(message or "")
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "note" and rest ~= "" then
        FC:AddNote(rest)
    elseif command == "remind" then
        local noteID, state = rest:match("^(%d+)%s*(%S*)$")
        state = string.lower(state or "")
        local enabled
        if state == "on" or state == "an" or state == "1" then enabled = true
        elseif state == "off" or state == "aus" or state == "0" then enabled = false end
        if enabled == nil then
            FC:Print(FC.L.NOTE_REMIND_HELP)
        elseif FC:SetNoteReminder(noteID, enabled) then
            FC:Print(FC.L.REMINDER .. ": " .. (enabled and FC.L.REMINDER_ON or FC.L.REMINDER_OFF))
        else
            FC:Print(FC.L.NOTE_NOT_FOUND)
        end
    elseif command == "pin" then
        local noteID, state = rest:match("^(%d+)%s*(%S*)$")
        state = string.lower(state or "")
        local visible
        if state == "on" or state == "an" or state == "1" then visible = true
        elseif state == "off" or state == "aus" or state == "0" then visible = false end
        if visible == nil then
            FC:Print(FC.L.NOTE_PIN_HELP)
        elseif FC:SetNoteMapVisible(noteID, visible) then
            FC:Print(FC.L.NOTE_PIN .. ": " .. (visible and FC.L.NOTE_PIN_ON or FC.L.NOTE_PIN_OFF))
        else
            FC:Print(FC.L.NOTE_NOT_FOUND)
        end
    elseif command == "forget" then
        local noteID, confirmation = rest:match("^(%d+)%s*(%S*)$")
        if confirmation ~= "confirm" and confirmation ~= "bestätigen" then
            FC:Print(FC.L.FORGET_CONFIRM)
        elseif FC:ArchiveNote(noteID) then
            FC:Print(FC.L.NOTE_ARCHIVED)
        else
            FC:Print(FC.L.NOTE_NOT_FOUND)
        end
    elseif command == "notes" then
        FC:OpenMemory("type:note")
    elseif command == "quests" then
        FC:OpenUI("quests")
    elseif command == "find" and rest ~= "" then
        FC:OpenMemory(rest)
    elseif command == "coords" then
        if rest == "" then
            FC:Print(FC.L.COORDS_HELP)
        else
            FC:OpenMemory("type:item " .. rest)
        end
    elseif command == "export" then
        FC:OpenUI("settings")
    elseif command == "recap" then
        local session = FC:GetPreviousSession()
        local summary = session and (session.summary or FC:BuildSessionSummary(session)) or FC:BuildSessionSummary(FC.activeSession)
        FC:Print((session and FC.L.LAST_JOURNEY or FC.L.CURRENT_JOURNEY) .. ": " .. FC:FormatSessionSummary(summary))
    elseif command == "debug" then
        FC.db.settings.debug = not FC.db.settings.debug
        FC:Print(FC.L.DEBUG_LABEL .. (FC.db.settings.debug and FC.L.DEBUG_ON or FC.L.DEBUG_OFF))
    elseif command == "stats" then
        FC:OpenUI("statistics")
    elseif command == "diagnose" then
        FC:PrintDiagnostics()
    elseif command == "demo" then
        local action = string.lower(rest or "")
        if action == "off" or action == "aus" or action == "stop" then
            if FC.demoMode then FC:ExitDemoMode() else FC:Print(FC.L.DEMO_NOT_ACTIVE) end
        elseif action == "on" or action == "an" or action == "" then
            FC:EnterDemoMode()
        else
            FC:Print(FC.L.DEMO_HELP)
        end
    elseif command == "help" then
        FC:OpenUI("help")
    else
        FC:ToggleUI()
    end
end
