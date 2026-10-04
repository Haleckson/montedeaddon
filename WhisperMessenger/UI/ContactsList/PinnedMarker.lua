local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")





local PinnedMarker={}

local function wanted(row)
local item=row.item
return item~=nil and item.pinned==true and(item.unreadCount or 0)==0
end


function PinnedMarker.update(row)
if row.pinnedMarker==nil then
if not wanted(row)or row.pinButton==nil then
return
end
local marker=row:CreateTexture(nil,"OVERLAY")
marker:SetPoint("CENTER",row.pinButton,"CENTER",0,0)
marker:SetTexture(Theme.TEXTURES.pinned_marker)
row.pinnedMarker=marker
end
local glyphSize=Theme.LAYOUT.CONTACT_ACTION_SIZE-2
row.pinnedMarker:SetSize(glyphSize,glyphSize)
UIHelpers.applyVertexColor(row.pinnedMarker,Theme.COLORS.text_secondary)
PinnedMarker.setVisible(row,true)
end


function PinnedMarker.setVisible(row,visible)
if row.pinnedMarker==nil then
return
end
row.pinnedMarker:SetShown(visible and wanted(row))
end

ns.ContactsListPinnedMarker=PinnedMarker
return PinnedMarker
