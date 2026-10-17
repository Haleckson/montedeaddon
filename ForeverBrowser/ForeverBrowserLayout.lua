-- Shared presentation layer. Existing builders and database records remain intact.
ForeverBrowserLayout226={}
local L=ForeverBrowserLayout226
local function text(object)
    if object and type(object.GetText)=="function" then return tostring(object:GetText() or "") end
    if object and object.text and type(object.text.GetText)=="function" then return tostring(object.text:GetText() or "") end
    return ""
end
local function category(url)
    if url:find("profession",1,true) or url:find("recipe",1,true) or url:find("shopping",1,true) or url:find("planner",1,true) then return "Professions","forever://professions" end
    if url:find("dungeon",1,true) or url:find("farming",1,true) or url:find("guides",1,true) then return "Dungeons","forever://dungeons" end
    if url:find("quest",1,true) or url:find("chain",1,true) then return "Quests","forever://quests" end
    if url:find("npc",1,true) then return "NPCs","forever://npcs" end
    if url:find("item",1,true) or url:find("list",1,true) or url:find("tags",1,true) or url:find("favorites",1,true) or url:find("recent",1,true) then return "Items","forever://items" end
    if url:find("settings",1,true) or url:find("updates",1,true) or url:find("debug",1,true) then return "Settings","forever://codex/settings" end
    if url:find("codex",1,true) then return "Codex Tools","forever://codex" end
    return "Home","forever://home"
end
local function sectionName(value)
    value=value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):upper():gsub("%s*%(%d+%)%s*$","")
    if value=="ITEM INFORMATION" or value=="NPC INFORMATION" or value=="QUEST INFORMATION" or value=="OVERVIEW" then return "Overview" end
    if value:find("PERSONAL NOTES",1,true) or value=="NOTES & TAGS" then return "My Notes" end
    if value=="WHERE TO OBTAIN" or value=="ACQUISITION SOURCES" then return "Sources" end
    if value=="NPC LOCATIONS" or value=="LOCATIONS" or value=="ENTRANCES" then return "Locations" end
    if value=="VENDOR ITEMS" or value=="VENDOR INVENTORY" then return "Vendor" end
    if value=="DROPS" or value=="DROP ITEMS" or value=="LOOT" or value=="ALL DUNGEON LOOT" then return "Loot" end
    if value=="QUESTS" or value=="QUEST STARTERS" or value=="QUEST FINISHERS" or value=="RELATED QUESTS" then return "Quests" end
    if value=="QUEST REWARDS" or value=="REWARDS" then return "Rewards" end
    if value=="OBJECTIVES" or value=="QUEST OBJECTIVES" then return "Objectives" end
    if value=="REAGENTS" or value=="MATERIALS" then return "Materials" end
    if value=="LEARNED FROM" or value=="TRAINERS" then return "Learning" end
    if value=="DUNGEON BOSSES" or value=="BOSSES" then return "Bosses" end
    if value=="DATABASE DETAILS" or value=="DATA PROVENANCE" then return "Data Details" end
end
local function points(object)
    local result={}
    if type(object.GetNumPoints)=="function" then for i=1,object:GetNumPoints() do result[#result+1]={object:GetPoint(i)} end end
    return result
end
function L:Settings()
    local db=self.context.database()
    db.layout226=db.layout226 or {enabled=true,tabs={}}
    db.layout226.tabs=db.layout226.tabs or {}
    return db.layout226
end
function L:Restore()
    for _,node in ipairs(self.nodes or {}) do
        if node.moved then
            node.object:ClearAllPoints()
            for _,p in ipairs(node.points) do node.object:SetPoint(unpack(p)) end
            node.object:SetSize(node.width,node.height)
            node.moved=false
        end
        if node.hidden then node.object:Show();node.hidden=false end
    end
    for _,action in ipairs(self.actions or {}) do if action.hidden then action.object:Show();action.hidden=false end end
end
function L:Begin()
    if self.menu then self.menu:Hide() end
    self:Restore();self.nodes=nil;self.actions=nil;self.groups=nil;self.originalHeight=nil
end
function L:Menu(entries)
    local ctx=self.context
    if not self.menu then
        self.menu=CreateFrame("Frame",nil,ctx.scroll:GetParent())
        self.menu:SetFrameStrata("TOOLTIP");self.menu:SetFrameLevel(1000)
        self.menuButtons={}
        ctx.background(self.menu,unpack((ctx.theme and ctx.theme.inset) or {.025,.02,.015,.99}))
    end
    self.menu:ClearAllPoints();self.menu:SetPoint("TOPRIGHT",self.bar,"BOTTOMRIGHT",0,-3)
    self.menu:SetSize(260,math.min(#entries,12)*30+12)
    self.menuPage=1
    local function paint()
        for _,button in ipairs(self.menuButtons) do button:Hide() end
        local first=(self.menuPage-1)*10+1
        for i=first,math.min(#entries,first+9) do
            local slot=i-first+1;local e=entries[i];local button=self.menuButtons[slot]
            if not button then button=ctx.button(self.menu,"",240,26);self.menuButtons[slot]=button end
            button:SetPoint("TOPLEFT",self.menu,"TOPLEFT",10,-8-(slot-1)*30);button:SetText(e.name)
            button:SetScript("OnClick",function() self.menu:Hide();e.run() end)
            if e.disabled then button:Disable() else button:Enable() end
            button:Show()
        end
        if #entries>10 then
            local button=self.menuButtons[11]
            if not button then button=ctx.button(self.menu,"",240,26);self.menuButtons[11]=button end
            button:SetPoint("TOPLEFT",self.menu,"TOPLEFT",10,-308);button:SetText("More options >")
            button:Enable();button:Show();button:SetScript("OnClick",function() self.menuPage=self.menuPage%math.ceil(#entries/10)+1;paint() end)
        end
    end
    paint();self.menu:Show()
end
function L:Select(name,automatic)
    self:Restore()
    self.selected=name
    self:Settings().tabs[self.context.url]=name
    if name=="All Sections" or not self.groups or #self.groups<2 then
        self.context.page:SetHeight(self.originalHeight or 700)
    else
        local first=self.groups[1].y;local selected
        for _,group in ipairs(self.groups) do if group.name==name then selected=group break end end
        if not selected then return self:Select("All Sections") end
        local delta=selected.y-first;local bottom=first+80
        for _,node in ipairs(self.nodes or {}) do
            if node.group then
                if node.group.name==name then
                    node.object:ClearAllPoints();node.object:SetSize(node.width,node.height)
                    node.object:SetPoint("TOPLEFT",self.context.page,"TOPLEFT",node.x,-node.y+delta)
                    node.moved=true;bottom=math.max(bottom,node.y-delta+node.height)
                else node.object:Hide();node.hidden=true end
            end
        end
        self.context.page:SetHeight(math.max(600,bottom+40))
    end
    -- Header actions remain available through their original callbacks.
    for _,action in ipairs(self.actions or {}) do action.object:Hide();action.hidden=true end
    if self.sectionButton then self.sectionButton:SetText("All / More Sections") end
    for _,button in ipairs(self.tabButtons or {}) do if button.sectionName then button:SetText(button.sectionName==name and ("["..name.."]") or button.sectionName) end end
    if not automatic and self.context.scroll.SetVerticalScroll then self.context.scroll:SetVerticalScroll(0) end
end
function L:Build()
    local ctx=self.context
    self:Restore()
    if self.originalHeight then ctx.page:SetHeight(self.originalHeight) end
    local enabled=self:Settings().enabled~=false
    if not self.bar then
        self.bar=CreateFrame("Frame",nil,ctx.scroll:GetParent())
        self.bar:SetHeight(66)
        self.bar:SetPoint("TOPLEFT",ctx.navigation,"TOPRIGHT",10,0)
        self.bar:SetPoint("TOPRIGHT",ctx.scroll,"TOPRIGHT",0,66)
        ctx.background(self.bar,unpack((ctx.theme and ctx.theme.panel) or {.035,.028,.019,.98}))
        self.categoryButton=ctx.button(self.bar,"",140,26);self.categoryButton:SetPoint("TOPLEFT",self.bar,"TOPLEFT",8,-5)
        self.title=ctx.label(self.bar,"",12,(ctx.theme and ctx.theme.goldSoft) or {.87,.81,.67,1});self.title:SetPoint("LEFT",self.categoryButton,"RIGHT",12,0);self.title:SetWidth(430);self.title:SetHeight(22);self.title:SetJustifyH("LEFT")
        self.sectionButton=ctx.button(self.bar,"All Sections",185,26);self.sectionButton:SetPoint("TOPLEFT",self.bar,"TOPLEFT",8,-35)
        self.actionsButton=ctx.button(self.bar,"Page Actions",150,26);self.actionsButton:SetPoint("TOPRIGHT",self.bar,"TOPRIGHT",-10,-35)
    end
    ctx.scroll:SetPoint("TOPLEFT",ctx.navigation,"TOPRIGHT",10,enabled and -66 or 0)
    if not enabled then self.bar:Hide();return end
    self.bar:Show()
    local cat,route=category(ctx.url)
    self.categoryButton:SetText(cat);self.categoryButton:SetScript("OnClick",function() ctx.navigate(route) end)
    self.title:SetText(cat.." • Browse and manage records")
    self.originalHeight=ctx.page:GetHeight();self.actions={};self.nodes={};self.groups={}
    local pageTop,pageLeft=ctx.page:GetTop(),ctx.page:GetLeft()
    if not pageTop or not pageLeft then return end
    local objects={ctx.page:GetChildren()}
    for _,region in ipairs({ctx.page:GetRegions()}) do objects[#objects+1]=region end
    local seen={};local bestTitle,bestSize=nil,0
    local function pageTitle(label)
        if type(label.GetFont)~="function" or type(label.GetTop)~="function" then return end
        local _,size=label:GetFont();local value=text(label);local top=label:GetTop()
        if top and pageTop-top<220 and type(size)=="number" and size>=18 and size>bestSize and value~="" then bestTitle=value;bestSize=size end
    end
    local function heading(root,label)
        local name=sectionName(text(label))
        local top=root:GetTop()
        if name and top and pageTop-top>100 and not seen[root] then
            seen[root]=true;self.groups[#self.groups+1]={name=name,y=pageTop-top,root=root}
        end
    end
    for _,object in ipairs(objects) do
        if object:IsShown() and object.GetTop and object.GetLeft and object.GetWidth and object.GetHeight then
            local top,left=object:GetTop(),object:GetLeft()
            if top and left then
                local node={object=object,x=left-pageLeft,y=pageTop-top,width=object:GetWidth(),height=object:GetHeight(),points=points(object)}
                self.nodes[#self.nodes+1]=node
                if object.GetObjectType and object:GetObjectType()=="FontString" then pageTitle(object);heading(object,object) end
                if object.GetRegions and object.GetObjectType and object:GetObjectType()=="Frame" then
                    for _,region in ipairs({object:GetRegions()}) do if region.GetObjectType and region:GetObjectType()=="FontString" then pageTitle(region);heading(object,region) end end
                end
                if object.GetObjectType and object:GetObjectType()=="Button" and node.y>=0 and node.y<56 then
                    local label=text(object);local fn=object:GetScript("OnClick")
                    if label~="" and fn then self.actions[#self.actions+1]={object=object,name=label,run=fn,x=node.x} end
                end
            end
        end
    end
    if bestTitle then self.title:SetText(bestTitle:gsub("[\r\n]+"," ")) end
    table.sort(self.actions,function(a,b) return a.x<b.x end)
    table.sort(self.groups,function(a,b) return a.y<b.y end)
    -- Only long record/settings pages receive section isolation; browsing grids stay intact.
    local detail=ctx.url:match("^forever://item/%d+$") or ctx.url:match("^forever://npc/%d+$") or ctx.url:match("^forever://quest/%d+$") or ctx.url:match("^forever://recipe/%d+$") or ctx.url:match("^forever://dungeon/") or ctx.url:match("settings$")
    if not detail then self.groups={} end
    if #self.groups>=2 then for _,node in ipairs(self.nodes) do
        for _,group in ipairs(self.groups) do if node.y>=group.y-3 then node.group=group end end
    end end
    self.tabButtons=self.tabButtons or {}
    for _,button in ipairs(self.tabButtons) do button:Hide() end
    local unique,seenNames={},{}
    for _,group in ipairs(self.groups) do if not seenNames[group.name] then seenNames[group.name]=true;unique[#unique+1]=group.name end end
    self.sectionButton:ClearAllPoints()
    self.sectionButton:SetSize(#unique>=2 and 150 or 185,26)
    self.sectionButton:SetPoint("TOPLEFT",self.bar,"TOPLEFT",#unique>=2 and 428 or 8,-35)
    if #unique>=2 then for i=1,math.min(3,#unique) do
        local name=unique[i];local button=self.tabButtons[i]
        if not button then button=ctx.button(self.bar,name,130,26);self.tabButtons[i]=button end
        button.sectionName=name;button:ClearAllPoints();button:SetPoint("TOPLEFT",self.bar,"TOPLEFT",8+(i-1)*140,-35)
        button:SetScript("OnClick",function() self:Select(name) end);button:Show()
    end end
    self.sectionButton:SetScript("OnClick",function()
        local entries={{name="All Sections",run=function() self:Select("All Sections") end}};local names={}
        for _,group in ipairs(self.groups) do if not names[group.name] then names[group.name]=true;local name=group.name;entries[#entries+1]={name=name,run=function() self:Select(name) end} end end
        self:Menu(entries)
    end)
    if #self.groups>=2 then self.sectionButton:Enable() else self.sectionButton:Disable() end
    self.actionsButton:SetScript("OnClick",function()
        local entries={}
        for _,action in ipairs(self.actions) do local original=action;entries[#entries+1]={name=original.name,disabled=original.object.IsEnabled and not original.object:IsEnabled(),run=function()
            original.run(original.object,"LeftButton")
            if self.context==ctx then self:Build() end
        end} end
        entries[#entries+1]={name="Show original page layout",run=function() self:Settings().enabled=false;self:Restore();self.bar:Hide();ctx.scroll:SetPoint("TOPLEFT",ctx.navigation,"TOPRIGHT",10,0);ctx.page:SetHeight(self.originalHeight or 700) end}
        self:Menu(entries)
    end)
    local saved=self:Settings().tabs[ctx.url]
    self:Select(saved or (#self.groups>=2 and self.groups[1].name or "All Sections"),true)
end
function L:Schedule(context)
    self.context=context
    if not self.worker then self.worker=CreateFrame("Frame") end
    local ticks=0
    self.worker:SetScript("OnUpdate",function(frame)
        ticks=ticks+1;if ticks<2 then return end
        frame:SetScript("OnUpdate",nil)
        self:Build()
    end)
end
SLASH_FOREVERBROWSERLAYOUT2261="/fblayout"
SlashCmdList.FOREVERBROWSERLAYOUT226=function()
    if L.context then L:Settings().enabled=not L:Settings().enabled;L:Begin();L.context.navigate(L.context.url,true) end
end
