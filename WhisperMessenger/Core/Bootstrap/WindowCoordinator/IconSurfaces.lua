local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local BadgeFilter=ns.ToggleIconBadgeFilter or require("WhisperMessenger.UI.ToggleIcon.BadgeFilter")
local DataBroker=ns.MinimapIconDataBroker or require("WhisperMessenger.UI.MinimapIcon.DataBroker")



local IconSurfaces={}



function IconSurfaces.Update(contacts,surfaces)




local unread=BadgeFilter.SumWhisperUnread(contacts)
local window=surfaces.getWindow()
local tabMode=window and type(window.getTabMode)=="function"and window.getTabMode()or"whispers"
local whispersVisibleInPane=surfaces.isWindowVisible()and tabMode=="whispers"
local preview=not whispersVisibleInPane and surfaces.buildMessagePreview(contacts)or nil
local previewSender=preview and preview.senderName or nil
local previewText=preview and preview.messageText or nil
local previewClass=preview and preview.classTag or nil

local icon=surfaces.getIcon()
if icon and icon.setUnreadCount then
icon.setUnreadCount(unread)
end
if icon and icon.setIncomingPreview then
icon.setIncomingPreview(previewSender,previewText,previewClass)
end

local minimap=surfaces.getMinimapIcon()
if minimap and minimap.setUnreadCount then
minimap.setUnreadCount(unread)
end
if minimap and minimap.setIncomingPreview then


if not minimap.isShown or minimap.isShown()then
minimap.setIncomingPreview(previewSender,previewText,previewClass)
else
minimap.setIncomingPreview(nil,nil,nil)
end
end

local ldb=surfaces.getLdbObject()
if ldb then
ldb.unread=unread
ldb.text=DataBroker.FormatText(unread)
end
end

ns.BootstrapWindowCoordinatorIconSurfaces=IconSurfaces
return IconSurfaces
