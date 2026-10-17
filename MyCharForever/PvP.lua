local addonName, MCF = ...
-- World PvP: player kills and deaths caused by players outside battlegrounds and arenas.
--   * A kill is noticed from the game's honorable-kill chat line (its text comes from the client's own global strings, so any language
--     works) or from the PvP-kills event; whatever fires first counts, the second within DEDUPE seconds is the same kill.
--   * A death by a player is reported by DeathCause.lua (the Death Recap names a player as the killer).
--   * No player names are stored, only class, race and level of the opponent, when known.
-- The first kill and the first death each get an automatic screenshot and a journal entry (MCF:AutoMoment).
-- Every kill and death is a row in db.pvp.history and shows as a crossed-swords pin on the map.
-- Every number and wording lives in MCF.PvP below.

MCF.PvP = {
  historyLimit = 300, -- rows kept in db.pvp.history (the oldest are dropped; the counters keep everything)
  dedupe = 2,         -- seconds: the kill chat line and the kills event are the same kill
  deathDedupe = 5,    -- seconds: the Death Recap can report one death more than once
  momentDelay = 1.5,  -- seconds between the first kill and its screenshot
}
local P = MCF.PvP

local function de() return MCF.GetLanguage and MCF:GetLanguage() == "deDE" end
local function setting(key, default)
  local s = MyCharForeverDB and MyCharForeverDB.settings
  local v = s and s[key]
  if v == nil then return default end
  return v
end
local function safe(v)
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

local function ensure()
  local db = MyCharForeverDB
  if type(db) ~= "table" then return nil end
  db.pvp = type(db.pvp) == "table" and db.pvp or {}
  local p = db.pvp
  p.kills, p.deaths, p.bgKills, p.bgDeaths = p.kills or 0, p.deaths or 0, p.bgKills or 0, p.bgDeaths or 0
  p.byClass = type(p.byClass) == "table" and p.byClass or {}
  p.byZone = type(p.byZone) == "table" and p.byZone or {}
  p.byLevel = type(p.byLevel) == "table" and p.byLevel or {}
  p.history = type(p.history) == "table" and p.history or {}
  return p
end

-- Battleground and arena fights are only counted, not listed or marked.
local function inPvPInstance()
  if not IsInInstance then return false end
  local ok, inside, kind = pcall(IsInInstance)
  return ok and inside and (kind == "pvp" or kind == "arena")
end

local function className(file)
  local names = (UnitSex and UnitSex("player") == 3) and LOCALIZED_CLASS_NAMES_FEMALE or LOCALIZED_CLASS_NAMES_MALE
  return names and file and names[file] or file
end

-- Describes the opponent for the journal text: "Orc Warrior, level 12" (whatever is known).
local function describe(foe)
  local bits = {}
  if foe.race then bits[#bits + 1] = foe.race end
  if foe.class then bits[#bits + 1] = className(foe.class) end
  local text = table.concat(bits, " ")
  if foe.level then
    local lv = string.format(de() and "Stufe %d" or "level %d", foe.level)
    text = text ~= "" and (text .. ", " .. lv) or lv
  end
  return text
end

local function record(kind, foe)
  local p = ensure(); if not p then return end
  local now = time()
  local level = UnitLevel("player")
  local zone, subZone = GetZoneText(), GetSubZoneText()
  local mapID, x, y
  if MCF.PlayerPosition then mapID, x, y = MCF.PlayerPosition() end -- (not `a and f()`: that would cut the result to one value)
  if kind == "kill" then p.kills = p.kills + 1 else p.deaths = p.deaths + 1 end
  if kind == "kill" then
    if foe.class then p.byClass[foe.class] = (p.byClass[foe.class] or 0) + 1 end
    local zoneKey = (zone and zone ~= "") and zone or "?"
    p.byZone[zoneKey] = (p.byZone[zoneKey] or 0) + 1
    if level then p.byLevel[level] = (p.byLevel[level] or 0) + 1 end
  end
  table.insert(p.history, {time = now, type = kind, level = level, mapID = mapID, x = x, y = y, zone = zone, subZone = subZone,
    class = foe.class, race = foe.race, enemyLevel = foe.level})
  while #p.history > P.historyLimit do table.remove(p.history, 1) end
  if MCF.AddEvent then
    MCF:AddEvent(kind == "kill" and "PVP_KILL" or "PVP_DEATH", {class = foe.class, race = foe.race, enemyLevel = foe.level})
  end
  -- first of its kind: photo and journal entry
  local firstKey = kind == "kill" and "firstKill" or "firstDeath"
  if not p[firstKey] then
    p[firstKey] = now
    local who = describe(foe)
    local title, text
    if kind == "kill" then
      title = de() and "Erster Spielerkill" or "First player kill"
      text = who ~= "" and string.format(de() and "Du hast einen Spieler besiegt: %s." or "You defeated a player: %s.", who)
        or (de() and "Du hast einen Spieler besiegt." or "You defeated a player.")
    else
      title = de() and "Erster Tod durch einen Spieler" or "First death by a player"
      text = who ~= "" and string.format(de() and "Besiegt von: %s." or "Defeated by: %s.", who)
        or (de() and "Du wurdest von einem Spieler besiegt." or "You were defeated by a player.")
    end
    if MCF.AutoMoment then
      MCF:AutoMoment{reason = kind == "kill" and "PVP_FIRST_KILL" or "PVP_FIRST_DEATH", shotKey = "screenshotPvp", journalKey = "pvpJournal",
        delay = P.momentDelay, force = true, source = kind == "kill" and "PVP_FIRST_KILL" or "PVP_FIRST_DEATH",
        fields = {pvpClass = foe.class, pvpRace = foe.race, pvpLevel = foe.level}, title = title, text = text}
    end
  end
  if MCF.RefreshMapJourney then MCF:RefreshMapJourney() end
  if MCF.RefreshUI then MCF:RefreshUI() end
end

-- Class, race and level of the dead enemy player if we are targeting it right now.
local function targetFoe()
  local foe = {}
  if not (UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target")) then return foe end
  local ok, class = pcall(function() return select(2, UnitClass("target")) end)
  if ok then foe.class = safe(class) end
  local okr, race = pcall(function() return select(2, UnitRace("target")) end)
  if okr then foe.race = safe(race) end
  local lv = safe(UnitLevel("target"))
  if type(lv) == "number" and lv > 0 then foe.level = lv end
  return foe
end

local lastKill, lastDeath = 0, 0

function MCF:OnPvPKill()
  if not setting("recordPvp", true) then return end
  local p = ensure(); if not p then return end
  local now = GetTime()
  if now - lastKill < P.dedupe then return end
  lastKill = now
  if inPvPInstance() then p.bgKills = p.bgKills + 1; return end
  record("kill", targetFoe())
end

-- Called by DeathCause.lua when the Death Recap names a player as the killer.
function MCF:OnPvPDeath(killerGUID)
  if not setting("recordPvp", true) then return end
  local p = ensure(); if not p then return end
  local now = GetTime()
  if now - lastDeath < P.deathDedupe then return end
  lastDeath = now
  if inPvPInstance() then p.bgDeaths = p.bgDeaths + 1; return end
  local foe = {}
  local guid = safe(killerGUID)
  if type(guid) == "string" and GetPlayerInfoByGUID then
    local ok, _, classFile, _, raceFile = pcall(GetPlayerInfoByGUID, guid)
    if ok then foe.class, foe.race = safe(classFile), safe(raceFile) end
  end
  record("death", foe)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- "%s dies, honorable kill Rank: %s (%d Honor Points)" -> Lua pattern (any placeholder like %s, %d, %.2f, %1$s matches anything)
local function formatToPattern(fmt)
  if type(fmt) ~= "string" or fmt == "" then return nil end
  local marked = fmt:gsub("%%[%d%$%.]*[sdf]", "\1")
  marked = marked:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  return "^" .. marked:gsub("\1", ".-") .. "$"
end
P.formatToPattern = formatToPattern

local patterns
local function isKillLine(message)
  if type(message) ~= "string" then return false end
  if not patterns then
    patterns = {}
    for _, key in ipairs({"COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK"}) do
      local pat = formatToPattern(_G[key])
      if pat then patterns[#patterns + 1] = pat end
    end
  end
  for _, pat in ipairs(patterns) do if message:match(pat) then return true end end
  return false
end
P.isKillLine = isKillLine

local frame = CreateFrame("Frame")
pcall(function() frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN") end)
pcall(function() frame:RegisterEvent("PLAYER_PVP_KILLS_CHANGED") end)
frame:SetScript("OnEvent", function(_, event, message)
  if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
    if isKillLine(safe(message)) then pcall(MCF.OnPvPKill, MCF) end
  else
    pcall(MCF.OnPvPKill, MCF)
  end
end)

function MCF:GetPvPSummary()
  return ensure()
end

-- Debug: /mcf pvptest [kill|death|clear] puts a fake kill or death at your position (map pin, history row), without touching
-- the counters, the first-kill/first-death moments or the export statistics; /mcf pvptest clear removes every fake.
MCF:AddCommand{group="debug", usage="/mcf pvptest [kill|death|clear]", key="pvptest",
  de="Test-Marker fuer PvP auf die Karte setzen (kill, death) oder entfernen (clear)", en="Put a fake PvP marker on the map (kill, death) or remove them (clear)",
  run=function(arg)
    local p = ensure(); if not p then return end
    local what = tostring(arg or ""):lower():match("%a+") or "kill"
    local function say(t) print("|cff00ccffMyCharForever|r: " .. t) end
    if what == "clear" then
      local n = 0
      for i = #p.history, 1, -1 do if p.history[i].test then table.remove(p.history, i); n = n + 1 end end
      if MCF.RefreshMapJourney then MCF:RefreshMapJourney() end
      say((de() and "Test-Marker entfernt: " or "Test markers removed: ") .. n); return
    end
    if what ~= "kill" and what ~= "death" then what = "kill" end
    local mapID, x, y
    if MCF.PlayerPosition then mapID, x, y = MCF.PlayerPosition() end
    if not (mapID and x and y) then say(de() and "Keine Kartenposition verfuegbar (Instanz?)." or "No map position available (instance?)."); return end
    table.insert(p.history, {time = time(), type = what, level = UnitLevel("player"), mapID = mapID, x = x, y = y,
      zone = GetZoneText(), subZone = GetSubZoneText(), class = "WARRIOR", race = "Orc", enemyLevel = UnitLevel("player"), test = true})
    if MCF.RefreshMapJourney then MCF:RefreshMapJourney() end
    say(de() and ("Test-Marker gesetzt (" .. what .. "). Entfernen mit /mcf pvptest clear") or ("Test marker placed (" .. what .. "). Remove with /mcf pvptest clear"))
  end}

MCF:AddCommand{group="main", usage="/mcf pvp", key="pvp",
  de="PvP-Bilanz anzeigen (Spielerkills und -tode in der offenen Welt)", en="Show PvP totals (player kills and deaths in the open world)",
  run=function()
    local p = ensure()
    local line = p and string.format(de() and "Kills %d, Tode durch Spieler %d (Schlachtfelder: %d / %d)" or "Kills %d, deaths by players %d (battlegrounds: %d / %d)",
      p.kills, p.deaths, p.bgKills, p.bgDeaths) or "-"
    print("|cff00ccffMyCharForever|r: " .. line)
  end}
