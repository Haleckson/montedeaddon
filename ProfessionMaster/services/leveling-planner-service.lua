--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local LevelingPlannerService = _G.professionMaster:CreateService("leveling-planner");

--- Initialize service.
-- The service calculates the cheapest way to level a crafting profession from
-- the current skill level to the chosen target (a rank cap, by default the max
-- level of the client). Every skill point takes the recipe with the lowest
-- expected cost for that point (crafts needed for one point times the reagent
-- cost). Reagents are priced along their real
-- supply: own items first (bags, bank, mail), then vendor, then the auction
-- house offers of the last scan level by level, so buying 80 units walks up the
-- price ladder instead of assuming the cheapest price for all of them.
-- Recipes sold on the auction house are tried one by one on top of the known
-- and trainer recipes and kept when they make the whole way cheaper.
function LevelingPlannerService:Initialize()
    -- skill level at which the next rank has to be trained at the trainer
    self.RankLevels = {
        { level = 75, key = "ProfessionsViewRankJourneyman" },
        { level = 150, key = "ProfessionsViewRankExpert" },
        { level = 225, key = "ProfessionsViewRankArtisan" },
        { level = 300, key = "ProfessionsViewRankMaster" },
        { level = 375, key = "ProfessionsViewRankGrandMaster" },
        { level = 450, key = "ProfessionsViewRankIllustriousGrandMaster" },
        { level = 525, key = "ProfessionsViewRankZenMaster" },
    };

    -- milliseconds a calculation may take per frame
    self.FrameBudget = 8;

    -- rounds of trying the auction house recipes again after one was accepted
    self.MaxRecipeRounds = 3;

    -- recipes at most this much more expensive per point than the cheapest count as equal
    -- (share of the cost plus a few copper, cheap low level recipes differ by single coppers)
    self.SwitchTolerance = 0.1;
    self.SwitchToleranceCopper = 10;

    -- nesting depth for reagents the character crafts from other reagents
    self.MaxCraftDepth = 2;

    -- order of the reagent sources in the plan
    self.SourceOrder = { bags = 1, bank = 2, mail = 3, produced = 4, vendor = 5, auction = 6, estimate = 7, craft = 8, missing = 9 };

    -- seconds the changes of skill, recipes and bags are collected before the open plan follows them
    self.RefreshDelay = 0.5;

    self.generation = 0;

    -- finished plans of this session per character and profession: the window
    -- reopens with them and they follow the skill ups like a to do list
    self.plans = {};

    -- target levels chosen in this session per character and profession
    self.targets = {};

    -- recipes the chat reported as learned before the profession window was scanned again
    self.learnedSkills = {};
    self.listeners = {};

    -- everything a plan follows: skill ups, a trained rank, learned recipes
    -- (own scan of the profession window) and bought or used reagents
    for _, event in ipairs({ "CHAT_MSG_SKILL", "SKILL_LINES_CHANGED", "TRADE_SKILL_UPDATE", "CRAFT_UPDATE" }) do
        self:HandleEvent(event, function()
            self:ScheduleRefresh("progress");
        end);
    end
    self:HandleEvent("BAG_UPDATE_DELAYED", function()
        self:ScheduleRefresh("bags");
    end);
    self:HandleEvent("CHAT_MSG_SYSTEM", function(message)
        self:HandleLearnedRecipeMessage(message);
    end);
end

--- Register a listener called when the plans may have changed.
-- @param callback Function(reasons): set with "progress" (skill up, rank, recipe), "bags" and "calculated" (a new plan was calculated).
function LevelingPlannerService:AddListener(callback)
    table.insert(self.listeners, callback);
end

--- Notify the listeners.
-- @param reasons Set of reasons, see AddListener.
function LevelingPlannerService:Notify(reasons)
    for _, listener in ipairs(self.listeners) do
        listener(reasons);
    end
end

--- Notify the listeners once after a burst of events. The data is read when
--- the timer fires, so the other services have handled the same events by then.
-- @param reason "progress" or "bags".
function LevelingPlannerService:ScheduleRefresh(reason)
    if (next(self.plans) == nil) then
        return;
    end

    self.refreshReasons = self.refreshReasons or {};
    self.refreshReasons[reason] = true;
    if (self.refreshPending) then
        return;
    end

    self.refreshPending = true;
    C_Timer.After(self.RefreshDelay, function()
        local reasons = self.refreshReasons or {};
        self.refreshPending = nil;
        self.refreshReasons = nil;
        self:Notify(reasons);
    end);
end

--- Get a cheap fingerprint of everything a plan in progress follows except
--- the bags: skill level, trained rank and known recipes. Lets the windows
--- skip the many skill events that do not concern the profession (weapon skills).
-- @return fingerprint string.
function LevelingPlannerService:GetPlanSignature(characterName, professionId)
    local playerService = self:GetService("player");
    local maxRank = (characterName == playerService.current) and self:GetMaxRank(professionId) or nil;
    local ownProfessions = playerService.node.own[characterName];
    local learnedCount = 0;
    for _ in pairs(self.learnedSkills) do
        learnedCount = learnedCount + 1;
    end
    return table.concat({
        tostring(self:GetCurrentLevel(characterName, professionId)),
        tostring(maxRank),
        #(ownProfessions and ownProfessions[professionId] or {}),
        learnedCount,
    }, ":");
end

--- Show the small to do list of a plan (the view is created on first use).
-- @param characterName The character name.
-- @param professionId The profession id.
function LevelingPlannerService:ShowTodo(characterName, professionId)
    if (not self.addon.levelingTodoView) then
        self.addon.levelingTodoView = self.addon:NewView("leveling-todo");
    end
    self.addon.levelingTodoView:Show(characterName, professionId);
end

--- Show the to do list again that was open when the character logged out.
function LevelingPlannerService:RestoreTodo()
    local professionId = PM_CharacterSettings.levelingTodo;
    if (professionId) then
        self.addon:Log("LevelingPlannerService", "RestoreTodo", "restoring the to do list of profession %s", tostring(professionId));
        self:ShowTodo(self:GetService("player").current, professionId);
    end
end

--- Store the run of the logged in character in its character settings, so the
--- plan and its to do list survive a reload: the recipe per skill range and the
--- recipes bought on the auction house with item and price. The crafts per
--- point follow from the recipe difficulty.
-- @param context The calculation context.
-- @param run The chosen run.
function LevelingPlannerService:SavePlan(context, run)
    if (not context.isCurrentCharacter) then
        return;
    end

    local segments = {};
    local recipes = {};
    local segment;
    for level = context.startLevel, run.reachedLevel - 1 do
        local recipe = run.choices[level];
        if (segment and segment[3] == recipe.skillId) then
            segment[2] = level + 1;
        else
            segment = { level, level + 1, recipe.skillId };
            table.insert(segments, segment);
        end
        if (recipe.source == "auction") then
            recipes[recipe.skillId] = { recipe.recipeItemId, recipe.price };
        end
    end

    if (not PM_CharacterSettings.levelingPlans) then
        PM_CharacterSettings.levelingPlans = {};
    end
    PM_CharacterSettings.levelingPlans[context.professionId] = {
        startLevel = context.startLevel,
        targetLevel = context.targetLevel,
        reachedLevel = run.reachedLevel,
        segments = segments,
        recipes = recipes,
    };
end

--- Delete the stored plan of a profession of the logged in character.
function LevelingPlannerService:DeleteStoredPlan(characterName, professionId)
    if (characterName == self:GetService("player").current and PM_CharacterSettings.levelingPlans) then
        PM_CharacterSettings.levelingPlans[professionId] = nil;
    end
end

--- Rebuild the plan stored for the logged in character (see SavePlan). A
--- stored plan that no longer matches the skill data is dropped.
-- @return cache entry { context, run }, or nil.
function LevelingPlannerService:RestorePlan(characterName, professionId)
    local stored = PM_CharacterSettings.levelingPlans and PM_CharacterSettings.levelingPlans[professionId];
    if (not stored or characterName ~= self:GetService("player").current) then
        return nil;
    end

    local skillsService = self:GetService("skills");
    local context = self:CreateContext(characterName, professionId, stored.startLevel, stored.targetLevel);
    local known = self:GetKnownSkills(characterName, professionId);
    local recipesById = {};
    for _, recipe in ipairs(context.recipes) do
        recipesById[recipe.skillId] = recipe;
    end

    local run = { choices = {}, crafts = {}, used = {}, totalCost = 0, reachedLevel = stored.reachedLevel };
    for _, segment in ipairs(stored.segments or {}) do
        local skillId = segment[3];
        local recipe = recipesById[skillId];

        -- a recipe of the auction house whose offers are gone by now keeps its stored item and price
        local skill = skillsService.allSkills[skillId];
        local storedRecipe = stored.recipes and stored.recipes[skillId];
        if (not recipe and storedRecipe and skill and skill.reagents and self:HasDifficulty(skill.difficulty)) then
            recipe = self:CreateRecipe(context, skillId, skill, known);
            if (not recipe.source) then
                recipe.source = "auction";
                recipe.recipeItemId, recipe.price, recipe.recipeOwned = storedRecipe[1], storedRecipe[2], false;
            end
            table.insert(context.recipes, recipe);
            recipesById[skillId] = recipe;
        end

        -- every point of the range must still be a point of the recipe
        for level = segment[1], segment[2] - 1 do
            if (recipe and (recipe.difficulty[1] or 0) <= level and level < recipe.difficulty[4]) then
                run.choices[level] = recipe;
                run.crafts[level] = 1 / self:GetSkillUpChance(recipe.difficulty, level);
            end
        end
    end

    -- the ranges must cover the whole way without a gap
    for level = stored.startLevel, stored.reachedLevel - 1 do
        if (not run.choices[level]) then
            self:DeleteStoredPlan(characterName, professionId);
            self.addon:Log("LevelingPlannerService", "RestorePlan", "stored plan of profession %d no longer matches the skill data, dropped", professionId);
            return nil;
        end
    end

    self.addon:Log("LevelingPlannerService", "RestorePlan", "restored the stored plan of profession %d (%d to %d)", professionId, stored.startLevel, stored.reachedLevel);
    return { context = context, run = run };
end

--- Mark a recipe of the cached plans as known when the chat reports it as
--- learned (recipe item read with the profession window closed). Only an exact
--- name match with a recipe of a plan counts; the scan of the profession
--- window confirms it later anyway.
-- @param message The system chat message.
function LevelingPlannerService:HandleLearnedRecipeMessage(message)
    if (not ERR_LEARN_RECIPE_S or not message or next(self.plans) == nil) then
        return;
    end

    -- build the match pattern from the localized format string once
    if (not self.learnedRecipePattern) then
        local pattern = string.gsub(ERR_LEARN_RECIPE_S, "[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0");
        pattern = string.gsub(pattern, "%%%d%%%$s", "(.+)");
        pattern = string.gsub(pattern, "%%s", "(.+)");
        self.learnedRecipePattern = "^" .. pattern .. "$";
    end

    local recipeName = string.match(message, self.learnedRecipePattern);
    if (not recipeName) then
        return;
    end

    for _, entry in pairs(self.plans) do
        if (entry.context.isCurrentCharacter) then
            for _, recipe in ipairs(entry.context.recipes) do
                if (recipe.source ~= "known" and recipe.skill.name == recipeName) then
                    recipe.source = "known";
                    self.learnedSkills[recipe.skillId] = true;
                    self.addon:Log("LevelingPlannerService", "HandleLearnedRecipeMessage", "recipe of skill %d learned, plan updated", recipe.skillId);
                    self:ScheduleRefresh("progress");
                end
            end
        end
    end
end

--- Get the key of a cached plan.
function LevelingPlannerService:GetPlanKey(characterName, professionId)
    return tostring(characterName) .. ":" .. tostring(professionId);
end

--- Get the plan calculated earlier in this session, brought up to date as a to
--- do list: steps below the current skill level are done, the step in progress
--- needs fewer crafts, learned recipes are no longer bought, a trained rank is
--- no longer asked for and the reagents are priced again with the current bags
--- and offers. The chosen recipes stay, only "recalculate" looks for a new way.
-- @param characterName The character name.
-- @param professionId The profession id.
-- @return plan, or nil when nothing usable is cached (never calculated, skill below the start, end of a stuck plan reached).
function LevelingPlannerService:GetCachedPlan(characterName, professionId)
    local key = self:GetPlanKey(characterName, professionId);
    local entry = self.plans[key];
    if (not entry) then
        -- the plan of an earlier session of this character
        entry = self:RestorePlan(characterName, professionId);
        if (not entry) then
            return nil;
        end
        self.plans[key] = entry;
    end

    local context = entry.context;
    local run = entry.run;
    local level = math.max(self:GetCurrentLevel(characterName, professionId) or 0, 1);

    -- a finished plan needs no place in the character settings any more
    if (level >= run.reachedLevel) then
        self:DeleteStoredPlan(characterName, professionId);
    end

    -- the end of a plan that got stuck is worth a new search once the character
    -- got there; a plan that was stuck from its start on stays (it would be
    -- calculated again and again with the same result)
    local reachedStuckEnd = level >= run.reachedLevel and run.reachedLevel < context.targetLevel and level > context.startLevel;
    if (level < context.startLevel or reachedStuckEnd) then
        self.plans[key] = nil;
        self:DeleteStoredPlan(characterName, professionId);
        self.addon:Log("LevelingPlannerService", "GetCachedPlan", "cached plan of profession %d no longer fits skill %d", professionId, level);
        return nil;
    end

    self:RefreshContext(context);
    return self:BuildSteps(context, run, level);
end

--- Bring the context of a cached plan up to date: bags, offers, learned
--- recipes and the recipe items bought in the meantime.
-- @param context The calculation context.
function LevelingPlannerService:RefreshContext(context)
    context.ladders = {};
    if (context.isCurrentCharacter) then
        self:GetService("inventory"):ScanInventory();
    end

    local known = self:GetKnownSkills(context.characterName, context.professionId);
    for _, recipe in ipairs(context.recipes) do
        if (recipe.source ~= "known" and known[recipe.skillId]) then
            recipe.source = "known";
        elseif (recipe.source == "auction") then
            -- a recipe item bought in the meantime is owned now, offers may have changed
            local recipeItemId, price, owned = self:FindRecipeOffer(context, recipe.skill);
            if (recipeItemId) then
                recipe.recipeItemId, recipe.price, recipe.recipeOwned = recipeItemId, price, owned;
            end
        end
    end
end

--- Get the recipes a character knows: the own scan of the profession window
--- plus the recipes the chat reported as learned since (current character).
-- @return set of skill ids.
function LevelingPlannerService:GetKnownSkills(characterName, professionId)
    local playerService = self:GetService("player");
    local known = {};
    local ownProfessions = playerService.node.own[characterName];
    for _, ownSkill in ipairs(ownProfessions and ownProfessions[professionId] or {}) do
        known[ownSkill.skillId] = true;
    end
    if (characterName == playerService.current) then
        for skillId in pairs(self.learnedSkills) do
            known[skillId] = true;
        end
    end
    return known;
end

--- Get the skill cap of the rank the logged in character has trained in a
--- profession (75, 150, ...), so a rank that is already trained is not asked for.
-- @param professionId The profession id.
-- @return max rank, or nil when the client does not tell (profession not learned).
function LevelingPlannerService:GetMaxRank(professionId)
    local professionNamesService = self:GetService("profession-names");

    -- vanilla, tbc, wrath: skill lines
    if (self.addon.compat.GetNumSkillLines and self.addon.compat.GetSkillLineInfo) then
        for index = 1, self.addon.compat.GetNumSkillLines() do
            local skillName, isHeader, _, _, _, _, skillMaxRank = self.addon.compat.GetSkillLineInfo(index);
            if (skillName and not isHeader and professionNamesService:GetProfessionId(skillName) == professionId) then
                return skillMaxRank;
            end
        end
    end

    -- cata, mop: profession slots
    if (GetProfessions and GetProfessionInfo) then
        for _, professionIndex in pairs({ GetProfessions() }) do
            local name, _, _, maxSkillLevel, _, _, skillLine = GetProfessionInfo(professionIndex);
            if (skillLine == professionId or (name and professionNamesService:GetProfessionId(name) == professionId)) then
                return maxSkillLevel;
            end
        end
    end

    return nil;
end

--- Get the max skill level of the running client.
-- @return max skill level.
function LevelingPlannerService:GetMaxLevel()
    local addon = self.addon;
    if (addon.isMop) then return 600; end
    if (addon.isCata) then return 525; end
    if (addon.isWrath) then return 450; end
    if (addon.isBcc) then return 375; end
    return 300;
end

--- Get the skill caps of the trainer ranks up to the max level of the client
--- (75, 150, 225, ...): the targets of a plan and the limits of the own list.
-- @param aboveLevel Only caps above this skill level (optional).
-- @return list of skill levels, ascending, the max level of the client last.
function LevelingPlannerService:GetRankCaps(aboveLevel)
    local maxLevel = self:GetMaxLevel();
    local caps = {};
    for _, rank in ipairs(self.RankLevels) do
        if (rank.level < maxLevel and rank.level > (aboveLevel or 0)) then
            table.insert(caps, rank.level);
        end
    end
    table.insert(caps, maxLevel);
    return caps;
end

--- Get the level a new plan aims at: the target chosen for the character and
--- profession (in this session, or the one of the stored plan after a reload)
--- while it is above the skill level, otherwise the max level of the client.
-- @param characterName The character name.
-- @param professionId The profession id.
-- @return target skill level.
function LevelingPlannerService:GetTargetLevel(characterName, professionId)
    local maxLevel = self:GetMaxLevel();
    local target = self.targets[self:GetPlanKey(characterName, professionId)];
    if (not target and characterName == self:GetService("player").current) then
        local stored = PM_CharacterSettings.levelingPlans and PM_CharacterSettings.levelingPlans[professionId];
        target = stored and stored.targetLevel;
    end

    -- a reached target gives way to the max level
    local level = math.max(self:GetCurrentLevel(characterName, professionId) or 0, 1);
    if (not target or target <= level or target > maxLevel) then
        return maxLevel;
    end
    return target;
end

--- Get the stored skill level of a character in a profession.
-- @param characterName The character name.
-- @param professionId The profession id.
-- @return skill level or nil if unknown.
function LevelingPlannerService:GetCurrentLevel(characterName, professionId)
    local playerService = self:GetService("player");
    if (characterName == playerService.current) then
        return PM_CharacterSettings.professionLevels and PM_CharacterSettings.professionLevels[professionId];
    end

    local ownLevels = playerService.node.ownLevels and playerService.node.ownLevels[characterName];
    return ownLevels and ownLevels[professionId];
end

--- Check whether the planner can work for a profession: a crafting profession
--- below the max level with a known skill level.
-- @param characterName The character name.
-- @param professionId The profession id.
-- @return true if a plan can be calculated.
function LevelingPlannerService:CanPlan(characterName, professionId)
    if (not professionId or professionId <= 0 or self:GetService("profession-names"):IsGatheringProfession(professionId)) then
        return false;
    end

    local level = self:GetCurrentLevel(characterName, professionId);
    return level ~= nil and level < self:GetMaxLevel();
end

--- Start the calculation of a plan. It runs spread over several frames; a
--- new call cancels a running calculation.
-- @param characterName The character to plan for.
-- @param professionId The profession id.
-- @param onProgress Function(fraction) called while calculating.
-- @param onFinish Function(plan) called with the finished plan (nil on error).
-- @param targetLevel Skill level to plan to (optional, default the chosen target, see GetTargetLevel).
function LevelingPlannerService:Calculate(characterName, professionId, onProgress, onFinish, targetLevel)
    self:Cancel();
    self.generation = self.generation + 1;
    local generation = self.generation;

    -- learning a profession starts at skill 1, a profession without level (debug only) plans from there
    local startLevel = math.max(self:GetCurrentLevel(characterName, professionId) or 0, 1);

    -- the target is kept for the next calculations of this character and profession
    if (not targetLevel or targetLevel <= startLevel or targetLevel > self:GetMaxLevel()) then
        targetLevel = self:GetTargetLevel(characterName, professionId);
    end
    self.targets[self:GetPlanKey(characterName, professionId)] = targetLevel;
    self.addon:Log("LevelingPlannerService", "Calculate", "planning profession %d for %s from %d to %d", professionId, tostring(characterName), startLevel, targetLevel);

    local worker = coroutine.create(function()
        return self:BuildPlan(characterName, professionId, startLevel, targetLevel, onProgress);
    end);

    -- resume the worker once per frame until it is done
    self.ticker = C_Timer.NewTicker(0, function()
        if (self.generation ~= generation) then
            return;
        end

        self.frameStart = debugprofilestop();
        local success, result = coroutine.resume(worker);
        if (not success) then
            self:Cancel();
            self.addon:Log("LevelingPlannerService", "Calculate", "calculation failed: %s", tostring(result));
            onFinish(nil);
            return;
        end

        if (coroutine.status(worker) == "dead") then
            self:Cancel();
            onFinish(result);
            self:Notify({ calculated = true });
        end
    end);
end

--- Cancel a running calculation.
function LevelingPlannerService:Cancel()
    if (self.ticker) then
        self.ticker:Cancel();
        self.ticker = nil;
    end
end

--- Check if a calculation is running.
-- @return true while calculating.
function LevelingPlannerService:IsCalculating()
    return self.ticker ~= nil;
end

--- Hand the frame back when the calculation used up its time budget.
function LevelingPlannerService:YieldIfBusy()
    if (debugprofilestop() - self.frameStart > self.FrameBudget) then
        coroutine.yield();
    end
end

--- Check whether a difficulty table is complete (orange, yellow, green, grey).
-- @param difficulty Difficulty table {d1, d2, d3, d4}.
-- @return true if the skill up chance can be calculated.
function LevelingPlannerService:HasDifficulty(difficulty)
    return difficulty ~= nil and (difficulty[2] or 0) > 0 and (difficulty[4] or 0) > 0 and difficulty[4] >= difficulty[2];
end

--- Get the chance of a skill point when crafting at a skill level: always on
--- orange, falling from yellow to grey.
-- @param difficulty Difficulty table {d1, d2, d3, d4}.
-- @param level The skill level.
-- @return chance between 0 and 1.
function LevelingPlannerService:GetSkillUpChance(difficulty, level)
    local yellow = difficulty[2];
    local grey = difficulty[4];
    if (level < yellow) then
        return 1;
    end
    if (level >= grey) then
        return 0;
    end
    return (grey - level) / (grey - yellow);
end

--- Build the plan (runs inside the worker coroutine).
-- @return plan table.
function LevelingPlannerService:BuildPlan(characterName, professionId, startLevel, targetLevel, onProgress)
    local context = self:CreateContext(characterName, professionId, startLevel, targetLevel);

    -- the way with the recipes the character knows or a trainer teaches
    local accepted = {};
    local best = self:RunGreedy(context, accepted);
    onProgress(0.1);

    -- try the recipes of the auction house one by one, a recipe stays when the
    -- whole way gets cheaper or goes further with it
    local candidates = context.auctionRecipes;
    for round = 1, self.MaxRecipeRounds do
        local improved = false;
        for index, candidate in ipairs(candidates) do
            local worthTrying = (not accepted[candidate.skillId])
                and (best.reachedLevel < targetLevel or candidate.price < best.totalCost);
            if (worthTrying) then
                accepted[candidate.skillId] = true;
                local trial = self:RunGreedy(context, accepted);
                if (trial.reachedLevel > best.reachedLevel or (trial.reachedLevel == best.reachedLevel and trial.totalCost < best.totalCost)) then
                    best = trial;
                    improved = true;
                    self.addon:Log("LevelingPlannerService", "BuildPlan", "recipe of skill %d from the auction house makes the way cheaper", candidate.skillId);

                    -- recipes the new way does not use any more are dropped again
                    for skillId in pairs(accepted) do
                        if (not trial.used[skillId]) then
                            accepted[skillId] = nil;
                        end
                    end
                else
                    accepted[candidate.skillId] = nil;
                end
            end
            onProgress(0.1 + 0.85 * ((round - 1) + index / #candidates) / self.MaxRecipeRounds);
        end
        if (not improved) then
            break;
        end
    end

    self.plans[self:GetPlanKey(characterName, professionId)] = { context = context, run = best };
    self:SavePlan(context, best);
    local plan = self:BuildSteps(context, best, startLevel);
    onProgress(1);
    self.addon:Log("LevelingPlannerService", "BuildPlan", "plan finished: level %d of %d reached, %d steps, %d copper", plan.reachedLevel, targetLevel, #plan.steps, plan.totalCost);
    return plan;
end

--- Collect everything a calculation needs once: the usable recipes of the
--- profession, the auction house recipes and the reagents the character can craft.
-- @return context table.
function LevelingPlannerService:CreateContext(characterName, professionId, startLevel, targetLevel)
    local skillsService = self:GetService("skills");
    local playerService = self:GetService("player");

    local context = {
        characterName = characterName,
        professionId = professionId,
        startLevel = startLevel,
        targetLevel = targetLevel,
        isCurrentCharacter = (characterName == playerService.current),
        recipes = {},
        auctionRecipes = {},
        craftRecipes = {},
        ladders = {},
    };

    -- own items only count for the logged in character (bags, bank and mail are per character)
    if (context.isCurrentCharacter) then
        self:GetService("inventory"):ScanInventory();
    end

    -- recipes the character already knows
    local known = self:GetKnownSkills(characterName, professionId);

    -- recipes with a cooldown (transmutes, mooncloth) cannot be crafted in bulk,
    -- neither for skill points nor as reagent
    local cooldownSpells = self:GetModel("cooldown-spells") or {};

    for skillId, skill in pairs(skillsService.allSkills) do
        if (skillId < 9000000 and skill.professionId == professionId and skill.reagents and not cooldownSpells[skillId]
            and self:HasDifficulty(skill.difficulty) and not skillsService:IsHiddenSkill(skill)) then
            local recipe = self:CreateRecipe(context, skillId, skill, known);
            if (recipe.source) then
                -- only recipes that give points somewhere on the way
                local difficulty = recipe.difficulty;
                if (difficulty[4] > startLevel and (difficulty[1] or 0) < targetLevel) then
                    table.insert(context.recipes, recipe);
                    if (recipe.source == "auction") then
                        table.insert(context.auctionRecipes, recipe);
                    end
                end

                -- reagents the character can make without buying a recipe (known recipes preferred)
                if (recipe.itemId and recipe.itemId ~= 0 and recipe.source ~= "auction") then
                    local existing = context.craftRecipes[recipe.itemId];
                    if (not existing or (existing.source ~= "known" and recipe.source == "known")) then
                        context.craftRecipes[recipe.itemId] = recipe;
                    end
                end
            end
        end
    end

    -- the greedy walk stops at the first recipe that is still red
    -- (same orange level: fixed order, so equal recipes are always tried the same way)
    table.sort(context.recipes, function(a, b)
        local aLevel, bLevel = a.difficulty[1] or 0, b.difficulty[1] or 0;
        if (aLevel ~= bLevel) then
            return aLevel < bLevel;
        end
        return a.skillId < b.skillId;
    end);
    table.sort(context.auctionRecipes, function(a, b)
        return a.price < b.price;
    end);

    self.addon:Log("LevelingPlannerService", "CreateContext", "%d usable recipes, %d recipes on the auction house", #context.recipes, #context.auctionRecipes);
    return context;
end

--- Create the planner recipe of a skill with the way the character gets it:
--- known, trainer or auction house (the source stays nil without a way).
-- @param context The calculation context.
-- @param skillId The spell id.
-- @param skill The skill wrapper.
-- @param known Set of the skill ids the character knows.
-- @return recipe.
function LevelingPlannerService:CreateRecipe(context, skillId, skill, known)
    local recipe = {
        skillId = skillId,
        skill = skill,
        difficulty = skill.difficulty,
        reagents = skill.reagents,
        itemId = skill.itemId,
        itemAmount = skill.itemAmount or 1,
    };

    local sources = skill.sources;
    if (known[skillId]) then
        recipe.source = "known";
    elseif (sources and ((sources.trainers and #sources.trainers > 0) or sources.auto)) then
        recipe.source = "trainer";
    else
        recipe.recipeItemId, recipe.price, recipe.recipeOwned = self:FindRecipeOffer(context, skill);
        if (recipe.recipeItemId) then
            recipe.source = "auction";
        end
    end

    return recipe;
end

--- Find the cheapest way to get a recipe item: owned (free) or the cheapest auction house offer.
-- @param context The calculation context.
-- @param skill The skill wrapper.
-- @return recipe item id, price, owned flag; nil if no recipe item is available.
function LevelingPlannerService:FindRecipeOffer(context, skill)
    local scanService = self:GetService("auction-scan");
    local bestItemId, bestPrice, bestOwned;

    for _, recipeItemId in ipairs(skill.recipeItemIds or {}) do
        local bags, bank, mail = self:GetOwnedAmounts(context, recipeItemId);
        if (bags + bank + mail > 0) then
            return recipeItemId, 0, true;
        end

        local listings = scanService:GetListings(recipeItemId);
        if (listings and listings[1] and (not bestPrice or listings[1] < bestPrice)) then
            bestItemId = recipeItemId;
            bestPrice = listings[1];
            bestOwned = false;
        end
    end

    return bestItemId, bestPrice, bestOwned;
end

--- Get the amounts of an item the character owns.
-- @param context The calculation context.
-- @param itemId The item id.
-- @return bags, bank and mail amounts.
function LevelingPlannerService:GetOwnedAmounts(context, itemId)
    if (not context.isCurrentCharacter) then
        return 0, 0, 0;
    end

    local bags = context.skipBags and 0 or self:GetService("inventory"):GetBagAmount(itemId);
    return bags,
        self:GetService("bank"):GetItemCount(itemId),
        self:GetService("mail"):GetItemCount(itemId);
end

--- Get the supply ladder of an item: the free own amounts first, then the
--- paid offers cheapest first. A vendor sells without limit; auction house
--- offers are limited, beyond them an estimated price takes over.
-- @param context The calculation context.
-- @param itemId The item id.
-- @return array of { kind, unitPrice, count }.
function LevelingPlannerService:GetLadder(context, itemId)
    local ladder = context.ladders[itemId];
    if (ladder) then
        return ladder;
    end

    ladder = {};
    local bags, bank, mail = self:GetOwnedAmounts(context, itemId);
    if (bags > 0) then table.insert(ladder, { kind = "bags", unitPrice = 0, count = bags }); end
    if (bank > 0) then table.insert(ladder, { kind = "bank", unitPrice = 0, count = bank }); end
    if (mail > 0) then table.insert(ladder, { kind = "mail", unitPrice = 0, count = mail }); end

    local auctionService = self:GetService("auction");
    local vendorPrice = auctionService:GetVendorPrice(itemId);
    if (vendorPrice) then
        table.insert(ladder, { kind = "vendor", unitPrice = vendorPrice, count = math.huge });
    else
        local listings = self:GetService("auction-scan"):GetListings(itemId);
        local lastPrice;
        if (listings) then
            for index = 1, #listings - 1, 2 do
                table.insert(ladder, { kind = "auction", unitPrice = listings[index], count = listings[index + 1] });
                lastPrice = listings[index];
            end
        end

        -- beyond the offers (or without a scan) Auctionator, TSM or the last seen price estimate the cost;
        -- drop reagents report 0 and stay limited to the own amounts
        local estimate = auctionService:GetItemPrice(itemId);
        if (lastPrice) then
            estimate = math.max(estimate or 0, lastPrice);
        end
        if (estimate and estimate > 0) then
            table.insert(ladder, { kind = "estimate", unitPrice = estimate, count = math.huge });
        end
    end

    context.ladders[itemId] = ladder;
    return ladder;
end

--- Get the recipe the character can use to craft a reagent at the current level of a run.
-- @return recipe or nil.
function LevelingPlannerService:GetCraftRecipe(context, state, itemId)
    local recipe = context.craftRecipes[itemId];
    if (recipe and (recipe.difficulty[1] or 0) <= state.level) then
        return recipe;
    end
    return nil;
end

--- Price an amount of an item along its supply ladder, optionally consuming it.
-- A reagent the character can craft is crafted as soon as that is cheaper
-- than the next offer.
-- @param context The calculation context.
-- @param state The run state (used amounts, level, recorded sources).
-- @param itemId The item id.
-- @param amount The amount (may be fractional while planning).
-- @param commit true to consume the amount.
-- @param depth Current craft nesting depth.
-- @return cost in copper, math.huge if the amount cannot be obtained (only without commit).
function LevelingPlannerService:Take(context, state, itemId, amount, commit, depth)
    local ladder = self:GetLadder(context, itemId);
    local remaining = amount;
    local cost = 0;

    -- items made by earlier steps of the way are used first
    local produced = state.produced[itemId];
    if (produced and produced > 0) then
        local taken = math.min(produced, remaining);
        remaining = remaining - taken;
        if (commit) then
            state.produced[itemId] = produced - taken;
            self:AddSource(state, itemId, "produced", 0, taken);
        end
        if (remaining <= 0) then
            return 0;
        end
    end

    -- crafting the reagent competes with the paid offers
    local craftRecipe = depth < self.MaxCraftDepth and self:GetCraftRecipe(context, state, itemId) or nil;
    local craftUnitPrice = math.huge;
    if (craftRecipe) then
        craftUnitPrice = self:GetCraftCost(context, state, craftRecipe, 1, false, depth + 1) / craftRecipe.itemAmount;
    end

    -- skip what earlier crafts already used
    local offset = state.used[itemId] or 0;
    for _, segment in ipairs(ladder) do
        if (remaining <= 0) then
            break;
        end

        if (offset >= segment.count) then
            offset = offset - segment.count;
        else
            if (segment.unitPrice > craftUnitPrice) then
                break;
            end

            local taken = math.min(segment.count - offset, remaining);
            offset = 0;
            cost = cost + taken * segment.unitPrice;
            remaining = remaining - taken;
            if (commit) then
                state.used[itemId] = (state.used[itemId] or 0) + taken;
                self:AddSource(state, itemId, segment.kind, segment.unitPrice, taken);
            end
        end
    end

    if (remaining > 0) then
        if (craftUnitPrice < math.huge) then
            cost = cost + self:GetCraftCost(context, state, craftRecipe, remaining / craftRecipe.itemAmount, commit, depth + 1);
            if (commit) then
                self:AddSource(state, itemId, "craft", craftUnitPrice, remaining);
            end
        elseif (commit) then
            -- the plan needs more than the market offers (only after rounding up the crafts)
            self:AddSource(state, itemId, "missing", 0, remaining);
        else
            return math.huge;
        end
    end

    return cost;
end

--- Price the reagents of a number of crafts, optionally consuming them.
-- @return cost in copper, math.huge if a reagent cannot be obtained (only without commit).
function LevelingPlannerService:GetCraftCost(context, state, recipe, crafts, commit, depth)
    local cost = 0;
    for reagentId, count in pairs(recipe.reagents) do
        local reagentCost = self:Take(context, state, reagentId, count * crafts, commit, depth);
        if (reagentCost == math.huge) then
            return math.huge;
        end
        cost = cost + reagentCost;
    end
    return cost;
end

--- Record where consumed units of an item come from (final pass only).
function LevelingPlannerService:AddSource(state, itemId, kind, unitPrice, count)
    if (not state.sources) then
        return;
    end

    local itemSources = state.sources[itemId];
    if (not itemSources) then
        itemSources = {};
        state.sources[itemId] = itemSources;
    end

    -- crafted units are one source, whatever their reagents cost at the time
    local key = (kind == "craft") and kind or (kind .. ":" .. unitPrice);
    local source = itemSources[key];
    if (not source) then
        source = { kind = kind, unitPrice = unitPrice, count = 0 };
        itemSources[key] = source;
    end
    source.count = source.count + count;

    -- reagents crafted along the way are listed with the step that needs them
    if (kind == "craft" and state.step) then
        state.step.crafted[itemId] = (state.step.crafted[itemId] or 0) + count;
    end
end

--- Sum up the recorded sources of an item: amount, owned amount, cost of the
--- paid units and the estimate / missing flags, sources in display order.
-- @param itemId The item id.
-- @param itemSources The recorded sources of the item (keyed, see AddSource).
-- @return reagent { itemId, count, owned, cost, sources, hasEstimate, hasMissing }.
function LevelingPlannerService:BuildReagent(itemId, itemSources)
    local reagent = { itemId = itemId, count = 0, owned = 0, cost = 0, sources = {} };
    for _, source in pairs(itemSources or {}) do
        -- fractional leftovers of the crafted intermediates are rounded for display
        source.count = math.ceil(source.count - 0.05);
        if (source.count > 0) then
            table.insert(reagent.sources, source);
            reagent.count = reagent.count + source.count;
            if (source.kind == "bags" or source.kind == "bank" or source.kind == "mail") then
                reagent.owned = reagent.owned + source.count;
            elseif (source.kind ~= "craft") then
                reagent.cost = reagent.cost + source.count * source.unitPrice;
            end
            if (source.kind == "estimate") then
                reagent.hasEstimate = true;
            elseif (source.kind == "missing") then
                reagent.hasMissing = true;
            end
        end
    end

    table.sort(reagent.sources, function(a, b)
        if (a.kind ~= b.kind) then
            return self.SourceOrder[a.kind] < self.SourceOrder[b.kind];
        end
        return a.unitPrice < b.unitPrice;
    end);

    return reagent;
end

--- Price an amount of a single reagent along its supply ladder, outside of a
--- plan: bank and mail first for free, then vendor or the auction house
--- offers level by level (missing reagents window, same prices as the planner).
-- @param itemId The item id.
-- @param amount The amount still missing in the bags.
-- @return reagent (see BuildReagent).
function LevelingPlannerService:PriceReagent(itemId, amount)
    -- the bag amount is already taken off the missing amount
    local context = { isCurrentCharacter = true, skipBags = true, ladders = {}, craftRecipes = {} };
    local state = { used = {}, produced = {}, level = 0, sources = {} };
    self:Take(context, state, itemId, amount, true, self.MaxCraftDepth);
    return self:BuildReagent(itemId, state.sources[itemId]);
end

--- Keep the items of the crafts of a step for the reagents of later steps.
-- @param state The run state.
-- @param recipe The crafted recipe.
-- @param crafts Number of crafts.
function LevelingPlannerService:AddProduced(state, recipe, crafts)
    if (recipe.itemId and recipe.itemId ~= 0) then
        state.produced[recipe.itemId] = (state.produced[recipe.itemId] or 0) + crafts * recipe.itemAmount;
    end
end

--- Walk the skill levels and take the cheapest recipe per skill point.
-- @param context The calculation context.
-- @param accepted Set of auction house recipes (skill ids) that may be used.
-- @return run { choices, crafts, used, totalCost, reachedLevel }.
function LevelingPlannerService:RunGreedy(context, accepted)
    local state = { used = {}, produced = {}, level = context.startLevel };
    local run = { choices = {}, crafts = {}, used = {}, totalCost = 0, reachedLevel = context.startLevel };
    local recipes = context.recipes;

    local previousRecipe;
    for level = context.startLevel, context.targetLevel - 1 do
        state.level = level;
        local candidates = {};
        local cheapestCost = math.huge;

        for _, recipe in ipairs(recipes) do
            local difficulty = recipe.difficulty;
            if ((difficulty[1] or 0) > level) then
                break;
            end

            if (level < difficulty[4] and (recipe.source ~= "auction" or accepted[recipe.skillId])) then
                local crafts = 1 / self:GetSkillUpChance(difficulty, level);
                local cost = self:GetCraftCost(context, state, recipe, crafts, false, 0);
                if (cost < math.huge) then
                    table.insert(candidates, { recipe = recipe, crafts = crafts, cost = cost });
                    cheapestCost = math.min(cheapestCost, cost);
                end
            end
        end

        -- no recipe left that gives a point here
        if (#candidates == 0) then
            break;
        end

        -- recipes about as cheap as the cheapest one count as equal: the recipe
        -- of the last point stays (rising offer prices would otherwise switch
        -- back and forth every point), otherwise the one that gives points up
        -- to the highest level wins, so the player crafts it longer without switching
        local limit = cheapestCost * (1 + self.SwitchTolerance) + self.SwitchToleranceCopper;
        local best;
        for _, candidate in ipairs(candidates) do
            if (candidate.cost <= limit) then
                if (candidate.recipe == previousRecipe) then
                    best = candidate;
                    break;
                end
                local grey = candidate.recipe.difficulty[4];
                if (not best or grey > best.recipe.difficulty[4] or (grey == best.recipe.difficulty[4] and candidate.cost < best.cost)) then
                    best = candidate;
                end
            end
        end
        local bestRecipe, bestCrafts, bestCost = best.recipe, best.crafts, best.cost;
        previousRecipe = bestRecipe;

        self:GetCraftCost(context, state, bestRecipe, bestCrafts, true, 0);
        self:AddProduced(state, bestRecipe, bestCrafts);
        run.choices[level] = bestRecipe;
        run.crafts[level] = bestCrafts;
        run.totalCost = run.totalCost + bestCost;
        if (not run.used[bestRecipe.skillId]) then
            run.used[bestRecipe.skillId] = true;
            run.totalCost = run.totalCost + (bestRecipe.price or 0);
        end
        run.reachedLevel = level + 1;

        self:YieldIfBusy();
    end

    return run;
end

--- Turn a run into the displayed steps: grouped crafts with whole numbers,
--- the recipes to buy or learn before their first craft and the ranks to train.
-- The reagents are priced again with the rounded crafts. Only the levels from
-- fromLevel on are listed, so a plan in progress shows what is left to do.
-- @param context The calculation context.
-- @param run The chosen run.
-- @param fromLevel The skill level the steps start at.
-- @return plan table.
function LevelingPlannerService:BuildSteps(context, run, fromLevel)
    local state = { used = {}, produced = {}, level = fromLevel, sources = {} };
    local plan = {
        characterName = context.characterName,
        professionId = context.professionId,
        startLevel = fromLevel,
        targetLevel = context.targetLevel,
        reachedLevel = run.reachedLevel,
        steps = {},
        reagents = {},
        totalCost = 0,
    };

    local rankAt = {};
    for _, rank in ipairs(self.RankLevels) do
        rankAt[rank.level] = rank;
    end

    -- the trained rank of the logged in character; unknown for other characters
    local maxRank = context.isCurrentCharacter and self:GetMaxRank(context.professionId) or nil;

    local learned = {};
    local group;

    -- price the reagents of a finished craft group with the rounded number of crafts
    local function FlushGroup()
        if (not group) then
            return;
        end
        group.crafts = math.max(1, math.ceil(group.expected - 0.05));
        group.reagents = {};
        for reagentId, count in pairs(group.recipe.reagents) do
            group.reagents[reagentId] = count * group.crafts;
        end
        state.level = group.fromLevel;
        state.step = group;
        group.cost = self:GetCraftCost(context, state, group.recipe, group.crafts, true, 0);
        state.step = nil;
        self:AddProduced(state, group.recipe, group.crafts);
        plan.totalCost = plan.totalCost + group.cost;
        table.insert(plan.steps, group);
        group = nil;
    end

    for level = fromLevel, run.reachedLevel - 1 do
        local recipe = run.choices[level];

        -- the next rank has to be trained before the first point above it, unless
        -- the character already did (without that knowledge the rank at the start counts as trained)
        local rank = rankAt[level];
        local rankMissing = (maxRank ~= nil and maxRank <= level) or (maxRank == nil and level > fromLevel);
        if (rank and rankMissing) then
            FlushGroup();
            table.insert(plan.steps, { kind = "rank", level = level, key = rank.key });
        end

        if (not group or group.recipe ~= recipe) then
            FlushGroup();

            -- a recipe from the auction house is bought right before its first
            -- craft; trainer recipes get no own step, the tooltip of the craft names the trainers
            if (recipe.source == "auction" and not learned[recipe.skillId]) then
                learned[recipe.skillId] = true;
                table.insert(plan.steps, { kind = "recipe", recipe = recipe, level = level, cost = recipe.price, owned = recipe.recipeOwned });
                plan.totalCost = plan.totalCost + recipe.price;
            end

            group = { kind = "craft", recipe = recipe, fromLevel = level, toLevel = level + 1, expected = 0, crafted = {} };
        end

        group.expected = group.expected + run.crafts[level];
        group.toLevel = level + 1;
    end
    FlushGroup();

    -- reagent list: all sources per item, the paid ones make up its cost
    for itemId, itemSources in pairs(state.sources) do
        local reagent = self:BuildReagent(itemId, itemSources);
        if (#reagent.sources > 0) then
            table.insert(plan.reagents, reagent);
            plan.hasEstimates = plan.hasEstimates or reagent.hasEstimate;
            plan.hasMissing = plan.hasMissing or reagent.hasMissing;
        end
    end

    -- the most expensive reagents first
    table.sort(plan.reagents, function(a, b)
        if (a.cost ~= b.cost) then
            return a.cost > b.cost;
        end
        return a.count > b.count;
    end);

    -- the reagent costs are the sum of the displayed rows, recipes come on top
    local reagentCost = 0;
    for _, reagent in ipairs(plan.reagents) do
        reagentCost = reagentCost + reagent.cost;
    end
    local recipeCost = 0;
    for _, step in ipairs(plan.steps) do
        if (step.kind == "recipe") then
            recipeCost = recipeCost + step.cost;
        end
    end
    plan.totalCost = reagentCost + recipeCost;

    return plan;
end
