local addonName, MCF = ...
-- Last worn gear per character level, including transmog, for later export
-- (e.g. an external 3D model viewer). Stored compactly in db.gearByLevel[level]:
--   {t=time, level=n, helm=bool, cloak=bool, src="live"|"levelup",
--    slots={[slotID]={l=itemLink, s=shownSourceID, v=shownVisualID, t=true if transmogged, h=true if hidden, i=illusionID}}}
-- s/v are what the character actually shows: the transmog if one is applied, otherwise the item's own look.
-- The slot list itself comes from LevelHistory (MCF.EQUIPMENT_SLOTS).

local DEBOUNCE = 2     -- seconds after the last equipment change
local LOGIN_DELAY = 4  -- seconds after login (item data needs a moment)

-- Slots that can carry a transmog appearance (illusions: weapon slots only).
local TRANSMOG_SLOTS = {[1]=true,[3]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[15]=true,[16]=true,[17]=true,[18]=true}
MCF.TransmogSlots = TRANSMOG_SLOTS -- shared with Achievements (one list)
local ILLUSION_SLOTS = {[16]=true,[17]=true}

local function safe(v)
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

local function positive(v)
  v = safe(v)
  return type(v) == "number" and v > 0 and v or nil
end

local function makeLocation(slotID, kind)
  local enumType = Enum and Enum.TransmogType and Enum.TransmogType[kind]
  local enumMod = Enum and Enum.TransmogModification and Enum.TransmogModification.Main
  if not (TransmogUtil and enumType ~= nil and enumMod ~= nil) then return nil end
  for _, fname in ipairs({"CreateTransmogLocation", "GetTransmogLocation"}) do
    local f = TransmogUtil[fname]
    if type(f) == "function" then
      local ok, loc = pcall(f, slotID, enumType, enumMod)
      if ok and loc then return loc end
    end
  end
  return nil
end

-- Returns sourceID, visualID, transmogged, hidden for what the slot SHOWS: the applied
-- transmog if there is one, otherwise the equipped item's own appearance.
local function readSlotVisual(slotID, kind)
  if not (C_Transmog and type(C_Transmog.GetSlotVisualInfo) == "function") then return nil end
  local loc = makeLocation(slotID, kind)
  if not loc then return nil end
  local ok, a, b, c, d = pcall(C_Transmog.GetSlotVisualInfo, loc)
  if not ok then return nil end
  local baseSource, baseVisual, appliedSource, appliedVisual, hidden
  if type(a) == "table" then
    baseSource, baseVisual = positive(a.baseSourceID), positive(a.baseVisualID)
    appliedSource, appliedVisual = positive(a.appliedSourceID), positive(a.appliedVisualID)
    hidden = safe(a.isHideVisual) == true
  else
    -- Older signature: baseSourceID, baseVisualID, appliedSourceID, appliedVisualID, ...
    baseSource, baseVisual, appliedSource, appliedVisual = positive(a), positive(b), positive(c), positive(d)
  end
  if kind == "Illusion" then return appliedSource, appliedVisual, appliedSource ~= nil, false end
  local transmogged = appliedSource ~= nil or appliedVisual ~= nil
  if transmogged then return appliedSource, appliedVisual, true, hidden end
  return baseSource, baseVisual, false, hidden
end

local function ensure()
  local db = MyCharForeverDB
  if type(db) ~= "table" then return nil end
  db.gearByLevel = type(db.gearByLevel) == "table" and db.gearByLevel or {}
  return db.gearByLevel
end

local function signature(record)
  local parts = {tostring(record.helm), tostring(record.cloak)}
  for _, slot in ipairs(MCF.EQUIPMENT_SLOTS or {}) do
    local e = record.slots[slot[1]]
    if e then parts[#parts + 1] = slot[1] .. ":" .. tostring(e.l) .. ":" .. tostring(e.s) .. ":" .. tostring(e.v) .. ":" .. tostring(e.t) .. ":" .. tostring(e.h) .. ":" .. tostring(e.i) end
  end
  return table.concat(parts, "|")
end

function MCF:CaptureGearRecord()
  local level = safe(UnitLevel("player"))
  if type(level) ~= "number" then return nil end
  local record = {t = time(), level = level, src = "live", slots = {}}
  if ShowingHelm then record.helm = ShowingHelm() and true or false end
  if ShowingCloak then record.cloak = ShowingCloak() and true or false end
  for _, slot in ipairs(MCF.EQUIPMENT_SLOTS or {}) do
    local slotID = slot[1]
    local link = safe(GetInventoryItemLink("player", slotID))
    local entry = {l = type(link) == "string" and link or nil}
    if TRANSMOG_SLOTS[slotID] then
      local source, visual, transmogged, hidden = readSlotVisual(slotID, "Appearance")
      entry.s, entry.v = source, visual
      entry.t = transmogged or nil
      entry.h = hidden or nil
      if ILLUSION_SLOTS[slotID] then entry.i = (readSlotVisual(slotID, "Illusion")) end
    end
    if entry.l or entry.s or entry.v or entry.i then record.slots[slotID] = entry end
  end
  return record
end

function MCF:UpdateGearRecord()
  local store = ensure()
  if not store then return end
  local record = self:CaptureGearRecord()
  if not record then return end
  local old = store[record.level]
  if old and old.src == "live" and signature(old) == signature(record) then
    old.t = record.t -- unchanged: only refresh the "still worn at" time
    return
  end
  store[record.level] = record
  local c = MyCharForeverDB.character
  if type(c) == "table" and UnitSex then c.sex = c.sex or UnitSex("player") end
end

-- Levels played before the live tracking existed: the level-up snapshot of
-- level N+1 shows the gear worn at the end of level N (links only, no transmog).
local function backfill()
  local store = ensure()
  if not store or MyCharForeverDB.gearBackfilled then return end
  for level, snapshot in pairs(type(MyCharForeverDB.levelSnapshots) == "table" and MyCharForeverDB.levelSnapshots or {}) do
    local previous = type(level) == "number" and level - 1
    if previous and previous >= 1 and not store[previous] and type(snapshot) == "table" and type(snapshot.equipment) == "table" then
      local record = {t = snapshot.time, level = previous, src = "levelup", slots = {}}
      for _, item in pairs(snapshot.equipment) do
        if type(item) == "table" and item.slotID and (item.link or item.itemID) then
          record.slots[item.slotID] = {l = item.link or ("item:" .. tostring(item.itemID))}
        end
      end
      if next(record.slots) then store[previous] = record end
    end
  end
  MyCharForeverDB.gearBackfilled = true
end

function MCF:PrintGearReport()
  local de = self:GetLanguage() == "deDE"
  local record = self:CaptureGearRecord()
  if not record then print("MyCharForever: gear unavailable"); return end
  local slots, withLook, withTransmog = 0, 0, 0
  for _, e in pairs(record.slots) do
    slots = slots + 1
    if e.s or e.v then withLook = withLook + 1 end
    if e.t then withTransmog = withTransmog + 1 end
  end
  local stored = 0
  for _ in pairs(MyCharForeverDB.gearByLevel or {}) do stored = stored + 1 end
  print(string.format("|cff00ccffMyCharForever|r: " .. (de and "Gear Level %d: %d Slots, %d mit Erscheinungs-ID, davon %d per Transmog. Helm: %s, Umhang: %s. Gespeicherte Level: %d"
    or "Gear level %d: %d slots, %d with appearance ID, %d of them transmogged. Helm: %s, cloak: %s. Stored levels: %d"),
    record.level, slots, withLook, withTransmog, tostring(record.helm), tostring(record.cloak), stored))
end


-- /mcf gear probe: shows what the client offers for transmog, so a missing ID can be told
-- apart from "no transmog applied" and "API not usable".
local function names(t)
  local list = {}
  if type(t) == "table" then for k, v in pairs(t) do if type(v) == "function" then list[#list + 1] = tostring(k) end end end
  table.sort(list)
  return list
end

local function chunkedPrint(label, list)
  local text, line = {}, label .. " (" .. #list .. "): "
  for i, n in ipairs(list) do
    if #line + #n > 190 then text[#text + 1] = line; line = "  " end
    line = line .. n .. (i < #list and ", " or "")
  end
  text[#text + 1] = line
  for _, l in ipairs(text) do print(l) end
end

function MCF:PrintGearProbe()
  local p = function(s) print("|cff00ccffMyCharForever|r probe: " .. s) end
  p("TransmogUtil=" .. type(TransmogUtil) .. " Enum.TransmogType=" .. type(Enum and Enum.TransmogType)
    .. " C_Transmog=" .. type(C_Transmog) .. " C_TransmogCollection=" .. type(C_TransmogCollection)
    .. " C_TransmogOutfitInfo=" .. type(C_TransmogOutfitInfo))
  chunkedPrint("C_Transmog", names(C_Transmog))
  chunkedPrint("TransmogUtil", names(TransmogUtil))
  chunkedPrint("C_TransmogCollection", names(C_TransmogCollection))
  for _, slotID in ipairs({1, 5, 16}) do
    local link = GetInventoryItemLink("player", slotID)
    if link then
      local loc = makeLocation(slotID, "Appearance")
      p(string.format("slot %d: item=%s location=%s", slotID, tostring(link:match("%[(.-)%]")), type(loc)))
      if loc and C_Transmog and C_Transmog.GetSlotVisualInfo then
        local ok, a, b, c, d = pcall(C_Transmog.GetSlotVisualInfo, loc)
        if type(a) == "table" then
          local parts = {}
          for k, v in pairs(a) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
          table.sort(parts)
          p("  result(table): " .. table.concat(parts, " "))
        else
          p("  result: ok=" .. tostring(ok) .. " " .. tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d))
        end
      end
    end
  end
end

local pending = false
local function schedule(delay)
  if pending then return end
  pending = true
  C_Timer.After(delay, function()
    pending = false
    pcall(MCF.UpdateGearRecord, MCF)
  end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_LOGOUT")
pcall(function() frame:RegisterEvent("PLAYER_LEVEL_UP") end)
pcall(function() frame:RegisterEvent("TRANSMOG_COLLECTION_UPDATED") end)
pcall(function() frame:RegisterEvent("TRANSMOGRIFY_SUCCESS") end)
frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(LOGIN_DELAY, function() pcall(backfill); pcall(MCF.UpdateGearRecord, MCF) end)
  elseif event == "PLAYER_LOGOUT" then
    pcall(MCF.UpdateGearRecord, MCF)
  else
    schedule(DEBOUNCE)
  end
end)
