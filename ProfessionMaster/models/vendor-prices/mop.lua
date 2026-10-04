--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- Vendor prices for mop (additions and overrides to vanilla, bcc, wrath and cata, same format)
local vendorPrices = {
    -- Enchanting
    [38682] = 200,       -- Enchanting Vellum

    -- Inscription
    [79740] = 23,        -- Plain Wooden Staff

    -- Engineering
    [90146] = 20000,     -- Tinker's Kit

    -- Jewelcrafting / Engineering
    [83092] = 200000000, -- Orb of Mystery

    -- Cooking
    [4537] = 25,         -- Tel'Abim Banana
    [102539] = 1000,     -- Fresh Strawberries
    [102540] = 1000,     -- Fresh Mangos
    [74854] = 7000,      -- Instant Noodles
    [74832] = 12000,     -- Barley
    [85583] = 12000,     -- Needle Mushrooms
    [74851] = 14000,     -- Rice
    [74660] = 15000,     -- Pandaren Peach
    [74852] = 16000,     -- Yak Milk
    [85584] = 17000,     -- Silkworm Pupa
    [85585] = 27000,     -- Red Beans
    [74659] = 30000,     -- Farm Chicken
    [74845] = 35000,     -- Ginseng
}

_G.professionMaster:CreateModel("vendor-prices-mop", vendorPrices);
