local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local AutoOpenHooks={}

function AutoOpenHooks.Create(deps)
local hooks={}

local function shouldRouteToMessenger()



local isVisible=deps.isWindowVisible and deps.isWindowVisible()==true

if deps.isCompetitive and deps.isCompetitive()and not isVisible then
return false
end

if deps.isInCombat and deps.isInCombat()then
if isVisible then
return true
end
return false
end
return true
end

local function shouldRouteOutgoingToMessenger()
if not shouldRouteToMessenger()then
return false
end

local settings=deps.getSettings and deps.getSettings()or{}
local isVisible=deps.isWindowVisible and deps.isWindowVisible()==true
if settings.autoOpenOutgoing~=true and not isVisible then
return false
end

return true
end

local function openAndSelect(conversationKey,forceFocus)
deps.ensureWindow()
deps.setWindowVisible(true)






if deps.setTabMode then
deps.setTabMode("whispers")
end
deps.selectConversation(conversationKey)
if forceFocus then
deps.focusComposer()
end
end

function hooks.onIncomingWhisper(conversationKey)
if not conversationKey then
return
end


local isVisible=deps.isWindowVisible and deps.isWindowVisible()
local activeKey=deps.getActiveConversationKey and deps.getActiveConversationKey()
if isVisible and activeKey then
return
end
openAndSelect(conversationKey,false)
end

function hooks.onReplyTell()
if not shouldRouteToMessenger()then
return false
end

local conversationKey=deps.getLastReplyKey and deps.getLastReplyKey()
if not conversationKey then
return false
end
openAndSelect(conversationKey,true)
return true
end

function hooks.onSendTell(playerName)
if not shouldRouteOutgoingToMessenger()then
return false
end
if not playerName then
return false
end
local conversationKey=deps.findConversationKeyByName(playerName)
if not conversationKey and deps.buildConversationKeyFromName then
conversationKey=deps.buildConversationKeyFromName(playerName)
end
if not conversationKey then
return false
end

if deps.ensureConversation then
deps.ensureConversation(conversationKey,playerName)
end
openAndSelect(conversationKey,true)
return true
end

function hooks.onOutgoingWhisper(conversationKey)
if not shouldRouteOutgoingToMessenger()then
return false
end
if not conversationKey then
return false
end
openAndSelect(conversationKey,true)
return true
end

return hooks
end

ns.BootstrapAutoOpenHooks=AutoOpenHooks
return AutoOpenHooks
