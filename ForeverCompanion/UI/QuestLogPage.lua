--[[
  Forever Companion - UI/QuestLogPage.lua
  The Completed quests page of the journal: every quest the game says a
  character completed, by name. It is the list behind the "Quests
  completed" number of the Progress page, so the two always agree.

  The quests come from the game (Features/QuestHistory.lua), also the ones
  done before the addon was installed or while it was off: those have their
  name, zone, level and quest giver, but no date. A quest the game cannot
  name is listed as "Unknown completed quest" with its ID until its name
  arrives. Quests accepted while the journal watched open their journal
  entry on a click; the others set a waypoint to where they start.

  Characters are picked with the chips (one of yours, or all of them); the
  journal's search box filters by name, zone, quest giver or ID, and the
  list is grouped by zone or sorted by name, level or date. Only the rows
  that fit are drawn, so a character with thousands of quests costs the
  same as one with twenty.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local Theme = FC.Theme
local Compat = FC.Compat

local ROW = 22
local LEVEL_WIDTH, INFO_WIDTH = 46, 150
local CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local WAITING = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"
local QUEST_ICON = "Interface\\Icons\\INV_Misc_Note_02"

UI.QUESTLOG_SORTS = { "zone", "name", "level", "recent" }

local function lowered(text)
    return type(text) == "string" and text:lower() or ""
end

local function byTitle(a, b)
    local ta, tb = lowered(a.title), lowered(b.title)
    if ta ~= tb then return ta < tb end
    return a.questID < b.questID
end

local function newRow(parent, page)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.05)
    row.hover:SetAllPoints()
    row.icon = UI.Icon(row, 14)
    row.icon:SetPoint("LEFT", 6, 0)
    row.info = UI.Text(row, "meta", "muted")
    row.info:SetJustifyH("RIGHT")
    row.info:SetWidth(INFO_WIDTH)
    row.info:SetPoint("RIGHT", -8, 0)
    row.level = UI.Text(row, "meta", "muted")
    row.level:SetJustifyH("RIGHT")
    row.level:SetWidth(LEVEL_WIDTH)
    row.level:SetPoint("RIGHT", row.info, "LEFT", -8, 0)
    row.title = UI.Text(row, "secondary", "text")
    row.title:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.title:SetPoint("RIGHT", row.level, "LEFT", -8, 0)
    -- a group's title: its name, how many, and a rule under it
    row.group = UI.Text(row, "meta", "accent")
    row.group:SetPoint("LEFT", 6, 0)
    row.count = UI.Text(row, "meta", "muted")
    row.count:SetJustifyH("RIGHT")
    row.count:SetPoint("RIGHT", -8, 0)
    row.group:SetPoint("RIGHT", row.count, "LEFT", -8, 0)
    row.line = UI.Divider(row, "border", 0.6)
    row.line:SetPoint("BOTTOMLEFT", 4, 1)
    row.line:SetPoint("BOTTOMRIGHT", -4, 1)
    row:SetScript("OnEnter", function(self)
        page.hover = self
        page:RowTooltip(self)
    end)
    row:SetScript("OnLeave", function(self)
        if page.hover == self then page.hover = nil end
        UI.HideTooltip()
    end)
    row:SetScript("OnClick", function(self) FC:SafeCall("questlog-row", page.RowClick, page, self.item) end)
    return row
end

function UI.QuestLogPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page.title = L.NAV_QUESTLOG
    page.keys = nil       -- nil: the character you play; otherwise { [key] = true }
    page.searchText = ""
    page.items, page.rows, page.offset = {}, {}, 0

    page.summary = UI.WrappedText(page, "secondary", "text")
    page.summary:SetPoint("TOPLEFT", 4, -4)
    page.note = UI.WrappedText(page, "meta", "muted")
    page.chips = UI.Pool(function()
        return UI.Chip(page, "", nil, function(_, _, chip)
            if chip.onClick then FC:SafeCall("questlog-chip", chip.onClick) end
        end)
    end, function(chip) chip.onClick = nil end)

    -- the rows lie on a sheet of parchment, like the journal's cards
    page.panel = UI.Panel(page, { bg = "panel", bgAlpha = 0, border = false, shade = false, skin = "panel", corner = 12 })
    local list = CreateFrame("Frame", nil, page.panel)
    if list.SetClipsChildren then list:SetClipsChildren(true) end
    page.list = list
    local bar = UI.CreateScrollbar(list, function(value)
        page.offset = math.floor(value + 0.5)
        page:Render()
    end)
    bar:SetPoint("TOPRIGHT", 0, -2)
    bar:SetPoint("BOTTOMRIGHT", 0, 2)
    page.bar = bar
    page.empty = UI.EmptyState(page)

    function page:Sort()
        local sort = FC.P.journal.questSort
        for _, key in ipairs(UI.QUESTLOG_SORTS) do
            if key == sort then return sort end
        end
        return "zone"
    end

    -- the page's own controls, shown in the journal's toolbar row (MainWindow
    -- places them); the dropdown asks for the sort as soon as it is made
    page.sortBox = UI.Dropdown(page, nil, function()
        local items = {}
        for _, key in ipairs(UI.QUESTLOG_SORTS) do items[#items + 1] = { value = key, text = L["QUESTLOG_SORT_" .. key:upper()] } end
        return items
    end, function() return page:Sort() end, function(value)
        FC.P.journal.questSort = value
        page:Arrange()
    end, 150)
    page.rescan = UI.Button(page, L.QUESTLOG_RESCAN, { autoWidth = true, width = 90, height = 28, tooltip = L.QUESTLOG_RESCAN_TIP, onClick = function()
        FC.QuestHistory:Rescan()
        page:Refresh()
    end })

    --- The characters shown: { [key] = true }.
    function page:Keys()
        return self.keys or { [FC.Store.me] = true }
    end

    --- Shows the quests of these characters ({ [key] = true }; nil: the one you play).
    function page:SetSelection(keys)
        self.keys = keys
        self.offset = 0
        self:Refresh()
    end

    function page:SetSearch(text)
        text = U.Trim(text or "")
        if text == self.searchText then return end
        self.searchText = text
        self.offset = 0
        if self:IsShown() then self:Arrange() end
    end

    local function matches(row, needle)
        if needle == "" then return true end
        local id = tostring(row.questID)
        if id == needle or ("#" .. id) == needle then return true end
        return lowered(row.title):find(needle, 1, true) ~= nil or lowered(row.zone):find(needle, 1, true) ~= nil
            or lowered(row.giver):find(needle, 1, true) ~= nil
    end

    --- Filters, sorts and groups the quests into the lines to draw.
    function page:Arrange()
        local needle = lowered(self.searchText)
        local named, unnamed = {}, {}
        for _, row in ipairs(self.quests or {}) do
            if matches(row, needle) then
                if row.title then named[#named + 1] = row else unnamed[#unnamed + 1] = row end
            end
        end
        local items = {}
        local sort = self:Sort()
        if sort == "zone" then
            local groups, order = {}, {}
            for _, row in ipairs(named) do
                local zone = row.zone or false
                if not groups[zone] then
                    groups[zone] = {}
                    order[#order + 1] = zone
                end
                table.insert(groups[zone], row)
            end
            -- zones by name; quests that belong to no zone come last
            table.sort(order, function(a, b)
                if (a == false) ~= (b == false) then return b == false end
                return lowered(a or "") < lowered(b or "")
            end)
            for _, zone in ipairs(order) do
                local group = groups[zone]
                table.sort(group, function(a, b)
                    local la, lb = a.level or 999, b.level or 999
                    if la ~= lb then return la < lb end
                    return byTitle(a, b)
                end)
                items[#items + 1] = { header = zone or L.QUESTLOG_OTHER, count = #group }
                for _, row in ipairs(group) do items[#items + 1] = row end
            end
        else
            if sort == "level" then
                table.sort(named, function(a, b)
                    local la, lb = a.level or 999, b.level or 999
                    if la ~= lb then return la < lb end
                    return byTitle(a, b)
                end)
            elseif sort == "recent" then
                -- dated quests first, newest on top; the others have no date to sort by
                table.sort(named, function(a, b)
                    local ta, tb = a.at or 0, b.at or 0
                    if ta ~= tb then return ta > tb end
                    return byTitle(a, b)
                end)
            else
                table.sort(named, byTitle)
            end
            for _, row in ipairs(named) do items[#items + 1] = row end
        end
        if #unnamed > 0 then
            table.sort(unnamed, function(a, b) return a.questID < b.questID end)
            items[#items + 1] = { header = L.QUESTLOG_UNNAMED, count = #unnamed, unnamed = true }
            for _, row in ipairs(unnamed) do items[#items + 1] = row end
        end
        self.items = items
        self.shownQuests = #named + #unnamed
        self:Layout()
    end

    function page:VisibleCount()
        return math.max(0, math.floor((self.list:GetHeight() or 0) / ROW))
    end

    --- Who or what gives a quest, by the best name known right now. Only for
    --- the rows that are drawn and the one under the mouse: the game is asked
    --- in the background when it can name a creature better (Reference).
    local function giverName(item)
        if item.giverID then
            item.giver = FC.Reference:DisplayNpcName(item.giverID) or item.giver
        elseif item.start == "item" and not item.giver then
            item.giver = Compat.GetItemName(item.itemID)
        end
        return item.giver
    end

    local function bind(row, item)
        row.item = item
        local header = item.header ~= nil
        row.icon:SetShown(not header)
        row.title:SetShown(not header)
        row.level:SetShown(not header)
        row.info:SetShown(not header)
        row.group:SetShown(header)
        row.count:SetShown(header)
        row.line:SetShown(header)
        row.hover:SetShown(not header or item.unnamed == true)
        if header then
            row.group:SetText(item.header:upper())
            row.count:SetText(U.FormatNumber(item.count))
            return
        end
        if item.title then
            UI.SetIcon(row.icon, item.rec and (item.rec.ic or QUEST_ICON) or CHECK)
            row.title:SetText(U.Escape(item.title))
            Theme:Paint(row.title, "text")
            row.level:SetText(item.level and string.format(L.QUESTLOG_LEVEL, item.level) or "")
            -- on the right: when it was turned in, if the journal watched; else
            -- who gives it (under a zone's title) or its zone (in a plain list)
            local giver = giverName(item)
            if item.at then
                row.info:SetText(U.TimeAgo(item.at))
            elseif page:Sort() == "zone" then
                row.info:SetText(giver and U.Escape(giver) or "")
            else
                row.info:SetText(U.Escape(item.zone or giver or ""))
            end
        else
            UI.SetIcon(row.icon, item.pending and WAITING or UNKNOWN)
            row.title:SetText(item.pending and L.QUESTLOG_ASKING or L.QUESTLOG_UNKNOWN)
            Theme:Paint(row.title, "muted")
            row.level:SetText("")
            row.info:SetText(string.format(L.TIP_QUEST_ID, item.questID))
        end
    end

    function page:Render()
        local visible = self:VisibleCount()
        local maxOffset = math.max(0, #self.items - visible)
        self.offset = U.Clamp(self.offset, 0, maxOffset)
        for i = #self.rows + 1, visible do self.rows[i] = newRow(self.list, self) end
        for i, row in ipairs(self.rows) do
            local item = i <= visible and self.items[i + self.offset]
            if item then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
                row:SetPoint("RIGHT", self.bar, "LEFT", -6, 0)
                bind(row, item)
                row:Show()
            else
                row.item = nil
                row:Hide()
            end
        end
        local scroll = self.bar
        scroll.fcUpdating = true
        scroll:SetMinMaxValues(0, maxOffset)
        scroll:SetValue(self.offset)
        scroll.fcUpdating = false
        scroll:SetShown(maxOffset > 0)
    end

    --- Places the summary, the character chips and the list for the page's width.
    function page:Layout()
        local width = self:GetWidth() or 0
        if width <= 0 then width = 600 end
        local counts = self.counts or { total = 0, named = 0, unnamed = 0, pending = 0, journal = 0, dated = 0 }
        local parts = { string.format(L.QUESTLOG_SUMMARY, U.FormatNumber(counts.total)) }
        if counts.pending > 0 then
            parts[#parts + 1] = U.Colorize(string.format(L.QUESTLOG_SUMMARY_ASKING, counts.pending), Theme:Hex("accent"))
        elseif counts.unnamed > 0 then
            parts[#parts + 1] = string.format(L.QUESTLOG_SUMMARY_UNNAMED, counts.unnamed)
        end
        if self.searchText ~= "" then parts[#parts + 1] = string.format(L.QUESTLOG_SUMMARY_SHOWN, U.FormatNumber(self.shownQuests or 0)) end
        self.summary:SetWidth(width - 8)
        self.summary:SetText(table.concat(parts, "  \194\183  "))
        local y = 4 + math.max(14, self.summary:GetStringHeight()) + 4
        self.note:ClearAllPoints()
        self.note:SetPoint("TOPLEFT", 4, -y)
        self.note:SetWidth(width - 8)
        self.note:SetText(string.format(L.QUESTLOG_NOTE, U.FormatNumber(counts.dated), U.FormatNumber(counts.journal)))
        y = y + math.max(12, self.note:GetStringHeight()) + 10

        -- whose quests: one of your characters, or all of them
        self.chips:ReleaseAll()
        local chars = FC.Progress:Characters()
        local keys = self:Keys()
        local selected = U.Count(keys)
        local accent = Theme:Hex("accent")
        local x = 4
        local function chip(text, active, onClick)
            local c = self.chips:Acquire()
            c:SetChip(text, active and accent or nil)
            c.onClick = onClick
            local w = c:GetWidth()
            if x > 4 and x + w > width - 4 then
                x = 4
                y = y + 24
            end
            c:SetPoint("TOPLEFT", x, -y)
            x = x + w + 6
        end
        for _, char in ipairs(chars) do
            local done = U.Count((FC.db.characters[char.key] or {}).q)
            if done > 0 or char.current then
                local name = U.Colorize(U.Escape(char.name), Compat.ClassColorHex(char.class) or Theme:Hex("text"))
                chip(name .. "  " .. U.Colorize(U.FormatNumber(done), Theme:Hex("muted")), selected == 1 and keys[char.key] == true, function()
                    self:SetSelection(not char.current and { [char.key] = true } or nil)
                end)
            end
        end
        if #chars > 1 then
            local all = FC.Progress:AllKeys()
            chip(L.OVERVIEW_ALL_CHARACTERS, selected > 1 and selected == U.Count(all), function() self:SetSelection(all) end)
        end
        y = y + 18 + 10

        self.panel:ClearAllPoints()
        self.panel:SetPoint("TOPLEFT", 0, -y)
        self.panel:SetPoint("BOTTOMRIGHT", 0, 0)
        local pad = self.panel.fcPainted and 8 or 2
        self.list:ClearAllPoints()
        self.list:SetPoint("TOPLEFT", pad, -pad)
        self.list:SetPoint("BOTTOMRIGHT", -pad, pad)

        local nothing = #self.items == 0
        self.list:SetShown(not nothing)
        self.empty:SetShown(nothing)
        if nothing then
            self.empty:ClearAllPoints()
            self.empty:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -10)
            self.empty:SetPoint("BOTTOMRIGHT", self.panel, "BOTTOMRIGHT", -10, 10)
            local scan = FC.Characters:ScanState()
            if counts.total > 0 then
                self.empty:SetContent("Interface\\Icons\\INV_Misc_Spyglass_03", L.EMPTY_SEARCH_TITLE, L.QUESTLOG_EMPTY_SEARCH, nil, nil, "emptySearch")
            elseif scan.state ~= "ok" and selected == 1 and keys[FC.Store.me] then
                self.empty:SetContent(QUEST_ICON, L.QUESTLOG_WAITING_TITLE, L.QUESTLOG_WAITING_TEXT, L.QUESTLOG_RESCAN, function()
                    FC.QuestHistory:Rescan()
                    self:Refresh()
                end, "emptyJournal")
            else
                self.empty:SetContent(QUEST_ICON, L.QUESTLOG_EMPTY_TITLE, L.QUESTLOG_EMPTY_TEXT, nil, nil, "emptyJournal")
            end
        else
            self:Render()
        end
    end

    function page:RowTooltip(row)
        local item = row.item
        if not item then return end
        if item.header then
            if item.unnamed then UI.ShowTooltip(row, L.QUESTLOG_UNNAMED, { { L.QUESTLOG_UNNAMED_TIP, "text" } }, UNKNOWN) end
            return
        end
        local lines = { { string.format(L.TIP_QUEST_ID, item.questID), "muted" } }
        if not item.title then
            lines[#lines + 1] = { item.pending and L.QUESTLOG_PENDING_TIP or L.QUESTLOG_UNNAMED_TIP, "text" }
            UI.ShowTooltip(row, item.pending and L.QUESTLOG_ASKING or L.QUESTLOG_UNKNOWN, lines, UNKNOWN)
            return
        end
        local where = item.zone
        if item.level then where = (where and (where .. "  \194\183  ") or "") .. string.format(L.TIP_LEVEL, item.level) end
        if where then lines[#lines + 1] = { where, "muted" } end
        -- who or what gives it, and where it stands
        local giver = giverName(item)
        local start
        if item.start == "object" then
            start = string.format(L.QUESTLOG_STARTS_OBJECT, U.Escape(giver or string.format(L.ZONE_OBJECT_ID, item.objectID or 0)))
        elseif item.start == "item" then
            start = string.format(L.QUESTLOG_STARTS_ITEM, U.Escape(giver or string.format(L.TIP_ITEM_ID, item.itemID or 0)))
        elseif giver or item.giverID then
            start = string.format(L.ZONE_GIVEN_BY, U.Escape(giver or string.format(L.TIP_NPC_ID, item.giverID)))
        end
        if start then
            lines[#lines + 1] = { start, "text" }
            local m, x, y = self:PlaceOf(item)
            local coords = m and U.FormatCoords(x, y)
            if coords then
                local zone = Compat.GetMapName(m)
                lines[#lines + 1] = { zone and string.format(L.QUESTLOG_START_PLACE, zone, coords) or coords, "muted" }
            end
            if item.itemID and item.start ~= "item" then
                local name = Compat.GetItemName(item.itemID) or string.format(L.TIP_ITEM_ID, item.itemID)
                lines[#lines + 1] = { string.format(L.QUESTLOG_ALSO_ITEM, U.Escape(name)), "muted" }
            end
        else
            lines[#lines + 1] = { L.QUESTLOG_START_UNKNOWN, "muted" }
        end
        if item.at then
            lines[#lines + 1] = { string.format(L.QUESTLOG_TURNED_IN, U.FormatDate(item.at)), "text" }
        else
            lines[#lines + 1] = { L.QUESTLOG_NO_DATE, "muted" }
        end
        if (item.by or 1) > 1 then lines[#lines + 1] = { string.format(L.QUESTLOG_BY_N, item.by), "muted" } end
        if item.rec then
            lines[#lines + 1] = { L.QUESTLOG_HINT_JOURNAL, "accent" }
        elseif self:PlaceOf(item) then
            lines[#lines + 1] = { L.QUESTLOG_HINT_WAYPOINT, "muted" }
        end
        UI.ShowTooltip(row, U.Escape(item.title), lines, item.rec and (item.rec.ic or QUEST_ICON) or QUEST_ICON)
    end

    --- Where a quest starts, as far as anyone knows: map, x, y.
    function page:PlaceOf(item)
        if item.sm and item.sx then return item.sm, item.sx, item.sy end
        local m, x, y = FC.Reference:QuestPlace(item.questID)
        if m and x then return m, x, y end
        local npc = item.giverID and FC.QuestLore:GetNpc(item.giverID)
        if npc and npc.m and npc.x then return npc.m, npc.x, npc.y end
        return nil
    end

    function page:RowClick(item)
        if not item or item.header then return end
        if item.rec then
            FC.MainWindow:ShowDiscovery(item.rec.id)
            return
        end
        local m, x, y = self:PlaceOf(item)
        if m then FC.Waypoints:Set({ m = m, x = x, y = y, n = item.title or string.format(L.TIP_QUEST_ID, item.questID) }) end
    end

    function page:Refresh()
        local keys = self:Keys()
        -- characters that are no longer known leave the selection
        if self.keys then
            local known = FC.Progress:AllKeys()
            for key in pairs(self.keys) do
                if not known[key] then self.keys[key] = nil end
            end
            if next(self.keys) == nil then self.keys = nil end
            keys = self:Keys()
        end
        self.quests, self.counts = FC.QuestHistory:List(keys)
        local names = {}
        for key in pairs(keys) do names[#names + 1] = U.ShortName(key) end
        table.sort(names)
        local who = #names == 1 and names[1] or string.format(L.PROGRESS_N_CHARACTERS, #names)
        self.subtitle = string.format(L.QUESTLOG_SUBTITLE, who, U.FormatNumber(self.counts.total))
        self.sortBox:Refresh()
        self:Arrange()
        FC.MainWindow:PageChanged(self)
    end

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        page.offset = page.offset - delta * (IsShiftKeyDown() and 10 or 3)
        page:Render()
    end)
    list:SetScript("OnSizeChanged", function() page:Render() end)
    page:SetScript("OnSizeChanged", function(self)
        if self:IsVisible() and self.quests then self:Layout() end
    end)
    -- names the game told meanwhile: the rows drawn, and the open tooltip, take them
    FC.Bus:On("NPC_NAMES_CHANGED", page, function()
        if not page:IsVisible() then return end
        page:Render()
        local hover = page.hover
        if hover and hover.item and hover:IsVisible() then page:RowTooltip(hover) end
    end)
    return page
end
