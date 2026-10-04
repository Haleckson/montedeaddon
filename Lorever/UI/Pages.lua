local _, ns = ...

-- More pages of the book, drawn with the same pieces as the rest of it:
--   Lore > Timeline       the events of Azeroth, one point for each era
--   Journal > Journey     what the reader found, one point for each day
--   Journal > Favorites   the pages the reader marked
--
-- A "point" is a dot on a line that runs down the page, with a label on its
-- left (an era, a day) and the pages of that point on its right:
--
--   10,000 years      o   [book] War of the Ancients      v
--   before the        |   [lock] Great Sundering
--   Dark Portal       |
--   ------------------|--------------------------------------
--   The Third War     o   [book] Third War                v

local Panel = ns.Panel
local Layout, PAGES, PAD, ROW_H, CHECK = Panel.Layout, Panel.PAGES, Panel.PAD, Panel.ROW_H, Panel.CHECK
local Lore, P, Theme = ns.Lore, ns.Progress, ns.Theme
local C = Theme.Color

local LABEL_W = 92                 -- the label on the left of the line
local SPINE_X = PAD + LABEL_W + 10 -- where the line runs
local POINT_INDENT = LABEL_W + 22  -- where the rows of a point begin
local DOT = { all = "Interface\\COMMON\\Indicator-Green", some = "Interface\\COMMON\\Indicator-Yellow", none = "Interface\\COMMON\\Indicator-Gray" }
Layout.POINT_INDENT = POINT_INDENT

local reset = Layout.Reset
function Layout:Reset()
	reset(self)
	for _, point in ipairs(self.points or {}) do
		point.dot:Hide()
		point.rule:Hide()
	end
	for _, meter in ipairs(self.meters or {}) do meter:Hide() end
	if self.spine then self.spine:Hide() end
	self.np, self.nm, self.spineTop, self.pointEnd = 0, 0, nil, nil
end

-- A bar that shows how much is found, with the frame the game draws around its own bars.
function Layout:Meter(found, total, color)
	self.nm = (self.nm or 0) + 1
	self.meters = self.meters or {}
	local m = self.meters[self.nm]
	if not m then
		m = CreateFrame("Frame", nil, self.content)
		m:SetHeight(13)
		local bg = m:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.15, 0.12, 0.08, 0.85)
		m.bar = CreateFrame("StatusBar", nil, m)
		m.bar:SetPoint("TOPLEFT", m, "TOPLEFT", 3, -1)
		m.bar:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -3, 1)
		m.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		local border = m.bar:CreateTexture(nil, "OVERLAY")
		border:SetTexture(Panel.GAME_BORDER)
		border:SetPoint("TOPLEFT", m, "TOPLEFT", -3, 3)
		border:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 3, -3)
		m.value = m.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		m.value:SetPoint("CENTER")
		self.meters[self.nm] = m
	end
	m:ClearAllPoints()
	m:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD + 4, -(self.y + 3))
	m:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -(PAD + 4), -(self.y + 3))
	m.bar:SetStatusBarColor(unpack(color))
	m.bar:SetMinMaxValues(0, math.max(1, total))
	m.bar:SetValue(found)
	m.value:SetText(found .. " / " .. total)
	m:Show()
	self.y = self.y + 13 + 12
	return m
end

-- Starts a point: a thin rule across the page, the dot on the line, the label on its left.
-- `state` colors the dot: "all", "some" or "none" of its pages are known.
function Layout:Point(label, state)
	self.np = (self.np or 0) + 1
	self.points = self.points or {}
	local point = self.points[self.np]
	if not point then
		point = { dot = self.content:CreateTexture(nil, "ARTWORK"), rule = self.content:CreateTexture(nil, "BACKGROUND", nil, 1) }
		point.dot:SetSize(14, 14)
		self.points[self.np] = point
	end
	local r, g, b = unpack(Theme.PARCHMENT_EDGE)
	if self.np > 1 then
		point.rule:ClearAllPoints()
		point.rule:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD, -self.y)
		point.rule:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -PAD, -self.y)
		point.rule:SetHeight(1)
		point.rule:SetColorTexture(r, g, b, 0.6)
		point.rule:Show()
		self.y = self.y + 8
	else
		point.rule:Hide()
	end
	local fs = self:Font(Theme.FONT_SMALL)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", self.content, "TOPLEFT", PAD, -(self.y + 4))
	fs:SetWidth(LABEL_W)
	fs:SetText(label)
	point.dot:SetTexture(DOT[state] or DOT.none)
	point.dot:ClearAllPoints()
	point.dot:SetPoint("CENTER", self.content, "TOPLEFT", SPINE_X, -(self.y + ROW_H / 2))
	point.dot:Show()
	self.spineTop = self.spineTop or (self.y + ROW_H / 2)
	-- The rows of this point may be fewer than the lines of its label.
	self.pointEnd = self.y + (fs:GetStringHeight() or 14) + 10
	return point
end

function Layout:EndPoint()
	if self.pointEnd and self.y < self.pointEnd then self.y = self.pointEnd end
	self.pointEnd = nil
	self.y = self.y + 6
end

-- After the last point: the line that joins the dots.
function Layout:EndPoints()
	if not self.spineTop then return end
	if not self.spine then self.spine = self.content:CreateTexture(nil, "BACKGROUND", nil, 2) end
	local spine = self.spine
	spine:ClearAllPoints()
	spine:SetPoint("TOP", self.content, "TOPLEFT", SPINE_X, -self.spineTop)
	spine:SetSize(2, math.max(1, self.y - self.spineTop - 6))
	spine:SetColorTexture(unpack(Theme.PARCHMENT_EDGE))
	spine:Show()
end

local function known(entries)
	local n = 0
	for _, entry in ipairs(entries) do if P.IsUnlocked(entry.id) then n = n + 1 end end
	return n
end

-- Lore > Timeline ---------------------------------------------------------------------

Panel.TIMELINE_COLOR = { 0.25, 0.70, 0.25 }

PAGES["@timeline"] = function(self, L)
	local eras, total = Lore.Timeline()
	local found = 0
	for _, era in ipairs(eras) do found = found + known(era.entries) end
	L:Text(string.format(ns.T("Timeline progress: %d / %d discovered"), found, total), Theme.FONT_SMALL, 2)
	L:Meter(found, total, Panel.TIMELINE_COLOR)
	if total == 0 then
		L:Text(C(Theme.FADED, ns.T("No lore is written yet.")))
		return
	end
	for _, era in ipairs(eras) do
		local n = known(era.entries)
		L:Point(C(Theme.BOLD, era.label), n == #era.entries and "all" or n > 0 and "some" or "none")
		for _, entry in ipairs(era.entries) do
			self:EntryRow(L, entry, { indent = POINT_INDENT, right = P.IsUnlocked(entry.id) and CHECK or "" })
		end
		L:EndPoint()
	end
	L:EndPoints()
	L:Space(4)
	L:Text(C(Theme.FADED, CHECK .. " " .. ns.T("Discovered") .. "     " .. Theme.LOCK .. " " .. ns.T("Undiscovered")), Theme.FONT_SMALL, 4)
end

-- Journal > Journey -------------------------------------------------------------------

local function dayLabel(day)
	if day == "" then return C(Theme.BOLD, ns.T("Earlier")) end
	local now = time()
	if day == date("%Y-%m-%d", now) then return C(Theme.BOLD, ns.T("Today")) .. "\n" .. day end
	if day == date("%Y-%m-%d", now - 86400) then return C(Theme.BOLD, ns.T("Yesterday")) .. "\n" .. day end
	return C(Theme.BOLD, day)
end

PAGES["@journey"] = function(self, L)
	local oldestFirst = ns.db.journeyOldestFirst == true
	L:Text(C(Theme.FADED, ns.T("Everything you have discovered, day by day.")), Theme.FONT_SMALL, 6)
	-- The order of the days: one click turns the list over.
	L:Row({
		icon = oldestFirst and "Interface\\Buttons\\Arrow-Up-Up" or "Interface\\Buttons\\Arrow-Down-Up",
		left = oldestFirst and ns.T("Oldest first") or ns.T("Newest first"),
		right = C(Theme.FADED, ns.T("click to turn the order")),
		onClick = function()
			ns.db.journeyOldestFirst = not oldestFirst or nil
			self:Render()
		end,
	})
	L:Space(4)
	local days = P.Journey(oldestFirst)
	if #days == 0 then
		L:Text(C(Theme.FADED, ns.T("Nothing discovered yet. Travel, speak with the figures you meet and read what you find.")))
		return
	end
	for _, d in ipairs(days) do
		local label = dayLabel(d.day) .. "\n" .. C(Theme.FADED, string.format(ns.T("%d found"), #d.entries))
		L:Point(label, "all")
		for _, item in ipairs(d.entries) do
			self:EntryRow(L, item.entry, { indent = POINT_INDENT, right = item.at > 0 and C(Theme.FADED, date("%H:%M", item.at)) or "" })
		end
		L:EndPoint()
	end
	L:EndPoints()
end

-- Journal > Favorites -----------------------------------------------------------------

PAGES["@favorites"] = function(self, L)
	L:Text(C(Theme.FADED, ns.T("The pages you marked, and your notes on them.")), Theme.FONT_SMALL, 6)
	local list = ns.Journal.Favorites()
	for _, entry in ipairs(list) do
		local cat = entry.kind ~= "book" and Lore.CategoryOf(entry)
		self:EntryRow(L, entry, { right = cat and C(Theme.FADED, ns.T(cat.label)) or nil })
		local note = ns.Journal.Note(entry.id)
		if note then L:Text(C(Theme.ITALIC, note), Theme.FONT_SMALL, 6) end
	end
	if #list == 0 then
		L:Text(C(Theme.FADED, ns.T("No favorites yet. Open a page and press Add to favorites.")))
	end
end
