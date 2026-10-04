local _, A = ...
local GOLD = {1,0.82,0.45}
local COLORS = {Missing={0.78,0.83,0.88},Carried={0.35,0.85,1},Looted={0.48,0.83,0.66},Returned={0.42,0.87,0.53},Marked={0.9,0.72,0.42}}

local function Text(parent,font,x,y,width,value)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    label:SetPoint("TOPLEFT",x,y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(value or "")
    return label
end

local function Button(parent,label,width,x,y,callback)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetSize(width,25)
    button:SetPoint("TOPLEFT",x,y)
    button:SetText(label)
    button:SetScript("OnClick",callback)
    return button
end

local function Position(frame,key,point,x,y)
    frame:ClearAllPoints()
    local saved=A.db[key]
    if saved then frame:SetPoint(saved[1],UIParent,saved[2],saved[3],saved[4])
    else frame:SetPoint(point,UIParent,point,x,y) end
end

local function Draggable(frame,key)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        local point,_,relativePoint,x,y=self:GetPoint()
        A.db[key]={point,relativePoint,x,y}
    end)
end

local function Portrait(frame)
    local portrait=frame.portrait or (frame.PortraitContainer and frame.PortraitContainer.portrait)
    if portrait then portrait:SetTexture("Interface\\Icons\\INV_Misc_Book_09") end
end

local function Star(book)
    local advice=A.Advice(book)
    return advice=="Easy pickup" and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t " or advice=="Low-level option" and "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12:12|t " or ""
end

local function Tooltip(owner,book)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    GameTooltip:SetText(A.Name(book),unpack(GOLD))
    GameTooltip:AddLine(A.Zone(book.map)..string.format("  %.1f, %.1f",book.x,book.y),1,1,1)
    GameTooltip:AddLine(book.note,0.75,0.82,0.9,true)
    local advice,reason=A.Advice(book)
    GameTooltip:AddLine(advice..": "..reason,0.6,0.85,0.65,true)
    if book.uncertain then GameTooltip:AddLine("Forever location unknown • old SoD pin",1,0.5,0.25,true) end
    GameTooltip:Show()
end

function A.BuildUI()
    if A.frame then return end
    local f=CreateFrame("Frame","ForeverLibraryWindow",UIParent,"PortraitFrameTemplate,BackdropTemplate")
    A.frame=f
    f:SetSize(820,560)
    f:SetFrameStrata("HIGH")
    Position(f,"windowPosition","CENTER",0,0)
    Draggable(f,"windowPosition")
    if f.SetTitle then f:SetTitle("Forever Library Scout") elseif f.TitleText then f.TitleText:SetText("Forever Library Scout") end
    Portrait(f)
    table.insert(UISpecialFrames,"ForeverLibraryWindow")
    f:Hide()
    f:SetScript("OnShow",function() A.Scan() end)
    local background=CreateFrame("Frame",nil,f,"BackdropTemplate")
    background:SetPoint("TOPLEFT",7,-21)
    background:SetPoint("BOTTOMRIGHT",-7,7)
    A.StylePanel(background)
    local body=CreateFrame("Frame",nil,f,"BackdropTemplate")
    body:SetPoint("TOPLEFT",7,-61)
    body:SetPoint("BOTTOMRIGHT",-7,7)
    Text(body,"GameFontNormalLarge",20,-15,620,"Azeroth's scattered knowledge")
    f.summary=Text(body,"GameFontHighlightSmall",20,-41,590)
    Button(body,"Librarian & rewards",165,620,-18,function()
        A.rewardsFrame:SetShown(not A.rewardsFrame:IsShown())
        A.RefreshRewards()
    end)

    local left=CreateFrame("Frame",nil,body,"BackdropTemplate")
    left:SetPoint("TOPLEFT",16,-66)
    left:SetSize(440,389)
    A.StylePanel(left,true)
    f.search=CreateFrame("EditBox",nil,left,"SearchBoxTemplate")
    f.search:SetSize(408,24)
    f.search:SetPoint("TOPLEFT",12,-12)
    f.search:SetAutoFocus(false)
    f.search:SetScript("OnTextChanged",function(self)
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
        if f.scroll then f.scroll:SetVerticalScroll(0) end
        A.RefreshUI()
    end)
    f.filters={}
    for i,name in ipairs({"Missing","Carried","Tracked","Suggested","All"}) do
        f.filters[name]=Button(left,name,77,12+(i-1)*82,-44,function()
            A.filter=name
            f.scroll:SetVerticalScroll(0)
            A.RefreshUI()
        end)
    end
    f.scroll=A.CreateScrollFrame(left)
    f.scroll:SetPoint("TOPLEFT",8,-81)
    f.scroll:SetPoint("BOTTOMRIGHT",-20,12)
    f.content=CreateFrame("Frame",nil,f.scroll)
    f.content:SetSize(412,1)
    f.scroll:SetScrollChild(f.content)
    f.rows={}
    f.empty=Text(f.content,"GameFontHighlight",20,-40,380,"No books match this view.")

    local detail=CreateFrame("Frame",nil,body,"BackdropTemplate")
    detail:SetPoint("TOPLEFT",470,-66)
    detail:SetSize(324,389)
    A.StylePanel(detail,true)
    f.detail=detail
    Text(detail,"GameFontNormalSmall",14,-12,296,"FIELD NOTES")
    f.detailName=Text(detail,"GameFontNormalLarge",14,-33,296)
    f.detailName:SetWordWrap(true)
    f.detailZone=Text(detail,"GameFontHighlight",14,-81,296)
    f.detailStatus=Text(detail,"GameFontNormal",14,-103,296)
    -- Scroll long notes rather than clipping cave instructions or access warnings.
    f.noteScroll=A.CreateScrollFrame(detail)
    f.noteScroll:SetPoint("TOPLEFT",14,-129)
    f.noteScroll:SetSize(278,105)
    f.noteContent=CreateFrame("Frame",nil,f.noteScroll)
    f.noteContent:SetSize(274,105)
    f.noteScroll:SetScrollChild(f.noteContent)
    f.detailNote=Text(f.noteContent,"GameFontHighlight",0,0,274)
    f.detailNote:SetSpacing(3)
    f.detailNote:SetWordWrap(true)
    f.navigate=Button(detail,"Show map & navigate",190,14,-246,function() if A.selected then A.Navigate(A.selected,A.selected) end end)
    f.track=Button(detail,"Track",94,212,-246,function() if A.selected then A.ToggleTrack(A.selected) end end)
    f.alternate=Button(detail,"Thelsamar location",190,14,-277,function() A.Navigate(A.alternate,A.selected) end)
    f.manual=Button(detail,"Mark previously looted",220,14,-308,function()
        if A.selected then
            local q=A.selected.quest
            A.db.manual[q]=not A.db.manual[q] or nil
            A.Refresh()
        end
    end)
    Text(detail,"GameFontDisableSmall",14,-346,296,"Marked = your note, not a confirmed turn-in.\nGreen check: easy • Yellow clock: combat\nTravel can still be dangerous; hover for details.")

    f.trackerToggle=Button(body,"Tracker",88,20,-469,function() A.db.showTracker=not A.db.showTracker; A.Refresh() end)
    f.pinToggle=Button(body,"Map pins",100,118,-469,function() A.db.showPins=not A.db.showPins; A.Refresh() end)
    f.pinMode=Button(body,"Pins: missing",142,228,-469,function()
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(f.pinMode,function(_,root)
                root:CreateTitle("Show book pins")
                for _,entry in ipairs({{"Missing books","missing"},{"Tracked books","tracked"},{"All known books","all"}}) do
                    local value=entry[2]
                    root:CreateRadio(entry[1],function() return (A.db.pinMode or "missing")==value end,function() A.db.pinMode=value; A.Refresh() end)
                end
            end)
        else
            A.db.pinMode=A.db.pinMode=="all" and "tracked" or A.db.pinMode=="tracked" and "missing" or "all"
            A.Refresh()
        end
    end)
    f.themeToggle=Button(body,"Theme: classic",142,380,-469,A.ToggleTheme)
    Text(body,"GameFontDisableSmall",539,-476,255,"Rewards at 10 & 20 turn-ins")
    A.filter="Missing"
    A.selected=A.books[1]
    A.BuildRewards()
    A.BuildTracker()
    A.ApplyTheme()
    if A.CreateGamepad then A.CreateGamepad() end
end

function A.NewRow(index)
    local row=CreateFrame("Button",nil,A.frame.content)
    row:SetSize(410,54)
    row:SetPoint("TOPLEFT",0,-(index-1)*56)
    row.bg=row:CreateTexture(nil,"BACKGROUND")
    row.bg:SetAllPoints()
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(28,28)
    row.icon:SetPoint("LEFT",9,0)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    row.name=Text(row,"GameFontHighlight",45,-7,270)
    row.name:SetMaxLines(2)
    row.zone=Text(row,"GameFontDisableSmall",45,-37,270)
    row.state=Text(row,"GameFontHighlightSmall",320,-19,86)
    row:SetScript("OnClick",function(self)
        A.selected=self.book
        A.frame.noteScroll:SetVerticalScroll(0)
        if IsShiftKeyDown() then A.ToggleTrack(self.book) else A.RefreshUI() end
    end)
    row:SetScript("OnEnter",function(self) Tooltip(self,self.book) end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return row
end

function A.RefreshUI()
    local f=A.frame
    if not f or not f.rows then return end
    local found,returned,carried=A.Counts()
    f.summary:SetText(string.format("%d / 40 collected   •   %d returned   •   %d carried   •   %d missing",found,returned,carried,#A.books-found))
    f.trackerToggle:SetText(A.db.showTracker and "Tracker: on" or "Tracker: off")
    f.pinToggle:SetText(A.db.showPins and "Pins: on" or "Pins: off")
    f.pinMode:SetText("Pins: "..(A.db.pinMode or "missing"))
    for name,button in pairs(f.filters) do button:SetEnabled(name~=A.filter) end
    local query=(f.search:GetText() or ""):lower()
    local list={}
    for _,book in ipairs(A.books) do
        local status=A.Status(book)
        local advice=A.Advice(book)
        local suggested=advice=="Easy pickup" or advice=="Low-level option"
        local matches=A.filter=="All" or (A.filter=="Missing" and status=="Missing") or (A.filter=="Carried" and status=="Carried") or (A.filter=="Tracked" and A.db.tracked[book.quest]) or (A.filter=="Suggested" and suggested and status=="Missing")
        if matches and (query=="" or (A.Name(book).." "..book.name.." "..A.Zone(book.map).." "..book.note):lower():find(query,1,true)) then list[#list+1]=book end
    end
    local current=C_Map and C_Map.GetBestMapForUnit("player")
    table.sort(list,function(a,b)
        if (a.map==current)~=(b.map==current) then return a.map==current end
        if A.filter=="Suggested" then
            local easyA,easyB=A.Advice(a)=="Easy pickup",A.Advice(b)=="Easy pickup"
            if easyA~=easyB then return easyA end
        end
        if a.uncertain~=b.uncertain then return not a.uncertain end
        local za,zb=A.Zone(a.map),A.Zone(b.map)
        if za~=zb then return za<zb end
        return A.Name(a)<A.Name(b)
    end)
    if not A.selected then A.selected=list[1] or A.books[1] end
    for i,book in ipairs(list) do
        local row=f.rows[i] or A.NewRow(i)
        f.rows[i]=row
        row.book=book
        local iconFn=C_Item and C_Item.GetItemIconByID or GetItemIcon
        row.icon:SetTexture((iconFn and iconFn(book.item)) or "Interface\\Icons\\INV_Misc_Book_09")
        row.name:SetText(Star(book)..A.Name(book))
        row.zone:SetText(A.Zone(book.map)..string.format("  •  %.1f, %.1f",book.x,book.y)..(book.uncertain and "  •  unknown" or book.entrance and "  •  entrance" or ""))
        local status=A.Status(book)
        row.state:SetText(A.db.tracked[book.quest] and "Tracked" or status)
        row.state:SetTextColor(unpack(COLORS[status]))
        local selected=A.selected==book
        if A.db.darkSkin then row.bg:SetColorTexture(0.17,0.24,0.32,selected and 0.65 or (i%2==0 and 0.3 or 0.15))
        else row.bg:SetColorTexture(0.30,0.23,0.12,selected and 0.35 or (i%2==0 and 0.11 or 0.05)) end
        row:Show()
    end
    for i=#list+1,#f.rows do f.rows[i]:Hide() end
    f.content:SetHeight(math.max(100,#list*56))
    f.empty:SetShown(#list==0)
    f.scroll:SyncScrollBar()
    local maxScroll=math.max(0,f.content:GetHeight()-f.scroll:GetHeight())
    if f.scroll:GetVerticalScroll()>maxScroll then f.scroll:SetVerticalScroll(maxScroll) end
    local book=A.selected
    if book then
        local status=A.Status(book)
        f.detailName:SetText(A.Name(book))
        f.detailZone:SetText(A.Zone(book.map)..string.format("  •  %.1f, %.1f",book.x,book.y))
        f.detailStatus:SetText(status..(book.uncertain and "  •  Forever location unknown" or book.entrance and "  •  Entrance pin" or ""))
        f.detailStatus:SetTextColor(unpack(COLORS[status]))
        local advice,reason=A.Advice(book)
        f.detailNote:SetText(book.note.."\n\n|cffffce72"..advice.."|r: "..reason)
        f.noteContent:SetHeight(math.max(105,f.detailNote:GetStringHeight()+4))
        f.noteScroll:SyncScrollBar()
        f.track:SetText(A.db.tracked[book.quest] and "Untrack" or "Track")
        f.track:SetEnabled(status~="Returned")
        f.navigate:SetText(book.uncertain and "Show old SoD location" or "Show map & navigate")
        f.alternate:SetShown(book.quest==A.alternate.quest)
        f.manual:SetText(A.db.manual[book.quest] and "Clear manual note" or "Mark previously looted")
        f.manual:SetEnabled(status=="Missing" or status=="Marked")
    end
    if A.rewardsFrame then A.RefreshRewards() end
end

function A.RewardTooltip(button,reward)
    GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:"..reward.item)
    if GameTooltip:NumLines()==0 then
        GameTooltip:SetText(reward.name,0.3,0.55,1)
        GameTooltip:AddLine(reward.stats,1,1,1,true)
    end
    GameTooltip:AddLine(reward.count.." different books turned in • choose one reward",unpack(GOLD))
    GameTooltip:Show()
end

function A.BuildRewards()
    local f=CreateFrame("Frame","ForeverLibraryRewards",UIParent,"PortraitFrameTemplate,BackdropTemplate")
    A.rewardsFrame=f
    f:SetSize(560,455)
    Position(f,"rewardsPosition","CENTER",60,0)
    f:SetFrameStrata("DIALOG")
    if f.SetTitle then f:SetTitle("Librarian & rewards") end
    Portrait(f)
    table.insert(UISpecialFrames,"ForeverLibraryRewards")
    Draggable(f,"rewardsPosition")
    f:Hide()
    f.heading=Text(f,"GameFontNormalLarge",24,-70,510)
    f.subtitle=Text(f,"GameFontHighlightSmall",24,-98,510)
    f.subtitle:SetWordWrap(true)
    f.subtitle:SetHeight(42)
    f.cards={}
    for i,reward in ipairs(A.rewards) do
        local card=CreateFrame("Button",nil,f,"BackdropTemplate")
        card:SetPoint("TOPLEFT",22,-150-(i-1)*49)
        card:SetSize(510,45)
        A.StylePanel(card,true)
        card.icon=card:CreateTexture(nil,"ARTWORK")
        card.icon:SetPoint("LEFT",8,0)
        card.icon:SetSize(32,32)
        card.icon:SetTexture("Interface\\Icons\\"..reward.icon)
        Text(card,"GameFontHighlight",48,-6,345,"|cff4488ff"..reward.name.."|r")
        Text(card,"GameFontHighlightSmall",48,-25,355,reward.stats)
        card.state=Text(card,"GameFontNormalSmall",410,-16,94)
        card:SetScript("OnEnter",function(self) A.RewardTooltip(self,reward) end)
        card:SetScript("OnLeave",function() GameTooltip:Hide() end)
        card:SetScript("OnClick",function()
            if IsModifiedClick("CHATLINK") then
                local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
                local _,link=fn(reward.item)
                if link then HandleModifiedItemClick(link) end
            end
        end)
        f.cards[i]=card
    end
    Button(f,"Show my librarian on the map",260,24,-357,function() A.Navigate(A.Librarian()) end)
    Text(f,"GameFontDisableSmall",24,-395,510,"Turn in books and collect rewards from this same librarian.\nChoose one item at 10 and one at 20 total. Marked books do not count.")
end

function A.RefreshRewards()
    local _,returned,carried=A.Counts()
    local f=A.rewardsFrame
    f.heading:SetText(returned.." books returned to the library")
    f.subtitle:SetText((UnitFactionGroup("player") or "").." • "..A.Librarian().note.."\n"..carried.." books in your bags to turn in")
    for i,reward in ipairs(A.rewards) do
        f.cards[i].state:SetText(A.RewardDone(reward) and "Completed" or returned>=reward.count and "Visit NPC" or (returned.."/"..reward.count))
        local fn=C_Item and C_Item.GetItemIconByID or GetItemIcon
        local icon=fn and fn(reward.item)
        if icon then f.cards[i].icon:SetTexture(icon) end
        local eligible=not reward.class or (UnitClass and select(2,UnitClass("player"))==reward.class)
        f.cards[i].icon:SetDesaturated(not eligible)
        if not eligible then f.cards[i].state:SetText("Rogue only") end
    end
end

function A.BuildTracker()
    local f=CreateFrame("Frame","ForeverLibraryTracker",UIParent,"BackdropTemplate")
    A.tracker=f
    f:SetSize(280,80)
    Position(f,"trackerPosition","RIGHT",-55,70)
    Draggable(f,"trackerPosition")
    A.StylePanel(f)
    Text(f,"GameFontNormal",14,-12,205,"LIBRARY SCOUT")
    f.count=Text(f,"GameFontHighlightSmall",14,-34,248)
    Button(f,"+",24,217,-8,function() A.ToggleWindow() end)
    Button(f,"−",24,244,-8,function() A.db.showTracker=false; A.Refresh() end)
    f.rows={}
    f.empty=Text(f,"GameFontDisableSmall",14,-61,248,"Track books from /books.\nShift-click a journal row to track it.")
    f.more=Text(f,"GameFontNormalSmall",14,-375,250)
end

function A.RefreshTracker()
    local f=A.tracker
    if not f then return end
    f:SetShown(A.db.showTracker)
    if not A.db.showTracker then return end
    local _,returned,carried=A.Counts()
    f.count:SetText(string.format("%d / 20 returned  •  %d ready to bring",returned,carried))
    local list={}
    for _,book in ipairs(A.books) do if A.db.tracked[book.quest] and A.Status(book)~="Returned" then list[#list+1]=book end end
    local current=C_Map and C_Map.GetBestMapForUnit("player")
    table.sort(list,function(a,b)
        if (a.map==current)~=(b.map==current) then return a.map==current end
        return a.quest<b.quest
    end)
    for i=1,math.min(6,#list) do
        local row=f.rows[i]
        if not row then
            row=CreateFrame("Button",nil,f)
            row:SetPoint("TOPLEFT",12,-57-(i-1)*52)
            row:SetSize(256,49)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
            row.name=Text(row,"GameFontHighlightSmall",0,-3,230)
            row.name:SetMaxLines(2)
            row.zone=Text(row,"GameFontDisableSmall",0,-32,250)
            row:SetScript("OnClick",function(self) if IsShiftKeyDown() then A.ToggleTrack(self.book) else A.Navigate(self.book,self.book) end end)
            row:SetScript("OnEnter",function(self) Tooltip(self,self.book); GameTooltip:AddLine("Click: map pin • Shift-click: untrack",0.4,0.9,0.9); GameTooltip:Show() end)
            row:SetScript("OnLeave",function() GameTooltip:Hide() end)
            f.rows[i]=row
        end
        row.book=list[i]
        local status=A.Status(list[i])
        row.name:SetText((list[i].uncertain and "? " or Star(list[i])~="" and Star(list[i]) or "• ")..A.Name(list[i]))
        row.name:SetTextColor(unpack(COLORS[status]))
        row.zone:SetText(A.Zone(list[i].map).."  •  "..status)
        row:Show()
    end
    for i=math.min(6,#list)+1,#f.rows do f.rows[i]:Hide() end
    f.empty:SetShown(#list==0)
    f.more:SetText(#list>6 and ("+"..(#list-6).." more • open journal") or "")
    f.more:SetShown(#list>6)
    f:SetHeight(#list==0 and 112 or 65+math.min(6,#list)*52+(#list>6 and 24 or 0))
end

function A.ToggleWindow()
    if not A.frame then A.BuildUI() end
    A.frame:SetShown(not A.frame:IsShown())
end

function A.RegisterSettings()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local panel=CreateFrame("Frame")
    Text(panel,"GameFontNormalLarge",16,-16,560,"Forever Library Scout • Created by Kushen")
    Text(panel,"GameFontHighlight",16,-50,560,"Collect books and plan your next stop. Your faction's librarian is selected automatically.\n\n/books: journal • /books tracker: tracker • /books minimap: minimap button\nShift-click rows to track. Choose your theme inside the journal.")
    Button(panel,"Open book journal",190,16,-170,function() A.ToggleWindow() end)
    local category=Settings.RegisterCanvasLayoutCategory(panel,"Forever Library Scout")
    Settings.RegisterAddOnCategory(category)
end
