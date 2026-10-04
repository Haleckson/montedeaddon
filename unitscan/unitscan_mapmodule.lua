-- UnitScan Hardcore Map Module

local ALWAYS_SHOW_FOR_TESTING = false
local ICON_LIFETIME = 120
local PULSE_PERIOD = 3
local PULSE_RESTART_DELAY = 0.3
local TIMER_UPDATE_INTERVAL = 1.0
local MAP_WATCH_INTERVAL = 0.5
local COMM_PREFIX = "USHC"
local COMMS_CHANNEL_NAME = "ushccomms"
local PROX_TOLERANCE = 100.0

local ICON_TEXTURE = "Interface\\AddOns\\unitscan\\mapicon.tga"
local PULSE_TEXTURE = "Interface\\AddOns\\unitscan\\mapping.tga"

local HBD = LibStub and LibStub:GetLibrary("HereBeDragons-2.0", true)
local HBDPins = LibStub and LibStub:GetLibrary("HereBeDragons-Pins-2.0", true)
if not HBD then
    return
end

USHCMapSettings = USHCMapSettings or { Enabled = true }

local mapModule = {}
mapModule.icons = {}
mapModule._nextUid = mapModule._nextUid or 0 -- duplicate
mapModule.playerLayer = tonumber(_G["NWB_CurrentLayer"]) or 0
mapModule.displayedMapID = nil

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64_decode(data)
    if not data or data == '' then return '' end
    local rev = {}
    for i = 1, #b64chars do rev[b64chars:sub(i,i)] = i - 1 end
    local out = {}
    local len = #data
    local i = 1
    while i <= len do
        local c1 = data:sub(i, i)
        local c2 = data:sub(i+1, i+1)
        local c3 = data:sub(i+2, i+2)
        local c4 = data:sub(i+3, i+3)
        local v1 = rev[c1] or 0
        local v2 = rev[c2] or 0
        local v3 = rev[c3] or 0
        local v4 = rev[c4] or 0
        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
        local byte1 = math.floor(n / 65536) % 256
        local byte2 = math.floor(n / 256) % 256
        local byte3 = n % 256
        if c3 == '=' and c4 == '=' then
            table.insert(out, string.char(byte1))
        elseif c4 == '=' then
            table.insert(out, string.char(byte1))
            table.insert(out, string.char(byte2))
        else
            table.insert(out, string.char(byte1))
            table.insert(out, string.char(byte2))
            table.insert(out, string.char(byte3))
        end
        i = i + 4
    end
    return table.concat(out)
end

local function getPlayerLayer()
    return tonumber(_G["NWB_CurrentLayer"]) or 0
end

local function formattedKeyId(unitKey, mapID, layer)
    return strupper(tostring(unitKey)) .. '|' .. tostring(mapID) .. '|' .. tostring(layer)
end

local function isZoneMapDisplayed()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return false end
    local displayedMapID = WorldMapFrame:GetMapID()
    if not displayedMapID or displayedMapID == 0 then return false end
    local ok, w, h = pcall(function() return HBD:GetZoneSize(displayedMapID) end)
    if not ok or not w or not h then return false end
    return (type(w) == "number" and type(h) == "number" and w > 0 and h > 0)
end

local function isUnitTracked(keyU, recvMapID)
    if ALWAYS_SHOW_FOR_TESTING then
        return true
    end

    -- primary memory table
    if type(unitscan_targets) == "table" and unitscan_targets[keyU] then
        return true
    end

    -- fallback to gridstate
    -- safeguard(dont fuck this)
    if type(REGIONS_TABLE) ~= "table" or type(CHECKBOX_GRID_STATE) ~= "table" then
        return false
    end

    local mapnum = tonumber(recvMapID) or nil
    if not mapnum then return false end

    local zoneName = REGIONS_TABLE[mapnum]
    if not zoneName then return false end

    local zoneEntries = CHECKBOX_GRID_STATE[zoneName]
    if type(zoneEntries) ~= "table" then return false end

    -- iterate match entry
    for _, entry in ipairs(zoneEntries) do
        if entry and entry.text and entry.check then
            if strupper(tostring(entry.text)) == keyU then
                -- entry.check
                return true
            end
        end
    end

    return false
end

local function convertToWorld(mapID, xi, yi)
    if not mapID then return nil end
    local zx = (xi or 0) / 1000
    local zy = (yi or 0) / 1000
    local ok, wx, wy, instance = pcall(function() return HBD:GetWorldCoordinatesFromZone(zx, zy, tonumber(mapID)) end)
    if not ok then return nil, nil, nil, zx, zy end
    if not wx or not wy then return nil, nil, instance, zx, zy end
    return wx, wy, instance, zx, zy
end

local function createSinglePulseAnimation(tex)
    if not tex then return nil end
    local ag = tex:CreateAnimationGroup()
    ag:SetLooping("NONE")
    local scale = ag:CreateAnimation("Scale")
    scale:SetScale(2.8, 2.8)
    scale:SetDuration(PULSE_PERIOD)
    scale:SetOrder(1)
    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.9)
    alpha:SetToAlpha(0.0)
    alpha:SetDuration(PULSE_PERIOD)
    alpha:SetOrder(1)
    return ag
end

local function playPulseWithDelay(tex, ag)
    if not tex or not ag then return end
    tex:SetSize(tex._baseSize or 32, tex._baseSize or 32)
    tex:SetAlpha(0.0)
    pcall(function() ag:Stop() end)
    C_Timer.After(0.001, function()
        if not tex then return end
        tex:SetAlpha(0.9)
        pcall(function() ag:Play() end)
    end)
    ag:SetScript("OnFinished", function()
        if not tex then return end
        tex:SetAlpha(0.0)
        tex:SetSize(tex._baseSize or 32, tex._baseSize or 32)
        C_Timer.After(PULSE_RESTART_DELAY, function()
            if tex and ag and tex:IsShown() then playPulseWithDelay(tex, ag) end
        end)
    end)
end

local function hbd_add_pin_bestEffort(frame, uiMapID, wx, wy, instance, zx, zy, silent)
	-- prevent different layer
	-- remove HBD
	if not ALWAYS_SHOW_FOR_TESTING and frame and frame.layer and tonumber(frame.layer) and tonumber(frame.layer) ~= getPlayerLayer() then
		if HBDPins then
			pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, frame) end)
		end
		return false
	end
	
    if not HBDPins then
        if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00UnitScanHardcore: HBD-Pins missing.|r") end
        return false
    end

    -- zone map coords
    local useZx, useZy = zx, zy
	if (not useZx or not useZy) and frame and frame.lastXi and frame.lastYi then
		useZx = (frame.lastXi or 0) / 1000
		useZy = (frame.lastYi or 0) / 1000
	end
	if uiMapID and useZx and useZy then
		local ok2, err2 = pcall(function()
			HBDPins:AddWorldMapIconMap(mapModule, frame, tonumber(uiMapID), useZx, useZy, nil)
		end)
		if ok2 then
			if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00UnitScanHardcore: AddWorldMapIconMap succeeded for "..tostring(frame.keyU).." (map "..tostring(uiMapID)..").|r") end
			return true
		else
			if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000UnitScanHardcore: AddWorldMapIconMap failed: "..tostring(err2).."|r") end
			-- fall through
		end
	end
	
	-- Fallback
	if wx and wy and instance and (type(instance) == "number") then
		local ok, err = pcall(function()
			HBDPins:AddWorldMapIconWorld(mapModule, frame, instance, wx, wy, nil)
		end)
		if ok then
			if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00UnitScanHardcore: AddWorldMapIconWorld succeeded for "..tostring(frame.keyU).." (instance "..tostring(instance)..").|r") end
			return true
		else
			if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000UnitScanHardcore: AddWorldMapIconWorld failed: "..tostring(err).."|r") end
		end
	end

    -- Fallback AddWorldMapIconMap
    local useZx, useZy = zx, zy
    if (not useZx or not useZy) and frame.lastXi and frame.lastYi then
        useZx = (frame.lastXi or 0) / 1000
        useZy = (frame.lastYi or 0) / 1000
    end
    if uiMapID and useZx and useZy then
        local ok2, err2 = pcall(function()
            HBDPins:AddWorldMapIconMap(mapModule, frame, tonumber(uiMapID), useZx, useZy, nil)
        end)
        if ok2 then
            if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00UnitScanHardcore: AddWorldMapIconMap succeeded for "..tostring(frame.keyU).." (map "..tostring(uiMapID)..").|r") end
            return true
        else
            if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000UnitScanHardcore: AddWorldMapIconMap failed: "..tostring(err2).."|r") end
        end
    end

    if not silent then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000UnitScanHardcore: HBD-Pins could not register pin for "..tostring(frame.keyU).." (mapID="..tostring(uiMapID)..").|r") end
    return false
end

local function hbd_remove_pin(frame)
    if not HBDPins or not frame then return end
    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, frame) end)
end

local function positionFrameOnWorldMapFallback(frame)
    return -- no
end

local function createMapIcon(keyU, mapID, layer, worldX, worldY, recvXi, recvYi, instance, zx, zy)
	local baseId = formattedKeyId(keyU, mapID, layer)
	local id = baseId
	-- id
	if mapModule.icons[id] then
		mapModule._nextUid = (mapModule._nextUid or 0) + 1
		id = id .. '|' .. tostring(mapModule._nextUid)
	end
	local frameName = "USHCMapIcon_" .. id:gsub("[^%w]","_")
	local f = CreateFrame("Frame", frameName, UIParent)
    f:SetSize(64, 64)
    f:SetFrameStrata("HIGH")
    f.keyU = keyU
    f.mapID = tonumber(mapID)
    f.layer = tonumber(layer)
    f.worldX = worldX
    f.worldY = worldY
    f._instanceID = instance
    f.lastSeen = GetTime()
    f._needsReposition = true
    f.lastXi = recvXi
    f.lastYi = recvYi
    f._hiddenByToggle = false
    f._hiddenByLayer = false

    f.members = {}
    f.members[keyU] = { lastSeen = f.lastSeen, xi = recvXi, yi = recvYi, wx = worldX, wy = worldY, zx = zx, zy = zy, layer = tonumber(layer) }

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetSize((_G.LeaMapsDB and 25 or 19), (_G.LeaMapsDB and 25 or 19))
    icon:SetPoint("CENTER", 0, 0)
    f.icon = icon

    local nameFS = f:CreateFontString(nil, "OVERLAY")
    local font, fontSize = GameFontNormal:GetFont()
    if font then nameFS:SetFont(font, (_G.LeaMapsDB and 8.5 or 7), "THICKOUTLINE") end
    nameFS:SetPoint("BOTTOM", icon, "TOP", 0, 8)
    nameFS:SetText("|cFFFF0000" .. keyU .. "|r")
    f.nameFS = nameFS

    local timerFS = f:CreateFontString(nil, "OVERLAY")
    if font then timerFS:SetFont(font, (_G.LeaMapsDB and 9 or 7), "THICKOUTLINE") end
    timerFS:SetPoint("TOP", icon, "BOTTOM", 0, -8)
    timerFS:SetText("last seen: 0s ago")
	timerFS:SetTextColor(1, 1, 0) -- RGB: yellow
    f.timerFS = timerFS

    local basePulseSize = (_G.LeaMapsDB and 25 or 19)
    local pulse = f:CreateTexture(nil, "ARTWORK")
    pulse:SetTexture(PULSE_TEXTURE)
    pulse:SetBlendMode("ADD")
    pulse._baseSize = basePulseSize
    pulse:SetSize(basePulseSize, basePulseSize)
    pulse:SetPoint("CENTER", icon, "CENTER", 0, 0)
    pulse:SetAlpha(0.0)
    f.pulse = pulse
    f._pulseAnim = createSinglePulseAnimation(pulse)
    playPulseWithDelay(pulse, f._pulseAnim)

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cFFFFFF00UnitScan Hardcore|r")
        local count = 0
        for _ in pairs(self.members) do count = count + 1 end
        if count > 1 then
            GameTooltip:AddLine("Multiple Elites detected here:", 1,1,1)
            for name, meta in pairs(self.members) do
                local age = math.floor(GetTime() - (meta.lastSeen or 0) + 0.5)
                GameTooltip:AddLine(("|cFFFF0000%s|r - Layer: %s - last seen: %ds"):format(name, tostring(meta.layer or self.layer), age), 0.9, 0.9, 0.9, true)
            end
        else
            for name, meta in pairs(self.members) do
                local age = math.floor(GetTime() - (meta.lastSeen or 0) + 0.5)
                GameTooltip:AddLine(("|cFFFF0000%s|r - Layer: %s - last seen: %ds"):format(name, tostring(meta.layer or self.layer), age), 1,1,1, true)
            end
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f._hbd_added = false
    -- Register HBD pin
    if HBDPins and USHCMapSettings.Enabled then
        local ok = hbd_add_pin_bestEffort(f, f.mapID, f.worldX, f.worldY, instance, zx, zy, true) -- silent
        f._hbd_added = ok
    else
        f._hbd_added = false
    end

    mapModule.icons[id] = f
    return f
end

local function removeMapIconById(id)
    local f = mapModule.icons[id]
    if not f then return end

    if f._pulseAnim then
        pcall(function() f._pulseAnim:Stop() end)
    end

    if HBDPins then
        pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
    end

    pcall(function()
        f:Hide()
        f:UnregisterAllEvents()
        f:SetScript("OnUpdate", nil)
        f:SetScript("OnEnter", nil)
        f:SetScript("OnLeave", nil)
        f:ClearAllPoints()
    end)

    f.members = nil
    mapModule.icons[id] = nil
end

local function computeAverageWorldForMembers(members)
    local sx, sy, n = 0, 0, 0
    for _, meta in pairs(members) do
        if meta.wx and meta.wy then
            sx = sx + meta.wx
            sy = sy + meta.wy
            n = n + 1
        end
    end
    if n == 0 then return nil, nil end
    return sx / n, sy / n
end

local function computeAverageZoneForMembers(members)
    local sx, sy, n = 0, 0, 0
    for _, meta in pairs(members) do
        if meta.zx and meta.zy then
            sx = sx + meta.zx
            sy = sy + meta.zy
            n = n + 1
        elseif meta.xi and meta.yi then
            -- xi/yi normal
            sx = sx + ((meta.xi or 0) / 1000)
            sy = sy + ((meta.yi or 0) / 1000)
            n = n + 1
        end
    end
    if n == 0 then return nil, nil end
    return sx / n, sy / n
end

local function addOrUpdateHbdPinWithAverage(f)
    if not f or not HBDPins then return false end

    local avgZx, avgZy = computeAverageZoneForMembers(f.members)
    if avgZx and avgZy then
        -- keep lastXi/lastYi consistent
        f.lastXi = math.floor((avgZx * 1000) + 0.5)
        f.lastYi = math.floor((avgZy * 1000) + 0.5)

        -- resolve world coords
        local ok, wx, wy, instance = pcall(function()
            return HBD:GetWorldCoordinatesFromZone(avgZx, avgZy, tonumber(f.mapID))
        end)
        if ok and wx and wy then
            f.worldX = wx; f.worldY = wy
            if instance then f._instanceID = instance end
        end

        -- add HBD
        pcall(function()
            HBDPins:AddWorldMapIconMap(mapModule, f, tonumber(f.mapID), avgZx, avgZy, nil)
        end)
        return true
    else
        -- fallback
        pcall(function()
            HBDPins:AddWorldMapIconMap(mapModule, f, tonumber(f.mapID),
                ((f.lastXi or 0) / 1000),
                ((f.lastYi or 0) / 1000),
                nil)
        end)
        return false
    end
end

local function ensureHbdPinForFrame(f)
    if not f or not HBDPins or not USHCMapSettings.Enabled then return false end
    if not (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
        return false
    end

    -- averaged coords
    local ok = false
    pcall(function()
        ok = addOrUpdateHbdPinWithAverage(f) or false
    end)
    if ok then
        f._hbd_added = true
        f._needsReposition = nil
        return true
    end

    -- bestEffort
    local ok2 = false
    pcall(function()
        ok2 = hbd_add_pin_bestEffort(f, f.mapID, f.worldX, f.worldY, f._instanceID, nil, nil, true) or false
    end)
    if ok2 then
        f._hbd_added = true
        f._needsReposition = nil
        return true
    end

    return false
end

local function addOrUpdateMemberToFrame(f, keyU, recvXi, recvYi, wx, wy, layer, zx, zy, instance)
    local now = GetTime()
    if not f.members then f.members = {} end
    local existing = f.members[keyU]
    if existing then
        existing.lastSeen = now
		existing.zx = zx; existing.zy = zy
        existing.xi = recvXi; existing.yi = recvYi
        existing.wx = wx; existing.wy = wy
        existing.layer = tonumber(layer) or existing.layer
    else
        f.members[keyU] = { lastSeen = now, xi = recvXi, yi = recvYi, wx = wx, wy = wy, zx = zx, zy = zy, layer = tonumber(layer) }
    end

    local avgWx, avgWy = computeAverageWorldForMembers(f.members)
    if avgWx and avgWy then f.worldX = avgWx; f.worldY = avgWy end
    f._instanceID = instance or f._instanceID
    f.lastSeen = now; f.lastXi = recvXi; f.lastYi = recvYi; f._needsReposition = true

    local count = 0
    for name in pairs(f.members) do count = count + 1 end
    if count > 1 then
        f._isMultiple = true
        f.nameFS:SetText("|cFFFF0000Multiple Elites|r")
    else
        f._isMultiple = false
        for name in pairs(f.members) do f.nameFS:SetText("|cFFFF0000" .. name .. "|r") end
    end

    -- Update HBD
    if HBDPins and f._hbd_added then
        pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
        local added = hbd_add_pin_bestEffort(f, f.mapID, f.worldX, f.worldY, f._instanceID, zx, zy, true) -- silent
        f._hbd_added = added
        f._needsReposition = nil
    end
end

local function findNearbyFrame(recvMapID, recvLayer, recvXi, recvYi)
    if not recvMapID or not recvLayer or not recvXi or not recvYi then return nil end
    for id, f in pairs(mapModule.icons) do
        if f.mapID == tonumber(recvMapID) and f.layer == tonumber(recvLayer) then
            if f.lastXi and f.lastYi then
                if math.abs((f.lastXi or 0) - recvXi) <= PROX_TOLERANCE and math.abs((f.lastYi or 0) - recvYi) <= PROX_TOLERANCE then
                    return f
                end
            end
        end
    end
    return nil
end

local function upsertIconFromMessage(keyRaw, recvMapID, recvXi, recvYi, recvLayer)
    if not keyRaw or not recvMapID or not recvXi or not recvYi or not recvLayer then return nil end
    local keyU = strupper(tostring(keyRaw))
    -- decide packet rejection
    if not isUnitTracked(keyU, recvMapID) then return nil end

    local wx, wy, instance, zx, zy = convertToWorld(recvMapID, recvXi, recvYi)
    if not wx or not wy then
        if not zx then return nil end
    end

    local nearby = findNearbyFrame(recvMapID, recvLayer, recvXi, recvYi)
    if nearby then
        addOrUpdateMemberToFrame(nearby, keyU, recvXi, recvYi, wx, wy, recvLayer, zx, zy, instance)
        return nearby
    end

    local id = formattedKeyId(keyU, recvMapID, recvLayer)
    local f = createMapIcon(keyU, recvMapID, recvLayer, wx, wy, recvXi, recvYi, instance, zx, zy)
    f._needsReposition = true
	
	-- immediate consolidation
	--pcall
	
    return f
end

local managerFrame = CreateFrame("Frame", "USHCMapManager", UIParent)
managerFrame.elapsed = 0
managerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < TIMER_UPDATE_INTERVAL then return end
    self.elapsed = 0
	
	-- reconcile layer visibility
	pcall(updateLayerVisibility)

    local now = GetTime()
    local toRemove = {}

    for id, f in pairs(mapModule.icons) do
        if not f or not f.lastSeen then
            toRemove[#toRemove+1] = id
        else
            local memberCount = 0
            for name, meta in pairs(f.members) do
                local age = now - (meta.lastSeen or 0)
                if age > ICON_LIFETIME then
                    f.members[name] = nil
                else
                    memberCount = memberCount + 1
                end
            end

            if memberCount == 0 then
                toRemove[#toRemove+1] = id
            else
                local newest = 0
                for _, meta in pairs(f.members) do if meta.lastSeen and meta.lastSeen > newest then newest = meta.lastSeen end end
                f.lastSeen = newest

                if memberCount > 1 then
                    f._isMultiple = true
                    f.nameFS:SetText("|cFFFF0000Multiple Elites|r")
                else
                    f._isMultiple = false
                    for name,_ in pairs(f.members) do f.nameFS:SetText("|cFFFF0000" .. name .. "|r") end
                end

                local secs = math.floor(now - f.lastSeen + 0.5)
                f.timerFS:SetText(("last seen: %ds ago"):format(secs))

                if f._needsReposition then
                    -- ensure pin
                    if HBDPins and not f._hbd_added then
                        -- layer match
                        if ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer() then
                            pcall(function() ensureHbdPinForFrame(f) end)
                            -- clear
                            if f._hbd_added then
                                f._needsReposition = nil
                            else
                                -- leave _needsReposition
                            end
                        end
                    end

                    -- re-add
                    if HBDPins and f._hbd_added then
                        pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
                        pcall(function() addOrUpdateHbdPinWithAverage(f) end)
                        f._hbd_added = true
                        f._needsReposition = nil
                    else
                        -- disabled fb
                        positionFrameOnWorldMapFallback(f)
                    end
                end
            end
        end
    end

    for _, id in ipairs(toRemove) do
        removeMapIconById(id)
    end
end)
managerFrame:Show()

local function markAllNeedsReposition()
    for id, f in pairs(mapModule.icons) do if f then f._needsReposition = true end end
end

local function updateLayerVisibility()
    local newLayer = getPlayerLayer()
    --leave this disabled
    mapModule.playerLayer = newLayer

    for id, f in pairs(mapModule.icons) do
        if not ALWAYS_SHOW_FOR_TESTING then
            if f.layer == newLayer then
                f._hiddenByLayer = false
                f._needsReposition = true
                if USHCMapSettings.Enabled then f:Show() end
                -- register HBD pin on match
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added then
                    pcall(function() ensureHbdPinForFrame(f) end)
                end
            else
                f._hiddenByLayer = true
				-- remove any existing
				if f._hbd_added and HBDPins then
					pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
					f._hbd_added = false
				end
                f:Hide()
            end
        else
            f._hiddenByLayer = false
            f._needsReposition = true
            if USHCMapSettings.Enabled then f:Show() end
        end
    end
end

local function applyGlobalVisibility()
    if USHCMapSettings.Enabled then
        -- show frames
        for id, f in pairs(mapModule.icons) do
            f._hiddenByToggle = false
            -- silent add
            if HBDPins and not f._hbd_added then
                pcall(function() hbd_add_pin_bestEffort(f, f.mapID, f.worldX, f.worldY, f._instanceID, nil, nil, true) end)
                -- leave f._hbd_added
            end
            -- respect filters
            if ALWAYS_SHOW_FOR_TESTING or (getPlayerLayer() == f.layer) then
                if not f._hiddenByLayer then f:Show() end
            else
                f:Hide()
            end
            f._needsReposition = true
        end
    else
        -- user disabled
        for id, f in pairs(mapModule.icons) do
            f._hiddenByToggle = true
            -- remove existing
            if HBDPins and f._hbd_added then
                pcall(function() hbd_remove_pin(f) end)
                f._hbd_added = false
            end
            -- hide frame
            f:Hide()
        end
    end
end

local function createTopCheckbox()
    if not WorldMapFrame then return end
    if _G["USHCMapToggleCheckbox"] then return end

    local cbParent = WorldMapFrame
    local cb = CreateFrame("CheckButton", "USHCMapToggleCheckbox", cbParent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("BOTTOM", cbParent, "BOTTOM", (_G.LeaMapsDB and -120 or -120), (_G.LeaMapsDB and 23 or 6))
    cb:SetHitRectInsets(-200, -200, -6, 0)     -- expand maybe later
    cb:SetSize(24, 24)
	
	cb:SetFrameStrata("FULLSCREEN_DIALOG")
	cb:SetFrameLevel(500)

    -- icon
    local icon = cb:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetSize(20, 20)
    icon:SetPoint("RIGHT", cb, "LEFT", -8, 0)

    cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    cb.text:SetText("UnitScan Hardcore Real Time Map Tracking")
    cb.tooltipText = "Toggle UnitScan Hardcore icon display on the World Map"
	
	-- NWB check
	if not (NWB_CurrentLayer) then icon:Hide(); cb.text:Hide(); cb:Hide() end

    cb:SetScript("OnClick", function(self)
        USHCMapSettings.Enabled = self:GetChecked() and true or false
        applyGlobalVisibility()
    end)

    cb:SetChecked(USHCMapSettings.Enabled)
    if NWB_CurrentLayer then cb:Show() end
end

if WorldMapFrame then
    createTopCheckbox()
else
    local late = CreateFrame("Frame")
    late:RegisterEvent("PLAYER_ENTERING_WORLD")
    late:SetScript("OnEvent", function()
        createTopCheckbox()
        late:UnregisterAllEvents()
    end)
end

local mapWatcher = CreateFrame("Frame")
mapWatcher.elapsed = 0
mapWatcher:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < MAP_WATCH_INTERVAL then return end
    self.elapsed = 0

    local current = nil
    if WorldMapFrame and WorldMapFrame:IsShown() then current = WorldMapFrame:GetMapID() end

    if current ~= mapModule.displayedMapID then
        mapModule.displayedMapID = current
        markAllNeedsReposition()
        for id, f in pairs(mapModule.icons) do
            f._needsReposition = true
            if f._needsReposition then
                -- ensure HBD registration
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added and (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
                    pcall(function() ensureHbdPinForFrame(f) end)
                    f._needsReposition = nil
                elseif HBDPins and f._hbd_added and USHCMapSettings.Enabled then
                    -- averaged zone coords
                    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
                    pcall(function() addOrUpdateHbdPinWithAverage(f) end)
                    f._needsReposition = nil
                else
                    positionFrameOnWorldMapFallback(f)
                end
            end
        end
    end
end)
mapWatcher:Show()

if WorldMapFrame and WorldMapFrame.ScrollContainer then
    local sc = WorldMapFrame.ScrollContainer
    sc:HookScript("OnSizeChanged", function()
        markAllNeedsReposition()
        for _, f in pairs(mapModule.icons) do
            if f._needsReposition then
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added and (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
                    pcall(function() ensureHbdPinForFrame(f) end)
                    f._needsReposition = nil
                elseif HBDPins and f._hbd_added and USHCMapSettings.Enabled then
                    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
                    pcall(function() addOrUpdateHbdPinWithAverage(f) end)
                    f._needsReposition = nil
                else
                    positionFrameOnWorldMapFallback(f)
                end
            end
        end
    end)
    sc:HookScript("OnScrollRangeChanged", function()
        markAllNeedsReposition()
        for _, f in pairs(mapModule.icons) do
            if f._needsReposition then
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added and (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
                    pcall(function() ensureHbdPinForFrame(f) end)
                    f._needsReposition = nil
                elseif HBDPins and f._hbd_added and USHCMapSettings.Enabled then
                    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
                    pcall(function() addOrUpdateHbdPinWithAverage(f) end)
                    f._needsReposition = nil
                else
                    positionFrameOnWorldMapFallback(f)
                end
            end
        end
    end)
end

if WorldMapFrame then
    WorldMapFrame:HookScript("OnShow", function()
        createTopCheckbox()
		local cb = _G["USHCMapToggleCheckbox"]
		if cb then cb:SetChecked(USHCMapSettings.Enabled) end
        markAllNeedsReposition()
        for _, f in pairs(mapModule.icons) do
            if f._needsReposition then
                -- map stable, show
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added and (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
                    pcall(function() ensureHbdPinForFrame(f) end)
                    f._needsReposition = nil
                elseif HBDPins and f._hbd_added and USHCMapSettings.Enabled then
                    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
					local avgZx, avgZy = computeAverageZoneForMembers(f.members)
					pcall(function()
						HBDPins:AddWorldMapIconMap(mapModule, f, tonumber(f.mapID),
							avgZx or ((f.lastXi or 0) / 1000),
							avgZy or ((f.lastYi or 0) / 1000),
							nil)
					end)
					f._needsReposition = nil
                else
                    positionFrameOnWorldMapFallback(f)
                end
            end
            -- show/hide
            if USHCMapSettings.Enabled and not f._hiddenByToggle and not f._hiddenByLayer and (ALWAYS_SHOW_FOR_TESTING or getPlayerLayer() == f.layer) then
                f:Show()
            else
                f:Hide()
            end
        end
    end)
    WorldMapFrame:HookScript("OnHide", function()
        for _, f in pairs(mapModule.icons) do
            -- do NOT remove HBD
            f:Hide()
        end
    end)
end

local ev = CreateFrame("Frame", "USHCMapModuleEvents")
ev:RegisterEvent("CHAT_MSG_CHANNEL")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
    if event == "CHAT_MSG_CHANNEL" and arg1 then
        local message = arg1; local channelName = arg4
        if channelName and type(channelName) == "string" then
            local lname = strlower(channelName); local lcomm = strlower(COMMS_CHANNEL_NAME or "")
            if lname:find(lcomm, 1, true) then
                local pattern = '^' .. COMM_PREFIX .. '%s*(.*)$'
                local trimmed = nil; pcall(function() trimmed = message:match(pattern) end)
                if not trimmed or trimmed == "" then
                    local b64match = message:match('[Bb]64:([A-Za-z0-9%+/%=]+)')
                    if b64match then trimmed = 'B64:' .. b64match else trimmed = nil end
                end
                if trimmed and trimmed ~= '' then
                    local b64payload = trimmed:match('^%s*[Bb]64:(.+)$')
                    if b64payload then
                        local decoded = b64_decode(b64payload)
                        if decoded and decoded ~= '' then
                            local key, fld2, fld3, fld4, fld5 = strsplit("|", decoded, 5)
                            local recvMapID = tonumber(fld2) or 0
                            local recvXi = tonumber(fld3)
                            local recvYi = tonumber(fld4)
                            local recvLayer = tonumber(fld5) or 0
                            if key and recvMapID and recvXi and recvYi and recvLayer then
                                local keyU = strupper(tostring(key))
                                -- use helper
                                if isUnitTracked(keyU, recvMapID) then
                                    upsertIconFromMessage(key, recvMapID, recvXi, recvYi, recvLayer)
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" then -- delay
			-- tolerance delay for NWB
			C_Timer.After(10, updateLayerVisibility)
		else
			-- autism delay
			C_Timer.After(0.5, updateLayerVisibility)
		end
        markAllNeedsReposition()
        for _, f in pairs(mapModule.icons) do
            if f._needsReposition then
                -- ensure HBD
                if HBDPins and USHCMapSettings.Enabled and not f._hbd_added and (ALWAYS_SHOW_FOR_TESTING or tonumber(f.layer) == getPlayerLayer()) then
                    pcall(function() ensureHbdPinForFrame(f) end)
                    f._needsReposition = nil
                elseif HBDPins and f._hbd_added and USHCMapSettings.Enabled then
                    pcall(function() HBDPins:RemoveWorldMapIcon(mapModule, f) end)
                    local avgZx, avgZy = computeAverageZoneForMembers(f.members)
					pcall(function()
						HBDPins:AddWorldMapIconMap(mapModule, f, tonumber(f.mapID),
							avgZx or ((f.lastXi or 0) / 1000),
							avgZy or ((f.lastYi or 0) / 1000),
							nil)
					end)
                    f._needsReposition = nil
                else
                    positionFrameOnWorldMapFallback(f)
                end
            end
            -- do NOT recreate
            if USHCMapSettings.Enabled and (ALWAYS_SHOW_FOR_TESTING or getPlayerLayer() == f.layer) and not f._hiddenByLayer then
                f:Show()
            else
                f:Hide()
            end
        end
    end
end)

_G["USHCMapModule"] = {
    Upsert = upsertIconFromMessage,
    RemoveByKey = function(keyU, mapID, layer) for id,_ in pairs(mapModule.icons) do if id:sub(1, #(formattedKeyId(keyU,mapID,layer))) == formattedKeyId(keyU,mapID,layer) then removeMapIconById(id) end end end,
    RemoveAll = function() for id,_ in pairs(mapModule.icons) do removeMapIconById(id) end end,
    SetTesting = function(v) ALWAYS_SHOW_FOR_TESTING = not not v; updateLayerVisibility(); markAllNeedsReposition() end,
}

mapModule.playerLayer = getPlayerLayer()
mapModule.displayedMapID = (WorldMapFrame and WorldMapFrame:IsShown()) and WorldMapFrame:GetMapID() or nil
applyGlobalVisibility()
local cb = _G["USHCMapToggleCheckbox"]
if cb then cb:SetChecked(USHCMapSettings.Enabled) end
