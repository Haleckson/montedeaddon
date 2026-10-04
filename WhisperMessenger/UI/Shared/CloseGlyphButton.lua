local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")



local CloseGlyphButton={}


CloseGlyphButton.DANGER_HOVER={1.0,0.35,0.35,1.0}



function CloseGlyphButton.Create(factory,parent,size,theme,options)
theme=theme or Theme
local danger=options~=nil and options.danger==true
local button=factory.CreateFrame("Button",nil,parent)
button:SetSize(size,size)
button:EnableMouse(true)

local label=button:CreateFontString(nil,"OVERLAY",theme.FONTS.contact_name)
label:SetPoint("CENTER",button,"CENTER",0,0)
label:SetText("X")
UIHelpers.setTextColor(label,theme.COLORS.text_secondary)
button:SetScript("OnEnter",function()
UIHelpers.setTextColor(label,danger and CloseGlyphButton.DANGER_HOVER or theme.COLORS.text_primary)
end)
button:SetScript("OnLeave",function()
UIHelpers.setTextColor(label,theme.COLORS.text_secondary)
end)
button.label=label
return button
end

ns.CloseGlyphButton=CloseGlyphButton
return CloseGlyphButton
