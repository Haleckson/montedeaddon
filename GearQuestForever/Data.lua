local _, GQ = ...

GQ.Data = GQ.Data or {}

-- Curated BiS lists (user-defined order via curatedRank 1 = best).
-- Early Alliance mail melee bands. Item required level gates obtain checks in Equip.lua.

local ALLIANCE = { Alliance = true }
local ALLIANCE_MAIL = { WARRIOR = true, PALADIN = true }
local EARLY_MIN = 1
local EARLY_MAX = 8
local LEVEL1_MAX = 1
local LEVEL2_MIN = 2
local LEVEL2_MAX = 2
local LEVEL3_MIN = 3
local LEVEL3_MAX = 3
local EARLY4_MAX = 4
local LEVEL5_MIN = 5
local LEVEL5_MAX = 10
local LEVEL6_MIN = 6
local LEVEL6_MAX = 12
local LEVEL7_MIN = 7
local LEVEL7_MAX = 12
local LEVEL8_MIN = 8
local LEVEL8_MAX = 12
local LEVEL9_MIN = 9
local LEVEL9_MAX = 14
local LEVEL10_MIN = 10
local LEVEL10_MAX = 16
local SPEC_HOLY = { holy = true }
local SPEC_PROTECTION = { protection = true }
local SPEC_RETRIBUTION = { retribution = true }
local SPEC_SHADOW = { shadow = true }
local MAIL_MELEE = ALLIANCE_MAIL
local SPEC_MELEE = { retribution = true, protection = true }
local SPEC_RET = { retribution = true }
local SPEC_PROT = { protection = true }
local HORDE = { Horde = true }
local SHAMAN_CLASS = { SHAMAN = true }
local SPEC_ELEMENTAL = { elemental = true }
local SPEC_ENHANCEMENT = { enhancement = true }
local SPEC_ENHANCEMENT_TANK = { enhancement_tank = true }
local SPEC_ENHANCEMENT_ALL = { enhancement = true, enhancement_tank = true }
local SPEC_RESTORATION = { restoration = true }
local MAGE_CLASS = { MAGE = true }
local SPEC_MAGE_ALL = { frost = true, fire = true, arcane = true }
local SPEC_FROST = { frost = true }
local SPEC_FIRE = { fire = true }
local SPEC_ARCANE = { arcane = true }
local WARLOCK_CLASS = { WARLOCK = true }
local SPEC_WARLOCK_ALL = { affliction = true, demonology = true, destruction = true }
local SPEC_AFF_DEMO = { affliction = true, demonology = true }
local SPEC_DESTRUCTION = { destruction = true }
local DRUID_CLASS = { DRUID = true }
local SPEC_DRUID_ALL = { bear = true, feral = true, balance = true, restoration = true }
local SPEC_BEAR_BALANCE = { bear = true, balance = true }
local SPEC_BALANCE = { balance = true }
local SPEC_DRUID_RESTO = { restoration = true }
local SPEC_BAL_RESTO = { balance = true, restoration = true }
local ROGUE_CLASS = { ROGUE = true }
local PRIEST_CLASS = { PRIEST = true }
local SPEC_DISC = { discipline = true }
local SPEC_HOLY_DISC = { holy = true, discipline = true }
local HUNTER_CLASS = { HUNTER = true }
local SPEC_HUNTER_ALL = { beast_mastery = true, marksmanship = true, survival = true }
local PALADIN_CLASS = { PALADIN = true }
local WARRIOR_CLASS = { WARRIOR = true }
local SPEC_ARMS_FURY = { arms = true, fury = true }

-- Second ring-slot milestone: level 10 band adds more Finger upgrades.
GQ.Data.RING_SLOT_2_MILESTONE_LEVEL = 10

-- Crafted output names for trainer matching when GetItemInfo is not cached yet.
local PROFESSION_ITEM_NAMES = {
    [10421] = "Rough Copper Vest",
    [2853] = "Copper Bracers",
    [3469] = "Copper Chain Boots",
    [2852] = "Copper Chain Pants",
    [3471] = "Copper Chain Vest",
    [2851] = "Copper Chain Belt",
    [2580] = "Reinforced Linen Cape",
    [2570] = "Linen Cloak",
    [3472] = "Runed Copper Gauntlets",
    [2310] = "Embossed Leather Cloak",
    [3473] = "Runed Copper Pants",
    [3474] = "Gemmed Copper Gauntlets",
    [3488] = "Copper Battle Axe",
    [21931] = "Woven Copper Ring",
    [253887] = "Novice Ardent's Sash",
    [253885] = "Novice Arcanist's Sash",
    [250482] = "Glowing Copper Boots",
    [250621] = "Strange Copper Boots",
    [250620] = "Gemmed Copper Boots",
    [254001] = "Gilded Slippers",
    [254003] = "Frothing Slippers",
    [254005] = "Fiery Slippers",
    [254009] = "Golden Slippers",
    [254007] = "Black Slippers",
}

local MIDSUMMER_CROWN =
    "During the Midsummer Fire Festival, complete A Thief's Reward in a capital city after stealing the opposing faction's bonfire flames (or turn in if you finished in a previous year). Usable from level 1."

GQ.Data.entries = {
    -- Head — all classes / factions (seasonal)
    {
        id = "early4_all_head_crown_fire_festival",
        itemId = 23323,
        slot = "Head",
        minLevel = EARLY_MIN,
        maxLevel = EARLY_MAX,
        curatedRank = 1,
        sourceType = "seasonal_quest",
        instructions = MIDSUMMER_CROWN,
        zone = "Capital Cities",
        questName = "A Thief's Reward",
    },

    -- Level 1 band — Alliance mail melee (warrior / paladin)
    {
        id = "early1_back_linen_cloak",
        itemId = 2570,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Linen Cloak from a Tailoring trainer and craft at a loom (Tailoring 1). Requires Linen Cloth from humanoid drops or vendors.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_back_flimsy_chain_cloak",
        itemId = 2652,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Cloak is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_back_loose_chain_cloak",
        itemId = 2644,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Cloak (req 1) is a grey world drop from low-level humanoids in Alliance starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early1_chest_tarnished_chain_vest",
        itemId = 2379,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Vest from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_chest_flimsy_chain_vest",
        itemId = 2656,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Vest is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_wrist_slightly_rusted_bracers",
        itemId = 24131,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Replenishing the Healing Crystals on Azuremyst Isle and choose Slightly Rusted Bracers over the other rewards.",
        zone = "Azuremyst Isle",
        npc = "Proenitus",
        questName = "Replenishing the Healing Crystals",
    },
    {
        id = "early1_wrist_flimsy_chain_bracers",
        itemId = 2651,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Bracers are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_mainhand_bastard_sword",
        itemId = 1194,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Bastard Sword from Janos Hammerknuckle in Northshire Abbey. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early1_mainhand_broad_axe",
        itemId = 2479,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Broad Axe from Janos Hammerknuckle in Northshire Abbey. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early1_mainhand_scratched_claymore",
        itemId = 2128,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Scratched Claymore is a grey two-handed sword world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_offhand_cracked_buckler",
        itemId = 2212,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cracked Buckler is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_offhand_large_round_shield",
        itemId = 2129,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Large Round Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_offhand_small_shield",
        itemId = 2133,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Small Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early1_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_feet_flimsy_chain_boots",
        itemId = 2650,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Boots are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_legs_flimsy_chain_pants",
        itemId = 2654,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Pants are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_waist_flimsy_chain_belt",
        itemId = 2649,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Belt is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_waist_rustic_belt",
        itemId = 2172,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete A New Threat in Coldridge Valley and choose Rustic Belt over the other quest rewards.",
        zone = "Dun Morogh",
        questName = "A New Threat",
    },
    {
        id = "early1_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Level 2 band — Alliance mail melee (warrior / paladin)
    {
        id = "early2_back_linen_cloak",
        itemId = 2570,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Linen Cloak from a Tailoring trainer and craft at a loom (Tailoring 1). Requires Linen Cloth from humanoid drops or vendors.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_back_goat_fur_cloak",
        itemId = 2905,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Goat Fur Cloak drops from goats and other beasts in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early2_back_flimsy_chain_cloak",
        itemId = 2652,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Cloak is a grey world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2). Best mail chest at this level.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early2_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early2_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early2_wrist_copper_bracers",
        itemId = 2853,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Bracers from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early2_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_wrist_slightly_rusted_bracers",
        itemId = 24131,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Replenishing the Healing Crystals on Azuremyst Isle and choose Slightly Rusted Bracers over the other rewards.",
        zone = "Azuremyst Isle",
        npc = "Proenitus",
        questName = "Replenishing the Healing Crystals",
    },
    {
        id = "early2_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward. Train Two-Handed Maces from a weapon master first.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },
    {
        id = "early2_mainhand_practice_sword",
        itemId = 8177,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Practice Sword (req 2) is a grey two-handed sword world drop from low-level humanoids and beasts in starter zones. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_mainhand_scratched_claymore",
        itemId = 2128,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Scratched Claymore is a grey two-handed sword world drop from low-level humanoids in starter zones. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_worn_large_shield",
        itemId = 2213,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Worn Large Shield (req 2) is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_cracked_buckler",
        itemId = 2212,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Cracked Buckler is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_large_round_shield",
        itemId = 2129,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Large Round Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early2_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_feet_flimsy_chain_boots",
        itemId = 2650,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Boots are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_legs_beaten_chain_leggings",
        itemId = 24423,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Spare Parts in Ammen Vale: collect 4 Emitter Spare Parts from Nestlewood Thicket and Hills, then choose Beaten Chain Leggings from Technician Zhanaa.",
        zone = "Azuremyst Isle",
        npc = "Technician Zhanaa",
        questName = "Spare Parts",
    },
    {
        id = "early2_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_legs_flimsy_chain_pants",
        itemId = 2654,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Pants are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_waist_rustic_belt",
        itemId = 2172,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete A New Threat in Coldridge Valley and choose Rustic Belt over the other quest rewards.",
        zone = "Dun Morogh",
        questName = "A New Threat",
    },
    {
        id = "early2_waist_flimsy_chain_belt",
        itemId = 2649,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Belt is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Level 3 band — Alliance mail melee (warrior / paladin)
    {
        id = "early3_back_journeymans_cloak",
        itemId = 4662,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Journeyman's Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_back_warriors_cloak",
        itemId = 4658,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_back_burnt_cloak",
        itemId = 4665,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Burnt Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2). Best mail chest at this level.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early3_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early3_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early3_wrist_chargers_bindings",
        itemId = 15474,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Charger's Bindings (req 3) are a green mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_wrist_copper_bracers",
        itemId = 2853,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Bracers from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early3_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_mainhand_beatstick",
        itemId = 3190,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Beatstick (req 3) is a green two-handed mace world drop from low-level humanoids in starter zones. Train Two-Handed Maces from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_mainhand_large_axe",
        itemId = 2491,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Large Axe from Janos Hammerknuckle in Northshire or Andrew Krighton in Goldshire. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early3_mainhand_wood_chopper",
        itemId = 3189,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Wood Chopper (req 3) is a green two-handed axe world drop from low-level humanoids in starter zones. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_offhand_small_targe",
        itemId = 17186,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Small Targe from Andrew Krighton in Goldshire, Quartermaster Hudson in Northshire, or another shield vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early3_offhand_burnt_buckler",
        itemId = 15895,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Burnt Buckler (req 3) is a green shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_offhand_chargers_shield",
        itemId = 15478,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Charger's Shield (req 3) is a green mail shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_feet_bloody_chain_boots",
        itemId = 18612,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Bloody Chain Boots (req 3) drop from Fury Shelda, a rare spawn in southern Teldrassil.",
        zone = "Teldrassil",
        npc = "Fury Shelda",
    },
    {
        id = "early3_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early3_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_legs_beaten_chain_leggings",
        itemId = 24423,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Spare Parts in Ammen Vale: collect 4 Emitter Spare Parts from Nestlewood Thicket and Hills, then choose Beaten Chain Leggings from Technician Zhanaa.",
        zone = "Azuremyst Isle",
        npc = "Technician Zhanaa",
        questName = "Spare Parts",
    },
    {
        id = "early3_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_waist_warriors_girdle",
        itemId = 4659,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Girdle (req 3) is a green mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_waist_loose_chain_belt",
        itemId = 2635,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Belt (req 3) is an uncommon mail world drop from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Levels 2–4 band — Alliance mail melee
    {
        id = "early4_back_infantry_cloak",
        itemId = 6508,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Infantry Cloak (8 armor, req 4) is a green world drop or vendor find in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_back_pioneer_cloak",
        itemId = 6520,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Pioneer Cloak (8 armor, req 4) is a green world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_back_battle_chain_cloak",
        itemId = 4668,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Cloak (8 armor, req 4) drops from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest
    {
        id = "early4_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (requires level 2). Best early mail chest.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early4_chest_tarnished_vest",
        itemId = 2379,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Vest from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },

    -- Wrist
    {
        id = "early4_wrist_battle_chain_bracers",
        itemId = 3280,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Bracers (req 4) are green mail world drops in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_wrist_warriors_bracers",
        itemId = 3214,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Bracers (req 4) are green mail world drops in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_wrist_graystone_bracers",
        itemId = 6061,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Timberling Sprouts in Teldrassil: collect 12 Timberling Sprouts for Denalan at Lake Al'Ameth and choose Graystone Bracers over Gardening Gloves.",
        zone = "Teldrassil",
        npc = "Denalan",
        questName = "Timberling Sprouts",
    },

    -- Main Hand (two-hand)
    {
        id = "early4_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },
    {
        id = "early4_mainhand_vile_fin_battle_axe",
        itemId = 3325,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Vile Fin Battle Axe (req 4) drops from murlocs in starter zones. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_mainhand_rusted_claymore",
        itemId = 2497,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Rusted Claymore from Janos Hammerknuckle in Northshire or Andrew Krighton in Goldshire. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },

    -- Off Hand (shield)
    {
        id = "early4_offhand_pioneer_buckler",
        itemId = 7109,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Pioneer Buckler (req 4) is a green shield world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_offhand_primal_buckler",
        itemId = 15006,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Primal Buckler (req 4) is a green shield world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_offhand_warriors_buckler",
        itemId = 3648,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Warrior's Buckler (req 4) from Godric Rothgar in Northshire or Andrew Krighton in Goldshire.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },

    -- Feet
    {
        id = "early4_feet_copper_chain_boots",
        itemId = 3469,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Boots and craft at an anvil (requires level 4). Best mail boots at this band.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_feet_loose_chain_boots",
        itemId = 2642,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Boots (req 4) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_feet_bloody_chain_boots",
        itemId = 18612,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Bloody Chain Boots (req 3) drop from Fury Shelda, a rare spawn in southern Teldrassil.",
        zone = "Teldrassil",
        npc = "Fury Shelda",
    },

    -- Legs
    {
        id = "early4_legs_barkmail_leggings",
        itemId = 9599,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete The Relics of Wakening in Teldrassil: retrieve the four relics from Ban'ethil Barrow Den for Athridas Bearmantle in Dolanaar, then choose Barkmail Leggings over the Gritroot Staff.",
        zone = "Teldrassil",
        npc = "Athridas Bearmantle",
        questName = "The Relics of Wakening",
    },
    {
        id = "early4_legs_copper_chain_pants",
        itemId = 2852,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Pants and craft at an anvil (requires level 4).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Waist
    {
        id = "early4_waist_chargers_belt",
        itemId = 15472,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Charger's Belt (req 4) is a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_waist_warriors_girdle",
        itemId = 4659,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Girdle (req 3) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_waist_loose_chain_belt",
        itemId = 2635,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Belt (req 3) is an uncommon mail world drop in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Hands
    {
        id = "early4_hands_moss_covered_gauntlets",
        itemId = 5589,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Oakenscowl in Teldrassil: kill Oakenscowl and bring the Gargantuan Tumor to Denalan at Lake Al'Ameth, then choose Moss-covered Gauntlets over the Dirtwood Belt.",
        zone = "Teldrassil",
        npc = "Denalan",
        questName = "Oakenscowl",
    },
    {
        id = "early4_hands_warriors_gloves",
        itemId = 2968,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Gloves (req 4) are green mail world drops in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Level 5 band — Head unchanged (early4_all_head_* above). No Shoulder entries (no armor value at low levels).

    -- Back — Alliance, all classes (level 5)
    {
        id = "early5_back_worn_hide_cloak",
        itemId = 1421,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Worn Hide Cloak (9 armor, req 5) is a green world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_back_grizzly_cape",
        itemId = 15299,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Grizzly Cape (9 armor, req 5) is a green world drop in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_back_goat_fur_cloak",
        itemId = 2905,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Goat Fur Cloak (9 armor) drops from goats and other beasts in Dun Morogh and similar zones.",
        zone = "Dun Morogh",
    },

    -- Chest — Alliance mail melee (level 5)
    {
        id = "early5_chest_copper_chain_vest",
        itemId = 3471,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Vest and craft at an anvil (requires level 5). Best mail chest at this level (+1 Strength).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early5_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in Alliance starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_chest_light_mail_armor",
        itemId = 2392,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Armor (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },

    -- Wrist — mail melee, both factions (level 5)
    {
        id = "early5_wrist_light_chain_bracers",
        itemId = 2402,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Bracers (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early5_wrist_light_mail_bracers",
        itemId = 2396,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Bracers (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early5_wrist_infantry_bracers",
        itemId = 6507,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Infantry Bracers (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 5)
    {
        id = "early5_mainhand_training_sword",
        itemId = 8178,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Training Sword (req 5) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_mainhand_severing_axe",
        itemId = 4562,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.2,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Severing Axe (req 5) is a green two-handed axe world drop. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },

    -- Off Hand — mail melee, both factions (level 5)
    {
        id = "early5_offhand_dull_heater_shield",
        itemId = 1201,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Dull Heater Shield (req 5) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_offhand_worn_heater_shield",
        itemId = 2376,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Worn Heater Shield (req 5) from Godric Rothgar in Northshire or Andrew Krighton in Goldshire.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early5_offhand_small_targe",
        itemId = 1167,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Small Targe (req 5) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 5)
    {
        id = "early5_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_feet_light_mail_boots",
        itemId = 2395,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_feet_chargers_boots",
        itemId = 15473,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Charger's Boots (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 5)
    {
        id = "early5_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early5_legs_warriors_pants",
        itemId = 2966,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Pants (req 5) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_legs_light_mail_leggings",
        itemId = 2394,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Leggings (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },

    -- Waist — mail melee, both factions (level 5)
    {
        id = "early5_waist_light_chain_belt",
        itemId = 2399,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Belt (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_waist_light_mail_belt",
        itemId = 2393,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Belt (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_waist_battle_chain_girdle",
        itemId = 4669,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Girdle (req 5) is a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 5)
    {
        id = "early5_hands_light_mail_gloves",
        itemId = 2397,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Mail Gloves (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_hands_chargers_handwraps",
        itemId = 15476,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Charger's Handwraps (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_hands_light_chain_gloves",
        itemId = 2403,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Chain Gloves (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Level 6 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 6)
    {
        id = "early6_back_cadet_cloak",
        itemId = 9761,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Cadet Cloak (req 6) from a cloth vendor in a starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_back_rain_spotted_cape",
        itemId = 5591,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Rain-spotted Cape is a green world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_back_simple_cape",
        itemId = 9745,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Simple Cape (req 6) from a cloth vendor in a starter city.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 6)
    {
        id = "early6_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_chest_chargers_armor",
        itemId = 15479,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 8.8,
        suffixRange = "+1-2 Strength",
        instructions = "Charger's Armor (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_chest_copper_chain_vest",
        itemId = 3471,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Vest from a blacksmith trainer and craft at an anvil (requires level 5). +1 Strength.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },

    -- Wrist — mail melee, both factions (level 6)
    {
        id = "early6_wrist_war_torn_bands",
        itemId = 15482,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "War-torn Bands (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_wrist_light_chain_bracers",
        itemId = 2402,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Chain Bracers (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_wrist_light_mail_bracers",
        itemId = 2396,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Bracers (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 6)
    {
        id = "early6_mainhand_coldridge_hammer",
        itemId = 3103,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Protecting the Herd in Dun Morogh and choose Coldridge Hammer over the other rewards. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Rudra Amberstill",
        questName = "Protecting the Herd",
    },
    {
        id = "early6_mainhand_training_sword",
        itemId = 8178,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Training Sword (req 5) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_mainhand_severing_axe",
        itemId = 4562,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.2,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Severing Axe (req 5) is a green two-handed axe world drop. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },

    -- Off Hand — mail melee, both factions (level 6)
    {
        id = "early6_offhand_infantry_shield",
        itemId = 7108,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Infantry Shield (req 6) is a green mail shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_offhand_thuggish_shield",
        itemId = 6203,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Thuggish Shield (req 6) is a green shield world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_offhand_tribal_buckler",
        itemId = 3649,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tribal Buckler (req 6) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 6)
    {
        id = "early6_feet_infantry_boots",
        itemId = 6506,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Infantry Boots (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_feet_light_mail_boots",
        itemId = 2395,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 6)
    {
        id = "early6_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength, 113 armor) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early6_legs_chargers_pants",
        itemId = 15477,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 10.0,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Charger's Pants of Strength (req 6) are a green mail world drop in starter zones (101 armor, +1–2 Strength). Hunt the of Strength roll.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_legs_warriors_pants",
        itemId = 2966,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Warrior's Pants (req 5) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 6)
    {
        id = "early6_waist_copper_chain_belt",
        itemId = 2851,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Belt and craft at an anvil (requires level 6), or buy from a vendor if available.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early6_waist_royal_frostmane_girdle",
        itemId = 2546,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Royal Frostmane Girdle (req 6) drops from Frostmane trolls in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early6_waist_shackled_girdle",
        itemId = 5592,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Shackled Girdle is a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 6)
    {
        id = "early6_hands_battle_chain_gloves",
        itemId = 3281,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Gloves (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_hands_infantry_gauntlets",
        itemId = 6510,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Infantry Gauntlets (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_hands_worn_mail_gloves",
        itemId = 1734,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Worn Mail Gloves from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Level 7 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 7)
    {
        id = "early7_back_reinforced_linen_cape",
        itemId = 2580,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Reinforced Linen Cape from a Tailoring trainer and craft at a loom (Tailoring 60). +1 Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early7_back_veteran_cloak",
        itemId = 4677,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Cloak (req 7, 11 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_back_ceremonial_cloak",
        itemId = 4692,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Ceremonial Cloak (req 7, 11 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 7)
    {
        id = "early7_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_chest_explorers_vest",
        itemId = 7229,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete the Bashal'Aran quest chain in Darkshore (final turn-in to Asterion) and choose Explorer's Vest (+2 Stamina, +1 Intellect) over the other rewards.",
        zone = "Darkshore",
        npc = "Asterion",
        questName = "Bashal'Aran",
    },
    {
        id = "early7_chest_ravager_chitin_tunic",
        itemId = 24107,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Beasts of the Apocalypse! on Azuremyst Isle (Draenei starter zone) and choose Ravager Chitin Tunic (+1 Strength) over the other rewards.",
        zone = "Azuremyst Isle",
        questName = "Beasts of the Apocalypse!",
    },

    -- Wrist — mail melee, both factions (level 7)
    {
        id = "early7_wrist_ironwrought_bracers",
        itemId = 6177,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Tundra MacGrann's Stolen Stash in Dun Morogh (req 7) and choose Ironwrought Bracers over Wooly Mittens.",
        zone = "Dun Morogh",
        npc = "Tundra MacGrann",
        questName = "Tundra MacGrann's Stolen Stash",
    },
    {
        id = "early7_wrist_cadet_bracers",
        itemId = 9760,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Cadet Bracers (req 7) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_wrist_brackwater_bracers",
        itemId = 3303,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Brackwater Bracers (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 7)
    {
        id = "early7_mainhand_icepane_warhammer",
        itemId = 2254,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Farm Icepane Warhammer (+2 Strength) from Hammerspine in the Gol'Bolar Quarry mine in Dun Morogh. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Hammerspine",
    },
    {
        id = "early7_mainhand_short_bastard_sword",
        itemId = 3192,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Short Bastard Sword (req 7) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_mainhand_coldridge_hammer",
        itemId = 3103,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Protecting the Herd in Dun Morogh and choose Coldridge Hammer over the other rewards. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Rudra Amberstill",
        questName = "Protecting the Herd",
    },

    -- Off Hand — mail melee, both factions (level 7)
    {
        id = "early7_offhand_gypsy_buckler",
        itemId = 9753,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Gypsy Buckler (req 7) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_offhand_war_torn_shield",
        itemId = 15486,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "War-torn Shield (req 7) is a green shield world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_offhand_infantry_shield",
        itemId = 7108,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Infantry Shield (req 6) is a green mail shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 7)
    {
        id = "early7_feet_battle_chain_boots",
        itemId = 3279,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Boots (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_feet_infantry_boots",
        itemId = 6506,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Infantry Boots (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 7)
    {
        id = "early7_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early7_legs_infantry_leggings",
        itemId = 6337,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.7,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Infantry Leggings (req 7) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_legs_battle_chain_pants",
        itemId = 3282,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Pants (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 7)
    {
        id = "early7_waist_cadet_belt",
        itemId = 9758,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Belt (req 7) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_waist_worn_mail_belt",
        itemId = 1730,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Worn Mail Belt (req 7) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_waist_copper_chain_belt",
        itemId = 2851,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Belt and craft at an anvil (requires level 6), or buy from a vendor if available.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },

    -- Hands — mail melee, both factions (level 7)
    {
        id = "early7_hands_runed_copper_gauntlets",
        itemId = 3472,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 40). Random +Agility or +Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early7_hands_war_torn_handgrips",
        itemId = 15484,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-torn Handgrips (req 7) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_hands_battle_chain_gloves",
        itemId = 3281,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Gloves (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 8 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 8)
    {
        id = "early8_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early8_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 8)
    {
        id = "early8_chest_infantry_tunic",
        itemId = 6336,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Infantry Tunic of Strength (req 8) is a green mail world drop (+3-4 Strength, ~9.8% of rolls).",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_chest_ironheart_chain",
        itemId = 3166,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan — collect 4 Miners' Gear from Silver Stream Mine and return to Mountaineer Stormpike. Choose Ironheart Chain over Ironplate Buckler and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early8_chest_battle_chain_tunic",
        itemId = 3283,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Tunic (req 8) is a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Wrist — mail melee, both factions (level 8)
    {
        id = "early8_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_wrist_ironwrought_bracers",
        itemId = 6177,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Tundra MacGrann's Stolen Stash in Dun Morogh (req 7) and choose Ironwrought Bracers over Wooly Mittens.",
        zone = "Dun Morogh",
        npc = "Tundra MacGrann",
        questName = "Tundra MacGrann's Stolen Stash",
    },
    {
        id = "early8_wrist_cadet_bracers",
        itemId = 9760,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Bracers (req 7) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 8)
    {
        id = "early8_mainhand_spiked_club",
        itemId = 4564,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Spiked Club of Strength (req 8) is a green two-handed mace world drop (+3-4 Strength, ~5.9% of rolls). Train Two-Handed Maces first.",
        zone = "Westfall",
    },
    {
        id = "early8_mainhand_copper_battle_axe",
        itemId = 3488,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Battle Axe from a Blacksmithing trainer and craft at an anvil (Blacksmithing 35). Train Two-Handed Axes first.",
        zone = "Stormwind City",
    },
    {
        id = "early8_mainhand_icepane_warhammer",
        itemId = 2254,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm Icepane Warhammer (+2 Strength) from Hammerspine in the Gol'Bolar Quarry mine in Dun Morogh. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Hammerspine",
    },

    -- Off Hand — mail melee, both factions (level 8)
    {
        id = "early8_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_offhand_grizzly_buckler",
        itemId = 15298,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Grizzly Buckler (req 8) is a green shield world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_offhand_gypsy_buckler",
        itemId = 9753,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Gypsy Buckler (req 7) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 8)
    {
        id = "early8_feet_cadet_boots",
        itemId = 9759,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Boots (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_feet_war_torn_greaves",
        itemId = 15481,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-Torn Greaves (req 8) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_feet_battle_chain_boots",
        itemId = 3279,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Boots (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 8)
    {
        id = "early8_legs_runed_copper_pants",
        itemId = 3473,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Pants from a Blacksmithing trainer and craft at an anvil (Blacksmithing 45). +2 Strength, +2 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early8_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early8_legs_infantry_leggings",
        itemId = 6337,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.7,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Infantry Leggings (req 7) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 8)
    {
        id = "early8_waist_belt_of_peoples_militia",
        itemId = 1154,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Patrolling Westfall on Sentinel Hill and choose Belt of the People's Militia over Bracers of the People's Militia.",
        zone = "Westfall",
        npc = "Captain Danuvin",
        questName = "Patrolling Westfall",
    },
    {
        id = "early8_waist_war_torn_girdle",
        itemId = 15480,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-Torn Girdle (req 8) is a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_waist_cadet_belt",
        itemId = 9758,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Belt (req 7) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 8)
    {
        id = "early8_hands_cadet_gauntlets",
        itemId = 9762,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Gauntlets (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_hands_runed_copper_gauntlets",
        itemId = 3472,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 40). Random +Agility or +Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early8_hands_war_torn_handgrips",
        itemId = 15484,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "War-torn Handgrips (req 7) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 9 band — Head unchanged (early4_all_head_*). Finger and Shoulder unlock at 9.

    -- Shoulder — Alliance mail melee (level 9)
    {
        id = "early9_shoulder_durable_chain_shoulders",
        itemId = 6189,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Durable Chain Shoulders over Kimbra Boots. Minor Channeling Ring is a bonus reward on the same turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early9_shoulder_veteran_pauldrons",
        itemId = 2977,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Pauldrons (req 10) are a common mail world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_shoulder_talbar_mantle",
        itemId = 10657,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain in the Barrens (starts with Falla Sagewind) and deliver the Nightmare Shard to Mathrengyl Bearwalker in Darnassus. Choose Talbar Mantle over Quagmire Galoshes.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },

    -- Back — Alliance, all classes (level 9; unchanged from level 8)
    {
        id = "early9_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early9_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 9)
    {
        id = "early9_chest_infantry_tunic",
        itemId = 6336,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Infantry Tunic of Strength (req 8) is a green mail world drop (+3-4 Strength, ~9.8% of rolls).",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_chest_wax_polished_armor",
        itemId = 6195,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Farm Wax-Polished Armor (+2 Strength, +3 Stamina) from Grizlak in the Silver Stream Mine in Loch Modan (~40% drop).",
        zone = "Loch Modan",
        npc = "Grizlak",
    },
    {
        id = "early9_chest_ironheart_chain",
        itemId = 3166,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan — collect 4 Miners' Gear from Silver Stream Mine and return to Mountaineer Stormpike. Choose Ironheart Chain over Ironplate Buckler and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },

    -- Wrist — Alliance mail melee (level 9)
    {
        id = "early9_wrist_ridgeback_bracers",
        itemId = 15403,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Ridgeback Bracers over Timberland Armguards or Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_wrist_timberland_armguards",
        itemId = 5315,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Timberland Armguards over Ridgeback Bracers or Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — Alliance mail melee (level 9)
    {
        id = "early9_mainhand_edge_of_peoples_militia",
        itemId = 1566,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Finish The People's Militia quest chain in Westfall (three parts from Gryan Stoutmantle at Sentinel Hill) and choose Edge of the People's Militia (+5 Stamina) over the other weapons. Train Two-Handed Swords first.",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The People's Militia",
    },
    {
        id = "early9_mainhand_spiked_club",
        itemId = 4564,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Spiked Club of Strength (req 8) is a green two-handed mace world drop (+3-4 Strength, ~5.9% of rolls). Train Two-Handed Maces first.",
        zone = "Westfall",
    },
    {
        id = "early9_mainhand_copper_battle_axe",
        itemId = 3488,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Battle Axe from a Blacksmithing trainer and craft at an anvil (Blacksmithing 35). Train Two-Handed Axes first.",
        zone = "Stormwind City",
    },

    -- Off Hand — Alliance mail melee (level 9)
    {
        id = "early9_offhand_peacekeepers_buckler",
        itemId = 27400,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Deathclaw on Bloodmyst Isle — kill Deathclaw and turn in his paw for Peacekeeper's Buckler (+1 Strength, +2 Stamina).",
        zone = "Bloodmyst Isle",
        questName = "WANTED: Deathclaw",
    },
    {
        id = "early9_offhand_ironplate_buckler",
        itemId = 3160,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_PROT,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan and choose Ironplate Buckler over Ironheart Chain and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early9_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Finger — Alliance mail melee (level 9)
    {
        id = "early9_finger_woven_copper_ring",
        itemId = 21931,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Jewelcrafting",
        instructions = "Learn Woven Copper Ring from a Jewelcrafting trainer and craft at a workbench (Jewelcrafting 30).",
        zone = "Stormwind City",
    },
    {
        id = "early9_finger_ring_of_fortitude",
        itemId = 2237,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Ring of Fortitude (req 8, +4 Stamina) is a green world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_finger_minor_channeling_ring",
        itemId = 1449,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan — kill Chok'sul and turn in his head to Magistrate Bluntnose in Thelsamar. Minor Channeling Ring (+2 Intellect) is a bonus reward in addition to your shoulder or boot choice.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },

    -- Feet — Alliance mail melee (level 9)
    {
        id = "early9_feet_padded_lamellar_boots",
        itemId = 5320,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet (The Barrens) — recover the Shipment of Boots and Telescopic Lens from the Southsea pirates and choose Padded Lamellar Boots (+2 Strength, +2 Stamina) over Wayfaring Gloves.",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early9_feet_kimbra_boots",
        itemId = 6191,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Kimbra Boots over Durable Chain Shoulders. Minor Channeling Ring is a bonus reward on the same turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early9_feet_veteran_boots",
        itemId = 2979,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Boots (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 9)
    {
        id = "early9_legs_war_torn_pants",
        itemId = 15485,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "War-Torn Pants (req 9) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_legs_cadet_leggings",
        itemId = 9763,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Leggings (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_legs_runed_copper_pants",
        itemId = 3473,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Pants from a Blacksmithing trainer and craft at an anvil (Blacksmithing 45). +2 Strength, +2 Stamina.",
        zone = "Stormwind City",
    },

    -- Waist — Alliance mail melee (level 9)
    {
        id = "early9_waist_breakwater_girdle",
        itemId = 15404,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Breakwater Girdle over Ridgeback Bracers or Timberland Armguards.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_waist_veteran_girdle",
        itemId = 4678,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Girdle (req 9) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_waist_belt_of_peoples_militia",
        itemId = 1154,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Patrolling Westfall on Sentinel Hill and choose Belt of the People's Militia over Bracers of the People's Militia.",
        zone = "Westfall",
        npc = "Captain Danuvin",
        questName = "Patrolling Westfall",
    },

    -- Hands — Alliance mail melee (level 9)
    {
        id = "early9_hands_brackwater_gauntlets",
        itemId = 3304,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Brackwater Gauntlets (req 9) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_hands_wayfaring_gloves",
        itemId = 5337,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet and choose Wayfaring Gloves over Padded Lamellar Boots.",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early9_hands_cadet_gauntlets",
        itemId = 9762,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Gauntlets (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 10 band — Alliance Retribution paladin (mail melee). Head unchanged (early4_all_head_*).

    -- Shoulder — Alliance Ret (level 10)
    {
        id = "early10_shoulder_talbar_mantle",
        itemId = 10657,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain in the Barrens (starts with Falla Sagewind) and deliver the Nightmare Shard to Mathrengyl Bearwalker in Darnassus. Choose Talbar Mantle over Quagmire Galoshes.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },
    {
        id = "early10_shoulder_durable_chain_shoulders",
        itemId = 6189,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Durable Chain Shoulders over Kimbra Boots.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early10_shoulder_veteran_pauldrons",
        itemId = 2977,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Pauldrons (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Back — Alliance, all classes (level 10; unchanged from level 9)
    {
        id = "early10_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early10_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance Ret (level 10)
    {
        id = "early10_chest_cadet_vest",
        itemId = 9765,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Vest (req 10) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_chest_wax_polished_armor",
        itemId = 6195,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Farm Wax-Polished Armor (+2 Strength, +3 Stamina) from Grizlak in the Silver Stream Mine in Loch Modan (~40% drop).",
        zone = "Loch Modan",
        npc = "Grizlak",
    },
    {
        id = "early10_chest_slarkskin",
        itemId = 6180,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm Slarkskin (+3 Agility, +2 Stamina) from Slark, a rare murloc patrolling the Longshore coast in Westfall.",
        zone = "Westfall",
        npc = "Slark",
    },

    -- Wrist — Alliance Ret (level 10)
    {
        id = "early10_wrist_bloodspattered_wristbands",
        itemId = 15495,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.3,
        suffixRange = "+1-2 Strength",
        instructions = "Bloodspattered Wristbands (req 10) are a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },
    {
        id = "early10_wrist_soldiers_wristguards",
        itemId = 6550,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.3,
        suffixRange = "+1-2 Strength",
        instructions = "Soldier's Wristguards (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — Alliance Ret (level 10)
    {
        id = "early10_mainhand_edge_of_peoples_militia",
        itemId = 1566,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Finish The People's Militia quest chain in Westfall and choose Edge of the People's Militia (+5 Stamina). Train Two-Handed Swords first.",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The People's Militia",
    },
    {
        id = "early10_mainhand_birchwood_maul",
        itemId = 4570,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Birchwood Maul (req 10) is a green two-handed mace world drop. Train Two-Handed Maces first.",
        zone = "Loch Modan",
    },
    {
        id = "early10_mainhand_burrowing_shovel",
        itemId = 6205,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm the Burrowing Shovel (+4 Agility) from Master Digger, a rare kobold in the deepest part of Jangolode Mine in Westfall. Train Two-Handed Maces first.",
        zone = "Westfall",
        npc = "Master Digger",
    },

    -- Off Hand — unchanged from level 9 (level 10)
    {
        id = "early10_offhand_peacekeepers_buckler",
        itemId = 27400,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Deathclaw on Bloodmyst Isle — kill Deathclaw and turn in his paw for Peacekeeper's Buckler (+1 Strength, +2 Stamina).",
        zone = "Bloodmyst Isle",
        questName = "WANTED: Deathclaw",
    },
    {
        id = "early10_offhand_ironplate_buckler",
        itemId = 3160,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_PROT,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan and choose Ironplate Buckler over Ironheart Chain and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early10_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Finger — Alliance Ret (level 10)
    {
        id = "early10_finger_the_1_ring",
        itemId = 8350,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Fish up The 1 Ring from low-level fishing pools (Stormwind canals, Elwynn/Loch Modan waters, etc.) — extremely rare; check the Auction House if you prefer.",
        zone = "Stormwind City",
    },
    {
        id = "early10_finger_minor_channeling_ring",
        itemId = 1449,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan — Minor Channeling Ring (+2 Intellect) is a bonus reward on the turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early10_finger_woven_copper_ring",
        itemId = 21931,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Jewelcrafting",
        instructions = "Learn Woven Copper Ring from a Jewelcrafting trainer and craft at a workbench (Jewelcrafting 30).",
        zone = "Stormwind City",
    },

    -- Feet — Alliance Ret (level 10)
    {
        id = "early10_feet_quagmire_galoshes",
        itemId = 10658,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain and choose Quagmire Galoshes over Talbar Mantle when turning in to Mathrengyl Bearwalker in Darnassus.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },
    {
        id = "early10_feet_padded_lamellar_boots",
        itemId = 5320,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet and choose Padded Lamellar Boots (+2 Strength, +2 Stamina).",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early10_feet_mud_stompers",
        itemId = 6188,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete The Hunter's Revenge in Wetlands — kill Sarltooth and return his talon to Watcher Belgrum for Mud Stompers.",
        zone = "Wetlands",
        npc = "Watcher Belgrum",
        questName = "The Hunter's Revenge",
    },

    -- Legs — Alliance Ret (level 10)
    {
        id = "early10_legs_veteran_leggings",
        itemId = 2978,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Leggings (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_legs_war_torn_pants",
        itemId = 15485,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "War-Torn Pants (req 9) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_legs_cadet_leggings",
        itemId = 9763,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Leggings (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — Alliance Ret (level 10)
    {
        id = "early10_waist_bloodspattered_sash",
        itemId = 15492,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        instructions = "Bloodspattered Sash (req 10) is a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },
    {
        id = "early10_waist_silver_defias_belt",
        itemId = 832,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Silver Defias Belt (req 10) is a green world drop from Defias mobs in Westfall and the Deadmines area.",
        zone = "Westfall",
    },
    {
        id = "early10_waist_breakwater_girdle",
        itemId = 15404,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },

    -- Hands — Alliance Ret (level 10)
    {
        id = "early10_hands_veteran_gloves",
        itemId = 2980,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Gloves (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_hands_gemmed_copper_gauntlets",
        itemId = 3474,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "profession",
        suffix = "of Strength",
        suffixChance = 9.2,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        profession = "Blacksmithing",
        instructions = "Learn Gemmed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 25). +2 Strength.",
        zone = "Stormwind City",
    },
    {
        id = "early10_hands_bloodspattered_gloves",
        itemId = 15491,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.2,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        instructions = "Bloodspattered Gloves (req 10) are a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },

    -- Later Alliance leveling (unchanged horizon)
    {
        id = "early_chest_tunic_westfall",
        itemId = 2041,
        slot = "Chest",
        minLevel = 9,
        maxLevel = 18,
        factions = ALLIANCE,
        sourceType = "quest_reward",
        instructions = "Finish The Defias Brotherhood quest chain in Westfall. Turn in VanCleef's Head to Gryan Stoutmantle at Sentinel Hill and choose the Tunic of Westfall (leather chest).",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The Defias Brotherhood",
    },
    {
        id = "paladin_mainhand_hogger_blade",
        itemId = 6331,
        slot = "MainHand",
        minLevel = 6,
        maxLevel = 15,
        classes = { PALADIN = true },
        factions = ALLIANCE,
        sourceType = "world_drop",
        instructions = "Group for Hogger in Elwynn Forest (Wanted: Hogger quest). Howling Blade is a low-chance loot drop from Hogger.",
        zone = "Elwynn Forest",
        npc = "Hogger",
    },
    {
        id = "paladin_mainhand_verigans_fist",
        itemId = 6953,
        slot = "MainHand",
        minLevel = 20,
        maxLevel = 30,
        classes = { PALADIN = true },
        factions = ALLIANCE,
        sourceType = "quest_reward",
        instructions = "Complete the Paladin Test of Righteousness chain starting with The Tome of Valor in Stormwind. Gather Jordan's materials from Deadmines, Loch Modan, Shadowfang Keep, and Darkshore, then return to Jordan Stilwell in Ironforge.",
        zone = "Stormwind City",
        questName = "The Tome of Valor",
    },

    -- Forever phase-4 deltas (Horde shaman). Seen in the beta notebook with
    -- item IDs + tooltips. foreverDelta keeps them in the hunt across generated
    -- per-level bands; Compare still takes the top 3 by pipelineScore.
    {
        id = "forever_horde_shaman_ranged_windcarved_effigy",
        itemId = 263412,
        slot = "Ranged",
        minLevel = 1,
        maxLevel = 51,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Shaman totem: Lightning Bolt costs 5 less mana. Fills the relic slot until Totem of Rage (52).",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 9,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.38,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — more armor than the Classic grey/white belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 9,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.46,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — beats the Classic 1–9 leather greys on armor alone.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 4,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.71,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Burnt Leather Breeches take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.74,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.69,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 35,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 9.39,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.24,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 26,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.95,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 26,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 5.35,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, +9 healing / +3 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 44,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 12.65,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, +9 healing / +3 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 13,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 2.45,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_enh_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 14,
        classes = SHAMAN_CLASS,
        specs = SPEC_ENHANCEMENT_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 4.15,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_enh_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = SHAMAN_CLASS,
        specs = SPEC_ENHANCEMENT,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.15,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde mage). Cloth only. Mail copper boots
    -- and armor-only Skyborne whites do not beat the Classic cloth list.
    {
        id = "forever_horde_mage_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_frost_feet_frothing",
        itemId = 254003,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = MAGE_CLASS,
        specs = SPEC_FROST,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.25,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Frothing Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Frost damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_arcane_feet_frothing",
        itemId = 254003,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 37,
        classes = MAGE_CLASS,
        specs = SPEC_ARCANE,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 9.19,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Frothing Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +13 Frost damage also scores for Arcane. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_fire_feet_fiery",
        itemId = 254005,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 43,
        classes = MAGE_CLASS,
        specs = SPEC_FIRE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.25,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Fiery Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Fire damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.29,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_arcane_feet_golden",
        itemId = 254009,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = MAGE_CLASS,
        specs = SPEC_ARCANE,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.14,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Golden Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Arcane damage. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde warlock). Cloth only; 1-9 has no notebook winner.
    {
        id = "forever_horde_warlock_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.81,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_shadow_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = WARLOCK_CLASS,
        specs = SPEC_AFF_DEMO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.18,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_dest_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = WARLOCK_CLASS,
        specs = SPEC_DESTRUCTION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 12.42,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.62,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_dest_feet_fiery",
        itemId = 254005,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 37,
        classes = WARLOCK_CLASS,
        specs = SPEC_DESTRUCTION,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 9.17,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Fiery Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +13 Fire damage is the Destruction off-school. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde druid). Idol fills an empty relic slot.
    -- Cloth rares are Balance/Restoration only; feral/bear keep leather.
    {
        id = "forever_horde_druid_ranged_windcharged_leaf",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 1,
        maxLevel = 51,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Fills the relic slot until the Classic idols (52+).",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_ranged_windcharged_leaf_late_casters",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 52,
        maxLevel = 59,
        classes = DRUID_CLASS,
        specs = SPEC_BEAR_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Bear and Balance have no Classic idol until 60.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_ranged_windcharged_leaf_late_resto",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 52,
        maxLevel = 56,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Restoration's first Classic idol is 57.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.46,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.10,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 35,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 9.33,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.50,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 50,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 27.61,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +20 healing / +7 spell damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde rogue). Leather only; cloth/mail and
    -- white 2.0-dps weapons lose to Early 1-9. No 10+ notebook winner.
    {
        id = "forever_horde_rogue_chest_bandits_jerkin",
        itemId = 263421,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 2,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.205,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor — more than the Classic grey vests in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_chest_bandits_jerkin_l3",
        itemId = 263421,
        slot = "Chest",
        minLevel = 3,
        maxLevel = 3,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 0.205,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor. Rank 2 at 3 behind Handstitched Leather Vest.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_wrist_vuldren_hide",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 1,
        maxLevel = 2,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.075,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor — more than the Classic grey bracers in this band. Seen in Shen'dar Village on Zephras Isle.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_wrist_vuldren_hide_l3",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 3,
        maxLevel = 3,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 0.075,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor. Rank 3 at 3 behind the first +stat bracers.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde priest). Cloth only; 1-9 has no notebook
    -- winner (armor-only whites lose to the Classic cloth list). Radiant /
    -- Fiery / Frothing / Golden slippers are the wrong school.
    {
        id = "forever_horde_priest_holy_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 37,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.27,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_disc_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 43,
        classes = PRIEST_CLASS,
        specs = SPEC_DISC,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.06,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_heal_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 16,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY_DISC,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.16,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.57,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.87,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_heal_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 50,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY_DISC,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 29.17,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +20 healing / +7 spell damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.69,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.34,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde hunter). Mail whites win 1–9 on armor;
    -- leather Jerkin/bracers still beat the grey pile. Ranged/melee whites
    -- lose to Classic bows and 2H. No caster sash. Copper boots win at 10.
    {
        id = "forever_horde_hunter_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 9,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.19,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — more armor than the Classic grey/white belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 9,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.23,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — beats the Classic 1–9 leather greys on armor alone.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 4,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.355,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Burnt Leather Breeches take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_chest_watchers_mail",
        itemId = 263410,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 4,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.335,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail chest, 67 armor. +stat leather vests take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_chest_bandits_jerkin",
        itemId = 263421,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 2,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 0.199,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor. Rank 2 behind Watcher's Mail Chest.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_wrist_vuldren_hide",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 1,
        maxLevel = 2,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.073,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor — more than the Classic grey bracers in this band. Seen in Shen'dar Village on Zephras Isle.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_wrist_vuldren_hide_l3",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 3,
        maxLevel = 3,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 0.073,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor. Rank 3 at 3 behind the first +stat bracers.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_gemmed_copper_l11",
        itemId = 250620,
        slot = "Feet",
        minLevel = 11,
        maxLevel = 12,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Rank 3 at 11–12 behind Agility-suffix boots.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde paladin). Mail whites are close on the
    -- 0.02 armor weight. No Forever libram in the notebook (empty relic until
    -- Classic librams). Holy takes cloth sashes / Gilded; ret/prot take copper boots.
    {
        id = "forever_horde_paladin_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 2,
        classes = PALADIN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.68,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — ties the Classic chain belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 2,
        classes = PALADIN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.83,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — ties the Classic chain boots in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_feet_thendal_ranger_shoes_l3",
        itemId = 257257,
        slot = "Feet",
        minLevel = 3,
        maxLevel = 3,
        classes = PALADIN_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 0.83,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor. Rank 2 at 3 behind Gnoll Cast-offs.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 2,
        classes = PALADIN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.28,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Beats the Classic chain pants in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_legs_highlands_mail_l3",
        itemId = 263423,
        slot = "Legs",
        minLevel = 3,
        maxLevel = 3,
        classes = PALADIN_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.28,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Rank 2 at 3 behind Loose Chain Pants.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 13.32,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 18,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 8.47,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 29,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 19.39,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, +9 healing / +3 spell damage, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_feet_glowing_copper_late",
        itemId = 250482,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 19.39,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. Rank 2 from 30 behind Gilded Slippers.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 26,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 8.30,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_holy_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 51,
        classes = PALADIN_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 42.31,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +20 healing / +7 spell damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_ret_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = PALADIN_CLASS,
        specs = SPEC_RET,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.71,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_prot_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = PALADIN_CLASS,
        specs = SPEC_PROT,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 7.40,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_paladin_prot_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = PALADIN_CLASS,
        specs = SPEC_PROT,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 5.86,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde warrior). Mail whites on the 0.03 armor
    -- weight. Gemmed Copper Boots for all specs; prot also keeps Strange.
    -- Cloth sashes and white weapons lose. No relic slot.
    {
        id = "forever_horde_warrior_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 2,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.03,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — ties the Classic chain belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 2,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.24,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — ties the Classic chain boots in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_feet_thendal_ranger_shoes_l3",
        itemId = 257257,
        slot = "Feet",
        minLevel = 3,
        maxLevel = 3,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.24,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor. Rank 2 at 3 behind Gnoll Cast-offs.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 2,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.92,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Beats the Classic chain pants in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_legs_highlands_mail_l3",
        itemId = 263423,
        slot = "Legs",
        minLevel = 3,
        maxLevel = 3,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.92,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Rank 2 at 3 behind Loose Chain Pants.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_chest_watchers_mail",
        itemId = 263410,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 1,
        classes = WARRIOR_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.81,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail chest, 67 armor. Ties the Classic chain vests at 1; Rough Copper Vest takes over at 2.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_arms_fury_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = WARRIOR_CLASS,
        specs = SPEC_ARMS_FURY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 6.18,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_prot_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = WARRIOR_CLASS,
        specs = SPEC_PROT,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 6.35,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warrior_prot_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 15,
        classes = WARRIOR_CLASS,
        specs = SPEC_PROT,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 5.85,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },

}

local SLOT_TO_INVENTORY = {
    Head = 1,
    Neck = 2,
    Shoulder = 3,
    Back = 15,
    Chest = 5,
    Shirt = 4,
    Tabard = 19,
    Wrist = 9,
    Hands = 10,
    Waist = 6,
    Legs = 7,
    Feet = 8,
    Finger0 = 11,
    Finger1 = 12,
    Trinket0 = 13,
    Trinket1 = 14,
    MainHand = 16,
    SecondaryHand = 17,
    Ranged = 18,
}

-- Log categories: both finger/trinket inventory slots share one upgrade list each.
GQ.Data.MERGED_SLOT_INVENTORY = {
    Finger = { 11, 12 },
    Trinket = { 13, 14 },
}

function GQ.Data:NormalizeSlotName(slotName)
    if slotName == "Shield" then
        return "SecondaryHand"
    end
    if slotName == "Finger0" or slotName == "Finger1" then
        return "Finger"
    end
    if slotName == "Trinket0" or slotName == "Trinket1" then
        return "Trinket"
    end
    return slotName
end

function GQ.Data:GetInventorySlots(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if self.MERGED_SLOT_INVENTORY[slotName] then
        return self.MERGED_SLOT_INVENTORY[slotName]
    end

    local inv = SLOT_TO_INVENTORY[slotName]
    if inv then
        return { inv }
    end
    return {}
end

function GQ.Data:GetInventorySlot(slotName)
    local slots = self:GetInventorySlots(slotName)
    return slots[1]
end

function GQ.Data:EntryMatchesSlot(entry, slotName)
    if not entry or not entry.slot then
        return false
    end
    return self:NormalizeSlotName(entry.slot) == self:NormalizeSlotName(slotName)
end

function GQ.Data:GetCandidateSlotKeys(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Finger" then
        return { "Finger", "Finger0", "Finger1" }
    end
    if slotName == "Trinket" then
        return { "Trinket", "Trinket0", "Trinket1" }
    end
    if slotName == "SecondaryHand" then
        return { "SecondaryHand", "Shield" }
    end
    return { slotName }
end

function GQ.Data:GetForeverAudit(itemId)
    if not itemId or not self.foreverAudit then
        return nil
    end
    return self.foreverAudit[itemId]
end

function GQ.Data:GetForeverStatus(itemId)
    local audit = self:GetForeverAudit(itemId)
    return audit and audit.status or nil
end

function GQ.Data:IsForeverMissing(itemId)
    return self:GetForeverStatus(itemId) == "missing"
end

function GQ.Data:TipHasCombatStats(tip)
    if type(tip) ~= "string" or tip == "" then
        return false
    end
    if tip:find("%+%d") then
        return true
    end
    if tip:find("Armor", 1, true) or tip:find("Damage", 1, true) then
        return true
    end
    if tip:find("Equip:", 1, true) or tip:find("Use:", 1, true) then
        return true
    end
    if tip:find("Chance on hit", 1, true) then
        return true
    end
    return false
end

function GQ.Data:HasCombatTooltipData(entry)
    if not entry then
        return false
    end
    if entry.suffixRange and entry.suffixRange ~= "" then
        return true
    end
    if entry.proc and entry.proc ~= "" then
        return true
    end
    local fact = self:GetItemFact(entry.itemId)
    if fact and fact.proc and fact.proc ~= "" then
        return true
    end
    if fact and fact.stats then
        for _, value in pairs(fact.stats) do
            if type(value) == "number" and value ~= 0 then
                return true
            end
        end
    end
    local audit = self:GetForeverAudit(entry.itemId)
    if audit and self:TipHasCombatStats(audit.tip) then
        return true
    end
    return false
end

function GQ.Data:NeedsDatamineNotice(entry)
    if not entry then
        return false
    end
    if self:IsForeverMissing(entry.itemId) then
        return false
    end
    if self:HasCombatTooltipData(entry) then
        return false
    end
    -- A live client tooltip already has stats / suffixes / effects.
    if entry.itemId and self.ItemInfoIsReady and self:ItemInfoIsReady(entry.itemId) then
        return false
    end
    return true
end

function GQ.Data:AppendDatamineNotice(tooltip, entry)
    if not tooltip or not self:NeedsDatamineNotice(entry) then
        return
    end
    tooltip:AddLine("Has not been datamined yet", 1, 0.82, 0)
end

function GQ.Data:PruneMissingForever()
    if not self.entries or not self.foreverAudit then
        return
    end

    local kept = {}
    for i = 1, #self.entries do
        local entry = self.entries[i]
        if not self:IsForeverMissing(entry and entry.itemId) then
            kept[#kept + 1] = entry
        end
    end
    self.entries = kept
end

function GQ.Data:BuildIndex()
    self:PruneMissingForever()
    self.bySlot = {}
    self.byItemId = {}
    self.byId = {}
    self.byClass = {}
    self.byClassSlot = {}
    self.byClassSlotSpec = {}
    for _, entry in ipairs(self.entries) do
        local slot = self:NormalizeSlotName(entry.slot)
        self.bySlot[slot] = self.bySlot[slot] or {}
        table.insert(self.bySlot[slot], entry)
        self.byItemId[entry.itemId] = self.byItemId[entry.itemId] or {}
        table.insert(self.byItemId[entry.itemId], entry)
        if entry.id then
            self.byId[entry.id] = entry
        end
        if entry.classes then
            for classFile in pairs(entry.classes) do
                self.byClass[classFile] = self.byClass[classFile] or {}
                table.insert(self.byClass[classFile], entry)
                self.byClassSlot[classFile] = self.byClassSlot[classFile] or {}
                self.byClassSlot[classFile][slot] = self.byClassSlot[classFile][slot] or {}
                table.insert(self.byClassSlot[classFile][slot], entry)

                self.byClassSlotSpec[classFile] = self.byClassSlotSpec[classFile] or {}
                self.byClassSlotSpec[classFile][slot] = self.byClassSlotSpec[classFile][slot] or { _any = {} }
                local specMap = self.byClassSlotSpec[classFile][slot]
                local placed = false
                if entry.specs then
                    for specName, enabled in pairs(entry.specs) do
                        if enabled then
                            specMap[specName] = specMap[specName] or {}
                            table.insert(specMap[specName], entry)
                            placed = true
                        end
                    end
                end
                if not placed then
                    table.insert(specMap._any, entry)
                end
            end
        end
    end
    self:InvalidateQueryCache()
end

function GQ.Data:GetClassSlotEntryList(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local classFile = GQ:GetEffectiveClass()
    local specMap = classFile
        and self.byClassSlotSpec
        and self.byClassSlotSpec[classFile]
        and self.byClassSlotSpec[classFile][slotName]
    if specMap then
        local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
        local cacheKey = tostring(spec or "")
        if specMap._lookup and specMap._lookupKey == cacheKey then
            return specMap._lookup
        end
        local specList = spec and specMap[spec]
        local anyList = specMap._any
        local lookup
        if specList and anyList and #anyList > 0 then
            lookup = {}
            for i = 1, #specList do
                lookup[#lookup + 1] = specList[i]
            end
            for i = 1, #anyList do
                lookup[#lookup + 1] = anyList[i]
            end
        else
            lookup = specList or anyList or {}
        end
        specMap._lookup = lookup
        specMap._lookupKey = cacheKey
        return lookup
    end
    if classFile and self.byClassSlot and self.byClassSlot[classFile] then
        return self.byClassSlot[classFile][slotName]
    end
    return self.bySlot and self.bySlot[slotName]
end

function GQ.Data:GetEntriesByItemId(itemId)
    if not itemId then
        return {}
    end
    return self.byItemId and self.byItemId[itemId] or {}
end

function GQ.Data:GetItemFact(itemId)
    if not itemId then
        return nil
    end

    local tables = {
        self.itemFacts,
        self.warriorItemFacts,
        self.hunterItemFacts,
        self.druidItemFacts,
        self.shamanItemFacts,
        self.rogueItemFacts,
        self.priestItemFacts,
        self.priestEarly1to9Facts,
        self.warlockItemFacts,
        self.warlockEarly1to9Facts,
        self.mageItemFacts,
        self.mageEarly1to9Facts,
        self.paladinHorde1to9Facts,
        self.warriorHorde1to9Facts,
        self.hunterEarly1to9Facts,
        self.druidEarly1to9Facts,
        self.shamanEarly1to9Facts,
        self.rogueEarly1to9Facts,
    }

    for i = 1, #tables do
        local fact = tables[i] and tables[i][itemId]
        if fact then
            return fact
        end
    end

    return nil
end

function GQ.Data:NoteClientItemMissing(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    self._clientMissing = self._clientMissing or {}
    self._clientMissing[itemId] = true
end

function GQ.Data:IsClientItemMissing(itemId)
    itemId = tonumber(itemId)
    return itemId and self._clientMissing and self._clientMissing[itemId] == true
end

function GQ.Data:RequestItemInfo(itemIdOrLink, force)
    if not itemIdOrLink then
        return
    end

    local itemId = tonumber(itemIdOrLink)
    if not itemId and type(itemIdOrLink) == "string" then
        itemId = self:ItemLinkToId(itemIdOrLink)
    end
    if GQ.Equip and GQ.Equip.RequestItemInfo and itemId then
        GQ.Equip:RequestItemInfo(itemId, force)
    end
    if force and type(itemIdOrLink) == "string" and GetItemInfo then
        GetItemInfo(itemIdOrLink)
    end
end

function GQ.Data:IsPlaceholderItemName(name, itemId)
    if type(name) ~= "string" then
        return true
    end
    name = name:match("^%s*(.-)%s*$") or ""
    if name == "" then
        return true
    end
    -- Forever's client answers GetItemInfo with "Item 23173" until the
    -- real name is in its cache. That is not a name.
    if name:find("^Item #?%d+$") then
        return true
    end
    if itemId and name == tostring(itemId) then
        return true
    end
    return false
end

function GQ.Data:GetItemDisplayName(itemId)
    if not itemId then
        return nil
    end

    local clientName = GetItemInfo and GetItemInfo(itemId)
    if clientName and not self:IsPlaceholderItemName(clientName, itemId) then
        return clientName
    end

    local fact = self:GetItemFact(itemId)
    if fact and fact.name and not self:IsPlaceholderItemName(fact.name, itemId) then
        return fact.name
    end

    local audit = self:GetForeverAudit(itemId)
    if audit and audit.name and not self:IsPlaceholderItemName(audit.name, itemId) then
        return audit.name
    end

    local prof = PROFESSION_ITEM_NAMES[itemId]
    if prof and not self:IsPlaceholderItemName(prof, itemId) then
        return prof
    end

    return nil
end

function GQ.Data:GetEntryDisplayName(entry)
    if not entry then
        return nil
    end

    local base = self:GetItemDisplayName(entry.itemId) or ("Item " .. tostring(entry.itemId))
    local suffix = entry.suffix
    if suffix and suffix ~= "" then
        suffix = tostring(suffix)
        if suffix:sub(1, 1) == " " then
            return base .. suffix
        end
        return base .. " " .. suffix
    end

    return base
end

function GQ.Data:ItemNameMatchesSuffixTarget(itemName, targetName, entry)
    itemName = self:NormalizeItemName(itemName)
    targetName = self:NormalizeItemName(targetName)
    if not itemName or not targetName then
        return false
    end

    if itemName == targetName then
        return true
    end

    if entry and entry.suffix and entry.suffix ~= "" then
        local suffix = tostring(entry.suffix)
        if suffix:sub(1, 1) ~= " " then
            suffix = " " .. suffix
        end
        if itemName:sub(-#suffix) == suffix then
            return true
        end
    end

    return false
end

function GQ.Data:EntryDisplayNameReady(entry)
    if not entry or not entry.itemId then
        return false
    end

    local base = self:GetItemDisplayName(entry.itemId)
    if not base or base:find("^Item %d+$", 1) then
        return false
    end

    return true
end

function GQ.Data:SanitizeText(text)
    text = GQ.PublicText(text)
    if not text then
        return text
    end

    text = tostring(text)
    -- WoW fonts lack these glyphs and draw them as empty boxes.
    text = text:gsub("\239\191\189", "'") -- U+FFFD replacement char
    text = text:gsub("\226\128\148", "-") -- em dash
    text = text:gsub("\226\128\147", "-") -- en dash
    text = text:gsub("\226\128\146", "-") -- figure dash
    text = text:gsub("\194\183", ", ") -- middle dot
    text = text:gsub("\226\128\166", "...") -- ellipsis
    text = text:gsub("\226\128\156", "'") -- left double quote
    text = text:gsub("\226\128\157", "'") -- right double quote
    text = text:gsub("\226\128\152", "'") -- left single quote
    text = text:gsub("\226\128\153", "'") -- right single quote
    text = text:gsub("\194\160", " ")
    text = text:gsub("\147", "'") -- cp1252 left double quote
    text = text:gsub("\148", "'") -- cp1252 right double quote
    text = text:gsub("\145", "'")
    text = text:gsub("\146", "'")
    text = text:gsub("\151", "-")
    text = text:gsub("\150", "-")
    -- FFFD/em-dash pairs became quote-space-quote after a bad decode.
    text = text:gsub("' '", " - ")
    text = text:gsub('" "', " - ")
    text = text:gsub(" +", " ")
    text = text:gsub(" ,", ",")
    return text
end

-- Wowhead tips were stored with HTML stripped and no line breaks, so
-- "Item Level 27Binds when equippedShoulderMail142" reads as one word.
local FOREVER_TIP_BREAKS = {
    "Item Level ",
    "Binds when ",
    "Unique%-Equipped",
    "Unique",
    "Requires Level ",
    "Requires ",
    "Classes:",
    "Sell Price",
    "Durability",
    "Dropped by:",
    "Drop Chance:",
    "Durability",
    "Restores ",
    "Equip:",
    "Use:",
    "Chance on hit:",
}

local GREEN_STAT = {
    "Spell Power", "Damage Done", "Healing Done", "Ranged Attack Power",
    "Attack Power", "Critical Strike", "Expertise", "Hit", "Haste",
    "Defense", "Dodge", "Parry", "Resistance",
}

function GQ.Data:FormatAuditTip(tip)
    tip = self:SanitizeText(tip)
    if not tip or tip == "" then
        return tip
    end
    tip = tip:gsub("(%d)(%u)", "%1 %2")
    tip = tip:gsub("(%l)(%u)", "%1 %2")
    tip = tip:gsub("(%l)(%d)", "%1 %2")
    tip = tip:gsub("(%l)(%+)", "%1 %2")
    tip = tip:gsub("%)(%u)", ")\n%1")
    tip = tip:gsub("%.%(", ".\n(")
    tip = tip:gsub("%.(%u)", ".\n%1")
    tip = tip:gsub("(Binds when equipped)", "%1\n")
    tip = tip:gsub("(Binds when picked up)", "%1\n")
    tip = tip:gsub("(Unique)(%s)", "%1\n")
    tip = tip:gsub(" (%d+) Armor", "\n%1 Armor")
    tip = tip:gsub("(%a)(%d+) Armor", "%1\n%2 Armor")
    tip = tip:gsub("(%d+) Block", "\n%1 Block")
    -- Wowhead prints one line per bonus: "(2) Set : +10 Intellect."
    -- "Set:" and "Set :" both occur. Keep the +N on that line; the stat
    -- splitter below is for "+6 Strength+4 Stamina", not for set bonuses.
    tip = tip:gsub("(%(%d+%)%s*Set%s*:)", "\n%1")
    tip = tip:gsub("(Requires Level %d+)%s+", "%1\n")
    for _, head in ipairs(FOREVER_TIP_BREAKS) do
        tip = tip:gsub("(" .. head .. ")", "\n%1")
    end
    tip = tip:gsub("(%(%d+%)%s*Set%s*:%s*)%+(%d+)", "%1\1%2")
    tip = tip:gsub("%+(%d+)%s+", "\n+%1 ")
    tip = tip:gsub("(%(%d+%)%s*Set%s*:%s*)\1(%d+)", "%1+%2")
    tip = tip:gsub("(%(%d+%)%s*Set%s*:)%s*\n%s*(%+%d+)", "%1 %2")
    tip = tip:gsub(" +", " ")
    tip = tip:gsub("\n+", "\n")
    return tip:match("^%s*(.-)%s*$")
end

local GOLD_COIN = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t"
local SILVER_COIN = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t"
local COPPER_COIN = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"

function GQ.Data:FormatSellPriceLine(line)
    local rest = line and line:match("^Sell Price:%s*(.*)$")
    if not rest or rest == "" then
        return line
    end
    local nums = {}
    for n in rest:gmatch("%d+") do
        nums[#nums + 1] = tonumber(n)
    end
    if #nums == 0 then
        return line
    end
    local gold, silver, copper = 0, 0, 0
    if #nums == 1 then
        copper = nums[1]
    elseif #nums == 2 then
        silver, copper = nums[1], nums[2]
    else
        gold, silver, copper = nums[1], nums[2], nums[3]
    end
    local amount = gold * 10000 + silver * 100 + copper
    local coin
    if GetCoinTextureString then
        coin = GetCoinTextureString(amount)
    elseif C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        coin = C_CurrencyInfo.GetCoinTextureString(amount)
    end
    if coin and coin ~= "" then
        return "Sell Price: " .. coin
    end
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = gold .. GOLD_COIN
    end
    if silver > 0 or gold > 0 then
        parts[#parts + 1] = silver .. SILVER_COIN
    end
    parts[#parts + 1] = copper .. COPPER_COIN
    return "Sell Price: " .. table.concat(parts, " ")
end

local function lua_escape(s)
    return (s:gsub("(%W)", "%%%1"))
end

-- Infer the shared piece prefix from the mashed list ("Savage Gladiator Helm
-- Savage Gladiator Chain..."), not from the set title. "The Gladiator (0/6)"
-- is the Wowhead set name; splitting on "Gladiator" alone cuts every piece.
function GQ.Data:InferSetPiecePrefix(blob, total)
    if not blob or blob == "" then
        return nil
    end
    total = tonumber(total)
    local words = {}
    for w in blob:gmatch("%S+") do
        words[#words + 1] = w
    end
    local best, bestLen = nil, 0
    for len = math.min(4, #words), 1, -1 do
        local prefix = table.concat(words, " ", 1, len)
        local count = 0
        local pos = 1
        while true do
            local a, b = blob:find(prefix, pos, true)
            if not a then
                break
            end
            count = count + 1
            pos = b + 1
        end
        if count >= 2 and len > bestLen then
            best = prefix
            bestLen = len
            if total and count == total then
                return prefix
            end
        end
    end
    return best
end

-- Wowhead stores set blocks as "Cryptstalker Armor (0/9)Cryptstalker BootsCryptstalker Girdle...".
-- After camel-case spacing that is one long line; split it like the client tooltip.
function GQ.Data:SplitSetPieceNames(header, blob, total)
    local family = self:InferSetPiecePrefix(blob, total)
    if not family or family == "" then
        return blob
    end
    local out = blob
    out = out:gsub("of the " .. family, "of the\0" .. family)
    out = out:gsub(" (" .. lua_escape(family) .. ")", "\n" .. family)
    out = out:gsub("of the\0", "of the ")
    out = out:gsub(" (Ring of )", "\nRing of ")
    out = out:gsub(" (Cloak of )", "\nCloak of ")
    out = out:gsub(" (Band of )", "\nBand of ")
    out = out:gsub(" (Pendant of )", "\nPendant of ")
    out = out:gsub(" (Medallion of )", "\nMedallion of ")
    return out
end

function GQ.Data:ExpandForeverSetLines(lines)
    local out = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local req, rest = line:match("^(Requires Level %d+)%s+(.+)$")
        if req and rest then
            out[#out + 1] = req
            line = rest
        end
        local classesLine, afterClasses = line:match("^(Classes: [%a, ]+)%s+(.+)$")
        if classesLine and afterClasses and afterClasses:find("%(%d+/%d+%)") then
            classesLine = classesLine:gsub("%s+$", "")
            -- Keep only real class names; "Classes: Priest Vestments..." is mashed.
            local kept = {}
            for word in classesLine:gmatch("%u%l+") do
                if word == "Warrior" or word == "Paladin" or word == "Hunter"
                    or word == "Rogue" or word == "Priest" or word == "Shaman"
                    or word == "Mage" or word == "Warlock" or word == "Druid" then
                    kept[#kept + 1] = word
                end
            end
            if #kept > 0 then
                out[#out + 1] = "Classes: " .. table.concat(kept, ", ")
                line = afterClasses:match("^%s*(.-)%s*$") or afterClasses
            end
        end
        local name, worn, total, trail = line:match("^(.-)%s*%((%d+)/(%d+)%)%s*(.*)$")
        if name and total then
            out[#out + 1] = name .. " (" .. worn .. "/" .. total .. ")"
            local blob = trail
            if (not blob or blob == "") and lines[i + 1]
                and not lines[i + 1]:find("^%(%d+%) Set")
                and not lines[i + 1]:find("^Sell Price")
                and not lines[i + 1]:find("^Equip:") then
                blob = lines[i + 1]
                i = i + 1
            end
            if blob and blob ~= "" then
                local pieces = self:SplitSetPieceNames(name .. " (" .. worn .. "/" .. total .. ")", blob, total)
                for piece in string.gmatch(pieces .. "\n", "([^\n]*)\n") do
                    piece = piece:match("^%s*(.-)%s*$") or ""
                    if piece ~= "" then
                        out[#out + 1] = self:ResolveSetPieceLine(piece)
                    end
                end
            end
            i = i + 1
        else
            if line ~= "" then
                out[#out + 1] = line
            end
            i = i + 1
        end
    end
    return out
end

function GQ.Data:ForeverLineIsName(line, ...)
    if not line or line == "" then
        return false
    end
    local folded = line:lower()
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if type(name) == "string" and name ~= "" and folded == name:lower() then
            return true
        end
    end
    return false
end

function GQ.Data:ForeverTooltipLines(tip)
    local text = self:FormatAuditTip(tip)
    if not text then
        return {}
    end
    local lines = {}
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        line = line:match("^%s*(.-)%s*$") or ""
        if line ~= "" then
            if line:find("^Sell Price") then
                line = self:FormatSellPriceLine(line)
            end
            lines[#lines + 1] = line
        end
    end
    local merged = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local nxt = lines[i + 1]
        if line == "Restores" and nxt and nxt:find("^%+%d+ mana") then
            merged[#merged + 1] = "Restores " .. nxt
            i = i + 2
        else
            merged[#merged + 1] = line
            i = i + 1
        end
    end
    return self:SplitForeverLayoutLines(self:ExpandForeverSetLines(merged))
end

function GQ.Data:ForeverLineColor(line)
    if line:find("^Equip:") or line:find("^Use:") or line:find("^Chance on hit")
        or line:find("^Restores") or line:find("mana per 5", 1, true) then
        return 0, 1, 0
    end
    if line:find("^%+") then
        for _, label in ipairs(GREEN_STAT) do
            if line:find(label, 1, true) then
                return 0, 1, 0
            end
        end
        return 1, 1, 1
    end
    if line:find("^%(%d+%) Set") then
        return 0.5, 0.5, 0.5
    end
    if line:find("%(%d+/%d+%)$") then
        return 1, 0.82, 0.1
    end
    if line:find("^Item Level") then
        return 1, 0.82, 0.1
    end
    if line:find("^Sell Price") then
        return 1, 1, 1
    end
    if line:find("^Dropped by") or line:find("^Drop Chance") then
        return 0.62, 0.62, 0.62
    end
    return 1, 1, 1
end

function GQ.Data:IsSetHeaderLine(line)
    return type(line) == "string" and line:find("%(%d+/%d+%)%s*$")
end

-- Client tooltips put slot on the left and armor/weapon type on the right.
-- Wowhead Forever mashes them ("ShoulderLeather" -> "Shoulder Leather").
local EQUIP_SLOT_PAT = "Held In Off%-hand|Held In Off%-Hand|One%-Hand|Two%-Hand|Main Hand|Off Hand|Shoulder|Finger|Trinket|Chest|Wrist|Hands|Waist|Legs|Feet|Head|Neck|Back|Ranged|Thrown|Relic"
local EQUIP_TYPE_PAT = "Fist Weapon|Fishing Pole|Leather|Cloth|Mail|Plate|Shield|Sword|Dagger|Staff|Polearm|Mace|Axe|Crossbow|Wand|Bow|Gun|Thrown|Libram|Totem|Idol|Miscellaneous"

function GQ.Data:SplitForeverLayoutLines(lines)
    local out = {}
    local i = 1
    local combo = "^(" .. EQUIP_SLOT_PAT .. ")%s+(" .. EQUIP_TYPE_PAT .. ")$"
    local slotOnly = "^(" .. EQUIP_SLOT_PAT .. ")$"
    local typeOnly = "^(" .. EQUIP_TYPE_PAT .. ")$"
    while i <= #lines do
        local line = lines[i]
        local nxt = lines[i + 1]
        if type(line) ~= "string" then
            out[#out + 1] = line
            i = i + 1
        else
            local left, right = line:match(combo)
            if left and right then
                out[#out + 1] = { left = left, right = right }
                i = i + 1
            elseif line:match(slotOnly) and type(nxt) == "string" and nxt:match(typeOnly) then
                out[#out + 1] = { left = line, right = nxt }
                i = i + 2
            else
                local dmg, spd = line:match("^(%d+ %- %d+ Damage)%s+(Speed [%d%.]+)$")
                if dmg and spd then
                    out[#out + 1] = { left = dmg, right = spd }
                    i = i + 1
                elseif line:match("^%d+ %- %d+ Damage$") and type(nxt) == "string" and nxt:match("^Speed ") then
                    out[#out + 1] = { left = line, right = nxt }
                    i = i + 2
                else
                    out[#out + 1] = line
                    i = i + 1
                end
            end
        end
    end
    return out
end

function GQ.Data:AddForeverTooltipLines(tooltip, lines, displayName, auditName)
    local setPhase
    local worn = 0
    local lastBlank = false

    local function addBlank()
        if lastBlank then
            return
        end
        tooltip:AddLine(" ")
        lastBlank = true
    end

    for _, line in ipairs(lines) do
        if type(line) == "table" then
            tooltip:AddDoubleLine(line.left or "", line.right or "", 1, 1, 1, 1, 1, 1)
            lastBlank = false
        else
            local isHeader = self:IsSetHeaderLine(line)
            local isBonus = line:find("^%(%d+%) Set")
            local isTail = line:find("^Sell Price") or line:find("^Dropped")
            if isHeader then
                addBlank()
                setPhase = "pieces"
                worn = tonumber(line:match("%((%d+)/%d+%)%s*$")) or 0
            elseif isBonus then
                setPhase = "bonus"
            elseif isTail then
                if setPhase == "bonus" or setPhase == "pieces" then
                    addBlank()
                end
                setPhase = nil
            end

            -- Skip a leftover title line. Never drop the hovered piece from the set list.
            if setPhase == "pieces" or not self:ForeverLineIsName(line, displayName, auditName) then
                local text = line
                if setPhase == "pieces" and not isHeader and not text:find("^%s") then
                    text = "  " .. text
                end
                local lr, lg, lb
                if isHeader then
                    lr, lg, lb = 1, 0.82, 0.1
                elseif isBonus then
                    local need = tonumber(line:match("^%((%d+)%) Set"))
                    if need and worn >= need then
                        lr, lg, lb = 0, 1, 0
                    else
                        lr, lg, lb = 0.5, 0.5, 0.5
                    end
                elseif setPhase == "pieces" then
                    lr, lg, lb = 0.5, 0.5, 0.5
                else
                    lr, lg, lb = self:ForeverLineColor(line)
                end

                local wrap = isBonus or (not isHeader and setPhase ~= "pieces" and not isTail)
                tooltip:AddLine(text, lr, lg, lb, wrap)
                lastBlank = false
            end
        end
    end
end

function GQ.Data:ResolveSetPieceLine(line)
    local id = line and line:match("^Item #(%d+)$")
    if not id then
        return line
    end
    id = tonumber(id)
    local name = self:GetItemDisplayName(id)
    if name then
        return name
    end
    self:RequestItemInfo(id, true)
    return line
end

function GQ.Data:ReadScannerLeftLines(scanner)
    local name = scanner and scanner.GetName and scanner:GetName()
    local out = {}
    local n = (scanner and scanner.NumLines and scanner:NumLines()) or 0
    for i = 1, n do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
        if text and text ~= "" then
            out[#out + 1] = text
        end
    end
    return out
end

function GQ.Data:ParseSetBlockFromLines(lines)
    local start
    for i = 1, #lines do
        if lines[i]:find("%(%d+/%d+%)$") then
            start = i
            break
        end
    end
    if not start then
        return nil
    end
    local block = { header = lines[start], pieces = {}, bonuses = {} }
    for i = start + 1, #lines do
        local line = lines[i]
        if line:find("^Requires Level") or line:find("^Sell Price") or line:find("^Dropped")
            or line:find("^You haven") or line:find("^Press F")
            or line:find("^Item Level") or line:find("^Binds when") or line:find("^Durability") then
            break
        end
        if line:find("^Classes:") or line:find("^Item #") or self:IsSetHeaderLine(line) then
            -- Classes can sit above or below the bonuses; Item # / extra headers are not pieces.
        elseif line:find("^%(%d+%) Set") then
            block.bonuses[#block.bonuses + 1] = line
        else
            block.pieces[#block.pieces + 1] = line
        end
    end
    return block
end

function GQ.Data:ClientSetBlockIsUsable(block)
    if not block or not block.bonuses or #block.bonuses == 0 then
        return false
    end
    if block.header then
        local total = tonumber(block.header:match("%(%d+/(%d+)%)"))
        if total == 0 then
            return false
        end
    end
    local filled = 0
    for i = 1, #block.bonuses do
        local rest = block.bonuses[i]:match("^%(%d+%) Set%s*:?%s*(.*)$")
        if rest and rest:match("%S") then
            filled = filled + 1
        end
    end
    return filled > 0
end

function GQ.Data:ScannerSetLooksComplete(lines)
    for i = 1, #lines do
        if lines[i]:find("^Sell Price") or lines[i]:find("^Classes:") or lines[i]:find("^Press F") then
            return true
        end
    end
    return false
end

function GQ.Data:InvalidateClientSetBlock(itemId)
    if itemId and self._clientSetBlock then
        self._clientSetBlock[itemId] = nil
    end
end

-- Use the live client set block only when it actually has (2)/(4)/… bonuses.
-- Empty client bonuses (Savage Gladiator) stay on the Wowhead Forever piece list.
function GQ.Data:GetClientSetBlock(itemId)
    if not itemId then
        return nil, false
    end
    self._clientSetBlock = self._clientSetBlock or {}
    local cached = self._clientSetBlock[itemId]
    if cached ~= nil then
        if cached == false then
            return nil, false
        end
        return cached, false
    end

    self:RequestItemInfo(itemId, true)
    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    if not self:SetTooltipItem(scanner, itemId) or self:TooltipLooksRetrieving(scanner) then
        scanner:Hide()
        return nil, true
    end
    local lines = self:ReadScannerLeftLines(scanner)
    scanner:Hide()
    local block = self:ParseSetBlockFromLines(lines)
    if not block then
        if self:ScannerSetLooksComplete(lines) then
            self._clientSetBlock[itemId] = false
            return nil, false
        end
        return nil, true
    end
    if #block.bonuses > 0 and self:ClientSetBlockIsUsable(block) then
        self._clientSetBlock[itemId] = block
        return block, false
    end
    if self:ScannerSetLooksComplete(lines) then
        self._clientSetBlock[itemId] = false
        return nil, false
    end
    return nil, true
end

function GQ.Data:ReplaceSetBlock(lines, block)
    if not block or not block.header then
        return lines
    end
    local body, classes, requires, sell = {}, {}, {}, {}
    local dropping = false
    for i = 1, #lines do
        local line = lines[i]
        if type(line) == "table" then
            if not dropping then
                body[#body + 1] = line
            end
        else
        if self:IsSetHeaderLine(line) or line:find("^Item #") or line:find("^%(%d+%) Set") then
            dropping = true
        elseif dropping then
            if line:find("^Sell Price") or line:find("^Dropped") or line:find("^Requires Level")
                or line:find("^Classes:") or line:find("^Equip:") or line:find("^Use:")
                or line:find("^Item Level") or line:find("^Binds") or line:find("^Durability") then
                dropping = false
            end
        end
        if dropping then
            -- Wowhead set leftovers
        elseif line:find("^Sell Price") or line:find("^Dropped") then
            sell[#sell + 1] = line
        elseif line:find("^Requires Level") then
            requires[#requires + 1] = line
        elseif line:find("^Classes:") then
            classes[#classes + 1] = line
        else
            body[#body + 1] = line
        end
        end
    end

    local out = {}
    for i = 1, #body do
        out[#out + 1] = body[i]
    end
    for i = 1, #classes do
        out[#out + 1] = classes[i]
    end
    for i = 1, #requires do
        out[#out + 1] = requires[i]
    end
    out[#out + 1] = block.header
    for p = 1, #block.pieces do
        out[#out + 1] = block.pieces[p]
    end
    for b = 1, #block.bonuses do
        out[#out + 1] = block.bonuses[b]
    end
    for i = 1, #sell do
        out[#out + 1] = sell[i]
    end
    return out
end

function GQ.Data:LinesHaveSetHeader(lines)
    for i = 1, #lines do
        if self:IsSetHeaderLine(lines[i]) then
            return true
        end
    end
    return false
end

function GQ.Data:ApplyClientSetBlock(lines, block)
    if not block or not block.bonuses or #block.bonuses == 0 then
        return lines
    end
    local pieces = {}
    for i = 1, #(block.pieces or {}) do
        local piece = block.pieces[i]
        if piece and piece ~= "" and not piece:find("^Item #") and not self:IsSetHeaderLine(piece) then
            pieces[#pieces + 1] = piece
        end
    end
    return self:ReplaceSetBlock(lines, {
        header = block.header,
        pieces = pieces,
        bonuses = block.bonuses,
    })
end

-- Imbued result items. Printed stats stay the normal colors. Only the effect
-- the scroll adds is grey. Do not repeat that effect from entry.proc.
-- In its place: "Use: Combine the <base weapon> and <scroll>."
-- Add a row here and imbueBase / imbueScroll on the client override when
-- another weapon is made the same way.
local CLIENT_IMBUE = {
    [276631] = {
        scroll = "Imbue Blade",
        base = "Blade of Silverlaine",
        effect = {
            "Melee attacks deal",
            "against Frozen",
        },
    },
}

function GQ.Data:HideImbueScrollTooltip()
    if self._imbueTip then
        self._imbueTip:Hide()
    end
end

function GQ.Data:ShowImbueScrollTooltip(owner, info)
    if not owner or not info or not info.scroll then
        return
    end
    if not self._imbueTip then
        self._imbueTip = CreateFrame("GameTooltip", "GearQuestImbueTooltip", UIParent, "GameTooltipTemplate")
    end
    local tip = self._imbueTip
    tip:SetOwner(owner, "ANCHOR_NONE")
    tip:ClearAllPoints()
    tip:SetPoint("LEFT", owner, "RIGHT", 8, 0)
    tip:SetText(info.scroll, 0.75, 0.75, 0.75)
    tip:Show()
end

function GQ.Data:ImbueInfo(itemId)
    return CLIENT_IMBUE[itemId]
end

function GQ.Data:ImbueCombineLine(info)
    if not info or not info.base or info.base == "" or not info.scroll or info.scroll == "" then
        return nil
    end
    return "Use: Combine the " .. info.base .. " and " .. info.scroll .. "."
end

function GQ.Data:LineIsImbued(text, info)
    if not text or not info or not info.effect then
        return false
    end
    for i = 1, #info.effect do
        if text:find(info.effect[i], 1, true) then
            return true
        end
    end
    return false
end

function GQ.Data:AppendImbueOrProc(tooltip, entry)
    if not tooltip or not entry then
        return
    end
    local info = self:ImbueInfo(entry.itemId)
    if info then
        local line = self:ImbueCombineLine(info)
        if line then
            tooltip:AddLine(" ")
            tooltip:AddLine(line, 0, 1, 0, true)
        end
        return
    end
    if entry.proc and entry.proc ~= "" then
        tooltip:AddLine(" ")
        tooltip:AddLine(entry.proc, 1, 1, 1, true)
    end
end

function GQ.Data:ApplyImbueTooltipLines(tooltip, itemId)
    self:HideImbueScrollTooltip()
    local pool = tooltip and tooltip.gqImbueButtons
    if pool then
        for i = 1, #pool do
            pool[i]:Hide()
        end
    end
    local info = CLIENT_IMBUE[itemId]
    if not info or not tooltip or not tooltip.NumLines or not tooltip.GetName then
        return
    end
    local name = tooltip:GetName()
    if not name then
        return
    end
    if not self._imbueHooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnHide", function()
            GQ.Data:HideImbueScrollTooltip()
        end)
        self._imbueHooked = true
    end
    pool = tooltip.gqImbueButtons or {}
    tooltip.gqImbueButtons = pool
    local used = 0
    local n = tooltip:NumLines() or 0
    for i = 1, n do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs.GetText and fs:GetText()
        if text and self:LineIsImbued(text, info) then
            fs:SetTextColor(0.55, 0.55, 0.55)
            used = used + 1
            local btn = pool[used]
            if not btn then
                btn = CreateFrame("Button", nil, tooltip)
                btn:SetScript("OnEnter", function(self)
                    GQ.Data:ShowImbueScrollTooltip(self, self.gqImbue)
                end)
                btn:SetScript("OnLeave", function()
                    GQ.Data:HideImbueScrollTooltip()
                end)
                pool[used] = btn
            end
            btn.gqImbue = info
            btn:ClearAllPoints()
            btn:SetAllPoints(fs)
            btn:SetFrameLevel((tooltip:GetFrameLevel() or 0) + 20)
            btn:Show()
        end
    end
end

-- Paint the Wowhead Forever tooltip. The client still shows Classic Equip:
-- "Increases damage and healing done by up to N" for items that Wowhead
-- already prints as +N Spell Power / Damage Done / Healing Done.
function GQ.Data:ShowForeverItemTooltip(tooltip, entry)
    if not tooltip or not entry then
        return false
    end
    local audit = self:GetForeverAudit(entry.itemId)
    if not audit or not audit.tip or audit.tip == "" then
        return false
    end

    local displayName = self:GetEntryDisplayName(entry) or audit.name or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)

    if audit.status == "missing" then
        tooltip:AddLine("Not found on Wowhead Forever", 1, 0.2, 0.2)
    end

    local lines = self:ForeverTooltipLines(audit.tip)
    local clientSet, setPending = self:GetClientSetBlock(entry.itemId)
    if clientSet and clientSet.bonuses and #clientSet.bonuses > 0 then
        lines = self:ApplyClientSetBlock(lines, clientSet)
    end
    self._pendingClientSet = setPending and self:LinesHaveSetHeader(lines)
    self:AddForeverTooltipLines(tooltip, lines, displayName, audit.name)

    self:AppendImbueOrProc(tooltip, entry)
    self:AppendSuffixRangeLines(tooltip, entry)
    local suffixHint = self:GetSuffixHint(entry)
    if suffixHint then
        tooltip:AddLine(" ")
        tooltip:AddLine("Target random enchant: " .. suffixHint, 0.7, 0.9, 1)
    end
    self:AppendDatamineNotice(tooltip, entry)
    self:ApplyImbueTooltipLines(tooltip, entry.itemId)
    return true
end

function GQ.Data:GetSuffixHint(entry)
    if not entry or not entry.suffix then
        return nil
    end

    local parts = { entry.suffix }
    if entry.suffixRange and entry.suffixRange ~= "" then
        parts[#parts + 1] = entry.suffixRange
    elseif entry.suffixId then
        parts[#parts + 1] = "tier " .. tostring(entry.suffixId)
    end

    local hint = table.concat(parts, ", ")
    if entry.suffixChance then
        hint = hint .. " (slim ~" .. tostring(entry.suffixChance) .. "% roll -- BiS if you get it)"
    end

    return hint
end

-- Novelty on-use effects (fall damage/speed, drunk, party-only buffs, etc.) are not
-- real upgrades for the level band — hide them from picks and notables.
local NOVELTY_PROC_PATTERNS = {
    "fall speed",
    "fall damage",
    "slow fall",
    "safe fall",
    "parachute",
    "gets you quite drunk",
    "unless it explodes",
    "turns the target into a chicken",
    "look far into the distance",
    "nearby party members",
    "party members within",
    "summons the truesilver boar",
}

function GQ.Data:GetEntryProcText(entry)
    if not entry then
        return nil
    end

    if entry.proc and entry.proc ~= "" then
        return entry.proc
    end

    local facts = self.itemFacts
    if facts and entry.itemId then
        local fact = facts[entry.itemId]
        if fact and fact.proc and fact.proc ~= "" then
            return fact.proc
        end
    end

    return nil
end

function GQ.Data:IsNoveltyProcItem(entry)
    local proc = self:GetEntryProcText(entry)
    if not proc then
        return false
    end

    local lower = string.lower(tostring(proc))
    for i = 1, #NOVELTY_PROC_PATTERNS do
        if lower:find(NOVELTY_PROC_PATTERNS[i], 1, true) then
            return true
        end
    end

    return false
end

-- Ranged weapons whose DPS/procs only matter for Hunters (pull-slot filler for others).
GQ.Data.HUNTER_ONLY_RANGED_ITEMS = {
    [2825] = true, -- Bow of Searing Arrows
}

function GQ.Data:IsHunterOnlyRangedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.HUNTER_ONLY_RANGED_ITEMS[entry.itemId] == true
end

-- Melee attack-speed on-use (not spell haste) — bear/feral only for druids.
GQ.Data.DRUID_MELEE_HASTE_ITEMS = {
    [9449] = true, -- Manual Crowd Pummeler
}

function GQ.Data:IsDruidMeleeHasteForCaster(entry)
    if not entry or not entry.itemId then
        return false
    end
    if not self.DRUID_MELEE_HASTE_ITEMS[entry.itemId] then
        return false
    end
    if not entry.specs then
        return false
    end
    return entry.specs.balance or entry.specs.restoration
end

-- Rune Broker relics are sold by different NPCs per faction (ingest_forever_wowhead.py).
-- Generated itemFacts are keyed by itemId only, so Alliance broker copy must not
-- gate Horde lists at display time until the next re-score removes bad rows.
GQ.Data.RUNE_BROKER_ALLIANCE = {
    [205420] = true, [208849] = true, [208851] = true, [211472] = true,
}
GQ.Data.RUNE_BROKER_HORDE = {
    [206381] = true, [206382] = true, [206386] = true, [206387] = true,
    [206388] = true, [225838] = true,
}
GQ.Data.RUNE_BROKER_INSTRUCTIONS = {
    Alliance = "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, Elwynn Forest, Dun Morogh, and Teldrassil.",
    Horde = "Bought from Rune Broker in Orgrimmar, Thunder Bluff, Undercity, Durotar, Mulgore, and Tirisfal Glades.",
    Both = "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, Elwynn Forest, Dun Morogh, and Teldrassil, "
        .. "and in Orgrimmar, Thunder Bluff, Undercity, Durotar, Mulgore, and Tirisfal Glades.",
}

-- One-faction maps (mirrors pipeline ALLIANCE_MAPS / HORDE_MAPS). A pin in the
-- other faction's city is never shown, even when the spot was tagged wrong.
GQ.Data.FACTION_ZONE_DENY = {
    Alliance = {
        ["Valley of Trials"] = true, ["Durotar"] = true, ["Razor Hill"] = true, ["Orgrimmar"] = true,
        ["Mulgore"] = true, ["Camp Narache"] = true, ["Thunder Bluff"] = true, ["Deathknell"] = true,
        ["Tirisfal Glades"] = true, ["Brill"] = true, ["Undercity"] = true,
        ["Silverpine Forest"] = true, ["The Barrens"] = true, ["Camp Mojache"] = true,
    },
    Horde = {
        ["Northshire Valley"] = true, ["Elwynn Forest"] = true, ["Dun Morogh"] = true,
        ["Coldridge Valley"] = true, ["Kharanos"] = true, ["Teldrassil"] = true, ["Shadowglen"] = true,
        ["Darnassus"] = true, ["Ironforge"] = true, ["Stormwind City"] = true, ["Loch Modan"] = true,
        ["Westfall"] = true, ["Darkshore"] = true, ["Redridge Mountains"] = true, ["Duskwood"] = true,
    },
}

-- ignoreMapDeny is an open-world rare. Rohh patrols Redridge, and a Horde
-- player still needs that pin. Quest pins stay on the deny list.
function GQ.Data:SpotVisible(spot, faction, ignoreMapDeny)
    if not spot then
        return false
    end
    if not ignoreMapDeny then
        local deny = faction and self.FACTION_ZONE_DENY[faction]
        if deny and spot.map and deny[spot.map] then
            return false
        end
    end
    if spot.faction and spot.faction ~= "" and faction and spot.faction ~= faction then
        return false
    end
    return true
end

-- On-use AOE / novelty trinkets that are not real stat upgrades for leveling BiS.
GQ.Data.EXCLUDED_ITEMS = {
    [13515] = true, -- Ramstein's Lightning Bolts
}

function GQ.Data:IsExcludedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.EXCLUDED_ITEMS[entry.itemId] == true
end

function GQ.Data:EntryMatchesPlayerFaction(entry)
    if not entry then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    local itemId = entry.itemId
    if faction == "Horde" and itemId and self.RUNE_BROKER_ALLIANCE[itemId] then
        return false
    end
    if faction == "Alliance" and itemId and self.RUNE_BROKER_HORDE[itemId] then
        return false
    end

    -- Open-world rares stay listed for both factions. The patrol may sit in
    -- the other side's leveling zone (Rohh the Silent, Redridge Mountains).
    local zone = entry.zone
    if not entry.zoneOpen and entry.sourceType ~= "rare_npc" and zone and self.FACTION_ZONE_DENY[faction] and self.FACTION_ZONE_DENY[faction][zone] then
        return false
    end

    local locked = self.questFaction and entry.itemId and self.questFaction[entry.itemId]
    if locked and locked ~= faction then
        return false
    end

    -- A quest whose every pin is the other faction's city is not this side's quest.
    if entry.sourceType == "quest_reward" and entry.itemId and self.coordinates then
        local row = self.coordinates[entry.itemId]
        if row and row.spots and #row.spots > 0 then
            local any = false
            for i = 1, #row.spots do
                if self:SpotVisible(row.spots[i], faction) then
                    any = true
                    break
                end
            end
            if not any then
                return false
            end
        end
    end

    return true
end

function GQ.Data:GetEntryInstructions(entry)
    if not entry then
        return nil
    end

    local text = entry.instructions
    local itemId = entry.itemId
    if itemId and (self.RUNE_BROKER_ALLIANCE[itemId] or self.RUNE_BROKER_HORDE[itemId]) then
        local faction = GQ:GetEffectiveFaction()
        if self.RUNE_BROKER_ALLIANCE[itemId] and self.RUNE_BROKER_HORDE[itemId] then
            text = self.RUNE_BROKER_INSTRUCTIONS.Both
        elseif faction == "Horde" and self.RUNE_BROKER_HORDE[itemId] then
            text = self.RUNE_BROKER_INSTRUCTIONS.Horde
        else
            text = self.RUNE_BROKER_INSTRUCTIONS.Alliance
        end
    end

    return text
end

-- One coordinate under the source line. more=true, or a second spot the
-- viewer's faction can use, adds "more coordinates for this".
function GQ.Data:CoordinateLine(itemId)
    local row = self.coordinates and itemId and self.coordinates[itemId]
    if not row or not row.spots or #row.spots == 0 then
        return nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or nil
    local openWorld = row.note == "where this rare spawns" or row.note == "a farming spot"
    local mine = {}
    for i = 1, #row.spots do
        local spot = row.spots[i]
        if self:SpotVisible(spot, faction, openWorld) then
            mine[#mine + 1] = spot
        end
    end
    if #mine == 0 then
        return nil
    end
    local spot = mine[1]
    local line = string.format("Coordinates: %s %.1f, %.1f", spot.map or "", spot.x or 0, spot.y or 0)
    if #mine > 1 or row.more then
        line = line .. " more coordinates for this"
    end
    if row.note and row.note ~= "" then
        line = line .. " (" .. row.note .. ")"
    end
    return line
end

function GQ.Data:ShouldShowEntry(entry)
    if not entry or self:IsNoveltyProcItem(entry) or self:IsExcludedItem(entry) then
        return false
    end

    if self:IsHunterOnlyRangedItem(entry) and GQ:GetEffectiveClass() ~= "HUNTER" then
        return false
    end

    if self:IsDruidMeleeHasteForCaster(entry) then
        return false
    end

    if not self:EntryMatchesPlayerClass(entry) then
        return false
    end

    if not self:EntryMatchesPlayerFaction(entry) then
        return false
    end

    return true
end

GQ.Data.TIP_CLASS_NAMES = {
    Warrior = "WARRIOR", Paladin = "PALADIN", Hunter = "HUNTER",
    Rogue = "ROGUE", Priest = "PRIEST", Shaman = "SHAMAN",
    Mage = "MAGE", Warlock = "WARLOCK", Druid = "DRUID",
}

-- Longest first. Forever remakes often omit Classes: on a piece (Deathmist Robe).
GQ.Data.CLASS_SET_PREFIX = {
    {"beaststalker", "HUNTER"}, {"giantstalker", "HUNTER"}, {"dragonstalker", "HUNTER"},
    {"cryptstalker", "HUNTER"}, {"beastmaster", "HUNTER"},
    {"predator", "HUNTER"}, {"striker", "HUNTER"},
    {"deathmist", "WARLOCK"}, {"dreadmist", "WARLOCK"}, {"plagueheart", "WARLOCK"},
    {"felheart", "WARLOCK"}, {"demoniac", "WARLOCK"}, {"doomcaller", "WARLOCK"},
    {"nemesis", "WARLOCK"},
    {"netherwind", "MAGE"}, {"frostfire", "MAGE"}, {"illusionist", "MAGE"},
    {"sorcerer", "MAGE"}, {"arcanist", "MAGE"}, {"magister", "MAGE"}, {"enigma", "MAGE"},
    {"transcendence", "PRIEST"}, {"confessor", "PRIEST"}, {"prophecy", "PRIEST"},
    {"virtuous", "PRIEST"}, {"devout", "PRIEST"},
    {"nightslayer", "ROGUE"}, {"shadowcraft", "ROGUE"}, {"darkmantle", "ROGUE"},
    {"bonescythe", "ROGUE"}, {"deathdealer", "ROGUE"}, {"bloodfang", "ROGUE"},
    {"madcap", "ROGUE"},
    {"feralheart", "DRUID"}, {"dreamwalker", "DRUID"}, {"wildheart", "DRUID"},
    {"cenarion", "DRUID"}, {"stormrage", "DRUID"}, {"haruspex", "DRUID"},
    {"genesis", "DRUID"},
    {"lawbringer", "PALADIN"}, {"lightforge", "PALADIN"}, {"soulforge", "PALADIN"},
    {"freethinker", "PALADIN"}, {"redemption", "PALADIN"}, {"judgement", "PALADIN"},
    {"judgment", "PALADIN"}, {"avenger", "PALADIN"},
    {"earthshatter", "SHAMAN"}, {"stormcaller", "SHAMAN"}, {"earthfury", "SHAMAN"},
    {"augur", "SHAMAN"},
    {"dreadnaught", "WARRIOR"}, {"vindicator", "WARRIOR"}, {"conqueror", "WARRIOR"},
}

GQ.Data.CLASS_SET_SUFFIX = {
    {" of the gathering storm", "SHAMAN"},
    {" of the earthshatterer", "SHAMAN"},
    {" of the five thunders", "SHAMAN"},
    {" of the ten storms", "SHAMAN"},
    {" of the unseen path", "HUNTER"},
    {" of the oracle", "PRIEST"},
    {" of elements", "SHAMAN"},
    {" of heroism", "WARRIOR"},
    {" of valor", "WARRIOR"},
    {" of faith", "PRIEST"},
    {" of might", "WARRIOR"},
    {" of wrath", "WARRIOR"},
}

function GQ.Data:SetFamilyClass(name)
    if not name or name == "" then
        return nil
    end
    local lower = name:lower()
    for i = 1, #self.CLASS_SET_PREFIX do
        local row = self.CLASS_SET_PREFIX[i]
        if lower:sub(1, #row[1]) == row[1] then
            return row[2]
        end
    end
    for i = 1, #self.CLASS_SET_SUFFIX do
        local row = self.CLASS_SET_SUFFIX[i]
        if lower:sub(-#row[1]) == row[1] then
            return row[2]
        end
    end
    return nil
end

function GQ.Data:TipRequiredClasses(tip)
    if not tip or tip == "" then
        return nil
    end
    local pos = tip:find("Classes:", 1, true)
    if not pos then
        return nil
    end
    local after = tip:sub(pos + 8)
    local found = {}
    for word in after:gmatch("(%u%l+)") do
        local token = self.TIP_CLASS_NAMES[word]
        if not token then
            break
        end
        found[#found + 1] = token
    end
    if #found == 0 then
        return nil
    end
    return found
end

function GQ.Data:EntryMatchesPlayerClass(entry)
    if not entry or not entry.itemId then
        return true
    end
    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        return true
    end
    local audit = self:GetForeverAudit(entry.itemId)
    local family = self:SetFamilyClass((audit and audit.name) or entry.name)
    local required = family and { family } or self:TipRequiredClasses(audit and audit.tip)
    if not required then
        return true
    end
    for i = 1, #required do
        if required[i] == classFile then
            return true
        end
    end
    return false
end

function GQ.Data:GetTooltipScanner()
    if not self._tooltipScanner then
        self._tooltipScanner = CreateFrame("GameTooltip", "GearQuestTooltipScanner", UIParent, "GameTooltipTemplate")
    end
    return self._tooltipScanner
end

-- Craft skill from item tooltip ("Leatherworking (260)"), not equip level req.
local function StripTooltipText(text)
    text = GQ.PublicText(text)
    if not text then
        return ""
    end
    return text
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|A:.-|a", "")
        :gsub("|T.-|t", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

function GQ.Data:InvalidateCraftSkillCache(itemId)
    if not itemId or not self._craftSkillCache then
        return
    end
    self._craftSkillCache[itemId] = nil
end

-- BRD Chest of The Seven: boss reward chest after the Seven encounter, not a random world container.
local BOSS_CHEST_SEVEN = {
    sourceType = "boss_drop",
    instructions = "Drops from the Chest of The Seven after defeating the Seven in Blackrock Depths.",
    zone = "Blackrock Depths",
    npc = "The Seven",
}
GQ.Data.BOSS_CHEST_SOURCES = {
    [11921] = BOSS_CHEST_SEVEN,
    [11923] = BOSS_CHEST_SEVEN,
    [11925] = BOSS_CHEST_SEVEN,
    [11926] = BOSS_CHEST_SEVEN,
    [11927] = BOSS_CHEST_SEVEN,
    [11929] = BOSS_CHEST_SEVEN,
    [11945] = BOSS_CHEST_SEVEN,
    [11946] = BOSS_CHEST_SEVEN,
}

function GQ.Data:EnrichBossChestEntry(entry)
    if not entry or not entry.itemId then
        return entry
    end

    local override = self.BOSS_CHEST_SOURCES and self.BOSS_CHEST_SOURCES[entry.itemId]
    if not override then
        return entry
    end

    entry.sourceType = override.sourceType
    entry.instructions = override.instructions
    entry.zone = override.zone
    entry.npc = override.npc
    return entry
end

function GQ.Data:CacheTradeSkillRecipes()
    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillItemLink then
        return
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local num = GetNumTradeSkills()
    for i = 1, num do
        local _, skillType, _, _, skillLevel = GetTradeSkillInfo(i)
        if skillType ~= "header" and skillLevel and skillLevel > 0 then
            local link = GetTradeSkillItemLink(i)
            local itemId = link and self:ItemLinkToId(link)
            if itemId then
                self._craftSkillCache[itemId] = skillLevel
            end
        end
    end
end

function GQ.Data:CraftSkillFromText(text, profession)
    if not text or text == "" then
        return nil
    end
    if profession then
        local skill = tonumber(text:match(profession .. "%s*%((%d+)%)"))
        if skill and skill > 0 then
            return skill
        end
        skill = tonumber(text:match("requires skill (%d+)"))
        if skill and skill > 0 and text:find(profession, 1, true) then
            return skill
        end
    end
    local skill = tonumber(text:match("requires skill (%d+)"))
    if skill and skill > 0 then
        return skill
    end
    return nil
end

function GQ.Data:LookupProfessionCraftSkill(itemId, profession)
    if not itemId then
        return nil
    end

    if GQ.CraftSkills and GQ.CraftSkills[itemId] and GQ.CraftSkills[itemId].skill then
        return GQ.CraftSkills[itemId].skill
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local cached = self._craftSkillCache[itemId]
    if cached == false then
        return nil
    end
    if cached and cached > 0 then
        return cached
    end

    local audit = self:GetForeverAudit(itemId)
    local craftSkill = self:CraftSkillFromText(audit and audit.tip, profession)
    if craftSkill and craftSkill > 0 then
        self._craftSkillCache[itemId] = craftSkill
        return craftSkill
    end

    -- Item tooltips do not include recipe skill. Do not SetHyperlink-scan here:
    -- LoadGenerated used to do that for every profession row and hit
    -- "script ran too long".
    self._craftSkillCache[itemId] = false
    return nil
end

function GQ.Data:GetProfessionInstructions(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry and entry.instructions
    end

    local instructions = entry.instructions or ""
    local isBoP = GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(entry.itemId)
    -- BoE profession gear can be bought on the AH; only BoP must be self-crafted.
    if isBoP == false then
        return instructions
    end

    local craftSkill = self:LookupProfessionCraftSkill(entry.itemId, entry.profession)
    if craftSkill and craftSkill > 0 then
        local profession = entry.profession or "Profession"
        local head = string.format("Crafted with %s (requires skill %d).", profession, craftSkill)
        -- Keep the camp vendor sentence that follows "Crafted with …."
        local rest = instructions:match("^Crafted with [^.]*%.(.*)$")
        if rest and rest:find("%S") then
            return head .. rest
        end
        return head
    end

    return instructions
end

function GQ.Data:EnsureProfessionCraftSkillListener()
    if self._professionCraftSkillListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        if not itemId then
            return
        end

        GQ.Data:InvalidateCraftSkillCache(itemId)

        if GQ.Log and GQ.Log.frame and GQ.Log.frame:IsShown() then
            local entry = GQ.Log.selectedEntry
            if entry and entry.sourceType == "profession" and entry.itemId == itemId then
                if GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(itemId) then
                    GQ.Data:EnrichProfessionEntry(entry)
                    GQ.Log:ApplyEntryDetail(entry)
                end
            end
        end
    end)
    self._professionCraftSkillListener = frame
end

function GQ.Data:EnrichProfessionEntry(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry
    end

    local isBoP = GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(entry.itemId)
    if isBoP == false then
        return entry
    end

    self:EnsureProfessionCraftSkillListener()

    local instructions = self:GetProfessionInstructions(entry)
    if instructions then
        entry.instructions = instructions
    end

    return entry
end

function GQ.Data:CacheOwnedSuffixItemLink(entry, link)
    if not entry or not link then
        return
    end

    local key = self:EntryListKey(entry)
    if not key then
        return
    end

    self._ownedSuffixLinks = self._ownedSuffixLinks or {}
    self._ownedSuffixLinks[key] = link
end

function GQ.Data:GetCachedSuffixItemLink(entry)
    if not entry then
        return nil
    end

    local key = self:EntryListKey(entry)
    if not key then
        return nil
    end

    if self._ownedSuffixLinks and self._ownedSuffixLinks[key] then
        return self._ownedSuffixLinks[key]
    end

    return nil
end

function GQ.Data:FindCachedItemLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    local cached = self:GetCachedSuffixItemLink(entry)
    if cached then
        return cached
    end

    local function checkLink(link)
        if not link or self:ItemLinkToId(link) ~= entry.itemId then
            return nil
        end

        if entry.suffix and entry.suffix ~= "" then
            if not self:EntrySuffixMatchesLink(entry, link) then
                return nil
            end
        end

        self:CacheOwnedSuffixItemLink(entry, link)
        return link
    end

    for invSlot = 1, 19 do
        local link = checkLink(GetInventoryItemLink("player", invSlot))
        if link then
            return link
        end
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end

            link = checkLink(link)
            if link then
                return link
            end
        end
    end

    return nil
end

function GQ.Data:ExtractItemStringFromHyperlink(hyperlink)
    if not hyperlink or hyperlink == "" then
        return nil
    end

    local itemString = hyperlink:match("|H(item:[^|]+)|h")
    if itemString then
        return itemString
    end

    if hyperlink:match("^item:") then
        return hyperlink
    end

    return nil
end

function GQ.Data:SuffixIdFromLink(link)
    if not link then
        return nil
    end

    local itemString = self:ExtractItemStringFromHyperlink(link)
    if not itemString and link:match("^item:") then
        itemString = link
    end
    if not itemString then
        return nil
    end

    if strsplit then
        local id = tonumber(select(7, strsplit(":", itemString)))
        if id and id ~= 0 then
            return id
        end
        return nil
    end

    return self:ParseSuffixIdFromItemString(itemString)
end

function GQ.Data:ParseSuffixIdFromItemString(itemString)
    if not itemString then
        return nil
    end

    return tonumber(itemString:match("^item:%d+:0:0:0:0:0:(%-?%d+):"))
end

function GQ.Data:GetSuffixLinkLevel(entry)
    local fallback = GQ.MAX_PLAYER_LEVEL or 60
    if not entry then
        return fallback
    end

    if GetItemInfo and entry.itemId then
        local _, _, _, iLevel, reqLevel = GetItemInfo(entry.itemId)
        if iLevel and iLevel > 0 then
            return iLevel
        end
        if reqLevel and reqLevel > 0 then
            return reqLevel
        end
    end

    if entry.minLevel and entry.minLevel > 0 then
        return entry.minLevel
    end

    return fallback
end

-- Random enchant tooltips and completion use pipeline suffixId only.
-- Positive field-7 id = ItemRandomProperties (fixed tier lookup).
-- Negative field-7 id = ItemRandomSuffix (ilvl-scaled; factor in field 8).
function GQ.Data:MakeSuffixTargetLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if not entry.suffixId or entry.suffixId == 0 then
        return nil
    end

    if entry.suffixId < 0 then
        local factor = entry.suffixFactor or self:GetSuffixLinkLevel(entry)
        return string.format("item:%d:0:0:0:0:0:%d:%d:0", entry.itemId, entry.suffixId, factor)
    end

    return string.format("item:%d:0:0:0:0:0:%d:0:0", entry.itemId, entry.suffixId)
end

function GQ.Data:EntrySuffixMatchesLink(entry, link)
    if not entry or not link then
        return false
    end

    if self:ItemLinkToId(link) ~= entry.itemId then
        return false
    end

    if not entry.suffix or entry.suffix == "" then
        return true
    end

    -- The full green name is the hunt. "of the Bear" is not "of the Falcon",
    -- even though both share the base item id. A higher suffix id is a
    -- different enchant, not a better roll of this one.
    local fullName = self:ItemLinkFullName(link)
    local target = self:GetEntryDisplayName(entry)
    if fullName and target and not self:IsPlaceholderItemName(target, entry.itemId) then
        return fullName:lower() == self:NormalizeItemName(target):lower()
    end

    local rolledId = self:SuffixIdFromLink(link)
    if entry.suffixId and entry.suffixId ~= 0 and rolledId then
        return rolledId == entry.suffixId
    end

    return false
end

function GQ.Data:ResolveSuffixItemLink(entry)
    if not entry or not entry.suffix or entry.suffix == "" or not entry.itemId then
        return nil
    end

    self:EnrichEntrySuffix(entry)
    return self:MakeSuffixTargetLink(entry)
end

function GQ.Data:FormatSuffixRangeText(text)
    text = self:NormalizeItemName(text)
    if not text or text == "" then
        return nil
    end

    -- Pipeline keys first (longest match), then leftover "sp".
    text = text:gsub("spNature", "Nature Spell Power")
    text = text:gsub("spFire", "Fire Spell Power")
    text = text:gsub("spFrost", "Frost Spell Power")
    text = text:gsub("spShadow", "Shadow Spell Power")
    text = text:gsub("spArcane", "Arcane Spell Power")
    text = text:gsub("spHoly", "Holy Spell Power")
    text = text:gsub("(%d)%s+sp%f[%A]", "%1 Spell Power")
    return text
end

function GQ.Data:AppendSuffixRangeLines(tooltip, entry)
    if not tooltip or not entry or not entry.suffixRange or entry.suffixRange == "" then
        return
    end

    for part in string.gmatch(entry.suffixRange, "[^,]+") do
        local text = self:FormatSuffixRangeText(part)
        if text and text ~= "" then
            tooltip:AddLine(text, 0, 1, 0)
        end
    end
end

-- Forever often answers SetHyperlink(item:...:suffixId) with the BASE green
-- (name + armor only). The hunt text already has the roll; the tooltip must too.
function GQ.Data:TooltipShowsEntrySuffix(tooltip, entry)
    if not tooltip or not entry or not entry.suffix or entry.suffix == "" then
        return false
    end

    local name = tooltip.GetName and tooltip:GetName()
    local fs = name and _G[name .. "TextLeft1"]
    local title = GQ.PublicText(fs and fs.GetText and fs:GetText())
    if not title or title == "" then
        return false
    end

    local suffix = tostring(entry.suffix):gsub("^%s+", "")
    return title:lower():find(suffix:lower(), 1, true) ~= nil
end

function GQ.Data:GetItemQualityForDisplay(itemId)
    if not itemId then
        return nil
    end
    -- Forever quality wins (Reinforced Woolen Shoulders is green on Wowhead,
    -- but stale items.json still says common/white).
    local audit = self:GetForeverAudit(itemId)
    if audit and type(audit.quality) == "number" then
        return audit.quality
    end
    local quality = GQ.Equip and GQ.Equip.GetKnownItemQuality and GQ.Equip:GetKnownItemQuality(itemId)
    if type(quality) == "number" then
        return quality
    end
    local fact = self:GetItemFact(itemId)
    if fact and type(fact.quality) == "number" then
        return fact.quality
    end
    return nil
end

function GQ.Data:ShowLoadingItemTooltip(tooltip, entry)
    self:ShowFactFallbackTooltip(tooltip, entry)
end

function GQ.Data:ShowFactFallbackTooltip(tooltip, entry)
    if not tooltip or not entry then
        return
    end

    local displayName = self:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)

    local fact = self:GetItemFact(entry.itemId)
    local audit = self:GetForeverAudit(entry.itemId)
    if audit and audit.status == "missing" then
        tooltip:AddLine("Not found on Wowhead Forever", 1, 0.2, 0.2)
    end
    if audit and audit.tip and audit.tip ~= "" then
        local lines = self:ForeverTooltipLines(audit.tip)
        local clientSet = self:GetClientSetBlock(entry.itemId)
        if clientSet and clientSet.bonuses and #clientSet.bonuses > 0 then
            lines = self:ApplyClientSetBlock(lines, clientSet)
        end
        self:AddForeverTooltipLines(tooltip, lines, displayName, audit.name)
    else
        if entry.slot then
            tooltip:AddLine(entry.slot, 1, 1, 1)
        end
        if fact and fact.kind then
            tooltip:AddLine(fact.kind, 0.8, 0.8, 0.8)
        end
        local reqLevel = fact and fact.reqLevel
        if reqLevel and reqLevel > 0 then
            tooltip:AddLine("Requires Level " .. tostring(reqLevel), 1, 1, 1)
        end
        if fact and fact.stats then
            for stat, value in pairs(fact.stats) do
                if type(value) == "number" and value ~= 0 then
                    tooltip:AddLine(string.format("+%s %s", tostring(value), tostring(stat)), 0, 1, 0)
                end
            end
        end
        local instructions = self:GetEntryInstructions(entry) or (fact and fact.instructions)
        if instructions and instructions ~= "" then
            instructions = self:SanitizeText(instructions) or instructions
            tooltip:AddLine(" ")
            tooltip:AddLine(instructions, 0.8, 0.8, 0.8, true)
        end
    end
    self:AppendImbueOrProc(tooltip, entry)
    self:AppendSuffixRangeLines(tooltip, entry)
    self:AppendDatamineNotice(tooltip, entry)
end

function GQ.Data:ItemInfoIsReady(itemIdOrLink)
    if not itemIdOrLink or not GetItemInfo then
        return false
    end

    local itemId = tonumber(itemIdOrLink)
    if not itemId and type(itemIdOrLink) == "string" then
        itemId = self:ItemLinkToId(itemIdOrLink)
    end

    local cached = itemId and GQ.Equip and GQ.Equip.IsItemDataCached and GQ.Equip:IsItemDataCached(itemId)
    local name, _, quality = GetItemInfo(itemIdOrLink)
    if (not name or name == "") and itemId then
        name, _, quality = GetItemInfo(itemId)
    end
    if not name or name == "" then
        return false
    end
    if cached then
        return true
    end
    -- Stub GetItemInfo often returns quality 0 until the tooltip payload arrives.
    return type(quality) == "number" and quality > 0
end

function GQ.Data:TooltipLooksRetrieving(tooltip)
    if not tooltip then
        return false
    end

    local retrieving = RETRIEVING_ITEM_INFO or "Retrieving item information"
    local name = tooltip.GetName and tooltip:GetName()
    local lineCount = (tooltip.NumLines and tooltip:NumLines()) or 0
    for i = 1, math.min(lineCount, 5) do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text and (text == retrieving or text:find("Retrieving", 1, true)) then
            return true
        end
    end
    return false
end

function GQ.Data:SetTooltipItem(tooltip, itemIdOrLink)
    if not tooltip or not itemIdOrLink then
        return false
    end

    local ok
    if type(itemIdOrLink) == "number" then
        if tooltip.SetItemByID then
            ok = pcall(tooltip.SetItemByID, tooltip, itemIdOrLink)
            if ok and not self:TooltipLooksRetrieving(tooltip) then
                return true
            end
        end
        ok = pcall(tooltip.SetHyperlink, tooltip, "item:" .. itemIdOrLink)
        return ok == true
    end

    ok = pcall(tooltip.SetHyperlink, tooltip, itemIdOrLink)
    return ok == true
end

function GQ.Data:RefreshPendingTooltip(tooltip, entry, forceFallback)
    if not tooltip or not entry then
        return
    end
    if tooltip.gqItemInfoRefreshing then
        return
    end

    tooltip.gqItemInfoRefreshing = true
    if forceFallback then
        if not self:ShowForeverItemTooltip(tooltip, entry) then
            self:ShowFactFallbackTooltip(tooltip, entry)
        end
        self:ClearPendingItemTooltip(tooltip)
    else
        self:PopulateEntryItemTooltip(tooltip, entry)
    end
    if tooltip.Show then
        tooltip:Show()
    end
    if entry.itemId then
        self:ApplyImbueTooltipLines(tooltip, entry.itemId)
    end
    tooltip.gqItemInfoRefreshing = nil
end

function GQ.Data:EnsurePendingTooltipRefresh()
    if self._pendingTooltipRefresh then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId, success)
        itemId = tonumber(itemId)
        local pending = self._pendingItemTooltips
        if not pending then
            return
        end

        for tooltip, entry in pairs(pending) do
            if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
                pending[tooltip] = nil
            elseif entry and itemId and entry.itemId == itemId then
                self:InvalidateClientSetBlock(itemId)
                local failed = success == false and entry and entry.itemId == itemId
                self:RefreshPendingTooltip(tooltip, entry, failed)
            end
        end
    end)
    self._pendingTooltipRefresh = frame
end

function GQ.Data:EnsurePendingTooltipPoll()
end

function GQ.Data:TrackPendingItemTooltip(tooltip, entry)
    if not tooltip or not entry then
        return
    end

    self:EnsurePendingTooltipRefresh()
    self._pendingItemTooltips = self._pendingItemTooltips or {}
    self._pendingItemTooltips[tooltip] = entry
    if entry.itemId then
        self:RequestItemInfo(entry.itemId, true)
        local link = self:ResolveSuffixItemLink(entry)
        if link then
            self:RequestItemInfo(link, true)
        end
    end
end

function GQ.Data:ClearPendingItemTooltip(tooltip)
    self:HideImbueScrollTooltip()
    if self._pendingItemTooltips and tooltip then
        self._pendingItemTooltips[tooltip] = nil
    end
    if self._pendingTooltipStartedAt and tooltip then
        self._pendingTooltipStartedAt[tooltip] = nil
    end
end

function GQ.Data:TryShowSuffixTargetTooltip(tooltip, entry)
    if not tooltip or not entry then
        return false
    end

    self:EnrichEntrySuffix(entry)
    local link = self:MakeSuffixTargetLink(entry)
    if not link then
        return false
    end

    self:RequestItemInfo(link)
    if not self:ItemInfoIsReady(link) then
        return false
    end

    if not self:SetTooltipItem(tooltip, link) or self:TooltipLooksRetrieving(tooltip) then
        return false
    end
    return self:TooltipShowsEntrySuffix(tooltip, entry)
end

function GQ.Data:CopyTooltipLinesFromScanner(tooltip, scanner, skipTitle)
    local scannerName = scanner:GetName()
    local startLine = skipTitle and 2 or 1

    for i = startLine, scanner:NumLines() do
        local left = _G[scannerName .. "TextLeft" .. i]
        local right = _G[scannerName .. "TextRight" .. i]
        if left then
            local text = GQ.PublicText(left:GetText())
            if text then
                local lr, lg, lb = left:GetTextColor()
                if right then
                    local rightText = GQ.PublicText(right:GetText())
                    if rightText then
                        local rr, rg, rb = right:GetTextColor()
                        tooltip:AddDoubleLine(text, rightText, lr, lg, lb, rr, rg, rb)
                    else
                        tooltip:AddLine(text, lr, lg, lb)
                    end
                else
                    tooltip:AddLine(text, lr, lg, lb)
                end
            end
        end
    end
end

function GQ.Data:ShowSuffixFallbackTooltip(tooltip, entry)
    local itemId = entry.itemId
    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink("item:" .. itemId)

    local displayName = self:GetEntryDisplayName(entry)
    local _, _, quality = GetItemInfo(itemId)
    local r, g, b = GetItemQualityColor(quality or 1)

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)
    self:CopyTooltipLinesFromScanner(tooltip, scanner, true)
    self:AppendSuffixRangeLines(tooltip, entry)

    local suffixHint = self:GetSuffixHint(entry)
    if suffixHint then
        tooltip:AddLine(" ")
        tooltip:AddLine("Target random enchant: " .. suffixHint, 0.7, 0.9, 1)
    end
    self:AppendDatamineNotice(tooltip, entry)

    scanner:Hide()
end

function GQ.Data:GetEntryItemHyperlink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        self:EnrichEntrySuffix(entry)
        local link = self:MakeSuffixTargetLink(entry)
        if link then
            local _, itemHyperlink = GetItemInfo(link)
            if itemHyperlink and itemHyperlink ~= "" then
                return itemHyperlink
            end
            return link
        end
    end

    local _, itemHyperlink = GetItemInfo(entry.itemId)
    if itemHyperlink and itemHyperlink ~= "" then
        return itemHyperlink
    end

    return "item:" .. entry.itemId
end

function GQ.Data:ShowClientItemTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId then
        return false
    end
    if entry.suffix and entry.suffix ~= "" then
        return self:TryShowSuffixTargetTooltip(tooltip, entry)
    end
    if not self:SetTooltipItem(tooltip, entry.itemId) or self:TooltipLooksRetrieving(tooltip) then
        return false
    end
    return true
end

function GQ.Data:EntryUsesRebuiltTooltip(entry)
    if not entry then
        return false
    end
    -- Random-suffix greens keep the rebuilt jackpot tooltip.
    if entry.suffix and entry.suffix ~= "" then
        return true
    end
    -- A fixed green world drop or rare uses the Wowhead tip. A blue from a
    -- rare is not a jackpot green either.
    if entry.sourceType ~= "world_drop" and entry.sourceType ~= "rare_npc" then
        return false
    end
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    return quality == 2
end

function GQ.Data:AppendImbueCombineLine(tooltip, entry)
    if not tooltip or not entry then
        return
    end
    local info = self:ImbueInfo(entry.itemId)
    if not info then
        return
    end
    local line = self:ImbueCombineLine(info)
    if not line then
        return
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(line, 0, 1, 0, true)
end

function GQ.Data:ShowClientWaitTooltip(tooltip, entry, missing)
    local displayName = self:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end
    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)
    if missing then
        tooltip:AddLine("Not found in the client", 1, 0.2, 0.2)
    else
        tooltip:AddLine(RETRIEVING_ITEM_INFO or "Retrieving item information", 1, 1, 1)
    end
end

local SCORED_STAT_ORDER = {
    { key = "armor", label = "Armor" },
    { key = "str", label = "Strength" },
    { key = "agi", label = "Agility" },
    { key = "sta", label = "Stamina" },
    { key = "int", label = "Intellect" },
    { key = "spi", label = "Spirit" },
    { key = "sp", label = "Spell Power" },
    { key = "heal", label = "Healing" },
    { key = "ap", label = "Attack Power" },
}

function GQ.Data:TooltipPlainText(tooltip)
    if not tooltip or not tooltip.GetName or not tooltip.NumLines then
        return ""
    end
    local name = tooltip:GetName()
    local parts = {}
    for i = 1, tooltip:NumLines() or 0 do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text and text ~= "" then
            parts[#parts + 1] = text
        end
    end
    return table.concat(parts, "\n")
end

-- Items with no Wowhead tip still have the stats we score from. If the
-- client tooltip already printed them, leave it alone.
function GQ.Data:AppendScoredStatLines(tooltip, itemId)
    local row = self.scoredStats and itemId and self.scoredStats[itemId]
    if not tooltip or not row then
        return
    end
    local body = self:TooltipPlainText(tooltip):lower()
    for i = 1, #SCORED_STAT_ORDER do
        local spec = SCORED_STAT_ORDER[i]
        local value = row[spec.key]
        if type(value) == "number" and value ~= 0 and not body:find(spec.label:lower(), 1, true) then
            local line
            if spec.key == "armor" then
                line = string.format("%d Armor", value)
            elseif value > 0 then
                line = string.format("+%d %s", value, spec.label)
            else
                line = string.format("%d %s", value, spec.label)
            end
            local r, g, b = 0, 1, 0
            if value < 0 then
                r, g, b = 1, 0.2, 0.2
            end
            tooltip:AddLine(line, r, g, b)
            body = body .. "\n" .. spec.label:lower()
        end
    end
end

function GQ.Data:PopulateEntryItemTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId then
        return false
    end

    -- Green world drops keep the rebuilt jackpot tooltip. Every other item
    -- uses the Wowhead tip. A missing client item must not replace that hover.
    if self:EntryUsesRebuiltTooltip(entry) then
        if self:ShowForeverItemTooltip(tooltip, entry) then
            if self._pendingClientSet then
                self:TrackPendingItemTooltip(tooltip, entry)
            else
                self:ClearPendingItemTooltip(tooltip)
            end
            return true
        end

        if self:ShowClientItemTooltip(tooltip, entry) then
            self:ClearPendingItemTooltip(tooltip)
            return true
        end

        self:ShowFactFallbackTooltip(tooltip, entry)
        self:TrackPendingItemTooltip(tooltip, entry)
        return true
    end

    -- Quest, dungeon, and set pieces use the Wowhead tip. The client item
    -- is often missing until that level, and that must not replace the tip.
    if self:ShowForeverItemTooltip(tooltip, entry) then
        self:ClearPendingItemTooltip(tooltip)
        return true
    end

    -- No stored tip. The client tooltip has the armor and stats when the
    -- item is known. Scored stats fill in only the lines still missing.
    if self:ShowClientItemTooltip(tooltip, entry) and not self:TooltipLooksRetrieving(tooltip) then
        self:AppendScoredStatLines(tooltip, entry.itemId)
        self:ClearPendingItemTooltip(tooltip)
        return true
    end

    self:ShowFactFallbackTooltip(tooltip, entry)
    self:AppendScoredStatLines(tooltip, entry.itemId)
    self:ClearPendingItemTooltip(tooltip)
    return true
end

function GQ.Data:ShowEntryItemTooltip(tooltip, owner, entry, anchor, ...)
    if not tooltip or not entry or not entry.itemId then
        return
    end

    tooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT", ...)
    self:PopulateEntryItemTooltip(tooltip, entry)
    tooltip:Show()
    self:ApplyImbueTooltipLines(tooltip, entry.itemId)
end

function GQ.Data:CacheContainerItemLinks()
    if not self.byItemId then
        return
    end

    local function cacheLink(link)
        if not link then
            return
        end

        local itemId = self:ItemLinkToId(link)
        if not itemId then
            return
        end

        local itemName = self:ItemNameFromLink(link)
        if not itemName or not itemName:find(" of ", 1, true) then
            return
        end

        for _, entry in ipairs(self.byItemId[itemId] or {}) do
            if entry.suffix and self:EntrySuffixMatchesLink(entry, link) then
                self:CacheOwnedSuffixItemLink(entry, link)
            end
        end
    end

    for invSlot = 1, 19 do
        cacheLink(GetInventoryItemLink("player", invSlot))
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end
            cacheLink(link)
        end
    end
end

function GQ.Data:NormalizeItemName(name)
    if not name then
        return nil
    end

    if strtrim then
        return strtrim(name)
    end

    return (name:gsub("^%s*(.-)%s*$", "%1"))
end

function GQ.Data:ItemNameMatchesEntry(itemName, entry)
    if not itemName or not entry then
        return false
    end

    return self:NormalizeItemName(itemName) == self:GetEntryDisplayName(entry)
end

function GQ.Data:ItemLinkToId(link)
    if not link then
        return nil
    end

    return tonumber(link:match("item:(%d+)"))
end

function GQ.Data:ItemLinkFullName(link)
    if not link then
        return nil
    end

    local bracket = link:match("%[(.-)%]")
    if bracket and bracket ~= "" and not self:IsPlaceholderItemName(bracket) then
        return self:NormalizeItemName(bracket)
    end

    if GetItemInfo then
        local name = GetItemInfo(link)
        if type(name) == "string" and name ~= "" and not self:IsPlaceholderItemName(name) then
            return self:NormalizeItemName(name)
        end
    end

    return nil
end

function GQ.Data:ItemNameFromLink(link)
    if not link then
        return nil
    end

    local itemId = self:ItemLinkToId(link)
    if itemId then
        local name = self:GetItemDisplayName(itemId)
        if name then
            return name
        end
    end

    local bracket = link:match("%[(.-)%]")
    if bracket and not self:IsPlaceholderItemName(bracket, itemId) then
        return bracket
    end
    return nil
end

function GQ.Data:PlayerOwnsEntryItem(entry)
    if not entry or not entry.itemId then
        return false
    end

    self:EnrichEntrySuffix(entry)

    local itemId = entry.itemId
    local needsSuffix = entry.suffix and entry.suffix ~= ""

    local function linkMatches(link)
        if self:ItemLinkToId(link) ~= itemId then
            return false
        end

        if needsSuffix then
            return self:EntrySuffixMatchesLink(entry, link)
        end

        return true
    end

    local ok, owned = pcall(function()
        for invSlot = 1, 19 do
            if linkMatches(GetInventoryItemLink("player", invSlot)) then
                return true
            end
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots
            if C_Container and C_Container.GetContainerNumSlots then
                numSlots = C_Container.GetContainerNumSlots(bag) or 0
            elseif GetContainerNumSlots then
                numSlots = GetContainerNumSlots(bag) or 0
            else
                numSlots = 0
            end

            for slot = 1, numSlots do
                local link
                if C_Container and C_Container.GetContainerItemLink then
                    link = C_Container.GetContainerItemLink(bag, slot)
                elseif GetContainerItemLink then
                    link = GetContainerItemLink(bag, slot)
                end

                if linkMatches(link) then
                    return true
                end
            end
        end

        return false
    end)

    return ok and owned or false
end

function GQ.Data:GetEntryById(id)
    if not id then
        return nil
    end
    -- byId is built once login finishes. A miss is a stale saved hunt id.
    -- Walking self.entries here scans every generated row (about 467k) and
    -- the Completed tab does that once per slot, which trips "script ran too long".
    if self.byId then
        return self.byId[id] or self:GetNotableEntryById(id)
    end
    for _, entry in ipairs(self.entries or {}) do
        if entry.id == id then
            return entry
        end
    end
    return self:GetNotableEntryById(id)
end

function GQ.Data:InvalidatePlayerBandCache()
    self:InvalidateQueryCache()
end

function GQ.Data:InvalidateSpecCache()
    self._queryCache = nil
    self._activeBandCache = nil
end

function GQ.Data:InvalidateQueryCache()
    self._queryCache = nil
    self._activeBandCache = nil
    self._notableEntryCache = nil
    if GQ.Log and GQ.Log.InvalidateSourceFilterCache then
        GQ.Log:InvalidateSourceFilterCache()
    end
end

function GQ.Data:ScheduleQueryRefresh()
    self:InvalidateQueryCache()
    if self._queryRefreshScheduled then
        return
    end
    self._queryRefreshScheduled = true
    local function fire()
        self._queryRefreshScheduled = false
        if GQ.RefreshUI then
            GQ:RefreshUI()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, fire)
    else
        fire()
    end
end

-- Re-filter once GetItemInfo reports a real required level (unknown was allowed).
function GQ.Data:NotePendingRequiredLevel(itemId)
end

function GQ.Data:EnsureRequiredLevelListener()
    if self._requiredLevelListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        itemId = tonumber(itemId)
        local pending = GQ.Data._pendingRequiredLevel
        if not itemId or not pending or not pending[itemId] then
            return
        end
        pending[itemId] = nil
        GQ.Data:ScheduleQueryRefresh()
    end)
    self._requiredLevelListener = frame
end

function GQ.Data:InvalidateClassCache()
    self:InvalidateQueryCache()
    self.notableBySlot = nil
    self._notableBySlotClass = nil
end

function GQ.Data:GetQueryCacheKey()
    return self:GetActiveBandCacheKey()
end

function GQ.Data:EnsureQueryCache()
    local cacheKey = self:GetQueryCacheKey()
    if self._queryCache and self._queryCache.key == cacheKey then
        return
    end

    self._queryCache = {
        key = cacheKey,
        candidates = {},
        topUpgrades = {},
        notables = {},
        activeBandMin = nil,
    }
end

function GQ.Data:GetActiveBandCacheKey()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    return (GQ:GetEffectiveLevel() or 0) .. ":"
        .. (GQ:GetEffectiveClass() or "") .. ":"
        .. (GQ:GetEffectiveFaction() or "") .. ":"
        .. tostring(spec)
end

function GQ.Data:EntryMatchesPlayerBand(entry)
    if not entry or not entry.slot then
        return false
    end

    if not self:IsSlotUnlocked(entry.slot) then
        return false
    end

    local classFile = GQ:GetEffectiveClass()
    if entry.classes and not entry.classes[classFile] then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    if not GQ.Equip:EntryWithinLevelBand(entry) then
        return false
    end

    if GQ.Equip.EntryMatchesSpec and not GQ.Equip:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Data:EntryMatchesPlayer(entry)
    if not self:EntryMatchesPlayerBand(entry) then
        return false
    end

    -- Required level, class equip, and spec. Simulator uses GetEffectiveLevel.
    if not GQ.Equip:EntryMatchesItemRules(entry) then
        return false
    end

    return true
end

function GQ.Data:SelectActiveBand(entries, playerLevel)
    playerLevel = playerLevel or GQ:GetEffectiveLevel()
    local bestMinLevel
    local bestMaxLevel

    for _, entry in ipairs(entries or {}) do
        local minLevel = entry.minLevel or 1
        local maxLevel = entry.maxLevel or playerLevel
        if playerLevel >= minLevel and playerLevel <= maxLevel then
            if not bestMinLevel
                or minLevel > bestMinLevel
                or (minLevel == bestMinLevel and maxLevel < bestMaxLevel) then
                bestMinLevel = minLevel
                bestMaxLevel = maxLevel
            end
        end
    end

    if not bestMinLevel then
        -- Wide bands (e.g. seasonal head through level 8): fall back to highest minLevel reached.
        for _, entry in ipairs(entries or {}) do
            local minLevel = entry.minLevel or 1
            if playerLevel >= minLevel then
                if not bestMinLevel or minLevel > bestMinLevel then
                    bestMinLevel = minLevel
                    bestMaxLevel = nil
                end
            end
        end
    end

    return bestMinLevel, bestMaxLevel
end

function GQ.Data:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel)
    if not entry then
        return false
    end

    -- Forever hand-adds stay in the hunt for every overlapping generated band.
    -- Compare still caps the list at top 3 by score.
    if entry.foreverDelta then
        local playerLevel = GQ:GetEffectiveLevel()
        return playerLevel >= (entry.minLevel or 1)
            and playerLevel <= (entry.maxLevel or playerLevel)
    end

    if not activeMinLevel then
        return false
    end

    if (entry.minLevel or 1) ~= activeMinLevel then
        return false
    end

    if activeMaxLevel then
        return (entry.maxLevel or activeMaxLevel) == activeMaxLevel
    end

    return true
end

function GQ.Data:FilterToActiveBand(entries)
    if not entries or #entries == 0 then
        return entries
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(entries, playerLevel)

    if not activeMinLevel then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        if self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
            table.insert(filtered, entry)
        end
    end

    return filtered
end

function GQ.Data:EntryListKey(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        if entry.suffixId and entry.suffixId ~= 0 then
            return entry.itemId .. "\0" .. tostring(entry.suffixId)
        end
        return entry.itemId .. "\0" .. entry.suffix
    end

    return tostring(entry.itemId)
end

function GQ.Data:PreferEntry(a, b)
    if not a then
        return false
    end
    if not b then
        return true
    end

    if a.generated ~= b.generated then
        return not a.generated
    end

    local rankA = a.curatedRank or 99
    local rankB = b.curatedRank or 99
    if rankA ~= rankB then
        return rankA < rankB
    end

    return (a.minLevel or 0) > (b.minLevel or 0)
end

function GQ.Data:DeduplicateEntriesByItem(entries)
    local best = {}
    local order = {}

    for _, entry in ipairs(entries or {}) do
        local key = self:EntryListKey(entry)
        if key then
            local prev = best[key]
            if not prev then
                order[#order + 1] = key
                best[key] = entry
            elseif self:PreferEntry(entry, prev) then
                best[key] = entry
            end
        end
    end

    local results = {}
    for i = 1, #order do
        results[i] = best[order[i]]
    end

    return results
end

function GQ.Data:BackfillCandidates(allEntries, filtered, minCount)
    minCount = minCount or 3
    filtered = self:DeduplicateEntriesByItem(filtered)
    if not filtered or #filtered >= minCount then
        return filtered
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(allEntries, playerLevel)

    local seen = {}
    local seenItem = {}
    for _, entry in ipairs(filtered) do
        seen[entry.id] = true
        local key = self:EntryListKey(entry)
        if key then
            seenItem[key] = true
        end
    end

    local extras = {}
    for _, entry in ipairs(allEntries or {}) do
        if not seen[entry.id] and not entry.notable and self:ShouldShowEntry(entry)
            and self:EntryMatchesPlayer(entry) then
            local key = self:EntryListKey(entry)
            if key and not seenItem[key] and activeMinLevel
                and self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
                extras[#extras + 1] = entry
            end
        end
    end

    table.sort(extras, function(a, b)
        local rankA = a.curatedRank or 99
        local rankB = b.curatedRank or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return (a.minLevel or 0) > (b.minLevel or 0)
    end)

    for _, entry in ipairs(extras) do
        if #filtered >= minCount then
            break
        end
        local key = self:EntryListKey(entry)
        if key and not seenItem[key] then
            seen[entry.id] = true
            seenItem[key] = true
            filtered[#filtered + 1] = entry
        end
    end

    return self:DeduplicateEntriesByItem(filtered)
end

local NOTABLE_CLASS = {
    PALADIN = { rows = "paladinNotable", facts = "itemFacts" },
    WARRIOR = { rows = "warriorNotable", facts = "warriorItemFacts" },
    HUNTER  = { rows = "hunterNotable",  facts = "hunterItemFacts" },
    DRUID   = { rows = "druidNotable",   facts = "druidItemFacts" },
    SHAMAN  = { rows = "shamanNotable",  facts = "shamanItemFacts" },
    ROGUE   = { rows = "rogueNotable",   facts = "rogueItemFacts" },
    PRIEST  = { rows = "priestNotable",  facts = "priestItemFacts" },
    WARLOCK = { rows = "warlockNotable", facts = "warlockItemFacts" },
    MAGE    = { rows = "mageNotable",    facts = "mageItemFacts" },
}

local NOTABLE_SPECS = {
    PALADIN = {
        retribution = { retribution = true },
        protection = { protection = true },
        holy = { holy = true },
    },
    WARRIOR = {
        arms = { arms = true },
        fury = { fury = true },
        protection = { protection = true },
    },
    HUNTER = {
        beast_mastery = { beast_mastery = true },
        marksmanship  = { marksmanship  = true },
        survival      = { survival      = true },
    },
    DRUID = {
        bear        = { bear        = true },
        feral       = { feral       = true },
        balance     = { balance     = true },
        restoration = { restoration = true },
    },
    SHAMAN = {
        elemental   = { elemental   = true },
        enhancement = { enhancement = true },
        enhancement_tank = { enhancement_tank = true },
        restoration = { restoration = true },
    },
    ROGUE = {
        combat        = { combat        = true },
        assassination = { assassination = true },
        subtlety      = { subtlety      = true },
    },
    PRIEST = {
        holy       = { holy       = true },
        discipline = { discipline = true },
        shadow     = { shadow     = true },
    },
    WARLOCK = {
        affliction  = { affliction  = true },
        demonology  = { demonology  = true },
        destruction = { destruction = true },
    },
    MAGE = {
        frost  = { frost  = true },
        fire   = { fire   = true },
        arcane = { arcane = true },
    },
}

function GQ.Data:BuildNotableEntry(row, facts, classFile)
    if not row or not facts then
        return nil
    end

    local itemId, slot, minL, maxL = row[1], row[2], row[3], row[4]
    local spec, faction = row[5], row[6]
    local f = facts[itemId]
    if not f then
        return nil
    end

    if self:IsExcludedItem({ itemId = itemId, proc = f.proc }) then
        return nil
    end

    if f.proc then
        local probe = { itemId = itemId, proc = f.proc }
        if self:IsNoveltyProcItem(probe) then
            return nil
        end
    end

    local classTbl = { [classFile] = true }
    local specTbl = NOTABLE_SPECS[classFile]
    local FACTION = {
        Alliance = { Alliance = true },
        Horde = { Horde = true },
    }

    local entry = {
        id = string.format("notable:%s:%d:%s:%d:%s:%s", classFile, itemId, slot, minL, tostring(spec), tostring(faction)),
        itemId = itemId,
        slot = slot,
        minLevel = minL,
        maxLevel = maxL,
        classes = classTbl,
        specs = spec and specTbl and specTbl[spec] or nil,
        factions = faction and FACTION[faction] or nil,
        sourceType = f.sourceType,
        instructions = f.instructions,
        setPiece = f.setPiece,
        zone = f.zone,
        npc = f.npc,
        questName = f.questName,
        profession = f.profession,
        proc = f.proc,
        suffix = row.suffix,
        suffixChance = row.suffixChance,
        suffixId = row.suffixId,
        suffixRange = row.suffixRange,
        pipelineScore = self:LookupPipelineScore(itemId, slot, minL, faction, spec),
        generated = true,
        notable = true,
    }

    self._notableEntryCache = self._notableEntryCache or {}
    local cached = self._notableEntryCache[entry.id]
    if cached then
        return cached
    end

    entry = self:EnrichEntrySuffix(entry)
    entry = self:EnrichProfessionEntry(entry)
    self._notableEntryCache[entry.id] = entry
    return entry
end

function GQ.Data:AsMainBiSEntry(entry)
    if not entry or not entry.notable then
        return entry
    end

    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    copy.notable = false
    return copy
end

function GQ.Data:ShouldDisplayAsNotable(entry, slotName)
    if not entry or not entry.notable then
        return false
    end

    slotName = slotName and self:NormalizeSlotName(slotName)
    if not slotName then
        return true
    end

    local itemKey = self:EntryListKey(entry)
    if not itemKey then
        return true
    end

    for _, top in ipairs(self:GetTopUpgradesForSlot(slotName)) do
        if self:EntryListKey(top) == itemKey then
            return false
        end
    end

    return true
end

local function NormalizeEntryIdToken(value)
    if value == nil or value == "" or value == "nil" then
        return nil
    end
    return value
end

function GQ.Data:GetNotableEntryById(id)
    if type(id) ~= "string" or not id:match("^notable:") then
        return nil
    end

    local classFile, itemId, slot, minL, spec, faction = id:match(
        "^notable:([^:]+):(%d+):([^:]+):(%d+):([^:]*):([^:]*)$"
    )
    if not classFile then
        return nil
    end

    itemId = tonumber(itemId)
    minL = tonumber(minL)
    spec = NormalizeEntryIdToken(spec)
    faction = NormalizeEntryIdToken(faction)

    local src = NOTABLE_CLASS[classFile]
    if not src then
        return nil
    end

    local rows = self[src.rows]
    local facts = self[src.facts]
    if not rows or not facts then
        return nil
    end

    for i = 1, #rows do
        local row = rows[i]
        if row[1] == itemId
            and row[2] == slot
            and row[3] == minL
            and (row[5] or nil) == spec
            and (row[6] or nil) == faction then
            return self:BuildNotableEntry(row, facts, classFile)
        end
    end

    return nil
end

function GQ.Data:EnsureNotableBySlot(classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    if self._notableBySlotClass == classFile and self.notableBySlot then
        return
    end

    self._notableEntryCache = nil
    self.notableBySlot = {}
    self._notableBySlotClass = classFile

    local src = NOTABLE_CLASS[classFile]
    local rows = src and self[src.rows]
    if not rows then
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local slot = self:NormalizeSlotName(row[2])
        self.notableBySlot[slot] = self.notableBySlot[slot] or {}
        table.insert(self.notableBySlot[slot], row)
    end
end

function GQ.Data:GetNotableForSlot(slotName)
    local classFile = GQ:GetEffectiveClass()
    local src = NOTABLE_CLASS[classFile]
    if not src then
        return {}
    end

    local rows = self[src.rows]
    local facts = self[src.facts]
    if not rows or not facts then
        return {}
    end

    slotName = self:NormalizeSlotName(slotName)
    self:EnsureQueryCache()
    local cachedNotables = self._queryCache.notables[slotName]
    if cachedNotables then
        return cachedNotables
    end

    self:EnsureNotableBySlot(classFile)
    local slotRows = self.notableBySlot[slotName]
    if not slotRows then
        return {}
    end

    local results = {}
    for i = 1, #slotRows do
        local entry = self:BuildNotableEntry(slotRows[i], facts, classFile)
        if entry and self:ShouldShowEntry(entry) and self:EntryMatchesPlayer(entry) then
            table.insert(results, entry)
        end
    end

    results = self:FilterToActiveBand(results)
    results = self:DeduplicateEntriesByItem(results)
    self._queryCache.notables[slotName] = results
    return results
end

function GQ.Data:GetActiveBandMinLevel()
    local cacheKey = self:GetActiveBandCacheKey()
    if self._activeBandCache and self._activeBandCache.key == cacheKey then
        return self._activeBandCache.value
    end

    self:EnsureQueryCache()
    if self._queryCache.activeBandMin ~= nil then
        self._activeBandCache = { key = cacheKey, value = self._queryCache.activeBandMin }
        return self._queryCache.activeBandMin
    end

    local merged = {}
    for _, slotName in ipairs(self.BASE_SLOTS) do
        if self:IsSlotUnlocked(slotName) then
            local candidates = self:GetCandidatesForSlot(slotName)
            for i = 1, math.min(#candidates, 8) do
                merged[#merged + 1] = candidates[i]
            end
            if #merged >= 16 then
                break
            end
        end
    end

    local activeMinLevel = self:SelectActiveBand(merged)
    self._queryCache.activeBandMin = activeMinLevel
    self._activeBandCache = { key = cacheKey, value = activeMinLevel }
    return activeMinLevel
end

function GQ.Data:IsEntryNewForPlayer(entry)
    if not entry then
        return false
    end

    local activeMinLevel = self:GetActiveBandMinLevel()
    if not activeMinLevel then
        return false
    end

    return (entry.minLevel or 1) == activeMinLevel
end

-- Active-band candidates the player can equip now (required level uses GetEffectiveLevel).
function GQ.Data:GetCandidatesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    self:EnsureQueryCache()

    local cached = self._queryCache.candidates[slotName]
    if cached then
        return cached
    end

    local results = {}
    local seen = {}
    local equip = GQ.Equip
    local prevSuppress = equip and equip._suppressItemPrime
    if equip then
        equip._suppressItemPrime = true
    end

    for _, key in ipairs(self:GetCandidateSlotKeys(slotName)) do
        for _, entry in ipairs(self:GetClassSlotEntryList(key) or {}) do
            if not seen[entry.id] and self:ShouldShowEntry(entry) and self:EntryMatchesPlayer(entry) then
                seen[entry.id] = true
                table.insert(results, entry)
            end
        end
    end

    if equip then
        equip._suppressItemPrime = prevSuppress
    end

    local allMatching = results
    results = self:FilterToActiveBand(results)
    results = self:BackfillCandidates(allMatching, results, 3)
    results = self:DeduplicateEntriesByItem(results)
    self._queryCache.candidates[slotName] = results
    return results
end

GQ.Data.SLOT_LABELS = {
    Head = "Head",
    Neck = "Neck",
    Shoulder = "Shoulder",
    Back = "Back",
    Chest = "Chest",
    Wrist = "Wrist",
    Hands = "Hands",
    Waist = "Waist",
    Legs = "Legs",
    Feet = "Feet",
    Finger = "Finger",
    Trinket = "Trinket",
    MainHand = "Main Hand",
    SecondaryHand = "Off Hand",
    Ranged = "Ranged",
}

GQ.Data.BASE_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger", "Trinket",
    "MainHand", "SecondaryHand",
}

-- CharacterFrame slot buttons (Character{Name}Slot). Ranged is one UI slot for all
-- class relics: librams/relics, idols, totems, wands, bows/guns/crossbows.
GQ.Data.PAPER_DOLL_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
    "MainHand", "SecondaryHand", "Ranged",
}

GQ.Data.CLASS_RANGED = {
    WARRIOR = true,
    ROGUE = true,
    HUNTER = true,
    MAGE = true,
    PRIEST = true,
    WARLOCK = true,
    SHAMAN = true,
    PALADIN = true,
    DRUID = true,
}

-- GearQuest log/popup slots that unlock at specific character levels.
-- Milestone chat messages for these slots: see docs/DATA_RULES.md § Slot unlock & level-up messages.
GQ.Data.SLOT_UNLOCK_LEVEL = {
    Finger = 9,
    Shoulder = 9,
}

function GQ.Data:GetSlotUnlockLevel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    return self.SLOT_UNLOCK_LEVEL[slotName] or 1
end

function GQ.Data:IsSlotUnlocked(slotName)
    return GQ:GetEffectiveLevel() >= self:GetSlotUnlockLevel(slotName)
end

function GQ.Data:SlotHasHunts(slotName)
    local candidates = self:GetCandidatesForSlot(slotName)
    return candidates and #candidates > 0
end

function GQ.Data:GetSlotsForClass(classFile)
    local slots = {}
    local seen = {}

    for _, slotName in ipairs(self.BASE_SLOTS) do
        slotName = self:NormalizeSlotName(slotName)
        if not seen[slotName] and self:IsSlotUnlocked(slotName) and self:SlotHasHunts(slotName) then
            seen[slotName] = true
            table.insert(slots, slotName)
        end
    end

    if self.CLASS_RANGED[classFile] and not seen.Ranged and self:SlotHasHunts("Ranged") then
        table.insert(slots, "Ranged")
    end

    return slots
end

function GQ.Data:GetMaxUpgradesForSlot(slotName)
    return 3
end

function GQ.Data:RegisterPipelineScore(itemId, slot, minLevel, faction, spec, score)
    if not score then
        return
    end
    self._pipelineScoreLookup = self._pipelineScoreLookup or {}
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    self._pipelineScoreLookup[key] = score
end

function GQ.Data:LookupPipelineScore(itemId, slot, minLevel, faction, spec)
    if not self._pipelineScoreLookup then
        return nil
    end
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    return self._pipelineScoreLookup[key]
end

function GQ.Data:GetRankableEntriesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local merged = {}
    local seen = {}

    local function add(entry)
        if not entry or not entry.id or seen[entry.id] then
            return
        end
        seen[entry.id] = true
        merged[#merged + 1] = entry
    end

    for _, entry in ipairs(self:GetCandidatesForSlot(slotName)) do
        add(entry)
    end

    for _, entry in ipairs(self:GetNotableForSlot(slotName)) do
        add(entry)
    end

    return merged
end

function GQ.Data:GetTopUpgradesForSlot(slotName, maxResults)
    slotName = self:NormalizeSlotName(slotName)
    maxResults = maxResults or self:GetMaxUpgradesForSlot(slotName)
    self:EnsureQueryCache()

    local cacheKey = slotName .. ":" .. maxResults
    local cached = self._queryCache.topUpgrades[cacheKey]
    if cached then
        return cached
    end

    local candidates = {}
    for _, entry in ipairs(self:GetCandidatesForSlot(slotName)) do
        if not entry.reserve then
            candidates[#candidates + 1] = entry
        end
    end
    local ranked = GQ.Compare:RankEntries(candidates, slotName, maxResults)
    local results = {}
    for i = 1, #ranked do
        results[i] = self:AsMainBiSEntry(ranked[i])
    end
    self._queryCache.topUpgrades[cacheKey] = results
    return results
end

function GQ.Data:GetWeaponRouteForBand()
    for _, slot in ipairs({ "MainHand", "SecondaryHand" }) do
        for _, entry in ipairs(self:GetCandidatesForSlot(slot)) do
            if entry.route then
                return entry.route
            end
        end
    end
    return nil
end

local SHIELD_SPECS = {
    PALADIN = { protection = true, holy = true },
    WARRIOR = { protection = true },
    SHAMAN = { elemental = true, restoration = true, enhancement_tank = true },
}

local DUAL_WIELD_SPECS = {
    ROGUE = { combat = true, assassination = true, subtlety = true },
    WARRIOR = { fury = true },
}

local TWO_HAND_SPECS = {
    PALADIN = { retribution = true },
    WARRIOR = { arms = true },
}

-- The main-hand and off-hand lists stay separate. The main-hand header names
-- the choice. The off-hand header stays "Off Hand", and its rank 1 is the
-- piece that pairs with the one-hand (main-hand rank 2 when a staff is rank 1).
function GQ.Data:WeaponHeaderSuffix(slotName)
    local classFile = GQ:GetEffectiveClass()
    local spec = GQ:GetEffectiveSpec()
    if slotName == "Ranged" and classFile == "HUNTER" then
        return "Bow"
    end
    local shield = SHIELD_SPECS[classFile]
    if shield and shield[spec] then
        if slotName == "SecondaryHand" then
            return "Shield"
        end
        return nil
    end
    local dual = DUAL_WIELD_SPECS[classFile]
    if dual and dual[spec] then
        if slotName == "MainHand" then
            return "Dual wield"
        end
        return nil
    end
    local twoHand = TWO_HAND_SPECS[classFile]
    if twoHand and twoHand[spec] then
        if slotName == "MainHand" then
            return "Two-hand"
        end
        return nil
    end
    if classFile == "HUNTER" then
        if slotName == "MainHand" then
            return "Two-hand or dual wield"
        end
        return nil
    end
    if classFile == "SHAMAN" and spec == "enhancement" then
        if slotName == "MainHand" then
            return "Two-hand or main hand"
        end
        return nil
    end
    if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
        if slotName == "MainHand" then
            return "Staff or main hand"
        end
        return nil
    end
    if classFile == "DRUID" then
        if slotName == "MainHand" then
            return "Two-hand or main hand"
        end
        return nil
    end
    if slotName == "MainHand" and self:GetWeaponRouteForBand() then
        return "Two-hand or main hand"
    end
    return nil
end

function GQ.Data:EntryOffWeaponRoute(entry, slotName)
    if not entry or not entry.route then
        return false
    end
    slotName = self:NormalizeSlotName(slotName)
    if entry.route == "twohand" then
        return slotName == "SecondaryHand"
    end
    if entry.route == "onehand" and slotName == "MainHand" and GQ.Equip then
        return GQ.Equip:IsTwoHandWeapon(entry.itemId)
    end
    return false
end

function GQ.Data:SlotHeaderLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local label = self:SlotLabel(slotName)
    local routeLabel = self:WeaponHeaderSuffix(slotName)
    if routeLabel then
        if slotName == "Ranged" then
            return routeLabel
        end
        return label .. " — " .. routeLabel
    end
    return label
end

function GQ.Data:SlotLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Ranged" then
        local classFile = GQ:GetEffectiveClass()
        if classFile == "SHAMAN" then
            return "Totem"
        end
        if classFile == "DRUID" then
            return "Idol"
        end
        if classFile == "PALADIN" then
            return "Relic"
        end
        if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
            return "Wand"
        end
    end
    return self.SLOT_LABELS[slotName] or slotName
end
