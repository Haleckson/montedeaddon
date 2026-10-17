local addonName, MCF = ...
local frame=CreateFrame("Frame")
local pending=false
local ignoreEventsUntil=0 -- opening/closing headers fires UPDATE_FACTION itself: never rescan because of our own scan

local function Ensure()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.reputation=MyCharForeverDB.reputation or {initialized=false,current={},milestones={}}
    local r=MyCharForeverDB.reputation
    r.current=r.current or {}; r.milestones=r.milestones or {}
    return r
end
local function Loc()
    local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    return {time=time(),level=UnitLevel("player"),zone=GetZoneText(),subZone=GetSubZoneText(),mapID=mapID}
end
local function StandingName(id)
    local names={[1]="Hated",[2]="Hostile",[3]="Unfriendly",[4]="Neutral",[5]="Friendly",[6]="Honored",[7]="Revered",[8]="Exalted"}
    return names[tonumber(id) or 0] or tostring(id or "?")
end
-- One reader for both client generations. Newer clients removed GetNumFactions/GetFactionInfo
-- in favour of C_Reputation; the old globals then silently returned nothing (no factions at all).
-- Returns a normalised table or nil: {name,id,standingID,value,isHeader,hasRep,isCollapsed}
local function ReadFaction(i)
    local C=C_Reputation
    if C and C.GetFactionDataByIndex then
        local d=C.GetFactionDataByIndex(i)
        if type(d)~="table" then return nil end
        return {name=d.name,id=d.factionID,standingID=tonumber(d.reaction),value=tonumber(d.currentStanding) or 0,
            isHeader=d.isHeader and true or false,hasRep=(not d.isHeader) or d.isHeaderWithRep or false,
            isCollapsed=d.isCollapsed and true or false}
    end
    if GetFactionInfo then
        local name,_,standingID,_,_,value,_,_,isHeader,isCollapsed,hasRep,_,_,factionID=GetFactionInfo(i)
        if not name then return nil end
        return {name=name,id=factionID,standingID=tonumber(standingID),value=tonumber(value) or 0,
            isHeader=isHeader and true or false,hasRep=(not isHeader) or hasRep or false,isCollapsed=isCollapsed and true or false}
    end
    return nil
end
local function NumFactions()
    if C_Reputation and C_Reputation.GetNumFactions then return C_Reputation.GetNumFactions() or 0 end
    return GetNumFactions and GetNumFactions() or 0
end
local function SetHeader(index,expand)
    local C=C_Reputation
    if C then
        local f=expand and C.ExpandFactionHeader or C.CollapseFactionHeader
        if f then f(index); return true end
    end
    local g=expand and ExpandFactionHeader or CollapseFactionHeader
    if g then g(index); return true end
    return false
end

-- Collapsed headers hide their factions from the list. Open them for the scan and restore
-- exactly what the player had (highest index first, so earlier indices stay valid).
function MCF:ReadAllFactions()
    local list={}
    local opened={}
    local i=1
    while i<=NumFactions() and i<=400 do
        local f=ReadFaction(i)
        if f then
            if f.isHeader and f.isCollapsed and SetHeader(i,true) then opened[#opened+1]=i end
            if f.name and f.hasRep then list[#list+1]=f end
        end
        i=i+1
    end
    for k=#opened,1,-1 do SetHeader(opened[k],false) end
    if #opened>0 and GetTime then ignoreEventsUntil=GetTime()+3 end
    return list
end

local function Scan()
    local db=Ensure(); if not db then return end
    if not (C_Reputation and C_Reputation.GetNumFactions) and not GetNumFactions then return end
    local now={}
    for _,f in ipairs(MCF:ReadAllFactions()) do
        local key=f.id and f.id~=0 and ("id:"..tostring(f.id)) or ("name:"..f.name)
        now[key]={key=key,id=f.id,name=f.name,standingID=f.standingID or 4,value=f.value}
    end
    for key,r in pairs(now) do
        local old=db.current[key]
        if not old then
            local e=Loc(); e.key=key;e.id=r.id;e.name=r.name;e.standingID=r.standingID;e.standing=StandingName(r.standingID);e.kind="FIRST_SEEN"
            db.milestones[#db.milestones+1]=e
        elseif r.standingID>(tonumber(old.standingID) or 0) then
            for st=(tonumber(old.standingID) or 0)+1,r.standingID do
                if st>=4 and st<=8 then
                    local e=Loc(); e.key=key;e.id=r.id;e.name=r.name;e.standingID=st;e.standing=StandingName(st);e.kind="STANDING"
                    db.milestones[#db.milestones+1]=e
                end
            end
        end
    end
    db.current=now; db.initialized=true
    if MCF.RefreshUI then MCF:RefreshUI() end
end
function MCF:ScanReputation()
    if pending then return end
    pending=true
    C_Timer.After(0.8,function() pending=false; Scan() end)
end
frame:RegisterEvent("PLAYER_LOGIN")
pcall(function() frame:RegisterEvent("UPDATE_FACTION") end)
frame:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then C_Timer.After(3,function() Scan() end)
    elseif not (GetTime and GetTime()<ignoreEventsUntil) then MCF:ScanReputation() end
end)

MCF:AddCommand{group="debug",usage="/mcf rep",key="rep",de="Ruf-Auslesung prüfen (welche Schnittstelle, wie viele Fraktionen)",en="Check reputation reading (which API, how many factions)",
    run=function()
        local api=(C_Reputation and C_Reputation.GetFactionDataByIndex) and "C_Reputation" or (GetFactionInfo and "GetFactionInfo" or "none")
        local list=MCF:ReadAllFactions()
        local db=MyCharForeverDB and MyCharForeverDB.reputation
        local stored=0
        for _ in pairs(db and db.current or {}) do stored=stored+1 end
        print("|cff00ccffMyCharForever|r: "..(MCF:GetLanguage()=="deDE" and "Ruf: Schnittstelle " or "Reputation: API ")..api..
            (MCF:GetLanguage()=="deDE" and ", gelesen: " or ", read: ")..#list..(MCF:GetLanguage()=="deDE" and ", gespeichert: " or ", stored: ")..stored)
        Scan()
    end}
