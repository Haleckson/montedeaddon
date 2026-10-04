--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- Vendor prices for bcc (additions and overrides to vanilla, same format)
local vendorPrices = {
    -- Vials (Alchemy)
    [18256] = 4000,      -- Imbued Vial

    -- Cooking
    [30817] = 5,         -- Simple Flour
    [2593] = 150,        -- Flask of Stormwind Tawny
    [2594] = 1500,       -- Flagon of Dwarven Honeymead
    [4539] = 200,        -- Goldenbark Apple

    -- Jewelcrafting
    [27860] = 1280,      -- Purified Draenic Water

    -- Engineering
    [17020] = 1000,      -- Arcane Powder
    [34249] = 1000000,   -- Hula Girl Doll

    -- Poisons
    [2931] = 1000,       -- Maiden's Anguish
}

_G.professionMaster:CreateModel("vendor-prices-bcc", vendorPrices);
