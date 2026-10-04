--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ApiService = _G.professionMaster:CreateService("api");

--- Initialize service.
function ApiService:Initialize()
    self.addon:Log("ApiService", "Initialize", "Public api used by another addon for the first time");
end

--- Check whether the api can answer: the saved data is migrated and the
--- character is known from the login on.
-- @return boolean
function ApiService:IsReady()
    return IsLoggedIn() == true;
end

--- Build the public description of a skill. Always a fresh table, the
--- internal skill wrappers never leave the addon.
-- @param skillId Spell id of the crafting recipe.
-- @param recipeItemId Recipe item the caller asked with (optional).
-- @return Info table or nil for an unknown skill.
function ApiService:BuildRecipeInfo(skillId, recipeItemId)
    local skill = skillId and self:GetService("skills"):GetSkillById(skillId);
    if (not skill or not skill.professionId) then
        return nil;
    end

    -- gathering nodes carry made up ids, they are no spells of the game
    if (skillId >= 9000000) then
        return nil;
    end

    -- copy the lists so a caller can not change the database
    local difficulty = nil;
    if (skill.difficulty) then
        difficulty = { skill.difficulty[1] or 0, skill.difficulty[2] or 0, skill.difficulty[3] or 0, skill.difficulty[4] or 0 };
    end
    local recipeItemIds = {};
    for _, itemId in ipairs(skill.recipeItemIds or {}) do
        recipeItemIds[#recipeItemIds + 1] = itemId;
    end

    return {
        spellId = skillId,
        recipeItemId = recipeItemId,
        recipeItemIds = recipeItemIds,
        professionId = skill.professionId,
        professionName = self:GetService("profession-names"):GetProfessionName(skill.professionId),
        requiredSkill = difficulty and difficulty[1] or nil,
        difficulty = difficulty,
        craftedItemId = (skill.itemId and skill.itemId ~= 0) and skill.itemId or nil,
    };
end

--- Get the recipe a recipe item teaches.
-- @param recipeItemId Item id of the pattern, plans, schematic, ...
-- @return Info table or nil when the item is no recipe of this client.
function ApiService:GetRecipeInfo(recipeItemId)
    if (type(recipeItemId) ~= "number" or not self:IsReady()) then
        return nil;
    end
    return self:BuildRecipeInfo(self:GetService("skills"):GetSkillIdByRecipeItemId(recipeItemId), recipeItemId);
end

--- Get a recipe by the spell id of the crafting recipe (also trainer recipes).
-- @param spellId Spell id of the crafting recipe.
-- @return Info table or nil for an unknown spell.
function ApiService:GetRecipeInfoBySpell(spellId)
    if (type(spellId) ~= "number" or not self:IsReady()) then
        return nil;
    end
    return self:BuildRecipeInfo(spellId);
end

--- Look a skill up in the last scan of the profession window of the logged
--- in character.
-- @param skill Skill wrapper.
-- @param skillId Spell id of the crafting recipe.
-- @return true or false, nil when the profession was never scanned.
function ApiService:IsSkillInOwnScan(skill, skillId)
    local playerService = self:GetService("player");
    local ownProfessions = playerService.node.own[playerService.current];
    local ownSkills = ownProfessions and ownProfessions[skill.professionId];
    if (not ownSkills) then
        return nil;
    end

    for _, ownSkill in ipairs(ownSkills) do
        if (ownSkill.skillId == skillId) then
            return true;
        end
    end
    return false;
end

--- Read the "Already known" line of a recipe item from its tooltip. The game
--- writes it itself, so it is right even when the recipe was learned after
--- the last scan of the profession window.
-- @param recipeItemId Item id of the recipe item.
-- @return true or false, nil while the client has no data of the item yet.
function ApiService:IsRecipeItemMarkedKnown(recipeItemId)
    if (not ITEM_SPELL_KNOWN) then
        return nil;
    end

    -- an item the client has not seen yet has an empty tooltip, ask for it
    -- so a later call can answer
    local isCached;
    if (C_Item and C_Item.IsItemDataCachedByID) then
        isCached = C_Item.IsItemDataCachedByID(recipeItemId);
    else
        isCached = self.addon.compat.GetItemInfo and self.addon.compat.GetItemInfo(recipeItemId) ~= nil;
    end
    if (not isCached) then
        if (C_Item and C_Item.RequestLoadItemDataByID and C_Item.DoesItemExistByID(recipeItemId)) then
            C_Item.RequestLoadItemDataByID(recipeItemId);
        end
        return nil;
    end

    local lines = self:GetService("tooltip"):GetHyperlinkTooltipLines("item:" .. recipeItemId);
    if (#lines == 0) then
        return nil;
    end
    for _, line in ipairs(lines) do
        if (line.left == ITEM_SPELL_KNOWN) then
            return true;
        end
    end
    return false;
end

--- Check whether the logged in character knows a skill: the own scan and the
--- tooltips of the recipe items, whatever says "known" first wins.
-- @param skillId Spell id of the crafting recipe.
-- @param recipeItemId Recipe item to read the tooltip of (optional, default all of the skill).
-- @return true or false, nil when nothing can tell yet.
function ApiService:IsSkillKnown(skillId, recipeItemId)
    local skill = skillId and self:GetService("skills"):GetSkillById(skillId);
    if (not skill or not skill.professionId) then
        return nil;
    end

    local scanned = self:IsSkillInOwnScan(skill, skillId);
    if (scanned == true) then
        return true;
    end

    -- the tooltip answers for recipes learned since the last scan and for
    -- professions that were never opened
    local recipeItemIds = recipeItemId and { recipeItemId } or skill.recipeItemIds or {};
    local tooltipAnswered = false;
    for _, itemId in ipairs(recipeItemIds) do
        local marked = self:IsRecipeItemMarkedKnown(itemId);
        if (marked == true) then
            return true;
        elseif (marked == false) then
            tooltipAnswered = true;
        end
    end
    if (tooltipAnswered) then
        return false;
    end

    return scanned;
end

--- Check whether the logged in character knows the recipe of a recipe item.
-- @param recipeItemId Item id of the recipe item.
-- @return true or false, nil for an unknown item or when nothing can tell yet.
function ApiService:IsRecipeKnown(recipeItemId)
    if (type(recipeItemId) ~= "number" or not self:IsReady()) then
        return nil;
    end
    return self:IsSkillKnown(self:GetService("skills"):GetSkillIdByRecipeItemId(recipeItemId), recipeItemId);
end

--- Check whether the logged in character knows a crafting recipe by spell id.
-- @param spellId Spell id of the crafting recipe.
-- @return true or false, nil for an unknown spell or when nothing can tell yet.
function ApiService:IsRecipeKnownBySpell(spellId)
    if (type(spellId) ~= "number" or not self:IsReady()) then
        return nil;
    end
    return self:IsSkillKnown(spellId);
end

--- Get the skill level of the logged in character in a profession.
-- @param professionId Skill line id of the profession (197 tailoring, 333 enchanting, ...).
-- @return Skill level, nil when the character does not have the profession.
function ApiService:GetProfessionLevel(professionId)
    if (type(professionId) ~= "number" or not self:IsReady()) then
        return nil;
    end
    local playerService = self:GetService("player");
    local ownLevels = playerService.node.ownLevels and playerService.node.ownLevels[playerService.current];
    return ownLevels and ownLevels[professionId] or nil;
end

-- public api for other addons: a table of its own, so nothing of the addon
-- container becomes a contract by accident. Read only, functions are only
-- ever added (Version counts up with them), existing ones keep their
-- arguments and results. Every function may be called with a dot or a colon.
local PublicApi = { Version = 1 };
for _, name in ipairs({ "IsReady", "GetRecipeInfo", "GetRecipeInfoBySpell", "IsRecipeKnown", "IsRecipeKnownBySpell", "GetProfessionLevel" }) do
    PublicApi[name] = function(first, second)
        local service = _G.professionMaster:GetService("api");
        if (first == PublicApi) then
            return service[name](service, second);
        end
        return service[name](service, first);
    end
end
_G.ProfessionMasterApi = PublicApi;
