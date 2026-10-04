-- BLib_Scroll.lua
-- Custom scrollbar implementation for BLib.
-- Depends on: BLib_Compat.lua, BLib_Core.lua

local TRACK_W   = 4
local BTN_H     = 16
local BTN_W     = 16
local SCROLL_STEP = 20

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- The arrow images ship as .png, which is not a documented WoW texture format.
-- If a client refuses them the buttons render as nothing, so BLib.ARROW_STYLE
-- can switch the whole library to drawn text arrows instead. See BLib_Compat.
local function MakeArrowBtn(parent, texture, hoverTexture, w, h, glyph, t)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)

    if BLib.ARROW_STYLE == "glyph" then
        local fs = btn:CreateFontString(nil, "ARTWORK")
        BLib.SetFontSafe(fs, BLib.FONT, BLib.FONT_SM, "")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(glyph)
        BLib.SetTC(fs, t.subText)
        btn.glyph = fs

        btn:SetScript("OnEnter", function() BLib.SetTC(fs, t.accent) end)
        btn:SetScript("OnLeave", function() BLib.SetTC(fs, t.subText) end)

        return btn
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(BLib.Texture(texture))
    btn.icon = icon

    btn:SetScript("OnEnter", function()
        icon:SetTexture(BLib.Texture(hoverTexture))
    end)
    btn:SetScript("OnLeave", function()
        icon:SetTexture(BLib.Texture(texture))
    end)

    return btn
end

local function UpdateThumb(data)
    local scrollFrame = data.scrollFrame
    local thumb       = data.thumb
    local track       = data.track
    local trackH      = track:GetHeight()
    local contentH    = data.content:GetHeight()
    local frameH      = scrollFrame:GetHeight()

    if contentH <= frameH then
        -- Content fits — hide scrollbar entirely
        data.scrollBar:Hide()
        scrollFrame:SetVerticalScroll(0)
        return
    end

    data.scrollBar:Show()

    -- Thumb height proportional to visible ratio, minimum 16px
    local ratio   = frameH / contentH
    local thumbH  = math.max(16, math.floor(trackH * ratio))
    thumb:SetHeight(thumbH)

    -- Thumb position
    local maxScroll  = contentH - frameH
    local scroll     = scrollFrame:GetVerticalScroll()
    scroll           = math.max(0, math.min(maxScroll, scroll))
    -- Content that shrank (a list with a row removed) leaves the frame scrolled past its end: the scroll frame does
    -- not bring it back itself (review, 2026-10-03).
    if scroll ~= scrollFrame:GetVerticalScroll() then scrollFrame:SetVerticalScroll(scroll) end
    local thumbRange = trackH - thumbH
    local thumbPos   = thumbRange > 0
        and math.floor((scroll / maxScroll) * thumbRange) or 0

    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -thumbPos)
end

local function SetScroll(data, value)
    local contentH = data.content:GetHeight()
    local frameH   = data.scrollFrame:GetHeight()
    local maxScroll = math.max(0, contentH - frameH)
    value = math.max(0, math.min(maxScroll, value))
    data.scrollFrame:SetVerticalScroll(value)
    UpdateThumb(data)
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- BLib.MakeScrollFrame(parent, w, h, t)
--   parent  : parent frame
--   w       : total width including scrollbar
--   h       : height of the scroll frame
--   t       : theme table from BLib.GetTheme()
-- Returns: scrollFrame, content

function BLib.MakeScrollFrame(parent, w, h, t)
    local contentW = w - BTN_W - 2

    -- Container holds everything, this is what callers anchor
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(w, h)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT",     container, "TOPLEFT",  0, 0)
    scrollFrame:SetPoint("BOTTOMLEFT",  container, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetWidth(contentW)

    -- Content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(contentW, 1)
    scrollFrame:SetScrollChild(content)

    -- Scrollbar container
    local scrollBar = CreateFrame("Frame", nil, container)
    scrollBar:SetPoint("TOPLEFT",     container, "TOPRIGHT",    -BTN_W, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT",  0,     0)

    -- Up button
    local upBtn = MakeArrowBtn(scrollBar,
        "arrow_up_16x16", "arrow_up_hover_16x16", BTN_W, BTN_H, "^", t)
    upBtn:SetPoint("TOP", scrollBar, "TOP", 0, 0)

    local downBtn = MakeArrowBtn(scrollBar,
        "arrow_down_16x16", "arrow_down_hover_16x16", BTN_W, BTN_H, "v", t)
    downBtn:SetPoint("BOTTOM", scrollBar, "BOTTOM", 0, 0)

    -- Track (between buttons)
    local track = CreateFrame("Frame", nil, scrollBar)
    track:SetPoint("TOP",    upBtn,   "BOTTOM", 0, 0)
    track:SetPoint("BOTTOM", downBtn, "TOP",    0, 0)
    track:SetWidth(TRACK_W)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    BLib.SolidBase(trackBg)
    trackBg:SetAllPoints()
    trackBg:SetVertexColor(BLib.CR(t.panelBg), BLib.CG(t.panelBg),
        BLib.CB(t.panelBg), 1)
    BLib.ApplyBorder(track, track, t.border)

    -- Thumb
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(TRACK_W)
    thumb:SetHeight(32)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)

    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    BLib.SolidBase(thumbTex)
    thumbTex:SetAllPoints()
    thumbTex:SetVertexColor(BLib.CR(t.border), BLib.CG(t.border),
        BLib.CB(t.border), 1)
    thumb.tex = thumbTex

    thumb:SetScript("OnEnter", function()
        thumbTex:SetVertexColor(BLib.CR(t.accent), BLib.CG(t.accent),
            BLib.CB(t.accent), 1)
    end)
    thumb:SetScript("OnLeave", function()
        thumbTex:SetVertexColor(BLib.CR(t.border), BLib.CG(t.border),
            BLib.CB(t.border), 1)
    end)

    -- Shared data table
    local data = {
        scrollFrame = scrollFrame,
        content     = content,
        track       = track,
        thumb       = thumb,
        scrollBar   = scrollBar,
        upBtn       = upBtn,
        downBtn     = downBtn,
    }

    -- --------------------------------------------------------
    -- THUMB DRAGGING
    -- --------------------------------------------------------
    local dragging        = false
    local dragStartY      = 0
    local dragStartScroll = 0

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        dragging        = true
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = scrollFrame:GetVerticalScroll()
        thumb:SetScript("OnUpdate", function()
            if not dragging then
                thumb:SetScript("OnUpdate", nil)
                return
            end
            local curY       = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta      = dragStartY - curY
            local trackH     = track:GetHeight()
            local thumbH     = thumb:GetHeight()
            local contentH   = content:GetHeight()
            local frameH     = scrollFrame:GetHeight()
            local maxScroll  = math.max(0, contentH - frameH)
            local thumbRange = trackH - thumbH
            if thumbRange <= 0 then return end
            local scrollDelta = (delta / thumbRange) * maxScroll
            SetScroll(data, dragStartScroll + scrollDelta)
        end)
    end)

    thumb:SetScript("OnMouseUp", function()
        dragging = false
        thumb:SetScript("OnUpdate", nil)
    end)

    -- --------------------------------------------------------
    -- ARROW BUTTONS
    -- --------------------------------------------------------
    upBtn:SetScript("OnClick", function()
        SetScroll(data, scrollFrame:GetVerticalScroll() - SCROLL_STEP)
    end)

    downBtn:SetScript("OnClick", function()
        SetScroll(data, scrollFrame:GetVerticalScroll() + SCROLL_STEP)
    end)

    local function MakeRepeat(btn, dir)
        local elapsed = 0
        local holding = false
        btn:SetScript("OnMouseDown", function()
            holding = true
            elapsed = 0
            btn:SetScript("OnUpdate", function(self, dt)
                if not holding then
                    btn:SetScript("OnUpdate", nil)
                    return
                end
                elapsed = elapsed + dt
                if elapsed > 0.3 then
                    SetScroll(data,
                        scrollFrame:GetVerticalScroll() + (dir * SCROLL_STEP))
                end
            end)
        end)
        btn:SetScript("OnMouseUp", function()
            holding = false
            btn:SetScript("OnUpdate", nil)
        end)
    end

    MakeRepeat(upBtn,   -1)
    MakeRepeat(downBtn,  1)

    -- --------------------------------------------------------
    -- MOUSE WHEEL
    -- --------------------------------------------------------
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        SetScroll(data, scrollFrame:GetVerticalScroll() - (delta * SCROLL_STEP))
    end)

    -- --------------------------------------------------------
    -- TRACK CLICK
    -- --------------------------------------------------------
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local curY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local trackTopY = track:GetTop()
        local trackH    = track:GetHeight()
        local thumbH    = thumb:GetHeight()
        local contentH  = content:GetHeight()
        local frameH    = scrollFrame:GetHeight()
        local maxScroll = math.max(0, contentH - frameH)
        local clickFrac = math.max(0, math.min(1,
            (trackTopY - curY) / (trackH - thumbH)))
        SetScroll(data, clickFrac * maxScroll)
    end)

    -- --------------------------------------------------------
    -- SIZE WATCHERS
    -- --------------------------------------------------------
    content:SetScript("OnSizeChanged", function()
        UpdateThumb(data)
    end)

    scrollFrame:SetScript("OnSizeChanged", function()
        UpdateThumb(data)
    end)

    -- Initial state
    UpdateThumb(data)

    -- Expose update for callers
    container.UpdateScroll = function() UpdateThumb(data) end

    return container, content
end