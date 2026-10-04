local addonName,ns=...
if type(ns)~="table"then
ns={}
end


local ConversationOps=ns.BootstrapAutoOpenConversationOps or require("WhisperMessenger.Core.Bootstrap.AutoOpenCoordinator.ConversationOps")
local EditBoxInterop=ns.BootstrapAutoOpenEditBoxInterop or require("WhisperMessenger.Core.Bootstrap.AutoOpenCoordinator.EditBoxInterop")


local DirectHooks={}






function DirectHooks.shouldInterceptHook(runtime,deps)
if deps.isSuspended()then
return false
end





local isCompetitive=runtime.isCompetitiveContent and runtime.isCompetitiveContent()
local isVisible=deps.isWindowVisible and deps.isWindowVisible()or false

if isCompetitive then
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

function DirectHooks.Install(runtime,hooks,deps)
if type(_G.hooksecurefunc)~="function"then
return
end

local function handleWhisperHook(nameArg)
if not DirectHooks.shouldInterceptHook(runtime,deps)then
return
end








local isReplyHook=type(nameArg)~="string"or nameArg==""
local target=(not isReplyHook)and nameArg or nil
local hasExplicitSendTellTarget=target~=nil

local editBox
if type(_G.ChatEdit_GetActiveWindow)=="function"then
local ok,active=pcall(_G.ChatEdit_GetActiveWindow)
if ok then
editBox=active
end
end
if not editBox then
editBox=EditBoxInterop.findFocusedEditBox(deps)
end

local chatType
if editBox then
if deps.isInCombat and deps.isInCombat()then
EditBoxInterop.markCombatDraft(editBox)
end
if EditBoxInterop.shouldPreserveCombatDraft(editBox)then
return
end
chatType=EditBoxInterop.readEditBoxState(editBox,"chatType")
if not isReplyHook and not target then
target=EditBoxInterop.readEditBoxState(editBox,"tellTarget")
end
end

local opened=false
if isReplyHook then
if type(hooks.onReplyTell)=="function"then
opened=hooks.onReplyTell()==true
else
return
end
elseif not target or target==""then
return
elseif chatType=="BN_WHISPER"and not hasExplicitSendTellTarget then
pcall(function()
local accountInfo=EditBoxInterop.findBattleNetAccountInfo(target,deps.bnetApi,deps.getNumFriends)
if not accountInfo then
return
end
local conversationKey=ConversationOps.ensureBattleNetConversation(runtime,deps.identity,accountInfo)
if conversationKey and hooks.onOutgoingWhisper(conversationKey)then
opened=true
end
end)
else

opened=hooks.onSendTell(target)==true
end

if opened and editBox then



local timer=_G.C_Timer
if type(timer)=="table"and type(timer.After)=="function"then
timer.After(0,function()



if runtime.isCompetitiveContent and runtime.isCompetitiveContent()then
return
end
EditBoxInterop.closeEditBox(runtime,editBox,deps.deactivateChat)
end)
end
end
end

local function safeHook(name)
if type(_G[name])=="function"then
pcall(_G.hooksecurefunc,name,handleWhisperHook)
end
end








safeHook("ChatFrame_SendTell")
end

ns.BootstrapAutoOpenDirectHooks=DirectHooks
return DirectHooks
