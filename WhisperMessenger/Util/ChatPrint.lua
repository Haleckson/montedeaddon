local addonName,ns=...
if type(ns)~="table"then
ns={}
end


local ChatPrint={}

local PREFIX="|cffffd100WhisperMessenger:|r "


function ChatPrint.Print(text,frame)
frame=frame or _G.DEFAULT_CHAT_FRAME
if frame==nil or type(frame.AddMessage)~="function"then
return false
end
frame:AddMessage(PREFIX..text)
return true
end

ns.ChatPrint=ChatPrint
return ChatPrint
