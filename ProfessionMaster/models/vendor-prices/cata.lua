--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- Vendor prices for cata (additions and overrides to vanilla, bcc and wrath, same format)
local vendorPrices = {
    -- Alchemy: every recipe takes the Crystal Vial since Cataclysm, the old
    -- vials of recipes the skill data still lists cost the same
    [3371] = 20,         -- Crystal Vial
    [3372] = 20,         -- Leaded Vial, now Cracked Vial
    [8925] = 20,         -- Crystal Vial before Cataclysm, now Tainted Vial
    [18256] = 20,        -- Imbued Vial, now Melted Vial
    [65893] = 30000000,  -- Sands of Time
    [65892] = 50000000,  -- Pyrium-Laced Crystalline Vial

    -- Blacksmithing
    [18567] = 30000,     -- Elemental Flux

    -- Enchanting
    [38682] = 1000,      -- Enchanting Vellum

    -- Jewelcrafting
    [52188] = 15000,     -- Jeweler's Setting

    -- Inscription
    [62323] = 60000,     -- Deathwing Scale Fragment
    [68047] = 170437,    -- Scavenged Dragon Horn
    [67319] = 328990,    -- Preserved Ogre Eye
    [67348] = 394755,    -- Bleached Jawbone
    [67335] = 445561,    -- Silver Charm Bracelet

    -- Cooking
    [2595] = 2000,       -- Jug of Badlands Bourbon
    [58278] = 3200,      -- Tropical Sunfruit
    [58265] = 4000,      -- Highland Pomegranate

    -- Poisons: no vendor sells the reagents since Cataclysm
    [2928] = false,      -- Dust of Decay
    [2930] = false,      -- Essence of Pain
    [2931] = false,      -- Maiden's Anguish
    [5173] = false,      -- Deathweed
    [8923] = false,      -- Essence of Agony
    [8924] = false,      -- Dust of Deterioration
}

_G.professionMaster:CreateModel("vendor-prices-cata", vendorPrices);
