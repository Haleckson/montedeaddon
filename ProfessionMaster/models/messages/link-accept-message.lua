--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model: confirms a link and lists the own characters of the sending
-- account (chunked, the first chunk resets the list on the receiver)
local LinkAcceptMessage = _G.professionMaster:CreateModel("link-accept-message");
LinkAcceptMessage.prefix = "LA";

--- Create message model.
-- @param storageId Storage id of the sending account.
-- @param first True for the first chunk of a character list.
-- @param characterNames Array of character names (realm short form).
function LinkAcceptMessage:Create(storageId, first, characterNames)
    local message = {
        storageId = storageId,
        first = first and true or false,
        characterNames = characterNames or {}
    };
    setmetatable(message, LinkAcceptMessage);
    return message;
end

--- Parse message from string.
function LinkAcceptMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storageId = values[1] or "",
        first = values[2] == "1",
        characterNames = values[3] and messageService:SplitString(values[3], ",") or {}
    };
    setmetatable(message, LinkAcceptMessage);
    return message;
end

--- Convert message to string.
function LinkAcceptMessage:ToString()
    return self.storageId .. ":" .. (self.first and "1" or "0") .. ":" .. table.concat(self.characterNames, ",");
end
