local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChannelType=ns.ChannelType or require("WhisperMessenger.Model.Identity.ChannelType")

local ContactsTabFilter={}




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



ContactsTabFilter.IsGroupChannel=isGroupChannel



function ContactsTabFilter.ModeOf(item)
if isGroupChannel(item.channel)then
return"groups"
end
if item.isRequest==true then
return"requests"
end
return"whispers"
end

local function filterMode(items,mode)
local result={}
for _,item in ipairs(items or{})do
if ContactsTabFilter.ModeOf(item)==mode then
result[#result+1]=item
end
end
return result
end




function ContactsTabFilter.FilterWhispers(items)
return filterMode(items,"whispers")
end

function ContactsTabFilter.FilterRequests(items)
return filterMode(items,"requests")
end


function ContactsTabFilter.FilterGroups(items)
local result={}
for _,item in ipairs(items or{})do
if isGroupChannel(item.channel)then
result[#result+1]=item
end
end
return result
end




function ContactsTabFilter.Apply(items,mode,showGroupChats)
if mode=="requests"then
return ContactsTabFilter.FilterRequests(items)
end
if not showGroupChats then
return ContactsTabFilter.FilterWhispers(items)
end
if mode=="groups"then
return ContactsTabFilter.FilterGroups(items)
end
return ContactsTabFilter.FilterWhispers(items)
end

ns.ContactsTabFilter=ContactsTabFilter
return ContactsTabFilter
