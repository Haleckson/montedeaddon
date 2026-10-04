local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")
local Retention=ns.Retention or require("WhisperMessenger.Model.Retention")







local OutgoingDelivery={}

local STATUS={
queued="queued",
blocked="notSent",
failed="notSent",
}




local localProfileId=nil

function OutgoingDelivery.SetLocalProfileId(profileId)
localProfileId=profileId
end


local function isOtherCharacters(message)
return message.profileId~=nil and localProfileId~=nil and message.profileId~=localProfileId
end

function OutgoingDelivery.IsOtherCharacters(message)
return type(message)=="table"and isOtherCharacters(message)
end


function OutgoingDelivery.Status(message)
if type(message)~="table"or message.direction~="out"then
return nil
end
return STATUS[message.delivery]
end


local DISCARD_ONLY={"discard"}
local SEND_OR_DISCARD={"send_now","discard"}
local RETRY_OR_DISCARD={"retry","discard"}
local NO_ACTIONS={}




function OutgoingDelivery.Actions(message,chatLocked)
local status=OutgoingDelivery.Status(message)
if status=="queued"then
if chatLocked or isOtherCharacters(message)then
return DISCARD_ONLY
end
return SEND_OR_DISCARD
end
if status=="notSent"then
return message.delivery=="failed"and RETRY_OR_DISCARD or DISCARD_ONLY
end
return NO_ACTIONS
end

function OutgoingDelivery.CountQueued(store)
local count=0
local conversations=type(store)=="table"and store.conversations or nil
for _,conversation in pairs(conversations or{})do
for _,message in ipairs(conversation.messages or{})do
if message.direction=="out"and Retention.IsQueued(message)and not isOtherCharacters(message)then
count=count+1
end
end
end
return count
end

function OutgoingDelivery.Remove(store,conversationKey,message)
local conversation=Store.Find(store,conversationKey)
if conversation==nil or message==nil then
return false
end
local messages=conversation.messages or{}
for index=#messages,1,-1 do
if messages[index]==message then
table.remove(messages,index)
local last=messages[#messages]
conversation.lastPreview=last and last.text or nil
return true
end
end
return false
end


local recordSequence=0


function OutgoingDelivery.BuildRecord(fields,now,delivery,reason)
recordSequence=recordSequence+1
return{
id=tostring(now).."-"..recordSequence,
direction="out",
kind="user",
text=fields.text,
sentAt=now,
guid=fields.guid,
target=fields.target,
playerName=fields.displayName or fields.target,
channel=fields.channel or"WOW",
bnetAccountID=fields.bnetAccountID,
gameAccountName=fields.gameAccountName,
replyTo=fields.replyTo,
delivery=delivery,
blockedReason=reason,
profileId=localProfileId,
}
end

ns.OutgoingDelivery=OutgoingDelivery
return OutgoingDelivery
