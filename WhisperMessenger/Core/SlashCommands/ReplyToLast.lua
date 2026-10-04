local addonName,ns=...
if type(ns)~="table"then
ns={}
end















local ReplyToLast={}

local function isWhisperConversation(conv)
if type(conv)~="table"then
return false
end
local channel=conv.channel


if channel==nil then
return true
end
return channel=="WOW"or channel=="BN"or channel=="WHISPER"or channel=="BN_WHISPER"
end

function ReplyToLast.Create(deps)
local runtime=deps.runtime
local windowRuntime=deps.windowRuntime

local function focusComposerInput()
local window=runtime.window
local input=window and window.composer and window.composer.input
if not(input and input.SetFocus)then
return
end

input:SetFocus()

local timer=_G.C_Timer
if type(timer)=="table"and type(timer.After)=="function"then
timer.After(0,function()
if input and input.SetFocus then
input:SetFocus()
end
end)
end
end

return function()
local function scrubLeakedR()
local timer=_G.C_Timer
if type(timer)~="table"or type(timer.After)~="function"then
return
end
local function doScrub()
local window=runtime.window
local input=window and window.composer and window.composer.input
if input and input.GetText and input.SetText then
local text=input:GetText()or""
if text=="r"or text=="R"then
input:SetText("")
end
end
end




timer.After(0,function()
timer.After(0,doScrub)
end)
end

local hooks=runtime.autoOpenHooks
if hooks and hooks.onReplyTell and hooks.onReplyTell()==true then
scrubLeakedR()
return
end

local key=runtime.lastIncomingWhisperKey
if not key and runtime.store and runtime.store.conversations then



local latest=-1
for k,conv in pairs(runtime.store.conversations)do
if isWhisperConversation(conv)then
local activity=conv and conv.lastActivityAt or 0
if activity>latest then
latest=activity
key=k
end
end
end
end

if key and runtime.ensureWindow and runtime.setWindowVisible then
runtime.ensureWindow()
runtime.setWindowVisible(true)


local window=runtime.window
if window and type(window.setTabMode)=="function"then
window.setTabMode("whispers")
end
if windowRuntime.selectConversation then
windowRuntime.selectConversation(key)
end
focusComposerInput()
scrubLeakedR()
return
end

if runtime.toggle then
runtime.toggle()
end
end
end

ns.SlashCommandsReplyToLast=ReplyToLast
return ReplyToLast
