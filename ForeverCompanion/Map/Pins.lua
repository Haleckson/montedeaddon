--[[
  Forever Companion - Map/Pins.lua
  World map pin mixin. The pin template itself is declared in Pins.xml
  (map canvas pools require a named template); all behavior lives here.

  The world-map pins are intentionally light-touch: mostly the icon itself,
  with optional outline and optional subtle backdrop driven by Map settings.
]]

local _, FC = ...

local Mixin = (CreateFromMixins and MapCanvasPinMixin) and CreateFromMixins(MapCanvasPinMixin) or {}
ForeverCompanionMapPinMixin = Mixin

local BASE_SIZE = 11

function Mixin:OnLoad()
    if self.icon then return end -- the map pool may call OnLoad again on first acquisition
    self:HookScript("OnHide", function(pin) if FC.Narrator then FC.Narrator:Leave(pin) end end)
    if self.UseFrameLevelType then pcall(self.UseFrameLevelType, self, "PIN_FRAME_LEVEL_AREA_POI") end
    if self.SetScalingLimits then pcall(self.SetScalingLimits, self, 1, 1.0, 1.25) end
    local C = FC.C

    self.shadow = self:CreateTexture(nil, "BACKGROUND", nil, -2)
    self.shadow:SetTexture(FC.PinArt.DOT)
    self.shadow:SetPoint("CENTER", 0, -1)
    self.shadow:SetVertexColor(0, 0, 0, 0)

    self.backdrop = self:CreateTexture(nil, "BACKGROUND", nil, -1)
    self.backdrop:SetTexture(FC.PinArt.DOT)
    self.backdrop:SetPoint("CENTER")
    self.backdrop:SetVertexColor(0, 0, 0, 0)

    self.iconOutline = self:CreateTexture(nil, "ARTWORK", nil, -1)
    self.iconOutline:SetPoint("CENTER")
    self.iconOutline:SetVertexColor(0, 0, 0, 0)
    if self.iconOutline.SetTexCoord then self.iconOutline:SetTexCoord(0.08, 0.92, 0.08, 0.92) end

    self.icon = self:CreateTexture(nil, "ARTWORK")
    self.icon:SetPoint("CENTER")
    self.icon:SetTexCoord(0, 1, 0, 1)

    self.glow = self:CreateTexture(nil, "HIGHLIGHT")
    self.glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    self.glow:SetBlendMode("ADD")
    self.glow:SetPoint("CENTER")

    self.guild = self:CreateTexture(nil, "OVERLAY")
    self.guild:SetAlpha(0)
    self.guild:Hide()

    self.pulseTex = self:CreateTexture(nil, "OVERLAY")
    self.pulseTex:SetTexture(FC.PinArt.PULSE)
    self.pulseTex:SetPoint("CENTER")
    self.pulseTex:SetAlpha(0)
    local group = self.pulseTex:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.35)
    alpha:SetToAlpha(0)
    alpha:SetDuration(1.1)
    local scale = group:CreateAnimation("Scale")
    if scale.SetScaleFrom then
        scale:SetScaleFrom(1, 1)
        scale:SetScaleTo(1.9, 1.9)
    elseif scale.SetFromScale then
        scale:SetFromScale(1, 1)
        scale:SetToScale(1.9, 1.9)
    end
    scale:SetDuration(1.1)
    self.pulse = group
end

function Mixin:OnAcquired(rec, veiled, dotX, dotY)
    if FC.Narrator then FC.Narrator:Leave(self) end
    self.pulseGeneration = (self.pulseGeneration or 0) + 1
    if self.pulse then self.pulse:Stop() end
    self.pulseTex:SetAlpha(0)
    self.rec = rec
    self.veiled = veiled
    self.dot = dotX ~= nil
    self.fcDotX, self.fcDotY = dotX, dotY
    self:ApplyAppearance()
    self:SetPosition(dotX or rec.x, dotY or rec.y)
end

-- Settings changes restyle the active pin without releasing its map position.
function Mixin:ApplyAppearance()
    local rec, veiled = self.rec, self.veiled
    if not rec then return end
    local P = FC.P.map
    local size = FC.PinArt:PixelSize(self, BASE_SIZE * (P.iconScale or 1))
    local def = FC.Categories:ForRecord(rec)
    local hex = rec.col or def.color
    local r, g, b = FC.Utils.HexToRGB(hex)
    local showBackdrop = P.pinBackdrop == true
    local outlineAlpha = math.max(0, math.min(0.8, tonumber(P.pinOutlineAlpha) or 0))
    local dotScale = P.dotScale or 1

    if self.dot then
        local dotSize = math.max(2, size * 0.22 * dotScale)
        self:SetSize(dotSize + 2, dotSize + 2)
        self.shadow:SetSize(dotSize + 2, dotSize + 2)
        self.shadow:SetVertexColor(0, 0, 0, 0)
        self.backdrop:SetSize(dotSize + 1, dotSize + 1)
        self.backdrop:SetVertexColor(r, g, b, 0.88)
        self.iconOutline:Hide()
        self.icon:Hide()
        self.guild:Hide()
        self.pulseTex:SetSize(dotSize + 2, dotSize + 2)
        self.pulseTex:SetVertexColor(r, g, b)
        self.glow:SetSize((dotSize + 2) * 1.8, (dotSize + 2) * 1.8)
        self:SetAlpha((P.iconAlpha or 1) * 0.92)
        return
    end

    self.iconOutline:SetShown(outlineAlpha > 0)
    self.icon:Show()
    self.guild:Hide()

    -- Scale the artwork all the way down; only the mouse target has a floor.
    local frameSize = size
    local iconSize = frameSize
    self:SetSize(math.max(10, frameSize + 2), math.max(10, frameSize + 2))
    self.shadow:SetSize(frameSize + 1, frameSize + 1)
    self.shadow:SetVertexColor(0, 0, 0, outlineAlpha > 0 and math.min(0.12, outlineAlpha * 0.35) or 0)
    self.backdrop:SetSize(showBackdrop and (frameSize + 1) or 1, showBackdrop and (frameSize + 1) or 1)
    self.backdrop:SetVertexColor(0.03, 0.04, 0.06, showBackdrop and 0.16 or 0)
    self.iconOutline:SetSize(iconSize + (outlineAlpha > 0 and 1 or 0), iconSize + (outlineAlpha > 0 and 1 or 0))
    self.iconOutline:SetVertexColor(0, 0, 0, outlineAlpha)
    self.icon:SetSize(iconSize, iconSize)
    self.glow:SetSize((frameSize + 2) * 1.5, (frameSize + 2) * 1.5)
    self.pulseTex:SetSize(frameSize + 1, frameSize + 1)

    FC.PinArt:Apply(self.icon, rec, veiled, iconSize)
    if outlineAlpha > 0 then FC.PinArt:Apply(self.iconOutline, rec, veiled, iconSize) end
    self.pulseTex:SetVertexColor(r, g, b)
    self:SetAlpha(P.iconAlpha or 1)
end

function Mixin:OnReleased()
    if FC.Narrator then FC.Narrator:Leave(self) end
    self.rec = nil
    self.fcDotX, self.fcDotY = nil, nil
    self.pulseGeneration = (self.pulseGeneration or 0) + 1
    if self.pulse then self.pulse:Stop() end
    if self.pulseTex then self.pulseTex:SetAlpha(0) end
end

function Mixin:Pulse(seconds)
    if not self.pulse then return end
    self.pulseGeneration = (self.pulseGeneration or 0) + 1
    local generation = self.pulseGeneration
    self.pulse:Play()
    C_Timer.After(seconds or 4, function()
        if self.pulse and self.pulseGeneration == generation then self.pulse:Stop() end
    end)
end

-- Both maps share the visual tooltip; only the world map starts narration.
function Mixin:ShowDiscoveryTooltip(compact)
    local rec = self.rec
    if not rec then return end
    local UI, L, U = FC.UI, FC.L, FC.Utils
    local info = UI.Display(rec)
    if compact then
        UI.ShowTooltip(self, U.Escape(info.title), nil, info.icon, nil, info.iconFallback)
        return info
    end
    local lines = { { UI.MetaLine(info), "muted" } }
    if not info.rumored then
        if info.subzone then lines[#lines + 1] = { info.subzone, "muted" } end
        if info.description then
            -- The tooltip wraps and grows to fit. Longer translations should
            -- carry the same description as English, without a character cut.
            lines[#lines + 1] = { U.Escape(info.description), "text" }
        end
        if info.lore then
            lines[#lines + 1] = { info.loreEntry.scope == "facts" and L.LORE_FIELD_NOTES or L.SECTION_DISCOVERY_LORE, "accent" }
            lines[#lines + 1] = { U.Escape(info.lore), "text" }
        end
        local status = UI.STATUS[info.status.primary]
        lines[#lines + 1] = { UI.DiscoveredLine(info), status and status.color or "accent" }
        lines[#lines + 1] = { L.PIN_HINT, "muted" }
    else
        lines[#lines + 1] = { L.RUMORED_DESC, "muted" }
    end
    UI.ShowTooltip(self, U.Escape(info.title), lines, info.icon, nil, info.iconFallback)
    return info
end

function Mixin:OnMouseEnter()
    local info = Mixin.ShowDiscoveryTooltip(self)
    if info and FC.Narrator then FC.Narrator:Hover(self, self.rec, info) end
end

function Mixin:OnMouseLeave()
    if FC.Narrator then FC.Narrator:Leave(self) end
    FC.UI.HideTooltip(self)
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
