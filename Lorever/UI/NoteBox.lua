local _, ns = ...

-- A small window of our own to write a note on a page. It is not one of the
-- game's popups: the add-on puts nothing into Blizzard's dialog tables
-- (COMPLIANCE.md, R3). The note stays on the reader's computer.

local NoteBox = {}
ns.NoteBox = NoteBox

local Theme = ns.Theme
local frame

local function button(parent, label, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(90, 22)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	return b
end

function NoteBox.Save()
	if not frame or not frame.entryID then return end
	ns.Journal.SetNote(frame.entryID, frame.edit:GetText() or "")
	frame:Hide()
end

local function build()
	frame = CreateFrame("Frame", "LoreverNoteBox", UIParent)
	frame:SetSize(340, 190)
	frame:SetPoint("CENTER", 0, 80)
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.96)
	local rule = frame:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.TURQUOISE))
	rule:SetPoint("TOPLEFT")
	rule:SetPoint("TOPRIGHT")
	rule:SetHeight(2)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.title:SetPoint("TOPLEFT", 12, -12)
	frame.title:SetPoint("RIGHT", -12, 0)
	frame.title:SetJustifyH("LEFT")
	frame.title:SetWordWrap(false)
	frame.title:SetTextColor(unpack(Theme.TURQUOISE))

	local well = frame:CreateTexture(nil, "ARTWORK")
	well:SetColorTexture(0, 0, 0, 0.5)
	well:SetPoint("TOPLEFT", 10, -34)
	well:SetPoint("BOTTOMRIGHT", -10, 56)

	local edit = CreateFrame("EditBox", nil, frame)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFontObject("ChatFontNormal")
	edit:SetMaxLetters(ns.Journal.NOTE_MAX)
	edit:SetPoint("TOPLEFT", well, "TOPLEFT", 6, -6)
	edit:SetPoint("BOTTOMRIGHT", well, "BOTTOMRIGHT", -6, 6)
	edit:SetScript("OnEscapePressed", function() frame:Hide() end)
	frame.edit = edit

	frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.hint:SetPoint("BOTTOMLEFT", 12, 38)
	frame.hint:SetText(ns.T("Only you see this note. Leave it empty to remove it."))

	local cancel = button(frame, ns.T("Cancel"), function() frame:Hide() end)
	cancel:SetPoint("BOTTOMRIGHT", -10, 10)
	local save = button(frame, ns.T("Save"), NoteBox.Save)
	save:SetPoint("RIGHT", cancel, "LEFT", -6, 0)
	frame:Hide()
	NoteBox.frame = frame
end

function NoteBox.Open(entry)
	if not frame then build() end
	frame.entryID = entry.id
	frame.title:SetText(string.format(ns.T("Your note on %s"), entry.title))
	frame.edit:SetText(ns.Journal.Note(entry.id) or "")
	frame:Show()
	frame.edit:SetFocus()
end
