local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local DragReorder={}

local math_floor=math.floor
local math_max=math.max
local math_min=math.min





function DragReorder.GroupBoundaries(items)
local pinStart,pinEnd=0,0
local unStart,unEnd=0,0

for i,item in ipairs(items)do
if item.pinned then
if pinStart==0 then
pinStart=i
end
pinEnd=i
else
if unStart==0 then
unStart=i
end
unEnd=i
end
end

return pinStart,pinEnd,unStart,unEnd
end





function DragReorder.CursorToRowIndex(cursorY,scrollOffset,rowHeight,totalRows)
local adjusted=cursorY+scrollOffset
local raw=math_floor(adjusted/rowHeight)+1
return math_max(1,math_min(raw,totalRows))
end



function DragReorder.GroupRange(items,index)
local pinStart,pinEnd,unStart,unEnd=DragReorder.GroupBoundaries(items)
if items[index].pinned then
return pinStart,pinEnd
end
return unStart,unEnd
end



function DragReorder.FindDropIndex(items,sourceIndex,targetIndex)
local groupStart,groupEnd=DragReorder.GroupRange(items,sourceIndex)
return math_max(groupStart,math_min(targetIndex,groupEnd))
end




function DragReorder.ComputeNewOrders(items,sourceIndex,dropIndex)
local groupStart,groupEnd=DragReorder.GroupRange(items,sourceIndex)


local keys={}
for i=groupStart,groupEnd do
keys[#keys+1]=items[i].conversationKey
end


local relSource=sourceIndex-groupStart+1
local relDrop=dropIndex-groupStart+1


local movedKey=table.remove(keys,relSource)

table.insert(keys,relDrop,movedKey)


local orders={}
for i,key in ipairs(keys)do
orders[key]=i
end

return orders
end

ns.ContactsListDragReorder=DragReorder
return DragReorder
