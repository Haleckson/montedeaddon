local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Base=ns.UIHelpersBase or require("WhisperMessenger.UI.Helpers.Base")

local Shapes={}

local CIRCLE_MASK="Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local ICON_ZOOM=1.15
local ROUNDED_CIRCLE_TEX="Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall"


local REFERENCE_UI_HEIGHT=768
local FALLBACK_PHYSICAL_HEIGHT=1080





function Shapes.pixelSize(frame)
local physicalHeight
local getPhysicalScreenSize=_G.GetPhysicalScreenSize
if type(getPhysicalScreenSize)=="function"then
local _,height=getPhysicalScreenSize()
physicalHeight=height
end
if type(physicalHeight)~="number"or physicalHeight<=0 then
physicalHeight=FALLBACK_PHYSICAL_HEIGHT
end
local scale=frame and type(frame.GetEffectiveScale)=="function"and frame:GetEffectiveScale()or 1
if type(scale)~="number"or scale<=0 then
scale=1
end
return REFERENCE_UI_HEIGHT/physicalHeight/scale
end



function Shapes.hairlineThickness(frame,thickness)
if thickness==1 then
return Shapes.pixelSize(frame)
end
return thickness
end




function Shapes.snapToPixelGrid(texture)
if texture.SetSnapToPixelGrid then
texture:SetSnapToPixelGrid(true)
end
end



function Shapes.polishBadge(label,...)
for i=1,select("#",...)do
local circle=select(i,...)
if circle.SetSnapToPixelGrid then
circle:SetSnapToPixelGrid(false)
circle:SetTexelSnappingBias(0)
end
end
if label.SetShadowOffset then
label:SetShadowOffset(0,0)
end
end



local SHEEN_COLOR={1,1,1,0.05}

function Shapes.createSheen(frame,layer,subLayer)
local sheen=frame:CreateTexture(nil,layer or"BACKGROUND",nil,subLayer or 1)
sheen:SetAllPoints(frame)
sheen:Hide()
return sheen
end

function Shapes.applySheen(sheen)
Base.applyVerticalFade(sheen,SHEEN_COLOR)
sheen:Show()
end



local hairlineBoxes=setmetatable({},{__mode="k"})

local function setEdgeThickness(border,thickness)
if border.top then
border.top:SetHeight(thickness)
end
if border.bottom then
border.bottom:SetHeight(thickness)
end
if border.left then
border.left:SetWidth(thickness)
end
if border.right then
border.right:SetWidth(thickness)
end
end




function Shapes.refreshHairlines()
for border,frame in pairs(hairlineBoxes)do
setEdgeThickness(border,Shapes.pixelSize(frame))
end
end

function Shapes.createBorderBox(frame,colorTable,thickness,layer,edges)
if not frame or type(frame.CreateTexture)~="function"then
return nil
end

local edgeThickness=Shapes.hairlineThickness(frame,thickness or 1)
local drawLayer=layer or"BORDER"
local enabled=edges or{top=true,left=true,right=true,bottom=true}
local border={}
if enabled.top~=false then
border.top=frame:CreateTexture(nil,drawLayer)
end
if enabled.left~=false then
border.left=frame:CreateTexture(nil,drawLayer)
end
if enabled.right~=false then
border.right=frame:CreateTexture(nil,drawLayer)
end
if enabled.bottom~=false then
border.bottom=frame:CreateTexture(nil,drawLayer)
end

if border.top then
border.top:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
border.top:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
end




if border.left then
border.left:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
border.left:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
end

if border.right then
border.right:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
border.right:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
end

if border.bottom then
border.bottom:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
border.bottom:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
end

setEdgeThickness(border,edgeThickness)
if(thickness or 1)==1 then
hairlineBoxes[border]=frame
end

for _,edge in pairs(border)do
Shapes.snapToPixelGrid(edge)
end

if colorTable then
Base.applyBorderBoxColor(border,colorTable)
end

return border
end


function Shapes.resizeCircularIcon(frame,texture,size)
frame:SetSize(size,size)
local zoom=math.floor(size*ICON_ZOOM+0.5)
texture:SetSize(zoom,zoom)
end

function Shapes.createCircularIcon(factory,parent,size)
local frame=factory.CreateFrame("Frame",nil,parent)
frame:SetSize(size,size)
if frame.SetClipsChildren then
frame:SetClipsChildren(true)
end

local zoom=math.floor(size*ICON_ZOOM+0.5)



local texture=frame._wmCircularIconTexture
if not texture then
texture=frame:CreateTexture(nil,"ARTWORK")
if texture.SetMask then
texture:SetMask(CIRCLE_MASK)
end
frame._wmCircularIconTexture=texture
end
texture:SetSize(zoom,zoom)
texture:ClearAllPoints()
texture:SetPoint("CENTER",frame,"CENTER",0,0)
if texture.Show then
texture:Show()
end

return{frame=frame,texture=texture}
end





function Shapes.createRoundedBackground(frame,cornerRadius,drawLayer,subLayer)
local r=cornerRadius or 8
local layer=drawLayer or"BACKGROUND"

local fills={}
local corners={}

local bgCenter=frame:CreateTexture(nil,layer,nil,subLayer)
bgCenter:SetPoint("TOPLEFT",frame,"TOPLEFT",r,-r)
bgCenter:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-r,r)
fills[#fills+1]=bgCenter

local bgTop=frame:CreateTexture(nil,layer,nil,subLayer)
bgTop:SetPoint("TOPLEFT",frame,"TOPLEFT",r,0)
bgTop:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-r,0)
bgTop:SetHeight(r)
fills[#fills+1]=bgTop

local bgBottom=frame:CreateTexture(nil,layer,nil,subLayer)
bgBottom:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",r,0)
bgBottom:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-r,0)
bgBottom:SetHeight(r)
fills[#fills+1]=bgBottom

local bgLeft=frame:CreateTexture(nil,layer,nil,subLayer)
bgLeft:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-r)
bgLeft:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,r)
bgLeft:SetWidth(r)
fills[#fills+1]=bgLeft

local bgRight=frame:CreateTexture(nil,layer,nil,subLayer)
bgRight:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,-r)
bgRight:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,r)
bgRight:SetWidth(r)
fills[#fills+1]=bgRight

local function makeCorner(point)
local c=frame:CreateTexture(nil,layer,nil,subLayer)
c:SetSize(r,r)
c:SetPoint(point,frame,point,0,0)
if c.SetTexture then
c:SetTexture(ROUNDED_CIRCLE_TEX)
end
return c
end

local cTL=makeCorner("TOPLEFT")
local cTR=makeCorner("TOPRIGHT")
local cBL=makeCorner("BOTTOMLEFT")
local cBR=makeCorner("BOTTOMRIGHT")

if cTL.SetTexCoord then
cTL:SetTexCoord(0,0.5,0,0.5)
cTR:SetTexCoord(0.5,1,0,0.5)
cBL:SetTexCoord(0,0.5,0.5,1)
cBR:SetTexCoord(0.5,1,0.5,1)
end

corners[#corners+1]=cTL
corners[#corners+1]=cTR
corners[#corners+1]=cBL
corners[#corners+1]=cBR

local function setColor(colorTable)
for _,part in ipairs(fills)do
Base.applyColorTexture(part,colorTable)
end
for _,part in ipairs(corners)do
Base.applyVertexColor(part,colorTable)
end
end

return{fills=fills,corners=corners,setColor=setColor}
end

ns.UIHelpersShapes=Shapes

return Shapes
