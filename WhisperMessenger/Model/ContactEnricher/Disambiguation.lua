local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local PresenceCache=ns.PresenceCache or require("WhisperMessenger.Model.PresenceCache")

local Disambiguation={}




















function Disambiguation.ResolveWrongFaction(item,runtime,isOpposite)
local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")

local presence=PresenceCache.GetPresence(item.guid)

if isOpposite then

if presence=="online"then
return Availability.FromStatus("XFaction")
elseif presence=="offline"then
return Availability.FromStatus("Offline")
else
return Availability.FromStatus("WrongFaction")
end
end






if presence=="online"then
return Availability.FromStatus("CanWhisper")
elseif presence=="offline"then
return Availability.FromStatus("Offline")
end


local function findBNetFriendByGUID(guid,bnetApi)
if guid==nil or type(bnetApi)~="table"then
return nil
end
if type(bnetApi.GetAccountInfoByGUID)=="function"then
local ok,info=pcall(bnetApi.GetAccountInfoByGUID,guid)
if ok and info and(info.isOnline or info.isAFK or info.isDND)then
return info
end
end
return nil
end
local bnetInfo=findBNetFriendByGUID(item.guid,runtime.bnetApi)
if bnetInfo then
local bnetStatus="CanWhisper"
if bnetInfo.isAFK then
bnetStatus="Away"
elseif bnetInfo.isDND then
bnetStatus="Busy"
end
return Availability.FromStatus(bnetStatus)
end


local function isGroupMemberOnline(displayName)
if displayName==nil then
return false
end
local UnitIsConnected=_G["UnitIsConnected"]
local UnitName=_G["UnitName"]
local GetNumGroupMembers=_G["GetNumGroupMembers"]
if type(UnitIsConnected)~="function"or type(UnitName)~="function"then
return false
end
local numMembers=type(GetNumGroupMembers)=="function"and GetNumGroupMembers()or 0
if numMembers==0 then
return false
end

local targetName=string.lower(string.match(displayName,"^([^%-]+)")or displayName)
local IsInRaid=_G["IsInRaid"]
local prefix=(type(IsInRaid)=="function"and IsInRaid())and"raid"or"party"
for i=1,numMembers do
local unit=prefix..i
local name=UnitName(unit)
if name and string.lower(name)==targetName then
return UnitIsConnected(unit)==true
end
end
return false
end
if isGroupMemberOnline(item.displayName or item.playerName)then
return Availability.FromStatus("CanWhisper")
end




return Availability.FromStatus("CanWhisper")
end

ns.ContactEnricherDisambiguation=Disambiguation
return Disambiguation
