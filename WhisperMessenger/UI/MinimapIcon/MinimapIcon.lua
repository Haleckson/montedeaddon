local addonName,ns=...
if type(ns)~="table"then
ns={}
end
local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local applyVertexColor=UIHelpers.applyVertexColor
local Badge=ns.Badge or require("WhisperMessenger.UI.Badge")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local KeybindHints=ns.KeybindHints or require("WhisperMessenger.UI.Shared.KeybindHints")
local IncomingPreview=ns.ToggleIconIncomingPreview or require("WhisperMessenger.UI.ToggleIcon.IncomingPreview")
local PulseGlow=ns.ToggleIconPulseGlow or require("WhisperMessenger.UI.ToggleIcon.PulseGlow")
local Desaturation=ns.ToggleIconDesaturation or require("WhisperMessenger.UI.ToggleIcon.Desaturation")

local MinimapIcon={}



local ICON_SIZE=30
local ICON_TEXTURE="Interface\\AddOns\\WhisperMessenger\\Media\\icon.png"
local BADGE_SIZE=14
local BADGE_LEVEL_OFFSET=10

local BG_COLOR={0.08,0.08,0.08,0.85}
local BORDER_COLOR={0.3,0.3,0.3,0.4}
local ICON_COLOR={1,1,1,1}


local DEFAULT_DEGREES=45

local ICON_RADIUS_OFFSET=5




local MINIMAP_SHAPES={
["ROUND"]={true,true,true,true},
["SQUARE"]={false,false,false,false},
["CORNER-TOPLEFT"]={false,false,false,true},
["CORNER-TOPRIGHT"]={false,false,true,false},
["CORNER-BOTTOMLEFT"]={false,true,false,false},
["CORNER-BOTTOMRIGHT"]={true,false,false,false},
["SIDE-LEFT"]={false,true,false,true},
["SIDE-RIGHT"]={true,false,true,false},
["SIDE-TOP"]={false,false,true,true},
["SIDE-BOTTOM"]={true,true,false,false},
["TRICORNER-TOPLEFT"]={false,true,true,true},
["TRICORNER-TOPRIGHT"]={true,false,true,true},
["TRICORNER-BOTTOMLEFT"]={true,true,false,true},
["TRICORNER-BOTTOMRIGHT"]={true,true,true,false},
}



local rad,deg,cos,sin,sqrt,max,min=math.rad,math.deg,math.cos,math.sin,math.sqrt,math.max,math.min


local atan2=math.atan2 or math.atan

local function getMinimapShape()
if type(_G.GetMinimapShape)=="function"then
return _G.GetMinimapShape()or"ROUND"
end
return"ROUND"
end




local function updatePosition(button,parent,positionDegrees,radiusOffset)
local angle=rad(positionDegrees)
local x,y=cos(angle),sin(angle)

local q=1
if x<0 then
q=q+1
end
if y>0 then
q=q+2
end

local shape=getMinimapShape()
local quadTable=MINIMAP_SHAPES[shape]or MINIMAP_SHAPES["ROUND"]
local w=(parent:GetWidth()or 140)/2+(radiusOffset or ICON_RADIUS_OFFSET)
local h=(parent:GetHeight()or 140)/2+(radiusOffset or ICON_RADIUS_OFFSET)

if quadTable and quadTable[q]then

x,y=x*w,y*h
else

local diagRadiusW=sqrt(2*w*w)-10
local diagRadiusH=sqrt(2*h*h)-10
x=max(-w,min(x*diagRadiusW,w))
y=max(-h,min(y*diagRadiusH,h))
end

if button.ClearAllPoints then
button:ClearAllPoints()
end
button:SetPoint("CENTER",parent,"CENTER",x,y)
end



function MinimapIcon.Create(factory,options)
options=options or{}

local parent=options.parent or _G.Minimap or _G.UIParent
local state=options.state or{}
local degrees=state.degrees or DEFAULT_DEGREES

local frame=factory.CreateFrame("Button","WhisperMessengerMinimapIcon",parent)
frame:SetSize(ICON_SIZE,ICON_SIZE)
frame:SetFrameStrata("HIGH")
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")


local bg=frame:CreateTexture(nil,"BACKGROUND")
bg:SetAllPoints(frame)
bg:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
applyVertexColor(bg,BG_COLOR)


local iconTex=frame:CreateTexture(nil,"ARTWORK")
iconTex:SetAllPoints(frame)
iconTex:SetTexture(ICON_TEXTURE)

local border=frame:CreateTexture(nil,"BORDER")
border:SetPoint("TOPLEFT",frame,"TOPLEFT",-1,1)
border:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",1,-1)
border:SetTexture("Interface\\COMMON\\RingBorder")
applyVertexColor(border,BORDER_COLOR)


local pulseGlow=PulseGlow.Create(factory,frame,{
theme=Theme,
accent=Theme.COLORS.accent,
})


local badgeResult=Badge.Create(factory,frame,{size=BADGE_SIZE,outline=true})
local badge=badgeResult.frame
local badgeBackground=badgeResult.background
local badgeLabel=badgeResult.label
local innerSetUnreadCount=badgeResult.setCount
badge:SetPoint("TOPRIGHT",frame,"TOPRIGHT",4,4)
badge:SetFrameLevel(frame:GetFrameLevel()+BADGE_LEVEL_OFFSET)


local incomingPreview=IncomingPreview.Create(factory,frame,{
theme=Theme,
getPreviewPosition=options.getPreviewPosition,
getPreviewAutoDismissSeconds=options.getPreviewAutoDismissSeconds,
onDismissPreview=options.onDismissPreview,
})

incomingPreview.frame:SetParent(_G.UIParent)
local setIncomingPreview=incomingPreview.setIncomingPreview

local function applyRadialPosition()
updatePosition(frame,parent,degrees,ICON_RADIUS_OFFSET)
end
if parent then
applyRadialPosition()
end

local getShowUnreadBadge=options.getShowUnreadBadge
local getBadgePulse=options.getBadgePulse



local desaturation=Desaturation.Create({
textures={chatIcon=iconTex,background=bg,border=border},
resolveColors={
chatIcon=function()
return ICON_COLOR
end,
background=function()
return BG_COLOR
end,
border=function()
return BORDER_COLOR
end,
},
getIconDesaturated=options.getIconDesaturated,
applyVertexColor=applyVertexColor,
})

local function setUnreadCount(count)
local showBadge=not getShowUnreadBadge or getShowUnreadBadge()
local allowPulse=not getBadgePulse or getBadgePulse()
local unreadCount=tonumber(count)or 0

if showBadge then
innerSetUnreadCount(count)
else
innerSetUnreadCount(0)
end

if unreadCount>0 and allowPulse and showBadge then
pulseGlow.start()
else
pulseGlow.stop()
end

desaturation.update(unreadCount)
end







if parent and frame.SetScript then
frame:SetScript("OnDragStart",function(self)
self:SetScript("OnUpdate",function()
local mx,my=parent:GetCenter()
local px,py=_G.GetCursorPosition()
local scale=parent:GetEffectiveScale()or 1
px,py=px/scale,py/scale
degrees=deg(atan2(py-my,px-mx))%360
updatePosition(self,parent,degrees,ICON_RADIUS_OFFSET)
end)
end)

frame:SetScript("OnDragStop",function(self)
self:SetScript("OnUpdate",nil)
if options.onPositionChanged then
options.onPositionChanged({degrees=degrees})
end
end)


frame:SetScript("OnClick",function(self,buttonName)
if buttonName=="LeftButton"and options.onToggle then
options.onToggle()
end
end)

frame:SetScript("OnEnter",function()
if _G.GameTooltip and _G.GameTooltip.SetOwner then
_G.GameTooltip:SetOwner(frame,"ANCHOR_BOTTOM")
_G.GameTooltip:SetText("WhisperMessenger")
local showBadge=not getShowUnreadBadge or getShowUnreadBadge()
if showBadge and badge:IsShown()then
_G.GameTooltip:AddLine((badgeLabel:GetText()or"").." "..(Localization and Localization.Text("unread")or"unread"))
end
KeybindHints.AddToTooltip(_G.GameTooltip,type(options.getHideFromDefaultChat)=="function"and options.getHideFromDefaultChat()==true)
_G.GameTooltip:Show()
end
end)

frame:SetScript("OnLeave",function()
if _G.GameTooltip and _G.GameTooltip.Hide then
_G.GameTooltip:Hide()
end
end)
end



local function setShown(shown)
if shown then
frame:Show()
return
end
frame:Hide()
setIncomingPreview(nil,nil,nil)
end

local function isShown()
return frame.IsShown and frame:IsShown()==true
end

local function refreshTheme()
badgeResult.paint()
incomingPreview.applyTheme(Theme)
pulseGlow.applyTheme(Theme)
desaturation.refresh()
end

setUnreadCount(options.unreadCount or 0)

refreshTheme()

return{
frame=frame,
iconTex=iconTex,
border=border,
badge=badge,
badgeBackground=badgeBackground,
badgeLabel=badgeLabel,
pulseGlow=pulseGlow,
previewFrame=incomingPreview.frame,
setUnreadCount=setUnreadCount,
setIncomingPreview=setIncomingPreview,
applyPreviewPosition=incomingPreview.applyPreviewPosition,
refreshDesaturation=desaturation.refresh,
refreshTheme=refreshTheme,
applyRadialPosition=applyRadialPosition,
setShown=setShown,
isShown=isShown,
}
end

ns.MinimapIcon=MinimapIcon
return MinimapIcon
