local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local applyColorTexture=UIHelpers.applyColorTexture
local setFontObject=UIHelpers.setFontObject
local setTextColor=UIHelpers.setTextColor
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")

local DateSeparator={}


local function createLabelSeparator(factory,parent,paneWidth,labelText,labelColor)
local height=Theme.LAYOUT.DATE_SEPARATOR_HEIGHT
local frame=factory.CreateFrame("Frame",nil,parent)
frame:SetSize(paneWidth,height)


local labelFS=frame._labelFS
if not labelFS then
labelFS=frame:CreateFontString(nil,"OVERLAY")
frame._labelFS=labelFS

local lineLeft=frame:CreateTexture(nil,"ARTWORK")
lineLeft:SetHeight(Theme.LAYOUT.DIVIDER_THICKNESS)
applyColorTexture(lineLeft,Theme.COLORS.divider)
lineLeft:SetPoint("LEFT",frame,"LEFT",Theme.LAYOUT.TRANSCRIPT_LEFT_GUTTER,0)
lineLeft:SetPoint("RIGHT",labelFS,"LEFT",-8,0)
frame._lineLeft=lineLeft

local lineRight=frame:CreateTexture(nil,"ARTWORK")
lineRight:SetHeight(Theme.LAYOUT.DIVIDER_THICKNESS)
applyColorTexture(lineRight,Theme.COLORS.divider)
lineRight:SetPoint("LEFT",labelFS,"RIGHT",8,0)
lineRight:SetPoint("RIGHT",frame,"RIGHT",-Theme.LAYOUT.TRANSCRIPT_LEFT_GUTTER,0)
frame._lineRight=lineRight
else

if labelFS.Show then
labelFS:Show()
end
if frame._lineLeft and frame._lineLeft.Show then
frame._lineLeft:Show()
end
if frame._lineRight and frame._lineRight.Show then
frame._lineRight:Show()
end
end

setFontObject(labelFS,Theme.FONTS.date_separator)
setTextColor(labelFS,labelColor)



local lineLeft,lineRight=frame._lineLeft,frame._lineRight
local divider=Theme.COLORS.divider


UIHelpers.applyHorizontalFadeLeft(lineLeft,divider)
UIHelpers.applyHorizontalFade(lineRight,divider)

if labelFS.SetText then
labelFS:SetText(labelText)
end
labelFS:ClearAllPoints()
labelFS:SetPoint("CENTER",frame,"CENTER",0,0)

return{frame=frame,height=height}
end

function DateSeparator.CreateDateSeparator(factory,parent,timestamp,paneWidth)
local dateStr=""
if ns.TimeFormat and ns.TimeFormat.DateSeparator then
dateStr=ns.TimeFormat.DateSeparator(timestamp)or""
end
return createLabelSeparator(factory,parent,paneWidth,dateStr,Theme.COLORS.text_timestamp)
end


function DateSeparator.CreateNewMessagesSeparator(factory,parent,paneWidth)
return createLabelSeparator(factory,parent,paneWidth,Localization.Text("New messages"),Theme.COLORS.accent)
end

ns.ChatBubbleDateSeparator=DateSeparator
return DateSeparator
