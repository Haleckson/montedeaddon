local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Factions=ns.IdentityFactions or require("WhisperMessenger.Model.Identity.Factions")

local Identity={}




function Identity.ShortName(name)
if name~=nil and type(_G.Ambiguate)=="function"then
local ok,short=pcall(_G.Ambiguate,name,"none")
if ok and short~=nil then
return short
end
end
return name
end

local function normalizeName(name)
if name==nil then
return""
end
name=Identity.ShortName(name)
local ok,result=pcall(string.lower,name)
if ok then
return result
end
return""
end

local function buildGameAccountName(accountInfo)
local gameAccountInfo=accountInfo and accountInfo.gameAccountInfo or nil
if gameAccountInfo==nil then
return nil
end

local characterName=gameAccountInfo.characterName
local realmName=gameAccountInfo.realmName or gameAccountInfo.realmDisplayName
if characterName and realmName then
return characterName.."-"..realmName
end

return characterName or realmName
end

function Identity.InferFaction(raceTag)
return Factions.InferFaction(raceTag)
end

function Identity.BuildLocalProfileId(name,realmName)
if name==nil or name==""then
return nil
end

if realmName~=nil and realmName~=""then
return normalizeName(name.."-"..realmName)
end

return normalizeName(name)
end

function Identity.FromWhisper(fullName,guid,playerInfo)
playerInfo=playerInfo or{}

fullName=Identity.ShortName(fullName)
return{
channel="WOW",
contactKey="WOW::"..normalizeName(fullName),
canonicalName=normalizeName(fullName),
displayName=fullName,
guid=guid,
className=playerInfo.className,
classTag=playerInfo.classTag,
raceName=playerInfo.raceName,
raceTag=playerInfo.raceTag,
factionName=playerInfo.factionName or Factions.InferFaction(playerInfo.raceTag),
}
end

function Identity.FromBattleNet(bnetAccountID,accountInfo,playerInfo)
local gameAccountName=buildGameAccountName(accountInfo)
local gameAccountInfo=accountInfo and accountInfo.gameAccountInfo or nil
playerInfo=playerInfo or{}

local stableKey=(accountInfo and accountInfo.battleTag)or tostring(bnetAccountID)
return{
channel="BN",
contactKey="BN::"..normalizeName(stableKey),
canonicalName=normalizeName(stableKey),
displayName=(accountInfo and(accountInfo.battleTag or accountInfo.accountName))or gameAccountName or tostring(bnetAccountID),
battleTag=accountInfo and accountInfo.battleTag or nil,
accountName=accountInfo and accountInfo.accountName or nil,
bnetAccountID=bnetAccountID,
gameAccountName=gameAccountName,
guid=gameAccountInfo and gameAccountInfo.playerGuid or nil,
className=playerInfo.className or(gameAccountInfo and gameAccountInfo.className or nil),
classTag=playerInfo.classTag or nil,
raceName=playerInfo.raceName or(gameAccountInfo and gameAccountInfo.raceName or nil),
raceTag=playerInfo.raceTag or nil,
factionName=(gameAccountInfo and gameAccountInfo.factionName)or(playerInfo.factionName or Factions.InferFaction(playerInfo.raceTag))or nil,
}
end

local function conversationDisplayName(conversation)
if type(conversation)~="table"then
return nil
end
return conversation.displayName or conversation.contactDisplayName
end

local function findUniqueConversation(conversations,channel,matches)
local matchedKey=nil
local matchCount=0

for key,conversation in pairs(conversations)do
if type(conversation)=="table"and conversation.channel==channel and matches(conversation)then
matchCount=matchCount+1
matchedKey=key
end
end

if matchCount==1 then
return matchedKey
end

return nil
end

local function normalizedValue(value)
if type(value)=="number"then
value=tostring(value)
end
if type(value)~="string"then
return""
end
return normalizeName(value)
end

function Identity.ResolveWhisperConversation(runtime,target,channel)
local store=runtime and runtime.store
local conversations=store and store.conversations
local targetCanonical=normalizedValue(target)
if type(conversations)~="table"or targetCanonical==""then
return nil
end

if channel=="WOW"then
local exactKey=findUniqueConversation(conversations,"WOW",function(conversation)
return normalizedValue(conversationDisplayName(conversation))==targetCanonical
end)
if exactKey~=nil then
return exactKey
end

if string.find(targetCanonical,"-",1,true)~=nil then
return nil
end

return findUniqueConversation(conversations,"WOW",function(conversation)
local canonicalName=normalizedValue(conversationDisplayName(conversation))
local baseName=string.match(canonicalName,"^([^%-]+)")
return baseName==targetCanonical
end)
end

if channel=="BN"then
local byAccountID=findUniqueConversation(conversations,"BN",function(conversation)
return normalizedValue(conversation.bnetAccountID)==targetCanonical
end)
if byAccountID~=nil then
return byAccountID
end

return findUniqueConversation(conversations,"BN",function(conversation)
return normalizedValue(conversation.battleTag)==targetCanonical
or normalizedValue(conversation.gameAccountName)==targetCanonical
or normalizedValue(conversationDisplayName(conversation))==targetCanonical
end)
end

return nil
end

function Identity.BuildConversationKey(localProfileId,contactKey)
if type(contactKey)~="string"then
return localProfileId.."::"..tostring(contactKey)
end


if string.find(contactKey,"BN::",1,true)==1 then
return"bnet::"..contactKey
end

if string.find(contactKey,"WOW::",1,true)==1 then
return"wow::"..contactKey
end



if string.find(contactKey,"BNCONV::",1,true)==1 then
local id=string.sub(contactKey,9)
return"bnconv::"..id
end



if string.find(contactKey,"COMMUNITY::",1,true)==1 then
local rest=string.sub(contactKey,12)
return"community::"..rest
end





if string.find(contactKey,"GUILD::",1,true)==1 then
local name=string.sub(contactKey,8)
if type(name)=="string"and name~=""then
local ok,lowered=pcall(string.lower,name)
if ok and type(lowered)=="string"and lowered~=""then
return"guild::"..lowered
end
end
return"guild::"..localProfileId
end
if string.find(contactKey,"OFFICER::",1,true)==1 then
return"officer::"..localProfileId
end
if string.find(contactKey,"PARTY::",1,true)==1 then
return"party::"..localProfileId
end
if string.find(contactKey,"RAID::",1,true)==1 then
return"raid::"..localProfileId
end
if string.find(contactKey,"INSTANCE::",1,true)==1 then
return"instance::"..localProfileId
end



if string.find(contactKey,"CHANNEL::",1,true)==1 then
local basename=string.sub(contactKey,10)
return"channel::"..localProfileId.."::"..basename
end


return localProfileId.."::"..contactKey
end

ns.Identity=Identity

return Identity
