local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local applyColorTexture=UIHelpers.applyColorTexture
local applyVertexColor=UIHelpers.applyVertexColor
local HoverPointer=ns.ContactsListHoverPointer or require("WhisperMessenger.UI.ContactsList.HoverPointer")
local PinnedMarker=ns.ContactsListPinnedMarker or require("WhisperMessenger.UI.ContactsList.PinnedMarker")
local isPointerInsideRowFrames=HoverPointer.isPointerInsideRowFrames
local effectiveActionHoverCount=HoverPointer.effectiveActionHoverCount

local ActionButtons={}


local COLUMN_GAP=2

local COLUMN_GLYPH_NUDGE_X=1

local function rowBaseBackgroundColor(row)
local item=row and row.item or nil
return item and item.pinned and Theme.COLORS.bg_contact_pinned or Theme.COLORS.bg_secondary
end



function ActionButtons.paintPinIcon(row)
local pinned=row.item and row.item.pinned
local textures=Theme.TEXTURES
row.pinButton.icon:SetTexture(pinned and textures.unpin_icon or textures.pin_icon)
applyVertexColor(row.pinButton.icon,Theme.COLORS.action_icon)
end


function ActionButtons.paintRemoveIcon(row)
row.removeButton.icon:SetTexture(Theme.TEXTURES.trash_icon)
end


function ActionButtons.layout(row)
local pinButton,removeButton=row.pinButton,row.removeButton
local gap=COLUMN_GAP
pinButton:ClearAllPoints()
removeButton:ClearAllPoints()
if row.timeLabel then
pinButton:SetPoint("TOPRIGHT",row.timeLabel,"BOTTOMRIGHT",COLUMN_GLYPH_NUDGE_X,-gap)
else
pinButton:SetPoint("TOPRIGHT",row,"TOPRIGHT",-Theme.LAYOUT.CONTACT_PADDING,-gap)
end
removeButton:SetPoint("TOPRIGHT",pinButton,"BOTTOMRIGHT",0,-gap)
PinnedMarker.update(row)
end

local function pinTooltipText(row)
local item=row and row.item or nil
return item and item.pinned and Localization.Text("Unpin")or Localization.Text("Pin to top")
end

local function isPointerInsideRow(row)
if row and row._wmIsPointerInside then
return row._wmIsPointerInside()
end
return isPointerInsideRowFrames(row)
end

local function restoreRowVisualState(row)
if row._wmApplyVisualState then
row._wmApplyVisualState()
return
end
if row.selected then
applyColorTexture(row.bg,Theme.COLORS.bg_contact_selected)
elseif(row._wmActionHoverCount or 0)>0 or isPointerInsideRow(row)then
applyColorTexture(row.bg,Theme.COLORS.bg_contact_hover)
else
applyColorTexture(row.bg,rowBaseBackgroundColor(row))
end
end

local function adjustActionHoverCount(row,delta)
row._wmActionHoverCount=math.max(0,(row._wmActionHoverCount or 0)+delta)
if row._wmActionHoverCount>0 then
restoreRowVisualState(row)
ActionButtons.showActions(row)
return
end


local CTimer=_G.C_Timer
if CTimer and CTimer.After then
CTimer.After(0,function()
if not isPointerInsideRow(row)and effectiveActionHoverCount(row)==0 then
row._wmRowHover=false
restoreRowVisualState(row)
ActionButtons.hideActions(row)
end
end)
else
if not isPointerInsideRow(row)and effectiveActionHoverCount(row)==0 then
row._wmRowHover=false
restoreRowVisualState(row)
ActionButtons.hideActions(row)
else
restoreRowVisualState(row)
end
end
end

function ActionButtons.showActions(row)
local hasUnread=row.item and(row.item.unreadCount or 0)>0
if hasUnread then
return
end
if row.pinButton then
row.pinButton:Show()
end
if row.removeButton then
row.removeButton:Show()
end

PinnedMarker.setVisible(row,false)
end


function ActionButtons.hideActions(row)
PinnedMarker.setVisible(row,true)
if row.pinButton then
row.pinButton:Hide()
end
if row.removeButton then
row.removeButton:Hide()
end
end

function ActionButtons.createRemoveButton(factory,row,_parentWidth,options)
local ACTION_SIZE=Theme.LAYOUT.CONTACT_ACTION_SIZE
local ACTION_SPACING=Theme.LAYOUT.CONTACT_ACTION_SPACING

local btn=factory.CreateFrame("Button",nil,row)
btn:SetSize(ACTION_SIZE,ACTION_SIZE)
btn:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-Theme.LAYOUT.CONTACT_PADDING,4+ACTION_SIZE+ACTION_SPACING)
if btn.EnableMouse then
btn:EnableMouse(true)
end

btn.icon=btn:CreateTexture(nil,"ARTWORK")
btn.icon:SetSize(ACTION_SIZE-2,ACTION_SIZE-2)
btn.icon:SetPoint("CENTER",btn,"CENTER",0,0)
if btn.icon.SetDesaturated then
btn.icon:SetDesaturated(true)
end
applyVertexColor(btn.icon,Theme.COLORS.action_icon)

if btn.SetScript then
btn:SetScript("OnEnter",function(self)
applyVertexColor(self.icon,Theme.COLORS.action_remove_hover)
adjustActionHoverCount(row,1)
if _G.GameTooltip and _G.GameTooltip.SetOwner then
_G.GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
_G.GameTooltip:SetText(Localization.Text("Remove"))
_G.GameTooltip:Show()
end
end)

btn:SetScript("OnLeave",function(self)
applyVertexColor(self.icon,Theme.COLORS.action_icon)
adjustActionHoverCount(row,-1)
if _G.GameTooltip and _G.GameTooltip.Hide then
_G.GameTooltip:Hide()
end
end)

btn:SetScript("OnClick",function()
if row.item and options.onRemove then
options.onRemove(row.item)
end
end)
end

return btn
end

function ActionButtons.createPinButton(factory,row,_item,_parentWidth,options)
local ACTION_SIZE=Theme.LAYOUT.CONTACT_ACTION_SIZE
local ACTION_SPACING=Theme.LAYOUT.CONTACT_ACTION_SPACING

local btn=factory.CreateFrame("Button",nil,row)
btn:SetSize(ACTION_SIZE,ACTION_SIZE)
if row.removeButton then
btn:SetPoint("TOP",row.removeButton,"BOTTOM",0,-ACTION_SPACING)
end
if btn.EnableMouse then
btn:EnableMouse(true)
end

btn.icon=btn:CreateTexture(nil,"ARTWORK")
btn.icon:SetSize(ACTION_SIZE-2,ACTION_SIZE-2)
btn.icon:SetPoint("CENTER",btn,"CENTER",0,0)
if btn.icon.SetDesaturated then
btn.icon:SetDesaturated(true)
end

if btn.SetScript then
btn:SetScript("OnEnter",function(self)
applyVertexColor(self.icon,Theme.COLORS.action_icon_hover)
adjustActionHoverCount(row,1)
if _G.GameTooltip and _G.GameTooltip.SetOwner then
_G.GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
_G.GameTooltip:SetText(pinTooltipText(row))
_G.GameTooltip:Show()
end
end)

btn:SetScript("OnLeave",function(self)
applyVertexColor(self.icon,Theme.COLORS.action_icon)
adjustActionHoverCount(row,-1)
if _G.GameTooltip and _G.GameTooltip.Hide then
_G.GameTooltip:Hide()
end
end)

btn:SetScript("OnClick",function()
if row.item and options.onPin then
options.onPin(row.item)
end
end)
end

return btn
end

ns.ContactsListActionButtons=ActionButtons
return ActionButtons
