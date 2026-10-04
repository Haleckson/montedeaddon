local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local SecretString={}






local function rawStringCompare(value)
return value==""
end

local function isSecretString(value)
if value==nil then
return false
end
if type(value)~="string"then
return false
end
local ok=pcall(rawStringCompare,value)
return not ok
end





function SecretString.PayloadHasSecretFields(payload,detectOverride)


local detect=detectOverride or isSecretString
if detect(payload.text)then
return true
end
if detect(payload.playerName)then
return true
end
if detect(payload.guid)then
return true
end
return false
end


SecretString.IsSecretString=isSecretString

ns.GroupChatIngestSecretString=SecretString

return SecretString
