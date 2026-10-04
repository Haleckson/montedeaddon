local ADDON, FLT = ...

FLT.mapNameToID = {}

-- Recorded quest-start locations for dungeon quests (verified against the
-- Wowhead Classic/Forever quest maps, 2026-09-29). Coordinates are percentages
-- on the Classic/Forever world-map canvas. Entries are intentionally limited to
-- starts that are known with enough confidence to place a marker.
FLT.QUEST_START_MAPS = {
  [92401] = { mapID=1421, x=44.40, y=42.80, label="Tabitha Heartweaver — The Sepulcher" },
  [92421] = { mapID=1458, x=57.80, y=89.80, label="Morbin Lightbane — Royal Quarter" },
  [95216] = { mapID=1458, x=46.60, y=72.00, label="Theodore Griffs — Apothecarium" },
  [92422] = { mapID=1420, x=65.20, y=60.20, label="Deathguard Kristof — southeast of Brill" },

  [214]  = { mapID=1436, x=56.60, y=47.40, label="Scout Riell" },
  [168]  = { mapID=1453, x=65.20, y=21.20, label="Wilder Thistlenettle — Dwarven District" },
  [167]  = { mapID=1453, x=65.20, y=21.20, label="Wilder Thistlenettle — Dwarven District" },
  [2040] = { mapID=1453, x=55.40, y=12.60, label="Shoni the Shilent — Dwarven District" },
  [166]  = { mapID=1436, x=56.20, y=47.60, label="Gryan Stoutmantle" },
  [65]   = { mapID=1436, x=56.20, y=47.60, label="Gryan Stoutmantle — Sentinel Hill" },
  [135]  = { mapID=1436, x=56.20, y=47.60, label="Gryan Stoutmantle — Sentinel Hill" },
  [142]  = { mapID=1436, x=56.20, y=47.60, label="Gryan Stoutmantle — Sentinel Hill" },
  [155]  = { mapID=1436, x=55.60, y=47.40, label="Defias Traitor — Sentinel Hill" },

  [5723] = { mapID=1456, x=70.40, y=29.60, label="Rahauro" },
  [5722] = { mapID=1456, x=70.40, y=29.60, label="Rahauro" },
  [5728] = { mapID=1454, x=32.00, y=37.80, label="Thrall" },
  [5726] = { mapID=1454, x=32.00, y=37.80, label="Thrall" },
  [5727] = { mapID=1454, x=32.00, y=37.80, label="Thrall" },
  [5761] = { mapID=1454, x=49.60, y=50.40, label="Neeru Fireblade" },
  [5725] = { mapID=1458, x=56.20, y=92.60, label="Varimathras" },

  [971]  = { mapID=1455, x=50.40, y=6.00, label="Gerrig Bonegrip" },
  [1275] = { mapID=1439, x=38.40, y=43.00, label="Gershala Nightwhisper" },
  [1198] = { mapID=1457, x=55.40, y=24.60, label="Dawnwatcher Shaedlass" },
  [1199] = { mapID=1457, x=55.20, y=23.60, label="Argent Guard Manados" },
  [6563] = { mapID=1440, x=11.60, y=34.20, label="Je'neu Sancrea" },
  [6562] = { mapID=1442, x=47.20, y=64.20, label="Tsunaman — Sun Rock Retreat" },
  [6565] = { mapID=1440, x=11.60, y=34.20, label="Je'neu Sancrea" },
  [6921] = { mapID=1440, x=11.60, y=34.20, label="Je'neu Sancrea" },

  [1486] = { mapID=1413, x=46.60, y=36.30, label="Nalpak" },
  [1487] = { mapID=1413, x=46.60, y=35.70, label="Ebru" },
  [962]  = { mapID=1456, x=23.00, y=21.00, label="Apothecary Zamah — Pools of Vision, Thunder Bluff" },
  [865]  = { mapID=1413, x=62.40, y=37.60, label="Mebok Mizzyrix — Ratchet" },
  [1491] = { mapID=1413, x=62.40, y=37.60, label="Mebok Mizzyrix" },
  [959]  = { mapID=1413, x=63.00, y=37.60, label="Crane Operator Bigglefuzz" },
  [914]  = { mapID=1456, x=75.60, y=31.20, label="Nara Wildmane" },
  [6981] = { mapID=1413, x=62.98, y=37.20, label="Sputtervalve, Ratchet — first stop (quest starts from the Glowing Shard, Wailing Caverns)" },

  [1098] = { mapID=1421, x=43.40, y=40.80, label="High Executor Hadrec" },
  [1740] = { mapID=1413, x=49.20, y=57.20, label="Doan Karhan" },
  [1013] = { mapID=1458, x=53.60, y=54.00, label="Keeper Bel'dugur" },
  [1014] = { mapID=1421, x=44.20, y=39.80, label="Dalar Dawnweaver" },

  -- Hall of Thanes
  [96403] = { mapID=1455, x=32.40, y=44.80, label="Thom Filch — bridge in front of the Hall of Thanes entrance" },
  [96394] = { mapID=1455, x=33.00, y=48.00, label="Afadra Dunwall — above the Hall of Thanes entrance" },
  [96393] = { mapID=1426, x=64.80, y=58.40, label="Earthseer Farsen — camp above Gol'Bolar Quarry" },

  -- The Deadmines (Forever)
  [92753] = { mapID=1436, x=52.40, y=53.00, label="Alba Fairmoon — Sentinel Hill" },

  -- The Stockade (Wowhead Forever quest pages)
  [386]  = { mapID=1433, x=26.40, y=46.60, label="Guard Berton — Lakeshire" },
  [377]  = { mapID=1431, x=72.00, y=47.80, label="Councilman Millstipe — Darkshire" },
  [378]  = { mapID=1437, x=49.60, y=18.20, label="Motley Garmason — Dun Modr" },
  [303]  = { mapID=1437, x=49.60, y=18.20, label="Motley Garmason — Dun Modr" },
  [387]  = { mapID=1453, x=41.20, y=58.00, label="Warden Thelwater — Stockade entrance" },
  [391]  = { mapID=1453, x=41.20, y=58.00, label="Warden Thelwater — Stockade entrance" },
  [388]  = { mapID=1453, x=73.40, y=46.60, label="Nikova Raskol — Old Town" },
  [389]  = { mapID=1453, x=49.00, y=30.20, label="Baros Alexston — Cathedral Square" },

  -- Gnomeregan
  [2922] = { mapID=1455, x=69.80, y=50.20, label="Tinkmaster Overspark — Tinker Town" },
  [2923] = { mapID=1453, x=40.60, y=30.80, label="Brother Sarno — Cathedral Square" },
  [2924] = { mapID=1455, x=68.20, y=46.20, label="Klockmort Spannerspan — Tinker Town" },
  [2925] = { mapID=1457, x=59.20, y=45.40, label="Mathiel — Warrior's Terrace" },
  [2926] = { mapID=1426, x=45.80, y=49.20, label="Ozzie Togglevolt — Kharanos" },
  [2962] = { mapID=1426, x=45.80, y=49.20, label="Ozzie Togglevolt — Kharanos" },
  [2927] = { mapID=1455, x=69.40, y=50.60, label="Gnoarn — Tinker Town" },
  [2928] = { mapID=1453, x=55.40, y=12.60, label="Shoni the Shilent — Dwarven District" },
  [2929] = { mapID=1455, x=69.00, y=49.00, label="High Tinker Mekkatorque — Tinker Town" },
  [2930] = { mapID=1455, x=69.80, y=48.40, label="Master Mechanic Castpipe — Tinker Town" },
  [2931] = { mapID=1442, x=59.40, y=67.20, label="Gaxim Rustfizzle — Stonetalon Mountains" },
  [2841] = { mapID=1454, x=75.80, y=25.20, label="Nogg — Valley of Honor" },
  [2842] = { mapID=1454, x=75.60, y=25.20, label="Sovik — Valley of Honor" },
  [2843] = { mapID=1434, x=27.60, y=77.40, label="Scooty — Booty Bay" },

  -- Excavation Site: Wetlands
  [95647] = { mapID=1437, x=11.80, y=58.60, label="Caitlin Grassman — Menethil Harbor" },
  [95772] = { mapID=1433, x=30.80, y=46.60, label="Dorin Songblade — Lakeshire" },
  [98815] = { mapID=1437, x=8.60, y=55.60, label="James Halloran — Menethil Harbor" },
  [98824] = { mapID=1437, x=38.80, y=52.20, label="Prospector Whelgar — Whelgar's Excavation Site" },

  -- Scarlet Monastery: Graveyard
  [1113] = { mapID=1458, x=48.40, y=69.40, label="Master Apothecary Faranell — Apothecarium" },
  [1109] = { mapID=1458, x=48.40, y=69.40, label="Master Apothecary Faranell — Apothecarium" },
  -- City of Dalaran / Forever additions (October 2026)
  [92456] = { mapID=1453, x=31.50, y=62.60, label="Shylamiir" },
  [92489] = { mapID=1453, x=48.70, y=87.60, label="High Sorcerer Andromath" },
  [96986] = { mapID=1424, x=62.60, y=20.70, label="Melisara" },
  [96988] = { mapID=1458, x=46.60, y=74.10, label="Doctor Martin Felben" },
  [3369] = { mapID=1413, x=48.20, y=32.80, label="Falla Sagewind" },
  [3370] = { mapID=1413, x=48.20, y=32.80, label="Falla Sagewind" },
  [1654] = { mapID=1426, x=52.50, y=36.90, label="Jordan Stilwell" },
}

local function indexMap(id, depth)
  if not C_Map or not C_Map.GetMapInfo or depth > 5 then return end
  local info = C_Map.GetMapInfo(id)
  if info and info.name then FLT.mapNameToID[info.name:lower()] = id end
  if C_Map.GetMapChildrenInfo then
    local kids = C_Map.GetMapChildrenInfo(id, nil, true) or {}
    for _, k in ipairs(kids) do indexMap(k.mapID, depth + 1) end
  end
end

function FLT:BuildMapIndex()
  wipe(self.mapNameToID)
  for _, id in ipairs({947, 1414, 1415, 13, 12}) do pcall(indexMap, id, 0) end
end

function FLT:FindMapID(zone)
  if self.MAP_IDS and self.MAP_IDS[zone] then return self.MAP_IDS[zone] end
  if not next(self.mapNameToID) then self:BuildMapIndex() end
  local wanted = (zone or ""):lower()
  if self.mapNameToID[wanted] then return self.mapNameToID[wanted] end
  for name, id in pairs(self.mapNameToID) do
    if name == wanted or name:find(wanted, 1, true) or wanted:find(name, 1, true) then return id end
  end
end

local marker
local function ensureMarker()
  if marker or not WorldMapFrame then return marker end
  local parent = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child or WorldMapFrame
  marker = CreateFrame("Frame", "OneForAllMapPin", parent)
  marker:SetSize(46, 46)
  marker:SetFrameStrata("TOOLTIP")
  marker:SetFrameLevel(1000)

  local icon = marker:CreateTexture(nil, "OVERLAY")
  icon:SetAllPoints()
  icon:SetTexCoord(0, 1, 0, 1)
  icon:SetBlendMode("BLEND")
  icon:SetTexture((FLT.ASSET_ROOT or ("Interface\\AddOns\\" .. ADDON .. "\\Assets\\")) .. "map_pin")
  marker.icon = icon

  -- The pin lives on the map canvas, so it must only be visible while the map
  -- that it was placed on is displayed. Without this check the pin stayed at
  -- the same canvas position after browsing to another zone.
  local throttle = 0
  marker:SetScript("OnUpdate", function(self, elapsed)
    throttle = throttle + elapsed
    if throttle < 0.1 then return end
    throttle = 0
    local current = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    self:SetAlpha((current == self.mapID) and 1 or 0)
  end)
  marker:Hide()
  return marker
end

local function forceMap(mapID)
  -- C_Map.OpenWorldMap is the most reliable route on modern Classic clients.
  if C_Map and C_Map.OpenWorldMap then
    local ok = pcall(C_Map.OpenWorldMap, mapID)
    if ok then return true end
  end

  if OpenWorldMap then
    local ok = pcall(OpenWorldMap, mapID)
    if ok then return true end
  end

  if WorldMapFrame then
    if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
    if WorldMapFrame.SetMapID then
      pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID)
      return true
    end
  end
  return false
end

local function positionMarker(book, mapID)
  if not WorldMapFrame then return end

  -- Some clients only accept SetMapID after the frame has become visible.
  if WorldMapFrame.SetMapID then
    local current = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if current ~= mapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID) end
  end

  local current = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
  if current and current ~= mapID then
    FLT.Msg("Could not switch the world map to " .. tostring(book.zone or book.label or "the recorded location") .. ". Try clicking Map again outside combat.")
    return
  end

  local m = ensureMarker()
  if not m then return end
  local parent = m:GetParent()
  local w, h = parent:GetWidth(), parent:GetHeight()
  if w and h and w > 0 and h > 0 then
    m:ClearAllPoints()
    m:SetPoint("BOTTOM", parent, "TOPLEFT", (book.x / 100) * w, -(book.y / 100) * h + 3)
    m.mapID = mapID
    m:SetAlpha(1)
    m:Show()
  end
end

function FLT:ShowOnMap(book)
  if not book.x or not book.y then
    self.Msg("No reliable map position is known for this book yet.")
    return
  end

  local mapID = book.mapID or self:FindMapID(book.zone)
  if not mapID then
    self.Msg("Could not determine the map ID for '" .. tostring(book.zone or book.label or "this location") .. "'.")
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    self.Msg("The world map cannot be switched by the addon during combat.")
    return
  end

  local m = ensureMarker()
  if m then m:Hide() end

  if not forceMap(mapID) then
    self.Msg("The world map could not be opened.")
    return
  end

  -- Run twice: the first pass handles clients that initialize the map asynchronously.
  C_Timer.After(0.05, function() positionMarker(book, mapID) end)
  C_Timer.After(0.25, function() positionMarker(book, mapID) end)
end

function FLT:ShowQuestStartOnMap(quest)
  if not quest or not quest.id then
    self.Msg("No recorded quest-start location is available.")
    return
  end
  local loc = self.QUEST_START_MAPS and self.QUEST_START_MAPS[quest.id]
  if not loc then
    self.Msg("No reliable map position is recorded for this quest start yet.")
    return
  end
  self:ShowOnMap(loc)
end

