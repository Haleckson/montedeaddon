local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local setFontObject=UIHelpers.setFontObject

local EmptyState={}




function EmptyState.Create(parent,theme)
local resolvedTheme=theme or Theme
local frame=_G.CreateFrame("Frame",nil,parent)
frame:SetAllPoints(parent)
frame:Hide()

local label=frame:CreateFontString(nil,"ARTWORK")
setFontObject(label,(resolvedTheme.FONTS and resolvedTheme.FONTS.empty_state)or"GameFontNormal")
label:SetPoint("CENTER",frame,"CENTER",0,0)
label:SetJustifyH("CENTER")
label:SetJustifyV("MIDDLE")
label:SetWordWrap(true)
label:SetWidth(180)
label:SetText("")

local colors=resolvedTheme.COLORS or{}
local textColor=colors.text_secondary or{0.55,0.55,0.62,1.0}
label:SetTextColor(textColor[1],textColor[2],textColor[3],textColor[4]or 1.0)

frame.label=label
frame._theme=resolvedTheme

return frame
end


function EmptyState.Show(frame,message)
frame.label:SetText(message or"")
local colors=(frame._theme and frame._theme.COLORS)or{}
local textColor=colors.text_secondary or{0.55,0.55,0.62,1.0}
frame.label:SetTextColor(textColor[1],textColor[2],textColor[3],textColor[4]or 1.0)
frame:Show()
end


function EmptyState.Hide(frame)
frame.label:SetText("")
frame:Hide()
end

ns.ContactsListEmptyState=EmptyState
return EmptyState
