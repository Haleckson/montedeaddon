local addonName,ns=...
if type(ns)~="table"then
ns={}
end










local HoverFade={}

HoverFade.DURATION=0.1


function HoverFade.Attach(region)
local peak=1
local visible=region:IsShown()
local group,anim
if type(region.CreateAnimationGroup)=="function"then
group=region:CreateAnimationGroup()
anim=group:CreateAnimation("Alpha")
anim:SetDuration(HoverFade.DURATION)
if group.SetToFinalAlpha then
group:SetToFinalAlpha(true)
end
group:SetScript("OnFinished",function()
region:SetAlpha(visible and peak or 0)
if not visible then
region:Hide()
end
end)
end

local controller={}

local function isAnimating()
return group~=nil and group:IsPlaying()
end





local function repaint(write,color)
local alpha=region:GetAlpha()
peak=color[4]or 1
write(region,color[1],color[2],color[3],1)
if visible and region:IsShown()and not isAnimating()then
alpha=peak
end
region:SetAlpha(alpha)
end

function controller.paintColor(color)
repaint(region.SetColorTexture,color)
end

function controller.paintVertex(color)
repaint(region.SetVertexColor,color)
end

function controller.set(shown)
shown=shown==true
if shown==visible and(region:IsShown()==shown or isAnimating())then
return
end
visible=shown

if group==nil then
if shown then
region:SetAlpha(peak)
region:Show()
else
region:Hide()
end
return
end

local from=region:IsShown()and region:GetAlpha()or 0
group:Stop()
region:SetAlpha(from)
region:Show()
anim:SetFromAlpha(from)
anim:SetToAlpha(shown and peak or 0)
group:Play()
end

return controller
end

ns.UIHelpersHoverFade=HoverFade
return HoverFade
