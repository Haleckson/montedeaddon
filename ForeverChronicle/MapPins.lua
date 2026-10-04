local _, namespace = ...
local FC = namespace.FC

-- The Blizzard map only offers one user waypoint.  Chronicle pins are a
-- separate, local overlay so one remembered category can be inspected at a
-- time without replacing the player's waypoint or covering the map in layers.
local pinPool = {}
local visiblePins = {}
local pinOverlay
local pinOverlayParent
local pinOverlayCanvas
local filterButton
local filterPanel
local clusterMenu
local clusterMenuRows = {}
local refreshElapsed = 0
local clipElapsed = 0
local clipPinsToMap
local mapHooksInstalled = false

local PIN_ICONS = {
    -- Use familiar Classic inventory art for map markers. These icons are
    -- rendered directly by the client, without depending on a custom atlas.
    ore = "Interface\\Icons\\INV_Ore_Copper_01",
    herb = "Interface\\Icons\\INV_Misc_Flower_02",
    fishing = "Interface\\Icons\\Trade_Fishing",
    treasure = "Interface\\Icons\\INV_Misc_Chest_01",
    quests = "Interface\\Icons\\INV_Misc_Note_02",
    QUEST_COMPLETED = "Interface\\Icons\\INV_Misc_Note_02",
    rare = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    rares = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    RARE = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    npc = "Interface\\Icons\\INV_Misc_Head_Human_01",
    npcs = "Interface\\Icons\\INV_Misc_Head_Human_01",
    enemies = "Interface\\Icons\\INV_Sword_04",
    dungeons = "Interface\\Icons\\INV_Misc_Key_03",
    entrances = "Interface\\Icons\\INV_Misc_Key_03",
    DUNGEON = "Interface\\Icons\\INV_Misc_Key_03",
    note = "Interface\\Icons\\INV_Misc_Note_01",
    items = "Interface\\Icons\\INV_Misc_Bag_10",
    merchant = "Interface\\Icons\\INV_Misc_Coin_01",
    trainer = "Interface\\Icons\\Ability_Marksmanship",
    zones = "Interface\\Icons\\INV_Misc_Map_01",
}


local MARKER_ATLAS = "Interface\\AddOns\\ForeverChronicle\\Icons\\ChroniclePins.tga"
local MARKER_CELLS = 4
local MARKER_INDICES = {
    ore = 1, herb = 2, fishing = 3, treasure = 4,
    quests = 5, questflow = 5, QUEST_COMPLETED = 5,
    rare = 6, rares = 6, RARE = 6,
    npc = 7, npcs = 7, companion = 7, dungeons = 8, entrances = 8, DUNGEON = 8,
    note = 9, items = 10, items_account = 10, merchant = 11, trainer = 12, zones = 13,
}
local function markerIndex(kind, category, quality)
    local normalizedKind = type(kind) == "string" and string.lower(kind) or ""
    if normalizedKind == "item" then normalizedKind = "items" end
    if normalizedKind == "item_account" then normalizedKind = "items_account" end
    if normalizedKind == "quest" then normalizedKind = "quests" end
    if normalizedKind == "dungeon" then normalizedKind = "dungeons" end
    if normalizedKind == "items" or normalizedKind == "items_account"
        or category == FC.L.MAP_ITEMS then
        local qualityIndex = tonumber(quality)
        if qualityIndex == 2 then return 14 end
        if qualityIndex == 3 then return 15 end
        if qualityIndex == 4 then return 16 end
        return 10
    end
    local index = MARKER_INDICES[normalizedKind] or MARKER_INDICES[kind]
    if index then return index end
    local localized = {
        [FC.L.ORE_NODE] = 1, [FC.L.MAP_ORE] = 1,
        [FC.L.HERB_NODE] = 2, [FC.L.MAP_HERBS] = 2,
        [FC.L.FISHING_NODE] = 3, [FC.L.MAP_FISHING] = 3,
        [FC.L.TREASURE_NODE] = 4, [FC.L.MAP_TREASURES] = 4,
        [FC.L.MAP_QUESTS] = 5, [FC.L.MAP_RARES] = 6,
        [FC.L.MAP_NPCS] = 7, [FC.L.MAP_DUNGEONS] = 8,
        [FC.L.MAP_NOTES] = 9, [FC.L.MAP_MERCHANTS] = 11,
        [FC.L.MAP_TRAINERS] = 12, [FC.L.MAP_ZONES] = 13,
    }
    return localized[category] or 10
end

local function setMarkerIcon(texture, index)
    index = math.max(1, math.min(16, tonumber(index) or 10)) - 1
    local col, row = index % MARKER_CELLS, math.floor(index / MARKER_CELLS)
    local cell = 1 / MARKER_CELLS
    texture:SetTexture(MARKER_ATLAS)
    -- SetTexCoord's four-argument order is left, right, top, bottom.
    -- Keep the columns on the horizontal axis and rows on the vertical axis;
    -- swapping the middle arguments crops most symbols from the wrong cells.
    texture:SetTexCoord(col * cell, (col + 1) * cell, row * cell, (row + 1) * cell)
end

local PIN_COLORS = {
    ore = { 0.82, 0.58, 0.29 }, herb = { 0.42, 0.78, 0.34 },
    fishing = { 0.28, 0.68, 0.96 }, treasure = { 1.00, 0.75, 0.25 },
    quests = { 0.96, 0.83, 0.48 }, QUEST_COMPLETED = { 0.96, 0.83, 0.48 },
    rare = { 1.00, 0.36, 0.20 }, rares = { 1.00, 0.36, 0.20 }, RARE = { 1.00, 0.36, 0.20 },
    npc = { 0.38, 0.75, 0.94 }, npcs = { 0.38, 0.75, 0.94 },
    enemies = { 0.94, 0.34, 0.24 },
    dungeons = { 0.74, 0.52, 0.96 }, entrances = { 1.00, 0.78, 0.28 }, DUNGEON = { 0.74, 0.52, 0.96 },
    note = { 0.34, 0.86, 0.80 }, items = { 0.92, 0.88, 0.72 }, zones = { 0.50, 0.76, 0.90 },
    merchant = { 1.00, 0.78, 0.28 }, trainer = { 0.54, 0.78, 1.00 },
}

local function iconFor(kind, category, fallback)
    local normalizedKind = type(kind) == "string" and string.lower(kind) or ""
    if normalizedKind == "item" or normalizedKind == "item_account" or normalizedKind == "items_account" then
        normalizedKind = "items"
    elseif normalizedKind == "quest" then
        normalizedKind = "quests"
    elseif normalizedKind == "dungeon" then
        normalizedKind = "dungeons"
    elseif normalizedKind == "entrance" then
        normalizedKind = "entrances"
    elseif normalizedKind == "rare" then
        normalizedKind = "rares"
    elseif normalizedKind == "npc" then
        normalizedKind = "npcs"
    end
    if normalizedKind == "items" and fallback then return fallback end
    local byKind = PIN_ICONS[normalizedKind] or PIN_ICONS[kind]
    if byKind then return byKind end
    local localized = {
        [FC.L.ORE_NODE] = PIN_ICONS.ore, [FC.L.MAP_ORE] = PIN_ICONS.ore,
        [FC.L.HERB_NODE] = PIN_ICONS.herb, [FC.L.MAP_HERBS] = PIN_ICONS.herb,
        [FC.L.FISHING_NODE] = PIN_ICONS.fishing, [FC.L.MAP_FISHING] = PIN_ICONS.fishing,
        [FC.L.TREASURE_NODE] = PIN_ICONS.treasure, [FC.L.MAP_TREASURES] = PIN_ICONS.treasure,
        [FC.L.MAP_QUESTS] = PIN_ICONS.quests, [FC.L.MAP_RARES] = PIN_ICONS.rares,
        [FC.L.MAP_NPCS] = PIN_ICONS.npcs, [FC.L.MAP_DUNGEONS] = PIN_ICONS.dungeons,
        [FC.L.MAP_ENTRANCES] = PIN_ICONS.entrances,
        [FC.L.MAP_NOTES] = PIN_ICONS.note,
    }
    return localized[category] or fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local FILTERS = {
    { key = "mapShowOre", label = "MAP_ORE" },
    { key = "mapShowHerbs", label = "MAP_HERBS" },
    { key = "mapShowFishing", label = "MAP_FISHING" },
    { key = "mapShowTreasures", label = "MAP_TREASURES" },
    { key = "mapShowQuests", label = "MAP_QUESTS" },
    { key = "mapShowNotes", label = "MAP_NOTES" },
    { key = "mapShowRares", label = "MAP_RARES" },
    { key = "mapShowEnemies", label = "MAP_ENEMIES" },
    { key = "mapShowNPCs", label = "MAP_NPCS" },
    { key = "mapShowMerchants", label = "MAP_MERCHANTS" },
    { key = "mapShowTrainers", label = "MAP_TRAINERS" },
    { key = "mapShowItemsGreen", label = "MAP_ITEMS_UNCOMMON" },
    { key = "mapShowItemsBlue", label = "MAP_ITEMS_RARE" },
    { key = "mapShowItemsPurple", label = "MAP_ITEMS_EPIC" },
    { key = "mapShowDungeons", label = "MAP_DUNGEONS" },
    { key = "mapShowEntrances", label = "MAP_ENTRANCES" },
    { key = "mapShowZones", label = "MAP_ZONES" },
}

local function isResourceFilter(key)
    return key == "mapShowOre" or key == "mapShowHerbs"
        or key == "mapShowFishing" or key == "mapShowTreasures"
end

local function applyExclusiveFilter(settings, key)
    local valid = false
    for _, definition in ipairs(FILTERS) do
        if definition.key == key then valid = true end
        settings[definition.key] = definition.key == key
    end
    if not valid then key = nil end
    -- The former "all items" checkbox was removed; only an exact Chronicle
    -- search spotlight or a selected quality layer may put items on the map.
    settings.mapShowItems = false
    settings.activeMapFilter = key
    settings.mapShowAtlas = isResourceFilter(key)
end

local function normalizeExclusiveFilter(settings)
    local active = settings.activeMapFilter
    local known = false
    for _, definition in ipairs(FILTERS) do
        if definition.key == active then known = true; break end
    end
    if not known then
        -- Convert pre-exclusive saved settings once. Keep the first selected
        -- category in the displayed order, then turn the other layers off.
        for _, definition in ipairs(FILTERS) do
            if settings[definition.key] == true then active = definition.key; break end
        end
    end
    applyExclusiveFilter(settings, active)
end

local function mapCanvas()
    if not WorldMapFrame then
        return nil
    end
    -- Forever's Classic map uses the scroll child as the actual map-art
    -- coordinate space. Prefer it over newer GetCanvas accessors, which can
    -- return the viewport/container instead and place every pin off the art.
    local scroll = WorldMapFrame.ScrollContainer
    if scroll then
        if scroll.GetScrollChild then
            local child = scroll:GetScrollChild()
            if child then return child end
        end
        if scroll.Child then return scroll.Child end
    end
    return WorldMapFrame
end

local function currentMapID()
    if WorldMapFrame and WorldMapFrame.GetMapID then
        local ok, mapID = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
        if ok and not FC:IsSecret(mapID) and type(mapID) == "number" then return mapID end
    end
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and not FC:IsSecret(mapID) and type(mapID) == "number" then return mapID end
    end
end

local function getPinOverlay(canvas)
    if not canvas or not WorldMapFrame then return nil end
    local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
    if not pinOverlay then
        pinOverlay = CreateFrame("Frame", "ForeverChronicleMapPinsOverlay", parent)
        pinOverlayParent = parent
    elseif pinOverlayParent ~= parent then
        pinOverlay:SetParent(parent)
        pinOverlay:ClearAllPoints()
        pinOverlayParent = parent
        pinOverlayCanvas = nil
    end
    if pinOverlayCanvas ~= canvas then
        pinOverlay:ClearAllPoints()
        pinOverlay:SetAllPoints(canvas)
        pinOverlayCanvas = canvas
    end
    local parentLevel = parent.GetFrameLevel and parent:GetFrameLevel() or 0
    pinOverlay:SetFrameLevel(math.max(100, (tonumber(parentLevel) or 0) + 100))
    return pinOverlay
end

local function showClusterMenu(anchor, members)
    if not clusterMenu then
        clusterMenu = CreateFrame("Frame", nil, WorldMapFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
        clusterMenu:SetFrameStrata("DIALOG")
        clusterMenu:SetClampedToScreen(true)
        if clusterMenu.SetBackdrop then
            clusterMenu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            clusterMenu:SetBackdropColor(0.035, 0.035, 0.055, 0.98)
        end
        local scroll = CreateFrame("ScrollFrame", nil, clusterMenu, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -8)
        scroll:SetPoint("BOTTOMRIGHT", -28, 8)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetWidth(260)
        scroll:SetScrollChild(child)
        clusterMenu.child = child
        clusterMenu:Hide()
    end
    clusterMenu:ClearAllPoints()
    clusterMenu.mapID = members[1] and members[1].location and members[1].location.mapID
    clusterMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
    clusterMenu:SetSize(294, math.min(#members * 25 + 16, 266))
    clusterMenu.child:SetHeight(math.max(1, #members * 25))
    for index, member in ipairs(members) do
        local row = clusterMenuRows[index]
        if not row then
            row = CreateFrame("Button", nil, clusterMenu.child)
            row:SetHeight(24)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", 6, 0)
            row.label:SetPoint("RIGHT", -6, 0)
            row.label:SetJustifyH("LEFT")
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            clusterMenuRows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", clusterMenu.child, "TOPLEFT", 0, -(index - 1) * 25)
        row:SetPoint("TOPRIGHT", clusterMenu.child, "TOPRIGHT", 0, -(index - 1) * 25)
        row.label:SetText(member.title or member.name or FC.L.UNKNOWN)
        row:SetScript("OnClick", function()
            clusterMenu:Hide()
            FC:SetWaypoint(member.location)
        end)
        row:Show()
    end
    for index = #members + 1, #clusterMenuRows do clusterMenuRows[index]:Hide() end
    clusterMenu:Show()
end

local function createPin(index)
    local parent = pinOverlay
    if not parent then return nil end
    local pin = CreateFrame("Button", "ForeverChronicleMapPin" .. index, parent)
    pin:SetSize(20, 20)
    local parentLevel = parent.GetFrameLevel and parent:GetFrameLevel() or 0
    pin:SetFrameLevel((tonumber(parentLevel) or 0) + 1)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Keep the map itself legible: use one compact gold point instead of a
    -- square inventory icon. The selected exclusive filter supplies its
    -- meaning, while the tooltip names the remembered object or creature.
    pin:SetNormalTexture("Interface\\COMMON\\Indicator-Yellow")
    local icon = pin:GetNormalTexture()
    icon:SetSize(9, 9)
    icon:SetPoint("CENTER")
    icon:SetVertexColor(1.00, 0.77, 0.20, 1)
    pin.icon = icon

    local border = pin:CreateTexture(nil, "OVERLAY")
    border:SetSize(22, 22)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(1.00, 0.76, 0.22, 1)
    border:SetAlpha(0.9)
    pin.border = border

    local bundleRing = pin:CreateTexture(nil, "ARTWORK")
    bundleRing:SetPoint("CENTER")
    bundleRing:SetSize(28, 28)
    bundleRing:SetColorTexture(0.96, 0.72, 0.24, 1)
    bundleRing:Hide()
    pin.bundleRing = bundleRing

    local bundleCenter = pin:CreateTexture(nil, "ARTWORK")
    bundleCenter:SetPoint("CENTER")
    bundleCenter:SetSize(23, 23)
    bundleCenter:SetColorTexture(0.13, 0.09, 0.035, 0.96)
    bundleCenter:Hide()
    pin.bundleCenter = bundleCenter

    local cluster = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cluster:SetPoint("CENTER", 0, 0)
    cluster:SetJustifyH("CENTER")
    cluster:SetTextColor(1, 1, 1)
    cluster:SetShadowColor(0, 0, 0, 1)
    cluster:SetShadowOffset(1, -1)
    pin.cluster = cluster

    pin:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    pin:SetScript("OnClick", function(self, button)
        local data = self.data
        if not data then return end
        if data.members and #data.members > 1 then
            if button == "RightButton" then
                FC:OpenMemory(data.title or data.name or "")
            elseif clusterMenu and clusterMenu:IsShown() then clusterMenu:Hide()
            else showClusterMenu(self, data.members) end
            return
        end
        if button == "RightButton" then
            FC:OpenMemory(data.title or data.name or "")
        else
            FC:SetWaypoint(data.location)
        end
    end)
    pin:SetScript("OnEnter", function(self)
        local data = self.data
        if not data or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(data.title or data.name or FC.L.ATLAS, 1.0, 0.82, 0.25)
        if data.category then
            GameTooltip:AddLine(data.category, 0.82, 0.82, 0.72)
        end
        local quality = tonumber(data.quality)
        local qualityKey = quality == 2 and "ITEM_QUALITY_UNCOMMON"
            or quality == 3 and "ITEM_QUALITY_RARE"
            or quality == 4 and "ITEM_QUALITY_EPIC"
        if qualityKey and FC.L[qualityKey] then
            local qualityColor = quality == 4 and { 0.72, 0.34, 0.96 }
                or quality == 3 and { 0.32, 0.62, 1.00 } or { 0.24, 0.78, 0.30 }
            GameTooltip:AddLine(FC.L[qualityKey], qualityColor[1], qualityColor[2], qualityColor[3])
        end
        if data.clusterCount and data.clusterCount > 1 then
            GameTooltip:AddLine(string.format("%s: %d", FC.L.MAP_CLUSTER, data.clusterCount), 0.78, 0.78, 0.78)
            for index, member in ipairs(data.members or {}) do
                if index > 8 then break end
                GameTooltip:AddLine(member.title or member.name or FC.L.UNKNOWN, 0.88, 0.84, 0.72)
            end
        end
        if data.location then
            local place = FC:FormatLocation(data.location)
            if place ~= "" then GameTooltip:AddLine(place, 0.70, 0.85, 1.0) end
        end
        if data.count and data.count > 1 then
            GameTooltip:AddLine(string.format("%s: %d", FC.L.GATHERED, data.count), 0.78, 0.78, 0.78)
        end
        if data.detail and data.detail ~= "" then
            GameTooltip:AddLine(data.detail, 0.72, 0.72, 0.72, true)
        end
        GameTooltip:AddLine(data.members and #data.members > 1 and FC.L.MAP_CLUSTER_CLICK_HELP or FC.L.MAP_CLICK_HELP, 0.62, 0.62, 0.62)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return pin
end

local function acquirePin(index)
    local pin = pinPool[index]
    if not pin then
        pin = createPin(index)
        pinPool[index] = pin
    end
    return pin
end

local function addPin(list, category, title, location, extra)
    if not location or type(location.mapID) ~= "number" or location.mapID <= 0
        or type(location.x) ~= "number" or type(location.y) ~= "number"
        or location.x ~= location.x or location.y ~= location.y
        or location.x < 0 or location.x > 100 or location.y < 0 or location.y > 100 then
        return
    end
    extra = extra or {}
    extra.category = category
    extra.title = title or extra.name or category
    extra.location = location
    extra.icon = iconFor(extra.kind, category, extra.icon)
    extra.markerIndex = markerIndex(extra.kind, category, extra.quality)
    local tint = extra.kind == "items" and (tonumber(extra.quality) == 4 and { 0.72, 0.34, 0.96 }
        or tonumber(extra.quality) == 3 and { 0.32, 0.62, 1.00 }
        or tonumber(extra.quality) == 2 and { 0.24, 0.78, 0.30 })
    extra.pinColor = tint or PIN_COLORS[extra.kind] or PIN_COLORS[category] or PIN_COLORS.items
    table.insert(list, extra)
end

local function latestLocation(record)
    if record and record.locations and #record.locations > 0 then
        return record.locations[#record.locations]
    end
end

local function collectPins(mapID)
    local result = {}
    local settings = FC.GetMapSettings and FC:GetMapSettings() or (FC.db and FC.db.settings or {})
    normalizeExclusiveFilter(settings)
    local pinsEnabled = settings.mapPinsEnabled ~= false

    -- A Chronicle click is an exact search result. Show only that result's
    -- remembered locations; saved map layers stay intact but cannot flood it.
    local spotlight = FC.mapSpotlight
    if spotlight then
        for index, location in ipairs(spotlight.locations or {}) do
            if location.mapID == mapID then
                addPin(result, FC.L.MAP_SPOTLIGHT, spotlight.title, location, {
                    kind = spotlight.kind,
                    quality = spotlight.quality,
                    icon = iconFor(spotlight.kind, nil, spotlight.icon or "Interface\\Icons\\INV_Misc_Spyglass_03"),
                    detail = string.format(FC.L.MAP_SPOTLIGHT_DETAIL, index, #spotlight.locations),
                    spotlight = true,
                })
            end
        end
        table.sort(result, function(a, b) return (a.title or "") < (b.title or "") end)
        return result
    end

    if pinsEnabled and settings.mapShowAtlas ~= false then
        local atlas = FC.db.atlas or {}
        local nodes = {}
        local mapIndex = atlas.byMap and atlas.byMap[tostring(mapID)]
        if mapIndex then
            for nodeID in pairs(mapIndex) do
                if atlas.nodes and atlas.nodes[nodeID] then
                    table.insert(nodes, atlas.nodes[nodeID])
                end
            end
        else
            for _, node in pairs(atlas.nodes or {}) do
                if node.mapID == mapID then table.insert(nodes, node) end
            end
        end
        for _, node in ipairs(nodes) do
            local kindSetting = true
            if node.kind == "ore" then kindSetting = settings.mapShowOre
            elseif node.kind == "herb" then kindSetting = settings.mapShowHerbs
            elseif node.kind == "fishing" then kindSetting = settings.mapShowFishing
            elseif node.kind == "treasure" then kindSetting = settings.mapShowTreasures end
            if kindSetting ~= false then
                local loot = {}
                for _, item in pairs(node.lootItems or {}) do
                    if item.name then table.insert(loot, item.name) end
                end
                table.sort(loot)
                local discoverers = {}
                for characterKey, count in pairs(node.characters or {}) do
                    local profile = FC.db.characters and FC.db.characters[characterKey]
                    local identity = profile and profile.identity
                    local name = identity and identity.name or characterKey
                    if (tonumber(count) or 0) > 1 then name = name .. " (" .. tostring(count) .. ")" end
                    table.insert(discoverers, name)
                end
                table.sort(discoverers)
                local details = {}
                if #loot > 0 then table.insert(details, table.concat(loot, ", ")) end
                if #discoverers > 0 then
                    table.insert(details, string.format(FC.L.MAP_FOUND_BY, table.concat(discoverers, ", ")))
                end
                addPin(result, node.kind == "herb" and FC.L.HERB_NODE
                    or node.kind == "ore" and FC.L.ORE_NODE
                    or node.kind == "fishing" and FC.L.FISHING_NODE
                    or node.kind == "treasure" and FC.L.TREASURE_NODE
                    or FC.L.RESOURCE_NODE, node.name, {
                    mapID = node.mapID, zone = node.zone, subZone = node.subZone,
                    x = node.x, y = node.y,
                }, { kind = node.kind, icon = iconFor(node.kind, node.kind), count = node.count,
                    detail = table.concat(details, "\n") })
            end
        end
    end

    if pinsEnabled and settings.mapShowQuests ~= false then
        for _, quest in pairs(FC.db.questArchive and FC.db.questArchive.quests or {}) do
            local latest = quest.locations and quest.locations[#quest.locations]
            if latest and latest.mapID == mapID then
                local completedBy = {}
                for characterKey in pairs(latest.characters or {}) do
                    local profile = FC.db.characters and FC.db.characters[characterKey]
                    local identity = profile and profile.identity
                    table.insert(completedBy, (identity and identity.name) or characterKey)
                end
                if #completedBy == 0 then
                    for characterKey, character in pairs(quest.completedBy or {}) do
                        table.insert(completedBy, character.name or characterKey)
                    end
                end
                table.sort(completedBy)
                local detail = quest.englishName and (FC.L.QUEST_ENGLISH .. ": " .. quest.englishName)
                    or FC.L.QUEST_TRANSLATION_PENDING
                if #completedBy > 0 then detail = detail .. "  •  " .. table.concat(completedBy, ", ") end
                addPin(result, FC.L.MAP_QUESTS, quest.currentName or string.format(FC.L.QUEST_ID, tostring(quest.id)), {
                    mapID = latest.mapID, zone = latest.zone, subZone = latest.subZone,
                    x = latest.x, y = latest.y,
                }, {
                    kind = "quests",
                    icon = "Interface\\Icons\\INV_Misc_Note_02",
                    detail = detail,
                    count = quest.count,
                })
            end
        end
    end

    for characterKey, profile in pairs(FC.db.characters or {}) do
        if pinsEnabled and settings.mapShowNotes ~= false then
            for _, note in ipairs(profile.notes or {}) do
                -- Map visibility and arrival reminders are independent settings:
                -- disabling a reminder must never erase the user's map marker.
                if note.archived ~= true and note.mapVisible ~= false and note.location and note.location.mapID == mapID then
                    addPin(result, FC.L.MAP_NOTES, note.text, note.location, {
                        kind = "note",
                        icon = "Interface\\Icons\\INV_Misc_Note_01",
                        detail = characterKey,
                    })
                end
            end
        end
        if pinsEnabled and settings.mapShowMerchants then
            for _, merchant in pairs(profile.merchants or {}) do
                local locations = type(merchant.locations) == "table" and merchant.locations or {}
                if #locations == 0 and merchant.location then locations = { merchant.location } end
                local categories = {}
                for category in pairs(merchant.categories or {}) do table.insert(categories, category) end
                table.sort(categories)
                for _, location in ipairs(locations) do
                    if location.mapID == mapID then
                        addPin(result, FC.L.MAP_MERCHANTS, merchant.name or FC.L.MERCHANT, location, {
                            kind = "merchant", icon = PIN_ICONS.merchant,
                            detail = #categories > 0 and table.concat(categories, ", ") or FC.L.MERCHANT,
                            count = merchant.visits,
                        })
                    end
                end
            end
        end
        if pinsEnabled and settings.mapShowTrainers then
            for _, trainer in pairs(profile.trainers or {}) do
                local locations = type(trainer.locations) == "table" and trainer.locations or {}
                if #locations == 0 and trainer.location then locations = { trainer.location } end
                for _, location in ipairs(locations) do
                    if location.mapID == mapID then
                        addPin(result, FC.L.MAP_TRAINERS, trainer.name or FC.L.TRAINER, location, {
                            kind = "trainer", icon = PIN_ICONS.trainer,
                            detail = FC.L.TRAINER,
                            count = trainer.visits,
                        })
                    end
                end
            end
        end
    local categories = {
            enemies = settings.mapShowEnemies,
            rares = settings.mapShowRares,
            npcs = settings.mapShowNPCs,
            items = settings.mapShowItems or settings.mapShowItemsGreen or settings.mapShowItemsBlue or settings.mapShowItemsPurple,
            dungeons = settings.mapShowDungeons,
            entrances = settings.mapShowEntrances,
            zones = settings.mapShowZones,
        }
        for kind, enabled in pairs(categories) do
            if pinsEnabled and enabled then
                for _, record in pairs(profile.observed and profile.observed[kind] or {}) do
                    local quality = tonumber(record.quality)
                    local itemVisible = kind ~= "items" or settings.mapShowItems
                        or (quality == 2 and settings.mapShowItemsGreen)
                        or (quality == 3 and settings.mapShowItemsBlue)
                        or (quality == 4 and settings.mapShowItemsPurple)
                    if (kind ~= "npcs" or record.npcRole == "npc") and itemVisible then
                    local locations = record.locations or {}
                    if kind == "items" then
                        locations = FC.GetItemMapLocations and FC:GetItemMapLocations(record) or {}
                    elseif #locations == 0 then
                        local location = latestLocation(record)
                        if location then locations = { location } end
                    end
                    if kind == "enemies" or kind == "rares" then
                        local exactLocations = {}
                        for _, location in ipairs(locations) do
                            if location.unitPosition == true then table.insert(exactLocations, location) end
                        end
                        locations = exactLocations
                    end
                    local label = kind == "rares" and FC.L.MAP_RARES
                        or kind == "npcs" and FC.L.MAP_NPCS
                        or kind == "enemies" and FC.L.MAP_ENEMIES
                        or kind == "items" and FC.L.MAP_ITEMS
                        or kind == "dungeons" and FC.L.MAP_DUNGEONS
                        or kind == "entrances" and FC.L.MAP_ENTRANCES
                        or FC.L.MAP_ZONES
                    for locationIndex, location in ipairs(locations) do
                        if location.mapID == mapID then
                            addPin(result, label, record.name, location, {
                                kind = kind == "rares" and "rares" or kind == "enemies" and "enemies" or kind == "dungeons" and "dungeons" or kind == "entrances" and "entrances" or kind == "npcs" and "npcs" or kind == "items" and "items" or nil,
                                icon = iconFor(kind, label, record.icon),
                                quality = quality,
                                detail = characterKey .. (#locations > 1 and (" · " .. locationIndex .. "/" .. #locations) or ""),
                                count = record.count,
                            })
                        end
                    end
                    end
                end
            end
        end
    end
    table.sort(result, function(a, b)
        return (a.title or "") < (b.title or "")
    end)
    return result
end

-- Exposed for diagnostics and offline tests; the UI still uses the same
-- collector internally so test expectations match live pin selection.
function FC:GetMapPinsForMap(mapID)
    return collectPins(mapID)
end

local function updatePins()
    if not WorldMapFrame or not WorldMapFrame.IsShown or not WorldMapFrame:IsShown() then return end
    local canvas = mapCanvas()
    local overlay = getPinOverlay(canvas)
    local mapID = currentMapID()
    if not canvas or not overlay or not mapID then return end
    if clusterMenu and clusterMenu:IsShown() and clusterMenu.mapID ~= mapID then clusterMenu:Hide() end
    local width, height = overlay.GetWidth and overlay:GetWidth() or 0, overlay.GetHeight and overlay:GetHeight() or 0
    if not width or not height or width <= 0 or height <= 0 then return end

    local pins = collectPins(mapID)
    if FC:GetMapSettings().mapClusterPins or FC:GetMapSettings().mapShowNPCs
        or FC:GetMapSettings().mapShowMerchants or FC:GetMapSettings().mapShowTrainers then
        local grouped = {}
        for _, data in ipairs(pins) do
            local npcGroup = data.kind == "npcs" or data.kind == "merchant" or data.kind == "trainer"
            local groupThis = FC:GetMapSettings().mapClusterPins or npcGroup
            local existing
            if groupThis then
                for _, candidate in ipairs(grouped) do
                    local dx = (data.location.x - candidate.location.x) * width / 100
                    local dy = (data.location.y - candidate.location.y) * height / 100
                    local radius = npcGroup and 42 or 24
                    if data.category == candidate.category and dx * dx + dy * dy <= radius * radius then
                        existing = candidate
                        break
                    end
                end
            end
            if not existing then
                data.members = { data }
                table.insert(grouped, data)
            else
                table.insert(existing.members, data)
                existing.clusterCount = #existing.members
            end
        end
        pins = grouped
    end
    for index, data in ipairs(pins) do
        local pin = acquirePin(index)
        if pin then
            pin:SetParent(overlay)
            pin.data = data
            pin.icon:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            pin.icon:SetVertexColor(1.00, 0.77, 0.20, 1)
            pin.border:SetVertexColor(1.00, 0.76, 0.22, 1)
            local bundled = data.clusterCount and data.clusterCount > 1
            pin:SetSize(bundled and 30 or 20, bundled and 30 or 20)
            pin.cluster:SetText(bundled and "+" or "")
            pin.bundleRing:SetShown(bundled and true or false)
            pin.bundleCenter:SetShown(bundled and true or false)
            pin.icon:SetShown(not bundled)
            pin.border:SetShown(not bundled)
            pin.border:SetVertexColor(1, bundled and 0.92 or 0.76,
                bundled and 0.40 or 0.22, 1)
            pin:ClearAllPoints()
            -- The button is a child of the overlay, so anchor in the same
            -- local coordinate space. Anchoring to the scroll child here
            -- mixes the child's map coordinates with its parent's offsets.
            pin:SetPoint("CENTER", overlay, "TOPLEFT",
                (data.location.x / 100) * width,
                -(data.location.y / 100) * height)
            pin:Show()
            visiblePins[index] = pin
        end
    end
    for index = #pins + 1, #pinPool do
        if pinPool[index] then pinPool[index]:Hide(); pinPool[index].data = nil end
        visiblePins[index] = nil
    end
    if clipPinsToMap then clipPinsToMap() end
end

clipPinsToMap = function()
    local viewport = WorldMapFrame and WorldMapFrame.ScrollContainer
    if not viewport or not viewport.GetLeft then return end
    local left, right, top, bottom = viewport:GetLeft(), viewport:GetRight(), viewport:GetTop(), viewport:GetBottom()
    if not left or not right or not top or not bottom then return end
    for _, pin in ipairs(visiblePins) do
        if pin and pin.data then
            local x, y = pin:GetCenter()
            local inside = x and y and x >= left + 8 and x <= right - 8
                and y >= bottom + 8 and y <= top - 8
            pin:SetShown(inside and true or false)
        end
    end
end

local function setFilter(key, value)
    if not FC.db or not FC:GetMapSettings() then return end
    local settings = FC:GetMapSettings()
    local selected = value and key or nil
    applyExclusiveFilter(settings, selected)
    settings.mapPinsEnabled = true
    if filterPanel and filterPanel.all then filterPanel.all:SetChecked(true) end
    if filterPanel then
        for _, row in ipairs(filterPanel.rows or {}) do
            row:SetChecked(row.key == selected)
        end
    end
    if FC.TouchData then FC:TouchData("map-filter:" .. tostring(key)) end
    -- Switching to a persistent layer is an explicit request to browse it.
    -- End the one-result spotlight so regular layers do not mix with it.
    FC.mapSpotlight = nil
    updatePins()
end

local function createFilterPanel()
    if filterPanel or not WorldMapFrame then return end
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    filterPanel = CreateFrame("Frame", "ForeverChronicleMapFilterPanel", WorldMapFrame, template)
    filterPanel:SetSize(360, 330)
    filterPanel:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 48, -94)
    filterPanel:SetFrameStrata("DIALOG")
    if filterPanel.SetBackdrop then
        filterPanel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 20,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        filterPanel:SetBackdropColor(0.025, 0.045, 0.074, 0.99)
        filterPanel:SetBackdropBorderColor(0.74, 0.58, 0.30, 1)
    end
    local title = filterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(FC.L.MAP_FILTER)
    title:SetTextColor(1, 0.82, 0.25)

    local all = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
    all:SetPoint("TOPLEFT", 9, -31)
    all:SetSize(22, 22)
    all.text = all:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    all.text:SetPoint("LEFT", all, "RIGHT", 3, 0)
    all.text:SetText(FC.L.MAP_ALL)
    all:SetScript("OnClick", function(self)
        local enabled = self:GetChecked() and true or false
        FC:GetMapSettings().mapPinsEnabled = enabled
        if FC.TouchData then FC:TouchData("map-pins-enabled") end
        updatePins()
    end)
    filterPanel.all = all
    filterPanel.rows = {}
    for index, definition in ipairs(FILTERS) do
        local row = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
        local column = math.floor((index - 1) / 9)
        local rowIndex = (index - 1) % 9
        row:SetPoint("TOPLEFT", 9 + column * 165, -31 - rowIndex * 25)
        row:SetSize(22, 22)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row, "RIGHT", 3, 0)
        row.text:SetWidth(145)
        row.text:SetJustifyH("LEFT")
        row.text:SetText(FC.L[definition.label])
        row.key = definition.key
        row:SetScript("OnClick", function(self)
            setFilter(self.key, self:GetChecked())
        end)
        table.insert(filterPanel.rows, row)
    end
    local cluster = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
    cluster:SetPoint("BOTTOMLEFT", filterPanel, "BOTTOMLEFT", 12, 38)
    cluster:SetSize(22, 22)
    cluster.text = cluster:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cluster.text:SetPoint("LEFT", cluster, "RIGHT", 3, 0)
    cluster.text:SetText(FC.L.MAP_CLUSTER)
    cluster:SetScript("OnClick", function(self)
        local settings = FC:GetMapSettings()
        settings.mapClusterPins = self:GetChecked() and true or false
        if FC.TouchData then FC:TouchData("map-cluster-pins") end
        updatePins()
    end)
    filterPanel.cluster = cluster
    local clearSpotlight = CreateFrame("Button", nil, filterPanel, "UIPanelButtonTemplate")
    clearSpotlight:SetSize(184, 23)
    clearSpotlight:SetPoint("BOTTOM", filterPanel, "BOTTOM", 0, 9)
    clearSpotlight:SetText(FC.L.MAP_CLEAR_SPOTLIGHT)
    clearSpotlight:SetScript("OnClick", function()
        FC.mapSpotlight = nil
        updatePins()
    end)
    filterPanel:SetScript("OnShow", function()
        local settings = FC:GetMapSettings()
        normalizeExclusiveFilter(settings)
        all:SetChecked(settings.mapPinsEnabled ~= false)
        for _, row in ipairs(filterPanel.rows) do row:SetChecked(settings.activeMapFilter == row.key) end
        cluster:SetChecked(settings.mapClusterPins == true)
    end)
    filterPanel:Hide()
end

local function createFilterButton()
    if filterButton or not WorldMapFrame then return end
    filterButton = CreateFrame("Button", "ForeverChronicleMapFilterButton", WorldMapFrame)
    filterButton:SetSize(34, 34)
    -- Anchor to the map pane itself, clear of the map title and coordinate
    -- readout. The quickslot backing and bronze action border match Classic.
    local mapPane = WorldMapFrame.ScrollContainer or WorldMapFrame
    filterButton:SetPoint("BOTTOMLEFT", mapPane, "BOTTOMLEFT", 12, 14)
    filterButton:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local icon = filterButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(19, 19)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    filterButton.icon = icon
    local border = filterButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(40, 40)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(0.92, 0.68, 0.30, 0.88)
    filterButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    filterButton:SetFrameStrata("DIALOG")
    filterButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(FC.L.MAP_FILTER_BUTTON, 1, 0.82, 0.25)
        GameTooltip:AddLine(FC.L.MAP_FILTER_HELP, 0.85, 0.82, 0.72, true)
        GameTooltip:Show()
    end)
    filterButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    filterButton:SetScript("OnClick", function()
        createFilterPanel()
        if filterPanel:IsShown() then filterPanel:Hide() else filterPanel:Show() end
    end)
    createFilterPanel()
end

function FC:ToggleMapFilterPanel()
    if not WorldMapFrame then return false end
    createFilterButton()
    createFilterPanel()
    if filterPanel:IsShown() then filterPanel:Hide() else filterPanel:Show() end
    return true
end

local function installMapHooks()
    if not WorldMapFrame then return end
    createFilterButton()
    if mapHooksInstalled then return end
    mapHooksInstalled = true
    if WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnShow", function()
            createFilterButton()
            updatePins()
        end)
    end
    local canvas = WorldMapFrame.ScrollContainer
    if canvas and canvas.HookScript then
        canvas:HookScript("OnShow", updatePins)
    end
end

local function openWorldMapAt(mapID)
    -- This runs only after the player clicks a saved Chronicle result. Keeping
    -- the call inside that direct action preserves the expected one-click flow.
    if InCombatLockdown and InCombatLockdown() then return false, "combat" end
    if not WorldMapFrame or not (WorldMapFrame.IsShown and WorldMapFrame:IsShown()) then
        local open = ToggleWorldMap
        if not open and WorldMapFrame and WorldMapFrame.Toggle then
            open = function() WorldMapFrame:Toggle() end
        end
        if not open then return false, "unavailable" end
        local ok = pcall(open)
        if not ok then return false, "blocked" end
    end
    local worldMap = WorldMapFrame
    if not worldMap or not (worldMap.IsShown and worldMap:IsShown()) then return false end
    if mapID and worldMap.SetMapID then
        local ok = pcall(worldMap.SetMapID, worldMap, mapID)
        if not ok then return false end
    elseif mapID and worldMap.ScrollContainer and worldMap.ScrollContainer.SetMapID then
        local ok = pcall(worldMap.ScrollContainer.SetMapID, worldMap.ScrollContainer, mapID)
        if not ok then return false end
    end
    installMapHooks()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, updatePins)
        C_Timer.After(0.60, updatePins)
    else
        updatePins()
    end
    return true
end

function FC:ShowLocationsOnMap(title, kind, locations, icon, quality)
    local usable = {}
    for _, location in ipairs(locations or {}) do
        if location and type(location.mapID) == "number" and location.mapID > 0
            and type(location.x) == "number" and type(location.y) == "number"
            and location.x == location.x and location.y == location.y
            and location.x >= 0 and location.x <= 100 and location.y >= 0 and location.y <= 100 then
            local validMap = true
            if C_Map and type(C_Map.GetMapInfo) == "function" then
                local ok, mapInfo = pcall(C_Map.GetMapInfo, location.mapID)
                validMap = ok and type(mapInfo) == "table"
            end
            if validMap then
                table.insert(usable, {
                    mapID = location.mapID, zone = location.zone, subZone = location.subZone,
                    x = location.x, y = location.y,
                })
            end
        end
    end
    if #usable == 0 then
        self:Print(self.L.WAYPOINT_FAILED)
        return false
    end
    self.mapSpotlight = { title = title or self.L.UNKNOWN, kind = kind, locations = usable, icon = icon, quality = quality }
    -- A Chronicle search is an explicit request to find this memory. Put the
    -- nearest saved point in the player's current zone on Blizzard's user
    -- waypoint so its native minimap tracking arrow can guide the next step.
    -- If the result is elsewhere, use its first saved location; the map still
    -- displays every location in the spotlight.
    local mapToOpen = usable[1].mapID
    if not (InCombatLockdown and InCombatLockdown()) and self.SetWaypoint then
        local playerMapID
        if C_Map and C_Map.GetBestMapForUnit then
            local ok, value = pcall(C_Map.GetBestMapForUnit, "player")
            if ok and not FC:IsSecret(value) and type(value) == "number" then playerMapID = value end
        end
        local playerX, playerY
        if playerMapID and C_Map.GetPlayerMapPosition then
            local ok, position = pcall(C_Map.GetPlayerMapPosition, playerMapID, "player")
            if not FC:IsSecret(position) and position and position.GetXY then
                local okXY, x, y = pcall(position.GetXY, position)
                if ok and okXY then playerX, playerY = x, y end
                if self.IsSecret and self:IsSecret(playerX) or type(playerX) ~= "number" then playerX = nil end
                if self.IsSecret and self:IsSecret(playerY) or type(playerY) ~= "number" then playerY = nil end
            end
        end
        local target, nearestDistance
        for _, location in ipairs(usable) do
            if location.mapID == playerMapID and playerX and playerY then
                local dx, dy = location.x / 100 - playerX, location.y / 100 - playerY
                local distance = dx * dx + dy * dy
                if not nearestDistance or distance < nearestDistance then
                    target, nearestDistance = location, distance
                end
            end
        end
        local chosen = target or usable[1]
        mapToOpen = chosen.mapID
        self:SetWaypoint(chosen, true)
    end
    -- Search spotlights are deliberately independent from persistent map layers:
    -- a single clicked result must not enable every saved category.
    if self.TouchData then self:TouchData("map-spotlight") end
    local opened, reason = openWorldMapAt(mapToOpen)
    if not opened then
        self:Print(reason == "combat" and self.L.MAP_OPEN_COMBAT or self.L.MAP_OPEN_MANUALLY)
        return false
    end
    -- Showing a search result is a routine UI action. Do not announce every
    -- click in the shared chat frame; failure messages above remain actionable.
    return true
end

FC:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    installMapHooks()
end)
FC:RegisterEvent("ADDON_LOADED", function(_, _, loadedAddon)
    if loadedAddon == "Blizzard_WorldMap" then installMapHooks() end
end)
FC:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    updatePins()
end)

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, elapsed)
    refreshElapsed = refreshElapsed + (elapsed or 0)
    clipElapsed = clipElapsed + (elapsed or 0)
    if clipElapsed >= 0.05 then
        clipElapsed = 0
        if WorldMapFrame and WorldMapFrame:IsShown() then clipPinsToMap() end
    end
    if refreshElapsed >= 0.45 then
        refreshElapsed = 0
        if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then
            installMapHooks()
            updatePins()
        end
    end
end)

FC.RefreshMapPins = updatePins
