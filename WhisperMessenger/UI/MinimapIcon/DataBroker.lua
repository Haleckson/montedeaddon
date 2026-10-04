local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local DataBroker={}







function DataBroker.FormatText(unread)
local count=unread or 0
if count>0 then
return tostring(count).." unread"
end
return"Whisper Messenger"
end







function DataBroker.Register(options)
options=options or{}

local function tryRegister()
if type(_G.LibStub)~="table"then
return false
end
local ldb=_G.LibStub("LibDataBroker-1.1",true)
if ldb==nil then
return false
end



local dataobj=ldb:NewDataObject("WhisperMessenger",{
type="launcher",
icon="Interface\\AddOns\\WhisperMessenger\\Media\\icon.png",
label="Whisper Messenger",
text="Whisper Messenger",
OnClick=function(_)
if options.onToggle then
options.onToggle()
end
end,
OnTooltipShow=nil,
})

if dataobj==nil then
return false
end

dataobj.OnTooltipShow=function(tt)
if not tt or not tt.AddLine then
return
end
tt:AddLine("Whisper Messenger")
local count=tonumber(dataobj.unread)or 0
if count>0 then
tt:AddLine(DataBroker.FormatText(count))
end
end

if options.onRegistered then
options.onRegistered(dataobj)
end

return true
end

if not tryRegister()and type(_G.CreateFrame)=="function"then
local loginFrame=_G.CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent",function()
tryRegister()
loginFrame:UnregisterEvent("PLAYER_LOGIN")
end)
end
end

ns.MinimapIconDataBroker=DataBroker
return DataBroker
