--[[
  Forever Companion - Localization/Localization.lua
  Locale registry. English is registered first and always present; a locale
  file for the selected language overrides the keys it translates. A missing key
  falls back to the key name so a gap never produces a Lua error.

  Adding a translation: copy enUS.lua to xxXX.lua, change the locale code in
  the RegisterLocale call, translate the values and list the file in the TOC
  right after enUS.lua.
]]

local _, FC = ...

local L = setmetatable({}, {
    __index = function(_, key)
        return tostring(key)
    end,
})
FC.L = L

FC.Locale = {
    client = (GetLocale and GetLocale()) or "enUS",
    registered = {},
    tables = {},
}
local Locale = FC.Locale
Locale.aliases = { enGB = "enUS", esMX = "esES" }
Locale.active = Locale.aliases[Locale.client] or Locale.client
Locale.OPTIONS = {
    { value = "auto", label = "LANGUAGE_AUTO" },
    { value = "enUS", name = "English", label = "LANGUAGE_ENGLISH" },
    { value = "frFR", name = "Français", label = "LANGUAGE_FRENCH" },
    { value = "esES", name = "Español", label = "LANGUAGE_SPANISH" },
    { value = "ruRU", name = "Русский", label = "LANGUAGE_RUSSIAN" },
    { value = "deDE", name = "Deutsch", label = "LANGUAGE_GERMAN" },
}

function Locale:ValidChoice(value)
    for _, option in ipairs(self.OPTIONS) do if option.value == value then return true end end
    return false
end

function Locale:Resolve(choice)
    local code = choice ~= "auto" and choice or self.client
    code = self.aliases[code] or code
    return self.tables[code] and code or "enUS"
end

function Locale:Preference()
    return FC.db and self:ValidChoice(FC.db.language) and FC.db.language or "auto"
end

function Locale:Strings(choice)
    return self.tables[self:Resolve(choice)] or self.tables.enUS
end

function Locale:Name(choice, strings)
    strings = strings or L
    if choice == "auto" then
        return string.format(strings.LANGUAGE_AUTO_CURRENT, self:Name(self:Resolve("auto"), strings))
    end
    for _, option in ipairs(self.OPTIONS) do if option.value == choice then return option.name end end
    return "English"
end

-- SavedVariables arrive at ADDON_LOADED, after the Lua files have executed.
-- Keep the shared L table: modules already hold references to it. Apply the
-- preference before any module initializes or constructs localized widgets.
function Locale:Initialize(db)
    if not self:ValidChoice(db.language) then db.language = "auto" end
    db.languageChosen = db.languageChosen == true
    db.languageGuidePending = db.languageGuidePending == true or nil
    self.active = self:Resolve(db.language)
    wipe(L)
    for key, value in pairs(self.tables.enUS) do rawset(L, key, value == true and key or value) end
    for key, value in pairs(self.tables[self.active]) do rawset(L, key, value == true and key or value) end
    if self.ResetDisplayCache then self:ResetDisplayCache() end
end

-- Commit only when the player presses Apply. A different display language
-- takes effect after ReloadUI so existing panels and caches cannot mix languages.
function Locale:SetPreference(choice)
    if not self:ValidChoice(choice) then return false end
    FC.db.language, FC.db.languageChosen = choice, true
    FC.Bus:Emit("LANGUAGE_PREFERENCE_CHANGED")
    return true
end

--- Registers strings for a locale. The default locale (enUS) is always
--- applied; the saved override is applied later, once SavedVariables exist.
function FC:RegisterLocale(locale, strings, isDefault)
    FC.Locale.registered[locale] = true
    Locale.tables[locale] = strings
    if not isDefault and locale ~= Locale.active then return end
    for key, value in pairs(strings) do
        if value == true then value = key end
        rawset(L, key, value)
    end
end

-- Game names follow the client even when the addon uses a different language.
-- Keep English recognition words for custom servers as well.
function Locale:DetectionWords(key)
    local words, seen = {}, {}
    for _, code in ipairs({ "enUS", self:Resolve("auto"), self.active }) do
        local value = self.tables[code] and self.tables[code][key]
        if value and not seen[value] then words[#words + 1], seen[value] = value, true end
    end
    return table.concat(words, ", ")
end

function Locale:ThemeName(name)
    local keys = { ["Forever Dark"] = "THEME_DARK", Classic = "THEME_CLASSIC",
        Midnight = "THEME_MIDNIGHT", Minimal = "THEME_MINIMAL", Horde = "THEME_HORDE",
        Alliance = "THEME_ALLIANCE", Forest = "THEME_FOREST", Arcane = "THEME_ARCANE" }
    return keys[name] and L[keys[name]] or name
end
