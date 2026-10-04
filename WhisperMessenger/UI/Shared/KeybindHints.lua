local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local PickerStyles=ns.PickerStyles or require("WhisperMessenger.UI.Shared.PickerStyles")



local KeybindHints={}

local HINT_GREY=PickerStyles.HINT_GREY


local function keyNames(...)
local names={}
for i=1,select("#",...)do
local key=select(i,...)
if type(key)=="string"and key~=""then
names[#names+1]=type(_G.GetBindingText)=="function"and _G.GetBindingText(key)or key
end
end
return names
end

local function addHint(tooltip,labelKey,action)
local names=keyNames(_G.GetBindingKey(action))
if#names==0 then
return
end
local text=string.format(Localization.Text(labelKey),table.concat(names,", "))
tooltip:AddLine(text,HINT_GREY,HINT_GREY,HINT_GREY)
end



function KeybindHints.AddToTooltip(tooltip,includeReply)
if tooltip==nil or type(tooltip.AddLine)~="function"or type(_G.GetBindingKey)~="function"then
return
end
addHint(tooltip,"Open/close: %s","WHISPERMESSENGER_TOGGLE")
if includeReply then
addHint(tooltip,"Reply: %s","REPLY")
end
end

ns.KeybindHints=KeybindHints
return KeybindHints
