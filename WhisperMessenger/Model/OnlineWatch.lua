local addonName,ns=...
if type(ns)~="table"then
ns={}
end




local Identity=ns.Identity or require("WhisperMessenger.Model.Identity")

local OnlineWatch={}



function OnlineWatch.Observe(runtime,conversationKey,isOnline)
if isOnline==nil or conversationKey==nil then
return false
end
runtime.onlineWatch=runtime.onlineWatch or{}
local previous=runtime.onlineWatch[conversationKey]
runtime.onlineWatch[conversationKey]=isOnline
return previous==false and isOnline==true
end


function OnlineWatch.StampSeen(runtime,conversation)
if conversation~=nil and type(runtime.now)=="function"then
conversation.lastSeenAt=runtime.now()
end
end


local function readCharacterFriend(api,name)
if type(api)~="table"or type(api.GetFriendInfo)~="function"or type(name)~="string"then
return nil
end
local ok,info=pcall(api.GetFriendInfo,name)
if not(ok and type(info)=="table")then
local short=Identity.ShortName(name)
if short~=name then
ok,info=pcall(api.GetFriendInfo,short)
end
end
if ok and type(info)=="table"then
return info.connected==true
end
return nil
end


local function readBNetFriend(api,conversation)
local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")
local BNetStatus=ns.ContactEnricherBNetStatus or require("WhisperMessenger.Model.ContactEnricher.BNetStatus")
local accountInfo=BNetResolver.ResolveAccountInfo(api,conversation.bnetAccountID,conversation.guid,conversation.battleTag)
return BNetStatus.IsOnline(accountInfo)
end



function OnlineWatch.ReadOnline(runtime,conversation)
if type(conversation)~="table"then
return nil
end
if conversation.channel=="BN"then
if conversation.bnetAccountID==nil or runtime.bnetApi==nil then
return nil
end
local ok,online=pcall(readBNetFriend,runtime.bnetApi,conversation)
if not ok then
return nil
end
return online
end
return readCharacterFriend(runtime.friendListApi,conversation.displayName)
end




function OnlineWatch.CanWatch(item,friendListApi)
if type(item)~="table"then
return false
end
if item.notifyOnline==true or item.channel=="BN"then
return true
end
if type(friendListApi)~="table"or type(friendListApi.IsFriend)~="function"or item.guid==nil then
return false
end
local ok,isFriend=pcall(friendListApi.IsFriend,item.guid)
return ok and isFriend==true
end

ns.OnlineWatch=OnlineWatch
return OnlineWatch
