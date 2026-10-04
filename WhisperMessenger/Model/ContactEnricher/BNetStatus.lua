local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local BNetStatus={}




function BNetStatus.IsInWoW(gameInfo)
return gameInfo~=nil and type(gameInfo.characterName)=="string"and gameInfo.characterName~=""
end




function BNetStatus.IsOnline(accountInfo)
if type(accountInfo)~="table"then
return nil
end
local gameInfo=accountInfo.gameAccountInfo
local gameOnline=gameInfo and gameInfo.isOnline
if accountInfo.isOnline==true or gameOnline==true or BNetStatus.IsInWoW(gameInfo)then
return true
end
if accountInfo.isOnline==false or gameOnline==false then
return false
end
return nil
end





function BNetStatus.ApplyGameInfoMetadata(target,gameInfo,runtime)
if not BNetStatus.IsInWoW(gameInfo)then
return false
end
if gameInfo.factionName and gameInfo.factionName~=""then
target.factionName=gameInfo.factionName
end
if gameInfo.raceName and gameInfo.raceName~=""then
target.raceName=gameInfo.raceName
end
if gameInfo.areaName and gameInfo.areaName~=""then
target.areaName=gameInfo.areaName
end
local guid=gameInfo.playerGuid or target.guid
local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")
local playerInfo=guid and BNetResolver.ResolvePlayerInfo(runtime.playerInfoByGUID,guid)
if playerInfo and playerInfo.classTag then
target.classTag=playerInfo.classTag
target.className=(gameInfo.className~=nil and gameInfo.className~="")and gameInfo.className or playerInfo.className or target.className
if playerInfo.raceTag then
target.raceTag=playerInfo.raceTag
end
end


return true
end






function BNetStatus.Apply(item,runtime)
local BNetResolver=ns.BNetResolver or require("WhisperMessenger.Transport.BNetResolver")
local Availability=ns.Availability or require("WhisperMessenger.Transport.Availability")
local PresenceCache=ns.PresenceCache or require("WhisperMessenger.Model.PresenceCache")

local accountInfo=BNetResolver.ResolveAccountInfo(runtime.bnetApi,item.bnetAccountID,item.guid,item.battleTag or item.displayName)
if accountInfo then
if accountInfo.bnetAccountID then
item.bnetAccountID=accountInfo.bnetAccountID
if runtime.store and runtime.store.conversations and item.conversationKey then
local conversation=runtime.store.conversations[item.conversationKey]
if conversation then
conversation.bnetAccountID=item.bnetAccountID
end
end
end
local gameInfo=accountInfo.gameAccountInfo




local inWoW=BNetStatus.IsInWoW(gameInfo)
local isOnline=BNetStatus.IsOnline(accountInfo)

item.lastOnlineTime=not isOnline and tonumber(accountInfo.lastOnlineTime)or nil
if isOnline then

local bnetStatus
if accountInfo.isAFK or(gameInfo and gameInfo.isGameAFK)then
bnetStatus="Away"
elseif accountInfo.isDND or(gameInfo and gameInfo.isGameBusy)then
bnetStatus="Busy"
elseif not inWoW then

bnetStatus="BNetOnline"
else
bnetStatus="CanWhisper"
end
item.availability=Availability.FromStatus(bnetStatus)


BNetStatus.ApplyGameInfoMetadata(item,gameInfo,runtime)
elseif isOnline==false then

local presence=item.guid and PresenceCache.GetPresence(item.guid)or nil
if presence=="online"then

item.availability=Availability.FromStatus("CanWhisper")
else
item.availability=Availability.FromStatus("Offline")
end
elseif accountInfo.isOnline==nil then


local presence=item.guid and PresenceCache.GetPresence(item.guid)or nil
if presence=="online"then

item.availability=Availability.FromStatus("CanWhisper")
elseif presence=="offline"then


item.availability=Availability.FromStatus("Offline")
else

item.availability=Availability.FromStatus("BNetOnline")
end
end
end



if item.availability==nil then
local presence=item.guid and PresenceCache.GetPresence(item.guid)or nil
if presence=="online"then
item.availability=Availability.FromStatus("CanWhisper")
else
item.availability=Availability.FromStatus("Offline")
end
end
end

ns.ContactEnricherBNetStatus=BNetStatus
return BNetStatus
