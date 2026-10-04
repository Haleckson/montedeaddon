--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local PurgeService = _G.professionMaster:CreateService("purge");

--- Initialize service.
function PurgeService:Initialize()
    -- days without a logged in own member before a guild and its data are dropped
    self.GuildRetentionDays = 60;
end

--- Purge guilds no own character has been seen in for the retention period,
--- together with all stored players that belong to no kept guild any more.
--- Data of the current guild, own characters and their linked alts always
--- stays. Runs once per session as soon as the current guild is known.
function PurgeService:CheckStaleGuildCleanup()
    if (self.staleGuildCleanupDone) then
        return;
    end

    -- wait until the current guild name is known (can lag at login)
    local playerService = self:GetService("player");
    if (IsInGuild() and not playerService.guildName) then
        return;
    end
    self.staleGuildCleanupDone = true;

    local node = playerService.node;
    local now = time();
    local retention = self.GuildRetentionDays * 24 * 60 * 60;

    -- seed the tracking start: guilds stored by versions without own member
    -- info get one full retention window before they can be purged
    if (not node.guildTrackingSince) then
        node.guildTrackingSince = now;
    end

    -- the current character can only be a member of the current guild
    for otherGuildName, guildEntry in pairs(node.guilds) do
        if (otherGuildName ~= playerService.guildName and guildEntry.ownMembers) then
            guildEntry.ownMembers[playerService.current] = nil;
        end
    end

    -- collect guilds without a recently seen own member; guilds received from
    -- a linked account live as long as the link does
    local staleGuilds = {};
    local staleGuildCount = 0;
    for guildName, guildEntry in pairs(node.guilds) do
        local linked = guildEntry.linkedAccounts and next(guildEntry.linkedAccounts) ~= nil;
        if (guildName ~= playerService.guildName and not linked) then
            local lastSeen = 0;
            for _, seenAt in pairs(guildEntry.ownMembers or {}) do
                if (seenAt > lastSeen) then
                    lastSeen = seenAt;
                end
            end
            if (lastSeen == 0) then
                lastSeen = node.guildTrackingSince;
            end
            if (now - lastSeen > retention) then
                staleGuilds[guildName] = true;
                staleGuildCount = staleGuildCount + 1;
            end
        end
    end

    -- drop the stale guild entries, then everything nobody anchors any more
    for guildName, _ in pairs(staleGuilds) do
        node.guilds[guildName] = nil;
    end
    if (staleGuildCount > 0) then
        self.addon:Log("PurgeService", "CheckStaleGuildCleanup", "Dropped %d stale guilds", staleGuildCount);
    end
    self:PurgeUnanchoredPlayers("CheckStaleGuildCleanup");
end

--- Purge every stored player that no kept guild lists, that is not own, not a
--- character of a linked account and not linked to such a player via a
--- character set. Covers members of dropped guilds and players accumulated
--- without any guild entry (left guilds before member tracking existed).
-- @param context Name of the caller for the log line.
function PurgeService:PurgeUnanchoredPlayers(context)
    local playerService = self:GetService("player");
    local linkService = self:GetService("link");
    local node = playerService.node;

    -- lookup of the members of all kept guilds
    local keptMembers = {};
    for _, guildEntry in pairs(node.guilds) do
        if (guildEntry.members) then
            for memberName, _ in pairs(guildEntry.members) do
                keptMembers[string.lower(playerService:GetLongName(memberName))] = true;
            end
        end
    end

    -- a player is anchored when own, kept guild member or linked account character
    local function isAnchored(fullName)
        return keptMembers[string.lower(fullName)] or playerService:IsOwnCharacter(fullName)
            or linkService:GetLinkedAccountByCharacter(fullName) ~= nil;
    end

    local playersToPurge = {};
    for guildmateName, _ in pairs(node.guildmates) do
        local fullName = playerService:GetLongName(guildmateName);
        local keep = isAnchored(fullName);

        -- keep players whose linked alt is anchored
        if (not keep) then
            local characterSet = playerService:FindCharacterSet(fullName);
            if (characterSet) then
                for _, altName in ipairs(characterSet) do
                    if (isAnchored(playerService:GetLongName(altName))) then
                        keep = true;
                        break;
                    end
                end
            end
        end

        if (not keep) then
            table.insert(playersToPurge, fullName);
        end
    end

    -- purge in one batch and rebuild the skill index in the background
    if (#playersToPurge == 0) then
        return;
    end
    self.addon:Log("PurgeService", "PurgeUnanchoredPlayers", "Purged %d players (%s)", #playersToPurge, tostring(context));
    self:PurgeCharactersSilent(playersToPurge);
    self:PruneOrphanedCharacterSets();
    self:GetService("profession-query"):ScheduleRebuild();
end

--- Remove character sets that no longer contain any stored or own player.
function PurgeService:PruneOrphanedCharacterSets()
    local playerService = self:GetService("player");
    local characterSets = playerService.node.characterSets;
    local removedAny = false;

    for setIndex = #characterSets, 1, -1 do
        local hasStoredPlayer = false;
        for _, characterName in ipairs(characterSets[setIndex]) do
            local fullName = playerService:GetLongName(characterName);
            if (playerService.node.guildmates[fullName] or playerService:IsOwnCharacter(fullName)) then
                hasStoredPlayer = true;
                break;
            end
        end
        if (not hasStoredPlayer) then
            table.remove(characterSets, setIndex);
            removedAny = true;
        end
    end

    if (removedAny) then
        playerService:InvalidateCharacterSetIndex();
    end
end

--- Purge data.
function PurgeService:Purge(context)
    -- get chat service
    local chatService = self:GetService("chat");

    -- check if all data should be purged
    if (context == 'all') then
        -- purge all data
        local playerService = self:GetService("player");

        -- broadcast data resets for own characters so other players drop them too
        for characterName, _ in pairs(playerService.node.own) do
            self:BroadcastDataReset(playerService:GetLongName(characterName), 0);
        end

        playerService.node.guildmates = {};
        playerService.node.own = {};
        playerService.node.syncTimes = {};
        playerService.node.characterSets = {};
        playerService:InvalidateCharacterSetIndex();
        playerService.node.cooldowns = {};
        playerService.node.skillTimes = {};
        playerService.node.cooldownsUpdated = nil;
        playerService.node.specializationsUpdated = nil;
        playerService.node.guilds = {};
        PM_Specializations = {};
        PM_Settings = {};
        PM_Logs = {};
        PM_BucketList = {};
        PM_Frames = {};
        PM_CharacterSettings = {};
        self.addon:CheckSettings();

        -- rebuild reverse index after purge
        self:GetService("profession-query"):RebuildSkillIndex();

        -- refresh professions view
        if (self.addon.professionsView) then
            self.addon.professionsView:Refresh();
        end

        -- send message
        chatService:Write("AllDataPurged");
        return;
    end

    -- check if own data should be purged
    local playerService = self:GetService('player');
    if (context == 'own') then
        self:PurgeCharacter(playerService.current);
        PM_Frames = {};
        PM_CharacterSettings = {}; 
        return;
    end

    -- purge by player name
    self:PurgeCharacter(playerService:GetLongName(context));
end

--- Purge character.
function PurgeService:PurgeCharacter(characterName)
    -- determine ownership before purging (own table entry is removed below)
    local playerService = self:GetService("player");
    local storeName = playerService:GetLongName(characterName);
    local isOwnCharacter = playerService:IsOwnCharacter(storeName);

    -- purge character data silently
    self:PurgeCharacterSilent(characterName);

    -- reset all sync times
    self:GetService("player").node.syncTimes = {};

    -- reset storage id to receive data again
    self:GetService("player").node.storageId = self.addon:GenerateString(12);

    -- rebuild reverse index after purge
    self:GetService("profession-query"):RebuildSkillIndex();

    -- refresh professions view
    if (self.addon.professionsView) then
        self.addon.professionsView:Refresh();
    end

    -- broadcast reset to guild so other players drop the data too (own characters only)
    if (isOwnCharacter) then
        self:BroadcastDataReset(storeName, 0);
    end

    -- send message
    self:GetService("chat"):Write("CharacterPurged", characterName);
end

--- Broadcast a data reset tombstone for an own character to the guild.
-- @param storeName Full name of the character.
-- @param professionId Profession id to reset or 0 for all data.
function PurgeService:BroadcastDataReset(storeName, professionId)
    local playerService = self:GetService("player");
    local timestamp = time();

    -- remember sent reset for re-broadcast on later hello rounds (replace older entries for same scope)
    if (not playerService.node.sentDataResets) then
        playerService.node.sentDataResets = {};
    end
    local sentResets = playerService.node.sentDataResets;
    for i = #sentResets, 1, -1 do
        local entry = sentResets[i];
        if (entry.name == storeName and (professionId == 0 or entry.professionId == professionId)) then
            table.remove(sentResets, i);
        end
    end
    table.insert(sentResets, { name = storeName, professionId = professionId, time = timestamp });

    -- send tombstone to guild and linked accounts (BULK like all data messages, so it can never overtake older queued skill data)
    self:GetService("message"):Broadcast(self:GetModel("player-data-reset-message"):Create(storeName, timestamp, professionId), "BULK");
    self.addon:Log("PurgeService", "BroadcastDataReset", "Broadcasted data reset for %s (professionId=%s)", storeName, tostring(professionId));
end

--- Purge character data without chat output or sync reset.
function PurgeService:PurgeCharacterSilent(characterName)
    self:PurgeCharactersSilent({ characterName });
end

--- Purge several characters' data in one pass over the stored tables.
--- One combined pass keeps roster-leave purges of many players cheap: the old
--- per-character scans made mass purges O(characters × table sizes).
-- @param characterNames Array of character names (with or without realm).
function PurgeService:PurgeCharactersSilent(characterNames)
    if (not characterNames or #characterNames == 0) then
        return;
    end

    -- build lowercase lookup of all name variants (raw and Name-Realm)
    local playerService = self:GetService("player");
    local lowerNames = {};
    for _, characterName in ipairs(characterNames) do
        lowerNames[string.lower(characterName)] = true;
        lowerNames[string.lower(playerService:GetLongName(characterName))] = true;
    end

    -- remove from own professions
    for ownCharacter, _ in pairs(playerService.node.own) do
        if (lowerNames[string.lower(ownCharacter)]) then
            playerService.node.own[ownCharacter] = nil;
        end
    end

    -- remove from guildmates (player-centric: just delete the key)
    for guildmateKey, _ in pairs(playerService.node.guildmates) do
        if (lowerNames[string.lower(guildmateKey)]) then
            playerService.node.guildmates[guildmateKey] = nil;
        end
    end

    -- remove from guildmates (in-memory roster)
    for guildmateName, _ in pairs(playerService.guildmates) do
        if (lowerNames[string.lower(guildmateName)]) then
            playerService.guildmates[guildmateName] = nil;
        end
    end

    -- remove from specializations
    for specializationName, _ in pairs(PM_Specializations) do
        if (lowerNames[string.lower(specializationName)]) then
            PM_Specializations[specializationName] = nil;
        end
    end

    -- remove from persisted guild members
    for _, guildEntry in pairs(playerService.node.guilds) do
        if (guildEntry.members) then
            for memberName, _ in pairs(guildEntry.members) do
                if (lowerNames[string.lower(memberName)]) then
                    guildEntry.members[memberName] = nil;
                end
            end
        end
    end

    -- remove cooldowns for these characters
    for cooldownName, _ in pairs(playerService.node.cooldowns) do
        if (lowerNames[string.lower(cooldownName)]) then
            playerService.node.cooldowns[cooldownName] = nil;
        end
    end

    -- remove skill times for these characters
    for skillTimeName, _ in pairs(playerService.node.skillTimes) do
        if (lowerNames[string.lower(skillTimeName)]) then
            playerService.node.skillTimes[skillTimeName] = nil;
        end
    end

    -- remove sync times for these characters (storage id keys stay untouched)
    for syncTimeName, _ in pairs(playerService.node.syncTimes) do
        if (lowerNames[string.lower(syncTimeName)]) then
            playerService.node.syncTimes[syncTimeName] = nil;
        end
    end

    -- own characters and guildmates changed
    playerService:InvalidateVisiblePlayerCache();
end

