local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")
local Constants=ns.Constants or require("WhisperMessenger.Core.Constants")
local GroupChatIngest=ns.GroupChatIngest or require("WhisperMessenger.Core.Ingest.GroupChatIngest")
local IncomingAlerts=ns.BootstrapEventBridgeIncomingAlerts or require("WhisperMessenger.Core.Bootstrap.EventBridge.IncomingAlerts")

local GroupRouter={}

local GROUP_EVENTS={}
for _,name in ipairs(Constants.GROUP_EVENT_NAMES)do
GROUP_EVENTS[name]=true
end





local function conversationIncludesSender(conversationID,bnSenderID)
local ok,matched=pcall(function()
if type(_G.BNGetNumConversationMembers)~="function"or type(_G.BNGetConversationMemberInfo)~="function"then
return nil
end
local numMembers=_G.BNGetNumConversationMembers(conversationID)or 0
for memberIndex=1,numMembers do
local returns={_G.BNGetConversationMemberInfo(conversationID,memberIndex)}
for _,value in ipairs(returns)do
if value==bnSenderID then
return true
end
end
end
return false
end)
if not ok then
return nil
end
return matched
end






local function resolveBNConversationID(bnSenderID)
if bnSenderID==nil then
return nil
end
local ok,numConversations=pcall(function()
return _G.BNGetNumConversations and _G.BNGetNumConversations()or 0
end)
if not ok or type(numConversations)~="number"or numConversations<1 then
return nil
end
local firstConversationID=nil
local sawUnknownMembership=false
for i=1,numConversations do
local convOk,conversationID=pcall(function()
local id=_G.BNGetConversationInfo and _G.BNGetConversationInfo(i)
return id
end)
if convOk and conversationID~=nil then
if firstConversationID==nil then
firstConversationID=conversationID
end
local matched=conversationIncludesSender(conversationID,bnSenderID)
if matched==true then
return conversationID
end
if matched==nil then
sawUnknownMembership=true
end
end
end




if sawUnknownMembership then
return firstConversationID
end
return nil
end






local function resolveCommunityChatSource()
local clubApi=_G.C_Club
if type(clubApi)~="table"or type(clubApi.GetInfoFromLastCommunityChatLine)~="function"then
return nil,nil,nil
end
local ok,info=pcall(clubApi.GetInfoFromLastCommunityChatLine)
if not ok or type(info)~="table"then
return nil,nil,nil
end
return info.clubId,info.streamId,info.clubType
end

function GroupRouter.RouteGroupEvent(runtime,eventName,...)
if runtime==nil or not GROUP_EVENTS[eventName]then
return false
end




local args={...}
local text=args[1]
local playerName=args[2]
local channelName=args[4]
local channelBaseName=args[9]
local lineID=args[11]
local guid=args[12]
local bnSenderID=args[13]

local conversationID=nil
if eventName=="CHAT_MSG_BN_CONVERSATION"then
conversationID=resolveBNConversationID(bnSenderID)
end




local clubId,streamId,streamName=nil,nil,nil
if eventName=="CHAT_MSG_COMMUNITIES_CHANNEL"then
local cId,sId,clubType=resolveCommunityChatSource()
if cId==nil or sId==nil then
return false
end

if clubType==2 then
return false
end
clubId=tostring(cId)
streamId=tostring(sId)

if type(channelBaseName)=="string"and channelBaseName~=""then
streamName=channelBaseName
elseif type(channelName)=="string"and channelName~=""then
streamName=channelName
end
end




local playerInfo=nil
if guid and eventName~="CHAT_MSG_BN_CONVERSATION"then
playerInfo=BNetResolver.ResolvePlayerInfo(runtime and runtime.playerInfoByGUID or nil,guid)
end

local payload={
text=text,
playerName=playerName,
lineID=lineID,
guid=guid,
bnSenderID=bnSenderID,
conversationID=conversationID,
clubId=clubId,
streamId=streamId,
streamName=streamName,
playerInfo=playerInfo,
}

runtime.onGroupReactionFallbackDegraded=function(conversation)
pcall(function()
if conversation and type(runtime.isWindowVisible)=="function"and runtime.isWindowVisible()and type(runtime.refreshWindow)=="function"then
runtime.refreshWindow()
end
end)
end

local handled,_,meta=GroupChatIngest.HandleEvent(runtime,eventName,payload)


if meta and meta.mention then
IncomingAlerts.Notify(runtime.accountState and runtime.accountState.settings)
end
if handled and type(runtime.isWindowVisible)=="function"and runtime.isWindowVisible()and type(runtime.refreshWindow)=="function"then
runtime.refreshWindow()
end
return handled
end

ns.BootstrapEventBridgeGroupRouter=GroupRouter

return GroupRouter
