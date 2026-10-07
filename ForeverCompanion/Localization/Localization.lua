--[[
  Forever Companion - Localization/Localization.lua
  Locale registry. English is registered first and always present; a locale
  file for the client language overrides the keys it translates. A missing key
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
}

--- Registers strings for a locale. The default locale (enUS) is always
--- applied; other locales only when they match the client.
function FC:RegisterLocale(locale, strings, isDefault)
    FC.Locale.registered[locale] = true
    if not isDefault and locale ~= FC.Locale.client then return end
    for key, value in pairs(strings) do
        if value == true then value = key end
        rawset(L, key, value)
    end
end
