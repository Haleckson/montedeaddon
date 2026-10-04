local _, namespace = ...
local FC = namespace.FC

local KIND_LABELS = {
    quests = FC.L.QUEST_LABEL,
    npcs = FC.L.NPC,
    enemies = FC.L.MAP_ENEMIES,
    items = FC.L.ITEM_LABEL,
    zones = FC.L.AREA_LABEL,
    dungeons = FC.L.DUNGEON_LABEL,
    entrances = FC.L.MAP_ENTRANCES,
    rares = FC.L.RARE,
    note = FC.L.NOTE_LABEL,
    event = FC.L.EVENT_LABEL,
    merchant = FC.L.MERCHANT,
    trainer = FC.L.TRAINER,
    profession = FC.L.PROFESSION,
    companion = FC.L.COMPANION_LABEL,
    atlas = FC.L and FC.L.ATLAS or "Resource atlas",
}

local function lower(value)
    return FC:LowerText(value)
end

local function contains(value, query)
    if query == "" then
        return true
    end
    return string.find(lower(value), query, 1, true) ~= nil
end

local function parseSearch(searchText)
    local terms = {}
    local filters = {}
    local tokens, buffer, quoted = {}, {}, false
    for index = 1, #tostring(searchText or "") do
        local character = tostring(searchText or ""):sub(index, index)
        if character == '"' then
            quoted = not quoted
        elseif character:match("%s") and not quoted then
            if #buffer > 0 then table.insert(tokens, table.concat(buffer)); buffer = {} end
        else
            table.insert(buffer, character)
        end
    end
    if #buffer > 0 then table.insert(tokens, table.concat(buffer)) end
    for _, token in ipairs(tokens) do
        local key, value = token:match("^([%a_]+):(.+)$")
        if key and value then
            key = lower(key)
            value = lower(value)
            if key == "type" or key == "kind" then
                filters.kind = value
            elseif key == "char" or key == "character" then
                filters.character = value
            elseif key == "zone" or key == "gebiet" then
                filters.zone = value
            elseif key == "continent" or key == "kontinent" then
                filters.continent = value
            elseif key == "id" then
                filters.id = value
            else
                table.insert(terms, token)
            end
        else
            table.insert(terms, token)
        end
    end
    return table.concat(terms, " "), filters
end

local function kindMatches(kind, wanted)
    if not wanted or wanted == "" then return true end
    local aliases = {
        quest = "quests", quests = "quests", item = "items", items = "items",
        npc = "npcs", npcs = "npcs", rare = "rares", rares = "rares",
        zone = "zones", zones = "zones", dungeon = "dungeons", dungeons = "dungeons",
        note = "note", notes = "note", resource = "atlas", atlas = "atlas",
        merchant = "merchant", trainer = "trainer", companion = "companion",
    }
    local expected = aliases[wanted] or wanted
    return kind == expected or (expected == "items" and kind == "items_account")
end

local function passesSearchFilters(kind, id, record, characterKey, location, filters)
    if not kindMatches(kind, filters.kind) then return false end
    if filters.id and not contains(id, filters.id) then return false end
    if filters.character and not contains(characterKey, filters.character) then return false end
    if filters.zone then
        local found = contains(location and ((location.zone or "") .. " " .. (location.subZone or "")) or "", filters.zone)
        for _, previous in ipairs(record and record.locations or {}) do
            if contains((previous.zone or "") .. " " .. (previous.subZone or ""), filters.zone) then
                found = true
                break
            end
        end
        if not found then return false end
    end
    if filters.continent then
        local found = contains(location and location.continent or record and record.continent or "", filters.continent)
        for _, previous in ipairs(record and record.locations or {}) do
            if contains(previous.continent or "", filters.continent) then
                found = true
                break
            end
        end
        if not found then return false end
    end
    return true
end

local function allLocationText(record)
    local values = {}
    for _, location in ipairs(record and record.locations or {}) do
        table.insert(values, location.continent or "")
        table.insert(values, location.zone or "")
        table.insert(values, location.subZone or "")
    end
    return table.concat(values, " ")
end

local function latestLocation(record)
    if not record or not record.locations or #record.locations == 0 then
        return nil
    end
    return record.locations[#record.locations]
end

local function itemMapLocations(record)
    local locations = {}
    for index, location in ipairs(record and record.locations or {}) do
        if location.mapID and location.x ~= nil and location.y ~= nil
            and (location.source == "loot" or location.source == "vendor"
                or (index == 1 and not location.source
                    and (record.firstSource == "loot" or record.firstSource == "vendor")
                    and record.firstSeen and location.firstSeen == record.firstSeen)
                or (FC.demoMode and record.firstSource == "demo")) then
            table.insert(locations, location)
        end
    end
    return locations
end

function FC:GetItemMapLocations(record)
    return itemMapLocations(record)
end

local function inventoryCount(profile, itemID)
    if not profile or not profile.inventory then
        return 0, 0
    end
    local key = tostring(itemID)
    return (profile.inventory.bags and profile.inventory.bags[key] or 0),
        (profile.inventory.bank and profile.inventory.bank[key] or 0)
end

function FC:GetAccountSummary()
    local summary = {
        characters = 0,
        events = 0,
        discoveries = 0,
        notes = 0,
        locations = 0,
        items = 0,
        companions = 0,
        atlasNodes = 0,
    }
    local locationKeys = {}
    local itemKeys = {}
    local companionKeys = {}
    for _, profile in pairs(self.db.characters or {}) do
        summary.characters = summary.characters + 1
        summary.events = summary.events + #(profile.events or {})
        summary.discoveries = summary.discoveries + #(profile.discoveries or {})
        summary.notes = summary.notes + #(profile.notes or {})
        for itemID in pairs(profile.observed and profile.observed.items or {}) do
            itemKeys[tostring(itemID)] = true
        end
        for companionKey in pairs(profile.companions or {}) do
            companionKeys[companionKey] = true
        end
        for _, records in pairs(profile.observed or {}) do
            for _, record in pairs(records) do
                for _, location in ipairs(record.locations or {}) do
                    local key = table.concat({
                        tostring(location.mapID or location.zone or ""),
                        tostring(location.x and math.floor(location.x + 0.5) or ""),
                        tostring(location.y and math.floor(location.y + 0.5) or ""),
                    }, ":")
                    locationKeys[key] = true
                end
            end
        end
    end
    for _, node in pairs(self.db.atlas and self.db.atlas.nodes or {}) do
        summary.atlasNodes = summary.atlasNodes + 1
        if node.mapID and node.x and node.y then
            local key = table.concat({ tostring(node.mapID), tostring(math.floor(node.x + 0.5)), tostring(math.floor(node.y + 0.5)) }, ":")
            locationKeys[key] = true
        end
    end
    for _ in pairs(locationKeys) do
        summary.locations = summary.locations + 1
    end
    for _ in pairs(itemKeys) do
        summary.items = summary.items + 1
    end
    for _ in pairs(companionKeys) do
        summary.companions = summary.companions + 1
    end
    return summary
end

function FC:GetCharacters()
    local characters = {}
    for characterKey, profile in pairs(self.db.characters or {}) do
        table.insert(characters, {
            key = characterKey,
            identity = profile.identity or {},
            events = #(profile.events or {}),
            discoveries = #(profile.discoveries or {}),
            notes = #(profile.notes or {}),
            lastSeen = profile.identity and profile.identity.lastSeen or 0,
            location = profile.lastState and profile.lastState.location,
            profile = profile,
        })
    end
    table.sort(characters, function(a, b)
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)
    return characters
end

function FC:GetRecentLocations(limit)
    local results = {}
    local function add(characterKey, kind, title, location, timestamp, detail)
        if not location or not location.mapID or not location.x or not location.y then
            return
        end
        table.insert(results, {
            characterKey = characterKey,
            kind = kind,
            title = title,
            location = location,
            ts = timestamp or 0,
            detail = detail,
        })
    end

    for characterKey, profile in pairs(self.db.characters or {}) do
        for _, note in ipairs(profile.notes or {}) do
            if note.archived ~= true and note.mapVisible ~= false then
                add(characterKey, "note", note.text, note.location, note.ts, self.L.OWN_MEMORY)
            end
        end
        for _, kind in ipairs({ "rares", "npcs", "items", "zones", "dungeons" }) do
            for _, record in pairs(profile.observed and profile.observed[kind] or {}) do
                local location = latestLocation(record)
                if kind == "items" then
                    local observed = itemMapLocations(record)
                    location = observed[#observed]
                end
                add(characterKey, kind, record.name, location, record.lastSeen, record.vendor)
            end
        end
        for _, record in pairs(profile.merchants or {}) do
            add(characterKey, "merchant", record.name, record.location, record.lastSeen, self.L.MERCHANT)
        end
        for _, record in pairs(profile.trainers or {}) do
            add(characterKey, "trainer", record.name, record.location, record.lastSeen, self.L.TRAINER)
        end
    end
    for _, node in pairs(self.db.atlas and self.db.atlas.nodes or {}) do
        add("account", "atlas", node.name, {
            mapID = node.mapID, zone = node.zone, subZone = node.subZone,
            x = node.x, y = node.y,
        }, node.lastSeen, node.kind)
    end

    table.sort(results, function(a, b)
        return (a.ts or 0) > (b.ts or 0)
    end)
    if limit then
        while #results > limit do table.remove(results) end
    end
    return results
end

function FC:GetItemMemory(itemID)
    local result = { totalBags = 0, totalBank = 0, characters = {}, latest = nil, vendors = {} }
    local key = tostring(itemID or "")
    if key == "" then
        return result
    end
    for characterKey, profile in pairs(self.db.characters or {}) do
        local bags, bank = inventoryCount(profile, key)
        if bags > 0 or bank > 0 then
            table.insert(result.characters, { key = characterKey, bags = bags, bank = bank })
            result.totalBags = result.totalBags + bags
            result.totalBank = result.totalBank + bank
        end
        local record = profile.observed and profile.observed.items and profile.observed.items[key]
        if record then
            local knownLocations = itemMapLocations(record)
            local location = knownLocations[#knownLocations]
            if location and (not result.latest or (record.lastSeen or 0) > (result.latest.ts or 0)) then
                result.latest = {
                    ts = record.lastSeen,
                    location = location,
                    characterKey = characterKey,
                    icon = record.icon,
                }
            end
            if record.vendor and record.vendor ~= "" then
                result.vendors[record.vendor] = true
            end
            for _, vendor in pairs(record.vendors or {}) do
                if vendor.name and vendor.name ~= "" then
                    result.vendors[vendor.name] = true
                end
            end
        end
        for _, merchant in pairs(profile.merchants or {}) do
            if merchant.items and merchant.items[key] then
                result.vendors[merchant.name or merchant.key] = true
            end
        end
    end

    table.sort(result.characters, function(a, b)
        return a.key < b.key
    end)
    return result
end

function FC:GetNPCMemory(npcID)
    local key = tostring(npcID or "")
    local latest
    for characterKey, profile in pairs(self.db.characters or {}) do
        for _, kind in ipairs({ "npcs", "rares" }) do
            local record = profile.observed and profile.observed[kind] and profile.observed[kind][key]
            if record and (not latest or (record.lastSeen or 0) > (latest.ts or 0)) then
                latest = {
                    record = record,
                    location = latestLocation(record),
                    characterKey = characterKey,
                    ts = record.lastSeen,
                    kind = kind,
                }
            end
        end
    end
    return latest
end

function FC:AddNote(text, remind)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or not self.profile then
        return
    end
    self.db.meta = self.db.meta or {}
    local now = self:Now()
    local noteID = tonumber(self.db.meta.nextNoteID) or 1
    self.db.meta.nextNoteID = noteID + 1
    local note = {
        id = noteID,
        ts = now,
        updatedAt = now,
        text = text,
        location = self:GetLocation(),
        remind = remind ~= false,
    }
    table.insert(self.profile.notes, note)
    self:TouchData("note")
    self:LogEvent("NOTE", self.L.NOTE_SAVED, text, { noteID = note.id })
    self:Print(self.L.NOTE_SAVED .. ": " .. text)
end

function FC:SetNoteReminder(noteID, enabled)
    noteID = tonumber(noteID)
    if not noteID or not self.db then return false end
    for _, profile in pairs(self.db.characters or {}) do
        for _, note in ipairs(profile.notes or {}) do
            if tonumber(note.id) == noteID then
                note.remind = enabled and true or false
                note.updatedAt = self:Now()
                self:TouchData("note-reminder:" .. tostring(noteID))
                if self.RefreshUI then self:RefreshUI() end
                return true
            end
        end
    end
    return false
end

function FC:SetNoteMapVisible(noteID, enabled)
    noteID = tonumber(noteID)
    if not noteID or not self.db then return false end
    for _, profile in pairs(self.db.characters or {}) do
        for _, note in ipairs(profile.notes or {}) do
            if tonumber(note.id) == noteID then
                note.mapVisible = enabled and true or false
                note.updatedAt = self:Now()
                self:TouchData("note-pin:" .. tostring(noteID))
                if self.RefreshUI then self:RefreshUI() end
                if self.RefreshMapPins then self:RefreshMapPins() end
                return true
            end
        end
    end
    return false
end

function FC:ArchiveNote(noteID)
    noteID = tonumber(noteID)
    if not noteID or not self.db then return false end
    for _, profile in pairs(self.db.characters or {}) do
        for _, note in ipairs(profile.notes or {}) do
            if tonumber(note.id) == noteID then
                note.archived = true
                note.archivedAt = self:Now()
                note.updatedAt = note.archivedAt
                self:TouchData("note-archive:" .. tostring(noteID))
                if self.RefreshUI then self:RefreshUI() end
                if self.RefreshMapPins then self:RefreshMapPins() end
                return true
            end
        end
    end
    return false
end

function FC:SearchMemory(searchText)
    local query, filters = parseSearch(searchText)
    query = lower(query):gsub("^%s+", ""):gsub("%s+$", "")
    local results = {}

    for characterKey, profile in pairs(self.db.characters or {}) do
        for kind, records in pairs(profile.observed or {}) do
            for id, record in pairs(records) do
                local location = latestLocation(record)
                local savedLocations = kind == "items" and itemMapLocations(record) or (record.locations or {})
                if kind == "items" then location = savedLocations[#savedLocations] end
                local filterRecord = kind == "items" and { locations = savedLocations, continent = record.continent } or record
                local includeRecord = (kind ~= "npcs" or record.npcRole == "npc")
                    and passesSearchFilters(kind, id, filterRecord, characterKey, location, filters)
                local haystack = table.concat({
                    record.name or "",
                    id or "",
                    characterKey or "",
                    record.vendor or "",
                    record.lastSource or "",
                    location and location.zone or "",
                    location and location.subZone or "",
                    allLocationText(filterRecord),
                }, " ")

                if includeRecord and contains(haystack, query) and not (kind == "quests" and record.questState == "completed"
                    and self.db.questArchive and self.db.questArchive.quests[tostring(id)]) then
                    local bags, bank = kind == "items" and inventoryCount(profile, id) or 0, 0
                    if kind == "items" then
                        bags, bank = inventoryCount(profile, id)
                    end
                    local details = {}
                    if location then
                        table.insert(details, self:FormatLocation(location))
                    end
                    if #savedLocations > 1 then
                        table.insert(details, string.format(self.L.LOCATIONS_COUNT, #savedLocations))
                    end
                    if bags > 0 or bank > 0 then
                        table.insert(details, string.format("%s: %d %s, %d %s", characterKey, bags, self.L.BAGS, bank, self.L.BANK))
                    else
                        table.insert(details, characterKey)
                    end
                    if record.vendor then
                        table.insert(details, string.format(self.L.VENDOR_PREFIX, record.vendor))
                    end
                    local vendorNames = {}
                    for _, vendor in pairs(record.vendors or {}) do
                        if vendor.name then table.insert(vendorNames, vendor.name) end
                    end
                    if #vendorNames > 0 then
                        table.sort(vendorNames)
                        table.insert(details, self.L.MERCHANT .. ": " .. table.concat(vendorNames, ", "))
                    end

                    table.insert(results, {
                        kind = kind,
                        id = id,
                        title = string.format("[%s] %s", KIND_LABELS[kind] or kind, record.name or id),
                        subtitle = table.concat(details, "  •  "),
                        ts = record.lastSeen or 0,
                        location = location,
                        score = (contains(record.name, query) and 30 or 10) + (record.unknown and 2 or 0),
                        characterKey = characterKey,
                        record = record,
                        firstSeen = record.firstSeen or 0,
                        locations = savedLocations,
                        source = record.firstSource or record.lastSource,
                        locationCount = #savedLocations,
                    })
                end
            end
        end

        for merchantKey, merchant in pairs(profile.merchants or {}) do
            local matchingItems = {}
            local itemText = {}
            for itemID, item in pairs(merchant.items or {}) do
                local value = (item.name or "") .. " " .. tostring(itemID)
                table.insert(itemText, value)
                if query ~= "" and contains(value, query) then
                    table.insert(matchingItems, item.name or string.format(self.L.ITEM_ID, tostring(itemID)))
                end
            end
            for itemName, offer in pairs(merchant.itemsByName or {}) do
                local value = itemName .. " " .. tostring(offer.id or "")
                table.insert(itemText, value)
                if query ~= "" and contains(value, query) then
                    table.insert(matchingItems, itemName)
                end
            end
            local merchantCategories = {}
            for category in pairs(merchant.categories or {}) do table.insert(merchantCategories, category) end
            table.sort(merchantCategories)
            local locationText = self:FormatLocation(merchant.location)
            local merchantLocationCount = #(merchant.locations or {})
            local includeMerchant = passesSearchFilters("merchant", merchantKey, merchant, characterKey, merchant.location, filters)
            local categoryText = table.concat(merchantCategories, " ")
            local haystack = table.concat({ merchant.name or "", merchantKey, locationText, categoryText, table.concat(itemText, " ") }, " ")
            if includeMerchant and contains(haystack, query) then
                table.sort(matchingItems)
                local offer = #matchingItems > 0 and table.concat(matchingItems, ", ") or string.format(self.L.ITEMS_REMEMBERED, (function()
                    local count = 0
                    for _ in pairs(merchant.items or {}) do count = count + 1 end
                    for _ in pairs(merchant.itemsByName or {}) do count = count + 1 end
                    return count
                end)())
                local subtitleParts = { offer }
                if #merchantCategories > 0 then table.insert(subtitleParts, table.concat(merchantCategories, ", ")) end
                table.insert(subtitleParts, locationText)
                table.insert(subtitleParts, characterKey)
                if merchantLocationCount > 1 then
                    table.insert(subtitleParts, string.format(self.L.LOCATIONS_COUNT .. ": %d", merchantLocationCount))
                end
                table.insert(results, {
                    kind = "merchant", id = merchantKey,
                    title = "[" .. KIND_LABELS.merchant .. "] " .. (merchant.name or merchantKey),
                    subtitle = table.concat(subtitleParts, "  •  "),
                    ts = merchant.lastSeen or 0, location = merchant.location,
                    score = contains(merchant.name, query) and 45 or 38,
                    characterKey = characterKey, record = merchant,
                    firstSeen = merchant.firstSeen or 0,
                    source = "merchant",
                    locations = merchant.locations or (merchant.location and { merchant.location } or {}),
                })
            end
        end

        for trainerKey, trainer in pairs(profile.trainers or {}) do
            local matchingServices = {}
            local serviceText = {}
            for _, service in pairs(trainer.services or {}) do
                local value = (service.name or "") .. " " .. (service.rank or "")
                table.insert(serviceText, value)
                if query ~= "" and contains(value, query) then
                    table.insert(matchingServices, (service.name or "") .. (service.rank and (" " .. service.rank) or ""))
                end
            end
            local locationText = self:FormatLocation(trainer.location)
            local trainerLocationCount = #(trainer.locations or {})
            local includeTrainer = passesSearchFilters("trainer", trainerKey, trainer, characterKey, trainer.location, filters)
            local haystack = table.concat({ trainer.name or "", trainerKey, locationText, table.concat(serviceText, " ") }, " ")
            if includeTrainer and contains(haystack, query) then
                table.sort(matchingServices)
                local offer = #matchingServices > 0 and table.concat(matchingServices, ", ") or string.format(self.L.OFFERS_REMEMBERED, (function()
                    local count = 0
                    for _ in pairs(trainer.services or {}) do count = count + 1 end
                    return count
                end)())
                local subtitleParts = { offer, locationText, characterKey }
                if trainerLocationCount > 1 then
                    table.insert(subtitleParts, string.format(self.L.LOCATIONS_COUNT .. ": %d", trainerLocationCount))
                end
                table.insert(results, {
                    kind = "trainer", id = trainerKey,
                    title = "[" .. KIND_LABELS.trainer .. "] " .. (trainer.name or trainerKey),
                    subtitle = table.concat(subtitleParts, "  •  "),
                    ts = trainer.lastSeen or 0, location = trainer.location,
                    score = contains(trainer.name, query) and 46 or 40,
                    characterKey = characterKey, record = trainer,
                    firstSeen = trainer.firstSeen or 0,
                    source = "trainer",
                })
            end
        end

        for professionKey, profession in pairs(profile.professions or {}) do
            local skillText = string.format("%d/%d", profession.skillLevel or 0, profession.maxSkillLevel or 0)
            local haystack = table.concat({ profession.name or "", professionKey, skillText, characterKey }, " ")
            if contains(haystack, query) and passesSearchFilters("profession", professionKey, profession, characterKey, nil, filters) then
                table.insert(results, {
                    kind = "profession", id = professionKey,
                    title = "[" .. KIND_LABELS.profession .. "] " .. (profession.name or professionKey),
                    subtitle = table.concat({ skillText, characterKey }, "  •  "),
                    ts = profession.lastSeen or 0, location = nil,
                    score = contains(profession.name, query) and 47 or 35,
                    characterKey = characterKey, record = profession,
                    firstSeen = profession.firstSeen or 0, source = "profession",
                })
            end
        end

        for companionKey, companion in pairs(profile.companions or {}) do
            local dungeonNames = {}
            for dungeonName in pairs(companion.dungeons or {}) do table.insert(dungeonNames, dungeonName) end
            local location = latestLocation(companion)
            local includeCompanion = passesSearchFilters("companion", companionKey, companion, characterKey, location, filters)
            local haystack = table.concat({ companion.name or "", companionKey, table.concat(dungeonNames, " "), self:FormatLocation(location) }, " ")
            if includeCompanion and contains(haystack, query) then
                table.sort(dungeonNames)
                table.insert(results, {
                    kind = "companion", id = companionKey,
                    title = "[" .. KIND_LABELS.companion .. "] " .. (companion.name or companionKey),
                    subtitle = table.concat({ table.concat(dungeonNames, ", "), self:FormatLocation(location), characterKey }, "  •  "),
                    ts = companion.lastSeen or 0, location = location,
                    score = contains(companion.name, query) and 44 or 18,
                    characterKey = characterKey, record = companion,
                    firstSeen = companion.firstSeen or 0,
                    locations = companion.locations,
                    source = "group",
                })
            end
        end

        for _, note in ipairs(profile.notes or {}) do
            if note.archived ~= true then
            local locationText = self:FormatLocation(note.location)
            local includeNote = passesSearchFilters("note", note.id, note, characterKey, note.location, filters)
            if includeNote and contains(note.text .. " " .. locationText, query) then
                local reminderState = note.remind == false and self.L.REMINDER_OFF or self.L.REMINDER_ON
                local pinState = note.mapVisible == false and self.L.NOTE_PIN_OFF or self.L.NOTE_PIN_ON
                table.insert(results, {
                    kind = "note",
                    id = note.id,
                    title = "[" .. KIND_LABELS.note .. "] " .. note.text,
                    subtitle = "#" .. tostring(note.id or "?") .. "  •  " .. characterKey
                        .. (locationText ~= "" and ("  •  " .. locationText) or "") .. "  •  " .. reminderState .. "  •  " .. pinState,
                    ts = note.ts or 0,
                    location = note.location,
                    score = contains(note.text, query) and 50 or 15,
                    characterKey = characterKey,
                    record = note,
                    firstSeen = note.ts or 0,
                    source = "note",
                })
            end
        end
        end

        if query ~= "" then
            for _, event in ipairs(profile.events or {}) do
                local eventText = table.concat({ event.title or "", event.detail or "", self:FormatLocation(event.location) }, " ")
                if contains(eventText, query) then
                    table.insert(results, {
                        kind = "event",
                        id = event.id,
                        title = "[" .. KIND_LABELS.event .. "] " .. (event.title or event.type),
                        subtitle = characterKey .. "  •  " .. self:FormatLocation(event.location),
                        ts = event.ts or 0,
                        location = event.location,
                        score = contains(event.title, query) and 20 or 5,
                        characterKey = characterKey,
                        record = event,
                    })
                end
            end
        end
    end

    if (query ~= "" or filters.kind == "items" or filters.kind == "items_account")
        and kindMatches("items_account", filters.kind) then
        local itemIDs = {}
        for _, profile in pairs(self.db.characters or {}) do
            for itemID, record in pairs(profile.observed and profile.observed.items or {}) do
                local haystack = table.concat({ record.name or "", tostring(itemID), record.vendor or "" }, " ")
                if contains(haystack, query) then itemIDs[tostring(itemID)] = true end
            end
        end
        for itemID in pairs(itemIDs) do
            local memory = self:GetItemMemory(itemID)
            local names, locations = {}, {}
            local itemName = itemID
            for characterKey, profile in pairs(self.db.characters or {}) do
                local record = profile.observed and profile.observed.items and profile.observed.items[itemID]
                if record then
                    itemName = record.name or itemName
                    local bags, bank = inventoryCount(profile, itemID)
                    table.insert(names, string.format("%s: %d %s / %d %s", characterKey, bags, self.L.BAGS, bank, self.L.BANK))
                    for _, location in ipairs(itemMapLocations(record)) do
                        local zoneText = (location.zone or "") .. " " .. (location.subZone or "")
                        local matchesZone = not filters.zone or contains(zoneText, filters.zone)
                        local matchesContinent = not filters.continent or contains(location.continent or "", filters.continent)
                        if matchesZone and matchesContinent then table.insert(locations, location) end
                    end
                end
            end
            table.sort(names)
            local hasLocationFilter = filters.zone or filters.continent
            if not hasLocationFilter or #locations > 0 then
            local latest = memory.latest and memory.latest.location
            if #locations > 0 then latest = locations[#locations] end
            local subtitle = table.concat({
                string.format("%s: %d  •  %s: %d", self.L.TOTAL,
                    (memory.totalBags or 0) + (memory.totalBank or 0),
                    self.L.LOCATIONS_COUNT, #locations),
                table.concat(names, ", "),
            }, "  •  ")
            table.insert(results, {
                kind = "items_account", id = itemID,
                title = "[" .. self.L.ACCOUNT_ITEM .. "] " .. itemName,
                subtitle = subtitle,
                ts = memory.latest and memory.latest.ts or 0,
                location = latest,
                score = contains(itemName, query) and 52 or 43,
                characterKey = "account",
                record = { id = itemID, name = itemName, memory = memory, locations = locations, icon = memory.latest and memory.latest.icon },
                accountWide = true,
            })
            end
        end
    end

    for id, node in pairs(self.db.atlas and self.db.atlas.nodes or {}) do
        local location = {
            mapID = node.mapID, zone = node.zone, subZone = node.subZone,
            x = node.x, y = node.y,
        }
        local haystack = table.concat({ node.name or "", id or "", node.kind or "",
            node.continent or "", node.zone or "", node.subZone or "" }, " ")
        if passesSearchFilters("atlas", id, node, "account", location, filters) and contains(haystack, query) then
            local detail = self:FormatLocation(location)
            if node.count and node.count > 1 then detail = detail .. "  •  " .. string.format(self.L.FINDS, node.count) end
            table.insert(results, {
                kind = "atlas", id = id,
                title = "[" .. (KIND_LABELS.atlas or "Resource") .. "] " .. (node.name or id),
                subtitle = detail,
                ts = node.lastSeen or 0,
                location = location,
                score = contains(node.name, query) and 42 or 24,
                characterKey = "account",
                record = node,
                firstSeen = node.firstSeen or 0,
                source = node.source,
            })
        end
    end

    for id, quest in pairs(self.db.questArchive and self.db.questArchive.quests or {}) do
        local latest = quest.locations and quest.locations[#quest.locations]
        local names = {}
        for _, name in pairs(quest.names or {}) do table.insert(names, name) end
        local clientLocale = GetLocale and GetLocale() or "enUS"
        local displayQuestName
        if clientLocale == "deDE" then
            displayQuestName = quest.names and quest.names.deDE or (quest.locale == "deDE" and quest.currentName) or quest.englishName or quest.names and (quest.names.enUS or quest.names.enGB)
        else
            displayQuestName = quest.names and (quest.names.enUS or quest.names.enGB) or (quest.locale == clientLocale and quest.currentName) or quest.currentName
        end
        displayQuestName = displayQuestName or string.format(self.L.QUEST_ID, tostring(id))
        local objectiveText = {}
        for _, objective in pairs(quest.objectives or {}) do
            if objective.text then table.insert(objectiveText, objective.text) end
        end
        local location = latest and {
            mapID = latest.mapID, zone = latest.zone, subZone = latest.subZone,
            x = latest.x, y = latest.y,
        } or nil
        local haystack = table.concat({ displayQuestName, quest.currentName or "", quest.englishName or "",
            table.concat(names, " "), tostring(id), latest and latest.continent or "",
            latest and latest.zone or "", latest and latest.subZone or "", table.concat(objectiveText, " ") }, " ")
        if (quest.count or 0) > 0 and passesSearchFilters("quests", id, quest, "account", location, filters) and contains(haystack, query) then
            local completedBy = {}
            for characterKey, character in pairs(quest.completedBy or {}) do
                table.insert(completedBy, character.name or characterKey)
            end
            table.sort(completedBy)
            local subtitle = table.concat({
                (latest and self:FormatLocation(location) or ""),
                quest.englishName and (self.L.QUEST_ENGLISH .. ": " .. quest.englishName) or self.L.QUEST_TRANSLATION_PENDING,
                self.L.QUEST_COMPLETED_BY .. ": " .. table.concat(completedBy, ", "),
            }, "  •  ")
            table.insert(results, {
                kind = "quests", id = id,
                title = "[" .. self.L.QUEST_ARCHIVE .. "] " .. displayQuestName,
                subtitle = subtitle,
                ts = quest.lastCompleted or 0,
                location = location,
                score = (contains(displayQuestName, query) or contains(quest.currentName, query) or contains(quest.englishName, query)) and 48 or 36,
                characterKey = "account",
                record = quest,
                accountWide = true,
                firstSeen = quest.firstCompleted or 0,
                locations = quest.locations,
                source = "quest_archive",
            })
        end
    end

    table.sort(results, function(a, b)
        if a.score == b.score then
            return (a.ts or 0) > (b.ts or 0)
        end
        return a.score > b.score
    end)

    return results
end

function FC:SetWaypoint(location, quiet)
    if self:IsSecret(location) or type(location) ~= "table"
        or self:IsSecret(location.mapID) or type(location.mapID) ~= "number" or location.mapID <= 0
        or self:IsSecret(location.x) or self:IsSecret(location.y)
        or type(location.x) ~= "number" or type(location.y) ~= "number"
        or location.x ~= location.x or location.y ~= location.y
        or location.x < 0 or location.x > 100 or location.y < 0 or location.y > 100 then
        if not quiet then self:Print(self.L.WAYPOINT_FAILED) end
        return false
    end
    if not C_Map or not C_Map.SetUserWaypoint or not UiMapPoint or not UiMapPoint.CreateFromCoordinates then
        if not quiet then self:Print(self.L.WAYPOINT_FAILED) end
        return false
    end

    local ok, point = pcall(UiMapPoint.CreateFromCoordinates, location.mapID, location.x / 100, location.y / 100)
    if not ok or self:IsSecret(point) or not point then
        if not quiet then self:Print(self.L.WAYPOINT_FAILED) end
        return false
    end
    local setOK = pcall(C_Map.SetUserWaypoint, point)
    if not setOK then
        if not quiet then self:Print(self.L.WAYPOINT_FAILED) end
        return false
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    if not quiet then self:Print(self.L.WAYPOINT_SET) end
    return true
end

function FC:OpenMemory(query)
    self:OpenUI("memory")
    if self.SetUISearch then
        self:SetUISearch(query or "")
    end
end

FC:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(self, _, itemID, success)
    if self:IsSecret(itemID) or self:IsSecret(success) or not success then
        return
    end
    if type(itemID) ~= "number" then return end
    local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(getItemInfo) ~= "function" then
        return
    end
    local name, link, quality, _, _, itemType, itemSubType = getItemInfo(itemID)
    if self:IsSecret(name) then name = nil end
    if self:IsSecret(link) then link = nil end
    if self:IsSecret(quality) then quality = nil end
    if self:IsSecret(itemType) then itemType = nil end
    if self:IsSecret(itemSubType) then itemSubType = nil end
    if type(name) ~= "string" or name == "" then
        return
    end
    if type(link) ~= "string" then link = nil end
    if type(quality) ~= "number" then quality = nil end
    if type(itemType) ~= "string" then itemType = nil end
    if type(itemSubType) ~= "string" then itemSubType = nil end
    for _, profile in pairs(self.db.characters or {}) do
        local record = profile.observed and profile.observed.items and profile.observed.items[tostring(itemID)]
        if record then
            record.name = name
            record.link = link or record.link
            record.quality = quality or record.quality
        end
        for _, discovery in ipairs(profile.discoveries or {}) do
            if discovery.kind == "items" and tostring(discovery.id) == tostring(itemID) then
                discovery.name = name
            end
        end
        for _, merchant in pairs(profile.merchants or {}) do
            local item = merchant.items and merchant.items[tostring(itemID)]
            if item then
                item.name = name
                item.link = link or item.link
                item.quality = quality or item.quality
                item.itemType = itemType or item.itemType
                item.itemSubType = itemSubType or item.itemSubType
                if item.itemSubType and item.itemSubType ~= "" then
                    merchant.categories = merchant.categories or {}
                    merchant.categories[item.itemSubType] = true
                end
            end
            -- Upgrade name-only stock snapshots once the client exposes IDs.
            for oldName, offer in pairs(merchant.itemsByName or {}) do
                if oldName == name then
                    merchant.itemsByName[oldName] = nil
                    merchant.items = merchant.items or {}
                    local existing = merchant.items[tostring(itemID)] or { id = itemID, firstSeen = offer.firstSeen }
                    existing.name = name
                    existing.link = link or existing.link
                    existing.quality = quality or existing.quality
                    existing.itemType = itemType or existing.itemType
                    existing.itemSubType = itemSubType or existing.itemSubType
                    existing.lastSeen = math.max(existing.lastSeen or 0, offer.lastSeen or 0)
                    merchant.items[tostring(itemID)] = existing
                    if existing.itemSubType and existing.itemSubType ~= "" then
                        merchant.categories = merchant.categories or {}
                        merchant.categories[existing.itemSubType] = true
                    end
                end
            end
            if self.SetMerchantVisitCategories and merchant.lastDiaryEventID then
                self:SetMerchantVisitCategories(merchant, merchant.categories)
            end
        end
    end
    if self.TouchData then self:TouchData("item-info-loaded:" .. tostring(itemID)) end
    if self.RefreshUI then self:RefreshUI() end
end)
