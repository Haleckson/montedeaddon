local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local EventUtils={}





function EventUtils.IsUnknownEventError(err)
return string.find(string.lower(tostring(err or"")),"unknown event",1,true)~=nil
end

function EventUtils.RegisterEventIfSupported(frame,eventName)
local ok,err=pcall(frame.RegisterEvent,frame,eventName)
if ok then
return true
end
if EventUtils.IsUnknownEventError(err)then
return false
end
error(err)
end

ns.EventUtils=EventUtils

return EventUtils
