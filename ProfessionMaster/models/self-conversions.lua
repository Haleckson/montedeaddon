--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create self-conversions model
-- items anyone can craft without a profession (right-click / combine conversions),
-- e.g. enchanting essences and elemental motes. these are checked before profession
-- skills when the bucket list resolves how a reagent can be crafted by the player.
-- format: [resultItemId] = { itemAmount = producedCount, reagents = { [sourceItemId] = requiredCount } }
local addon = _G.professionMaster;
local conversions = {};

-- vanilla enchanting essences convert both ways: 3 lesser <-> 1 greater
conversions[11082] = { itemAmount = 1, reagents = { [10998] = 3 } };  -- 3 lesser astral -> 1 greater astral essence
conversions[10998] = { itemAmount = 3, reagents = { [11082] = 1 } };  -- 1 greater astral -> 3 lesser astral essence
conversions[16203] = { itemAmount = 1, reagents = { [16202] = 3 } };  -- 3 lesser eternal -> 1 greater eternal essence
conversions[16202] = { itemAmount = 3, reagents = { [16203] = 1 } };  -- 1 greater eternal -> 3 lesser eternal essence
conversions[11175] = { itemAmount = 1, reagents = { [11174] = 3 } };  -- 3 lesser nether -> 1 greater nether essence
conversions[11174] = { itemAmount = 3, reagents = { [11175] = 1 } };  -- 1 greater nether -> 3 lesser nether essence
conversions[11135] = { itemAmount = 1, reagents = { [11134] = 3 } };  -- 3 lesser mystic -> 1 greater mystic essence
conversions[11134] = { itemAmount = 3, reagents = { [11135] = 1 } };  -- 1 greater mystic -> 3 lesser mystic essence
conversions[10939] = { itemAmount = 1, reagents = { [10938] = 3 } };  -- 3 lesser magic -> 1 greater magic essence
conversions[10938] = { itemAmount = 3, reagents = { [10939] = 1 } };  -- 1 greater magic -> 3 lesser magic essence

-- tbc and later add planar essences (both ways) and elemental motes (one way)
if (addon.isBccAtLeast) then
    -- planar essence converts both ways: 3 lesser <-> 1 greater
    conversions[22446] = { itemAmount = 1, reagents = { [22447] = 3 } };  -- 3 lesser planar -> 1 greater planar essence
    conversions[22447] = { itemAmount = 3, reagents = { [22446] = 1 } };  -- 1 greater planar -> 3 lesser planar essence

    -- motes combine one way only: 10 motes -> 1 primal
    conversions[22451] = { itemAmount = 1, reagents = { [22572] = 10 } };  -- 10 mote of air -> 1 primal air
    conversions[22452] = { itemAmount = 1, reagents = { [22573] = 10 } };  -- 10 mote of earth -> 1 primal earth
    conversions[21884] = { itemAmount = 1, reagents = { [22574] = 10 } };  -- 10 mote of fire -> 1 primal fire
    conversions[21886] = { itemAmount = 1, reagents = { [22575] = 10 } };  -- 10 mote of life -> 1 primal life
    conversions[22457] = { itemAmount = 1, reagents = { [22576] = 10 } };  -- 10 mote of mana -> 1 primal mana
    conversions[22456] = { itemAmount = 1, reagents = { [22577] = 10 } };  -- 10 mote of shadow -> 1 primal shadow
    conversions[21885] = { itemAmount = 1, reagents = { [22578] = 10 } };  -- 10 mote of water -> 1 primal water
end

-- wrath adds cosmic essences (both ways) and crystallized/eternal elements (both ways)
if (addon.isWrathAtLeast) then
    -- cosmic essence converts both ways: 3 lesser <-> 1 greater
    conversions[34055] = { itemAmount = 1, reagents = { [34056] = 3 } };  -- 3 lesser cosmic -> 1 greater cosmic essence
    conversions[34056] = { itemAmount = 3, reagents = { [34055] = 1 } };  -- 1 greater cosmic -> 3 lesser cosmic essence

    -- crystallized elements convert both ways: 10 crystallized <-> 1 eternal
    conversions[35623] = { itemAmount = 1, reagents = { [37700] = 10 } };  -- 10 crystallized air -> 1 eternal air
    conversions[37700] = { itemAmount = 10, reagents = { [35623] = 1 } };  -- 1 eternal air -> 10 crystallized air
    conversions[35624] = { itemAmount = 1, reagents = { [37701] = 10 } };  -- 10 crystallized earth -> 1 eternal earth
    conversions[37701] = { itemAmount = 10, reagents = { [35624] = 1 } };  -- 1 eternal earth -> 10 crystallized earth
    conversions[36860] = { itemAmount = 1, reagents = { [37702] = 10 } };  -- 10 crystallized fire -> 1 eternal fire
    conversions[37702] = { itemAmount = 10, reagents = { [36860] = 1 } };  -- 1 eternal fire -> 10 crystallized fire
    conversions[35625] = { itemAmount = 1, reagents = { [37704] = 10 } };  -- 10 crystallized life -> 1 eternal life
    conversions[37704] = { itemAmount = 10, reagents = { [35625] = 1 } };  -- 1 eternal life -> 10 crystallized life
    conversions[35627] = { itemAmount = 1, reagents = { [37703] = 10 } };  -- 10 crystallized shadow -> 1 eternal shadow
    conversions[37703] = { itemAmount = 10, reagents = { [35627] = 1 } };  -- 1 eternal shadow -> 10 crystallized shadow
    conversions[35622] = { itemAmount = 1, reagents = { [37705] = 10 } };  -- 10 crystallized water -> 1 eternal water
    conversions[37705] = { itemAmount = 10, reagents = { [35622] = 1 } };  -- 1 eternal water -> 10 crystallized water
end

-- cata adds celestial essences (both ways); volatiles do not combine
if (addon.isCataAtLeast) then
    -- celestial essence converts both ways: 3 lesser <-> 1 greater
    conversions[52719] = { itemAmount = 1, reagents = { [52718] = 3 } };  -- 3 lesser celestial -> 1 greater celestial essence
    conversions[52718] = { itemAmount = 3, reagents = { [52719] = 1 } };  -- 1 greater celestial -> 3 lesser celestial essence
end

-- mop adds motes of harmony (one way); mop has no lesser/greater essence pair
if (addon.isMopAtLeast) then
    conversions[76061] = { itemAmount = 1, reagents = { [89112] = 10 } };  -- 10 mote of harmony -> 1 spirit of harmony
end

addon:CreateModel("self-conversions", conversions);
