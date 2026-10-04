local _, namespace = ...
local FC = namespace.FC

FC.Known = {
    quests = {},
    npcs = {},
    items = {},
    zones = {},
    dungeons = {},
    rares = {},
}

local function normalizeID(id)
    if id == nil or FC:IsSecret(id) then
        return nil
    end
    if type(id) ~= "string" and type(id) ~= "number" then return nil end
    return tostring(id)
end

local function sameArea(a, b)
    if not a or not b then
        return false
    end
    if a.mapID ~= b.mapID then
        return false
    end
    if a.mapID and a.x and b.x and a.y and b.y then
        -- Keep nearby drops/NPC observations distinct; the old 1.5% radius
        -- merged locations that could be far apart on a zone map.
        return math.abs(a.x - b.x) < 0.2 and math.abs(a.y - b.y) < 0.2
    end
    return a.zone == b.zone and a.subZone == b.subZone
end

function FC:IsKnown(kind, id)
    local known = self.Known[kind]
    if not known then
        return false
    end
    return known[tonumber(id)] == true or known[tostring(id)] == true
end

function FC:AddObservationLocation(record, location, source)
    if not record or not location then
        return
    end
    location = self:SanitizeStoredValue(location)
    source = self:SanitizeStoredValue(source)
    if type(source) ~= "string" then source = nil end
    if type(location) ~= "table" then return end
    local mapID = tonumber(location.mapID)
    if not mapID or mapID <= 0 or mapID ~= mapID or mapID % 1 ~= 0 then return end
    local x, y = location.x, location.y
    if x ~= nil or y ~= nil then
        x, y = tonumber(x), tonumber(y)
        if not x or not y or x ~= x or y ~= y or x < 0 or x > 100 or y < 0 or y > 100 then return end
    end
    location.mapID, location.x, location.y = mapID, x, y
    record.locations = record.locations or {}

    -- Before this fix, target/mouseover observations stored the player's
    -- coordinates. Once the client supplies the NPC's real unit position,
    -- discard those known approximate pins for this record.
    if location.unitPosition then
        local approximateUnitSources = { target = true, mouseover = true, nameplate = true }
        for index = #record.locations, 1, -1 do
            local previous = record.locations[index]
            if approximateUnitSources[previous.source] and previous.unitPosition ~= true then
                table.remove(record.locations, index)
            end
        end
    end

    for _, previous in ipairs(record.locations) do
        if sameArea(previous, location) then
            previous.lastSeen = math.max(previous.lastSeen or 0, location.lastSeen or self:Now())
            previous.firstSeen = math.min(previous.firstSeen or location.firstSeen or self:Now(), location.firstSeen or previous.firstSeen or self:Now())
            previous.continent = location.continent or previous.continent
            previous.x = location.x or previous.x
            previous.y = location.y or previous.y
            previous.unitPosition = location.unitPosition == true or previous.unitPosition or nil
            previous.source = source or location.source or previous.source
            return previous
        end
    end

    local copy = {
        mapID = location.mapID,
        continent = location.continent,
        zone = location.zone,
        subZone = location.subZone,
        x = location.x,
        y = location.y,
        unitPosition = location.unitPosition == true or nil,
        source = source or location.source,
        firstSeen = location.firstSeen or self:Now(),
        lastSeen = location.lastSeen or self:Now(),
    }
    table.insert(record.locations, copy)
    return copy
end

function FC:RecordDiscovery(kind, id, name, location, source)
    kind = self:SanitizeStoredValue(kind)
    id = self:SanitizeStoredValue(id)
    name = self:SanitizeStoredValue(name)
    location = self:SanitizeStoredValue(location)
    source = self:SanitizeStoredValue(source)
    if type(kind) ~= "string" or type(id) ~= "number" and type(id) ~= "string" then return nil end
    local discovery = {
        ts = self:Now(),
        kind = kind,
        id = id,
        name = name,
        location = location,
        source = source,
        databaseVersion = self.db.databaseVersion or 0,
    }
    table.insert(self.profile.discoveries, discovery)
    if self.CheckDataGrowth then self:CheckDataGrowth() end
end

function FC:Observe(kind, id, name, extra)
    kind = self:SanitizeStoredValue(kind)
    id = self:SanitizeStoredValue(id)
    name = self:SanitizeStoredValue(name)
    extra = self:SanitizeStoredValue(extra)
    if not self.initialized or not self.profile or not self.profile.observed[kind] then
        return nil, false
    end

    local key = normalizeID(id)
    if not key or key == "" then
        return nil, false
    end

    local collection = self.profile.observed[kind]
    local record = collection[key]
    local isFirst = record == nil
    local now = self:Now()
    local location
    if extra and extra.noLocation then
        location = nil
    else
        location = extra and extra.location or self:GetLocation()
    end

    if not record then
        record = {
            id = id,
            name = name or (kind .. " #" .. key),
            firstSeen = now,
            lastSeen = now,
            count = 0,
            locations = {},
            unknown = not self:IsKnown(kind, id),
            firstSource = extra and extra.source,
        }
        collection[key] = record
    end

    record.name = name or record.name
    record.lastSeen = now
    record.count = (record.count or 0) + 1
    record.lastSource = extra and extra.source or record.lastSource
    record.link = extra and extra.link or record.link
    record.icon = extra and extra.icon or record.icon
    record.quality = extra and extra.quality or record.quality
    record.vendor = extra and extra.vendor or record.vendor
    record.questState = extra and extra.questState or record.questState
    record.npcRole = extra and extra.npcRole or record.npcRole
    self:AddObservationLocation(record, location, extra and extra.source)

    if isFirst then
        self:RecordDiscovery(kind, id, record.name, location, extra and extra.source)
        if kind == "items" then
            self.profile.stats.itemsObserved = self.profile.stats.itemsObserved + 1
        end
    end

    self:TouchData("observe:" .. tostring(kind))

    return record, isFirst
end

function FC:GetObservation(kind, id, characterKey)
    local profile = self.db.characters[characterKey or self.characterKey]
    if not profile or not profile.observed or not profile.observed[kind] then
        return nil
    end
    return profile.observed[kind][normalizeID(id)]
end
