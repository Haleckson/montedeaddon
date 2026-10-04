local addonName,ns=...
if type(ns)~="table"then
ns={}
end










local AddonComm={}

local MAX_PAYLOAD_BYTES=255

local groupChannelSet={
PARTY=true,
RAID=true,
INSTANCE_CHAT=true,
GUILD=true,
OFFICER=true,
}

local registeredPrefixes={}

local function resolveRegister(api)
if type(api)=="table"and type(api.RegisterAddonMessagePrefix)=="function"then
return api.RegisterAddonMessagePrefix
end
return nil
end

local function resolveSend(api)
if type(api)=="table"and type(api.SendAddonMessage)=="function"then
return api.SendAddonMessage
end
return nil
end

local function resolveSendBNet(api)
if type(api)=="table"and type(api.SendGameData)=="function"then
return api.SendGameData
end
if type(_G.BNSendGameData)=="function"then
return _G.BNSendGameData
end
return nil
end

local function didSendSucceed(callSucceeded,...)
if not callSucceeded then
return false
end
local count=select("#",...)
local result
if count>0 then
result=select(count,...)
end
return result==nil or result==true or result==0
end

local function didRegisterSucceed(callSucceeded,...)
if not callSucceeded then
return false
end
local count=select("#",...)
local result
if count>0 then
result=select(count,...)
end
return result==nil or result==true or result==0 or result==1
end

function AddonComm.RegisterPrefix(api,prefix)
if type(prefix)~="string"or prefix==""then
return false
end

local register=resolveRegister(api)
if register==nil then


return false
end

if registeredPrefixes[prefix]then
return true
end

local registered=didRegisterSucceed(pcall(register,prefix))
if not registered then
return false
end

registeredPrefixes[prefix]=true
return true
end

function AddonComm.Send(api,prefix,payload,target)
if type(prefix)~="string"or prefix==""then
return false
end
if type(payload)~="string"or payload==""then
return false
end
if#payload>MAX_PAYLOAD_BYTES then
return false
end
if type(target)~="string"or target==""then
return false
end

local send=resolveSend(api)
if send==nil then
return false
end

return didSendSucceed(pcall(send,prefix,payload,"WHISPER",target))
end

function AddonComm.SendGroup(api,prefix,payload,channel)
if type(prefix)~="string"or prefix==""then
return false
end
if type(payload)~="string"or payload==""then
return false
end
if#payload>MAX_PAYLOAD_BYTES then
return false
end
if groupChannelSet[channel]~=true then
return false
end

local send=resolveSend(api)
if send==nil then
return false
end

return didSendSucceed(pcall(send,prefix,payload,channel))
end

function AddonComm.SendBNet(api,prefix,payload,gameAccountID)
if type(prefix)~="string"or prefix==""then
return false
end
if type(payload)~="string"or payload==""then
return false
end
if#payload>MAX_PAYLOAD_BYTES then
return false
end
if gameAccountID==nil then
return false
end

local send=resolveSendBNet(api)
if send==nil then
return false
end

local ok=pcall(send,gameAccountID,prefix,payload)
return ok
end

AddonComm.MAX_PAYLOAD_BYTES=MAX_PAYLOAD_BYTES

ns.AddonComm=AddonComm

return AddonComm
