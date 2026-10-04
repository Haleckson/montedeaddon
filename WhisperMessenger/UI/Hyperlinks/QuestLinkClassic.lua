local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local QuestLinkClassic={}













local CLASSIC_QUEST_LEVEL_PATTERN="%[%[(%d+)%]%s+([^%[%]|]+) %((%d+)%)%]"
local CLASSIC_QUEST_PATTERN="%[([^%[%]|]+) %((%d+)%)%]"
local QUEST_HYPERLINK_FORMAT="|cffffff00|Hquest:%s:%s|h[%s]|h|r"

local function rewriteSegment(segment)
local withLevel=string.gsub(segment,CLASSIC_QUEST_LEVEL_PATTERN,function(level,name,questId)
return string.format(QUEST_HYPERLINK_FORMAT,questId,level,name)
end)
local rewritten=string.gsub(withLevel,CLASSIC_QUEST_PATTERN,function(name,questId)
return string.format(QUEST_HYPERLINK_FORMAT,questId,"0",name)
end)
return rewritten
end












local QUEST_LINK_WITH_COLOR_PATTERN="|c%x+|Hquest:(%d+)[^|]*|h%[([^%]]+)%]|h|r"
local QUEST_LINK_BARE_PATTERN="|Hquest:(%d+)[^|]*|h%[([^%]]+)%]|h"

function QuestLinkClassic.Serialize(text)
if type(text)~="string"then
return text
end
if string.find(text,"|Hquest:",1,true)==nil then
return text
end

local result=string.gsub(text,QUEST_LINK_WITH_COLOR_PATTERN,function(questId,name)
return string.format("[%s (%s)]",name,questId)
end)
result=string.gsub(result,QUEST_LINK_BARE_PATTERN,function(questId,name)
return string.format("[%s (%s)]",name,questId)
end)
return result
end
function QuestLinkClassic.CanonicalizeForTransport(text)
if type(text)~="string"then
return text
end
local canonical=QuestLinkClassic.Serialize(text)
canonical=string.gsub(canonical,CLASSIC_QUEST_LEVEL_PATTERN,function(_,name)
return"["..name.."]"
end)
canonical=string.gsub(canonical,CLASSIC_QUEST_PATTERN,function(name)
return"["..name.."]"
end)
return canonical
end

function QuestLinkClassic.Rewrite(text)
if type(text)~="string"then
return text
end
if text==""or string.find(text,"%[")==nil then
return text
end

local output={}
local cursor=1

while cursor<=#text do
local hyperlinkStart,hyperlinkEnd=string.find(text,"|H.-|h.-|h",cursor)
if hyperlinkStart==nil then
table.insert(output,rewriteSegment(string.sub(text,cursor)))
break
end

if hyperlinkStart>cursor then
table.insert(output,rewriteSegment(string.sub(text,cursor,hyperlinkStart-1)))
end

table.insert(output,string.sub(text,hyperlinkStart,hyperlinkEnd))
cursor=hyperlinkEnd+1
end

return table.concat(output)
end

ns.UIHyperlinksQuestLinkClassic=QuestLinkClassic
return QuestLinkClassic
