local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton, addDivider = UI.makeTexture, UI.makeButton, UI.addDivider
local createPanelBanner = UI.createPanelBanner

local PROFESSION_ICONS = {
  Alchemy="Interface\\Icons\\Trade_Alchemy",
  Blacksmithing="Interface\\Icons\\Trade_BlackSmithing",
  Enchanting="Interface\\Icons\\Trade_Engraving",
  Engineering="Interface\\Icons\\Trade_Engineering",
  Leatherworking="Interface\\Icons\\Trade_LeatherWorking",
  Tailoring="Interface\\Icons\\Trade_Tailoring",
  Cooking="Interface\\Icons\\INV_Misc_Food_15",
  Fishing="Interface\\Icons\\Trade_Fishing",
  Herbalism="Interface\\Icons\\Spell_Nature_NatureTouchGrow",
  Mining="Interface\\Icons\\Trade_Mining",
  Skinning="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
  ["First Aid"]="Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}


local function createProfessionPanel(parent)
  local panel=CreateFrame("Frame",nil,parent)
  panel:SetPoint("TOPLEFT",15,-76); panel:SetPoint("BOTTOMRIGHT",-35,15)

  createPanelBanner(panel, "professions", -8, 8, -18)

  local _, faction = UnitFactionGroup("player")
  faction = faction or "Horde"
  local hub=(FLT.TRADE_HUBS or {})[faction] or (FLT.TRADE_HUBS or {}).Horde

  local function vendorFor(profession)
    for _,v in ipairs(FLT.PROFESSION_VENDORS or {}) do
      if v.profession == profession then
        local name = faction=="Alliance" and v.alliance or v.horde
        local x = faction=="Alliance" and v.ax or v.hx
        local y = faction=="Alliance" and v.ay or v.hy
        return name or "Profession quartermaster", x, y
      end
    end
    return "Profession quartermaster"
  end

  local function countRecipes(profession)
    local n=0
    for _,r in ipairs(FLT.MERCHANT_RECIPES or {}) do if r.profession==profession then n=n+1 end end
    return n
  end

  local function getFavorAmount()
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
      local info=C_CurrencyInfo.GetCurrencyInfo(3402)
      if info and info.quantity then return info.quantity end
    end
    if GetCurrencyInfo then
      local ok, _, amount = pcall(GetCurrencyInfo, 3402)
      if ok and type(amount)=="number" then return amount end
    end
    return nil
  end

  local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOPLEFT",8,-70); title:SetText("Merchant's Favor & Profession Recipes"); title:SetTextColor(1,0.82,0.20)

  local favorText=panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
  favorText:SetPoint("TOPRIGHT",-22,-74); favorText:SetTextColor(1,0.82,0.20)

  local function updateFavor()
    local amount=getFavorAmount()
    if amount then favorText:SetText("Merchant's Favor: "..amount) else favorText:SetText("Merchant's Favor") end
  end
  updateFavor()
  panel:SetScript("OnShow",function() updateFavor() end)

  local desc=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  desc:SetPoint("TOPLEFT",8,-97); desc:SetPoint("RIGHT",-22,0); desc:SetJustifyH("LEFT")
  desc:SetText("Earn Favor from Waylaid Crates, then browse your faction's profession recipes. The Merchant's Favor catalog and recipe/result IDs are embedded in OneForAll; native WoW tooltips are loaded directly from those IDs.")
  desc:SetTextColor(0.82,0.80,0.72)

  local nav=CreateFrame("Frame",nil,panel)
  nav:SetPoint("TOPLEFT",0,-128); nav:SetPoint("BOTTOMLEFT",0,0); nav:SetWidth(155)
  local navBg=makeTexture(nav,"BACKGROUND",0.035,0.030,0.022,0.88); navBg:SetAllPoints()
  local navRight=makeTexture(nav,"ARTWORK",0.72,0.50,0.12,0.35); navRight:SetPoint("TOPRIGHT",0,0); navRight:SetPoint("BOTTOMRIGHT",0,0); navRight:SetWidth(1)

  local body=CreateFrame("Frame",nil,panel)
  body:SetPoint("TOPLEFT",163,-128); body:SetPoint("BOTTOMRIGHT",0,0)

  local overview=CreateFrame("Frame",nil,body); overview:SetAllPoints()
  local campingView=CreateFrame("Frame",nil,body); campingView:SetAllPoints(); campingView:Hide()
  local recipeView=CreateFrame("Frame",nil,body); recipeView:SetAllPoints(); recipeView:Hide()
  local navButtons={}

  local function setNavButtonState(key)
    for k,b in pairs(navButtons) do
      if k==key then
        b._bg:SetColorTexture(0.14,0.105,0.045,1)
        b._label:SetTextColor(1,0.86,0.38)
      else
        b._bg:SetColorTexture(0.075,0.065,0.050,0.98)
        b._label:SetTextColor(0.96,0.78,0.34)
      end
    end
  end

  -- Overview content -------------------------------------------------------
  local ovTitle=overview:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  ovTitle:SetPoint("TOPLEFT",8,-3); ovTitle:SetText("How to get Merchant's Favor"); ovTitle:SetTextColor(1,0.82,0.20)

  local ovIntro=overview:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  ovIntro:SetPoint("TOPLEFT",8,-31); ovIntro:SetWidth(790); ovIntro:SetJustifyH("LEFT")
  ovIntro:SetText("Waylaid Crates are world drops. Use a crate to reveal its shipment, provide one complete material bundle, then deliver the sealed crate to your faction's supply representative.")
  ovIntro:SetTextColor(0.85,0.82,0.75)

  -- Two columns, no inner scrolling: steps + trade hub on the left, the
  -- crate reward table on the right.
  local stepsBox=CreateFrame("Frame",nil,overview); stepsBox:SetPoint("TOPLEFT",0,-72); stepsBox:SetSize(395,190)
  local sbg=makeTexture(stepsBox,"BACKGROUND",0.075,0.055,0.027,0.76); sbg:SetAllPoints()
  local sh=stepsBox:CreateFontString(nil,"OVERLAY","GameFontNormal"); sh:SetPoint("TOPLEFT",12,-10); sh:SetText("How it works"); sh:SetTextColor(1,0.82,0.20)
  local stepY=-34
  for i,step in ipairs(FLT.CRATE_STEPS or {}) do
    local num=stepsBox:CreateFontString(nil,"OVERLAY","GameFontNormal"); num:SetPoint("TOPLEFT",12,stepY); num:SetText(i.."."); num:SetTextColor(1,0.76,0.20)
    local fs=stepsBox:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fs:SetPoint("TOPLEFT",34,stepY-1); fs:SetWidth(348); fs:SetJustifyH("LEFT"); fs:SetText(step)
    stepY=stepY-math.max(20,(fs:GetStringHeight() or 14)+8)
  end
  stepsBox:SetHeight(math.max(150,-stepY+8))

  local hubBox=CreateFrame("Frame",nil,overview); hubBox:SetPoint("TOPLEFT",stepsBox,"BOTTOMLEFT",0,-10); hubBox:SetSize(395,70)
  local hb=makeTexture(hubBox,"BACKGROUND",0.16,0.11,0.045,0.88); hb:SetAllPoints()
  local hf=hubBox:CreateFontString(nil,"OVERLAY","GameFontNormal"); hf:SetPoint("TOPLEFT",12,-10); hf:SetWidth(290); hf:SetJustifyH("LEFT"); hf:SetText((hub and hub.name or "Trade hub")); hf:SetTextColor(1,0.82,0.20)
  local hw=hubBox:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hw:SetPoint("TOPLEFT",12,-32); hw:SetWidth(290); hw:SetJustifyH("LEFT")
  if hub then hw:SetText(string.format("%s, %s\nTurn-in: %s",hub.place or "",hub.zone or "",hub.handin or "supply representative")) else hw:SetText("Location unavailable") end
  local hubMap=makeButton(hubBox,"Map",72,24); hubMap:SetPoint("RIGHT",-12,0)
  if hub then hubMap:SetScript("OnClick",function() FLT:ShowOnMap({zone=hub.zone,x=hub.x,y=hub.y,name=hub.name}) end) else hubMap:Disable() end

  local rewards=CreateFrame("Frame",nil,overview); rewards:SetPoint("TOPLEFT",407,-72); rewards:SetPoint("TOPRIGHT",-22,-72); rewards:SetHeight(330)
  local rbg=makeTexture(rewards,"BACKGROUND",0.034,0.044,0.056,0.80); rbg:SetAllPoints()
  local rewardsTitle=rewards:CreateFontString(nil,"OVERLAY","GameFontNormal")
  rewardsTitle:SetPoint("TOPLEFT",12,-10); rewardsTitle:SetText("Crate rewards (beta)"); rewardsTitle:SetTextColor(1,0.82,0.20)
  local rewardHead=CreateFrame("Frame",nil,rewards); rewardHead:SetPoint("TOPLEFT",0,-32); rewardHead:SetPoint("TOPRIGHT",0,-32); rewardHead:SetHeight(22)
  local rhbg=makeTexture(rewardHead,"BACKGROUND",0.05,0.05,0.05,0.96); rhbg:SetAllPoints()
  local headers={{12,"Crate"},{214,"Level"},{262,"Reward"}}
  for _,h in ipairs(headers) do local f=rewardHead:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f:SetPoint("LEFT",h[1],0); f:SetText(h[2]); f:SetTextColor(0.90,0.78,0.53) end
  local ry=-56
  for i,g in ipairs(FLT.FAVOR_GUIDE or {}) do
    local row=CreateFrame("Frame",nil,rewards); row:SetPoint("TOPLEFT",0,ry); row:SetPoint("TOPRIGHT",0,ry); row:SetHeight(36); ry=ry-37
    local bg=makeTexture(row,"BACKGROUND",0.055,0.052,0.047,(i%2==0) and 0.94 or 0.70); bg:SetAllPoints()
    local a=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); a:SetPoint("TOPLEFT",12,-5); a:SetWidth(196); a:SetJustifyH("LEFT"); a:SetText(g.tier)
    local d=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); d:SetPoint("TOPLEFT",12,-20); d:SetWidth(196); d:SetJustifyH("LEFT"); d:SetWordWrap(false); d:SetText(g.note or "")
    local b=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b:SetPoint("LEFT",214,0); b:SetWidth(44); b:SetJustifyH("LEFT"); b:SetText(g.level)
    local c=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); c:SetPoint("LEFT",262,0); c:SetPoint("RIGHT",-6,0); c:SetJustifyH("LEFT"); c:SetText(g.reward); c:SetTextColor(1,0.82,0.20)
    row:EnableMouse(true)
    row:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(g.tier,1,0.82,0)
      GameTooltip:AddLine("Reward: "..(g.reward or "?"),1,1,1); if g.note then GameTooltip:AddLine(g.note,0.8,0.8,0.8,true) end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
  end
  rewards:SetHeight(-ry+8)
  local tip=rewards:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  tip:SetPoint("TOPLEFT",rewards,"BOTTOMLEFT",4,-6); tip:SetWidth(400); tip:SetJustifyH("LEFT")
  tip:SetText("One complete bundle is enough to seal a crate. Beta values can still change.")



  -- Camping buffs / profession objects ------------------------------------
  local campTitle=campingView:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  campTitle:SetPoint("TOPLEFT",8,-3); campTitle:SetText("Camping Buffs & Profession Objects"); campTitle:SetTextColor(1,0.82,0.20)
  local campIntro=campingView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  campIntro:SetPoint("TOPLEFT",8,-31); campIntro:SetWidth(790); campIntro:SetJustifyH("LEFT")
  campIntro:SetText("Choose a profession below to expand its camping objects. Sit/rest at a campfire to receive applicable buffs. Camping features share a 60-minute cooldown and beta values can change.")
  campIntro:SetTextColor(0.85,0.82,0.75)
  local csf=CreateFrame("ScrollFrame",nil,campingView,"UIPanelScrollFrameTemplate")
  csf:SetPoint("TOPLEFT",0,-66); csf:SetPoint("BOTTOMRIGHT",0,0)
  local cchild=CreateFrame("Frame",nil,csf); cchild:SetSize(780,1); csf:SetScrollChild(cchild)
  -- Headers and item rows are created once; expanding/collapsing only
  -- re-positions and shows/hides them.
  local campingGroups={}
  local layoutCamping

  for _,prof in ipairs(FLT.CAMPING_PROFESSIONS or {}) do
    local group={prof=prof, items={}}
    campingGroups[#campingGroups+1]=group

    local ph=CreateFrame("Button",nil,cchild); ph:SetSize(775,36)
    group.header=ph
    local pbg=makeTexture(ph,"BACKGROUND",0.15,0.105,0.045,0.90); pbg:SetAllPoints()
    local phi=makeTexture(ph,"HIGHLIGHT",0.42,0.30,0.10,0.18); phi:SetAllPoints()
    local toggle=ph:CreateFontString(nil,"OVERLAY","GameFontNormal")
    toggle:SetPoint("LEFT",12,0); toggle:SetWidth(18); toggle:SetJustifyH("CENTER"); toggle:SetTextColor(1,0.82,0.20)
    group.toggle=toggle
    local picon=ph:CreateTexture(nil,"ARTWORK"); picon:SetSize(22,22); picon:SetPoint("LEFT",36,0)
    picon:SetTexture(PROFESSION_ICONS[prof.profession] or "Interface\\Icons\\INV_Misc_QuestionMark")
    local pt=ph:CreateFontString(nil,"OVERLAY","GameFontNormal")
    pt:SetPoint("LEFT",66,0); pt:SetText(prof.profession); pt:SetTextColor(1,0.82,0.20)
    local count=ph:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    count:SetPoint("RIGHT",-14,0); count:SetText(tostring(#(prof.items or {})).." camping objects")
    ph:SetScript("OnClick",function()
      local expanded=ForeverCompanionDB.campingExpanded
      expanded[prof.profession]=not expanded[prof.profession] or nil
      layoutCamping()
    end)

    for ii,obj in ipairs(prof.items or {}) do
      local row=CreateFrame("Button",nil,cchild); row:SetSize(775,44)
      group.items[#group.items+1]=row
      local bg=makeTexture(row,"BACKGROUND",0.055,0.052,0.047,(ii%2==0) and 0.94 or 0.78); bg:SetAllPoints()
      local hi=makeTexture(row,"HIGHLIGHT",0.42,0.30,0.10,0.22); hi:SetAllPoints()
      local nm=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nm:SetPoint("TOPLEFT",36,-8); nm:SetWidth(200); nm:SetJustifyH("LEFT"); nm:SetText(obj.name)
      local sk=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sk:SetPoint("TOPLEFT",245,-9); sk:SetWidth(72); sk:SetJustifyH("LEFT"); sk:SetText("Skill "..tostring(obj.skill or "?")); sk:SetTextColor(1,0.82,0.20)
      local ef=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ef:SetPoint("TOPLEFT",325,-8); ef:SetWidth(430); ef:SetJustifyH("LEFT"); ef:SetText(obj.effect or "")
      row:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine(obj.name,1,0.82,0)
        GameTooltip:AddDoubleLine(prof.profession,"Requires skill "..tostring(obj.skill or "?"),0.65,0.85,1,1,1,1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(obj.effect or "Camping feature",0.25,1.0,0.25,true)
        if obj.reagents and obj.reagents~="" then
          GameTooltip:AddLine(" "); GameTooltip:AddLine("Reagents",1,0.82,0.20); GameTooltip:AddLine(obj.reagents,0.85,0.85,0.85,true)
        end
        GameTooltip:AddLine(" "); GameTooltip:AddLine("All camping features share a 60-minute cooldown. Beta values may change.",0.68,0.68,0.68,true)
        GameTooltip:Show()
      end)
      row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
  end

  layoutCamping=function()
    ForeverCompanionDB.campingExpanded = ForeverCompanionDB.campingExpanded or {}
    local cy=-2
    for _,group in ipairs(campingGroups) do
      local expanded=ForeverCompanionDB.campingExpanded[group.prof.profession]==true
      group.header:ClearAllPoints(); group.header:SetPoint("TOPLEFT",0,cy); cy=cy-38
      group.toggle:SetText(expanded and "-" or "+")
      for _,row in ipairs(group.items) do
        if expanded then
          row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,cy); cy=cy-45; row:Show()
        else
          row:Hide()
        end
      end
      if expanded then cy=cy-6 end
    end
    cchild:SetHeight(math.max(1,-cy+8))
  end

  layoutCamping()

  -- Recipe browser ---------------------------------------------------------
  local recipeTitle=recipeView:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  recipeTitle:SetPoint("TOPLEFT",8,-3); recipeTitle:SetTextColor(1,0.82,0.20)
  local recipeMeta=recipeView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  recipeMeta:SetPoint("TOPLEFT",8,-31); recipeMeta:SetWidth(665); recipeMeta:SetJustifyH("LEFT"); recipeMeta:SetTextColor(0.82,0.80,0.72)
  local vendorMap=makeButton(recipeView,"Vendor Map",94,24); vendorMap:SetPoint("TOPRIGHT",-8,-7)

  local rhead=CreateFrame("Frame",nil,recipeView); rhead:SetPoint("TOPLEFT",0,-65); rhead:SetPoint("TOPRIGHT",-20,-65); rhead:SetHeight(28)
  local rbg=makeTexture(rhead,"BACKGROUND",0.05,0.05,0.05,0.96); rbg:SetAllPoints()
  local rh={{14,"Recipe"},{540,"Skill"},{630,"Cost"}}
  for _,h in ipairs(rh) do local f=rhead:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f:SetPoint("LEFT",h[1],0); f:SetText(h[2]); f:SetTextColor(0.90,0.78,0.53) end
  addDivider(rhead,526); addDivider(rhead,616)

  local rsf=CreateFrame("ScrollFrame",nil,recipeView,"UIPanelScrollFrameTemplate")
  rsf:SetPoint("TOPLEFT",0,-94); rsf:SetPoint("BOTTOMRIGHT",0,0)
  local rchild=CreateFrame("Frame",nil,rsf); rchild:SetSize(780,1); rsf:SetScrollChild(rchild)
  local recipeRowsByProfession={}

  local function recipeFullName(recipe)
    return ((FLT.RECIPE_PREFIX or {})[recipe.profession] or "")..recipe.name
  end

  local STAT_LABELS = {
    ITEM_MOD_STRENGTH_SHORT="Strength", ITEM_MOD_AGILITY_SHORT="Agility", ITEM_MOD_STAMINA_SHORT="Stamina",
    ITEM_MOD_INTELLECT_SHORT="Intellect", ITEM_MOD_SPIRIT_SHORT="Spirit", ITEM_MOD_ARMOR_SHORT="Armor",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT="Defense", ITEM_MOD_ATTACK_POWER_SHORT="Attack Power",
    ITEM_MOD_SPELL_POWER_SHORT="Spell Power", ITEM_MOD_HEALING_DONE_SHORT="Healing",
    ITEM_MOD_CRIT_RATING_SHORT="Critical Strike", ITEM_MOD_HIT_RATING_SHORT="Hit",
  }

  local function addRuntimeResultDetails(recipe)
    local added=false
    local info = FLT.CRAFTED_RESULT_INFO and FLT.CRAFTED_RESULT_INFO[recipe.name]
    local extra = FLT.PROFESSION_RESULT_INFO and FLT.PROFESSION_RESULT_INFO[recipe.name]

    if info then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Crafted result",1,0.82,0.20)
      GameTooltip:AddLine(recipe.name,0.95,0.95,0.95)
      if info.level then GameTooltip:AddLine("Requires Level "..tostring(info.level),1,1,1) end
      if info.effect then GameTooltip:AddLine(info.effect,0.25,1.00,0.25,true) end
      if info.reagents then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Reagents: "..info.reagents,0.82,0.82,0.82,true)
      end
      return true
    end

    -- Ask the client for the crafted *result* by name.  This works immediately
    -- when another addon (for example AtlasLoot) or the client has already
    -- loaded the item.  It lets us show exact item level / requirements / stats
    -- for Blacksmithing, Leatherworking, Tailoring and Engineering without
    -- duplicating Blizzard's item database.
    local resultName, resultLink, itemLevel, reqLevel, itemType, itemSubType, _
    if GetItemInfo then
      resultName, resultLink, _, itemLevel, reqLevel, itemType, itemSubType = GetItemInfo(recipe.name)
    end
    if resultName then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Crafted result",1,0.82,0.20)
      GameTooltip:AddLine(resultName,0.95,0.95,0.95)
      if itemLevel and itemLevel > 0 then GameTooltip:AddLine("Item Level "..tostring(itemLevel),1,0.82,0) end
      if reqLevel and reqLevel > 0 then GameTooltip:AddLine("Requires Level "..tostring(reqLevel),1,1,1) end
      if itemType and itemType ~= "" then
        local kind=itemType
        if itemSubType and itemSubType ~= "" and itemSubType ~= itemType then kind=kind.." - "..itemSubType end
        GameTooltip:AddLine(kind,0.9,0.9,0.9)
      end
      if GetItemStats and resultLink then
        local stats=GetItemStats(resultLink) or {}
        local shown=0
        for key,value in pairs(stats) do
          if value and value ~= 0 and shown < 10 then
            local label=STAT_LABELS[key] or key:gsub("^ITEM_MOD_",""):gsub("_SHORT$",""):gsub("_"," "):lower():gsub("^%l",string.upper)
            GameTooltip:AddDoubleLine(label,tostring(value),0.75,0.9,1,1,1,1)
            shown=shown+1
          end
        end
      end
      if GetItemSpell and resultLink then
        local _, spellID = GetItemSpell(resultLink)
        if spellID and GetSpellDescription then
          local d=GetSpellDescription(spellID)
          if d and d ~= "" then GameTooltip:AddLine(d,0.25,1.00,0.25,true) end
        end
      end
      added=true
    end

    -- Enchants and several profession objects are spells rather than normal
    -- inventory results.  Ask the client for the tradeskill spell and append its
    -- real description when available.
    local spellID
    if GetSpellInfo then
      local _,_,_,_,_,_,sid = GetSpellInfo(recipe.name)
      spellID=sid
    end
    if spellID and GetSpellDescription then
      local d=GetSpellDescription(spellID)
      if d and d ~= "" and not d:find("Creates ") then
        if not added then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine(recipe.profession == "Enchanting" and "Enchant effect" or "Crafted effect",1,0.82,0.20)
        end
        GameTooltip:AddLine(d,0.25,1.00,0.25,true)
        added=true
      end
    end

    -- Embedded standalone profession data carries the authoritative craft
    -- spell ID.  Prefer the Forever client's real spell description when it is
    -- available; this is especially important for enchants, which often do not
    -- create a normal inventory item.
    local offline = FLT.GetOfflineProfessionResult and FLT:GetOfflineProfessionResult(recipe) or nil
    if offline and offline.spellID then
      local d
      if C_Spell and C_Spell.GetSpellDescription then
        local ok, value = pcall(C_Spell.GetSpellDescription, offline.spellID)
        if ok then d = value end
      end
      if (not d or d == "") and GetSpellDescription then
        local ok, value = pcall(GetSpellDescription, offline.spellID)
        if ok then d = value end
      end
      if d and d ~= "" and not d:find("Creates ") then
        if not added then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine(recipe.profession == "Enchanting" and "Enchant effect" or "Crafted effect",1,0.82,0.20)
        end
        GameTooltip:AddLine(d,0.25,1.00,0.25,true)
        added=true
      end
    end
    if offline and not added and offline.effect and offline.effect ~= "" then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(recipe.profession == "Enchanting" and "Enchant effect" or "Crafted effect",1,0.82,0.20)
      GameTooltip:AddLine(tostring(offline.effect),0.25,1.00,0.25,true)
      added=true
    end
    if offline and not added and offline.stats and next(offline.stats) then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(recipe.profession == "Enchanting" and "Enchant effect" or "Crafted stats",1,0.82,0.20)
      for key,value in pairs(offline.stats) do
        local label=STAT_LABELS[key] or tostring(key):gsub("^ITEM_MOD_",""):gsub("_SHORT$",""):gsub("_"," ")
        GameTooltip:AddDoubleLine(label,tostring(value),0.75,0.9,1,1,1,1)
      end
      added=true
    end

    if extra then
      if not added then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(extra.label or "Crafted result",1,0.82,0.20)
      end
      GameTooltip:AddLine(extra.effect,0.25,1.00,0.25,true)
      added=true
    end

    if not added then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Crafted result",1,0.82,0.20)
      if recipe.profession == "Enchanting" and recipe.name:find("^Enchant ") then
        GameTooltip:AddLine("Applies "..recipe.name..". Exact effect text is loaded automatically when the Forever client exposes this enchant spell.",0.72,0.72,0.72,true)
      else
        GameTooltip:AddLine(recipe.name,0.95,0.95,0.95)
        GameTooltip:AddLine("Exact result stats/effect are loaded automatically from the client when the crafted result is available in the item cache.",0.72,0.72,0.72,true)
      end
    end
    return added
  end

  local function showRecipeTooltip(row, recipe, vendor)
    GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
    local full=recipeFullName(recipe)

    -- Preferred path: OneForAll resolves the actual crafted result
    -- directly from WoW Forever's own item/tradeskill APIs. No external addon
    -- is required. If the item data is already available, show Blizzard's
    -- native tooltip; otherwise continue with our built-in fallback and retry
    -- the native tooltip once the client has had a moment to load the item.
    local offline = FLT.GetOfflineProfessionResult and FLT:GetOfflineProfessionResult(recipe) or nil
    if offline and offline.craftedItemID and GameTooltip.SetHyperlink then
      if FLT.RequestRecipeItemData then FLT:RequestRecipeItemData(offline.craftedItemID) end
      -- We already know the exact crafted item ID from the embedded Forever
      -- data, so ask Blizzard's tooltip directly instead of waiting for a name
      -- lookup to succeed first. The client will request the item data if it is
      -- not cached yet.
      local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:"..tostring(offline.craftedItemID))
      if ok then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Recipe",1,0.82,0.20)
        GameTooltip:AddLine(full,0.95,0.95,0.95,true)
        GameTooltip:AddDoubleLine("Requires "..tostring(recipe.profession), tostring(recipe.skill or "-"), 1,0.25,0.25, 1,1,1)
        GameTooltip:AddDoubleLine("Merchant's Favor",tostring(recipe.cost),1,0.82,0.20,1,0.82,0.20)
        GameTooltip:AddLine("Sold by "..(vendor or "profession quartermaster"),0.65,0.85,1)
        GameTooltip:Show()
        if C_Timer and C_Timer.After and GetItemInfo and not GetItemInfo(offline.craftedItemID) then
          C_Timer.After(0.35,function()
            if row and row.IsMouseOver and row:IsMouseOver() and GetItemInfo(offline.craftedItemID) then
              showRecipeTooltip(row,recipe,vendor)
            end
          end)
        end
        return
      end
    end
    local itemId = FLT.GetRecipeItemID and FLT:GetRecipeItemID(recipe) or nil
    local link = FLT.GetRecipeItemLink and FLT:GetRecipeItemLink(recipe) or nil

    -- Ask the client for native item data when we know the Forever item ID.
    -- The addon's own crafted-result data is appended in either case so the
    -- player can see what the resulting item actually does.
    if itemId and FLT.RequestRecipeItemData then FLT:RequestRecipeItemData(itemId) end

    local cachedName = nil
    if itemId and GetItemInfo then cachedName = GetItemInfo(itemId) end
    if link and cachedName and GameTooltip.SetHyperlink then
      GameTooltip:SetHyperlink(link)
      addRuntimeResultDetails(recipe)
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine("Merchant's Favor",tostring(recipe.cost),1,0.82,0.20,1,0.82,0.20)
      GameTooltip:AddLine("Sold by "..(vendor or "profession quartermaster"),0.65,0.85,1)
    else
      GameTooltip:ClearLines()
      GameTooltip:AddLine(full,1,0.82,0)
      GameTooltip:AddLine("Binds when picked up",1,1,1)
      GameTooltip:AddLine("Requires "..recipe.profession.." ("..tostring(recipe.skill)..")",1,0.25,0.25)
      GameTooltip:AddLine(" ")
      if recipe.profession == "Enchanting" and recipe.name:find("^Enchant ") then
        GameTooltip:AddLine("Teaches you "..recipe.name..".",0.25,1.00,0.25,true)
      else
        GameTooltip:AddLine("Teaches you how to craft "..recipe.name..".",0.25,1.00,0.25,true)
      end
      addRuntimeResultDetails(recipe)
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine("Cost",recipe.cost.." Merchant's Favor",0.80,0.80,0.80,1,0.82,0.20)
      GameTooltip:AddLine("Sold by "..(vendor or "profession quartermaster"),0.65,0.85,1)
      if itemId then
        GameTooltip:AddLine("Item ID: "..tostring(itemId),0.55,0.55,0.55)
      end
    end
    GameTooltip:Show()
  end


  -- WoW never frees frames, so recipe rows are created once per profession and
  -- afterwards only shown/hidden. (Previously every click created a new set.)
  local function buildRecipeRows(profession, vendor)
    local list={}
    local yoff=-2; local idx=0
    for _,recipe in ipairs(FLT.MERCHANT_RECIPES or {}) do
      if recipe.profession==profession then
        idx=idx+1
        local row=CreateFrame("Button",nil,rchild); row:SetSize(775,31); row:SetPoint("TOPLEFT",0,yoff); yoff=yoff-32
        local bg=makeTexture(row,"BACKGROUND",0.055,0.052,0.047,(idx%2==0) and 0.94 or 0.78); bg:SetAllPoints()
        local hover=makeTexture(row,"HIGHLIGHT",0.42,0.30,0.10,0.22); hover:SetAllPoints()
        local icon=row:CreateTexture(nil,"ARTWORK"); icon:SetSize(20,20); icon:SetPoint("LEFT",10,0); icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
        local nm=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nm:SetPoint("LEFT",40,0); nm:SetWidth(480); nm:SetJustifyH("LEFT"); nm:SetText(recipe.name)
        local sk=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sk:SetPoint("LEFT",540,0); sk:SetWidth(70); sk:SetJustifyH("LEFT"); sk:SetText(recipe.skill)
        local co=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); co:SetPoint("LEFT",630,0); co:SetWidth(125); co:SetJustifyH("LEFT"); co:SetText(recipe.cost.." Favor"); co:SetTextColor(1,0.82,0.20)
        addDivider(row,526); addDivider(row,616)
        row:SetScript("OnEnter",function(self) showRecipeTooltip(self,recipe,vendor) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        list[#list+1]=row
      end
    end
    list.height=math.max(1,-yoff+8)
    return list
  end

  local function showProfession(profession)
    overview:Hide(); campingView:Hide(); recipeView:Show(); setNavButtonState(profession)
    local vendor,x,y=vendorFor(profession)
    local count=countRecipes(profession)
    recipeTitle:SetText(profession.." - Merchant's Favor Recipes")
    recipeMeta:SetText(string.format("%s  |  %d recipes  |  %s",vendor,count,hub and (hub.place..", "..hub.zone) or "trade hub"))
    vendorMap:SetScript("OnClick",nil)
    if x and y and hub then vendorMap:Enable(); vendorMap:SetScript("OnClick",function() FLT:ShowOnMap({zone=hub.zone,x=x,y=y,name=vendor}) end) else vendorMap:Disable() end

    for key,list in pairs(recipeRowsByProfession) do
      if key~=profession then for _,row in ipairs(list) do row:Hide() end end
    end
    local list=recipeRowsByProfession[profession]
    if not list then list=buildRecipeRows(profession,vendor); recipeRowsByProfession[profession]=list end
    for _,row in ipairs(list) do row:Show() end
    rchild:SetHeight(list.height); rsf:SetVerticalScroll(0)
  end

  local function showOverview()
    recipeView:Hide(); campingView:Hide(); overview:Show(); setNavButtonState("overview"); updateFavor()
  end

  local function showCamping()
    recipeView:Hide(); overview:Hide(); campingView:Show(); setNavButtonState("camping")
  end

  local navY=-10
  local campingButton=makeButton(nav,"Camping Buffs",135,27); campingButton:SetPoint("TOPLEFT",10,navY); navY=navY-34
  campingButton:SetScript("OnClick",showCamping); navButtons.camping=campingButton
  local sep=makeTexture(nav,"ARTWORK",0.72,0.50,0.12,0.30); sep:SetPoint("TOPLEFT",10,navY+4); sep:SetPoint("TOPRIGHT",-10,navY+4); sep:SetHeight(1); navY=navY-10
  local overviewButton=makeButton(nav,"Favor Overview",135,27); overviewButton:SetPoint("TOPLEFT",10,navY); navY=navY-32
  overviewButton:SetScript("OnClick",showOverview); navButtons.overview=overviewButton
  for _,profession in ipairs(FLT.PROFESSION_ORDER or {}) do
    local label=profession
    local b=makeButton(nav,label,135,27); b:SetPoint("TOPLEFT",10,navY); navY=navY-32
    b:SetScript("OnClick",function() showProfession(profession) end)
    navButtons[profession]=b
  end

  showCamping()
  panel:Hide(); return panel
end


UI.RegisterPanel({ key="professions", label="Professions", order=5, tabWidth=132, create=createProfessionPanel })
