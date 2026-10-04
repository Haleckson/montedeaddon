local _, ns = ...

-- Turquoise "!" above figures whose lore is still undiscovered, and a
-- "Lore" line on their tooltip.
-- Nameplates: needs friendly NPC nameplates on (nameplateShowFriendlyNpcs).
-- Inside dungeons the game hides who an NPC is, so there is no marker there.

local M = {}
ns.Markers = M

local Lore, P, U, Theme = ns.Lore, ns.Progress, ns.U, ns.Theme
local plates = {} -- [unit] = plate
local icons = {}  -- [plate] = texture

local function undiscoveredFigure(npcID)
	for _, figure in ipairs(Lore.FiguresForNpc(npcID)) do
		if not P.IsFound(figure.id) then return figure end
	end
end

local function iconFor(plate)
	local icon = icons[plate]
	if not icon then
		icon = plate:CreateTexture(nil, "OVERLAY")
		icon:SetSize(14, 14) -- the size of the game's own quest mark
		icon:SetPoint("BOTTOM", plate, "TOP", 0, 2)
		Theme.Marker(icon)
		icons[plate] = icon
	end
	return icon
end

function M.UpdateUnit(unit)
	local plate = plates[unit]
	if not plate then return end
	local show = ns.db.settings.nameplateMarkers and undiscoveredFigure(U.UnitNpcID(unit)) ~= nil
	if show then
		iconFor(plate):Show()
	elseif icons[plate] then
		icons[plate]:Hide()
	end
end

function M.UpdateAll()
	for unit in pairs(plates) do M.UpdateUnit(unit) end
end

ns.On("NAME_PLATE_UNIT_ADDED", function(_, unit)
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
	-- Forbidden plates (friendly units in instances) come back as nil.
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if not plate then return end
	plates[unit] = plate
	M.UpdateUnit(unit)
end)

ns.On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	local plate = plates[unit]
	if plate and icons[plate] then icons[plate]:Hide() end
	plates[unit] = nil
end)

ns.Listen("FL_UNLOCKED", M.UpdateAll)

-- Friendly NPC nameplates ----------------------------------------------------

M.CVAR = "nameplateShowFriendlyNpcs"

function M.FriendlyPlatesOn()
	return GetCVar and GetCVar(M.CVAR) == "1"
end

function M.EnableFriendlyPlates()
	if U.InCombat() then
		ns.Print(ns.T("Wait until the fight is over."))
		return
	end
	SetCVar(M.CVAR, "1")
	ns.Print(ns.T("Friendly nameplates are on. Figures with undiscovered lore now show a turquoise mark."))
end

ns.Listen("FL_LOGIN", function()
	if ns.db.settings.nameplateMarkers and not M.FriendlyPlatesOn() and not ns.db.tips.friendlyPlates then
		ns.db.tips.friendlyPlates = true
		ns.Print(ns.T("Tip: type /lorever nameplates to see a turquoise mark above figures whose lore you have not yet discovered."))
	end
end)

-- Unit tooltip ------------------------------------------------------------------

local function tooltipLine(tooltip, data)
	if not ns.db or not ns.db.settings.unitTooltip then return end
	local guid = data and data.guid
	if not guid and tooltip.GetUnit then
		local _, unit = tooltip:GetUnit()
		guid = unit and UnitGUID(unit)
	end
	local figures = Lore.FiguresForNpc(U.NpcID(guid))
	local figure = figures[1]
	if not figure then return end
	local label = Theme.Color(Theme.TURQUOISE_HEX, ns.T("Lore:") .. " ")
	if P.IsFound(figure.id) then
		local done, total = P.EntryProgress(figure)
		tooltip:AddLine(label .. string.format(ns.T("%s (%d of %d)"), figure.title, done, total), 1, 1, 1)
	else
		tooltip:AddLine(label .. ns.T("undiscovered"), 1, 1, 1)
	end
	tooltip:Show()
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, tooltipLine)
end
