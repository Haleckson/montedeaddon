local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local LocalPlayer=ns.LocalPlayer or require("WhisperMessenger.Core.LocalPlayer")



local Mention={}



local function isWordByte(byte)
if byte==nil then
return false
end
return byte>=0x80 or string.find(string.char(byte),"%w")~=nil
end

local function containsWord(text,name)
local haystack=string.lower(text)
local needle=string.lower(name)
local start=1
while true do
local first,last=string.find(haystack,needle,start,true)
if first==nil then
return false
end
if not isWordByte(string.byte(haystack,first-1))and not isWordByte(string.byte(haystack,last+1))then
return true
end
start=first+1
end
end




function Mention.Matches(text,name)
if type(text)~="string"or type(name)~="string"or name==""then
return false
end
local ok,found=pcall(containsWord,text,name)
return ok and found==true
end



local playerName=nil

function Mention.PlayerName()
if playerName==nil then
playerName=LocalPlayer.Name()
end
return playerName
end

ns.GroupChatIngestMention=Mention
return Mention
