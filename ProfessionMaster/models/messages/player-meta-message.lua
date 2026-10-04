--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local PlayerMetaMessage = _G.professionMaster:CreateModel("player-meta-message");
PlayerMetaMessage.prefix = "PM";

--- Create message model.
-- @param storeName Short player name.
-- @param specializations Table of { [professionId] = spellId } or nil.
-- @param cooldowns Table of { [spellId] = expires } or nil.
function PlayerMetaMessage:Create(storeName, specializations, cooldowns)
    local message = {
        storeName = storeName,
        specializations = specializations or {},
        cooldowns = cooldowns or {}
    };
    setmetatable(message, PlayerMetaMessage);
    return message;
end

--- Parse message from string.
-- Format: storeName:specs|cooldowns
-- Specs: profId.spellId,profId.spellId
-- Cooldowns: spellId.expires,spellId.expires
function PlayerMetaMessage:Parse(value)
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        storeName = values[1],
        specializations = {},
        cooldowns = {}
    };

    -- remaining content is sections separated by |
    local content = values[2] or "";
    local sections = { "", "" };
    local sectionIndex = 1;
    for i = 1, #content do
        local char = string.sub(content, i, i);
        if (char == "|") then
            sectionIndex = sectionIndex + 1;
        else
            sections[sectionIndex] = sections[sectionIndex] .. char;
        end
    end

    -- parse specializations section
    if (sections[1] ~= "") then
        local specParts = messageService:SplitString(sections[1], ",");
        for i = 1, #specParts do
            local dotPos = string.find(specParts[i], ".", 1, true);
            if (dotPos) then
                local professionId = tonumber(string.sub(specParts[i], 1, dotPos - 1));
                local spellId = tonumber(string.sub(specParts[i], dotPos + 1));
                if (professionId and spellId) then
                    message.specializations[professionId] = spellId;
                end
            end
        end
    end

    -- parse cooldowns section
    if (sections[2] ~= "") then
        local cdParts = messageService:SplitString(sections[2], ",");
        for i = 1, #cdParts do
            local dotPos = string.find(cdParts[i], ".", 1, true);
            if (dotPos) then
                local spellId = tonumber(string.sub(cdParts[i], 1, dotPos - 1));
                local expires = tonumber(string.sub(cdParts[i], dotPos + 1));
                if (spellId and expires) then
                    message.cooldowns[spellId] = expires;
                end
            end
        end
    end

    setmetatable(message, PlayerMetaMessage);
    return message;
end

--- Convert message to string.
function PlayerMetaMessage:ToString()
    -- build specializations section
    local specValues = {};
    for professionId, spellId in pairs(self.specializations) do
        table.insert(specValues, professionId .. "." .. spellId);
    end

    -- build cooldowns section
    local cdValues = {};
    for spellId, expires in pairs(self.cooldowns) do
        table.insert(cdValues, spellId .. "." .. expires);
    end

    -- combine: storeName:specs|cooldowns
    return self.storeName .. ":" .. table.concat(specValues, ",") .. "|" .. table.concat(cdValues, ",");
end
