-- BLib_Compat.lua
-- Client compatibility layer. Must load FIRST in BLib.toc, before BLib_Core.
--
-- BLib targets two client families at once:
--   Classic   -- TBC Anniversary (interface 20505), where TideCaller and
--                Belphie's addons currently ship
--   Mainline  -- WoW: Forever, which shares modern WoW's UI architecture and
--                the vast majority of 12.1.5 APIs (game type "Camelot")
--
-- Everything here is FEATURE detection, never version detection. We do not yet
-- know Forever's interface number or what WOW_PROJECT_ID it reports, and
-- guessing would be the one mistake that breaks the whole library.

BLib = BLib or {}

-- ============================================================
-- CAPABILITIES
-- ============================================================

local caps = {}
BLib.Caps = caps

do
    -- Probe a throwaway texture rather than assuming anything by version.
    local probe = CreateFrame("Frame")
    local tex   = probe:CreateTexture(nil, "BACKGROUND")

    caps.colorTexture = (type(tex.SetColorTexture) == "function")
    caps.setColorTextureWorks = caps.colorTexture
        and pcall(tex.SetColorTexture, tex, 1, 1, 1, 1) or false

    caps.unitAuras   = (type(_G.C_UnitAuras) == "table")
    caps.questLogNS  = (type(_G.C_QuestLog) == "table")
    caps.settingsNS  = (type(_G.Settings) == "table")
    caps.addOnsNS    = (type(_G.C_AddOns) == "table")

    probe:Hide()
end

-- Diagnostic only. Never branch on this -- branch on caps.
BLib.Flavour = (caps.unitAuras and caps.settingsNS) and "Mainline" or "Classic"

-- ============================================================
-- SOLID FILL
--
-- BLib paints every background, border and bar by tinting a flat white
-- texture with SetVertexColor. Classic reaches for Interface\Buttons\WHITE8x8;
-- Mainline can generate the same thing with SetColorTexture and no file
-- dependency at all.
--
-- The base is always set to opaque WHITE so that SetVertexColor keeps
-- behaving as a straight colour assignment. Colouring via SetColorTexture
-- directly would make later SetVertexColor calls MULTIPLY instead of replace,
-- which would silently break BLib.SetVC and every widget that re-tints on
-- hover or focus.
-- ============================================================

local WHITE8X8 = "Interface\\Buttons\\WHITE8x8"

function BLib.SolidBase(tex)
    if caps.setColorTextureWorks then
        tex:SetColorTexture(1, 1, 1, 1)
    else
        tex:SetTexture(WHITE8X8)
    end
    return tex
end

-- ============================================================
-- FONTS
--
-- On Mainline SetFont RETURNS a boolean and fails soft on a bad path; on
-- Classic it returns nothing and may throw. Handle both, and never let a
-- missing font take the frame down with it.
-- ============================================================

function BLib.SetFontSafe(fontString, path, size, flags)
    path  = path or BLib.FONT
    size  = size or BLib.FONT_MD
    flags = flags or ""

    local ok, applied = pcall(fontString.SetFont, fontString, path, size, flags)

    -- ok == false        -> it threw (Classic style failure)
    -- applied == false   -> it refused the font (Mainline style failure)
    -- applied == nil     -> Classic success, which returns nothing
    if (not ok) or (applied == false) then
        pcall(fontString.SetFontObject, fontString, "GameFontNormal")
        return false
    end

    return true
end

-- ============================================================
-- ADDON TEXTURES
--
-- BLib ships its scrollbar arrows as .png. WoW's supported addon texture
-- formats are .blp and .tga -- .png is NOT documented as supported, and if
-- Forever rejects it the arrows render as nothing.
--
-- Centralised here so the fix is one line, and BLib.SetArrowStyle("glyph")
-- switches to drawn text arrows with no texture files at all.
-- ============================================================

BLib.TEXTURE_DIR = "Interface\\AddOns\\BLib\\Textures\\"
BLib.TEXTURE_EXT = ".png"

-- "texture" uses the shipped image files; "glyph" draws the arrow as text.
BLib.ARROW_STYLE = "texture"

function BLib.SetArrowStyle(style)
    if style == "texture" or style == "glyph" then
        BLib.ARROW_STYLE = style
    end
end

function BLib.Texture(name)
    return BLib.TEXTURE_DIR .. name .. BLib.TEXTURE_EXT
end

-- ============================================================
-- PIXELS
--
-- One screen pixel, measured in the units a frame's GetLeft/GetTop report.
-- BLib draws every border as a 1px texture, and a 1px edge landing between
-- two screen pixels rounds away to nothing. See BLib.SnapToPixels.
--
-- PixelUtil is Mainline's; the fallback derives the same factor from the
-- physical screen height, and 1 is the last resort rather than an error.
-- ============================================================

function BLib.PixelFactor(frame)
    local scale = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    if scale <= 0 then scale = 1 end

    if PixelUtil and PixelUtil.GetPixelToUIUnitFactor then
        local factor = PixelUtil.GetPixelToUIUnitFactor()
        if factor and factor > 0 then return factor / scale end
    end

    if GetPhysicalScreenSize then
        local _, screenHeight = GetPhysicalScreenSize()
        if screenHeight and screenHeight > 0 then
            return (768 / screenHeight) / scale
        end
    end

    return 1 / scale
end
