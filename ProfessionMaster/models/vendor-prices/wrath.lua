--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- Vendor prices for wrath (additions and overrides to vanilla and bcc, same format)
local vendorPrices = {
    -- Threads (Tailoring / Leatherworking)
    [38426] = 30000,     -- Eternium Thread

    -- Inscription
    [39354] = 15,        -- Light Parchment
    [10648] = 125,       -- Common Parchment
    [39501] = 1250,      -- Heavy Parchment
    [39502] = 5000,      -- Resilient Parchment

    -- Cooking
    [35949] = 1700,      -- Tundra Berries
    [35948] = 3200,      -- Savory Snowplum

    -- Engineering
    [5956] = 18,         -- Blacksmith Hammer
    [2901] = 81,         -- Mining Pick
    [7005] = 82,         -- Skinning Knife
    [39684] = 9000,      -- Hair Trigger
    [40533] = 50000,     -- Walnut Stock
    [44501] = 10000000,  -- Goblin-machined Piston
    [44499] = 30000000,  -- Salvaged Iron Golem Parts
}

_G.professionMaster:CreateModel("vendor-prices-wrath", vendorPrices);
