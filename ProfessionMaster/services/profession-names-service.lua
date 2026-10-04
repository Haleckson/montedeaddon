--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]
-- create service
local ProfessionNamesService = _G.professionMaster:CreateService("profession-names");

--- Initialize service.
function ProfessionNamesService:Initialize()
    self.professionSpells = self:GetModel("profession-spells");

    -- build profession names from game spell data (works in all locales and versions)
    self.professionNames = {};
    self.professionIds = {};

    for skillLineId, spellId in pairs(self.professionSpells) do
        -- GetSpellInfo works in Classic Era, BCC, Wrath, Cata, MoP for any valid spell ID
        local spellName = self.addon.compat.GetSpellInfo(spellId);
        if (spellName) then
            self.professionNames[skillLineId] = spellName;
            self.professionIds[spellName] = skillLineId;
        end
    end

    -- re-apply skill line aliases learned in previous sessions, so name lookups
    -- and display names are correct before any profession window was opened
    if (PM_CharacterSettings and PM_CharacterSettings.professionNameAliases) then
        for professionName, professionId in pairs(PM_CharacterSettings.professionNameAliases) do
            if (self.professionIds[professionName]) then
                -- name resolves via spell data meanwhile, drop the stale alias
                -- (also heals aliases learned for untracked skill lines like first aid)
                PM_CharacterSettings.professionNameAliases[professionName] = nil;
            else
                self.professionIds[professionName] = professionId;
                self.professionNames[professionId] = professionName;
            end
        end
    end

    -- warn if nothing loaded at all
    if (not next(self.professionNames)) then
        self:GetService("chat"):Write("LanguageNotSupported");
    end
end

--- Get profession ids to show.
-- @return List of ids.
function ProfessionNamesService:GetProfessionIdsToShow(personal)
    -- get classic profession ids
    local professionIds = {
        333,
        171,
        197,
        165,
        164,
        202,
        185,
        186
    };

    -- gathering professions only shown on personal (own) tab
    if (personal) then
        table.insert(professionIds, 7, 182);
    end

    -- add non vanilla ids
    if (self.addon.isBccAtLeast) then
        table.insert(professionIds, 2, 755);
    end
    if (self.addon.isWrathAtLeast) then
        table.insert(professionIds, 773);
    end
    return professionIds;
end

--- Profession IDs that have a gathering component (auto-learned skills based on level).
local GATHERING_COMPONENT_PROFESSIONS = { [182] = true, [186] = true };

--- Check if a profession is a pure gathering profession (no crafting window at all).
-- @param professionId Id of profession to check.
-- @return True if the profession is a pure gathering profession.
function ProfessionNamesService:IsGatheringProfession(professionId)
    return professionId == 182;
end

--- Check if a profession has a gathering component (auto-learned skills based on level).
-- Includes both pure gathering professions and hybrid ones like Mining.
-- @param professionId Id of profession to check.
-- @return True if the profession has gathering skills.
function ProfessionNamesService:HasGatheringComponent(professionId)
    return GATHERING_COMPONENT_PROFESSIONS[professionId] == true;
end

--- Get all profession IDs that have a gathering component.
-- @return Table with profession IDs as keys and true as values.
function ProfessionNamesService:GetGatheringProfessionIds()
    return GATHERING_COMPONENT_PROFESSIONS;
end

--- Get profession name by profession id.
-- @param professionId Id of profession to get name for.
-- @return Name of the given profession id or NIL if unknown.
function ProfessionNamesService:GetProfessionName(professionId)
    -- check profession id
    if (not professionId) then
        return nil;
    end

    -- get profession name
    return self.professionNames[professionId];
end

--- Get profession icon by profession id.
-- @param professionId Id of profession to get icon for.
-- @return Icon of the given profession id or NIL if unknown.
function ProfessionNamesService:GetProfessionIcon(professionId)
    -- check profession id
    if (not professionId) then
        return nil;
    end

    -- get profession name
    return self:GetModel("profession-icons")[professionId];
end

--- Register an additional localized name for a profession.
-- Used when the skill line name differs from the profession spell name
-- (e.g. frFR skill line "Ingénierie" vs. spell name "Ingénieur").
-- @param professionName Localized skill line name to register.
-- @param professionId Id of the profession the name belongs to.
function ProfessionNamesService:RegisterProfessionNameAlias(professionName, professionId)
    -- check parameters and skip already known names
    if (not professionName or professionName == "UNKNOWN" or not professionId or self.professionIds[professionName]) then
        return;
    end

    -- register alias
    self.professionIds[professionName] = professionId;

    -- prefer the skill line name for display, it matches the game's profession window
    self.professionNames[professionId] = professionName;

    -- persist learned alias for future sessions
    if (not PM_CharacterSettings.professionNameAliases) then
        PM_CharacterSettings.professionNameAliases = {};
    end
    PM_CharacterSettings.professionNameAliases[professionName] = professionId;
    self.addon:Log("ProfessionNamesService", "RegisterProfessionNameAlias", "Registered alias %s for profession %d", professionName, professionId);
end

--- Check whether a profession name is a learned skill line alias rather than a
--- name from the spell data.
-- @param professionName Name to check.
-- @return True when the name was registered as alias.
function ProfessionNamesService:IsProfessionNameAlias(professionName)
    local aliases = PM_CharacterSettings and PM_CharacterSettings.professionNameAliases;
    return (professionName ~= nil) and (aliases ~= nil) and (aliases[professionName] ~= nil);
end

--- Drop a learned skill line alias that points to the wrong profession; names
--- from the spell data are never dropped.
-- @param professionName Skill line name of the alias.
function ProfessionNamesService:DropProfessionNameAlias(professionName)
    if (not professionName) then
        return;
    end
    local aliases = PM_CharacterSettings and PM_CharacterSettings.professionNameAliases;
    if (not aliases or not aliases[professionName]) then
        return;
    end
    local professionId = aliases[professionName];
    aliases[professionName] = nil;
    self.professionIds[professionName] = nil;

    -- restore the spell data display name of the profession
    local spellId = self.professionSpells and self.professionSpells[professionId];
    local spellName = spellId and self.addon.compat.GetSpellInfo(spellId);
    if (spellName) then
        self.professionNames[professionId] = spellName;
        self.professionIds[spellName] = professionId;
    end
    self.addon:Log("ProfessionNamesService", "DropProfessionNameAlias", "Dropped alias %s for profession %d", professionName, professionId);
end

--- Get profession id by profession name.
-- @param professionName Name of profession to get id for.
-- @return Id of the given profession name or NIL if unknown.
function ProfessionNamesService:GetProfessionId(professionName)
    -- check profession name
    if (not professionName or professionName == "UNKNOWN") then
        return nil;
    end

    -- get profession id
    return self.professionIds[professionName];
end

--- Get skill id by skill link.
-- @param skillLink Link of skill to get id for.
-- @return Id of the given skill link.
function ProfessionNamesService:GetSkillId(skillLink)
    -- find enchant prefix
    local _, enchantPrefixEnd = string.find(skillLink, "|Henchant:");
    if (enchantPrefixEnd == 0 or enchantPrefixEnd == nil) then
        return nil;
    end

    -- find enchant suffix
    local enchantSuffixBegin = string.find(skillLink, "|h", enchantPrefixEnd + 1);
    if (enchantSuffixBegin < enchantPrefixEnd) then
        return nil;
    end

    -- get skill id
    return tonumber(string.sub(skillLink, enchantPrefixEnd + 1, enchantSuffixBegin - 1));
end

--- Get skill link by skill id and name.
-- @param professionId Id of profession to get link for.
-- @param skillId Id of skill to get link for.
-- @param itemName Name of item to get link for.
-- @return Link of the given skill id.
function ProfessionNamesService:GetSkillLink(professionId, skillId, itemName)
    return "|cffffd000|Henchant:" .. skillId .. "|h[" .. self:GetProfessionName(professionId) .. ": " .. itemName .. "]|h|r";
end

--- Get item color by item link.
-- @param itemLink Link of item to get color for.
-- @return Color of the given item link as AARRGGBB.
function ProfessionNamesService:GetItemColor(itemLink)
    if (type(itemLink) ~= "string") then
        return "ffffffff";
    end

    -- classic links carry the color itself: |cffRRGGBB|Hitem:...
    local hexColor = string.match(itemLink, "^|c(%x%x%x%x%x%x%x%x)");
    if (hexColor) then
        return hexColor;
    end

    -- links of the modern client name the quality instead: |cnIQ3:|Hitem:...
    local quality = tonumber(string.match(itemLink, "^|cnIQ(%d+):"));
    local qualityColor = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality];
    if (qualityColor and qualityColor.hex) then
        return string.match(qualityColor.hex, "^|c(%x%x%x%x%x%x%x%x)") or "ffffffff";
    end
    return "ffffffff";
end

--- Get formatted addon text with icon.
-- @param addonId Addon ID (1-5) or nil.
-- @return Formatted addon text string or nil.
function ProfessionNamesService:GetAddonText(addonId)
    if (addonId == 1) then
        return "|T135954:16|t Vanilla";
    elseif (addonId == 2) then
        return "|T135804:16|t TBC";
    elseif (addonId == 3) then
        return "|T135773:16|t WOTLK";
    elseif (addonId == 4) then
        return "|T134158:16|t Cata";
    elseif (addonId == 5) then
        return "|T132183:16|t MoP";
    elseif (addonId == 102) then
        return "|T135954:16|t SoD";
    end
    return nil;
end

--- Get formatted profession text with icon for dropdown display.
-- @param professionId Profession ID (0 = "All Professions").
-- @param allIcon Optional icon ID for the "All Professions" entry (default 133745).
-- @return Formatted string with icon texture and profession name.
function ProfessionNamesService:GetProfessionText(professionId, allIcon)
    if (professionId == 0) then
        -- "all professions" entry with configurable icon
        return "|T" .. (allIcon or 133745) .. ":16|t " .. self:GetService("locale"):Get("ProfessionsViewAllProfessions");
    end

    -- specific profession with its icon
    return "|T" .. self:GetProfessionIcon(professionId) .. ":16|t  " .. self:GetProfessionName(professionId);
end

--- Build addon dropdown items for the current game version.
-- @param includeAll Whether to include an "All Addons" entry at the top.
-- @return Array of dropdown items.
function ProfessionNamesService:BuildAddonItems(includeAll)
    local localeService = self:GetService("locale");
    local items = {};
    if (includeAll) then
        table.insert(items, { value = nil, text = "|T135749:16|t " .. localeService:Get("ProfessionsViewAllAddons") });
    end
    table.insert(items, { value = 1, text = self:GetAddonText(1) });
    if (self.addon.isSod) then
        table.insert(items, { value = 6, text = self:GetAddonText(102) });
    end
    if (self.addon.isBccAtLeast) then
        table.insert(items, { value = 2, text = self:GetAddonText(2) });
    end
    if (self.addon.isWrathAtLeast) then
        table.insert(items, { value = 3, text = self:GetAddonText(3) });
    end
    if (self.addon.isCataAtLeast) then
        table.insert(items, { value = 4, text = self:GetAddonText(4) });
    end
    if (self.addon.isMopAtLeast) then
        table.insert(items, { value = 5, text = self:GetAddonText(5) });
    end
    return items;
end
