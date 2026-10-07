--[[
  Forever Companion - Settings/SettingsWindow.lua
  The configuration window. Renders Settings/SettingsSchema.lua generically
  (one page per category, built on first open), plus three custom pages:
  Profiles, Data management and About. Every change applies immediately;
  nothing in the addon needs /reload.

  A small panel is also registered in Blizzard's Options > AddOns list that
  opens this window.
]]

local _, FC = ...

local SettingsWindow = FC:NewModule("SettingsWindow")

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local C = FC.C

local WIDTH, HEIGHT = 860, 640
local NAV_WIDTH = 190
local CONTROL_WIDTH = 320
local CORNER = 26          -- painted frame corners (journal style)
local HEADER_HEIGHT = 96   -- the settings painting (journal style)

------------------------------------------------------------------------
-- Generic control rendering
------------------------------------------------------------------------

-- controls read their setting path, or control.get for values kept outside
-- the profile (the progress mode belongs to the whole account)
local function getter(control)
    if control.get then return control.get end
    return function() return FC.Config:Get(control.path) end
end

-- checkgrid items bind to setting paths; a path that holds nothing counts
-- as on (categories registered after the defaults were written). With
-- control.invert the setting means "hidden" (map.hiddenGroups).
local function checkGridItems(control)
    local items = {}
    for _, item in ipairs(type(control.items) == "function" and control.items() or control.items) do
        items[#items + 1] = {
            text = item.text,
            icon = item.icon,
            get = function()
                local value = FC.Config:Get(item.path)
                if control.invert then return value ~= true end
                return value ~= false
            end,
            set = function(value)
                if control.invert then value = not value end
                FC.Config:Set(item.path, value and true or false)
            end,
        }
    end
    return items
end

local function setter(control)
    return function(value)
        if control.set then control.set(value) else FC.Config:Set(control.path, value) end
    end
end

local function buildControl(parent, control, width)
    local t = control.type
    if t == "checkbox" then
        local box = UI.Checkbox(parent, L[control.label], getter(control), setter(control), control.tip and L[control.tip])
        return box, 26
    elseif t == "slider" then
        local slider = UI.Slider(parent, L[control.label], control.min, control.max, control.step, getter(control), setter(control), control.format)
        slider:SetWidth(CONTROL_WIDTH)
        return slider, 48
    elseif t == "dropdown" then
        local dropdown = UI.Dropdown(parent, L[control.label], control.items, getter(control), setter(control), CONTROL_WIDTH)
        return dropdown, 54
    elseif t == "color" then
        local swatch = UI.ColorSwatch(parent, L[control.label], function() return FC.Theme:Hex(control.role) end, function(hex)
            FC.Theme:SetRoleColor(control.role, hex)
        end, function()
            FC.P.appearance.colors[control.role] = nil
            FC.Config:Set("appearance.colors", FC.P.appearance.colors)
        end)
        swatch:SetWidth(CONTROL_WIDTH)
        return swatch, 28
    elseif t == "button" then
        local button = UI.Button(parent, L[control.label], { style = control.style or "secondary", height = 26, autoWidth = true, width = 120, onClick = control.onClick })
        function button:Refresh()
            if control.disabled then self:SetDisabled(control.disabled()) end
        end
        return button, 34
    elseif t == "note" then
        local text = UI.WrappedText(parent, "secondary", "muted")
        text:SetWidth(width)
        text:SetText(L[control.text])
        return text, text:GetStringHeight() + 10
    elseif t == "checkgrid" then
        return UI.CheckGrid(parent, checkGridItems(control), width, control.columns)
    elseif t == "custom" then
        return control.build(parent, width)
    end
end

local function buildSchemaPage(page, category)
    local area = page.area
    local content = area.content
    local width = WIDTH - NAV_WIDTH - 90
    local y = 4
    page.controls = {}
    for _, section in ipairs(category.sections or {}) do
        local header = UI.SectionHeader(content, L[section.title])
        header:SetPoint("TOPLEFT", 0, -y)
        header:SetWidth(width)
        y = y + 32
        for _, control in ipairs(section.controls) do
            local widget, height = buildControl(content, control, width)
            if widget then
                widget:SetPoint("TOPLEFT", 4, -y)
                y = y + height + 4
                page.controls[#page.controls + 1] = { widget = widget, control = control }
            end
        end
        y = y + 14
    end
    area:SetContentHeight(y)
end

local function refreshControls(page)
    for _, entry in ipairs(page.controls or {}) do
        local widget, control = entry.widget, entry.control
        if widget.Refresh then widget:Refresh() end
        if control.disabled and widget.SetDisabled then widget:SetDisabled(control.disabled()) end
    end
    if page.OnRefresh then page:OnRefresh() end
end

------------------------------------------------------------------------
-- Custom pages
------------------------------------------------------------------------

local function buildProfilesPage(page)
    local content = page.area.content
    local P = FC.Profiles
    local width = WIDTH - NAV_WIDTH - 90
    local y = 4

    local header = UI.SectionHeader(content, L.PROFILE_ACTIVE)
    header:SetPoint("TOPLEFT", 0, -y)
    header:SetWidth(width)
    y = y + 32
    local selector = UI.Dropdown(content, L.PROFILE_SELECT, function()
        local items = {}
        for _, name in ipairs(P:List()) do items[#items + 1] = { value = name, text = name } end
        return items
    end, function() return P:GetActive() end, function(value) P:Activate(value) end, CONTROL_WIDTH)
    selector:SetPoint("TOPLEFT", 4, -y)
    y = y + 60
    page.info = UI.WrappedText(content, "secondary", "muted")
    page.info:SetPoint("TOPLEFT", 4, -y)
    page.info:SetWidth(width - 8)
    y = y + 30

    local quick = UI.SectionHeader(content, L.PROFILE_QUICK)
    quick:SetPoint("TOPLEFT", 0, -y)
    quick:SetWidth(width)
    y = y + 34
    local function row(buttons)
        local x = 4
        for _, spec in ipairs(buttons) do
            local button = UI.Button(content, spec[1], { style = spec[3] or "secondary", height = 26, autoWidth = true, width = 110, onClick = spec[2] })
            button:SetPoint("TOPLEFT", x, -y)
            x = x + button:GetWidth() + 8
        end
        y = y + 36
    end
    row({
        { L.PROFILE_USE_DEFAULT, function() P:Activate("Default") end },
        { L.PROFILE_USE_CHARACTER, function() P:Activate(P:CharacterProfileName()) end },
        { L.PROFILE_USE_CLASS, function() P:Activate(P:ClassProfileName()) end },
    })

    local manage = UI.SectionHeader(content, L.PROFILE_MANAGE)
    manage:SetPoint("TOPLEFT", 0, -y)
    manage:SetWidth(width)
    y = y + 34
    local function report(ok, err)
        if not ok and err then FC:Print(err) end
    end
    row({
        { L.PROFILE_NEW, function()
            UI.Prompt(L.PROFILE_NEW, L.PROFILE_NAME_PROMPT, "", function(name) report(P:Create(name)) end, 48)
        end },
        { L.PROFILE_COPY_AS_NEW, function()
            UI.Prompt(L.PROFILE_COPY_AS_NEW, L.PROFILE_NAME_PROMPT, P:GetActive() .. " copy", function(name) report(P:Create(name, P:GetActive())) end, 48)
        end },
        { L.PROFILE_RENAME, function()
            UI.Prompt(L.PROFILE_RENAME, L.PROFILE_NAME_PROMPT, P:GetActive(), function(name) report(P:Rename(P:GetActive(), name)) end, 48)
        end },
    })
    local copySource = UI.Dropdown(content, L.PROFILE_COPY_FROM, function()
        local items = {}
        for _, name in ipairs(P:List()) do
            if name ~= P:GetActive() then items[#items + 1] = { value = name, text = name } end
        end
        return items
    end, function() return nil end, function(value)
        UI.Confirm(L.PROFILE_COPY_FROM, string.format(L.PROFILE_COPY_CONFIRM, value, P:GetActive()), L.COPY, function() P:CopyFrom(value) end)
    end, CONTROL_WIDTH)
    copySource:SetPoint("TOPLEFT", 4, -y)
    y = y + 62
    row({
        { L.PROFILE_RESET, function()
            UI.Confirm(L.PROFILE_RESET, string.format(L.PROFILE_RESET_CONFIRM, P:GetActive()), L.RESET, function() P:Reset() end, true)
        end, "danger" },
        { L.PROFILE_DELETE, function()
            UI.Prompt(L.PROFILE_DELETE, L.PROFILE_DELETE_PROMPT, "", function(name)
                if P:Exists(name) then report(P:Delete(name)) else FC:Print(L.PROFILE_NOT_FOUND) end
            end, 48)
        end, "danger" },
    })

    local share = UI.SectionHeader(content, L.PROFILE_SHARE)
    share:SetPoint("TOPLEFT", 0, -y)
    share:SetWidth(width)
    y = y + 34
    row({
        { L.PROFILE_EXPORT, function()
            local text = FC.ImportExport:ExportProfile()
            if text then UI.TextDialog(L.PROFILE_EXPORT, text, true) end
        end },
        { L.PROFILE_IMPORT, function()
            UI.TextDialog(L.PROFILE_IMPORT, "", false, function(text)
                local result, err = FC.ImportExport:Import(text)
                FC:Print(result and FC.ImportExport:Describe(result) or string.format(L.IMPORT_FAILED, err or "?"))
            end)
        end },
    })
    page.area:SetContentHeight(y + 10)
    page.controls = { { widget = selector, control = {} }, { widget = copySource, control = {} } }
    function page:OnRefresh()
        self.info:SetText(string.format(L.PROFILE_INFO, P:GetActive(), P:CharacterKey() or "?"))
    end
end

local function buildDataPage(page)
    local content = page.area.content
    local width = WIDTH - NAV_WIDTH - 90
    local y = 4
    local header = UI.SectionHeader(content, L.DATA_STATS)
    header:SetPoint("TOPLEFT", 0, -y)
    header:SetWidth(width)
    y = y + 32
    page.statRows = {}
    for i = 1, 6 do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(360, 20)
        row:SetPoint("TOPLEFT", 4, -y)
        row.left = UI.Text(row, "body", "muted")
        row.left:SetPoint("LEFT")
        row.right = UI.Text(row, "body", "text")
        row.right:SetPoint("RIGHT")
        page.statRows[i] = row
        y = y + 22
    end
    y = y + 14

    local function section(title)
        local h = UI.SectionHeader(content, title)
        h:SetPoint("TOPLEFT", 0, -y)
        h:SetWidth(width)
        y = y + 34
    end
    local function button(label, onClick, style)
        local b = UI.Button(content, label, { style = style or "secondary", height = 26, autoWidth = true, width = 140, onClick = onClick })
        b:SetPoint("TOPLEFT", 4, -y)
        y = y + 34
        return b
    end
    local function note(text)
        local fs = UI.WrappedText(content, "secondary", "muted")
        fs:SetPoint("TOPLEFT", 4, -y)
        fs:SetWidth(width - 8)
        fs:SetText(text)
        y = y + fs:GetStringHeight() + 10
    end

    section(L.DATA_BACKUP)
    note(L.DATA_BACKUP_NOTE)
    button(L.DATA_EXPORT_BACKUP, function()
        local text, count = FC.ImportExport:ExportBackup()
        if text then UI.TextDialog(string.format(L.DATA_EXPORT_TITLE, count or 0), text, true) end
    end)
    button(L.DATA_EXPORT_SHARED, function()
        local list = {}
        for _, rec in FC.Store:Iterate() do
            if rec.v == "g" then list[#list + 1] = rec end
        end
        local text, count = FC.ImportExport:ExportRecords(list, false)
        if text then UI.TextDialog(string.format(L.DATA_EXPORT_TITLE, count or 0), text, true) else FC:Print(L.EXPORT_NOTHING) end
    end)
    button(L.DATA_IMPORT, function()
        UI.TextDialog(L.DATA_IMPORT, "", false, function(text)
            local result, err = FC.ImportExport:Import(text)
            FC:Print(result and FC.ImportExport:Describe(result) or string.format(L.IMPORT_FAILED, err or "?"))
        end)
    end)

    -- what the game remembers about a character the journal did not watch
    section(L.DATA_RECOVERY)
    note(L.DATA_RECOVERY_NOTE)
    button(L.DATA_RESCAN, function() FC.QuestHistory:Rescan() end)
    button(L.DATA_OPEN_QUESTLOG, function() FC.MainWindow:ShowQuestLog() end)

    section(L.DATA_MAINTENANCE)
    button(L.DATA_UNHIDE, function()
        FC:Print(L.MSG_UNHIDDEN, FC.Store:UnhideAll())
    end)
    button(L.DATA_CLEAR_CHARACTER, function()
        UI.Confirm(L.DATA_CLEAR_CHARACTER, L.DATA_CLEAR_CHARACTER_CONFIRM, L.CLEAR, function()
            FC.Database:ClearCharacterData()
            FC.Store:MarkDirty()
            FC.Bus:Emit("STORE_RESET")
        end, true)
    end, "danger")
    button(L.DATA_CLEAR_GUILD, function()
        UI.Confirm(L.DATA_CLEAR_GUILD, L.DATA_CLEAR_GUILD_CONFIRM, L.CLEAR, function()
            FC:Print(L.MSG_GUILD_CLEARED, FC.Store:ClearGuildCache())
        end, true)
    end, "danger")
    button(L.DATA_RESET_SETTINGS, function()
        UI.Confirm(L.DATA_RESET_SETTINGS, L.DATA_RESET_SETTINGS_CONFIRM, L.RESET, function() FC.Profiles:Reset() end, true)
    end, "danger")
    page.area:SetContentHeight(y + 10)

    function page:OnRefresh()
        local stats = FC.Store:Stats()
        local size = FC.Database:EstimateSize()
        -- the database holds your other characters' finds too, even when
        -- progress per character keeps them out of the journal
        local alts = FC.Store:PerCharacter() and stats.alts or 0
        local data = {
            { L.DATA_ENTRIES, U.FormatNumber(stats.total + alts) },
            { L.DATA_GUILD_ENTRIES, U.FormatNumber(stats.guild) },
            { L.DATA_PERSONAL_ENTRIES, U.FormatNumber(stats.personal + alts) },
            { L.DATA_PRIVATE_ENTRIES, U.FormatNumber(stats.private) },
            { L.DATA_HIDDEN_ENTRIES, U.FormatNumber(stats.hidden) },
            { L.DATA_SIZE, size > 1048576 and string.format("%.1f MB", size / 1048576) or string.format("%.1f KB", size / 1024) },
        }
        for i, row in ipairs(self.statRows) do
            row.left:SetText(data[i][1])
            row.right:SetText(data[i][2])
        end
    end
end

local function buildAboutPage(page)
    local content = page.area.content
    local width = WIDTH - NAV_WIDTH - 90
    local logo = content:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(C.MEDIA .. "Logo")
    logo:SetSize(64, 64)
    logo:SetPoint("TOPLEFT", 4, -4)
    local title = UI.Text(content, "title", "text")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 16, -6)
    title:SetText("Forever Companion")
    local version = UI.Text(content, "body", "accent")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    version:SetText(L.ABOUT_SUBTITLE)
    local body = UI.WrappedText(content, "body", "text")
    body:SetPoint("TOPLEFT", 4, -90)
    body:SetWidth(width - 8)
    body:SetText(L.ABOUT_TEXT)
    local commands = UI.WrappedText(content, "secondary", "muted")
    commands:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -16)
    commands:SetWidth(width - 8)
    commands:SetText(L.ABOUT_COMMANDS)
    page.area:SetContentHeight(90 + body:GetStringHeight() + commands:GetStringHeight() + 40)
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

function SettingsWindow:Build()
    if self.frame then return end
    local frame = UI.Panel(UIParent, { name = "ForeverCompanionSettings", strata = "HIGH", bg = "bg", skin = "window", corner = CORNER })
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 60, 0)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    -- taller or shorter, never narrower: the pages are laid out for this width
    frame:SetResizable(true)
    tinsert(UISpecialFrames, "ForeverCompanionSettings")
    frame:Hide()

    -- navigation: brand (drags the window), then the categories
    local nav = CreateFrame("Frame", nil, frame)
    nav:SetWidth(NAV_WIDTH)
    nav.bg = UI.Texture(nav, "BACKGROUND", "panel", 0.6)
    nav.bg:SetAllPoints()
    nav.line = UI.Texture(nav, "ARTWORK", "border", 1)
    nav.line:SetPoint("TOPRIGHT")
    nav.line:SetPoint("BOTTOMRIGHT")
    nav.line:SetWidth(1)
    self.nav = nav
    local brand = CreateFrame("Frame", nil, nav)
    brand:SetPoint("TOPLEFT")
    brand:SetPoint("TOPRIGHT")
    brand:SetHeight(52)
    brand.logo = brand:CreateTexture(nil, "ARTWORK")
    brand.logo:SetTexture(C.MEDIA .. "Logo")
    brand.logo:SetSize(30, 30)
    brand.logo:SetPoint("LEFT", 8, 0)
    brand.title = UI.Text(brand, "header", "text")
    brand.title:SetPoint("TOPLEFT", brand.logo, "TOPRIGHT", 8, 0)
    brand.title:SetPoint("RIGHT", -6, 0)
    brand.title:SetText(L.SETTINGS_TITLE)
    brand.profile = UI.Text(brand, "meta", "muted")
    brand.profile:SetPoint("BOTTOMLEFT", brand.logo, "BOTTOMRIGHT", 8, 0)
    brand.profile:SetPoint("RIGHT", -6, 0)
    UI.MakeMovable(frame, brand)
    self.brand = brand

    local area = UI.ScrollArea(nav)
    area:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -6)
    area:SetPoint("BOTTOMRIGHT", -2, 6)
    self.navArea = area
    self.navItems = {}
    self.pages = {}
    for i, category in ipairs(FC.SettingsSchema) do
        local item = UI.NavItem(area.content, category.icon, L[category.label], function() self:ShowCategory(category.key) end)
        item:SetPoint("TOPLEFT", 0, -(i - 1) * 29)
        item:SetPoint("RIGHT", area.content, "RIGHT", 0, 0)
        self.navItems[category.key] = item
    end
    area:SetContentHeight(#FC.SettingsSchema * 29 + 6)

    -- header: the category's name and description (over the painting)
    local header = CreateFrame("Frame", nil, frame)
    header.flat = UI.Texture(header, "BACKGROUND", "panel", 1, -6)
    header.flat:SetAllPoints()
    header.flatLine = UI.Divider(header, "border")
    header.flatLine:SetPoint("BOTTOMLEFT")
    header.flatLine:SetPoint("BOTTOMRIGHT")
    header.art = FC.Skin:Art(header, { layer = "BACKGROUND", sublevel = -4 })
    header.shade = FC.Skin:Shade(header, "HORIZONTAL", 0.05, 0.03, 0.02, 0.85, "BACKGROUND", -2)
    header.shade:SetPoint("TOPLEFT")
    header.shade:SetPoint("BOTTOMLEFT")
    header.shade:SetWidth(420)
    header.fade = FC.Skin:Shade(header, "VERTICAL", 0.05, 0.03, 0.02, 0.7, "BACKGROUND", -1)
    header.fade:SetPoint("BOTTOMLEFT")
    header.fade:SetPoint("BOTTOMRIGHT")
    header.fade:SetHeight(24)
    header.title = UI.Text(header, "title", "text")
    header.title:SetPoint("TOPLEFT", 18, -14)
    header.title:SetPoint("RIGHT", -170, 0)
    header.subtitle = UI.WrappedText(header, "secondary", "muted")
    header.subtitle:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -6)
    header.subtitle:SetPoint("RIGHT", -24, 0)
    header.subtitle:SetMaxLines(2)
    header.close = UI.IconButton(header, "Interface\\Buttons\\UI-StopButton", 24, L.CLOSE, function() frame:Hide() end)
    header.close:SetPoint("TOPRIGHT", -8, -8)
    header.journal = UI.Button(header, L.OPEN_JOURNAL, { height = 26, autoWidth = true, width = 110, onClick = function() FC.MainWindow:Show() end })
    header.journal:SetPoint("RIGHT", header.close, "LEFT", -6, 0)
    header.plate = header:CreateTexture(nil, "ARTWORK", nil, -1)
    header.plate:SetTexture(C.WHITE)
    header.plate:SetColorTexture(0.05, 0.03, 0.02, 0.6)
    header.plate:SetPoint("TOPLEFT", header.journal, "TOPLEFT", -4, 4)
    header.plate:SetPoint("BOTTOMRIGHT", header.close, "BOTTOMRIGHT", 4, -4)
    UI.MakeMovable(frame, header)
    self.header = header

    self.body = CreateFrame("Frame", nil, frame)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    self.grip = grip

    frame:HookScript("OnSizeChanged", function() self:Layout() end)
    frame:SetScript("OnShow", function() self:RefreshAll() end)
    self:Layout()
end

--- Painted or flat dress and the places of the window's parts.
function SettingsWindow:Layout()
    local frame = self.frame
    if not frame then return end
    local painted = frame.fcPainted
    local edge = painted and FC.Skin:FrameInset(CORNER) or 8
    local nav, header = self.nav, self.header
    nav:ClearAllPoints()
    nav:SetPoint("TOPLEFT", edge, -edge)
    nav:SetPoint("BOTTOMLEFT", edge, edge)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", edge + NAV_WIDTH + 12, -edge)
    header:SetPoint("TOPRIGHT", -edge, -edge)
    header:SetHeight(painted and HEADER_HEIGHT or 70)
    self.body:ClearAllPoints()
    self.body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 4, -12)
    self.body:SetPoint("BOTTOMRIGHT", -edge, edge)
    self.grip:ClearAllPoints()
    self.grip:SetPoint("BOTTOMRIGHT", painted and -(edge - 6) or -3, painted and (edge - 6) or 3)
    if painted then
        nav.bg:SetColorTexture(0, 0, 0, 0.28)
        FC.Theme:Forget(nav.bg)
        FC.Theme:Paint(nav.line, "accent", 0.3)
        FC.Theme:Paint(header.subtitle, "text", 0.82)
    else
        FC.Theme:Paint(nav.bg, "panel", 0.6)
        FC.Theme:Paint(nav.line, "border", 1)
        FC.Theme:Paint(header.subtitle, "muted")
    end
    header.flat:SetShown(not painted)
    header.flatLine:SetShown(not painted)
    header.art:SetShown(painted)
    header.shade:SetShown(painted)
    header.fade:SetShown(painted)
    header.plate:SetShown(painted)
    if painted then
        local path, focusY = FC.Skin:HeaderPath("settings")
        header.art:SetArt(path, 0.5, focusY)
    end
end

--- Fits the window to the screen at its scale (it may only get shorter).
function SettingsWindow:FitScreen()
    local frame = self.frame
    local scale = frame:GetScale() or 1
    local screenH = UIParent:GetHeight()
    if not screenH or screenH <= 0 then screenH = 1080 end
    local maxH = math.max(360, math.floor(screenH / scale) - 16)
    local minH = math.min(480, maxH)
    if frame.SetResizeBounds then frame:SetResizeBounds(WIDTH, minH, WIDTH, math.max(minH, math.min(1000, maxH))) end
    frame:SetSize(WIDTH, U.Clamp(frame:GetHeight() or HEIGHT, minH, math.max(minH, math.min(1000, maxH))))
end

function SettingsWindow:GetPage(key)
    if self.pages[key] then return self.pages[key] end
    local category
    for _, c in ipairs(FC.SettingsSchema) do
        if c.key == key then category = c break end
    end
    if not category then return nil end
    local page = CreateFrame("Frame", nil, self.body)
    page:SetAllPoints()
    page.area = UI.ScrollArea(page)
    page.area:SetAllPoints()
    -- shown in the window's header (wrapped: descriptions can be long)
    page.title = L[category.label]
    page.subtitle = L[category.label .. "_DESC"]
    if category.custom == "profiles" then
        buildProfilesPage(page)
    elseif category.custom == "data" then
        buildDataPage(page)
    elseif category.custom == "about" then
        buildAboutPage(page)
    else
        buildSchemaPage(page, category)
    end
    self.pages[key] = page
    return page
end

function SettingsWindow:ShowCategory(key)
    self.current = key
    for k, item in pairs(self.navItems) do item:SetSelected(k == key) end
    for k, page in pairs(self.pages) do page:SetShown(k == key) end
    local page = self:GetPage(key)
    if page then
        page:Show()
        refreshControls(page)
        page.area:ScrollToTop()
        self.header.title:SetText(page.title or "")
        self.header.subtitle:SetText(page.subtitle or "")
    end
end

function SettingsWindow:RefreshAll()
    if not self.frame then return end
    self.brand.profile:SetText(string.format(L.SETTINGS_PROFILE, FC.Profiles:GetActive()))
    for _, page in pairs(self.pages) do refreshControls(page) end
end

function SettingsWindow:Show(key)
    self:Build()
    self.frame:SetScale(FC.P.appearance.scale)
    self:FitScreen()
    self:Layout()
    self:ShowCategory(key or self.current or "general")
    UI.FadeIn(self.frame, 0.14)
    self:RefreshAll()
end

function SettingsWindow:Toggle(key)
    if self.frame and self.frame:IsShown() then self.frame:Hide() else self:Show(key) end
end

function SettingsWindow:RegisterBlizzardPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Forever Companion"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Forever Companion")
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    text:SetText(L.BLIZZARD_PANEL_TEXT)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(200, 26)
    button:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
    button:SetText(L.OPEN_SETTINGS)
    button:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then pcall(HideUIPanel, SettingsPanel) end
        self:Show()
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            pcall(Settings.RegisterAddOnCategory, category)
            self.blizzardCategory = category
        end
    elseif InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
    end
end

function SettingsWindow:OnEnable()
    FC:SafeCall("Settings:BlizzardPanel", self.RegisterBlizzardPanel, self)
    local function refresh()
        if self.frame and self.frame:IsShown() then
            U.Debounce("settings-refresh", 0.1, function() self:RefreshAll() end)
        end
    end
    FC.Bus:On("SETTINGS_CHANGED", self, refresh)
    FC.Bus:On("PROFILE_CHANGED", self, refresh)
    FC.Bus:On("THEMES_LIST_CHANGED", self, refresh)
    -- the style (journal or flat) can change while the window is open
    FC.Bus:On("THEME_CHANGED", self, function()
        if self.frame then self:Layout() end
    end)
end
