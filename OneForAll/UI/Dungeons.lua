local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton = UI.makeTexture, UI.makeButton
local createPanelBanner = UI.createPanelBanner
local LAYOUT = UI.LAYOUT
local ASSET_ROOT = UI.ASSET_ROOT
local H = UI.DungeonHelpers
local QUEST_STATUS_LABELS = H.QUEST_STATUS_LABELS
local getDungeonQuestStatus = H.getDungeonQuestStatus
local getQuestLogInfo = H.getQuestLogInfo
local getChainProgress = H.getChainProgress
local dungeonSideColor = H.dungeonSideColor
local normalizeDungeonItem = H.normalizeDungeonItem
local colorDungeonItemText = H.colorDungeonItemText
local tryShowItemTooltip = H.tryShowItemTooltip
local handleDungeonItemClick = H.handleDungeonItemClick
local dungeonItemIcon = H.dungeonItemIcon
local setBossPortrait = UI.setBossPortrait

local DUNGEON_ART = {
  hall=ASSET_ROOT.."Dungeons\\hall_of_thanes",
  rfc=ASSET_ROOT.."Dungeons\\ragefire_chasm",
  lordaeron=ASSET_ROOT.."Dungeons\\ruins_of_lordaeron",
  deadmines=ASSET_ROOT.."Dungeons\\deadmines",
  wc=ASSET_ROOT.."Dungeons\\wailing_caverns",
  sfk=ASSET_ROOT.."Dungeons\\shadowfang_keep",
  bfd=ASSET_ROOT.."Dungeons\\blackfathom_deeps",
  stockade=ASSET_ROOT.."Dungeons\\the_stockade",
  excavation=ASSET_ROOT.."Dungeons\\excavation_site",
  dalaran=ASSET_ROOT.."Dungeons\\city_of_dalaran",
  gnomeregan=ASSET_ROOT.."Dungeons\\gnomeregan",
  smgy=ASSET_ROOT.."Dungeons\\sm_graveyard",
}

-- Collapsible level brackets for the browse list (grouped by minimum level).
local BRACKETS = {
  { id="10", label="Levels 10 - 19", min=0,  max=19 },
  { id="20", label="Levels 20 - 29", min=20, max=29 },
  { id="30", label="Levels 30 - 39", min=30, max=39 },
  { id="40", label="Levels 40 - 49", min=40, max=49 },
  { id="50", label="Levels 50 - 60", min=50, max=99 },
}

UI.DUNGEON_BRACKETS = BRACKETS

local function playerLevel()
  return (UnitLevel and tonumber(UnitLevel("player"))) or 1
end

-- green = fits your level, yellow = slightly below, orange/red = too low,
-- grey = outleveled.
local function levelColor(d)
  local pl=playerLevel()
  local lo=d.minLevel or 0
  local hi=d.maxLevel or lo
  if pl>hi then return 0.55,0.55,0.55 end
  if pl>=lo then return 0.25,1.00,0.35 end
  if pl>=lo-3 then return 1.00,0.82,0.10 end
  if pl>=lo-6 then return 1.00,0.50,0.15 end
  return 1.00,0.20,0.20
end

local function fitsPlayer(d)
  local pl=playerLevel()
  local lo=d.minLevel or 0
  local hi=d.maxLevel or lo
  return pl>=lo-3 and pl<=hi+2
end


local function dungeonArt(key) return DUNGEON_ART[key] end


local function createDungeonPanel(parent)
  local panel=CreateFrame("Frame",nil,parent)
  panel:SetPoint("TOPLEFT",15,-76); panel:SetPoint("BOTTOMRIGHT",-35,15)

  local browse=CreateFrame("Frame",nil,panel); browse:SetAllPoints()
  local detail=CreateFrame("Frame",nil,panel); detail:SetAllPoints(); detail:Hide()
  createPanelBanner(browse, "dungeons", -8, 8, -18)
  createPanelBanner(detail, "dungeons", -8, 8, -18)

  local browseTitle=browse:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  browseTitle:SetPoint("TOPLEFT",10,-70); browseTitle:SetText("Browse Dungeons"); browseTitle:SetTextColor(1,0.82,0.20)
  local browseSub=browse:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  browseSub:SetPoint("TOPLEFT",10,-96); browseSub:SetText("Select a dungeon to view bosses, boss-specific loot and a structured quest guide. Beta data can change."); browseSub:SetTextColor(0.78,0.75,0.68)
  local line=makeTexture(browse,"ARTWORK",0.72,0.50,0.12,0.42); line:SetPoint("TOPLEFT",8,-118); line:SetPoint("TOPRIGHT",-10,-118); line:SetHeight(1)

  local fallbackSettings={}
  local function dungeonSettings()
    local db=ForeverCompanionDB
    if type(db)~="table" then db=fallbackSettings end
    db.dungeonBrowse = db.dungeonBrowse or {}
    local cfg=db.dungeonBrowse
    cfg.collapsed = cfg.collapsed or {}
    return cfg
  end

  -- "Only my level" filter (saved account-wide).
  local fitCheck=CreateFrame("CheckButton",nil,browse,"UICheckButtonTemplate")
  fitCheck:SetSize(24,24); fitCheck:SetPoint("TOPRIGHT",-150,-66)
  local fitLabel=browse:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  fitLabel:SetPoint("LEFT",fitCheck,"RIGHT",2,0); fitLabel:SetText("Only dungeons for my level"); fitLabel:SetTextColor(0.90,0.86,0.76)
  fitCheck:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:AddLine("Only dungeons for my level",1,0.82,0)
    GameTooltip:AddLine("Hides dungeons that are more than 3 levels above you or that you have clearly outleveled.",1,1,1,true)
    GameTooltip:Show()
  end)
  fitCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)

  -- Same information hierarchy as Library Books: object, level/status, territory,
  -- location/coordinates and a right-aligned action column.
  local header=CreateFrame("Frame",nil,browse); header:SetPoint("TOPLEFT",8,-128); header:SetPoint("TOPRIGHT",-28,-128); header:SetHeight(28)
  local hbg=makeTexture(header,"BACKGROUND",0.12,0.095,0.055,0.96); hbg:SetAllPoints()
  local function headerText(text,x,w,justify)
    local f=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f:SetPoint("LEFT",x,0); f:SetWidth(w); f:SetJustifyH(justify or "LEFT"); f:SetText(text); f:SetTextColor(0.88,0.76,0.48); return f
  end
  headerText("Dungeon",14,285); headerText("Level",300,64,"CENTER"); headerText("Territory",375,100,"CENTER"); headerText("Zone",488,205); headerText("Quests",700,72,"CENTER"); headerText("Actions",792,105,"CENTER")

  local sf=CreateFrame("ScrollFrame",nil,browse,"UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT",8,-158); sf:SetPoint("BOTTOMRIGHT",0,0)
  local child=CreateFrame("Frame",nil,sf); child:SetSize(LAYOUT.DUNGEON_BROWSE_WIDTH,1); sf:SetScrollChild(child)

  local selectedDungeon=nil
  local mode="bosses"
  local bossSelection={}
  local questSelection={}
  local questFactionFilter={}

  local function questProgressForPlayer(d)
    local counts = { completed=0, inlog=0, available=0, unavailable=0 }
    for _,q in ipairs(d.quests or {}) do
      local status = getDungeonQuestStatus(d, q)
      counts[status] = (counts[status] or 0) + 1
    end
    local relevant = counts.completed + counts.inlog + counts.available
    return counts.completed, relevant, counts
  end

  -- Section headers (one per level bracket), styled like the Library Books sets.
  local sections={}
  local function createSection(bracket)
    local holder=CreateFrame("Frame",nil,child); holder:SetSize(LAYOUT.DUNGEON_ROW_WIDTH,34)
    local bg=makeTexture(holder,"BACKGROUND",0.16,0.11,0.045,0.95); bg:SetAllPoints()
    local top=makeTexture(holder,"ARTWORK",0.72,0.50,0.12,0.65); top:SetPoint("TOPLEFT",0,0); top:SetPoint("TOPRIGHT",0,0); top:SetHeight(1)
    local bottom=makeTexture(holder,"ARTWORK",0.72,0.50,0.12,0.40); bottom:SetPoint("BOTTOMLEFT",0,0); bottom:SetPoint("BOTTOMRIGHT",0,0); bottom:SetHeight(1)
    local toggle=makeButton(holder,"-",22,22); toggle:SetPoint("LEFT",12,0)
    local title=holder:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("LEFT",44,0); title:SetText(bracket.label); title:SetTextColor(1,0.82,0.20)
    local info=holder:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); info:SetPoint("RIGHT",-16,0); info:SetJustifyH("RIGHT"); info:SetTextColor(0.78,0.75,0.68)
    local section={bracket=bracket,header=holder,toggle=toggle,info=info,rows={}}
    toggle:SetScript("OnClick",function()
      local cfg=dungeonSettings()
      cfg.collapsed[bracket.id]=not cfg.collapsed[bracket.id] or nil
      if browse._relayout then browse._relayout() end
    end)
    toggle:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(dungeonSettings().collapsed[bracket.id] and "Expand" or "Collapse")
      GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave",function() GameTooltip:Hide() end)
    -- The whole header bar toggles too, not just the +/- button.
    holder:EnableMouse(true)
    local hhi=makeTexture(holder,"ARTWORK",0.55,0.36,0.10,0.18); hhi:SetAllPoints(); hhi:Hide()
    holder:SetScript("OnEnter",function() hhi:Show() end)
    holder:SetScript("OnLeave",function() hhi:Hide() end)
    holder:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" then toggle:Click() end end)
    return section
  end
  local function sectionFor(d)
    local lvl=d.minLevel or 0
    for bi,br in ipairs(BRACKETS) do
      if lvl>=br.min and lvl<=br.max then
        sections[bi]=sections[bi] or createSection(br)
        return sections[bi]
      end
    end
  end

  local browseRows={}
  for _,d in ipairs(FLT.DUNGEONS or {}) do
    local dungeon=d
    local partial=d.dataStatus=="partial"
    local row=CreateFrame("Button",nil,child)
    row:SetSize(LAYOUT.DUNGEON_ROW_WIDTH,52)
    local bg=makeTexture(row,"BACKGROUND",0.055,0.052,0.047,0.86); bg:SetAllPoints()
    local hi=makeTexture(row,"HIGHLIGHT",0.42,0.30,0.10,0.24); hi:SetAllPoints()
    local sep=makeTexture(row,"ARTWORK",0.72,0.50,0.12,0.28); sep:SetPoint("BOTTOMLEFT",0,0); sep:SetPoint("BOTTOMRIGHT",0,0); sep:SetHeight(1)

    local artPath=dungeonArt(d.key)
    if artPath then
      local art=row:CreateTexture(nil,"ARTWORK"); art:SetSize(84,42); art:SetPoint("LEFT",10,0); art:SetTexture(artPath); art:SetTexCoord(0,1,0,1)
    end
    local nm=row:CreateFontString(nil,"OVERLAY","GameFontNormal"); nm:SetWidth(155); nm:SetJustifyH("LEFT"); nm:SetText(d.short or d.name); nm:SetTextColor(1,0.82,0.20)
    if partial then
      -- Only dungeons with incomplete data get a second status line.
      nm:SetPoint("TOPLEFT",96,-10)
      local status=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); status:SetPoint("TOPLEFT",96,-29); status:SetWidth(195); status:SetJustifyH("LEFT")
      status:SetText("Bosses only - loot & quests not recorded yet"); status:SetTextColor(0.95,0.62,0.25)
    else
      nm:SetPoint("LEFT",96,0)
    end
    if d.betaNew then
      local tag=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); tag:SetPoint("LEFT",nm,"LEFT",159,0); tag:SetText("NEW"); tag:SetTextColor(0.45,0.95,0.55)
    end
    local lv=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); lv:SetPoint("LEFT",300,0); lv:SetWidth(64); lv:SetJustifyH("CENTER"); lv:SetText(d.level)
    local sr,sg,sb=dungeonSideColor(d.territory or d.side)
    local side=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); side:SetPoint("LEFT",375,0); side:SetWidth(100); side:SetJustifyH("CENTER"); side:SetText(d.territory or d.side or "Contested"); side:SetTextColor(sr,sg,sb)
    -- Coordinates are left to the Map button; the column only names the zone.
    local zoneText=(d.mapZone or d.area or "Unknown")
    local ar=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ar:SetPoint("LEFT",488,0); ar:SetWidth(205); ar:SetJustifyH("LEFT"); ar:SetText(zoneText)
    -- Quest progress is refreshed whenever the list is shown.
    local qc=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); qc:SetPoint("LEFT",700,0); qc:SetWidth(72); qc:SetJustifyH("CENTER"); qc:SetTextColor(0.90,0.82,0.56)
    local qhover=CreateFrame("Frame",nil,row); qhover:SetPoint("LEFT",700,0); qhover:SetSize(72,30)
    qhover:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(d.name,1,0.82,0.20)
      if #(d.quests or {})==0 then
        GameTooltip:AddLine(partial and "No quests have been recorded for this dungeon yet." or "No dungeon quests recorded.",0.92,0.90,0.84,true)
      else
        local completedQuests,relevantQuests,questCounts=questProgressForPlayer(d)
        GameTooltip:AddLine(completedQuests.." quests completed of "..relevantQuests.." currently relevant/available to your character.",0.92,0.90,0.84,true)
        GameTooltip:AddLine("Completed: "..questCounts.completed.."  |  In log: "..questCounts.inlog,0.55,0.95,0.65,true)
        GameTooltip:AddLine("Available: "..questCounts.available.."  |  Unavailable: "..questCounts.unavailable,0.80,0.80,0.76,true)
      end
      GameTooltip:Show()
    end)
    qhover:SetScript("OnLeave",function() GameTooltip:Hide() end)
    local mapBtn=makeButton(row,"Map",76,24); mapBtn:SetPoint("LEFT",807,0)
    if d.mapZone and d.mapX and d.mapY then
      mapBtn:SetScript("OnClick",function() FLT:ShowOnMap({zone=d.mapZone,x=d.mapX,y=d.mapY,name=d.name.." entrance"}) end)
      if d.coordsUnverified then
        mapBtn:SetScript("OnEnter",function(self)
          GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
          GameTooltip:AddLine("Dungeon entrance",1,0.82,0)
          GameTooltip:AddLine("This entrance position has not been verified in game yet.",1,1,1,true)
          GameTooltip:Show()
        end)
        mapBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
      end
    else
      mapBtn:Disable()
    end
    row:SetScript("OnClick",function()
      selectedDungeon=dungeon; browse:Hide(); detail:Show()
      bossSelection[dungeon.key]=bossSelection[dungeon.key] or 1
      questSelection[dungeon.key]=questSelection[dungeon.key] or 1
      if detail._render then detail._render() end
    end)
    local entry={dungeon=d,row=row,bg=bg,questText=qc,levelText=lv}
    browseRows[#browseRows+1]=entry
    local sec=sectionFor(d)
    if sec then sec.rows[#sec.rows+1]=entry end
  end

  local emptyText=child:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  emptyText:SetPoint("TOPLEFT",14,-14); emptyText:SetText("No dungeons match your level. Untick \"Only dungeons for my level\" to see all."); emptyText:SetTextColor(0.78,0.75,0.68); emptyText:Hide()

  local function relayout()
    local cfg=dungeonSettings()
    local onlyFit=cfg.onlyFit and true or false
    fitCheck:SetChecked(onlyFit)
    local y=-2
    local shownSections=0
    for bi=1,#BRACKETS do
      local sec=sections[bi]
      if sec and cfg.hiddenBrackets and cfg.hiddenBrackets[sec.bracket.id] then
        sec.header:Hide()
        for _,entry in ipairs(sec.rows) do entry.row:Hide() end
        sec=nil
      end
      if sec then
        local visible={}
        local newCount=0
        for _,entry in ipairs(sec.rows) do
          if not onlyFit or fitsPlayer(entry.dungeon) then visible[#visible+1]=entry end
          if entry.dungeon.betaNew then newCount=newCount+1 end
        end
        for _,entry in ipairs(sec.rows) do entry.row:Hide() end
        if #visible==0 then
          sec.header:Hide()
        else
          shownSections=shownSections+1
          if shownSections>1 then y=y-8 end
          sec.header:ClearAllPoints(); sec.header:SetPoint("TOPLEFT",0,y); sec.header:Show()
          y=y-36
          local collapsed=cfg.collapsed[sec.bracket.id]
          sec.toggle:SetText(collapsed and "+" or "-")
          local infoText=#visible..(#visible==1 and " dungeon" or " dungeons")
          if newCount>0 then infoText=infoText.."  |  "..newCount.." new in Forever" end
          sec.info:SetText(infoText)
          if not collapsed then
            for vi,entry in ipairs(visible) do
              entry.row:ClearAllPoints(); entry.row:SetPoint("TOPLEFT",0,y); entry.row:Show()
              entry.bg:SetColorTexture(0.055,0.052,0.047,(vi%2==0) and 0.94 or 0.78)
              y=y-53
            end
          end
        end
      end
    end
    emptyText:SetShown(shownSections==0)
    child:SetHeight(math.max(1,-y+8))
  end
  browse._relayout=relayout
  UI.RefreshDungeonList=function() if browse:IsShown() then relayout() end end

  fitCheck:SetScript("OnClick",function(self)
    dungeonSettings().onlyFit=self:GetChecked() and true or nil
    relayout()
  end)

  local function refreshBrowse()
    for _,entry in ipairs(browseRows) do
      local d=entry.dungeon
      if #(d.quests or {})==0 then
        entry.questText:SetText("-")
      else
        local completedQuests,relevantQuests=questProgressForPlayer(d)
        entry.questText:SetText(completedQuests.." / "..relevantQuests)
      end
      entry.levelText:SetTextColor(levelColor(d))
    end
    relayout()
  end
  browse:SetScript("OnShow",refreshBrowse)
  refreshBrowse()

  local back=makeButton(detail,"Dungeons",120,26); back:SetPoint("TOPLEFT",8,-70)
  back:SetScript("OnClick",function() detail:Hide(); browse:Show() end)
  local detailArt=detail:CreateTexture(nil,"ARTWORK"); detailArt:SetSize(96,48); detailArt:SetPoint("TOPLEFT",8,-108); detailArt:Hide()
  local dtitle=detail:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); dtitle:SetPoint("TOPLEFT",112,-111); dtitle:SetTextColor(1,0.82,0.20)
  local dmeta=detail:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); dmeta:SetPoint("TOPLEFT",112,-138); dmeta:SetTextColor(0.78,0.75,0.68)
  local bossesBtn=makeButton(detail,"Bosses & Loot",130,26); bossesBtn:SetPoint("TOPRIGHT",-145,-111)
  local questsBtn=makeButton(detail,"Quests",120,26); questsBtn:SetPoint("TOPRIGHT",-15,-111)
  local dline=makeTexture(detail,"ARTWORK",0.72,0.50,0.12,0.42); dline:SetPoint("TOPLEFT",8,-162); dline:SetPoint("TOPRIGHT",-10,-162); dline:SetHeight(1)

  -- Body is no longer one big ScrollFrame. Boss/quest lists own their scroll state,
  -- so selecting an entry never sends the entire dungeon page back to the top.
  local body=CreateFrame("Frame",nil,detail); body:SetPoint("TOPLEFT",8,-174); body:SetPoint("BOTTOMRIGHT",-8,4)
  -- Every dungeon/mode(/faction filter) combination gets its own view frame.
  -- A view is built on first use and afterwards only shown/hidden. WoW never
  -- frees frames, so the previous "destroy and rebuild on every click"
  -- approach leaked frames for as long as the UI was used.
  local views={}
  local currentView
  local function showView(key)
    for k,v in pairs(views) do if k~=key then v:Hide() end end
    local v=views[key]
    if v then v:Show() end
    return v
  end
  local function newView(key)
    local v=CreateFrame("Frame",nil,body); v:SetAllPoints()
    views[key]=v; currentView=v
    showView(key)
    return v
  end
  local function dynFrame(kind,parentFrame,template)
    return CreateFrame(kind,nil,parentFrame or currentView,template)
  end
  local function dynText(parentFrame,template)
    return parentFrame:CreateFontString(nil,"OVERLAY",template or "GameFontHighlight")
  end

  -- Item names/icons are colored from the client item cache. Cached panes
  -- re-apply them when shown again, because the data may have loaded since.
  local function refreshItemVisuals(list)
    for _,it in ipairs(list or {}) do
      colorDungeonItemText(it.text,it.rec,it.r,it.g,it.b)
      if it.icon then it.icon:SetTexture(dungeonItemIcon(it.rec)) end
    end
  end

  local function showLootTooltip(owner,item,label)
    local rec=normalizeDungeonItem(item)
    if tryShowItemTooltip(owner,rec) then return end
    H.anchorItemTooltip(owner)
    GameTooltip:AddLine(rec.name or "Unknown item",1,0.82,0)
    if rec.slot then GameTooltip:AddLine(rec.slot,0.70,0.82,1.00) end
    if rec.summary then GameTooltip:AddLine(rec.summary,0.85,0.85,0.85,true) end
    GameTooltip:AddLine(label or "Dungeon loot",0.65,0.85,1)
    if rec.id then GameTooltip:AddLine("Item ID: "..tostring(rec.id),0.55,0.55,0.55) end
    GameTooltip:AddLine("Current Forever beta data; stats and drop tables can change.",0.70,0.70,0.70,true)
    GameTooltip:Show()
  end


  local function renderBosses(d)
    local viewKey="bosses:"..d.key
    local view=showView(viewKey)
    if view then
      -- Portraits resolve asynchronously and may have failed earlier; ask
      -- again (resolved display IDs are cached, so this is cheap).
      for _,row in ipairs(view.rows) do
        if row.boss then setBossPortrait(row.icon,d,row.boss) end
      end
      view.select(bossSelection[d.key] or 1)
      return
    end
    view=newView(viewKey)

    local left=dynFrame("Frame"); left:SetPoint("TOPLEFT",0,0); left:SetPoint("BOTTOMLEFT",0,0); left:SetWidth(390)
    local lbg=makeTexture(left,"BACKGROUND",0.10,0.072,0.030,0.88); lbg:SetAllPoints()
    local ltop=makeTexture(left,"ARTWORK",0.56,0.38,0.10,0.28); ltop:SetPoint("TOPLEFT",0,0); ltop:SetPoint("TOPRIGHT",0,0); ltop:SetHeight(1)
    local lright=makeTexture(left,"ARTWORK",0.72,0.50,0.12,0.42); lright:SetPoint("TOPRIGHT",0,0); lright:SetPoint("BOTTOMRIGHT",0,0); lright:SetWidth(1)
    local lh=dynText(left,"GameFontNormalLarge"); lh:SetPoint("TOPLEFT",14,-12); lh:SetText("Bosses  |  "..#(d.bosses or {})); lh:SetTextColor(1,0.82,0.20)

    local bsf=dynFrame("ScrollFrame",left,"UIPanelScrollFrameTemplate"); bsf:SetPoint("TOPLEFT",10,-45); bsf:SetPoint("BOTTOMRIGHT",-3,8)
    local bchild=dynFrame("Frame",bsf); bchild:SetSize(LAYOUT.QUEST_LIST_WIDTH,1); bsf:SetScrollChild(bchild)
    local bosses=d.bosses or {}
    local trashLoot=d.trashLoot or {}
    local entryCount=#bosses + ((#trashLoot>0) and 1 or 0)
    local idx=bossSelection[d.key] or 1; if idx>entryCount then idx=1 end; if idx<1 then idx=1 end
    local by=-2
    local rows={}
    for i,boss in ipairs(bosses) do
      local bossName=boss.name or tostring(boss)
      local b=dynFrame("Button",bchild); b:SetSize(LAYOUT.QUEST_ROW_WIDTH,50); b:SetPoint("TOPLEFT",0,by); by=by-52
      local bg=makeTexture(b,"BACKGROUND",0.115,0.082,0.038,0.78); bg:SetAllPoints()
      local hi=makeTexture(b,"HIGHLIGHT",0.55,0.36,0.10,0.22); hi:SetAllPoints()
      local bframe=UI.CreateBossFrame(b,42,false); bframe:SetPoint("LEFT",5,1)
      local icon=bframe.portrait; setBossPortrait(icon,d,boss)
      -- Number and name are separate so the level line lines up exactly
      -- under the first letter of the boss name.
      local num=b:CreateFontString(nil,"OVERLAY","GameFontHighlight"); num:SetWidth(24); num:SetJustifyH("LEFT"); num:SetText(i..".")
      local t=b:CreateFontString(nil,"OVERLAY","GameFontHighlight"); t:SetWidth(250); t:SetJustifyH("LEFT"); t:SetText(bossName)
      local bossLevel=FLT.GetBossLevel and FLT:GetBossLevel(boss)
      if bossLevel then
        num:SetPoint("TOPLEFT",50,-9); t:SetPoint("TOPLEFT",76,-9)
        local lv=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); lv:SetPoint("TOPLEFT",t,"BOTTOMLEFT",0,-3); lv:SetJustifyH("LEFT"); lv:SetText("Level "..bossLevel)
      else
        num:SetPoint("LEFT",50,0); t:SetPoint("LEFT",76,0)
      end
      t.num=num
      rows[i]={button=b,bg=bg,text=t,icon=icon,boss=boss}
    end
    if #trashLoot>0 then
      local i=#bosses+1
      local b=dynFrame("Button",bchild); b:SetSize(LAYOUT.QUEST_ROW_WIDTH,50); b:SetPoint("TOPLEFT",0,by); by=by-52
      local bg=makeTexture(b,"BACKGROUND",0.095,0.105,0.080,0.82); bg:SetAllPoints()
      local hi=makeTexture(b,"HIGHLIGHT",0.55,0.36,0.10,0.22); hi:SetAllPoints()
      local tframe=UI.CreateRingFrame(b,40,"gold"); tframe:SetPoint("LEFT",6,0)
      local icon=tframe.portrait; icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue")
      local t=b:CreateFontString(nil,"OVERLAY","GameFontHighlight"); t:SetPoint("LEFT",50,0); t:SetWidth(270); t:SetJustifyH("LEFT"); t:SetText("Trash")
      rows[i]={button=b,bg=bg,text=t,icon=icon,isTrash=true}
    end
    bchild:SetHeight(math.max(1,-by+2))

    local right=dynFrame("Frame"); right:SetPoint("TOPLEFT",405,0); right:SetPoint("BOTTOMRIGHT",0,0)
    local rbg=makeTexture(right,"BACKGROUND",0.034,0.044,0.056,0.93); rbg:SetAllPoints()
    local rleft=makeTexture(right,"ARTWORK",0.16,0.22,0.28,0.35); rleft:SetPoint("TOPLEFT",0,0); rleft:SetPoint("BOTTOMLEFT",0,0); rleft:SetWidth(1)

    -- One cached detail pane per boss entry.
    local detailPanes={}
    local host
    local function dframe(kind,parentFrame,template)
      return CreateFrame(kind,nil,parentFrame or host,template)
    end
    local function dtext(parentFrame,template)
      return parentFrame:CreateFontString(nil,"OVERLAY",template or "GameFontHighlight")
    end

    local function selectBoss(newIdx)
      local bosses=d.bosses or {}
      local trashLoot=d.trashLoot or {}
      local maxIdx=#bosses + ((#trashLoot>0) and 1 or 0)
      if maxIdx==0 then return end
      if newIdx<1 then newIdx=1 elseif newIdx>maxIdx then newIdx=maxIdx end
      bossSelection[d.key]=newIdx
      for i,row in ipairs(rows) do
        if i==newIdx then
          row.bg:SetColorTexture(0.24,0.17,0.055,0.98)
          row.text:SetTextColor(1,0.82,0.20); if row.text.num then row.text.num:SetTextColor(1,0.82,0.20) end
        else
          if row.isTrash then row.bg:SetColorTexture(0.095,0.105,0.080,0.82) else row.bg:SetColorTexture(0.115,0.082,0.038,0.78) end
          row.text:SetTextColor(0.92,0.90,0.84); if row.text.num then row.text.num:SetTextColor(0.92,0.90,0.84) end
        end
      end

      for i,pane in pairs(detailPanes) do if i~=newIdx then pane:Hide() end end
      if detailPanes[newIdx] then
        local pane=detailPanes[newIdx]
        pane:Show()
        if pane.boss then setBossPortrait(pane.portrait,d,pane.boss) end
        refreshItemVisuals(pane.items)
        return
      end
      host=CreateFrame("Frame",nil,right); host:SetAllPoints()
      host.items={}
      detailPanes[newIdx]=host

      local isTrash=(#trashLoot>0 and newIdx==#bosses+1)
      local boss=isTrash and nil or bosses[newIdx]
      local loot=isTrash and trashLoot or (boss and (boss.loot or (d.bossLoot and d.bossLoot[boss.name]) or {}) or {})
      local portrait
      if isTrash then
        portrait=UI.CreateRingFrame(host,72,"gold"); portrait:SetPoint("TOPLEFT",12,-10)
      else
        portrait=UI.CreateBossFrame(host,80,true); portrait:SetPoint("TOPLEFT",10,-8)
        portrait:SetLevel(FLT.GetBossLevel and FLT:GetBossLevel(boss))
      end
      local portraitIcon=portrait.portrait
      if isTrash then portraitIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue") else setBossPortrait(portraitIcon,d,boss) end
      host.portrait=portraitIcon; host.boss=boss or false
      local bn=dtext(host,"GameFontNormalLarge"); bn:SetPoint("TOPLEFT",100,-18); bn:SetWidth(420); bn:SetJustifyH("LEFT"); bn:SetText(isTrash and "Trash" or (boss.name or tostring(boss))); bn:SetTextColor(1,0.82,0.20)
      local sub=dtext(host,"GameFontDisableSmall"); sub:SetPoint("TOPLEFT",100,-47); local bossLevel=(not isTrash) and FLT.GetBossLevel and FLT:GetBossLevel(boss)
      sub:SetText((bossLevel and ("Level "..bossLevel.."  |  ") or "")..(isTrash and "Relevant trash loot  |  " or "Known loot  |  ")..tostring(#loot).." items")
      if isTrash then
        local desc=dtext(host,"GameFontHighlightSmall"); desc:SetPoint("TOPLEFT",18,-80); desc:SetWidth(500); desc:SetJustifyH("LEFT"); desc:SetText("Rare+ dungeon drops plus selected notable set/progression items. Generic green world drops are omitted.")
      elseif boss.description then
        local desc=dtext(host,"GameFontHighlightSmall"); desc:SetPoint("TOPLEFT",18,-80); desc:SetWidth(500); desc:SetJustifyH("LEFT"); desc:SetText(boss.description)
      end

      local lsf=dframe("ScrollFrame",host,"UIPanelScrollFrameTemplate"); lsf:SetPoint("TOPLEFT",12,-102); lsf:SetPoint("BOTTOMRIGHT",-2,8)
      local lchild=dframe("Frame",lsf); lchild:SetSize(515,1); lsf:SetScrollChild(lchild)
      local ly=-2
      if #loot==0 then
        local none=dtext(lchild,"GameFontDisable"); none:SetPoint("TOPLEFT",8,ly-8); none:SetWidth(495); none:SetJustifyH("LEFT"); none:SetText(isTrash and "No curated trash loot is present in the current embedded beta data set." or (d.dataStatus=="partial" and "Loot for this new Forever dungeon has not been recorded yet. It will be added once drop data is available." or (boss and boss.worldDropsOnly and "This boss has no boss-specific loot - it only drops random world items (the same as in Classic)." or "No boss-specific loot is recorded for this boss in the current Forever data.")))
        ly=ly-44
      else
        for j,item in ipairs(loot) do
          local rec=normalizeDungeonItem(item)
          local row=dframe("Button",lchild); row:SetSize(510,48); row:SetPoint("TOPLEFT",0,ly); ly=ly-50
          local bg=makeTexture(row,"BACKGROUND",0.055,0.067,0.080,(j%2==0) and 0.96 or 0.84); bg:SetAllPoints()
          local hi=makeTexture(row,"HIGHLIGHT",0.22,0.34,0.46,0.22); hi:SetAllPoints()
          local ic=row:CreateTexture(nil,"ARTWORK"); ic:SetSize(30,30); ic:SetPoint("LEFT",9,0); ic:SetTexture(dungeonItemIcon(rec))
          local nm=row:CreateFontString(nil,"OVERLAY","GameFontNormal"); nm:SetPoint("TOPLEFT",50,-8); nm:SetWidth(445); nm:SetJustifyH("LEFT"); nm:SetText(rec.name); colorDungeonItemText(nm,rec,0.55,0.78,1.00)
          host.items[#host.items+1]={text=nm,icon=ic,rec=rec,r=0.55,g=0.78,b=1.00}
          if rec.slot then local sl=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); sl:SetPoint("TOPLEFT",50,-27); sl:SetWidth(445); sl:SetJustifyH("LEFT"); sl:SetText(rec.slot) end
          row:SetScript("OnEnter",function(self)
            showLootTooltip(self,rec,isTrash and "Dungeon trash loot" or "Dungeon loot")
            -- SetHyperlink may finish loading live Forever item data on first hover.
            -- Re-read the quality so the row immediately matches the native tooltip.
            colorDungeonItemText(nm,rec,0.55,0.78,1.00)
          end)
          row:SetScript("OnLeave",function() GameTooltip:Hide() end)
          row:RegisterForClicks("LeftButtonUp")
          row:SetScript("OnClick",function(_,button) handleDungeonItemClick(rec,button) end)
        end
      end
      lchild:SetHeight(math.max(1,-ly+2))
    end

    for i,row in ipairs(rows) do
      row.button:SetScript("OnClick",function() selectBoss(i) end)
    end
    view.select=selectBoss
    view.rows=rows
    selectBoss(idx)
  end

  local function renderQuests(d)
    local allQuests=d.quests or {}
    local playerFaction=UnitFactionGroup("player")
    local filter=questFactionFilter[d.key] or playerFaction or "Alliance"
    if filter~="Alliance" and filter~="Horde" then filter="Alliance" end
    questFactionFilter[d.key]=filter

    local viewKey="quests:"..d.key..":"..filter
    local view=showView(viewKey)
    if view then
      -- Quest states (completed / in log / level) can change while the view
      -- is cached, so re-evaluate them each time the view is shown.
      view.refresh()
      view.select(questSelection[d.key] or 1)
      return
    end
    view=newView(viewKey)

    local quests={}
    for _,q in ipairs(allQuests) do if q.side=="Both" or q.side=="Neutral" or q.side==filter then quests[#quests+1]=q end end
    local idx=questSelection[d.key] or 1; if idx>#quests then idx=1 end; if idx<1 then idx=1 end; questSelection[d.key]=idx

    local left=dynFrame("Frame"); left:SetPoint("TOPLEFT",0,0); left:SetPoint("BOTTOMLEFT",0,0); left:SetWidth(390)
    local lbg=makeTexture(left,"BACKGROUND",0.10,0.072,0.030,0.88); lbg:SetAllPoints()
    local lright=makeTexture(left,"ARTWORK",0.72,0.50,0.12,0.42); lright:SetPoint("TOPRIGHT",0,0); lright:SetPoint("BOTTOMRIGHT",0,0); lright:SetWidth(1)
    local lh=dynText(left,"GameFontNormalLarge"); lh:SetPoint("TOPLEFT",14,-12); lh:SetText("Quests  |  "..#quests); lh:SetTextColor(1,0.82,0.20)
    local allianceBtn=makeButton(left,"Alliance",92,24); allianceBtn:SetPoint("TOPRIGHT",-108,-8)
    local hordeBtn=makeButton(left,"Horde",92,24); hordeBtn:SetPoint("TOPRIGHT",-10,-8)
    if filter=="Alliance" then allianceBtn:LockHighlight() else hordeBtn:LockHighlight() end
    allianceBtn:SetScript("OnClick",function() questFactionFilter[d.key]="Alliance"; questSelection[d.key]=1; renderQuests(d) end)
    hordeBtn:SetScript("OnClick",function() questFactionFilter[d.key]="Horde"; questSelection[d.key]=1; renderQuests(d) end)
    local legend=dynText(left,"GameFontDisableSmall"); legend:SetPoint("TOPLEFT",14,-42); legend:SetText("Green = in quest log   Dim = unavailable   Showing "..filter.." + shared quests")

    local qsf=dynFrame("ScrollFrame",left,"UIPanelScrollFrameTemplate"); qsf:SetPoint("TOPLEFT",10,-64); qsf:SetPoint("BOTTOMRIGHT",-3,8)
    local qchild=dynFrame("Frame",qsf); qchild:SetSize(LAYOUT.QUEST_LIST_WIDTH,1); qsf:SetScrollChild(qchild)
    local qy=-2
    local rows={}
    for i,quest in ipairs(quests) do
      local row=dynFrame("Button",qchild); row:SetSize(LAYOUT.QUEST_ROW_WIDTH,40); row:SetPoint("TOPLEFT",0,qy); qy=qy-42
      local bg=makeTexture(row,"BACKGROUND",0.115,0.082,0.038,0.78); bg:SetAllPoints()
      local hi=makeTexture(row,"HIGHLIGHT",0.55,0.36,0.10,0.22); hi:SetAllPoints()
      local check=row:CreateTexture(nil,"OVERLAY")
      check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
      check:SetSize(18,18); check:SetPoint("TOPLEFT",8,-1)
      check:SetVertexColor(0.20,1.00,0.35,1)
      local qn=row:CreateFontString(nil,"OVERLAY","GameFontNormal")
      qn:SetWidth(295); qn:SetJustifyH("LEFT")
      qn:SetText(quest.name)
      local meta=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); meta:SetPoint("TOPLEFT",30,-21); meta:SetWidth(295); meta:SetJustifyH("LEFT")
      rows[i]={button=row,bg=bg,name=qn,meta=meta,check=check,quest=quest}
    end
    qchild:SetHeight(math.max(1,-qy+2))

    local function refreshRowStatus()
      for _,row in ipairs(rows) do
        local quest=row.quest
        local questStatus=getDungeonQuestStatus(d, quest)
        row.status=questStatus
        row.name:ClearAllPoints()
        if questStatus=="completed" then
          row.check:Show(); row.name:SetPoint("TOPLEFT",30,-3)
        else
          row.check:Hide(); row.name:SetPoint("TOPLEFT",12,-3)
        end
        local req=quest.required or quest.level or "?"; local m="Req. "..tostring(req).."  |  "..(quest.side or "Both")
        if quest.class then m=m.." / "..quest.class end
        m=m.."  |  "..(QUEST_STATUS_LABELS[questStatus] or questStatus)
        if quest.id and FLT.QUEST_PREREQ_CHAINS and FLT.QUEST_PREREQ_CHAINS[quest.id] then
          local stepIdx, stepTotal = getChainProgress(quest)
          if questStatus=="inlog" and not stepIdx and stepTotal then stepIdx = stepTotal end
          m=m..(stepIdx and ("  |  Chain "..stepIdx.."/"..stepTotal) or "  |  Chain")
        end
        row.meta:SetText(m)
      end
    end
    refreshRowStatus()

    local right=dynFrame("Frame"); right:SetPoint("TOPLEFT",405,0); right:SetPoint("BOTTOMRIGHT",0,0)
    local rbg=makeTexture(right,"BACKGROUND",0.034,0.044,0.056,0.93); rbg:SetAllPoints()
    local rleft=makeTexture(right,"ARTWORK",0.16,0.22,0.28,0.35); rleft:SetPoint("TOPLEFT",0,0); rleft:SetPoint("BOTTOMLEFT",0,0); rleft:SetWidth(1)
    if #quests==0 then
      local none=dynText(right,"GameFontDisable"); none:SetPoint("TOPLEFT",18,-18); none:SetWidth(460); none:SetJustifyH("LEFT")
      if #allQuests==0 then
        none:SetText(d.dataStatus=="partial" and "No quests have been recorded for this new Forever dungeon yet." or "No dungeon quests are recorded for this dungeon.")
      else
        none:SetText("No "..filter.." or shared quests are recorded for this dungeon. Switch the faction filter to see the other quests.")
      end
    end

    -- One cached detail pane per quest. pane.update() refreshes the parts that
    -- depend on live character state (status line, quest-chain progress).
    local detailPanes={}
    local host
    local function dframe(kind,parentFrame,template)
      return CreateFrame(kind,nil,parentFrame or host,template)
    end
    local function dtext(parentFrame,template)
      return parentFrame:CreateFontString(nil,"OVERLAY",template or "GameFontHighlight")
    end

    local function selectQuest(newIdx)
      if #quests==0 then return end
      if newIdx<1 then newIdx=1 elseif newIdx>#quests then newIdx=#quests end
      questSelection[d.key]=newIdx
      for i,row in ipairs(rows) do
        if i==newIdx then
          row.bg:SetColorTexture(0.24,0.17,0.055,0.98)
          row.name:SetTextColor(1,0.82,0.20)
        elseif row.status == "inlog" then
          row.bg:SetColorTexture(0.035,0.16,0.055,0.90)
          row.name:SetTextColor(0.25,1,0.35)
        elseif row.status == "completed" then
          row.bg:SetColorTexture(0.045,0.10,0.08,0.84)
          row.name:SetTextColor(0.45,0.85,0.70)
        elseif row.status == "unavailable" then
          row.bg:SetColorTexture(0.07,0.06,0.05,0.72)
          row.name:SetTextColor(0.58,0.56,0.52)
        else
          row.bg:SetColorTexture(0.115,0.082,0.038,0.78)
          row.name:SetTextColor(0.92,0.90,0.84)
        end
      end

      for i,pane in pairs(detailPanes) do if i~=newIdx then pane:Hide() end end
      if detailPanes[newIdx] then
        detailPanes[newIdx]:Show()
        detailPanes[newIdx].update()
        return
      end

      local q=quests[newIdx]
      if not q then return end
      host=CreateFrame("Frame",nil,right); host:SetAllPoints()
      host.items={}
      detailPanes[newIdx]=host
      local pane=host
      local chainRows={}

      local qn=dtext(host,"GameFontNormalLarge"); qn:SetPoint("TOPLEFT",18,-16); qn:SetWidth(475); qn:SetJustifyH("LEFT"); qn:SetText(q.name); qn:SetTextColor(1,0.82,0.20)
      local st=dtext(host,"GameFontHighlightSmall"); st:SetPoint("TOPLEFT",18,-48); st:SetWidth(475); st:SetJustifyH("LEFT")

      pane.update=function()
        local questStatus=getDungeonQuestStatus(d, q)
        local statusLabel=QUEST_STATUS_LABELS[questStatus] or questStatus
        local stepIdx, stepTotal = getChainProgress(q)
        if questStatus=="inlog" and stepIdx then statusLabel=statusLabel.." - chain step "..stepIdx.." of "..stepTotal end
        st:SetText("Required level: "..tostring(q.required or q.level or "?").."   |   "..(q.side or "Both")..(q.class and (" / "..q.class) or "").."\nStatus: "..statusLabel)
        if questStatus == "inlog" then st:SetTextColor(0.25,1,0.35)
        elseif questStatus == "completed" then st:SetTextColor(0.45,0.85,0.70)
        elseif questStatus == "unavailable" then st:SetTextColor(0.62,0.60,0.56)
        else st:SetTextColor(0.82,0.80,0.74) end

        for _,cr in ipairs(chainRows) do
          local done=(cr.id and FLT:IsQuestDone(cr.id)) or false
          local inLog=(not done and cr.id and getQuestLogInfo({ id = cr.id })) or false
          if cr.isCurrent then cr.bg:SetColorTexture(0.24,0.17,0.055,0.95)
          elseif done then cr.bg:SetColorTexture(0.035,0.16,0.055,0.86)
          elseif inLog then cr.bg:SetColorTexture(0.035,0.20,0.065,0.90)
          else cr.bg:SetColorTexture(0.055,0.067,0.080,0.82) end
          if cr.isCurrent then cr.name:SetTextColor(1,0.82,0.20) elseif done or inLog then cr.name:SetTextColor(0.35,1,0.45) elseif cr.optional then cr.name:SetTextColor(0.62,0.60,0.56) else cr.name:SetTextColor(0.90,0.88,0.82) end
          local stateText = done and "Done" or (inLog and "In log" or (cr.optional and "Optional" or "Required"))
          -- The last row is the dungeon quest this page is about.
          if cr.isCurrent and not done and not inLog then stateText = "Dungeon quest" end
          cr.state:SetText(stateText)
          if cr.isCurrent then cr.state:SetTextColor(1,0.82,0.20) elseif done or inLog then cr.state:SetTextColor(0.35,1,0.45) else cr.state:SetTextColor(0.66,0.66,0.66) end
        end
        refreshItemVisuals(pane.items)
      end

      local rsf=dframe("ScrollFrame",host,"UIPanelScrollFrameTemplate"); rsf:SetPoint("TOPLEFT",10,-78); rsf:SetPoint("BOTTOMRIGHT",-2,8)
      local rchild=dframe("Frame",rsf); rchild:SetSize(LAYOUT.QUEST_DETAIL_CHILD_WIDTH,1); rsf:SetScrollChild(rchild)
      local ry=-6
      local function section(title,text)
        local h=dtext(rchild,"GameFontNormalSmall"); h:SetPoint("TOPLEFT",8,ry); h:SetWidth(84); h:SetJustifyH("LEFT"); h:SetText(title); h:SetTextColor(1,0.82,0.20)
        local b=dtext(rchild,"GameFontHighlightSmall"); b:SetPoint("TOPLEFT",96,ry); b:SetWidth(334); b:SetJustifyH("LEFT"); b:SetText(text or "Unknown"); b:SetWordWrap(true)
        local height=math.max(18,b:GetStringHeight() or 18); ry=ry-height-10
      end
      do
        local h=dtext(rchild,"GameFontNormalSmall"); h:SetPoint("TOPLEFT",8,ry); h:SetWidth(84); h:SetJustifyH("LEFT"); h:SetText("Starts at"); h:SetTextColor(1,0.82,0.20)
        local loc=q.id and FLT.QUEST_START_MAPS and FLT.QUEST_START_MAPS[q.id]
        local valueWidth=loc and 215 or 310
        local b=dtext(rchild,"GameFontHighlightSmall"); b:SetPoint("TOPLEFT",96,ry); b:SetWidth(valueWidth); b:SetJustifyH("LEFT"); b:SetText(q.starts or "Unknown"); b:SetWordWrap(true)
        if loc then
          local mapBtn=makeButton(rchild,"Map",52,18)
          mapBtn:SetPoint("TOPLEFT",314,ry+2)
          mapBtn:SetScript("OnClick",function() if FLT.ShowQuestStartOnMap then FLT:ShowQuestStartOnMap(q) end end)
          mapBtn:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText("Quest start",1,0.82,0.20)
            GameTooltip:AddLine(loc.label or (q.starts or q.name),0.92,0.90,0.84,true)
            GameTooltip:AddLine("Open the world map and mark this location with the golden OneForAll pin.",0.72,0.72,0.72,true)
            GameTooltip:Show()
          end)
          mapBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        local height=math.max(18,b:GetStringHeight() or 18); ry=ry-height-10
      end
      if q.objective then section("Objective",q.objective) end
      if q.turnin and q.turnin~="" then section("Turn in",q.turnin) end
      -- Only show a prerequisite line when there is real info and the quest
      -- chain below does not already list the required steps.
      local chain=q.id and FLT.QUEST_PREREQ_CHAINS and FLT.QUEST_PREREQ_CHAINS[q.id]
      if q.prereq and q.prereq~="" and not (chain and #chain>0) then section("Prerequisite",q.prereq) end
      if chain and #chain>0 then
        local ch=dtext(rchild,"GameFontNormalSmall"); ch:SetPoint("TOPLEFT",8,ry); ch:SetText("Quest chain"); ch:SetTextColor(1,0.82,0.20); ry=ry-22
        local steps={}
        local currentIncluded=false
        for _,step in ipairs(chain) do
          steps[#steps+1]=step
          if step.id==q.id then currentIncluded=true end
        end
        if not currentIncluded then steps[#steps+1]={id=q.id,name=q.name,current=true} end
        for ci,step in ipairs(steps) do
          local row=dframe("Button",rchild); row:SetSize(440,26); row:SetPoint("TOPLEFT",8,ry); ry=ry-28
          local isCurrent=step.id==q.id
          local bg=makeTexture(row,"BACKGROUND",0.055,0.067,0.080,0.82)
          bg:SetAllPoints()
          local stepLoc=step.id and FLT.QUEST_START_MAPS and FLT.QUEST_START_MAPS[step.id]
          local nm=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); nm:SetPoint("LEFT",8,0); nm:SetWidth(stepLoc and 226 or 292); nm:SetJustifyH("LEFT"); nm:SetText(tostring(ci)..".  "..(step.name or ("Quest "..tostring(step.id or "?"))))
          if stepLoc then
            local stepMapBtn=makeButton(row,"Map",42,18)
            stepMapBtn:SetPoint("RIGHT",-94,0)
            stepMapBtn:SetScript("OnClick",function()
              FLT:ShowOnMap(stepLoc)
            end)
            stepMapBtn:SetScript("OnEnter",function(self)
              GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
              GameTooltip:SetText("Quest start",1,0.82,0.20)
              GameTooltip:AddLine(stepLoc.label or (step.name or "Quest step"),0.92,0.90,0.84,true)
              GameTooltip:AddLine("Open the world map and mark this pickup location with the golden OneForAll pin.",0.72,0.72,0.72,true)
              GameTooltip:Show()
            end)
            stepMapBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
          end
          local stp=row:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); stp:SetPoint("RIGHT",-8,0); stp:SetWidth(stepLoc and 82 or 110); stp:SetJustifyH("RIGHT")
          chainRows[#chainRows+1]={id=step.id,isCurrent=isCurrent,optional=step.optional,bg=bg,name=nm,state=stp}
          local detail=step.id and FLT.QUEST_PREREQ_DETAILS and FLT.QUEST_PREREQ_DETAILS[step.id]
          row:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(step.name or ("Quest "..tostring(step.id or "?")),1,0.82,0.20)
            if detail then
              if detail.pickup then GameTooltip:AddLine("Start: "..detail.pickup,0.92,0.90,0.84,true) end
              if detail.objective then GameTooltip:AddLine(detail.objective,1,1,1,true) end
              if detail.turnin then GameTooltip:AddLine("Turn in: "..detail.turnin,0.76,0.76,0.72,true) end
              if step.optional then GameTooltip:AddLine("Optional lead-in: not required to accept the quest.",0.62,0.60,0.56,true) end
            elseif isCurrent then
              GameTooltip:AddLine(q.objective or "The dungeon quest on this page",0.92,0.90,0.84,true)
            end
            if stepLoc and stepLoc.label then
              GameTooltip:AddLine("Map: "..stepLoc.label,0.72,0.72,0.72,true)
            end
            GameTooltip:Show()
          end)
          row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        ry=ry-4
      end

      if q.note then section("Notes",q.note) end

      local rh=dtext(rchild,"GameFontNormal"); rh:SetPoint("TOPLEFT",8,ry); rh:SetText("Rewards"); rh:SetTextColor(1,0.82,0.20); ry=ry-24
      local rewards=q.rewards or {}
      if #rewards==0 then
        local summary=dtext(rchild,"GameFontHighlight"); summary:SetPoint("TOPLEFT",8,ry); summary:SetWidth(440); summary:SetJustifyH("LEFT"); summary:SetText(q.rewardSummary or "No item reward is listed in the current beta data for this quest."); summary:SetTextColor(0.76,0.76,0.72); ry=ry-(math.max(22,summary:GetStringHeight() or 22)+14)
      else
        for ri,rec in ipairs(rewards) do
          local reward=dframe("Button",rchild); reward:SetSize(440,52); reward:SetPoint("TOPLEFT",8,ry); ry=ry-54
          local rwb=makeTexture(reward,"BACKGROUND",0.055,0.067,0.080,(ri%2==0) and 0.96 or 0.84); rwb:SetAllPoints()
          local rhi=makeTexture(reward,"HIGHLIGHT",0.22,0.34,0.46,0.20); rhi:SetAllPoints()
          local ric=reward:CreateTexture(nil,"ARTWORK"); ric:SetSize(34,34); ric:SetPoint("LEFT",10,0); ric:SetTexture(dungeonItemIcon(rec))
          local rw=reward:CreateFontString(nil,"OVERLAY","GameFontHighlight"); rw:SetPoint("TOPLEFT",54,-8); rw:SetWidth(370); rw:SetJustifyH("LEFT"); rw:SetText(rec.name)
          pane.items[#pane.items+1]={text=rw,icon=ric,rec=rec,r=0.92,g=0.90,b=0.84}
          if rec.slot then local sl=reward:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); sl:SetPoint("TOPLEFT",54,-29); sl:SetWidth(370); sl:SetJustifyH("LEFT"); sl:SetText(rec.slot) end
          reward:SetScript("OnEnter",function(self) showLootTooltip(self,rec,"Quest reward") end); reward:SetScript("OnLeave",function() GameTooltip:Hide() end)
          reward:RegisterForClicks("LeftButtonUp"); reward:SetScript("OnClick",function(_,button) handleDungeonItemClick(rec,button) end)
        end
        if q.rewardSummary then local sum=dtext(rchild,"GameFontDisableSmall"); sum:SetPoint("TOPLEFT",8,ry-2); sum:SetWidth(440); sum:SetJustifyH("LEFT"); sum:SetText(q.rewardSummary); ry=ry-32 end
      end
      if q.noteRewards and #q.noteRewards>0 then
        local nh=dtext(rchild,"GameFontNormal"); nh:SetPoint("TOPLEFT",8,ry); nh:SetText("Follow-up rewards"); nh:SetTextColor(1,0.82,0.20); ry=ry-28
        for _,rec in ipairs(q.noteRewards) do
          -- Same layout as the regular reward rows (left-aligned name + slot).
          local reward=dframe("Button",rchild); reward:SetSize(440,52); reward:SetPoint("TOPLEFT",8,ry); ry=ry-54
          local bg=makeTexture(reward,"BACKGROUND",0.055,0.067,0.080,0.88); bg:SetAllPoints()
          local hi=makeTexture(reward,"HIGHLIGHT",0.22,0.34,0.46,0.20); hi:SetAllPoints()
          local ic=reward:CreateTexture(nil,"ARTWORK"); ic:SetSize(34,34); ic:SetPoint("LEFT",10,0); ic:SetTexture(dungeonItemIcon(rec))
          local nm=reward:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nm:SetPoint(rec.slot and "TOPLEFT" or "LEFT",54,rec.slot and -8 or 0); nm:SetWidth(370); nm:SetJustifyH("LEFT"); nm:SetText(rec.name)
          if rec.slot then local sl=reward:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); sl:SetPoint("TOPLEFT",54,-29); sl:SetWidth(370); sl:SetJustifyH("LEFT"); sl:SetText(rec.slot) end
          pane.items[#pane.items+1]={text=nm,icon=ic,rec=rec,r=0.92,g=0.90,b=0.84}
          reward:SetScript("OnEnter",function(self) showLootTooltip(self,rec,"Follow-up quest reward") end); reward:SetScript("OnLeave",function() GameTooltip:Hide() end)
          reward:RegisterForClicks("LeftButtonUp"); reward:SetScript("OnClick",function(_,button) handleDungeonItemClick(rec,button) end)
        end
      end
      rchild:SetHeight(math.max(1,-ry+8))
      pane.update()
    end

    for i,row in ipairs(rows) do row.button:SetScript("OnClick",function() selectQuest(i) end) end
    view.select=selectQuest
    view.refresh=refreshRowStatus
    selectQuest(idx)
  end

  detail._render=function()
    local d=selectedDungeon; if not d then return end
    dtitle:SetText(d.name)
    local ap=dungeonArt(d.key)
    if ap then
      detailArt:SetTexture(ap); detailArt:SetTexCoord(0,1,0,1); detailArt:Show()
    else
      detailArt:Hide()
    end
    local sr,sg,sb=dungeonSideColor(d.territory or d.side)
    local zoneText=(d.mapZone or d.area or "Unknown")
    dmeta:SetText("LV "..d.level.."  |  "..zoneText.."  |  "..(d.territory or d.side or "Contested")..(d.betaNew and "  |  New in Forever" or "")); dmeta:SetTextColor(sr,sg,sb)
    if mode=="quests" then renderQuests(d) else renderBosses(d) end
    if mode=="quests" then questsBtn:LockHighlight(); bossesBtn:UnlockHighlight() else bossesBtn:LockHighlight(); questsBtn:UnlockHighlight() end
  end
  -- Re-render (cheap: views are cached) whenever the detail page becomes
  -- visible again, so quest states are current after reopening the window.
  detail:SetScript("OnShow",function() if detail._render then detail._render() end end)
  bossesBtn:SetScript("OnClick",function() mode="bosses"; detail._render() end)
  questsBtn:SetScript("OnClick",function() mode="quests"; detail._render() end)

  -- Opens a dungeon's detail page directly (used when the window is opened
  -- inside that dungeon).
  UI.OpenDungeon=function(target)
    if not target then return end
    selectedDungeon=target; mode="bosses"; browse:Hide(); detail:Show()
    bossSelection[target.key]=bossSelection[target.key] or 1
    questSelection[target.key]=questSelection[target.key] or 1
    if detail._render then detail._render() end
  end
  panel:Hide(); return panel
end


UI.RegisterPanel({ key="dungeons", label="Dungeons", order=2, tabWidth=128, create=createDungeonPanel })
