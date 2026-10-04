local _, ns = ...

-- The narrator bar: a small bar that stays on screen while lore is read aloud,
-- so the reader can close the book and keep playing.
--
--   [book] Elwynn Forest · History   2/5   (queue 3)
--   [<<] [Pause] [>>] [x]
--
-- Drag it anywhere; its place is kept. Click the title to open the page.

local Narrator = {}
ns.Narrator = Narrator

local Theme, Voice = ns.Theme, ns.Voice
local C = Theme.Color
local bar

local function button(parent, label, width, tip, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 20)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(tip, 1, 1, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	return b
end

function Narrator.Update()
	if not bar then return end
	local entry, s = Voice.Current()
	if not entry or not ns.db.settings.narratorBar then
		bar:Hide()
		return
	end
	local section, sections, item, items = Voice.Progress()
	local sc = Voice.Script(entry)
	local sectionTitle = sc[section] and sc[section].section or ""
	local title = entry.title
	if sectionTitle ~= "" and sectionTitle ~= entry.title then title = title .. C("ffaaaaaa", " \194\183 " .. sectionTitle) end
	bar.title:SetText(title)
	local info = string.format("%d/%d", section, sections)
	if items > 1 then info = info .. C("ffaaaaaa", "   " .. string.format(ns.T("page %d of %d"), item, items)) end
	bar.info:SetText(info)
	bar.play:SetText((s.paused or not Voice.IsPlaying()) and ns.T("Play") or ns.T("Pause"))
	bar:Show()
end

local function create()
	bar = CreateFrame("Frame", "LoreverNarratorBar", UIParent)
	bar:SetSize(300, 50)
	bar:SetFrameStrata("MEDIUM")
	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", bar.StartMoving)
	bar:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, rel, x, y = self:GetPoint()
		ns.db.narratorPos = { point, rel, x, y }
	end)
	local pos = ns.db.narratorPos
	if pos then bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180) end
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.85)
	local rule = bar:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.TURQUOISE))
	rule:SetPoint("TOPLEFT")
	rule:SetPoint("TOPRIGHT")
	rule:SetHeight(2)

	local icon = bar:CreateTexture(nil, "ARTWORK")
	icon:SetSize(16, 16)
	icon:SetPoint("TOPLEFT", 6, -6)
	icon:SetTexture(Theme.ICON)
	local titleButton = CreateFrame("Button", nil, bar)
	titleButton:SetPoint("TOPLEFT", icon, "TOPRIGHT", 4, 0)
	titleButton:SetPoint("RIGHT", -60, 0)
	titleButton:SetHeight(16)
	bar.title = titleButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.title:SetAllPoints()
	bar.title:SetJustifyH("LEFT")
	bar.title:SetWordWrap(false)
	titleButton:SetScript("OnClick", function()
		local entry = Voice.Current()
		if entry then ns.QuestLogTab.Open(entry.id) end
	end)
	bar.info = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	bar.info:SetPoint("TOPRIGHT", -6, -8)

	local prev = button(bar, "<<", 36, ns.T("Start of this section (or the one before)"), Voice.Prev)
	prev:SetPoint("BOTTOMLEFT", 6, 6)
	bar.play = button(bar, ns.T("Pause"), 60, ns.T("Pause or resume"), Voice.Toggle)
	bar.play:SetPoint("LEFT", prev, "RIGHT", 4, 0)
	local nextB = button(bar, ">>", 36, ns.T("Next section"), Voice.Next)
	nextB:SetPoint("LEFT", bar.play, "RIGHT", 4, 0)
	local stop = button(bar, ns.T("Stop"), 50, ns.T("Stop and clear the queue"), Voice.Stop)
	stop:SetPoint("BOTTOMRIGHT", -6, 6)
	local voices = button(bar, ns.T("Voice"), 50, ns.T("The narrator panel: voices, styles, speed and tone"), function() ns.NarratorPanel.Toggle() end)
	voices:SetPoint("RIGHT", stop, "LEFT", -4, 0)
	bar:Hide()
	Narrator.bar = bar
end

ns.Listen("FL_LOGIN", function()
	create()
	Narrator.Update()
end)
ns.Listen("FL_NARRATION", function() Narrator.Update() end)
ns.Listen("FL_SETTINGS_CHANGED", function() Narrator.Update() end)
