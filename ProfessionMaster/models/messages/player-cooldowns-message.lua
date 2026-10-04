--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local PlayerCooldownsMessage = _G.professionMaster:CreateModel("player-cooldowns-message");
PlayerCooldownsMessage.prefix = "CD";

--- Create message model.
-- @param playerName Short name of the player.
-- @param cooldowns Table of { [spellId] = expiresTimestamp }.
function PlayerCooldownsMessage:Create(playerName, cooldowns)
    local message = {
        playerName = playerName,
        cooldowns = cooldowns
    };
    setmetatable(message, PlayerCooldownsMessage);
    return message;
end

--- Parse message from string.
function PlayerCooldownsMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        playerName = values[1],
        cooldowns = {}
    };

    -- parse cooldown entries (format: spellId.timestamp,spellId.timestamp,...)
    if (values[2]) then
        local entries = messageService:SplitString(values[2], ",");
        for i = 1, #entries do
            local parts = messageService:SplitString(entries[i], ".");
            local spellId = tonumber(parts[1]);
            local expires = tonumber(parts[2]);
            if (spellId and expires) then
                message.cooldowns[spellId] = expires;
            end
        end
    end

    setmetatable(message, PlayerCooldownsMessage);
    return message;
end

--- Convert message to string.
function PlayerCooldownsMessage:ToString()
    local entries = {};
    for spellId, expires in pairs(self.cooldowns) do
        table.insert(entries, spellId .. "." .. expires);
    end
    return self.playerName .. ":" .. table.concat(entries, ",");
end
