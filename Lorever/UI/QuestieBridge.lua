local _, ns = ...

-- Optional: draw Lorever's marks with Questie's own map icons ("Use Questie
-- icons" in the options). They then show on the minimap too, obey Questie's
-- show/hide toggles and scale, and Ctrl-click sends them to TomTom.
--
-- Questie has no public API for this, so it uses Questie's internal map
-- module. Every call is guarded: if Questie changes, Lorever falls back to its
-- own pins and shows no error. Questie's code is not copied, only called.

local Bridge = {}
ns.QuestieBridge = Bridge

local Lore, P, Theme = ns.Lore, ns.Progress, ns.Theme
local TYPE = "Lorever"
local ICON_FIGURE = "Interface\\GossipFrame\\AvailableQuestIcon"
local ICON_BOOK = "Interface\\Icons\\INV_Misc_Book_11"

local QuestieMap, ZoneDB

-- Questie's modules, or nil. ImportModule makes an empty module for a wrong
-- name, so the functions themselves are checked.
local function modules()
	if QuestieMap and ZoneDB then return QuestieMap, ZoneDB end
	local loader = _G.QuestieLoader
	if not (loader and loader.ImportModule) then return nil end
	local okM, map = pcall(loader.ImportModule, loader, "QuestieMap")
	local okZ, zones = pcall(loader.ImportModule, loader, "ZoneDB")
	if okM and okZ and map and zones and type(map.DrawManualIcon) == "function"
		and type(map.ResetManualFrames) == "function" and type(zones.GetAreaIdByUiMapId) == "function" then
		QuestieMap, ZoneDB = map, zones
		return map, zones
	end
end

-- Questie is loaded, ready, and the reader wants its icons.
function Bridge.Active()
	if not (ns.db and ns.db.settings.useQuestieIcons) then return false end
	local API = _G.Questie and _G.Questie.API
	if not (API and API.isReady) then return false end
	return modules() ~= nil
end

local function areaOf(maps)
	for _, uiMap in ipairs(maps or {}) do
		local ok, area = pcall(ZoneDB.GetAreaIdByUiMapId, ZoneDB, uiMap)
		if ok and area and area ~= 0 then return area end
	end
end

-- Draws every undiscovered figure and unread writing. Returns the icon count.
function Bridge.Redraw()
	local map = modules()
	if not map then return 0 end
	pcall(map.ResetManualFrames, map, TYPE)
	if not Bridge.Active() then return 0 end
	local s, drawn = ns.db.settings, 0
	for i, entry in ipairs(Lore.order) do
		local isBook = entry.kind == "book"
		local wanted = (isBook and s.bookPins) or (entry.kind == "figure" and s.mapPins)
		if wanted and not P.IsFound(entry.id) then
			for _, spot in ipairs(ns.Track.Spots(entry)) do
				local area = areaOf(spot.maps)
				if area then
					local data = {
						id = -(1000000 + i), -- negative: never the ID of a real NPC or object
						Name = entry.title,
						Icon = isBook and ICON_BOOK or ICON_FIGURE,
						GetIconScale = function() return 1 end,
						Type = "manual",
						ManualTooltipData = {
							Title = entry.title,
							Body = { { isBook and ns.T(ns.Library.Category(entry).one) or ns.T("Undiscovered Lore"),
								Theme.Plain(isBook and (entry.found or "") or Lore.Hint(entry)) } },
							disableShiftToRemove = true,
						},
					}
					if pcall(map.DrawManualIcon, map, data, area, spot.x, spot.y, TYPE) then drawn = drawn + 1 end
				end
			end
		end
	end
	return drawn
end

local function redrawSoon()
	if Bridge.pending then return end
	Bridge.pending = true
	C_Timer.After(0.5, function()
		Bridge.pending = false
		Bridge.Redraw()
	end)
end

ns.Listen("FL_LOGIN", function()
	local API = _G.Questie and _G.Questie.API
	if API and API.RegisterOnReady then pcall(API.RegisterOnReady, redrawSoon) end
end)
ns.Listen("FL_UNLOCKED", function() if Bridge.Active() then redrawSoon() end end)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key)
	if key == "useQuestieIcons" or key == "mapPins" or key == "bookPins" then
		redrawSoon()
		if ns.MapPins.provider and WorldMapFrame:IsShown() then ns.MapPins.provider:RefreshAllData() end
	end
end)
