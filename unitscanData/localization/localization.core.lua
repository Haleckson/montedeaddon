local addonName, L = ...; -- L1
local function defaultFunc(L, key)

 return key;
end
setmetatable(L, {__index=defaultFunc});

