local _, ns = ...

-- Lore beside the game's own windows:
-- - quest windows (the quest giver's and the quest log's) say which lore the
--   quest reveals: "Turning this in reveals a chapter of Marshal Dughan";
-- - item tooltips of books, letters and journals say whether they were read;
-- - the tooltip of a book, plaque or stone in the world says the same.

local QuestLore = {}
ns.QuestLore = QuestLore

local Lore, P, Theme, Library = ns.Lore, ns.Progress, ns.Theme, ns.Library
local C = Theme.Color

-- Quest ---------------------------------------------------------------------------------

-- Lines for a quest: what completing it reveals that the reader has not found yet.
function QuestLore.Lines(questID)
	local out, seen = {}, {}
	for _, part in ipairs(Lore.index.quest[questID] or {}) do
		local entry = part.entry
		if not P.IsFound(part.key) and not seen[part.key] then
			seen[part.key] = true
			local text
			if part.kind == "chapter" then
				text = string.format(ns.T("reveals a chapter of %s"), entry.title)
			elseif part.kind == "mention" then
				text = string.format(ns.T("adds to the story of %s"), entry.title)
			elseif entry.kind == "book" then
				text = string.format(ns.T("opens %s in your library"), entry.title)
			else
				text = string.format(ns.T("reveals the lore of %s"), entry.title)
			end
			out[#out + 1] = { text = text, entry = entry }
		end
	end
	return out
end

local badges = {}

-- A small turquoise note beside a quest window. Click it to read the page.
local function badge(host)
	local b = badges[host]
	if b then return b end
	b = CreateFrame("Button", nil, host)
	b:SetSize(210, 20)
	b:SetPoint("TOPLEFT", host, "TOPRIGHT", 2, -36)
	b:SetFrameStrata("HIGH")
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.08, 0.07, 0.05, 0.88)
	local rule = b:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.TURQUOISE))
	rule:SetPoint("TOPLEFT")
	rule:SetPoint("BOTTOMLEFT")
	rule:SetWidth(2)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(14, 14)
	b.icon:SetPoint("LEFT", 6, 0)
	Theme.Marker(b.icon)
	b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.text:SetPoint("LEFT", b.icon, "RIGHT", 4, 0)
	b.text:SetPoint("RIGHT", -6, 0)
	b.text:SetJustifyH("LEFT")
	b:SetScript("OnClick", function(self)
		if self.entry and P.IsUnlocked(self.entry.id) then ns.QuestLogTab.Open(self.entry.id) end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Lorever", unpack(Theme.TURQUOISE))
		for _, line in ipairs(self.lines or {}) do GameTooltip:AddLine(string.format(ns.T("Completing this quest %s."), line.text), 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	badges[host] = b
	return b
end

function QuestLore.Show(host, questID)
	if not host then return end
	local lines = ns.db.settings.questLore and questID and QuestLore.Lines(questID) or {}
	if #lines == 0 then
		if badges[host] then badges[host]:Hide() end
		return
	end
	local b = badge(host)
	b.lines, b.entry = lines, lines[1].entry
	local text = ns.T("Lore:") .. " " .. lines[1].entry.title
	if #lines > 1 then text = text .. C("ffaaaaaa", " " .. string.format(ns.T("and %d more"), #lines - 1)) end
	b.text:SetText(text)
	b:Show()
	return b
end

local function questGiverShown()
	local id = GetQuestID and GetQuestID()
	QuestLore.Show(QuestFrame, id)
end
ns.On("QUEST_DETAIL", questGiverShown)
ns.On("QUEST_PROGRESS", questGiverShown)
ns.On("QUEST_COMPLETE", questGiverShown)
ns.On("QUEST_FINISHED", function() if badges[QuestFrame] then badges[QuestFrame]:Hide() end end)

ns.Listen("FL_LOGIN", function()
	-- The quest log's details, beside the map.
	local details = QuestMapFrame and QuestMapFrame.DetailsFrame
	if details and _G.QuestMapFrame_ShowQuestDetails then
		hooksecurefunc("QuestMapFrame_ShowQuestDetails", function(questID) QuestLore.Show(details, questID) end)
		if details.HookScript then
			details:HookScript("OnHide", function() if badges[details] then badges[details]:Hide() end end)
		end
	end
end)

-- Tooltips --------------------------------------------------------------------------------

local byItem, byTitle
local function indexes()
	if byItem then return byItem, byTitle end
	byItem, byTitle = {}, {}
	for _, book in ipairs(Lore.books) do
		for _, id in ipairs(book.items or {}) do byItem[id] = book end
		for _, title in ipairs(Library.Titles(book)) do byTitle[title] = book end
	end
	return byItem, byTitle
end
function QuestLore.BookForItem(itemID) return (indexes())[itemID] end
function QuestLore.BookForTitle(title) return select(2, indexes())[title] end

function QuestLore.TooltipLine(book)
	local kind = ns.T(Library.Category(book).one)
	if P.IsFound(book.id) then
		return C(Theme.TURQUOISE_HEX, "Lorever: ") .. string.format(ns.T("%s, read"), kind)
	end
	local xp = Lore.Part(book.id) and Lore.Part(book.id).xp or 0
	return C(Theme.TURQUOISE_HEX, "Lorever: ") .. string.format(ns.T("%s, not yet read"), kind) .. " "
		.. C("ffaaaaaa", string.format(ns.T("(+%d Literature)"), xp))
end

local function onItem(tooltip, data)
	if not ns.db.settings.itemTooltip then return end
	local id = data and data.id
	local book = id and QuestLore.BookForItem(id)
	if book then tooltip:AddLine(QuestLore.TooltipLine(book)) end
end

-- A book, plaque or stone in the world: its tooltip is a single title line.
local function onWorldTooltip(tooltip)
	if not ns.db.settings.itemTooltip or tooltip:GetUnit() or (tooltip.GetItem and tooltip:GetItem()) then return end
	local line = _G[tooltip:GetName() .. "TextLeft1"]
	local title = line and line:GetText()
	if not title or ns.U.IsSecret(title) then return end
	local book = QuestLore.BookForTitle(title)
	if book and book.objects then
		tooltip:AddLine(QuestLore.TooltipLine(book))
		tooltip:Show()
	end
end

ns.Listen("FL_LOGIN", function()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItem)
	end
	if GameTooltip and GameTooltip.HookScript and GameTooltip.GetName then
		GameTooltip:HookScript("OnShow", onWorldTooltip)
	end
end)
