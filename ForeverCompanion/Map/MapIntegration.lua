--[[
  Forever Companion - Map/MapIntegration.lua
  World map layer: a map canvas data provider that places discovery pins,
  the knowledge-layer filters ("Discovery Fog"), a filter button on the map
  and Alt+Right-click to create a map note.

  Pins read from the Store only; the map never scans the whole database:
  it asks for the records indexed under the displayed map ID.
]]

local _, FC = ...

local MapIntegration = FC:NewModule("MapIntegration")

local UI = FC.UI
local L = FC.L
local U = FC.Utils
local Categories = FC.Categories

local TEMPLATE = "ForeverCompanionMapPinTemplate"

------------------------------------------------------------------------
-- Filters
------------------------------------------------------------------------

--- Returns visible, veiled for a record under the current map settings.
function MapIntegration:IsVisible(rec)
    if not FC.P.map.enabled then return false end
    return self:PassesFilters(rec)
end

--- The filters shared by the world map and the minimap: position, Discovery
--- Fog, archive, category groups, dangerous spots, mine / guild.
--- Returns visible, veiled.
function MapIntegration:PassesFilters(rec)
    local P = FC.P.map
    if not rec.x or not rec.y then return false end
    if not FC.Store:IsKnown(rec) then return false end
    local state = FC.Store:GetState(rec.id)
    if state and state.arch and not FC.P.journal.showArchived then return false end
    local group = Categories:ForRecord(rec).mapGroup
    if P.hiddenGroups[group] == true then return false end
    if not P.showDeaths and type(rec.id) == "string" and rec.id:find("^u:death:") then return false end
    local mine = FC.Store:IsMine(rec)
    if mine and not P.showMine then return false end
    if not mine and not P.showGuild then return false end
    return true, FC.Store:IsRumored(rec)
end

------------------------------------------------------------------------
-- Data provider
------------------------------------------------------------------------

local function createProvider()
    local provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
    end

    function provider:RefreshAllData()
        local map = self:GetMap()
        local mapID = map and map:GetMapID()
        if not mapID then self:RemoveAllData(); return end
        -- Releasing every pin also ends its hover and cuts narration short.
        -- Reuse unchanged records; remove only pins that no longer belong here.
        local existing, unused = {}, {}
        local function positionKey(x, y)
            return x ~= nil and (tostring(x) .. ":" .. tostring(y)) or "main"
        end
        if type(map.EnumeratePinsByTemplate) == "function" and type(map.RemovePin) == "function" then
            for pin in map:EnumeratePinsByTemplate(TEMPLATE) do
                unused[pin] = true
                if pin.rec then
                    existing[pin.rec] = existing[pin.rec] or {}
                    existing[pin.rec][positionKey(pin.fcDotX, pin.fcDotY)] = pin
                end
            end
        else
            self:RemoveAllData()
        end
        local function acquire(rec, veiled, x, y)
            local pin = existing[rec] and existing[rec][positionKey(x, y)]
            if pin and unused[pin] and pin.veiled == veiled then
                unused[pin] = nil
                pin:ApplyAppearance()
                pin:SetPosition(x or rec.x, y or rec.y)
            else
                map:AcquirePin(TEMPLATE, rec, veiled, x, y)
            end
        end
        FC.ZoneGuide:OnWorldMapChanged(mapID)
        for _, rec in ipairs(FC.Store:ForMap(mapID)) do
            local visible, veiled = MapIntegration:IsVisible(rec)
            if visible then
                acquire(rec, veiled)
                if not veiled then MapIntegration:AcquireDots(map, rec, acquire) end
            end
        end
        for pin in pairs(unused) do map:RemovePin(pin) end
    end

    return provider
end

--- Route points (paths, shortcuts) and extra spots (gathering nodes).
function MapIntegration:AcquireDots(map, rec, acquire)
    if FC.P.map.routeDots == false then return end
    local list = rec.tr or rec.pts
    if not list then return end
    for i, packed in ipairs(list) do
        local x, y = U.UnpackPoint(packed)
        local isMain = math.abs(x - rec.x) < 0.0005 and math.abs(y - rec.y) < 0.0005
        if not isMain and i <= 60 then
            if acquire then acquire(rec, false, x, y)
            else map:AcquirePin(TEMPLATE, rec, false, x, y) end
        end
    end
end

function MapIntegration:Refresh()
    if self.provider and WorldMapFrame and WorldMapFrame:IsShown() then
        FC:SafeCall("Map:Refresh", self.provider.RefreshAllData, self.provider)
    end
end

function MapIntegration:QueueRefresh()
    U.Debounce("map-refresh", 0.2, function() self:Refresh() end)
end

-- Apply visual sliders immediately, without rebuilding data or recycling pins
-- on every step of a drag. Hidden maps pick up the profile on their next refresh.
function MapIntegration:RefreshPinAppearance()
    local map = WorldMapFrame
    if not (map and map:IsShown() and map.EnumeratePinsByTemplate) then return end
    for pin in map:EnumeratePinsByTemplate(TEMPLATE) do
        if pin.ApplyAppearance then pin:ApplyAppearance() end
    end
end

local PIN_APPEARANCE = {
    ["map.iconScale"] = true, ["map.iconAlpha"] = true,
    ["map.pinArtwork"] = true, ["map.dotScale"] = true,
    ["map.pinBackdrop"] = true, ["map.pinOutlineAlpha"] = true,
}

function MapIntegration:Highlight(id)
    C_Timer.After(0.3, function()
        if not (WorldMapFrame and WorldMapFrame.EnumeratePinsByTemplate) then return end
        local ok, iterator, state, key = pcall(WorldMapFrame.EnumeratePinsByTemplate, WorldMapFrame, TEMPLATE)
        if not ok or not iterator then return end
        -- Pool iterators may return a function, state and initial key (pairs),
        -- rather than a self-contained closure. Preserve the complete result.
        for pin in iterator, state, key do
            if pin.rec and pin.rec.id == id and pin.Pulse then pin:Pulse(4) end
        end
    end)
end

------------------------------------------------------------------------
-- Map note (Alt + Right-click)
------------------------------------------------------------------------

function MapIntegration:OnCanvasClick(button, x, y)
    if button ~= "RightButton" or not IsAltKeyDown() or not FC.P.map.altClickNotes then return false end
    local mapID = WorldMapFrame:GetMapID()
    if not mapID or type(x) ~= "number" or type(y) ~= "number" then return false end
    if x < 0 or x > 1 or y < 0 or y > 1 then return false end
    FC.Editor:OpenAt(mapID, x, y)
    return true
end

function MapIntegration:HookClicks()
    local map = WorldMapFrame
    if map.AddCanvasClickHandler then
        map:AddCanvasClickHandler(function(_, button, cursorX, cursorY)
            local ok, handled = pcall(self.OnCanvasClick, self, button, cursorX, cursorY)
            return ok and handled or false
        end, 100)
        return
    end
    local container = map.ScrollContainer
    if container and container.HookScript then
        container:HookScript("OnMouseUp", function(frame, button)
            if button == "RightButton" and IsAltKeyDown() and frame.GetNormalizedCursorPosition then
                local x, y = frame:GetNormalizedCursorPosition()
                self:OnCanvasClick(button, x, y)
            end
        end)
    end
end

------------------------------------------------------------------------
-- Filter button on the world map
------------------------------------------------------------------------

-- Store fractions of the usable map area, not screen coordinates. This
-- keeps the button on the map when its size, position or UI scale changes.
local function buttonFraction(value, fallback)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.max(0, math.min(1, value))
end

local function buttonPosition()
    local saved = FC.P.map.menuButton
    if type(saved) ~= "table" then return 0, 1 end
    return buttonFraction(saved.x, 0), buttonFraction(saved.y, 1)
end

local function buttonBounds(button)
    local parent = button:GetParent()
    local scale = button:GetScale() or 1
    local width = math.max(0, parent:GetWidth() - button:GetWidth() * scale)
    local height = math.max(0, parent:GetHeight() - button:GetHeight() * scale)
    local padX, padY = math.min(8, width / 2), math.min(8, height / 2)
    return parent, padX, padY, width - 2 * padX, height - 2 * padY
end

local function anchorButton(button, x, y)
    local parent, padX, padY, width, height = buttonBounds(button)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", padX + width * x, -padY - height * y)
end

function MapIntegration:PlaceFilterButton()
    local button = self.filterButton
    if not button or button.fcMapDrag then return end
    local x, y = buttonPosition()
    anchorButton(button, x, y)
end

function MapIntegration:UpdateFilterButtonDrag()
    local button = self.filterButton
    local drag = button and button.fcMapDrag
    if not drag then return end
    local parent, padX, padY, width, height = buttonBounds(button)
    local left, top = parent:GetLeft(), parent:GetTop()
    local scale = parent:GetEffectiveScale()
    if not left or not top or not scale or scale <= 0 then return end
    local cursorX, cursorY = GetCursorPosition()
    drag.x = width > 0 and buttonFraction((cursorX / scale - left - drag.grabX - padX) / width, drag.x) or 0
    drag.y = height > 0 and buttonFraction((top - cursorY / scale - drag.grabY - padY) / height, drag.y) or 0
    anchorButton(button, drag.x, drag.y)
end

function MapIntegration:StopFilterButtonDrag(save)
    local button = self.filterButton
    local drag = button and button.fcMapDrag
    if not drag then return end
    button:SetScript("OnUpdate", nil)
    button.fcMapDrag = nil
    if save then
        FC.Config:Set("map.menuButton", { x = drag.x, y = drag.y })
    end
    self:PlaceFilterButton()
end

function MapIntegration:BuildFilterButton()
    local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
    local button = UI.IconButton(parent, FC.C.MEDIA .. "Logo", 24, nil, function(b, mouseButton)
        -- A move must not also open the zone guide or the filter menu.
        if b.fcMapDrag or b.fcMapDragClick or IsShiftKeyDown() then return end
        if mouseButton == "RightButton" then
            self:OpenFilterMenu(b)
        else
            FC.ZoneGuide:ToggleForMap(WorldMapFrame:GetMapID())
        end
    end)
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetHitRectInsets(-4, -4, -4, -4)

    -- Make the map button cleaner and less intrusive: smaller footprint,
    -- sharper logo, soft round backing for contrast, no opaque square fill.
    FC.Theme:Forget(button.bg)
    button.bg:SetAlpha(0)
    button.hover:SetAlpha(0.14)
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("CENTER")
    if button.icon.SetTexelSnappingBias then pcall(button.icon.SetTexelSnappingBias, button.icon, 0) end

    button.shadow = button:CreateTexture(nil, "BACKGROUND", nil, -2)
    button.shadow:SetTexture(FC.C.WHITE)
    if button.shadow.SetMask then pcall(button.shadow.SetMask, button.shadow, FC.C.CIRCLE_MASK) end
    button.shadow:SetPoint("CENTER")
    button.shadow:SetSize(22, 22)
    button.shadow:SetVertexColor(0, 0, 0, 0.22)

    button.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.backdrop:SetTexture(FC.C.WHITE)
    if button.backdrop.SetMask then pcall(button.backdrop.SetMask, button.backdrop, FC.C.CIRCLE_MASK) end
    button.backdrop:SetPoint("CENTER")
    button.backdrop:SetSize(20, 20)
    button.backdrop:SetVertexColor(0.04, 0.06, 0.09, 0.18)

    button:SetScript("OnMouseDown", function(b) b.fcMapDragClick = nil end)
    button:SetScript("OnDragStart", function(b)
        if not IsShiftKeyDown() then return end
        local map, padX, padY, width, height = buttonBounds(b)
        local left, top = map:GetLeft(), map:GetTop()
        local scale = map:GetEffectiveScale()
        if not left or not top or not scale or scale <= 0 then return end
        local x, y = buttonPosition()
        local cursorX, cursorY = GetCursorPosition()
        b.fcMapDrag = {
            x = x, y = y,
            grabX = cursorX / scale - left - padX - width * x,
            grabY = top - padY - height * y - cursorY / scale,
        }
        b.fcMapDragClick = true
        UI.HideTooltip(b)
        UI.CloseMenu()
        -- Move only this button, always anchored to its map parent. Avoid
        -- StartMoving's screen anchors and never drag the world map itself.
        b:SetScript("OnUpdate", function() self:UpdateFilterButtonDrag() end)
    end)
    button:SetScript("OnDragStop", function()
        self:UpdateFilterButtonDrag()
        self:StopFilterButtonDrag(true)
    end)
    button:SetScript("OnHide", function() self:StopFilterButtonDrag(true) end)
    button:SetScript("OnShow", function() self:PlaceFilterButton() end)
    if parent.HookScript then
        parent:HookScript("OnSizeChanged", function() self:PlaceFilterButton() end)
    end
    button:SetScript("OnEnter", function(b)
        UI.ShowTooltip(b, L.ADDON_NAME, {
            { L.MAP_ZONE_TIP, "text" },
            { L.MAP_FILTER_TIP, "muted" },
            { L.MAP_BUTTON_MOVE_TIP, "muted" },
            { L.MAP_NOTE_TIP, "muted" },
        }, FC.C.MEDIA .. "Logo")
    end)
    button:SetScript("OnLeave", UI.HideTooltip)
    self.filterButton = button
    self:PlaceFilterButton()
end
function MapIntegration:OpenFilterMenu(anchor)
    local P = FC.P.map
    local function toggle(path)
        return function()
            FC.Config:Set(path, not FC.Config:Get(path))
            self:OpenFilterMenu(anchor)
        end
    end
    local mode = FC.P.knowledge.mode
    local function setMode(value)
        return function()
            FC.Config:Set("knowledge.mode", value)
            self:OpenFilterMenu(anchor)
        end
    end
    local items = {
        { text = L.MAP_SHOW_PINS, checked = P.enabled, onClick = toggle("map.enabled") },
        { text = L.MAP_SHOW_MINE, checked = P.showMine, onClick = toggle("map.showMine") },
        { text = L.MAP_SHOW_GUILD, checked = P.showGuild, onClick = toggle("map.showGuild") },
        { divider = true },
        { text = L.KNOWLEDGE_LAYER, isTitle = true },
        { text = L.KNOWLEDGE_MINE, checked = mode == "mine", onClick = setMode("mine") },
        { text = L.KNOWLEDGE_VERIFIED, checked = mode == "verified", onClick = setMode("verified") },
        { text = L.KNOWLEDGE_ALL, checked = mode == "all", onClick = setMode("all") },
        { text = L.KNOWLEDGE_VEIL, checked = FC.P.knowledge.veil, onClick = toggle("knowledge.veil") },
        { divider = true },
        { text = L.MAP_CATEGORIES, isTitle = true },
    }
    items[#items + 1] = { text = L.MAP_SHOW_DEATHS, checked = P.showDeaths, onClick = toggle("map.showDeaths") }
    for _, group in ipairs(Categories.MAP_GROUPS) do
        items[#items + 1] = {
            text = L[group.label],
            checked = P.hiddenGroups[group.key] ~= true,
            onClick = function()
                P.hiddenGroups[group.key] = P.hiddenGroups[group.key] ~= true
                FC.Config:Set("map.hiddenGroups", P.hiddenGroups)
                self:OpenFilterMenu(anchor)
            end,
        }
    end
    UI.OpenMenu(anchor, items, 230)
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function MapIntegration:Attach()
    if self.provider then return true end
    if not (WorldMapFrame and WorldMapFrame.AddDataProvider and MapCanvasDataProviderMixin and CreateFromMixins) then
        return false
    end
    self.provider = createProvider()
    WorldMapFrame:AddDataProvider(self.provider)
    self:HookClicks()
    self:BuildFilterButton()
    if WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnHide", function() FC.ZoneGuide:OnWorldMapClosed() end)
    end
    FC.Log:Debug("World map layer attached")
    return true
end

function MapIntegration:OnEnable()
    if not self:Attach() then
        FC.Events:Register("ADDON_LOADED", self, function(_, _, name)
            if name == "Blizzard_WorldMap" and self:Attach() then
                FC.Events:Unregister("ADDON_LOADED", self)
            end
        end)
    end
    local function refresh() self:QueueRefresh() end
    for _, message in ipairs({ "DISCOVERY_ADDED", "DISCOVERY_UPDATED", "DISCOVERY_REMOVED", "DISCOVERY_STATE", "STORE_RESET", "PROFILE_CHANGED" }) do
        FC.Bus:On(message, self, refresh)
    end
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path == "map" or path == "map.*" or path:find("^map%.menuButton") then
            -- A profile switch or settings reset takes precedence over a drag.
            self:StopFilterButtonDrag(false)
            self:PlaceFilterButton()
        end
        if PIN_APPEARANCE[path] then
            self:RefreshPinAppearance()
        elseif path == "*" or path:find("^map") or path:find("^knowledge") or path:find("^discovery%.verify") then
            self:QueueRefresh()
        end
    end)
    FC.Events:Register("UI_SCALE_CHANGED", self, self.RefreshPinAppearance)
end
