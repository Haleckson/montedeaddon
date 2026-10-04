local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local WoWStatus=ns.ContactEnricherWoWStatus or require("WhisperMessenger.Model.ContactEnricher.WoWStatus")
local BNetStatus=ns.ContactEnricherBNetStatus or require("WhisperMessenger.Model.ContactEnricher.BNetStatus")
local OnlineWatch=ns.OnlineWatch or require("WhisperMessenger.Model.OnlineWatch")
local Store=ns.ConversationStore or require("WhisperMessenger.Model.ConversationStore")

local AvailabilityEnricher={}



local function isOppositeFaction(itemFaction,localFaction)
if localFaction==nil or itemFaction==nil or itemFaction==""then
return false
end
return itemFaction~=localFaction
end


AvailabilityEnricher.isOppositeFaction=isOppositeFaction

function AvailabilityEnricher.ShouldRequestAvailability(_cached)




return true
end


local ONLINE_STATUSES={CanWhisper=true,XFaction=true,Away=true,Busy=true,BNetOnline=true}



local function isProvenOnline(item,runtime)
if not ONLINE_STATUSES[item.availability and item.availability.status]then
return false
end
if item.channel=="BN"then
return true
end
local cached=item.guid and runtime.availabilityByGUID[item.guid]
return cached~=nil and cached.canWhisper==true
end



local function stampLastSeen(item,runtime)
if not isProvenOnline(item,runtime)then
return
end
OnlineWatch.StampSeen(runtime,Store.Find(runtime.store,item.conversationKey))
end

function AvailabilityEnricher.EnrichContactsAvailability(contacts,runtime)
local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")
for _,item in ipairs(contacts)do
if item.guid and runtime.availabilityByGUID[item.guid]then
WoWStatus.ApplyCached(item,runtime)
elseif item.guid and item.channel~="BN"then
WoWStatus.ApplyPresenceFallback(item,runtime)
end
if item.guid and item.channel~="BN"then
WoWStatus.ApplyZone(item)
end

if item.availability==nil and item.channel~="BN"then
item.availability=Availability.FromStatus("Offline")
end

if item.channel=="BN"and item.bnetAccountID then
BNetStatus.Apply(item,runtime)
end
stampLastSeen(item,runtime)
end
end

ns.AvailabilityEnricher=AvailabilityEnricher
return AvailabilityEnricher
