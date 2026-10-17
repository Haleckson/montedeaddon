local C = _G.Chronicle
local U = C.Util
local bg = "Interface\\Buttons\\WHITE8X8"
local frame, hero, dossier, search, searchHint, count, prev, next, empty
local filterButtons, cards = {}, {}
local mode, demo, page, selectedKey = "all", false, 1, nil
local PAGE_SIZE = 14
local gold, cream, muted = {1,.82,.1}, {.98,.94,.84}, {.85,.79,.69}

local demoItems = {
    {key="demo:rare",name="Seltenes Musterstück",quality=3,iconItemID=6460,
        iconFallback="Interface\\Icons\\INV_Belt_03",quantity=1,occurrences=1,
        zone="Beispielgebiet",sourceName="Beispielgegner",sourceConfidence="demo",
        description="So sieht ein seltener Fund mit Quelle, Fundort und Beschreibung aus.",
        demoChance=18.4,sellPrice=4825},
    {key="demo:epic",name="Epischer Musterfund",quality=4,iconItemID=18832,
        iconFallback="Interface\\Icons\\INV_Sword_39",quantity=1,occurrences=1,
        zone="Beispielgebiet",sourceName="Beispielgegner",sourceConfidence="demo",
        description="Ein epischer Fund erhält seine eigene violette Kennzeichnung, Quelle und Fundgeschichte.",
        demoChance=8.5,sellPrice=123456},
    {key="demo:legendary",name="Legendäres Musterstück",quality=5,iconItemID=17182,
        iconFallback="Interface\\Icons\\INV_Hammer_Unique_Sulfuras",quantity=1,occurrences=1,
        zone="Beispielgebiet",sourceName="Beispielgegner",sourceConfidence="demo",
        description="Ein legendärer Fund wird in Orange hervorgehoben und erhält dasselbe vollständige Funddossier.",
        demoChance=0.8,sellPrice=0},
}

local function font(parent,size,color)
    local label=parent:CreateFontString(nil,"OVERLAY")
    label:SetFont(C:FontPath(),size)
    label:SetTextColor(unpack(color))
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    return label
end

local function qualityColor(quality,id,link)
    return C:ItemQualityColor(id,quality,link)
end

local function percent(value)
    return string.format("%.2f",value):gsub("0+$",""):gsub("%.$",""):gsub("%.",",").."%"
end

local function itemIcon(entry)
    if entry.icon then return entry.icon end
    local iconID=entry.id or entry.iconItemID
    if iconID and C_Item and C_Item.GetItemIconByID then
        local ok,icon=pcall(C_Item.GetItemIconByID,iconID)
        if ok and icon then return icon end
    end
    if iconID and GetItemIcon then
        local ok,icon=pcall(GetItemIcon,iconID)
        if ok and icon then return icon end
    end
    return entry.iconFallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function itemDescription(entry)
    if entry.description then return entry.description end
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink and entry.link then
        local ok,data=pcall(C_TooltipInfo.GetHyperlink,entry.link)
        if ok and data and type(data.lines)=="table" then
            for _,line in ipairs(data.lines) do
                local value=line.leftText
                if type(value)=="string" and
                    (value:match('^".+"$') or value:match("^“.+”$")) then
                    return value
                end
            end
        end
    end
    if entry.id and GetItemInfo then
        local ok,_,_,_,level,required,itemType,subType=pcall(GetItemInfo,entry.id)
        if ok and itemType then
            local details=subType and subType~="" and (itemType.." · "..subType) or itemType
            if tonumber(level) and level>0 then details=details.." · Gegenstandsstufe "..level end
            if tonumber(required) and required>0 then details=details.." · Benötigt Stufe "..required end
            return details
        end
    end
    return "Weitere Eigenschaften zeigt der Gegenstandstooltip."
end

local function tooltip(owner,entry)
    if not GameTooltip or not entry then return end
    if entry.id and C.ShowLootItemTooltip then
        C:ShowLootItemTooltip(owner,entry.id,entry.name,
            "Chronicle · "..(entry.zone or "Ort nicht erfasst")..(entry.sourceName and
                (" · Mob: "..entry.sourceName) or ""),entry.quality,entry.link)
        return
    end
    GameTooltip:SetOwner(owner,"ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    local native=false
    if entry.link and GameTooltip.SetHyperlink then
        local ok=pcall(GameTooltip.SetHyperlink,GameTooltip,entry.link)
        native=ok and GameTooltip.NumLines and GameTooltip:NumLines()>0
    elseif entry.id and GameTooltip.SetItemByID then
        local ok=pcall(GameTooltip.SetItemByID,GameTooltip,entry.id)
        native=ok and GameTooltip.NumLines and GameTooltip:NumLines()>0
    end
    if not native then
        local r,g,b=qualityColor(entry.quality,entry.id,entry.link)
        GameTooltip:AddLine(entry.name or "Fundstück",r,g,b)
        GameTooltip:AddLine(itemDescription(entry),.92,.85,.72,true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Chronicle · "..(entry.zone or "Ort nicht erfasst"),1,.82,.1)
    if entry.sourceName then GameTooltip:AddLine("Mob: "..entry.sourceName,.9,.83,.7) end
    if entry.demoChance then
        GameTooltip:AddLine("Beispielchance: ~"..percent(entry.demoChance),.86,.8,.67)
    end
    GameTooltip:Show()
end

local function sourceFor(entry)
    if entry.sourceName then return entry.sourceName,entry.sourceConfidence end
    for _,boss in pairs(C.char.bosses or {}) do
        for _,loot in ipairs(boss.loot or {}) do
            if entry.id and loot.id and tonumber(loot.id)==tonumber(entry.id) and
                math.abs((tonumber(loot.time) or 0)-(tonumber(entry.time) or 0))<=120 then
                return boss.name,loot.source=="event" and "boss" or "inferred"
            end
        end
    end
end

local function collect()
    if demo then
        local result={}
        for _,entry in ipairs(demoItems) do
            if mode=="all" or (mode=="epic" and entry.quality>=4) or
                (mode=="legendary" and entry.quality>=5) then result[#result+1]=entry end
        end
        return result,3,2
    end
    local groups,byKey={},{}
    local blue,epic=0,0
    for _,entry in ipairs(C.char.loot or {}) do
        if U.LootVisible(entry) then
            blue=blue+1
            local quality=tonumber(entry.quality) or tonumber(type(entry.link)=="string" and
                entry.link:match("|cnIQ(%d+):")) or 0
            if quality>=4 then epic=epic+1 end
            if mode=="all" or (mode=="epic" and quality>=4) or
                (mode=="legendary" and quality>=5) then
                local key=tostring(entry.id or entry.link or entry.name)
                local group=byKey[key]
                if not group then
                    group={}
                    for field,value in pairs(entry) do group[field]=value end
                    group.key=key;group.quality=quality
                    group.occurrences=0;group.totalQuantity=0
                    group.firstTime=entry.time
                    groups[#groups+1]=group;byKey[key]=group
                end
                group.occurrences=group.occurrences+1
                group.totalQuantity=group.totalQuantity+(tonumber(entry.quantity) or 1)
                if not group.sourceName and entry.sourceName then
                    group.sourceName=entry.sourceName
                    group.sourceConfidence=entry.sourceConfidence
                end
                if (tonumber(entry.time) or 0)>(tonumber(group.time) or 0) then
                    group.time=entry.time;group.zone=entry.zone
                end
                if (tonumber(entry.time) or 0)<(tonumber(group.firstTime) or math.huge) then
                    group.firstTime=entry.time
                end
            end
        end
    end
    table.sort(groups,function(a,b) return (tonumber(a.time) or 0)>(tonumber(b.time) or 0) end)
    return groups,blue,epic
end

local function section(label,text,top,width)
    label:ClearAllPoints();label:SetPoint("TOPLEFT",dossier,"TOPLEFT",22,-top)
    text:ClearAllPoints();text:SetPoint("TOPLEFT",dossier,"TOPLEFT",22,-top-24)
    text:SetWidth(width-44)
    return top+24+math.max(18,text:GetStringHeight() or 18)+24
end

local function setDossier(entry,width)
    dossier:SetWidth(width)
    if not entry then
        dossier.empty:Show()
        dossier.icon:Hide();dossier.title:Hide();dossier.meta:Hide()
        dossier.caption:Hide();dossier.quality:Hide();dossier.headerRule:Hide()
        for _,pair in ipairs(dossier.sections) do pair[1]:Hide();pair[2]:Hide() end
        dossier.epicAura:Hide();dossier:SetHeight(600)
        return 600
    end
    dossier.empty:Hide()
    dossier.entry=entry
    local r,g,b=qualityColor(entry.quality,entry.id,entry.link)
    local quality=C:ItemQuality(entry.id,entry.quality,entry.link) or 1
    dossier:SetBackdropBorderColor(r,g,b,.95)
    dossier.iconBorder:SetBackdropBorderColor(r,g,b,1)
    dossier.epicAura:SetShown(quality>=4)
    dossier.epicAura:SetVertexColor(r,g,b,.09)
    dossier.headerRule:SetVertexColor(r,g,b,.66)
    dossier.caption:SetText(demo and "DEMO  /  FUNDSTÜCK" or "CHRONICLE  /  FUNDSTÜCK")
    dossier.quality:SetText(quality>=5 and "LEGENDÄR" or quality>=4 and "EPISCH" or "SELTEN")
    dossier.quality:SetTextColor(r,g,b)
    dossier.icon.texture:SetTexture(itemIcon(entry))
    dossier.title:SetText(entry.name or "Unbekanntes Fundstück")
    dossier.title:SetTextColor(r,g,b)
    dossier.title:SetWidth(width-170)
    dossier.meta:SetText((entry.totalQuantity or entry.quantity or 1).." Stück  ·  "..
        (entry.occurrences or 1).." Fund"..((entry.occurrences or 1)==1 and "" or "e"))
    dossier.icon:Show();dossier.title:Show();dossier.meta:Show()
    dossier.caption:Show();dossier.quality:Show();dossier.headerRule:Show()
    local source,confidence=sourceFor(entry)
    local sourceText=source and ((confidence=="target" or confidence=="inferred") and
        "Möglicher Mob: " or "Mob: ")..source or "Mob nicht erfasst"
    dossier.sections[1][2]:SetText(itemDescription(entry))
    dossier.sections[2][2]:SetText(sourceText)
    dossier.sections[3][2]:SetText(entry.zone or "Gebiet nicht erfasst")
    dossier.sections[4][2]:SetText((entry.firstTime and "Erster Fund: "..U.Date(entry.firstTime,true).."\n" or "")..
        (entry.time and "Letzter Fund: "..U.Date(entry.time,true) or (demo and "Vorschau ohne gespeicherten Fund" or "Zeitpunkt nicht erfasst")))
    local price=tonumber(entry.sellPrice)
    dossier.sections[5][2]:SetText(price and price>0 and U.Money(price) or
        (price==0 and "Nicht beim Händler verkäuflich" or "Wert nicht erfasst"))
    local chanceText="Keine verlässliche Dropchance erfasst"
    if entry.demoChance then
        chanceText="Beispielchance: ~"..percent(entry.demoChance)
    elseif entry.id and C.GetItemDropSources then
        local sources=C:GetItemDropSources(entry.id)
        if #sources>0 then
            local lines={}
            for index=1,math.min(3,#sources) do
                lines[#lines+1]=sources[index].source.."  ·  ~"..percent(sources[index].chance)
            end
            if #sources>3 then lines[#lines+1]="Weitere "..(#sources-3).." bekannte Quellen" end
            chanceText=table.concat(lines,"\n")
        end
    end
    dossier.sections[6][2]:SetText(chanceText)
    local y=151
    for _,pair in ipairs(dossier.sections) do
        pair[1]:Show();pair[2]:Show()
        y=section(pair[1],pair[2],y,width)
    end
    local height=math.max(600,y+12)
    dossier:SetHeight(height)
    return height
end

local function makeCard(parent)
    local card=CreateFrame("Button",nil,parent)
    card:SetHeight(47)
    card.shade=card:CreateTexture(nil,"BACKGROUND")
    card.shade:SetTexture(bg);card.shade:SetAllPoints()
    card.shade:SetVertexColor(.09,.085,.075,.32)
    card.accent=card:CreateTexture(nil,"ARTWORK")
    card.accent:SetTexture(bg);card.accent:SetPoint("TOPLEFT",0,-3)
    card.accent:SetPoint("BOTTOMLEFT",0,3);card.accent:SetWidth(2)
    card.icon=card:CreateTexture(nil,"ARTWORK")
    card.icon:SetSize(36,36);card.icon:SetPoint("LEFT",8,0)
    card.iconBorder=CreateFrame("Frame",nil,card,"BackdropTemplate")
    card.iconBorder:SetSize(40,40);card.iconBorder:SetPoint("CENTER",card.icon,"CENTER")
    card.iconBorder:SetBackdrop({edgeFile=bg,edgeSize=2})
    card.iconBorder:EnableMouse(false)
    card.name=font(card,14,cream);card.name:SetPoint("TOPLEFT",54,-5)
    card.meta=font(card,11,muted);card.meta:SetPoint("TOPLEFT",54,-25)
    card:SetScript("OnEnter",function(self)
        self.shade:SetShown(true)
        tooltip(self,self.entry)
    end)
    card:SetScript("OnLeave",function(self)
        self.shade:SetShown(self.key==selectedKey)
        if GameTooltip then GameTooltip:Hide() end
    end)
    card:SetScript("OnClick",function(self)
        selectedKey=self.key
        C:RefreshLootGallery()
    end)
    return card
end

function C:RefreshLootGallery()
    if not frame or not frame:IsShown() then return end
    local width=frame:GetWidth()
    local entries,blueCount,epicCount=collect()
    local query=search and U.Trim(search:GetText()):lower() or ""
    local filtered={}
    for _,entry in ipairs(entries) do
        local source=entry.sourceName or ""
        if query=="" or tostring(entry.name or ""):lower():find(query,1,true) or
            tostring(entry.zone or ""):lower():find(query,1,true) or
            source:lower():find(query,1,true) then
            filtered[#filtered+1]=entry
        end
    end
    local pages=math.max(1,math.ceil(#filtered/PAGE_SIZE))
    page=math.min(page,pages)
    hero:SetWidth(width-8)
    hero.summary:SetText(demo and "Vorschau ohne gespeicherte Funde" or
        (blueCount.." Funde ab Blau  ·  "..epicCount.." episch oder besser"))
    hero.demo:SetText(demo and "DEMO BEENDEN" or "DEMO ANZEIGEN")
    for _,button in ipairs(filterButtons) do
        local active=button.mode==mode
        button:SetBackdropColor(active and .095 or .038,active and .082 or .036,
            active and .061 or .032,.96)
        button:GetFontString():SetTextColor(active and 1 or .88,
            active and .82 or .8,active and .1 or .68)
    end
    local listWidth=math.max(275,math.floor(width*.40))
    count:SetText(#filtered.." TREFFER  ·  "..page.."/"..pages)
    prev:SetEnabled(page>1);next:SetEnabled(page<pages)
    prev:ClearAllPoints();prev:SetPoint("TOPLEFT",frame,"TOPLEFT",listWidth-164,-142)
    next:ClearAllPoints();next:SetPoint("TOPLEFT",frame,"TOPLEFT",listWidth-82,-142)
    local start=(page-1)*PAGE_SIZE+1
    local chosen
    for index=start,math.min(#filtered,start+PAGE_SIZE-1) do
        if filtered[index].key==selectedKey then chosen=filtered[index];break end
    end
    if not chosen then chosen=filtered[start];selectedKey=chosen and chosen.key end
    local used=0
    for index=start,math.min(#filtered,start+PAGE_SIZE-1) do
        used=used+1
        local entry=filtered[index]
        local card=cards[used]
        if not card then card=makeCard(frame);cards[used]=card end
        card:ClearAllPoints();card:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-171-(used-1)*48)
        card:SetWidth(listWidth-8)
        card.entry,card.key=entry,entry.key
        card.icon:SetTexture(itemIcon(entry))
        local r,g,b=qualityColor(entry.quality,entry.id,entry.link)
        card.iconBorder:SetBackdropBorderColor(r,g,b,1)
        card.name:SetText(entry.name or "Fundstück")
        card.name:SetTextColor(r,g,b)
        card.name:SetWidth(listWidth-100)
        card.meta:SetText((entry.zone or "Ort nicht erfasst").."  ·  "..
            (entry.occurrences or 1).." Fund"..((entry.occurrences or 1)==1 and "" or "e"))
        card.meta:SetWidth(listWidth-95)
        card.accent:SetVertexColor(r,g,b,.95)
        card.accent:SetShown(card.key==selectedKey)
        card.shade:SetShown(card.key==selectedKey)
        card:Show()
    end
    for index=used+1,#cards do cards[index]:Hide() end
    empty:SetShown(#filtered==0)
    if #filtered==0 then
        empty:SetText(demo and "Keine Musterfunde für diesen Filter." or
            "Noch keine Fundstücke ab blauer Qualität erfasst. Die Demo zeigt den Aufbau.")
    end
    dossier:ClearAllPoints();dossier:SetPoint("TOPLEFT",frame,"TOPLEFT",listWidth+12,-142)
    local detailHeight=setDossier(chosen,width-listWidth-20)
    frame:SetHeight(142+math.max(600,detailHeight,29+used*48)+16)
    if frame:GetParent() then frame:GetParent():SetHeight(frame:GetHeight()+8) end
end

function C:HideLootGallery()
    if frame then frame:Hide() end
end

function C:ShowLootGallery(parent,width)
    if not frame then
        frame=CreateFrame("Frame",nil,parent)
        frame:SetPoint("TOPLEFT",0,0)
        hero=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        hero:SetPoint("TOPLEFT",4,0);hero:SetHeight(126)
        hero:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
        hero:SetBackdropColor(.035,.034,.032,.98)
        hero:SetBackdropBorderColor(.59,.44,.17,.9)
        C:ApplyMaterial(hero,.27);C:OrnateCorners(hero)
        C:SetHeroMotif(hero,"Loot",.13)
        hero.caption=font(hero,10,gold);hero.caption:SetPoint("TOPLEFT",19,-13)
        hero.caption:SetText("CHRONICLE  /  SAMMLUNG")
        hero.title=font(hero,23,cream);hero.title:SetPoint("TOPLEFT",19,-34)
        hero.title:SetText("Fundstücke")
        hero.summary=font(hero,12,muted);hero.summary:SetPoint("TOPLEFT",20,-65)
        hero.demo=CreateFrame("Button",nil,hero,"BackdropTemplate")
        C:StyleChronicleButton(hero.demo)
        hero.demo:SetSize(130,23);hero.demo:SetPoint("TOPRIGHT",-18,-14)
        hero.demo:SetScript("OnClick",function()
            demo=not demo;page=1;selectedKey=nil;C:RefreshLootGallery()
        end)
        local names={{"all","ALLE AB BLAU"},{"epic","NUR EPISCH+"},
            {"legendary","NUR LEGENDÄR"}}
        for index,pair in ipairs(names) do
            local button=CreateFrame("Button",nil,hero,"BackdropTemplate")
            C:StyleChronicleButton(button)
            button.mode=pair[1];button:SetText(pair[2])
            button:SetSize(150,23)
            button:SetPoint("TOPLEFT",19+(index-1)*156,-91)
            button:SetScript("OnClick",function(self)
                mode=self.mode;page=1;selectedKey=nil;C:RefreshLootGallery()
            end)
            filterButtons[index]=button
        end
        search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate")
        search:SetSize(210,24);search:SetPoint("TOPRIGHT",-19,-51)
        search:SetAutoFocus(false);search:SetMaxLetters(80)
        searchHint=font(search,11,muted);searchHint:SetPoint("LEFT",7,0)
        searchHint:SetText("Fundstück suchen ...")
        search:SetScript("OnTextChanged",function(self)
            searchHint:SetShown(self:GetText()=="")
            page=1;selectedKey=nil;C:RefreshLootGallery()
        end)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        count=font(frame,11,gold);count:SetPoint("TOPLEFT",frame,"TOPLEFT",11,-146)
        prev=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(prev);prev:SetSize(76,20);prev:SetText("‹ Zurück")
        prev:SetScript("OnClick",function() page=math.max(1,page-1);selectedKey=nil;C:RefreshLootGallery() end)
        next=CreateFrame("Button",nil,frame,"BackdropTemplate")
        C:StyleChronicleButton(next);next:SetSize(76,20);next:SetText("Weiter ›")
        next:SetScript("OnClick",function() page=page+1;selectedKey=nil;C:RefreshLootGallery() end)
        empty=font(frame,13,muted);empty:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-180)
        empty:SetWidth(280)
        dossier=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        dossier:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
        dossier:SetBackdropColor(.03,.029,.027,.98)
        dossier:SetBackdropBorderColor(.59,.44,.17,.9)
        C:ApplyMaterial(dossier,.32);C:OrnateCorners(dossier)
        dossier.epicAura=dossier:CreateTexture(nil,"ARTWORK")
        dossier.epicAura:SetTexture(bg)
        dossier.epicAura:SetPoint("TOPLEFT",4,-4)
        dossier.epicAura:SetPoint("TOPRIGHT",-4,-4)
        dossier.epicAura:SetHeight(117)
        dossier.caption=font(dossier,10,gold)
        dossier.caption:SetPoint("TOPLEFT",22,-15)
        dossier.quality=font(dossier,11,gold)
        dossier.quality:SetPoint("TOPRIGHT",-20,-15)
        dossier.quality:SetJustifyH("RIGHT")
        dossier.icon=CreateFrame("Button",nil,dossier)
        dossier.icon:SetSize(58,58);dossier.icon:SetPoint("TOPLEFT",22,-48)
        dossier.icon.texture=dossier.icon:CreateTexture(nil,"ARTWORK")
        dossier.icon.texture:SetAllPoints()
        dossier.iconBorder=CreateFrame("Frame",nil,dossier.icon,"BackdropTemplate")
        dossier.iconBorder:SetSize(62,62)
        dossier.iconBorder:SetPoint("CENTER",dossier.icon,"CENTER")
        dossier.iconBorder:SetBackdrop({edgeFile=bg,edgeSize=2})
        dossier.iconBorder:EnableMouse(false)
        dossier.icon:SetScript("OnEnter",function(self) tooltip(self,dossier.entry) end)
        dossier.icon:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        dossier.title=font(dossier,21,cream);dossier.title:SetPoint("TOPLEFT",91,-48)
        dossier.meta=font(dossier,11,muted);dossier.meta:SetPoint("TOPLEFT",92,-84)
        dossier.headerRule=dossier:CreateTexture(nil,"ARTWORK")
        dossier.headerRule:SetTexture(bg)
        dossier.headerRule:SetPoint("TOPLEFT",20,-125)
        dossier.headerRule:SetPoint("TOPRIGHT",-20,-125)
        dossier.headerRule:SetHeight(C:RuleThickness())
        dossier.sections={}
        for _,title in ipairs({"BESCHREIBUNG","HERKUNFT","FUNDORT","ERHALTEN","HÄNDLERWERT","DROPCHANCE"}) do
            local heading=font(dossier,12,gold);heading:SetText(title)
            local value=font(dossier,13,cream)
            dossier.sections[#dossier.sections+1]={heading,value}
        end
        dossier.empty=font(dossier,14,muted)
        dossier.empty:SetPoint("TOPLEFT",22,-54)
        dossier.empty:SetText("Wähle links ein Fundstück aus.")
        frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        frame:SetScript("OnEvent",function(self)
            if self:IsShown() then C:RefreshLootGallery() end
        end)
    end
    frame:SetParent(parent);frame:SetWidth(width);frame:Show()
    self:RefreshLootGallery()
end
