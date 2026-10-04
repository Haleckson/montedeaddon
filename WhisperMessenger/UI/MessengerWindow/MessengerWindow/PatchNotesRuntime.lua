local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local PatchNotesRuntime={}








function PatchNotesRuntime.Wire(options)
options=options or{}

local button=options.button
local tab=options.tab
local setGlowing=options.setGlowing
local settingsConfig=options.settingsConfig or{}
local patchNotes=options.patchNotes or ns.PatchNotes or{}
local openPage=options.openPage

local function isUnseen()
return settingsConfig.patchNotesSeenVersion~=patchNotes.version
end

local function markSeen()
settingsConfig.patchNotesSeenVersion=patchNotes.version
if setGlowing then
setGlowing(false)
end
end

if setGlowing then
setGlowing(isUnseen())
end

if button and button.SetScript then
button:SetScript("OnClick",function()
if openPage then
openPage()
end
markSeen()
end)
end



if tab and tab.HookScript then
tab:HookScript("OnClick",markSeen)
end

return{isUnseen=isUnseen,markSeen=markSeen}
end

ns.MessengerWindowPatchNotesRuntime=PatchNotesRuntime

return PatchNotesRuntime
