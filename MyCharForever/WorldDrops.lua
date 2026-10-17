local addonName, MCF = ...
-- Notable drops outside instances (dungeons have their own loot log).
-- Stored flat in db.worldDrops; each entry carries its level, so exports can group it.
-- Every tunable value lives in MCF.WorldDrops below.

MCF.WorldDrops = {
  defaultMinQuality = 3,         -- Rare and better
  duplicateWindow = 2,           -- seconds: the same link is not recorded twice
  sourceWindow = 10,             -- seconds a loot window's source stays valid for the chat message
  iconPath = "Interface\\AddOns\\MyCharForever\\Textures\\WorldDrop%d.png",
  iconQualities = {2, 3, 4, 5},  -- qualities that have an icon file (Textures/WorldDrop<q>.png)
  -- Item link colour -> quality (the colour code of a link is the quality colour).
  qualityByColor = {
    ["9d9d9d"] = 0, ["ffffff"] = 1, ["1eff00"] = 2, ["0070dd"] = 3,
    ["a335ee"] = 4, ["ff8000"] = 5, ["e6cc80"] = 6, ["00ccff"] = 7,
  },
}
local W = MCF.WorldDrops

function W.IconFor(quality)
  local best = W.iconQualities[1]
  for _, q in ipairs(W.iconQualities) do
    if (tonumber(quality) or 0) >= q then best = q end
  end
  return string.format(W.iconPath, best)
end

local function safe(v)
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

local function setting(key, default)
  local s = MyCharForeverDB and MyCharForeverDB.settings
  local v = s and s[key]
  if v == nil then return default end
  return v
end

function W.MinQuality() return tonumber(setting("worldDropMinQuality", W.defaultMinQuality)) or W.defaultMinQuality end

local function qualityOf(link)
  -- Forever uses |cnIQ<quality>: ; classic clients use |cAARRGGBB.
  local nq = tonumber(link:match("^|cnIQ(%d+):"))
  if nq then return nq end
  local color = link:match("^|c%x%x(%x%x%x%x%x%x)|Hitem")
  local q = color and W.qualityByColor[color:lower()]
  if q then return q end
  local itemID = tonumber(link:match("item:(%d+)"))
  if itemID and C_Item and C_Item.GetItemQualityByID then
    local ok, quality = pcall(C_Item.GetItemQualityByID, itemID)
    if ok and type(quality) == "number" then return quality end
  end
  return nil
end

W.QualityOf = qualityOf -- shared: Dungeons.lua and UI.lua read the quality from the link colour as well

---------------------------------------------------------------------------
-- Loot source (from the loot window, best effort)
---------------------------------------------------------------------------
local recentSources = {} -- [itemLink] = {guid=..., time=...}

local function parseGuid(guid)
  if type(guid) ~= "string" then return nil end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
  if kind == "Creature" or kind == "Vehicle" then return "creature", tonumber(id) end
  if kind == "GameObject" then return "object", tonumber(id) end
  return nil
end

local function onLootOpened()
  if not (GetNumLootItems and GetLootSlotLink and GetLootSourceInfo) then return end
  local now = time()
  for slot = 1, (GetNumLootItems() or 0) do
    local link = safe(GetLootSlotLink(slot))
    if type(link) == "string" then
      local ok, guid = pcall(GetLootSourceInfo, slot)
      guid = ok and safe(guid) or nil
      if type(guid) == "string" then recentSources[link] = {guid = guid, time = now} end
    end
  end
end

local function sourceNameFor(guid, npcID)
  local targetGuid = UnitGUID and safe(UnitGUID("target"))
  if guid and targetGuid == guid then
    local name = safe(UnitName("target"))
    if type(name) == "string" and name ~= "" then return name end
  end
  local mobs = MyCharForeverDB and MyCharForeverDB.combat and MyCharForeverDB.combat.kills and MyCharForeverDB.combat.kills.mobs
  local row = npcID and type(mobs) == "table" and mobs["npc:" .. npcID]
  return type(row) == "table" and row.name or nil
end

---------------------------------------------------------------------------
-- Recording
---------------------------------------------------------------------------
local function position()
  local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if not mapID then return nil end
  local pos = C_Map.GetPlayerMapPosition(mapID, "player")
  if not pos then return mapID end
  local x, y = pos:GetXY()
  if not x or not y or (x == 0 and y == 0) then return mapID end
  return mapID, x, y
end

MCF.PlayerPosition = position -- shared: mapID, x, y of the player (PvP.lua, ItemJournal.lua)

function MCF:AddWorldDrop(link, source)
  local db = MyCharForeverDB
  if type(db) ~= "table" or type(link) ~= "string" then return nil end
  db.worldDrops = type(db.worldDrops) == "table" and db.worldDrops or {}
  local quality = qualityOf(link)
  if not quality then return nil end
  local mapID, x, y = position()
  source = source or {}
  local zone, subZone = GetZoneText(), GetSubZoneText()
  local entry = {
    time = time(), level = UnitLevel("player"), itemID = tonumber(link:match("item:(%d+)")),
    link = link, quality = quality, mapID = mapID, x = x, y = y, zone = zone, subZone = subZone,
    sourceType = source.type, npcID = source.id, sourceName = source.name, test = source.test,
  }
  table.insert(db.worldDrops, entry)
  local itemName = link:match("%[(.-)%]") or "?"
  if self.AddEvent then
    self:AddEvent("WORLD_DROP", {itemID = entry.itemID, itemLink = link, quality = quality, sourceName = entry.sourceName})
  end
  if setting("worldDropJournal", true) then
    db.journal = type(db.journal) == "table" and db.journal or {}
    local where = (zone and zone ~= "") and zone or "?"
    local text = entry.sourceName and string.format(self:T("Found at %s in %s"), entry.sourceName, where)
      or string.format(self:T("Found in %s"), where)
    local comment, invType
    if self.LootComment then comment, invType = self:LootComment(link, quality) end
    if comment then text = comment .. "\n" .. text end
    table.insert(db.journal, {
      time = entry.time, level = entry.level, mapID = mapID, x = x, y = y, zone = zone, subZone = subZone,
      title = string.format(self:T("Notable drop: %s"), itemName),
      text = text .. "\n" .. link,
      auto = true, source = "WORLD_DROP", itemID = entry.itemID, itemLink = link, quality = quality,
      dropIndex = #db.worldDrops, test = source.test, invType = invType,
    })
  end
  if self.RefreshMapJourney then self:RefreshMapJourney() end
  if self.RefreshUI then self:RefreshUI() end
  return entry
end

-- Test helper: /mcf droptest adds a fake epic drop here, /mcf droptest clear removes all fakes.
function MCF:AddTestWorldDrop()
  return self:AddWorldDrop("|cffa335ee|Hitem:19019::::::::60:::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
    {type = "creature", name = self:T("Test drop source"), test = true})
end

function MCF:ClearTestWorldDrops()
  local db = MyCharForeverDB
  if type(db) ~= "table" then return 0 end
  local removed = 0
  for _, key in ipairs({"worldDrops", "journal"}) do
    local list = db[key]
    if type(list) == "table" then
      local kept = {}
      for _, e in ipairs(list) do
        if type(e) == "table" and e.test then removed = removed + 1 else kept[#kept + 1] = e end
      end
      for i = 1, #list do list[i] = kept[i] end
    end
  end
  if self.RefreshMapJourney then self:RefreshMapJourney() end
  if self.RefreshUI then self:RefreshUI() end
  return removed
end

local patterns
local function selfLootLink(message)
  if type(message) ~= "string" or not MCF.LootFormatPattern then return nil end
  if not patterns then
    patterns = {}
    -- Only real loot ("You receive loot: ..."), not quest rewards, mail or purchases.
    for _, key in ipairs({"LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE"}) do
      local pat = MCF.LootFormatPattern(_G[key])
      if pat then patterns[#patterns + 1] = pat end
    end
  end
  for _, pat in ipairs(patterns) do
    if message:match(pat) then return message:match("(|c[^|]*|Hitem:.-|h.-|h|r)") or message:match("(|Hitem:.-|h.-|h)") end
  end
  return nil
end

local lastRecorded = {}
local function onChatLoot(message)
  if not setting("recordWorldDrops", true) then return end
  if IsInInstance and IsInInstance() then return end
  local link = selfLootLink(safe(message))
  if not link then return end
  local quality = qualityOf(link)
  if not quality or quality < W.MinQuality() then return end
  local now = time()
  if lastRecorded[link] and now - lastRecorded[link] <= W.duplicateWindow then return end
  lastRecorded[link] = now
  local source = {}
  local known = recentSources[link]
  if known and now - known.time <= W.sourceWindow then
    local kind, id = parseGuid(known.guid)
    source.type, source.id = kind, id
    source.name = kind == "creature" and sourceNameFor(known.guid, id) or nil
  end
  MCF:AddWorldDrop(link, source)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:SetScript("OnEvent", function(_, event, message)
  if event == "LOOT_OPENED" then pcall(onLootOpened)
  else pcall(onChatLoot, message) end
end)
