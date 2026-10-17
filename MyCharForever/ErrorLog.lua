local addonName, MCF = ...
-- Error protection.
--   * Every Lua error that comes from this addon is written to a small account-wide log
--     (MyCharForeverAccountDB.errors), identical errors are counted instead of repeated.
--   * Nothing is printed to the chat. `/mcf errors` shows the log, `/mcf errors export` opens it in a
--     copy window (for bug reports), `/mcf errors clear` empties it.
--   * The previous error handler is always called afterwards, so the game's own error display and other
--     error addons keep working exactly as before.
--   * MCF:SafeCall(name, fn, ...) runs a step so that its failure is logged and swallowed: the steps that
--     follow it still run (used for the login sequence and the database migration).
-- Every limit lives in MCF.ErrorLog below.

MCF.ErrorLog = {
  limit = 50,          -- distinct errors kept
  maxCaptures = 300,   -- errors recorded per session; after that only the counters of known errors grow
  maxMessage = 500,    -- characters kept of one message
  maxStack = 1500,     -- characters kept of one stack trace
  listCount = 5,       -- errors listed by /mcf errors
  pendingLimit = 30,   -- errors held back until the saved variables are loaded
}
local E = MCF.ErrorLog
local unpack = unpack or table.unpack -- the game runs Lua 5.1 (unpack); table.unpack only for other runtimes

local pending, captured = {}, 0
local previous, installed, inHandler
local lastMessage, lastTime

local function entries()
  if type(MyCharForeverAccountDB) ~= "table" then return nil end
  if type(MyCharForeverAccountDB.errors) ~= "table" then MyCharForeverAccountDB.errors = {} end
  return MyCharForeverAccountDB.errors
end

local function signature(msg)
  local sig = msg:gsub("0x%x+", "0x"):gsub("table: %S+", "table"):gsub("function: %S+", "function")
  return sig
end

local function store(list, item)
  for _, e in ipairs(list) do
    if e.sig == item.sig then
      e.count = (e.count or 1) + 1
      e.last = item.time
      e.version = item.version
      return
    end
  end
  if captured > E.maxCaptures then return end
  list[#list + 1] = {sig = item.sig, msg = item.msg, stack = item.stack, count = 1,
                     first = item.time, last = item.time, version = item.version, source = item.source}
  while #list > E.limit do
    local oldest = 1
    for i, e in ipairs(list) do if (e.last or 0) < (list[oldest].last or 0) then oldest = i end end
    table.remove(list, oldest)
  end
end

-- Records one error. Never raises.
function MCF:LogError(msg, stack, source)
  local ok = pcall(function()
    captured = captured + 1
    msg = tostring(msg or "?")
    if #msg > E.maxMessage then msg = msg:sub(1, E.maxMessage) end
    if type(stack) == "string" and #stack > E.maxStack then stack = stack:sub(1, E.maxStack) end
    local item = {sig = signature(msg), msg = msg, stack = type(stack) == "string" and stack or nil,
                  time = time and time() or 0, version = MCF.VERSION, source = source}
    local list = entries()
    if not list then
      if #pending < E.pendingLimit then pending[#pending + 1] = item end
      return
    end
    for i = 1, #pending do store(list, pending[i]) end
    if #pending > 0 then pending = {} end
    store(list, item)
  end)
  return ok
end

local function isOurs(msg)
  return type(msg) == "string" and msg:find(addonName, 1, true) ~= nil
end

local function stackTrace()
  if not debugstack then return nil end
  local ok, s = pcall(debugstack, 3, 12, 0)
  return ok and s or nil
end

local function handler(msg)
  if not inHandler and isOurs(msg) then
    inHandler = true
    local now = GetTime and GetTime() or 0
    if not (msg == lastMessage and now == lastTime) then -- two chained copies of this handler: record once
      lastMessage, lastTime = msg, now
      MCF:LogError(msg, stackTrace(), "handler")
    end
    inHandler = false
  end
  if previous then return previous(msg) end
end

-- Puts the handler in front of the current one. Safe to call again: it does nothing while it is still in front.
function E.Install()
  if not (seterrorhandler and geterrorhandler) then return end
  local current = geterrorhandler()
  if current == handler then return end
  previous = current
  seterrorhandler(handler)
  installed = true
end
E.Install()

-- Other addons may replace the handler after us; take the front position again at login.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function() E.Install() end)

-- Runs fn(...); an error is logged (not shown) and false is returned. Returns true plus the results otherwise.
function MCF:SafeCall(name, fn, ...)
  if type(fn) ~= "function" then return false end
  local n, args = select("#", ...), {...}
  local results = {}
  local ok = xpcall(function() results = {fn(unpack(args, 1, n))} end, function(err)
    MCF:LogError(tostring(name) .. ": " .. tostring(err), stackTrace(), "SafeCall")
    return err
  end)
  if not ok then return false end
  return true, unpack(results)
end

function MCF:GetErrorLog()
  local list = entries() or {}
  return list, #pending
end

function MCF:GetErrorCount()
  local list = entries() or {}
  local total = 0
  for _, e in ipairs(list) do total = total + (e.count or 1) end
  return #list, total
end

function MCF:ClearErrorLog()
  if type(MyCharForeverAccountDB) == "table" then MyCharForeverAccountDB.errors = {} end
  pending = {}
end

-- Text for the copy window / bug reports.
function MCF:BuildErrorReport()
  local de = self:GetLanguage() == "deDE"
  local lines = {}
  local _, _, _, toc = (GetBuildInfo or function() end)()
  lines[#lines + 1] = "MyCharForever " .. tostring(self.VERSION) .. " | Interface " .. tostring(toc)
    .. " | DB " .. tostring(MyCharForeverDB and MyCharForeverDB.dbVersion)
  local list = entries() or {}
  if #list == 0 then
    lines[#lines + 1] = de and "Keine Fehler protokolliert." or "No errors logged."
  end
  for i = #list, 1, -1 do
    local e = list[i]
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("[%d] x%d  %s  (%s)", #list - i + 1, e.count or 1,
      date("%Y-%m-%d %H:%M", e.last or 0), tostring(e.version))
    lines[#lines + 1] = tostring(e.msg)
    if e.stack then lines[#lines + 1] = e.stack end
  end
  return table.concat(lines, "\n")
end

MCF:AddCommand{group="debug", usage="/mcf errors", match=function(m) return m == "errors" or m:find("^errors ") ~= nil end,
  de="Fehlerprotokoll des Addons: anzeigen | export | clear | test",
  en="The addon's error log: show | export | clear | test",
  run=function(arg)
    local de = MCF:GetLanguage() == "deDE"
    local function say(m) print("|cff00ccffMyCharForever|r: " .. m) end
    arg = (arg or ""):lower()
    if arg:find("clear", 1, true) then
      MCF:ClearErrorLog(); say(de and "Fehlerprotokoll geleert." or "Error log cleared."); return
    elseif arg:find("export", 1, true) then
      if MCF.ShowErrorsExport then MCF:ShowErrorsExport() end; return
    elseif arg:find("test", 1, true) then
      C_Timer.After(0, function() error("MyCharForever test error (/mcf errors test)") end)
      say(de and "Testfehler ausgelöst; /mcf errors zeigt ihn gleich an." or "Test error raised; /mcf errors will list it in a moment.")
      return
    end
    local distinct, total = MCF:GetErrorCount()
    if distinct == 0 then say(de and "Keine Fehler protokolliert." or "No errors logged."); return end
    say(string.format(de and "%d verschiedene Fehler, %d Vorfälle. Neueste zuerst; /mcf errors export zum Kopieren."
      or "%d distinct errors, %d occurrences. Newest first; /mcf errors export to copy them.", distinct, total))
    local list = MCF:GetErrorLog()
    for i = #list, math.max(1, #list - E.listCount + 1), -1 do
      local e = list[i]
      local first = tostring(e.msg):gsub("\n.*", ""):sub(1, 160)
      print(string.format("  x%d %s  %s", e.count or 1, date("%d.%m. %H:%M", e.last or 0), first))
    end
  end}
