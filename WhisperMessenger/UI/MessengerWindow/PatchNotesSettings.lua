local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local SettingsControls=ns.SettingsControls or require("WhisperMessenger.UI.Shared.SettingsControls")
local Divider=ns.SettingsControlsDivider or require("WhisperMessenger.UI.Shared.SettingsControls.Divider")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local setTextColor=UIHelpers.setTextColor

local PatchNotesSettings={}

local PADDING=Theme.CONTENT_PADDING
local BODY_TOP_GAP=-24
local MIN_BODY_WIDTH=160
local BULLET_PREFIX="• "
local DIVIDER_GAP=10

local function text(key)
return Localization.Text(key)
end



local function hintText()
return text("See what changed in the latest update.").." ("..text("English only")..")"
end

local function buildTitle(config)
local title=text("What's New")
if type(config.version)=="string"and config.version~=""then
title=title.." "..config.version
end
if type(config.date)=="string"and config.date~=""then
title=title.." · "..config.date
end
return title
end



local function createNote(frame,line)
local note=frame:CreateFontString(nil,"OVERLAY",Theme.FONTS.message_text)
note:SetText(BULLET_PREFIX..line)
note:SetJustifyH("LEFT")
if note.SetJustifyV then
note:SetJustifyV("TOP")
end
if note.SetWordWrap then
note:SetWordWrap(true)
end
return note
end





local function buildNotes(frame,anchor,lines)
local notes,dividers={},{}
local previous,gap=anchor,BODY_TOP_GAP
for index,line in ipairs(lines or{})do
if index>1 then
local divider=Divider.Create(frame)
divider.left:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-DIVIDER_GAP)
dividers[#dividers+1]=divider
previous,gap=divider.left,-DIVIDER_GAP
end
local note=createNote(frame,line)
note:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,gap)
notes[#notes+1]=note
previous=note
end
return notes,dividers,previous
end

function PatchNotesSettings.Create(factory,parent,config,_options)
config=config or{}

local frame=factory.CreateFrame("Frame",nil,parent)
frame:SetAllPoints(parent)

local header=SettingsControls.CreateHeader(frame,{
title=buildTitle(config),
hint=hintText(),
})

local notes,dividers,lastRegion=buildNotes(frame,header.hint,config.lines)



local bottomSpacer=factory.CreateFrame("Frame",nil,frame)
bottomSpacer:SetSize(1,PADDING)
bottomSpacer:SetPoint("TOPLEFT",lastRegion,"BOTTOMLEFT",0,0)
frame._wmBottomMarker=bottomSpacer

local function refreshTheme(activeTheme)
activeTheme=activeTheme or Theme
header.refreshTheme(activeTheme)
for _,note in ipairs(notes)do
setTextColor(note,activeTheme.COLORS.text_primary)
end
for _,divider in ipairs(dividers)do
divider.applyTheme(activeTheme)
end
end

refreshTheme(Theme)

local function setLanguage()
header.title:SetText(buildTitle(config))
header.hint:SetText(hintText())
end



local function refreshLayout(width)
if type(width)~="number"or width<=0 then
return
end
local effective=math.max(MIN_BODY_WIDTH,math.floor(width))
header.refreshLayout(effective)
for _,note in ipairs(notes)do
note:SetWidth(effective)
end
for _,divider in ipairs(dividers)do
divider.setWidth(effective)
end
end

return{
frame=frame,
refreshTheme=refreshTheme,
refreshLayout=refreshLayout,
setLanguage=setLanguage,
}
end

ns.PatchNotesSettings=PatchNotesSettings
return PatchNotesSettings
