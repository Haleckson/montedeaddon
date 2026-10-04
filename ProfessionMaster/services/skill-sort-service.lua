--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local SkillSortService = _G.professionMaster:CreateService("skill-sort");

--- Determine the difficulty zone for a skill at a given level.
-- @param difficulty Difficulty table {d1, d2, d3, d4}.
-- @param level Current skill level.
-- @return Zone number: 1=red, 2=orange, 3=yellow, 4=green, 5=grey.
function SkillSortService:GetDifficultyZone(difficulty, level)
    if (not difficulty) then return 5; end
    local d1 = difficulty[1] or 0;
    local d2 = difficulty[2] or 0;
    local d3 = difficulty[3] or 0;
    local d4 = difficulty[4] or 0;
    if (level < d1) then return 1; end
    if (level < d2) then return 2; end
    if (level < d3) then return 3; end
    if (level < d4) then return 4; end
    return 5;
end

--- Get the colored leveling text of a skill: the skill points until the
--- recipe turns orange, yellow, green and grey at the given level.
-- @param difficulty Difficulty table {d1, d2, d3, d4}.
-- @param level Current skill level.
-- @return Colored text or nil without difficulty data.
function SkillSortService:GetLevelingText(difficulty, level)
    if (not difficulty) then
        return nil;
    end

    local d1 = difficulty[1] or 0;
    local d2 = difficulty[2] or 0;
    local d3 = difficulty[3] or 0;
    local d4 = difficulty[4] or 0;
    level = level or 0;

    if (level < d1) then
        return "|cffff4040" .. (d1 - level) .. "|r";
    elseif (level < d2) then
        return "|cffff8040" .. (d2 - level) .. "|r |cffffffff/|r |cffffff00" .. (d3 - level) .. "|r |cffffffff/|r |cff40c040" .. (d4 - level) .. "|r";
    elseif (level < d3) then
        return "|cffffff00" .. (d3 - level) .. "|r |cffffffff/|r |cff40c040" .. (d4 - level) .. "|r";
    elseif (level < d4) then
        return "|cff40c040" .. (d4 - level) .. "|r";
    else
        return "|cffaaaaaa0|r";
    end
end

--- Sort a skills table by difficulty zones.
-- Bucket list items are always sorted first, favorites second.
-- @param skills Array of skill entries (each with .skill.difficulty, .skill.name, .bucketListAmount, .isFavorite).
-- @param level Current skill level.
-- @param sortAscending Whether to sort ascending (easiest first).
function SkillSortService:SortByDifficulty(skills, level, sortAscending)
    table.sort(skills, function(a, b)
        if (a.bucketListAmount and not b.bucketListAmount) then return true; end
        if (not a.bucketListAmount and b.bucketListAmount) then return false; end
        if (a.isFavorite and not b.isFavorite) then return true; end
        if (not a.isFavorite and b.isFavorite) then return false; end

        local ad = a.skill.difficulty;
        local bd = b.skill.difficulty;
        local ad1 = ad and ad[1] or 0;
        local ad2 = ad and ad[2] or 0;
        local ad3 = ad and ad[3] or 0;
        local ad4 = ad and ad[4] or 0;
        local bd1 = bd and bd[1] or 0;
        local bd2 = bd and bd[2] or 0;
        local bd3 = bd and bd[3] or 0;
        local bd4 = bd and bd[4] or 0;

        local aZone = self:GetDifficultyZone(ad, level);
        local bZone = self:GetDifficultyZone(bd, level);

        if (aZone ~= bZone) then
            if (sortAscending) then
                return aZone > bZone;
            else
                return aZone < bZone;
            end
        end

        -- within same zone, sort by relevant values
        if (aZone == 1) then
            local aDiff = ad1 - level; local bDiff = bd1 - level;
            if (aDiff ~= bDiff) then
                if (sortAscending) then return aDiff < bDiff; else return aDiff > bDiff; end
            end
        elseif (aZone == 2) then
            local aDiff = ad2 - level; local bDiff = bd2 - level;
            if (aDiff ~= bDiff) then
                if (sortAscending) then return aDiff < bDiff; else return aDiff > bDiff; end
            end
            local aDiff3 = ad3 - level; local bDiff3 = bd3 - level;
            if (aDiff3 ~= bDiff3) then
                if (sortAscending) then return aDiff3 < bDiff3; else return aDiff3 > bDiff3; end
            end
            local aDiff4 = ad4 - level; local bDiff4 = bd4 - level;
            if (aDiff4 ~= bDiff4) then
                if (sortAscending) then return aDiff4 < bDiff4; else return aDiff4 > bDiff4; end
            end
        elseif (aZone == 3) then
            local aDiff = ad3 - level; local bDiff = bd3 - level;
            if (aDiff ~= bDiff) then
                if (sortAscending) then return aDiff < bDiff; else return aDiff > bDiff; end
            end
            local aDiff4 = ad4 - level; local bDiff4 = bd4 - level;
            if (aDiff4 ~= bDiff4) then
                if (sortAscending) then return aDiff4 < bDiff4; else return aDiff4 > bDiff4; end
            end
        elseif (aZone == 4) then
            local aDiff = ad4 - level; local bDiff = bd4 - level;
            if (aDiff ~= bDiff) then
                if (sortAscending) then return aDiff < bDiff; else return aDiff > bDiff; end
            end
        else
            if (ad4 ~= bd4) then
                if (sortAscending) then return ad4 < bd4; else return ad4 > bd4; end
            end
        end

        -- tiebreaker: always alphabetical ascending
        return a.skill.name < b.skill.name;
    end);
end

--- Sort a skills table by item name.
-- Bucket list items are always sorted first, favorites second.
-- @param skills Array of skill entries (each with .skill.name, .bucketListAmount, .isFavorite).
-- @param sortAscending Whether to sort ascending (A-Z).
function SkillSortService:SortByName(skills, sortAscending)
    table.sort(skills, function(a, b)
        if (a.bucketListAmount and not b.bucketListAmount) then return true; end
        if (not a.bucketListAmount and b.bucketListAmount) then return false; end
        if (a.isFavorite and not b.isFavorite) then return true; end
        if (not a.isFavorite and b.isFavorite) then return false; end

        if (sortAscending) then
            return a.skill.name < b.skill.name;
        else
            return a.skill.name > b.skill.name;
        end
    end);
end

--- Sort a skills table by profit.
-- Bucket list items are always sorted first, favorites second.
-- Skills without profit data are sorted to the end.
-- @param skills Array of skill entries (each with .profit, .skill.name, .bucketListAmount, .isFavorite).
-- @param sortAscending Whether to sort ascending (lowest profit first).
function SkillSortService:SortByProfit(skills, sortAscending)
    table.sort(skills, function(a, b)
        -- bucket list items always first, favorites second
        if (a.bucketListAmount and not b.bucketListAmount) then return true; end
        if (not a.bucketListAmount and b.bucketListAmount) then return false; end
        if (a.isFavorite and not b.isFavorite) then return true; end
        if (not a.isFavorite and b.isFavorite) then return false; end

        -- nil profits go to end
        if (a.profit and not b.profit) then return true; end
        if (not a.profit and b.profit) then return false; end
        if (not a.profit and not b.profit) then return a.skill.name < b.skill.name; end

        -- sort by profit value
        if (a.profit ~= b.profit) then
            if (sortAscending) then
                return a.profit < b.profit;
            else
                return a.profit > b.profit;
            end
        end

        -- tiebreaker: alphabetical
        return a.skill.name < b.skill.name;
    end);
end
