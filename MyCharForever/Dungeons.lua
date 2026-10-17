local addonName, MCF = ...
local function T(key) return MCF:T(key) end

local f=CreateFrame("Frame")
local currentRun=nil

-- Item level of a link (nil while the item is not cached yet or has none).
local function ItemLevelOf(link)
    if not link or not GetItemInfo then return nil end
    local _,_,_,ilvl=GetItemInfo(link)
    ilvl=tonumber(ilvl)
    if ilvl and ilvl>0 then return ilvl end
    return nil
end
local lastInstanceKey=nil

local function SafeInstanceInfo()
    if not GetInstanceInfo then return nil end
    local name, instanceType, difficultyID, difficultyName, maxPlayers,
          dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, lfgDungeonID = GetInstanceInfo()
    return {
        name=name, instanceType=instanceType, difficultyID=difficultyID,
        difficultyName=difficultyName, maxPlayers=maxPlayers,
        instanceID=instanceID, instanceGroupSize=instanceGroupSize,
        lfgDungeonID=lfgDungeonID,
    }
end

local function IsDungeon(info)
    if not info then return false end
    -- "party" is the normal 5-player dungeon instance type.
    return info.instanceType=="party"
end

local function CurrentKey(info)
    if not info then return nil end
    return tostring(info.instanceID or "?")..":"..tostring(info.name or "?")
end


local function UnitClassSafe(unit)
    if not UnitClass then return nil,nil end
    local localized,classFile=UnitClass(unit)
    return localized,classFile
end

local function CapturePartyRoster(run)
    if not run then return end
    run.party=run.party or {}
    local now=time()
    local function remember(unit)
        if not UnitExists or not UnitExists(unit) then return end
        local name=UnitName(unit)
        if not name or name=="" then return end
        local realm=GetRealmName and GetRealmName() or nil
        local localizedClass,classFile=UnitClassSafe(unit)
        local level=UnitLevel(unit)
        local key=name
        local entry=run.party[key]
        if not entry then
            entry={name=name,realm=realm,class=localizedClass,classFile=classFile,
                   level=level,firstSeen=now,lastSeen=now}
            run.party[key]=entry
        else
            entry.lastSeen=now
            if level and level>0 then entry.level=level end
            if localizedClass then entry.class=localizedClass end
            if classFile then entry.classFile=classFile end
        end
    end
    remember("player")
    if GetAverageItemLevel then
        local ok,_,equipped=pcall(GetAverageItemLevel)
        local own=run.party[UnitName("player") or ""]
        if ok and own and type(equipped)=="number" and not own.averageItemLevel then own.averageItemLevel=equipped end
    end
    local n=GetNumGroupMembers and GetNumGroupMembers() or 0
    if IsInRaid and IsInRaid() then
        for i=1,n do remember("raid"..i) end
    else
        for i=1,math.max(0,n-1) do remember("party"..i) end
    end
end

---------------------------------------------------------------------------
-- Average item level of the party (setting inspectParty, default on). Runs by itself in the background: one member at a time,
-- only out of combat, only when the player's own inspect window is closed, only in range, at most 3 tries per member and run.
-- The result is a single number per member inside the dungeon run (run.party[name].averageItemLevel); nothing else is kept,
-- the queue lives in memory and ends with the run. Missing numbers stay missing.
---------------------------------------------------------------------------
local INSPECT_SLOTS={1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
local INSPECT_MIN_ITEMS=6
local INSPECT_MAX_TRIES=3
local inspect={current=nil,tries={},timer=0}

local function InspectEnabled()
    local st=MyCharForeverDB and MyCharForeverDB.settings
    return not (st and st.inspectParty==false)
end

local function InspectUnits()
    local out={}
    local n=GetNumGroupMembers and GetNumGroupMembers() or 0
    if IsInRaid and IsInRaid() then return out end
    for i=1,math.max(0,n-1) do out[#out+1]="party"..i end
    return out
end

-- nil when too few items are readable yet (cache) - then another try follows.
local function ReadItemLevel(unit)
    local sum,count,missing=0,0,false
    for _,slot in ipairs(INSPECT_SLOTS) do
        local link=GetInventoryItemLink and GetInventoryItemLink(unit,slot)
        if link then
            local ilvl=ItemLevelOf(link)
            if ilvl then sum=sum+ilvl; count=count+1 else missing=true end
        end
    end
    if missing or count<INSPECT_MIN_ITEMS then return nil end
    return math.floor(sum/count*10+0.5)/10
end

local NextInspect
local function InspectLater(seconds)
    if C_Timer and C_Timer.After then C_Timer.After(seconds,function() NextInspect() end) end
end

NextInspect=function()
    if not currentRun or not InspectEnabled() or inspect.current then return end
    if not (NotifyInspect and CanInspect) then return end
    if UnitAffectingCombat and UnitAffectingCombat("player") then return InspectLater(8) end
    if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then return InspectLater(12) end
    local pending=false
    for _,unit in ipairs(InspectUnits()) do
        local name=UnitExists and UnitExists(unit) and UnitName(unit)
        local entry=name and currentRun.party and currentRun.party[name]
        if entry and not entry.averageItemLevel and (inspect.tries[name] or 0)<INSPECT_MAX_TRIES then
            pending=true
            local inRange=CheckInteractDistance and CheckInteractDistance(unit,1)
            if inRange and CanInspect(unit) then
                inspect.tries[name]=(inspect.tries[name] or 0)+1
                local token={unit=unit,name=name}
                inspect.current=token
                NotifyInspect(unit)
                if C_Timer and C_Timer.After then
                    C_Timer.After(4,function()
                        if inspect.current==token then
                            inspect.current=nil
                            if ClearInspectPlayer then ClearInspectPlayer() end
                            InspectLater(1)
                        end
                    end)
                end
                return
            end
        end
    end
    if pending then InspectLater(20) end
end

local function OnInspectReady(guid)
    local cur=inspect.current
    if not cur or not currentRun then return end
    if UnitGUID and guid and UnitGUID(cur.unit)~=guid then return end
    inspect.current=nil
    local entry=currentRun.party and currentRun.party[cur.name]
    local value=entry and ReadItemLevel(cur.unit)
    if value then entry.averageItemLevel=value end
    if ClearInspectPlayer then ClearInspectPlayer() end
    InspectLater(1.5)
end

local function ResetInspect()
    inspect.current=nil
    inspect.tries={}
end

-- Forever does not reliably emit a dungeon-completion event for old Classic
-- instances. For known dungeons we can therefore use the complete required
-- boss set as an additional completion signal.
local KNOWN_BOSSES={
    ["Ragefire Chasm"]={
        ["Oggleflint"]=true, ["Taragaman the Hungerer"]=true,
        ["Jergosh the Invoker"]=true, ["Bazzalan"]=true,
    },
    ["Ragefireabgrund"]={
        ["Filthauge"]=true, ["Taragaman der Hungerleider"]=true,
        ["Jergosh der Herbeirufer"]=true, ["Bazzalan"]=true,
    },
}
-- Final bosses (lower-case name fragments, English and German). Killing one completes the run, whatever the dungeon is called:
-- the names are distinctive and some instances (wings) have several finals. Forever dungeons that are not vanilla are added here
-- as they are seen (Ruins of Lordaeron: last boss of the observed kill order, a best guess).
local FINAL_BOSSES={
    "edwin vancleef","mutanus","arugal","aku'mai","bazil thredd","thermaplugg","charlga","agathelos","amnennar","archaedas",
    "ukorz","theradras","eranikus","gandling","rivendare","totenschwur","dagran","wyrmthalax","drakkisath","alzzin","tortheldrin",
    "gordok","immol'thar","whitemane","weißmähne","herod","arcanist doan","thalnos","bazzalan","rath'mael",
    "kältebringer","dunkelmeister","wildformer",
}
local function IsFinalBoss(name)
    if type(name)~="string" or name=="" then return false end
    local low=name:lower()
    for _,frag in ipairs(FINAL_BOSSES) do
        if low:find(frag,1,true) then return true end
    end
    return false
end

local function BossSetComplete(run)
    for _,boss in ipairs(run and run.bosses or {}) do
        if boss.success and IsFinalBoss(boss.name) then return true end
    end
    local required=KNOWN_BOSSES[run and run.dungeon or ""]
    if not required then return false end
    local killed={}
    for _,boss in ipairs(run.bosses or {}) do
        if boss.success and boss.name then killed[boss.name]=true end
    end
    for name in pairs(required) do if not killed[name] then return false end end
    return true
end

-- "Fully cleared" = every boss of the dungeon is dead (a run is "completed" as soon as the main boss is dead, bosses may be skipped).
-- The list of bosses comes from the game's Encounter Journal when this client has it (checked inside the dungeon, entries are matched
-- by the encounter ID of ENCOUNTER_END), otherwise from KNOWN_BOSSES above (by name). Without a list a run is never "fully cleared".
local function JournalRoster()
    if not (EJ_SelectInstance and EJ_GetEncounterInfoByIndex and EJ_GetInstanceForMap and C_Map and C_Map.GetBestMapForUnit) then return nil end
    if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() then return nil end -- do not disturb an open journal
    local ok,res=pcall(function()
        local mapID=C_Map.GetBestMapForUnit("player")
        local jid=mapID and EJ_GetInstanceForMap(mapID)
        if not jid or jid==0 then return nil end
        EJ_SelectInstance(jid)
        local roster={ids={},names={},source="journal"}
        for i=1,30 do
            local name,_,_,_,_,_,dungeonEncounterID=EJ_GetEncounterInfoByIndex(i)
            if not name then break end
            roster.names[#roster.names+1]=name
            roster.ids[#roster.ids+1]=tonumber(dungeonEncounterID) or 0
        end
        if #roster.names==0 then return nil end
        return roster
    end)
    if ok then return res end
end

local rosterCache=setmetatable({},{__mode="k"}) -- run table -> roster (not saved; the journal is asked again after a reload)
local function RosterOf(run,allowJournal)
    if not run then return nil end
    local known=KNOWN_BOSSES[run.dungeon or ""]
    if known then
        local roster={ids={},names={},source="list"}
        for name in pairs(known) do roster.names[#roster.names+1]=name; roster.ids[#roster.ids+1]=0 end
        return roster
    end
    if rosterCache[run] then return rosterCache[run] end
    if allowJournal then
        local roster=JournalRoster()
        if roster then rosterCache[run]=roster; run.bossTotal=#roster.names; return roster end
    end
    return nil
end

local function IsFullClear(run,allowJournal)
    local roster=RosterOf(run,allowJournal)
    if not roster then return false end
    local ids,names={}, {}
    for _,b in ipairs(run.bosses or {}) do
        if b.success then
            if b.encounterID then ids[tonumber(b.encounterID) or 0]=true end
            if b.name then names[b.name]=true end
        end
    end
    for i,name in ipairs(roster.names) do
        local id=roster.ids[i] or 0
        if not ((id~=0 and ids[id]) or names[name]) then return false end
    end
    return true
end

local function MarkStoredRunComplete(run,source)
    if not run or run.completed then return false end
    run.completed=true
    run.completedAt=run.completedAt or run.left or time()
    run.completionSource=source or "boss_set"
    return true
end


-- One-time repair: runs that ended by logout before 1.0.2 stored 0 as their end gold (the game reports 0 while logging out),
-- which showed as losing all the gold. The real value is unknown, so it is stored as missing.
local function RepairLogoutGold()
    local db=MyCharForeverDB
    if not db or not db.dungeons then return end
    db.stats=db.stats or {}
    if db.stats.dungeonGoldRepaired then return end
    for _,r in ipairs(db.dungeons) do
        if r.exitReason=="logout" and r.goldEnd==0 and (tonumber(r.goldStart) or 0)>0 then r.goldEnd=nil end
    end
    db.stats.dungeonGoldRepaired=true
end

local function BackfillKnownDungeonCompletions()
    if not MyCharForeverDB or not MyCharForeverDB.dungeons then return end
    local added=0
    for _,run in ipairs(MyCharForeverDB.dungeons) do
        if not run.completed and BossSetComplete(run) then
            if MarkStoredRunComplete(run,"boss_set_retroactive") then added=added+1 end
        end
        if not run.fullClear and IsFullClear(run,false) then
            run.fullClear=true; run.fullClearAt=run.fullClearAt or run.completedAt or run.left
            if not run.completed then MarkStoredRunComplete(run,"full_clear_retroactive"); added=added+1 end
        end
    end
    if added>0 then
        MyCharForeverDB.stats=MyCharForeverDB.stats or {}
        local count=0
        for runIndex,run in ipairs(MyCharForeverDB.dungeons) do
            if run.completed then count=count+1 end
            if run.completed and MyCharForeverDB.levelActivity then
                local a=MyCharForeverDB.levelActivity[tonumber(run.levelEntered) or 0]
                if a and a.dungeons then
                    for _,ad in ipairs(a.dungeons) do
                        if ad.runIndex==runIndex or
                           (ad.dungeon==run.dungeon and not ad.completed and
                            (not ad.entered or not run.entered or math.abs(ad.entered-run.entered)<10)) then
                            ad.completed=true
                            ad.completedAt=run.completedAt
                            ad.completionSource=run.completionSource
                            break
                        end
                    end
                end
            end
        end
        MyCharForeverDB.stats.dungeonCompletions=count
    end
end

-- How long a break may last (reload, disconnect, crash) so that the same dungeon visit simply continues.
local RESUME_SECONDS=1800

-- Last time something was recorded in a run (used when the run was never closed, e.g. after a crash).
local function LastActivity(run)
    local t=run.entered or 0
    for _,b in ipairs(run.bosses or {}) do if (b.ended or 0)>t then t=b.ended end end
    for _,x in ipairs(run.loot or {}) do if (x.time or 0)>t then t=x.time end end
    return t
end

-- Is the group now (nearly) the same as in the stored run? Members do change now and then, so at least half of the smaller
-- group (without yourself) must be the same people. If either side is unknown (group data not ready yet) it counts as the same.
local function PartiesMatch(storedParty,otherParty,me)
    local stored,other,nStored,nOther={},{},0,0
    for name in pairs(storedParty or {}) do
        if name~=me then stored[name]=true; nStored=nStored+1 end
    end
    for name in pairs(otherParty or {}) do
        if name~=me and not other[name] then other[name]=true; nOther=nOther+1 end
    end
    if nStored==0 or nOther==0 then return true end
    local shared=0
    for name in pairs(other) do if stored[name] then shared=shared+1 end end
    return shared>=math.ceil(math.min(nStored,nOther)/2)
end

local function SameGroup(run)
    local me=UnitName and UnitName("player")
    local nowNames={}
    local n=GetNumGroupMembers and GetNumGroupMembers() or 0
    if not (IsInRaid and IsInRaid()) then
        for i=1,math.max(0,n-1) do
            local name=UnitExists and UnitExists("party"..i) and UnitName("party"..i) or nil
            if name and name~="" and name~=me then nowNames[name]=true end
        end
    end
    return PartiesMatch(run.party,nowNames,me)
end

-- Exit reasons after which the same visit may continue: logout/reload, and leaving the instance as a ghost after a wipe.
local RESUMABLE_EXIT={logout=true,ghost=true}

-- The newest stored run if it is the same instance and was only interrupted (logout/reload, ghost run after a wipe,
-- or never closed) less than RESUME_SECONDS ago. Leaving the instance on purpose (zone change) starts a new run as before.
local function ResumableRun(key,now)
    local list=MyCharForeverDB and MyCharForeverDB.dungeons
    local run=list and list[#list]
    if not run or run.key~=key then return nil end
    local since
    if run.left then
        if not RESUMABLE_EXIT[run.exitReason] then return nil end
        since=run.left
    else
        since=LastActivity(run)
    end
    if now-since<0 or now-since>RESUME_SECONDS then return nil end
    if not SameGroup(run) then return nil end
    return run,now-since
end

-- A resumed run whose instance ID (from a creature GUID) still has to be confirmed: {run,backup,uid,at}.
local pendingResume=nil
local UID_VERIFY_SECONDS=120 -- a wrong guess is only undone this long after the resume (later entries would be lost)
local ScheduleUIDScan -- defined further down

function MCF:StartDungeonRun(info,forceNew)
    if not MyCharForeverDB or not IsDungeon(info) then return end
    local key=CurrentKey(info)
    if currentRun and currentRun.key==key then return end

    local now=time()
    local old,gap
    if not forceNew then old,gap=ResumableRun(key,now) end
    if old then
        -- same visit continues: the break does not count as time in the dungeon
        pendingResume=nil
        if old.instanceUID then
            -- the group looked the same, but the instance ID decides: keep what is needed to undo this guess
            local backup={pausedSeconds=old.pausedSeconds,resumed=old.resumed,left=old.left,duration=old.duration,
                levelLeft=old.levelLeft,goldEnd=old.goldEnd,exitReason=old.exitReason,
                nb=#(old.bosses or {}),nl=#(old.loot or {}),party={}}
            for name,e in pairs(old.party or {}) do
                local c={}; for k,v in pairs(e) do c[k]=v end
                backup.party[name]=c
            end
            pendingResume={run=old,backup=backup,uid=old.instanceUID,at=now}
        end
        currentRun=old
        currentRun.pausedSeconds=(currentRun.pausedSeconds or 0)+gap
        currentRun.resumed=(currentRun.resumed or 0)+1
        currentRun.activeEncounter=nil
        currentRun.left=nil; currentRun.duration=nil; currentRun.levelLeft=nil; currentRun.goldEnd=nil; currentRun.exitReason=nil
        currentRun.bosses=currentRun.bosses or {}; currentRun.loot=currentRun.loot or {}; currentRun.party=currentRun.party or {}
        ResetInspect()
        CapturePartyRoster(currentRun)
        InspectLater(3)
        if ScheduleUIDScan then ScheduleUIDScan() end
        MCF:Notify(T("Dungeon continued - ")..tostring(currentRun.dungeon))
        return
    end
    pendingResume=nil
    currentRun={
        key=key,
        dungeon=info.name or "Unknown Dungeon",
        instanceID=info.instanceID,
        difficultyID=info.difficultyID,
        difficultyName=info.difficultyName,
        maxPlayers=info.maxPlayers,
        lfgDungeonID=info.lfgDungeonID,
        entered=now,
        left=nil,
        duration=nil,
        levelEntered=UnitLevel("player"),
        levelLeft=nil,
        deaths=0,
        goldStart=GetMoney() or 0,
        goldEnd=nil,
        completed=false,
        completionSource=nil,
        bosses={},
        loot={},
        party={},
    }
    ResetInspect()
    CapturePartyRoster(currentRun)
    table.insert(MyCharForeverDB.dungeons,currentRun)
    InspectLater(3)
    MyCharForeverDB.stats.dungeonVisits=(MyCharForeverDB.stats.dungeonVisits or 0)+1
    MCF:AddEvent("DUNGEON_ENTER",{dungeon=currentRun.dungeon,instanceID=currentRun.instanceID})
    if ScheduleUIDScan then ScheduleUIDScan() end
    MCF:Notify(T("Dungeon entered - ")..currentRun.dungeon)
end

function MCF:EndDungeonRun(reason)
    if not currentRun then return end
    CapturePartyRoster(currentRun)
    local now=time()
    currentRun.left=now
    currentRun.duration=math.max(0,now-(currentRun.entered or now)-(currentRun.pausedSeconds or 0))
    currentRun.levelLeft=UnitLevel("player")
    -- GetMoney() reports 0 while logging out; KnownMoney falls back to the last value the gold tracking saw
    currentRun.goldEnd=MCF:KnownMoney(currentRun.goldStart)
    currentRun.exitReason=reason or "left_instance"
    MCF:AddEvent("DUNGEON_LEAVE",{dungeon=currentRun.dungeon,duration=currentRun.duration,completed=currentRun.completed})
    currentRun=nil
    ResetInspect()
end

function MCF:MarkDungeonFullClear()
    local run=currentRun
    if not run or run.fullClear then return end
    run.fullClear=true
    run.fullClearAt=time()
    MCF:AddEvent("DUNGEON_FULLCLEAR",{dungeon=run.dungeon})
    MCF:Notify(T("Dungeon fully cleared - ")..tostring(run.dungeon))
    if not run.completed then MCF:MarkDungeonComplete("full_clear") end
end

function MCF:MarkDungeonComplete(source)
    if not currentRun or currentRun.completed then return end
    currentRun.completed=true
    currentRun.completedAt=time()
    currentRun.completionSource=source or "unknown"
    local a=MCF.GetLevelActivity and MCF:GetLevelActivity(currentRun.levelEntered)
    if a then
        for i=#a.dungeons,1,-1 do
            local d=a.dungeons[i]
            if d.runIndex==#MyCharForeverDB.dungeons or (d.dungeon==currentRun.dungeon and not d.completed) then
                d.completed=true; d.completedAt=currentRun.completedAt; break
            end
        end
    end
    MyCharForeverDB.stats.dungeonCompletions=(MyCharForeverDB.stats.dungeonCompletions or 0)+1
    MCF:AddEvent("DUNGEON_COMPLETE",{dungeon=currentRun.dungeon,source=currentRun.completionSource})
    MCF:Notify(T("Dungeon completion detected - ")..currentRun.dungeon)
    -- Settings "At dungeon completion" (on by default; the switch existed but did nothing before 1.0.2)
    local st=MyCharForeverDB.settings
    if st and st.screenshotDungeon~=false and MCF.TakeChronicleScreenshot and C_Timer and C_Timer.After then
        C_Timer.After(2,function() MCF:TakeChronicleScreenshot("DUNGEON_COMPLETE",true) end)
    end
end


local function ItemIDFromLink(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end

local function FindBossName(run,encounterID)
    if not run then return nil end
    if encounterID then
        for i=#(run.bosses or {}),1,-1 do
            local b=run.bosses[i]
            if b.encounterID==encounterID then return b.name end
        end
    end
    local now=time()
    for i=#(run.bosses or {}),1,-1 do
        local b=run.bosses[i]
        if b.success and b.ended and now-b.ended<=120 then return b.name end
    end
end

local function PlayerOwnsLoot(playerName)
    if not playerName or playerName=="" then return false end
    local me=UnitName("player")
    if not me or me=="" then return false end
    local short=playerName:match("^([^%-]+)") or playerName
    return short==me
end

local function ItemQuality(itemLink,itemID)
    -- The colour of the link is known immediately; GetItemInfo returns nothing for items that are not cached yet
    -- (that left the quality empty and the website showed such items as white).
    local W=MCF.WorldDrops
    if W and W.QualityOf and type(itemLink)=="string" then
        local q=W.QualityOf(itemLink)
        if type(q)=="number" then return q end
    end
    if GetItemInfo then
        local _,_,quality=GetItemInfo(itemLink or itemID)
        if type(quality)=="number" then return quality end
    end
    if C_Item and C_Item.GetItemQualityByID and itemID then
        local ok,quality=pcall(C_Item.GetItemQualityByID,itemID)
        if ok and type(quality)=="number" then return quality end
    end
end

-- Own item of the run: it becomes a journal entry once (ItemJournal.lua decides whether it is good enough).
local function JournalMine(x)
    if not x or not x.isMine or x.journaled or not currentRun then return end
    if x.quality==nil then x.quality=ItemQuality(x.itemLink,x.itemID) end
    x.journaled=true
    if MCF.OnDungeonLootMine then pcall(MCF.OnDungeonLootMine,MCF,x,currentRun.dungeon) end
end

local LOOT_CHAT_WINDOW=120
local lootOpenStamp=0   -- counts LOOT_OPENED events: slots of ONE opening are separate copies, a later opening shows the same pending items again
local function RecordDungeonLoot(itemLink,quantity,playerName,encounterID,source)
    if not currentRun or not itemLink then return end
    currentRun.loot=currentRun.loot or {}
    quantity=tonumber(quantity) or 1
    local now=time()
    local itemID=ItemIDFromLink(itemLink)
    local mine=PlayerOwnsLoot(playerName)
    -- The loot window and the chat line report the same item with differently written links, so items are
    -- compared by itemID. A window entry and a chat entry belong together; two entries from the SAME source
    -- are two copies of the item. The chat line can come well after the window (after a roll) and the other
    -- way round, so this pairing looks back LOOT_PAIR_WINDOW seconds.
    local chan=(source=="LOOT_OPENED" and "openSeen") or (source=="CHAT_MSG_LOOT" and "chatSeen") or nil
    local other=(chan=="openSeen" and "chatSeen") or (chan=="chatSeen" and "openSeen") or nil
    if chan and itemID then
        for i=#currentRun.loot,1,-1 do
            local x=currentRun.loot[i]
            if now-(x.time or 0)>LOOT_CHAT_WINDOW then break end
            if (x.itemID or ItemIDFromLink(x.itemLink))==itemID and x[other] and not x[chan]
              and (not playerName or not x.player or x.player==playerName) then
                x[chan]=true
                if playerName then x.player=playerName end
                if mine then x.isMine=true end
                if x.quality==nil then x.quality=ItemQuality(itemLink,itemID) end
                if x.itemLevel==nil then x.itemLevel=ItemLevelOf(itemLink) end
                JournalMine(x)
                return x
            end
        end
    end
    -- Opening the same corpse again while a rolled item is still pending shows it again: that is the same entry, not a new copy.
    -- (A second slot with the same item inside ONE opening is a real second copy and gets its own entry below.)
    if source=="LOOT_OPENED" and itemID then
        for i=#currentRun.loot,1,-1 do
            local x=currentRun.loot[i]
            if now-(x.time or 0)>600 then break end
            if (x.itemID or ItemIDFromLink(x.itemLink))==itemID and x.openSeen and not x.rollDone and not x.received and not x.chatSeen
              and x.openStamp~=lootOpenStamp then
                x.openStamp=lootOpenStamp
                return x
            end
        end
    end
    for i=#currentRun.loot,1,-1 do
        local x=currentRun.loot[i]
        if now-(x.time or 0)>8 then break end
        if ((itemID and (x.itemID or ItemIDFromLink(x.itemLink))==itemID) or x.itemLink==itemLink) and (not playerName or not x.player or x.player==playerName)
          and (not encounterID or not x.encounterID or x.encounterID==encounterID)
          and not (source=="LOOT_OPENED" and x.openStamp==lootOpenStamp) then
            -- LOOT_OPENED often arrives without ownership/source information.
            -- Enrich that existing entry when a more specific event follows.
            if playerName then x.player=playerName end
            if mine then x.isMine=true end
            if encounterID then x.encounterID=encounterID end
            if not x.boss then x.boss=FindBossName(currentRun,encounterID) end
            if source=="ENCOUNTER_LOOT_RECEIVED" then x.source=source end
            if x.quality==nil then x.quality=ItemQuality(itemLink,itemID) end
            if x.itemLevel==nil then x.itemLevel=ItemLevelOf(itemLink) end
            JournalMine(x)
            return x
        end
    end
    local entry={
        time=now,itemLink=itemLink,itemID=itemID,quantity=quantity,itemLevel=ItemLevelOf(itemLink),
        player=playerName,isMine=mine or nil,quality=ItemQuality(itemLink,itemID),
        encounterID=encounterID,boss=FindBossName(currentRun,encounterID),source=source,
    }
    if chan then entry[chan]=true end
    if source=="LOOT_OPENED" then entry.openStamp=lootOpenStamp end
    table.insert(currentRun.loot,entry)
    JournalMine(entry)
    MCF:AddEvent("DUNGEON_LOOT",{dungeon=currentRun.dungeon,boss=entry.boss,itemID=itemID,itemLink=itemLink,quantity=quantity,player=playerName,isMine=entry.isMine,quality=entry.quality,source=source})
    return entry
end

local function LootFormatPattern(fmt)
    if type(fmt)~="string" or fmt=="" then return nil end
    -- Plain (%s, %d) and positional (%1$s) placeholders.
    fmt=fmt:gsub("%%%d%$s","\1"):gsub("%%%d%$d","\2"):gsub("%%s","\1"):gsub("%%d","\2")
    fmt=fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])","%%%1")
    fmt=fmt:gsub("\1",".-"):gsub("\2","%%d+")
    return "^"..fmt.."$"
end

MCF.LootFormatPattern=LootFormatPattern -- shared with WorldDrops

local SELF_LOOT_PATTERNS={}
for _,key in ipairs({"LOOT_ITEM_SELF","LOOT_ITEM_SELF_MULTIPLE","LOOT_ITEM_PUSHED_SELF","LOOT_ITEM_PUSHED_SELF_MULTIPLE"}) do
    local pat=LootFormatPattern(_G[key])
    if pat then SELF_LOOT_PATTERNS[#SELF_LOOT_PATTERNS+1]=pat end
end

local function MarkPersonalLootFromChat(message)
    if not currentRun or type(message)~="string" then return end
    local isSelf=false
    for _,pat in ipairs(SELF_LOOT_PATTERNS) do
        if message:match(pat) then isSelf=true break end
    end
    if not isSelf then return end
    -- the full link with its colour code, the same text the loot events deliver (a bare |H link never equals those)
    local link=message:match("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h.-|h|r)") or message:match("(|Hitem:.-|h.-|h)")
    if not link then return end
    local now=time()
    local me=UnitName("player")
    local linkID=ItemIDFromLink(link)
    for i=#(currentRun.loot or {}),1,-1 do
        local x=currentRun.loot[i]
        -- A rolled item can lie in the loot window for a minute before its winner gets it, so the chat line may come late.
        if now-(x.time or 0)>LOOT_CHAT_WINDOW then break end
        if linkID and (x.itemID or ItemIDFromLink(x.itemLink))==linkID and not x.chatSeen and (not x.isMine or (x.rollDone and not x.received)) then
            x.chatSeen=true
            x.received=true
            x.isMine=true
            x.player=me or x.player
            if x.quality==nil then x.quality=ItemQuality(x.itemLink,x.itemID) end
            JournalMine(x)
            return
        end
    end
    -- If chat arrives without a usable LOOT_OPENED entry, keep the personal item anyway.
    RecordDungeonLoot(link,1,me,nil,"CHAT_MSG_LOOT")
end

-- ---------------------------------------------------------------------------------------------------------------
-- Loot rolls of the group (need / greed / disenchant / pass), saved per item in dungeons[].loot[]:
--   rolls = { {player=, choice="NEED"|"GREED"|"DISENCHANT"|"PASS", roll=<number or nil>}, ... }
--   roll / rollType = the winner's roll and choice, player = the winner, rollDone = true, rollAllPassed = true when nobody wanted it.
-- Source: the loot chat lines (the game's own format strings, so they work in every client language). Only inside a dungeon run.
-- ---------------------------------------------------------------------------------------------------------------
local ROLL_LINES={
    -- kind: SELECT (a choice was made) / ROLL (number rolled) / WON / ALLPASSED. self=true: the line has no player name ("You ...").
    -- Order matters: the long forms must come before the short ones whose "%s" would swallow them.
    {"LOOT_ROLL_YOU_WON_NO_SPAM_NEED","WON","NEED",true},{"LOOT_ROLL_YOU_WON_NO_SPAM_GREED","WON","GREED",true},{"LOOT_ROLL_YOU_WON_NO_SPAM_DE","WON","DISENCHANT",true},
    {"LOOT_ROLL_WON_NO_SPAM_NEED","WON","NEED",false},{"LOOT_ROLL_WON_NO_SPAM_GREED","WON","GREED",false},{"LOOT_ROLL_WON_NO_SPAM_DE","WON","DISENCHANT",false},
    {"LOOT_ROLL_YOU_WON","WON",nil,true},{"LOOT_ROLL_WON","WON",nil,false},
    {"LOOT_ROLL_ALL_PASSED","ALLPASSED",nil,false},
    {"LOOT_ROLL_ROLLED_NEED","ROLL","NEED",false},{"LOOT_ROLL_ROLLED_GREED","ROLL","GREED",false},{"LOOT_ROLL_ROLLED_DE","ROLL","DISENCHANT",false},
    {"LOOT_ROLL_NEED_SELF","SELECT","NEED",true},{"LOOT_ROLL_NEED","SELECT","NEED",false},
    {"LOOT_ROLL_GREED_SELF","SELECT","GREED",true},{"LOOT_ROLL_GREED","SELECT","GREED",false},
    {"LOOT_ROLL_DISENCHANT_SELF","SELECT","DISENCHANT",true},{"LOOT_ROLL_DISENCHANT","SELECT","DISENCHANT",false},
    {"LOOT_ROLL_PASSED_SELF_AUTO","SELECT","PASS",true},{"LOOT_ROLL_PASSED_AUTO_FEMALE","SELECT","PASS",false},{"LOOT_ROLL_PASSED_AUTO","SELECT","PASS",false},
    {"LOOT_ROLL_PASSED_SELF","SELECT","PASS",true},{"LOOT_ROLL_PASSED","SELECT","PASS",false},
}
local ROLL_MAX_ENTRIES=10
local ROLL_SESSION_SECONDS=900

-- Game format string -> Lua pattern; also returns the kinds of the captures in order ("s" text, "d" number).
local function RollLinePattern(fmt)
    if type(fmt)~="string" or fmt=="" then return nil end
    local caps={}
    fmt=fmt:gsub("%%%d?%$?([sd])",function(kind) caps[#caps+1]=kind; return kind=="d" and "\2" or "\1" end)
    fmt=fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])","%%%1")
    fmt=fmt:gsub("\1","(.-)"):gsub("\2","(%%d+)")
    return "^"..fmt.."$",caps
end

local rollMatchers
local function RollMatchers()
    if rollMatchers then return rollMatchers end
    rollMatchers={}
    for _,d in ipairs(ROLL_LINES) do
        local pat,caps=RollLinePattern(_G[d[1]])
        if pat then rollMatchers[#rollMatchers+1]={pat=pat,caps=caps,kind=d[2],choice=d[3],self=d[4]} end
    end
    return rollMatchers
end

-- A group loot roll is a number from 1 to 100; anything else is not a roll (one place for this rule: parser, loot history, windows).
function MCF.ValidRoll(v)
    local n=tonumber(v)
    if n and n>=1 and n<=100 and n==math.floor(n) then return n end
    return nil
end

-- The game names the same player in two forms ("Name" for yourself, "Name Surname" in roll lines): the own character always
-- counts as UnitName("player"), so it is never listed twice. Used for new data (RollEntry/FinishRoll) and for stored rolls (window).
function MCF.CanonPlayer(name)
    if type(name)~="string" then return name end
    local me=UnitName and UnitName("player")
    if me and me~="" and (name==me or name:sub(1,#me+1)==me.." " or name:sub(1,#me+1)==me.."-") then return me end
    return name
end

-- One chat line -> {kind,choice,player,link,roll} or nil. Pure function (SelfTest/simulation can call it).
local function ParseRollLine(msg)
    if type(msg)~="string" then return nil end
    for _,m in ipairs(RollMatchers()) do
        local c={msg:match(m.pat)}
        if c[1]~=nil then
            local r={kind=m.kind,choice=m.choice}
            for i,kind in ipairs(m.caps) do
                local v=c[i]
                if kind=="d" then
                    local n=MCF.ValidRoll(v)
                    if n then r.roll=n
                    else
                        -- unexpected number (not a 1-100 roll): keep the raw line for diagnosis
                        pcall(function()
                            if MyCharForeverDB then
                                local d=MyCharForeverDB.rollDebug or {}
                                MyCharForeverDB.rollDebug=d
                                if #d<10 then d[#d+1]=msg end
                            end
                        end)
                    end
                elseif type(v)=="string" and v:find("|Hitem:",1,true) then r.link=r.link or v
                elseif v and v~="" then r.player=v end
            end
            if m.self then r.player=UnitName and UnitName("player") or nil end
            if r.link then return r end
            return nil
        end
    end
    return nil
end
MCF.ParseRollLine=ParseRollLine

local rollBook={} -- [itemID] = list of open sessions {t=,link=,list={},by={}}

local function RollSessionFor(itemID,link,player,needsNew)
    local now=time()
    local list=rollBook[itemID]
    if not list then list={}; rollBook[itemID]=list end
    for i=#list,1,-1 do if now-list[i].t>ROLL_SESSION_SECONDS then table.remove(list,i) end end
    for i=#list,1,-1 do
        local sess=list[i]
        if not (player and needsNew and needsNew(sess.by[player])) then return sess end
    end
    local sess={t=now,link=link,list={},by={}}
    list[#list+1]=sess
    return sess
end

local function RollEntry(sess,player)
    player=MCF.CanonPlayer(player)
    local e=sess.by[player]
    if not e then
        e={player=player}
        sess.by[player]=e
        if #sess.list<ROLL_MAX_ENTRIES then sess.list[#sess.list+1]=e end
    end
    return e
end

local function FindLootEntryForRoll(itemID)
    local now=time()
    for i=#(currentRun.loot or {}),1,-1 do
        local x=currentRun.loot[i]
        if now-(x.time or 0)>1800 then break end
        if not x.rollDone and (x.itemID or ItemIDFromLink(x.itemLink))==itemID then return x end
    end
end

local function FinishRoll(itemID,sess,winner,choice,roll)
    winner=MCF.CanonPlayer(winner)
    local list=rollBook[itemID]
    if list then for i=#list,1,-1 do if list[i]==sess then table.remove(list,i) end end end
    local x=FindLootEntryForRoll(itemID)
    if not x and winner then x=RecordDungeonLoot(sess.link,1,winner,nil,"LOOT_ROLL") end
    if not x then return end
    local copy={}
    for _,e in ipairs(sess.list) do copy[#copy+1]={player=e.player,choice=e.choice,roll=e.roll} end
    x.rolls=copy
    x.rollDone=true
    if winner then
        local w=sess.by[winner]
        x.player=winner
        if PlayerOwnsLoot(winner) then x.isMine=true end
        x.rollType=choice or (w and w.choice) or nil
        x.roll=roll or (w and w.roll) or nil
        JournalMine(x)
    else
        x.rollAllPassed=true
    end
end

local function TrackRollLine(msg)
    if not currentRun then return end
    local r=ParseRollLine(msg)
    if not r then return end
    local itemID=ItemIDFromLink(r.link)
    if not itemID then return end
    r.player=MCF.CanonPlayer(r.player)
    if r.kind=="SELECT" and r.player then
        -- a second choice of the same player for the same item = the next copy of the item
        local sess=RollSessionFor(itemID,r.link,r.player,function(e) return e and e.choice end)
        RollEntry(sess,r.player).choice=r.choice
    elseif r.kind=="ROLL" and r.player then
        local sess=RollSessionFor(itemID,r.link,r.player,function(e) return e and e.roll end)
        local e=RollEntry(sess,r.player)
        e.choice=r.choice or e.choice
        e.roll=r.roll
    elseif r.kind=="WON" and r.player then
        local sess=RollSessionFor(itemID,r.link)
        FinishRoll(itemID,sess,r.player,r.choice,r.roll)
    elseif r.kind=="ALLPASSED" then
        local sess=RollSessionFor(itemID,r.link)
        FinishRoll(itemID,sess,nil)
    end
end


-- Second source for rolls: the game's own loot history (no chat needed, independent of chat tabs/filters).
-- Uses the C_LootHistory API (GetNumItems/GetItem/GetPlayerInfo) when this client has it; every call is guarded.
local function MCFIsSecret(v) return issecretvalue and issecretvalue(v) or false end
local ROLL_TYPE_NAME={[0]="PASS",[1]="NEED",[2]="GREED",[3]="DISENCHANT"}
local historyDone={} -- finished history items already booked, key = rollID or link
local function SyncLootHistory()
    if not currentRun then return end
    local H=C_LootHistory
    if not (H and H.GetNumItems and H.GetItem and H.GetPlayerInfo) then return end
    for idx=1,(H.GetNumItems() or 0) do
        local rollID,link,numPlayers,isDone,winnerIdx=H.GetItem(idx)
        if type(link)=="string" and not MCFIsSecret(link) then
            local itemID=ItemIDFromLink(link)
            local key=tostring(rollID or link).."|"..tostring(itemID)
            if itemID and not historyDone[key] then
                local sess=RollSessionFor(itemID,link)
                local winner,wchoice,wroll
                for pi=1,(numPlayers or 0) do
                    local name,_,rollType,roll,isWinner,isMe=H.GetPlayerInfo(idx,pi)
                    if isMe and UnitName then name=UnitName("player") end
                    if type(name)=="string" and not MCFIsSecret(name) then
                        local e=RollEntry(sess,name)
                        local ch=ROLL_TYPE_NAME[tonumber(rollType)]
                        if ch then e.choice=ch end
                        local n=MCF.ValidRoll(roll)
                        if n then e.roll=n end
                        if isWinner or pi==winnerIdx then winner,wchoice,wroll=name,e.choice,e.roll end
                    end
                end
                if isDone then
                    historyDone[key]=true
                    FinishRoll(itemID,sess,winner,wchoice,wroll)
                end
            end
        end
    end
end


-- ---------------------------------------------------------------------------------------------------------------
-- Instance ID: the creature GUID is Creature-0-<server>-<map>-<instance>-<npc>-<spawn>. <map>-<instance> is the same for every
-- creature of one dungeon visit and changes when the instance was reset, so it tells visits of the same dungeon apart
-- (seen in the game: 9 before and 10 after "reset instances"). Secret values (in combat) are skipped; the scan simply retries.
local function InstanceUIDOf(guid)
    if type(guid)~="string" or MCFIsSecret(guid) then return nil end
    local map,uid=guid:match("^%a+%-%d+%-%d+%-(%d+)%-(%d+)%-")
    if not map then return nil end
    return map.."-"..uid
end

-- The resumed run was a wrong guess (another instance): give it back as it was and continue in a new run.
local function RevertResume(pr,uid)
    local old,b=pr.run,pr.backup
    local movedBosses,movedLoot={},{}
    for i=b.nb+1,#old.bosses do movedBosses[#movedBosses+1]=old.bosses[i] end
    for i=#old.bosses,b.nb+1,-1 do table.remove(old.bosses,i) end
    for i=b.nl+1,#old.loot do movedLoot[#movedLoot+1]=old.loot[i] end
    for i=#old.loot,b.nl+1,-1 do table.remove(old.loot,i) end
    old.pausedSeconds=b.pausedSeconds; old.resumed=b.resumed; old.left=b.left; old.duration=b.duration
    old.levelLeft=b.levelLeft; old.goldEnd=b.goldEnd; old.exitReason=b.exitReason; old.party=b.party
    old.activeEncounter=nil
    currentRun=nil
    ResetInspect()
    MCF:StartDungeonRun(SafeInstanceInfo(),true)
    if currentRun then
        currentRun.instanceUID=uid
        for _,x in ipairs(movedBosses) do currentRun.bosses[#currentRun.bosses+1]=x end
        for _,x in ipairs(movedLoot) do currentRun.loot[#currentRun.loot+1]=x end
    end
end

local function ApplyInstanceUID(uid)
    local run=currentRun
    if not run then return end
    local pr=pendingResume
    if pr and pr.run==run then
        pendingResume=nil
        if time()-pr.at<=UID_VERIFY_SECONDS and pr.uid~=uid then RevertResume(pr,uid); return end
    end
    if not run.instanceUID then run.instanceUID=uid end
end

local UID_UNITS={"target","mouseover","focus","boss1","boss2","boss3","boss4","boss5"}
local function ScanInstanceUID()
    local run=currentRun
    if not run then return end
    if run.instanceUID and not (pendingResume and pendingResume.run==run) then return end
    local function try(unit)
        if UnitExists and UnitExists(unit) then
            local uid=InstanceUIDOf(UnitGUID(unit))
            if uid then ApplyInstanceUID(uid); return true end
        end
    end
    for _,u in ipairs(UID_UNITS) do if try(u) then return end end
    for i=1,40 do if try("nameplate"..i) then return end end
end

ScheduleUIDScan=function()
    for _,d in ipairs({1,3,6,10,20,40,80}) do
        C_Timer.After(d,function() pcall(ScanInstanceUID) end)
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- Merging runs that were already stored as several runs (made before runs could be continued): /mcf mergeruns.
-- Candidates are neighbouring runs in the list: same dungeon, the earlier one ended by reload/logout/ghost run or never closed,
-- the next one started less than RESUME_SECONDS later and the group is (nearly) the same. Nothing is changed without a confirmation.
-- Instance ID decides when both runs have one; otherwise the group comparison.
local function SameInstance(a,b,me)
    if a.instanceUID and b.instanceUID then return a.instanceUID==b.instanceUID end
    return PartiesMatch(a.party,b.party,me)
end

local function MergeCandidates()
    local list=MyCharForeverDB and MyCharForeverDB.dungeons or {}
    local me=UnitName and UnitName("player")
    local groups,cur={},nil
    for i=1,#list-1 do
        local a,b=list[i],list[i+1]
        local ok=false
        if a.key and a.key==b.key then
            local since
            if a.left then
                if RESUMABLE_EXIT[a.exitReason] then since=a.left end
            else since=LastActivity(a) end
            local gap=since and ((b.entered or 0)-since) or nil
            ok=gap~=nil and gap>=0 and gap<=RESUME_SECONDS and SameInstance(a,b,me)
        end
        if ok then
            if not cur then cur={i}; groups[#groups+1]=cur end
            cur[#cur+1]=i+1
        else cur=nil end
    end
    return groups
end

local function MergeInto(a,b)
    local gap=math.max(0,(b.entered or 0)-(a.left or LastActivity(a)))
    a.pausedSeconds=(a.pausedSeconds or 0)+(b.pausedSeconds or 0)+gap
    a.resumed=(a.resumed or 0)+(b.resumed or 0)+1
    a.deaths=(tonumber(a.deaths) or 0)+(tonumber(b.deaths) or 0)
    for _,x in ipairs(b.bosses or {}) do a.bosses[#a.bosses+1]=x end
    a.loot=a.loot or {}
    for _,x in ipairs(b.loot or {}) do a.loot[#a.loot+1]=x end
    table.sort(a.loot,function(x,y) return (x.time or 0)<(y.time or 0) end)
    a.party=a.party or {}
    for name,e in pairs(b.party or {}) do
        local m=a.party[name]
        if not m then a.party[name]=e
        else
            m.lastSeen=math.max(m.lastSeen or 0,e.lastSeen or 0)
            if e.level and e.level>0 then m.level=e.level end
            if m.averageItemLevel==nil then m.averageItemLevel=e.averageItemLevel end
        end
    end
    if b.completed and not a.completed then
        a.completed=true; a.completedAt=b.completedAt; a.completionSource=b.completionSource
    end
    if b.fullClear and not a.fullClear then
        a.fullClear=true; a.fullClearAt=b.fullClearAt
    end
    a.instanceUID=a.instanceUID or b.instanceUID
    a.left=b.left; a.exitReason=b.exitReason; a.levelLeft=b.levelLeft; a.goldEnd=b.goldEnd
    if a.left then a.duration=math.max(0,a.left-(a.entered or a.left)-a.pausedSeconds) else a.duration=nil end
end

local function MergeStoredRuns()
    local list=MyCharForeverDB and MyCharForeverDB.dungeons
    if not list then return 0 end
    local groups,merged=MergeCandidates(),0
    for g=#groups,1,-1 do
        local idx=groups[g]
        for k=2,#idx do
            MergeInto(list[idx[1]],list[idx[k]])
            merged=merged+1
        end
        for k=#idx,2,-1 do table.remove(list,idx[k]) end
    end
    local completions=0
    for _,r in ipairs(list) do if r.completed then completions=completions+1 end end
    MyCharForeverDB.stats=MyCharForeverDB.stats or {}
    MyCharForeverDB.stats.dungeonVisits=#list
    MyCharForeverDB.stats.dungeonCompletions=completions
    return merged
end

StaticPopupDialogs["MYCHARFOREVER_MERGE_DUNGEON_RUNS"]={
    text="%s",
    button1=YES,
    button2=NO,
    OnAccept=function()
        local ok,n=pcall(MergeStoredRuns)
        local de=MCF:GetLanguage()=="deDE"
        print("|cff00ccffMyCharForever|r: "..(ok and (de and ("Zusammengeführt: "..tostring(n).." Run(s) wurden angehängt.") or ("Merged: "..tostring(n).." run(s) were added to the one before.")) or tostring(n)))
        if ok and MCF.RefreshUI then pcall(MCF.RefreshUI,MCF) end
    end,
    timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
}

MCF:AddCommand{group="test", usage="/mcf bossroster", key="bossroster",
  de="Zeigt, woher die Bossliste des aktuellen Dungeons stammt (Abenteuerführer oder feste Liste)",
  en="Shows where the boss list of the current dungeon comes from (Encounter Journal or fixed list)",
  run=function()
    local de=MCF:GetLanguage()=="deDE"
    local function say(t) print("|cff00ccffMyCharForever|r: "..t) end
    say("Encounter Journal API: "..((EJ_SelectInstance and EJ_GetEncounterInfoByIndex and EJ_GetInstanceForMap) and "yes" or "no"))
    if not currentRun then say(de and "Kein laufender Dungeon-Run." or "No dungeon run in progress."); return end
    local roster=RosterOf(currentRun,true)
    if not roster then say(de and "Keine Bossliste bekannt: Dieser Dungeon kann nicht als komplett geräumt gelten." or "No boss list known: this dungeon cannot count as fully cleared."); return end
    say((de and "Bossliste (Quelle: " or "Boss list (source: ")..roster.source.."): "..table.concat(roster.names,", "))
    say((de and "Besiegt: " or "Defeated: ")..tostring(IsFullClear(currentRun,false) and (de and "alle - komplett geräumt" or "all - fully cleared") or (de and "noch nicht alle" or "not all yet")))
  end}

MCF:AddCommand{group="main", usage="/mcf mergeruns", key="mergeruns",
  de="Dungeon-Runs zusammenführen, die durch Reload/Disconnect getrennt wurden (fragt vorher nach)",
  en="Merge dungeon runs that were split by a reload or disconnect (asks first)",
  run=function()
    local de=MCF:GetLanguage()=="deDE"
    local groups=MergeCandidates()
    if #groups==0 then
        print("|cff00ccffMyCharForever|r: "..(de and "Keine getrennten Runs gefunden." or "No split runs found."))
        return
    end
    local runs=0
    for _,g in ipairs(groups) do runs=runs+#g-1 end
    local text=de and ("%d zusammengehörende Dungeon-Besuche gefunden (%d Runs würden an den vorherigen angehängt). Zusammenführen? Das kann nicht rückgängig gemacht werden.")
        or ("%d split dungeon visits found (%d runs would be added to the one before). Merge them? This cannot be undone.")
    StaticPopup_Show("MYCHARFOREVER_MERGE_DUNGEON_RUNS",MCF.Branded(string.format(text,#groups,runs)))
  end}

local function RecheckInstance()
    if not MyCharForeverDB then return end
    local inInstance, instanceType=IsInInstance()
    local info=SafeInstanceInfo()
    local isDungeon=inInstance and instanceType=="party" and IsDungeon(info)
    local key=isDungeon and CurrentKey(info) or nil

    if currentRun and (not isDungeon or currentRun.key~=key) then
        -- released after a wipe: the ghost is teleported out of the instance and runs back, that is still the same visit
        local ghost=UnitIsGhost and UnitIsGhost("player")
        if MCFIsSecret(ghost) then ghost=nil end
        MCF:EndDungeonRun(ghost and "ghost" or "zone_change")
    end
    if isDungeon and (not currentRun or currentRun.key~=key) then
        MCF:StartDungeonRun(info)
    end
    lastInstanceKey=key
end

function MCF:GetCurrentDungeonRun()
    return currentRun
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_DEAD")
-- These may not all fire on every Forever/Classic build. RegisterEvent is safe;
-- the recorder treats them as extra evidence, not as the only source.
pcall(function() f:RegisterEvent("ENCOUNTER_START") end)
pcall(function() f:RegisterEvent("ENCOUNTER_END") end)
pcall(function() f:RegisterEvent("CHALLENGE_MODE_COMPLETED") end)
pcall(function() f:RegisterEvent("LFG_COMPLETION_REWARD") end)
pcall(function() f:RegisterEvent("ENCOUNTER_LOOT_RECEIVED") end)
pcall(function() f:RegisterEvent("LOOT_OPENED") end)
pcall(function() f:RegisterEvent("CHAT_MSG_LOOT") end)
pcall(function() f:RegisterEvent("PLAYER_TARGET_CHANGED") end)
pcall(function() f:RegisterEvent("UPDATE_MOUSEOVER_UNIT") end)
pcall(function() f:RegisterEvent("NAME_PLATE_UNIT_ADDED") end)
pcall(function() f:RegisterEvent("LOOT_HISTORY_FULL_UPDATE") end)
pcall(function() f:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED") end)
pcall(function() f:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE") end)
pcall(function() f:RegisterEvent("GROUP_ROSTER_UPDATE") end)
pcall(function() f:RegisterEvent("INSPECT_READY") end)

f:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
        if event=="PLAYER_ENTERING_WORLD" then C_Timer.After(2,BackfillKnownDungeonCompletions); C_Timer.After(2,RepairLogoutGold) end
        C_Timer.After(1,RecheckInstance)
    elseif event=="PLAYER_DEAD" then
        if currentRun then currentRun.deaths=(currentRun.deaths or 0)+1 end
    elseif event=="INSPECT_READY" then
        OnInspectReady((...))
    elseif event=="GROUP_ROSTER_UPDATE" then
        if currentRun then C_Timer.After(0.5,function() CapturePartyRoster(currentRun); InspectLater(2) end) end
    elseif event=="ENCOUNTER_START" then
        if currentRun then
            local encounterID, encounterName, difficultyID, groupSize=...
            currentRun.activeEncounter={id=encounterID,name=encounterName,started=time()}
        end
    elseif event=="ENCOUNTER_END" then
        if currentRun then
            local encounterID, encounterName, difficultyID, groupSize, success=...
            local boss={
                encounterID=encounterID,name=encounterName,
                ended=time(),success=(success==1),
            }
            if currentRun.activeEncounter and currentRun.activeEncounter.id==encounterID then
                boss.started=currentRun.activeEncounter.started
                boss.duration=math.max(0,boss.ended-(boss.started or boss.ended))
                if boss.duration<=0 then boss.duration=nil end -- no real fight time known: stored as missing, not as 0
            end
            table.insert(currentRun.bosses,boss)
            local a=MCF.GetLevelActivity and MCF:GetLevelActivity(UnitLevel("player"))
            if a then table.insert(a.bosses,{
                time=boss.ended,dungeon=currentRun.dungeon,boss=encounterName,
                encounterID=encounterID,success=(success==1),duration=boss.duration
            }) end
            currentRun.activeEncounter=nil
            MCF:AddEvent("DUNGEON_BOSS",{dungeon=currentRun.dungeon,boss=encounterName,success=(success==1)})
            if success==1 and BossSetComplete(currentRun) then
                MCF:MarkDungeonComplete("boss_set")
            end
            if success==1 and not currentRun.fullClear and IsFullClear(currentRun,true) then
                MCF:MarkDungeonFullClear()
            end
        end
    elseif event=="ENCOUNTER_LOOT_RECEIVED" then
        local encounterID,itemID,itemLink,quantity,playerName,className=...
        RecordDungeonLoot(itemLink,quantity,playerName,encounterID,"ENCOUNTER_LOOT_RECEIVED")
    elseif event=="CHAT_MSG_LOOT" then
        local message=...
        if type(message)=="string" and not (issecretvalue and issecretvalue(message)) then
            MarkPersonalLootFromChat(message)
            local ok,err=pcall(TrackRollLine,message)
            if not ok and MCF.LogError then pcall(MCF.LogError,MCF,"Dungeons roll tracker: "..tostring(err)) end
        end
    elseif event=="PLAYER_TARGET_CHANGED" or event=="UPDATE_MOUSEOVER_UNIT" or event=="NAME_PLATE_UNIT_ADDED" then
        if currentRun then pcall(ScanInstanceUID) end
    elseif event=="LOOT_HISTORY_FULL_UPDATE" or event=="LOOT_HISTORY_ROLL_CHANGED" or event=="LOOT_HISTORY_ROLL_COMPLETE" then
        local ok,err=pcall(SyncLootHistory)
        if not ok and MCF.LogError then pcall(MCF.LogError,MCF,"Dungeons loot history: "..tostring(err)) end
    elseif event=="LOOT_OPENED" then
        lootOpenStamp=lootOpenStamp+1
        if currentRun and GetNumLootItems and GetLootSlotLink then
            for slot=1,(GetNumLootItems() or 0) do
                local link=GetLootSlotLink(slot)
                if link then
                    local quantity=1
                    if GetLootSlotInfo then
                        local _,_,qty=GetLootSlotInfo(slot)
                        quantity=qty or 1
                    end
                    RecordDungeonLoot(link,quantity,nil,nil,"LOOT_OPENED")
                end
            end
        end
    elseif event=="LFG_COMPLETION_REWARD" or event=="CHALLENGE_MODE_COMPLETED" then
        MCF:MarkDungeonComplete(event)
    end
end)

-- On logout Core closes the session; preserve an open dungeon visit too.
local logout=CreateFrame("Frame")
logout:RegisterEvent("PLAYER_LOGOUT")
logout:SetScript("OnEvent",function()
    if currentRun then MCF:EndDungeonRun("logout") end
end)
