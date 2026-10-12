--[[
  Forever Companion - UI/MinimapButton.lua
  Minimap launcher (drag around the minimap edge) and the Blizzard addon
  compartment entry (declared in the TOC, handled by the globals below).

    Left click   open / close the journal
    Right click  open settings
    Shift click  quick discovery at your position
]]

local _, FC = ...

local MinimapButton = FC:NewModule("MinimapButton")

local UI = FC.UI
local L = FC.L
local C = FC.C
local U = FC.Utils

local RADIUS_PAD = 10

local function onClick(button)
    if IsShiftKeyDown() then
        FC.Editor:OpenNew()
    elseif button == "MiddleButton" then
        FC.ZoneGuide:Toggle()
    elseif button == "RightButton" then
        FC.SettingsWindow:Toggle()
    else
        FC.MainWindow:Toggle()
    end
end

local function tooltipAnchor()
    local angle = (FC.P and FC.P.general and FC.P.general.minimap and FC.P.general.minimap.angle) or 215
    angle = angle % 360
    if angle >= 45 and angle < 135 then return "ANCHOR_TOP" end
    if angle >= 135 and angle < 225 then return "ANCHOR_LEFT" end
    if angle >= 225 and angle < 315 then return "ANCHOR_BOTTOM" end
    return "ANCHOR_RIGHT"
end

local function showTooltip(owner)
    local stats = FC.Store:Stats()
    if not GameTooltip then
        UI.ShowTooltip(owner, L.ADDON_NAME, {
            { string.format(L.FOOTER_ENTRIES, U.FormatNumber(stats.total)), "text" },
            { L.MINIMAP_LEFT, "muted" },
            { L.MINIMAP_RIGHT, "muted" },
            { L.MINIMAP_SHIFT, "muted" },
            { L.MINIMAP_MIDDLE, "muted" },
        }, nil)
        return
    end
    UI.SetTooltipOwner(owner, tooltipAnchor())
    GameTooltip:ClearLines()
    UI.AddTooltipLine(GameTooltip, L.ADDON_NAME, 1, 0.82, 0)
    UI.AddTooltipLine(GameTooltip, string.format(L.FOOTER_ENTRIES, U.FormatNumber(stats.total)), 0.92, 0.92, 0.92)
    UI.AddTooltipLine(GameTooltip, L.MINIMAP_LEFT, 0.75, 0.75, 0.75, true)
    UI.AddTooltipLine(GameTooltip, L.MINIMAP_RIGHT, 0.75, 0.75, 0.75, true)
    UI.AddTooltipLine(GameTooltip, L.MINIMAP_SHIFT, 0.75, 0.75, 0.75, true)
    UI.AddTooltipLine(GameTooltip, L.MINIMAP_MIDDLE, 0.75, 0.75, 0.75, true)
    GameTooltip:Show()
end

function MinimapButton:UpdatePosition()
    local button = self.button
    if not button or not Minimap then return end
    local angle = math.rad(FC.P.general.minimap.angle or 215)
    local x, y = math.cos(angle), math.sin(angle)
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local w = (Minimap:GetWidth() / 2) + RADIUS_PAD
    local h = (Minimap:GetHeight() / 2) + RADIUS_PAD
    if shape == "SQUARE" then
        x = math.max(-1, math.min(1, x * 1.41))
        y = math.max(-1, math.min(1, y * 1.41))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * w, y * h)
end

function MinimapButton:Build()
    if self.button or not Minimap then return end
    local button = CreateFrame("Button", "ForeverCompanionMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button:RegisterForDrag("LeftButton")
    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    button.background:SetSize(22, 22)
    button.background:SetPoint("CENTER")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(C.MEDIA .. "Logo")
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("CENTER")
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetSize(54, 54)
    button.border:SetPoint("TOPLEFT")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, mouseButton) onClick(mouseButton) end)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", UI.HideTooltip)
    button:SetScript("OnDragStart", function(b)
        b:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            FC.P.general.minimap.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
            self:UpdatePosition()
        end)
    end)
    button:SetScript("OnDragStop", function(b) b:SetScript("OnUpdate", nil) end)
    self.button = button
end

function MinimapButton:Apply()
    if FC.P.general.minimap.show then
        self:Build()
        if self.button then
            local clean = FC.PinArt and FC.PinArt:Launcher(self.button.icon, 24)
            self.button.icon:SetSize(clean and 24 or 20, clean and 24 or 20)
            self.button.background:SetShown(not clean)
            self.button.border:SetShown(not clean)
            self.button:Show()
            self:UpdatePosition()
        end
    elseif self.button then
        self.button:Hide()
    end
end

function MinimapButton:OnEnable()
    self:Apply()
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path == "map" or path == "map.pinArtwork" or path:find("^general%.minimap") then self:Apply() end
    end)
end

-- Addon compartment (TOC: AddonCompartmentFunc / OnEnter / OnLeave)
function ForeverCompanion_OnAddonCompartmentClick(_, mouseButton)
    if FC.enabled then onClick(mouseButton) end
end

function ForeverCompanion_OnAddonCompartmentEnter(_, owner)
    if FC.enabled and owner then showTooltip(owner) end
end

function ForeverCompanion_OnAddonCompartmentLeave(_, owner)
    UI.HideTooltip(owner)
end
