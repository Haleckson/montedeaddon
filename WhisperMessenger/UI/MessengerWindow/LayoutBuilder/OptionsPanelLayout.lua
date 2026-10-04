local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local ScrollView=ns.ScrollView or require("WhisperMessenger.UI.ScrollView")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local applyColorTexture=UIHelpers.applyColorTexture
local sizeValue=UIHelpers.sizeValue

local OptionsPanelLayout={}

function OptionsPanelLayout.Build(factory,frame,initialState,options)
options=options or{}

local theme=options.theme or Theme
local contactsWidth=options.contactsWidth
local scrollView=options.scrollView or ScrollView
local applyTexture=options.applyColorTexture or applyColorTexture



local nativeChrome=options.nativeChrome==true






local optionsPanel=factory.CreateFrame("Frame",nil,frame)





if nativeChrome then
optionsPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
optionsPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
else
optionsPanel:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-20)
optionsPanel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,5)
end




local optionsMenu=factory.CreateFrame("Frame",nil,optionsPanel)
optionsMenu:SetPoint("TOPLEFT",optionsPanel,"TOPLEFT",0,0)
optionsMenu:SetPoint("BOTTOMLEFT",optionsPanel,"BOTTOMLEFT",0,0)
optionsMenu:SetWidth(contactsWidth)

local optionsMenuBg=optionsMenu:CreateTexture(nil,"BACKGROUND")
optionsMenuBg:SetAllPoints(optionsMenu)
applyTexture(optionsMenuBg,theme.COLORS.bg_secondary)

local menuPadding=theme.CONTENT_PADDING
local OPTIONS_MENU_MIN_CONTENT_HEIGHT=430
local optionsMenuViewportHeight=nativeChrome and options.contactsHeight or(initialState.height-theme.TOP_BAR_HEIGHT)
local optionsMenuScrollView=scrollView.Create(factory,optionsMenu,{
width=contactsWidth,
height=optionsMenuViewportHeight,
step=24,
})
if optionsMenuScrollView.scrollBar.ClearAllPoints then
optionsMenuScrollView.scrollBar:ClearAllPoints()
end
optionsMenuScrollView.scrollBar:SetPoint("TOPRIGHT",optionsMenu,"TOPRIGHT",0,0)

local function refreshOptionsMenuScrollGeometry()
local menuWidth=sizeValue(optionsMenu,"GetWidth","width",contactsWidth)
local menuHeight=sizeValue(optionsMenu,"GetHeight","height",optionsMenuViewportHeight)
local menuContentHeight=math.max(menuHeight,OPTIONS_MENU_MIN_CONTENT_HEIGHT)

optionsMenuScrollView.totalWidth=menuWidth
optionsMenuScrollView.viewportHeight=menuHeight
optionsMenuScrollView.hasOverflow=false
optionsMenuScrollView.scrollFrame:SetSize(menuWidth,menuHeight)
optionsMenuScrollView.content:SetSize(menuWidth,menuContentHeight)
optionsMenuScrollView.scrollBar:SetHeight(menuHeight)
scrollView.RefreshMetrics(optionsMenuScrollView,menuContentHeight)
end

refreshOptionsMenuScrollGeometry()

local optionsHeader=optionsMenuScrollView.content:CreateFontString(nil,"OVERLAY",theme.FONTS.header_name)
optionsHeader:SetPoint("TOPLEFT",optionsMenuScrollView.content,"TOPLEFT",menuPadding,-menuPadding)
optionsHeader:SetText(Localization.Text("Options"))

local optionsMenuDivider=optionsPanel:CreateTexture(nil,"BORDER")
optionsMenuDivider:SetPoint("TOPLEFT",optionsMenu,"TOPRIGHT",0,0)
optionsMenuDivider:SetPoint("BOTTOMLEFT",optionsMenu,"BOTTOMRIGHT",0,0)
optionsMenuDivider:SetWidth(theme.DIVIDER_THICKNESS)
applyTexture(optionsMenuDivider,theme.COLORS.divider)





local optionsContentPane=factory.CreateFrame("Frame",nil,optionsPanel)

local contentTopGap=nativeChrome and 0 or 2
local contentRightInset=nativeChrome and 0 or 4
optionsContentPane:SetPoint("TOPLEFT",optionsMenu,"TOPRIGHT",theme.DIVIDER_THICKNESS,-contentTopGap)
optionsContentPane:SetPoint("BOTTOMRIGHT",optionsPanel,"BOTTOMRIGHT",-contentRightInset,0)



local optionsContentWidth=nativeChrome and options.optionsContentWidth or(initialState.width-contactsWidth-theme.DIVIDER_THICKNESS-4)
local optionsContentH=nativeChrome and options.contactsHeight or(initialState.height-theme.TOP_BAR_HEIGHT-28-2)
optionsContentPane:SetSize(optionsContentWidth,optionsContentH)

local optionsContentBg=optionsContentPane:CreateTexture(nil,"BACKGROUND")
optionsContentBg:SetAllPoints(optionsContentPane)
applyTexture(optionsContentBg,theme.COLORS.bg_primary)







local OPTIONS_CONTENT_HEIGHT=800
local optionsScrollView=scrollView.Create(factory,optionsContentPane,{
width=optionsContentWidth,
height=optionsContentH,
step=24,
})
optionsScrollView.content:SetSize(optionsContentWidth,OPTIONS_CONTENT_HEIGHT)






if optionsPanel.SetScript then
optionsPanel:SetScript("OnShow",function()
refreshOptionsMenuScrollGeometry()
scrollView.Sync(optionsScrollView)
end)
end

local function setLanguage()
optionsHeader:SetText(Localization.Text("Options"))
end

return{
optionsPanel=optionsPanel,
optionsMenu=optionsMenu,
optionsMenuBg=optionsMenuBg,
menuPadding=menuPadding,
optionsMenuScrollView=optionsMenuScrollView,
optionsMenuMinimumContentHeight=OPTIONS_MENU_MIN_CONTENT_HEIGHT,
refreshOptionsMenuScrollGeometry=refreshOptionsMenuScrollGeometry,
optionsHeader=optionsHeader,
optionsMenuDivider=optionsMenuDivider,
optionsContentPane=optionsContentPane,
optionsContentBg=optionsContentBg,
optionsScrollView=optionsScrollView,
optionsContentHeight=OPTIONS_CONTENT_HEIGHT,
setLanguage=setLanguage,
}
end

ns.MessengerWindowLayoutOptionsPanelLayout=OptionsPanelLayout

return OptionsPanelLayout
