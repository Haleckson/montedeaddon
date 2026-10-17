local C = _G.Chronicle
local button
local DEFAULT_X, DEFAULT_Y = -.7071, -.7071

function C:UpdateMinimapButtonVisibility()
    if not button then return end
    local settings = self.db and self.db.settings
    button:SetShown(not settings or settings.showMinimapButton ~= false)
end

local function edgeRadius()
    local width = Minimap and Minimap:GetWidth() or 140
    local height = Minimap and Minimap:GetHeight() or 140
    -- Keep the emblem centered on the actual rim, including scaled or resized minimaps.
    return math.max(40, math.min(width, height) * .5 + 7)
end

local function position(x, y)
    if not button or not Minimap then return end
    x, y = tonumber(x) or DEFAULT_X, tonumber(y) or DEFAULT_Y
    local length = math.sqrt(x * x + y * y)
    if length < .01 then x, y, length = DEFAULT_X, DEFAULT_Y, 1 end
    x, y = x / length, y / length
    button:ClearAllPoints()
    local radius = edgeRadius()
    button:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
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
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetVertexColor(.08, .045, .018, 1)
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

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
    if Minimap.HookScript then
        Minimap:HookScript("OnSizeChanged", function()
            local settings = C.db and C.db.settings
            position(settings and settings.minimapX, settings and settings.minimapY)
        end)
    end
    C.minimapButton = button
    C:UpdateMinimapButtonVisibility()
    return button
end

C:On("DATABASE_READY", function()
    if createButton() then
        local settings = C.db and C.db.settings
        position(settings and settings.minimapX, settings and settings.minimapY)
        C:UpdateMinimapButtonVisibility()
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
