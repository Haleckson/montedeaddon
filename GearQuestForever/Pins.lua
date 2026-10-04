local _, GQ = ...

GQ.Pins = GQ.Pins or {}

local ICONS = {
    q = "Interface\\GossipFrame\\AvailableQuestIcon",
    b = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    p = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
    v = "Interface\\GossipFrame\\VendorIcon",
    w = "Interface\\Icons\\INV_Misc_Map_01",
}
local AREA_TEXTURE = "Interface\\Minimap\\UI-Minimap-Ping-Center"
local AREA_COLOR = { 0.3, 0.55, 1, 0.35 }
local UPDATE_INTERVAL = 0.05
local WORLD_PIN_SIZE = 24
local MINI_PIN_SIZE = 18
local EDGE_LIMIT_SQ = 0.92 * 0.92

local pins = {}
local selectedEntryId
local driver
local worldPool = {}
local miniPool = {}
local worldArea
local miniArea
local spanCache = {}
local elapsedAcc = 0
local poolsActive = true

local function MapSpans(mapId)
    local cached = spanCache[mapId]
    if cached then
        return cached[1], cached[2]
    end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return 0, 0
    end
    local _, topLeft = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(0, 0))
    local _, bottomRight = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(1, 1))
    if not (topLeft and bottomRight) then
        return 0, 0
    end
    local spanX = math.abs(bottomRight.x - topLeft.x)
    local spanY = math.abs(bottomRight.y - topLeft.y)
    spanCache[mapId] = { spanX, spanY }
    return spanX, spanY
end

local function ShowPinTooltip(frame)
    local pin = frame.pinData
    if not pin or not pin.entry then
        return
    end
    local entry = pin.entry
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local name = GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)
    GameTooltip:AddLine(name or ("Item " .. tostring(entry.itemId)), 1, 0.82, 0)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(pin.mapId)
    local zone = pin.map or (info and info.name) or entry.zone or ""
    if zone ~= "" then
        GameTooltip:AddLine(string.format("%s %.1f, %.1f", zone, pin.x, pin.y), 0.6, 0.8, 1)
    end
    GameTooltip:Show()
end

local function ToggleArea(frame)
    local pin = frame.pinData
    if not pin or not pin.entry then
        return
    end
    if selectedEntryId == pin.entry.id then
        selectedEntryId = nil
    else
        selectedEntryId = pin.entry.id
    end
end

local function WirePin(frame)
    frame:SetScript("OnEnter", ShowPinTooltip)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnClick", function(self)
        ToggleArea(self)
    end)
    return frame
end

local function EnsureWorldPin(index)
    local frame = worldPool[index]
    if frame then
        return frame
    end
    local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    if not canvas then
        return nil
    end
    frame = CreateFrame("Button", nil, canvas)
    frame:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    frame:SetFrameStrata(canvas:GetFrameStrata() or "HIGH")
    frame:SetFrameLevel((canvas:GetFrameLevel() or 1) + 5)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    WirePin(frame)
    frame:Hide()
    worldPool[index] = frame
    return frame
end

local function EnsureWorldArea(canvas)
    if worldArea and worldArea:GetParent() == canvas then
        return worldArea
    end
    worldArea = CreateFrame("Frame", nil, canvas)
    worldArea:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    worldArea:SetFrameStrata(canvas:GetFrameStrata() or "HIGH")
    worldArea:SetFrameLevel((canvas:GetFrameLevel() or 1) + 2)
    worldArea.tex = worldArea:CreateTexture(nil, "ARTWORK")
    worldArea.tex:SetTexture(AREA_TEXTURE)
    worldArea.tex:SetAllPoints()
    worldArea.tex:SetVertexColor(AREA_COLOR[1], AREA_COLOR[2], AREA_COLOR[3], AREA_COLOR[4])
    worldArea:EnableMouse(false)
    worldArea:Hide()
    return worldArea
end

local function HideWorldPins()
    for _, frame in ipairs(worldPool) do
        frame:Hide()
    end
    if worldArea then
        worldArea:Hide()
    end
end

local function UpdateWorldMap()
    local mapId = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    if not (WorldMapFrame and WorldMapFrame:IsShown() and mapId and canvas) then
        HideWorldPins()
        return
    end
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    if width <= 0 or height <= 0 then
        HideWorldPins()
        return
    end

    local used = 0
    for _, pin in ipairs(pins) do
        if pin.mapId == mapId then
            used = used + 1
            local frame = EnsureWorldPin(used)
            if not frame then
                break
            end
            local nx, ny = pin.x / 100, pin.y / 100
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", canvas, "TOPLEFT", nx * width, -ny * height)
            local texture = ICONS[pin.kind] or ICONS.w
            if frame.lastTexture ~= texture then
                frame.lastTexture = texture
                frame.icon:SetTexture(texture)
            end
            frame.pinData = pin
            frame:Show()
        end
    end
    for index = used + 1, #worldPool do
        worldPool[index]:Hide()
    end

    local area = EnsureWorldArea(canvas)
    local selected
    if selectedEntryId then
        for _, pin in ipairs(pins) do
            if pin.entry and pin.entry.id == selectedEntryId and pin.mapId == mapId then
                selected = pin
                break
            end
        end
    end
    if not selected then
        area:Hide()
        return
    end
    area:ClearAllPoints()
    area:SetPoint("CENTER", canvas, "TOPLEFT", selected.x / 100 * width, -selected.y / 100 * height)
    area:SetSize(math.max(width * 0.08, 64), math.max(height * 0.08, 64))
    area:Show()
end

local function EnsureMiniPin(index)
    local frame = miniPool[index]
    if frame then
        return frame
    end
    frame = CreateFrame("Button", nil, Minimap)
    frame:SetSize(MINI_PIN_SIZE, MINI_PIN_SIZE)
    frame:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    WirePin(frame)
    frame:Hide()
    miniPool[index] = frame
    return frame
end

local function EnsureMiniArea()
    if miniArea then
        return miniArea
    end
    miniArea = CreateFrame("Frame", nil, Minimap)
    miniArea:SetSize(MINI_PIN_SIZE, MINI_PIN_SIZE)
    miniArea:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 2)
    miniArea.tex = miniArea:CreateTexture(nil, "ARTWORK")
    miniArea.tex:SetTexture(AREA_TEXTURE)
    miniArea.tex:SetAllPoints()
    miniArea.tex:SetVertexColor(AREA_COLOR[1], AREA_COLOR[2], AREA_COLOR[3], AREA_COLOR[4])
    miniArea:EnableMouse(false)
    miniArea:Hide()
    return miniArea
end

local function HideMiniPins()
    for _, frame in ipairs(miniPool) do
        frame:Hide()
    end
    if miniArea then
        miniArea:Hide()
    end
end

local function FacingRadians()
    if not (GetCVar and GetCVar("rotateMinimap") == "1") then
        return 0, false
    end
    local facing = GetPlayerFacing and GetPlayerFacing() or nil
    if not facing then
        return 0, false
    end
    return facing, true
end

local function UpdateMinimap()
    if not (Minimap and Minimap:IsShown()) then
        HideMiniPins()
        return
    end
    local playerMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local playerPos = playerMap and C_Map.GetPlayerMapPosition(playerMap, "player")
    if not (playerMap and playerPos) then
        HideMiniPins()
        return
    end
    local px, py = playerPos:GetXY()
    local radius = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if not radius or radius <= 0 then
        HideMiniPins()
        return
    end
    local halfW = Minimap:GetWidth() / 2
    local halfH = Minimap:GetHeight() / 2
    local facing, rotating = FacingRadians()
    local cos, sin = math.cos(facing), math.sin(facing)
    local spanX, spanY = MapSpans(playerMap)
    if spanX <= 0 or spanY <= 0 then
        HideMiniPins()
        return
    end

    local function project(x, y)
        local east = (x - px) * spanX
        local north = (py - y) * spanY
        local fx, fy = east / radius, north / radius
        if rotating then
            local rx = fx * cos - fy * sin
            local ry = fx * sin + fy * cos
            return rx, ry
        end
        return fx, fy
    end

    local used = 0
    for _, pin in ipairs(pins) do
        if pin.mapId == playerMap then
            local fx, fy = project(pin.x / 100, pin.y / 100)
            if fx * fx + fy * fy <= EDGE_LIMIT_SQ then
                used = used + 1
                local frame = EnsureMiniPin(used)
                if frame then
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", Minimap, "CENTER", fx * halfW, -fy * halfH)
                    local texture = ICONS[pin.kind] or ICONS.w
                    if frame.lastTexture ~= texture then
                        frame.lastTexture = texture
                        frame.icon:SetTexture(texture)
                    end
                    frame.pinData = pin
                    frame:Show()
                end
            end
        end
    end
    for index = used + 1, #miniPool do
        miniPool[index]:Hide()
    end

    local area = EnsureMiniArea()
    local selected
    if selectedEntryId then
        for _, pin in ipairs(pins) do
            if pin.entry and pin.entry.id == selectedEntryId and pin.mapId == playerMap then
                selected = pin
                break
            end
        end
    end
    if not selected then
        area:Hide()
        return
    end
    local fx, fy = project(selected.x / 100, selected.y / 100)
    if fx * fx + fy * fy > EDGE_LIMIT_SQ then
        area:Hide()
        return
    end
    area:ClearAllPoints()
    area:SetPoint("CENTER", Minimap, "CENTER", fx * halfW, -fy * halfH)
    area:SetSize(halfW * 0.7, halfH * 0.7)
    area:Show()
end

local function UpdateAll()
    if #pins == 0 then
        if poolsActive then
            poolsActive = false
            HideWorldPins()
            HideMiniPins()
        end
        return
    end
    poolsActive = true
    UpdateWorldMap()
    UpdateMinimap()
end

function GQ.Pins:Sync()
    if not driver then
        self:Init()
    end
    pins = {}
    local entries = GQ.Tracker and GQ.Tracker.GetTrackedEntries and GQ.Tracker:GetTrackedEntries()
    if entries and GQ.Map and GQ.Map.SpotForEntry then
        for _, entry in ipairs(entries) do
            local pin = GQ.Map:SpotForEntry(entry)
            if pin then
                pins[#pins + 1] = pin
            end
        end
    end
    if selectedEntryId then
        local found = false
        for _, pin in ipairs(pins) do
            if pin.entry and pin.entry.id == selectedEntryId then
                found = true
                break
            end
        end
        if not found then
            selectedEntryId = nil
        end
    end
    UpdateAll()
end

function GQ.Pins:Init()
    if driver then
        return
    end
    driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed)
        elapsedAcc = elapsedAcc + (elapsed or 0)
        if elapsedAcc < UPDATE_INTERVAL then
            return
        end
        elapsedAcc = 0
        UpdateAll()
    end)
    UpdateAll()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    GQ.Pins:Init()
    GQ.Pins:Sync()
end)
