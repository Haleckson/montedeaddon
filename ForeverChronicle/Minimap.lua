local _, namespace = ...
local FC = namespace.FC

local minimapButton

function FC:SetMinimapButtonVisible(visible)
    if not self.db or not self.db.settings then return end
    self.db.settings.minimap = visible and true or false
    if minimapButton then
        minimapButton:SetShown(self.db.settings.minimap)
    end
end

local function getMinimapRadius()
    local size = Minimap and Minimap.GetWidth and Minimap:GetWidth()
    size = tonumber(size) or 140
    -- Keep the complete button outside the map circle. The old fixed radius
    -- placed the icon inside larger Forever minimaps.
    -- Leave a small gap so the book sits beside the map instead of over its
    -- edge or quest text below it.
    return (size / 2) + 24
end

local function updatePosition()
    if not minimapButton or not FC.db then
        return
    end
    local angle = math.rad(FC.db.settings.minimapAngle or 225)
    local radius = getMinimapRadius()
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function updateFromCursor()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local dx = cursorX - centerX
    local dy = cursorY - centerY
    local angle
    if math.atan2 then
        angle = math.deg(math.atan2(dy, dx))
    else
        angle = math.deg(math.atan(dy / (dx == 0 and 0.0001 or dx)))
        if dx < 0 then
            angle = angle + 180
        end
    end
    FC.db.settings.minimapAngle = angle
    updatePosition()
end

local function createMinimapButton()
    -- Keep the button on UIParent. Some Classic minimap frames clip child
    -- regions, which made an otherwise correctly positioned icon look as if
    -- it were still inside the map.
    minimapButton = CreateFrame("Button", "ForeverChronicleMinimapButton", UIParent)
    minimapButton:SetSize(30, 30)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local backing = minimapButton:CreateTexture(nil, "BACKGROUND")
    backing:SetSize(31, 31)
    backing:SetPoint("CENTER", 0, 1)
    backing:SetTexture("Interface\\Buttons\\UI-ActionButton-Up")
    backing:SetVertexColor(0.48, 0.37, 0.20, 1)

    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(36, 36)
    border:SetPoint("CENTER", 0, 1)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(0.96, 0.72, 0.31, 1)

    minimapButton:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            StaticPopup_Show("FOREVER_CHRONICLE_ADD_NOTE")
        elseif FC.ToggleUI then
            FC:ToggleUI()
        elseif FC.Print then
            FC:Print("Chronicle window is unavailable. Try /reload.")
        end
    end)

    minimapButton:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", updateFromCursor)
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(FC.L.TITLE, 0.95, 0.74, 0.28)
        GameTooltip:AddLine(FC.L.MINIMAP_LEFT, 1, 1, 1)
        GameTooltip:AddLine(FC.L.MINIMAP_RIGHT, 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    updatePosition()
    minimapButton:SetShown(FC.db.settings.minimap ~= false)
end

FC:RegisterEvent("PLAYER_LOGIN", function()
    -- Move the old untouched lower-left default away from the quest tracker.
    if FC.db and FC.db.settings.minimapAngle == 225 then
        FC.db.settings.minimapAngle = 180
        if FC.TouchData then FC:TouchData("minimap-button-position") end
    end
    if not minimapButton then
        createMinimapButton()
    end
end)
