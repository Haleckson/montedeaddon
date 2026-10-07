--[[
  Forever Companion - Features/ChatLinks.lua
  Clickable discovery links in chat.

  The server strips custom hyperlinks from chat, so links travel as plain
  text:  [FC:<id> <title>]
  Clients with the addon rewrite that text locally into an "addon" hyperlink
  (a link type Blizzard reserves for addons). Clicking opens the discovery,
  or asks the sender for it when it is not in the local journal yet.
  Clients without the addon simply see the readable bracket text.
]]

local _, FC = ...

local ChatLinks = FC:NewModule("ChatLinks")

local U = FC.Utils
local Compat = FC.Compat
local LINK_PATTERN = "%[FC:(%S+) ([^%]]+)%]"
local LINK_TYPE = "addon:ForeverCompanion:"

local EVENTS = {
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_CHANNEL",
}

--- Plain-text link for a record (what is typed into chat).
function ChatLinks:Build(rec)
    local title = (rec.n or "?"):gsub("[%[%]|]", "")
    if #title > 40 then title = title:sub(1, 40) end
    return "[FC:" .. rec.id .. " " .. title .. "]"
end

function ChatLinks:Insert(rec)
    if not rec then return false end
    return Compat.InsertChatLink(self:Build(rec))
end

local function validID(id)
    return type(id) == "string" and #id <= FC.C.LIMITS.ID and not id:find("[|%[%]]")
end

local function rewrite(text, sender)
    local senderName = U.NormalizeSender(sender) or ""
    return (text:gsub(LINK_PATTERN, function(id, title)
        if not validID(id) then return nil end
        return "|cffd8b25c|H" .. LINK_TYPE .. id .. ":" .. senderName .. "|h[" .. U.Escape(title) .. "]|h|r"
    end))
end

local function filter(_, _, message, sender, ...)
    if not FC.P or not FC.P.general.chatLinks then return false end
    if Compat.IsSecret(message) or type(message) ~= "string" then return false end
    if not message:find("[FC:", 1, true) then return false end
    return false, rewrite(message, sender), sender, ...
end

function ChatLinks:OnEnable()
    for _, event in ipairs(EVENTS) do
        Compat.AddChatFilter(event, filter)
    end
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("SetItemRef", function(_, link)
            FC:SafeCall("ChatLinks:Click", self.OnClick, self, link)
        end, self)
    end
    if hooksecurefunc and _G.SetItemRef then
        hooksecurefunc("SetItemRef", function(link)
            FC:SafeCall("ChatLinks:Click", self.OnClick, self, link)
        end)
    end
    FC.Bus:On("DISCOVERY_ADDED", self, function(_, rec)
        if self.pendingLink and rec.id == self.pendingLink then
            self.pendingLink = nil
            FC.MainWindow:ShowDiscovery(rec.id)
        end
    end)
end

function ChatLinks:OnClick(link)
    if type(link) ~= "string" or link:sub(1, #LINK_TYPE) ~= LINK_TYPE then return end
    local now = GetTime()
    if self.lastClick and now - self.lastClick < 0.2 then return end -- both hooks may fire
    self.lastClick = now
    local rest = link:sub(#LINK_TYPE + 1)
    local id, sender = rest:match("^(.*):([^:]*)$")
    if not validID(id) then return end
    if FC.Store:Get(id) then
        FC.MainWindow:ShowDiscovery(id)
    elseif sender and sender ~= "" and not U.SameCharacter(sender, FC.Store.me) then
        FC.Sync:RequestIds({ id }, sender)
        self.pendingLink = id
        FC:Print(FC.L.MSG_LINK_REQUESTED, U.ShortName(sender))
    else
        FC:Print(FC.L.MSG_LINK_UNKNOWN)
    end
end
