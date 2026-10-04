local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local sizeValue=UIHelpers.sizeValue

local Apply={}

function Apply.Relayout(layout,relayout,theme)
local resolvedTheme=theme or Theme
local layoutTheme=resolvedTheme.LAYOUT or{}

local contactsWidth=relayout.contactsWidth
local contactsHeight=relayout.contactsHeight
local contentWidth=relayout.contentWidth
local contentHeight=relayout.contentHeight
local threadHeight=relayout.threadHeight
local searchHeight=relayout.searchHeight
local searchMargin=relayout.searchMargin
local searchTotalHeight=relayout.searchTotalHeight
local contactsListHeight=relayout.contactsListHeight

layout.contactsWidth=contactsWidth

layout.contactsPane:SetSize(contactsWidth,contactsHeight)

local contactsPaneParent=layout.contactsPane.GetParent and layout.contactsPane:GetParent()or layout.contactsPane.parent
if contactsPaneParent and layout.contactsPane.ClearAllPoints then
layout.contactsPane:ClearAllPoints()
layout.contactsPane:SetPoint(
"TOPLEFT",
contactsPaneParent,
"TOPLEFT",
layoutTheme.CONTACTS_PANE_LEFT_INSET,
layout.contactsTopOffset or-layoutTheme.TOP_BAR_HEIGHT
)
layout.contactsPane:SetPoint(
"BOTTOMLEFT",
contactsPaneParent,
"BOTTOMLEFT",
layoutTheme.CONTACTS_PANE_BOTTOM_LEFT_INSET,
layoutTheme.CONTACTS_PANE_BOTTOM_INSET
)
end
layout.contactsDivider:SetSize(UIHelpers.hairlineThickness(layout.contactsDivider,resolvedTheme.DIVIDER_THICKNESS),contactsHeight)
if layout.contactsResizeHandle then
local handleWidth=
sizeValue(layout.contactsResizeHandle,"GetWidth","width",layout.contactsHandleWidth or Theme.LAYOUT.CONTACTS_RESIZE_HANDLE_WIDTH)
layout.contactsResizeHandle:SetSize(handleWidth,contactsHeight)
if layout.contactsResizeHandle.ClearAllPoints then
layout.contactsResizeHandle:ClearAllPoints()
end
layout.contactsResizeHandle:SetPoint("TOPLEFT",layout.contactsPane,"TOPRIGHT",-math.floor(handleWidth/2),0)
end

if layout.contactsSearchFrame then
local insetX=resolvedTheme.LAYOUT.CONTACT_SEARCH_INSET_X or searchMargin
layout.contactsSearchFrame:SetSize(math.max(0,contactsWidth-(insetX*2)),searchHeight)
if layout.contactsSearchFrame.ClearAllPoints then
layout.contactsSearchFrame:ClearAllPoints()
end
layout.contactsSearchFrame:SetPoint("TOPLEFT",layout.contactsPane,"TOPLEFT",insetX,-searchMargin)
end

layout.contentPane:SetSize(contentWidth,contentHeight)
if layout.contentPane.ClearAllPoints then
layout.contentPane:ClearAllPoints()
end
layout.contentPane:SetPoint("TOPLEFT",layout.contactsPane,"TOPRIGHT",resolvedTheme.DIVIDER_THICKNESS,0)




local contentParentForAnchor
if layout.contactsPane then
if type(layout.contactsPane.GetParent)=="function"then
contentParentForAnchor=layout.contactsPane:GetParent()
end
if contentParentForAnchor==nil then
contentParentForAnchor=layout.contactsPane.parent
end
end
if contentParentForAnchor then
layout.contentPane:SetPoint(
"BOTTOMRIGHT",
contentParentForAnchor,
"BOTTOMRIGHT",
-Theme.LAYOUT.CONTENT_PANE_RIGHT_INSET,
Theme.LAYOUT.CONTENT_PANE_BOTTOM_INSET
)
end
if layout.headerDivider then
layout.headerDivider:SetSize(contentWidth,UIHelpers.hairlineThickness(layout.headerDivider,resolvedTheme.DIVIDER_THICKNESS))
end
layout.threadPane:SetSize(contentWidth,threadHeight)





local contentPaneWidth=(layout.contentPane.GetWidth and layout.contentPane:GetWidth())or layout.contentPane.width or contentWidth
layout.composerPane:SetSize(contentPaneWidth,resolvedTheme.COMPOSER_HEIGHT)
if layout.composerPane.ClearAllPoints then
layout.composerPane:ClearAllPoints()
layout.composerPane:SetPoint("BOTTOMLEFT",layout.contentPane,"BOTTOMLEFT",0,0)
layout.composerPane:SetPoint("BOTTOMRIGHT",layout.contentPane,"BOTTOMRIGHT",0,0)
end


local cv=layout.contactsView
if cv then
cv.totalWidth=contactsWidth
if cv.scrollFrame.ClearAllPoints then
cv.scrollFrame:ClearAllPoints()
end






cv.scrollFrame:SetPoint("TOPLEFT",layout.contactsPane,"TOPLEFT",0,-searchTotalHeight)
cv.scrollFrame:SetSize(contactsWidth,contactsListHeight)
cv.scrollFrame:SetPoint("BOTTOMRIGHT",layout.contactsPane,"BOTTOMRIGHT",0,relayout.contactsBottomInset or 0)
cv.scrollBar:SetHeight(contactsListHeight)
cv.viewportHeight=contactsListHeight
local Metrics=ns.ScrollViewMetrics or require("WhisperMessenger.UI.ScrollView.Metrics")
Metrics.RefreshMetrics(cv,sizeValue(cv.content,"GetHeight","height",contactsListHeight))
end






local optionsHeight=contactsHeight


local optionsContentWidth=relayout.optionsContentWidth
layout.optionsMenu:SetSize(contactsWidth,optionsHeight)
layout.optionsMenuDivider:SetSize(resolvedTheme.DIVIDER_THICKNESS,optionsHeight)
layout.optionsContentPane:SetSize(optionsContentWidth,optionsHeight)
layout.refreshOptionsMenuScrollGeometry()

local menuPadding=layout.menuPadding or resolvedTheme.CONTENT_PADDING
local optionsButtonWidth=math.max(0,contactsWidth-(menuPadding*2))
local optionsButtonHeight=layout.optionsButtonHeight or layoutTheme.OPTION_BUTTON_HEIGHT
if layout.optionsHint then
if layout.optionsHint.SetWidth then
layout.optionsHint:SetWidth(optionsButtonWidth)
end
if layout.optionsHint.SetWordWrap then
layout.optionsHint:SetWordWrap(true)
end
if layout.optionsHint.SetJustifyH then
layout.optionsHint:SetJustifyH("LEFT")
end
end
for _,button in ipairs({
layout.generalTab,
layout.appearanceTab,
layout.behaviorTab,
layout.notificationsTab,
layout.iconsTab,
layout.whatsNewTab,
layout.resetWindowButton,
layout.resetIconButton,
layout.clearAllChatsButton,
})do
if button and button.SetSize then
button:SetSize(optionsButtonWidth,optionsButtonHeight)
end
end


local osv=layout.optionsScrollView
if osv then
osv.scrollFrame:SetSize(optionsContentWidth,optionsHeight)
osv.scrollBar:SetHeight(optionsHeight)
osv.viewportHeight=optionsHeight
osv.totalWidth=optionsContentWidth
local Metrics=ns.ScrollViewMetrics or require("WhisperMessenger.UI.ScrollView.Metrics")
Metrics.RefreshMetrics(osv,sizeValue(osv.content,"GetHeight","height",layout.optionsContentHeight or 420))
end

return{
contactsWidth=contactsWidth,
contentWidth=contentWidth,
contactsHeight=contactsHeight,
contactsListHeight=contactsListHeight,
threadHeight=threadHeight,
}
end

ns.MessengerWindowLayoutApply=Apply

return Apply
