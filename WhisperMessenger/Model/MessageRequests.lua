local addonName,ns=...
if type(ns)~="table"then
ns={}
end






local Identity=ns.Identity or require("WhisperMessenger.Model.Identity")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")

local MessageRequests={}

function MessageRequests.IsRequest(conversation,settings)
return type(conversation)=="table"and conversation.request==true and type(settings)=="table"and settings.requestsInbox==true
end



local function ask(fn,...)
if type(fn)~="function"then
return nil
end
local ok,related=pcall(function(...)
return fn(...)and true or false
end,...)
if not ok then
return nil
end
return related
end


local function isStranger(runtime,guid,name)
if type(guid)~="string"or guid==""or type(name)~="string"or name==""then
return false
end
local friendListApi=runtime.friendListApi or{}
local bnetApi=runtime.bnetApi or{}
local unitName=Identity.ShortName(name)
local answers={
ask(friendListApi.IsFriend,guid),
ask(bnetApi.GetGameAccountInfoByGUID,guid),
ask(_G.IsGuildMember,guid),
ask(_G.UnitInParty,unitName),
ask(_G.UnitInRaid,unitName),
}
for index=1,5 do
if answers[index]~=false then
return false
end
end


if type(_G.IsGUIDInGroup)=="function"and ask(_G.IsGUIDInGroup,guid)~=false then
return false
end
return true
end



function MessageRequests.ClassifyNew(runtime,conversation,guid,name)
local settings=runtime and runtime.accountState and runtime.accountState.settings
if type(conversation)~="table"or type(settings)~="table"or settings.requestsInbox~=true then
return
end
if conversation.channel=="BN"then
return
end
if isStranger(runtime,guid,name)then
conversation.request=true
end
end

function MessageRequests.Accept(store,conversationKey)
local conversation=Store.Find(store,conversationKey)
if conversation then
conversation.request=nil
end
end

ns.MessageRequests=MessageRequests
return MessageRequests
