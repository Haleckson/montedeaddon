local MCF=MyCharForever
if not MCF then return end
-- Text compression for the chronicle export: DEFLATE (RFC 1951, fixed Huffman codes, LZ77 with a hash chain)
-- written in plain Lua, then Base64. A browser can unpack it without a library (DecompressionStream "deflate-raw"),
-- and so can zlib (raw deflate). The export text for a high-level character shrinks to roughly a tenth.
--
-- Output format of MCF.Compress.Encode:   MCF1:<length of the original text in bytes>:<Base64 in lines>
-- The length lets the reader detect text that was cut off while copying.
-- Work is split into slices (one per frame) so the game never freezes; every limit lives in MCF.Compress below.

MCF.Compress = {
  magic = "MCF1",
  window = 32768,        -- DEFLATE window: matches reach back at most this far (format maximum)
  maxMatch = 258,        -- longest match DEFLATE can express
  minMatch = 3,
  maxChain = 8,          -- hash-chain candidates tried per position (more = smaller output, slower)
  sliceBytes = 30000,    -- input bytes handled per slice
  lineLength = 120,      -- Base64 characters per output line
}
local C = MCF.Compress
local unpack = unpack or table.unpack
local floor, byte, char = math.floor, string.byte, string.char

-- Fixed Huffman codes (RFC 1951, 3.2.6). Codes are written most significant bit first, so they are stored reversed.
local function reverseBits(code, length)
  local r = 0
  for _ = 1, length do r = r * 2 + code % 2; code = floor(code / 2) end
  return r
end
local LIT_CODE, LIT_BITS = {}, {}
for sym = 0, 287 do
  local code, bits
  if sym <= 143 then code, bits = 0x30 + sym, 8
  elseif sym <= 255 then code, bits = 0x190 + (sym - 144), 9
  elseif sym <= 279 then code, bits = sym - 256, 7
  else code, bits = 0xC0 + (sym - 280), 8 end
  LIT_CODE[sym], LIT_BITS[sym] = reverseBits(code, bits), bits
end
local DIST_CODE = {}
for d = 0, 29 do DIST_CODE[d] = reverseBits(d, 5) end

local LEN_BASE  = {3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}
local LEN_EXTRA = {0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
local DIST_BASE  = {1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577}
local DIST_EXTRA = {0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}

-- length (3..258) -> index into LEN_BASE; distance (1..32768) -> index into DIST_BASE
local LEN_INDEX, DIST_INDEX = {}, {}
for i = 1, #LEN_BASE do
  local top = (i < #LEN_BASE) and (LEN_BASE[i + 1] - 1) or LEN_BASE[i]
  for len = LEN_BASE[i], top do LEN_INDEX[len] = i end
end
LEN_INDEX[258] = #LEN_BASE
for i = 1, #DIST_BASE do
  local top = (i < #DIST_BASE) and (DIST_BASE[i + 1] - 1) or 32768
  for dist = DIST_BASE[i], top do DIST_INDEX[dist] = i end
end

-- Creates a compressor for `text`. step() handles one slice and returns the progress (0..1) and, when finished,
-- the raw DEFLATE bytes as a string.
local function newDeflate(text)
  local n = #text
  local out, outN = {}, 0
  local acc, accBits = 0, 0
  local pow2 = {}
  for i = 0, 32 do pow2[i] = 2 ^ i end

  local function put(value, bits) -- least significant bit first
    acc = acc + value * pow2[accBits]
    accBits = accBits + bits
    while accBits >= 8 do
      outN = outN + 1
      out[outN] = acc % 256
      acc = floor(acc / 256)
      accBits = accBits - 8
    end
  end
  local function literal(sym) put(LIT_CODE[sym], LIT_BITS[sym]) end

  put(1, 1); put(1, 2) -- final block, fixed Huffman

  local head, prev = {}, {} -- hash of 3 bytes -> latest position; prev[] is a ring over the window
  local W, MAXM, MINM, CHAIN = C.window, C.maxMatch, C.minMatch, C.maxChain
  local pos = 1

  local function hashAt(i)
    local a, b, c = byte(text, i, i + 2)
    return a * 65536 + b * 256 + c
  end
  local function insert(i)
    if i + 2 <= n then
      local h = hashAt(i)
      prev[i % W] = head[h]
      head[h] = i
    end
  end

  local function step()
    local stop = math.min(n, pos + C.sliceBytes - 1)
    while pos <= stop do
      local bestLen, bestDist = 0, 0
      if pos + 2 <= n then
        local h = hashAt(pos)
        local cand, tries = head[h], CHAIN
        local limit = math.min(MAXM, n - pos + 1)
        while cand and tries > 0 do
          local dist = pos - cand
          if dist > W or dist <= 0 then break end
          -- cheap test of the byte after the current best before comparing in full
          if bestLen == 0 or byte(text, cand + bestLen) == byte(text, pos + bestLen) then
            local len = 0
            while len < limit and byte(text, cand + len) == byte(text, pos + len) do len = len + 1 end
            if len > bestLen then
              bestLen, bestDist = len, dist
              if len >= limit then break end
            end
          end
          cand = prev[cand % W]
          tries = tries - 1
        end
      end
      if bestLen >= MINM then
        local li = LEN_INDEX[bestLen]
        literal(256 + li)
        if LEN_EXTRA[li] > 0 then put(bestLen - LEN_BASE[li], LEN_EXTRA[li]) end
        local di = DIST_INDEX[bestDist]
        put(DIST_CODE[di - 1], 5)
        if DIST_EXTRA[di] > 0 then put(bestDist - DIST_BASE[di], DIST_EXTRA[di]) end
        for k = 0, bestLen - 1 do insert(pos + k) end
        pos = pos + bestLen
      else
        literal(byte(text, pos))
        insert(pos)
        pos = pos + 1
      end
    end
    if pos > n then
      literal(256) -- end of block
      if accBits > 0 then outN = outN + 1; out[outN] = acc % 256; acc, accBits = 0, 0 end
      local parts = {}
      for i = 1, outN, 4000 do parts[#parts + 1] = char(unpack(out, i, math.min(outN, i + 3999))) end
      return 1, table.concat(parts)
    end
    return (pos - 1) / n, nil
  end
  return step
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64CHAR = {}
for i = 0, 63 do B64CHAR[i] = B64:sub(i + 1, i + 1) end

local function base64(data)
  local parts, n = {}, #data
  for i = 1, n, 3 do
    local a, b, c = byte(data, i, i + 2)
    local v = a * 65536 + (b or 0) * 256 + (c or 0)
    local c1, c2 = floor(v / 262144) % 64, floor(v / 4096) % 64
    local c3, c4 = floor(v / 64) % 64, v % 64
    if b == nil then parts[#parts + 1] = B64CHAR[c1] .. B64CHAR[c2] .. "=="
    elseif c == nil then parts[#parts + 1] = B64CHAR[c1] .. B64CHAR[c2] .. B64CHAR[c3] .. "="
    else parts[#parts + 1] = B64CHAR[c1] .. B64CHAR[c2] .. B64CHAR[c3] .. B64CHAR[c4] end
  end
  return table.concat(parts)
end

local function wrapLines(s, width)
  local lines = {}
  for i = 1, #s, width do lines[#lines + 1] = s:sub(i, i + width - 1) end
  return table.concat(lines, "\n")
end

local function finish(text, deflated)
  return C.magic .. ":" .. #text .. ":\n" .. wrapLines(base64(deflated), C.lineLength)
end

-- Everything at once (tests, small texts). Returns the finished text.
function C.EncodeNow(text)
  local step = newDeflate(text)
  local progress, deflated
  repeat progress, deflated = step() until deflated
  return finish(text, deflated)
end

-- One slice per frame. onProgress(0..1) is called after each slice, onDone(text) at the end, onFail(message) on an error.
function C.Encode(text, onProgress, onDone, onFail)
  local ok, step = pcall(newDeflate, text)
  if not ok then if onFail then onFail(tostring(step)) end; return end
  local function run()
    local good, progress, deflated = pcall(step)
    if not good then
      MCF:LogError("Compress: " .. tostring(progress), nil, "Compress")
      if onFail then onFail(tostring(progress)) end
      return
    end
    if onProgress then onProgress(progress) end
    if deflated then
      local done, result = pcall(finish, text, deflated)
      if done then onDone(result) elseif onFail then onFail(tostring(result)) end
    else
      C_Timer.After(0, run)
    end
  end
  C_Timer.After(0, run)
end
