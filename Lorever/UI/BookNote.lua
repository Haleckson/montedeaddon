local _, ns = ...

-- A small note beside the game's book window, while a writing is open:
--   "Lorever: 3 of 6 pages kept. Turn the pages to keep the rest."
-- Lorever never turns a page itself: it keeps each page the reader sees
-- (COMPLIANCE.md, R3: no automation). The note only tells how many are kept.
-- Click it to open the writing's page in Lorever.

local BookNote = {}
ns.BookNote = BookNote

local Theme, Library = ns.Theme, ns.Library
local note

local function build()
	note = CreateFrame("Button", "LoreverBookNote", UIParent)
	note:SetSize(250, 34)
	note:SetFrameStrata("HIGH")
	ns.Movable.Add("bookNote", note, UIParent, function(f)
		if ItemTextFrame then
			f:SetPoint("TOPLEFT", ItemTextFrame, "TOPRIGHT", 2, -36)
		else
			f:SetPoint("CENTER", UIParent, "CENTER", 260, 160)
		end
	end)
	local bg = note:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.88)
	local rule = note:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.TURQUOISE))
	rule:SetPoint("TOPLEFT")
	rule:SetPoint("BOTTOMLEFT")
	rule:SetWidth(2)
	note.icon = note:CreateTexture(nil, "ARTWORK")
	note.icon:SetSize(18, 18)
	note.icon:SetPoint("LEFT", 6, 0)
	note.icon:SetTexture(Theme.ICON)
	note.text = note:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	note.text:SetPoint("LEFT", note.icon, "RIGHT", 6, 0)
	note.text:SetPoint("RIGHT", -6, 0)
	note.text:SetJustifyH("LEFT")
	note:RegisterForClicks("LeftButtonUp")
	note:SetScript("OnClick", function(self)
		if self.entry then ns.Window.Show(self.entry.id) end
	end)
	note:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Lorever", unpack(Theme.TURQUOISE))
		GameTooltip:AddLine(ns.T("Lorever keeps each page you see, so you can read or hear this writing later. It never turns a page for you."), 1, 1, 1, true)
		GameTooltip:AddLine(ns.T("Click: open the lore page"), 0.8, 0.8, 0.8)
		GameTooltip:AddLine(ns.Movable.Tip(), 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	note:SetScript("OnLeave", GameTooltip_Hide)
	note:Hide()
end

-- The text of the note for a writing: how many of its pages are kept.
function BookNote.Text(book)
	local kept, total = Library.PageCount(book)
	if total and total > 0 then
		if kept >= total then return string.format(ns.T("All %d pages kept."), total) end
		return string.format(ns.T("%d of %d pages kept. Turn the pages to keep the rest."), kept, total)
	end
	return string.format(ns.T("%d pages kept."), kept)
end

function BookNote.Update()
	local book = Library.reading
	if not book or not ns.db.settings.bookNote then
		if note then note:Hide() end
		return
	end
	if not note then build() end
	note.entry = book
	note.text:SetText(BookNote.Text(book))
	note:Show()
end

ns.Listen("FL_TEXT_KEPT", BookNote.Update)
ns.On("ITEM_TEXT_CLOSED", function() if note then note:Hide() end end)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key) if key == "bookNote" then BookNote.Update() end end)
