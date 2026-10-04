--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local HelloMessage = _G.professionMaster:CreateModel("hello-message");
HelloMessage.prefix = "H";

--- Create message model.
function HelloMessage:Create(storageId, fingerprint)
    local message = {
        storageId = storageId,
        fingerprint = fingerprint or ""
    };
    setmetatable(message, HelloMessage);
    return message;
end

--- Parse message from string.
function HelloMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storageId = values[1],
        fingerprint = values[2] or ""
    };
    setmetatable(message, HelloMessage);
    return message;
end

--- Convert message to string.
function HelloMessage:ToString()
    return self.storageId .. ":" .. self.fingerprint;
end
