local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local SelectionSync={}




function SelectionSync.SyncComposerSelectedContact(target,selectedContact,composer,getDraft)
local previousKey=target.conversationKey
target.conversationKey=selectedContact and selectedContact.conversationKey or nil
target.displayName=selectedContact and selectedContact.displayName or nil
target.channel=selectedContact and selectedContact.channel or nil
target.bnetAccountID=selectedContact and selectedContact.bnetAccountID or nil
target.conversationID=selectedContact and selectedContact.conversationID or nil
target.guid=selectedContact and selectedContact.guid or nil
target.gameAccountName=selectedContact and selectedContact.gameAccountName or nil

local nextKey=target.conversationKey
if nextKey==previousKey or composer==nil or composer.loadDraft==nil then
return
end
composer.loadDraft(nextKey~=nil and getDraft~=nil and getDraft(nextKey)or nil)
end

function SelectionSync.SetComposerEnabled(composer,selectedContact,noticeText)
local hasNotice=noticeText and noticeText~=""
local enabled=selectedContact~=nil and not hasNotice
if composer.setEnabled then
composer.setEnabled(enabled)
end
end

ns.MessengerWindowSelectionSync=SelectionSync

return SelectionSync
