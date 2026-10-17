local addonName, MCF = ...
-- Things that cannot be caught up later: time spent in states (combat, mounted, dead ...), how long each item was worn,
-- talents and stats per level, skills and languages, XP by source, the game version and enchanted items.
-- Everything lands in ONE saved key, db.tracking (exported as it is, see docs/EXPORT_SCHEMA.md):
--   time.byLevel[level]      seconds per state (tracked = total watched seconds; states may overlap, e.g. mounted + group)
--   wear.items[itemID]       seconds each item was worn (only items worn >= wearMinSeconds in one go), wear.slots[slotID] = stints
--   levels[level]            snapshot when the level was reached: game build, stats, talents, skills, languages
--   talentLog[]              every change of the talent points (learn / respec)
--   xp.byLevel[level]        XP by source (kill, quest, explore, other) and rested bonus used
--   enchant                  enchanted items seen while worn, first time, "all slots" time
--   capitals[id]             real entries into a capital city (visits, byLevel, first, last)
--   quests                   how long quests stayed in the quest log (active, byLevel, longest, widest, done)
-- Every game call is guarded: a missing function leaves a gap in the data, it never breaks the addon (/mcf trackcheck shows which ones exist).

MCF.Tracking = {
  tick = 1,               -- seconds between state samples
  maxStep = 5,            -- a longer gap (loading screen, sleep) is not counted
  wearMinSeconds = 300,   -- an item counts as "worn" after this many seconds in one go (changing clothes does not count)
  wearReadyDelay = 8,     -- seconds after entering the world before gear is read (the client reports empty slots while loading)
  historyMax = 60,        -- stints kept per slot
  talentLogMax = 300,
  levelSnapshotDelay = 4, -- seconds after a level-up (stats update a moment later)
  loginSnapshotDelay = 12,
  xpResolveDelay = 0.5,   -- XP is classified a moment after it arrived, when the matching chat / quest events are known
  xpWindow = 3,           -- seconds in which a quest / discovery / kill message belongs to an XP gain
  -- Slots a normal enchant can go on in this game (a shield / off-hand is not required)
  enchantSlots = {5, 9, 10, 8, 15, 16},
}
local Cfg = MCF.Tracking

local function tbl(v) return type(v) == "table" and v or {} end
local function safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function num(v) v = safe(v); return type(v) == "number" and v or nil end
local function round1(v) return math.floor(v * 10 + 0.5) / 10 end
local function call(f, ...)
  if type(f) ~= "function" then return nil end
  local ok, a, b, c, d, e, g, h = pcall(f, ...)
  if ok then return a, b, c, d, e, g, h end
  return nil
end
local function flag(f, ...) local v = call(f, ...); return v and v ~= 0 and true or false end

local function data()
  local d = MyCharForeverDB
  if not d then return nil end
  d.tracking = d.tracking or {}
  local t = d.tracking
  t.time = t.time or {}; t.time.byLevel = t.time.byLevel or {}
  t.wear = t.wear or {}; t.wear.items = t.wear.items or {}; t.wear.pending = t.wear.pending or {}; t.wear.slots = t.wear.slots or {}
  t.levels = t.levels or {}
  t.talentLog = t.talentLog or {}
  t.xp = t.xp or {}; t.xp.byLevel = t.xp.byLevel or {}
  t.enchant = t.enchant or {}; t.enchant.items = t.enchant.items or {}; t.enchant.count = t.enchant.count or 0
  t.capitals = t.capitals or {}
  t.quests = t.quests or {}; t.quests.active = t.quests.active or {}; t.quests.byLevel = t.quests.byLevel or {}; t.quests.done = t.quests.done or 0
  return t
end

---------------------------------------------------------------------------
-- Time in states
---------------------------------------------------------------------------
local lastTick
local readyAt = 0

local function formName()
  local idx = num(call(GetShapeshiftForm))
  if not idx or idx <= 0 then return nil end
  local a, b, c, d, e = call(GetShapeshiftFormInfo, idx)
  for _, v in ipairs({b, a, c, d, e}) do
    if type(v) == "string" and not v:find("[\\/]") and v ~= "" then return v end
    if type(v) == "number" and v > 1000 then
      local n = call(GetSpellInfo, v)
      if type(n) == "string" then return n end
    end
  end
  return "form" .. idx
end

-- The states, one place: key -> how it is detected.
local function sampleState()
  local s = {}
  s.combat = flag(UnitAffectingCombat, "player")
  s.mounted = flag(IsMounted)
  local dead = flag(UnitIsDeadOrGhost, "player")
  s.ghost = flag(UnitIsGhost, "player")
  s.dead = dead and not s.ghost
  s.swim = flag(IsSwimming)
  s.taxi = flag(UnitOnTaxi, "player")
  s.resting = flag(IsResting)
  s.group = flag(IsInGroup)
  s.solo = not s.group
  local _, itype = call(IsInInstance)
  s.dungeon = itype == "party"
  s.raid = itype == "raid"
  s.bg = itype == "pvp" or itype == "arena"
  return s
end

local function stintHistory(w, slot, id, lvl)
  local h = w.slots[slot]
  if not h then h = {}; w.slots[slot] = h end
  local cur = h[#h]
  if cur and cur.to == nil and cur.id == id then return end
  local now = time()
  if cur and cur.to == nil then
    cur.to = now; cur.toLevel = lvl
    if now - cur.from < Cfg.wearMinSeconds then table.remove(h) end -- changing clothes, not wearing
  end
  if id then h[#h + 1] = {id = id, from = now, fromLevel = lvl} end
  while #h > Cfg.historyMax do table.remove(h, 1) end
end

local function trackWear(t, dt, lvl)
  local w = t.wear
  local worn = {}
  for _, s in ipairs(MCF.EQUIPMENT_SLOTS or {}) do
    local slot = s[1]
    local id = num(call(GetInventoryItemID, "player", slot))
    if id then
      worn[id] = true
      local rec = w.items[id]
      if rec then
        rec.seconds = round1(rec.seconds + dt)
        rec.last = time()
        rec.byLevel[lvl] = round1((rec.byLevel[lvl] or 0) + dt)
      else
        local p = (w.pending[id] or 0) + dt
        if p >= Cfg.wearMinSeconds then
          w.pending[id] = nil
          w.items[id] = {slot = slot, seconds = round1(p), first = time() - math.floor(p), last = time(),
                         link = call(GetInventoryItemLink, "player", slot), byLevel = {[lvl] = round1(p)}}
        else
          w.pending[id] = p
        end
      end
    end
    stintHistory(w, slot, id, lvl)
  end
  for id in pairs(w.pending) do if not worn[id] then w.pending[id] = nil end end
end

local function onTick()
  local t = data()
  if not t then return end
  local now = GetTime()
  local dt = now - (lastTick or now)
  lastTick = now
  if dt <= 0 or dt > Cfg.maxStep then return end
  local lvl = UnitLevel("player") or 0
  local row = t.time.byLevel[lvl]
  if not row then row = {tracked = 0}; t.time.byLevel[lvl] = row end
  row.tracked = round1(row.tracked + dt)
  for k, v in pairs(sampleState()) do
    if v then row[k] = round1((row[k] or 0) + dt) end
  end
  local f = formName()
  if f then row.forms = row.forms or {}; row.forms[f] = round1((row.forms[f] or 0) + dt) end
  if now >= readyAt then trackWear(t, dt, lvl) end
end

---------------------------------------------------------------------------
-- Snapshot per level: game version, stats, talents, skills, languages
---------------------------------------------------------------------------
local function gameInfo()
  local v, b, d, toc = call(GetBuildInfo)
  return {v = v, b = b, d = d, toc = toc, addon = MCF.VERSION}
end

local function pct(v) v = num(v); return v and math.floor(v * 100 + 0.5) / 100 or nil end

local function statsSnapshot()
  local s = {}
  for i, n in ipairs({"str", "agi", "sta", "int", "spi"}) do
    local base, eff = call(UnitStat, "player", i)
    base, eff = num(base), num(eff)
    if base then s[n] = {base, eff} end
  end
  local _, armor = call(UnitArmor, "player")
  s.armor = num(armor)
  s.hp = num(call(UnitHealthMax, "player"))
  s.power = num(call(UnitPowerMax, "player"))
  s.powerType = num(call(UnitPowerType, "player"))
  local ab, ap, an = call(UnitAttackPower, "player")
  if num(ab) then s.ap = ab + (num(ap) or 0) + (num(an) or 0) end
  s.crit = pct(call(GetCritChance))
  s.rangedCrit = pct(call(GetRangedCritChance))
  s.spellCrit = pct(call(GetSpellCritChance, 2))
  s.dodge = pct(call(GetDodgeChance))
  s.parry = pct(call(GetParryChance))
  s.block = pct(call(GetBlockChance))
  s.spellPower = num(call(GetSpellBonusDamage, 2))
  s.healPower = num(call(GetSpellBonusHealing))
  return s
end

local function talentSnapshot()
  if type(GetNumTalentTabs) ~= "function" or type(GetTalentTabInfo) ~= "function" or type(GetTalentInfo) ~= "function" then
    return {api = "none"}
  end
  local tabs, list, total = {}, {}, 0
  local bestName, bestSpent = nil, -1
  for tab = 1, (num(call(GetNumTalentTabs)) or 0) do
    local a, b, c, d, e = call(GetTalentTabInfo, tab)
    local name, spent
    if type(a) == "number" then name, spent = b, e else name, spent = a, c end
    spent = num(spent) or 0
    tabs[#tabs + 1] = {name, spent}
    total = total + spent
    if spent > bestSpent then bestSpent, bestName = spent, name end
    for i = 1, (num(call(GetNumTalents, tab)) or 0) do
      local nm, _, _, _, rank = call(GetTalentInfo, tab, i)
      rank = num(rank)
      if type(nm) == "string" and rank and rank > 0 then list[#list + 1] = {nm, rank, tab} end
    end
  end
  return {api = "classic", points = total, unspent = num(call(GetUnspentTalentPoints)), spec = (bestSpent > 0) and bestName or nil, tabs = tabs, list = list}
end

local function skillSnapshot()
  if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then return nil end
  -- Lines under a collapsed header are not listed: open all, read, then close the same headers again.
  local closed = {}
  local n0 = num(call(GetNumSkillLines)) or 0
  for i = 1, n0 do
    local name, isHeader, isExpanded = call(GetSkillLineInfo, i)
    if isHeader and not isExpanded then closed[name] = true end
  end
  if next(closed) then call(ExpandSkillHeader, 0) end
  local out, header = {}, "?"
  for i = 1, (num(call(GetNumSkillLines)) or 0) do
    local name, isHeader, _, rank, _, _, maxRank = call(GetSkillLineInfo, i)
    if type(name) == "string" then
      if isHeader then header = name; out[header] = out[header] or {}
      else
        out[header] = out[header] or {}
        local list = out[header]
        list[#list + 1] = {name, num(rank), num(maxRank)}
      end
    end
  end
  if next(closed) then
    for i = (num(call(GetNumSkillLines)) or 0), 1, -1 do
      local name, isHeader = call(GetSkillLineInfo, i)
      if isHeader and closed[name] then call(CollapseSkillHeader, i) end
    end
  end
  return out
end

local function languagesSnapshot()
  local n = num(call(GetNumLanguages))
  if not n then return nil end
  local out = {}
  for i = 1, n do
    local l = call(GetLanguageByIndex, i)
    if type(l) == "string" then out[#out + 1] = l end
  end
  return out
end

function MCF:CaptureTrackingLevel(level, reason)
  local t = data()
  if not t then return nil end
  level = level or UnitLevel("player") or 0
  local old = t.levels[level]
  if old and old.reason == "levelup" and reason ~= "levelup" then return old end -- the level-up moment is the real one
  local rec = {time = time(), reason = reason, game = gameInfo()}
  local ok, v = pcall(statsSnapshot); rec.stats = ok and v or nil
  ok, v = pcall(talentSnapshot); rec.talents = ok and v or nil
  ok, v = pcall(skillSnapshot); rec.skills = ok and v or nil
  ok, v = pcall(languagesSnapshot); rec.languages = ok and v or nil
  t.levels[level] = rec
  return rec
end

---------------------------------------------------------------------------
-- Talent log
---------------------------------------------------------------------------
local talentPending
function MCF:CheckTalentChange()
  local t = data()
  if not t then return end
  local snap = talentSnapshot()
  if snap.api ~= "classic" then return end
  local cur = {}
  for _, e in ipairs(snap.list) do cur[e[1]] = e[2] end
  local last = t.talentLast
  t.talentLast = {ranks = cur, points = snap.points}
  if not last then return end -- first look: only the starting point
  local changes = {}
  for name, rank in pairs(cur) do
    local was = (last.ranks and last.ranks[name]) or 0
    if rank ~= was then changes[#changes + 1] = {name, was, rank} end
  end
  for name, was in pairs(tbl(last.ranks)) do
    if not cur[name] then changes[#changes + 1] = {name, was, 0} end
  end
  if #changes == 0 then return end
  local log = t.talentLog
  log[#log + 1] = {time = time(), level = UnitLevel("player"), points = snap.points, spec = snap.spec,
                   kind = (snap.points < (last.points or 0)) and "respec" or "learn", changes = changes}
  while #log > Cfg.talentLogMax do table.remove(log, 1) end
end

local function scheduleTalentCheck()
  if talentPending then return end
  talentPending = true
  C_Timer.After(2, function() talentPending = false; pcall(MCF.CheckTalentChange, MCF) end)
end

---------------------------------------------------------------------------
-- XP by source
---------------------------------------------------------------------------
local xp = {at = {}}
local EXPLORE_PATTERN
do
  local fmt = _G.ERR_ZONE_EXPLORED_XP or "Discovered %s: %d experience gained"
  local p = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  p = p:gsub("%%%%s", ".+")
  p = p:gsub("%%%%d", "%%d+")
  EXPLORE_PATTERN = p
end

local function xpReading()
  return num(call(UnitXP, "player")), num(call(UnitXPMax, "player")), UnitLevel("player"), num(call(GetXPExhaustion)) or 0
end

local function resolveXP(delta, lvl, exhDrop, at)
  local t = data()
  if not t then return end
  local w = Cfg.xpWindow
  -- The source is the event closest in time to the gain (quest wins a tie, then discovery).
  local src, best = "other", w + 0.001
  for _, c in ipairs({{"quest", xp.at.quest}, {"explore", xp.at.explore}, {"kill", xp.at.kill}}) do
    local d = c[2] and math.abs(c[2] - at)
    if d and d <= w and d < best then src, best = c[1], d end
  end
  local row = t.xp.byLevel[lvl]
  if not row then row = {}; t.xp.byLevel[lvl] = row end
  row[src] = (row[src] or 0) + delta
  row.total = (row.total or 0) + delta
  if src == "kill" and exhDrop > 0 then row.rested = (row.rested or 0) + math.min(exhDrop, delta) end
end

local function onXPUpdate()
  local cur, mx, lvl, exh = xpReading()
  if cur and xp.last then
    local delta
    if lvl == xp.last.level then delta = cur - xp.last.xp else delta = (xp.last.max or 0) - xp.last.xp + cur end
    if delta and delta > 0 then
      local at, rowLevel, drop = GetTime(), xp.last.level, math.max(0, xp.last.exh - exh)
      C_Timer.After(Cfg.xpResolveDelay, function() pcall(resolveXP, delta, rowLevel, drop, at) end)
    end
  end
  if cur then xp.last = {xp = cur, max = mx, level = lvl, exh = exh} end
end

---------------------------------------------------------------------------
-- Enchants
---------------------------------------------------------------------------
local scanPending
function MCF:ScanEnchants()
  local t = data()
  if not t then return end
  local e = t.enchant
  local lvl = UnitLevel("player") or 0
  local added = false
  local bySlot = {}
  for _, s in ipairs(MCF.EQUIPMENT_SLOTS or {}) do
    local slot = s[1]
    local link = call(GetInventoryItemLink, "player", slot)
    if type(link) == "string" then
      local itemID, ench = link:match("item:(%d+):(%d*)")
      itemID, ench = tonumber(itemID), tonumber(ench) or 0
      if itemID and ench > 0 then
        bySlot[slot] = true
        local key = itemID .. ":" .. ench
        if not e.items[key] then
          e.items[key] = {time = time(), level = lvl, slot = slot, item = itemID, enchant = ench}
          e.count = e.count + 1
          added = true
          if not e.first then e.first = {time = time(), level = lvl, slot = slot, item = itemID, enchant = ench} end
        end
      end
    end
  end
  if not e.allSlots then
    local all = true
    for _, slot in ipairs(Cfg.enchantSlots) do if not bySlot[slot] then all = false; break end end
    if all then e.allSlots = {time = time(), level = lvl}; added = true end
  end
  if added and MCF.CheckAchievements then C_Timer.After(1, function() MCF:CheckAchievements() end) end
end

local function scheduleEnchantScan()
  if scanPending then return end
  scanPending = true
  C_Timer.After(1.5, function() scanPending = false; pcall(MCF.ScanEnchants, MCF) end)
end

---------------------------------------------------------------------------
-- Capital visits (called from Iconic.lua when a real entry was seen)
---------------------------------------------------------------------------
-- onlyIfNone: the first sighting (e.g. logged in inside the city) counts once if no visit is stored yet, never again
function MCF:CountCapitalVisit(id, onlyIfNone)
  local t = data()
  if not t or type(id) ~= "string" then return end
  local rec = t.capitals[id]
  if not rec then rec = {visits = 0, byLevel = {}}; t.capitals[id] = rec end
  if onlyIfNone and rec.visits > 0 then return end
  local lvl = UnitLevel("player") or 0
  rec.visits = rec.visits + 1
  rec.byLevel[lvl] = (rec.byLevel[lvl] or 0) + 1
  rec.first = rec.first or {time = time(), level = lvl}
  rec.last = time()
end

---------------------------------------------------------------------------
-- Quests: how long each one stays in the quest log
---------------------------------------------------------------------------
-- Measured in levels gained and in watched ("played") seconds between accepting and handing in. Quests abandoned do not count.
-- Quests already in the log when the addon first looks are measured from that moment (so the time can only be too short).
-- active[key] = {id, title, level (player level at accepting), trk (tracked seconds then), time, gone (time it left the log)}
-- byLevel[level] = the quest that had been in the log the longest when that level ended (booked at the level-up, on the level before);
-- a quest handed in right before the level-up still counts. longest / widest = overall by seconds / by levels (handed in or still active); done = handed in
local GONE_AFTER = 20 -- seconds a quest must be missing before it counts as left (log not loaded yet, collapsed headers ...)

local function trackedNow(t)
  local sum = 0
  for _, row in pairs(tbl(t.time and t.time.byLevel)) do sum = sum + (tonumber(tbl(row).tracked) or 0) end
  return sum
end

-- Quests in the log right now: key -> {id, title}, plus whether some header is collapsed (its quests are not listed then)
local function readQuestLog()
  local out, collapsed, seen = {}, false, 0
  local n
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    n = num(call(C_QuestLog.GetNumQuestLogEntries))
    for i = 1, (n or 0) do
      local info = call(C_QuestLog.GetInfo, i)
      if type(info) == "table" then
        if info.isHeader then
          if info.isCollapsed then collapsed = true end
        else
          local id, title = num(info.questID), safe(info.title)
          if id or title then out[id and ("q" .. id) or ("t" .. title)] = {id = id, title = title}; seen = seen + 1 end
        end
      end
    end
  elseif type(GetNumQuestLogEntries) == "function" and type(GetQuestLogTitle) == "function" then
    n = num(call(GetNumQuestLogEntries))
    for i = 1, (n or 0) do
      local title, _, _, isHeader, isCollapsed, _, _, id = call(GetQuestLogTitle, i)
      if isHeader then
        if isCollapsed then collapsed = true end
      else
        id, title = num(id), safe(title)
        if id or title then out[id and ("q" .. id) or ("t" .. title)] = {id = id, title = title}; seen = seen + 1 end
      end
    end
  else
    return nil
  end
  return out, collapsed
end

local function stillInLog(rec, key, current, collapsed)
  if current[key] then return true end
  if rec.id and C_QuestLog and C_QuestLog.IsOnQuest then
    local on = call(C_QuestLog.IsOnQuest, rec.id)
    if on ~= nil then return on and true or false end
  end
  return collapsed -- cannot tell: a collapsed header hides quests, so keep it
end

local recentFinished = {} -- quests handed in a moment ago (the hand-in usually comes right before the level-up)
local function finishQuest(t, key, rec, level)
  local qs = t.quests
  local secs = math.max(0, trackedNow(t) - (rec.trk or 0))
  local span = math.max(0, (level or UnitLevel("player") or 0) - (rec.level or 0))
  local r = {id = rec.id, title = rec.title, sec = round1(secs), span = span, from = rec.level, to = level, time = time()}
  qs.done = qs.done + 1
  recentFinished[#recentFinished + 1] = {rec = rec, sec = r.sec, at = GetTime()}
  if #recentFinished > 6 then table.remove(recentFinished, 1) end
  if not qs.longest or r.sec > (qs.longest.sec or 0) then qs.longest = r end
  if not qs.widest or r.span > (qs.widest.span or 0) then qs.widest = r end
  qs.active[key] = nil
end

-- Level ended: book the quest that was in the log the longest (seconds; levels as the tie-break) on that level.
-- Quests handed in within the last seconds count too: the quest that gave the last XP was in the log all level long.
function MCF:BookQuestLevelEnd(prevLevel)
  local t = data()
  prevLevel = tonumber(prevLevel)
  if not t or not prevLevel or prevLevel < 1 then return end
  local best
  local now = trackedNow(t)
  local function consider(rec, sec)
    local span = math.max(0, prevLevel - (tonumber(rec.level) or prevLevel))
    if not best or sec > best.sec or (sec == best.sec and span > best.span) then
      best = {id = rec.id, title = rec.title, sec = round1(sec), span = span, from = rec.level, time = time()}
    end
  end
  for _, rec in pairs(t.quests.active) do
    if type(rec) == "table" and not rec.gone then consider(rec, math.max(0, now - (tonumber(rec.trk) or 0))) end
  end
  local g = GetTime()
  for _, f in ipairs(recentFinished) do if g - f.at <= 8 then consider(f.rec, f.sec) end end
  if best then t.quests.byLevel[prevLevel] = best end
end

-- The quest that has been in the log the longest right now (for the level in progress)
function MCF:GetOldestActiveQuest(db)
  local tr = tbl((db or MyCharForeverDB) and (db or MyCharForeverDB).tracking)
  local now, lvl, best = trackedNow(tr), UnitLevel("player") or 0, nil
  for _, rec in pairs(tbl(tr.quests and tr.quests.active)) do
    if type(rec) == "table" and not rec.gone then
      local sec = math.max(0, now - (tonumber(rec.trk) or 0))
      if not best or sec > best.sec then
        best = {id = rec.id, title = rec.title, sec = sec, span = math.max(0, lvl - (tonumber(rec.level) or lvl)), from = rec.level, active = true}
      end
    end
  end
  return best
end

local questScanPending
function MCF:ScanQuestLog()
  local t = data()
  if not t then return end
  local current, collapsed = readQuestLog()
  if not current then return end
  local qs, lvl, now = t.quests, UnitLevel("player") or 0, time()
  local anyGone = false
  for key, q in pairs(current) do
    local rec = qs.active[key]
    if rec then
      rec.gone = nil
      rec.title = rec.title or q.title
    else
      qs.active[key] = {id = q.id, title = q.title, level = lvl, trk = round1(trackedNow(t)), time = now}
    end
  end
  for key, rec in pairs(qs.active) do
    if not current[key] and not stillInLog(rec, key, current, collapsed) then
      if not rec.gone then rec.gone = now; anyGone = true
      elseif now - rec.gone >= GONE_AFTER then qs.active[key] = nil -- abandoned (a hand-in has already removed it)
      else anyGone = true end
    end
  end
  if anyGone and not questScanPending then
    questScanPending = true
    C_Timer.After(GONE_AFTER + 2, function() questScanPending = false; pcall(MCF.ScanQuestLog, MCF) end)
  end
end

local questDebounce
local function scheduleQuestScan()
  if questDebounce then return end
  questDebounce = true
  C_Timer.After(2, function() questDebounce = false; pcall(MCF.ScanQuestLog, MCF) end)
end

local function questTurnedIn(questID)
  local t = data()
  questID = num(questID)
  if not t or not questID then return end
  local key = "q" .. questID
  local rec = t.quests.active[key]
  if not rec then
    -- title based record (no id from the game) or a quest we never saw
    local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and safe(call(C_QuestLog.GetTitleForQuestID, questID))
    if title and t.quests.active["t" .. title] then key = "t" .. title; rec = t.quests.active[key] end
  end
  if rec then
    finishQuest(t, key, rec, UnitLevel("player") or 0)
    if MCF.CheckAchievements then C_Timer.After(1, function() MCF:CheckAchievements() end) end
  end
end

function MCF:FormatQuestLogRecord(r)
  if type(r) ~= "table" then return "-" end
  return string.format("%s  (%s, %d %s%s)", tostring(r.title or ("#" .. tostring(r.id or "?"))), MCF:FormatDuration(r.sec or 0),
    r.span or 0, MCF:T("Level"), r.active and (", " .. MCF:T("still in the log")) or "")
end

-- Compact variant for narrow value columns: "Quest name…  6m 50s". The name is cut (UTF-8 safe) so the line stays short.
MCF.QUEST_NAME_MAX = 22 -- single source of truth for the name length in the compact line
function MCF:FormatQuestLogRecordShort(r)
  if type(r) ~= "table" then return "-" end
  local name = tostring(r.title or ("#" .. tostring(r.id or "?")))
  local max = MCF.QUEST_NAME_MAX
  local n, pos = 0, 1
  while pos <= #name do
    n = n + 1
    if n > max then name = name:sub(1, pos - 1) .. "..."; break end
    local c = name:byte(pos)
    pos = pos + (c >= 240 and 4 or c >= 224 and 3 or c >= 192 and 2 or 1)
  end
  local sec = math.max(0, math.floor(tonumber(r.sec) or 0))
  local d, h, m, x = math.floor(sec / 86400), math.floor(sec % 86400 / 3600), math.floor(sec % 3600 / 60), sec % 60
  local t
  if d > 0 then t = string.format("%dd %dh %dm %ds", d, h, m, x)
  elseif h > 0 then t = string.format("%dh %dm %ds", h, m, x)
  elseif m > 0 then t = string.format("%dm %ds", m, x)
  else t = string.format("%ds", x) end
  return name .. "  " .. t
end

-- Longest times, including quests still in the log (for achievements, display and export-independent use).
-- Returns bestSeconds, bestLevels, and the records behind them.
function MCF:GetQuestLogStats(db)
  local tr = tbl((db or MyCharForeverDB) and (db or MyCharForeverDB).tracking)
  local qs = tbl(tr.quests)
  local bestSec, bestSpan = tbl(qs.longest), tbl(qs.widest)
  local sec, span = tonumber(bestSec.sec) or 0, tonumber(bestSpan.span) or 0
  local recSec, recSpan = qs.longest, qs.widest
  local now, lvl = trackedNow(tr), UnitLevel("player") or 0
  for _, rec in pairs(tbl(qs.active)) do
    if type(rec) == "table" and not rec.gone then
      local s2 = math.max(0, now - (tonumber(rec.trk) or 0))
      local l2 = math.max(0, lvl - (tonumber(rec.level) or lvl))
      if s2 > sec then sec, recSec = s2, {id = rec.id, title = rec.title, sec = s2, span = l2, from = rec.level, active = true} end
      if l2 > span then span, recSpan = l2, {id = rec.id, title = rec.title, sec = s2, span = l2, from = rec.level, active = true} end
    end
  end
  return sec, span, recSec, recSpan
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local EVENTS = {"PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED",
  "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_SYSTEM", "UI_INFO_MESSAGE", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "CONFIRM_TALENT_WIPE"}
for _, ev in ipairs(EVENTS) do pcall(frame.RegisterEvent, frame, ev) end

local ticker
local function start()
  lastTick = GetTime()
  if ticker then ticker:Cancel() end
  ticker = C_Timer.NewTicker(Cfg.tick, function() pcall(onTick) end)
end

frame:SetScript("OnEvent", function(_, event, a, b)
  if not MyCharForeverDB then return end
  if event == "PLAYER_ENTERING_WORLD" then
    readyAt = GetTime() + Cfg.wearReadyDelay
    local cur, mx, lvl, exh = xpReading()
    if cur then xp.last = {xp = cur, max = mx, level = lvl, exh = exh} end
    if not ticker then start() end
    lastTick = GetTime()
    scheduleQuestScan()
    C_Timer.After(Cfg.loginSnapshotDelay, function()
      local t = data()
      local lvl2 = UnitLevel("player") or 0
      if t and not t.levels[lvl2] then pcall(MCF.CaptureTrackingLevel, MCF, lvl2, "login") end
      pcall(MCF.CheckTalentChange, MCF)
      pcall(MCF.ScanEnchants, MCF)
    end)
  elseif event == "PLAYER_LEVEL_UP" then
    local level = tonumber(a)
    if level then pcall(MCF.BookQuestLevelEnd, MCF, level - 1) end
    if level then C_Timer.After(Cfg.levelSnapshotDelay, function() pcall(MCF.CaptureTrackingLevel, MCF, level, "levelup") end) end
  elseif event == "PLAYER_XP_UPDATE" then
    pcall(onXPUpdate)
  elseif event == "QUEST_TURNED_IN" then
    xp.at.quest = GetTime()
    pcall(questTurnedIn, a)
  elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_ACCEPTED" or event == "QUEST_REMOVED" then
    scheduleQuestScan()
  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
    xp.at.kill = GetTime()
  elseif event == "CHAT_MSG_SYSTEM" or event == "UI_INFO_MESSAGE" then
    local text = (event == "UI_INFO_MESSAGE") and b or a
    if type(text) == "string" and not (issecretvalue and issecretvalue(text)) and text:find(EXPLORE_PATTERN) then xp.at.explore = GetTime() end
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    scheduleEnchantScan()
  else -- talent events
    scheduleTalentCheck()
  end
end)

---------------------------------------------------------------------------
-- Summaries for other files
---------------------------------------------------------------------------
-- Seconds in a state over all levels (state "tracked" = all watched time).
function MCF:GetTrackedSeconds(state)
  local t = MyCharForeverDB and MyCharForeverDB.tracking
  local sum = 0
  for _, row in pairs(tbl(t and t.time and t.time.byLevel)) do sum = sum + (tonumber(tbl(row)[state]) or 0) end
  return sum
end

---------------------------------------------------------------------------
-- /mcf trackcheck: which sources this game version offers (nothing is changed or saved)
---------------------------------------------------------------------------
local function eventKnown(name)
  local f = CreateFrame("Frame")
  local ok = pcall(f.RegisterEvent, f, name)
  if ok then pcall(f.UnregisterEvent, f, name) end
  return ok
end

local function isGerman() return MCF:GetLanguage() == "deDE" end

function MCF:RunTrackCheck(full)
  local de = isGerman()
  local rows = {}
  local function line(ok, name, extra) rows[#rows + 1] = {ok = ok and true or false, name = name, extra = extra} end
  local function fn(name)
    if name == "GetItemInfoInstant" then return type(_G[name]) == "function" or (C_Item and type(C_Item.GetItemInfoInstant) == "function") or false end
    return type(_G[name]) == "function"
  end
  local groups = {
    {de and "Zeitarten" or "Time states", {"UnitAffectingCombat", "IsMounted", "UnitIsGhost", "UnitIsDeadOrGhost", "IsSwimming", "UnitOnTaxi", "IsResting", "IsInGroup", "IsInInstance", "GetShapeshiftForm", "GetShapeshiftFormInfo"}},
    {de and "Ausrüstung" or "Gear", {"GetInventoryItemID", "GetInventoryItemLink"}},
    {de and "Werte" or "Stats", {"UnitStat", "UnitArmor", "UnitAttackPower", "GetCritChance", "GetDodgeChance", "GetParryChance", "GetBlockChance", "GetSpellBonusDamage"}},
    {de and "Talente" or "Talents", {"GetNumTalentTabs", "GetTalentTabInfo", "GetNumTalents", "GetTalentInfo", "GetUnspentTalentPoints"}},
    {de and "Fertigkeiten, Sprachen" or "Skills, languages", {"GetNumSkillLines", "GetSkillLineInfo", "ExpandSkillHeader", "CollapseSkillHeader", "GetNumLanguages", "GetLanguageByIndex"}},
    {"XP", {"UnitXP", "UnitXPMax", "GetXPExhaustion"}},
    {de and "Spielversion" or "Game version", {"GetBuildInfo"}},
    {de and "Gold-Zuordnung" or "Gold sorting", {"BuyMerchantItem", "GetMerchantItemLink", "GetItemInfoInstant", "BuyTrainerService", "GetTrainerServiceInfo",
      "ConfirmTalentWipe", "TakeInboxMoney", "GetInboxInvoiceInfo", "TakeTaxiNode", "RepairAllItems", "InRepairMode", "PurchaseSlot"}},
  }
  for _, g in ipairs(groups) do
    local missing = {}
    for _, name in ipairs(g[2]) do if not fn(name) then missing[#missing + 1] = name end end
    line(#missing == 0, g[1], #missing > 0 and ((de and "fehlt: " or "missing: ") .. table.concat(missing, ", ")) or nil)
  end
  local questApi = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) or (fn("GetNumQuestLogEntries") and fn("GetQuestLogTitle"))
  line(questApi and true or false, de and "Questlog" or "Quest log", not questApi and (de and "weder C_QuestLog.GetInfo noch GetQuestLogTitle" or "neither C_QuestLog.GetInfo nor GetQuestLogTitle") or nil)
  local evs = {"MAIL_SHOW", "TRADE_SHOW", "GUILDBANKFRAME_OPENED", "BANKFRAME_OPENED", "TAXIMAP_OPENED", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "CONFIRM_TALENT_WIPE",
    "CHAT_MSG_COMBAT_XP_GAIN", "PLAYER_XP_UPDATE", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED"}
  local badEv = {}
  for _, e in ipairs(evs) do if not eventKnown(e) then badEv[#badEv + 1] = e end end
  line(#badEv == 0, de and "Ereignisse" or "Events", #badEv > 0 and ((de and "unbekannt: " or "unknown: ") .. table.concat(badEv, ", ")) or nil)
  line(_G.ERR_ZONE_EXPLORED_XP ~= nil, de and "Text für Entdeckungs-XP" or "Discovery XP text", _G.ERR_ZONE_EXPLORED_XP)
  -- Samples: what the sources return right now
  local ok, tal = pcall(talentSnapshot)
  if ok then line(tal.api == "classic", de and "Talente jetzt" or "Talents now", tal.api == "classic" and string.format("%s, %d %s", tostring(tal.spec or "-"), tal.points or 0, de and "Punkte" or "points") or "api=none") end
  local ok2, st = pcall(statsSnapshot)
  if ok2 then line(st.str ~= nil and st.hp ~= nil, de and "Werte jetzt" or "Stats now", string.format("STR %s HP %s", tostring(st.str and st.str[2]), tostring(st.hp))) end
  local ok3, sk = pcall(skillSnapshot)
  if ok3 then
    local n = 0
    for _, list in pairs(sk or {}) do n = n + #list end
    line(sk ~= nil and n > 0, de and "Fertigkeiten jetzt" or "Skills now", n .. (de and " Zeilen" or " lines"))
  end
  local okq, ql = pcall(readQuestLog)
  if okq and ql then
    local n = 0
    for _ in pairs(ql) do n = n + 1 end
    line(true, de and "Quests im Log jetzt" or "Quests in log now", tostring(n))
  end
  local t = MyCharForeverDB and MyCharForeverDB.tracking
  if t then
    line(MCF:GetTrackedSeconds("tracked") > 0, de and "Zeit erfasst" or "Time recorded", MCF:FormatDuration(MCF:GetTrackedSeconds("tracked")))
    local n = 0
    for _ in pairs(tbl(t.wear and t.wear.items)) do n = n + 1 end
    line(true, de and "Getragene Items (>= 5 Min.)" or "Worn items (>= 5 min)", tostring(n))
    local nq = 0
    for _ in pairs(tbl(t.quests and t.quests.active)) do nq = nq + 1 end
    line(true, de and "Quests im Zeitmesser" or "Quests being timed", nq .. (de and (", abgegeben: ") or (", handed in: ")) .. tostring(tbl(t.quests).done or 0))
  end
  -- Output: short by default (only problems), everything with "full"
  local bad = 0
  for _, r in ipairs(rows) do if not r.ok then bad = bad + 1 end end
  local head = "|cff00ccffMyCharForever|r " .. (de and "Tracking-Prüfung (ändert nichts): " or "Tracking check (changes nothing): ")
  if bad == 0 then head = head .. "|cff46d39a" .. (de and "alles in Ordnung" or "all good") .. "|r"
  else head = head .. "|cffff6b6b" .. bad .. (de and " Auffälligkeit(en)" or " problem(s)") .. "|r" end
  print(head .. (full and "" or ("  |cffaaaaaa(" .. (de and "Details: /mcf trackcheck full" or "details: /mcf trackcheck full") .. ")|r")))
  for _, r in ipairs(rows) do
    if full or not r.ok then
      print(string.format("|cff00ccffMCF|r %s %s%s", r.ok and "|cff46d39aOK|r  " or "|cffff6b6bFEHLT|r", r.name, r.extra and ("  |cffaaaaaa" .. r.extra .. "|r") or ""))
    end
  end
end

MCF:AddCommand{group = "debug", usage = "/mcf trackcheck [full]", example = "/mcf trackcheck full",
  match = function(msg) return msg == "trackcheck" or msg == "trackcheck full" end,
  de = "Prüft, welche Aufzeichnungsquellen dieses Spiel liefert; kurz = nur Auffälligkeiten, mit \"full\" alles",
  en = "Checks which recording sources this game provides; short = problems only, \"full\" = everything",
  run = function(msg) MCF:RunTrackCheck(msg == "trackcheck full") end}
