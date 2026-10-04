-- BLib_Core.lua
-- Shared UI foundation library for Belphie's addons.
-- Load order: after BLib_Compat.lua, which supplies SolidBase and SetFontSafe.

BLib = BLib or {}

-- ============================================================
-- SAVED VARIABLE INIT
-- ============================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "BLib" then
        BLibDB = BLibDB or {}
        if BLibDB.theme == nil then BLibDB.theme = "dark" end
        -- nil means "use the Addons tab if one exists"; only an explicit false
        -- from /blib tab off sends output back to the default frame.
        if BLibDB.outputTab == nil then BLibDB.outputTab = true end
        if BLibDB.inventory   == nil then BLibDB.inventory   = {} end
        if BLibDB.guildBanks  == nil then BLibDB.guildBanks  = {} end
        if BLibDB.professions == nil then BLibDB.professions = {} end
    end
end)

-- ============================================================
-- THEMES
-- ============================================================

BLib.Themes = {
    dark = {
        frameBg      = {0.06, 0.06, 0.06, 0.96},
        headerBg     = {0.10, 0.10, 0.10, 1.00},
        panelBg      = {0.08, 0.08, 0.08, 0.95},
        sidebarBg    = {0.07, 0.07, 0.07, 1.00},
        border       = {0.25, 0.25, 0.25, 1.00},
        text         = {0.95, 0.95, 0.95, 1.00},
        subText      = {0.80, 0.80, 0.80, 1.00},
        accent       = {1.00, 0.82, 0.00, 1.00},
        buttonBg     = {0.12, 0.12, 0.12, 1.00},
        buttonHover  = {0.18, 0.18, 0.18, 1.00},
        buttonBorder = {0.25, 0.25, 0.25, 1.00},
        placeholder  = {0.42, 0.42, 0.42, 1.00},
    },
    darker = {
        frameBg      = {0.03, 0.03, 0.03, 0.98},
        headerBg     = {0.06, 0.06, 0.06, 1.00},
        panelBg      = {0.05, 0.05, 0.05, 0.98},
        sidebarBg    = {0.04, 0.04, 0.04, 1.00},
        border       = {0.18, 0.18, 0.18, 1.00},
        text         = {0.92, 0.92, 0.92, 1.00},
        subText      = {0.72, 0.72, 0.72, 1.00},
        accent       = {1.00, 0.82, 0.00, 1.00},
        buttonBg     = {0.09, 0.09, 0.09, 1.00},
        buttonHover  = {0.15, 0.15, 0.15, 1.00},
        buttonBorder = {0.18, 0.18, 0.18, 1.00},
        placeholder  = {0.38, 0.38, 0.38, 1.00},
    },
    gray = {
        frameBg      = {0.12, 0.12, 0.12, 0.96},
        headerBg     = {0.16, 0.16, 0.16, 1.00},
        panelBg      = {0.14, 0.14, 0.14, 0.95},
        sidebarBg    = {0.11, 0.11, 0.11, 1.00},
        border       = {0.30, 0.30, 0.30, 1.00},
        text         = {0.95, 0.95, 0.95, 1.00},
        subText      = {0.82, 0.82, 0.82, 1.00},
        accent       = {1.00, 0.82, 0.00, 1.00},
        buttonBg     = {0.18, 0.18, 0.18, 1.00},
        buttonHover  = {0.24, 0.24, 0.24, 1.00},
        buttonBorder = {0.32, 0.32, 0.32, 1.00},
        placeholder  = {0.48, 0.48, 0.48, 1.00},
    },
}

-- ============================================================
-- SEMANTIC COLOURS (theme-independent)
-- ============================================================

BLib.Colours = {
    red    = {1.00, 0.35, 0.35, 1.00},
    green  = {0.35, 1.00, 0.35, 1.00},
    cyan   = {0.40, 0.90, 0.90, 1.00},
    orange = {1.00, 0.60, 0.10, 1.00},
    stale  = {1.00, 0.65, 0.10, 1.00},
    gold   = {1.00, 0.82, 0.00, 1.00},
}

-- ============================================================
-- THEME RESOLUTION
-- ============================================================

-- Per-addon overrides: { ["Forgemaster"] = "darker", ... }
local addonOverrides = {}

-- Set a theme override for a specific addon.
-- Pass nil to clear the override and fall back to global.
function BLib.SetAddonTheme(addonName, themeName)
    addonOverrides[addonName] = themeName
end

-- Get the resolved theme table for an addon (or global if no override).
function BLib.GetTheme(addonName)
    local name
    if addonName then
        name = addonOverrides[addonName]
    end
    name = name or (BLibDB and BLibDB.theme) or "dark"
    return BLib.Themes[name] or BLib.Themes.dark
end

-- Get/set the global theme (affects all addons without an override).
function BLib.SetGlobalTheme(themeName)
    if BLibDB then
        BLibDB.theme = themeName
    end
end

function BLib.GetGlobalTheme()
    return (BLibDB and BLibDB.theme) or "dark"
end

-- ============================================================
-- COLOUR HELPERS
-- ============================================================

function BLib.CR(c) return c[1] end
function BLib.CG(c) return c[2] end
function BLib.CB(c) return c[3] end
function BLib.CA(c) return c[4] or 1 end

function BLib.SetTC(fontString, c)
    fontString:SetTextColor(BLib.CR(c), BLib.CG(c), BLib.CB(c))
end

function BLib.SetVC(texture, c)
    texture:SetVertexColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), BLib.CA(c))
end

-- ============================================================
-- FONT CONSTANTS
-- ============================================================

BLib.FONT    = "Fonts\\FRIZQT__.TTF"
BLib.FONT_SM = 11
BLib.FONT_MD = 12
BLib.FONT_LG = 14

-- ============================================================
-- PRIMITIVES
-- ============================================================

function BLib.MakeBg(parent, c)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    BLib.SolidBase(t)
    t:SetAllPoints()
    t:SetVertexColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), BLib.CA(c))
    return t
end

-- A BORDER IS ONE PHYSICAL PIXEL, NOT ONE UI UNIT, and that difference is the
-- whole of the missing-border bug.
--
-- These edges used to be SetHeight(1), which asks for one UI unit. On a UI
-- scaled BELOW 1 a unit is SMALLER than a screen pixel, so a one-unit line has
-- to be rounded to something -- and rounding a hairline down rounds it out of
-- existence. It goes on the top and bottom first because those are the edges
-- whose rounding is decided by the frame's height, which is rarely a whole
-- number of pixels.
--
-- 1.3.0 attacked this from the other side by snapping frames to pixel
-- boundaries, which helped and was not enough: a snapped frame with a
-- sub-pixel border still has a sub-pixel border. Both halves are needed, and
-- they are now both here.
--
-- math.max keeps it at least as thick as it has always been, so no window
-- anywhere in the portfolio can come out of this thinner than it went in.
local function EdgeThickness(frame)
    local pixel = BLib.PixelFactor(frame)
    if type(pixel) ~= "number" or pixel <= 0 then return 1 end
    return math.max(1, pixel)
end

function BLib.ApplyBorder(frame, parent, c)
    local thickness = EdgeThickness(frame)
    local edges = {}

    local function Edge(p1, p2, vertical)
        local t = parent:CreateTexture(nil, "BORDER")
        BLib.SolidBase(t)
        t:SetPoint(p1, frame, p1)
        t:SetPoint(p2, frame, p2)
        if vertical then t:SetWidth(thickness) else t:SetHeight(thickness) end
        t:SetVertexColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), BLib.CA(c))
        t.blibVertical = vertical
        edges[#edges + 1] = t
        -- The pixel kit (BLib_Pixel.lua) re-measures it when the UI scale or the screen changes.
        if BLib.Pixel then BLib.Pixel.Track(t, frame, vertical, 1, 1) end
        return t
    end

    Edge("TOPLEFT",    "TOPRIGHT",    false)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", false)
    Edge("TOPLEFT",    "BOTTOMLEFT",  true)
    Edge("TOPRIGHT",   "BOTTOMRIGHT", true)

    -- Kept so the thickness can be recomputed later. A frame's effective scale
    -- is not necessarily settled when its border is drawn, and the player can
    -- change the UI scale afterwards, so a thickness worked out once at
    -- creation is a thickness that will eventually be wrong.
    frame.blibBorderEdges = edges
    return edges
end

function BLib.RefreshBorder(frame)
    local edges = frame and frame.blibBorderEdges
    if not edges then return end

    local thickness = EdgeThickness(frame)
    for _, t in ipairs(edges) do
        if t.blibVertical then t:SetWidth(thickness) else t:SetHeight(thickness) end
    end
end

function BLib.MakeSeparator(parent, yOffset, xPad)
    xPad = xPad or 0
    local t = parent:CreateTexture(nil, "ARTWORK")
    BLib.SolidBase(t)
    -- One screen pixel, not one UI unit (which can round to nothing below a UI scale of 1): the pixel kit's.
    if BLib.Pixel then
        BLib.Pixel.Track(t, parent, false, 1)
        t:SetHeight(BLib.Pixel.Size(parent, 1))
    else
        t:SetHeight(1)
    end
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",   xPad,  yOffset)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT",  -xPad, yOffset)
    return t
end

function BLib.MakeFS(parent, size, c)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    BLib.SetFontSafe(fs, BLib.FONT, size or BLib.FONT_MD, "")
    if c then BLib.SetTC(fs, c) end
    return fs
end

function BLib.MakePanel(parent, t, c)
    local f = CreateFrame("Frame", nil, parent)
    c = c or t.panelBg
    BLib.MakeBg(f, c)
    BLib.ApplyBorder(f, f, t.border)
    return f
end

function BLib.MakeButton(parent, text, w, h, t, isAccent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w or 100, h or 22)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    BLib.SolidBase(bg)
    bg:SetAllPoints()
    bg:SetVertexColor(BLib.CR(t.buttonBg), BLib.CG(t.buttonBg),
        BLib.CB(t.buttonBg), BLib.CA(t.buttonBg))
    btn.bg = bg

    BLib.ApplyBorder(btn, btn, t.buttonBorder)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    BLib.SetFontSafe(lbl, BLib.FONT, BLib.FONT_SM, "")
    lbl:SetPoint("CENTER", 0, 0)
    local labelColour = isAccent and t.accent or t.text
    lbl:SetTextColor(BLib.CR(labelColour), BLib.CG(labelColour), BLib.CB(labelColour))
    lbl:SetText(text or "")
    btn.label = lbl

    btn:SetScript("OnEnter", function()
        bg:SetVertexColor(BLib.CR(t.buttonHover), BLib.CG(t.buttonHover),
            BLib.CB(t.buttonHover), BLib.CA(t.buttonHover))
    end)
    btn:SetScript("OnLeave", function()
        bg:SetVertexColor(BLib.CR(t.buttonBg), BLib.CG(t.buttonBg),
            BLib.CB(t.buttonBg), BLib.CA(t.buttonBg))
    end)

    return btn
end

-- ============================================================
-- STATUS BAR
-- A flat progress bar with an independently tinted background.
-- Returns the StatusBar; drive it with :SetValue and :SetStatusBarColor
-- as normal. Min/max default to 0..1 so callers can pass a fraction.
-- ============================================================

function BLib.MakeStatusBar(parent, w, h, t, fillColour)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(w or 100, h or 8)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    BLib.SolidBase(bg)
    bg:SetAllPoints()
    BLib.SetVC(bg, t.panelBg)
    bar.bg = bg

    local fill = bar:CreateTexture(nil, "ARTWORK")
    BLib.SolidBase(fill)
    bar:SetStatusBarTexture(fill)
    bar.fill = fill

    local c = fillColour or t.accent
    bar:SetStatusBarColor(BLib.CR(c), BLib.CG(c), BLib.CB(c), BLib.CA(c))
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    return bar
end

function BLib.MakeSectionHeader(parent, text, yOffset, t)
    local fs = BLib.MakeFS(parent, BLib.FONT_SM, t.accent)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    fs:SetText(text)
    return fs
end

-- ============================================================
-- PIXEL SNAPPING
--
-- A 1px border disappears when the window's edge falls between two screen
-- pixels. A centred window's top edge does exactly that on a screen with an
-- odd number of pixels, and dragging a frame lands it wherever the cursor
-- left it, so the top and bottom edges come and go.
--
-- The fix, proven in Belphie's Dialogue: nudge the anchor so the top-left
-- corner sits on whole pixels, and round the size so the bottom and right
-- edges do too. The anchor POINT is untouched, so saved positions still mean
-- what they said.
-- ============================================================

function BLib.SnapToPixels(f)
    local point, relativeTo, relativePoint, x, y = f:GetPoint(1)
    local left, top = f:GetLeft(), f:GetTop()
    if not (point and left and top) then return end

    local pixel = BLib.PixelFactor(f)
    if not pixel or pixel <= 0 then return end

    local dx = math.floor(left / pixel + 0.5) * pixel - left
    local dy = math.floor(top  / pixel + 0.5) * pixel - top
    if math.abs(dx) > 0.001 or math.abs(dy) > 0.001 then
        f:SetPoint(point, relativeTo, relativePoint, x + dx, y + dy)
    end

    -- A fractional height leaves the BOTTOM edge between pixels even after the
    -- top has been snapped, which is the bottom border going missing on its
    -- own. Same for the right edge.
    local w, h = f:GetWidth(), f:GetHeight()
    local snappedW = math.floor(w / pixel + 0.5) * pixel
    local snappedH = math.floor(h / pixel + 0.5) * pixel
    if math.abs(snappedW - w) > 0.001 or math.abs(snappedH - h) > 0.001 then
        f:SetSize(snappedW, snappedH)
    end
end

-- Snap a frame once layout has finished. Moving a frame from inside its own
-- OnShow or OnSizeChanged, mid-layout, left some of its contents without a
-- rect so they never drew at all (Belphie's Dialogue 1.2.2 and 1.2.3: a blank
-- vendor tab). Never SetPoint a frame from inside those handlers; defer it.
function BLib.QueueSnapToPixels(f)
    if f.blibSnapQueued then return end
    f.blibSnapQueued = true

    local function run()
        f.blibSnapQueued = false
        BLib.SnapToPixels(f)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

-- ============================================================
-- RAISING WINDOWS
--
-- WINDOWS THAT SHARE A STRATA ARE DRAWN IN FRAME-LEVEL ORDER, AND BY NOTHING
-- ELSE. Every window in this family sits at HIGH, and none of them used to
-- rise when shown or clicked, so their level ranges overlapped and their
-- pieces interleaved: Countinghouse's search box over Forgemaster's recipe
-- list, Forgemaster's plan over Countinghouse's listings, and Satchel's item
-- slots through both (screenshot, 2026-09-27).
--
-- Toplevel is how Blizzard's own panels avoid it: the client lifts a toplevel
-- window above the rest of its strata when it is clicked. Raising on show as
-- well puts the window you just opened in front.
--
-- Raise and SetToplevel are protected (Forever's API docs), which only bites
-- in combat and only for a window holding secure children, such as Satchel's
-- slot guards. So the show-time raise is skipped in combat; the client's own
-- raise on click still works then.
-- ============================================================

function BLib.MakeRaisable(f)
    if not f or f.blibRaisable then return end
    f.blibRaisable = true
    if not InCombatLockdown() and f.SetToplevel then f:SetToplevel(true) end
    f:HookScript("OnShow", function(self)
        if InCombatLockdown() or not self.Raise then return end
        self:Raise()
    end)
end

-- ============================================================
-- POPOUT FRAME
-- A lightweight floating frame with header, close button, drag,
-- and a content area. Used for detachable panels across addons.
-- Returns: frame, contentArea
-- ============================================================

-- onMoved: optional callback, receives (left, bottom) when the frame is dragged.
function BLib.MakePopout(title, width, height, t, onMoved, strata)
    strata = strata or "HIGH"
    local frameName = "BLibPopout_" .. title:gsub("%s+", "_")
    local f = CreateFrame("Frame", frameName, UIParent)
    f:SetSize(width, height)
    f:SetFrameStrata(strata)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()
    BLib.MakeRaisable(f)

    BLib.MakeBg(f, t.frameBg)
    BLib.ApplyBorder(f, f, t.border)

    -- SNAP AND RE-MEASURE ON SHOW, not only after a drag.
    --
    -- Snapping used to happen on drag-stop alone, which meant a window that
    -- had never been dragged was never snapped -- and a window nobody has
    -- moved is the common case, not the rare one. Belphie's Dialogue hooks
    -- OnShow on its own panels and was fixed; every BLib popout did not and
    -- was not, which is why this kept coming back.
    --
    -- Deferred inside QueueSnapToPixels rather than done here: moving a frame
    -- from inside its own OnShow left some of its children shown but with no
    -- rect, so they never drew at all (BDL 1.2.2, the blank vendor tab).
    local function Settle(self)
        BLib.RefreshBorder(self)
        BLib.QueueSnapToPixels(self)
    end
    f:HookScript("OnShow", Settle)
    f:HookScript("OnSizeChanged", Settle)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -1)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    header:SetHeight(26)
    BLib.MakeBg(header, t.headerBg)

    local hline = header:CreateTexture(nil, "BORDER")
    BLib.SolidBase(hline)
    hline:SetHeight(1)
    hline:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT")
    hline:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
    hline:SetVertexColor(BLib.CR(t.border), BLib.CG(t.border),
        BLib.CB(t.border), BLib.CA(t.border))

    local titleFS = BLib.MakeFS(header, BLib.FONT_SM, t.accent)
    titleFS:SetPoint("LEFT", header, "LEFT", 10, 0)
    titleFS:SetText(title)

    -- Drag
    local drag = CreateFrame("Frame", nil, header)
    drag:SetPoint("TOPLEFT",     header, "TOPLEFT",  0,   0)
    drag:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", -28, -26)
    -- At the header's own level, not above it: a button an addon adds to the
    -- header sits above the strip instead of sharing its level and losing
    -- the click to it (Forgemaster's "..." menu did nothing).
    drag:SetFrameLevel(header:GetFrameLevel())
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        -- Dragging drops the frame wherever the cursor left it, between
        -- pixels as often as not, so the borders need snapping afterwards too.
        BLib.QueueSnapToPixels(f)
        if type(onMoved) == "function" then
            onMoved(f:GetLeft(), f:GetBottom())
        end
    end)

    -- Close button
    local closeBtn = BLib.MakeButton(header, "x", 20, 20, t)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -4, 0)
    BLib.SetFontSafe(closeBtn.label, BLib.FONT, BLib.FONT_MD, "")
    closeBtn.label:SetTextColor(BLib.CR(t.subText), BLib.CG(t.subText),
        BLib.CB(t.subText))
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function()
        closeBtn.bg:SetVertexColor(BLib.CR(t.buttonHover), BLib.CG(t.buttonHover),
            BLib.CB(t.buttonHover), BLib.CA(t.buttonHover))
        closeBtn.label:SetTextColor(BLib.CR(t.text), BLib.CG(t.text), BLib.CB(t.text))
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBtn.bg:SetVertexColor(BLib.CR(t.buttonBg), BLib.CG(t.buttonBg),
            BLib.CB(t.buttonBg), BLib.CA(t.buttonBg))
        closeBtn.label:SetTextColor(BLib.CR(t.subText), BLib.CG(t.subText),
            BLib.CB(t.subText))
    end)

    -- Content area (below header)
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT",     f, "TOPLEFT",     4, -27)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4,  4)

    f.header   = header
    f.closeBtn = closeBtn
    f.titleFS  = titleFS

    -- Hooked, not set, so a caller's own handlers still run.
    f:HookScript("OnShow",        BLib.QueueSnapToPixels)
    f:HookScript("OnSizeChanged", BLib.QueueSnapToPixels)

    return f, content
end
-- ============================================================
-- MINIMAP BUTTON
-- BLib.MakeMinimapButton(addonName, iconPath, angle, onLeft, onRight, onAngleChanged)
--   addonName       : used for frame naming
--   iconPath        : full texture path for the 24x24 icon
--   angle           : initial angle in degrees (saved value or default)
--   onLeft          : function() called on left click
--   onRight         : function() called on right click
--   onAngleChanged  : function(angle) called when drag stops, use to save angle
-- Returns: button frame
-- ============================================================

-- GEOMETRY, TAKEN FROM THE STOCK BUTTONS RATHER THAN GUESSED AT.
--
-- MiniMap-TrackingBorder is a 53x53 texture whose visible ring sits off-centre
-- inside its own canvas. Every hand-rolled button in this portfolio compensated
-- with a different fudge -- 56 at (12,-13) here, 52 at (11,-11) in Forgemaster
-- and Belphie's Dialogue -- and none of them lined up with the icon. Anchoring
-- the border TOPLEFT of a 31px button, with a 17px icon at (7,-6), is the
-- arrangement Blizzard's own minimap buttons use, so these now sit correctly
-- alongside third-party ones instead of merely near them.
local BUTTON_SIZE = 31
local ICON_SIZE   = 17
local BORDER_SIZE = 53

-- THE RADIUS IS DERIVED, NOT HARDCODED.
--
-- The old constant was 80, which is exactly (140 / 2) + 10: correct for the
-- default 140px minimap and wrong for every other size. Forever's minimap is
-- larger, so 80 placed every button inside the map rather than on its rim,
-- which is what they looked like.
local function MinimapRadius()
    local w = Minimap and Minimap:GetWidth()
    if not w or w <= 0 then w = 140 end
    return (w / 2) + 10
end

local function MinimapAngleToPosition(angle)
    local rad = math.rad(angle)
    local r   = MinimapRadius()
    return math.cos(rad) * r, math.sin(rad) * r
end

-- THE ANGLE COMES FROM THE CURSOR, NOT FROM THE BUTTON.
--
-- This used to read the button's own position and feed it straight back into
-- UpdatePosition. Nothing here calls StartMoving and nothing follows the
-- cursor, so the button never actually moved: every frame of a drag computed
-- the angle it was already at and put it back there. Dragging ran, cost a
-- frame, and did nothing -- for every addon in this family, since the library
-- shipped.
--
-- Scaled by the MINIMAP's effective scale rather than UIParent's, because
-- Minimap:GetLeft() is already in the minimap's own coordinate space and the
-- two scales are not the same for anyone who has resized their minimap.
local function AngleFromCursor()
    local scale = Minimap:GetEffectiveScale()
    if not scale or scale == 0 then return nil end

    local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
    if not (left and bottom) then return nil end

    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale

    local mx = left   + Minimap:GetWidth()  / 2
    local my = bottom + Minimap:GetHeight() / 2

    return math.deg(math.atan2(cy - my, cx - mx))
end

-- WHERE A BUTTON GOES WHEN NOBODY HAS PLACED IT.
--
-- The default used to be a flat 45 degrees, which put every button in the
-- family in one pile -- and because the drag above never worked, no caller had
-- ever saved an angle to override it with. Four addons meant four buttons in
-- a stack with no way to separate them.
--
-- A button created without a saved angle now takes the first free slot
-- instead. Angles callers DO supply are still honoured exactly, and are
-- recorded here so the next unplaced button steps around them.
local takenAngles = {}
local ANGLE_SPACING = 26   -- a 32px button on an 80px radius subtends about 23

local function AngleIsFree(a)
    for _, t in ipairs(takenAngles) do
        -- Shortest way round the circle, so 350 and 10 read as 20 apart.
        local d = math.abs((a - t + 180) % 360 - 180)
        if d < ANGLE_SPACING then return false end
    end
    return true
end

-- Walks forward from `from` to the first angle nothing is occupying, so a
-- button that has to move moves as little as possible and always lands in the
-- same place given the same load order.
local function NextFreeAngle(from)
    local start = from or 45
    for step = 0, 359 do
        local a = (start + step) % 360
        if AngleIsFree(a) then return a end
    end
    return start
end

-- ============================================================
-- MINIMAP SLOTS, FOR BUTTONS THAT DRAW THEMSELVES
--
-- Belphie's Dialogue and Forgemaster both predate MakeMinimapButton and have
-- their own art sizing, so neither can simply be swapped over without changing
-- how they look. They can still share the seating plan: claim an angle here and
-- every button in the family fans out instead of piling up at 45 degrees.
--
--   local angle, slot = BLib.ClaimMinimapAngle(SavedAngleOrNil)
--   ... on drag stop:  BLib.UpdateMinimapAngle(slot, newAngle)
-- ============================================================

-- nil means "you decide". A supplied angle is honoured unless something is
-- already sitting on it, in which case it steps to the nearest free slot: two
-- buttons at one angle is never what anyone chose, and until the drag above was
-- fixed it was not even possible to choose one, so every saved angle in the
-- wild is a default nobody picked. First loaded keeps the spot; the rest fan
-- out around it.
function BLib.ClaimMinimapAngle(saved)
    local a = saved
    if a == nil or not AngleIsFree(a) then
        a = NextFreeAngle(a)
    end
    table.insert(takenAngles, a)
    return a, #takenAngles
end

-- Called after a drag so later buttons step around the new position rather
-- than the one it was created at.
function BLib.UpdateMinimapAngle(slot, angle)
    if slot and takenAngles[slot] then takenAngles[slot] = angle end
end

-- Exposed for the same reason: a button that positions itself still needs the
-- one correct way to turn a cursor into an angle.
function BLib.MinimapAngleFromCursor()
    return AngleFromCursor()
end

function BLib.MakeMinimapButton(addonName, iconPath, angle, onLeft, onRight, onAngleChanged)
    local requested = angle

    local angleSlot
    angle, angleSlot = BLib.ClaimMinimapAngle(angle)

    -- Told the caller straight away when the claim differs from what it asked
    -- for, so the new position is saved and stays put. Without this the whole
    -- family renegotiates its seating on every login and reshuffles the moment
    -- one addon is enabled or disabled -- which is a worse kind of annoying
    -- than the pile it replaced, because it moves after you have learned where
    -- things are.
    if angle ~= requested and onAngleChanged then
        onAngleChanged(angle)
    end

    local btn = CreateFrame("Button", "BLibMinimap_" .. addonName, Minimap)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetClampedToScreen(false)
    -- No SetNormalTexture/SetPushedTexture here: a button made without a
    -- template has none to clear, and Mainline raises an error when those are
    -- passed nil. A highlight with a real path is fine, and is what makes the
    -- button feel like it responds to the mouse.
    pcall(btn.SetHighlightTexture, btn,
        "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Behind the icon, so a mask's transparent corners show minimap-button
    -- backing rather than whatever happens to be under the frame.
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(iconPath)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    -- Centred on the backing, which is centred in the ring. It was at TOPLEFT
    -- 7,-6, its centre 1.5 left of and 0.5 above the ring's: every button in
    -- the family sat off-centre (seen in game, 2026-09-28).
    icon:SetPoint("CENTER", bg, "CENTER", 0, 0)

    -- MASKED TO A CIRCLE. Icon art is square with a dark border baked in, so
    -- unmasked it reads as a black box sitting inside a round ring -- which is
    -- exactly how Ranksmith's book looked. SetMask is the clean fix; the
    -- TexCoord trim is the fallback for a client that lacks it, and only crops
    -- the baked border rather than rounding the corners.
    local masked = pcall(icon.SetMask, icon,
        "Interface\\CharacterFrame\\TempPortraitAlphaMask")
    if not masked then
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- Exposed so callers can anchor to the art rather than guess at offsets --
    -- Ranksmith hangs its count badge off the icon's corner.
    btn.icon   = icon
    btn.border = border

    -- Position on minimap rim
    local function UpdatePosition(a)
        local x, y = MinimapAngleToPosition(a)
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    UpdatePosition(angle)

    -- Dragging
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)

    local dragging = false

    btn:SetScript("OnDragStart", function()
        dragging = true
        btn:SetScript("OnUpdate", function()
            if not dragging then
                btn:SetScript("OnUpdate", nil)
                return
            end
            local a = AngleFromCursor()
            if a then
                angle = a
                UpdatePosition(a)
            end
        end)
    end)

    btn:SetScript("OnDragStop", function()
        dragging = false
        btn:SetScript("OnUpdate", nil)

        local a = AngleFromCursor()
        if a then angle = a end
        UpdatePosition(angle)

        -- So the next unplaced button in the family steps around this one
        -- rather than landing back underneath it.
        BLib.UpdateMinimapAngle(angleSlot, angle)

        if onAngleChanged then
            onAngleChanged(angle)
        end
    end)

    -- Click handling
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, mouseButton)
        if dragging then return end
        if mouseButton == "LeftButton" and onLeft then
            onLeft()
        elseif mouseButton == "RightButton" and onRight then
            onRight()
        end
    end)

    -- NO FADE.
    --
    -- The old behaviour dimmed to 0.8 after five seconds and started at 0.2,
    -- relying on an OnShow that never fired because the frame is created
    -- already shown -- so buttons sat at a fifth opacity until first hovered.
    -- Rather than repair that: a minimap button is a control, not a
    -- notification, and hiding a control the user placed themselves is not an
    -- improvement. Removing it also retires a Frame running an OnUpdate every
    -- frame for the life of the session, per button, to animate an effect
    -- nobody asked for.
    --
    -- Addons that want theirs gone entirely hide it outright; Ranksmith has
    -- /rs minimap for exactly that.
    btn:SetAlpha(1)

    return btn
end

