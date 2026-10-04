local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local BNetIdentity=ns.BNetIdentity or require("WhisperMessenger.Core.BNetIdentity")
local Direction={}

local function rawGuidEqual(a,b)
return a==b
end

local function compareGuids(a,b)
if a==nil or b==nil then
return false
end
local ok,equal=pcall(rawGuidEqual,a,b)
return ok and equal==true
end





local function resolveLocalPlayerGuid(state)
if type(state.localPlayerGuid)=="string"and state.localPlayerGuid~=""then
return state.localPlayerGuid
end
if type(_G.UnitGUID)=="function"then
local ok,guid=pcall(_G.UnitGUID,"player")
if ok and type(guid)=="string"and guid~=""then
state.localPlayerGuid=guid
return guid
end
end
return nil
end

local function resolveLocalBnetAccountID(state)
local accountID=BNetIdentity.ResolveLocalAccountID(state.localBnetAccountID,state.getBNetInfo or _G.BNGetInfo)
if accountID~=nil then
state.localBnetAccountID=accountID
end
return accountID
end



function Direction.Resolve(eventName,payload,state)
if eventName=="CHAT_MSG_BN_CONVERSATION"then


local localBnetAccountID=resolveLocalBnetAccountID(state)
if localBnetAccountID~=nil and payload.bnSenderID==localBnetAccountID then
return"out"
end
return"in"
end


local localGuid=resolveLocalPlayerGuid(state)
if compareGuids(payload.guid,localGuid)then
return"out"
end
return"in"
end



function Direction.CompareGuids(a,b)
return compareGuids(a,b)
end

ns.GroupChatIngestDirection=Direction

return Direction
