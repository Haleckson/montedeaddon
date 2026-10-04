local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local PresenceCache={}



local INDEX_MIN_INTERVAL=300


local cache={}


local indexClub={}
local indexMember={}

local zoneByGuid={}

local freshAt={}
local indexBuiltAt=nil
local ttl=30
local dirty=true
local clubApi=nil
local function normalizeNow(now)
if type(now)~="number"then
return 0
end
return math.floor(now)
end

local function defaultNow()
local timeFn=_G.time
if type(timeFn)~="function"then
return 0
end
return normalizeNow(timeFn())
end

local nowFn=defaultNow
local function presenceToString(presence)
if presence==1 or presence==2 or presence==4 then
return"online"
end
if presence==3 then
return"offline"
end
return nil
end

local function safeIpairs(tbl)
local iterOk,iter,state,start=pcall(ipairs,tbl)
if not iterOk then
return ipairs({})
end
return iter,state,start
end




local function readZone(info)
local zone=info.zone
if type(zone)=="string"and zone~=""then
return zone
end
return nil
end





local function recordMember(acc,clubId,memberId,info)
acc.club[info.guid]=clubId
acc.member[info.guid]=memberId
acc.freshAt[info.guid]=acc.now
local p=presenceToString(info.presence)
if p then
acc.cache[info.guid]=p
end


local zone=readZone(info)
if zone then
acc.zoneByGuid[info.guid]=zone
end
end

local function cacheClub(acc,api,clubId)
local ok,members=pcall(api.GetClubMembers,clubId)
if not ok or type(members)~="table"then
return
end
for _,memberId in safeIpairs(members)do
local infoOk,info=pcall(api.GetMemberInfo,clubId,memberId)
if infoOk and info then
pcall(recordMember,acc,clubId,memberId,info)
end
end
end

function PresenceCache.Initialize(api,options)
options=options or{}
clubApi=api
ttl=options.ttl or 30
local providedNow=options.now
if type(providedNow)=="function"then
nowFn=function()
return normalizeNow(providedNow())
end
else
nowFn=defaultNow
end
cache={}
indexClub={}
indexMember={}
zoneByGuid={}
freshAt={}
indexBuiltAt=nil


dirty=true
end

function PresenceCache.Rebuild()
local now=nowFn()
local acc={cache={},club={},member={},zoneByGuid={},freshAt={},now=now}

if type(clubApi)=="table"then
local guildId=nil


if type(clubApi.GetGuildClubId)=="function"then
local ok,id=pcall(clubApi.GetGuildClubId)
if ok and id then
guildId=id
cacheClub(acc,clubApi,id)
end
end



if type(clubApi.GetSubscribedClubs)=="function"then
local ok,clubs=pcall(clubApi.GetSubscribedClubs)
if ok and clubs then
for _,club in ipairs(clubs)do
if club.clubId~=guildId then
cacheClub(acc,clubApi,club.clubId)
end
end
end
end
end

cache=acc.cache
indexClub=acc.club
indexMember=acc.member
zoneByGuid=acc.zoneByGuid
freshAt=acc.freshAt
indexBuiltAt=now
dirty=false
end

function PresenceCache.GetPresence(guid)
if guid==nil then
return nil
end
return cache[guid]
end

function PresenceCache.GetZone(guid)
if guid==nil then
return nil
end
return zoneByGuid[guid]
end



local function guidMatches(info,guid)
return info.guid==guid
end




local function lookupIndexed(guid)
local clubId=indexClub[guid]
if clubId==nil or type(clubApi)~="table"then
return nil,false
end

local ok,info=pcall(clubApi.GetMemberInfo,clubId,indexMember[guid])
if not ok or type(info)~="table"then


indexClub[guid]=nil
indexMember[guid]=nil
return nil,false
end

local matchOk,matches=pcall(guidMatches,info,guid)
if not matchOk then



return cache[guid],true
end
if not matches then
indexClub[guid]=nil
indexMember[guid]=nil
return nil,false
end

local zoneOk,zone=pcall(readZone,info)
if zoneOk and zone then
zoneByGuid[guid]=zone
end

local presenceOk,presence=pcall(presenceToString,info.presence)
if not presenceOk then

return cache[guid],true
end

return presence,true
end




function PresenceCache.RefreshPresence(guid)
if guid==nil or type(clubApi)~="table"then
return nil
end

local presence,found=lookupIndexed(guid)
if not found then
local staleIndex=dirty and indexBuiltAt~=nil and(nowFn()-indexBuiltAt)>=INDEX_MIN_INTERVAL
if indexBuiltAt==nil or staleIndex then
PresenceCache.Rebuild()
presence=lookupIndexed(guid)
end
end

cache[guid]=presence
freshAt[guid]=nowFn()
return presence
end



function PresenceCache.EnsureFresh(guid)
if guid==nil or type(clubApi)~="table"then
return nil
end

local readAt=freshAt[guid]
if readAt~=nil and(nowFn()-readAt)<ttl then
return cache[guid]
end

return PresenceCache.RefreshPresence(guid)
end

function PresenceCache.Invalidate()
dirty=true
end


function PresenceCache._reset()
cache={}
indexClub={}
indexMember={}
zoneByGuid={}
freshAt={}
indexBuiltAt=nil
dirty=true
clubApi=nil
nowFn=function()
return 0
end
end


function PresenceCache._initForTest(api,options)
PresenceCache.Initialize(api,options)
PresenceCache.Rebuild()
end

function PresenceCache._setCache(tbl)
cache=tbl or{}
dirty=false
end

ns.PresenceCache=PresenceCache

return PresenceCache
