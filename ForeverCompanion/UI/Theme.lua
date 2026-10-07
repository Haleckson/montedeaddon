--[[
  Forever Companion - UI/Theme.lua
  Color system. A theme is a palette of named roles; widgets never hold raw
  colors, they ask the theme to paint a region with a role. Every painted
  region is remembered (weakly), so switching themes, editing a color or
  toggling high contrast repaints the whole addon immediately.

  Roles: bg panel panelAlt border accent highlight text muted success warning danger secret
]]

local _, FC = ...

local Theme = FC:NewModule("Theme")

local U = FC.Utils
local Compat = FC.Compat

Theme.ROLES = { "bg", "panel", "panelAlt", "border", "accent", "highlight", "text", "muted", "success", "warning", "danger", "secret" }

Theme.presets = {
    ["Forever Dark"] = { bg = "0f1115", panel = "161a21", panelAlt = "1e232c", border = "2c323d", accent = "d8b25c", highlight = "262c37", text = "ece8df", muted = "8d95a3", success = "62c27e", warning = "e3a444", danger = "e25c5c", secret = "e8c35a" },
    ["Classic"] = { bg = "17100a", panel = "21170e", panelAlt = "2b1f13", border = "5a4526", accent = "ffd100", highlight = "3a2a17", text = "f2e6c9", muted = "a8977a", success = "7fbf5f", warning = "e8a33c", danger = "d9534f", secret = "ffd100" },
    ["Midnight"] = { bg = "0b0d1a", panel = "11142a", panelAlt = "181c38", border = "282d55", accent = "8c7bff", highlight = "212654", text = "e4e6ff", muted = "8a8fb8", success = "5fd3a4", warning = "f0b35a", danger = "ff6b8a", secret = "c7b8ff" },
    ["Minimal"] = { bg = "121212", panel = "191919", panelAlt = "212121", border = "2f2f2f", accent = "e6e6e6", highlight = "2a2a2a", text = "f2f2f2", muted = "8f8f8f", success = "7ac47a", warning = "d9b061", danger = "d96161", secret = "f0d77a" },
    ["Horde"] = { bg = "140b0a", panel = "1d100e", panelAlt = "281512", border = "4d231c", accent = "d6402f", highlight = "36191a", text = "f1e3dc", muted = "a58c84", success = "6fbf6a", warning = "e79b3c", danger = "ff5a4f", secret = "f0c05a" },
    ["Alliance"] = { bg = "0a0f1a", panel = "0f1726", panelAlt = "152035", border = "243659", accent = "4f95e8", highlight = "1b2a45", text = "e6edf7", muted = "8a9ab3", success = "5fc38a", warning = "e8b04a", danger = "e0605a", secret = "f2d06b" },
    ["Forest"] = { bg = "0c130e", panel = "111b14", panelAlt = "17241a", border = "2a412e", accent = "93d06d", highlight = "1e3024", text = "e3eee2", muted = "8ea893", success = "93d06d", warning = "d9b45a", danger = "d9665a", secret = "e3d27a" },
    ["Arcane"] = { bg = "120b1a", panel = "1a1026", panelAlt = "221533", border = "3b2559", accent = "c77dff", highlight = "2d1c45", text = "efe6f7", muted = "a291b8", success = "6fd3b3", warning = "e8b04a", danger = "ff6b8a", secret = "f2c9ff" },
}
Theme.presetOrder = { "Forever Dark", "Classic", "Midnight", "Minimal", "Horde", "Alliance", "Forest", "Arcane" }

-- The journal style's own palette (leather, parchment, brass, cream ink).
-- The themes above, custom themes and color edits belong to the flat style.
Theme.JOURNAL = { bg = "140d08", panel = "231910", panelAlt = "33251a", border = "6b5232", accent = "d9b45f", highlight = "3d2c1b", text = "f0e4c8", muted = "b8a586", success = "8fc06b", warning = "e6a94a", danger = "e0684f", secret = "eac65c" }

local registry = setmetatable({}, { __mode = "k" })
local callbacks = setmetatable({}, { __mode = "k" })
local palette = {}
local rgbCache = {}

local function mix(hexA, hexB, t)
    local r1, g1, b1 = U.HexToRGB(hexA)
    local r2, g2, b2 = U.HexToRGB(hexB)
    return U.RGBToHex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t)
end

function Theme:BasePalette(name)
    return self.presets[name] or FC.db.customThemes[name] or self.presets["Forever Dark"]
end

function Theme:Build()
    local appearance = FC.P.appearance
    local journal = FC.Skin and FC.Skin:Enabled()
    local base = journal and self.JOURNAL or self:BasePalette(appearance.theme)
    wipe(palette)
    for _, role in ipairs(self.ROLES) do
        palette[role] = base[role] or self.presets["Forever Dark"][role]
        local override = not journal and appearance.colors[role]
        if U.IsValidHex(override) then palette[role] = override:lower() end
    end
    if appearance.highContrast then
        palette.bg = "000000"
        palette.panel = mix(palette.panel, "000000", 0.5)
        palette.text = "ffffff"
        palette.muted = "d0d0d0"
        palette.border = mix(palette.border, "ffffff", 0.45)
        palette.highlight = mix(palette.highlight, "ffffff", 0.15)
    end
    wipe(rgbCache)
end

function Theme:Hex(role)
    return palette[role] or "ffffff"
end

function Theme:Color(role)
    local cached = rgbCache[role]
    if not cached then
        cached = { U.HexToRGB(self:Hex(role)) }
        rgbCache[role] = cached
    end
    return cached[1], cached[2], cached[3]
end

local function resolveAlpha(alpha)
    if alpha == "bg" then return FC.P.appearance.bgAlpha end
    return alpha or 1
end

local function apply(region, role, alpha)
    local r, g, b = Theme:Color(role)
    local a = resolveAlpha(alpha)
    local kind = region.GetObjectType and region:GetObjectType()
    if kind == "FontString" or kind == "EditBox" then
        region:SetTextColor(r, g, b, a)
    elseif kind == "Texture" then
        region:SetColorTexture(r, g, b, a)
    elseif region.SetBackdropColor then
        region:SetBackdropColor(r, g, b, a)
    end
end

--- Paints a texture, font string or edit box with a role and remembers it.
--- alpha: number or "bg" (follows the background opacity setting).
function Theme:Paint(region, role, alpha)
    if not region then return end
    registry[region] = { role = role, alpha = alpha }
    apply(region, role, alpha)
end

--- Tints a textured region (icons, masks) instead of replacing its texture.
function Theme:Tint(region, role, alpha)
    if not region then return end
    registry[region] = { role = role, alpha = alpha, tint = true }
    local r, g, b = self:Color(role)
    region:SetVertexColor(r, g, b, resolveAlpha(alpha))
end

function Theme:Forget(region)
    registry[region] = nil
end

--- fn(owner) runs after every theme change (for composite widgets).
function Theme:OnChange(owner, fn)
    callbacks[owner] = fn
end

function Theme:Refresh()
    self:Build()
    for region, info in pairs(registry) do
        if info.tint then
            local r, g, b = self:Color(info.role)
            region:SetVertexColor(r, g, b, resolveAlpha(info.alpha))
        else
            apply(region, info.role, info.alpha)
        end
    end
    for owner, fn in pairs(callbacks) do
        FC:SafeCall("Theme:callback", fn, owner)
    end
    FC.Bus:Emit("THEME_CHANGED")
end

function Theme:OnInitialize()
    self:Build()
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^appearance") then
            U.Debounce("theme-refresh", 0.05, function() self:Refresh() end)
        end
    end)
end

------------------------------------------------------------------------
-- Theme management (presets, custom themes, overrides)
------------------------------------------------------------------------

function Theme:List()
    local list = {}
    for _, name in ipairs(self.presetOrder) do list[#list + 1] = name end
    for _, name in ipairs(U.SortedKeys(FC.db.customThemes)) do list[#list + 1] = name end
    return list
end

function Theme:IsPreset(name)
    return self.presets[name] ~= nil
end

function Theme:Select(name)
    if not (self.presets[name] or FC.db.customThemes[name]) then return false end
    wipe(FC.P.appearance.colors)
    FC.Config:Set("appearance.theme", name)
    return true
end

function Theme:SetRoleColor(role, hex)
    FC.P.appearance.colors[role] = hex
    FC.Config:Set("appearance.colors." .. role, hex)
end

function Theme:ResetColors()
    wipe(FC.P.appearance.colors)
    FC.Config:Set("appearance.colors", FC.P.appearance.colors)
end

function Theme:CurrentPalette()
    local copy = {}
    for _, role in ipairs(self.ROLES) do copy[role] = palette[role] end
    return copy
end

--- Validates and stores a custom theme. Returns the stored name or nil.
function Theme:SaveCustom(name, colors, keepExisting)
    name = U.CleanText(name, 32)
    if not name or name == "" or type(colors) ~= "table" then return nil end
    if self.presets[name] then name = name .. " (custom)" end
    if keepExisting and FC.db.customThemes[name] then return name end
    local clean = {}
    for _, role in ipairs(self.ROLES) do
        local hex = colors[role]
        clean[role] = U.IsValidHex(hex) and hex:lower() or self.presets["Forever Dark"][role]
    end
    FC.db.customThemes[name] = clean
    FC.Bus:Emit("THEMES_LIST_CHANGED")
    return name
end

function Theme:CopyCurrent(newName)
    return self:SaveCustom(newName, self:CurrentPalette())
end

function Theme:DeleteCustom(name)
    if self.presets[name] or not FC.db.customThemes[name] then return false end
    FC.db.customThemes[name] = nil
    if FC.P.appearance.theme == name then self:Select("Forever Dark") end
    FC.Bus:Emit("THEMES_LIST_CHANGED")
    return true
end

--- Category and profession accent colors.
function Theme:CategoryColor(typeKey)
    return U.HexToRGB(FC.Categories:Get(typeKey).color)
end

--- Per-pixel size for crisp borders at the current scale.
function Theme:Pixel(frame)
    local scale = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    return Compat.GetScreenPixel() / (scale > 0 and scale or 1)
end
