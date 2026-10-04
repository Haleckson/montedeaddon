local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ContactsList=ns.ContactsList or require("WhisperMessenger.UI.ContactsList")
local ScrollView=ns.ScrollView or require("WhisperMessenger.UI.ScrollView")
local Navigation=ns.ScrollViewNavigation or require("WhisperMessenger.UI.ScrollView.Navigation")
local DragController=ns.MessengerWindowDragController or require("WhisperMessenger.UI.MessengerWindow.DragController")
local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")

local ContactsController={}










function ContactsController.Create(factory,contactsView,initialContacts,options)
options=options or{}

local currentContacts=initialContacts or{}
local currentSelectedKey=options.initialSelectedKey
local viewportH=contactsView.viewportHeight or 0
local rowH=Theme.LAYOUT.CONTACT_ROW_HEIGHT
local visibleCount=math.max(10,math.ceil(viewportH/rowH)+1)

local controller={
rows={},
content=contactsView.content,
scrollFrame=contactsView.scrollFrame,
scrollBar=contactsView.scrollBar,
view=contactsView,
}

local dragHandlers=DragController.Create(factory,controller,function()
return currentContacts
end,{
onReorder=options.onReorder,
rowHeight=rowH,
})


local rowOptions={
onSelect=function(item)
if options.onSelect then
options.onSelect(item)
end
end,
onPin=function(item)
if options.onPin then
options.onPin(item)
end
end,
onRemove=function(item)
if options.onRemove then
options.onRemove(item)
end
end,
onMarkUnread=function(item)
if options.onMarkUnread then
options.onMarkUnread(item)
end
end,
onUpdatePrefs=function(item,changes)
if options.onUpdatePrefs then
options.onUpdatePrefs(item,changes)
end
end,
onDragStart=dragHandlers.handleDragStart,
onDragStop=dragHandlers.handleDragStop,
}

local function refresh(nextContacts,selectedKey,resetPaging)
if nextContacts~=nil then
currentContacts=nextContacts
end
if selectedKey~=nil then
currentSelectedKey=selectedKey
end
if resetPaging then


local liveViewportH=contactsView.viewportHeight or viewportH
visibleCount=math.max(10,math.ceil(liveViewportH/rowH)+1)
ScrollView.SetVerticalScroll(contactsView,0)
end

rowOptions.selectedConversationKey=currentSelectedKey
rowOptions.visibleCount=visibleCount
rowOptions.hideMessagePreview=type(options.getHideMessagePreview)=="function"and options.getHideMessagePreview()
or options.hideMessagePreview

controller.rows=ContactsList.Refresh(factory,controller.content,controller.rows,currentContacts,rowOptions)
ScrollView.Sync(contactsView)

return controller.rows
end

local function loadMore()
if not ContactsList.HasMore(controller.content)then
return
end
visibleCount=visibleCount+10

refresh(nil,nil)
end

local function fillViewport(newHeight)
local needed=math.ceil(newHeight/rowH)+1
if needed>visibleCount then
visibleCount=needed
refresh(nil,nil)
end
end

controller.refresh=refresh
controller.loadMore=loadMore
controller.fillViewport=fillViewport








local function checkLoadMore()
local range=ScrollView.GetRange(contactsView)
local offset=ScrollView.GetOffset(contactsView)
if range>0 and offset>0 and offset>=range-Theme.LAYOUT.CONTACT_ROW_HEIGHT then
loadMore()
end
end

Navigation.InstallPostScrollHook(contactsView,checkLoadMore)

return controller
end

ns.MessengerWindowContactsController=ContactsController

return ContactsController
