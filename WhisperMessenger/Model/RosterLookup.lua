local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Identity=ns.Identity or require("WhisperMessenger.Model.Identity")





local RosterLookup={}

local function canonical(name)
return Identity.FromWhisper(name).canonicalName
end


local function matchingGUID(info,target)
if canonical(info.name)==target then
return info.guid
end
return nil
end

local function findInClub(api,clubId,target)
local ok,members=pcall(api.GetClubMembers,clubId)
if not ok or type(members)~="table"then
return nil
end
for _,memberId in ipairs(members)do
local infoOk,info=pcall(api.GetMemberInfo,clubId,memberId)
if infoOk and type(info)=="table"then
local matchOk,guid=pcall(matchingGUID,info,target)
if matchOk and guid then
return guid
end
end
end
return nil
end


function RosterLookup.FindGUIDByName(api,name)
if type(api)~="table"or type(api.GetSubscribedClubs)~="function"or name==nil then
return nil
end
local ok,clubs=pcall(api.GetSubscribedClubs)
if not ok or type(clubs)~="table"then
return nil
end
local target=canonical(name)
for _,club in ipairs(clubs)do
local guid=findInClub(api,club.clubId,target)
if guid then
return guid
end
end
return nil
end

ns.RosterLookup=RosterLookup
return RosterLookup
