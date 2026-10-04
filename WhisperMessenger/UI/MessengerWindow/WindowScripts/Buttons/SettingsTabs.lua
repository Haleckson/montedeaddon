local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local ScrollView=ns.ScrollView or require("WhisperMessenger.UI.ScrollView.ScrollView")

local SettingsTabs={}









local function measurePanelContentHeight(panel)
if type(panel)~="table"then
return 0
end
local marker=panel._wmBottomMarker
if not marker or type(panel.GetTop)~="function"or type(marker.GetBottom)~="function"then
return 0
end
local panelTop=panel:GetTop()
local markerBottom=marker:GetBottom()
if type(panelTop)~="number"or type(markerBottom)~="number"then
return 0
end
local height=panelTop-markerBottom
if height<=0 then
return 0
end
return height
end

function SettingsTabs.Wire(options)
options=options or{}

local optionsPanel=options.optionsPanel
local optionsScrollView=options.optionsScrollView
local settingsTabs=options.settingsTabs or{}
local settingsPanels=options.settingsPanels or{}
local theme=options.theme or Theme
local scrollView=options.scrollView or ScrollView
local measureContentHeight=options.measurePanelContentHeight or measurePanelContentHeight
local function getPanel(index)
local panel=settingsPanels[index]
if not panel and type(settingsPanels.getPanel)=="function"then
panel=settingsPanels.getPanel(index)
end
return panel
end

if#settingsTabs==0 or#settingsPanels==0 then
return
end

local function activeHighlightColor()
return theme.COLORS.option_button_active or theme.COLORS.bg_contact_selected or{0.16,0.18,0.28,0.80}
end
local function activeHoverColor()
return theme.COLORS.option_button_active_hover or activeHighlightColor()
end
local function inactiveBackgroundColor()
return theme.COLORS.option_button_bg or{0.14,0.15,0.20,0.80}
end
local function inactiveHoverColor()
return theme.COLORS.option_button_hover or inactiveBackgroundColor()
end
local function inactiveTextColor()
return theme.COLORS.option_button_text or theme.COLORS.text_secondary
end
local function inactiveTextHoverColor()
return theme.COLORS.option_button_text_hover or theme.COLORS.text_primary
end
local function activeTextColor()
return theme.COLORS.option_button_text_active or theme.COLORS.text_primary
end






local function applyVisibleTabContentHeight(visiblePanel)
if not visiblePanel or not optionsScrollView or not optionsScrollView.content then
return false
end
if type(optionsScrollView.content.SetHeight)~="function"then
return false
end
local contentHeight=measureContentHeight(visiblePanel)
if contentHeight<=0 then
return false
end
optionsScrollView.content:SetHeight(contentHeight)
if scrollView and type(scrollView.Sync)=="function"then
scrollView.Sync(optionsScrollView)
end
return true
end

local function scheduleVisibleTabRemeasure(visiblePanel)
if not visiblePanel then
return
end





if _G.C_Timer and type(_G.C_Timer.After)=="function"then
_G.C_Timer.After(0,function()
applyVisibleTabContentHeight(visiblePanel)
end)
end
end

local wiredPanels={}

local function wirePanel(panel)
if not panel or wiredPanels[panel]then
return
end
wiredPanels[panel]=true


panel._wmRemeasure=function()
scheduleVisibleTabRemeasure(panel)
end
if type(panel.HookScript)~="function"then
return
end
panel:HookScript("OnSizeChanged",function(self)
if type(self.IsShown)=="function"and not self:IsShown()then
return
end
if not applyVisibleTabContentHeight(self)then
scheduleVisibleTabRemeasure(self)
end
end)
end

local function selectTab(index)
local visiblePanel=getPanel(index)
wirePanel(visiblePanel)
for i,panel in ipairs(settingsPanels)do
if panel and panel.Hide and panel.Show then
if i==index then
panel:Show()
else
panel:Hide()
end
end
end
if not applyVisibleTabContentHeight(visiblePanel)then
scheduleVisibleTabRemeasure(visiblePanel)
end






if optionsScrollView and scrollView and scrollView.SetVerticalScroll then
scrollView.SetVerticalScroll(optionsScrollView,0)
end
for i,tab in ipairs(settingsTabs)do
if tab and tab.bg and tab.SetScript then
local bg=tab.bg
local function applyTabVisual(hovered)
local isActive=tab._wmIsActiveTab==true
local color
local textColor
local hoverBg
local hoverText
if isActive then
color=activeHighlightColor()
hoverBg=activeHoverColor()
textColor=activeTextColor()
hoverText=activeTextColor()
else
color=inactiveBackgroundColor()
hoverBg=inactiveHoverColor()
textColor=inactiveTextColor()
hoverText=inactiveTextHoverColor()
end
if tab.applyThemeColors then
tab.applyThemeColors({
bg=color,
bgHover=hoverBg,
text=textColor,
textHover=hoverText,
})
end


if tab.setNavActive then
tab._wmHovered=hovered
tab.setNavActive(isActive)
return
end
local paintColor=hovered and hoverBg or color
if bg and bg.SetColorTexture then
bg:SetColorTexture(paintColor[1],paintColor[2],paintColor[3],paintColor[4]or 1)
end
if tab.label and tab.label.SetTextColor then
local paintText=hovered and hoverText or textColor
tab.label:SetTextColor(paintText[1],paintText[2],paintText[3],paintText[4]or 1)
end
end
tab._wmIsActiveTab=i==index
tab._wmIsHoveredTab=tab.IsMouseOver and tab:IsMouseOver()or false
applyTabVisual(tab._wmIsHoveredTab)
tab:SetScript("OnEnter",function()
tab._wmIsHoveredTab=true


tab._wmHovered=true
applyTabVisual(true)
end)
tab:SetScript("OnLeave",function()
tab._wmIsHoveredTab=false
tab._wmHovered=false
applyTabVisual(false)
end)
end
end
end

for i,tab in ipairs(settingsTabs)do
if tab and tab.SetScript then
local tabIndex=i
tab:SetScript("OnClick",function()
selectTab(tabIndex)
end)
end
end


selectTab(1)





if optionsPanel and type(optionsPanel.HookScript)=="function"then
optionsPanel:HookScript("OnShow",function()
for i,panel in ipairs(settingsPanels)do
if panel and type(panel.IsShown)=="function"and panel:IsShown()then
selectTab(i)
return
end
end
end)
end





for _,panel in ipairs(settingsPanels)do
wirePanel(panel)
end

return{selectTab=selectTab}
end

ns.MessengerWindowWindowScriptsButtonsSettingsTabs=SettingsTabs

return SettingsTabs
