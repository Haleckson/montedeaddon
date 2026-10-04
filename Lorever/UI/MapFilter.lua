local _, ns = ...

-- Map filters: a small book button on the world map opens a little panel of
-- our own with the choices below. It does not use Blizzard's menu system: code
-- from an add-on inside Blizzard's menus can "taint" them, and the game then
-- blocks protected actions that use the same menus (such as marking a target).
-- The choices change the same settings as Options > AddOns > Lorever.

local Filter = {}
ns.MapFilter = Filter

local Theme = ns.Theme

local N = ns.N
Filter.CHOICES = {
	{ key = "mapPins", label = N("Lore to discover") },
	{ key = "bookPins", label = N("Literature to read") },
	{ key = "mapPinsDiscovered", label = N("Also what I already know") },
	{ key = "continentPins", label = N("Counts on continent maps") },
}

function Filter.Set(key, value)
	ns.db.settings[key] = value and true or false
	ns.Progress.Invalidate()
	ns.Fire("FL_SETTINGS_CHANGED", key)
	local provider = ns.MapPins.provider
	if provider and provider.GetMap and provider:GetMap() and WorldMapFrame:IsShown() then provider:RefreshAllData() end
end

local panel

local function createPanel(anchor)
	panel = CreateFrame("Frame", "LoreverMapFilterPanel", anchor)
	panel:SetSize(210, 24 + #Filter.CHOICES * 22)
	panel:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
	panel:SetFrameStrata("DIALOG")
	panel:EnableMouse(true)
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.94)
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 8, -6)
	title:SetText(ns.T("Lorever marks"))
	title:SetTextColor(unpack(Theme.TURQUOISE))
	panel.boxes = {}
	for i, choice in ipairs(Filter.CHOICES) do
		local box = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
		box:SetSize(22, 22)
		box:SetPoint("TOPLEFT", 6, -22 - (i - 1) * 22)
		local label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", box, "RIGHT", 2, 0)
		label:SetText(ns.T(choice.label))
		box:SetScript("OnClick", function(self) Filter.Set(choice.key, self:GetChecked()) end)
		box.key = choice.key
		panel.boxes[#panel.boxes + 1] = box
	end
	panel:Hide()
	Filter.panel = panel
end

function Filter.Toggle(anchor)
	if not panel then createPanel(anchor) end
	if panel:IsShown() then
		panel:Hide()
		return
	end
	for _, box in ipairs(panel.boxes) do box:SetChecked(ns.db.settings[box.key] == true) end
	panel:Show()
end

local function createButton()
	local parent = type(WorldMapFrame.ScrollContainer) == "table" and WorldMapFrame.ScrollContainer or WorldMapFrame
	local b = CreateFrame("Button", "LoreverMapFilterButton", parent)
	b:SetSize(28, 28)
	ns.Movable.Add("mapFilterButton", b, parent, function(f) f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -40, -4) end)
	b:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 20)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture(Theme.ICON)
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetScript("OnClick", function(self) Filter.Toggle(self) end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(ns.T("Lorever marks"), unpack(Theme.TURQUOISE))
		local s = ns.db.settings
		GameTooltip:AddLine(string.format(ns.T("Lore: %s   Literature: %s"),
			s.mapPins and ns.T("shown") or ns.T("hidden"), s.bookPins and ns.T("shown") or ns.T("hidden")), 1, 1, 1)
		GameTooltip:AddLine(ns.T("Click to choose."), 0.7, 0.7, 0.7)
		GameTooltip:AddLine(ns.Movable.Tip(), 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	-- The panel closes with the map.
	if WorldMapFrame.HookScript then WorldMapFrame:HookScript("OnHide", function() if panel then panel:Hide() end end) end
	Filter.button = b
	b:SetShown(ns.db.settings.mapButton ~= false)
end

ns.Listen("FL_LOGIN", function()
	if WorldMapFrame then createButton() end
end)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key)
	if key == "mapButton" and Filter.button then
		Filter.button:SetShown(ns.db.settings.mapButton ~= false)
		if panel and not ns.db.settings.mapButton then panel:Hide() end
	end
end)
