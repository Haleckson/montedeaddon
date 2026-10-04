local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")





local Divider={}

function Divider.createLine(frame)
local line=frame:CreateTexture(nil,"ARTWORK")
line:SetHeight(UIHelpers.hairlineThickness(frame,1))
UIHelpers.snapToPixelGrid(line)
return line
end


function Divider.paint(leftLine,rightLine,activeTheme)
local color=activeTheme.COLORS.contacts_border_right or activeTheme.COLORS.divider
UIHelpers.applyHorizontalFadeLeft(leftLine,color)
UIHelpers.applyHorizontalFade(rightLine,color)
end


function Divider.Create(frame)
local left=Divider.createLine(frame)
local right=Divider.createLine(frame)
right:SetPoint("LEFT",left,"RIGHT",0,0)

return{
left=left,
right=right,
setWidth=function(width)
left:SetWidth(width/2)
right:SetWidth(width/2)
end,
applyTheme=function(activeTheme)
Divider.paint(left,right,activeTheme)
end,
}
end

ns.SettingsControlsDivider=Divider
return Divider
