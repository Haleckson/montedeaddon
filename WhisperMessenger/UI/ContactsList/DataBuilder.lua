local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local DataBuilder={}

local ConversationSnapshot=ns.ConversationSnapshot or require("WhisperMessenger.Model.ConversationSnapshot")

local function compareItems(left,right)
local leftPinned=left.pinned and true or false
local rightPinned=right.pinned and true or false
if leftPinned~=rightPinned then
return leftPinned
end


if leftPinned and rightPinned then
local leftOrder=left.sortOrder or 0
local rightOrder=right.sortOrder or 0
if leftOrder~=0 or rightOrder~=0 then
if leftOrder~=rightOrder then
if leftOrder==0 then
return false
end
if rightOrder==0 then
return true
end
return leftOrder<rightOrder
end
end
end

if left.lastActivityAt~=right.lastActivityAt then
return left.lastActivityAt>right.lastActivityAt
end

return(left.displayName or"")<(right.displayName or"")
end

function DataBuilder.BuildItems(conversations)
local items={}

for conversationKey,conversation in pairs(conversations or{})do
table.insert(items,ConversationSnapshot.Build(conversationKey,conversation))
end

table.sort(items,compareItems)
return items
end




local PER_CHARACTER_GROUP_PREFIXES={
"guild::",
"officer::",
"party::",
"raid::",
"instance::",
}



local ACCOUNT_GROUP_PREFIXES={
"bnconv::",
"community::",
}

local function resolvePlayerGuildName()
local getGuildInfo=_G.GetGuildInfo
if type(getGuildInfo)~="function"then
return nil
end
local ok,name=pcall(getGuildInfo,"player")
if not ok then
return nil
end
if type(name)=="string"and name~=""then
return name
end
return nil
end

local function resolveGuildOwnership(conversation,conversationKey,localProfileId)




if conversation and type(conversation.guildName)=="string"and conversation.guildName~=""then
local playerGuild=resolvePlayerGuildName()
if playerGuild and string.lower(playerGuild)==string.lower(conversation.guildName)then
return nil,nil
end
local ownerProfileId=conversation.ownerProfileId
return ownerProfileId,ownerProfileId
end


local keyOwner=string.sub(conversationKey,8)
if keyOwner==""then
return nil,nil
end
if keyOwner==localProfileId then
return nil,keyOwner
end
return keyOwner,keyOwner
end

function DataBuilder.BuildItemsForProfile(savedState,localProfileId)
local items={}
local profilePrefix=localProfileId.."::"
local bnetPrefix="bnet::"
local wowPrefix="wow::"
local playerClasses=savedState.playerClasses or{}

for conversationKey,conversation in pairs(savedState.conversations or{})do
local include=false




local foreignOwner=nil




local ownerClassTag=nil

if
string.find(conversationKey,profilePrefix,1,true)==1
or string.find(conversationKey,bnetPrefix,1,true)==1
or string.find(conversationKey,wowPrefix,1,true)==1
then
include=true
end

if not include then
if string.find(conversationKey,"guild::",1,true)==1 then
include=true
local ownerId
foreignOwner,ownerId=resolveGuildOwnership(conversation,conversationKey,localProfileId)
if foreignOwner==nil and ownerId==nil then

ownerClassTag=playerClasses[localProfileId]or nil
elseif ownerId then
ownerClassTag=playerClasses[ownerId]or nil
end
end
end

if not include then
for _,prefix in ipairs(PER_CHARACTER_GROUP_PREFIXES)do
if prefix~="guild::"and string.find(conversationKey,prefix,1,true)==1 then
include=true
local keyOwner=conversation and conversation.ownerProfileId
if type(keyOwner)~="string"or keyOwner==""then
keyOwner=string.sub(conversationKey,#prefix+1)
end
if keyOwner~=""then
if keyOwner~=localProfileId then
foreignOwner=keyOwner
end
ownerClassTag=playerClasses[keyOwner]or nil
end
break
end
end
end

if not include then
for _,prefix in ipairs(ACCOUNT_GROUP_PREFIXES)do
if string.find(conversationKey,prefix,1,true)==1 then
include=true
break
end
end
end

if include then
local snapshot=ConversationSnapshot.Build(conversationKey,conversation,savedState.settings)
snapshot.ownerProfileId=foreignOwner
snapshot.ownerClassTag=ownerClassTag
table.insert(items,snapshot)
end
end

table.sort(items,compareItems)
return items
end

ns.ContactsListDataBuilder=DataBuilder
return DataBuilder
