--[[
  Forever Companion - UI/TargetButton.lua
  Small "Add discovery" button next to the target frame. It appears only
  for NPC targets outside combat, can be moved with Shift+drag and disabled
  in Settings > General.
]]

local _, FC = ...

local TargetButton = FC:NewModule("TargetButton")

local UI = FC.UI
local L = FC.L
local Compat = FC.Compat

function TargetButton:Build()
    if self.button then return end
    local button = UI.Button(UIParent, L.TARGET_BUTTON, {
        style = "primary", height = 20, autoWidth = true, width = 60,
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        onClick = function() FC.Editor:OpenNew() end,
    })
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(b) if IsShiftKeyDown() then b:StartMoving() end end)
    button:SetScript("OnDragStop", function(b)
        b:StopMovingOrSizing()
        local point, _, relPoint, x, y = b:GetPoint(1)
        FC.P.general.targetButton.point = { point, relPoint, x, y }
    end)
    UI.AttachTooltip(button, L.TARGET_BUTTON, L.TARGET_BUTTON_TIP)
    button:Hide()
    self.button = button
    self:Place()
end

function TargetButton:Place()
    local button = self.button
    local saved = FC.P.general.targetButton.point
    button:ClearAllPoints()
    if type(saved) == "table" and saved[1] then
        button:SetPoint(saved[1], UIParent, saved[2] or saved[1], saved[3] or 0, saved[4] or 0)
    elseif TargetFrame then
        button:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 24, 4)
    else
        button:SetPoint("TOP", UIParent, "TOP", 120, -120)
    end
end

function TargetButton:Update()
    if not FC.P.general.targetButton.show then
        if self.button then self.button:Hide() end
        return
    end
    self:Build()
    local info = Compat.GetUnitInfo("target")
    local show = info and not info.isPlayer and info.npcID and not Compat.InCombat()
    self.button:SetShown(show and true or false)
end

function TargetButton:OnEnable()
    FC.Events:Register("PLAYER_TARGET_CHANGED", self, self.Update)
    FC.Events:Register("PLAYER_REGEN_DISABLED", self, function() if self.button then self.button:Hide() end end)
    FC.Events:Register("PLAYER_REGEN_ENABLED", self, self.Update)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^general%.targetButton") then
            if self.button then self:Place() end
            self:Update()
        end
    end)
end
