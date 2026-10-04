--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local DataRequestMessage = _G.professionMaster:CreateModel("data-request-message");
DataRequestMessage.prefix = "DR";

--- Create message model.
-- @param players Table of { storeName = sinceTimestamp } pairs (0 = full sync).
function DataRequestMessage:Create(players)
    local message = {
        players = players
    };
    setmetatable(message, DataRequestMessage);
    return message;
end

--- Parse message from string.
function DataRequestMessage:Parse(value)
    local messageService = self:GetService("message");
    local message = {
        players = {}
    };

    -- parse entries (storeName.sinceTimestamp,storeName.sinceTimestamp,...)
    local parts = messageService:SplitString(value, ",");
    for _, part in ipairs(parts) do
        local dotPos = string.find(part, ".", 1, true);
        if (dotPos) then
            -- new format: name.timestamp
            local storeName = string.sub(part, 1, dotPos - 1);
            local since = tonumber(string.sub(part, dotPos + 1)) or 0;
            message.players[storeName] = since;
        else
            -- legacy format: just name (treat as full sync request)
            message.players[part] = 0;
        end
    end

    setmetatable(message, DataRequestMessage);
    return message;
end

--- Convert message to string.
function DataRequestMessage:ToString()
    -- build entry list
    local parts = {};
    for storeName, since in pairs(self.players) do
        table.insert(parts, storeName .. "." .. since);
    end
    return table.concat(parts, ",");
end
