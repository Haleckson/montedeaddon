local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Types={}






Types.AVAILABILITY_STATUS_BY_CODE={
[0]="CanWhisper",
[1]="Offline",
[2]="WrongFaction",
[3]="WrongFaction",
}





Types.WHISPERABLE={
CanWhisper=true,
XFaction=true,
Away=true,
Busy=true,
BNetOnline=true,
}

ns.TransportTypes=Types
return Types
