-- BLib_Format.lua
-- Money, counts and ages as text, shared so every addon in the family writes
-- a price the same way. Moved here from Countinghouse (1.8.0), which wrote
-- them first.
-- Depends on: nothing.

BLib = BLib or {}

local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- 78941 -> "78,941". Our own rather than BreakUpLargeNumbers, a FrameXML
-- helper that is one more thing to be there.
function BLib.Num(n)
    n = tonumber(n)
    if not n then return "?" end
    local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (s:gsub("^(-?),", "%1"))
end

local GOLD, SILVER, COPPER = "|cffffd700", "|cffc7c7cf", "|cffeda55f"

-- "12g 05s 30c", coloured; zero parts are left off at the front only, so a
-- column of prices lines up on its last digits. nil gives a grey "--".
function BLib.Money(copper)
    if IsSecret(copper) then return "?" end
    copper = tonumber(copper)
    if not copper then return "|cff888888--|r" end
    copper = math.floor(copper + 0.5)
    local g = math.floor(copper / 10000)
    local s = math.floor(copper / 100) % 100
    local c = copper % 100
    if g > 0 then
        return ("%s%s|rg %s%02d|rs %s%02d|rc"):format(GOLD, BLib.Num(g), SILVER, s, COPPER, c)
    elseif s > 0 then
        return ("%s%d|rs %s%02d|rc"):format(SILVER, s, COPPER, c)
    end
    return ("%s%d|rc"):format(COPPER, c)
end

-- "1g 20s 5c", uncoloured, for a box the player edits; nil gives "".
function BLib.MoneyPlain(copper)
    copper = tonumber(copper)
    if not copper then return "" end
    copper = math.floor(copper + 0.5)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

-- "1g 20s", "75s", "3g5c" or a bare number of copper; nil when it is none of
-- those.
function BLib.ParseMoney(text)
    if type(text) ~= "string" then return nil end
    text = text:lower():gsub("%s", "")
    if text == "" then return nil end
    if text:match("^%d+$") then return tonumber(text) end
    local total, found = 0, false
    for n, unit in text:gmatch("(%d+)([gsc])") do
        found = true
        total = total + tonumber(n) * ((unit == "g" and 10000) or (unit == "s" and 100) or 1)
    end
    return found and total or nil
end

-- Seconds since something, as "just now", "12m ago", "3h ago", "2d ago".
function BLib.Ago(seconds)
    seconds = tonumber(seconds)
    if not seconds then return "never" end
    if seconds < 60 then return "just now" end
    if seconds < 3600 then return math.floor(seconds / 60) .. "m ago" end
    if seconds < 86400 then return math.floor(seconds / 3600) .. "h ago" end
    return math.floor(seconds / 86400) .. "d ago"
end
