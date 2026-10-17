local addonName, MCF = ...

local DEFAULT_UPDATE_INTERVAL = 5

local function UpdateInterval()
    return DEFAULT_UPDATE_INTERVAL
end
local MIN_DISTANCE = 0.004
local FORCE_DISTANCE = 0.015
local MIN_TURN_DEGREES = 12

local journeyTicker
local taxiState

local function XY(p)
    return p.x or p[3], p.y or p[4]
end

local function MapID(p)
    return p.mapID or p.m or p[2]
end

local function Reason(p)
    return p.reason or p.r
end

local function Distance(x1,y1,x2,y2)
    local dx,dy=x2-x1,y2-y1
    return math.sqrt(dx*dx+dy*dy)
end

local function TurnDegrees(a,b,c)
    local ax,ay=XY(a); local bx,by=XY(b); local cx,cy=XY(c)
    if not ax or not bx or not cx then return 180 end
    local v1x,v1y=bx-ax,by-ay
    local v2x,v2y=cx-bx,cy-by
    local l1=math.sqrt(v1x*v1x+v1y*v1y)
    local l2=math.sqrt(v2x*v2x+v2y*v2y)
    if l1==0 or l2==0 then return 0 end
    local dot=(v1x*v2x+v1y*v2y)/(l1*l2)
    dot=math.max(-1,math.min(1,dot))
    return math.deg(math.acos(dot))
end

local function NewCompactPoint(mapID,x,y,reason,levelOverride,taxiOverride)
    -- Short keys substantially reduce SavedVariables size.
    -- q=true marks a flight-master/taxi sample. It stays in the raw chronicle
    -- but the normal walking Journey route deliberately does not render it.
    local taxi = taxiOverride
    if taxi == nil then taxi = UnitOnTaxi and UnitOnTaxi("player") or false end
    local round=MCF.Maintenance and MCF.Maintenance.RoundCoord or function(v) return v end
    return {
        t=time(),
        m=mapID,
        x=round(x),
        y=round(y),
        l=levelOverride or UnitLevel("player"),
        r=reason,
        q=taxi and true or nil
    }
end

function MCF:GetJourneyPointData(p)
    return {
        time=p.time or p.t,
        mapID=p.mapID or p.m,
        x=p.x,
        y=p.y,
        level=p.level or p.l,
        reason=p.reason or p.r,
        taxi=p.taxi or p.q,
        zone=p.zone,
        subZone=p.subZone,
    }
end

function MCF:RecordJourneyPoint(reason, force, levelOverride, taxiOverride)
    if not MyCharForeverDB or not MyCharForeverDB.settings.trackJourney then return end

    local mapID=C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos=C_Map.GetPlayerMapPosition(mapID,"player")
    if not pos then return end
    local x,y=pos:GetXY()
    if not x or not y or (x==0 and y==0) then return end

    local j=MyCharForeverDB.journey
    local last=j[#j]
    local lastData=last and self:GetJourneyPointData(last)

    if not force and lastData and lastData.mapID==mapID then
        local d=Distance(lastData.x,lastData.y,x,y)
        if d < MIN_DISTANCE then return end

        -- If the previous movement point lies almost on a straight line,
        -- replace it instead of appending another redundant point.
        local prev=j[#j-1]
        if prev and not lastData.reason then
            local prevData=self:GetJourneyPointData(prev)
            if prevData.mapID==mapID then
                local candidate={x=x,y=y}
                local turn=TurnDegrees(prevData,lastData,candidate)
                local fromPrev=Distance(prevData.x,prevData.y,x,y)
                if turn < MIN_TURN_DEGREES and fromPrev < FORCE_DISTANCE then
                    j[#j]=NewCompactPoint(mapID,x,y,nil,nil,taxiOverride)
                    return
                end
            end
        end
    end

    j[#j+1]=NewCompactPoint(mapID,x,y,reason,levelOverride,taxiOverride)
end

local function CurrentTaxiState()
    return UnitOnTaxi and UnitOnTaxi("player") and true or false
end

function MCF:CheckJourneyTaxiState(silent)
    local now=CurrentTaxiState()
    if taxiState == nil then
        taxiState=now
        return
    end
    if now == taxiState then return end

    taxiState=now
    if silent then return end

    if now then
        -- Explicit boundary: last point at take-off belongs to the taxi run.
        self:RecordJourneyPoint("TAXI_START",true,nil,true)
    else
        -- Explicit boundary: landing starts a fresh ground run.
        self:RecordJourneyPoint("TAXI_END",true,nil,false)
    end

    if self.RefreshJourneyMapIfVisible then self:RefreshJourneyMapIfVisible() end
end

function MCF:JourneyTaxiEvent()
    -- PLAYER_CONTROL_LOST/GAINED can fire slightly before UnitOnTaxi changes.
    -- Check immediately and again shortly afterwards. The transition function
    -- is idempotent, so duplicate events are harmless.
    self:CheckJourneyTaxiState(false)
    C_Timer.After(0.15,function()
        if MCF and MCF.CheckJourneyTaxiState then MCF:CheckJourneyTaxiState(false) end
    end)
    C_Timer.After(0.50,function()
        if MCF and MCF.CheckJourneyTaxiState then MCF:CheckJourneyTaxiState(false) end
    end)
end

function MCF:StartJourneyTracking()
    if journeyTicker then journeyTicker:Cancel() end
    -- Adopt a flight already in progress on login/reload without inventing a
    -- TAXI_START event. New transitions are recorded from control events.
    taxiState=CurrentTaxiState()
    self:RecordJourneyPoint("LOGIN",true,nil,taxiState)

    local interval=UpdateInterval()
    journeyTicker=C_Timer.NewTicker(interval,function()
        if MCF.CheckJourneyTaxiState then MCF:CheckJourneyTaxiState(false) end
        if MyCharForeverDB then
            local zone=GetZoneText()
            local subZone=GetSubZoneText()
            local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
            local inInstance,instanceType=IsInInstance()
            local resting=IsResting and IsResting() or false
            if issecretvalue and issecretvalue(resting) then resting=false end

            if zone and zone~="" then
                -- Legacy aggregate kept for compatibility with the existing Overview.
                MyCharForeverDB.zoneTime=MyCharForeverDB.zoneTime or {}
                MyCharForeverDB.zoneTime[zone]=(MyCharForeverDB.zoneTime[zone] or 0)+interval

                -- Rich location totals: enough raw categorisation to build later
                -- Zone / City / Subzone / Instance statistics without changing old data.
                MyCharForeverDB.locationTime=MyCharForeverDB.locationTime or {
                    zones={}, subZones={}, maps={}, categories={}
                }
                local lt=MyCharForeverDB.locationTime
                lt.zones=lt.zones or {}; lt.subZones=lt.subZones or {}
                lt.maps=lt.maps or {}; lt.categories=lt.categories or {}

                lt.zones[zone]=(lt.zones[zone] or 0)+interval
                if subZone and subZone~="" then
                    local skey=zone.." > "..subZone
                    lt.subZones[skey]=(lt.subZones[skey] or 0)+interval
                end
                if mapID then
                    local mkey=tostring(mapID)
                    lt.maps[mkey]=lt.maps[mkey] or {seconds=0,zone=zone}
                    lt.maps[mkey].seconds=(lt.maps[mkey].seconds or 0)+interval
                    lt.maps[mkey].zone=zone
                end

                local category
                if inInstance then
                    if instanceType=="party" then category="dungeon"
                    elseif instanceType=="raid" then category="raid"
                    elseif instanceType=="pvp" or instanceType=="arena" then category="pvp"
                    else category="instance" end
                elseif resting then
                    -- WoW reliably exposes resting areas, but not every resting area is
                    -- necessarily a capital city. Preserve that distinction in the raw data.
                    category="resting"
                else
                    category="world"
                end
                lt.categories[category]=(lt.categories[category] or 0)+interval

                -- Per-level zone time is kept separately so later reports can
                -- reconstruct where each individual level was spent.
                local a=MCF.GetLevelActivity and MCF:GetLevelActivity(UnitLevel("player"))
                if a then
                    a.zoneSeconds=a.zoneSeconds or {}
                    a.zoneSeconds[zone]=(a.zoneSeconds[zone] or 0)+interval
                    MCF:RecordLevelZone(zone,subZone,mapID)
                end
            end
        end
        local before=MyCharForeverDB and MyCharForeverDB.journey and #MyCharForeverDB.journey or 0
        MCF:RecordJourneyPoint(nil,false)
        local after=MyCharForeverDB and MyCharForeverDB.journey and #MyCharForeverDB.journey or 0
        if after>before and MCF.RefreshJourneyMapIfVisible then
            MCF:RefreshJourneyMapIfVisible()
        end
    end)
end
