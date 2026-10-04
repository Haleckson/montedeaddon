local addonName,ns=...
if type(ns)~="table"then
ns={}
end




local AlertPolicy={}

local MessageRequests=ns.MessageRequests or require("WhisperMessenger.Model.MessageRequests")



function AlertPolicy.ShouldAlert(conversation,settings)
if type(conversation)~="table"then
return true
end
if MessageRequests.IsRequest(conversation,settings)then
return false
end
return conversation.muted~=true
end

ns.AlertPolicy=AlertPolicy
return AlertPolicy
