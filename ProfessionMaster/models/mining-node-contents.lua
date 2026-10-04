--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

Mining node loot tables: secondary drops with approximate drop rates.
Format: [oreItemId] = { {itemId, dropPercent}, ... }
Sorted by drop rate descending. Primary ore (100%) is omitted.

--]]

local miningNodeContents = {

    -- ===== Vanilla =====

    -- Copper Vein
    [2770] = {
        {2835, 46},   -- Rough Stone
        {774, 5},     -- Malachite
        {818, 5},     -- Tigerseye
        {1210, 1},    -- Shadowgem
    },

    -- Tin Vein
    [2771] = {
        {2836, 44},   -- Coarse Stone
        {2775, 4},    -- Silver Ore
        {1206, 4},    -- Moss Agate
        {1210, 3},    -- Shadowgem
        {1529, 2},    -- Jade
        {1705, 2},    -- Lesser Moonstone
    },

    -- Silver Vein
    [2775] = {
        {1206, 5},    -- Moss Agate
        {1705, 3},    -- Lesser Moonstone
        {1210, 3},    -- Shadowgem
    },

    -- Gold Vein
    [2776] = {
        {1529, 5},    -- Jade
        {3864, 4},    -- Citrine
        {1705, 3},    -- Lesser Moonstone
    },

    -- Iron Deposit
    [2772] = {
        {2838, 44},   -- Heavy Stone
        {1529, 3},    -- Jade
        {1705, 3},    -- Lesser Moonstone
        {3864, 2},    -- Citrine
        {7909, 1},    -- Aquamarine
        {7910, 1},    -- Star Ruby
    },

    -- Mithril Deposit
    [3858] = {
        {7912, 39},   -- Solid Stone
        {7911, 4},    -- Truesilver Ore
        {3864, 4},    -- Citrine
        {7910, 3},    -- Star Ruby
        {7909, 2},    -- Aquamarine
    },

    -- Truesilver Deposit
    [7911] = {
        {3864, 5},    -- Citrine
        {7910, 3},    -- Star Ruby
        {7909, 3},    -- Aquamarine
    },

    -- Dark Iron Deposit
    [11370] = {
        {11754, 3},   -- Black Diamond
        {11382, 1},   -- Blood of the Mountain
    },

    -- Thorium Vein
    [10620] = {
        {12365, 42},  -- Dense Stone
        {7910, 4},    -- Star Ruby
        {12363, 3},   -- Arcane Crystal
        {12361, 3},   -- Blue Sapphire
        {12799, 3},   -- Large Opal
        {12800, 1},   -- Azerothian Diamond
        {12364, 1},   -- Huge Emerald
    },

    -- ===== TBC =====

    -- Fel Iron Deposit
    [23424] = {
        {23427, 10},  -- Eternium Ore
        {23077, 3},   -- Blood Garnet
        {21929, 3},   -- Flame Spessarite
        {23079, 3},   -- Deep Peridot
        {23107, 3},   -- Shadow Draenite
        {23112, 3},   -- Golden Draenite
        {23117, 3},   -- Azure Moonstone
    },

    -- Adamantite Deposit
    [23425] = {
        {23427, 12},  -- Eternium Ore
        {23077, 3},   -- Blood Garnet
        {21929, 3},   -- Flame Spessarite
        {23079, 3},   -- Deep Peridot
        {23107, 3},   -- Shadow Draenite
        {23112, 3},   -- Golden Draenite
        {23117, 3},   -- Azure Moonstone
    },

    -- Khorium Vein
    [23426] = {
        {23427, 15},  -- Eternium Ore
        {23077, 4},   -- Blood Garnet
        {21929, 4},   -- Flame Spessarite
        {23079, 4},   -- Deep Peridot
        {23107, 4},   -- Shadow Draenite
        {23112, 4},   -- Golden Draenite
        {23117, 4},   -- Azure Moonstone
    },

    -- ===== Wrath =====

    -- Cobalt Deposit
    [36909] = {
        {37705, 25},  -- Crystallized Earth
        {36917, 3},   -- Bloodstone
        {36918, 3},   -- Sun Crystal
        {36923, 3},   -- Chalcedony
        {36926, 3},   -- Shadow Crystal
        {36929, 3},   -- Huge Citrine
        {36932, 3},   -- Dark Jade
    },

    -- Saronite Deposit
    [36912] = {
        {37705, 22},  -- Crystallized Earth
        {36917, 3},   -- Bloodstone
        {36918, 3},   -- Sun Crystal
        {36923, 3},   -- Chalcedony
        {36926, 3},   -- Shadow Crystal
        {36929, 3},   -- Huge Citrine
        {36932, 3},   -- Dark Jade
    },

    -- Titanium Vein
    [36910] = {
        {37705, 30},  -- Crystallized Earth
        {36917, 4},   -- Bloodstone
        {36918, 4},   -- Sun Crystal
        {36923, 4},   -- Chalcedony
        {36926, 4},   -- Shadow Crystal
        {36929, 4},   -- Huge Citrine
        {36932, 4},   -- Dark Jade
    },

    -- ===== Cata =====

    -- Obsidium Deposit
    [53038] = {
        {52327, 22},  -- Volatile Earth
        {52177, 3},   -- Carnelian
        {52178, 3},   -- Hessonite
        {52179, 3},   -- Alicite
        {52180, 3},   -- Nightstone
        {52181, 3},   -- Jasper
        {52182, 3},   -- Zephyrite
    },

    -- Elementium Vein
    [52185] = {
        {52327, 22},  -- Volatile Earth
        {52177, 3},   -- Carnelian
        {52178, 3},   -- Hessonite
        {52179, 3},   -- Alicite
        {52180, 3},   -- Nightstone
        {52181, 3},   -- Jasper
        {52182, 3},   -- Zephyrite
    },

    -- Pyrite Deposit
    [52183] = {
        {52327, 25},  -- Volatile Earth
        {52177, 4},   -- Carnelian
        {52178, 4},   -- Hessonite
        {52179, 4},   -- Alicite
        {52180, 4},   -- Nightstone
        {52181, 4},   -- Jasper
        {52182, 4},   -- Zephyrite
    },

    -- ===== MoP =====

    -- Ghost Iron Deposit
    [72092] = {
        {76130, 3},   -- Tiger Opal
        {76131, 3},   -- Lapis Lazuli
        {76132, 3},   -- Roguestone
        {76133, 3},   -- Sunstone
        {76134, 3},   -- Alexandrite
        {76135, 3},   -- Pandarian Garnet
    },

    -- Kyparite Deposit
    [72093] = {
        {76130, 3},   -- Tiger Opal
        {76131, 3},   -- Lapis Lazuli
        {76132, 3},   -- Roguestone
        {76133, 3},   -- Sunstone
        {76134, 3},   -- Alexandrite
        {76135, 3},   -- Pandarian Garnet
    },

    -- Trillium Vein (Black)
    [72094] = {
        {76130, 4},   -- Tiger Opal
        {76131, 4},   -- Lapis Lazuli
        {76132, 4},   -- Roguestone
        {76133, 4},   -- Sunstone
        {76134, 4},   -- Alexandrite
        {76135, 4},   -- Pandarian Garnet
    },

    -- Trillium Vein (White)
    [72103] = {
        {76130, 4},   -- Tiger Opal
        {76131, 4},   -- Lapis Lazuli
        {76132, 4},   -- Roguestone
        {76133, 4},   -- Sunstone
        {76134, 4},   -- Alexandrite
        {76135, 4},   -- Pandarian Garnet
    }
};

-- create model
_G.professionMaster:CreateModel("mining-node-contents", miningNodeContents);
