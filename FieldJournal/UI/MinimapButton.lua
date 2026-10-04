local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.UI = FieldJournal.UI or {}

local UI = FieldJournal.UI

-- =========================
-- SAVED POSITION
-- =========================
FieldJournalDB = FieldJournalDB or {}
FieldJournalDB.config = FieldJournalDB.config or {}

local DEFAULT_ANGLE = 225
FieldJournalDB.config.minimapButtonAngle = FieldJournalDB.config.minimapButtonAngle or DEFAULT_ANGLE

-- =========================
-- MINIMAP POSITION HELPER
-- =========================
local function UpdateMinimapButtonPosition(button)
    local angle = FieldJournalDB.config.minimapButtonAngle or DEFAULT_ANGLE
    local radians = math.rad(angle)

    -- Seat the visible round button against the outer minimap rim. Using its
    -- half-width keeps the book close without placing its center on the map.
    local minimapRadius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2
    local radius = minimapRadius + button:GetWidth() / 2 + 2

    local x = math.cos(radians) * radius
    local y = math.sin(radians) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function SaveMinimapButtonPosition(button)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    px = px / scale
    py = py / scale

    local angle = math.deg(math.atan2(py - my, px - mx))

    if angle < 0 then
        angle = angle + 360
    end

    FieldJournalDB.config.minimapButtonAngle = angle

    UpdateMinimapButtonPosition(button)
end

-- =========================
-- MINIMAP BUTTON
-- =========================
local button = CreateFrame("Button", "FieldJournalMinimapButton", Minimap)
UI.MinimapButton = button

button:SetSize(40, 40)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")

-- =========================
-- BUTTON TEXTURE
-- =========================
button.icon = button:CreateTexture(nil, "ARTWORK")
button.icon:SetSize(25, 25)
button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
button.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

button.overlay = button:CreateTexture(nil, "OVERLAY")
button.overlay:SetSize(67.5, 67.5)
button.overlay:SetPoint("CENTER", button, "CENTER", 12.5, -12.5)
button.overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
button.highlight:SetSize(40, 40)
button.highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
button.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button.highlight:SetBlendMode("ADD")

-- =========================
-- TOOLTIP
-- =========================
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Field Journal", 1.0, 0.82, 0.0)
    GameTooltip:AddLine("Left-click to open or close your Field Journal.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move this button.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- =========================
-- CLICK / DRAG
-- =========================
button:SetScript("OnClick", function()
    if button.isDragging then
        return
    end

    if FieldJournal.UI
        and FieldJournal.UI.JournalFrame
        and FieldJournal.UI.JournalFrame.Toggle then

        FieldJournal.UI.JournalFrame:Toggle()
    else
        print("|cffcc0000[Field Journal]|r Journal UI is not loaded.")
    end
end)

button:SetScript("OnDragStart", function(self)
    self.isDragging = true
    GameTooltip:Hide()

    self:SetScript("OnUpdate", function(dragButton)
        SaveMinimapButtonPosition(dragButton)
    end)
end)

button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)

    C_Timer.After(0.05, function()
        self.isDragging = false
    end)
end)

-- =========================
-- INITIAL POSITION
-- =========================
UpdateMinimapButtonPosition(button)
