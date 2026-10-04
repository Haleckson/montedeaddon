local C = _G.Chronicle
local button
local RADIUS = 80
local DEFAULT_X, DEFAULT_Y = -.7071, -.7071

local function position(x, y)
    if not button or not Minimap then return end
    x, y = tonumber(x) or DEFAULT_X, tonumber(y) or DEFAULT_Y
    local length = math.sqrt(x * x + y * y)
    if length < .01 then x, y, length = DEFAULT_X, DEFAULT_Y, 1 end
    x, y = x / length, y / length
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * RADIUS, y * RADIUS)
end

local function updateDrag()
    if not button or not Minimap or not GetCursorPosition then return end
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY or scale == 0 then return end
    local x, y = cursorX / scale - centerX, cursorY / scale - centerY
    local length = math.sqrt(x * x + y * y)
    if length < 1 then return end
    x, y = x / length, y / length
    position(x, y)
    if C.db and C.db.settings then
        C.db.settings.minimapX, C.db.settings.minimapY = x, y
    end
end

local function createButton()
    if button or not Minimap then return button end
    button = CreateFrame("Button", "ChronicleMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Buttons\\WHITE8X8")
    background:SetVertexColor(.08, .045, .018, 1)
    background:SetSize(24, 24)
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
    icon:SetSize(26, 26)
    icon:SetPoint("CENTER")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function() if C.Toggle then C:Toggle() end end)
    button:SetScript("OnDragStart", function(self)
        if GameTooltip then GameTooltip:Hide() end
        self:SetScript("OnUpdate", updateDrag)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        updateDrag()
    end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(C.displayName, 1, .82, .1)
        GameTooltip:AddLine(C:L("minimapToggle"), 1, 1, 1)
        GameTooltip:AddLine(C:L("minimapDrag"), .72, .65, .52)
        C:ShowLocalizedTooltip()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    position()
    C.minimapButton = button
    return button
end

C:On("DATABASE_READY", function()
    if createButton() then
        local settings = C.db and C.db.settings
        position(settings and settings.minimapX, settings and settings.minimapY)
    end
end)

if Minimap then
    createButton()
else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", function(self)
        createButton()
        local settings = C.db and C.db.settings
        position(settings and settings.minimapX, settings and settings.minimapY)
        self:UnregisterEvent("PLAYER_LOGIN")
    end)
end
