-- BLib_Widgets.lua
-- Higher-level UI widgets for BLib.
-- Depends on: BLib_Compat.lua, BLib_Core.lua, BLib_Scroll.lua

local ITEM_H      = 22
local MAX_VISIBLE = 7
local POPUP_MAX_H = ITEM_H * MAX_VISIBLE

-- Track the currently open dropdown so we can close it when another opens
local openDropdown = nil

-- Dropdown popups need a global name to register with UISpecialFrames.
-- A counter cannot collide; the old math.random name could.
local dropdownCount = 0

-- ============================================================
-- INPUT BOX
-- BLib.MakeInputBox(parent, w, h, t, placeholderText, onEnter)
-- Returns the EditBox frame.
-- ============================================================

function BLib.MakeInputBox(parent, w, h, t, placeholderText, onEnter)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(w, h or 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(64)
    BLib.SetFontSafe(box, BLib.FONT, BLib.FONT_MD, "")
    box:SetTextInsets(6, 6, 0, 0)
    box:SetTextColor(BLib.CR(t.text), BLib.CG(t.text), BLib.CB(t.text))

    local bg = BLib.MakeBg(box, t.buttonBg)
    BLib.ApplyBorder(box, box, t.buttonBorder)

    -- Placeholder. Deliberately dimmer than subText: at subText's brightness a
    -- hint reads as a value somebody typed, and people submit the form
    -- believing the example in the box is their answer.
    local ph
    if placeholderText then
        local phColour = t.placeholder or t.subText
        ph = box:CreateFontString(nil, "OVERLAY")
        BLib.SetFontSafe(ph, BLib.FONT, BLib.FONT_MD, "")
        ph:SetPoint("LEFT", box, "LEFT", 6, 0)
        ph:SetTextColor(BLib.CR(phColour), BLib.CG(phColour), BLib.CB(phColour))
        ph:SetText(placeholderText)
    end

    box:SetScript("OnEditFocusGained", function(self)
        BLib.SetVC(bg, t.panelBg)
        if ph then ph:Hide() end
    end)

    box:SetScript("OnEditFocusLost", function(self)
        BLib.SetVC(bg, t.buttonBg)
        if ph and self:GetText() == "" then ph:Show() end
    end)

    box:SetScript("OnTextChanged", function(self)
        if ph then
            if self:GetText() ~= "" then ph:Hide() else ph:Show() end
        end
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    box:SetScript("OnEnterPressed", function(self)
        local text = self:GetText():match("^%s*(.-)%s*$")
        if onEnter and text ~= "" then
            onEnter(text)
        end
        self:ClearFocus()
    end)

    return box
end

-- ============================================================
-- SLIDER
-- BLib.MakeSlider(parent, w, t, minValue, maxValue, step, initialValue, onChange)
--   w            : total width of the returned frame, including the value text
--   onChange     : function(value) called when the USER moves the slider
-- Returns the outer frame. Methods:
--   :SetValue(v) -- move the slider without firing onChange
--   :GetValue()
--
-- Built on a bare Slider with no Blizzard template: OptionsSliderTemplate is
-- deprecated on Mainline and the backdrop templates differ between clients,
-- so the track and thumb are drawn the same way as the scrollbar's.
-- ============================================================

local SLIDER_H   = 18
local TRACK_H    = 4
local THUMB_W    = 8
local THUMB_H    = 14
local VALUE_W    = 38

local function DecimalsFor(step)
    if not step or step >= 1 then return 0 end
    if step >= 0.1 then return 1 end
    return 2
end

-- Snap to the nearest step and round off float drift, so 0.5 + 7 * 0.1
-- reads as 1.2 rather than 1.2000000000000002.
local function SnapToStep(value, minValue, step, decimals)
    if step and step > 0 then
        value = minValue + math.floor(((value - minValue) / step) + 0.5) * step
    end
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

function BLib.MakeSlider(parent, w, t, minValue, maxValue, step, initialValue, onChange)
    w = w or 200
    minValue = minValue or 0
    maxValue = maxValue or 1
    local decimals = DecimalsFor(step)
    local trackW   = w - VALUE_W

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(w, SLIDER_H)

    -- Track
    local track = CreateFrame("Frame", nil, frame)
    track:SetSize(trackW, TRACK_H)
    track:SetPoint("LEFT", frame, "LEFT", 0, 0)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    BLib.SolidBase(trackBg)
    trackBg:SetAllPoints()
    BLib.SetVC(trackBg, t.panelBg)
    BLib.ApplyBorder(track, track, t.border)

    -- Value readout
    local valueText = BLib.MakeFS(frame, BLib.FONT_SM, t.subText)
    valueText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    valueText:SetWidth(VALUE_W)
    valueText:SetJustifyH("RIGHT")

    -- The slider itself, covering the track
    local slider = CreateFrame("Slider", nil, frame)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(trackW, SLIDER_H)
    slider:SetPoint("LEFT", frame, "LEFT", 0, 0)
    slider:SetMinMaxValues(minValue, maxValue)
    if step and step > 0 then
        slider:SetValueStep(step)
        -- Not present on every client; without it, dragging is continuous and
        -- SnapToStep in the handler still keeps reported values on-step.
        if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    end

    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumbTex = slider:GetThumbTexture()
    if thumbTex then
        BLib.SolidBase(thumbTex)
        thumbTex:SetSize(THUMB_W, THUMB_H)
        BLib.SetVC(thumbTex, t.accent)
    end

    slider:SetScript("OnEnter", function()
        if thumbTex then BLib.SetVC(thumbTex, t.text) end
    end)
    slider:SetScript("OnLeave", function()
        if thumbTex then BLib.SetVC(thumbTex, t.accent) end
    end)

    -- suppress is raised while we move the slider ourselves, so a programmatic
    -- SetValue (the Reset button) updates the display without calling back into
    -- the caller and re-applying settings it has already written.
    local suppress = false

    slider:SetScript("OnValueChanged", function(self, raw)
        local value = SnapToStep(raw, minValue, step, decimals)
        valueText:SetText(string.format("%." .. decimals .. "f", value))
        if not suppress and onChange then
            onChange(value)
        end
    end)

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local by = (step and step > 0) and step or ((maxValue - minValue) / 20)
        self:SetValue(math.max(minValue, math.min(maxValue, self:GetValue() + delta * by)))
    end)

    -- Public methods on the outer frame. Frame has no SetValue of its own,
    -- so there is nothing to shadow here.
    function frame:SetValue(v)
        suppress = true
        slider:SetValue(math.max(minValue, math.min(maxValue, v or minValue)))
        suppress = false
    end

    function frame:GetValue()
        return SnapToStep(slider:GetValue(), minValue, step, decimals)
    end

    function frame:SetEnabled(enabled)
        if enabled then slider:Enable() else slider:Disable() end
    end

    frame.slider = slider
    frame:SetValue(initialValue or minValue)

    return frame
end

-- ============================================================
-- DROPDOWN
-- BLib.MakeDropdown(parent, w, t, options, onChange)
--   options  = { { text = "Label", value = "value" }, ... }
--   onChange = function(value, text) ... end
-- Returns the trigger button. Has methods:
--   :SetSelected(value)   -- sets displayed text by value
--   :SetOptions(options)  -- replaces the option list
--   :Close()              -- closes popup if open
-- ============================================================

function BLib.MakeDropdown(parent, w, t, options, onChange)
    options = options or {}

    -- Trigger button
    local trigger = BLib.MakeButton(parent, "None", w, ITEM_H, t)

    -- Arrow indicator on the right of the trigger
    local arrow = trigger:CreateFontString(nil, "OVERLAY")
    BLib.SetFontSafe(arrow, BLib.FONT, BLib.FONT_SM, "")
    arrow:SetPoint("RIGHT", trigger, "RIGHT", -6, 0)
    arrow:SetTextColor(BLib.CR(t.subText), BLib.CG(t.subText), BLib.CB(t.subText))
    arrow:SetText("v")

    -- Left-align the label
    trigger.label:ClearAllPoints()
    trigger.label:SetPoint("LEFT", trigger, "LEFT", 6, 0)
    trigger.label:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    trigger.label:SetJustifyH("LEFT")

    -- Popup frame
    dropdownCount = dropdownCount + 1
    local popupName = "BLibDropdownPopup" .. dropdownCount
    local popup = CreateFrame("Frame", popupName, UIParent)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetClampedToScreen(true)
    popup:Hide()
    BLib.MakeBg(popup, t.panelBg)
    BLib.ApplyBorder(popup, popup, t.border)
    tinsert(UISpecialFrames, popupName)

    local currentOptions = options
    local itemButtons = {}
    local totalH = #currentOptions * ITEM_H
    local popupH = math.min(totalH, POPUP_MAX_H) + 2

    popup:SetWidth(w)
    popup:SetHeight(popupH)

    local scrollContainer, scrollContent = BLib.MakeScrollFrame(popup, w, popupH - 2, t)

    popup:SetScript("OnHide", function()
        if scrollContainer then
            scrollContainer:Hide()
        end
        openDropdown = nil
        arrow:SetText("v")
    end)
    scrollContainer:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -1)
    scrollContainer:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 0, 1)
    scrollContent:SetHeight(math.max(1, totalH))

    -- One button per row, made the first time a list is that long and reused
    -- by every list after it; rows past the current list are hidden. This
    -- used to make a whole new set on every SetOptions and only hide the old
    -- one, and frames are never freed, so a list refreshed on each visit grew
    -- all session (Satchel review S13, Muster review M8).
    local function BuildItems()
        local used = 0
        for i, opt in ipairs(currentOptions) do
            local item = itemButtons[i]
            if not item then
                item = BLib.MakeButton(scrollContent, opt.text, w - 18, ITEM_H, t)
                item:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -(i - 1) * ITEM_H)
                item.label:ClearAllPoints()
                item.label:SetPoint("LEFT", item, "LEFT", 6, 0)
                item.label:SetJustifyH("LEFT")
                -- The row's option is read at the click, since rows are reused.
                item:SetScript("OnClick", function()
                    local chosen = item.blibOption
                    trigger.label:SetText(chosen.text)
                    trigger._selectedValue = chosen.value
                    popup:Hide()
                    if onChange then onChange(chosen.value, chosen.text) end
                end)
                itemButtons[i] = item
            end
            item.blibOption = opt
            item.label:SetText(opt.text or "")
            item:Show()
            used = i
        end
        for i = used + 1, #itemButtons do
            itemButtons[i]:Hide()
        end

        local newTotalH = #currentOptions * ITEM_H
        local newPopupH = math.min(newTotalH, POPUP_MAX_H) + 2
        popup:SetWidth(w)
        popup:SetHeight(newPopupH)
        scrollContent:SetHeight(math.max(1, newTotalH))
        scrollContainer.UpdateScroll()
    end

    BuildItems()

    local function PositionPopup()
        local popupH = math.min(#currentOptions * ITEM_H, POPUP_MAX_H) + 2
        local triggerBottom = trigger:GetBottom()
        popup:ClearAllPoints()
        if triggerBottom and triggerBottom - popupH < 0 then
            popup:SetPoint("BOTTOMLEFT", trigger, "TOPLEFT", 0, 1)
        else
            popup:SetPoint("TOPLEFT", trigger, "BOTTOMLEFT", 0, -1)
        end
    end

    trigger:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            if openDropdown and openDropdown ~= popup then
                openDropdown:Hide()
            end
            PositionPopup()
            scrollContainer:Show()
            popup:Show()
            openDropdown = popup
            arrow:SetText("^")
        end
    end)

    -- Public methods
    function trigger:SetSelected(value)
        if value == nil or value == "" then
            self.label:SetText("None")
            self._selectedValue = nil
            return
        end
        for _, opt in ipairs(currentOptions) do
            if opt.value == value then
                self.label:SetText(opt.text)
                self._selectedValue = value
                return
            end
        end
        self.label:SetText("None")
        self._selectedValue = nil
    end

    function trigger:SetOptions(newOptions)
        currentOptions = newOptions
        self.label:SetText("None")
        self._selectedValue = nil
        BuildItems()
        if popup:IsShown() then
            PositionPopup()
        end
    end

    function trigger:Close()
        if popup:IsShown() then
            popup:Hide()
            if openDropdown == popup then openDropdown = nil end
            arrow:SetText("v")
        end
    end
    -- The list is parented to UIParent, so it outlives its button: close it when the button goes (a settings page
    -- switched, the window shut), or it floats on and still changes the hidden setting (review, 2026-10-03).
    trigger:HookScript("OnHide", function() trigger:Close() end)

    return trigger
end
-- ============================================================
-- THE COLOUR PICKER
--
-- Blizzard rewrote this in 10.2.5 and the rewrite is not backwards compatible.
-- The old way hung callbacks off ColorPickerFrame as fields, set the starting
-- colour with ColorPickerFrame:SetColorRGB and called Show(). The new way
-- passes one table to SetupColorPickerAndShow, which carries the colour and
-- opens the frame itself -- and SetColorRGB is simply gone, having moved to
-- ColorPickerFrame.Content.ColorPicker.
--
-- The asymmetry is the trap: GetColorRGB SURVIVED on the frame. So the getter
-- and the setter now live in different places, and code that assumes both
-- moved is as wrong as code that assumes neither did.
--
-- This exists because that fix had to be written TWICE on 2026-09-20, once in
-- Belphie's Dialogue and once in Belphie's Quest Log, from two identical
-- copies of the old pattern. Two bugs, one defect. The next time Blizzard
-- moves it, there is one place to change.
--
--   BLib.OpenColorPicker({
--       r = 1, g = 0.82, b = 0,
--       onChange = function(r, g, b) ... end,   -- picked, or live-dragged
--       onCancel = function(r, g, b) ... end,   -- optional; gets the ORIGINAL
--       hasOpacity = false,
--   })
--
-- With no onCancel, cancelling calls onChange with the original colour, which
-- is what "put it back" means for nearly every caller.
-- ============================================================

function BLib.OpenColorPicker(info)
    if type(info) ~= "table" then return false end
    if not ColorPickerFrame then return false end

    local startR = info.r or 1
    local startG = info.g or 1
    local startB = info.b or 1

    -- Read back through whichever door this client kept.
    local function Current()
        if ColorPickerFrame.GetColorRGB then
            local ok, r, g, b = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
            if ok and type(r) == "number" then return r, g, b end
        end

        local picker = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
        if picker and picker.GetColorRGB then
            local ok, r, g, b = pcall(picker.GetColorRGB, picker)
            if ok and type(r) == "number" then return r, g, b end
        end

        return startR, startG, startB
    end

    local function Apply()
        if info.onChange then info.onChange(Current()) end
    end

    local function Cancel()
        if info.onCancel then
            info.onCancel(startR, startG, startB)
        elseif info.onChange then
            info.onChange(startR, startG, startB)
        end
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = Apply,
            cancelFunc = Cancel,
            hasOpacity = info.hasOpacity and true or false,
            opacity    = info.opacity,
            r = startR, g = startG, b = startB,
        })
        return true
    end

    -- Pre-10.2.5. Kept so this file still works on an older client.
    ColorPickerFrame.hasOpacity  = info.hasOpacity and true or false
    ColorPickerFrame.opacityFunc = info.hasOpacity and Apply or nil
    ColorPickerFrame.func        = Apply
    ColorPickerFrame.swatchFunc  = Apply
    ColorPickerFrame.cancelFunc  = Cancel
    if ColorPickerFrame.SetColorRGB then
        ColorPickerFrame:SetColorRGB(startR, startG, startB)
    end
    ColorPickerFrame:Show()
    return true
end
