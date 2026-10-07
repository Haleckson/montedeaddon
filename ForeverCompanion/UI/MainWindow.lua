--[[
  Forever Companion - UI/MainWindow.lua
  The Discovery Journal window. Navigation on the left (brand, then the
  pages); on the right each page's illustrated header, a row with search,
  the page's own controls and "New discovery", the filter chips, then the
  page itself (card list + detail panel, or a full page). A footer shows the
  sync status; the window resizes from its corner.

  It reads everything through the Store and Query and reacts to bus
  messages with a coalesced refresh, so heavy sync bursts cost one redraw.
  The journal style paints it as leather, brass and parchment (UI/Skin.lua);
  the flat style keeps the same layout in theme colors.
]]

local _, FC = ...

local MainWindow = FC:NewModule("MainWindow")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C
local Theme = FC.Theme
local Categories = FC.Categories
local Skin = FC.Skin

local SIDEBAR_WIDTH = 200
local FOOTER_HEIGHT = 22
local TOOLBAR_HEIGHT = 30
local GAP = 10
local CORNER = 30                     -- painted frame corners (UI units)
local FLAT_EDGE = 8
local MIN_W, MIN_H, MAX_W, MAX_H = 860, 500, 1800, 1200
local ICON = "Interface\\Icons\\"

MainWindow.PAGES = {
    { key = "overview", label = "NAV_OVERVIEW", icon = ICON .. "INV_Misc_Book_09", kind = "overview", section = "NAVSECTION_JOURNAL" },
    { key = "recent", label = "NAV_RECENT", icon = ICON .. "INV_Misc_PocketWatch_01", kind = "list", spec = { sort = "recent" } },
    { key = "map", label = "NAV_MAP", icon = ICON .. "INV_Misc_Map_01", kind = "action", action = "OpenMap" },
    { key = "zone", label = "NAV_ZONE_GUIDE", icon = ICON .. "INV_Misc_Spyglass_02", kind = "action", action = "ToggleZoneGuide" },
    { key = "quests", label = "NAV_QUESTS", icon = ICON .. "INV_Misc_Note_02", kind = "list", group = "quests", section = "NAVSECTION_CATEGORIES" },
    -- every quest the game says a character completed, also without the journal watching
    { key = "questlog", label = "NAV_QUESTLOG", icon = ICON .. "INV_Scroll_05", kind = "questlog" },
    { key = "npcs", label = "NAV_NPCS", icon = ICON .. "INV_Misc_Head_Human_01", kind = "list", group = "npcs" },
    { key = "rares", label = "NAV_RARES", icon = ICON .. "INV_Misc_Head_Dragon_01", kind = "list", group = "rares" },
    { key = "bestiary", label = "NAV_BESTIARY", icon = ICON .. "Ability_Hunter_Pet_Wolf", kind = "list", group = "bestiary" },
    { key = "vendors", label = "NAV_VENDORS", icon = ICON .. "INV_Misc_Bag_10", kind = "list", group = "vendors" },
    { key = "recipes", label = "NAV_RECIPES", icon = ICON .. "INV_Scroll_04", kind = "list", group = "recipes" },
    { key = "items", label = "NAV_ITEMS", icon = ICON .. "INV_Misc_Gem_01", kind = "list", group = "items" },
    { key = "secrets", label = "NAV_SECRETS", icon = ICON .. "INV_Misc_QuestionMark", kind = "list", group = "secrets" },
    { key = "dungeons", label = "NAV_DUNGEONS", icon = ICON .. "INV_Misc_Key_03", kind = "list", group = "dungeons" },
    { key = "professions", label = "NAV_PROFESSIONS", icon = ICON .. "Trade_BlackSmithing", kind = "list", group = "professions", professionChips = true },
    { key = "guild", label = "NAV_GUILD", icon = C.GUILD_ICON, kind = "list", spec = { scope = "guild" }, section = "NAVSECTION_COLLECTIONS" },
    { key = "favorites", label = "NAV_FAVORITES", icon = C.FAVORITE_ICON, kind = "list", spec = { favorites = true }, favoriteChips = true },
    { key = "notes", label = "NAV_NOTES", icon = ICON .. "INV_Misc_Note_01", kind = "list", group = "notes" },
    { key = "archived", label = "NAV_ARCHIVED", icon = ICON .. "INV_Crate_01", kind = "list", spec = { archived = "only" } },
    { key = "progress", label = "NAV_PROGRESS", icon = ICON .. "Spell_Holy_SurgeOfLight", kind = "progress", section = "NAVSECTION_INSIGHTS" },
    { key = "statistics", label = "NAV_STATISTICS", icon = ICON .. "INV_Misc_Spyglass_03", kind = "stats" },
    { key = "biography", label = "NAV_BIOGRAPHY", icon = ICON .. "INV_Misc_Book_07", kind = "bio" },
}

MainWindow.FAVORITE_GROUPS = { "raidprep", "professions", "leveling", "secrets", "later" }

local pageByKey = {}
for _, page in ipairs(MainWindow.PAGES) do pageByKey[page.key] = page end

------------------------------------------------------------------------
-- Construction
------------------------------------------------------------------------

local function savePosition()
    local frame = MainWindow.frame
    local point, _, relPoint, x, y = frame:GetPoint(1)
    local w = FC.P.appearance.window
    w.point, w.relPoint, w.x, w.y = point, relPoint, x, y
end

function MainWindow:Build()
    if self.frame then return self.frame end
    local frame = UI.Panel(UIParent, { name = "ForeverCompanionMainWindow", strata = "HIGH", bg = "bg", skin = "window", corner = CORNER })
    self.frame = frame
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    elseif frame.SetMinResize then
        frame:SetMinResize(MIN_W, MIN_H)
    end
    tinsert(UISpecialFrames, "ForeverCompanionMainWindow")
    frame:Hide()

    self:BuildSidebar()
    self:BuildHeader()
    self:BuildToolbar()
    self:BuildContent()
    self:BuildFooter()
    self:ApplyGeometry()
    frame:HookScript("OnSizeChanged", function() self:Layout() end)

    frame:SetScript("OnShow", function()
        if self.dirty then self:Refresh() end
        FC.Compat.PlaySoundKit("IG_SPELLBOOK_OPEN")
    end)
    frame:SetScript("OnHide", function()
        UI.CloseMenu()
        UI.HideTooltip()
        FC.Compat.PlaySoundKit("IG_SPELLBOOK_CLOSE")
    end)
    return frame
end

function MainWindow:BuildSidebar()
    local frame = self.frame
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar.bg = UI.Texture(sidebar, "BACKGROUND", "panel", 0.6)
    sidebar.bg:SetAllPoints()
    sidebar.line = UI.Texture(sidebar, "ARTWORK", "border", 1)
    sidebar.line:SetPoint("TOPRIGHT")
    sidebar.line:SetPoint("BOTTOMRIGHT")
    sidebar.line:SetWidth(1)
    self.sidebar = sidebar

    -- brand: the window is dragged by it (and by the page header)
    local brand = CreateFrame("Frame", nil, sidebar)
    brand:SetPoint("TOPLEFT")
    brand:SetPoint("TOPRIGHT")
    brand:SetHeight(58)
    brand.logo = brand:CreateTexture(nil, "ARTWORK")
    brand.logo:SetTexture(C.MEDIA .. "Logo")
    brand.logo:SetSize(36, 36)
    brand.logo:SetPoint("LEFT", 8, 0)
    brand.title = UI.Text(brand, "cardTitle", "text")
    brand.title:SetPoint("TOPLEFT", brand.logo, "TOPRIGHT", 8, -2)
    brand.title:SetPoint("RIGHT", -6, 0)
    brand.title:SetText("Forever Companion")
    brand.subtitle = UI.Text(brand, "meta", "accent")
    brand.subtitle:SetPoint("BOTTOMLEFT", brand.logo, "BOTTOMRIGHT", 8, 1)
    brand.subtitle:SetPoint("RIGHT", -6, 0)
    brand.subtitle:SetText(L.DISCOVERY_JOURNAL:upper())
    brand.rule = CreateFrame("Frame", nil, brand)
    brand.rule:SetPoint("BOTTOMLEFT", 6, -2)
    brand.rule:SetPoint("BOTTOMRIGHT", -8, -2)
    brand.rule:SetHeight(8)
    brand.rule.flat = UI.Divider(brand.rule, "border")
    brand.rule.flat:SetPoint("LEFT")
    brand.rule.flat:SetPoint("RIGHT")
    brand.rule.art = Skin:Divider(brand.rule, { layer = "ARTWORK" })
    UI.MakeMovable(frame, brand, savePosition)
    self.brand = brand

    local area = UI.ScrollArea(sidebar)
    area:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -8)
    area:SetPoint("BOTTOMRIGHT", -2, 6)
    self.navArea = area
    local content = area.content
    self.navItems = {}
    self.navSections = {}
    for _, page in ipairs(self.PAGES) do
        if page.section then
            local label = UI.Text(content, "meta", "muted")
            label:SetText(L[page.section]:upper())
            self.navSections[page.key] = label
        end
        self.navItems[page.key] = UI.NavItem(content, page.icon, L[page.label], function()
            if page.kind == "action" then
                self[page.action](self)
            else
                self:SelectPage(page.key)
            end
        end)
    end
    self:LayoutNav()
end

--- Navigation rows grow with the font size, so labels never overlap.
function MainWindow:LayoutNav()
    if not self.navItems then return end
    local content = self.navArea.content
    local itemHeight = math.max(28, math.floor((tonumber(FC.P.fonts.size) or 12) + 16))
    local y = 0
    for _, page in ipairs(self.PAGES) do
        local label = self.navSections[page.key]
        if label then
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", 14, -(y + 10))
            label:SetPoint("RIGHT", content, "RIGHT", -8, 0)
            y = y + 30
        end
        local item = self.navItems[page.key]
        item:SetHeight(itemHeight)
        item:ClearAllPoints()
        item:SetPoint("TOPLEFT", 0, -y)
        item:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        y = y + itemHeight + 1
    end
    self.navArea:SetContentHeight(y + 8)
end

function MainWindow:BuildHeader()
    local frame = self.frame
    local header = CreateFrame("Frame", nil, frame)
    header.flat = UI.Texture(header, "BACKGROUND", "panel", 1, -6)
    header.flat:SetAllPoints()
    header.flatLine = UI.Divider(header, "border")
    header.flatLine:SetPoint("BOTTOMLEFT")
    header.flatLine:SetPoint("BOTTOMRIGHT")
    -- journal style: the page's painting, darkened on the left for the
    -- title and toward the bottom so it settles into the window
    header.art = Skin:Art(header, { layer = "BACKGROUND", sublevel = -4 })
    header.shade = Skin:Shade(header, "HORIZONTAL", 0.05, 0.03, 0.02, 0.85, "BACKGROUND", -2)
    header.shade:SetPoint("TOPLEFT")
    header.shade:SetPoint("BOTTOMLEFT")
    header.fade = Skin:Shade(header, "VERTICAL", 0.05, 0.03, 0.02, 0.7, "BACKGROUND", -1)
    header.fade:SetPoint("BOTTOMLEFT")
    header.fade:SetPoint("BOTTOMRIGHT")
    header.fade:SetHeight(26)
    header.rule = CreateFrame("Frame", nil, header)
    header.rule:SetPoint("BOTTOMLEFT", 0, -5)
    header.rule:SetPoint("BOTTOMRIGHT", 0, -5)
    header.rule:SetHeight(10)
    header.rule.art = Skin:Divider(header.rule, { layer = "ARTWORK" })

    header.title = UI.Text(header, "title", "text")
    header.subtitle = UI.Text(header, "body", "muted")
    header.close = UI.IconButton(header, "Interface\\Buttons\\UI-StopButton", 24, L.CLOSE, function() self:Hide() end)
    header.close:SetPoint("TOPRIGHT", -8, -8)
    header.settings = UI.IconButton(header, "Interface\\Buttons\\UI-OptionsButton", 24, L.SETTINGS, function() FC.SettingsWindow:Toggle() end)
    header.settings:SetPoint("RIGHT", header.close, "LEFT", -4, 0)
    -- the look, one click away: the painted journal or a flat color theme
    header.look = UI.IconButton(header, "Interface\\Icons\\INV_Misc_Gem_Variety_01", 24, nil, function(button) self:OpenLookMenu(button) end)
    header.look.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    header.look:SetPoint("RIGHT", header.settings, "LEFT", -4, 0)
    UI.AttachTooltip(header.look, L.LOOK_BUTTON, L.LOOK_BUTTON_TIP)
    -- a dark plate keeps the buttons readable over bright paintings
    header.plate = header:CreateTexture(nil, "ARTWORK", nil, -1)
    header.plate:SetTexture(C.WHITE)
    header.plate:SetColorTexture(0.05, 0.03, 0.02, 0.6)
    header.plate:SetPoint("TOPLEFT", header.look, "TOPLEFT", -4, 4)
    header.plate:SetPoint("BOTTOMRIGHT", header.close, "BOTTOMRIGHT", 4, -4)
    UI.MakeMovable(frame, header, savePosition)
    self.header = header
end

function MainWindow:BuildToolbar()
    local bar = CreateFrame("Frame", nil, self.frame)
    bar:SetHeight(TOOLBAR_HEIGHT)
    bar.search = UI.SearchBox(bar, L.SEARCH_PLACEHOLDER, function(text)
        self.searchText = text
        if self.page and self.page.kind == "questlog" then
            -- the completed quests are searched where they are listed
            self.questLog:SetSearch(text)
        elseif self.page and self.page.kind ~= "list" and text ~= "" then
            self:SelectPage("recent", true)
        else
            self:RefreshList()
        end
    end)
    UI.AttachTooltip(bar.search, L.SEARCH_HELP_TITLE, L.SEARCH_HELP)
    bar.new = UI.Button(bar, L.NEW_DISCOVERY, { style = "primary", height = 28, autoWidth = true, width = 130, onClick = function() FC.Editor:OpenNew(self:DefaultTypeForPage()) end })
    bar.density = UI.IconButton(bar, "Interface\\Buttons\\UI-GuildButton-PublicNote-Up", 26, L.TOGGLE_DENSITY, function()
        FC.Config:Set("appearance.cardDensity", FC.P.appearance.cardDensity == "compact" and "comfortable" or "compact")
    end)
    bar.filter = UI.Button(bar, L.FILTERS, { width = 90, height = 28, autoWidth = true, icon = "Interface\\ChatFrame\\ChatFrameExpandArrow", onClick = function(button) self:OpenFilterMenu(button) end })
    bar.sort = UI.Dropdown(bar, nil, function()
        local items = {}
        for _, key in ipairs(FC.Query.SORTS) do items[#items + 1] = { value = key, text = L["SORT_" .. key:upper()] } end
        return items
    end, function() return FC.P.journal.sort end, function(value)
        FC.Config:Set("journal.sort", value)
    end, 150)
    bar.map = UI.Button(bar, L.OPEN_MAP, { autoWidth = true, width = 100, height = 28, onClick = function() self:OpenMap() end })
    self.toolbar = bar
end

function MainWindow:BuildContent()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame)
    self.content = content

    -- list view: the cards (filter chips above them) and the detail panel
    local listView = CreateFrame("Frame", nil, content)
    listView:SetAllPoints()
    listView:SetScript("OnSizeChanged", function()
        self:FitDetail()
        if self.page and self.page.kind == "list" then self:RenderChips() end
    end)
    self.listView = listView

    self.chipBar = CreateFrame("Frame", nil, listView)
    self.chipBar:SetPoint("TOPLEFT")
    self.chipBar:SetHeight(1)
    self.chipPool = UI.Pool(function()
        return UI.Chip(self.chipBar, "", nil, function(_, _, chip)
            if chip.onClick then FC:SafeCall("filter-chip", chip.onClick) end
        end)
    end, function(chip) chip.onClick = nil end)

    self.detail = UI.DetailPanel(listView)
    self.detail:SetPoint("TOPRIGHT")
    self.detail:SetPoint("BOTTOMRIGHT")

    self.splitter = CreateFrame("Frame", nil, listView)
    self.splitter:SetWidth(8)
    self.splitter:SetPoint("TOPRIGHT", self.detail, "TOPLEFT", -1, 0)
    self.splitter:SetPoint("BOTTOMRIGHT", self.detail, "BOTTOMLEFT", -1, 0)
    self.splitter:EnableMouse(true)
    self.splitter.hl = UI.Texture(self.splitter, "HIGHLIGHT", "accent", 0.35)
    self.splitter.hl:SetPoint("TOP")
    self.splitter.hl:SetPoint("BOTTOM")
    self.splitter.hl:SetWidth(2)
    self.splitter:SetScript("OnMouseDown", function()
        self.splitter.dragging = true
        self.splitter.startX = GetCursorPosition() / self.frame:GetEffectiveScale()
        self.splitter.startWidth = self.detail:GetWidth()
        self.splitter:SetScript("OnUpdate", function()
            local x = GetCursorPosition() / self.frame:GetEffectiveScale()
            local width = U.Clamp(self.splitter.startWidth + (self.splitter.startX - x), 280, math.max(300, self.listView:GetWidth() - 360))
            self.detail:SetWidth(width)
        end)
    end)
    self.splitter:SetScript("OnMouseUp", function()
        self.splitter:SetScript("OnUpdate", nil)
        FC.P.appearance.window.detailWidth = math.floor(self.detail:GetWidth())
        self.detail:Refresh()
    end)

    self.chipBar:SetPoint("RIGHT", self.splitter, "LEFT", -4, 0)

    -- the cards lie on a sheet of parchment (journal style)
    self.listPanel = UI.Panel(listView, { bg = "panel", bgAlpha = 0, border = false, shade = false, skin = "panel", corner = 12 })
    self.listPanel:SetPoint("TOPLEFT", self.chipBar, "BOTTOMLEFT", 0, -6)
    self.listPanel:SetPoint("BOTTOMRIGHT", self.splitter, "BOTTOMLEFT", -4, 0)
    self.list = UI.CardList(self.listPanel, self)

    self.emptyState = UI.EmptyState(listView)
    self.emptyState:SetPoint("TOPLEFT", self.listPanel, "TOPLEFT", 10, -10)
    self.emptyState:SetPoint("BOTTOMRIGHT", self.listPanel, "BOTTOMRIGHT", -10, 10)

    -- full-width pages
    self.overview = UI.OverviewPage(content)
    self.overview:SetAllPoints()
    self.statistics = UI.StatisticsPage(content)
    self.statistics:SetAllPoints()
    self.biography = UI.BiographyPage(content)
    self.biography:SetAllPoints()
    self.progressPage = UI.ProgressPage(content)
    self.progressPage:SetAllPoints()
    self.questLog = UI.QuestLogPage(content)
    self.questLog:SetAllPoints()
    -- full pages are laid out for a width: they use the whole of it while
    -- there is nothing to scroll (their right edge then lines up with the
    -- toolbar's), and lay out again when it changes (a resize)
    for _, page in ipairs({ self.overview, self.statistics, self.biography, self.progressPage }) do
        page.area:AutoGutter(function()
            U.Debounce("fullpage:" .. tostring(page), 0.1, function()
                if page:IsVisible() then page:Refresh() end
            end)
        end)
    end

    -- the full pages' own controls live in the toolbar row
    local bar = self.toolbar
    self.progressPage.showButton:SetParent(bar)
    self.biography.character:SetParent(bar)
    self.questLog.sortBox:SetParent(bar)
    self.questLog.rescan:SetParent(bar)
    self.pageActions = {
        list = { bar.sort, bar.filter, bar.density },
        overview = { bar.map },
        progress = { self.progressPage.showButton },
        bio = { self.biography.character },
        questlog = { self.questLog.sortBox, self.questLog.rescan },
        stats = {},
    }
end

function MainWindow:BuildFooter()
    local footer = CreateFrame("Frame", nil, self.frame)
    footer:SetHeight(FOOTER_HEIGHT)
    footer.bg = UI.Texture(footer, "BACKGROUND", "panel", 1)
    footer.bg:SetAllPoints()
    footer.line = UI.Divider(footer, "border")
    footer.line:SetPoint("TOPLEFT")
    footer.line:SetPoint("TOPRIGHT")
    footer.dot = footer:CreateTexture(nil, "ARTWORK")
    footer.dot:SetTexture(C.WHITE)
    footer.dot:SetSize(7, 7)
    footer.dot:SetPoint("LEFT", 8, 0)
    footer.status = UI.Text(footer, "meta", "muted")
    footer.status:SetPoint("LEFT", footer.dot, "RIGHT", 8, 0)
    footer.status:SetPoint("RIGHT", -24, 0)
    self.footer = footer

    local grip = CreateFrame("Button", nil, self.frame)
    grip:SetSize(16, 16)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() self.frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        self.frame:StopMovingOrSizing()
        local w = FC.P.appearance.window
        w.width, w.height = math.floor(self.frame:GetWidth()), math.floor(self.frame:GetHeight())
        savePosition()
        self:Refresh()
    end)
    self.grip = grip
end

------------------------------------------------------------------------
-- Layout
------------------------------------------------------------------------

--- The page header: tall enough for the painting, never eating the page.
function MainWindow:HeaderHeight()
    if not self.frame.fcPainted then return 58 end
    return U.Clamp(math.floor((self.frame:GetHeight() or 660) * 0.18), 84, 124)
end

function MainWindow:Layout()
    local frame = self.frame
    if not frame then return end
    local painted = frame.fcPainted
    local edge = painted and Skin:FrameInset(CORNER) or FLAT_EDGE
    local bottom = edge + FOOTER_HEIGHT + 6
    local mainX = edge + SIDEBAR_WIDTH + GAP

    self.sidebar:ClearAllPoints()
    self.sidebar:SetPoint("TOPLEFT", edge, -edge)
    self.sidebar:SetPoint("BOTTOMLEFT", edge, bottom)

    local header = self.header
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", mainX, -edge)
    header:SetPoint("TOPRIGHT", -edge, -edge)
    header:SetHeight(self:HeaderHeight())

    self.toolbar:ClearAllPoints()
    self.toolbar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    self.toolbar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -10)

    self.content:ClearAllPoints()
    self.content:SetPoint("TOPLEFT", self.toolbar, "BOTTOMLEFT", 0, -8)
    self.content:SetPoint("BOTTOMRIGHT", -edge, bottom)

    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", edge, edge)
    self.footer:SetPoint("BOTTOMRIGHT", -edge, edge)
    self.grip:ClearAllPoints()
    if painted then
        self.grip:SetPoint("BOTTOMRIGHT", -(edge - 6), edge - 6)
    else
        self.grip:SetPoint("BOTTOMRIGHT", -3, 3)
    end

    self:StyleChrome()
    self:LayoutToolbar()
    self:FitDetail()
end

--- Painted or flat dress for the window's own parts.
function MainWindow:StyleChrome()
    local painted = self.frame.fcPainted
    local header = self.header
    local sidebar = self.sidebar
    if painted then
        Theme:Forget(sidebar.bg)
        sidebar.bg:SetColorTexture(0, 0, 0, 0.28)
        Theme:Paint(sidebar.line, "accent", 0.3)
    else
        Theme:Paint(sidebar.bg, "panel", 0.6)
        Theme:Paint(sidebar.line, "border", 1)
    end
    self.brand.rule.flat:SetShown(not painted)
    self.brand.rule.art:SetShown(painted and Skin:Has("divider"))
    header.flat:SetShown(not painted)
    header.flatLine:SetShown(not painted)
    header.art:SetShown(painted)
    header.shade:SetShown(painted)
    header.fade:SetShown(painted)
    header.plate:SetShown(painted)
    header.rule.art:SetShown(painted and Skin:Has("divider"))
    header.shade:SetWidth(math.max(120, (header:GetWidth() or 600) * 0.62))
    if painted then
        Theme:Paint(header.subtitle, "text", 0.82)
    else
        Theme:Paint(header.subtitle, "muted")
    end
    -- title and subtitle in the calm left part; the title clears the buttons
    local h = self:HeaderHeight()
    header.title:ClearAllPoints()
    header.title:SetPoint("LEFT", painted and 20 or 16, painted and math.max(8, math.floor(h * 0.1)) or 9)
    header.title:SetPoint("RIGHT", -112, 0)
    header.subtitle:ClearAllPoints()
    header.subtitle:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -6)
    header.subtitle:SetPoint("RIGHT", -24, 0)
    local footer = self.footer
    footer.bg:SetShown(not painted)
    footer.line:SetShown(not painted)
    self.listPanel:SetAlpha(1)
    local pad = (painted and self.listPanel.fcPainted) and 8 or 0
    self.list:ClearAllPoints()
    self.list:SetPoint("TOPLEFT", pad, -pad)
    self.list:SetPoint("BOTTOMRIGHT", -pad, pad)
    self:SetHeaderArt()
end

--- The current page's painting in the header.
function MainWindow:SetHeaderArt()
    if not self.header or not self.frame.fcPainted then return end
    local key = self.page and self.page.key or "overview"
    local path, focusY = Skin:HeaderPath(key)
    self.header.art:SetArt(path, 0.5, focusY)
end

--- The look, one click from the journal: the painted expedition journal or
--- a flat color theme (Settings > Appearance has the rest).
function MainWindow:OpenLookMenu(anchor)
    local flat = FC.P.appearance.style == "flat"
    local items = {
        { text = L.SET_STYLE_JOURNAL, checked = not flat, onClick = function() FC.Config:Set("appearance.style", "journal") end },
        { divider = true },
        { text = L.LOOK_FLAT, isTitle = true },
    }
    for _, name in ipairs(Theme:List()) do
        items[#items + 1] = {
            text = Theme:IsPreset(name) and name or (name .. "  (" .. L.CUSTOM .. ")"),
            checked = flat and FC.P.appearance.theme == name,
            onClick = function()
                FC.Config:Set("appearance.style", "flat")
                Theme:Select(name)
            end,
        }
    end
    items[#items + 1] = { divider = true }
    items[#items + 1] = { text = L.LOOK_MORE, onClick = function() FC.SettingsWindow:Show("appearance") end }
    UI.OpenMenu(anchor, items, 220)
end

--- Search on the left; on the right "New discovery" and the page's own
--- controls. The search box shrinks first, the sort list next.
function MainWindow:LayoutToolbar()
    local bar = self.toolbar
    if not bar then return end
    local kind = self.page and self.page.kind or "overview"
    for _, list in pairs(self.pageActions) do
        for _, widget in ipairs(list) do widget:Hide() end
    end
    local actions = self.pageActions[kind] or {}
    local width = bar:GetWidth()
    if not width or width <= 0 then width = 640 end
    bar.new:ClearAllPoints()
    bar.new:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    local right = bar.new:GetWidth() + 8
    local visible = {}
    for _, widget in ipairs(actions) do
        if widget ~= self.progressPage.showButton or self.progressPage.showWanted then
            visible[#visible + 1] = widget
        end
    end
    local used = right
    for _, widget in ipairs(visible) do used = used + widget:GetWidth() + 6 end
    if used + 220 > width then bar.sort:SetWidth(120) else bar.sort:SetWidth(150) end
    for _, widget in ipairs(visible) do
        widget:Show()
        widget:ClearAllPoints()
        widget:SetPoint("RIGHT", bar, "RIGHT", -right, 0)
        right = right + widget:GetWidth() + 6
    end
    bar.search:ClearAllPoints()
    bar.search:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.search:SetPoint("RIGHT", bar, "RIGHT", -(right + 4), 0)
end

function MainWindow:ApplyGeometry()
    local frame = self.frame
    if not frame then return end
    local appearance = FC.P.appearance
    local w = appearance.window
    local scale = U.Clamp(appearance.scale or 1, 0.6, 1.6)
    frame:SetScale(scale)
    frame:SetAlpha(U.Clamp(appearance.alpha or 1, 0.3, 1))
    -- never larger than the screen at this scale: every part stays reachable
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if not screenW or screenW <= 0 then screenW = 1920 end
    if not screenH or screenH <= 0 then screenH = 1080 end
    local maxW = math.max(480, math.floor(screenW / scale) - 16)
    local maxH = math.max(360, math.floor(screenH / scale) - 16)
    local minW, minH = math.min(MIN_W, maxW), math.min(MIN_H, maxH)
    maxW, maxH = math.min(MAX_W, maxW), math.min(MAX_H, maxH)
    if frame.SetResizeBounds then frame:SetResizeBounds(minW, minH, maxW, maxH) end
    frame:SetSize(U.Clamp(w.width or 1100, minW, maxW), U.Clamp(w.height or 660, minH, maxH))
    frame:ClearAllPoints()
    if w.point then
        frame:SetPoint(w.point, UIParent, w.relPoint or w.point, w.x or 0, w.y or 0)
    else
        frame:SetPoint("CENTER", 0, 30)
    end
    self:Layout()
end

--- Gives the detail panel its saved width, but never so much that the card
--- list gets squeezed or the panel reaches past the window's left side
--- (a wide panel saved in a large window, then the window made smaller).
function MainWindow:FitDetail()
    if not self.detail then return end
    local width = U.Clamp(FC.P.appearance.window.detailWidth or 340, 280, 700)
    local total = self.listView and self.listView:GetWidth() or 0
    if total > 0 then
        width = math.max(260, math.min(width, math.floor(total - 340)))
    end
    self.detail:SetWidth(width)
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function MainWindow:OnEnable()
    local function dirty() self:MarkDirty() end
    for _, message in ipairs({ "DISCOVERY_ADDED", "DISCOVERY_UPDATED", "DISCOVERY_REMOVED", "DISCOVERY_STATE", "STORE_RESET", "SYNC_STATE", "PROFILE_CHANGED" }) do
        FC.Bus:On(message, self, dirty)
    end
    -- quest names arriving, a quest turned in: only the pages that list or count them redraw
    FC.Bus:On("QUEST_HISTORY_CHANGED", self, function()
        local kind = self.page and self.page.kind
        if kind == "questlog" or kind == "progress" then
            self:MarkDirty()
        elseif self.frame and self.frame:IsShown() then
            self:RefreshNav()
        end
    end)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if not self.frame then return end
        if path == "*" or path:find("^appearance%.scale") or path:find("^appearance%.alpha") or path:find("^appearance%.window") then
            self:ApplyGeometry()
        end
        self:MarkDirty()
    end)
    FC.Bus:On("FONTS_CHANGED", self, function()
        if self.frame then self:LayoutNav() end
        self:MarkDirty()
    end)
    -- a style change (journal or flat) moves the window's parts
    FC.Bus:On("THEME_CHANGED", self, function()
        if self.frame then self:Layout() end
        self:MarkDirty()
    end)
end

function MainWindow:MarkDirty()
    self.dirty = true
    if self.frame and self.frame:IsShown() then
        U.Debounce("mainwindow-refresh", 0.15, function() self:Refresh() end)
    end
end

function MainWindow:Show(pageKey)
    self:Build()
    if pageKey then
        self:SelectPage(pageKey, true)
    elseif not self.page then
        self:SelectPage(FC.P.journal.defaultPage or "overview", true)
    end
    UI.FadeIn(self.frame, 0.16)
    self:Refresh()
end

function MainWindow:Hide()
    if self.frame then self.frame:Hide() end
end

function MainWindow:Toggle()
    if self.frame and self.frame:IsShown() then self:Hide() else self:Show() end
end

function MainWindow:IsShown()
    return self.frame and self.frame:IsShown()
end

------------------------------------------------------------------------
-- Pages and filters
------------------------------------------------------------------------

function MainWindow:SelectPage(key, silent)
    local page = pageByKey[key] or pageByKey.overview
    if page.kind == "action" then page = pageByKey.overview end
    self.page = page
    self.filters = {}
    if not silent then
        self.toolbar.search:SetText("")
        self.searchText = ""
    end
    for pageKey, item in pairs(self.navItems) do item:SetSelected(pageKey == page.key) end
    self.listView:SetShown(page.kind == "list")
    self.overview:SetShown(page.kind == "overview")
    self.statistics:SetShown(page.kind == "stats")
    self.biography:SetShown(page.kind == "bio")
    self.progressPage:SetShown(page.kind == "progress")
    self.questLog:SetShown(page.kind == "questlog")
    if page.kind == "questlog" then self.questLog:SetSearch(self.searchText or "") end
    self:SetHeaderArt()
    self:LayoutToolbar()
    self:Refresh()
end

function MainWindow:SetSearch(text)
    self:Build()
    if not self.frame:IsShown() then self:Show() end
    if self.page.kind ~= "list" then self:SelectPage("recent", true) end
    self.toolbar.search:SetText(text or "")
    self.searchText = text
    self:RefreshList()
end

function MainWindow:CurrentSpec()
    local page = self.page
    local spec = { sort = FC.P.journal.sort }
    if page.spec then
        for k, v in pairs(page.spec) do spec[k] = v end
    end
    if page.group then
        local types = {}
        for _, t in ipairs(Categories:TypesInGroup(page.group) or {}) do types[t] = true end
        spec.types = types
    end
    for k, v in pairs(self.filters or {}) do spec[k] = v end
    return spec
end

local SINCE = { today = 86400, week = 7 * 86400, month = 30 * 86400 }

function MainWindow:OpenFilterMenu(anchor)
    local f = self.filters
    local function set(key, value)
        f[key] = value
        self:RefreshList()
    end
    local items = {
        { text = L.FILTER_SHOW, isTitle = true },
        { text = L.FILTER_SCOPE_ALL, checked = not f.scope, onClick = function() set("scope", nil) end },
        { text = L.FILTER_SCOPE_MINE, checked = f.scope == "mine", onClick = function() set("scope", "mine") end },
        { text = L.FILTER_SCOPE_GUILD, checked = f.scope == "guild", onClick = function() set("scope", "guild") end },
        { divider = true },
        { text = L.FILTER_VERIFIED, checked = f.verified == true, onClick = function() set("verified", not f.verified or nil) end },
        { text = L.FILTER_FAVORITES, checked = f.favorites == true, onClick = function() set("favorites", not f.favorites or nil) end },
        { text = L.FILTER_ARCHIVED, checked = f.archived == "include", onClick = function() set("archived", f.archived ~= "include" and "include" or nil) end },
        { divider = true },
        { text = L.FILTER_ADDED, isTitle = true },
        { text = L.FILTER_ANY_TIME, checked = not f.sinceKey, onClick = function() f.sinceKey = nil set("since", nil) end },
        { text = L.FILTER_TODAY, checked = f.sinceKey == "today", onClick = function() f.sinceKey = "today" set("since", U.Now() - SINCE.today) end },
        { text = L.FILTER_WEEK, checked = f.sinceKey == "week", onClick = function() f.sinceKey = "week" set("since", U.Now() - SINCE.week) end },
        { text = L.FILTER_MONTH, checked = f.sinceKey == "month", onClick = function() f.sinceKey = "month" set("since", U.Now() - SINCE.month) end },
        { divider = true },
        { text = L.FILTER_ZONE, isTitle = true },
        { text = L.FILTER_ANY_ZONE, checked = not f.zone, onClick = function() set("zone", nil) end },
    }
    for _, zone in ipairs(FC.Query:DistinctValues("z")) do
        items[#items + 1] = { text = zone, checked = f.zone == zone, onClick = function() set("zone", zone) end }
    end
    UI.OpenMenu(anchor, items, 220)
end

function MainWindow:RenderChips()
    self.chipPool:ReleaseAll()
    local f = self.filters or {}
    local chips = {}
    local page = self.page
    if page.professionChips then
        for _, prof in ipairs(Categories.PROFESSIONS) do
            chips[#chips + 1] = {
                text = "|T" .. prof.icon .. ":12:12:0:0:64:64:5:59:5:59|t " .. L[prof.label],
                active = f.profession == prof.key,
                onClick = function()
                    f.profession = f.profession ~= prof.key and prof.key or nil
                    self:RefreshList()
                end,
            }
        end
    elseif page.favoriteChips then
        for _, group in ipairs(self.FAVORITE_GROUPS) do
            chips[#chips + 1] = {
                text = L["FAVGROUP_" .. group:upper()],
                active = f.favoriteGroup == group,
                onClick = function()
                    f.favoriteGroup = f.favoriteGroup ~= group and group or nil
                    self:RefreshList()
                end,
            }
        end
    end
    local function removable(label, key)
        chips[#chips + 1] = { text = label .. "  x", active = true, onClick = function()
            f[key] = nil
            if key == "since" then f.sinceKey = nil end
            if key == "foundBy" then f.foundByLabel = nil end
            self:RefreshList()
        end }
    end
    if f.foundBy then removable(string.format(L.FILTER_FOUND_BY, f.foundByLabel or "?"), "foundBy") end
    if f.scope == "mine" then removable(L.FILTER_SCOPE_MINE, "scope") end
    if f.scope == "guild" then removable(L.FILTER_SCOPE_GUILD, "scope") end
    if f.verified then removable(L.FILTER_VERIFIED, "verified") end
    if f.favorites then removable(L.FILTER_FAVORITES, "favorites") end
    if f.archived then removable(L.FILTER_ARCHIVED, "archived") end
    if f.since then removable(L["FILTER_" .. (f.sinceKey or "any"):upper()], "since") end
    if f.zone then removable(f.zone, "zone") end

    -- every chip stays visible: they wrap onto as many rows as they need
    local width = self.chipBar:GetWidth()
    if not width or width <= 0 then width = 600 end
    local x, y, rows = 0, 0, #chips > 0 and 1 or 0
    local accent = Theme:Hex("accent")
    for _, spec in ipairs(chips) do
        local chip = self.chipPool:Acquire()
        chip:SetChip(spec.text, spec.active and accent or nil)
        chip.onClick = spec.onClick
        if chip:GetWidth() > width then
            chip:SetWidth(width)
            chip.label:SetWidth(width - 14)
        else
            chip.label:SetWidth(0)
        end
        if x > 0 and x + chip:GetWidth() > width then
            x, y, rows = 0, y + 22, rows + 1
        end
        chip:SetPoint("TOPLEFT", x, -y)
        x = x + chip:GetWidth() + 6
    end
    self.chipBar:SetHeight(rows > 0 and (rows * 22 - 4) or 1)
    -- without chips the cards start level with the detail panel
    self.listPanel:SetPoint("TOPLEFT", self.chipBar, "BOTTOMLEFT", 0, rows > 0 and -6 or 1)
end

------------------------------------------------------------------------
-- Rendering
------------------------------------------------------------------------

function MainWindow:Refresh()
    if not self.frame then return end
    self.dirty = false
    self:RefreshNav()
    self:RefreshFooter()
    if not self.page then return end
    local page
    if self.page.kind == "overview" then
        page = self.overview
    elseif self.page.kind == "stats" then
        page = self.statistics
    elseif self.page.kind == "bio" then
        page = self.biography
    elseif self.page.kind == "progress" then
        page = self.progressPage
    elseif self.page.kind == "questlog" then
        page = self.questLog
    end
    if page then
        page:Refresh()
        self:SetHeaderText(page.title, page.subtitle)
        self:LayoutToolbar()
    else
        self:RefreshList(true)
    end
end

--- The header's title and subtitle (the pages keep them, the header shows them).
function MainWindow:SetHeaderText(title, subtitle)
    self.header.title:SetText(title or "")
    self.header.subtitle:SetText(subtitle or "")
end

--- A full page redrew itself (a chip or a row clicked on it): its header
--- text and toolbar controls follow.
function MainWindow:PageChanged(page)
    if not self.header or not page:IsShown() then return end
    self:SetHeaderText(page.title, page.subtitle)
    self:LayoutToolbar()
end

function MainWindow:RefreshNav()
    local stats = FC.Store:Stats()
    for _, page in ipairs(self.PAGES) do
        local item = self.navItems[page.key]
        local count
        if page.group then
            count = 0
            for _, t in ipairs(Categories:TypesInGroup(page.group) or {}) do count = count + (stats.byType[t] or 0) end
        elseif page.key == "guild" then
            count = stats.guild
        elseif page.key == "favorites" then
            count = stats.favorites
        elseif page.key == "recent" then
            count = stats.week
        elseif page.key == "questlog" then
            count = select(2, FC.QuestHistory:Completed())
        end
        item:SetCount(count)
    end
end

function MainWindow:RefreshFooter()
    local status = FC.Sync:Status()
    local stats = FC.Store:Stats()
    local text
    if not status.enabled then
        text = L.FOOTER_SYNC_OFF
        self.footer.dot:SetColorTexture(Theme:Color("muted"))
    elseif not status.channel then
        text = L.FOOTER_SYNC_NO_CHANNEL
        self.footer.dot:SetColorTexture(Theme:Color("warning"))
    else
        text = string.format(L.FOOTER_SYNC_ON, L["CHANNEL_" .. status.channel] or status.channel, status.peers)
        self.footer.dot:SetColorTexture(Theme:Color("success"))
    end
    self.footer.status:SetText(string.format(L.FOOTER_ENTRIES, U.FormatNumber(stats.total)) .. "   \194\183   " .. text)
end

function MainWindow:RefreshList(keepOffset)
    if not self.frame or self.page.kind ~= "list" then return end
    local results = FC.Query:Run(self:CurrentSpec(), self.searchText)
    self.results = results
    self:SetHeaderText(L[self.page.label], string.format(L.RESULTS_COUNT, U.FormatNumber(#results)))
    self:RenderChips()
    self.list:SetItems(results, keepOffset)

    if #results == 0 then
        self.list:Hide()
        self.emptyState:Show()
        local searching = (self.searchText and self.searchText ~= "") or next(self.filters or {}) ~= nil
        if searching then
            self.emptyState:SetContent("Interface\\Icons\\INV_Misc_Spyglass_03", L.EMPTY_SEARCH_TITLE, L.EMPTY_SEARCH_TEXT, L.CLEAR_FILTERS, function()
                self.filters = {}
                self.toolbar.search:SetText("")
                self.searchText = ""
                self:RefreshList()
            end, "emptySearch")
        else
            local key = self.page.key:upper()
            self.emptyState:SetContent(self.page.icon, L["EMPTY_" .. key .. "_TITLE"], L["EMPTY_" .. key .. "_TEXT"], L.NEW_DISCOVERY, function()
                FC.Editor:OpenNew(self:DefaultTypeForPage())
            end, "emptyJournal")
        end
    else
        self.list:Show()
        self.emptyState:Hide()
    end

    local selected = self.selected and FC.Store:Get(self.selected)
    local inResults = false
    if selected then
        for _, rec in ipairs(results) do
            if rec.id == selected.id then inResults = true break end
        end
    end
    if not inResults then
        selected = results[1]
        self.selected = selected and selected.id or nil
        self.list:Render()
    end
    self.detail:ShowRecord(selected)
end

function MainWindow:DefaultTypeForPage()
    local page = self.page
    if page and page.group then
        local types = Categories:TypesInGroup(page.group)
        return types and types[1]
    end
    return nil
end

------------------------------------------------------------------------
-- Selection (CardList owner interface)
------------------------------------------------------------------------

function MainWindow:Select(id)
    self.selected = id
    self.list:Render()
    self.detail:ShowRecord(FC.Store:Get(id))
end

function MainWindow:IsSelected(id)
    return self.selected == id
end

--- Opens the journal on a discovery (from map pins, links, notifications).
function MainWindow:ShowDiscovery(id)
    local rec = FC.Store:Get(id)
    if not rec then return end
    self:Build()
    local group = Categories:Get(rec.t).group
    local target = "recent"
    for _, page in ipairs(self.PAGES) do
        if page.group == group then target = page.key break end
    end
    local state = FC.Store:GetState(id)
    if state and state.arch then target = "archived" end
    self.selected = id
    if not self.frame:IsShown() then UI.FadeIn(self.frame, 0.16) end
    self:SelectPage(target)
    self.list:ScrollTo(id)
    self.detail:ShowRecord(rec)
end

--- The journal's list of everything some of your characters found
--- ({ [key] = true }), from the Progress page.
function MainWindow:ShowFinds(keys, label)
    self:Build()
    if not self.frame:IsShown() then UI.FadeIn(self.frame, 0.16) end
    self:SelectPage("recent")
    self.filters.foundBy = keys
    self.filters.foundByLabel = label
    self:RefreshList()
end

--- The journal's list of the quests some of your characters completed
--- ({ [key] = true }; nil: the one you play), from the Progress page or /fc quests.
function MainWindow:ShowQuestLog(keys)
    self:Build()
    if not self.frame:IsShown() then UI.FadeIn(self.frame, 0.16) end
    self.questLog.keys = keys
    self.questLog.offset = 0
    self:SelectPage("questlog")
end

function MainWindow:ToggleZoneGuide()
    FC.ZoneGuide:Toggle()
end

function MainWindow:OpenMap()
    local mapID = FC.Compat.GetPlayerMapID()
    FC.Compat.OpenWorldMap(mapID)
end

------------------------------------------------------------------------
-- Actions (detail toolbar and context menu)
------------------------------------------------------------------------

function MainWindow:RunAction(action, rec)
    local store = FC.Store
    rec = store:Get(rec.id)
    if not rec then return end
    if action == "map" then
        FC.Waypoints:ShowOnMap(rec)
    elseif action == "waypoint" then
        FC.Waypoints:Set(rec)
    elseif action == "favorite" then
        local state = store:GetState(rec.id)
        if state and state.fav then
            store:SetFavorite(rec.id, false)
        else
            self:OpenFavoriteMenu(rec)
        end
    elseif action == "share" then
        self:Share(rec)
    elseif action == "link" then
        FC.ChatLinks:Insert(rec)
    elseif action == "edit" then
        FC.Editor:OpenEdit(rec)
    elseif action == "note" then
        local state = store:GetState(rec.id)
        UI.Prompt(L.ACTION_NOTE, L.NOTE_PROMPT, state and state.note or "", function(text)
            store:SetNote(rec.id, text)
        end, C.LIMITS.NOTE)
    elseif action == "tag" then
        UI.Prompt(L.ADD_TAG, L.TAG_PROMPT, "", function(text)
            for _, tag in ipairs(U.Split(text, ",")) do store:AddUserTag(rec.id, tag) end
        end, 80)
    elseif action == "verify" then
        store:MarkSeen(rec.id)
        if store:AddVerification(rec.id, store.me, U.Now(), "local") then
            FC:Print(L.MSG_VERIFIED, U.Escape(rec.n or "?"))
        end
    elseif action == "archive" then
        local state = store:GetState(rec.id)
        store:SetArchived(rec.id, not (state and state.arch))
    elseif action == "export" then
        local text = FC.ImportExport:ExportRecords({ rec }, true)
        if text then UI.TextDialog(L.EXPORT_DISCOVERY, text, true) end
    elseif action == "delete" then
        self:ConfirmDelete(rec)
    end
end

function MainWindow:OpenFavoriteMenu(rec)
    local items = {
        { text = L.FAVORITE_ADD, onClick = function() FC.Store:SetFavorite(rec.id, true) end },
        { divider = true },
        { text = L.FAVORITE_GROUP_TITLE, isTitle = true },
    }
    for _, group in ipairs(self.FAVORITE_GROUPS) do
        items[#items + 1] = { text = L["FAVGROUP_" .. group:upper()], onClick = function() FC.Store:SetFavorite(rec.id, true, group) end }
    end
    UI.OpenMenu("cursor", items, 190)
end

function MainWindow:Share(rec)
    if not FC.Sync:Enabled() then
        FC:Print(L.MSG_SYNC_DISABLED)
        return
    end
    if FC.Store:IsMine(rec) and rec.v == "p" then
        UI.Confirm(L.SHARE_CONFIRM_TITLE, L.SHARE_CONFIRM_TEXT, L.ACTION_SHARE, function()
            if FC.Sync:ShareNow(rec.id) then FC:Print(L.MSG_SHARED, U.Escape(rec.n or "?")) end
        end)
    elseif FC.Sync:ShareNow(rec.id) then
        FC:Print(L.MSG_SHARED, U.Escape(rec.n or "?"))
    end
end

function MainWindow:ConfirmDelete(rec)
    local store = FC.Store
    local title = U.Escape(rec.n or "?")
    if store:IsMine(rec) and rec.v == "g" then
        UI.Confirm(L.RETRACT_TITLE, string.format(L.RETRACT_TEXT, title), L.RETRACT, function()
            store:Retract(rec.id)
            self.selected = nil
        end, true)
    elseif store:IsMine(rec) then
        UI.Confirm(L.DELETE_TITLE, string.format(L.DELETE_TEXT, title), L.DELETE, function()
            store:DeletePersonal(rec.id)
            self.selected = nil
        end, true)
    else
        UI.Confirm(L.HIDE_TITLE, string.format(L.HIDE_TEXT, title), L.HIDE, function()
            store:DeletePersonal(rec.id)
            self.selected = nil
        end, true)
    end
end

function MainWindow:OpenContextMenu(rec)
    local status = FC.Store:GetStatus(rec)
    local mine = FC.Store:IsMine(rec)
    local function act(key) return function() self:RunAction(key, rec) end end
    UI.OpenMenu("cursor", {
        { text = U.Escape(UI.Display(rec).title), isTitle = true },
        { text = L.ACTION_SHOW_MAP, disabled = not rec.m, onClick = act("map") },
        { text = L.ACTION_WAYPOINT, disabled = not (rec.m and rec.x), onClick = act("waypoint") },
        { text = status.favorite and L.ACTION_UNFAVORITE or L.ACTION_FAVORITE, onClick = act("favorite") },
        { text = L.ACTION_LINK, disabled = status.rumored, onClick = act("link") },
        { text = L.ACTION_SHARE, disabled = status.rumored or not FC.Sync:Enabled(), onClick = act("share") },
        { text = L.ACTION_EDIT, disabled = not mine, onClick = act("edit") },
        { text = L.ACTION_NOTE, onClick = act("note") },
        { text = status.archived and L.ACTION_UNARCHIVE or L.ACTION_ARCHIVE, onClick = act("archive") },
        { divider = true },
        { text = mine and rec.v == "g" and L.RETRACT or (mine and L.DELETE or L.HIDE), danger = true, onClick = act("delete") },
    }, 200)
end
