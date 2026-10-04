local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local FlavorCompat={}

local projectId=_G["WOW_PROJECT_ID"]
local MAINLINE=_G["WOW_PROJECT_MAINLINE"]or 1

FlavorCompat.isRetail=(projectId==MAINLINE)
FlavorCompat.isClassic=not FlavorCompat.isRetail


local FOREVER_TOC_MIN=16000
local FOREVER_TOC_MAX=17000
local tocVersion=nil
if type(_G["GetBuildInfo"])=="function"then
tocVersion=select(4,_G["GetBuildInfo"]())
end
FlavorCompat.isForever=type(tocVersion)=="number"and tocVersion>=FOREVER_TOC_MIN and tocVersion<FOREVER_TOC_MAX


FlavorCompat.hasMythicPlus=FlavorCompat.isRetail and not FlavorCompat.isForever

ns.FlavorCompat=FlavorCompat

return FlavorCompat
