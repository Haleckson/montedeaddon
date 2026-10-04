local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local HoverFade=ns.UIHelpersHoverFade or require("WhisperMessenger.UI.Helpers.HoverFade")




local RowHoverOverlay={}

local function createFill(row)
local fill=row:CreateTexture(nil,"BACKGROUND",nil,1)
fill:SetAllPoints()
fill:Hide()
return fill
end


function RowHoverOverlay.ensure(row)
if row.hoverFill==nil then
row.selectionFill=createFill(row)
row.hoverFill=createFill(row)
row.hoverFade=HoverFade.Attach(row.hoverFill)
end
UIHelpers.applyHorizontalFade(row.selectionFill,Theme.COLORS.bg_contact_selected)


row.hoverFade.paintColor(Theme.COLORS.bg_contact_hover)
end



function RowHoverOverlay.update(row,hovered)
if row.hoverFade==nil then
return false
end
row.selectionFill:SetShown(row.selected==true)
row.hoverFade.set(hovered and not row.selected)
return true
end

ns.ContactsListRowHoverOverlay=RowHoverOverlay
return RowHoverOverlay
