local C = _G.Chronicle
local pendingItemRequests = {}

local slotNames = {
    [1]="Kopf",[2]="Hals",[3]="Schultern",[5]="Brust",[6]="Taille",
    [7]="Beine",[8]="Füße",[9]="Handgelenke",[10]="Hände",
    [11]="Finger",[12]="Schmuck",[13]="Waffe",[14]="Schild",
    [15]="Fernkampf",[16]="Rücken",[17]="Zweihandwaffe",
    [20]="Robe",[21]="Waffenhand",[22]="Schildhand",[23]="Nebenhand",
    [25]="Wurfwaffe",[26]="Fernkampf",[28]="Relikt",
}
local statNames = {
    str="Stärke",agi="Beweglichkeit",sta="Ausdauer",int="Intelligenz",
    spi="Willenskraft",ap="Angriffskraft",sp="Zaubermacht",
    hit="Trefferwertung",crit="Kritische Trefferwertung",def="Verteidigung",
}

function C:ItemCategory(itemID,fallback)
    local location,itemType,classID
    local instant=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if itemID and type(instant)=="function" then
        local ok,_,_,_,equipLoc,_,itemClass=pcall(instant,itemID)
        if ok then location=equipLoc;classID=itemClass end
    end
    if itemID and GetItemInfo then
        local ok,_,_,_,_,_,kind,_,_,equipLoc=pcall(GetItemInfo,itemID)
        if ok then
            itemType=kind
            if type(equipLoc)=="string" and equipLoc~="" then location=equipLoc end
        end
    end
    local facts=itemID and self.lootTooltipFacts and self.lootTooltipFacts[itemID]
    local slot=facts and facts.slot
    if location=="INVTYPE_WEAPON" or (not location and slot==13) then
        return "1 Hand - Waffe"
    end
    if location=="INVTYPE_2HWEAPON" or (not location and slot==17) then
        return "2 Hand - Waffe"
    end
    if location=="INVTYPE_WEAPONMAINHAND" or (not location and slot==21) then
        return "Waffenhand - Waffe"
    end
    if location=="INVTYPE_WEAPONOFFHAND" or (not location and slot==23) then
        return "Nebenhand - Waffe"
    end
    local label=(type(location)=="string" and location~="" and
        location~="INVTYPE_NON_EQUIP" and (_G[location] or
        location:gsub("^INVTYPE_",""))) or (slot and slotNames[slot])
    if label then
        if classID==2 or itemType=="Waffen" or itemType=="Weapon" then
            return label.." - Waffe"
        end
        if classID==4 or itemType=="Rüstung" or itemType=="Armor" or
            (facts and type(facts.armor)=="number" and facts.armor>0) then
            return label.." - Rüstung"
        end
        return label
    end
    if type(itemType)=="string" and itemType~="" then return itemType end
    if type(fallback)=="string" and fallback~="" and
        not fallback:match("^Item #%d+$") then return fallback end
    return nil
end

local qualityByHex = {
    ["9d9d9d"]=0,["ffffff"]=1,["1eff00"]=2,["0070dd"]=3,
    ["a335ee"]=4,["ff8000"]=5,["e6cc80"]=7,
}

function C:ItemQuality(itemID,recordedQuality,itemLink)
    if GetItemInfo then
        if itemLink then
            local ok,_,_,quality=pcall(GetItemInfo,itemLink)
            if ok and type(quality)=="number" then return quality end
        end
        if itemID then
            local ok,_,_,quality=pcall(GetItemInfo,itemID)
            if ok and type(quality)=="number" then return quality end
        end
    end
    if itemID and C_Item and C_Item.GetItemQualityByID then
        local ok,quality=pcall(C_Item.GetItemQualityByID,itemID)
        if ok and type(quality)=="number" then return quality end
    end
    local recorded=tonumber(recordedQuality)
    if recorded then return recorded end
    if type(itemLink)=="string" then
        local colored=tonumber(itemLink:match("|cnIQ(%d+):"))
        if colored then return colored end
        local hex=itemLink:match("|cff(%x%x%x%x%x%x)")
        if hex and qualityByHex[hex:lower()] then return qualityByHex[hex:lower()] end
    end
    local reference=itemID and self.lootItemFacts and self.lootItemFacts[itemID]
    if reference and type(reference.q)=="number" then return reference.q end
    local facts=itemID and self.lootTooltipFacts and self.lootTooltipFacts[itemID]
    if facts and type(facts.q)=="number" then return facts.q end
end

function C:ItemQualityColor(itemID,recordedQuality,itemLink)
    local quality=self:ItemQuality(itemID,recordedQuality,itemLink)
    if type(quality)=="number" and GetItemQualityColor then
        local ok,r,g,b=pcall(GetItemQualityColor,quality)
        if ok and type(r)=="number" then return r,g,b end
    end
    local clientColor=type(quality)=="number" and ITEM_QUALITY_COLORS and
        ITEM_QUALITY_COLORS[quality]
    if clientColor and type(clientColor.r)=="number" then
        return clientColor.r,clientColor.g,clientColor.b
    end
    local colors={ [0]={.62,.62,.62},[1]={1,1,1},[2]={.12,1,0},
        [3]={0,.44,.87},[4]={.64,.21,.93},[5]={1,.5,0},
        [6]={.9,.8,.5},[7]={.9,.8,.5} }
    local color=colors[quality] or colors[1]
    return color[1],color[2],color[3]
end

local function validGameTooltip(tooltip)
    if not tooltip.NumLines or tooltip:NumLines()<1 then return false end
    local name=tooltip.GetName and tooltip:GetName()
    local title=name and _G[name.."TextLeft1"]
    local text=title and title.GetText and title:GetText()
    if name and (type(text)~="string" or text=="") then return false end
    if type(text)=="string" then
        if text:find("Retrieving Item",1,true) or
            text:find("Gegenstandsinformationen",1,true) or
            text:find("Gegenstandsdaten",1,true) then return false end
    end
    return true
end

local dropSources
function C:InvalidateItemDropSources()
    dropSources=nil
end
function C:GetItemDropSources(itemID)
    if not dropSources then
        dropSources={}
        local function add(id,source,chance)
            id, chance=tonumber(id),tonumber(chance)
            if not id or not chance or chance<=0 or not source then return end
            local entries=dropSources[id] or {}
            dropSources[id]=entries
            for _,entry in ipairs(entries) do
                if entry.source==source then return end
            end
            entries[#entries+1]={source=source,chance=chance}
        end
        for _,catalog in ipairs({self.dungeonKnowledge or {},self.raidKnowledge or {}}) do
            for _,instance in pairs(catalog) do
                for _,boss in ipairs(instance.bosses or {}) do
                    for _,item in ipairs(boss.loot or {}) do
                        add(item[1],boss.name,item[5])
                    end
                end
            end
        end
        for _,rare in pairs(self.rareReferenceCatalog or {}) do
            for _,item in ipairs(rare.loot or {}) do add(item[1],rare.n,item[2]) end
        end
        for _,entries in pairs(dropSources) do
            table.sort(entries,function(a,b) return a.chance>b.chance end)
        end
    end
    return dropSources[itemID] or {}
end

local function chanceText(value)
    local text=string.format("%.2f",value):gsub("0+$",""):gsub("%.$","")
    return text:gsub("%.",",")
end

function C:AppendItemDropChance(tooltip,itemID,chance,source)
    chance=tonumber(chance)
    if chance and chance>0 then
        tooltip:AddLine("Dropchance"..(source and (" bei "..source) or "")..
            ": ~"..chanceText(chance).."%",.86,.8,.67,true)
        return
    end
    local entries=self:GetItemDropSources(itemID)
    for index=1,math.min(3,#entries) do
        local entry=entries[index]
        tooltip:AddLine("Dropchance bei "..entry.source..": ~"..
            chanceText(entry.chance).."%",.86,.8,.67,true)
    end
    if #entries>3 then
        tooltip:AddLine("Weitere "..(#entries-3).." bekannte Quellen",.58,.55,.49)
    end
end

local function usefulName(name)
    return type(name)=="string" and name~="" and
        not name:match("^Item #%d+$") and
        not name:match("^Gegenstand #%d+$")
end

function C:KnownItemName(itemID,fallback)
    if not itemID then return usefulName(fallback) and fallback or nil end
    if C_Item and C_Item.GetItemNameByID then
        local ok,name=pcall(C_Item.GetItemNameByID,itemID)
        if ok and usefulName(name) then return name end
    end
    if GetItemInfo then
        local ok,name=pcall(GetItemInfo,itemID)
        if ok and usefulName(name) then return name end
    end
    local reference=self.lootItemFacts and self.lootItemFacts[itemID]
    if reference and usefulName(reference.n) then return reference.n end
    if usefulName(fallback) then return fallback end
    if not pendingItemRequests[itemID] and C_Item and C_Item.RequestLoadItemDataByID then
        pendingItemRequests[itemID]=true
        pcall(C_Item.RequestLoadItemDataByID,itemID)
    end
    return nil
end

function C:ShowLootItemTooltip(owner,itemID,fallbackName,fallbackMeta,fallbackQuality,itemLink,dropChance,dropSource)
    if not owner or not itemID or not GameTooltip then return end
    local tooltip=GameTooltip
    tooltip:SetOwner(owner,"ANCHOR_CURSOR")
    if type(itemLink)=="string" and itemLink~="" and tooltip.SetHyperlink then
        tooltip:ClearLines()
        local ok=pcall(tooltip.SetHyperlink,tooltip,itemLink)
        if ok and validGameTooltip(tooltip) then
            self:AppendItemDropChance(tooltip,itemID,dropChance,dropSource)
            tooltip:Show();return
        end
    end
    if tooltip.SetItemByID then
        tooltip:ClearLines()
        local ok=pcall(tooltip.SetItemByID,tooltip,itemID)
        if ok and validGameTooltip(tooltip) then
            self:AppendItemDropChance(tooltip,itemID,dropChance,dropSource)
            tooltip:Show();return
        end
    end
    if tooltip.SetHyperlink then
        tooltip:ClearLines()
        local ok=pcall(tooltip.SetHyperlink,tooltip,"item:"..tostring(itemID))
        if ok and validGameTooltip(tooltip) then
            self:AppendItemDropChance(tooltip,itemID,dropChance,dropSource)
            tooltip:Show();return
        end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID,itemID)
    end

    local reference=self.lootItemFacts and self.lootItemFacts[itemID]
    local fact=self.lootTooltipFacts and self.lootTooltipFacts[itemID]
    local name=self:KnownItemName(itemID,fallbackName) or ("Gegenstand #"..itemID)
    if C_Item and C_Item.GetItemNameByID then
        local ok,clientName=pcall(C_Item.GetItemNameByID,itemID)
        if ok and type(clientName)=="string" and clientName~="" then name=clientName end
    end
    local r,g,b=self:ItemQualityColor(itemID,fallbackQuality,itemLink)
    tooltip:ClearLines()
    tooltip:AddLine(name,r,g,b)
    local category=self:ItemCategory(itemID)
    if category then tooltip:AddLine(category,1,1,1) end
    if fact then
        if fact.bind==1 then tooltip:AddLine("Beim Aufheben gebunden",1,1,1)
        elseif fact.bind==2 then tooltip:AddLine("Beim Anlegen gebunden",1,1,1) end
        if fact.level then tooltip:AddLine("Gegenstandsstufe "..fact.level,1,.82,.1) end
        if fact.armor and fact.armor>0 then
            tooltip:AddLine(fact.armor.." Rüstung",1,1,1)
        end
        if fact.damage then
            local minimum,maximum,speed=fact.damage:match("^(%d+)%-(%d+)@([%d%.]+)$")
            if minimum then
                tooltip:AddLine(minimum.." - "..maximum.." Schaden  ·  Tempo "..speed,1,1,1)
            end
        end
        if fact.required then tooltip:AddLine("Benötigt Stufe "..fact.required,1,1,1) end
        for stat,value in (fact.stats or ""):gmatch("([%a_]+)=([%d%.%-]+)") do
            tooltip:AddLine("+"..value.." "..(statNames[stat] or stat),.2,1,.2)
        end
        for effect in (fact.effects or ""):gmatch("[^|]+") do
            local kind,description=effect:match("^([EUH]):(.+)$")
            if description then
                tooltip:AddLine((kind=="U" and "Benutzen: " or kind=="H" and
                    "Trefferchance: " or "Anlegen: ")..description,.2,1,.2,true)
            end
        end
    end
    if type(fallbackMeta)=="string" and fallbackMeta~="" then
        tooltip:AddLine(fallbackMeta,.86,.8,.67,true)
    end
    if not (dropChance and type(fallbackMeta)=="string" and
        fallbackMeta:find("%%")) then
        self:AppendItemDropChance(tooltip,itemID,dropChance,dropSource)
    end
    tooltip:AddLine("Referenzwerte · Spielclient hat diesen Gegenstand noch nicht geladen",.58,.55,.49,true)
    tooltip:Show()
end
