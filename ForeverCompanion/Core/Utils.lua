--[[
  Forever Companion - Core/Utils.lua
  Small pure helpers shared by every layer. No WoW frames here.
]]

local _, FC = ...

local U = {}
FC.Utils = U

local floor, max, min = math.floor, math.max, math.min
local format, gsub, lower, sub = string.format, string.gsub, string.lower, string.sub

function U.Now()
    if GetServerTime then
        local t = GetServerTime()
        if type(t) == "number" and t > 0 then return t end
    end
    return time()
end

function U.Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

function U.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return floor(value * mult + 0.5) / mult
end

function U.Trim(s)
    if type(s) ~= "string" then return "" end
    return (gsub(s, "^%s*(.-)%s*$", "%1"))
end

--- Removes control characters and caps the length. Used on every piece of
--- text that a user or another client supplies.
function U.CleanText(s, maxLen)
    if type(s) ~= "string" then return nil end
    s = gsub(s, "[%z\1-\8\11\12\14-\31\127]", "")
    s = gsub(s, "\r\n?", "\n")
    s = U.Trim(s)
    if maxLen and #s > maxLen then
        -- cut on UTF-8 character boundaries, never inside a multi-byte sequence
        local out, length = {}, 0
        for ch in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
            if length + #ch > maxLen then break end
            out[#out + 1] = ch
            length = length + #ch
        end
        s = table.concat(out)
    end
    return s
end

--- Escapes WoW UI escape sequences so user text cannot inject colors,
--- textures or hyperlinks into our frames.
function U.Escape(s)
    if type(s) ~= "string" then return "" end
    return (gsub(s, "|", "||"))
end

function U.NormalizeTitle(s)
    if type(s) ~= "string" then return "" end
    s = lower(s)
    s = gsub(s, "[%s%p]+", "")
    return s
end

function U.Split(s, sep)
    local result = {}
    if type(s) ~= "string" or s == "" then return result end
    for piece in string.gmatch(s, "([^" .. sep .. "]+)") do
        local t = U.Trim(piece)
        if t ~= "" then result[#result + 1] = t end
    end
    return result
end

function U.CopyTable(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end
    local dst = {}
    seen[src] = dst
    for k, v in pairs(src) do
        dst[U.CopyTable(k, seen)] = U.CopyTable(v, seen)
    end
    return dst
end

--- Fills missing keys in dst from defaults (recursively). Wrong types are
--- replaced by the default, so a damaged profile cannot break the UI.
function U.ApplyDefaults(dst, defaults)
    for k, v in pairs(defaults) do
        local current = dst[k]
        if type(v) == "table" then
            if type(current) ~= "table" then
                dst[k] = U.CopyTable(v)
            else
                U.ApplyDefaults(current, v)
            end
        elseif current == nil or type(current) ~= type(v) then
            dst[k] = v
        end
    end
    return dst
end

function U.Count(t)
    local n = 0
    if type(t) == "table" then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

function U.Contains(list, value)
    if type(list) ~= "table" then return false end
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

local BASE36 = "0123456789abcdefghijklmnopqrstuvwxyz"
function U.ToBase36(n)
    n = floor(math.abs(n or 0))
    if n == 0 then return "0" end
    local out = {}
    while n > 0 do
        local r = n % 36
        table.insert(out, 1, sub(BASE36, r + 1, r + 1))
        n = floor(n / 36)
    end
    return table.concat(out)
end

function U.RandomToken(length)
    local out = {}
    for i = 1, length or 6 do
        local r = math.random(1, 36)
        out[i] = sub(BASE36, r, r)
    end
    return table.concat(out)
end

function U.PlayerFullName()
    local name, realm
    if UnitFullName then
        name, realm = UnitFullName("player")
    end
    name = name or (UnitName and UnitName("player")) or "Unknown"
    if not realm or realm == "" then
        realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or ""
    end
    if realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

-- WoW: Forever characters have a first name and a surname. The game reports
-- the surname where other clients report the realm, so the journal's key of
-- a character is "First-Surname"; chat and addon messages name the same
-- character "First Surname-Realm". Other clients have no surnames, and
-- every helper below then leaves names exactly as they were.

--- The separator between a first name and a surname, or nil on a client
--- without surnames.
function U.SurnameSeparator()
    if type(RegionalUniqueNamesEnabled) ~= "function" then return nil end
    local ok, enabled = pcall(RegionalUniqueNamesEnabled)
    if not ok or enabled ~= true then return nil end
    local consts = Constants and Constants.CharacterNameSeparatorConsts
    local separator = type(consts) == "table" and consts.CHARACTERNAME_SURNAME_SEPARATOR
    return type(separator) == "string" and separator ~= "" and separator or " "
end

--- The journal's key of the character a chat or addon message names:
--- "First Surname-Realm" and "First Surname" become "First-Surname". A key,
--- and any name without a surname, comes back unchanged.
function U.CharacterKey(name)
    if type(name) ~= "string" or name == "" then return name end
    local separator = U.SurnameSeparator()
    if not separator then return name end
    local base = name:match("^(.-)%-[^%-]*$") or name
    local at = base:find(separator, 1, true)
    if not at or at == 1 or at + #separator > #base then return name end
    return base:sub(1, at - 1) .. "-" .. base:sub(at + #separator)
end

--- Whether two names (keys, chat or addon message senders) are one character.
function U.SameCharacter(a, b)
    if type(a) ~= "string" or type(b) ~= "string" or a == "" or b == "" then return false end
    return a == b or U.CharacterKey(a) == U.CharacterKey(b)
end

--- "Name-Realm" -> "Name" when the realm is the player's own. On Forever a
--- character is shown as "First Surname", whichever form names it.
function U.ShortName(full)
    if type(full) ~= "string" then return "?" end
    local separator = U.SurnameSeparator()
    if separator then
        local base, suffix = full:match("^(.-)%-([^%-]*)$")
        if not base or base == "" then return full end
        if base:find(separator, 1, true) or suffix == "" then return base end -- "First Surname-Realm"
        local realm = GetNormalizedRealmName and GetNormalizedRealmName()
        if suffix == realm then return base end                              -- no surname: "Name-Realm"
        return base .. separator .. suffix                                   -- the key "First-Surname"
    end
    if Ambiguate then
        local ok, short = pcall(Ambiguate, full, "guild")
        if ok and short then return short end
    end
    return (full:match("^([^%-]+)")) or full
end

function U.NormalizeSender(sender)
    if type(sender) ~= "string" or sender == "" then return nil end
    if not sender:find("-", 1, true) then
        local realm = GetNormalizedRealmName and GetNormalizedRealmName()
        if realm and realm ~= "" then sender = sender .. "-" .. realm end
    end
    return sender
end

function U.FormatCoords(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return format("%.1f, %.1f", x * 100, y * 100)
end

function U.FormatNumber(n)
    n = floor(tonumber(n) or 0)
    local s = tostring(n)
    local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if result:sub(1, 1) == "," then result = result:sub(2) end
    return result
end

function U.TimeAgo(timestamp)
    local L = FC.L
    if type(timestamp) ~= "number" or timestamp <= 0 then return L.TIME_UNKNOWN end
    local delta = max(0, U.Now() - timestamp)
    if delta < 60 then return L.TIME_JUST_NOW end
    if delta < 3600 then return format(L.TIME_MINUTES_AGO, floor(delta / 60)) end
    if delta < 86400 then return format(L.TIME_HOURS_AGO, floor(delta / 3600)) end
    if delta < 86400 * 2 then return L.TIME_DAY_AGO end
    if delta < 86400 * 30 then return format(L.TIME_DAYS_AGO, floor(delta / 86400)) end
    return U.FormatDate(timestamp)
end

function U.ShortAgo(timestamp)
    local L = FC.L
    if type(timestamp) ~= "number" then return "" end
    local delta = max(0, U.Now() - timestamp)
    if delta < 3600 then return format(L.TIME_SHORT_MIN, max(1, floor(delta / 60))) end
    if delta < 86400 then return format(L.TIME_SHORT_HOUR, floor(delta / 3600)) end
    return format(L.TIME_SHORT_DAY, floor(delta / 86400))
end

function U.FormatDate(timestamp)
    if type(timestamp) ~= "number" then return "?" end
    return date("%Y-%m-%d %H:%M", timestamp)
end

function U.FormatDuration(seconds)
    seconds = floor(seconds or 0)
    if seconds < 60 then return format("%ds", seconds) end
    if seconds < 3600 then return format("%dm", floor(seconds / 60 + 0.5)) end
    return format("%dh %02dm", floor(seconds / 3600), floor((seconds % 3600) / 60))
end

--- 12 h 05 m, or 3 d 4 h for longer spans.
function U.FormatLongDuration(seconds)
    seconds = math.floor(seconds or 0)
    if seconds >= 86400 then
        return string.format(FC.L.BIO_DAYS, math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end
    return U.FormatDuration(seconds)
end

function U.HexToRGB(hex)
    if type(hex) ~= "string" then return 1, 1, 1 end
    hex = hex:gsub("#", "")
    if not hex:match("^%x%x%x%x%x%x$") then return 1, 1, 1 end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

function U.RGBToHex(r, g, b)
    return format("%02x%02x%02x", U.Clamp(floor(r * 255 + 0.5), 0, 255), U.Clamp(floor(g * 255 + 0.5), 0, 255), U.Clamp(floor(b * 255 + 0.5), 0, 255))
end

function U.Colorize(text, hex)
    return "|cff" .. (hex or "ffffff") .. tostring(text) .. "|r"
end

local ANCHORS = {
    TOP = true, BOTTOM = true, LEFT = true, RIGHT = true, CENTER = true,
    TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}
function U.IsAnchor(point)
    return type(point) == "string" and ANCHORS[point] == true
end

function U.IsValidHex(hex)
    return type(hex) == "string" and hex:match("^%x%x%x%x%x%x$") ~= nil
end

--- Runs fn once after `delay` seconds; repeated calls with the same key inside
--- the window collapse into one call (coalescing for UI refreshes).
local pendingDebounce = {}
function U.Debounce(key, delay, fn)
    if pendingDebounce[key] then return end
    pendingDebounce[key] = true
    C_Timer.After(delay, function()
        pendingDebounce[key] = nil
        FC:SafeCall("debounce:" .. tostring(key), fn)
    end)
end

function U.After(delay, fn)
    C_Timer.After(delay, function() FC:SafeCall("timer", fn) end)
end

--- Sorted list of the keys of a set.
function U.SortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

--- Distance in "map units" between two normalized points, optionally scaled
--- to yards with the map's world size.
function U.MapDistance(x1, y1, x2, y2, width, height)
    local dx, dy = (x1 - x2), (y1 - y2)
    if width and height and width > 0 and height > 0 then
        dx, dy = dx * width, dy * height
    end
    return math.sqrt(dx * dx + dy * dy)
end

--- Packs a normalized point into one integer (4 decimals per axis).
function U.PackPoint(x, y)
    return floor(U.Clamp(x, 0, 1) * 10000 + 0.5) * 10000 + floor(U.Clamp(y, 0, 1) * 10000 + 0.5)
end

function U.UnpackPoint(value)
    return floor(value / 10000) / 10000, (value % 10000) / 10000
end

function U.GridKey(x, y, cells)
    if type(x) ~= "number" or type(y) ~= "number" then return "nopos" end
    cells = cells or 50
    return floor(x * cells) .. "." .. floor(y * cells)
end

function U.Median(list)
    local n = #list
    if n == 0 then return nil end
    local copy = {}
    for i = 1, n do copy[i] = list[i] end
    table.sort(copy)
    if n % 2 == 1 then return copy[(n + 1) / 2] end
    return (copy[n / 2] + copy[n / 2 + 1]) / 2
end

U.min, U.max = min, max
