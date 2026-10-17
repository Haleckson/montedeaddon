local C = _G.Chronicle
local window
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function text(parent, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(C:FontPath(), size)
    label:SetTextColor(unpack(color or { .96, .91, .78 }))
    return label
end

local function ensureWindow()
    if window then return window end
    window = CreateFrame("Frame", "ChronicleDungeonMapWindow", UIParent, "BackdropTemplate")
    window:SetFrameStrata("FULLSCREEN_DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({ bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 17,
        insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    window:SetBackdropColor(.09, .055, .027, .99)
    window:SetBackdropBorderColor(.77, .57, .18, 1)
    window.title = text(window, 20, { 1, .82, .1 })
    window.title:SetPoint("TOPLEFT", 18, -17)
    window.close = CreateFrame("Button", nil, window, "BackdropTemplate")
    window.close:SetSize(96, 25)
    window.close:SetPoint("TOPRIGHT", -15, -14)
    window.close:SetBackdrop({ bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    window.close:SetBackdropColor(.19, .11, .04, 1)
    window.close:SetBackdropBorderColor(.65, .47, .15, 1)
    window.close.label = text(window.close, 11, { 1, .82, .1 })
    window.close.label:SetPoint("CENTER")
    window.close:SetScript("OnClick", function() window:Hide() end)
    window.map = CreateFrame("Frame", nil, window)
    window.map:SetPoint("TOP", window, "TOP", 0, -53)
    if window.map.SetClipsChildren then window.map:SetClipsChildren(true) end
    window.map.backdrop = window.map:CreateTexture(nil, "BACKGROUND")
    window.map.backdrop:SetAllPoints(window.map)
    window.map.backdrop:SetTexture(WHITE)
    window.map.backdrop:SetVertexColor(.045, .028, .018, 1)
    window.map.art = window.map:CreateTexture(nil, "ARTWORK")
    window.map.art:SetAllPoints(window.map)
    window.map.tiles = {}
    window.map.pins = {}
    window:RegisterEvent("PLAYER_LEVEL_UP")
    window:SetScript("OnEvent", function(self)
        if not self:IsShown() then return end
        for _, pin in ipairs(self.map.pins) do
            if pin:IsShown() and pin.bossLevel then
                local r, g, b = C:BossDifficultyColor(pin.bossLevel)
                pin.level:SetTextColor(r, g, b)
            end
        end
    end)
    window.message = text(window.map, 13, { .9, .8, .65 })
    window.message:SetPoint("BOTTOM", window.map, "BOTTOM", 0, 8)
    window.message:SetWidth(800)
    window.message:SetJustifyH("CENTER")
    window:Hide()
    return window
end

local function floorID(floor)
    if floor.id then return floor.id end
    local file = floor.file or ""
    if file:match("2959_2$") then return 2959002 end
    return tonumber(file:match("(%d+)$"))
end

local function drawMap(frame, floor)
    local map = frame.map
    map.art:Hide()
    for _, tile in ipairs(map.tiles) do tile:Hide() end
    if floor.file then
        map.art:SetTexture(floor.file)
        map.art:SetTexCoord(0, math.min(1, (floor.width or 1024) / (floor.fileWidth or 1024)),
            0, math.min(1, (floor.height or 683) / (floor.fileHeight or 1024)))
        map.art:Show()
        return true
    end
    local id = floorID(floor)
    if not id or not C_Map or not C_Map.GetMapArtLayers or
        not C_Map.GetMapArtLayerTextures then return false end
    local ok, layers = pcall(C_Map.GetMapArtLayers, id)
    local layer = ok and layers and layers[1]
    if not layer or not layer.layerWidth or not layer.layerHeight or
        not layer.tileWidth or not layer.tileHeight then return false end
    local got, images = pcall(C_Map.GetMapArtLayerTextures, id, 1)
    if not got or not images or #images == 0 then return false end
    local width, height = map:GetWidth(), map:GetHeight()
    local scale = math.min(width / layer.layerWidth, height / layer.layerHeight)
    local drawnWidth, drawnHeight = layer.layerWidth * scale, layer.layerHeight * scale
    local offsetX, offsetY = (width - drawnWidth) / 2, -(height - drawnHeight) / 2
    local columns = math.ceil(layer.layerWidth / layer.tileWidth)
    for index, imageID in ipairs(images) do
        local tile = map.tiles[index]
        if not tile then
            tile = map:CreateTexture(nil, "ARTWORK")
            map.tiles[index] = tile
        end
        local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", map, "TOPLEFT", offsetX + column * layer.tileWidth * scale,
            offsetY - row * layer.tileHeight * scale)
        tile:SetSize(layer.tileWidth * scale, layer.tileHeight * scale)
        tile:SetTexture(imageID)
        tile:Show()
    end
    return true
end

local function matchBoss(instanceName, npcID, pinName)
    local catalog = C.dungeonKnowledge and C.dungeonKnowledge[instanceName] or
        C.raidKnowledge and C.raidKnowledge[instanceName]
    for _, boss in ipairs(catalog and catalog.bosses or {}) do
        local meta = C:GetBossMetadata(instanceName, boss.name, npcID)
        if boss.npcID == npcID or (meta and meta[3] == npcID) or
            boss.name == pinName then return boss, meta end
    end
end

local function ensurePin(map, index)
    local pin = map.pins[index]
    if pin then return pin end
    pin = CreateFrame("Button", nil, map)
    pin:SetSize(34, 34)
    pin.ring = pin:CreateTexture(nil, "OVERLAY", nil, 1)
    pin.ring:SetPoint("CENTER")
    pin.ring:SetSize(46.5, 46.5)
    pin.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    pin.ring:SetTexCoord(0, .6, 0, .6)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetPoint("CENTER")
    pin.icon:SetSize(30, 30)
    pin.dragon = pin:CreateTexture(nil, "OVERLAY", nil, 2)
    local scale = 30 / 64
    pin.dragon:SetSize(256 * scale, 128 * scale)
    pin.dragon:SetPoint("CENTER", pin, "CENTER", -54 * scale, -20 * scale)
    if pin.CreateMaskTexture and pin.icon.AddMaskTexture then
        local iconMask = pin:CreateMaskTexture()
        iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        iconMask:SetAllPoints(pin.icon)
        pin.icon:AddMaskTexture(iconMask)
    end
    pin.badge = CreateFrame("Frame", nil, pin)
    pin.badge:SetSize(16 * 30 / 34, 16 * 30 / 34)
    pin.badge:SetPoint("CENTER", pin, "CENTER", 19.5 * scale, -22 * scale)
    pin.badge:SetFrameLevel(pin:GetFrameLevel() + 2)
    pin.badgeRing = pin.badge:CreateTexture(nil, "BORDER")
    pin.badgeRing:SetAllPoints(pin.badge)
    pin.badgeFill = pin.badge:CreateTexture(nil, "ARTWORK")
    pin.badgeFill:SetPoint("TOPLEFT", 1.5, -1.5)
    pin.badgeFill:SetPoint("BOTTOMRIGHT", -1.5, 1.5)
    pin.badgeFill:SetColorTexture(.05, .04, .03, .95)
    if pin.badge.CreateMaskTexture and pin.badgeRing.AddMaskTexture then
        for _, target in ipairs({pin.badgeRing, pin.badgeFill}) do
            local mask = pin.badge:CreateMaskTexture()
            mask:SetAllPoints(target)
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
                "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            target:AddMaskTexture(mask)
        end
    end
    pin.level = pin.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pin.level:SetPoint("CENTER", pin.badge, "CENTER", .5, 0)
    local fontFile, _, fontFlags = pin.level:GetFont()
    if fontFile then pin.level:SetFont(fontFile, 8, fontFlags) end
    pin.skull = pin.badge:CreateTexture(nil, "OVERLAY")
    pin.skull:SetSize(9, 9)
    pin.skull:SetPoint("CENTER", pin.badge, "CENTER")
    pin.skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    pin:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(C:LocalizeCatalog(self.boss.name))
        GameTooltip:AddLine(C:L("level") .. " " .. (self.bossLevel or "?"),
            1, .82, .1)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    pin:SetScript("OnClick", function(self)
        window:Hide()
        C:FocusDungeonBoss(self.instanceName, self.boss.name)
    end)
    map.pins[index] = pin
    return pin
end

function C:ShowDungeonMapWindow(instanceName, floor)
    if not floor then return end
    local frame = ensureWindow()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local width = math.min(1000, screenWidth - 100)
    local height = width * (floor.height or 683) / (floor.width or 1024)
    if height > screenHeight - 125 then
        height = screenHeight - 125
        width = height * (floor.width or 1024) / (floor.height or 683)
    end
    frame:SetSize(width + 30, height + 85)
    frame:ClearAllPoints(); frame:SetPoint("CENTER")
    frame.map:SetSize(width, height)
    local floors = self:GetDungeonMapFloors(instanceName)
    local title = self:LocalizeInstanceName(instanceName)
    if #floors > 1 and floor.name and floor.name ~= instanceName then
        title = title .. "  ·  " .. self:LocalizeCatalog(floor.name)
    end
    frame.title:SetText(title)
    frame.close.label:SetText(self:L("mapClose"))
    local hasImage = drawMap(frame, floor)
    for _, pin in ipairs(frame.map.pins) do pin:Hide() end
    local placed = 0
    -- Coordinates in the local catalog refer to its full-size image, not to
    -- arbitrary client map layers. Only show markers on that matching image.
    if floor.file then
        for _, marker in ipairs(self:GetMapBossPins(floorID(floor))) do
            local boss, meta = matchBoss(instanceName, marker[3], marker[4])
            if boss then
                placed = placed + 1
                local pin = ensurePin(frame.map, placed)
                pin.instanceName, pin.boss = instanceName, boss
                pin.bossLevel = meta and meta[1] or boss.level or marker[5]
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", frame.map, "TOPLEFT",
                    width * marker[1], -height * marker[2])
                local displayID = self:GetBossDisplayID(instanceName, boss.name) or boss.displayID
                pin.icon:SetTexCoord(0, 1, 0, 1)
                local ok = displayID and SetPortraitTextureFromCreatureDisplayID and
                    pcall(SetPortraitTextureFromCreatureDisplayID, pin.icon, displayID)
                if not ok then pin.icon:SetTexture("Interface\\AddOns\\Chronicle\\BossMedallion") end
                local rank = meta and meta[2] or (boss.rare and 2 or 1)
                pin.bossRank = rank
                if rank == 2 then
                    pin.dragon:SetTexture("Interface\\AddOns\\Chronicle\\DungeonMapArt\\BossDragon-Rare-Elite")
                    pin.ring:SetVertexColor(.85, .87, .95)
                elseif rank == 4 then
                    pin.dragon:SetTexture("Interface\\AddOns\\Chronicle\\DungeonMapArt\\BossDragon-Rare")
                    pin.ring:SetVertexColor(.85, .87, .95)
                else
                    pin.dragon:SetTexture("Interface\\AddOns\\Chronicle\\DungeonMapArt\\BossDragon-Elite")
                    pin.ring:SetVertexColor(.95, .75, .25)
                end
                pin.level:SetText(pin.bossLevel and tostring(pin.bossLevel) or "?")
                local rare = rank == 2 or rank == 4
                pin.badgeRing:SetColorTexture(rare and .85 or .95,
                    rare and .87 or .75, rare and .95 or .25, 1)
                local skull = rank == 3 or (pin.bossLevel and pin.bossLevel >= 63)
                pin.skull:SetShown(skull and true or false)
                pin.level:SetShown(not skull)
                if pin.bossLevel then pin.level:SetTextColor(self:BossDifficultyColor(pin.bossLevel))
                else pin.level:SetTextColor(.55, .55, .55) end
                pin.badge:Show()
                pin:Show()
            end
        end
    end
    frame.message:SetShown(not hasImage or placed == 0)
    frame.message:SetText(hasImage and self:L("unmappedBosses") or self:L("noEntries"))
    frame.message:SetWidth(width - 30)
    frame:Show()
end
