local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ContactsTabFilter=ns.ContactsTabFilter or require("WhisperMessenger.UI.ContactsList.ContactsTabFilter")




local RequestFollow={}

function RequestFollow.Create(getWindow,selectConversation)



local requestKeys={}
local follow={}


function follow.takeRequestKeys(contacts)
local previous=requestKeys
requestKeys={}
for _,item in ipairs(contacts)do
if item.isRequest==true then
requestKeys[item.conversationKey]=true
end
end
return previous
end




local function followToWhispers(window,conversationKey)
if selectConversation==nil or window==nil or type(window.setTabMode)~="function"then
return nil
end
window.setTabMode("whispers")
if window.getTabMode()~="whispers"then
return nil
end
return selectConversation(conversationKey)
end









function follow.reconcile(nextState,previousRequestKeys)
local window=getWindow()
local tabMode=window and type(window.getTabMode)=="function"and window.getTabMode()or nil
local selectedMode=tabMode and nextState and nextState.selectedContact and ContactsTabFilter.ModeOf(nextState.selectedContact)
if not selectedMode or selectedMode==tabMode then
return nextState,false
end
local selectedKey=nextState.selectedContact.conversationKey
if tabMode=="requests"and selectedMode=="whispers"and previousRequestKeys[selectedKey]then
local followed=followToWhispers(window,selectedKey)
if followed then
return followed,true
end
end
return{contacts=nextState.contacts},false
end

return follow
end

ns.BootstrapWindowCoordinatorRequestFollow=RequestFollow
return RequestFollow
