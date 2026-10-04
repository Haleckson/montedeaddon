local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")
local Router=ns.EventRouter or require("WhisperMessenger.Core.EventRouter")
local Gateway=ns.WhisperGateway or require("WhisperMessenger.Transport.WhisperGateway")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")
local FlavorCompat=ns.FlavorCompat or require("WhisperMessenger.Core.FlavorCompat")
local QuestLinkClassic=ns.UIHyperlinksQuestLinkClassic or require("WhisperMessenger.UI.Hyperlinks.QuestLinkClassic")
local AddonComm=ns.AddonComm or require("WhisperMessenger.Transport.AddonComm")
local QuestLinkExchange=ns.QuestLinkExchange or require("WhisperMessenger.Model.QuestLinkExchange")
local MessageReactionProtocol=ns.MessageReactionProtocol or require("WhisperMessenger.Model.MessageReactionProtocol")
local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")
local OutgoingDelivery=ns.OutgoingDelivery or require("WhisperMessenger.Model.OutgoingDelivery")
local MessageReplies=ns.MessageReplies or require("WhisperMessenger.Model.MessageReplies")
local LivePresence=ns.LivePresence or require("WhisperMessenger.Model.LivePresence")

local QUEST_LINK_ADDON_PREFIX="WMQL"
local REACTION_ADDON_PREFIX="WMRX"

local SendHandler={}





local function appendUnsentOutgoing(runtime,payload,delivery,reason)
if runtime==nil or runtime.store==nil or payload==nil or payload.conversationKey==nil or payload.reactionControl~=nil then
return
end

local now=runtime.now and runtime.now()or 0
payload.deliveryRecorded=true
Store.AppendOutgoing(runtime.store,payload.conversationKey,OutgoingDelivery.BuildRecord(payload,now,delivery,reason))
end


local function lockReason(runtime)
if runtime.isMythicLockdown and runtime.isMythicLockdown()then
return"Mythic Lockdown"
end
if runtime.isCompetitiveContent and runtime.isCompetitiveContent()then
return"Competitive Content"
end
return nil
end

local function isBattleTag(value)
return type(value)=="string"and string.match(value,"^[^#]+#%d+$")~=nil
end

local function resolveBattleNetRecipient(runtime,payload)
local conversations=runtime.store and runtime.store.conversations
local conversation=conversations and conversations[payload.conversationKey]
local storedBattleTag=conversation and conversation.battleTag
local payloadBattleTag=payload.battleTag
if storedBattleTag~=nil and payloadBattleTag~=nil and storedBattleTag~=payloadBattleTag then
return nil
end

local expectedBattleTag=storedBattleTag or payloadBattleTag
if expectedBattleTag==nil and isBattleTag(payload.displayName)then
expectedBattleTag=payload.displayName
end

local oldBnetAccountID=payload.bnetAccountID or(conversation and conversation.bnetAccountID)
local guid=payload.guid or(conversation and conversation.guid)
local accountInfo
if expectedBattleTag and oldBnetAccountID~=nil and type(BNetResolver.ResolveAccountInfo)=="function"then
accountInfo=BNetResolver.ResolveAccountInfo(runtime.bnetApi,oldBnetAccountID,guid,expectedBattleTag)
end

local resolvedBnetAccountID=accountInfo and BNetResolver.SanitizeAccountID(accountInfo.bnetAccountID)
if accountInfo==nil or accountInfo.battleTag~=expectedBattleTag or type(resolvedBnetAccountID)~="number"then
if expectedBattleTag and type(BNetResolver.ResolveFriendByBattleTag)=="function"then
accountInfo=BNetResolver.ResolveFriendByBattleTag(runtime.bnetApi,expectedBattleTag,guid)
resolvedBnetAccountID=accountInfo and BNetResolver.SanitizeAccountID(accountInfo.bnetAccountID)
end
end

if accountInfo==nil or accountInfo.battleTag~=expectedBattleTag or type(resolvedBnetAccountID)~="number"then
return nil
end

local gameAccountInfo=accountInfo.gameAccountInfo
local resolvedGameAccountID=BNetResolver.SanitizeAccountID(gameAccountInfo and gameAccountInfo.gameAccountID)
if type(resolvedGameAccountID)~="number"then
resolvedGameAccountID=nil
end

payload.bnetAccountID=resolvedBnetAccountID
payload.gameAccountID=resolvedGameAccountID
if conversation then
conversation.bnetAccountID=resolvedBnetAccountID
end

return resolvedBnetAccountID
end

local function normalizeOutgoingText(payload,text)
if type(text)~="string"then
return text
end
local isClassicCharacterWhisper=FlavorCompat.isClassic and(payload.channel==nil or payload.channel=="WOW")
if isClassicCharacterWhisper then
return QuestLinkClassic.Serialize(text)
end
return QuestLinkClassic.Rewrite(text)
end

local function canonicalReactionText(text)
if type(QuestLinkClassic.CanonicalizeForTransport)=="function"then
return QuestLinkClassic.CanonicalizeForTransport(text)
end
return text
end

local function canonicalTargetText(text)
if type(QuestLinkClassic.Serialize)=="function"then
return QuestLinkClassic.Serialize(text)
end
return text
end

local function dispatchReactionMetadata(runtime,payload,addonPayload)
if type(addonPayload)~="string"then
return false
end
AddonComm.RegisterPrefix(runtime.chatApi,REACTION_ADDON_PREFIX)
if payload.channel=="BN"then
return AddonComm.SendBNet(runtime.bnetApi,REACTION_ADDON_PREFIX,addonPayload,payload.gameAccountID)
end
return AddonComm.Send(runtime.chatApi,REACTION_ADDON_PREFIX,addonPayload,payload.target)
end

function SendHandler.HandleSend(runtime,payload,refreshWindow)
local locked=lockReason(runtime)
if locked then
appendUnsentOutgoing(runtime,payload,"queued",locked)
runtime.sendStatusByConversation[payload.conversationKey]=Availability.FromStatus(locked)
refreshWindow()
return false
end

local sendAvailable
if payload.channel=="BN"then
local resolvedBnetAccountID=resolveBattleNetRecipient(runtime,payload)
sendAvailable=resolvedBnetAccountID~=nil and Gateway.CanSendBattleNetWhisper(runtime.bnetApi)
else
sendAvailable=Gateway.CanSendCharacterWhisper(runtime.chatApi)
end

if not sendAvailable then
runtime.sendStatusByConversation[payload.conversationKey]=Availability.FromStatus("Send unavailable")
refreshWindow()
return false
end
runtime.sendStatusByConversation[payload.conversationKey]=nil

local reactionControl=type(payload.reactionControl)=="table"and payload.reactionControl or nil
if reactionControl then
local operation=reactionControl.operation or{}
local normalizedSource=canonicalReactionText(normalizeOutgoingText(payload,reactionControl.sourceText or""))
payload.text=MessageReactionProtocol.BuildFallback(operation.key,operation.operation,normalizedSource,reactionControl.hintSuffix)
else
payload.text=normalizeOutgoingText(payload,payload.text)
end

local wireId
local reactionAddonPayload
if reactionControl then
local operation=reactionControl.operation or{}
reactionAddonPayload=MessageReactionProtocol.EncodeReaction(
operation.operation,
operation.key,
operation.wireId,
canonicalTargetText(reactionControl.sourceText),
canonicalReactionText(payload.text)
)
local encodedOperation=MessageReactionProtocol.Decode(reactionAddonPayload)
if encodedOperation then
reactionControl.operation=encodedOperation
end
else
wireId=payload.wireId or MessageReactionProtocol.NewWireId(runtime,runtime.now and runtime.now()or 0)
payload.wireId=wireId
reactionAddonPayload=MessageReactionProtocol.EncodeIdentity(wireId,canonicalReactionText(payload.text))
end

local pendingConversationKey=Router.RecordPendingSend(runtime,payload,payload.text,{
wireId=wireId,
reactionControl=reactionControl,
replyTo=payload.replyTo,
})
local callOk
if payload.channel=="BN"then
callOk=pcall(Gateway.SendBattleNetWhisper,runtime.bnetApi,payload.bnetAccountID,payload.text)






if callOk and FlavorCompat.isClassic and payload.gameAccountID~=nil then
local encoded=QuestLinkExchange.Encode(payload.text)
if encoded~=nil then
AddonComm.RegisterPrefix(runtime.chatApi,QUEST_LINK_ADDON_PREFIX)
AddonComm.SendBNet(runtime.bnetApi,QUEST_LINK_ADDON_PREFIX,encoded,payload.gameAccountID)
end
end
else



Gateway.SendCharacterWhisper(runtime.chatApi,payload.target,payload.text)
callOk=true







if FlavorCompat.isClassic then
local encoded=QuestLinkExchange.Encode(payload.text)
if encoded~=nil and payload.target~=nil and payload.target~=""then
AddonComm.RegisterPrefix(runtime.chatApi,QUEST_LINK_ADDON_PREFIX)
AddonComm.Send(runtime.chatApi,QUEST_LINK_ADDON_PREFIX,encoded,payload.target)
end
end
end

if not callOk then
local pending=runtime.pendingOutgoing[pendingConversationKey]
if pending and#pending>0 then
table.remove(pending,#pending)
if#pending==0 then
runtime.pendingOutgoing[pendingConversationKey]=nil
end
end

appendUnsentOutgoing(runtime,payload,"failed","Send failed")
runtime.sendStatusByConversation[payload.conversationKey]=Availability.FromStatus("Send failed")
refreshWindow()
return false
end

dispatchReactionMetadata(runtime,payload,reactionAddonPayload)

if LivePresence.HasPeer(runtime,payload.conversationKey)then
dispatchReactionMetadata(runtime,payload,MessageReplies.EncodeLink(wireId,payload.replyTo))
end

refreshWindow()
return true
end

ns.BootstrapSendHandler=SendHandler
return SendHandler
