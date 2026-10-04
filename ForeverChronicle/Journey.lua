local _, namespace = ...
local FC = namespace.FC


-- Each character keeps an independent shuffled phrase deck per diary family.
-- A complete deck is consumed before any wording is reused; old records keep
-- their saved choice, and legacy recent-window state is migrated below.
local function chooseDiaryVariant(self, family, count, salt, record)
    if count <= 1 then return 1 end
    record = type(record) == "table" and record or nil
    if record then
        record.diaryVariants = type(record.diaryVariants) == "table" and record.diaryVariants or {}
        local saved = tonumber(record.diaryVariants[family])
        if saved and saved >= 1 and saved <= count then return saved end
    end

    local profile = self.profile
    profile.diaryStyle = type(profile.diaryStyle) == "table" and profile.diaryStyle or {}
    local state = profile.diaryStyle[family]
    if type(state) ~= "table" then
        state = { recent = {} }
        profile.diaryStyle[family] = state
    end

    local function validDeck(deck)
        if type(deck) ~= "table" or #deck ~= count then return false end
        local seen = {}
        for i = 1, count do
            local value = tonumber(deck[i])
            if not value or value < 1 or value > count or value % 1 ~= 0 or seen[value] then
                return false
            end
            seen[value] = true
        end
        return true
    end

    local function shuffledDeck()
        local seed = math.abs(tonumber(salt) or 1)
        local hash = 0
        for i = 1, #family do hash = (hash * 33 + string.byte(family, i)) % 2147483647 end
        seed = (seed + hash + (tonumber(state.cycle) or 0) * 104729
            + (tonumber(time and time()) or 1)) % 2147483647
        if seed == 0 then seed = 1 end
        local function nextRandom(maximum)
            seed = (seed * 48271) % 2147483647
            return (seed % maximum) + 1
        end
        local deck = {}
        for i = 1, count do deck[i] = i end
        for i = count, 2, -1 do
            local j = nextRandom(i)
            deck[i], deck[j] = deck[j], deck[i]
        end
        local previous = tonumber(state.last)
        if count > 1 and previous and deck[1] == previous then
            deck[1], deck[2] = deck[2], deck[1]
        end
        return deck
    end

    -- Migrate old recent-window preferences into the first shuffled cycle.
    -- Every option is still used once; recently used options are moved toward
    -- the back instead of being discarded from the cycle.
    if not validDeck(state.deck) or tonumber(state.count) ~= count then
        local deck = shuffledDeck()
        local recent = {}
        for _, value in ipairs(type(state.recent) == "table" and state.recent or {}) do
            value = tonumber(value)
            if value and value >= 1 and value <= count then recent[value] = true end
        end
        local front, back = {}, {}
        for _, value in ipairs(deck) do
            table.insert(recent[value] and back or front, value)
        end
        for _, value in ipairs(back) do table.insert(front, value) end
        state.deck, state.cursor, state.count = front, 1, count
    end

    local cursor = tonumber(state.cursor) or 1
    if cursor > count then
        state.cycle = (tonumber(state.cycle) or 0) + 1
        state.deck = shuffledDeck()
        cursor = 1
    end
    local selected = state.deck[cursor]
    state.cursor = cursor + 1
    state.last = selected
    state.recent = type(state.recent) == "table" and state.recent or {}
    table.insert(state.recent, selected)
    while #state.recent > math.min(5, count - 1) do table.remove(state.recent, 1) end
    if record then record.diaryVariants[family] = selected end
    return selected
end
local function copyLocation(location)
    if not location then
        return nil
    end
    return {
        mapID = location.mapID,
        continent = location.continent,
        zone = location.zone,
        subZone = location.subZone,
        x = location.x,
        y = location.y,
        unitPosition = location.unitPosition,
        source = location.source,
        firstSeen = location.firstSeen,
        lastSeen = location.lastSeen,
    }
end

local function objectIDFromGUID(guid)
    if FC:IsSecret(guid) or type(guid) ~= "string" then
        return nil
    end
    local objectID = guid:match("^[^-]+%-[^-]*%-[^-]*%-[^-]*%-[^-]*%-(%d+)")
    return tonumber(objectID)
end

local function unitIdentity(unit)
    if FC:IsSecret(unit) or type(unit) ~= "string" then return nil end
    local exists = UnitExists and UnitExists(unit)
    if FC:IsSecret(exists) or not exists then
        return nil
    end
    local name = UnitName and UnitName(unit)
    if FC:IsSecret(name) or type(name) ~= "string" or name == "" then
        return nil
    end
    return { name = name }
end

local function groupUnits()
    local units = {}
    local inRaid = IsInRaid and IsInRaid()
    local inGroup = IsInGroup and IsInGroup()
    if FC:IsSecret(inRaid) then inRaid = false end
    if FC:IsSecret(inGroup) then inGroup = false end
    if inRaid then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        if FC:IsSecret(count) or type(count) ~= "number" then count = 0 end
        for index = 1, count do
            table.insert(units, "raid" .. index)
        end
    elseif inGroup then
        for index = 1, 4 do
            table.insert(units, "party" .. index)
        end
    end
    return units
end

function FC:TrackCompanions()
    if not self.initialized then return end
    if not self.db.settings.trackCompanions then
        self.currentGroupMembers = {}
        return
    end
    local identities = {}
    for _, unit in ipairs(groupUnits()) do
        local identity = unitIdentity(unit)
        if identity then
            table.insert(identities, identity)
        end
    end
    local currentNames = {}
    for _, identity in ipairs(identities) do table.insert(currentNames, identity.name) end
    table.sort(currentNames)
    -- Keep the live roster only long enough to associate names with a shared
    -- quest or dungeon event. Merely joining a group does not create a record.
    self.currentGroupMembers = currentNames
end

function FC:GetCompanions(limit)
    local merged = {}
    for _, profile in pairs(self.db.characters or {}) do
        local ownCharacter = profile.identity and profile.identity.name
        for _, event in ipairs(profile.events or {}) do
            if (event.type == "QUEST_COMPLETED" or event.type == "DUNGEON")
                and type(event.companions) == "table" then
                for _, name in ipairs(event.companions) do
                    if not self:IsSecret(name) and type(name) == "string" and name ~= "" then
                        local eventTime = tonumber(event.ts) or 0
                        local entry = merged[name]
                        if not entry then
                            entry = { key = name, name = name, characters = {}, lastSeen = eventTime }
                            merged[name] = entry
                        end
                        entry.lastSeen = math.max(entry.lastSeen or 0, eventTime)
                        if not self:IsSecret(ownCharacter) and type(ownCharacter) == "string" and ownCharacter ~= "" then
                            entry.characters[ownCharacter] = true
                        end
                    end
                end
            end
        end
    end
    local results = {}
    for _, entry in pairs(merged) do
        table.insert(results, entry)
    end
    table.sort(results, function(a, b)
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)
    while #results > (limit or 250) do
        table.remove(results)
    end
    return results
end

function FC:RememberMerchant(vendorName, npcID, location, countVisit)
    vendorName = self:SanitizeStoredValue(vendorName)
    if type(vendorName) ~= "string" or vendorName == "" then vendorName = FC.L.UNKNOWN_MERCHANT end
    npcID = self:SanitizeStoredValue(npcID)
    if type(npcID) ~= "number" then npcID = nil end
    location = self:SanitizeStoredValue(location)
    local key = tostring(npcID or vendorName)
    local now = self:Now()
    local record = self.profile.merchants[key]
    if not record then
        record = {
            key = key,
            id = npcID,
            name = vendorName,
            firstSeen = now,
            visits = 0,
            items = {},
            locations = {},
        }
        self.profile.merchants[key] = record
        self.profile.stats.merchantsVisited = (self.profile.stats.merchantsVisited or 0) + 1
    end
    record.name = vendorName
    record.lastSeen = now
    if countVisit ~= false then record.visits = (record.visits or 0) + 1 end
    record.location = copyLocation(location or self:GetLocation())
    record.location.source = record.location.source or "merchant"
    record.location.firstSeen = record.location.firstSeen or record.firstSeen
    record.location.lastSeen = now
    self:AddObservationLocation(record, record.location, "merchant")
    local sessionID = self.activeSession and self.activeSession.id
    if countVisit ~= false and sessionID and record.lastDiarySessionID ~= sessionID then
        record.lastDiarySessionID = sessionID
        local event = self:LogEvent("MERCHANT", self.L.DIARY_MERCHANT_VISIT .. ": " .. vendorName, nil, {
            npcID = npcID,
            merchantKey = key,
            merchantName = vendorName,
            location = copyLocation(record.location),
        })
        record.lastDiaryEventID = event and event.id or nil
    end
    self:TouchData("merchant-visit")
    return record
end

function FC:RememberMerchantItem(merchant, itemID, itemName, itemType, itemSubType, link)
    itemID = self:SanitizeStoredValue(itemID)
    itemName = self:SanitizeStoredValue(itemName)
    itemType = self:SanitizeStoredValue(itemType)
    itemSubType = self:SanitizeStoredValue(itemSubType)
    link = self:SanitizeStoredValue(link)
    if type(itemID) ~= "number" then return end
    if type(itemName) ~= "string" then itemName = nil end
    if type(itemType) ~= "string" then itemType = nil end
    if type(itemSubType) ~= "string" then itemSubType = nil end
    if type(link) ~= "string" then link = nil end
    if not merchant or not itemID then
        return
    end
    merchant.items = merchant.items or {}
    local key = tostring(itemID)
    local item = merchant.items[key] or { id = itemID, firstSeen = self:Now() }
    item.name = itemName or item.name or string.format(self.L.ITEM_ID, key)
    item.link = link or item.link
    item.itemType = itemType or item.itemType
    item.itemSubType = itemSubType or item.itemSubType
    item.lastSeen = self:Now()
    merchant.items[key] = item

    local observed = self:GetObservation("items", itemID)
    if observed then
        observed.vendors = observed.vendors or {}
        observed.vendors[merchant.key] = {
            name = merchant.name,
            lastSeen = self:Now(),
            location = copyLocation(merchant.location),
        }
    end
end

function FC:SetMerchantVisitCategories(merchant, categories)
    if not merchant or not merchant.lastDiaryEventID then return end
    local event
    for index = #self.profile.events, 1, -1 do
        local candidate = self.profile.events[index]
        if candidate.id == merchant.lastDiaryEventID then event = candidate; break end
    end
    if not event then return end
    event.data = event.data or {}
    event.data.vendorCategories = {}
    for category in pairs(categories or {}) do table.insert(event.data.vendorCategories, category) end
    table.sort(event.data.vendorCategories)
end

function FC:ScanTrainer()
    if not self.initialized or not self.db.settings.trackTrainers or not GetNumTrainerServices then
        return
    end
    local trainerName = UnitName and UnitName("npc")
    if FC:IsSecret(trainerName) or type(trainerName) ~= "string" or trainerName == "" then trainerName = UnitName and UnitName("target") end
    if FC:IsSecret(trainerName) or type(trainerName) ~= "string" or trainerName == "" then trainerName = FC.L.UNKNOWN_TRAINER end
    local trainerGUID = UnitGUID and UnitGUID("npc")
    if FC:IsSecret(trainerGUID) or type(trainerGUID) ~= "string" or trainerGUID == "" then trainerGUID = UnitGUID and UnitGUID("target") end
    local npcID = objectIDFromGUID(trainerGUID)
    local key = tostring(npcID or trainerName)
    local now = self:Now()
    local trainer = self.profile.trainers[key]
    if not trainer then
        trainer = { key = key, id = npcID, name = trainerName, firstSeen = now, visits = 0, services = {}, locations = {} }
        self.profile.trainers[key] = trainer
        self.profile.stats.trainersVisited = (self.profile.stats.trainersVisited or 0) + 1
    end
    trainer.name = trainerName
    trainer.lastSeen = now
    trainer.visits = (trainer.visits or 0) + 1
    trainer.location = copyLocation(self:GetLocation(self:GetInteractedUnitToken()))
    trainer.location.source = trainer.location.source or "trainer"
    trainer.location.firstSeen = trainer.location.firstSeen or trainer.firstSeen
    trainer.location.lastSeen = now
    local sessionID = self.activeSession and self.activeSession.id
    if sessionID and trainer.lastDiarySessionID ~= sessionID then
        trainer.lastDiarySessionID = sessionID
        self:LogEvent("TRAINER", self.L.DIARY_TRAINER_VISIT .. ": " .. trainerName, nil,
            { npcID = npcID, location = copyLocation(trainer.location) })
    end
    self:AddObservationLocation(trainer, trainer.location, "trainer")
    trainer.services = trainer.services or {}

    local serviceCount = GetNumTrainerServices()
    if FC:IsSecret(serviceCount) or type(serviceCount) ~= "number" or serviceCount ~= serviceCount
        or serviceCount < 0 or serviceCount > 1000 or serviceCount % 1 ~= 0 then return end
    for index = 1, serviceCount do
        local name, rank, category, _, serviceType, _, isLearned = GetTrainerServiceInfo(index)
        if FC:IsSecret(name) or type(name) ~= "string" then name = nil end
        if FC:IsSecret(rank) or type(rank) ~= "string" and type(rank) ~= "number" then rank = nil end
        if FC:IsSecret(category) or type(category) ~= "string" then category = nil end
        if FC:IsSecret(serviceType) or type(serviceType) ~= "string" then serviceType = nil end
        if FC:IsSecret(isLearned) or type(isLearned) ~= "boolean" then isLearned = nil end
        if type(name) == "string" and name ~= "" then
            local serviceKey = tostring(name) .. ":" .. tostring(rank or "")
            local service = trainer.services[serviceKey] or { firstSeen = now }
            service.name = name
            service.rank = rank
            service.category = category
            service.serviceType = serviceType
            service.isLearned = isLearned and true or false
            local icon = GetTrainerServiceIcon and GetTrainerServiceIcon(index)
            local cost = GetTrainerServiceCost and GetTrainerServiceCost(index)
            local requiredLevel = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(index)
            if not FC:IsSecret(icon) and (type(icon) == "number" or type(icon) == "string") then service.icon = icon end
            if not FC:IsSecret(cost) and type(cost) == "number" then service.cost = cost end
            if not FC:IsSecret(requiredLevel) and type(requiredLevel) == "number" then service.requiredLevel = requiredLevel end
            service.lastSeen = now
            trainer.services[serviceKey] = service
        end
    end
end

local function sameZone(a, b)
    if not a or not b then
        return false
    end
    if a.mapID and b.mapID then
        return a.mapID == b.mapID
    end
    return type(a.zone) == "string" and a.zone ~= "" and a.zone == b.zone
end

function FC:ShowLocationReminder(note, characterKey)
    local owner = characterKey and characterKey ~= self.characterKey and (" (" .. characterKey .. ")") or ""
    local message = string.format("%s: %s%s", self.L.REMINDER, note.text or "", owner)
    self:Print(message)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
        RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo.RAID_WARNING)
    elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(message, 1.0, 0.82, 0.2, 1.0)
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_OPEN then
        PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
    end
end

function FC:CheckLocationReminders(location)
    if not self.initialized or not self.db.settings.zoneReminders then
        return
    end
    self.sessionReminderKeys = self.sessionReminderKeys or {}
    for characterKey, profile in pairs(self.db.characters or {}) do
        for _, note in ipairs(profile.notes or {}) do
            local key = characterKey .. ":" .. tostring(note.id or note.ts or note.text)
            if note.archived ~= true and note.remind ~= false and not self.sessionReminderKeys[key] and sameZone(note.location, location) then
                self.sessionReminderKeys[key] = true
                self:ShowLocationReminder(note, characterKey)
            end
        end
    end
end

function FC:BuildSessionSummary(session)
    session = session or self.activeSession
    if not session then
        return nil
    end
    local finish = session.endedAt or self:Now()
    local summary = {
        startedAt = session.startedAt,
        endedAt = finish,
        duration = math.max(0, finish - (session.startedAt or finish)),
        startLevel = session.startLevel,
        endLevel = session.endLevel or self:GetPlayerLevel() or session.startLevel,
        quests = 0,
        areas = 0,
        dungeons = 0,
        rares = 0,
        deaths = 0,
        notes = 0,
        companions = 0,
        interrupted = session.interrupted,
    }
    local areaKeys, companionKeys = {}, {}
    for _, event in ipairs(self.profile.events or {}) do
        if (event.ts or 0) >= (session.startedAt or 0) and (event.ts or 0) <= finish then
            if event.type == "QUEST_COMPLETED" then summary.quests = summary.quests + 1 end
            if event.type == "DUNGEON" then summary.dungeons = summary.dungeons + 1 end
            if event.type == "RARE" then summary.rares = summary.rares + 1 end
            if event.type == "DEATH" then summary.deaths = summary.deaths + 1 end
            if event.type == "NOTE" then summary.notes = summary.notes + 1 end
            if event.type == "QUEST_COMPLETED" or event.type == "DUNGEON" then
                for _, name in ipairs(event.companions or {}) do
                    if not self:IsSecret(name) and type(name) == "string" and name ~= "" then companionKeys[name] = true end
                end
            end
            if event.location then
                local areaKey = tostring(event.location.mapID or event.location.zone or "") .. ":" .. tostring(event.location.subZone or "")
                if areaKey ~= ":" then areaKeys[areaKey] = true end
            end
        end
    end
    for _ in pairs(areaKeys) do summary.areas = summary.areas + 1 end
    for _ in pairs(companionKeys) do summary.companions = summary.companions + 1 end
    return summary
end

local function diaryPlace(location)
    if not location then return nil end
    local place = location.zone
    if not place or place == "" then place = location.subZone end
    if not place or place == "" then place = location.continent end
    return place and place ~= "" and place or nil
end

local function diaryName(self, event)
    if (event.type == "QUEST_ACCEPTED" or event.type == "QUEST_COMPLETED") and event.data and event.data.questID then
        local archive = self.db and self.db.questArchive and self.db.questArchive.quests
        local quest = archive and archive[tostring(event.data.questID)]
        if quest then
            local names = quest.names or {}
            local clientLocale = GetLocale and GetLocale() or ""
            if clientLocale == "deDE" then
                return names.deDE or (quest.locale == "deDE" and quest.currentName) or quest.englishName or quest.currentName or ""
            end
            return names.enUS or names.enGB or (quest.locale == clientLocale and quest.currentName) or quest.currentName or quest.englishName or ""
        end
    end
    local title = tostring(event and event.title or "")
    return title:match("^[^:]+:%s*(.+)$") or title
end

local function diaryNames(self, value)
    local names = {}
    if type(value) == "table" then
        for _, name in ipairs(value) do if name and name ~= "" then table.insert(names, name) end end
    else
        for name in (tostring(value or "") .. ","):gmatch("(.-),") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" then table.insert(names, name) end
        end
    end
    if #names < 2 then return names[1] or self.L.DIARY_COMPANION_UNKNOWN end
    if #names == 2 then return names[1] .. self.L.DIARY_NAME_AND .. names[2] end
    return table.concat(names, self.L.DIARY_NAME_SEPARATOR, 1, #names - 1)
        .. self.L.DIARY_NAME_AND .. names[#names]
end

local function diaryTimePeriod(timestamp, locale)
    local hour = tonumber(date and date("%H", timestamp or 0)) or 12
    if hour >= 5 and hour < 11 then return locale.DIARY_TIME_MORNING end
    if hour >= 11 and hour < 14 then return locale.DIARY_TIME_MIDDAY end
    if hour >= 14 and hour < 18 then return locale.DIARY_TIME_AFTERNOON end
    if hour >= 18 and hour < 22 then return locale.DIARY_TIME_EVENING end
    return locale.DIARY_TIME_NIGHT
end

local function diaryEventText(self, locale, event, index, sessionIndex)
    local salt = (tonumber(event.id) or index or 1) + (tonumber(sessionIndex) or 1) * 37
    local function variant(family, maximum)
        return chooseDiaryVariant(self, family, maximum, salt, event)
    end
    local title = diaryName(self, event)
    if event.type == "CONTINENT_DISCOVERED" then
        local continent = event.data and event.data.continent or title
        return string.format(locale["DIARY_CONTINENT_" .. variant("continent", 48)], continent)
    elseif event.type == "ZONE" then
        local place = diaryPlace(event.location) or title
        return string.format(locale["DIARY_ZONE_" .. variant("zone", 48)], place)
    elseif event.type == "SUBZONE_DISCOVERED" then
        local data = event.data or {}
        local zone = data.zone or (event.location and event.location.zone) or title
        local subzone = data.subZone or title
        return string.format(locale["DIARY_SUBZONE_" .. variant("subzone", 40)], zone, subzone)
    elseif event.type == "QUEST_ACCEPTED" then
        return string.format(locale["DIARY_QUEST_ACCEPTED_" .. variant("questAccepted", 48)], title)
    elseif event.type == "QUEST_COMPLETED" then
        if event.companions and #event.companions > 0 then
            return string.format(locale["DIARY_SHARED_QUEST_" .. variant("questShared", 28)], diaryNames(self, event.companions), title)
        end
        return string.format(locale["DIARY_QUEST_COMPLETED_" .. variant("questCompleted", 48)], title)
    elseif event.type == "LEVEL" then
        local level = event.data and event.data.level or title:match("(%d+)%s*$") or ""
        return string.format(locale["DIARY_LEVEL_" .. variant("level", 40)], tostring(level))
    elseif event.type == "DUNGEON" then
        if event.companions and #event.companions > 0 then
            return string.format(locale["DIARY_SHARED_DUNGEON_" .. variant("dungeonShared", 40)], diaryNames(self, event.companions), title)
        end
        return string.format(locale["DIARY_DUNGEON_" .. variant("dungeon", 40)], title)
    elseif event.type == "BOSS_DEFEATED" then
        return string.format(locale.DIARY_BOSS_DEFEATED, title, (event.data and event.data.instanceName) or event.detail or "")
    elseif event.type == "RARE" then
        return string.format(locale["DIARY_RARE_" .. variant("rare", 48)], title)
    elseif event.type == "GATHER" then
        return string.format(locale["DIARY_GATHER_" .. variant("gather", 40)], title)
    elseif event.type == "ITEM" then
        if event.detail == "loot" then
        return string.format(locale["DIARY_ITEM_LOOT_" .. variant("itemLoot", 40)], title)
        elseif event.detail == "vendor" then
        return string.format(locale["DIARY_ITEM_VENDOR_" .. variant("itemVendor", 40)], title)
        end
        return string.format(locale["DIARY_ITEM_" .. variant("item", 40)], title)
    elseif event.type == "NPC_DISCOVERY" then
        return string.format(locale["DIARY_NPC_DISCOVERY_" .. variant("npc", 40)], title)
    elseif event.type == "DEATH" then
        return locale["DIARY_DEATH_" .. variant("death", 40)]
    elseif event.type == "RESURRECTION" then
        return locale["DIARY_RESURRECTION_" .. variant("resurrection", 40)]
    elseif event.type == "HEALTH_RECOVERY" then
        return locale["DIARY_HEALTH_RECOVERY_" .. variant("healthRecovery", 20)]
    elseif event.type == "EAT" then
        return locale["DIARY_EAT_" .. variant("eat", 20)]
    elseif event.type == "DRINK" then
        return locale["DIARY_DRINK_" .. variant("drink", 20)]
    elseif event.type == "NOTE" then
        return string.format(locale["DIARY_NOTE_" .. variant("note", 40)], tostring(event.detail or ""))
    elseif event.type == "COMPANION" then
        return string.format(locale["DIARY_COMPANIONS_" .. variant("companion", 40)], diaryNames(self, event.detail))
    elseif event.type == "MERCHANT" then
        local merchantName = event.data and event.data.merchantName or title
        local categories = event.data and event.data.vendorCategories or {}
        local categoryText = #categories > 0 and diaryNames(self, categories) or locale.DIARY_MERCHANT_GENERAL
        local location = event.location or {}
        -- Coordinates are kept in the event for search/map use. They make the
        -- diary prose read like a log, so use only the familiar named zone.
        local place = location.zone or location.subZone or locale.DIARY_UNKNOWN_PLACE
        return string.format(locale["DIARY_MERCHANT_" .. variant("merchant", 40)], merchantName, place, categoryText)
    elseif event.type == "TRAINER" then
        return string.format(locale["DIARY_TRAINER_" .. variant("trainer", 40)], title)
    elseif event.type == "DAILY_RETURN" then
        local place = diaryPlace(event.location)
        if place then
            return string.format(locale["DIARY_RETURN_" .. variant("return", 24)], diaryTimePeriod(event.ts, locale), place)
        end
        return string.format(locale.DIARY_RETURN_UNKNOWN, diaryTimePeriod(event.ts, locale))
    elseif event.type == "DAILY_INTERRUPTED" then
        return locale.DIARY_INTERRUPTED
    end
    return nil
end

local function diaryGroupKey(event)
    if event.type == "GATHER" or event.type == "NPC_DISCOVERY"
        or event.type == "TRAINER" or event.type == "KILL" then
        return event.type
    end
    if event.type == "ITEM" then
        return "ITEM:" .. tostring(event.detail or "other")
    end
end

local function diaryGroupOrder(eventType)
    if eventType == "GATHER" then return 1 end
    if eventType == "NPC_DISCOVERY" then return 2 end
    if eventType == "ITEM:loot" then return 3 end
    if eventType == "ITEM:vendor" then return 4 end
    if eventType == "ITEM" then return 5 end
    if eventType == "KILL" then return 6 end
    if eventType == "MERCHANT" then return 7 end
    if eventType == "TRAINER" then return 8 end
    return 9
end

local function sameDiaryGroupPlace(a, b)
    if a and b and a.mapID and b.mapID then return a.mapID == b.mapID end
    return diaryPlace(a) == diaryPlace(b)
end

local function diaryGroupedNames(self, group)
    local names, seen = {}, {}
    local fold = function(value) return FC:LowerText(value) end
    for _, event in ipairs(group.events) do
        local name = diaryName(self, event)
        local data = event.data or {}
        local identity = data.npcID or data.itemID or fold(name)
        identity = tostring(identity)
        if name ~= "" and name ~= self.L.DIARY_COMPANION_UNKNOWN and not seen[identity] then
            seen[identity] = true
            table.insert(names, name)
        end
    end
    if #names <= 3 then return diaryNames(self, names) end
    local visible = { names[1], names[2] }
    return string.format(self.L.DIARY_NAMES_AND_MORE, table.concat(visible, self.L.DIARY_NAME_SEPARATOR), #names - #visible)
end

local function diarySampleNames(events, eventType, maximum)
    local names, seen = {}, {}
    for _, event in ipairs(events or {}) do
        if event.type == eventType then
            local data = event.data or {}
            local name = data.questTitle or data.merchantName or data.trainerName or data.name or event.title
            if type(name) == "string" then
                name = name:match(".*:%s*(.+)$") or name
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
            end
            if eventType == "MERCHANT" and type(data.vendorCategories) == "table" and #data.vendorCategories > 0 then
                name = tostring(name) .. " (" .. table.concat(data.vendorCategories, ", ") .. ")"
            end
            if type(name) == "string" and name ~= "" and not seen[name] then
                seen[name] = true
                table.insert(names, name)
                if #names >= maximum then break end
            end
        end
    end
    return names
end

local function diaryLevelSamples(events, maximum, locale)
    local names = {}
    for _, event in ipairs(events or {}) do
        if event.type == "LEVEL" then
            local level = tonumber(event.data and event.data.level)
            if level then
                table.insert(names, string.format(locale.LEVEL_SHORT .. " %d", level))
                if #names >= maximum then break end
            end
        end
    end
    return names
end

local function diaryAreaSamples(events, maximum)
    local names, seen = {}, {}
    for _, event in ipairs(events or {}) do
        local name
        if event.type == "SUBZONE_DISCOVERED" then
            name = event.data and event.data.subZone or event.title
        elseif event.type == "ZONE" then
            name = event.location and (event.location.subZone or event.location.zone) or event.title
        end
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(names, name)
            if #names >= maximum then break end
        end
    end
    return names
end

local function diaryFactSentence(self, locale, key, count, names, salt, record)
    local form = count == 1 and "_ONE" or ""
    local family = "summaryFact:" .. key .. form
    local variant = chooseDiaryVariant(self, family, 89, salt, record)
    if variant <= 3 then
        local pattern = locale[key .. form .. (variant == 1 and "" or "_" .. variant)]
        if count == 1 then return string.format(pattern, names) end
        return string.format(pattern, count, names)
    end
    if count == 1 then
        local pattern = locale["DIARY_PERIOD_FACT_ONE_FRAME_" .. variant]
        local label = locale["DIARY_PERIOD_FACT_ONE_LABEL_" .. key:match("DIARY_PERIOD_FACT_(.+)")]
        return string.format(pattern, label, names)
    end
    local pattern = locale["DIARY_PERIOD_FACT_FRAME_" .. variant]
    local label = locale["DIARY_PERIOD_FACT_LABEL_" .. key:match("DIARY_PERIOD_FACT_(.+)")]
    return string.format(pattern, count, label, names)
end

local function selectDiaryPassages(orderedBody, limit)
    local weight = {
        NOTE = 10, QUEST_COMPLETED = 9, LEVEL = 9, DUNGEON = 9, BOSS_DEFEATED = 9,
        CONTINENT_DISCOVERED = 8, RARE = 8, DEATH = 7, ZONE = 7,
        SUBZONE_DISCOVERED = 6, QUEST_ACCEPTED = 6, ITEM = 5, DAILY_RETURN = 5,
        RESURRECTION = 4, COMPANION = 4, GATHER = 4, NPC_DISCOVERY = 4,
        MERCHANT = 3, TRAINER = 3, KILL = 2,
        HEALTH_RECOVERY = 1, EAT = 1, DRINK = 1,
    }
    local ranked = {}
    for _, part in ipairs(orderedBody or {}) do
        ranked[#ranked + 1] = { part = part, score = weight[part.eventType] or 3 }
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.part.index < b.part.index
    end)
    local selected = {}
    for index = 1, math.min(limit, #ranked) do selected[#selected + 1] = ranked[index].part end
    table.sort(selected, function(a, b) return a.index < b.index end)
    return selected
end

local function buildLongPeriodSummary(self, locale, session, orderedBody, sessionIndex, diaryLength)
    local kind = session.periodKind == "years" and "YEARS" or "MONTHS"
    local openingVariant = chooseDiaryVariant(self, "periodSummary:" .. kind, 24,
        (session.startedAt or sessionIndex or 1) + 29, session)
    local openingKey = "DIARY_PERIOD_SUMMARY_" .. kind
        .. (openingVariant > 1 and ("_" .. openingVariant) or "")
    local opening = locale[openingKey] or locale["DIARY_PERIOD_SUMMARY_" .. kind]

    -- Longer chapters prioritize milestones; the selected length controls
    -- how many chronological passages make it into the generated text.
    local limits = session.periodKind == "years" and { 6, 12, 22, 32 } or { 4, 8, 14, 20 }
    local limit = limits[diaryLength] or limits[4]
    local selected = selectDiaryPassages(orderedBody, limit)

    local lines = { opening }
    for _, part in ipairs(selected) do table.insert(lines, part.text) end
    if #selected == 0 then table.insert(lines, locale.DIARY_QUIET) end
    return lines
end

local function buildDayNarrativeBody(self, locale, events, counts, areas, session, sessionIndex, diaryLength)
    local areaCount = 0
    for _ in pairs(areas) do areaCount = areaCount + 1 end
    local questNames = diarySampleNames(events, "QUEST_COMPLETED", 2)
    for _, name in ipairs(diarySampleNames(events, "QUEST_ACCEPTED", 2)) do
        local found = false
        for _, existing in ipairs(questNames) do if existing == name then found = true; break end end
        if not found and #questNames < 2 then table.insert(questNames, name) end
    end
    local sentences = { route = {}, adventure = {}, quieter = {} }
    local facts = {
        { "QUEST_COMPLETED", "DIARY_PERIOD_FACT_QUESTS", questNames, (counts.QUEST_COMPLETED or 0) + (counts.QUEST_ACCEPTED or 0) },
        { "LEVEL", "DIARY_PERIOD_FACT_LEVELS", diaryLevelSamples(events, 2, locale), counts.LEVEL or 0 },
        { "DEATH", "DIARY_PERIOD_FACT_DEATHS", diarySampleNames(events, "DEATH", 2), counts.DEATH or 0 },
        { "HEALTH_RECOVERY", "DIARY_PERIOD_FACT_HEALING", diarySampleNames(events, "HEALTH_RECOVERY", 2), counts.HEALTH_RECOVERY or 0 },
        { "EAT", "DIARY_PERIOD_FACT_MEALS", diarySampleNames(events, "EAT", 2), counts.EAT or 0 },
        { "DRINK", "DIARY_PERIOD_FACT_DRINKS", diarySampleNames(events, "DRINK", 2), counts.DRINK or 0 },
        { "ZONE", "DIARY_PERIOD_FACT_AREAS", diaryAreaSamples(events, 2), areaCount },
        { "KILL", "DIARY_PERIOD_FACT_KILLS", diarySampleNames(events, "KILL", 2), counts.KILL or 0 },
        { "RARE", "DIARY_PERIOD_FACT_RARES", diarySampleNames(events, "RARE", 2), counts.RARE or 0 },
        { "DUNGEON", "DIARY_PERIOD_FACT_DUNGEONS", diarySampleNames(events, "DUNGEON", 2), counts.DUNGEON or 0 },
        { "GATHER", "DIARY_PERIOD_FACT_GATHERING", diarySampleNames(events, "GATHER", 2), counts.GATHER or 0 },
        { "MERCHANT", "DIARY_PERIOD_FACT_MERCHANTS", diarySampleNames(events, "MERCHANT", 2), counts.MERCHANT or 0 },
        { "TRAINER", "DIARY_PERIOD_FACT_TRAINERS", diarySampleNames(events, "TRAINER", 2), counts.TRAINER or 0 },
        { "ITEM", "DIARY_PERIOD_FACT_ITEMS", diarySampleNames(events, "ITEM", 2), counts.ITEM or 0 },
    }
    local factPriority = {
        QUEST_COMPLETED = 8, LEVEL = 8, DUNGEON = 8, RARE = 8, DEATH = 7,
        ZONE = 6, KILL = 5, ITEM = 5, GATHER = 4, MERCHANT = 4,
        TRAINER = 4, HEALTH_RECOVERY = 2, EAT = 2, DRINK = 2,
    }
    local factLimit = ({ 5, 8, 11, 14 })[diaryLength] or 14
    local rankedFacts = {}
    for factIndex, fact in ipairs(facts) do
        if (fact[4] or 0) > 0 then
            rankedFacts[#rankedFacts + 1] = { index = factIndex, priority = factPriority[fact[1]] or 1 }
        end
    end
    table.sort(rankedFacts, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.index < b.index
    end)
    local includedFacts = {}
    for index = 1, math.min(factLimit, #rankedFacts) do includedFacts[rankedFacts[index].index] = true end
    for factIndex, fact in ipairs(facts) do
        local count = fact[4]
        if count > 0 and includedFacts[factIndex] then
            local samples = fact[3]
            local names = #samples > 0 and table.concat(samples, locale.DIARY_NAME_SEPARATOR or ", ")
                or locale.DIARY_PERIOD_NO_NAMES
            local key = fact[2]
            local sentence = diaryFactSentence(self, locale, key, count, names,
                (session.startedAt or sessionIndex or 1) + factIndex * 97, session)
            local destination = (fact[1] == "QUEST_COMPLETED" or fact[1] == "ZONE" or fact[1] == "LEVEL") and "route"
                or (fact[1] == "KILL" or fact[1] == "RARE" or fact[1] == "DUNGEON" or fact[1] == "DEATH") and "adventure"
                or "quieter"
            table.insert(sentences[destination], sentence)
        end
    end

    local paragraphs = {}
    if #sentences.route > 0 then table.insert(paragraphs, table.concat(sentences.route, " ")) end
    if #sentences.adventure > 0 then
        local bridge = chooseDiaryVariant(self, "dayAdventureBridge", 24, session.startedAt or sessionIndex, session)
        table.insert(paragraphs, locale["DIARY_DAY_ADVENTURE_" .. bridge] .. " " .. table.concat(sentences.adventure, " "))
    end
    if #sentences.quieter > 0 then
        local bridge = chooseDiaryVariant(self, "dayQuieterBridge", 24, (session.startedAt or sessionIndex) + 11, session)
        table.insert(paragraphs, locale["DIARY_DAY_QUIETER_" .. bridge] .. " " .. table.concat(sentences.quieter, " "))
    end

    local returns, seenPlaces = {}, {}
    for _, event in ipairs(events or {}) do
        if event.type == "DAILY_RETURN" then
            local place = diaryPlace(event.location)
            if place and not seenPlaces[place] then
                seenPlaces[place] = true
                table.insert(returns, place)
            end
        end
    end
    if #returns > 0 then
        table.insert(paragraphs, string.format(locale.DIARY_DAY_RETURN, table.concat(returns, locale.DIARY_NAME_SEPARATOR)))
    end
    if #paragraphs == 0 then table.insert(paragraphs, locale.DIARY_QUIET) end
    return paragraphs
end

function FC:BuildDiaryNarrative(session, events, sessionIndex)
    if not session then return "" end
    events = events or {}
    sessionIndex = sessionIndex or 1
    local locale = self.L
    local diaryLength = math.floor(tonumber(self.profile and self.profile.diaryLength) or 4)
    if diaryLength < 1 or diaryLength > 4 then diaryLength = 4 end
    local startTime = session.startedAt or (events[1] and events[1].ts) or self:Now()
    local finish = session.endedAt or self:Now()
    -- A session must not borrow a later discovery as its departure point. LOGIN
    -- is the authoritative per-session location; only old sessions without a
    -- LOGIN event may fall back to their first recorded event.
    local loginLocation
    local sawLogin = false
    for _, event in ipairs(events) do
        if event.type == "LOGIN" then
            sawLogin = true
            if event.location then loginLocation = diaryPlace(event.location) end
            -- In a daily summary, only the first session's login can establish
            -- the day's departure point. Never borrow a later login's location.
            if session.dailySummary or loginLocation then break end
        end
    end
    local startPlace = diaryPlace(session.startLocation) or loginLocation
    if not startPlace and not sawLogin then
        startPlace = diaryPlace(events[1] and events[1].location)
    end
    local endPlace = diaryPlace(session.endLocation)
    if not endPlace and #events > 0 then endPlace = diaryPlace(events[#events].location) end

    local openingIndex = chooseDiaryVariant(self, "opening", 40, session.startedAt or sessionIndex, session)
    local opening
    if startPlace then
        opening = string.format(locale["DIARY_OPEN_" .. openingIndex], diaryTimePeriod(startTime, locale), startPlace)
    else
        opening = locale.DIARY_OPEN_UNKNOWN
    end

    local orderedBody, groups, counts, areas = {}, {}, {}, {}
    local lastGroup
    local currentPlace = startPlace
    for index, event in ipairs(events) do
        if event.type == "LOGIN" then
            -- Ignore the technical login marker in prose; a daily-return event
            -- below is the human-readable boundary between two sessions.
        elseif event.type ~= "LOGIN" then
            local groupKey = diaryGroupKey(event)
            if groupKey then
                local bucketKey = event.type == "ITEM" and ("ITEM:" .. tostring(event.detail or "other")) or groupKey
                -- Only combine adjacent events of the same kind. A session-wide
                -- bucket made later fights or discoveries appear out of order.
                local previousEvent = lastGroup and lastGroup.events[#lastGroup.events]
                local group = lastGroup and lastGroup.key == bucketKey and previousEvent
                    and sameDiaryGroupPlace(previousEvent.location, event.location) and lastGroup or nil
                if not group then
                    group = { key = bucketKey, type = event.type, detail = event.detail, events = {}, index = index }
                    table.insert(groups, group)
                end
                table.insert(group.events, event)
                counts[event.type] = (counts[event.type] or 0) + 1
                lastGroup = group
            else
                lastGroup = nil
                local text = diaryEventText(self, locale, event, index, sessionIndex)
                if event.type == "ZONE" then
                    local place = diaryPlace(event.location)
                    if place and place == currentPlace then text = nil end
                    if place then currentPlace = place end
                    if text then areas[place or text] = true end
                elseif event.type == "SUBZONE_DISCOVERED" then
                    local data = event.data or {}
                    local place = data.subZone or event.title
                    if place and place ~= "" then areas[place] = true end
                end
                if text then
                    counts[event.type] = (counts[event.type] or 0) + 1
                    table.insert(orderedBody, { index = index, text = text, eventType = event.type })
                end
            end
        end
    end

    table.sort(groups, function(a, b)
        if a.index ~= b.index then return a.index < b.index end
        return diaryGroupOrder(a.key) < diaryGroupOrder(b.key)
    end)
    local groupPassages = {}
    for _, group in ipairs(groups) do
        local first = group.events[1]
        local groupedEvent = {}
        for key, value in pairs(first) do groupedEvent[key] = value end
        groupedEvent.title = diaryGroupedNames(self, group)
        if group.type == "ITEM" then
            if group.key == "ITEM:loot" then
                groupedEvent.detail = "loot"
            elseif group.key == "ITEM:vendor" then
                groupedEvent.detail = "vendor"
            else
                groupedEvent.detail = nil
            end
        end
        local text
        if group.type == "KILL" then
            local variantIndex = chooseDiaryVariant(self, "killGroup", 40,
                (tonumber(first.id) or group.index or 1) + (tonumber(sessionIndex) or 1) * 37, first)
            text = string.format(locale["DIARY_KILL_GROUP_" .. variantIndex], #group.events,
                diaryGroupedNames(self, group))
        else
            text = diaryEventText(self, locale, groupedEvent, group.index, sessionIndex)
        end
        if text then
            table.insert(groupPassages, { index = group.index, text = text, eventType = group.type })
        end
    end

    -- Merge milestones and category summaries by their first observed event index.
    for _, groupPassage in ipairs(groupPassages) do table.insert(orderedBody, groupPassage) end
    table.sort(orderedBody, function(a, b) return a.index < b.index end)
    local bodyParts = {}
    for _, part in ipairs(orderedBody) do table.insert(bodyParts, part.text) end
    if #bodyParts == 0 then table.insert(bodyParts, locale.DIARY_QUIET) end
    if session.dailySummary then
        bodyParts = buildDayNarrativeBody(self, locale, events, counts, areas, session, sessionIndex, diaryLength)
    elseif session.periodKind == "months" or session.periodKind == "years" then
        bodyParts = buildLongPeriodSummary(self, locale, session, orderedBody, sessionIndex, diaryLength)
    elseif diaryLength < 4 then
        local limits = { 4, 8, 15 }
        local selected = selectDiaryPassages(orderedBody, limits[diaryLength])
        bodyParts = {}
        for _, part in ipairs(selected) do bodyParts[#bodyParts + 1] = part.text end
        if #bodyParts == 0 then bodyParts[1] = locale.DIARY_QUIET end
    end
    local period = diaryTimePeriod(finish, locale)
    local ending
    if session.endedAt then
        local endingIndex = chooseDiaryVariant(self, "ending", 40, session.startedAt or sessionIndex, session)
        if endPlace then
            ending = string.format(locale["DIARY_END_" .. endingIndex], period, endPlace)
        else
            ending = locale.DIARY_END_UNKNOWN
        end
        if session.interrupted then
            ending = ending .. " " .. locale.DIARY_INTERRUPTED
        end
    else
        ending = endPlace and string.format(locale.DIARY_STILL_TRAVELLING, endPlace)
            or locale.DIARY_STILL_TRAVELLING_UNKNOWN
    end
    local periodKind = session.periodKind
    if periodKind == "weeks" or periodKind == "months" or periodKind == "years" then
        local periodTag = periodKind:sub(1, 1):upper() .. periodKind:sub(2)
        local openVariant = chooseDiaryVariant(self, "periodOpen:" .. periodKind, 24,
            session.startedAt or sessionIndex, session)
        opening = string.format(locale["DIARY_PERIOD_OPEN_" .. periodTag .. "_" .. openVariant],
            startPlace or locale.DIARY_UNKNOWN_PLACE, endPlace or locale.DIARY_UNKNOWN_PLACE)
        if periodKind == "months" or periodKind == "years" then
            local wrapVariant = chooseDiaryVariant(self, "periodWrap:" .. periodKind, 24,
                (session.startedAt or sessionIndex) + 53, session)
            local wrapKey = "DIARY_PERIOD_WRAP_" .. periodTag
                .. (wrapVariant > 1 and ("_" .. wrapVariant) or "")
            ending = string.format(locale[wrapKey] or locale["DIARY_PERIOD_WRAP_" .. periodTag],
                tonumber(session.periodSessionCount) or 1)
        else
            local highlights = {}
            if (counts.QUEST_COMPLETED or 0) > 0 then
                table.insert(highlights, string.format(locale.DIARY_PERIOD_QUESTS, counts.QUEST_COMPLETED))
            end
            if diaryLength >= 2 and (counts.KILL or 0) > 0 then
                table.insert(highlights, string.format(locale.DIARY_PERIOD_KILLS, counts.KILL))
            end
            if diaryLength >= 3 and (counts.MERCHANT or 0) > 0 then
                table.insert(highlights, string.format(locale.DIARY_PERIOD_MERCHANTS, counts.MERCHANT))
            end
            if (counts.DUNGEON or 0) > 0 then
                table.insert(highlights, string.format(locale.DIARY_PERIOD_DUNGEONS, counts.DUNGEON))
            end
            if #highlights == 0 then table.insert(highlights, locale.DIARY_PERIOD_QUIET) end
            local recap = table.concat(highlights, locale.DIARY_NAME_SEPARATOR)
            local endVariant = chooseDiaryVariant(self, "periodEnd:" .. periodKind, 24,
                (session.startedAt or sessionIndex) + 17, session)
            ending = string.format(locale["DIARY_PERIOD_END_" .. periodTag .. "_" .. endVariant],
                endPlace or locale.DIARY_UNKNOWN_PLACE, recap, tonumber(session.periodSessionCount) or 1)
        end
    end
    return table.concat({ opening, table.concat(bodyParts, "\n"), ending }, "\n"), {
        startedAt = startTime,
        endedAt = finish,
        duration = math.max(0, finish - startTime),
        startPlace = startPlace,
        endPlace = endPlace,
        events = #events,
        quests = (counts.QUEST_ACCEPTED or 0) + (counts.QUEST_COMPLETED or 0),
        areas = (function() local count = 0; for _ in pairs(areas) do count = count + 1 end; return count end)(),
        dungeons = counts.DUNGEON or 0,
        rares = counts.RARE or 0,
        kills = counts.KILL or 0,
        merchants = counts.MERCHANT or 0,
        deaths = counts.DEATH or 0,
        companions = counts.COMPANION or 0,
    }
end

function FC:DiaryEntryMatchesQuery(entry, query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local fold = function(value) return FC:LowerText(value) end
    query = fold(query)
    if query == "" then return true end
    local terms = { entry and entry.narrative or "", entry and entry.dayKey or "" }
    local entryTimestamp = entry and entry.session and entry.session.startedAt
    if entryTimestamp and date then
        table.insert(terms, date(self.L.DIARY_DAY_DATE_FORMAT, entryTimestamp))
        table.insert(terms, date(self.L.DIARY_DATE_FORMAT, entryTimestamp))
    end
    local function addLocation(location)
        if not location then return end
        table.insert(terms, location.continent or "")
        table.insert(terms, location.zone or "")
        table.insert(terms, location.subZone or "")
        table.insert(terms, tostring(location.mapID or ""))
        if location.x then
            table.insert(terms, tostring(location.x))
            table.insert(terms, string.format("%.1f", location.x * 100))
        end
        if location.y then
            table.insert(terms, tostring(location.y))
            table.insert(terms, string.format("%.1f", location.y * 100))
        end
    end
    local session = entry and entry.session or {}
    addLocation(session.startLocation)
    addLocation(session.endLocation)
    for _, event in ipairs(entry and entry.events or {}) do
        table.insert(terms, event.title or "")
        table.insert(terms, event.detail or "")
        for _, name in ipairs(event.companions or {}) do table.insert(terms, name) end
        addLocation(event.location)
        local data = event.data or {}
        table.insert(terms, tostring(data.questID or ""))
        table.insert(terms, tostring(data.itemID or ""))
        table.insert(terms, tostring(data.npcID or ""))
    end
    return fold(table.concat(terms, " ")):find(query, 1, true) ~= nil
end

local function localDayKey(timestamp)
    return date and date("%Y-%m-%d", timestamp or 0) or tostring(timestamp or 0)
end

function FC:GetDiaryEntries()
    local profile = self.profile
    if not profile then return {} end
    local entries, byID = {}, {}
    for index, session in ipairs(profile.sessions or {}) do
        local entry = {
            session = session, events = {}, index = index,
            dayKey = session.dayKey or localDayKey(session.startedAt),
        }
        table.insert(entries, entry)
        if session.id then byID[tostring(session.id)] = entry end
    end
    table.sort(entries, function(a, b)
        return (a.session.startedAt or 0) < (b.session.startedAt or 0)
    end)

    local cursor = 1
    for _, event in ipairs(profile.events or {}) do
        local entry = event.sessionID and byID[tostring(event.sessionID)] or nil
        if not entry then
            while cursor < #entries do
                local nextSession = entries[cursor + 1].session
                local belongsToNext
                if nextSession.eventStartID then
                    belongsToNext = (tonumber(event.id) or 0) >= nextSession.eventStartID
                else
                    belongsToNext = (event.ts or 0) >= (nextSession.startedAt or math.huge)
                end
                if belongsToNext then cursor = cursor + 1 else break end
            end
            local candidate = entries[cursor]
            if candidate then
                local session = candidate.session
                local inRange = session.eventStartID
                    and (tonumber(event.id) or 0) >= session.eventStartID
                    or not session.eventStartID and (event.ts or 0) >= (session.startedAt or 0)
                if session.endedAt then inRange = inRange and (event.ts or 0) <= session.endedAt end
                if session.eventEndID then inRange = inRange and (tonumber(event.id) or 0) <= session.eventEndID end
                if inRange then entry = candidate end
            end
        end
        -- Keep LOGIN in the private session event list so its location can
        -- anchor the story even when the first other recorded event is later.
        if entry then table.insert(entry.events, event) end
    end

    local function sessionForTimestamp(timestamp)
        local low, high, found = 1, #entries, nil
        while low <= high do
            local middle = math.floor((low + high) / 2)
            if (entries[middle].session.startedAt or 0) <= timestamp then
                found = entries[middle]
                low = middle + 1
            else
                high = middle - 1
            end
        end
        if found and (not found.session.endedAt or timestamp <= found.session.endedAt) then return found end
    end

    -- The discovery archive contains the first verified loot/vendor finds and
    -- first named non-hostile NPC observations, including records that predate
    -- the detailed session-event journal. Add these to the matching session.
    for _, discovery in ipairs(profile.discoveries or {}) do
        local eventType
        if discovery.kind == "items" and (discovery.source == "loot" or discovery.source == "vendor") then
            eventType = "ITEM"
        elseif discovery.kind == "npcs" then
            local npc = profile.observed and profile.observed.npcs
                and profile.observed.npcs[tostring(discovery.id)]
            if npc and npc.npcRole == "npc" then eventType = "NPC_DISCOVERY" end
        end
        if eventType and discovery.ts then
            local entry = sessionForTimestamp(discovery.ts)
            local duplicate = false
            if entry and eventType == "ITEM" then
                for _, event in ipairs(entry.events) do
                    local itemID = event.data and event.data.itemID
                    if event.type == "ITEM" and (tostring(itemID or "") == tostring(discovery.id)
                        or event.title == discovery.name and math.abs((event.ts or 0) - discovery.ts) <= 2) then
                        duplicate = true
                        break
                    end
                end
            end
            if entry and not duplicate then
                table.insert(entry.events, {
                    ts = discovery.ts,
                    type = eventType,
                    title = discovery.name,
                    detail = discovery.source,
                    data = eventType == "ITEM" and { itemID = discovery.id }
                        or eventType == "NPC_DISCOVERY" and { npcID = discovery.id } or nil,
                    location = discovery.location,
                    syntheticDiscovery = true,
                })
            end
        end
    end

    for _, entry in ipairs(entries) do
        table.sort(entry.events, function(a, b)
            if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) < (b.ts or 0) end
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
        end)
        entry.narrative, entry.summary = self:BuildDiaryNarrative(entry.session, entry.events, entry.index)
    end
    table.sort(entries, function(a, b)
        return (a.session.startedAt or 0) > (b.session.startedAt or 0)
    end)
    return entries
end

function FC:GetDailyDiaryEntries()
    local sessions = self:GetDiaryEntries()
    local days, byDay = {}, {}
    for _, entry in ipairs(sessions) do
        local session = entry.session or {}
        local dayKey = session.dayKey or localDayKey(session.startedAt)
        local day = byDay[dayKey]
        if not day then
            day = { dayKey = dayKey, sessions = {}, events = {} }
            byDay[dayKey] = day
            table.insert(days, day)
        end
        table.insert(day.sessions, entry)
        for _, event in ipairs(entry.events or {}) do
            table.insert(day.events, event)
        end
    end

    for _, day in ipairs(days) do
        table.sort(day.sessions, function(a, b)
            return (a.session.startedAt or 0) < (b.session.startedAt or 0)
        end)
        local firstEntry = day.sessions[1]
        local lastEntry = day.sessions[#day.sessions]
        local firstSession = firstEntry.session
        local lastSession = lastEntry.session
        for index = 2, #day.sessions do
            local previous = day.sessions[index - 1].session
            local current = day.sessions[index].session
            if previous.interrupted then
                table.insert(day.events, {
                    id = -2, ts = current.startedAt, type = "DAILY_INTERRUPTED",
                    location = current.startLocation,
                })
            end
            local returnLocation = current.startLocation
            if not diaryPlace(returnLocation) then
                for _, event in ipairs(day.sessions[index].events or {}) do
                    if event.type == "LOGIN" and diaryPlace(event.location) then
                        returnLocation = event.location
                        break
                    end
                end
            end
            if diaryPlace(returnLocation) then
                table.insert(day.events, {
                    id = -1, ts = current.startedAt, type = "DAILY_RETURN",
                    location = returnLocation,
                })
            end
        end
        table.sort(day.events, function(a, b)
            if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) < (b.ts or 0) end
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
        end)
        local combined = {
            id = "DAY:" .. tostring(day.dayKey),
            dayKey = day.dayKey,
            dailySummary = true,
            startedAt = firstSession.startedAt,
            endedAt = lastSession.endedAt,
            startLevel = firstSession.startLevel,
            endLevel = lastSession.endLevel,
            startLocation = firstSession.startLocation,
            endLocation = lastSession.endLocation or (lastEntry.events[#lastEntry.events] and lastEntry.events[#lastEntry.events].location),
            interrupted = lastSession.interrupted,
        }
        self.profile.diaryDayVariants = self.profile.diaryDayVariants or {}
        local dayVariantKey = tostring(day.dayKey)
        self.profile.diaryDayVariants[dayVariantKey] = self.profile.diaryDayVariants[dayVariantKey] or {}
        combined.diaryVariants = self.profile.diaryDayVariants[dayVariantKey]
        day.session = combined
        day.entryCount = #day.sessions
        day.narrative, day.summary = self:BuildDiaryNarrative(combined, day.events, #days)
        day.events = day.events
    end
    table.sort(days, function(a, b)
        return (a.session.startedAt or 0) > (b.session.startedAt or 0)
    end)
    return days
end

local function diaryPeriodKey(timestamp, period)
    if not date then return tostring(timestamp or 0) end
    if period == "weeks" then return date("%Y-W%W", timestamp or 0) end
    if period == "months" then return date("%Y-%m", timestamp or 0) end
    return date("%Y", timestamp or 0)
end

-- Builds long-form chapters from the same saved sessions and events. These are
-- virtual groupings: they do not duplicate or rewrite the character's history.
function FC:GetDiaryPeriodEntries(period)
    if period == "sessions" then return self:GetDiaryEntries() end
    if period == "days" then return self:GetDailyDiaryEntries() end
    if period ~= "weeks" and period ~= "months" and period ~= "years" then
        period = "sessions"
    end
    local sessions = self:GetDiaryEntries()
    local periods, byKey = {}, {}
    for index = #sessions, 1, -1 do
        local entry = sessions[index]
        local session = entry.session or {}
        local timestamp = session.startedAt or 0
        local key = diaryPeriodKey(timestamp, period)
        local chapter = byKey[key]
        if not chapter then
            chapter = { periodKey = key, periodKind = period, sessions = {}, events = {}, firstAt = timestamp, lastAt = timestamp }
            byKey[key] = chapter
            table.insert(periods, chapter)
        end
        table.insert(chapter.sessions, entry)
        chapter.firstAt = math.min(chapter.firstAt or timestamp, timestamp)
        chapter.lastAt = math.max(chapter.lastAt or timestamp, session.endedAt or timestamp)
        for _, event in ipairs(entry.events or {}) do table.insert(chapter.events, event) end
        if #chapter.sessions > 1 and diaryPlace(session.startLocation) then
            table.insert(chapter.events, {
                id = -1 - #chapter.sessions,
                ts = session.startedAt,
                type = "DAILY_RETURN",
                location = session.startLocation,
            })
        end
        if #chapter.sessions > 1 and chapter.sessions[#chapter.sessions - 1].session.interrupted then
            table.insert(chapter.events, { id = -100 - #chapter.sessions, ts = session.startedAt, type = "DAILY_INTERRUPTED" })
        end
    end
    for _, chapter in ipairs(periods) do
        table.sort(chapter.sessions, function(a, b) return (a.session.startedAt or 0) < (b.session.startedAt or 0) end)
        table.sort(chapter.events, function(a, b)
            if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) < (b.ts or 0) end
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
        end)
        local firstEntry = chapter.sessions[1]
        local lastEntry = chapter.sessions[#chapter.sessions]
        local firstSession = firstEntry.session
        local lastSession = lastEntry.session
        local combined = {
            id = "PERIOD:" .. chapter.periodKey,
            dayKey = chapter.periodKey,
            periodKind = period,
            periodSessionCount = #chapter.sessions,
            startedAt = firstSession.startedAt,
            endedAt = lastSession.endedAt,
            startLevel = firstSession.startLevel,
            endLevel = lastSession.endLevel,
            startLocation = firstSession.startLocation,
            endLocation = lastSession.endLocation,
            interrupted = lastSession.interrupted,
        }
        self.profile.diaryPeriodVariants = self.profile.diaryPeriodVariants or {}
        local variantKey = period .. ":" .. chapter.periodKey
        self.profile.diaryPeriodVariants[variantKey] = self.profile.diaryPeriodVariants[variantKey] or {}
        combined.diaryVariants = self.profile.diaryPeriodVariants[variantKey]
        chapter.session = combined
        chapter.events = chapter.events
        chapter.entryCount = #chapter.sessions
        chapter.narrative, chapter.summary = self:BuildDiaryNarrative(combined, chapter.events, #periods)
    end
    table.sort(periods, function(a, b) return (a.firstAt or 0) > (b.firstAt or 0) end)
    return periods
end

function FC:GetPreviousSession()
    local sessions = self.profile and self.profile.sessions or {}
    for index = #sessions, 1, -1 do
        local session = sessions[index]
        if session ~= self.activeSession and session.endedAt then
            return session
        end
    end
    return nil
end

function FC:FormatSessionSummary(summary)
    if not summary then
        return ""
    end
    local minutes = math.floor((summary.duration or 0) / 60)
    local duration = minutes >= 60 and string.format("%d:%02d h", math.floor(minutes / 60), minutes % 60) or string.format("%d Min.", minutes)
    local parts = { duration }
    if summary.quests > 0 then table.insert(parts, summary.quests .. " " .. self.L.QUESTS_SHORT) end
    if summary.areas > 0 then table.insert(parts, summary.areas .. " " .. self.L.AREAS_SHORT) end
    if summary.dungeons > 0 then table.insert(parts, summary.dungeons .. " " .. self.L.DUNGEONS_SHORT) end
    if summary.rares > 0 then table.insert(parts, summary.rares .. " " .. self.L.RARES_SHORT) end
    if summary.companions > 0 then table.insert(parts, summary.companions .. " " .. self.L.COMPANIONS_SHORT) end
    return table.concat(parts, "  •  ")
end

-- A readable narrative layer for the character page.  It deliberately uses only
-- facts the addon has observed; it never invents quest instructions or spoilers.
function FC:BuildCharacterStory()
    local profile = self.profile
    if not profile then return "" end
    local identity = profile.identity or {}
    local events = profile.events or {}
    local first, last, counts, zones, levels, quests, dungeons, rares = nil, nil, {}, {}, {}, {}, {}, {}
    for _, event in ipairs(events) do
        if event.type ~= "LOGIN" then
            first = first or event
            last = event
            counts[event.type] = (counts[event.type] or 0) + 1
            if event.type == "ZONE" and event.location then
                zones[event.location.zone or event.location.subZone or ""] = true
            elseif event.type == "SUBZONE_DISCOVERED" then
                local data = event.data or {}
                zones[data.subZone or event.title or ""] = true
            elseif event.type == "LEVEL" then
                levels[event.data and event.data.level or event.title] = true
            elseif event.type == "QUEST_COMPLETED" then
                table.insert(quests, event.title or self.L.QUEST_COMPLETED)
            elseif event.type == "DUNGEON" then
                table.insert(dungeons, event.title or self.L.DUNGEON_ENTERED)
            elseif event.type == "RARE" then
                table.insert(rares, event.title or self.L.RARE_SEEN)
            end
        end
    end
    if not first then return self.L.STORY_EMPTY end
    local name = identity.name
    local currentName = UnitName and UnitName("player")
    if not FC:IsSecret(currentName) and type(currentName) == "string" and currentName ~= ""
        and currentName:lower() ~= "unknown" and currentName:lower() ~= "unbekannt" then
        name = currentName
    end
    if FC:IsSecret(name) or type(name) ~= "string" or name == "" or name:lower() == "unknown" or name:lower() == "unbekannt" then
        name = self.L.UNKNOWN_CHARACTER
    end
    local level = identity.level or self:GetPlayerLevel() or 1
    if FC:IsSecret(level) or type(level) ~= "number" then level = identity.level or 1 end
    local startPlace = first.location and (first.location.zone or first.location.subZone)
    local endPlace = last.location and (last.location.zone or last.location.subZone)
    local journey = startPlace and string.format(self.L.STORY_BEGAN, startPlace) or self.L.STORY_BEGAN_UNKNOWN
    local destination = endPlace and string.format(self.L.STORY_NOW, endPlace) or ""
    local timeSpan = ""
    if first.ts and last.ts and date then
        timeSpan = string.format(self.L.STORY_TIMESPAN, date("%d.%m.%Y", first.ts), date("%d.%m.%Y", last.ts))
    end
    local highlights = {}
    if (counts.QUEST_COMPLETED or 0) > 0 then table.insert(highlights, string.format(self.L.STORY_QUESTS, counts.QUEST_COMPLETED)) end
    if (counts.DUNGEON or 0) > 0 then table.insert(highlights, string.format(self.L.STORY_DUNGEONS, counts.DUNGEON)) end
    if (counts.RARE or 0) > 0 then table.insert(highlights, string.format(self.L.STORY_RARES, counts.RARE)) end
    if (counts.GATHER or 0) > 0 then table.insert(highlights, string.format(self.L.STORY_GATHERINGS, counts.GATHER)) end
    local zoneCount, levelCount = 0, 0
    for _ in pairs(zones) do zoneCount = zoneCount + 1 end
    for _ in pairs(levels) do levelCount = levelCount + 1 end
    if zoneCount > 0 then table.insert(highlights, string.format(self.L.STORY_ZONES, zoneCount)) end
    if levelCount > 0 then table.insert(highlights, string.format(self.L.STORY_LEVELS, levelCount)) end
    local middle = #highlights > 0 and (self.L.STORY_HIGHLIGHTS .. table.concat(highlights, self.L.STORY_JOIN)) or ""
    local recent = {}
    local function appendRecent(source, count, category)
        for index = math.max(1, #source - count + 1), #source do
            if source[index] then table.insert(recent, source[index]) end
        end
        if #source > count then table.insert(recent, string.format(self.L.STORY_MORE, #source - count, category)) end
    end
    appendRecent(quests, 3, self.L.QUESTS_SHORT)
    appendRecent(dungeons, 2, self.L.DUNGEONS_SHORT)
    appendRecent(rares, 2, self.L.RARES_SHORT)
    local recentText = #recent > 0 and (self.L.STORY_RECENT .. table.concat(recent, self.L.STORY_JOIN)) or ""
    if middle ~= "" then middle = middle .. ". " end
    if destination ~= "" then destination = destination .. " " end
    if recentText ~= "" then recentText = recentText .. "." end
    return string.format(self.L.STORY_TEMPLATE, name, level, timeSpan, journey, middle, destination, recentText)
end

FC:RegisterEvent("GROUP_ROSTER_UPDATE", function(self)
    self:TrackCompanions()
end)

FC:RegisterEvent("TRAINER_SHOW", function(self)
    local function scan()
        if self.initialized then self:ScanTrainer() end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, scan) else scan() end
end)

FC:RegisterEvent("PLAYER_LOGIN", function(self)
    self:TrackCompanions()
    local function showRecap()
        if not self.initialized or not self.db.settings.showLoginRecap then return end
        local previous = self:GetPreviousSession()
        if previous then
            local summary = previous.summary or self:BuildSessionSummary(previous)
            self:Print(self.L.LAST_JOURNEY .. ": " .. self:FormatSessionSummary(summary))
        end
    end
    if C_Timer and C_Timer.After then C_Timer.After(3, showRecap) else showRecap() end
end)
