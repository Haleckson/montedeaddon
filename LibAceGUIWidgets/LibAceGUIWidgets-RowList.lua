-- LibAceGUIWidgets — RowList component.
-- A virtual-scrolling data-row list, ported from FastGuildInvite's GUI\RowList.lua
-- and decoupled from FGI state. Panels that show lists of data consume RowList
-- instead of building their own row layouts, so the visual style stays consistent
-- across consumers.
--
-- Visual contract:
--   * 16 px row height.
--   * Alternating subtle background banding (every 2nd row, white @ 0.04).
--   * Left-anchored auto-width column (typically the name), class-coloured via
--     lib:ClassColor(entry.classFile) when the column spec opts in
--     (color == "class") and the entry carries a `classFile` field.
--   * Fixed-width auxiliary columns right-justified with 4 px column gaps.
--   * Right-edge action icons: 14 px textures with the standard
--     ButtonHilight-Square highlight; tooltip anchored via lib:AnchorTooltip.
--   * Virtual scrolling — a pool of row frames sized to the parent's height
--     (grown on demand), a manual Blizzard-style scrollbar + mouse-wheel.
--
-- Construction:
--   local W  = LibStub("LibAceGUIWidgets-1.0")
--   local rl = W.RowList:New(parent, {
--       rowCount   = 30,          -- INITIAL pool size; grows on demand
--       rowHeight  = 16,          -- optional; a SCALE-1.0 value, multiplied by W:GetScale() (MINOR 29)
--       columns    = {
--           { key = "name", width = nil, color = "class" },
--           { key = "lvl",  width = 30 },   -- width is a scale-1.0 value too
--           -- `justify` is honoured by a `button` column only (MINOR 34); text cells ignore it, since
--           -- honouring it now would move a column in every consumer that already passes one. Use
--           -- `align = "RIGHT"` (MINOR 34) to right-align any text or button cell.
--           -- The effective (scaled, header-fitted) width is `rl:ColumnWidth(key)`; `col.width`
--           -- is never written back (it was, before MINOR 29).
--           -- AT MOST ONE column may omit `width`. That one is the auto-width column and it fills
--           -- whatever is left between the fixed columns; a second is a construction-time error,
--           -- because there is no sensible way to split the leftover space between two of them.
--       },
--       actions    = {
--           { texture = "...", tooltip = "Invite", onClick = function(entry, idx, rl, btn) ... end },
--           -- `btn` is the clicked action button, so a handler can anchor a menu/popup to it.
--           -- `show = function(entry) -> boolean` (optional) hides the icon on rows where the action
--           -- doesn't apply -- the action-side counterpart of an icon column's nil texture. Omit it
--           -- and the icon always shows. `texture` may be a function(entry) -> path, desaturated.
--           -- HOLES ARE FINE: `cond and action or nil` is compacted away in New, so a conditional
--           -- action neither disappears nor raises. Prefer `show` for per-ROW visibility -- omitting
--           -- an action entirely removes it for every row and shrinks the reserved icon strip.
--       },
--       onRowClick = function(entry, idx, rl, button, rowFrame) ... end,  -- optional; button is
--                                 -- "LeftButton"/"RightButton"/..., rowFrame anchors a menu (MINOR 27)
--       onRowEnter = function(entry, idx, rl, rowFrame) ... end,  -- optional (hover)
--       onRowLeave = function(entry, idx, rl, rowFrame) ... end,  -- optional
--       tiebreak   = function(a, b) return a.id < b.id end,      -- optional (MINOR 30): decides rows
--                                 -- whose sort cells tie, before SetData order; not flipped by the arrow
--   })
--   A column may carry `sortValue = function(entry) -> key` (MINOR 30): the header sorts on it while
--   the cell shows entry[key]. Ties keep SetData order -- the sort is stable since MINOR 30.
--   A column may also carry `onCellEnter(entry, idx, rl, cellFrame)` / `onCellLeave(...)` (MINOR 30) for
--   a tooltip that belongs to ONE cell rather than the row. A text cell is a FontString and cannot take
--   the mouse, so a column that asks gets a mouse-enabled overlay laid exactly over its cell; a column
--   that does not ask builds none. `cellFrame` is that overlay -- anchor a tooltip to it. The entry is
--   resolved when the pointer arrives, never captured at build time, because rows are pooled. In the
--   client the overlay takes the mouse from the row, so the row's own `onRowLeave` fires as the pointer
--   enters a cell and `onRowEnter` fires again as it leaves -- NOT verified in a client. A click on the
--   overlay is forwarded to `onRowClick` with the ROW frame, so a right-click menu still works there.
--   A column may carry `onCellClick(entry, idx, rl, button, cellFrame) -> consumed` (MINOR 33), the click
--   half of that pair. It gets the overlay a hover column gets -- a column that asks for only the click
--   still gets one -- and it is called FIRST on a click. Return true and the click is CONSUMED:
--   `onRowClick` does not also run. Return false or nothing and it falls through to `onRowClick`
--   unchanged, with the same `(entry, idx, rl, button, rowFrame)` the row handler always gets. That
--   return is what lets one cell behave like a hyperlink -- a plain left click opens its target -- while
--   every other click on that same cell still does whatever the row does.
--   A text column may carry `strike = function(entry) -> boolean` (MINOR 33): when it answers true for
--   the entry a pooled row is showing, a hairline is drawn across that cell's text -- a "done", "won" or
--   "no longer available" row that stays in the list instead of vanishing from it. WoW has no
--   strikethrough font style, so this is a texture, sized to the RENDERED text rather than the column
--   (an item link measures as the player sees it) and clamped to the cell so a truncated string's line
--   cannot run out over the next column. Resolved on every populate, so the line follows the ENTRY
--   through a scroll rather than staying on the frame. A column that does not ask builds no texture.
--   rl:SetSort(key[, desc])   -- optional; call BEFORE SetData for a pre-sorted first render.
--                             -- Without it a list opens in the model's own order, since the only
--                             -- other writer of the sort is a header click by the user.
--   rl:SetData(table[, preserveScroll])
--   rl:Refresh()
--       onEmptyRender = function(rl, dataCount) ... end,  -- optional (MINOR 33): the list has rows and
--                             -- no room to draw them (a parent whose height resolved to zero). Absent,
--                             -- the list prints one line naming the count and the parent's height --
--                             -- once per list, because this state is always a consumer bug and is
--                             -- otherwise completely silent.
--   rl:SetColumns(columns) -> changed   (MINOR 33)
--                             -- a new column set on a LIVE list: header and cells rebuilt, data,
--                             -- scroll and the row frames kept. Cells are pooled per row, so a set
--                             -- that comes and goes costs frames once. A set that differs only in
--                             -- its closures is adopted WITHOUT a rebuild (returns false), so it is
--                             -- safe to call on every repaint. Validated exactly as `New` is.
--   rl:ScrollToEntry(entry | function(entry) -> bool) -> boolean   (MINOR 31)
--                             -- scrolls so that entry is the TOP visible row where the clamp allows
--                             -- (an entry on the last page sits lower: the list never scrolls past
--                             -- its end); false, and no scroll, when nothing matches
--   rl:SetSelected(entry | function(entry) -> bool | nil) -> entry | nil   (MINOR 31)
--                             -- a persistent accent-tinted highlight on that row, through pooling,
--                             -- scroll and sort; nil clears it. Cleared by SetData unless the same
--                             -- entry (identity) is still present
--   rl:GetSelected() -> entry | nil
--
-- MINOR 34 -- requested by FastGuildInvite (inbox 7e28e319) and TOGTools (inbox c571dee6):
--   opts.externalSort = true    the consumer orders `data`; a header still sets the key and the arrow
--   opts.onSortChanged = function(key, desc, rl)   every sort the USER makes (header or column menu);
--                               not called for the consumer's own SetSort
--   opts.headerMenu = true      every header opens the column menu (below), not only filterable ones
--   opts.hyperlinks = true      |H links in cells hover into the tooltip and click like chat links
--   opts.refontHook / opts.classDisplay   this list's own hooks, over the session-global lib.config ones
--   col.expander = true         a +/- tree toggle bound to entry[key]: true "-", false "+", nil hidden;
--                               col.onToggle(entry, newValue, idx, rl), and the entry is NOT written
--   col.button = true           a clickable text cell: col.onClick(entry, idx, rl, mouseButton, cellFrame),
--                               col.cellTip(entry) -> tooltip text under the header; honours col.justify
--   entry._readonly = true      that row's checkbox and button cells are disabled
--   col.filterable = true       its header opens a menu: sort, then a checkbox per distinct value (what
--                               the cell SHOWS, escape-stripped), cascading across columns, with a search
--                               box; col.filterGroup(entry) -> label nests values under group submenus
--   col.autoFit = true          width = the widest cell over `data` + padding, at least col.minWidth
--                               (on an icon, checkbox or expander column, the filter lists and autoFit
--                               measures the RAW value -- "true", "1" -- since those cells show no text)
--   rl:SetSearch(text)          case-insensitive plain substring over every text/button cell; nil clears
--   rl:ClearFilters()
--
-- Class-coloured cells read entry.classFile (e.g. "WARRIOR"). For a fully
-- localized + coloured class name, set col.classDisplay = true and supply
-- lib.config.classDisplay(classFile) -> string via W:Configure.

-- The client's link handlers, read only by `_enableHyperlinks` and every one feature-detected there.
-- luacheck: read globals FriendsFrame_ShowDropdown WOW_PROJECT_ID WOW_PROJECT_MAINLINE DEFAULT_CHAT_FRAME
-- luacheck: read globals SetItemRef HandleModifiedItemClick IsModifiedClick ChatEdit_InsertLink
-- Drag to reorder (MINOR 36).
-- luacheck: read globals InCombatLockdown GetCursorPosition

local lib = LibStub and LibStub("LibAceGUIWidgets-1.0", true)
if not lib then return end

-- EVERY NUMBER BELOW IS A SCALE-1.0 VALUE (MINOR 29). An instance derives its live geometry from
-- them in `_applyMetrics` -- `self.rowHeight`, `self.iconSize`, the per-column widths -- and re-lays
-- every pooled frame on `lib:OnScaleChanged`, so a consumer's list follows the slider without the
-- consumer touching it. A `rowHeight` or `col.width` the consumer passed is a scale-1.0 value too.
-- The scrollbar lane is the one thing left at its pixel size: it is the client's canonical
-- scrollbar shape, not something a reader has to see.
local DEFAULT_ROW_HEIGHT = 16
local HEADER_HEIGHT      = 20
local ICON_SIZE          = 14
local ICON_GAP           = 3
local LEFT_PAD           = 6
local COL_GAP            = 4
local ARROW_W, ARROW_H   = 15, 11   -- the sort arrow
local ARROW_GAP          = 3        -- between the header text and the arrow
local HEADER_PAD         = 4        -- right padding after the arrow
local CHECKBOX_SIZE      = 16       -- col.boxSize default
local ICON_CELL_SIZE     = 14       -- col.iconSize default
local EXPANDER_SIZE      = 14       -- col.boxSize default for an `expander` column (MINOR 34, FGI's 14)
-- col.autoFit (MINOR 34): the room added past the widest measured cell, so text does not touch the
-- next column.
local AUTOFIT_PAD        = 8
-- The column filter menu (MINOR 34) lists at most this many distinct values, then one line saying how
-- many were left out. 200 is TOGTools' number; the menu's search box narrows past it.
local FILTER_VALUE_CAP   = 200
-- col.strike: a hairline through the cell's text, scaled like everything else the list draws, and
-- slightly under the text's own alpha so the words stay readable through it rather than being
-- crossed out twice as hard as they are written.
-- The row hover highlight's default (MINOR 36): the stock quest-log title highlight, ADD-blended, which is
-- what TOGProfessionMaster's hand-rolled lists and this library's own date-picker day cells use.
local HOVER_TEXTURE      = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight"
-- Group header rows and indent (MINOR 36). The +/- are the Classic Era craft window's own category
-- toggles (Blizzard_CraftUI/Vanilla/Blizzard_CraftUI.lua:195-197), so a header reads like the client's.
local INDENT_STEP        = 12
local HEADER_EXP_SIZE    = 14
local HEADER_MINUS       = "Interface\\Buttons\\UI-MinusButton-Up"
local HEADER_PLUS        = "Interface\\Buttons\\UI-PlusButton-Up"
local HEADER_STRIP_ALPHA = 0.10   -- the accent-tinted strip a header row draws in place of banding
local NO_COLUMNS         = {}     -- what a header row's populate walks instead of the column set
-- `col.iconTexCoord = true` (MINOR 36): the usual crop of the 1px border baked into Interface\Icons art.
local ICON_CROP          = { 0.07, 0.93, 0.07, 0.93 }
-- Drag to reorder (MINOR 36): the insert line's thickness, the dragged row's dimming, and how often the
-- list steps while the dragged row is held against its top or bottom edge.
local DROP_LINE_HEIGHT   = 2
local DRAG_DIM_ALPHA     = 0.4
local DRAG_SCROLL_STEP   = 0.1
local STRIKE_HEIGHT      = 1
local STRIKE_ALPHA       = 0.8
local SCROLLBAR_WIDTH    = 12
-- Up/down arrow buttons match Blizzard's ScrollBar arrow textures, designed to
-- render ~32 px; buttons stick out beyond the 16 px track gutter to either side,
-- the canonical WoW scrollbar shape.
local SCROLLBAR_BTN_SIZE = 24
-- Gutter reserved permanently on the row's right edge for the scrollbar lane, so
-- rows don't shift horizontally when the scrollbar shows/hides.
local SCROLLBAR_GUTTER   = SCROLLBAR_WIDTH + 4

local RowList = {}
lib.RowList = RowList
RowList.__index = RowList

-- A column with a set width, or one that measures its own (`autoFit`, MINOR 34). Every other column is
-- the auto-width column that fills what is left. ONE predicate, used by validation, both layout chains
-- and the metrics: an autoFit column declares no `width`, and each place that used to test `col.width`
-- would otherwise have taken it for a second auto-width column.
local function isFixed(col)
	return (col.width or col.autoFit) and true or false
end

-- `col.gapBefore` (MINOR 34, TOGTools inbox c571dee6 item 7): extra space to the column's LEFT, a
-- scale-1.0 value -- so a right-aligned number column followed by a left-aligned name does not read
-- as one. Both layout chains and the header read it here, so they cannot disagree.
local function gapBefore(col)
	return col.gapBefore and lib:ScaledSize(col.gapBefore) or 0
end

-- Plain text of what a cell shows: colour codes, textures, atlases and hyperlink wrappers removed, so
-- "|cff..|Hitem:..|h[Foo]|h|r" and "[Foo]" are one filter value and one search target (MINOR 34).
local function stripEscapes(s)
	s = tostring(s or "")
	s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	s = s:gsub("|H.-|h(.-)|h", "%1")
	s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
	s = s:gsub("|n", " ")
	s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

-- Right-edge action icon. Size and anchor are `_layoutRow`'s, applied at build and on every scale
-- change. The OnClick dispatcher closes over the row index so it resolves the entry via
-- listOffset + i at click time, not build time.
local function makeRowIcon(parent, texture, tooltip, onClick, anchorTip)
	local b = CreateFrame("Button", nil, parent)
	-- A STRING texture is fixed here; a FUNCTION(entry) texture is per-row STATE (e.g. a wishlist coin that's
	-- gold when listed, grey when not) — left unset here and resolved on each populate in _renderRows, since
	-- rows are pooled.
	if type(texture) == "string" then
		b:SetNormalTexture(texture)
		b:SetPushedTexture(texture)
		local pushed = b:GetPushedTexture()
		if pushed then pushed:SetVertexColor(0.7, 0.7, 0.7) end
	end
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", function(self)
		anchorTip(self)   -- the list's own tooltipOwner when it has one (MINOR 34)
		GameTooltip:SetText(tooltip or "", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() lib:HideTooltip() end)
	return b
end

-- THE THREE RULES A COLUMN SET MUST SATISFY, checked once, in the one place both entry points reach.
-- Factored out because `SetColumns` (MINOR 33) must apply the SAME rules to a set handed over at
-- runtime: a validation that only ran at construction would let the exact table `New` rejects
-- through the back door, and the runtime path is the one where a column set is assembled in a loop
-- -- which is where all three of these actually happen.
--
-- `level` blames the CONSUMER's call, not this line.
--
--  1. EVERY COLUMN NEEDS A `key`. Without one, `cells[col.key] = fs` is `cells[nil] = fs` and Lua
--     raises "table index is nil" from inside `_buildRowCells`, two call paths away from the table
--     that caused it. Named here instead, with the column's position.
--
--  2. KEYS SHOULD BE UNIQUE -- and this one WARNS rather than raising, which was a deliberate
--     reversal. `cells[col.key]` OVERWRITES, so the earlier column's FontString is no longer
--     reachable from `row.cells`: never re-populated, never released into the pool, never hidden --
--     a frozen cell on every row drawing whatever it last drew, silently and forever.
--
--     THE FIRST VERSION OF THIS RULE RAISED, AND THAT WAS THE WRONG SEVERITY FOR A LIBRARY. A
--     column set is assembled at RUNTIME from a consumer's own data -- a guild's raid list, a
--     settings flag, a loop over items -- so a duplicate can appear in ONE player's configuration
--     and in nobody else's, including the author's. Raising there kills the whole tab for that
--     player; the existing behaviour costs them one stale cell. A library must not convert a
--     cosmetic fault in a configuration it cannot enumerate into a dead window, which is the same
--     reasoning `tooltipText` applies to a caller's wrong argument. So: one printed line per list,
--     naming the key and what it costs, exactly as `_reportEmptyRender` does -- the party that can
--     cheaply see the problem says so, and the list still draws.
--
--  3. AT MOST ONE COLUMN MAY OMIT `width` -- the auto-width column; see the long note at the call
--     site in `New`. This one RAISES, and the asymmetry is not an oversight: a second auto-width
--     column has no defined behaviour to fall back to, while a duplicate key has one.
--
-- Rules 1 and 2 were peer review's F6 and F5 against MINOR 33, both filed after `SetColumns` made
-- the runtime path reachable.
-- Keys already reported by rule 2 below, so a rebuilt-every-repaint column set says it once.
local dupeWarned = {}

local function assertValidColumns(columns, level)
	level = level or 2
	local seen, autoKeys = {}, nil
	for i, col in ipairs(columns) do
		-- NIL FIRST, and that order is load-bearing: `seen[col.key]` below is itself a `table index
		-- is nil` when the key is missing, so a uniqueness check placed first would raise the very
		-- error this rule exists to replace -- measured, by disabling both rules and watching the
		-- nil-key spec fail at this function rather than at the message it asserts.
		if col.key == nil then
			error(("RowList: column %d has no `key`; every column needs one"):format(i), level)
		end
		if seen[col.key] and not dupeWarned[col.key] then
			-- Once per KEY for the life of the session, not once per list: a consumer whose column
			-- set is rebuilt on every repaint would otherwise print this on every repaint, which
			-- buries it exactly as `_reportEmptyRender`'s once-per-instance guard prevents there.
			dupeWarned[col.key] = true
			lib:_Report("duplicateColumnKey",
				("RowList: two columns share the key %q (columns %d and %d). "):
					format(tostring(col.key), seen[col.key], i)
				.. "Only the LAST one is drawn -- the earlier column's cell is left on every row showing "
				.. "whatever it last drew, and never updates again. Give each column its own key.",
				{ key = col.key, first = seen[col.key], second = i })
		end
		seen[col.key] = i
		if not isFixed(col) then
			autoKeys = autoKeys or {}
			autoKeys[#autoKeys + 1] = tostring(col.key)
		end
	end
	if autoKeys and #autoKeys > 1 then
		error(("RowList: at most one column may omit `width` (the auto-width column); got %d: %s")
			:format(#autoKeys, table.concat(autoKeys, ", ")), level)
	end
end

-- Structurally identical? `SetColumns` is documented as callable on every repaint, so the no-op
-- check is what makes that safe -- without it a consumer following the documentation would rebuild
-- every cell in the list on every refresh.
--
-- Compares what decides the LAYOUT (key, header, width) and what decides WHAT GETS BUILT -- the cell
-- kind, and whether a column asks for a strike line, a mouse overlay or a toggle script. The second
-- half is compared by PRESENCE, never by identity: a consumer who rebuilds their table every repaint
-- hands over fresh closures each time, and comparing those would answer "different" forever. But a
-- column that newly asks for a strike needs a texture that does not exist yet, so gaining or losing
-- one of these features has to count as a change. (The first version compared only the layout
-- fields, and a set that added `strike` to an existing column was adopted with no texture built for
-- it -- a spec caught it.)
local function builds(col)
	return (col.checkbox and "c" or col.expander and "x" or col.button and "b" or col.icon and "i" or "t")
		.. (col.strike and "s" or "")
		.. ((col.onCellEnter or col.onCellLeave or col.onCellClick) and "o" or "")
		.. (col.onCellClick and "k" or "")
		.. (col.onToggle and "g" or "")
end

local function sameColumnSet(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		local x, y = a[i], b[i]
		if x.key ~= y.key or x.header ~= y.header or x.width ~= y.width then return false end
		-- Plain values the HEADER is built from; strings, so compared by value.
		if x.headerTip ~= y.headerTip or x.sortable ~= y.sortable then return false end
		-- Applied when a cell is BUILT, so a set that changes them must rebuild (peer review L5).
		if x.font ~= y.font or x.justify ~= y.justify or x.align ~= y.align then return false end
		if x.gapBefore ~= y.gapBefore then return false end   -- layout, like width
		-- MINOR 34: a filterable header opens a menu instead of sorting, and autoFit decides the width.
		if (x.filterable and true or false) ~= (y.filterable and true or false) then return false end
		if (x.autoFit and true or false) ~= (y.autoFit and true or false) or x.minWidth ~= y.minWidth then
			return false
		end
		if builds(x) ~= builds(y) then return false end
	end
	return true
end

--- Construct a new RowList anchored to `parent`. Rows attach TOPLEFT/TOPRIGHT to
--- the parent so they stretch to full width; fixed column widths are subtracted
--- off the right edge and the auto-width column gets whatever's left.
-- Declared with a dot and a discarded first parameter rather than `RowList:New`, so the new instance below
-- can be called `self` without shadowing the implicit class argument (luacheck W412). `RowList:New(...)` at
-- the call site is unchanged — that desugars to `RowList.New(RowList, ...)`, and the class is reached through
-- the upvalue here anyway.
function RowList.New(_, parent, opts)
	opts = opts or {}
	local self = setmetatable({}, RowList)

	self.parent     = parent
	-- INITIAL pool size (default 30); grows on demand when the parent is taller.
	self.rowCount   = opts.rowCount  or 30
	-- The consumer's row height is a SCALE-1.0 value; `self.rowHeight` is the live, scaled one and
	-- is what every layout and the visible-row arithmetic read.
	self.baseRowHeight = opts.rowHeight or DEFAULT_ROW_HEIGHT
	self.columns    = opts.columns   or {}
	self.onRowClick = opts.onRowClick
	self.onRowEnter = opts.onRowEnter
	self.onRowLeave = opts.onRowLeave
	-- MINOR 33: called instead of the printed warning when a populate has data but no room to draw it.
	self.onEmptyRender = opts.onEmptyRender
	self.tiebreak   = opts.tiebreak   -- MINOR 30: function(a, b) -> a before b, for rows whose sort cells tie
	-- MINOR 34 (FastGuildInvite inbox 7e28e319): the consumer orders `data` itself. A header still
	-- sets the key and the arrow and still calls `onSortChanged`, but the rows are drawn as given --
	-- a tree of parent rows with their children spliced in after them cannot be ordered by a flat
	-- per-row comparator, so the owner re-sorts and calls SetData.
	self.externalSort  = opts.externalSort and true or false
	self.onSortChanged = opts.onSortChanged   -- function(key, desc, rl), on every header-driven sort
	-- MINOR 36: "three" makes a header cycle asc -> desc -> none (a column may ask alone with
	-- `col.sortNone`). Anything else keeps the two-state toggle every existing list has.
	self.sortCycle = opts.sortCycle == "three" and "three" or nil
	-- MINOR 36 (TOGProfessionMaster inbox 85482ed8): `searchText(entry)` -> a string the search also reads,
	-- for text the row does not show (a tooltip, a spell effect, crafter names). Either it or
	-- `searchTokens = true` switches SetSearch to W:SearchMatch's every-word rule. Named `searchTextFn`
	-- on the instance because `searchText` there is the live query.
	self.searchTextFn = type(opts.searchText) == "function" and opts.searchText or nil
	self.searchTokens = opts.searchTokens and true or false
	-- MINOR 36: `onScroll(rl, offset)`. The list starts at 0, which is not news.
	self.onScroll, self._reportedOffset = opts.onScroll, 0
	-- MINOR 34 (TOGTools inbox c571dee6): every header opens the column menu, not only filterable ones.
	self.headerMenu = opts.headerMenu and true or false
	-- MINOR 34: hoverable, clickable |H links in cells. Opt-in, because a row that takes hyperlink
	-- clicks also takes the mouse, which changes what an existing list's rows do.
	self.hyperlinks = opts.hyperlinks and true or false
	-- MINOR 36: a highlight on the row under the pointer (TOGProfessionMaster inbox 0c477b45). `true` is
	-- the stock quest-log title highlight; a string is a texture path; a table is { r, g, b, a }. Opt-in,
	-- because the row takes the mouse to know it is hovered, as it does for `hyperlinks`.
	self.hoverHighlight = opts.hoverHighlight or nil
	-- MINOR 36 (TOGProfessionMaster inbox 57b66577): group header rows and per-row indent. A row is a
	-- header when `opts.isHeader(entry)` answers truthy, or, with no such function, when `entry._header`
	-- is. A STRING answer is the heading's text; `true` uses the indent column's own text. `entry._indent`
	-- is a LEVEL (0, 1, 2 ...), each `indentStep` scale-1.0 px (default 12), applied to `indentKey`'s
	-- column -- by default the first column that shows text.
	self.isHeaderFn = type(opts.isHeader) == "function" and opts.isHeader or nil
	self.indentStep = tonumber(opts.indentStep) or INDENT_STEP
	self.indentKey  = opts.indentKey
	self.headerFont = opts.headerFont
	-- MINOR 36 (inbox 973a1ab1): drag a row to a new place. `onReorder(fromIndex, toIndex, entry, rl)`;
	-- the consumer moves the item in its model and calls SetData. Both are needed, or nothing drags.
	self.reorderable = (opts.reorderable and type(opts.onReorder) == "function") and true or false
	self.onReorder   = opts.onReorder
	-- MINOR 36 (inbox 8680f2cc): the list sizes its PARENT to its rows. `true` or `{ maxRows = n }`;
	-- `onHeightChanged(rl, height)` is told each new height.
	if opts.fitContent then
		self.fitContent = type(opts.fitContent) == "table" and opts.fitContent or {}
	end
	self.onHeightChanged = opts.onHeightChanged
	-- MINOR 34: PER-LIST overrides of the session-global `lib.config` hooks. `lib.config` is one table
	-- for every addon in the session, so a hook set there by one consumer re-fonts or re-labels the
	-- next consumer's lists as well. Given here, it applies to this list only; absent, the global one
	-- is used exactly as before.
	self.refontHook   = opts.refontHook
	self.classDisplay = opts.classDisplay
	-- MINOR 34 (FGI inbox df5ec079): anchors every tooltip the LIST draws -- header, action icon,
	-- button cell, hyperlink -- instead of lib.config.tooltipOwner or the default. Same precedence
	-- and the same reason as the two hooks above.
	self.tooltipOwner = opts.tooltipOwner
	-- MINOR 34: the column filter (`colExcluded[key][label] = true` for each UNCHECKED value) and the
	-- free-text search (lower-cased, nil when empty). Both narrow what `_getSortedData` hands back.
	self.colExcluded = {}
	self.searchText  = nil

	-- `actions` is consumer-supplied and may legitimately arrive with a HOLE: this API documents
	-- `show = function(entry)` and a nil `texture` as ways to say "this action may not apply", so a
	-- consumer writing `cond and action or nil` in the constructor is following its grain. But `#` on a
	-- holed table is UNDEFINED in Lua 5.1, and every read below uses `#` -- so one mistake produced two
	-- opposite outcomes decided purely by position. Measured on 5.1.5: `{a, nil}` reports 1 and the
	-- entry is silently dropped; `{nil, a}` reports 2, the draw loop hands nil to makeRowIcon, and it
	-- RAISES out of the public SetData/Refresh into the consumer's call site (nothing here pcalls).
	-- Compacting once makes every `#self.actions` below honest, iconAreaW included.
	-- `table.maxn`, NOT `ipairs`: ipairs stops at the first hole, dropping exactly the entries at risk.
	-- Peer review finding 7; it had already shipped at two Dibs call sites.
	local rawActions = opts.actions or {}
	self.actions = {}
	for i = 1, table.maxn(rawActions) do
		local a = rawActions[i]
		if a then self.actions[#self.actions + 1] = a end
	end

	-- The reserved icon strip (`iconAreaW`) is computed in `_applyMetrics` from the SURVIVING
	-- actions -- never from how many draw on a given row, since `show` gates icons per row by
	-- design and the strip is a fixed reserve so the text columns line up across every row.

	self.data            = {}
	self.listOffset      = 0
	self.rows            = {}
	self.visibleRowCount = 0

	-- AT MOST ONE column may omit `width`. That one is the auto-width column, which fills the gap
	-- between the left-anchored and right-anchored chains. A SECOND used to vanish in total silence:
	-- `autoIdx` is the FIRST width-less column and both chains `break` there, then guard on `col.width`
	-- with no else (_buildHeader's right chain, and the same shape in _buildRow), so a later width-less
	-- column got no cell, no header and no anchor -- and `_renderRows`' `if cell then` swallowed the
	-- miss. A column the consumer declared was simply not there, with no error and no log line.
	-- Raising here names the offenders at construction. Chosen over silently defaulting the extra to
	-- zero width, which would render a column the caller cannot see and reads as "no data" rather than
	-- a bug. Peer review finding 10; the docstring above now states the rule too.
	-- Runs BEFORE the width pre-pass below, which is safe only because that pre-pass never ASSIGNS a
	-- width to a width-less column -- it widens existing ones. Seed any future default width above this
	-- check, or every table using it will trip.
	--
	-- IF YOU ARE ADDING A COLUMN TO A LIST BUILT AT RUNTIME, THE WIDTH IS NOT OPTIONAL THERE.
	-- This raises at construction, which for a statically declared table is effectively build-time: it
	-- fires for everybody or for nobody, and whoever wrote it sees it immediately. A column set
	-- assembled in a loop or behind a config check is different -- `Dibs/GUI/Tracker.lua:555-571`
	-- appends one column per tracked raid and a `dkp` column only when the guild runs DKP. It is safe
	-- today because every appended column carries a literal width, but the day one does not, this
	-- raise reaches only the guilds whose configuration takes that branch, and the developer's own
	-- client may not be one of them. Failing loudly is still right -- a silent drop would hit exactly
	-- the same configuration, and say nothing.
	assertValidColumns(self.columns, 3)   -- 3: past this helper and past New, onto the caller

	-- Any column with a `header` string enables the header bar, and a header needs the measuring
	-- probe. Both are `_syncHeaderState`'s job, shared with `SetColumns`.
	self:_syncHeaderState(self.columns)

	-- Live geometry at the current scale, then the frames built against it.
	self:_applyMetrics()
	if self.hasHeader then self:_buildHeader() end

	for i = 1, self.rowCount do
		self.rows[i] = self:_buildRow(i)
	end

	-- Scrollbar lane on the parent's right edge. Plain CreateFrame("Slider")
	-- with manual textures — UIPanelScrollBarTemplate calls
	-- parent:SetVerticalScroll inside SetValue, which only exists on real
	-- ScrollFrames and errors on a plain Frame. Build the visuals manually with
	-- the canonical Blizzard ScrollBar textures.
	local sb = CreateFrame("Slider", nil, parent)
	sb:SetOrientation("VERTICAL")
	sb:SetWidth(SCROLLBAR_WIDTH)
	sb:SetMinMaxValues(0, 0)
	sb:SetValueStep(1)
	sb:SetValue(0)

	local sbBg = sb:CreateTexture(nil, "BACKGROUND")
	sbBg:SetAllPoints(sb)
	sbBg:SetColorTexture(0, 0, 0, 0.4)

	local upBtn = CreateFrame("Button", nil, sb)
	upBtn:SetPoint("BOTTOM", sb, "TOP", 0, 0)
	upBtn:SetSize(SCROLLBAR_BTN_SIZE, SCROLLBAR_BTN_SIZE)
	upBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
	upBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
	upBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
	upBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight", "ADD")
	upBtn:SetScript("OnClick", function() sb:SetValue(sb:GetValue() - 1) end)

	local downBtn = CreateFrame("Button", nil, sb)
	downBtn:SetPoint("TOP", sb, "BOTTOM", 0, 0)
	downBtn:SetSize(SCROLLBAR_BTN_SIZE, SCROLLBAR_BTN_SIZE)
	downBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
	downBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
	downBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
	downBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight", "ADD")
	downBtn:SetScript("OnClick", function() sb:SetValue(sb:GetValue() + 1) end)

	local sbThumb = sb:CreateTexture(nil, "ARTWORK")
	sbThumb:SetSize(SCROLLBAR_WIDTH, 24)
	sbThumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	sb:SetThumbTexture(sbThumb)

	sb.upBtn   = upBtn
	sb.downBtn = downBtn

	sb:SetScript("OnValueChanged", function(_, val)
		local newOffset = math.floor(val + 0.5)
		if newOffset == self.listOffset then return end
		self.listOffset = newOffset
		self:_renderRows()
	end)
	sb:Hide()
	self.scrollbar = sb
	self:_anchorScrollbar()

	-- Recompute visible rows + refresh whenever the parent resizes.
	parent:HookScript("OnSizeChanged", function()
		-- A fitContent list sizing its own parent is already mid-refresh (MINOR 36).
		if self._fitting then return end
		self:_refresh()   -- a resize changes no data, so the cached view stands
	end)

	-- Re-lay on a scale change. The listener is a module-level function taking the instance as its
	-- owner argument, not a closure over `self`: the library's listener table is weak-keyed, and a
	-- closure would keep a list nobody else references alive through its own registration.
	lib:OnScaleChanged(self, RowList._onScaleChanged)

	-- Mouse-wheel drives the scrollbar (not listOffset directly), so the thumb
	-- tracks the wheel and OnValueChanged keeps state in sync.
	parent:EnableMouseWheel(true)
	parent:HookScript("OnMouseWheel", function(_, delta)
		if self._detached or not self.data or #self:_getSortedData() == 0 then return end
		local _, maxOffset = sb:GetMinMaxValues()
		if maxOffset <= 0 then return end
		local newVal = math.max(0, math.min(maxOffset, sb:GetValue() - delta))
		sb:SetValue(newVal)
	end)

	return self
end

-- ---------------------------------------------------------------------------
-- Scale: live metrics, and the re-layout that follows a change (MINOR 29)
-- ---------------------------------------------------------------------------

-- Derive every live dimension from the scale-1.0 constants and the consumer's values. Called at
-- construction and on every scale change, BEFORE any frame is laid out against them.
--
-- Column widths live in `self._colW[col]` (the effective, scaled width per column table) rather
-- than being written back into the consumer's `col.width` as they used to be: a write-back of a
-- scaled number would be scaled again on the next change, and the consumer's table stays theirs.
-- A fixed column with a header is widened to fit the header text at the CURRENT scale (measured
-- with the scaled header font on the probe) plus the sort arrow and its padding.
function RowList:_applyMetrics()
	local S = function(px) return lib:ScaledSize(px) end
	self.rowHeight    = S(self.baseRowHeight)
	self.headerHeight = self.hasHeader and S(HEADER_HEIGHT) or 0
	self.iconSize     = S(ICON_SIZE)
	self.iconGap      = S(ICON_GAP)
	self.leftPad      = S(LEFT_PAD)
	self.colGap       = S(COL_GAP)

	-- Reserved px on the right edge of each ROW for action icons, from the surviving count.
	local n = #self.actions
	self.iconAreaW = (n > 0) and (n * self.iconSize + (n - 1) * self.iconGap + self.leftPad) or 0

	local widen = S(ARROW_GAP + ARROW_W + HEADER_PAD)   -- 22 at scale 1.0
	self._colW = {}
	for _, col in ipairs(self.columns) do
		if isFixed(col) then
			local w
			if col.autoFit then
				w = self:_measureColumn(col)
			else
				w = S(col.width)
			end
			if col.header and self._probe then
				-- A filterable column's header can carry " *" while it filters, so it is measured with
				-- it: a tight column would otherwise truncate the star or push the arrow (peer review L7).
				self._probe:SetText(lib:Brand(col.header .. (col.filterable and " *" or "")))
				local needed = math.ceil((self._probe:GetStringWidth() or 0) + widen)
				if w < needed then w = needed end
			end
			self._colW[col] = w
		end
	end
end

--- The effective (scaled, header-fitted) pixel width of the fixed column keyed `key`, or nil for
--- the auto-width column and for a key the list does not have. This is what `col.width` used to
--- be widened to in place; the consumer's table is no longer written.
function RowList:ColumnWidth(key)
	for _, col in ipairs(self.columns) do
		if col.key == key then return self._colW[col] end
	end
	return nil
end

--- The pixel width a cell of column `key` has RIGHT NOW (MINOR 36), including the auto-width column:
--- the parent's width less the scrollbar gutter and the two chains, never below 0. nil for a key the
--- list does not have, and for the auto column before any row has been laid out (not measured yet).
--- `ColumnWidth` keeps answering nil for the auto column, as it always has, so a
--- consumer summing the fixed widths is unchanged.
function RowList:CellWidth(key)
	for ci, col in ipairs(self.columns) do
		if col.key == key then
			if ci ~= self:_autoIndex() then return self._colW[col] end
			-- nil until a row has been laid out: before that the insets are unknown, and the whole
			-- parent's width would be a wrong number a formatter sizes text against (peer review).
			if not self._autoInsetL then return nil end
			local total = (self.parent:GetWidth() or 0) - SCROLLBAR_GUTTER
			return math.max(0, total - self._autoInsetL - self._autoInsetR)
		end
	end
	return nil
end

-- The lane sits below the header, which moves with the scale.
function RowList:_anchorScrollbar()
	local sb = self.scrollbar
	if not sb then return end
	sb:ClearAllPoints()
	sb:SetPoint("TOPRIGHT",    self.parent, "TOPRIGHT",    -1, -(self.headerHeight + SCROLLBAR_BTN_SIZE))
	sb:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", -1,  SCROLLBAR_BTN_SIZE)
end

-- The whole re-layout: new metrics, every pooled frame re-laid against them, the pool re-fitted to
-- the parent at the new row height, and a repaint. The fonts have already followed in place.
function RowList:_applyScale()
	if self._detached then return end
	self:_applyMetrics()
	if self.header then self:_layoutHeader() end
	for i = 1, #self.rows do self:_layoutRow(self.rows[i], i) end
	self:_anchorScrollbar()
	self:_refresh()
end

function RowList._onScaleChanged(_, _, rl)
	rl:_applyScale()
end

--- Build one header column: the button, its label, the sort arrow, the tooltip and the click.
--- Geometry (width, anchors, sizes) is `_layoutHeader`'s, applied after build and on every scale
--- change.
function RowList:_makeHeaderColumn(parent, col)
	-- A pooled entry from a previous column set, if there is one: `SetColumns` releases the buttons
	-- rather than orphaning them, so a list whose columns change with a tick box builds its header
	-- once for the session. Everything a reused button carries from its old column -- its click, its
	-- tooltip, its arrow -- is reset below, unconditionally.
	local pooled = self._headerPool and table.remove(self._headerPool)
	local btn, fs, arrow
	if pooled then
		btn, fs, arrow = pooled.btn, pooled.fs, pooled.arrow
		btn:Show()
	else
		btn = CreateFrame("Button", nil, parent)
		btn:EnableMouse(true)

		fs = btn:CreateFontString(nil, "OVERLAY")
		fs:SetFontObject(lib:ScaledFont("GameFontNormalSmall"))
		fs:SetAllPoints(btn)
		-- Headers are always LEFT-justified so the sort arrow sits predictably 3 px
		-- right of the last character regardless of the data cells' justification.
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false)
		fs:SetMaxLines(1)

		-- Sort-direction arrow — hidden by default; shown/oriented by
		-- _updateHeaderText on the active sort column. ASC/DESC swaps top<->bottom
		-- in the V axis of the texcoords.
		arrow = btn:CreateTexture(nil, "OVERLAY")
		arrow:SetTexture("Interface\\Calendar\\MoreArrow")
		arrow:Hide()
	end

	self._headerLabels = self._headerLabels or {}
	self._headerLabels[col.key] = { btn = btn, fs = fs, arrow = arrow, col = col }

	-- ALWAYS assigned, both halves, so a reused button cannot keep the previous column's tooltip:
	-- AttachTooltip writes the fields and hooks once, and nil/nil draws nothing.
	lib:AttachTooltip(btn, col.headerTip and (col.header or col.key or "") or nil, col.headerTip,
		self.tooltipOwner and { owner = self.tooltipOwner } or nil)

	-- Any column with a header is sortable unless explicitly opted out. A FILTERABLE column's header --
	-- or every header, on a list built with `headerMenu` -- opens the column menu instead (MINOR 34),
	-- which carries the sort as its first two rows. The click resolves the column by KEY at event
	-- time, for the reason `_buildRowCells` gives: a structurally identical `SetColumns` swaps the
	-- table without rebuilding the header.
	btn:SetScript("OnClick", nil)
	if col.header then
		local rl  = self
		local key = col.key
		-- `headerMenu` on a column that can neither sort nor filter would open a title-only menu
		-- (peer review L6), so such a header stays inert.
		if col.filterable or (self.headerMenu and col.sortable ~= false) then
			btn:SetScript("OnClick", function(b) rl:_openColumnMenu(key, b, true) end)
		elseif col.sortable ~= false then
			btn:SetScript("OnClick", function()
				-- `col.sortDescDefault` (MINOR 34, TOGTools item 8): a column whose FIRST click sorts
				-- high-to-low -- memory, counts, times. Read by key at click time, like the rest.
				local live = rl:_column(key)
				local first = live and live.sortDescDefault and true or false
				if rl.sortKey ~= key then
					rl:_applySort(key, first)
				elseif rl.sortDesc ~= first
					and (rl.sortCycle == "three" or (live and live.sortNone)) then
					-- THE THIRD CLICK (MINOR 36, TOGProfessionMaster inbox 1013eeea): the column has
					-- shown both directions, so this one hands back the model's own order -- a list
					-- whose unsorted order MEANS something (a category tree) needs a way back to it.
					-- The same state `SetSort(nil)` leaves, so the next click behaves the same.
					rl:_applySort(nil, false)
				else
					rl:_applySort(key, not rl.sortDesc)
				end
			end)
		end
	end

	return btn
end

--- A sort the USER asked for, through a header or the column menu. The one place that writes the sort
--- on their behalf, so the two entry points cannot disagree about whether `onSortChanged` fires
--- (MINOR 34). `SetSort` is the consumer's own call and does not fire it -- a consumer is not told
--- about a change it just made.
function RowList:_applySort(key, desc)
	self.sortKey  = key
	self.sortDesc = desc and true or false
	self._dataSorted = nil
	self:_updateHeaderText()
	if self.onSortChanged then
		-- A cleared sort (MINOR 36) reports (nil, nil): there is no direction to report.
		local reported = nil
		if key ~= nil then reported = self.sortDesc end
		self.onSortChanged(self.sortKey, reported, self)
	end
	self:Refresh()
end

-- Refresh every header's label text + sort arrow. The arrow shows only on the
-- active sort column; ASC vs DESC flips the top<->bottom V coords.
function RowList:_updateHeaderText()
	if not self._headerLabels then return end
	for _, h in pairs(self._headerLabels) do
		local text = h.col.header or ""
		-- A column the filter is narrowing says so (MINOR 34), or a list with rows missing reads as
		-- a list with nothing more to show.
		if self:_isFiltering(h.col.key) then text = text .. " *" end
		h.fs:SetText(lib:Brand(text))
		if h.arrow then
			if self.sortKey == h.col.key then
				if self.sortDesc then
					h.arrow:SetTexCoord(0.0, 0.9375, 0.0,    0.6875)
				else
					h.arrow:SetTexCoord(0.0, 0.9375, 0.6875, 0.0)
				end
				-- Anchor 3 px (scaled) right of the last rendered character (headers are
				-- LEFT-justified, so text runs from btn.LEFT to btn.LEFT + textW).
				local textW = h.fs:GetStringWidth() or 0
				h.arrow:ClearAllPoints()
				h.arrow:SetPoint("LEFT", h.btn, "LEFT", textW + lib:ScaledSize(ARROW_GAP), 0)
				h.arrow:Show()
			else
				h.arrow:Hide()
			end
		end
	end
end

--- Set `self.hasHeader` from `columns`, and make sure the header-text probe exists when it is needed.
--- Returns whether the list had a header BEFORE this call, which is what `SetColumns` needs to decide
--- whether to hide a header frame a new column set no longer wants.
---
--- THE PROBE is one hidden FontString per list, carrying the SCALED header font, kept so a scale
--- change can re-measure: `_applyMetrics` widens a fixed column that is narrower than its own header
--- text, and it has to measure in the font the header will actually be drawn in.
---
--- ONE FUNCTION BECAUSE THE FONT IS THE POINT. `New` and `SetColumns` both had these three lines
--- written out, and peer review filed it as F3 against MINOR 33: change the probe's font object in
--- one of them and a list that gained its header through `SetColumns` measures header widths in a
--- different font than a list that was born with one -- columns silently a few pixels out, depending
--- on which path built the list. The `not self._probe` guard also makes it idempotent, so a list
--- re-columned ten times still owns exactly one probe.
function RowList:_syncHeaderState(columns)
	local had = self.hasHeader
	self.hasHeader = false
	for _, col in ipairs(columns) do
		if col.header then self.hasHeader = true; break end
	end
	if self.hasHeader and not self._probe then
		self._probe = UIParent:CreateFontString(nil, "BACKGROUND")
		self._probe:SetFontObject(lib:ScaledFont("GameFontNormalSmall"))
		self._probe:Hide()
	end
	return had
end

function RowList:_buildHeader()
	local h = CreateFrame("Frame", nil, self.parent)
	h:SetPoint("TOPLEFT",  self.parent, "TOPLEFT",   0,                0)
	h:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -SCROLLBAR_GUTTER, 0)

	local bg = h:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(h)
	bg:SetColorTexture(1, 1, 1, 0.08)

	-- The underline is the list's OWN mark, so it takes the configured accent like the selection tint
	-- in `_renderRows` does -- it was a hardcoded (1, 0.82, 0) until MINOR 33, which was then the
	-- accent's DEFAULT ("ffFFD100") and therefore invisible as a bug until someone re-themed, at which
	-- point a list drew a gold line under an orange-branded window. (The default itself is the suite
	-- orange as of MINOR 36.) Resolved at build rather than per populate because it is one static texture; a consumer
	-- who re-accents after the list exists gets the new colour on the next list they build.
	local border = h:CreateTexture(nil, "OVERLAY")
	border:SetHeight(1)
	border:SetPoint("BOTTOMLEFT",  h, "BOTTOMLEFT",  0, 0)
	border:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 0)
	local hr, hg, hb = lib:AccentRGB()
	border:SetColorTexture(hr, hg, hb, 0.4)

	self._headerBorder = border   -- kept so the colour is readable: an accent this list never applied
	                              -- is otherwise only claimable in a comment, which is how the
	                              -- hardcoded gold survived four rounds of review.
	self.header = h
	self:_buildHeaderColumns()
end

--- (Re)build the per-column header buttons inside the existing header frame. Split out of
--- `_buildHeader` so `SetColumns` can re-run it against a new column set without a second header
--- frame -- the frame, its background and its gold underline are the list's for its whole life.
function RowList:_buildHeaderColumns()
	self._headerPool = self._headerPool or {}
	-- Release what is there. A header button's OnClick closes over its COLUMN's key, so a button
	-- reused for a different column with the old script would sort by the old key.
	for _, entry in pairs(self._headerLabels or {}) do
		entry.btn:Hide()
		entry.btn:ClearAllPoints()
		entry.btn:SetScript("OnClick", nil)
		entry.arrow:Hide()
		self._headerPool[#self._headerPool + 1] = entry
	end
	self._headerLabels = {}

	for _, col in ipairs(self.columns) do
		self:_makeHeaderColumn(self.header, col)
	end
	self:_layoutHeader()
end

-- The auto-width column's index: the FIRST width-less column (New rejects a second).
function RowList:_autoIndex()
	for ci, col in ipairs(self.columns) do
		if not isFixed(col) then return ci end
	end
	return nil
end

-- Place every header column at the current metrics. Same array-order placement as `_layoutRow`:
-- columns before the auto-width column chain LEFT->LEFT; columns after chain RIGHT->RIGHT; the
-- auto column fills the middle. `Tests/rowlist_spec.lua` pins that the two chains agree.
function RowList:_layoutHeader()
	local h = self.header
	h:SetHeight(self.headerHeight)
	local labels = self._headerLabels or {}
	local colW = self._colW
	local autoIdx = self:_autoIndex()

	local function place(col, leftOffset, rightOffset)
		local entry = labels[col.key]
		if not entry then return end
		local btn = entry.btn
		btn:ClearAllPoints()
		btn:SetHeight(self.headerHeight)
		if leftOffset and rightOffset then
			btn:SetPoint("LEFT",  h, "LEFT",  leftOffset,   0)
			btn:SetPoint("RIGHT", h, "RIGHT", -rightOffset, 0)
		elseif leftOffset then
			btn:SetWidth(colW[col])
			btn:SetPoint("LEFT", h, "LEFT", leftOffset, 0)
		else
			btn:SetWidth(colW[col])
			btn:SetPoint("RIGHT", h, "RIGHT", -rightOffset, 0)
		end
		entry.arrow:SetSize(lib:ScaledSize(ARROW_W), lib:ScaledSize(ARROW_H))
	end

	local leftOffset = self.leftPad
	if autoIdx then
		for ci = 1, autoIdx - 1 do
			local col = self.columns[ci]
			leftOffset = leftOffset + gapBefore(col)
			place(col, leftOffset, nil)
			leftOffset = leftOffset + colW[col] + self.colGap
		end
	end

	local rightOffset = self.iconAreaW + self.colGap
	local rightChainStart = autoIdx and (autoIdx + 1) or 1
	for ci = #self.columns, rightChainStart, -1 do
		local col = self.columns[ci]
		if isFixed(col) then
			place(col, nil, rightOffset)
			rightOffset = rightOffset + colW[col] + self.colGap + gapBefore(col)
		end
	end

	if autoIdx then
		place(self.columns[autoIdx], leftOffset + gapBefore(self.columns[autoIdx]), rightOffset)
	end

	self:_updateHeaderText()
end

-- The rows the list DRAWS: `self.data` narrowed by the column filters and the search (MINOR 34), then
-- sorted by self.sortKey when set -- unless the list is `externalSort`, where the consumer has already
-- ordered `data` and the rows are drawn in that order. Cached on self._dataSorted; invalidated by
-- SetData, a sort, a filter, a search and SetColumns. With nothing narrowing and nothing to sort, it
-- is `self.data` itself, exactly as before MINOR 34.
function RowList:_getSortedData()
	if self._dataSorted then return self._dataSorted end
	local narrowed = self:_narrowedData()
	if not self.sortKey or self.externalSort then
		if narrowed == self.data then return self.data end
		self._dataSorted = narrowed
		return narrowed
	end

	local key, desc = self.sortKey, self.sortDesc
	-- A column may ask that empty/absent cells ALWAYS sink to the bottom (both directions) instead of
	-- flipping top<->bottom with the sort arrow — e.g. an EP-delta column where "no EP value" is not a
	-- number and should read as "n/a", never as the smallest or largest value. A column may also supply
	-- `sortValue(entry)` (MINOR 30): the header sorts on that while the cell still shows `entry[key]` --
	-- an MM/DD/YYYY string sorts by a YYYYMMDD number.
	local nilsLast, sortValue
	for _, c in ipairs(self.columns or {}) do
		if c.key == key then nilsLast, sortValue = c.nilsLast, c.sortValue; break end
	end

	-- DETERMINISTIC (MINOR 30, ClassicCalendar inbox 4d698ce3 item 4): the rows are DECORATED with their
	-- sort value and their SetData position, and the comparator falls through value -> the consumer's
	-- `tiebreak(a, b)` -> position. So equal cells keep the order they were given, which `table.sort` (a
	-- quicksort in Lua 5.1) does not do on its own. A replicated table needs this: every client sorting
	-- the same data must see the same rows in the same order. `sortValue` runs ONCE per entry here,
	-- never inside the comparator.
	--
	-- GROUP HEADER ROWS (MINOR 36) are not sorted data: the library sorts each header's rows UNDER it.
	-- Every entry carries its group number `g` (a header opens the next group; rows before the first
	-- header are group 0) and `h` for the header itself, and the comparator orders by group, header
	-- first, before anything else -- so headers keep their order and a row never leaves its group.
	-- Groups are flat: a nested tree that wants its sub-groups sorted uses `externalSort`.
	local tiebreak = self.tiebreak
	local deco, g = {}, 0
	for i, e in ipairs(narrowed) do
		local v, h = nil, self:_isHeaderRow(e)
		if h then
			g = g + 1
		elseif sortValue then
			v = sortValue(e)
		else
			v = e[key]
		end
		deco[i] = { e = e, v = v, i = i, g = g, h = h }
	end

	-- -1 when x's value sorts before y's in the current direction, 1 after, 0 for a tie.
	local function byValue(x, y)
		local av, bv = x.v, y.v
		if av == nil and bv == nil then return 0 end
		if nilsLast then
			if av == nil then return 1 end    -- a is nil → a sorts AFTER b, regardless of direction
			if bv == nil then return -1 end   -- b is nil → a sorts before b
		else
			-- Peer review finding 2: these two returns were the exact INVERSE of the comments beside them, so
			-- every sortable column put its blank cells at the TOP on first click — and the header handler sets
			-- ascending whenever you click a new column, so ascending is what a user always sees first. On the
			-- example the comment itself gives, an EP-delta column, the first click filled the top of the window
			-- with "n/a" rows. Code, comments and two specs were in three-way disagreement, which is the worst
			-- available state: each of the three reads as corroboration for whichever you looked at first.
			--
			-- Traced in both directions rather than assumed symmetric: ASC (desc = false) → a's nil sorts
			-- after b and b's nil sorts after a. DESC inverts both.
			if av == nil then return desc and -1 or 1 end   -- nils last in ASC, first in DESC
			if bv == nil then return desc and 1 or -1 end
		end
		local r = 0
		-- Numeric-aware compare: if BOTH cells parse as numbers, order by value — so a
		-- column of "3" / "12" (or 3 / 12) sorts 3 < 12, never lexically ("12" < "3").
		-- Uses tonumber, not type=="number", so a consumer that stores pre-formatted
		-- display strings still gets a correct numeric sort — no per-column flag to forget.
		local an, bn = tonumber(av), tonumber(bv)
		if an and bn then
			if an < bn then r = -1 elseif an > bn then r = 1 end
		else
			-- Case-insensitive lex compare, with a case-sensitive tiebreak -- a total order over DISTINCT
			-- values (peer review finding 11). Exactly-equal values are a tie, decided below.
			local as, bs = tostring(av), tostring(bv)
			local al, bl = as:lower(), bs:lower()
			if al < bl then r = -1 elseif al > bl then r = 1
			elseif as < bs then r = -1 elseif as > bs then r = 1 end
		end
		if desc then r = -r end
		return r
	end

	table.sort(deco, function(x, y)
		if x.g ~= y.g then return x.g < y.g end
		if x.h ~= y.h then return x.h end
		local r = byValue(x, y)
		if r ~= 0 then return r < 0 end
		-- The consumer's tiebreak is an IDENTITY order (a unique id, a name), so the sort arrow does not
		-- flip it. Asked both ways because `false` alone does not say "after": it may be "equal too", and
		-- only a tie the tiebreak ALSO calls equal falls through to the SetData position.
		if tiebreak then
			if tiebreak(x.e, y.e) then return true end
			if tiebreak(y.e, x.e) then return false end
		end
		return x.i < y.i
	end)
	local sorted = {}
	for i, d in ipairs(deco) do sorted[i] = d.e end

	self._dataSorted = sorted
	return sorted
end

-- The cell's font: the consumer's `col.font` (a global font name) or the default, through
-- ScaledFont so it follows the scale in place. The base object is the fallback for a name the
-- client does not have.
local function cellFont(col)
	local name = col.font or "GameFontHighlightSmall"
	return lib:ScaledFont(name) or _G[name] or name
end

-- Which kind of cell a column needs. Only cells of the SAME kind may be reused for a new column set
-- (MINOR 33): a FontString cannot serve a checkbox column.
local function cellKind(col)
	if col.checkbox then return "checkbox" end
	if col.expander then return "expander" end   -- MINOR 34
	if col.button then return "button" end       -- MINOR 34
	if col.icon then return "icon" end
	return "text"
end

-- The kinds that SHOW a string, and so are the ones the search reads.
local function showsText(col)
	local k = cellKind(col)
	return k == "text" or k == "button"
end

--- The string a text or button cell shows for `entry`: `format`, then the class name or class tint.
--- ONE function for the draw, the filter labels, the search and the autoFit measure (MINOR 34), so
--- "what you see is what you filter" holds by construction -- four copies would drift the first time
--- one of them learned about a new column option. A non-text column answers its raw value as text.
---
--- `width` and `measure` (MINOR 36, TOGProfessionMaster inbox c5476af2) are handed to `col.format` as its
--- third and fourth arguments ONLY when the text is being DRAWN: the cell's pixel width at the current
--- scale, and `measure(text)` -> the rendered width in the cell's font. Filter labels, the search and the
--- autoFit measure pass neither, so a formatter that fits to the width answers its full text there --
--- which is what a filter or a search should see.
function RowList:_cellText(col, entry, width, measure)
	local val = entry[col.key]
	if val == nil then val = "" end
	if not showsText(col) then return tostring(val) end
	-- A `button` column's per-row presence and label (MINOR 36, TOGProfessionMaster inbox 337bb7d3): a row
	-- the button does not apply to shows nothing, and `col.text(entry)` IS the label -- not run through
	-- `format` or the class tint. Here rather than in the draw alone, so the search and the filter read
	-- exactly what the row shows.
	if col.button then
		if col.show and not col.show(entry) then return "" end
		if col.text then
			local t = col.text(entry)
			return t == nil and "" or tostring(t)
		end
	end
	-- Optional per-column display formatter (display only; the row data stays raw so sorting keeps
	-- its value).
	--
	-- The WHOLE ENTRY is passed as a second argument (MINOR 25). The one-argument form cannot express
	-- the common icon+link cell: an item column has to DISPLAY "|Ticon|t |Hitem:..|h[Name]|h|r" and
	-- SORT on the plain name, and with only the value in hand a formatter cannot reach the icon or the
	-- link. Consumers then put the display string in the sorted field, and the header silently sorts
	-- by icon path -- which is what Dibs' Loots tab did. Additive: every existing `function(v)`
	-- formatter ignores the extra argument unchanged.
	if col.format then val = col.format(val, entry, width, measure) end
	local classTok = entry.classFile
	local classDisplay = self.classDisplay or lib.config.classDisplay
	if col.classDisplay and classTok and classDisplay then
		-- Fully coloured + localized class name (consumer-supplied).
		val = classDisplay(classTok)
	elseif col.color == "class" and classTok then
		-- Tint this cell's own value by class colour.
		local cls = (tostring(classTok):upper():gsub("%s+", ""))
		local c = lib:ClassColor(cls)
		if c then val = "|c" .. c .. tostring(val) .. "|r" end
	end
	return tostring(val)
end

--- The plain label of a cell -- what the filter lists and what the search matches.
function RowList:_cellLabel(col, entry)
	return stripEscapes(self:_cellText(col, entry))
end

--- The column set's column for `key`, or nil.
function RowList:_column(key)
	for _, col in ipairs(self.columns) do
		if col.key == key then return col end
	end
	return nil
end

--- The column `entry._indent` shifts, and whose text a `_header = true` row shows (MINOR 36): `indentKey`'s
--- column when the list names one, else the first column that shows text. nil when no column does.
function RowList:_indentColumn()
	if self.indentKey ~= nil then
		local col = self:_column(self.indentKey)
		if col then return col end
	end
	for _, col in ipairs(self.columns) do
		if showsText(col) then return col end
	end
	return nil
end

--- Is `entry` a group header row (MINOR 36)? `opts.isHeader(entry)` decides when given, else `entry._header`.
function RowList:_isHeaderRow(entry)
	if self.isHeaderFn then return self.isHeaderFn(entry) and true or false end
	return entry._header and true or false
end

--- The heading a header row shows: the string the flag carries, or, for `true`, the indent column's text.
function RowList:_headerText(entry)
	local h
	if self.isHeaderFn then h = self.isHeaderFn(entry) else h = entry._header end
	if type(h) == "string" then return h end
	local col = self:_indentColumn()
	return col and self:_cellText(col, entry) or ""
end

--- The indent in live pixels for `entry`: its `_indent` level times the scaled step, never negative.
function RowList:_indentPx(entry)
	local level = tonumber(entry._indent) or 0
	if level <= 0 then return 0 end
	return lib:ScaledSize(level * self.indentStep)
end

--- Is the filter hiding any value of column `key`? With no key: of any column.
function RowList:_isFiltering(key)
	for k, ex in pairs(self.colExcluded or {}) do
		if (key == nil or k == key) and next(ex) then return true end
	end
	return false
end

--- Does `entry` pass every column filter except `exceptKey`'s? The exception is what makes the filter
--- menu CASCADE: a column's value list is drawn from the rows the OTHER filters let through, so ticking
--- one of its own values never makes the rest vanish from its own menu.
function RowList:_passesFilters(entry, exceptKey)
	for k, ex in pairs(self.colExcluded) do
		if k ~= exceptKey and next(ex) then
			local col = self:_column(k)
			if col and ex[self:_cellLabel(col, entry)] then return false end
		end
	end
	return true
end

--- The text a WORD search reads for `entry` (MINOR 36): every shown cell's label and the consumer's
--- `searchText(entry)`, colour escapes stripped. Built once per entry and kept until the data changes
--- (`SetData`, `Refresh`, `SetColumns`), so `searchText` runs once per entry, not once per keystroke.
function RowList:_searchHaystack(entry)
	local cache = self._searchHay
	if not cache then
		cache = setmetatable({}, { __mode = "k" })
		self._searchHay = cache
	end
	local hay = cache[entry]
	if hay then return hay end
	local parts = {}
	for _, col in ipairs(self.columns) do
		if showsText(col) then parts[#parts + 1] = self:_cellLabel(col, entry) end
	end
	if self.searchTextFn then
		local extra = self.searchTextFn(entry)
		if extra ~= nil then parts[#parts + 1] = stripEscapes(tostring(extra)) end
	end
	hay = table.concat(parts, " ")
	cache[entry] = hay
	return hay
end

--- Does `entry` match the search? By default: the query as ONE plain substring of any text or button
--- cell. With `opts.searchText` or `opts.searchTokens` (MINOR 36): every WORD of the query somewhere in
--- the cells and the hidden text, any order, any case -- `W:SearchMatch`'s rule, by calling it.
function RowList:_matchesSearch(entry)
	local q = self.searchText
	if not q then return true end
	if self.searchTextFn or self.searchTokens then
		return lib:SearchMatch(q, self:_searchHaystack(entry))
	end
	for _, col in ipairs(self.columns) do
		if showsText(col) and self:_cellLabel(col, entry):lower():find(q, 1, true) then return true end
	end
	return false
end

--- `self.data` narrowed by the filters and the search, in `data`'s order. `self.data` itself when
--- neither is active, so a list that uses neither pays nothing and sees no change.
---
--- A GROUP HEADER ROW (MINOR 36) is not data, so no column filter judges it. It is drawn when a row of
--- its group (the rows after it, up to the next header) survives, or when the search matches its own
--- heading -- so a search never leaves a heading with nothing under it, and still finds a collapsed group
--- by name.
function RowList:_narrowedData()
	if not (self.searchText or self:_isFiltering()) then return self.data end
	local out, header, headerIn = {}, nil, false
	local q = self.searchText
	for _, e in ipairs(self.data) do
		if self:_isHeaderRow(e) then
			header, headerIn = e, false
			local hay = q and stripEscapes(self:_headerText(e))
			local hit = hay and ((self.searchTextFn or self.searchTokens) and lib:SearchMatch(q, hay)
				or hay:lower():find(q, 1, true))
			if hit then
				out[#out + 1] = e
				headerIn = true
			end
		elseif self:_passesFilters(e) and self:_matchesSearch(e) then
			if header and not headerIn then
				out[#out + 1] = header
				headerIn = true
			end
			out[#out + 1] = e
		end
	end
	return out
end

--- Free-text search over every text and button cell's displayed text: case-insensitive, a plain
--- substring (no patterns, so "[" and "%" match themselves), composed with the column filters. nil or
--- "" clears it. The list goes back to its top, since the rows it was scrolled to may be gone.
--- (MINOR 34, TOGTools inbox c571dee6.)
function RowList:SetSearch(text)
	text = text and tostring(text):lower() or nil
	if text == "" then text = nil end
	if text == self.searchText then return end
	self.searchText  = text
	self._dataSorted = nil
	self.listOffset  = 0
	-- `_refresh`, not `Refresh`: a new query changes no data, so the per-entry search text built for the
	-- last keystroke stands (MINOR 36). `_dataSorted` is dropped just above, which is all Refresh adds.
	self:_refresh()
end

--- Drop every column filter (MINOR 34). The search is left alone; `SetSearch(nil)` clears that.
function RowList:ClearFilters()
	self.colExcluded = {}
	self._dataSorted = nil
	self:_updateHeaderText()
	self:Refresh()
end

--- The width an `autoFit` column needs at the current scale: the widest cell over ALL of `data` (not
--- the filtered view, so a column does not change width as the player filters), in the column's own
--- scaled font, plus padding, and never under `minWidth` (a scale-1.0 value). The header's own width is
--- applied after this by `_applyMetrics`, the same way it is for any fixed column.
function RowList:_cellProbeFor(col)
	if not self._cellProbe then
		self._cellProbe = UIParent:CreateFontString(nil, "BACKGROUND")
		self._cellProbe:Hide()
	end
	self._cellProbe:SetFontObject(cellFont(col))
	return self._cellProbe
end

--- `measure(text)` for `col.format` (MINOR 36): the rendered width of `text` in the column's own scaled
--- font. One closure per column table, kept for the life of the list, so a repaint builds none.
function RowList:_measurerFor(col)
	self._measurers = self._measurers or setmetatable({}, { __mode = "k" })
	local m = self._measurers[col]
	if not m then
		local rl = self
		m = function(text)
			local probe = rl:_cellProbeFor(col)
			probe:SetText(tostring(text or ""))
			return probe:GetStringWidth() or 0
		end
		self._measurers[col] = m
	end
	return m
end

function RowList:_measureColumn(col)
	local floor = lib:ScaledSize(col.minWidth or 0)
	local probe = self:_cellProbeFor(col)
	local widest = 0
	for _, e in ipairs(self.data or {}) do
		-- A header row draws its heading across the whole row, not in this column (MINOR 36).
		if not self:_isHeaderRow(e) then
			probe:SetText(self:_cellText(col, e))
			local w = probe:GetStringWidth() or 0
			if w > widest then widest = w end
		end
	end
	if widest <= 0 then return floor end
	return math.max(floor, math.ceil(widest + lib:ScaledSize(AUTOFIT_PAD)))
end

--- Does any column measure itself? SetData re-lays the list only when one does.
function RowList:_hasAutoFit()
	for _, col in ipairs(self.columns or {}) do
		if col.autoFit then return true end
	end
	return false
end

--- Re-derive the metrics and re-lay the header and every pooled row, without a repaint. What a scale
--- change does, and what SetData does when an autoFit column's width may have moved.
function RowList:_relayout()
	if self._detached then return end
	self:_applyMetrics()
	if self.header then self:_layoutHeader() end
	for i = 1, #self.rows do self:_layoutRow(self.rows[i], i) end
end

-- The order the menu lists values in: the header's own order -- numbers by value, text case-folded,
-- with a case-sensitive tiebreak -- so "9" comes before "10" and "alpha" before "Zeta" (peer review L4;
-- the first build sorted raw bytes).
local function labelLess(a, b)
	local na, nb = tonumber(a), tonumber(b)
	if na and nb then
		if na ~= nb then return na < nb end
		return a < b
	end
	local al, bl = a:lower(), b:lower()
	if al ~= bl then return al < bl end
	return a < b
end

-- `list` cut to `cap` entries: returns the shown part and how many were left out. `list` is untouched.
local function capped(list, cap)
	if #list <= cap then return list, 0 end
	local shown = {}
	for i = 1, cap do shown[i] = list[i] end
	return shown, #list - cap
end

--- How many value rows the menu can draw and still fit on screen (MINOR 34, peer review M2): the menu
--- does not scroll and is clamped to the screen, so a 200-row list put ~180 rows out of reach. `fixed`
--- is the rows above the values; `withSearch` reserves the root's search box. Never above
--- FILTER_VALUE_CAP, never below one.
local function valueCapacity(fixed, withSearch)
	return math.max(1, math.min(FILTER_VALUE_CAP, lib:MenuCapacity(withSearch) - fixed))
end

-- The column menu's value rows: distinct labels of `col` over the rows the OTHER filters pass, sorted.
-- `query` (the menu's search box) narrows them. Returns ALL of them; the caller caps what it draws.
function RowList:_filterValues(col, query)
	local seen, list = {}, {}
	for _, e in ipairs(self.data) do
		if not self:_isHeaderRow(e) and self:_passesFilters(e, col.key) then
			local lbl = self:_cellLabel(col, e)
			if lbl ~= "" and not seen[lbl] and (not query or lbl:lower():find(query, 1, true)) then
				seen[lbl] = true
				list[#list + 1] = lbl
			end
		end
	end
	table.sort(list, labelLess)
	return list
end

-- The same values grouped by `col.filterGroup(entry)` (Zone under its continent). A group with no
-- label is "Other". Groups and the values in each are sorted.
function RowList:_filterGroups(col, query)
	local order, byGroup = {}, {}
	for _, e in ipairs(self.data) do
		if not self:_isHeaderRow(e) and self:_passesFilters(e, col.key) then
			local lbl = self:_cellLabel(col, e)
			if lbl ~= "" and (not query or lbl:lower():find(query, 1, true)) then
				local g = col.filterGroup(e)
				g = (g == nil or g == "") and "Other" or tostring(g)
				local grp = byGroup[g]
				if not grp then
					grp = { label = g, values = {}, seen = {} }
					byGroup[g] = grp
					order[#order + 1] = g
				end
				if not grp.seen[lbl] then
					grp.seen[lbl] = true
					grp.values[#grp.values + 1] = lbl
				end
			end
		end
	end
	table.sort(order, labelLess)
	local out = {}
	for _, g in ipairs(order) do
		table.sort(byGroup[g].values, labelLess)
		out[#out + 1] = { label = g, values = byGroup[g].values }
	end
	return out
end

--- Forget excluded values the data no longer has (peer review M3). The menu lists only values that are
--- present, so an exclusion on an absent one could never be ticked back from the UI -- the header kept
--- its filtered marker and only `ClearFilters()` from code could reach it. A value that comes back in
--- a later SetData therefore comes back SHOWN.
function RowList:_pruneFilters()
	for k, ex in pairs(self.colExcluded) do
		local col = next(ex) and self:_column(k)
		if col then
			local present = {}
			for _, e in ipairs(self.data) do present[self:_cellLabel(col, e)] = true end
			for v in pairs(ex) do
				if not present[v] then ex[v] = nil end
			end
		end
	end
end

--- Rebuild after a filter change: the view, the header's filtered marker, the rows.
function RowList:_commitFilter()
	self._dataSorted = nil
	self.listOffset  = 0
	self:_updateHeaderText()
	self:Refresh()
end

--- The items `W:OpenMenu` draws for column `key`'s menu. Split from `_openColumnMenu` so the menu's
--- search box can call it again per keystroke, and so a spec can read what the menu offers.
function RowList:_columnMenuItems(key, query)
	local col = self:_column(key)
	if not col then return {} end
	local rl, items = self, {}
	items[#items + 1] = { text = col.header or tostring(key), isTitle = true }
	if col.sortable ~= false then
		items[#items + 1] = { text = "Sort ascending",  keepOpen = false,
			checked = function() return rl.sortKey == key and not rl.sortDesc end,
			onClick = function() rl:_applySort(key, false) end }
		items[#items + 1] = { text = "Sort descending", keepOpen = false,
			checked = function() return rl.sortKey == key and rl.sortDesc end,
			onClick = function() rl:_applySort(key, true) end }
	end
	if not col.filterable then return items end

	local ex = self.colExcluded[key]
	if not ex then ex = {}; self.colExcluded[key] = ex end
	local function valueItem(v)
		return { text = v, keepOpen = true,
			checked = function() return not ex[v] end,
			onClick = function()
				if ex[v] then ex[v] = nil else ex[v] = true end
				rl:_commitFilter()
			end }
	end
	-- Select all / Clear all over `vals` -- EVERY value the menu stands for, not only the ones it has
	-- room to draw (peer review M1: with 350 values Clear all hid 200). At the ROOT they re-draw the
	-- menu in place through its own search callback, which keeps what the player typed; re-opening it
	-- cleared the box (peer review L3). Inside a group submenu they close the menu, because a submenu
	-- cannot be re-drawn from here.
	local function bulk(label, vals, checked, redraw)
		return { text = label, keepOpen = redraw and true or false,
			onClick = function()
				for _, v in ipairs(vals) do
					if checked then ex[v] = nil else ex[v] = true end
				end
				rl:_commitFilter()
				local root = redraw and lib._menus and lib._menus[1]
				if root and root._onSearch then
					root._onSearch(root.search and root.search:GetText() or "")
				end
			end }
	end
	local function moreLine(cut, hint)
		return { text = ("%d more (not shown)"):format(cut), disabled = true, tooltipTitle = hint }
	end

	-- Title, the two sorts, the spacer and the two bulk rows sit above the values, plus a "more" line.
	local fixed = #items + 4
	items[#items + 1] = { text = "", disabled = true }
	if col.filterGroup then
		local groups, all = self:_filterGroups(col, query), {}
		for _, g in ipairs(groups) do
			for _, v in ipairs(g.values) do all[#all + 1] = v end
		end
		items[#items + 1] = bulk("Select all", all, true, true)
		items[#items + 1] = bulk("Clear all",  all, false, true)
		local shownGroups, cutGroups = capped(groups, valueCapacity(fixed, true))
		for _, g in ipairs(shownGroups) do
			local vals = g.values
			items[#items + 1] = { text = g.label, children = function()
				-- A submenu has no search box and the same screen to fit in (two bulk rows + "more").
				local shown, cut = capped(vals, valueCapacity(3, false))
				local sub = { bulk("Select all", vals, true, false), bulk("Clear all", vals, false, false) }
				for _, v in ipairs(shown) do sub[#sub + 1] = valueItem(v) end
				if cut > 0 then sub[#sub + 1] = moreLine(cut, "Type in the search box to narrow the list.") end
				return sub
			end }
		end
		if cutGroups > 0 then
			items[#items + 1] = moreLine(cutGroups, "Type in the box above to narrow the list.")
		end
	else
		local values = self:_filterValues(col, query)
		items[#items + 1] = bulk("Select all", values, true, true)
		items[#items + 1] = bulk("Clear all",  values, false, true)
		local shown, cut = capped(values, valueCapacity(fixed, true))
		for _, v in ipairs(shown) do items[#items + 1] = valueItem(v) end
		if cut > 0 then items[#items + 1] = moreLine(cut, "Type in the box above to narrow the list.") end
	end
	return items
end

--- Open column `key`'s menu under its header (MINOR 34, TOGTools inbox c571dee6): sort ascending and
--- descending, then, for a `filterable` column, a checkbox per distinct value with Select all / Clear
--- all. The values CASCADE (see `_passesFilters`), `filterGroup` nests them, and a filterable menu
--- carries a search box that narrows the value list as the player types. Built on `W:OpenMenu`, so it
--- is the same menu, the same strata and the same click-outside close as every other menu here.
--- `toggle` (the header's own click): a second click on the header that opened the menu closes it.
function RowList:_openColumnMenu(key, anchor, toggle)
	local col = self:_column(key)
	if not (col and anchor) then return end
	if toggle and lib:CloseMenuFor(anchor) then return end
	self._menuAnchor = anchor
	local rl = self
	return lib:OpenMenu(anchor, self:_columnMenuItems(key), {
		keepOpen = true,
		search   = col.filterable and true or nil,
		itemsFor = col.filterable and function(q)
			q = q and q:lower() or ""
			return rl:_columnMenuItems(key, q ~= "" and q or nil)
		end or nil,
	})
end

-- Hand this row's current cells, overlays and strike lines back to its own pools. Nothing is
-- destroyed, because WoW has no way to destroy a frame or a region -- which is precisely why
-- `SetColumns` pools rather than rebuilding: a consumer whose column set changes with a tick box
-- would otherwise leak a full set of cells every time it was toggled.
--
-- EVERY SCRIPT IS CLEARED ON RELEASE, and that is not tidiness. A checkbox's OnClick and an
-- overlay's OnEnter/OnLeave/OnMouseDown each close over the COLUMN they were built for; a reused
-- frame that kept them would call the old column's handler with the new column's data, which looks
-- like a consumer bug and is not one.
-- THE KIND TRAVELS ON THE CELL, not in a table beside it. Until MINOR 33 this read
-- `row._cellPool[row._cellKinds[key]]` -- a parallel table keyed by COLUMN KEY -- and peer review
-- filed it as F4: any cell that reached `row.cells` without its kind being written in the same
-- breath turned into `row._cellPool[nil]`, nil, and `attempt to index a nil value` raised out of
-- `SetColumns` into the consumer, far from the write that caused it. Keying by column key made it
-- worse than a plain invariant, because two columns sharing a key collapse to ONE kind entry while
-- still being two cells. A field on the frame cannot drift from the frame.
local function releaseRowCells(row)
	for _, cell in pairs(row.cells) do
		cell:Hide()
		cell:ClearAllPoints()
		-- Only the kinds built as Buttons carry an OnClick. A text cell is a FontString and an icon
		-- cell a plain Frame: both HAVE SetScript, and the client raises `Doesn't have a "OnClick"
		-- script` on them -- which the old `if cell.SetScript` guard let through, so SetColumns with a
		-- new set crashed on any list with a text column (ItemDB, inbox 91e50ebd, in the client on
		-- Classic Era; shipped in MINOR 33).
		local k = cell._lagwKind
		if k == "checkbox" or k == "expander" or k == "button" then cell:SetScript("OnClick", nil) end
		-- A `button` cell (MINOR 34) also carries its tooltip and its right-click forward, each closed
		-- over the column it was built for.
		if cell._lagwKind == "button" then
			cell:SetScript("OnEnter", nil)
			cell:SetScript("OnLeave", nil)
			cell:SetScript("OnMouseDown", nil)
		end
		-- A cell with no kind was not built by `_buildRowCells`. It is already hidden, unanchored and
		-- stripped of scripts by the three lines above, so letting it fall out of the pool costs one
		-- re-created frame and nothing else -- which is the right trade against raising into a
		-- consumer's repaint for a frame the library did not make.
		local bucket = cell._lagwKind and row._cellPool[cell._lagwKind]
		if bucket then bucket[#bucket + 1] = cell end
	end
	for _, ov in pairs(row.cellOverlays or {}) do
		ov:Hide()
		ov:ClearAllPoints()
		ov:SetScript("OnEnter", nil)
		ov:SetScript("OnLeave", nil)
		ov:SetScript("OnMouseDown", nil)
		row._overlayPool[#row._overlayPool + 1] = ov
	end
	for _, st in pairs(row.cellStrikes or {}) do
		st:Hide()
		st:ClearAllPoints()
		row._strikePool[#row._strikePool + 1] = st
	end
	row.cells, row.cellOverlays, row.cellStrikes = {}, nil, nil
end

local function takePooled(pool)
	local n = #pool
	if n == 0 then return nil end
	local item = pool[n]
	pool[n] = nil
	item:Show()
	return item
end

--- Build (or rebuild) this row's cells, overlays and strike lines for the CURRENT column set, and
--- install the per-cell scripts. Called once from `_buildRow` and again for every pooled row by
--- `SetColumns`. It does no geometry: `_layoutRow` places what this creates.
function RowList:_buildRowCells(row, i)
	releaseRowCells(row)
	local cells, overlays, strikes = row.cells, nil, nil
	local rl, entryAt = self, row._entryAt

	-- EVERY SCRIPT BELOW RESOLVES ITS COLUMN AT EVENT TIME, `rl.columns[ci]`, and never closes over
	-- the column table it was built from -- the same rule this widget already applies to the ENTRY,
	-- and for the same reason. `SetColumns` may hand over a set that is structurally identical but
	-- carries fresh closures (a consumer who rebuilds their column table on every repaint does
	-- exactly that), and in that case nothing is rebuilt; a script holding the old table would go on
	-- calling the previous repaint's `onCellClick` forever, with nothing to see.
	for ci, col in ipairs(self.columns) do
		local kind = cellKind(col)
		local pooled = takePooled(row._cellPool[kind])
		if kind == "checkbox" then
			local cb = pooled or CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
			cells[col.key] = cb
			if col.onToggle then
				cb:SetScript("OnClick", function(self_)
					local live = rl.columns[ci]
					if not (live and live.onToggle) then return end
					local entry, idx = entryAt()
					if entry then
						local val = self_:GetChecked() and true or false
						-- Keep row data in sync with the visible state so a later
						-- re-render (resize/scroll/sort/Refresh) doesn't revert it.
						entry[live.key] = val
						live.onToggle(entry, val, idx, rl)
					end
				end)
			end
		elseif kind == "expander" then
			-- A tree toggle (MINOR 34, FastGuildInvite inbox 7e28e319): "+" collapsed, "-" expanded,
			-- bound to entry[key]. TRI-STATE, as FGI's is: true expanded, false collapsed, nil means the
			-- row has nothing to expand and the button is hidden -- so leaf rows in the same list simply
			-- carry no value. The OWNER decides what expanding means (it splices child rows into `data`
			-- and calls SetData), so the click reports the NEW value and does not write the entry itself;
			-- a write here would flip it twice for an owner that also sets it.
			local btn = pooled
			if not btn then
				btn = CreateFrame("Button", nil, row)
				local fs = btn:CreateFontString(nil, "OVERLAY")
				fs:SetAllPoints(btn)
				fs:SetJustifyH("CENTER")
				btn.label = fs
			end
			btn.label:SetFontObject(lib:ScaledFont(col.font or "GameFontNormalSmall"))
			cells[col.key] = btn
			btn:SetScript("OnClick", function()
				local live = rl.columns[ci]
				if not (live and live.onToggle) then return end
				local entry, idx = entryAt()
				if entry and entry[live.key] ~= nil then
					live.onToggle(entry, not entry[live.key], idx, rl)
				end
			end)
		elseif kind == "button" then
			-- A TEXT CELL YOU CAN CLICK (MINOR 34, FastGuildInvite inbox 7e28e319): a Button carrying its
			-- own label, because a FontString takes no mouse. Sized and anchored exactly like a text cell,
			-- with the hover highlight the rest of the list's clickable things use.
			--   col.onClick(entry, idx, rl, mouseButton, cellFrame)
			--   col.cellTip(entry) -> text   a tooltip under the column's header; nil shows nothing
			-- `col.justify` is honoured here (default LEFT), as FGI's is. No hover overlay is built for a
			-- button column: the button already takes the mouse, and an overlay on top would eat its clicks.
			-- So the button's own scripts call `onCellEnter` / `onCellLeave` / `onCellClick` in the same
			-- order the overlay does (peer review L2: they were silently ignored on a button column).
			local btn = pooled
			if not btn then
				btn = CreateFrame("Button", nil, row)
				btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
				-- A `_readonly` row disables this button, and a disabled Button fires no OnEnter unless
				-- this is set -- so `cellTip` would go silent on exactly the rows FGI explains
				-- (peer review M4). Same rule and same Classic Era source as the core's
				-- `allowHoverWhileDisabled`.
				if btn.SetMotionScriptsWhileDisabled then btn:SetMotionScriptsWhileDisabled(true) end
				local fs = btn:CreateFontString(nil, "OVERLAY")
				fs:SetAllPoints(btn)
				fs:SetWordWrap(false)
				fs:SetMaxLines(1)
				btn.label = fs
			end
			btn.label:SetFontObject(cellFont(col))
			btn.label:SetJustifyH(col.align or col.justify or "LEFT")
			cells[col.key] = btn
			btn:SetScript("OnClick", function(cellFrame, mouseButton)
				local live = rl.columns[ci]
				local entry, idx = entryAt()
				if not (entry and live) then return end
				if live.onCellClick and live.onCellClick(entry, idx, rl, mouseButton, cellFrame) then return end
				if live.onClick then live.onClick(entry, idx, rl, mouseButton, cellFrame) end
			end)
			-- The button takes the mouse from the row, so a right-click menu on the row would stop working
			-- over this one column. Anything but a left click goes to `onCellClick` first, as the overlay
			-- does, and is forwarded to `onRowClick` with the ROW unless that consumed it.
			btn:SetScript("OnMouseDown", function(cellFrame, mouseButton)
				if mouseButton == "LeftButton" then return end
				local live = rl.columns[ci]
				local entry, idx = entryAt()
				if not entry then return end
				if live and live.onCellClick and live.onCellClick(entry, idx, rl, mouseButton, cellFrame) then
					return
				end
				if rl.onRowClick then rl.onRowClick(entry, idx, rl, mouseButton, row) end
			end)
			btn:SetScript("OnEnter", function(cellFrame)
				row._hoverOn()
				local live = rl.columns[ci]
				local entry, idx = entryAt()
				if not (entry and live) then return end
				if live.onCellEnter then live.onCellEnter(entry, idx, rl, cellFrame) end
				local owner = rl.tooltipOwner and { owner = rl.tooltipOwner } or nil
				-- `col.tip(entry, button) -> title, body[, reason]` (MINOR 36, inbox 337bb7d3): read NOW, on
				-- hover, so text about how stale some data is was true when the player looked. The reason is
				-- the red last line CreateExplainedButton draws. It wins over `cellTip` when both are given.
				if live.tip then
					local title, body, reason = live.tip(entry, cellFrame)
					lib:ShowTooltip(cellFrame, title, body, { reason = reason, owner = rl.tooltipOwner })
					return
				end
				if not live.cellTip then return end
				-- The RESULT decides, not the function's presence: a row with nothing to explain answers
				-- nil, and the header alone would still draw a title-only tooltip (FGI, thread 7e28e319).
				local tip = live.cellTip(entry)
				if tip == nil or tip == "" then return end
				lib:ShowTooltip(cellFrame, live.header, tip, owner)
			end)
			btn:SetScript("OnLeave", function(cellFrame)
				row._hoverOff()
				local live = rl.columns[ci]
				if live and live.onCellLeave then
					local entry, idx = entryAt()
					live.onCellLeave(entry, idx, rl, cellFrame)
				end
				lib:HideTooltip(cellFrame)
			end)
			if col.strike then
				strikes = strikes or {}
				local line = takePooled(row._strikePool)
					or row:CreateTexture(nil, "OVERLAY", nil, 1)
				line:SetPoint("LEFT", btn.label, "LEFT", 0, 0)
				line:Hide()
				strikes[col.key] = line
			end
		elseif kind == "icon" then
			-- Icon column: a fixed-size TEXTURE (desaturatable) inside a col.width holder frame, so the per-row
			-- marker can render gold/grey (an "on"/"off" state) without stretching to the column width. Held
			-- non-interactive (a pure indicator); the header still sorts on entry[col.key]. `col.iconSize` sets the
			-- glyph size (default 14). Populated in _renderRows via col.icon(entry) -> texturePath, desaturated.
			local holder = pooled
			if not holder then
				holder = CreateFrame("Frame", nil, row)
				local t = holder:CreateTexture(nil, "OVERLAY")
				t:SetPoint("LEFT", holder, "LEFT", 2, 0)
				holder._tex = t
			end
			cells[col.key] = holder
		else
			local fs = pooled
			if not fs then
				fs = row:CreateFontString(nil, "OVERLAY")
				fs:SetJustifyH("LEFT")
				fs:SetWordWrap(false)
				fs:SetMaxLines(1)
			end
			-- Re-set on every build, not only on creation: a reused cell may be serving a column with
			-- a different `font`.
			fs:SetFontObject(cellFont(col))
			-- `col.align` (MINOR 34, TOGTools item 6) is the OPT-IN way to right-align a text cell.
			-- `col.justify` stays ignored on text cells: consumers already pass it, and honouring it now
			-- would move their columns. Re-set per build because the cell is pooled.
			fs:SetJustifyH(col.align or "LEFT")
			cells[col.key] = fs
			-- Per-column STRIKETHROUGH (MINOR 33, Dibs' DIBSREQ-LAGW-006): a line drawn across this
			-- cell's text when `col.strike(entry)` says so. WoW has no strikethrough font style and no
			-- FontString flag for one, so a texture is what every addon that strikes text draws.
			-- Anchored to the FONT STRING, not the row, so it follows the cell through every re-layout;
			-- sized, coloured, shown and hidden in `_renderRows`, because a pooled frame shows a
			-- different entry after a scroll and nothing calls the consumer in between. A column that
			-- does not ask builds none.
			if col.strike then
				strikes = strikes or {}
				local line = takePooled(row._strikePool)
					or row:CreateTexture(nil, "OVERLAY", nil, 1)
				line:SetPoint("LEFT", fs, "LEFT", 0, 0)
				line:Hide()
				strikes[col.key] = line
			end
		end
		-- The pool this cell goes home to, written on the cell itself the moment it exists and in the
		-- one place all three branches above converge. `releaseRowCells` reads it back; see the note
		-- there for why it is a field rather than a table keyed by `col.key`.
		cells[col.key]._lagwKind = kind
		-- The checkbox and the expander take the mouse from the row and set no OnEnter of their own. Their
		-- pools are this row's, so a hook added once can never reach another row (MINOR 36).
		if (kind == "checkbox" or kind == "expander") and not cells[col.key]._lagwHoverHooked then
			local c = cells[col.key]
			c._lagwHoverHooked = true
			c:HookScript("OnEnter", function() row._hoverOn() end)
			c:HookScript("OnLeave", function() row._hoverOff() end)
		end
		-- Per-column hover (MINOR 30, Dibs' DIBSREQ-LAGW-004) and per-column click (MINOR 33, their
		-- DIBSREQ-LAGW-005): a mouse-enabled frame laid over the cell, because a text cell is a
		-- FontString and cannot take the mouse itself. Built only for a column that asks, so nothing
		-- else pays a frame; `_layoutRow` puts it exactly over the cell.
		if kind ~= "button" and (col.onCellEnter or col.onCellLeave or col.onCellClick) then
			overlays = overlays or {}
			local ov = takePooled(row._overlayPool) or CreateFrame("Frame", nil, row)
			ov:EnableMouse(true)
			overlays[col.key] = ov
			ov:SetScript("OnEnter", function(cellFrame)
				row._hoverOn()
				local live = rl.columns[ci]
				local entry, idx = entryAt()
				if entry and live and live.onCellEnter then live.onCellEnter(entry, idx, rl, cellFrame) end
			end)
			ov:SetScript("OnLeave", function(cellFrame)
				row._hoverOff()
				local live = rl.columns[ci]
				local entry, idx = entryAt()
				if live and live.onCellLeave then live.onCellLeave(entry, idx, rl, cellFrame) end
			end)
			-- The overlay sits above the row and takes the mouse, so a click on it would never reach
			-- the row's own handler -- a right-click menu would stop working over exactly one column.
			-- Forwarded with the ROW frame, which is what a consumer anchors a menu to.
			--
			-- `onCellClick` (MINOR 33, DIBSREQ-LAGW-005) gets first refusal, and its RETURN is
			-- the whole contract: true means the cell CONSUMED the click and `onRowClick` must
			-- not also run -- which is what lets a link cell open its target on a plain left
			-- click while every other click on that same cell still does what the row does.
			-- Anything else falls through unchanged, so a column that merely wants to see the
			-- click adds no behaviour.
			if self.onRowClick or col.onCellClick then
				ov:SetScript("OnMouseDown", function(cellFrame, button)
					local live = rl.columns[ci]
					local entry, idx = entryAt()
					if not entry then return end
					if live and live.onCellClick and live.onCellClick(entry, idx, rl, button, cellFrame) then
						return
					end
					if rl.onRowClick then rl.onRowClick(entry, idx, rl, button, row) end
				end)
			end
		end
	end

	row.cellOverlays, row.cellStrikes = overlays, strikes
	self:_layoutRow(row, i)
end

--- Replace the column set on a LIVE list (MINOR 33, Dibs' DIBSREQ-LAGW-010). The header and every
--- pooled row's cells are rebuilt against the new set; `data`, `listOffset`, the scrollbar and the
--- row FRAMES themselves are kept, and the list repaints. Returns whether anything changed.
---
--- WHY IT EXISTS: a column set can be DATA-DRIVEN -- one column per tracked raid, per season, per
--- category -- and that data changes under a drawn window. With the columns fixed at construction
--- the only remedy is a whole new RowList on a fresh host frame, which orphans every pooled row, its
--- header and its scrollbar for the session, because WoW frames cannot be destroyed. The worse half
--- is what it looks like when a consumer does neither: the column headed "MC" goes on showing BL's
--- numbers until the window is reopened -- a wrong number with nothing odd-looking about it.
---
--- Structurally identical input is a NO-OP, so this may be called on every repaint.
function RowList:SetColumns(columns)
	if self._detached then return false end
	columns = columns or {}
	-- Structurally identical: nothing to rebuild, but the new table is still ADOPTED and the list
	-- repainted. A consumer following the "call it every repaint" advice hands over a freshly built
	-- table with fresh closures each time, and dropping it on the floor would pin `format`, `strike`
	-- and the per-cell handlers to whatever the first call happened to carry -- a silent staleness
	-- with nothing on screen to show for it. Every cell script resolves its column through
	-- `rl.columns[ci]` at event time, so the swap alone is enough to make them current.
	if sameColumnSet(self.columns, columns) then
		self.columns = columns
		-- `_colW` is keyed by column TABLE, so the new tables need their widths derived now. Without
		-- this every later layout read `colW[newcol]` as nil and raised on the arithmetic -- any grow,
		-- resize or rescale after a repaint-time SetColumns (peer review H1 against MINOR 34; the
		-- defect is MINOR 33's). Same numbers, new keys; nothing is re-laid.
		self:_applyMetrics()
		self._dataSorted = nil
		self:Refresh()
		return false
	end
	assertValidColumns(columns, 3)   -- the same rules `New` applies, blamed on the caller

	self.columns = columns

	-- A sort key naming a column that no longer exists would keep ordering the list by a field
	-- nothing on screen shows, with no arrow to explain it. Dropped, and `_dataSorted` with it --
	-- `sortValue` is a column's function, so the cached order belongs to the old set.
	if self.sortKey then
		local stillThere = false
		for _, col in ipairs(columns) do
			if col.key == self.sortKey then stillThere = true; break end
		end
		if not stillThere then self.sortKey, self.sortDesc = nil, false end
	end
	-- A filter on a column that is gone would go on hiding rows by a value nothing on screen shows.
	for k in pairs(self.colExcluded) do
		local present = false
		for _, col in ipairs(columns) do
			if col.key == k then present = true; break end
		end
		if not present then self.colExcluded[k] = nil end
	end
	self._dataSorted = nil

	local hadHeader = self:_syncHeaderState(columns)

	-- Metrics first: the column widths and the header height every layout below reads.
	self:_applyMetrics()

	if self.hasHeader then
		if not self.header then self:_buildHeader() else self:_buildHeaderColumns() end
		self.header:Show()
	elseif hadHeader and self.header then
		-- Kept, not discarded: a set with headers may come back, and the frame cannot be destroyed.
		self:_buildHeaderColumns()   -- releases every button into the pool
		self.header:Hide()
	end

	for i = 1, #self.rows do self:_buildRowCells(self.rows[i], i) end
	self:_anchorScrollbar()
	self:Refresh()
	return true
end

-- Hover and click on |H links in a row's cells (MINOR 34, TOGTools inbox c571dee6; `opts.hyperlinks`).
-- Ported from TOGTools' GUI/RowList.lua `_buildRow`, which carries the reasons at length:
--   hover         GameTooltip:SetHyperlink, anchored like every tooltip here. PLAYER links are skipped:
--                 they have no SetHyperlink form, and the chat frame shows no tooltip for them either.
--   player link   right-click opens the client's chat-name menu (FriendsFrame_ShowDropdown). Its 5th
--                 argument is the chat frame the menu's Whisper sends through, and Classic reads that
--                 frame's `editBox` -- a row has none, so Classic gets DEFAULT_CHAT_FRAME and Retail
--                 gets the row, which is the tested path there. Any other click goes to SetItemRef.
--   other links   HandleModifiedItemClick first (shift-click to chat, ctrl-click to dress up), then
--                 a CHATLINK insert when the modifier is held.
-- Feature-detected: a client whose frames have no SetHyperlinksEnabled leaves the markup inert, as before.
-- The row takes the mouse to receive these, which is why this is opt-in.
--- Anchor a tooltip this list draws: its own `tooltipOwner` when set (MINOR 34), else AnchorTooltip.
function RowList:_anchorTip(frame)
	if self.tooltipOwner then self.tooltipOwner(frame) else lib:AnchorTooltip(frame) end
end

function RowList:_enableHyperlinks(row)
	if not row.SetHyperlinksEnabled then return end
	row:EnableMouse(true)
	row:SetHyperlinksEnabled(true)
	row:SetScript("OnHyperlinkEnter", function(rowFrame, link)
		if type(link) ~= "string" or link:sub(1, 6) == "player" then return end
		self:_anchorTip(rowFrame)
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)
	row:SetScript("OnHyperlinkLeave", function() lib:HideTooltip() end)
	row:SetScript("OnHyperlinkClick", function(rowFrame, link, text, button)
		if type(link) ~= "string" then return end
		if link:sub(1, 6) == "player" then
			if button == "RightButton" and FriendsFrame_ShowDropdown then
				local name = link:match("^player:([^:]+)")
				if name and name ~= "" then
					local retail = WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
					FriendsFrame_ShowDropdown(name, 1, nil, nil, retail and rowFrame or DEFAULT_CHAT_FRAME)
					return
				end
			end
		end
		-- Every other click goes the way chat's does: SetItemRef(link, text, ...). The Classic client's
		-- SetItemRef (Classic/ItemRef.lua:1-21) hands modified clicks to HandleModifiedItemClick with the
		-- FULL hyperlink text, and a plain item click opens the item's own tooltip. The first build
		-- passed the bare "item:..." link to HandleModifiedItemClick itself, which expects |H markup
		-- (Blizzard_ItemButton/Classic/ItemButtonTemplate.lua:137-159), so shift-click inserted nothing
		-- and a plain click opened nothing (peer review H3).
		if SetItemRef then
			SetItemRef(link, text, button, rowFrame)
			return
		end
		-- A client with no SetItemRef: the same two steps, with the full text.
		if HandleModifiedItemClick and HandleModifiedItemClick(text) then return end
		if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
			ChatEdit_InsertLink(text)
		end
	end)
end

-- Build one row: the frame, its banding, one cell per column (text, checkbox or icon holder), the
-- action buttons and the scripts. NO geometry -- `_layoutRow` places everything, at build and again
-- on every scale change, so a pooled row built at one scale is re-laid at the next.
function RowList:_buildRow(i)
	local row = CreateFrame("Frame", nil, self.parent)

	-- Banding for readability — every second row.
	-- Kept on the row so a group header row (MINOR 36) can hide it: a header draws its own strip.
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(row)
		bg:SetColorTexture(1, 1, 1, 0.04)
		row.bandTex = bg
	end

	-- The selected-row highlight (MINOR 31): one texture per pooled row, above the banding (BORDER sits
	-- over BACKGROUND) and below every cell. Shown or hidden per populate against `self._selected`, and
	-- tinted with the consumer's accent at paint time, so a Configure after construction is honoured.
	local sel = row:CreateTexture(nil, "BORDER")
	sel:SetAllPoints(row)
	sel:Hide()
	row.selectedTex = sel

	-- The entry this pooled frame is showing RIGHT NOW. Resolved per event, never captured at build
	-- time: the same frame shows a different entry after a scroll, a sort or a SetData. Stored ON THE
	-- ROW so `_buildRowCells` can hand it to the cell scripts it installs, at build and again on
	-- every `SetColumns`.
	local rl = self
	local function entryAt()
		local idx = (rl.listOffset or 0) + i
		return rl:_getSortedData()[idx], idx
	end
	row._entryAt = entryAt

	-- The hover highlight (MINOR 36). Drawn on BORDER one sublevel UNDER the selection tint, so it sits
	-- over the banding and never hides the selection. The row, and every child that takes the mouse
	-- from it (cell overlays, button cells, checkboxes, action icons), calls `_hoverOn` on enter and
	-- `_hoverOff` on leave. A leave only hides while the pointer is off the ROW as a whole: moving from
	-- the row onto one of its own cells fires the row's OnLeave, and hiding there is the flicker the
	-- contract rules out.
	if self.hoverHighlight then
		local hv = row:CreateTexture(nil, "BORDER", nil, -1)
		hv:SetAllPoints(row)
		local h = self.hoverHighlight
		if type(h) == "table" then
			hv:SetColorTexture(h[1] or 1, h[2] or 1, h[3] or 1, h[4] or 0.15)
		else
			hv:SetTexture(type(h) == "string" and h or HOVER_TEXTURE)
			hv:SetBlendMode("ADD")
		end
		hv:Hide()
		row.hoverTex = hv
		row:EnableMouse(true)
	end
	row._hoverOn = function()
		if row.hoverTex and entryAt() then row.hoverTex:Show() end
	end
	row._hoverOff = function()
		if row.hoverTex and not row:IsMouseOver() then row.hoverTex:Hide() end
	end

	if self.hyperlinks then self:_enableHyperlinks(row) end

	-- Per-row pools, so a later `SetColumns` reuses this row's cells instead of orphaning them.
	row.cells = {}
	row._cellPool   = { text = {}, checkbox = {}, icon = {}, expander = {}, button = {} }
	row._overlayPool, row._strikePool = {}, {}
	self:_buildRowCells(row, i)

	if #self.actions > 0 then
		row.actionBtns = {}
		for ai = 1, #self.actions do
			local action = self.actions[ai]
			-- `btn` is the clicked action button (WoW passes it as OnClick's first arg) — forwarded so the
			-- consumer can anchor a menu/popup to it (e.g. drop a restriction menu from the gear icon).
			local function dispatch(btn)
				local idx = (rl.listOffset or 0) + i
				local entry = rl:_getSortedData()[idx]
				if not entry then return end
				if action.onClick then action.onClick(entry, idx, rl, btn) end
			end
			local b = makeRowIcon(row, action.texture, action.tooltip, dispatch,
				function(f) rl:_anchorTip(f) end)
			-- An icon lives on this row for good, so a hook added once cannot follow it anywhere else.
			if self.hoverHighlight then
				b:HookScript("OnEnter", row._hoverOn)
				b:HookScript("OnLeave", row._hoverOff)
			end
			row.actionBtns[ai] = b
		end
	end

	self:_layoutRow(row, i)

	-- Drag to reorder (MINOR 36). The client starts a drag only once the pointer has moved past its own
	-- threshold with the button held, so a plain click stays a click and still reaches OnMouseDown.
	if self.reorderable then
		row:EnableMouse(true)
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function() rl:_beginDrag(i) end)
		row:SetScript("OnDragStop", function() rl:_endDrag(true) end)
	end

	if self.onRowClick or self.onRowEnter or self.onRowLeave or self.hoverHighlight then
		row:EnableMouse(true)
		if self.onRowClick then
			-- `button` ("LeftButton" / "RightButton" / ...) and the row frame are passed through (MINOR 27).
			-- Both were in hand here and discarded, so a consumer wanting a right-click menu had to ask
			-- the client with GetMouseButtonClicked() and stash the frame from onRowEnter -- inferring
			-- widget internals for facts the widget already held. Additive: three-argument handlers are
			-- unchanged. VersionCheck-1.0 request, 2026-09-10.
			row:SetScript("OnMouseDown", function(rowFrame, button)
				local entry, idx = entryAt()
				if entry then rl.onRowClick(entry, idx, rl, button, rowFrame) end
			end)
		end
		if self.onRowEnter or self.onRowLeave or self.hoverHighlight then
			row:SetScript("OnEnter", function(rowFrame)
				row._hoverOn()
				local entry, idx = entryAt()
				if entry and rl.onRowEnter then rl.onRowEnter(entry, idx, rl, rowFrame) end
			end)
			row:SetScript("OnLeave", function(rowFrame)
				row._hoverOff()
				local entry, idx = entryAt()
				if rl.onRowLeave then rl.onRowLeave(entry, idx, rl, rowFrame) end
			end)
		end
	end

	row:Hide()
	return row
end

-- Place row `i` and everything in it at the current metrics: the frame's height and anchors
-- (TOPRIGHT subtracts the scrollbar gutter so rows never overlap the lane; Y starts at
-- -headerHeight so the pool begins below the optional header), each cell's width and anchor
-- along the two chains, the checkbox and icon-cell sizes, and the action buttons. The chains are
-- the same array-order placement `_layoutHeader` uses, and the spec pins that they agree.
function RowList:_layoutRow(row, i)
	local S = function(px) return lib:ScaledSize(px) end
	local colW, cells = self._colW, row.cells
	local rowH = self.rowHeight

	row:SetHeight(rowH)
	row:ClearAllPoints()
	local yOff = -(self.headerHeight + (i - 1) * rowH)
	row:SetPoint("TOPLEFT",  self.parent, "TOPLEFT",   0,                yOff)
	row:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -SCROLLBAR_GUTTER, yOff)

	-- A column's hover overlay (MINOR 30), laid exactly over the cell it belongs to. Called after the
	-- cell is anchored, by every branch that anchors one -- both chains and the auto column -- so the
	-- overlay follows a re-layout (scale change, resize, column width) without knowing the chains.
	local function coverCell(col, cell)
		local ov = row.cellOverlays and row.cellOverlays[col.key]
		if not ov then return end
		ov:ClearAllPoints()
		ov:SetAllPoints(cell)
	end

	-- Size a cell for its kind, then hand it to the chain's anchor.
	local function place(col, anchor)
		local cell = cells[col.key]
		if not cell then return end
		cell:ClearAllPoints()
		local kind = cellKind(col)
		if kind == "checkbox" or kind == "expander" then
			local box = S(col.boxSize or (kind == "expander" and EXPANDER_SIZE or CHECKBOX_SIZE))
			cell:SetSize(box, box)
			anchor(cell, box)
		elseif kind == "icon" then
			cell:SetHeight(rowH)
			local size = S(col.iconSize or ICON_CELL_SIZE)
			cell._tex:SetSize(size, size)
			anchor(cell, nil)
		else
			cell:SetHeight(rowH)
			anchor(cell, nil)
		end
		coverCell(col, cell)
	end

	local autoIdx = self:_autoIndex()

	-- The row's indent (MINOR 36), set per populate by `_renderRows`. Only the indent column's TEXT moves:
	-- its left edge steps right and its right edge stays, so the text still clips at the column. A box
	-- kind (checkbox, expander) has no text to indent and is left where it is.
	local ind = row._indent or 0
	local indentCol = ind > 0 and self:_indentColumn() or nil
	local function indentOf(col, box) return (col == indentCol and not box) and ind or 0 end

	-- LEFT chain — columns before the auto-width column, LEFT->LEFT from row.LEFT + leftPad.
	local leftOffset = self.leftPad
	if autoIdx then
		for ci = 1, autoIdx - 1 do
			local col = self.columns[ci]
			leftOffset = leftOffset + gapBefore(col)
			local lo = leftOffset
			place(col, function(cell, box)
				local dx = indentOf(col, box)
				if not box then cell:SetWidth(math.max(0, colW[col] - dx)) end
				cell:SetPoint("LEFT", row, "LEFT", lo + dx, 0)
			end)
			leftOffset = leftOffset + colW[col] + self.colGap
		end
	end

	-- RIGHT chain — columns after the auto-width column, RIGHT->RIGHT from row.RIGHT - iconAreaW,
	-- processed in reverse so the rightmost lands first.
	local rightOffset = self.iconAreaW + self.colGap
	local rightChainStart = autoIdx and (autoIdx + 1) or 1
	for ci = #self.columns, rightChainStart, -1 do
		local col = self.columns[ci]
		if isFixed(col) then
			local ro = rightOffset
			place(col, function(cell, box)
				if box then
					cell:SetPoint("RIGHT", row, "RIGHT", -(ro + colW[col] - box), 0)
				else
					cell:SetWidth(math.max(0, colW[col] - indentOf(col, box)))
					cell:SetPoint("RIGHT", row, "RIGHT", -ro, 0)
				end
			end)
			rightOffset = rightOffset + colW[col] + self.colGap + gapBefore(col)
		end
	end

	-- Auto column — fills the gap between the two chains.
	if autoIdx then
		local col = self.columns[autoIdx]
		-- Kept for `CellWidth` (MINOR 36): the auto cell is two anchors, not a width, so its width is
		-- the row's less these two insets. The same for every row, so the last write stands.
		self._autoInsetL, self._autoInsetR = leftOffset + gapBefore(col), rightOffset
		local cell = cells[col.key]
		if cell then
			cell:ClearAllPoints()
			cell:SetHeight(rowH)
			local dx = indentOf(col, cellKind(col) == "checkbox" or cellKind(col) == "expander")
			cell:SetPoint("LEFT",  row, "LEFT",  leftOffset + gapBefore(col) + dx, 0)
			cell:SetPoint("RIGHT", row, "RIGHT", -rightOffset, 0)
			coverCell(col, cell)
		end
	end

	-- Action icons: action[1] sits rightmost at -leftPad; each next icon steps left.
	if row.actionBtns then
		for ai, b in ipairs(row.actionBtns) do
			b:SetSize(self.iconSize, self.iconSize)
			b:ClearAllPoints()
			b:SetPoint("RIGHT", row, "RIGHT", -(self.leftPad + (ai - 1) * (self.iconSize + self.iconGap)), 0)
		end
	end
end

--- Replace the data set. Scroll resets to 0 by default (correct for a search
--- change / fresh tab). Pass preserveScroll=true for in-place mutations (a
--- checkbox tick, an action click) so the list doesn't snap to the top;
--- listOffset is clamped to the new length.
--- Set the active sort column without going through a header click.
--- `key` is a column key (nil clears the sort and restores the model's own order); `desc` sorts
--- descending. Call it before `SetData` to have the FIRST render appear pre-sorted.
---
--- Why this exists: `_getSortedData` returns `self.data` verbatim when there is no `sortKey`, and the
--- only writer of `sortKey` used to be the header's OnClick. So a consumer wanting a sorted list had
--- exactly one mechanism available -- asking the user to click a header -- and every list opened in
--- whatever order its model happened to hand over. Dibs' Loot Log opened in the raw append order of a
--- network-merged store while its own module asserted in writing that the tab sorted on time.
--- Peer review finding 14.
---
--- Writes the same two fields the header handler does, so the two compose: a later click on the same
--- column toggles direction from here rather than resetting.
function RowList:SetSort(key, desc)
	self.sortKey  = key
	-- Normalised to a real boolean rather than stored as given: the header handler flips this with
	-- `not rl.sortDesc`, and a nil left here would make the first click on the sorted column produce
	-- descending when the caller had already asked for ascending.
	self.sortDesc = desc and true or false
	self._dataSorted = nil
	-- Only once the header exists. `SetSort` before `SetData` is the documented order, and at that
	-- point a list built without any `header` column has no header bar to relabel.
	if self.header then self:_updateHeaderText() end
	self:Refresh()
end

function RowList:SetData(data, preserveScroll)
	self.data = data or {}
	self._searchHay = nil
	-- A selection survives a SetData only if the SAME entry (identity) is still in the list: a
	-- rebuilt model with equal-looking rows is a new set, and the highlight must not land on a
	-- stranger that happens to sit at the old index.
	if self._selected ~= nil and not self:_indexOf(self._selected, self.data) then
		self._selected = nil
	end
	-- Filters on values the new data no longer has go first, so the clamp below measures the real view.
	if self.colExcluded and self:_isFiltering() then
		self:_pruneFilters()
		if self.header then self:_updateHeaderText() end
	end
	self._dataSorted = nil
	if preserveScroll then
		local maxOffset = math.max(0, #self:_getSortedData() - (self.visibleRowCount or 0))
		if (self.listOffset or 0) > maxOffset then
			self.listOffset = maxOffset
		end
	else
		self.listOffset = 0
	end
	-- An autoFit column's width follows the data (MINOR 34). Only a list that has one pays the re-lay.
	if self:_hasAutoFit() then self:_relayout() end
	self:Refresh()
end

-- Recompute how many rows fit in the parent's current height, growing the pool
-- if the parent is now taller than the pool can fill.
function RowList:_recomputeVisibleRows()
	local h = (self.parent:GetHeight() or 0) - self.headerHeight
	-- The small epsilon keeps a height that is EXACTLY n rows (fitContent sets one, MINOR 36) from
	-- flooring to n - 1 when the scaled row height is not a whole number and the product rounds down.
	local need = math.max(0, math.floor(h / self.rowHeight + 1e-6))
	if need > #self.rows then
		for i = #self.rows + 1, need do
			self.rows[i] = self:_buildRow(i)
		end
		self.rowCount = #self.rows
	end
	self.visibleRowCount = need
end

--- `opts.fitContent` (MINOR 36, TOGProfessionMaster inbox 8680f2cc): size the PARENT to the rows drawn --
--- the header bar plus one row height per row, up to `maxRows`, past which the list scrolls as any other
--- does. Both heights are the live, scaled ones, so a scale change re-fits. No rows gives the header's
--- height alone (0 without a header), which is not an empty-render fault: there is nothing to draw.
--- `onHeightChanged(rl, height)` is told each NEW height. The parent must be free to take a height --
--- anchored by its top alone, like any frame whose height is set; one anchored top AND bottom ignores it.
function RowList:_fitHeight()
	local n = #self:_getSortedData()
	local cap = tonumber(self.fitContent.maxRows)
	if cap and n > cap then n = math.max(0, math.floor(cap)) end
	local h = self.headerHeight + n * self.rowHeight
	if h == self._fitH then return end
	self._fitH = h
	self._fitting = true
	self.parent:SetHeight(h)
	self._fitting = nil
	if self.onHeightChanged then self.onHeightChanged(self, h) end
end

--- A list holding data and showing NO rows is always a consumer bug, and the widget is the only party
--- that can cheaply see both halves (MINOR 33, raised by Dibs after it cost the author an evening).
---
--- WHAT HAPPENED, because the shape is not obvious from either side alone: their list host was
--- anchored top AND bottom with no height of its own, the controls stacked above it grew past the
--- area's bottom, and the anchor chain resolved to ZERO. `_recomputeVisibleRows` divides the parent's
--- height by the row height, answered zero, and every row was correctly hidden. Measured in the
--- client: **314 rows built, 0 shown, host 0 pixels tall.** Nothing in this widget was wrong, the
--- consumer's own empty-state hint did not fire because the data was not empty, and the player saw a
--- blank panel with no text and no error for an unknown length of time. Three sessions and three
--- offline suites could not see it, because no suite builds a host whose anchors resolve to nothing.
---
--- So the widget says it. ONE line per list for the life of the instance -- not per populate, or a
--- list left collapsed behind a tab would fill the log -- naming the parent's height, because "314
--- rows, parent is 0 pixels tall" is the whole diagnosis in one sentence. Same idiom as the
--- PersistWindow / DockWindow refusal in MINOR 32: a silent wrong state is worse than a noisy right
--- one, and the message names the fix rather than the symptom.
---
--- `onEmptyRender(rl, dataCount)` lets a consumer handle it themselves (their own message in their
--- own panel), and replaces the print for that list. The hook alone would NOT have helped here: an
--- opt-in is set by the consumers who already thought about this case, and never by the one that
--- silently broke.
function RowList:_reportEmptyRender(dataCount)
	if dataCount <= 0 or (self.visibleRowCount or 0) > 0 then return end
	if self.onEmptyRender then
		self.onEmptyRender(self, dataCount)
		return
	end
	if self._warnedEmptyRender then return end
	self._warnedEmptyRender = true
	local parent = self.parent
	local h = (parent and parent.GetHeight and parent:GetHeight()) or 0
	lib:_Report("emptyRender",
		("RowList has %d row(s) but is showing none: its parent frame is %d pixel(s) "):
			format(dataCount, math.floor(h + 0.5))
		.. "tall, so there is no room to draw any. Give that frame a height, or anchor it by its TOP alone "
		.. "rather than top-and-bottom -- a frame anchored on both edges has no say in its own height.",
		-- No list identifier in the entry: `opts.id` is passed by consumers but this widget has never
		-- stored it (checked, not assumed), and a field that is always nil is worse than an absent
		-- one -- a reader takes it for "this list had no id" rather than "nobody recorded one".
		{ rows = dataCount, parentHeight = h })
end

--- Paint pooled `row` as a GROUP HEADER for `entry` (MINOR 36): every cell, cell overlay, strike line and
--- action icon hidden (so nothing on it takes a click meant for data, and no empty action slot shows), the
--- banding swapped for an accent-tinted strip, and ONE heading across the row in the accent colour, after
--- its indent and an optional +/- when `entry._expanded` is true or false. The parts are built on the
--- first header this frame shows and kept, since the frame cannot be destroyed.
function RowList:_paintHeader(row, entry)
	row._wasHeader = true
	if row.bandTex then row.bandTex:Hide() end
	for _, cell in pairs(row.cells) do cell:Hide() end
	for _, ov in pairs(row.cellOverlays or {}) do ov:Hide() end
	for _, st in pairs(row.cellStrikes or {}) do st:Hide() end
	for _, b in ipairs(row.actionBtns or {}) do b:Hide() end

	local hp = row.headerParts
	if not hp then
		hp = {
			strip = row:CreateTexture(nil, "BACKGROUND", nil, 1),
			exp   = row:CreateTexture(nil, "OVERLAY"),
			fs    = row:CreateFontString(nil, "OVERLAY"),
		}
		hp.strip:SetAllPoints(row)
		hp.fs:SetJustifyH("LEFT")
		hp.fs:SetWordWrap(false)
		hp.fs:SetMaxLines(1)
		row.headerParts = hp
	end
	local ar, ag, ab = lib:AccentRGB()
	hp.strip:SetColorTexture(ar, ag, ab, HEADER_STRIP_ALPHA)
	hp.strip:Show()

	local x = self.leftPad + (row._indent or 0)
	local st = entry._expanded
	if st == nil then
		hp.exp:Hide()
	else
		local sz = lib:ScaledSize(HEADER_EXP_SIZE)
		hp.exp:SetTexture(st and HEADER_MINUS or HEADER_PLUS)
		hp.exp:SetSize(sz, sz)
		hp.exp:ClearAllPoints()
		hp.exp:SetPoint("LEFT", row, "LEFT", x, 0)
		hp.exp:Show()
		x = x + sz + self.iconGap
	end

	local fontName = self.headerFont or "GameFontNormal"
	hp.fs:SetFontObject(lib:ScaledFont(fontName) or _G[fontName] or fontName)
	hp.fs:ClearAllPoints()
	hp.fs:SetPoint("LEFT", row, "LEFT", x, 0)
	hp.fs:SetPoint("RIGHT", row, "RIGHT", -self.leftPad, 0)
	hp.fs:SetText(self:_headerText(entry))
	hp.fs:SetTextColor(ar, ag, ab)
	hp.fs:Show()
end

--- Undo `_paintHeader` when the frame goes back to showing data: banding back, header parts hidden, the
--- cell overlays shown (the cells themselves are re-shown by the populate).
function RowList:_unpaintHeader(row)
	row._wasHeader = nil
	if row.bandTex then row.bandTex:Show() end
	local hp = row.headerParts
	hp.strip:Hide()
	hp.exp:Hide()
	hp.fs:Hide()
	for _, ov in pairs(row.cellOverlays or {}) do ov:Show() end
end

-- Render the visible pool against current data + listOffset. Split from Refresh
-- so the scrollbar's OnValueChanged can update content without recomputing pool
-- size / scrollbar range (which would feed back into OnValueChanged).
function RowList:_renderRows()
	if self._detached then return end
	local data = self:_getSortedData()
	self:_reportEmptyRender(#data)
	local selected = self._selected
	local ar, ag, ab
	if selected then ar, ag, ab = lib:AccentRGB() end
	for i = 1, #self.rows do
		local row = self.rows[i]
		if i <= self.visibleRowCount then
			local entry = data[(self.listOffset or 0) + i]
			if entry then
				-- Selection is by IDENTITY, resolved per populate because the rows are pooled: the frame
				-- that showed the selected entry before a scroll shows a different one after it.
				local sel = row.selectedTex
				if sel then
					if entry == selected then
						-- No `or` fallbacks: this line is only reached when `entry == selected` and
						-- `entry` is non-nil, so `selected` was truthy and `ar/ag/ab` were assigned
						-- above -- and `AccentRGB` always returns three numbers, never nil. The old
						-- `ar or 1, ag or 0.82, ab or 0` was unreachable AND was a fourth spelling
						-- of the gold, which is how it survived review.
						sel:SetColorTexture(ar, ag, ab, 0.18)
						sel:Show()
					else
						sel:Hide()
					end
				end
				-- The hover highlight (MINOR 36) is re-decided per populate: a scroll changes the entry
				-- under a row the pointer never left, and fires no OnEnter or OnLeave. It stays only
				-- while the pointer really is over this row.
				local hv = row.hoverTex
				if hv then
					if row:IsMouseOver() then hv:Show() else hv:Hide() end
				end
				-- The indent (MINOR 36) is a LAYOUT, so a row whose entry changed level is re-laid; one that
				-- did not pays nothing. Laid for header rows too, so the cells are right when the frame next
				-- shows a data row at the same level.
				local ind = self:_indentPx(entry)
				if (row._indent or 0) ~= ind then
					row._indent = ind
					self:_layoutRow(row, i)
				end
				-- The row being dragged (MINOR 36) is dimmed wherever it is drawn, and only while dragged. A
				-- list that never drags never touches the alpha.
				local dim = self._drag and self._drag.entry == entry
				if dim or row._dimmed then
					row._dimmed = dim or nil
					row:SetAlpha(dim and DRAG_DIM_ALPHA or 1)
				end
				local isHeader = self:_isHeaderRow(entry)
				if isHeader then
					self:_paintHeader(row, entry)
				elseif row._wasHeader then
					self:_unpaintHeader(row)
				end
				for _, col in ipairs(isHeader and NO_COLUMNS or self.columns) do
					local cell = row.cells[col.key]
					local kind = cell and cell._lagwKind
					if cell then
						-- Shown here because a header row (MINOR 36) or a hidden button hid it on this frame's
						-- last populate; the kinds below hide it again where they must.
						cell:Show()
						if kind == "checkbox" then
							cell:SetChecked(entry[col.key] and true or false)
							-- A row flagged `_readonly` (MINOR 34, FGI inbox 7e28e319) cannot be toggled: rows a
							-- guild policy owns, shown to someone who may only look. Re-applied per populate in
							-- BOTH directions, because a pooled frame goes on to show an editable row.
							if entry._readonly then cell:Disable() else cell:Enable() end
						elseif kind == "expander" then
							-- nil: the row has nothing to expand, so no affordance at all.
							local st = entry[col.key]
							if st == nil then
								cell:Hide()
							else
								cell:Show()
								cell.label:SetText(st and "-" or "+")
							end
						elseif kind == "icon" then
							-- Icon column: draw a per-row texture, resolved from col.icon(entry) -> texturePath,
							-- desaturated. A nil texture hides the cell; `desaturated` truthy renders it greyed (an
							-- "off" state) — e.g. a wishlist coin gold when listed, grey when not. SORTING still uses
							-- entry[col.key], so the row supplies a sort value (1 present / 0 absent) and the header
							-- sorts marker-first/-last like any column. Reusable for a wishlist coin, a won / standby /
							-- priority marker in DKP/EPGP lists, etc.
							local t = cell._tex
							if t then
								local tex, desat = col.icon(entry)
								if tex then
									t:SetTexture(tex)
									t:SetDesaturated(desat and true or false)
									-- `col.iconTexCoord` (MINOR 36): `{ l, r, t, b }`, or `true` for the usual icon
									-- crop. Set on EVERY populate, full texture included, because the holder is
									-- pooled and may have served a cropping column before.
									local tc = col.iconTexCoord
									if tc == true then tc = ICON_CROP end
									if type(tc) == "table" then
										t:SetTexCoord(tc[1] or 0, tc[2] or 1, tc[3] or 0, tc[4] or 1)
									else
										t:SetTexCoord(0, 1, 0, 1)
									end
									t:Show()
								else
									t:Hide()
								end
							end
						else
							-- A `button` cell (MINOR 34) holds its text on its own label; a text cell IS the
							-- FontString. One target, so the two kinds cannot drift apart in how they format,
							-- colour, re-font or strike their value.
							local fs = cell
							if kind == "button" then
								fs = cell.label
								-- Read-only, exactly as the checkbox above: a disabled Button takes no click and
								-- shows no highlight, so the cell stops claiming to be editable.
								if entry._readonly then cell:Disable() else cell:Enable() end
								-- `col.show(entry)` false (MINOR 36): no button at all on this row -- hidden, so it
								-- takes no mouse and leaves the cell blank. `_cellText` answers "" for it too.
								if col.show and not col.show(entry) then cell:Hide() end
							end
							-- Width and measure only for a formatter, and resolved per repaint: a parent resize
							-- ends in `_refresh`, so a fit-to-width formatter re-fits (MINOR 36). The indent
							-- column's text is narrower by the row's indent.
							local sval
							if col.format then
								local w = self:CellWidth(col.key)
								if w and ind > 0 and col == self:_indentColumn() then w = math.max(0, w - ind) end
								sval = self:_cellText(col, entry, w, self:_measurerFor(col))
							else
								sval = self:_cellText(col, entry)
							end
							fs:SetText(sval)
							-- Optional re-font of a cell whose text just turned
							-- non-Latin (e.g. native numerals), if the consumer
							-- wired a refont hook (LibLocaleOverride font manager).
							-- Handed the SCALED font object, so a re-font keeps the size the scale chose.
							-- The list's own hook (MINOR 34) wins over the session-global one.
							local refont = self.refontHook or lib.config.refontHook
							if refont and sval:find("[\128-\255]") then
								refont(fs, cellFont(col))
							end
							-- The strikethrough (MINOR 33), resolved HERE rather than by the consumer,
							-- because the rows are pooled: a scroll changes which entry this frame shows
							-- and fires no callback, so a line drawn from outside would stay on the frame
							-- while the entry it belonged to moved.
							--
							-- Sized to the RENDERED text (`GetStringWidth`), not the column, so the line
							-- stops where the words do -- and it follows the FontString rather than the
							-- raw string, so an item link's colour escapes and its icon are measured as
							-- the player sees them. Clamped to the cell, because a string too long for
							-- its column is truncated on screen while GetStringWidth still reports the
							-- whole of it, and an unclamped line would run out across the next column.
							-- Height and colour are set per populate too: the height follows the scale
							-- (a re-scale ends in Refresh), and the colour is the cell's own text colour
							-- so the line belongs to the text rather than to the theme.
							local st = row.cellStrikes and row.cellStrikes[col.key]
							if st then
								if col.strike(entry) then
									local w = fs:GetStringWidth() or 0
									local cw = cell:GetWidth() or 0
									if cw > 0 and w > cw then w = cw end
									if w > 0 then
										local r, g, b = fs:GetTextColor()
										st:SetHeight(lib:ScaledSize(STRIKE_HEIGHT))
										st:SetWidth(w)
										st:SetColorTexture(r or 1, g or 1, b or 1, STRIKE_ALPHA)
										st:Show()
									else
										st:Hide()
									end
								else
									st:Hide()
								end
							end
						end
					end
				end
				-- Per-row action icons whose texture is a FUNCTION(entry) reflect this row's STATE (e.g. a
				-- wishlist coin: gold when listed, grey when not) — resolved here on populate (pooled rows). The
				-- function may return (texture, desaturated) so the SAME icon can render greyed for an "off" state.
				if row.actionBtns and not isHeader then
					for ai = 1, #self.actions do
						local action = self.actions[ai]
						local b = row.actionBtns[ai]
						-- `action.show(entry)` gates the icon's PRESENCE — the action-side counterpart of an
						-- icon column returning a nil texture to hide its cell. Needed when an action is
						-- meaningful on only a few rows (e.g. "request this from the guild bank" — true for a
						-- handful of items, false for the rest): a greyed icon on EVERY row is noise, and a
						-- blank normal texture is worse, because the button keeps its highlight and stays
						-- clickable. Absent `show` = always visible, so existing consumers are unaffected.
						-- Re-evaluated per populate, so a consumer whose gating data arrives late (a sibling
						-- addon still initializing) only has to call Refresh.
						if b and action.show and not action.show(entry) then
							b:Hide()
						elseif b then
							b:Show()
							if type(action.texture) == "function" then
								local tex, desat = action.texture(entry)
								b:SetNormalTexture(tex or "")
								local nt = b:GetNormalTexture()
								if nt then nt:SetDesaturated(desat and true or false) end
							end
						end
					end
				end
				row:Show()
			else
				row:Hide()
			end
		else
			row:Hide()
		end
	end
	-- Every path that moves the list ends in this repaint, so this is the one place to say it moved.
	self:_reportScroll()
end

--- Re-render visible rows from current data + listOffset, recomputing pool size
--- and scrollbar range from the parent's current height. Call after external
--- data mutation, parent resize, or whenever the visible window may be stale.
---
--- It DROPS the cached view first (MINOR 34, peer review H2): "after external data mutation" means the
--- filtered and sorted snapshot may hold a row the consumer just removed, which would stay drawn and
--- clickable. The list's own repaints that change nothing in the data -- a resize, a scale change, a
--- scroll-to -- call `_refresh`, which keeps the cache.
function RowList:Refresh()
	self._dataSorted = nil
	self._searchHay = nil   -- MINOR 36: an entry's words may have changed with it
	self:_refresh()
end

function RowList:_refresh()
	if self._detached then return end
	if self.fitContent then self:_fitHeight() end
	self:_recomputeVisibleRows()

	-- The rows DRAWN, not `#self.data`: a filtered or searched list is shorter than its data, and a
	-- scroll range over the full count would scroll into empty rows (MINOR 34).
	local maxOffset = math.max(0, #self:_getSortedData() - self.visibleRowCount)
	if self.listOffset > maxOffset then
		self.listOffset = maxOffset
	end

	local sb = self.scrollbar
	if sb then
		sb:SetMinMaxValues(0, maxOffset)
		-- SetValue fires OnValueChanged, but its handler early-returns when the
		-- offset hasn't changed — no loop.
		sb:SetValue(self.listOffset)
		if maxOffset > 0 then
			sb:Show()
		else
			sb:Hide()
		end
	end

	self:_renderRows()
end

--- Take the list off its parent for good (MINOR 34, TOGTools inbox c571dee6 item 5). Call it from the
--- host widget's OnRelease.
---
--- WHY: a list is usually built inside an AceGUI container's frame, and AceGUI pools that frame for the
--- next widget that asks -- possibly another addon's. `New` HookScripts the parent's OnSizeChanged and
--- OnMouseWheel, and a HookScript cannot be removed, so without this the old list goes on growing,
--- re-laying and scrolling its rows inside whatever widget gets the frame next.
---
--- What it does: closes a column menu this list opened, hides the rows, header and scrollbar and
--- re-parents them to UIParent, and makes every later repaint, resize, rescale, scroll, wheel and
--- SetColumns a no-op. A detached list is finished; build a new one for the next window. Idempotent.
function RowList:Detach()
	if self._detached then return end
	self:_endDrag(false)   -- a drag in progress is cancelled, not dropped into a list that is going away
	self._detached = true
	if self._menuAnchor then lib:CloseMenuFor(self._menuAnchor) end
	local function orphan(f)
		if not f then return end
		f:Hide()
		f:ClearAllPoints()
		f:SetParent(UIParent)
	end
	for _, r in ipairs(self.rows) do orphan(r) end
	orphan(self.header)
	orphan(self.scrollbar)
end

--- Clamp the scroll offset to a valid value and refresh — useful after the data
--- array shrinks (e.g. an entry was deleted).
function RowList:ClampOffset()
	self._dataSorted = nil   -- documented for after the array shrinks, so the view is stale (H2)
	local maxOffset = math.max(0, #self:_getSortedData() - (self.visibleRowCount or self.rowCount))
	if self.listOffset > maxOffset then
		self.listOffset = maxOffset
	end
	self:Refresh()
end

-- ---------------------------------------------------------------------------
-- Finding an entry, scrolling to it, and selecting it (MINOR 31)
-- ---------------------------------------------------------------------------
-- Questbook's Rewards tab (inbox 6b742a0a, 2026-09-18): a click on a reward jumps to the Browse tab
-- with the quest in view and marked. They had it working by reading `_getSortedData` and writing
-- `listOffset` from the consumer side -- two internals -- and had nothing for "marked" at all.

-- The 1-based index of `target` in `list` (default: the sorted data, which is the order the rows are
-- drawn in). `target` is an entry (matched by identity) or a `function(entry) -> bool` (the FIRST
-- match in list order wins). nil, and the entry, when found; nil alone otherwise.
function RowList:_indexOf(target, list)
	list = list or self:_getSortedData()
	if type(target) == "function" then
		for i, e in ipairs(list) do
			if target(e) then return i, e end
		end
	elseif target ~= nil then
		for i, e in ipairs(list) do
			if e == target then return i, e end
		end
	end
	return nil
end

--- Scroll so `target` (an entry, or a predicate) is the TOP visible row. Returns whether it was found.
---
--- "Top" holds only where the clamp allows: the list never scrolls past its own end, so an entry on
--- the last page comes into view lower down, exactly as the scrollbar would leave it. That clamp is
--- Refresh's, the same one every other scroll goes through -- this method sets the offset and lets
--- Refresh settle it, so a consumer's spec written for "top" must expect the clamp on the last page.
--- Nothing scrolls when nothing matches.
---
--- `opts` (MINOR 36, TOGProfessionMaster inbox bdf1159c), both optional:
---   `context = n`   leave n rows visible beyond the entry -- above it when scrolling up to it, below it
---                   when scrolling down -- capped at one less than the rows on screen, and still subject
---                   to the clamp at either end of the list.
---   `ifNeeded`      do not scroll at all when the entry is already on screen, so a selection that moves
---                   within the page does not make the list lurch. Scrolling down brings the entry in at
---                   the BOTTOM (plus `context`) rather than the top.
function RowList:ScrollToEntry(target, opts)
	local idx = self:_indexOf(target)
	if not idx then return false end
	local off, vis = self.listOffset or 0, self.visibleRowCount or 0
	local ctx = math.floor(tonumber(opts and opts.context) or 0)
	ctx = math.max(0, math.min(ctx, vis - 1))
	if opts and opts.ifNeeded then
		if idx > off and idx <= off + vis then return true end
		if idx > off + vis then
			self.listOffset = idx - vis + ctx
		else
			self.listOffset = idx - 1 - ctx
		end
	else
		self.listOffset = idx - 1 - ctx
	end
	if self.listOffset < 0 then self.listOffset = 0 end
	self:_refresh()   -- the index came from the cached view; dropping it could move the entry
	return true
end

--- The scroll position in ROWS: the index of the top visible entry, less one (MINOR 36, inbox bdf1159c).
--- What a consumer saves to put a list back where the player left it, even across a /reload.
function RowList:GetScrollOffset()
	return self.listOffset or 0
end

--- Scroll to `offset` rows, clamped exactly as every other scroll is (never negative, never past the
--- last full page of what is drawn), with one repaint. Returns the offset that stood. Call it after
--- `SetData`: the clamp needs the rows to measure against.
function RowList:SetScrollOffset(offset)
	self.listOffset = math.max(0, math.floor(tonumber(offset) or 0))
	self:_refresh()
	return self.listOffset
end

--- `opts.onScroll(rl, offset)` (MINOR 36): told the new offset after ANY change -- the wheel, the
--- scrollbar, `SetScrollOffset`, `ScrollToEntry`, a `SetData` or search that went back to the top, a
--- clamp. Called from the repaint, so it is once per repaint and only with an offset different from the
--- last one reported: a repaint that did not move the list says nothing.
---
--- NOT COALESCED ACROSS A FRAME, which the request asked for. That would need a timer standing in for
--- "the frame ended", and this library does not add one; each wheel notch is its own event and its own
--- new offset, and saving an integer per notch costs a consumer nothing.
function RowList:_reportScroll()
	local off = self.listOffset or 0
	if not self.onScroll or off == self._reportedOffset then return end
	self._reportedOffset = off
	self.onScroll(self, off)
end

--- Mark `target` (an entry, a predicate, or nil to clear) as the selected row and repaint. Returns
--- the entry now selected, or nil. A target not in the data selects nothing (and clears the previous
--- selection), so the highlight can never point at something the list does not hold. The highlight
--- rides the ENTRY, not the row frame: it follows through pooling, scroll and a re-sort, and SetData
--- drops it unless the same entry is still present.
function RowList:SetSelected(target)
	local _, entry = self:_indexOf(target)
	self._selected = entry
	self:_renderRows()
	return entry
end

function RowList:GetSelected()
	return self._selected
end

--- `rl:CellFrameFor(target, columnKey)` (MINOR 37, Dibs inbox 55767d11): the frame on screen that shows
--- `target`'s cell in column `columnKey`, or nil. `target` is an entry (by identity), a
--- `function(entry) -> bool`, or an index into the drawn (sorted, filtered) order. For a column with
--- `onCellEnter` / `onCellLeave` / `onCellClick` it is that cell's mouse overlay, since that is what takes
--- the pointer; otherwise the cell itself.
---
--- READ-ONLY: it never scrolls or repaints. nil for an entry not in the view, one scrolled off the page,
--- an unknown column, a heading row (its cells are hidden), a cell this row does not show (a hidden
--- button, an expander with nothing to expand), and a detached list. Answers for the columns as they are
--- NOW, so it follows a `SetColumns`. Rows are pooled: hold the frame only as long as nothing scrolls.
function RowList:CellFrameFor(target, columnKey)
	if self._detached or columnKey == nil then return nil end
	local col
	for _, c in ipairs(self.columns) do
		if c.key == columnKey then col = c; break end
	end
	if not col then return nil end
	local idx, entry
	if type(target) == "number" then
		idx = math.floor(target)
		entry = self:_getSortedData()[idx]
	else
		idx, entry = self:_indexOf(target)
	end
	if not entry or self:_isHeaderRow(entry) then return nil end
	local slot = idx - (self.listOffset or 0)
	if slot < 1 or slot > (self.visibleRowCount or 0) then return nil end
	local row = self.rows[slot]
	if not row then return nil end
	local frame = (row.cellOverlays and row.cellOverlays[columnKey]) or row.cells[columnKey]
	if not frame or not frame:IsShown() then return nil end
	return frame
end

-- ---------------------------------------------------------------------------
-- Drag to reorder (MINOR 36, TOGProfessionMaster inbox 973a1ab1)
-- ---------------------------------------------------------------------------
-- `opts.reorderable = true` with `opts.onReorder(fromIndex, toIndex, entry, rl)`. Dragging a row lifts a
-- copy of it that follows the pointer at TOOLTIP strata, dims the row itself, and draws an accent line at
-- the slot it would drop into. Dropping calls `onReorder` with the entry's index in `data` now and the
-- index it should have after the move; the list moves nothing itself -- the consumer reorders its model
-- and calls SetData. Held against the list's top or bottom row, the list scrolls a row every 0.1 s.
-- Escape (out of combat), a drop off the list, or a drop in the slot it came from ends it with no call.

--- Can a drag start now? Only while the DRAWN order is the MODEL order, so an index means the same thing
--- to the list and the consumer: no header sort (an `externalSort` list draws `data` as given, so it
--- may drag), no column filter and no search. With any of those active, a drag simply does not start.
function RowList:_canReorder()
	if not self.reorderable or self._detached then return false end
	if self.sortKey and not self.externalSort then return false end
	if self.searchText or self:_isFiltering() then return false end
	return true
end

--- The lifted row and the insert line, built on the first drag and kept.
function RowList:_dragFrames()
	if self._dragGhost then return self._dragGhost, self._dropLine end
	local rl = self
	local ghost = CreateFrame("Frame", nil, UIParent)
	ghost:SetFrameStrata("TOOLTIP")
	local bg = ghost:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(ghost)
	bg:SetColorTexture(0, 0, 0, 0.75)
	local fs = ghost:CreateFontString(nil, "OVERLAY")
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(false)
	fs:SetMaxLines(1)
	ghost.label = fs
	ghost:Hide()
	-- Runs only while the ghost is shown, which is only while a drag is live.
	ghost:SetScript("OnUpdate", function(_, elapsed) rl:_dragUpdate(elapsed) end)
	-- Escape cancels; every other key goes on to the game. SetPropagateKeyboardInput is restricted
	-- (SimpleFrameAPIDocumentation.lua, HasRestrictions) and EnableKeyboard protected, so both are only
	-- touched out of combat -- in combat the keyboard is not captured, and a drop off the list cancels.
	ghost:SetScript("OnKeyDown", function(f, key)
		local esc = key == "ESCAPE"
		if not InCombatLockdown() then f:SetPropagateKeyboardInput(not esc) end
		if esc then rl:_endDrag(false) end
	end)
	-- A FRAME above the rows, not a texture on the parent: a frame's own textures draw beneath its child
	-- frames, so every row would cover the line.
	local line = CreateFrame("Frame", nil, self.parent)
	line:SetFrameLevel((self.parent:GetFrameLevel() or 0) + 20)
	local lt = line:CreateTexture(nil, "OVERLAY")
	lt:SetAllPoints(line)
	line.tex = lt
	line:Hide()
	self._dragGhost, self._dropLine = ghost, line
	return ghost, line
end

--- OnDragStart of pooled row `i`.
function RowList:_beginDrag(i)
	if self._drag or not self:_canReorder() then return end
	local from = (self.listOffset or 0) + i
	local entry = self.data[from]
	if not entry then return end
	local ghost, line = self:_dragFrames()
	local row = self.rows[i]
	-- The ghost lives on UIParent (so it can leave the window); scaled to match the list's own scale.
	ghost:SetScale((self.parent:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1))
	ghost:SetSize(row:GetWidth() or 0, self.rowHeight)
	local col = self:_indentColumn()
	ghost.label:SetFontObject(cellFont(col or {}))
	ghost.label:ClearAllPoints()
	ghost.label:SetPoint("LEFT", ghost, "LEFT", self.leftPad, 0)
	ghost.label:SetPoint("RIGHT", ghost, "RIGHT", -self.leftPad, 0)
	local text = self:_isHeaderRow(entry) and self:_headerText(entry) or (col and self:_cellText(col, entry)) or ""
	ghost.label:SetText(text)
	local ar, ag, ab = lib:AccentRGB()
	line.tex:SetColorTexture(ar, ag, ab, 1)
	line:SetHeight(lib:ScaledSize(DROP_LINE_HEIGHT))
	self._drag = { from = from, entry = entry, acc = 0 }
	if not InCombatLockdown() then
		ghost:EnableKeyboard(true)
		ghost:SetPropagateKeyboardInput(true)
	end
	ghost:Show()
	self:_dragUpdate(0)
	self:_renderRows()   -- dims the lifted row
end

--- Per frame while dragging: move the ghost to the pointer, work out the drop slot and draw the line
--- there, and step the list when the pointer is held on its first or last drawn row.
function RowList:_dragUpdate(elapsed)
	local d = self._drag
	if not d then return end
	if not self.parent:IsVisible() then return self:_endDrag(false) end
	local ghost, line = self._dragGhost, self._dropLine
	local _, cy = GetCursorPosition()
	local ps = self.parent:GetEffectiveScale() or 1
	local gs = ghost:GetEffectiveScale() or 1
	ghost:ClearAllPoints()
	ghost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", (self.parent:GetLeft() or 0) * ps / gs, cy / gs)

	local off = self.listOffset or 0
	local shown = math.min(self.visibleRowCount or 0, #self.data - off)
	local top = self.parent:GetTop()
	if not top or shown <= 0 then
		d.slot = nil
		line:Hide()
		return
	end
	-- Pointer distance below the first row's top edge, in the list's own units; the slot is the row
	-- boundary nearest it, so the line sits BETWEEN rows.
	local rel = (top - self.headerHeight) - cy / ps
	local s = math.max(0, math.min(shown, math.floor(rel / self.rowHeight + 0.5)))
	d.slot = off + s + 1   -- the index the entry is inserted BEFORE
	local y = -(self.headerHeight + s * self.rowHeight) + line:GetHeight() / 2
	line:ClearAllPoints()
	line:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, y)
	line:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -SCROLLBAR_GUTTER, y)
	line:Show()

	d.acc = d.acc + (elapsed or 0)
	if d.acc < DRAG_SCROLL_STEP then return end
	d.acc = 0
	local _, maxOffset = self.scrollbar:GetMinMaxValues()
	if rel < self.rowHeight and off > 0 then
		self.scrollbar:SetValue(off - 1)
	elseif rel > (shown - 1) * self.rowHeight and off < (maxOffset or 0) then
		self.scrollbar:SetValue(off + 1)
	end
end

--- End the drag. `commit` false is a cancel. A commit still calls nothing when the pointer is off the
--- list, when the entry would land where it already is, or when the data changed under the drag (the
--- index it was lifted from no longer holds it, or a sort, filter or search started).
function RowList:_endDrag(commit)
	local d = self._drag
	if not d then return end
	self._drag = nil
	local ghost = self._dragGhost
	ghost:Hide()
	if not InCombatLockdown() then ghost:EnableKeyboard(false) end
	self._dropLine:Hide()
	local slot = commit and self.parent:IsMouseOver() and d.slot or nil
	if self.data[d.from] ~= d.entry or not self:_canReorder() then slot = nil end
	self:_renderRows()   -- un-dims the row
	if not slot then return end
	local to = slot > d.from and slot - 1 or slot
	if to ~= d.from then self.onReorder(d.from, to, d.entry, self) end
end
