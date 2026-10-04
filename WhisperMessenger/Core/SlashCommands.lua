local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local SlashCommands={}
ns.SlashCommands=SlashCommands

function SlashCommands.Register(handlers)
handlers=handlers or{}

local function handleCommand(_msg)
if handlers.toggle then
handlers.toggle()
end
end




local function handleReplyCommand()
if handlers.replyToLast then
handlers.replyToLast()
end
end




if type(_G.SlashCmdList)=="table"then
_G.SLASH_WHISPERMESSENGER1="/wmsg"
_G.SLASH_WHISPERMESSENGER2="/whispermessenger"
_G.SlashCmdList["WHISPERMESSENGER"]=handleCommand

_G.SLASH_WHISPERMESSENGER_REPLY1="/wr"
_G.SLASH_WHISPERMESSENGER_REPLY2="/wreply"
_G.SlashCmdList["WHISPERMESSENGER_REPLY"]=handleReplyCommand
end

return true
end

return SlashCommands
