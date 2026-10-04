local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}

local frame = CreateFrame("Frame", "FieldJournalObserveFrame", UIParent, "BackdropTemplate")
FieldJournal.ObserveFrame = frame

frame:SetFrameStrata("DIALOG")
frame:SetSize(460, 250)
frame:SetScale(0.75)
frame:SetPoint("CENTER")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    if self:IsMovable() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
frame:SetBackdropColor(0.07, 0.05, 0.02, 0.95)
frame:SetBackdropBorderColor(0.55, 0.42, 0.12, 1)

frame.inSession = false
frame.targetAvailable = false
frame.canObserve = false
frame.actionButtons = {}

-- =========================
-- OBSERVATION ACTION DEFINITIONS
-- =========================
local OBSERVE_ACTIONS = {
    [1] = {
        label = "Observation",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_02",
    },
    [2] = {
        label = "Field Sketch",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
    },
   [3] = {
    label = "Set Trap",
    icon = "Interface\\Icons\\Ability_Hunter_SnakeTrap",
},
}

-- =========================
-- QUICK TARGET BUTTON
-- =========================
frame.quickButton = CreateFrame("Button", "FieldJournalQuickObserveButton", UIParent, "UIPanelButtonTemplate")
frame.quickButton:SetSize(70, 20)
frame.quickButton:SetScale(1.2)
frame.quickButton:SetText("Observe")
frame.quickButton:Hide()

if TargetFrame then
    frame.quickButton:SetPoint("LEFT", TargetFrame, "RIGHT", 8, 0)
else
    frame.quickButton:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
end

frame.quickButton:SetScript("OnClick", function()
    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.StartObservation then
        FieldJournal.ObserveSystem:StartObservation()
    end
end)

-- =========================
-- HELPERS
-- =========================
local function StyleActionButton(button, active)
    if active then
        button:SetBackdropBorderColor(1, 0.82, 0, 1)
        button:SetScale(1.08)
        button.icon:SetVertexColor(1, 1, 1, 1)
        button.text:SetTextColor(1, 0.95, 0.6)
        button.glow:Show()
    else
        button:SetBackdropBorderColor(0.4, 0.3, 0.12, 1)
        button:SetScale(1.0)
        button.icon:SetVertexColor(0.75, 0.75, 0.75, 1)
        button.text:SetTextColor(1, 1, 1)
        button.glow:Hide()
    end
end

local function CreateText(parent, point, relPoint, x, y, fontObject)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    fs:SetPoint(point, parent, relPoint or point, x or 0, y or 0)
    return fs
end

-- =========================
-- MAIN WINDOW TEXT
-- =========================
frame.title = CreateText(frame, "TOP", "TOP", 0, -12, "GameFontNormalLarge")
frame.title:SetText("Field Study")

frame.targetText = CreateText(frame, "TOP", "TOP", 0, -40, "GameFontNormal")
frame.targetText:SetText("Target: --")

frame.statusText = CreateText(frame, "TOP", "TOP", 0, -62, "GameFontHighlight")
frame.statusText:SetText("")

frame.promptText = CreateText(frame, "TOP", "TOP", 0, -82, "GameFontHighlight")
frame.promptText:SetText("")

-- =========================
-- PROGRESS BAR
-- =========================
frame.bar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
frame.bar:SetSize(400, 18)
frame.bar:SetPoint("TOP", frame, "TOP", 0, -108)
frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
frame.bar:SetMinMaxValues(0, 22)
frame.bar:SetValue(0)
frame.bar:SetStatusBarColor(0.85, 0.62, 0.15, 1)
frame.bar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
frame.bar:SetBackdropColor(0.12, 0.09, 0.03, 1)
frame.bar:SetBackdropBorderColor(0.45, 0.33, 0.1, 1)

frame.barText = CreateText(frame.bar, "CENTER", "CENTER", 0, 0, "GameFontHighlightSmall")
frame.barText:SetText("")

-- =========================
-- CANCEL BUTTON
-- =========================
frame.cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.cancelButton:SetSize(120, 28)
frame.cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
frame.cancelButton:SetText("Stop")
frame.cancelButton:SetScript("OnClick", function()
    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.CancelObservation then
        FieldJournal.ObserveSystem:CancelObservation("Cancelled.")
    end
end)

-- Kept for compatibility, but hidden because observation starts from the target-frame quick button.
frame.startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.startButton:SetSize(120, 28)
frame.startButton:SetPoint("BOTTOM", frame, "BOTTOM", -70, 18)
frame.startButton:SetText("Observe")
frame.startButton:Hide()
frame.startButton:SetScript("OnClick", function()
    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.StartObservation then
        FieldJournal.ObserveSystem:StartObservation()
    end
end)

-- =========================
-- ICON ACTION BUTTONS
-- =========================
for i = 1, 3 do
    local action = OBSERVE_ACTIONS[i]

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetSize(86, 62)

    button:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button:SetBackdropColor(0.12, 0.09, 0.03, 1)
    button:SetBackdropBorderColor(0.4, 0.3, 0.12, 1)

    button.glow = button:CreateTexture(nil, "BACKGROUND")
    button.glow:SetPoint("CENTER")
    button.glow:SetSize(58, 58)
    button.glow:SetColorTexture(1, 0.82, 0, 0.22)
    button.glow:Hide()

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("TOP", button, "TOP", 0, -7)
    button.icon:SetTexture(action.icon)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("TOP", button.icon, "BOTTOM", 0, -3)
    button.text:SetText(action.label)

    local index = i
    button:SetScript("OnClick", function()
        if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.PressPromptButton then
            FieldJournal.ObserveSystem:PressPromptButton(index)
        end
    end)

    button:Hide()
    button:Disable()

    frame.actionButtons[i] = button
end

frame.actionButtons[1]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 64, 52)
frame.actionButtons[2]:SetPoint("BOTTOM", frame, "BOTTOM", 0, 52)
frame.actionButtons[3]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -64, 52)

-- =========================
-- FRAME METHODS
-- =========================
function frame:SetSystem(system)
    self.system = system
end

function frame:PlayStartEmote()
    -- Emote intentionally disabled.
end

function frame:ShowVisualMode()
end

function frame:HideVisualMode()
end

function frame:HideActionButtons()
    for _, button in ipairs(self.actionButtons) do
        button:Hide()
        button:Disable()
        StyleActionButton(button, false)
    end
end

function frame:ShowActionButtons()
    for _, button in ipairs(self.actionButtons) do
        button:Show()
        button:Disable()
        StyleActionButton(button, false)
    end
end

function frame:ClearPrompt()
    self.promptText:SetText("Waiting for the cue...")

    for _, button in ipairs(self.actionButtons) do
        button:Disable()
        StyleActionButton(button, false)
    end
end

function frame:UpdateTargetState(hasTarget, targetName, canObserve, reason)
    self.targetAvailable = hasTarget
    self.targetName = targetName
    self.canObserve = canObserve

    if self.inSession then
        self.quickButton:Hide()
        return
    end

    if hasTarget and canObserve then
        self.quickButton:Show()
        self.quickButton:Enable()
    else
        self.quickButton:Hide()
    end

    if not self.inSession then
        self:Hide()
    end
end

function frame:StartSession(targetName, duration, promptDelay)
    self.inSession = true
    self.currentDuration = duration
    self.endTime = GetTime() + duration
    self.promptDelay = promptDelay

    self.quickButton:Hide()

    self:ShowVisualMode()

    self.targetText:SetText("Studying: " .. (targetName or "Unknown"))
    self.statusText:SetText("Observation in progress.")
    self.promptText:SetText("Waiting for the cue...")

    self.startButton:Hide()
    self.cancelButton:Show()
    self.cancelButton:Enable()

    self.bar:Show()
    self.barText:Show()
    self.bar:SetMinMaxValues(0, duration)
    self.bar:SetValue(duration)

    self:ShowActionButtons()
    self:Show()
end

function frame:ShowPrompt(index, label, windowDuration)
    self.currentPromptIndex = index
    self.promptText:SetText("React now.")
    self.statusText:SetText("Choose the glowing tool.")

    for i, button in ipairs(self.actionButtons) do
        button:Enable()
        StyleActionButton(button, i == index)
    end
end

function frame:EndSession(success, message)
    self.inSession = false
    self.currentDuration = nil
    self.endTime = nil
    self.currentPromptIndex = nil

    self:HideVisualMode()

    self.statusText:SetText(message or (success and "Observation complete." or "Observation interrupted."))
    self.cancelButton:Hide()
    self.startButton:Hide()

    self.bar:Hide()
    self.barText:Hide()
    self:ClearPrompt()
    self:HideActionButtons()
    self:Hide()

    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.RefreshTargetState then
        FieldJournal.ObserveSystem:RefreshTargetState()
    end
end

frame:SetScript("OnUpdate", function(self)
    if not self.inSession or not self.endTime then
        return
    end

    if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.ValidateActiveSession then
        FieldJournal.ObserveSystem:ValidateActiveSession()
        if not self.inSession then
            return
        end
    end

    local remaining = self.endTime - GetTime()
    if remaining < 0 then
        remaining = 0
    end

    self.bar:SetValue(remaining)
    self.barText:SetText(string.format("%.1f", remaining))
    self.statusText:SetText(string.format("Time remaining: %.1fs", remaining))
end)

frame:Hide()
frame.quickButton:Hide()