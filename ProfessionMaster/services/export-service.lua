--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ExportService = _G.professionMaster:CreateService("export");

-- signature used for Discord Bot export to verify data integrity
local EXPORT_SIGNATURE = "a7f3c9e2b1d4058f6a9c3e7b2d5f";

-- gathering skill threshold (skills >= this are gathering and excluded from export)
local GATHERING_SKILL_THRESHOLD = 9000000;

--- Collect skill-to-players map for a given guild.
-- @param guildName The name of the guild to collect skills for.
-- @return Table mapping skillId to array of player short names.
function ExportService:CollectGuildSkills(guildName)
    -- get player service
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    local guilds = playerService.node.guilds;

    -- check if guild exists
    local guildEntry = guilds[guildName];
    if (not guildEntry or not guildEntry.members) then
        return {};
    end

    -- collect all guild member store names
    local guildMemberStoreNames = {};
    for memberName, _ in pairs(guildEntry.members) do
        local storeName = playerService:GetLongName(memberName);
        guildMemberStoreNames[storeName] = true;
    end

    -- collect skills grouped by skillId across all guild members
    local skillsByPlayer = {};
    for storeName, professions in pairs(guildmates) do

        -- check if player is in this guild
        if (guildMemberStoreNames[storeName]) then

            -- iterate all professions of this player
            for _, skillIds in pairs(professions) do

                -- iterate all skills
                for _, skillId in ipairs(skillIds) do

                    -- skip gathering skills
                    if (skillId < GATHERING_SKILL_THRESHOLD) then

                        -- initialize skill entry if needed
                        if (not skillsByPlayer[skillId]) then
                            skillsByPlayer[skillId] = {};
                        end

                        -- add realm-short player name for export display
                        local shortName = playerService:GetRealmShortName(storeName);
                        table.insert(skillsByPlayer[skillId], shortName);
                    end
                end
            end
        end
    end

    return skillsByPlayer;
end

--- Build the Discord Bot export string for a given guild (base64 encoded with metadata header).
-- @param guildName The name of the guild to export.
-- @return Base64 encoded export string.
function ExportService:BuildDiscordBotExport(guildName)
    -- get services
    local playerService = self:GetService("player");
    local cryptoService = self:GetService("crypto");

    -- collect skills
    local skillsByPlayer = self:CollectGuildSkills(guildName);

    -- build parts array with metadata header
    local parts = {};
    table.insert(parts, guildName);
    table.insert(parts, playerService.realmName);
    table.insert(parts, self.addon.version);
    table.insert(parts, tostring(self.addon.expansionId or 0));
    table.insert(parts, EXPORT_SIGNATURE);

    -- append skill data (skillId followed by comma-separated player names)
    for skillId, players in pairs(skillsByPlayer) do
        table.insert(parts, tostring(skillId));
        table.insert(parts, table.concat(players, ","));
    end

    -- join all parts with semicolon and encode to base64
    local rawString = table.concat(parts, ";");
    return cryptoService:EncodeBase64(rawString);
end

--- Build the plain text list export for a given guild (one skill per line).
-- @param guildName The name of the guild to export.
-- @return Plain text export string with newline-separated entries.
function ExportService:BuildListExport(guildName)
    -- collect skills
    local skillsByPlayer = self:CollectGuildSkills(guildName);

    -- build lines: skillId;player1,player2
    local lines = {};
    for skillId, players in pairs(skillsByPlayer) do
        table.insert(lines, tostring(skillId) .. ";" .. table.concat(players, ","));
    end

    -- join with newlines
    return table.concat(lines, "\n");
end

--- Build the export string based on the selected format.
-- @param guildName The name of the guild to export.
-- @param format The export format ("list" or "discord").
-- @return Formatted export string.
function ExportService:BuildExport(guildName, format)
    -- check format selection
    if (format == "list") then
        return self:BuildListExport(guildName);
    end

    -- default to discord bot format
    return self:BuildDiscordBotExport(guildName);
end
