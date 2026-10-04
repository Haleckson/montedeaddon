local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChannelType=ns.ChannelType or require("WhisperMessenger.Model.Identity.ChannelType")

local BadgeFilter={}





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




function BadgeFilter.IsGroupChannel(channel)
return isGroupChannel(channel)
end



local function badgeUnread(contact)
if contact.isRequest==true or(contact.muted==true and contact.hasUnreadMention~=true)then
return 0
end
return tonumber(contact.unreadCount)or 0
end


BadgeFilter.BadgeUnread=badgeUnread






function BadgeFilter.SumWhisperUnread(contacts)
local total=0
for _,contact in ipairs(contacts or{})do
if not isGroupChannel(contact.channel)then
total=total+badgeUnread(contact)
end
end
return total
end



function BadgeFilter.SumGroupUnread(contacts)
local total=0
for _,contact in ipairs(contacts or{})do
if isGroupChannel(contact.channel)then
total=total+badgeUnread(contact)
end
end
return total
end


function BadgeFilter.SumRequestUnread(contacts)
local total=0
for _,contact in ipairs(contacts or{})do
if contact.isRequest==true then
total=total+(tonumber(contact.unreadCount)or 0)
end
end
return total
end

ns.ToggleIconBadgeFilter=BadgeFilter
return BadgeFilter
