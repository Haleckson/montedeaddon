--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local DigestOfferMessage = _G.professionMaster:CreateModel("digest-offer-message");
DigestOfferMessage.prefix = "DO";

--- Create message model.
-- @param storageId Own storage id.
-- @param entries Table of { storeName = count } pairs for this chunk.
function DigestOfferMessage:Create(storageId, entries)
    local message = {
        storageId = storageId,
        entries = entries
    };
    setmetatable(message, DigestOfferMessage);
    return message;
end

--- Parse message from string.
function DigestOfferMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storageId = values[1],
        entries = {}
    };

    -- parse entries (storeName.count,storeName.count,...)
    if (values[2] and values[2] ~= "") then
        local entryParts = messageService:SplitString(values[2], ",");
        for i = 1, #entryParts do
            local dotPos = string.find(entryParts[i], ".", 1, true);
            if (dotPos) then
                local storeName = string.sub(entryParts[i], 1, dotPos - 1);
                local count = tonumber(string.sub(entryParts[i], dotPos + 1));
                if (storeName and count) then
                    message.entries[storeName] = count;
                end
            end
        end
    end

    setmetatable(message, DigestOfferMessage);
    return message;
end

--- Convert message to string.
function DigestOfferMessage:ToString()
    -- build entry list
    local entryValues = {};
    for storeName, count in pairs(self.entries) do
        table.insert(entryValues, storeName .. "." .. count);
    end

    return self.storageId .. ":" .. table.concat(entryValues, ",");
end
