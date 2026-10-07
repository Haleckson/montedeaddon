--[[
  Forever Companion - Map/Pins.lua
  World map pin mixin. The pin template itself is declared in Pins.xml
  (map canvas pools require a named template); all behavior lives here.

  A pin is a round category icon with a colored ring. Veiled (rumored)
  discoveries show a desaturated question mark instead of their icon, and
  their tooltip gives only the type and zone.
]]

local _, FC = ...

local Mixin = (CreateFromMixins and MapCanvasPinMixin) and CreateFromMixins(MapCanvasPinMixin) or {}
ForeverCompanionMapPinMixin = Mixin

local BASE_SIZE = 12 -- small enough to leave the map readable; the "Pin size" setting scales it

function Mixin:OnLoad()
    if self.UseFrameLevelType then pcall(self.UseFrameLevelType, self, "PIN_FRAME_LEVEL_AREA_POI") end
    if self.SetScalingLimits then pcall(self.SetScalingLimits, self, 1, 1.0, 1.25) end
    local C = FC.C
    self.ring = self:CreateTexture(nil, "BACKGROUND")
    self.ring:SetTexture(C.WHITE)
    self.ring:SetPoint("CENTER")
    if self.ring.SetMask then pcall(self.ring.SetMask, self.ring, C.CIRCLE_MASK) end
    self.shadow = self:CreateTexture(nil, "BACKGROUND", nil, -1)
    self.shadow:SetTexture(C.WHITE)
    self.shadow:SetPoint("CENTER", 0, -1)
    self.shadow:SetVertexColor(0, 0, 0, 0.6)
    if self.shadow.SetMask then pcall(self.shadow.SetMask, self.shadow, C.CIRCLE_MASK) end
    self.icon = self:CreateTexture(nil, "ARTWORK")
    self.icon:SetPoint("CENTER")
    if self.icon.SetMask then pcall(self.icon.SetMask, self.icon, C.CIRCLE_MASK) end
    self.glow = self:CreateTexture(nil, "HIGHLIGHT")
    self.glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    self.glow:SetBlendMode("ADD")
    self.glow:SetPoint("CENTER")
    self.guild = self:CreateTexture(nil, "OVERLAY")
    self.guild:SetTexture(C.WHITE)
    self.guild:SetPoint("BOTTOMRIGHT", 1, -1)
    if self.guild.SetMask then pcall(self.guild.SetMask, self.guild, C.CIRCLE_MASK) end

    self.pulseTex = self:CreateTexture(nil, "OVERLAY")
    self.pulseTex:SetTexture(C.WHITE)
    self.pulseTex:SetPoint("CENTER")
    if self.pulseTex.SetMask then pcall(self.pulseTex.SetMask, self.pulseTex, C.CIRCLE_MASK) end
    self.pulseTex:SetAlpha(0)
    local group = self.pulseTex:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.7)
    alpha:SetToAlpha(0)
    alpha:SetDuration(1.1)
    local scale = group:CreateAnimation("Scale")
    if scale.SetScaleFrom then
        scale:SetScaleFrom(1, 1)
        scale:SetScaleTo(2.2, 2.2)
    elseif scale.SetFromScale then
        scale:SetFromScale(1, 1)
        scale:SetToScale(2.2, 2.2)
    end
    scale:SetDuration(1.1)
    self.pulse = group
end

function Mixin:OnAcquired(rec, veiled, dotX, dotY)
    self.rec = rec
    self.veiled = veiled
    self.dot = dotX ~= nil
    local P = FC.P.map
    local size = BASE_SIZE * (P.iconScale or 1)
    if self.dot then
        -- a route point or an extra gathering spot: small ring, no icon
        local dotSize = math.max(4, size * 0.4)
        self:SetSize(dotSize, dotSize)
        self.shadow:SetSize(dotSize + 2, dotSize + 2)
        self.ring:SetSize(dotSize, dotSize)
        self.ring:SetVertexColor(FC.Utils.HexToRGB(rec.col or FC.Categories:Get(rec.t).color))
        self.icon:Hide()
        self.guild:Hide()
        self.glow:SetSize(dotSize * 2, dotSize * 2)
        self:SetAlpha((P.iconAlpha or 1) * 0.85)
        self:SetPosition(dotX, dotY)
        return
    end
    self.icon:Show()
    -- the colored ring stays about a fifth of the pin at every size
    local inner = size - math.max(2, math.floor(size * 0.2 + 0.5))
    local guildSize = math.max(3, size * 0.35)
    self:SetSize(size, size)
    self.shadow:SetSize(size + 2, size + 2)
    self.ring:SetSize(size, size)
    self.icon:SetSize(inner, inner)
    self.guild:SetSize(guildSize, guildSize)
    self.glow:SetSize(size * 1.8, size * 1.8)
    self.pulseTex:SetSize(size, size)
    local def = FC.Categories:Get(rec.t)
    local hex = rec.col or def.color
    if veiled then
        self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.icon:SetDesaturated(true)
        self.ring:SetVertexColor(0.55, 0.55, 0.6, 1)
    else
        self.icon:SetTexture(rec.ic or def.icon)
        self.icon:SetDesaturated(false)
        self.ring:SetVertexColor(FC.Utils.HexToRGB(hex))
    end
    self.pulseTex:SetVertexColor(FC.Utils.HexToRGB(hex))
    local mine = FC.Store:IsMine(rec)
    self.guild:SetShown(not mine)
    if not mine then self.guild:SetVertexColor(FC.Utils.HexToRGB(FC.UI.STATUS.guild.color)) end
    self:SetAlpha(P.iconAlpha or 1)
    self:SetPosition(rec.x, rec.y)
end

function Mixin:OnReleased()
    self.rec = nil
    if self.pulse then self.pulse:Stop() end
end

function Mixin:Pulse(seconds)
    if not self.pulse then return end
    self.pulse:Play()
    C_Timer.After(seconds or 4, function()
        if self.pulse then self.pulse:Stop() end
    end)
end

function Mixin:OnMouseEnter()
    local rec = self.rec
    if not rec then return end
    local UI, L, U = FC.UI, FC.L, FC.Utils
    local info = UI.Display(rec)
    local lines = { { UI.MetaLine(info), "muted" } }
    if not info.rumored then
        if info.subzone then lines[#lines + 1] = { info.subzone, "muted" } end
        if info.description then
            local text = info.description
            if #text > 140 then text = text:sub(1, 137) .. "..." end
            lines[#lines + 1] = { U.Escape(text), "text" }
        end
        local status = UI.STATUS[info.status.primary]
        lines[#lines + 1] = { UI.DiscoveredLine(info), status and status.color or "accent" }
        lines[#lines + 1] = { L.PIN_HINT, "muted" }
    else
        lines[#lines + 1] = { L.RUMORED_DESC, "muted" }
    end
    UI.ShowTooltip(self, U.Escape(info.title), lines, info.icon)
end

function Mixin:OnMouseLeave()
    FC.UI.HideTooltip()
end

function Mixin:OnClick(button)
    local rec = self.rec
    if not rec or button ~= "LeftButton" then return end
    if IsShiftKeyDown() and not self.veiled then
        FC.Waypoints:Set(rec)
    else
        FC.MainWindow:ShowDiscovery(rec.id)
    end
end
