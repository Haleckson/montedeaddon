local _, namespace = ...
local FC = namespace.FC
local function lower(value)
    return FC:LowerText(value)
end

local lastZoneKey
local lastInstanceKey
local lastLevel
local bagScanScheduled = false
local unitObservationTimes = {}
local trackedTargetGUID
local trackedTargetHealth
local trackedTargetDamageAt
local recordedDefeatGUIDs = {}
local lastPlayerHealth
local lastRecoveryAt = 0
local lastPvpInstanceKey
local deathPendingResurrection = false
-- The first instance state observed in a client session is only a baseline.
-- This prevents logging the last saved outdoor position as an entrance when
-- the player logs in or reloads while already inside a dungeon.
local instanceStateInitialized = false
local wasInTrackedInstance = false
FC:RegisterEvent("PLAYER_LOGIN", function(self)
    if self.initialized then self:RebuildQuestArchiveIndex() end
end)

local function safeItemInfo(itemID)
    if FC:IsSecret(itemID) or not itemID then
        return nil, nil, nil
    end
    local name, link, quality, itemType, itemSubType
    if GetItemInfo then
        name, link, quality, _, _, itemType, itemSubType = GetItemInfo(itemID)
    end
    if FC:IsSecret(name) then name = nil end
    if FC:IsSecret(link) then link = nil end
    if FC:IsSecret(quality) then quality = nil end
    if FC:IsSecret(itemType) then itemType = nil end
    if FC:IsSecret(itemSubType) then itemSubType = nil end
    if not name and C_Item and C_Item.GetItemNameByID then
        name = C_Item.GetItemNameByID(itemID)
    end
    if FC:IsSecret(name) then name = nil end
    if FC:IsSecret(link) then link = nil end
    if FC:IsSecret(quality) then quality = nil end
    if FC:IsSecret(itemType) then itemType = nil end
    if FC:IsSecret(itemSubType) then itemSubType = nil end
    if type(name) ~= "string" then name = nil end
    if type(link) ~= "string" then link = nil end
    if type(quality) ~= "number" then quality = nil end
    if type(itemType) ~= "string" then itemType = nil end
    if type(itemSubType) ~= "string" then itemSubType = nil end
    return name, link, quality, itemType, itemSubType
end

local function itemIDFromLink(link)
    if FC:IsSecret(link) or type(link) ~= "string" then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

local function idFromGUID(guid)
    if (issecretvalue and issecretvalue(guid)) or type(guid) ~= "string" then
        return nil, nil
    end
    local unitType, _, _, _, _, objectID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet" then
        return tonumber(objectID), unitType
    end
    return nil, unitType
end

function FC:TrackItem(itemID, source, details)
    if not self.db.settings.trackItems then
        return
    end
    if self:IsSecret(itemID) then return end
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    local name, link, quality = safeItemInfo(itemID)
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    elseif GetItemIcon then
        icon = GetItemIcon(itemID)
    end
    if self:IsSecret(icon) then icon = nil end
    details = details or {}
    details.source = source or details.source
    details.link = details.link or link
    details.quality = details.quality or quality
    details.icon = details.icon or icon
    if (source == "bag" or source == "bank") and not details.location then
        details.noLocation = true
    end
    local itemName = name or string.format(self.L.ITEM_ID, itemID)
    local _, isFirst = self:Observe("items", itemID, itemName, details)

    if isFirst and quality and quality >= (self.db.settings.recordLootQuality or 3) then
        self:LogEvent("ITEM", itemName, source, {
            itemID = itemID,
            link = link,
            quality = quality,
        })
    end
end

function FC:TrackUnit(unit, source)
    if not self.db.settings.trackNPCs then
        return
    end
    if self:IsSecret(unit) or type(unit) ~= "string" or unit == "" then return end
    local exists = UnitExists(unit)
    if self:IsSecret(exists) or not exists then
        return
    end
    local guid = UnitGUID(unit)
    local npcID = idFromGUID(guid)
    if not npcID then
        return
    end

    local name = UnitName(unit)
    if self:IsSecret(name) then
        name = nil
    end
    name = name or string.format(self.L.NPC_ID, npcID)
    local classification = UnitClassification and UnitClassification(unit)
    if self:IsSecret(classification) then
        classification = nil
    end
    local isRare = classification == "rare" or classification == "rareelite"
    local canAttack
    if UnitCanAttack then
        canAttack = UnitCanAttack("player", unit)
    elseif UnitReaction then
        local reaction = UnitReaction("player", unit)
        if not self:IsSecret(reaction) then canAttack = reaction and reaction <= 3 end
    end
    if self:IsSecret(canAttack) then return end
    -- Remember one reliable map location per ordinary enemy species and zone.
    -- Individual defeats are already written to the diary; repeating the same
    -- mob's position after every kill would create a noisy, crowded map layer.
    local location = self:GetLocation(unit)
    local throttleKey = tostring(npcID) .. ":" .. tostring(location.mapID or location.zone or "")
    local now = GetTime and GetTime() or self:Now()
    if unitObservationTimes[throttleKey] and now - unitObservationTimes[throttleKey] < 30 then
        return
    end
    unitObservationTimes[throttleKey] = now
    if canAttack == true and not isRare then
        local record = self:GetObservation("enemies", npcID)
        local knownOnMap = false
        for _, previous in ipairs(record and record.locations or {}) do
            if previous.mapID == location.mapID and previous.unitPosition == true then knownOnMap = true; break end
        end
        if not record or (location.unitPosition and not knownOnMap) then
            self:Observe("enemies", npcID, name, {
                source = source or unit,
                location = location,
                npcRole = "enemy",
            })
        end
        return
    end
    if canAttack ~= false and not isRare then return end
    if not isRare then
        self:Observe("npcs", npcID, name, {
            source = source or unit,
            location = location,
            npcRole = "npc",
        })
    end

    if isRare then
        local rareDetails = { source = source or unit }
        if location.unitPosition == true then
            rareDetails.location = location
        else
            -- Keep the rare's name in memory but never attach the player's
            -- fallback coordinates to a creature that could not be resolved.
            rareDetails.noLocation = true
        end
        local _, isFirst = self:Observe("rares", npcID, name, {
            source = rareDetails.source,
            location = rareDetails.location,
            noLocation = rareDetails.noLocation,
        })
        if isFirst then
            self.profile.stats.raresSeen = self.profile.stats.raresSeen + 1
            self:LogEvent("RARE", self.L.RARE_SEEN .. ": " .. name, string.format(self.L.NPC_ID, npcID), {
                npcID = npcID,
                guid = guid,
                classification = classification,
            })
        end
    end
end

local function updateTargetDefeat(self, resetTarget)
    if not self.initialized or not self.db.settings.trackNPCs then return end
    local unit = "target"
    local exists = UnitExists and UnitExists(unit)
    if self:IsSecret(exists) or not exists then
        trackedTargetGUID, trackedTargetHealth, trackedTargetDamageAt = nil, nil, nil
        return
    end
    local guid = UnitGUID and UnitGUID(unit)
    if self:IsSecret(guid) or type(guid) ~= "string" then return end
    if resetTarget or guid ~= trackedTargetGUID then
        trackedTargetGUID = guid
        local currentHealth = UnitHealth and UnitHealth(unit)
        trackedTargetHealth = not self:IsSecret(currentHealth) and type(currentHealth) == "number" and currentHealth or nil
        trackedTargetDamageAt = nil
        return
    end

    local health = UnitHealth and UnitHealth(unit)
    if self:IsSecret(health) or type(health) ~= "number" then return end
    local now = GetTime and GetTime() or self:Now()
    if type(trackedTargetHealth) == "number" and health < trackedTargetHealth then
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        if not self:IsSecret(inCombat) and inCombat then
            trackedTargetDamageAt = now
        end
    end
    trackedTargetHealth = health

    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
    if self:IsSecret(dead) or not dead or not trackedTargetDamageAt or now - trackedTargetDamageAt > 120 then return end
    if recordedDefeatGUIDs[guid] then return end
    local npcID, unitType = idFromGUID(guid)
    if not npcID or (unitType ~= "Creature" and unitType ~= "Vehicle") then return end
    local canAttack = UnitCanAttack and UnitCanAttack("player", unit)
    if self:IsSecret(canAttack) or not canAttack then return end
    local name = UnitName and UnitName(unit)
    if self:IsSecret(name) or type(name) ~= "string" or name == "" then
        name = string.format(self.L.NPC_ID, npcID)
    end

    recordedDefeatGUIDs[guid] = true
    self:LogEvent("KILL", name, nil, {
        npcID = npcID,
        guid = guid,
        attribution = "target_health_drop_during_combat",
    })
    trackedTargetDamageAt = nil
end

function FC:TrackZone()
    if not self.initialized or not self.db.settings.trackZones then
        return
    end
    local location = self:GetLocation()
    local insideInstance = false
    if IsInInstance then
        local value = IsInInstance()
        insideInstance = not self:IsSecret(value) and value == true
    end
    if not insideInstance and location.mapID and location.x and location.y then
        self.profile.lastState.lastOutsideLocation = location
    end
    local id = location.mapID or location.zone
    if not id or id == "" then
        return
    end
    local zoneKey = tostring(id) .. ":" .. tostring(location.subZone or "")
    if zoneKey == lastZoneKey then
        return
    end
    lastZoneKey = zoneKey

    -- A first visit to a continent is a major chapter milestone. Keep it
    -- separate from the first visit to a zone so both discoveries survive in
    -- the character's story and remain independently searchable.
    local continent = location.continent
    if type(continent) == "string" and continent ~= "" then
        self.profile.discoveredContinents = type(self.profile.discoveredContinents) == "table"
            and self.profile.discoveredContinents or {}
        if not self.profile.discoveredContinents[continent] then
            local wasAlreadyKnown = false
            -- Rebuild this small index from durable Chronicle data. This keeps
            -- beta 5 upgrades and export/import from announcing an old home as
            -- a brand-new discovery.
            for _, event in ipairs(self.profile.events or {}) do
                local recordedContinent = event.type == "CONTINENT_DISCOVERED"
                    and event.data and event.data.continent
                if recordedContinent == continent then wasAlreadyKnown = true; break end
            end
            if not wasAlreadyKnown then
                for _, zone in pairs(self.profile.observed and self.profile.observed.zones or {}) do
                    if type(zone) == "table" then
                        for _, priorLocation in ipairs(type(zone.locations) == "table" and zone.locations or {}) do
                            if type(priorLocation) == "table" and priorLocation.continent == continent then
                                wasAlreadyKnown = true
                                break
                            end
                        end
                    end
                    if wasAlreadyKnown then break end
                end
            end
            if wasAlreadyKnown then
                self.profile.discoveredContinents[continent] = true
            else
                self.profile.discoveredContinents[continent] = self:Now()
                self:LogEvent("CONTINENT_DISCOVERED", continent, nil, {
                    continent = continent,
                    location = location,
                })
            end
        end
    end

    -- Subzones (for example a named camp, road, or landmark inside the Barrens)
    -- are independent first-discovery memories, stored on this character only.
    local subZone = type(location.subZone) == "string" and location.subZone or ""
    local parentZone = type(location.zone) == "string" and location.zone or ""
    local subZoneKey = tostring(id) .. ":" .. lower(subZone)
    if subZone ~= "" and lower(subZone) ~= lower(parentZone) then
        self.profile.discoveredSubZones = type(self.profile.discoveredSubZones) == "table"
            and self.profile.discoveredSubZones or {}
        if not self.profile.discoveredSubZones[subZoneKey] then
            local wasAlreadyKnown = false
            for _, event in ipairs(self.profile.events or {}) do
                local data = event.data or {}
                if event.type == "SUBZONE_DISCOVERED"
                    and data.mapID == location.mapID
                    and lower(data.subZone) == lower(subZone) then
                    wasAlreadyKnown = true
                    break
                end
                local prior = event.location
                if prior and prior.mapID == location.mapID
                    and lower(prior.subZone) == lower(subZone) then
                    wasAlreadyKnown = true
                    break
                end
            end
            if not wasAlreadyKnown then
                for _, zone in pairs(self.profile.observed and self.profile.observed.zones or {}) do
                    for _, prior in ipairs(type(zone) == "table" and zone.locations or {}) do
                        if prior and prior.mapID == location.mapID
                            and lower(prior.subZone) == lower(subZone) then
                            wasAlreadyKnown = true
                            break
                        end
                    end
                    if wasAlreadyKnown then break end
                end
            end
            if wasAlreadyKnown then
                self.profile.discoveredSubZones[subZoneKey] = true
            else
                self.profile.discoveredSubZones[subZoneKey] = self:Now()
                self:LogEvent("SUBZONE_DISCOVERED", subZone, nil, {
                    mapID = location.mapID, zone = parentZone, subZone = subZone,
                    location = location,
                })
            end
        end
    end

    -- Zones are keyed by mapID (or the localized zone name on older clients),
    -- not by subzone. That records each actual zone once and avoids treating
    -- every street, inn or cave label as a separate zone discovery.
    local name = (type(location.zone) == "string" and location.zone ~= "" and location.zone) or location.subZone or self.L.UNKNOWN
    local _, isFirst = self:Observe("zones", id, name, {
        source = "zone",
        location = location,
    })
    self.profile.lastState.location = location
    if self.CheckLocationReminders then
        self:CheckLocationReminders(location)
    end
    if isFirst then
        self.profile.stats.zonesDiscovered = self.profile.stats.zonesDiscovered + 1
        self:LogEvent("ZONE", self.L.ZONE_DISCOVERED .. ": " .. tostring(name), nil, {
            mapID = location.mapID,
            location = location,
        })
    end
end

function FC:TrackInstance()
    if not GetInstanceInfo or not self.initialized then
        return
    end
    local name, instanceType, difficultyID, difficultyName, maxPlayers, _, _, instanceID = GetInstanceInfo()
    if self:IsSecret(name) or type(name) ~= "string" or name == "" then return end
    if self:IsSecret(instanceType) or type(instanceType) ~= "string" then instanceType = nil end
    if not instanceType then return end
    if self:IsSecret(difficultyID) or type(difficultyID) ~= "number" then difficultyID = nil end
    if self:IsSecret(difficultyName) or type(difficultyName) ~= "string" then difficultyName = nil end
    if self:IsSecret(maxPlayers) or type(maxPlayers) ~= "number" then maxPlayers = nil end
    if self:IsSecret(instanceID) or type(instanceID) ~= "number" then instanceID = nil end
    local isTrackedInstance = instanceType == "party" or instanceType == "raid"
    local isInInstance = instanceType ~= "none" and instanceType ~= "pvp" and instanceType ~= "arena"
    if not instanceStateInitialized then
        instanceStateInitialized = true
        wasInTrackedInstance = isTrackedInstance
        if not isInInstance then
            local outdoorLocation = self:GetLocation()
            if outdoorLocation.mapID and outdoorLocation.x and outdoorLocation.y then
                self.profile.lastState.lastOutsideLocation = outdoorLocation
            end
        end
    elseif isTrackedInstance and not wasInTrackedInstance then
        local entranceLocation = self.profile.lastState.lastOutsideLocation
        if entranceLocation and entranceLocation.mapID and entranceLocation.x and entranceLocation.y then
            local entranceID = instanceID or name
            self:Observe("entrances", entranceID, name, {
                source = "instance_entrance",
                location = entranceLocation,
            })
        end
    end
    wasInTrackedInstance = isTrackedInstance
    if not isInInstance then
        local outdoorLocation = self:GetLocation()
        if outdoorLocation.mapID and outdoorLocation.x and outdoorLocation.y then
            self.profile.lastState.lastOutsideLocation = outdoorLocation
        end
    end
    if instanceType == "pvp" or instanceType == "arena" then
        lastInstanceKey = nil
        local typeKey = instanceType == "pvp" and "BATTLEGROUND" or "ARENA"
        local pvpKey = typeKey .. ":" .. tostring(instanceID or name)
        local trackingEnabled = instanceType == "pvp" and self.db.settings.trackBattlegrounds ~= false
            or instanceType == "arena" and self.db.settings.trackBattlegrounds ~= false
        if trackingEnabled and pvpKey ~= lastPvpInstanceKey then
            lastPvpInstanceKey = pvpKey
            self:LogEvent(typeKey, (instanceType == "pvp" and self.L.BATTLEGROUND_ENTERED or self.L.ARENA_ENTERED) .. ": " .. name,
                difficultyName, { instanceID = instanceID, instanceName = name, instanceType = instanceType,
                    difficultyID = difficultyID, difficultyName = difficultyName })
        end
        return
    end
    lastPvpInstanceKey = nil
    if not self.db.settings.trackDungeons then
        lastInstanceKey = nil
        return
    end
    if instanceType == "none" then
        lastInstanceKey = nil
        return
    end

    local id = instanceID or name
    local instanceKey = tostring(id) .. ":" .. tostring(difficultyID or "")
    if instanceKey == lastInstanceKey then
        return
    end
    lastInstanceKey = instanceKey

    local _, isFirst = self:Observe("dungeons", id, name, {
        source = instanceType,
        location = self:GetLocation(),
    })
    self.profile.stats.dungeonsEntered = self.profile.stats.dungeonsEntered + 1
    -- Refresh the live roster before LogEvent snapshots shared companions.
    if self.TrackCompanions then self:TrackCompanions() end
    self:LogEvent("DUNGEON", self.L.DUNGEON_ENTERED .. ": " .. name, difficultyName, {
        instanceName = name,
        instanceID = instanceID,
        instanceType = instanceType,
        difficultyID = difficultyID,
        difficultyName = difficultyName,
        maxPlayers = maxPlayers,
        firstVisit = isFirst,
    })
end

-- Only confirmed encounter events count as boss victories. Keep the last
-- encounter long enough to merge ENCOUNTER_END and BOSS_KILL for one kill.
local recentBossVictories = {}
function FC:RecordBossVictory(encounterID, encounterName, source, eventDifficultyID)
    if not self.initialized or not self.profile or not self.db.settings.trackDungeons then return end
    if self:IsSecret(encounterID) or self:IsSecret(encounterName) then return end
    if self:IsSecret(eventDifficultyID) then eventDifficultyID = nil end
    if type(encounterID) ~= "number" or type(encounterName) ~= "string" or encounterName == "" then return end
    local instanceName, instanceType, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()
    if self:IsSecret(instanceName) or self:IsSecret(instanceType) then return end
    if self:IsSecret(difficultyID) or type(difficultyID) ~= "number" then difficultyID = nil end
    if self:IsSecret(difficultyName) or type(difficultyName) ~= "string" then difficultyName = nil end
    if self:IsSecret(instanceID) or type(instanceID) ~= "number" then instanceID = nil end
    if instanceType ~= "party" and instanceType ~= "raid" then return end
    if not instanceName or instanceName == "" then return end
    local now = self:Now()
    local instanceKey = tostring(instanceID or instanceName)
    local victoryKey = instanceKey .. ":" .. tostring(encounterID)
    if recentBossVictories[victoryKey] and now - recentBossVictories[victoryKey] < 15 then return end
    recentBossVictories[victoryKey] = now
    for key, ts in pairs(recentBossVictories) do
        if now - ts > 120 then recentBossVictories[key] = nil end
    end
    local dungeon = self.profile.observed and self.profile.observed.dungeons
        and self.profile.observed.dungeons[instanceKey]
    if not dungeon then
        dungeon = self:Observe("dungeons", instanceID or instanceName, instanceName,
            { source = "boss_victory", location = self:GetLocation() })
    end
    if dungeon then
        dungeon.bosses = dungeon.bosses or {}
        local key = tostring(encounterID)
        local boss = dungeon.bosses[key] or { encounterID = encounterID, firstDefeated = now, victories = 0 }
        boss.name = encounterName
        boss.victories = (boss.victories or 0) + 1
        boss.lastDefeated = now
        boss.difficultyID = eventDifficultyID or difficultyID
        dungeon.bosses[key] = boss
    end
    self:LogEvent("BOSS_DEFEATED", encounterName, instanceName, {
        encounterID = encounterID, encounterName = encounterName,
        instanceID = instanceID, instanceName = instanceName, instanceType = instanceType,
        difficultyID = eventDifficultyID or difficultyID, difficultyName = difficultyName,
        source = source,
    })
end

FC:RegisterEvent("ENCOUNTER_END", function(self, _, encounterID, encounterName, difficultyID, groupSize, success)
    if self:IsSecret(success) then return end
    if success == 1 then self:RecordBossVictory(encounterID, encounterName, "ENCOUNTER_END", difficultyID) end
end)
FC:RegisterEvent("BOSS_KILL", function(self, _, encounterID, encounterName)
    self:RecordBossVictory(encounterID, encounterName, "BOSS_KILL")
end)

local function questTitle(questID, questLogIndex)
    if FC:IsSecret(questID) or FC:IsSecret(questLogIndex) then return FC.L.QUEST_COMPLETED end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID and questID then
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if not FC:IsSecret(title) and type(title) == "string" and title ~= "" then
            return title
        end
    end
    if C_QuestLog and C_QuestLog.GetInfo and questLogIndex then
        local info = C_QuestLog.GetInfo(questLogIndex)
        if info and not FC:IsSecret(info) and type(info) == "table"
            and not FC:IsSecret(info.title) and type(info.title) == "string" and info.title ~= "" then
            return info.title
        end
    end
    if GetQuestLogTitle and questLogIndex then
        local title = GetQuestLogTitle(questLogIndex)
        if not FC:IsSecret(title) and type(title) == "string" then return title end
    end
    return questID and string.format(FC.L.QUEST_ID, questID) or FC.L.QUEST_COMPLETED
end

local function questLocale()
    return (GetLocale and GetLocale()) or "enUS"
end

local function questLocation(location)
    location = location or {}
    local continent = location.continent or ""
    if continent == "" and FC.GetContinentName and location.mapID then
        local ok, name = pcall(FC.GetContinentName, FC, location.mapID)
        if ok and type(name) == "string" then continent = name end
    end
    local copy = {
        mapID = location.mapID,
        continent = continent,
        zone = location.zone or "",
        subZone = location.subZone or "",
        x = location.x,
        y = location.y,
    }
    return copy
end

function FC:IndexQuestArchive(record)
    if not self.db or not self.db.questArchive or not record then return end
    local index = self.db.questArchive.byContinent or {}
    self.db.questArchive.byContinent = index
    local location = record.locations and record.locations[#record.locations]
    local continent = location and location.continent or self.L.UNKNOWN
    local zone = location and location.zone or self.L.UNKNOWN
    index[continent] = index[continent] or {}
    index[continent][zone] = index[continent][zone] or {}
    index[continent][zone][tostring(record.id)] = true
end

function FC:RebuildQuestArchiveIndex()
    if not self.db or not self.db.questArchive then return end
    self.db.questArchive.byContinent = {}
    for _, record in pairs(self.db.questArchive.quests or {}) do
        self:IndexQuestArchive(record)
    end
end

local function appendQuestLocation(list, location, now, characterKey)
    if not location then return end
    location.characters = location.characters or {}
    if characterKey then location.characters[characterKey] = true end
    for _, previous in ipairs(list) do
        if previous.mapID == location.mapID and previous.zone == location.zone
            and (not previous.x or not location.x or math.abs(previous.x - location.x) < 0.2)
            and (not previous.y or not location.y or math.abs(previous.y - location.y) < 0.2) then
            previous.lastSeen = now
            previous.x = location.x or previous.x
            previous.y = location.y or previous.y
            previous.continent = location.continent or previous.continent
            previous.characters = previous.characters or {}
            for key in pairs(location.characters) do previous.characters[key] = true end
            return previous
        end
    end
    location.firstSeen = location.firstSeen or now
    location.lastSeen = now
    table.insert(list, location)
    return location
end

function FC:RecordAcceptedQuest(questID, title, location)
    if not self.initialized or not self.db or not self.db.questArchive then return nil end
    local key = tostring(questID)
    local archive = self.db.questArchive.quests
    local now = self:Now()
    local locale = questLocale()
    local record = archive[key]
    if not record then
        record = { id = questID, count = 0, names = {}, locations = {}, acceptedLocations = {}, completedBy = {}, acceptedBy = {} }
        archive[key] = record
    end
    record.names = record.names or {}
    if title and title ~= "" then record.names[locale] = title end
    record.englishName = record.names.enUS or record.names.enGB or record.englishName
    record.currentName = record.names[locale] or title or record.currentName or string.format(self.L.QUEST_ID, key)
    record.locale = locale
    record.acceptedLocations = record.acceptedLocations or {}
    appendQuestLocation(record.acceptedLocations, questLocation(location or self:GetLocation()), now, self.characterKey)
    record.acceptedBy = record.acceptedBy or {}
    local character = record.acceptedBy[self.characterKey] or { count = 0, firstSeen = now }
    character.count = (character.count or 0) + 1
    character.lastSeen = now
    character.locale = locale
    character.name = character.name or (self.profile and self.profile.identity and self.profile.identity.name) or self.characterKey
    record.acceptedBy[self.characterKey] = character
    self:IndexQuestArchive(record)
    self:TouchData("quest:accepted")
    return record
end

function FC:CaptureQuestObjectives(questLogIndex, questID)
    if not self.initialized or not self.db.settings.trackQuests then return end
    if self:IsSecret(questID) or self:IsSecret(questLogIndex) then return end
    questID = tonumber(questID)
    if not questID or questID == 0 then return end
    local objectives = {}
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local values = C_QuestLog.GetQuestObjectives(questID)
        if self:IsSecret(values) or type(values) ~= "table" then values = {} end
        for index, objective in ipairs(values) do
            if objective and not self:IsSecret(objective) and type(objective) == "table" then
                local text = objective.text
                if self:IsSecret(text) or type(text) ~= "string" then text = objective.description end
                if self:IsSecret(text) or type(text) ~= "string" then text = "" end
                local fulfilled, required, finished = objective.numFulfilled, objective.numRequired, objective.finished
                if self:IsSecret(fulfilled) then fulfilled = 0 end
                if self:IsSecret(required) then required = 0 end
                if self:IsSecret(finished) then finished = false end
                objectives[index] = {
                    text = type(text) == "string" and text or "",
                    numFulfilled = tonumber(fulfilled) or 0,
                    numRequired = tonumber(required) or 0,
                    finished = finished and true or false,
                }
            end
        end
    elseif GetNumQuestLeaderBoards and GetQuestLogLeaderBoard and questLogIndex then
        local count = GetNumQuestLeaderBoards(questLogIndex)
        if self:IsSecret(count) or type(count) ~= "number" then count = 0 end
        for index = 1, count do
            local text, objectiveType, finished = GetQuestLogLeaderBoard(index, questLogIndex)
            if self:IsSecret(text) then text = nil end
            if self:IsSecret(objectiveType) then objectiveType = nil end
            if self:IsSecret(finished) then finished = false end
            if type(text) == "string" then
                objectives[index] = { text = text, objectiveType = objectiveType, finished = finished and true or false }
            end
        end
    end
    if next(objectives) == nil then return end
    local key = tostring(questID)
    local observed = self.profile.observed.quests[key]
    if not observed then
        observed = { id = questID, name = questTitle(questID, questLogIndex), locations = {}, count = 0 }
        self.profile.observed.quests[key] = observed
    end
    observed.objectives = objectives
    observed.objectivesUpdatedAt = self:Now()
    local archive = self.db.questArchive.quests[key]
    if archive then
        archive.objectives = objectives
        archive.objectivesUpdatedAt = self:Now()
    end
    self:TouchData("quest:objectives")
end

function FC:RecordCompletedQuest(questID, title, location)
    if not self.initialized or not self.db or not self.db.questArchive then return nil end
    local key = tostring(questID)
    local archive = self.db.questArchive.quests
    local now = self:Now()
    local locale = questLocale()
    local record = archive[key]
    if not record then
        record = {
            id = questID,
            firstCompleted = now,
            lastCompleted = now,
            count = 0,
            names = {},
            locations = {},
            completedBy = {},
        }
        archive[key] = record
    end
    record.names = record.names or {}
    if title and title ~= "" then
        record.names[locale] = title
    end
    record.englishName = record.names.enUS or record.names.enGB or record.englishName
    record.currentName = record.names[locale] or title or record.currentName or string.format(self.L.QUEST_ID, key)
    record.locale = locale
    record.firstCompleted = math.min(record.firstCompleted or now, now)
    record.lastCompleted = math.max(record.lastCompleted or 0, now)
    record.count = (record.count or 0) + 1

    location = questLocation(location or self:GetLocation())
    record.locations = record.locations or {}
    appendQuestLocation(record.locations, location, now, self.characterKey)

    record.completedBy = record.completedBy or {}
    local character = record.completedBy[self.characterKey] or {
        count = 0,
        firstSeen = now,
        name = self.profile and self.profile.identity and self.profile.identity.name or self.characterKey,
    }
    character.count = (character.count or 0) + 1
    character.lastSeen = now
    character.locale = locale
    character.name = character.name or self.characterKey
    record.completedBy[self.characterKey] = character
    self:IndexQuestArchive(record)
    self:TouchData("quest:completed")
    return record
end

function FC:GetQuestArchive()
    local result = {}
    for _, record in pairs(self.db and self.db.questArchive and self.db.questArchive.quests or {}) do
        if (record.count or 0) <= 0 then
            -- Accepted-only entries stay in the raw archive but not in the completed quest view.
        else
        local latest = record.locations and record.locations[#record.locations]
        local names = record.names or {}
        local clientLocale = GetLocale and GetLocale() or "enUS"
        local displayName
        if clientLocale == "deDE" then
            displayName = names.deDE or (record.locale == "deDE" and record.currentName) or record.englishName or names.enUS or names.enGB
        else
            displayName = names.enUS or names.enGB or (record.locale == clientLocale and record.currentName) or record.currentName
        end
        table.insert(result, {
            record = record,
            id = record.id,
            name = displayName or string.format(self.L.QUEST_ID, tostring(record.id)),
            englishName = record.englishName or record.names and (record.names.enUS or record.names.enGB),
            locale = record.locale,
            location = latest,
            continent = latest and latest.continent or self.L.UNKNOWN,
            zone = latest and latest.zone or self.L.UNKNOWN,
            subZone = latest and latest.subZone or "",
            lastCompleted = record.lastCompleted or 0,
        })
        end
    end
    table.sort(result, function(a, b)
        local ac, bc = lower(a.continent), lower(b.continent)
        if ac ~= bc then return ac < bc end
        local az, bz = lower(a.zone), lower(b.zone)
        if az ~= bz then return az < bz end
        local an, bn = lower(a.name), lower(b.name)
        if an ~= bn then return an < bn end
        return (a.id or 0) < (b.id or 0)
    end)
    return result
end

function FC:TrackQuestAccepted(questLogIndex, questID)
    if not self.db.settings.trackQuests then
        return
    end
    if self:IsSecret(questID) then return end
    questID = tonumber(questID)
    if not questID or questID == 0 then
        return
    end
    local title = questTitle(questID, questLogIndex)
    self:RecordAcceptedQuest(questID, title, self:GetLocation())
    self:Observe("quests", questID, title, {
        source = "accepted",
        questState = "accepted",
        location = self:GetLocation(),
    })
    self.profile.stats.questsAccepted = self.profile.stats.questsAccepted + 1
    self.profile.lastState.lastQuestID = questID
    self.profile.lastState.lastQuestTitle = title
    self:LogEvent("QUEST_ACCEPTED", self.L.QUEST_ACCEPTED .. ": " .. title, string.format(self.L.QUEST_ID, questID), {
        questID = questID,
    })
end

function FC:TrackQuestCompleted(questID, experienceReward, moneyReward)
    if not self.db.settings.trackQuests then
        return
    end
    if self:IsSecret(questID) then return end
    if self:IsSecret(experienceReward) then experienceReward = nil end
    if self:IsSecret(moneyReward) then moneyReward = nil end
    questID = tonumber(questID)
    if not questID or questID == 0 then
        return
    end
    local title = questTitle(questID)
    local location = self:GetLocation()
    self:Observe("quests", questID, title, {
        source = "completed",
        questState = "completed",
        location = location,
    })
    self:RecordCompletedQuest(questID, title, location)
    self.profile.stats.questsCompleted = self.profile.stats.questsCompleted + 1
    self.profile.lastState.lastQuestID = questID
    self.profile.lastState.lastQuestTitle = title
    -- Keep the companion snapshot current even if the roster event was delayed.
    if self.TrackCompanions then self:TrackCompanions() end
    self:LogEvent("QUEST_COMPLETED", self.L.QUEST_COMPLETED .. ": " .. title, string.format(self.L.QUEST_ID, questID), {
        questID = questID,
        experienceReward = experienceReward,
        moneyReward = moneyReward,
    })
end

local function containerItem(bagID, slotID)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bagID, slotID)
        if info then
            local itemID, count, link = info.itemID, info.stackCount, info.hyperlink
            if FC:IsSecret(itemID) then itemID = nil end
            if FC:IsSecret(count) or type(count) ~= "number" then count = 1 end
            if FC:IsSecret(link) then link = nil end
            return itemID, count or 1, link
        end
    elseif GetContainerItemInfo then
        local _, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bagID, slotID)
        if FC:IsSecret(itemID) then itemID = nil end
        if FC:IsSecret(count) or type(count) ~= "number" then count = 1 end
        if FC:IsSecret(link) then link = nil end
        return itemID or itemIDFromLink(link), count or 1, link
    end
    return nil, 0, nil
end

local function containerSlots(bagID)
    if C_Container and C_Container.GetContainerNumSlots then
        local count = C_Container.GetContainerNumSlots(bagID)
        return not FC:IsSecret(count) and type(count) == "number" and count or 0
    elseif GetContainerNumSlots then
        local count = GetContainerNumSlots(bagID)
        return not FC:IsSecret(count) and type(count) == "number" and count or 0
    end
    return 0
end

function FC:ScanContainers(target, bagIDs, source)
    if not self.initialized or not self.db.settings.trackInventory then
        return
    end
    local inventory = {}
    for _, bagID in ipairs(bagIDs) do
        for slotID = 1, containerSlots(bagID) do
            local itemID, count, link = containerItem(bagID, slotID)
            if itemID then
                local key = tostring(itemID)
                inventory[key] = (inventory[key] or 0) + (count or 1)
                self:TrackItem(itemID, source, { link = link })
            end
        end
    end
    self.profile.inventory[target] = inventory
    self.profile.inventory[target .. "UpdatedAt"] = self:Now()
    self:TouchData("inventory:" .. tostring(target))
end

function FC:ScanBags()
    local bagIDs = {}
    local maximum = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    for bagID = 0, maximum do
        table.insert(bagIDs, bagID)
    end
    self:ScanContainers("bags", bagIDs, "bag")
end

function FC:ScanBank()
    local bagIDs = { -1 }
    local firstBankBag = (NUM_BAG_SLOTS or 4) + 1
    local bankBags = NUM_BANKBAGSLOTS or 7
    for bagID = firstBankBag, firstBankBag + bankBags - 1 do
        table.insert(bagIDs, bagID)
    end
    self:ScanContainers("bank", bagIDs, "bank")
end

function FC:ScanProfessions()
    if not self.initialized or not self.db.settings.trackProfessions or not GetProfessions or not GetProfessionInfo then
        return
    end
    local professionIDs = { GetProfessions() }
    local now = self:Now()
    for _, professionID in ipairs(professionIDs) do
        if self:IsSecret(professionID) then professionID = nil end
        if type(professionID) == "number" and professionID ~= 0 then
            local name, icon, skillLevel, maxSkillLevel = GetProfessionInfo(professionID)
            if self:IsSecret(name) or type(name) ~= "string" then name = nil end
            if self:IsSecret(icon) or type(icon) ~= "string" and type(icon) ~= "number" then icon = nil end
            if self:IsSecret(skillLevel) or type(skillLevel) ~= "number" then skillLevel = nil end
            if self:IsSecret(maxSkillLevel) or type(maxSkillLevel) ~= "number" then maxSkillLevel = nil end
            if type(name) == "string" and name ~= "" then
                local key = tostring(professionID)
                local record = self.profile.professions[key] or { id = professionID, firstSeen = now }
                record.name = name
                record.icon = icon
                record.skillLevel = tonumber(skillLevel) or record.skillLevel or 0
                record.maxSkillLevel = tonumber(maxSkillLevel) or record.maxSkillLevel or 0
                record.lastSeen = now
                self.profile.professions[key] = record
            end
        end
    end
    self.profile.stats.professionsScanned = (self.profile.stats.professionsScanned or 0) + 1
    self:TouchData("professions")
end

function FC:ScanMerchant(retry)
    if not GetMerchantNumItems then
        return
    end
    local vendor = UnitName("npc")
    if self:IsSecret(vendor) or type(vendor) ~= "string" or vendor == "" then vendor = UnitName("target") end
    if self:IsSecret(vendor) or type(vendor) ~= "string" or vendor == "" then vendor = self.L.UNKNOWN_MERCHANT end
    local vendorGUID = UnitGUID("npc")
    if self:IsSecret(vendorGUID) or type(vendorGUID) ~= "string" or vendorGUID == "" then vendorGUID = UnitGUID("target") end
    local npcID = idFromGUID(vendorGUID)
    local location = self:GetLocation(self:GetInteractedUnitToken())
    local stockCount = GetMerchantNumItems()
    if self:IsSecret(stockCount) or type(stockCount) ~= "number" or stockCount ~= stockCount
        or stockCount < 0 or stockCount > 1000 or stockCount % 1 ~= 0 then return end
    local merchant = self.RememberMerchant and self:RememberMerchant(vendor, npcID, location, not retry)
    local categories = {}
    for index = 1, stockCount do
        local link = GetMerchantItemLink and GetMerchantItemLink(index)
        if self:IsSecret(link) then link = nil end
        local itemID = itemIDFromLink(link)
        local merchantName = link and link:match("%[(.-)%]")
        if not merchantName and GetMerchantItemInfo then
            local ok, visibleName = pcall(GetMerchantItemInfo, index)
            if ok and not self:IsSecret(visibleName) and type(visibleName) == "string" then merchantName = visibleName end
        end
        if itemID then
            local itemName, _, _, itemType, itemSubType = safeItemInfo(itemID)
            if self.db.settings.trackItems then
                self:TrackItem(itemID, "vendor", {
                    link = link,
                    vendor = vendor,
                    location = location,
                })
            end
            if self.RememberMerchantItem then
                self:RememberMerchantItem(merchant, itemID, itemName or merchantName, itemType, itemSubType, link)
            end
            if not itemName and C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
            if merchant and (itemSubType or itemType) then
                local category = itemSubType and itemSubType ~= "" and itemSubType or itemType
                categories[category] = true
            end
        elseif merchant and merchantName and merchantName ~= "" then
            -- Keep a vendor's visible stock name even if the client has not
            -- supplied an item link/ID yet. GET_ITEM_INFO_RECEIVED upgrades it.
            merchant.itemsByName = merchant.itemsByName or {}
            local item = merchant.itemsByName[merchantName] or { firstSeen = self:Now() }
            item.name = merchantName
            item.lastSeen = self:Now()
            merchant.itemsByName[merchantName] = item
        end
    end
    if merchant then
        merchant.categories = merchant.categories or {}
        for category in pairs(categories) do merchant.categories[category] = true end
        if self.SetMerchantVisitCategories then self:SetMerchantVisitCategories(merchant, categories) end
        self:TouchData("merchant-stock")
    end
end

local function scanLootMessage(self, message)
    if self:IsSecret(message) or type(message) ~= "string" then
        return
    end
    for itemID in message:gmatch("item:(%d+)") do
        self:TrackItem(tonumber(itemID), "loot")
    end
end

FC:RegisterEvent("PLAYER_LOGIN", function(self)
    lastLevel = UnitLevel("player")
    if self:IsSecret(lastLevel) or type(lastLevel) ~= "number" then lastLevel = nil end
    self:TrackZone()
    self:TrackInstance()
    self:ScanProfessions()
    lastPlayerHealth = UnitHealth and UnitHealth("player") or nil
    if self:IsSecret(lastPlayerHealth) then lastPlayerHealth = nil end
    if C_Timer and C_Timer.After then
        C_Timer.After(2, function()
            if self.initialized then
                self:ScanBags()
            end
        end)
    else
        self:ScanBags()
    end
end)

FC:RegisterEvent("SKILL_LINES_CHANGED", function(self)
    self:ScanProfessions()
end)

FC:RegisterEvent("PLAYER_LEVEL_UP", function(self, _, level)
    if self:IsSecret(level) then level = nil end
    level = tonumber(level)
    if not level then
        local currentLevel = UnitLevel("player")
        if not self:IsSecret(currentLevel) and type(currentLevel) == "number" then level = currentLevel end
    end
    if self:IsSecret(level) or type(level) ~= "number" then return end
    if level == lastLevel then
        return
    end
    lastLevel = level
    self.profile.identity.level = level
    self.profile.lastState.level = level
    self:LogEvent("LEVEL", self.L.LEVEL_REACHED .. ": " .. level, nil, { level = level })
end)

FC:RegisterEvent("QUEST_ACCEPTED", function(self, _, questLogIndex, questID)
    if self:IsSecret(questID) then return end
    if self:IsSecret(questLogIndex) then questLogIndex = nil end
    self:TrackQuestAccepted(questLogIndex, questID)
    self:CaptureQuestObjectives(questLogIndex, questID)
end)

FC:RegisterEvent("QUEST_LOG_UPDATE", function(self)
    if not self.initialized or not self.db.settings.trackQuests then return end
    local questCount = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries()
        or (GetNumQuestLogEntries and GetNumQuestLogEntries() or 0)
    if self:IsSecret(questCount) or type(questCount) ~= "number" or questCount ~= questCount
        or questCount <= 0 or questCount > 1000 or questCount % 1 ~= 0 then return end
    for index = 1, questCount do
        local title, level, tag, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID
        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(index)
            if info and not self:IsSecret(info) and type(info) == "table" then
                local isHeader = info.isHeader
                if not self:IsSecret(isHeader) and not isHeader then
                    questID = info.questID
                    isComplete = info.isComplete
                end
            end
        elseif GetQuestLogTitle then
            title, level, tag, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(index)
        end
        if not self:IsSecret(questID) and not self:IsSecret(isComplete) and questID and not isComplete then
            self:CaptureQuestObjectives(index, questID)
        end
    end
end)

FC:RegisterEvent("QUEST_TURNED_IN", function(self, _, questID, experienceReward, moneyReward)
    if self:IsSecret(questID) then return end
    if self:IsSecret(experienceReward) then experienceReward = nil end
    if self:IsSecret(moneyReward) then moneyReward = nil end
    self:TrackQuestCompleted(questID, experienceReward, moneyReward)
end)

FC:RegisterEvent("ZONE_CHANGED_NEW_AREA", function(self)
    self:TrackZone()
    self:TrackInstance()
end)

FC:RegisterEvent("ZONE_CHANGED", function(self)
    self:TrackZone()
end)

FC:RegisterEvent("ZONE_CHANGED_INDOORS", function(self)
    self:TrackZone()
end)

FC:RegisterEvent("PLAYER_ENTERING_WORLD", function(self)
    self:TrackZone()
    self:TrackInstance()
end)

FC:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function(self)
    self:TrackUnit("mouseover", "mouseover")
end)

FC:RegisterEvent("PLAYER_TARGET_CHANGED", function(self)
    self:TrackUnit("target", "target")
    updateTargetDefeat(self, true)
end)

FC:RegisterEvent("UNIT_HEALTH", function(self, _, unit)
    if self:IsSecret(unit) or type(unit) ~= "string" then return end
    if unit == "target" then updateTargetDefeat(self, false) end
    if unit == "player" then
        local current = UnitHealth and UnitHealth("player")
        if not self:IsSecret(current) and not self:IsSecret(lastPlayerHealth) and type(current) == "number" then
            local now = self:Now()
            if type(lastPlayerHealth) == "number" and current > lastPlayerHealth and InCombatLockdown then
                local inCombat = InCombatLockdown()
                if not self:IsSecret(inCombat) and inCombat and now - lastRecoveryAt >= 4 then
                    self:LogEvent("HEALTH_RECOVERY", self.L.STAT_HEALING, nil,
                        { observedGain = true })
                    lastRecoveryAt = now
                end
            end
            lastPlayerHealth = current
        end
    end
end)


FC:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(self, _, unit)
    self:TrackUnit(unit, "nameplate")
end)

FC:RegisterEvent("CHAT_MSG_LOOT", function(self, _, message)
    scanLootMessage(self, message)
end)

FC:RegisterEvent("BAG_UPDATE_DELAYED", function(self)
    if bagScanScheduled then
        return
    end
    bagScanScheduled = true
    local function scan()
        bagScanScheduled = false
        if self.initialized then
            self:ScanBags()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.35, scan)
    else
        scan()
    end
end)

FC:RegisterEvent("BANKFRAME_OPENED", function(self)
    self:ScanBank()
end)

FC:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function(self)
    self:ScanBank()
end)

FC:RegisterEvent("MERCHANT_SHOW", function(self)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() self:ScanMerchant() end)
        -- Classic clients can populate merchant links a fraction after the
        -- frame opens. Retry stock capture without counting extra visits.
        C_Timer.After(0.25, function() self:ScanMerchant(true) end)
    else
        self:ScanMerchant()
    end
end)

FC:RegisterEvent("PLAYER_DEAD", function(self)
    if not self.db.settings.recordDeaths then
        return
    end
    self.profile.stats.deaths = self.profile.stats.deaths + 1
    deathPendingResurrection = true
    local name, instanceType
    if GetInstanceInfo then name, instanceType = GetInstanceInfo() end
    if self:IsSecret(name) then name = nil end
    if self:IsSecret(instanceType) then instanceType = nil end
    self:LogEvent("DEATH", self.L.DEATH, nil, {
        instanceName = (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena") and name or nil,
        instanceType = instanceType,
    })
end)

local function recordResurrection(self)
    if not deathPendingResurrection then return end
    deathPendingResurrection = false
    local name, instanceType
    if GetInstanceInfo then name, instanceType = GetInstanceInfo() end
    if self:IsSecret(name) then name = nil end
    if self:IsSecret(instanceType) then instanceType = nil end
    self:LogEvent("RESURRECTION", self.L.RESURRECTION_RECORDED, nil, {
        instanceName = (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena") and name or nil,
        instanceType = instanceType,
    })
end

FC:RegisterEvent("PLAYER_ALIVE", recordResurrection)
FC:RegisterEvent("PLAYER_UNGHOST", recordResurrection)

FC:RegisterEvent("VIGNETTE_MINIMAP_UPDATED", function(self, _, vignetteGUID)
    if self:IsSecret(vignetteGUID) or type(vignetteGUID) ~= "string" then return end
    if not C_VignetteInfo or not C_VignetteInfo.GetVignetteInfo then
        return
    end
    local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if self:IsSecret(info) or type(info) ~= "table" then
        return
    end
    if self:IsSecret(info.objectGUID) then return end
    local npcID = idFromGUID(info.objectGUID)
    if not npcID then
        return
    end
    local name = info.name
    if self:IsSecret(name) or type(name) ~= "string" or name == "" then name = string.format(self.L.NPC_ID, npcID) end
    local atlasName = info.atlasName
    if self:IsSecret(atlasName) or type(atlasName) ~= "string" then atlasName = nil end
    local _, isFirst = self:Observe("rares", npcID, name, {
        source = "vignette",
        location = self:GetLocation(),
    })
    if isFirst then
        self.profile.stats.raresSeen = self.profile.stats.raresSeen + 1
        self:LogEvent("RARE", self.L.RARE_SEEN .. ": " .. name, string.format(self.L.NPC_ID, npcID), {
            npcID = npcID,
            vignetteGUID = vignetteGUID,
            atlasName = atlasName,
        })
    end
end)
