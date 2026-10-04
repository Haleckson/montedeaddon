local _, ns = ...

-- "Lore Discovered" and "Lore Level" banners, shown one after another.
-- Click a banner to read the entry.

local Toast = {}
ns.Toast = Toast

local Theme, Lore = ns.Theme, ns.Lore
local queue = {}
local frame
local SHOW_TIME = 4

local function build()
	frame = CreateFrame("Button", "LoreverToast", UIParent)
	frame:SetSize(320, 64)
	-- Below the zone name the game shows on entering a land. Shift-drag moves it.
	ns.Movable.Add("toast", frame, UIParent, function(f) f:SetPoint("TOP", UIParent, "TOP", 0, -235) end)
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.88)
	local rule = frame:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.TURQUOISE))
	rule:SetPoint("BOTTOMLEFT")
	rule:SetPoint("BOTTOMRIGHT")
	rule:SetHeight(2)

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetSize(44, 44)
	frame.icon:SetPoint("LEFT", 10, 0)
	frame.icon:SetTexture(Theme.ICON)

	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.label:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 10, -2)
	frame.label:SetTextColor(unpack(Theme.TURQUOISE))
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	frame.title:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -2)
	frame.title:SetPoint("RIGHT", -10, 0)
	frame.title:SetJustifyH("LEFT")
	frame.title:SetWordWrap(false)
	frame.xp = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.xp:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -2)

	local fade = frame:CreateAnimationGroup()
	local out = fade:CreateAnimation("Alpha")
	out:SetFromAlpha(1)
	out:SetToAlpha(0)
	out:SetDuration(0.6)
	out:SetStartDelay(SHOW_TIME)
	fade:SetScript("OnFinished", function()
		frame:Hide()
		Toast.Next()
	end)
	frame.fade = fade

	frame:SetScript("OnClick", function(self)
		if self.entryID then ns.QuestLogTab.Open(self.entryID) end
		self.fade:Stop()
		self:Hide()
		Toast.Next()
	end)
end

function Toast.Next()
	local item = table.remove(queue, 1)
	if not item then return end
	if not frame then build() end
	frame.icon:SetTexture(item.icon or Theme.ICON)
	frame.label:SetText(item.label)
	frame.title:SetText(item.title)
	frame.xp:SetText(item.xp or "")
	frame.entryID = item.entryID
	frame:SetAlpha(1)
	frame:Show()
	frame.fade:Play()
	Theme.PlaySound(item.sound)
end

-- /lorever banner: a sample that stays a while, to drag the banners where you want them.
function Toast.Sample()
	if not frame then build() end
	queue = {}
	frame.icon:SetTexture(Theme.ICON)
	frame.label:SetText(ns.T("Lore Discovered"))
	frame.title:SetText(ns.T("Shift-drag: move the banners"))
	frame.xp:SetText("")
	frame.entryID = nil
	frame.fade:Stop()
	frame:SetAlpha(1)
	frame:Show()
	C_Timer.After(20, function() if frame.entryID == nil and frame:IsShown() and not ns.Movable.IsMoving(frame) then frame:Hide() end end)
end

function Toast.Push(item)
	if not ns.db.settings.toasts then return end
	table.insert(queue, item)
	if not (frame and frame:IsShown()) then Toast.Next() end
end

local N = ns.N
local LABEL = { base = N("Lore Discovered"), chapter = N("New Chapter"), mention = N("New Mention") }

ns.Listen("FL_UNLOCKED", function(_, part, xp, quiet)
	if quiet then return end
	local entry = part.entry
	if part.pool == "books" then
		Toast.Push({ label = ns.T("Book Read"), title = entry.title, xp = string.format(ns.T("+%d Books"), xp), entryID = entry.id, icon = "Interface\\Icons\\INV_Misc_Book_11" })
		return
	end
	local title = entry.title
	if part.kind == "chapter" then title = part.chapter.title .. " \226\128\148 " .. entry.title end
	Toast.Push({ label = ns.T(LABEL[part.kind]), title = title, xp = string.format(ns.T("+%d Lore"), xp), entryID = entry.id })
end)

ns.Listen("FL_LEVEL_UP", function(_, level, _, quiet, pool)
	if quiet then return end
	if pool == "books" then
		Toast.Push({ label = ns.T("Your Library Grows"), title = string.format(ns.T("Books Level %d"), level), sound = "level", icon = "Interface\\Icons\\INV_Misc_Book_11" })
	else
		Toast.Push({ label = ns.T("Your Knowledge Grows"), title = string.format(ns.T("Lore Level %d"), level), sound = "level" })
	end
end)

ns.Listen("FL_CAUGHT_UP", function(_, gained)
	ns.Print(string.format(ns.T("Your past deeds revealed lore worth %d experience. Lore Level %d."), gained, (ns.Progress.Level())))
end)
