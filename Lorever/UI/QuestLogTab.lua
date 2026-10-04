local _, ns = ...

-- A "Lore" tab beside the quest log (in Forever the quest log lives in the
-- world map, QuestMapFrame).
--
-- It never writes into Blizzard's frames, tables or modes: writing there can
-- "taint" the interface and make the game block protected actions (such as
-- marking a target). So the tab is our own button, and the page is our own
-- frame laid over the quest list. It closes when the reader clicks one of
-- Blizzard's tabs, opens a quest, or closes the map (hooks only, read-only).
-- If anything is missing, a small book button on the map opens the lore window.

local Q = {}
ns.QuestLogTab = Q

local ICON = ns.Theme.ICON

function Q.IsOpen()
	return Q.page ~= nil and Q.page:IsShown() and QuestMapFrame ~= nil and QuestMapFrame:IsVisible()
end

function Q.Close()
	if Q.page then Q.page:Hide() end
end

local function addTab()
	local qm = QuestMapFrame
	if not (qm and qm.QuestsFrame) then
		return false, ns.T("quest log not found")
	end

	local page = CreateFrame("Frame", nil, qm)
	page:SetAllPoints(qm.QuestsFrame)
	page:SetFrameLevel((qm.QuestsFrame.GetFrameLevel and qm.QuestsFrame:GetFrameLevel() or 1) + 20)
	page:EnableMouse(true) -- the quest list under it stays out of reach while it is open
	page:Hide()
	Q.page = page
	Q.panel = ns.Panel.Create(page)

	local tab = CreateFrame("Button", nil, qm)
	tab:SetSize(32, 32)
	ns.Movable.Add("questLogTab", tab, qm, function(f)
		if qm.QuestsTab then
			f:SetPoint("TOP", qm.QuestsTab, "BOTTOM", 0, -3)
		else
			f:SetPoint("TOPLEFT", qm, "TOPRIGHT", 2, -40)
		end
	end)
	tab:SetNormalTexture(ICON)
	tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	tab:SetScript("OnClick", function() page:SetShown(not page:IsShown()) end)
	tab:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(ns.T("Lore"))
		GameTooltip:AddLine(ns.T("The book of lore. Click again to return to your quests."), 1, 1, 1, true)
		GameTooltip:AddLine(ns.Movable.Tip(), 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	tab:SetScript("OnLeave", GameTooltip_Hide)
	Q.tab = tab

	-- Blizzard's own tabs, a quest opened, or the map closed: the quest log comes back.
	for _, b in ipairs(qm.TabButtons or {}) do
		if b ~= tab and b.HookScript then b:HookScript("OnMouseUp", Q.Close) end
	end
	if qm.HookScript then qm:HookScript("OnHide", Q.Close) end
	if QuestMapFrame_ShowQuestDetails then hooksecurefunc("QuestMapFrame_ShowQuestDetails", Q.Close) end
	return true
end

local function addMapButton()
	if Q.button or not WorldMapFrame then return end
	local parent = type(WorldMapFrame.BorderFrame) == "table" and WorldMapFrame.BorderFrame or WorldMapFrame
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(28, 28)
	ns.Movable.Add("mapBookButton", b, parent, function(f) f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -64, -2) end)
	b:SetNormalTexture(ICON)
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetScript("OnClick", function() ns.Window.Toggle() end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Lorever")
		GameTooltip:AddLine(ns.T("Open the book of lore."), 1, 1, 1)
		GameTooltip:AddLine(ns.Movable.Tip(), 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	Q.button = b
end

-- Opens a page: on the Lore tab when the map is already open, else in the
-- Lorever window. The add-on never opens Blizzard's map or panels itself.
function Q.Open(entryID)
	if Q.page and QuestMapFrame and QuestMapFrame:IsVisible() then
		Q.page:Show()
		if entryID then Q.panel:Open(entryID) else Q.panel:Refresh() end
		return
	end
	ns.Window.Show(entryID)
end

ns.Listen("FL_LOGIN", function()
	local ok, result, reason = false, nil, nil
	if ns.db.settings.questLogTab then
		ok, result, reason = pcall(addTab)
		if ok and not result then ok = false end
	end
	if not ok and ns.db.settings.questLogTab then
		ns.Print(string.format(ns.T("The Lore tab could not join the quest log (%s). Use the book on the map or /lorever."), tostring(reason or result)))
	end
	if not Q.tab then addMapButton() end
end)
