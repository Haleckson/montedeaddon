local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")




local ConversationDrafts={}

function ConversationDrafts.Get(store,conversationKey)
local conversation=Store.Find(store,conversationKey)
return conversation and conversation.draft or nil
end




function ConversationDrafts.Set(store,conversationKey,text)
local conversation=Store.Find(store,conversationKey)
if conversation==nil then
return
end
local ok,hasText=pcall(string.find,text,"%S")
if type(text)=="string"and ok and hasText then
conversation.draft=text
else
conversation.draft=nil
end
end

ns.ConversationDrafts=ConversationDrafts
return ConversationDrafts
