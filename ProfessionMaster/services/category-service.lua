--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local CategoryService = _G.professionMaster:CreateService("category");

--- Get localized text for a main category id.
-- @param categoryId Category ID string (e.g. "enchant", "4:1", "2").
-- @return Localized category text.
function CategoryService:GetCategoryText(categoryId)
    if (not categoryId) then
        return self:GetService("locale"):Get("ProfessionsViewCategoryAll");
    end

    if (categoryId == "enchant") then
        return self:GetService("locale"):Get("ProfessionsViewEnchantment");
    end

    local parts = {strsplit(":", categoryId)};
    local classId = tonumber(parts[1]);
    local subclassId = tonumber(parts[2]);

    if (classId and subclassId) then
        return self.addon.compat.GetItemClassInfo(classId) .. " - " .. self.addon.compat.GetItemSubClassInfo(classId, subclassId);
    elseif (classId) then
        return self.addon.compat.GetItemClassInfo(classId);
    end

    return categoryId;
end

--- Get localized text for a subcategory id.
-- @param subcategoryId Subcategory ID string (e.g. "ec:Chest", "sub:2:7", "slot:INVTYPE_CHEST").
-- @return Localized subcategory text.
function CategoryService:GetSubcategoryText(subcategoryId)
    if (not subcategoryId) then
        return self:GetService("locale"):Get("ProfessionsViewSubcategoryAll");
    end

    if (string.sub(subcategoryId, 1, 3) == "ec:") then
        return string.sub(subcategoryId, 4);
    end

    if (string.sub(subcategoryId, 1, 4) == "sub:") then
        local parts = {strsplit(":", string.sub(subcategoryId, 5))};
        local classId = tonumber(parts[1]);
        local subclassId = tonumber(parts[2]);
        if (classId and subclassId) then
            return self.addon.compat.GetItemSubClassInfo(classId, subclassId);
        end
    end

    if (string.sub(subcategoryId, 1, 5) == "slot:") then
        local equipLoc = string.sub(subcategoryId, 6);
        return _G[equipLoc] or equipLoc;
    end

    return subcategoryId;
end

--- Check if a skill matches the given addon filter.
-- @param skillData Skill data table.
-- @param addonId Addon ID to check.
-- @return true if skill matches addon.
function CategoryService:MatchesAddon(skillData, addonId)
    if (skillData.addonIds) then
        return tContains(skillData.addonIds, addonId);
    end
    return addonId == skillData.addon;
end

--- Check if a skill matches the given category and subcategory filters.
-- @param skillData Skill data table.
-- @param professionId Profession ID of this skill.
-- @param categoryId Currently selected category (or nil for all).
-- @param subcategoryId Currently selected subcategory (or nil for all).
-- @return true if skill passes the filter.
function CategoryService:MatchesCategory(skillData, professionId, categoryId, subcategoryId)
    if (not categoryId) then
        return true;
    end

    if (categoryId == "enchant") then
        if (professionId ~= 333 or (skillData.itemId and skillData.itemId ~= 0)) then
            return false;
        end
        if (subcategoryId) then
            local filterCategory = string.sub(subcategoryId, 4);
            return skillData.enchantCategory == filterCategory;
        end
        return true;
    end

    if (string.sub(categoryId, 1, 2) == "4:") then
        local catSubclassId = tonumber(string.sub(categoryId, 3));
        if (skillData.classId ~= 4 or skillData.subclassId ~= catSubclassId) then
            return false;
        end
        if (subcategoryId) then
            local filterEquipLoc = string.sub(subcategoryId, 6);
            local normalizedLoc = (skillData.equipLoc == "INVTYPE_ROBE") and "INVTYPE_CHEST" or skillData.equipLoc;
            return normalizedLoc == filterEquipLoc;
        end
        return true;
    end

    local catClassId = tonumber(categoryId);
    if (catClassId) then
        if (skillData.classId ~= catClassId) then
            return false;
        end
        if (subcategoryId and string.sub(subcategoryId, 1, 4) == "sub:") then
            local parts = {strsplit(":", string.sub(subcategoryId, 5))};
            local filterSubclassId = tonumber(parts[2]);
            return skillData.subclassId == filterSubclassId;
        end
        return true;
    end

    return true;
end

--- Determine the category ID for a given skill.
-- @param skillData Skill data table.
-- @param professionId Profession ID.
-- @return Category ID string or nil.
function CategoryService:GetSkillCategoryId(skillData, professionId)
    if (professionId == 333 and (not skillData.itemId or skillData.itemId == 0)) then
        return "enchant";
    elseif (skillData.classId == 4 and skillData.subclassId) then
        return "4:" .. skillData.subclassId;
    elseif (skillData.classId) then
        return tostring(skillData.classId);
    end
    return nil;
end

--- Determine the subcategory ID for a given skill within a category.
-- @param skillData Skill data table.
-- @param professionId Profession ID.
-- @param categoryId Currently selected category.
-- @return Subcategory ID string or nil.
function CategoryService:GetSkillSubcategoryId(skillData, professionId, categoryId)
    if (not categoryId) then return nil; end

    if (categoryId == "enchant") then
        if (professionId == 333 and skillData.enchantCategory) then
            return "ec:" .. skillData.enchantCategory;
        end
    elseif (string.sub(categoryId, 1, 2) == "4:") then
        local catSubclassId = tonumber(string.sub(categoryId, 3));
        if (skillData.classId == 4 and skillData.subclassId == catSubclassId and skillData.equipLoc and skillData.equipLoc ~= "") then
            local normalizedLoc = (skillData.equipLoc == "INVTYPE_ROBE") and "INVTYPE_CHEST" or skillData.equipLoc;
            return "slot:" .. normalizedLoc;
        end
    else
        local catClassId = tonumber(categoryId);
        if (catClassId and skillData.classId == catClassId and skillData.subclassId) then
            return "sub:" .. skillData.classId .. ":" .. skillData.subclassId;
        end
    end

    return nil;
end

--- Build category dropdown items from a list of visible skill entries.
-- @param visibleSkills Array of { professionId, skillData } tables.
-- @return Array of dropdown items.
function CategoryService:BuildCategoryItems(visibleSkills)
    local localeService = self:GetService("locale");
    local items = {{ value = nil, text = localeService:Get("ProfessionsViewCategoryAll") }};

    local categories = {};
    local categoryOrder = {};

    for _, entry in ipairs(visibleSkills) do
        local catId = self:GetSkillCategoryId(entry.skillData, entry.professionId);
        if (catId and not categories[catId]) then
            categories[catId] = true;
            table.insert(categoryOrder, catId);
        end
    end

    table.sort(categoryOrder, function(a, b)
        return self:GetCategoryText(a) < self:GetCategoryText(b);
    end);

    for _, catId in ipairs(categoryOrder) do
        table.insert(items, { value = catId, text = self:GetCategoryText(catId) });
    end

    return items;
end

--- Build subcategory dropdown items from a list of visible skill entries.
-- @param visibleSkills Array of { professionId, skillData } tables.
-- @param categoryId Currently selected category.
-- @return Array of dropdown items.
function CategoryService:BuildSubcategoryItems(visibleSkills, categoryId)
    local localeService = self:GetService("locale");
    local items = {{ value = nil, text = localeService:Get("ProfessionsViewSubcategoryAll") }};

    if (not categoryId) then
        return items;
    end

    local subcategories = {};
    local subcategoryOrder = {};

    for _, entry in ipairs(visibleSkills) do
        local subId = self:GetSkillSubcategoryId(entry.skillData, entry.professionId, categoryId);
        if (subId and not subcategories[subId]) then
            subcategories[subId] = true;
            table.insert(subcategoryOrder, subId);
        end
    end

    table.sort(subcategoryOrder, function(a, b)
        return self:GetSubcategoryText(a) < self:GetSubcategoryText(b);
    end);

    for _, subId in ipairs(subcategoryOrder) do
        table.insert(items, { value = subId, text = self:GetSubcategoryText(subId) });
    end

    return items;
end

--- Check if there are multiple subcategories available for a given category.
-- @param visibleSkills Array of { professionId, skillData } tables.
-- @param categoryId Currently selected category.
-- @return true if more than one subcategory exists.
function CategoryService:HasSubcategories(visibleSkills, categoryId)
    if (not categoryId) then
        return false;
    end

    local subcategories = {};
    local count = 0;

    for _, entry in ipairs(visibleSkills) do
        local subId = self:GetSkillSubcategoryId(entry.skillData, entry.professionId, categoryId);
        if (subId and not subcategories[subId]) then
            subcategories[subId] = true;
            count = count + 1;
            if (count > 1) then
                return true;
            end
        end
    end

    return false;
end
