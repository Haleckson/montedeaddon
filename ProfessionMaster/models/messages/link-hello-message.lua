--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model: presence beacon on the hidden link channel; carries nothing
-- but a protocol version, the sender name is part of every channel message
local LinkHelloMessage = _G.professionMaster:CreateModel("link-hello-message");
LinkHelloMessage.prefix = "LH";

--- Create message model.
function LinkHelloMessage:Create()
    local message = {
        version = 1
    };
    setmetatable(message, LinkHelloMessage);
    return message;
end

--- Parse message from string.
function LinkHelloMessage:Parse(value)
    local message = {
        version = tonumber(value) or 0
    };
    setmetatable(message, LinkHelloMessage);
    return message;
end

--- Convert message to string.
function LinkHelloMessage:ToString()
    return tostring(self.version);
end
