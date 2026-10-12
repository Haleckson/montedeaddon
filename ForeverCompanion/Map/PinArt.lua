-- Presentation-only assets shared by maps, journal, tooltips and discoveries.
-- Resolve by discovery type; map groups are filters, not icon identities.
-- Never changes record icons, IDs, coordinates, category filters or progress.
local _, FC = ...
local Art = {}
FC.PinArt = Art
local ROOT = FC.C.MEDIA .. "MapPins\\"
local GROUPS = { quest=true, rare=true, vendor=true, recipe=true, npc=true,
    creature=true, secret=true, treasure=true, explored=true, dungeon=true,
    profession=true, path=true, note=true, other=true }
local missing = {}
local CATEGORY_ROOT = FC.C.MEDIA .. "CategoryIcons\\"
-- Keep the existing saved value ("transparent") for the Dark set.
-- Previewing a style never changes the active profile.
Art.STYLES = {
    { id="transparent", label="PIN_STYLE_DARK", description="PIN_STYLE_DARK_DESC", folder="" },
    { id="engraved", label="PIN_STYLE_ENGRAVED", description="PIN_STYLE_ENGRAVED_DESC", folder="Engraved\\" },
    { id="midjourney", label="PIN_STYLE_MIDJOURNEY", description="PIN_STYLE_MIDJOURNEY_DESC", folder="Midjourney\\" },
    { id="heraldic", label="PIN_STYLE_HERALDIC", description="PIN_STYLE_HERALDIC_DESC", folder="Heraldic\\" },
    { id="original", label="PIN_STYLE_ORIGINAL", description="PIN_STYLE_ORIGINAL_DESC" },
}
local styles = {}
for _, style in ipairs(Art.STYLES) do styles[style.id] = style end

function Art:GetStyle(value)
    if value == nil then value = FC.P and FC.P.map and FC.P.map.pinArtwork end
    return styles[value] or styles.transparent
end

local CATEGORY_FILES = {
    quest="quest", questchain="questchain", rare="rare", vendor="vendor",
    recipe="recipe", npc="npc", creature="creature", secret="secret",
    treasure="treasure", landmark="landmark_explored", explored="landmark_explored",
    dungeon="dungeon", profession="profession", path="path", note="note",
    other="other", cave="cave", shortcut="shortcut", entrance="entrance",
    boss="boss", mechanic="mechanic", room="room", trainer="trainer", travel="travel",
    item="item", object="object", rumored="rumored_unknown",
}

function Art:Enabled()
    return self:GetStyle().id ~= "original"
end

function Art:PixelSize(owner, value)
    local scale = owner.GetEffectiveScale and owner:GetEffectiveScale() or 1
    if not scale or scale <= 0 then scale = 1 end
    return math.max(1, math.floor(value * scale + 0.5)) / scale
end

local function setFile(tex, path)
    if missing[path] then return false end
    local ok, result = pcall(tex.SetTexture, tex, path, "CLAMP", "CLAMP", "LINEAR")
    if not ok then ok, result = pcall(tex.SetTexture, tex, path) end
    if not ok or result == false then missing[path] = true return false end
    if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(false) end
    if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
    return true
end

function Art:Path(key, pixels)
    local size = (pixels or 16) <= 24 and "32" or ((pixels or 16) <= 56 and "64" or "Master")
    local valid = GROUPS[key] or key == "rumored" or key == "compass"
    return ROOT .. size .. "\\" .. (valid and key or "other")
end

function Art:Apply(tex, rec, veiled, size)
    return self:ApplyDiscovery(tex, rec, veiled, size)
end

-- One category mapping for all discovery surfaces. The compass launcher
-- keeps its separate artwork; saved record icons remain original fallbacks.
function Art:CategoryPath(rec, veiled, pixels, styleID)
    local def = FC.Categories:ForRecord(rec)
    local key = rec.t == "npc" and rec.cls == "worldboss" and "boss" or def.key
    local file = veiled and CATEGORY_FILES.rumored or CATEGORY_FILES[key] or CATEGORY_FILES[def.mapGroup] or "other"
    local size = (pixels or 16) <= 24 and "32" or ((pixels or 16) <= 56 and "64" or ((pixels or 16) <= 112 and "128" or "Master"))
    return CATEGORY_ROOT .. (self:GetStyle(styleID).folder or "") .. size .. "\\" .. file
end

function Art:IsCategoryIcon(path)
    return type(path) == "string" and path:sub(1, #CATEGORY_ROOT) == CATEGORY_ROOT
end

--- Returns presentation icon and original fallback, without editing rec.ic.
function Art:Icon(rec, veiled, pixels, fallback)
    return self:IconForStyle(self:GetStyle().id, rec, veiled, pixels, fallback)
end

function Art:IconForStyle(styleID, rec, veiled, pixels, fallback)
    local def = FC.Categories:ForRecord(rec)
    -- Toasts can already carry a presentation icon from UI.Display. It must
    -- not become its own fallback, or leak a known icon through the veil.
    if self:IsCategoryIcon(fallback) then fallback = nil end
    if def.key ~= rec.t then fallback = def.icon end
    local original = veiled and "Interface\\Icons\\INV_Misc_QuestionMark" or (fallback or rec.ic or def.icon)
    local style = self:GetStyle(styleID)
    local path = self:CategoryPath(rec, veiled, pixels, style.id)
    if style.id ~= "original" and not missing[path] then return path, original end
    return original, original
end

--- Alpha artwork uses its full rectangle; pooled game icons restore their crop.
function Art:SetIcon(tex, icon, fallback)
    icon = icon or fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
    local clean = self:IsCategoryIcon(icon)
    if not setFile(tex, icon) then
        setFile(tex, fallback or "Interface\\Icons\\INV_Misc_QuestionMark")
        clean = false
    end
    if clean then
        tex:SetTexCoord(0, 1, 0, 1)
    else
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    return clean
end

function Art:ApplyDiscovery(tex, rec, veiled, size, fallback)
    local scale = tex.GetEffectiveScale and tex:GetEffectiveScale() or 1
    local icon, original = self:Icon(rec, veiled, (size or 16) * (scale or 1), fallback)
    local clean = self:SetIcon(tex, icon, original)
    tex:SetDesaturated(veiled and true or false)
    return clean and true or false
end

function Art:Launcher(tex, size)
    local scale = tex.GetEffectiveScale and tex:GetEffectiveScale() or 1
    local clean = self:Enabled() and setFile(tex, self:Path("compass", (size or 24) * (scale or 1)))
    if not clean then setFile(tex, FC.C.MEDIA .. "Logo") end
    tex:SetTexCoord(0, 1, 0, 1)
    return clean and true or false
end

Art.DOT = ROOT .. "Dot"
Art.PULSE = ROOT .. "PulseRing"
