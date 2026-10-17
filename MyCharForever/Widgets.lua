local addonName, MCF = ...
-- Shared window kit: the single source for the look of every MyCharForever window (colors, backdrop,
-- window frame with title / close button, section card with header band). Settings, the dungeon view,
-- the level windows, journal, export and the list windows are all built from these functions, so a
-- change of style happens here and nowhere else.
-- Loaded right after Localization.lua; uses nothing but that file.

local Kit = {}
MCF.Kit = Kit

Kit.BACKDROP = {bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14, insets = {left = 3, right = 3, top = 3, bottom = 3}}
Kit.WINDOW_BG = {0.10, 0.075, 0.055, 0.98}
Kit.CARD_BG = {0.06, 0.045, 0.03, 0.95}
Kit.BORDER = {0.49, 0.34, 0.17, 1}
Kit.GOLD = {0.95, 0.75, 0.22}
Kit.TITLE = {0.75, 0.6, 0.3}
Kit.BAND = {0.20, 0.14, 0.05, 0.85}
Kit.BAND_HOVER = {0.30, 0.21, 0.07, 0.9}
Kit.BAND_LINE = {0.75, 0.55, 0.10, 0.8}
Kit.BAND_H = 26
Kit.FOOTER_H = 52   -- space reserved at the bottom of a window for its buttons
Kit.TOP_H = 38      -- space reserved at the top for the title

-- The font sizes the player can choose: value, German name, English name (one list for Settings, UI and Welcome).
MCF.FontScaleChoices={{0.8,"Klein (80 %)","Small (80 %)"},{1,"Normal (100 %)","Normal (100 %)"},{1.2,"Groß (120 %)","Large (120 %)"}}

-- "Screenshots cannot be shown in the game" hint: ONE text (Localization keys) used by every "?" in the addon.
-- short=true uses the shorter wording. Hint.Mark is the text variant for rows that are already hover targets.
Kit.Hint = {Mark = "|cff66ccff(?)|r"}
function Kit.Hint.Text(short) return MCF:T(short and "Screenshot display hint short" or "Screenshot display hint") end
function Kit.Hint.Show(owner, short)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(Kit.Hint.Text(short), 1, 1, 1, 1, true)
    GameTooltip:Show()
end
-- Small clickless "?" button with the tooltip; the caller anchors it.
function Kit.Hint.Button(parent, short)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(16, 16)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER"); fs:SetText("?"); fs:SetTextColor(0.4, 0.8, 1)
    b:SetScript("OnEnter", function(self) fs:SetTextColor(1, 1, 1); Kit.Hint.Show(self, short) end)
    b:SetScript("OnLeave", function() fs:SetTextColor(0.4, 0.8, 1); GameTooltip:Hide() end)
    return b
end

function Kit.IsGerman() return MCF.GetLanguage and MCF:GetLanguage() == "deDE" end
function Kit.CloseText() return Kit.IsGerman() and "Schließen" or "Close" end

-- Bordered panel in the common colors.
function Kit.Panel(parent, bg)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop(Kit.BACKDROP)
    local c = bg or Kit.CARD_BG
    f:SetBackdropColor(c[1], c[2], c[3], c[4])
    f:SetBackdropBorderColor(unpack(Kit.BORDER))
    return f
end

-- Gold header band. Returns the button; band.label is its text, band:SetLabel(text) changes it.
-- The caller anchors and sizes the button.
function Kit.Band(parent, onClick)
    local band = CreateFrame("Button", nil, parent)
    band:SetHeight(Kit.BAND_H)
    local bg = band:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(unpack(Kit.BAND))
    local line = band:CreateTexture(nil, "ARTWORK"); line:SetColorTexture(unpack(Kit.BAND_LINE)); line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")
    band.label = band:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    band.label:SetPoint("LEFT", 8, 0); band.label:SetTextColor(unpack(Kit.GOLD))
    function band:SetLabel(text) self.label:SetText(text) end
    band:SetScript("OnEnter", function() bg:SetColorTexture(unpack(Kit.BAND_HOVER)) end)
    band:SetScript("OnLeave", function() bg:SetColorTexture(unpack(Kit.BAND)) end)
    if onClick then band:SetScript("OnClick", onClick) else band:EnableMouse(false) end
    return band
end

-- Card = bordered panel + header band. Returns the panel; panel.band and panel.body (content host,
-- starts below the band) are attached to it. The caller sets width/height and the position.
function Kit.Card(parent, onClick)
    local card = Kit.Panel(parent)
    card.band = Kit.Band(card, onClick)
    card.band:SetPoint("TOPLEFT", 4, -4); card.band:SetPoint("TOPRIGHT", -4, -4)
    card.body = CreateFrame("Frame", nil, card)
    card.body:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -(Kit.BAND_H + 8))
    card.body:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -(Kit.BAND_H + 8))
    card.body:SetHeight(1)
    return card
end

-- Window. o = {w, h, title, level, strata, scroll=true, close=false (no bottom close button)}.
--   f.title      gold title font string (top left)
--   f.content    area between title and footer (for fixed layouts)
--   f.scroll/f.child  scroll frame and its scroll child, when o.scroll
--   f.closeButton     labeled button bottom right (unless o.close == false); the X is always there
-- Logo and addon name at the top of an own popup (it takes Kit.BRAND_H of height): it is clearly not a game message.
Kit.BRAND_H = 26
function Kit.Brand(frame)
    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(20, 20); logo:SetPoint("TOPLEFT", 12, -8)
    logo:SetTexture(MCF.LOGO_PATH)
    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", logo, "RIGHT", 6, 0); name:SetText(MCF.BRAND_NAME)
    return logo, name
end

function Kit.Window(name, o)
    o = o or {}
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(o.w or 600, o.h or 400); f:SetPoint("CENTER")
    f:SetFrameStrata(o.strata or "FULLSCREEN_DIALOG"); f:SetFrameLevel(o.level or 800)
    f:SetBackdrop(Kit.BACKDROP); f:SetBackdropColor(unpack(Kit.WINDOW_BG)); f:SetBackdropBorderColor(unpack(Kit.BORDER))
    MCF.MakeOpaque(f, 4)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetToplevel(true)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 18, -14); f.title:SetTextColor(unpack(Kit.TITLE))
    if o.title then f.title:SetText(o.title) end
    f.closeX = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeX:SetPoint("TOPRIGHT", -3, -3); f.closeX:SetFrameLevel(f:GetFrameLevel() + 20)
    f.closeX:SetScript("OnClick", function() f:Hide() end)
    local footer = 14
    if o.close ~= false then
        footer = Kit.FOOTER_H
        f.closeButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.closeButton:SetSize(120, 24); f.closeButton:SetPoint("BOTTOMRIGHT", -18, 16)
        f.closeButton:SetText(Kit.CloseText())
        f.closeButton:SetScript("OnClick", function() f:Hide() end)
        f:HookScript("OnShow", function() f.closeButton:SetText(Kit.CloseText()) end)
    end
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 14, -Kit.TOP_H); f.content:SetPoint("BOTTOMRIGHT", -14, o.footer or footer)
    if o.scroll then
        f.scroll = CreateFrame("ScrollFrame", o.scrollName, f, "UIPanelScrollFrameTemplate")
        f.scroll:SetPoint("TOPLEFT", 14, -Kit.TOP_H); f.scroll:SetPoint("BOTTOMRIGHT", -32, o.footer or footer)
        f.child = CreateFrame("Frame", o.childName, f.scroll)
        f.child:SetSize((o.w or 600) - 50, 100)
        f.scroll:SetScrollChild(f.child)
        f.content:Hide()
    end
    if name then tinsert(UISpecialFrames, name) end
    f:Hide()
    return f
end

-- Plain label (gold, for field captions) inside a window or card.
function Kit.Label(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y); fs:SetText(text or ""); fs:SetTextColor(unpack(Kit.GOLD))
    return fs
end

-- Tab / Shift+Tab moves between the given edit boxes (in order, wrapping around). Use it in every window with
-- more than one text field; the game does not do this by itself.
function Kit.TabOrder(boxes)
    local n = #boxes
    if n < 2 then return end
    for i, box in ipairs(boxes) do
        box:SetScript("OnTabPressed", function(self)
            local step = (IsShiftKeyDown and IsShiftKeyDown()) and -1 or 1
            local target = boxes[(i - 1 + step) % n + 1]
            self:HighlightText(0, 0)
            target:SetFocus()
            if target.HighlightText and not (target.IsMultiLine and target:IsMultiLine()) then target:HighlightText() end
        end)
    end
end

-- Dark inset behind text areas and lists.
function Kit.Inset(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}})
    f:SetBackdropColor(0.03, 0.022, 0.015, 1); f:SetBackdropBorderColor(unpack(Kit.BORDER))
    return f
end
