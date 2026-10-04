--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local PlayerDataResetMessage = _G.professionMaster:CreateModel("player-data-reset-message");
PlayerDataResetMessage.prefix = "RS";

--- Create message model.
-- @param storeName Full name of the character whose data should be reset.
-- @param timestamp Time of the reset (owner clock).
-- @param professionId Profession id to reset or 0 for all data.
function PlayerDataResetMessage:Create(storeName, timestamp, professionId)
    local message = {
        storeName = storeName,
        timestamp = timestamp,
        professionId = professionId or 0
    };
    setmetatable(message, PlayerDataResetMessage);
    return message;
end

--- Parse message from string.
function PlayerDataResetMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storeName = values[1],
        timestamp = tonumber(values[2]) or 0,
        professionId = tonumber(values[3]) or 0
    };
    setmetatable(message, PlayerDataResetMessage);
    return message;
end

--- Convert message to string.
function PlayerDataResetMessage:ToString()
    return self.storeName .. ":" .. self.timestamp .. ":" .. self.professionId;
end
