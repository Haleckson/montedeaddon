local C = _G.Chronicle
local U = C.Util
local bg = "Interface\\Buttons\\WHITE8X8"
local frame, hero, professionPane, recipePane, detailPane, chapter
local professionRows, recipeRows, materialRows = {}, {}, {}
local search, searchHint, pageLabel, prevButton, nextButton
local selectedProfession, selectedRecipe, page = nil, nil, 1
local PAGE_SIZE = 8
local gold, cream, muted = {1,.82,.1}, {.98,.94,.84}, {.85,.79,.69}
local secondary = { ["Erste Hilfe"]=true, ["Kochkunst"]=true, ["Angeln"]=true,
    ["First Aid"]=true, ["Cooking"]=true, ["Fishing"]=true }
local icons = {
    ["Bergbau"]="Interface\\Icons\\Trade_Mining",
    ["Kräuterkunde"]="Interface\\Icons\\Trade_Herbalism",
    ["Alchemie"]="Interface\\Icons\\Trade_Alchemy",
    ["Schmiedekunst"]="Interface\\Icons\\Trade_BlackSmithing",
    ["Ingenieurskunst"]="Interface\\Icons\\Trade_Engineering",
    ["Schneiderei"]="Interface\\Icons\\Trade_Tailoring",
    ["Verzauberkunst"]="Interface\\Icons\\Trade_Engraving",
}
local bannerBySkillLine = {
    [129]="FirstAid", [164]="Blacksmithing", [165]="Leatherworking",
    [171]="Alchemy", [182]="Herbalism", [185]="Cooking", [186]="Mining",
    [197]="Tailoring", [202]="Engineering", [333]="Enchanting",
    [356]="Fishing", [393]="Skinning",
}
local bannerByName = {
    ["Erste Hilfe"]="FirstAid", ["First Aid"]="FirstAid",
    ["Schmiedekunst"]="Blacksmithing", ["Blacksmithing"]="Blacksmithing",
    ["Lederverarbeitung"]="Leatherworking", ["Leatherworking"]="Leatherworking",
    ["Alchemie"]="Alchemy", ["Alchemy"]="Alchemy",
    ["Kräuterkunde"]="Herbalism", ["Herbalism"]="Herbalism",
    ["Kochkunst"]="Cooking", ["Cooking"]="Cooking",
    ["Bergbau"]="Mining", ["Mining"]="Mining",
    ["Schneiderei"]="Tailoring", ["Tailoring"]="Tailoring",
    ["Ingenieurskunst"]="Engineering", ["Engineering"]="Engineering",
    ["Verzauberkunst"]="Enchanting", ["Enchanting"]="Enchanting",
    ["Angeln"]="Fishing", ["Fishing"]="Fishing",
    ["Kürschnerei"]="Skinning", ["Skinning"]="Skinning",
}
local function professionBanner(name,data)
    local key=bannerBySkillLine[tonumber(data and data.skillLine)] or bannerByName[name]
    return key and ("Interface\\AddOns\\Chronicle\\ProfessionBanner_"..key) or nil
end
local pendingItemLoads = {}
local transitionWatcher, returnPending, professionOpened = nil, false, false
local reopenChapterAfterProfession = false
local hookedProfessionPanels = {}
local hookProfessionPanels

local function shownProfessionPanel()
    for _,name in ipairs({"ProfessionsFrame","TradeSkillFrame","CraftFrame"}) do
        local panel=_G[name]
        if panel and panel.IsShown and panel:IsShown() then return panel end
    end
end

local function restoreChronicle()
    if not returnPending or shownProfessionPanel() then return end
    returnPending=false;professionOpened=false
    C:ShowPage("professions")
    if reopenChapterAfterProfession then
        reopenChapterAfterProfession=false
        C:OpenProfessionChapter(selectedProfession,true)
    end
end

local function restoreSoon()
    if C_Timer and C_Timer.After then C_Timer.After(.1,restoreChronicle)
    else restoreChronicle() end
end

local function hideForProfession()
    if not returnPending then return end
    if shownProfessionPanel() then
        professionOpened=true
        hookProfessionPanels()
        if C.frame and C.frame:IsShown() then C.frame:Hide() end
    end
end

hookProfessionPanels = function()
    for _,name in ipairs({"ProfessionsFrame","TradeSkillFrame","CraftFrame"}) do
        local panel=_G[name]
        if panel and panel.HookScript and not hookedProfessionPanels[panel] then
            hookedProfessionPanels[panel]=true
            panel:HookScript("OnHide",function()
                if returnPending and professionOpened then restoreSoon() end
            end)
        end
    end
end

local function ensureTransitionWatcher()
    if transitionWatcher then return end
    transitionWatcher=CreateFrame("Frame")
    for _,event in ipairs({"TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","CRAFT_SHOW","CRAFT_CLOSE"}) do
        pcall(transitionWatcher.RegisterEvent,transitionWatcher,event)
    end
    transitionWatcher:SetScript("OnEvent",function(_,event)
        if not returnPending then return end
        if event=="TRADE_SKILL_SHOW" or event=="CRAFT_SHOW" then
            professionOpened=true
            if C_Timer and C_Timer.After then C_Timer.After(.05,hideForProfession)
            else hideForProfession() end
        elseif professionOpened then
            restoreSoon()
        end
    end)
end

local function itemName(itemID)
    if not itemID then return nil end
    if C.KnownItemName then
        local known=C:KnownItemName(itemID)
        if known then return known end
    end
    if C_Item and C_Item.GetItemNameByID then
        local ok,name=pcall(C_Item.GetItemNameByID,itemID)
        if ok and type(name)=="string" and name~="" then return name end
    end
    if GetItemInfo then
        local ok,name=pcall(GetItemInfo,itemID)
        if ok and type(name)=="string" and name~="" then return name end
    end
    if not pendingItemLoads[itemID] and C_Item and C_Item.RequestLoadItemDataByID then
        pendingItemLoads[itemID]=true
        pcall(C_Item.RequestLoadItemDataByID,itemID)
    end
end

local function label(parent,size,color)
    local fs=parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(C:FontPath(),size)
    fs:SetTextColor(unpack(color))
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    return fs
end

local function panel(parent)
    local box=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    box:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
    box:SetBackdropColor(.035,.034,.032,.98)
    box:SetBackdropBorderColor(.59,.44,.17,.9)
    C:ApplyMaterial(box,.24)
    C:OrnateCorners(box)
    return box
end

local function iconFor(itemID)
    if not itemID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if C_Item and C_Item.GetItemIconByID then
        local ok,value=pcall(C_Item.GetItemIconByID,itemID)
        if ok and value then return value end
    end
    if GetItemIcon then
        local ok,value=pcall(GetItemIcon,itemID)
        if ok and value then return value end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function itemTooltip(owner,itemID,name)
    if itemID and C.ShowLootItemTooltip then
        C:ShowLootItemTooltip(owner,itemID,name)
        return
    end
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    local shown=false
    if itemID and GameTooltip.SetItemByID then
        local ok=pcall(GameTooltip.SetItemByID,GameTooltip,itemID)
        shown=ok and GameTooltip.NumLines and GameTooltip:NumLines()>0
    end
    if not shown then GameTooltip:AddLine(name or "Material",1,.82,.1) end
    GameTooltip:Show()
end

local function professions()
    local result={}
    for name in pairs(C.char and C.char.professions or {}) do result[#result+1]=name end
    table.sort(result,function(a,b)
        if (not not secondary[a]) ~= (not not secondary[b]) then return not secondary[a] end
        return a<b
    end)
    return result
end

local function recipesFor(name)
    local result={}
    for key,recipe in pairs(C.char and C.char.recipes and C.char.recipes[name] or {}) do
        result[#result+1]={
            key=tostring(key), id=tonumber(recipe.id) or tonumber(key),
            name=U.SafeText(recipe.name,"Rezept #"..tostring(key)),
            icon=recipe.icon, skill=recipe.skill, reagents=recipe.reagents,
            outputItemID=recipe.outputItemID, firstSeen=recipe.firstSeen,
            thresholds=C.ProfessionThresholds and C.ProfessionThresholds[tonumber(recipe.id) or tonumber(key)],
        }
    end
    table.sort(result,function(a,b) return a.name:lower()<b.name:lower() end)
    return result
end

local function ingredientSummary(reagents)
    if type(reagents)~="table" or #reagents==0 then return "Materialien nicht erfasst" end
    local parts={}
    for index=1,math.min(2,#reagents) do
        local reagent=reagents[index]
        local name=reagent.name or itemName(reagent.id) or
            (reagent.id and "Gegenstand nicht geladen" or "Material")
        parts[#parts+1]=(tonumber(reagent.count) or 1).."× "..name
    end
    if #reagents>2 then parts[#parts+1]="+"..(#reagents-2).." weitere" end
    return table.concat(parts,"  ·  ")
end

local function beginProfessionTransition()
    if not selectedProfession then return end
    ensureTransitionWatcher()
    returnPending=true
    professionOpened=false
    hookProfessionPanels()
    if C_Timer and C_Timer.After then
        C_Timer.After(.05,hideForProfession)
        C_Timer.After(2,function()
            if returnPending and not professionOpened then returnPending=false end
        end)
    else
        hideForProfession()
    end
end

local function selectNativeRecipe(recipeID, attempt)
    if not recipeID or not returnPending then return end
    local panel=shownProfessionPanel()
    local available=false
    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        local ok,ids=pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if ok and type(ids)=="table" then
            for _,id in ipairs(ids) do if id==recipeID then available=true;break end end
        end
    end
    if available and panel and panel.SelectRecipe then
        local ok=pcall(panel.SelectRecipe,panel,recipeID)
        if ok then return end
    end
    if available and panel and panel.CraftingPage and panel.CraftingPage.SelectRecipe then
        local ok=pcall(panel.CraftingPage.SelectRecipe,panel.CraftingPage,recipeID)
        if ok then return end
    end
    if (attempt or 0)<10 and C_Timer and C_Timer.After then
        C_Timer.After(.15,function() selectNativeRecipe(recipeID,(attempt or 0)+1) end)
    end
end

local function openProfession(recipeID)
    if type(recipeID)~="number" then recipeID=nil end
    local profession=C.char and C.char.professions and C.char.professions[selectedProfession]
    local skillLine=profession and tonumber(profession.skillLine)
    if not skillLine or not (C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill) or
        (InCombatLockdown and InCombatLockdown()) then return end
    reopenChapterAfterProfession=chapter and chapter:IsShown() or false
    if shownProfessionPanel() and C_TradeSkillUI.GetBaseProfessionInfo then
        local infoOK,info=pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        local sameOK,same=pcall(function()
            return infoOK and type(info)=="table" and tonumber(info.professionID)==skillLine
        end)
        if sameOK and same then
            beginProfessionTransition()
            hideForProfession()
            selectNativeRecipe(recipeID)
            return
        end
    end
    beginProfessionTransition()
    local ok=pcall(C_TradeSkillUI.OpenTradeSkill,skillLine)
    if not ok then returnPending=false;professionOpened=false;reopenChapterAfterProfession=false end
    if ok then selectNativeRecipe(recipeID) end
end

local function createProfessionRow()
    local row=CreateFrame("Button",nil,professionPane,"BackdropTemplate")
    row:SetHeight(150)
    row:SetBackdrop({bgFile=bg,edgeFile=bg,edgeSize=C:RuleThickness()})
    row:SetBackdropColor(.03,.029,.027,.94)
    row.banner=row:CreateTexture(nil,"BORDER",nil,0)
    row.banner:SetPoint("TOPLEFT",2,-2)
    row.banner:SetPoint("BOTTOMRIGHT",-2,2)
    row.banner:SetTexCoord(0,1,0,1)
    row.shade=row:CreateTexture(nil,"BORDER",nil,2)
    row.shade:SetTexture(bg);row.shade:SetAllPoints();row.shade:SetVertexColor(.065,.061,.055,.18)
    row.accent=row:CreateTexture(nil,"ARTWORK")
    row.accent:SetTexture(bg);row.accent:SetPoint("TOPLEFT",1,-2)
    row.accent:SetPoint("BOTTOMLEFT",1,2);row.accent:SetWidth(3)
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(72,72);row.icon:SetPoint("TOPRIGHT",-14,-38)
    row.name=label(row,21,gold);row.name:SetPoint("TOPLEFT",22,-80)
    row.name:SetShadowColor(0,0,0,1);row.name:SetShadowOffset(1,-1)
    row.rank=label(row,11,cream);row.rank:SetPoint("TOPLEFT",23,-113)
    row.rank:SetShadowColor(0,0,0,1);row.rank:SetShadowOffset(1,-1)
    row.skill=label(row,10,muted);row.skill:SetPoint("TOPLEFT",23,-17)
    row.skill:SetJustifyH("LEFT")
    row.skill:SetShadowColor(0,0,0,1);row.skill:SetShadowOffset(1,-1)
    row.skillValue=label(row,17,cream);row.skillValue:SetPoint("TOPLEFT",22,-35)
    row.skillValue:SetShadowColor(0,0,0,1);row.skillValue:SetShadowOffset(1,-1)
    row:SetScript("OnEnter",function(self)
        self.shade:Show()
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.professionName,1,.82,.1)
            GameTooltip:AddLine("Klicken: Berufskapitel öffnen",.85,.79,.69)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave",function(self)
        row.shade:SetShown(self.professionName==selectedProfession)
        if GameTooltip then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick",function(self)
        C:OpenProfessionChapter(self.professionName)
    end)
    return row
end

local function createRecipeRow()
    local row=CreateFrame("Button",nil,recipePane)
    row:SetHeight(43)
    row.shade=row:CreateTexture(nil,"BACKGROUND")
    row.shade:SetTexture(bg);row.shade:SetAllPoints();row.shade:SetVertexColor(.09,.085,.075,.28)
    row.rule=row:CreateTexture(nil,"ARTWORK")
    row.rule:SetTexture(bg);row.rule:SetVertexColor(.43,.3,.14,.48)
    row.rule:SetPoint("BOTTOMLEFT",8,0);row.rule:SetPoint("BOTTOMRIGHT",-8,0)
    row.rule:SetHeight(C:RuleThickness())
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(30,30);row.icon:SetPoint("LEFT",10,0)
    row.known=row:CreateTexture(nil,"ARTWORK")
    row.known:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    row.known:SetSize(15,15)
    row.known:SetPoint("TOPLEFT",45,-5)
    row.name=label(row,13,cream);row.name:SetPoint("TOPLEFT",64,-5)
    row.name:SetHeight(16)
    row.meta=label(row,10,muted);row.meta:SetPoint("TOPLEFT",64,-24)
    row.meta:SetHeight(14)
    row.thresholds={}
    local colors={{1,.48,.12},{1,.82,.1},{.37,.8,.31},{.63,.66,.67}}
    for index=1,4 do
        local value=label(row,10,colors[index])
        value:SetPoint("TOPRIGHT",-8-(4-index)*28,-7)
        value:SetWidth(25);value:SetJustifyH("RIGHT")
        row.thresholds[index]=value
    end
    row:SetScript("OnEnter",function(self)
        self.shade:Show()
        if C.ShowRecordedRecipeTooltip then C:ShowRecordedRecipeTooltip(self) end
        if self.thresholdData and GameTooltip then
            GameTooltip:AddLine("Fertigkeit: Erlernen / Gelb / Grün / Grau",.84,.78,.67)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave",function(self)
        self.shade:SetShown(self.recipeKey==selectedRecipe)
        if GameTooltip then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick",function(self)
        selectedRecipe=self.recipeKey;C:RefreshProfessionBrowser()
        openProfession(self.recipeID)
    end)
    return row
end

local function createMaterialRow()
    local row=CreateFrame("Button",nil,detailPane)
    row:SetHeight(31)
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(25,25);row.icon:SetPoint("LEFT",0,0)
    row.text=label(row,12,cream);row.text:SetPoint("LEFT",34,0)
    row:SetScript("OnEnter",function(self) itemTooltip(self,self.itemID,self.itemName) end)
    row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    return row
end

local function setDetails(recipe,width,wide)
    detailPane.title:SetWidth(width-100)
    local materialX=wide and math.floor(width*.52) or 22
    detailPane.result:SetWidth(wide and (materialX-45) or (width-48))
    detailPane.skill:SetWidth(wide and (materialX-45) or (width-44))
    detailPane.materialLabel:ClearAllPoints()
    detailPane.materialLabel:SetPoint("TOPLEFT",detailPane,"TOPLEFT",materialX,wide and -116 or -249)
    detailPane.noMaterials:ClearAllPoints()
    detailPane.noMaterials:SetPoint("TOPLEFT",detailPane,"TOPLEFT",materialX+1,wide and -148 or -280)
    detailPane.empty:SetShown(not recipe)
    detailPane.icon:SetShown(not not recipe)
    detailPane.title:SetShown(not not recipe)
    detailPane.skillLabel:SetShown(not not recipe)
    detailPane.skill:SetShown(not not recipe)
    detailPane.outputLabel:SetShown(not not recipe)
    detailPane.result:SetShown(not not recipe)
    detailPane.materialLabel:SetShown(not not recipe)
    detailPane.learned:SetShown(not not recipe)
    if not recipe then
        for _,row in ipairs(materialRows) do row:Hide() end
        detailPane.noMaterials:Hide()
        detailPane.learned:Hide()
        detailPane.open:ClearAllPoints()
        detailPane.open:SetPoint("TOPLEFT",detailPane,"TOPLEFT",21,-111)
        detailPane.open:SetPoint("TOPRIGHT",detailPane,"TOPRIGHT",-21,-111)
        detailPane:SetHeight(180)
        return
    end
    detailPane.icon:SetTexture(recipe.icon or "Interface\\Icons\\INV_Scroll_03")
    detailPane.title:SetText(recipe.name)
    if recipe.thresholds then
        local t=recipe.thresholds
        detailPane.skill:SetText("|cffff7a1f"..(t[1] or "–").."|r  /  |cffffd119"..
            (t[2] or "–").."|r  /  |cff66cc55"..(t[3] or "–")..
            "|r  /  |cffa5a9ad"..(t[4] or "–").."|r")
    else
        detailPane.skill:SetText(recipe.skill and ("Fertigkeitsstufe "..tostring(recipe.skill)) or "Nicht erfasst")
    end
    local outputName=itemName(recipe.outputItemID)
    detailPane.result:SetText(outputName or (recipe.outputItemID and
        "Gegenstand nicht geladen" or "Kein Ergebnis erfasst"))
    if recipe.outputItemID then
        detailPane.result:SetTextColor(C:ItemQualityColor(recipe.outputItemID))
    else
        detailPane.result:SetTextColor(unpack(cream))
    end
    detailPane.learned:SetText(recipe.firstSeen and
        ("Erstmals erfasst: "..U.Date(recipe.firstSeen)) or "Erfassungszeitpunkt unbekannt")
    local reagents=recipe.reagents or {}
    for index,reagent in ipairs(reagents) do
        local row=materialRows[index]
        if not row then row=createMaterialRow();materialRows[index]=row end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",detailPane,"TOPLEFT",materialX+1,-(wide and 143 or 276)-(index-1)*34)
        row:SetWidth(width-materialX-24)
        local resolvedName=reagent.name or itemName(reagent.id)
        row.itemID=reagent.id;row.itemName=resolvedName
        row.icon:SetTexture(iconFor(reagent.id))
        row.text:SetTextColor(C:ItemQualityColor(reagent.id))
        row.text:SetText((tonumber(reagent.count) or 1).." × "..(resolvedName or
            (reagent.id and "Gegenstand nicht geladen" or "Unbekanntes Material")))
        row.text:SetWidth(width-materialX-67)
        row:Show()
    end
    for index=#reagents+1,#materialRows do materialRows[index]:Hide() end
    detailPane.noMaterials:SetShown(#reagents==0)
    local dateTop=wide and math.max(260,160+#reagents*34) or math.max(315,294+#reagents*34)
    detailPane.learned:ClearAllPoints()
    detailPane.learned:SetPoint("TOPLEFT",detailPane,"TOPLEFT",22,-dateTop)
    detailPane.open:ClearAllPoints()
    detailPane.open:SetPoint("TOPLEFT",detailPane,"TOPLEFT",21,-dateTop-30)
    detailPane.open:SetPoint("TOPRIGHT",detailPane,"TOPRIGHT",-21,-dateTop-30)
    detailPane:SetHeight(dateTop+78)
end

function C:RefreshProfessionBrowser()
    if not frame or not frame:IsShown() then return end
    local width=frame:GetWidth()
    chapter:SetWidth(width-8)
    hero:SetShown(not chapter:IsShown())
    professionPane:SetShown(not chapter:IsShown())
    local names=professions()
    if not selectedProfession or not (C.char.professions or {})[selectedProfession] then
        selectedProfession=names[1];selectedRecipe=nil
    end
    local total=0
    for _,name in ipairs(names) do total=total+U.Count(C.char.recipes and C.char.recipes[name]) end
    hero:SetWidth(width-8)
    hero.summary:SetText(#names.." Berufe  ·  "..total.." Rezepte")
    local lastSeen=tonumber(C.char.stats and C.char.stats.lastSkillUpdate) or 0
    for _,name in ipairs(names) do
        lastSeen=math.max(lastSeen,tonumber(C.char.professions[name].lastSeen) or 0)
    end
    hero.date:SetText(lastSeen>0 and ("Zuletzt erfasst: "..U.Date(lastSeen)) or "Noch kein Berufsstand erfasst")
    local columns=math.min(2,math.max(1,#names))
    local cardWidth=math.floor((width-28-(columns-1)*8)/columns)
    local mainCount=0
    for _,name in ipairs(names) do if not secondary[name] then mainCount=mainCount+1 end end
    local secondaryCount=#names-mainCount
    local mainLines=math.ceil(mainCount/columns)
    local secondaryLines=math.ceil(secondaryCount/columns)
    local mainCardsTop=mainCount>0 and 77 or 0
    local secondaryHeaderTop=mainCount>0 and (mainCardsTop+mainLines*160+12) or 50
    local secondaryCardsTop=secondaryHeaderTop+27
    local professionHeight=(secondaryCount>0 and (secondaryCardsTop+secondaryLines*160+9) or
        mainCount>0 and (mainCardsTop+mainLines*160+9) or 100)
    professionPane:SetWidth(width-8)
    professionPane:SetHeight(professionHeight)
    professionPane.groupTitle:SetText("MEINE BERUFE  ·  "..#names)
    professionPane.primaryLabel:ClearAllPoints()
    professionPane.primaryLabel:SetPoint("TOPLEFT",19,-51)
    professionPane.primaryLabel:SetText("HAUPTBERUFE  ·  "..mainCount)
    professionPane.primaryLabel:SetShown(mainCount>0)
    professionPane.primaryRule:ClearAllPoints()
    professionPane.primaryRule:SetPoint("TOPLEFT",professionPane,"TOPLEFT",177,-56)
    professionPane.primaryRule:SetPoint("TOPRIGHT",professionPane,"TOPRIGHT",-18,-56)
    professionPane.primaryRule:SetShown(mainCount>0)
    professionPane.secondaryLabel:ClearAllPoints()
    professionPane.secondaryLabel:SetPoint("TOPLEFT",19,-secondaryHeaderTop)
    professionPane.secondaryLabel:SetText("NEBENBERUFE  ·  "..secondaryCount)
    professionPane.secondaryLabel:SetShown(secondaryCount>0)
    professionPane.secondaryRule:ClearAllPoints()
    professionPane.secondaryRule:SetPoint("TOPLEFT",professionPane,"TOPLEFT",177,-secondaryHeaderTop-5)
    professionPane.secondaryRule:SetPoint("TOPRIGHT",professionPane,"TOPRIGHT",-18,-secondaryHeaderTop-5)
    professionPane.secondaryRule:SetShown(secondaryCount>0)
    for index,name in ipairs(names) do
        local row=professionRows[index]
        if not row then row=createProfessionRow();professionRows[index]=row end
        local position=secondary[name] and (index-mainCount-1) or (index-1)
        local column=position%columns
        local line=math.floor(position/columns)
        local cardsTop=secondary[name] and secondaryCardsTop or mainCardsTop
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",professionPane,"TOPLEFT",10+column*(cardWidth+8),-cardsTop-line*160)
        row:SetWidth(cardWidth)
        row.professionName=name
        local data=C.char.professions[name]
        local rank,maxRank=tonumber(data.rank) or 0,tonumber(data.maxRank) or 0
        local banner=professionBanner(name,data)
        row.banner:SetShown(banner~=nil)
        if banner then row.banner:SetTexture(banner) end
        row.icon:SetShown(not banner)
        row.icon:SetTexture(data.icon or icons[name] or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(C:LocalizeDisplay(name));row.name:SetWidth(cardWidth-244)
        local recipeCount=U.Count(C.char.recipes and C.char.recipes[name])
        row.rank:SetText(recipeCount..(recipeCount==1 and " Rezept" or " Rezepte"))
        row.rank:SetWidth(130)
        row.skill:SetText("FERTIGKEIT")
        row.skill:SetWidth(160)
        row.skillValue:SetText(rank.." / "..maxRank)
        row.skillValue:SetWidth(160)
        local active=name==selectedProfession and chapter:IsShown()
        row.banner:SetAlpha(1)
        row.shade:SetShown(active)
        row.shade:SetVertexColor(.065,.061,.055,active and .3 or .18)
        row.accent:SetShown(active)
        row.name:SetTextColor(1,.82,.1)
        row:SetBackdropBorderColor(active and .84 or .43,active and .62 or .32,active and .19 or .14,1)
        row:Show()
    end
    for index=#names+1,#professionRows do professionRows[index]:Hide() end
    local chapterWidth=chapter:GetWidth()
    local lowerTop=130
    local middle=math.floor(chapterWidth*.44)
    local right=chapterWidth-middle-48
    recipePane:ClearAllPoints()
    recipePane:SetPoint("TOPLEFT",chapter,"TOPLEFT",16,-lowerTop)
    recipePane:SetWidth(middle)
    detailPane:ClearAllPoints()
    detailPane:SetPoint("TOPLEFT",chapter,"TOPLEFT",middle+32,-lowerTop)
    detailPane:SetWidth(right)
    chapter.columnRule:ClearAllPoints()
    chapter.columnRule:SetPoint("TOPLEFT",chapter,"TOPLEFT",middle+24,-lowerTop-12)
    chapter.columnRule:SetPoint("BOTTOMLEFT",chapter,"BOTTOMLEFT",middle+24,20)
    local profession=C.char.professions[selectedProfession] or {}
    chapter.title:SetText(C:LocalizeDisplay(selectedProfession or "Beruf"))
    chapter.summary:SetText((tonumber(profession.rank) or 0).." / "..
        (tonumber(profession.maxRank) or 0).." Fertigkeit  ·  "..
        U.Count(C.char.recipes and C.char.recipes[selectedProfession]).." Rezepte")
    recipePane.title:SetText("Rezepte")
    recipePane.subtitle:SetText((tonumber(profession.rank) or 0).." / "..
        (tonumber(profession.maxRank) or 0).." Fertigkeit")
    local query=U.Trim(search:GetText()):lower()
    local recipes={}
    for _,recipe in ipairs(recipesFor(selectedProfession)) do
        if query=="" or recipe.name:lower():find(query,1,true) then
            recipes[#recipes+1]=recipe
        end
    end
    local pages=math.max(1,math.ceil(#recipes/PAGE_SIZE));page=math.min(page,pages)
    local start=(page-1)*PAGE_SIZE+1
    local chosen
    for index=start,math.min(#recipes,start+PAGE_SIZE-1) do
        if recipes[index].key==selectedRecipe then chosen=recipes[index];break end
    end
    if not chosen then chosen=recipes[start];selectedRecipe=chosen and chosen.key end
    recipePane.count:SetText(#recipes.." REZEPTE")
    pageLabel:SetText(page.." / "..pages)
    prevButton:SetEnabled(page>1);nextButton:SetEnabled(page<pages)
    prevButton:SetShown(pages>1);nextButton:SetShown(pages>1)
    pageLabel:SetShown(pages>1)
    recipePane.empty:SetShown(#recipes==0)
    recipePane.empty:SetText(query~="" and "Keine passenden Rezepte gefunden." or
        "Noch keine Rezepte erfasst. Öffne das Berufsfenster im Spiel.")
    for index=start,math.min(#recipes,start+PAGE_SIZE-1) do
        local used,entry=index-start+1,recipes[index]
        local row=recipeRows[used]
        if not row then row=createRecipeRow();recipeRows[used]=row end
        row:ClearAllPoints();row:SetPoint("TOPLEFT",recipePane,"TOPLEFT",9,-118-(used-1)*44)
        row:SetWidth(middle-18)
        row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Scroll_03")
        row.name:SetText(entry.name)
        row.name:SetWidth(entry.thresholds and middle-191 or middle-90)
        row.meta:SetText(ingredientSummary(entry.reagents))
        row.meta:SetWidth(middle-90)
        row.thresholdData=entry.thresholds
        for thresholdIndex,value in ipairs(row.thresholds) do
            local number=entry.thresholds and entry.thresholds[thresholdIndex]
            value:SetText(number and tostring(number) or "")
        end
        row.recipeID=entry.id;row.recipeName=entry.name;row.professionName=selectedProfession
        row.learnedAt=entry.firstSeen and U.Date(entry.firstSeen) or "unbekannt"
        row.recipeKey=entry.key
        row.shade:SetShown(entry.key==selectedRecipe)
        row:Show()
    end
    local visible=math.max(0,math.min(PAGE_SIZE,#recipes-start+1))
    for index=visible+1,#recipeRows do recipeRows[index]:Hide() end
    local recipeHeight=118+visible*44+(pages>1 and 50 or 20)
    setDetails(chosen,right,false)
    local commonHeight=math.max(470,recipeHeight,detailPane:GetHeight())
    recipePane:SetHeight(commonHeight)
    detailPane:SetHeight(commonHeight)
    detailPane.open:SetText("BERUFSFENSTER ÖFFNEN")
    chapter:SetHeight(lowerTop+commonHeight+18)
    frame:SetHeight(chapter:IsShown() and (chapter:GetHeight()+8) or (76+professionHeight+12))
    if frame:GetParent() then frame:GetParent():SetHeight(frame:GetHeight()+8) end
end

function C:OpenProfessionChapter(name,preserveSelection)
    if not chapter or not name or not (C.char.professions or {})[name] then return end
    selectedProfession=name
    if not preserveSelection then
        selectedRecipe=nil;page=1
        if search then search:SetText("") end
    end
    chapter:Show()
    self:RefreshProfessionBrowser()
end

function C:HideProfessionBrowser()
    if chapter then chapter:Hide() end
    if frame then frame:Hide() end
end

function C:ShowProfessionBrowser(parent,width)
    if not frame then
        frame=CreateFrame("Frame",nil,parent)
        frame:SetPoint("TOPLEFT",0,0)
        hero=CreateFrame("Frame",nil,frame)
        hero:SetPoint("TOPLEFT",4,0);hero:SetHeight(64)
        hero.caption=label(hero,10,gold);hero.caption:SetPoint("TOPLEFT",20,-12)
        hero.caption:SetText("CHRONICLE  /  HANDWERK")
        hero.summary=label(hero,16,cream);hero.summary:SetPoint("TOPLEFT",19,-31)
        hero.date=label(hero,11,muted);hero.date:SetPoint("TOPRIGHT",-20,-34)
        hero.date:SetJustifyH("RIGHT")
        hero.rule=hero:CreateTexture(nil,"ARTWORK")
        hero.rule:SetTexture(bg);hero.rule:SetVertexColor(.65,.45,.16,.72)
        hero.rule:SetPoint("BOTTOMLEFT",8,0);hero.rule:SetPoint("BOTTOMRIGHT",-8,0)
        hero.rule:SetHeight(C:RuleThickness())
        professionPane=CreateFrame("Frame",nil,frame);professionPane:SetPoint("TOPLEFT",4,-76)
        professionPane.groupTitle=label(professionPane,12,gold)
        professionPane.groupTitle:SetPoint("TOPLEFT",19,-19)
        professionPane.openHint=label(professionPane,11,muted)
        professionPane.openHint:SetPoint("TOPRIGHT",-19,-19)
        professionPane.openHint:SetJustifyH("RIGHT")
        professionPane.openHint:SetText("Banner anklicken, um das Berufskapitel zu öffnen")
        professionPane.primaryLabel=label(professionPane,11,gold)
        professionPane.primaryLabel:SetText("HAUPTBERUFE")
        professionPane.secondaryLabel=label(professionPane,11,gold)
        professionPane.secondaryLabel:SetText("NEBENBERUFE")
        professionPane.primaryRule=professionPane:CreateTexture(nil,"ARTWORK")
        professionPane.primaryRule:SetTexture(bg)
        professionPane.primaryRule:SetVertexColor(.48,.33,.14,.65)
        professionPane.primaryRule:SetHeight(C:RuleThickness())
        professionPane.secondaryRule=professionPane:CreateTexture(nil,"ARTWORK")
        professionPane.secondaryRule:SetTexture(bg)
        professionPane.secondaryRule:SetVertexColor(.48,.33,.14,.65)
        professionPane.secondaryRule:SetHeight(C:RuleThickness())
        chapter=CreateFrame("Frame",nil,frame)
        chapter:SetSize(width-8,650)
        chapter:SetPoint("TOPLEFT",frame,"TOPLEFT",4,0)
        chapter.caption=label(chapter,10,gold)
        chapter.caption:SetPoint("TOPLEFT",26,-21)
        chapter.caption:SetText("CHRONICLE  /  HANDWERKSKAPITEL")
        chapter.title=label(chapter,24,cream)
        chapter.title:SetPoint("TOPLEFT",26,-46)
        chapter.title:SetWidth(700)
        chapter.summary=label(chapter,11,muted)
        chapter.summary:SetPoint("TOPLEFT",27,-84)
        chapter.rule=chapter:CreateTexture(nil,"ARTWORK")
        chapter.rule:SetTexture(bg)
        chapter.rule:SetVertexColor(.65,.45,.17,.8)
        chapter.rule:SetPoint("TOPLEFT",22,-111)
        chapter.rule:SetPoint("TOPRIGHT",-22,-111)
        chapter.rule:SetHeight(C:RuleThickness())
        chapter.columnRule=chapter:CreateTexture(nil,"ARTWORK")
        chapter.columnRule:SetTexture(bg)
        chapter.columnRule:SetVertexColor(.56,.39,.17,.58)
        chapter.columnRule:SetWidth(C:RuleThickness())
        chapter.back=CreateFrame("Button",nil,chapter,"BackdropTemplate")
        C:StyleChronicleButton(chapter.back)
        chapter.back:SetSize(134,24)
        chapter.back:SetPoint("TOPRIGHT",-24,-22)
        chapter.back:SetText("‹ Alle Berufe")
        chapter.back:SetScript("OnClick",function()
            chapter:Hide()
            C:RefreshProfessionBrowser()
        end)
        chapter:SetScript("OnHide",function() if GameTooltip then GameTooltip:Hide() end end)
        chapter:Hide()
        recipePane=CreateFrame("Frame",nil,chapter)
        recipePane.title=label(recipePane,19,cream)
        recipePane.title:SetPoint("TOPLEFT",18,-16)
        recipePane.subtitle=label(recipePane,11,muted)
        recipePane.subtitle:SetPoint("TOPLEFT",19,-45)
        search=CreateFrame("EditBox",nil,recipePane,"InputBoxTemplate")
        search:SetSize(204,23);search:SetPoint("TOPLEFT",18,-69)
        search:SetAutoFocus(false);search:SetMaxLetters(80)
        searchHint=label(search,11,muted);searchHint:SetPoint("LEFT",7,0)
        searchHint:SetText("Rezept suchen ...")
        search:SetScript("OnTextChanged",function(self)
            searchHint:SetShown(self:GetText()=="");page=1;selectedRecipe=nil
            C:RefreshProfessionBrowser()
        end)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        recipePane.count=label(recipePane,10,gold)
        recipePane.count:SetPoint("TOPRIGHT",-18,-52);recipePane.count:SetJustifyH("RIGHT")
        recipePane.empty=label(recipePane,12,muted)
        recipePane.empty:SetPoint("TOPLEFT",19,-132)
        recipePane.legend=label(recipePane,10,muted)
        recipePane.legend:SetPoint("TOPLEFT",19,-98)
        recipePane.legend:SetText("FERTIGKEIT   |cffff7a1fErlernen|r   |cffffd119Gelb|r   |cff66cc55Grün|r   |cffa5a9adGrau|r")
        prevButton=CreateFrame("Button",nil,recipePane,"BackdropTemplate")
        C:StyleChronicleButton(prevButton);prevButton:SetSize(70,22)
        prevButton:SetPoint("BOTTOMLEFT",18,17);prevButton:SetText("‹ Zurück")
        prevButton:SetScript("OnClick",function() page=math.max(1,page-1);selectedRecipe=nil;C:RefreshProfessionBrowser() end)
        pageLabel=label(recipePane,11,muted)
        pageLabel:SetPoint("BOTTOM",0,23);pageLabel:SetJustifyH("CENTER")
        nextButton=CreateFrame("Button",nil,recipePane,"BackdropTemplate")
        C:StyleChronicleButton(nextButton);nextButton:SetSize(70,22)
        nextButton:SetPoint("BOTTOMRIGHT",-18,17);nextButton:SetText("Weiter ›")
        nextButton:SetScript("OnClick",function() page=page+1;selectedRecipe=nil;C:RefreshProfessionBrowser() end)
        detailPane=CreateFrame("Frame",nil,chapter);detailPane:SetHeight(545)
        detailPane.caption=label(detailPane,10,gold)
        detailPane.caption:SetPoint("TOPLEFT",21,-18)
        detailPane.caption:SetText("CHRONICLE  /  REZEPTDOSSIER")
        detailPane.icon=detailPane:CreateTexture(nil,"ARTWORK")
        detailPane.icon:SetSize(45,45);detailPane.icon:SetPoint("TOPLEFT",22,-50)
        detailPane.title=label(detailPane,18,cream)
        detailPane.title:SetPoint("TOPLEFT",78,-53)
        detailPane.empty=label(detailPane,13,muted)
        detailPane.empty:SetPoint("TOPLEFT",22,-60)
        detailPane.empty:SetText("Wähle ein Rezept aus der Liste.")
        detailPane.skillLabel=label(detailPane,11,gold)
        detailPane.skillLabel:SetPoint("TOPLEFT",22,-116)
        detailPane.skillLabel:SetText("FERTIGKEIT")
        detailPane.skill=label(detailPane,13,cream)
        detailPane.skill:SetPoint("TOPLEFT",22,-139)
        detailPane.outputLabel=label(detailPane,11,gold)
        detailPane.outputLabel:SetPoint("TOPLEFT",22,-182)
        detailPane.outputLabel:SetText("ERGEBNIS")
        detailPane.result=label(detailPane,13,cream)
        detailPane.result:SetPoint("TOPLEFT",22,-205)
        detailPane.materialLabel=label(detailPane,11,gold)
        detailPane.materialLabel:SetPoint("TOPLEFT",22,-249)
        detailPane.materialLabel:SetText("MATERIALIEN")
        detailPane.noMaterials=label(detailPane,12,muted)
        detailPane.noMaterials:SetPoint("TOPLEFT",23,-280)
        detailPane.noMaterials:SetText("Keine Materialien erfasst.")
        detailPane.learned=label(detailPane,11,muted)
        detailPane.open=CreateFrame("Button",nil,detailPane,"BackdropTemplate")
        C:StyleChronicleButton(detailPane.open)
        detailPane.open:SetHeight(27)
        detailPane.open:SetScript("OnClick",openProfession)
        frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        frame:SetScript("OnEvent",function(self,_,itemID)
            if itemID then pendingItemLoads[itemID]=nil end
            if self:IsShown() then C:RefreshProfessionBrowser() end
        end)
    end
    frame:SetParent(parent);frame:SetWidth(width);frame:Show()
    self:RefreshProfessionBrowser()
end
