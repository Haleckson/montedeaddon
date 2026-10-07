--[[
  Forever Companion - UI/Controls.lua
  Input controls built on the framework: FCCheckbox, checkbox grid, FCSlider,
  FCDropdown, FCColorPicker (swatch), segmented control and context menus.

  Controls bind to getter/setter functions, never to settings directly, so
  the same widgets work for the settings window, the editor and filters.
  Every control has :Refresh() to re-read its value (profile switches).
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local Theme = FC.Theme
local Compat = FC.Compat
local WHITE = FC.C.WHITE

------------------------------------------------------------------------
-- Menu (shared popup used by dropdowns and context menus)
------------------------------------------------------------------------

local menu, catcher
local MENU_ROW = 22
local MENU_MAX_ROWS = 14

local function ensureMenu()
    if menu then return menu end
    catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN")
    catcher:RegisterForClicks("AnyUp")
    catcher:SetScript("OnClick", function() UI.CloseMenu() end)
    catcher:Hide()

    menu = UI.Panel(UIParent, { name = "ForeverCompanionMenu", strata = "FULLSCREEN_DIALOG", bgAlpha = 0.98, skin = "panel", corner = 10 })
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu.rows = {}
    menu.offset = 0
    menu:SetScript("OnMouseWheel", function(self, delta)
        local maxOffset = math.max(0, #self.items - MENU_MAX_ROWS)
        self.offset = U.Clamp(self.offset - delta, 0, maxOffset)
        UI.RenderMenu()
    end)
    -- whoever opened the menu hears when it closes (a toast waits for it)
    menu:SetScript("OnHide", function(self)
        local onHide = self.fcOnHide
        self.fcOnHide = nil
        if onHide then FC:SafeCall("menu:hide", onHide) end
    end)
    menu:Hide()
    return menu
end

local function menuRow(index)
    local row = menu.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, menu)
    row:SetHeight(MENU_ROW)
    row.hover = UI.Texture(row, "HIGHLIGHT", "accent", 0.16)
    row.hover:SetAllPoints()
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(14, 14)
    row.check:SetPoint("LEFT", 6, 0)
    Theme:Tint(row.check, "accent")
    row.icon = UI.Icon(row, 14)
    row.icon:SetPoint("LEFT", 24, 0)
    row.label = UI.Text(row, "body", "text")
    row.label:SetPoint("LEFT", 24, 0)
    row.label:SetPoint("RIGHT", -8, 0)
    row.divider = UI.Divider(row, "border")
    row.divider:SetPoint("LEFT", 6, 0)
    row.divider:SetPoint("RIGHT", -6, 0)
    row:SetScript("OnClick", function(self)
        local item = self.item
        if not item or item.disabled or item.isTitle or item.divider then return end
        UI.CloseMenu()
        if item.onClick then FC:SafeCall("menu", item.onClick, item.value, item) end
    end)
    menu.rows[index] = row
    return row
end

function UI.RenderMenu()
    local items = menu.items
    local count = math.min(#items, MENU_MAX_ROWS)
    for i = 1, count do
        local item = items[i + menu.offset]
        local row = menuRow(i)
        row.item = item
        row:ClearAllPoints()
        local pad = menu.fcPainted and 7 or 4
        row:SetPoint("TOPLEFT", pad, -pad - (i - 1) * MENU_ROW)
        row:SetPoint("TOPRIGHT", -pad, -pad - (i - 1) * MENU_ROW)
        row:Show()
        row.divider:SetShown(item.divider == true)
        row.check:SetShown(item.checked == true)
        row.label:SetShown(not item.divider)
        if item.icon then
            row.icon:Show()
            UI.SetIcon(row.icon, item.icon)
            row.label:SetPoint("LEFT", 44, 0)
        else
            row.icon:Hide()
            row.label:SetPoint("LEFT", 24, 0)
        end
        row.label:SetText(item.text or "")
        if item.isTitle then
            Theme:Paint(row.label, "accent")
            row.label:SetFontObject(FC.Fonts:Get("meta"))
        else
            Theme:Paint(row.label, item.disabled and "muted" or (item.danger and "danger" or "text"))
            row.label:SetFontObject(FC.Fonts:Get("body"))
        end
        row.hover:SetShown(not (item.isTitle or item.divider or item.disabled))
    end
    for i = count + 1, #menu.rows do menu.rows[i]:Hide() end
    menu:SetHeight(count * MENU_ROW + (menu.fcPainted and 14 or 8))
end

--- items: { { text, value, icon, checked, disabled, danger, isTitle, divider, onClick(value, item) } }
--- onHide() runs when the menu closes, whichever way.
function UI.OpenMenu(anchor, items, width, onHide)
    ensureMenu()
    -- a menu replaced by another one has closed for its owner
    local previous = menu:IsShown() and menu.fcOnHide
    menu.fcOnHide = nil
    if previous then FC:SafeCall("menu:hide", previous) end
    menu.fcOnHide = onHide
    menu.items = items
    menu.offset = 0
    menu:SetScale(FC.P.appearance.scale)
    local w = width or 180
    for _, item in ipairs(items) do
        if item.text then
            local probe = menuRow(1).label
            probe:SetText(item.text)
            w = math.max(w, probe:GetStringWidth() + (item.icon and 60 or 40))
        end
    end
    menu:SetWidth(math.min(w, 360))
    menu:ClearAllPoints()
    if anchor == "cursor" then
        local x, y = GetCursorPosition()
        local scale = menu:GetEffectiveScale()
        menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    else
        menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    end
    UI.RenderMenu()
    catcher:Show()
    menu:Show()
end

function UI.CloseMenu()
    if menu then menu:Hide() end
    if catcher then catcher:Hide() end
end

------------------------------------------------------------------------
-- Checkbox
------------------------------------------------------------------------

function UI.Checkbox(parent, label, get, set, tooltip)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(22)
    row.box = CreateFrame("Frame", nil, row)
    row.box:SetSize(16, 16)
    row.box:SetPoint("LEFT")
    row.box.bg = UI.Texture(row.box, "BACKGROUND", "bg", 0.9)
    row.box.bg:SetAllPoints()
    UI.AddBorder(row.box, "border")
    row.check = row.box:CreateTexture(nil, "ARTWORK")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetPoint("CENTER")
    row.check:SetSize(18, 18)
    Theme:Tint(row.check, "accent")
    row.label = UI.Text(row, "body", "text")
    row.label:SetPoint("LEFT", row.box, "RIGHT", 8, 0)
    row.label:SetText(label or "")
    row:SetWidth(row.label:GetStringWidth() + 30)
    row.hover = UI.Texture(row, "HIGHLIGHT", "text", 0.04)
    row.hover:SetAllPoints()
    function row:Refresh()
        local value = get()
        self.check:SetShown(value and true or false)
        UI.SetBorderColor(self.box, value and "accent" or "border", value and 0.8 or 1)
    end
    function row:SetDisabled(disabled)
        self.fcDisabled = disabled
        self:SetAlpha(disabled and 0.4 or 1)
    end
    row:SetScript("OnClick", function(self)
        if self.fcDisabled then return end
        set(not get())
        self:Refresh()
    end)
    if tooltip then UI.AttachTooltip(row, label, tooltip) end
    row:Refresh()
    return row
end

------------------------------------------------------------------------
-- Checkbox grid
------------------------------------------------------------------------

--- Checkboxes in columns. items: { { text, icon, get(), set(value) } }.
--- Returns the frame and its height; frame:Refresh() re-reads every box.
function UI.CheckGrid(parent, items, width, columns)
    local frame = CreateFrame("Frame", nil, parent)
    columns = columns or 2
    local columnWidth = math.floor(width / columns)
    local rowHeight = 24
    frame.boxes = {}
    for i, item in ipairs(items) do
        local label = item.text or ""
        if item.icon then label = "|T" .. item.icon .. ":14:14:0:0:64:64:5:59:5:59|t  " .. label end
        local box = UI.Checkbox(frame, label, item.get, item.set, item.tip)
        box:SetPoint("TOPLEFT", ((i - 1) % columns) * columnWidth, -math.floor((i - 1) / columns) * rowHeight)
        frame.boxes[i] = box
    end
    local height = math.ceil(#items / columns) * rowHeight
    frame:SetSize(width, height)
    function frame:Refresh()
        for _, box in ipairs(self.boxes) do box:Refresh() end
    end
    return frame, height
end

------------------------------------------------------------------------
-- Slider
------------------------------------------------------------------------

function UI.Slider(parent, label, minValue, maxValue, step, get, set, formatter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(260, 40)
    frame.label = UI.Text(frame, "body", "text")
    frame.label:SetPoint("TOPLEFT")
    frame.label:SetText(label or "")
    frame.value = UI.Text(frame, "body", "accent")
    frame.value:SetPoint("TOPRIGHT")
    local slider = CreateFrame("Slider", nil, frame)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("BOTTOMLEFT", 0, 4)
    slider:SetPoint("BOTTOMRIGHT", 0, 4)
    slider:SetHeight(14)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider.track = UI.Texture(slider, "BACKGROUND", "border", 1)
    slider.track:SetPoint("LEFT")
    slider.track:SetPoint("RIGHT")
    slider.track:SetHeight(4)
    slider.fill = UI.Texture(slider, "ARTWORK", "accent", 0.9)
    slider.fill:SetPoint("LEFT", slider.track, "LEFT")
    slider.fill:SetHeight(4)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(10, 14)
    Theme:Paint(thumb, "text", 1)
    slider:SetThumbTexture(thumb)
    slider:EnableMouseWheel(true)
    frame.slider = slider

    local function format(v)
        if formatter then return formatter(v) end
        if step < 1 then return string.format("%.2f", v) end
        return tostring(math.floor(v + 0.5))
    end
    local function updateFill(v)
        local width = slider:GetWidth()
        if width and width > 0 then
            slider.fill:SetWidth(math.max(1, (v - minValue) / (maxValue - minValue) * width))
        end
    end
    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        frame.value:SetText(format(v))
        updateFill(v)
        if frame.fcUpdating then return end
        set(v)
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(U.Clamp(self:GetValue() + delta * step, minValue, maxValue))
    end)
    slider:SetScript("OnSizeChanged", function() updateFill(slider:GetValue()) end)
    function frame:Refresh()
        self.fcUpdating = true
        local v = tonumber(get()) or minValue
        slider:SetValue(v)
        self.value:SetText(format(v))
        updateFill(v)
        self.fcUpdating = false
    end
    frame:Refresh()
    return frame
end

------------------------------------------------------------------------
-- Dropdown
------------------------------------------------------------------------

--- items: array or function returning { { value, text, icon } }
function UI.Dropdown(parent, label, items, get, set, width)
    local frame = CreateFrame("Frame", nil, parent)
    width = width or 220
    frame:SetSize(width, label and 46 or 26)
    if label then
        frame.label = UI.Text(frame, "body", "text")
        frame.label:SetPoint("TOPLEFT")
        frame.label:SetText(label)
    end
    local button = CreateFrame("Button", nil, frame)
    button:SetPoint("BOTTOMLEFT")
    button:SetPoint("BOTTOMRIGHT")
    button:SetHeight(26)
    button.bg = UI.Texture(button, "BACKGROUND", "bg", 0.85)
    button.bg:SetAllPoints()
    UI.AddBorder(button, "border")
    button.hover = UI.Texture(button, "HIGHLIGHT", "text", 0.05)
    button.hover:SetAllPoints()
    button.icon = UI.Icon(button, 16)
    button.icon:SetPoint("LEFT", 7, 0)
    button.text = UI.Text(button, "body", "text")
    button.text:SetPoint("LEFT", 8, 0)
    button.text:SetPoint("RIGHT", -22, 0)
    button.arrow = button:CreateTexture(nil, "ARTWORK")
    button.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    button.arrow:SetSize(12, 12)
    button.arrow:SetPoint("RIGHT", -7, -2)
    Theme:Tint(button.arrow, "muted")
    frame.button = button
    -- text, icon and arrow stay inside the well's rim (journal style)
    button.fcOnSkin = function(self, rim)
        self.fcRim = rim
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", math.max(7, rim), 0)
        self.text:SetPoint("LEFT", math.max(8, rim) + (self.icon:IsShown() and 20 or 0), 0)
        self.text:SetPoint("RIGHT", -math.max(22, rim + 16), 0)
        self.arrow:ClearAllPoints()
        self.arrow:SetPoint("RIGHT", -math.max(7, rim), -2)
    end
    UI.SkinInput(button)

    local function list()
        return type(items) == "function" and items() or items
    end

    function frame:Refresh()
        local current = get()
        local text, icon = tostring(current or ""), nil
        for _, item in ipairs(list()) do
            if item.value == current then
                text, icon = item.text, item.icon
                break
            end
        end
        button.text:SetText(text)
        local rim = button.fcRim or 0
        if icon then
            button.icon:Show()
            UI.SetIcon(button.icon, icon)
            button.text:SetPoint("LEFT", math.max(8, rim) + 20, 0)
        else
            button.icon:Hide()
            button.text:SetPoint("LEFT", math.max(8, rim), 0)
        end
    end
    function frame:SetDisabled(disabled)
        self.fcDisabled = disabled
        self:SetAlpha(disabled and 0.4 or 1)
    end

    button:SetScript("OnClick", function()
        if frame.fcDisabled then return end
        local current = get()
        local menuItems = {}
        for _, item in ipairs(list()) do
            menuItems[#menuItems + 1] = {
                text = item.text, value = item.value, icon = item.icon,
                checked = item.value == current, isTitle = item.isTitle, divider = item.divider,
                onClick = function(value)
                    set(value)
                    frame:Refresh()
                end,
            }
        end
        UI.OpenMenu(button, menuItems, button:GetWidth())
    end)
    frame:Refresh()
    return frame
end

------------------------------------------------------------------------
-- Color swatch (FCColorPicker)
------------------------------------------------------------------------

function UI.ColorSwatch(parent, label, getHex, setHex, onReset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(240, 24)
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(34, 18)
    swatch:SetPoint("LEFT")
    swatch.color = swatch:CreateTexture(nil, "ARTWORK")
    swatch.color:SetPoint("TOPLEFT", 2, -2)
    swatch.color:SetPoint("BOTTOMRIGHT", -2, 2)
    swatch.color:SetTexture(WHITE)
    swatch.bg = UI.Texture(swatch, "BACKGROUND", "bg", 1)
    swatch.bg:SetAllPoints()
    UI.AddBorder(swatch, "border")
    row.swatch = swatch
    row.label = UI.Text(row, "body", "text")
    row.label:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
    row.label:SetText(label or "")
    row.hex = UI.Text(row, "meta", "muted")
    row.hex:SetPoint("LEFT", row.label, "RIGHT", 8, 0)
    if onReset then
        row.reset = UI.IconButton(row, "Interface\\Buttons\\UI-RefreshButton", 18, FC.L.RESET, function()
            onReset()
            row:Refresh()
        end)
        row.reset:SetPoint("RIGHT")
    end
    function row:Refresh()
        local hex = getHex() or "ffffff"
        swatch.color:SetColorTexture(U.HexToRGB(hex))
        self.hex:SetText("#" .. hex:upper())
    end
    swatch:SetScript("OnClick", function()
        local r, g, b = U.HexToRGB(getHex() or "ffffff")
        Compat.OpenColorPicker(r, g, b, function(nr, ng, nb)
            setHex(U.RGBToHex(nr, ng, nb))
            row:Refresh()
        end)
    end)
    row:Refresh()
    return row
end

------------------------------------------------------------------------
-- Segmented control
------------------------------------------------------------------------

--- options: { { value, text, icon } }
function UI.Segmented(parent, options, get, set, width)
    local frame = CreateFrame("Frame", nil, parent)
    width = width or 240
    frame:SetSize(width, 26)
    frame.buttons = {}
    local segment = width / #options
    for i, option in ipairs(options) do
        local button = UI.Button(frame, option.text, {
            width = segment - (i < #options and 2 or 0), height = 26, icon = option.icon,
            onClick = function()
                set(option.value)
                frame:Refresh()
            end,
        })
        button:SetPoint("LEFT", (i - 1) * segment, 0)
        button.value = option.value
        frame.buttons[i] = button
    end
    function frame:Refresh()
        local current = get()
        for _, button in ipairs(self.buttons) do
            button:SetStyle(button.value == current and "primary" or "secondary")
        end
    end
    frame:Refresh()
    return frame
end
