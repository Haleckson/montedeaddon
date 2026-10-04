local _, ns = ...

-- The Lorever panel: an encyclopedia of Azeroth and a library of its Literature.
--
-- Header (always visible):
--   back / forward / home            [Lore] [Literature]
--   Lore  level  [==== experience ====]
--   Literature level  [==== experience ====]
--   Lore pages:  Here | Regions | Categories | A-Z
--   Literature pages:  By Region | Missing | Read | Unlisted, filtered by kind
-- Body: an index page or one entry. Every name in the text is a link.
-- It can live in any parent: the quest log tab or the standalone window.

local Panel = {}
Panel.__index = Panel
ns.Panel = Panel

local Lore, P, Theme = ns.Lore, ns.Progress, ns.Theme
local R = Theme.Render
local C = Theme.Color

local ROW_H = 20
local PAD = 12
local NAV = 22
local HEADER_H = 100
local BOOK_ICON = "Interface\\Icons\\INV_Misc_Book_11"
local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:0|t"
-- The frame the game draws around its own bars (also on tabs and headings in some looks).
local GAME_BORDER = "Interface\\Tooltips\\UI-StatusBar-Border"
-- How far inside that frame its color starts: clear of the frame's round ends.
local INSET_X, INSET_Y = 5, 2

local N = ns.N
Panel.SECTIONS = {
	lore = {
		label = N("Lore"),
		home = "@here",
		pages = {
			{ id = "@here", label = N("Here") },
			{ id = "@regions", label = N("Regions") },
			{ id = "@categories", label = N("Categories") },
			{ id = "@az", label = N("A\226\128\147Z") },
		},
	},
	books = {
		label = N("Literature"),
		home = "@books",
		pages = {
			{ id = "@books", label = N("By Region") },
			{ id = "@books-missing", label = N("Missing") },
			{ id = "@books-read", label = N("Read") },
			{ id = "@books-unlisted", label = N("Unlisted") },
		},
	},
}

-- Which section a page belongs to.
function Panel.SectionOf(id)
	if id:sub(1, 6) == "@books" or id:sub(1, 6) == "@text:" then return "books" end
	local entry = Lore.Get(id)
	if entry and entry.kind == "book" then return "books" end
	return "lore"
end

-- Layout: stacks headings, text and rows down a scroll child ----------------------

local Layout = {}
Layout.__index = Layout

local function newLayout(content)
	return setmetatable({ content = content, y = 0, fonts = {}, rows = {}, nf = 0, nr = 0 }, Layout)
end

function Layout:Reset()
	for _, fs in ipairs(self.fonts) do fs:Hide() end
	for _, row in ipairs(self.rows) do row:Hide() end
	for _, bar in ipairs(self.bars or {}) do
		bar.edge:Hide()
		bar.fill:Hide()
		bar.border:Hide()
	end
	self.nf, self.nr, self.nb, self.y = 0, 0, 0, PAD
end

function Layout:Width()
	return math.max(120, (self.content:GetWidth() or 0) - PAD * 2)
end

function Layout:Font(fontObject)
	self.nf = self.nf + 1
	local fs = self.fonts[self.nf]
	if not fs then
		fs = self.content:CreateFontString(nil, "OVERLAY")
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(true)
		self.fonts[self.nf] = fs
	end
	fs:SetFontObject(fontObject)
	fs:SetTextColor(unpack(Theme.INK))
	fs:SetWidth(self:Width())
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD, -self.y)
	fs:Show()
	return fs
end

function Layout:Text(text, fontObject, gap)
	local fs = self:Font(fontObject or Theme.FONT_BODY)
	fs:SetText(text)
	self.y = self.y + (fs:GetStringHeight() or 14) + (gap or 8)
	return fs
end

function Layout:Heading(text)
	self.y = self.y + 4
	if not Theme.HEADING_BAR then return self:Text(C(Theme.HEADING, text), Theme.FONT_TITLE, 4) end
	-- A bar behind the heading (the "axell" look).
	self.nb = (self.nb or 0) + 1
	self.bars = self.bars or {}
	local bar = self.bars[self.nb]
	if not bar then
		bar = { edge = self.content:CreateTexture(nil, "BACKGROUND", nil, 1), fill = self.content:CreateTexture(nil, "BACKGROUND", nil, 2) }
		bar.border = self.content:CreateTexture(nil, "BORDER")
		bar.border:SetTexture(GAME_BORDER)
		bar.border:SetPoint("TOPLEFT", bar.edge, "TOPLEFT", -2, 2)
		bar.border:SetPoint("BOTTOMRIGHT", bar.edge, "BOTTOMRIGHT", 2, -2)
		self.bars[self.nb] = bar
	end
	local top = self.y
	self.y = self.y + 4
	local fs = self:Text(C(Theme.HEADING, text), Theme.FONT_TITLE, 4)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD + 8, -(top + 4))
	fs:SetWidth(self:Width() - 16)
	local height = (fs:GetStringHeight() or 14) + 8
	bar.edge:ClearAllPoints()
	bar.edge:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD - 2, -top)
	bar.edge:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -(PAD - 2), -top)
	bar.edge:SetHeight(height)
	-- With the game's frame around it, the bar needs no line of its own, and the
	-- color sits inside the frame's round ends (as on the experience bars).
	local inX, inY = 1, 1
	if Theme.GAME_BORDER then
		bar.edge:SetColorTexture(0, 0, 0, 0)
		inX, inY = INSET_X, INSET_Y
	else
		bar.edge:SetColorTexture(unpack(Theme.HEADING_BAR_EDGE))
	end
	bar.fill:ClearAllPoints()
	bar.fill:SetPoint("TOPLEFT", bar.edge, "TOPLEFT", inX, -inY)
	bar.fill:SetPoint("BOTTOMRIGHT", bar.edge, "BOTTOMRIGHT", -inX, inY)
	bar.fill:SetColorTexture(unpack(Theme.HEADING_BAR))
	bar.edge:Show()
	bar.fill:Show()
	bar.border:SetShown(Theme.GAME_BORDER or false)
	self.y = top + height + 6
	return fs
end

function Layout:Space(h)
	self.y = self.y + (h or 6)
end

-- opts: icon, iconLocked, left, right, new, indent, onClick, onEnter
function Layout:Row(opts)
	self.nr = self.nr + 1
	local row = self.rows[self.nr]
	if not row then
		row = CreateFrame("Button", nil, self.content)
		row:SetHeight(ROW_H)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(ROW_H - 4, ROW_H - 4)
		row.icon:SetPoint("LEFT", 2, 0)
		row.new = row:CreateTexture(nil, "OVERLAY")
		row.new:SetSize(ROW_H - 2, ROW_H - 2)
		row.new:SetPoint("RIGHT", -2, 0)
		Theme.Marker(row.new)
		row.right = row:CreateFontString(nil, "OVERLAY", Theme.FONT_SMALL)
		row.right:SetPoint("RIGHT", row.new, "LEFT", -2, 0)
		row.left = row:CreateFontString(nil, "OVERLAY", Theme.FONT_BODY)
		row.left:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
		row.left:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
		row.left:SetJustifyH("LEFT")
		row.left:SetWordWrap(false)
		row:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
		row:SetScript("OnEnter", function(self) if self.onEnter then self.onEnter(self) end end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		self.rows[self.nr] = row
	end
	row:ClearAllPoints()
	local indent = opts.indent or 0
	row:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD - 2 + indent, -self.y)
	row:SetWidth(self:Width() + 4 - indent)
	row.icon:SetTexture(opts.icon or Theme.ICON)
	row.icon:SetDesaturated(opts.iconLocked or false)
	row.icon:SetAlpha(opts.iconLocked and 0.5 or 1)
	row.left:SetText(opts.left or "")
	row.left:SetTextColor(unpack(Theme.INK))
	row.right:SetText(opts.right or "")
	row.right:SetTextColor(unpack(Theme.INK))
	row.new:SetShown(opts.new or false)
	row.onClick, row.onEnter = opts.onClick, opts.onEnter
	row:Show()
	self.y = self.y + ROW_H + 2
	return row
end

function Layout:Finish()
	self.content:SetHeight(self.y + PAD)
end

-- Helpers --------------------------------------------------------------------------

local function tooltipLines(owner, title, lines)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(title, 1, 1, 1)
	for _, line in ipairs(lines) do GameTooltip:AddLine(line, nil, nil, nil, true) end
	GameTooltip:Show()
end

local function firstSentence(entry)
	local section = entry.sections and entry.sections[1]
	if not section then return nil end
	local text = Theme.Plain(section.text)
	local sentence = text:match("^(.-[%.!?])%s") or text
	if #sentence > 220 then sentence = sentence:sub(1, 217) .. "..." end
	return sentence
end

local function whereText(book)
	local pin = book.pin or (book.pins and book.pins[1])
	local text = book.found or ""
	if pin then text = text .. string.format(" %.1f, %.1f", pin.x, pin.y) end
	return text
end

-- Tooltip preview of any page, as when hovering a link.
function Panel.Preview(owner, id)
	local entry = Lore.Get(id)
	if not entry then
		tooltipLines(owner, Theme.TitleFromID(id), { ns.T("This page has not yet been written.") })
		return
	end
	local lines = {}
	if entry.subtitle then lines[#lines + 1] = entry.subtitle end
	if entry.kind == "book" then
		local kind = ns.T(ns.Library.Category(entry).one)
		lines[#lines + 1] = C(Theme.TURQUOISE_HEX, string.format(P.IsUnlocked(id) and ns.T("%s \194\183 read") or ns.T("%s \194\183 not yet read"), kind))
		lines[#lines + 1] = ns.T("Found:") .. " " .. whereText(entry)
		tooltipLines(owner, entry.title, lines)
		return
	end
	local cat = Lore.CategoryOf(entry)
	if cat then lines[#lines + 1] = C(Theme.TURQUOISE_HEX, ns.T(cat.label)) end
	if P.IsUnlocked(id) then
		lines[#lines + 1] = firstSentence(entry) or ""
	else
		lines[#lines + 1] = ns.T("Undiscovered.") .. " " .. Theme.Plain(Lore.Hint(entry))
	end
	tooltipLines(owner, entry.title, lines)
end

-- What changes with the look of the book (Theme.Apply): edges and fixed labels.
local edges, inks, panels, tabs = {}, {}, {}, {}

local function edge(parent, point1, point2, horizontal)
	local t = parent:CreateTexture(nil, "BORDER")
	t:SetColorTexture(unpack(Theme.PARCHMENT_EDGE))
	t:SetPoint(point1)
	t:SetPoint(point2)
	if horizontal then t:SetHeight(2) else t:SetWidth(2) end
	edges[#edges + 1] = t
end

local function navButton(parent, texture, tip, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(NAV, NAV)
	b:SetNormalTexture(texture)
	b:SetPushedTexture((texture:gsub("%-Up$", "-Down")))
	b:SetDisabledTexture((texture:gsub("%-Up$", "-Disabled")))
	b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(tip, 1, 1, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	return b
end

-- The box around a tab (only the looks that ask for one), and its line.
local function paintTab(tab)
	local boxed = Theme.TAB_BOX ~= nil
	tab.box:SetShown(boxed)
	tab.boxEdge:SetShown(boxed)
	tab.border:SetShown(boxed and Theme.GAME_BORDER or false)
	if boxed then
		local inX, inY = 1, 1
		if Theme.GAME_BORDER then
			tab.boxEdge:SetColorTexture(0, 0, 0, 0)
			inX, inY = INSET_X, INSET_Y
		else
			tab.boxEdge:SetColorTexture(unpack(Theme.TAB_EDGE))
		end
		tab.box:SetColorTexture(unpack(Theme.TAB_BOX))
		tab.box:ClearAllPoints()
		tab.box:SetPoint("TOPLEFT", inX, -inY)
		tab.box:SetPoint("BOTTOMRIGHT", -inX, inY)
	end
	tab.line:SetColorTexture(unpack(Theme.ACCENT))
end

-- A text tab with an underline when selected.
local function textTab(parent, label, onClick)
	local tab = CreateFrame("Button", nil, parent)
	tab:SetHeight(18)
	tab.text = tab:CreateFontString(nil, "OVERLAY", Theme.FONT_SMALL)
	tab.text:SetPoint("CENTER")
	tab.text:SetText(label)
	tab.text:SetTextColor(unpack(Theme.INK))
	inks[#inks + 1] = tab.text
	tab:SetWidth(math.max(44, (tab.text:GetStringWidth() or 40) + 14))
	tab.boxEdge = tab:CreateTexture(nil, "BACKGROUND", nil, 1)
	tab.boxEdge:SetAllPoints()
	tab.box = tab:CreateTexture(nil, "BACKGROUND", nil, 2)
	tab.box:SetPoint("TOPLEFT", 1, -1)
	tab.box:SetPoint("BOTTOMRIGHT", -1, 1)
	tab.border = tab:CreateTexture(nil, "BORDER")
	tab.border:SetTexture(GAME_BORDER)
	tab.border:SetPoint("TOPLEFT", -2, 2)
	tab.border:SetPoint("BOTTOMRIGHT", 2, -2)
	tab.line = tab:CreateTexture(nil, "ARTWORK")
	tab.line:SetColorTexture(unpack(Theme.ACCENT))
	tabs[#tabs + 1] = tab
	paintTab(tab)
	tab.line:SetPoint("BOTTOMLEFT")
	tab.line:SetPoint("BOTTOMRIGHT")
	tab.line:SetHeight(2)
	tab:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	tab:SetScript("OnClick", onClick)
	return tab
end

-- One experience bar: "Lore 3  [=====]  120 / 155".
local function xpBar(parent, y, pool, label, color)
	local text = parent:CreateFontString(nil, "OVERLAY", Theme.FONT_SMALL)
	text:SetPoint("TOPLEFT", PAD, y)
	text:SetWidth(84)
	text:SetJustifyH("LEFT")
	text:SetTextColor(unpack(Theme.INK))
	inks[#inks + 1] = text
	-- The frame and the dark ground keep the full size; the colored part sits
	-- a little inside them, so it never shows past the frame's round ends.
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetPoint("TOPLEFT", PAD + 86, y + 1)
	holder:SetPoint("TOPRIGHT", -PAD, y + 1)
	holder:SetHeight(13)
	local bg = holder:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.15, 0.12, 0.08, 0.85)
	local bar = CreateFrame("StatusBar", nil, holder)
	bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 3, -1)
	bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -3, 1)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetStatusBarColor(unpack(color))
	local border = bar:CreateTexture(nil, "OVERLAY")
	border:SetTexture(GAME_BORDER)
	border:SetPoint("TOPLEFT", holder, "TOPLEFT", -3, 3)
	border:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 3, -3)
	bar.border = border
	bar.value = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.value:SetPoint("CENTER")
	bar:EnableMouse(true)
	bar:SetScript("OnEnter", function(b)
		local level, into, need = P.Level(pool)
		local found, total = P.Totals(pool)
		tooltipLines(b, string.format(ns.T("%s Level %d"), label, level), {
			string.format(ns.T("%d / %d experience toward level %d."), into, need, level + 1),
			string.format(ns.T("%d experience earned in all."), P.TotalXP(pool)),
			string.format(pool == "books" and ns.T("%d of %d writings read.") or ns.T("%d of %d pages discovered."), found, total),
		})
	end)
	bar:SetScript("OnLeave", GameTooltip_Hide)
	function bar:Update()
		local level, into, need = P.Level(pool)
		text:SetText(label .. " " .. level)
		self:SetMinMaxValues(0, need)
		self:SetValue(into)
		self.value:SetText(into .. " / " .. need)
	end
	return bar
end

Panel.BOOK_COLOR = { 0.85, 0.65, 0.25 }

-- Panel -------------------------------------------------------------------------

function Panel.Create(parent)
	local self = setmetatable({
		parent = parent, current = "@here", back = {}, forward = {},
		openCats = {}, queries = { lore = "", books = "" }, subTabs = {},
	}, Panel)

	local root = CreateFrame("Frame", nil, parent)
	root:SetAllPoints(parent)
	self.root = root

	local bg = root:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetAllPoints()
	bg:SetColorTexture(unpack(Theme.PARCHMENT))
	-- The game's own parchment, over the plain color, for the looks that name one.
	-- The parchment has a size of its own: it keeps its shape across the page's
	-- width, and a mirrored copy carries it on to the bottom (no stretching).
	local art = root:CreateTexture(nil, "BACKGROUND", nil, -7)
	local art2 = root:CreateTexture(nil, "BACKGROUND", nil, -7)
	art:Hide()
	art2:Hide()
	self.bg, self.art, self.art2 = bg, art, art2
	root:SetScript("OnSizeChanged", function() self:LayArt() end)
	edge(root, "TOPLEFT", "TOPRIGHT", true)
	edge(root, "BOTTOMLEFT", "BOTTOMRIGHT", true)
	edge(root, "TOPLEFT", "BOTTOMLEFT", false)
	edge(root, "TOPRIGHT", "BOTTOMRIGHT", false)

	-- Row 1: navigation, and the Lore / Books switch.
	self.backButton = navButton(root, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", ns.T("Back"), function() self:Back() end)
	self.backButton:SetPoint("TOPLEFT", PAD - 4, -5)
	self.forwardButton = navButton(root, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", ns.T("Forward"), function() self:Forward() end)
	self.forwardButton:SetPoint("LEFT", self.backButton, "RIGHT", 0, 0)
	local home = CreateFrame("Button", nil, root)
	home:SetSize(NAV - 2, NAV - 2)
	home:SetPoint("LEFT", self.forwardButton, "RIGHT", 4, 0)
	home:SetNormalTexture(Theme.ICON)
	home:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	home:SetScript("OnClick", function() self:Open(Panel.SECTIONS[Panel.SectionOf(self.current)].home) end)
	home:SetScript("OnEnter", function(b) tooltipLines(b, ns.T("Home"), { ns.T("Return to the first page of this book.") }) end)
	home:SetScript("OnLeave", GameTooltip_Hide)

	self.sectionTabs = {}
	local booksTab = textTab(root, ns.T(Panel.SECTIONS.books.label), function() self:Open(Panel.SECTIONS.books.home) end)
	booksTab:SetPoint("TOPRIGHT", -PAD, -8)
	local loreTab = textTab(root, ns.T(Panel.SECTIONS.lore.label), function() self:Open(Panel.SECTIONS.lore.home) end)
	loreTab:SetPoint("RIGHT", booksTab, "LEFT", -6, 0)
	self.sectionTabs.lore, self.sectionTabs.books = loreTab, booksTab

	-- Rows 2 and 3: both experience bars, always visible.
	self.loreBar = xpBar(root, -32, "lore", ns.T(Panel.SECTIONS.lore.label), Theme.TURQUOISE)
	self.bookBar = xpBar(root, -50, "books", ns.T(Panel.SECTIONS.books.label), Panel.BOOK_COLOR)

	-- Row 4: pages of the current section.
	for key, section in pairs(Panel.SECTIONS) do
		local tabs, prev = {}, nil
		for _, page in ipairs(section.pages) do
			local tab = textTab(root, ns.T(page.label), function() self:Open(page.id) end)
			if prev then tab:SetPoint("LEFT", prev, "RIGHT", 6, 0) else tab:SetPoint("TOPLEFT", PAD - 4, -72) end
			tab.pageID = page.id
			tabs[#tabs + 1] = tab
			prev = tab
		end
		self.subTabs[key] = tabs
	end

	local rule = root:CreateTexture(nil, "BORDER")
	rule:SetColorTexture(unpack(Theme.PARCHMENT_EDGE))
	edges[#edges + 1] = rule
	rule:SetPoint("TOPLEFT", PAD, -(HEADER_H - 7))
	rule:SetPoint("TOPRIGHT", -PAD, -(HEADER_H - 7))
	rule:SetHeight(1)

	-- Body.
	local scroll = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -(HEADER_H - 4))
	scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -26, 6)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll:SetScript("OnSizeChanged", function(_, w)
		content:SetWidth(w)
		self:Render()
	end)
	self.scroll, self.content = scroll, content
	self.layout = newLayout(content)

	-- Links inside the text.
	content:SetHyperlinksEnabled(true)
	content:SetScript("OnHyperlinkClick", function(_, link)
		local id = Theme.LinkTarget(link)
		if id then self:Open(id, true) end
	end)
	content:SetScript("OnHyperlinkEnter", function(frame, link)
		local id = Theme.LinkTarget(link)
		if id then Panel.Preview(frame, id) end
	end)
	content:SetScript("OnHyperlinkLeave", GameTooltip_Hide)

	-- Search box for the A-Z page.
	local search = CreateFrame("EditBox", nil, content, "SearchBoxTemplate")
	search:SetSize(200, 20)
	search:SetAutoFocus(false)
	search:HookScript("OnTextChanged", function(box)
		local text = box:GetText() or ""
		local key = self.searchKey or "lore"
		if text ~= self.queries[key] then
			self.queries[key] = text
			self:Render()
		end
	end)
	search:Hide()
	self.search = search

	root:SetScript("OnShow", function() self:Refresh() end)
	Panel.instances = Panel.instances or {}
	table.insert(Panel.instances, self)
	panels[#panels + 1] = self
	self:Paint()
	return self
end

function Panel:UpdateHeader()
	self.loreBar:Update()
	self.bookBar:Update()
	self.backButton:SetEnabled(#self.back > 0)
	self.forwardButton:SetEnabled(#self.forward > 0)
	local section = Panel.SectionOf(self.current)
	for key, tab in pairs(self.sectionTabs) do tab.line:SetShown(key == section) end
	for key, tabs in pairs(self.subTabs) do
		for _, tab in ipairs(tabs) do
			tab:SetShown(key == section)
			tab.line:SetShown(tab.pageID == self.current)
		end
	end
end

-- Where the parchment of a look goes: the art at its own shape from the top,
-- then its mirror image down to the bottom of the page.
function Panel.ArtPieces(width, height, coords)
	local u0, u1, v0, v1 = unpack(coords)
	local artHeight = width * (v1 - v0) / (u1 - u0)
	if artHeight >= height then
		return { height = height, coords = { u0, u1, v0, v0 + (v1 - v0) * height / artHeight } }, nil
	end
	local rest = height - artHeight
	local part = math.min(1, rest / artHeight)
	return { height = artHeight, coords = { u0, u1, v0, v1 } },
		{ height = rest, coords = { u0, u1, v1, v1 - (v1 - v0) * part } }
end

function Panel:LayArt()
	local art, art2 = self.art, self.art2
	local width, height = self.root:GetWidth(), self.root:GetHeight()
	if not Theme.BACKGROUND or type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
		art:Hide()
		art2:Hide()
		return
	end
	local top, bottom = Panel.ArtPieces(width, height, Theme.BACKGROUND_COORDS or { 0, 1, 0, 1 })
	art:SetTexture(Theme.BACKGROUND)
	art:ClearAllPoints()
	art:SetPoint("TOPLEFT")
	art:SetPoint("TOPRIGHT")
	art:SetHeight(top.height)
	art:SetTexCoord(unpack(top.coords))
	art:Show()
	if bottom then
		art2:SetTexture(Theme.BACKGROUND)
		art2:ClearAllPoints()
		art2:SetPoint("TOPLEFT", art, "BOTTOMLEFT")
		art2:SetPoint("BOTTOMRIGHT")
		art2:SetTexCoord(unpack(bottom.coords))
		art2:Show()
	else
		art2:Hide()
	end
end

-- Paints the page in the look chosen (Theme.Apply), then draws its text again.
function Panel:Paint()
	self.bg:SetColorTexture(unpack(Theme.PARCHMENT))
	self:LayArt()
	for _, t in ipairs(edges) do t:SetColorTexture(unpack(Theme.PARCHMENT_EDGE)) end
	for _, fs in ipairs(inks) do fs:SetTextColor(unpack(Theme.INK)) end
	for _, tab in ipairs(tabs) do paintTab(tab) end
	self:Refresh()
end
ns.Listen("FL_THEME", function() for _, panel in ipairs(panels) do panel:Paint() end end)

function Panel:Refresh()
	if not self.root:IsVisible() then return end
	self:UpdateHeader()
	self:Render()
end

local PAGES = {}

function Panel:Render()
	if not ns.db then return end
	local L = self.layout
	L:Reset()
	-- The search box is not hidden and shown again while the reader types: that
	-- would take the cursor away after every letter. It hides only on pages without one.
	self.searchPlaced = false
	for _, tab in ipairs(self.kindTabs or {}) do tab:Hide() end
	local page = PAGES[self.current]
	if page then page(self, L) else self:RenderEntry(L, self.current) end
	if not self.searchPlaced then self.search:Hide() end
	L:Finish()
end

-- Navigation, like a web browser. `viaLink` = the reader followed a link.
function Panel:Open(id, viaLink)
	if not id then return end
	if id ~= self.current then
		table.insert(self.back, self.current)
		wipe(self.forward)
		self.current = id
	end
	local entry = Lore.Get(id)
	if viaLink and entry and not P.IsUnlocked(id) and Lore.HasRule(entry, "read") then
		P.Unlock(id) -- knowledge gained by reading
	end
	self.scroll:SetVerticalScroll(0)
	self:Refresh()
end

function Panel:Back()
	if #self.back == 0 then return end
	table.insert(self.forward, self.current)
	self.current = table.remove(self.back)
	self.scroll:SetVerticalScroll(0)
	self:Refresh()
end

function Panel:Forward()
	if #self.forward == 0 then return end
	table.insert(self.back, self.current)
	self.current = table.remove(self.forward)
	self.scroll:SetVerticalScroll(0)
	self:Refresh()
end

-- One clickable row for any entry.
function Panel:EntryRow(L, entry, opts)
	opts = opts or {}
	local unlocked = P.IsUnlocked(entry.id)
	local done, total = P.EntryProgress(entry)
	local isBook = entry.kind == "book"
	local tier = entry.tier and (" " .. C(Theme.FADED, "[" .. entry.tier .. "]")) or ""
	local right = opts.right
	if right == nil then
		if isBook then right = unlocked and CHECK or ""
		else right = unlocked and total > 1 and (done .. "/" .. total) or "" end
	end
	local label
	if isBook then
		label = unlocked and entry.title or C(Theme.FADED, entry.title)
	else
		label = (unlocked and entry.title or C(Theme.FADED, Theme.LOCK .. " " .. entry.title)) .. tier
	end
	L:Row({
		icon = isBook and BOOK_ICON or nil,
		iconLocked = not unlocked,
		indent = opts.indent,
		left = label,
		right = right,
		new = not isBook and P.EntryHasNew(entry),
		onClick = function() self:Open(entry.id) end,
		onEnter = function(row)
			if opts.note then
				local lines = { opts.note }
				lines[#lines + 1] = unlocked and string.format(ns.T("%d of %d parts discovered."), done, total) or Theme.Plain(Lore.Hint(entry))
				tooltipLines(row, entry.title, lines)
			else
				Panel.Preview(row, entry.id)
			end
		end,
	})
end

local function countFound(list)
	local n = 0
	for _, entry in ipairs(list) do if P.IsUnlocked(entry.id) then n = n + 1 end end
	return n
end

-- Lore pages ------------------------------------------------------------------------

-- "Here": the region you stand in, and how much of its lore is still in the fog.
-- "Listen": the narrator reads this page, or adds it to what it is reading.
function Panel:ListenRow(L, entry)
	if not ns.Voice.Available() then return end
	local busy = ns.Voice.IsActive()
	L:Row({
		icon = Theme.ICON,
		left = busy and ns.T("Listen next") or ns.T("Listen"),
		right = C(Theme.FADED, busy and ns.T("add to the narrator's queue") or ns.T("read aloud while you play")),
		onClick = function()
			if busy then ns.Voice.Enqueue(entry.id) else ns.Voice.Play(entry.id) end
			self:Render()
		end,
	})
end

-- "Track" and "Set waypoint" for anything with a place on the map.
function Panel:TrackRows(L, entry)
	if #ns.Track.Spots(entry) == 0 then return end
	local tracked = ns.Track.IsTracked(entry.id)
	L:Row({
		icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
		left = tracked and ns.T("Stop tracking") or ns.T("Track"),
		right = C(Theme.FADED, tracked and ns.T("in the Lore tracker") or ns.T("add to the Lore tracker")),
		onClick = function()
			ns.Track.Toggle(entry.id)
			self:Render()
		end,
	})
	L:Row({
		icon = "Interface\\Icons\\INV_Misc_Map_01",
		left = ns.T("Set waypoint"),
		right = C(Theme.FADED, _G.TomTom and ns.T("TomTom arrow") or ns.T("map arrow")),
		onClick = function() ns.Track.SetWaypoint(entry) end,
	})
	L:Space(4)
end

PAGES["@here"] = function(self, L)
	local region = ns.Triggers.CurrentRegion()
	if not region then
		L:Text(C(Theme.HEADING, ns.T("Uncharted Pages")), Theme.FONT_TITLE, 4)
		L:Text(C(Theme.FADED, ns.T("No history of this place has yet been set down. Its lore will be written in time.")))
		return
	end
	local pct = P.RegionPercent(region)
	L:Row({ left = C(Theme.HEADING, region.title), right = string.format(ns.T("%d%% uncovered"), pct), onClick = function() self:Open(region.id) end,
		onEnter = function(row) Panel.Preview(row, region.id) end })
	local fog = 100 - pct
	if fog > 0 then
		L:Text(C(Theme.FADED, string.format(ns.T("%d%% of this land's lore still lies in the fog. Seek out the figures and places below."), fog)), Theme.FONT_SMALL, 6)
	else
		L:Text(C(Theme.TEAL_INK, ns.T("Every page of this land's lore has been uncovered.")), Theme.FONT_SMALL, 6)
	end
	self:RenderRegionContents(L, region)
	local books = Lore.BooksOf(region.id)
	if #books > 0 then
		L:Heading(string.format(ns.T("Literature (%d/%d)"), countFound(books), #books))
		for _, book in ipairs(books) do self:EntryRow(L, book) end
	end
end

PAGES["@regions"] = function(self, L)
	local any = false
	for _, continent in ipairs(Lore.Continents()) do
		any = true
		local page = Lore.Get((continent.name:lower():gsub("[^%w]+", "-")))
		if page then
			L:Row({ left = C(Theme.HEADING, continent.name), onClick = function() self:Open(page.id) end,
				onEnter = function(row) Panel.Preview(row, page.id) end })
		else
			L:Heading(continent.name == "Other" and ns.T("Other") or continent.name)
		end
		for _, region in ipairs(continent.regions) do
			local hasNew = P.EntryHasNew(region)
			for _, list in ipairs({ Lore.FiguresOf(region.id), Lore.PlacesOf(region.id), Lore.TopicsOf(region.id) }) do
				for _, child in ipairs(list) do
					if P.EntryHasNew(child) then hasNew = true end
				end
			end
			local unlocked = P.IsUnlocked(region.id)
			L:Row({
				iconLocked = not unlocked,
				indent = 8,
				left = unlocked and region.title or C(Theme.FADED, region.title),
				right = P.RegionPercent(region) .. "%",
				new = hasNew,
				onClick = function() self:Open(region.id) end,
				onEnter = function(row) Panel.Preview(row, region.id) end,
			})
		end
	end
	if not any then L:Text(C(Theme.FADED, ns.T("No lore is written yet."))) end
end

PAGES["@categories"] = function(self, L)
	L:Text(C(Theme.FADED, ns.T("Every page of the encyclopedia, by kind. Click a heading to open or close it.")), Theme.FONT_SMALL, 6)
	for _, cat in ipairs(Lore.CATEGORIES) do
		local entries = Lore.InCategory(cat.key)
		if #entries > 0 then
			local open = self.openCats[cat.key]
			L:Row({
				icon = open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up",
				left = C(Theme.HEADING, ns.T(cat.label)),
				right = countFound(entries) .. "/" .. #entries,
				onClick = function()
					self.openCats[cat.key] = not open
					self:Render()
				end,
			})
			if open then
				for _, entry in ipairs(entries) do self:EntryRow(L, entry, { indent = 12 }) end
			end
		end
	end
end

-- Puts the search box at the top of a list. Each book has its own words:
-- "lore" for the A-Z page, "books" for the Literature pages.
function Panel:PlaceSearch(L, key)
	local box = self.search
	self.searchKey, self.searchPlaced = key, true
	if (box:GetText() or "") ~= self.queries[key] then box:SetText(self.queries[key]) end
	box:ClearAllPoints()
	box:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD + 6, -L.y)
	box:SetWidth(L:Width() - 6)
	if not box:IsShown() then box:Show() end
end

PAGES["@az"] = function(self, L)
	self:PlaceSearch(L, "lore")
	L:Space(28)
	local letter
	for _, entry in ipairs(Lore.Search(self.queries.lore)) do
		local first = entry.title:sub(1, 1):upper()
		if first ~= letter then
			letter = first
			L:Heading(letter)
		end
		local cat = Lore.CategoryOf(entry)
		self:EntryRow(L, entry, { right = cat and C(Theme.FADED, ns.T(cat.label)) or "" })
	end
end

-- Literature pages -------------------------------------------------------------------

local Library = ns.Library
local CONTINENT_ORDER = { ["Eastern Kingdoms"] = 1, ["Kalimdor"] = 2, ["Unknown"] = 9 }

-- The search box and the row of kinds (All, Books, Letters...) at the top of a list.
local function libraryTools(self, L)
	self:PlaceSearch(L, "books")
	L:Space(26)
	if not self.kindTabs then
		self.kindTabs = {}
		local kinds = { { key = "all", label = N("All") } }
		for _, cat in ipairs(Library.CATEGORIES) do kinds[#kinds + 1] = cat end
		for _, kind in ipairs(kinds) do
			local tab = textTab(self.content, ns.T(kind.label), function()
				self.kind = kind.key
				self:Render()
			end)
			tab.key = kind.key
			self.kindTabs[#self.kindTabs + 1] = tab
		end
	end
	local x, y = PAD, L.y
	for _, tab in ipairs(self.kindTabs) do
		local w = tab:GetWidth()
		if x + w > L:Width() + PAD then
			x, y = PAD, y + 22
		end
		tab:ClearAllPoints()
		tab:SetPoint("TOPLEFT", self.content, "TOPLEFT", x, -y)
		tab.line:SetShown(tab.key == (self.kind or "all"))
		tab:Show()
		x = x + w + 6
	end
	L:Space(y - L.y + 24)
end

local function wanted(self, book)
	local kind = self.kind or "all"
	if kind ~= "all" and Library.Category(book).key ~= kind then return false end
	local needle = (self.queries.books or ""):lower()
	return needle == "" or book.title:lower():find(needle, 1, true) ~= nil
end

-- Writings grouped by continent, then by zone. filter(book) decides which to list.
local function bookList(self, L, filter, empty)
	local groups, order = {}, {}
	for _, book in ipairs(Lore.books) do
		if filter(book) and wanted(self, book) then
			-- A writing with copies in several lands is listed in each of them.
			for _, place in ipairs(Library.Places(book)) do
				local continent, zone = place.continent, place.zone
				local g = groups[continent]
				if not g then
					g = { name = continent, zones = {}, zoneOrder = {} }
					groups[continent] = g
					order[#order + 1] = g
				end
				if not g.zones[zone] then
					g.zones[zone] = {}
					g.zoneOrder[#g.zoneOrder + 1] = zone
				end
				table.insert(g.zones[zone], book)
			end
		end
	end
	table.sort(order, function(a, b)
		local ra, rb = CONTINENT_ORDER[a.name] or 5, CONTINENT_ORDER[b.name] or 5
		if ra ~= rb then return ra < rb end
		return a.name < b.name
	end)
	for _, g in ipairs(order) do
		L:Heading(g.name == "Unknown" and ns.T("Unknown") or g.name)
		table.sort(g.zoneOrder)
		for _, zone in ipairs(g.zoneOrder) do
			local list = g.zones[zone]
			table.sort(list, function(a, b) return a.title < b.title end)
			L:Text(C(Theme.BOLD, zone) .. C(Theme.FADED, "  " .. string.format(ns.T("%d/%d read"), countFound(list), #list)), Theme.FONT_BODY, 2)
			for _, book in ipairs(list) do
				local right = P.IsUnlocked(book.id) and CHECK or C(Theme.FADED, ns.T(Library.Category(book).one))
				self:EntryRow(L, book, { indent = 8, right = right })
			end
			L:Space(4)
		end
	end
	if #order == 0 then L:Text(C(Theme.FADED, empty)) end
end

local function libraryIntro(L)
	local found, total = P.Totals("books")
	L:Text(C(Theme.FADED, string.format(ns.T("%d of %d writings read. Open any book, letter or inscription in the world to keep it in your library."), found, total)), Theme.FONT_SMALL, 6)
end

PAGES["@books"] = function(self, L)
	libraryIntro(L)
	libraryTools(self, L)
	bookList(self, L, function() return true end, ns.T("Nothing here matches."))
end

PAGES["@books-missing"] = function(self, L)
	libraryIntro(L)
	libraryTools(self, L)
	bookList(self, L, function(book) return not P.IsUnlocked(book.id) end, ns.T("You have read everything that matches."))
end

PAGES["@books-read"] = function(self, L)
	libraryIntro(L)
	libraryTools(self, L)
	bookList(self, L, function(book) return P.IsUnlocked(book.id) end, ns.T("You have not read anything that matches yet."))
end

-- Writings read in the world that the catalogue does not know yet.
PAGES["@books-unlisted"] = function(self, L)
	L:Text(C(Theme.FADED, ns.T("Writings you have read that are not yet in the catalogue. Their text is kept all the same.")), Theme.FONT_SMALL, 6)
	local list = Library.Unlisted()
	for _, title in ipairs(list) do
		L:Row({ icon = BOOK_ICON, left = title, onClick = function() self:Open("@text:" .. title) end })
	end
	if #list == 0 then L:Text(C(Theme.FADED, ns.T("None so far."))) end
end

-- Entry pages --------------------------------------------------------------------------

function Panel:RenderMissing(L, id)
	L:Text(C(Theme.HEADING, Theme.TitleFromID(id)), Theme.FONT_TITLE, 6)
	L:Text(C(Theme.FADED, ns.T("This page of the encyclopedia has not yet been written. It will be filled as the histories of Azeroth are set down.")))
end

-- The game's page text can hold simple HTML; keep the words and the line breaks.
local function plainPage(text)
	text = text:gsub("<[Bb][Rr]%s*/?>", "\n"):gsub("</[Pp]>", "\n"):gsub("<[^>]+>", "")
	return (text:gsub("\n\n\n+", "\n\n"):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- The kept pages of one title.
local function renderText(L, title, text, heading)
	if heading then L:Text(C(Theme.BOLD, title), Theme.FONT_BODY, 2) end
	local numbers = {}
	for n in pairs(text.pages) do numbers[#numbers + 1] = n end
	table.sort(numbers)
	for _, n in ipairs(numbers) do
		if #numbers > 1 then L:Text(C(Theme.FADED, string.format(ns.T("Page %d"), n)), Theme.FONT_SMALL, 2) end
		L:Text(plainPage(text.pages[n]), Theme.FONT_BODY, 6)
	end
end

function Panel:RenderText(L, title)
	L:Text(C(Theme.HEADING, title), Theme.FONT_TITLE, 2)
	L:Text(C(Theme.TEAL_INK, ns.T("Unlisted writing")), Theme.FONT_SMALL, 6)
	local text = Library.Text(title)
	if text then renderText(L, title, text) end
end

function Panel:RenderBook(L, book)
	local read = P.IsUnlocked(book.id)
	L:Text(C(Theme.HEADING, book.title), Theme.FONT_TITLE, 2)
	local region = book.region and Lore.Get(book.region)
	local sub = { C(Theme.TEAL_INK, ns.T(Library.Category(book).one)) }
	local places = Library.Places(book)
	if #places > 1 or (book.found or ""):find("^Copies") then
		sub[#sub + 1] = ns.T("in several places")
	elseif region then
		sub[#sub + 1] = string.format(ns.T("in %s"), R("{link:" .. region.id .. "}" .. region.title .. "{/link}"))
	else
		sub[#sub + 1] = string.format(ns.T("in %s"), Library.Zone(book))
	end
	L:Text(table.concat(sub, " \194\183 "), Theme.FONT_SMALL, 6)
	L:Text((read and string.format(ns.T("%s Read"), CHECK) or C(Theme.FADED, ns.T("Not yet read"))), Theme.FONT_BODY, 6)

	L:Heading(ns.T("Where to Find It"))
	L:Text(R(book.found or ns.T("Where it lies is not yet known.")), Theme.FONT_BODY, 4)
	if not P.IsFound(book.id) then self:TrackRows(L, book) end
	if read then self:ListenRow(L, book) end
	local pins = book.pins or {}
	if book.pin and region and region.maps then pins = { { maps = region.maps, x = book.pin.x, y = book.pin.y } } end
	for i, pin in ipairs(pins) do
		if i > 4 then
			L:Text(C(Theme.FADED, string.format(ns.T("And %d more places."), #pins - 4)), Theme.FONT_SMALL, 4)
			break
		end
		L:Row({
			icon = "Interface\\Icons\\INV_Misc_Map_01",
			left = ns.T("Point the arrow here"),
			right = C(Theme.FADED, string.format("%.1f, %.1f", pin.x, pin.y)),
			onClick = function()
				-- The add-on never opens or turns Blizzard's map itself: it points the arrow.
				ns.Track.SetWaypoint(book)
				ns.Print(ns.T("Waypoint set. Open your map (M) to see it."))
			end,
		})
	end
	local at = Library.FoundAt(book)
	if at then
		local where = at.subzone and at.subzone ~= "" and (at.subzone .. ", " .. (at.zone or "")) or at.zone or "?"
		if #pins == 0 then
			L:Text(C(Theme.TEAL_INK, string.format(ns.T("You found it in %s, at %.1f, %.1f."), where, at.x, at.y)), Theme.FONT_SMALL, 4)
		else
			L:Text(C(Theme.TEAL_INK, string.format(ns.T("You read it in %s."), where)), Theme.FONT_SMALL, 4)
		end
	end

	if read then
		for _, section in ipairs(book.sections or {}) do
			L:Heading(section.title)
			L:Text(R(section.text))
		end
	elseif book.sections and #book.sections > 0 then
		L:Text(C(Theme.FADED, Theme.LOCK .. " " .. ns.T("Read it in the world to open these notes.")), Theme.FONT_SMALL, 6)
	end

	L:Heading(ns.T("Text"))
	local texts = Library.TextsOf(book)
	if #texts == 0 then
		L:Text(C(Theme.FADED, read and ns.T("Open it again in the world, and its text will be kept here.")
			or Theme.LOCK .. " " .. ns.T("Read it in the world, and its text will be kept here.")), Theme.FONT_SMALL, 6)
	else
		-- A voice pack never holds the game's book text (COMPLIANCE.md, R8): say who reads it.
		if ns.Voice and ns.Voice.Pack and ns.Voice.Pack.Installed() then
			L:Text(C(Theme.FADED, ns.T("The text of a writing is read by the game's own voice: voice packs hold only Lorever's own words.")), Theme.FONT_SMALL, 6)
		end
		for _, t in ipairs(texts) do renderText(L, t.title, t.text, #texts > 1) end
		local kept, total = Library.PageCount(book)
		if total and kept < total then
			L:Text(C(Theme.FADED, string.format(ns.T("%d of %d pages kept. Turn every page in the world to keep the rest."), kept, total)), Theme.FONT_SMALL, 6)
		end
	end
	P.MarkRead(book)
end

function Panel:RenderEntry(L, id)
	local entry = Lore.Get(id)
	if id:sub(1, 6) == "@text:" then return self:RenderText(L, id:sub(7)) end
	if not entry then return self:RenderMissing(L, id) end
	if entry.kind == "book" then return self:RenderBook(L, entry) end

	local cat = Lore.CategoryOf(entry)
	L:Text(C(Theme.HEADING, entry.title), Theme.FONT_TITLE, 2)
	local sub = {}
	if entry.subtitle then sub[#sub + 1] = C(Theme.ITALIC, entry.subtitle) end
	if cat then sub[#sub + 1] = C(Theme.TEAL_INK, ns.T(cat.label)) end
	local owner = Lore.Owner(entry)
	if owner then sub[#sub + 1] = string.format(ns.T("in %s"), R("{link:" .. owner.id .. "}" .. owner.title .. "{/link}")) end
	if #sub > 0 then L:Text(table.concat(sub, " \194\183 "), Theme.FONT_SMALL, 6) end

	if not P.IsUnlocked(entry.id) then
		L:Text(C(Theme.FADED, Theme.LOCK .. " " .. R(Lore.Hint(entry))), nil, 6)
		self:TrackRows(L, entry)
		if entry.kind == "region" then self:RenderRegionContents(L, entry) end
		return
	end
	if not P.IsFound(entry.id) then self:TrackRows(L, entry) end
	self:ListenRow(L, entry)
	if entry.kind == "region" and ns.Triggers.CurrentRegion() == entry then
		L:Row({ icon = Theme.ICON, left = ns.T("Listen to this land"), right = C(Theme.FADED, ns.T("this page, its places and figures")),
			onClick = function() ns.Voice.PlayHere() end })
	end
	L:Space(4)

	local meta = {}
	if entry.allegiance then meta[#meta + 1] = ns.T("Allegiance:") .. " " .. entry.allegiance end
	if entry.found then meta[#meta + 1] = ns.T("Found:") .. " " .. entry.found end
	if entry.faction then meta[#meta + 1] = ns.T("Faction:") .. " " .. entry.faction end
	local done, total = P.EntryProgress(entry)
	if total > 1 then meta[#meta + 1] = string.format(ns.T("Discovered: %d of %d"), done, total) end
	if entry.kind == "region" and not entry.parent then meta[#meta + 1] = string.format(ns.T("Uncovered: %d%%"), P.RegionPercent(entry)) end
	if #meta > 0 then L:Text(C(Theme.FADED, table.concat(meta, "\n")), Theme.FONT_SMALL, 10) end

	for _, section in ipairs(entry.sections or {}) do
		L:Heading(section.title)
		L:Text(R(section.text))
	end

	if entry.chapters then
		L:Heading(ns.T("Chapters"))
		for _, chapter in ipairs(entry.chapters) do
			if P.IsUnlocked(chapter.part.key) then
				L:Text(C(Theme.BOLD, chapter.title), Theme.FONT_BODY, 2)
				L:Text(R(chapter.text))
			else
				L:Text(C(Theme.FADED, Theme.LOCK .. " " .. chapter.title .. (chapter.hint and (" \226\128\148 " .. Theme.Plain(chapter.hint)) or "")))
			end
		end
	end

	if entry.mentions then
		local shown, hidden = {}, 0
		for _, mention in ipairs(entry.mentions) do
			if P.IsUnlocked(mention.part.key) then shown[#shown + 1] = "\226\128\162 " .. R(mention.text) else hidden = hidden + 1 end
		end
		L:Heading(ns.T("Mentioned In"))
		if #shown > 0 then L:Text(table.concat(shown, "\n"), Theme.FONT_BODY, 4) end
		if hidden > 0 then
			L:Text(C(Theme.FADED, Theme.LOCK .. " " .. string.format(hidden == 1 and ns.T("%d more mention yet to be found.") or ns.T("%d more mentions yet to be found."), hidden)))
		end
	end

	-- The web of relations: every bond is a way to another page.
	if entry.bonds then
		L:Heading(ns.T("Bonds"))
		for _, bond in ipairs(entry.bonds) do
			local other = Lore.Get(bond.id)
			if other then
				self:EntryRow(L, other, { note = Theme.Plain(bond.note), right = C(Theme.FADED, Theme.Plain(bond.note)) })
			else
				L:Text("\226\128\162 " .. R("{red:" .. bond.id .. "}" .. bond.name .. "{/red}") .. C(Theme.FADED, " \226\128\148 " .. R(bond.note)), Theme.FONT_BODY, 2)
			end
		end
		L:Space(6)
	end

	if entry.kind == "region" then self:RenderRegionContents(L, entry) end
	P.MarkRead(entry)
end

-- A region is a portal: its places, its figures, then its other pages by category.
function Panel:RenderRegionContents(L, region)
	local function block(title, list)
		if #list == 0 then return end
		L:Heading(string.format("%s (%d/%d)", title, countFound(list), #list))
		for _, entry in ipairs(list) do self:EntryRow(L, entry) end
		L:Space(4)
	end
	block(ns.T("Places"), Lore.PlacesOf(region.id))
	block(ns.T("Figures of Note"), Lore.FiguresOf(region.id))
	local topics = Lore.TopicsOf(region.id)
	for _, cat in ipairs(Lore.CATEGORIES) do
		local list = {}
		for _, topic in ipairs(topics) do
			if topic.category == cat.key then list[#list + 1] = topic end
		end
		block(ns.T(cat.label), list)
	end
end

-- Keep every open panel current.
local function refreshAll()
	for _, panel in ipairs(Panel.instances or {}) do panel:Refresh() end
end
ns.Listen("FL_UNLOCKED", refreshAll)
ns.Listen("FL_SETTINGS_CHANGED", refreshAll)
ns.Listen("FL_ZONE", function()
	for _, panel in ipairs(Panel.instances or {}) do
		if panel.current == "@here" then panel:Refresh() end
	end
end)
ns.Listen("FL_READ", function()
	for _, panel in ipairs(Panel.instances or {}) do panel:UpdateHeader() end
end)
