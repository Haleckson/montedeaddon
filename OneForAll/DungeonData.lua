local _, FLT = ...

local SRC = FLT.DUNGEON_JOURNAL_DB or {}

-- Level ranges: WoW Forever recommended ranges (Warcraft Tavern Forever dungeon
-- list; the new dungeons match the Wowhead Forever overview). They are stored
-- in the Data\Dungeons files; minLevel below only drives sorting/grouping.
-- coordsUnverified marks entrances that still need an in-game /ofa where check.
-- dataStatus: "forever" = Forever quests/loot recorded, "partial" = bosses only.
local META = {
  ["Hall of Thanes"] = {key="hall", short="Hall of Thanes", territory="Alliance", mapZone="Ironforge", mapX=43.5, mapY=52.0, betaNew=true, minLevel=13},
  ["Ragefire Chasm"] = {key="rfc", instanceID=389, territory="Horde", mapZone="Orgrimmar", mapX=52.8, mapY=49.6, minLevel=13},
  -- The only published entrance coordinates (71.6, 11.4) are labelled "Tirisfal
  -- Glades", but on the Tirisfal map they point at the northern coast. They match
  -- the east side of the ruined keep on the Undercity map, which is where the
  -- entrance is described ("just outside the Undercity, east side of the keep's
  -- courtyard"). Verify in game with /ofa where.
  ["Ruins of Lordaeron"] = {key="lordaeron", territory="Horde", mapZone="Undercity", mapX=71.6, mapY=11.4, betaNew=true, minLevel=15, coordsUnverified=true},
  ["The Deadmines"] = {key="deadmines", instanceID=36, territory="Alliance", mapZone="Westfall", mapX=42.5, mapY=71.6, minLevel=15},
  ["Wailing Caverns"] = {key="wc", instanceID=43, territory="Horde", mapZone="The Barrens", mapX=46.0, mapY=36.3, minLevel=17},
  ["Shadowfang Keep"] = {key="sfk", instanceID=33, territory="Horde", mapZone="Silverpine Forest", mapX=44.5, mapY=68.0, minLevel=20},
  ["Blackfathom Deeps"] = {key="bfd", instanceID=48, territory="Contested", mapZone="Ashenvale", mapX=14.0, mapY=14.0, minLevel=22},
  ["Excavation Site: Wetlands"] = {key="excavation", short="Excavation Site", territory="Contested", mapZone="Wetlands", mapX=38.5, mapY=47.0, betaNew=true, minLevel=24, coordsUnverified=true},
  ["The Stockade"] = {key="stockade", instanceID=34, territory="Alliance", mapZone="Stormwind City", mapX=41.2, mapY=58.0, minLevel=25, coordsUnverified=true},
  ["City of Dalaran"] = {key="dalaran", territory="Contested", mapZone="Alterac Mountains", betaNew=true, minLevel=28, dataStatus="partial"},
  ["Gnomeregan"] = {key="gnomeregan", instanceID=90, territory="Alliance", mapZone="Dun Morogh", mapX=24.4, mapY=39.8, minLevel=29, coordsUnverified=true, openToBoth=true},
  ["Scarlet Monastery: Graveyard"] = {key="smgy", instanceID=189, short="SM: Graveyard", territory="Horde", mapZone="Tirisfal Glades", mapX=82.6, mapY=33.8, minLevel=30, coordsUnverified=true},
}

-- Sorted by minimum level (then name). The browse list groups these into
-- collapsible level brackets.
local ORDER = {}
for name in pairs(META) do ORDER[#ORDER+1] = name end
table.sort(ORDER, function(a, b)
  local la, lb = META[a].minLevel or 0, META[b].minLevel or 0
  if la ~= lb then return la < lb end
  return a < b
end)

local function itemRec(tuple)
  if type(tuple) ~= "table" then return {name=tostring(tuple or "Unknown item")} end
  -- Dungeon loot tuples are {itemID, name, slot, quality}.
  -- Quest reward tuples from the journal are often {itemID, name, quality}.
  -- Treat a numeric third field as quality rather than a display slot/count.
  if type(tuple[3]) == "number" and tuple[4] == nil then
    return {id=tuple[1], name=tuple[2], quality=tuple[3]}
  end
  return {id=tuple[1], name=tuple[2], slot=tuple[3], quality=tuple[4]}
end

local function convertQuest(q)
  local rewards={}
  for _,it in ipairs(q.rewardItems or {}) do rewards[#rewards+1]=itemRec(it) end
  local noteRewards={}
  for _,it in ipairs(q.noteRewardItems or {}) do noteRewards[#noteRewards+1]=itemRec(it) end
  local class=q.class or q.classOnly
  if type(class)=="string" then class=class:upper() end
  return {
    id=q.id,
    name=q.name,
    level=q.level,
    required=q.requires or q.level,
    side=q.faction or "Both",
    class=class,
    starts=q.pickup,
    objective=q.objective,
    turnin=q.turnin,
    prereq=q.prerequisite or q.prereq,
    note=q.note,
    rewards=rewards,
    noteRewards=noteRewards,
    rewardChoice=q.rewardChoice,
    rewardSummary=q.rewardSummary or q.rewards,
    startItem=q.startItem and itemRec(q.startItem) or nil,
    noteItem=q.noteItem and itemRec(q.noteItem) or nil,
    liveXPFallback=q.liveXPFallback,
  }
end

local function convertBoss(b)
  local loot={}
  for _,it in ipairs(b.loot or {}) do loot[#loot+1]=itemRec(it) end
  return {
    name=b.name,
    npcID=b.npcID,
    rare=b.rare,
    description=b.description,
    icon=b.icon,
    customIcon=b.customIcon,
    customPortrait=b.customPortrait,
    displayID=b.displayID,
    worldDropsOnly=b.worldDropsOnly,
    aliases=b.aliases,
    loot=loot,
  }
end

FLT.DUNGEONS={}
FLT.DUNGEON_ITEM_DB=FLT.DUNGEON_ITEM_DB or {}
for _,name in ipairs(ORDER) do
  local s=SRC[name]
  local m=META[name] or {}
  if s then
    local d={
      key=m.key or name,
      name=name,
      short=m.short,
      level=s.level or "?",
      area=s.location or m.mapZone or "Unknown",
      territory=m.territory or "Contested",
      side=m.territory or "Contested", -- compatibility with existing UI helpers
      betaNew=m.betaNew,
      minLevel=m.minLevel,
      maxLevel=tonumber(tostring(s.level or ""):match("%-(%d+)")),
      coordsUnverified=m.coordsUnverified,
      openToBoth=m.openToBoth,
      instanceID=m.instanceID,
      dataStatus=m.dataStatus or "forever",
      mapZone=m.mapZone,
      mapX=m.mapX,
      mapY=m.mapY,
      description=s.description,
      icon=s.icon,
      bosses={},
      quests={},
      bossLoot={},
      trashLoot={},
    }
    for _,b in ipairs(s.bosses or {}) do
      local cb=convertBoss(b)
      d.bosses[#d.bosses+1]=cb
      d.bossLoot[cb.name]=cb.loot
      for _,it in ipairs(cb.loot) do
        if it.name and not FLT.DUNGEON_ITEM_DB[it.name] then FLT.DUNGEON_ITEM_DB[it.name]={id=it.id,quality=it.quality,summary=it.slot} end
      end
    end
    for _,it in ipairs(s.trashLoot or {}) do
      local rec=itemRec(it)
      d.trashLoot[#d.trashLoot+1]=rec
      if rec.name and not FLT.DUNGEON_ITEM_DB[rec.name] then FLT.DUNGEON_ITEM_DB[rec.name]={id=rec.id,quality=rec.quality,summary=rec.slot} end
    end
    for _,q in ipairs(s.quests or {}) do
      local cq=convertQuest(q)
      d.quests[#d.quests+1]=cq
      for _,it in ipairs(cq.rewards or {}) do
        if it.name and not FLT.DUNGEON_ITEM_DB[it.name] then FLT.DUNGEON_ITEM_DB[it.name]={id=it.id,quality=it.quality,summary=it.slot} end
      end
      for _,it in ipairs(cq.noteRewards or {}) do
        if it.name and not FLT.DUNGEON_ITEM_DB[it.name] then FLT.DUNGEON_ITEM_DB[it.name]={id=it.id,quality=it.quality,summary=it.slot} end
      end
    end
    FLT.DUNGEONS[#FLT.DUNGEONS+1]=d
  end
end

-- Boss levels (QuestieDB Forever data). Forever-only bosses are missing here;
-- their level is learned in game when you target them (ForeverCompanionDB.bossInfo).
FLT.BOSS_LEVELS = {
  -- Blackfathom Deeps
  [4829] = "28", -- Aku'mai
  [12876] = "28", -- Baron Aquanis
  [6243] = "26", -- Gelihast
  [4887] = "25", -- Ghamoo-ra
  [4831] = "25", -- Lady Sarevess
  [12902] = "26", -- Lorgus Jett
  [4830] = "26", -- Old Serra'kis
  [4832] = "27", -- Twilight Lord Kelris
  -- Gnomeregan
  [6229] = "32", -- Crowd Pummeler 9-60
  [6228] = "33", -- Dark Iron Ambassador
  [6235] = "32", -- Electrocutioner 6000
  [7361] = "32", -- Grubbis
  [7800] = "34", -- Mekgineer Thermaplugg
  [7079] = "30", -- Viscous Fallout
  -- Ragefire Chasm
  [11519] = "16", -- Bazzalan
  [11518] = "16", -- Jergosh the Invoker
  [11517] = "16", -- Oggleflint
  [11520] = "16", -- Taragaman the Hungerer
  -- Scarlet Monastery: Graveyard
  [6490] = "33", -- Azshir the Sleepless
  [4543] = "34", -- Bloodmage Thalnos
  [6488] = "33", -- Fallen Champion
  [3983] = "32", -- Interrogator Vishas
  [6489] = "33", -- Ironspine
  [14693] = "34", -- Scorn
  -- Shadowfang Keep
  [4275] = "26", -- Archmage Arugal
  [4627] = "24-25", -- Arugal's Voidwalker
  [3887] = "24", -- Baron Silverlaine
  [4278] = "24", -- Commander Springvale
  [3872] = "25", -- Deathsworn Captain
  [3864] = "19-20", -- Fel Steed / Shadow Charger
  [4274] = "25", -- Fenrus the Devourer
  [4279] = "24", -- Odo the Blindwatcher
  [3886] = "22", -- Razorclaw the Butcher
  [3914] = "20", -- Rethilgore
  [14682] = "25", -- Sever
  [3927] = "25", -- Wolf Master Nandos
  -- The Deadmines
  [647] = "20", -- Captain Greenskin
  [645] = "20", -- Cookie
  [639] = "21", -- Edwin VanCleef
  [1763] = "20", -- Gilnid
  [3586] = "19", -- Miner Johnson
  [646] = "20", -- Mr. Smite
  [644] = "19", -- Rhahk'Zor
  [643] = "20", -- Sneed
  [642] = "20", -- Sneed's Shredder
  -- The Stockade
  [1716] = "29", -- Bazil Thredd
  [1720] = "26", -- Bruegal Ironknuckle
  [1663] = "26", -- Dextren Ward
  [1717] = "28", -- Hamhock
  [1666] = "27", -- Kam Deepfury
  [1696] = "24", -- Targorr the Dread
  -- Wailing Caverns
  [5912] = "20", -- Deviate Faerie Dragon
  [3653] = "20", -- Kresh
  [3671] = "20", -- Lady Anacondra
  [3669] = "20", -- Lord Cobrahn
  [3670] = "21", -- Lord Pythas
  [3673] = "21", -- Lord Serpentis
  [3654] = "22", -- Mutanus the Devourer
  [3674] = "21", -- Skum
  [5775] = "21", -- Verdan the Everliving
}
