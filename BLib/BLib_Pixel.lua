-- BLib_Pixel.lua: the pixel kit (the shared framework, docs/suite-consolidation-analysis.md option A).
--
-- A line or border drawn SetHeight(1) is one UI unit, and on a UI scaled below 1 a unit is less than a screen
-- pixel, so the line is rounded and can vanish (BLib_Core.lua's note on ApplyBorder). Belphie's Quest Log drew 90
-- such hairlines, Belphie's Dialogue 45, Satchel and Forgemaster 19 each (2026-10-03). The kit draws in screen
-- pixels instead, and keeps everything it drew right when the UI scale or the screen changes, which a size worked
-- out once at creation does not.
--
--   BLib.Pixel.Size(frame, n)              n screen pixels, in frame's own units (1 when n is left out)
--   BLib.Pixel.Line(parent, vertical, n)   a texture n pixels thick (the caller anchors its length), kept so
--   BLib.Pixel.Border(frame, c, n, layer)  four edges n pixels thick on frame, coloured c ({r, g, b, a} or BLib's
--                                          colour table); returns { edges, SetColor, SetThickness, SetShown }
--   BLib.Pixel.Refresh(frame)              after frame:SetScale, its lines and borders again
--   BLib.Pixel.RefreshAll()                every one (done for you on UI_SCALE_CHANGED and DISPLAY_SIZE_CHANGED)
--   BLib.Pixel.OnChange(fn)                fn() after every RefreshAll: for an addon with edges of its own
--   BLib.Pixel.Snap(frame)                 its corner and size on whole pixels (BLib.SnapToPixels)
--
-- Borders made by BLib.ApplyBorder join the kit too, so every BLib window's border follows a scale change.

BLib = BLib or {}
local P = {}
BLib.Pixel = P

local tracked = setmetatable({}, { __mode = "k" })   -- texture -> { frame, vertical, n }
local listeners = {}

function P.Size(frame, n)
    n = n or 1
    local factor = BLib.PixelFactor and BLib.PixelFactor(frame) or 1
    if type(factor) ~= "number" or factor <= 0 then factor = 1 end
    return n * factor
end

local function Apply(t, info)
    local th = math.max(info.min or 0, P.Size(info.frame, info.n))
    if info.vertical then t:SetWidth(th) else t:SetHeight(th) end
end

-- frame is the one whose scale decides the size (the parent, unless the line belongs to a frame drawn at another).
function P.Line(parent, vertical, n, layer, frame)
    local t = parent:CreateTexture(nil, layer or "BORDER")
    if BLib.SolidBase then BLib.SolidBase(t) else t:SetColorTexture(1, 1, 1, 1) end
    local info = { frame = frame or parent, vertical = vertical and true or false, n = n or 1 }
    tracked[t] = info
    Apply(t, info)
    return t
end

-- A colour is BLib's { r, g, b, a } (a may be left out), or a table with .r .g .b .a.
local function SetColour(edges, c)
    if not c then return end
    local r, g, b, a = c[1] or c.r, c[2] or c.g, c[3] or c.b, c[4] or c.a or 1
    for _, t in ipairs(edges) do t:SetVertexColor(r, g, b, a) end
end

function P.Border(frame, c, n, layer, parent)
    parent = parent or frame
    local edges = {}
    local function Edge(p1, p2, vertical)
        local t = P.Line(parent, vertical, n, layer, frame)
        t:SetPoint(p1, frame, p1)
        t:SetPoint(p2, frame, p2)
        edges[#edges + 1] = t
    end
    Edge("TOPLEFT", "TOPRIGHT", false)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", false)
    Edge("TOPLEFT", "BOTTOMLEFT", true)
    Edge("TOPRIGHT", "BOTTOMRIGHT", true)
    SetColour(edges, c)
    local border = { edges = edges }
    function border:SetColor(colour) SetColour(edges, colour) end
    function border:SetThickness(px)
        for _, t in ipairs(edges) do
            local info = tracked[t]
            if info then info.n = px or 1 Apply(t, info) end
        end
    end
    function border:SetShown(on) for _, t in ipairs(edges) do t:SetShown(on and true or false) end end
    return border
end

-- A line made elsewhere (a texture anchored along its length) made one screen pixel thick, and kept so: what an
-- addon's own SetHeight(1) or SetWidth(1) on a line becomes. frame defaults to the region's parent.
function P.Hair(region, vertical, frame)
    local info = { frame = frame or region:GetParent(), vertical = vertical and true or false, n = 1 }
    tracked[region] = info
    Apply(region, info)
end

-- A texture made elsewhere joins the kit at a thickness of n pixels, and never under minUnits UI units
-- (BLib.ApplyBorder's edges keep their promise of at least one unit).
function P.Track(t, frame, vertical, n, minUnits)
    tracked[t] = { frame = frame, vertical = vertical and true or false, n = n or 1, min = minUnits }
end

function P.Refresh(frame)
    for t, info in pairs(tracked) do
        if info.frame == frame then Apply(t, info) end
    end
    if frame and frame.blibBorderEdges and BLib.RefreshBorder then BLib.RefreshBorder(frame) end
end

function P.RefreshAll()
    for t, info in pairs(tracked) do Apply(t, info) end
    for _, fn in ipairs(listeners) do pcall(fn) end
end

function P.OnChange(fn)
    if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

function P.Snap(frame) if BLib.SnapToPixels then BLib.SnapToPixels(frame) end end

-- The scale settles a moment after the event (the client applies it on the next frame), so wait one.
local events = CreateFrame("Frame")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent", function()
    if C_Timer and C_Timer.After then C_Timer.After(0, P.RefreshAll) else P.RefreshAll() end
end)
