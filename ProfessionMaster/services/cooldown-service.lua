--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local CooldownService = _G.professionMaster:CreateService("cooldown");

--- Initialize service.
function CooldownService:Initialize()
    -- ensure cooldowns node exists in PM_Data
    local playerService = self:GetService("player");
    if (not playerService.node.cooldowns) then
        playerService.node.cooldowns = {};
    end

    -- create cooldown view instance
    self.cooldownView = self.addon:NewView("cooldown");

    -- build known cooldowns cache
    self:RebuildKnownCooldowns();

    -- clean up cross-realm duplicate cooldown entries from connected realms
    self:DeduplicateCooldowns();

    -- scan item cooldowns on login after a short delay and broadcast (only on fresh login)
    C_Timer.After(3, function()
        self:CheckItemCooldowns();
        if (self:GetService("startup").isInitialLogin) then
            self:SendOwnCooldownsToGuild();
        end
    end);

    -- rescan item cooldowns when an item cooldown starts or ends
    self:HandleEvent("BAG_UPDATE_COOLDOWN", function()
        self:ScheduleItemCooldownScan();
    end);

    -- also rescan on spell cooldown update (item use triggers spell cooldown in Classic)
    self:HandleEvent("SPELL_UPDATE_COOLDOWN", function()
        self:ScheduleItemCooldownScan();
    end);

    -- start ticker to check watched cooldowns for real-time expiry notifications
    self.notifiedExpired = {};
    self.previouslyActive = {};
    self:SeedPreviouslyActive();
    self:StartWatchedCooldownTicker();
end

--- Schedule a debounced item cooldown scan.
function CooldownService:ScheduleItemCooldownScan()
    if (self.itemCooldownPending) then
        self.itemCooldownPending:Cancel();
    end
    self.itemCooldownPending = C_Timer.NewTimer(1, function()
        self.itemCooldownPending = nil;
        self:CheckItemCooldowns();
    end);
end

--- Rebuild the cached known cooldowns lookup.
-- Merges cooldown-spells and cooldown-items into a single table.
function CooldownService:RebuildKnownCooldowns()
    local cooldownSpells = self:GetModel("cooldown-spells");
    local cooldownItems = self:GetModel("cooldown-items");

    -- merge all known cooldown spellIds to professionId
    local knownCooldowns = {};
    if (cooldownSpells) then
        for spellId, profId in pairs(cooldownSpells) do
            knownCooldowns[spellId] = profId;
        end
    end
    if (cooldownItems) then
        for _, itemInfo in pairs(cooldownItems) do
            knownCooldowns[itemInfo.spellId] = itemInfo.professionId;
        end
    end

    -- build set of profession IDs that have cooldowns
    local professionIds = {};
    for _, profId in pairs(knownCooldowns) do
        professionIds[profId] = true;
    end

    self.knownCooldowns = knownCooldowns;
    self.cooldownProfessionIds = professionIds;
end

--- Get merged lookup of all known cooldown spellIds to professionId.
-- @return Table { [spellId] = professionId }.
function CooldownService:GetKnownCooldowns()
    return self.knownCooldowns;
end

--- Get set of profession IDs that have at least one known cooldown.
-- @return Table { [professionId] = true }.
function CooldownService:GetCooldownProfessionIds()
    return self.cooldownProfessionIds;
end

--- Remove duplicate cooldown entries caused by connected-realm short-name broadcasts.
-- When the same character appears under multiple realms (e.g. "Aryx-MirageRaceway" and
-- "Aryx-NethergardeKeep" with identical data), keeps only the entry whose full name
-- exists in characterSets. Falls back to keeping the entry with the more recent syncTime.
function CooldownService:DeduplicateCooldowns()
    local playerService = self:GetService("player");
    local cooldownsData = playerService.node.cooldowns;
    if (not cooldownsData) then
        return;
    end

    -- group full names by short name
    local shortNameGroups = {};
    for fullName, _ in pairs(cooldownsData) do
        local shortName = playerService:GetShortName(fullName);
        if (not shortNameGroups[shortName]) then
            shortNameGroups[shortName] = {};
        end
        table.insert(shortNameGroups[shortName], fullName);
    end

    -- for short names with multiple entries, determine the canonical full name
    local removedCount = 0;
    for shortName, fullNames in pairs(shortNameGroups) do
        if (#fullNames > 1) then
            -- find the canonical name: prefer one that exists in characterSets
            local canonicalName = nil;
            for _, fullName in ipairs(fullNames) do
                if (playerService:FindCharacterSet(fullName)) then
                    canonicalName = fullName;
                    break;
                end
            end

            -- fallback: prefer entry from own characters
            if (not canonicalName) then
                for _, fullName in ipairs(fullNames) do
                    if (playerService.node.own[fullName]) then
                        canonicalName = fullName;
                        break;
                    end
                end
            end

            -- fallback: prefer entry with more recent syncTime
            if (not canonicalName) then
                local bestTime = 0;
                for _, fullName in ipairs(fullNames) do
                    local syncTime = playerService.node.syncTimes[fullName] or 0;
                    if (syncTime > bestTime) then
                        bestTime = syncTime;
                        canonicalName = fullName;
                    end
                end
            end

            -- remove all non-canonical entries
            if (canonicalName) then
                for _, fullName in ipairs(fullNames) do
                    if (fullName ~= canonicalName) then
                        cooldownsData[fullName] = nil;
                        removedCount = removedCount + 1;
                    end
                end
            end
        end
    end

    if (removedCount > 0) then
        self.addon:Log("CooldownService", "DeduplicateCooldowns", "Removed %d duplicate cross-realm cooldown entries", removedCount);
    end
end

--- Get cooldown data grouped by spellId, filtered by profession.
-- @param professionId Filter by profession (0 = all professions).
-- @return Table { [spellId] = { {playerName=, expires=}, ... } }.
function CooldownService:GetCooldownGroups(professionId)
    local playerService = self:GetService("player");
    local cooldownsData = playerService.node.cooldowns or {};
    local knownCooldowns = self.knownCooldowns;

    -- deduplicate: track seen short names per spellId to skip cross-realm duplicates
    local spellGroups = {};
    local seenPerSpell = {};
    for playerName, spellCooldowns in pairs(cooldownsData) do
        -- use short name for display
        local shortName = playerService:GetShortName(playerName);
        for spellId, expires in pairs(spellCooldowns) do
            if (knownCooldowns[spellId]) then
                if (professionId == 0 or knownCooldowns[spellId] == professionId) then
                    -- skip if this short name already seen for this spell (cross-realm duplicate)
                    if (not seenPerSpell[spellId]) then
                        seenPerSpell[spellId] = {};
                    end
                    if (not seenPerSpell[spellId][shortName]) then
                        seenPerSpell[spellId][shortName] = true;
                        if (not spellGroups[spellId]) then
                            spellGroups[spellId] = {};
                        end
                        table.insert(spellGroups[spellId], {
                            playerName = shortName,
                            expires = expires,
                        });
                    end
                end
            end
        end
    end

    return spellGroups;
end

--- Check item cooldowns and store/send if changed.
function CooldownService:CheckItemCooldowns()
    local cooldowns = self:ScanItemCooldowns();
    if (cooldowns) then
        local changed = self:StoreOwnCooldowns(cooldowns);
        if (changed) then
            self:SendOwnCooldownsToGuild();
        end
    end
end

--- Scan cooldowns from the currently open trade skill window.
-- Called during TRADE_SKILL_UPDATE processing.
-- @return Table of cooldowns: { [spellId] = expiresTimestamp } or nil if nothing found.
function CooldownService:ScanTradeSkillCooldowns()
    -- get cooldown spells model and trade skill count
    local cooldownSpells = self:GetModel("cooldown-spells");
    local tradeSkillAmount = GetNumTradeSkills();
    local cooldowns = {};
    local found = false;

    -- build reverse lookup: itemId → spellId for cooldown spells only
    local cooldownItemIds = {};
    local skillsService = self:GetService("skills");
    for spellId, _ in pairs(cooldownSpells) do
        local skillData = skillsService.sourceSkills[spellId];
        if (skillData and skillData.itemId) then
            cooldownItemIds[skillData.itemId] = spellId;
        end
    end

    for tradeSkillIndex = 1, tradeSkillAmount do
        local tradeSkillName, tradeSkillType = GetTradeSkillInfo(tradeSkillIndex);
        if (tradeSkillName and tradeSkillType ~= "header") then
            -- get spell id from link
            local tradeSkillLink = GetTradeSkillItemLink(tradeSkillIndex);
            if (not tradeSkillLink) then
                tradeSkillLink = GetTradeSkillRecipeLink(tradeSkillIndex);
            end
            if (tradeSkillLink) then
                local spellId = tonumber(tradeSkillLink:match("enchant:(%d+)"));
                if (not spellId) then
                    local recipeLink = GetTradeSkillRecipeLink(tradeSkillIndex);
                    if (recipeLink) then
                        spellId = self:GetService("profession-names"):GetSkillId(recipeLink);
                    end
                end

                -- fallback: extract item id from item link and match against cooldown spells
                if (not spellId) then
                    local itemId = tonumber(tradeSkillLink:match("item:(%d+)"));
                    if (itemId and cooldownItemIds[itemId]) then
                        spellId = cooldownItemIds[itemId];
                    end
                end

                -- check if this spell has a known cooldown
                if (spellId and cooldownSpells[spellId]) then
                    local cooldownRemaining = GetTradeSkillCooldown(tradeSkillIndex);
                    if (cooldownRemaining and cooldownRemaining > 0) then
                        cooldowns[spellId] = time() + cooldownRemaining;
                    else
                        cooldowns[spellId] = 0;
                    end
                    found = true;
                end
            end
        end
    end

    if (not found) then
        return nil;
    end

    -- log cooldown count
    local cooldownCount = 0;
    for _ in pairs(cooldowns) do
        cooldownCount = cooldownCount + 1;
    end
    self.addon:Log("CooldownService", "ScanTradeSkillCooldowns", "Found %d cooldowns in trade skill window", cooldownCount);

    return cooldowns;
end

--- Scan cooldowns of learned recipes through the modern profession api
--- (C_TradeSkillUI), where recipe ids are the spell ids.
-- @param recipeIds Array of learned recipe ids of the open profession window.
-- @return Table of cooldowns: { [spellId] = expiresTimestamp } or nil if nothing found.
function CooldownService:ScanRecipeCooldowns(recipeIds)
    if (not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeCooldown) then
        return nil;
    end

    local cooldownSpells = self:GetModel("cooldown-spells");
    local cooldowns = {};
    local cooldownCount = 0;
    for _, recipeId in ipairs(recipeIds) do
        if (cooldownSpells[recipeId]) then
            local cooldownRemaining = C_TradeSkillUI.GetRecipeCooldown(recipeId);
            cooldowns[recipeId] = (cooldownRemaining and cooldownRemaining > 0) and (time() + cooldownRemaining) or 0;
            cooldownCount = cooldownCount + 1;
        end
    end
    if (cooldownCount == 0) then
        return nil;
    end
    self.addon:Log("CooldownService", "ScanRecipeCooldowns", "Found %d cooldowns in profession window", cooldownCount);
    return cooldowns;
end

--- Scan cooldowns from the currently open craft window.
-- Enchanting uses the craft API instead of the trade skill API on Classic clients,
-- so its cooldowns (e.g. Void Sphere) are scanned here during CRAFT_UPDATE processing.
-- @return Table of cooldowns: { [spellId] = expiresTimestamp } or nil if nothing found.
function CooldownService:ScanCraftCooldowns()
    -- the craft cooldown api is not available on all clients
    if (not GetCraftCooldown or not GetNumCrafts) then
        return nil;
    end

    -- get cooldown spells model and craft count
    local cooldownSpells = self:GetModel("cooldown-spells");
    local craftAmount = GetNumCrafts();
    local cooldowns = {};
    local found = false;

    -- build reverse lookup: itemId → spellId for cooldown spells only
    local cooldownItemIds = {};
    local skillsService = self:GetService("skills");
    for spellId, _ in pairs(cooldownSpells) do
        local skillData = skillsService.sourceSkills[spellId];
        if (skillData and skillData.itemId) then
            cooldownItemIds[skillData.itemId] = spellId;
        end
    end

    for craftIndex = 1, craftAmount do
        local craftName, _, craftType = GetCraftInfo(craftIndex);
        if (craftName and craftType ~= "header") then
            -- get spell id from craft link
            local craftLink = GetCraftItemLink(craftIndex);
            if (craftLink) then
                local spellId = tonumber(craftLink:match("enchant:(%d+)")) or tonumber(craftLink:match("spell:(%d+)"));

                -- fallback: extract item id from item link and match against cooldown spells
                if (not spellId) then
                    local itemId = tonumber(craftLink:match("item:(%d+)"));
                    if (itemId and cooldownItemIds[itemId]) then
                        spellId = cooldownItemIds[itemId];
                    end
                end

                -- check if this spell has a known cooldown
                if (spellId and cooldownSpells[spellId]) then
                    local cooldownRemaining = GetCraftCooldown(craftIndex);
                    if (cooldownRemaining and cooldownRemaining > 0) then
                        cooldowns[spellId] = time() + cooldownRemaining;
                    else
                        cooldowns[spellId] = 0;
                    end
                    found = true;
                end
            end
        end
    end

    if (not found) then
        return nil;
    end

    -- log cooldown count
    local cooldownCount = 0;
    for _ in pairs(cooldowns) do
        cooldownCount = cooldownCount + 1;
    end
    self.addon:Log("CooldownService", "ScanCraftCooldowns", "Found %d cooldowns in craft window", cooldownCount);

    return cooldowns;
end

--- Scan item-based cooldowns from bags.
-- Checks for profession items that have use-cooldowns (e.g. Salt Shaker).
-- @return Table of cooldowns: { [spellId] = expiresTimestamp } or nil if nothing found.
function CooldownService:ScanItemCooldowns()
    local cooldownItems = self:GetModel("cooldown-items");
    if (not cooldownItems or not next(cooldownItems)) then
        return nil;
    end

    local cooldowns = {};
    local found = false;

    -- iterate all bags looking for cooldown items
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemId = C_Container.GetContainerItemID(bag, slot);
            if (itemId and cooldownItems[itemId]) then
                -- found a cooldown item, read its cooldown
                local startTime, duration, enable = C_Container.GetContainerItemCooldown(bag, slot);
                local itemInfo = cooldownItems[itemId];
                local spellId = itemInfo.spellId;

                -- skip if enable ~= 1 (cooldown data not yet available)
                if (not enable or enable ~= 1) then
                    self.addon:Log("CooldownService", "ScanItemCooldowns", "Item %d: enable=%s, data not ready - scheduling retry", itemId, tostring(enable));
                    if (not self.itemCooldownRetryScheduled) then
                        self.itemCooldownRetryScheduled = true;
                        C_Timer.After(5, function()
                            self.itemCooldownRetryScheduled = nil;
                            self:CheckItemCooldowns();
                        end);
                    end
                elseif (startTime and startTime > 0 and duration and duration > 0) then
                    -- validate duration against known maximum (ignore bogus values)
                    if (itemInfo.maxDuration and duration > itemInfo.maxDuration * 1.1) then
                        self.addon:Log("CooldownService", "ScanItemCooldowns", "Item %d: duration %.0f exceeds maxDuration %d, ignoring", itemId, duration, itemInfo.maxDuration);
                    else
                        -- calculate remaining seconds and expiration timestamp
                        local elapsed = GetTime() - startTime;
                        local remaining = duration - elapsed;

                        -- cap remaining to valid range
                        if (remaining > duration) then
                            remaining = duration;
                        elseif (remaining < 0) then
                            remaining = 0;
                        end

                        cooldowns[spellId] = time() + remaining;
                    end
                else
                    -- item is ready (no active cooldown)
                    cooldowns[spellId] = 0;
                end
                found = true;
            end
        end
    end

    if (not found) then
        return nil;
    end

    local count = 0;
    for _ in pairs(cooldowns) do
        count = count + 1;
    end
    self.addon:Log("CooldownService", "ScanItemCooldowns", "Found %d item cooldowns in bags", count);
    return cooldowns;
end

--- Store cooldowns for the current player.
-- @param cooldowns Table of { [spellId] = expiresTimestamp }.
-- @return True if any cooldown value actually changed.
function CooldownService:StoreOwnCooldowns(cooldowns)
    -- get player service and full name
    local playerService = self:GetService("player");
    local playerName = playerService.current;

    if (not playerService.node.cooldowns[playerName]) then
        playerService.node.cooldowns[playerName] = {};
    end

    -- get stored cooldowns
    local stored = playerService.node.cooldowns[playerName];
    local changed = false;

    -- merge new cooldown data into stored data, track changes
    for spellId, expires in pairs(cooldowns) do
        local oldValue = stored[spellId];

        -- consider changed if new spell, or ready state changed, or expires differs by more than 60s
        if (not oldValue) then
            changed = true;
        elseif (oldValue == 0 and expires ~= 0) then
            changed = true;
        elseif (oldValue ~= 0 and expires == 0) then
            changed = true;
        elseif (math.abs(oldValue - expires) > 60) then
            changed = true;
        end
        stored[spellId] = expires;
    end

    -- track when own cooldowns changed
    if (changed) then
        if (not playerService.node.cooldownsUpdated) then
            playerService.node.cooldownsUpdated = {};
        end
        playerService.node.cooldownsUpdated[playerName] = time();
    end

    return changed;
end

--- Store cooldowns received from a guild member.
-- @param playerName Name of the player (short or full).
-- @param cooldowns Table of { [spellId] = expiresTimestamp }. Special: {[0] = -1} means clear.
function CooldownService:StorePlayerCooldowns(playerName, cooldowns)
    -- get player service and full name
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(playerName);

    -- check for clear signal
    if (cooldowns[0] == -1) then
        playerService.node.cooldowns[fullName] = nil;
        self.addon:Log("CooldownService", "StorePlayerCooldowns", "Cleared cooldowns for %s (sharing disabled)", fullName);
        return;
    end

    -- remove cross-realm duplicates for this character (same short name, different realm)
    local shortName = playerService:GetShortName(fullName);
    for existingName, _ in pairs(playerService.node.cooldowns) do
        if (existingName ~= fullName and playerService:GetShortName(existingName) == shortName) then
            playerService.node.cooldowns[existingName] = nil;
            self.addon:Log("CooldownService", "StorePlayerCooldowns", "Removed duplicate entry %s (canonical: %s)", existingName, fullName);
        end
    end

    if (not playerService.node.cooldowns[fullName]) then
        playerService.node.cooldowns[fullName] = {};
    end

    -- overwrite with received data (skip values that exceed max cooldown duration)
    local maxDuration = 7 * 24 * 3600;
    local currentTime = time();
    for spellId, expires in pairs(cooldowns) do
        if (expires > 0 and (expires - currentTime) > maxDuration) then
            expires = 0;
        end
        playerService.node.cooldowns[fullName][spellId] = expires;
    end

    -- update sync time so relay logic knows about newer cooldown data
    playerService.node.syncTimes[fullName] = time();
end

--- Send own cooldowns to guild.
function CooldownService:SendOwnCooldownsToGuild()
    -- check if sharing is enabled
    if (not PM_Settings.shareCooldowns) then
        return;
    end

    -- get player cooldowns (use full name to avoid cross-realm duplicates on connected realms)
    local playerService = self:GetService("player");
    local playerName = playerService.current;
    local cooldowns = playerService.node.cooldowns[playerService.current];

    if (not cooldowns or not next(cooldowns)) then
        return;
    end

    local cooldownCount = 0;
    for _ in pairs(cooldowns) do
        cooldownCount = cooldownCount + 1;
    end
    self.addon:Log("CooldownService", "SendOwnCooldownsToGuild", "Sending %d cooldowns to guild", cooldownCount);

    -- create and send message to the guild and the linked accounts (BULK like
    -- all data messages, keeps ordering with queued pushes)
    local PlayerCooldownsMessage = self:GetModel("player-cooldowns-message");
    local message = PlayerCooldownsMessage:Create(playerName, cooldowns);
    self:GetService("message"):Broadcast(message, "BULK");
end

--- Check if a cooldown is being watched.
-- @param playerName Player name (short or full).
-- @param spellId Spell ID of the cooldown.
-- @return True if watched.
function CooldownService:IsWatched(playerName, spellId)
    -- normalize to full name for comparison
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(playerName);

    for _, entry in ipairs(PM_Settings.watchedCooldowns) do
        -- compare both as full names to handle mixed short/full entries
        if (playerService:GetLongName(entry.playerName) == fullName and entry.spellId == spellId) then
            return true;
        end
    end
    return false;
end

--- Add a cooldown to the watch list.
-- @param playerName Player name (short or full).
-- @param spellId Spell ID of the cooldown.
function CooldownService:WatchCooldown(playerName, spellId)
    if (self:IsWatched(playerName, spellId)) then
        return;
    end

    -- store as full name for consistency
    local fullName = self:GetService("player"):GetLongName(playerName);
    table.insert(PM_Settings.watchedCooldowns, { playerName = fullName, spellId = spellId });
    self.addon:Log("CooldownService", "WatchCooldown", "Watching %s spellId=%d", fullName, spellId);

    -- show cooldown view (clear hide flag since user is actively watching)
    PM_Settings.hideCooldowns = nil;
    if (self.cooldownView) then
        self.cooldownView:Show();
    end
end

--- Remove a cooldown from the watch list.
-- @param playerName Player name (short or full).
-- @param spellId Spell ID of the cooldown.
function CooldownService:UnwatchCooldown(playerName, spellId)
    -- normalize to full name for comparison
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(playerName);

    for i, entry in ipairs(PM_Settings.watchedCooldowns) do
        -- compare both as full names to handle mixed short/full entries
        if (playerService:GetLongName(entry.playerName) == fullName and entry.spellId == spellId) then
            table.remove(PM_Settings.watchedCooldowns, i);
            self.addon:Log("CooldownService", "UnwatchCooldown", "Unwatched %s spellId=%d", fullName, spellId);

            -- hide cooldown view if no more watched cooldowns
            if (#PM_Settings.watchedCooldowns == 0 and self.cooldownView) then
                self.cooldownView:Hide();
            elseif (self.cooldownView and self.cooldownView.visible) then
                self.cooldownView:Refresh();
            end
            return;
        end
    end
end

--- Toggle the cooldown view visibility.
function CooldownService:ToggleCooldownView()
    if (self.cooldownView.visible) then
        PM_Settings.hideCooldowns = true;
        self.cooldownView:Hide();
    else
        PM_Settings.hideCooldowns = nil;
        self.cooldownView:Show();
    end
end

--- Show cooldown view if there are watched cooldowns and not explicitly hidden.
function CooldownService:CheckWatchedCooldowns()
    if (#PM_Settings.watchedCooldowns > 0 and not PM_Settings.hideCooldowns) then
        self.cooldownView:Show();
    end
end

--- Seed previouslyActive table with watched cooldowns that are currently active.
-- This allows the ticker to detect transitions to ready for CDs that were active at session start.
function CooldownService:SeedPreviouslyActive()
    local playerService = self:GetService("player");
    local currentTime = time();

    for _, watched in ipairs(PM_Settings.watchedCooldowns) do
        local key = watched.playerName .. ":" .. watched.spellId;
        local fullName = playerService:GetLongName(watched.playerName);
        local cooldowns = playerService.node.cooldowns and playerService.node.cooldowns[fullName];

        if (cooldowns and cooldowns[watched.spellId]) then
            local expires = cooldowns[watched.spellId];

            -- seed active CDs so the ticker can detect when they become ready
            if (expires > 0 and expires > currentTime) then
                self.previouslyActive[key] = expires;
            end
        end
    end

    self.addon:Log("CooldownService", "SeedPreviouslyActive", "Seeded %d active watched cooldowns", self:CountTable(self.previouslyActive));
end

--- Count entries in a table.
-- @param tbl Table to count.
-- @return Number of entries.
function CooldownService:CountTable(tbl)
    local count = 0;
    for _ in pairs(tbl) do
        count = count + 1;
    end
    return count;
end

--- Start the periodic ticker that checks for watched cooldown expirations.
function CooldownService:StartWatchedCooldownTicker()
    self.watchedTicker = C_Timer.NewTicker(10, function()
        self:CheckWatchedCooldownExpiry();
    end);
end

--- Check if any watched cooldown just expired and notify.
-- Uses state-transition detection: notifies when a cooldown transitions from active to ready,
-- regardless of how much time has passed since the actual expiry.
function CooldownService:CheckWatchedCooldownExpiry()
    if (PM_Settings.cooldownNotification == "never") then return; end

    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local currentTime = time();
    local justExpired = {};

    for _, watched in ipairs(PM_Settings.watchedCooldowns) do
        local key = watched.playerName .. ":" .. watched.spellId;
        local fullName = playerService:GetLongName(watched.playerName);
        local cooldowns = playerService.node.cooldowns and playerService.node.cooldowns[fullName];

        if (cooldowns and cooldowns[watched.spellId]) then
            local expires = cooldowns[watched.spellId];

            -- determine current state: active (expires in the future) or ready
            local isActive = (expires > 0 and expires > currentTime);
            local isReady = (expires == 0 or (expires > 0 and expires <= currentTime));

            if (isActive) then
                -- mark as active so we can detect the transition to ready
                self.previouslyActive[key] = expires;
            elseif (isReady and self.previouslyActive[key]) then
                -- transitioned from active to ready: notify once per expiry value
                if (not self.notifiedExpired[key] or self.notifiedExpired[key] ~= self.previouslyActive[key]) then
                    self.notifiedExpired[key] = self.previouslyActive[key];
                    self.previouslyActive[key] = nil;

                    -- get item/spell name
                    local skill = skillsService:GetSkillById(watched.spellId);
                    local itemName;
                    if (skill and skill.itemId and skill.itemId > 0) then
                        itemName = self.addon.compat.GetItemInfo(skill.itemId);
                    end
                    if (not itemName) then
                        itemName = self.addon.compat.GetSpellInfo(watched.spellId) or ("Spell " .. watched.spellId);
                    end

                    -- determine display name
                    local displayName;
                    local shortName = playerService:GetShortName(watched.playerName);
                    if (playerService:IsCurrentPlayer(watched.playerName)) then
                        displayName = self:GetService("locale"):Get("You");
                    elseif (playerService.node.own[playerService:GetLongName(watched.playerName)]) then
                        displayName = self:GetService("locale"):Get("You") .. " (" .. shortName .. ")";
                    else
                        displayName = shortName;
                    end

                    table.insert(justExpired, {
                        characterName = displayName,
                        itemName = itemName
                    });
                end
            end
        end
    end

    -- notify about just-expired cooldowns
    if (#justExpired > 0) then
        local localeService = self:GetService("locale");
        local chatService = self:GetService("chat");

        -- build display parts
        local parts = {};
        for _, cd in ipairs(justExpired) do
            table.insert(parts, cd.itemName .. ": " .. cd.characterName);
        end

        -- build header
        local header;
        if (#justExpired == 1) then
            header = localeService:Get("CooldownReadyNotification");
        else
            header = localeService:Get("CooldownsReadyNotification", #justExpired);
        end

        -- show in chat
        local message = "|cff00ff00" .. header .. "|r " .. table.concat(parts, " | ");
        chatService:WriteBare(message);

        self.addon:Log("CooldownService", "CheckWatchedCooldownExpiry", "Notified %d ready cooldowns", #justExpired);

        -- show center screen alert
        if (PM_Settings.cooldownNotification == "both") then
            local alertText = "|cff00ff00" .. header .. "|r\n" .. table.concat(parts, "\n");
            self.addon.compat.RaidNotice_AddMessage(RaidWarningFrame, alertText, ChatTypeInfo["RAID_WARNING"]);
            PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3);
        end
    end
end

--- Notify the player about ready watched cooldowns on login.
function CooldownService:NotifyReadyCooldowns()
    -- check notification setting
    if (PM_Settings.cooldownNotification == "never") then
        return;
    end

    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local currentTime = time();
    local readyCooldowns = {};

    -- check only watched cooldowns
    for _, watched in ipairs(PM_Settings.watchedCooldowns) do
        local fullName = playerService:GetLongName(watched.playerName);
        local cooldowns = playerService.node.cooldowns and playerService.node.cooldowns[fullName];
        if (cooldowns and cooldowns[watched.spellId]) then
            local expires = cooldowns[watched.spellId];
            if (expires == 0 or expires <= currentTime) then
                -- clear previouslyActive so the ticker doesn't double-notify
                local key = watched.playerName .. ":" .. watched.spellId;
                self.previouslyActive[key] = nil;

                -- get item/spell name
                local skill = skillsService:GetSkillById(watched.spellId);
                local itemName;
                if (skill and skill.itemId and skill.itemId > 0) then
                    itemName = self.addon.compat.GetItemInfo(skill.itemId);
                end
                if (not itemName) then
                    itemName = self.addon.compat.GetSpellInfo(watched.spellId) or ("Spell " .. watched.spellId);
                end

                -- determine display name
                local displayName;
                local shortName = playerService:GetShortName(watched.playerName);
                if (playerService:IsCurrentPlayer(watched.playerName)) then
                    displayName = self:GetService("locale"):Get("You");
                elseif (playerService.node.own[playerService:GetLongName(watched.playerName)]) then
                    displayName = self:GetService("locale"):Get("You") .. " (" .. shortName .. ")";
                else
                    displayName = shortName;
                end

                table.insert(readyCooldowns, {
                    characterName = displayName,
                    itemName = itemName
                });
            end
        end
    end

    -- notify if any ready
    if (#readyCooldowns > 0) then
        local localeService = self:GetService("locale");
        local chatService = self:GetService("chat");

        -- group by item name
        local itemGroups = {};
        local itemOrder = {};
        for _, cd in ipairs(readyCooldowns) do
            if (not itemGroups[cd.itemName]) then
                itemGroups[cd.itemName] = {};
                table.insert(itemOrder, cd.itemName);
            end
            table.insert(itemGroups[cd.itemName], cd.characterName);
        end

        -- build display parts: "[ItemName]: Player1, Player2"
        local parts = {};
        for _, itemName in ipairs(itemOrder) do
            table.insert(parts, itemName .. ": " .. table.concat(itemGroups[itemName], ", "));
        end

        -- build header with singular/plural
        local header;
        if (#readyCooldowns == 1) then
            header = localeService:Get("CooldownReadyNotification");
        else
            header = localeService:Get("CooldownsReadyNotification", #readyCooldowns);
        end

        -- show in chat
        local message = "|cff00ff00" .. header .. "|r " .. table.concat(parts, " | ");
        chatService:WriteBare(message);

        -- show prominent center screen alert with details
        if (PM_Settings.cooldownNotification == "both") then
            local alertText = "|cff00ff00" .. header .. "|r\n" .. table.concat(parts, "\n");
            self.addon.compat.RaidNotice_AddMessage(RaidWarningFrame, alertText, ChatTypeInfo["RAID_WARNING"]);
            PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3);
        end
    end
end
