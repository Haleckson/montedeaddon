local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local WhisperGateway=ns.WhisperGateway or require("WhisperMessenger.Transport.WhisperGateway")
local ChannelType=ns.ChannelType or require("WhisperMessenger.Model.Identity.ChannelType")

local Gateway={}








local function resolveChatSender(api)
if type(api)=="table"and type(api.SendChatMessage)=="function"then
return api.SendChatMessage
end
if type(_G.C_ChatInfo)=="table"and type(_G.C_ChatInfo.SendChatMessage)=="function"then
return _G.C_ChatInfo.SendChatMessage
end
return nil
end




local function resolveConversationSender(api)
if type(api)=="table"and type(api.SendConversationMessage)=="function"then
return api.SendConversationMessage
end
if type(_G.BNSendConversationMessage)=="function"then
return _G.BNSendConversationMessage
end
return nil
end






function Gateway.SendWhisper(api,target,text)
return WhisperGateway.SendCharacterWhisper(api,target,text)
end


function Gateway.SendBattleNetWhisper(api,bnetAccountID,text)
return WhisperGateway.SendBattleNetWhisper(api,bnetAccountID,text)
end


function Gateway.SendBattleNetConversation(api,conversationID,text)
local sender=resolveConversationSender(api)
if sender==nil then
error("No Battle.net conversation sender available")
end
return sender(conversationID,text)
end


function Gateway.SendParty(api,text)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
return sender(text,"PARTY")
end



function Gateway.SendRaid(api,text,warning)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
local chatType=warning and"RAID_WARNING"or"RAID"
return sender(text,chatType)
end


function Gateway.SendInstance(api,text)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
return sender(text,"INSTANCE_CHAT")
end


function Gateway.SendGuild(api,text)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
return sender(text,"GUILD")
end


function Gateway.SendOfficer(api,text)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
return sender(text,"OFFICER")
end



function Gateway.SendChannel(api,channelIndex,text)
local sender=resolveChatSender(api)
if sender==nil then
error("No chat sender available")
end
return sender(text,"CHANNEL",nil,channelIndex)
end







local function checkMembership(fn,...)
local ok,result=pcall(fn,...)
return ok and result==true
end



local senderAvailability={
[ChannelType.WHISPER]=function(api)
return WhisperGateway.CanSendCharacterWhisper(api)
end,
[ChannelType.BN_WHISPER]=function(api)
return WhisperGateway.CanSendBattleNetWhisper(api)
end,
[ChannelType.BN_CONVERSATION]=function(api,conversation)
if resolveConversationSender(api)==nil then
return false
end

if type(_G.BNGetConversationInfo)=="function"then
local conversationID=type(conversation)=="table"and conversation.conversationID or nil
local ok,info=pcall(_G.BNGetConversationInfo,conversationID)
return ok and info~=nil
end
return true
end,
[ChannelType.PARTY]=function(api)
if resolveChatSender(api)==nil then
return false
end
if type(_G.IsInGroup)=="function"then
local category=type(_G.LE_PARTY_CATEGORY_HOME)=="number"and _G.LE_PARTY_CATEGORY_HOME or 1
return checkMembership(_G.IsInGroup,category)
end
return true
end,
[ChannelType.RAID]=function(api)
if resolveChatSender(api)==nil then
return false
end
if type(_G.IsInRaid)=="function"then


local category=type(_G.LE_PARTY_CATEGORY_HOME)=="number"and _G.LE_PARTY_CATEGORY_HOME or 1
return checkMembership(_G.IsInRaid,category)
end
return true
end,
[ChannelType.INSTANCE_CHAT]=function(api)
if resolveChatSender(api)==nil then
return false
end
if type(_G.IsInGroup)=="function"then
local category=type(_G.LE_PARTY_CATEGORY_INSTANCE)=="number"and _G.LE_PARTY_CATEGORY_INSTANCE or 2
return checkMembership(_G.IsInGroup,category)
end
return true
end,
[ChannelType.GUILD]=function(api)
if resolveChatSender(api)==nil then
return false
end
if type(_G.IsInGuild)=="function"then
return checkMembership(_G.IsInGuild)
end
return true
end,
[ChannelType.OFFICER]=function(api)
if resolveChatSender(api)==nil then
return false
end
if type(_G.IsInGuild)=="function"then
return checkMembership(_G.IsInGuild)
end
return true
end,
[ChannelType.CHANNEL]=function(api,conversation)
if resolveChatSender(api)==nil then
return false
end
if type(_G.GetChannelName)=="function"then
local baseName=type(conversation)=="table"and conversation.channelBaseName or nil
local ok,index=pcall(_G.GetChannelName,baseName)
return ok and type(index)=="number"and index~=0
end
return true
end,
}



function Gateway.CanSend(api,conversation)
if type(conversation)~="table"then
return false
end
local channel=conversation.channel
if channel==ChannelType.COMMUNITY then
return false
end
local checker=senderAvailability[channel]
if checker==nil then
return false
end
local ok,result=pcall(checker,api,conversation)
return ok and result==true
end



function Gateway.Send(api,conversation,text)
local channel=conversation and conversation.channel

if channel==ChannelType.WHISPER then
return Gateway.SendWhisper(api,conversation.target,text)
elseif channel==ChannelType.BN_WHISPER then
return Gateway.SendBattleNetWhisper(api,conversation.bnetAccountID,text)
elseif channel==ChannelType.BN_CONVERSATION then
return Gateway.SendBattleNetConversation(api,conversation.conversationID,text)
elseif channel==ChannelType.PARTY then
return Gateway.SendParty(api,text)
elseif channel==ChannelType.RAID then
return Gateway.SendRaid(api,text,false)
elseif channel==ChannelType.INSTANCE_CHAT then
return Gateway.SendInstance(api,text)
elseif channel==ChannelType.GUILD then
return Gateway.SendGuild(api,text)
elseif channel==ChannelType.OFFICER then
return Gateway.SendOfficer(api,text)
elseif channel==ChannelType.CHANNEL then
return Gateway.SendChannel(api,conversation.channelIndex,text)
elseif channel==ChannelType.COMMUNITY then
error("COMMUNITY is receive-only: addon sends are blocked by Blizzard C_Club protection")
else
error("Unknown channel: "..tostring(channel))
end
end

ns.ChatGateway=Gateway

return Gateway
