local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local TimeFormat={}

local floor=math.floor

local VALID_FORMATS={["12h"]=true,["24h"]=true}
local VALID_SOURCES={["local"]=true,["server"]=true}

local config={
timeFormat="12h",
timeSource="local",
}

local serverOffset=nil




local WEEKDAY_KEYS={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
local MONTH_ABBR_KEYS={"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}



local MAY_FULL_KEY="May (full)"
local MONTH_FULL_KEYS={
"January",
"February",
"March",
"April",
MAY_FULL_KEY,
"June",
"July",
"August",
"September",
"October",
"November",
"December",
}





local function L(key)
local Localization=ns.Localization
if Localization and Localization.Text then
local translated=Localization.Text(key)
if translated~=key then
return translated
end
end
if key==MAY_FULL_KEY then
return"May"
end
return key
end



local function startOfLocalDay(ts)
local t=date("*t",ts)
return time({year=t.year,month=t.month,day=t.day,hour=0,min=0,sec=0})
end



local function computeServerOffset()
if not _G.C_DateAndTime or not _G.C_DateAndTime.GetCurrentCalendarTime then
return 0
end
local sCal=_G.C_DateAndTime.GetCurrentCalendarTime()
local lt=date("*t")
local sEpoch=time({
year=sCal.year,
month=sCal.month,
day=sCal.monthDay,
hour=sCal.hour,
min=sCal.minute,
sec=sCal.second or 0,
isdst=lt.isdst,
})
local lEpoch=time(lt)
local raw=sEpoch-lEpoch
return floor(raw/900+0.5)*900
end




local function displayTimestamp(ts)
if config.timeSource~="server"then
return ts
end
if serverOffset==nil then
serverOffset=computeServerOffset()
end
return ts+serverOffset
end




function TimeFormat.Configure(opts)
if type(opts)~="table"then
return
end
if opts.timeFormat and VALID_FORMATS[opts.timeFormat]then
config.timeFormat=opts.timeFormat
end
if opts.timeSource and VALID_SOURCES[opts.timeSource]then
config.timeSource=opts.timeSource
serverOffset=nil
end
end


local function now()
if config.timeSource=="server"and _G.GetServerTime then
return _G.GetServerTime()
end
return time()
end



function TimeFormat.MessageTime(timestamp)
if not timestamp or timestamp==0 then
return""
end
local ts=displayTimestamp(timestamp)
if config.timeFormat=="24h"then
return date("%H:%M",ts)
end


local t=date("*t",ts)
local meridiem=(t.hour>=12)and L("PM")or L("AM")

local digits=string.gsub(date("%I:%M",ts),"^0","")
return digits.." "..meridiem
end


function TimeFormat.GroupSessionTimestamp(timestamp)
if not timestamp or timestamp==0 then
return""
end
local ts=displayTimestamp(timestamp)
if config.timeFormat=="24h"then
return date("%H:%M %d/%m",ts)
end
local t=date("*t",ts)
local meridiem=(t.hour>=12)and L("PM")or L("AM")
local digits=string.gsub(date("%I:%M",ts),"^0","")
return digits.." "..meridiem.." "..date("%d/%m",ts)
end



function TimeFormat.DateSeparator(timestamp)
if not timestamp or timestamp==0 then
return""
end
local t=date("*t",displayTimestamp(timestamp))
local monthName=L(MONTH_FULL_KEYS[t.month]or MONTH_FULL_KEYS[1])
return monthName.." "..t.day..", "..t.year
end



function TimeFormat.ContactPreview(timestamp)
if not timestamp or timestamp==0 then
return""
end
local current=now()
local diff=current-timestamp
if diff<60 then
return L("now")
elseif diff<3600 then
return floor(diff/60)..L("m")
elseif diff<86400 then
return floor(diff/3600)..L("h")
end

local todayStart=startOfLocalDay(current)
if timestamp>=todayStart-86400 and timestamp<todayStart then
return L("Yesterday")
end
local t=date("*t",displayTimestamp(timestamp))

if diff<604800 then
return L(WEEKDAY_KEYS[t.wday]or WEEKDAY_KEYS[1])
end

return L(MONTH_ABBR_KEYS[t.month]or MONTH_ABBR_KEYS[1]).." "..t.day
end



function TimeFormat.IsDifferentDay(ts1,ts2)
if not ts1 or not ts2 or ts1==0 or ts2==0 then
return true
end
return date("%Y%m%d",displayTimestamp(ts1))~=date("%Y%m%d",displayTimestamp(ts2))
end

ns.TimeFormat=TimeFormat

return TimeFormat
