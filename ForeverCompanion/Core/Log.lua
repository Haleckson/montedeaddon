--[[
  Forever Companion - Core/Log.lua
  Leveled logging. Production users only ever see errors; everything else is
  visible while debug mode is on (/fc debug). The last messages are kept in a
  ring buffer so /fc debug log can show them even when chat output was off.
]]

local _, FC = ...

local Log = {}
FC.Log = Log

Log.LEVELS = { ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4, TRACE = 5 }
Log.NAMES = { "ERROR", "WARN", "INFO", "DEBUG", "TRACE" }
local LEVEL_COLORS = { "ff5c5c", "ffb347", "9fd4ff", "b8b8b8", "808080" }
local BUFFER_SIZE = 200

Log.debugEnabled = false
Log.level = Log.LEVELS.DEBUG
Log.buffer = {}
Log.bufferStart = 1
local reportedErrors = {}

local PREFIX = "|cffd8b25cForever Companion|r"

local function format(msg, ...)
    if select("#", ...) > 0 then
        local ok, result = pcall(string.format, msg, ...)
        if ok then return result end
    end
    return tostring(msg)
end

local function output(text)
    local frame = DEFAULT_CHAT_FRAME
    if frame and frame.AddMessage then
        frame:AddMessage(text)
    end
end

local function remember(level, text)
    local buffer = Log.buffer
    local stamp = date and date("%H:%M:%S") or ""
    buffer[#buffer + 1] = string.format("%s [%s] %s", stamp, Log.NAMES[level], text)
    if #buffer > BUFFER_SIZE then
        table.remove(buffer, 1)
    end
end

function Log:Write(level, msg, ...)
    local text = format(msg, ...)
    remember(level, text)
    if level == self.LEVELS.ERROR then
        if reportedErrors[text] then return end
        reportedErrors[text] = true
        output(string.format("%s |cff%s%s|r", PREFIX, LEVEL_COLORS[level], text:match("^[^\n]*") or text))
        return
    end
    if self.debugEnabled and level <= self.level then
        output(string.format("%s |cff%s[%s]|r %s", PREFIX, LEVEL_COLORS[level], self.NAMES[level], text))
    end
end

function Log:Error(msg, ...) self:Write(1, msg, ...) end
function Log:Warn(msg, ...) self:Write(2, msg, ...) end
function Log:Info(msg, ...) self:Write(3, msg, ...) end
function Log:Debug(msg, ...) self:Write(4, msg, ...) end
function Log:Trace(msg, ...)
    if self.debugEnabled and self.level >= 5 then self:Write(5, msg, ...) end
end

function Log:Configure(enabled, level)
    self.debugEnabled = enabled and true or false
    if type(level) == "number" and level >= 1 and level <= 5 then
        self.level = math.floor(level)
    end
end

function Log:Dump(count)
    count = count or 30
    local first = math.max(1, #self.buffer - count + 1)
    for i = first, #self.buffer do
        output("|cff808080" .. self.buffer[i] .. "|r")
    end
end

--- User-facing message (always shown).
function FC:Print(msg, ...)
    output(PREFIX .. " " .. format(msg, ...))
end
