local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local ScriptBindings={}

function ScriptBindings.Bind(options)
options=options or{}

local frame=options.frame
local resizeGrip=options.resizeGrip
local contactsResizeHandle=options.contactsResizeHandle
local windowResize=options.windowResize
local contactsResize=options.contactsResize
local relayoutWindow=options.relayoutWindow

local alphaTicker=nil

local function updateResizeFromCursor()
contactsResize.updateFromCursor()
windowResize.updateFromCursor()
end

local function updateResizeOnly()
updateResizeFromCursor()
end

local function updateFrameOnUpdate()
if frame==nil or type(frame.SetScript)~="function"then
return
end
if windowResize.isResizing()or contactsResize.isResizing()then
frame:SetScript("OnUpdate",updateResizeOnly)
else
frame:SetScript("OnUpdate",nil)
end
end

local function startAlphaTicker()
local timer=_G.C_Timer
if alphaTicker~=nil or type(timer)~="table"or type(timer.NewTicker)~="function"then
return
end
alphaTicker=timer.NewTicker(options.frameTheme.WINDOW_ALPHA_UPDATE_INTERVAL,function()
if not windowResize.isResizing()then
options.refreshWindowAlpha()
end
end)
end

local function stopAlphaTicker()
if alphaTicker==nil then
return
end
alphaTicker:Cancel()
alphaTicker=nil
end

local function composerHasFocus()
local input=options.composerInput
if input==nil or type(input.HasFocus)~="function"then
return false
end
local ok,focused=pcall(function()
return input:HasFocus()==true
end)
return ok and focused==true
end

local function isMouseOverFrame()
if frame==nil or type(frame.IsMouseOver)~="function"then
return false
end
local ok,over=pcall(function()
return frame:IsMouseOver()==true
end)
return ok and over==true
end






local function preserveComposerFocusAround(fn)
local hadFocus=composerHasFocus()
fn()
if hadFocus and not composerHasFocus()then
local input=options.composerInput
if input and type(input.SetFocus)=="function"then
input:SetFocus()
end
end
end

local function promoteStrata()
preserveComposerFocusAround(function()
if frame and type(frame.SetFrameStrata)=="function"then
frame:SetFrameStrata("HIGH")
end
if frame and type(frame.Raise)=="function"then
frame:Raise()
end
end)
end

local function demoteStrataIfIdle()
if composerHasFocus()or isMouseOverFrame()then
return
end
preserveComposerFocusAround(function()
if frame and type(frame.SetFrameStrata)=="function"then
frame:SetFrameStrata("MEDIUM")
end



if frame and type(frame.Raise)=="function"then
frame:Raise()
end
end)
end

if frame and frame.SetScript then
frame:SetScript("OnShow",function()
startAlphaTicker()
options.refreshWindowAlpha(true)


promoteStrata()
if options.composerInput and options.getAutoFocusChatInput and options.getAutoFocusChatInput()and options.composerInput.SetFocus then
options.composerInput:SetFocus()
end
end)

frame:SetScript("OnHide",function()
stopAlphaTicker()
contactsResize.reset()
windowResize.reset()
updateFrameOnUpdate()
end)

frame:SetScript("OnMouseDown",function()
promoteStrata()
end)

frame:SetScript("OnEnter",function()
if windowResize.isResizing()then
return
end
options.refreshWindowAlpha(true)
end)

frame:SetScript("OnLeave",function()
if windowResize.isResizing()then
return
end
options.refreshWindowAlpha()




end)







if type(frame.RegisterEvent)=="function"then
frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
end
frame:SetScript("OnEvent",function(self,event)
if event=="GLOBAL_MOUSE_DOWN"and not isMouseOverFrame()then
demoteStrataIfIdle()
end
end)

frame:SetScript("OnSizeChanged",function(_self,w,h)
if options.isSuppressSizeChangedRelayout()then
return
end
relayoutWindow(w,h,nil,false)
end)

frame:SetScript("OnDragStart",function(self)
if self.IsMovable==nil or self:IsMovable()then
self:StartMoving()
end
end)

frame:SetScript("OnDragStop",function(self)
self:StopMovingOrSizing()
local nextState=options.buildState(self)
if options.onPositionChanged then
options.onPositionChanged(nextState)
end
end)

local previousFrameMouseUp=frame.GetScript and frame:GetScript("OnMouseUp")
frame:SetScript("OnMouseUp",function(self,button)
if previousFrameMouseUp then
previousFrameMouseUp(self,button)
end
windowResize.stop(button)
contactsResize.stop(button)
updateFrameOnUpdate()
end)
updateFrameOnUpdate()
end




if options.composerInput and type(options.composerInput.HookScript)=="function"then
options.composerInput:HookScript("OnEditFocusGained",function()
promoteStrata()
end)
end

if resizeGrip and resizeGrip.SetScript then
resizeGrip:SetScript("OnMouseDown",function(_self,button)
windowResize.start(button)
updateFrameOnUpdate()
end)

resizeGrip:SetScript("OnMouseUp",function(_self,button)
windowResize.stop(button)
updateFrameOnUpdate()
end)
end

if contactsResizeHandle and contactsResizeHandle.SetScript then
contactsResizeHandle:SetScript("OnEnter",function()
contactsResize.setHighlight(true)
end)

contactsResizeHandle:SetScript("OnLeave",function()
if not contactsResize.isResizing()then
contactsResize.setHighlight(false)
end
end)

contactsResizeHandle:SetScript("OnMouseDown",function(_self,button)
contactsResize.start(button)
updateFrameOnUpdate()
end)

contactsResizeHandle:SetScript("OnMouseUp",function(_self,button)
contactsResize.stop(button)
updateFrameOnUpdate()
end)
end
end

ns.MessengerWindowWindowScriptsFrameScriptBindings=ScriptBindings

return ScriptBindings
