local _, ns = ...

-- Turquoise "!" on the world map where a figure with lore can be found.
-- Uses Blizzard's map canvas (the same system as quest and area pins).
-- The template is in MapPins.xml. Blizzard's base mixins are mixed in at
-- login, when the world map is sure to be loaded.

local Lore, P, Theme = ns.Lore, ns.Progress, ns.Theme
local TEMPLATE = "LoreverPinTemplate"

-- Pin ------------------------------------------------------------------------

local Pin = {}

function Pin:OnLoad()
	if self.UseFrameLevelType then self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI") end
	if self.SetScalingLimits then self:SetScalingLimits(1, 1.0, 1.2) end
	Theme.Marker(self.Icon)
	self.Count = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	self.Count:SetPoint("BOTTOMRIGHT", 4, -2)
end

-- A pin marks a figure (turquoise "!") or a writing (book icon), at x, y (0-100).
-- A "zone-summary" (continent maps) is a "!" with the count of what is left, at x, y (0-1).
function Pin:OnAcquired(figure, x, y)
	self.figure = figure
	if self.Count then self.Count:SetText(figure.kind == "zone-summary" and tostring(figure.count) or "") end
	-- Sizes: the "!" as small as the game's own quest mark; a count needs a little more room.
	local size = figure.kind == "zone-summary" and 18 or figure.kind == "book" and 13 or 12
	if self.SetSize then self:SetSize(size, size) end
	if figure.kind == "zone-summary" then
		Theme.Marker(self.Icon)
		Theme.Round(self, self.Icon, false)
		self.Icon:SetAlpha(1)
		self:SetPosition(x, y)
		return
	elseif figure.kind == "book" then
		-- A writing: a small round book, a little see-through.
		self.Icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, 1, 1)
		Theme.Round(self, self.Icon, true)
		self.Icon:SetAlpha(P.IsFound(figure.id) and 0.4 or 0.75)
		self:SetPosition(x / 100, y / 100)
		return
	else
		Theme.Marker(self.Icon)
	end
	Theme.Round(self, self.Icon, false)
	self.Icon:SetAlpha(P.IsFound(figure.id) and 0.55 or 1)
	self:SetPosition(x / 100, y / 100)
end

function Pin:OnMouseEnter()
	local figure = self.figure
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if figure.kind == "zone-summary" then
		GameTooltip:AddLine(figure.title, 1, 1, 1)
		GameTooltip:AddLine(string.format(ns.T("%d still to find: figures and writings."), figure.count), unpack(Theme.TURQUOISE))
		GameTooltip:Show()
		return
	elseif figure.kind == "book" then
		local kind = ns.T(ns.Library.Category(figure).one)
		GameTooltip:AddLine(figure.title, 1, 1, 1)
		GameTooltip:AddLine(string.format(P.IsFound(figure.id) and ns.T("%s, already read.") or ns.T("%s, not yet read."), kind), unpack(ns.Panel.BOOK_COLOR))
		if figure.found then GameTooltip:AddLine(Theme.Plain(figure.found), 1, 1, 1, true) end
	elseif P.IsFound(figure.id) then
		GameTooltip:AddLine(figure.title, 1, 1, 1)
		if figure.subtitle then GameTooltip:AddLine(figure.subtitle, nil, nil, nil, true) end
		GameTooltip:AddLine(ns.T("Click to read."), unpack(Theme.TURQUOISE))
	else
		GameTooltip:AddLine(ns.T("Undiscovered Lore"), unpack(Theme.TURQUOISE))
		GameTooltip:AddLine(Theme.Plain(Lore.Hint(figure)), 1, 1, 1, true)
	end
	GameTooltip:AddLine(ns.T("Right-click: set a waypoint"), 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

function Pin:OnMouseLeave()
	GameTooltip:Hide()
end

function Pin:OnClick(button)
	if self.figure.kind == "zone-summary" then return end -- a count only: the add-on never turns the map
	if button == "RightButton" then
		ns.Track.SetWaypoint(self.figure)
	elseif button == "LeftButton" and (P.IsUnlocked(self.figure.id) or self.figure.kind == "book") then
		ns.QuestLogTab.Open(self.figure.id)
	end
end

-- The XML template names this global.
LoreverPinMixin = {}
for k, v in pairs(Pin) do LoreverPinMixin[k] = v end

-- Data provider -----------------------------------------------------------------

local Own = {}

function Own:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
end

function Own:RefreshAllData()
	self:RemoveAllData()
	local map = self:GetMap()
	local mapID = map:GetMapID()
	ns.Triggers.OnMapShown(mapID)
	local s = ns.db.settings
	local questie = ns.QuestieBridge and ns.QuestieBridge.Active() -- then Questie draws the marks
	for _, spot in ipairs(questie and {} or ns.MapPins.PinsOn(mapID)) do
		local entry = spot.entry
		local wanted = (entry.kind == "book" and s.bookPins) or (entry.kind ~= "book" and s.mapPins)
		if wanted and (s.mapPinsDiscovered or not P.IsFound(entry.id)) then
			map:AcquirePin(TEMPLATE, entry, spot.x, spot.y)
		end
	end
	if s.continentPins then ns.MapPins.AddZoneSummaries(map, mapID) end
end

-- A map that changes its size or scale (window mode, a zoom add-on) draws the marks again.
function Own:OnCanvasSizeChanged() self:RefreshAllData() end
function Own:OnCanvasScaleChanged()
	local map = self:GetMap()
	for pin in map:EnumeratePinsByTemplate(TEMPLATE) do
		if pin.ApplyCurrentScale then pin:ApplyCurrentScale() end
		if pin.ApplyCurrentPosition then pin:ApplyCurrentPosition() end
	end
end
function Own:OnShow() self:RefreshAllData() end

local M = {}
ns.MapPins = M

-- On a continent map: one mark per zone, with the number of figures and
-- writings still to find there. Click it to open the zone.
function M.ZoneSummaries(mapID)
	local out = {}
	local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
	local continent = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
	if not (info and info.mapType == continent and C_Map.GetMapChildrenInfo and C_Map.GetMapRectOnMap) then return out end
	local children = C_Map.GetMapChildrenInfo(mapID, Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3) or {}
	for _, child in ipairs(children) do
		local count = ns.Track.CountOn(child.mapID)
		if count > 0 then
			local left, right, top, bottom = C_Map.GetMapRectOnMap(child.mapID, mapID)
			if left and right and top and bottom then
				out[#out + 1] = { kind = "zone-summary", id = "zone:" .. child.mapID, mapID = child.mapID, title = child.name,
					count = count, x = (left + right) / 2, y = (top + bottom) / 2 }
			end
		end
	end
	return out
end

function M.AddZoneSummaries(map, mapID)
	for _, zone in ipairs(M.ZoneSummaries(mapID)) do map:AcquirePin(TEMPLATE, zone, zone.x, zone.y) end
end

local function has(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then return true end
	end
	return false
end

-- Every pin on this map, as { entry, x, y }. An entry with "pin" shows on its
-- region's maps; one with "pins" names the maps of each place itself.
function M.PinsOn(mapID)
	local out = {}
	for _, entry in ipairs(Lore.order) do
		if entry.kind == "figure" or entry.kind == "book" then
			if entry.pin then
				local region = Lore.Get(entry.region)
				if region and has(region.maps, mapID) then
					out[#out + 1] = { entry = entry, x = entry.pin.x, y = entry.pin.y }
				end
			end
			for _, pin in ipairs(entry.pins or {}) do
				if has(pin.maps, mapID) then out[#out + 1] = { entry = entry, x = pin.x, y = pin.y } end
			end
		end
	end
	return out
end

ns.Listen("FL_LOGIN", function()
	if not (WorldMapFrame and WorldMapFrame.AddDataProvider and MapCanvasPinMixin and MapCanvasDataProviderMixin) then return end
	-- Blizzard's base first, our methods on top.
	for k, v in pairs(MapCanvasPinMixin) do
		if Pin[k] == nil then LoreverPinMixin[k] = v end
	end
	M.provider = Mixin({}, MapCanvasDataProviderMixin, Own)
	WorldMapFrame:AddDataProvider(M.provider)
	-- Another add-on may resize the map after it is shown (window mode): draw again, once, a moment later.
	local pending
	local function again()
		if pending or not WorldMapFrame:IsShown() then return end
		pending = true
		C_Timer.After(0.2, function()
			pending = false
			if WorldMapFrame:IsShown() and M.provider:GetMap() then pcall(M.provider.RefreshAllData, M.provider) end
		end)
	end
	if WorldMapFrame.HookScript then
		WorldMapFrame:HookScript("OnShow", again)
		WorldMapFrame:HookScript("OnSizeChanged", again)
	end
end)

ns.Listen("FL_UNLOCKED", function()
	local provider = M.provider
	if provider and provider.GetMap and provider:GetMap() and WorldMapFrame:IsShown() then
		provider:RefreshAllData()
	end
end)
