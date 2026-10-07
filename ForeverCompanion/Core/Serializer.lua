--[[
  Forever Companion - Core/Serializer.lua
  Safe, dependency-free data encoding used by guild sync and import/export.

  Format (length-prefixed, binary safe, never executed):
    n<number>;       number
    s<len>:<bytes>   string
    T / F            true / false
    {  k v k v ... } table (keys: string or number)

  Nothing received from another client or pasted by a user is ever passed to
  loadstring. Decoding is a bounded recursive parser with depth, node and
  length limits; any violation returns false plus an error.

  Also provides Base64 (for text exports) and a 32-bit checksum.
]]

local _, FC = ...

local Serializer = {}
FC.Serializer = Serializer

local concat, byte, char, sub, find, format = table.concat, string.byte, string.char, string.sub, string.find, string.format
local floor = math.floor

------------------------------------------------------------------------
-- Encoding
------------------------------------------------------------------------

local function encodeNumber(n, out)
    if n ~= n or n == math.huge or n == -math.huge then
        error("cannot serialize non-finite number")
    end
    if n == floor(n) and n > -2^53 and n < 2^53 then
        out[#out + 1] = "n" .. format("%.0f", n) .. ";"
    else
        out[#out + 1] = "n" .. format("%.10g", n) .. ";"
    end
end

local function encode(value, out, depth)
    if depth > 16 then error("table nesting too deep") end
    local t = type(value)
    if t == "string" then
        out[#out + 1] = "s" .. #value .. ":" .. value
    elseif t == "number" then
        encodeNumber(value, out)
    elseif t == "boolean" then
        out[#out + 1] = value and "T" or "F"
    elseif t == "table" then
        out[#out + 1] = "{"
        -- array part first in order, then the rest sorted for stable output
        local n = #value
        for i = 1, n do
            encode(i, out, depth + 1)
            encode(value[i], out, depth + 1)
        end
        local keys = {}
        for k in pairs(value) do
            local kt = type(k)
            if kt == "string" or (kt == "number" and (k < 1 or k > n or k ~= floor(k))) then
                keys[#keys + 1] = k
            end
        end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        for _, k in ipairs(keys) do
            encode(k, out, depth + 1)
            encode(value[k], out, depth + 1)
        end
        out[#out + 1] = "}"
    else
        error("cannot serialize type " .. t)
    end
end

--- Returns the encoded string, or nil + error.
function Serializer:Serialize(value)
    local out = {}
    local ok, err = pcall(encode, value, out, 0)
    if not ok then return nil, err end
    return concat(out)
end

------------------------------------------------------------------------
-- Decoding
------------------------------------------------------------------------

local function decodeValue(state, depth)
    if depth > state.maxDepth then error("depth limit") end
    state.nodes = state.nodes + 1
    if state.nodes > state.maxNodes then error("node limit") end
    local s, pos = state.s, state.pos
    local tag = sub(s, pos, pos)
    if tag == "n" then
        local stop = find(s, ";", pos + 1, true)
        if not stop or stop - pos > 32 then error("bad number") end
        local num = tonumber(sub(s, pos + 1, stop - 1))
        if not num or num ~= num or num == math.huge or num == -math.huge then error("bad number") end
        state.pos = stop + 1
        return num
    elseif tag == "s" then
        local colon = find(s, ":", pos + 1, true)
        if not colon or colon - pos > 10 then error("bad string header") end
        local len = tonumber(sub(s, pos + 1, colon - 1))
        if not len or len < 0 or len ~= floor(len) or len > state.maxString then error("bad string length") end
        local stop = colon + len
        if stop > #s then error("truncated string") end
        state.pos = stop + 1
        return sub(s, colon + 1, stop)
    elseif tag == "T" then
        state.pos = pos + 1
        return true
    elseif tag == "F" then
        state.pos = pos + 1
        return false
    elseif tag == "{" then
        state.pos = pos + 1
        local result = {}
        while true do
            if state.pos > #s then error("unterminated table") end
            if sub(s, state.pos, state.pos) == "}" then
                state.pos = state.pos + 1
                return result
            end
            local key = decodeValue(state, depth + 1)
            local kt = type(key)
            if kt ~= "string" and kt ~= "number" then error("bad key type") end
            local value = decodeValue(state, depth + 1)
            result[key] = value
        end
    end
    error("unexpected token at " .. pos)
end

--- Decodes a string. Returns true, value or false, error.
--- limits: { maxDepth, maxNodes, maxString }
function Serializer:Deserialize(s, limits)
    if type(s) ~= "string" or s == "" then return false, "empty" end
    limits = limits or {}
    local state = {
        s = s,
        pos = 1,
        nodes = 0,
        maxDepth = limits.maxDepth or FC.C.LIMITS.DESERIALIZE_DEPTH,
        maxNodes = limits.maxNodes or FC.C.LIMITS.DESERIALIZE_NODES,
        maxString = limits.maxString or 65536,
    }
    local ok, result = pcall(decodeValue, state, 0)
    if not ok then return false, tostring(result) end
    if state.pos ~= #s + 1 then return false, "trailing data" end
    return true, result
end

------------------------------------------------------------------------
-- Base64 (arithmetic only, no bit library needed)
------------------------------------------------------------------------

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local ENCODE, DECODE = {}, {}
for i = 1, 64 do
    local c = sub(ALPHABET, i, i)
    ENCODE[i - 1] = c
    DECODE[byte(c)] = i - 1
end

function Serializer:Base64Encode(data)
    local out = {}
    local len = #data
    for i = 1, len, 3 do
        local a, b, c = byte(data, i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = floor(n / 262144) % 64
        local c2 = floor(n / 4096) % 64
        local c3 = floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = ENCODE[c1] .. ENCODE[c2] .. (b and ENCODE[c3] or "=") .. (c and ENCODE[c4] or "=")
    end
    return concat(out)
end

function Serializer:Base64Decode(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("%s", "")
    if #text % 4 ~= 0 then return nil end
    local out = {}
    for i = 1, #text, 4 do
        local v = { byte(text, i, i + 3) }
        local n, pad = 0, 0
        for j = 1, 4 do
            local code = v[j]
            local value
            if code == 61 then -- "="
                if i + 3 < #text then return nil end
                value = 0
                pad = pad + 1
            else
                if pad > 0 then return nil end
                value = DECODE[code]
                if not value then return nil end
            end
            n = n * 64 + value
        end
        local b1 = floor(n / 65536) % 256
        local b2 = floor(n / 256) % 256
        local b3 = n % 256
        if pad == 0 then
            out[#out + 1] = char(b1, b2, b3)
        elseif pad == 1 then
            out[#out + 1] = char(b1, b2)
        elseif pad == 2 then
            out[#out + 1] = char(b1)
        else
            return nil
        end
    end
    return concat(out)
end

------------------------------------------------------------------------
-- Checksum (32-bit polynomial hash, integer-exact in doubles)
------------------------------------------------------------------------

function Serializer:Hash(data)
    local h1, h2 = 5381, 52711
    for i = 1, #data do
        local c = byte(data, i)
        h1 = (h1 * 33 + c) % 4294967296
        h2 = (h2 * 31 + c) % 4294967291
    end
    return format("%04x%04x%04x%04x", floor(h1 / 65536), h1 % 65536, floor(h2 / 65536), h2 % 65536)
end
