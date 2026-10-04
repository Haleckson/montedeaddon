local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")

local applyColorTexture=UIHelpers.applyColorTexture
local applyBorderBoxColor=UIHelpers.applyBorderBoxColor
local applyClassColor=UIHelpers.applyClassColor




local DragGhost={}

local GHOST_ALPHA=0.95
local NAME_GAP=8



DragGhost.STRATA="TOOLTIP"


function DragGhost.PlaceOnTop(frame,listFrame)
frame:SetFrameStrata(DragGhost.STRATA)
local host=frame.GetParent and frame:GetParent()or nil
if frame.SetScale and host and host.GetEffectiveScale and listFrame.GetEffectiveScale then
frame:SetScale(listFrame:GetEffectiveScale()/host:GetEffectiveScale())
end
end


function DragGhost.Create(factory,parent)
local frame=factory.CreateFrame("Frame",nil,parent)
frame:Hide()
frame:SetAlpha(GHOST_ALPHA)

local bg=frame:CreateTexture(nil,"BACKGROUND")
bg:SetAllPoints(frame)
local border=UIHelpers.createBorderBox(frame,Theme.COLORS.window_border,1,"BORDER")

local iconSize=Theme.LAYOUT.CONTACT_ICON_SIZE
local icon=UIHelpers.createCircularIcon(factory,frame,iconSize)
icon.frame:SetPoint("LEFT",frame,"LEFT",Theme.LAYOUT.CONTACT_PADDING,0)

local label=frame:CreateFontString(nil,"OVERLAY",Theme.FONTS.contact_name)
label:SetPoint("LEFT",icon.frame,"RIGHT",NAME_GAP,0)
label:SetPoint("RIGHT",frame,"RIGHT",-Theme.LAYOUT.CONTACT_PADDING,0)
label:SetJustifyH("LEFT")
label:SetWordWrap(false)

return{frame=frame,bg=bg,border=border,iconFrame=icon.frame,icon=icon.texture,label=label}
end

function DragGhost.Show(ghost,sourceRow,listFrame)
local frame=ghost.frame
DragGhost.PlaceOnTop(frame,listFrame)
local surface=Theme.COLORS.bg_primary
applyColorTexture(ghost.bg,{surface[1],surface[2],surface[3],1})
applyBorderBoxColor(ghost.border,Theme.COLORS.window_border)

local item=sourceRow.item or{}

local iconPath=sourceRow.classIcon and sourceRow.classIcon.GetTexture and sourceRow.classIcon:GetTexture()or nil
ghost.icon:SetTexture(iconPath or Theme.ClassIcon(item.classTag)or Theme.TEXTURES.bnet_icon)
ghost.label:SetText(item.displayName or"")
applyClassColor(ghost.label,item.classTag,Theme.COLORS.text_primary)

if sourceRow.GetHeight then
frame:SetHeight(sourceRow:GetHeight())
end
frame:Show()
end



function DragGhost.MoveTo(ghost,sourceRow,offsetY)
local frame=ghost.frame
frame:ClearAllPoints()
frame:SetPoint("TOPLEFT",sourceRow,"TOPLEFT",0,-offsetY)
frame:SetPoint("TOPRIGHT",sourceRow,"TOPRIGHT",0,-offsetY)
end

function DragGhost.Hide(ghost)
ghost.frame:Hide()
end

ns.MessengerWindowDragGhost=DragGhost
return DragGhost
