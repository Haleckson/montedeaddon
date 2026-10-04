local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local PendingOutgoing=ns.EventRouterPendingOutgoing or require("WhisperMessenger.Core.EventRouter.PendingOutgoing")
local OutgoingDelivery=ns.OutgoingDelivery or require("WhisperMessenger.Model.OutgoingDelivery")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")
local RosterLookup=ns.RosterLookup or require("WhisperMessenger.Model.RosterLookup")
local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")






local FailedWhisper={}

local function namedBy(template,text,name)
return type(name)=="string"and name~=""and string.format(template,name)==text
end




local function applyRosterIdentity(state,record)
record.guid=record.guid or RosterLookup.FindGUIDByName(state.clubApi or _G["C_Club"],record.target)
local playerInfo=BNetResolver.ResolvePlayerInfo(state.playerInfoByGUID,record.guid)
if playerInfo then
record.className=playerInfo.className
record.classTag=playerInfo.classTag
record.raceName=playerInfo.raceName
record.raceTag=playerInfo.raceTag
end
end


function FailedWhisper.Handle(state,text)
local template=_G.ERR_CHAT_PLAYER_NOT_FOUND_S
if type(text)~="string"or type(template)~="string"or type(state.pendingOutgoing)~="table"then
return nil
end
local now=state.now and state.now()or nil
local conversationKey,entry=PendingOutgoing.ConsumeWhere(state,function(pending)
if(pending.channel or"WOW")~="WOW"or pending.reactionControl~=nil then
return false
end
return namedBy(template,text,pending.target)or namedBy(template,text,pending.displayName)
end,now)
if entry==nil then
return nil
end
local sentAt=entry.createdAt or now or 0
local record=OutgoingDelivery.BuildRecord(entry,sentAt,"failed","Player not found")
applyRosterIdentity(state,record)
Store.AppendOutgoing(state.store,conversationKey,record)
local conversation=state.store.conversations[conversationKey]
if conversation then
conversation.conversationKey=conversationKey
end
return conversation
end

ns.EventRouterFailedWhisper=FailedWhisper
return FailedWhisper
