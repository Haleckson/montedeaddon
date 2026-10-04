local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")
local ContactsTabFilter=ns.ContactsTabFilter or require("WhisperMessenger.UI.ContactsList.ContactsTabFilter")
local ContactPrefsDialog=ns.ContactsListContactPrefsDialog or require("WhisperMessenger.UI.ContactsList.ContactPrefsDialog")
local OnlineWatch=ns.OnlineWatch or require("WhisperMessenger.Model.OnlineWatch")
local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")

local ContextMenu={}

local function hasUnansweredIncoming(item)
if type(item.conversation)=="table"then
return Store.CountUnansweredIncoming(item.conversation)>0
end
return(tonumber(item.unansweredCount)or 0)>0
end

local registeredModernMenu=nil

local function addMarkUnreadButton(rootDescription,item,onMarkUnread)
if type(onMarkUnread)~="function"then
return
end
local button=rootDescription:CreateButton(Localization.Text("Mark last messages as unread"),function()
onMarkUnread(item)
end)
if button and type(button.SetEnabled)=="function"then
button:SetEnabled(hasUnansweredIncoming(item))
end
end



local function addNotifyOnlineEntry(rootDescription,item,onUpdatePrefs)
if not OnlineWatch.CanWatch(item,_G.C_FriendList)then
return
end
local label=Localization.Text("Notify when online")


local enabled=item.notifyOnline==true
local function toggle()
enabled=not enabled
onUpdatePrefs(item,{notifyOnline=enabled})
end
if type(rootDescription.CreateCheckbox)=="function"then
rootDescription:CreateCheckbox(label,function()
return enabled
end,toggle)
else
rootDescription:CreateButton(label,toggle)
end
end



local function addPrefsButtons(rootDescription,item,onUpdatePrefs,isGroup)
if type(onUpdatePrefs)~="function"then
return
end
local muted=item.muted==true
rootDescription:CreateButton(Localization.Text(muted and"Unmute"or"Mute"),function()
onUpdatePrefs(item,{muted=not muted})
end)
if isGroup then
return
end
rootDescription:CreateButton(Localization.Text("Set nickname…"),function()
ContactPrefsDialog.ShowNickname(item,function(text)
onUpdatePrefs(item,{nickname=text})
end)
end)
rootDescription:CreateButton(Localization.Text("Edit note…"),function()
ContactPrefsDialog.ShowNote(item,function(text)
onUpdatePrefs(item,{note=text})
end)
end)
addNotifyOnlineEntry(rootDescription,item,onUpdatePrefs)
end




local function addWhisperMessengerEntries(_owner,rootDescription,contextData)
if rootDescription==nil or type(rootDescription.CreateButton)~="function"then
return
end
if type(contextData)~="table"or type(contextData.whisperMessengerItem)~="table"then
return
end
local item=contextData.whisperMessengerItem
local onMarkUnread=contextData.whisperMessengerOnMarkUnread
local onUpdatePrefs=contextData.whisperMessengerOnUpdatePrefs

if type(onMarkUnread)~="function"and type(onUpdatePrefs)~="function"then
return
end

if type(rootDescription.CreateDivider)=="function"then
rootDescription:CreateDivider()
end
if type(rootDescription.CreateTitle)=="function"then
rootDescription:CreateTitle(UIHelpers.colorEscape(Theme.TAG_GOLD).."WhisperMessenger|r")
end
addMarkUnreadButton(rootDescription,item,onMarkUnread)
addPrefsButtons(rootDescription,item,onUpdatePrefs,false)
end

local function ensureModernMenu()
local menu=_G.Menu
if type(menu)~="table"or type(menu.ModifyMenu)~="function"then
return false
end
if registeredModernMenu==menu then
return true
end

local okFriend=pcall(menu.ModifyMenu,"MENU_UNIT_FRIEND",addWhisperMessengerEntries)
local okBnet=pcall(menu.ModifyMenu,"MENU_UNIT_BN_FRIEND",addWhisperMessengerEntries)
if not okFriend or not okBnet then
return false
end

registeredModernMenu=menu
return true
end

local function resolveMenuName(item)
local name=item.displayName or item.gameAccountName or item.battleTag
if name==nil or name==""then
return nil
end

return name
end




local function openGroupMenu(item,anchorFrame,onMarkUnread,onUpdatePrefs)
local menuUtil=_G.MenuUtil
if type(menuUtil)~="table"or type(menuUtil.CreateContextMenu)~="function"then
return false
end
menuUtil.CreateContextMenu(anchorFrame,function(_owner,rootDescription)
addMarkUnreadButton(rootDescription,item,onMarkUnread)
addPrefsButtons(rootDescription,item,onUpdatePrefs,true)
end)
return true
end



function ContextMenu.Open(item,anchorFrame,onMarkUnread,onUpdatePrefs)
if type(item)~="table"then
return false
end
if ContactsTabFilter.IsGroupChannel(item.channel)then
return openGroupMenu(item,anchorFrame,onMarkUnread,onUpdatePrefs)
end

local name=resolveMenuName(item)
if name==nil then
return false
end

local lineID=item.lineID
local chatType=item.chatType
local which=item.channel=="BN"and"BN_FRIEND"or"FRIEND"

if ensureModernMenu()and type(_G.UnitPopup_OpenMenu)=="function"then
_G.UnitPopup_OpenMenu(which,{
name=name,
lineID=lineID,
chatType=chatType,
chatTarget=name,
chatFrame=anchorFrame,
bnetAccountID=item.bnetAccountID,
bnetIDAccount=item.bnetAccountID,
guid=item.guid,
battleTag=item.battleTag,
communityClubID=item.communityClubID,
communityStreamID=item.communityStreamID,
communityEpoch=item.communityEpoch,
communityPosition=item.communityPosition,
whisperMessengerItem=item,
whisperMessengerOnMarkUnread=onMarkUnread,
whisperMessengerOnUpdatePrefs=onUpdatePrefs,
})
return true
end

if item.channel=="BN"then
if type(_G.FriendsFrame_ShowBNDropdown)=="function"then
_G.FriendsFrame_ShowBNDropdown(
name,
1,
lineID,
chatType,
anchorFrame,
nil,
item.bnetAccountID,
item.communityClubID,
item.communityStreamID,
item.communityEpoch,
item.communityPosition,
item.battleTag
)
return true
end
elseif type(_G.FriendsFrame_ShowDropdown)=="function"then
_G.FriendsFrame_ShowDropdown(
name,
1,
lineID,
chatType,
anchorFrame,
nil,
item.communityClubID,
item.communityStreamID,
item.communityEpoch,
item.communityPosition,
item.guid
)
return true
end

if type(_G.UnitPopup_OpenMenu)=="function"then
_G.UnitPopup_OpenMenu(which,{
name=name,
lineID=lineID,
chatType=chatType,
chatTarget=name,
chatFrame=anchorFrame,
bnetIDAccount=item.bnetAccountID,
guid=item.guid,
battleTag=item.battleTag,
communityClubID=item.communityClubID,
communityStreamID=item.communityStreamID,
communityEpoch=item.communityEpoch,
communityPosition=item.communityPosition,
})
return true
end

return false
end

ns.ContactsListContextMenu=ContextMenu
return ContextMenu
