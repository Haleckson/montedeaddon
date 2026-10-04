local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local UnreadDividerPosition={}





function UnreadDividerPosition.OpeningOffset(transcript,state,dividerMessage,viewportHeight)
local isNew=dividerMessage~=nil and dividerMessage~=transcript._positionedDivider
transcript._positionedDivider=dividerMessage
if not isNew then
return nil
end
for _,row in ipairs(state.rows)do
if row.message==dividerMessage then
if state.totalHeight-row.offset>viewportHeight then
return row.offset
end
return nil
end
end
return nil
end

ns.ConversationPaneUnreadDividerPosition=UnreadDividerPosition
return UnreadDividerPosition
