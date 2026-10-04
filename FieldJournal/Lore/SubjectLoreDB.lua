local ADDON_NAME, FieldJournal = ...

FieldJournal_LoreDB = FieldJournal_LoreDB or {}

-- =========================
-- DUN MOROGH: BEASTS
-- =========================

FieldJournal_LoreDB.WOLVES = {
    id = "WOLVES",
    displayName = "Wolves",
    ldr = "LDR-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Dun Morogh" },

    npcs = {
        705,  -- Ragged Young Wolf
        704,  -- Ragged Timber Wolf
        1138, -- Snow Tracker Wolf
        1133, -- Starving Winter Wolf
        1131, -- Winter Wolf

        -- Rare / named wolves
        1132, -- Timber
        1137, -- Edan the Howler
    },

    lore = {
        [1] = "Wolves are carnivorous mammals classified as wilderness predators across Azeroth. They are commonly encountered in forested and frontier regions.",

        [2] = "Field reports describe wolves as pack-oriented hunters exhibiting coordinated pursuit behavior when engaging prey. Their social structure appears loosely hierarchical, driven primarily by dominance rather than fixed leadership roles.",

        [3] = "Archival records confirm wolves are widely distributed across multiple regions of Azeroth, inhabiting forests, plains, and harsher wilderness environments. Environmental conditions influence physical characteristics such as size, fur density, and resilience, though these variations are documented as adaptive responses rather than distinct subspecies classifications.",

        [4] = "Historical and cultural records indicate that wolves have been domesticated or trained by various humanoid groups. Notably, orcish martial traditions make use of wolves as mounts and battlefield companions. These records suggest wolves possess sufficient behavioral adaptability to respond to sustained conditioning under structured humanoid influence.",

        [5] = "Wolves are a widely distributed predatory species defined by ecological adaptability and cooperative hunting behavior. Compiled field observations and archival records indicate that their success stems from flexible pack coordination, environmental resilience, and opportunistic predation patterns. Rather than functioning as simple threats, wolves represent a stable ecological predator class influencing prey populations across multiple regions of Azeroth."
    }
}

FieldJournal_LoreDB.BOARS = {
    id = "BOARS",
    displayName = "Boars",
    ldr = "LDR-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Dun Morogh" },

    npcs = {
        708,  -- Small Crag Boar
        1125, -- Crag Boar
        1126, -- Large Crag Boar
        1127, -- Elder Crag Boar
        1689, -- Scarred Crag Boar
    },

    lore = {
        [1] = "Crag boars are hardy mountain beasts native to Dun Morogh, recognizable by their tusks, heavy shoulders, and low, stubborn charge. Small, common, large, elder, and scarred crag boars all belong to the same practical family of cold-country boars found across the dwarven homeland.",

        [2] = "Field signs include rooted snow, churned soil, and hard hoof-marks around roads, ranches, and sheltered valleys. Crag boars are not clever hunters, but they are strong, territorial animals that meet danger head-on with tusk and charge.",

        [3] = "Crag boars are well adapted to Dun Morogh's harsh mountain climate. They are recorded around Coldridge Valley, Kharanos, Brewnall Village, Helm's Bed Lake, the North Gate routes, and other settled edges where scrub, roots, and traveler refuse offer steady forage.",

        [4] = "For dwarves and gnomes beginning their travels, crag boars are among the first lessons in the difference between a peaceful-looking beast and a safe one. Their meat, hides, and presence near roads make them part of ordinary frontier life rather than an exceptional menace.",

        [5] = "The crag boars of Dun Morogh represent the rugged everyday wildlife of the mountain kingdom. They are neither invaders nor unnatural threats, but native survivors shaped by snow, stone, and the stubborn endurance that defines the land itself.",
    }
}

FieldJournal_LoreDB.BEARS = {
    id = "BEARS",
    displayName = "Bears",
    ldr = "LDR-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Dun Morogh" },

    npcs = {
        1128, -- Young Black Bear
        1129, -- Black Bear
        1196, -- Ice Claw Bear

        -- Rare / named bears
        1130, -- Bjarn
        1271, -- Old Icebeard
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

FieldJournal_LoreDB.SNOW_LEOPARDS = {
    id = "SNOW_LEOPARDS",
    displayName = "Snow Leopards",
    ldr = "LDR-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Dun Morogh" },

    npcs = {
        1199, -- Juvenile Snow Leopard
        1201, -- Snow Leopard

        -- Rare / named snow leopard
        1961, -- Mangeclaw
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

FieldJournal_LoreDB.WENDIGO = {
    id = "WENDIGO",
    displayName = "Wendigo",
    ldr = "LDR-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
    zones = { "Dun Morogh" },

    npcs = {
        1134, -- Young Wendigo
        1135, -- Wendigo

        -- Rare / named wendigo
        1388, -- Vagash
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

-- =========================
-- DUN MOROGH: HUMANOID / MONSTROUS HOSTILE GROUPS
-- =========================

FieldJournal_LoreDB.FROSTMANE_TROLLS = {
    id = "FROSTMANE_TROLLS",
    displayName = "Frostmane Trolls",
    ldr = "LDR-6",
    icon = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    zones = { "Dun Morogh" },

    npcs = {
        706,  -- Frostmane Troll Whelp
        1120, -- Frostmane Troll
        1121, -- Frostmane Snowstrider
        1122, -- Frostmane Hideskinner
        1123, -- Frostmane Headhunter
        1124, -- Frostmane Shadowcaster
        946,  -- Frostmane Novice
        1397, -- Frostmane Seer

        -- Rare / named Frostmane
        1260, -- Great Father Arctikus
        808,  -- Grik'nir the Cold
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

FieldJournal_LoreDB.ROCKJAW_TROGGS = {
    id = "ROCKJAW_TROGGS",
    displayName = "Rockjaw Troggs",
    ldr = "LDR-7",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Dun Morogh" },

    npcs = {
        707,  -- Rockjaw Trogg
        724,  -- Burly Rockjaw Trogg
        1115, -- Rockjaw Skullthumper
        1116, -- Rockjaw Ambusher
        1117, -- Rockjaw Bonesnapper
        1118, -- Rockjaw Raider
        208752, -- Frozen Trogg

        -- Rare / named troggs
        1119, -- Hammerspine
        6113, -- Vejrek
    },

    lore = {
        [1] = "Rockjaw troggs are brutish humanoids of the Rockjaw tribe found in Dun Morogh, especially around Coldridge Valley, Coldridge Pass, and nearby mountain holds. They are cave-dwelling, violent, and physically powerful despite their crude tools and rough organization.",

        [2] = "Rockjaw troggs fight with direct aggression, relying on ambush points, narrow passes, and numbers rather than discipline. Skullthumpers, bonesnappers, raiders, and ambushers suggest a simple but functional division of roles within their tribe.",

        [3] = "Their presence in Dun Morogh is tied to caves, passes, and broken mountain ground where dwarven control weakens. In the field, I found their camps and patrols most dangerous where stone walls and snowdrifts limited movement.",

        [4] = "Troggs have long troubled the dwarven lands of Khaz Modan, and the Rockjaw are one of the earliest examples faced by new defenders of Ironforge. Their raids into passes and settlements make them a practical military concern, not merely a wilderness nuisance.",

        [5] = "The Rockjaw troggs embody the hostile underworld pressing up against Dun Morogh's roads and holds. They are primitive but persistent, a reminder that the mountain belongs not only to dwarves and gnomes, but also to older, rougher things in the dark stone beneath their feet.",
    }
}

FieldJournal_LoreDB.LEPER_GNOMES = {
    id = "LEPER_GNOMES",
    displayName = "Leper Gnomes",
    ldr = "LDR-8",
    icon = "Interface\\Icons\\INV_Misc_Head_Gnome_01",
    zones = { "Dun Morogh" },

    npcs = {
        6221,   -- Addled Leper
        216667, -- Addled Leper
        1211,   -- Leper Gnome

        -- Rare / named leper gnome
        8503, -- Gibblewilt
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

FieldJournal_LoreDB.DARK_IRON_AGENTS = {
    id = "DARK_IRON_AGENTS",
    displayName = "Dark Iron Agents",
    ldr = "LDR-9",
    icon = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
    zones = { "Dun Morogh" },

    npcs = {
        6123, -- Dark Iron Spy
    },

    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    }
}

-- =========================
-- ELWYNN FOREST: BEASTS
-- =========================

FieldJournal_LoreDB.ELWYNN_WOLVES = {
    id = "ELWYNN_WOLVES",
    displayName = "Wolves",
    ldr = "LDR-EF-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Elwynn Forest" },

    npcs = {
        299,  -- Young Wolf
        525,  -- Mangy Wolf
        69,   -- Timber Wolf
        1922, -- Gray Forest Wolf
        118,  -- Prowler

    },

    lore = {
        [1] = "The wolves of Elwynn Forest are common forest predators, ranging from young wolves near Northshire to larger timber wolves and prowlers deeper in the trees. They are not unnatural monsters, but ordinary beasts made dangerous by hunger, territory, and numbers.",

        [2] = "Wolf tracks appear often along wooded paths and near farms where small livestock or careless travelers pass too close to the tree line. I found the younger wolves bold but undisciplined, while the older prowlers struck with more patience and confidence.",

        [3] = "Elwynn's wolves thrive because the forest gives them cover, prey, and easy access to the edges of human settlement. Their presence is a reminder that even the Kingdom of Stormwind's heartland remains a living wilderness beyond the roads and lamplight.",

        [4] = "For new defenders of Stormwind, wolves are often the first lesson in field survival. Farmers, guards, and abbey recruits all have reason to watch the woods, since a hungry pack can turn a peaceful road into a dangerous crossing.",

        [5] = "The wolves of Elwynn represent the forest's oldest law: civilization may build roads, farms, and abbeys, but the wild still watches from the shade. A proper field journal must record them not as villains, but as native predators living beside an expanding human kingdom.",
    }
}

FieldJournal_LoreDB.ELWYNN_BOARS = {
    id = "ELWYNN_BOARS",
    displayName = "Boars",
    ldr = "LDR-EF-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Elwynn Forest" },

    npcs = {
        113, -- Stonetusk Boar
        524, -- Rockhide Boar
        330, -- Princess
        119, -- Longsnout
    },

    lore = {
        [1] = "Elwynn's boars are sturdy forest animals, recognizable by their tusks, low build, and stubborn temper. Stonetusk and rockhide varieties are common enough near farms and trails to become a regular concern for travelers.",

        [2] = "Boars do not stalk like wolves, but they are quick to charge when threatened. I found their signs in rooted earth, broken brush, and churned mud where they had searched for food beneath the forest floor.",

        [3] = "These animals are well suited to Elwynn's soft soil and settled clearings. Orchards, vineyards, pumpkin patches, and farms draw them close to people, making conflict almost inevitable wherever the forest meets cultivated land.",

        [4] = "Boars are part of the practical life of Elwynn: hunted for meat, feared by farmers, and sometimes named with enough personality to become local trouble. Their danger is mundane, but no less real to those whose fields they ruin.",

        [5] = "The boars of Elwynn are the forest's blunt force made flesh. They are not cunning enemies, but they shape daily life by testing fences, crops, and careless adventurers with the same hard-headed persistence.",
    }
}

FieldJournal_LoreDB.ELWYNN_BEARS = {
    id = "ELWYNN_BEARS",
    displayName = "Bears",
    ldr = "LDR-EF-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Elwynn Forest" },

    npcs = {
        822, -- Young Forest Bear
    },

    lore = {
        [1] = "Young forest bears are powerful animals still growing into their full strength. Even immature bears are dangerous enough to injure an unwary traveler who mistakes youth for weakness.",

        [2] = "Bear signs are heavier than wolf tracks: clawed bark, disturbed brush, and broad paw marks in soft earth. I found that they rely less on pursuit and more on raw strength once provoked.",

        [3] = "Elwynn's bears keep mostly to wooded stretches where food and cover remain plentiful. Their presence suggests that despite roads and farms, enough wild country remains to support larger animals.",

        [4] = "To the people of Elwynn, bears are both a resource and a hazard. Pelts, meat, and protection of the frontier all give locals reason to hunt them, though doing so carelessly is a quick path to injury.",

        [5] = "The bears of Elwynn are living proof that the forest is not merely scenery around Stormwind's roads. They are part of the old woodland strength beneath the kingdom's settled surface.",
    }
}

FieldJournal_LoreDB.ELWYNN_SPIDERS = {
    id = "ELWYNN_SPIDERS",
    displayName = "Spiders",
    ldr = "LDR-EF-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Elwynn Forest" },

    npcs = {
        30,  -- Forest Spider
        43,  -- Mine Spider
        471, -- Mother Fang
        442, -- Tarantula
    },

    lore = {
        [1] = "Elwynn's spiders range from forest spiders among the trees to mine spiders lurking in darker tunnels. Their threat lies in ambush, venom, and the unsettling patience common to web-spinning predators.",

        [2] = "Webbing is the first warning sign: stretched between roots, beams, and low branches where prey might blunder through. I found the larger spiders most dangerous when terrain forced me close before I could see them clearly.",

        [3] = "The spiders of Elwynn favor shadowed places, abandoned corners, and disturbed mines where insects and small animals gather. Their spread into human-worked spaces shows how quickly the wild reclaims any place left unwatched.",

        [4] = "Spiders are a recurring hazard in frontier work, especially where miners, farmers, or guards push into neglected ground. A mine may be valuable to Stormwind, but to a spider it is only another den.",

        [5] = "Elwynn's spiders embody the hidden danger of familiar places. They are rarely the loudest threat in the forest, but their webs mark the quiet borders where safety gives way to the unseen.",
    }
}

-- =========================
-- ELWYNN FOREST: HOSTILE HUMANOIDS
-- =========================

FieldJournal_LoreDB.ELWYNN_KOBOLDS = {
    id = "ELWYNN_KOBOLDS",
    displayName = "Kobolds",
    ldr = "LDR-EF-5",
    icon = "Interface\\Icons\\INV_Misc_Candle_01",
    zones = { "Elwynn Forest" },

    npcs = {
        6,   -- Kobold Vermin
        257, -- Kobold Worker
        80,  -- Kobold Laborer
        475, -- Kobold Tunneler
        40,  -- Kobold Miner
        476, -- Kobold Geomancer

        -- Named / notable kobolds
        327, -- Goldtooth
        79,  -- Narg the Taskmaster
    },

    lore = {
        [1] = "Kobolds are small, candle-bearing humanoids found throughout Elwynn's mines and ridges. Their cries over candles are more than nuisance; they mark a people fiercely protective of their tunnels and claims.",

        [2] = "Kobolds fight in crude but determined fashion, using numbers, tight tunnels, and familiar ground to their advantage. I found that miners and tunnelers appear where digging is active, while geomancers suggest a rough command of earth magic among them.",

        [3] = "Elwynn's kobolds infest places such as Echo Ridge, Fargodeep Mine, and Jasperlode Mine, where Stormwind's need for resources brings humans into direct conflict with underground dwellers. The mines are useful to the kingdom, but the kobolds defend them as fiercely as any home.",

        [4] = "To Stormwind, kobolds are pests and thieves of mineral wealth; to the kobolds, the tunnels may be home, hoard, and refuge. The conflict is simple on patrol orders but more complicated when observed in the field.",

        [5] = "The kobolds of Elwynn are the forest's underground resistance to human expansion. Their candles, crude tools, and stubborn defense of the mines make them one of the first true organized threats a human adventurer studies.",
    }
}

FieldJournal_LoreDB.ELWYNN_DEFIAS = {
    id = "ELWYNN_DEFIAS",
    displayName = "Defias and Outlaws",
    ldr = "LDR-EF-6",
    icon = "Interface\\Icons\\INV_Mask_04",
    zones = { "Elwynn Forest" },

    npcs = {
        38,   -- Defias Thug
        116,  -- Defias Bandit
        94,   -- Defias Cutpurse
        583,  -- Defias Ambusher
        6866, -- Defias Bodyguard
        6846, -- Defias Dockworker
        6927, -- Defias Dockmaster
        474,  -- Defias Rogue Wizard

        -- Named / notable outlaws
        103, -- Garrick Padfoot
        473, -- Morgan the Collector
        61,  -- Thuros Lightfingers
        99,  -- Morgaine the Sly
        60,  -- Ruklar the Trapper
    },

    lore = {
        [1] = "The Defias and other outlaws in Elwynn Forest are human criminals, thieves, ambushers, and organized bandits. Unlike beasts or kobolds, they understand the roads, farms, and weaknesses of Stormwind's settlements.",

        [2] = "Defias activity is marked by stolen goods, red linen, hidden camps, and sudden attacks from cover. I found them more dangerous than common wildlife because they choose their targets and often operate with purpose.",

        [3] = "Elwynn's bandit presence is strongest around farms, vineyards, pumpkin patches, and routes where isolated workers can be threatened. Places that appear peaceful from the road can become dangerous once criminals settle into the fields.",

        [4] = "The Defias Brotherhood is not merely a bandit problem; it is a political and criminal wound tied to Stormwind's recent history. Their presence in Elwynn shows how unrest can reach even the kingdom's central forest.",

        [5] = "The Defias and outlaws of Elwynn represent civilized danger turned inward. They are men and women of the same roads and fields they now prey upon, making them one of the clearest signs that the forest's troubles are not only natural ones.",
    }
}

FieldJournal_LoreDB.ELWYNN_RIVERPAW_GNOLLS = {
    id = "ELWYNN_RIVERPAW_GNOLLS",
    displayName = "Riverpaw Gnolls",
    ldr = "LDR-EF-7",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Elwynn Forest" },

    npcs = {
        97,   -- Riverpaw Runt
        478,  -- Riverpaw Outrunner

        -- Rare / named gnolls
        448,  -- Hogger
        100,  -- Gruff Swiftbite
        6093, -- Dead-Tooth Jack
    },

    lore = {
        [1] = "The Riverpaw gnolls of Elwynn are hyena-like humanoids found along the forest's rougher edges. They are more organized than beasts and more savage in the field than most common bandits.",

        [2] = "Gnoll camps show signs of scavenged supplies, crude weapons, and territorial patrols. I found their runts less disciplined, but their outrunners and named leaders are bold enough to threaten travelers and guards alike.",

        [3] = "The Riverpaw press against Elwynn from camps near the forest's borders and rougher stretches, especially toward the west. This places them near roads and borderlands where Stormwind's control becomes thinner.",

        [4] = "The Riverpaw are a serious concern for Elwynn because they challenge both settlement and travel. Hogger's name alone carries enough fear among locals to turn a bounty into a warning.",

        [5] = "The Riverpaw gnolls represent Elwynn's border violence: not wild animals, not political rebels, but raiders pressing against the kingdom's soft places. A complete study of Elwynn cannot ignore their camps, trails, or bloody reputation.",
    }
}

FieldJournal_LoreDB.ELWYNN_MURLOCS = {
    id = "ELWYNN_MURLOCS",
    displayName = "Murlocs",
    ldr = "LDR-EF-8",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Elwynn Forest" },

    npcs = {
        285, -- Murloc
        46,  -- Murloc Forager
        732, -- Murloc Lurker
        735, -- Murloc Streamrunner

        -- Named / notable murlocs
        472, -- Fedfennel
    },

    lore = {
        [1] = "Murlocs are amphibious humanoids found near Elwynn's lakes and streams. Their croaking calls, quick movements, and tendency to gather near water make them distinct from the forest's land-bound threats.",

        [2] = "Murlocs rarely feel alone for long. I found that a single forager or lurker can quickly become a skirmish with several more, especially near shorelines where escape routes are uneven and wet.",

        [3] = "Murlocs have taken up residence around Elwynn's waters, including Stone Cairn Lake and Crystal Lake. In practice, this places them close enough to human travel and fishing routes to become a persistent local danger.",

        [4] = "To Stormwind's people, murlocs are strange, noisy, and often hostile neighbors at the water's edge. Their settlements complicate travel, fishing, and guard work wherever the forest opens onto lakes or rivers.",

        [5] = "The murlocs of Elwynn are the voice of the waterline: half-hidden, communal, and difficult to understand from the road. Their presence reminds the field researcher that Elwynn's dangers do not end at the trees.",
    }
}

if FieldJournal and FieldJournal.Config and FieldJournal.Config.debug then
    print(">>> SubjectLoreDB LOADED <<<")
end

-- =========================
-- LOCH MODAN: BEASTS
-- =========================

FieldJournal_LoreDB.LOCH_MODAN_BOARS = {
    id = "LOCH_MODAN_BOARS",
    displayName = "Mountain Boars",
    ldr = "LDR-LM-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Loch Modan" },

    npcs = {
        1191, -- Mangy Mountain Boar
        1190, -- Mountain Boar
        1192, -- Elder Mountain Boar
    },

    lore = {
        [1] = "Mountain boars are sturdy, tusked beasts common across the wooded slopes and open stretches of Loch Modan. They are not unnatural creatures, but their strength and temperament make them dangerous to careless travelers.",
        [2] = "Boars root through soft earth, trample brush, and defend themselves with sudden charges. I found their signs near roads and settlements where wild feeding grounds meet dwarven travel routes.",
        [3] = "Loch Modan's temperate hills and scattered woods suit these animals well. The lake, farms, and low mountain passes give them enough water, cover, and forage to remain a steady presence throughout the region.",
        [4] = "For the people of Thelsamar and the nearby lodges, boars are both food source and nuisance. Their meat can provision travelers, yet a large boar can injure a hunter or ruin a working path through sheer stubborn force.",
        [5] = "The mountain boars of Loch Modan represent the ordinary resilience of Khaz Modan's wild country. They are humble creatures, but they teach the first rule of the loch: even common beasts deserve respect when the road leaves town behind.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_BEARS = {
    id = "LOCH_MODAN_BEARS",
    displayName = "Black Bears",
    ldr = "LDR-LM-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Loch Modan" },

    npcs = {
        1189, -- Black Bear Patriarch
        1186, -- Elder Black Bear
        1188, -- Grizzled Black Bear
        1225, -- Ol' Sooty
    },

    lore = {
        [1] = "Black bears are powerful woodland beasts found throughout Loch Modan's forests and ridges. Mature bears and patriarchs possess enough strength to make them a serious threat even to armored travelers.",
        [2] = "Bear signs are heavy and plain: clawed bark, overturned stones, and broad tracks in damp soil. I observed that older bears are less easily startled than younger beasts and more willing to hold ground when challenged.",
        [3] = "The forests around Thelsamar, Grizzlepaw Ridge, and the loch provide bears with cover and steady food. Their presence confirms that Loch Modan remains a living wilderness despite roads, lodges, mines, and patrols.",
        [4] = "Dwarven hunters respect bears as sources of meat, hide, and danger. Named beasts such as Ol' Sooty become local tales because they turn an ordinary wilderness hazard into something remembered by the whole region.",
        [5] = "The black bears of Loch Modan are the weight of the forest given form. They are not invaders or rebels, but old inhabitants of the hills, forcing every explorer to remember that Khaz Modan's beauty has claws.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_CROCOLISKS = {
    id = "LOCH_MODAN_CROCOLISKS",
    displayName = "Loch Crocolisks",
    ldr = "LDR-LM-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk",
    zones = { "Loch Modan" },

    npcs = {
        1693, -- Loch Crocolisk
        2476, -- Large Loch Crocolisk
    },

    lore = {
        [1] = "Loch crocolisks are broad-jawed reptilian predators found along the water and shorelines of Loch Modan. Their bodies are low, armored, and suited to ambush near the edge of the lake.",
        [2] = "Crocolisks wait with unnerving stillness, then lunge with sudden force when prey comes close. I learned to watch quiet banks carefully, especially where reeds or shallow water hide the shape of a resting beast.",
        [3] = "The great loch gives these predators their natural place in the region. Fish, birds, careless beasts, and travelers all pass near the shore, making the lake both lifeline and hunting ground.",
        [4] = "To Thelsamar and the Farstrider Lodge, crocolisks are a practical danger for hunters, fishers, and anyone traveling near the water. Their hides and meat may be useful, but the price of harvesting them is paid in caution.",
        [5] = "The crocolisks of Loch Modan are the loch's hidden teeth. They make the water feel ancient and watchful, transforming a peaceful shore into one of the region's most deceptive frontiers.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_BUZZARDS = {
    id = "LOCH_MODAN_BUZZARDS",
    displayName = "Buzzards",
    ldr = "LDR-LM-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Vulture",
    zones = { "Loch Modan" },

    npcs = {
        1194, -- Mountain Buzzard
        2829, -- Starving Buzzard
    },

    lore = {
        [1] = "Buzzards are carrion birds seen circling the open ground and ridges of Loch Modan. They are scavengers by nature, but hunger and opportunity can make them aggressive toward the living.",
        [2] = "Their shadows often appear before their bodies descend. I found them near carcasses, battle sites, and lonely stretches where the smell of death carries well on the mountain air.",
        [3] = "Loch Modan's cliffs, valleys, and contested wilds give buzzards ample places to nest and feed. Trogg fights, ogre raids, and hunter kills all leave remains that draw them from above.",
        [4] = "Among travelers, buzzards are treated as ill omens because they gather where something has already gone wrong. To a field researcher, their presence marks the invisible economy of death that follows every conflict in the region.",
        [5] = "The buzzards of Loch Modan are the sky's record keepers. They do not cause most of the violence below, but they reveal where the land has bled and where the careless may soon join the carrion.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_LURKERS = {
    id = "LOCH_MODAN_LURKERS",
    displayName = "Forest Lurkers",
    ldr = "LDR-LM-5",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Loch Modan" },

    npcs = {
        1185, -- Wood Lurker
        1195, -- Forest Lurker
        1184, -- Cliff Lurker
        14266, -- Shanda the Spinner
    },

    lore = {
        [1] = "The lurkers of Loch Modan are spider-like woodland predators found among trees, cliffs, and shadowed ground. Their bodies and habits mark them as ambush hunters rather than open pursuers.",
        [2] = "Webbing, disturbed brush, and sudden movement from cover are the common warnings. I found cliff lurkers especially dangerous where rock and slope narrowed the space for retreat.",
        [3] = "These creatures suit the mixed terrain of Loch Modan: pine forest, rocky ridges, and caves all provide places for webs and ambush. Their spread shows how many hidden corners exist between the roads and settlements.",
        [4] = "Hunters and mountaineers must treat lurker territory seriously, for a path that seems clear by daylight may be trapped by silk and patience. Named specimens such as Shanda the Spinner become local hazards worth recording.",
        [5] = "The lurkers of Loch Modan embody the danger of the unseen. Where bears warn with weight and crocolisks with water, lurkers make the forest itself feel like it might close around the unwary.",
    }
}

-- =========================
-- LOCH MODAN: HUMANOID AND MONSTROUS GROUPS
-- =========================

FieldJournal_LoreDB.LOCH_MODAN_STONESPLINTER_TROGGS = {
    id = "LOCH_MODAN_STONESPLINTER_TROGGS",
    displayName = "Stonesplinter Troggs",
    ldr = "LDR-LM-6",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_02",
    zones = { "Loch Modan" },

    npcs = {
        1161, -- Stonesplinter Trogg
        1162, -- Stonesplinter Scout
        1163, -- Stonesplinter Skullthumper
        1164, -- Stonesplinter Bonesnapper
        1165, -- Stonesplinter Geomancer
        1166, -- Stonesplinter Seer / Berserk Trogg records in local lists
        1167, -- Stonesplinter Digger
        1197, -- Stonesplinter Shaman
        1398, -- Boss Galgosh
        1399, -- Magosh
        1425, -- Grizlak
    },

    lore = {
        [1] = "The Stonesplinter troggs are hostile subterranean humanoids active throughout Loch Modan. They are crude, violent, and strongly associated with caves, valleys, mines, and broken ground.",
        [2] = "Trogg groups rely on numbers, blunt weapons, and a willingness to fight in cramped terrain. I found scouts near the edges, skullthumpers and bonesnappers in the thick of fighting, and geomancers or seers where the tribe showed more organized threat.",
        [3] = "Loch Modan is heavily troubled by trogg activity, especially around Stonesplinter Valley and nearby caves. Classic zone records describe Loch Modan as populated by hostile troggs unearthed from underground, making them one of the defining dangers of the region.",
        [4] = "For the dwarves of Thelsamar and Ironband's Excavation, the Stonesplinter are more than wandering monsters. They threaten roads, dig sites, patrols, and the King's lands, forcing the mountaineers to treat them as a standing enemy.",
        [5] = "The Stonesplinter troggs are Loch Modan's oldest pressure from below. They make the land feel unstable beneath dwarven roads and halls, reminding every traveler that Khaz Modan's mountains hold enemies as well as stone.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_MOGROSH_OGRES = {
    id = "LOCH_MODAN_MOGROSH_OGRES",
    displayName = "Mo'grosh Ogres",
    ldr = "LDR-LM-7",
    icon = "Interface\\Icons\\INV_Misc_Head_Ogre_01",
    zones = { "Loch Modan" },

    npcs = {
        1178, -- Mo'grosh Ogre
        1180, -- Mo'grosh Brute
        1179, -- Mo'grosh Enforcer
        1181, -- Mo'grosh Shaman
        1183, -- Mo'grosh Mystic
        1205, -- Grawmug
        1210, -- Chok'sul
        14267, -- Emogg the Crusher
    },

    lore = {
        [1] = "The Mo'grosh ogres are large, brutal humanoids occupying strongholds and rough highland ground in Loch Modan. Their size alone makes them dangerous, and their shamans and mystics show that brute force is not their only weapon.",
        [2] = "Mo'grosh patrols are not subtle. Broken ground, heavy tracks, and crude camps mark their territory, while brutes and enforcers use raw strength to hold it against intruders.",
        [3] = "Mo'grosh Stronghold gives the ogres a clear foothold in the region. From there, they threaten travelers, hunters, and dwarven authority along the eastern and rugged parts of Loch Modan.",
        [4] = "The WANTED: Chok'sul bounty reflects how seriously Thelsamar treats the Mo'grosh threat. A single ogre leader can become a regional problem when strength, followers, and terrain all favor him.",
        [5] = "The Mo'grosh ogres represent Loch Modan's open, physical menace. Where troggs rise from caves and Dark Irons strike with sabotage, the ogres simply occupy the land by force and dare the dwarves to remove them.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_TUNNEL_RAT_KOBOLDS = {
    id = "LOCH_MODAN_TUNNEL_RAT_KOBOLDS",
    displayName = "Tunnel Rat Kobolds",
    ldr = "LDR-LM-8",
    icon = "Interface\\Icons\\INV_Misc_Candle_01",
    zones = { "Loch Modan" },

    npcs = {
        1091, -- Tunnel Rat Kobold
        1172, -- Tunnel Rat Vermin
        1173, -- Tunnel Rat Scout
        1174, -- Tunnel Rat Geomancer
        1175, -- Tunnel Rat Digger
        1176, -- Tunnel Rat Forager
        1177, -- Tunnel Rat Surveyor
        1206, -- Gnasher
    },

    lore = {
        [1] = "Tunnel Rat kobolds are candle-bearing humanoids found in and around Loch Modan's mines. They are smaller than troggs or ogres, but their numbers and familiarity with tunnels make them a real hazard.",
        [2] = "These kobolds dig, scavenge, scout, and defend their claims with desperate persistence. I found that geomancers and surveyors suggest more organization than their fearful cries might first imply.",
        [3] = "Silver Stream Mine and other worked places give the Tunnel Rat kobolds room to spread. The dwarven hunger for ore brings miners into direct conflict with creatures already living beneath the hills.",
        [4] = "To Thelsamar, the Tunnel Rat problem is both economic and defensive. A mine lost to kobolds is not merely dangerous; it cuts into supply, trade, and the steady labor that supports the region.",
        [5] = "The Tunnel Rat kobolds are Loch Modan's small, stubborn claimants below the surface. They show that even a lesser enemy can become important when it controls the dark spaces others need to enter.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_DARK_IRON = {
    id = "LOCH_MODAN_DARK_IRON",
    displayName = "Dark Iron Dwarves",
    ldr = "LDR-LM-9",
    icon = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
    zones = { "Loch Modan" },

    npcs = {
        2149, -- Dark Iron Raider
        1222, -- Dark Iron Sapper
        1169, -- Dark Iron Insurgent
        1981, -- Dark Iron Ambusher
        2057, -- Huldar
        3291, -- Rann Flamespinner
    },

    lore = {
        [1] = "The Dark Iron dwarves in Loch Modan are hostile dwarven enemies tied to sabotage, raids, and the long rivalries of Khaz Modan. Unlike beasts or troggs, they bring discipline, tools, and intent to their attacks.",
        [2] = "Dark Iron raiders and sappers strike with purpose, often near strategic targets. I found their work most troubling around the Stonewrought Dam, where a small act of sabotage could threaten far more than a patrol route.",
        [3] = "Loch Modan's dam, roads, and dwarven settlements make the region strategically valuable. The A Dark Threat Looms chain centers on countering Dark Iron danger around the dam, reinforcing their role as a serious local threat.",
        [4] = "For Ironforge and Thelsamar, the Dark Irons are not random marauders but enemies bound to dwarven history and factional conflict. Their presence turns Loch Modan from frontier wilderness into a contested military landscape.",
        [5] = "The Dark Iron dwarves are Loch Modan's political shadow: kin turned enemy, attacking stone, road, and order from within Khaz Modan's own story. Their study belongs beside beasts and troggs because they threaten not only lives, but infrastructure and trust.",
    }
}

FieldJournal_LoreDB.LOCH_MODAN_DRAGONKIN = {
    id = "LOCH_MODAN_DRAGONKIN",
    displayName = "Wandering Dragonkin",
    ldr = "LDR-LM-10",
    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    zones = { "Loch Modan" },

    npcs = {
        2757, -- Blacklash
        2759, -- Hematus
    },

    lore = {
        [1] = "Rare dragonkin sightings in Loch Modan include dangerous named drakes such as Blacklash and Hematus. They are not common wildlife, and any encounter with them should be treated as exceptional.",
        [2] = "Dragonkin move with a confidence unlike ordinary beasts. I noted that their presence changes the feel of an area immediately, as though the land itself has become too small for the creature crossing it.",
        [3] = "Loch Modan is not defined primarily by dragons, which makes such sightings stand apart from the usual pattern of troggs, ogres, and local beasts. Their wandering presence suggests that even familiar zones can be crossed by threats from larger stories.",
        [4] = "To a mountaineer or hunter, a dragonkin sighting is more than a hunting tale. It is a warning that the region's dangers are not limited to local tribes or animals, and that Khaz Modan remains connected to greater powers moving through Azeroth.",
        [5] = "The wandering dragonkin of Loch Modan are rare marks of scale in the field journal. They remind the observer that a regional survey may begin with boars and kobolds, yet still end beneath the shadow of something far older and more dangerous.",
    }
}

-- =========================
-- WESTFALL: BEASTS
-- =========================

FieldJournal_LoreDB.WESTFALL_COYOTES = {
    id = "WESTFALL_COYOTES",
    displayName = "Coyotes",
    ldr = "LDR-WF-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Westfall" },

    npcs = {
        834, -- Coyote
        833, -- Coyote Packleader
    },

    lore = {
        [1] = "Coyotes are lean scavenging predators common across the dry fields and broken roads of Westfall. They are smaller than the great wolves of colder lands, but hunger and numbers make them dangerous to travelers and livestock.",
        [2] = "Coyote signs appear around abandoned farms, fence lines, and carrion left in the open. I found their packleaders bolder than the rest, often lingering near prey while the lesser coyotes circled and tested for weakness.",
        [3] = "Westfall's drought-struck fields suit opportunistic animals. With farms ruined and carcasses left by war, banditry, and neglect, coyotes have little need to stay far from human roads.",
        [4] = "To the farmers of Westfall, coyotes are another hardship in a land already stripped thin. They do not carry banners like the Defias, but they profit from the same collapse of order.",
        [5] = "The coyotes of Westfall are the sound of a hungry province. They follow in the wake of abandonment, surviving where steadier creatures would fail and reminding the observer that decay feeds more than criminals.",
    }
}

FieldJournal_LoreDB.WESTFALL_GORETUSKS = {
    id = "WESTFALL_GORETUSKS",
    displayName = "Goretusks",
    ldr = "LDR-WF-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Westfall" },

    npcs = {
        454, -- Young Goretusk
        157, -- Goretusk
        547, -- Great Goretusk
    },

    lore = {
        [1] = "Goretusks are tusked boars of Westfall, known for their heavy bodies and aggressive charges. They range from young animals to great adults strong enough to threaten any careless traveler.",
        [2] = "Their tracks cut across dry soil and ruined farm rows, often near places where roots and scraps remain. I found that a goretusk does not need malice to be dangerous; panic and muscle are enough.",
        [3] = "The fallow farms of Westfall give goretusks room to root and roam. Once cultivated fields now serve as feeding grounds, blurring the line between livestock country and wild territory.",
        [4] = "Goretusks are tied to daily survival in Westfall, not only as threats but as food. Local recipes and requests for meat show how farmers use whatever the harsh land still provides.",
        [5] = "The goretusks of Westfall embody the stubborn life left in ruined farmland. They are rough, useful, and dangerous, much like the province itself after years of neglect.",
    }
}

FieldJournal_LoreDB.WESTFALL_FLESHRIPPERS = {
    id = "WESTFALL_FLESHRIPPERS",
    displayName = "Fleshrippers",
    ldr = "LDR-WF-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Vulture",
    zones = { "Westfall" },

    npcs = {
        199,  -- Young Fleshripper
        1109, -- Fleshripper
        154,  -- Greater Fleshripper
        462,  -- Vultros
    },

    lore = {
        [1] = "Fleshrippers are carrion birds that circle Westfall's plains and fields. Their hooked beaks and patient flight mark them as scavengers, though they are fully capable of attacking the living when hunger drives them close.",
        [2] = "The birds descend where fighting, dead livestock, or exposed remains promise food. I noticed that even young fleshrippers watch from above with the same cold patience as the older birds.",
        [3] = "Westfall's open sky and ruined farms make ideal country for carrion birds. In a healthier land they would follow natural death; here, neglect and violence provide them with a feast.",
        [4] = "To Westfall's people, fleshrippers are grim symbols of the province's condition. They are not responsible for the suffering below, but they are always present to claim what suffering leaves behind.",
        [5] = "The fleshrippers of Westfall are the witnesses overhead. Their shadows cross abandoned fields, Defias camps, and militia roads alike, recording in their own way how much the land has lost.",
    }
}

FieldJournal_LoreDB.WESTFALL_CRABS = {
    id = "WESTFALL_CRABS",
    displayName = "Coastal Crawlers",
    ldr = "LDR-WF-4",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    zones = { "Westfall" },

    npcs = {
        6250, -- Crawler
        235,  -- Sand Crawler
        830,  -- Sea Crawler
        1216, -- Shore Crawler
    },

    lore = {
        [1] = "Coastal crawlers are crablike beasts found along Westfall's beaches and tide pools. Their hard shells and snapping claws make them simple but stubborn shoreline hazards.",
        [2] = "Crawlers hold close to the surf, half-hidden in sand or shallow water until approached. I found their movement slow compared to wolves or murlocs, but their claws punish anyone who treats them as harmless.",
        [3] = "Westfall's long coast gives these creatures ample feeding ground. Wreckage, fish remains, and the constant wash of the Great Sea support a different ecology from the dry farms inland.",
        [4] = "For travelers along the coast, crawlers are part of the practical danger of gathering supplies near the water. They are not a grand threat, but many small wounds can still end a journey.",
        [5] = "The coastal crawlers of Westfall mark the meeting of famine-struck land and indifferent sea. They endure where waves erase tracks, feeding quietly beside larger troubles.",
    }
}

FieldJournal_LoreDB.WESTFALL_DUST_DEVILS = {
    id = "WESTFALL_DUST_DEVILS",
    displayName = "Dust Devils",
    ldr = "LDR-WF-5",
    icon = "Interface\\Icons\\Spell_Nature_Cyclone",
    zones = { "Westfall" },

    npcs = {
        832, -- Dust Devil
    },

    lore = {
        [1] = "Dust devils are hostile wind elementals found across Westfall's dry plains. Their bodies are little more than moving air, dust, and force gathered into a dangerous shape.",
        [2] = "A dust devil announces itself through swirling grit and sudden pressure changes in the air. I found them difficult to read like beasts, since they show no fear, hunger, or ordinary instinct.",
        [3] = "Westfall's barren soil and constant wind provide fitting conditions for such elementals. The land is dry enough that even the weather seems capable of turning against the living.",
        [4] = "To farmers, a dust devil is both hazard and omen: the field made hostile. It is easy to understand why locals speak of the land itself as wounded when the dust rises with claws of its own.",
        [5] = "The dust devils of Westfall are the province's drought given motion. They make the air itself part of the field record, proof that Westfall's decay is not only political or criminal but environmental as well.",
    }
}

-- =========================
-- WESTFALL: CONSTRUCTS AND HOSTILE HUMANOIDS
-- =========================

FieldJournal_LoreDB.WESTFALL_HARVEST_GOLEMS = {
    id = "WESTFALL_HARVEST_GOLEMS",
    displayName = "Harvest Golems",
    ldr = "LDR-WF-6",
    icon = "Interface\\Icons\\INV_Gizmo_01",
    zones = { "Westfall" },

    npcs = {
        36,     -- Harvest Golem
        115,    -- Harvest Reaper
        114,    -- Harvest Watcher
        480,    -- Rusty Harvest Golem
        573,    -- Foe Reaper 4000
        210501, -- Harvest Reaper Prototype
        212252, -- Harvest Golem V000-A
    },

    lore = {
        [1] = "Harvest golems are mechanical field machines found wandering Westfall's farms. Built for labor, they have become a danger where oversight has failed and fields have fallen into ruin.",
        [2] = "Their movements are heavy, repetitive, and uncaring, like work continued after purpose has rotted away. I found that even rusted models can strike hard enough to crush an unarmored farmer.",
        [3] = "Westfall's abandoned croplands are ideal ground for malfunctioning harvest machines. They remain among the fields they were meant to serve, turning old industry into another threat against recovery.",
        [4] = "The golems are a bitter symbol of Westfall's collapse. Tools once meant to feed Stormwind now stalk the fields beside bandits and beasts, showing how neglect can corrupt even useful craft.",
        [5] = "The harvest golems of Westfall are labor without stewardship. They summarize the tragedy of the province: farms built to nourish a kingdom, left to break down until the machinery itself became hostile.",
    }
}

FieldJournal_LoreDB.WESTFALL_DEFIAS = {
    id = "WESTFALL_DEFIAS",
    displayName = "Defias Brotherhood",
    ldr = "LDR-WF-7",
    icon = "Interface\\Icons\\INV_Mask_04",
    zones = { "Westfall" },

    npcs = {
        502,  -- Benny Blaanco
        520,  -- Brack
        619,  -- Defias Conjurer
        824,  -- Defias Digger
        7050, -- Defias Drone
        481,  -- Defias Footpad
        594,  -- Defias Henchman
        122,  -- Defias Highwayman
        449,  -- Defias Knuckleduster
        590,  -- Defias Looter
        550,  -- Defias Messenger
        121,  -- Defias Pathstalker
        589,  -- Defias Pillager
        1669, -- Defias Profiteer
        6180, -- Defias Raider
        450,  -- Defias Renegade Mage
        210549, -- Defias Scout
        95,   -- Defias Smuggler
        7052, -- Defias Tower Patroller
        7056, -- Defias Tower Sentry
        504,  -- Defias Trapper
        7053, -- Klaven Mortwake
        209548, -- Malformed Defias Drone
        467,  -- The Defias Traitor
    },

    lore = {
        [1] = "The Defias Brotherhood is the dominant organized threat in Westfall, appearing as footpads, looters, pillagers, smugglers, trappers, and spellcasters. Unlike beasts, they occupy farms, roads, mines, and towers with deliberate purpose.",
        [2] = "Defias patrols use ambush, numbers, and local knowledge to control ruined settlements. I found red cloth, stolen supplies, and guarded paths wherever their influence had settled in deeply.",
        [3] = "Classic records describe Westfall as heavily choked by Defias activity, with the Brotherhood controlling camps, farmsteads, Moonbrook, and the hidden path toward the Deadmines. Their spread explains why ordinary farmers cannot simply return to their fields.",
        [4] = "The Defias are more than bandits; they are the political wound of Stormwind made armed and local. In Westfall, the failure of noble protection and the anger of dispossessed workers take visible form behind red masks.",
        [5] = "The Defias Brotherhood is the central subject of any Westfall field journal. They are criminals, rebels, laborers, and occupiers all at once, and their presence turns a starving province into a battlefield over justice, revenge, and survival.",
    }
}

FieldJournal_LoreDB.WESTFALL_RIVERPAW_GNOLLS = {
    id = "WESTFALL_RIVERPAW_GNOLLS",
    displayName = "Riverpaw Gnolls",
    ldr = "LDR-WF-8",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Westfall" },

    npcs = {
        452, -- Riverpaw Bandit
        124, -- Riverpaw Brute
        117, -- Riverpaw Gnoll
        501, -- Riverpaw Herbalist
        1426, -- Riverpaw Miner
        123, -- Riverpaw Mongrel
        453, -- Riverpaw Mystic
        125, -- Riverpaw Overseer
        500, -- Riverpaw Scout
        1065, -- Riverpaw Shaman
        98, -- Riverpaw Taskmaster
        519, -- Slark
    },

    lore = {
        [1] = "Riverpaw gnolls are hyena-like humanoids occupying parts of Westfall, particularly around mines, hills, and broken farm country. They are raiders and scavengers, dangerous both alone and in packs.",
        [2] = "Their camps show crude organization: scouts, brutes, mystics, miners, overseers, and taskmasters each filling a rough role. I found that their disorder is deceptive; they know how to hold ground when pressed.",
        [3] = "Westfall's weakened state gives the Riverpaw room to expand from the edges. Where Stormwind authority thins, gnoll camps and work gangs appear, competing with Defias and farmers alike for control of the land.",
        [4] = "To the People's Militia, Riverpaw gnolls are part of the same survival crisis as bandits and broken machines. They are not the root of Westfall's fall, but they worsen every attempt to recover it.",
        [5] = "The Riverpaw gnolls of Westfall represent opportunistic pressure on a wounded province. They gather where order has failed, turning abandoned ground into contested territory one campfire at a time.",
    }
}

FieldJournal_LoreDB.WESTFALL_MURLOCS = {
    id = "WESTFALL_MURLOCS",
    displayName = "Coastal Murlocs",
    ldr = "LDR-WF-9",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Westfall" },

    npcs = {
        126, -- Murloc Coastrunner
        458, -- Murloc Hunter
        456, -- Murloc Minor Oracle
        513, -- Murloc Netter
        517, -- Murloc Oracle
        515, -- Murloc Raider
        127, -- Murloc Tidehunter
        171, -- Murloc Warrior
        391, -- Old Murk-Eye
    },

    lore = {
        [1] = "Westfall's murlocs are amphibious humanoids found along the coast and near the shallows. Their tribes include hunters, oracles, netters, raiders, and warriors, making them more organized than their croaking speech first suggests.",
        [2] = "Murlocs fight best near water, where retreat and reinforcement come easily. I learned to watch the shoreline carefully; one cry can turn a single skirmish into a swarm.",
        [3] = "Westfall's coast gives murlocs a long border with human settlement. The same beaches that offer fishing, wreckage, and travel also provide murloc clans with paths inland.",
        [4] = "For the people of Westfall, murlocs are a coastal menace layered atop famine and banditry. They make the sea unreliable at the very moment the land itself can barely sustain its farmers.",
        [5] = "The coastal murlocs of Westfall are the danger beneath the surf's constant noise. Their camps complete the province's encirclement: Defias in the towns, gnolls in the hills, golems in the fields, and murlocs at the waterline.",
    }
}

FieldJournal_LoreDB.WESTFALL_KOBOLDS = {
    id = "WESTFALL_KOBOLDS",
    displayName = "Jangolode Kobolds",
    ldr = "LDR-WF-10",
    icon = "Interface\\Icons\\INV_Misc_Candle_01",
    zones = { "Westfall" },

    npcs = {
        1236, -- Kobold Digger
    },

    lore = {
        [1] = "Kobold diggers are candle-bearing tunnelers found in Westfall's mines. They are physically small but stubbornly territorial around ore, tunnels, and whatever treasures they claim below ground.",
        [2] = "Kobold signs include loose earth, candle stubs, and cramped passages widened by crude tools. I found their digging less disciplined than dwarven work, but persistent enough to undermine any claim that a mine is secure.",
        [3] = "Classic Westfall records connect kobolds with Jangolode Mine, tying underground trouble to the province's surface collapse. Even the mineral workings are not free from occupation and theft.",
        [4] = "To Westfall's settlers, kobolds are a smaller concern than the Defias, yet they still matter. A mine in enemy hands means lost ore, lost tools, and one more resource denied to recovery.",
        [5] = "The kobolds of Westfall are a narrow but telling subject: the province's ruin extends below the fields. Their candles mark the underside of Westfall's struggle for labor, resources, and control.",
    }
}

FieldJournal_LoreDB.WESTFALL_RESTLESS_DEAD = {
    id = "WESTFALL_RESTLESS_DEAD",
    displayName = "Restless Dead",
    ldr = "LDR-WF-11",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    zones = { "Westfall" },

    npcs = {
        2044, -- Forlorn Spirit
        846,  -- Ghoul
        572,  -- Leprithus
        506,  -- The Snatcher
        523,  -- Undying Laborer
    },

    lore = {
        [1] = "The restless dead of Westfall include ghouls, spirits, and named horrors that appear among graveyards, ruins, and lonely places. They are not the common face of the province's crisis, but their presence is unmistakable.",
        [2] = "Undead signs are unlike beast spoor or bandit tracks. I found cold places, uneasy silence, and the sense that something remained after life and purpose should have ended.",
        [3] = "Westfall is not a plague land, but suffering leaves marks. In a region of abandoned farms, murdered travelers, and broken communities, the dead have many reasons to be unquiet.",
        [4] = "For the people trying to reclaim Westfall, undead sightings carry spiritual as well as physical weight. They suggest that the province needs healing, burial, and justice, not merely patrols.",
        [5] = "The restless dead of Westfall are the field journal's quietest warning. Beneath the louder war against Defias and hunger lies a deeper cost: some wounds remain active even after the body falls still.",
    }
}

FieldJournal_LoreDB.WESTFALL_SHARKS = {
    id = "WESTFALL_SHARKS",
    displayName = "Reef Sharks",
    ldr = "LDR-WF-12",
    icon = "Interface\\Icons\\INV_Misc_Fish_05",
    zones = { "Westfall" },

    npcs = {
        12123, -- Reef Shark
    },

    lore = {
        [1] = "Reef sharks are aquatic predators found off Westfall's coast. They are not creatures of the road or farm, but the sea has its own hunters.",
        [2] = "A reef shark gives little warning beyond the motion of water and a sudden turn beneath the surface. I found the open coast less forgiving once I remembered that danger can rise from below as easily as from the dunes.",
        [3] = "Westfall's western edge meets the Great Sea, and its waters support predators apart from the troubles ashore. The coastline is therefore both boundary and habitat.",
        [4] = "For fishers, swimmers, and wreck scavengers, sharks are a practical risk. They care nothing for Defias claims or militia patrols, only blood and movement in the water.",
        [5] = "The reef sharks of Westfall complete the region's natural record. They remind the observer that beyond the farms, mines, and human conflicts, the Great Sea remains wild and indifferent.",
    }
}



-- =========================================================
-- DARKSHORE: BEASTS, SPIRITS, NAGA, SATYR, AND CULTISTS
-- =========================================================

FieldJournal_LoreDB.DARKSHORE_MOONSTALKERS = {
    id = "DARKSHORE_MOONSTALKERS",
    displayName = "Moonstalkers",
    ldr = "LDR-DS-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Darkshore" },
    npcs = { 2070, 2069, 2237, 2238 },
    lore = {
        [1] = "Moonstalkers are nightsaber-like cats found in the shadowed forests of Darkshore. They are natural predators rather than corrupted creatures, but their stealth and strength make them dangerous near the road or ruins.",
        [2] = "Moonstalkers hunt from cover, using the dim woods and uneven ground to approach before prey fully marks their presence. I found their tracks where brush narrowed and travelers might pass too close to the trees.",
        [3] = "Darkshore's long gloom and thick coastal forest give these cats excellent hunting ground. Their survival shows that the region remains wild beneath the ruins, wreckage, and political trouble that crowd the shore.",
        [4] = "For the kaldorei and other Alliance travelers, moonstalkers are part of Darkshore's natural trial. They are not enemies of civilization by intent, but a reminder that even sacred lands are not tame lands.",
        [5] = "The moonstalkers of Darkshore are the forest's quiet teeth. They belong to the old wilderness that persists between Auberdine's lamps and the ancient ruins, and no field record of the coast is complete without them."
    }
}

FieldJournal_LoreDB.DARKSHORE_THISTLE_BEARS = {
    id = "DARKSHORE_THISTLE_BEARS",
    displayName = "Thistle Bears",
    ldr = "LDR-DS-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Darkshore" },
    npcs = { 2163, 2164, 2165, 6788, 6789 }, -- Thistle Cub
    lore = {
        [1] = "Thistle bears are large forest bears native to Darkshore and its surrounding woodland. Their size, claws, and stubborn territorial behavior make them one of the coast's more direct natural hazards.",
        [2] = "The bears leave broad tracks, scratched bark, and broken brush around their feeding grounds. I found that even a sickly or agitated bear remains more than strong enough to break an inexperienced guard's line.",
        [3] = "Darkshore's damp woods sustain bears well, though disease, corruption, and disturbed ruins have made some animals more aggressive than ordinary wilderness behavior would suggest.",
        [4] = "To the night elves, a bear is often both respected beast and practical danger. Observing the thistle bears makes clear how the kaldorei's reverence for nature must coexist with the hard work of surviving it.",
        [5] = "The thistle bears of Darkshore represent the region's wounded wild strength. They are native creatures enduring a coastline crowded by loss, corruption, and refugee labor, and they should be recorded with respect as well as caution."
    }
}

FieldJournal_LoreDB.DARKSHORE_FORESTSTRIDERS = {
    id = "DARKSHORE_FORESTSTRIDERS",
    displayName = "Foreststriders",
    ldr = "LDR-DS-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
    zones = { "Darkshore" },
    npcs = { 2321, 2322, 2323 },
    lore = {
        [1] = "Foreststriders are tall, long-legged birds found in Darkshore's open woods and coastal clearings. They are not inherently monstrous, but their speed and sharp beaks can make them troublesome when startled or cornered.",
        [2] = "A foreststrider's trail is easy to spot where long steps cross wet soil. I found them watchful and quick to flee unless pressed, though older striders can turn surprisingly fierce.",
        [3] = "These birds thrive where Darkshore's forest opens into marshy clearings or broken coastal ground. Their presence marks healthier patches of the ecosystem, places where ordinary animal life continues despite the region's gloom.",
        [4] = "Foreststriders are part of the practical texture of kaldorei lands: game, hazard, and sign of local balance. They lack the malice of satyr or naga but still shape travel through the coast.",
        [5] = "The foreststriders of Darkshore are reminders that the zone is not only a place of tragedy. Among ruins and haunted beaches, ordinary wild creatures still move through the trees and keep the land alive."
    }
}

FieldJournal_LoreDB.DARKSHORE_GRELLS_AND_SPRITES = {
    id = "DARKSHORE_GRELLS_AND_SPRITES",
    displayName = "Grells and Vile Sprites",
    ldr = "LDR-DS-4",
    icon = "Interface\\Icons\\INV_Misc_Head_Elf_02",
    zones = { "Darkshore" },
    npcs = { 2190, 2191, 2192, 2189 },
    lore = {
        [1] = "Grells and vile sprites are small, troublesome fae-like creatures encountered around Darkshore's ancient ruins. Though individually slight, they become dangerous in numbers and through their ties to darker influences.",
        [2] = "They favor ruins, moonwells, and old kaldorei sites where magic and neglect mingle. I found their behavior erratic, with sudden attacks and retreats that made them hard to predict.",
        [3] = "Darkshore's ruined places, especially areas such as Bashal'Aran and Ameth'Aran, provide the kind of disturbed magical ground where sprites and grells become more than woodland nuisances.",
        [4] = "Their presence is significant because it shows how sacred or historical kaldorei places can become corrupted. A ruined temple is not merely stone; it can become a shelter for lesser creatures drawn to lingering power.",
        [5] = "The grells and vile sprites of Darkshore are the small claws of old disorder. They are not the greatest threat on the coast, but they reveal how corruption first takes root in forgotten corners."
    }
}

FieldJournal_LoreDB.DARKSHORE_NAGA = {
    id = "DARKSHORE_NAGA",
    displayName = "Naga",
    ldr = "LDR-DS-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Darkshore" },
    npcs = { 2201, 2202, 2203, 2204, 2205, 2206 },
    lore = {
        [1] = "The naga of Darkshore are serpentine humanoids found near the coast, ruins, and waters. They are intelligent, hostile, and far more organized than ordinary shoreline predators.",
        [2] = "Naga patrol in groups and use the waterline to their advantage. I found that their warriors and spellcasters guarded coastal ruins with purpose, not animal territorial instinct.",
        [3] = "Darkshore's broken coastline, ancient kaldorei remains, and access to the Great Sea make it suitable ground for naga intrusion. Their presence ties local field work to deeper histories beneath the sea.",
        [4] = "Naga activity is culturally significant because of their ancient connection to the kaldorei past. In Darkshore, their hostility feels like old ruin rising again from the tide.",
        [5] = "The naga of Darkshore are the coast's hostile memory. They turn beaches and ruins into contested ground, forcing any observer to treat the sea itself as an active frontier."
    }
}

FieldJournal_LoreDB.DARKSHORE_SATYR = {
    id = "DARKSHORE_SATYR",
    displayName = "Satyr",
    ldr = "LDR-DS-6",
    icon = "Interface\\Icons\\Spell_Shadow_SummonSatyr",
    zones = { "Darkshore" },
    npcs = { 2168, 2169, 2170, 2171, 2172, 2212, 10373 },
    lore = {
        [1] = "Satyr are demonic, corrupted beings tied to fel influence and betrayal in kaldorei history. In Darkshore, they appear as organized corruptors rather than mere wandering monsters.",
        [2] = "Satyr camps show discipline, cruelty, and ritual purpose. I found them more dangerous than beasts because they seek to spread corruption as much as defend territory.",
        [3] = "Darkshore's ancient forests and wounded ruins give satyr places to hide and poison. Their presence often explains why nearby lesser creatures become more violent or warped.",
        [4] = "For the night elves, satyr are a deeply cultural and historical threat. They are living reminders of corruption within ancient kinship, making their camps more than simple enemy positions.",
        [5] = "The satyr of Darkshore represent the forest turned against itself. Their study belongs in the journal because they show how spiritual damage can become ecological and military danger."
    }
}

FieldJournal_LoreDB.DARKSHORE_TWILIGHT_CULTISTS = {
    id = "DARKSHORE_TWILIGHT_CULTISTS",
    displayName = "Twilight's Hammer Cultists",
    ldr = "LDR-DS-7",
    icon = "Interface\\Icons\\Spell_Shadow_Twilight",
    zones = { "Darkshore" },
    npcs = { 2335, 2336, 2337, 2338, 2339 }, -- Twilight Thug
    lore = {
        [1] = "Twilight's Hammer cultists are mortal servants of dark, destructive powers. In Darkshore, they are not native creatures but intruders who treat the wounded coast as useful ground for ritual and secrecy.",
        [2] = "Their camps show signs of organized belief: guarded tents, ritual objects, and hostile response to discovery. I found that cultists fight with fanatic certainty rather than simple self-preservation.",
        [3] = "Darkshore's remote beaches and ruined places give cult activity cover. The region's sorrow and isolation make it a dangerous place for such groups to work unseen.",
        [4] = "The cultists matter because they link local patrol work to wider threats across Azeroth. A single camp on the coast can point toward much larger forces moving beneath ordinary politics.",
        [5] = "The Twilight's Hammer in Darkshore are proof that wounded lands attract opportunists. Their presence turns grief, ruin, and distance from authority into a stage for darker designs."
    }
}

FieldJournal_LoreDB.DARKSHORE_THRESHERS = {
    id = "DARKSHORE_THRESHERS",
    displayName = "Darkshore Threshers",
    ldr = "LDR-DS-8",
    icon = "Interface\\Icons\\INV_Misc_Fish_02",
    zones = { "Darkshore" },
    npcs = { 2185 }, -- Darkshore Thresher
    lore = {
        [1] = "Threshers patrol Darkshore's coastal waters. A quiet stretch of shore can conceal one below the surface.",
        [2] = "I watch the surf and shallows before crossing, as these hunters have the advantage when a traveler enters the water.",
        [3] = "Darkshore's reefs and broken coastline provide shelter and feeding grounds for aquatic predators.",
        [4] = "These creatures make fishing, salvage, and coastal travel risky even where no naga or satyr are present.",
        [5] = "The coast is a living habitat as well as a frontier. Its predators belong in the field record alongside the dangers on land.",
    },
}

FieldJournal_LoreDB.DARKSHORE_MOONKIN = {
    id = "DARKSHORE_MOONKIN",
    displayName = "Moonkin",
    ldr = "LDR-DS-9",
    icon = "Interface\\Icons\\Spell_Nature_ForceOfNature",
    zones = { "Darkshore" },
    npcs = { 10158 }, -- Moonkin
    lore = {
        [1] = "Moonkin are great owl-like beings found in Darkshore's wilderness, distinct from its ordinary birds and foreststriders.",
        [2] = "Their size and unusual bearing make them easy to recognize, though a careful observer keeps a respectful distance.",
        [3] = "The wooded edges of Darkshore give moonkin room to move away from the busier coastal settlements.",
        [4] = "Their presence is one more sign that this land holds creatures shaped by old natural powers as well as familiar wildlife.",
        [5] = "A field record of Darkshore's creatures would be incomplete without these imposing inhabitants of the forest.",
    },
}

-- =========================================================
-- SILVERPINE FOREST: FORSAKEN FRONTIER THREATS
-- =========================================================

FieldJournal_LoreDB.SILVERPINE_WORGEN = {
    id = "SILVERPINE_WORGEN",
    displayName = "Worgen",
    ldr = "LDR-SP-1",
    icon = "Interface\\Icons\\Ability_Druid_Rake",
    zones = { "Silverpine Forest" },
    npcs = { 1893, 1894, 1895, 1896, 1957, 1779, 1782, 203139 },
    lore = {
        [1] = "Worgen are ferocious wolf-like humanoids haunting Silverpine Forest, especially near Pyrewood and the roads toward Shadowfang territory. They are not ordinary wolves but cursed, violent creatures with humanoid cunning.",
        [2] = "Worgen strike with claws and pack aggression, often closing distance quickly from the trees or village ruins. I found their howls carried strangely in Silverpine's dead air, making distance difficult to judge.",
        [3] = "Silverpine's gloomy woods, abandoned settlements, and proximity to the Greymane Wall and Shadowfang Keep make it fitting territory for worgen activity. The forest itself seems to hide them well.",
        [4] = "Worgen are significant to Silverpine because they embody the fear surrounding Gilneas, Pyrewood, and the cursed shape of the region's history. For the Forsaken, they are both enemy and warning.",
        [5] = "The worgen of Silverpine are the forest's unnatural howl. They turn villages and roads into hunting grounds, blending bestial violence with the tragedy of cursed humanity."
    }
}

FieldJournal_LoreDB.SILVERPINE_MOONRAGE = {
    id = "SILVERPINE_MOONRAGE",
    displayName = "Moonrage Wolves",
    ldr = "LDR-SP-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Silverpine Forest" },
    npcs = { 1766, 1765, 1767, 1768, 1778 },
    lore = {
        [1] = "Moonrage wolves and related lycanthropic beasts prowl Silverpine's dark woods. Their name alone separates them from ordinary forest wolves, suggesting a local strain of violence tied to the forest's cursed reputation.",
        [2] = "These wolves move through the trees with speed and aggression. I found their behavior more hostile than simple predator caution, especially near settlements touched by worgen trouble.",
        [3] = "Silverpine's sickly forest provides heavy cover and little comfort. Such conditions suit predators that rely on fear, darkness, and broken lines of sight.",
        [4] = "For the Forsaken, wolves in Silverpine are not merely hunting pests. Their proximity to worgen legends and cursed settlements makes them part of a wider pattern of transformation and loss.",
        [5] = "The Moonrage wolves are Silverpine's border between natural and unnatural danger. They may still wear the shape of beasts, but the forest around them has made every howl suspect."
    }
}

FieldJournal_LoreDB.SILVERPINE_FOREST_BEASTS = {
    id = "SILVERPINE_FOREST_BEASTS",
    displayName = "Forest Beasts",
    ldr = "LDR-SP-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Silverpine Forest" },
    npcs = { 1772, 1773, 1770, 1771, 1769, 1780, 1781, 1797 },
    lore = {
        [1] = "Silverpine's bears, spiders, and prowlers are natural forest beasts surviving in a land altered by plague, death, and abandonment. They are not necessarily undead or cursed, but they are hardened by the region.",
        [2] = "I found that the beasts here behave with the same suspicion as the forest itself: quick to vanish into dead trees, then sudden in attack when approached carelessly.",
        [3] = "Warcraft Wiki describes Silverpine as a primeval western Lordaeron forest, sickly, silent, and dotted with abandoned farmsteads and mines. Such terrain sustains predators but gives them a haunted cast.",
        [4] = "These beasts matter because they show that Silverpine is not dead, only changed. Natural life persists among Forsaken patrols, worgen, and ruins, often as dangerous as the unnatural things nearby.",
        [5] = "Silverpine's forest beasts are the living part of a half-dead land. They make the field record more complex, proving that not every danger beneath the dead trees comes from curse or grave."
    }
}

FieldJournal_LoreDB.SILVERPINE_MURLOCS = {
    id = "SILVERPINE_MURLOCS",
    displayName = "Murlocs",
    ldr = "LDR-SP-4",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Silverpine Forest" },
    npcs = { 1732, 1733, 1734, 1735, 1763 },
    lore = {
        [1] = "Murlocs inhabit Silverpine's shores, lake edges, and riverbanks. Their wet camps and clustered movement make them a constant hazard where the forest touches water.",
        [2] = "Murlocs rarely fight as isolated creatures for long. I found their cries quickly drew others from the shore, turning a simple skirmish into a chaotic scramble.",
        [3] = "Silverpine is bordered by Lordamere Lake and the rugged western coast, giving murlocs many places to nest. The waters offer them refuge where land patrols cannot easily follow.",
        [4] = "For the Forsaken, murlocs are an obstacle to control of Silverpine's water routes and shores. They are not central to the kingdom's old tragedies, but they exploit the same absence of order.",
        [5] = "The murlocs of Silverpine are the voice of the dark water. Their camps remind the observer that even a haunted forest has borders below the trees, and those borders are not safe."
    }
}

FieldJournal_LoreDB.SILVERPINE_REEF_FRENZY = {
    id = "SILVERPINE_REEF_FRENZY",
    displayName = "Reef Frenzies",
    ldr = "LDR-SP-7",
    icon = "Interface\\Icons\\INV_Misc_Fish_02",
    zones = { "Silverpine Forest" },
    npcs = { 2173 }, -- Reef Frenzy
    lore = {
        [1] = "Reef frenzies are predatory fish found in Silverpine's coastal waters.",
        [2] = "They are a danger to anyone who enters the water without watching what moves beneath the surface.",
        [3] = "Silverpine's long, dark shoreline gives these fish a feeding ground away from its haunted woods.",
        [4] = "They make fishing and passage along the coast more hazardous than the calm surface suggests.",
        [5] = "The reef frenzy reminds a field observer that Silverpine's wild dangers extend beyond the trees and into the sea.",
    },
}

FieldJournal_LoreDB.SILVERPINE_DALARAN = {
    id = "SILVERPINE_DALARAN",
    displayName = "Dalaran Forces",
    ldr = "LDR-SP-5",
    icon = "Interface\\Icons\\Spell_Arcane_Blast",
    zones = { "Silverpine Forest" },
    npcs = { 1912, 1913, 1914, 1915, 1916 },
    lore = {
        [1] = "Dalaran forces in Silverpine are human and magical holdouts operating around Ambermill and nearby camps. They are organized enemies of the Forsaken rather than wild denizens of the forest.",
        [2] = "Their spellcasters use arcane force, patrol discipline, and fortified positions. I found them far more predictable than beasts but far more dangerous at range.",
        [3] = "Silverpine's southern reaches bring Forsaken interests into conflict with Dalaran survivors and allied humans. This gives the forest a political front as well as a haunted one.",
        [4] = "The Dalaran presence matters because it shows that Lordaeron's ruins remain contested by the living and undead alike. Silverpine is not empty; it is claimed by competing memories of human power.",
        [5] = "The Dalaran forces of Silverpine are the living resistance embedded in a Forsaken frontier. Their towers and spells make the forest a borderland of old alliances, new undeath, and unresolved war."
    }
}

FieldJournal_LoreDB.SILVERPINE_UNDEAD = {
    id = "SILVERPINE_UNDEAD",
    displayName = "Restless Undead",
    ldr = "LDR-SP-6",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    zones = { "Silverpine Forest" },
    npcs = { 1783, 1784, 1785, 1787, 1788, 1789, 1866, 1868, 1870, 1939, 1940, 1942, 1943, 1947, 1971, 1983 },
    lore = {
        [1] = "Restless undead are common across Silverpine's abandoned farms, graves, and ruins. They differ from the organized Forsaken, appearing as lingering bodies and spirits driven by undeath rather than society.",
        [2] = "Their movements are uneven but relentless, and they often gather where death once settled heavily. I found that even weak undead become dangerous when the forest hides their approach.",
        [3] = "Silverpine's history after the fall of Lordaeron left many places unburied, abandoned, or cursed. Such ground easily supports ghouls, ghosts, and wandering dead.",
        [4] = "For the Forsaken, these undead are an uneasy mirror: proof that undeath can be either peoplehood or mindless horror. The distinction matters greatly in Silverpine.",
        [5] = "The restless undead of Silverpine are the forest's unfinished dead. They give the land its coldest field signs and make every abandoned house a possible grave still moving."
    }
}

-- =========================================================
-- STONETALON MOUNTAINS: HARPIES, BEASTS, VENTURE CO., AND ELEMENTAL TROUBLE
-- =========================================================

FieldJournal_LoreDB.STONETALON_HARPIES = {
    id = "STONETALON_HARPIES",
    displayName = "Bloodfury Harpies",
    ldr = "LDR-SM-1",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_02",
    zones = { "Stonetalon Mountains" },
    npcs = { 4022, 4023, 4024, 4025, 4026, 4027 },
    lore = {
        [1] = "Bloodfury harpies are hostile winged humanoids nesting among Stonetalon's cliffs and ridges. They are territorial, organized in roosts, and capable of harrying travelers from above.",
        [2] = "Harpies use height and broken ground to their advantage, calling from the rocks before descending in sudden attacks. I found their camps marked by feathers, bones, and crude signs of scavenged trophies.",
        [3] = "Wowhead describes Stonetalon as a mountainous region home to harpies and chimeras, making the Bloodfury presence central to the zone's field ecology. The cliffs shelter them well.",
        [4] = "The harpies matter because they contest sacred and strategic heights. Their roosts turn mountain passes into ambush grounds for both Horde and Alliance travelers.",
        [5] = "The Bloodfury harpies are Stonetalon's hostile sky. Their shrieks belong to the ridges as surely as the wind, making every ascent a test of vigilance."
    }
}

FieldJournal_LoreDB.STONETALON_CHIMERAS = {
    id = "STONETALON_CHIMERAS",
    displayName = "Chimeras",
    ldr = "LDR-SM-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Chimera",
    zones = { "Stonetalon Mountains" },
    npcs = { 6167, 6168, 6169 },
    lore = {
        [1] = "Chimeras are large, two-headed flying beasts associated with wild mountain regions such as Stonetalon. Their size and aerial movement make them far more dangerous than ordinary carrion birds.",
        [2] = "A chimera controls space by air, forcing travelers to watch both cliff and sky. I found their silhouettes over the ridges unnerving, since open ground offered little cover once they noticed movement.",
        [3] = "Stonetalon's heights and remote valleys provide suitable hunting ranges for chimeras. Their presence reinforces the zone's identity as a rugged mountain wilderness rather than simple forest.",
        [4] = "Chimeras are significant to Stonetalon because they give the mountains a mythic quality. They are not just predators, but creatures that make the land feel ancient and dangerous.",
        [5] = "The chimeras of Stonetalon are the region's wild grandeur made flesh. They make fieldwork feel small beneath the peaks and remind the observer that some native powers answer to no faction."
    }
}

FieldJournal_LoreDB.STONETALON_BASILISKS = {
    id = "STONETALON_BASILISKS",
    displayName = "Basilisks",
    ldr = "LDR-SM-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Basilisk",
    zones = { "Stonetalon Mountains" },
    npcs = { 4142, 4143, 4144 },
    lore = {
        [1] = "Basilisks are reptilian predators with heavy bodies and dangerous natural defenses. In Stonetalon, they are found among dry slopes, caves, and stony ground.",
        [2] = "Their tracks drag low across dust and rock, and they often hold position until prey comes close. I treated every still shape near the stones with suspicion after the first encounter.",
        [3] = "The arid portions of Stonetalon suit basilisks well, giving them warm stone and broken cover. Their presence marks the harsher side of the mountains, away from greener druidic places.",
        [4] = "For travelers, basilisks are not political threats but practical ones. They punish carelessness in terrain already made hazardous by cliffs, company camps, and harpy roosts.",
        [5] = "The basilisks of Stonetalon belong to the stone itself: low, patient, and difficult to move. They make the mountains dangerous even when no enemy banner is nearby."
    }
}

FieldJournal_LoreDB.STONETALON_VENTURE_CO = {
    id = "STONETALON_VENTURE_CO",
    displayName = "Venture Co.",
    ldr = "LDR-SM-4",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    zones = { "Stonetalon Mountains" },
    npcs = { 3998, 3999, 4001, 4002, 4003, 4004 },
    lore = {
        [1] = "The Venture Company is a goblin-run extraction force operating in Stonetalon. Its workers, operators, and guards are hostile when their logging and mining interests are threatened.",
        [2] = "Their camps are easy to identify by cut timber, smoke, machinery, and polluted work sites. I found that they defend equipment and claims with the same zeal others reserve for homeland.",
        [3] = "Wowhead notes that the Venture Co. has stripped western Stonetalon of natural resources, filling air with soot and water with oil. This environmental damage defines much of the zone's conflict.",
        [4] = "The Venture Co. is significant because it makes Stonetalon's struggle ecological as well as military. Horde and Alliance both have reason to oppose a force that treats sacred mountains as fuel.",
        [5] = "The Venture Company in Stonetalon is greed mechanized. Their saws and pumps turn the field journal from natural study into evidence of exploitation."
    }
}

FieldJournal_LoreDB.STONETALON_DEEPMOSS_SPIDERS = {
    id = "STONETALON_DEEPMOSS_SPIDERS",
    displayName = "Deepmoss Spiders",
    ldr = "LDR-SM-6",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Stonetalon Mountains" },
    npcs = { 4005, 4006, 4007, 4263 }, -- Creeper, Webspinner, Venomspitter, Hatchling
    lore = {
        [1] = "Deepmoss spiders inhabit Stonetalon's wooded paths and caves. Their hatchlings and adults are dangerous even before the venomous varieties appear.",
        [2] = "Webspinners anchor webs across narrow routes, while creepers and venomspitters threaten travelers who stray into the undergrowth.",
        [3] = "The shaded passages of Stonetalon give these spiders cover and plenty of places to lay eggs beyond the main road.",
        [4] = "Their nests make travel through the mountains a problem of attention as much as strength: webs reveal where a path is no longer clear.",
        [5] = "The Deepmoss colony is a persistent part of Stonetalon's wild ecology, from hatchlings to the larger hunters that guard their territory.",
    },
}

FieldJournal_LoreDB.STONETALON_PRIDEWINGS = {
    id = "STONETALON_PRIDEWINGS",
    displayName = "Pridewing Wyverns",
    ldr = "LDR-SM-7",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent",
    zones = { "Stonetalon Mountains" },
    npcs = { 4011, 4012, 4013 }, -- Young Pridewing, Pridewing Wyvern, Skyhunter
    lore = {
        [1] = "Pridewing wyverns nest in the heights of Stonetalon, from young flyers to experienced skyhunters.",
        [2] = "They patrol open air above steep ground, giving a traveler little warning before descending.",
        [3] = "Cliffs and high passes provide roosts, shelter, and a wide view of prey below.",
        [4] = "Their presence changes how one travels the mountains: the sky deserves as much attention as the trail.",
        [5] = "The Pridewing colony is part of the wild life of the peaks, raising its young above Stonetalon's contested valleys.",
    },
}

FieldJournal_LoreDB.STONETALON_ELEMENTALS = {
    id = "STONETALON_ELEMENTALS",
    displayName = "Mountain Elementals",
    ldr = "LDR-SM-8",
    icon = "Interface\\Icons\\Spell_Fire_Fire",
    zones = { "Stonetalon Mountains" },
    npcs = { 4009, 4036 }, -- Raging Cliff Stormer, Rogue Flame Spirit
    lore = {
        [1] = "Storm and flame sometimes take hostile form in Stonetalon's rugged country.",
        [2] = "A raging cliff stormer and a rogue flame spirit are different forces, but both demand caution beyond the habits used for ordinary beasts.",
        [3] = "The mountains' exposed slopes and troubled places provide a setting for elemental danger.",
        [4] = "These manifestations make the region feel volatile even when no faction patrol is nearby.",
        [5] = "Recording Stonetalon's elemental threats helps distinguish hazards of the land itself from its hunters and raiders.",
    },
}

FieldJournal_LoreDB.STONETALON_GRIMTOTEM = {
    id = "STONETALON_GRIMTOTEM",
    displayName = "Grimtotem Tauren",
    ldr = "LDR-SM-5",
    icon = "Interface\\Icons\\INV_Misc_Head_Tauren_01",
    zones = { "Stonetalon Mountains" },
    npcs = { 11910, 11911, 11912, 11913 },
    lore = {
        [1] = "Grimtotem tauren are hostile members of a tauren faction found in several contested regions. In Stonetalon, their presence adds humanoid conflict to an already strained mountain frontier.",
        [2] = "They fight with discipline and clan identity rather than bandit opportunism. I found their camps marked by totems, hides, and guarded approaches.",
        [3] = "Stonetalon's sacred peaks and contested resources make it a fitting place for factional tauren conflict. The mountains hold spiritual meaning as well as strategic value.",
        [4] = "The Grimtotem matter because they complicate any simple view of Horde lands. They are tauren, but not allies to every tauren traveler, and their hostility carries internal political weight.",
        [5] = "The Grimtotem of Stonetalon are conflict within kinship. They show that the mountains divide not only factions, but traditions and loyalties inside the peoples who revere them."
    }
}

-- =========================================================
-- REDRIDGE MOUNTAINS: ORCS, GNOLLS, DRAGON WHELPS, AND LAKE COUNTRY
-- =========================================================

FieldJournal_LoreDB.REDRIDGE_BLACKROCK_ORCS = {
    id = "REDRIDGE_BLACKROCK_ORCS",
    displayName = "Blackrock Orcs",
    ldr = "LDR-RR-1",
    icon = "Interface\\Icons\\INV_Misc_Head_Orc_01",
    zones = { "Redridge Mountains" },
    npcs = { 429, 431, 432, 433, 434, 435, 436, 437, 440, 485 },
    lore = {
        [1] = "Blackrock orcs are the chief organized military threat in Redridge Mountains. They occupy strongholds, patrol roads, and field warriors, scouts, champions, and spellcasters.",
        [2] = "Their positions are disciplined and aggressive, especially around Stonewatch. I found their patrols more coordinated than local gnolls and far more willing to hold fortified ground.",
        [3] = "Wowhead describes Blackrock Clan orcs as having claimed part of Redridge, including Stonewatch Keep, while the rest of the region remains comparatively peaceful under Stormwind's protection.",
        [4] = "The Blackrock presence gives Redridge its wartime edge. Lakeshire may feel settled, but the orcs remind the kingdom that the Burning Steppes and old Horde threats are never far away.",
        [5] = "The Blackrock orcs of Redridge are the mountains' armed shadow. Their camps turn an idyllic lake province into a frontier, and every field note near Stonewatch must treat them as soldiers, not raiders."
    }
}

FieldJournal_LoreDB.REDRIDGE_GNOLLS = {
    id = "REDRIDGE_GNOLLS",
    displayName = "Redridge Gnolls",
    ldr = "LDR-RR-2",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Redridge Mountains" },
    npcs = { 423, 424, 426, 430, 446, 580, 712, 445 },
    lore = {
        [1] = "Gnolls in Redridge are hyena-like humanoids found in packs and camps across the hills. They are less disciplined than the Blackrock orcs but dangerous through numbers and aggression.",
        [2] = "Gnoll camps show scavenged goods, rough weapons, and constant territorial squabbling. I found them quick to swarm once a fight began, especially where paths narrowed.",
        [3] = "Redridge's hills and wooded slopes provide hiding places for gnoll packs near travel routes and farmsteads. Their presence threatens the settled supply lines around Lakeshire.",
        [4] = "For the people of Redridge, gnolls represent persistent disorder rather than invasion. They steal, raid, and unsettle the countryside even when larger military threats draw more attention.",
        [5] = "The gnolls of Redridge are the province's low-burning violence. They lack the Blackrock banner, but their camps keep the hills dangerous long after the road seems clear."
    }
}

FieldJournal_LoreDB.REDRIDGE_DRAGON_WHELPS = {
    id = "REDRIDGE_DRAGON_WHELPS",
    displayName = "Dragon Whelps",
    ldr = "LDR-RR-3",
    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    zones = { "Redridge Mountains" },
    npcs = { 441 },
    lore = {
        [1] = "Dragon whelps are young draconic creatures found in Redridge's wilder reaches. Though small by dragon standards, they remain dangerous magical predators to ordinary travelers.",
        [2] = "Whelps fight with tooth, claw, and breath, and they often linger near slopes or caves where escape is difficult. I found their size deceptive; youth does not make a dragon harmless.",
        [3] = "Redridge's mountains and proximity to the Burning Steppes make draconic sightings more plausible than in gentler lands. Their presence gives the zone an older and more dangerous quality.",
        [4] = "Dragonkin matter culturally because they connect local patrol work to Azeroth's ancient powers. A militia errand can become something larger when dragon sign appears in the hills.",
        [5] = "The dragon whelps of Redridge are sparks from a greater fire. They make the mountains feel linked to forces beyond human farms and fishing boats, and they deserve careful record even when encountered in small numbers."
    }
}

FieldJournal_LoreDB.REDRIDGE_CONDORS = {
    id = "REDRIDGE_CONDORS",
    displayName = "Condors",
    ldr = "LDR-RR-6",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
    zones = { "Redridge Mountains" },
    npcs = { 428 }, -- Dire Condor
    lore = {
        [1] = "Dire condors circle above Redridge's rocky country. These large birds are scavengers and opportunistic predators.",
        [2] = "They watch from above before descending, taking advantage of steep slopes and travelers occupied by dangers on the ground.",
        [3] = "Open ridges and rocky heights provide perches and broad sightlines over the valley.",
        [4] = "A condor overhead can reveal where carrion or a recent fight lies below, making its flight a useful field sign.",
        [5] = "The dire condor belongs to Redridge's high, exposed places, an ordinary wild threat amid the province's more organized enemies.",
    },
}

FieldJournal_LoreDB.REDRIDGE_TARANTULAS = {
    id = "REDRIDGE_TARANTULAS",
    displayName = "Tarantulas",
    ldr = "LDR-RR-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Redridge Mountains" },
    npcs = { 442, 930, 505 }, -- Greater Tarantula
    lore = {
        [1] = "Redridge tarantulas are large spiders inhabiting hills, caves, and brush away from Lakeshire's safer paths. Their size and venom make them a familiar threat to travelers.",
        [2] = "They favor ambush positions where rocks, webs, and roots hide their approach. I found the oldest specimens difficult to dislodge once they claimed a den.",
        [3] = "The warm, rocky slopes of Redridge suit large spiders well. Their dens appear where settlement has not cleared the land fully.",
        [4] = "Spiders are a practical concern for local hunters and scouts. They are not tied to Redridge's wars, yet they claim the same hills where messengers and patrols must pass.",
        [5] = "The tarantulas of Redridge are the quiet danger beneath the idyllic surface. They remind the observer that even protected Stormwind lands remain full of native hazards."
    }
}

FieldJournal_LoreDB.REDRIDGE_BOARS = {
    id = "REDRIDGE_BOARS",
    displayName = "Redridge Boars",
    ldr = "LDR-RR-7",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Redridge Mountains" },
    npcs = { 345 }, -- Bellygrub
    lore = {
        [1] = "Bellygrub is a large boar roaming Redridge's countryside.",
        [2] = "Its weight and tusks make a close encounter dangerous even away from the orc and gnoll camps.",
        [3] = "Fields and brush around the settled valley give a wild boar food and cover.",
        [4] = "For local farmers, a large boar is a practical threat to land, livestock, and safe passage.",
        [5] = "Bellygrub is a reminder that Redridge's familiar countryside still has its own wild inhabitants.",
    },
}

FieldJournal_LoreDB.REDRIDGE_LAKE_THRESHERS = {
    id = "REDRIDGE_LAKE_THRESHERS",
    displayName = "Lake Threshers",
    ldr = "LDR-RR-8",
    icon = "Interface\\Icons\\INV_Misc_Fish_02",
    zones = { "Redridge Mountains" },
    npcs = { 14357 }, -- Lake Thresher
    lore = {
        [1] = "Lake threshers hunt in the waters of Redridge, where the calm surface can hide dangerous life beneath.",
        [2] = "I watch the water before crossing or fishing, since an underwater predator can close the distance quickly.",
        [3] = "Lake Everstill provides a broad habitat for aquatic hunters as well as the murlocs along its shore.",
        [4] = "The lake is central to local travel and food. Its predators shape how safely people can use it.",
        [5] = "A record of Redridge's threats must include the water as well as the roads and hills.",
    },
}

FieldJournal_LoreDB.REDRIDGE_MURLOCS = {
    id = "REDRIDGE_MURLOCS",
    displayName = "Lake Murlocs",
    ldr = "LDR-RR-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Redridge Mountains" },
    npcs = { 4457, 4458, 4459, 4460, 422, 548, 578, 1083 },
    lore = {
        [1] = "Lake murlocs occupy the waters and shores of Redridge, threatening fishing, travel, and settlement around Lake Everstill. Their calls are a familiar warning near the banks.",
        [2] = "Murlocs rarely remain a single-target problem. I found that one cry near the lake could draw several more from reeds or water before the first fight ended.",
        [3] = "Redridge's central lake makes a natural home for murlocs. While the hills hold orcs and gnolls, the water has its own hostile inhabitants.",
        [4] = "For Lakeshire, murlocs are a direct pressure on food, trade, and safe passage across the lake. They turn a source of prosperity into a border of danger.",
        [5] = "The murlocs of Redridge are Lake Everstill's unruly claimants. Their camps give the water a voice of its own, one that does not answer to Stormwind."
    }
}

-- =========================================================
-- DUSKWOOD: UNDEAD, WORGEN, SPIDERS, AND HAUNTED WOODS
-- =========================================================

FieldJournal_LoreDB.DUSKWOOD_UNDEAD = {
    id = "DUSKWOOD_UNDEAD",
    displayName = "Undead of Raven Hill",
    ldr = "LDR-DW-1",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    zones = { "Duskwood" },
    npcs = { 3, 48, 203, 205, 206, 210, 531, 5317, 522 },
    lore = {
        [1] = "Duskwood's undead include ghouls, skeletons, horrors, fiends, and named terrors haunting Raven Hill and the surrounding graveyards. They are among the defining threats of the zone.",
        [2] = "The undead gather where burial has failed to mean rest. I found that grave soil, broken mausoleums, and sudden movement in the fog were the surest signs of danger.",
        [3] = "Duskwood is covered in perpetual darkness and shaped by curse, death, and abandonment. Raven Hill Cemetery provides the most obvious ground for the dead to rise and linger.",
        [4] = "The undead matter because they embody Duskwood's central fear: that the past cannot stay buried. The Night Watch fights not only monsters, but the consequences of a land gone wrong.",
        [5] = "The undead of Duskwood are the province's open graves. They make the field journal read like a warning, proving that here death is not an ending but another hostile condition."
    }
}

FieldJournal_LoreDB.DUSKWOOD_WORGEN = {
    id = "DUSKWOOD_WORGEN",
    displayName = "Nightbane Worgen",
    ldr = "LDR-DW-2",
    icon = "Interface\\Icons\\Ability_Druid_Rake",
    zones = { "Duskwood" },
    npcs = { 533, 539, 898, 920, 921, 923, 2064 },
    lore = {
        [1] = "Nightbane worgen are cursed wolf-like humanoids stalking the dark woods and homesteads of Duskwood. They are one of the zone's most feared living nightmares.",
        [2] = "They strike swiftly and with pack violence, often near places where the road gives way to trees. I found their claw marks on wood and soil before I ever saw the creatures themselves.",
        [3] = "Duskwood's perpetual gloom and cursed reputation make it ideal territory for worgen. The forest hides movement, carries howls strangely, and keeps fear close to every settlement.",
        [4] = "Worgen are culturally significant to Duskwood because they tie local terror to old curses and the broader mystery of the Scythe of Elune. They are not merely wolves, but tragedy given claws.",
        [5] = "The Nightbane worgen are Duskwood's curse in motion. They blur human, beast, and nightmare, making them essential to any serious account of the region."
    }
}

FieldJournal_LoreDB.DUSKWOOD_SPIDERS = {
    id = "DUSKWOOD_SPIDERS",
    displayName = "Duskwood Spiders",
    ldr = "LDR-DW-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Duskwood" },
    npcs = { 930, 949, 1111, 1112, 1113, 1114 },
    lore = {
        [1] = "Duskwood's spiders are large venomous predators occupying the dark trees, hills, and webbed clearings of the region. Their presence makes even ordinary woodland travel dangerous.",
        [2] = "The webs appear first: between trees, across slopes, and near places where travelers might be forced to slow. I found that the largest spiders used the darkness almost as well as any ambusher.",
        [3] = "Duskwood's dim canopy, abandoned farms, and low traffic provide excellent conditions for spiders to spread. The forest's curse has not stopped natural predators; it has given them better cover.",
        [4] = "To the Night Watch, spiders are less mysterious than undead or worgen but no less practical a threat. Many patrols likely end in webbing before they ever meet the legendary horrors of the zone.",
        [5] = "The spiders of Duskwood are the mundane horror beneath supernatural terror. Their webs prove that fear here is layered: natural, cursed, and undead all at once."
    }
}

FieldJournal_LoreDB.DUSKWOOD_WOLVES = {
    id = "DUSKWOOD_WOLVES",
    displayName = "Dark Wolves",
    ldr = "LDR-DW-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Duskwood" },
    npcs = { 213, 118, 565, 628 },
    lore = {
        [1] = "Dark wolves and related forest predators prowl Duskwood's roads and tree lines. They are natural beasts, but the cursed forest makes their presence feel less ordinary.",
        [2] = "I found wolf sign near the road shoulders and around abandoned farms. Their behavior remains predatory rather than undead, though darkness makes every attack feel sudden.",
        [3] = "Duskwood's forests provide cover and prey enough for wolves to thrive. The lack of safe settlement outside Darkshire leaves many stretches to the beasts.",
        [4] = "For locals, wolves are part of the daily danger that exists beneath larger legends. Not every howl belongs to a worgen, and that uncertainty is part of the fear.",
        [5] = "The wolves of Duskwood mark the line where ordinary wilderness becomes nightmare. They may be natural animals, but in this forest even nature wears a shadowed face."
    }
}

FieldJournal_LoreDB.DUSKWOOD_OGRES = {
    id = "DUSKWOOD_OGRES",
    displayName = "Vul'Gol Ogres",
    ldr = "LDR-DW-5",
    icon = "Interface\\Icons\\INV_Misc_Head_Ogre_01",
    zones = { "Duskwood" },
    npcs = { 597, 598, 599, 5977, 5978 },
    lore = {
        [1] = "Vul'Gol ogres are large hostile humanoids occupying the hills and mounds of Duskwood. Their strength and crude organization make them a serious threat to anyone leaving the road.",
        [2] = "Ogre camps are loud, rough, and guarded by brute force rather than stealth. I found their magic-users especially dangerous because they add spellcraft to already overwhelming size.",
        [3] = "Duskwood's hills and remote hollows give ogres room to establish camps away from Darkshire's immediate control. The cursed forest leaves many such pockets under-defended.",
        [4] = "The Vul'Gol are significant because they show that Duskwood's danger is not solely undead or cursed. Ordinary humanoid violence has also taken root where Stormwind's reach is weak.",
        [5] = "The Vul'Gol ogres are Duskwood's heavy shadow in the hills. They broaden the field record from ghost story to frontier war, proving that many kinds of danger thrive under the same dark canopy."
    }
}

FieldJournal_LoreDB.DUSKWOOD_DARK_RIDERS = {
    id = "DUSKWOOD_DARK_RIDERS",
    displayName = "Dark Riders and Necromancers",
    ldr = "LDR-DW-6",
    icon = "Interface\\Icons\\Spell_Shadow_Shadowform",
    zones = { "Duskwood" },
    npcs = { 570, 771, 3150 },
    lore = {
        [1] = "Dark riders, necromancers, and named shadowed figures in Duskwood represent deliberate evil rather than wandering hazard. They are rare compared to wolves or undead, but far more significant when encountered.",
        [2] = "Such enemies leave signs of intent: rituals, cursed objects, grave disturbances, and reports from terrified locals. I treated each sighting as evidence rather than merely an encounter.",
        [3] = "Duskwood's history as Brightwood fallen into darkness makes it fertile ground for stories of riders, necromancy, and sinister bargains. The land seems to preserve secrets as easily as bones.",
        [4] = "These figures matter because they connect Duskwood's local troubles to named legends: Stalvan, Morbent Fel, the Hermit, and the darker powers whispered through the zone's quests.",
        [5] = "The dark riders and necromancers of Duskwood are the intelligence behind the haunting. They turn fear into design, making the journal read not only as natural history but as investigation."
    }
}


-- =========================================================
-- ASHENVALE: ANCIENT FOREST CONFLICTS
-- =========================================================

FieldJournal_LoreDB.ASHENVALE_FURBOLGS = {
    id = "ASHENVALE_FURBOLGS",
    displayName = "Thistlefur Furbolgs",
    ldr = "LDR-AS-1",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_08",
    zones = { "Ashenvale" },
    npcs = { 3921, 3922, 3923, 3924, 3925, 3926 },
    lore = {
        [1] = "The Thistlefur furbolgs are bear-like humanoids dwelling in Ashenvale's deep woods and dens. They are not simple beasts; they are an organized people whose hostility has become a serious danger to travelers and kaldorei holdings.",
        [2] = "Thistlefur camps show signs of den life, crude ritual practice, and territorial defense. I found their warriors direct and powerful, while their shamans and totemic figures made any approach more dangerous.",
        [3] = "Ashenvale's ancient forest gives furbolgs cover, food, and sacred ground, but corruption and war have strained many native peoples of the region. The Thistlefur presence marks parts of the forest where old woodland inhabitants have turned inward and hostile.",
        [4] = "Furbolgs have long ties to the forests of northern Kalimdor, so conflict with them carries more weight than a skirmish with raiders. In Ashenvale, their aggression is part of the broader wound suffered by the forest and its peoples.",
        [5] = "The Thistlefur furbolgs represent Ashenvale's native strength under pressure. They are dangerous enemies in the field, but a serious journal should record them as a forest people shaped by territory, corruption, and the slow collapse of trust."
    }
}

FieldJournal_LoreDB.ASHENVALE_SATYR = {
    id = "ASHENVALE_SATYR",
    displayName = "Satyr",
    ldr = "LDR-AS-2",
    icon = "Interface\\Icons\\Spell_Shadow_SummonSatyr",
    zones = { "Ashenvale" },
    npcs = { 3752, 3754, 3755, 3757, 3758, 3762, 3763 },
    lore = {
        [1] = "Satyr in Ashenvale are demonic, corrupted beings tied to fel influence and ancient kaldorei tragedy. They are intelligent enemies who poison the forest rather than merely inhabit it.",
        [2] = "Satyr favor hidden camps, ruins, and shadowed groves where corruption can spread quietly. I found that they fight with malice and purpose, often supported by spellcasters and lesser corrupt creatures.",
        [3] = "Ashenvale's sacred forest makes satyr activity especially dangerous. Where they gather, the land itself often feels fouled, as though their presence turns old power toward decay.",
        [4] = "For the night elves, satyr are not simply demons in the woods; they are a reminder of betrayal, corruption, and ancient kinship twisted into hatred. Their presence in Ashenvale gives every patrol a spiritual weight.",
        [5] = "The satyr of Ashenvale are the forest's internal wound. They make clear that the region is threatened not only by axes, armies, and beasts, but by corruption that knows the old paths and sacred places."
    }
}

FieldJournal_LoreDB.ASHENVALE_NAGA = {
    id = "ASHENVALE_NAGA",
    displayName = "Wrathtail Naga",
    ldr = "LDR-AS-3",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Ashenvale" },
    npcs = { 3711, 3712, 3713, 3715, 3717 },
    lore = {
        [1] = "The Wrathtail naga are serpentine humanoids found along Ashenvale's western shore near the Zoram Strand. They are organized, hostile, and strongly tied to the sea and ancient ruins.",
        [2] = "Naga patrol beaches and ruins with discipline, using warriors and spellcasters together. I found the shoreline more dangerous than it looked, especially where the surf masked movement and calls.",
        [3] = "Ashenvale's coast opens directly to the Great Sea and to older kaldorei histories beneath it. The naga presence along the strand makes the western edge of the forest a maritime frontier rather than a quiet beach.",
        [4] = "Naga matter in Ashenvale because they bind the zone's present troubles to the ancient past of the kaldorei. Their hold on ruins and shoreline suggests purpose beyond simple raiding.",
        [5] = "The Wrathtail naga are Ashenvale's threat from the tide. They make the forest's western border feel watched by an older, colder intelligence rising from the sea."
    }
}

FieldJournal_LoreDB.ASHENVALE_WILDLIFE = {
    id = "ASHENVALE_WILDLIFE",
    displayName = "Ashenvale Wildlife",
    ldr = "LDR-AS-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Ashenvale" },
    npcs = { 3809, 3810, 3811, 3820, 3821, 3823, 3824, 3825, 3826, 3827, 12676, 12677, 12678 },
    lore = {
        [1] = "Ashenvale's bears, wolves, spiders, and forest cats are native woodland creatures shaped by an old and living forest. They are natural hazards, not invaders, but their strength should not be underestimated.",
        [2] = "The beasts here use the dense canopy and uneven forest floor to their advantage. I found tracks, scratch marks, and webbing close to roads, showing how thin the line is between settlement and wild ground.",
        [3] = "As an ancestral night elf forest, Ashenvale supports a broad natural web of predators and prey. Its wildlife is one of the clearest signs that the land remains alive despite war and harvesting.",
        [4] = "Kaldorei traditions give the wilds of Ashenvale great cultural importance. Hunting or culling its animals is therefore never merely practical; it touches the balance between survival, reverence, and defense.",
        [5] = "Ashenvale's wildlife is the forest's living pulse. These creatures make the zone feel ancient and untamed, even where war camps and lumber operations have cut into its heart."
    }
}

FieldJournal_LoreDB.ASHENVALE_WARSONG = {
    id = "ASHENVALE_WARSONG",
    displayName = "Warsong Outriders",
    ldr = "LDR-AS-5",
    icon = "Interface\\Icons\\INV_BannerPVP_02",
    zones = { "Ashenvale" },
    npcs = { 11680, 11681, 11682, 11683, 11684, 11685 },
    lore = {
        [1] = "Warsong forces in Ashenvale are Horde-aligned soldiers and lumber workers pressing into the forest. They are organized humanoid enemies for Alliance observers and a major military presence in the zone.",
        [2] = "Their camps are built around supply, axes, patrols, and aggressive defense. I found the signs of logging impossible to miss: stumps, cleared ground, and guards positioned to protect the work.",
        [3] = "Warcraft Wiki describes Ashenvale as a contested forest between Alliance and Horde territories, and the Warsong operations make that conflict visible in the trees. The forest itself becomes a battlefield over resources.",
        [4] = "The Warsong presence is culturally significant because it strikes at a land sacred to the night elves while serving the Horde's need for lumber. Every felled tree becomes political as well as practical.",
        [5] = "The Warsong forces are Ashenvale's axe edge. They turn the forest conflict into something a field observer can see, count, and smell in fresh-cut wood and smoke."
    }
}

-- =========================================================
-- WETLANDS: MARSH, DRAGONKIN, AND BORDER WAR
-- =========================================================

FieldJournal_LoreDB.WETLANDS_MURLOCS = {
    id = "WETLANDS_MURLOCS",
    displayName = "Bluegill Murlocs",
    ldr = "LDR-WL-1",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Wetlands" },
    npcs = { 1024, 1025, 1026, 1027, 1028, 1029 },
    lore = {
        [1] = "Bluegill murlocs are amphibious humanoids occupying shorelines, marsh water, and river mouths throughout the Wetlands. Their camps make travel near water unpredictable.",
        [2] = "Murlocs respond rapidly to noise and nearby fighting. I found that one skirmish at the water's edge can pull half a camp into motion before a traveler has firm footing.",
        [3] = "The Wetlands are filled with rivers, pools, and low marsh, making them ideal for murloc settlement. Their distribution follows the water as surely as roads follow dry ground.",
        [4] = "For Menethil Harbor and Alliance patrols, murlocs are a practical obstacle to fishing, travel, and coastal control. They are not the zone's grandest threat, but they are one of its most persistent.",
        [5] = "The Bluegill murlocs are the Wetlands' wet, chattering border. They turn every bank and pool into contested ground and remind the observer that this zone belongs as much to water as to road."
    }
}

FieldJournal_LoreDB.WETLANDS_RAPTORS = {
    id = "WETLANDS_RAPTORS",
    displayName = "Wetlands Raptors",
    ldr = "LDR-WL-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Raptor",
    zones = { "Wetlands" },
    npcs = { 1020, 1021, 1022, 1023, 1030, 1031, 1032, 1033 },
    lore = {
        [1] = "Raptors in the Wetlands are swift reptilian predators found across the marsh flats and drier rises. Their speed and pack behavior make them especially dangerous in open ground.",
        [2] = "Raptor signs include clawed tracks, stripped carcasses, and sudden movement through reeds. I found that they close distance quickly and punish hesitation.",
        [3] = "The mixture of marsh, grass, and broken elevation gives raptors ample hunting territory. The Wetlands may appear slow and waterlogged, but these predators move through it with practiced ease.",
        [4] = "Raptors are part of the wild pressure that keeps Alliance holdings in the Wetlands from feeling fully secure. They make even routine survey and supply work into armed travel.",
        [5] = "The raptors of the Wetlands are the zone's sudden violence. In a land of mud and slow water, they are speed, teeth, and the reminder that the marsh can lunge."
    }
}

FieldJournal_LoreDB.WETLANDS_DRAGONMAW = {
    id = "WETLANDS_DRAGONMAW",
    displayName = "Dragonmaw Orcs",
    ldr = "LDR-WL-3",
    icon = "Interface\\Icons\\INV_Misc_Head_Orc_01",
    zones = { "Wetlands" },
    npcs = { 1034, 1035, 1036, 1037, 1038, 1039 },
    lore = {
        [1] = "Dragonmaw orcs in the Wetlands are organized hostile humanoids tied to the old wars and to the region's dragon-related threats. They are not wandering raiders but a martial force with strongholds and purpose.",
        [2] = "Their camps show military habit: sentries, warlocks, riders, and guarded approaches. I found them far more dangerous than beasts because they choose ground and respond with coordination.",
        [3] = "The Wetlands lie between Khaz Modan and northern Lordaeron, a border region shaped by old Horde and Alliance conflict. Dragonmaw activity keeps that history alive in the marsh.",
        [4] = "The Dragonmaw are significant because of their connection to the Second War and to the enslavement and use of dragons in older conflicts. In the Wetlands, their presence turns local patrol duty into historical reckoning.",
        [5] = "The Dragonmaw orcs are the Wetlands' old war made present. Their camps, riders, and spellcasters make the marsh feel like a battlefield that never fully drained."
    }
}

FieldJournal_LoreDB.WETLANDS_DARK_IRON = {
    id = "WETLANDS_DARK_IRON",
    displayName = "Dark Iron Dwarves",
    ldr = "LDR-WL-4",
    icon = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
    zones = { "Wetlands" },
    npcs = { 1051, 1052, 1053, 1054, 1055 },
    lore = {
        [1] = "Dark Iron dwarves in the Wetlands are hostile dwarven forces operating from camps, dig sites, and contested routes. They are disciplined enemies whose threat lies in arms, explosives, and old grudges.",
        [2] = "Dark Iron patrols show signs of mining discipline and ambush planning. I found their positions often chosen near roads, excavations, or strategic approaches rather than random wilderness.",
        [3] = "The Wetlands connect Khaz Modan's dwarven lands to dangerous northern routes, making them a natural place for rival dwarven interests to clash. The marsh hides movement well enough for raids and sabotage.",
        [4] = "Dark Iron activity matters because it ties the Wetlands to the deeper history of dwarven division. Their presence is never just banditry; it is part of a long conflict over power, stone, and allegiance.",
        [5] = "The Dark Iron dwarves of the Wetlands are a reminder that not every danger here comes from marsh or monster. Some threats wear familiar faces and carry older claims beneath their armor."
    }
}

FieldJournal_LoreDB.WETLANDS_MOSSHIDE = {
    id = "WETLANDS_MOSSHIDE",
    displayName = "Mosshide Gnolls",
    ldr = "LDR-WL-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Wetlands" },
    npcs = { 1007, 1008, 1009, 1010, 1011, 1012 },
    lore = {
        [1] = "Mosshide gnolls are hyena-like humanoid raiders found in the Wetlands. They are territorial, scavenging, and violent enough to threaten roads, farms, and isolated patrols.",
        [2] = "Their camps are crude but active, with stolen goods and rough weapons scattered among hides and bones. I found they rely on numbers and aggression more than discipline.",
        [3] = "The Wetlands' broken ground and thick marsh cover give gnoll bands places to raid from and retreat into. Their presence makes the land between settlements feel less empty and far less safe.",
        [4] = "For Alliance outposts, Mosshide gnolls are a persistent local menace. They lack the history of the Dragonmaw or Dark Irons, but their raids grind away at order just the same.",
        [5] = "The Mosshide gnolls are the Wetlands' scavenger war. They live in the margins of greater conflicts, taking what they can from a land already difficult to hold."
    }
}

FieldJournal_LoreDB.WETLANDS_MARSH_BEASTS = {
    id = "WETLANDS_MARSH_BEASTS",
    displayName = "Marsh Beasts",
    ldr = "LDR-WL-6",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk",
    zones = { "Wetlands" },
    npcs = { 1040, 1041, 1042, 1043, 1059, 1060, 1062, 1063 },
    lore = {
        [1] = "Crocolisks, oozes, and fen creatures are common natural hazards of the Wetlands. They are shaped by mud, stagnant water, and the slow violence of marshland survival.",
        [2] = "Crocolisks wait near banks while oozes drift through wet ground with little warning. I found both dangers easy to underestimate until the terrain made retreat slow.",
        [3] = "Warcraft Wiki describes the Wetlands as a large wet region full of rivers, lakes, and ponds below Stonewrought Dam. Such terrain favors creatures that hunt from water or thrive in rot.",
        [4] = "Marsh beasts influence travel, trade, and patrol routes. They are not political enemies, but they decide where wagons move, where scouts step, and where bodies are recovered.",
        [5] = "The marsh beasts of the Wetlands are the land's own resistance. They make the zone feel soaked, hungry, and alive beneath every patch of reeds."
    }
}

-- =========================================================
-- HILLSBRAD FOOTHILLS: HUMAN FARMS AND FORSAKEN FRONTIER
-- =========================================================

FieldJournal_LoreDB.HILLSBRAD_WILDLIFE = {
    id = "HILLSBRAD_WILDLIFE",
    displayName = "Foothills Wildlife",
    ldr = "LDR-HF-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Hillsbrad Foothills" },
    npcs = { 2384, 2385, 2406, 2407, 2348, 2349, 2350, 2351 },
    lore = {
        [1] = "Hillsbrad's bears, mountain lions, spiders, and other beasts inhabit grassy hills, farms, and wooded slopes. They are ordinary wildlife, but in a contested frontier even ordinary wildlife can be deadly.",
        [2] = "I found predator signs close to human paths and farm edges. The beasts of Hillsbrad do not seem monstrous, but they are bold enough to make travel outside town an armed affair.",
        [3] = "Hillsbrad Foothills is known for grassy hills and abundant wildlife, making it one of Lordaeron's more visibly living regions despite the wars around it. Its animals help distinguish it from the sicklier lands nearby.",
        [4] = "For Southshore and Tarren Mill alike, wildlife is a daily concern beneath larger military tensions. Farmers may speak of war, but they still need hides, meat, and protection from claws.",
        [5] = "The wildlife of Hillsbrad is the zone's uneasy normalcy. It shows that beneath faction banners and old ruins, the foothills remain a living countryside."
    }
}

FieldJournal_LoreDB.HILLSBRAD_SYNDICATE = {
    id = "HILLSBRAD_SYNDICATE",
    displayName = "Syndicate",
    ldr = "LDR-HF-2",
    icon = "Interface\\Icons\\INV_Mask_04",
    zones = { "Hillsbrad Foothills" },
    npcs = { 2240, 2241, 2242, 2243, 2245, 2246, 2247 },
    lore = {
        [1] = "The Syndicate are human criminals and former Alteraci loyalists operating through Hillsbrad and nearby ruins. They are organized outlaws rather than common thieves.",
        [2] = "Syndicate camps show planning, hierarchy, and familiarity with the land. I found their rogues and watchmen dangerous because they understand roads, farms, and ruins as well as any local soldier.",
        [3] = "Hillsbrad's location near Alterac and Durnholde gives the Syndicate places to hide and old political wounds to exploit. Their activity turns the foothills into a criminal borderland.",
        [4] = "The Syndicate matter because they are tied to the fallen kingdom of Alterac and the lingering consequences of the Second War. Their crimes carry history as well as greed.",
        [5] = "The Syndicate of Hillsbrad are the past refusing lawful burial. They make every ruined tower and roadside camp feel connected to old betrayal and present danger."
    }
}

FieldJournal_LoreDB.HILLSBRAD_MURLOCS = {
    id = "HILLSBRAD_MURLOCS",
    displayName = "Hillsbrad Murlocs",
    ldr = "LDR-HF-3",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Hillsbrad Foothills" },
    npcs = { 2374, 2375, 2376, 2377, 2378 },
    lore = {
        [1] = "Murlocs live along Hillsbrad's coast, rivers, and wet lowlands. Their camps are noisy, fast-moving hazards near water routes and fishing grounds.",
        [2] = "Murlocs respond in groups, making one careless pull into a small battle. I found the shore deceptively open until their cries began carrying across it.",
        [3] = "The foothills are not all dry farmland; water and coastline give murlocs enough space to hold settlements at the edge of human control.",
        [4] = "For Southshore, murlocs are a practical concern for trade, fishing, and patrols. They lack the politics of the Forsaken or Syndicate but still wear down daily security.",
        [5] = "The murlocs of Hillsbrad are the wet edge of a contested countryside. They make the land's peaceful appearance feel incomplete wherever water gathers."
    }
}

FieldJournal_LoreDB.HILLSBRAD_YETI = {
    id = "HILLSBRAD_YETI",
    displayName = "Yeti",
    ldr = "LDR-HF-4",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
    zones = { "Hillsbrad Foothills" },
    npcs = { 2248, 2249, 2250, 2251, 2252 },
    lore = {
        [1] = "Yeti are large, shaggy cave-dwelling humanoids found in the colder and rougher parts of Hillsbrad. Their strength and territorial nature make their caves especially dangerous.",
        [2] = "Yeti signs include heavy tracks, bones, and clawed stone near cave mouths. I found that they rely on brute force and tight quarters, where their size becomes impossible to ignore.",
        [3] = "The foothills rise toward harsher northern terrain, and caves provide the shelter these creatures need. Their presence marks the transition from farmland to wild mountain edge.",
        [4] = "Yeti are important to local work because mines, passes, and caves cannot be safely used while they hold them. They are not political actors, but they shape where people dare to go.",
        [5] = "The yeti of Hillsbrad are the foothills' raw strength hidden in stone. They give the zone a colder, older danger beyond the fields and roads."
    }
}

FieldJournal_LoreDB.HILLSBRAD_FORSAKEN = {
    id = "HILLSBRAD_FORSAKEN",
    displayName = "Forsaken Forces",
    ldr = "LDR-HF-5",
    icon = "Interface\\Icons\\INV_Misc_Head_Undead_01",
    zones = { "Hillsbrad Foothills" },
    npcs = { 2214, 2215, 2216, 2217, 2218, 2219 },
    lore = {
        [1] = "Forsaken forces operating from Tarren Mill are organized undead soldiers, apothecaries, and agents. For Alliance observers they are a military and alchemical threat on Hillsbrad's northern side.",
        [2] = "Their patrols and experiments show discipline unlike wandering undead. I found their presence more chilling than simple rot, because each action seemed directed by policy and purpose.",
        [3] = "Hillsbrad sits between Southshore and Tarren Mill, making it one of Classic's clearest faction frontiers. Warcraft Wiki notes the zone's towns and contested history, and the Forsaken presence drives much of that tension.",
        [4] = "The Forsaken matter here because Hillsbrad is one of the places where living Lordaeron and undead Lordaeron confront one another directly. The conflict is territorial, historical, and personal.",
        [5] = "The Forsaken of Hillsbrad are the zone's cold political edge. They turn green fields into a front line between memory, survival, and revenge."
    }
}

-- =========================================================
-- THE BARRENS: HORDE SAVANNA AND WIDE-OPEN DANGERS
-- =========================================================

FieldJournal_LoreDB.BARRENS_PLAINSTRIDERS = {
    id = "BARRENS_PLAINSTRIDERS",
    displayName = "Plainstriders",
    ldr = "LDR-BR-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
    zones = { "The Barrens" },
    npcs = { 2955, 2956, 2957, 3244, 3245 },
    lore = {
        [1] = "Plainstriders are tall, swift birds roaming the open savanna of the Barrens. They are natural creatures rather than monsters, but their size and speed make them dangerous when provoked.",
        [2] = "Their tracks cross long stretches of dust and dry grass. I found them quick to scatter, though older birds defend themselves with sudden kicks and sharp strikes.",
        [3] = "The Barrens' open terrain is ideal for creatures that move by speed and distance. Plainstriders are one of the clearest signs of the zone's savanna character.",
        [4] = "For Horde hunters and travelers, plainstriders are food, trial, and landmark. They are part of the practical life of the Crossroads and the roads between Horde settlements.",
        [5] = "The plainstriders of the Barrens are the motion of the open land. Their long strides make the zone feel vast, dry, and alive beneath the sun."
    }
}

FieldJournal_LoreDB.BARRENS_RAPTORS = {
    id = "BARRENS_RAPTORS",
    displayName = "Raptors",
    ldr = "LDR-BR-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Raptor",
    zones = { "The Barrens" },
    npcs = { 3254, 3255, 3256, 3257, 3259 },
    lore = {
        [1] = "Raptors are fast reptilian predators common across the Barrens. They hunt with speed, teeth, and enough group behavior to threaten even armed travelers.",
        [2] = "I found raptor nests, bones, and clawed tracks near open ground and scrub. They close distance faster than the empty horizon suggests.",
        [3] = "The Barrens provides broad hunting territory with scattered cover, ideal for raptors that rely on bursts of speed. Their range overlaps roads, oases, and hunting grounds.",
        [4] = "Raptors are a regular test for young Horde adventurers. Their hides, claws, and meat enter practical use, but each hunt carries real risk.",
        [5] = "The raptors of the Barrens are the savanna's snapping jaws. They make the open land feel less empty and far less safe than it appears from a distance."
    }
}

FieldJournal_LoreDB.BARRENS_QUILLBOAR = {
    id = "BARRENS_QUILLBOAR",
    displayName = "Razormane Quillboar",
    ldr = "LDR-BR-3",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_09",
    zones = { "The Barrens" },
    npcs = { 3111, 3112, 3113, 3114, 3118, 3265, 3266, 3267, 3268, 3269 },
    lore = {
        [1] = "Razormane quillboar are aggressive boar-like humanoids entrenched in thorny camps across the Barrens. They are organized tribal enemies and frequent opponents of Horde settlements.",
        [2] = "Their camps are defended with brambles, crude weapons, and numbers. I found that they fight fiercely around water and shelter, resources too scarce in the Barrens to surrender easily.",
        [3] = "The Barrens' dry land and limited oases make competition severe. Quillboar settlements often appear where survival resources are worth fighting over.",
        [4] = "For the Horde, Razormane quillboar are one of the Barrens' defining local threats. Their conflict with orcs, tauren, and trolls is practical, territorial, and ongoing.",
        [5] = "The Razormane quillboar are the Barrens' thorned resistance. They show that survival here is not only a fight against heat and distance, but against other peoples who claim the same water and dust."
    }
}

FieldJournal_LoreDB.BARRENS_BRISTLEBACK = {
    id = "BARRENS_BRISTLEBACK",
    displayName = "Bristleback Quillboar",
    ldr = "LDR-BARRENS-8",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "The Barrens" },
    npcs = { 3258, 3260, 3263 }, -- Hunter, Water Seeker, Geomancer
    lore = {
        [1] = "Bristleback quillboar hold camps in the Barrens, distinct from the Razormane tribes recorded elsewhere in the region.",
        [2] = "Their hunters range away from camp, water seekers contest scarce pools, and geomancers add magic to the tribe's defenses.",
        [3] = "Competition for water and territory brings Bristleback patrols into conflict with travelers and neighboring settlements.",
        [4] = "These quillboar form a rooted community with roles beyond simple raiding; their movements reveal how they use the dry landscape.",
        [5] = "The Bristleback are another claim on the Barrens, shaping its paths, watering places, and constant tribal conflicts.",
    },
}

FieldJournal_LoreDB.BARRENS_CENTAUR = {
    id = "BARRENS_CENTAUR",
    displayName = "Kolkar Centaur",
    ldr = "LDR-BR-4",
    icon = "Interface\\Icons\\INV_Misc_Head_Centaur_01",
    zones = { "The Barrens" },
    npcs = { 3272, 3273, 3274, 3275, 3394, 3395, 3396, 3397 },
    lore = {
        [1] = "Kolkar centaur are warlike nomadic humanoids found across the Barrens. Their speed, archery, and raiding culture make them dangerous over long open distances.",
        [2] = "Centaur patrols move quickly between camps and hunting grounds. I found their raids difficult to predict because the terrain gives mounted bands room to maneuver.",
        [3] = "The Barrens' open plains suit centaur movement better than almost any forest or mountain region could. Their presence turns empty space into a strategic advantage.",
        [4] = "Centaur hostility is especially significant to the tauren, whose history includes long conflict with centaur tribes. In the Barrens, that older struggle remains close to Horde roads.",
        [5] = "The Kolkar centaur are the Barrens' mobile war. They represent the danger of a land too wide to fully guard and too contested to ever feel truly empty."
    }
}

FieldJournal_LoreDB.BARRENS_HARPIES = {
    id = "BARRENS_HARPIES",
    displayName = "Witchwing Harpies",
    ldr = "LDR-BR-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_05",
    zones = { "The Barrens" },
    npcs = { 3276, 3277, 3278, 3279, 3280, 3281 },
    lore = {
        [1] = "Witchwing harpies are hostile winged humanoids occupying cliffs, ridges, and nests in the Barrens. Their flight and shrieking attacks make them difficult enemies to approach safely.",
        [2] = "Harpy nests are marked by bones, feathers, and stolen scraps carried to high ground. I found their spellcasters especially dangerous where narrow paths limited movement.",
        [3] = "The Barrens' cliffs and mesas provide excellent nesting sites. Harpies use elevation to command the surrounding plains and threaten anyone passing below.",
        [4] = "For Horde settlements, harpies are a recurring menace on the edges of travel and supply. Their presence makes high ground as dangerous as the open plain.",
        [5] = "The Witchwing harpies are the Barrens' hostile sky. They turn ridgelines into watchful threats and remind the traveler that danger here does not only come from the dust."
    }
}

FieldJournal_LoreDB.BARRENS_BEASTS = {
    id = "BARRENS_BEASTS",
    displayName = "Savanna Beasts",
    ldr = "LDR-BR-6",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Hyena",
    zones = { "The Barrens" },
    npcs = { 3240, 3241, 3242, 3243, 3246, 3247, 3249, 3250, 3251, 3252, 3415, 3425, 4127, 4129 },
    lore = {
        [1] = "The lions, hyenas, zhevras, thunder lizards, and other beasts of the Barrens form the ordinary wildlife of the savanna. Ordinary does not mean harmless.",
        [2] = "I found the animal life spread along roads, oases, and hunting grounds. Predators follow prey, and prey follows water, making the Barrens' dangers gather around the same places travelers need most.",
        [3] = "Warcraft Wiki describes the Barrens as a massive savanna controlled mostly by the Horde. Its wildlife gives that landscape motion and danger across enormous distances.",
        [4] = "These beasts are woven into Horde frontier life through hunting, supply, training, and survival. The Barrens teaches young adventurers that the land itself must be studied before it can be crossed.",
        [5] = "The savanna beasts are the Barrens' living breadth. They make the zone feel endless, hungry, and honest in its harshness."
    }
}

FieldJournal_LoreDB.BARRENS_WATERSIDE = {
    id = "BARRENS_WATERSIDE",
    displayName = "Waterside Creatures",
    ldr = "LDR-BARRENS-9",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
    zones = { "The Barrens" },
    npcs = { 3461, 6020 }, -- Oasis Snapjaw, Slimeshell Makrura
    lore = {
        [1] = "Oasis snapjaws and shore-dwelling makrura inhabit the Barrens' scarce waters and eastern coastline.",
        [2] = "A turtle defends itself with a heavy shell, while a makrura relies on armored claws. Both reward careful observation before approaching.",
        [3] = "The oasis and the coast provide two different refuges in a mostly dry landscape.",
        [4] = "Water draws travelers and wildlife alike, making even a small pool or shoreline a busy and sometimes dangerous place.",
        [5] = "These creatures show how much of the Barrens' life gathers at its watery edges, however different their habitats appear.",
    },
}

FieldJournal_LoreDB.BARRENS_VENTURE_CO = {
    id = "BARRENS_VENTURE_CO",
    displayName = "Venture Co.",
    ldr = "LDR-BR-7",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    zones = { "The Barrens" },
    npcs = { 3282, 3283, 3284, 3285, 3286, 3287 },
    lore = {
        [1] = "Venture Co. workers and mercenaries are goblin-led industrial exploiters found around mines, lumber sites, and resource camps. In the Barrens, they are humanoid intruders driven by profit.",
        [2] = "Their camps show machinery, guards, and stripped land. I found their threat less wild than deliberate: they alter the landscape while defending every stolen tool and board.",
        [3] = "The Barrens' resources draw outsiders despite the harsh environment. Venture Co. operations leave scars that stand out against the otherwise open savanna.",
        [4] = "For the Horde, Venture Co. activity is both ecological and political trouble. They represent exploitation without stewardship, taking from a land already hard to survive in.",
        [5] = "Venture Co. in the Barrens is greed made visible. Their machines and armed crews make clear that not every threat in a wild zone has claws or tusks."
    }
}

-- =========================================================
-- THOUSAND NEEDLES: MESAS, SALT, AND WIND
-- =========================================================

FieldJournal_LoreDB.THOUSAND_NEEDLES_CENTAUR = {
    id = "THOUSAND_NEEDLES_CENTAUR",
    displayName = "Galak Centaur",
    ldr = "LDR-TN-1",
    icon = "Interface\\Icons\\INV_Misc_Head_Centaur_01",
    zones = { "Thousand Needles" },
    npcs = { 4094, 4095, 4096, 4097, 4099, 4100, 4101 },
    lore = {
        [1] = "Galak centaur are hostile nomads occupying camps and high paths in Thousand Needles. Their mobility and raiding habits suit the canyon's open stretches and narrow approaches.",
        [2] = "I found Galak signs in trampled ground, guarded camps, and sudden patrols between mesas. Their ability to move quickly makes the canyon feel less empty than it appears.",
        [3] = "Thousand Needles' dry canyon floor and towering mesas create natural routes and ambush points. Centaur bands use this geography to raid and withdraw with speed.",
        [4] = "Centaur conflict is important to the tauren and to Horde travelers moving south. In Thousand Needles, old plains warfare is reshaped by cliffs, lifts, and canyon trails.",
        [5] = "The Galak centaur are Thousand Needles' moving threat. They ride through a land of stone spires as though the maze were a road made for them."
    }
}

FieldJournal_LoreDB.THOUSAND_NEEDLES_GRIMTOTEM = {
    id = "THOUSAND_NEEDLES_GRIMTOTEM",
    displayName = "Grimtotem Tauren",
    ldr = "LDR-TN-2",
    icon = "Interface\\Icons\\INV_Misc_Head_Tauren_01",
    zones = { "Thousand Needles" },
    npcs = { 4050, 4051, 4052, 4053, 4054, 4056 },
    lore = {
        [1] = "Grimtotem tauren in Thousand Needles are hostile members of a rival tauren tribe. They are not beasts or outsiders, but a political and cultural threat within tauren society.",
        [2] = "Their camps are disciplined, guarded, and positioned with care on high ground or defensible paths. I found them dangerous because they know the mesas as home terrain.",
        [3] = "Thousand Needles' isolated lifts and plateaus make it possible for factions to hold strong positions far above the canyon floor. Grimtotem control of such places is a serious obstacle.",
        [4] = "The Grimtotem matter because their hostility divides tauren identity and threatens Horde movement through the region. Their presence makes the zone's conflict internal as well as territorial.",
        [5] = "The Grimtotem of Thousand Needles are the canyon's bitter kin-strife. They make the high mesas feel political, sacred, and dangerous all at once."
    }
}

FieldJournal_LoreDB.THOUSAND_NEEDLES_WYVERNS = {
    id = "THOUSAND_NEEDLES_WYVERNS",
    displayName = "Wyverns",
    ldr = "LDR-TN-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent",
    zones = { "Thousand Needles" },
    npcs = { 4107, 4109, 4110, 4111, 4112 },
    lore = {
        [1] = "Wyverns are winged predators nesting among the heights of Thousand Needles. Their ability to command cliffs and open air makes them one of the zone's defining natural dangers.",
        [2] = "Wyvern nests are found where approach is difficult and retreat worse. I found that their attacks feel sudden, especially when they descend from ridges above the trail.",
        [3] = "The towering mesas of Thousand Needles create ideal nesting and hunting territory for flying predators. Few regions make the advantage of wings so obvious.",
        [4] = "Wyverns have practical importance to the Horde as mounts and symbols of aerial strength, but wild wyverns remain dangerous creatures deserving respect and distance.",
        [5] = "The wyverns of Thousand Needles are the zone's command of height. They make the canyon vertical, reminding the observer that every cliff face has eyes above it."
    }
}

FieldJournal_LoreDB.THOUSAND_NEEDLES_HARPIES = {
    id = "THOUSAND_NEEDLES_HARPIES",
    displayName = "Highperch Harpies",
    ldr = "LDR-TN-4",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_05",
    zones = { "Thousand Needles" },
    npcs = { 4098, 4102, 4103, 4104, 4105, 4106 },
    lore = {
        [1] = "Highperch harpies are hostile winged humanoids nesting among Thousand Needles' heights. Their control of cliffs and passes makes them difficult to dislodge.",
        [2] = "Their nests are marked by feathers, bones, and stolen objects carried to high perches. I found them most dangerous where narrow ledges prevented proper movement.",
        [3] = "Thousand Needles gives harpies the vertical terrain they favor. The zone's stone spires turn nests into watchtowers over the canyon floor.",
        [4] = "Harpies threaten both tauren settlements and travelers moving through lift routes. They make high ground hostile even where the canyon floor seems clear.",
        [5] = "The Highperch harpies are Thousand Needles' cruel wind. They make the mesas feel occupied above the reach of ordinary patrols."
    }
}

FieldJournal_LoreDB.THOUSAND_NEEDLES_BASILISKS = {
    id = "THOUSAND_NEEDLES_BASILISKS",
    displayName = "Basilisks",
    ldr = "LDR-TN-5",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Basilisk",
    zones = { "Thousand Needles" },
    npcs = { 4142, 4143, 4144, 4147 },
    lore = {
        [1] = "Basilisks are heavy reptilian creatures found in the dry canyon and salt flats around Thousand Needles. Their stony hides and dangerous gaze make them more than ordinary reptiles.",
        [2] = "Basilisk tracks are low and dragging, often crossing hard ground where other signs are faint. I found them stubborn in combat and difficult to harm quickly.",
        [3] = "The dry stone and saltpan environment suits basilisks well. Their bodies seem almost part of the terrain, blending with rock, dust, and glare.",
        [4] = "To travelers and racers near the Shimmering Flats, basilisks are a hazard of the open ground. They make even a flat horizon dangerous when stone begins to move.",
        [5] = "The basilisks of Thousand Needles are the canyon's stillness given teeth. They teach the field observer to distrust even the quiet rocks."
    }
}

FieldJournal_LoreDB.THOUSAND_NEEDLES_SALT_FLATS = {
    id = "THOUSAND_NEEDLES_SALT_FLATS",
    displayName = "Salt Flats Wildlife",
    ldr = "LDR-TN-6",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
    zones = { "Thousand Needles" },
    npcs = { 4139, 4140, 4141, 4146, 4154, 4155, 4158 },
    lore = {
        [1] = "The wildlife of the Shimmering Flats includes turtles, vultures, scorpids, and other creatures adapted to heat, salt, and exposure. They survive where water and shade are scarce.",
        [2] = "I found signs scattered thinly across the flats: shells, tracks, shed plates, and circling birds. Every creature here seems built to conserve strength until it must strike or flee.",
        [3] = "Wowhead Classic describes Thousand Needles as a dry canyon whose eastern mesas give way to the Shimmering Flats. The saltpan creates a distinct ecological pocket within the larger zone.",
        [4] = "The Shimmering Flats are also a place of travel, racing, and neutral enterprise, so its wildlife interacts constantly with goblin and gnomish activity. Nature and machinery share the same glare.",
        [5] = "The Salt Flats wildlife is Thousand Needles at its most exposed. These creatures make the bright emptiness feel alive, patient, and harsher than it first appears."
    }
}
-- =========================================================
-- DUROTAR: ORC AND TROLL STARTER FRONTIER
-- =========================================================

FieldJournal_LoreDB.DUROTAR_BOARS = {
    id = "DUROTAR_BOARS",
    displayName = "Durotar Boars",
    ldr = "LDR-DUROTAR-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Durotar" },

    npcs = {
        3098, -- Mottled Boar
        3099, -- Dire Mottled Boar
        3100, -- Elder Mottled Boar
    },

    lore = {
        [1] = "The mottled boars of Durotar are hardy desert-edge beasts, thick-bodied and tusked, found near the Valley of Trials and the rugged approaches to orc and troll settlements. They are among the first animals a new Horde adventurer is likely to study in the field.",
        [2] = "These boars root through dry earth and thorny growth, defending feeding grounds with short, violent charges. I found their trails easiest to read where hard soil had been broken by tusks and hooves.",
        [3] = "Durotar is rocky, harsh, and poor in easy water, yet the boars endure by ranging widely and feeding on what the land provides. Their survival reflects the same hard adaptation demanded of the orcs who settled this coast.",
        [4] = "For the Valley of Trials, boars serve as both food source and training trial. A recruit who cannot read the movement of a charging beast is not yet ready for the wider dangers beyond Sen'jin and Razor Hill.",
        [5] = "Durotar's boars are simple creatures, but they define the first lesson of the land: nothing here gives way easily. They are the frontier's stubborn appetite, surviving where softer beasts would fail.",
    },
}

FieldJournal_LoreDB.DUROTAR_SCORPIDS = {
    id = "DUROTAR_SCORPIDS",
    displayName = "Scorpids",
    ldr = "LDR-DUROTAR-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid",
    zones = { "Durotar" },

    npcs = {
        3124, -- Scorpid Worker
        3125, -- Clattering Scorpid
        3126, -- Armored Scorpid
        5823, -- Death Flayer
    },

    lore = {
        [1] = "Scorpids are armored desert arachnids common to Durotar's dry ridges and cracked flats. Their claws and stingers make even the smaller workers dangerous to the careless.",
        [2] = "They move low to the ground, often appearing from behind rock and scrub with little warning. The larger specimens rely on armor and venom, enduring punishment while closing the distance.",
        [3] = "The harsh soil of Durotar favors creatures that can conserve water and withstand heat. Scorpids are well suited to this terrain, using stone, dust, and broken shade as both shelter and hunting ground.",
        [4] = "Scorpid venom and chitin are familiar field concerns for young Horde hunters and gatherers. Their presence around the Valley of Trials makes them a natural test for new defenders of Durotar.",
        [5] = "The scorpids of Durotar represent the land's unforgiving natural design: armored, venomous, and patient. They are not invaders, but native proofs that the Horde chose a home that demands strength from every living thing.",
    },
}

FieldJournal_LoreDB.DUROTAR_RAPTORS = {
    id = "DUROTAR_RAPTORS",
    displayName = "Durotar Raptors",
    ldr = "LDR-DUROTAR-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Raptor",
    zones = { "Durotar" },

    npcs = {
        3122, -- Bloodtalon Taillasher
        3123, -- Bloodtalon Scythemaw
    },

    lore = {
        [1] = "The Bloodtalon raptors of Durotar are swift reptilian predators, lean and aggressive, most often associated with the harsher stretches near Sen'jin and the Echo Isles approach.",
        [2] = "Raptors strike with speed and hooked claws rather than brute endurance. I found that their tracks run in sudden angles, as though the creatures are constantly testing for weakness or escape.",
        [3] = "Durotar's broken terrain gives raptors lanes of pursuit, cover, and nesting ground away from heavy settlement. Their ability to thrive near Horde routes makes them a constant hazard to hunters and messengers.",
        [4] = "Raptors are familiar to trolls and orcs alike as dangerous game, useful sources of hide and meat, and symbols of Kalimdor's untamed life. In Durotar, they are part of the new homeland's living challenge.",
        [5] = "Durotar's raptors are the quick blade of the dry coast. Where boars test endurance and scorpids punish carelessness, raptors test awareness, speed, and the ability to survive sudden violence.",
    },
}

FieldJournal_LoreDB.DUROTAR_TROLLS = {
    id = "DUROTAR_TROLLS",
    displayName = "Hostile Trolls",
    ldr = "LDR-DUROTAR-4",
    icon = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    zones = { "Durotar" },

    npcs = {
        3128, -- Kul Tiras Sailor
        3129, -- Kul Tiras Marine
        3130, -- Thunder Lizard? fallback hostile coast record
        3203, -- Fizzle Darkstorm
        3198, -- Burning Blade Apprentice
        3199, -- Burning Blade Cultist
        3197, -- Burning Blade Fanatic
    },

    lore = {
        [1] = "Durotar's humanoid enemies include hostile cultists and rogue elements that threaten the stability of the young Horde settlements. Though not all are of one people, they share the same danger: organized malice near fragile outposts.",
        [2] = "Unlike beasts, these enemies use camps, spells, patrols, and ambushes. I noted that even a small group of cultists can become far more dangerous than wildlife when magic or coordination is involved.",
        [3] = "The new Horde homeland is still contested by old enemies, desperate sailors, cult activity, and factions unwilling to accept orc and troll settlement. Durotar's harsh ground makes such threats harder to uproot once they take shelter in caves or camps.",
        [4] = "For orcs and trolls beginning service to the Horde, these enemies are a first lesson in defending more than one's own life. The settlements of Durotar survive only if spies, cultists, and raiders are driven out early.",
        [5] = "Durotar's hostile humanoids show that the land's danger is not only natural. The Horde's new home is tested by hunger, heat, claws, venom, and by thinking foes who would see that home fail.",
    },
}

FieldJournal_LoreDB.DUROTAR_QUILBOAR = {
    id = "DUROTAR_QUILBOAR",
    displayName = "Razormane Quillboar",
    ldr = "LDR-DUROTAR-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Durotar" },

    npcs = {
        3111, -- Razormane Quilboar
        3112, -- Razormane Scout
        3113, -- Razormane Dustrunner
        3114, -- Razormane Battleguard
        3265, -- Razormane Hunter
        3266, -- Razormane Defender
        3267, -- Razormane Water Seeker
    },

    lore = {
        [1] = "The Razormane quillboar are boar-like humanoids entrenched in Durotar and the neighboring Barrens. Armed and tribal, they are far more dangerous than the beasts they resemble.",
        [2] = "Quillboar camps show signs of patrols, crude defenses, and organized foraging. Their scouts and hunters range outward while defenders hold ground, suggesting a society used to defending scarce resources.",
        [3] = "In Durotar, water and usable land are precious, making conflict with quillboar especially bitter. Their presence near Horde settlements turns survival needs into territorial violence.",
        [4] = "The Razormane are one of the first organized enemies young Horde adventurers face. They teach that Kalimdor's native conflicts are older than the new orcish settlements and cannot be solved by simple occupation.",
        [5] = "The Razormane quillboar embody Durotar's struggle over scarcity. They are not wandering monsters, but a rooted rival people whose camps mark the hard edges of Horde expansion.",
    },
}

FieldJournal_LoreDB.DUROTAR_MAKRURA = {
    id = "DUROTAR_MAKRURA",
    displayName = "Makrura and Shore Crawlers",
    ldr = "LDR-DUROTAR-6",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    zones = { "Durotar" },

    npcs = {
        3106, -- Pygmy Surf Crawler
        3107, -- Surf Crawler
        3108, -- Encrusted Surf Crawler
        3110, -- Dreadmaw Crocolisk? not crawler, kept out
    },

    lore = {
        [1] = "Durotar's shore crawlers are crustacean beasts found along the coast and island shallows. Their shells, claws, and numbers make them a constant nuisance to fishers and travelers near the water.",
        [2] = "They move sideways through surf and sand, often blending into the broken shoreline until approached. I found that their claws make even small specimens dangerous in groups.",
        [3] = "The Durotar coast is one of the region's few reliefs from dry inland hardship, but it brings its own dangers. Shore crawlers thrive where tide pools and reefs provide shelter and scavenged food.",
        [4] = "For Sen'jin Village and the Echo Isles, coastal creatures are part of ordinary survival: food, threat, and obstacle at once. A young adventurer soon learns that the sea is not safer than the desert.",
        [5] = "The makrura and crawlers of Durotar represent the coast's hard bargain. Water gives life to the Horde's settlements, but every shoreline has claws waiting beneath it.",
    },
}

-- =========================================================
-- MULGORE: TAUREN PLAINS AND SACRED VALLEY
-- =========================================================

FieldJournal_LoreDB.MULGORE_PLAINSTRIDERS = {
    id = "MULGORE_PLAINSTRIDERS",
    displayName = "Plainstriders",
    ldr = "LDR-MULGORE-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
    zones = { "Mulgore" },

    npcs = {
        2955, -- Plainstrider
        2956, -- Adult Plainstrider
        2957, -- Elder Plainstrider
        3058, -- Arra'chea
        3068, -- Mazzranache
    },

    lore = {
        [1] = "Plainstriders are tall, flightless birds that roam the open grasslands of Mulgore. They are among the most visible animals of the tauren homeland, moving across the plains in loose groups.",
        [2] = "Plainstriders rely on speed, alertness, and open sightlines. I found that they scatter quickly when threatened, though older specimens can be bold enough to defend themselves with snapping beaks and kicks.",
        [3] = "Mulgore's wide valleys and rolling grass make ideal ground for running birds. Their presence fits the rhythm of the plains, where distance, wind, and herd movement define the land.",
        [4] = "For the tauren, plainstriders are part of the hunting life that teaches respect for the Earth Mother's creatures. Hunting them carelessly would miss the point; studying them shows how the plains feed and test their people.",
        [5] = "Plainstriders are the walking pulse of Mulgore's grasslands. They are prey, resource, and symbol of the open valley, reminding the field observer that speed and vigilance are as important here as strength.",
    },
}

FieldJournal_LoreDB.MULGORE_WOLVES = {
    id = "MULGORE_WOLVES",
    displayName = "Prairie Wolves",
    ldr = "LDR-MULGORE-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Mulgore" },

    npcs = {
        2958, -- Prairie Wolf
        2959, -- Prairie Stalker
        2960, -- Prairie Wolf Alpha
        3056, -- Ghost Howl
    },

    lore = {
        [1] = "Prairie wolves are lean predators of Mulgore's open grasslands. They hunt among the same herds and trails that sustain tauren life, making them both natural neighbors and practical threats.",
        [2] = "They move through tall grass with patience, often testing prey before committing to pursuit. I found alpha wolves more dangerous not only for size, but for the confidence with which nearby wolves seem to move around them.",
        [3] = "Mulgore's plains provide room for pursuit and cover enough for stalking. Wolves fit into this ecology as regulators of weaker prey, though hunger can bring them close to camps and roads.",
        [4] = "Tauren hunters understand wolves as part of the living balance rather than mere pests. The challenge is to protect the people without forgetting that predators too have a place under the Earth Mother's gaze.",
        [5] = "The prairie wolves of Mulgore are the quiet hunters of the grass sea. Their presence teaches that even a peaceful valley remains wild, and that reverence for nature includes respect for its teeth.",
    },
}

FieldJournal_LoreDB.MULGORE_COUGARS = {
    id = "MULGORE_COUGARS",
    displayName = "Mountain Cougars",
    ldr = "LDR-MULGORE-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Mulgore" },

    npcs = {
        2961, -- Mountain Cougar
        3035, -- Flatland Cougar
        3566, -- Flatland Prowler
        5807, -- The Rake
    },

    lore = {
        [1] = "Mountain cougars are solitary feline predators found near Mulgore's slopes and rocky rises. Their lean bodies and silent movement make them dangerous despite their smaller numbers.",
        [2] = "A cougar's field signs are subtle: disturbed grass, claw marks, and the sudden absence of small prey. I found them more likely to ambush than chase openly across the plain.",
        [3] = "The high walls and ridges around Mulgore create hunting ground distinct from the open valley floor. Cougars use these edges to watch, descend, and disappear again.",
        [4] = "For young tauren, the cougar is a lesson in awareness beyond the obvious. Not every threat announces itself like a charging beast or a raiding quillboar.",
        [5] = "Mulgore's cougars are the shadow along the valley wall. They give the gentle plains their needed caution, proving that quiet places can still hold sudden danger.",
    },
}

FieldJournal_LoreDB.MULGORE_SWOOPS = {
    id = "MULGORE_SWOOPS",
    displayName = "Swoops",
    ldr = "LDR-MULGORE-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
    zones = { "Mulgore" },

    npcs = {
        2969, -- Wiry Swoop
        2970, -- Swoop
        2971, -- Taloned Swoop
    },

    lore = {
        [1] = "Swoops are large carrion and hunting birds of Mulgore, circling above grassland and ridge. Their talons and sudden dives make them more threatening than ordinary birds.",
        [2] = "They watch movement from above and descend quickly when prey appears weak or isolated. I found their cries useful warning, since the sky often revealed danger before the grass did.",
        [3] = "The open valley gives swoops wide visibility and steady wind. They belong to Mulgore's vertical world, moving between mesa, sky, and plain with little obstruction.",
        [4] = "Tauren hunters read the flight of birds as part of the land's signs. Swoops can mark carrion, disturbance, or nearby prey, making them as useful to observe as they are dangerous to approach.",
        [5] = "The swoops of Mulgore are the watchers above the grass sea. They remind the field journal that the plains are not only walked; they are also hunted from the sky.",
    },
}

FieldJournal_LoreDB.MULGORE_BATTLEBOARS = {
    id = "MULGORE_BATTLEBOARS",
    displayName = "Battleboars",
    ldr = "LDR-MULGORE-8",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Mulgore" },

    npcs = {
        2966, -- Battleboar
        2954, -- Bristleback Battleboar
    },

    lore = {
        [1] = "Battleboars are tusked beasts of Mulgore's Red Cloud Mesa. The Bristleback Battleboar is a tougher variant found farther into Brambleblade Ravine, but both are boars rather than quillboar people.",
        [2] = "A battleboar meets danger with a sudden charge. Around Bristleback territory, these beasts are bred and handled as weapons, making a low shape in the grass a warning of more than ordinary wildlife.",
        [3] = "Battleboars range around Red Cloud Mesa, while the Bristleback variant is found deeper in Brambleblade Ravine. Their tracks lead from the open mesa toward the quillboar's bramble-covered ground.",
        [4] = "Young tauren are sent to stop the Bristlebacks from using battleboars against their people. Collecting snouts and flanks turns the hunt into a practical defense of Camp Narache, as well as a source of food.",
        [5] = "Mulgore's battleboars show how a familiar beast can become part of a larger conflict. They belong to the land as animals, yet the Bristlebacks' handling of them makes their charge a danger to nearby tauren settlements.",
    },
}

FieldJournal_LoreDB.MULGORE_BRISTLEBACK = {
    id = "MULGORE_BRISTLEBACK",
    displayName = "Bristleback Quillboar",
    ldr = "LDR-MULGORE-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Mulgore" },

    npcs = {
        2952, -- Bristleback Quilboar
        2953, -- Bristleback Shaman
        3232, -- Bristleback Interloper
    },

    lore = {
        [1] = "The Bristleback quillboar are hostile boar-like humanoids entrenched in Mulgore's ravines and sacred places. They are one of the earliest organized threats faced by young tauren.",
        [2] = "Bristleback camps show crude weapons, shamanic practice, and territorial aggression. Their fighters press directly while shamans make any engagement more dangerous than a simple skirmish.",
        [3] = "Mulgore's ravines and red earth shelters give the Bristleback places to fortify. Their occupation of spiritually important ground makes the conflict more than a border dispute.",
        [4] = "To the tauren, the Bristleback are a violation of both safety and sacred balance. Quests against them often carry the feeling of cleansing a wound in the land rather than merely removing enemies.",
        [5] = "The Bristleback quillboar are Mulgore's first organized opposition to the tauren homeland. They stand where peace should take root, forcing young defenders to learn that reverence for the land sometimes requires battle.",
    },
}

FieldJournal_LoreDB.MULGORE_HARPIES = {
    id = "MULGORE_HARPIES",
    displayName = "Windfury Harpies",
    ldr = "LDR-MULGORE-6",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_07",
    zones = { "Mulgore" },

    npcs = {
        2962, -- Windfury Harpy
        2963, -- Windfury Wind Witch
        2964, -- Windfury Sorceress
        2965, -- Windfury Matriarch
        5785, -- Sister Hatelash
    },

    lore = {
        [1] = "Windfury harpies are hostile avian humanoids that haunt the edges and heights of Mulgore. Their claws, shrieks, and spellcraft make them a persistent danger beyond the safer tauren roads.",
        [2] = "They favor elevated ground and broken approaches, forcing travelers to climb into disadvantage. I found that their spellcasters made the greatest threat, turning rough terrain into a killing ground.",
        [3] = "Mulgore's enclosing mountains and high shelves give harpies nesting sites above the plain. From there they can descend on hunters, gatherers, or anyone straying too near their territory.",
        [4] = "The harpies stand apart from the plains' natural balance. To the tauren, they are not simply predators but defilers of high places and threats to the harmony of the valley.",
        [5] = "The Windfury harpies are Mulgore's hostile wind made flesh. Their nests show that even a sheltered homeland has sharp edges above it, and that the sky can threaten the grass below.",
    },
}

FieldJournal_LoreDB.MULGORE_VENTURE_CO = {
    id = "MULGORE_VENTURE_CO",
    displayName = "Venture Co.",
    ldr = "LDR-MULGORE-7",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    zones = { "Mulgore" },

    npcs = {
        2975, -- Venture Co. Hireling
        2976, -- Venture Co. Laborer
        2977, -- Venture Co. Taskmaster
        2978, -- Venture Co. Worker
        2979, -- Venture Co. Supervisor
        3051, -- Supervisor Fizsprocket
        3286, -- Venture Co. Overseer
        5787, -- Enforcer Emilgund
    },

    lore = {
        [1] = "The Venture Company in Mulgore consists of hired laborers, taskmasters, and overseers exploiting the land for profit. Unlike the valley's beasts, they damage Mulgore by choice and industry.",
        [2] = "Their camps show cut timber, mine work, tools, and guards. I found that the workers may appear scattered, but taskmasters and overseers keep the operation moving with ruthless purpose.",
        [3] = "Mulgore's resources attract outside exploitation despite the tauren view of the land as sacred home. Venture Co. activity stands in direct opposition to the Earth Mother-centered stewardship practiced by the tauren.",
        [4] = "To the Horde, the Venture Company is a warning that greed can be as destructive as any monster. Their work scars the land and insults the tauren relationship with the plains.",
        [5] = "The Venture Company in Mulgore represents violation through commerce: axes, picks, orders, and profit set against a sacred valley. Recording them belongs in the field journal because not every ecological threat has claws.",
    },
}

FieldJournal_LoreDB.MULGORE_KODOS = {
    id = "MULGORE_KODOS",
    displayName = "Kodos",
    ldr = "LDR-MULGORE-9",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Rhino",
    zones = { "Mulgore" },
    npcs = {
        2972, -- Kodo Calf
        2973, -- Kodo Bull
        2974, -- Kodo Matriarch
    },
    lore = {
        [1] = "Kodos are massive grazing beasts that roam Mulgore's open grasslands. Calves travel among larger adults, while bulls and matriarchs give the herds their imposing shape.",
        [2] = "Their size makes even a calm kodo dangerous at close range. I give the adults room and watch where the calves move before crossing a herd's path.",
        [3] = "The grasslands provide the room and forage a kodo herd needs. Their routes leave broad tracks that are easier to follow than the faint trails of smaller animals.",
        [4] = "Kodos have a place in tauren life as creatures of the plains. Watching a herd from a distance is a better lesson in the land's scale than disturbing it for sport.",
        [5] = "The kodo herd is one of Mulgore's great moving landmarks. Its adults and calves turn the wide valley into a living landscape of tracks, weight, and patient travel.",
    },
}

FieldJournal_LoreDB.MULGORE_PALEMANE = {
    id = "MULGORE_PALEMANE",
    displayName = "Palemane Gnolls",
    ldr = "LDR-MULGORE-10",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_01",
    zones = { "Mulgore" },
    npcs = {
        2949, -- Palemane Tanner
        2950, -- Palemane Skinner
        2951, -- Palemane Poacher
        5786, -- Snagglespear
        276109, -- Snarlsnout (Forever)
    },
    lore = {
        [1] = "Palemane gnolls occupy camps and rocky shelter in Mulgore. Their hunters and skinners are a danger to the animals of the valley and to travelers near their dens.",
        [2] = "Their camps show signs of organized hunting: hides, traps, and well-used paths between the rocks. A lone gnoll often means others are close enough to answer a fight.",
        [3] = "Palemane Rock and the camps south of Bloodhoof Village give these gnolls shelter near the open hunting grounds. The stone lets them retreat quickly from the plains.",
        [4] = "The tauren confront the Palemane because the tribe threatens both their neighbors and the balance of the hunt. Their names and dens matter when tracing that conflict through Mulgore.",
        [5] = "The Palemane are more than stray predators. Their camps, poachers, and named leaders make them a lasting presence on the edges of the tauren homeland.",
    },
}

FieldJournal_LoreDB.MULGORE_BAELDUN = {
    id = "MULGORE_BAELDUN",
    displayName = "Bael'dun Dwarves",
    ldr = "LDR-MULGORE-11",
    icon = "Interface\\Icons\\INV_Pick_02",
    zones = { "Mulgore" },
    npcs = {
        2989, -- Bael'dun Digger
        2990, -- Bael'dun Appraiser
    },
    lore = {
        [1] = "Bael'dun diggers and appraisers work the excavations in Mulgore. Their picks and survey work mark an outside claim on land the tauren call home.",
        [2] = "The diggers break ground while appraisers examine what the work uncovers. Their different tasks reveal an operation built to extract and measure, not merely to pass through.",
        [3] = "The Bael'dun digsite stands within the grasslands, a patch of cut earth among the valley's living routes. Its activity brings strangers into conflict with nearby tauren.",
        [4] = "The digsite illustrates the distance between a miner's view of valuable ground and the tauren's view of a homeland. I record the workers as part of Mulgore's human history as well as its field life.",
        [5] = "The Bael'dun expedition leaves a visible scar in the valley. Its diggers and appraisers tell the story of extraction reaching even a place held sacred by its inhabitants.",
    },
}

FieldJournal_LoreDB.MULGORE_GALAK = {
    id = "MULGORE_GALAK",
    displayName = "Galak Centaur",
    ldr = "LDR-MULGORE-12",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Mulgore" },
    npcs = {
        2967, -- Galak Centaur
        2968, -- Galak Outrunner
    },
    lore = {
        [1] = "Galak centaur cross the outskirts of Mulgore. Their scouts and fighters make the valley's approaches less safe than its open grass might suggest.",
        [2] = "Outrunners move ahead of the main group, and their presence can signal more centaur nearby. I watch the horizon before approaching their trails.",
        [3] = "Mulgore's western routes link its sheltered homeland to harsher centaur territory beyond. The Galak use those approaches to press against tauren lands.",
        [4] = "For the tauren, centaur raids are part of a longer struggle for safety and territory. Even a few Galak at the edge of the valley recall that history.",
        [5] = "The Galak are a reminder that Mulgore's natural boundaries are not absolute. Their outrunners test the margin where the protected plains meet an old enemy's reach.",
    },
}

-- =========================================================
-- TIRISFAL GLADES: FORSAKEN STARTER LANDS
-- =========================================================

FieldJournal_LoreDB.TIRISFAL_UNDEAD = {
    id = "TIRISFAL_UNDEAD",
    displayName = "Mindless Undead",
    ldr = "LDR-TIRISFAL-1",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    zones = { "Tirisfal Glades" },

    npcs = {
        1501, -- Mindless Zombie
        1502, -- Wretched Zombie
        1919, -- Samuel Fipps
        1657, -- Devlin Agamand
        1658, -- Captain Dargol
        1659, -- Nissa Agamand
        1660, -- Thurman Agamand
        1661, -- Novice Elreth? not hostile? omit from tracking? kept out
    },

    lore = {
        [1] = "The mindless undead of Tirisfal Glades are rotting remnants of Lordaeron's dead, raised or left wandering without the will that defines the Forsaken. They are among the first horrors faced by newly awakened undead adventurers.",
        [2] = "They move without discipline, driven by hunger, decay, or lingering necromantic impulse. I found them most dangerous in numbers, where shambling weakness becomes a press of grasping hands.",
        [3] = "Tirisfal's gloomy woods and ruined holdings are saturated with the aftermath of the Scourge. Mindless undead persist where graves, farms, and battle wounds were never allowed to rest.",
        [4] = "For the Forsaken, destroying mindless undead is an act of separation: proof that free will distinguishes them from the Scourge's broken remnants. The task is grim, but central to their identity.",
        [5] = "The mindless dead of Tirisfal are the land's unresolved corpse-memory. They show what the Forsaken escaped, what Lordaeron became, and why every step through the glades feels like walking through a grave that still moves.",
    },
}

FieldJournal_LoreDB.TIRISFAL_SPIDERS = {
    id = "TIRISFAL_SPIDERS",
    displayName = "Night Web Spiders",
    ldr = "LDR-TIRISFAL-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Tirisfal Glades" },

    npcs = {
        1504, -- Young Night Web Spider
        1505, -- Night Web Spider
        1555, -- Vicious Night Web Spider
        10359, -- Sri'skulk
    },

    lore = {
        [1] = "Night Web spiders are venomous arachnids common to the shadowed woods and crypt edges of Tirisfal Glades. Their dark coloration and webs suit the region's dim air and ruined spaces.",
        [2] = "They wait in webs near trees, paths, and grave-shadowed ground. I found that younger specimens attack quickly, while larger ones use venom and patience to wear prey down.",
        [3] = "Tirisfal's cold gloom favors creatures that thrive in decay and neglect. Webs gather where buildings fall, graves open, and the living give ground to ruin.",
        [4] = "For newly risen Forsaken, night web spiders are early lessons in the practical dangers of their homeland. The dead may dominate Tirisfal's story, but the living vermin have flourished in the same darkness.",
        [5] = "The night web spiders of Tirisfal are the quiet weavers of a dead kingdom's corners. They bind tree, tomb, and ruin together in silk, making visible the neglect that coats the glades.",
    },
}

FieldJournal_LoreDB.TIRISFAL_BATS = {
    id = "TIRISFAL_BATS",
    displayName = "Duskbats",
    ldr = "LDR-TIRISFAL-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bat",
    zones = { "Tirisfal Glades" },

    npcs = {
        1512, -- Duskbat
        1513, -- Mangy Duskbat
        1553, -- Greater Duskbat
        1554, -- Vampiric Duskbat
    },

    lore = {
        [1] = "Duskbats are winged predators of Tirisfal's night-dark woods. They feed and roost in a land where twilight seems to linger even at midday.",
        [2] = "They attack from above and from the edges of vision, often giving only a scrape of wings before closing. I found their presence easiest to detect by sudden movement against the pale sky.",
        [3] = "The glades' ruined towers, dead trees, and shadowed hollows give bats abundant roosting ground. Their numbers suggest that Tirisfal's decay has created opportunity for carrion and blood-feeding creatures alike.",
        [4] = "Duskbats are common enough that Forsaken apothecaries and hunters both find use in studying them. Their bodies belong to the practical economy of a people who waste little in a ruined land.",
        [5] = "Tirisfal's duskbats are the wings of the gravewood. They are not the greatest horror of the glades, but their constant presence makes the sky itself feel diseased and watchful.",
    },
}

FieldJournal_LoreDB.TIRISFAL_SCARLET = {
    id = "TIRISFAL_SCARLET",
    displayName = "Scarlet Crusade",
    ldr = "LDR-TIRISFAL-4",
    icon = "Interface\\Icons\\INV_BannerPVP_02",
    zones = { "Tirisfal Glades" },

    npcs = {
        1506, -- Scarlet Convert
        1507, -- Scarlet Initiate
        1535, -- Scarlet Warrior
        1536, -- Scarlet Missionary
        1537, -- Scarlet Zealot
        1538, -- Scarlet Friar
        1662, -- Captain Perrine
        1664, -- Captain Vachon
        1665, -- Captain Melrache
        1934, -- Tirisfal Farmer? omit? no
    },

    lore = {
        [1] = "The Scarlet Crusade in Tirisfal Glades consists of fanatical human zealots who view the undead with absolute hatred. To the Forsaken, they are an early and persistent military enemy.",
        [2] = "Scarlet forces operate in camps, towers, and patrol groups, mixing armed fighters with priests and missionaries. I found them more disciplined than bandits and more dangerous because conviction makes them difficult to frighten.",
        [3] = "Tirisfal was once part of Lordaeron, and the Scarlet presence reflects human attempts to reclaim or purify lands lost to plague and undeath. Their outposts stand like angry embers among the ruins.",
        [4] = "The conflict between Forsaken and Scarlet Crusade is ideological as much as territorial. Each side sees the other as an abomination to be removed, leaving little room for mercy in the glades.",
        [5] = "The Scarlet Crusade of Tirisfal is the living kingdom's vengeance curdled into fanaticism. Their camps show that the dead are not the only danger haunting Lordaeron; memory and hatred can march with banners too.",
    },
}

FieldJournal_LoreDB.TIRISFAL_GNOLLS = {
    id = "TIRISFAL_GNOLLS",
    displayName = "Rot Hide Gnolls",
    ldr = "LDR-TIRISFAL-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_04",
    zones = { "Tirisfal Glades" },

    npcs = {
        1674, -- Rot Hide Gnoll
        1675, -- Rot Hide Mongrel
        1676, -- Finbus Geargrind? no
        1941, -- Rot Hide Graverobber
        1942, -- Rot Hide Savage
        1943, -- Raging Rot Hide
        1944, -- Rot Hide Bruiser
    },

    lore = {
        [1] = "Rot Hide gnolls are diseased and violent gnoll clans operating in Tirisfal Glades. Their raids, grave-robbing, and scavenging place them among the region's most unpleasant living threats.",
        [2] = "Their camps are marked by stolen goods, disturbed graves, and the stink of sickness. I found the graverobbers especially foul, since they make profit and shelter from a land already overburdened by death.",
        [3] = "Tirisfal provides the Rot Hide with ruins, farms, and burial grounds to plunder. The same collapse that empowered the undead also leaves room for scavenger clans to multiply.",
        [4] = "For the Forsaken, the Rot Hide are not an existential enemy like the Scarlet Crusade, but they are an insult to order and burial alike. Their presence turns decay into theft.",
        [5] = "The Rot Hide gnolls are Tirisfal's scavenging wound. They thrive in the aftermath of catastrophe, feeding on the bones of a kingdom that has not finished dying.",
    },
}

FieldJournal_LoreDB.TIRISFAL_MURLOCS = {
    id = "TIRISFAL_MURLOCS",
    displayName = "North Coast Murlocs",
    ldr = "LDR-TIRISFAL-6",
    icon = "Interface\\Icons\\INV_Misc_MonsterHead_03",
    zones = { "Tirisfal Glades" },

    npcs = {
        1543, -- Vile Fin Puddlejumper
        1544, -- Vile Fin Minor Oracle
        1545, -- Vile Fin Muckdweller
        1547, -- Decrepit Darkhound? omit
        1548, -- Cursed Darkhound? omit
        1549, -- Ravenous Darkhound? omit
        1917, -- Daniel Ulfman? omit
    },

    lore = {
        [1] = "The murlocs of Tirisfal's northern coast are amphibious humanoids found along cold, debris-strewn shorelines. Their guttural calls carry strangely over the grey water.",
        [2] = "They gather in shoreline groups and answer disturbance quickly. I found that even a lone murloc near the water may be only the nearest voice of a larger cluster.",
        [3] = "The Whispering Shore and North Coast give murlocs access to fish, wreckage, and ruins beyond the easy reach of inland patrols. The coast is bleak, but not empty.",
        [4] = "To the Forsaken, coastal murlocs are a practical nuisance and a reminder that Tirisfal's dangers are not limited to plague and crusade. Even the sea has its own claimants.",
        [5] = "The north-coast murlocs are Tirisfal's cold-water chorus: alien, persistent, and half-hidden in fog and ruin. They widen the field journal's view from graveyards to the grey edge of the world.",
    },
}

-- =========================================================
-- TELDRASSIL: CREATURE LORE
-- Vanilla / Classic content only. Season of Discovery NPCs omitted.
-- =========================================================

FieldJournal_LoreDB.TELDRASSIL_NIGHTSABERS = {
    id = "TELDRASSIL_NIGHTSABERS",
    displayName = "Nightsabers",
    ldr = "LDR-TD-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Teldrassil" },

    npcs = {
        2031,  -- Young Nightsaber
        2032,  -- Mangy Nightsaber
        2042,  -- Nightsaber
        2043,  -- Nightsaber Stalker
        2033,  -- Elder Nightsaber
        2034,  -- Feral Nightsaber
        14430, -- Duskstalker (rare)
    },

    lore = {
        [1] = "Nightsabers are among the most familiar predators of Teldrassil. They range from young cats around Shadowglen to larger hunters deeper among the boughs, all adapted to moving quietly through the forest.",
        [2] = "Their tracks and hunting paths show animals that rely on cover, patience, and sudden speed. Stalkers are especially difficult to notice before they close the distance.",
        [3] = "The kaldorei do not treat nightsabers as unnatural enemies. They are native predators, and even when their numbers must be culled, they remain part of the balance the night elves are trying to preserve.",
        [4] = "Nightsabers are closely woven into kaldorei culture as wild creatures, companions, and mounts. Seeing them in their natural territory makes that relationship feel older than any road or settlement on the tree.",
        [5] = "Duskstalker is an unusually dangerous member of the same family. The nightsabers of Teldrassil show that a healthy wilderness can still have teeth, and respecting nature never means pretending it is harmless.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_THISTLE_BOARS = {
    id = "TELDRASSIL_THISTLE_BOARS",
    displayName = "Thistle Boars",
    ldr = "LDR-TD-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    zones = { "Teldrassil" },

    npcs = {
        1984, -- Young Thistle Boar
        1985, -- Thistle Boar
    },

    lore = {
        [1] = "Thistle boars root through the lower growth of Teldrassil, especially around Shadowglen and the central forest. They are ordinary woodland animals, but their tusks and stubborn charges make them dangerous when pressed.",
        [2] = "Field signs include churned soil, broken brush, and rooted patches where the animals search for food. Their behavior is simple compared with the forest's corrupted creatures, but no less capable of injuring an unwary traveler.",
        [3] = "The boars are one of the first examples of the kaldorei idea of balance. Hunting them is not a war against nature, but an intervention when local populations grow beyond what the grove can comfortably support.",
        [4] = "Thistle boars also provide meat and other useful materials to those living on Teldrassil. They belong to the practical ecology of the tree rather than any larger magical threat.",
        [5] = "The thistle boars are a useful baseline for field study: wild, territorial, and dangerous without being corrupted. Not every threat on Teldrassil needs a darker explanation.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_WEBWOOD_SPIDERS = {
    id = "TELDRASSIL_WEBWOOD_SPIDERS",
    displayName = "Webwood Spiders",
    ldr = "LDR-TD-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    zones = { "Teldrassil" },

    npcs = {
        1986, -- Webwood Spider
        1998, -- Webwood Lurker
        1999, -- Webwood Venomfang
        2000, -- Webwood Silkspinner
        2001, -- Giant Webwood Spider
        1994, -- Githyiss the Vile
        7319, -- Lady Sathrah
    },

    lore = {
        [1] = "Webwood spiders inhabit the caves, hollows, and shaded forest of Teldrassil. Webbing, venom, and patience make them dangerous long before the largest specimens are encountered.",
        [2] = "Different Webwood spiders fill different roles around their nesting grounds. Lurkers hide close to travel routes, venomfangs rely on poison, and silkspinners turn confined passages into traps.",
        [3] = "Githyiss the Vile is a particularly large and corrupted specimen associated with the Webwood nesting grounds near Shadowglen. Her size makes clear how dangerous the colony can become when left undisturbed.",
        [4] = "Lady Sathrah carries a more tragic place in Teldrassil's story. Her presence near the northern waters is tied to Elune's priesthood, grief, and a fate remembered as more than the death of a simple beast.",
        [5] = "The Webwood spiders sit at the boundary between ordinary predator and the wider unease of Teldrassil. Their nests are natural, but some of their greatest members carry signs that the forest's problems run deeper.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_GRELLS_AND_SPRITES = {
    id = "TELDRASSIL_GRELLS_AND_SPRITES",
    displayName = "Grells and Sprites",
    ldr = "LDR-TD-4",
    icon = "Interface\\Icons\\Spell_Shadow_SummonImp",
    zones = { "Teldrassil" },

    npcs = {
        1988,  -- Grell
        1989,  -- Grellkin
        2002,  -- Rascal Sprite
        2003,  -- Shadow Sprite
        2004,  -- Dark Sprite
        2005,  -- Vicious Grell
        14432, -- Threggil (rare)
    },

    lore = {
        [1] = "Grells and sprites gather in several of Teldrassil's wooded pockets. Individually they are small, but their numbers, theft, and sudden hostility can make an otherwise quiet grove unsafe.",
        [2] = "The creatures around Shadowglen are tied to some of the earliest signs that something is wrong with the forest. Stolen moss and unnatural aggression turn minor woodland nuisances into useful evidence.",
        [3] = "Sprites show a range of temperaments and magical coloration, while grells rely more directly on claws, mischief, and numbers. Their similarities make them easy to group in the field even when their behavior differs.",
        [4] = "Their presence near corrupted places suggests that lesser creatures can be affected by the same disturbances troubling larger beings. They are often symptoms before they are causes.",
        [5] = "Threggil is a rare and unusually dangerous grell found on Teldrassil. Such specimens show how even the smallest hostile families can produce individuals worth recording separately.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_GNARLPINE_FURBOLGS = {
    id = "TELDRASSIL_GNARLPINE_FURBOLGS",
    displayName = "Gnarlpine Furbolgs",
    ldr = "LDR-TD-5",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
    zones = { "Teldrassil" },

    npcs = {
        2006,  -- Gnarlpine Ursa
        2007,  -- Gnarlpine Gardener
        2008,  -- Gnarlpine Warrior
        2009,  -- Gnarlpine Shaman
        2010,  -- Gnarlpine Defender
        2011,  -- Gnarlpine Augur
        2012,  -- Gnarlpine Pathfinder
        2013,  -- Gnarlpine Avenger
        2014,  -- Gnarlpine Totemic
        2152,  -- Gnarlpine Ambusher
        11690, -- Gnarlpine Instigator
        7235,  -- Gnarlpine Mystic

        -- Named / notable Gnarlpine
        1993,  -- Greenpaw
        2162,  -- Agal
        7234,  -- Ferocitas the Dream Eater
        2039,  -- Ursal the Mauler
        14428, -- Uruson (rare)
        14429, -- Grimmaw (rare)
    },

    lore = {
        [1] = "The Gnarlpine are furbolgs who once lived more peacefully on Teldrassil but now attack settlements, travelers, and sacred places. Their hostility is one of the clearest signs that something has gone badly wrong beneath the forest's beauty.",
        [2] = "Their presence around Starbreeze Village, Ban'ethil, and the western woods is organized rather than random. Warriors, shamans, defenders, scouts, and totemic leaders show a community turned toward sustained violence.",
        [3] = "The Gnarlpine's madness is connected to the corruption affecting Teldrassil. That makes them tragic as well as dangerous: they are not outsiders invading the tree, but inhabitants whose relationship with it has been twisted.",
        [4] = "Ferocitas the Dream Eater and Ursal the Mauler show how strongly that corruption can concentrate in individuals. Their names are tied to some of the most dangerous Gnarlpine activity in the region.",
        [5] = "Uruson and Grimmaw are rare threats among the tribe, while Greenpaw and Agal appear in the deeper furbolg territories. Together the Gnarlpine make Teldrassil's sickness personal, turning some of the tree's own inhabitants against one another.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_TIMBERLINGS = {
    id = "TELDRASSIL_TIMBERLINGS",
    displayName = "Timberlings",
    ldr = "LDR-TD-6",
    icon = "Interface\\Icons\\Spell_Nature_NatureGuardian",
    zones = { "Teldrassil" },

    npcs = {
        3569, -- Bogling
        2022, -- Timberling
        2025, -- Timberling Bark Ripper
        2027, -- Timberling Trampler
        2029, -- Timberling Mire Beast
        2030, -- Elder Timberling
        2166, -- Oakenscowl
        3535, -- Blackmoss the Fetid (rare)
    },

    lore = {
        [1] = "Timberlings are plantlike beings found around Lake Al'Ameth and the northern waters of Teldrassil. They look like pieces of the forest given motion, which makes their growing hostility particularly unsettling.",
        [2] = "Denalan's studies show why the timberlings matter. Seeds, sprouts, growths, and strange tumors can be examined as evidence of the great tree's condition rather than treated as unrelated monsters.",
        [3] = "Bark rippers, tramplers, mire beasts, elders, and lesser boglings suggest a whole living population rather than one malformed creature repeated across the woods.",
        [4] = "Oakenscowl is an especially dangerous timberling, while Blackmoss the Fetid is a rare specimen whose moss-twined heart becomes part of Denalan's investigation into corruption and recovery.",
        [5] = "The timberlings may be the clearest field measure of Teldrassil itself. When beings so closely tied to plant life become swollen, violent, or diseased, the problem is no longer merely around the forest. It is inside it.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_BLOODFEATHER_HARPIES = {
    id = "TELDRASSIL_BLOODFEATHER_HARPIES",
    displayName = "Bloodfeather Harpies",
    ldr = "LDR-TD-7",
    icon = "Interface\\Icons\\INV_Feather_13",
    zones = { "Teldrassil" },

    npcs = {
        2015,  -- Bloodfeather Harpy
        2017,  -- Bloodfeather Rogue
        2018,  -- Bloodfeather Sorceress
        2019,  -- Bloodfeather Fury
        2020,  -- Bloodfeather Wind Witch
        2021,  -- Bloodfeather Matriarch
        14431, -- Fury Shelda (rare)
    },

    lore = {
        [1] = "Bloodfeather harpies occupy the northern reaches around the Oracle Glade. Their nests and patrols turn sacred woodland into contested ground and keep the Sentinels there under constant pressure.",
        [2] = "The Bloodfeathers are not a single kind of fighter. Rogues move differently from sorceresses, furies, and wind witches, while matriarchs suggest a settled and defended colony.",
        [3] = "Their location matters as much as their numbers. The Oracle Glade and nearby sacred sites are important to the night elves, so every Bloodfeather camp is both a military threat and an intrusion into revered land.",
        [4] = "The harpies fight with claws, speed, and magic, using the open spaces between trees differently from the ground-bound creatures elsewhere on Teldrassil.",
        [5] = "Fury Shelda is a rare and unusually dangerous Bloodfeather. The colony makes northern Teldrassil feel less like empty wilderness and more like territory actively claimed by another people.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_STRIGID_OWLS = {
    id = "TELDRASSIL_STRIGID_OWLS",
    displayName = "Strigid Owls",
    ldr = "LDR-TD-8",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
    zones = { "Teldrassil" },

    npcs = {
        1995, -- Strigid Owl
        1996, -- Strigid Screecher
        1997, -- Strigid Hunter
    },

    lore = {
        [1] = "Strigid owls hunt through Teldrassil's canopy and clearings. They are large enough to threaten a traveler, yet their presence belongs more to ordinary wilderness than corruption.",
        [2] = "Screechers and hunters show how well these birds fill the predatory niches of the forest. Their calls can announce danger, but a descending hunter may still arrive with little warning.",
        [3] = "Their feathers are useful enough to draw the attention of local collectors and tricksters, which is how even ordinary owls become part of life around Dolanaar.",
        [4] = "Unlike the Gnarlpine or diseased timberlings, the Strigid owls need no curse to explain them. They hunt because they are predators, and that distinction is worth preserving.",
        [5] = "The Strigid owls are evidence that much of Teldrassil remains simply wild. Their danger belongs to the normal rhythm of talon, hunger, territory, and prey.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_SATYRS = {
    id = "TELDRASSIL_SATYRS",
    displayName = "Satyrs",
    ldr = "LDR-TD-9",
    icon = "Interface\\Icons\\Spell_Shadow_SummonSatyr",
    zones = { "Teldrassil" },

    npcs = {
        2038, -- Lord Melenas
        6128, -- Vorlus Vilehoof
    },

    lore = {
        [1] = "Satyrs are corrupted demonic beings tied deeply to kaldorei history and fel influence. Their presence on Teldrassil is more alarming than the behavior of ordinary predators because it points toward deliberate corruption.",
        [2] = "Lord Melenas occupies Fel Rock and stands behind some of the darker activity near Dolanaar. His lair links the strange behavior of lesser creatures to a more focused source of fel influence.",
        [3] = "Vorlus Vilehoof is another hostile satyr found on Teldrassil. Even when encountered through specialized druidic work, his presence belongs to the same larger pattern of demonic corruption within night elf lands.",
        [4] = "For the kaldorei, satyrs are not merely monsters. They are reminders of ancient betrayal and of how easily power can turn a defender of the forest into one of its corruptors.",
        [5] = "The satyrs of Teldrassil are few compared with the Gnarlpine or wildlife, but their importance is greater than their numbers. They give the tree's scattered sickness a darker historical context.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_CORRUPTED_DRUIDS = {
    id = "TELDRASSIL_CORRUPTED_DRUIDS",
    displayName = "Corrupted Druids",
    ldr = "LDR-TD-10",
    icon = "Interface\\Icons\\Ability_Druid_Maul",
    zones = { "Teldrassil" },

    npcs = {
        2852, -- Enslaved Druid of the Talon
        7318, -- Rageclaw
    },

    lore = {
        [1] = "Ban'ethil Barrow Den was meant to shelter druids in enchanted sleep, but corruption and Gnarlpine intrusion disturbed that purpose. Some druids within are encountered in hostile or enslaved states.",
        [2] = "The Enslaved Druids of the Talon show how dangerous it is when sacred sleep is interrupted or controlled. Their aggression is not simply the behavior of another forest tribe.",
        [3] = "Rageclaw is tied to the same troubled chambers and demonstrates how druidic power can become a threat when the mind or spirit behind it is no longer free.",
        [4] = "These encounters make Ban'ethil different from an ordinary hostile cave. Fighting there means confronting defenders of the kaldorei tradition who have themselves become victims of the corruption.",
        [5] = "The corrupted druids are among Teldrassil's saddest subjects. They show that the tree's disorder does not stop at animals or furbolgs; even those dedicated to guarding nature can be caught inside it.",
    },
}

FieldJournal_LoreDB.TELDRASSIL_SETHIR = {
    id = "TELDRASSIL_SETHIR",
    displayName = "Sethir and His Minions",
    ldr = "LDR-TD-11",
    icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    zones = { "Teldrassil" },

    npcs = {
        6911, -- Minion of Sethir
        6909, -- Sethir the Ancient
    },

    lore = {
        [1] = "Sethir the Ancient and his minions are hostile figures encountered on Teldrassil outside the ordinary wildlife and tribal conflicts of the zone.",
        [2] = "The minions surrounding Sethir indicate a threat with followers and purpose rather than a solitary wanderer. That organization makes the encounter worth distinguishing from common humanoid hostility.",
        [3] = "Their presence is limited compared with the Gnarlpine or Bloodfeathers, but field work benefits from recording uncommon threats precisely rather than forcing them into a broader family that does not fit.",
        [4] = "Sethir's title marks him as an exceptional individual, and his followers reinforce that the great tree can attract dangers whose origins lie beyond its normal ecology.",
        [5] = "Sethir and his minions are a reminder that Teldrassil's field record cannot be reduced to one corruption or one enemy. Even a sheltered homeland contains isolated threats that deserve their own entry.",
    },
}

-- =========================================================
-- ZEPHRAS ISLE: ENCOUNTER SUBJECTS (BUILD 51)
-- Mob/NPC registration only. Lore is intentionally pending
-- for the dedicated research/writing pass.
-- =========================================================

FieldJournal_LoreDB.ZEPHRAS_VULDREN = {
    id = "ZEPHRAS_VULDREN",
    displayName = "Vuldren",
    ldr = "LDR-ZI-1",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    zones = { "Zephras Isle" },

    npcs = {
        250873, -- Juvenile Vuldren
        250868, -- Vuldren
        250874, -- Vuldren Alpha
        254589, -- Vulgara the Insatiable
        255887, -- Slydris
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_URSERA = {
    id = "ZEPHRAS_URSERA",
    displayName = "Ursera",
    ldr = "LDR-ZI-2",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
    zones = { "Zephras Isle" },

    npcs = {
        250926, -- Scrawny Ursera
        250937, -- Ursera Scavenger
        251115, -- Urs'anah
        250928, -- Highlands Ursera
        250927, -- Shadowgale Ursera
        258443, -- Ur'endra
        259388, -- Mystmane
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_PRIDECLAWS = {
    id = "ZEPHRAS_PRIDECLAWS",
    displayName = "Prideclaws",
    ldr = "LDR-ZI-3",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    zones = { "Zephras Isle" },

    npcs = {
        251245, -- Prideclaw
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_GALESTRIDERS = {
    id = "ZEPHRAS_GALESTRIDERS",
    displayName = "Galestriders",
    ldr = "LDR-ZI-4",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
    zones = { "Zephras Isle" },

    npcs = {
        251661, -- Galestrider
        251707, -- Ornery Galestrider
        256492, -- Fernfeather
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_CLOUDRUNNERS = {
    id = "ZEPHRAS_CLOUDRUNNERS",
    displayName = "Cloudrunners",
    ldr = "LDR-ZI-5",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
    zones = { "Zephras Isle" },

    npcs = {
        271707, -- Juvenile Cloudrunner
        271712, -- Cloudrunner
        271710, -- Cloudrunner Matriarch
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_HIPPOGRYPHS = {
    id = "ZEPHRAS_HIPPOGRYPHS",
    displayName = "Hippogryphs",
    ldr = "LDR-ZI-6",
    icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
    zones = { "Zephras Isle" },

    npcs = {
        251291, -- Hippogryph Youth
        251284, -- Hippogryph Protector
        251261, -- Hippogryph Matriarch
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_CIRRUSFLIES = {
    id = "ZEPHRAS_CIRRUSFLIES",
    displayName = "Cirrusflies",
    ldr = "LDR-ZI-7",
    icon = "Interface\\Icons\\INV_Misc_MonsterScales_03",
    zones = { "Zephras Isle" },

    npcs = {
        251169, -- Pesky Cirrusfly
        251402, -- Cirrusfly Soldier
        251404, -- Cirrusfly Queen
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_SHRIEKLINGS = {
    id = "ZEPHRAS_SHRIEKLINGS",
    displayName = "Shrieklings",
    ldr = "LDR-ZI-8",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
    zones = { "Zephras Isle" },

    npcs = {
        253282, -- Shriekling Fledgling
        253283, -- Shriekling Matriarch
        256092, -- Shadowgale Shriekling
        256108, -- Shadowgale Shrieker
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_WINDSONG_CRAWLERS = {
    id = "ZEPHRAS_WINDSONG_CRAWLERS",
    displayName = "Windsong Crawlers",
    ldr = "LDR-ZI-9",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Crab",
    zones = { "Zephras Isle" },

    npcs = {
        254588, -- Windsong Crawler
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_FLUTTERFLIES = {
    id = "ZEPHRAS_FLUTTERFLIES",
    displayName = "Flutterflies",
    ldr = "LDR-ZI-10",
    icon = "Interface\\Icons\\INV_Misc_Dust_02",
    zones = { "Zephras Isle" },

    npcs = {
        251622, -- Flutterfly
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_SKYHOPPERS = {
    id = "ZEPHRAS_SKYHOPPERS",
    displayName = "Skyhoppers",
    ldr = "LDR-ZI-11",
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
    zones = { "Zephras Isle" },

    npcs = {
        251314, -- Skyhopper
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_BANDITS = {
    id = "ZEPHRAS_BANDITS",
    displayName = "Zephras Bandits",
    ldr = "LDR-ZI-12",
    icon = "Interface\\Icons\\INV_Mask_04",
    zones = { "Zephras Isle" },

    npcs = {
        251918, -- Highlands Bandit
        255534, -- "Badwind" Bennic
        252875, -- Bandit Henchman
        252820, -- Bandit Highwayman
        252863, -- Ferauu the Bludgeon
        252802, -- Hungry Bandit
        274868, -- Gabbel Shattergale
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_ALAKETH = {
    id = "ZEPHRAS_ALAKETH",
    displayName = "Al'Aketh",
    ldr = "LDR-ZI-13",
    icon = "Interface\\Icons\\Spell_Nature_Cyclone",
    zones = { "Zephras Isle" },

    npcs = {
        251451, -- Al'Aketh Ambusher
        254626, -- Al'Aketh Assassin
        270201, -- Al'Aketh Brawler
        251145, -- Al'Aketh Brute
        251160, -- Al'Aketh Convert
        252665, -- Al'Aketh Footsoldier
        252762, -- Al'Aketh Guardian
        254596, -- Al'Aketh Healer
        252767, -- Al'Aketh Honor Guard
        251448, -- Al'Aketh Neophyte
        253511, -- Al'Aketh Pillager
        253195, -- Al'Aketh Preacher
        252764, -- Al'Aketh Skypriest
        252763, -- Al'Aketh Spiritcaller
        252068, -- Al'Aketh Stormcaller
        252664, -- Al'Aketh Stormchaser
        256996, -- Al'Aketh Warrior
        252765, -- Al'Aketh Blademaster
        252077, -- Skypriest Aanders
        256966, -- Skypriest Aanders (West Pylon variant)
        251966, -- Commander Cyclas
        253622, -- Commander Haalien
        268602, -- Skypriest Faladiel
        256935, -- Malduko Cloudcrush
        257196, -- Zaal Stormshield
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_WIND_ELEMENTALS = {
    id = "ZEPHRAS_WIND_ELEMENTALS",
    displayName = "Wind Elementals",
    ldr = "LDR-ZI-14",
    icon = "Interface\\Icons\\Spell_Nature_Cyclone",
    zones = { "Zephras Isle" },

    npcs = {
        251143, -- Roiling Winds
        251662, -- Living Lightning
        251676, -- Wind Hollow
        252481, -- Wind Sprite
        256250, -- Living Storm
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_FOREST_SPRITES = {
    id = "ZEPHRAS_FOREST_SPRITES",
    displayName = "Forest Sprites",
    ldr = "LDR-ZI-15",
    icon = "Interface\\Icons\\Spell_Nature_NatureGuardian",
    zones = { "Zephras Isle" },

    npcs = {
        250921, -- Forest Sprite
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_HIGH_ORDER_COMBATANTS = {
    id = "ZEPHRAS_HIGH_ORDER_COMBATANTS",
    displayName = "High Order Combatants",
    ldr = "LDR-ZI-16",
    icon = "Interface\\Icons\\Spell_Arcane_Arcane01",
    zones = { "Zephras Isle" },

    npcs = {
        257521, -- High Order Apprentice
        256619, -- High Order Mage
        259060, -- High Order Mage (alternate variant)
        273968, -- High Order Messenger
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_WINDSHAPER_COMBATANTS = {
    id = "ZEPHRAS_WINDSHAPER_COMBATANTS",
    displayName = "Windshaper Combatants",
    ldr = "LDR-ZI-17",
    icon = "Interface\\Icons\\Spell_Nature_Cyclone",
    zones = { "Zephras Isle" },

    npcs = {
        257532, -- Windshaper Novice Seer
        276415, -- Windshaper Guardian
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}

FieldJournal_LoreDB.ZEPHRAS_DENDRALASS = {
    id = "ZEPHRAS_DENDRALASS",
    displayName = "Den'dralass",
    ldr = "LDR-ZI-18",
    icon = "Interface\\Icons\\INV_Feather_13",
    zones = { "Zephras Isle" },

    npcs = {
        250936, -- Den'dralass
    },

    -- Lore intentionally deferred to the dedicated Zephras lore pass.
    lore = {
        [1] = "Lore entry pending.",
        [2] = "Lore entry pending.",
        [3] = "Lore entry pending.",
        [4] = "Lore entry pending.",
        [5] = "Lore entry pending.",
    },
}
