local _, namespace = ...
local FC = namespace.FC

local function localized(de, en)
    return GetLocale and GetLocale() == "deDE" and de or en
end

local function mapLocation(mapID, continent, zone, subZone, x, y)
    return { mapID = mapID, continent = continent, zone = zone, subZone = subZone, x = x, y = y }
end

local function demoQuestID(index) return 990000 + index end
local function demoItemID(index) return 980000 + index end
local function demoNpcID(index) return 970000 + index end

local function sampleProfile(name, realm, class, level, location, events, now)
    local profile = {
        identity = {
            name = name, realm = realm, className = class, classFile = class:upper(),
            raceName = localized("Orc", "Orc"), raceFile = "ORC", faction = "Horde",
            level = level, guid = "DEMO-" .. name, firstSeen = now - 86400 * 4, lastSeen = now,
        },
        events = events or {}, discoveries = {}, observed = {
            quests = {}, npcs = {}, enemies = {}, items = {}, zones = {}, dungeons = {}, entrances = {}, rares = {},
        },
        inventory = { bags = {}, bank = {}, bagsUpdatedAt = now, bankUpdatedAt = now },
        merchants = {}, trainers = {}, professions = {}, companions = {}, notes = {},
        sessions = {}, stats = {
            questsAccepted = 6, questsCompleted = 4, zonesDiscovered = 3,
            dungeonsEntered = 1, raresSeen = 1, deaths = 0, itemsObserved = 4,
            merchantsVisited = 1, trainersVisited = 1, companionsMet = 1,
        },
        lastState = { location = location, level = level }, nextEventID = #(events or {}) + 1,
        mapSettings = {},
    }
    return profile
end

local function observed(profile, kind, id, name, locations, now, extra)
    local record = {
        id = id, name = name, firstSeen = now - 86400, lastSeen = now,
        count = #locations, locations = locations, unknown = true,
        firstSource = "demo", lastSource = "demo",
    }
    if kind == "npcs" then record.npcRole = "npc" end
    for key, value in pairs(extra or {}) do record[key] = value end
    profile.observed[kind][tostring(id)] = record
    table.insert(profile.discoveries, {
        ts = now - 86400, kind = kind, id = id, name = name,
        location = locations[1], source = "demo", databaseVersion = 0,
    })
    return record
end

local function makeDemoDatabase(realSettings)
    local now = FC:Now()
    local de = GetLocale and GetLocale() == "deDE"
    local continent = de and "Kalimdor" or "Kalimdor"
    local durotar = de and "Durotar" or "Durotar"
    local barrens = de and "Das Brachland" or "The Barrens"
    local valley = de and "Tal der Prüfungen" or "Valley of Trials"
    local crossroads = de and "Der Kreuzweg" or "The Crossroads"
    local locations = {
        start = mapLocation(1411, continent, durotar, valley, 44.8, 67.2),
        ore1 = mapLocation(1411, continent, durotar, valley, 47.1, 61.4),
        ore2 = mapLocation(1413, continent, barrens, crossroads, 51.2, 29.8),
        herb1 = mapLocation(1413, continent, barrens, crossroads, 53.8, 26.3),
        herb2 = mapLocation(1413, continent, barrens, crossroads, 49.6, 31.5),
        rare = mapLocation(1413, continent, barrens, crossroads, 55.4, 24.7),
        quest = mapLocation(1413, continent, barrens, crossroads, 52.1, 29.1),
        dungeon = mapLocation(1413, continent, barrens, crossroads, 47.9, 35.2),
    }

    local startAt = now - 86400 * 4
    local journey = {
        { id=1, ts=startAt, type="LOGIN", title=FC.L.SESSION_STARTED, location=locations.start },
        { id=2, ts=startAt+240, type="ZONE", title=FC.L.ZONE_DISCOVERED .. ": " .. durotar, location=locations.start },
        { id=3, ts=startAt+1900, type="LEVEL", title=FC.L.LEVEL_REACHED .. ": 3", data={level=3}, location=locations.start },
        { id=4, ts=startAt+4400, type="QUEST_ACCEPTED", title=FC.L.QUEST_ACCEPTED .. ": " .. localized("Eine sichere Lieferung", "A Safe Delivery"), location=locations.start },
        { id=5, ts=startAt+6100, type="GATHER", title=FC.L.GATHERED .. ": " .. localized("Kupferader", "Copper Vein"), data={kind="ore",nodeID=1}, location=locations.ore1 },
        { id=6, ts=startAt+7900, type="ZONE", title=FC.L.ZONE_DISCOVERED .. ": " .. barrens, location=locations.quest },
        { id=7, ts=startAt+9200, type="QUEST_COMPLETED", title=localized("Der Weg zum Kreuzweg", "The Road to Crossroads"), data={questID=demoQuestID(1)}, location=locations.quest },
        { id=8, ts=startAt+11000, type="RARE", title=FC.L.RARE_SEEN .. ": " .. localized("Khan Dez'hepah", "Khan Dez'hepah"), location=locations.rare },
        { id=9, ts=startAt+12400, type="NPC_DISCOVERY", title=localized("Gazlowe", "Gazlowe"), location=locations.quest },
        { id=10, ts=startAt+13700, type="GATHER", title=FC.L.GATHERED .. ": " .. localized("Silberblatt", "Silverleaf"), data={kind="herb",nodeID=3}, location=locations.herb1 },
        { id=11, ts=startAt+15300, type="DUNGEON", title=FC.L.DUNGEON_ENTERED .. ": " .. localized("Höhlen des Wehklagens", "Wailing Caverns"), location=locations.dungeon },
        { id=12, ts=startAt+18100, type="LEVEL", title=FC.L.LEVEL_REACHED .. ": 5", data={level=5}, location=locations.dungeon },
        { id=13, ts=startAt+21100, type="QUEST_COMPLETED", title=localized("Ein neuer Verbündeter", "A New Ally"), data={questID=demoQuestID(2)}, location=locations.quest },
        { id=14, ts=startAt+21800, type="ITEM", title=localized("Leinenstoff", "Linen Cloth"), detail="loot", data={itemID=demoItemID(1), quality=1}, location=locations.quest },
        { id=15, ts=startAt+22600, type="COMPANION", title=FC.L.DIARY_GROUP_EVENT, detail=localized("Mira und Thrall", "Mira and Thrall"), location=locations.quest },
        { id=16, ts=startAt+22900, type="MERCHANT", title=FC.L.DIARY_MERCHANT_VISIT .. ": " .. localized("Harnor", "Harnor"), location=locations.quest },
        { id=17, ts=startAt+23200, type="TRAINER", title=FC.L.DIARY_TRAINER_VISIT .. ": " .. localized("Throg", "Throg"), location=locations.quest },
        { id=18, ts=startAt+28000, type="LOGIN", title=FC.L.SESSION_STARTED, location=locations.quest },
        { id=19, ts=startAt+29500, type="QUEST_ACCEPTED", title=FC.L.QUEST_ACCEPTED .. ": " .. localized("Eine alte Schuld", "An Old Debt"), location=locations.quest },
        { id=20, ts=startAt+32200, type="GATHER", title=FC.L.GATHERED .. ": " .. localized("Kupferader", "Copper Vein"), data={kind="ore",nodeID=2}, location=locations.ore2 },
        { id=21, ts=startAt+34500, type="QUEST_COMPLETED", title=localized("Eine alte Schuld", "An Old Debt"), location=locations.quest },
    }

    local mainName = localized("Chronist", "Chronicler")
    local alternateName = localized("Sammlerin", "Gatherer")
    local realm = GetRealmName and GetRealmName()
    if FC:IsSecret(realm) or type(realm) ~= "string" or realm == "" then realm = "Forever" end
    local mainKey, alternateKey = mainName .. "-" .. realm, alternateName .. "-" .. realm
    local profile = sampleProfile(mainName, realm, "Hunter", 5, locations.quest, journey, now)
    local demoSessionID = "demo-session-" .. tostring(startAt)
    profile.sessions[1] = {
        id = demoSessionID, startedAt = startAt, endedAt = startAt + 24000,
        startLevel = 2, endLevel = 5, startLocation = locations.start,
        endLocation = locations.quest, eventStartID = 1, eventEndID = 17,
    }
    local laterSessionID = demoSessionID .. "-return"
    profile.sessions[2] = {
        id = laterSessionID, startedAt = startAt + 28000, endedAt = startAt + 36000,
        startLevel = 5, endLevel = 5, startLocation = locations.quest,
        endLocation = locations.quest, eventStartID = 18, eventEndID = #journey,
    }
    for index, event in ipairs(journey) do
        event.sessionID = index <= 17 and demoSessionID or laterSessionID
    end
    local alternate = sampleProfile(alternateName, realm, "Druid", 14, locations.herb2, {}, now)
    alternate.observed.items[tostring(demoItemID(1))] = {
        id=demoItemID(1), name=localized("Leinenstoff", "Linen Cloth"), firstSeen=now-80000,
        lastSeen=now-3600, count=7, locations={locations.start,locations.quest}, unknown=true, firstSource="demo",
    }
    alternate.inventory.bags[tostring(demoItemID(1))] = 7
    alternate.companions[mainKey] = {
        name=localized("Chronist", "Chronicler"), realm="Forever", classFile="HUNTER", level=5,
        firstSeen=now-86400, lastSeen=now-3600, groups=3, locations={locations.quest}, dungeons={},
    }

    observed(profile,"npcs",demoNpcID(1),localized("Gazlowe", "Gazlowe"),{locations.quest},now,{vendor=localized("Leinenstoff", "Linen Cloth")})
    observed(profile,"rares",demoNpcID(2),localized("Khan Dez'hepah", "Khan Dez'hepah"),{locations.rare},now)
    observed(profile,"items",demoItemID(1),localized("Leinenstoff", "Linen Cloth"),{locations.start,locations.quest},now,{quality=1})
    observed(profile,"zones",1411,durotar,{locations.start},now)
    observed(profile,"zones",1413,barrens,{locations.quest},now)
    observed(profile,"dungeons",719,localized("Höhlen des Wehklagens", "Wailing Caverns"),{locations.dungeon},now)
    observed(profile,"entrances",719,localized("Höhlen des Wehklagens", "Wailing Caverns"),{locations.quest},now)

    profile.merchants["demo-merchant"] = {
        id=demoNpcID(1), name=localized("Gazlowe", "Gazlowe"), firstSeen=now-50000, lastSeen=now-4000,
        visits=2, location=locations.quest, locations={locations.quest}, items={
            [tostring(demoItemID(1))]={name=localized("Leinenstoff", "Linen Cloth"),count=7,firstSeen=now-40000,lastSeen=now-4000},
        },
    }
    profile.trainers["demo-trainer"] = {
        id=demoNpcID(3), name=localized("Thotar", "Thotar"), firstSeen=now-45000, lastSeen=now-4200,
        visits=1, location=locations.start, locations={locations.start}, services={
            ["demo-skill"]={name=localized("Wildtiere aufspüren", "Track Beasts"),rank="",category="HUNTER",firstSeen=now-45000,lastSeen=now-4200},
        },
    }
    profile.professions["mining"]={name=localized("Bergbau","Mining"),skill=31,maxSkill=75,lastSeen=now-5000}
    profile.notes[1]={id=1,ts=now-1800,updatedAt=now-1800,text=localized("Kupferader am Kreuzweg", "Copper vein by the Crossroads"),location=locations.ore2,remind=true,mapVisible=true}

    local quests = {
        [tostring(demoQuestID(1))]={id=demoQuestID(1),count=1,firstCompleted=journey[7].ts,lastCompleted=journey[7].ts,
            names={deDE="Der Weg zum Kreuzweg",enUS="The Road to Crossroads"},
            currentName=localized("Der Weg zum Kreuzweg","The Road to Crossroads"),englishName="The Road to Crossroads",locale=de and "deDE" or "enUS",
            locations={locations.quest},acceptedLocations={locations.start},completedBy={[mainKey]={count=1,name=profile.identity.name,firstSeen=journey[7].ts,lastSeen=journey[7].ts}}},
        [tostring(demoQuestID(2))]={id=demoQuestID(2),count=1,firstCompleted=journey[12].ts,lastCompleted=journey[12].ts,
            names={deDE="Ein neuer Verbündeter",enUS="A New Ally"},currentName=localized("Ein neuer Verbündeter","A New Ally"),englishName="A New Ally",locale=de and "deDE" or "enUS",
            locations={locations.quest},acceptedLocations={locations.quest},completedBy={[mainKey]={count=1,name=profile.identity.name,firstSeen=journey[12].ts,lastSeen=journey[12].ts}}},
    }
    local atlasNodes = {
        ["1"]={id=1,kind="ore",name=localized("Kupferader","Copper Vein"),icon="Interface\\Icons\\Trade_Mining",mapID=locations.ore1.mapID,continent=continent,zone=durotar,subZone=valley,x=locations.ore1.x,y=locations.ore1.y,firstSeen=now-80000,lastSeen=now-60000,count=2,source="demo",characters={[mainKey]=2},lootItems={}},
        ["2"]={id=2,kind="ore",name=localized("Kupferader","Copper Vein"),icon="Interface\\Icons\\Trade_Mining",mapID=locations.ore2.mapID,continent=continent,zone=barrens,subZone=crossroads,x=locations.ore2.x,y=locations.ore2.y,firstSeen=now-40000,lastSeen=now-1800,count=1,source="demo",characters={[mainKey]=1},lootItems={}},
        ["3"]={id=3,kind="herb",name=localized("Silberblatt","Silverleaf"),icon="Interface\\Icons\\Trade_Herbalism",mapID=locations.herb1.mapID,continent=continent,zone=barrens,subZone=crossroads,x=locations.herb1.x,y=locations.herb1.y,firstSeen=now-30000,lastSeen=now-20000,count=3,source="demo",characters={[alternateKey]=3},lootItems={}},
        ["4"]={id=4,kind="herb",name=localized("Friedensblume","Peacebloom"),icon="Interface\\Icons\\Trade_Herbalism",mapID=locations.herb2.mapID,continent=continent,zone=barrens,subZone=crossroads,x=locations.herb2.x,y=locations.herb2.y,firstSeen=now-18000,lastSeen=now-9000,count=2,source="demo",characters={[alternateKey]=2},lootItems={}},
        ["5"]={id=5,kind="fishing",name=localized("Angelstelle am Fluss","Riverside fishing spot"),icon="Interface\\Icons\\Trade_Fishing",mapID=locations.quest.mapID,continent=continent,zone=barrens,subZone=crossroads,x=51.1,y=32.2,firstSeen=now-7000,lastSeen=now-6500,count=1,source="demo",characters={[mainKey]=1},lootItems={}},
        ["6"]={id=6,kind="treasure",name=localized("Vorratskiste","Supply Chest"),icon="Interface\\Icons\\INV_Misc_Chest_01",mapID=locations.quest.mapID,continent=continent,zone=barrens,subZone=crossroads,x=54.2,y=31.7,firstSeen=now-5000,lastSeen=now-4800,count=1,source="demo",characters={[mainKey]=1},lootItems={}},
    }

    local settings = {}
    for key,value in pairs(realSettings or {}) do settings[key]=value end
    settings.mapPinsEnabled=true
    for _,key in ipairs({"mapShowAtlas","mapShowOre","mapShowHerbs","mapShowFishing","mapShowTreasures","mapShowQuests","mapShowNotes","mapShowRares","mapShowNPCs","mapShowItems","mapShowDungeons","mapShowEntrances","mapShowZones"}) do settings[key]=true end
    settings.mapClusterPins=false
    local mapSettings={mapPinsEnabled=true,mapShowAtlas=true,mapShowOre=true,mapShowHerbs=true,mapShowFishing=true,mapShowTreasures=true,mapShowQuests=true,mapShowNotes=true,mapShowRares=true,mapShowNPCs=true,mapShowItems=true,mapShowDungeons=true,mapShowEntrances=true,mapShowZones=true,mapClusterPins=false}
    profile.mapSettings=mapSettings
    alternate.mapSettings=mapSettings

    local db={schema=FC.SCHEMA_VERSION,databaseVersion=0,settings=settings,meta={revision=1,createdAt=now-86400*4,lastMutationAt=now},health={errors={},errorCount=0},
        characters={[mainKey]=profile,[alternateKey]=alternate},atlas={nextNodeID=7,nodes=atlasNodes,byContinent={},byMap={}},questArchive={quests=quests,byContinent={}},}
    for id,node in pairs(atlasNodes) do
        db.atlas.byContinent[continent]=db.atlas.byContinent[continent] or {}
        db.atlas.byContinent[continent][node.zone]=db.atlas.byContinent[continent][node.zone] or {}
        db.atlas.byContinent[continent][node.zone][id]=true
        db.atlas.byMap[tostring(node.mapID)]=db.atlas.byMap[tostring(node.mapID)] or {}
        db.atlas.byMap[tostring(node.mapID)][id]=true
    end
    local activeSession = { startedAt=now-3600, startLevel=4, endLevel=5, startLocation=locations.start, eventStartID=7 }
    return db, profile, mainKey, activeSession
end

function FC:EnterDemoMode()
    if self.demoMode then
        self:Print(self.L.DEMO_ON)
        self:OpenUI("chronicle")
        return
    end
    local demoDB, profile, characterKey, activeSession = makeDemoDatabase(self.db and self.db.settings)
    self._demoReturn = { db=self.db, profile=self.profile, characterKey=self.characterKey, activeSession=self.activeSession }
    self.db, self.profile, self.characterKey, self.activeSession = demoDB, profile, characterKey, activeSession
    self.demoMode = true
    self.mapSpotlight = nil
    if self.RefreshMapPins then self:RefreshMapPins() end
    self:Print(self.L.DEMO_ON)
    self:OpenUI("chronicle")
end

function FC:ExitDemoMode()
    if not self.demoMode or not self._demoReturn then return false end
    local previous = self._demoReturn
    self.db, self.profile, self.characterKey, self.activeSession = previous.db, previous.profile, previous.characterKey, previous.activeSession
    self._demoReturn = nil
    self.demoMode = false
    self.mapSpotlight = nil
    if self.RefreshMapPins then self:RefreshMapPins() end
    if self.RefreshUI then self:RefreshUI() end
    self:Print(self.L.DEMO_OFF)
    return true
end
