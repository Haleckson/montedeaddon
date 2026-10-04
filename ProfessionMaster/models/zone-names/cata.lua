--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Zone name lookup for cata
-- Keyed by zoneId (areaID), used to resolve zone names from recipe-sources data
local zoneNames = {
    [616] = "Mount Hyjal",
    [4706] = "Ruins of Gilneas",
    [4709] = "Southern Barrens",
    [4714] = "Gilneas",
    [4720] = "The Lost Isles",
    [4742] = "Hrothgar's Landing",
    [4755] = "Gilneas City",
    [4815] = "Kelp'thar Forest",
    [4922] = "Twilight Highlands",
    [4926] = "Blackrock Caverns",
    [4945] = "Halls of Origination",
    [4950] = "Grim Batol",
    [4987] = "The Ruby Sanctum",
    [5004] = "Throne of the Tides",
    [5034] = "Uldum",
    [5035] = "The Vortex Pinnacle",
    [5042] = "Deepholm",
    [5088] = "The Stonecore",
    [5094] = "Blackwing Descent",
    [5095] = "Tol Barad",
    [5144] = "Shimmering Expanse",
    [5145] = "Abyssal Depths",
    [5287] = "The Cape of Stranglethorn",
    [5334] = "The Bastion of Twilight",
    [5389] = "Tol Barad Peninsula",
    [5396] = "Lost City of the Tol'vir",
    [5600] = "Baradin Hold",
    [5723] = "Firelands",
    [5733] = "Molten Front",
    [5788] = "Well of Eternity",
    [5789] = "End Time",
    [5844] = "Hour of Twilight",
    [5861] = "Darkmoon Island",
    [5892] = "Dragon Soul",
    [5339] = "Stranglethorn Vale",
};

_G.professionMaster:CreateModel("zone-names-cata", zoneNames);
