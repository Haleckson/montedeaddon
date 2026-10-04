local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChatReplyState=ns.ChatReplyState or(type(require)=="function"and require("WhisperMessenger.Util.ChatReplyState"))or nil
local Localization=ns.Localization or(type(require)=="function"and require("WhisperMessenger.Locale.Localization"))or nil
local function L(key)
return Localization and Localization.Text(key)or key
end

local MythicSuspendController={}
local DEFAULT_MYTHIC_PAUSE_NOTICE_KEY="Whispers are paused in Mythic content. Incoming and outgoing messages will resume after you leave."
local SUSPEND_PRINT_KEY="Suspended for mythic content. Whispers will resume when you leave."
local RESUME_PRINT_KEY="Resumed. Whispers are active again."
local R_REPLY_ADVISORY_KEY=
'/r and R-key may fail in Mythic while "Hide whispers from default chat" is on. Use |cffffff00/wr|r to reply (or bind it to R via macro).'

function MythicSuspendController.Attach(runtime,deps)
deps=deps or{}

local Bootstrap=deps.Bootstrap or{}
local isWindowVisible=deps.isWindowVisible or function()
return false
end
local setWindowVisible=deps.setWindowVisible or function(...)
local _=...
end
local refreshWindow=deps.refreshWindow or function(...)
local _=...
end
local getNumChatWindows=deps.getNumChatWindows
local getEditBox=deps.getEditBox

runtime.suspend=function()
runtime.messagingNotice=deps.mythicPauseNotice or L(DEFAULT_MYTHIC_PAUSE_NOTICE_KEY)
Bootstrap._wasVisibleBeforeMythic=isWindowVisible()
setWindowVisible(false)
if Bootstrap.unregisterChatFilters then
Bootstrap.unregisterChatFilters()
end




local EventBridge=deps.getEventBridge and deps.getEventBridge()or ns.BootstrapEventBridge
if EventBridge and Bootstrap._loadFrame then
EventBridge.UnregisterLiveEvents(Bootstrap._loadFrame)
EventBridge.UnregisterSuspendableLifecycleEvents(Bootstrap._loadFrame)
end


_G._wmSuspended=true




if runtime.syncReplyKey then
runtime.syncReplyKey()
end

local printFn=deps.print or _G.print
if type(printFn)=="function"then
printFn("|cff888888[WhisperMessenger]|r "..L(SUSPEND_PRINT_KEY))
local settings=runtime.accountState and runtime.accountState.settings
if settings and settings.hideFromDefaultChat==true then
printFn("|cff888888[WhisperMessenger]|r "..L(R_REPLY_ADVISORY_KEY))
end
end
end

runtime.resume=function()
runtime.messagingNotice=nil
_G._wmSuspended=nil
local printFn=deps.print or _G.print
if type(printFn)=="function"then
printFn("|cff888888[WhisperMessenger]|r "..L(RESUME_PRINT_KEY))
end












runtime.lastIncomingWhisperKey=nil




local staleReplyResolved=true
if ChatReplyState and ChatReplyState.CaptureStaleWhisperReplyTarget then
local _,resolved=ChatReplyState.CaptureStaleWhisperReplyTarget(runtime,getNumChatWindows,getEditBox)
staleReplyResolved=resolved~=false
end







if staleReplyResolved and ChatReplyState and ChatReplyState.ClearStaleWhisperReplyState then
ChatReplyState.ClearStaleWhisperReplyState(getNumChatWindows,getEditBox)
end

local EventBridge=deps.getEventBridge and deps.getEventBridge()or ns.BootstrapEventBridge
if EventBridge and Bootstrap._loadFrame then
EventBridge.RegisterLiveEvents(Bootstrap._loadFrame)
EventBridge.RegisterSuspendableLifecycleEvents(Bootstrap._loadFrame)
end

if Bootstrap.syncChatFilters then
Bootstrap.syncChatFilters()
elseif Bootstrap.registerChatFilters then
Bootstrap.registerChatFilters()
end


if runtime.syncReplyKey then
runtime.syncReplyKey()
end
if
Bootstrap._wasVisibleBeforeMythic
and not(runtime.accountState and runtime.accountState.settings and runtime.accountState.settings.hideOnCombat==true)
then
setWindowVisible(true)
end
refreshWindow()
Bootstrap._wasVisibleBeforeMythic=nil
end

return runtime
end

ns.BootstrapMythicSuspendController=MythicSuspendController
return MythicSuspendController
