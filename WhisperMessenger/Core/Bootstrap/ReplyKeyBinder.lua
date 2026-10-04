local addonName,ns=...
if type(ns)~="table"then
ns={}
end










local ReplyKeyBinder={}

local BUTTON_NAME="WhisperMessengerReplyButton"

local function defaultGetBindingKey(action)
if type(_G.GetBindingKey)=="function"then
return _G.GetBindingKey(action)
end
return nil
end



local function collectReplyKeys(getBindingKey)
local keys={}
if type(getBindingKey)~="function"then
return keys
end
local raw={getBindingKey("REPLY")}
for i=1,#raw do
local key=raw[i]
if type(key)=="string"and key~=""then
table.insert(keys,key)
end
end
return keys
end

local function keysEqual(a,b)
if#a~=#b then
return false
end
for i=1,#a do
if a[i]~=b[i]then
return false
end
end
return true
end

function ReplyKeyBinder.New(deps)
deps=deps or{}
local createFrame=deps.createFrame or _G.CreateFrame
local setOverrideBindingClick=deps.setOverrideBindingClick or _G.SetOverrideBindingClick
local clearOverrideBindings=deps.clearOverrideBindings or _G.ClearOverrideBindings
local uiParent=deps.uiParent or _G.UIParent
local getBindingKey=deps.getBindingKey or defaultGetBindingKey
local getSettings=deps.getSettings or function()
return{}
end

local button
local boundKeys={}

local function ensureButton()
if button then
return button
end
if type(createFrame)~="function"then
return nil
end
button=createFrame("Button",BUTTON_NAME,uiParent,"SecureActionButtonTemplate")
if button and button.SetAttribute then
button:SetAttribute("type","macro")
button:SetAttribute("macrotext","/wr")
end






if button and button.RegisterForClicks then
button:RegisterForClicks("AnyDown")
end
return button
end

local self={}

local function clearCurrentBindings()
if#boundKeys==0 then
return
end
if button and type(clearOverrideBindings)=="function"then
clearOverrideBindings(button)
end
boundKeys={}
end

function self.bind()
local btn=ensureButton()
if not btn or type(setOverrideBindingClick)~="function"then
return
end

local desiredKeys=collectReplyKeys(getBindingKey)



if keysEqual(desiredKeys,boundKeys)then
return
end



clearCurrentBindings()



if#desiredKeys==0 then
return
end

for _,key in ipairs(desiredKeys)do
setOverrideBindingClick(btn,true,key,BUTTON_NAME)
end
boundKeys=desiredKeys
end

function self.unbind()
clearCurrentBindings()
end

function self.sync()
local settings=getSettings()or{}





if settings.hideFromDefaultChat==true then
self.bind()
else
self.unbind()
end
end

return self
end

ns.BootstrapReplyKeyBinder=ReplyKeyBinder
return ReplyKeyBinder
