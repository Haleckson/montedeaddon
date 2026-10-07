--[[
  Forever Companion - UI/ProgressPage.lua
  The Progress page of the journal: what the whole account found, and what
  any of your characters found, alone or together, whatever the progress
  mode. Characters are picked with the chips at the top (click more than
  one to add them up); the table at the bottom compares every character
  side by side, and a click on a row shows that character alone.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local Theme = FC.Theme
local Categories = FC.Categories
local Compat = FC.Compat

local ROW = 24
local TILE = 72
local COLUMNS = { "found", "zones", "quests", "rares", "flights" }
local COLUMN_WIDTH, SEEN_WIDTH = 70, 100
local MODE_WIDTH = 220

local function coloredName(char)
    local text = U.Colorize(U.Escape(char.name), Compat.ClassColorHex(char.class) or Theme:Hex("text"))
    if not char.tracked then text = text .. U.Colorize(" *", Theme:Hex("muted")) end
    return text
end

local function newTile(parent)
    local tile = UI.Panel(parent, { bg = "panelAlt", bgAlpha = 1, border = "border", shade = false, skin = "panel", corner = 10 })
    tile:SetHeight(TILE)
    tile.value = UI.Text(tile, "numeric", "text")
    tile.value:SetPoint("TOPLEFT", 14, -12)
    tile.value:SetPoint("RIGHT", -8, 0)
    tile.label = UI.Text(tile, "meta", "muted")
    tile.label:SetPoint("BOTTOMLEFT", 14, 12)
    tile.label:SetPoint("RIGHT", -8, 0)
    tile.bar = UI.Texture(tile, "ARTWORK", "accent", 0.9)
    tile.bar:SetPoint("BOTTOMLEFT", 1, 1)
    tile.bar:SetPoint("BOTTOMRIGHT", -1, 1)
    tile.bar:SetHeight(2)
    return tile
end

local function newBar(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(22)
    row.icon = UI.Icon(row, 16)
    row.icon:SetPoint("LEFT")
    row.label = UI.Text(row, "secondary", "text")
    row.label:SetPoint("LEFT", 24, 0)
    row.label:SetWidth(150)
    row.label:SetWordWrap(false)
    row.track = UI.Texture(row, "BACKGROUND", "panelAlt", 1)
    row.track:SetPoint("LEFT", 180, 0)
    row.track:SetPoint("RIGHT", -70, 0)
    row.track:SetHeight(8)
    row.fill = row:CreateTexture(nil, "ARTWORK")
    row.fill:SetTexture(FC.C.WHITE)
    row.fill:SetPoint("LEFT", row.track, "LEFT")
    row.fill:SetHeight(8)
    row.value = UI.Text(row, "secondary", "muted")
    row.value:SetPoint("RIGHT")
    return row
end

-- One line of the character table: name, the numbers, last played.
local function newTableRow(parent, header)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW)
    row.bg = UI.Texture(row, "BACKGROUND", "accent", 0)
    row.bg:SetAllPoints()
    if not header then
        row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.05)
        row.hover:SetAllPoints()
    end
    local font, color = header and "meta" or "secondary", header and "muted" or "text"
    row.seen = UI.Text(row, "meta", "muted")
    row.seen:SetJustifyH("RIGHT")
    row.seen:SetWidth(SEEN_WIDTH)
    row.seen:SetPoint("RIGHT", -6, 0)
    row.cells = {}
    for i = #COLUMNS, 1, -1 do
        local cell = UI.Text(row, font, color)
        cell:SetJustifyH("RIGHT")
        cell:SetWidth(COLUMN_WIDTH)
        cell:SetPoint("RIGHT", i == #COLUMNS and row.seen or row.cells[i + 1], "LEFT", 0, 0)
        row.cells[i] = cell
    end
    row.name = UI.Text(row, font, color)
    row.name:SetPoint("LEFT", 6, 0)
    row.name:SetPoint("RIGHT", row.cells[1], "LEFT", -8, 0)
    if header then
        row:EnableMouse(false)
    else
        row:SetScript("OnEnter", function(self)
            if self.tip then UI.ShowTooltip(self, self.tip.title, self.tip.lines) end
        end)
        row:SetScript("OnLeave", UI.HideTooltip)
        row:SetScript("OnClick", function(self)
            if self.onClick then FC:SafeCall("progress-row", self.onClick) end
        end)
    end
    return row
end

function UI.ProgressPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    local area = UI.ScrollArea(page)
    area:SetAllPoints()
    local content = area.content
    page.area = area
    page.selection = nil -- nil: the whole account; otherwise { [key] = true }

    page.title = L.PROGRESS_TITLE
    -- how progress counts, on the page that shows it (also Settings > General)
    page.mode = UI.Dropdown(content, L.SET_PROGRESS_MODE, {
        { value = "account", text = L.PROGRESS_MODE_ACCOUNT },
        { value = "character", text = L.PROGRESS_MODE_CHARACTER },
    }, function() return FC.Progress:Mode() end, function(value) FC.Progress:SetMode(value) end, MODE_WIDTH)
    page.mode:SetPoint("TOPLEFT", 4, -4)
    page.modeHint = UI.WrappedText(content, "secondary", "muted")
    page.modeHint:SetPoint("TOPLEFT", page.mode, "TOPRIGHT", 16, -2)
    -- shown in the journal's toolbar row (MainWindow places it)
    page.showButton = UI.Button(content, L.PROGRESS_SHOW_FINDS, { autoWidth = true, width = 120, height = 28, onClick = function()
        FC.MainWindow:ShowFinds(page.selection or FC.Progress:AllKeys(), page.selectionLabel)
    end })

    page.chips = UI.Pool(function()
        return UI.Chip(content, "", nil, function(_, _, chip)
            if chip.onClick then FC:SafeCall("progress-chip", chip.onClick) end
        end)
    end, function(chip) chip.onClick = nil end)
    page.tiles = {}
    for i = 1, 5 do page.tiles[i] = newTile(content) end
    -- the quests tile opens their list by name (the Completed quests page)
    local questsTile = page.tiles[3]
    questsTile.link = CreateFrame("Button", nil, questsTile)
    questsTile.link:SetAllPoints()
    questsTile.link.hover = UI.Texture(questsTile.link, "HIGHLIGHT", "text", 0.06)
    questsTile.link.hover:SetAllPoints()
    questsTile.link:SetScript("OnClick", function()
        FC:SafeCall("progress-quests", FC.MainWindow.ShowQuestLog, FC.MainWindow, page.selection and U.CopyTable(page.selection) or FC.Progress:AllKeys())
    end)
    UI.AttachTooltip(questsTile.link, L.NAV_QUESTLOG, L.PROGRESS_QUESTS_TIP)
    questsTile.more = UI.Text(questsTile, "meta", "accent")
    questsTile.more:SetPoint("TOPRIGHT", -8, -10)
    questsTile.more:SetText(L.PROGRESS_QUESTS_LIST)
    questsTile.value:SetPoint("RIGHT", questsTile.more, "LEFT", -4, 0)
    page.headers = UI.Pool(function() return UI.SectionHeader(content) end)
    page.bars = UI.Pool(function() return newBar(content) end)
    page.notes = UI.Pool(function() return UI.WrappedText(content, "secondary", "muted") end)
    page.rows = UI.Pool(function() return newTableRow(content) end, function(row)
        row.onClick, row.tip = nil, nil
    end)
    page.tableHeader = newTableRow(content, true)

    --- "Whole account", a character's name, or "3 characters".
    function page:LabelFor(chars)
        if not self.selection then return L.PROGRESS_WHOLE_ACCOUNT end
        local names = {}
        for _, char in ipairs(chars) do
            if self.selection[char.key] then names[#names + 1] = char.name end
        end
        if #names == 1 then return names[1] end
        return string.format(L.PROGRESS_N_CHARACTERS, #names)
    end

    function page:Toggle(key)
        local selection = self.selection
        if not selection then
            self.selection = { [key] = true }
        elseif selection[key] then
            selection[key] = nil
            if next(selection) == nil then self.selection = nil end
        else
            selection[key] = true
        end
        self:Refresh()
    end

    function page:Refresh()
        local width = area:ContentWidth() - 8
        local chars = FC.Progress:Characters()
        -- characters that are no longer known leave the selection
        if self.selection then
            local known = {}
            for _, char in ipairs(chars) do known[char.key] = true end
            for key in pairs(self.selection) do
                if not known[key] then self.selection[key] = nil end
            end
            if next(self.selection) == nil then self.selection = nil end
        end
        self.selectionLabel = self:LabelFor(chars)
        local perCharacter = FC.Store:PerCharacter()
        local mode = perCharacter and L.PROGRESS_MODE_CHARACTER or L.PROGRESS_MODE_ACCOUNT
        self.subtitle = string.format(L.PROGRESS_SUBTITLE, self.selectionLabel, mode)
        -- per character, other characters' discoveries are only numbers: the
        -- journal lists what the character you play found, nothing else
        local onlyMe = self.selection ~= nil and self.selection[FC.Store.me] == true
        if onlyMe then
            for key in pairs(self.selection) do
                if key ~= FC.Store.me then onlyMe = false break end
            end
        end
        self.showWanted = not perCharacter or onlyMe

        self.chips:ReleaseAll()
        self.headers:ReleaseAll()
        self.bars:ReleaseAll()
        self.notes:ReleaseAll()
        self.rows:ReleaseAll()

        -- how progress counts, and what that means
        self.mode:Refresh()
        self.modeHint:SetWidth(math.max(120, width - MODE_WIDTH - 20))
        self.modeHint:SetText(perCharacter and L.PROGRESS_MODE_HINT_CHARACTER or L.PROGRESS_MODE_HINT_ACCOUNT)
        local modeHeight = math.max(self.mode:GetHeight(), 2 + self.modeHint:GetStringHeight())

        -- who: the whole account or some characters
        local y, x = 4 + math.ceil(modeHeight) + 16, 4
        local accent = Theme:Hex("accent")
        local function chip(text, active, onClick)
            local c = self.chips:Acquire()
            c:SetChip(text, active and accent or nil)
            c.onClick = onClick
            local w = c:GetWidth()
            if x > 4 and x + w > width then
                x = 4
                y = y + 24
            end
            c:SetPoint("TOPLEFT", x, -y)
            x = x + w + 6
        end
        chip(L.PROGRESS_WHOLE_ACCOUNT, self.selection == nil, function()
            self.selection = nil
            self:Refresh()
        end)
        for _, char in ipairs(chars) do
            local level = char.level and ("  " .. U.Colorize(tostring(char.level), Theme:Hex("muted"))) or ""
            chip(coloredName(char) .. level, self.selection ~= nil and self.selection[char.key] == true, function() self:Toggle(char.key) end)
        end
        y = y + 18 + 16

        -- the numbers of the selection
        local data = FC.Progress:Compute(self.selection, true)
        local gap = 10
        local tileWidth = (width - gap * 4) / 5
        local tiles = {
            { data.found, L.PROGRESS_FOUND, "accent" },
            { data.zones, L.PROGRESS_ZONES, "secret" },
            { data.quests, L.PROGRESS_QUESTS, "success" },
            { data.rares, L.PROGRESS_RARES, "warning" },
            { data.flights, L.PROGRESS_FLIGHTS, "accent" },
        }
        for i, tile in ipairs(self.tiles) do
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (i - 1) * (tileWidth + gap) + 4, -y)
            tile:SetWidth(tileWidth)
            tile.value:SetText(U.FormatNumber(tiles[i][1]))
            tile.label:SetText(tiles[i][2]:upper())
            Theme:Paint(tile.bar, tiles[i][3], 0.9)
        end
        y = y + TILE + 22

        local function section(title)
            local h = self.headers:Acquire()
            h:SetText(title)
            h:SetPoint("TOPLEFT", 4, -y)
            h:SetWidth(width)
            y = y + 28
        end
        local function bar(icon, label, value, maxValue, hex, valueText)
            local row = self.bars:Acquire()
            row:SetPoint("TOPLEFT", 4, -y)
            row:SetWidth(width)
            UI.SetIcon(row.icon, icon)
            row.label:SetText(label)
            row.value:SetText(valueText or U.FormatNumber(value))
            local trackWidth = math.max(10, width - 250)
            row.fill:SetWidth(math.max(2, trackWidth * (maxValue > 0 and math.min(1, value / maxValue) or 0)))
            row.fill:SetColorTexture(U.HexToRGB(hex))
            y = y + 24
        end
        local function note(text)
            local line = self.notes:Acquire()
            line:SetPoint("TOPLEFT", 4, -y)
            line:SetWidth(width)
            line:SetText(text)
            y = y + math.max(16, line:GetStringHeight()) + 4
        end

        -- what was found, by category
        section(L.PROGRESS_BY_CATEGORY)
        local maxCount = 0
        for _, count in pairs(data.byType) do maxCount = math.max(maxCount, count) end
        local any = false
        for _, key in ipairs(Categories.order) do
            local count = data.byType[key]
            if count and count > 0 then
                local def = Categories:Get(key)
                bar(def.icon, L[def.label], count, maxCount, def.color)
                any = true
            end
        end
        if not any then note(L.PROGRESS_NOTHING) end
        y = y + 8

        -- milestones, measured for the selection
        if FC.P.milestones.enabled and data.milestones then
            section(L.MILESTONES)
            for _, ms in ipairs(FC.Milestones.list) do
                local current = math.min(data.milestones[ms.stat] or 0, ms.goal)
                local reached = current >= ms.goal
                bar(ms.icon, L[ms.label], current, ms.goal, reached and UI.STATUS.verified.color or Theme:Hex("muted"), current .. " / " .. ms.goal)
            end
            y = y + 8
        end

        -- every character side by side
        section(L.PROGRESS_CHARACTERS)
        local header = self.tableHeader
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", 4, -y)
        header:SetWidth(width)
        header.name:SetText(L.PROGRESS_COL_CHARACTER)
        for i, column in ipairs(COLUMNS) do header.cells[i]:SetText(L["PROGRESS_COL_" .. column:upper()]) end
        header.seen:SetText(L.PROGRESS_COL_SEEN)
        y = y + ROW
        local untracked = false
        for _, char in ipairs(chars) do
            local own = FC.Progress:Compute({ [char.key] = true })
            local row = self.rows:Acquire()
            row:SetPoint("TOPLEFT", 4, -y)
            row:SetWidth(width)
            local selected = self.selection ~= nil and self.selection[char.key] == true
            Theme:Paint(row.bg, "accent", selected and 0.14 or 0)
            local suffix = char.current and ("  " .. U.Colorize(L.PROGRESS_PLAYING, Theme:Hex("accent"))) or ""
            local level = char.level and ("  " .. U.Colorize(string.format(L.TIP_LEVEL, char.level), Theme:Hex("muted"))) or ""
            row.name:SetText(coloredName(char) .. level .. suffix)
            for i, column in ipairs(COLUMNS) do row.cells[i]:SetText(U.FormatNumber(own[column])) end
            row.seen:SetText(char.current and L.PROGRESS_NOW or (char.seen > 0 and U.TimeAgo(char.seen) or L.NEVER))
            local lines = { { L.PROGRESS_ROW_HINT, "muted" } }
            if not char.tracked then table.insert(lines, 1, { L.PROGRESS_NOT_TRACKED, "warning" }) end
            row.tip = { title = char.name, lines = lines }
            row.onClick = function()
                self.selection = { [char.key] = true }
                self:Refresh()
                area:ScrollToTop()
            end
            untracked = untracked or not char.tracked
            y = y + ROW
        end
        if untracked then
            y = y + 6
            note(L.PROGRESS_NOT_TRACKED_NOTE)
        end
        area:SetContentHeight(y + 16)
        FC.MainWindow:PageChanged(self)
    end
    return page
end
