-- BLib_Options.lua
-- Settings windows, the way the family builds them (agreed 2026-09-27): a
-- BLib window of labelled rows, and a page in Options > AddOns that points
-- to it. Lifeline and Countinghouse each had a copy of the row builder; it
-- lives here from 1.8.0.
-- Depends on: BLib_Compat.lua, BLib_Core.lua, BLib_Widgets.lua
--
--   local b = BLib.NewOptionsBuilder(parent, t, width, onChange)
--   b:Section("Scanning")
--   b:Toggle("Full scan on open", get, set)
--   b:Input("Gold cap", get, set, { numeric = true, min = 0 })   -- a box to type into (1.10.0)
--   b:Key("Buy key", get, set)                                   -- a key binding (1.10.0)
--   ...
--   parentHeight = b.y + b.pad
--   b:Refresh()          -- every row reads its value again
--
-- Every row reads its value through `get` when refreshed rather than holding
-- it, so a change made by a slash command shows the next time the window
-- opens. onChange runs after a row changes a value (default: b:Refresh()),
-- for a window with several builders to refresh them all.
--
-- BLib.NewOptionsWindow (1.10.0, below) is the window itself: pages in a list,
-- each made with a builder, or drawn by the addon.

BLib = BLib or {}

local PAD   = 12
local ROW_H = 24

local Builder = {}
Builder.__index = Builder

function BLib.NewOptionsBuilder(parent, t, width, onChange)
    local b = setmetatable({ parent = parent, t = t, w = width, y = PAD, pad = PAD, refreshers = {} }, Builder)
    b.changed = onChange or function() b:Refresh() end
    return b
end

function Builder:OnRefresh(fn)
    self.refreshers[#self.refreshers + 1] = fn
end

-- A row that errors is skipped, not the rows after it.
function Builder:Refresh()
    for _, fn in ipairs(self.refreshers) do pcall(fn) end
end

function Builder:Section(text)
    if self.y > PAD then self.y = self.y + 8 end
    local header = BLib.MakeFS(self.parent, BLib.FONT_SM, self.t.accent)
    header:SetPoint("TOPLEFT", PAD, -self.y)
    header:SetText(text)
    local rule = self.parent:CreateTexture(nil, "ARTWORK")
    BLib.SolidBase(rule)
    rule:SetSize(self.w - PAD * 2, BLib.Pixel and BLib.Pixel.Size(self.parent, 1) or 1)
    if BLib.Pixel then BLib.Pixel.Track(rule, self.parent, false, 1) end
    rule:SetPoint("TOPLEFT", PAD, -(self.y + 14))
    BLib.SetVC(rule, self.t.border)
    self.y = self.y + 22
end

function Builder:Note(text, colour)
    local fs = BLib.MakeFS(self.parent, BLib.FONT_SM, colour or self.t.subText)
    fs:SetPoint("TOPLEFT", PAD, -self.y)
    fs:SetWidth(self.w - PAD * 2)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    self.y = self.y + fs:GetStringHeight() + 6
    return fs
end

-- A note whose text is worked out on every refresh; `lines` reserves room.
function Builder:LiveNote(getText, lines)
    local fs = BLib.MakeFS(self.parent, BLib.FONT_SM, self.t.subText)
    fs:SetPoint("TOPLEFT", PAD, -self.y)
    fs:SetWidth(self.w - PAD * 2)
    fs:SetJustifyH("LEFT")
    self:OnRefresh(function() fs:SetText(getText() or "") end)
    self.y = self.y + (lines or 1) * 14 + 6
    return fs
end

-- The label is kept clear of the control at the right, so a long one wraps
-- rather than running under it.
local function Label(self, text, controlW)
    local fs = BLib.MakeFS(self.parent, BLib.FONT_SM, self.t.text)
    fs:SetPoint("TOPLEFT", PAD, -(self.y + 5))
    fs:SetWidth(self.w - PAD * 2 - (controlW or 0) - 10)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

function Builder:Toggle(text, get, set)
    Label(self, text, 50)
    local t = self.t
    local button = BLib.MakeButton(self.parent, "", 50, 18, t)
    button:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", self.w - PAD, -(self.y + 1))
    button:SetScript("OnClick", function()
        set(not get())
        self.changed()
    end)
    self:OnRefresh(function()
        local on = get()
        button.label:SetText(on and "ON" or "OFF")
        BLib.SetTC(button.label, on and t.accent or t.subText)
    end)
    self.y = self.y + ROW_H + 2
    return button
end

function Builder:Slider(text, minValue, maxValue, step, get, set)
    local fs = BLib.MakeFS(self.parent, BLib.FONT_SM, self.t.text)
    fs:SetPoint("TOPLEFT", PAD, -self.y)
    fs:SetText(text)
    self.y = self.y + 16
    local slider = BLib.MakeSlider(self.parent, self.w - PAD * 2, self.t, minValue, maxValue, step, get(),
        function(v) set(v) end)
    slider:SetPoint("TOPLEFT", PAD, -self.y)
    -- A page that scrolls would stop at whichever slider passed under the
    -- pointer and change it instead (Lifeline review, 2026-09-24). Here the
    -- wheel scrolls the page; sliders are dragged or clicked.
    if slider.slider then slider.slider:EnableMouseWheel(false) end
    self:OnRefresh(function() slider:SetValue(get()) end)
    self.y = self.y + slider:GetHeight() + 8
    return slider
end

-- options = { { text =, value = }, ... }
function Builder:Choice(text, options, get, set, width)
    width = width or 150
    Label(self, text, width)
    local dropdown = BLib.MakeDropdown(self.parent, width, self.t, options, function(value)
        set(value)
        self.changed()
    end)
    dropdown:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", self.w - PAD, -self.y)
    self:OnRefresh(function() dropdown:SetSelected(get()) end)
    self.y = self.y + ROW_H + 4
    return dropdown
end

-- A colour swatch; get returns r, g, b. Cancel in the picker puts back the colour it opened with (1.10.0).
function Builder:Colour(text, get, set)
    Label(self, text, 40)
    local swatch = CreateFrame("Button", nil, self.parent)
    swatch:SetSize(40, 16)
    swatch:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", self.w - PAD, -(self.y + 2))
    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.5, 0.5, 0.5, 1)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetColorTexture(1, 1, 1, 1)
    swatch:SetScript("OnClick", function()
        local r, g, b = get()
        BLib.OpenColorPicker({
            r = r, g = g, b = b,
            onChange = function(nr, ng, nb)
                set(nr, ng, nb)
                fill:SetVertexColor(nr, ng, nb)
            end,
            onCancel = function()
                set(r, g, b)
                fill:SetVertexColor(r, g, b)
            end,
        })
    end)
    self:OnRefresh(function() fill:SetVertexColor(get()) end)
    self.y = self.y + ROW_H
    return swatch
end

-- A box to type into. opts: width (default 120), numeric (a number, kept within min and max), maxLetters.
-- The value is set on Enter or when the box loses focus; Escape puts back what was there; a number that will
-- not read puts back what was there too.
function Builder:Input(text, get, set, opts)
    opts = opts or {}
    local width = opts.width or 120
    Label(self, text, width)
    local t = self.t
    local holder = CreateFrame("Frame", nil, self.parent)
    holder:SetSize(width, 20)
    holder:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", self.w - PAD, -self.y)
    BLib.MakeBg(holder, t.panelBg or t.frameBg)
    BLib.ApplyBorder(holder, holder, t.border)
    local box = CreateFrame("EditBox", nil, holder)
    box:SetPoint("TOPLEFT", 5, 0)
    box:SetPoint("BOTTOMRIGHT", -5, 0)
    box:SetAutoFocus(false)
    BLib.SetFontSafe(box, BLib.FONT, BLib.FONT_SM, "")
    box:SetTextColor(BLib.CR(t.text), BLib.CG(t.text), BLib.CB(t.text))
    if opts.maxLetters then box:SetMaxLetters(opts.maxLetters) end
    local function Show() local v = get() box:SetText(v == nil and "" or tostring(v)) end
    local function Commit()
        local raw = box:GetText() or ""
        local value = raw
        if opts.numeric then
            value = tonumber(raw)
            if not value then Show() return end
            if opts.min and value < opts.min then value = opts.min end
            if opts.max and value > opts.max then value = opts.max end
        end
        if value ~= get() then
            set(value)
            self.changed()
        end
        Show()
    end
    box:SetScript("OnEnterPressed", function(eb) Commit() eb:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(eb) Show() eb:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function() Commit() end)
    holder:EnableMouse(true)
    holder:SetScript("OnMouseDown", function() box:SetFocus() end)
    self:OnRefresh(function() if not box:HasFocus() then Show() end end)
    self.y = self.y + ROW_H + 4
    return box
end

-- A key binding: click it and press a key (with Shift, Ctrl or Alt held if wanted); Escape gives up, right-click
-- clears it. get returns the key ("SHIFT-F") or nil; set is given the key or nil. While it waits for a key the
-- button takes the keyboard and keeps every key: it never passes one on (SetPropagateKeyboardInput), since a key
-- passed on from addon code runs its binding tainted (the Escape error, 2026-10-02).
local MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }

function Builder:Key(text, get, set, width)
    width = width or 120
    Label(self, text, width)
    local t = self.t
    local button = BLib.MakeButton(self.parent, "", width, 20, t)
    button:SetPoint("TOPRIGHT", self.parent, "TOPLEFT", self.w - PAD, -self.y)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function Show()
        local key = get()
        button.label:SetText(button.waiting and "Press a key" or (key or "Not bound"))
        BLib.SetTC(button.label, (button.waiting or key) and t.text or t.subText)
    end
    local function Stop()
        button.waiting = false
        button:EnableKeyboard(false)
        button:SetScript("OnKeyDown", nil)
        Show()
    end
    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            if get() ~= nil then set(nil) self.changed() end
            Stop()
            return
        end
        if button.waiting then Stop() return end
        button.waiting = true
        button:EnableKeyboard(true)
        button:SetScript("OnKeyDown", function(_, key)
            if MODIFIERS[key] then return end
            if key == "ESCAPE" then Stop() return end
            local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "")
                .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
            if combo ~= get() then set(combo) self.changed() end
            Stop()
        end)
        Show()
    end)
    button:SetScript("OnHide", Stop)
    self:OnRefresh(Show)
    self.y = self.y + ROW_H + 4
    return button
end

-- onClick(button); width defaults to 200.
function Builder:Button(text, onClick, width)
    local button = BLib.MakeButton(self.parent, text, width or 200, 22, self.t)
    button:SetPoint("TOPLEFT", PAD, -self.y)
    button:SetScript("OnClick", function(b) onClick(b) end)
    self.y = self.y + 28
    return button
end

-- Several buttons sharing one row: list = { { text, onClick }, ... }.
function Builder:Buttons(list)
    local gap = 6
    local width = math.floor((self.w - PAD * 2 - gap * (#list - 1)) / #list)
    for i, item in ipairs(list) do
        local button = BLib.MakeButton(self.parent, item[1], width, 22, self.t)
        button:SetPoint("TOPLEFT", PAD + (i - 1) * (width + gap), -self.y)
        button:SetScript("OnClick", function(b) item[2](b) end)
    end
    self.y = self.y + 28
end

-- ============================================================
-- OPTIONS WINDOW (1.10.0)
-- An addon's settings in one BLib window: a list of pages on the left, with
-- headings, and the page chosen on the right, the way Foreverbound's was laid
-- out by hand, so every addon's settings look and move alike. A page is built
-- the first time it is shown. Every row on every built page reads its value
-- again when one row changes, when the window opens, and on win:Refresh()
-- (after a slash command or an import has changed something).
--
--   local win = BLib.NewOptionsWindow({
--       title    = "Satchel Settings",      -- the header; also names the frame
--       theme    = BLib.GetTheme("Satchel"),
--       width    = 780, height = 560,        -- the defaults
--       navWidth = 170,                      -- the page list
--       accordion = false,                   -- true: a heading folds and unfolds its pages, one open at a time
--       columns  = 1,                        -- 2: a builder for each of two columns
--       strata   = "HIGH",                   -- the default: popups (DIALOG) show above it
--       position = function() return left, bottom end,    -- nil: the centre
--       onMoved  = function(left, bottom) end,
--       onChange = function() end,           -- after any row changes a value
--       onSelect = function(id) end,         -- a page was chosen (to open on it next time)
--       onShow   = function() end, onHide = function() end,
--   })
--   win:AddPage({ id = "bags", title = "Bags", group = "Settings",   -- group: a heading above it in the list
--                 about = "A line or two under the page's title.",
--                 build = function(b, b2, page) b:Toggle(...) end,   -- b2 only with columns = 2
--                 label = function(page) return text, dimmed end })  -- optional: the list's text
--   win:AddPage({ id = "groups", title = "Groups", custom = true,     -- a page that draws itself
--                 bare = true, heading = "Quest List: Display",       -- bare: no title or line of the window's; or a
--                                                                     -- longer title than the list's
--                 build = function(body, width, page) return height end,
--                 refresh = function(body, page) end })
--   win:Open(id)   win:Toggle(id)   win:Select(id)   win:Refresh()
--   win:SetPageHeight(id, height)    a custom page that grew or shrank
--   win:IsShown()  win:Hide()  win.frame (once built)  win.current
-- ============================================================

local COL_GAP = 16
local NAV_ROW = 25

local Win = {}
Win.__index = Win

function BLib.NewOptionsWindow(spec)
    spec = spec or {}
    local win = setmetatable({ spec = spec, pages = {}, order = {} }, Win)
    win.t       = spec.theme or BLib.GetTheme()
    win.width   = spec.width or 780
    win.height  = spec.height or 560
    win.navW    = spec.navWidth or 170
    win.columns = spec.columns == 2 and 2 or 1
    win.accordion = spec.accordion and true or false
    return win
end

function Win:AddPage(page)
    if type(page) ~= "table" or page.id == nil or type(page.build) ~= "function" then
        error("BLib options window: a page needs an id and a build function", 2)
    end
    if self.pages[page.id] then error("BLib options window: two pages called " .. tostring(page.id), 2) end
    page.title = page.title or tostring(page.id)
    self.pages[page.id] = page
    self.order[#self.order + 1] = page
    if self.nav then self:LayoutNav() self:RefreshNav() end
    return page
end

-- The list: a heading wherever the group changes, then a row per page. Laid out
-- again when a page is added to a window already built.
function Win:LayoutNav()
    local t = self.t
    self.heads = self.heads or {}
    for _, fs in ipairs(self.heads) do fs:Hide() end
    local y, lastGroup, n = 8, false, 0
    for _, page in ipairs(self.order) do
        if page.group ~= lastGroup then
            lastGroup = page.group
            if page.group and self.accordion then
                -- A heading that folds and unfolds its pages.
                n = n + 1
                local head = self.heads[n]
                if not head then
                    head = BLib.MakeButton(self.nav, "", self.navW - 16, 24, t)
                    head.label:ClearAllPoints()
                    head.label:SetPoint("LEFT", head, "LEFT", 22, 0)
                    head.label:SetPoint("RIGHT", head, "RIGHT", -4, 0)
                    head.label:SetJustifyH("LEFT")
                    head.arrow = BLib.MakeFS(head, BLib.FONT_SM, t.subText)
                    head.arrow:SetPoint("LEFT", head, "LEFT", 8, 0)
                    head:SetScript("OnClick", function(b) self:ToggleGroup(b.group) end)
                    self.heads[n] = head
                end
                head.group = page.group
                head.label:SetText(page.group)
                head.arrow:SetText(self.expandedGroup == page.group and "v" or ">")
                head:ClearAllPoints()
                head:SetPoint("TOPLEFT", self.nav, "TOPLEFT", 8, -y)
                head:Show()
                y = y + NAV_ROW + 3
            elseif page.group then
                n = n + 1
                local head = self.heads[n] or BLib.MakeFS(self.nav, BLib.FONT_SM, t.subText)
                self.heads[n] = head
                head:ClearAllPoints()
                head:SetPoint("TOPLEFT", self.nav, "TOPLEFT", 12, -(y + 6))
                head:SetText(page.group)
                head:Show()
                y = y + 24
            end
        end
        local btn = self.navButtons[page.id]
        if not btn then
            btn = BLib.MakeButton(self.nav, page.title, self.navW - 16, 22, t)
            btn.label:ClearAllPoints()
            btn.label:SetPoint("LEFT", btn, "LEFT", 12, 0)
            btn.label:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
            btn.label:SetJustifyH("LEFT")
            btn.label:SetWordWrap(false)
            btn.mark = btn:CreateTexture(nil, "OVERLAY")
            BLib.SolidBase(btn.mark)
            BLib.SetVC(btn.mark, t.accent)
            btn.mark:SetSize(2, 14)
            btn.mark:SetPoint("LEFT", btn, "LEFT", 3, 0)
            btn.mark:Hide()
            local id = page.id
            btn:SetScript("OnClick", function() self:Select(id) end)
            self.navButtons[page.id] = btn
        end
        btn:ClearAllPoints()
        if self.accordion and page.group and self.expandedGroup ~= page.group then
            btn:Hide()
        else
            local x = self.accordion and page.group and 18 or 8
            btn:SetWidth(self.navW - x - 8)
            btn:SetPoint("TOPLEFT", self.nav, "TOPLEFT", x, -y)
            btn:Show()
            y = y + NAV_ROW
        end
    end
end

-- With an accordion: the heading folds or unfolds its pages, the others fold.
function Win:ToggleGroup(group)
    self.expandedGroup = (self.expandedGroup ~= group) and group or nil
    if self.nav then self:LayoutNav() end
end

-- The chosen page's row in the accent colour with a mark; a page whose label says
-- so (a bar switched off) dimmed.
function Win:RefreshNav()
    if not self.navButtons then return end
    local t = self.t
    for id, btn in pairs(self.navButtons) do
        local page = self.pages[id]
        local text, dim = page.title, false
        if page.label then
            local ok, a, b = pcall(page.label, page)
            if ok then text, dim = a or page.title, b end
        end
        local selected = self.current == id
        btn.mark:SetShown(selected)
        BLib.SetTC(btn.label, selected and t.accent or (dim and t.subText or t.text))
        btn.label:SetText(text)
    end
end

function Win:Build()
    if self.frame then return self.frame end
    local spec, t = self.spec, self.t
    local f, content = BLib.MakePopout(spec.title or "Settings", self.width, self.height, t, spec.onMoved,
        spec.strata or "HIGH")
    local left, bottom
    if spec.position then left, bottom = spec.position() end
    if type(left) == "number" and type(bottom) == "number" then
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    end
    -- A screen too short for it shrinks the window rather than clipping it.
    local fit = (UIParent:GetHeight() or self.height) / (self.height + 40)
    if fit < 1 then f:SetScale(math.max(fit, 0.6)) end
    tinsert(UISpecialFrames, f:GetName())
    self.frame = f
    f:HookScript("OnShow", function()
        self:Refresh()
        if spec.onShow then spec.onShow() end
    end)
    if spec.onHide then f:HookScript("OnHide", function() spec.onHide() end) end

    local nav = CreateFrame("Frame", nil, content)
    nav:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    nav:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    nav:SetWidth(self.navW)
    BLib.MakeBg(nav, t.headerBg)
    self.nav, self.navButtons = nav, {}
    self:LayoutNav()

    local scroll, scrollContent = BLib.MakeScrollFrame(content, self.width - 8 - self.navW - 8, self.height - 31, t)
    scroll:SetPoint("TOPLEFT", content, "TOPLEFT", self.navW + 8, 0)
    self.scroll, self.scrollContent = scroll, scrollContent
    self.pageW = scrollContent:GetWidth()
    return f
end

-- Returns false when the page's build raised: the error goes to the error handler, the half-built page is thrown
-- away, and the next Select tries again (a page kept half-built never grew its height, and its lower rows could
-- not be scrolled to; review, 2026-10-03).
function Win:BuildPage(page)
    if page.frame then return true end
    local t, w = self.t, self.pageW
    local frame = CreateFrame("Frame", nil, self.scrollContent)
    frame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, 0)
    frame:SetSize(w, 1)
    frame:Hide()
    page.frame, page.builders = frame, {}
    local ok = xpcall(function() self:FillPage(page, frame, t, w) end, geterrorhandler())
    if not ok then
        frame:Hide()
        page.frame, page.body, page.builders, page.head, page.height = nil, nil, nil, nil, nil
        return false
    end
    return true
end

-- The page's title, its line, and its rows (or what a custom page draws), then its height.
function Win:FillPage(page, frame, t, w)
    local head = 0
    if not page.bare then
        local title = BLib.MakeFS(frame, BLib.FONT_LG, t.accent)
        title:SetPoint("TOPLEFT", PAD, -10)
        title:SetText(page.heading or page.title)
        head = 34
    end
    if not page.bare and page.about and page.about ~= "" then
        local about = BLib.MakeFS(frame, BLib.FONT_SM, t.subText)
        about:SetPoint("TOPLEFT", PAD, -34)
        about:SetWidth(w - PAD * 2)
        about:SetJustifyH("LEFT")
        about:SetText(page.about)
        head = 34 + math.ceil(about:GetStringHeight() or 12) + 6
    end
    page.head = head

    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -head)
    body:SetSize(w, 1)
    page.body = body
    local height
    if page.custom then
        height = page.build(body, w, page)
    else
        local function Changed() self:Changed() end
        if self.columns == 2 then
            local colW = math.floor((w - COL_GAP) / 2)
            local left = CreateFrame("Frame", nil, body)
            left:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
            left:SetSize(colW, 1)
            local right = CreateFrame("Frame", nil, body)
            right:SetPoint("TOPLEFT", body, "TOPLEFT", colW + COL_GAP, 0)
            right:SetSize(colW, 1)
            local L = BLib.NewOptionsBuilder(left, t, colW, Changed)
            local R = BLib.NewOptionsBuilder(right, t, colW, Changed)
            page.builders = { L, R }
            page.build(L, R, page)
            height = math.max(L.y, R.y) + PAD
        else
            local b = BLib.NewOptionsBuilder(body, t, w, Changed)
            page.builders = { b }
            page.build(b, nil, page)
            height = b.y + PAD
        end
    end
    self:SetPageHeight(page.id, type(height) == "number" and height or body:GetHeight())
end

-- The page's body is `height` tall; the scroll range follows if it is the page shown.
function Win:SetPageHeight(id, height)
    local page = self.pages[id]
    if not (page and page.frame) then return end
    height = math.max(height or 1, 1)
    page.body:SetHeight(height)
    page.height = page.head + height
    page.frame:SetHeight(page.height)
    if self.current == id then
        self.scrollContent:SetHeight(page.height)
        if self.scroll.UpdateScroll then self.scroll.UpdateScroll() end
    end
end

local function RefreshPage(page)
    for _, b in ipairs(page.builders or {}) do b:Refresh() end
    if page.refresh then
        local ok, err = pcall(page.refresh, page.body, page)
        if not ok then geterrorhandler()(err) end
    end
end

function Win:Select(id)
    local page = self.pages[id] or self.order[1]
    if not page then return end
    self:Build()
    if not self:BuildPage(page) then return end
    if self.accordion and page.group and self.expandedGroup ~= page.group then
        self.expandedGroup = page.group
        self:LayoutNav()
    end
    local old = self.current and self.pages[self.current]
    if old and old ~= page and old.frame then old.frame:Hide() end
    self.current = page.id
    page.frame:Show()
    self.scrollContent:SetHeight(page.height or 1)
    self.scrollContent:GetParent():SetVerticalScroll(0)
    if self.scroll.UpdateScroll then self.scroll.UpdateScroll() end
    RefreshPage(page)
    self:RefreshNav()
    if self.spec.onSelect then self.spec.onSelect(page.id) end
end

-- Every built page's rows read their values again, and the list its labels.
function Win:Refresh()
    for _, page in ipairs(self.order) do
        if page.frame then RefreshPage(page) end
    end
    self:RefreshNav()
end

-- A row changed a value: it may show on another page too.
function Win:Changed()
    self:Refresh()
    if self.spec.onChange then self.spec.onChange() end
end

-- Opens on the page given, else the one last shown, else the first.
function Win:Open(id)
    self:Build()
    self.frame:Show()
    self:Select(id or self.current or (self.order[1] and self.order[1].id))
end

function Win:Toggle(id)
    if self:IsShown() and (id == nil or id == self.current) then
        self.frame:Hide()
        return false
    end
    self:Open(id)
    return true
end

function Win:IsShown() return self.frame ~= nil and self.frame:IsShown() end
function Win:Hide() if self.frame then self.frame:Hide() end end

-- ============================================================
-- POINTER PAGE
-- BLib.RegisterPointerPage(name, t, text, buttonText, open)
-- Options > AddOns > <name>: a title, a sentence, and a button that closes
-- Blizzard's settings and runs open(). Drawn the first time it is shown.
-- Returns the category, or nil on a client without the Settings API.
-- ============================================================

function BLib.RegisterPointerPage(name, t, text, buttonText, open)
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return nil end
    local panel = CreateFrame("Frame")
    panel:SetScript("OnShow", function(self)
        if self.built then return end
        self.built = true
        local title = BLib.MakeFS(self, BLib.FONT_LG, t.accent)
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(name)
        local note = BLib.MakeFS(self, BLib.FONT_SM, t.text)
        note:SetPoint("TOPLEFT", 16, -40)
        note:SetWidth(520)
        note:SetJustifyH("LEFT")
        note:SetText(text)
        local button = BLib.MakeButton(self, buttonText, math.max(200, #buttonText * 7 + 30), 24, t)
        button:SetPoint("TOPLEFT", 16, -70)
        button:SetScript("OnClick", function()
            if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
            open()
        end)
        self.title, self.note = title, note
    end)
    local category = Settings.RegisterCanvasLayoutCategory(panel, name)
    Settings.RegisterAddOnCategory(category)
    return category, panel
end
