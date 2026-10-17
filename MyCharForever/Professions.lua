local addonName, MCF = ...
local function T(key) return MCF:T(key) end

-- Profession history is deliberately milestone based. We still keep the current
-- skill value, but history only grows when a profession is first seen/learned,
-- its cap changes, or a 25-point milestone is crossed.
local frame=CreateFrame("Frame")
local scanPending=false

local function EnsureDB()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.professions=MyCharForeverDB.professions or {
        initialized=false,current={},history={},milestones={}
    }
    local p=MyCharForeverDB.professions
    p.current=p.current or {}; p.history=p.history or {}; p.milestones=p.milestones or {}
    return p
end

local function SnapshotLocation()
    local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    return {time=time(),level=UnitLevel("player"),zone=GetZoneText(),subZone=GetSubZoneText(),mapID=mapID}
end

local function AddHistory(kind,entry,extra)
    local db=EnsureDB(); if not db then return end
    local e=SnapshotLocation()
    e.kind=kind; e.key=entry.key; e.name=entry.name; e.skill=entry.skill; e.maxSkill=entry.maxSkill
    e.skillLine=entry.skillLine
    if extra then for k,v in pairs(extra) do e[k]=v end end
    table.insert(db.history,e)
end

local function AddMilestone(entry,value,kind)
    local db=EnsureDB(); if not db then return end
    local id=tostring(entry.key)..":"..tostring(kind or "SKILL")..":"..tostring(value)
    if db.milestones[id] then return end
    local e=SnapshotLocation()
    e.kind=kind or "SKILL"; e.key=entry.key; e.name=entry.name
    e.value=value; e.skill=entry.skill; e.maxSkill=entry.maxSkill; e.skillLine=entry.skillLine
    db.milestones[id]=e
end

local function ReadProfessions()
    local out={}
    if GetProfessions and GetProfessionInfo then
        local ok,a,b,c,d,e,f=pcall(GetProfessions)
        if ok then
            local indexes={a,b,c,d,e,f}
            for _,idx in ipairs(indexes) do
                if idx then
                    local ok2,name,icon,skill,maxSkill,_,_,skillLine=pcall(GetProfessionInfo,idx)
                    if ok2 and name and tonumber(maxSkill) and tonumber(maxSkill)>0 then
                        local key=skillLine and ("id:"..tostring(skillLine)) or ("name:"..name)
                        out[key]={key=key,name=name,icon=icon,skill=tonumber(skill) or 0,
                                  maxSkill=tonumber(maxSkill) or 0,skillLine=skillLine}
                    end
                end
            end
        end
    end
    return out
end

function MCF:GetProfessionSnapshot()
    local out={}
    for key,p in pairs(ReadProfessions()) do
        out[key]={key=p.key,name=p.name,skill=p.skill,maxSkill=p.maxSkill,skillLine=p.skillLine,icon=p.icon}
    end
    return out
end

-- A profession missing from one scan is not yet "unlearned": right after login the game may not have the
-- skill list ready. It must be missing in two scans at least MISSING_CONFIRM_SECONDS apart.
local MISSING_CONFIRM_SECONDS=5
local missingSince={}
local recheckPending=false

function MCF:ScanProfessions()
    local db=EnsureDB(); if not db then return end
    local now=ReadProfessions()
    local firstScan=not db.initialized

    for key,p in pairs(now) do
        local old=db.current[key]
        missingSince[key]=nil
        if not old then
            AddHistory(firstScan and "FIRST_SEEN" or "LEARNED",p)
            AddMilestone(p,p.skill,"FIRST_SEEN")
        elseif old.unlearned then
            -- Learned again after it had been dropped: everything recorded so far stays (milestones, history,
            -- first-seen date); the milestones already reached are not recorded a second time.
            AddHistory("RELEARNED",p,{previousSkill=old.skill,unlearnedAt=old.unlearnedAt})
            p.relearned=(tonumber(old.relearned) or 0)+1
        else
            if (p.maxSkill or 0)>(old.maxSkill or 0) then
                AddHistory("CAP_CHANGED",p,{oldMaxSkill=old.maxSkill,newMaxSkill=p.maxSkill})
                AddMilestone(p,p.maxSkill,"CAP")
            end
            local oldSkill=tonumber(old.skill) or 0
            local newSkill=tonumber(p.skill) or 0
            if newSkill>oldSkill then
                local threshold=(math.floor(oldSkill/25)+1)*25
                while threshold<=newSkill do
                    AddMilestone(p,threshold,"SKILL")
                    threshold=threshold+25
                end
            end
        end
        p.lastSeen=time()
        p.firstSeen=(old and old.firstSeen) or time()
        if old and not p.relearned then p.relearned=old.relearned end
        db.current[key]=p
    end

    if not firstScan then
        local anyMissing=false
        local nowCount=0; for _ in pairs(now) do nowCount=nowCount+1 end
        for key,old in pairs(db.current) do
            if not now[key] and not old.unlearned then
                anyMissing=true
                local t=GetTime()
                if not missingSince[key] then
                    missingSince[key]=t
                elseif t-missingSince[key]>=MISSING_CONFIRM_SECONDS then
                    local copy={}
                    for k,v in pairs(old) do copy[k]=v end
                    AddHistory("UNLEARNED",copy)
                    old.unlearned=true; old.unlearnedAt=time()
                    missingSince[key]=nil
                end
            end
        end
        if anyMissing and not recheckPending then
            recheckPending=true
            C_Timer.After(MISSING_CONFIRM_SECONDS+1,function() recheckPending=false; MCF:ScanProfessions() end)
        end
    end
    -- Skill per character level: the last scan of a level is the value at the end of that level.
    local lvl=UnitLevel("player")
    if lvl and lvl>0 then
        db.byLevel=db.byLevel or {}
        local row=db.byLevel[lvl] or {}
        for key,p in pairs(now) do row[key]={name=p.name,skill=p.skill,maxSkill=p.maxSkill} end
        db.byLevel[lvl]=row
    end
    db.initialized=true
    db.lastScan=time()
    if MCF.RefreshUI then MCF:RefreshUI() end
end

local function QueueScan(delay)
    if scanPending then return end
    scanPending=true
    C_Timer.After(delay or 0.5,function()
        scanPending=false
        MCF:ScanProfessions()
    end)
end

-- Recipes that did not come from a trainer (world drops, dungeons, quests, vendors): learned recipes are
-- recorded unless the trainer window is open. Trainer recipes are not interesting for a chronicle.
local RECIPE_LIMIT=300
local trainerOpen,merchantOpen=false,false
local lastRecipe,lastRecipeAt="",0

local function PatternFromFormat(fmt)
    if type(fmt)~="string" then return nil end
    fmt=fmt:gsub("([%^%$%(%)%.%[%]%*%+%-%?%%])","%%%1")
    fmt=fmt:gsub("%%%%s","(.+)")
    return "^"..fmt.."$"
end
local RECIPE_PATTERN=PatternFromFormat(ERR_LEARN_RECIPE_S)

function MCF:RecordLearnedRecipe(name,recipeID)
    local db=EnsureDB(); if not db then return end
    if trainerOpen or type(name)~="string" or name=="" then return end
    local now=GetTime()
    if name==lastRecipe and now-lastRecipeAt<5 then return end -- chat message and event for the same recipe
    lastRecipe,lastRecipeAt=name,now
    db.recipes=db.recipes or {}
    local e=SnapshotLocation()
    e.name=name; e.recipeID=recipeID; e.source=merchantOpen and "VENDOR" or "OTHER"
    table.insert(db.recipes,e)
    while #db.recipes>RECIPE_LIMIT do table.remove(db.recipes,1) end
    if MCF.RefreshUI then MCF:RefreshUI() end
end

local function RecipeNameFromMessage(msg)
    if not RECIPE_PATTERN or type(msg)~="string" then return nil end
    local captured=msg:match(RECIPE_PATTERN)
    if not captured then return nil end
    local name=captured:match("%[(.-)%]")
    if not name then name=captured:gsub("|c%x%x%x%x%x%x%x%x",""); name=name:gsub("|r","") end
    return name
end

MCF.RecipeNameFromMessage=RecipeNameFromMessage -- also used by the self test (/mcf selftest)

frame:RegisterEvent("PLAYER_LOGIN")
pcall(function() frame:RegisterEvent("SKILL_LINES_CHANGED") end)
pcall(function() frame:RegisterEvent("CHAT_MSG_SKILL") end)
pcall(function() frame:RegisterEvent("PLAYER_LEVEL_UP") end)
for _,e in ipairs({"TRAINER_SHOW","TRAINER_CLOSED","MERCHANT_SHOW","MERCHANT_CLOSED","NEW_RECIPE_LEARNED","CHAT_MSG_SYSTEM"}) do
    pcall(function() frame:RegisterEvent(e) end)
end
frame:SetScript("OnEvent",function(_,event,...)
    if event=="PLAYER_LOGIN" then QueueScan(2)
    elseif event=="TRAINER_SHOW" then trainerOpen=true
    elseif event=="TRAINER_CLOSED" then trainerOpen=false
    elseif event=="MERCHANT_SHOW" then merchantOpen=true
    elseif event=="MERCHANT_CLOSED" then merchantOpen=false
    elseif event=="NEW_RECIPE_LEARNED" then
        local recipeID=MCF.Readable and MCF.Readable((...)) or (...)
        local name
        if type(recipeID)=="number" and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
            local ok,info=pcall(C_TradeSkillUI.GetRecipeInfo,recipeID)
            if ok and type(info)=="table" then name=info.name end
        end
        if name then MCF:RecordLearnedRecipe(name,recipeID) end
        QueueScan(0.5)
    elseif event=="CHAT_MSG_SYSTEM" then
        local msg=MCF.Readable and MCF.Readable((...)) or (...)
        local name=RecipeNameFromMessage(msg)
        if name then MCF:RecordLearnedRecipe(name) end
    elseif event=="PLAYER_LEVEL_UP" then QueueScan(1.5) -- record the skill state at the start of the new level
    else QueueScan(0.5) end
end)
