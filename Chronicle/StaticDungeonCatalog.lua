-- Forever dungeon reference adapted from the user-installed AtlasLootContinued data-forever.lua.
-- Existing Chronicle quest and boss pages remain authoritative; missing data stays explicit.
local C = _G.Chronicle
local known = {}
for _, name in ipairs(C.dungeonKnowledgeOrder) do known[name] = true end
if not C.dungeonKnowledge["Ragefire Chasm"] then
    C.dungeonKnowledge["Ragefire Chasm"] = { level = "13-16", atlasSource = true, quests = {}, bosses = {
        { name = "Taragaman the Hungerer", loot = {
            {14149, "Subterranean Cape", ""},
            {14148, "Crystalline Cuffs", ""},
            {14145, "Cursed Felblade", ""},
        } },
        { name = "Jergosh the Invoker", loot = {
            {14150, "Robe of Evocation", ""},
            {14147, "Cavedweller Bracers", ""},
            {14151, "Chanting Blade", ""},
        } },
    } }
end
if not known["Ragefire Chasm"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Ragefire Chasm"
    known["Ragefire Chasm"] = true
end
if not C.dungeonKnowledge["Hall of Thanes"] then
    C.dungeonKnowledge["Hall of Thanes"] = { level = "13-18", atlasSource = true, quests = {}, bosses = {
        { name = "Faldrim Anvilmar", loot = {
            {270227, "Ephemeral Choker", ""},
            {271096, "Aetherwisp Bracers", ""},
            {271097, "Spiritwraith Drape", ""},
        } },
        { name = "Magmatus", loot = {
            {270230, "Kindlegem Girdle", ""},
            {270231, "Flamefist Grips", ""},
            {271095, "Fang of Magmatus", ""},
        } },
        { name = "Plunder", loot = {
            {270228, "Golemheart Stave", ""},
            {270229, "Treads of the Protector Golem", ""},
            {271098, "Golemguard Chest", ""},
        } },
        { name = "Durgen Dirgehammer", loot = {
            {270256, "Durgen's Crescent Axe", ""},
            {270260, "Direhammer Leggings", ""},
            {270261, "Robes of the Disgraced Thane", ""},
        } },
    } }
end
if not known["Hall of Thanes"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Hall of Thanes"
    known["Hall of Thanes"] = true
end
if not C.dungeonKnowledge["Ruins of Lordaeron"] then
    C.dungeonKnowledge["Ruins of Lordaeron"] = { level = "15-20", atlasSource = true, quests = {}, bosses = {
        { name = "Witherfang", loot = {
            {271202, "Witherbite Bracers", ""},
            {271201, "Atrophic Girdle", ""},
            {271203, "Segmented Spider Leg", ""},
        } },
        { name = "The Baron", loot = {
            {271206, "Leftover Abomination Skin", ""},
            {271205, "Abomination Bones", ""},
            {271204, "Meathook Slicer", ""},
        } },
        { name = "Viktor the Vile", loot = {
            {271212, "Bloodied Chestwraps", ""},
            {271211, "Vilewalkers", ""},
            {271218, "Vileblood Scimitar", ""},
        } },
        { name = "The Abandoned", loot = {
            {271207, "Rotmender's Leggings", ""},
            {271208, "Grip of Fear", ""},
            {271216, "Scepter of the Abandoned", ""},
        } },
        { name = "Bjork", loot = {
            {271210, "Tuskwrap Belt", ""},
            {271209, "Bonerust Leggings", ""},
            {271217, "Corpse Chopper", ""},
        } },
        { name = "Rath'mael", loot = {
            {271214, "Rotmender's Treads", ""},
            {271213, "Mirror of Rath'mael", ""},
            {271215, "Coldspire Staff", ""},
        } },
        { name = "Lordaeron Captain", loot = {
            {6642, "Phantom Armor", ""},
            {6641, "Haunting Blade", ""},
        } },
    } }
end
if not known["Ruins of Lordaeron"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Ruins of Lordaeron"
    known["Ruins of Lordaeron"] = true
end
if not C.dungeonKnowledge["Wailing Caverns"] then
    C.dungeonKnowledge["Wailing Caverns"] = { level = "17-21", atlasSource = true, quests = {}, bosses = {
        { name = "Lord Cobrahn", loot = {
            {6460, "Cobrahn's Grasp", ""},
            {10410, "Leggings of the Fang", ""},
            {6465, "Robe of the Moccasin", ""},
        } },
        { name = "Lady Anacondra", loot = {
            {10412, "Belt of the Fang", ""},
            {5404, "Serpent's Shoulders", ""},
            {6446, "Snakeskin Bag", ""},
        } },
        { name = "Kresh", loot = {
            {13245, "Kresh's Back", ""},
            {6447, "Worn Turtle Shell Shield", ""},
        } },
        { name = "Lord Pythas", loot = {
            {6472, "Stinging Viper", ""},
            {6473, "Armor of the Fang", ""},
        } },
        { name = "Skum", loot = {
            {6449, "Glowing Lizardscale Cloak", ""},
            {6448, "Tail Spike", ""},
        } },
        { name = "Lord Serpentis", loot = {
            {6469, "Venomstrike", ""},
            {5970, "Serpent Gloves", ""},
            {10411, "Footpads of the Fang", ""},
            {6459, "Savage Trodders", ""},
        } },
        { name = "Verdan the Everliving", loot = {
            {6630, "Seedcloud Buckler", ""},
            {6631, "Living Root", ""},
            {6629, "Sporid Cape", ""},
        } },
        { name = "Mutanus the Devourer", loot = {
            {6461, "Slime-encrusted Pads", ""},
            {6627, "Mutant Scale Breastplate", ""},
            {6463, "Deep Fathom Ring", ""},
            {10441, "Glowing Shard", ""},
        } },
        { name = "Deviate Faerie Dragon", loot = {
            {5243, "Firebelcher", ""},
            {6632, "Feyscale Cloak", ""},
        } },
        { name = "Trash", loot = {
            {10413, "Gloves of the Fang", ""},
        } },
    } }
end
if not known["Wailing Caverns"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Wailing Caverns"
    known["Wailing Caverns"] = true
end
if not C.dungeonKnowledge["The Deadmines"] then
    C.dungeonKnowledge["The Deadmines"] = { level = "18-22", atlasSource = true, quests = {}, bosses = {
        { name = "Rhahk'Zor", loot = {
            {872, "Rockslicer", ""},
            {5187, "Rhahk'Zor's Hammer", ""},
        } },
        { name = "Miner Johnson", loot = {
            {5443, "Gold-plated Buckler", ""},
            {5444, "Miner's Cape", ""},
        } },
        { name = "Sneed", loot = {
            {5194, "Taskmaster Axe", ""},
            {5195, "Gold-flecked Gloves", ""},
        } },
        { name = "Sneed's Shredder", loot = {
            {1937, "Buzz Saw", ""},
            {2169, "Buzzer Blade", ""},
        } },
        { name = "Gilnid", loot = {
            {1156, "Lavishly Jeweled Ring", ""},
            {5199, "Smelting Pants", ""},
        } },
        { name = "Mr. Smite", loot = {
            {7230, "Smite's Mighty Hammer", ""},
            {5192, "Thief's Blade", ""},
            {5196, "Smite's Reaver", ""},
        } },
        { name = "Captain Greenskin", loot = {
            {5201, "Emberstone Staff", ""},
            {10403, "Blackened Defias Belt", ""},
            {5200, "Impaling Harpoon", ""},
        } },
        { name = "Edwin VanCleef", loot = {
            {5193, "Cape of the Brotherhood", ""},
            {5202, "Corsair's Overshirt", ""},
            {10399, "Blackened Defias Armor", ""},
            {5191, "Cruel Barb", ""},
            {2874, "An Unsent Letter", ""},
        } },
        { name = "Cookie", loot = {
            {5198, "Cookie's Stirring Rod", ""},
            {5197, "Cookie's Tenderizer", ""},
            {8490, "Cat Carrier (Siamese)", ""},
        } },
        { name = "Defias Gunpowder", loot = {
            {5397, "Defias Gunpowder", ""},
        } },
        { name = "Trash Mobs", loot = {
            {8492, "Parrot Cage (Green Wing Macaw)", ""},
        } },
    } }
end
if not known["The Deadmines"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "The Deadmines"
    known["The Deadmines"] = true
end
if not C.dungeonKnowledge["Shadowfang Keep"] then
    C.dungeonKnowledge["Shadowfang Keep"] = { level = "18-21", atlasSource = true, quests = {}, bosses = {
        { name = "Rethilgore", loot = {
            {5254, "Rugged Spaulders", ""},
        } },
        { name = "Fel Steed / Shadow Charger", loot = {
            {6341, "Eerie Stable Lantern", ""},
            {932, "Fel Steed Saddlebags", ""},
        } },
        { name = "Razorclaw the Butcher", loot = {
            {1292, "Butcher's Cleaver", ""},
            {6226, "Bloody Apron", ""},
            {6633, "Butcher's Slicer", ""},
        } },
        { name = "Baron Silverlaine", loot = {
            {6321, "Silverlaine's Family Seal", ""},
            {6323, "Baron's Scepter", ""},
        } },
        { name = "Commander Springvale", loot = {
            {6320, "Commander's Crest", ""},
            {3191, "Arced War Axe", ""},
        } },
        { name = "Odo the Blindwatcher", loot = {
            {6318, "Odo's Ley Staff", ""},
            {6319, "Girdle of the Blindwatcher", ""},
        } },
        { name = "Deathsworn Captain", loot = {
            {6642, "Phantom Armor", ""},
            {6641, "Haunting Blade", ""},
        } },
        { name = "Arugal's Voidwalker", loot = {
            {5943, "Rift Bracers", ""},
        } },
        { name = "Fenrus the Devourer", loot = {
            {6340, "Fenrus' Hide", ""},
            {3230, "Black Wolf Bracers", ""},
        } },
        { name = "Wolf Master Nandos", loot = {
            {3748, "Feline Mantle", ""},
            {6314, "Wolfmaster Cape", ""},
        } },
        { name = "Archmage Arugal", loot = {
            {6324, "Robes of Arugal", ""},
            {6392, "Belt of Arugal", ""},
            {6220, "Meteor Shard", ""},
        } },
        { name = "Trash", loot = {
            {2292, "Necrology Robes", ""},
            {1489, "Gloomshroud Armor", ""},
            {1974, "Mindthrust Bracers", ""},
            {2807, "Guillotine Axe", ""},
            {1482, "Shadowfang", ""},
            {1935, "Assassin's Blade", ""},
            {1483, "Face Smasher", ""},
            {1318, "Night Reaver", ""},
            {3194, "Black Malice", ""},
            {2205, "Duskbringer", ""},
            {1484, "Witching Stave", ""},
        } },
        { name = "Sever", loot = {
            {23173, "Abomination Skin Leggings", ""},
            {23171, "The Axe of Severing", ""},
        } },
        { name = "Jordan's Smithing Hammer", loot = {
            {6895, "Jordan's Smithing Hammer", ""},
        } },
        { name = "The Book of Ur", loot = {
            {6283, "The Book of Ur", ""},
        } },
    } }
end
if not known["Shadowfang Keep"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Shadowfang Keep"
    known["Shadowfang Keep"] = true
end
if not C.dungeonKnowledge["Excavation Site: Wetlands"] then
    C.dungeonKnowledge["Excavation Site: Wetlands"] = { level = "26-31", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["Excavation Site: Wetlands"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Excavation Site: Wetlands"
    known["Excavation Site: Wetlands"] = true
end
if not C.dungeonKnowledge["Blackfathom Deeps"] then
    C.dungeonKnowledge["Blackfathom Deeps"] = { level = "22-24", atlasSource = true, quests = {}, bosses = {
        { name = "Ghamoo-ra", loot = {
            {6907, "Tortoise Armor", ""},
            {6908, "Ghamoo-ra's Bind", ""},
        } },
        { name = "Lady Sarevess", loot = {
            {888, "Naga Battle Gloves", ""},
            {3078, "Naga Heartpiercer", ""},
            {11121, "Darkwater Talwar", ""},
        } },
        { name = "Gelihast", loot = {
            {6906, "Algae Fists", ""},
            {6905, "Reef Axe", ""},
            {1470, "Murloc Skin Bag", ""},
        } },
        { name = "Baron Aquanis", loot = {
            {16782, "Strange Water Globe", ""},
        } },
        { name = "Twilight Lord Kelris", loot = {
            {1155, "Rod of the Sleepwalker", ""},
            {6903, "Gaze Dreamer Pants", ""},
        } },
        { name = "Old Serra'kis", loot = {
            {6901, "Glowing Thresher Cape", ""},
            {6904, "Bite of Serra'kis", ""},
            {6902, "Bands of Serra'kis", ""},
        } },
        { name = "Aku'mai", loot = {
            {6911, "Moss Cinch", ""},
            {6910, "Leech Pants", ""},
            {6909, "Strike of the Hydra", ""},
        } },
        { name = "Trash", loot = {
            {1486, "Tree Bark Jacket", ""},
            {3416, "Martyr's Chain", ""},
            {1491, "Ring of Precision", ""},
            {3414, "Crested Scepter", ""},
            {1454, "Axe of the Enforcer", ""},
            {1481, "Grimclaw", ""},
            {2567, "Evocator's Blade", ""},
            {3413, "Doomspike", ""},
            {3417, "Onyx Claymore", ""},
            {3415, "Staff of the Friar", ""},
            {2271, "Staff of the Blessed Seer", ""},
        } },
    } }
end
if not known["Blackfathom Deeps"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Blackfathom Deeps"
    known["Blackfathom Deeps"] = true
end
if not C.dungeonKnowledge["Stormwind Stockade"] then
    C.dungeonKnowledge["Stormwind Stockade"] = { level = "23-29", atlasSource = true, quests = {}, bosses = {
        { name = "Kam Deepfury", loot = {
            {2280, "Kam's Walking Stick", ""},
        } },
        { name = "Bruegal Ironknuckle", loot = {
            {3228, "Jimmied Handcuffs", ""},
            {2941, "Prison Shank", ""},
            {2942, "Iron Knuckles", ""},
        } },
        { name = "Trash", loot = {
            {1076, "Defias Renegade Ring", ""},
        } },
    } }
end
if not known["Stormwind Stockade"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Stormwind Stockade"
    known["Stormwind Stockade"] = true
end
if not C.dungeonKnowledge["Scarlet Monastery: Graveyard"] then
    C.dungeonKnowledge["Scarlet Monastery: Graveyard"] = { level = "30-32", atlasSource = true, quests = {}, artName = "Scarlet Monastery", bosses = {
        { name = "Interrogator Vishas", loot = {
            {7682, "Torturing Poker", ""},
            {7683, "Bloody Brass Knuckles", ""},
        } },
        { name = "Azshir the Sleepless", loot = {
            {7709, "Blighted Leggings", ""},
            {7708, "Necrotic Wand", ""},
            {7731, "Ghostshard Talisman", ""},
        } },
        { name = "Fallen Champion", loot = {
            {7691, "Embalmed Shroud", ""},
            {7690, "Ebon Vise", ""},
            {7689, "Morbid Dawn", ""},
        } },
        { name = "Ironspine", loot = {
            {7688, "Ironspine's Ribcage", ""},
            {7687, "Ironspine's Fist", ""},
            {7686, "Ironspine's Eye", ""},
        } },
        { name = "Bloodmage Thalnos", loot = {
            {7685, "Orb of the Forgotten Seer", ""},
            {7684, "Bloodmage Mantle", ""},
        } },
        { name = "Trash", loot = {
            {5819, "Sunblaze Coif", ""},
            {7727, "Watchman Pauldrons", ""},
            {7728, "Beguiler Robes", ""},
            {7754, "Harbinger Boots", ""},
            {10332, "Scarlet Boots", ""},
            {2262, "Mark of Kern", ""},
            {7787, "Resplendent Guardian", ""},
            {7729, "Chesterfall Musket", ""},
            {7761, "Steelclaw Reaver", ""},
            {7752, "Dreamslayer", ""},
            {8226, "The Butcher", ""},
            {7786, "Headsplitter", ""},
            {7753, "Bloodspiller", ""},
            {7730, "Cobalt Crusher", ""},
        } },
        { name = "Scorn", loot = {
            {23169, "Scorn's Icy Choker", ""},
            {23170, "The Frozen Clutch", ""},
            {23168, "Scorn's Focal Dagger", ""},
        } },
    } }
end
if not known["Scarlet Monastery: Graveyard"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Scarlet Monastery: Graveyard"
    known["Scarlet Monastery: Graveyard"] = true
end
if not C.dungeonKnowledge["City of Dalaran"] then
    C.dungeonKnowledge["City of Dalaran"] = { level = "28-33", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["City of Dalaran"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "City of Dalaran"
    known["City of Dalaran"] = true
end
if not C.dungeonKnowledge["Razorfen Kraul"] then
    C.dungeonKnowledge["Razorfen Kraul"] = { level = "24-27", atlasSource = true, quests = {}, bosses = {
        { name = "Aggem Thorncurse", loot = {
            {6681, "Thornspike", ""},
        } },
        { name = "Death Speaker Jargba", loot = {
            {2816, "Death Speaker Scepter", ""},
            {6685, "Death Speaker Mantle", ""},
            {6682, "Death Speaker Robes", ""},
        } },
        { name = "Overlord Ramtusk", loot = {
            {6687, "Corpsemaker", ""},
            {6686, "Tusken Helm", ""},
        } },
        { name = "Razorfen Spearhide", loot = {
            {6679, "Armor Piercer", ""},
        } },
        { name = "Agathelos the Raging", loot = {
            {6691, "Swinetusk Shank", ""},
            {6690, "Ferine Leggings", ""},
        } },
        { name = "Blind Hunter", loot = {
            {6695, "Stygian Bone Amulet", ""},
            {6697, "Batwing Mantle", ""},
            {6696, "Nightstalker Bow", ""},
        } },
        { name = "Charlga Razorflank", loot = {
            {6693, "Agamaggan's Clutch", ""},
            {6694, "Heart of Agamaggan", ""},
            {6692, "Pronged Reaver", ""},
            {17008, "Small Scroll", ""},
        } },
        { name = "Earthcaller Halmgar", loot = {
            {6689, "Wind Spirit Staff", ""},
            {6688, "Whisperwind Headdress", ""},
        } },
        { name = "Trash", loot = {
            {2264, "Mantle of Thieves", ""},
            {1488, "Avenger's Armor", ""},
            {4438, "Pugilist Bracers", ""},
            {1978, "Wolfclaw Gloves", ""},
            {2039, "Plains Ring", ""},
            {1727, "Sword of Decay", ""},
            {776, "Vendetta", ""},
            {1976, "Slaghammer", ""},
            {1975, "Pysan's Old Greatsword", ""},
            {2549, "Staff of the Shade", ""},
        } },
    } }
end
if not known["Razorfen Kraul"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Razorfen Kraul"
    known["Razorfen Kraul"] = true
end
if not C.dungeonKnowledge["Gnomeregan"] then
    C.dungeonKnowledge["Gnomeregan"] = { level = "25-28", atlasSource = true, quests = {}, bosses = {
        { name = "Techbot", loot = {
            {9444, "Techbot CPU Shell", ""},
        } },
        { name = "Grubbis", loot = {
            {9445, "Grubbis Paws", ""},
        } },
        { name = "Viscous Fallout", loot = {
            {9454, "Acidic Walkers", ""},
            {9453, "Toxic Revenger", ""},
            {9452, "Hydrocane", ""},
        } },
        { name = "Electrocutioner 6000", loot = {
            {9447, "Electrocutioner Lagnut", ""},
            {9446, "Electrocutioner Leg", ""},
            {9448, "Spidertank Oilrag", ""},
            {6893, "Workshop Key", ""},
        } },
        { name = "Crowd Pummeler 9-60", loot = {
            {9449, "Manual Crowd Pummeler", ""},
            {9450, "Gnomebot Operating Boots", ""},
        } },
        { name = "Dark Iron Ambassador", loot = {
            {9455, "Emissary Cuffs", ""},
            {9456, "Glass Shooter", ""},
            {9457, "Royal Diplomatic Scepter", ""},
        } },
        { name = "Mekgineer Thermaplugg", loot = {
            {9492, "Electromagnetic Gigaflux Reactivator", ""},
            {9461, "Charged Gear", ""},
            {9458, "Thermaplugg's Central Core", ""},
            {9459, "Thermaplugg's Left Arm", ""},
            {4415, "Schematic: Craftsman's Monocle", ""},
            {4413, "Schematic: Discombobulator Ray", ""},
            {4411, "Schematic: Flame Deflector", ""},
            {7742, "Schematic: Gnomish Cloaking Device", ""},
            {11828, "Schematic: Pet Bombling", ""},
        } },
        { name = "Trash", loot = {
            {9508, "Mechbuilder's Overalls", ""},
            {9491, "Hotshot Pilot's Gloves", ""},
            {9509, "Petrolspill Leggings", ""},
            {9510, "Caverndeep Trudgers", ""},
            {9487, "Hi-tech Supergun", ""},
            {9485, "Vibroblade", ""},
            {9488, "Oscillating Power Hammer", ""},
            {9486, "Supercharger Battle Axe", ""},
            {9490, "Gizmotron Megachopper", ""},
            {9489, "Gyromatic Icemaker", ""},
            {11827, "Schematic: Lil' Smoky", ""},
            {9327, "Security DELTA Data Access Card", ""},
            {7191, "Fused Wiring", ""},
            {9308, "Grime-Encrusted Object", ""},
            {9326, "Grime-Encrusted Ring", ""},
            {9279, "White Punch Card", ""},
            {9280, "Yellow Punch Card", ""},
            {9282, "Blue Punch Card", ""},
            {9281, "Red Punch Card", ""},
            {9316, "Prismatic Punch Card", ""},
        } },
    } }
end
if not known["Gnomeregan"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Gnomeregan"
    known["Gnomeregan"] = true
end
if not C.dungeonKnowledge["Scarlet Monastery: Library"] then
    C.dungeonKnowledge["Scarlet Monastery: Library"] = { level = "33-35", atlasSource = true, quests = {}, artName = "Scarlet Monastery", bosses = {
        { name = "Houndmaster Loksey", loot = {
            {7710, "Loksey's Training Stick", ""},
            {7756, "Dog Training Gloves", ""},
            {3456, "Dog Whistle", ""},
        } },
        { name = "Arcanist Doan", loot = {
            {7714, "Hypnotic Blade", ""},
            {7713, "Illusionary Rod", ""},
            {7712, "Mantle of Doan", ""},
            {7711, "Robe of Doan", ""},
        } },
        { name = "Trash", loot = {
            {5819, "Sunblaze Coif", ""},
            {7755, "Flintrock Shoulders", ""},
            {7727, "Watchman Pauldrons", ""},
            {7728, "Beguiler Robes", ""},
            {7759, "Archon Chestpiece", ""},
            {7760, "Warchief Kilt", ""},
            {7754, "Harbinger Boots", ""},
            {10332, "Scarlet Boots", ""},
            {1992, "Swampchill Fetish", ""},
            {2262, "Mark of Kern", ""},
            {7787, "Resplendent Guardian", ""},
            {7729, "Chesterfall Musket", ""},
            {7761, "Steelclaw Reaver", ""},
            {7752, "Dreamslayer", ""},
            {8226, "The Butcher", ""},
            {7786, "Headsplitter", ""},
            {5756, "Sliverblade", ""},
            {7736, "Fight Club", ""},
            {8225, "Tainted Pierce", ""},
            {7753, "Bloodspiller", ""},
            {7730, "Cobalt Crusher", ""},
            {7758, "Ruthless Shiv", ""},
            {7757, "Windweaver Staff", ""},
        } },
        { name = "Doan's Strongbox", loot = {
            {7146, "The Scarlet Key", ""},
        } },
    } }
end
if not known["Scarlet Monastery: Library"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Scarlet Monastery: Library"
    known["Scarlet Monastery: Library"] = true
end
if not C.dungeonKnowledge["Scarlet Monastery: Armory"] then
    C.dungeonKnowledge["Scarlet Monastery: Armory"] = { level = "35-37", atlasSource = true, quests = {}, artName = "Scarlet Monastery", bosses = {
        { name = "Herod", loot = {
            {7719, "Raging Berserker's Helm", ""},
            {7718, "Herod's Shoulder", ""},
            {10330, "Scarlet Leggings", ""},
            {7717, "Ravager", ""},
        } },
        { name = "Trash", loot = {
            {5819, "Sunblaze Coif", ""},
            {7755, "Flintrock Shoulders", ""},
            {7727, "Watchman Pauldrons", ""},
            {7728, "Beguiler Robes", ""},
            {7759, "Archon Chestpiece", ""},
            {7754, "Harbinger Boots", ""},
            {10332, "Scarlet Boots", ""},
            {1992, "Swampchill Fetish", ""},
            {2262, "Mark of Kern", ""},
            {7787, "Resplendent Guardian", ""},
            {7729, "Chesterfall Musket", ""},
            {7761, "Steelclaw Reaver", ""},
            {7752, "Dreamslayer", ""},
            {8226, "The Butcher", ""},
            {7786, "Headsplitter", ""},
            {5756, "Sliverblade", ""},
            {7736, "Fight Club", ""},
            {8225, "Tainted Pierce", ""},
            {7753, "Bloodspiller", ""},
            {7730, "Cobalt Crusher", ""},
            {7757, "Windweaver Staff", ""},
            {10333, "Scarlet Wristguards", ""},
            {10329, "Scarlet Belt", ""},
            {23192, "Tabard of the Scarlet Crusade", ""},
        } },
    } }
end
if not known["Scarlet Monastery: Armory"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Scarlet Monastery: Armory"
    known["Scarlet Monastery: Armory"] = true
end
if not C.dungeonKnowledge["The Drowned City"] then
    C.dungeonKnowledge["The Drowned City"] = { level = "35-40", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["The Drowned City"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "The Drowned City"
    known["The Drowned City"] = true
end
if not C.dungeonKnowledge["Scarlet Monastery: Cathedral"] then
    C.dungeonKnowledge["Scarlet Monastery: Cathedral"] = { level = "36-40", atlasSource = true, quests = {}, artName = "Scarlet Monastery", bosses = {
        { name = "High Inquisitor Fairbanks", loot = {
            {19507, "Inquisitor's Shawl", ""},
            {19508, "Branded Leather Bracers", ""},
            {19509, "Dusty Mail Boots", ""},
        } },
        { name = "Scarlet Commander Mograine", loot = {
            {7724, "Gauntlets of Divinity", ""},
            {10330, "Scarlet Leggings", ""},
            {7726, "Aegis of the Scarlet Commander", ""},
            {7723, "Mograine's Might", ""},
        } },
        { name = "High Inquisitor Whitemane", loot = {
            {7720, "Whitemane's Chapeau", ""},
            {7722, "Triune Amulet", ""},
            {7721, "Hand of Righteousness", ""},
        } },
        { name = "Trash", loot = {
            {5819, "Sunblaze Coif", ""},
            {7755, "Flintrock Shoulders", ""},
            {7727, "Watchman Pauldrons", ""},
            {7728, "Beguiler Robes", ""},
            {7759, "Archon Chestpiece", ""},
            {7760, "Warchief Kilt", ""},
            {7754, "Harbinger Boots", ""},
            {10332, "Scarlet Boots", ""},
            {1992, "Swampchill Fetish", ""},
            {2262, "Mark of Kern", ""},
            {7787, "Resplendent Guardian", ""},
            {7729, "Chesterfall Musket", ""},
            {7761, "Steelclaw Reaver", ""},
            {7752, "Dreamslayer", ""},
            {8226, "The Butcher", ""},
            {7786, "Headsplitter", ""},
            {5756, "Sliverblade", ""},
            {7736, "Fight Club", ""},
            {8225, "Tainted Pierce", ""},
            {7753, "Bloodspiller", ""},
            {7730, "Cobalt Crusher", ""},
            {7758, "Ruthless Shiv", ""},
            {7757, "Windweaver Staff", ""},
            {10328, "Scarlet Chestpiece", ""},
            {10331, "Scarlet Gauntlets", ""},
            {10329, "Scarlet Belt", ""},
        } },
    } }
end
if not known["Scarlet Monastery: Cathedral"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Scarlet Monastery: Cathedral"
    known["Scarlet Monastery: Cathedral"] = true
end
if not C.dungeonKnowledge["Razorfen Downs"] then
    C.dungeonKnowledge["Razorfen Downs"] = { level = "25+", atlasSource = true, quests = {}, bosses = {
        { name = "Tuten'kash", loot = {
            {10776, "Silky Spider Cape", ""},
            {10775, "Carapace of Tuten'kash", ""},
            {10777, "Arachnid Gloves", ""},
        } },
        { name = "Mordresh Fire Eye", loot = {
            {10769, "Glowing Eye of Mordresh", ""},
            {10771, "Deathmage Sash", ""},
            {10770, "Mordresh's Lifeless Skull", ""},
        } },
        { name = "Glutton", loot = {
            {10774, "Fleshhide Shoulders", ""},
            {10772, "Glutton's Cleaver", ""},
        } },
        { name = "Ragglesnout", loot = {
            {10768, "Boar Champion's Belt", ""},
            {10767, "Savage Boar's Guard", ""},
            {10758, "X'caliboar", ""},
        } },
        { name = "Amnennar the Coldbringer", loot = {
            {10763, "Icemetal Barbute", ""},
            {10762, "Robes of the Lich", ""},
            {10764, "Deathchill Armor", ""},
            {10761, "Coldrage Dagger", ""},
            {10765, "Bonefingers", ""},
        } },
        { name = "Plaguemaw the Rotting", loot = {
            {10766, "Plaguerot Sprig", ""},
            {10760, "Swine Fists", ""},
        } },
        { name = "Trash", loot = {
            {10574, "Corpseshroud", ""},
            {10581, "Death's Head Vestment", ""},
            {10583, "Quillward Harness", ""},
            {10584, "Stormgale Fists", ""},
            {10578, "Thoughtcast Boots", ""},
            {10582, "Briar Tredders", ""},
            {10572, "Freezing Shard", ""},
            {10567, "Quillshooter", ""},
            {10571, "Ebony Boneclub", ""},
            {10570, "Manslayer", ""},
            {10573, "Boneslasher", ""},
        } },
        { name = "Lady Falther'ess", loot = {
            {23178, "Mantle of Lady Falther'ess", ""},
            {23177, "Lady Falther'ess' Finger", ""},
        } },
        { name = "Henry Stern", loot = {
            {3826, "Mighty Troll's Blood Potion", ""},
            {10841, "Goldthorn Tea", ""},
        } },
    } }
end
if not known["Razorfen Downs"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Razorfen Downs"
    known["Razorfen Downs"] = true
end
if not C.dungeonKnowledge["Krol'dok Stronghold"] then
    C.dungeonKnowledge["Krol'dok Stronghold"] = { level = "40-45", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["Krol'dok Stronghold"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Krol'dok Stronghold"
    known["Krol'dok Stronghold"] = true
end
if not C.dungeonKnowledge["Uldaman"] then
    C.dungeonKnowledge["Uldaman"] = { level = "30+", atlasSource = true, quests = {}, bosses = {
        { name = "Baelog", loot = {
            {9401, "Nordic Longshank", ""},
            {9399, "Precision Arrow", ""},
            {9400, "Baelog's Shortbow", ""},
        } },
        { name = "Olaf", loot = {
            {9404, "Olaf's All Purpose Shield", ""},
            {9403, "Battered Viking Shield", ""},
            {1177, "Oil of Olaf", ""},
        } },
        { name = "Revelosh", loot = {
            {9389, "Revelosh's Spaulders", ""},
            {9388, "Revelosh's Armguards", ""},
            {9390, "Revelosh's Gloves", ""},
            {9387, "Revelosh's Boots", ""},
            {7741, "The Shaft of Tsol", ""},
        } },
        { name = "Ironaya", loot = {
            {9409, "Ironaya's Bracers", ""},
            {9407, "Stoneweaver Leggings", ""},
            {9408, "Ironshod Bludgeon", ""},
        } },
        { name = "Obsidian Sentinel", loot = {
            {8053, "Obsidian Power Source", ""},
        } },
        { name = "Ancient Stone Keeper", loot = {
            {9410, "Cragfists", ""},
            {9411, "Rockshard Pauldrons", ""},
        } },
        { name = "Galgann Firehammer", loot = {
            {11310, "Flameseer Mantle", ""},
            {9412, "Galgann's Fireblaster", ""},
            {11311, "Emberscale Cape", ""},
            {9419, "Galgann's Firehammer", ""},
        } },
        { name = "Grimlok", loot = {
            {9415, "Grimlok's Tribal Vestments", ""},
            {9416, "Grimlok's Charge", ""},
            {9414, "Oilskin Leggings", ""},
            {7670, "Shattered Necklace Sapphire", ""},
        } },
        { name = "Archaedas", loot = {
            {11118, "Archaedic Stone", ""},
            {9413, "The Rockpounder", ""},
            {9418, "Stoneslayer", ""},
        } },
        { name = "Trash", loot = {
            {9431, "Papal Fez", ""},
            {9429, "Miner's Hat of the Deep", ""},
            {9420, "Adventurer's Pith Helmet", ""},
            {9430, "Spaulders of a Lost Age", ""},
            {9397, "Energy Cloak", ""},
            {9406, "Spirewind Fetter", ""},
            {9428, "Unearthed Bands", ""},
            {9432, "Skullplate Bracers", ""},
            {9396, "Legguards of the Vault", ""},
            {9393, "Beacon of Hope", ""},
            {7666, "Shattered Necklace", ""},
            {9381, "Earthen Rod", ""},
            {9426, "Monolithic Bow", ""},
            {9422, "Shadowforge Bushmaster", ""},
            {9465, "Digmaster 5000", ""},
            {9384, "Stonevault Shiv", ""},
            {9386, "Excavator's Brand", ""},
            {9427, "Stonevault Bonebreaker", ""},
            {9392, "Annealed Blade", ""},
            {9424, "Ginn-su Sword", ""},
            {9383, "Obsidian Cleaver", ""},
            {9425, "Pendulum of Doom", ""},
            {9423, "The Jackhammer", ""},
            {9391, "The Shoveler", ""},
        } },
        { name = "Baelog's Chest", loot = {
            {7740, "Gni'kiv Medallion", ""},
        } },
        { name = "Conspicuous Urn", loot = {
            {7671, "Shattered Necklace Topaz", ""},
        } },
        { name = "Shadowforge Cache", loot = {
            {7669, "Shattered Necklace Ruby", ""},
        } },
        { name = "Tablet of Will", loot = {
            {5824, "Tablet of Will", ""},
        } },
    } }
end
if not known["Uldaman"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Uldaman"
    known["Uldaman"] = true
end
if not C.dungeonKnowledge["Zul'Farrak"] then
    C.dungeonKnowledge["Zul'Farrak"] = { level = "42-46", atlasSource = true, quests = {}, bosses = {
        { name = "Antu'sul", loot = {
            {9640, "Vice Grips", ""},
            {9641, "Lifeblood Amulet", ""},
            {9639, "The Hand of Antu'sul", ""},
            {9379, "Sang'thraze the Deflector", ""},
        } },
        { name = "Theka the Martyr", loot = {
            {10660, "First Mosh'aru Tablet", ""},
        } },
        { name = "Sandarr Dunereaver", loot = {
        } },
        { name = "Witch Doctor Zum'rah", loot = {
            {18083, "Jumanza Grips", ""},
            {18082, "Zum'rah's Vexing Cane", ""},
        } },
        { name = "Nekrum Gutchewer", loot = {
            {9471, "Nekrum's Medallion", ""},
        } },
        { name = "Shadowpriest Sezz'ziz", loot = {
            {9470, "Bad Mojo Mask", ""},
            {9473, "Jinxed Hoodoo Skin", ""},
            {9474, "Jinxed Hoodoo Kilt", ""},
            {9475, "Diabolic Skiver", ""},
        } },
        { name = "Dustwraith", loot = {
            {12471, "Desertwalker Cane", ""},
        } },
        { name = "Sandfury Executioner", loot = {
            {8444, "Executioner's Key", ""},
        } },
        { name = "Sergeant Bly", loot = {
            {8548, "Divino-matic Rod", ""},
        } },
        { name = "Hydromancer Velratha", loot = {
            {9234, "Tiara of the Deep", ""},
            {10661, "Second Mosh'aru Tablet", ""},
        } },
        { name = "Gahz'rilla", loot = {
            {9469, "Gahz'rilla Scale Armor", ""},
            {9467, "Gahz'rilla Fang", ""},
        } },
        { name = "Chief Ukorz Sandscalp", loot = {
            {9479, "Embrace of the Lycan", ""},
            {9476, "Big Bad Pauldrons", ""},
            {9478, "Ripsaw", ""},
            {9477, "The Chief's Enforcer", ""},
            {11086, "Jang'thraze the Protector", ""},
        } },
        { name = "Zerillis", loot = {
            {12470, "Sandstalker Ankleguards", ""},
        } },
        { name = "Trash", loot = {
            {9512, "Blackmetal Cape", ""},
            {9484, "Spellshock Leggings", ""},
            {862, "Runed Ring", ""},
            {6440, "Brainlash", ""},
            {9483, "Flaming Incinerator", ""},
            {2040, "Troll Protector", ""},
            {5616, "Gutwrencher", ""},
            {9511, "Bloodletter Scalpel", ""},
            {9481, "The Minotaur", ""},
            {9480, "Eyegouger", ""},
            {9482, "Witch Doctor's Cane", ""},
            {9243, "Shriveled Heart", ""},
        } },
    } }
end
if not known["Zul'Farrak"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Zul'Farrak"
    known["Zul'Farrak"] = true
end
if not C.dungeonKnowledge["Maraudon"] then
    C.dungeonKnowledge["Maraudon"] = { level = "43-48", atlasSource = true, quests = {}, bosses = {
        { name = "Veng", loot = {
            {17765, "Gem of the Fifth Khan", ""},
        } },
        { name = "Noxxion", loot = {
            {17746, "Noxxion's Shackles", ""},
            {17744, "Heart of Noxxion", ""},
            {17745, "Noxious Shooter", ""},
        } },
        { name = "Razorlash", loot = {
            {17749, "Phytoskin Spaulders", ""},
            {17748, "Vinerot Sandals", ""},
            {17750, "Chloromesh Girdle", ""},
            {17751, "Brusslehide Leggings", ""},
        } },
        { name = "Maraudos", loot = {
            {17764, "Gem of the Fourth Khan", ""},
        } },
        { name = "Lord Vyletongue", loot = {
            {17755, "Satyrmane Sash", ""},
            {17754, "Infernal Trickster Leggings", ""},
            {17752, "Satyr's Lash", ""},
        } },
        { name = "Meshlok the Harvester", loot = {
            {17767, "Bloomsprout Headpiece", ""},
            {17741, "Nature's Embrace", ""},
            {17742, "Fungus Shroud Armor", ""},
        } },
        { name = "Celebras the Cursed", loot = {
            {17740, "Soothsayer's Headdress", ""},
            {17739, "Grovekeeper's Drape", ""},
            {17738, "Claw of Celebras", ""},
        } },
        { name = "Landslide", loot = {
            {17734, "Helm of the Mountain", ""},
            {17736, "Rockgrip Gauntlets", ""},
            {17737, "Cloud Stone", ""},
            {17943, "Fist of Stone", ""},
        } },
        { name = "Tinkerer Gizlock", loot = {
            {17718, "Gizlock's Hypertech Buckler", ""},
            {17717, "Megashot Rifle", ""},
            {17719, "Inventor's Focal Sword", ""},
        } },
        { name = "Rotgrip", loot = {
            {17732, "Rotgrip Mantle", ""},
            {17728, "Albino Crocscale Boots", ""},
            {17730, "Gatorbite Axe", ""},
        } },
        { name = "Princess Theradras", loot = {
            {17780, "Blade of Eternal Darkness", ""},
            {17715, "Eye of Theradras", ""},
            {17707, "Gemshard Heart", ""},
            {17714, "Bracers of the Stone Princess", ""},
            {17711, "Elemental Rockridge Leggings", ""},
            {17713, "Blackstone Ring", ""},
            {17710, "Charstone Dirk", ""},
            {17766, "Princess Theradras' Scepter", ""},
        } },
        { name = "The Nameless Prophet", loot = {
            {17757, "Amulet of Spirits", ""},
        } },
        { name = "Kolk", loot = {
            {17761, "Gem of the First Khan", ""},
        } },
        { name = "Gelk", loot = {
            {17762, "Gem of the Second Khan", ""},
        } },
        { name = "Magra", loot = {
            {17763, "Gem of the Third Khan", ""},
        } },
    } }
end
if not known["Maraudon"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Maraudon"
    known["Maraudon"] = true
end
if not C.dungeonKnowledge["Alcaz Prison"] then
    C.dungeonKnowledge["Alcaz Prison"] = { level = "48-53", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["Alcaz Prison"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Alcaz Prison"
    known["Alcaz Prison"] = true
end
if not C.dungeonKnowledge["Sunken Temple"] then
    C.dungeonKnowledge["Sunken Temple"] = { level = "47-50", atlasSource = true, quests = {}, bosses = {
        { name = "Balcony Minibosses", loot = {
            {10783, "Atal'ai Spaulders", ""},
            {10784, "Atal'ai Breastplate", ""},
            {10787, "Atal'ai Gloves", ""},
            {10788, "Atal'ai Girdle", ""},
            {10785, "Atal'ai Leggings", ""},
            {10786, "Atal'ai Boots", ""},
            {20606, "Amber Voodoo Feather", ""},
            {20607, "Blue Voodoo Feather", ""},
            {20608, "Green Voodoo Feather", ""},
        } },
        { name = "Atal'alarion", loot = {
            {10800, "Darkwater Bracers", ""},
            {10798, "Atal'alarion's Tusk Ring", ""},
            {10799, "Headspike", ""},
        } },
        { name = "Spawn of Hakkar", loot = {
            {10801, "Slitherscale Boots", ""},
            {10802, "Wingveil Cloak", ""},
        } },
        { name = "Avatar of Hakkar", loot = {
            {12462, "Embrace of the Wind Serpent", ""},
            {10843, "Featherskin Cape", ""},
            {10845, "Warrior's Embrace", ""},
            {10842, "Windscale Sarong", ""},
            {10846, "Bloodshot Greaves", ""},
            {10838, "Might of Hakkar", ""},
            {10844, "Spire of Hakkar", ""},
        } },
        { name = "Jammal'an the Prophet", loot = {
            {10806, "Vestments of the Atal'ai Prophet", ""},
            {10808, "Gloves of the Atal'ai Prophet", ""},
            {10807, "Kilt of the Atal'ai Prophet", ""},
        } },
        { name = "Ogom the Wretched", loot = {
            {10805, "Eater of the Dead", ""},
            {10803, "Blade of the Wretched", ""},
            {10804, "Fist of the Damned", ""},
        } },
        { name = "Dreamscythe", loot = {
            {12465, "Nightfall Drape", ""},
            {12466, "Dawnspire Cord", ""},
            {12464, "Bloodfire Talons", ""},
            {10797, "Firebreather", ""},
            {12463, "Drakefang Butcher", ""},
            {12243, "Smoldering Claw", ""},
            {10795, "Drakeclaw Band", ""},
            {10796, "Drakestone", ""},
        } },
        { name = "Weaver", loot = {
            {12465, "Nightfall Drape", ""},
            {12466, "Dawnspire Cord", ""},
            {12464, "Bloodfire Talons", ""},
            {10797, "Firebreather", ""},
            {12463, "Drakefang Butcher", ""},
            {12243, "Smoldering Claw", ""},
            {10795, "Drakeclaw Band", ""},
            {10796, "Drakestone", ""},
        } },
        { name = "Hazzas", loot = {
            {12465, "Nightfall Drape", ""},
            {12466, "Dawnspire Cord", ""},
            {12464, "Bloodfire Talons", ""},
            {10797, "Firebreather", ""},
            {12463, "Drakefang Butcher", ""},
            {12243, "Smoldering Claw", ""},
            {10795, "Drakeclaw Band", ""},
            {10796, "Drakestone", ""},
        } },
        { name = "Morphaz", loot = {
            {12465, "Nightfall Drape", ""},
            {12466, "Dawnspire Cord", ""},
            {12464, "Bloodfire Talons", ""},
            {10797, "Firebreather", ""},
            {12463, "Drakefang Butcher", ""},
            {12243, "Smoldering Claw", ""},
            {10795, "Drakeclaw Band", ""},
            {10796, "Drakestone", ""},
        } },
        { name = "Shade of Eranikus", loot = {
            {10847, "Dragon's Call", ""},
            {10833, "Horns of Eranikus", ""},
            {10829, "Dragon's Eye", ""},
            {10836, "Rod of Corrosion", ""},
            {10835, "Crest of Supremacy", ""},
            {10837, "Tooth of Eranikus", ""},
            {10828, "Dire Nail", ""},
            {10454, "Essence of Eranikus", ""},
        } },
        { name = "Trash", loot = {
            {10630, "Soulcatcher Halo", ""},
            {10632, "Slimescale Bracers", ""},
            {10631, "Murkwater Gauntlets", ""},
            {10633, "Silvershell Leggings", ""},
            {10629, "Mistwalker Boots", ""},
            {10634, "Mindseye Circle", ""},
            {10624, "Stinging Bow", ""},
            {10623, "Winter's Bite", ""},
            {10625, "Stealthblade", ""},
            {10626, "Ragehammer", ""},
            {10628, "Deathblow", ""},
            {10627, "Bludgeon of the Grinning Dog", ""},
            {10782, "Hakkari Shroud", ""},
            {10781, "Hakkari Breastplate", ""},
            {10780, "Mark of Hakkar", ""},
            {16216, "Formula: Enchant Cloak - Greater Resistance", ""},
            {15733, "Pattern: Green Dragonscale Leggings", ""},
        } },
    } }
end
if not known["Sunken Temple"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Sunken Temple"
    known["Sunken Temple"] = true
end
if not C.dungeonKnowledge["Blackrock Depths"] then
    C.dungeonKnowledge["Blackrock Depths"] = { level = "48-56", atlasSource = true, quests = {}, bosses = {
        { name = "Lord Roccor", loot = {
            {22234, "Mantle of Lost Hope", ""},
            {11632, "Earthslag Shoulders", ""},
            {11631, "Stoneshell Guard", ""},
            {22397, "Idol of Ferocity", ""},
            {11630, "Rockshard Pellets", ""},
            {11813, "Formula: Smoking Heart of the Mountain", ""},
        } },
        { name = "High Interrogator Gerstahn ", loot = {
            {11626, "Blackveil Cape", ""},
            {11624, "Kentic Amice", ""},
            {22240, "Greaves of Withering Despair", ""},
            {11625, "Enthralled Sphere", ""},
            {11140, "Prison Cell Key", ""},
        } },
        { name = "Houndmaster Grebmar", loot = {
            {11623, "Spritecaster Cape", ""},
            {11627, "Fleetfoot Greaves", ""},
            {11628, "Houndmaster's Bow", ""},
            {11629, "Houndmaster's Rifle", ""},
        } },
        { name = "Gorosh the Dervish", loot = {
            {11726, "Savage Gladiator Chain", ""},
            {22271, "Leggings of Frenzied Magic", ""},
            {22257, "Bloodclot Band", ""},
            {22266, "Flarethorn", ""},
        } },
        { name = "Grizzle", loot = {
            {11722, "Dregmetal Spaulders", ""},
            {11703, "Stonewall Girdle", ""},
            {22270, "Entrenching Boots", ""},
            {11702, "Grizzle's Skinner", ""},
            {11610, "Plans: Dark Iron Pulverizer", ""},
        } },
        { name = "Eviscerator", loot = {
            {11685, "Splinthide Shoulders", ""},
            {11679, "Rubicund Armguards", ""},
            {11686, "Girdle of Beastial Fury", ""},
            {11730, "Savage Gladiator Grips", ""},
        } },
        { name = "Ok'thor the Breaker", loot = {
            {11665, "Ogreseer Fists", ""},
            {11662, "Ban'thok Sash", ""},
            {11728, "Savage Gladiator Leggings", ""},
            {11824, "Cyclopean Band", ""},
        } },
        { name = "Anub'shiah", loot = {
            {11678, "Carapace of Anub'shiah", ""},
            {11677, "Graverot Cape", ""},
            {11675, "Shadefiend Boots", ""},
            {11731, "Savage Gladiator Greaves", ""},
        } },
        { name = "Hedrum the Creeper", loot = {
            {11633, "Spiderfang Carapace", ""},
            {11634, "Silkweb Gloves", ""},
            {11635, "Hookfang Shanker", ""},
            {11729, "Savage Gladiator Helm", ""},
        } },
        { name = "Pyromancer Loregrain", loot = {
            {11747, "Flamestrider Robes", ""},
            {11749, "Searingscale Leggings", ""},
            {11748, "Pyric Caduceus", ""},
            {11750, "Kindling Stave", ""},
            {11207, "Formula: Enchant Weapon - Fiery Weapon", ""},
        } },
        { name = "Dark Coffer", loot = {
            {11197, "Dark Keeper Key", ""},
            {22256, "Mana Shaping Handwraps", ""},
            {22205, "Black Steel Bindings", ""},
            {22255, "Magma Forged Band", ""},
            {22254, "Wand of Eternal Light", ""},
            {11923, "The Hammer of Grace", ""},
            {11945, "Dark Iron Ring", ""},
            {11946, "Fire Opal Necklace", ""},
            {11752, "Black Blood of the Tormented", ""},
            {11751, "Burning Essence", ""},
            {11753, "Eye of Kajal", ""},
        } },
        { name = "Warder Stilgiss", loot = {
            {11782, "Boreal Mantle", ""},
            {22241, "Dark Warder's Pauldrons", ""},
            {11783, "Chillsteel Girdle", ""},
            {11784, "Arbiter's Blade", ""},
        } },
        { name = "Verek", loot = {
            {11755, "Verek's Collar", ""},
            {22242, "Verek's Leash", ""},
        } },
        { name = "Watchman Doomgrip", loot = {
            {22205, "Black Steel Bindings", ""},
            {22255, "Magma Forged Band", ""},
            {22256, "Mana Shaping Handwraps", ""},
            {22254, "Wand of Eternal Light", ""},
        } },
        { name = "Fineous Darkvire", loot = {
            {11839, "Chief Architect's Monocle", ""},
            {22223, "Foreman's Head Protector", ""},
            {11842, "Lead Surveyor's Mantle", ""},
            {11841, "Senior Designer's Pantaloons", ""},
            {11840, "Master Builder's Shirt", ""},
        } },
        { name = "Lord Incendius", loot = {
            {11766, "Flameweave Cuffs", ""},
            {11764, "Cinderhide Armsplints", ""},
            {11765, "Pyremail Wristguards", ""},
            {11767, "Emberplate Armguards", ""},
            {19268, "Ace of Elementals", ""},
            {11768, "Incendic Bracers", ""},
        } },
        { name = "Bael'Gar", loot = {
            {11807, "Sash of the Burning Heart", ""},
            {11802, "Lavacrest Leggings", ""},
            {11805, "Rubidium Hammer", ""},
            {11803, "Force of Magma", ""},
        } },
        { name = "General Angerforge", loot = {
            {11820, "Royal Decorated Armor", ""},
            {11821, "Warstrife Leggings", ""},
            {11810, "Force of Will", ""},
            {11817, "Lord General's Sword", ""},
            {11816, "Angerforge's Battle Axe", ""},
            {11841, "Senior Designer's Pantaloons", ""},
        } },
        { name = "Golem Lord Argelmach", loot = {
            {11823, "Luminary Kilt", ""},
            {11822, "Omnicast Boots", ""},
            {11669, "Naglering", ""},
            {11819, "Second Wind", ""},
        } },
        { name = "Guzzler", loot = {
            {11735, "Ragefury Eyepatch", ""},
            {18043, "Coal Miner Boots", ""},
            {22275, "Firemoss Boots", ""},
            {18044, "Hurley's Tankard", ""},
            {18592, "Plans: Sulfuron Hammer", ""},
            {11612, "Plans: Dark Iron Plate", ""},
            {2662, "Ribbly's Quiver", ""},
            {2663, "Ribbly's Bandolier", ""},
            {11742, "Wayfarer's Knapsack", ""},
            {12793, "Mixologist's Tunic", ""},
            {12791, "Barman Shanker", ""},
            {18653, "Schematic: Goblin Jumper Cables XL", ""},
            {13483, "Recipe: Transmute Fire to Earth", ""},
            {15759, "Pattern: Black Dragonscale Breastplate", ""},
            {11325, "Dark Iron Ale Mug", ""},
            {11602, "Grim Guzzler Key", ""},
        } },
        { name = "Phalanx", loot = {
            {22212, "Golem Fitted Pauldrons", ""},
            {11745, "Fists of Phalanx", ""},
            {11744, "Bloodfist", ""},
            {11743, "Rockfist", ""},
        } },
        { name = "Ambassador Flamelash", loot = {
            {11808, "Circle of Flame", ""},
            {11812, "Cape of the Fire Salamander", ""},
            {11814, "Molten Fists", ""},
            {11832, "Burst of Knowledge", ""},
            {11809, "Flame Wrath", ""},
            {23320, "Tablet of Flame Shock VI", ""},
        } },
        { name = "Panzor the Invincible", loot = {
            {22245, "Soot Encrusted Footwear", ""},
            {11787, "Shalehusk Boots", ""},
            {11785, "Rock Golem Bulwark", ""},
            {11786, "Stone of the Earth", ""},
        } },
        { name = "Chest of The Seven", loot = {
            {11925, "Ghostshroud", ""},
            {11926, "Deathdealer Breastplate", ""},
            {11929, "Haunting Specter Leggings", ""},
            {11927, "Legplates of the Eternal Guardian", ""},
            {11920, "Wraith Scythe", ""},
            {11923, "The Hammer of Grace", ""},
            {11922, "Blood-etched Blade", ""},
            {11921, "Impervious Giant", ""},
        } },
        { name = "Magmus", loot = {
            {11746, "Golem Skull Helm", ""},
            {11935, "Magmus Stone", ""},
            {22395, "Totem of Rage", ""},
            {22400, "Libram of Truth", ""},
            {22208, "Lavastone Hammer", ""},
        } },
        { name = "Princess Moira Bronzebeard ", loot = {
            {12557, "Ebonsteel Spaulders", ""},
            {12554, "Hands of the Exalted Herald", ""},
            {12556, "High Priestess Boots", ""},
            {12553, "Swiftwalker Boots", ""},
        } },
        { name = "Emperor Dagran Thaurissan", loot = {
            {11684, "Ironfoe", ""},
            {11933, "Imperial Jewel", ""},
            {11930, "The Emperor's New Cape", ""},
            {11924, "Robes of the Royal Crown", ""},
            {22204, "Wristguards of Renown", ""},
            {22207, "Sash of the Grand Hunt", ""},
            {11934, "Emperor's Seal", ""},
            {11815, "Hand of Justice", ""},
            {11928, "Thaurissan's Royal Scepter", ""},
            {11931, "Dreadforge Retaliator", ""},
            {11932, "Guiding Stave of Wisdom", ""},
            {12033, "Thaurissan Family Jewels", ""},
        } },
        { name = "Trash", loot = {
            {12549, "Braincage", ""},
            {12552, "Blisterbane Wrap", ""},
            {12551, "Stoneshield Cloak", ""},
            {12542, "Funeral Pyre Vestment", ""},
            {12546, "Aristocratic Cuffs", ""},
            {12550, "Runed Golem Shackles", ""},
            {12547, "Mar Alom's Grip", ""},
            {12555, "Battlechaser's Greaves", ""},
            {12527, "Ribsplitter", ""},
            {12531, "Searing Needle", ""},
            {12535, "Doomforged Straightedge", ""},
            {12528, "The Judge's Gavel", ""},
            {12532, "Spire of the Stoneshaper", ""},
            {15781, "Pattern: Black Dragonscale Leggings", ""},
            {15770, "Pattern: Black Dragonscale Shoulders", ""},
            {11611, "Plans: Dark Iron Sunderer", ""},
            {11614, "Plans: Dark Iron Mail", ""},
            {11615, "Plans: Dark Iron Shoulders", ""},
            {16048, "Schematic: Dark Iron Rifle", ""},
            {16053, "Schematic: Master Engineer's Goggles", ""},
            {16049, "Schematic: Dark Iron Bomb", ""},
            {18654, "Schematic: Gnomish Alarm-O-Bot", ""},
            {18661, "Schematic: World Enlarger", ""},
        } },
        { name = "Plans", loot = {
            {11614, "Plans: Dark Iron Mail", ""},
            {11615, "Plans: Dark Iron Shoulders", ""},
        } },
        { name = "Theldren", loot = {
            {22305, "Ironweave Mantle", ""},
            {22330, "Shroud of Arcane Mastery", ""},
            {22318, "Malgen's Long Bow", ""},
            {22317, "Lefty's Brass Knuckle", ""},
        } },
    } }
end
if not known["Blackrock Depths"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Blackrock Depths"
    known["Blackrock Depths"] = true
end
if not C.dungeonKnowledge["Lower Blackrock Spire"] then
    C.dungeonKnowledge["Lower Blackrock Spire"] = { level = "54-60", atlasSource = true, quests = {}, artName = "Blackrock Spire", bosses = {
        { name = "Burning Felguard", loot = {
            {13181, "Demonskin Gloves", ""},
            {13182, "Phase Blade", ""},
        } },
        { name = "Spirestone Butcher", loot = {
            {12608, "Butcher's Apron", ""},
            {13286, "Rivenspike", ""},
        } },
        { name = "Highlord Omokk", loot = {
            {16670, "Boots of Elements", ""},
            {13166, "Slamshot Shoulders", ""},
            {13168, "Plate of the Shaman King", ""},
            {13170, "Skyshroud Leggings", ""},
            {13169, "Tressermane Leggings", ""},
            {13167, "Fist of Omokk", ""},
            {12336, "Gemstone of Spirestone", ""},
            {12534, "Omokk's Head", ""},
        } },
        { name = "Spirestone Battle Lord", loot = {
            {13284, "Swiftdart Battleboots", ""},
            {13285, "The Nicker", ""},
        } },
        { name = "Spirestone Lord Magus", loot = {
            {13282, "Ogreseer Tower Boots", ""},
            {13283, "Magus Ring", ""},
            {13261, "Globe of D'sak", ""},
        } },
        { name = "Shadow Hunter Vosh'gajin", loot = {
            {16712, "Shadowcraft Gloves", ""},
            {13257, "Demonic Runed Spaulders", ""},
            {12626, "Funeral Cuffs", ""},
            {13255, "Trueaim Gauntlets", ""},
            {12653, "Riphook", ""},
            {12651, "Blackcrow", ""},
            {12654, "Doomshot", ""},
        } },
        { name = "War Master Voone", loot = {
            {16676, "Beaststalker's Gloves", ""},
            {13177, "Talisman of Evasion", ""},
            {13179, "Brazecore Armguards", ""},
            {22231, "Kayser's Boots of Precision", ""},
            {13173, "Flightblade Throwing Axe", ""},
            {12582, "Keris of Zul'Serak", ""},
            {12335, "Gemstone of Smolderthorn", ""},
        } },
        { name = "Bannok Grimaxe", loot = {
            {12637, "Backusarian Gauntlets", ""},
            {12634, "Chiselbrand Girdle", ""},
            {12621, "Demonfork", ""},
            {12838, "Plans: Arcanite Reaper", ""},
        } },
        { name = "Mother Smolderweb", loot = {
            {16715, "Wildheart Boots", ""},
            {13244, "Gilded Gauntlets", ""},
            {13213, "Smolderweb's Eye", ""},
            {13183, "Venomspitter", ""},
        } },
        { name = "Crystal Fang", loot = {
            {13185, "Sunderseer Mantle", ""},
            {13184, "Fallbrush Handgrips", ""},
            {13218, "Fang of the Crystal Spider", ""},
        } },
        { name = "Urok Doomhowl", loot = {
            {13258, "Slaghide Gauntlets", ""},
            {22232, "Marksman's Girdle", ""},
            {13259, "Ribsteel Footguards", ""},
            {13178, "Rosewine Circle", ""},
            {18784, "Top Half of Advanced Armorsmithing: Volume III", ""},
        } },
        { name = "Quartermaster Zigris", loot = {
            {13247, "Quartermaster Zigris' Footlocker", ""},
            {13253, "Hands of Power", ""},
            {13252, "Cloudrunner Girdle", ""},
            {12835, "Plans: Annihilator", ""},
        } },
        { name = "Halycon", loot = {
            {13212, "Halycon's Spiked Collar", ""},
            {22313, "Ironweave Bracers", ""},
            {13211, "Slashclaw Bracers", ""},
            {13210, "Pads of the Dread Wolf", ""},
        } },
        { name = "Gizrul the Slavener", loot = {
            {16718, "Wildheart Spaulders", ""},
            {13208, "Bleak Howler Armguards", ""},
            {13206, "Wolfshear Leggings", ""},
            {13205, "Rhombeard Protector", ""},
        } },
        { name = "Ghok Bashguud", loot = {
            {13203, "Armswake Cloak", ""},
            {13198, "Hurd Smasher", ""},
            {13204, "Bashguuder", ""},
        } },
        { name = "Overlord Wyrmthalak", loot = {
            {13143, "Mark of the Dragon Lord", ""},
            {16679, "Beaststalker's Mantle", ""},
            {13162, "Reiver Claws", ""},
            {13164, "Heart of the Scale", ""},
            {22321, "Heart of Wyrmthalak", ""},
            {13163, "Relentless Scythe", ""},
            {13148, "Chillpike", ""},
            {13161, "Trindlehaven Staff", ""},
            {12337, "Gemstone of Bloodaxe", ""},
            {12780, "General Drakkisath's Command", ""},
        } },
        { name = "Trash", loot = {
            {14513, "Pattern: Robe of the Archmage", ""},
            {16696, "Devout Belt", ""},
            {16685, "Magister's Belt", ""},
            {16683, "Magister's Bindings", ""},
            {16703, "Dreadmist Bracers", ""},
            {16713, "Shadowcraft Belt", ""},
            {16716, "Wildheart Belt", ""},
            {16680, "Beaststalker's Belt", ""},
            {16673, "Cord of Elements", ""},
            {16736, "Belt of Valor", ""},
            {16735, "Bracers of Valor", ""},
            {15749, "Pattern: Volcanic Breastplate", ""},
            {15775, "Pattern: Volcanic Shoulders", ""},
            {13494, "Recipe: Greater Fire Protection Potion", ""},
            {16250, "Formula: Enchant Weapon - Superior Striking", ""},
            {16244, "Formula: Enchant Gloves - Greater Strength", ""},
            {9214, "Grimoire of Inferno", ""},
            {12219, "Unadorned Seal of Ascension", ""},
            {12586, "Immature Venom Sac", ""},
        } },
        { name = "Mor Grayhoof", loot = {
            {22306, "Ironweave Belt", ""},
            {22325, "Belt of the Trickster", ""},
            {22319, "Tome of Divine Right", ""},
            {22398, "Idol of Rejuvenation", ""},
            {22322, "The Jaw Breaker", ""},
        } },
    } }
end
if not known["Lower Blackrock Spire"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Lower Blackrock Spire"
    known["Lower Blackrock Spire"] = true
end
if not C.dungeonKnowledge["Blackmaw Hold"] then
    C.dungeonKnowledge["Blackmaw Hold"] = { level = "55-60", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["Blackmaw Hold"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Blackmaw Hold"
    known["Blackmaw Hold"] = true
end
if not C.dungeonKnowledge["Dire Maul East"] then
    C.dungeonKnowledge["Dire Maul East"] = { level = "55-60", atlasSource = true, quests = {}, artName = "Dire Maul", bosses = {
        { name = "Pusillin", loot = {
            {18267, "Recipe: Runn Tum Tuber Surprise", ""},
            {18249, "Crescent Key", ""},
        } },
        { name = "Zevrim Thornhoof", loot = {
            {18319, "Fervent Helm", ""},
            {18313, "Helm of Awareness", ""},
            {18323, "Satyr's Bow", ""},
            {18308, "Clever Hat", ""},
            {18306, "Gloves of Shadowy Mist", ""},
        } },
        { name = "Hydrospawn", loot = {
            {18317, "Tempest Talisman", ""},
            {18322, "Waterspout Boots", ""},
            {18324, "Waveslicer", ""},
            {19268, "Ace of Elementals", ""},
            {18305, "Breakwater Legguards", ""},
            {18307, "Riptide Shoes", ""},
        } },
        { name = "Lethtendris", loot = {
            {18325, "Felhide Cap", ""},
            {18311, "Quel'dorai Channeling Rod", ""},
            {18301, "Lethtendris's Wand", ""},
            {18302, "Band of Vigor", ""},
        } },
        { name = "Alzzin the Wildshaper", loot = {
            {18328, "Shadewood Cloak", ""},
            {18312, "Energized Chestplate", ""},
            {18309, "Gloves of Restoration", ""},
            {18326, "Razor Gauntlets", ""},
            {18327, "Whipvine Cord", ""},
            {18318, "Merciful Greaves", ""},
            {18321, "Energetic Rod", ""},
            {18310, "Fiendish Machete", ""},
            {18314, "Ring of Demonic Guile", ""},
            {18315, "Ring of Demonic Potency", ""},
        } },
        { name = "Trash", loot = {
            {18289, "Barbed Thorn Necklace", ""},
            {18296, "Marksman Bands", ""},
            {18298, "Unbridled Leggings", ""},
            {18295, "Phasing Boots", ""},
            {18333, "Libram of Focus", ""},
            {18334, "Libram of Protection", ""},
            {18332, "Libram of Rapidity", ""},
            {18255, "Runn Tum Tuber", ""},
            {18297, "Thornling Seed", ""},
        } },
        { name = "Isalien", loot = {
            {22304, "Ironweave Gloves", ""},
            {22472, "Boots of Ferocity", ""},
            {22401, "Libram of Hope", ""},
            {22345, "Totem of Rebirth", ""},
            {22315, "Hammer of Revitalization", ""},
            {22314, "Huntsman's Harpoon", ""},
        } },
    } }
end
if not known["Dire Maul East"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Dire Maul East"
    known["Dire Maul East"] = true
end
if not C.dungeonKnowledge["Upper Blackrock Spire"] then
    C.dungeonKnowledge["Upper Blackrock Spire"] = { level = "58-60", atlasSource = true, quests = {}, artName = "Blackrock Spire", bosses = {
        { name = "Pyroguard Emberseer", loot = {
            {16672, "Gauntlets of Elements", ""},
            {12929, "Emberfury Talisman", ""},
            {12927, "TruestrikeShoulders", ""},
            {12905, "Wildfire Cape", ""},
            {12926, "Flaming Band", ""},
            {23320, "Tablet of Flame Shock VI", ""},
        } },
        { name = "Solakar Flamewreath", loot = {
            {16695, "Devout Mantle", ""},
            {12609, "Polychromatic Visionwrap", ""},
            {12603, "Nightbrace Tunic", ""},
            {12589, "Dustfeather Sash", ""},
            {12606, "Crystallized Girdle", ""},
            {18657, "Schematic: Hyper-Radiant Flame Reflector", ""},
        } },
        { name = "Jed Runewatcher", loot = {
            {12604, "Starfire Tiara", ""},
            {12930, "Briarwood Reed", ""},
            {12605, "Serpentine Skuller", ""},
        } },
        { name = "Goraluk Anvilcrack ", loot = {
            {13502, "Handcrafted Mastersmith Girdle", ""},
            {13498, "Handcrafted Mastersmith Leggings", ""},
            {18047, "Flame Walkers", ""},
            {18048, "Mastersmith's Hammer", ""},
            {12834, "Plans: Arcanite Champion", ""},
            {12837, "Plans: Masterwork Stormhammer", ""},
            {18779, "Bottom Half of Advanced Armorsmithing: Volume I", ""},
            {12806, "Unforged Rune Covered Breastplate", ""},
            {12696, "Plans: Demon Forged Breastplate", ""},
        } },
        { name = "Gyth", loot = {
            {12871, "Chromatic Carapace", ""},
            {16669, "Pauldrons of Elements", ""},
            {22225, "Dragonskin Cowl", ""},
            {12960, "Tribal War Feathers", ""},
            {12953, "Dragoneye Coif", ""},
            {12952, "Gyth's Skull", ""},
            {13522, "Recipe: Flask of Chromatic Resistance", ""},
        } },
        { name = "Warchief Rend Blackhand", loot = {
            {12590, "Felstriker", ""},
            {16733, "Spaulders of Valor", ""},
            {12587, "Eye of Rend", ""},
            {12588, "Bonespike Shoulder", ""},
            {12936, "Battleborn Armbraces", ""},
            {18104, "Feralsurge Girdle", ""},
            {12935, "Warmaster Legguards", ""},
            {18102, "Dragonrider Boots", ""},
            {22247, "Faith Healer's Boots", ""},
            {18103, "Band of Rumination", ""},
            {12940, "Dal'Rend's Sacred Charge", ""},
            {12939, "Dal'Rend's Tribal Guardian", ""},
            {12583, "Blackhand Doomsaw", ""},
        } },
        { name = "The Beast", loot = {
            {12731, "Pristine Hide of the Beast", ""},
            {16729, "Lightforge Spaulders", ""},
            {12967, "Bloodmoon Cloak", ""},
            {12968, "Frostweaver Cape", ""},
            {12966, "Blackmist Armguards", ""},
            {12965, "Spiritshroud Leggings", ""},
            {12963, "Blademaster Leggings", ""},
            {12964, "Tristam Legguards", ""},
            {22311, "Ironweave Boots", ""},
            {12709, "Finkle's Skinner", ""},
            {12969, "Seeping Willow", ""},
            {24101, "Book of Ferocious Bite V", ""},
            {19227, "Ace of Beasts", ""},
        } },
        { name = "General Drakkisath", loot = {
            {12592, "Blackblade of Shahram", ""},
            {22267, "Spellweaver's Turban", ""},
            {13141, "Tooth of Gnarr", ""},
            {22269, "Shadow Prowler's Cloak", ""},
            {13142, "Brigam Girdle", ""},
            {13098, "Painweaver Band", ""},
            {22268, "Draconic Infused Emblem", ""},
            {22253, "Tome of the Lost", ""},
            {12602, "Draconian Deflector", ""},
            {15730, "Pattern: Red Dragonscale Breastplate", ""},
            {13519, "Recipe: Flask of the Titans", ""},
            {16690, "Devout Robe", ""},
            {16688, "Magister's Robes", ""},
            {16700, "Dreadmist Robe", ""},
            {16721, "Shadowcraft Tunic", ""},
            {16706, "Wildheart Vest", ""},
            {16674, "Beaststalker's Tunic", ""},
            {16666, "Vest of Elements", ""},
            {16726, "Lightforge Breastplate", ""},
            {16730, "Breastplate of Valor", ""},
        } },
        { name = "Trash", loot = {
            {24102, "Manual of Eviscerate IX", ""},
            {13260, "Wind Dancer Boots", ""},
            {16696, "Devout Belt", ""},
            {16683, "Magister's Bindings", ""},
            {16703, "Dreadmist Bracers", ""},
            {16713, "Shadowcraft Belt", ""},
            {16681, "Beaststalker's Bindings", ""},
            {16680, "Beaststalker's Belt", ""},
            {16673, "Cord of Elements", ""},
            {16735, "Bracers of Valor", ""},
            {16247, "Formula: Enchant 2H Weapon - Superior Impact", ""},
        } },
        { name = "Darkstone Tablet", loot = {
            {12358, "Darkstone Tablet", ""},
        } },
        { name = "Lord Valthalak", loot = {
            {22302, "Ironweave Cowl", ""},
            {22340, "Pendant of Celerity", ""},
            {22337, "Shroud of Domination", ""},
            {22343, "Handguards of Savagery", ""},
            {22342, "Leggings of Torment", ""},
            {22339, "Rune Band of Wizardry", ""},
            {22336, "Draconian Aegis of the Legion", ""},
            {22335, "Lord Valthalak's Staff of Command", ""},
        } },
    } }
end
if not known["Upper Blackrock Spire"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Upper Blackrock Spire"
    known["Upper Blackrock Spire"] = true
end
if not C.dungeonKnowledge["Shaper's Terrace"] then
    C.dungeonKnowledge["Shaper's Terrace"] = { level = "58-60", atlasSource = true, quests = {}, preview = true, bosses = {
    } }
end
if not known["Shaper's Terrace"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Shaper's Terrace"
    known["Shaper's Terrace"] = true
end
if not C.dungeonKnowledge["Dire Maul West"] then
    C.dungeonKnowledge["Dire Maul West"] = { level = "58-60", atlasSource = true, quests = {}, artName = "Dire Maul", bosses = {
        { name = "Tendris Warpwood", loot = {
            {18393, "Warpwood Binding", ""},
            {18390, "Tanglemoss Leggings", ""},
            {18352, "Petrified Bark Shield", ""},
            {18353, "Stoneflower Staff", ""},
        } },
        { name = "Illyanna Ravenoak", loot = {
            {18383, "Force Imbued Gauntlets", ""},
            {18386, "Padre's Trousers", ""},
            {18349, "Gauntlets of Accuracy", ""},
            {18347, "Well Balanced Axe", ""},
        } },
        { name = "Magister Kalendris", loot = {
            {18374, "Flamescarred Shoulders", ""},
            {18397, "Elder Magus Pendant", ""},
            {18371, "Mindtap Talisman", ""},
            {18350, "Amplifying Cloak", ""},
            {18351, "Magically Sealed Bracers", ""},
            {22309, "Pattern: Big Bag of Enchantment", ""},
        } },
        { name = "Tsu'zee", loot = {
            {18387, "Brightspark Gloves", ""},
            {18346, "Threadbare Trousers", ""},
            {18345, "Murmuring Ring", ""},
        } },
        { name = "Immol'thar", loot = {
            {18381, "Evil Eye Pendant", ""},
            {18384, "Bile-etched Spaulders", ""},
            {18389, "Cloak of the Cosmos", ""},
            {18385, "Robe of Everlasting Night", ""},
            {18394, "Demon Howl Wristguards", ""},
            {18377, "Quickdraw Gloves", ""},
            {18391, "Eyestalk Cord", ""},
            {18379, "Odious Greaves", ""},
            {18370, "Vigilance Charm", ""},
            {18372, "Blade of the New Moon", ""},
        } },
        { name = "Prince Tortheldrin", loot = {
            {18382, "Fluctuating Cloak", ""},
            {18373, "Chestplate of Tranquility", ""},
            {18375, "Bracers of the Eclipse", ""},
            {18378, "Silvermoon Leggings", ""},
            {18380, "Eldritch Reinforced Legplates", ""},
            {18395, "Emerald Flame Ring", ""},
            {18388, "Stoneshatter", ""},
            {18396, "Mind Carver", ""},
            {18376, "Timeworn Mace", ""},
            {18392, "Distracting Dagger", ""},
        } },
        { name = "Trash", loot = {
            {18340, "Eidolon Talisman", ""},
            {18344, "Stonebark Gauntlets", ""},
            {18338, "Wand of Arcane Potency", ""},
            {18333, "Libram of Focus", ""},
            {18334, "Libram of Protection", ""},
            {18332, "Libram of Rapidity", ""},
        } },
        { name = "Revanchion", loot = {
            {23127, "Cloak of Revanchion", ""},
            {23129, "Bracers of Mending", ""},
            {23128, "The Shadow's Grasp", ""},
        } },
        { name = "Shen'dralar Provisioner", loot = {
        } },
        { name = "Lord Hel'nurath", loot = {
            {18757, "Diabolic Mantle", ""},
            {18754, "Fel Hardened Bracers", ""},
            {18755, "Xorothian Firestick", ""},
            {18756, "Dreadguard's Protector", ""},
        } },
    } }
end
if not known["Dire Maul West"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Dire Maul West"
    known["Dire Maul West"] = true
end
if not C.dungeonKnowledge["Dire Maul North"] then
    C.dungeonKnowledge["Dire Maul North"] = { level = "58-60", atlasSource = true, quests = {}, artName = "Dire Maul", bosses = {
        { name = "Guard Mol'dar", loot = {
            {18494, "Denwatcher's Shoulders", ""},
            {18493, "Bulky Iron Spaulders", ""},
            {18496, "Heliotrope Cloak", ""},
            {18497, "Sublime Wristguards", ""},
            {18498, "Hedgecutter", ""},
            {18450, "Robe of Combustion", ""},
            {18458, "Modest Armguards", ""},
            {18459, "Gallant's Wristguards", ""},
            {18451, "Hyena Hide Belt", ""},
            {18462, "Jagged Bone Fist", ""},
            {18463, "Ogre Pocket Knife", ""},
            {18464, "Gordok Nose Ring", ""},
            {18460, "Unsophisticated Hand Cannon", ""},
            {18250, "Gordok Shackle Key", ""},
            {18268, "Gordok Inner Door Key", ""},
        } },
        { name = "Stomper Kreeg", loot = {
            {18425, "Kreeg's Mug", ""},
        } },
        { name = "Guard Fengus", loot = {
            {18450, "Robe of Combustion", ""},
            {18458, "Modest Armguards", ""},
            {18459, "Gallant's Wristguards", ""},
            {18451, "Hyena Hide Belt", ""},
            {18462, "Jagged Bone Fist", ""},
            {18463, "Ogre Pocket Knife", ""},
            {18464, "Gordok Nose Ring", ""},
            {18460, "Unsophisticated Hand Cannon", ""},
            {18250, "Gordok Shackle Key", ""},
            {18266, "Gordok Courtyard Key", ""},
        } },
        { name = "Guard Slip'kik", loot = {
            {18494, "Denwatcher's Shoulders", ""},
            {18493, "Bulky Iron Spaulders", ""},
            {18496, "Heliotrope Cloak", ""},
            {18497, "Sublime Wristguards", ""},
            {18498, "Hedgecutter", ""},
            {18450, "Robe of Combustion", ""},
            {18458, "Modest Armguards", ""},
            {18459, "Gallant's Wristguards", ""},
            {18451, "Hyena Hide Belt", ""},
            {18462, "Jagged Bone Fist", ""},
            {18463, "Ogre Pocket Knife", ""},
            {18464, "Gordok Nose Ring", ""},
            {18460, "Unsophisticated Hand Cannon", ""},
            {18250, "Gordok Shackle Key", ""},
        } },
        { name = "Knot Thimblejack's Cache", loot = {
            {18414, "Pattern: Belt of the Archmage", ""},
            {18517, "Pattern: Chromatic Cloak", ""},
            {18518, "Pattern: Hide of the Wild", ""},
            {18519, "Pattern: Shifting Cloak", ""},
            {18415, "Pattern: Felcloth Gloves", ""},
            {18416, "Pattern: Inferno Gloves", ""},
            {18417, "Pattern: Mooncloth Gloves", ""},
            {18418, "Pattern: Cloak of Warding", ""},
            {18514, "Pattern: Girdle of Insight", ""},
            {18515, "Pattern: Mongoose Boots", ""},
            {18516, "Pattern: Swift Flight Bracers", ""},
            {18258, "Gordok Ogre Suit", ""},
            {18240, "Ogre Tannin", ""},
        } },
        { name = "Captain Kromcrush", loot = {
            {18503, "Kromcrush's Chestplate", ""},
            {18505, "Mugger's Belt", ""},
            {18507, "Boots of the Full Moon", ""},
            {18502, "Monstrous Glaive", ""},
        } },
        { name = "Cho'Rush the Observer", loot = {
            {18490, "Insightful Hood", ""},
            {18483, "Mana Channeling Wand", ""},
            {18485, "Observer's Shield", ""},
            {18484, "Cho'Rush's Blade", ""},
        } },
        { name = "King Gordok", loot = {
            {18526, "Crown of the Ogre King", ""},
            {18525, "Bracers of Prosperity", ""},
            {18527, "Harmonious Gauntlets", ""},
            {18524, "Leggings of Destruction", ""},
            {18521, "Grimy Metal Boots", ""},
            {18522, "Band of the Ogre King", ""},
            {18523, "Brightly Glowing Stone", ""},
            {18520, "Barbarous Blade", ""},
            {19258, "Ace of Warlords", ""},
            {18780, "Top Half of Advanced Armorsmithing: Volume I", ""},
        } },
        { name = "Tribute", loot = {
            {18538, "Treant's Bane", ""},
            {18528, "Cyclone Spaulders", ""},
            {18495, "Redoubt Cloak", ""},
            {18532, "Mindsurge Robe", ""},
            {18530, "Ogre Forged Hauberk", ""},
            {18533, "Gordok Bracers of Power", ""},
            {18529, "Elemental Plate Girdle", ""},
            {18500, "Tarnished Elven Ring", ""},
            {18537, "Counterattack Lodestone", ""},
            {18499, "Barrier Shield", ""},
            {18531, "Unyielding Maul", ""},
            {18534, "Rod of the Ogre Magi", ""},
            {18479, "Carrion Scorpid Helm", ""},
            {18480, "Scarab Plate Helm", ""},
            {18478, "Hyena Hide Jerkin", ""},
            {18475, "Oddly Magical Belt", ""},
            {18477, "Shaggy Leggings", ""},
            {18476, "Mud Stained Boots", ""},
            {18482, "Ogre Toothpick Shooter", ""},
            {18481, "Skullcracking Mace", ""},
            {18655, "Schematic: Major Recombobulator", ""},
        } },
        { name = "Trash", loot = {
            {18250, "Gordok Shackle Key", ""},
            {18333, "Libram of Focus", ""},
            {18334, "Libram of Protection", ""},
            {18332, "Libram of Rapidity", ""},
            {18640, "Happy Fun Rock", ""},
        } },
    } }
end
if not known["Dire Maul North"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Dire Maul North"
    known["Dire Maul North"] = true
end
if not C.dungeonKnowledge["Scholomance"] then
    C.dungeonKnowledge["Scholomance"] = { level = "58-60", atlasSource = true, quests = {}, bosses = {
        { name = "Blood Steward of Kirtonos", loot = {
            {13523, "Blood of Innocents", ""},
        } },
        { name = "Kirtonos the Herald", loot = {
            {16734, "Boots of Valor", ""},
            {13960, "Heart of the Fiend", ""},
            {13955, "Stoneform Shoulders", ""},
            {13969, "Loomguard Armbraces", ""},
            {13957, "Gargoyle Slashers", ""},
            {13956, "Clutch of Andros", ""},
            {13967, "Windreaver Greaves", ""},
            {14024, "Frightalon", ""},
            {13983, "Gravestone War Axe", ""},
        } },
        { name = "Jandice Barov", loot = {
            {16701, "Dreadmist Mantle", ""},
            {14548, "Royal Cap Spaulders", ""},
            {18689, "Phantasmal Cloak", ""},
            {14543, "Darkshade Gloves", ""},
            {14545, "Ghostloom Leggings", ""},
            {18690, "Wraithplate Leggings", ""},
            {14541, "Barovian Family Sword", ""},
            {22394, "Staff of Metanoia", ""},
            {13523, "Blood of Innocents", ""},
        } },
        { name = "Rattlegore", loot = {
            {16711, "Shadowcraft Boots", ""},
            {14539, "Bone Ring Helm", ""},
            {14538, "Deadwalker Mantle", ""},
            {18686, "Bone Golem Shoulders", ""},
            {14537, "Corpselight Greaves", ""},
            {14528, "Rattlecage Buckler", ""},
            {14531, "Frightskull Shaft", ""},
            {18782, "Top Half of Advanced Armorsmithing: Volume II", ""},
            {13873, "Viewing Room Key", ""},
        } },
        { name = "Death Knight Darkreaver", loot = {
            {18760, "Necromantic Band", ""},
            {18761, "Oblivion's Touch", ""},
            {18758, "Specter's Blade", ""},
            {18759, "Malicious Axe", ""},
        } },
        { name = "Marduk Blackpool", loot = {
            {18692, "Death Knight Sabatons", ""},
            {14576, "Ebon Hilt of Marduk", ""},
        } },
        { name = "Vectus", loot = {
            {18691, "Dark Advisor's Pendant", ""},
            {14577, "Skullsmoke Pants", ""},
        } },
        { name = "Ras Frostwhisper", loot = {
            {13314, "Alanna's Embrace", ""},
            {16689, "Magister's Mantle", ""},
            {14503, "Death's Clutch", ""},
            {14340, "Freezing Lich Robes", ""},
            {18693, "Shivery Handwraps", ""},
            {14525, "Boneclenched Gauntlets", ""},
            {14502, "Frostbite Girdle", ""},
            {14522, "Maelstrom Leggings", ""},
            {18694, "Shadowy Mail Greaves", ""},
            {18695, "Spellbound Tome", ""},
            {18696, "Intricately Runed Shield", ""},
            {13952, "Iceblade Hacker", ""},
            {14487, "Bonechill Hammer", ""},
            {13521, "Recipe: Flask of Supreme Power", ""},
        } },
        { name = "Instructor Malicia", loot = {
            {16710, "Shadowcraft Bracers", ""},
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "Doctor Theolen Krastinov", loot = {
            {16684, "Magister's Gloves", ""},
            {14617, "Sawbones Shirt", ""},
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "Lorekeeper Polkelt", loot = {
            {16705, "Dreadmist Wraps", ""},
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "The Ravenian", loot = {
            {16716, "Wildheart Belt", ""},
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "Lord Alexei Barov", loot = {
            {16722, "Lightforge Bracers", ""},
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "Lady Illucia Barov", loot = {
            {18681, "Burial Shawl", ""},
            {14633, "Necropile Mantle", ""},
            {14626, "Necropile Robe", ""},
            {14637, "Cadaverous Armor", ""},
            {14611, "Bloodmail Hauberk", ""},
            {14624, "Deathbone Chestplate", ""},
            {14629, "Necropile Cuffs", ""},
            {14640, "Cadaverous Gloves", ""},
            {14615, "Bloodmail Gauntlets", ""},
            {14622, "Deathbone Gauntlets", ""},
            {14636, "Cadaverous Belt", ""},
            {14614, "Bloodmail Belt", ""},
            {14620, "Deathbone Girdle", ""},
            {14632, "Necropile Leggings", ""},
            {14638, "Cadaverous Leggings", ""},
            {18682, "Ghoul Skin Leggings", ""},
            {14612, "Bloodmail Legguards", ""},
            {14623, "Deathbone Legguards", ""},
            {14631, "Necropile Boots", ""},
            {14641, "Cadaverous Walkers", ""},
            {14616, "Bloodmail Boots", ""},
            {14621, "Deathbone Sabatons", ""},
            {18684, "Dimly Opalescent Ring", ""},
            {23201, "Libram of Divinity", ""},
            {23200, "Totem of Sustaining", ""},
            {18680, "Ancient Bone Bow", ""},
            {18683, "Hammer of the Vesper", ""},
        } },
        { name = "Darkmaster Gandling", loot = {
            {13937, "Headmaster's Charge", ""},
            {14514, "Pattern: Robe of the Void", ""},
            {16693, "Devout Crown", ""},
            {16686, "Magister's Crown", ""},
            {16698, "Dreadmist Mask", ""},
            {16707, "Shadowcraft Cap", ""},
            {16720, "Wildheart Cowl", ""},
            {16677, "Beaststalker's Cap", ""},
            {16667, "Coif of Elements", ""},
            {16727, "Lightforge Helm", ""},
            {16731, "Helm of Valor", ""},
            {13944, "Tombstone Breastplate", ""},
            {13951, "Vigorsteel Vambraces", ""},
            {13950, "Detention Strap", ""},
            {13398, "Boots of the Shrieker", ""},
            {22433, "Don Mauricio's Band of Domination", ""},
            {13938, "Bonecreeper Stylus", ""},
            {13953, "Silent Fang", ""},
            {13964, "Witchblade", ""},
            {19276, "Ace of Portals", ""},
            {13501, "Recipe: Major Mana Potion", ""},
        } },
        { name = "Trash", loot = {
            {16685, "Magister's Belt", ""},
            {16702, "Dreadmist Belt", ""},
            {16710, "Shadowcraft Bracers", ""},
            {16714, "Wildheart Bracers", ""},
            {16716, "Wildheart Belt", ""},
            {16671, "Bindings of Elements", ""},
            {16722, "Lightforge Bracers", ""},
            {12843, "Corruptor's Scourgestone", ""},
            {12841, "Invader's Scourgestone", ""},
            {12840, "Minion's Scourgestone", ""},
            {20520, "Dark Rune", ""},
            {12753, "Skin of Shadow", ""},
            {18698, "Tattered Leather Hood", ""},
            {18699, "Icy Tomb Spaulders", ""},
            {14536, "Bonebrace Hauberk", ""},
            {18700, "Malefic Bracers", ""},
            {18702, "Belt of the Ordained", ""},
            {18697, "Coldstone Slippers", ""},
            {18701, "Innervating Band", ""},
            {16254, "Formula: Enchant Weapon - Lifestealing", ""},
            {16255, "Formula: Enchant 2H Weapon - Major Spirit", ""},
            {15773, "Pattern: Wicked Leather Armor", ""},
            {15776, "Pattern: Runic Leather Armor", ""},
            {13920, "Healthy Dragon Scale", ""},
        } },
        { name = "Lord Blackwood", loot = {
            {23132, "Lord Blackwood's Blade", ""},
            {23156, "Blackwood's Thigh", ""},
            {23139, "Lord Blackwood's Buckler", ""},
        } },
        { name = "Kormok", loot = {
            {22303, "Ironweave Pants", ""},
            {22326, "Amalgam's Band", ""},
            {22331, "Band of the Steadfast Hero", ""},
            {22332, "Blade of Necromancy", ""},
            {22333, "Hammer of Divine Might", ""},
        } },
    } }
end
if not known["Scholomance"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Scholomance"
    known["Scholomance"] = true
end
if not C.dungeonKnowledge["Stratholme"] then
    C.dungeonKnowledge["Stratholme"] = { level = "58-60", atlasSource = true, quests = {}, bosses = {
        { name = "Skul", loot = {
            {13395, "Skul's Fingerbone Claws", ""},
            {13394, "Skul's Cold Embrace", ""},
            {13396, "Skul's Ghastly Touch", ""},
        } },
        { name = "Stratholme Courier", loot = {
            {13303, "Crusaders' Square Postbox Key", ""},
            {13305, "Elders' Square Postbox Key", ""},
            {13304, "Festival Lane Postbox Key", ""},
            {13307, "Fras Siabi's Postbox Key", ""},
            {13306, "King's Square Postbox Key", ""},
            {13302, "Market Row Postbox Key", ""},
        } },
        { name = "Hearthsinger Forresten", loot = {
            {16682, "Magister's Boots", ""},
            {13378, "Songbird Blouse", ""},
            {13384, "Rainbow Girdle", ""},
            {13383, "Woollies of the Prancing Minstrel", ""},
            {13379, "Piccolo of the Flaming Fire", ""},
        } },
        { name = "The Unforgiven", loot = {
            {16717, "Wildheart Gloves", ""},
            {13404, "Mask of the Unforgiven", ""},
            {13405, "Wailing Nightbane Pauldrons", ""},
            {13409, "Tearfall Bracers", ""},
            {13408, "Soul Breaker", ""},
        } },
        { name = "Postmaster Malown", loot = {
            {13390, "The Postmaster's Band", ""},
            {13388, "The Postmaster's Tunic", ""},
            {13389, "The Postmaster's Trousers", ""},
            {13391, "The Postmaster's Treads", ""},
            {13392, "The Postmaster's Seal", ""},
            {13393, "Malown's Slam", ""},
        } },
        { name = "Timmy the Cruel", loot = {
            {16724, "Lightforge Gauntlets", ""},
            {13400, "Vambraces of the Sadist", ""},
            {13403, "Grimgore Noose", ""},
            {13402, "Timmy's Galoshes", ""},
            {13401, "The Cruel Hand of Timmy", ""},
        } },
        { name = "Malor the Zealous", loot = {
            {12845, "Medallion of Faith", ""},
        } },
        { name = "Crimson Hammersmith", loot = {
            {18781, "Bottom Half of Advanced Armorsmithing: Volume II", ""},
        } },
        { name = "Cannon Master Willey", loot = {
            {16708, "Shadowcraft Spaulders", ""},
            {22407, "Helm of the New Moon", ""},
            {22403, "Diana's Pearl Necklace", ""},
            {22405, "Mantle of the Scarlet Crusade", ""},
            {18721, "Barrage Girdle", ""},
            {13381, "Master Cannoneer Boots", ""},
            {13382, "Cannonball Runner", ""},
            {13380, "Willey's Portable Howitzer", ""},
            {13377, "Miniature Cannon Balls", ""},
            {22404, "Willey's Back Scratcher", ""},
            {22406, "Redemption", ""},
            {12839, "Plans: Heartseeker", ""},
        } },
        { name = "Archivist Galford", loot = {
            {16692, "Devout Gloves", ""},
            {13386, "Archivist Cape", ""},
            {13387, "Foresight Girdle", ""},
            {18716, "Ash Covered Boots", ""},
            {13385, "Tome of Knowledge", ""},
            {12811, "Righteous Orb", ""},
            {22897, "Tome of Conjure Food VII", ""},
        } },
        { name = "Balnazzar", loot = {
            {13353, "Book of the Dead", ""},
            {14512, "Pattern: Truefaith Vestments", ""},
            {16725, "Lightforge Boots", ""},
            {13359, "Crown of Tyranny", ""},
            {18718, "Grand Crusader's Helm", ""},
            {12103, "Star of Mystaria", ""},
            {18720, "Shroud of the Nathrezim", ""},
            {13358, "Wyrmtongue Shoulders", ""},
            {13369, "Fire Striders", ""},
            {13360, "Gift of the Elven Magi", ""},
            {18717, "Hammer of the Grand Crusader", ""},
            {22334, "Band of Mending", ""},
            {13348, "Demonshear", ""},
            {13520, "Recipe: Flask of Distilled Wisdom", ""},
            {13250, "Head of Balnazzar", ""},
        } },
        { name = "Magistrate Barthilas", loot = {
            {18727, "Crimson Felt Hat", ""},
            {13376, "Royal Tribunal Cloak", ""},
            {18726, "Magistrate's Cuffs", ""},
            {18722, "Death Grips", ""},
            {23198, "Idol of Brutality", ""},
            {18725, "Peacemaker", ""},
            {12382, "Key to the City", ""},
        } },
        { name = "Stonespine", loot = {
            {13397, "Stoneskin Gargoyle Cape", ""},
            {13954, "Verdant Footpads", ""},
            {13399, "Gargoyle Shredder Talons", ""},
        } },
        { name = "Baroness Anastari", loot = {
            {16704, "Dreadmist Sandals", ""},
            {18728, "Anastari Heirloom", ""},
            {18730, "Shadowy Laced Handwraps", ""},
            {18729, "Screeching Bow", ""},
            {13534, "Banshee Finger", ""},
            {13538, "Windshrieker Pauldrons", ""},
            {13535, "Coldtouch Phantom Wraps", ""},
            {13537, "Chillhide Bracers", ""},
            {13539, "Banshee's Touch", ""},
            {13514, "Wail of the Banshee", ""},
        } },
        { name = "Black Guard Swordsmith", loot = {
            {18783, "Bottom Half of Advanced Armorsmithing: Volume III", ""},
        } },
        { name = "Nerub'enkan", loot = {
            {16675, "Beaststalker's Boots", ""},
            {18740, "Thuzadin Sash", ""},
            {18739, "Chitinous Plate Legguards", ""},
            {18738, "Carapace Spine Crossbow", ""},
            {13529, "Husk of Nerub'enkan", ""},
            {13533, "Acid-etched Pauldrons", ""},
            {13532, "Darkspinner Claws", ""},
            {13531, "Crypt Stalker Leggings", ""},
            {13530, "Fangdrip Runners", ""},
            {13508, "Eye of Arachnida", ""},
        } },
        { name = "Maleki the Pallid", loot = {
            {16691, "Devout Sandals", ""},
            {18734, "Pale Moon Cloak", ""},
            {18735, "Maleki's Footwraps", ""},
            {13524, "Skull of Burning Shadows", ""},
            {18737, "Bone Slicing Hatchet", ""},
            {13528, "Twilight Void Bracers", ""},
            {13525, "Darkbind Fingers", ""},
            {13526, "Flamescarred Girdle", ""},
            {13527, "Lavawalker Greaves", ""},
            {13509, "Clutch of Foresight", ""},
            {12833, "Plans: Hammer of the Titans", ""},
        } },
        { name = "Ramstein the Gorger", loot = {
            {16737, "Gauntlets of Valor", ""},
            {18723, "Animated Chain Necklace", ""},
            {13374, "Soulstealer Mantle", ""},
            {13373, "Band of Flesh", ""},
            {13515, "Ramstein's Lightning Bolts", ""},
            {13375, "Crest of Retribution", ""},
            {13372, "Slavedriver's Cane", ""},
        } },
        { name = "Baron Rivendare", loot = {
            {13335, "Deathcharger's Reins", ""},
            {13505, "Runeblade of Baron Rivendare", ""},
            {22411, "Helm of the Executioner", ""},
            {22412, "Thuzadin Mantle", ""},
            {13340, "Cape of the Black Baron", ""},
            {13346, "Robes of the Exalted", ""},
            {22409, "Tunic of the Crescent Moon", ""},
            {13344, "Dracorian Gauntlets", ""},
            {22410, "Gauntlets of Deftness", ""},
            {13345, "Seal of Rivendare", ""},
            {22408, "Ritssyn's Wand of Bad Mojo", ""},
            {13349, "Scepter of the Unholy", ""},
            {13368, "Bonescraper", ""},
            {13361, "Skullforge Reaver", ""},
            {16694, "Devout Skirt", ""},
            {16687, "Magister's Leggings", ""},
            {16699, "Dreadmist Leggings", ""},
            {16709, "Shadowcraft Pants", ""},
            {16719, "Wildheart Kilt", ""},
            {16678, "Beaststalker's Pants", ""},
            {16668, "Kilt of Elements", ""},
            {16728, "Lightforge Legplates", ""},
            {16732, "Legplates of Valor", ""},
        } },
        { name = "Trash", loot = {
            {16697, "Devout Bracers", ""},
            {16685, "Magister's Belt", ""},
            {16702, "Dreadmist Belt", ""},
            {16710, "Shadowcraft Bracers", ""},
            {16714, "Wildheart Bracers", ""},
            {16681, "Beaststalker's Bindings", ""},
            {16671, "Bindings of Elements", ""},
            {16723, "Lightforge Belt", ""},
            {16736, "Belt of Valor", ""},
            {12811, "Righteous Orb", ""},
            {12735, "Frayed Abomination Stitching", ""},
            {12843, "Corruptor's Scourgestone", ""},
            {12841, "Invader's Scourgestone", ""},
            {12840, "Minion's Scourgestone", ""},
            {18742, "Stratholme Militia Shoulderguard", ""},
            {18743, "Gracious Cape", ""},
            {17061, "Juno's Shadow", ""},
            {18741, "Morlune's Bracer", ""},
            {18744, "Plaguebat Fur Gloves", ""},
            {18745, "Sacred Cloth Leggings", ""},
            {18736, "Plaguehound Leggings", ""},
            {16249, "Formula: Enchant 2H Weapon - Major Intellect", ""},
            {16248, "Formula: Enchant Weapon - Unholy", ""},
            {14495, "Pattern: Ghostweave Pants", ""},
            {15777, "Pattern: Runic Leather Shoulders", ""},
            {15768, "Pattern: Wicked Leather Belt", ""},
            {18658, "Schematic: Ultra-Flash Shadow Reflector", ""},
            {16052, "Schematic: Voice Amplification Modulator", ""},
        } },
        { name = "Plans", loot = {
            {12827, "Plans: Serenity", ""},
            {12830, "Plans: Corruption", ""},
        } },
        { name = "Atiesh", loot = {
            {22736, "Andonisus, Reaper of Souls", ""},
        } },
        { name = "Balzaphon", loot = {
            {23126, "Waistband of Balzaphon", ""},
            {23125, "Chains of the Lich", ""},
            {23124, "Staff of Balzaphon", ""},
        } },
        { name = "Sothos and Jarien's Heirlooms", loot = {
            {22327, "Amulet of the Redeemed", ""},
            {22301, "Ironweave Robe", ""},
            {22328, "Legplates of Vigilance", ""},
            {22334, "Band of Mending", ""},
            {22329, "Scepter of Interminable Focus", ""},
        } },
    } }
end
if not known["Stratholme"] then
    C.dungeonKnowledgeOrder[#C.dungeonKnowledgeOrder + 1] = "Stratholme"
    known["Stratholme"] = true
end
-- Forever-only raids currently listed as previews in the installed source catalog.
for _, name in ipairs({"Mount Hyjal", "Barrow Deeps"}) do
    if not C.raidKnowledge[name] then
        C.raidKnowledge[name] = { atlasSource = true, preview = true, quests = {}, bosses = {} }
        C.raidKnowledgeOrder[#C.raidKnowledgeOrder + 1] = name
    end
end
