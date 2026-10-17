local addonName, MCF = ...
local frame=CreateFrame("Frame")
local pending=false
local leaveConfirmToken=0

local function CleanTransientHistory(db)
    if not db or type(db.history)~="table" then return end
    local src,out=db.history,{}
    local i=1
    while i<=#src do
        local a,b=src[i],src[i+1]
        local close=a and b and tonumber(a.time) and tonumber(b.time)
            and math.abs(tonumber(b.time)-tonumber(a.time))<=10
        if a and b and a.kind=="LEFT" and b.kind=="JOINED"
            and a.guild and a.guild==b.guild and close then
            i=i+2
        else
            out[#out+1]=a
            i=i+1
        end
    end
    db.history=out
    if db.current and db.current.name then
        local joined=nil
        for _,e in ipairs(out) do
            if e.guild==db.current.name then
                if e.kind=="JOINED" or e.kind=="FIRST_SEEN" then joined=joined or e.time
                elseif e.kind=="LEFT" then joined=nil end
            end
        end
        if joined then
            db.current.joinedAt=joined
            db.current.firstSeen=db.current.firstSeen or joined
        end
    end
end


local function Ensure()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.guild=MyCharForeverDB.guild or {initialized=false,current=nil,history={}}
    MyCharForeverDB.guild.history=MyCharForeverDB.guild.history or {}
    CleanTransientHistory(MyCharForeverDB.guild)
    return MyCharForeverDB.guild
end

local function Where()
    local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    return {time=time(),level=UnitLevel("player"),zone=GetZoneText(),subZone=GetSubZoneText(),mapID=mapID}
end

local function OwnGuild()
    if not GetGuildInfo then return nil end
    local ok,name,rankName,rankIndex=pcall(GetGuildInfo,"player")
    if not ok or not name or name=="" then return nil end
    return {name=name,rankName=rankName,rankIndex=rankIndex}
end

local function Event(kind,g,extra)
    local db=Ensure(); if not db then return end
    local e=Where(); e.kind=kind
    if g then e.guild=g.name; e.rankName=g.rankName; e.rankIndex=g.rankIndex end
    if extra then for k,v in pairs(extra) do e[k]=v end end
    table.insert(db.history,e)
end

-- Joining or being invited to a guild: photo (not held back by the cooldown) + journal entry. Settings: screenshotGuild, guildJournal.
local function German() return MCF.GetLanguage and MCF:GetLanguage()=="deDE" end
function MCF:OnGuildJoined(g)
    if not g or not g.name then return end
    local de=German()
    if self.AddEvent then pcall(self.AddEvent,self,"GUILD_JOIN",{guild=g.name,rankName=g.rankName}) end
    self:AutoMoment{reason="GUILD_JOIN",shotKey="screenshotGuild",journalKey="guildJournal",delay=1.5,force=true,source="GUILD_JOIN",fields={guild=g.name},
        title=string.format(de and "Der Gilde <%s> beigetreten" or "Joined the guild <%s>",g.name),
        text=(g.rankName and g.rankName~="") and string.format(de and "Rang: %s" or "Rank: %s",g.rankName) or ""}
end

function MCF:OnGuildInvite(inviter,guildName)
    if type(guildName)~="string" or guildName=="" then return end
    local de=German()
    inviter=type(inviter)=="string" and inviter~="" and inviter or nil
    if self.AddEvent then pcall(self.AddEvent,self,"GUILD_INVITE",{guild=guildName,inviter=inviter}) end
    -- no delay: the invitation window is on screen right now
    self:AutoMoment{reason="GUILD_INVITE",shotKey="screenshotGuild",journalKey="guildJournal",force=true,source="GUILD_INVITE",fields={guild=guildName,inviter=inviter},
        title=string.format(de and "Einladung in die Gilde <%s>" or "Invited to the guild <%s>",guildName),
        text=inviter and string.format(de and "%s hat dich eingeladen." or "%s invited you.",inviter) or ""}
end

function MCF:ScanGuild()
    local db=Ensure(); if not db then return end
    local now=OwnGuild()
    if now then leaveConfirmToken=leaveConfirmToken+1 end
    local old=db.current
    if not db.initialized then
        if now then
            Event("FIRST_SEEN",now)
            now.firstSeen=time()
        end
        db.current=now
        db.initialized=true
        db.lastScan=time()
        if MCF.RefreshUI then MCF:RefreshUI() end
        return
    end

    if not old and now then
        Event("JOINED",now)
        now.joinedAt=time()
        db.current=now
        MCF:OnGuildJoined(now)
    elseif old and not now then
        -- GetGuildInfo can transiently return nil while guild data is being
        -- refreshed. Confirm a real leave before writing history.
        leaveConfirmToken=leaveConfirmToken+1
        local token=leaveConfirmToken
        C_Timer.After(2.0,function()
            if token~=leaveConfirmToken then return end
            local check=OwnGuild()
            local live=Ensure()
            if not live or not live.current then return end
            if check then
                -- Same/another guild is visible again: the nil was transient.
                MCF:ScanGuild()
                return
            end
            local leftName=live.current.name
            Event("LEFT",live.current)
            if MCF.OnGuildLeft then pcall(MCF.OnGuildLeft,MCF,leftName) end
            live.current=nil
            live.lastScan=time()
            if MCF.RefreshUI then MCF:RefreshUI() end
        end)
        db.lastScan=time()
        return
    elseif old and now then
        if old.name~=now.name then
            Event("LEFT",old,{changedTo=now.name})
            Event("JOINED",now,{changedFrom=old.name})
            now.joinedAt=time()
            MCF:OnGuildJoined(now)
        else
            now.firstSeen=old.firstSeen
            now.joinedAt=old.joinedAt
            if (old.rankName or "")~=(now.rankName or "") or tonumber(old.rankIndex)~=tonumber(now.rankIndex) then
                Event("RANK_CHANGED",now,{oldRankName=old.rankName,oldRankIndex=old.rankIndex})
            end
        end
        db.current=now
    end
    db.lastScan=time()
    if MCF.RefreshUI then MCF:RefreshUI() end
end

local function Queue(delay)
    if pending then return end
    pending=true
    C_Timer.After(delay or 1,function() pending=false; MCF:ScanGuild() end)
end

frame:RegisterEvent("PLAYER_LOGIN")
pcall(function() frame:RegisterEvent("PLAYER_GUILD_UPDATE") end)
pcall(function() frame:RegisterEvent("GUILD_ROSTER_UPDATE") end)
pcall(function() frame:RegisterEvent("GUILD_INVITE_REQUEST") end)
frame:SetScript("OnEvent",function(_,event,...)
    if event=="GUILD_INVITE_REQUEST" then
        local inviter,guildName=...
        pcall(MCF.OnGuildInvite,MCF,inviter,guildName)
    elseif event=="PLAYER_LOGIN" then Queue(3) else Queue(1) end
end)
