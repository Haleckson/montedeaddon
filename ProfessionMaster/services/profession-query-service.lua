--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ProfessionQueryService = _G.professionMaster:CreateService("profession-query");

-- chunked rebuild tuning: skill entries per tick, tick interval and coalesce delay
local REBUILD_ENTRY_BUDGET = 4000;
local REBUILD_TICK_INTERVAL = 0.05;
local REBUILD_COALESCE_DELAY = 0.2;

--- Initialize service.
function ProfessionQueryService:Initialize()
    -- start with an empty index; the initial build runs chunked in the background
    self.skillIndex = {};
    self.indexVersion = 0;

    -- build reverse skill index from stored guildmates data (deferred, chunked)
    self:ScheduleRebuild();
end

--- Note that index-relevant data changed outside a full rebuild.
--- Bumps the version so derived caches refresh and flags a running chunked
--- rebuild as stale (it re-runs once to pick up the change).
function ProfessionQueryService:NoteIndexUpdated()
    self.indexVersion = self.indexVersion + 1;
    if (self.rebuildWork) then
        self.rebuildDirty = true;
    end
end

--- Schedule a chunked skill index rebuild.
--- Coalesces bursts (login sync, roster purges) into a single rebuild and keeps
--- each execution slice small so the client watchdog never triggers.
function ProfessionQueryService:ScheduleRebuild()
    -- cancel scheduled and running rebuilds (data changed, their result would be stale)
    self:CancelRebuild();

    self.rebuildTimer = C_Timer.NewTimer(REBUILD_COALESCE_DELAY, function()
        self.rebuildTimer = nil;
        self:StartChunkedRebuild();
    end);
end

--- Cancel any scheduled or running rebuild.
function ProfessionQueryService:CancelRebuild()
    if (self.rebuildTimer) then
        self.rebuildTimer:Cancel();
        self.rebuildTimer = nil;
    end
    if (self.rebuildTicker) then
        self.rebuildTicker:Cancel();
        self.rebuildTicker = nil;
    end
    self.rebuildWork = nil;
    self.rebuildDirty = false;
end

--- Start a chunked rebuild driven by a ticker (each tick gets a fresh execution budget).
function ProfessionQueryService:StartChunkedRebuild()
    self.rebuildWork = self:CreateRebuildWork();
    self.rebuildDirty = false;
    self.rebuildTicker = C_Timer.NewTicker(REBUILD_TICK_INTERVAL, function()
        local work = self.rebuildWork;
        if (not work) then
            return;
        end
        if (self:RunRebuildStep(work, REBUILD_ENTRY_BUDGET)) then
            self:FinishRebuild(work, true);
        end
    end);
end

--- Create rebuild work state with snapshots of the player name lists.
--- Snapshots avoid undefined pairs() behavior when sync adds players mid-build;
--- players added after the snapshot are picked up via the dirty re-run.
function ProfessionQueryService:CreateRebuildWork()
    local playerService = self:GetService("player");
    local guildmateNames = {};
    for playerName in pairs(playerService.node.guildmates) do
        guildmateNames[#guildmateNames + 1] = playerName;
    end
    local ownNames = {};
    for characterName in pairs(playerService.node.own) do
        ownNames[#ownNames + 1] = characterName;
    end
    return {
        index = {},
        guildmateNames = guildmateNames,
        ownNames = ownNames,
        guildmatePos = 1,
        ownPos = 1
    };
end

--- Process one slice of a rebuild: professionId → skillId → { playerName, ... }
-- @param work Rebuild work state.
-- @param budget Number of skill entries to process in this step.
-- @return true when the rebuild is complete.
function ProfessionQueryService:RunRebuildStep(work, budget)
    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local guildmates = playerService.node.guildmates;
    local ownCharacters = playerService.node.own;
    local index = work.index;

    -- iterate guildmates (players removed after the snapshot are skipped)
    while (budget > 0 and work.guildmatePos <= #work.guildmateNames) do
        local playerName = work.guildmateNames[work.guildmatePos];
        work.guildmatePos = work.guildmatePos + 1;
        budget = budget - 1;

        local professions = guildmates[playerName];
        if (professions) then
            for storedProfessionId, skillIds in pairs(professions) do
                budget = budget - #skillIds;
                for _, skillId in ipairs(skillIds) do
                    -- skip gathering skills (auto-learned, not synced)
                    if (skillId < 9000000) then
                        -- a skill the guild member knows must be listed even when the
                        -- content phase setting is behind (same as for own characters)
                        skillsService:EnsureSkillCached(skillId, 0, storedProfessionId);

                        -- use profession from skill model if available (fixes mismatched storage)
                        local skillData = skillsService:GetSkillById(skillId);
                        local professionId = (skillData and skillData.professionId) or storedProfessionId;

                        -- ensure index tables exist
                        local professionIndex = index[professionId];
                        if (not professionIndex) then
                            professionIndex = {};
                            index[professionId] = professionIndex;
                        end
                        local skillPlayers = professionIndex[skillId];
                        if (not skillPlayers) then
                            skillPlayers = {};
                            professionIndex[skillId] = skillPlayers;
                        end

                        skillPlayers[#skillPlayers + 1] = playerName;
                    end
                end
            end
        end
    end
    if (work.guildmatePos <= #work.guildmateNames) then
        return false;
    end

    -- iterate own characters (ensures own skills always appear even without guild membership)
    while (budget > 0 and work.ownPos <= #work.ownNames) do
        local characterName = work.ownNames[work.ownPos];
        work.ownPos = work.ownPos + 1;
        budget = budget - 1;

        local professions = ownCharacters[characterName];

        -- union with the synced copy indexed by the guildmates loop above: the
        -- own store is authoritative for what was scanned on this computer,
        -- the synced copy may know skills learned on another one; a stale
        -- synced copy alone must never hide own skills
        if (professions) then
            -- collect skill ids the guildmates loop already indexed for this character
            local indexedSkillIds = nil;
            local syncedProfessions = guildmates[characterName];
            if (syncedProfessions) then
                indexedSkillIds = {};
                for _, syncedSkillIds in pairs(syncedProfessions) do
                    for _, syncedSkillId in ipairs(syncedSkillIds) do
                        indexedSkillIds[syncedSkillId] = true;
                    end
                end
            end

            for professionId, skills in pairs(professions) do
                budget = budget - #skills;
                for _, skill in ipairs(skills) do
                    -- skip gathering skills (auto-learned, not synced) and skills already indexed
                    if (skill.skillId < 9000000 and not (indexedSkillIds and indexedSkillIds[skill.skillId])) then
                        -- ensure skill cache entry exists
                        skillsService:EnsureSkillCached(skill.skillId, skill.itemId or 0, professionId);

                        -- ensure index tables exist
                        local professionIndex = index[professionId];
                        if (not professionIndex) then
                            professionIndex = {};
                            index[professionId] = professionIndex;
                        end
                        local skillPlayers = professionIndex[skill.skillId];
                        if (not skillPlayers) then
                            skillPlayers = {};
                            professionIndex[skill.skillId] = skillPlayers;
                        end

                        skillPlayers[#skillPlayers + 1] = characterName;
                    end
                end
            end
        end
    end
    return work.ownPos > #work.ownNames;
end

--- Swap in the finished index and refresh dependent caches.
-- @param work Completed rebuild work state.
-- @param refreshView Refresh the professions view when done (chunked path only).
function ProfessionQueryService:FinishRebuild(work, refreshView)
    -- stop the ticker
    if (self.rebuildTicker) then
        self.rebuildTicker:Cancel();
        self.rebuildTicker = nil;
    end
    self.rebuildWork = nil;

    -- swap index and bump version so consumers drop derived caches
    self.skillIndex = work.index;
    self.indexVersion = self.indexVersion + 1;

    -- the underlying player data changed, drop derived visibility results
    self:GetService("player"):InvalidateVisiblePlayerCache();
    self.addon:Log("ProfessionQueryService", "FinishRebuild", "Rebuilt skill index (%d guildmates, %d own characters)", #work.guildmateNames, #work.ownNames);

    -- data changed while building (e.g. sync burst): run again to pick it up
    if (self.rebuildDirty) then
        self.rebuildDirty = false;
        self:ScheduleRebuild();
    end

    -- refresh view
    if (refreshView and self.addon.professionsView) then
        self.addon.professionsView:Refresh();
    end
end

--- Build the reverse skill index synchronously.
--- Only for interactive callers (purge command, cache refresh) — login-time and
--- sync-driven callers must use ScheduleRebuild to stay inside the execution budget.
function ProfessionQueryService:RebuildSkillIndex()
    self:CancelRebuild();
    local work = self:CreateRebuildWork();
    self:RunRebuildStep(work, math.huge);
    self:FinishRebuild(work, false);
end

--- Check if a skill has at least one visible player (cached).
--- Intermediate layer over PlayerService:HasVisiblePlayers: list views ask this
--- for every skill on every refresh, so results are cached per skill until the
--- index or the visibility data changes.
-- @param professionId Profession ID.
-- @param skillId Skill ID.
-- @param players Optional player list (defaults to the indexed players).
-- @return boolean
function ProfessionQueryService:HasVisibleSkillPlayers(professionId, skillId, players)
    local playerService = self:GetService("player");

    -- reset cache when index or visibility data changed
    local cache = self.visibleSkillCache;
    if (not cache or cache.indexVersion ~= self.indexVersion or cache.visibilityVersion ~= playerService.visibilityVersion) then
        cache = { indexVersion = self.indexVersion, visibilityVersion = playerService.visibilityVersion, professions = {} };
        self.visibleSkillCache = cache;
    end

    -- get profession cache
    local professionCache = cache.professions[professionId];
    if (not professionCache) then
        professionCache = {};
        cache.professions[professionId] = professionCache;
    end

    -- use cached result
    local cached = professionCache[skillId];
    if (cached ~= nil) then
        return cached;
    end

    local visible = playerService:HasVisiblePlayers(players or self:GetSkillPlayers(professionId, skillId));
    professionCache[skillId] = visible;
    return visible;
end

--- Check whether any visible player besides the own characters has shared
--- profession data. The guild list shows its empty state without it: own
--- skills alone are no guild data (cached until the index or the visibility
--- data changes).
-- @return boolean
function ProfessionQueryService:HasGuildData()
    local playerService = self:GetService("player");

    -- use cached result
    local cache = self.guildDataCache;
    if (cache and cache.indexVersion == self.indexVersion and cache.visibilityVersion == playerService.visibilityVersion) then
        return cache.hasData;
    end

    -- look for a visible foreign player with at least one crafting skill
    -- (gathering skills are not listed in the guild list)
    local hasData = false;
    for playerName, professions in pairs(playerService.node.guildmates) do
        if (not playerService:IsCurrentPlayer(playerName) and not playerService:IsOwnPlayer(playerName)
            and playerService:IsVisiblePlayer(playerName)) then
            for _, skillIds in pairs(professions) do
                for _, skillId in ipairs(skillIds) do
                    if (skillId < 9000000) then
                        hasData = true;
                        break;
                    end
                end
                if (hasData) then break; end
            end
        end
        if (hasData) then break; end
    end

    self.guildDataCache = { indexVersion = self.indexVersion, visibilityVersion = playerService.visibilityVersion, hasData = hasData };
    self.addon:Log("ProfessionQueryService", "HasGuildData", "Guild data available: %s", tostring(hasData));
    return hasData;
end

--- Get player list for a skill (from reverse index).
-- @param professionId Profession ID.
-- @param skillId Skill ID.
-- @return players array or empty table.
function ProfessionQueryService:GetSkillPlayers(professionId, skillId)
    if (self.skillIndex[professionId] and self.skillIndex[professionId][skillId]) then
        return self.skillIndex[professionId][skillId];
    end
    return {};
end

--- Get the crafters of a skill for the !who answers: whether an own character
--- can craft it and the guild members that can, online ones first and each
--- group sorted by name so every guild member sees the same order.
-- @param professionId Profession ID.
-- @param skillId Skill ID.
-- @return { own = boolean, players = { fullName, ... }, online = { fullName, ... } }
function ProfessionQueryService:GetSkillCrafters(professionId, skillId)
    local playerService = self:GetService("player");
    local messageService = self:GetService("message");
    local crafters = { own = false, players = {}, online = {} };
    local offline = {};
    for _, playerName in ipairs(self:GetSkillPlayers(professionId, skillId)) do
        local fullName = playerService:GetLongName(playerName);
        if (playerService:IsOwnPlayer(fullName)) then
            crafters.own = true;
        elseif (playerService:IsGuildmate(fullName)) then
            if (messageService:IsPlayerOnline(fullName)) then
                table.insert(crafters.online, fullName);
            else
                table.insert(offline, fullName);
            end
        end
    end
    table.sort(crafters.online);
    table.sort(offline);
    for _, fullName in ipairs(crafters.online) do
        table.insert(crafters.players, fullName);
    end
    for _, fullName in ipairs(offline) do
        table.insert(crafters.players, fullName);
    end
    return crafters;
end

--- Find skills by free text for the !who command. Every word must occur in
--- the skill name, or the text without spaces in the name without spaces
--- ("spell power" finds "Spellpower" and the other way round). Only skills
--- with at least one indexed crafter count, exact names and skills with more
--- crafters come first. Recipes that only work on the equipment of the crafter
--- are left out and counted instead, nobody can make them for the requester.
-- @param text Search text.
-- @return list of { skillId, professionId, skillData }, best match first, and
--- the number of matches dropped as self only.
function ProfessionQueryService:FindSkillsByText(text)
    local messageService = self:GetService("message");
    local searchText = string.lower(messageService:TrimString(text or ""));
    if (string.len(searchText) < 3) then
        return {}, 0;
    end

    -- search words as plain patterns (chat text may carry magic characters)
    local parts = {};
    for part in string.gmatch(searchText, "%S+") do
        table.insert(parts, (string.gsub(part, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")));
    end
    local compactSearch = (string.gsub(searchText, "%s+", ""));

    -- collect matching skills that somebody can craft
    local skillsService = self:GetService("skills");
    local matches = {};
    local selfOnlyCount = 0;
    for skillId, skillData in pairs(skillsService.allSkills) do
        local skillName = skillData.name;
        if (skillName and skillId < 9000000) then
            local lowerName = string.lower(skillName);
            local matched = true;
            for _, part in ipairs(parts) do
                if (not string.find(lowerName, part)) then
                    matched = false;
                    break;
                end
            end
            if (not matched) then
                matched = string.find((string.gsub(lowerName, "%s+", "")), compactSearch, 1, true) ~= nil;
            end
            if (matched and skillsService:IsSelfOnlySkill(skillId)) then
                -- only the crafter can use it, count it so the answer can say so
                matched = false;
                selfOnlyCount = selfOnlyCount + 1;
            end

            if (matched) then
                local professionId = skillData.professionId;
                local playerCount = #self:GetSkillPlayers(professionId, skillId);
                if (playerCount > 0) then
                    table.insert(matches, {
                        skillId = skillId,
                        professionId = professionId,
                        skillData = skillData,
                        exact = (lowerName == searchText),
                        playerCount = playerCount
                    });
                end
            end
        end
    end
    table.sort(matches, function(a, b)
        if (a.exact ~= b.exact) then
            return a.exact;
        end
        if (a.playerCount ~= b.playerCount) then
            return a.playerCount > b.playerCount;
        end
        return a.skillData.name < b.skillData.name;
    end);
    return matches, selfOnlyCount;
end

--- Find skill by item link.
-- @return skillId, skillData, professionId or nil.
function ProfessionQueryService:FindSkillByItemLink(itemLink)
    -- check input
    if (not itemLink) then
        return nil;
    end

    -- extract item id from link using pattern match (avoids SplitString allocation)
    local itemId = tonumber(itemLink:match("item:(%d+)"));
    if ((not itemId) or itemId == 0) then
        return nil;
    end

    -- use skills service for O(1) lookup
    local skillsService = self:GetService("skills");
    local skillId = skillsService:GetSkillIdByItemId(itemId);
    if (skillId) then
        local skillData = skillsService:GetSkillById(skillId);
        if (skillData) then
            return skillId, skillData, skillData.professionId;
        end
    end

    -- check if item is a recipe
    local recipeSkillId = skillsService:GetSkillIdByRecipeItemId(itemId);
    if (recipeSkillId) then
        local skillData = skillsService:GetSkillById(recipeSkillId);
        if (skillData) then
            return recipeSkillId, skillData, skillData.professionId;
        end
    end

    return nil;
end

--- Find skill by skill id or item id.
-- @param targetSkillId Skill id to find (optional if item id provided).
-- @param targetItemId Item id to find (optional if skill id provided).
-- @return skillId, skillData, professionId or nil.
function ProfessionQueryService:FindSkillByIdOrItemId(targetSkillId, targetItemId)
    -- check values
    if ((not targetSkillId) and (not targetItemId)) then
        return nil;
    end

    local skillsService = self:GetService("skills");

    -- try item id lookup (O(1))
    if (targetItemId) then
        local skillId = skillsService:GetSkillIdByItemId(targetItemId);
        if (skillId) then
            local skillData = skillsService:GetSkillById(skillId);
            if (skillData) then
                return skillId, skillData, skillData.professionId;
            end
        end
    end

    -- try direct skill id lookup
    if (targetSkillId) then
        local skillData = skillsService:GetSkillById(targetSkillId);
        if (skillData) then
            return targetSkillId, skillData, skillData.professionId;
        end
    end
    return nil;
end

--- Find skill by skill name.
-- @return skillId, skillData, professionId or nil.
function ProfessionQueryService:FindSkillByName(skillName)
    -- check input
    if (not skillName) then
        return nil;
    end

    -- find separator
    local separatorPos = string.find(skillName, ":");
    if (not separatorPos or separatorPos < 2) then
        return nil;
    end

    -- get profession and skill name parts
    local professionName = string.sub(skillName, 1, separatorPos - 1);
    local targetSkillName = string.sub(skillName, separatorPos + 1);

    -- find profession id by name
    local professionId = self:GetService("profession-names"):GetProfessionId(professionName);
    if (not professionId) then
        return nil;
    end

    -- trim whitespace from skill name
    targetSkillName = string.trim(targetSkillName);

    -- search skills for matching name and profession
    local skillsService = self:GetService("skills");
    for skillId, skillData in pairs(skillsService.allSkills) do
        if (skillData.professionId == professionId and skillData.name and skillData.name == targetSkillName) then
            return skillId, skillData, professionId;
        end
    end
end
