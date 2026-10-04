-- BLib_Dock.lua
-- A panel that sits against the edge of another window -- Blizzard's
-- auction house, bank, trainer or profession window, or another addon's --
-- and shows what an addon has to offer there. Forgemaster's redesign
-- (docs/forgemaster-redesign-layout.md, section 4) is built on these.
-- Depends on: BLib_Compat.lua, BLib_Core.lua
--
--   local panel = BLib.MakeDockPanel(title, t, opts)
--   opts: { width = 300, strata = "HIGH", gap = 4,
--           footer = { text = "Open Forgemaster", onClick = fn },
--           onClose = fn }                    after the close button
--   panel.content                             the area to fill
--   panel:DockTo(target)   beside target: its right edge if there is room on
--                          screen, its left otherwise. Shows the panel, unless
--                          it was closed during this visit to target. Returns
--                          true when shown.
--   panel:FitContent(h)    sizes the panel to h of content, no taller than the
--                          target; returns the content height it got
--   panel:SetCollapsed(on) folds it to its header (the "-" button does this)
--   panel:Undock()         hides it and forgets the target
--
-- A visit ends when the target hides: the panel goes with it, and a panel
-- closed during the visit may show again next time.

BLib = BLib or {}

local HEADER_H = 24
local FOOTER_H = 20

local function Hover(b, t, on)
    local c = on and t.buttonHover or t.buttonBg
    b.bg:SetVertexColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), BLib.CA(c))
end

-- The target's size and edges in the panel's own units, which differ when
-- either has been scaled.
local function InPanelUnits(panel, target, v)
    return v * target:GetEffectiveScale() / panel:GetEffectiveScale()
end

function BLib.MakeDockPanel(title, t, opts)
    opts = opts or {}
    local width = opts.width or 300
    local gap = opts.gap or 4

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(width, 120)
    f:SetFrameStrata(opts.strata or "HIGH")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()
    BLib.MakeRaisable(f)
    BLib.MakeBg(f, t.frameBg)
    BLib.ApplyBorder(f, f, t.border)
    f:HookScript("OnShow", function(self)
        BLib.RefreshBorder(self)
        BLib.QueueSnapToPixels(self)
    end)

    -- -------------------------------------------------- header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_H)
    BLib.MakeBg(header, t.headerBg)
    local rule = header:CreateTexture(nil, "BORDER")
    BLib.SolidBase(rule)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    BLib.SetVC(rule, t.border)

    local titleFS = BLib.MakeFS(header, BLib.FONT_SM, t.accent)
    titleFS:SetPoint("LEFT", header, "LEFT", 8, 0)
    titleFS:SetText(title)
    f.titleFS = titleFS

    local close = BLib.MakeButton(header, "x", 18, 18, t)
    close:SetPoint("RIGHT", header, "RIGHT", -3, 0)
    BLib.SetTC(close.label, t.subText)
    close:SetScript("OnClick", function()
        f.dismissedFor = f.target
        f:Hide()
        if opts.onClose then opts.onClose() end
    end)
    close:SetScript("OnEnter", function(self)
        Hover(self, t, true)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Close for this visit")
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function(self)
        Hover(self, t, false)
        GameTooltip:Hide()
    end)

    local fold = BLib.MakeButton(header, "-", 18, 18, t)
    fold:SetPoint("RIGHT", close, "LEFT", -3, 0)
    BLib.SetTC(fold.label, t.subText)
    fold:SetScript("OnClick", function() f:SetCollapsed(not f.collapsed) end)
    f.header, f.closeBtn, f.foldBtn = header, close, fold

    titleFS:SetPoint("RIGHT", fold, "LEFT", -6, 0)
    titleFS:SetJustifyH("LEFT")
    titleFS:SetWordWrap(false)

    -- -------------------------------------------------- footer
    local footerH = 0
    if opts.footer then
        footerH = FOOTER_H
        local link = CreateFrame("Button", nil, f)
        link:SetPoint("BOTTOMLEFT", 6, 3)
        link:SetSize(width - 12, FOOTER_H - 4)
        local fs = BLib.MakeFS(link, BLib.FONT_SM, t.subText)
        fs:SetPoint("LEFT")
        fs:SetText(opts.footer.text)
        link:SetScript("OnEnter", function() BLib.SetTC(fs, t.accent) end)
        link:SetScript("OnLeave", function() BLib.SetTC(fs, t.subText) end)
        link:SetScript("OnClick", function() opts.footer.onClick() end)
        f.footer = link
    end

    -- -------------------------------------------------- content
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 4, -HEADER_H - 4)
    content:SetPoint("BOTTOMRIGHT", -4, footerH + 4)
    f.content = content
    f.contentWidth = width - 8

    local contentH = 120 - HEADER_H - footerH - 8

    local function MaxContent()
        local target = f.target
        if not target then return math.huge end
        local h = InPanelUnits(f, target, target:GetHeight() or 0)
        return math.max(40, h - HEADER_H - footerH - 8)
    end

    function f:FitContent(h)
        contentH = math.min(h, MaxContent())
        if not self.collapsed then
            self:SetHeight(contentH + HEADER_H + footerH + 8)
        end
        return contentH
    end

    function f:SetCollapsed(on)
        self.collapsed = on and true or false
        content:SetShown(not self.collapsed)
        if self.footer then self.footer:SetShown(not self.collapsed) end
        fold.label:SetText(self.collapsed and "+" or "-")
        self:SetHeight(self.collapsed and (HEADER_H + 2) or (contentH + HEADER_H + footerH + 8))
    end

    local hooked = {}

    function f:DockTo(target)
        if not target then return false end
        if self.target ~= target then
            self.target = target
            self.dismissedFor = nil
        end
        if not hooked[target] then
            hooked[target] = true
            target:HookScript("OnHide", function()
                if f.target ~= target then return end
                f.dismissedFor = nil
                f:Hide()
            end)
        end
        if self.dismissedFor == target or not target:IsVisible() then return false end

        -- The right edge if the panel fits between it and the screen's edge,
        -- else the left.
        local right = target:GetRight()
        local screenRight = InPanelUnits(self, UIParent, UIParent:GetRight() or 0)
        if screenRight <= 0 then screenRight = math.huge end   -- not laid out yet: assume room
        local roomRight = right and (InPanelUnits(self, target, right) + gap + width <= screenRight)
        self:ClearAllPoints()
        if roomRight or not right then
            self:SetPoint("TOPLEFT", target, "TOPRIGHT", gap, 0)
        else
            self:SetPoint("TOPRIGHT", target, "TOPLEFT", -gap, 0)
        end
        self:Show()
        return true
    end

    function f:Undock()
        self.target, self.dismissedFor = nil, nil
        self:Hide()
    end

    return f
end
