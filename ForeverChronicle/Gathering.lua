local _, namespace = ...
local FC = namespace.FC
local unpack = unpack or table.unpack

local pendingGather
local lastGatherNode

local function lower(value)
    return FC:LowerText(value)
end

local function spellName(spellID)
    if FC:IsSecret(spellID) then return "" end
    if not spellID then
        return ""
    end
    if type(spellID) == "string" then
        -- Older Classic-compatible clients can supply the localized spell
        -- name in event payloads instead of a numeric spellID.
        return spellID
    end
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and not FC:IsSecret(name) and type(name) == "string" then return name end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and not FC:IsSecret(name) and type(name) == "string" then return name end
    end
    return ""
end

local function classifySpell(spellID)
    if FC:IsSecret(spellID) then return nil end
    local name = lower(spellName(spellID))
    local known = {
        [2575] = "ore", [2366] = "herb", [7620] = "fishing",
        [3365] = "treasure", [22810] = "treasure", [1804] = "treasure",
    }
    if known[tonumber(spellID)] then
        return known[tonumber(spellID)]
    end
    if name:find("mining", 1, true) or name:find("bergbau", 1, true) or name:find("mine", 1, true) then
        return "ore"
    end
    if name:find("herbal", 1, true) or name:find("kräuter", 1, true) or name:find("krauter", 1, true)
        or name:find("herb", 1, true) or name:find("harvest", 1, true)
        or name:find("pflück", 1, true) or name:find("pfluck", 1, true) then
        return "herb"
    end
    if name:find("fishing", 1, true) or name:find("angeln", 1, true)
        or name:find("fisch", 1, true) then
        return "fishing"
    end
    if name:find("open", 1, true) or name:find("öffnen", 1, true) or name:find("offnen", 1, true)
        or name:find("plündern", 1, true) or name:find("plundern", 1, true)
        or name:find("loot", 1, true) or name:find("lockpick", 1, true)
        or name:find("lock picking", 1, true) or name:find("schloss knacken", 1, true)
        or name:find("knacken", 1, true) then
        return "treasure"
    end
    return nil
end

local function findGatherSpell(...)
    local args = { ... }
    -- Spellcast event parameters differ between the live API and older
    -- Classic-compatible clients. Search the payload instead of assuming that
    -- the spell name or ID always occupies the same argument position.
    for index = #args, 1, -1 do
        if not FC:IsSecret(args[index]) and classifySpell(args[index]) then return args[index] end
    end
end

local function defaultIcon(kind)
    if kind == "ore" then return "Interface\\Icons\\Trade_Mining" end
    if kind == "herb" then return "Interface\\Icons\\Trade_Herbalism" end
    if kind == "fishing" then return "Interface\\Icons\\Trade_Fishing" end
    if kind == "treasure" then return "Interface\\Icons\\INV_Misc_Chest_01" end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function mapNames(mapID, zone, subZone)
    if FC:IsSecret(mapID) or type(mapID) ~= "number" then mapID = nil end
    if FC:IsSecret(zone) or type(zone) ~= "string" then zone = "" end
    if FC:IsSecret(subZone) or type(subZone) ~= "string" then subZone = "" end
    local continent = ""
    local mapName = zone or ""
    if C_Map and C_Map.GetMapInfo and mapID then
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if not ok or FC:IsSecret(info) or type(info) ~= "table" then info = nil end
        local infoName = info and info.name
        if FC:IsSecret(infoName) or type(infoName) ~= "string" then infoName = nil end
        if infoName and infoName ~= "" then
            mapName = mapName ~= "" and mapName or infoName
        end
        local parent = info and info.parentMapID
        if FC:IsSecret(parent) or type(parent) ~= "number" then parent = nil end
        local guard = 0
        while parent and parent ~= 0 and guard < 8 do
            local parentOK, parentInfo = pcall(C_Map.GetMapInfo, parent)
            if not parentOK or FC:IsSecret(parentInfo) or type(parentInfo) ~= "table" then parentInfo = nil end
            if not parentInfo then break end
            local parentType, parentID, parentName = parentInfo.mapType, parentInfo.parentMapID, parentInfo.name
            if FC:IsSecret(parentType) then parentType = nil end
            if FC:IsSecret(parentID) then parentID = nil end
            if FC:IsSecret(parentName) then parentName = nil end
            if parentType == 2 or not parentID or parentID == 0 then
                continent = type(parentName) == "string" and parentName or continent
                break
            end
            parent = type(parentID) == "number" and parentID or nil
            guard = guard + 1
        end
    end
    return continent, mapName, subZone or ""
end

local function nodeName(kind, target)
    if target and target ~= "" then
        return target
    end
    if kind == "ore" then return FC.L.ORE_NODE end
    if kind == "herb" then return FC.L.HERB_NODE end
    if kind == "fishing" then return FC.L.FISHING_NODE end
    if kind == "treasure" then return FC.L.TREASURE_NODE end
    return FC.L.RESOURCE_NODE
end

local function sameNode(node, kind, name, location)
    if not node or not location or node.kind ~= kind or node.mapID ~= location.mapID then
        return false
    end
    if lower(node.name) ~= lower(name) then
        return false
    end
    return math.abs((node.x or 0) - (location.x or 0)) < 0.12
        and math.abs((node.y or 0) - (location.y or 0)) < 0.12
end

function FC:IndexAtlasNode(node)
    if not node then return end
    local atlas = self.db and self.db.atlas
    if not atlas then return end
    atlas.byContinent = atlas.byContinent or {}
    atlas.byMap = atlas.byMap or {}
    local continent = node.continent ~= "" and (node.continent or self.L.UNKNOWN) or self.L.UNKNOWN
    local zone = node.zone ~= "" and (node.zone or self.L.UNKNOWN) or self.L.UNKNOWN
    atlas.byContinent[continent] = atlas.byContinent[continent] or {}
    atlas.byContinent[continent][zone] = atlas.byContinent[continent][zone] or {}
    atlas.byContinent[continent][zone][tostring(node.id)] = true
    if node.mapID then
        local mapKey = tostring(node.mapID)
        atlas.byMap[mapKey] = atlas.byMap[mapKey] or {}
        atlas.byMap[mapKey][tostring(node.id)] = true
    end
end

function FC:RemoveAtlasNodeIndex(node)
    if not node or not self.db or not self.db.atlas then return end
    local atlas, id = self.db.atlas, tostring(node.id)
    local continent = node.continent ~= "" and (node.continent or self.L.UNKNOWN) or self.L.UNKNOWN
    local zone = node.zone ~= "" and (node.zone or self.L.UNKNOWN) or self.L.UNKNOWN
    local byZone = atlas.byContinent and atlas.byContinent[continent] and atlas.byContinent[continent][zone]
    if byZone then byZone[id] = nil end
    local mapKey = node.mapID and tostring(node.mapID)
    if mapKey and atlas.byMap and atlas.byMap[mapKey] then atlas.byMap[mapKey][id] = nil end
end

function FC:RebuildAtlasIndex()
    if not self.db or not self.db.atlas then return end
    self.db.atlas.byContinent = {}
    self.db.atlas.byMap = {}
    for _, node in pairs(self.db.atlas.nodes or {}) do
        self:IndexAtlasNode(node)
    end
end

function FC:RecordAtlasNode(kind, name, location, source)
    if not self.initialized or not self.db.settings.trackItems then
        return nil, false
    end
    kind = self:SanitizeStoredValue(kind)
    name = self:SanitizeStoredValue(name)
    location = self:SanitizeStoredValue(location)
    source = self:SanitizeStoredValue(source)
    if type(kind) ~= "string" or type(name) ~= "string" or type(location) ~= "table" then return nil, false end
    local mapID, x, y = location.mapID, location.x, location.y
    if type(mapID) ~= "number" or mapID <= 0 or mapID ~= mapID
        or type(x) ~= "number" or type(y) ~= "number"
        or x ~= x or y ~= y or x < 0 or x > 1 or y < 0 or y > 1 then return nil, false end
    kind = kind or "other"
    name = nodeName(kind, name)
    local atlas = self.db.atlas
    local node
    local mapNodes = atlas.byMap and atlas.byMap[tostring(location.mapID)] or nil
    for nodeKey in pairs(mapNodes or {}) do
        local candidate = atlas.nodes[tostring(nodeKey)]
        if sameNode(candidate, kind, name, location) then
            node = candidate
            break
        end
    end
    local now = self:Now()
    local isFirst = node == nil
    if node and self.RemoveAtlasNodeIndex then self:RemoveAtlasNodeIndex(node) end
    local continent, zone, subZone = mapNames(location.mapID, location.zone, location.subZone)
    if not node then
        local id = atlas.nextNodeID or 1
        atlas.nextNodeID = id + 1
        node = {
            id = id,
            kind = kind,
            name = name,
            icon = defaultIcon(kind),
            mapID = location.mapID,
            continent = continent,
            zone = zone,
            subZone = subZone,
            x = location.x,
            y = location.y,
            firstSeen = now,
            lastSeen = now,
            count = 0,
            source = source or "gather",
            characters = {},
            lootItems = {},
        }
        atlas.nodes[tostring(id)] = node
    end
    node.name = name or node.name
    node.continent = continent ~= "" and continent or node.continent
    node.zone = zone or node.zone
    node.subZone = subZone or node.subZone
    node.x = location.x or node.x
    node.y = location.y or node.y
    node.lastSeen = now
    node.count = (node.count or 0) + 1
    node.source = source or node.source
    node.characters = node.characters or {}
    node.characters[self.characterKey] = (node.characters[self.characterKey] or 0) + 1
    node.lootItems = node.lootItems or {}
    self:IndexAtlasNode(node)
    lastGatherNode = node

    if isFirst then
        self.profile.stats.atlasNodes = (self.profile.stats.atlasNodes or 0) + 1
    end
    -- The atlas merges repeated visits into one map node, while the diary keeps
    -- every successful gather as a session event.
    if self.LogEvent then
        self:LogEvent("GATHER", self.L.GATHERED .. ": " .. name, self:FormatLocation(location), {
            nodeID = node.id,
            kind = kind,
        })
    end
    return node, isFirst
end

local function itemInfo(itemID)
    local name, link, quality
    if GetItemInfo then
        name, link, quality = GetItemInfo(itemID)
    end
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    elseif GetItemIcon then
        icon = GetItemIcon(itemID)
    end
    if FC:IsSecret(name) then name = nil end
    if FC:IsSecret(link) then link = nil end
    if FC:IsSecret(quality) then quality = nil end
    if FC:IsSecret(icon) then icon = nil end
    if type(name) ~= "string" then name = nil end
    if type(link) ~= "string" then link = nil end
    if type(quality) ~= "number" then quality = nil end
    if type(icon) ~= "string" and type(icon) ~= "number" then icon = nil end
    return name, link, quality, icon
end

function FC:AttachGatherLoot(message)
    if self:IsSecret(message) or type(message) ~= "string" or not lastGatherNode or self:Now() - (lastGatherNode.lastSeen or 0) > 8 then
        return
    end
    for rawItemID in message:gmatch("item:(%d+)") do
        local itemID = tonumber(rawItemID)
        local name, link, quality, icon = itemInfo(itemID)
        local key = tostring(itemID)
        local item = lastGatherNode.lootItems[key] or { id = itemID, firstSeen = self:Now() }
        item.name = name or item.name or string.format(self.L.ITEM_ID, key)
        item.link = link or item.link
        item.quality = quality or item.quality
        item.icon = icon or item.icon
        item.lastSeen = self:Now()
        item.count = (item.count or 0) + 1
        lastGatherNode.lootItems[key] = item
        if icon then
            lastGatherNode.lootIcon = icon
        end
    end
end

local function startGather(self, unit, target, _, spellID)
    if self:IsSecret(unit) then return end
    if unit ~= "player" or not self.initialized then
        return
    end
    if self:IsSecret(target) or type(target) ~= "string" then target = nil end
    local kind = classifySpell(spellID)
    if not kind then
        return
    end
    pendingGather = {
        kind = kind,
        target = target,
        spellID = spellID,
        startedAt = self:Now(),
        finished = false,
    }
end

local function finishGather(self, unit, _, _, spellID)
    if self:IsSecret(unit) then return end
    if unit ~= "player" or not pendingGather then
        return
    end
    local completedKind = classifySpell(spellID)
    if completedKind and completedKind ~= pendingGather.kind then
        return
    end
    if pendingGather.finished then
        return
    end
    pendingGather.finished = true
    local gather = pendingGather
    pendingGather = nil
    if self:Now() - (gather.startedAt or self:Now()) > 12 then
        return
    end
    self:RecordAtlasNode(gather.kind, nodeName(gather.kind, gather.target), self:GetLocation(), "gather")
end

FC:RegisterEvent("UNIT_SPELLCAST_SENT", function(self, _, unit, ...)
    local args = { ... }
    startGather(self, unit, args[1], nil, findGatherSpell(unpack(args)))
end)

FC:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(self, _, unit, ...)
    finishGather(self, unit, nil, nil, findGatherSpell(...))
end)

FC:RegisterEvent("UNIT_SPELLCAST_STOP", function(self, _, unit, ...)
    finishGather(self, unit, nil, nil, findGatherSpell(...))
end)

FC:RegisterEvent("UNIT_SPELLCAST_FAILED", function(_, _, unit)
    if unit == "player" then pendingGather = nil end
end)

FC:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(_, _, unit)
    if unit == "player" then pendingGather = nil end
end)

FC:RegisterEvent("CHAT_MSG_LOOT", function(self, _, message)
    self:AttachGatherLoot(message)
end)

FC:RegisterEvent("PLAYER_LOGIN", function(self)
    if self.initialized then self:RebuildAtlasIndex() end
end)
