local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ContactsTabFilter=ns.ContactsTabFilter or require("WhisperMessenger.UI.ContactsList.ContactsTabFilter")
local ConversationSnapshot=ns.ConversationSnapshot or require("WhisperMessenger.Model.ConversationSnapshot")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")

local ToggleFlow={}



local function conversationMatchesTab(runtime,conversationKey,tabMode)
if tabMode==nil then
return true
end

local conversation=Store.Find(runtime.store,conversationKey)
if conversation==nil then
return true
end

local settings=runtime.accountState and runtime.accountState.settings
return ContactsTabFilter.ModeOf(ConversationSnapshot.Build(conversationKey,conversation,settings))==tabMode
end

function ToggleFlow.Create(options)
options=options or{}

local runtime=options.runtime or{}
local ensureWindow=options.ensureWindow or function()end
local isWindowVisible=options.isWindowVisible or function()
return false
end
local setWindowVisible=options.setWindowVisible or function()end
local getWindow=options.getWindow or function()
return nil
end
local findLatestUnreadKey=options.findLatestUnreadKey or function()
return nil
end
local selectConversation=options.selectConversation or function()end
local refreshWindow=options.refreshWindow or function()end

local function matchesTab(conversationKey,tabMode)
return conversationMatchesTab(runtime,conversationKey,tabMode)
end

local function toggle()
ensureWindow()
local nextVisible=not isWindowVisible()
setWindowVisible(nextVisible)

if nextVisible then
local window=getWindow()
local tabMode=window and type(window.getTabMode)=="function"and window.getTabMode()or nil
local unreadKey=findLatestUnreadKey()



if unreadKey and not matchesTab(unreadKey,tabMode)then
unreadKey=nil
end

local targetKey=unreadKey or runtime.activeConversationKey
if targetKey~=nil and matchesTab(targetKey,tabMode)then
selectConversation(targetKey)
return
end
end

refreshWindow()
end

return{
toggle=toggle,
conversationMatchesTab=matchesTab,
}
end

ns.BootstrapWindowRuntimeToggleFlow=ToggleFlow

return ToggleFlow
