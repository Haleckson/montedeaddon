--[[
  Forever Companion - UI/Dialogs.lua
  Themed modal dialogs: confirmation (dangerous operations), single-line
  prompt (names, tags, notes) and large text (export / import strings).
  Built in-house instead of StaticPopup to avoid tainting Blizzard dialogs.
]]

local _, FC = ...

local UI = FC.UI
local L = FC.L

local dim
local function ensureDim()
    if dim then return dim end
    dim = CreateFrame("Frame", nil, UIParent)
    dim:SetAllPoints(UIParent)
    dim:SetFrameStrata("DIALOG")
    dim:SetFrameLevel(1)
    dim:EnableMouse(true)
    dim.tex = dim:CreateTexture(nil, "BACKGROUND")
    dim.tex:SetAllPoints()
    dim.tex:SetColorTexture(0, 0, 0, 0.45)
    dim:Hide()
    return dim
end

local EDGE = 22 -- clear of the painted frame, with a strip of leather

local function baseDialog(name, width, height)
    local dialog = UI.Panel(UIParent, { name = name, strata = "DIALOG", bgAlpha = 0.99, skin = "window", corner = 20 })
    dialog:SetFrameLevel(20)
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER", 0, 80)
    dialog:EnableMouse(true)
    dialog:SetClampedToScreen(true)
    dialog.accent = UI.AccentLine(dialog)
    dialog.title = UI.Text(dialog, "header", "text")
    dialog.title:SetPoint("TOPLEFT", EDGE + 2, -(EDGE + 2))
    dialog.title:SetPoint("TOPRIGHT", -(EDGE + 2), -(EDGE + 2))
    dialog.text = UI.WrappedText(dialog, "body", "muted")
    dialog.text:SetPoint("TOPLEFT", dialog.title, "BOTTOMLEFT", 0, -10)
    dialog.text:SetPoint("TOPRIGHT", dialog.title, "BOTTOMRIGHT", 0, -10)
    dialog.accept = UI.Button(dialog, L.OK, { style = "primary", width = 110 })
    dialog.accept:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    dialog.cancel = UI.Button(dialog, L.CANCEL, { width = 100, onClick = function() dialog:Close() end })
    dialog.cancel:SetPoint("RIGHT", dialog.accept, "LEFT", -8, 0)
    -- Escape closes dialogs through UISpecialFrames (no keyboard capture needed)
    tinsert(UISpecialFrames, name)
    dialog:SetScript("OnHide", function()
        if dim then dim:Hide() end
    end)
    function dialog:Open()
        ensureDim():Show()
        UI.FitScale(self, FC.P.appearance.scale)
        UI.FadeIn(self, 0.12)
    end
    function dialog:Close()
        self:Hide()
    end
    dialog:Hide()
    return dialog
end

------------------------------------------------------------------------
-- Confirm
------------------------------------------------------------------------

local confirm

--- Confirmation dialog. danger = true styles the accept button red.
function UI.Confirm(title, text, acceptLabel, onAccept, danger)
    if not confirm then
        confirm = baseDialog("ForeverCompanionConfirm", 432, 182)
    end
    confirm.title:SetText(title or "")
    confirm.text:SetText(text or "")
    confirm.accept:SetLabel(acceptLabel or L.OK)
    confirm.accept:SetStyle(danger and "danger" or "primary")
    confirm.accept:SetScript("OnClick", function()
        confirm:Close()
        if onAccept then FC:SafeCall("confirm", onAccept) end
    end)
    local height = 122 + confirm.text:GetStringHeight()
    confirm:SetHeight(math.max(162, height))
    confirm:Open()
end

------------------------------------------------------------------------
-- Prompt
------------------------------------------------------------------------

local prompt

function UI.Prompt(title, text, default, onAccept, maxLetters)
    if not prompt then
        prompt = baseDialog("ForeverCompanionPrompt", 432, 192)
        prompt.input = UI.EditBox(prompt, { width = 384, height = 28 })
        prompt.input:SetPoint("BOTTOMLEFT", EDGE + 2, EDGE + 42)
        prompt.input:SetScript("OnEnterPressed", function() prompt.accept:Click() end)
    end
    prompt.title:SetText(title or "")
    prompt.text:SetText(text or "")
    prompt.input:SetMaxLetters(maxLetters or 120)
    prompt.input:SetText(default or "")
    prompt.accept:SetLabel(L.SAVE)
    prompt.accept:SetScript("OnClick", function()
        local value = prompt.input:GetText()
        prompt:Close()
        if onAccept then FC:SafeCall("prompt", onAccept, value) end
    end)
    prompt:Open()
    prompt.input:SetFocus()
    prompt.input:HighlightText()
end

------------------------------------------------------------------------
-- Large text (export / import)
------------------------------------------------------------------------

local textDialog

--- readOnly: shows text selected for copying. Otherwise onAccept(text) on Import.
function UI.TextDialog(title, text, readOnly, onAccept, hint)
    if not textDialog then
        textDialog = baseDialog("ForeverCompanionTextDialog", 572, 372)
        textDialog.box = UI.MultiLineEdit(textDialog, { width = 524, height = 220 })
        textDialog.box:SetPoint("TOPLEFT", EDGE + 2, -(EDGE + 60))
        textDialog.box.edit:SetScript("OnEscapePressed", function() textDialog:Close() end)
        textDialog.count = UI.Text(textDialog, "meta", "muted")
        textDialog.count:SetPoint("BOTTOMLEFT", EDGE + 2, EDGE + 6)
        textDialog.box.edit:HookScript("OnTextChanged", function(self)
            textDialog.count:SetText(FC.Utils.FormatNumber(#self:GetText()) .. " " .. L.CHARACTERS)
        end)
    end
    textDialog.title:SetText(title or "")
    textDialog.text:SetText(hint or (readOnly and L.EXPORT_HINT or L.IMPORT_HINT))
    textDialog.box:SetText(text or "")
    textDialog.readOnly = readOnly
    local edit = textDialog.box.edit
    if readOnly then
        edit:SetScript("OnChar", function(self) self:SetText(text or "") self:HighlightText() end)
        textDialog.accept:SetLabel(L.CLOSE)
        textDialog.accept:SetScript("OnClick", function() textDialog:Close() end)
        textDialog.cancel:Hide()
    else
        edit:SetScript("OnChar", nil)
        textDialog.accept:SetLabel(L.IMPORT)
        textDialog.cancel:Show()
        textDialog.accept:SetScript("OnClick", function()
            local value = edit:GetText()
            textDialog:Close()
            if onAccept then FC:SafeCall("import", onAccept, value) end
        end)
    end
    textDialog:Open()
    edit:SetFocus()
    if readOnly then edit:HighlightText() end
end
