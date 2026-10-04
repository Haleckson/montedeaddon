local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChannelType=ns.ChannelType or require("WhisperMessenger.Model.Identity.ChannelType")
local GroupLabel=ns.ContactsListGroupLabel or require("WhisperMessenger.UI.ContactsList.GroupLabel")

local GroupHeaderViewModel={}



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

local function isGroupChannel(channel)
return KNOWN_GROUP_CHANNELS[channel]==true
end












function GroupHeaderViewModel.Build(contact,conversation)
if contact==nil then
return nil
end

local channel=contact.channel
local isGroup=isGroupChannel(channel)

if not isGroup then
return{
isGroup=false,
title=contact.displayName or"",
showPresenceDot=true,
showFactionIcon=true,
showStatusLine=true,
channelChip=nil,
}
end


local convTitle=conversation and conversation.title or nil
local label=GroupLabel.LabelForChannelAndTitle(channel,convTitle)
local fromAnotherCharacter=contact.ownerProfileId~=nil and contact.ownerProfileId~=""





if channel==ChannelType.GUILD then
local storedGuildName=contact.guildName or(conversation and conversation.guildName)or nil
if storedGuildName and storedGuildName~=""then
label=storedGuildName
elseif not fromAnotherCharacter then
local guildName=GroupLabel.PlayerGuildName and GroupLabel.PlayerGuildName()or nil
if guildName then
label=guildName
end
end
end



if fromAnotherCharacter then
local ownerName=GroupLabel.OwnerShortName and GroupLabel.OwnerShortName(contact.ownerProfileId)or contact.ownerProfileId
label=ownerName.." - "..label
end




local canonical=GroupLabel.LabelForChannel(channel)
local chip=nil
if canonical~=""and canonical~=label then
chip=canonical
end

return{
isGroup=true,
title=label,
showPresenceDot=false,
showFactionIcon=false,
showStatusLine=false,
channelChip=chip,
}
end

ns.ConversationPaneGroupHeaderViewModel=GroupHeaderViewModel
return GroupHeaderViewModel
