local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local PresenceCache=ns.PresenceCache or require("WhisperMessenger.Model.PresenceCache")

local WoWStatus={}




local function isOppositeFaction(itemFaction,localFaction)
if localFaction==nil or itemFaction==nil or itemFaction==""then
return false
end
return itemFaction~=localFaction
end





function WoWStatus.ApplyCached(item,runtime)
local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")
local Disambiguation=ns.ContactEnricherDisambiguation or require("WhisperMessenger.Model.ContactEnricher.Disambiguation")
local localFaction=runtime.localFaction

item.availability=runtime.availabilityByGUID[item.guid]






if item.factionName==nil and localFaction and item.channel~="BN"and item.availability.status=="CanWhisper"then
item.factionName=localFaction

if runtime.store and item.conversationKey then
local conversation=runtime.store.conversations[item.conversationKey]
if conversation and conversation.factionName==nil then
conversation.factionName=item.factionName
end
end
end

if isOppositeFaction(item.factionName,localFaction)then
if item.availability.status=="CanWhisper"then

item.availability=Availability.FromStatus("XFaction")
elseif item.availability.status=="WrongFaction"or item.availability.status=="Offline"then


item.availability=Disambiguation.ResolveWrongFaction(item,runtime,true)
end
else



if item.availability.status=="WrongFaction"then
item.availability=Disambiguation.ResolveWrongFaction(item,runtime,false)
end
end
end




function WoWStatus.ApplyPresenceFallback(item,runtime)
local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")
local localFaction=runtime.localFaction


local presence=PresenceCache.GetPresence(item.guid)
if presence=="online"then
if isOppositeFaction(item.factionName,localFaction)then
item.availability=Availability.FromStatus("XFaction")
else
item.availability=Availability.FromStatus("CanWhisper")
end
elseif presence=="offline"then
item.availability=Availability.FromStatus("Offline")
end
end


function WoWStatus.ApplyZone(item)
if PresenceCache.GetPresence(item.guid)=="online"then
item.areaName=PresenceCache.GetZone(item.guid)
else
item.areaName=nil
end
end

ns.ContactEnricherWoWStatus=WoWStatus
return WoWStatus
