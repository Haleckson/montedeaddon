local addonName, MCF = ...

local elapsed=0
local lastShot=0

local CHRONICLE_BINDING_ACTION="MYCHARFOREVER_CHRONICLE_SCREENSHOT"

MCF.SHOT_WAIT=1.5 -- longest wait for the game to finish a screenshot before the comment window opens

function MCF:GetChronicleScreenshotBinding()
    if GetBindingKey then
        local k1=GetBindingKey(CHRONICLE_BINDING_ACTION)
        if k1 and k1~="" then return k1 end
    end
    return nil
end

function MCF:FormatBindingKey(key)
    if not key or key=="" then return self:T("Not assigned") end
    local out=tostring(key)
    out=out:gsub("CTRL%-","Ctrl+"):gsub("SHIFT%-","Shift+"):gsub("ALT%-","Alt+")
    return out
end

function MCF:SetChronicleScreenshotBinding(key)
    if not SetBinding then return false end
    local old=self:GetChronicleScreenshotBinding()
    if old and old~="" and old~=key then SetBinding(old) end
    if not key or key=="" then
        if old and old~="" then SetBinding(old) end
    else
        -- If the selected key was used elsewhere, WoW replaces that binding.
        SetBinding(key,CHRONICLE_BINDING_ACTION)
    end
    if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
    return true
end

local knownEquipped={}
local f=CreateFrame("Frame")

local function S()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.settings=MyCharForeverDB.settings or {}
    local s=MyCharForeverDB.settings
    if s.screenshotLogAll==nil then s.screenshotLogAll=true end
    if s.screenshotEnabled==nil then s.screenshotEnabled=true end
    if s.screenshotLevelUp==nil then s.screenshotLevelUp=true end
    if s.screenshotLogin==nil then s.screenshotLogin=false end
    if s.screenshotDeath==nil then s.screenshotDeath=false end
    if s.screenshotDungeon==nil then s.screenshotDungeon=true end
    -- 1.0.2: the switch "At dungeon completion" now works and is on by default. Older versions stored it as off without it ever doing anything.
    if not s.screenshotDungeonV102 then s.screenshotDungeonV102=true; s.screenshotDungeon=true end
    if s.screenshotPeriodic==nil then s.screenshotPeriodic=false end
    if not s.screenshotInterval then s.screenshotInterval=5 end
    if s.screenshotEquip==nil then s.screenshotEquip=true end
    if not s.screenshotMinQuality then s.screenshotMinQuality=2 end
    -- 0.30.0: first green / blue / epic / legendary per slot; the old default (blue) is lowered once to green
    if not s.screenshotMinQualityV30 then
        s.screenshotMinQualityV30=true
        if s.screenshotMinQuality==3 then s.screenshotMinQuality=2 end
    end
    if not s.screenshotCooldown then s.screenshotCooldown=10 end
    return s
end

function MCF:TakeChronicleScreenshot(reason,force)
    local s=S()
    if not s or not s.screenshotEnabled then return false end
    local now=GetTime()
    -- force: moments that must not be lost to the cooldown (guild invite followed by joining a few seconds later)
    if not force and now-lastShot < (tonumber(s.screenshotCooldown) or 10) then return false end
    lastShot=now
    if self.RecordScreenshot then self:RecordScreenshot(reason) end
    Screenshot()
    return true
end

-- One place for "a moment worth a photo and a journal entry" (iconic moments, guild invite / join, ...).
-- spec: reason (screenshot reason), title, text, source (journal source), fields (extra journal fields),
--       shotKey / journalKey (settings, a missing value counts as on), noJournal (picture only), delay (s), force (ignore the screenshot cooldown).
-- The journal entry links to the screenshot when one was taken; without a screenshot it is written without a picture.
function MCF:AutoMoment(spec)
    local st=MyCharForeverDB and MyCharForeverDB.settings or {}
    local doShot=not (spec.shotKey and st[spec.shotKey]==false)
    local doJournal=not spec.noJournal and not (spec.journalKey and st[spec.journalKey]==false)
    if not (doShot or doJournal) then return end
    local function run()
        if not MyCharForeverDB then return end
        local shot
        if doShot and self:TakeChronicleScreenshot(spec.reason,spec.force) then
            shot=MyCharForeverDB.screenshots and MyCharForeverDB.screenshots[#MyCharForeverDB.screenshots]
        end
        if not doJournal then return end
        local zone,sub=GetZoneText(),GetSubZoneText()
        local place=(sub and sub~="" and sub~=zone) and (zone..", "..sub) or zone
        local entry={
            time=(shot and shot.time) or time(),level=UnitLevel("player"),mapID=shot and shot.mapID,x=shot and shot.x,y=shot and shot.y,
            zone=zone,subZone=sub,title=spec.title,
            text=(spec.text or "")..((place and place~="") and ("\n"..place) or ""),
            auto=true,source=spec.source,
        }
        for k,v in pairs(spec.fields or {}) do entry[k]=v end
        if shot then entry.screenshotFile=shot.expectedFileName; entry.screenshotIndex=#MyCharForeverDB.screenshots end
        MyCharForeverDB.journal=MyCharForeverDB.journal or {}
        table.insert(MyCharForeverDB.journal,entry)
        if self.RefreshMapJourney then self:RefreshMapJourney() end
        if self.RefreshUI then self:RefreshUI() end
    end
    if tonumber(spec.delay) and spec.delay>0 and C_Timer and C_Timer.After then C_Timer.After(spec.delay,run) else run() end
end

-- Row for a screenshot the addon is about to take (position + level + zone).
function MCF:RecordScreenshot(reason)
    if not MyCharForeverDB or not self.LogScreenshot then return nil end
    local mapID=C_Map.GetBestMapForUnit("player"); local x,y
    if mapID then local pos=C_Map.GetPlayerMapPosition(mapID,"player"); if pos then x,y=pos:GetXY() end end
    return self:LogScreenshot(reason,UnitLevel("player"),mapID,x,y)
end

-- Screenshots the player takes with the game's own key (Print Screen) are logged too. The addon's own
-- screenshots fire the same event; they are recognised by the mark LogScreenshot leaves.
local gameShots=CreateFrame("Frame")
local afterShot -- set while a manual screenshot waits to show its comment window (see TakeManualChronicleScreenshot)

-- WoW's Screenshot() does not return the file name. Two sources get us closer than the request time:
--  1. SCREENSHOT_SUCCEEDED: the file was written just now, so its time stamp is the event time ("saved").
--  2. The client's own on-screen/chat message, which (if it names the file) gives the real name ("chat").
-- Both are matched to the same screenshot; the real name always wins. Every step is guarded: a missing
-- or differently worded message just leaves the "saved" name in place.
local NAME_PATTERN="(WoWScrnShot_%d%d%d%d%d%d_%d%d%d%d%d%d%.%a+)"
local lastSaved,lastChat -- {entry=,t=} and {name=,t=,used=}, t = GetTime()

local function ReplacePlain(text,old,new)
    local i,j=text:find(old,1,true)
    if not i then return text end
    return text:sub(1,i-1)..new..text:sub(j+1)
end

function MCF:ApplyScreenshotName(entry,name,source)
    if type(entry)~="table" or type(name)~="string" or entry.fileNameSource=="chat" then return false end
    local old=entry.expectedFileName
    if name~=old then
        entry.requestedFileName=entry.requestedFileName or old -- keep the first guess; the viewer can try both
        entry.expectedFileName=name
        -- A journal entry written with the old name keeps pointing at the right picture.
        for _,j in ipairs((MyCharForeverDB and MyCharForeverDB.journal) or {}) do
            if old and j.screenshotFile==old then
                j.screenshotFile=name
                if type(j.text)=="string" then j.text=ReplacePlain(j.text,old,name) end
            end
        end
    end
    entry.fileNameSource=source
    return true
end

-- Oldest screenshot of the last 30 seconds that still waits for its confirmation.
local function OldestWaiting()
    local list=(MyCharForeverDB and MyCharForeverDB.screenshots) or {}
    local now=time()
    local first=#list
    while first>1 and list[first-1] and now-(list[first-1].time or 0)<=30 do first=first-1 end
    for i=first,#list do
        local e=list[i]
        if e and not e.savedAt and now-(e.time or 0)<=30 then return e end
    end
end

local function TryPair()
    if lastSaved and lastChat and not lastChat.used and math.abs(lastSaved.t-lastChat.t)<=3 then
        if MCF:ApplyScreenshotName(lastSaved.entry,lastChat.name,"chat") then lastChat.used=true end
    end
end

local function SawFileName(text)
    if type(text)~="string" then return end
    local name=text:match(NAME_PATTERN)
    if not name then return end
    lastChat={name=name,t=GetTime()}
    TryPair()
end

local function Saved(entry)
    if not entry then return end
    entry.savedAt=time()
    if entry.fileNameSource~="chat" then MCF:ApplyScreenshotName(entry,MCF:ScreenshotFileName(entry.savedAt),"saved") end
    lastSaved={entry=entry,t=GetTime()}
    TryPair()
end

gameShots:RegisterEvent("SCREENSHOT_SUCCEEDED")
gameShots:RegisterEvent("SCREENSHOT_FAILED")
gameShots:RegisterEvent("CHAT_MSG_SYSTEM")
gameShots:SetScript("OnEvent",function(_,event,msg)
    if event=="CHAT_MSG_SYSTEM" then SawFileName(msg); return end
    local own=event=="SCREENSHOT_SUCCEEDED" and MCF:ConsumeOwnShotMark()
    if own then Saved(OldestWaiting()) end
    if afterShot then local show=afterShot; afterShot=nil; show() end
    if event=="SCREENSHOT_FAILED" then return end
    if own then return end
    local st=S()
    if not st or st.screenshotLogAll==false then return end
    Saved(MCF:RecordScreenshot("GAME"))
end)
-- The message the client shows after saving may not be a chat line: also listen on its status frame.
if ActionStatus and ActionStatus.DisplayMessage and hooksecurefunc then
    hooksecurefunc(ActionStatus,"DisplayMessage",function(_,msg) pcall(SawFileName,msg) end)
end

-- The explanation is deliberately kept on screen until the screenshot is taken.
local notice=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
notice:SetSize(450,110)
notice:SetPoint("TOP",UIParent,"TOP",0,-145)
notice:SetFrameStrata("TOOLTIP")
notice:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,insets={left=4,right=4,top=4,bottom=4}})
notice:SetBackdropColor(0.035,0.035,0.045,1)
notice:SetBackdropBorderColor(0.75,0.58,0.17,1)
local heading=notice:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
heading:SetPoint("TOPLEFT",18,-15)
heading:SetText("MyCharForever - "..MCF:T("Equipment milestone"))
local details=notice:CreateFontString(nil,"OVERLAY","GameFontHighlight")
details:SetPoint("TOPLEFT",18,-42)
details:SetPoint("RIGHT",notice,"RIGHT",-18,0)
details:SetJustifyH("LEFT")
local itemText=notice:CreateFontString(nil,"OVERLAY","GameFontNormal")
itemText:SetPoint("TOPLEFT",18,-72)
itemText:SetPoint("RIGHT",notice,"RIGHT",-18,0)
itemText:SetJustifyH("LEFT")
notice:Hide()

-- Quality labels include the familiar item color; use WoW quality colors for emphasis.
local function FormatEquipmentQuality(quality, fallback)
    local de=(GetLocale()=="deDE")
    local labels=de and {
        [0]="Schlecht (Grau)", [1]="Gewöhnlich (Weiß)",
        [2]="Ungewöhnlich (Grün)", [3]="Selten (Blau)",
        [4]="Episch (Violett)", [5]="Legendär (Orange)",
        [6]="Artefakt (Gold)", [7]="Erbstück (Hellblau)",
    } or {
        [0]="Poor (Gray)", [1]="Common (White)",
        [2]="Uncommon (Green)", [3]="Rare (Blue)",
        [4]="Epic (Purple)", [5]="Legendary (Orange)",
        [6]="Artifact (Gold)", [7]="Heirloom (Light Blue)",
    }
    local label=labels[quality] or fallback or tostring(quality)
    local hex=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex
    if hex then return hex..label.."|r" end
    return label
end

local queue={}
local busy=false

-- Test helper: forget only equipment-quality screenshot milestones for this character.
-- Unequip the test item first, run /mcfresetgear, then equip it again.
MCF:AddCommand{group="debug",usage="/mcfresetgear",de="Screenshot-Meilensteine für Ausrüstungsqualität zurücksetzen (zum Testen)",en="Reset equipment-quality screenshot milestones (for testing)"}
SLASH_MCFRESETGEAR1="/mcfresetgear"
SlashCmdList.MCFRESETGEAR=function()
    local settings=S()
    if not settings then
        print("|cffffd200MyCharForever:|r Character data not ready.")
        return
    end
    settings.equipmentQualityShots={}
    wipe(knownEquipped)
    wipe(queue)
    notice:Hide()
    print("|cffffd200MyCharForever:|r " .. (GetLocale()=="deDE"
        and "Ausrüstungs-Screenshot-Meilensteine zurückgesetzt. Jetzt Gegenstand erneut anlegen."
        or "Equipment screenshot milestones reset. Now equip your test item again."))
end
local function ProcessEquipmentQueue()
    if busy or #queue==0 then return end
    local s=S()
    -- screenshot and journal entry are independent: the milestone counts even when no picture is wanted
    local wantShot=s and s.screenshotEnabled and s.screenshotEquip
    local wantJournal=s and s.equipJournal~=false
    if not (wantShot or wantJournal) then
        for i=#queue,1,-1 do queue[i]=nil end
        return
    end
    local wait=wantShot and math.max(0,(tonumber(s.screenshotCooldown) or 10)-(GetTime()-lastShot)) or 0
    if wait>0 then
        busy=true
        C_Timer.After(wait+0.1,function() busy=false; ProcessEquipmentQueue() end)
        return
    end
    local entry=table.remove(queue,1)
    if not entry then return end
    if s.equipmentQualityShots and s.equipmentQualityShots[entry.key] then
        ProcessEquipmentQueue()
        return
    end
    busy=true
    local showNotice=wantShot and (s.screenshotEquipNotice~=false)
    if showNotice then
        details:SetText(string.format(MCF:T("First quality in slot"),FormatEquipmentQuality(entry.quality,entry.qualityName),entry.slotName))
        itemText:SetText(entry.link or "")
        notice:Show()
    end
    C_Timer.After(showNotice and 1.5 or 0,function()
        local current=S()
        if current then
            current.equipmentQualityShots=current.equipmentQualityShots or {}
            current.equipmentQualityShots[entry.key]=true
            if MCF.AutoMoment then
                local comment=MCF.MomentComment and MCF:MomentComment("EQUIP",entry.quality,entry.group) or ""
                MCF:AutoMoment{reason="EQUIP_QUALITY_"..entry.quality.."_SLOT_"..entry.slot,
                    shotKey="screenshotEquip",journalKey="equipJournal",force=true,source="EQUIP_MILESTONE",
                    title=MCF.EquipMomentTitle and MCF:EquipMomentTitle(entry.group,entry.quality) or entry.slotName,
                    text=(comment or "")..(entry.link and ("\n"..entry.link) or ""),
                    fields={itemLink=entry.link,quality=entry.quality,slot=entry.slot,slotGroup=entry.group}}
            end
        end
        C_Timer.After(0.8,function()
            notice:Hide()
            busy=false
            ProcessEquipmentQueue()
        end)
    end)
end

local function ScanEquipped(takeShot)
    local s=S()
    if not s then return end
    s.equipmentQualityShots=s.equipmentQualityShots or {}
    -- First scan after the update (or after installing): what is worn right now is not a milestone of this journey.
    local seed=not s.equipmentSeeded and not takeShot
    for slot=1,19 do
        local group=MCF.SlotGroupOfSlot and MCF:SlotGroupOfSlot(slot)
        local link=group and GetInventoryItemLink("player",slot)
        if link then
            local itemID=GetInventoryItemID and GetInventoryItemID("player",slot)
            if not itemID then itemID=tonumber(link:match("item:(%d+)")) end
            local quality
            if C_Item and C_Item.GetItemQualityByID and itemID then
                quality=C_Item.GetItemQualityByID(itemID)
            end
            if quality==nil and GetItemInfo then
                local _,_,legacyQuality=GetItemInfo(link)
                quality=legacyQuality
            end
            if quality~=nil then
                local key=group..":"..tostring(quality)
                local itemKey=tostring(slot)..":"..tostring(itemID or link)
                if seed and quality>=2 and quality<=5 then s.equipmentQualityShots[key]=true end
                if takeShot and (s.screenshotEnabled and s.screenshotEquip or s.equipJournal~=false)
                    and quality<=5 and quality >= (tonumber(s.screenshotMinQuality) or 2)
                    and not knownEquipped[itemKey] and not s.equipmentQualityShots[key] then
                    -- Reserve pending milestones to prevent duplicate equipment events.
                    local pending=false
                    for _,entry in ipairs(queue) do if entry.key==key then pending=true; break end end
                    if not pending then
                        local slotName
                        -- WoW's numbered equipment slot labels are available as global strings.
                        local slotLabels={"HeadSlot","NeckSlot","ShoulderSlot","ShirtSlot","ChestSlot","WaistSlot","LegsSlot","FeetSlot","WristSlot","HandsSlot","Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot","BackSlot","MainHandSlot","SecondaryHandSlot","RangedSlot","TabardSlot"}
                        local slotId=slotLabels[slot]
                        local label=slotId and _G[slotId:upper()] or nil
                        slotName=label or (MCF:T("Equipment slot").." "..slot)
                        local qNames={[0]=ITEM_QUALITY0_DESC,[1]=ITEM_QUALITY1_DESC,[2]=ITEM_QUALITY2_DESC,[3]=ITEM_QUALITY3_DESC,[4]=ITEM_QUALITY4_DESC,[5]=ITEM_QUALITY5_DESC}
                        table.insert(queue,{key=key,slot=slot,group=group,quality=quality,qualityName=qNames[quality] or tostring(quality),slotName=slotName,link=link})
                    end
                end
                knownEquipped[itemKey]=true
            end
        end
    end
    if seed then s.equipmentSeeded=true end
    ProcessEquipmentQueue()
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:SetScript("OnEvent",function(_,event)
    local s=S()
    if event=="PLAYER_LOGIN" then
        C_Timer.After(0,function()
            local st=S()
            if st and not st.chronicleBindingInitialized then
                st.chronicleBindingInitialized=true
                local current=MCF.GetChronicleScreenshotBinding and MCF:GetChronicleScreenshotBinding() or nil
                local existing=GetBindingAction and GetBindingAction("CTRL-P") or ""
                if not current and (not existing or existing=="") and SetBinding then
                    SetBinding("CTRL-P",CHRONICLE_BINDING_ACTION)
                    if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
                end
            end
        end)
        C_Timer.After(2,function()
            MCF:CreateMinimapButton()
            ScanEquipped(false)
            if s and s.screenshotLogin then MCF:TakeChronicleScreenshot("LOGIN") end
        end)
    elseif event=="PLAYER_ENTERING_WORLD" then
        C_Timer.After(1,function() ScanEquipped(false) end)
    elseif event=="PLAYER_DEAD" then
        if s and s.screenshotDeath then MCF:TakeChronicleScreenshot("DEATH") end
    elseif event=="PLAYER_EQUIPMENT_CHANGED" then
        C_Timer.After(0.5,function() ScanEquipped(true) end)
    end
end)

f:SetScript("OnUpdate",function(_,dt)
    local s=S()
    if not s or not s.screenshotEnabled or not s.screenshotPeriodic then elapsed=0; return end
    elapsed=elapsed+dt
    local interval=math.max(1,math.min(60,tonumber(s.screenshotInterval) or 5))*60
    if elapsed>=interval then
        elapsed=elapsed-interval
        MCF:TakeChronicleScreenshot("PERIODIC")
    end
end)

-- Manual chronicle screenshot + optional comment.
local cf=MCF.Kit.Window("MyCharForeverScreenshotCommentFrame",{w=430,h=225,level=700,close=false,title=MCF:T("Chronicle screenshot")})
local ci=cf:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); ci:SetPoint("TOPLEFT",16,-38); ci:SetPoint("RIGHT",-16,0); ci:SetJustifyH("LEFT")
local ce=CreateFrame("EditBox",nil,cf,"InputBoxTemplate"); ce:SetPoint("TOPLEFT",18,-88); ce:SetPoint("RIGHT",-18,0); ce:SetHeight(30); ce:SetAutoFocus(true); ce:SetMaxLetters(500)
local cs=CreateFrame("Button",nil,cf,"UIPanelButtonTemplate"); cs:SetSize(120,24); cs:SetPoint("BOTTOMRIGHT",-16,14); cs:SetText(MCF:T("Save comment"))
local ck=CreateFrame("Button",nil,cf,"UIPanelButtonTemplate"); ck:SetSize(120,24); ck:SetPoint("RIGHT",cs,"LEFT",-8,0); ck:SetText(MCF:T("Without comment"))
local cj=CreateFrame("CheckButton",nil,cf,"UICheckButtonTemplate"); cj:SetSize(24,24); cj:SetPoint("BOTTOMLEFT",16,50)
cj.text=cj:CreateFontString(nil,"OVERLAY","GameFontHighlight"); cj.text:SetPoint("LEFT",cj,"RIGHT",4,0); cj.text:SetText(MCF:T("Also create journal entry"))
local pending
local function Finish(save)
    if pending then
        local v=(ce:GetText() or ""):match("^%s*(.-)%s*$")
        if save then pending.comment=(v~="") and v or nil end
        if cj:GetChecked() and MyCharForeverDB then
            MyCharForeverDB.journal=MyCharForeverDB.journal or {}
            local fn=pending.expectedFileName or MCF:T("Screenshot")
            local body=(save and v~="" and v or MCF:T("No comment"))
            body=body.."\n\n"..MCF:T("Screenshot file: ")..fn
            local entry={time=pending.time or time(),level=pending.level or UnitLevel("player"),mapID=pending.mapID,x=pending.x,y=pending.y,zone=pending.zone,subZone=pending.subZone,title=MCF:T("Screenshot journal title"),text=body,screenshotFile=fn,screenshotIndex=#(MyCharForeverDB.screenshots or {})}
            table.insert(MyCharForeverDB.journal,entry)
            if MCF.AddEvent then MCF:AddEvent("JOURNAL",{journalIndex=#MyCharForeverDB.journal,title=entry.title,source="SCREENSHOT"}) end
        end
    end
    pending=nil; ce:SetText(""); ce:ClearFocus(); cj:SetChecked(false); cf:Hide()
    if MCF.RefreshMapJourney then MCF:RefreshMapJourney() end
    if MCF.RefreshUI then MCF:RefreshUI() end
end
cs:SetScript("OnClick",function() Finish(true) end); ck:SetScript("OnClick",function() Finish(false) end)
ce:SetScript("OnEnterPressed",function() Finish(true) end); ce:SetScript("OnEscapePressed",function() Finish(false) end)

function MCF:TakeManualChronicleScreenshot()
    local st=S()
    if not st or not st.screenshotEnabled then print("|cffff4444MyCharForever|r: "..MCF:T("Screenshot recording disabled")); return end
    local mapID=C_Map.GetBestMapForUnit("player"); local x,y
    if mapID then local pos=C_Map.GetPlayerMapPosition(mapID,"player"); if pos then x,y=pos:GetXY() end end
    local entry
    if self.RecordScreenshot then entry=self:RecordScreenshot("MANUAL_CHRONICLE")
    elseif self.LogScreenshot then entry=self:LogScreenshot("MANUAL_CHRONICLE",UnitLevel("player"),mapID,x,y) end
    if entry then
        entry.manual=true; entry.level=entry.level or UnitLevel("player"); entry.mapID=entry.mapID or mapID
        entry.x=entry.x or x; entry.y=entry.y or y; entry.zone=entry.zone or GetZoneText(); entry.subZone=entry.subZone or GetSubZoneText()
        pending=entry
    end
    Screenshot()
    if pending then
        -- The game captures the picture a moment after this call, so the comment window must not appear before the
        -- capture is done (it would be in the picture). It opens on SCREENSHOT_SUCCEEDED / SCREENSHOT_FAILED, or after
        -- SHOT_WAIT seconds at the latest.
        local entryShown=pending
        local function show()
            if pending ~= entryShown then return end
            ci:SetText((pending.expectedFileName or MCF:T("Screenshot")).."\n"..(pending.zone or "")..
              ((pending.subZone and pending.subZone~="") and (" - "..pending.subZone) or "").."   |   Level "..tostring(pending.level or "?"))
            ce:SetText(""); cj:SetChecked(false); cf:Show(); cf:Raise(); ce:SetFocus()
        end
        local done=false
        afterShot=function() if not done then done=true; show() end end
        C_Timer.After(MCF.SHOT_WAIT,function() if afterShot and not done then afterShot=nil; done=true; show() end end)
    end
end
function MyCharForever_TakeManualChronicleScreenshot() if MCF and MCF.TakeManualChronicleScreenshot then MCF:TakeManualChronicleScreenshot() end end

-- Portrait picture (Portrait.lua): logged like any screenshot, reason PORTRAIT, plus the crop the website needs
-- (zoom, x, y). Works even when automatic screenshots are switched off: the player asked for this one.
-- onDone(entry) is called once the game has finished the capture (or after SHOT_WAIT at the latest).
function MCF:TakePortraitScreenshot(crop,onDone)
    if not MyCharForeverDB or not self.RecordScreenshot then if onDone then onDone(nil) end return end
    local entry=self:RecordScreenshot("PORTRAIT")
    if entry then entry.portrait=crop end
    Screenshot()
    local done=false
    local function finish() if done then return end done=true; if onDone then onDone(entry) end end
    afterShot=finish
    C_Timer.After(MCF.SHOT_WAIT,function() if afterShot==finish then afterShot=nil end finish() end)
end
