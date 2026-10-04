local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local sizeValue=UIHelpers.sizeValue
local applyColorTexture=UIHelpers.applyColorTexture

local ActionButtons=ns.ContactsListActionButtons or require("WhisperMessenger.UI.ContactsList.ActionButtons")
local StatusDot=ns.ContactsListStatusDot or require("WhisperMessenger.UI.ContactsList.StatusDot")
local RowElements=ns.ContactsListRowElements or require("WhisperMessenger.UI.ContactsList.RowElements")
local RowMarkers=ns.ContactsListRowMarkers or require("WhisperMessenger.UI.ContactsList.RowMarkers")
local RowScripts=ns.ContactsListRowScripts or require("WhisperMessenger.UI.ContactsList.RowScripts")
local RowHoverOverlay=ns.ContactsListRowHoverOverlay or require("WhisperMessenger.UI.ContactsList.RowHoverOverlay")
local GroupLabel=ns.ContactsListGroupLabel or require("WhisperMessenger.UI.ContactsList.GroupLabel")
local ChannelType=ns.ChannelType or require("WhisperMessenger.Model.Identity.ChannelType")

local RowView={}



local function mutedColor(base)
if type(base)~="table"then
return base
end
local MUTE=0.85
return{(base[1]or 0)*MUTE,(base[2]or 0)*MUTE,(base[3]or 0)*MUTE,base[4]or 1}
end



local KNOWN_GROUP_CHANNELS={
[ChannelType.BN_CONVERSATION]=true,
[ChannelType.PARTY]=true,
[ChannelType.RAID]=true,
[ChannelType.INSTANCE_CHAT]=true,
[ChannelType.GUILD]=true,
[ChannelType.OFFICER]=true,
[ChannelType.CHANNEL]=true,
[ChannelType.COMMUNITY]=true,
}


local function isGroupItem(item)
return item~=nil and KNOWN_GROUP_CHANNELS[item.channel]==true
end




local cachedPlayerClassTag=nil
local function playerClassTag()
if cachedPlayerClassTag~=nil then
return cachedPlayerClassTag
end
local unitClass=_G.UnitClass
if type(unitClass)~="function"then
return nil
end
local ok,_,tag=pcall(unitClass,"player")
if ok and type(tag)=="string"and tag~=""then
cachedPlayerClassTag=tag
return cachedPlayerClassTag
end
return nil
end

local function bindRow(factory,parent,row,index,item,options)
local parentWidth=sizeValue(parent,"GetWidth","width",260)
local ROW_HEIGHT=Theme.LAYOUT.CONTACT_ROW_HEIGHT
row=row or factory.CreateFrame("Button",nil,parent)
row.item=item


row:SetSize(parentWidth-2,ROW_HEIGHT)
row:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-((index-1)*ROW_HEIGHT))
if row.EnableMouse then
row:EnableMouse(true)
end


if row.bg==nil then
row.bg=row:CreateTexture(nil,"BACKGROUND")
row.bg:SetAllPoints()
end
local isGroup=isGroupItem(item)
local whisperBaseBg=item.pinned and Theme.COLORS.bg_contact_pinned or Theme.COLORS.bg_secondary
local rowBaseBg=isGroup and mutedColor(whisperBaseBg)or whisperBaseBg
applyColorTexture(row.bg,rowBaseBg)


if row.accentBar==nil then
row.accentBar=row:CreateTexture(nil,"BORDER")
row.accentBar:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
row.accentBar:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",0,0)
end
row.accentBar:SetWidth(Theme.LAYOUT.CONTACT_ACCENT_BAR_W)
applyColorTexture(row.accentBar,Theme.COLORS.accent_bar)
row.accentBar:Hide()


RowHoverOverlay.ensure(row)
RowScripts.bindHover(row)
RowScripts.bindClick(row,item,options)
row.rowIndex=index
RowScripts.bindDrag(row,item,options)




if row.classIconFrame==nil then
RowElements.createClassIcon(factory,row,item)
end
if row.classIcon and row.classIcon.SetTexture then
local iconPath
if isGroup then
iconPath=Theme.ChannelIcon and Theme.ChannelIcon(item.channel)or nil
else
iconPath=Theme.ClassIcon(item.classTag)
end
row.classIcon:SetTexture(iconPath or Theme.TEXTURES.bnet_icon)
end



if row.statusDot==nil then
row.statusDot=StatusDot.create(factory,row,row.classIconFrame,item.availability).frame
else
StatusDot.update(row.statusDot,item.availability)
end
if row.statusDot and row.statusDot.SetShown then
row.statusDot:SetShown(not isGroup)
end


if row.title==nil then
RowElements.createNameLabel(row,item,parentWidth)
end
if row.factionIcon==nil then
RowElements.createFactionIcon(factory,row,item,ns)
end


if row.timeLabel==nil then
RowElements.createTimestamp(row,item,ns)
else
RowElements.updateTimestamp(row,item,ns)
end
RowMarkers.updateMuted(row,item)


RowElements.updateNameLabel(row,item,parentWidth)
RowElements.updateFactionIcon(row,item,ns)



if isGroup and row.factionIcon and row.factionIcon.Hide then
row.factionIcon:Hide()
end



if isGroup and row.title then
local groupName
if item.channel==ChannelType.PARTY or item.channel==ChannelType.RAID or item.channel==ChannelType.INSTANCE_CHAT then
groupName=GroupLabel.LabelForSession(item.channel,item.leftGroup,item.ownerProfileId,item.lastActivityAt)
else
groupName=GroupLabel.LabelForChannelAndTitle(item.channel,item.title)
end
if groupName==""then
groupName=item.displayName or""
end


local ownerName=GroupLabel.OwnerShortName and GroupLabel.OwnerShortName(item.ownerProfileId)or nil
if ownerName then
groupName=ownerName.." - "..groupName
end
if row.title.SetText then
row.title:SetText(groupName)
end










local titleClassTag=item.ownerClassTag
if titleClassTag==nil and not item.ownerProfileId then
titleClassTag=playerClassTag()
end
UIHelpers.applyClassColor(row.title,titleClassTag,Theme.COLORS.text_primary)
end


if row.preview==nil then
RowElements.createPreview(row,item,parentWidth)
end
RowElements.updatePreview(row,item,parentWidth,options and options.hideMessagePreview,options and options.selectedConversationKey)



if row.location==nil then
RowElements.createLocation(row,item,parentWidth)
end
RowElements.updateLocation(row,item,parentWidth)
if isGroup and row.location and row.location.Hide then
row.location:Hide()
end


if row.removeButton==nil then
row.removeButton=ActionButtons.createRemoveButton(factory,row,parentWidth,options)
end
if row.pinButton==nil then
row.pinButton=ActionButtons.createPinButton(factory,row,item,parentWidth,options)
end

ActionButtons.paintPinIcon(row)
ActionButtons.paintRemoveIcon(row)
ActionButtons.layout(row)


row.pinButton:Hide()
row.removeButton:Hide()


if row.unreadBadge==nil then
RowElements.createUnreadBadge(factory,row)
end
RowElements.updateUnreadBadge(row,item)
RowMarkers.updateBadge(row,item)

if row.Show then
row:Show()
end

return row
end

RowView.bindRow=bindRow

ns.ContactsListRowView=RowView
return RowView
