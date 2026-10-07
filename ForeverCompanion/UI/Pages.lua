--[[
  Forever Companion - UI/Pages.lua
  Full-width pages of the journal: Overview (dashboard + recent feed) and
  Statistics (guild activity, categories, zones, milestones), plus the
  reusable empty-state block used by every list page.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local Theme = FC.Theme
local Categories = FC.Categories

------------------------------------------------------------------------
-- Empty state
------------------------------------------------------------------------

function UI.EmptyState(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame.icon = UI.Icon(frame, 48)
    frame.icon:SetAlpha(0.85)
    -- journal style: a painting instead of the icon (empty journal, spyglass)
    frame.art = frame:CreateTexture(nil, "ARTWORK")
    frame.art:SetSize(112, 112)
    frame.art:SetPoint("TOP", 0, 0)
    frame.title = UI.Text(frame, "header", "text")
    frame.title:SetJustifyH("CENTER")
    frame.text = UI.WrappedText(frame, "body", "muted")
    frame.text:SetPoint("TOP", frame.title, "BOTTOM", 0, -8)
    frame.text:SetWidth(360)
    frame.text:SetJustifyH("CENTER")
    frame.button = UI.Button(frame, "", { style = "primary", autoWidth = true, width = 150, height = 28 })
    frame.button:SetPoint("TOP", frame.text, "BOTTOM", 0, -16)
    frame:SetSize(400, 280)
    -- Fits whatever space it is given: the painting when there is room,
    -- else the small icon, else the words alone; centered vertically and
    -- never wider or taller than its frame.
    function frame:Arrange()
        local w, h = self:GetWidth() or 0, self:GetHeight() or 0
        if w <= 0 then w = 400 end
        if h <= 0 then h = 280 end
        self.text:SetWidth(math.max(120, math.min(360, w - 20)))
        self.title:SetWidth(math.max(120, w - 20))
        local words = 20 + 8 + self.text:GetStringHeight() + (self.button:IsShown() and 44 or 0)
        local picture
        if self.hasArt and h >= words + 118 then
            picture = self.art
        elseif h >= words + 62 then
            picture = self.icon
        end
        self.art:SetShown(picture == self.art)
        self.icon:SetShown(picture == self.icon)
        local pictureHeight = picture == self.art and 118 or (picture == self.icon and 62 or 0)
        local top = math.max(0, math.floor((h - words - pictureHeight) / 2))
        self.art:ClearAllPoints()
        self.art:SetPoint("TOP", 0, -top)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("TOP", 0, -(top + 10))
        self.title:ClearAllPoints()
        self.title:SetPoint("TOP", 0, -(top + pictureHeight))
    end
    frame:SetScript("OnSizeChanged", function(self) self:Arrange() end)
    function frame:SetContent(icon, title, text, buttonLabel, onClick, artKey)
        local Skin = FC.Skin
        self.hasArt = (artKey and Skin:Has(artKey) and Skin:SetFile(self.art, Skin.ASSETS[artKey].path)) and true or false
        UI.SetIcon(self.icon, icon)
        self.title:SetText(title and title:upper() or "")
        self.text:SetText(text or "")
        if buttonLabel then
            self.button:Show()
            self.button:SetLabel(buttonLabel)
            self.button:SetScript("OnClick", function() FC:SafeCall("empty", onClick) end)
        else
            self.button:Hide()
        end
        self:Arrange()
    end
    return frame
end

------------------------------------------------------------------------
-- Shared page pieces
------------------------------------------------------------------------

local function statTile(parent)
    local tile = UI.Panel(parent, { bg = "panelAlt", bgAlpha = 1, border = "border", shade = false, skin = "panel", corner = 10 })
    tile:SetHeight(72)
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
    function tile:Set(value, label, role)
        self.value:SetText(U.FormatNumber(value))
        self.label:SetText(label:upper())
        Theme:Paint(self.bar, role or "accent", 0.9)
    end
    return tile
end

local function feedRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(40)
    row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.05)
    row.hover:SetAllPoints()
    row.time = UI.Text(row, "meta", "muted")
    row.time:SetPoint("LEFT", 4, 0)
    row.time:SetWidth(44)
    row.icon = UI.Icon(row, 26)
    row.icon:SetPoint("LEFT", 52, 0)
    row.text = UI.Text(row, "secondary", "text")
    row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
    row.text:SetPoint("RIGHT", -4, 0)
    row.sub = UI.Text(row, "meta", "muted")
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1)
    row.sub:SetPoint("RIGHT", -4, 0)
    row:SetScript("OnClick", function(self)
        if self.id then FC.MainWindow:ShowDiscovery(self.id) end
    end)
    return row
end

local function describeEvent(event)
    local info = UI.Display(event.rec)
    local actor = U.Colorize(U.ShortName(event.actor), Theme:Hex("accent"))
    local title = U.Colorize(U.Escape(info.title), Theme:Hex("text"))
    if event.kind == "verified" then
        return string.format(L.FEED_VERIFIED, actor, title), info
    elseif event.kind == "note" then
        return string.format(L.FEED_NOTE, actor, title), info
    end
    return string.format(L.FEED_DISCOVERED, actor, title), info
end

------------------------------------------------------------------------
-- Overview
------------------------------------------------------------------------

function UI.OverviewPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    local area = UI.ScrollArea(page)
    area:SetAllPoints()
    local content = area.content
    page.area = area

    page.tiles = {}
    for i = 1, 5 do page.tiles[i] = statTile(content) end

    page.feedHeader = UI.SectionHeader(content, L.RECENT_DISCOVERIES)
    page.sideHeader = UI.SectionHeader(content, L.GUILD_ACTIVITY)
    page.msHeader = UI.SectionHeader(content, L.MILESTONES)
    page.feedRows = UI.Pool(function() return feedRow(content) end, function(row) row.id = nil end)
    page.sideRows = UI.Pool(function()
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(20)
        row.left = UI.Text(row, "secondary", "text")
        row.left:SetPoint("LEFT")
        row.left:SetPoint("RIGHT", -56, 0)
        row.right = UI.Text(row, "secondary", "accent")
        row.right:SetPoint("RIGHT")
        return row
    end)
    page.msIcons = UI.Pool(function()
        local frame = CreateFrame("Frame", nil, content)
        frame:SetSize(34, 34)
        frame.icon = UI.Icon(frame, 32)
        frame.icon:SetPoint("CENTER")
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
            if self.ms then
                UI.ShowTooltip(self, L[self.ms.label], { { L[self.ms.desc], "text" }, { self.unlocked and string.format(L.MS_UNLOCKED_AT, U.FormatDate(self.unlocked)) or L.MS_LOCKED, self.unlocked and "success" or "muted" } }, self.ms.icon)
            end
        end)
        frame:SetScript("OnLeave", UI.HideTooltip)
        return frame
    end)

    page.welcome = UI.EmptyState(content)
    -- progress per character: the other characters only appear as numbers here
    page.progressButton = UI.Button(content, L.OVERVIEW_ALL_PROGRESS, { autoWidth = true, width = 120, height = 24, onClick = function()
        FC.MainWindow:Show("progress")
    end })

    function page:Refresh()
        local stats = FC.Store:Stats()
        local width = area:ContentWidth() - 8
        local perCharacter = FC.Store:PerCharacter()
        self.title = L.OVERVIEW_TITLE
        local guild = FC.Compat.GetGuildName()
        if perCharacter then
            self.subtitle = string.format(L.OVERVIEW_SUBTITLE_CHARACTER, U.ShortName(FC.Store.me))
        else
            self.subtitle = guild and string.format(L.OVERVIEW_SUBTITLE_GUILD, guild) or L.OVERVIEW_SUBTITLE
        end
        self.progressButton:Hide()

        local y = 4
        local gap = 10
        local tileWidth = (width - gap * 4) / 5
        local tileData = {
            { stats.total, L.STAT_DISCOVERIES, "accent" },
            { stats.personal, L.STAT_PERSONAL, "success" },
            { stats.guild, L.STAT_GUILD, "warning" },
            { stats.verified, L.STAT_VERIFIED, "success" },
            { stats.zoneCount, L.STAT_ZONES, "secret" },
        }
        if perCharacter then
            -- the journal of the character you play, as if it were the first
            tileData[2] = { stats.character, L.STAT_CHARACTER, "success" }
        end
        for i, tile in ipairs(self.tiles) do
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (i - 1) * (tileWidth + gap) + 4, -y)
            tile:SetWidth(tileWidth)
            tile:Set(tileData[i][1], tileData[i][2], tileData[i][3])
        end
        y = y + 72 + 22

        self.feedRows:ReleaseAll()
        self.sideRows:ReleaseAll()
        self.msIcons:ReleaseAll()

        if stats.total == 0 then
            self.feedHeader:Hide()
            self.sideHeader:Hide()
            self.msHeader:Hide()
            self.welcome:Show()
            self.welcome:ClearAllPoints()
            self.welcome:SetPoint("TOP", content, "TOP", 0, -y - 10)
            self.welcome:SetContent("Interface\\Icons\\INV_Misc_Map_01", L.WELCOME_EMPTY_TITLE, L.WELCOME_EMPTY_TEXT, L.NEW_DISCOVERY, function() FC.Editor:OpenNew() end, "emptyJournal")
            if perCharacter then
                self.progressButton:Show()
                self.progressButton:ClearAllPoints()
                self.progressButton:SetPoint("TOP", content, "TOP", 0, -y - 300)
            end
            area:SetContentHeight(y + 350)
            FC.MainWindow:PageChanged(self)
            return
        end
        self.welcome:Hide()

        local leftWidth = math.floor(width * 0.62)
        local rightX = leftWidth + 24
        local rightWidth = width - rightX

        self.feedHeader:Show()
        self.feedHeader:ClearAllPoints()
        self.feedHeader:SetPoint("TOPLEFT", 4, -y)
        self.feedHeader:SetWidth(leftWidth)
        local feedY = y + 28
        for i, event in ipairs(FC.Store:Feed()) do
            if i > 12 then break end
            local row = self.feedRows:Acquire()
            local text, info = describeEvent(event)
            row:SetPoint("TOPLEFT", 4, -feedY)
            row:SetWidth(leftWidth)
            row.time:SetText(U.ShortAgo(event.ts))
            UI.SetIcon(row.icon, info.icon)
            row.text:SetText(text)
            row.sub:SetText(UI.MetaLine(info))
            row.id = event.rec.id
            feedY = feedY + 42
        end

        self.sideHeader:Show()
        self.sideHeader:ClearAllPoints()
        self.sideHeader:SetPoint("TOPLEFT", rightX, -y)
        self.sideHeader:SetWidth(rightWidth)
        local sideY = y + 28
        local function side(left, right)
            local row = self.sideRows:Acquire()
            row:SetPoint("TOPLEFT", rightX, -sideY)
            row:SetWidth(rightWidth)
            row.left:SetText(left)
            row.right:SetText(right)
            sideY = sideY + 22
        end
        side(L.STAT_TODAY, U.FormatNumber(stats.today))
        side(L.STAT_WEEK, U.FormatNumber(stats.week))
        side(L.STAT_SECRETS, U.FormatNumber(stats.secrets))
        side(L.STAT_RECIPES, U.FormatNumber(stats.recipes))
        side(L.STAT_RARES, U.FormatNumber(stats.rares))
        sideY = sideY + 8
        local label = self.sideRows:Acquire()
        label:SetPoint("TOPLEFT", rightX, -sideY)
        label:SetWidth(rightWidth)
        label.left:SetText(U.Colorize(perCharacter and L.OVERVIEW_ALL_CHARACTERS or L.EXPLORERS, Theme:Hex("muted")))
        label.right:SetText("")
        sideY = sideY + 22
        if perCharacter then
            -- every character's count; their discoveries stay out of this journal
            local counts = FC.Progress:FoundCounts()
            local chars = FC.Progress:Characters()
            for i = 1, math.min(6, #chars) do
                local char = chars[i]
                local name = U.Colorize(U.Escape(char.name), FC.Compat.ClassColorHex(char.class) or Theme:Hex("text"))
                if char.current then name = name .. " " .. U.Colorize(L.YOU_SUFFIX, Theme:Hex("muted")) end
                side(name, U.FormatNumber(counts.byChar[char.key] or 0))
            end
            side(L.PROGRESS_WHOLE_ACCOUNT, U.FormatNumber(counts.total))
            self.progressButton:Show()
            self.progressButton:ClearAllPoints()
            self.progressButton:SetPoint("TOPLEFT", rightX, -(sideY + 4))
            sideY = sideY + 34
        else
            for i = 1, math.min(5, #stats.topExplorers) do
                local explorer = stats.topExplorers[i]
                side(U.ShortName(explorer.name), U.FormatNumber(explorer.count))
            end
        end

        if FC.P.milestones.enabled then
            sideY = sideY + 12
            self.msHeader:Show()
            self.msHeader:ClearAllPoints()
            self.msHeader:SetPoint("TOPLEFT", rightX, -sideY)
            self.msHeader:SetWidth(rightWidth)
            sideY = sideY + 28
            local perRow = math.max(1, math.floor(rightWidth / 38))
            for i, ms in ipairs(FC.Milestones.list) do
                local icon = self.msIcons:Acquire()
                local col, line = (i - 1) % perRow, math.floor((i - 1) / perRow)
                icon:SetPoint("TOPLEFT", rightX + col * 38, -(sideY + line * 38))
                UI.SetIcon(icon.icon, ms.icon)
                icon.ms = ms
                icon.unlocked = FC.Milestones:UnlockedAt(ms.id)
                icon.icon:SetDesaturated(not icon.unlocked)
                icon.icon:SetAlpha(icon.unlocked and 1 or 0.35)
            end
            sideY = sideY + math.ceil(#FC.Milestones.list / perRow) * 38
        else
            self.msHeader:Hide()
        end
        area:SetContentHeight(math.max(feedY, sideY) + 16)
        FC.MainWindow:PageChanged(self)
    end
    return page
end

------------------------------------------------------------------------
-- Statistics
------------------------------------------------------------------------

function UI.StatisticsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    local area = UI.ScrollArea(page)
    area:SetAllPoints()
    local content = area.content
    page.area = area

    page.title = L.NAV_STATISTICS
    page.subtitle = L.STATS_SUBTITLE

    page.headers = UI.Pool(function() return UI.SectionHeader(content) end)
    page.bars = UI.Pool(function()
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(22)
        row.icon = UI.Icon(row, 16)
        row.icon:SetPoint("LEFT")
        row.label = UI.Text(row, "secondary", "text")
        row.label:SetPoint("LEFT", 24, 0)
        row.label:SetWidth(150)
        row.track = UI.Texture(row, "BACKGROUND", "panelAlt", 1)
        row.track:SetPoint("LEFT", 180, 0)
        row.track:SetPoint("RIGHT", -56, 0)
        row.track:SetHeight(8)
        row.fill = row:CreateTexture(nil, "ARTWORK")
        row.fill:SetTexture(FC.C.WHITE)
        row.fill:SetPoint("LEFT", row.track, "LEFT")
        row.fill:SetHeight(8)
        row.value = UI.Text(row, "secondary", "muted")
        row.value:SetPoint("RIGHT")
        return row
    end)
    page.tiles = {}
    for i = 1, 4 do page.tiles[i] = statTile(content) end

    function page:Refresh()
        local stats = FC.Store:Stats()
        local width = area:ContentWidth() - 8
        self.headers:ReleaseAll()
        self.bars:ReleaseAll()
        local y = 4
        local gap = 10
        local tileWidth = (width - gap * 3) / 4
        local data = {
            { stats.today, L.STAT_TODAY, "accent" },
            { stats.week, L.STAT_WEEK, "accent" },
            { stats.favorites, L.STAT_FAVORITES, "warning" },
            { stats.private, L.STAT_PRIVATE, "muted" },
        }
        for i, tile in ipairs(self.tiles) do
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (i - 1) * (tileWidth + gap) + 4, -y)
            tile:SetWidth(tileWidth)
            tile:Set(data[i][1], data[i][2], data[i][3])
        end
        y = y + 72 + 22

        local function section(title)
            local h = self.headers:Acquire()
            h:SetText(title)
            h:SetPoint("TOPLEFT", 4, -y)
            h:SetWidth(width)
            y = y + 28
        end
        local function bar(icon, label, value, maxValue, hex)
            local row = self.bars:Acquire()
            row:SetPoint("TOPLEFT", 4, -y)
            row:SetWidth(width)
            UI.SetIcon(row.icon, icon)
            row.label:SetText(label)
            row.value:SetText(U.FormatNumber(value))
            local trackWidth = math.max(10, width - 230)
            row.fill:SetWidth(math.max(2, trackWidth * (maxValue > 0 and value / maxValue or 0)))
            row.fill:SetColorTexture(U.HexToRGB(hex))
            y = y + 24
        end

        section(L.STATS_BY_CATEGORY)
        local maxCount = 0
        for _, count in pairs(stats.byType) do maxCount = math.max(maxCount, count) end
        local any = false
        for _, key in ipairs(Categories.order) do
            local count = stats.byType[key]
            if count and count > 0 then
                local def = Categories:Get(key)
                bar(def.icon, L[def.label], count, maxCount, def.color)
                any = true
            end
        end
        if not any then y = y + 4 end

        section(L.STATS_EXPLORERS)
        local top = stats.topExplorers
        local maxExplorer = top[1] and top[1].count or 0
        for i = 1, math.min(10, #top) do
            bar(FC.C.GUILD_ICON, U.ShortName(top[i].name), top[i].count, maxExplorer, Theme:Hex("accent"))
        end
        y = y + 8

        if FC.P.milestones.enabled then
            section(L.MILESTONES)
            local progress = FC.Milestones:Progress()
            for _, ms in ipairs(FC.Milestones.list) do
                local current = math.min(progress[ms.stat] or 0, ms.goal)
                local unlocked = FC.Milestones:UnlockedAt(ms.id)
                bar(ms.icon, L[ms.label], current, ms.goal, unlocked and UI.STATUS.verified.color or Theme:Hex("muted"))
            end
        end
        area:SetContentHeight(y + 16)
        FC.MainWindow:PageChanged(self)
    end
    return page
end
