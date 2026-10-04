local _, FLT = ...
local UI = FLT.UI

-- Boss portraits: bundled art, known display IDs, the encounter journal and,
-- as a last resort, an asynchronous lookup through a hidden model frame.

local BOSS_PORTRAIT_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"

local STATIC_DISPLAY_IDS = {
  -- Wailing Caverns
  [3669] = 4213, [3671] = 4313, [3653] = 5126, [3670] = 4214,
  [3674] = 4203, [3673] = 4215, [5775] = 4256, [3654] = 4088, [5912] = 1267,
  -- The Deadmines
  [644] = 14403, [3586] = 556, [642] = 1269, [643] = 7125, [1763] = 7124,
  [646] = 2026, [647] = 7113, [639] = 2029, [645] = 1305,
  -- Blackfathom Deeps
  [4887] = 5027, [4831] = 4979, [6243] = 1773, [12902] = 12822,
  [12876] = 110, [4830] = 1816, [4832] = 4939, [4829] = 2837,
  -- Ragefire Chasm
  [11517] = 11611, [11520] = 7970, [11518] = 11429, [11519] = 2007,
  -- Shadowfang Keep
  [3914] = 524, [3864] = 1951, [3886] = 524, [3887] = 3222, [4278] = 3223,
  [4279] = 522, [3872] = 3224, [4627] = 1131, [4274] = 2352, [3927] = 11179,
  [4275] = 2353,
}

local journalCache = {}
local journalScanComplete = false

local function normalizeDungeonName(name)
  if type(name) ~= "string" then return nil end
  local n = string.lower(name)
  if string.find(n, "ragefire chasm", 1, true) then return "Ragefire Chasm" end
  if string.find(n, "hall of thanes", 1, true) then return "Hall of Thanes" end
  if string.find(n, "deadmines", 1, true) then return "The Deadmines" end
  if string.find(n, "wailing caverns", 1, true) then return "Wailing Caverns" end
  if string.find(n, "shadowfang keep", 1, true) or string.find(n, "shadowfang", 1, true) then return "Shadowfang Keep" end
  if string.find(n, "ruins of lordaeron", 1, true) then return "Ruins of Lordaeron" end
  if string.find(n, "blackfathom deeps", 1, true) or string.find(n, "blackfathom depths", 1, true) then return "Blackfathom Deeps" end
  return nil
end

local function scanEncounterJournal()
  if journalScanComplete then return end
  if type(EJ_GetInstanceByIndex) ~= "function"
    or type(EJ_SelectInstance) ~= "function"
    or type(EJ_GetEncounterInfoByIndex) ~= "function"
    or type(EJ_GetCreatureInfo) ~= "function" then
    -- Some Forever/Classic clients expose the journal APIs later in the load cycle.
    -- Keep this retryable instead of permanently locking the cache empty.
    return
  end
  journalScanComplete = true
  if type(wipe) == "function" then wipe(journalCache) else journalCache = {} end

  local tiers = { nil }
  if type(EJ_GetNumTiers) == "function" and type(EJ_SelectTier) == "function" then
    local ok, numTiers = pcall(EJ_GetNumTiers)
    if ok and type(numTiers) == "number" and numTiers > 0 then
      tiers = {}
      for tier = 1, numTiers do tiers[#tiers + 1] = tier end
    end
  end

  for _, tier in ipairs(tiers) do
    if tier and type(EJ_SelectTier) == "function" then pcall(EJ_SelectTier, tier) end
    for instanceIndex = 1, 200 do
      local okInstance, instanceID, instanceName = pcall(EJ_GetInstanceByIndex, instanceIndex, false)
      if not okInstance or not instanceID then break end
      local dungeonName = normalizeDungeonName(instanceName)
      if dungeonName then
        pcall(EJ_SelectInstance, instanceID)
        local cache = journalCache[dungeonName] or { instanceID = instanceID, encounters = {}, creaturesByID = {} }
        cache.creaturesByID = cache.creaturesByID or {}
        journalCache[dungeonName] = cache
        for encounterIndex = 1, 40 do
          local okEncounter, encounterName, encounterDescription, encounterID = pcall(EJ_GetEncounterInfoByIndex, encounterIndex, instanceID)
          if (not okEncounter) or not encounterName or not encounterID then
            okEncounter, encounterName, encounterDescription, encounterID = pcall(EJ_GetEncounterInfoByIndex, encounterIndex)
          end
          if (not okEncounter) or not encounterName or not encounterID then break end

          local encounterPrimary
          for creatureIndex = 1, 9 do
            local okCreature, creatureID, creatureName, creatureDescription, displayInfo, iconImage = pcall(EJ_GetCreatureInfo, creatureIndex, encounterID)
            if (not okCreature) or not creatureID then break end
            local data = {
              encounterID = encounterID,
              name = encounterName,
              description = encounterDescription,
              creatureID = creatureID,
              creatureName = creatureName,
              creatureDescription = creatureDescription,
              displayInfo = displayInfo,
              iconImage = iconImage,
            }
            encounterPrimary = encounterPrimary or data
            if type(creatureID) == "number" and creatureID > 0 then cache.creaturesByID[creatureID] = data end
            if type(creatureName) == "string" and creatureName ~= "" then cache.encounters[string.lower(creatureName)] = data end
          end
          if encounterPrimary and type(encounterName) == "string" and encounterName ~= "" then
            cache.encounters[string.lower(encounterName)] = encounterPrimary
          end
        end
      end
    end
  end
end

local function getBossJournalData(dungeonName, boss)
  local cache = journalCache[dungeonName]
  if not cache or not boss then return nil end
  if boss.npcID and cache.creaturesByID and cache.creaturesByID[boss.npcID] then
    return cache.creaturesByID[boss.npcID]
  end
  local aliases = boss.aliases or { boss.name }
  for _, alias in ipairs(aliases) do
    if type(alias) == "string" and alias ~= "" then
      local data = cache.encounters[string.lower(alias)]
      if data then return data end
    end
  end
  return nil
end

local function trySetDisplayPortrait(texture, displayID)
  if type(displayID) ~= "number" or displayID <= 0 then return false end
  if type(SetPortraitTextureFromCreatureDisplayID) ~= "function" then return false end
  texture:SetTexture(nil)
  local ok = pcall(SetPortraitTextureFromCreatureDisplayID, texture, displayID)
  if not ok then return false end
  local current = texture:GetTexture()
  return current ~= nil and current ~= 0 and current ~= ""
end

local portraitDisplayCache = {}

-- Boss info learned in game (display ID for the portrait, level), saved
-- account-wide so a portrait that resolved once stays available.
local function bossInfoDB()
  if type(ForeverCompanionDB) ~= "table" then return nil end
  ForeverCompanionDB.bossInfo = ForeverCompanionDB.bossInfo or {}
  return ForeverCompanionDB.bossInfo
end
local function savedDisplayID(npcID)
  local db = npcID and bossInfoDB()
  local e = db and db[npcID]
  return e and e.displayID
end
local function saveBossInfo(npcID, key, value)
  local db = npcID and bossInfoDB()
  if not db or value == nil then return end
  db[npcID] = db[npcID] or {}
  db[npcID][key] = value
end
local portraitDiagnostics = {}

local function portraitKey(dungeon, boss)
  return tostring(dungeon and dungeon.name or "Unknown dungeon") .. " / " .. tostring(boss and boss.name or "Unknown boss")
end

local function recordPortraitSource(dungeon, boss, source, detail)
  local key = portraitKey(dungeon, boss)
  portraitDiagnostics[key] = { source=source, detail=detail }
end

function FLT:PrintPortraitDebug()
  local keys = {}
  for key in pairs(portraitDiagnostics) do keys[#keys+1] = key end
  table.sort(keys)
  if #keys == 0 then
    self.Msg("Portrait diagnostics: no boss portraits have been rendered yet. Open a dungeon boss list first.")
    return
  end
  self.Msg("Portrait diagnostics (source used for the latest render):")
  for _, key in ipairs(keys) do
    local rec = portraitDiagnostics[key]
    self.Msg(key .. " -> " .. tostring(rec.source) .. (rec.detail and (" ("..tostring(rec.detail)..")") or ""))
  end
end
local portraitResolveQueue = {}
local portraitResolveQueued = {}
local portraitRetryAt = {}
local portraitWaiters = {}
local portraitResolveCurrent = nil
local portraitResolver = nil

local function updatePortraitWaiters(npcID, displayID)
  local waiters = portraitWaiters[npcID]
  portraitWaiters[npcID] = nil
  if not waiters then return end
  for _, texture in ipairs(waiters) do
    if texture and texture._oneForAllPortraitNpcID == npcID then
      if trySetDisplayPortrait(texture, displayID) then
        local meta = texture._oneForAllPortraitMeta
        if meta then recordPortraitSource(meta.dungeon, meta.boss, "resolved model display", displayID) end
      else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local meta = texture._oneForAllPortraitMeta
        if meta then recordPortraitSource(meta.dungeon, meta.boss, "neutral fallback", "resolved display failed") end
      end
    end
  end
end

local function finishPortraitResolve(request, displayID)
  if portraitResolveCurrent ~= request then return end
  if type(displayID) == "number" and displayID > 0 then
    portraitDisplayCache[request.npcID] = displayID
    saveBossInfo(request.npcID, "displayID", displayID)
    portraitRetryAt[request.npcID] = nil
  else
    portraitRetryAt[request.npcID] = (GetTime and GetTime() or 0) + 30
  end

  request.model:SetScript("OnModelLoaded", nil)
  if request.model.ClearModel then pcall(request.model.ClearModel, request.model) end
  request.model:Hide()
  portraitResolveQueued[request.npcID] = nil
  portraitResolveCurrent = nil

  if displayID then updatePortraitWaiters(request.npcID, displayID) end
end

local function startNextPortraitResolve()
  if portraitResolveCurrent or not portraitResolver then return end
  local npcID = table.remove(portraitResolveQueue, 1)
  if not npcID then return end

  -- A fresh model per lookup is intentional: a reused model still reports the
  -- previous creature's display ID, which breaks the change detection below.
  -- Lookups are cached per NPC, so this stays bounded by the number of bosses.
  local model = CreateFrame("PlayerModel", nil, UIParent)
  model:SetSize(1, 1)
  model:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  model:SetAlpha(0)
  model:Show()

  local request = { npcID=npcID, model=model, elapsed=0, loaded=false, failed=false }
  portraitResolveCurrent = request
  local okPrev, previousID = pcall(model.GetDisplayInfo, model)
  request.previousID = okPrev and previousID or nil
  model:SetScript("OnModelLoaded", function() if portraitResolveCurrent == request then request.loaded=true end end)
  local ok = pcall(model.SetCreature, model, npcID)
  if not ok then request.failed=true end
end

local function queuePortraitResolve(npcID, texture)
  if type(npcID) ~= "number" or npcID <= 0 then return end
  if texture then
    texture._oneForAllPortraitNpcID = npcID
    portraitWaiters[npcID] = portraitWaiters[npcID] or {}
    local already = false
    for _, t in ipairs(portraitWaiters[npcID]) do if t == texture then already = true; break end end
    if not already then table.insert(portraitWaiters[npcID], texture) end
  end
  if portraitDisplayCache[npcID] then
    if texture then trySetDisplayPortrait(texture, portraitDisplayCache[npcID]) end
    return
  end
  if portraitResolveQueued[npcID] then return end
  local now = GetTime and GetTime() or 0
  if portraitRetryAt[npcID] and now < portraitRetryAt[npcID] then return end
  portraitResolveQueued[npcID] = true
  table.insert(portraitResolveQueue, npcID)
  if portraitResolver then portraitResolver:Show() end
end

portraitResolver = CreateFrame("Frame")
portraitResolver:SetScript("OnUpdate", function(self, elapsed)
  if not portraitResolveCurrent then
    if #portraitResolveQueue == 0 then self:Hide(); return end
    startNextPortraitResolve()
    return
  end
  local request = portraitResolveCurrent
  request.elapsed = request.elapsed + elapsed
  if request.failed then finishPortraitResolve(request, nil); return end
  if request.loaded or request.elapsed >= 0.10 then
    local ok, displayID = pcall(request.model.GetDisplayInfo, request.model)
    if ok and type(displayID) == "number" and displayID > 0 and (request.loaded or displayID ~= request.previousID) then
      finishPortraitResolve(request, displayID)
      return
    end
  end
  if request.elapsed >= 1.5 then finishPortraitResolve(request, nil) end
end)
portraitResolver:Hide()

local function setBossPortrait(texture, dungeon, boss)
  if not texture then return false end
  scanEncounterJournal()
  texture:SetTexture(nil)
  texture:SetTexCoord(0.04, 0.96, 0.04, 0.96)
  texture._oneForAllPortraitNpcID = nil
  texture._oneForAllPortraitMeta = { dungeon=dungeon, boss=boss }

  if boss and boss.customPortrait then
    texture:SetTexture(boss.customPortrait)
    texture:SetTexCoord(0, 1, 0, 1)
    recordPortraitSource(dungeon, boss, "bundled portrait", boss.customPortrait)
    return true
  end

  if boss and boss.customIcon then
    texture:SetTexture(boss.customIcon)
    texture:SetTexCoord(0.04, 0.96, 0.04, 0.96)
    local current = texture.GetTexture and texture:GetTexture()
    if current and current ~= 0 and current ~= "" then
      recordPortraitSource(dungeon, boss, "bundled icon", boss.customIcon)
      return true
    end
  end

  if boss and trySetDisplayPortrait(texture, boss.displayID) then
    recordPortraitSource(dungeon, boss, "boss displayID", boss.displayID)
    return true
  end

  local data = getBossJournalData(dungeon and dungeon.name, boss)
  if data and trySetDisplayPortrait(texture, data.displayInfo) then
    recordPortraitSource(dungeon, boss, "encounter journal display", data.displayInfo)
    return true
  end

  local npcID = boss and boss.npcID
  if (not npcID) and data and type(data.creatureID)=="number" and data.creatureID>0 then npcID=data.creatureID end

  if npcID and trySetDisplayPortrait(texture, STATIC_DISPLAY_IDS[npcID]) then
    recordPortraitSource(dungeon, boss, "static display", STATIC_DISPLAY_IDS[npcID])
    return true
  end
  if npcID and trySetDisplayPortrait(texture, savedDisplayID(npcID)) then
    recordPortraitSource(dungeon, boss, "saved display (seen in game)", savedDisplayID(npcID))
    return true
  end
  if npcID and trySetDisplayPortrait(texture, portraitDisplayCache[npcID]) then
    recordPortraitSource(dungeon, boss, "cached model display", portraitDisplayCache[npcID])
    return true
  end

  -- Forever-only bosses often have valid NPC IDs but no bundled display ID.
  -- Resolve their CreatureDisplayID asynchronously through a hidden PlayerModel,
  -- then update the already-visible portrait texture in place.
  if npcID then queuePortraitResolve(npcID, texture) end

  if data and data.iconImage and data.iconImage ~= 0 then
    texture:SetTexture(data.iconImage)
    texture:SetTexCoord(0.04, 0.96, 0.04, 0.96)
    recordPortraitSource(dungeon, boss, "encounter journal icon", data.iconImage)
    return true
  end

  texture:SetTexture(BOSS_PORTRAIT_FALLBACK)
  texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  recordPortraitSource(dungeon, boss, "neutral fallback", BOSS_PORTRAIT_FALLBACK)
  return false
end


UI.setBossPortrait = setBossPortrait


-- Boss level: static table (QuestieDB) or learned in game.
function FLT:GetBossLevel(boss)
  if not boss then return nil end
  local lv = boss.npcID and FLT.BOSS_LEVELS and FLT.BOSS_LEVELS[boss.npcID]
  if lv then return lv end
  local db = boss.npcID and bossInfoDB()
  local e = db and db[boss.npcID]
  if e and e.level then return (e.level < 0) and "??" or tostring(e.level) end
  return nil
end

-- Learn level and display ID of dungeon bosses when you target or mouse over
-- them (or their nameplate appears). Updates portraits that are on screen.
do
  local bossNpc
  local function buildBossSet()
    bossNpc = {}
    for _, d in ipairs(FLT.DUNGEONS or {}) do
      for _, b in ipairs(d.bosses or {}) do if b.npcID then bossNpc[b.npcID] = true end end
    end
  end
  local probe
  local function learn(unit)
    if not (UnitExists and UnitExists(unit) and UnitGUID) then return end
    local kind, _, _, _, _, id = strsplit("-", UnitGUID(unit) or "")
    id = tonumber(id)
    if kind ~= "Creature" or not id then return end
    if not bossNpc then buildBossSet() end
    if not bossNpc[id] then return end
    if UnitLevel then saveBossInfo(id, "level", UnitLevel(unit)) end
    if savedDisplayID(id) or STATIC_DISPLAY_IDS[id] then return end
    probe = probe or CreateFrame("PlayerModel", nil, UIParent)
    probe:SetSize(1, 1); probe:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 10, -10)
    probe:Show()
    local ok = pcall(probe.SetUnit, probe, unit)
    if not ok then return end
    local tries = 0
    local function check()
      tries = tries + 1
      local okd, display = pcall(probe.GetDisplayInfo, probe)
      if okd and type(display) == "number" and display > 0 then
        saveBossInfo(id, "displayID", display)
        portraitDisplayCache[id] = display
        updatePortraitWaiters(id, display)
        probe:Hide()
      elseif tries < 10 and C_Timer and C_Timer.After then
        C_Timer.After(0.2, check)
      else
        probe:Hide()
      end
    end
    check()
  end
  local ev = CreateFrame("Frame")
  for _, e in ipairs({"PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED"}) do pcall(ev.RegisterEvent, ev, e) end
  ev:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then learn("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then learn("mouseover")
    else learn(unit) end
  end)
end


-- Framed portraits ---------------------------------------------------------------
-- Boss: gold frame that runs into a point at the bottom right (like the player
-- frame) with an optional level badge. Pets: plain round gold ring; pet
-- abilities: silver ring with gems. Geometry matches the 256px design files.
local ASSET = "Interface\\AddOns\\OneForAll\\Assets\\"
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local function roundMask(owner, tex)
  if tex.AddMaskTexture and owner.CreateMaskTexture then
    local m = owner:CreateMaskTexture()
    m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(tex)
    tex:AddMaskTexture(m)
  end
end

-- Returns a holder frame with .portrait (texture to fill), .badge/.level.
function UI.CreateBossFrame(parent, size, withBadge)
  local f = CreateFrame("Frame", nil, parent); f:SetSize(size, size)
  local k = size / 256
  local r = 85 * k
  local portrait = f:CreateTexture(nil, "ARTWORK")
  portrait:SetSize(2 * r, 2 * r); portrait:SetPoint("TOPLEFT", (136 * k) - r, -((120 * k) - r))
  roundMask(f, portrait)
  local frame = f:CreateTexture(nil, "OVERLAY", nil, 1)
  frame:SetAllPoints(); frame:SetTexture(ASSET .. "frame_boss")
  f.portrait = portrait
  if withBadge then
    local bs = 86 * k
    local badge = f:CreateTexture(nil, "OVERLAY", nil, 3)
    badge:SetSize(bs, bs); badge:SetPoint("CENTER", f, "TOPLEFT", 56 * k, -204 * k)
    badge:SetTexture(ASSET .. "frame_badge")
    local lv = f:CreateFontString(nil, "OVERLAY", size >= 64 and "GameFontHighlight" or "GameFontHighlightSmall")
    lv:SetPoint("CENTER", badge, "CENTER", 0, 0); lv:SetTextColor(0.96, 0.94, 0.90)
    f.badge, f.level = badge, lv
    f.SetLevel = function(self, text)
      if text and text ~= "" then badge:Show(); lv:SetText(text); lv:Show() else badge:Hide(); lv:Hide() end
    end
  end
  return f
end

-- kind: "gold" (pet families) or "silver" (pet abilities).
function UI.CreateRingFrame(parent, size, kind)
  local f = CreateFrame("Frame", nil, parent); f:SetSize(size, size)
  local d = size * 202 / 256
  local portrait = f:CreateTexture(nil, "ARTWORK")
  portrait:SetSize(d, d); portrait:SetPoint("CENTER")
  roundMask(f, portrait)
  local ring = f:CreateTexture(nil, "OVERLAY", nil, 1)
  ring:SetAllPoints(); ring:SetTexture(ASSET .. (kind == "silver" and "ring_silver" or "ring_gold"))
  f.portrait = portrait
  return f
end

-- Square icon with rounded corners and a dark border, like action bar spells
-- (uses the same mask/border artwork as the talent planner buttons).
function UI.CreateActionFrame(parent, size)
  local f = CreateFrame("Frame", nil, parent); f:SetSize(size, size)
  local inset = math.floor(size * 0.07 + 0.5)
  local shadow = f:CreateTexture(nil, "BACKGROUND")
  shadow:SetTexture(ASSET .. "talent_button_border")
  shadow:SetPoint("TOPLEFT", 1, -2); shadow:SetPoint("BOTTOMRIGHT", 2, -2)
  shadow:SetVertexColor(0, 0, 0, 0.7)
  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", inset, -inset); icon:SetPoint("BOTTOMRIGHT", -inset, inset)
  if icon.AddMaskTexture and f.CreateMaskTexture then
    local m = f:CreateMaskTexture()
    m:SetTexture(ASSET .. "talent_icon_mask"); m:SetAllPoints(icon)
    icon:AddMaskTexture(m)
  end
  local border = f:CreateTexture(nil, "OVERLAY", nil, 1)
  border:SetTexture(ASSET .. "talent_button_border"); border:SetAllPoints()
  border:SetVertexColor(0.16, 0.15, 0.14, 1)
  f.portrait = icon
  return f
end
