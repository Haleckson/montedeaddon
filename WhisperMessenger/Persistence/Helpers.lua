local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Helpers={}


function Helpers.applyDefaults(target,defaults)
if target==nil or defaults==nil then
return target or{}
end
for key,value in pairs(defaults)do
if target[key]==nil then
target[key]=value
end
end
return target
end

ns.PersistenceHelpers=Helpers
return Helpers
