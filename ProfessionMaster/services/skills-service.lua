--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local SkillsService = _G.professionMaster:CreateService("skills");

-- skill cache version (bump when static skill data or cache structure changes)
local SKILL_CACHE_VERSION = 36;

--- Check whether a skill id is a first aid skill (profession 129 in the skill
--- data). First aid is not a tracked profession, so its ids stay out of the own
--- and guildmate stores whatever path delivers them.
function SkillsService:IsFirstAidSkill(skillId)
    local skill = self.sourceSkills and self.sourceSkills[skillId];
    return skill ~= nil and skill.professionId == 129;
end

--- Check whether a vendor tuple of models/recipe-sources is a holiday vendor:
--- flagged with "E" or listed in the seasonal vendors model.
-- @param vendor Vendor tuple {npcId, zoneId, side, flag}.
function SkillsService:IsSeasonalVendor(vendor)
    if (vendor[4] == "E") then
        return true;
    end
    local seasonalVendors = self:GetModel("seasonal-vendors");
    return seasonalVendors and seasonalVendors[vendor[1]] == true;
end

--- Check whether a recipe item is only obtainable during a holiday: it has
--- vendors, all of them are seasonal, and no other source at all.
-- @param recipe Recipe table with the source fields of models/recipe-sources.
function SkillsService:IsSeasonalRecipe(recipe)
    if (not recipe.vendors or #recipe.vendors == 0 or recipe.unobtainable) then
        return false;
    end
    if (recipe.drops or recipe.zoneDrops or recipe.worldDrop or recipe.quests or recipe.objects
        or recipe.containers or recipe.fishing or recipe.pickpocket or recipe.crafted) then
        return false;
    end
    for _, vendor in ipairs(recipe.vendors) do
        if (not self:IsSeasonalVendor(vendor)) then
            return false;
        end
    end
    return true;
end

--- Get the availability of a skill: "unavailable" when the skill was never
--- learnable on this client (unobtainable flag without any source),
--- "seasonal" when every way to learn it is a holiday vendor, nil otherwise
--- (or when nothing is known about it).
-- @param skill Skill wrapper (recipes, sources).
-- @return Availability key or nil.
function SkillsService:GetSkillAvailability(skill)
    if (not skill) then return nil; end
    local sources = skill.sources;

    -- any way to learn the skill itself makes it available all year
    if (sources and ((sources.trainers and #sources.trainers > 0) or sources.auto
        or (sources.quests and #sources.quests > 0) or (sources.objects and #sources.objects > 0)
        or (sources.discovery and #sources.discovery > 0))) then
        return nil;
    end

    -- the obtainable recipe items decide: all seasonal or none at all
    local recipeCount = 0;
    local seasonalCount = 0;
    if (skill.recipes) then
        for _, recipe in ipairs(skill.recipes) do
            if (not recipe.unobtainable) then
                recipeCount = recipeCount + 1;
                if (self:IsSeasonalRecipe(recipe)) then
                    seasonalCount = seasonalCount + 1;
                end
            end
        end
    end
    if (recipeCount > 0) then
        return (seasonalCount == recipeCount) and "seasonal" or nil;
    end
    if (sources and sources.unobtainable) then
        return "unavailable";
    end
    return nil;
end

--- Check whether a skill stays out of the database and the unlearned lists:
--- it was never learnable on this client. Skills a player knows anyway are
--- still listed by the lists built from player data.
-- @param skill Skill wrapper (recipes, sources).
function SkillsService:IsHiddenSkill(skill)
    return self:GetSkillAvailability(skill) == "unavailable";
end

--- Get the active tbc content phase (nil = no phase filtering on this client).
function SkillsService:GetActivePhase()
    if (not self.addon.isBcc) then
        return nil;
    end
    return PM_Settings.bccPhase or 5;
end

--- Check whether a skill is visible for the selected tbc content phase.
--- Skills without phase info are always visible; on non-tbc clients everything is visible.
function SkillsService:IsSkillPhaseVisible(sourceData)
    if (not sourceData or not sourceData.phase) then
        return true;
    end
    local activePhase = self:GetActivePhase();
    return (not activePhase) or (sourceData.phase <= activePhase);
end

--- Get the expansion model parts this client loads, in merge order (vanilla
--- base first, later expansions override earlier entries). Season of Discovery
--- is season-only and not cumulative, so it is merged right after vanilla.
-- @return Array of { suffix, addonNumber } tables.
function SkillsService:GetActiveExpansions()
    if (self.activeExpansions) then
        return self.activeExpansions;
    end

    -- wow forever has its own complete data set and shares no part with the
    -- classic clients
    if (self.addon.isForever) then
        self.activeExpansions = { { suffix = "forever", addonNumber = 1 } };
        return self.activeExpansions;
    end

    local expansions = { { suffix = "vanilla", addonNumber = 1 } };
    if (self.addon.isSod) then table.insert(expansions, { suffix = "sod", addonNumber = 6 }); end
    if (self.addon.isBccAtLeast) then table.insert(expansions, { suffix = "bcc", addonNumber = 2 }); end
    if (self.addon.isWrathAtLeast) then table.insert(expansions, { suffix = "wrath", addonNumber = 3 }); end
    if (self.addon.isCataAtLeast) then table.insert(expansions, { suffix = "cata", addonNumber = 4 }); end
    if (self.addon.isMopAtLeast) then table.insert(expansions, { suffix = "mop", addonNumber = 5 }); end

    self.activeExpansions = expansions;
    return expansions;
end

--- Merge the per-expansion parts of a lookup model family (recipe sources, npc
--- names, zone names) into one table.
-- @param targetTable Table to merge into.
-- @param modelPrefix Model name prefix, e.g. "recipe-sources".
-- @return The target table.
function SkillsService:MergeExpansionModels(targetTable, modelPrefix)
    for _, expansion in ipairs(self:GetActiveExpansions()) do
        self:MergeRecipeSources(targetTable, self:GetModel(modelPrefix .. "-" .. expansion.suffix));
    end
    return targetTable;
end

--- Initialize service.
function SkillsService:Initialize()
    -- always merge source skill data into self.sourceSkills (stays in RAM for metatable fallback)
    self.sourceSkills = {};
    for _, expansion in ipairs(self:GetActiveExpansions()) do
        self:MergeSourceSkills(self.sourceSkills, expansion.addonNumber, self:GetModel(expansion.suffix .. "-skills"));
    end

    -- log active tbc content phase filter
    local activePhase = self:GetActivePhase();
    if (activePhase) then
        self.addon:Log("SkillsService", "Initialize", "TBC content phase filter active: phase %d", activePhase);
    end

    -- check if skill cache needs rebuilding
    -- the cache is also keyed by expansion id: era and sod share the same client
    -- and account-wide saved variables, so a cache built on sod would otherwise
    -- leak sod skills into era (and vice versa)
    local currentLocale = GetLocale();
    self.cacheRebuilt = (not PM_Settings.skillCacheVersion) or (PM_Settings.skillCacheVersion < SKILL_CACHE_VERSION) or (PM_Settings.skillCacheLanguage ~= currentLocale) or (PM_Settings.skillCacheExpansion ~= self.addon.expansionId) or (PM_Settings.skillCachePhase ~= self:GetActivePhase()) or (not PM_Skills) or (not next(PM_Skills));

    if (self.cacheRebuilt) then
        -- notify player
        local chatService = self:GetService("chat");
        chatService:Write("SkillCacheUpdating");

        -- reset and rebuild skill cache from scratch
        PM_Skills = {};
        PM_Recipes = {};
        self:BuildCache();
        PM_Settings.skillCacheVersion = SKILL_CACHE_VERSION;
        PM_Settings.skillCacheLanguage = currentLocale;
        PM_Settings.skillCacheExpansion = self.addon.expansionId;
        PM_Settings.skillCachePhase = self:GetActivePhase();
        self.addon:Log("SkillsService", "Initialize", "Rebuilt skill cache for expansion %d", self.addon.expansionId);

        -- count cached skills and notify player
        local skillCount = 0;
        for _ in pairs(PM_Skills) do
            skillCount = skillCount + 1;
        end
        chatService:Write("SkillCacheUpdated", skillCount);
    end

    -- the two gathering lookups stay in RAM: a later cache refresh rebuilds the
    -- wrappers and has to attach them again, and their entries are referenced
    -- by the wrappers anyway
    self.nodeContents = self:GetModel("mining-node-contents");
    self.gatheringZones = self:GetModel("gathering-zones");

    self:BuildSkillWrappers();
    self:AttachGatheringData();

    -- merge per-expansion recipe source models (stays in RAM for runtime recipe building)
    self.recipeSources = self:MergeExpansionModels({}, "recipe-sources");

    -- merge per-expansion skill source models (trainer groups, trainer npcs, per skill sources)
    self.skillSources = self:MergeSkillSources();

    -- quest and game object name lookups (english fallback for the source tooltips)
    self.questNames = self:MergeExpansionModels({}, "quest-names");
    self.objectNames = self:MergeExpansionModels({}, "object-names");

    self:BuildReverseIndexes();

    -- merge per-expansion NPC name lookup models (needed every load for tooltip display)
    self.npcNames = self:MergeExpansionModels({}, "npc-names");

    -- create zone name lookup using C_Map.GetAreaInfo for localized names at runtime
    -- falls back to static English data if the API is unavailable
    local mergedZoneNames = self:MergeExpansionModels({}, "zone-names");

    -- wrap with C_Map.GetAreaInfo for automatic locale resolution
    -- the api only accepts integer area ids inside the int32 range, anything else
    -- raises a lua error, so validate the key before calling it
    local reportedZoneIds = {};
    self.zoneNames = setmetatable({}, {
        __index = function(zoneNames, areaId)
            local name;
            if (type(areaId) == "number" and areaId > 0 and areaId <= 2147483647 and math.floor(areaId) == areaId) then
                if (C_Map and C_Map.GetAreaInfo) then
                    name = C_Map.GetAreaInfo(areaId);
                end
            elseif (areaId ~= nil and not reportedZoneIds[tostring(areaId)]) then
                -- report every unusable zone id once to keep the log quiet
                reportedZoneIds[tostring(areaId)] = true;
                self.addon:Log("SkillsService", "ZoneNames", "Ignored invalid zone id '%s' (%s)", tostring(areaId), type(areaId));
            end

            name = name or mergedZoneNames[areaId];

            -- cache the resolved name so the lookup runs only once per zone
            if (name) then
                rawset(zoneNames, areaId, name);
            end
            return name;
        end
    });

    -- load self-craft conversions (essences/motes anyone can combine without a profession)
    self.conversions = self:GetModel("self-conversions") or {};
    local conversionCount = 0;
    for _ in pairs(self.conversions) do
        conversionCount = conversionCount + 1;
    end
    self.addon:Log("SkillsService", "Initialize", "Loaded %d self-craft conversions", conversionCount);

    -- load skills that only work on the equipment of the crafter (ring enchants,
    -- tinkers, embroideries, sockets); nobody can make them for someone else
    self.selfOnlySkills = self:GetModel("self-only-skills") or {};

    -- free source model data to allow garbage collection
    self:FreeSkillModels();
end

--- Force-refresh skill cache (triggered by /pm skillrefresh).
function SkillsService:ForceRefreshCache()
    -- notify player
    local chatService = self:GetService("chat");
    chatService:Write("SkillCacheUpdating");

    -- reset and rebuild skill cache from scratch
    PM_Skills = {};
    PM_Recipes = {};
    self:BuildCache();
    PM_Settings.skillCacheVersion = SKILL_CACHE_VERSION;
    PM_Settings.skillCacheLanguage = GetLocale();
    PM_Settings.skillCacheExpansion = self.addon.expansionId;
    PM_Settings.skillCachePhase = self:GetActivePhase();

    -- rebuild the wrapper tables and reverse indexes (same as at login)
    self:BuildSkillWrappers();
    self:AttachGatheringData();
    self:BuildReverseIndexes();

    -- rebuild skill index in profession query service
    self:GetService("profession-query"):RebuildSkillIndex();

    -- count cached skills and notify player
    local skillCount = 0;
    for _ in pairs(PM_Skills) do
        skillCount = skillCount + 1;
    end
    chatService:Write("SkillCacheUpdated", skillCount);

    -- refresh view
    if (self.addon.professionsView) then
        self.addon.professionsView:Refresh();
    end

    self.addon:Log("SkillsService", "ForceRefreshCache", "Rebuilt %d skills", skillCount);
end

--- Build the allSkills wrapper tables so runtime data (recipes) does not
--- pollute PM_Skills; the lookup chain is wrapper → PM_Skills entry →
--- sourceSkills entry (via metatables). Skills of a not yet released tbc
--- content phase are left out entirely.
function SkillsService:BuildSkillWrappers()
    self.allSkills = {};
    for skillId, sourceData in pairs(self.sourceSkills) do
        if (self:IsSkillPhaseVisible(sourceData)) then
            local cached = PM_Skills[skillId];
            if (not cached) then
                -- source skill not yet cached; create entry so it is available for lookups
                cached = {};
                PM_Skills[skillId] = cached;
            end
            setmetatable(cached, { __index = sourceData });
            self.allSkills[skillId] = setmetatable({}, { __index = cached });
        end
    end

    -- add PM_Skills entries not in source data (from PM_Professions);
    -- entries that exist in source data but are missing from allSkills were
    -- filtered by phase and must not be re-added from the cache
    for skillId, cached in pairs(PM_Skills) do
        if (not self.allSkills[skillId]) and (not self.sourceSkills[skillId]) then
            self.allSkills[skillId] = setmetatable({}, { __index = cached });
        end
    end
end

--- Attach mining node contents and gathering zones to the gathering skill
--- wrappers (runs after every wrapper rebuild, login and cache refresh alike).
function SkillsService:AttachGatheringData()
    local nodeContents = self.nodeContents;
    local gatheringZones = self.gatheringZones;
    if (not nodeContents and not gatheringZones) then
        return;
    end

    for skillId, wrapper in pairs(self.allSkills) do
        if (skillId >= 9000000) then
            local itemId = wrapper.itemId;
            if (itemId) then
                -- mining node contents
                if (nodeContents and wrapper.professionId == 186 and nodeContents[itemId]) then
                    wrapper.contents = nodeContents[itemId];
                end

                -- gathering zones
                if (gatheringZones and gatheringZones[itemId]) then
                    wrapper.zones = gatheringZones[itemId];
                end
            end
        end
    end
end

--- Build the reverse indexes (item id → skills, reagent item id → skills) and
--- the runtime recipe arrays on the wrapper tables.
function SkillsService:BuildReverseIndexes()
    self.allItems = {};
    self.allRecipes = {};
    self.allReagents = {};
    self.unresolvedRecipeCount = 0;
    for skillId, wrapper in pairs(self.allSkills) do
        local itemId = wrapper.itemId;
        if (itemId and itemId ~= 0) then
            local itemSkills = self.allItems[itemId];
            if (not itemSkills) then
                itemSkills = {};
                self.allItems[itemId] = itemSkills;
            end
            itemSkills[#itemSkills + 1] = skillId;
        end
        if (wrapper.reagents) then
            for reagentItemId, _ in pairs(wrapper.reagents) do
                local reagentSkills = self.allReagents[reagentItemId];
                if (not reagentSkills) then
                    reagentSkills = {};
                    self.allReagents[reagentItemId] = reagentSkills;
                end
                reagentSkills[#reagentSkills + 1] = skillId;
            end
        end
        self:BuildRecipesForSkill(skillId, wrapper);
        wrapper.sources = self:BuildSkillSourceInfo(skillId);
    end

    -- one summary line for recipe items asked again (their name was still missing)
    if (self.unresolvedRecipeCount > 0) then
        self.addon:Log("SkillsService", "BuildReverseIndexes", "Requested %d recipe items again whose name was still unresolved", self.unresolvedRecipeCount);
    end
end

--- Build PM_Skills and PM_Recipes caches from source data files and PM_Professions.
--- PM_Skills stores only dynamically resolved skill fields (names, links, icons).
--- PM_Recipes stores only dynamically resolved recipe fields (name, itemLink, itemColor).
--- Static data (reagents, vendors, drops, etc.) is accessed at runtime from source models.
function SkillsService:BuildCache()
    local professionNamesService = self:GetService("profession-names");

    -- build PM_Skills entries from source data (only dynamic fields);
    -- skills of a not yet released tbc content phase are not cached
    for skillId, skillInfo in pairs(self.sourceSkills) do
        if (self:IsSkillPhaseVisible(skillInfo)) then
            self:LoadSkillIntoCache(skillId, skillInfo.itemId, skillInfo.professionId, professionNamesService);

            -- resolve recipe item data into PM_Recipes
            if (skillInfo.recipeItemIds) then
                for _, recipeItemId in ipairs(skillInfo.recipeItemIds) do
                    if (not PM_Recipes[recipeItemId]) then
                        self:ResolveRecipeItemData(recipeItemId, professionNamesService);
                    end
                end
            end
        end
    end

    -- also build from existing guildmates data (for skills not in source data)
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    if (guildmates) then
        for playerName, professions in pairs(guildmates) do
            for professionId, skillIds in pairs(professions) do
                for _, skillId in ipairs(skillIds) do
                    if (not PM_Skills[skillId]) then
                        self:LoadSkillIntoCache(skillId, 0, professionId, professionNamesService);
                    end
                end
            end
        end
    end
end

--- Merge recipe source data from a per-expansion model into the target table.
--- Later expansions override earlier entries for the same item.
function SkillsService:MergeRecipeSources(targetTable, expansionSources)
    if (not expansionSources) then return; end
    for recipeItemId, sourceData in pairs(expansionSources) do
        targetTable[recipeItemId] = sourceData;
    end
end

--- Merge the per-expansion skill source models into one table with the sub tables
--- groups (group id → trainer npc ids), npcs (npc id → {zoneId, side}) and
--- skills (skill id → source entry). Group ids are unique per expansion, so the
--- three parts merge by plain union; a later expansion replaces the skill entry.
-- @return Merged skill sources table.
function SkillsService:MergeSkillSources()
    local merged = { groups = {}, npcs = {}, skills = {} };
    for _, expansion in ipairs(self:GetActiveExpansions()) do
        local model = self:GetModel("skill-sources-" .. expansion.suffix);
        if (model) then
            self:MergeRecipeSources(merged.groups, model.groups);
            self:MergeRecipeSources(merged.npcs, model.npcs);
            self:MergeRecipeSources(merged.skills, model.skills);
        end
    end
    return merged;
end

--- Build the runtime source info of a skill (trainers, quests, discovery, learned
--- with the profession, not available) from the merged skill source models.
-- @param skillId Skill id.
-- @return Source info table or nil when the skill has no entry.
function SkillsService:BuildSkillSourceInfo(skillId)
    local sources = self.skillSources;
    local entry = sources and sources.skills[skillId];
    if (not entry) then
        return nil;
    end
    local info = { quests = entry.q, objects = entry.o, discovery = entry.d, auto = entry.a, unobtainable = entry.u };
    if (entry.t) then
        info.trainers = sources.groups[entry.t];
    end
    self:RequestQuestStarterLinks(entry.q);
    return info;
end

--- Request the item links of quests started by an item (giver type "i") so the
--- tooltip can show the starting item by its localized link.
-- @param quests Quest tuples {questId, giverId, zoneId, side, flags, giverType}.
function SkillsService:RequestQuestStarterLinks(quests)
    if (not quests) then return; end
    for _, quest in ipairs(quests) do
        if (quest[6] == "i" and quest[2]) then
            self:RequestItemLink(quest[2]);
        end
    end
end

--- Get zone id and side of a trainer npc.
-- @param npcId Npc id.
-- @return Zone id (or nil), side ("A", "H" or nil for both).
function SkillsService:GetTrainerInfo(npcId)
    local npcs = self.skillSources and self.skillSources.npcs;
    local info = npcs and npcs[npcId];
    if (not info) then
        return nil, nil;
    end
    return info[1], info[2];
end

--- Request the localized link of an item used by the source tooltips (container
--- items like caches and bags). Resolved asynchronously into self.itemLinks.
-- @param itemId Item id.
function SkillsService:RequestItemLink(itemId)
    self.itemLinks = self.itemLinks or {};
    if (self.itemLinks[itemId] ~= nil) then
        return;
    end
    self.itemLinks[itemId] = false;
    if (C_Item.DoesItemExistByID(itemId)) then
        local item = Item:CreateFromItemID(itemId);
        if (not item:IsItemEmpty()) then
            local itemLinks = self.itemLinks;
            pcall(function()
                item:ContinueOnItemLoad(function()
                    itemLinks[itemId] = item:GetItemLink() or item:GetItemName() or false;
                end);
            end);
        end
    end
end

--- Merge source skill data from an addon into the target table.
function SkillsService:MergeSourceSkills(targetTable, addonNumber, addonData)
    if (not addonData) then return; end
    for skillId, skillData in pairs(addonData) do
        -- normalize recipe item IDs to array
        local newRecipeItemIds = {};
        if (type(skillData.r) == "number") then
            newRecipeItemIds = {skillData.r};
        elseif (type(skillData.r) == "table") then
            newRecipeItemIds = skillData.r;
        end

        local skill = {
            itemId = skillData.itemId,
            itemAmount = skillData.itemAmount,
            reagents = skillData.reagents,
            professionId = skillData.p,
            difficulty = skillData.d,
            recipeItemIds = newRecipeItemIds,
            localeKey = skillData.localeKey,
            phase = skillData.ph
        };

        if (targetTable[skillId]) then
            skill.addon = targetTable[skillId].addon;
            skill.addonIds = targetTable[skillId].addonIds or {targetTable[skillId].addon};

            -- accumulate recipe IDs from previous expansions
            local previousRecipeItemIds = targetTable[skillId].recipeItemIds or {};
            skill.recipeItemIds = previousRecipeItemIds;

            -- check for new recipe IDs not seen in earlier expansions
            local hasNewRecipe = false;
            for _, newId in ipairs(newRecipeItemIds) do
                local found = false;
                for _, existingId in ipairs(skill.recipeItemIds) do
                    if (existingId == newId) then
                        found = true;
                        break;
                    end
                end
                if (not found) then
                    hasNewRecipe = true;
                    table.insert(skill.recipeItemIds, newId);
                end
            end

            -- if new recipes appeared in this expansion, mark it as relevant
            if (hasNewRecipe) then
                table.insert(skill.addonIds, addonNumber);
            end
        else
            skill.addon = addonNumber;
            skill.addonIds = {addonNumber};
        end

        targetTable[skillId] = skill;
    end
end

--- Load a single skill into PM_Skills cache.
--- For source-data skills, only stores dynamically resolved fields (name, links, icons, classification).
--- Static fields (itemId, professionId, reagents, etc.) are accessed via metatable from self.sourceSkills.
--- For PM_Professions skills (not in source data), also stores itemId and professionId directly.
function SkillsService:LoadSkillIntoCache(skillId, itemId, professionId, professionNamesService)
    -- an entry without a name means the item answer never arrived (item not
    -- on the client, no server answer during login); it is kept and asked
    -- again instead of being treated as resolved
    local entry = PM_Skills[skillId];
    if (entry and entry.name) then
        return;
    end

    -- create cache entry (only dynamic fields for source-data skills)
    entry = entry or {};

    -- for skills not in source data, store identifiers directly (no metatable fallback available)
    if (not self.sourceSkills[skillId]) then
        entry.itemId = itemId or 0;
        entry.professionId = professionId;
    end

    PM_Skills[skillId] = entry;

    -- resolve locale key for display name (e.g. mining nodes)
    local sourceData = self.sourceSkills[skillId];
    if (sourceData and sourceData.localeKey) then
        local localeService = self:GetService("locale");
        local localeName = localeService:GetBare(sourceData.localeKey);
        if (localeName) then
            entry.name = localeName;
        end
    end

    -- handle enchantment spells (profession 333) without an item result
    if (professionId == 333 and (not itemId or itemId == 0)) then
        local spellName, _, spellIcon = self.addon.compat.GetSpellInfo(skillId);
        if (spellName) then
            entry.name = spellName;
            entry.icon = spellIcon;
            entry.itemColor = "FF71D5FF";
            entry.equipLoc = self:GetEnchantEquipLoc(spellName);
            entry.enchantCategory = self:GetEnchantCategory(spellName);
            entry.skillLink = professionNamesService:GetSkillLink(333, skillId, spellName);
        end
        return;
    end

    -- handle item-based skills
    if (itemId and itemId ~= 0 and type(itemId) == "number") then
        -- load item data asynchronously
        if (C_Item.DoesItemExistByID(itemId)) then
            local item = Item:CreateFromItemID(itemId);
            if (not item:IsItemEmpty()) then
                pcall(function()
                    item:ContinueOnItemLoad(function()
                        local itemName = item:GetItemName();
                        local itemLink = item:GetItemLink();
                        entry.itemLink = itemLink;
                        entry.itemColor = professionNamesService:GetItemColor(itemLink);
                        entry.icon = item:GetItemIcon();
                        if (not entry.name) then
                            entry.name = itemName;

                            -- invalidate gathering node lookup so new name is picked up
                            if (skillId >= 9000000) then
                                self:GetService("tooltip"):InvalidateGatheringNodeLookup();
                            end
                        end
                        if (not entry.skillLink and professionId) then
                            entry.skillLink = professionNamesService:GetSkillLink(professionId, skillId, itemName);
                        end

                        -- store item classification for filtering
                        local _, _, _, itemEquipLoc, _, classID, subclassID = self.addon.compat.GetItemInfoInstant(itemId);
                        entry.classId = classID;
                        entry.subclassId = subclassID;
                        entry.equipLoc = itemEquipLoc or nil;
                    end);
                end);
            end
        end
    end
end

--- Resolve recipe item data (name, link, color) and store in PM_Recipes.
--- The item answer arrives asynchronously and can stay out (item not on the
--- client, no server answer during login), so an existing entry without a
--- name is kept and asked again instead of being treated as resolved.
-- @return The PM_Recipes entry of the recipe item.
function SkillsService:ResolveRecipeItemData(recipeItemId, professionNamesService)
    local entry = PM_Recipes[recipeItemId];
    if (not entry) then
        entry = {};
        PM_Recipes[recipeItemId] = entry;
    end
    professionNamesService = professionNamesService or self:GetService("profession-names");

    if (C_Item.DoesItemExistByID(recipeItemId)) then
        local item = Item:CreateFromItemID(recipeItemId);
        if (not item:IsItemEmpty()) then
            pcall(function()
                item:ContinueOnItemLoad(function()
                    entry.name = item:GetItemName();
                    entry.itemLink = item:GetItemLink();
                    entry.itemColor = professionNamesService:GetItemColor(item:GetItemLink());

                    -- names that arrive after the lists were built show up on the next refresh
                    self:ScheduleRecipeRefresh();
                end);
            end);
        end
    end
    return entry;
end

--- Refresh the professions view once after a burst of late recipe item answers
--- (debounced, only refreshes when the view is open).
function SkillsService:ScheduleRecipeRefresh()
    if (self.recipeRefreshPending) then
        self.recipeRefreshPending:Cancel();
    end
    self.recipeRefreshPending = C_Timer.NewTimer(1, function()
        self.recipeRefreshPending = nil;
        if (self.addon.professionsView) then
            self.addon.professionsView:Refresh();
        end
    end);
end

--- Build the runtime recipes array for a skill and populate allRecipes reverse index.
--- Combines PM_Recipes (dynamic: name, link, color) with self.recipeSources (static: vendors, drops).
function SkillsService:BuildRecipesForSkill(skillId, wrapper)
    local recipeItemIds = wrapper.recipeItemIds;
    if (not recipeItemIds or #recipeItemIds == 0) then return; end

    local recipes = {};
    for _, recipeItemId in ipairs(recipeItemIds) do
        local cachedRecipe = PM_Recipes and PM_Recipes[recipeItemId];
        local sourceData = self.recipeSources and self.recipeSources[recipeItemId];

        -- a missing or nameless cache entry means the item answer never arrived
        -- (the labels hide recipes without a name), ask the client again
        if (PM_Recipes and (not cachedRecipe or not cachedRecipe.name)) then
            cachedRecipe = self:ResolveRecipeItemData(recipeItemId);
            self.unresolvedRecipeCount = (self.unresolvedRecipeCount or 0) + 1;
        end

        -- name, link and color are read through the cache entry so a late item
        -- answer becomes visible without rebuilding the recipe list
        local recipe = setmetatable({ itemId = recipeItemId }, { __index = cachedRecipe });
        if (sourceData) then
            recipe.vendors = sourceData.vendors;
            recipe.drops = sourceData.drops;
            recipe.zoneDrops = sourceData.zoneDrops;
            recipe.worldDrop = sourceData.worldDrop;
            recipe.quests = sourceData.quests;
            recipe.objects = sourceData.objects;
            recipe.containers = sourceData.containers;
            recipe.fishing = sourceData.fishing;
            recipe.pickpocket = sourceData.pickpocket;
            recipe.crafted = sourceData.crafted;
            recipe.unobtainable = sourceData.unobtainable;

            -- container and quest starting items are shown by their localized link, requested once here
            if (sourceData.containers) then
                for _, containerItemId in ipairs(sourceData.containers) do
                    self:RequestItemLink(containerItemId);
                end
            end
            self:RequestQuestStarterLinks(sourceData.quests);
        end
        table.insert(recipes, recipe);
        self.allRecipes[recipeItemId] = skillId;
    end
    wrapper.recipes = recipes;
end

--- Determine equip location for an enchantment based on spell name patterns.
function SkillsService:GetEnchantEquipLoc(spellName)
    if (not spellName) then return nil; end
    local name = string.lower(spellName);

    if (string.find(name, "bracer") or string.find(name, "wrist")) then return "INVTYPE_WRIST"; end
    if (string.find(name, "chest") or string.find(name, "torso")) then return "INVTYPE_CHEST"; end
    if (string.find(name, "cloak") or string.find(name, "back")) then return "INVTYPE_CLOAK"; end
    if (string.find(name, "boots") or string.find(name, "feet") or string.find(name, "speed")) then return "INVTYPE_FEET"; end
    if (string.find(name, "gloves") or string.find(name, "hands") or string.find(name, "glove")) then return "INVTYPE_HAND"; end
    if (string.find(name, "shield")) then return "INVTYPE_SHIELD"; end
    if (string.find(name, "2h weapon") or string.find(name, "two%-hand")) then return "INVTYPE_2HWEAPON"; end
    if (string.find(name, "weapon") or string.find(name, "striking") or string.find(name, "fiery") or string.find(name, "lifestealing") or string.find(name, "crusader") or string.find(name, "mongoose") or string.find(name, "berserking") or string.find(name, "executioner") or string.find(name, "blade")) then return "INVTYPE_WEAPON"; end
    if (string.find(name, "head") or string.find(name, "helm")) then return "INVTYPE_HEAD"; end
    if (string.find(name, "shoulder")) then return "INVTYPE_SHOULDER"; end
    if (string.find(name, "legs") or string.find(name, "leg")) then return "INVTYPE_LEGS"; end
    if (string.find(name, "ring")) then return "INVTYPE_FINGER"; end

    return nil;
end

--- Extract enchantment category from spell name (text before first " - ").
-- e.g. "Enchant Weapon - Fiery Weapon" -> "Enchant Weapon"
function SkillsService:GetEnchantCategory(spellName)
    if (not spellName) then return nil; end
    local dashPos = string.find(spellName, " %- ", 1, false);
    if (dashPos) then
        return string.sub(spellName, 1, dashPos - 1);
    end
    return spellName;
end

--- Ensure a skill exists in the cache, creating it if necessary.
function SkillsService:EnsureSkillCached(skillId, itemId, professionId)
    if (self.allSkills[skillId]) then
        return;
    end

    -- a skill of the source data that is not in allSkills belongs to a later
    -- content phase; a player who knows it proves it is live, so it joins the
    -- lookups with the item and profession of the model (the callers usually
    -- have neither, the wire carries only the skill id)
    local sourceData = self.sourceSkills[skillId];
    if (sourceData) then
        if (not itemId or itemId == 0) then
            itemId = sourceData.itemId or 0;
        end
        professionId = sourceData.professionId or professionId;
        self.addon:Log("SkillsService", "EnsureSkillCached", "Skill %d of content phase %s is known by a player, added to the lookups", skillId, tostring(sourceData.phase));
    end

    local professionNamesService = self:GetService("profession-names");
    self:LoadSkillIntoCache(skillId, itemId or 0, professionId, professionNamesService);

    -- add to allSkills using wrapper pattern
    local entry = PM_Skills[skillId];
    if (entry) then
        if (sourceData) then
            setmetatable(entry, { __index = sourceData });
        end
        local wrapper = setmetatable({}, { __index = entry });
        self.allSkills[skillId] = wrapper;

        -- update reverse index
        if (wrapper.itemId and wrapper.itemId ~= 0) then
            if (not self.allItems[wrapper.itemId]) then
                self.allItems[wrapper.itemId] = {};
            end
            table.insert(self.allItems[wrapper.itemId], skillId);
        end

        -- build runtime recipes
        self:BuildRecipesForSkill(skillId, wrapper);
    end
end

--- Get skill by id.
function SkillsService:GetSkillById(skillId)
   return self.allSkills[skillId];
end

--- Check whether a skill only works on the equipment of the crafter.
--- Ring enchants, engineering tinkers, embroideries, fur linings, shoulder
--- inscriptions and blacksmithing sockets carry the "enchant own item only"
--- flag of the game, so a crafter can never apply them for another player.
-- @param skillId Skill ID.
-- @return boolean
function SkillsService:IsSelfOnlySkill(skillId)
    return (self.selfOnlySkills and self.selfOnlySkills[skillId]) == true;
end

--- Build the lowercase name -> skill id lookup index.
function SkillsService:BuildNameIndex()
    local index = {};
    for skillId, skillData in pairs(self.allSkills) do
        local skillName = skillData.name;
        if (skillName) then
            local key = string.lower(skillName);
            if (not index[key]) then
                index[key] = skillId;
            end
        end
    end
    self.nameIndex = index;
    self.nameIndexTime = GetTime();
end

--- Get skill id by localized skill/item name (case-insensitive). The index is
--- built lazily and rebuilt (throttled) on a miss, since skill names can still
--- be filled asynchronously after the cache is built.
function SkillsService:GetSkillIdByName(name)
    if (not name or name == "") then
        return nil;
    end
    local key = string.lower(name);

    if (not self.nameIndex) then
        self:BuildNameIndex();
    end
    local skillId = self.nameIndex[key];
    if (skillId) then
        return skillId;
    end

    -- retry with a fresh index at most every 30 seconds
    if (GetTime() - (self.nameIndexTime or 0) > 30) then
        self:BuildNameIndex();
        return self.nameIndex[key];
    end
    return nil;
end

--- Get skill id by item id. If professionId is given, prefer skill matching that profession.
function SkillsService:GetSkillIdByItemId(itemId, professionId)
    local skillIds = self.allItems[itemId];
    if (not skillIds or #skillIds == 0) then
        return nil;
    end
    if (professionId) then
        for _, skillId in ipairs(skillIds) do
            local skillData = self.allSkills[skillId];
            if (skillData and skillData.professionId == professionId) then
                return skillId;
            end
        end
    end
    return skillIds[1];
end

--- Resolve how the player can craft an item themselves for the bucket list breakdown.
--- Self-craft conversions (essences/motes, no profession needed) are checked first so a
--- free conversion always wins over a profession recipe; profession skills are the fallback.
-- @param itemId Item to craft.
-- @return descriptor { reagents, itemAmount, skillId } or nil. skillId is nil for conversions.
function SkillsService:GetSelfCraftInfo(itemId)
    -- prefer a free conversion (anyone can combine, e.g. 3 lesser -> 1 greater essence)
    local conversion = self.conversions and self.conversions[itemId];
    if (conversion) then
        return { reagents = conversion.reagents, itemAmount = conversion.itemAmount };
    end

    -- fall back to a profession skill that produces the item
    local skillId = self:GetSkillIdByItemId(itemId);
    if (skillId) then
        local skill = self:GetSkillById(skillId);
        return { skillId = skillId, reagents = skill and skill.reagents, itemAmount = skill and skill.itemAmount };
    end

    return nil;
end

--- Get skill id by recipe item id.
function SkillsService:GetSkillIdByRecipeItemId(recipeItemId)
   return self.allRecipes[recipeItemId];
end

--- Get skill ids that use this item as a reagent.
function SkillsService:GetSkillIdsByReagentItemId(reagentItemId)
    return self.allReagents[reagentItemId];
end

--- Free raw model data references so Lua garbage collector can reclaim source file tables.
--- self.sourceSkills is kept alive (needed for metatable fallback on allSkills entries).
function SkillsService:FreeSkillModels()
    local modelTypes = self.addon.modelTypes;

    -- all expansion parts are dropped, not only the ones this client merged
    for _, suffix in ipairs({ "vanilla", "forever", "sod", "bcc", "wrath", "cata", "mop" }) do
        modelTypes[suffix .. "-skills"] = nil;
        modelTypes["recipe-sources-" .. suffix] = nil;
        modelTypes["skill-sources-" .. suffix] = nil;
        modelTypes["quest-names-" .. suffix] = nil;
        modelTypes["object-names-" .. suffix] = nil;
        modelTypes["npc-names-" .. suffix] = nil;
        modelTypes["zone-names-" .. suffix] = nil;
    end
    modelTypes["mining-node-contents"] = nil;
    modelTypes["gathering-zones"] = nil;
end
