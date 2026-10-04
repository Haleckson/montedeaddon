local addonName,ns=...
if type(ns)~="table"then
ns={}
end
local FlavorCompat=ns.FlavorCompat or(type(require)=="function"and require("WhisperMessenger.Core.FlavorCompat"))or nil

local MYTHIC_KEYSTONE_DIFFICULTY=8

local ContentDetector={}

function ContentDetector.IsMythicRestricted(getInstanceInfo)
if not FlavorCompat or not FlavorCompat.hasMythicPlus then
return false
end
if type(getInstanceInfo)~="function"then
return false
end
local _,_,difficultyID=getInstanceInfo()
return difficultyID==MYTHIC_KEYSTONE_DIFFICULTY
end

function ContentDetector.IsCompetitiveContent(getInstanceInfo)
if type(getInstanceInfo)~="function"then
return false
end
local _,instanceType=getInstanceInfo()





if instanceType=="pvp"or instanceType=="arena"then
return true
end


return false
end

ns.ContentDetector=ContentDetector
return ContentDetector
