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
    local group = Categories:Get(rec.t).mapGroup
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
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map and map:GetMapID()
        if not mapID then return end
        FC.ZoneGuide:OnWorldMapChanged(mapID)
        for _, rec in ipairs(FC.Store:ForMap(mapID)) do
            local visible, veiled = MapIntegration:IsVisible(rec)
            if visible then
                map:AcquirePin(TEMPLATE, rec, veiled)
                if not veiled then MapIntegration:AcquireDots(map, rec) end
            end
        end
    end

    return provider
end

--- Route points (paths, shortcuts) and extra spots (gathering nodes).
function MapIntegration:AcquireDots(map, rec)
    local list = rec.tr or rec.pts
    if not list then return end
    for i, packed in ipairs(list) do
        local x, y = U.UnpackPoint(packed)
        local isMain = math.abs(x - rec.x) < 0.0005 and math.abs(y - rec.y) < 0.0005
        if not isMain and i <= 60 then
            map:AcquirePin(TEMPLATE, rec, false, x, y)
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

function MapIntegration:Highlight(id)
    C_Timer.After(0.3, function()
        if not (WorldMapFrame and WorldMapFrame.EnumeratePinsByTemplate) then return end
        local ok, iterator = pcall(WorldMapFrame.EnumeratePinsByTemplate, WorldMapFrame, TEMPLATE)
        if not ok or not iterator then return end
        for pin in iterator do
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

function MapIntegration:BuildFilterButton()
    local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
    local button = UI.IconButton(parent, FC.C.MEDIA .. "Logo", 30, nil, function(b, mouseButton)
        if mouseButton == "RightButton" then
            self:OpenFilterMenu(b)
        else
            FC.ZoneGuide:ToggleForMap(WorldMapFrame:GetMapID())
        end
    end)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    FC.Theme:Forget(button.bg)
    button.bg:SetColorTexture(0, 0, 0, 0.55)
    button:SetScript("OnEnter", function(b)
        UI.ShowTooltip(b, L.ADDON_NAME, { { L.MAP_ZONE_TIP, "text" }, { L.MAP_FILTER_TIP, "muted" }, { L.MAP_NOTE_TIP, "muted" } }, FC.C.MEDIA .. "Logo")
    end)
    button:SetScript("OnLeave", UI.HideTooltip)
    self.filterButton = button
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
        if path == "*" or path:find("^map") or path:find("^knowledge") or path:find("^discovery%.verify") then
            self:QueueRefresh()
        end
    end)
end
