--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- Vendor prices for vanilla
-- Reagents that vendors of both factions sell without limit all year.
-- Keyed by itemId, price per unit in copper: an item sold in stacks has the
-- stack price divided by the stack size. A later expansion file overrides an
-- entry, false takes it out.
local vendorPrices = {
    -- Vials (Alchemy)
    [3371] = 4,          -- Empty Vial
    [3372] = 40,         -- Leaded Vial
    [8925] = 500,        -- Crystal Vial
    [18256] = 6000,      -- Imbued Vial

    -- Threads (Tailoring / Leatherworking)
    [2320] = 10,         -- Coarse Thread
    [2321] = 100,        -- Fine Thread
    [4291] = 500,        -- Silken Thread
    [8343] = 2000,       -- Heavy Silken Thread
    [14341] = 5000,      -- Rune Thread

    -- Dyes (Tailoring / Leatherworking)
    [2324] = 25,         -- Bleach
    [2604] = 50,         -- Red Dye
    [6260] = 50,         -- Blue Dye
    [2605] = 100,        -- Green Dye
    [4340] = 350,        -- Gray Dye
    [4341] = 500,        -- Yellow Dye
    [2325] = 1000,       -- Black Dye
    [6261] = 1000,       -- Orange Dye
    [4342] = 2500,       -- Purple Dye
    [10290] = 2500,      -- Pink Dye

    -- Blacksmithing / Mining
    [2880] = 100,        -- Weak Flux
    [3466] = 2000,       -- Strong Flux
    [3857] = 500,        -- Coal
    [18567] = 150000,    -- Elemental Flux

    -- Leatherworking
    [4289] = 50,         -- Salt

    -- Enchanting
    [17034] = 200,       -- Maple Seed
    [17035] = 400,       -- Stranglethorn Seed
    [4470] = 38,         -- Simple Wood
    [11291] = 4500,      -- Star Wood
    [6217] = 124,        -- Copper Rod

    -- Engineering
    [4399] = 200,        -- Wooden Stock
    [4400] = 2000,       -- Heavy Stock
    [10647] = 2000,      -- Engineer's Ink
    [10648] = 500,       -- Blank Parchment
    [6530] = 100,        -- Nightcrawlers
    [3030] = 2,          -- Razor Arrow, 3s for 200, rounded up

    -- Cooking
    [2678] = 2,          -- Mild Spices
    [2692] = 40,         -- Hot Spices
    [3713] = 160,        -- Soothing Spices
    [159] = 5,           -- Refreshing Spring Water
    [1179] = 25,         -- Ice Cold Milk
    [4536] = 5,          -- Shiny Red Apple
    [2596] = 120,        -- Skin of Dwarven Stout

    -- Poisons
    [2928] = 20,         -- Dust of Decay
    [2930] = 50,         -- Essence of Pain
    [5173] = 100,        -- Deathweed
    [8924] = 100,        -- Dust of Deterioration
    [8923] = 200,        -- Essence of Agony
}

_G.professionMaster:CreateModel("vendor-prices-vanilla", vendorPrices);
