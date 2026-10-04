--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model: whispered to a trusted character to open a link between two
-- accounts; the storage id identifies the sending account on this realm
local LinkRequestMessage = _G.professionMaster:CreateModel("link-request-message");
LinkRequestMessage.prefix = "LR";

--- Create message model.
function LinkRequestMessage:Create(storageId)
    local message = {
        storageId = storageId
    };
    setmetatable(message, LinkRequestMessage);
    return message;
end

--- Parse message from string.
function LinkRequestMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storageId = values[1] or ""
    };
    setmetatable(message, LinkRequestMessage);
    return message;
end

--- Convert message to string.
function LinkRequestMessage:ToString()
    return self.storageId;
end
