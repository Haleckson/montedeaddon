--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model: guild roster shared with a linked account (chunked, the first
-- chunk resets the member list on the receiver). The guild name sits between
-- the chunk flag and the member list, so it may contain any character but a
-- colon; member names never contain colons or commas
local LinkGuildMessage = _G.professionMaster:CreateModel("link-guild-message");
LinkGuildMessage.prefix = "LG";

--- Create message model.
-- @param guildName Name of the guild.
-- @param first True for the first chunk of the member list.
-- @param memberNames Array of member names (realm short form).
function LinkGuildMessage:Create(guildName, first, memberNames)
    local message = {
        guildName = guildName,
        first = first and true or false,
        memberNames = memberNames or {}
    };
    setmetatable(message, LinkGuildMessage);
    return message;
end

--- Parse message from string.
function LinkGuildMessage:Parse(value)
    local messageService = self:GetService("message");
    local first, guildName, members = string.match(value, "^(%d):(.*):([^:]*)$");
    local message = {
        guildName = guildName or "",
        first = first == "1",
        memberNames = (members and members ~= "") and messageService:SplitString(members, ",") or {}
    };
    setmetatable(message, LinkGuildMessage);
    return message;
end

--- Convert message to string.
function LinkGuildMessage:ToString()
    return (self.first and "1" or "0") .. ":" .. self.guildName .. ":" .. table.concat(self.memberNames, ",");
end
