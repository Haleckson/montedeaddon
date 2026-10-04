local addonName,ns=...
if type(ns)~="table"then
ns={}
end


local TextLimits={}


TextLimits.MESSAGE_MAX_BYTES=255



TextLimits.INPUT_MAX_BYTES=TextLimits.MESSAGE_MAX_BYTES+1

local function isContinuationByte(byte)
return byte~=nil and byte>=0x80 and byte<0xC0
end


function TextLimits.Trim(text)
if type(text)~="string"then
return nil
end
local trimmed=string.match(text,"^%s*(.-)%s*$")
if trimmed==""then
return nil
end
return trimmed
end


function TextLimits.CapBytes(text,maxBytes)
if#text<=maxBytes then
return text
end
local cut=maxBytes
while cut>0 and isContinuationByte(string.byte(text,cut+1))do
cut=cut-1
end
return string.sub(text,1,cut)
end


function TextLimits.CapChars(text,maxChars)
local chars=0
for index=1,#text do
if not isContinuationByte(string.byte(text,index))then
chars=chars+1
if chars>maxChars then
return string.sub(text,1,index-1)
end
end
end
return text
end

ns.TextLimits=TextLimits
return TextLimits
