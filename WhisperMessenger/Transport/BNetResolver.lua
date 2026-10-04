local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Types=ns.TransportTypes or require("WhisperMessenger.Transport.Types")
local BNetResolver={}








local function lookupByAccountId(bnetApi,bnetAccountID,_guid,expectedBattleTag)
if type(bnetApi.GetAccountInfoByID)~="function"then
return nil,false
end
local ok,info=pcall(bnetApi.GetAccountInfoByID,bnetAccountID)
if not ok or not info then
return nil,false
end

if expectedBattleTag and info.battleTag and info.battleTag~=expectedBattleTag then
return nil,true
end



local gameInfo=info.gameAccountInfo
if
info.isOnline==nil
and gameInfo
and gameInfo.isOnline==true
and type(gameInfo.characterName)=="string"
and gameInfo.characterName~=""
then
info.isOnline=true
end
return info,false
end

local function resolveGetNumFriends(bnetApi)
if type(bnetApi.GetNumFriends)=="function"then
return bnetApi.GetNumFriends
end
if type(_G.BNGetNumFriends)=="function"then
return _G.BNGetNumFriends
end
end

function BNetResolver.SanitizeAccountID(value)
local issecretvalue=_G.issecretvalue
if type(issecretvalue)=="function"then
local ok,isSecret=pcall(issecretvalue,value)
if not ok or isSecret then
return nil
end
end
if value==nil then
return nil
end
return value
end

function BNetResolver.ResolveAccountInfoByGameAccountID(bnetApi,gameAccountID)
if type(bnetApi)~="table"then
return nil
end
gameAccountID=BNetResolver.SanitizeAccountID(gameAccountID)
if gameAccountID==nil or type(bnetApi.GetGameAccountInfoByID)~="function"then
return nil
end

local gameCallSucceeded,gameAccountInfo=pcall(bnetApi.GetGameAccountInfoByID,gameAccountID)
if not gameCallSucceeded or type(gameAccountInfo)~="table"then
return nil
end

local playerGuid=BNetResolver.SanitizeAccountID(gameAccountInfo.playerGuid)
if playerGuid==nil or type(bnetApi.GetAccountInfoByGUID)~="function"then
return nil
end

local accountCallSucceeded,accountInfo=pcall(bnetApi.GetAccountInfoByGUID,playerGuid)
if not accountCallSucceeded or type(accountInfo)~="table"then
return nil
end

local bnetAccountID=BNetResolver.SanitizeAccountID(accountInfo.bnetAccountID)
if bnetAccountID==nil then
return nil
end
accountInfo.bnetAccountID=bnetAccountID
return accountInfo
end



local function scanFriendListById(bnetApi,bnetAccountID)
local getNumFriends=resolveGetNumFriends(bnetApi)
if type(getNumFriends)~="function"or type(bnetApi.GetFriendAccountInfo)~="function"then
return nil,nil
end
local ok,numFriends=pcall(getNumFriends)
if not ok or not numFriends then
return nil,nil
end
for i=1,numFriends do
local ok2,info=pcall(bnetApi.GetFriendAccountInfo,i)
if ok2 and info then
local candidate=BNetResolver.SanitizeAccountID(info.bnetAccountID)
if candidate~=nil and candidate==bnetAccountID then
if info.isOnline~=nil then
return info,i
end
return info,i
end
end
end
return nil,nil
end





local function pickGameAccount(bnetApi,friendIndex,numAccounts)
local fallback
for j=1,numAccounts do
local ok,gameInfo=pcall(bnetApi.GetFriendGameAccountInfo,friendIndex,j)
if ok and gameInfo then
if gameInfo.characterName and gameInfo.characterName~=""then
return gameInfo
end
if not fallback and gameInfo.isOnline then
fallback=gameInfo
end
end
end
return fallback
end




local function probeGameAccounts(bnetApi,friendIndex,accountInfo)
if
not friendIndex
or not accountInfo
or accountInfo.isOnline~=nil
or type(bnetApi.GetFriendNumGameAccounts)~="function"
or type(bnetApi.GetFriendGameAccountInfo)~="function"
then
return nil
end
local ok,numAccounts=pcall(bnetApi.GetFriendNumGameAccounts,friendIndex)
if not ok or not numAccounts or numAccounts<=0 then
return nil
end
local picked=pickGameAccount(bnetApi,friendIndex,numAccounts)
if not picked then
return nil
end
accountInfo.isOnline=true
local existing=accountInfo.gameAccountInfo
local existingHasCharacter=existing and existing.characterName and existing.characterName~=""
local pickedHasCharacter=picked.characterName and picked.characterName~=""
if not(existingHasCharacter and not pickedHasCharacter)then
accountInfo.gameAccountInfo=picked
end
return accountInfo
end







local function resolveByGUID(bnetApi,guid,accountInfo,isStaleId)
if not guid or type(bnetApi.GetAccountInfoByGUID)~="function"then
return nil
end


if isStaleId and accountInfo==nil then
local ok,info=pcall(bnetApi.GetAccountInfoByGUID,guid)
if ok and info then
return info
end
return nil
end


if not accountInfo or accountInfo.isOnline~=nil then
return nil
end

local ok,info=pcall(bnetApi.GetAccountInfoByGUID,guid)
if not ok or not info then
return nil
end

local isDifferentPerson=info.battleTag and accountInfo.battleTag and info.battleTag~=accountInfo.battleTag

if isDifferentPerson then



local gameInfo=info.gameAccountInfo
if info.isOnline==true or(gameInfo and(gameInfo.isOnline or gameInfo.characterName))then
return info
end
return nil
else

local gameInfo=info.gameAccountInfo
if info.isOnline or(gameInfo and(gameInfo.isOnline or gameInfo.characterName))then
if gameInfo then
accountInfo.gameAccountInfo=gameInfo
end
accountInfo.isOnline=info.isOnline

if accountInfo.isOnline==nil and gameInfo and(gameInfo.isOnline or gameInfo.characterName)then
accountInfo.isOnline=true
end

if info.isAFK then
accountInfo.isAFK=true
end
if info.isDND then
accountInfo.isDND=true
end
return accountInfo
end
return nil
end
end

function BNetResolver.ResolveFriendByBattleTag(bnetApi,battleTag,guid)
local getNumFriends=resolveGetNumFriends(bnetApi)
if type(getNumFriends)~="function"or type(bnetApi.GetFriendAccountInfo)~="function"then
return nil
end
local ok,numFriends=pcall(getNumFriends)
if not ok or not numFriends then
return nil
end
local friendIndex
local accountInfo
for i=1,numFriends do
local ok2,info=pcall(bnetApi.GetFriendAccountInfo,i)
if ok2 and info and info.battleTag==battleTag then
if info.isOnline~=nil then
return info
end
accountInfo=info
friendIndex=i
break
end
end

local enriched=probeGameAccounts(bnetApi,friendIndex,accountInfo)
if enriched then
return enriched
end

if guid and type(bnetApi.GetAccountInfoByGUID)=="function"then
local ok2,info=pcall(bnetApi.GetAccountInfoByGUID,guid)
if ok2 and info and info.battleTag==battleTag then

local gameInfo=info.gameAccountInfo
if info.isOnline==true or(gameInfo and(gameInfo.isOnline or gameInfo.characterName))then
return info
end
end
end
return accountInfo
end

function BNetResolver.ResolveAccountInfo(bnetApi,bnetAccountID,guid,expectedBattleTag)
if bnetApi==nil then
return nil
end
bnetAccountID=BNetResolver.SanitizeAccountID(bnetAccountID)
if bnetAccountID==nil then
return nil
end


local accountInfo,isStaleId=lookupByAccountId(bnetApi,bnetAccountID,guid,expectedBattleTag)
if accountInfo and accountInfo.isOnline~=nil and not isStaleId then
return accountInfo
end


if expectedBattleTag and(isStaleId or accountInfo==nil)then
local resolved=BNetResolver.ResolveFriendByBattleTag(bnetApi,expectedBattleTag,guid)
if resolved then
return resolved
end

end


if not isStaleId then
local scannedInfo,friendIndex=scanFriendListById(bnetApi,bnetAccountID)
if scannedInfo and scannedInfo.isOnline~=nil then
return scannedInfo
end
accountInfo=accountInfo or scannedInfo


if friendIndex and accountInfo and accountInfo.isOnline==nil then
local enriched=probeGameAccounts(bnetApi,friendIndex,accountInfo)
if enriched then
return enriched
end
end
end


local guidResult=resolveByGUID(bnetApi,guid,accountInfo,isStaleId)
if guidResult then
return guidResult
end

return accountInfo
end

function BNetResolver.ResolvePlayerInfo(playerInfoByGUID,guid)
if type(playerInfoByGUID)~="function"or guid==nil then
return nil
end

local ok,className,classTag,raceName,raceTag=pcall(playerInfoByGUID,guid)
if not ok then
return nil
end

if className==nil and classTag==nil and raceName==nil and raceTag==nil then
return nil
end

return{
className=className,
classTag=classTag,
raceName=raceName,
raceTag=raceTag,
}
end

function BNetResolver.ScanFriendList(bnetApi)
local byBattleTag={}
if type(bnetApi)~="table"then
return byBattleTag
end
local getNumFriends=resolveGetNumFriends(bnetApi)
if type(getNumFriends)~="function"or type(bnetApi.GetFriendAccountInfo)~="function"then
return byBattleTag
end
local ok,numFriends=pcall(getNumFriends)
if not ok or not numFriends then
return byBattleTag
end
for i=1,numFriends do
local ok2,info=pcall(bnetApi.GetFriendAccountInfo,i)
if ok2 and info and info.battleTag then
byBattleTag[info.battleTag]={
bnetAccountID=info.bnetAccountID,
friendIndex=i,
accountInfo=info,
}
end
end
return byBattleTag
end

function BNetResolver.NormalizeAvailabilityStatus(status)
if status==nil or type(status)=="string"then
return status
end

return Types.AVAILABILITY_STATUS_BY_CODE[status]or tostring(status)
end

ns.BNetResolver=BNetResolver

return BNetResolver
