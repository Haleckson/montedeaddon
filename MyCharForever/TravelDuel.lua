local addonName, MCF = ...
-- Walking pace (yards/second) for the walk-distance counter: normal walking is about 2.5, running 7.
-- hearthSpells: spell IDs that count as a Hearthstone use (counted when the cast succeeds, not when it is started or interrupted).
MCF.Travel = {walkMinYps = 0.5, walkMaxYps = 3.5, hearthSpells = {[8690] = true}}
local f=CreateFrame("Frame")
local lastX,lastY,lastMap,lastTick
local wasTaxi=false
local duelOpponent,duelResolved=nil,false

local function ensure()
    if not MyCharForeverDB then return nil end
    local db=MyCharForeverDB
    db.travel=db.travel or {groundYards=0,taxiYards=0,taxiSeconds=0,taxiRoutes=0,byLevel={}}
    db.travel.byLevel=db.travel.byLevel or {}
    db.duels=db.duels or {total=0,wins=0,losses=0,byLevel={},history={}}
    db.duels.byLevel=db.duels.byLevel or {}; db.duels.history=db.duels.history or {}
    return db
end
local function LT(level)
    local db=ensure(); if not db then return end
    level=tonumber(level) or UnitLevel("player") or 0
    db.travel.byLevel[level]=db.travel.byLevel[level] or {groundYards=0,taxiYards=0,taxiSeconds=0,taxiRoutes=0}
    return db.travel.byLevel[level]
end
-- Hearthstone use: total in db.travel.hearthstoneUses, per level in byLevel[level].hearthstoneUses, plus a HEARTHSTONE event
-- (position = where the player stood when the cast finished, i.e. the place left behind).
local function addHearthstone()
    local db=ensure(); if not db then return end
    local lt=LT(UnitLevel("player") or 0)
    db.travel.hearthstoneUses=(db.travel.hearthstoneUses or 0)+1
    lt.hearthstoneUses=(lt.hearthstoneUses or 0)+1
    if MCF.AddEvent then MCF:AddEvent("HEARTHSTONE",{useNumber=db.travel.hearthstoneUses}) end
end
local function LD(level)
    local db=ensure(); if not db then return end
    level=tonumber(level) or UnitLevel("player") or 0
    db.duels.byLevel[level]=db.duels.byLevel[level] or {total=0,wins=0,losses=0}
    return db.duels.byLevel[level]
end
local function addDuel(result)
    local db=ensure(); if not db or duelResolved then return end
    duelResolved=true
    local level=UnitLevel("player") or 0; local ld=LD(level)
    db.duels.total=(db.duels.total or 0)+1; ld.total=(ld.total or 0)+1
    if result=="WIN" then db.duels.wins=(db.duels.wins or 0)+1; ld.wins=(ld.wins or 0)+1
    elseif result=="LOSS" then db.duels.losses=(db.duels.losses or 0)+1; ld.losses=(ld.losses or 0)+1 end
    table.insert(db.duels.history,{time=time(),level=level,opponent=duelOpponent,result=result,zone=GetZoneText(),subZone=GetSubZoneText()})
    if MCF.AddEvent then MCF:AddEvent("DUEL",{opponent=duelOpponent,result=result}) end
end
local function fmtPattern(fmt)
    if type(fmt)~="string" then return nil end
    local token="__MCFS__"
    local p=fmt:gsub("%%s",token)
    p=p:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1")
    p=p:gsub(token,"(.+)")
    return "^"..p.."$"
end
local knockoutPattern=fmtPattern(_G.ERR_DUEL_WINNER_KNOCKOUT)
local retreatPattern=fmtPattern(_G.ERR_DUEL_WINNER_RETREAT)

f:RegisterEvent("PLAYER_LOGIN")
pcall(function() f:RegisterEvent("DUEL_REQUESTED") end)
pcall(function() f:RegisterEvent("DUEL_INBOUNDS") end)
pcall(function() f:RegisterEvent("DUEL_FINISHED") end)
f:RegisterEvent("CHAT_MSG_SYSTEM")
pcall(function() f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player") end)
f:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_LOGIN" then ensure(); wasTaxi=UnitOnTaxi and UnitOnTaxi("player") or false
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        local _,_,spellID=...
        if spellID and MCF.Travel.hearthSpells[spellID] then addHearthstone() end
    elseif event=="DUEL_REQUESTED" then duelOpponent=(...); duelResolved=false
    elseif event=="DUEL_INBOUNDS" then
        duelResolved=false
        if not duelOpponent and UnitExists("target") and UnitIsPlayer("target") then duelOpponent=UnitName("target") end
    elseif event=="CHAT_MSG_SYSTEM" and duelOpponent and not duelResolved then
        local msg=(...); local winner,loser
        if knockoutPattern then winner,loser=msg:match(knockoutPattern) end
        if not winner and retreatPattern then winner,loser=msg:match(retreatPattern) end
        if winner and loser then
            local me=UnitName("player")
            if winner==me then addDuel("WIN") elseif loser==me then addDuel("LOSS") end
        end
    elseif event=="DUEL_FINISHED" then
        C_Timer.After(1,function() duelOpponent=nil; duelResolved=false end)
    end
end)

C_Timer.NewTicker(1,function()
    local db=ensure(); if not db or not UnitPosition then return end
    local now=GetTime(); local x,y,_,mapID=UnitPosition("player")
    local taxi=UnitOnTaxi and UnitOnTaxi("player") or false
    local level=UnitLevel("player") or 0; local lt=LT(level)
    if taxi and not wasTaxi then
        db.travel.taxiRoutes=(db.travel.taxiRoutes or 0)+1; lt.taxiRoutes=(lt.taxiRoutes or 0)+1
        if MCF.AddEvent then MCF:AddEvent("TAXI_START",{routeNumber=db.travel.taxiRoutes}) end
    end
    local dt=lastTick and (now-lastTick) or 0
    if dt>0 and dt<=3 and taxi then
        db.travel.taxiSeconds=(db.travel.taxiSeconds or 0)+dt; lt.taxiSeconds=(lt.taxiSeconds or 0)+dt
    end
    if x and y and lastX and lastY and mapID and lastMap==mapID and dt>0 and dt<=3 then
        local dx,dy=x-lastX,y-lastY; local dist=math.sqrt(dx*dx+dy*dy)
        if dist>=0 and dist<=500*dt then
            if taxi then db.travel.taxiYards=(db.travel.taxiYards or 0)+dist; lt.taxiYards=(lt.taxiYards or 0)+dist
            else
                db.travel.groundYards=(db.travel.groundYards or 0)+dist; lt.groundYards=(lt.groundYards or 0)+dist
                local speed=dist/dt
                if speed>=MCF.Travel.walkMinYps and speed<=MCF.Travel.walkMaxYps then db.travel.walkYards=(db.travel.walkYards or 0)+dist end
            end
        end
    end
    lastX,lastY,lastMap,lastTick=x,y,mapID,now; wasTaxi=taxi
end)
