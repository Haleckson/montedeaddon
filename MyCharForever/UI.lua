local addonName, MCF = ...
local function T(key) return MCF:T(key) end

-- Defined further down; declared here so earlier code sees the local, not a nil global.
local ScreenshotTypeLabel, ShowLevelScreenshotFiles
-- Forward-declared because RefreshUI is defined before the achievement widgets.
local achUI = {}

local frame=CreateFrame("Frame","MyCharForeverFrame",UIParent,"BasicFrameTemplateWithInset")
-- Keep the window within the visible UI area, including on smaller displays.
-- Do not enlarge it from navigation refreshes or while a resize is in progress.
-- Frames and regions can never be destroyed in WoW. Rows that are redrawn on every refresh are retired into a
-- hidden parent instead of staying under the window: the window's tree (font scaling, layout) then stays small
-- however often it is redrawn. MCF.perf counts what was retired (shown by /mcf perf).
MCF.graveyard=CreateFrame("Frame"); MCF.graveyard:Hide()
MCF.perf=MCF.perf or {retired=0}
function MCF.Retire(o)
    if not o then return end
    if o.Hide then o:Hide() end
    if o.SetParent then o:SetParent(MCF.graveyard) end
    MCF.perf.retired=MCF.perf.retired+1
end
local WINDOW_MIN_W, WINDOW_MIN_H = 700, 480
local WINDOW_SCREEN_HEIGHT_FRACTION = 0.92 -- share of the screen height the window may use at most
local WINDOW_MAX_W, WINDOW_MAX_H = 1000, 1400
local function WindowLimits()
    local screenW = UIParent:GetWidth() or WINDOW_MAX_W
    local screenH = UIParent:GetHeight() or WINDOW_MAX_H
    return math.min(WINDOW_MAX_W, math.max(WINDOW_MIN_W, screenW - 40)),
           math.max(1, math.min(WINDOW_MAX_H, screenH * WINDOW_SCREEN_HEIGHT_FRACTION))
end
local function ClampWindowSize()
    local maxW, maxH = WindowLimits()
    local w = math.min(maxW, math.max(math.min(WINDOW_MIN_W,maxW), frame:GetWidth()))
    local h = math.min(maxH, math.max(math.min(WINDOW_MIN_H,maxH), frame:GetHeight()))
    if math.abs(frame:GetWidth()-w)>0.5 or math.abs(frame:GetHeight()-h)>0.5 then
        frame:SetSize(w,h)
    end
end
local WINDOW_DEFAULT_W, WINDOW_DEFAULT_H = 900, 620
frame:SetSize(WINDOW_DEFAULT_W,WINDOW_DEFAULT_H)
frame:SetPoint("CENTER")
frame:SetResizable(true)
local maxW,maxH=WindowLimits()
if frame.SetResizeBounds then frame:SetResizeBounds(WINDOW_MIN_W,WINDOW_MIN_H,maxW,maxH)
else
    if frame.SetMinResize then frame:SetMinResize(WINDOW_MIN_W,WINDOW_MIN_H) end
    if frame.SetMaxResize then frame:SetMaxResize(maxW,maxH) end
end
frame:SetClampedToScreen(true)
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
-- Reset size/position every time the window is opened. No saved layout geometry.
local function ResetWindowGeometry()
    local maxW,maxH=WindowLimits()
    frame:ClearAllPoints()
    frame:SetSize(math.min(WINDOW_DEFAULT_W,maxW),math.min(WINDOW_DEFAULT_H,maxH))
    frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(math.min(WINDOW_MIN_W,maxW),math.min(WINDOW_MIN_H,maxH),maxW,maxH)
    end
end
frame:SetScript("OnShow",function()
    ResetWindowGeometry()
    if MCF.uiDirty and MCF.RefreshUI then MCF:RefreshUI() end
end)
frame:Hide()

-- Description texts at the top of tabs (journal, screenshots, gold): one shared font, two points larger than the standard text.
do local d=CreateFont("MyCharForeverDescriptionFont"); local f,sz,fl=GameFontHighlight:GetFont(); d:SetFont(f,(sz or 12)+2,fl); d:SetTextColor(1,1,1) end

-- Font scaling only affects addon-owned font strings, never the Blizzard UI.
local scaledFonts=setmetatable({},{__mode="k"})
function MCF:GetFontScale()
    local st=MyCharForeverDB and MyCharForeverDB.settings
    local v=st and tonumber(st.fontScale) or 1
    for _,c in ipairs(MCF.FontScaleChoices) do if c[1]==v then return v end end
    return 1
end
function MCF:SetFontScale(value)
    local st=MyCharForeverDB and MyCharForeverDB.settings
    if st then st.fontScale=value end
    if self.RefreshUI then self:RefreshUI() end
    if self.ApplyFontScale then self:ApplyFontScale() end
end
local function ScaleTree(root, factor, depth)
    if not root or depth>18 then return end
    if root.GetRegions then
        for i=1,root:GetNumRegions() do
            local region=select(i,root:GetRegions())
            if region and region.IsObjectType and region:IsObjectType("FontString") and region.GetFont then
                local font,size,flags=region:GetFont()
                if font and type(size)=="number" and size>0 then
                    local record=scaledFonts[region]
                    local base=(record and record.font==font and math.abs(size-record.base*record.scale)<0.1) and record.base or size
                    if not record or record.scale~=factor or base~=record.base then
                        region:SetFont(font,math.max(6,base*factor),flags)
                    end
                    scaledFonts[region]={font=font,base=base,scale=factor}
                end
            end
        end
    end
    if root.GetChildren then
        local children={root:GetChildren()}
        for _,childFrame in ipairs(children) do ScaleTree(childFrame,factor,depth+1) end
    end
end
function MCF:ApplyFontScale()
    local factor=self:GetFontScale()
    self.fontAppliedFactor=factor
    ScaleTree(frame,factor,0)
    if self.settingsFontRoot then ScaleTree(self.settingsFontRoot,factor,0) end
end
local fontElapsed=0
frame:HookScript("OnUpdate",function(_,elapsed)
    fontElapsed=fontElapsed+elapsed
    if fontElapsed>=0.35 then
        fontElapsed=0
        -- Walking the whole window tree is costly: only when content was rebuilt or the scale changed.
        if MCF.fontDirty or MCF.fontAppliedFactor~=MCF:GetFontScale() then MCF.fontDirty=false; MCF:ApplyFontScale() end
    end
end)

local resizeGrip=CreateFrame("Button",nil,frame)
resizeGrip:SetSize(20,20)
resizeGrip:SetPoint("BOTTOMRIGHT",-5,5)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
resizeGrip:SetScript("OnMouseDown",function(self,button)
    if button=="LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
end)
resizeGrip:SetScript("OnMouseUp",function(self,button)
    if button=="LeftButton" then
        frame:StopMovingOrSizing()
        ClampWindowSize()
    end
end)
frame.title=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
frame.title:SetPoint("TOP",0,-5); frame.title:SetText("MyCharForever")

local viewMode="overview"
local ClearAchievementRows, DrawAchievementRows

local tabs={}
local function CreateTab(label, x)
    local tab=CreateFrame("Button",nil,frame)
    tab:SetSize(108,28)
    tab:SetPoint("TOPLEFT",x,-27)

    tab.bg=tab:CreateTexture(nil,"BACKGROUND")
    tab.bg:SetAllPoints()
    tab.bg:SetColorTexture(0.08,0.08,0.08,0.95)

    tab.line=tab:CreateTexture(nil,"ARTWORK")
    tab.line:SetPoint("BOTTOMLEFT",0,0)
    tab.line:SetPoint("BOTTOMRIGHT",0,0)
    tab.line:SetHeight(1)
    tab.line:SetColorTexture(0.75,0.55,0.10,1)

    tab.label=tab:CreateFontString(nil,"OVERLAY","GameFontNormal")
    tab.label:SetPoint("CENTER")
    tab.label:SetText(label)
    tabs[#tabs+1]=tab
    return tab
end

-- Two-row navigation: keeps localized tab labels readable as the addon grows.
local overviewButton=CreateTab(T("Overview"),14)
local levelsButton=CreateTab(T("Level-Ups"),126)
local journalTab=CreateTab(T("Journal"),238)
local goldTab=CreateTab(T("Gold"),350)
local dungeonTab=CreateTab(T("Dungeons"),462)

local professionsTab=CreateTab(T("Professions"),14)
local reputationTab=CreateTab(T("Reputation"),158)
local charactersTab=CreateTab(T("Characters"),302)
local screenshotTab=CreateTab(T("Screenshots"),446)
local achievementsTab=CreateTab(T("Achievements tab"),590)
local iconicTab=CreateTab("Ikonische Momente",692)

for _,tab in ipairs(tabs) do tab:SetWidth(108) end
achievementsTab:SetWidth(96)
iconicTab:ClearAllPoints(); iconicTab:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-92); iconicTab:SetWidth(160)
for _,tab in ipairs({professionsTab,reputationTab,charactersTab,screenshotTab}) do
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT",frame,"TOPLEFT",tab==professionsTab and 14 or tab==reputationTab and 158 or tab==charactersTab and 302 or 446,-64)
    tab:SetWidth(138)
end
for _,tab in ipairs({overviewButton,levelsButton,journalTab,goldTab,dungeonTab}) do
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT",frame,"TOPLEFT",tab==overviewButton and 14 or tab==levelsButton and 126 or tab==journalTab and 238 or tab==goldTab and 350 or 462,-36)
end

-- Visual-only Forever-inspired navigation.  The classic tabs remain intact
-- and can be restored immediately with the toggle below.
local modernLayout = true
local classicPositions = {}
for _, t in ipairs(tabs) do
    local point, relative, relativePoint, x, y = t:GetPoint(1)
    classicPositions[t] = {point, relative, relativePoint, x, y, t:GetWidth(), t:GetHeight()}
end
local sidebar = CreateFrame("Frame",nil,frame,"BackdropTemplate")
sidebar:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-66)
sidebar:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",12,17)
sidebar:SetWidth(204)
sidebar:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=3,right=3,top=3,bottom=3}})
sidebar:SetBackdropColor(0.10,0.075,0.055,0.97)
sidebar:SetBackdropBorderColor(0.49,0.34,0.17,1)
-- Scroll the navigation if many account characters cannot fit within 75% of screen height.
local sidebarScroll=CreateFrame("ScrollFrame",nil,sidebar)
sidebarScroll:SetPoint("TOPLEFT",sidebar,"TOPLEFT",3,-4)
sidebarScroll:SetPoint("BOTTOMRIGHT",sidebar,"BOTTOMRIGHT",-3,4)
local navHost=CreateFrame("Frame",nil,sidebarScroll)
navHost:SetSize(198,500)
sidebarScroll:SetScrollChild(navHost)
sidebarScroll:EnableMouseWheel(true)
sidebarScroll:SetScript("OnMouseWheel",function(self,delta)
    -- Whole numbers only: a fractional scroll offset makes the 1 px separator lines of some rows vanish.
    local maxScroll=math.max(0,math.floor(navHost:GetHeight()-self:GetHeight()))
    self:SetVerticalScroll(math.floor(math.max(0,math.min(maxScroll,self:GetVerticalScroll()-delta*45))+0.5))
end)
local navigationGroups = {
    {"Nav group chronicle", {overviewButton,levelsButton,journalTab,screenshotTab}},
    {"Nav group progress", {goldTab,professionsTab,reputationTab}},
    {"Nav group adventure", {dungeonTab,achievementsTab,iconicTab}},
    {"Nav group characters", {charactersTab}},
}
local groupHeaders = {}
local characterNavButtons = {}
local selectedAccountCharacter = nil
local UpdateNavigation
local collapsed = {}
-- The window always opens at its default size; the navigation scrolls when there are many characters.
local layoutToggle = CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
layoutToggle:SetSize(130,20)
layoutToggle:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-38,-34)
layoutToggle:Hide() -- The Forever navigation is now the only visible layout.
UpdateNavigation = function()
    sidebar:SetShown(modernLayout)
    if modernLayout then
        -- Never force a larger width here: this runs on every navigation refresh.
        local y = -12
        for groupIndex, group in ipairs(navigationGroups) do
            local header = groupHeaders[groupIndex]
            header:ClearAllPoints(); header:SetPoint("TOPLEFT",navHost,"TOPLEFT",5,y)
            header:SetText((collapsed[groupIndex] and "+  " or "-  ")..T(group[1]))
            header:Show(); y=y-29
            for _,tab in ipairs(group[2]) do
                if (tab==achievementsTab and MCF.AchievementsEnabled and not MCF:AchievementsEnabled())
                    or (tab==iconicTab and MCF.IconicEnabled and not MCF:IconicEnabled()) then tab:Hide() else
                tab:ClearAllPoints()
                tab:SetParent(navHost)
                tab:SetSize(180,27)
                if tab==charactersTab then tab.label:SetText((MCF:GetLanguage()=="deDE" or MCF:GetLanguage()=="de") and "Accountübersicht" or "Account overview") end
                tab:SetPoint("TOPLEFT",navHost,"TOPLEFT",13,y)
                tab:SetShown(not collapsed[groupIndex])
                y=y-(collapsed[groupIndex] and 0 or 29)
                end
            end
            if groupIndex==4 and not collapsed[groupIndex] then
                local characters=MCF.GetAccountCharacters and MCF:GetAccountCharacters() or {}
                for ci,ch in ipairs(characters) do
                    local b=characterNavButtons[ci]
                    if not b then
                        b=CreateFrame("Button",nil,navHost)
                        b:SetSize(180,27)
                        b.bg=b:CreateTexture(nil,"BACKGROUND")
                        b.bg:SetAllPoints()
                        b.line=b:CreateTexture(nil,"ARTWORK")
                        b.line:SetPoint("BOTTOMLEFT",0,0)
                        b.line:SetPoint("BOTTOMRIGHT",0,0)
                        b.line:SetColorTexture(0.75,0.55,0.10,1)
                        if b.line.SetSnapToPixelGrid then b.line:SetSnapToPixelGrid(true) end; if b.line.SetTexelSnappingBias then b.line:SetTexelSnappingBias(0) end -- keep the thin line at least one pixel
                        local fs=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
                        fs:SetPoint("CENTER"); fs:SetJustifyH("CENTER"); b:SetFontString(fs)
                        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
                        characterNavButtons[ci]=b
                    end
                    local key=ch.key or ((ch.realm or "?").."::"..(ch.name or "?"))
                    local active=(viewMode=="characters" and selectedAccountCharacter==key)
                    b:ClearAllPoints(); b:SetPoint("TOPLEFT",navHost,"TOPLEFT",13,y)
                    b.bg:SetColorTexture(active and 0.18 or 0.08,active and 0.14 or 0.08,active and 0.05 or 0.08,0.98)
                    b.line:SetHeight(active and 3 or 1)
                    b:GetFontString():SetTextColor(active and 1 or 0.75,active and 0.82 or 0.75,active and 0.20 or 0.75)
                    b:SetText(ch.name or "?")
                    b:SetScript("OnClick",function()
                        selectedAccountCharacter=key
                        viewMode="characters"
                        UpdateNavigation()
                        MCF:RefreshUI()
                    end)
                    b:Show(); y=y-29
                end
                for ci=#characters+1,#characterNavButtons do characterNavButtons[ci]:Hide() end
            else
                for _,b in ipairs(characterNavButtons) do b:Hide() end
            end
            y=y-8
        end
        navHost:SetHeight(math.max(1,-y+12))
        local maxScroll=math.max(0,math.floor(navHost:GetHeight()-sidebarScroll:GetHeight()))
        local cur=sidebarScroll:GetVerticalScroll()
        if cur>maxScroll then sidebarScroll:SetVerticalScroll(maxScroll)
        elseif cur~=math.floor(cur) then sidebarScroll:SetVerticalScroll(math.floor(cur)) end -- no fractional offset (see mouse wheel)
        layoutToggle:Hide()
    else
        frame:SetWidth(math.min(frame:GetWidth(),700))
        ClampWindowSize()
        for _,b in ipairs(characterNavButtons) do b:Hide() end
        for _,header in ipairs(groupHeaders) do header:Hide() end
        for _,tab in ipairs(tabs) do
            local pos=classicPositions[tab]
            tab:SetParent(frame)
            if tab==charactersTab then tab.label:SetText(T("Characters")) end
            tab:ClearAllPoints()
            tab:SetPoint(pos[1],pos[2],pos[3],pos[4],pos[5])
            tab:SetSize(pos[6],pos[7])
            tab:Show()
        end
        layoutToggle:Hide()
    end
end
for i,group in ipairs(navigationGroups) do
    local header=CreateFrame("Button",nil,navHost,"BackdropTemplate")
    header:SetSize(188,26)
    header:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=9})
    header:SetBackdropColor(0.20,0.13,0.065,0.96)
    header:SetBackdropBorderColor(0.42,0.29,0.13,0.9)
    local label=header:CreateFontString(nil,"OVERLAY","GameFontNormal")
    label:SetPoint("LEFT",8,0)
    header:SetFontString(label)
    header:SetScript("OnClick",function() collapsed[i]=not collapsed[i]; UpdateNavigation() end)
    groupHeaders[i]=header
end
layoutToggle:SetScript("OnClick",function()
    modernLayout=not modernLayout
    if modernLayout then frame:SetWidth(math.min(WindowLimits(),910)) end
    ClampWindowSize()
    UpdateNavigation()
end)
UpdateNavigation()
local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",230,-68); scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-60,18)
-- Bottom inset of the content area: the overview has two buttons in the window's bottom right corner, so its
-- content must end above them (frame.SetContentBottom, called from RefreshUI).
-- (kept on the frame: this file is at Lua's limit of 200 locals per chunk)
frame.contentInsets={normal=18,withButtons=52}
frame.contentBottom=frame.contentInsets.normal
local function UpdateContentAnchor()
    scroll:ClearAllPoints()
    if modernLayout then
        scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",230,-68)
    else
        scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-102)
    end
    scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-60,frame.contentBottom)
end
function frame.SetContentBottom(withButtons)
    local v=withButtons and frame.contentInsets.withButtons or frame.contentInsets.normal
    if frame.contentBottom~=v then frame.contentBottom=v; UpdateContentAnchor() end
end
layoutToggle:HookScript("OnClick",UpdateContentAnchor)
local child=CreateFrame("Frame",nil,scroll); child:SetSize(590,1000); scroll:SetScrollChild(child)
local function UpdateContentWidth()
    local w=math.max(590,(scroll:GetWidth() or 630)-28)
    child:SetWidth(w)
end
scroll:SetScript("OnSizeChanged",function() UpdateContentWidth() end)
local text=child:CreateFontString(nil,"OVERLAY","GameFontNormal")
text:SetPoint("TOPLEFT",8,-5); text:SetWidth(570); text:SetJustifyH("LEFT"); text:SetJustifyV("TOP")
-- Character name in the overview: big and gold, with the round addon logo at the top right.
local overviewName=child:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
overviewName:SetFontObject(_G.GameFontNormalHuge or GameFontNormalLarge)
overviewName:SetPoint("TOPLEFT",8,-6)
overviewName:SetWidth(520)
overviewName:SetJustifyH("LEFT")
overviewName:SetTextColor(1,0.82,0)
overviewName:Hide()
local overviewLogo=child:CreateTexture(nil,"ARTWORK")
overviewLogo:SetTexture(MCF.LOGO_PATH)
overviewLogo:SetSize(52,52); overviewLogo:SetPoint("TOPRIGHT",child,"TOPRIGHT",-8,-2)
overviewLogo:Hide()

local overviewRight=child:CreateFontString(nil,"OVERLAY","GameFontNormal")
overviewRight:SetPoint("TOPLEFT",325,-5); overviewRight:SetWidth(420); overviewRight:SetJustifyH("LEFT"); overviewRight:SetJustifyV("TOP")
overviewRight:Hide()

-- Invisible hover rows for the overview. They make every statistic explain itself
-- without changing the compact two-column layout.
local overviewTipFrames={}
MCF.tipPool={}
local overviewTipSerial=0
local function ClearOverviewTips()
    overviewTipSerial=overviewTipSerial+1
    for _,f in ipairs(overviewTipFrames) do f:Hide(); f._hover=false; MCF.tipPool[#MCF.tipPool+1]=f end -- reused, not recreated
    wipe(overviewTipFrames)
    GameTooltip:Hide()
end
local function AddOverviewTip(column,lineIndex,lineHeight,tipKey)
    if not tipKey then return end
    local pooled=table.remove(MCF.tipPool)
    local f=pooled or CreateFrame("Frame",nil,child)
    f:SetParent(child); f:ClearAllPoints(); f:Show()
    f:SetFrameLevel(child:GetFrameLevel()+20)
    f:EnableMouse(true)
    f:SetSize(column=="left" and 285 or 255,lineHeight)
    -- Anchor to the exact top of the FontString. lineHeight is calculated from
    -- the rendered string height, so the hit boxes stay aligned with WoW's font.
    f:SetPoint("TOPLEFT",column=="left" and 8 or 325,-35-((lineIndex-1)*lineHeight))
    f.tipKey=tipKey
    if not pooled then
        f:SetScript("OnEnter",function(self)
            self._hover=true
            overviewTipSerial=overviewTipSerial+1
            local serial=overviewTipSerial
            C_Timer.After(1.0,function()
                if self._hover and self:IsShown() and serial==overviewTipSerial then
                    GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
                    GameTooltip:SetText(T(self.tipKey),1,1,1)
                    GameTooltip:Show()
                end
            end)
        end)
        f:SetScript("OnLeave",function(self)
            self._hover=false
            overviewTipSerial=overviewTipSerial+1
            GameTooltip:Hide()
        end)
    end
    overviewTipFrames[#overviewTipFrames+1]=f
end

local overviewTipByPrefix={
    ["First tracked: "]="Tip First tracked", ["Total /played: "]="Tip Total played",
    ["AFK time: "]="Tip AFK", ["Stationary time: "]="Tip Stationary", ["Longest stationary stretch: "]="Tip Longest stationary", ["Active play time: "]="Tip Active play",
    ["Current session: "]="Tip Current session", ["Time this level: "]="Tip Time level",
    ["Tracked sessions: "]="Tip Sessions", ["Average session: "]="Tip Average session",
    ["Journey points: "]="Tip Journey points", ["Maps with recorded movement: "]="Tip Maps movement",
    ["Zone changes: "]="Tip Zone changes", ["Map path: "]="Tip Map path",
    ["Timeline events: "]="Tip Timeline", ["Journal entries: "]="Tip Journal entries",
    ["Screenshot records: "]="Tip Screenshot records", ["Level snapshots: "]="Tip Level snapshots",
    ["Journey tracking: "]="Tip Journey tracking", ["Level-up screenshots: "]="Tip Level screenshots",
    ["Database version: "]="Tip Database version", ["Addon version: "]="Tip Addon version",
    ["Level-ups tracked: "]="Tip Levelups", ["Completed level records: "]="Tip Completed levels",
    ["Average time / completed level: "]="Tip Average level", ["Longest tracked level: "]="Tip Longest level",
    ["Deaths: "]="Tip Deaths", ["Duels: "]="Tip Duels", ["Ground distance: "]="Tip Ground distance",
    ["Flight routes: "]="Tip Flight routes", ["Flight distance: "]="Tip Flight distance",
    ["Flight time: "]="Tip Flight time", ["Dungeon visits: "]="Tip Dungeon visits",
    ["Dungeon completions detected: "]="Tip Dungeon completions", ["Deaths / played hour: "]="Tip Death rate",
    ["Current money: "]="Tip Money", ["Current zone: "]="Tip Current zone",
    ["Current subzone: "]="Tip Current subzone", ["World: "]="Tip World time",
    ["Resting areas: "]="Tip Resting time", ["Dungeons: "]="Tip Dungeon time",
    ["Raids: "]="Tip Raid time", ["PvP instances: "]="Tip PvP time",
}
local function FindOverviewTip(line)
    for prefix,key in pairs(overviewTipByPrefix) do
        local localized=T(prefix)
        if line:sub(1,#localized)==localized then return key end
    end
end
local function BuildOverviewTips(leftText,rightText)
    ClearOverviewTips()
    local function addColumn(txt,col,fontString)
        local lines={}
        for line in (txt.."\n"):gmatch("(.-)\n") do lines[#lines+1]=line end
        local rendered=fontString:GetStringHeight() or 0
        local lineHeight=(#lines>0 and rendered>0) and (rendered/#lines) or 14
        -- Keep the hit area usable, but do not let it drift away from rendered lines.
        if lineHeight<10 then lineHeight=10 end
        for i,line in ipairs(lines) do
            local plain=line:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
            AddOverviewTip(col,i,lineHeight,FindOverviewTip(plain))
        end
    end
    addColumn(leftText or "","left",text)
    addColumn(rightText or "","right",overviewRight)
end

local overviewSettings=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
overviewSettings:SetSize(120,24)
overviewSettings:SetPoint("BOTTOMRIGHT",-84,18)
overviewSettings:SetText(T("Settings"))
overviewSettings:SetScript("OnClick",function()
    if MCF.OpenAddonSettings then MCF:OpenAddonSettings() end
end)
overviewSettings:Hide()

local overviewExport=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
overviewExport:SetSize(120,24)
overviewExport:SetPoint("RIGHT",overviewSettings,"LEFT",-8,0)
overviewExport:SetText(T("Export chronicle"))
overviewExport:SetScript("OnClick",function()
    if MCF and type(MCF.ShowExport)=="function" then
        MCF:ShowExport()
    else
        print("|cffff4040MyCharForever:|r Export-Funktion ist nicht geladen.")
    end
end)
overviewExport:Hide()

-- Hint to the website (photo book view); attached to the frame to spare a local.
frame.websiteButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
frame.websiteButton:SetSize(100,24)
frame.websiteButton:SetPoint("RIGHT",overviewExport,"LEFT",-8,0)
frame.portraitButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
frame.portraitButton:SetSize(110,24)
frame.portraitButton:SetPoint("RIGHT",frame.websiteButton,"LEFT",-8,0)
frame.portraitButton:SetScript("OnClick",function() if MCF.ShowPortraitWindow then MCF:ShowPortraitWindow() end end)
frame.portraitButton:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:AddLine(MCF:GetLanguage()=="deDE" and "Porträt für die Webseite" or "Portrait for the website",1,0.82,0.1)
    GameTooltip:AddLine(MCF:GetLanguage()=="deDE" and "Nimmt automatisch einen Screenshot deines Kopfes auf. Die Webseite zeigt ihn als rundes Porträt." or "Automatically takes a screenshot of your head. The website shows it as a round portrait.",1,1,1,true); GameTooltip:Show()
end)
frame.portraitButton:SetScript("OnLeave",function() GameTooltip:Hide() end)
frame.portraitButton:Hide()
frame.websiteButton:SetText("Website")
frame.websiteButton:SetScript("OnClick",function() if MCF.ShowWebsite then MCF:ShowWebsite() end end)
frame.websiteButton:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:AddLine("MyCharForever",1,0.82,0.1)
    GameTooltip:AddLine(MCF:GetWebsiteText(),1,1,1,true); GameTooltip:Show()
end)
frame.websiteButton:SetScript("OnLeave",function() GameTooltip:Hide() end)
frame.websiteButton:Hide()

local journalLayer=CreateFrame("Frame",nil,child)
journalLayer:SetAllPoints(child)
journalLayer:SetFrameLevel(child:GetFrameLevel()+10)
journalLayer:Hide()

local screenshotLayer=CreateFrame("Frame",nil,child)
screenshotLayer:SetAllPoints(child); screenshotLayer:SetFrameLevel(child:GetFrameLevel()+11); screenshotLayer:Hide()
local screenshotCards={}
local screenshotSearchText=""
local screenshotSearchBox
local function ClearScreenshotCards()
    for _,card in ipairs(screenshotCards) do MCF.Retire(card) end
    wipe(screenshotCards)
end
-- Screenshot tab: "Manual" (taken by the player) and "Automatic" (taken by the addon, filterable by type).
-- Shots.group is the one place that maps a stored reason to a tab / filter group.
local Shots={}   -- one local for the whole tab state (the chunk is close to Lua's 200-locals limit)
Shots.groups={
    {key="levelup",label="Level-Up"},{key="login",label="Login"},{key="interval",label="Shot interval"},
    {key="death",label="Death"},{key="dungeon",label="Shot dungeon"},{key="achievement",label="Shot achievement"},
    {key="iconic",label="Iconic moments"},{key="equip",label="Shot equipment"},
    {key="guild",label="Shot guild"},{key="pvp",label="PvP"},{key="other",label="Shot other"},
}
-- Shots.group is the one place that maps a stored reason to a tab / filter group.
function Shots.group(shot)
    local r=shot and shot.reason or ""
    if r=="MANUAL_CHRONICLE" or r=="GAME" or (shot and shot.manual) then return "manual" end
    if r=="LEVEL_UP" or r=="LEVELUP" then return "levelup" end
    if r=="LOGIN" then return "login" end
    if r=="PERIODIC" then return "interval" end
    if r=="DEATH" or r=="FIRST_DEATH" or r=="COMEBACK" then return "death" end
    if r=="DUNGEON_COMPLETE" then return "dungeon" end
    if r=="ACHIEVEMENT" then return "achievement" end
    if r:sub(1,7)=="ICONIC_" or r=="ROLL_ONE" or r=="ROLL_HUNDRED" then return "iconic" end
    if r:sub(1,6)=="EQUIP_" then return "equip" end
    if r:sub(1,6)=="GUILD_" then return "guild" end
    if r:sub(1,4)=="PVP_" then return "pvp" end
    return "other"
end
Shots.mode="manual"      -- "manual" | "auto"
Shots.filter="ALL"       -- "ALL" or a Shots.groups key
function Shots.filterLabel()
    if Shots.filter=="ALL" then return T("Shot all types") end
    for _,g in ipairs(Shots.groups) do if g.key==Shots.filter then return T(g.label) end end
    return T("Shot all types")
end
-- The global search looks at everything a card shows: comment, place, file name and type.
function Shots.matches(shot,q)
    if q=="" then return true end
    local hay=table.concat({shot.comment or "",shot.zone or "",shot.subZone or "",shot.expectedFileName or "",ScreenshotTypeLabel(shot) or ""}," "):lower()
    return hay:find(q,1,true)~=nil
end
-- A real tab: flat dark button, the active one is lit with a thick gold line (same look as the window tabs).
function Shots.tab(parent,text,x,y,active,onClick)
    local tab=CreateFrame("Button",nil,parent)
    tab:SetSize(235,28); tab:SetPoint("TOPLEFT",x,y)
    local bg=tab:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints()
    local line=tab:CreateTexture(nil,"ARTWORK"); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")
    local label=tab:CreateFontString(nil,"OVERLAY",active and "GameFontHighlight" or "GameFontNormal"); label:SetPoint("CENTER"); label:SetText(text)
    if active then
        bg:SetColorTexture(0.22,0.15,0.04,0.98); line:SetHeight(3); line:SetColorTexture(1,0.82,0.2,1)
    else
        bg:SetColorTexture(0.08,0.08,0.08,0.95); line:SetHeight(1); line:SetColorTexture(0.75,0.55,0.10,1)
        tab:SetScript("OnEnter",function() bg:SetColorTexture(0.14,0.11,0.06,0.98) end)
        tab:SetScript("OnLeave",function() bg:SetColorTexture(0.08,0.08,0.08,0.95) end)
    end
    tab:SetScript("OnClick",onClick)
    return tab
end
local function DrawScreenshotCards(db)
    ClearScreenshotCards()
    if Shots.dropdown then Shots.dropdown:Hide() end
    local auto=(Shots.mode=="auto")
    local q=(screenshotSearchText or ""):lower()
    local counts={manual=0,auto=0}
    local shots={}
    for _,shot in ipairs(db.screenshots or {}) do
        if Shots.matches(shot,q) then
            local g=Shots.group(shot)
            local tabName=(g=="manual") and "manual" or "auto"
            counts[tabName]=counts[tabName]+1
            if auto then
                if tabName=="auto" and (Shots.filter=="ALL" or Shots.filter==g) then shots[#shots+1]=shot end
            elseif tabName=="manual" then shots[#shots+1]=shot end
        end
    end
    local y=-5
    -- 1. general introduction
    local info=screenshotLayer:CreateFontString(nil,"OVERLAY","MyCharForeverDescriptionFont")
    info:SetPoint("TOPLEFT",8,y); info:SetWidth(540); info:SetJustifyH("LEFT"); info:SetText(T("Screenshot intro"))
    screenshotCards[#screenshotCards+1]=info
    y=y-math.max(36,math.ceil(info:GetStringHeight()))-10
    -- 2. shortcut
    local shortcut=screenshotLayer:CreateFontString(nil,"OVERLAY","GameFontNormal")
    shortcut:SetPoint("TOPLEFT",8,y); shortcut:SetWidth(475); shortcut:SetJustifyH("LEFT")
    local bound=MCF.GetChronicleScreenshotBinding and MCF:GetChronicleScreenshotBinding() or nil
    local shown=MCF.FormatBindingKey and MCF:FormatBindingKey(bound) or (bound or T("Not assigned"))
    shortcut:SetText(T("Screenshot shortcut")..": |cffffffff"..shown.."|r")
    screenshotCards[#screenshotCards+1]=shortcut
    local scHint=MCF.Kit.Hint.Button(screenshotLayer); scHint:SetPoint("LEFT",shortcut,"LEFT",shortcut:GetStringWidth()+8,0)
    screenshotCards[#screenshotCards+1]=scHint
    y=y-math.ceil(shortcut:GetStringHeight())-14
    -- 3. global search (applies to everything below)
    local searchLabel=screenshotLayer:CreateFontString(nil,"OVERLAY","GameFontNormal")
    searchLabel:SetPoint("TOPLEFT",8,y); searchLabel:SetText(T("Search screenshots"))
    screenshotCards[#screenshotCards+1]=searchLabel
    y=y-math.ceil(searchLabel:GetStringHeight())-6
    screenshotSearchBox=CreateFrame("EditBox",nil,screenshotLayer,"InputBoxTemplate")
    screenshotSearchBox:SetSize(300,24); screenshotSearchBox:SetPoint("TOPLEFT",14,y)
    screenshotSearchBox:SetAutoFocus(false); screenshotSearchBox:SetText(screenshotSearchText or "")
    screenshotSearchBox:SetScript("OnTextChanged",function(self,userInput)
        if not userInput then return end
        screenshotSearchText=self:GetText() or ""
        MCF:RefreshUI()
    end)
    screenshotCards[#screenshotCards+1]=screenshotSearchBox
    local clear=CreateFrame("Button",nil,screenshotLayer,"UIPanelButtonTemplate")
    clear:SetSize(80,24); clear:SetPoint("LEFT",screenshotSearchBox,"RIGHT",12,0); clear:SetText(T("Clear"))
    clear:SetScript("OnClick",function() screenshotSearchText=""; MCF:RefreshUI() end)
    screenshotCards[#screenshotCards+1]=clear
    y=y-24-16
    -- 4. the two tabs
    screenshotCards[#screenshotCards+1]=Shots.tab(screenshotLayer,T("Shot tab manual").." ("..counts.manual..")",8,y,not auto,function() Shots.mode="manual"; MCF:RefreshUI() end)
    screenshotCards[#screenshotCards+1]=Shots.tab(screenshotLayer,T("Shot tab automatic").." ("..counts.auto..")",247,y,auto,function() Shots.mode="auto"; MCF:RefreshUI() end)
    y=y-28-8
    -- 5. short description of this tab
    local desc=screenshotLayer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT",8,y); desc:SetWidth(540); desc:SetJustifyH("LEFT"); desc:SetTextColor(0.75,0.75,0.75)
    desc:SetText(T(auto and "Automatic screenshot info" or "Manual screenshot info"))
    screenshotCards[#screenshotCards+1]=desc
    y=y-math.ceil(desc:GetStringHeight())-10
    -- 6. type filter (automatic tab only)
    if auto then
        local typeLabel=screenshotLayer:CreateFontString(nil,"OVERLAY","GameFontNormal")
        typeLabel:SetPoint("TOPLEFT",8,y-4); typeLabel:SetText(T("Shot type").."  ")
        screenshotCards[#screenshotCards+1]=typeLabel
        if not Shots.dropdown then
            Shots.dropdown=CreateFrame("Frame","MyCharForeverShotTypeDropdown",screenshotLayer,"UIDropDownMenuTemplate")
            UIDropDownMenu_SetWidth(Shots.dropdown,190)
            UIDropDownMenu_Initialize(Shots.dropdown,function(_,level)
                local function Add(key,label)
                    local i=UIDropDownMenu_CreateInfo()
                    i.text=label; i.checked=(Shots.filter==key)
                    i.func=function() Shots.filter=key; MCF:RefreshUI() end
                    UIDropDownMenu_AddButton(i,level)
                end
                Add("ALL",T("Shot all types"))
                for _,g in ipairs(Shots.groups) do Add(g.key,T(g.label)) end
            end)
        end
        Shots.dropdown:ClearAllPoints()
        Shots.dropdown:SetPoint("LEFT",typeLabel,"RIGHT",-14,-2)
        UIDropDownMenu_SetText(Shots.dropdown,Shots.filterLabel())
        Shots.dropdown:Show()
        y=y-40
    end
    if #shots==0 then
        local fs=screenshotLayer:CreateFontString(nil,"OVERLAY","GameFontNormal")
        fs:SetPoint("TOPLEFT",8,y); fs:SetText(T(q~="" and "No screenshots found." or "No screenshots recorded yet.")); screenshotCards[#screenshotCards+1]=fs
        return math.abs(y)+60
    end
    for i=1,#shots do
        local shot=shots[#shots+1-i]
        local card=CreateFrame("Frame",nil,screenshotLayer,"InsetFrameTemplate")
        card:SetSize(555,104); card:SetPoint("TOPLEFT",8,y)
        -- The file name is a read-only edit box: click it, then Ctrl+C copies the name (to find the file or paste it elsewhere).
        local fileName=shot.expectedFileName or T("Screenshot")
        local title=CreateFrame("EditBox",nil,card)
        title:SetPoint("TOPLEFT",12,-8); title:SetSize(525,20); title:SetAutoFocus(false); title:SetMaxLetters(0)
        title:SetFontObject(GameFontNormal); title:SetTextColor(1,1,1); title:SetJustifyH("LEFT")
        title:SetText(fileName); title:SetCursorPosition(0)
        title:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
        title:SetScript("OnEditFocusLost",function(self) self:HighlightText(0,0) end)
        title:SetScript("OnTextChanged",function(self) if self:GetText()~=fileName then self:SetText(fileName); self:HighlightText() end end)
        title:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        title:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
        local meta=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); meta:SetPoint("TOPLEFT",12,-32); meta:SetWidth(525); meta:SetJustifyH("LEFT")
        local place=(shot.zone or "?")..((shot.subZone and shot.subZone~="") and (" - "..shot.subZone) or "")
        meta:SetText(date("%d.%m.%Y %H:%M",shot.time or time()).."  |  "..T("Level").." "..tostring(shot.level or "?").."  |  "..place)
        local comment=card:CreateFontString(nil,"OVERLAY","GameFontNormal"); comment:SetPoint("TOPLEFT",12,-55); comment:SetWidth(525); comment:SetJustifyH("LEFT")
        if auto then
            comment:SetText(ScreenshotTypeLabel(shot))   -- automatic shots have no comment: show what triggered them
        else
            comment:SetText((shot.comment and shot.comment~="") and ("|cffdddddd"..shot.comment.."|r") or ("|cff777777"..T("No comment").."|r"))
        end
        local cardHint=MCF.Kit.Hint.Button(card,true); cardHint:SetPoint("TOPRIGHT",card,"TOPRIGHT",-6,-8)
        screenshotCards[#screenshotCards+1]=card; y=y-112
    end
    return math.abs(y)+20
end

local fmtDate

local journalCards={}
local journalSearchText=""
local journalSearchBox
local function ClearJournalCards()
    for _,card in ipairs(journalCards) do MCF.Retire(card) end
    wipe(journalCards)
end

local journalCalendarMonth,journalCalendarYear,journalSelectedDate
local journalCalendarRows={}
local function ClearJournalCalendar()
    ClearJournalCards()
    for _,r in ipairs(journalCalendarRows) do if r.Hide then r:Hide() end end
    wipe(journalCalendarRows)
end
local function DateKey(ts) return ts and date("%Y-%m-%d",ts) or nil end
local function DaysInMonth(y,m)
    local nm=m+1; local ny=y
    if nm==13 then nm=1; ny=y+1 end
    return tonumber(date("%d",time{year=ny,month=nm,day=1,hour=12}-86400))
end
local function DrawJournalCards(db)
    ClearJournalCalendar()
    local entries=db.journal or {}
    local query=(journalSearchText or ""):lower()
    local filtered={}
    for i,e in ipairs(entries) do
        local haystack=table.concat({tostring(e.title or ""),tostring(e.text or ""),tostring(e.zone or ""),tostring(e.subZone or ""),tostring(e.level or "")}," "):lower()
        if query=="" or haystack:find(query,1,true) then filtered[#filtered+1]={entry=e,index=i} end
    end
    if query~="" then
        local y=-82
        for j=#filtered,1,-1 do
            local e=filtered[j].entry; local i=filtered[j].index
            local card=CreateFrame("Frame",nil,journalLayer,"BackdropTemplate"); card:SetSize(555,118); card:SetPoint("TOPLEFT",8,y)
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}}); card:SetBackdropColor(.04,.04,.04,.72)
            local title=card:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",12,-10); title:SetText(e.title or (T("Journal Entry ")..i))
            local meta=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); meta:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-4); meta:SetText(fmtDate(e.time).." | "..T("Level").." "..tostring(e.level or "?").." | "..tostring(e.zone or ""))
            local body=card:CreateFontString(nil,"OVERLAY","GameFontHighlight"); body:SetPoint("TOPLEFT",meta,"BOTTOMLEFT",0,-8); body:SetWidth(490); body:SetJustifyH("LEFT"); body:SetText((e.text or ""):sub(1,180))
            local edit=CreateFrame("Button",nil,card,"UIPanelButtonTemplate"); edit:SetSize(68,22); edit:SetPoint("TOPRIGHT",-84,-12); edit:SetText(T("Edit")); edit:SetScript("OnClick",function() MCF:OpenJournalEntry(e) end)
            local del=CreateFrame("Button",nil,card,"UIPanelButtonTemplate"); del:SetSize(68,22); del:SetPoint("TOPRIGHT",-10,-12); del:SetText(T("Delete")); del:SetScript("OnClick",function() MCF:DeleteJournalEntry(e) end)
            journalCards[#journalCards+1]=card; y=y-126
        end
        if #filtered==0 then
            local fs=journalLayer:CreateFontString(nil,"OVERLAY","GameFontNormal"); fs:SetPoint("TOPLEFT",24,-90); fs:SetText(T("No journal entries match your search.")); journalCalendarRows[#journalCalendarRows+1]=fs
        end
        return math.max(520,math.abs(y)+20)
    end

    local now=time()
    journalCalendarMonth=journalCalendarMonth or tonumber(date("%m",now))
    journalCalendarYear=journalCalendarYear or tonumber(date("%Y",now))
    local monthNames={T("January"),T("February"),T("March"),T("April"),T("May"),T("June"),T("July"),T("August"),T("September"),T("October"),T("November"),T("December")}
    local byDate={}
    local screenshotsByDate={}
    for _,shot in ipairs(db.screenshots or {}) do
        local ts=tonumber(shot.time)
        if ts then
            local skey=date("%Y-%m-%d",ts)
            screenshotsByDate[skey]=(screenshotsByDate[skey] or 0)+1
        end
    end
    for i,e in ipairs(entries) do local k=DateKey(e.time); if k then byDate[k]=byDate[k] or {}; byDate[k][#byDate[k]+1]={entry=e,index=i} end end

    local prev=CreateFrame("Button",nil,journalLayer,"UIPanelButtonTemplate"); prev:SetSize(30,22); prev:SetPoint("TOPLEFT",130,-108); prev:SetText("<")
    prev:SetScript("OnClick",function() journalCalendarMonth=journalCalendarMonth-1; if journalCalendarMonth<1 then journalCalendarMonth=12;journalCalendarYear=journalCalendarYear-1 end; MCF:RefreshUI() end); journalCalendarRows[#journalCalendarRows+1]=prev
    local nextb=CreateFrame("Button",nil,journalLayer,"UIPanelButtonTemplate"); nextb:SetSize(30,22); nextb:SetPoint("TOPLEFT",405,-108); nextb:SetText(">")
    nextb:SetScript("OnClick",function() journalCalendarMonth=journalCalendarMonth+1; if journalCalendarMonth>12 then journalCalendarMonth=1;journalCalendarYear=journalCalendarYear+1 end; MCF:RefreshUI() end); journalCalendarRows[#journalCalendarRows+1]=nextb
    local mh=journalLayer:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge"); mh:SetPoint("TOP",journalLayer,"TOP",-5,-111); mh:SetText("|cffffffff"..monthNames[journalCalendarMonth].." "..journalCalendarYear.."|r"); journalCalendarRows[#journalCalendarRows+1]=mh

    local days={T("Mon"),T("Tue"),T("Wed"),T("Thu"),T("Fri"),T("Sat"),T("Sun")}
    local x0,y0,cw,ch=20,-144,76,48
    for col=1,7 do local fs=journalLayer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fs:SetPoint("TOPLEFT",x0+(col-1)*cw,y0); fs:SetWidth(cw); fs:SetJustifyH("CENTER"); fs:SetText("|cffffffff"..days[col].."|r"); journalCalendarRows[#journalCalendarRows+1]=fs end
    local first=time{year=journalCalendarYear,month=journalCalendarMonth,day=1,hour=12}
    local wd=tonumber(date("%w",first)); local mondayIndex=(wd==0) and 7 or wd
    local dim=DaysInMonth(journalCalendarYear,journalCalendarMonth)
    for d=1,dim do
        local slot=(mondayIndex-1)+(d-1); local row=math.floor(slot/7); local col=slot%7
        local key=string.format("%04d-%02d-%02d",journalCalendarYear,journalCalendarMonth,d)
        local count=byDate[key] and #byDate[key] or 0
        local screenshotCount=screenshotsByDate[key] or 0
        local b=CreateFrame("Button",nil,journalLayer,"BackdropTemplate"); b:SetSize(cw-4,ch-4); b:SetPoint("TOPLEFT",x0+col*cw,y0-20-row*ch)
        b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        b:SetBackdropColor(journalSelectedDate==key and .20 or .04,journalSelectedDate==key and .16 or .04,.02,.80)
        local n=b:CreateFontString(nil,"OVERLAY","GameFontHighlight"); n:SetPoint("TOPLEFT",7,-6); n:SetText("|cffffffff"..tostring(d).."|r")
        local function AddCalendarIcon(texturePath,countValue,point,relPoint,x,y,size)
            local icon=b:CreateTexture(nil,"ARTWORK")
            icon:SetSize(size,size); icon:SetPoint(point,b,relPoint,x,y)
            icon:SetTexture(texturePath); icon:SetTexCoord(0,1,0,1)
            if countValue>1 then
                local badge=CreateFrame("Frame",nil,b,"BackdropTemplate")
                badge:SetSize(15,15); badge:SetPoint("CENTER",icon,"TOPRIGHT",-1,-1)
                badge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
                badge:SetBackdropColor(0,0,0,.95); badge:SetBackdropBorderColor(.85,.68,.15,1)
                local num=badge:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
                num:SetPoint("CENTER",0,0); num:SetText("|cffffffff"..tostring(countValue).."|r")
            end
        end
        if count>0 then
            AddCalendarIcon(MCF.MarkerTexture("Journal"),count,"BOTTOMLEFT","BOTTOMLEFT",7,5,23)
        end
        if screenshotCount>0 then
            AddCalendarIcon(MCF.MarkerTexture("Screenshot"),screenshotCount,"BOTTOMRIGHT","BOTTOMRIGHT",-7,5,23)
        end
        b:SetScript("OnClick",function() journalSelectedDate=key; MCF:RefreshUI() end)
        b:SetScript("OnEnter",function(self)
            if count>0 or screenshotCount>0 then
                GameTooltip:SetOwner(self,"ANCHOR_CURSOR"); GameTooltip:SetText(key,1,1,1)
                if count>0 then GameTooltip:AddLine(tostring(count).." "..T("journal entries"),1,.82,0) end
                if screenshotCount>0 then GameTooltip:AddLine(tostring(screenshotCount).." "..T("screenshots"),1,1,1) end
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        journalCalendarRows[#journalCalendarRows+1]=b
    end
    local rows=math.ceil(((mondayIndex-1)+dim)/7)
    local detailY=y0-28-rows*ch-12
    local chosen=journalSelectedDate and byDate[journalSelectedDate] or nil
    local chosenShots={}
    if journalSelectedDate then
        for _,ss in ipairs(db.screenshots or {}) do
            if DateKey(tonumber(ss.time))==journalSelectedDate then chosenShots[#chosenShots+1]=ss end
        end
    end
    local hasSelected=(journalSelectedDate~=nil)
    local head=journalLayer:CreateFontString(nil,"OVERLAY","GameFontNormal"); head:SetPoint("TOPLEFT",20,detailY)
    head:SetText(hasSelected and (T("Entries on").." "..journalSelectedDate) or T("Select a day with journal entries."))
    journalCalendarRows[#journalCalendarRows+1]=head
    local y=detailY-24

    if #chosenShots>0 then
        local export=CreateFrame("Button",nil,journalLayer,"UIPanelButtonTemplate")
        export:SetSize(230,22); export:SetPoint("TOPLEFT",20,y)
        export:SetText(T("Show screenshot filenames"))
        export:SetScript("OnClick",function() ShowLevelScreenshotFiles(journalSelectedDate,chosenShots) end)
        journalCalendarRows[#journalCalendarRows+1]=export
        local exHint=MCF.Kit.Hint.Button(journalLayer); exHint:SetPoint("LEFT",export,"RIGHT",6,0)
        journalCalendarRows[#journalCalendarRows+1]=exHint
        y=y-30

        y=y-8
    end

    if chosen then
        for _,wrap in ipairs(chosen) do
            local e=wrap.entry
            local card=CreateFrame("Frame",nil,journalLayer,"BackdropTemplate"); card:SetSize(530,94); card:SetPoint("TOPLEFT",20,y)
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}}); card:SetBackdropColor(.04,.04,.04,.72)
            local title=card:CreateFontString(nil,"OVERLAY","GameFontNormal"); title:SetPoint("TOPLEFT",10,-9); title:SetText(e.title or T("Journal Entry"))
            local meta=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); meta:SetPoint("TOPLEFT",10,-29); meta:SetText(date("%H:%M",e.time or time()).." | "..T("Level").." "..tostring(e.level or "?").." | "..tostring(e.zone or ""))
            local body=card:CreateFontString(nil,"OVERLAY","GameFontHighlight"); body:SetPoint("TOPLEFT",10,-48); body:SetWidth(390); body:SetJustifyH("LEFT"); body:SetText((e.text or ""):sub(1,120))
            local edit=CreateFrame("Button",nil,card,"UIPanelButtonTemplate"); edit:SetSize(60,20); edit:SetPoint("TOPRIGHT",-70,-8); edit:SetText(T("Edit")); edit:SetScript("OnClick",function() MCF:OpenJournalEntry(e) end)
            local del=CreateFrame("Button",nil,card,"UIPanelButtonTemplate"); del:SetSize(60,20); del:SetPoint("TOPRIGHT",-6,-8); del:SetText(T("Delete")); del:SetScript("OnClick",function() MCF:DeleteJournalEntry(e) end)
            journalCards[#journalCards+1]=card; y=y-100
        end
    end
    return math.max(650,math.abs(y)+30)
end

local journalVersionText=journalLayer:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
journalVersionText:SetPoint("BOTTOMRIGHT",journalLayer,"BOTTOMRIGHT",-12,10)
journalVersionText:SetText("MyCharForever v"..tostring(MCF.VERSION or "?"))
journalVersionText:SetTextColor(0.65,0.65,0.65)

local journalManualHint=journalLayer:CreateFontString(nil,"OVERLAY","MyCharForeverDescriptionFont")
journalManualHint:SetPoint("TOPLEFT",18,-6); journalManualHint:SetWidth(530); journalManualHint:SetJustifyH("LEFT"); journalManualHint:SetText(T("Journal manual only hint"))

local journalNewButton=CreateFrame("Button",nil,journalLayer,"UIPanelButtonTemplate")
journalNewButton:SetSize(150,24); journalNewButton:SetPoint("TOPRIGHT",-18,-62); journalNewButton:SetText(T("New journal entry"))
journalNewButton:SetScript("OnClick",function() if MCF.OpenJournalEntry then MCF:OpenJournalEntry(nil) end end)

journalSearchBox=CreateFrame("EditBox","MyCharForeverJournalSearchBox",journalLayer,"InputBoxTemplate")
journalSearchBox:SetSize(250,24); journalSearchBox:SetPoint("TOPLEFT",18,-62); journalSearchBox:SetAutoFocus(false); journalSearchBox:SetMaxLetters(100)
local journalSearchLabel=journalLayer:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); journalSearchLabel:SetPoint("BOTTOMLEFT",journalSearchBox,"TOPLEFT",0,2); journalSearchLabel:SetText(T("Search journal"))
local journalSearchClear=CreateFrame("Button",nil,journalLayer,"UIPanelButtonTemplate"); journalSearchClear:SetSize(70,22); journalSearchClear:SetPoint("LEFT",journalSearchBox,"RIGHT",8,0); journalSearchClear:SetText(T("Clear"))
journalSearchClear:SetScript("OnClick",function() journalSearchBox:SetText(""); journalSearchBox:ClearFocus() end)
journalSearchBox:SetScript("OnTextChanged",function(self) journalSearchText=self:GetText() or ""; if viewMode=="journal" and MyCharForeverDB then child:SetHeight(math.max(1000,DrawJournalCards(MyCharForeverDB))); MCF:ApplyFontScale() end end)
journalSearchBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end); journalSearchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)


function MCF:RefreshLocalizedUI()
    overviewButton.label:SetText(T("Overview"))
    levelsButton.label:SetText(T("Level-Ups"))
    journalTab.label:SetText(T("Journal"))
    goldTab.label:SetText(T("Gold"))
    dungeonTab.label:SetText(T("Dungeons"))
    professionsTab.label:SetText(T("Professions"))
    reputationTab.label:SetText(T("Reputation"))
    charactersTab.label:SetText(T("Characters"))
    achievementsTab.label:SetText(T("Achievements tab"))
    screenshotTab.label:SetText(T("Screenshots"))
    iconicTab.label:SetText(MCF:GetLanguage()=="deDE" and "Ikonische Momente" or "Iconic Moments")
    overviewSettings:SetText(T("Settings"))
    overviewExport:SetText(T("Export chronicle"))
    frame.portraitButton:SetText(MCF:GetLanguage()=="deDE" and "Porträt" or "Portrait")
    journalManualHint:SetText(T("Journal manual only hint"))
    journalNewButton:SetText(T("New journal entry"))
    journalSearchLabel:SetText(T("Search journal"))
    journalSearchClear:SetText(T("Clear"))
    -- (goldInfo is declared further down and gets its translated text every time the gold view is drawn)
end


local function money(copper)
    copper=math.floor(copper or 0)
    return string.format("%dg %ds %dc",math.floor(copper/10000),math.floor((copper%10000)/100),copper%100)
end


local function MCF_SetDropdownText(dropdown,text)
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dropdown,text) end
end
-- Looted gold is counted from the first level it was recorded at; older levels cannot be filled in afterwards.
function MCF.LootedSinceText()
    local by=MyCharForeverDB and MyCharForeverDB.goldLooted and MyCharForeverDB.goldLooted.byLevel
    local first
    for lvl in pairs(by or {}) do lvl=tonumber(lvl); if lvl and lvl>0 and (not first or lvl<first) then first=lvl end end
    if first and first>1 then return " ("..string.format(T("recorded since level %d"),first)..")" end
    return ""
end
local goldInfo=child:CreateFontString(nil,"OVERLAY","MyCharForeverDescriptionFont")
goldInfo:SetPoint("TOPLEFT",12,-6); goldInfo:SetWidth(560); goldInfo:SetJustifyH("LEFT")
goldInfo:SetWordWrap(true)
goldInfo:SetText(T("Gold history info")); goldInfo:Hide()

local goldChart=CreateFrame("Frame",nil,child)
goldChart:SetSize(555,315)
goldChart.textTop=100   -- y offset (downwards) of the gold balance lines; set from the description height when the gold tab is drawn
goldChart:SetPoint("TOPLEFT",8,-190)
goldChart:Hide()

local goldHistoryTextFrame=CreateFrame("Frame",nil,child)
goldHistoryTextFrame:SetSize(540,400)
goldHistoryTextFrame:SetPoint("TOPLEFT",8,-530)
goldHistoryTextFrame:Hide()
goldHistoryTextFrame.rows={}
goldHistoryTextFrame.contentHeight=40
function goldHistoryTextFrame:SetText(_) end
function goldHistoryTextFrame:GetStringHeight() return self.contentHeight or 40 end
goldChart.lines={}
goldChart.dots={}
goldChart.labels={}
goldChart.hitFrames={}
local goldRange="30D"
local goldScaleMode=T("AUTO")
local milestoneFrame
local milestoneRows={}
local DrawGoldChart


local rangeButtons={}
local function CreateRangeButton(key,x)
    local b=CreateFrame("Button",nil,goldChart,"UIPanelButtonTemplate")
    b:SetSize(52,20); b:SetPoint("TOPRIGHT",x,-2); b:SetText(T(key))
    rangeButtons[key]=b
    return b
end
CreateRangeButton("3D",-280)
CreateRangeButton("7D",-224)
CreateRangeButton("30D",-168)
CreateRangeButton("90D",-112)
CreateRangeButton("1Y",-56)
CreateRangeButton("ALL",0)

local scaleLabel=goldChart:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
scaleLabel:SetPoint("TOPLEFT",4,-32)
scaleLabel:SetText(T("Scale:"))

local scaleButton=CreateFrame("Frame","MyCharForeverGoldScaleDropdown",goldChart,"UIDropDownMenuTemplate")
scaleButton:SetPoint("LEFT",scaleLabel,"RIGHT",-10,0)
UIDropDownMenu_SetWidth(scaleButton,125)
UIDropDownMenu_SetText(scaleButton,T("AUTO"))

local manageMilestones=CreateFrame("Button",nil,goldChart,"UIPanelButtonTemplate")
manageMilestones:SetSize(185,20) -- wide enough for the German text
manageMilestones:SetPoint("LEFT",scaleButton,"RIGHT",-8,0)
manageMilestones:SetText(T("Edit Milestones"))

do -- these two are created after RefreshLocalizedUI, so they join it here
    local base=MCF.RefreshLocalizedUI
    function MCF:RefreshLocalizedUI()
        base(self)
        scaleLabel:SetText(T("Scale:"))
        manageMilestones:SetText(T("Edit Milestones"))
    end
end

local function EnsureMilestoneDefaults()
    MyCharForeverDB.settings=MyCharForeverDB.settings or {}
    MyCharForeverDB.settings.goldMilestones=MyCharForeverDB.settings.goldMilestones or {}
end

local function OpenMilestoneManager()
    EnsureMilestoneDefaults()
    if not milestoneFrame then
        local f=MCF.Kit.Window("MyCharForeverGoldMilestoneFrame",{w=430,h=360,level=700,close=false,title=T("MyCharForever - Gold Milestones")})
        local info=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        info:SetPoint("TOPLEFT",18,-38); info:SetWidth(390); info:SetJustifyH("LEFT")
        info:SetText(T("Configure your own gold goals. Prices are intentionally not predefined."))

        f.rows={}
        for i=1,5 do
            local y=-70-((i-1)*43)
            local name=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
            name:SetSize(210,24); name:SetPoint("TOPLEFT",20,y); name:SetAutoFocus(false)
            local gold=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
            gold:SetSize(90,24); gold:SetPoint("LEFT",name,"RIGHT",14,0); gold:SetAutoFocus(false); gold:SetNumeric(true)
            local gl=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
            gl:SetPoint("LEFT",gold,"RIGHT",5,0); gl:SetText("g")
            f.rows[i]={name=name,gold=gold}
        end
        local order={}
        for _,row in ipairs(f.rows) do order[#order+1]=row.name; order[#order+1]=row.gold end
        MCF.Kit.TabOrder(order)
        local save=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        save:SetSize(90,24); save:SetPoint("BOTTOMRIGHT",-18,16); save:SetText(T("Save"))
        local cancel=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        cancel:SetSize(90,24); cancel:SetPoint("RIGHT",save,"LEFT",-8,0); cancel:SetText(T("Cancel"))
        cancel:SetScript("OnClick",function() f:Hide() end)
        save:SetScript("OnClick",function()
            local list={}
            for i,row in ipairs(f.rows) do
                local n=strtrim(row.name:GetText() or "")
                local g=tonumber(row.gold:GetText())
                if n~="" and g and g>0 then list[#list+1]={name=n,gold=g} end
            end
            MyCharForeverDB.settings.goldMilestones=list
            if goldScaleMode~=T("AUTO") and not list[tonumber(goldScaleMode) or 0] then goldScaleMode=T("AUTO") end
            if goldScaleMode==T("AUTO") then
                MCF_SetDropdownText(scaleButton,T("AUTO"))
            else
                local selected=list[tonumber(goldScaleMode)]
                MCF_SetDropdownText(scaleButton,(selected and selected.name or T("AUTO")))
            end
            f:Hide()
            MCF:RefreshUI()
        end)
        milestoneFrame=f
    end
    for i,row in ipairs(milestoneFrame.rows) do
        local m=MyCharForeverDB.settings.goldMilestones[i]
        row.name:SetText(m and m.name or "")
        row.gold:SetText(m and tostring(m.gold) or "")
    end
    milestoneFrame:Show()
end

local function InitializeGoldScaleDropdown(self,level)
    -- UIDropDownMenu_Initialize may invoke this while UI.lua is loading,
    -- before Core's PLAYER_LOGIN handler has initialized SavedVariables.
    local info=UIDropDownMenu_CreateInfo()
    if not MyCharForeverDB then
        info.text=T("AUTO")
        info.checked=true
        info.func=function()
            goldScaleMode=T("AUTO")
            MCF_SetDropdownText(scaleButton,T("AUTO"))
        end
        UIDropDownMenu_AddButton(info,level)
        return
    end
    EnsureMilestoneDefaults()
    info.text=T("AUTO")
    info.checked=(goldScaleMode==T("AUTO"))
    info.func=function()
        goldScaleMode=T("AUTO")
        MCF_SetDropdownText(scaleButton,T("AUTO"))
        DrawGoldChart(MyCharForeverDB)
    end
    UIDropDownMenu_AddButton(info,level)

    for i,m in ipairs(MyCharForeverDB.settings.goldMilestones or {}) do
        local idx=i
        local name=m.name or ("Milestone "..i)
        info=UIDropDownMenu_CreateInfo()
        info.text=name.." ("..tostring(m.gold or 0).."g)"
        info.checked=(goldScaleMode==tostring(idx))
        info.func=function()
            goldScaleMode=tostring(idx)
            MCF_SetDropdownText(scaleButton,name)
            DrawGoldChart(MyCharForeverDB)
        end
        UIDropDownMenu_AddButton(info,level)
    end
end
UIDropDownMenu_Initialize(scaleButton,InitializeGoldScaleDropdown)

manageMilestones:SetScript("OnClick",OpenMilestoneManager)

local function ClearGoldChart()
    for _,x in ipairs(goldChart.lines) do MCF.Retire(x) end
    for _,x in ipairs(goldChart.dots) do MCF.Retire(x) end
    for _,x in ipairs(goldChart.labels) do MCF.Retire(x) end
    for _,x in ipairs(goldChart.hitFrames) do MCF.Retire(x) end
    wipe(goldChart.lines); wipe(goldChart.dots); wipe(goldChart.labels); wipe(goldChart.hitFrames)
end

local function AggregateGoldDays(days)
    -- ALL keeps the raw daily SavedVariables intact, but groups old histories
    -- for rendering so the graph remains useful after years of play.
    if #days <= 365 then return days end
    local groups={}
    local bucket=math.ceil(#days/180)
    local i=1
    while i<=#days do
        local last=math.min(#days,i+bucket-1)
        local firstRow=days[i]
        local lastRow=days[last]
        local minV,maxV=nil,nil
        for j=i,last do
            local d=days[j].data
            minV=math.min(minV or d.min or 0,d.min or 0)
            maxV=math.max(maxV or d.max or 0,d.max or 0)
        end
        groups[#groups+1]={
            key=lastRow.key,
            rangeStart=firstRow.key,
            rangeEnd=lastRow.key,
            data={
                first=firstRow.data.first,
                last=lastRow.data.last,
                min=minV,max=maxV,
                level=lastRow.data.level,
                aggregated=true,
            }
        }
        i=last+1
    end
    return groups
end

DrawGoldChart=function(db)
    ClearGoldChart()
    local allDays=MCF:GetGoldDays()
    if #allDays==0 then return end

    local shown={}
    if goldRange=="ALL" then
        for i=1,#allDays do shown[#shown+1]=allDays[i] end
        shown=AggregateGoldDays(shown)
    else
        local spanDays=goldRange=="3D" and 3 or goldRange=="7D" and 7 or goldRange=="30D" and 30 or goldRange=="90D" and 90 or 365
        local cutoff=date("%Y-%m-%d",time()-((spanDays-1)*86400))
        for i=1,#allDays do
            if allDays[i].key>=cutoff then shown[#shown+1]=allDays[i] end
        end
    end
    if #shown==0 then return end

    local maxMoney=1
    for _,row in ipairs(shown) do maxMoney=math.max(maxMoney,row.data.last or 0) end
    local left,bottom,width,height=72,42,455,190

    local function NiceScaleMax(value)
        if value <= 0 then return 100 end
        local magnitude=10^math.floor(math.log10(value))
        local normalized=value/magnitude
        local nice=(normalized<=1 and 1) or (normalized<=2 and 2) or (normalized<=5 and 5) or 10
        return nice*magnitude
    end
    local scaleMax=NiceScaleMax(maxMoney)

    local selectedMilestone
    if goldScaleMode ~= T("AUTO") then
        local idx=tonumber(goldScaleMode)
        selectedMilestone=idx and MyCharForeverDB.settings.goldMilestones and MyCharForeverDB.settings.goldMilestones[idx]
        if selectedMilestone and selectedMilestone.gold then
            scaleMax=NiceScaleMax(math.max(maxMoney,selectedMilestone.gold*10000))
        end
    end

    for step=0,4 do
        local gy=bottom+(height*(step/4))
        local grid=goldChart:CreateLine(nil,"BACKGROUND")
        grid:SetThickness(step==0 and 1.5 or 1); grid:SetColorTexture(0.28,0.28,0.28,0.85)
        grid:SetStartPoint("BOTTOMLEFT",goldChart,left,gy); grid:SetEndPoint("BOTTOMLEFT",goldChart,left+width,gy)
        goldChart.lines[#goldChart.lines+1]=grid
        local value=goldChart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        value:SetPoint("RIGHT",goldChart,"BOTTOMLEFT",left-8,gy); value:SetText(money(scaleMax*(step/4)))
        goldChart.labels[#goldChart.labels+1]=value
    end

    if selectedMilestone and selectedMilestone.gold then
        local targetCopper=selectedMilestone.gold*10000
        local my=bottom+((targetCopper/scaleMax)*height)
        local ml=goldChart:CreateLine(nil,"ARTWORK")
        ml:SetThickness(2); ml:SetColorTexture(0.95,0.55,0.10,0.9)
        ml:SetStartPoint("BOTTOMLEFT",goldChart,left,my)
        ml:SetEndPoint("BOTTOMLEFT",goldChart,left+width,my)
        goldChart.lines[#goldChart.lines+1]=ml
        local mt=goldChart:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        mt:SetPoint("BOTTOMRIGHT",goldChart,"BOTTOMLEFT",left+width-4,my+3)
        mt:SetText((selectedMilestone.name or T("Milestone fallback")).." - "..tostring(selectedMilestone.gold).."g")
        goldChart.labels[#goldChart.labels+1]=mt
    end

    local prevX,prevY
    for i,row in ipairs(shown) do
        local frac=(#shown==1) and 0 or ((i-1)/(#shown-1))
        local x=left+(frac*width)
        local y=bottom+(((row.data.last or 0)/scaleMax)*height)
        local dot=goldChart:CreateTexture(nil,"OVERLAY")
        dot:SetColorTexture(1,0.78,0.10,1)
        local dotSize=(#shown>100 and 2) or (#shown>50 and 3) or (#shown>20 and 4) or 6
        dot:SetSize(dotSize,dotSize); dot:SetPoint("CENTER",goldChart,"BOTTOMLEFT",x,y)
        goldChart.dots[#goldChart.dots+1]=dot

        local hit=CreateFrame("Frame",nil,goldChart)
        hit:SetSize(math.max(10,width/math.max(1,#shown)),18)
        hit:SetPoint("CENTER",goldChart,"BOTTOMLEFT",x,y)
        hit:EnableMouse(true)
        hit:SetScript("OnEnter",function()
            dot:SetSize(math.max(dotSize+4,8),math.max(dotSize+4,8))
            GameTooltip:SetOwner(hit,"ANCHOR_CURSOR")
            if row.data.aggregated then
                GameTooltip:AddLine((row.rangeStart or row.key).." - "..(row.rangeEnd or row.key),1,.82,.2)
            else
                GameTooltip:AddLine(row.key,1,.82,.2)
            end
            GameTooltip:AddLine(T("Level")..": "..tostring(row.data.level or "-"),1,1,1)
            GameTooltip:AddLine(T("Gold: ")..money(row.data.last or 0),1,1,1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(T("Start: ")..money(row.data.first or 0),.8,.8,.8)
            GameTooltip:AddLine(T("Low: ")..money(row.data.min or 0),.8,.8,.8)
            GameTooltip:AddLine(T("High: ")..money(row.data.max or 0),.8,.8,.8)
            local delta=(row.data.last or 0)-(row.data.first or 0)
            GameTooltip:AddLine(T("Change: ")..(delta>=0 and "+" or "-")..money(math.abs(delta)),.8,.8,.8)
            GameTooltip:Show()
        end)
        hit:SetScript("OnLeave",function()
            dot:SetSize(dotSize,dotSize); GameTooltip:Hide()
        end)
        goldChart.hitFrames[#goldChart.hitFrames+1]=hit

        if prevX then
            local line=goldChart:CreateLine(nil,"ARTWORK")
            line:SetThickness(2); line:SetColorTexture(1,0.78,0.10,1)
            line:SetStartPoint("BOTTOMLEFT",goldChart,prevX,prevY); line:SetEndPoint("BOTTOMLEFT",goldChart,x,y)
            goldChart.lines[#goldChart.lines+1]=line
        end
        prevX,prevY=x,y
    end

    local top=goldChart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    top:SetPoint("TOPLEFT",4,-4); top:SetText(T("DAILY GOLD BALANCE"))
    goldChart.labels[#goldChart.labels+1]=top

    local labelCount=math.min(5,#shown)
    local used={}
    for n=1,labelCount do
        local idx=(labelCount==1) and 1 or math.floor(1+((#shown-1)*(n-1)/(labelCount-1))+0.5)
        if not used[idx] then
            used[idx]=true
            local frac=(#shown==1) and 0 or ((idx-1)/(#shown-1))
            local x=left+(frac*width)
            local lbl=goldChart:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            lbl:SetPoint("TOP",goldChart,"BOTTOMLEFT",x,bottom-6)
            lbl:SetText(shown[idx].key:sub(9,10).."."..shown[idx].key:sub(6,7))
            goldChart.labels[#goldChart.labels+1]=lbl
        end
    end
end



local function UpdateGoldRangeButtons()
    for k,b in pairs(rangeButtons) do
        b:SetEnabled(true)
        if k==goldRange then
            b:LockHighlight()
            b:GetFontString():SetTextColor(1,.82,.2)
        else
            b:UnlockHighlight()
            b:GetFontString():SetTextColor(1,1,1)
        end
    end
end
for label,button in pairs(rangeButtons) do
    button:SetScript("OnClick",function()
        goldRange=label
        UpdateGoldRangeButtons()
        -- Rebuild both axes/labels and the data series. RefreshUI also keeps
        -- the history table and scroll-child height in sync.
        if MCF.RefreshUI then MCF:RefreshUI() else DrawGoldChart(MyCharForeverDB) end
    end)
end
UpdateGoldRangeButtons()

fmtDate=function(t)
    if not t then return "-" end
    return date("%d.%m.%Y %H:%M",t)
end

local function completedLevels(db)
    local n=0
    for _,e in pairs(db.levels or {}) do if e.completed then n=n+1 end end
    return n
end

local function longestLevel(db)
    local bestLevel,best= nil,0
    for lvl,e in pairs(db.levels or {}) do
        if (e.duration or 0)>best then best=e.duration or 0; bestLevel=lvl end
    end
    return bestLevel,best
end

local function topZones(db,limit)
    -- The overview tree renders these as actual columns, not a padded text line.
    local a={}
    for z,seconds in pairs(db.zoneTime or {}) do
        if type(z)=="string" and type(seconds)=="number" then
            a[#a+1]={zone=z,seconds=math.max(0,seconds)}
        end
    end
    table.sort(a,function(x,y)
        if x.seconds==y.seconds then return x.zone<y.zone end
        return x.seconds>y.seconds
    end)
    if #a==0 then return T("No zone-time data yet.") end
    local out={"__MCFZONEHEADER__"}
    for i=1,math.min(limit,#a) do
        local total=math.floor(a[i].seconds)
        local days=math.floor(total/86400)
        local hours=math.floor(total%86400/3600)
        local minutes=math.floor(total%3600/60)
        local secs=total%60
        local duration=MCF:FormatDuration(total)
        out[#out+1]=string.format("__MCFZONEROW__\t%d\t%s\t%s",i,a[i].zone,duration)
    end
    return table.concat(out,"\n")
end

local function recentLevels(db,limit)
    local a={}
    for lvl,e in pairs(db.levels or {}) do
        if e.completed then a[#a+1]={lvl=lvl,e=e} end
    end
    table.sort(a,function(x,y) return x.lvl>y.lvl end)
    local out={}
    for i=1,math.min(limit,#a) do
        local x=a[i]
        out[#out+1]=string.format("Level %d  %s  %s",x.lvl,MCF:FormatDuration(x.e.duration or 0),x.e.zone or "?")
    end
    return #out>0 and table.concat(out,"\n") or T("No completed levels yet.")
end

local function levelUpHistory(db)
    local rows={}
    local current=UnitLevel("player")

    for level,e in pairs(db.levels or {}) do
        level=tonumber(level)
        if level and level >= 2 and e.reached then
            rows[#rows+1]={level=level,e=e}
        end
    end

    table.sort(rows,function(a,b) return a.level>b.level end)

    local o={}
    local function H(x) o[#o+1]="|cff00ccff"..x.."|r" end
    local function L(x) o[#o+1]=x end

    H(T("LEVEL-UP HISTORY"))
    L(T("A chronological record of this character's milestones."))
    L("")

    if #rows==0 then
        L(T("No recorded level-ups yet."))
        return table.concat(o,"\n")
    end

    for _,row in ipairs(rows) do
        local level=row.level
        local e=row.e
        local prev=db.levels and db.levels[level-1]
        local snapshot=db.levelSnapshots and db.levelSnapshots[level]

        local shot=nil
        for _,ss in ipairs(db.screenshots or {}) do
            if ss.reason=="LEVEL_UP" and tonumber(ss.level)==level then
                shot=ss
                break
            end
        end

        H("LEVEL "..level)
        L(T("Reached: ")..fmtDate(e.reached))
        L(T("Location: ")..(e.zone or "?")..
          ((e.x and e.y) and string.format("  (%.1f, %.1f)",e.x*100,e.y*100) or ""))

        if prev and prev.duration then
            L(T("Time for Level ")..(level-1)..": "..MCF:FormatDuration(prev.duration))
        end

        if snapshot then
            local gearCount=0
            for _ in pairs(snapshot.equipment or {}) do gearCount=gearCount+1 end
            L("Snapshot: YES  |  Equipment slots: "..gearCount..
              "  |  Money: "..money(snapshot.money or 0))
        else
            L(T("Snapshot: no"))
        end

        L(T("Screenshot record: ")..(shot and T("YES") or T("no")))
        if shot then
            local fileName=shot.expectedFileName or (shot.time and MCF:ScreenshotFileName(shot.time))
            if fileName then L(T("Screenshot file: ")..fileName) end
        end
        L("")
    end

    H(T("ARCHIVE"))
    L(T("Recorded level-ups: ")..#rows)
    local snapCount=0
    for _ in pairs(db.levelSnapshots or {}) do snapCount=snapCount+1 end
    L(T("Level snapshots: ")..snapCount)
    L(T("Screenshot records: ")..#(db.screenshots or {}))

    return table.concat(o,"\n")
end

local function journalHistory(db)
    local o={}
    local function H(x) o[#o+1]="|cff00ccff"..x.."|r" end
    local function L(x) o[#o+1]=x end

    H(T("JOURNAL"))
    L(T("Personal notes from this character's journey."))
    L("")

    local entries=db.journal or {}
    if #entries==0 then
        L(T("No journal entries yet."))
        L("")
        L(T("Create one with '+ Journal Entry' on the world map."))
        return table.concat(o,"\n")
    end

    for i=#entries,1,-1 do
        local e=entries[i]
        H(e.title or (T("Journal Entry ")..i))
        L(fmtDate(e.time))
        L(T("Level").." "..tostring(e.level or "?").."  |  "..(e.zone or "?"))
        if e.x and e.y then
            L(string.format("Position: %.1f, %.1f",e.x*100,e.y*100))
        end
        if e.text and e.text~="" then
            L("")
            L(e.text)
        end
        L("")
        L("----------------------------------------")
        L("")
    end
    return table.concat(o,"\n")
end

local function goldSummaryText(db)
    local o={}
    local function H(x) o[#o+1]="|cff00ccff"..x.."|r" end
    local function L(x) o[#o+1]=x end
    local days=MCF:GetGoldDays()
    local current=GetMoney() or 0

    L("|cffffd100"..T("Current balance:").."|r  "..money(current))
    if #days>0 then
        local today=days[#days].data
        local delta=(today.last or current)-(today.first or current)
        local sign=delta>=0 and "+" or "-"
        L(T("Today's change: ")..sign..money(math.abs(delta))..
          "   |   "..T("Low: ")..money(today.min or current)..
          "   |   "..T("High: ")..money(today.max or current))
    else
        L(T("Gold history starts with this addon version."))
    end
    return table.concat(o,"\n")
end

local function goldDailyHistoryText(db)
    local o={"|cff00ccff"..T("DAILY HISTORY").."|r",""}
    local days=MCF:GetGoldDays()
    if #days==0 then
        o[#o+1]=T("No gold history recorded yet.")
    else
        o[#o+1]=string.format("|cffaaaaaa%-10s  %-12s  %-12s  %-12s  %-12s  %-12s|r",
            T("Date"),T("Start"),T("End"),T("Low"),T("High"),T("Change"))
        o[#o+1]="|cff666666----------------------------------------------------------------------------|r"
        for i=#days,math.max(1,#days-199),-1 do
            local row=days[i]; local d=row.data
            local delta=(d.last or 0)-(d.first or 0); local sign=delta>=0 and "+" or "-"
            local dateText=row.key:sub(9,10).."."..row.key:sub(6,7).."."..row.key:sub(1,4)
            o[#o+1]=string.format("%-10s  %-12s  %-12s  %-12s  %-12s  %-12s",
                dateText,money(d.first or 0),money(d.last or 0),money(d.min or 0),money(d.max or 0),sign..money(math.abs(delta)))
        end
    end
    return table.concat(o,"\n")
end

local function ClearGoldHistoryRows()
    for _,r in ipairs(goldHistoryTextFrame.rows or {}) do MCF.Retire(r) end
    wipe(goldHistoryTextFrame.rows)
end

local expandedGoldDays={}
local function DrawGoldHistoryTable(db)
    ClearGoldHistoryRows()
    local f=goldHistoryTextFrame
    local allDays=MCF:GetGoldDays()
    local days={}
    if goldRange=="ALL" then
        for i=1,#allDays do days[#days+1]=allDays[i] end
    else
        local spanDays=goldRange=="3D" and 3 or goldRange=="7D" and 7 or goldRange=="30D" and 30 or goldRange=="90D" and 90 or 365
        local cutoff=date("%Y-%m-%d",time()-((spanDays-1)*86400))
        for i=1,#allDays do
            if allDays[i].key>=cutoff then days[#days+1]=allDays[i] end
        end
    end
    local y=0
    local function Text(parent,value,x,w,font,justify)
        local fs=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT",x,y); fs:SetWidth(w); fs:SetJustifyH(justify or "LEFT")
        fs:SetText(value or ""); f.rows[#f.rows+1]=fs
        return fs
    end
    Text(f,T("DAILY HISTORY"),0,540,"GameFontNormal")
    y=y-27
    if #days==0 then
        Text(f,T("No gold history recorded yet."),0,540,"GameFontHighlight")
        f.contentHeight=60; return
    end

    local cols={
        {T("Date"),0,84},{T("Start"),86,88},{T("End"),176,88},
        {T("Low"),266,88},{T("High"),356,88},{T("Change"),446,92},
    }
    local header=CreateFrame("Frame",nil,f)
    header:SetPoint("TOPLEFT",0,y+5); header:SetSize(540,23)
    local bg=header:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(.12,.12,.12,.95)
    f.rows[#f.rows+1]=header
    for _,c in ipairs(cols) do
        local fs=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fs:SetPoint("LEFT",c[2]+5,0); fs:SetWidth(c[3]-8); fs:SetJustifyH("LEFT"); fs:SetText(c[1])
    end
    y=y-25

    for i=#days,math.max(1,#days-199),-1 do
        local row=days[i]; local d=row.data
        local rf=CreateFrame("Button",nil,f)
        rf:SetPoint("TOPLEFT",0,y+3); rf:SetSize(540,22)
        local dayKey=row.key
        rf:SetScript("OnClick",function()
            expandedGoldDays[dayKey]=not expandedGoldDays[dayKey]
            MCF:RefreshUI()
        end)
        rf:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        local bg=rf:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints()
        if i%2==0 then bg:SetColorTexture(.07,.07,.07,.75) else bg:SetColorTexture(.02,.02,.02,.45) end
        f.rows[#f.rows+1]=rf
        local delta=(d.last or 0)-(d.first or 0)
        local vals={
            (expandedGoldDays[row.key] and "- " or "+ ")..row.key:sub(9,10).."."..row.key:sub(6,7).."."..row.key:sub(1,4),
            money(d.first or 0),money(d.last or 0),money(d.min or 0),money(d.max or 0),
            (delta>=0 and "+" or "-")..money(math.abs(delta))
        }
        for ci,c in ipairs(cols) do
            local fs=rf:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            fs:SetPoint("LEFT",c[2]+5,0); fs:SetWidth(c[3]-8); fs:SetJustifyH("LEFT")
            fs:SetText(vals[ci]); if ci==6 then fs:SetTextColor(delta>=0 and .35 or 1,delta>=0 and 1 or .35,.35) end
        end
        y=y-22
        if expandedGoldDays[row.key] then
            local de=MCF:GetLanguage()=="deDE" or MCF:GetLanguage()=="de"
            local labels={
                merchantBuy=de and "Händlerkäufe" or "Merchant purchases",
                merchantSell=de and "Händlerverkäufe" or "Merchant sales",
                training=de and "Lehrer / Fähigkeiten" or "Training / abilities",
                repairs=de and "Reparaturen" or "Repairs",
                auction=de and "Auktionshaus" or "Auction house",
                loot=de and "Beute" or "Loot",
                quest=de and "Quests" or "Quests",
                other=de and "Sonstiges / nicht zugeordnet" or "Other / unclassified",
            }
            local order={"merchantBuy","merchantSell","training","repairs","auction","loot","quest","other"}
            local entries={}
            for _,key in ipairs(order) do
                local amount=(d.categories or {})[key]
                if type(amount)=="number" and amount~=0 then
                    entries[#entries+1]={labels[key],amount}
                end
            end
            local first=d.firstTime and date("%H:%M",d.firstTime) or "-"
            local last=d.lastTime and date("%H:%M",d.lastTime) or "-"
            local function DetailRow(left,right,heading)
                local line=CreateFrame("Frame",nil,f)
                line:SetSize(518,19)
                line:SetPoint("TOPLEFT",11,y+2)
                if heading then
                    local shade=line:CreateTexture(nil,"BACKGROUND")
                    shade:SetAllPoints(); shade:SetColorTexture(.13,.13,.13,.75)
                end
                local a=line:CreateFontString(nil,"OVERLAY",heading and "GameFontNormalSmall" or "GameFontHighlightSmall")
                a:SetPoint("LEFT",6,0); a:SetWidth(330); a:SetJustifyH("LEFT"); a:SetText(left)
                local b=line:CreateFontString(nil,"OVERLAY",heading and "GameFontNormalSmall" or "GameFontHighlightSmall")
                b:SetPoint("RIGHT",-8,0); b:SetWidth(165); b:SetJustifyH("RIGHT"); b:SetText(right)
                f.rows[#f.rows+1]=line
                y=y-19
            end
            DetailRow(de and "Messzeitraum" or "Readings",first.." – "..last,true)
            DetailRow(de and "Tagesänderung" or "Daily change",(delta>=0 and "+" or "-")..money(math.abs(delta)))
            if #entries>0 then
                DetailRow(de and "Kategorie" or "Category",de and "Betrag" or "Amount",true)
                for _,entry in ipairs(entries) do
                    DetailRow(entry[1],(entry[2]>=0 and "+" or "-")..money(math.abs(entry[2])))
                end
                DetailRow(de and "Hinweis: nur seit Update erfasst" or "Note: tracked since update","",false)
            else
                DetailRow(de and "Keine kategorisierten Bewegungen" or "No categorized movements","-")
            end
            y=y-8
        end
    end
    f.contentHeight=math.abs(y)+20
    f:SetHeight(math.max(40,f.contentHeight))
end


local dungeonRows={}
local dungeonDetailFrame
local dungeonFilter="ALL"
local dungeonStatusFilter="ALL"
local dungeonSelected={}
local dungeonFilterButton
local dungeonStatusButton
local dungeonDeleteButton

local function ClearDungeonRows()
    for _,row in ipairs(dungeonRows) do MCF.Retire(row) end
    wipe(dungeonRows)
end

local function DungeonDate(t)
    return t and date("%d.%m.%Y %H:%M",t) or "-"
end

local function RecountDungeonStats()
    if not MyCharForeverDB then return end
    local runs=MyCharForeverDB.dungeons or {}
    local completions=0
    for _,r in ipairs(runs) do
        if r.completed then completions=completions+1 end
    end
    MyCharForeverDB.stats.dungeonVisits=#runs
    MyCharForeverDB.stats.dungeonCompletions=completions
end

local function DeleteDungeonRuns(indices)
    if not MyCharForeverDB or not indices then return end
    table.sort(indices,function(a,b) return a>b end)
    for _,idx in ipairs(indices) do
        if MyCharForeverDB.dungeons[idx] then
            table.remove(MyCharForeverDB.dungeons,idx)
        end
    end
    wipe(dungeonSelected)
    RecountDungeonStats()
    if dungeonDetailFrame then dungeonDetailFrame:Hide() end
    MCF:RefreshUI()
end

StaticPopupDialogs["MYCHARFOREVER_DELETE_DUNGEON_RUNS"]={
    text=MCF.Branded(T("Delete selected dungeon run(s) permanently?")),
    button1=YES,
    button2=NO,
    OnAccept=function(_,data) DeleteDungeonRuns(data) end,
    timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
}

local function ConfirmDeleteDungeonRuns(indices)
    if indices and #indices>0 then
        StaticPopup_Show("MYCHARFOREVER_DELETE_DUNGEON_RUNS",nil,nil,indices)
    end
end

local itemTooltipFrames={}
local function ClearItemTooltipFrames(owner)
    for i=#itemTooltipFrames,1,-1 do
        local x=itemTooltipFrames[i]
        if x.owner==owner then x.frame:Hide(); table.remove(itemTooltipFrames,i) end
    end
end
local function AddItemTooltipFrame(owner,parent,itemLink,line,lineHeight,width)
    if not itemLink then return end
    local hit=CreateFrame("Frame",nil,parent)
    hit:SetPoint("TOPLEFT",4,-4-((line-1)*lineHeight))
    hit:SetSize(width or 390,lineHeight)
    hit:EnableMouse(true)
    hit:SetFrameLevel(parent:GetFrameLevel()+5)
    hit:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show()
    end)
    hit:SetScript("OnLeave",function() GameTooltip:Hide() end)
    itemTooltipFrames[#itemTooltipFrames+1]={owner=owner,frame=hit}
end

local dungeonDetailExpanded={general=true,party=true,filter=true,bosses=true,loot=true}
local dungeonBossExpanded={}
local dungeonLootQualities={[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true}
-- Same look as the main window (MCF.Kit): dark brown dialog background, bronze border, gold headings; every
-- section is its own bordered card with a header band, tables get alternating row stripes.
local DETAIL_PANEL_W=600
local function OpenDungeonRunDetails(r,runIndex)
    if not dungeonDetailFrame then
        local f=MCF.Kit.Window("MyCharForeverDungeonDetailFrame",{w=660,h=640,level=900,scroll=true,title=T("MyCharForever - Dungeon Run")})
        f.child:SetSize(612,800)
        f.delete=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        f.delete:SetSize(120,24); f.delete:SetPoint("BOTTOMLEFT",18,16); f.delete:SetText(T("Delete Run"))
        f.delete:SetScript("OnClick",function() if f.runIndex then ConfirmDeleteDungeonRuns({f.runIndex}) end end)
        f.widgets={}; dungeonDetailFrame=f
    end
    local f=dungeonDetailFrame
    f.runIndex=runIndex
    for _,w in ipairs(f.widgets) do w:Hide(); w:SetParent(nil) end
    f.widgets={}
    local cf=f.child
    local host=cf           -- frame that owns the widgets being drawn (the section card, or the page)
    local y=-4
    local de=MCF:GetLanguage()=="deDE"
    local GOLD={0.95,0.75,0.22}
    local function track(w) f.widgets[#f.widgets+1]=w; return w end
    local function cell(value,x,width,color,big,link,tip,oneLine)
        local fs=track(host:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge" or (oneLine and "GameFontHighlightSmall" or "GameFontHighlight")))
        fs:SetPoint("TOPLEFT",cf,"TOPLEFT",x,y); fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetText(value or "")
        if oneLine then fs:SetWordWrap(false); if fs.SetMaxLines then fs:SetMaxLines(1) end end   -- too long: cut off with "..." (the tooltip shows the full item)
        if color then fs:SetTextColor(color[1],color[2],color[3]) else fs:SetTextColor(0.95,0.95,0.95) end
        if link or tip then
            local hit=track(CreateFrame("Frame",nil,host)); hit:SetPoint("TOPLEFT",cf,"TOPLEFT",x,y); hit:SetSize(width,21)
            hit:EnableMouse(true)
            hit:SetScript("OnEnter",function(self)
                GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
                if tip then
                    for i,line in ipairs(tip) do
                        if i==1 then GameTooltip:SetText(line,1,0.9,0.5)
                        elseif type(line)=="table" then   -- {left,right,{r,g,b} left,{r,g,b} right}
                            local lc,rc=line[3] or {0.9,0.9,0.9},line[4] or {0.9,0.9,0.9}
                            GameTooltip:AddDoubleLine(line[1],line[2],lc[1],lc[2],lc[3],rc[1],rc[2],rc[3])
                        else GameTooltip:AddLine(line,0.9,0.9,0.9) end
                    end
                else GameTooltip:SetHyperlink(link) end
                GameTooltip:Show()
            end)
            hit:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        return math.max(22,(fs:GetStringHeight() or 18)+4)
    end
    local stripeIndex=0
    local function row(cols,header)
        local h=22
        for _,c in ipairs(cols) do h=math.max(h,cell(c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8])) end
        if host~=cf then
            local t=track(host:CreateTexture(nil,"BACKGROUND"))
            t:SetPoint("TOPLEFT",cf,"TOPLEFT",8,y); t:SetSize(DETAIL_PANEL_W-8,h)
            if header then
                t:SetColorTexture(0.30,0.21,0.07,0.55)
            else
                stripeIndex=stripeIndex+1
                t:SetColorTexture(1,1,1,stripeIndex%2==0 and 0.05 or 0)
            end
        end
        y=y-h
    end
    local function tableHeader(cols)
        for _,c in ipairs(cols) do c[4]=GOLD end
        stripeIndex=0
        row(cols,true)
    end
    -- Section card with a clickable header band; call the returned function when the section is done.
    local function section(key,deName,enName,info)
        local startY=y
        local p=track(MCF.Kit.Panel(cf))
        p:SetPoint("TOPLEFT",cf,"TOPLEFT",4,y); p:SetWidth(DETAIL_PANEL_W)
        local open=dungeonDetailExpanded[key]
        local btn=MCF.Kit.Band(p,function() dungeonDetailExpanded[key]=not dungeonDetailExpanded[key]; OpenDungeonRunDetails(r,runIndex) end)
        btn:SetPoint("TOPLEFT",4,-4); btn:SetPoint("TOPRIGHT",-4,-4)
        btn:SetLabel((open and "-  " or "+  ")..(de and deName or enName))
        if info then
            local right=btn:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); right:SetPoint("RIGHT",-8,0)
            right:SetText(info); right:SetTextColor(0.7,0.7,0.7)
        end
        y=y-34; host=p; stripeIndex=0
        return open,function()
            p:SetHeight(startY-y+8)
            y=y-18; host=cf
        end
    end
    local function kv(k,v,color) row({{k,16,170,{0.72,0.72,0.72}},{tostring(v or "-"),195,390,color}}) end
    local function quality(drop)
        if type(drop.quality)=="number" then return drop.quality end
        if GetItemInfo then
            local _,_,q=GetItemInfo(drop.itemLink or drop.itemID)
            if type(q)=="number" then return q end
        end
        local W=MCF.WorldDrops
        if W and W.QualityOf and type(drop.itemLink)=="string" then
            local q=W.QualityOf(drop.itemLink)
            if type(q)=="number" then return q end
        end
        if C_Item and C_Item.GetItemQualityByID and drop.itemID then
            local q=C_Item.GetItemQualityByID(drop.itemID)
            if type(q)=="number" then return q end
        end
        return -1
    end
    local qualityColors={[0]={0.62,0.62,0.62},[1]={1,1,1},[2]={0.12,1,0.12},[3]={0.15,0.55,1},[4]={0.72,0.3,1},[5]={1,0.55,0}}
    local function sortedDrops(bossName,unassignedOnly)
        local a={}
        for _,drop in ipairs(r.loot or {}) do
            local belongs=(bossName and drop.boss==bossName) or (unassignedOnly and not drop.boss) or (not bossName and not unassignedOnly)
            local q=quality(drop)
            -- Unknown quality is only shown while all quality filters are enabled.
            local allEnabled=true
            for n=0,5 do if not dungeonLootQualities[n] then allEnabled=false; break end end
            if belongs and ((q>=0 and dungeonLootQualities[q]) or (q<0 and allEnabled)) then a[#a+1]=drop end
        end
        table.sort(a,function(x,z)
            if quality(x)~=quality(z) then return quality(x)>quality(z) end
            return (x.itemLink or "")<(z.itemLink or "")
        end)
        return a
    end
    -- Loot rolls of the group (saved by Dungeons.lua): short text for the table, full list as tooltip.
    local ROLL_SHORT={NEED=de and "Bedarf" or "Need",GREED=de and "Gier" or "Greed",DISENCHANT=de and "Entz." or "DE",PASS=de and "Gepasst" or "Passed"}
    local ROLL_LONG={NEED=de and "Bedarf" or "Need",GREED=de and "Gier" or "Greed",DISENCHANT=de and "Entzaubern" or "Disenchant",PASS=de and "Gepasst" or "Passed"}
    local function rollCell(drop)
        if drop.rollAllPassed then return de and "alle gepasst" or "all passed",nil end
        local roll=MCF.ValidRoll(drop.roll)
        local text=roll and ((ROLL_SHORT[drop.rollType] and (ROLL_SHORT[drop.rollType].." ") or "")..tostring(roll)) or ROLL_SHORT[drop.rollType] or "-"
        local tip
        if type(drop.rolls)=="table" and #drop.rolls>0 then
            -- one line per player: name left, choice and roll right; the winner first (gold, green), then by choice and roll
            local me=MCF.CanonPlayer
            local winnerName=me(drop.player)
            local byName,list={},{}
            for _,e in ipairs(drop.rolls) do
                local n=me(e.player or "?")
                local x=byName[n]
                if not x then x={player=n}; byName[n]=x; list[#list+1]=x end
                x.choice=x.choice or e.choice
                x.roll=x.roll or MCF.ValidRoll(e.roll)
            end
            local RANK={NEED=1,GREED=2,DISENCHANT=3,PASS=4}
            table.sort(list,function(p,q)
                local pw,qw=(p.player==winnerName),(q.player==winnerName)
                if pw~=qw then return pw end
                local pr,qr=RANK[p.choice] or 5,RANK[q.choice] or 5
                if pr~=qr then return pr<qr end
                if (p.roll or 0)~=(q.roll or 0) then return (p.roll or 0)>(q.roll or 0) end
                return tostring(p.player)<tostring(q.player)
            end)
            tip={de and "Würfe" or "Rolls"}
            for _,e in ipairs(list) do
                local what=ROLL_LONG[e.choice] or tostring(e.choice or "?")
                if e.roll then what=what.." "..tostring(e.roll) end
                local won=(e.player==winnerName)
                if won then
                    tip[#tip+1]={e.player,what.."  ("..(de and "gewonnen" or "won")..")",{1,0.82,0.2},{0.35,0.95,0.4}}
                else
                    local c=(e.choice=="PASS") and {0.55,0.55,0.55} or {0.95,0.95,0.95}
                    tip[#tip+1]={e.player,what,c,c}
                end
            end
        end
        return text,tip
    end
    local function lootRows(drops)
        tableHeader({{de and "Gegenstand" or "Item",16,205,nil,nil,nil,nil,true},{de and "Gewinner" or "Winner",225,115,nil,nil,nil,nil,true},{de and "Wurf" or "Roll",344,85,nil,nil,nil,nil,true},{de and "Quelle" or "Source",433,160,nil,nil,nil,nil,true}})
        if #drops==0 then row({{de and "Keine Beute erfasst" or "No loot recorded",20,550,{0.6,0.6,0.6}}}) end
        for _,drop in ipairs(drops) do
            local q=quality(drop)
            local owner=drop.player or (drop.isMine and UnitName("player")) or "-"
            local rollText,rollTip=rollCell(drop)
            row({{drop.itemLink or (T("Item ")..tostring(drop.itemID or "?")),16,205,qualityColors[q],false,drop.itemLink,nil,true},{owner,225,115,nil,false,nil,nil,true},{rollText,344,85,nil,false,nil,rollTip,true},{drop.boss or "-",433,160,nil,false,nil,nil,true}})
        end
    end

    ---------------------------------------------------------------- header
    local status,statusColor
    if r.fullClear then status,statusColor=(de and "KOMPLETT GERÄUMT" or "FULLY CLEARED"),{1,0.82,0.2}
    elseif r.completed then status,statusColor=(de and "ABGESCHLOSSEN" or "COMPLETED"),{0.35,0.95,0.4}
    elseif r.left then status,statusColor=(de and "BESUCHT" or "VISITED"),{0.6,0.75,1}
    else status,statusColor=(de and "LÄUFT" or "IN PROGRESS"),{1,0.82,0.2} end
    do
        local name=track(cf:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"))
        name:SetPoint("TOPLEFT",cf,"TOPLEFT",8,y-2); name:SetWidth(430); name:SetJustifyH("LEFT")
        name:SetText(r.dungeon or T("Unknown Dungeon")); name:SetTextColor(1,0.9,0.5)
        local badge=track(cf:CreateFontString(nil,"OVERLAY","GameFontNormal"))
        badge:SetPoint("TOPRIGHT",cf,"TOPLEFT",DETAIL_PANEL_W+4,y-8); badge:SetText(status); badge:SetTextColor(statusColor[1],statusColor[2],statusColor[3])
        y=y-34
        local sub=track(cf:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"))
        sub:SetPoint("TOPLEFT",cf,"TOPLEFT",8,y); sub:SetTextColor(0.7,0.7,0.7)
        sub:SetText(T("Level").." "..tostring(r.levelEntered or "?").."   |   "..DungeonDate(r.entered))
        y=y-24
    end
    ---------------------------------------------------------------- stat tiles
    do
        local killed,total=0,#(r.bosses or {})
        for _,b in ipairs(r.bosses or {}) do if b.success then killed=killed+1 end end
        local delta=(r.goldEnd and r.goldStart) and (r.goldEnd-r.goldStart) or nil
        local tiles={
            {de and "DAUER" or "DURATION",r.duration and MCF:FormatDuration(r.duration) or "-",nil},
            {de and "TODE" or "DEATHS",tostring(r.deaths or 0),(r.deaths or 0)>0 and {1,0.45,0.4} or {0.35,0.95,0.4}},
            {de and "BOSSE" or "BOSSES",total>0 and (killed.." / "..total) or "-",nil},
            {de and "GOLD" or "GOLD",delta and ((delta>=0 and "+" or "-")..money(math.abs(delta))) or "-",delta and (delta>0 and {0.35,0.95,0.4} or delta<0 and {1,0.45,0.4}) or nil},
        }
        local w=(DETAIL_PANEL_W-3*8)/4
        for i,t in ipairs(tiles) do
            local tile=track(CreateFrame("Frame",nil,cf,"BackdropTemplate"))
            tile:SetPoint("TOPLEFT",cf,"TOPLEFT",4+(i-1)*(w+8),y); tile:SetSize(w,54)
            tile:SetBackdrop(MCF.Kit.BACKDROP); tile:SetBackdropColor(0.14,0.10,0.05,0.95); tile:SetBackdropBorderColor(0.75,0.55,0.10,0.9)
            local l=tile:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); l:SetPoint("TOPLEFT",10,-8); l:SetText(t[1]); l:SetTextColor(0.75,0.6,0.3)
            local v=tile:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); v:SetPoint("TOPLEFT",10,-26); v:SetWidth(w-16); v:SetJustifyH("LEFT"); v:SetWordWrap(false)
            v:SetText(t[2]); local c=t[3] or {1,1,1}; v:SetTextColor(c[1],c[2],c[3])
        end
        y=y-54-14
    end

    ---------------------------------------------------------------- general
    do
        local open,done=section("general","ALLGEMEIN","GENERAL")
        if open then
            kv(T("Entered: "),DungeonDate(r.entered))
            if r.left then kv(T("Left: "),DungeonDate(r.left)) end
            kv(T("Deaths: "),r.deaths or 0)
            if r.goldStart then kv(T("Gold at start: "),money(r.goldStart)) end
            if r.goldEnd then
                kv(T("Gold at end: "),money(r.goldEnd))
                local delta=r.goldEnd-(r.goldStart or r.goldEnd)
                kv(T("Gold change: "),(delta>=0 and "+" or "-")..money(math.abs(delta)),delta>0 and {0.35,0.95,0.4} or delta<0 and {1,0.45,0.4} or nil)
            end
            if r.exitReason then kv(T("Exit: "),r.exitReason) end
        end
        done()
    end
    ---------------------------------------------------------------- party
    do
        local members={}; for _,m in pairs(r.party or {}) do members[#members+1]=m end
        table.sort(members,function(a,b) return (a.name or "")<(b.name or "") end)
        local open,done=section("party","GRUPPE","PARTY",#members>0 and tostring(#members) or nil)
        if open then
            tableHeader({{de and "Spieler" or "Player",16,190},{de and "Klasse" or "Class",215,160},{"Level",390,65},{"Ø iLvl",480,100}})
            for _,m in ipairs(members) do row({{m.name or "?",16,190},{MCF:ClassName(m.classFile,m.class) or "?",215,160},{tostring(m.level or "?"),390,65},{m.averageItemLevel and string.format("%.1f",m.averageItemLevel) or "-",480,100}}) end
            if #members==0 then row({{de and "Keine Gruppe erfasst" or "No party recorded",20,550,{0.6,0.6,0.6}}}) end
        end
        done()
    end
    ---------------------------------------------------------------- loot filter (above the bosses, because it also applies to boss loot)
    do
        local open,done=section("filter","BEUTE-FILTER","LOOT FILTER")
        if open then
            local labels=de and {[0]="Schlecht",[1]="Gewöhnlich",[2]="Ungewöhnlich",[3]="Selten",[4]="Episch",[5]="Legendär"} or {[0]="Poor",[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary"}
            for q=0,5 do
                local x=14+((q%3)*190); local yy=y-math.floor(q/3)*24
                local cb=track(CreateFrame("CheckButton",nil,host,"UICheckButtonTemplate")); cb:SetPoint("TOPLEFT",cf,"TOPLEFT",x,yy); cb:SetSize(22,22); cb:SetChecked(dungeonLootQualities[q])
                local label=cb:CreateFontString(nil,"OVERLAY","GameFontHighlight"); label:SetPoint("LEFT",cb,"RIGHT",2,0); label:SetText(labels[q]); label:SetTextColor(qualityColors[q][1],qualityColors[q][2],qualityColors[q][3])
                cb:SetScript("OnClick",function(self) dungeonLootQualities[q]=self:GetChecked() and true or false; OpenDungeonRunDetails(r,runIndex) end)
            end
            y=y-52
        end
        done()
    end
    ---------------------------------------------------------------- bosses
    do
        local open,done=section("bosses","BOSSE","BOSSES")
        if open then
            tableHeader({{de and "Boss / Beute" or "Boss / Loot",16,370},{de and "Ergebnis" or "Result",390,90},{de and "Dauer" or "Duration",490,100}})
            for i,boss in ipairs(r.bosses or {}) do
                local key=tostring(runIndex)..":"..tostring(i)
                local expanded=dungeonBossExpanded[key]
                stripeIndex=stripeIndex+1
                local t=track(host:CreateTexture(nil,"BACKGROUND")); t:SetPoint("TOPLEFT",cf,"TOPLEFT",8,y); t:SetSize(DETAIL_PANEL_W-8,24)
                t:SetColorTexture(1,1,1,stripeIndex%2==0 and 0.05 or 0)
                local btn=track(CreateFrame("Button",nil,host)); btn:SetPoint("TOPLEFT",cf,"TOPLEFT",12,y); btn:SetSize(365,22)
                local txt=btn:CreateFontString(nil,"OVERLAY","GameFontHighlight"); txt:SetPoint("LEFT",3,0)
                txt:SetText((expanded and "[-] " or "[+] ")..(boss.name or "?")); txt:SetTextColor(0.95,0.95,0.95)
                btn:SetScript("OnEnter",function() txt:SetTextColor(1,0.9,0.5) end)
                btn:SetScript("OnLeave",function() txt:SetTextColor(0.95,0.95,0.95) end)
                btn:SetScript("OnClick",function() dungeonBossExpanded[key]=not dungeonBossExpanded[key]; OpenDungeonRunDetails(r,runIndex) end)
                cell(boss.success and (de and "BESIEGT" or "KILL") or (de and "FEHLVERSUCH" or "WIPE"),390,90,boss.success and {0.35,0.95,0.4} or {1,0.4,0.4})
                cell(boss.duration and MCF:FormatDuration(boss.duration) or "-",490,100)
                y=y-24
                if expanded then lootRows(sortedDrops(boss.name,false)); y=y-4 end
            end
            if not r.bosses or #r.bosses==0 then row({{T("No boss encounters recorded for this run."),20,560,{0.6,0.6,0.6}}}) end
        end
        done()
    end
    ---------------------------------------------------------------- loot
    do
        local open,done=section("loot","BEUTE","LOOT")
        if open then
            local mine,group={},{}
            local me=UnitName("player")
            for _,drop in ipairs(sortedDrops(nil,false)) do
                if drop.isMine or (me and drop.player and (drop.player:match("^([^%-]+)") or drop.player)==me) then mine[#mine+1]=drop else group[#group+1]=drop end
            end
            y=y-8
            row({{(T("MY LOOT")).."  ("..#mine..")",16,580,{1,0.9,0.5}}}); y=y-6
            lootRows(mine)
            y=y-18
            row({{(T("GROUP LOOT")).."  ("..#group..")",16,580,{1,0.9,0.5}}}); y=y-6
            lootRows(group)
        end
        done()
    end
    cf:SetHeight(math.max(450,-y+10))
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(900); f:Raise(); f:Show()
end

local function GetDungeonNames(db)
    local names,seen={},{}
    for _,r in ipairs(db.dungeons or {}) do
        local n=r.dungeon or T("Unknown Dungeon")
        if not seen[n] then seen[n]=true; names[#names+1]=n end
    end
    table.sort(names)
    return names
end

local function InitializeDungeonFilterDropdown(self,level)
    local info=UIDropDownMenu_CreateInfo()
    if not MyCharForeverDB then
        info.text=T("All Dungeons"); info.checked=true
        UIDropDownMenu_AddButton(info,level)
        return
    end
    info.text=T("All Dungeons"); info.checked=(dungeonFilter=="ALL")
    info.func=function() dungeonFilter="ALL"; MCF:RefreshUI() end
    UIDropDownMenu_AddButton(info,level)
    for _,name in ipairs(GetDungeonNames(MyCharForeverDB)) do
        local n=name
        info=UIDropDownMenu_CreateInfo()
        info.text=n; info.checked=(dungeonFilter==n)
        info.func=function() dungeonFilter=n; MCF:RefreshUI() end
        UIDropDownMenu_AddButton(info,level)
    end
end

local function InitializeDungeonStatusDropdown(self,level)
    if not MyCharForeverDB then
        local info=UIDropDownMenu_CreateInfo()
        info.text=T("All"); info.checked=true
        UIDropDownMenu_AddButton(info,level)
        return
    end
    local values={{"ALL",T("All")},{"COMPLETED",T("Completed")},{"CLEARED",T("Fully cleared")},{"VISITED",T("Visited")},{"IN PROGRESS",T("In Progress")}}
    for _,entry in ipairs(values) do
        local value,label=entry[1],entry[2]
        local info=UIDropDownMenu_CreateInfo()
        info.text=label; info.checked=(dungeonStatusFilter==value)
        info.func=function() dungeonStatusFilter=value; MCF:RefreshUI() end
        UIDropDownMenu_AddButton(info,level)
    end
end

local function DrawDungeonRows(db)
    ClearDungeonRows()
    local runs=db.dungeons or {}
    local y=-5

    local info=child:CreateFontString(nil,"OVERLAY","MyCharForeverDescriptionFont")
    info:SetPoint("TOPLEFT",12,y-2); info:SetWidth(560); info:SetJustifyH("LEFT")
    info:SetText(T("Dungeon history info").."\n"..T("Dungeon web hint"))
    dungeonRows[#dungeonRows+1]=info
    -- the filters below start under the description, however many lines it takes at the current font size
    y=y-math.ceil((info:GetStringHeight() or 40)*MCF:GetFontScale()/(MCF.fontAppliedFactor or 1))-16

    local dungeonLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    dungeonLabel:SetPoint("TOPLEFT",12,y-5); dungeonLabel:SetText(T("Dungeon:"))
    dungeonRows[#dungeonRows+1]=dungeonLabel

    dungeonFilterButton=CreateFrame("Frame",nil,child,"UIDropDownMenuTemplate")
    dungeonFilterButton:SetPoint("LEFT",dungeonLabel,"RIGHT",-10,0)
    UIDropDownMenu_SetWidth(dungeonFilterButton,165)
    UIDropDownMenu_SetText(dungeonFilterButton,(dungeonFilter=="ALL" and T("All Dungeons") or dungeonFilter))
    UIDropDownMenu_Initialize(dungeonFilterButton,InitializeDungeonFilterDropdown)
    dungeonRows[#dungeonRows+1]=dungeonFilterButton

    local statusLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    statusLabel:SetPoint("LEFT",dungeonFilterButton,"RIGHT",-6,0); statusLabel:SetText(T("Status:"))
    dungeonRows[#dungeonRows+1]=statusLabel

    dungeonStatusButton=CreateFrame("Frame",nil,child,"UIDropDownMenuTemplate")
    dungeonStatusButton:SetPoint("LEFT",statusLabel,"RIGHT",-10,0)
    UIDropDownMenu_SetWidth(dungeonStatusButton,105)
    local statusDisplay=(dungeonStatusFilter=="ALL" and T("All")) or (dungeonStatusFilter=="IN PROGRESS" and T("In Progress")) or (dungeonStatusFilter=="CLEARED" and T("Fully cleared")) or (dungeonStatusFilter:sub(1,1)..dungeonStatusFilter:sub(2):lower())
    UIDropDownMenu_SetText(dungeonStatusButton,statusDisplay)
    UIDropDownMenu_Initialize(dungeonStatusButton,InitializeDungeonStatusDropdown)
    dungeonRows[#dungeonRows+1]=dungeonStatusButton

    dungeonDeleteButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    dungeonDeleteButton:SetSize(125,22); dungeonDeleteButton:SetPoint("LEFT",dungeonStatusButton,"RIGHT",-4,0)
    dungeonDeleteButton:SetText(T("Delete selected"))
    dungeonDeleteButton:SetScript("OnClick",function()
        local indices={}
        for idx,selected in pairs(dungeonSelected) do if selected then indices[#indices+1]=idx end end
        ConfirmDeleteDungeonRuns(indices)
    end)
    dungeonRows[#dungeonRows+1]=dungeonDeleteButton
    y=y-34

    local filtered={}
    for idx,r in ipairs(runs) do
        local status=r.fullClear and "CLEARED" or (r.completed and "COMPLETED" or (r.left and "VISITED" or "IN PROGRESS"))
        local dungeonOK=(dungeonFilter=="ALL" or (r.dungeon or T("Unknown Dungeon"))==dungeonFilter)
        -- "Completed" includes the fully cleared runs (main boss dead); "Fully cleared" is the stricter one
        local statusOK=(dungeonStatusFilter=="ALL" or status==dungeonStatusFilter or (dungeonStatusFilter=="COMPLETED" and r.completed))
        if dungeonOK and statusOK then filtered[#filtered+1]={index=idx,run=r,status=status} end
    end

    local summary=CreateFrame("Frame",nil,child); summary:SetSize(555,22); summary:SetPoint("TOPLEFT",8,y)
    local st=summary:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    st:SetPoint("TOPLEFT",4,-2)
    st:SetText(T("Showing ")..#filtered..T(" of ")..#runs..T(" runs   |   Completions: ")..tostring(db.stats.dungeonCompletions or 0))
    dungeonRows[#dungeonRows+1]=summary
    y=y-25

    local header=CreateFrame("Frame",nil,child); header:SetSize(555,22); header:SetPoint("TOPLEFT",8,y)
    local function H(text,x,w)
        local fs=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fs:SetPoint("TOPLEFT",x,-2); fs:SetWidth(w); fs:SetJustifyH("LEFT"); fs:SetText(text)
    end
    H("",2,20); H(T("Date"),28,92); H("Dungeon",120,190); H("Lv",310,30); H("Duration",340,70); H("Status",410,82)
    dungeonRows[#dungeonRows+1]=header
    y=y-22

    if #filtered==0 then
        local row=CreateFrame("Frame",nil,child); row:SetSize(555,35); row:SetPoint("TOPLEFT",8,y)
        local msg=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        msg:SetPoint("TOPLEFT",28,-5); msg:SetText(T("No dungeon runs match the current filters."))
        dungeonRows[#dungeonRows+1]=row
        return math.abs(y)+60
    end

    for n=#filtered,1,-1 do
        local item=filtered[n]; local r=item.run; local idx=item.index
        local row=CreateFrame("Frame",nil,child)
        row:SetSize(555,26); row:SetPoint("TOPLEFT",8,y)

        local check=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate")
        check:SetSize(22,22); check:SetPoint("LEFT",0,0); check:SetChecked(dungeonSelected[idx] or false)
        check:SetScript("OnClick",function(self) dungeonSelected[idx]=self:GetChecked() and true or nil end)

        local function C(text,x,w,justify)
            local fs=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            fs:SetPoint("LEFT",x,0); fs:SetWidth(w); fs:SetJustifyH(justify or "LEFT"); fs:SetText(text)
        end
        C(r.entered and date("%d.%m.%y %H:%M",r.entered) or "-",28,90)
        C(r.dungeon or T("Unknown Dungeon"),120,185)
        C(tostring(r.levelEntered or "?"),310,28)
        C(r.duration and MCF:FormatDuration(r.duration) or "--:--",340,66)
        local statusText=item.status
        if item.status=="CLEARED" then statusText="|cffffd200"..T("CLEARED SHORT").."|r"
        elseif item.status=="COMPLETED" then statusText="|cff44ff44"..T("COMPLETED").."|r"
        elseif item.status=="VISITED" then statusText="|cffffcc44"..T("VISITED").."|r"
        else statusText="|cff00ccff"..T("IN PROGRESS").."|r" end
        C(statusText,410,82)

        local show=CreateFrame("Button",nil,row,"UIPanelButtonTemplate")
        show:SetSize(52,20); show:SetPoint("RIGHT",-2,0); show:SetText(T("Show"))
        show:SetScript("OnClick",function() OpenDungeonRunDetails(r,idx) end)

        dungeonRows[#dungeonRows+1]=row
        y=y-27
    end
    return math.abs(y)+30
end


local screenshotFilesWindow
local screenshotFilesCopyBox
local screenshotFilesTableRows={}
function ScreenshotTypeLabel(ss)
    local r=ss and ss.reason or ""
    if r=="LEVEL_UP" or r=="LEVELUP" then return T("Level-Up")
    elseif r=="MANUAL_CHRONICLE" or (ss and ss.manual) then return T("Manual")
    elseif r=="PERIODIC" then return T("Automatic")
    elseif r=="GAME" then return MCF:GetLanguage()=="deDE" and "Spiel-Screenshot" or "Game screenshot"
    elseif r=="DEATH" then return T("Death")
    elseif r=="LOGIN" then return T("Login")
    elseif r=="PVP_FIRST_KILL" then return MCF:GetLanguage()=="deDE" and "Erster Spielerkill" or "First player kill"
    elseif r=="PVP_FIRST_DEATH" then return MCF:GetLanguage()=="deDE" and "Erster Tod durch Spieler" or "First death by a player"
    elseif r=="GUILD_INVITE" then return MCF:GetLanguage()=="deDE" and "Gildeneinladung" or "Guild invitation"
    elseif r=="GUILD_JOIN" then return MCF:GetLanguage()=="deDE" and "Gildenbeitritt" or "Joined guild"
    elseif type(r)=="string" and r:sub(1,7)=="ICONIC_" then return MCF:GetLanguage()=="deDE" and "Ikonisch" or "Iconic"
    elseif r and r~="" then
        local g=Shots.group(ss)   -- equipment, guild leave/kick, first death, comeback, roll moments ...
        for _,grp in ipairs(Shots.groups) do if grp.key==g and g~="other" then return T(grp.label) end end
        return tostring(r)
    end
    return T("Automatic")
end
local function ClearScreenshotFileRows()
    for _,r in ipairs(screenshotFilesTableRows) do if r.Hide then r:Hide() end end
    wipe(screenshotFilesTableRows)
end
function ShowLevelScreenshotFiles(level,shots)
    if not screenshotFilesWindow then
        local f=MCF.Kit.Window("MyCharForeverScreenshotFilesWindow",{w=700,h=390,level=650})
        screenshotFilesWindow=f
        local h1=MCF.Kit.Label(f.content,T("Filename"),10,-4)
        local h2=MCF.Kit.Label(f.content,T("Type"),521,-4)
        local line=f.content:CreateTexture(nil,"ARTWORK"); line:SetPoint("TOPLEFT",4,-24); line:SetPoint("TOPRIGHT",-4,-24); line:SetHeight(1)
        line:SetColorTexture(unpack(MCF.Kit.BAND_LINE))
        f.rowsHost=CreateFrame("Frame",nil,f.content); f.rowsHost:SetPoint("TOPLEFT",4,-30); f.rowsHost:SetPoint("TOPRIGHT",-4,-30); f.rowsHost:SetHeight(235)
        -- Copy view: a visible, scrollable text area. The old copy box was a 1x1 invisible
        -- edit box, so the click on the export button had no visible effect.
        local copyBg=MCF.Kit.Inset(f.content); copyBg:SetPoint("TOPLEFT",0,0); copyBg:SetPoint("BOTTOMRIGHT",0,0); copyBg:Hide()
        local copyScroll=CreateFrame("ScrollFrame",nil,copyBg,"UIPanelScrollFrameTemplate")
        copyScroll:SetPoint("TOPLEFT",8,-8); copyScroll:SetPoint("BOTTOMRIGHT",-28,8)
        local edit=CreateFrame("EditBox",nil,copyScroll); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlight"); edit:SetWidth(620)
        copyScroll:SetScrollChild(edit)
        f.copyScroll=copyBg
        local status=f:CreateFontString(nil,"OVERLAY","GameFontNormal"); status:SetPoint("BOTTOMLEFT",20,20); status:SetWidth(320); status:SetJustifyH("LEFT")
        f.status=status
        local hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hint:SetPoint("BOTTOMLEFT",20,16); hint:SetWidth(320); hint:SetJustifyH("LEFT"); hint:SetText(T("Export filenames hint"))
        f.hint=hint
        local export=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); export:SetSize(190,24); export:SetPoint("RIGHT",f.closeButton,"LEFT",-8,0)
        f.exportButton=export
        function f:SetCopyMode(on)
            self.copyMode=on
            self.rowsHost:SetShown(not on); self.copyScroll:SetShown(on)
            self.hint:SetShown(not on); self.status:SetShown(on)
            self.exportButton:SetText(on and T("Back to list") or T("Export filenames only"))
            if on then
                self.status:SetText(T("Filenames selected - press Ctrl+C now."))
                edit:SetText(self.namesText or ""); edit:SetFocus(); edit:HighlightText()
            else
                edit:ClearFocus()
            end
        end
        export:SetScript("OnClick",function() f:SetCopyMode(not f.copyMode) end)
        edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        edit:SetScript("OnKeyDown",function(_,key) if key=="C" and IsControlKeyDown() then status:SetText(T("Copied - paste it with Ctrl+V.")) end end)
        -- Keep the text read-only: any edit snaps back to the full list, still highlighted.
        edit:SetScript("OnTextChanged",function(self,user) if user then self:SetText(f.namesText or ""); self:HighlightText() end end)
        screenshotFilesCopyBox=edit
    end
    ClearScreenshotFileRows()
    local names={}
    local y=0
    for i,ss in ipairs(shots or {}) do
        local fn=ss.expectedFileName or ss.filename or ss.fileName or ss.name
        if fn and fn~="" then names[#names+1]=tostring(fn) else fn=T("Filename unavailable") end
        local row=CreateFrame("Frame",nil,screenshotFilesWindow.rowsHost)
        row:SetPoint("TOPLEFT",0,-y); row:SetPoint("TOPRIGHT",0,-y); row:SetHeight(24)
        local hi=row:CreateTexture(nil,"BACKGROUND"); hi:SetAllPoints(); hi:SetTexture("Interface\\Buttons\\WHITE8X8"); hi:SetVertexColor(1,1,1,.10); hi:Hide()
        row:EnableMouse(true); row:SetScript("OnEnter",function() hi:Show() end); row:SetScript("OnLeave",function() hi:Hide() end)
        local a=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); a:SetPoint("LEFT",8,0); a:SetWidth(490); a:SetJustifyH("LEFT"); a:SetText(fn)
        local b=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); b:SetPoint("LEFT",515,0); b:SetWidth(125); b:SetJustifyH("LEFT"); b:SetText(ScreenshotTypeLabel(ss))
        screenshotFilesTableRows[#screenshotFilesTableRows+1]=row; y=y+25
    end
    if #shots==0 then
        local fs=screenshotFilesWindow.rowsHost:CreateFontString(nil,"OVERLAY","GameFontHighlight"); fs:SetPoint("TOPLEFT",8,0); fs:SetText(T("No screenshot filenames recorded.")); screenshotFilesTableRows[#screenshotFilesTableRows+1]=fs
    end
    if type(level)=="string" and level:match("^%d%d%d%d%-%d%d%-%d%d$") then
        screenshotFilesWindow.title:SetText(T("Screenshots").." - "..level)
    else
        screenshotFilesWindow.title:SetText(T("Screenshot files on level").." "..tostring(level))
    end
    screenshotFilesWindow.namesText=table.concat(names,"\n")
    screenshotFilesWindow:SetCopyMode(false)
    screenshotFilesWindow:Show()
end

local levelRows={}
local levelDetailExpanded={}
local levelBlockExpanded={}
local function ClearLevelRows()
    for _,row in ipairs(levelRows) do MCF.Retire(row) end
    wipe(levelRows)
end


local questListWindow
local questListRows={}
local questListCopyBox

local function ClearQuestListRows()
    for _,row in ipairs(questListRows) do MCF.Retire(row) end
    wipe(questListRows)
end

local function ShowQuestList(level,quests)
    if not questListWindow then
        questListWindow=MCF.Kit.Window("MyCharForeverQuestListWindow",{w=700,h=440,level=650})
        local body=questListWindow.content
        questListWindow:HookScript("OnHide",function() if questListCopyBox then questListCopyBox:ClearFocus(); questListCopyBox:Hide() end end)

        local summary=body:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        summary:SetPoint("TOPLEFT",4,-2)
        questListWindow.summary=summary

        local header=CreateFrame("Frame",nil,body)
        header:SetPoint("TOPLEFT",0,-22)
        header:SetPoint("TOPRIGHT",-22,-22)
        header:SetHeight(25)
        local headerBg=header:CreateTexture(nil,"BACKGROUND"); headerBg:SetAllPoints(); headerBg:SetColorTexture(unpack(MCF.Kit.BAND))

        local function Header(txt,x,w,justify)
            local fs=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            fs:SetPoint("LEFT",x,0)
            fs:SetWidth(w)
            fs:SetJustifyH(justify or "LEFT")
            fs:SetText(txt)
            fs:SetTextColor(unpack(MCF.Kit.GOLD))
        end
        Header(T("Quest ID"),8,65)
        Header(T("Quest"),78,330)
        Header(T("XP"),414,70,"RIGHT")
        Header(T("Zone"),500,140)

        local scroll=CreateFrame("ScrollFrame",nil,body,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",0,-50)
        scroll:SetPoint("BOTTOMRIGHT",-22,0)

        local content=CreateFrame("Frame",nil,scroll)
        content:SetSize(640,1)
        scroll:SetScrollChild(content)
        questListWindow.content=content

        local copy=CreateFrame("Button",nil,questListWindow,"UIPanelButtonTemplate")
        copy:SetSize(145,24)
        copy:SetPoint("BOTTOMLEFT",18,16)
        copy:SetText(T("Copy quest list"))

        local copyHint=questListWindow:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        copyHint:SetPoint("LEFT",copy,"RIGHT",10,0)
        copyHint:SetWidth(330); copyHint:SetJustifyH("LEFT")
        copyHint:SetText(T("Copy quest list hint"))

        questListCopyBox=CreateFrame("EditBox",nil,questListWindow)
        questListCopyBox:SetFrameLevel(questListWindow:GetFrameLevel()+3)
        questListCopyBox:SetMultiLine(true)
        questListCopyBox:SetAutoFocus(false)
        questListCopyBox:SetFontObject("ChatFontNormal")
        questListCopyBox:SetSize(1,1)
        questListCopyBox:SetPoint("BOTTOMLEFT",18,18)
        questListCopyBox:SetAlpha(0)
        questListCopyBox:Hide()
        questListCopyBox:SetScript("OnEscapePressed",function(self)
            self:ClearFocus()
            self:Hide()
            questListWindow:Hide()
        end)
        questListCopyBox:SetScript("OnEditFocusLost",function(self) self:Hide() end)

        copy:SetScript("OnClick",function()
            questListCopyBox:Show()
            questListCopyBox:SetFocus()
            questListCopyBox:HighlightText()
        end)

        questListWindow:SetScript("OnKeyDown",function(self,key)
            if key=="ESCAPE" then self:Hide() end
        end)
        questListWindow:EnableKeyboard(true)
        questListWindow:SetPropagateKeyboardInput(true)
    end

    ClearQuestListRows()
    questListWindow.title:SetText(T("Quests on level").." "..tostring(level))

    local totalXP=0
    for _,q in ipairs(quests or {}) do totalXP=totalXP+(tonumber(q.xp) or 0) end
    questListWindow.summary:SetText(string.format(T("Quest list total"),#(quests or {}),totalXP))

    local y=0
    local copyRows={"ID\t"..T("Quest").."\tXP\t"..T("Zone")}
    for i,q in ipairs(quests or {}) do
        local row=CreateFrame("Frame",nil,questListWindow.content,"BackdropTemplate")
        row:SetPoint("TOPLEFT",0,-y)
        row:SetSize(640,24)
        if i%2==0 then
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(1,1,1,0.04)
        end

        local function Cell(txt,x,w,justify)
            local fs=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            fs:SetPoint("LEFT",x,0)
            fs:SetWidth(w)
            fs:SetJustifyH(justify or "LEFT")
            fs:SetText(txt)
        end

        local id=tostring(q.questID or "?")
        local name=tostring((q.title and q.title~="") and q.title or "?")
        local xp=tonumber(q.xp) or 0
        local zone=tostring(q.zone or "?")
        Cell(id,8,65)
        Cell(name,78,330)
        Cell(tostring(xp),414,70,"RIGHT")
        Cell(zone,500,140)

        questListRows[#questListRows+1]=row
        copyRows[#copyRows+1]=id.."\t"..name.."\t"..xp.."\t"..zone
        y=y+24
    end

    questListWindow.content:SetHeight(math.max(1,y))
    questListCopyBox:SetText(table.concat(copyRows,"\n"))
    questListWindow:Show()
end


local levelDungeonFrame
local levelDungeonRows={}
local function ClearLevelDungeonRows()
    for _,r in ipairs(levelDungeonRows) do MCF.Retire(r) end
    wipe(levelDungeonRows)
end

local function OpenLevelDungeonRuns(level)
    if not levelDungeonFrame then
        local f=MCF.Kit.Window("MyCharForeverLevelDungeonFrame",{w=620,h=390,level=700})
        f.header=f.content:CreateFontString(nil,"OVERLAY","GameFontNormal")
        f.header:SetPoint("TOPLEFT",10,-4); f.header:SetTextColor(unpack(MCF.Kit.GOLD))
        f.header:SetText(T("Date").."        "..T("Dungeon").."                         "..T("Duration").."       "..T("Status"))
        f.rows=CreateFrame("Frame",nil,f.content); f.rows:SetPoint("TOPLEFT",4,-26); f.rows:SetPoint("BOTTOMRIGHT",0,0)
        levelDungeonFrame=f
    end
    ClearLevelDungeonRows()
    levelDungeonFrame.title:SetText(T("Dungeons on level").." "..tostring(level))
    local y=-4
    local found=0
    for runIndex,r in ipairs(MyCharForeverDB.dungeons or {}) do
        if tonumber(r.levelEntered)==tonumber(level) then
            found=found+1
            local row=CreateFrame("Frame",nil,levelDungeonFrame.rows)
            row:SetHeight(26); row:SetPoint("TOPLEFT",4,y); row:SetPoint("TOPRIGHT",-4,y)
            if found%2==0 then local st=row:CreateTexture(nil,"BACKGROUND"); st:SetAllPoints(); st:SetColorTexture(1,1,1,0.05) end
            local txt=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            txt:SetPoint("LEFT",4,0); txt:SetWidth(470); txt:SetJustifyH("LEFT")
            local status=r.fullClear and T("CLEARED") or (r.completed and T("COMPLETED") or T("VISITED"))
            txt:SetText(string.format("%s   %-26s   %s   %s",
                DungeonDate(r.entered),r.dungeon or "?",MCF:FormatDuration(r.duration or 0),status))
            local show=CreateFrame("Button",nil,row,"UIPanelButtonTemplate")
            show:SetSize(72,20); show:SetPoint("RIGHT",-2,0); show:SetText(T("Show"))
            show:SetScript("OnClick",function() OpenDungeonRunDetails(r,runIndex) end)
            levelDungeonRows[#levelDungeonRows+1]=row
            y=y-28
        end
    end
    if found==0 then
        local msg=levelDungeonFrame.rows:CreateFontString(nil,"OVERLAY","GameFontNormal")
        msg:SetPoint("TOPLEFT",8,-8); msg:SetText(T("No dungeon runs recorded on this level."))
        local holder=CreateFrame("Frame",nil,levelDungeonFrame.rows); holder:SetSize(1,1); holder:Hide()
        holder.msg=msg; levelDungeonRows[#levelDungeonRows+1]=holder
    end
    levelDungeonFrame:Show(); levelDungeonFrame:Raise()
end


local levelDetailsFrame
local function OpenLevelDetails(level,e,prev,snapshot,activity,quests,dungeons,deaths,bossKills,sessions,zoneList,shot)
    if not levelDetailsFrame then
        local f=MCF.Kit.Window("MyCharForeverLevelDetailsFrame",{w=560,h=520,level=700,scroll=true})
        local cf=f.child; cf:SetSize(490,700)
        f.text=cf:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        f.text:SetPoint("TOPLEFT",4,-4); f.text:SetWidth(475); f.text:SetJustifyH("LEFT"); f.text:SetJustifyV("TOP")
        levelDetailsFrame=f
    end
    ClearItemTooltipFrames(levelDetailsFrame)
    local lines={}
    local equipmentTooltipLines={}
    local function L(s) lines[#lines+1]=s or "" end
    local function KV2(k,v) L("|cffffcc00"..k.."|r  "..tostring(v or "-")) end
    levelDetailsFrame.title:SetText(T("Level details").." - "..T("Level").." "..level)
    local posText=(e.x and e.y) and string.format(" (%.1f, %.1f)",e.x*100,e.y*100) or ""
    KV2(T("Reached: "),fmtDate(e.reached))
    KV2(T("Location: "),(e.zone or "?")..posText)
    KV2(T("Time on Level ")..(level-1)..":",prev and prev.duration and MCF:FormatDuration(prev.duration) or "-")
    local afk=MCF.GetAFKTimeForLevel and MCF:GetAFKTimeForLevel(level-1)
    if afk~=nil and prev and prev.duration then
        local total=tonumber(prev.duration) or 0
        KV2(T("AFK time:"),MCF:FormatDuration(afk).." ("..string.format("%.1f%%",total>0 and afk/total*100 or 0)..")")
        KV2(T("Active time:"),MCF:FormatDuration(math.max(0,total-afk)))
    else KV2(T("AFK time:"),T("not recorded")) end
    local stillLevel=MCF.GetStationaryForLevel and MCF:GetStationaryForLevel(level-1)
    if stillLevel~=nil then KV2(T("Stationary time:"),MCF:FormatDuration(stillLevel)) end
    L("")
    KV2(T("Snapshot:"),snapshot and T("YES") or T("no"))
    local gearCount=0; if snapshot then for _ in pairs(snapshot.equipment or {}) do gearCount=gearCount+1 end end
    KV2(T("Equipment slots:"),snapshot and gearCount or "-")
    if snapshot and tonumber(snapshot.averageItemLevel) then KV2(T("Average item level:"),string.format("%.1f",snapshot.averageItemLevel)) end
    KV2(T("Money:"),snapshot and money(snapshot.money or 0) or "-")
    if snapshot and snapshot.equipment and next(snapshot.equipment) then
        L(""); L("|cff00ccff"..T("Equipment").."|r")
        local gear={}
        for slot,item in pairs(snapshot.equipment) do gear[#gear+1]={slot=slot,item=item} end
        table.sort(gear,function(a,b) return tostring(a.slot)<tostring(b.slot) end)
        for _,g in ipairs(gear) do
            local item=g.item or {}
            local link=item.link or item.itemLink
            L(tostring(g.slot)..":  "..(link or item.name or (T("Item ")..tostring(item.itemID or "?"))))
            if link then equipmentTooltipLines[#equipmentTooltipLines+1]={line=#lines,link=link} end
        end
    end
    L("")
    KV2(T("Quests completed:"),#quests)
    local questXP=0; for _,q in ipairs(quests) do questXP=questXP+(tonumber(q.xp) or 0) end
    local requiredXP=tonumber(activity.requiredXP)
    if requiredXP and requiredXP>0 then
        local otherXP=math.max(0,requiredXP-questXP)
        KV2(T("Quest XP:"),string.format("%d (%.1f%%)",questXP,questXP/requiredXP*100))
        KV2(T("Other XP:"),string.format("%d (%.1f%%)",otherXP,otherXP/requiredXP*100))
        KV2(T("Required XP:"),requiredXP)
    else KV2(T("Quest XP:"),questXP) end
    L("")
    local completed=0; for _,r in ipairs(dungeons) do if r.completed then completed=completed+1 end end
    KV2(T("Dungeon runs:"),#dungeons)
    KV2(T("Dungeon completions:"),completed)
    KV2(T("Boss kills:"),#bossKills)
    KV2(T("Deaths:"),#deaths)
    KV2(T("Sessions:"),#sessions)
    KV2(T("Zones visited:"),#zoneList)
    local fileName=shot and (shot.expectedFileName or (shot.time and MCF:ScreenshotFileName(shot.time)))
    KV2(T("Screenshot file: "),fileName or T("no"))
    levelDetailsFrame.text:SetText(table.concat(lines,"\n"))
    levelDetailsFrame.child:SetHeight(math.max(700,(levelDetailsFrame.text:GetStringHeight() or 0)+30))
    local lh=(#lines>0 and (levelDetailsFrame.text:GetStringHeight() or 0)>0) and ((levelDetailsFrame.text:GetStringHeight() or 0)/#lines) or 14
    if lh<10 then lh=10 end
    for _,it in ipairs(equipmentTooltipLines) do AddItemTooltipFrame(levelDetailsFrame,levelDetailsFrame.child,it.link,it.line,lh,470) end
    levelDetailsFrame:Show(); levelDetailsFrame:Raise()
end

local function DrawLevelRows(db)
    ClearLevelRows()
    local y=-5

    local function AddText(value,x,width,ypos,font)
        local fs=child:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
        fs:SetPoint("TOPLEFT",x,ypos); fs:SetWidth(width)
        fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetText(value or "")
        levelRows[#levelRows+1]=fs
        return fs
    end

    AddText(T("LEVEL HISTORY"),8,550,y,"GameFontNormal"); y=y-20
    AddText(T("Level history description"),8,550,y,"GameFontHighlight"); y=y-34

    local currentLevel=UnitLevel("player") or 0
    local currentActivity=db.levelActivity and db.levelActivity[currentLevel] or {}
    local currentQuests=currentActivity.quests or {}
    local currentDeaths=currentActivity.deaths or {}
    local currentDungeons=currentActivity.dungeons or {}
    local currentTravel=db.travel and db.travel.byLevel and db.travel.byLevel[currentLevel] or {}
    local currentGold=db.goldByLevel and db.goldByLevel[currentLevel]

    local live=CreateFrame("Frame",nil,child,"InsetFrameTemplate")
    live:SetSize(535,278); live:SetPoint("TOPLEFT",8,y)
    local liveTitle=live:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    liveTitle:SetPoint("TOPLEFT",12,-10); liveTitle:SetText("|cffffffff"..T("Level").." "..currentLevel.." - "..T("in progress").."|r")
    local curTime=0
    local le=db.levels and db.levels[currentLevel]
    if le then
        curTime=tonumber(le.duration) or 0
        if le.startRuntime then curTime=curTime+math.max(0,GetTime()-le.startRuntime) end
    end
    local cg=currentGold and ((currentGold.earned or 0)-(currentGold.spent or 0)) or nil

    local liveY=-40
    local function LiveKV(label,value)
        local row=CreateFrame("Frame",nil,live)
        row:SetPoint("TOPLEFT",12,liveY+2); row:SetSize(510,18)
        local hl=row:CreateTexture(nil,"BACKGROUND")
        hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(1,1,1,0.08); hl:Hide()
        row:EnableMouse(true)
        row:SetScript("OnEnter",function() hl:Show() end)
        row:SetScript("OnLeave",function() hl:Hide() end)
        local l=row:CreateFontString(nil,"OVERLAY","GameFontNormal")
        l:SetPoint("LEFT",4,0); l:SetWidth(210); l:SetJustifyH("LEFT"); l:SetText(label)
        local r=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        r:SetPoint("RIGHT",-4,0); r:SetWidth(285); r:SetJustifyH("RIGHT"); r:SetText(value or "")
        liveY=liveY-19
    end

    LiveKV(T("Time on current level:"),MCF:FormatDuration(curTime))
    LiveKV(T("Activity:"),#currentQuests.." "..T("Quests").."  |  "..#currentDeaths.." "..T("Deaths").."  |  "..#currentDungeons.." "..T("Dungeons"))
    LiveKV(T("Ground distance:"),MCF:FormatDistance(currentTravel.groundYards or 0))
    LiveKV(T("Flight routes:"),tostring(currentTravel.taxiRoutes or 0))
    LiveKV(T("Hearthstone uses:"),tostring(currentTravel.hearthstoneUses or 0))
    LiveKV(T("Gold balance:"),(cg and ((cg>=0 and "+" or "-")..money(math.abs(cg))) or T("not recorded")))
    local currentLooted=db.goldLooted and db.goldLooted.byLevel and db.goldLooted.byLevel[currentLevel] or 0
    LiveKV(T("Looted gold:"),money(currentLooted))
    local topKill=MCF.GetTopMob and MCF:GetTopMob(currentActivity.mobKillTypes) or nil
    local fear=MCF.GetTopMob and MCF:GetTopMob(currentActivity.deathsByMob) or nil
    local qlLive=MCF:GetOldestActiveQuest(db)
    LiveKV(T("Longest in quest log:"),qlLive and MCF:FormatQuestLogRecordShort(qlLive) or "-")
    LiveKV(T("Defeated mobs:"),tostring(tonumber(currentActivity.mobKills) or 0))
    LiveKV(T("Most defeated mob:"),MCF:FormatTopMob(topKill,"x"))
    LiveKV(T("Nemesis:"),MCF:FormatTopMob(fear," "..T("Deaths")))

    levelRows[#levelRows+1]=live; y=y-292

    AddText(T("COMPLETED LEVEL SECTIONS"),8,550,y,"GameFontNormal"); y=y-24

    local rows={}
    for level,e in pairs(db.levels or {}) do
        if e.reached then rows[#rows+1]={level=tonumber(level) or 0,e=e} end
    end
    table.sort(rows,function(a,b) return a.level>b.level end)
    if #rows==0 then AddText(T("No recorded level-ups yet."),8,550,y,"GameFontHighlight"); return math.abs(y)+50 end

    local labelX,valueX=28,300
    local labelW,valueW=255,220
    local rowH=17
    local function KV(label,value,hint)
        local rowY=y
        if hint then label=label.." "..MCF.Kit.Hint.Mark end
        local hl=child:CreateTexture(nil,"BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(1,1,1,0.08)
        hl:SetPoint("TOPLEFT",24,rowY+2); hl:SetSize(505,rowH); hl:Hide()
        levelRows[#levelRows+1]=hl
        local left=AddText(label,labelX,labelW,rowY,"GameFontNormal")
        local right=AddText(value,valueX,valueW,rowY,"GameFontHighlight")
        right:SetJustifyH("RIGHT")
        right:SetWordWrap(true)
        right:SetNonSpaceWrap(true)
        local hit=CreateFrame("Frame",nil,child)
        hit:SetPoint("TOPLEFT",24,rowY+2); hit:SetSize(505,rowH); hit:EnableMouse(true)
        hit:SetFrameLevel(child:GetFrameLevel()+20)
        hit:SetScript("OnEnter",function(self) hl:Show(); if hint then MCF.Kit.Hint.Show(self) end end)
        hit:SetScript("OnLeave",function() hl:Hide(); GameTooltip:Hide() end)
        levelRows[#levelRows+1]=hit
        y=y-rowH
    end

    for _,row in ipairs(rows) do
        local level,e=row.level,row.e
        local prev=db.levels and db.levels[level-1]
        local snapshot=db.levelSnapshots and db.levelSnapshots[level]
        local shot=nil
        for _,ss in ipairs(db.screenshots or {}) do
            if ss.reason=="LEVEL_UP" and tonumber(ss.level)==level then shot=ss; break end
        end
        local activity=db.levelActivity and db.levelActivity[level-1] or {}
        local quests=activity.quests or {}
        local deaths=activity.deaths or {}
        local activityDungeons=activity.dungeons or {}
        local dungeons={}
        for runIndex,run in ipairs(db.dungeons or {}) do
            if tonumber(run.levelEntered)==tonumber(level-1) then
                local item={}; for k,v in pairs(run) do item[k]=v end
                item.runIndex=runIndex; dungeons[#dungeons+1]=item
            end
        end
        -- Use actual persisted runs as the source for the dungeon list.
        -- Older activity-only records have no full run to open.
        if #dungeons==0 then dungeons=activityDungeons end
        local bosses=activity.bosses or {}
        local sessions=activity.sessions or {}
        local zoneList={}
        for zone,zdata in pairs(activity.zones or {}) do
            zoneList[#zoneList+1]={zone=zone,firstEver=zdata.firstEver,time=zdata.first}
        end
        table.sort(zoneList,function(a,b) return (a.time or 0)<(b.time or 0) end)
        local bossKills={}; for _,b in ipairs(bosses) do if b.success then bossKills[#bossKills+1]=b end end

        local stateKey=tostring(level)..":tree"
        local expanded=levelBlockExpanded[stateKey] and true or false

        -- Entire header row is clickable; +/- is the familiar WoW tree affordance.
        local toggle=CreateFrame("Button",nil,child)
        toggle:SetSize(510,24); toggle:SetPoint("TOPLEFT",8,y+4)
        toggle:EnableMouse(true)
        local marker=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        marker:SetPoint("LEFT",2,0); marker:SetText(expanded and "|cffffcc00-|r" or "|cffffcc00+|r")
        local title=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("LEFT",22,0); title:SetText(T("Level").." "..level.." "..T("reached")); title:SetTextColor(1,1,1)
        local meta=toggle:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        meta:SetPoint("RIGHT",-4,0)
        local snapshotItemLevel = snapshot and tonumber(snapshot.averageItemLevel)
        if snapshotItemLevel then
            meta:SetText(string.format("%s %.1f  |  %s", T("Itemlevel:"), snapshotItemLevel, fmtDate(e.reached)))
        else
            meta:SetText(fmtDate(e.reached).."  -  "..(e.zone or "?"))
        end
        toggle:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        toggle:SetScript("OnClick",function()
            levelBlockExpanded[stateKey]=not levelBlockExpanded[stateKey]
            MCF:RefreshUI()
        end)
        levelRows[#levelRows+1]=toggle
        y=y-28

        if expanded then
            local pos=(e.x and e.y) and string.format(" (%.1f, %.1f)",e.x*100,e.y*100) or ""
            KV(T("Reached on: "),fmtDate(e.reached))
            KV(T("Location: "),(e.zone or "?")..pos)
            KV(T("Time on Level ")..(level-1)..":",prev and prev.duration and MCF:FormatDuration(prev.duration) or "-")
            local afk=MCF.GetAFKTimeForLevel and MCF:GetAFKTimeForLevel(level-1)
            if afk~=nil and prev and prev.duration then
                local total=tonumber(prev.duration) or 0
                KV(T("AFK time:"),MCF:FormatDuration(afk).." ("..string.format("%.1f%%",total>0 and afk/total*100 or 0)..")")
                KV(T("Active time:"),MCF:FormatDuration(math.max(0,total-afk)))
            end
            local summary=#quests.." "..T("Quests").."  |  "..#deaths.." "..T("Deaths").."  |  "..#dungeons.." "..T("Dungeons")
            KV(T("Activity:"),summary)
            if snapshot and tonumber(snapshot.averageItemLevel) then
                KV(T("Average item level:"),string.format("%.1f",tonumber(snapshot.averageItemLevel)))
            end

            local questXP=0; for _,q in ipairs(quests) do questXP=questXP+(tonumber(q.xp) or 0) end
            if tonumber(activity.requiredXP) and activity.requiredXP>0 then
                local req=tonumber(activity.requiredXP)
                KV(T("Quest XP:"),string.format("%d (%.1f%%)",questXP,questXP/req*100))
                KV(T("Other XP:"),string.format("%d (%.1f%%)",math.max(0,req-questXP),math.max(0,req-questXP)/req*100))
            end
            local completed=0; for _,r in ipairs(dungeons) do if r.completed then completed=completed+1 end end
            KV(T("Dungeon completions:"),completed)
            KV(T("Boss kills:"),#bossKills)
            local topKill=MCF.GetTopMob and MCF:GetTopMob(activity.mobKillTypes) or nil
            local fear=MCF.GetTopMob and MCF:GetTopMob(activity.deathsByMob) or nil
            local qlRec=db.tracking and db.tracking.quests and db.tracking.quests.byLevel and db.tracking.quests.byLevel[level-1]
            KV(T("Longest in quest log:"),qlRec and MCF:FormatQuestLogRecordShort(qlRec) or "-")
            KV(T("Defeated mobs:"),tostring(tonumber(activity.mobKills) or 0))
            KV(T("Most defeated mob:"),MCF:FormatTopMob(topKill,"x"))
            KV(T("Nemesis:"),MCF:FormatTopMob(fear," "..T("Deaths")))
            KV(T("Sessions:"),#sessions)
            KV(T("Zones visited:"),#zoneList)
            local travelLevel=db.travel and db.travel.byLevel and db.travel.byLevel[level-1] or {}
            KV(T("Ground distance:"),MCF:FormatDistance(travelLevel.groundYards or 0))
            KV(T("Flight routes:"),tostring(travelLevel.taxiRoutes or 0))
            KV(T("Hearthstone uses:"),tostring(travelLevel.hearthstoneUses or 0))
            KV(T("Flight distance:"),MCF:FormatDistance(travelLevel.taxiYards or 0))
            KV(T("Flight time:"),MCF:FormatDuration(travelLevel.taxiSeconds or 0))
            local goldLevel=db.goldByLevel and db.goldByLevel[level-1]
            if goldLevel then
                local earned,spent=goldLevel.earned or 0,goldLevel.spent or 0
                KV(T("Gold earned:"),money(earned))
                KV(T("Gold spent:"),money(spent))
                local balance=earned-spent
                KV(T("Gold balance:"),(balance>=0 and "+" or "-")..money(math.abs(balance)))
            else
                KV(T("Gold earned:"),T("not recorded"))
                KV(T("Gold spent:"),T("not recorded"))
                KV(T("Gold balance:"),T("not recorded"))
            end

            local lootedLevel=db.goldLooted and db.goldLooted.byLevel and db.goldLooted.byLevel[level-1] or 0
            KV(T("Looted gold:"),money(lootedLevel))

            local duelLevel=db.duels and db.duels.byLevel and db.duels.byLevel[level] or {}
            KV(T("Duels:"),tostring(duelLevel.total or 0).."  |  "..T("Wins").." "..tostring(duelLevel.wins or 0).."  |  "..T("Losses").." "..tostring(duelLevel.losses or 0))

            local levelShots={}
            for _,ss in ipairs(db.screenshots or {}) do if tonumber(ss.level)==tonumber(level) then levelShots[#levelShots+1]=ss end end
            KV(T("Screenshots on this level:"),tostring(#levelShots),true)

            local journalCount=0
            for _,j in ipairs(db.journal or {}) do if tonumber(j.level)==tonumber(level) then journalCount=journalCount+1 end end
            KV(T("Journal entries on this level:"),tostring(journalCount))

            local newZones={}
            for _,z in ipairs(zoneList) do if z.firstEver then newZones[#newZones+1]=z.zone end end
            KV(T("New zones discovered:"),#newZones>0 and table.concat(newZones,", ") or "-")

            local profState={}
            local levelSnap=db.levelSnapshots and db.levelSnapshots[level]
            for _,p in pairs(levelSnap and levelSnap.professions or {}) do
                profState[#profState+1]=MCF:ProfessionName(p.key,p.name or "?").." "..tostring(p.skill or 0).."/"..tostring(p.maxSkill or 0)
            end
            table.sort(profState)
            KV(T("Profession skill at level-up:"),#profState>0 and table.concat(profState,"  |  ") or T("not recorded"))

            local profParts={}
            for _,m in ipairs(db.professions and db.professions.milestones or {}) do
                if tonumber(m.level)==tonumber(level) then
                    local n=MCF:ProfessionName(m.key,m.name or m.profession or "?")
                    local val=m.skill or m.value or m.threshold or m.cap
                    profParts[#profParts+1]=val and (n.." "..tostring(val)) or n
                end
            end
            KV(T("Profession milestones:"),#profParts>0 and table.concat(profParts,", ") or "-")

            -- Specialized child views share one horizontal button row.
            local x=labelX
            if #quests>0 then
                local b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
                b:SetSize(145,20); b:SetPoint("TOPLEFT",x,y-1); b:SetText(T("Show quest list"))
                b:SetScript("OnClick",function() ShowQuestList(level,quests) end)
                levelRows[#levelRows+1]=b; x=x+151
            end
            if #dungeons>0 then
                local b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
                b:SetSize(145,20); b:SetPoint("TOPLEFT",x,y-1); b:SetText(T("Show dungeon list"))
                b:SetScript("OnClick",function() OpenLevelDungeonRuns(level-1) end)
                levelRows[#levelRows+1]=b; x=x+151
            end
            if #levelShots>0 then
                local b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
                b:SetSize(165,20); b:SetPoint("TOPLEFT",x,y-1); b:SetText(T("Show screenshot files"))
                b:SetScript("OnClick",function() ShowLevelScreenshotFiles(level,levelShots) end)
                levelRows[#levelRows+1]=b
            end
            if #levelShots>0 or #quests>0 or #dungeons>0 then y=y-28 end
        end

        local divider=child:CreateTexture(nil,"ARTWORK")
        divider:SetTexture("Interface\\Buttons\\WHITE8X8"); divider:SetVertexColor(0.45,0.45,0.45,0.35)
        divider:SetSize(510,1); divider:SetPoint("TOPLEFT",8,y-6)
        levelRows[#levelRows+1]=divider; y=y-18
    end

    AddText(T("ARCHIVE"),8,550,y,"GameFontNormal"); y=y-22
    KV(T("Recorded level-ups: "),tostring(#rows))
    local snapCount=0; for _ in pairs(db.levelSnapshots or {}) do snapCount=snapCount+1 end
    KV(T("Level snapshots: "),tostring(snapCount))
    KV(T("Screenshot records: "),tostring(#(db.screenshots or {})))
    return math.abs(y)+35
end

local reputationRows={}
local reputationExpanded={}
local function ClearReputationRows()
    for _,r in ipairs(reputationRows) do MCF.Retire(r) end
    wipe(reputationRows)
end
local function ReputationStanding(id)
    local k={[1]="Hated",[2]="Hostile",[3]="Unfriendly",[4]="Neutral",[5]="Friendly",[6]="Honored",[7]="Revered",[8]="Exalted"}
    return T(k[tonumber(id) or 0] or "?")
end
local function DrawReputationRows(db)
    ClearReputationRows()
    local y=-5
    local function Txt(v,x,w,yp,font)
        local f=child:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight"); f:SetPoint("TOPLEFT",x,yp); f:SetWidth(w); f:SetJustifyH("LEFT"); f:SetText(v or ""); reputationRows[#reputationRows+1]=f; return f
    end
    Txt(T("REPUTATION PROGRESS"),8,620,y,"GameFontNormal"); y=y-24
    local desc=Txt(T("Reputation milestone description"),8,620,y,"GameFontHighlight")
    desc:SetWordWrap(true)
    desc:SetNonSpaceWrap(true)
    y=y-62
    local current=db.reputation and db.reputation.current or {}
    local list={}; for _,r in pairs(current) do list[#list+1]=r end
    table.sort(list,function(a,b) return (a.name or "")<(b.name or "") end)
    if #list==0 then Txt(T("No reputation recorded yet."),8,550,y); return math.abs(y)+40 end
    for _,r in ipairs(list) do
        local key=r.key or r.name; local expanded=reputationExpanded[key]
        local row=CreateFrame("Button",nil,child); row:SetSize(540,28); row:SetPoint("TOPLEFT",8,y); row:EnableMouse(true)
        local hi=row:CreateTexture(nil,"BACKGROUND"); hi:SetAllPoints(); hi:SetTexture("Interface\\Buttons\\WHITE8X8"); hi:SetVertexColor(1,1,1,.08); hi:Hide()
        row:SetScript("OnEnter",function() hi:Show() end); row:SetScript("OnLeave",function() hi:Hide() end)
        local n=row:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge"); n:SetPoint("LEFT",20,0); n:SetText((expanded and "- " or "+ ")..(r.name or "?"))
        local st=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); st:SetPoint("RIGHT",-10,0); st:SetText(ReputationStanding(r.standingID))
        row:SetScript("OnClick",function() reputationExpanded[key]=not reputationExpanded[key]; MCF:RefreshUI() end)
        reputationRows[#reputationRows+1]=row; y=y-31
        if expanded then
            local ms={}
            for _,m in ipairs(db.reputation and db.reputation.milestones or {}) do if m.key==key then ms[#ms+1]=m end end
            table.sort(ms,function(a,b) return (a.time or 0)<(b.time or 0) end)
            for _,m in ipairs(ms) do
                local label=(m.kind=="FIRST_SEEN") and T("First recorded") or ReputationStanding(m.standingID)
                Txt(label,38,180,y,"GameFontNormal"); Txt(fmtDate(m.time).."  |  "..T("Level").." "..tostring(m.level or "?").."  |  "..tostring(m.zone or ""),225,315,y,"GameFontHighlight")
                y=y-20
            end
        end
        local line=child:CreateTexture(nil,"ARTWORK"); line:SetTexture("Interface\\Buttons\\WHITE8X8"); line:SetVertexColor(.4,.4,.4,.25); line:SetSize(530,1); line:SetPoint("TOPLEFT",12,y); reputationRows[#reputationRows+1]=line; y=y-8
    end
    return math.abs(y)+35
end


local iconicRows={}
local function ClearIconicRows()
    for _,r in ipairs(iconicRows) do MCF.Retire(r) end
    wipe(iconicRows)
end
local ICONIC_GROUPS=MCF.IconicGroups -- single source: Iconic.lua
local function DrawIconicRows(db)
    ClearIconicRows()
    local german=MCF:GetLanguage()=="deDE"
    local y=-5
    local function Txt(v,x,w,yp,font)
        local f=child:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight"); f:SetPoint("TOPLEFT",x,yp); f:SetWidth(w); f:SetJustifyH("LEFT"); f:SetText(v or ""); iconicRows[#iconicRows+1]=f; return f
    end
    local found,total=MCF:GetIconicFound()
    Txt((german and "IKONISCHE MOMENTE" or "ICONIC MOMENTS").."  |cffffd100"..found.." / "..total.."|r",8,620,y,"GameFontNormal"); y=y-24
    local d=Txt(german and "Die Augenblicke, die jeder Azeroth-Reisende kennt: legendäre Gegner, berühmte Orte und Sammelstücke. Erkannt werden sie über die Namen im Spiel; bei Abweichungen hilft /mcf iconic." or "The moments every Azeroth traveler knows: legendary foes, famous places and collectibles. They are recognised by in-game names; /mcf iconic helps if something does not trigger.",8,620,y)
    d:SetWordWrap(true); y=y-48
    local list=MCF:GetIconicList()
    for _,g in ipairs(ICONIC_GROUPS) do
        local n,k=0,0
        for _,row in ipairs(list) do if row.def.group==g[1] then n=n+1; if row.found then k=k+1 end end end
        if n>0 then
            Txt((german and g[2] or g[3]).."  |cff9d9d9d"..k.." / "..n.."|r",8,620,y,"GameFontNormalLarge"); y=y-26
            for _,row in ipairs(list) do
                if row.def.group==g[1] then
                    local def,e=row.def,row.entry
                    local card=CreateFrame("Frame",nil,child,"BackdropTemplate"); card:SetSize(580,56); card:SetPoint("TOPLEFT",8,y)
                    card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
                    if row.found then card:SetBackdropColor(0.10,0.18,0.10,0.9); card:SetBackdropBorderColor(0.25,0.6,0.25,1)
                    else card:SetBackdropColor(0.08,0.08,0.08,0.8); card:SetBackdropBorderColor(0.25,0.25,0.25,1) end
                    local title=card:CreateFontString(nil,"OVERLAY","GameFontNormal"); title:SetPoint("TOPLEFT",10,-8); title:SetWidth(380); title:SetJustifyH("LEFT")
                    title:SetText((row.found and "|cff44ff44[x]|r " or "|cff777777[ ]|r ")..(german and def.de or def.en))
                    local desc=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); desc:SetPoint("TOPLEFT",10,-28); desc:SetWidth(400); desc:SetJustifyH("LEFT")
                    desc:SetText(german and def.deDesc or def.enDesc)
                    desc:SetTextColor(row.found and 0.85 or 0.55,row.found and 0.85 or 0.55,row.found and 0.85 or 0.55)
                    local info=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); info:SetPoint("TOPRIGHT",-10,-10); info:SetWidth(150); info:SetJustifyH("RIGHT")
                    if row.found then
                        local f=e.first or {}
                        local cnt=row.total and ("|cff44ff44"..row.progress.." / "..row.total.."|r\n") or ""
                        info:SetText(cnt.."|cff9d9d9d"..(f.time and date(german and "%d.%m.%Y" or "%Y-%m-%d",f.time) or "")..(f.level and ("  Lv "..f.level) or "").."|r\n|cff9d9d9d"..(f.subZone and f.subZone~="" and f.subZone or f.zone or "").."|r")
                    else
                        info:SetText(row.total and ("|cff777777"..(row.progress or 0).." / "..row.total.."|r") or ("|cff777777"..(german and "Noch nicht" or "Not yet").."|r"))
                    end
                    local lore=german and def.deLore or def.enLore
                    if lore then
                        card:EnableMouse(true)
                        card:SetScript("OnEnter",function(self)
                            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                            GameTooltip:SetText(german and def.de or def.en,1,0.82,0.2)
                            GameTooltip:AddLine(lore,1,1,1,true)
                            GameTooltip:Show()
                        end)
                        card:SetScript("OnLeave",function() GameTooltip:Hide() end)
                    end
                    iconicRows[#iconicRows+1]=card; y=y-62
                end
            end
            y=y-8
        end
    end
    return math.abs(y)+35
end

local professionRows={}
local professionBlockExpanded={}
local function ClearProfessionRows()
    for _,row in ipairs(professionRows) do MCF.Retire(row) end
    wipe(professionRows)
end

local function ProfessionRankName(cap)
    cap=tonumber(cap) or 0
    if cap<=75 then return T("Apprentice") end
    if cap<=150 then return T("Journeyman") end
    if cap<=225 then return T("Expert") end
    return T("Artisan")
end

local craftedItemsExpanded=true
local function GetCraftedItemRows(db)
    local result={}
    local items=db.crafting and db.crafting.items or {}
    for key,entry in pairs(items) do
        if type(entry)=="table" then
            local qty=tonumber(entry.quantity) or 0
            if qty>0 then
                local id=tonumber(entry.itemID) or tonumber(key)
                local name
                if id and GetItemInfo then name=GetItemInfo(id) end
                if not name and type(entry.hyperlink)=="string" then
                    name=entry.hyperlink:match("%[([^%]]+)%]")
                end
                name=name or (id and (T("Item").." #"..id) or tostring(key))
                result[#result+1]={name=name,quantity=qty,id=id,link=entry.hyperlink}
            end
        end
    end
    table.sort(result,function(a,b)
        if a.quantity~=b.quantity then return a.quantity>b.quantity end
        return a.name:lower()<b.name:lower()
    end)
    return result
end

local function DrawProfessionRows(db)
    ClearProfessionRows()
    local y=-5
    local function AddText(value,x,width,ypos,font)
        local fs=child:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
        fs:SetPoint("TOPLEFT",x,ypos); fs:SetWidth(width)
        fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetText(value or "")
        professionRows[#professionRows+1]=fs
        return fs
    end
    AddText(T("PROFESSION PROGRESS"),8,550,y,"GameFontNormal"); y=y-20
    AddText(T("Profession progress description"),8,550,y,"GameFontHighlight"); y=y-28

    local pdata=db.professions or {}
    local rows={}
    -- Dropped professions stay listed (marked): everything recorded for them is kept.
    for _,pr in pairs(pdata.current or {}) do rows[#rows+1]=pr end
    table.sort(rows,function(a,b)
        if (a.unlearned and true or false)~=(b.unlearned and true or false) then return not a.unlearned end
        return MCF:ProfessionName(a.key,a.name or "")<MCF:ProfessionName(b.key,b.name or "")
    end)
    if #rows==0 then AddText(T("No professions recorded yet."),8,550,y,"GameFontHighlight"); y=y-35 end

    for _,pr in ipairs(rows) do
        local stateKey=tostring(pr.key or pr.name)
        local expanded=professionBlockExpanded[stateKey] and true or false
        local toggle=CreateFrame("Button",nil,child)
        toggle:SetSize(510,24); toggle:SetPoint("TOPLEFT",8,y+4)
        local marker=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        marker:SetPoint("LEFT",2,0); marker:SetText(expanded and "|cffffcc00-|r" or "|cffffcc00+|r")
        local title=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("LEFT",22,0); title:SetText(MCF:ProfessionName(pr.key,pr.name or "?")..(pr.unlearned and (" |cff888888("..T("unlearned")..")|r") or "")); title:SetTextColor(1,1,1)
        local value=toggle:CreateFontString(nil,"OVERLAY","GameFontNormal")
        value:SetPoint("RIGHT",-4,0); value:SetText((pr.unlearned and "|cff999999" or "|cffffcc00")..tostring(pr.skill or 0).." / "..tostring(pr.maxSkill or 0).."|r")
        toggle:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        toggle:SetScript("OnClick",function()
            professionBlockExpanded[stateKey]=not professionBlockExpanded[stateKey]
            MCF:RefreshUI()
        end)
        professionRows[#professionRows+1]=toggle; y=y-28

        if expanded then
            -- Milestones and the learn / unlearn / relearn events of this profession in one timeline.
            local ms={}
            for _,m in pairs(pdata.milestones or {}) do if m.key==pr.key then ms[#ms+1]=m end end
            for _,h in ipairs(pdata.history or {}) do
                if h.key==pr.key and (h.kind=="UNLEARNED" or h.kind=="RELEARNED") then ms[#ms+1]=h end
            end
            table.sort(ms,function(a,b) return (a.time or 0)<(b.time or 0) end)
            if #ms==0 then
                AddText(T("No professions recorded yet."),30,500,y,"GameFontHighlightSmall"); y=y-16
            else
                for _,m in ipairs(ms) do
                    local what
                    if m.kind=="UNLEARNED" then what="|cffff6666"..T("unlearned").."|r ("..tostring(m.skill or 0).." / "..tostring(m.maxSkill or 0)..")"
                    elseif m.kind=="RELEARNED" then what="|cff66ff66"..T("relearned").."|r"
                    elseif m.kind=="CAP" then what=ProfessionRankName(m.value).." ("..tostring(m.value)..")"
                    elseif m.kind=="FIRST_SEEN" then what=T("First recorded")..": "..tostring(m.value or m.skill or 0)
                    else what=tostring(m.value).." "..T("skill reached") end
                    AddText(fmtDate(m.time),30,135,y,"GameFontHighlightSmall")
                    AddText(what,170,245,y,"GameFontNormal")
                    AddText(T("Level").." "..tostring(m.level or "?"),420,90,y,"GameFontHighlightSmall")
                    y=y-17
                end
            end
        end
        local divider=child:CreateTexture(nil,"ARTWORK")
        divider:SetTexture("Interface\\Buttons\\WHITE8X8"); divider:SetVertexColor(0.45,0.45,0.45,0.35)
        divider:SetSize(510,1); divider:SetPoint("TOPLEFT",8,y-6)
        professionRows[#professionRows+1]=divider; y=y-18
    end
    -- Crafted items are aggregated by item ID, not by chat message or spellcast.
    y=y-10
    local crafted=GetCraftedItemRows(db)
    local toggle=CreateFrame("Button",nil,child)
    toggle:SetSize(510,25); toggle:SetPoint("TOPLEFT",8,y+4)
    local marker=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    marker:SetPoint("LEFT",2,0); marker:SetText(craftedItemsExpanded and "|cffffcc00-|r" or "|cffffcc00+|r")
    local title=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("LEFT",22,0); title:SetText(T("Crafted items")); title:SetTextColor(1,1,1)
    toggle:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    toggle:SetScript("OnClick",function() craftedItemsExpanded=not craftedItemsExpanded; MCF:RefreshUI() end)
    professionRows[#professionRows+1]=toggle; y=y-31
    if craftedItemsExpanded then
        AddText(T("Item"),28,370,y,"GameFontNormal")
        local qtyHeader=AddText(T("Crafted quantity"),405,105,y,"GameFontNormal")
        qtyHeader:SetJustifyH("RIGHT")
        y=y-23
        if #crafted==0 then
            AddText(T("No crafted items recorded yet."),28,475,y,"GameFontHighlightSmall")
            y=y-22
        else
            for i,entry in ipairs(crafted) do
                local name=AddText(entry.name,28,365,y,"GameFontHighlight")
                local qty=AddText(tostring(entry.quantity),405,105,y,"GameFontHighlight")
                qty:SetJustifyH("RIGHT")
                y=y-21
            end
        end
    end
    ---------------------------------------------------------------------
    -- Collapsible blocks: gathering, salvaging, skill per level, special recipes
    ---------------------------------------------------------------------
    MCF.professionOpen=MCF.professionOpen or {}
    local function Section(key,titleText,body)
        y=y-10
        local open=MCF.professionOpen[key] and true or false
        local sectionToggle=CreateFrame("Button",nil,child)
        sectionToggle:SetSize(510,25); sectionToggle:SetPoint("TOPLEFT",8,y+4)
        local sectionMarker=sectionToggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        sectionMarker:SetPoint("LEFT",2,0); sectionMarker:SetText(open and "|cffffcc00-|r" or "|cffffcc00+|r")
        local sectionTitle=sectionToggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        sectionTitle:SetPoint("LEFT",22,0); sectionTitle:SetText(titleText); sectionTitle:SetTextColor(1,1,1)
        sectionToggle:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        sectionToggle:SetScript("OnClick",function() MCF.professionOpen[key]=not MCF.professionOpen[key]; MCF:RefreshUI() end)
        professionRows[#professionRows+1]=sectionToggle; y=y-31
        if open then body() end
    end
    local de=MCF:GetLanguage()=="deDE"
    local qualityNames=de and {[0]="Schlecht",[1]="Gewöhnlich",[2]="Ungewöhnlich",[3]="Selten",[4]="Episch",[5]="Legendär"}
        or {[0]="Poor",[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary"}
    local function KindBlock(kinds)
        local shown=0
        for _,kind in ipairs(kinds) do
            local k=MCF:GetGatheringKind(kind)
            if k and (tonumber(k.events) or 0)>0 then
                shown=shown+1
                AddText(T("Kind "..kind),28,300,y,"GameFontNormal")
                local sum=AddText(string.format("%d x  |  %d",tonumber(k.events) or 0,tonumber(k.quantity) or 0),330,175,y,"GameFontHighlight")
                sum:SetJustifyH("RIGHT")
                y=y-21
                if kind=="disenchant" and next(k.bySource or {}) then
                    local parts={}
                    for q=0,5 do local c=k.bySource[tostring(q)]; if c then parts[#parts+1]=qualityNames[q].." "..c end end
                    if #parts>0 then
                        AddText(T("Destroyed items")..": "..table.concat(parts,", "),42,460,y,"GameFontHighlightSmall"); y=y-18
                    end
                end
                for _,row in ipairs(MCF:GetGatheringItems(kind)) do
                    AddText(row.name,42,330,y,"GameFontHighlightSmall")
                    local q=AddText(tostring(row.quantity),380,125,y,"GameFontHighlightSmall"); q:SetJustifyH("RIGHT")
                    y=y-17
                end
                y=y-8
            end
        end
        if shown==0 then AddText(T("Nothing recorded yet."),28,475,y,"GameFontHighlightSmall"); y=y-22 end
    end
    local function Relevant(kinds)
        local out={}
        for _,kind in ipairs(kinds) do if MCF:IsGatheringKindRelevant(kind) then out[#out+1]=kind end end
        return out
    end
    local gatherKinds,salvageKinds=Relevant(MCF.GatherKinds),Relevant(MCF.SalvageKinds)
    if #gatherKinds>0 then Section("gathered",T("Gathered resources"),function() KindBlock(gatherKinds) end) end
    if #salvageKinds>0 then
        local names={}
        for _,kind in ipairs(salvageKinds) do names[#names+1]=T("Kind "..kind) end
        Section("salvaged",table.concat(names,", "),function() KindBlock(salvageKinds) end)
    end

    Section("skillbylevel",T("Skill per level"),function()
        local byLevel=pdata.byLevel or {}
        local levels={}
        for lvl in pairs(byLevel) do levels[#levels+1]=tonumber(lvl) end
        table.sort(levels)
        local keys,names={}, {}
        for _,lvl in ipairs(levels) do
            for key,v in pairs(byLevel[lvl] or byLevel[tostring(lvl)] or {}) do
                if not names[key] then names[key]=MCF:ProfessionName(key,(pdata.current and pdata.current[key] and pdata.current[key].name) or v.name or "?"); keys[#keys+1]=key end
            end
        end
        table.sort(keys,function(a,b) return names[a]<names[b] end)
        if #levels==0 or #keys==0 then AddText(T("No profession skill recorded yet."),28,475,y,"GameFontHighlightSmall"); y=y-22; return end
        local colWidth=math.min(110,math.floor(430/math.max(1,#keys)))
        AddText(T("Level"),28,60,y,"GameFontNormal")
        for i,key in ipairs(keys) do
            local h=AddText(names[key],90+(i-1)*colWidth,colWidth-4,y,"GameFontNormalSmall"); h:SetWordWrap(false)
        end
        y=y-20
        for _,lvl in ipairs(levels) do
            AddText(tostring(lvl),28,60,y,"GameFontHighlightSmall")
            local row=byLevel[lvl] or byLevel[tostring(lvl)] or {}
            for i,key in ipairs(keys) do
                local v=row[key]
                AddText(v and (tostring(v.skill or 0).." / "..tostring(v.maxSkill or 0)) or "-",90+(i-1)*colWidth,colWidth-4,y,"GameFontHighlightSmall")
            end
            y=y-17
        end
    end)

    Section("recipes",T("Special recipes"),function()
        local list=pdata.recipes or {}
        if #list==0 then AddText(T("No special recipes recorded yet."),28,475,y,"GameFontHighlightSmall"); y=y-22; return end
        for i=#list,1,-1 do
            local r=list[i]
            AddText(fmtDate(r.time),28,135,y,"GameFontHighlightSmall")
            AddText(r.name or "?",170,250,y,"GameFontNormal")
            AddText(T("Level").." "..tostring(r.level or "?").." - "..(r.source=="VENDOR" and T("Vendor") or T("Found or rewarded")),425,130,y,"GameFontHighlightSmall")
            y=y-17
        end
    end)
    return math.abs(y)+35
end

local function professionHistory(db)
    local p=db.professions or {}
    local current=p.current or {}
    local milestones=p.milestones or {}
    local out={}
    local function L(x) out[#out+1]=x or "" end
    L("|cffffcc00"..T("PROFESSION PROGRESS").."|r")
    L(T("Profession progress description"))
    L("")

    local rows={}
    for _,v in pairs(current) do rows[#rows+1]=v end
    table.sort(rows,function(a,b) return MCF:ProfessionName(a.key,a.name or "")<MCF:ProfessionName(b.key,b.name or "") end)
    if #rows==0 then L(T("No professions recorded yet.")) end

    for _,pr in ipairs(rows) do
        L("|cffffffff"..MCF:ProfessionName(pr.key,pr.name or "?")..(pr.unlearned and (" ("..T("unlearned")..")") or "").."|r   |cffffcc00"..tostring(pr.skill or 0).." / "..tostring(pr.maxSkill or 0).."|r")
        local ms={}
        for _,m in pairs(milestones) do
            if m.key==pr.key then ms[#ms+1]=m end
        end
        table.sort(ms,function(a,b) return (a.time or 0)<(b.time or 0) end)
        for _,m in ipairs(ms) do
            local what
            if m.kind=="CAP" then
                what=T("Skill cap").." "..tostring(m.value)
            elseif m.kind=="FIRST_SEEN" then
                what=T("First recorded")..": "..tostring(m.value or m.skill or 0)
            else
                what=tostring(m.value).." "..T("skill reached")
            end
            L("  |cffaaaaaa"..fmtDate(m.time).."|r  "..what.."  |cffaaaaaa("..T("Level").." "..tostring(m.level or "?")..")|r")
        end
        L("")
    end

    L("")
    L("|cffffcc00"..T("Crafted items").."|r")
    L(T("Item").."  |  "..T("Crafted quantity"))
    local crafted=GetCraftedItemRows(db)
    if #crafted==0 then L(T("No crafted items recorded yet.")) end
    for _,entry in ipairs(crafted) do L(entry.name.."  |  "..tostring(entry.quantity)) end
    local history=p.history or {}
    if #history>0 then
        L("|cffffffff"..T("Profession history").."|r")
        for i=math.max(1,#history-9),#history do
            local h=history[i]
            local action=h.kind=="LEARNED" and T("learned")
                or h.kind=="UNLEARNED" and T("unlearned")
                or h.kind=="RELEARNED" and T("relearned")
                or h.kind=="CAP_CHANGED" and T("skill cap increased")
                or T("first recorded")
            L(fmtDate(h.time).."  "..MCF:ProfessionName(h.key,h.name or "?").." - "..action)
        end
    end
    return table.concat(out,"\n")
end

local function BuildText()
    if not MyCharForeverDB then return "Database not initialized." end
    local db=MyCharForeverDB
    if viewMode=="levels" then
        return levelUpHistory(db)
    elseif viewMode=="journal" then
        return journalHistory(db)
    elseif viewMode=="gold" then
        return goldSummaryText(db)
    elseif viewMode=="dungeons" then
        return "" -- the dungeon view draws its own rows (there is no text version)
    elseif viewMode=="professions" then
        return professionHistory(db)
    elseif viewMode=="screenshots" then
        return ""
    end
    local lvl=UnitLevel("player")
    local longestLvl,longest=longestLevel(db)
    local total=(MCF.GetLivePlayedTime and MCF:GetLivePlayedTime()) or MCF.totalPlayed or 0
    local avg=0
    local done=completedLevels(db)
    if done>0 then
        local sum=0
        for _,e in pairs(db.levels or {}) do if e.completed then sum=sum+(e.duration or 0) end end
        avg=sum/done
    end
    local currentSession=(MCF.GetLiveSessionTime and MCF:GetLiveSessionTime()) or (MCF.sessionStartTime and (GetTime()-MCF.sessionStartTime) or 0)
    local uniqueMaps={}
    for _,p in ipairs(db.journey or {}) do local mapID=p.m or p.mapID; if mapID then uniqueMaps[mapID]=true end end
    local mapCount=0; for _ in pairs(uniqueMaps) do mapCount=mapCount+1 end

    local left,right={},{}
    local function H(tbl,x) tbl[#tbl+1]="|cffffffff"..x.."|r" end
    local function L(tbl,x) tbl[#tbl+1]=x end

    -- LEFT COLUMN: character, playtime, exploration
    H(left,T("CHARACTER"))
    L(left,(MCF:RaceName(db.character.raceFile,db.character.race) or "?").." "..(MCF:ClassName(db.character.classFile,db.character.class) or "?").."  |  "..T("Level").." "..lvl)
    L(left,T("First tracked: ")..fmtDate(db.character.created)); L(left,"")

    H(left,T("GUILD"))
    local gd=db.guild or {}
    local gc=gd.current
    if gc then
        L(left,T("Current guild: ")..(gc.name or "?"))
        L(left,T("Guild rank: ")..(gc.rankName or "?"))
        local since=gc.joinedAt or gc.firstSeen
        if gc.joinedAt then L(left,T("Guild member since: ")..fmtDate(since))
        elseif gc.firstSeen then L(left,T("Guild first recorded: ")..fmtDate(since)) end
    else
        L(left,T("No guild membership recorded."))
    end
    local gh=gd.history or {}
    if #gh>0 then
        L(left,T("Guild history:"))
        L(left,"__MCFGUILDHEADER__")
        for i=math.max(1,#gh-5),#gh do
            local e=gh[i]
            local action
            if e.kind=="JOINED" then action=T("Joined guild")
            elseif e.kind=="LEFT" then action=T("Left guild")
            elseif e.kind=="RANK_CHANGED" then action=T("Guild rank changed")
            else action=T("Guild first recorded") end
            local detail=e.guild or "?"
            if e.kind=="RANK_CHANGED" and e.rankName then detail=detail.." ("..e.rankName..")" end
            L(left,"__MCFGUILDROW__\t"..fmtDate(e.time).."\t"..action.."\t"..detail.."\t"..tostring(e.level or "?"))
        end
    end
    L(left,"")

    H(left,T("PLAYTIME"))
    L(left,T("Total /played: ")..MCF:FormatDuration(total))
    local totalAFK=MCF.GetTotalAFKTime and MCF:GetTotalAFKTime()
    if totalAFK~=nil then
        local afkRatio=total>0 and (totalAFK/total*100) or 0
        L(left,T("AFK time: ")..MCF:FormatDuration(totalAFK).." ("..string.format("%.1f%%",afkRatio)..")")
        L(left,T("Active play time:").." "..MCF:FormatDuration(math.max(0,total-totalAFK))..
            (total>0 and (" ("..string.format("%.1f%%",100-afkRatio)..")") or ""))
    else
        L(left,T("AFK time: ")..T("not recorded"))
    end
    local still=MCF.GetStationaryTotal and MCF:GetStationaryTotal()
    if still and still>0 then
        L(left,T("Stationary time: ")..MCF:FormatDuration(still).." ("..string.format("%.1f%%",total>0 and still/total*100 or 0)..")")
        local longest,longestLevel=MCF:GetLongestStationary()
        if longest then L(left,T("Longest stationary stretch: ")..MCF:FormatDuration(longest).." ("..T("Level").." "..tostring(longestLevel or "?")..")") end
    end
    L(left,T("Current session: ")..MCF:FormatDuration(currentSession))
    L(left,T("Time this level: ")..MCF:FormatDuration(MCF:GetCurrentLevelDuration()))
    L(left,T("Tracked sessions: ")..#(db.sessions or {}))
    if #(db.sessions or {})>0 then
        L(left,T("Average session: ")..MCF:FormatDuration((MCF.GetAverageSessionTime and MCF:GetAverageSessionTime()) or 0))
    end
    L(left,"")

    H(left,T("ARCHIVE / DATA"))
    L(left,T("Timeline events: ")..#(db.events or {}))
    L(left,T("Journal entries: ")..#(db.journal or {}))
    L(left,T("Screenshot records: ")..#(db.screenshots or {}))
    local snapCount=0; for _ in pairs(db.levelSnapshots or {}) do snapCount=snapCount+1 end
    L(left,T("Level snapshots: ")..snapCount)
    L(left,T("Journey tracking: ")..(db.settings.trackJourney and T("ON") or T("OFF")))
    L(left,T("Level-up screenshots: ")..(db.settings.levelScreenshots and T("ON") or T("OFF")))
    L(left,T("Database version: ")..tostring(db.dbVersion))
    L(left,T("Addon version: ")..MCF.VERSION)

    -- RIGHT COLUMN: leveling, adventure, location statistics
    H(right,T("LEVELING"))
    L(right,T("Level-ups tracked: ")..(db.stats.levelUps or 0))
    L(right,T("Completed level records: ")..done)
    L(right,T("Average time / completed level: ")..MCF:FormatDuration(avg))
    if longestLvl then L(right,T("Longest tracked level: ")..longestLvl.." ("..MCF:FormatDuration(longest)..")") end
    if done==0 then L(right,T("No completed levels yet.")) end
    L(right,"")

    H(right,T("ADVENTURE"))
    L(right,T("Deaths: ")..(db.stats.deaths or 0))
    local combat=db.combat or {}; local kills=combat.kills or {}
    local topKill=MCF.GetTopMob and MCF:GetTopMob(kills.mobs) or nil
    local fear=MCF.GetTopMob and MCF:GetTopMob(combat.deathsByMob) or nil
    local _,_,longestQuest=MCF:GetQuestLogStats(db)
    L(right,T("Longest in quest log:").." "..(longestQuest and MCF:FormatQuestLogRecord(longestQuest) or "-"))
    L(right,T("Defeated mobs: ")..tostring(tonumber(kills.total) or 0))
    L(right,T("Most defeated mob: ")..(MCF:FormatTopMob(topKill,"x")))
    L(right,T("Nemesis: ")..(MCF:FormatTopMob(fear," "..T("Deaths"))))
    local du=db.duels or {}
    L(right,T("Duels: ")..tostring(du.total or 0).."  |  "..T("Wins")..": "..tostring(du.wins or 0).."  |  "..T("Losses")..": "..tostring(du.losses or 0))
    local tr=db.travel or {}
    L(right,T("Ground distance: ")..MCF:FormatDistance(tr.groundYards or 0))
    L(right,T("Flight routes: ")..tostring(tr.taxiRoutes or 0))
    L(right,T("Hearthstone uses: ")..tostring(tr.hearthstoneUses or 0))
    L(right,T("Flight distance: ")..MCF:FormatDistance(tr.taxiYards or 0))
    L(right,T("Flight time: ")..MCF:FormatDuration(tr.taxiSeconds or 0))
    L(right,T("Dungeon visits: ")..(db.stats.dungeonVisits or 0))
    L(right,T("Dungeon completions detected: ")..(db.stats.dungeonCompletions or 0))
    if total>0 then L(right,string.format(T("Deaths / played hour: ").."%.2f",(db.stats.deaths or 0)/(total/3600))) end
    L(right,T("Current money: ")..money(GetMoney()))
    L(right,T("Current zone: ")..(GetZoneText() or "?"))
    local sub=GetSubZoneText(); if sub and sub~="" then L(right,T("Current subzone: ")..sub) end
    L(right,"")

    H(right,T("LOCATION TIMES"))
    local lt=db.locationTime or {}
    local cats=lt.categories or {}
    L(right,T("World: ")..MCF:FormatDuration(cats.world or 0))
    L(right,T("Resting areas: ")..MCF:FormatDuration(cats.resting or 0))
    L(right,T("Dungeons: ")..MCF:FormatDuration(cats.dungeon or 0))
    L(right,T("Raids: ")..MCF:FormatDuration(cats.raid or 0))
    L(right,T("PvP instances: ")..MCF:FormatDuration(cats.pvp or 0))
    L(right,"")

    H(right,T("MOST TIME SPENT"))
    L(right,topZones(db,8))
    L(right,"")

    H(right,T("EXPLORATION"))
    L(right,T("Journey points: ")..#(db.journey or {}))
    L(right,T("Maps with recorded movement: ")..mapCount)
    L(right,T("Zone changes: ")..(db.stats.zoneChanges or 0))
    L(right,T("Map path: ")..((db.settings.showMapJourney~=false) and T("shown") or T("hidden")))

    return table.concat(left,"\n"),table.concat(right,"\n")
end


local characterRows={}
local characterBlockExpanded={}
local function ClearCharacterRows()
    for _,r in ipairs(characterRows) do MCF.Retire(r) end
    wipe(characterRows)
end
local function DrawCharacterRows()
    ClearCharacterRows()
    MCF:UpdateAccountCharacterSummary()
    local rows=MCF:GetAccountCharacters()
    local y=-5
    local function AddText(value,x,w,ypos,font,justify)
        local fs=child:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
        fs:SetPoint("TOPLEFT",x,ypos); fs:SetWidth(w); fs:SetJustifyH(justify or "LEFT"); fs:SetText(value or "")
        characterRows[#characterRows+1]=fs; return fs
    end
    local desc=AddText(T("Characters tab description"),8,540,y,"GameFontHighlightSmall")
    desc:SetTextColor(0.75,0.75,0.75)
    y=y-32
    local function Row(label,value)
        local rowY=y
        local hl=child:CreateTexture(nil,"BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(1,1,1,0.08)
        hl:SetPoint("TOPLEFT",24,rowY+2); hl:SetSize(510,17); hl:Hide()
        characterRows[#characterRows+1]=hl
        AddText(label,28,235,rowY,"GameFontHighlight","LEFT"); AddText(value,275,250,rowY,"GameFontHighlight","RIGHT")
        local hit=CreateFrame("Frame",nil,child); hit:SetPoint("TOPLEFT",24,rowY+2); hit:SetSize(510,17); hit:EnableMouse(true)
        hit:SetFrameLevel(child:GetFrameLevel()+10); hit:SetScript("OnEnter",function() hl:Show() end); hit:SetScript("OnLeave",function() hl:Hide() end)
        characterRows[#characterRows+1]=hit
        y=y-17
    end
    if not modernLayout or not selectedAccountCharacter then
    AddText(T("ACCOUNT SUMMARY"),8,540,y,"GameFontNormal"); y=y-25
    local a={played=0,active=0,afk=0,deaths=0,quests=0,dungeons=0,complete=0,bosses=0,money=0,ground=0,taxi=0,taxiTime=0,sessions=0,screens=0,journal=0}
    local uniqueZones={}
    for _,ch in ipairs(rows) do
        a.played=a.played+(ch.played or 0); a.active=a.active+(ch.activePlayed or 0); a.afk=a.afk+(ch.afk or 0)
        a.deaths=a.deaths+(ch.deaths or 0); a.quests=a.quests+(ch.quests or 0); a.dungeons=a.dungeons+(ch.dungeonVisits or 0)
        a.complete=a.complete+(ch.dungeonCompletions or 0); a.bosses=a.bosses+(ch.bosses or 0); a.money=a.money+(ch.money or 0)
        a.ground=a.ground+(ch.groundYards or 0); a.taxi=a.taxi+(ch.taxiYards or 0); a.taxiTime=a.taxiTime+(ch.taxiSeconds or 0)
        a.sessions=a.sessions+(ch.sessions or 0); a.screens=a.screens+(ch.screenshots or 0); a.journal=a.journal+(ch.journal or 0)
        for z,_ in pairs(ch.zones or {}) do uniqueZones[z]=true end
    end
    local zoneCount=0; for _ in pairs(uniqueZones) do zoneCount=zoneCount+1 end
    Row(T("Tracked characters"),tostring(#rows)); Row(T("Combined /played"),MCF:FormatDuration(a.played)); Row(T("Active play time"),MCF:FormatDuration(a.active))
    Row(T("AFK time"),MCF:FormatDuration(a.afk)); Row(T("Deaths"),tostring(a.deaths)); Row(T("Quests"),tostring(a.quests))
    Row(T("Dungeon visits"),tostring(a.dungeons)); Row(T("Dungeon completions"),tostring(a.complete)); Row(T("Boss kills"),tostring(a.bosses))
    Row(T("Unique zones"),tostring(zoneCount)); Row(T("Combined gold"),money(a.money)); Row(T("Ground distance"),MCF:FormatDistance(a.ground))
    Row(T("Flight distance"),MCF:FormatDistance(a.taxi)); Row(T("Flight time"),MCF:FormatDuration(a.taxiTime)); Row(T("Sessions"),tostring(a.sessions))
    Row(T("Screenshots"),tostring(a.screens)); Row(T("Journal entries"),tostring(a.journal))
    y=y-10
    AddText(T("RECORDS"),8,540,y,"GameFontNormal"); y=y-25
    local function best(field,rate)
        local winner,val=nil,nil
        for _,ch in ipairs(rows) do
            local v=tonumber(ch[field]) or 0
            if rate then v=(ch.played or 0)>0 and (v/((ch.played or 0)/3600)) or 0 end
            if not val or v>val then winner,val=ch,v end
        end
        return winner,val or 0
    end
    local w,v=best("played"); if w then Row(T("Most playtime"),(w.name or "?").." - "..MCF:FormatDuration(v)) end
    w,v=best("level"); if w then Row(T("Highest character"),(w.name or "?").." - "..T("Level").." "..tostring(v)) end
    w,v=best("quests"); if w then Row(T("Most quests"),(w.name or "?").." - "..tostring(v)) end
    w,v=best("deaths"); if w then Row(T("Most deaths"),(w.name or "?").." - "..tostring(v)) end
    w,v=best("money"); if w then Row(T("Richest character"),(w.name or "?").." - "..money(v)) end
    w,v=best("groundYards"); if w then Row(T("Farthest traveler"),(w.name or "?").." - "..MCF:FormatDistance(v)) end
    y=y-12
    end -- Account-wide summary only; selected characters show their own details.
    if not modernLayout then
    AddText(T("CHARACTERS"),8,540,y,"GameFontNormal"); y=y-25
    for _,ch in ipairs(rows) do
        local key=ch.key or ((ch.realm or "?").."::"..(ch.name or "?")); local expanded=(modernLayout and selectedAccountCharacter==key) or characterBlockExpanded[key] and true or false
        if not modernLayout or selectedAccountCharacter==key then
        local b=CreateFrame("Button",nil,child); b:SetSize(540,25); b:SetPoint("TOPLEFT",8,y+4)
        local m=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); m:SetPoint("LEFT",2,0); m:SetText(expanded and "|cffffcc00-|r" or "|cffffcc00+|r")
        local title=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("LEFT",22,0); title:SetText((ch.name or "?").." - "..(ch.realm or "?")); title:SetTextColor(1,1,1)
        local meta=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); meta:SetPoint("RIGHT",-4,0); meta:SetText((MCF:ClassName(ch.classFile,ch.class) or "?").."  |  "..T("Level").." "..tostring(ch.level or "?"))
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD"); b:SetScript("OnClick",function() characterBlockExpanded[key]=not characterBlockExpanded[key]; MCF:RefreshUI() end)
        characterRows[#characterRows+1]=b; y=y-29
        if expanded then
            Row(T("Total /played"),MCF:FormatDuration(ch.played or 0)); Row(T("Active play time"),MCF:FormatDuration(ch.activePlayed or 0))
            Row(T("Deaths"),tostring(ch.deaths or 0)); Row(T("Quests"),tostring(ch.quests or 0)); Row(T("Dungeon visits"),tostring(ch.dungeonVisits or 0))
            Row(T("Boss kills"),tostring(ch.bosses or 0)); Row(T("Gold"),money(ch.money or 0)); Row(T("Last seen"),fmtDate(ch.lastSeen))
        end
        y=y-12
        end
    end
    end -- Classic character accordion.
    if modernLayout and selectedAccountCharacter then
        for _,ch in ipairs(rows) do
            local key=ch.key or ((ch.realm or "?").."::"..(ch.name or "?"))
            if key==selectedAccountCharacter then
                AddText((ch.name or "?").." - "..(ch.realm or "?"),8,540,y,"GameFontNormalLarge"); y=y-35
                Row(T("Level"),tostring(ch.level or "?"))
                Row(T("Total /played"),MCF:FormatDuration(ch.played or 0))
                Row(T("Active play time"),MCF:FormatDuration(ch.activePlayed or 0))
                Row(T("Deaths"),tostring(ch.deaths or 0))
                Row(T("Quests"),tostring(ch.quests or 0))
                Row(T("Dungeon visits"),tostring(ch.dungeonVisits or 0))
                Row(T("Dungeon completions"),tostring(ch.dungeonCompletions or 0))
                Row(T("Boss kills"),tostring(ch.bosses or 0))
                Row(T("Gold"),money(ch.money or 0))
                Row(T("Screenshots"),tostring(ch.screenshots or 0))
                Row(T("Journal entries"),tostring(ch.journal or 0))
                Row(T("Last seen"),fmtDate(ch.lastSeen))
                break
            end
        end
    end
    return math.abs(y)+35
end

local overviewTreeRows={}
local overviewTreeExpanded=overviewTreeExpanded or {}
local function ClearOverviewTreeRows()
    for _,r in ipairs(overviewTreeRows) do MCF.Retire(r) end
    wipe(overviewTreeRows)
end

local function SplitOverviewSections(txt)
    local sections={}
    local current=nil
    for line in (txt.."\n"):gmatch("(.-)\n") do
        local header=line:match("^|cffffffff(.-)|r$")
        if header then
            current={title=header,lines={}}
            sections[#sections+1]=current
        elseif current and line~="" then
            current.lines[#current.lines+1]=line
        end
    end
    return sections
end

local function DrawOverviewTree(db)
    ClearOverviewTreeRows()
    local leftText,rightText=BuildText()
    local raw=SplitOverviewSections(leftText)
    local r=SplitOverviewSections(rightText)
    for _,sec in ipairs(r) do raw[#raw+1]=sec end
    local sections={}
    local wanted={T("CHARACTER"),T("LEVELING"),T("PLAYTIME"),T("ADVENTURE"),T("GUILD"),T("LOCATION TIMES"),T("MOST TIME SPENT"),T("EXPLORATION"),T("ARCHIVE / DATA")}
    local used={}
    for _,title in ipairs(wanted) do
        for i,sec in ipairs(raw) do
            if not used[i] and sec.title==title then sections[#sections+1]=sec; used[i]=true; break end
        end
    end
    for i,sec in ipairs(raw) do if not used[i] then sections[#sections+1]=sec end end

    local y=-56
    local function AddText(value,x,width,ypos,font,justify)
        local fs=child:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
        fs:SetPoint("TOPLEFT",x,ypos); fs:SetWidth(width)
        fs:SetJustifyH(justify or "LEFT"); fs:SetJustifyV("TOP"); fs:SetText(value or "")
        overviewTreeRows[#overviewTreeRows+1]=fs
        return fs
    end
    local function AddHover(rowY,tipKey)
        local hl=child:CreateTexture(nil,"BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(1,1,1,0.08)
        hl:SetPoint("TOPLEFT",26,rowY+2); hl:SetSize(505,16); hl:Hide()
        overviewTreeRows[#overviewTreeRows+1]=hl
        local hit=CreateFrame("Frame",nil,child)
        hit:SetPoint("TOPLEFT",26,rowY+2); hit:SetSize(505,16); hit:EnableMouse(true)
        hit:SetFrameLevel(child:GetFrameLevel()+20)
        hit:SetScript("OnEnter",function(self)
            hl:Show()
            if tipKey then
                self._hover=true; overviewTipSerial=overviewTipSerial+1
                local serial=overviewTipSerial
                C_Timer.After(1,function()
                    if self._hover and self:IsShown() and serial==overviewTipSerial then
                        GameTooltip:SetOwner(self,"ANCHOR_CURSOR"); GameTooltip:SetText(T(tipKey),1,1,1); GameTooltip:Show()
                    end
                end)
            end
        end)
        hit:SetScript("OnLeave",function(self)
            hl:Hide(); self._hover=false; overviewTipSerial=overviewTipSerial+1; GameTooltip:Hide()
        end)
        overviewTreeRows[#overviewTreeRows+1]=hit
    end

    for _,section in ipairs(sections) do
        local key=section.title
        if overviewTreeExpanded[key]==nil then overviewTreeExpanded[key]=(key==T("CHARACTER") or key==T("LEVELING") or key==T("PLAYTIME")) end
        local expanded=overviewTreeExpanded[key]
        local toggle=CreateFrame("Button",nil,child)
        toggle:SetSize(540,25); toggle:SetPoint("TOPLEFT",8,y+4)
        local marker=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        marker:SetPoint("LEFT",2,0); marker:SetText(expanded and "|cffffcc00-|r" or "|cffffcc00+|r")
        local title=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("LEFT",22,0); title:SetText(section.title); title:SetTextColor(1,1,1)
        toggle:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        toggle:SetScript("OnClick",function() overviewTreeExpanded[key]=not overviewTreeExpanded[key]; MCF:RefreshUI() end)
        overviewTreeRows[#overviewTreeRows+1]=toggle
        y=y-29

        if expanded then
            for _,line in ipairs(section.lines) do
                local rowY=y
                local rank,name,dur=line:match("^(%d+)%.%s+(.+)%s+%-%s+(%d+:%d+:%d+)$")
                local label,value=line:match("^([^:]+):%s*(.+)$")
                local gd,ga,gg,gl=line:match("^__MCFGUILDROW__\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
                local zoneRank,zoneName,zoneDuration=line:match("^__MCFZONEROW__\t(%d+)\t([^\t]*)\t([^\t]*)$")
                if line=="__MCFZONEHEADER__" then
                    local isGerman=MCF:GetLanguage()=="deDE"
                    AddText(isGerman and "Platzierung" or "Rank",30,105,rowY,"GameFontNormalSmall","LEFT")
                    AddText(isGerman and "Zone" or "Zone",145,185,rowY,"GameFontNormalSmall","LEFT")
                    AddText(isGerman and "Zeit (tt:hh:mm:ss)" or "Time (dd:hh:mm:ss)",338,182,rowY,"GameFontNormalSmall","RIGHT")
                elseif zoneRank then
                    AddText(zoneRank..".",30,105,rowY,"GameFontHighlight","LEFT")
                    local zoneText=AddText(zoneName,145,185,rowY,"GameFontHighlight","LEFT")
                    zoneText:SetWordWrap(false)
                    AddText(zoneDuration,338,182,rowY,"GameFontHighlight","RIGHT")
                elseif line=="__MCFGUILDHEADER__" then
                    AddText(T("Date / time"),30,118,rowY,"GameFontNormalSmall","LEFT")
                    AddText(T("Event"),152,92,rowY,"GameFontNormalSmall","LEFT")
                    AddText(T("Guild"),248,220,rowY,"GameFontNormalSmall","LEFT")
                    AddText(T("Lvl"),472,45,rowY,"GameFontNormalSmall","RIGHT")
                elseif gd then
                    AddText(gd,30,118,rowY,"GameFontHighlightSmall","LEFT")
                    AddText(ga,152,92,rowY,"GameFontHighlightSmall","LEFT")
                    AddText(gg,248,220,rowY,"GameFontHighlightSmall","LEFT")
                    AddText(gl,472,45,rowY,"GameFontHighlightSmall","RIGHT")
                elseif rank and name and dur then
                    AddText(rank..".",30,28,rowY,"GameFontHighlight","RIGHT")
                    AddText(name,70,315,rowY,"GameFontHighlight","LEFT")
                    AddText(dur,395,125,rowY,"GameFontHighlight","RIGHT")
                elseif label and value then
                    AddText(label,30,285,rowY,"GameFontHighlight","LEFT")
                    local shown=value
                    if type(value)=="string" and #value>36 then shown=value:sub(1,33).."..." end
                    local valueText=AddText(shown,325,195,rowY,"GameFontHighlight","RIGHT")
                    valueText:SetWordWrap(false)
                    if shown~=value then
                        local hit=CreateFrame("Frame",nil,child)
                        hit:SetPoint("TOPLEFT",valueText,"TOPLEFT",0,0); hit:SetSize(195,20); hit:EnableMouse(true)
                        hit:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(value); GameTooltip:Show() end)
                        hit:SetScript("OnLeave",function() GameTooltip:Hide() end)
                        overviewTreeRows[#overviewTreeRows+1]=hit
                    end
                else
                    AddText(line,30,490,rowY,"GameFontHighlight","LEFT")
                end
                AddHover(rowY,FindOverviewTip(line))
                y=y-math.ceil(16*(MCF:GetFontScale()))
            end
            y=y-3
        end
        local divider=child:CreateTexture(nil,"ARTWORK")
        divider:SetTexture("Interface\\Buttons\\WHITE8X8"); divider:SetVertexColor(0.45,0.45,0.45,0.35)
        divider:SetSize(540,1); divider:SetPoint("TOPLEFT",8,y-5)
        overviewTreeRows[#overviewTreeRows+1]=divider
        y=y-17
    end
    return math.abs(y)+35
end

function MCF:RefreshUI()
    ClearOverviewTips()
    -- Reset all tab-specific layers first. This is important because several
    -- tab branches return early and would otherwise leave content from the
    -- previously active tab visible.
    journalLayer:Hide()
    screenshotLayer:Hide()
    overviewRight:Hide()
    overviewName:Hide(); overviewLogo:Hide()
    overviewSettings:Hide()
    overviewExport:Hide()
    frame.websiteButton:Hide()
    frame.portraitButton:Hide()
    frame.SetContentBottom(false)
    goldInfo:Hide()
    text:SetText("")
    ClearJournalCards()
    ClearScreenshotCards()
    if Shots.dropdown then Shots.dropdown:Hide() end
    ClearDungeonRows()
    ClearLevelRows()
    ClearProfessionRows()
    ClearReputationRows()
    ClearIconicRows()
    ClearOverviewTreeRows()
    ClearCharacterRows()
    ClearAchievementRows()
    if viewMode~="achievements" then
        if achUI.filterPanel then achUI.filterPanel:Hide() end
        if achUI.recentPanel then achUI.recentPanel:Hide() end
        if achUI.pointsPanel then achUI.pointsPanel:Hide() end
        if achUI.pointsToggle then achUI.pointsToggle:Hide() end
        if achUI.filterToggle then achUI.filterToggle:Hide() end
        for _,control in ipairs(achUI.achievementFilterControls or {}) do for _,widget in ipairs(control) do widget:Hide() end end
        for _,b in ipairs(achUI.secretControls or {}) do b:Hide() end
        for _,w in ipairs({achUI.modeNormal,achUI.modeSecrets,achUI.modeNormalLabel,achUI.modeSecretsLabel}) do if w then w:Hide() end end
    end
    if viewMode=="achievements" then
        goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart()
        child:SetHeight(math.max(1000,DrawAchievementRows()))
        return
    elseif viewMode=="levels" then
        goldChart:Hide()
        goldHistoryTextFrame:Hide()
        ClearGoldChart()
        overviewRight:Hide()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawLevelRows(MyCharForeverDB)))
        return
    elseif viewMode=="dungeons" then
        goldChart:Hide()
        goldHistoryTextFrame:Hide()
        ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawDungeonRows(MyCharForeverDB)))
        return
    elseif viewMode=="characters" then
        if modernLayout then UpdateNavigation() end
        goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawCharacterRows()))
        return
    elseif viewMode=="professions" then
        goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawProfessionRows(MyCharForeverDB)))
        return
    elseif viewMode=="iconic" then
        goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawIconicRows(MyCharForeverDB)))
        return
    elseif viewMode=="reputation" then
        goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawReputationRows(MyCharForeverDB)))
        return
    elseif viewMode=="screenshots" then
        screenshotLayer:Show(); goldChart:Hide(); goldHistoryTextFrame:Hide(); ClearGoldChart(); text:SetText("")
        child:SetHeight(math.max(1000,DrawScreenshotCards(MyCharForeverDB))); return
    elseif viewMode=="journal" then
        journalLayer:Show()
        goldChart:Hide()
        goldHistoryTextFrame:Hide()
        ClearGoldChart()
        text:SetText("")
        child:SetHeight(math.max(1000,DrawJournalCards(MyCharForeverDB)))
        return
    elseif viewMode=="gold" then
        goldInfo:SetText(T("Gold history info").."\n"..T("Gold web hint").."\n\n|cffffd100"..T("Looted gold total:").." "..money(MyCharForeverDB and MyCharForeverDB.goldLooted and MyCharForeverDB.goldLooted.total or 0)..MCF.LootedSinceText().."|r")
        goldInfo:Show()
        -- Below the description: balance lines, then chart (315 high), then the daily table. All offsets follow the description's real height.
        goldChart.textTop=12+math.ceil((goldInfo:GetStringHeight() or 80)*MCF:GetFontScale()/(MCF.fontAppliedFactor or 1))
        goldChart:ClearAllPoints(); goldChart:SetPoint("TOPLEFT",8,-(goldChart.textTop+60))
        goldHistoryTextFrame:ClearAllPoints(); goldHistoryTextFrame:SetPoint("TOPLEFT",8,-(goldChart.textTop+60+340))
        goldChart:Show()
        DrawGoldChart(MyCharForeverDB)
        goldHistoryTextFrame:Show()
        DrawGoldHistoryTable(MyCharForeverDB)
    else
        goldChart:Hide()
        goldHistoryTextFrame:Hide()
        ClearGoldChart()
    end

    text:ClearAllPoints()
    overviewRight:ClearAllPoints()
    if viewMode=="overview" then
        local db=MyCharForeverDB
        if not db or not db.character then
            overviewName:Hide(); overviewLogo:Hide()
            overviewRight:Hide()
            text:SetPoint("TOPLEFT",8,-5); text:SetWidth(570)
            text:SetText("")
            return
        end
        overviewName:SetText((db.character.name or "?").." - "..(db.character.realm or "?"))
        overviewName:Show(); overviewLogo:Show()
        overviewSettings:Show()
        overviewExport:Show()
        frame.websiteButton:Show()
        frame.portraitButton:SetText(MCF:GetLanguage()=="deDE" and "Porträt" or "Portrait")
        frame.portraitButton:Show()
        frame.SetContentBottom(true)
        text:SetText("")
        overviewRight:Hide()
        child:SetHeight(math.max(1000,DrawOverviewTree(db)))
    else
        overviewRight:Hide()
        if viewMode=="gold" then
            text:SetPoint("TOPLEFT",12,-goldChart.textTop); text:SetWidth(570)
        else
            text:SetPoint("TOPLEFT",8,-5); text:SetWidth(570)
        end
        text:SetText(BuildText())
    end
    if viewMode=="gold" then
        child:SetHeight(math.max(970,goldChart.textTop+60+340+goldHistoryTextFrame:GetStringHeight()+35))
    else
        local h=text:GetStringHeight()
        if viewMode=="overview" then
            -- DrawOverviewTree already sized the scroll child.
        else
            child:SetHeight(math.max(1000,h+30))
        end
    end
end

-- Rebuilding the window is expensive (it creates frames, which the game never frees). Data events fire
-- all the time (gold, loot, reputation, skills ...), so nothing is rebuilt while the window is closed:
-- it is only marked dirty and refreshed when the window opens (see the OnShow script).
do
    local rebuild=MCF.RefreshUI
    -- State lives in a table field: UI.lua is at Lua's limit of 200 local variables.
    MCF.refreshGate={last=0,pending=false,gap=0.3} -- bursts of data events (looting, gold) redraw once instead of many times
    function MCF:RefreshUI()
        if not frame:IsShown() then MCF.uiDirty=true; return end
        local gate,now=MCF.refreshGate,GetTime()
        if now-gate.last<gate.gap then
            if not gate.pending then
                gate.pending=true
                C_Timer.After(gate.gap-(now-gate.last)+0.02,function() gate.pending=false; MCF:RefreshUI() end)
            end
            return
        end
        gate.last=now
        MCF.uiDirty=false
        rebuild(self)
        -- New font strings need the font scale at once: waiting for the timer shows them at normal size for a moment.
        MCF.fontDirty=false
        MCF:ApplyFontScale()
    end
end

-- Achievement panels: inspired by the compact bronze/gold WoW achievement cards.
-- Cards and headers are pooled: the panel is redrawn on every refresh and frames
-- can never be destroyed in WoW, so creating new ones each time would leak.
-- Keep achievement UI state in one table to stay below WoW Lua's 200-local limit.
-- Reuse the forward-declared state table.
achUI.ACHIEVEMENT_CARD_WIDTH,achUI.ACHIEVEMENT_CARD_HEIGHT,achUI.ACHIEVEMENT_CARD_GAP=540,78,10
achUI.achievementRows,achUI.cardPool,achUI.headerPools,achUI.categoryPool={},{},{},{}
-- Fonts used by the panel's text rows (single definition; rows are pooled per role,
-- so a pooled FontString never changes role and never has to switch font objects).
achUI.FONT={title="GameFontNormalLarge",body="GameFontHighlightSmall"}
achUI.achievementFilter={done=true,open=true,easy=true,medium=true,hard=true,bad=false}
achUI.achievementMode="normal"
achUI.secretControls={}
achUI.achievementFilterControls={}
-- One opaque filter panel; separate groups share a common visual frame.
achUI.filterPanel=CreateFrame("Frame",nil,child,"BackdropTemplate")
achUI.filterPanel:SetPoint("TOPLEFT",child,"TOPLEFT",12,-120) -- repositioned on every draw
achUI.FILTER_PANEL_HEIGHT=146
achUI.filterPanel:SetSize(achUI.ACHIEVEMENT_CARD_WIDTH,achUI.FILTER_PANEL_HEIGHT)
achUI.filterPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
achUI.filterPanel:SetBackdropColor(0.035,0.03,0.025,1)
achUI.filterPanel:SetBackdropBorderColor(0.53,0.40,0.19,0.95)
achUI.filterPanel:SetFrameLevel(child:GetFrameLevel()+1)
achUI.filterTitle=achUI.filterPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
achUI.filterTitle:SetPoint("TOPLEFT",14,-9)
achUI.filterDivider1=achUI.filterPanel:CreateTexture(nil,"ARTWORK")
achUI.filterDivider1:SetColorTexture(0.40,0.31,0.15,0.75)
achUI.filterDivider1:SetPoint("TOPLEFT",10,-54);achUI.filterDivider1:SetPoint("TOPRIGHT",-10,-54);achUI.filterDivider1:SetHeight(1)
achUI.filterDivider2=achUI.filterPanel:CreateTexture(nil,"ARTWORK")
achUI.filterDivider2:SetColorTexture(0.40,0.31,0.15,0.75)
achUI.filterDivider2:SetPoint("TOPLEFT",10,-82);achUI.filterDivider2:SetPoint("TOPRIGHT",-10,-82);achUI.filterDivider2:SetHeight(1)
achUI.filterDivider3=achUI.filterPanel:CreateTexture(nil,"ARTWORK")
achUI.filterDivider3:SetColorTexture(0.40,0.31,0.15,0.75)
achUI.filterDivider3:SetPoint("TOPLEFT",10,-112);achUI.filterDivider3:SetPoint("TOPRIGHT",-10,-112);achUI.filterDivider3:SetHeight(1)
-- Text search: matches what the card shows (title, description, category). Unrevealed secrets only match their
-- placeholder text, so the search cannot give a secret away.
achUI.searchText=""
achUI.searchLabel=achUI.filterPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
achUI.searchLabel:SetPoint("TOPLEFT",14,-122)
achUI.searchBox=CreateFrame("EditBox","MyCharForeverAchievementSearchBox",achUI.filterPanel,"InputBoxTemplate")
achUI.searchBox:SetSize(280,22); achUI.searchBox:SetPoint("TOPLEFT",86,-117); achUI.searchBox:SetAutoFocus(false); achUI.searchBox:SetMaxLetters(60)
achUI.searchClear=CreateFrame("Button",nil,achUI.filterPanel,"UIPanelButtonTemplate")
achUI.searchClear:SetSize(70,22); achUI.searchClear:SetPoint("LEFT",achUI.searchBox,"RIGHT",8,0)
achUI.searchClear:SetScript("OnClick",function() achUI.searchBox:SetText(""); achUI.searchBox:ClearFocus() end)
achUI.searchBox:SetScript("OnTextChanged",function(self)
 achUI.searchText=strtrim(self:GetText() or "")
 if viewMode=="achievements" and MCF.RefreshUI then MCF:RefreshUI() end
end)
achUI.searchBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
achUI.searchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
-- Collapsible panels (points box, filter box): the part below the header can be folded away.
-- State is remembered per character in settings.achievementPanels[key]: false = the player opened it; anything else = collapsed (default).
function achUI.PanelCollapsed(key)
 local st=MyCharForeverDB and MyCharForeverDB.settings
 local v=st and st.achievementPanels and st.achievementPanels[key]
 return v~=false
end
-- The fold buttons sit in the top right corner of their own panel (points box, filter box).
achUI.TOGGLE_W,achUI.TOGGLE_H=24,22
function achUI.LabelToggles()
 achUI.pointsToggle:SetText(achUI.PanelCollapsed("points") and "+" or "-")
 achUI.filterToggle:SetText(achUI.PanelCollapsed("filter") and "+" or "-")
 achUI.pointsToggle:Show(); achUI.filterToggle:Show()
end
function achUI.MakeToggle(parent,key,tipDe,tipEn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")

 b:SetSize(achUI.TOGGLE_W,achUI.TOGGLE_H)
 b:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-12,-10)
 b:SetScript("OnClick",function()
  local st=MyCharForeverDB and MyCharForeverDB.settings
  if not st then return end
  st.achievementPanels=st.achievementPanels or {}
  -- collapsed -> open (false), open -> collapsed (true). Not "x and false or true": that always yields true in Lua.
  if achUI.PanelCollapsed(key) then st.achievementPanels[key]=false else st.achievementPanels[key]=true end
  if MCF.RefreshUI then MCF:RefreshUI() end
 end)
 b:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_TOP")
  local de=MCF.GetLanguage and MCF:GetLanguage()=="deDE"
  GameTooltip:SetText(achUI.PanelCollapsed(key) and (de and "Ausklappen" or "Expand") or (de and "Einklappen" or "Collapse"),1,0.82,0.2)
  GameTooltip:AddLine(de and tipDe or tipEn,1,1,1,true)
  GameTooltip:Show()
 end)
 b:SetScript("OnLeave",function() GameTooltip:Hide() end)
 return b
end
achUI.filterToggle=achUI.MakeToggle(achUI.filterPanel,"filter","Zeigt oder versteckt die Filter und die Suche.","Shows or hides the filters and the search.")
-- Filter labels are resolved per language in DrawAchievementRows (label(german) -> text).
function achUI.CreateAchievementFilter(label,key,x,y)
 local cb=CreateFrame("CheckButton",nil,achUI.filterPanel,"UICheckButtonTemplate")
 cb:SetSize(22,22); cb:SetPoint("TOPLEFT",x,y)
 cb:SetChecked(achUI.achievementFilter[key])
 local txt=achUI.filterPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 txt:SetPoint("LEFT",cb,"RIGHT",1,0)
 cb:SetScript("OnClick",function(self)
  achUI.achievementFilter[key]=not not self:GetChecked()
  if MCF.RefreshUI then MCF:RefreshUI() end
 end)
 achUI.achievementFilterControls[#achUI.achievementFilterControls+1]={cb,txt,label=label,key=key}
end
function achUI.TierLabel(key) return function(german) local tier=MCF.AchievementTiers and MCF.AchievementTiers[key]; return tier and (german and tier.de or tier.en) or key end end
achUI.CreateAchievementFilter(function(g) return g and "Erledigte" or "Completed" end,"done",14,-59)
achUI.CreateAchievementFilter(function(g) return g and "Offene" or "Open" end,"open",172,-59)
-- Only visible while unverified achievements exist; when ticked it shows just those and greys out the difficulty row.
achUI.CreateAchievementFilter(function(g) return g and "Nicht verifiziert" or "Unverified" end,"bad",345,-59)
achUI.CreateAchievementFilter(achUI.TierLabel("easy"),"easy",14,-87)
achUI.CreateAchievementFilter(achUI.TierLabel("medium"),"medium",172,-87)
achUI.CreateAchievementFilter(achUI.TierLabel("hard"),"hard",345,-87)

function achUI.SecretButton(label,x,y,w,callback)
 local b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
 b:SetSize(w,25); b:SetPoint("TOPLEFT",x,y); b:SetText(label)
 b:SetScript("OnClick",callback)
 achUI.secretControls[#achUI.secretControls+1]=b
 return b
end
function achUI.ConfirmTamperReset(id)
 local de=MCF.GetLanguage and MCF:GetLanguage()=="deDE"
 StaticPopupDialogs["MCF_TAMPER_RESET"]={
  text=MCF.Branded(de and "Diese Freischaltung wurde von Hand verändert.\n\nZurücksetzen? Wirklich Erreichtes bleibt erhalten, es wird nichts bestraft." or "This unlock was edited by hand.\n\nReset it? Whatever you really earned is kept, nothing is punished."),
  button1=YES,button2=NO,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
  OnAccept=function() if MCF.ResetTamperedAchievement then MCF:ResetTamperedAchievement(id) end end,
 }
 StaticPopup_Show("MCF_TAMPER_RESET")
end
function achUI.ConfirmSecret(id,cost)
 StaticPopupDialogs["MCF_REVEAL_SECRET"]={
  text=MCF.Branded((MCF.GetLanguage and MCF:GetLanguage()=="deDE") and ("Geheimnis für "..cost.." Punkte enthüllen?") or ("Reveal secret for "..cost.." points?")),
  button1=YES,button2=NO,timeout=0,whileDead=true,hideOnEscape=true,
  OnAccept=function()
   if not MCF.RevealSecret then return end
   local ok,revealedId,def=MCF:RevealSecret(id)
   if not ok then return end
   local name,desc=revealedId,""
   for _,a in ipairs(MCF:GetAchievements()) do if a.id==revealedId then name,desc=a.name,a.description end end
   local german=MCF:GetLanguage()=="deDE"
   print("|cff00ccffMyCharForever|r: "..(german and "Geheimnis enthüllt: " or "Secret revealed: ").."|cffffd200"..name.."|r - "..desc)
   StaticPopupDialogs["MCF_SECRET_REVEALED"]={
    text=MCF.Branded((german and "Geheimnis enthüllt!\n\n" or "Secret revealed!\n\n").."|cffffd200"..name.."|r\n"..desc),
    button1=OKAY,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
   StaticPopup_Show("MCF_SECRET_REVEALED")
   MCF:RefreshUI()
  end,
  preferredIndex=3,
 }
 StaticPopup_Show("MCF_REVEAL_SECRET")
end
-- Compact mode selection: no three large red buttons at the top.
achUI.modeNormal=CreateFrame("CheckButton",nil,achUI.filterPanel,"UICheckButtonTemplate")
achUI.modeNormal:SetSize(22,22);achUI.modeNormal:SetPoint("TOPLEFT",14,-30)
achUI.modeSecrets=CreateFrame("CheckButton",nil,achUI.filterPanel,"UICheckButtonTemplate")
achUI.modeSecrets:SetSize(22,22);achUI.modeSecrets:SetPoint("TOPLEFT",172,-30)
achUI.modeNormalLabel=achUI.filterPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
achUI.modeNormalLabel:SetPoint("LEFT",achUI.modeNormal,"RIGHT",2,0)
achUI.modeSecretsLabel=achUI.filterPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
achUI.modeSecretsLabel:SetPoint("LEFT",achUI.modeSecrets,"RIGHT",2,0)
achUI.modeNormal:SetScript("OnClick",function() achUI.achievementMode="normal";MCF:RefreshUI() end)
achUI.modeSecrets:SetScript("OnClick",function() achUI.achievementMode="secrets";MCF:RefreshUI() end)
achUI.secretBuyButtons={}
function achUI.AcquireSecretBuyButton()
 local b=table.remove(achUI.secretBuyButtons)
 if not b then
  b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate");b:SetSize(125,22)
 end
 b:Show();return b
end
achUI.activeSecretButtons={}
function achUI.AcquireAchievementCard()
 local card=table.remove(achUI.cardPool)
 if card then card:Show(); return card end
 card=CreateFrame("Frame",nil,child,"BackdropTemplate")
 card:SetSize(achUI.ACHIEVEMENT_CARD_WIDTH,achUI.ACHIEVEMENT_CARD_HEIGHT)
 card:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=13,insets={left=3,right=3,top=3,bottom=3}})
 card.isCard=true
 card.icon=card:CreateTexture(nil,"ARTWORK"); card.icon:SetSize(40,40); card.icon:SetPoint("LEFT",12,0)
 card.title=card:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 card.title:SetPoint("TOPLEFT",64,-10); card.title:SetWidth(330); card.title:SetJustifyH("LEFT")
 card.desc=card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 card.desc:SetPoint("TOPLEFT",64,-35); card.desc:SetWidth(355); card.desc:SetJustifyH("LEFT")
 card.tierText=card:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 card.tierText:SetPoint("TOPRIGHT",-12,-12)
 card.count=card:CreateFontString(nil,"OVERLAY","GameFontNormal")
 card.count:SetPoint("RIGHT",-12,-6)
 card.check=card:CreateTexture(nil,"OVERLAY"); card.check:SetSize(24,24)
 card.check:SetPoint("BOTTOMRIGHT",card.icon,"BOTTOMRIGHT",8,-8)
 card.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); card.check:SetVertexColor(0.25,1,0.25)
 card.barBack=card:CreateTexture(nil,"BACKGROUND"); card.barBack:SetColorTexture(0,0,0,0.5)
 card.barBack:SetPoint("BOTTOMLEFT",64,10); card.barBack:SetSize(355,5)
 card.bar=card:CreateTexture(nil,"ARTWORK"); card.bar:SetPoint("BOTTOMLEFT",64,10); card.bar:SetHeight(5)
 return card
end
function achUI.AcquireAchievementHeader(font)
 local pool=achUI.headerPools[font]
 local header=pool and table.remove(pool)
 if header then header:Show(); header:SetWidth(0); return header end
 header=child:CreateFontString(nil,"OVERLAY",font)
 header.fontRole=font
 return header
end

-- Collapsible category header. Collapsed categories are remembered per character.
function achUI.CollapsedCategories()
 local st=MyCharForeverDB and MyCharForeverDB.settings
 if not st then return {} end
 st.achievementCollapsed=st.achievementCollapsed or {}
 return st.achievementCollapsed
end
function achUI.AcquireCategoryButton()
 local b=table.remove(achUI.categoryPool)
 if b then b:Show(); return b end
 b=CreateFrame("Button",nil,child)
 b:SetSize(achUI.ACHIEVEMENT_CARD_WIDTH,28)
 b.isCategory=true
 b.arrow=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); b.arrow:SetPoint("LEFT",4,0)
 b.label=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); b.label:SetPoint("LEFT",26,0)
 b.count=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b.count:SetPoint("RIGHT",-8,0)
 b.line=b:CreateTexture(nil,"ARTWORK"); b.line:SetColorTexture(0.75,0.55,0.05,0.55); b.line:SetHeight(1)
 b.line:SetPoint("BOTTOMLEFT",0,0); b.line:SetPoint("BOTTOMRIGHT",0,0)
 b:SetScript("OnEnter",function(self) self.label:SetTextColor(1,1,1); self.arrow:SetTextColor(1,1,1); self.line:SetColorTexture(1,0.82,0.15,0.9) end)
 b:SetScript("OnLeave",function(self) self.label:SetTextColor(1,0.82,0); self.arrow:SetTextColor(1,0.82,0); self.line:SetColorTexture(0.75,0.55,0.05,0.55) end)
 b:SetScript("OnClick",function(self)
  local t=achUI.CollapsedCategories()
  t[self.categoryKey]=(not t[self.categoryKey]) or nil
  MCF:RefreshUI()
 end)
 return b
end


-- Points panel: one clear box with the spendable balance and where the points come from.
-- Layout: top row = balance (left) and reveal button (right); below it the figures as running text.
-- Its height follows the real text height, so a larger font setting never makes anything overlap.
achUI.POINT_ROWS,achUI.POINT_LABEL_WIDTH=6,300
function achUI.EnsurePointsPanel()
 if achUI.pointsPanel then return achUI.pointsPanel end
 local p=CreateFrame("Frame",nil,child,"BackdropTemplate")
 p:SetSize(achUI.ACHIEVEMENT_CARD_WIDTH,100)
 p:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 p:SetBackdropColor(0.16,0.11,0.02,1); p:SetBackdropBorderColor(1,0.82,0.15,1)
 p.caption=p:CreateFontString(nil,"OVERLAY","GameFontNormal"); p.caption:SetPoint("TOPLEFT",16,-12)
 p.big=p:CreateFontString(nil,"OVERLAY","GameFontNormalHuge"); p.big:SetPoint("TOPLEFT",p.caption,"BOTTOMLEFT",0,-4)
 p.big:SetTextColor(1,0.9,0.3)
 p.sub=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); p.sub:SetPoint("TOPLEFT",p.big,"BOTTOMLEFT",0,-4); p.sub:SetJustifyH("LEFT")
 -- The figures are a small two-column table: label on the left, value on the right. One row more is one more entry in POINT_ROWS.
 p.divider=p:CreateTexture(nil,"ARTWORK"); p.divider:SetTexture("Interface\\Buttons\\WHITE8X8"); p.divider:SetVertexColor(1,0.82,0.15,0.35); p.divider:SetHeight(1)
 p.rows={}
 for i=1,achUI.POINT_ROWS do
  local label=p:CreateFontString(nil,"OVERLAY","GameFontNormal"); label:SetJustifyH("LEFT"); label:SetWordWrap(true)
  local value=p:CreateFontString(nil,"OVERLAY","GameFontHighlight"); value:SetJustifyH("LEFT"); value:SetWordWrap(true)
  p.rows[i]={label=label,value=value}
 end
 -- Random secret reveal: always reachable from the points box, where the points are shown.
 local rb=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
 rb:SetPoint("TOPRIGHT",-44,-12)
 rb:SetScript("OnClick",function() achUI.ConfirmSecret(nil,MCF.SecretCost.random) end)
 rb:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_TOP")
  local de=MCF:GetLanguage()=="deDE"
  GameTooltip:SetText(de and "Zufälliges Geheimnis" or "Random secret",1,0.82,0.2)
  GameTooltip:AddLine(de and ("Kostet "..MCF.SecretCost.random.." Punkte und schaltet einen zufälligen geheimen Erfolg frei. Gezielt wählen kostet "..MCF:SecretCostText()..", je nach Stufe.")
   or ("Costs "..MCF.SecretCost.random.." points and unlocks one random secret achievement. Choosing one yourself costs "..MCF:SecretCostText()..", by difficulty."),1,1,1,true)
  GameTooltip:Show()
 end)
 rb:SetScript("OnLeave",function() GameTooltip:Hide() end)
 p.reveal=rb; achUI.randomReveal=rb
 achUI.pointsToggle=achUI.MakeToggle(p,"points","Zeigt oder versteckt die Aufschlüsselung der Punkte.","Shows or hides the points breakdown.")
 achUI.pointsPanel=p
 -- Existing font strings must already carry the font scale when the height is measured.
 if MCF.ApplyFontScale then MCF:ApplyFontScale() end
 return p
end
function achUI.UpdatePointsPanel(data,summary,german)
 local p=achUI.EnsurePointsPanel()
 local total,available,fromAch,fromIconic,spent,fromAccount=MCF:GetSecretPoints(data)
 local found=MCF.GetIconicFound and (MCF:GetIconicFound()) or 0
 local lastName
 local lastId=MyCharForeverDB and MyCharForeverDB.achievements and MyCharForeverDB.achievements.lastRevealed
 for _,a in ipairs(data) do if a.id==lastId then lastName=a.name end end
 p.caption:SetText(german and "VERFÜGBARE PUNKTE" or "AVAILABLE POINTS")
 p.big:SetText(tostring(available))
 p.reveal:SetText((german and "Zufälliges Geheimnis\nenthüllen (" or "Reveal random\nsecret (")..MCF.SecretCost.random..(german and " Pkt.)" or " pts)"))
 p.reveal:SetEnabled(available>=MCF.SecretCost.random)
 local scale=math.max(1,MCF:GetFontScale())
 p.reveal:SetSize(math.floor(140*scale),math.floor(50*scale))
 p.sub:SetText(german and ("Erfolge: "..summary.earned.." / "..summary.total) or ("Achievements: "..summary.earned.." / "..summary.total))
 local left=p.caption:GetStringHeight()+p.big:GetStringHeight()+p.sub:GetStringHeight()+8
 local top=math.max(left,p.reveal:GetHeight())
 local revealedN,secretN=MCF:GetSecretCounts(data)
 local white=function(v) return "|cffffffff"..tostring(v).."|r" end
 local rows={
  {german and "Aus Erfolgen" or "From achievements",white(fromAch)},
  {german and "Aus ikonischen Momenten" or "From iconic moments",white(fromIconic).." |cff9d9d9d("..found.." x "..MCF.IconicPoints..")|r"},
  {german and "Aus Account-Erfolgen (für alle Charaktere)" or "From account achievements (shared by all characters)",white(fromAccount or 0)},
  {german and "Bereits ausgegeben" or "Already spent",white(spent)},
  {german and "Geheime Erfolge aufgedeckt" or "Secret achievements revealed",white(revealedN)..(german and " von " or " of ")..white(secretN)},
  {german and "Zuletzt enthüllt" or "Last revealed","|cffffd200"..(lastName or "-").."|r"},
 }
 local labelW=achUI.POINT_LABEL_WIDTH
 local fold=achUI.PanelCollapsed("points")
 p.divider:SetShown(not fold)
 for _,r in ipairs(p.rows) do r.label:SetShown(not fold); r.value:SetShown(not fold) end
 if fold then p:SetHeight(math.ceil(12+top+12)); return p end
 local valueW=achUI.ACHIEVEMENT_CARD_WIDTH-32-labelW-10
 local y=-(12+top+10)
 p.divider:ClearAllPoints(); p.divider:SetPoint("TOPLEFT",16,y); p.divider:SetPoint("TOPRIGHT",-16,y)
 y=y-8
 for i,r in ipairs(p.rows) do
  local d=rows[i]
  r.label:SetWidth(labelW); r.value:SetWidth(valueW)
  r.label:SetText(d[1]); r.value:SetText(d[2])
  r.label:ClearAllPoints(); r.label:SetPoint("TOPLEFT",16,y)
  r.value:ClearAllPoints(); r.value:SetPoint("TOPLEFT",16+labelW+10,y)
  y=y-math.max(r.label:GetStringHeight(),r.value:GetStringHeight())-4
 end
 p:SetHeight(math.ceil(-y+12))
 return p
end

-- "Recently earned": one card-wide panel, three entries side by side.
achUI.RECENT_COUNT,achUI.RECENT_HEIGHT=3,58
function achUI.EnsureRecentPanel()
 if achUI.recentPanel then return achUI.recentPanel end
 local p=CreateFrame("Frame",nil,child,"BackdropTemplate")
 p:SetSize(achUI.ACHIEVEMENT_CARD_WIDTH,achUI.RECENT_HEIGHT)
 p:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=13,insets={left=3,right=3,top=3,bottom=3}})
 p:SetBackdropBorderColor(0.92,0.72,0.16,1)
 p.label=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 p.label:SetPoint("TOPLEFT",12,-7)
 p.empty=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 p.empty:SetPoint("TOPLEFT",12,-27)
 p.slots={}
 local slotWidth=(achUI.ACHIEVEMENT_CARD_WIDTH-24)/achUI.RECENT_COUNT
 for i=1,achUI.RECENT_COUNT do
  local b=CreateFrame("Button",nil,p)
  b:SetSize(slotWidth,32); b:SetPoint("TOPLEFT",12+(i-1)*slotWidth,-22)
  b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(28,28); b.icon:SetPoint("LEFT",0,0)
  b.name=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  b.name:SetPoint("TOPLEFT",b.icon,"TOPRIGHT",6,-2); b.name:SetWidth(slotWidth-40)
  b.name:SetJustifyH("LEFT"); b.name:SetWordWrap(false)
  b.date=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  b.date:SetPoint("TOPLEFT",b.name,"BOTTOMLEFT",0,-2)
  b:SetScript("OnEnter",function(self)
   if not self.data then return end
   GameTooltip:SetOwner(self,"ANCHOR_TOP")
   GameTooltip:SetText(self.data.name,1,0.82,0)
   GameTooltip:AddLine(self.data.description,1,1,1,true)
   GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function() GameTooltip:Hide() end)
  p.slots[i]=b
 end
 achUI.recentPanel=p
 return p
end
function achUI.UpdateRecentPanel(data,german)
 local p=achUI.EnsureRecentPanel()
 local earned={}
 for _,a in ipairs(data) do if a.unlocked and not a.tampered then earned[#earned+1]=a end end
 table.sort(earned,function(x,y)
  local tx,ty=tonumber(x.unlocked.time) or 0,tonumber(y.unlocked.time) or 0
  if tx~=ty then return tx>ty end
  return x.order>y.order
 end)
 achUI.ApplyScaledFont(p.label,"GameFontNormalSmall")
 p.label:SetText(german and "Zuletzt erreicht" or "Recently earned")
 achUI.ApplyScaledFont(p.empty,"GameFontHighlightSmall")
 p.empty:SetText(#earned==0 and (german and "Noch keine Erfolge erreicht." or "No achievements earned yet.") or "")
 for i,b in ipairs(p.slots) do
  local a=earned[i]
  b.data=a
  b:SetShown(a~=nil)
  if a then
   achUI.ApplyScaledFont(b.name,"GameFontHighlightSmall")
   achUI.ApplyScaledFont(b.date,"GameFontDisableSmall")
   b.icon:SetTexture("Interface\\Icons\\Achievement_General")
   b.name:SetText(a.name)
   b.date:SetText(a.unlocked.time and date(german and "%d.%m.%Y" or "%Y-%m-%d",a.unlocked.time) or "")
  end
 end
 return p
end
ClearAchievementRows=function()
 for _,row in ipairs(achUI.achievementRows) do
  row:Hide()
  if row.isCard then
   achUI.cardPool[#achUI.cardPool+1]=row
  elseif row.isCategory then
   achUI.categoryPool[#achUI.categoryPool+1]=row
  else
   achUI.headerPools[row.fontRole]=achUI.headerPools[row.fontRole] or {}
   table.insert(achUI.headerPools[row.fontRole],row)
  end
 end
 wipe(achUI.achievementRows)
 for _,b in ipairs(achUI.activeSecretButtons) do b:Hide();achUI.secretBuyButtons[#achUI.secretBuyButtons+1]=b end
 wipe(achUI.activeSecretButtons)
end
-- Positions a text row and applies the user's font scale. The unscaled size comes from
-- the font OBJECT, never from row:GetFont(): after SetFont/SetFontObject the row can
-- still report the size of its previous use, which froze a wrong size on reused rows.
function achUI.ApplyScaledFont(row,font)
 row:SetFontObject(font)
 local fontObject=_G[font]
 local fontPath,baseSize,fontFlags
 if fontObject and fontObject.GetFont then fontPath,baseSize,fontFlags=fontObject:GetFont() end
 if fontPath and type(baseSize)=="number" and baseSize>0 then
  local factor=MCF:GetFontScale()
  row:SetFont(fontPath,math.max(6,baseSize*factor),fontFlags)
  scaledFonts[row]={font=fontPath,base=baseSize,scale=factor}
 end
end
function achUI.PlaceRow(row,x,offsetY,font)
 row:ClearAllPoints(); row:SetPoint("TOPLEFT",x,offsetY)
 if font then achUI.ApplyScaledFont(row,font) end
 achUI.achievementRows[#achUI.achievementRows+1]=row
end
DrawAchievementRows=function()
 local data=MCF.GetAchievements and MCF:GetAchievements() or {}
 local summary=MCF.GetAchievementSummary and MCF:GetAchievementSummary(data) or {earned=0,total=#data,points=0,pointsTotal=0,hiddenLeft=0}
 local german=MCF.GetLanguage and MCF:GetLanguage()=="deDE"
 local y=-12
 local secretMode=achUI.achievementMode=="secrets"
 achUI.filterPanel:Show()
 achUI.filterTitle:SetText(german and "Filter" or "Filters")
 achUI.searchLabel:SetText(german and "Suche" or "Search")
 achUI.searchClear:SetText(german and "Leeren" or "Clear")
 for _,control in ipairs(achUI.achievementFilterControls) do
  control[2]:SetText(control.label(german))
  for _,widget in ipairs(control) do widget:Show() end -- the same filters apply to both modes
 end
 achUI.modeNormal:Show();achUI.modeSecrets:Show()
 achUI.modeNormalLabel:Show();achUI.modeSecretsLabel:Show()
 achUI.modeNormal:SetChecked(not secretMode);achUI.modeSecrets:SetChecked(secretMode)
 achUI.modeNormalLabel:SetText(german and "Normale Erfolge" or "Regular achievements")
 achUI.modeSecretsLabel:SetText(german and "Geheimnisse" or "Secrets")
 local Place=achUI.PlaceRow
 local header=achUI.AcquireAchievementHeader(achUI.FONT.title)
 Place(header,14,y,achUI.FONT.title)
 header:SetText(german and "MyCharForever Erfolge" or "MyCharForever Achievements")
 y=y-30
 local intro=achUI.AcquireAchievementHeader(achUI.FONT.body)
 Place(intro,14,y,achUI.FONT.body)
 intro:SetWidth(530);intro:SetJustifyH("LEFT")
 intro:SetText(german and "Hier zählen nur Erfolge innerhalb von MyCharForever. Sie haben nichts mit den offiziellen WoW-Erfolgen zu tun.\nEs gibt auch geheime Erfolge, die du mit gesammelten Erfolgspunkten aufdecken kannst!" or "Only achievements earned in MyCharForever count here. They are independent of official WoW achievements.\nYou can spend earned achievement points to reveal hidden achievements!")
 -- Everything below the intro follows its real height: no fixed offsets, no dead space.
 y=y-math.max(30,(intro.GetStringHeight and intro:GetStringHeight() or 36))-10
 achUI.EnsurePointsPanel()
 achUI.LabelToggles()
 local pp=achUI.UpdatePointsPanel(data,summary,german)
 pp:ClearAllPoints(); pp:SetPoint("TOPLEFT",child,"TOPLEFT",12,y); pp:Show()
 y=y-pp:GetHeight()-14
 -- Filter panel sits right below; in secrets mode only the mode row is needed.
 local panelHeight=achUI.FILTER_PANEL_HEIGHT
 local fold=achUI.PanelCollapsed("filter")
 if fold then panelHeight=54 end -- title + mode row stay visible
 for _,control in ipairs(achUI.achievementFilterControls) do
  for _,widget in ipairs(control) do widget:SetShown(not fold) end
 end

 local anyBad=false
 for _,a in ipairs(data) do if a.tampered then anyBad=true;break end end
 if not anyBad then achUI.achievementFilter.bad=false end
 local badOn=achUI.achievementFilter.bad and true or false
 for _,control in ipairs(achUI.achievementFilterControls) do
  if control.key=="bad" then
   control[1]:SetChecked(badOn)
   for _,widget in ipairs(control) do widget:SetShown(anyBad and not fold) end
  elseif control.key=="easy" or control.key=="medium" or control.key=="hard" then
   control[1]:SetEnabled(not badOn)
   if badOn then control[2]:SetTextColor(0.5,0.5,0.5) else control[2]:SetTextColor(1,1,1) end
  end
 end
 achUI.searchLabel:SetShown(not fold);achUI.searchBox:SetShown(not fold);achUI.searchClear:SetShown(not fold)
 achUI.filterPanel:ClearAllPoints()
 achUI.filterPanel:SetPoint("TOPLEFT",child,"TOPLEFT",12,y)
 achUI.filterPanel:SetHeight(panelHeight)
 achUI.filterDivider1:SetShown(not fold);achUI.filterDivider2:SetShown(not fold);achUI.filterDivider3:SetShown(not fold)
 y=y-panelHeight-12
 local recent=achUI.UpdateRecentPanel(data,german)
 recent:ClearAllPoints();recent:SetPoint("TOPLEFT",child,"TOPLEFT",12,y)
 recent:Show()
 y=y-achUI.RECENT_HEIGHT-18
 if secretMode then
  local total,available=MCF:GetSecretPoints(data)
  local how=achUI.AcquireAchievementHeader(achUI.FONT.body);Place(how,14,y,achUI.FONT.body)
  how:SetWidth(530);how:SetJustifyH("LEFT")
  how:SetText(german and ("So kommst du an Punkte: Jeder erreichte Erfolg gibt Punkte (leicht 1, mittel 3, schwer 5). Jeder ikonische Moment gibt zusätzlich "..MCF.IconicPoints.." Punkte. Mit den Punkten enthüllst du Geheimnisse: zufällig für "..MCF.SecretCost.random.." oder gezielt für "..MCF:SecretCostText().." (leicht / mittel / schwer).")
   or ("How to get points: every achievement earned gives points (easy 1, medium 3, hard 5). Every iconic moment adds "..MCF.IconicPoints.." more. Spend points to reveal secrets: random for "..MCF.SecretCost.random..", or a chosen one for "..MCF:SecretCostText().." (easy / medium / hard)."))
  y=y-math.max(30,(how.GetStringHeight and how:GetStringHeight() or 42))-8
 end
 local lastCategory
 local needle=string.lower(achUI.searchText or "")
 -- While searching, collapsed categories are ignored so every hit is visible.
 local collapsed=needle~="" and {} or achUI.CollapsedCategories()
 local hits=0
 local stats={} -- per category: earned / total of the achievements this mode lists
 for _,a in ipairs(data) do
  local listed=secretMode and a.secret or (not secretMode and not a.secret and (not a.hidden or a.unlocked))
  if listed then
   local st=stats[a.category] or {earned=0,total=0}
   stats[a.category]=st
   st.total=st.total+1
   if a.unlocked and not a.tampered then st.earned=st.earned+1 end
  end
 end
 for _,a in ipairs(data) do
  local secret=a.secret
  -- Status and difficulty filters apply to everything: category and difficulty of a secret are visible, only name and text are hidden.
  local statusOk=(a.unlocked and achUI.achievementFilter.done) or (not a.unlocked and achUI.achievementFilter.open)
  local revealedSecret=secret and MCF:IsSecretRevealed(a)
  local revealed=not secret or revealedSecret
  local shownTitle=revealed and a.name or ((german and "Geheimer Erfolg #" or "Secret achievement #")..string.sub(a.id,-3))
  local shownDesc=revealed and a.description or (german and "Bedingung und Fortschritt unbekannt" or "Condition and progress unknown")
  local show
  if badOn then -- unverified only: status and difficulty filters do not apply
   show=a.tampered and ((secretMode and secret) or (not secretMode and not secret)) and true or false
  else
   show=(achUI.achievementMode=="secrets" and secret and statusOk and achUI.achievementFilter[a.tier])
    or (achUI.achievementMode=="normal" and not secret and (not a.hidden or a.unlocked) and achUI.achievementFilter[a.tier] and statusOk)
  end
  if show and needle~="" then
   local haystack=string.lower(shownTitle.."\n"..shownDesc.."\n"..(a.categoryName or ""))
   show=string.find(haystack,needle,1,true)~=nil
  end
  if show then
   hits=hits+1
   if a.category~=lastCategory then
    lastCategory=a.category
    local cat=achUI.AcquireCategoryButton()
    cat.categoryKey=a.category
    cat:ClearAllPoints(); cat:SetPoint("TOPLEFT",12,y-2)
    achUI.achievementRows[#achUI.achievementRows+1]=cat
    achUI.ApplyScaledFont(cat.arrow,achUI.FONT.title)
    achUI.ApplyScaledFont(cat.label,achUI.FONT.title)
    achUI.ApplyScaledFont(cat.count,achUI.FONT.body)
    cat.arrow:SetText(collapsed[a.category] and "+" or "-")
    cat.label:SetText(a.categoryName)
    local st=stats[a.category] or {earned=0,total=0}
    cat.count:SetText(st.earned.." / "..st.total.." "..(german and "erreicht" or "earned"))
    cat.label:SetTextColor(1,0.82,0); cat.arrow:SetTextColor(1,0.82,0)
    y=y-34
   end
   if not collapsed[a.category] then
   local card=achUI.AcquireAchievementCard()
   card:ClearAllPoints(); card:SetPoint("TOPLEFT",12,y)
   achUI.achievementRows[#achUI.achievementRows+1]=card
   if a.id==achUI.focusId then achUI.focusY=y end
   local color=a.tierColor
   if a.tampered then card:SetBackdropBorderColor(1,0.15,0.15,1)
   elseif a.unlocked then card:SetBackdropBorderColor(0.92,0.72,0.16,1) else card:SetBackdropBorderColor(color[1]*0.55,color[2]*0.55,color[3]*0.55,1) end
   if a.id==achUI.focusId then card:SetBackdropBorderColor(1,1,1,1) end
   card.icon:SetTexture(a.unlocked and "Interface\\Icons\\Achievement_General" or "Interface\\Icons\\INV_Misc_QuestionMark")
   -- Completed: green tint, check mark, coloured icon, gold title. Open: neutral card, grey icon and title.
   -- Unverified (edited by hand): the whole card is red, no check mark, and it says why no points are given.
   if a.tampered then card:SetBackdropColor(1,0.35,0.35,1)
   elseif a.unlocked then card:SetBackdropColor(0.55,0.95,0.55,1) else card:SetBackdropColor(1,1,1,1) end
   card.icon:SetDesaturated(not a.unlocked or a.tampered and true or false)
   card.check:SetShown(a.unlocked and not a.tampered and true or false)
   card.barBack:SetShown(not a.tampered); card.bar:SetShown(not a.tampered)
   if a.tampered then card.title:SetTextColor(1,0.4,0.4) elseif a.unlocked then card.title:SetTextColor(1,0.82,0) else card.title:SetTextColor(0.72,0.72,0.72) end
   card.title:SetText(shownTitle)
   if a.tampered then
    card.desc:SetText("|cffffb0b0"..(german and "Dieser Erfolg wurde fehlerhaft gutgeschrieben, deshalb werden dafür keine Punkte vergeben." or "This achievement was credited incorrectly, so no points are awarded for it.").."|r")
   else card.desc:SetText(shownDesc) end
   card.tierText:SetText(a.tierName.." |cffffffff+"..(a.tampered and 0 or a.points).."|r") -- the difficulty is visible even for unrevealed secrets
   card.tierText:SetTextColor(color[1],color[2],color[3])
   local fraction=a.unlocked and 1 or (revealed and math.min(1,(a.value or 0)/a.target) or 0)
   card.bar:SetColorTexture(color[1],color[2],color[3],a.unlocked and 0.9 or 0.7)
   card.bar:SetWidth(math.max(1,355*fraction))
   if a.unlocked then
    local when=a.unlocked.time and date(german and "%d.%m.%Y" or "%Y-%m-%d",a.unlocked.time) or ""
    if a.tampered then card.count:SetText("") -- the red card and its text already say it; the reset button sits vertically centred
     local b=achUI.AcquireSecretBuyButton()
     b:ClearAllPoints();b:SetPoint("RIGHT",card,"RIGHT",-12,-6)
     b:SetText(german and "Zurücksetzen" or "Reset")
     local resetId=a.id
     b:SetScript("OnClick",function() achUI.ConfirmTamperReset(resetId) end)
     b:SetEnabled(true)
     achUI.activeSecretButtons[#achUI.activeSecretButtons+1]=b
    else card.count:SetText("|cff44ff44"..(german and "Erreicht" or "Earned").."|r\n|cff9d9d9d"..when.."|r") end
   elseif not revealed then
    card.count:SetText("")
    local b=achUI.AcquireSecretBuyButton()
    b:ClearAllPoints();b:SetPoint("BOTTOMRIGHT",card,"BOTTOMRIGHT",-9,7)
    local secretCost=MCF:SecretCostFor(a.tier)
    b:SetText((german and "Enthüllen (" or "Reveal (")..secretCost..")")
    local secretId=a.id
    b:SetScript("OnClick",function() achUI.ConfirmSecret(secretId,secretCost) end)
    b:SetEnabled(select(2,MCF:GetSecretPoints(data))>=secretCost)
    achUI.activeSecretButtons[#achUI.activeSecretButtons+1]=b
   else
    card.count:SetText(a.progress.." / "..a.target)
   end
   y=y-(achUI.ACHIEVEMENT_CARD_HEIGHT+achUI.ACHIEVEMENT_CARD_GAP)
   end
  end
 end
 if needle~="" and hits==0 then
  local none=achUI.AcquireAchievementHeader(achUI.FONT.body);Place(none,14,y,achUI.FONT.body)
  none:SetWidth(530);none:SetJustifyH("LEFT")
  none:SetText(german and ("Keine Erfolge gefunden für \""..achUI.searchText.."\".") or ("No achievements found for \""..achUI.searchText.."\"."))
  y=y-40
 end
 return -y+30
end
local function SetView(mode)
    viewMode=mode
    if mode=="characters" and modernLayout then
        selectedAccountCharacter=nil -- The parent item is the account-wide overview.
        UpdateNavigation()
    end
    local selected = mode=="overview" and overviewButton
        or mode=="levels" and levelsButton
        or mode=="journal" and journalTab
        or mode=="gold" and goldTab
        or mode=="dungeons" and dungeonTab
        or mode=="professions" and professionsTab
        or mode=="reputation" and reputationTab
        or mode=="characters" and charactersTab
        or mode=="achievements" and achievementsTab
        or mode=="iconic" and iconicTab
        or screenshotTab

    for _,tab in ipairs(tabs) do
        local active=(tab==selected)
        if active then
            tab.bg:SetColorTexture(0.18,0.14,0.05,0.98)
            tab.line:SetHeight(3)
            tab.label:SetTextColor(1,0.82,0.20)
        else
            tab.bg:SetColorTexture(0.08,0.08,0.08,0.95)
            tab.line:SetHeight(1)
            tab.label:SetTextColor(0.75,0.75,0.75)
        end
    end

    MCF:RefreshUI()
    scroll:SetVerticalScroll(0)
end

overviewButton:SetScript("OnClick",function() SetView("overview") end)
levelsButton:SetScript("OnClick",function() SetView("levels") end)
journalTab:SetScript("OnClick",function() SetView("journal") end)
goldTab:SetScript("OnClick",function() SetView("gold") end)
dungeonTab:SetScript("OnClick",function() SetView("dungeons") end)
professionsTab:SetScript("OnClick",function() SetView("professions") end)
reputationTab:SetScript("OnClick",function() SetView("reputation") end)
charactersTab:SetScript("OnClick",function() SetView("characters") end)
screenshotTab:SetScript("OnClick",function() SetView("screenshots") end)
achievementsTab:SetScript("OnClick",function() SetView("achievements") end)
iconicTab:SetScript("OnClick",function() SetView("iconic") end)
-- Setting "achievementsEnabled": hides the tab and leaves the achievements view if it is open.
function MCF:ApplyAchievementsSetting()
    if not self:AchievementsEnabled() and viewMode=="achievements" then SetView("overview") end
    UpdateNavigation()
    if self.RefreshUI then self:RefreshUI() end
end
-- Setting "iconicEnabled": same for the iconic-moments tab (and the map stars).
function MCF:ApplyIconicSetting()
    if not self:IconicEnabled() and viewMode=="iconic" then SetView("overview") end
    UpdateNavigation()
    if self.RefreshUI then self:RefreshUI() end
    if self.RefreshMapJourney then self:RefreshMapJourney() end
end
-- Opens the achievements tab; with an id, makes that achievement visible (filters, category, scroll) and
-- outlines it for a few seconds. Used by the achievement popup.
function MCF:OpenAchievements(id)
    achUI.focusId,achUI.focusY=id,nil
    if id then
        for _,a in ipairs(MCF:GetAchievements()) do
            if a.id==id then
                achUI.achievementMode=a.secret and "secrets" or "normal"
                local f=achUI.achievementFilter
                f.done,f.open,f.bad=true,true,false
                if a.tier then f[a.tier]=true end
                achUI.CollapsedCategories()[a.category]=false
                for _,control in ipairs(achUI.achievementFilterControls) do
                    local key=control.key
                    if key and f[key]~=nil then control[1]:SetChecked(f[key]) end
                end
            end
        end
    end
    frame:Show()
    SetView("achievements")
    if id then
        C_Timer.After(0.05,function()
            if achUI.focusY then
                local range=scroll:GetVerticalScrollRange() or 0
                scroll:SetVerticalScroll(math.max(0,math.min(range,-achUI.focusY-70)))
            end
        end)
        C_Timer.After(8,function() if achUI.focusId==id then achUI.focusId=nil; if frame:IsShown() then MCF:RefreshUI() end end end)
    end
end
SetView("overview")
frame:HookScript("OnShow",function()
    -- Account data is initialized after UI.lua loads. Populate the sidebar on
    -- every opening, not only after clicking Accountübersicht.
    if modernLayout then
        UpdateNavigation()
        -- OnShow resets geometry before the navigation is populated.
        -- Recompute once the account character list is available.
        ResetWindowGeometry()
    end
    MCF:RefreshUI()
end)

-- Public UI API used by the minimap button and future integrations.
MCF.mainFrame=frame
function MCF:ShowMainWindow()
    SetView("overview")
    self:RefreshUI()
    frame:Show()
    frame:Raise()
end
function MCF:ToggleMainWindow()
    if frame:IsShown() then
        frame:Hide()
    else
        self:ShowMainWindow()
    end
end

-- Commands (usage text, examples and dispatch all come from this one list).
local function AddCmd(e) MCF:AddCommand(e) end
AddCmd{group="main",usage="/mcf",de="Hauptfenster ein-/ausblenden (auch /mycharforever)",en="Show/hide the main window (also /mycharforever)"}
AddCmd{group="main",usage="/mcf help",example="/mcf ?",key="help",de="Diese Befehlsliste anzeigen",en="Show this command list",
    run=function() MCF:PrintCommandHelp() end}
AddCmd{group="main",usage="/mcf ?",key="?",run=function() MCF:PrintCommandHelp() end,
    de="Wie /mcf help",en="Same as /mcf help",hidden=true}
AddCmd{group="main",usage="/mcf resetui",key="resetui",de="Fensterposition und -größe zurücksetzen",en="Reset window position and size",
    run=function()
        ResetWindowGeometry()
        if not frame:IsShown() then frame:Show() end
        MCF:RefreshUI()
    end}
AddCmd{group="main",usage="/mcf snapshot",key="snapshot",de="Ausrüstungs-Snapshot für das aktuelle Level jetzt anlegen",en="Take a gear snapshot for the current level now",
    run=function() if MCF.CaptureManualCurrentLevelSnapshot then MCF:CaptureManualCurrentLevelSnapshot() end end}
AddCmd{group="main",usage="/mcf gear",key="gear",de="Erfasste Ausrüstung prüfen (Slots, Transmog-IDs)",en="Check recorded gear (slots, transmog IDs)",
    run=function() if MCF.PrintGearReport then MCF:PrintGearReport() end end}
AddCmd{group="main",usage="/mcf gear probe",key="gear probe",de="Transmog-Schnittstellen des Clients auflisten (Diagnose, bitte Ausgabe schicken)",en="List the client's transmog interfaces (diagnostics, please send the output)",
    run=function() if MCF.PrintGearProbe then MCF:PrintGearProbe() end end}
AddCmd{group="main",usage="/mcf size",key="size",de="Datenverbrauch pro Bereich anzeigen",en="Show data usage per section",
    run=function() MCF:PrintDataSizeReport() end}
AddCmd{group="main",usage="/mcf maintain",key="maintain",de="Datenwartung jetzt ausführen (siehe Einstellungen, Bereich Datenbank)",en="Run data maintenance now (see settings, Database section)",
    run=function() print("|cff00ccffMyCharForever|r: "..MCF:DescribeMaintenance(MCF:RunMaintenance(true))) end}
AddCmd{group="test",usage="/mcf droptest",key="droptest",de="Fake-Weltdrop an deiner Position erzeugen (Karte und Journal testen)",en="Create a fake world drop at your position (test map and journal)",
    run=function()
        local entry=MCF:AddTestWorldDrop()
        print("|cff00ccffMyCharForever|r: "..(entry and MCF:T("Test drop added. Remove with /mcf droptest clear") or "no map position"))
    end}
AddCmd{group="test",usage="/mcf droptest clear",key="droptest clear",de="Alle Fake-Weltdrops wieder entfernen",en="Remove all fake world drops",
    run=function() print("|cff00ccffMyCharForever|r: "..MCF:T("Test drops removed: ")..MCF:ClearTestWorldDrops()) end}
AddCmd{group="test",usage="/mcf goldtest [days]",example="/mcf goldtest 500",
    de="Simulierten Gold-Verlauf erzeugen (Standard 200, max. 2000 Tage)",en="Create a simulated gold history (default 200, max 2000 days)",
    match=function(msg) return msg=="goldtest" or msg:match("^goldtest%s+%d+$")~=nil end,
    run=function(msg)
        local days=msg:match("^goldtest%s+(%d+)$")
        MCF:SimulateGoldHistory(math.min(2000,tonumber(days) or 200))
        SetView("gold")
        frame:Show()
    end}
AddCmd{group="test",usage="/mcf goldtest clear",key="goldtest clear",de="Simulierten Gold-Verlauf löschen",en="Delete the simulated gold history",
    run=function() MCF:ClearSimulatedGoldHistory() end}

SLASH_MYCHARFOREVER1="/mcf"; SLASH_MYCHARFOREVER2="/mycharforever"
SlashCmdList["MYCHARFOREVER"]=function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "" then
        if frame:IsShown() then frame:Hide() else MCF:RefreshUI(); frame:Show() end
    elseif not MCF:RunCommand(msg) then
        print("|cff00ccffMyCharForever|r: "..(MCF:GetLanguage()=="deDE" and "Unbekannter Befehl" or "Unknown command").." '"..msg.."' - /mcf help")
    end
end
