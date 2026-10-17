local addonName, MCF = ...
-- Data maintenance: size report, retention limits and route thinning.
-- Every limit and tolerance lives in MCF.Maintenance below and nowhere else.

MCF.Maintenance = {
  limits = {events = 2000, craftHistory = 500, guildHistory = 1000, professionHistory = 1000,
            duelHistory = 1000, worldDrops = 5000, dungeonRuns = 1500},
  -- Lists that keep only their newest entries: save-data path -> key in `limits`. Events and the crafting list
  -- are reported separately (see RunMaintenance); the others are counted together. Journal, screenshots,
  -- sessions and every total or counter are never trimmed.
  retained = {
    ["guild.history"] = "guildHistory", ["professions.history"] = "professionHistory",
    ["duels.history"] = "duelHistory", ["worldDrops"] = "worldDrops", ["dungeons"] = "dungeonRuns",
  },
  coordDecimals = 4,        -- stored route precision (map-normalised 0..1 coordinates)
  journeyEpsilon = 0.0015,  -- Douglas-Peucker tolerance for COMPLETED levels (0.15% of a map)
  exportEpsilon = 0.0070,   -- coarser tolerance for the simplified export
  maxRunJump = 0.20,        -- never connect points further apart than this in one run
  exportSplitSeconds = 900, -- export: start a new route segment after a pause this long (the recorder thins straight stretches, so short gaps are normal)
  startupDelay = 20,        -- seconds after login before the automatic run
  levelUpDelay = 10,        -- seconds after a level-up before the automatic run
}
local M = MCF.Maintenance

local function tbl(v) return type(v) == "table" and v or {} end

---------------------------------------------------------------------------
-- Size estimate (single implementation, also used by the settings panel)
---------------------------------------------------------------------------
local function estimate(v, seen)
  local tv = type(v)
  if tv == "nil" then return 3
  elseif tv == "boolean" then return v and 4 or 5
  elseif tv == "number" then return #tostring(v)
  elseif tv == "string" then return #v + 2
  elseif tv ~= "table" then return 0 end
  if seen[v] then return 0 end
  seen[v] = true
  local n = 2
  for k, val in pairs(v) do n = n + estimate(k, seen) + estimate(val, seen) + 4 end
  return n
end

function MCF:EstimateSize(value) return estimate(value, {}) end

function MCF:FormatBytes(bytes)
  if bytes >= 1024 * 1024 then return string.format("%.2f MB", bytes / (1024 * 1024))
  elseif bytes >= 1024 then return string.format("%.1f KB", bytes / 1024) end
  return bytes .. " B"
end

-- Per top-level key: estimated bytes and entry count, biggest first.
function MCF:GetDataSizeReport()
  local db = MyCharForeverDB
  if type(db) ~= "table" then return {}, 0 end
  local rows, total = {}, 0
  for key, value in pairs(db) do
    local bytes = estimate(value, {})
    local count = 0
    if type(value) == "table" then for _ in pairs(value) do count = count + 1 end end
    rows[#rows + 1] = {key = tostring(key), bytes = bytes, count = count}
    total = total + bytes
  end
  table.sort(rows, function(a, b) return a.bytes > b.bytes end)
  return rows, total
end

function MCF:PrintDataSizeReport()
  local rows, total = self:GetDataSizeReport()
  print("|cff00ccffMyCharForever|r: " .. (self:GetLanguage() == "deDE" and "Datenverbrauch (geschätzt)" or "Data usage (estimated)")
    .. ": |cffffd200" .. self:FormatBytes(total) .. "|r")
  for i = 1, math.min(10, #rows) do
    local r = rows[i]
    print(string.format("  %-18s %10s  (%d)", r.key, self:FormatBytes(r.bytes), r.count))
  end
end

---------------------------------------------------------------------------
-- Douglas-Peucker (shared with the export). Iterative, order preserving.
-- getX/getY read the coordinates of one point.
---------------------------------------------------------------------------
function MCF.RDP(points, epsilon, getX, getY)
  local n = #points
  if n <= 2 then return points end
  local keep = {[1] = true, [n] = true}
  local stack = {{1, n}}
  while #stack > 0 do
    local range = table.remove(stack)
    local lo, hi = range[1], range[2]
    if hi - lo > 1 then
      local ax, ay = getX(points[lo]), getY(points[lo])
      local dx, dy = getX(points[hi]) - ax, getY(points[hi]) - ay
      local len2 = dx * dx + dy * dy
      local maxDist, index = 0, nil
      for i = lo + 1, hi - 1 do
        local px, py = getX(points[i]), getY(points[i])
        local d
        if len2 == 0 then
          d = math.sqrt((px - ax) ^ 2 + (py - ay) ^ 2)
        else
          local t = ((px - ax) * dx + (py - ay) * dy) / len2
          if t < 0 then t = 0 elseif t > 1 then t = 1 end
          d = math.sqrt((px - (ax + t * dx)) ^ 2 + (py - (ay + t * dy)) ^ 2)
        end
        if d > maxDist then maxDist, index = d, i end
      end
      if index and maxDist > epsilon then
        keep[index] = true
        stack[#stack + 1] = {lo, index}
        stack[#stack + 1] = {index, hi}
      end
    end
  end
  local out = {}
  for i = 1, n do if keep[i] then out[#out + 1] = points[i] end end
  return out
end

---------------------------------------------------------------------------
-- Journey: round coordinates, thin completed levels
---------------------------------------------------------------------------
local function roundCoord(v)
  local m = 10 ^ M.coordDecimals
  return math.floor(v * m + 0.5) / m
end
M.RoundCoord = roundCoord -- used by the journey recorder for new points

local function px(p) return p.x end
local function py(p) return p.y end

local function thinJourney(db, currentLevel)
  local j = db.journey
  if type(j) ~= "table" then return 0, 0 end
  local before = #j
  local out, n = {}, 0
  local run, runMap, runLevel = {}, nil, nil

  local function flush()
    if #run == 0 then return end
    local kept = MCF.RDP(run, M.journeyEpsilon, px, py)
    for _, p in ipairs(kept) do n = n + 1; out[n] = p end
    run = {}
  end

  for _, p in ipairs(j) do
    if type(p) == "table" then
      if type(p.x) == "number" then p.x = roundCoord(p.x) end
      if type(p.y) == "number" then p.y = roundCoord(p.y) end
      local mapID = p.m or p.mapID
      local level = tonumber(p.l or p.level)
      local protected = (p.r or p.reason) or (p.q or p.taxi)
      local eligible = not protected and level and level > 0 and level < currentLevel
        and type(p.x) == "number" and type(p.y) == "number"
      if eligible then
        local last = run[#run]
        local jump = last and math.sqrt((p.x - last.x) ^ 2 + (p.y - last.y) ^ 2) or 0
        if mapID ~= runMap or level ~= runLevel or jump > M.maxRunJump then flush() end
        runMap, runLevel = mapID, level
        run[#run + 1] = p
      else
        flush()
        n = n + 1; out[n] = p
      end
    end
  end
  flush()

  -- Write back in place: other code holds a reference to the same table.
  for i = 1, n do j[i] = out[i] end
  for i = n + 1, before do j[i] = nil end
  return before, n
end

---------------------------------------------------------------------------
-- Retention
---------------------------------------------------------------------------
local function trimTail(list, limit)
  if type(list) ~= "table" or #list <= limit then return 0 end
  local total = #list
  local drop = total - limit
  for i = 1, limit do list[i] = list[i + drop] end
  for i = limit + 1, total do list[i] = nil end
  return drop
end

function MCF:RunMaintenance(manual)
  local db = MyCharForeverDB
  if type(db) ~= "table" then return nil end
  local _, bytesBefore = self:GetDataSizeReport()
  local currentLevel = self.currentLevel or UnitLevel("player") or 1
  local jBefore, jAfter = thinJourney(db, currentLevel)
  local otherDropped = 0
  for path, limitKey in pairs(M.retained) do
    local node = db
    for part in path:gmatch("[^.]+") do node = type(node) == "table" and node[part] or nil end
    otherDropped = otherDropped + trimTail(node, M.limits[limitKey])
  end
  local result = {
    time = time(), manual = manual and true or nil,
    journeyBefore = jBefore, journeyAfter = jAfter,
    eventsDropped = trimTail(db.events, M.limits.events),
    craftDropped = trimTail(tbl(db.crafting).history, M.limits.craftHistory),
    otherDropped = otherDropped,
  }
  if db.damageMeterDebug ~= nil then db.damageMeterDebug = nil; result.debugCleared = true end
  local _, bytesAfter = self:GetDataSizeReport()
  result.bytesBefore, result.bytesAfter = bytesBefore, bytesAfter
  db.maintenance = db.maintenance or {}
  db.maintenance.last = result
  if self.RefreshSettingsInfo then self:RefreshSettingsInfo() end
  if self.RefreshJourneyMapIfVisible then self:RefreshJourneyMapIfVisible() end
  return result
end

function MCF:DescribeMaintenance(result)
  local de = self:GetLanguage() == "deDE"
  if not result then return de and "Noch keine Wartung durchgeführt." or "No maintenance run yet." end
  local saved = math.max(0, (result.bytesBefore or 0) - (result.bytesAfter or 0))
  return string.format(de and "%s: %s gespart, Routenpunkte %d -> %d, Ereignisse -%d, Herstellungen -%d"
    or "%s: saved %s, route points %d -> %d, events -%d, crafts -%d",
    date(de and "%d.%m.%Y %H:%M" or "%Y-%m-%d %H:%M", result.time or 0), self:FormatBytes(saved),
    result.journeyBefore or 0, result.journeyAfter or 0, result.eventsDropped or 0, result.craftDropped or 0)
end


-- One explanation for tooltip, hint line and confirmation dialog (numbers come from M).
function MCF:MaintenanceDescription()
  local de = self:GetLanguage() == "deDE"
  local pct = string.format("%.2f", M.journeyEpsilon * 100)
  if de then
    return "Was wird bereinigt:\n"
      .. "• Routenpunkte abgeschlossener Level werden ausgedünnt (Verlauf bleibt auf " .. pct .. " % der Kartengröße genau); Koordinaten werden auf " .. M.coordDecimals .. " Stellen gerundet.\n"
      .. "• Der Ereignisverlauf behält die letzten " .. M.limits.events .. " Einträge, die Herstellungsliste die letzten " .. M.limits.craftHistory .. " (Gesamtsummen bleiben).\n"
      .. "• Weitere Verläufe behalten nur die neuesten Einträge (Gilde/Berufe/Duelle je " .. M.limits.guildHistory .. ", Weltdrops " .. M.limits.worldDrops .. ", Dungeon-Läufe " .. M.limits.dungeonRuns .. "); das passiert erst bei sehr langer Spielzeit.\n"
      .. "• Der Debug-Export des Schadensmessers (/mcfdmgdebug) wird geleert.\n"
      .. "Nicht angetastet: aktuelles Level, Routenmarker, Flugrouten, Level-Historie, Ausrüstung, Journal, Screenshots, Dungeons, Gold, Kills/Tode, Erfolge und Statistiken.\n"
      .. "Ausgedünnte Routenpunkte lassen sich nicht wiederherstellen."
  end
  return "What gets cleaned up:\n"
    .. "• Route points of completed levels are thinned (path stays accurate to " .. pct .. "% of the map size); coordinates are rounded to " .. M.coordDecimals .. " decimals.\n"
    .. "• The event log keeps the last " .. M.limits.events .. " entries, the crafting list the last " .. M.limits.craftHistory .. " (totals are kept).\n"
    .. "• Other histories keep only their newest entries (guild/professions/duels " .. M.limits.guildHistory .. " each, world drops " .. M.limits.worldDrops .. ", dungeon runs " .. M.limits.dungeonRuns .. "); this only matters after a very long time played.\n"
    .. "• The damage-meter debug export (/mcfdmgdebug) is cleared.\n"
    .. "Untouched: current level, route markers, flight paths, level history, gear, journal, screenshots, dungeons, gold, kills/deaths, achievements and statistics.\n"
    .. "Thinned route points cannot be restored."
end

local function autoEnabled()
  local s = MyCharForeverDB and MyCharForeverDB.settings
  return not (s and s.autoMaintenance == false)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
pcall(function() frame:RegisterEvent("PLAYER_LEVEL_UP") end)
frame:SetScript("OnEvent", function(_, event)
  local delay = event == "PLAYER_LOGIN" and M.startupDelay or M.levelUpDelay
  C_Timer.After(delay, function()
    if autoEnabled() then pcall(MCF.RunMaintenance, MCF, false) end
  end)
end)
