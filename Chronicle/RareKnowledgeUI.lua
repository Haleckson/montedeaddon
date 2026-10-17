local C = _G.Chronicle
local bg = "Interface\\Buttons\\WHITE8X8"
local frame, hero, filters, continentButton, continentPrev, continentNext, search, count, detail, cards, prev, next, empty
local filter, continent, query, page, selectedID = "all", "all", "", 1, nil
local selectedSpotRareID, selectedSpotIndex = nil, 1
local requestedItemData = {}
local PAGE_SIZE = 15
local gold, cream, muted = {1,.82,.1}, {.98,.94,.84}, {.86,.80,.70}
local filterNames = {{"all","Alle seltenen"},{"seen","Protokoll"},
    {"level","Meine Stufe"},{"zone","Diese Zone"},{"elite","Nur Elite"}}
local continentNames = {{"all","Alle Kontinente"},{"kalimdor","Kalimdor"},
    {"eastern","Östliche Königreiche"},{"other","Weitere Gebiete"}}
local dungeonNames = {
    brd="Schwarzfelstiefen",dm="Düsterbruch",dme="Düsterbruch Ost",
    gnomer="Gnomeregan",lbrs="Untere Schwarzfelsspitze",
    lordaeron="Ruinen von Lordaeron",mara="Maraudon",
    rfd="Hügel der Klingenhauer",rfk="Kral der Klingenhauer",
    sfk="Burg Schattenfang",smgy="Scharlachrotes Kloster: Friedhof",
    stocks="Das Verlies",stratlive="Stratholme",wc="Höhlen des Wehklagens",
    zf="Zul'Farrak",
}
-- Instanzgegner ohne Koordinaten öffnen die Region ihres Instanzeingangs.
local dungeonRegions = {
    brd=1427,dm=1444,dme=1444,gnomer=1426,lbrs=1427,
    lordaeron=1420,mara=1443,rfd=1413,rfk=1413,sfk=1421,
    smgy=1420,stocks=1453,stratlive=1423,wc=1413,zf=1446,
}

local function continentForMap(mapID)
    if not mapID then return nil end
    if C_Map and C_Map.GetMapInfo then
        local current=mapID
        for _=1,8 do
            if current==1414 then return "kalimdor" end
            if current==1415 then return "eastern" end
            local ok,info=pcall(C_Map.GetMapInfo,current)
            if not ok or not info or not info.parentMapID or info.parentMapID==current then break end
            current=info.parentMapID
        end
    end
    -- Klassische Zonenkarten bleiben auch ohne geladene Karten-API zuordenbar.
    if mapID>=1411 and mapID<=1413 or mapID>=1439 and mapID<=1452 or
        mapID==1454 or mapID==1456 or mapID==1457 then return "kalimdor" end
    if mapID>=1416 and mapID<=1438 or mapID==1453 or mapID==1455 or
        mapID==1458 then return "eastern" end
    return nil
end

local function font(parent,size,color)
    local fs=parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(C:FontPath(),size);fs:SetTextColor(unpack(color));fs:SetJustifyH("LEFT")
    return fs
end

local function mapName(id)
    if C_Map and C_Map.GetMapInfo and id then
        local ok,info=pcall(C_Map.GetMapInfo,id)
        if ok and info and info.name then return info.name end
    end
    return id and ("Karte #"..id) or "Ort unbekannt"
end

local function remainingText(seconds)
    seconds=math.max(0,math.ceil(seconds))
    local hours=math.floor(seconds/3600)
    local minutes=math.floor(seconds%3600/60)
    if hours>0 then return string.format("%dh %02dm",hours,minutes) end
    return string.format("%dm %02ds",minutes,seconds%60)
end

local function respawnState(id,rare,now)
    local death=C.char and C.char.rareDeaths and C.char.rareDeaths[id]
    if not death or type(death.time)~="number" then return nil end
    local resp=rare and rare.resp
    local first=resp and tonumber(resp[1])
    local last=resp and tonumber(resp[2] or resp[1])
    if not first or first<=0 then
        return nil,"TOD BEOBACHTET","Wiederkehr nicht erfasst"
    end
    last=math.max(first,last or first)
    local earliest=death.time+first-now
    local latest=death.time+last-now
    if earliest>0 then
        return "ab "..remainingText(earliest),"RESPAWN (SCHÄTZUNG)",
            "Frühestens in "..remainingText(earliest).."\nSpätestens in "..remainingText(latest)
    end
    if latest>0 then
        return "bis "..remainingText(latest),"RESPAWNFENSTER",
            "Wiederkehr möglich\nFenster bis ungefähr "..remainingText(latest)
    end
    return nil,"WIEDERKEHR MÖGLICH",
        "Letzter Tod: "..date("%d.%m. %H:%M",death.time)
end

local function updateTimerLabels()
    local now=time()
    if detail and detail:IsShown() and detail.rareID then
        detail.resetTimer:SetShown(C.char and C.char.rareDeaths and
            C.char.rareDeaths[detail.rareID]~=nil)
        local _,title,description=respawnState(detail.rareID,detail.rareData,now)
        if title then
            detail.spawnTitle:SetText(title)
            detail.respawn:SetText(description)
        else
            detail.spawnTitle:SetText("ERSCHEINEN")
            local resp=detail.rareData and detail.rareData.resp
            detail.respawn:SetText(resp and "Wiederkehr ungefähr: "..
                (math.floor((resp[1] or 0)/3600*10)/10).."–"..
                (math.floor((resp[2] or resp[1] or 0)/3600*10)/10).." Stunden" or
                "Wiederkehr: nicht erfasst")
        end
    end
    for _,card in ipairs(cards or {}) do
        if card:IsShown() and card.rareID then
            local rare=C.rareReferenceCatalog and C.rareReferenceCatalog[card.rareID]
            local label=respawnState(card.rareID,rare,now)
            card.timer:SetShown(label~=nil)
            if label then card.timer:SetText(label) end
            card.place:SetWidth(card:GetWidth()-(label and 115 or 20))
        end
    end
end

local slots = {[1]="Kopf",[2]="Hals",[3]="Schulter",[5]="Brust",[6]="Taille",
    [7]="Beine",[8]="Füße",[9]="Handgelenke",[10]="Hände",[11]="Finger",
    [12]="Schmuck",[13]="Waffe",[14]="Schild",[15]="Fernkampf",[16]="Rücken",
    [17]="Zweihand",[20]="Robe",[21]="Waffenhand",[22]="Schildhand",
    [23]="Nebenhand",[25]="Wurfwaffe",[26]="Fernkampf",[28]="Relikt"}

local function money(value,compact)
    if not value then return compact and "Wert unbekannt" or "Verkaufswert unbekannt" end
    if value<=0 then return "Kein Händlerwert" end
    return (compact and "Wert " or "Verkaufswert ")..C.Util.Money(value)
end

local function itemFacts(id)
    -- This table is built from ForeverGuide's item-only namespace, avoiding
    -- collisions with the separate NPC and quest ID namespaces.
    local reference=C.lootItemFacts and C.lootItemFacts[id]
    local name,quality,slot,icon,value=reference and reference.n,
        reference and reference.q,nil,nil,nil
    if GetItemInfo then
        local result={pcall(GetItemInfo,id)}
        if result[1] then
            name=result[2] or name
            quality=result[4] or quality
            slot=(_G[result[10]] or (result[10] and result[10]:gsub("^INVTYPE_",""))) or slot
            icon=result[11]
            value=result[12]
        end
    end
    if not slot and GetItemInfoInstant then
        local ok,_,_,_,location=pcall(GetItemInfoInstant,id)
        if ok and location and location~="" and location~="INVTYPE_NON_EQUIP" then
            slot=_G[location] or location:gsub("^INVTYPE_","")
        end
    end
    if not icon and GetItemInfoInstant then
        local ok,_,_,_,_,instantIcon=pcall(GetItemInfoInstant,id)
        if ok then icon=instantIcon end
    end
    if not icon and C_Item and C_Item.GetItemIconByID then
        local ok,itemIcon=pcall(C_Item.GetItemIconByID,id)
        if ok then icon=itemIcon end
    end
    if not icon and GetItemIcon then
        local ok,itemIcon=pcall(GetItemIcon,id)
        if ok then icon=itemIcon end
    end
    if not icon and not requestedItemData[id] and C_Item and C_Item.RequestLoadItemDataByID then
        requestedItemData[id]=true
        pcall(C_Item.RequestLoadItemDataByID,id)
    end
    local r,g,b=C:ItemQualityColor(id,quality)
    return name,C:ItemCategory(id,slot) or "Kein Ausrüstungsslot",icon,value,r,g,b
end

local function currentMap()
    if C_Map and C_Map.GetBestMapForUnit then
        local ok,id=pcall(C_Map.GetBestMapForUnit,"player")
        if ok then return id end
    end
end

local function sightings()
    local byID={}
    for name,entry in pairs(C.char.rares or {}) do
        if type(entry)=="table" and entry.npcID then
            byID[entry.npcID]={name=name,entry=entry}
        end
    end
    return byID
end

local function matches(...)
    if query=="" then return true end
    for i=1,select("#",...) do
        local value=select(i,...)
        if value and tostring(value):lower():find(query,1,true) then return true end
    end
    return false
end

local function firstSpot(row,map)
    for _,spot in ipairs(row.spots or {}) do if map and spot[1]==map then return spot end end
    return row.spots and row.spots[1]
end

local function build()
    local list,seen={},sightings()
    local map=currentMap()
    local level=UnitLevel and tonumber(UnitLevel("player")) or 0
    local settings=C.db and C.db.settings or {}
    local range=tonumber(settings.rareLevelRange) or 5
    for id,record in pairs(C.rareReferenceCatalog or {}) do
        local observed=seen[id]
        local name=observed and observed.name or record.n or ("Rare #"..id)
        local spot=firstSpot(record,map)
        local extra=C.rareExtra and C.rareExtra[id]
        local regionMap=spot and spot[1] or extra and dungeonRegions[extra.dungeon]
        local entryContinent=continentForMap(regionMap)
        local zone=spot and mapName(spot[1]) or
            (extra and extra.dungeon and dungeonNames[extra.dungeon]) or "Ort unbekannt"
        local min,max=record.l1 or 0,record.l2 or record.l1 or 0
        local allowed=filter=="all" or
            filter=="zone" and spot and spot[1]==map or
            filter=="level" and min<=level+range and max>=level-range or
            filter=="elite" and record.elite or
            filter=="seen" and observed
        if allowed and (continent=="all" or entryContinent==continent or
            continent=="other" and not entryContinent) and
            matches(name,record.n,id,zone) then
            list[#list+1]={id=id,data=record,name=name,spot=spot,zone=zone,
                observed=observed,level=min,near=spot and spot[1]==map,
                regionMap=regionMap}
        end
    end
    for id,observed in pairs(seen) do
        if not (C.rareReferenceCatalog or {})[id] and
            (filter=="all" or filter=="seen") and
            (continent=="all" or continent=="other") and
            matches(observed.name,id,observed.entry.zone) then
            local entry=observed.entry
            list[#list+1]={id=id,data={n=observed.name,l1=0,l2=0},name=observed.name,
                zone=entry.zone or "Ort unbekannt",observed=observed,level=0}
        end
    end
    table.sort(list,function(a,b)
        if a.near~=b.near then return a.near and true or false end
        if (a.observed~=nil)~=(b.observed~=nil) then return a.observed~=nil end
        if a.level~=b.level then return a.level<b.level end
        return a.name<b.name
    end)
    return list
end

local function highlightSpots()
    for _,button in ipairs(detail.spotButtons) do
        local active=button.spotIndex==selectedSpotIndex
        button.marker:SetShown(active)
        button.label:SetTextColor(active and 1 or .88,
            active and .82 or .82,active and .1 or .69)
    end
end

local function layoutSpots(entry,mainY,textWidth)
    for _,button in ipairs(detail.spotButtons) do button:Hide() end
    for _,label in ipairs(detail.spotGroupLabels) do label:Hide() end
    local spots=entry.data.spots or {}
    if #spots<=1 then
        detail.place:Show()
        local spot=spots[1]
        local text=entry.zone
        if spot then
            text=mapName(spot[1])
            if not (C.db and C.db.settings and C.db.settings.rareShowCoordinates==false) then
                text=text..string.format(" %.1f / %.1f",spot[2],spot[3])
            end
        end
        detail.place:SetText(text)
        detail.place:SetWidth(textWidth)
        return math.max(14,detail.place:GetStringHeight() or 14)
    end
    detail.place:Hide()
    local top=mainY+24
    local y=top
    for index,spot in ipairs(spots) do
        local button=detail.spotButtons[index]
        if not button then
            button=CreateFrame("Button",nil,detail)
            button.marker=button:CreateTexture(nil,"ARTWORK")
            button.marker:SetTexture(bg)
            button.marker:SetVertexColor(1,.82,.1,.95)
            button.marker:SetPoint("TOPLEFT",0,-2)
            button.marker:SetPoint("BOTTOMLEFT",0,2)
            button.marker:SetWidth(2)
            button.label=font(button,11,cream)
            button.label:SetPoint("LEFT",6,0)
            button:SetScript("OnClick",function(self)
                selectedSpotIndex=self.spotIndex
                detail.mapButton.mapID=self.mapID
                detail.mapButton.x=self.x
                detail.mapButton.y=self.y
                highlightSpots()
                if C.OpenBlizzardMap then C:OpenBlizzardMap(self.mapID,self.x,self.y) end
            end)
            button:SetScript("OnEnter",function(self)
                self.label:SetTextColor(1,.82,.1)
            end)
            button:SetScript("OnLeave",highlightSpots)
            detail.spotButtons[index]=button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT",detail,"TOPLEFT",20,-y)
        button:SetSize(textWidth,20)
        button.label:SetWidth(textWidth-8)
        button.spotIndex=index
        button.mapID=spot[1]
        button.x=spot[2]
        button.y=spot[3]
        local name=mapName(spot[1])
        button.label:SetText((C.db and C.db.settings and
            C.db.settings.rareShowCoordinates==false) and
            string.format("%d. %s",index,name) or
            string.format("%d. %s  %.1f / %.1f",index,name,spot[2],spot[3]))
        button:Show()
        y=y+21
    end
    highlightSpots()
    return y-top
end

local function setDetail(entry,width)
    if not entry then detail:Hide();return 0 end
    detail:Show();detail:SetWidth(width)
    detail.rareID,detail.rareData=entry.id,entry.data
    detail.resetTimer.rareID=entry.id
    detail.caption:SetText("CHRONICLE  /  RARE-DOSSIER")
    detail.title:SetText(entry.name)
    detail.title:SetWidth(math.max(180,width-270))
    local rare=entry.data
    local levels=(rare.l1 and rare.l1>0) and (rare.l1==rare.l2 and tostring(rare.l1) or
        rare.l1.."–"..(rare.l2 or rare.l1)) or "?"
    detail.meta:SetText("STUFE "..levels..(rare.elite and "  ·  ELITE" or "")..
        (entry.observed and "  ·  ENTDECKT" or ""))
    detail.status:SetText(entry.observed and "VON DIR ENTDECKT" or "SELTENER GEGNER")
    detail.status:SetTextColor(entry.observed and .55 or 1,
        entry.observed and .83 or .82,entry.observed and .42 or .1)
    if selectedSpotRareID~=entry.id then
        selectedSpotRareID=entry.id
        selectedSpotIndex=1
    end
    if selectedSpotIndex>#(rare.spots or {}) then selectedSpotIndex=1 end
    local extra=C.rareExtra and C.rareExtra[entry.id] or {}
    local traits={}
    for i,note in ipairs(extra.notes or {}) do
        if i>2 then break end
        if note~="Aus zusätzlichen Referenzdaten erfasst." then
            traits[#traits+1]=note
        end
    end
    detail.traits:SetText(table.concat(traits,"  "))
    detail.specialTitle:SetShown(#traits>0)
    detail.traits:SetShown(#traits>0)
    detail.traits:SetWidth(width-40)
    local shown=rare.model and detail.model.SetDisplayInfo and
        pcall(detail.model.SetDisplayInfo,detail.model,rare.model)
    local hasModel=shown
    detail.modelBox:SetShown(hasModel and true or false)
    detail.model:SetShown(shown and true or false)
    detail.modelFallback:Hide()
    detail.motif:SetShown(not hasModel)
    local spellCount=math.min(#(rare.spells or {}),#detail.abilityButtons)
    local middleColumn=width>=690
    local modelWidth=math.min(300,math.max(220,math.floor(width*.42)))
    local modelBottom=154+modelWidth
    local mapBottom=modelBottom+30
    detail.modelBox:SetSize(modelWidth,modelWidth)
    detail.model:SetSize(modelWidth-8,modelWidth-36)
    detail.traits:SetWidth(hasModel and
        math.max(150,width-modelWidth-55) or width-40)
    detail.specialTitle:ClearAllPoints()
    detail.specialTitle:SetPoint("TOPLEFT",20,-170)
    detail.traits:ClearAllPoints()
    detail.traits:SetPoint("TOPLEFT",20,-194)
    local traitsHeight=#traits>0 and math.max(14,detail.traits:GetStringHeight() or 14) or 0
    local mainY=#traits>0 and math.max(254,194+traitsHeight+24) or 186
    detail.where:ClearAllPoints()
    detail.where:SetPoint("TOPLEFT",20,-mainY)
    detail.place:ClearAllPoints()
    detail.place:SetPoint("TOPLEFT",20,-mainY-26)
    local abilitiesX=middleColumn and math.max(205,math.floor(width*.30)) or 20
    local textWidth=middleColumn and math.max(150,abilitiesX-32) or
        (hasModel and math.max(150,width-modelWidth-38) or width-42)
    local abilityWidth=middleColumn and
        math.max(125,width-abilitiesX-(hasModel and modelWidth+28 or 30)) or width-42
    local placeHeight=layoutSpots(entry,mainY,textWidth)
    local placeBottom=mainY+26+placeHeight
    local mapTop=math.max(mainY+59,placeBottom+10)
    local seenY=hasModel and math.max(mainY+62,placeBottom+20) or
        math.max(mainY+104,mapTop+45)
    local abilitiesY=middleColumn and mainY or
        math.max(hasModel and mapBottom+18 or 386,seenY+62)
    detail.abilitiesTitle:ClearAllPoints()
    detail.abilitiesTitle:SetPoint("TOPLEFT",abilitiesX,-abilitiesY)
    detail.noAbilities:ClearAllPoints()
    detail.noAbilities:SetPoint("TOPLEFT",abilitiesX,-abilitiesY-27)
    if spellCount==0 then detail.noAbilities:Show() else detail.noAbilities:Hide() end
    detail.noAbilities:SetWidth(abilityWidth)
    for i,button in ipairs(detail.abilityButtons) do
        local spell=i<=spellCount and rare.spells[i]
        button:SetShown(spell and true or false)
        if spell then
            local note
            for _,candidate in ipairs(extra.spells or {}) do
                if candidate[1]==spell[1] then note=candidate;break end
            end
            local iconName=note and note[3]
            button.spellID=spell[1]
            button.spellName=spell[2]
            button.description=note and note[2]
            button.icon:SetTexture(iconName and ("Interface\\Icons\\"..iconName) or
                (GetSpellTexture and GetSpellTexture(spell[1])) or
                "Interface\\Icons\\INV_Misc_QuestionMark")
            button.name:SetText(spell[2]);button.name:SetWidth(abilityWidth-44)
            button:SetWidth(abilityWidth)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT",detail,"TOPLEFT",abilitiesX,-abilitiesY-27-(i-1)*34)
        end
    end
    detail.seenTitle:ClearAllPoints()
    detail.seenTitle:SetPoint("TOPLEFT",20,-seenY)
    detail.seen:ClearAllPoints()
    detail.seen:SetPoint("TOPLEFT",20,-seenY-24)
    detail.seen:SetWidth(textWidth)
    local observation=entry.observed and entry.observed.entry
    detail.seen:SetText(observation and
        ((observation.sightings or 1).." Sichtung(en)  ·  zuletzt "..
        (observation.lastSeen and date("%d.%m.%Y %H:%M",observation.lastSeen) or "unbekannt")) or
        "Noch nicht persönlich entdeckt")
    local showLoot=not (C.db and C.db.settings and C.db.settings.rareShowLoot==false)
    local abilityBottom=abilitiesY+27+math.max(1,spellCount)*34
    local lootY=math.max(seenY+76,abilityBottom+26)
    detail.lootTitle:ClearAllPoints()
    detail.lootTitle:SetPoint("TOPLEFT",18,-lootY)
    detail.lootTitle:SetShown(showLoot)
    local lootList={}
    for _,loot in ipairs(rare.loot or {}) do lootList[#lootList+1]=loot end
    for _,id in ipairs(extra.extraLoot or {}) do
        local duplicate=false
        for _,loot in ipairs(lootList) do if loot[1]==id then duplicate=true;break end end
        if not duplicate then lootList[#lootList+1]={id} end
    end
    local verifiedLoot={}
    if showLoot then
        for _,loot in ipairs(lootList) do
            local name,slot,icon,value,r,g,b=itemFacts(loot[1])
            if type(name)=="string" and name~="" then
                verifiedLoot[#verifiedLoot+1]={loot=loot,name=name,slot=slot,
                    icon=icon,value=value,r=r,g=g,b=b}
            end
        end
    end
    detail.noLoot:SetText(#lootList==0 and "Keine besondere Beute erfasst." or
        "Weitere Beuteeinträge werden geladen.")
    detail.noLoot:SetShown(showLoot and #verifiedLoot==0)
    detail.noLoot:ClearAllPoints()
    detail.noLoot:SetPoint("TOPLEFT",18,-lootY-30)
    local rowTop=lootY+34
    for i,button in ipairs(detail.lootButtons) do
        local row=showLoot and verifiedLoot[i]
        button:SetShown(row~=nil)
        if row then
            local loot=row.loot
            button.itemID=loot[1]
            button.itemChance,button.itemSource=loot[2],rare.n
            local name,slot,icon,value,r,g,b=row.name,row.slot,row.icon,
                row.value,row.r,row.g,row.b
            button.itemName,button.qualityR,button.qualityG,button.qualityB=name,r,g,b
            local narrow=hasModel and rowTop<mapBottom+8
            local rowWidth=narrow and math.max(225,width-modelWidth-50) or width-36
            local hasSlot=slot and slot~="Kein Ausrüstungsslot"
            local rowHeight=48
            local chanceValue=loot[2] and string.format("%.1f",loot[2]):gsub("%.",",")
            local chance=chanceValue and ("Chance "..chanceValue.."%") or
                "Chance unbekannt"
            button.icon:SetShown(icon~=nil)
            if icon then button.icon:SetTexture(icon) end
            button.name:ClearAllPoints()
            button.name:SetPoint("TOPLEFT",button,"TOPLEFT",icon and 48 or 4,-4)
            button.meta:ClearAllPoints()
            button.meta:SetPoint("TOPLEFT",button,"TOPLEFT",icon and 48 or 4,-27)
            button.name:SetText(name);button.name:SetTextColor(r,g,b)
            button.name:SetWidth(rowWidth-(icon and 60 or 12))
            button.meta:SetFont(C:FontPath(),12)
            local metaWidth=rowWidth-(icon and 60 or 12)
            button.meta:SetWidth(1000)
            button.meta:SetText(chance..(hasSlot and ("  ·  "..slot) or "")..
                (value and ("  ·  "..money(value,narrow)) or ""))
            if narrow and button.meta:GetStringWidth()>metaWidth then
                button.meta:SetText(chance..(hasSlot and ("  ·  "..slot) or "")..
                    (value and ("  ·  "..C.Util.Money(value)) or ""))
            end
            if button.meta:GetStringWidth()>metaWidth then
                button.meta:SetFont(C:FontPath(),11)
            end
            button.meta:SetWidth(metaWidth)
            button.itemMeta=button.meta:GetText()
            button:SetSize(rowWidth,rowHeight)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT",detail,"TOPLEFT",18,-rowTop)
            rowTop=rowTop+rowHeight+3
        end
    end
    detail.mapButton:Show()
    local selectedSpot=rare.spots and rare.spots[selectedSpotIndex]
    detail.mapButton:SetEnabled(selectedSpot~=nil or entry.regionMap~=nil)
    detail.mapButton:SetText(selectedSpot and "AUF KARTE ZEIGEN" or
        entry.regionMap and "REGION AUF KARTE ZEIGEN" or "KEIN KARTENPUNKT")
    detail.mapButton.mapID=selectedSpot and selectedSpot[1] or entry.regionMap
    detail.mapButton.x=selectedSpot and selectedSpot[2]
    detail.mapButton.y=selectedSpot and selectedSpot[3]
    detail.mapButton:ClearAllPoints()
    if hasModel then detail.mapButton:SetPoint("TOP",detail.modelBox,"BOTTOM",0,-5)
    else detail.mapButton:SetPoint("TOPLEFT",detail,"TOPLEFT",20,-mapTop) end
    local height=math.max(600,hasModel and mapBottom+58 or 420,
        rowTop+24)
    detail:SetHeight(height)
    return height
end

local function refresh(width)
    if not frame or not frame:IsShown() then return end
    width=width or frame:GetWidth()
    hero:SetWidth(width-8)
    local compact=width<770
    local columns=compact and 3 or 5
    hero:SetHeight(compact and 137 or 111)
    C:SetHeroMotif(hero,"Loot",.13)
    hero.intro:SetWidth(width-330)
    hero.intro:SetShown(width>=640)
    search:SetWidth(math.min(275,math.max(180,math.floor(width*.32))))
    local filterWidth=compact and (width-52)/3 or (width-245)/5
    for i,button in ipairs(filters) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT",hero,"TOPLEFT",18+((i-1)%columns)*(filterWidth+4),
            -74-math.floor((i-1)/columns)*26)
        button:SetSize(filterWidth,23)
        button:GetFontString():SetFont(C:FontPath(),12)
        local active=button.mode==filter
        button:SetBackdropColor(active and .095 or .038,
            active and .082 or .036,active and .061 or .032,.96)
        button:GetFontString():SetTextColor(active and 1 or .90,
            active and .82 or .83,active and .1 or .71)
    end
    continentPrev:ClearAllPoints()
    if compact then
        continentPrev:SetPoint("TOPLEFT",hero,"TOPLEFT",18+2*(filterWidth+4),-100)
    else
        continentPrev:SetPoint("TOPLEFT",hero,"TOPLEFT",18+5*(filterWidth+4),-74)
    end
    local continentWidth=compact and filterWidth or 190
    continentPrev:SetSize(22,23)
    continentButton:ClearAllPoints()
    continentButton:SetPoint("TOPLEFT",continentPrev,"TOPRIGHT",0,0)
    continentButton:SetSize(continentWidth-44,23)
    continentButton:GetFontString():SetFont(C:FontPath(),12)
    continentNext:ClearAllPoints()
    continentNext:SetPoint("TOPLEFT",continentButton,"TOPRIGHT",0,0)
    continentNext:SetSize(22,23)
    for _,pair in ipairs(continentNames) do
        if pair[1]==continent then
            continentButton:SetText(pair[2])
            break
        end
    end
    continentButton:SetBackdropColor(continent~="all" and .095 or .038,
        continent~="all" and .082 or .036,continent~="all" and .061 or .032,.96)
    local list=build()
    local pages=math.max(1,math.ceil(#list/PAGE_SIZE))
    page=math.min(page,pages)
    count:SetText(#list.." TREFFER  ·  "..page.."/"..pages)
    prev:SetEnabled(page>1);next:SetEnabled(page<pages)
    local selected
    if selectedID then
        for index=(page-1)*PAGE_SIZE+1,math.min(#list,page*PAGE_SIZE) do
            local entry=list[index]
            if entry.id==selectedID then selected=entry;break end
        end
    end
    if not selected and #list>0 then
        selected=list[(page-1)*PAGE_SIZE+1];selectedID=selected.id
    end
    local listWidth=compact and width-8 or math.max(245,math.floor(width*.34))
    local detailWidth=compact and width-8 or width-listWidth-18
    local y=hero:GetHeight()+12
    count:ClearAllPoints()
    count:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-y-3)
    count:SetWidth(math.max(70,listWidth-174))
    prev:ClearAllPoints();prev:SetPoint("TOPLEFT",frame,"TOPLEFT",listWidth-162,-y)
    next:ClearAllPoints();next:SetPoint("TOPLEFT",frame,"TOPLEFT",listWidth-80,-y)
    detail:ClearAllPoints()
    detail:SetPoint("TOPLEFT",frame,"TOPLEFT",compact and 4 or listWidth+13,
        compact and -y-600 or -y)
    local detailHeight=setDetail(selected,detailWidth)
    local used=0
    if empty then empty:Hide() end
    if #list==0 then
        if not empty then empty=font(frame,14,cream);empty:SetJustifyH("CENTER") end
        empty:ClearAllPoints();empty:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-y-29)
        empty:SetWidth(listWidth-30)
        empty:SetText("Keine passenden seltenen Kreaturen gefunden.")
        empty:Show()
    end
    local cardWidth=listWidth-8
    for index=(page-1)*PAGE_SIZE+1,math.min(#list,page*PAGE_SIZE) do
        used=used+1
        local entry=list[index]
        local card=cards[used]
        if not card then
            card=CreateFrame("Button",nil,frame)
            card.selection=card:CreateTexture(nil,"BACKGROUND")
            card.selection:SetTexture(bg)
            card.selection:SetVertexColor(.09,.085,.075,.35)
            card.selection:SetAllPoints()
            card.accent=card:CreateTexture(nil,"ARTWORK")
            card.accent:SetTexture(bg);card.accent:SetVertexColor(1,.75,.12,.95)
            card.accent:SetPoint("TOPLEFT",0,-3);card.accent:SetPoint("BOTTOMLEFT",0,3)
            card.accent:SetWidth(2)
            card.name=font(card,14,cream);card.name:SetPoint("TOPLEFT",10,-3)
            card.place=font(card,12,muted);card.place:SetPoint("TOPLEFT",10,-22)
            card.level=font(card,11,gold);card.level:SetPoint("TOPRIGHT",-9,-7)
            card.level:SetJustifyH("RIGHT")
            card.timer=font(card,10,gold)
            card.timer:SetPoint("TOPRIGHT",-9,-23)
            card.timer:SetWidth(108)
            card.timer:SetJustifyH("RIGHT")
            card.rule=card:CreateTexture(nil,"ARTWORK")
            card.rule:SetTexture(bg);card.rule:SetVertexColor(.45,.32,.14,.55)
            card.rule:SetPoint("BOTTOMLEFT",5,0);card.rule:SetPoint("BOTTOMRIGHT",-5,0)
            card.rule:SetHeight(C:RuleThickness())
            card:SetScript("OnClick",function(self)
                selectedID=self.rareID;refresh()
            end)
            card:SetScript("OnEnter",function(self)
                self.accent:Show()
                self.accent:SetAlpha(self.rareID==selectedID and 1 or .55)
            end)
            card:SetScript("OnLeave",function(self)
                self.accent:SetShown(self.rareID==selectedID)
                self.accent:SetAlpha(1)
            end)
            cards[used]=card
        end
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-y-27-(used-1)*41)
        card:SetSize(cardWidth,40)
        card.selection:SetShown(entry.id==selectedID)
        card.accent:SetShown(entry.id==selectedID)
        card.accent:SetAlpha(1)
        card.name:SetText(entry.name)
        card.name:SetWidth(cardWidth-89)
        card.name:SetTextColor(entry.observed and 1 or .96,
            entry.observed and .82 or .91,entry.observed and .1 or .78)
        local level=entry.data.l1 and entry.data.l1>0 and tostring(entry.data.l1) or "?"
        card.level:SetText("STUFE "..level)
        card.place:SetText((entry.data.elite and "Elite  ·  " or "")..entry.zone)
        card.place:SetWidth(cardWidth-20)
        card.rareID=entry.id;card:Show()
    end
    for i=used+1,#cards do cards[i]:Hide() end
    updateTimerLabels()
    local listHeight=27+used*41
    frame:SetHeight(y+math.max(600,detailHeight,listHeight)+
        (compact and detailHeight+8 or 0)+12)
    if frame:GetParent() then frame:GetParent():SetHeight(frame:GetHeight()+8) end
end

function C:HideRareKnowledge() if frame then frame:Hide() end end

function C:ShowRareKnowledge(parent,width)
    if not frame then
        frame=CreateFrame("Frame",nil,parent);frame:SetPoint("TOPLEFT",0,0)
        frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        frame:SetScript("OnEvent",function() if frame:IsShown() then refresh() end end)
        frame.timerElapsed=0
        frame:SetScript("OnUpdate",function(self,elapsed)
            self.timerElapsed=self.timerElapsed+elapsed
            if self.timerElapsed>=1 then
                self.timerElapsed=0
                updateTimerLabels()
            end
        end)
        filters,cards={},{}
        hero=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        hero:SetPoint("TOPLEFT",4,0)
        hero:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
        hero:SetBackdropColor(.035,.034,.032,.98);hero:SetBackdropBorderColor(.59,.44,.17,.9)
        C:ApplyMaterial(hero,.28);C:OrnateCorners(hero)
        C:SetHeroMotif(hero,"Loot",.13)
        hero.caption=font(hero,10,gold);hero.caption:SetPoint("TOPLEFT",20,-14)
        hero.caption:SetText("CHRONICLE  /  SAMMLUNG")
        hero.title=font(hero,23,cream);hero.title:SetPoint("TOPLEFT",20,-32)
        hero.title:SetText("Rare-Gegner")
        hero.intro=font(hero,12,muted);hero.intro:SetPoint("TOPLEFT",21,-59)
        hero.intro:SetText("Fundorte, Beute und deine eigenen Begegnungen.")
        search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate")
        search:SetSize(275,24);search:SetPoint("TOPRIGHT",-23,-26);search:SetAutoFocus(false)
        search.placeholder=font(search,11,muted)
        search.placeholder:SetPoint("LEFT",7,0);search.placeholder:SetText("Name des Gegners ...")
        search:SetScript("OnTextChanged",function(self)
            query=self:GetText():lower();page=1;selectedID=nil
            self.placeholder:SetShown(query=="");refresh()
        end)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        for i,pair in ipairs(filterNames) do
            local button=CreateFrame("Button",nil,hero,"BackdropTemplate")
            C:StyleChronicleButton(button);button.mode=pair[1];button:SetText(pair[2])
            button:SetScript("OnClick",function()
                filter=pair[1];page=1;selectedID=nil
                refresh()
            end)
            filters[i]=button
        end
        local function stepContinent(direction)
            local current=1
            for i,pair in ipairs(continentNames) do
                if pair[1]==continent then current=i;break end
            end
            local nextIndex=((current-1+direction)%#continentNames)+1
            continent=continentNames[nextIndex][1]
            page=1;selectedID=nil;refresh()
        end
        continentPrev=CreateFrame("Button",nil,hero,"BackdropTemplate")
        C:StyleChronicleButton(continentPrev)
        continentPrev:SetText("‹")
        continentPrev:SetScript("OnClick",function() stepContinent(-1) end)
        continentButton=CreateFrame("Button",nil,hero,"BackdropTemplate")
        C:StyleChronicleButton(continentButton)
        continentButton:SetScript("OnClick",function() stepContinent(1) end)
        continentNext=CreateFrame("Button",nil,hero,"BackdropTemplate")
        C:StyleChronicleButton(continentNext)
        continentNext:SetText("›")
        continentNext:SetScript("OnClick",function() stepContinent(1) end)
        count=font(frame,11,gold)
        prev=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(prev);prev:SetSize(78,20)
        prev:SetText("‹ Zurück");prev:SetScript("OnClick",function() page=math.max(1,page-1);refresh() end)
        next=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(next);next:SetSize(78,20)
        next:SetText("Weiter ›");next:SetScript("OnClick",function() page=page+1;refresh() end)
        detail=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        detail:SetHeight(635)
        detail:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
        detail:SetBackdropColor(.03,.029,.027,.98)
        detail:SetBackdropBorderColor(.59,.44,.17,.9)
        C:ApplyMaterial(detail,.32);C:OrnateCorners(detail)
        detail.headerBand=detail:CreateTexture(nil,"ARTWORK")
        detail.headerBand:SetTexture(bg);detail.headerBand:SetVertexColor(.20,.12,.055,.0)
        detail.headerBand:SetPoint("TOPLEFT",4,-4);detail.headerBand:SetPoint("TOPRIGHT",-4,-4)
        detail.headerBand:SetHeight(55)
        detail.headerRule=detail:CreateTexture(nil,"ARTWORK")
        detail.headerRule:SetTexture(bg);detail.headerRule:SetVertexColor(.52,.36,.14,.75)
        detail.headerRule:SetPoint("TOPLEFT",18,-112)
        detail.headerRule:SetPoint("TOPRIGHT",-18,-112)
        detail.headerRule:SetHeight(C:RuleThickness())
        detail.caption=font(detail,10,gold);detail.caption:SetPoint("TOPLEFT",19,-15)
        detail.title=font(detail,21,cream);detail.title:SetPoint("TOPLEFT",19,-43)
        detail.meta=font(detail,11,muted);detail.meta:SetPoint("TOPLEFT",20,-82)
        detail.status=font(detail,12,gold);detail.status:SetPoint("TOPLEFT",20,-130)
        detail.resetTimer=CreateFrame("Button",nil,detail,"BackdropTemplate")
        C:StyleChronicleButton(detail.resetTimer)
        detail.resetTimer:SetSize(142,21)
        detail.resetTimer:SetPoint("TOPRIGHT",-20,-124)
        detail.resetTimer:SetText("TIMER ZURÜCKSETZEN")
        detail.resetTimer:SetScript("OnClick",function(self)
            if C.char and C.char.rareDeaths and self.rareID then
                C.char.rareDeaths[self.rareID]=nil
                updateTimerLabels()
                C:Fire("DATA_CHANGED","rareDeath")
            end
        end)
        detail.modelBox=CreateFrame("Frame",nil,detail)
        detail.modelBox:SetPoint("TOPRIGHT",-17,-154)
        detail.modelBox:SetSize(300,300)
        detail.motif=detail:CreateTexture(nil,"ARTWORK")
        detail.motif:SetTexture("Interface\\AddOns\\Chronicle\\LotusEmblem")
        detail.motif:SetSize(132,132)
        detail.motif:SetPoint("CENTER",detail.modelBox,"CENTER",0,0)
        detail.motif:SetAlpha(.27)
        detail.model=CreateFrame("PlayerModel",nil,detail.modelBox)
        detail.model:SetPoint("TOPLEFT",4,-4);detail.model:SetSize(292,264)
        detail.modelFallback=font(detail.modelBox,10,muted)
        detail.modelFallback:SetPoint("CENTER",0,20)
        detail.modelFallback:SetText("Modell nicht verfügbar")
        detail.where=font(detail,12,gold)
        detail.where:SetPoint("TOPLEFT",20,-176);detail.where:SetText("WO")
        detail.place=font(detail,12,cream);detail.place:SetPoint("TOPLEFT",20,-200)
        detail.spotButtons={}
        detail.spotGroupLabels={}
        detail.spawnTitle=font(detail,12,gold)
        detail.spawnTitle:SetPoint("TOPRIGHT",-20,-43)
        detail.spawnTitle:SetWidth(205)
        detail.spawnTitle:SetJustifyH("RIGHT")
        detail.spawnTitle:SetText("ERSCHEINEN")
        detail.respawn=font(detail,11,muted)
        detail.respawn:SetPoint("TOPRIGHT",-20,-67)
        detail.respawn:SetWidth(205)
        detail.respawn:SetJustifyH("RIGHT")
        detail.seenTitle=font(detail,12,gold)
        detail.seenTitle:SetPoint("TOPLEFT",20,-317)
        detail.seenTitle:SetText("VON DIR GESEHEN")
        detail.seen=font(detail,12,cream);detail.seen:SetPoint("TOPLEFT",20,-341)
        detail.specialTitle=font(detail,12,gold)
        detail.specialTitle:SetPoint("TOPLEFT",20,-443)
        detail.specialTitle:SetText("BESONDERHEITEN")
        detail.traits=font(detail,12,muted);detail.traits:SetPoint("TOPLEFT",20,-467)
        detail.abilitiesTitle=font(detail,12,gold)
        detail.abilitiesTitle:SetPoint("TOPLEFT",20,-248)
        detail.abilitiesTitle:SetText("FÄHIGKEITEN")
        detail.noAbilities=font(detail,12,muted)
        detail.noAbilities:SetPoint("TOPLEFT",20,-276)
        detail.noAbilities:SetText("Keine besonderen Fähigkeiten erfasst.")
        detail.abilityButtons={}
        for i=1,6 do
            local button=CreateFrame("Button",nil,detail)
            button:SetHeight(32)
            button.icon=button:CreateTexture(nil,"ARTWORK")
            button.icon:SetSize(28,28);button.icon:SetPoint("LEFT",2,0)
            button.name=font(button,12,cream)
            button.name:SetPoint("LEFT",button.icon,"RIGHT",9,0)
            button:SetScript("OnEnter",function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
                local shown=self.spellID and GameTooltip.SetSpellByID and
                    pcall(GameTooltip.SetSpellByID,GameTooltip,self.spellID)
                if shown and GameTooltip.NumLines and GameTooltip:NumLines()==0 then
                    shown=false
                end
                if not shown then
                    GameTooltip:AddLine(self.spellName or "Fähigkeit",1,.82,.1)
                    if self.description and self.description~="" then
                        GameTooltip:AddLine(self.description,.9,.84,.73,true)
                    end
                end
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
            detail.abilityButtons[i]=button
        end
        detail.lootTitle=font(detail,12,gold)
        detail.lootTitle:SetText("BEUTE")
        detail.noLoot=font(detail,12,muted)
        detail.noLoot:SetText("Keine besondere Beute erfasst.")
        detail.lootButtons={}
        for i=1,16 do
            local button=CreateFrame("Button",nil,detail)
            button:SetSize(300,48)
            button.icon=button:CreateTexture(nil,"ARTWORK")
            button.icon:SetSize(36,36);button.icon:SetPoint("TOPLEFT",4,-4)
            button.name=font(button,14,cream);button.name:SetPoint("TOPLEFT",48,-4)
            if button.name.SetMaxLines then button.name:SetMaxLines(1) end
            button.meta=font(button,12,muted);button.meta:SetPoint("TOPLEFT",48,-27)
            if button.meta.SetMaxLines then button.meta:SetMaxLines(1) end
            button:SetScript("OnEnter",function(self)
                if self.itemID and C.ShowLootItemTooltip then
                    C:ShowLootItemTooltip(self,self.itemID,self.itemName,self.itemMeta,
                        nil,nil,self.itemChance,self.itemSource)
                end
            end)
            button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
            detail.lootButtons[i]=button
        end
        detail.mapButton=CreateFrame("Button",nil,detail,"BackdropTemplate")
        C:StyleChronicleButton(detail.mapButton)
        detail.mapButton:SetSize(180,25)
        detail.mapButton:SetPoint("TOP",detail.modelBox,"BOTTOM",0,-5)
        detail.mapButton:SetText("AUF KARTE ZEIGEN")
        detail.mapButton:SetScript("OnEnter",function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
            if self.mapID and not self.x then
                GameTooltip:AddLine("Instanzregion auf der Karte öffnen",1,.82,.1)
                GameTooltip:AddLine("Genaue Koordinaten sind nicht erfasst.",.8,.72,.6)
            elseif not self.mapID then
                GameTooltip:AddLine("Kein Kartenpunkt erfasst",1,.82,.1)
            else
                return
            end
            GameTooltip:Show()
        end)
        detail.mapButton:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        detail.mapButton:SetScript("OnClick",function(self)
            if self.mapID and C.OpenBlizzardMap then C:OpenBlizzardMap(self.mapID,self.x,self.y) end
        end)
    end
    frame:SetParent(parent);frame:SetWidth(width);frame:Show();refresh(width)
end
