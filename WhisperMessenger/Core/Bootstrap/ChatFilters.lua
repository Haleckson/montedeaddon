local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ChatFilters={}







local function secureCallBlizzard(fn,...)
local sc=_G.securecall
if type(sc)=="function"then
return sc(fn,...)
end
return fn(...)
end

function ChatFilters.Configure(Bootstrap,accountState)






Bootstrap._whisperFilter=function()
return true
end

Bootstrap._bnWhisperFilter=function()
return true
end

Bootstrap._filtersRegistered=false

Bootstrap.registerChatFilters=function()
if Bootstrap._filtersRegistered or type(_G.ChatFrame_AddMessageEventFilter)~="function"then
return
end

local addFilter=_G.ChatFrame_AddMessageEventFilter
secureCallBlizzard(addFilter,"CHAT_MSG_WHISPER",Bootstrap._whisperFilter)
secureCallBlizzard(addFilter,"CHAT_MSG_WHISPER_INFORM",Bootstrap._whisperFilter)
secureCallBlizzard(addFilter,"CHAT_MSG_BN_WHISPER",Bootstrap._bnWhisperFilter)
secureCallBlizzard(addFilter,"CHAT_MSG_BN_WHISPER_INFORM",Bootstrap._bnWhisperFilter)
Bootstrap._filtersRegistered=true
end

Bootstrap.unregisterChatFilters=function()
if not Bootstrap._filtersRegistered then
return
end

if type(_G.ChatFrame_RemoveMessageEventFilter)=="function"then
local removeFilter=_G.ChatFrame_RemoveMessageEventFilter
secureCallBlizzard(removeFilter,"CHAT_MSG_WHISPER",Bootstrap._whisperFilter)
secureCallBlizzard(removeFilter,"CHAT_MSG_WHISPER_INFORM",Bootstrap._whisperFilter)
secureCallBlizzard(removeFilter,"CHAT_MSG_BN_WHISPER",Bootstrap._bnWhisperFilter)
secureCallBlizzard(removeFilter,"CHAT_MSG_BN_WHISPER_INFORM",Bootstrap._bnWhisperFilter)
end

Bootstrap._filtersRegistered=false
end

Bootstrap.syncChatFilters=function()
local shouldFilter=accountState.settings.hideFromDefaultChat==true
and not Bootstrap._inCompetitiveContent
and not Bootstrap._inMythicContent
and not Bootstrap._inEncounter
and not _G._wmSuspended

if shouldFilter and not Bootstrap._filtersRegistered then
Bootstrap.registerChatFilters()
elseif not shouldFilter and Bootstrap._filtersRegistered then
Bootstrap.unregisterChatFilters()
end
end
end

ns.BootstrapChatFilters=ChatFilters
return ChatFilters
