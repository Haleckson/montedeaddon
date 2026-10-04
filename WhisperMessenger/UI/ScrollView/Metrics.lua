local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local sizeValue=UIHelpers.sizeValue

local SCROLLBAR_WIDTH=Theme.LAYOUT.SCROLLBAR_WIDTH
local SCROLLBAR_INSET=0
local MICRO_OVERFLOW_TOLERANCE=5
local MAX_SNAP_TO_END_RETRY_ATTEMPTS=3

local Metrics={}


Metrics.SCROLLBAR_WIDTH=SCROLLBAR_WIDTH
Metrics.SCROLLBAR_INSET=SCROLLBAR_INSET
Metrics.MICRO_OVERFLOW_TOLERANCE=MICRO_OVERFLOW_TOLERANCE

local function captureLiveGeometry(view)
if view==nil or view.scrollFrame==nil then
return 0,0
end

local fallbackViewportWidth=view.hasOverflow and math.max((view.totalWidth or 0)-SCROLLBAR_WIDTH-SCROLLBAR_INSET,0)or(view.totalWidth or 0)
local liveViewportWidth=sizeValue(view.scrollFrame,"GetWidth","width",fallbackViewportWidth)
local liveViewportHeight=sizeValue(view.scrollFrame,"GetHeight","height",view.viewportHeight or 0)

view.totalWidth=liveViewportWidth+(view.hasOverflow and(SCROLLBAR_WIDTH+SCROLLBAR_INSET)or 0)
view.viewportHeight=liveViewportHeight
view.viewportWidth=liveViewportWidth
return liveViewportWidth,liveViewportHeight
end

local function applyViewportLayout(view,hasOverflow)
if view==nil or view.scrollFrame==nil then
return 0
end

local totalWidth=view.totalWidth or 0
local viewportHeight=view.viewportHeight or 0
local scrollFrameWidth=hasOverflow and math.max(totalWidth-SCROLLBAR_WIDTH-SCROLLBAR_INSET,0)or totalWidth
local contentHeight=sizeValue(view.content,"GetHeight","height",viewportHeight)

if view.scrollFrame.SetSize then
view.scrollFrame:SetSize(scrollFrameWidth,viewportHeight)
end

if view.content and view.content.SetSize then
view.content:SetSize(scrollFrameWidth,contentHeight)
end

if view.scrollBar and view.scrollBar.SetSize then
local wasSyncingScrollBar=view.syncingScrollBar
view.syncingScrollBar=true
view.scrollBar:SetSize(SCROLLBAR_WIDTH,viewportHeight)
view.syncingScrollBar=wasSyncingScrollBar
end

view.viewportWidth=scrollFrameWidth
view.hasOverflow=hasOverflow
return scrollFrameWidth
end


Metrics._captureLiveGeometry=captureLiveGeometry
Metrics._applyViewportLayout=applyViewportLayout

local function normalizeRange(range)
if type(range)~="number"or range<=MICRO_OVERFLOW_TOLERANCE then
return 0
end
return range
end

function Metrics.GetRange(view)
if view==nil or view.scrollFrame==nil then
return 0
end








local viewportHeight=sizeValue(view.scrollFrame,"GetHeight","height",0)



if viewportHeight<=0 then




viewportHeight=view.viewportHeight or 0
if viewportHeight<=0 then
return 0
end
end
local contentHeight=sizeValue(view.content,"GetHeight","height",viewportHeight)
local computed=normalizeRange(contentHeight-viewportHeight)
if computed>0 then
return computed
end

if type(view.scrollFrame.GetVerticalScrollRange)=="function"then
local range=view.scrollFrame:GetVerticalScrollRange()
range=normalizeRange(range)
if range>0 then
return range
end
end
return 0
end

function Metrics.GetOffset(view)
if view==nil or view.scrollFrame==nil then
return 0
end

if type(view.scrollFrame.GetVerticalScroll)=="function"then
local offset=view.scrollFrame:GetVerticalScroll()
if type(offset)=="number"then
return offset
end
end

return view.scrollFrame.verticalScroll or 0
end

local function scheduleSnapToEndRetry(view,Navigation,targetOffset,generation,retryAttempt)
retryAttempt=retryAttempt or 0
if
type(targetOffset)~="number"
or targetOffset<=0
or retryAttempt>=MAX_SNAP_TO_END_RETRY_ATTEMPTS
or view._snapToEndRetryPendingGeneration==generation
then
return
end

local timer=_G.C_Timer
if type(timer)~="table"or type(timer.After)~="function"then
return
end

local actualOffset=Metrics.GetOffset(view)
if actualOffset>=targetOffset then
return
end

view._snapToEndRetryPendingGeneration=generation
timer.After(0,function()
if view._snapToEndRetryPendingGeneration==generation then
view._snapToEndRetryPendingGeneration=nil
end

if view._snapToEndRetryGeneration~=generation then
return
end

if Metrics.GetOffset(view)~=actualOffset then
return
end

local retryTarget=Metrics.GetRange(view)
if retryTarget<=0 or Metrics.GetOffset(view)>=retryTarget then
return
end

Navigation.SetVerticalScroll(view,retryTarget)
scheduleSnapToEndRetry(view,Navigation,Metrics.GetRange(view),generation,retryAttempt+1)
end)
end



function Metrics.RefreshMetrics(view,contentHeight,snapToEnd)
if view==nil or view.content==nil or view.scrollFrame==nil then
return 0
end

captureLiveGeometry(view)

local viewportHeight=view.viewportHeight or 0
local nextContentHeight=math.max(viewportHeight,contentHeight or 0)



local hasOverflow=viewportHeight>0 and normalizeRange((contentHeight or 0)-viewportHeight)>0

applyViewportLayout(view,hasOverflow)

local viewportWidth=sizeValue(view.scrollFrame,"GetWidth","width",view.viewportWidth or view.totalWidth or 0)
if view.content.SetSize then
view.content:SetSize(viewportWidth,nextContentHeight)
end

if type(view.scrollFrame.UpdateScrollChildRect)=="function"then
view.scrollFrame:UpdateScrollChildRect()
end


local Navigation=ns.ScrollViewNavigation or require("WhisperMessenger.UI.ScrollView.Navigation")
local snapGeneration
if snapToEnd then
snapGeneration=(view._snapToEndRetryGeneration or 0)+1
view._snapToEndRetryGeneration=snapGeneration
end

local targetOffset=snapToEnd and Metrics.GetRange(view)or Metrics.GetOffset(view)
Navigation.SetVerticalScroll(view,targetOffset)
if snapToEnd then
scheduleSnapToEndRetry(view,Navigation,targetOffset,snapGeneration)
end
return nextContentHeight
end

ns.ScrollViewMetrics=Metrics
return Metrics
