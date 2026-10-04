local addonName,ns=...
if type(ns)~="table"then
ns={}
end











local RestrictedActions={}


RestrictedActions.TYPES={
Combat=0,
Encounter=1,
ChallengeMode=2,
PvPMatch=3,
Map=4,
}


RestrictedActions.STATES={
Inactive=0,
Activating=1,
Active=2,
}

function RestrictedActions.New()
local cached={}
local self={}

function self.updateFromEvent(restrictionType,newState)
if type(restrictionType)~="number"or type(newState)~="number"then
return
end
cached[restrictionType]=newState
end

function self.isActive(restrictionType)
local s=cached[restrictionType]
if s~=nil then
return s==RestrictedActions.STATES.Active or s==RestrictedActions.STATES.Activating
end
local api=_G.C_RestrictedActions
if api and type(api.IsAddOnRestrictionActive)=="function"then
local ok,result=pcall(api.IsAddOnRestrictionActive,restrictionType)
if ok then
return result==true
end
end
return false
end

function self.isCompetitive()
return self.isActive(RestrictedActions.TYPES.Encounter)
or self.isActive(RestrictedActions.TYPES.ChallengeMode)
or self.isActive(RestrictedActions.TYPES.PvPMatch)
end

function self.isMythic()
return self.isActive(RestrictedActions.TYPES.ChallengeMode)
end

return self
end

ns.BootstrapRestrictedActions=RestrictedActions
return RestrictedActions
