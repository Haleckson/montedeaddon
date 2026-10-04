--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local PlayerProfessionsMessage = _G.professionMaster:CreateModel("player-professions-message");
PlayerProfessionsMessage.prefix = "S";

--- Create message model.
function PlayerProfessionsMessage:Create(professionId, storageId, playerName, skills)
    -- store values
    local message = {
        professionId = professionId,
        storageId = storageId,
        playerName = playerName,
        skills = skills
    };

    -- message created
    setmetatable(message, PlayerProfessionsMessage);
    return message;
end

--- Parse message from string.
function PlayerProfessionsMessage:Parse(value)
    -- split values an prepare message
    local messageService = self:GetService("message");
    local values = messageService:SplitString(value, ":");
    local message = {
        professionId = tonumber(values[1]),
        storageId = values[2],
        playerName = values[3],
        skills = {}
    };

    -- parse skill ids (itemId looked up locally from PM_Skills)
    local skills = messageService:SplitString(values[4], ",");
    for skillIndex = 1, #skills do
        table.insert(message.skills, {
            skillId = tonumber(skills[skillIndex])
        });
    end

    -- message parsed
    setmetatable(message, PlayerProfessionsMessage);
    return message;
end

--- Convert message to string.
function PlayerProfessionsMessage:ToString()
    -- combine skill ids (itemId omitted, deterministic from PM_Skills)
    local skillValues = {};
    for i, skill in ipairs(self.skills) do
        skillValues[i] = skill.skillId;
    end

    -- build message
    return table.concat({
        self.professionId,
        self.storageId,
        self.playerName,
        table.concat(skillValues, ",")
    }, ":");  
end

