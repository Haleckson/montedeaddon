-- ForeverBiS.lua
-- ForeverBrowser Best-in-Slot browser.
-- UI/logic only.  Actual rankings belong in ForeverBiSData.lua.

ForeverBiS = ForeverBiS or {}
ForeverBiS.version = "Beta v1.020"

local CLASS_ORDER = {
    "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST",
    "SHAMAN","MAGE","WARLOCK","DRUID",
}

local CLASS_NAMES = {
    WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter",
    ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman",
    MAGE="Mage", WARLOCK="Warlock", DRUID="Druid",
}

local CLASS_ICONS = {
    WARRIOR="Interface\\Icons\\ClassIcon_Warrior",
    PALADIN="Interface\\Icons\\ClassIcon_Paladin",
    HUNTER="Interface\\Icons\\ClassIcon_Hunter",
    ROGUE="Interface\\Icons\\ClassIcon_Rogue",
    PRIEST="Interface\\Icons\\ClassIcon_Priest",
    SHAMAN="Interface\\Icons\\ClassIcon_Shaman",
    MAGE="Interface\\Icons\\ClassIcon_Mage",
    WARLOCK="Interface\\Icons\\ClassIcon_Warlock",
    DRUID="Interface\\Icons\\ClassIcon_Druid",
}

local SPECS = {
    WARRIOR={"ARMS","FURY","PROTECTION"},
    PALADIN={"HOLY","PROTECTION","RETRIBUTION"},
    HUNTER={"BEAST_MASTERY","MARKSMANSHIP","SURVIVAL"},
    ROGUE={"ASSASSINATION","COMBAT","SUBTLETY"},
    PRIEST={"DISCIPLINE","HOLY","SHADOW"},
    SHAMAN={"ELEMENTAL","ENHANCEMENT","RESTORATION"},
    MAGE={"ARCANE","FIRE","FROST"},
    WARLOCK={"AFFLICTION","DEMONOLOGY","DESTRUCTION"},
    DRUID={"BALANCE","FERAL","RESTORATION"},
}

local SPEC_NAMES = {
    ARMS="Arms", FURY="Fury", PROTECTION="Protection",
    HOLY="Holy", RETRIBUTION="Retribution",
    BEAST_MASTERY="Beast Mastery", MARKSMANSHIP="Marksmanship", SURVIVAL="Survival",
    ASSASSINATION="Assassination", COMBAT="Combat", SUBTLETY="Subtlety",
    DISCIPLINE="Discipline", SHADOW="Shadow",
    ELEMENTAL="Elemental", ENHANCEMENT="Enhancement", RESTORATION="Restoration",
    ARCANE="Arcane", FIRE="Fire", FROST="Frost",
    AFFLICTION="Affliction", DEMONOLOGY="Demonology", DESTRUCTION="Destruction",
    BALANCE="Balance", FERAL="Feral",
}

local CONTENT_ORDER={"PRE_RAID","RAID","PVP"}
local CONTENT_NAMES={PRE_RAID="PRE-RAID",RAID="RAID",PVP="PVP"}

local SLOT_ORDER={
    {"HEAD","Head"},
    {"NECK","Neck"},
    {"SHOULDER","Shoulder"},
    {"BACK","Back"},
    {"CHEST","Chest"},
    {"WRIST","Wrist"},
    {"HANDS","Hands"},
    {"WAIST","Waist"},
    {"LEGS","Legs"},
    {"FEET","Feet"},
    {"FINGER1","Finger 1"},
    {"FINGER2","Finger 2"},
    {"TRINKET1","Trinket 1"},
    {"TRINKET2","Trinket 2"},
    {"MAIN_HAND","Main Hand"},
    {"OFF_HAND","Off Hand"},
    {"RANGED","Ranged / Relic"},
}

local function ColorButton(frame, selected)
    local bg=frame:CreateTexture(nil,"BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    if selected then
        bg:SetVertexColor(0.12,0.09,0.025,1)
    else
        bg:SetVertexColor(0.025,0.03,0.05,1)
    end
    bg:SetAllPoints(frame)
    return bg
end

local function Label(parent,text,size,color)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    fs:SetText(text or "")
    if size and fs.SetFont then
        local font,_,flags=fs:GetFont()
        if font then fs:SetFont(font,size,flags) end
    end
    color=color or {0.85,0.87,0.92,1}
    fs:SetTextColor(color[1],color[2],color[3],color[4] or 1)
    return fs
end

local function Button(parent,text,width,height,selected)
    local b=CreateFrame("Button",nil,parent)
    b:SetSize(width,height)
    b:EnableMouse(true)
    local bg=ColorButton(b,selected)
    local t=Label(b,text,10,selected and {1,0.82,0.25,1} or {0.72,0.78,0.90,1})
    t:SetPoint("CENTER")
    b:SetScript("OnEnter",function()
        if not selected then bg:SetVertexColor(0.06,0.075,0.11,1) end
    end)
    b:SetScript("OnLeave",function()
        if not selected then bg:SetVertexColor(0.025,0.03,0.05,1) end
    end)
    return b
end

local function GetList(classKey,specKey,contentKey)
    -- Curated/verified data always wins when present.
    if ForeverBiSData and ForeverBiSData.lists then
        local c=ForeverBiSData.lists[classKey]
        local s=c and c[specKey]
        local list=s and s[contentKey] or nil
        if type(list)=="table" and next(list) then
            return list,"CURATED"
        end
    end

    -- Generated candidates are the fallback when no curated list exists.
    if ForeverBiSGenerated and ForeverBiSGenerated.lists then
        local c=ForeverBiSGenerated.lists[classKey]
        local s=c and c[specKey]
        local list=s and s[contentKey] or nil
        if type(list)=="table" and next(list) then
            return list,"GENERATED"
        end
    end

    return nil,nil
end

local function EntryItemID(entry)
    if type(entry)=="number" then return entry end
    if type(entry)=="table" then return tonumber(entry.itemID or entry.id) end
    return nil
end

local function EntryName(entry,itemID)
    if type(entry)=="table" and entry.name and entry.name~="" then return tostring(entry.name) end
    return itemID and ("Item "..tostring(itemID)) or "No item"
end

local function EntrySource(entry)
    if type(entry)=="table" then
        return tostring(entry.source or entry.location or "")
    end
    return ""
end

local function AlternativeIDs(entry)
    local out={}
    if type(entry)=="table" and type(entry.alternatives)=="table" then
        for _,v in ipairs(entry.alternatives) do
            local id=EntryItemID(v)
            if id then table.insert(out,id) end
        end
    end
    return out
end

function ForeverBiS.BuildList(ctx,classKey,specKey,contentKey)
    ctx.ClearPage()
    local parent=ctx.PageContent

    classKey=classKey or "WARRIOR"
    local specs=SPECS[classKey] or SPECS.WARRIOR
    specKey=specKey or specs[1]
    contentKey=contentKey or "PRE_RAID"

    local title=Label(parent,"BEST IN SLOT",22,{1,0.82,0.25,1})
    title:SetPoint("TOPLEFT",parent,"TOPLEFT",25,-22)

    local subtitle=Label(parent,"Forever-specific gear lists. Curated lists override generated candidate rankings.",11,{0.62,0.66,0.74,1})
    subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-7)

    -- Class selector: compact 3-column grid with class icons + names.
    -- This is easier to scan than a long row of text-only buttons.
    for i,key in ipairs(CLASS_ORDER) do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local selected=(key==classKey)
        local b=Button(parent,"",205,42,selected)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",25+(col*214),-72-(row*48))

        local icon=b:CreateTexture(nil,"ARTWORK")
        icon:SetSize(30,30)
        icon:SetPoint("LEFT",b,"LEFT",7,0)
        icon:SetTexture(CLASS_ICONS[key])

        local name=Label(b,string.upper(CLASS_NAMES[key]),10,selected and {1,0.82,0.25,1} or {0.78,0.82,0.90,1})
        name:SetPoint("LEFT",icon,"RIGHT",9,0)

        b:SetScript("OnClick",function()
            local first=(SPECS[key] or {})[1]
            ForeverBiS.BuildList(ctx,key,first,"PRE_RAID")
        end)
    end

    local y=-232
    local classTitle=Label(parent,string.upper(CLASS_NAMES[classKey]),15,{1,0.82,0.25,1})
    classTitle:SetPoint("TOPLEFT",parent,"TOPLEFT",25,y)

    y=y-34
    for i,key in ipairs(specs) do
        local b=Button(parent,string.upper(SPEC_NAMES[key] or key),150,27,key==specKey)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",25+((i-1)*158),y)
        b:SetScript("OnClick",function()
            ForeverBiS.BuildList(ctx,classKey,key,contentKey)
        end)
    end

    y=y-42
    for i,key in ipairs(CONTENT_ORDER) do
        local b=Button(parent,CONTENT_NAMES[key],120,27,key==contentKey)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",25+((i-1)*128),y)
        b:SetScript("OnClick",function()
            ForeverBiS.BuildList(ctx,classKey,specKey,key)
        end)
    end

    y=y-48
    local list,listKind=GetList(classKey,specKey,contentKey)

    if type(list)~="table" or not next(list) then
        local empty=Label(parent,
            "No verified "..CONTENT_NAMES[contentKey].." BiS data has been added for "..CLASS_NAMES[classKey].." - "..(SPEC_NAMES[specKey] or specKey).." yet.",
            12,{0.78,0.80,0.86,1})
        empty:SetPoint("TOPLEFT",parent,"TOPLEFT",25,y)
        empty:SetWidth(820)
        empty:SetJustifyH("LEFT")

        local note=Label(parent,
            "No curated or generated list is available for this selection yet.",
            11,{0.55,0.59,0.68,1})
        note:SetPoint("TOPLEFT",empty,"BOTTOMLEFT",0,-12)
        note:SetWidth(820)
        note:SetJustifyH("LEFT")
        parent:SetHeight(500)
        return
    end

    local statusText
    local statusColor
    if listKind=="CURATED" then
        statusText="CURATED / VERIFIED LIST"
        statusColor={0.45,1.00,0.55,1}
    else
        statusText="GENERATED GEAR CANDIDATES - NOT VERIFIED BIS"
        statusColor={1.00,0.72,0.25,1}
    end

    local status=Label(parent,statusText,10,statusColor)
    status:SetPoint("TOPLEFT",parent,"TOPLEFT",25,y)
    status:SetWidth(820)
    status:SetJustifyH("LEFT")
    y=y-26

    -- Character equipment-screen layout.
    local function GetItemIcon(itemID)
        if not itemID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
        if C_Item and C_Item.GetItemInfoInstant then
            local a,b,c,d,e,f,g,h,i,j=C_Item.GetItemInfoInstant(itemID)
            if type(e)=="string" or type(e)=="number" then return e end
            if type(j)=="string" or type(j)=="number" then return j end
        end
        if C_Item and C_Item.GetItemInfo then
            local a,b,c,d,e,f,g,h,i,j=C_Item.GetItemInfo(itemID)
            if type(j)=="string" or type(j)=="number" then return j end
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local sheet=CreateFrame("Frame",nil,parent)
    sheet:SetSize(820,455)
    sheet:SetPoint("TOPLEFT",parent,"TOPLEFT",25,y)
    local sheetBG=sheet:CreateTexture(nil,"BACKGROUND")
    sheetBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    sheetBG:SetVertexColor(0.008,0.012,0.020,0.96)
    sheetBG:SetAllPoints(sheet)

    local heading=Label(sheet,string.upper(CLASS_NAMES[classKey]).."  -  "..string.upper(SPEC_NAMES[specKey] or specKey),15,{1,0.82,0.25,1})
    heading:SetPoint("TOP",sheet,"TOP",0,-18)
    local mode=Label(sheet,CONTENT_NAMES[contentKey],11,{0.70,0.75,0.84,1})
    mode:SetPoint("TOP",heading,"BOTTOM",0,-5)
    local hint=Label(sheet,"Hover for details  |  Click item to open",9,{0.48,0.53,0.62,1})
    hint:SetPoint("TOP",mode,"BOTTOM",0,-7)

    -- 3D BiS gear preview.  Forever clients can expose different model APIs,
    -- so every model/equipment operation is guarded.
    local model
    local okModel=false

    local ok,created=pcall(function()
        return CreateFrame("DressUpModel",nil,sheet)
    end)
    if ok and created then
        model=created
        okModel=true
    else
        ok,created=pcall(function()
            return CreateFrame("PlayerModel",nil,sheet)
        end)
        if ok and created then
            model=created
            okModel=true
        end
    end

    if okModel and model then
        model:SetSize(270,315)
        model:SetPoint("TOP",sheet,"TOP",0,-72)
        model:EnableMouse(true)
        if model.EnableMouseWheel then model:EnableMouseWheel(true) end

        local modelBG=model:CreateTexture(nil,"BACKGROUND")
        modelBG:SetTexture("Interface\\Buttons\\WHITE8X8")
        modelBG:SetVertexColor(0.012,0.016,0.025,0.65)
        modelBG:SetAllPoints(model)

        local loaded=false
        if model.SetUnit then
            loaded=pcall(function() model:SetUnit("player") end)
        end

        if not loaded and model.SetDisplayInfo and UnitRace then
            -- Do not guess a display ID. If SetUnit is unavailable, leave the
            -- model safely blank rather than showing the wrong race/model.
        end

        if model.SetPosition then
            pcall(function() model:SetPosition(0,0,-0.15) end)
        end
        if model.SetFacing then
            pcall(function() model:SetFacing(0) end)
        end

        -- Dress only after SetUnit has finished loading the model. On this
        -- Forever client, dressing immediately after SetUnit is wiped when the
        -- character model finishes loading.
        local previewOrder={
            "HEAD","SHOULDER","BACK","CHEST","WRIST","HANDS","WAIST",
            "LEGS","FEET","MAIN_HAND","OFF_HAND","RANGED",
        }

        -- Native item info can be uncached on Forever. Queue the visible gear
        -- and only TryOn an item after C_Item reports usable information.
        local pendingGear={}
        for _,slotKey in ipairs(previewOrder) do
            local previewEntry=list[slotKey]
            local previewID=EntryItemID(previewEntry)
            if previewID then
                table.insert(pendingGear,{id=previewID,done=false})
            end
        end

        local function NativeItemReady(itemID)
            if not C_Item or not C_Item.GetItemInfo then
                -- If this build has no cache query, allow TryOn to be attempted.
                return true
            end

            local okInfo,a,b,c,d,e,f,g,h,i,j=pcall(C_Item.GetItemInfo,itemID)
            if not okInfo then return false end

            -- Forever builds vary in return layout. A non-empty item name or
            -- link is enough to tell us the native item cache has resolved it.
            if type(a)=="string" and a~="" then return true end
            if type(b)=="string" and b~="" then return true end
            return false
        end

        local function TryDressItem(itemID)
            local itemRef="item:"..tostring(itemID)

            if model.TryOn then
                local okTry=pcall(function() model:TryOn(itemRef) end)
                if okTry then return true end

                okTry=pcall(function() model:TryOn(itemID) end)
                if okTry then return true end
            end

            if model.Dress then
                local okDress=pcall(function() model:Dress(itemRef) end)
                if okDress then return true end
            end

            return false
        end

        local dressElapsed=0
        local dressStarted=false
        local dressFinished=false
        local dressTimeout=8.0
        local dressPoll=0

        local function BeginDress()
            if dressStarted then return end
            dressStarted=true

            -- This Forever client exposes Dress(), TryOn(), and resolved item
            -- cache data. Dress the player first, then TryOn replaces each slot.
            -- Starting from an undressed model prevented TryOn gear from
            -- appearing reliably on this client.
            if model.Dress then
                pcall(function() model:Dress() end)
            end
        end

        local oldUpdate=model:GetScript("OnUpdate")
        model:SetScript("OnUpdate",function(self,elapsed)
            if oldUpdate then oldUpdate(self,elapsed) end
            if dressFinished then return end

            elapsed=elapsed or 0
            dressElapsed=dressElapsed+elapsed
            dressPoll=dressPoll+elapsed

            -- Give SetUnit time to finish before Undress/TryOn.
            if dressElapsed>=0.45 then BeginDress() end
            if not dressStarted then return end

            if dressPoll>=0.20 then
                dressPoll=0
                local remaining=0

                for _,gear in ipairs(pendingGear) do
                    if not gear.done then
                        if NativeItemReady(gear.id) then
                            -- Mark complete after the native cache resolves.
                            -- If TryOn itself is unsupported, don't retry forever.
                            TryDressItem(gear.id)
                            gear.done=true
                        else
                            remaining=remaining+1
                        end
                    end
                end

                if remaining==0 or dressElapsed>=dressTimeout then
                    dressFinished=true
                end
            end
        end)

        local dragging=false
        local lastX=0
        model:SetScript("OnMouseDown",function(self,button)
            if button=="LeftButton" then
                dragging=true
                lastX=GetCursorPosition()
            end
        end)
        model:SetScript("OnMouseUp",function()
            dragging=false
        end)
        local dressUpdate=model:GetScript("OnUpdate")
        model:SetScript("OnUpdate",function(self,elapsed)
            if dressUpdate then dressUpdate(self,elapsed) end
            if dragging and self.SetFacing then
                local x=GetCursorPosition()
                local delta=(x-lastX)*0.012
                lastX=x
                local facing=0
                if self.GetFacing then
                    local okFacing,value=pcall(function() return self:GetFacing() end)
                    if okFacing and type(value)=="number" then facing=value end
                end
                pcall(function() self:SetFacing(facing+delta) end)
            end
        end)

        local zoom=0
        model:SetScript("OnMouseWheel",function(self,delta)
            zoom=zoom+(delta*0.12)
            if zoom>1.2 then zoom=1.2 end
            if zoom<-1.2 then zoom=-1.2 end
            if self.SetPosition then
                pcall(function() self:SetPosition(zoom,0,-0.15) end)
            end
        end)

        local previewLabel=Label(sheet,"3D GEAR PREVIEW",9,{0.58,0.63,0.72,1})
        previewLabel:SetPoint("TOP",model,"BOTTOM",0,-4)

    else
        local unavailable=Label(sheet,"3D preview unavailable on this client",10,{0.48,0.53,0.62,1})
        unavailable:SetPoint("CENTER",sheet,"CENTER",0,0)
    end

    local function EquipSlot(slotKey,slotName,xPos,yPos,width)
        local entry=list[slotKey]
        local itemID=EntryItemID(entry)
        local w=width or 250
        local b=CreateFrame("Button",nil,sheet)
        b:SetSize(w,44)
        b:SetPoint("TOPLEFT",sheet,"TOPLEFT",xPos,yPos)
        b:EnableMouse(true)
        local bg=b:CreateTexture(nil,"BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.025,0.030,0.045,1)
        bg:SetAllPoints(b)
        local iconBG=b:CreateTexture(nil,"BORDER")
        iconBG:SetTexture("Interface\\Buttons\\WHITE8X8")
        iconBG:SetVertexColor(0.38,0.30,0.08,1)
        iconBG:SetSize(42,42)
        iconBG:SetPoint("LEFT",b,"LEFT",1,0)
        local icon=b:CreateTexture(nil,"ARTWORK")
        icon:SetSize(38,38)
        icon:SetPoint("CENTER",iconBG,"CENTER",0,0)
        icon:SetTexture(entry and GetItemIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        local slot=Label(b,string.upper(slotName),8,{1,0.82,0.25,1})
        slot:SetPoint("TOPLEFT",b,"TOPLEFT",50,-5)
        slot:SetWidth(w-55)
        slot:SetJustifyH("LEFT")
        local itemName=Label(b,entry and EntryName(entry,itemID) or "Empty",10,entry and {0.90,0.92,1,1} or {0.40,0.44,0.52,1})
        itemName:SetPoint("TOPLEFT",slot,"BOTTOMLEFT",0,-4)
        itemName:SetWidth(w-55)
        itemName:SetJustifyH("LEFT")
        if entry and itemID then
            b:SetScript("OnEnter",function()
                bg:SetVertexColor(0.055,0.070,0.105,1)
                if GameTooltip then
                    GameTooltip:SetOwner(b,"ANCHOR_CURSOR")

                    local nativeReady=false
                    if C_Item and C_Item.GetItemInfo then
                        local okInfo,a,bInfo=pcall(C_Item.GetItemInfo,itemID)
                        if okInfo then
                            nativeReady=(type(a)=="string" and a~="") or
                                        (type(bInfo)=="string" and bInfo~="")
                        end
                    end

                    if nativeReady and GameTooltip.SetHyperlink then
                        GameTooltip:SetHyperlink("item:"..tostring(itemID))
                    else
                        if GameTooltip.ClearLines then GameTooltip:ClearLines() end
                        if GameTooltip.AddLine then
                            GameTooltip:AddLine(EntryName(entry,itemID),1,0.82,0.25)
                            GameTooltip:AddLine("Item ID: "..tostring(itemID),0.72,0.78,0.90)
                        end
                    end

                    local source=EntrySource(entry)
                    if source~="" and GameTooltip.AddLine then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Source: "..source,0.72,0.78,0.90,true)
                    end
                    local alternatives=AlternativeIDs(entry)
                    if #alternatives>0 and GameTooltip.AddLine then
                        GameTooltip:AddLine("Alternatives: "..table.concat(alternatives,", "),0.60,0.65,0.74,true)
                    end
                    GameTooltip:Show()
                end
            end)
            b:SetScript("OnLeave",function()
                bg:SetVertexColor(0.025,0.030,0.045,1)
                if GameTooltip then GameTooltip:Hide() end
            end)
            b:SetScript("OnClick",function() ctx.Navigate("forever://item/"..tostring(itemID)) end)
        end
    end

    local left={{"HEAD","Head"},{"NECK","Neck"},{"SHOULDER","Shoulder"},{"BACK","Back"},{"CHEST","Chest"},{"WRIST","Wrist"}}
    local right={{"HANDS","Hands"},{"WAIST","Waist"},{"LEGS","Legs"},{"FEET","Feet"},{"FINGER1","Finger 1"},{"FINGER2","Finger 2"},{"TRINKET1","Trinket 1"},{"TRINKET2","Trinket 2"}}
    for i,v in ipairs(left) do EquipSlot(v[1],v[2],14,-67-((i-1)*43),250) end
    for i,v in ipairs(right) do EquipSlot(v[1],v[2],556,-67-((i-1)*43),250) end
    EquipSlot("MAIN_HAND","Main Hand",105,-411,190)
    EquipSlot("OFF_HAND","Off Hand",315,-411,190)
    EquipSlot("RANGED","Ranged / Relic",525,-411,210)
    parent:SetHeight(math.max(810,math.abs(y)+500))
end

function ForeverBiS.BuildHome(ctx)
    ForeverBiS.BuildList(ctx,"WARRIOR","FURY","PRE_RAID")
end
