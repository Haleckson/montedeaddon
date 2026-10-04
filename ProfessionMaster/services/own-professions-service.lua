--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local OwnProfessionsService = _G.professionMaster:CreateService("own-professions");

--- Initialize service.
function OwnProfessionsService:Initialize()
    -- ensure profession levels table exists
    if (not PM_CharacterSettings.professionLevels) then
        PM_CharacterSettings.professionLevels = {};
    end

    -- the modern client (WoW Forever) has one profession window for all
    -- professions on top of C_TradeSkillUI and no trade skill / craft api
    self.usesTradeSkillUi = GetNumTradeSkills == nil and C_TradeSkillUI ~= nil;

    -- register events
    if (self.usesTradeSkillUi) then
        self:HandleEvent("TRADE_SKILL_LIST_UPDATE", function()
            self:QueueTradeSkillUiScan();
        end);
        self:HandleEvent("TRADE_SKILL_DATA_SOURCE_CHANGED", function()
            self:QueueTradeSkillUiScan();
        end);
        self.addon:Log("OwnProfessionsService", "Initialize", "profession scan uses C_TradeSkillUI");
    else
        self:HandleEvent("TRADE_SKILL_UPDATE", function()
            self:GetProfessionData();
        end);
        self:HandleEvent("CRAFT_UPDATE", function()
            self:GetProfessionData();
        end);
    end

    -- register chat skill-up event for all professions
    self:HandleEvent("CHAT_MSG_SKILL", function(message)
        self:HandleSkillUpMessage(message);
    end);

    -- register skill lines changed event (fires when skill data becomes available)
    self:HandleEvent("SKILL_LINES_CHANGED", function()
        if (not self.gatheringScanDone) then
            self.gatheringScanDone = true;
            self:CleanupDroppedProfessions();
            self:ScanGatheringProfessions();
        end
    end);

    -- skill line aliases already checked against the recipes of their window
    self.verifiedAliases = {};
end

--- Detect own specializations for the current player.
-- Checks IsSpellKnown for all known specialization spells (TBC+).
function OwnProfessionsService:DetectSpecializations()
    -- only available from TBC onwards
    if (not self.addon.isBccAtLeast) then
        return;
    end

    -- get player name
    local playerName = self:GetService("player").current;

    -- get specialization spells model
    local specializationSpells = self:GetModel("specialization-spells");

    -- prepare specializations for this player
    local specializations = {};

    -- iterate all professions that have specializations
    for professionId, specs in pairs(specializationSpells) do
        for _, spec in ipairs(specs) do
            if (self.addon.compat.IsSpellKnown(spec.spellId)) then
                specializations[professionId] = spec.spellId;
                self.addon:Log("OwnProfessionsService", "DetectSpecializations", "Detected specialization %s for profession %s", tostring(spec.spellId), tostring(professionId));
                break;
            end
        end
    end

    -- store in saved variable
    PM_Specializations[playerName] = specializations;

    -- track when specializations changed
    local playerService = self:GetService("player");
    playerService.node.specializationsUpdated = time();
end

--- Store profession level in the persistent node (shared across characters).
-- @param professionId The profession ID.
-- @param level The skill level to store.
function OwnProfessionsService:StoreProfessionLevel(professionId, level)
    local playerService = self:GetService("player");
    local playerName = playerService.current;

    -- ensure ownLevels structure exists
    if (not playerService.node.ownLevels) then
        playerService.node.ownLevels = {};
    end
    if (not playerService.node.ownLevels[playerName]) then
        playerService.node.ownLevels[playerName] = {};
    end

    -- store level
    playerService.node.ownLevels[playerName][professionId] = level;
end

-- dot colors of the ownership kinds: green for the logged in character, blue for an alt
local OwnershipColors = { current = { 0.2, 0.9, 0.2 }, alt = { 0.4, 0.7, 1 } };

--- Get the dot color of an ownership kind ("current" or "alt"), nil for none.
-- @return Table { r, g, b } or nil.
function OwnProfessionsService:GetOwnershipColor(kind)
    return kind and OwnershipColors[kind] or nil;
end

--- Add the ownership lines to a tooltip: the logged in character knows it
--- and/or the alts that know it.
-- @param tooltip GameTooltip to fill (already owned and anchored).
-- @param ownership "current" or "alt".
-- @param altNames Short names of the alts knowing it.
-- @param append True to add lines to a filled tooltip instead of setting the first line.
function OwnProfessionsService:AddOwnershipTooltipLines(tooltip, ownership, altNames, append)
    local localeService = self:GetService("locale");
    local current = OwnershipColors.current;
    local alt = OwnershipColors.alt;
    local hasAlts = altNames and #altNames > 0;
    local function AddLine(text, color)
        if (append) then
            tooltip:AddLine(text, color[1], color[2], color[3]);
        else
            tooltip:SetText(text, color[1], color[2], color[3]);
            append = true;
        end
    end
    if (ownership == "current") then
        AddLine(localeService:Get("KnownByCurrentCharacter"), current);
    end
    if (hasAlts) then
        AddLine(localeService:Get("KnownByAlts"), alt);
        tooltip:AddLine(table.concat(altNames, ", "), 1, 1, 1, true);
    end
end

--- Get which own characters match a check: the logged in character first,
--- then the alts of this realm and faction.
-- @param matches Function(characterName) returning true when the character counts.
-- @return "current" when the logged in character matches, "alt" when only alts do, nil otherwise; the matching alt short names.
function OwnProfessionsService:GetOwnership(matches)
    local playerService = self:GetService("player");
    local kind = matches(playerService.current) and "current" or nil;
    local altNames = {};
    for characterName, _ in pairs(playerService.node.own) do
        if (characterName ~= playerService.current and matches(characterName)) then
            altNames[#altNames + 1] = playerService:GetShortName(characterName);
        end
    end
    table.sort(altNames);
    if (not kind and #altNames > 0) then
        kind = "alt";
    end
    return kind, altNames;
end

--- Get who of the own characters knows a profession.
-- @param professionId The profession ID.
-- @return "current", "alt" or nil; the alt short names knowing it.
function OwnProfessionsService:GetProfessionOwnership(professionId)
    local playerService = self:GetService("player");
    return self:GetOwnership(function(characterName)
        local ownProfessions = playerService.node.own[characterName];
        return ownProfessions ~= nil and ownProfessions[professionId] ~= nil;
    end);
end

--- Get who of the own characters has a specialization.
-- @param professionId The profession ID.
-- @param spellId The specialization spell ID.
-- @return "current", "alt" or nil; the alt short names having it.
function OwnProfessionsService:GetSpecializationOwnership(professionId, spellId)
    return self:GetOwnership(function(characterName)
        local specializations = PM_Specializations and PM_Specializations[characterName];
        return specializations and specializations[professionId] == spellId;
    end);
end

--- Get own profession data.
function OwnProfessionsService:GetProfessionData()
    -- check if is in combat
    if (self.addon.inCombat) then
        return;
    end

    -- check if is link
    local professionIsLink, professionPlayerName = self.addon.compat.IsTradeSkillLinked();
    if (professionIsLink) then
        -- get long name
        professionPlayerName = self:GetService("player"):GetLongName(professionPlayerName);

        -- check if is guild mate
        if (not self:GetService("player"):IsGuildmate(professionPlayerName)) then
            return;
        end
    end

    -- get trade skill profession data
    self:GetTradeSkillProfessionData(professionIsLink, professionPlayerName);

    -- get craft skill profession data
    self:GetCraftSkillProfessionData(professionIsLink, professionPlayerName);
end

--- Queue a scan of the modern profession window. The list update event fires
--- in bursts (filters, searches, every craft), so the scan runs once shortly
--- after the last one.
function OwnProfessionsService:QueueTradeSkillUiScan()
    if (self.tradeSkillUiScanQueued) then
        return;
    end
    self.tradeSkillUiScanQueued = true;
    C_Timer.After(0.5, function()
        self.tradeSkillUiScanQueued = false;
        self:GetTradeSkillUiProfessionData();
    end);
end

--- Get own profession data from the modern profession window (C_TradeSkillUI).
--- Recipe ids are spell ids there, so they are the skill ids without any link parsing.
function OwnProfessionsService:GetTradeSkillUiProfessionData()
    -- check if is in combat
    if (self.addon.inCombat) then
        return;
    end

    -- crafting at an npc and the guild wide recipe view are not a character's profession
    if ((C_TradeSkillUI.IsNPCCrafting and C_TradeSkillUI.IsNPCCrafting()) or (C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild())) then
        return;
    end

    -- check if is link
    local playerService = self:GetService("player");
    local professionIsLink, professionPlayerName = C_TradeSkillUI.IsTradeSkillLinked();
    if (professionIsLink) then
        professionPlayerName = playerService:GetLongName(professionPlayerName);
        if (not playerService:IsGuildmate(professionPlayerName)) then
            return;
        end
    end

    -- get profession: the child info carries the skill level, its parent is the profession
    local professionInfo = C_TradeSkillUI.GetChildProfessionInfo();
    if (not professionInfo or professionInfo.professionID == 0) then
        professionInfo = C_TradeSkillUI.GetBaseProfessionInfo();
    end
    local professionId = professionInfo and (professionInfo.parentProfessionID or professionInfo.professionID);
    local professionNamesService = self:GetService("profession-names");
    if (not professionId or professionId == 0 or not professionNamesService:GetProfessionName(professionId)) then
        return;
    end

    -- first aid is not a tracked profession, never scan or sync its window
    if (professionId == 129) then
        return;
    end

    -- store skill level for own character
    local currentRank = professionInfo.skillLevel;
    if (not professionIsLink and currentRank and currentRank > 0) then
        PM_CharacterSettings.professionLevels[professionId] = currentRank;
        self:StoreProfessionLevel(professionId, currentRank);
        if (professionNamesService:HasGatheringComponent(professionId)) then
            self:UpdateGatheringSkills(professionId);
        end
    end

    -- gathering professions: only the skill level, skip skill scanning
    if (professionNamesService:IsGatheringProfession(professionId)) then
        return;
    end

    -- collect the learned recipes
    local skillsService = self:GetService("skills");
    local recipeIds = (C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetAllRecipeIDs()) or C_TradeSkillUI.GetFilteredRecipeIDs() or {};
    local skills = {};
    local learnedRecipeIds = {};
    for _, recipeId in ipairs(recipeIds) do
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeId);
        if (recipeInfo and recipeInfo.learned) then
            local skillData = skillsService.sourceSkills[recipeId];
            table.insert(learnedRecipeIds, recipeId);
            table.insert(skills, {
                skillId = recipeId,
                itemId = skillData and skillData.itemId or 0,
                added = time()
            });
        end
    end

    -- the list is empty while the window still loads its data
    if (#recipeIds == 0) then
        return;
    end
    self.addon:Log("OwnProfessionsService", "GetTradeSkillUiProfessionData", "Scanned %d skills for profession %s (total recipes: %d, rank: %s)", #skills, tostring(professionId), #recipeIds, tostring(currentRank));

    -- scan cooldowns for own character
    if (not professionIsLink) then
        local cooldownService = self:GetService("cooldown");
        local cooldowns = cooldownService:ScanRecipeCooldowns(learnedRecipeIds);
        if (cooldowns) then
            local changed = cooldownService:StoreOwnCooldowns(cooldowns);
            if (changed) then
                cooldownService:SendOwnCooldownsToGuild();
            end
        end
    end

    -- store: a linked profession of a guildmate or the own one
    if (professionIsLink) then
        self:GetService("profession-store"):StorePlayerSkills(professionPlayerName, professionId, skills);
    else
        self:StoreAndSendOwnProfession(professionId, skills);
    end
end

--- Get own trade skill profession data.
function OwnProfessionsService:GetTradeSkillProfessionData(professionIsLink, professionPlayerName)
    -- get and check profession id
    local professionNamesService = self:GetService("profession-names");
    local skillLineName, currentRank, maxRank = GetTradeSkillLine();
    local professionId = professionNamesService:GetProfessionId(skillLineName);
    if (not professionId) then
        -- locale fallback: on some clients the skill line name differs from the
        -- profession spell name (e.g. frFR "Ingénierie" vs. "Ingénieur"), resolve
        -- the profession from the recipe ids in the open window instead
        professionId = self:ResolveProfessionIdFromTradeSkills();
        if (not professionId) then
            return;
        end

        -- register the skill line name so name based lookups work from now on
        professionNamesService:RegisterProfessionNameAlias(skillLineName, professionId);
        self.verifiedAliases[skillLineName] = true;
    end

    -- an alias learned in an earlier session is checked once against the recipes
    -- of the window: older versions aliased the first aid skill line to tailoring
    -- or alchemy, which sent the bandages into the scan
    professionId = self:VerifyProfessionNameAlias(skillLineName, professionId);

    -- first aid is not a tracked profession, never scan or sync its window
    if (professionId == 129) then
        return;
    end

    -- gathering professions: only store the skill level, skip skill scanning
    if (professionNamesService:IsGatheringProfession(professionId)) then
        if (not professionIsLink and currentRank) then
            PM_CharacterSettings.professionLevels[professionId] = currentRank;
            self:StoreProfessionLevel(professionId, currentRank);
            self.addon:Log("OwnProfessionsService", "GetTradeSkillProfessionData", "Gathering profession %s (id=%s) rank=%s", tostring(skillLineName), tostring(professionId), tostring(currentRank));
            self:UpdateGatheringSkills(professionId);
        end
        return;
    end

    -- store skill level for own character
    if (not professionIsLink and currentRank) then
        PM_CharacterSettings.professionLevels[professionId] = currentRank;
        self:StoreProfessionLevel(professionId, currentRank);
        self.addon:Log("OwnProfessionsService", "GetTradeSkillProfessionData", "TradeSkill profession %s (id=%s) rank=%s maxRank=%s", tostring(skillLineName), tostring(professionId), tostring(currentRank), tostring(maxRank));

        -- update gathering skills for hybrid professions (e.g. Mining)
        if (professionNamesService:HasGatheringComponent(professionId)) then
            self:UpdateGatheringSkills(professionId);
        end
    end

    -- get amount of trade skills
    local tradeSkillAmount = GetNumTradeSkills();

    -- prepare item ids
    local skillsService = self:GetService("skills");
    local skills = {};

    -- iterate trade skills
    for tradeSkillIndex = 1, tradeSkillAmount do
        -- get trade skill name and type
        local tradeSkillName, tradeSkillType = GetTradeSkillInfo(tradeSkillIndex);

        -- check name and type
        if (tradeSkillName and (tradeSkillType == "optimal" or tradeSkillType == "medium" or tradeSkillType == "easy" or tradeSkillType == "trivial")) then
            -- get link and item id
            local tradeSkillLink = GetTradeSkillItemLink(tradeSkillIndex);
            local tradeSkillId = nil;
            local tradeSkillItemId = nil;

            -- try to extract skill id from item link
            if (tradeSkillLink) then
                tradeSkillId = tonumber(tradeSkillLink:match("enchant:(%d+)"));
                tradeSkillItemId = tonumber(tradeSkillLink:match("item:(%d+)"));
                if (tradeSkillItemId and (not tradeSkillId)) then
                    tradeSkillId = skillsService:GetSkillIdByItemId(tradeSkillItemId, professionId);
                end

                -- try spell link format as fallback
                if (not tradeSkillId) then
                    tradeSkillId = tonumber(tradeSkillLink:match("spell:(%d+)"));
                end
            end

            -- get trade skill id via recipe link fallback
            if (not tradeSkillId) then
                local recipeLink = GetTradeSkillRecipeLink(tradeSkillIndex);
                if (recipeLink) then
                    tradeSkillId = professionNamesService:GetSkillId(recipeLink);

                    -- try spell link format as secondary fallback
                    if (not tradeSkillId) then
                        tradeSkillId = tonumber(recipeLink:match("enchant:(%d+)")) or tonumber(recipeLink:match("spell:(%d+)"));
                    end
                end
            end

            -- log unresolved skills for debugging
            if (not tradeSkillId) then
                local recipeLink = GetTradeSkillRecipeLink(tradeSkillIndex) or '';
                self.addon:Log("OwnProfessionsService", "GetTradeSkillProfessionData", "Could not resolve skill: name=%s, itemLink=%s, recipeLink=%s", tostring(tradeSkillName), tostring(tradeSkillLink), tostring(recipeLink));
            end

            -- check trade skill id
            if (tradeSkillId) then
                -- add skill
                table.insert(skills, {
                    skillId = tradeSkillId,
                    itemId = tradeSkillItemId or 0,
                    added = time()
                });
            end
        end
    end

    -- log scan result
    self.addon:Log("OwnProfessionsService", "GetTradeSkillProfessionData", "Scanned %d skills for profession %s (total recipes: %d)", #skills, tostring(professionId), tradeSkillAmount);

    -- scan cooldowns for own character
    if (not professionIsLink) then
        local cooldownService = self:GetService("cooldown");
        local cooldowns = cooldownService:ScanTradeSkillCooldowns();
        if (cooldowns) then
            local changed = cooldownService:StoreOwnCooldowns(cooldowns);
            if (changed) then
                cooldownService:SendOwnCooldownsToGuild();
            end
        end
    end

    -- check if is link
    if (professionIsLink) then
        -- add to player professions
        self:GetService("profession-store"):StorePlayerSkills(professionPlayerName, professionId, skills);
    else
        -- store own profession
        self:StoreAndSendOwnProfession(professionId, skills);
    end
end

--- Get own craft skill profession data. 
function OwnProfessionsService:GetCraftSkillProfessionData(professionIsLink, professionPlayerName)
    -- get and check profession id
    local professionNamesService = self:GetService("profession-names");
    local craftSkillLineName = GetCraftDisplaySkillLine();
    local professionId = professionNamesService:GetProfessionId(craftSkillLineName);
    if (not professionId) then
        -- locale fallback: resolve the profession from the craft recipe ids
        -- (stays NIL for non profession craft frames like beast training)
        professionId = self:ResolveProfessionIdFromCrafts();
        if (not professionId) then
            return;
        end

        -- register the skill line name so name based lookups work from now on
        professionNamesService:RegisterProfessionNameAlias(craftSkillLineName, professionId);
    end

    -- store skill level for own character
    if (not professionIsLink) then
        local _, currentRank = GetCraftDisplaySkillLine();
        if (currentRank) then
            PM_CharacterSettings.professionLevels[professionId] = currentRank;
            self:StoreProfessionLevel(professionId, currentRank);
        else
            -- retry after short delay (API sometimes returns nil if window not fully loaded)
            C_Timer.After(0.5, function()
                local _, retryRank = GetCraftDisplaySkillLine();
                if (retryRank) then
                    PM_CharacterSettings.professionLevels[professionId] = retryRank;
                    self:StoreProfessionLevel(professionId, retryRank);
                    self.addon:Log("OwnProfessionsService", "GetCraftSkillProfessionData", "Retry succeeded: rank=%s", tostring(retryRank));
                end
            end);
        end
    end

    -- get amount of craft skills
    local craftSkillAmount = GetNumCrafts();

    -- prepare item ids
    local skillsService = self:GetService("skills");
    local skills = {};

    -- iterate craft skills
    for craftSkillIndex = 1, craftSkillAmount do
        -- get craft skill name and type
        local craftSkillName, _, craftSkillType = GetCraftInfo(craftSkillIndex);

        -- check name and type
        if (craftSkillName and (craftSkillType == "optimal" or craftSkillType == "medium" or craftSkillType == "easy" or craftSkillType == "trivial")) then
            -- get link, id and item id from enchant
            local craftSkillLink = GetCraftItemLink(craftSkillIndex);
            if (craftSkillLink) then
                local craftSkillId = tonumber(craftSkillLink:match("enchant:(%d+)"));
                local craftSkillItemId = tonumber(craftSkillLink:match("item:(%d+)"));
                local craftSkill = skillsService:GetSkillById(craftSkillId);
                if (craftSkill and (not craftSkillItemId)) then
                    craftSkillItemId = craftSkill["itemId"];
                end

                -- check trade skill id
                if (craftSkillId) then
                    -- add skill
                    table.insert(skills, {
                        skillId = craftSkillId,
                        itemId = craftSkillItemId or 0,
                        added = time()
                    });
                end
            end
        end
    end

    -- scan craft cooldowns for own character (enchanting uses the craft api)
    if (not professionIsLink) then
        local cooldownService = self:GetService("cooldown");
        local cooldowns = cooldownService:ScanCraftCooldowns();
        if (cooldowns) then
            local changed = cooldownService:StoreOwnCooldowns(cooldowns);
            if (changed) then
                cooldownService:SendOwnCooldownsToGuild();
            end
        end
    end

    -- check if is link
    if (professionIsLink) then
        -- add to player professions
        self:GetService("profession-store"):StorePlayerSkills(professionPlayerName, professionId, skills);
    else
        -- store own profession
        self:StoreAndSendOwnProfession(professionId, skills);
    end
end

--- Check a learned skill line alias against the recipes of the open trade skill
--- window and re-point it when the recipes resolve to another profession.
-- @param skillLineName Skill line name of the window.
-- @param professionId Profession id the name resolved to.
-- @return Profession id confirmed by the recipes.
function OwnProfessionsService:VerifyProfessionNameAlias(skillLineName, professionId)
    local professionNamesService = self:GetService("profession-names");
    if (self.verifiedAliases[skillLineName] or not professionNamesService:IsProfessionNameAlias(skillLineName)) then
        return professionId;
    end

    -- no verdict without resolvable recipes, check again next time
    local recipeProfessionId = self:ResolveProfessionIdFromTradeSkills();
    if (not recipeProfessionId) then
        return professionId;
    end
    self.verifiedAliases[skillLineName] = true;
    if (recipeProfessionId == professionId) then
        return professionId;
    end

    -- re-point the alias to the profession of the recipes
    professionNamesService:DropProfessionNameAlias(skillLineName);
    professionNamesService:RegisterProfessionNameAlias(skillLineName, recipeProfessionId);
    self.addon:Log("OwnProfessionsService", "VerifyProfessionNameAlias", "Alias %s pointed to profession %d, its recipes belong to profession %d", skillLineName, professionId, recipeProfessionId);
    return recipeProfessionId;
end

--- Resolve the profession id from the recipes in the open trade skill window.
-- Locale independent fallback for clients where the skill line name differs
-- from the profession spell name.
-- @return Profession id or NIL if no recipe could be resolved.
function OwnProfessionsService:ResolveProfessionIdFromTradeSkills()
    local skillsService = self:GetService("skills");
    local resolvedProfessionId = nil;

    -- iterate all trade skills and resolve their professions from the skill data
    for tradeSkillIndex = 1, GetNumTradeSkills() do
        local tradeSkillName, tradeSkillType = GetTradeSkillInfo(tradeSkillIndex);
        if (tradeSkillName and tradeSkillType ~= "header" and tradeSkillType ~= "subheader") then
            -- collect candidate links for this recipe (skip nil links)
            local links = {};
            local recipeLink = GetTradeSkillRecipeLink(tradeSkillIndex);
            if (recipeLink) then
                table.insert(links, recipeLink);
            end
            local itemLink = GetTradeSkillItemLink(tradeSkillIndex);
            if (itemLink) then
                table.insert(links, itemLink);
            end
            for _, link in ipairs(links) do
                -- try enchant and spell ids first (unique per profession)
                local skillId = tonumber(link:match("enchant:(%d+)")) or tonumber(link:match("spell:(%d+)"));

                -- fall back to the crafted item id
                if (not skillId) then
                    local itemId = tonumber(link:match("item:(%d+)"));
                    if (itemId) then
                        skillId = skillsService:GetSkillIdByItemId(itemId);
                    end
                end

                -- check if the skill is known and carries a profession id
                local skill = skillId and skillsService:GetSkillById(skillId);
                if (skill and skill.professionId) then
                    -- all recipes must agree on one profession, mixed results mean
                    -- the window belongs to an untracked profession
                    if (resolvedProfessionId and resolvedProfessionId ~= skill.professionId) then
                        return nil;
                    end
                    resolvedProfessionId = skill.professionId;
                    break;
                end
            end
        end
    end
    return resolvedProfessionId;
end

--- Resolve the profession id from the recipes in the open craft window.
-- Locale independent fallback, see ResolveProfessionIdFromTradeSkills.
-- @return Profession id or NIL if no recipe could be resolved.
function OwnProfessionsService:ResolveProfessionIdFromCrafts()
    local skillsService = self:GetService("skills");

    -- iterate craft skills until a recipe resolves to a known skill
    for craftSkillIndex = 1, GetNumCrafts() do
        local craftSkillLink = GetCraftItemLink(craftSkillIndex);
        if (craftSkillLink) then
            local skillId = tonumber(craftSkillLink:match("enchant:(%d+)")) or tonumber(craftSkillLink:match("spell:(%d+)"));
            local skill = skillId and skillsService:GetSkillById(skillId);
            if (skill and skill.professionId) then
                return skill.professionId;
            end
        end
    end
    return nil;
end

--- Store profession.
-- @param professionId Id of profession to store.
-- @param skills List of skills of this profession to store.
-- @return Ne added item ids.
function OwnProfessionsService:StoreAndSendOwnProfession(professionId, skills)
    -- prepare new skills
    local newSkills = {};

    -- check player
    local playerService = self:GetService("player");
    local playerName = playerService.current;
    local ownProfessions = playerService.node.own;
    if (not ownProfessions[playerName]) then
        -- add player name
        ownProfessions[playerName] = {};

        -- track character set change
        playerService.node.characterSetUpdated = time();
    end

    -- get player professions
    local playerProfessions = ownProfessions[playerName];

    -- check profession
    if (not playerProfessions[professionId]) then
        -- profession not set before, store all item ids
        playerProfessions[professionId] = skills;
        newSkills = skills;
        self.addon:Log("OwnProfessionsService", "StoreAndSendOwnProfession", "New profession %s for %s with %d skills", tostring(professionId), playerName, #skills);
    else
        -- get profession
        local profession = playerProfessions[professionId];

        -- build lookup of current skill ids from scan
        local currentSkillIds = {};
        for _, skill in ipairs(skills) do
            currentSkillIds[skill.skillId] = true;
        end

        -- remove skills that are no longer in the trade skill window
        -- (skip gathering skills with synthetic IDs, they are managed separately)
        for i = #profession, 1, -1 do
            if (not currentSkillIds[profession[i].skillId] and profession[i].skillId < 9000000) then
                table.remove(profession, i);
            end
        end

        -- iterate all skills
        for i, skill in ipairs(skills) do
            -- check if skill exists
            local skillExists = false;
            for j, existingSkill in ipairs(profession) do
                -- check if skill id matches
                if (existingSkill.skillId == skill.skillId) then
                    -- skill already exists
                    skillExists = true;
                    break;
                end
            end

            -- check if does not exists already
            if (not skillExists) then
                -- add item id
                table.insert(profession, skill);
                table.insert(newSkills, skill);
            end
        end
    end

    -- reconcile the synced copy with the full scan: the views and the sync
    -- digest read node.guildmates, which can fall behind the own store when a
    -- delta got lost (old purge, legacy migration); StorePlayerSkills only
    -- appends missing skills, so this is cheap when both are in step
    self:GetService("profession-store"):StorePlayerSkills(playerName, professionId, skills);

    -- check if has new item ids
    if (#newSkills == 0) then
        return;
    end

    -- log new skills count
    self.addon:Log("OwnProfessionsService", "StoreAndSendOwnProfession", "Sending %d new skills for profession %s", #newSkills, tostring(professionId));

    -- clear own data reset tombstones for this profession (data exists again, stop re-broadcasting)
    local sentResets = playerService.node.sentDataResets;
    if (sentResets) then
        local storeName = playerService:GetLongName(playerName);
        for i = #sentResets, 1, -1 do
            local entry = sentResets[i];
            if (entry.name == storeName and (entry.professionId == 0 or entry.professionId == professionId)) then
                table.remove(sentResets, i);
            end
        end
    end

    -- send hello message
    self:GetService("profession-sync"):SayHelloToGuild();
end

--- Send all own profession to player.
-- @param playerName Name of player to send professions to.
-- @param playerStorageId Storage id of player to send professions to.
-- @param lastSyncDate Date of last sync.
-- @param sendBack Indicates if can sync back.
-- @param shouldRelay If true, relay offline guildmate data to this player.
function OwnProfessionsService:SendOwnProfessionsToPlayer(playerName, playerStorageId, lastSyncDate, sendBack, shouldRelay)
    -- log send start
    self.addon:Log("OwnProfessionsService", "SendOwnProfessionsToPlayer", "Sending to %s (lastSync=%s, sendBack=%s, relay=%s)", playerName, tostring(lastSyncDate), tostring(sendBack), tostring(shouldRelay));

    -- build a message queue to throttle all outgoing messages
    local messageQueue = {};
    local playerService = self:GetService("player");
    local messageService = self:GetService("message");

    -- collect own profession messages
    for characterName, professions in pairs(playerService.node.own) do
        -- iterate all professions
        local fullName = playerService:GetLongName(characterName);
        for professionId, skills in pairs(professions) do
            self:QueueOwnProfessionMessages(messageQueue, professionId, skills, lastSyncDate, fullName);
        end
    end

    -- queue my characters message with chunking (only if character list changed since last sync)
    if ((not lastSyncDate) or lastSyncDate == 0 or (playerService.node.characterSetUpdated and playerService.node.characterSetUpdated > lastSyncDate)) then
        local messageCharacters = {};
        for characterName, _ in pairs(playerService.node.own) do
            table.insert(messageCharacters, characterName);
        end
        if (#messageCharacters > 0) then
            self:GetService("profession-sync"):QueueMyCharactersMessages(messageQueue, messageCharacters);
        end
    end

    -- queue specializations and cooldowns via combined meta message (only if changed since last sync)
    local PlayerMetaMessage = self:GetModel("player-meta-message");
    for characterName, _ in pairs(playerService.node.own) do
        local fullName = playerService:GetLongName(characterName);
        local specializations = PM_Specializations[fullName] or {};
        local cooldowns = (playerService.node.cooldowns and playerService.node.cooldowns[fullName]) or {};

        -- check if specs or cooldowns changed since last sync
        local specsChanged = (not lastSyncDate) or lastSyncDate == 0 or (playerService.node.specializationsUpdated and playerService.node.specializationsUpdated > lastSyncDate);
        local cooldownsChanged = (not lastSyncDate) or lastSyncDate == 0 or (playerService.node.cooldownsUpdated and playerService.node.cooldownsUpdated[fullName] and playerService.node.cooldownsUpdated[fullName] > lastSyncDate);

        -- send if any meta data exists and is newer
        if ((specsChanged or cooldownsChanged) and (next(specializations) or next(cooldowns))) then
            table.insert(messageQueue, PlayerMetaMessage:Create(characterName, specializations, cooldowns));
        end
    end

    -- queue relay data from offline guildmates (only if designated as relayer)
    if (shouldRelay) then
        -- use the later of receiver's lastSync and our own last-send timestamp
        -- this prevents re-sending relay data that was already sent but dropped by WoW throttling
        local ourLastSend = playerService.node.syncTimes[playerStorageId] or 0;
        local relayLastSync = math.max(lastSyncDate, ourLastSend);
        self:QueueRelayMessages(messageQueue, relayLastSync);
    end

    -- append end-of-sequence marker
    local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
    table.insert(messageQueue, EndOfSequenceMessage:Create("PP"));

    -- send all queued messages via queue (message-service handles throttling)
    self.addon:Log("OwnProfessionsService", "SendOwnProfessionsToPlayer", "Queued %d messages for %s", #messageQueue, playerName);
    for _, message in ipairs(messageQueue) do
        messageService:SendToPlayer(playerName, message, "BULK");
    end

    -- update our own syncTimes for this player after sending
    -- this prevents re-sending the same data if they request again before their syncTimes updates
    if (playerStorageId) then
        playerService.node.syncTimes[playerStorageId] = time();
    end

    -- check if should send back (send immediately, not queued)
    if (sendBack) then
        self:GetService("profession-sync"):RequestProfessionsFromPlayer(playerName, playerStorageId, false, shouldRelay);
    end
end

--- Queue relay messages for offline guildmates into the given queue.
-- @param messageQueue Table to append messages to.
-- @param lastSyncDate Requester's last sync timestamp.
function OwnProfessionsService:QueueRelayMessages(messageQueue, lastSyncDate)
    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");
    local PlayerProfessionsMessage = self:GetModel("player-professions-message");
    local PlayerMetaMessage = self:GetModel("player-meta-message");
    local guildmates = playerService.node.guildmates;
    local syncTimes = playerService.node.syncTimes;

    -- iterate all stored guildmates
    for storeName, professions in pairs(guildmates) do

        -- check if we received this guildmate's data after the requester's last sync
        local fullName = playerService:GetLongName(storeName);
        local dataTimestamp = syncTimes[fullName];
        if (dataTimestamp and dataTimestamp > lastSyncDate) then
            -- check if this guildmate is currently offline
            local guildmate = playerService:GetGuildmate(fullName);
            if (not guildmate or not guildmate.online) then
                -- check if player or a character set member is in the current guild
                local isInCurrentGuild = (guildmate ~= nil);
                if (not isInCurrentGuild) then
                    local characterSet = playerService:FindCharacterSet(storeName);
                    if (characterSet) then
                        for _, twinkName in ipairs(characterSet) do
                            local twinkFullName = playerService:GetLongName(twinkName);
                            if (playerService:IsGuildmate(twinkFullName)) then
                                isInCurrentGuild = true;
                                break;
                            end
                        end
                    end
                end

                -- only relay if related to current guild
                if (isInCurrentGuild) then
                    -- queue profession messages
                    for professionId, skillIds in pairs(professions) do
                        local messageSkills = {};
                        for _, skillId in ipairs(skillIds) do
                            local skill = skillsService:GetSkillById(skillId);
                            local itemId = skill and skill.itemId or 0;
                            table.insert(messageSkills, { skillId = skillId, itemId = itemId });

                            -- chunk at 28 skills per message (6-digit IDs + max-length player names fit 255 bytes)
                            if (#messageSkills == 28) then
                                table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, playerService.node.storageId, fullName, messageSkills));
                                messageSkills = {};
                            end
                        end

                        -- queue remaining
                        if (#messageSkills > 0) then
                            table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, playerService.node.storageId, fullName, messageSkills));
                        end
                    end

                    -- queue character set with chunking (avoids 255-byte overflow)
                    local characterSet = playerService:FindCharacterSet(storeName);
                    if (characterSet and #characterSet > 0) then
                        self:GetService("profession-sync"):QueueMyCharactersMessages(messageQueue, characterSet);
                    end

                    -- queue combined meta (specializations + cooldowns) in single message
                    local specializations = PM_Specializations[fullName] or {};
                    local cooldowns = (playerService.node.cooldowns and playerService.node.cooldowns[fullName]) or {};
                    if (next(specializations) or next(cooldowns)) then
                        table.insert(messageQueue, PlayerMetaMessage:Create(storeName, specializations, cooldowns));
                    end
                end
            end
        end
    end
end

--- Queue own profession skill messages into the given queue.
-- @param messageQueue Table to append messages to.
-- @param professionId Profession id.
-- @param skills List of skills.
-- @param lastSyncDate Only include skills added after this date.
-- @param ownPlayerName Character name to tag the messages with.
function OwnProfessionsService:QueueOwnProfessionMessages(messageQueue, professionId, skills, lastSyncDate, ownPlayerName)
    -- skip gathering professions (not sent to guild)
    if (self:GetService("profession-names"):IsGatheringProfession(professionId)) then
        return;
    end

    local PlayerProfessionsMessage = self:GetModel("player-professions-message");
    local messageSkills = {};

    -- iterate all skills
    for skillIndex = 1, #skills do
        local skill = skills[skillIndex];

        -- skip gathering skills (auto-learned, not synced to guild)
        if (skill.skillId >= 9000000) then
            -- skip
        elseif ((not lastSyncDate) or lastSyncDate == 0 or (not skill.added) or skill.added > lastSyncDate) then
            table.insert(messageSkills, skill);

            -- chunk at 28 skills per message (6-digit IDs + max-length player names fit 255 bytes)
            if (#messageSkills == 28) then
                table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, self:GetService("player").node.storageId, ownPlayerName, messageSkills));
                messageSkills = {};
            end
        end
    end

    -- queue remaining
    if (#messageSkills > 0) then
        table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, self:GetService("player").node.storageId, ownPlayerName, messageSkills));
    end
end

--- Check welcome.
function OwnProfessionsService:CheckWelcome()
    -- check if welcome read
    if (PM_CharacterSettings.welcomeRead) then
        return;
    end

    -- check if player professions read
    local playerService = self:GetService("player");
    if (playerService.node.own[playerService.current]) then
        return;
    end

    -- show welcome view
    self.addon:NewView("welcome"):Show();
end

--- Handle a chat skill-up message for any profession.
-- Parses the skill name and new level from the message, updates stored level,
-- and for gathering professions also updates auto-learned skills.
function OwnProfessionsService:HandleSkillUpMessage(message)
    -- parse skill name and new level using the locale format string
    if (not ERR_SKILL_UP_SI) then return; end
    local pattern;
    if (string.find(ERR_SKILL_UP_SI, "%%%d%$")) then
        -- positional format specifiers (e.g. %1$s, %2$d)
        pattern = string.gsub(ERR_SKILL_UP_SI, "%%%d%$s", "(.+)");
        pattern = string.gsub(pattern, "%%%d%$d", "(%%d+)");
    else
        -- non-positional format specifiers (e.g. %s, %d)
        pattern = string.gsub(ERR_SKILL_UP_SI, "%%s", "(.+)");
        pattern = string.gsub(pattern, "%%d", "(%%d+)");
    end
    local skillName, newLevel = string.match(message, pattern);

    if (not skillName or not newLevel) then
        return;
    end

    newLevel = tonumber(newLevel);
    if (not newLevel) then
        return;
    end

    -- find profession id
    local professionNamesService = self:GetService("profession-names");
    local professionId = professionNamesService:GetProfessionId(skillName);
    if (not professionId) then
        return;
    end

    -- update skill level
    PM_CharacterSettings.professionLevels[professionId] = newLevel;
    self:StoreProfessionLevel(professionId, newLevel);
    self.addon:Log("OwnProfessionsService", "HandleSkillUpMessage", "Skill up: %s (%d) now at level %d", skillName, professionId, newLevel);

    -- for professions with gathering component, update auto-learned skills
    if (self:GetService("profession-names"):HasGatheringComponent(professionId)) then
        self:UpdateGatheringSkills(professionId);
    end

    -- refresh view
    if (self.addon.professionsView) then
        self.addon.professionsView:Refresh();
    end
end

--- Scan character skills to detect gathering professions on login.
-- Tries multiple approaches: skill lines API, GetProfessions API, and IsSpellKnown.
-- Falls back to persisted level from previous sessions.
function OwnProfessionsService:ScanGatheringProfessions()
    -- try to detect gathering professions via available APIs
    local detected = self:DetectGatheringProfessionLevels();
    self.addon:Log("OwnProfessionsService", "ScanGatheringProfessions", "detected %d gathering professions", self:CountTable(detected));

    -- update auto-learned skills for detected professions
    for professionId, _ in pairs(detected) do
        self:UpdateGatheringSkills(professionId);
    end

    -- if nothing detected yet, retry with delay (APIs may not be ready)
    if (not next(detected)) then
        C_Timer.After(5, function()
            local retryDetected = self:DetectGatheringProfessionLevels();
            for professionId, _ in pairs(retryDetected) do
                self:UpdateGatheringSkills(professionId);
            end
        end);
    else
        -- retry for potentially better level data (API may return more accurate levels after delay)
        local previousLevels = {};
        for professionId, _ in pairs(detected) do
            previousLevels[professionId] = PM_CharacterSettings.professionLevels[professionId] or 0;
        end
        C_Timer.After(5, function()
            local retryDetected = self:DetectGatheringProfessionLevels();
            for professionId, _ in pairs(retryDetected) do
                -- update skills only if level increased since first detection
                if ((PM_CharacterSettings.professionLevels[professionId] or 0) > (previousLevels[professionId] or 0)) then
                    self:UpdateGatheringSkills(professionId);
                end
            end
        end);
    end
end

--- Detect gathering profession levels using all available APIs.
-- @return Table of detected gathering profession IDs (keys) with true as value.
function OwnProfessionsService:DetectGatheringProfessionLevels()
    local professionNamesService = self:GetService("profession-names");
    local detected = {};

    -- use shared detection to find all current primary professions with levels
    local currentProfessions = self:DetectCurrentProfessions();
    for professionId, skillRank in pairs(currentProfessions) do
        -- store the level for every detected profession, not only gathering:
        -- the profession windows also store on open, but bar, max-level layout
        -- and difficulty colors need a valid level from login on
        if (skillRank > 0) then
            PM_CharacterSettings.professionLevels[professionId] = skillRank;
            self:StoreProfessionLevel(professionId, skillRank);
        end

        -- filter for gathering professions only
        if (professionNamesService:HasGatheringComponent(professionId)) then
            if (skillRank <= 0 and not PM_CharacterSettings.professionLevels[professionId]) then
                PM_CharacterSettings.professionLevels[professionId] = 1;
                self:StoreProfessionLevel(professionId, 1);
            end
            self.addon:Log("OwnProfessionsService", "DetectGatheringProfessionLevels", "Found %s at level %d", tostring(professionId), PM_CharacterSettings.professionLevels[professionId]);
            detected[professionId] = true;
        end
    end

    -- fallback: check spellbook for gathering profession spells (when API returned nothing)
    if (not next(detected) and self.addon.compat.GetNumSpellTabs and self.addon.compat.GetSpellTabInfo) then
        for professionId, _ in pairs(professionNamesService:GetGatheringProfessionIds()) do
            local professionName = professionNamesService:GetProfessionName(professionId);
            if (professionName) then
                local found = false;
                for tabIndex = 1, self.addon.compat.GetNumSpellTabs() do
                    local tabName = self.addon.compat.GetSpellTabInfo(tabIndex);
                    if (tabName == professionName) then
                        found = true;
                        break;
                    end
                end
                if (found and not detected[professionId]) then
                    if (not PM_CharacterSettings.professionLevels[professionId]) then
                        PM_CharacterSettings.professionLevels[professionId] = 1;
                        self:StoreProfessionLevel(professionId, 1);
                    end
                    detected[professionId] = true;
                    self.addon:Log("OwnProfessionsService", "DetectGatheringProfessionLevels", "Found %s via spellbook tab", professionName);
                end
            end
        end
    end

    -- fallback: use persisted level from previous session
    for professionId, _ in pairs(professionNamesService:GetGatheringProfessionIds()) do
        if (not detected[professionId] and PM_CharacterSettings.professionLevels[professionId]) then
            detected[professionId] = true;
        end
    end

    return detected;
end

--- Count entries in a table (for logging).
function OwnProfessionsService:CountTable(tbl)
    local count = 0;
    for _ in pairs(tbl) do count = count + 1; end
    return count;
end

--- Update auto-learned skills for a gathering profession based on current skill level.
-- Adds all herbs/nodes where the required skill (d1) is at or below the current level.
-- @param professionId The gathering profession ID (e.g. 182 for Herbalism).
function OwnProfessionsService:UpdateGatheringSkills(professionId)
    -- get current level
    local currentLevel = PM_CharacterSettings.professionLevels
        and PM_CharacterSettings.professionLevels[professionId] or 0;
    if (currentLevel == 0) then
        return;
    end

    local skillsService = self:GetService("skills");
    local playerService = self:GetService("player");
    local playerName = playerService.current;

    -- ensure own professions entry exists
    if (not playerService.node.own[playerName]) then
        playerService.node.own[playerName] = {};
        playerService.node.characterSetUpdated = time();
    end

    local ownProfessions = playerService.node.own[playerName];
    if (not ownProfessions[professionId]) then
        ownProfessions[professionId] = {};
    end

    -- build lookup of existing skill ids
    local existingSkillIds = {};
    for _, skill in ipairs(ownProfessions[professionId]) do
        existingSkillIds[skill.skillId] = true;
    end

    -- iterate all gathering skills for this profession (synthetic IDs >= 9000000)
    local addedCount = 0;
    for skillId, skillData in pairs(skillsService.allSkills) do
        if (skillData.professionId == professionId and skillId >= 9000000) then
            local d1 = skillData.difficulty and skillData.difficulty[1] or 0;
            if (d1 > 0 and d1 <= currentLevel and not existingSkillIds[skillId]) then
                table.insert(ownProfessions[professionId], {
                    skillId = skillId,
                    itemId = skillData.itemId or 0,
                    added = time()
                });
                existingSkillIds[skillId] = true;
                addedCount = addedCount + 1;
            end
        end
    end

    -- log and refresh if new skills were added
    if (addedCount > 0) then
        self.addon:Log("OwnProfessionsService", "UpdateGatheringSkills", "Added %d gathering skills for profession %d (level=%d)", addedCount, professionId, currentLevel);

        -- refresh view
        if (self.addon.professionsView) then
            self.addon.professionsView:Refresh();
        end
    end
end

-- secondary profession IDs (cannot be unlearned, never removed)
local SECONDARY_PROFESSION_IDS = { [185] = true, [356] = true, [129] = true };

--- Detect all current primary professions for the active character using available APIs.
-- @return Table of detected profession IDs (keys) with skill level as value (0 if level unknown), or empty table if API not ready.
-- @return Amount of abandonable skill lines whose name could not be mapped to a profession id (locale mismatch).
function OwnProfessionsService:DetectCurrentProfessions()
    local professionNamesService = self:GetService("profession-names");
    local currentProfessions = {};
    local unresolvedCount = 0;

    -- approach 1: Classic Era / TBC / Wrath skill lines API
    if (self.addon.compat.GetNumSkillLines and self.addon.compat.GetSkillLineInfo) then
        -- expand all headers so hidden skills become visible
        if (self.addon.compat.ExpandSkillHeader) then
            self.addon.compat.ExpandSkillHeader(0);
        end

        for i = 1, self.addon.compat.GetNumSkillLines() do
            local skillName, isHeader, _, skillRank, _, _, _, isAbandonable = self.addon.compat.GetSkillLineInfo(i);
            if (skillName and not isHeader and isAbandonable) then
                -- primary profession (abandonable)
                local professionId = professionNamesService:GetProfessionId(skillName);
                if (professionId) then
                    currentProfessions[professionId] = (skillRank and skillRank > 0) and skillRank or 0;
                else
                    -- skill line name not mappable (locale alias not learned yet)
                    unresolvedCount = unresolvedCount + 1;
                end
            end
        end
    end

    -- approach 2: Cata / MoP API (GetProfessions returns only primary professions)
    if (GetProfessions and GetProfessionInfo) then
        local prof1, prof2 = GetProfessions();
        local profIndices = {};
        if (prof1) then table.insert(profIndices, prof1); end
        if (prof2) then table.insert(profIndices, prof2); end

        for _, profIndex in ipairs(profIndices) do
            local name, _, skillLevel = GetProfessionInfo(profIndex);
            if (name) then
                local professionId = professionNamesService:GetProfessionId(name);
                if (professionId) then
                    if (not currentProfessions[professionId]) then
                        currentProfessions[professionId] = (skillLevel and skillLevel > 0) and skillLevel or 0;
                    end
                else
                    -- profession name not mappable (locale alias not learned yet)
                    unresolvedCount = unresolvedCount + 1;
                end
            end
        end
    end

    return currentProfessions, unresolvedCount;
end

--- Remove first aid skills that older versions stored as own or guildmate
--- profession skills (the first aid window was scanned as tailoring or alchemy)
--- and reset affected own professions guild wide so remote copies drop them too.
--- Runs once per login and is a no-op when nothing is left to remove.
function OwnProfessionsService:RepairFirstAidSkills()
    local playerService = self:GetService("player");
    local skillsService = self:GetService("skills");

    -- strip first aid skills from own characters
    local repairedOwn = {};
    for characterName, professions in pairs(playerService.node.own) do
        for professionId, skills in pairs(professions) do
            local removed = false;
            for i = #skills, 1, -1 do
                if (skillsService:IsFirstAidSkill(skills[i].skillId)) then
                    table.remove(skills, i);
                    removed = true;
                end
            end
            if (removed) then
                table.insert(repairedOwn, { characterName = characterName, professionId = professionId, empty = (#skills == 0) });
            end
        end
    end

    -- remove own professions that only consisted of first aid skills
    for _, repaired in ipairs(repairedOwn) do
        if (repaired.empty) then
            playerService.node.own[repaired.characterName][repaired.professionId] = nil;
        end
    end

    -- strip first aid skills received from affected guild members
    local removedFromGuildmates = false;
    for _, professions in pairs(playerService.node.guildmates) do
        for _, skillIds in pairs(professions) do
            for i = #skillIds, 1, -1 do
                if (skillsService:IsFirstAidSkill(skillIds[i])) then
                    table.remove(skillIds, i);
                    removedFromGuildmates = true;
                end
            end
        end
    end

    -- nothing to repair
    if (#repairedOwn == 0 and not removedFromGuildmates) then
        return;
    end

    -- rebuild skill index and fingerprint after data changes
    self.addon:Log("OwnProfessionsService", "RepairFirstAidSkills", "Removed first aid skills from %d own professions (guildmates changed: %s)", #repairedOwn, tostring(removedFromGuildmates));
    self:GetService("profession-query"):ScheduleRebuild();
    self:GetService("profession-store"):ScheduleRefresh();

    -- reset affected own professions guild wide
    local purgeService = self:GetService("purge");
    for _, repaired in ipairs(repairedOwn) do
        purgeService:BroadcastDataReset(playerService:GetLongName(repaired.characterName), repaired.professionId);
    end
end

--- Detect current primary professions and remove any stored ones that were dropped.
-- Called once per session on SKILL_LINES_CHANGED to clean up unlearned professions.
function OwnProfessionsService:CleanupDroppedProfessions()
    local playerService = self:GetService("player");
    local characterName = playerService.current;

    -- skip if no professions stored for this character
    local ownProfessions = playerService.node.own[characterName];
    if (not ownProfessions) then
        return;
    end

    -- detect current professions (same approach as gathering detection)
    local currentProfessions, unresolvedCount = self:DetectCurrentProfessions();

    -- safety: skip if no professions detected (API might not be ready)
    if (not next(currentProfessions)) then
        return;
    end

    -- safety: skip if any skill line could not be mapped to a profession id,
    -- the unmapped line could be a stored profession (locale mismatch)
    if (unresolvedCount > 0) then
        self.addon:Log("OwnProfessionsService", "CleanupDroppedProfessions", "Skipping cleanup, %d unresolved skill lines", unresolvedCount);
        return;
    end

    -- check stored professions against detected current ones
    local removedAny = false;
    local droppedProfessionIds = {};
    for storedProfessionId, _ in pairs(ownProfessions) do
        -- only check primary professions (secondaries cannot be dropped)
        if (not SECONDARY_PROFESSION_IDS[storedProfessionId] and not currentProfessions[storedProfessionId]) then
            self.addon:Log("OwnProfessionsService", "CleanupDroppedProfessions", "Removing dropped profession %s from %s", tostring(storedProfessionId), characterName);
            ownProfessions[storedProfessionId] = nil;
            table.insert(droppedProfessionIds, storedProfessionId);
            removedAny = true;
        end
    end

    -- clean up guildmates store and rebuild index if any professions were removed
    if (removedAny) then
        -- remove from guildmates store
        local storeName = playerService:GetLongName(playerService.current);
        local guildmateEntry = playerService.node.guildmates[storeName];
        if (guildmateEntry) then
            for storedProfessionId, _ in pairs(guildmateEntry) do
                if (not SECONDARY_PROFESSION_IDS[storedProfessionId] and not currentProfessions[storedProfessionId]) then
                    guildmateEntry[storedProfessionId] = nil;
                end
            end
        end

        -- remove profession levels for dropped professions
        if (PM_CharacterSettings.professionLevels) then
            for storedProfessionId, _ in pairs(PM_CharacterSettings.professionLevels) do
                if (not SECONDARY_PROFESSION_IDS[storedProfessionId] and not currentProfessions[storedProfessionId]) then
                    PM_CharacterSettings.professionLevels[storedProfessionId] = nil;
                end
            end
        end

        -- rebuild skill index and update fingerprint (deferred, runs at login)
        self:GetService("profession-query"):ScheduleRebuild();
        self:GetService("profession-store"):ScheduleRefresh();

        -- broadcast scoped data resets so other players drop the unlearned professions too
        local purgeService = self:GetService("purge");
        for _, droppedProfessionId in ipairs(droppedProfessionIds) do
            purgeService:BroadcastDataReset(storeName, droppedProfessionId);
        end
    end
end

