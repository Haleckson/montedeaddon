--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ProfessionStoreService = _G.professionMaster:CreateService("profession-store");

--- Initialize service.
function ProfessionStoreService:Initialize()
    -- clean up own character set (remove cross-faction entries from old migrations)
    self:CleanupOwnCharacterSet();

    -- calculate initial data fingerprint
    self:UpdateFingerprint();
end

--- Calculate and store the data fingerprint for all guild data.
--- The fingerprint is a compact string that changes whenever skill data changes.
--- Used in Hello messages to quickly detect if two players are already in sync.
function ProfessionStoreService:UpdateFingerprint()
    -- count total skills and compute a simple checksum across all guildmates
    local guildmates = self:GetService("player").node.guildmates;
    local totalCount = 0;
    local checksum = 0;

    -- iterate all stored guildmate skills
    for _, professions in pairs(guildmates) do
        for _, skillIds in pairs(professions) do
            for _, skillId in ipairs(skillIds) do
                totalCount = totalCount + 1;
                checksum = (checksum + skillId) % 1000000;
            end
        end
    end

    -- fingerprint = count + checksum (detects additions, removals, and swaps)
    self.dataFingerprint = totalCount .. "." .. checksum;
end

--- Store character set.
function ProfessionStoreService:StoreCharacterSet(characterNames)
    -- check new names
    if (not characterNames or #characterNames == 0) then
        return;
    end

    -- convert to full names (Name-Realm format)
    local playerService = self:GetService('player');
    for i = 1, #characterNames do
        characterNames[i] = playerService:GetLongName(characterNames[i]);
    end

    -- find existing character set
    local existingCharacterSet = nil;
    for _, newCharacterName in ipairs(characterNames) do
        existingCharacterSet = playerService:FindCharacterSet(newCharacterName);
        if (existingCharacterSet) then
            break;
        end
    end

    -- check if existing found
    if (existingCharacterSet) then
        -- replace existing set with new names (removes stale cross-faction entries)
        for i = #existingCharacterSet, 1, -1 do
            table.remove(existingCharacterSet, i);
        end
        for _, newCharacterName in ipairs(characterNames) do
            table.insert(existingCharacterSet, newCharacterName);
        end

        -- invalidate lookup index
        playerService:InvalidateCharacterSetIndex();
        return;
    end

    -- create new character set
    table.insert(playerService.node.characterSets, characterNames);

    -- invalidate lookup index
    playerService:InvalidateCharacterSetIndex();
end

--- Remove characters from own character set that don't belong in this faction node.
-- Fixes stale cross-faction entries left over from old migrations.
function ProfessionStoreService:CleanupOwnCharacterSet()
    local playerService = self:GetService("player");
    local currentPlayer = playerService.current;

    -- find the character set containing the current player
    local ownSet = playerService:FindCharacterSet(currentPlayer);
    if (not ownSet) then
        return;
    end

    -- build lookup of persisted guild members (live roster may not be available yet)
    local persistedMembers = {};
    if (playerService.guildName) then
        local guildEntry = playerService.node.guilds[playerService.guildName];
        if (guildEntry and guildEntry.members) then
            persistedMembers = guildEntry.members;
        end
    end

    -- collect names that actually belong to this node
    local validNames = {};
    local removedAny = false;
    for i = 1, #ownSet do
        local name = ownSet[i];

        -- valid if: current player, own character, or in persisted guild members
        if (playerService:IsCurrentPlayer(name) or playerService.node.own[name] or persistedMembers[name]) then
            table.insert(validNames, name);
        else
            -- stale entry (cross-faction or leftover) — also remove from guildmates data
            if (playerService.node.guildmates[name]) then
                playerService.node.guildmates[name] = nil;
                self.addon:Log("ProfessionStoreService", "CleanupOwnCharacterSet", "Removed stale guildmates data for '%s'", name);
            end
            self.addon:Log("ProfessionStoreService", "CleanupOwnCharacterSet", "Removed stale entry '%s' from own character set", name);
            removedAny = true;
        end
    end

    -- replace set contents if anything was removed
    if (removedAny) then
        for i = #ownSet, 1, -1 do
            table.remove(ownSet, i);
        end
        for _, name in ipairs(validNames) do
            table.insert(ownSet, name);
        end
    end
end

--- Store player skills.
function ProfessionStoreService:StorePlayerSkills(playerName, professionId, skills)
    -- first aid is not a tracked profession (nearby crafting and profession
    -- links can resolve to it)
    if (professionId == 129) then
        return;
    end

    -- get player service and node
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    local skillTimes = playerService.node.skillTimes;
    local storeName = playerService:GetLongName(playerName);

    -- ensure player entry exists
    if (not guildmates[storeName]) then
        guildmates[storeName] = {};
    end
    if (not guildmates[storeName][professionId]) then
        guildmates[storeName][professionId] = {};
    end
    local playerSkills = guildmates[storeName][professionId];

    -- ensure skill times entry exists (one timestamp per profession)
    if (not skillTimes[storeName]) then
        skillTimes[storeName] = {};
    end

    -- track when we last received data for this guildmate (reuses syncTimes)
    local fullName = playerService:GetLongName(storeName);
    playerService.node.syncTimes[fullName] = time();

    -- get query service for skill index updates
    local queryService = self:GetService("profession-query");

    -- ensure skill index entries exist
    if (not queryService.skillIndex[professionId]) then
        queryService.skillIndex[professionId] = {};
    end

    -- get skills service
    local skillsService = self:GetService("skills");

    -- build lookup of already stored skills (avoids O(n²) contains scans during bulk sync)
    local existingSkillIds = {};
    for _, existingSkillId in ipairs(playerSkills) do
        existingSkillIds[existingSkillId] = true;
    end

    -- check skills
    local addedAny = false;
    local addedCount = 0;
    for _, skill in ipairs(skills) do
        -- skip gathering skills (auto-learned, not synced) and first aid ids
        -- (older versions synced them as tailoring or alchemy skills)
        if (skill.skillId < 9000000 and not skillsService:IsFirstAidSkill(skill.skillId)) then
            -- resolve itemId from local skill data if not provided on wire
            local itemId = skill.itemId;
            if (not itemId or itemId == 0) then
                local knownSkill = skillsService:GetSkillById(skill.skillId);
                itemId = (knownSkill and knownSkill.itemId) or 0;
            end

            -- ensure skill cache entry exists
            skillsService:EnsureSkillCached(skill.skillId, itemId, professionId);

            -- add skill if not exist
            if (not existingSkillIds[skill.skillId]) then
                existingSkillIds[skill.skillId] = true;
                table.insert(playerSkills, skill.skillId);

                -- update reverse index
                if (not queryService.skillIndex[professionId][skill.skillId]) then
                    queryService.skillIndex[professionId][skill.skillId] = {};
                end
                table.insert(queryService.skillIndex[professionId][skill.skillId], storeName);
                addedAny = true;
                addedCount = addedCount + 1;
            end
        end
    end

    -- bump index version so derived caches (view lists) pick up the new data
    if (addedAny) then
        queryService:NoteIndexUpdated();

        -- record when this profession last changed (drives the sync delta)
        skillTimes[storeName][professionId] = time();

        -- collect for the burst summary logged by ScheduleRefresh (keeps the
        -- log at one line per sync burst instead of one per message)
        self.pendingLogSkills = (self.pendingLogSkills or 0) + addedCount;
        if (not self.pendingLogPlayers) then
            self.pendingLogPlayers = {};
        end
        self.pendingLogPlayers[storeName] = true;
    end

    -- debounced refresh of professions view and fingerprint update (5s to avoid lag during bulk sync)
    self:ScheduleRefresh();
end

--- Debounced fingerprint update and professions view refresh (5s).
--- Bulk changes (login sync, data reset bursts) collapse into a single update.
function ProfessionStoreService:ScheduleRefresh()
    if (self.refreshPending) then
        self.refreshPending:Cancel();
    end
    self.refreshPending = C_Timer.NewTimer(5, function()
        self.refreshPending = nil;

        -- one summary line for the whole burst (login syncs collapse here)
        if (self.pendingLogSkills and self.pendingLogSkills > 0) then
            local playerCount = 0;
            for _ in pairs(self.pendingLogPlayers) do
                playerCount = playerCount + 1;
            end
            self.addon:Log("ProfessionStoreService", "ScheduleRefresh", "Stored %d new skills for %d players", self.pendingLogSkills, playerCount);
            self.pendingLogSkills = 0;
            self.pendingLogPlayers = {};
        end

        -- recalculate fingerprint after data changed
        self:UpdateFingerprint();

        -- refresh view
        if (self.addon.professionsView) then
            self.addon.professionsView:Refresh();
        end
    end);
end
