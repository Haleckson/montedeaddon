local addonName, MCF = ...
local function T(key) return MCF:T(key) end

_G.MyCharForever = MCF

local function AddonVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, "Version")
    end
    if GetAddOnMetadata then
        return GetAddOnMetadata(addonName, "Version")
    end
    return nil
end
MCF.VERSION = AddonVersion() or "unknown"

local frame = CreateFrame("Frame")
MCF.eventFrame = frame

local function GetCharacterInfo()
    local name, realm = UnitFullName("player")
    local raceName, raceFile, raceID = UnitRace("player")
    local className, classFile, classID = UnitClass("player")

    return {
        name = name,
        realm = realm or GetRealmName(),
        race = raceName,
        raceFile = raceFile,
        raceID = raceID,
        class = className,
        classFile = classFile,
        classID = classID,
    }
end

-- Saved data lives in a file named after realm + character name. If a character is deleted and a new one gets the same
-- name, WoW loads the old file. The stored GUID tells them apart: the old data is moved to the account archive (newest
-- MAX_ARCHIVED_CHARACTERS are kept) and the new character starts clean. Data without a stored GUID (made before 1.0.1)
-- is adopted once, never reset.
MCF.MAX_ARCHIVED_CHARACTERS = 3
function MCF:ArchiveIfNameReused()
    local guid = UnitGUID and UnitGUID("player") or nil
    local old = type(MyCharForeverDB) == "table" and MyCharForeverDB.character
    if not guid or type(old) ~= "table" or not old.guid or old.guid == guid then return false end
    local adb = self:EnsureAccountDB()
    adb.archivedCharacters = type(adb.archivedCharacters) == "table" and adb.archivedCharacters or {}
    local list = adb.archivedCharacters
    list[#list + 1] = {key = self:GetCharacterKey(), guid = old.guid, archivedAt = time(), data = MyCharForeverDB}
    while #list > self.MAX_ARCHIVED_CHARACTERS do table.remove(list, 1) end
    MyCharForeverDB = {}
    MyCharForeverExportDB = nil
    return true
end

function MCF:InitializeDB()
    if type(MyCharForeverDB) ~= "table" then
        MyCharForeverDB = {}
    end
    self:ArchiveIfNameReused()

    local db = MyCharForeverDB
    local fresh = next(db) == nil -- brand-new saved data starts at the current version

    self:RepairDB(db)
    if fresh then db.dbVersion = self.DB_VERSION end
    db.character = db.character or {}
    db.settings = db.settings or {}
    db.settings.goldMilestones = db.settings.goldMilestones or {}
    db.sessions = db.sessions or {}
    db.levels = db.levels or {}
    db.journey = db.journey or {}
    db.events = db.events or {}
    db.stats = db.stats or {}
    db.screenshots = db.screenshots or {}
    db.levelSnapshots = db.levelSnapshots or {}
    db.journal = db.journal or {}
    db.goldHistory = db.goldHistory or {}
    db.goldByLevel = db.goldByLevel or {}
    db.goldLooted = db.goldLooted or {total=0,byLevel={}}
    db.goldLooted.total = tonumber(db.goldLooted.total) or 0
    db.goldLooted.byLevel = db.goldLooted.byLevel or {}
    db.dungeons = db.dungeons or {}
    db.professions = db.professions or {initialized=false,current={},history={},milestones={}}
    db.professions.current = db.professions.current or {}
    db.professions.history = db.professions.history or {}
    db.professions.milestones = db.professions.milestones or {}
    db.guild = db.guild or {initialized=false,current=nil,history={}}
    db.guild.history = db.guild.history or {}
    db.levelActivity = db.levelActivity or {}
    db.firstVisitedZones = db.firstVisitedZones or {}
    db.travel = db.travel or {groundYards=0,taxiYards=0,taxiSeconds=0,taxiRoutes=0,byLevel={}}
    db.travel.byLevel = db.travel.byLevel or {}
    db.duels = db.duels or {total=0,wins=0,losses=0,byLevel={},history={}}
    db.duels.byLevel = db.duels.byLevel or {}
    db.duels.history = db.duels.history or {}
    db.combat = db.combat or {kills={total=0,mobs={}},deathsByMob={}}
    db.combat.kills = db.combat.kills or {total=0,mobs={}}
    db.combat.kills.total = tonumber(db.combat.kills.total) or 0
    db.combat.kills.mobs = db.combat.kills.mobs or {}
    db.combat.deathsByMob = db.combat.deathsByMob or {}
    db.combat.critterIDs = db.combat.critterIDs or {} -- npcIDs seen as creature type "Critter" (learned from target/mouseover)

    db.stats.deaths = db.stats.deaths or 0
    db.stats.totalSessionTime = db.stats.totalSessionTime or 0
    db.stats.zoneChanges = db.stats.zoneChanges or 0
    db.stats.levelUps = db.stats.levelUps or 0
    db.stats.dungeonVisits = db.stats.dungeonVisits or 0
    db.stats.dungeonCompletions = db.stats.dungeonCompletions or 0
    db.stats.firstLogin = db.stats.firstLogin or db.character.created or time()
    db.zoneTime = db.zoneTime or {}
    db.locationTime = db.locationTime or {zones={},subZones={},maps={},categories={}}
    db.locationTime.zones = db.locationTime.zones or {}
    db.locationTime.subZones = db.locationTime.subZones or {}
    db.locationTime.maps = db.locationTime.maps or {}
    db.locationTime.categories = db.locationTime.categories or {}
    self:MigrateDB(db) -- layout changes are listed in Migrations.lua
    db.lastAddonVersion = self.VERSION
    if db.settings.showMapJourney == nil then db.settings.showMapJourney = true end

    if db.settings.trackJourney == nil then
        db.settings.trackJourney = true
    end
    if db.settings.levelScreenshots == nil then
        db.settings.levelScreenshots = true
    end

    local info = GetCharacterInfo()

    if not db.character.created then
        db.character.created = time()
        db.character.firstSeenLevel = UnitLevel("player")
    end

    db.character.guid = db.character.guid or (UnitGUID and UnitGUID("player")) or nil
    db.character.name = info.name
    db.character.realm = info.realm
    db.character.race = info.race
    db.character.raceFile = info.raceFile
    db.character.raceID = info.raceID
    db.character.class = info.class
    db.character.classFile = info.classFile
    db.character.classID = info.classID
    db.character.lastSeen = time()
end


function MCF:GetCharacterKey()
    if not MyCharForeverDB or not MyCharForeverDB.character then return nil end
    local ch=MyCharForeverDB.character
    return tostring(ch.realm or GetRealmName() or "?").."::"..tostring(ch.name or UnitName("player") or "?")
end

function MCF:EnsureAccountDB()
    MyCharForeverAccountDB=MyCharForeverAccountDB or {}
    local a=MyCharForeverAccountDB
    a.version=a.version or 1
    a.characters=a.characters or {}
    a.created=a.created or time()
    return a
end

function MCF:GetLivePlayedTime()
    local total=tonumber(self.totalPlayed) or 0
    if self.playedSyncAt then total=total+math.max(0,GetTime()-self.playedSyncAt) end
    return total
end

function MCF:GetLiveSessionTime()
    if not self.sessionStartTime then return 0 end
    local elapsed=math.max(0,GetTime()-self.sessionStartTime)
    -- On a brand-new character the addon may start before WoW begins counting
    -- /played. Once /played is known, never let the session exceed it.
    local played=self:GetLivePlayedTime()
    if played>0 then elapsed=math.min(elapsed,played) end
    return elapsed
end

function MCF:GetAverageSessionTime()
    if not MyCharForeverDB then return 0 end
    local sum,count=0,0
    for _,s in ipairs(MyCharForeverDB.sessions or {}) do
        local d=tonumber(s.duration)
        if s==self.currentSession and not s.endTime then d=self:GetLiveSessionTime() end
        if d and d>=0 then sum=sum+d; count=count+1 end
    end
    return count>0 and (sum/count) or 0
end

-- Current gold for the account overview. GetMoney() can report 0 while logging out, which used to overwrite the stored
-- balance of every character; the last value seen by the gold tracking is used then.
function MCF:KnownMoney(stored)
    local now=GetMoney and tonumber(GetMoney()) or nil
    if now and now>0 then return now end
    local last=MyCharForeverDB and MyCharForeverDB.stats and tonumber(MyCharForeverDB.stats.lastKnownMoney)
    if last then return last end
    return now or tonumber(stored) or 0
end

function MCF:UpdateAccountCharacterSummary(totalPlayed)
    if not MyCharForeverDB then return end
    local adb=self:EnsureAccountDB()
    local key=self:GetCharacterKey(); if not key then return end
    local db=MyCharForeverDB; local ch=db.character or {}
    local old=adb.characters[key] or {}
    local played=tonumber(totalPlayed)
    if played and self.playedSyncAt then played=played+math.max(0,GetTime()-self.playedSyncAt) end
    played=played or self:GetLivePlayedTime() or tonumber(old.played) or 0
    local afk=self.GetTotalAFKTime and self:GetTotalAFKTime() or 0
    local tr=db.travel or {}
    local summary={
        key=key,name=ch.name or UnitName("player"),realm=ch.realm or GetRealmName(),
        race=ch.race,raceFile=ch.raceFile,class=ch.class,classFile=ch.classFile,
        level=UnitLevel("player") or old.level or 1,
        played=played,afk=tonumber(afk) or 0,activePlayed=math.max(0,played-(tonumber(afk) or 0)),
        money=MCF:KnownMoney(old.money),
        deaths=tonumber(db.stats and db.stats.deaths) or 0,
        dungeonVisits=tonumber(db.stats and db.stats.dungeonVisits) or 0,
        dungeonCompletions=tonumber(db.stats and db.stats.dungeonCompletions) or 0,
        levelUps=tonumber(db.stats and db.stats.levelUps) or 0,
        groundYards=tonumber(tr.groundYards) or 0,taxiYards=tonumber(tr.taxiYards) or 0,
        taxiSeconds=tonumber(tr.taxiSeconds) or 0,taxiRoutes=tonumber(tr.taxiRoutes) or 0,
        screenshots=#(db.screenshots or {}),journal=#(db.journal or {}),
        sessions=#(db.sessions or {}),avgSession=self:GetAverageSessionTime(),
        firstTracked=ch.created or old.firstTracked,lastSeen=time(),
        zones={},
    }
    local quests,bosses=0,0
    for _,activity in pairs(db.levelActivity or {}) do
        quests=quests+#(activity.quests or {}); bosses=bosses+#(activity.bosses or {})
    end
    summary.quests=quests; summary.bosses=bosses
    for zoneName,_ in pairs(db.zoneTime or {}) do if type(zoneName)=="string" then summary.zones[zoneName]=true end end
    adb.characters[key]=summary
    adb.lastUpdated=time()
end

function MCF:GetAccountCharacters()
    local adb=self:EnsureAccountDB()
    local rows={}
    for _,ch in pairs(adb.characters or {}) do rows[#rows+1]=ch end
    table.sort(rows,function(a,b)
        if (a.realm or "")==(b.realm or "") then return (a.name or "")<(b.name or "") end
        return (a.realm or "")<(b.realm or "")
    end)
    return rows
end


function MCF:GetLevelActivity(level)
    if not MyCharForeverDB then return nil end
    level=tonumber(level) or UnitLevel("player")
    MyCharForeverDB.levelActivity=MyCharForeverDB.levelActivity or {}
    local a=MyCharForeverDB.levelActivity[level]
    if not a then
        a={quests={},deaths={},dungeons={},bosses={},sessions={},zones={},journal={},screenshots={}}
        MyCharForeverDB.levelActivity[level]=a
    end
    a.quests=a.quests or {}; a.deaths=a.deaths or {}; a.dungeons=a.dungeons or {}
    a.bosses=a.bosses or {}; a.sessions=a.sessions or {}; a.zones=a.zones or {}
    a.journal=a.journal or {}; a.screenshots=a.screenshots or {}
    a.mobKills=tonumber(a.mobKills) or 0
    a.mobKillTypes=a.mobKillTypes or {}
    a.deathsByMob=a.deathsByMob or {}
    return a
end

function MCF:CaptureLevelXPRequirement(level)
    local a=self:GetLevelActivity(level or UnitLevel("player"))
    if not a then return end
    if UnitXPMax then
        local maxXP=tonumber(UnitXPMax("player"))
        if maxXP and maxXP>0 then a.requiredXP=maxXP end
    end
end

function MCF:RecordLevelZone(zone,subZone,mapID)
    if not MyCharForeverDB or not zone or zone=="" then return end
    local level=UnitLevel("player")
    local a=self:GetLevelActivity(level)
    if not a then return end
    if not a.zones[zone] then
        MyCharForeverDB.firstVisitedZones=MyCharForeverDB.firstVisitedZones or {}
        local firstEver=not MyCharForeverDB.firstVisitedZones[zone]
        a.zones[zone]={first=time(),subZone=subZone,mapID=mapID,firstEver=firstEver}
        if firstEver then MyCharForeverDB.firstVisitedZones[zone]={time=time(),level=level,mapID=mapID} end
    end
end

function MCF:AddEvent(eventType, data)
    if not MyCharForeverDB then return end

    data = data or {}

    local mapID = C_Map.GetBestMapForUnit("player")
    local x, y

    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            x, y = pos:GetXY()
        end
    end

    local event = {
        time = time(),
        type = eventType,
        level = UnitLevel("player"),
        mapID = mapID,
        x = x,
        y = y,
        zone = GetZoneText(),
        subZone = GetSubZoneText(),
        data = data,
    }

    table.insert(MyCharForeverDB.events, event)
    return event
end

function MCF:StartSession()
    local session = {
        startTime = time(),
        endTime = nil,
        levelStart = UnitLevel("player"),
        levelEnd = nil,
        zoneStart = GetZoneText(),
    }

    local previous = MyCharForeverDB.sessions[#MyCharForeverDB.sessions]
    table.insert(MyCharForeverDB.sessions, session)
    if previous and self.CheckComeback then pcall(self.CheckComeback, self, previous) end
    local a=self:GetLevelActivity(session.levelStart)
    if a then table.insert(a.sessions,{time=session.startTime,sessionIndex=#MyCharForeverDB.sessions}) end
    self.currentSession = session
    self.sessionStartTime = GetTime()

    self:AddEvent("LOGIN")
    RequestTimePlayed()
end

function MCF:EndSession()
    if not self.currentSession then return end

    self.currentSession.endTime = time()
    self.currentSession.levelEnd = UnitLevel("player")
    self.currentSession.zoneEnd = GetZoneText()

    if self.sessionStartTime then
        self.currentSession.duration = math.floor(GetTime() - self.sessionStartTime)
        MyCharForeverDB.stats.totalSessionTime =
            (MyCharForeverDB.stats.totalSessionTime or 0) + self.currentSession.duration
    end

    if self.CommitCurrentLevelSession then
        self:CommitCurrentLevelSession()
    end

    self:AddEvent("LOGOUT")
    MyCharForeverDB.character.lastSeen = time()
end

function MCF:FormatDistance(yards)
    yards=tonumber(yards) or 0
    local locale=GetLocale and GetLocale() or "enUS"
    if locale=="enUS" then
        if yards>=1760 then return string.format("%.2f mi",yards/1760) end
        return string.format("%d yd",math.floor(yards+0.5))
    end
    local meters=yards*0.9144
    if meters>=1000 then return string.format("%.2f km",meters/1000) end
    return string.format("%d m",math.floor(meters+0.5))
end

function MCF:FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if days > 0 then
        return string.format("%dd:%02dh:%02dm:%02ds", days, hours, minutes, secs)
    end

    if hours > 0 then return string.format("%02dh:%02dm:%02ds", hours, minutes, secs) end
    if minutes > 0 then return string.format("%dm:%02ds", minutes, secs) end
    return string.format("%ds", secs)
end


-- AFK tracking, introduced in v0.9.39.
-- Older levels intentionally remain "not recorded": AFK time cannot be reconstructed.
local afkTicker
local afkLastTick

local function EnsureAFKData()
    if not MyCharForeverDB then return end
    if not MyCharForeverDB.afk then
        MyCharForeverDB.afk={total=0,byLevel={},trackingSince=time()}
    end
    MyCharForeverDB.afk.byLevel=MyCharForeverDB.afk.byLevel or {}
    MyCharForeverDB.afk.total=tonumber(MyCharForeverDB.afk.total) or 0
    -- "Not moved from the spot": the game flags AFK only after minutes, so standing still is counted on its own.
    local st=MyCharForeverDB.afk.stationary
    if not st then st={total=0,byLevel={},longest={seconds=0},since=time()}; MyCharForeverDB.afk.stationary=st end
    st.byLevel=st.byLevel or {}; st.longest=st.longest or {seconds=0}
    st.total=tonumber(st.total) or 0
end

function MCF:GetStationaryTotal()
    local st=MyCharForeverDB and MyCharForeverDB.afk and MyCharForeverDB.afk.stationary
    return st and (tonumber(st.total) or 0) or nil
end

function MCF:GetStationaryForLevel(level)
    local st=MyCharForeverDB and MyCharForeverDB.afk and MyCharForeverDB.afk.stationary
    local v=st and st.byLevel and st.byLevel[tonumber(level)]
    return v~=nil and (tonumber(v) or 0) or nil
end

-- Returns seconds, level, timestamp of the longest uninterrupted stretch without moving.
function MCF:GetLongestStationary()
    local st=MyCharForeverDB and MyCharForeverDB.afk and MyCharForeverDB.afk.stationary
    local l=st and st.longest
    if not l or (tonumber(l.seconds) or 0)<=0 then return nil end
    return tonumber(l.seconds) or 0,l.level,l.time
end

-- Current stretch (seconds), for the overview and /mcf still.
local stillState={streak=0,moveTicks=0}
function MCF:GetCurrentStationary() return stillState.streak end

-- Chat messages that only matter while debugging. Off unless the player switches it on in the settings
-- (Diagnostics card); the data itself is always recorded, only the chat line is optional.
function MCF:DebugPrint(msg)
    local st=MyCharForeverDB and MyCharForeverDB.settings
    if st and st.debugChat==true then print("|cff00ccffMyCharForever|r: "..msg) end
end

-- Status messages in the chat (loaded, level reached, dungeon entered, achievement unlocked ...).
-- Off by default: the data is recorded either way, only the chat line is optional (Settings > Diagnostics).
function MCF:Notify(msg)
    local st=MyCharForeverDB and MyCharForeverDB.settings
    if st and st.chatMessages==true then print("|cff00ccffMyCharForever|r: "..msg) end
end

MCF:AddCommand{group="debug", usage="/mcf still", key="still",
    de="Zeit ohne Bewegung anzeigen (aktuell, gesamt, längste Phase)",
    en="Show time without moving (current, total, longest stretch)",
    run=function()
        local f=function(v) return MCF:FormatDuration(v or 0) end
        local sec,lvl=MCF:GetLongestStationary()
        print("|cff00ccffMyCharForever|r: "..string.format("now %s | total %s | longest %s (level %s)",
            f(MCF:GetCurrentStationary()),f(MCF:GetStationaryTotal()),f(sec),tostring(lvl or "-")))
    end}

MCF:AddCommand{group="debug", usage="/mcf cpu", key="cpu",
    de="CPU-Verbrauch dieses Addons anzeigen (braucht /console scriptProfile 1 + /reload)",
    en="Show this addon's CPU use (needs /console scriptProfile 1 + /reload)",
    run=function()
        local on=GetCVar and GetCVar("scriptProfile")=="1"
        if not on then
            print("|cff00ccffMyCharForever|r: "..(MCF:GetLanguage()=="deDE"
                and "Profiling ist aus. Mit /console scriptProfile 1 und danach /reload einschalten."
                or "Profiling is off. Enable with /console scriptProfile 1, then /reload."))
            return
        end
        if UpdateAddOnCPUUsage then UpdateAddOnCPUUsage() end
        local get=(C_AddOns and C_AddOns.GetAddOnCPUUsage) or GetAddOnCPUUsage
        print("|cff00ccffMyCharForever|r: CPU total (ms) "..string.format("%.0f",get and get("MyCharForever") or 0))
    end}

local function IsMovingNow()
    if UnitOnTaxi and UnitOnTaxi("player") then return true end
    if IsFalling and IsFalling() then return true end
    if GetUnitSpeed then
        local speed=GetUnitSpeed("player")
        -- WoW Forever can hand out "secret" numbers (type is still "number"); comparing one raises an error.
        -- Unknown speed -> nil: the caller skips that second instead of guessing.
        if issecretvalue and issecretvalue(speed) then return nil end
        if type(speed)=="number" and speed>0 then return true end
    end
    return false
end

function MCF:GetTotalAFKTime()
    return MyCharForeverDB and MyCharForeverDB.afk and (tonumber(MyCharForeverDB.afk.total) or 0) or nil
end

function MCF:GetAFKTimeForLevel(level)
    if not MyCharForeverDB or not MyCharForeverDB.afk or not MyCharForeverDB.afk.byLevel then return nil end
    local v=MyCharForeverDB.afk.byLevel[tonumber(level)]
    return v~=nil and (tonumber(v) or 0) or nil
end

function MCF:StartAFKTracking()
    EnsureAFKData()
    afkLastTick=GetTime()
    if afkTicker then afkTicker:Cancel() end
    afkTicker=C_Timer.NewTicker(1,function()
        if not MyCharForeverDB then return end
        EnsureAFKData()
        local now=GetTime()
        local dt=now-(afkLastTick or now)
        afkLastTick=now
        -- Ignore long stalls/loading screens; only count time while WoW itself flags AFK.
        local st=MyCharForeverDB.afk.stationary
        if dt>0 and dt<=5 then
            local moving=IsMovingNow()
            if moving==nil then
                -- speed unreadable this second: neither moving nor standing still is counted
            elseif moving then
                -- A single step does not end a stretch; two moving seconds in a row do.
                stillState.moveTicks=stillState.moveTicks+1
                if stillState.moveTicks>=2 then stillState.streak=0 end
            else
                stillState.moveTicks=0
                stillState.streak=stillState.streak+dt
                local level=UnitLevel("player") or MCF.currentLevel or 0
                st.total=st.total+dt
                st.byLevel[level]=(tonumber(st.byLevel[level]) or 0)+dt
                if stillState.streak>(tonumber(st.longest.seconds) or 0) then
                    st.longest.seconds=stillState.streak; st.longest.level=level; st.longest.time=time()
                end
            end
        else
            stillState.streak=0; stillState.moveTicks=0 -- loading screen / long stall: position changed
        end
        -- The AFK flag can be a secret value (e.g. in combat): it cannot be tested then, so that second is not counted.
        local afkNow=UnitIsAFK and UnitIsAFK("player")
        if issecretvalue and issecretvalue(afkNow) then afkNow=nil end
        if dt>0 and dt<=5 and afkNow then
            local level=UnitLevel("player") or MCF.currentLevel or 0
            MyCharForeverDB.afk.total=MyCharForeverDB.afk.total+dt
            MyCharForeverDB.afk.byLevel[level]=(tonumber(MyCharForeverDB.afk.byLevel[level]) or 0)+dt
        end
    end)
end

-- Combat-log compatibility ---------------------------------------------------
-- Forever can expose either the modern CLEU payload (with hideCaster/raid flags)
-- or the older compact payload. Normalize both layouts before using the data.
local lastHostileDamage=nil
local recentlyDamagedMobs={}

local function CombatPayload(...)
    local info
    if CombatLogGetCurrentEventInfo then
        local got={CombatLogGetCurrentEventInfo()}
        if got[2] then info=got end
    end
    if not info then info={...} end
    if not info[2] then return nil end
    local modern=(type(info[3])=="boolean")
    if modern then
        return {raw=info,modern=true,subevent=info[2],sourceGUID=info[4],sourceName=info[5],sourceFlags=info[6],destGUID=info[8],destName=info[9],destFlags=info[10],payload=12}
    end
    return {raw=info,modern=false,subevent=info[2],sourceGUID=info[3],sourceName=info[4],sourceFlags=info[5],destGUID=info[6],destName=info[7],destFlags=info[8],payload=9}
end

local function CreatureIDFromGUID(guid)
    if type(guid)~="string" then return nil end
    local _,_,_,_,_,npc=guid:match("^([^-]+)%-([^-]*)%-([^-]*)%-([^-]*)%-([^-]*)%-([^-]+)")
    return tonumber(npc)
end

-- Canonical NPC labels confirmed in Forever; use IDs for grouping, never
-- remove arbitrary trailing words from other NPC names.
local canonicalNPCNames = {
    [3035] = {de="Flachlandpuma", en="Flatland Cougar"},
}
local function CanonicalMobName(name, npcID)
    local names = npcID and canonicalNPCNames[npcID]
    if not names then return name end
    local lang = MCF.GetLanguage and MCF:GetLanguage() or "de"
    return (lang == "de" or lang == "deDE") and names.de or names.en
end

local function MobKey(name,guid)
    local id=CreatureIDFromGUID(guid)
    if id then return "npc:"..id,id end
    return "name:"..tostring(name or "?"),nil
end

local function AddMobCount(tbl,name,guid)
    local key,id=MobKey(name,guid)
    local row=tbl[key]
    if type(row)~="table" then row={count=tonumber(row) or 0} end
    row.count=(tonumber(row.count) or 0)+1
    -- A missing/placeholder meter label must not overwrite an earlier real name.
    local candidate = name
    if type(candidate) ~= "string" or candidate == "" or candidate == "?" or candidate == "Unknown" then candidate = row.name end
    row.name=CanonicalMobName(candidate or "?", id or row.npcID); row.npcID=id or row.npcID; row.guid=guid or row.guid
    tbl[key]=row
    return row
end

local function DisplayMobName(row)
    local name=CanonicalMobName(row.name,row.npcID)
    if not name or name=="?" then name=row.npcID and ("NPC #"..row.npcID) or "Unbekannter Gegner" end
    return name
end

-- Highest-count row of a mob table. On a tie it returns {tied=true, ties=n, count=n, names={...}}.
function MCF:GetTopMob(tbl)
    local best, maxCount = nil, 0
    for _,row in pairs(tbl or {}) do
        if type(row)=="table" then
            local n=tonumber(row.count) or 0
            if n>maxCount then best=row; maxCount=n end
        end
    end
    if not best then return nil end
    local names={}
    for _,row in pairs(tbl) do
        if type(row)=="table" and (tonumber(row.count) or 0)==maxCount then names[#names+1]=DisplayMobName(row) end
    end
    if #names>1 then
        table.sort(names)
        return {count=maxCount,ties=#names,tied=true,names=names}
    end
    local display={}
    for k,v in pairs(best) do display[k]=v end
    display.name=DisplayMobName(best)
    return display
end

local MAX_TIED_NAMES=2
-- One text format for "most defeated mob" and "nemesis"; unit follows the count ("x", " Deaths").
function MCF:FormatTopMob(top,unit)
    if not top then return self:T("none") end
    unit=unit or ""
    if not top.tied then return top.name.." - "..tostring(top.count or 0)..unit end
    local shown={}
    for i=1,math.min(MAX_TIED_NAMES,#top.names) do shown[i]=top.names[i] end
    local list=table.concat(shown,", ")
    if #top.names>MAX_TIED_NAMES then list=list.." +"..(#top.names-MAX_TIED_NAMES) end
    local label=self:GetLanguage()=="deDE" and "Gleichstand" or "Tie"
    return label..": "..list.." - "..tostring(top.count)..unit
end

local function RecordPersonalKill(name,guid)
    if not MyCharForeverDB then return end
    if type(name) ~= "string" or name == "" or name == "?" then
        local id=CreatureIDFromGUID(guid)
        if id then name="NPC #"..id else name="Unbekannter Gegner" end
    end
    local c=MyCharForeverDB.combat
    c.kills.total=(tonumber(c.kills.total) or 0)+1
    AddMobCount(c.kills.mobs,name,guid)
    local a=MCF:GetLevelActivity(UnitLevel("player"))
    if a then a.mobKills=(tonumber(a.mobKills) or 0)+1; AddMobCount(a.mobKillTypes,name,guid) end

    if MCF.OnIconicKill then pcall(MCF.OnIconicKill,MCF,name) end
end

local function RecordMobDeath(name,guid)
    if not MyCharForeverDB or not name then return end
    AddMobCount(MyCharForeverDB.combat.deathsByMob,name,guid)
    local a=MCF:GetLevelActivity(UnitLevel("player")); if a then AddMobCount(a.deathsByMob,name,guid) end
end

-- Called only for a confirmed lethal Death Recap row. Do not change the
-- total death count: PLAYER_DEAD already owns that statistic.
function MCF:RecordDeathRecapKiller(name, sourceGUID)
    if type(name) ~= "string" or name == "" or not MyCharForeverDB then return false end
    local pending = self._pendingMobDeath
    if not pending or pending.resolved or (time() - (pending.time or 0)) > 600 then return false end
    if issecretvalue and (issecretvalue(name) or (sourceGUID ~= nil and issecretvalue(sourceGUID))) then return false end
    -- Only attribute the current character's pending death once.
    pending.resolved = true
    RecordMobDeath(name, sourceGUID)
    local a = self:GetLevelActivity(pending.level or UnitLevel("player"))
    if a and a.deaths then
        for i = #a.deaths, 1, -1 do
            local row = a.deaths[i]
            if row.time and math.abs(row.time - pending.time) <= 3 and not row.killerName then
                row.killerName, row.killerGUID = name, sourceGUID
                break
            end
        end
    end
    if pending.event then pending.event.killerName = name; pending.event.killerGUID = sourceGUID end
    MyCharForeverDB.combatDebug = MyCharForeverDB.combatDebug or {}
    MyCharForeverDB.combatDebug.lastResolvedKiller = {time=time(),name=name,method="DeathRecap.confirmedLethal"}
    self._pendingMobDeath = nil
    if self.RefreshUI then self:RefreshUI() end
    return true
end

local function IsOurCombatSource(c,playerGUID,petGUID)
    if c.sourceGUID and (c.sourceGUID==playerGUID or (petGUID and c.sourceGUID==petGUID)) then return true end
    -- Some Forever builds expose a compact CLEU payload where GUID matching is unreliable.
    -- The affiliation flag and the unit names give us safe fallbacks.
    if c.sourceFlags and COMBATLOG_OBJECT_AFFILIATION_MINE and bit and bit.band then
        if bit.band(c.sourceFlags,COMBATLOG_OBJECT_AFFILIATION_MINE)~=0 then return true end
    end
    local pn=UnitName and UnitName("player") or nil
    local petn=UnitName and UnitName("pet") or nil
    if c.sourceName and (c.sourceName==pn or (petn and c.sourceName==petn)) then return true end
    return false
end

local function RememberDamagedMob(c)
    if not c.destGUID or not c.destName then return end
    recentlyDamagedMobs[c.destGUID]={name=c.destName,guid=c.destGUID,runtime=GetTime()}
end

local function PruneDamagedMobs()
    local now=GetTime()
    for guid,row in pairs(recentlyDamagedMobs) do
        if now-(row.runtime or 0)>120 then recentlyDamagedMobs[guid]=nil end
    end
end

local function DamageInfo(c)
    local i,p=c.raw,c.payload
    if c.subevent=="SWING_DAMAGE" then return tonumber(i[p]),"white",T("Auto Attack"),nil,tonumber(i[p+1]) end
    if c.subevent=="RANGE_DAMAGE" or c.subevent=="SPELL_DAMAGE" or c.subevent=="SPELL_PERIODIC_DAMAGE" then
        local spellID=tonumber(i[p]); local ability=i[p+1] or (spellID and GetSpellInfo and GetSpellInfo(spellID)) or T("Spell")
        local amount=tonumber(i[p+3]); local overkill=tonumber(i[p+4])
        local kind=(c.subevent=="RANGE_DAMAGE" and spellID==75) and "white" or "yellow"
        return amount,kind,ability,spellID,overkill
    end
end


-- Forever damage-meter diagnostics ------------------------------------------
-- COMBAT_LOG_EVENT_UNFILTERED is protected on Forever. Do not register it.
-- Instead read Blizzard's C_DamageMeter data after PLAYER_REGEN_ENABLED.
-- Forever kill/death test ----------------------------------------------------
-- Values exposed by the Midnight/Forever combat APIs can be secret while
-- combat is active. Never inspect/compare/use them as keys until readable.
local function MCFIsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function Readable(v)
    if v==nil or MCFIsSecret(v) then return nil end
    return v
end

-- Expose secret-safe reader for Social.lua.
MCF.Readable=Readable

local function DMEnum(group,key,fallback)
    return Enum and Enum[group] and Enum[group][key] or fallback
end

local function SafeScalar(v)
    local tv=type(v)
    if tv=="string" or tv=="number" or tv=="boolean" then return v end
    return nil
end


local function CopyDamageMeterRaw(value,depth,seen)
    depth=depth or 0
    seen=seen or {}
    local tv=type(value)
    if tv=="nil" or tv=="string" or tv=="number" or tv=="boolean" then return SafeScalar(value) end
    if tv~="table" then return "<"..tv..">" end
    if seen[value] then return "<cycle>" end
    if depth>=7 then return "<max-depth>" end
    seen[value]=true
    local out={}
    local count=0
    for k,v in pairs(value) do
        count=count+1
        if count>200 then out["<truncated>"]="more than 200 fields"; break end
        local key=type(k)=="string" and k or tostring(k)
        out[key]=CopyDamageMeterRaw(v,depth+1,seen)
    end
    seen[value]=nil
    return out
end

function MCF:CaptureDamageMeterDebug()
    if InCombatLockdown and InCombatLockdown() then return end
    local out={
        capturedAt=time(),
        apiAvailable=(C_DamageMeter and C_DamageMeter.GetCombatSessionFromType) and true or false,
        player=UnitName and UnitName("player") or nil,
        playerGUID=UnitGUID and UnitGUID("player") or nil,
        level=UnitLevel and UnitLevel("player") or nil,
        combatSessionID=self._damageMeterSessionID,
        sessionIDEvents=CopyDamageMeterRaw(self._damageMeterSessionIDEvents or {}),
        meterTypes={},
    }
    if not out.apiAvailable then
        out.error="C_DamageMeter unavailable"
        self.damageMeterDebug=out
        if MyCharForeverDB then MyCharForeverDB.damageMeterDebug=out end
        return
    end
    if C_DamageMeter.IsDamageMeterAvailable then
        local ok,a,b=pcall(C_DamageMeter.IsDamageMeterAvailable)
        out.availabilityCallOK=ok
        if ok then out.isAvailable=SafeScalar(a); out.failureReason=SafeScalar(b) end
    end

    local current=DMEnum("DamageMeterSessionType","Current",1)
    local wanted={
        {name="DamageDone",value=DMEnum("DamageMeterType","DamageDone",0)},
        {name="DamageTaken",value=DMEnum("DamageMeterType","DamageTaken",7)},
        {name="Deaths",value=DMEnum("DamageMeterType","Deaths",9)},
        {name="EnemyDamageTaken",value=DMEnum("DamageMeterType","EnemyDamageTaken",10)},
    }
    for _,kind in ipairs(wanted) do
        local row={name=kind.name,damageMeterType=kind.value,combatSessionID=self._damageMeterSessionID,sources={}}
        local ok,session
        if self._damageMeterSessionID and C_DamageMeter.GetCombatSessionFromID then
            ok,session=pcall(C_DamageMeter.GetCombatSessionFromID,self._damageMeterSessionID,kind.value)
            row.query="GetCombatSessionFromID"
        else
            ok,session=pcall(C_DamageMeter.GetCombatSessionFromType,current,kind.value)
            row.query="GetCombatSessionFromType(Current)"
        end
        row.callOK=ok
        if not ok then
            row.error=tostring(session)
        elseif type(session)=="table" then
            row.rawSession=CopyDamageMeterRaw(session)
            row.durationSeconds=SafeScalar(session.durationSeconds)
            row.maxAmount=SafeScalar(session.maxAmount)
            row.totalAmount=SafeScalar(session.totalAmount)
            for i,src in ipairs(session.combatSources or {}) do
                local sr={index=i,raw=CopyDamageMeterRaw(src)}
                sr.name=SafeScalar(src.name); sr.sourceGUID=SafeScalar(src.sourceGUID); sr.sourceCreatureID=SafeScalar(src.sourceCreatureID)
                sr.isLocalPlayer=src.isLocalPlayer and true or false
                sr.totalAmount=SafeScalar(src.totalAmount); sr.amountPerSecond=SafeScalar(src.amountPerSecond)
                local ok2,detail
                if self._damageMeterSessionID and C_DamageMeter.GetCombatSessionSourceFromID then
                    ok2,detail=pcall(C_DamageMeter.GetCombatSessionSourceFromID,self._damageMeterSessionID,kind.value,src.sourceGUID,src.sourceCreatureID)
                    sr.detailQuery="GetCombatSessionSourceFromID"
                elseif C_DamageMeter.GetCombatSessionSourceFromType then
                    ok2,detail=pcall(C_DamageMeter.GetCombatSessionSourceFromType,current,kind.value,src.sourceGUID,src.sourceCreatureID)
                    sr.detailQuery="GetCombatSessionSourceFromType(Current)"
                end
                sr.detailCallOK=ok2
                if ok2 and type(detail)=="table" then sr.rawDetail=CopyDamageMeterRaw(detail)
                elseif ok2==false then sr.detailError=tostring(detail) end
                row.sources[#row.sources+1]=sr
            end
        else
            row.returnType=type(session)
        end
        out.meterTypes[#out.meterTypes+1]=row
    end
    self.damageMeterDebug=out
    if MyCharForeverDB then MyCharForeverDB.damageMeterDebug=out end
    MCF:DebugPrint("Multi-Type DamageMeter-Debug erfasst. /mcfdmgdebug zum Kopieren.")
end



local processedKillSessions={}

-- Positive kill evidence only: true if the meter reports overkill damage or a
-- deadly hit for this enemy, nil otherwise. Empty/false fields prove nothing
-- (they may just be placeholders), so they are never read as "did not die".
local function EnemyDeathEvidence(sessionID,enemyType,src)
    if not C_DamageMeter.GetCombatSessionSourceFromID then return nil end
    local ok,detail=pcall(C_DamageMeter.GetCombatSessionSourceFromID,sessionID,enemyType,
        Readable(src.sourceGUID),Readable(src.sourceCreatureID))
    if not ok or type(detail)~="table" or MCFIsSecret(detail) then return nil end
    for _,spell in ipairs(detail.combatSpells or {}) do
        if type(spell)=="table" and not MCFIsSecret(spell) then
            local deadly,overkill=Readable(spell.isDeadly),Readable(spell.overkillAmount)
            if deadly==true or (type(overkill)=="number" and overkill>0) then return true end
        end
    end
    return nil
end

local function EnemyKey(e) return e.creatureID or e.name end

local function ResolveKillsFromFinishedSession()
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local sessionID=Readable(MCF._damageMeterSessionID)
    if not sessionID or processedKillSessions[sessionID] then return end

    local signals=MCF._unitDiedSignals or {}

    local current=DMEnum("DamageMeterSessionType","Current",1)
    local enemyType=DMEnum("DamageMeterType","EnemyDamageTaken",10)
    local ok,session
    if C_DamageMeter.GetCombatSessionFromID then
        ok,session=pcall(C_DamageMeter.GetCombatSessionFromID,sessionID,enemyType)
    else
        ok,session=pcall(C_DamageMeter.GetCombatSessionFromType,current,enemyType)
    end
    if not ok or type(session)~="table" or MCFIsSecret(session) then return end

    local enemies={}
    for _,src in ipairs(session.combatSources or {}) do
        if type(src)=="table" and not MCFIsSecret(src) then
            local name=Readable(src.name)
            local cid=Readable(src.sourceCreatureID)
            local localPlayer=Readable(src.isLocalPlayer)
            if name and localPlayer~=true then
                enemies[#enemies+1]={name=name,creatureID=cid,died=EnemyDeathEvidence(sessionID,enemyType,src)}
            end
        end
    end
    if #enemies==0 then return end

    -- UNIT_DIED also fires for deaths of units we never fought (other players'
    -- kills nearby), so it is never counted on its own: kills are bounded by the
    -- enemies this session actually lists, and positive meter evidence wins.
    local positives={}
    for _,e in ipairs(enemies) do if e.died==true then positives[#positives+1]=e end end

    local single=true
    for _,e in ipairs(enemies) do if EnemyKey(e)~=EnemyKey(enemies[1]) then single=false end end

    local kills,method={},nil
    if #positives==#enemies then
        kills,method=positives,"EnemyDamageTaken overkill/isDeadly"
    elseif single then
        -- No (complete) evidence, one enemy type: bounded by the enemies listed.
        for i=1,math.min(#signals,#enemies) do kills[#kills+1]=enemies[i] end
        method="UNIT_DIED, bounded by enemies"
    elseif #positives>0 then
        kills,method=positives,"EnemyDamageTaken overkill/isDeadly (partial)"
    end

    MyCharForeverDB.combatDebug=MyCharForeverDB.combatDebug or {}
    if method then
        for _,e in ipairs(kills) do
            local guid=nil
            if e.creatureID then guid="Creature-0-0-0-0-"..tostring(e.creatureID).."-0000000000" end
            RecordPersonalKill(e.name,guid)
        end
        processedKillSessions[sessionID]=true
        MCF._unitDiedSignals={}
        MyCharForeverDB.combatDebug.lastResolvedKills={
            time=time(),sessionID=sessionID,count=#kills,enemies=#enemies,
            unitDiedSignals=#signals,method=method,name=kills[1] and kills[1].name or nil,
            positiveEvidence=#positives
        }
        if MCF.RefreshUI then MCF:RefreshUI() end
    else
        MyCharForeverDB.combatDebug.lastUnresolvedKills={
            time=time(),sessionID=sessionID,unitDiedSignals=#signals,enemyCount=#enemies
        }
    end
end

local function CaptureDeathRecapDiagnostic()
    if not MyCharForeverDB then return end
    MyCharForeverDB.combatDebug=MyCharForeverDB.combatDebug or {}
    local out={time=time(),available=false}
    if C_DeathRecap and C_DeathRecap.GetRecapEvents then
        out.available=true
        local ok,events=pcall(C_DeathRecap.GetRecapEvents)
        out.callOK=ok
        if ok and type(events)=="table" and not MCFIsSecret(events) then
            out.events=CopyDamageMeterRaw(events)
        elseif not ok then
            out.error=Readable(events)
        else
            out.secretOrUnexpected=true
        end
    end
    MyCharForeverDB.combatDebug.deathRecap=out
end

local function ResolvePendingMobDeathFromMeter()
    if not MCF._pendingMobDeath or MCF._pendingMobDeath.resolved or not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local current=DMEnum("DamageMeterSessionType","Current",1)
    local damageTaken=DMEnum("DamageMeterType","DamageTaken",7)
    local ok,session=pcall(C_DamageMeter.GetCombatSessionFromType,current,damageTaken)
    if not ok or type(session)~="table" or MCFIsSecret(session) then return end

    local killerName=nil
    for _,src in ipairs(session.combatSources or {}) do
        if type(src)=="table" and not MCFIsSecret(src) then
            local srcName=Readable(src.name)
            for _,spell in ipairs(src.combatSpells or src.spells or {}) do
                if type(spell)=="table" and not MCFIsSecret(spell) then
                    local deadly=Readable(spell.isDeadly)
                    local creature=Readable(spell.creatureName)
                    if deadly==true and (creature or srcName) then
                        killerName=creature or srcName
                        break
                    end
                end
            end
        end
        if killerName then break end
    end
    if killerName then
        RecordMobDeath(killerName,nil)
        MCF._pendingMobDeath=nil
        MyCharForeverDB.combatDebug=MyCharForeverDB.combatDebug or {}
        MyCharForeverDB.combatDebug.lastResolvedKiller={time=time(),name=killerName,method="DamageTaken.isDeadly"}
        if MCF.RefreshUI then MCF:RefreshUI() end
    end
end


function MCF:GetDamageMeterDebug()
    return self.damageMeterDebug or (MyCharForeverDB and MyCharForeverDB.damageMeterDebug) or {error="Noch keine DamageMeter-Daten erfasst."}
end


-- Individual damage values are intentionally not tracked by MyCharForever.
-- The DamageMeter diagnostic above remains temporarily available while we
-- validate death/enemy information exposed by Forever.

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("TIME_PLAYED_MSG")
frame:RegisterEvent("PLAYER_DEAD")
pcall(function() frame:RegisterEvent("UNIT_DIED") end)
pcall(function() frame:RegisterEvent("PLAYER_TARGET_CHANGED") end)
pcall(function() frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") end)
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pcall(function() frame:RegisterEvent("PLAYER_CONTROL_LOST") end)
pcall(function() frame:RegisterEvent("PLAYER_CONTROL_GAINED") end)
pcall(function() frame:RegisterEvent("QUEST_TURNED_IN") end)
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(function() frame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED") end)


-- Critter detection. The kill log only knows names/NPC IDs, so the creature type is learned whenever a unit is
-- targeted or moused over: its NPC ID goes into db.combat.critterIDs. "Critter kills" are then the kill counts
-- of those IDs (one source of truth: kills.mobs; nothing is counted twice).
MCF.CRITTER_TYPES={Critter=true,Kleintier=true,Bestiole=true,["Alimaña"]=true,Bicho=true,Animale=true,
    ["Существо"]=true,["동물"]=true,["小动物"]=true,["小動物"]=true} -- UnitCreatureType() is localized
function MCF:LearnCritter(unit)
    pcall(function()
        if not (MyCharForeverDB and MyCharForeverDB.combat and UnitCreatureType and UnitGUID) then return end
        if UnitIsPlayer(unit) or UnitPlayerControlled(unit) then return end
        local ctype=UnitCreatureType(unit)
        if MCFIsSecret(ctype) or type(ctype)~="string" or not MCF.CRITTER_TYPES[ctype] then return end
        local guid=UnitGUID(unit)
        if MCFIsSecret(guid) then return end
        local id=CreatureIDFromGUID(guid)
        if id then MyCharForeverDB.combat.critterIDs=MyCharForeverDB.combat.critterIDs or {}; MyCharForeverDB.combat.critterIDs[id]=true end
    end)
end

local recentTargetByGUID={}
local function RememberCurrentTarget()
    MCF:LearnCritter("target")
    if not UnitGUID or not UnitName then return end
    local guid=UnitGUID("target")
    local name=UnitName("target")
    -- Forever/Midnight can hand out secret values (e.g. in combat): they must not be used as table keys or stored.
    if MCFIsSecret(guid) or MCFIsSecret(name) then return end
    if guid and name then
        recentTargetByGUID[guid]={name=name,time=GetTime(),level=UnitLevel and UnitLevel("target") or nil}
    end
end

local function RecordUnitDiedDiagnostic(guid)
    if not MyCharForeverDB or not guid then return end
    MyCharForeverDB.combatDebug=MyCharForeverDB.combatDebug or {unitDeaths={}}
    local d=MyCharForeverDB.combatDebug
    d.unitDeaths=d.unitDeaths or {}
    local recent=recentTargetByGUID[guid]
    d.unitDeaths[#d.unitDeaths+1]={
        time=time(),guid=guid,npcID=CreatureIDFromGUID(guid),
        recentTargetName=recent and recent.name or nil,
        recentTargetAge=recent and (GetTime()-(recent.time or GetTime())) or nil,
        recentTargetLevel=recent and recent.level or nil,
        playerLevel=UnitLevel("player"),
        zone=GetZoneText(),subZone=GetSubZoneText(),
    }
    while #d.unitDeaths>50 do table.remove(d.unitDeaths,1) end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Each step is protected on its own: a failing step is logged (/mcf errors) and the others still run.
        local function step(name, fn, ...) MCF:SafeCall(name, fn, ...) end
        step("InitializeDB", MCF.InitializeDB, MCF)
        if MCF.RefreshLocalizedUI then step("RefreshLocalizedUI", MCF.RefreshLocalizedUI, MCF) end
        if MCF.RefreshSettingsLocalization then step("RefreshSettingsLocalization", MCF.RefreshSettingsLocalization, MCF) end

        if MCF.InitializeLevelTracking then
            step("InitializeLevelTracking", MCF.InitializeLevelTracking, MCF)
        end

        step("EnsureAccountDB", MCF.EnsureAccountDB, MCF)
        step("UpdateAccountCharacterSummary", MCF.UpdateAccountCharacterSummary, MCF)
        step("StartSession", MCF.StartSession, MCF)
        step("CaptureLevelXPRequirement", MCF.CaptureLevelXPRequirement, MCF, UnitLevel("player"))
        step("RecordLevelZone", MCF.RecordLevelZone, MCF, GetZoneText(), GetSubZoneText(), C_Map.GetBestMapForUnit("player"))

        if MCF.StartJourneyTracking then
            step("StartJourneyTracking", MCF.StartJourneyTracking, MCF)
        end
        step("StartAFKTracking", MCF.StartAFKTracking, MCF)

        MCF:Notify("v"..MCF.VERSION..T(" loaded."))

    elseif event == "PLAYER_LOGOUT" then
        MCF:UpdateAccountCharacterSummary(MCF.totalPlayed)
        MCF:EndSession()

    elseif event == "TIME_PLAYED_MSG" then
        local totalTime, levelTime = ...
        MCF.totalPlayed = totalTime
        MCF.levelPlayed = levelTime
        MCF.playedSyncAt = GetTime()
        MCF:UpdateAccountCharacterSummary(totalTime)

        if MCF.UpdatePlayedTime then
            MCF:UpdatePlayedTime(totalTime, levelTime)
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        RememberCurrentTarget()

    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        MCF:LearnCritter("mouseover")

    elseif event == "UNIT_DIED" then
        -- Forever/Midnight may expose the event payload as a secret value while
        -- combat is active. Do not touch the payload here at all; only count
        -- that the event fired. Enemy identity is resolved after combat via
        -- EnemyDamageTaken.
        MCF._unitDiedSignals=MCF._unitDiedSignals or {}
        MCF._unitDiedSignals[#MCF._unitDiedSignals+1]=true
        MyCharForeverDB.combatDebug=MyCharForeverDB.combatDebug or {}
        MyCharForeverDB.combatDebug.unitDiedEvents=(MyCharForeverDB.combatDebug.unitDiedEvents or 0)+1

    elseif event == "PLAYER_DEAD" then
        MyCharForeverDB.stats.deaths = MyCharForeverDB.stats.deaths + 1

        -- Killer attribution is resolved after combat from DamageTaken/Deaths;
        -- the old lastHostileDamage CLEU path is intentionally no longer used.
        local killer=nil
        MCF._pendingMobDeath={time=time(),level=UnitLevel("player")}
        C_Timer.After(0.5,CaptureDeathRecapDiagnostic)
        C_Timer.After(1.5,CaptureDeathRecapDiagnostic)
        local deathEvent=MCF:AddEvent("DEATH", {
            deathNumber = MyCharForeverDB.stats.deaths,
        })
        MCF._pendingMobDeath.event = deathEvent
        if MyCharForeverDB.stats.deaths == 1 and MCF.OnFirstDeath then pcall(MCF.OnFirstDeath, MCF) end
        local a=MCF:GetLevelActivity(UnitLevel("player"))
        if a then table.insert(a.deaths,{
            time=deathEvent and deathEvent.time or time(),
            zone=GetZoneText(),subZone=GetSubZoneText(),
            mapID=deathEvent and deathEvent.mapID,x=deathEvent and deathEvent.x,y=deathEvent and deathEvent.y,
            killerName=killer and killer.name or nil,killerGUID=killer and killer.guid or nil
        }) end
        lastHostileDamage=nil

        if MCF.RecordJourneyPoint then
            MCF:RecordJourneyPoint("DEATH", true)
        end

    elseif event == "QUEST_TURNED_IN" then
        local questID,xpReward,moneyReward=...
        local title=nil
        if C_QuestLog and C_QuestLog.GetTitleForQuestID then
            title=C_QuestLog.GetTitleForQuestID(questID)
        end
        MCF:CaptureLevelXPRequirement(UnitLevel("player"))
        local a=MCF:GetLevelActivity(UnitLevel("player"))
        if a then table.insert(a.quests,{
            time=time(),questID=questID,title=title,xp=xpReward,money=moneyReward,
            zone=GetZoneText(),subZone=GetSubZoneText()
        }) end
        MCF:AddEvent("QUEST_TURNED_IN",{questID=questID,title=title,xp=xpReward,money=moneyReward})
    elseif event == "PLAYER_REGEN_DISABLED" then
        MCF._damageMeterCombatStarted=GetTime()
        MCF._unitDiedSignals={}
        MCF._damageMeterSessionID=nil
        MCF._damageMeterSessionIDEvents={}

    elseif event == "DAMAGE_METER_COMBAT_SESSION_UPDATED" then
        local dmType,sessionID=...
        MCF._damageMeterSessionIDEvents=MCF._damageMeterSessionIDEvents or {}
        MCF._damageMeterSessionIDEvents[#MCF._damageMeterSessionIDEvents+1]={damageMeterType=SafeScalar(dmType),sessionID=SafeScalar(sessionID),at=GetTime()}
        if type(sessionID)=="number" and sessionID>0 then MCF._damageMeterSessionID=sessionID end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Forever 1.60 uses Blizzard's C_DamageMeter API. Its values may be
        -- secret while combat is active, so inspect the finished session only
        -- after combat has ended and the restrictions have cleared.
        local tries=0
        local function ReadFinishedCombat()
            tries=tries+1
            if MCF.CaptureDamageMeterDebug then MCF:CaptureDamageMeterDebug() end
            ResolveKillsFromFinishedSession()
            ResolvePendingMobDeathFromMeter()
            if MCF._pendingMobDeath and tries<5 then C_Timer.After(1,ReadFinishedCombat) end
        end
        C_Timer.After(0.75,ReadFinishedCombat)

    elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" then
        if MCF.JourneyTaxiEvent then
            MCF:JourneyTaxiEvent()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        MyCharForeverDB.stats.zoneChanges = (MyCharForeverDB.stats.zoneChanges or 0) + 1
        MCF:RecordLevelZone(GetZoneText(),GetSubZoneText(),C_Map.GetBestMapForUnit("player"))
        MCF:AddEvent("ZONE_CHANGED")

        if MCF.RecordJourneyPoint then
            MCF:RecordJourneyPoint("ZONE_CHANGED", true)
        end
    end
end)
