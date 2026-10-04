local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChannelContextMerger={}





local cachedEntry
local cachedPlayerName
local cachedMessage


local WHISPER_CHANNELS={WOW=true,BN=true}

local function lookupNameFor(selectedContact)
if type(selectedContact)~="table"then
return nil
end
local name=selectedContact.gameAccountName or selectedContact.displayName
if type(name)~="string"or name==""then
return nil
end
return string.lower(name)
end

local function buildChannelMessage(entry,playerName)
return{
id="channel-ctx-"..tostring(entry.sentAt),
direction="in",
kind="channel_context",
text=entry.text,
sentAt=entry.sentAt,
playerName=playerName,
channelLabel=entry.channelLabel,
}
end

local function insertChronological(messages,channelMsg)
local insertAt=#messages+1
for index,message in ipairs(messages)do
if(channelMsg.sentAt or 0)<(message.sentAt or 0)then
insertAt=index
break
end
end
table.insert(messages,insertAt,channelMsg)
end





local function persistIntoConversation(conversation,entry,playerName)
local messages=conversation.messages
for index,message in ipairs(messages)do
if message.kind=="channel_context"then
if(message.sentAt or 0)>entry.sentAt or(message.sentAt==entry.sentAt and message.text==entry.text)then
return
end
table.remove(messages,index)
break
end
end
insertChronological(messages,buildChannelMessage(entry,playerName))
end




function ChannelContextMerger.Merge(messages,selectedContact,deps)
deps=deps or{}
local store=deps.channelMessageStore
local state=deps.channelMessageState
if not store or not state then
return messages
end

local lookupName=lookupNameFor(selectedContact)
if lookupName==nil then
return messages
end

local entry=store.GetLatest(state,lookupName,deps.now)
if not entry then
return messages
end

local playerName=selectedContact.displayName or entry.playerName
local conversation=deps.conversation
if type(conversation)=="table"and conversation.messages==messages and WHISPER_CHANNELS[conversation.channel]then
persistIntoConversation(conversation,entry,playerName)
return messages
end

local channelMsg=cachedMessage
if channelMsg==nil or cachedEntry~=entry or cachedPlayerName~=playerName then
channelMsg=buildChannelMessage(entry,playerName)
cachedEntry=entry
cachedPlayerName=playerName
cachedMessage=channelMsg
end

local result={}
for _,m in ipairs(messages)do
result[#result+1]=m
end
insertChronological(result,channelMsg)
return result
end

ns.ConversationPaneChannelContextMerger=ChannelContextMerger
return ChannelContextMerger
