--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Skill sources for mop: trainer groups, trainer npcs (zone, side) and per skill sources
-- Format: skills[spellId] = {t = groupId, q = {{questId, giverId, zoneId, side, flags, giverType}}, d = {researchSpellId}, a = true (learned with the profession), u = true (not available)}
-- flags: 1 daily, 2 weekly, 4 repeatable; giverType: nil npc, "o" object, "i" item
local mopSkillSources = {
    groups = {
        [4001] = {1355, 1382, 1430, 1699, 2818, 3026, 3067, 3087, 3399, 3966, 4210, 4552, 4894, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19186, 19369, 26905, 26953, 26972, 26989, 28705, 29631, 33587, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786, 45550, 46709, 47405, 49789, 50567, 54232},
        [4002] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26911, 26961, 26996, 26998, 28400, 28700, 29507, 29508, 29509, 33581, 33635, 33681, 53436, 65121},
        [4003] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 12020, 16161, 16487, 16588, 16642, 16723, 17215, 18802, 19052, 26903, 26951, 26975, 26987, 27023, 27029, 28703, 33588, 33630, 33674, 65186},
        [4004] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 12020, 16161, 16487, 16588, 16642, 16723, 17215, 18802, 19052, 26903, 26951, 26975, 26987, 27023, 27029, 28703, 33588, 33630, 33674},
        [4005] = {996, 1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11052, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684, 43428, 44783, 45559},
        [4006] = {996, 1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11052, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684, 43428, 44783, 45559, 57405},
        [4007] = {1355, 1382, 1430, 1699, 2818, 3026, 3067, 3087, 3399, 4210, 4552, 4894, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18993, 19185, 19186, 19369, 26905, 26953, 26972, 26989, 28705, 29631, 33587, 45550, 46709, 47405, 49789, 50567, 54232},
        [4008] = {1384, 1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 12035, 16663, 16752, 17488, 18747, 18779, 26912, 26962, 26976, 26999, 28698, 33640, 33682, 43431, 46357, 52170, 52642, 53409, 65092, 66360, 66979, 67024},
        [4009] = {1384, 1681, 1701, 2222, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 12035, 16663, 16752, 17488, 18747, 18779, 26912, 26962, 26976, 26999, 28698, 33640, 33682, 43431, 46357, 52170, 52642, 53409},
        [4010] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 4888, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29505, 29506, 29924, 33591, 33631, 33675, 37072, 43429, 44781, 45548, 52640, 55684, 65114, 65129},
        [4011] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 4888, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29505, 29506, 29924, 33591, 33631, 33675, 37072, 43429, 44781, 45548, 52640, 55684},
        [4012] = {2326, 2329, 2798, 3181, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 12939, 16272, 16662, 16731, 17214, 17424, 18990, 18991, 19184, 19478, 22477, 23734, 26956, 26992, 28706, 29233, 33589, 36615, 45540, 49879, 50574, 56796, 66222},
        [4013] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 12020, 16161, 16487, 16588, 16642, 16723, 18802, 19052, 26903, 26951, 26975, 26987, 27023, 27029, 28703, 33588, 33630, 33674},
        [4014] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 4888, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29505, 29506, 29924, 33591, 33631, 33675, 37072, 44781, 45548, 52640, 55684},
        [4015] = {996, 1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11052, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684, 44783, 45559},
        [4016] = {1676, 1702, 3290, 3494, 4941, 5174, 5518, 7406, 7944, 8126, 8736, 8738, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 21493, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 29513, 29514, 33586, 33634, 33677, 45545, 52636, 52651, 55143},
        [4017] = {1676, 1702, 3290, 3494, 4941, 5174, 5518, 8736, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 33586, 33634, 33677, 45545, 52636, 52651},
        [4018] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 26906, 26954, 26980, 26990, 28693, 33583, 33633, 33676, 48685, 53410, 65127},
        [4019] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 26906, 26954, 26980, 26990, 28693, 33583, 33633, 33676, 48685, 53410},
        [4020] = {1676, 1702, 3290, 3494, 4941, 5174, 5518, 8126, 8736, 8738, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 29513, 33586, 33634, 33677, 45545, 52636, 52651},
        [4021] = {1676, 1702, 3290, 3494, 4941, 5174, 5518, 7406, 7944, 8736, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 29514, 33586, 33634, 33677, 45545, 52636, 52651},
        [4022] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26911, 26961, 26996, 26998, 28400, 28700, 29507, 29508, 29509, 33581, 33635, 33681, 53436},
        [4023] = {5388, 15501, 16702, 16744, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680, 44582, 46675, 52586, 52587, 52645, 52657, 65098},
        [4024] = {5388, 15501, 18751, 18774, 19063, 19539, 19775, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680, 44582, 46675, 52586, 52587, 52645, 52657},
        [4025] = {26916, 26959, 26977, 26995, 28702, 30706, 30709, 30710, 30711, 30713, 30715, 30716, 30717, 30721, 30722, 33603, 33638, 33679, 46716, 53415, 56065, 62327, 64691},
        [4026] = {26916, 26959, 26977, 26995, 28702, 30706, 30709, 30710, 30711, 30713, 30715, 30716, 30717, 30721, 30722, 33603, 33638, 33679, 46716, 53415},
        [4027] = {66222},
        [4028] = {5388, 15501, 18751, 18774, 19063, 19539, 19775, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680, 44582, 46675, 52586, 52587, 52645, 52657, 65098},
        [4029] = {65098},
        [4030] = {15501, 18751, 18774, 19063, 19539, 19775, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680, 44582, 46675, 52586, 52587, 52645, 52657, 65098},
        [4031] = {56707, 64231},
        [4032] = {64231},
    },
    npcs = {
        [514] = {12, "A"}, -- Smith Argus
        [996] = {}, -- Eric Dodds the Third
        [1103] = {12, "A"}, -- Eldrin
        [1215] = {12, "A"}, -- Alchemist Mallory
        [1241] = {1, "A"}, -- Tognus Flintfire
        [1317] = {1519, "A"}, -- Lucan Cordell
        [1346] = {1519, "A"}, -- Georgio Bolero
        [1355] = {1, "A"}, -- Cook Ghilm
        [1382] = {33, "H"}, -- Mudduk
        [1384] = {}, -- Z'tark
        [1385] = {33, "H"}, -- Brawn
        [1386] = {8, "H"}, -- Rogvar
        [1430] = {12, "A"}, -- Tomas
        [1470] = {38, "A"}, -- Ghak Healtouch
        [1632] = {12, "A"}, -- Adele Fielder
        [1676] = {10, "A"}, -- Finbus Geargrind
        [1681] = {38, "A"}, -- Brock Stoneseeker
        [1699] = {1, "A"}, -- Gremlock Pilsnor
        [1701] = {1, "A"}, -- Dank Drizzlecut
        [1702] = {1, "A"}, -- Bronk Guzzlegear
        [2132] = {85, "H"}, -- Carolai Anise
        [2222] = {}, -- Undead Mining Trainer
        [2326] = {1, "A"}, -- Thamner Pol
        [2329] = {12, "A"}, -- Michelle Belle
        [2391] = {267, "H"}, -- Serge Hinott
        [2399] = {267, "H"}, -- Daryl Stack
        [2627] = {5287}, -- Grarnik Goodstitch
        [2798] = {1638, "H"}, -- Pand Stonebinder
        [2818] = {45, "H"}, -- Slagg
        [2836] = {5287}, -- Brikk Keencraft
        [2837] = {5287}, -- Jaxin Chong
        [2998] = {1638, "H"}, -- Karn Stonehoof
        [3001] = {1638, "H"}, -- Brek Stonehoof
        [3004] = {1638, "H"}, -- Tepa
        [3007] = {1638, "H"}, -- Una
        [3009] = {1638, "H"}, -- Bena Winterhoof
        [3011] = {1638, "H"}, -- Teg Dawnstrider
        [3026] = {1638, "H"}, -- Aska Mistrunner
        [3067] = {215, "H"}, -- Pyall Silentstride
        [3069] = {215, "H"}, -- Chaw Stronghide
        [3087] = {44, "A"}, -- Crystal Boughman
        [3136] = {10, "A"}, -- Clarise Gnarltree
        [3137] = {10, "A"}, -- Matt Johnson
        [3174] = {14, "H"}, -- Dwukk
        [3175] = {14, "H"}, -- Krunn
        [3181] = {11, "A"}, -- Fremal Doohickey
        [3184] = {14, "H"}, -- Miao'zan
        [3290] = {38, "A"}, -- Deek Fizzlebizz
        [3345] = {1637, "H"}, -- Godan
        [3347] = {1637, "H"}, -- Yelmak
        [3355] = {1637, "H"}, -- Saru Steelfury
        [3357] = {1637, "H"}, -- Makaru
        [3363] = {1637, "H"}, -- Magar
        [3365] = {1637, "H"}, -- Karolek
        [3399] = {1637, "H"}, -- Zamja
        [3478] = {17, "H"}, -- Traugh
        [3484] = {17, "H"}, -- Kil'hala
        [3494] = {17}, -- Tinkerwiz
        [3523] = {85, "H"}, -- Bowen Brisboise
        [3549] = {85, "H"}, -- Shelene Rhobart
        [3555] = {130, "H"}, -- Johan Focht
        [3557] = {130, "H"}, -- Guillaume Sorouy
        [3603] = {141, "A"}, -- Cyndra Kindwhisper
        [3605] = {141, "A"}, -- Nadyia Maneweaver
        [3606] = {141, "A"}, -- Alanna Raveneye
        [3703] = {4709, "H"}, -- Krulmoo Fullmoon
        [3704] = {4709, "H"}, -- Mahani
        [3964] = {331, "A"}, -- Kylanna
        [3966] = {}, -- Kaleem
        [3967] = {331, "A"}, -- Aayndia Floralwind
        [4159] = {1657, "A"}, -- Me'lynn
        [4160] = {1657, "A"}, -- Ainethil
        [4193] = {nil, "A"}, -- Grondal Moonbreeze
        [4210] = {1657, "A"}, -- Alegorn
        [4211] = {1657, "A"}, -- Dannelor
        [4212] = {1657, "A"}, -- Telonis
        [4213] = {1657, "A"}, -- Taladan
        [4254] = {1537, "A"}, -- Geofram Bouldertoe
        [4258] = {1537, "A"}, -- Bengus Deepforge
        [4552] = {1497, "H"}, -- Eunice Burch
        [4576] = {1497, "H"}, -- Josef Gregorian
        [4578] = {1497, "H"}, -- Josephine Lister
        [4588] = {1497, "H"}, -- Arthur Moore
        [4591] = {1497, "H"}, -- Mary Edras
        [4596] = {1497, "H"}, -- James Van Brunt
        [4598] = {1497, "H"}, -- Brom Killian
        [4611] = {1497, "H"}, -- Doctor Herbert Halsey
        [4616] = {1497, "H"}, -- Lavinia Crowe
        [4888] = {15, "A"}, -- Marie Holdston
        [4894] = {15, "A"}, -- Craig Nollward
        [4900] = {15, "A"}, -- Alchemist Narett
        [4941] = {15, "A"}, -- Caz Twosprocket
        [5127] = {1537, "A"}, -- Fimble Finespindle
        [5150] = {1537, "A"}, -- Nissa Firestone
        [5153] = {1537, "A"}, -- Jormund Stonebrow
        [5157] = {1537, "A"}, -- Gimble Thistlefuzz
        [5159] = {1537, "A"}, -- Daryl Riknussun
        [5164] = {1537, "A"}, -- Grumnus Steelshaper
        [5174] = {1537, "A"}, -- Springspindle Fizzlegear
        [5177] = {1537, "A"}, -- Tally Berryfizz
        [5388] = {15, "A"}, -- Ingo Woolybush
        [5392] = {1, "A"}, -- Yarr Hammerstone
        [5482] = {1519, "A"}, -- Stephen Ryback
        [5499] = {1519, "A"}, -- Lilyssia Nightbreeze
        [5511] = {1519, "A"}, -- Therum Deepforge
        [5513] = {1519, "A"}, -- Gelman Stonehand
        [5518] = {1519, "A"}, -- Lilliam Sparkspindle
        [5564] = {1519, "A"}, -- Simon Tanner
        [5695] = {85, "H"}, -- Vance Undergloom
        [5759] = {85, "H"}, -- Nurse Neela
        [5784] = {nil, "H"}, -- Waldor
        [5939] = {215, "H"}, -- Vira Younghoof
        [5943] = {14, "H"}, -- Rawrk
        [6094] = {141, "A"}, -- Byancie
        [6286] = {141, "A"}, -- Zarrin
        [6297] = {nil, "A"}, -- Kurdram Stonehammer
        [6299] = {nil, "A"}, -- Delfrum Flintbeard
        [7230] = {1637, "H"}, -- Shayis Steelfury
        [7231] = {1637, "H"}, -- Kelgruk Bloodaxe
        [7232] = {1519, "A"}, -- Borgus Steelhand
        [7406] = {5287}, -- Oglethorpe Obnoticus
        [7866] = {nil, "A"}, -- Peter Galen
        [7867] = {nil, "H"}, -- Thorkaf Dragoneye
        [7868] = {nil, "A"}, -- Sarah Tanner
        [7869] = {45, "H"}, -- Brumn Winterhoof
        [7870] = {nil, "A"}, -- Caryssia Moonhunter
        [7871] = {5339, "H"}, -- Se'Jib
        [7944] = {1537, "A"}, -- Tinkmaster Overspark
        [7948] = {357, "A"}, -- Kylanna Windwhisper
        [7949] = {357, "A"}, -- Xylinnia Starshine
        [8126] = {440}, -- Nixx Sprocketspring
        [8128] = {440}, -- Pikkle
        [8153] = {405, "H"}, -- Narv Hidecrafter
        [8306] = {17, "H"}, -- Duhng
        [8736] = {440}, -- Buzzek Bracketswing
        [8738] = {17}, -- Vazario Linkgrease
        [9584] = {1519, "A"}, -- Jalane Ayrole
        [10993] = {215}, -- Twizwick Sprocketgrind
        [11017] = {1637, "H"}, -- Roxxik
        [11025] = {14, "H"}, -- Mukdrak
        [11031] = {1497, "H"}, -- Franklin Lloyd
        [11037] = {148, "A"}, -- Jenna Lemkenilli
        [11052] = {15, "A"}, -- Timothy Worthington
        [11072] = {12, "A"}, -- Kitta Firewind
        [11073] = {1337}, -- Annora
        [11074] = {406, "H"}, -- Hgarth
        [11097] = {47, "A"}, -- Drakk Stonehand
        [11098] = {357, "H"}, -- Hahrana Ironhide
        [11146] = {1537, "A"}, -- Ironus Coldsteel
        [11177] = {1637, "H"}, -- Okothos Ironrager
        [11178] = {1637, "H"}, -- Borgosh Corebender
        [12020] = {}, -- Moonglade Alchemy Trainer
        [12035] = {}, -- Aerie Peak Mining Trainer
        [12939] = {15, "A"}, -- Doctor Gustaf VanHowzen
        [15400] = {3430, "H"}, -- Arathel Sunforge
        [15501] = {3430, "H"}, -- Aleinia
        [16160] = {3430, "H"}, -- Magistrix Eredania
        [16161] = {3430, "H"}, -- Arcanist Sheynathren
        [16190] = {}, -- Expansion Enchanting Trainer
        [16253] = {3433, "H"}, -- Master Chef Mouldier
        [16265] = {}, -- Smith Daelarin
        [16272] = {3430, "H"}, -- Kanaria
        [16277] = {3430, "H"}, -- Quarelestra
        [16278] = {3430, "H"}, -- Sathein
        [16366] = {3430, "H"}, -- Sempstress Ambershine
        [16487] = {}, -- Master Alchemist
        [16583] = {3483, "H"}, -- Rohok
        [16588] = {3483, "H"}, -- Apothecary Antonivich
        [16633] = {3487, "H"}, -- Sedana
        [16640] = {3487, "H"}, -- Keelen Sheets
        [16642] = {3487, "H"}, -- Camberon
        [16662] = {3487, "H"}, -- Alestus
        [16663] = {3487, "H"}, -- Belil
        [16667] = {3487, "H"}, -- Danwe
        [16669] = {3487, "H"}, -- Bemarrin
        [16676] = {3487, "H"}, -- Sylann
        [16688] = {3487, "H"}, -- Lynalis
        [16702] = {}, -- Telia
        [16719] = {3557, "A"}, -- Mumman
        [16723] = {3557, "A"}, -- Lucc
        [16724] = {3557, "A"}, -- Miall
        [16725] = {3557, "A"}, -- Nahogg
        [16726] = {3557, "A"}, -- Ockil
        [16728] = {3557, "A"}, -- Akham
        [16729] = {3557, "A"}, -- Refik
        [16731] = {3557, "A"}, -- Nus
        [16744] = {nil, "A"}, -- Driaan
        [16752] = {3557, "A"}, -- Muaat
        [16823] = {3483, "A"}, -- Humphry
        [17214] = {3524, "A"}, -- Anchorite Fateema
        [17215] = {3524, "A"}, -- Daedal
        [17222] = {3524, "A"}, -- Artificer Daelo
        [17245] = {3524, "A"}, -- Blacksmith Calypso
        [17246] = {3524, "A"}, -- "Cookie" McWeaksauce
        [17424] = {3525, "A"}, -- Anchorite Paetheus
        [17442] = {3524, "A"}, -- Moordo
        [17487] = {3524, "A"}, -- Erin Kelly
        [17488] = {3524, "A"}, -- Dulvi
        [17634] = {3521, "A"}, -- K. Lee Smallfry
        [17637] = {3521, "H"}, -- Mack Diver
        [18747] = {3483, "H"}, -- Krugosh
        [18749] = {3483, "H"}, -- Dalinna
        [18751] = {3483, "H"}, -- Kalaen
        [18752] = {3483, "H"}, -- Zebig
        [18753] = {3483, "H"}, -- Felannia
        [18754] = {3483, "H"}, -- Barim Spilthoof
        [18771] = {3483, "A"}, -- Brumman
        [18772] = {3483, "A"}, -- Hama
        [18773] = {3483, "A"}, -- Johan Barnes
        [18774] = {3483, "A"}, -- Tatiana
        [18775] = {3483, "A"}, -- Lebowski
        [18779] = {3483, "A"}, -- Hurnak Grimmord
        [18802] = {3483, "A"}, -- Alchemist Gribble
        [18987] = {3483, "A"}, -- Gaston
        [18988] = {3483, "H"}, -- Baxter
        [18990] = {3483, "A"}, -- Burko
        [18991] = {3483, "H"}, -- Aresella
        [18993] = {3521}, -- Naka
        [19052] = {3703}, -- Lorokeem
        [19063] = {3703}, -- Hamanar
        [19184] = {3703}, -- Mildred Fletcher
        [19185] = {3703}, -- Jack Trapper
        [19186] = {3703}, -- Kylene
        [19187] = {3703}, -- Darmari
        [19251] = {3703}, -- Enchantress Volali
        [19252] = {3703}, -- High Enchanter Bardolan
        [19341] = {3520, "H"}, -- Grutah
        [19369] = {3520, "A"}, -- Celie Steelwing
        [19478] = {3522, "H"}, -- Fera Palerunner
        [19539] = {3523}, -- Jazdalaad
        [19540] = {3523}, -- Asarnan
        [19576] = {3523}, -- Xyrol
        [19774] = {3487, "H"}, -- Toban
        [19775] = {3487, "H"}, -- Kalinda
        [19777] = {nil, "A"}, -- Elaando
        [19778] = {3557, "A"}, -- Farii
        [20124] = {3703}, -- Kradu Grimblade
        [20125] = {3703}, -- Zula Slagfury
        [21087] = {3522, "H"}, -- Grikka
        [21209] = {3483, "A"}, -- Dumphry
        [21493] = {3523}, -- Kablamm Farflinger
        [22477] = {3519}, -- Anchorite Ensham
        [23734] = {495, "A"}, -- Anchorite Yazmina
        [24868] = {3520}, -- Niobe Whizzlespark
        [25099] = {3520, "H"}, -- Jonathan Garrett
        [25277] = {3537, "H"}, -- Chief Engineer Leveny
        [26564] = {65, "H"}, -- Borus Ironbender
        [26903] = {495, "A"}, -- Lanolis Dewdrop
        [26904] = {495, "A"}, -- Rosina Rivet
        [26905] = {495, "A"}, -- Brom Brewbaster
        [26906] = {495, "A"}, -- Elizabeth Jackson
        [26907] = {495, "A"}, -- Tisha Longbridge
        [26911] = {495, "A"}, -- Bernadette Dexter
        [26912] = {495, "A"}, -- Grumbol Stoutpick
        [26914] = {495, "A"}, -- Benjamin Clegg
        [26915] = {495, "A"}, -- Ounhulo
        [26916] = {495, "A"}, -- Mindri Dinkles
        [26951] = {495, "H"}, -- Wilhelmina Renel
        [26952] = {495, "H"}, -- Kristen Smythe
        [26953] = {495, "H"}, -- Thomas Kolichio
        [26954] = {495, "H"}, -- Emil Autumn
        [26955] = {495, "H"}, -- Jamesina Watterly
        [26956] = {495, "H"}, -- Sally Tompkins
        [26959] = {495, "H"}, -- Booker Kells
        [26960] = {495, "H"}, -- Carter Tiffens
        [26961] = {495, "H"}, -- Gunter Hansen
        [26962] = {495, "H"}, -- Jonathan Lewis
        [26964] = {495, "H"}, -- Alexandra McQueen
        [26969] = {3537, "H"}, -- Raenah
        [26972] = {3537, "H"}, -- Orn Tenderhoof
        [26975] = {3537, "H"}, -- Arthur Henslowe
        [26976] = {3537, "H"}, -- Brunna Ironaxe
        [26977] = {3537, "H"}, -- Adelene Sunlance
        [26980] = {3537, "H"}, -- Eorain Dawnstrike
        [26981] = {3537, "H"}, -- Crog Steelspine
        [26982] = {3537, "H"}, -- Geba'li
        [26987] = {3537, "A"}, -- Falorn Nightwhisper
        [26988] = {3537, "A"}, -- Argo Strongstout
        [26989] = {3537, "A"}, -- Rollick MacKreel
        [26990] = {3537, "A"}, -- Alexis Marlowe
        [26991] = {3537, "A"}, -- Sock Brightbolt
        [26992] = {3537, "A"}, -- Brynna Wilson
        [26995] = {3537, "A"}, -- Tink Brightbolt
        [26996] = {3537}, -- Awan Iceborn
        [26997] = {3537, "A"}, -- Alestos
        [26998] = {3537, "A"}, -- Rosemary Bovard
        [26999] = {3537, "A"}, -- Fendrig Redbeard
        [27001] = {3537, "A"}, -- Darin Goodstitch
        [27023] = {65, "H"}, -- Apothecary Bressa
        [27029] = {65, "H"}, -- Apothecary Wormwick
        [27034] = {65, "H"}, -- Josric Fame
        [28400] = {}, -- Northrend Leatherworking Trainer
        [28693] = {4395}, -- Enchanter Nalthanis
        [28694] = {4395}, -- Alard Schmied
        [28697] = {4395}, -- Timofey Oshenko
        [28698] = {4395}, -- Jedidiah Handers
        [28699] = {4395}, -- Charles Worth
        [28700] = {4395}, -- Diane Cannings
        [28701] = {4395}, -- Timothy Jones
        [28702] = {4395}, -- Professor Pallin
        [28703] = {4395}, -- Linzy Blackbolt
        [28705] = {4395, "A"}, -- Katherine Lee
        [28706] = {4395}, -- Olisarra the Kind
        [29233] = {3537, "H"}, -- Nurse Applewood
        [29505] = {4395}, -- Imindril Spearsong
        [29506] = {4395}, -- Orland Schaeffer
        [29507] = {4395}, -- Manfred Staller
        [29508] = {4395}, -- Andellion
        [29509] = {4395}, -- Namha Moonwater
        [29513] = {4395}, -- Didi the Wrench
        [29514] = {4395}, -- Findle Whistlesteam
        [29631] = {4395, "H"}, -- Awilo Lon'gomba
        [29924] = {67, "A"}, -- Brandig
        [30706] = {1637, "H"}, -- Jo'mah
        [30709] = {1638, "H"}, -- Poshken Hardbinder
        [30710] = {3487, "H"}, -- Zantasia
        [30711] = {1497, "H"}, -- Margaux Parchley
        [30713] = {1519, "A"}, -- Catarina Stanford
        [30715] = {1657, "A"}, -- Feyden Darkin
        [30716] = {3557, "A"}, -- Thoth
        [30717] = {1537, "A"}, -- Elise Brightletter
        [30721] = {3483, "A"}, -- Michael Schwan
        [30722] = {3483, "H"}, -- Neferatti
        [33580] = {210}, -- Dustin Vail
        [33581] = {210}, -- Kul'de
        [33583] = {210}, -- Fael Morningsong
        [33586] = {210}, -- Binkie Brightgear
        [33587] = {210}, -- Bethany Cromwell
        [33588] = {210}, -- Crystal Brightspark
        [33589] = {210}, -- Joseph Wilson
        [33590] = {210}, -- Oluros
        [33591] = {210}, -- Rekka the Hammer
        [33603] = {210}, -- Arthur Denny
        [33630] = {3703}, -- Aelthin
        [33631] = {3703}, -- Barien
        [33633] = {3703}, -- Enchantress Andiala
        [33634] = {3703}, -- Engineer Sinbei
        [33635] = {3703}, -- Daenril
        [33636] = {3703}, -- Miralisse
        [33637] = {3703}, -- Kirembri Silvermane
        [33638] = {3703}, -- Scribe Lanloer
        [33640] = {3703}, -- Hanlir
        [33674] = {3703}, -- Alchemist Kanhu
        [33675] = {3703}, -- Onodo
        [33676] = {3703}, -- Zurii
        [33677] = {3703}, -- Technician Mihila
        [33679] = {3703}, -- Recorder Lidio
        [33680] = {3703}, -- Nemiha
        [33681] = {3703}, -- Korim
        [33682] = {3703}, -- Fono
        [33684] = {3703}, -- Weaver Aoa
        [34708] = {1, "A"}, -- Caitrin Ironkettle
        [34710] = {12, "A"}, -- Ellen Moore
        [34711] = {1657, "A"}, -- Mary Allerton
        [34712] = {85, "H"}, -- Roberta Carter
        [34713] = {14, "H"}, -- Ondani Greatmill
        [34714] = {1638, "H"}, -- Mahara Goldwheat
        [34785] = {3557, "A"}, -- Alnar Whitebough
        [34786] = {3430, "H"}, -- Alice Rigsdale
        [36615] = {4720, "H"}, -- Doc Zapnozzle
        [37072] = {1637, "H"}, -- Rogg
        [43428] = {148, "A"}, -- Faeyrin Willowmoon
        [43429] = {148, "A"}, -- Taryel Firestrike
        [43431] = {148, "A"}, -- Periale
        [44582] = {1519, "A"}, -- Theresa Denman
        [44781] = {1637, "H"}, -- Opuno Ironhorn
        [44783] = {1637, "H"}, -- Hiwahi Three-Feathers
        [45540] = {1637, "H"}, -- Krenk Choplimb
        [45545] = {1637, "H"}, -- "Jack" Pisarek Slamfix
        [45548] = {1637, "H"}, -- Kark Helmbreaker
        [45550] = {1637, "H"}, -- Zarbo Porkpatty
        [45559] = {1637, "H"}, -- Nivi Weavewell
        [46357] = {1637, "H"}, -- Gonto
        [46675] = {1637, "H"}, -- Lugrah
        [46709] = {1637, "H"}, -- Arugi
        [46716] = {1637, "H"}, -- Nerog
        [47405] = {85, "H"}, -- The Chef
        [48685] = {}, -- Cataclysm Shard Vendor
        [49789] = {3483, "H"}, -- Allison
        [49879] = {16, "H"}, -- Doc Zapnozzle
        [50567] = {4714, "A"}, -- Fielding Chesterhill
        [50574] = {4714, "A"}, -- Amelia Atherton
        [52170] = {1637, "H"}, -- Gizzik Oregrab
        [52586] = {1537, "A"}, -- Hanner Gembold
        [52587] = {1497, "H"}, -- Neller Fayne
        [52636] = {1657, "A"}, -- Tana Lentner
        [52640] = {1657, "A"}, -- Rolf Karner
        [52642] = {1657, "A"}, -- Foreman Pernic
        [52645] = {1657, "A"}, -- Aessa Silverdew
        [52651] = {1638, "H"}, -- Engineer Palehoof
        [52657] = {1638, "H"}, -- Nahari Cloudchaser
        [53409] = {15, "A"}, -- "Kobold" Kerik
        [53410] = {15, "A"}, -- Lissah Spellwick
        [53415] = {15, "A"}, -- Theoden Manners
        [53436] = {15, "A"}, -- Eustace Tanwell
        [54232] = {5287}, -- Mrs. Gant
        [55143] = {5805}, -- Sally Fizzlefury
        [55684] = {1519, "A"}, -- Jordan Smith
        [56065] = {5785}, -- Inkmaster Wei
        [56707] = {5785}, -- Chin
        [56796] = {1519, "A"}, -- Angela Leifeld
        [57405] = {5805}, -- Silkmaster Tsai
        [62327] = {5785}, -- Scribe Rinji
        [64231] = {5805}, -- Sungshin Ironpaw
        [64691] = {5840}, -- Lorewalker Huynh
        [65092] = {5785}, -- Smeltmaster Ashpaw
        [65098] = {5785}, -- Mai the Jade Shaper
        [65114] = {5785}, -- Len the Hammer
        [65121] = {5841}, -- Clean Pelt
        [65127] = {5785}, -- Lai the Spellpaw
        [65129] = {5840}, -- Zen Master Lao
        [65186] = {6138}, -- Poisoncrafter Kil'zit
        [66222] = {5785, "H"}, -- Elder Muur
        [66360] = {5841}, -- Master Brandom
        [66979] = {5785, "H"}, -- Stonebreaker Ruian
        [67024] = {5785, "A"}, -- Rockseeker Guo
    },
    skills = {
        [818] = {t = 4001, a = true}, -- Cooking Fire
        [2149] = {t = 4002, a = true}, -- Handstitched Leather Boots
        [2152] = {t = 4002, a = true}, -- Light Armor Kit
        [2329] = {t = 4003, a = true}, -- Elixir of Lion's Strength
        [2330] = {t = 4003, a = true}, -- Minor Healing Potion
        [2331] = {t = 4004}, -- Minor Mana Potion
        [2332] = {t = 4004}, -- Minor Rejuvenation Potion
        [2333] = {t = 4003}, -- Elixir of Lesser Agility
        [2334] = {t = 4004}, -- Elixir of Minor Fortitude
        [2337] = {t = 4004}, -- Lesser Healing Potion
        [2385] = {t = 4005}, -- Brown Linen Vest
        [2386] = {t = 4005}, -- Linen Boots
        [2387] = {t = 4006, a = true}, -- Linen Cloak
        [2392] = {t = 4005}, -- Red Linen Shirt
        [2393] = {t = 4005}, -- White Linen Shirt
        [2394] = {t = 4005}, -- Blue Linen Shirt
        [2395] = {t = 4005}, -- Barbaric Linen Vest
        [2396] = {t = 4005}, -- Green Linen Shirt
        [2397] = {t = 4005}, -- Reinforced Linen Cape
        [2399] = {t = 4005}, -- Green Woolen Vest
        [2401] = {t = 4005}, -- Woolen Boots
        [2402] = {t = 4005}, -- Woolen Cape
        [2406] = {t = 4005}, -- Gray Woolen Shirt
        [2538] = {t = 4001, a = true}, -- Charred Wolf Meat
        [2539] = {t = 4007}, -- Spiced Wolf Meat
        [2540] = {t = 4001, a = true}, -- Roasted Boar Meat
        [2541] = {t = 4007}, -- Coyote Steak
        [2544] = {t = 4007}, -- Crab Cake
        [2546] = {t = 4007}, -- Dry Pork Ribs
        [2657] = {t = 4008, a = true}, -- Smelt Copper
        [2658] = {t = 4009}, -- Smelt Silver
        [2659] = {t = 4009}, -- Smelt Bronze
        [2660] = {t = 4010, a = true}, -- Rough Sharpening Stone
        [2661] = {t = 4011}, -- Copper Chain Belt
        [2662] = {t = 4011}, -- Copper Chain Pants
        [2663] = {t = 4010, a = true}, -- Copper Bracers
        [2664] = {t = 4011}, -- Runed Copper Bracers
        [2665] = {t = 4011}, -- Coarse Sharpening Stone
        [2666] = {t = 4011}, -- Runed Copper Belt
        [2668] = {t = 4011}, -- Rough Bronze Leggings
        [2670] = {t = 4011}, -- Rough Bronze Cuirass
        [2672] = {t = 4011}, -- Patterned Bronze Bracers
        [2674] = {t = 4011}, -- Heavy Sharpening Stone
        [2675] = {t = 4011}, -- Shining Silver Breastplate
        [2737] = {t = 4011}, -- Copper Mace
        [2738] = {t = 4011}, -- Copper Axe
        [2739] = {t = 4011}, -- Copper Shortsword
        [2740] = {t = 4011}, -- Bronze Mace
        [2741] = {t = 4011}, -- Bronze Axe
        [2742] = {t = 4011}, -- Bronze Shortsword
        [2881] = {t = 4002, a = true}, -- Light Leather
        [2963] = {t = 4006, a = true}, -- Bolt of Linen Cloth
        [2964] = {t = 4005}, -- Bolt of Woolen Cloth
        [3115] = {t = 4010, a = true}, -- Rough Weightstone
        [3116] = {t = 4011}, -- Coarse Weightstone
        [3117] = {t = 4011}, -- Heavy Weightstone
        [3170] = {t = 4004}, -- Weak Troll's Blood Elixir
        [3171] = {t = 4004}, -- Elixir of Wisdom
        [3172] = {t = 4003}, -- Minor Magic Resistance Potion
        [3173] = {t = 4004}, -- Lesser Mana Potion
        [3175] = {t = 4003}, -- Limited Invulnerability Potion
        [3176] = {t = 4004}, -- Strong Troll's Blood Elixir
        [3177] = {t = 4004}, -- Elixir of Defense
        [3275] = {t = 4006, a = true}, -- Linen Bandage
        [3276] = {t = 4012, a = true}, -- Heavy Linen Bandage
        [3277] = {t = 4012, a = true}, -- Wool Bandage
        [3278] = {t = 4012, a = true}, -- Heavy Wool Bandage
        [3292] = {t = 4011}, -- Heavy Copper Broadsword
        [3293] = {t = 4011}, -- Copper Battle Axe
        [3294] = {t = 4011}, -- Thick War Axe
        [3296] = {t = 4011}, -- Heavy Bronze Mace
        [3304] = {t = 4009}, -- Smelt Tin
        [3307] = {t = 4009}, -- Smelt Iron
        [3308] = {t = 4009}, -- Smelt Gold
        [3319] = {t = 4011}, -- Copper Chain Boots
        [3320] = {t = 4011}, -- Rough Grinding Stone
        [3323] = {t = 4011}, -- Runed Copper Gauntlets
        [3324] = {t = 4011}, -- Runed Copper Pants
        [3326] = {t = 4011}, -- Coarse Grinding Stone
        [3328] = {t = 4011}, -- Rough Bronze Shoulders
        [3331] = {t = 4011}, -- Silvered Bronze Boots
        [3333] = {t = 4011}, -- Silvered Bronze Gauntlets
        [3337] = {t = 4011}, -- Heavy Grinding Stone
        [3399] = {t = 4007}, -- Tasty Lion Steak
        [3400] = {t = 4007}, -- Soothing Turtle Bisque
        [3447] = {t = 4004}, -- Healing Potion
        [3448] = {t = 4013}, -- Lesser Invisibility Potion
        [3449] = {t = 4013}, -- Shadow Oil
        [3450] = {t = 4013}, -- Elixir of Fortitude
        [3452] = {t = 4013}, -- Mana Potion
        [3491] = {t = 4011}, -- Big Bronze Knife
        [3501] = {t = 4014}, -- Green Iron Bracers
        [3502] = {t = 4014}, -- Green Iron Helm
        [3506] = {t = 4014}, -- Green Iron Leggings
        [3508] = {t = 4014}, -- Green Iron Hauberk
        [3569] = {t = 4009}, -- Smelt Steel
        [3755] = {t = 4005}, -- Linen Bag
        [3757] = {t = 4005}, -- Woolen Bag
        [3813] = {t = 4005}, -- Small Silk Pack
        [3839] = {t = 4005}, -- Bolt of Silk Cloth
        [3840] = {t = 4005}, -- Heavy Linen Gloves
        [3841] = {t = 4005}, -- Green Linen Bracers
        [3842] = {t = 4005}, -- Handstitched Linen Britches
        [3843] = {t = 4005}, -- Heavy Woolen Gloves
        [3845] = {t = 4005}, -- Soft-soled Linen Boots
        [3848] = {t = 4005}, -- Double-stitched Woolen Shoulders
        [3850] = {t = 4005}, -- Heavy Woolen Pants
        [3852] = {t = 4005}, -- Gloves of Meditation
        [3855] = {t = 4005}, -- Spidersilk Boots
        [3859] = {t = 4005}, -- Azure Silk Vest
        [3861] = {t = 4015}, -- Long Silken Cloak
        [3865] = {t = 4015}, -- Bolt of Mageweave
        [3866] = {t = 4005}, -- Stylish Red Shirt
        [3871] = {t = 4015}, -- Formal White Shirt
        [3914] = {t = 4005}, -- Brown Linen Pants
        [3915] = {t = 4006, a = true}, -- Brown Linen Shirt
        [3918] = {t = 4016, a = true}, -- Rough Blasting Powder
        [3919] = {t = 4016, a = true}, -- Rough Dynamite
        [3920] = {t = 4016, a = true}, -- Crafted Light Shot
        [3922] = {t = 4017}, -- Handful of Copper Bolts
        [3923] = {t = 4017}, -- Rough Copper Bomb
        [3924] = {t = 4016}, -- Copper Tube
        [3925] = {t = 4017}, -- Rough Boomstick
        [3926] = {t = 4016}, -- Copper Modulator
        [3929] = {t = 4017}, -- Coarse Blasting Powder
        [3930] = {t = 4016}, -- Crafted Heavy Shot
        [3931] = {t = 4017}, -- Coarse Dynamite
        [3932] = {t = 4017}, -- Target Dummy
        [3934] = {t = 4017}, -- Flying Tiger Goggles
        [3936] = {t = 4017}, -- Deadly Blunderbuss
        [3937] = {t = 4017}, -- Large Copper Bomb
        [3938] = {t = 4017}, -- Bronze Tube
        [3939] = {t = 4017}, -- Lovingly Crafted Boomstick
        [3941] = {t = 4017}, -- Small Bronze Bomb
        [3942] = {t = 4017}, -- Whirring Bronze Gizmo
        [3945] = {t = 4017}, -- Heavy Blasting Powder
        [3946] = {t = 4017}, -- Heavy Dynamite
        [3947] = {t = 4016}, -- Crafted Solid Shot
        [3949] = {t = 4017}, -- Silver-plated Shotgun
        [3950] = {t = 4017}, -- Big Bronze Bomb
        [3953] = {t = 4017}, -- Bronze Framework
        [3955] = {t = 4017}, -- Explosive Sheep
        [3956] = {t = 4017}, -- Green Tinted Goggles
        [3958] = {t = 4017}, -- Iron Strut
        [3961] = {t = 4017}, -- Gyrochronatom
        [3962] = {t = 4017}, -- Iron Grenade
        [3963] = {t = 4017}, -- Compact Harvest Reaper Kit
        [3965] = {t = 4017}, -- Advanced Target Dummy
        [3967] = {t = 4017}, -- Big Iron Bomb
        [3973] = {t = 4017}, -- Silver Contact
        [3977] = {t = 4017}, -- Crude Scope
        [3978] = {t = 4017}, -- Standard Scope
        [4094] = {t = 4007}, -- Barbecued Buzzard Wing
        [6412] = {t = 4007}, -- Kaldorei Spider Kabob
        [6415] = {t = 4007}, -- Fillet of Frenzy
        [6458] = {t = 4017}, -- Ornate Spyglass
        [6499] = {t = 4007}, -- Boiled Clams
        [6500] = {t = 4007}, -- Goblin Deviled Clams
        [6517] = {t = 4011}, -- Pearl-handled Dagger
        [6521] = {t = 4005}, -- Pearl-clasped Cloak
        [6619] = {t = 4003}, -- Cowardly Flight Potion
        [6690] = {t = 4005}, -- Lesser Wizard's Robe
        [7126] = {t = 4002, a = true}, -- Handstitched Leather Vest
        [7179] = {t = 4004}, -- Elixir of Water Breathing
        [7181] = {t = 4013}, -- Greater Healing Potion
        [7183] = {t = 4003, a = true}, -- Elixir of Minor Defense
        [7223] = {t = 4014}, -- Golden Scale Bracers
        [7408] = {t = 4011}, -- Heavy Copper Maul
        [7418] = {t = 4018, a = true}, -- Enchant Bracer - Minor Health
        [7420] = {t = 4019}, -- Enchant Chest - Minor Health
        [7421] = {t = 4018, a = true}, -- Runed Copper Rod
        [7426] = {t = 4019}, -- Enchant Chest - Minor Absorption
        [7428] = {t = 4018, a = true}, -- Enchant Bracer - Minor Dodge
        [7430] = {t = 4017}, -- Arclight Spanner
        [7457] = {t = 4019}, -- Enchant Bracer - Minor Stamina
        [7623] = {t = 4005}, -- Brown Linen Robe
        [7624] = {t = 4005}, -- White Linen Robe
        [7745] = {t = 4019}, -- Enchant 2H Weapon - Minor Impact
        [7748] = {t = 4019}, -- Enchant Chest - Lesser Health
        [7771] = {t = 4019}, -- Enchant Cloak - Minor Protection
        [7779] = {t = 4019}, -- Enchant Bracer - Minor Agility
        [7788] = {t = 4019}, -- Enchant Weapon - Minor Striking
        [7817] = {t = 4011}, -- Rough Bronze Boots
        [7818] = {t = 4010}, -- Silver Rod
        [7836] = {t = 4004}, -- Blackmouth Oil
        [7837] = {t = 4004}, -- Fire Oil
        [7841] = {t = 4004}, -- Swim Speed Potion
        [7845] = {t = 4004}, -- Elixir of Firepower
        [7857] = {t = 4019}, -- Enchant Chest - Health
        [7863] = {t = 4019}, -- Enchant Boots - Minor Stamina
        [7928] = {t = 4012, a = true}, -- Silk Bandage
        [7929] = {t = 4012, a = true}, -- Heavy Silk Bandage
        [7934] = {t = 4012, a = true}, -- Anti-Venom
        [8334] = {t = 4017}, -- Clockwork Box
        [8465] = {t = 4005}, -- Simple Dress
        [8467] = {t = 4005}, -- White Woolen Dress
        [8483] = {t = 4015}, -- White Swashbuckler's Shirt
        [8489] = {t = 4015}, -- Red Swashbuckler's Shirt
        [8604] = {t = 4001, a = true}, -- Herb Baked Egg
        [8758] = {t = 4005}, -- Azure Silk Pants
        [8760] = {t = 4005}, -- Azure Silk Hood
        [8762] = {t = 4015}, -- Silk Headband
        [8764] = {t = 4015}, -- Earthen Vest
        [8766] = {t = 4015}, -- Azure Silk Belt
        [8768] = {t = 4011}, -- Iron Buckle
        [8770] = {t = 4015}, -- Robe of Power
        [8772] = {t = 4015}, -- Crimson Silk Belt
        [8774] = {t = 4015}, -- Green Silken Shoulders
        [8776] = {t = 4005}, -- Linen Belt
        [8791] = {t = 4015}, -- Crimson Silk Vest
        [8799] = {t = 4015}, -- Crimson Silk Pantaloons
        [8804] = {t = 4015}, -- Crimson Silk Gloves
        [8880] = {t = 4011}, -- Copper Dagger
        [8895] = {t = 4020}, -- Goblin Rocket Boots
        [9058] = {t = 4002, a = true}, -- Handstitched Leather Cloak
        [9059] = {t = 4002, a = true}, -- Handstitched Leather Bracers
        [9060] = {t = 4002}, -- Light Leather Quiver
        [9062] = {t = 4002}, -- Small Leather Ammo Pouch
        [9193] = {t = 4002}, -- Heavy Quiver
        [9194] = {t = 4002}, -- Heavy Leather Ammo Pouch
        [9271] = {t = 4017}, -- Aquadynamic Fish Attractor
        [9916] = {t = 4014}, -- Steel Breastplate
        [9918] = {t = 4014}, -- Solid Sharpening Stone
        [9920] = {t = 4014}, -- Solid Grinding Stone
        [9921] = {t = 4014}, -- Solid Weightstone
        [9926] = {t = 4014}, -- Heavy Mithril Shoulder
        [9928] = {t = 4014}, -- Heavy Mithril Gauntlet
        [9931] = {t = 4014}, -- Mithril Scale Pants
        [9935] = {t = 4014}, -- Steel Plate Helm
        [9954] = {t = 4010}, -- Truesilver Gauntlets
        [9959] = {t = 4014}, -- Heavy Mithril Breastplate
        [9961] = {t = 4014}, -- Mithril Coif
        [9968] = {t = 4014}, -- Heavy Mithril Boots
        [9974] = {t = 4010}, -- Truesilver Breastplate
        [9983] = {t = 4011}, -- Copper Claymore
        [9985] = {t = 4011}, -- Bronze Warhammer
        [9986] = {t = 4011}, -- Bronze Greatsword
        [9987] = {t = 4011}, -- Bronze Battle Axe
        [9993] = {t = 4014}, -- Heavy Mithril Axe
        [10001] = {t = 4014}, -- Big Black Mace
        [10003] = {t = 4010}, -- The Shatterer
        [10011] = {t = 4010}, -- Blight
        [10015] = {t = 4010}, -- Truesilver Champion
        [10097] = {t = 4009}, -- Smelt Mithril
        [10098] = {t = 4009}, -- Smelt Truesilver
        [10619] = {t = 4002}, -- Dragonscale Gauntlets
        [10621] = {t = 4002}, -- Wolfshead Helm
        [10840] = {t = 4012, a = true}, -- Mageweave Bandage
        [10841] = {t = 4012, a = true}, -- Heavy Mageweave Bandage
        [11447] = {t = 4003}, -- Elixir of Waterwalking
        [11448] = {t = 4013}, -- Greater Mana Potion
        [11449] = {t = 4013}, -- Elixir of Agility
        [11450] = {t = 4013}, -- Elixir of Greater Defense
        [11451] = {t = 4013}, -- Oil of Immolation
        [11452] = {q = {{2203}, {2501}}}, -- Restorative Potion
        [11453] = {t = 4003}, -- Magic Resistance Potion
        [11457] = {t = 4013}, -- Superior Healing Potion
        [11460] = {t = 4013}, -- Elixir of Detect Undead
        [11461] = {t = 4013}, -- Arcane Elixir
        [11465] = {t = 4013}, -- Elixir of Greater Intellect
        [11467] = {t = 4013}, -- Elixir of Greater Agility
        [11478] = {t = 4013}, -- Elixir of Detect Demon
        [12044] = {t = 4006, a = true}, -- Simple Linen Pants
        [12045] = {t = 4005}, -- Simple Linen Boots
        [12046] = {t = 4005}, -- Simple Kilt
        [12048] = {t = 4015}, -- Black Mageweave Vest
        [12049] = {t = 4015}, -- Black Mageweave Leggings
        [12050] = {t = 4015}, -- Black Mageweave Robe
        [12052] = {t = 4015}, -- Shadoweave Pants
        [12053] = {t = 4015}, -- Black Mageweave Gloves
        [12055] = {t = 4015}, -- Shadoweave Robe
        [12061] = {t = 4015}, -- Orange Mageweave Shirt
        [12065] = {t = 4015}, -- Mageweave Bag
        [12067] = {t = 4015}, -- Dreamweave Gloves
        [12069] = {t = 4015}, -- Cindercloth Robe
        [12070] = {t = 4015}, -- Dreamweave Vest
        [12071] = {t = 4015}, -- Shadoweave Gloves
        [12072] = {t = 4015}, -- Black Mageweave Headband
        [12073] = {t = 4015}, -- Black Mageweave Boots
        [12074] = {t = 4015}, -- Black Mageweave Shoulders
        [12076] = {t = 4015}, -- Shadoweave Shoulders
        [12077] = {t = 4015}, -- Simple Black Dress
        [12079] = {t = 4015}, -- Red Mageweave Bag
        [12082] = {t = 4015}, -- Shadoweave Boots
        [12088] = {t = 4015}, -- Cindercloth Boots
        [12092] = {t = 4015}, -- Dreamweave Circlet
        [12260] = {t = 4010, a = true}, -- Rough Copper Vest
        [12584] = {t = 4017}, -- Gold Power Core
        [12585] = {t = 4017}, -- Solid Blasting Powder
        [12586] = {t = 4017}, -- Solid Dynamite
        [12589] = {t = 4017}, -- Mithril Tube
        [12590] = {t = 4017}, -- Gyromatic Micro-Adjustor
        [12591] = {t = 4017}, -- Unstable Trigger
        [12594] = {t = 4017}, -- Fire Goggles
        [12595] = {t = 4017}, -- Mithril Blunderbuss
        [12596] = {t = 4016}, -- Hi-Impact Mithril Slugs
        [12599] = {t = 4017}, -- Mithril Casing
        [12603] = {t = 4017}, -- Mithril Frag Bomb
        [12609] = {t = 4013}, -- Catseye Elixir
        [12615] = {t = 4017}, -- Spellpower Goggles Xtreme
        [12617] = {t = 4017}, -- Deepdive Helmet
        [12618] = {t = 4017}, -- Rose Colored Goggles
        [12619] = {t = 4017}, -- Hi-Explosive Bomb
        [12621] = {t = 4016}, -- Mithril Gyro-Shot
        [12622] = {t = 4017}, -- Green Lens
        [12715] = {t = 4020}, -- Goblin Rocket Fuel Recipe
        [12716] = {t = 4020}, -- Goblin Mortar
        [12717] = {t = 4020}, -- Goblin Mining Helmet
        [12718] = {t = 4020}, -- Goblin Construction Helmet
        [12719] = {t = 4016}, -- Explosive Arrow
        [12720] = {t = 4016}, -- Goblin "Boom" Box
        [12722] = {t = 4016}, -- Goblin Radio
        [12754] = {t = 4020}, -- The Big One
        [12755] = {t = 4020}, -- Goblin Bomb Dispenser
        [12758] = {t = 4020}, -- Goblin Rocket Helmet
        [12759] = {t = 4021}, -- Gnomish Death Ray
        [12760] = {t = 4020}, -- Goblin Sapper Charge
        [12895] = {t = 4021}, -- Inlaid Mithril Cylinder Plans
        [12897] = {t = 4021}, -- Gnomish Goggles
        [12899] = {t = 4021}, -- Gnomish Shrink Ray
        [12900] = {t = 4016}, -- Mobile Alarm
        [12902] = {t = 4021}, -- Gnomish Net-o-Matic Projector
        [12903] = {t = 4021}, -- Gnomish Harm Prevention Belt
        [12904] = {t = 4016}, -- Gnomish Ham Radio
        [12905] = {t = 4021}, -- Gnomish Rocket Boots
        [12906] = {t = 4021}, -- Gnomish Battle Chicken
        [12907] = {t = 4021}, -- Gnomish Mind Control Cap
        [12908] = {t = 4020}, -- Goblin Dragon Gun
        [13240] = {t = 4016}, -- The Mortar: Reloaded
        [13378] = {t = 4019}, -- Enchant Shield - Minor Stamina
        [13421] = {t = 4019}, -- Enchant Cloak - Lesser Protection
        [13485] = {t = 4019}, -- Enchant Shield - Lesser Spirit
        [13501] = {t = 4019}, -- Enchant Bracer - Lesser Stamina
        [13503] = {t = 4019}, -- Enchant Weapon - Lesser Striking
        [13529] = {t = 4019}, -- Enchant 2H Weapon - Lesser Impact
        [13538] = {t = 4019}, -- Enchant Chest - Lesser Absorption
        [13607] = {t = 4019}, -- Enchant Chest - Mana
        [13622] = {t = 4019}, -- Enchant Bracer - Lesser Intellect
        [13626] = {t = 4019}, -- Enchant Chest - Minor Stats
        [13631] = {t = 4019}, -- Enchant Shield - Lesser Stamina
        [13635] = {t = 4019}, -- Enchant Cloak - Defense
        [13637] = {t = 4019}, -- Enchant Boots - Lesser Agility
        [13640] = {t = 4019}, -- Enchant Chest - Greater Health
        [13642] = {t = 4019}, -- Enchant Bracer - Spirit
        [13644] = {t = 4019}, -- Enchant Boots - Lesser Stamina
        [13646] = {t = 4019}, -- Enchant Bracer - Lesser Dodge
        [13648] = {t = 4019}, -- Enchant Bracer - Stamina
        [13659] = {t = 4019}, -- Enchant Shield - Spirit
        [13661] = {t = 4019}, -- Enchant Bracer - Strength
        [13663] = {t = 4019}, -- Enchant Chest - Greater Mana
        [13693] = {t = 4019}, -- Enchant Weapon - Striking
        [13695] = {t = 4019}, -- Enchant 2H Weapon - Impact
        [13700] = {t = 4019}, -- Enchant Chest - Lesser Stats
        [13746] = {t = 4019}, -- Enchant Cloak - Greater Defense
        [13815] = {t = 4019}, -- Enchant Gloves - Agility
        [13822] = {t = 4019}, -- Enchant Bracer - Intellect
        [13836] = {t = 4019}, -- Enchant Boots - Stamina
        [13858] = {t = 4019}, -- Enchant Chest - Superior Health
        [13887] = {t = 4019}, -- Enchant Gloves - Strength
        [13890] = {t = 4019}, -- Enchant Boots - Minor Speed
        [13905] = {t = 4019}, -- Enchant Shield - Greater Spirit
        [13917] = {t = 4019}, -- Enchant Chest - Superior Mana
        [13935] = {t = 4019}, -- Enchant Boots - Agility
        [13937] = {t = 4019}, -- Enchant 2H Weapon - Greater Impact
        [13939] = {t = 4019}, -- Enchant Bracer - Greater Strength
        [13941] = {t = 4019}, -- Enchant Chest - Stats
        [13943] = {t = 4019}, -- Enchant Weapon - Greater Striking
        [13948] = {t = 4019}, -- Enchant Gloves - Minor Haste
        [14293] = {t = 4019}, -- Lesser Magic Wand
        [14379] = {t = 4010}, -- Golden Rod
        [14380] = {t = 4010}, -- Truesilver Rod
        [14807] = {t = 4019}, -- Greater Magic Wand
        [14809] = {t = 4019}, -- Lesser Mystic Wand
        [14810] = {t = 4019}, -- Greater Mystic Wand
        [14891] = {t = 4008}, -- Smelt Dark Iron
        [14930] = {t = 4002}, -- Quickdraw Quiver
        [14932] = {t = 4002}, -- Thick Leather Ammo Pouch
        [15255] = {t = 4017}, -- Mechanical Repair Kit
        [15833] = {t = 4013}, -- Dreamless Sleep Potion
        [15972] = {t = 4014}, -- Glinting Steel Dagger
        [16153] = {t = 4009}, -- Smelt Thorium
        [16639] = {t = 4014}, -- Dense Grinding Stone
        [16640] = {t = 4014}, -- Dense Weightstone
        [16641] = {t = 4014}, -- Dense Sharpening Stone
        [16642] = {t = 4014}, -- Thorium Armor
        [16643] = {t = 4014}, -- Thorium Belt
        [16644] = {t = 4014}, -- Thorium Bracers
        [16646] = {t = 4014}, -- Imperial Plate Shoulders
        [16647] = {t = 4014}, -- Imperial Plate Belt
        [16649] = {t = 4014}, -- Imperial Plate Bracers
        [16652] = {t = 4014}, -- Thorium Boots
        [16653] = {t = 4014}, -- Thorium Helm
        [16657] = {t = 4014}, -- Imperial Plate Boots
        [16658] = {t = 4014}, -- Imperial Plate Helm
        [16662] = {t = 4014}, -- Thorium Leggings
        [16663] = {t = 4014}, -- Imperial Plate Chest
        [16730] = {t = 4014}, -- Imperial Plate Leggings
        [16969] = {t = 4014}, -- Ornate Thorium Handaxe
        [16971] = {t = 4014}, -- Huge Thorium Battleaxe
        [17180] = {t = 4019}, -- Enchanted Thorium Bar
        [17181] = {t = 4019}, -- Enchanted Leather
        [17551] = {t = 4013}, -- Stonescale Oil
        [17552] = {t = 4013}, -- Mighty Rage Potion
        [17553] = {t = 4013}, -- Superior Mana Potion
        [17555] = {t = 4013}, -- Elixir of the Sages
        [17556] = {t = 4013}, -- Major Healing Potion
        [17557] = {t = 4013}, -- Elixir of Brute Force
        [17572] = {t = 4013}, -- Purification Potion
        [17573] = {t = 4013}, -- Greater Arcane Elixir
        [17638] = {t = 4003}, -- Flask of Chromatic Resistance
        [18238] = {t = 4007}, -- Spotted Yellowtail
        [18240] = {t = 4007}, -- Grilled Squid
        [18243] = {t = 4007}, -- Nightfin Soup
        [18244] = {t = 4007}, -- Poached Sunscale Salmon
        [18401] = {t = 4015}, -- Bolt of Runecloth
        [18402] = {t = 4015}, -- Runecloth Belt
        [18403] = {t = 4015}, -- Frostweave Tunic
        [18406] = {t = 4015}, -- Runecloth Robe
        [18407] = {t = 4015}, -- Runecloth Tunic
        [18409] = {t = 4015}, -- Runecloth Cloak
        [18410] = {t = 4015}, -- Ghostweave Belt
        [18411] = {t = 4015}, -- Frostweave Gloves
        [18413] = {t = 4015}, -- Ghostweave Gloves
        [18414] = {t = 4015}, -- Brightcloth Robe
        [18415] = {t = 4015}, -- Brightcloth Gloves
        [18416] = {t = 4015}, -- Ghostweave Vest
        [18417] = {t = 4015}, -- Runecloth Gloves
        [18420] = {t = 4015}, -- Brightcloth Cloak
        [18421] = {t = 4015}, -- Wizardweave Leggings
        [18423] = {t = 4015}, -- Runecloth Boots
        [18424] = {t = 4015}, -- Frostweave Pants
        [18437] = {t = 4015}, -- Felcloth Boots
        [18438] = {t = 4015}, -- Runecloth Pants
        [18441] = {t = 4015}, -- Ghostweave Pants
        [18442] = {t = 4015}, -- Felcloth Hood
        [18444] = {t = 4015}, -- Runecloth Headband
        [18446] = {t = 4015}, -- Wizardweave Robe
        [18449] = {t = 4015}, -- Runecloth Shoulders
        [18450] = {t = 4015}, -- Wizardweave Turban
        [18451] = {t = 4015}, -- Felcloth Robe
        [18453] = {t = 4015}, -- Felcloth Shoulders
        [18629] = {t = 4012, a = true}, -- Runecloth Bandage
        [18630] = {t = 4012, a = true}, -- Heavy Runecloth Bandage
        [19052] = {t = 4022}, -- Wicked Leather Bracers
        [19055] = {t = 4022}, -- Runic Leather Gauntlets
        [19065] = {t = 4022}, -- Runic Leather Bracers
        [19071] = {t = 4022}, -- Wicked Leather Headband
        [19072] = {t = 4022}, -- Runic Leather Belt
        [19082] = {t = 4022}, -- Runic Leather Headband
        [19083] = {t = 4022}, -- Wicked Leather Pants
        [19091] = {t = 4022}, -- Runic Leather Pants
        [19092] = {t = 4022}, -- Wicked Leather Belt
        [19098] = {t = 4022}, -- Wicked Leather Armor
        [19102] = {t = 4022}, -- Runic Leather Armor
        [19103] = {t = 4022}, -- Runic Leather Shoulders
        [19567] = {t = 4017}, -- Salt Shaker
        [19666] = {t = 4011}, -- Silver Skeleton Key
        [19667] = {t = 4011}, -- Golden Skeleton Key
        [19668] = {t = 4014}, -- Truesilver Skeleton Key
        [19669] = {t = 4014}, -- Arcanite Skeleton Key
        [19788] = {t = 4017}, -- Dense Blasting Powder
        [19790] = {t = 4017}, -- Thorium Grenade
        [19791] = {t = 4017}, -- Thorium Widget
        [19792] = {t = 4017}, -- Thorium Rifle
        [19794] = {t = 4017}, -- Spellpower Goggles Xtreme Plus
        [19795] = {t = 4017}, -- Thorium Tube
        [19800] = {t = 4016}, -- Thorium Shells
        [19825] = {t = 4017}, -- Master Engineer's Goggles
        [20008] = {t = 4019}, -- Enchant Bracer - Greater Intellect
        [20012] = {t = 4019}, -- Enchant Gloves - Greater Agility
        [20013] = {t = 4019}, -- Enchant Gloves - Greater Strength
        [20016] = {t = 4019}, -- Enchant Shield - Vitality
        [20023] = {t = 4019}, -- Enchant Boots - Greater Agility
        [20028] = {t = 4019}, -- Enchant Chest - Major Mana
        [20201] = {t = 4010}, -- Arcanite Rod
        [21175] = {t = 4007}, -- Spider Sausage
        [22430] = {t = 4003}, -- Refined Scale of Onyxia
        [22808] = {t = 4013}, -- Elixir of Greater Water Breathing
        [23070] = {t = 4017}, -- Dense Dynamite
        [23071] = {t = 4017}, -- Truesilver Transformer
        [24266] = {t = 4003}, -- Gurubashi Mojo Madness
        [24654] = {t = 4022}, -- Blue Dragonscale Leggings
        [24655] = {t = 4022}, -- Green Dragonscale Gauntlets
        [25081] = {t = 4018}, -- Enchant Cloak - Greater Fire Resistance
        [25082] = {t = 4018}, -- Enchant Cloak - Greater Nature Resistance
        [25255] = {t = 4023, a = true}, -- Delicate Copper Wire
        [25278] = {t = 4024}, -- Bronze Setting
        [25280] = {t = 4024}, -- Elegant Silver Ring
        [25283] = {t = 4024}, -- Inlaid Malachite Ring
        [25284] = {t = 4024}, -- Simple Pearl Ring
        [25287] = {t = 4024}, -- Gloom Band
        [25305] = {t = 4024}, -- Heavy Silver Ring
        [25317] = {t = 4024}, -- Ring of Silver Might
        [25318] = {t = 4024}, -- Ring of Twilight Shadows
        [25321] = {t = 4024}, -- Moonsoul Crown
        [25490] = {t = 4024}, -- Solid Bronze Ring
        [25493] = {t = 4023, a = true}, -- Braided Copper Ring
        [25498] = {t = 4024}, -- Barbaric Iron Collar
        [25610] = {t = 4024}, -- Pendant of the Agate Shield
        [25612] = {t = 4024}, -- Heavy Iron Knuckles
        [25613] = {t = 4024}, -- Golden Dragon Ring
        [25615] = {t = 4024}, -- Mithril Filigree
        [25617] = {t = 4024}, -- Blazing Citrine Ring
        [25620] = {t = 4024}, -- Engraved Truesilver Ring
        [25621] = {t = 4024}, -- Citrine Ring of Rapid Healing
        [26011] = {q = {{8798, 10305, 618}}}, -- Tranquil Mechanical Yeti
        [26745] = {t = 4015}, -- Bolt of Netherweave
        [26746] = {t = 4015}, -- Netherweave Bag
        [26764] = {t = 4015}, -- Netherweave Bracers
        [26765] = {t = 4015}, -- Netherweave Belt
        [26770] = {t = 4015}, -- Netherweave Gloves
        [26771] = {t = 4015}, -- Netherweave Pants
        [26772] = {t = 4015}, -- Netherweave Boots
        [26872] = {t = 4024}, -- Figurine - Jade Owl
        [26874] = {t = 4024}, -- Aquamarine Signet
        [26876] = {t = 4024}, -- Aquamarine Pendant of the Warrior
        [26880] = {t = 4024}, -- Thorium Setting
        [26883] = {t = 4024}, -- Ruby Pendant of Fire
        [26885] = {t = 4024}, -- Truesilver Healing Ring
        [26902] = {t = 4024}, -- Simple Opal Ring
        [26903] = {t = 4024}, -- Sapphire Signet
        [26907] = {t = 4024}, -- Onslaught Ring
        [26908] = {t = 4024}, -- Sapphire Pendant of Winter Night
        [26911] = {t = 4024}, -- Living Emerald Pendant
        [26916] = {t = 4024}, -- Band of Natural Fire
        [26925] = {t = 4023, a = true}, -- Woven Copper Ring
        [26926] = {t = 4024}, -- Heavy Copper Ring
        [26927] = {t = 4024}, -- Thick Bronze Necklace
        [26928] = {t = 4024}, -- Ornate Tigerseye Necklace
        [27032] = {t = 4012}, -- Netherweave Bandage
        [27033] = {t = 4012}, -- Heavy Netherweave Bandage
        [27899] = {t = 4019}, -- Enchant Bracer - Brawn
        [27905] = {t = 4019}, -- Enchant Bracer - Stats
        [27944] = {t = 4019}, -- Enchant Shield - Lesser Dodge
        [27947] = {t = 4018}, -- Enchant Shield - Resistance
        [27957] = {t = 4019}, -- Enchant Chest - Exceptional Health
        [27958] = {t = 4019}, -- Enchant Chest - Exceptional Mana
        [27961] = {t = 4019}, -- Enchant Cloak - Major Armor
        [27962] = {t = 4018}, -- Enchant Cloak - Major Resistance
        [28027] = {t = 4019}, -- Prismatic Sphere
        [28028] = {t = 4019}, -- Void Sphere
        [28544] = {t = 4013}, -- Elixir of Major Strength
        [28545] = {t = 4013}, -- Elixir of Healing Power
        [28551] = {t = 4013}, -- Super Healing Potion
        [28905] = {t = 4024}, -- Bold Blood Garnet
        [28906] = {t = 4023}, -- Brilliant Blood Garnet
        [28907] = {t = 4023}, -- Delicate Blood Garnet
        [28910] = {t = 4024}, -- Inscribed Flame Spessarite
        [28914] = {t = 4024}, -- Glinting Shadow Draenite
        [28916] = {t = 4024}, -- Radiant Deep Peridot
        [28917] = {t = 4024}, -- Jagged Deep Peridot
        [28924] = {t = 4023}, -- Purified Shadow Draenite
        [28925] = {t = 4024}, -- Timeless Shadow Draenite
        [28936] = {t = 4024}, -- Sovereign Shadow Draenite
        [28938] = {t = 4023}, -- Brilliant Blood Garnet
        [28948] = {t = 4024}, -- Rigid Azure Moonstone
        [28950] = {t = 4024}, -- Solid Azure Moonstone
        [28953] = {t = 4024}, -- Sparkling Azure Moonstone
        [28957] = {t = 4023}, -- Sparkling Azure Moonstone
        [29356] = {t = 4009}, -- Smelt Fel Iron
        [29358] = {t = 4009}, -- Smelt Adamantite
        [29359] = {t = 4009}, -- Smelt Eternium
        [29360] = {t = 4009}, -- Smelt Felsteel
        [29361] = {t = 4009}, -- Smelt Khorium
        [29545] = {t = 4014}, -- Fel Iron Plate Gloves
        [29547] = {t = 4014}, -- Fel Iron Plate Belt
        [29548] = {t = 4014}, -- Fel Iron Plate Boots
        [29549] = {t = 4014}, -- Fel Iron Plate Pants
        [29550] = {t = 4014}, -- Fel Iron Breastplate
        [29551] = {t = 4014}, -- Fel Iron Chain Coif
        [29552] = {t = 4014}, -- Fel Iron Chain Gloves
        [29553] = {t = 4014}, -- Fel Iron Chain Bracers
        [29556] = {t = 4014}, -- Fel Iron Chain Tunic
        [29557] = {t = 4014}, -- Fel Iron Hatchet
        [29558] = {t = 4014}, -- Fel Iron Hammer
        [29565] = {t = 4014}, -- Fel Iron Greatsword
        [29654] = {t = 4014}, -- Fel Sharpening Stone
        [29686] = {t = 4009}, -- Smelt Hardened Adamantite
        [30047] = {t = 4001}, -- Crystal Throat Lozenge
        [30303] = {t = 4017}, -- Elemental Blasting Powder
        [30304] = {t = 4017}, -- Fel Iron Casing
        [30305] = {t = 4017}, -- Handful of Fel Iron Bolts
        [30306] = {t = 4017}, -- Adamantite Frame
        [30307] = {t = 4017}, -- Hardened Adamantite Tube
        [30308] = {t = 4017}, -- Khorium Power Core
        [30309] = {t = 4017}, -- Felsteel Stabilizer
        [30310] = {t = 4017}, -- Fel Iron Bomb
        [30311] = {t = 4017}, -- Adamantite Grenade
        [30312] = {t = 4017}, -- Fel Iron Musket
        [30346] = {t = 4016}, -- Fel Iron Shells
        [30347] = {t = 4016}, -- Adamantite Shell Machine
        [30558] = {t = 4020}, -- The Bigger One
        [30560] = {t = 4020}, -- Super Sapper Charge
        [30561] = {t = 4016}, -- Goblin Tonk Controller
        [30563] = {t = 4020}, -- Goblin Rocket Launcher
        [30565] = {t = 4020}, -- Foreman's Enchanted Helmet
        [30566] = {t = 4020}, -- Foreman's Reinforced Helmet
        [30568] = {t = 4021}, -- Gnomish Flame Turret
        [30569] = {t = 4021}, -- Gnomish Poultryizer
        [30570] = {t = 4021}, -- Nigh-Invulnerability Belt
        [30573] = {t = 4016}, -- Gnomish Tonk Controller
        [30574] = {t = 4021}, -- Gnomish Power Goggles
        [30575] = {t = 4021}, -- Gnomish Battle Goggles
        [31048] = {t = 4024}, -- Fel Iron Blood Ring
        [31049] = {t = 4024}, -- Golden Draenite Ring
        [31050] = {t = 4024}, -- Azure Moonstone Ring
        [31051] = {t = 4024}, -- Thick Adamantite Necklace
        [31052] = {t = 4024}, -- Heavy Adamantite Ring
        [31087] = {t = 4023}, -- Brilliant Living Ruby
        [31089] = {t = 4023}, -- Delicate Living Ruby
        [31094] = {t = 4023}, -- Sparkling Star of Elune
        [31096] = {t = 4023}, -- Brilliant Living Ruby
        [31099] = {t = 4023}, -- Smooth Dawnstone
        [31100] = {t = 4023}, -- Subtle Dawnstone
        [31105] = {t = 4023}, -- Purified Nightseye
        [31110] = {t = 4023}, -- Regal Talasite
        [31460] = {t = 4015}, -- Netherweave Net
        [32178] = {t = 4024}, -- Malachite Pendant
        [32179] = {t = 4024}, -- Tigerseye Band
        [32259] = {t = 4023, a = true}, -- Rough Stone Statue
        [32284] = {t = 4014}, -- Lesser Rune of Warding
        [32455] = {t = 4022}, -- Heavy Knothide Leather
        [32655] = {t = 4010}, -- Fel Iron Rod
        [32656] = {t = 4010}, -- Adamantite Rod
        [32657] = {t = 4010}, -- Eternium Rod
        [32801] = {t = 4024}, -- Coarse Stone Statue
        [32807] = {t = 4024}, -- Heavy Stone Statue
        [32808] = {t = 4024}, -- Solid Stone Statue
        [32809] = {t = 4024}, -- Dense Stone Statue
        [33285] = {t = 4001}, -- Sporeling Snack
        [33732] = {t = 4013}, -- Volatile Healing Potion
        [33733] = {t = 4013}, -- Unstable Mana Potion
        [33738] = {t = 4013}, -- Onslaught Elixir
        [33740] = {t = 4013}, -- Adept's Elixir
        [33741] = {t = 4013}, -- Elixir of Mastery
        [33990] = {t = 4019}, -- Enchant Chest - Major Spirit
        [33991] = {t = 4019}, -- Enchant Chest - Restore Mana Prime
        [33993] = {t = 4019}, -- Enchant Gloves - Blasting
        [33995] = {t = 4019}, -- Enchant Gloves - Major Strength
        [33996] = {t = 4019}, -- Enchant Gloves - Assault
        [34001] = {t = 4019}, -- Enchant Bracer - Major Intellect
        [34002] = {t = 4019}, -- Enchant Bracer - Lesser Assault
        [34004] = {t = 4019}, -- Enchant Cloak - Greater Agility
        [34005] = {t = 4018}, -- Enchant Cloak - Greater Arcane Resistance
        [34006] = {t = 4018}, -- Enchant Cloak - Greater Shadow Resistance
        [34069] = {t = 4023}, -- Smooth Golden Draenite
        [34529] = {t = 4010}, -- Nether Chain Shirt
        [34530] = {t = 4010}, -- Twisting Nether Chain Shirt
        [34533] = {t = 4010}, -- Breastplate of Kings
        [34534] = {t = 4010}, -- Bulwark of Kings
        [34535] = {t = 4010}, -- Fireguard
        [34537] = {t = 4010}, -- Blazeguard
        [34538] = {t = 4010}, -- Lionheart Blade
        [34540] = {t = 4010}, -- Lionheart Champion
        [34541] = {t = 4010}, -- The Planar Edge
        [34542] = {t = 4010}, -- Black Planar Edge
        [34543] = {t = 4010}, -- Lunar Crescent
        [34544] = {t = 4010}, -- Mooncleaver
        [34545] = {t = 4010}, -- Drakefist Hammer
        [34546] = {t = 4010}, -- Dragonmaw
        [34547] = {t = 4010}, -- Thunder
        [34548] = {t = 4010}, -- Deep Thunder
        [34590] = {t = 4024}, -- Delicate Blood Garnet
        [34607] = {t = 4014}, -- Fel Weightstone
        [34955] = {t = 4024}, -- Golden Ring of Power
        [34959] = {t = 4024}, -- Truesilver Commander's Ring
        [34960] = {t = 4024}, -- Glowing Thorium Band
        [34961] = {t = 4024}, -- Emerald Lion Ring
        [34979] = {t = 4010}, -- Thick Bronze Darts
        [34981] = {t = 4010}, -- Whirling Steel Axes
        [34982] = {t = 4010}, -- Enchanted Thorium Blades
        [34983] = {t = 4010}, -- Felsteel Whisper Knives
        [35520] = {t = 4002}, -- Shadow Armor Kit
        [35521] = {t = 4002}, -- Flame Armor Kit
        [35522] = {t = 4002}, -- Frost Armor Kit
        [35523] = {t = 4002}, -- Nature Armor Kit
        [35524] = {t = 4002}, -- Arcane Armor Kit
        [35750] = {t = 4009}, -- Earth Shatter
        [35751] = {t = 4009}, -- Fire Sunder
        [36074] = {t = 4022}, -- Blackstorm Leggings
        [36075] = {t = 4022}, -- Wildfeather Leggings
        [36076] = {t = 4022}, -- Dragonstrike Leggings
        [36077] = {t = 4022}, -- Primalstorm Breastplate
        [36078] = {t = 4022}, -- Living Crystal Breastplate
        [36079] = {t = 4022}, -- Golden Dragonstrike Breastplate
        [36122] = {t = 4010}, -- Earthforged Leggings
        [36124] = {t = 4010}, -- Windforged Leggings
        [36125] = {t = 4010}, -- Light Earthforged Blade
        [36126] = {t = 4010}, -- Light Skyforged Axe
        [36128] = {t = 4010}, -- Light Emberforged Hammer
        [36129] = {t = 4010}, -- Heavy Earthforged Breastplate
        [36130] = {t = 4010}, -- Stormforged Hauberk
        [36131] = {t = 4010}, -- Windforged Rapier
        [36133] = {t = 4010}, -- Stoneforged Claymore
        [36134] = {t = 4010}, -- Stormforged Axe
        [36135] = {t = 4010}, -- Skyforged Great Axe
        [36136] = {t = 4010}, -- Lavaforged Warhammer
        [36137] = {t = 4010}, -- Great Earthforged Hammer
        [36256] = {t = 4010}, -- Embrace of the Twisting Nether
        [36257] = {t = 4010}, -- Bulwark of the Ancient Kings
        [36258] = {t = 4010}, -- Blazefury
        [36259] = {t = 4010}, -- Lionheart Executioner
        [36260] = {t = 4010}, -- Wicked Edge of the Planes
        [36261] = {t = 4010}, -- Bloodmoon
        [36262] = {t = 4010}, -- Dragonstrike
        [36263] = {t = 4010}, -- Stormherald
        [36523] = {t = 4024}, -- Brilliant Necklace
        [36524] = {t = 4024}, -- Heavy Jade Ring
        [36525] = {t = 4024}, -- Red Ring of Destruction
        [36526] = {t = 4024}, -- Diamond Focus Ring
        [37818] = {t = 4024}, -- Bronze Band of Force
        [37836] = {t = 4007}, -- Spice Bread
        [38068] = {t = 4024}, -- Mercurial Adamantite
        [38070] = {t = 4013}, -- Mercurial Stone
        [38175] = {t = 4024}, -- Bronze Torc
        [39451] = {t = 4023}, -- Rigid Azure Moonstone
        [39452] = {t = 4023}, -- Rigid Star of Elune
        [39455] = {t = 4023}, -- Shifting Shadow Draenite
        [39458] = {t = 4023}, -- Shifting Shadow Draenite
        [39462] = {t = 4023}, -- Glinting Nightseye
        [39463] = {t = 4023}, -- Shifting Nightseye
        [39636] = {t = 4013}, -- Elixir of Major Fortitude
        [39638] = {t = 4013}, -- Elixir of Draenic Wisdom
        [39710] = {t = 4023}, -- Brilliant Crimson Spinel
        [39712] = {t = 4023}, -- Delicate Crimson Spinel
        [39717] = {t = 4023}, -- Sparkling Empyrean Sapphire
        [39719] = {t = 4023}, -- Brilliant Crimson Spinel
        [39722] = {t = 4023}, -- Smooth Lionseye
        [39723] = {t = 4023}, -- Subtle Lionseye
        [39725] = {t = 4023}, -- Rigid Empyrean Sapphire
        [39729] = {t = 4023}, -- Shifting Shadowsong Amethyst
        [39730] = {t = 4023}, -- Glinting Shadowsong Amethyst
        [39732] = {t = 4023}, -- Purified Shadowsong Amethyst
        [39735] = {t = 4023}, -- Reckless Pyrestone
        [39971] = {t = 4017}, -- Icy Blasting Primers
        [39973] = {t = 4017}, -- Frost Grenade
        [40000] = {t = 4002}, -- LeCraft's Fantastic Script Test Spell
        [40274] = {t = 4016}, -- Furious Gizmatic Goggles
        [40514] = {t = 4024}, -- Necklace of the Deep
        [41307] = {t = 4017}, -- Gyro-balanced Khorium Destroyer
        [41311] = {t = 4016}, -- Justicebringer 2000 Specs
        [41312] = {t = 4016}, -- Tankatronic Goggles
        [41314] = {t = 4016}, -- Surestrike Goggles v2.0
        [41315] = {t = 4016}, -- Gadgetstorm Goggles
        [41316] = {t = 4016}, -- Living Replicator Specs
        [41317] = {t = 4016}, -- Deathblow X11 Goggles
        [41318] = {t = 4016}, -- Wonderheal XT40 Shades
        [41319] = {t = 4016}, -- Magnified Moon Specs
        [41320] = {t = 4017}, -- Destruction Holo-gogs
        [41321] = {t = 4016}, -- Powerheal 4000 Lens
        [41414] = {t = 4024}, -- Brilliant Pearl Band
        [41415] = {t = 4024}, -- The Black Pearl
        [41418] = {t = 4024}, -- Crown of the Sea Witch
        [41420] = {t = 4024}, -- Purified Jaggal Pearl
        [41429] = {t = 4024}, -- Purified Shadow Pearl
        [42296] = {t = 4007}, -- Stewed Trout
        [42302] = {t = 4007}, -- Fisherman's Feast
        [42305] = {t = 4007}, -- Hot Buttered Trout
        [42613] = {t = 4019}, -- Nexus Transformation
        [42615] = {t = 4019}, -- Small Prismatic Shard
        [42736] = {t = 4003}, -- Flask of Chromatic Wonder
        [43676] = {t = 4016}, -- Adamantite Arrow Maker
        [44155] = {t = 4017}, -- Flying Machine
        [44157] = {t = 4017}, -- Turbo-Charged Flying Machine
        [44343] = {t = 4002}, -- Knothide Ammo Pouch
        [44344] = {t = 4002}, -- Knothide Quiver
        [44359] = {t = 4002}, -- Quiver of a Thousand Feathers
        [44383] = {t = 4019}, -- Enchant Shield - Resilience
        [44483] = {t = 4018}, -- Enchant Cloak - Superior Frost Resistance
        [44484] = {t = 4019}, -- Enchant Gloves - Expertise
        [44488] = {t = 4019}, -- Enchant Gloves - Precision
        [44489] = {t = 4019}, -- Enchant Shield - Dodge
        [44492] = {t = 4019}, -- Enchant Chest - Mighty Health
        [44494] = {t = 4018}, -- Enchant Cloak - Superior Nature Resistance
        [44500] = {t = 4019}, -- Enchant Cloak - Superior Agility
        [44506] = {t = 4019}, -- Enchant Gloves - Gatherer
        [44508] = {t = 4019}, -- Enchant Boots - Greater Spirit
        [44509] = {t = 4019}, -- Enchant Chest - Greater Mana Restoration
        [44510] = {t = 4019}, -- Enchant Weapon - Exceptional Spirit
        [44513] = {t = 4019}, -- Enchant Gloves - Greater Assault
        [44528] = {t = 4019}, -- Enchant Boots - Greater Fortitude
        [44529] = {t = 4019}, -- Enchant Gloves - Major Agility
        [44555] = {t = 4019}, -- Enchant Bracer - Exceptional Intellect
        [44556] = {t = 4018}, -- Enchant Cloak - Superior Fire Resistance
        [44582] = {t = 4019}, -- Enchant Cloak - Minor Power
        [44584] = {t = 4019}, -- Enchant Boots - Greater Vitality
        [44589] = {t = 4019}, -- Enchant Boots - Superior Agility
        [44590] = {t = 4018}, -- Enchant Cloak - Superior Shadow Resistance
        [44592] = {t = 4019}, -- Enchant Gloves - Exceptional Spellpower
        [44593] = {t = 4019}, -- Enchant Bracer - Major Spirit
        [44596] = {t = 4018}, -- Enchant Cloak - Superior Arcane Resistance
        [44598] = {t = 4019}, -- Enchant Bracer - Expertise
        [44616] = {t = 4019}, -- Enchant Bracer - Greater Stats
        [44623] = {t = 4019}, -- Enchant Chest - Super Stats
        [44629] = {t = 4019}, -- Enchant Weapon - Exceptional Spellpower
        [44630] = {t = 4019}, -- Enchant 2H Weapon - Greater Savagery
        [44633] = {t = 4019}, -- Enchant Weapon - Exceptional Agility
        [44635] = {t = 4019}, -- Enchant Bracer - Greater Spellpower
        [44636] = {t = 4019}, -- Enchant Ring - Lesser Intellect
        [44645] = {t = 4019}, -- Enchant Ring - Assault
        [44768] = {t = 4002}, -- Netherscale Ammo Pouch
        [45061] = {t = 4013}, -- Mad Alchemist's Potion
        [45382] = {t = 4025, a = true}, -- Scroll of Stamina
        [45545] = {t = 4012}, -- Frostweave Bandage
        [45546] = {t = 4012}, -- Heavy Frostweave Bandage
        [45549] = {t = 4007}, -- Mammoth Meal
        [45550] = {t = 4007}, -- Shoveltusk Steak
        [45551] = {t = 4007}, -- Worm Delight
        [45552] = {t = 4007}, -- Roasted Worg
        [45553] = {t = 4007}, -- Rhino Dogs
        [45554] = {t = 4007}, -- Great Feast
        [45560] = {t = 4007}, -- Smoked Rockfin
        [45561] = {t = 4007}, -- Grilled Bonescale
        [45562] = {t = 4007}, -- Sauteed Goby
        [45563] = {t = 4007}, -- Grilled Sculpin
        [45564] = {t = 4007}, -- Smoked Salmon
        [45565] = {t = 4007}, -- Poached Nettlefish
        [45566] = {t = 4007}, -- Pickled Fangtooth
        [45569] = {t = 4007}, -- Baked Manta Ray
        [46404] = {t = 4023}, -- Reckless Noble Topaz
        [46684] = {t = 4007}, -- Charred Bear Kabobs
        [46688] = {t = 4007}, -- Juicy Bear Burger
        [47280] = {t = 4024}, -- Brilliant Glass
        [47766] = {t = 4019}, -- Enchant Chest - Greater Dodge
        [47900] = {t = 4019}, -- Enchant Chest - Super Health
        [48114] = {t = 4025, a = true}, -- Scroll of Intellect
        [48116] = {t = 4025, a = true}, -- Scroll of Spirit
        [48121] = {t = 4026}, -- Glyph of Entangling Roots
        [48247] = {t = 4026}, -- Mysterious Tarot
        [48248] = {t = 4026}, -- Scroll of Recall
        [48789] = {t = 4023}, -- Purified Shadowsong Amethyst
        [49252] = {t = 4009}, -- Smelt Cobalt
        [49258] = {t = 4009}, -- Smelt Saronite
        [50598] = {t = 4026}, -- Scroll of Intellect II
        [50599] = {t = 4026}, -- Scroll of Intellect III
        [50600] = {t = 4026}, -- Scroll of Intellect IV
        [50601] = {t = 4026}, -- Scroll of Intellect V
        [50602] = {t = 4026}, -- Scroll of Intellect VI
        [50603] = {t = 4026}, -- Scroll of Intellect VII
        [50604] = {t = 4026}, -- Scroll of Intellect VIII
        [50605] = {t = 4026}, -- Scroll of Spirit II
        [50606] = {t = 4026}, -- Scroll of Spirit III
        [50607] = {t = 4026}, -- Scroll of Spirit IV
        [50608] = {t = 4026}, -- Scroll of Spirit V
        [50609] = {t = 4026}, -- Scroll of Spirit VI
        [50610] = {t = 4026}, -- Scroll of Spirit VII
        [50611] = {t = 4026}, -- Scroll of Spirit VIII
        [50612] = {t = 4026}, -- Scroll of Stamina II
        [50614] = {t = 4026}, -- Scroll of Stamina III
        [50616] = {t = 4026}, -- Scroll of Stamina IV
        [50617] = {t = 4026}, -- Scroll of Stamina V
        [50618] = {t = 4026}, -- Scroll of Stamina VI
        [50619] = {t = 4026}, -- Scroll of Stamina VII
        [50620] = {t = 4026}, -- Scroll of Stamina VIII
        [52567] = {t = 4014}, -- Cobalt Legplates
        [52568] = {t = 4014}, -- Cobalt Belt
        [52569] = {t = 4014}, -- Cobalt Boots
        [52570] = {t = 4014}, -- Cobalt Chestpiece
        [52571] = {t = 4014}, -- Cobalt Helm
        [52572] = {t = 4014}, -- Cobalt Shoulders
        [52738] = {t = 4025, a = true}, -- Ivory Ink
        [52739] = {t = 4026}, -- Enchanting Vellum
        [52840] = {t = 4025}, -- Weapon Vellum
        [52843] = {t = 4026}, -- Moonglow Ink
        [53281] = {t = 4017}, -- Volatile Blasting Trigger
        [53462] = {t = 4026}, -- Midnight Ink
        [53770] = {t = 4003}, -- Scourge Haunt Visual
        [53772] = {t = 4003}, -- Scourge Haunt Visual, Face Player and give GUID
        [53778] = {t = 4003}, -- Lay On Hands
        [53812] = {t = 4013}, -- Pygmy Oil
        [53831] = {t = 4024}, -- Bold Bloodstone
        [53832] = {t = 4024}, -- Delicate Bloodstone
        [53834] = {t = 4023}, -- Brilliant Bloodstone
        [53835] = {t = 4023}, -- Delicate Bloodstone
        [53836] = {t = 4013}, -- Runic Healing Potion
        [53837] = {t = 4013}, -- Runic Mana Potion
        [53838] = {t = 4013}, -- Resurgent Healing Potion
        [53839] = {t = 4013}, -- Icy Mana Potion
        [53840] = {t = 4013}, -- Elixir of Mighty Agility
        [53841] = {t = 4013}, -- Wrath Elixir
        [53842] = {t = 4013}, -- Spellpower Elixir
        [53843] = {t = 4024}, -- Subtle Sun Crystal
        [53844] = {t = 4024}, -- Flashing Bloodstone
        [53845] = {t = 4024}, -- Smooth Sun Crystal
        [53847] = {t = 4013}, -- Elixir of Spirit
        [53848] = {t = 4013}, -- Guru's Elixir
        [53852] = {t = 4024}, -- Brilliant Bloodstone
        [53853] = {t = 4023}, -- Smooth Sun Crystal
        [53854] = {t = 4024}, -- Rigid Chalcedony
        [53855] = {t = 4023}, -- Subtle Sun Crystal
        [53856] = {t = 4024}, -- Quick Sun Crystal
        [53859] = {t = 4024}, -- Sovereign Shadow Crystal
        [53860] = {t = 4024}, -- Shifting Shadow Crystal
        [53861] = {t = 4024}, -- Glinting Shadow Crystal
        [53862] = {t = 4023}, -- Timeless Shadow Crystal
        [53863] = {t = 4023}, -- Purified Shadow Crystal
        [53864] = {t = 4023}, -- Purified Shadow Crystal
        [53866] = {t = 4023}, -- Shifting Shadow Crystal
        [53867] = {t = 4023}, -- Glinting Shadow Crystal
        [53868] = {t = 4023}, -- Regal Dark Jade
        [53870] = {t = 4024}, -- Jagged Dark Jade
        [53871] = {t = 4024}, -- Guardian's Shadow Crystal
        [53872] = {t = 4024}, -- Inscribed Huge Citrine
        [53873] = {t = 4024}, -- Etched Shadow Crystal
        [53874] = {t = 4024}, -- Champion's Huge Citrine
        [53876] = {t = 4024}, -- Fierce Huge Citrine
        [53878] = {t = 4023}, -- Glinting Shadow Crystal
        [53880] = {t = 4024}, -- Deft Huge Citrine
        [53881] = {t = 4023}, -- Reckless Huge Citrine
        [53882] = {t = 4024}, -- Potent Huge Citrine
        [53883] = {t = 4024}, -- Veiled Shadow Crystal
        [53886] = {t = 4023}, -- Deadly Huge Citrine
        [53887] = {t = 4023}, -- Glinting Shadow Crystal
        [53888] = {t = 4023}, -- Lucent Huge Citrine
        [53889] = {t = 4023}, -- Deft Huge Citrine
        [53890] = {t = 4023}, -- Stalwart Huge Citrine
        [53891] = {t = 4024}, -- Stalwart Huge Citrine
        [53892] = {t = 4024}, -- Accurate Shadow Crystal
        [53893] = {t = 4024}, -- Resolute Huge Citrine
        [53894] = {t = 4024}, -- Timeless Shadow Crystal
        [53898] = {t = 4013}, -- Elixir of Mighty Fortitude
        [53899] = {t = 4013}, -- Lesser Flask of Toughness
        [53900] = {t = 4013}, -- Potion of Nightmares
        [53901] = {t = 4013}, -- Flask of the Frost Wyrm
        [53902] = {t = 4013}, -- Flask of Stoneblood
        [53903] = {t = 4013}, -- Flask of Endless Rage
        [53905] = {t = 4013}, -- Indestructible Potion
        [53916] = {t = 4023}, -- Jagged Dark Jade
        [53918] = {t = 4024}, -- Regal Dark Jade
        [53920] = {t = 4024}, -- Forceful Dark Jade
        [53922] = {t = 4024}, -- Misty Dark Jade
        [53923] = {t = 4024}, -- Lightning Dark Jade
        [53925] = {t = 4024}, -- Energized Dark Jade
        [53926] = {t = 4023}, -- Purified Shadow Crystal
        [53927] = {t = 4023}, -- Misty Dark Jade
        [53928] = {t = 4023}, -- Lightning Dark Jade
        [53929] = {t = 4023}, -- Turbid Dark Jade
        [53930] = {t = 4023}, -- Energized Dark Jade
        [53931] = {t = 4023}, -- Radiant Dark Jade
        [53934] = {t = 4024}, -- Solid Chalcedony
        [53940] = {t = 4023}, -- Sparkling Chalcedony
        [53941] = {t = 4024}, -- Sparkling Chalcedony
        [53947] = {t = 4023}, -- Delicate Scarlet Ruby
        [53950] = {t = 4023}, -- Smooth Autumn's Glow
        [53953] = {t = 4023}, -- Sparkling Sky Sapphire
        [53956] = {t = 4023}, -- Brilliant Scarlet Ruby
        [53959] = {t = 4023}, -- Subtle Autumn's Glow
        [53964] = {t = 4023}, -- Glinting Twilight Opal
        [53967] = {t = 4023}, -- Purified Twilight Opal
        [53969] = {t = 4023}, -- Shifting Twilight Opal
        [53970] = {t = 4023}, -- Glinting Twilight Opal
        [53971] = {t = 4023}, -- Regal Forest Emerald
        [53973] = {t = 4023}, -- Jagged Forest Emerald
        [53979] = {t = 4023}, -- Deadly Monarch Topaz
        [53982] = {t = 4023}, -- Deft Monarch Topaz
        [53983] = {t = 4023}, -- Reckless Monarch Topaz
        [53989] = {t = 4023}, -- Glinting Twilight Opal
        [53990] = {t = 4023}, -- Lucent Monarch Topaz
        [53992] = {t = 4023}, -- Stalwart Monarch Topaz
        [53995] = {t = 4023}, -- Timeless Twilight Opal
        [54002] = {t = 4023}, -- Purified Twilight Opal
        [54004] = {t = 4023}, -- Lightning Forest Emerald
        [54006] = {t = 4023}, -- Energized Forest Emerald
        [54007] = {t = 4023}, -- Purified Twilight Opal
        [54008] = {t = 4023}, -- Misty Forest Emerald
        [54010] = {t = 4023}, -- Turbid Forest Emerald
        [54013] = {t = 4023}, -- Radiant Forest Emerald
        [54017] = {t = 4024}, -- Precise Bloodstone
        [54020] = {d = {60893}}, -- Transmute: Eternal Might
        [54213] = {t = 4013}, -- Flask of Pure Mojo
        [54218] = {t = 4013}, -- Elixir of Mighty Strength
        [54353] = {t = 4017}, -- Mark "S" Boomstick
        [54550] = {t = 4014}, -- Cobalt Triangle Shield
        [54551] = {t = 4014}, -- Tempered Saronite Belt
        [54552] = {t = 4014}, -- Tempered Saronite Boots
        [54553] = {t = 4014}, -- Tempered Saronite Breastplate
        [54554] = {t = 4014}, -- Tempered Saronite Legplates
        [54555] = {t = 4014}, -- Tempered Saronite Helm
        [54556] = {t = 4014}, -- Tempered Saronite Shoulders
        [54557] = {t = 4014}, -- Saronite Defender
        [54736] = {t = 4017}, -- EMP Generator
        [54793] = {t = 4017}, -- Frag Belt
        [54917] = {t = 4014}, -- Spiked Cobalt Helm
        [54918] = {t = 4014}, -- Spiked Cobalt Boots
        [54941] = {t = 4014}, -- Spiked Cobalt Shoulders
        [54944] = {t = 4014}, -- Spiked Cobalt Chestpiece
        [54945] = {t = 4014}, -- Spiked Cobalt Gauntlets
        [54946] = {t = 4014}, -- Spiked Cobalt Belt
        [54947] = {t = 4014}, -- Spiked Cobalt Legplates
        [54948] = {t = 4014}, -- Spiked Cobalt Bracers
        [54949] = {t = 4014}, -- Horned Cobalt Helm
        [54998] = {t = 4017}, -- Hand-Mounted Pyro Rocket
        [54999] = {t = 4017}, -- Hyperspeed Accelerators
        [55002] = {t = 4017}, -- Flexweave Underlay
        [55013] = {t = 4014}, -- Saronite Protector
        [55014] = {t = 4014}, -- Saronite Bulwark
        [55015] = {t = 4014}, -- Tempered Saronite Gauntlets
        [55016] = {t = 4017}, -- Nitro Boosts
        [55017] = {t = 4014}, -- Tempered Saronite Bracers
        [55055] = {t = 4014}, -- Brilliant Saronite Legplates
        [55056] = {t = 4014}, -- Brilliant Saronite Gauntlets
        [55057] = {t = 4014}, -- Brilliant Saronite Boots
        [55058] = {t = 4014}, -- Brilliant Saronite Breastplate
        [55174] = {t = 4014}, -- Honed Cobalt Cleaver
        [55177] = {t = 4014}, -- Savage Cobalt Slicer
        [55179] = {t = 4014}, -- Saronite Ambusher
        [55181] = {t = 4014}, -- Saronite Shiv
        [55182] = {t = 4014}, -- Furious Saronite Beatstick
        [55183] = {t = 4010}, -- Corroded Saronite Edge
        [55184] = {t = 4010}, -- Corroded Saronite Woundbringer
        [55185] = {t = 4014}, -- Saronite Mindcrusher
        [55186] = {t = 4010}, -- Chestplate of Conquest
        [55187] = {t = 4010}, -- Legplates of Conquest
        [55200] = {t = 4014}, -- Sturdy Cobalt Quickblade
        [55201] = {t = 4014}, -- Cobalt Tenderizer
        [55202] = {t = 4010}, -- Sure-fire Shuriken
        [55203] = {t = 4014}, -- Forged Cobalt Claymore
        [55204] = {t = 4014}, -- Notched Cobalt War Axe
        [55206] = {t = 4014}, -- Deadly Saronite Dirk
        [55208] = {t = 4009}, -- Smelt Titansteel
        [55211] = {t = 4009}, -- Smelt Titanium
        [55243] = {t = 4002}, -- Bracers of Deflection
        [55298] = {t = 4014}, -- Vengeance Bindings
        [55300] = {t = 4014}, -- Righteous Gauntlets
        [55301] = {t = 4014}, -- Daunting Handguards
        [55302] = {t = 4014}, -- Helm of Command
        [55303] = {t = 4014}, -- Daunting Legplates
        [55304] = {t = 4014}, -- Righteous Greaves
        [55305] = {t = 4014}, -- Savage Saronite Bracers
        [55306] = {t = 4014}, -- Savage Saronite Pauldrons
        [55307] = {t = 4014}, -- Savage Saronite Waistguard
        [55308] = {t = 4014}, -- Savage Saronite Walkers
        [55309] = {t = 4014}, -- Savage Saronite Gauntlets
        [55310] = {t = 4014}, -- Savage Saronite Legplates
        [55311] = {t = 4014}, -- Savage Saronite Hauberk
        [55312] = {t = 4014}, -- Savage Saronite Skullshield
        [55369] = {t = 4014}, -- Titansteel Destroyer
        [55370] = {t = 4014}, -- Titansteel Bonecrusher
        [55371] = {t = 4014}, -- Titansteel Guardian
        [55372] = {t = 4014}, -- Spiked Titansteel Helm
        [55373] = {t = 4014}, -- Tempered Titansteel Helm
        [55374] = {t = 4014}, -- Brilliant Titansteel Helm
        [55375] = {t = 4014}, -- Spiked Titansteel Treads
        [55376] = {t = 4014}, -- Tempered Titansteel Treads
        [55377] = {t = 4014}, -- Brilliant Titansteel Treads
        [55386] = {t = 4024}, -- Tireless Skyflare Diamond
        [55394] = {t = 4024}, -- Swift Skyflare Diamond
        [55399] = {t = 4024}, -- Powerful Earthsiege Diamond
        [55402] = {t = 4024}, -- Persistent Earthsiege Diamond
        [55628] = {t = 4014}, -- Socket Bracer
        [55641] = {t = 4014}, -- Socket Gloves
        [55642] = {t = 4015}, -- Lightweave Embroidery
        [55656] = {t = 4014}, -- Eternal Belt Buckle
        [55732] = {t = 4010}, -- Titanium Rod
        [55769] = {t = 4015}, -- Darkglow Embroidery
        [55777] = {t = 4015}, -- Swordguard Embroidery
        [55834] = {t = 4014}, -- Cobalt Bracers
        [55835] = {t = 4014}, -- Cobalt Gauntlets
        [55839] = {t = 4014}, -- Titanium Weapon Chain
        [55898] = {t = 4015}, -- Frostweave Net
        [55899] = {t = 4015}, -- Bolt of Frostweave
        [55900] = {t = 4015}, -- Bolt of Imbued Frostweave
        [55901] = {t = 4015}, -- Duskweave Leggings
        [55902] = {t = 4015}, -- Frostwoven Shoulders
        [55903] = {t = 4015}, -- Frostwoven Robe
        [55904] = {t = 4015}, -- Frostwoven Gloves
        [55906] = {t = 4015}, -- Frostwoven Boots
        [55907] = {t = 4015}, -- Frostwoven Cowl
        [55908] = {t = 4015}, -- Frostwoven Belt
        [55910] = {t = 4015}, -- Mystic Frostwoven Shoulders
        [55911] = {t = 4015}, -- Mystic Frostwoven Robe
        [55913] = {t = 4015}, -- Mystic Frostwoven Wristwraps
        [55914] = {t = 4015}, -- Duskweave Belt
        [55919] = {t = 4015}, -- Duskweave Cowl
        [55920] = {t = 4015}, -- Duskweave Wristwraps
        [55921] = {t = 4015}, -- Duskweave Robe
        [55922] = {t = 4015}, -- Duskweave Gloves
        [55923] = {t = 4015}, -- Duskweave Shoulders
        [55924] = {t = 4015}, -- Duskweave Boots
        [55925] = {t = 4015}, -- Black Duskweave Leggings
        [55941] = {t = 4015}, -- Black Duskweave Robe
        [55943] = {t = 4015}, -- Black Duskweave Wristwraps
        [55995] = {t = 4015}, -- Yellow Lumberjack Shirt
        [56000] = {t = 4015}, -- Green Workman's Shirt
        [56001] = {t = 4015}, -- Moonshroud
        [56002] = {t = 4015}, -- Ebonweave
        [56003] = {t = 4015}, -- Spellweave
        [56007] = {t = 4015}, -- Frostweave Bag
        [56008] = {t = 4015}, -- Shining Spellthread
        [56010] = {t = 4015}, -- Azure Spellthread
        [56014] = {t = 4015}, -- Cloak of the Moon
        [56015] = {t = 4015}, -- Cloak of Frozen Spirits
        [56018] = {t = 4015}, -- Hat of Wintry Doom
        [56019] = {t = 4015}, -- Silky Iceshard Boots
        [56020] = {t = 4015}, -- Deep Frozen Cord
        [56021] = {t = 4015}, -- Frostmoon Pants
        [56022] = {t = 4015}, -- Light Blessed Mittens
        [56023] = {t = 4015}, -- Aurora Slippers
        [56024] = {t = 4015}, -- Moonshroud Robe
        [56025] = {t = 4015}, -- Moonshroud Gloves
        [56026] = {t = 4015}, -- Ebonweave Robe
        [56027] = {t = 4015}, -- Ebonweave Gloves
        [56028] = {t = 4015}, -- Spellweave Robe
        [56029] = {t = 4015}, -- Spellweave Gloves
        [56030] = {t = 4015}, -- Frostwoven Leggings
        [56031] = {t = 4015}, -- Frostwoven Wristwraps
        [56034] = {t = 4015}, -- Master's Spellthread
        [56039] = {t = 4015}, -- Sanctified Spellthread
        [56048] = {t = 4006}, -- Duskweave Boots
        [56054] = {t = 4023}, -- Delicate Dragon's Eye
        [56074] = {t = 4023}, -- Brilliant Dragon's Eye
        [56076] = {t = 4023}, -- Smooth Dragon's Eye
        [56077] = {t = 4023}, -- Sparkling Dragon's Eye
        [56089] = {t = 4023}, -- Subtle Dragon's Eye
        [56193] = {t = 4024}, -- Bloodstone Band
        [56194] = {t = 4024}, -- Sun Rock Ring
        [56195] = {t = 4024}, -- Jade Dagger Pendant
        [56196] = {t = 4024}, -- Blood Sun Necklace
        [56197] = {t = 4024}, -- Dream Signet
        [56199] = {t = 4024}, -- Figurine - Ruby Hare
        [56201] = {t = 4024}, -- Figurine - Twilight Serpent
        [56202] = {t = 4024}, -- Figurine - Sapphire Owl
        [56203] = {t = 4024}, -- Figurine - Emerald Boar
        [56205] = {t = 4024}, -- Dark Jade Focusing Lens
        [56206] = {t = 4024}, -- Shadow Crystal Focusing Lens
        [56208] = {t = 4024}, -- Shadow Jade Focusing Lens
        [56234] = {t = 4014}, -- Titansteel Shanker
        [56280] = {t = 4014}, -- Cudgel of Saronite Justice
        [56349] = {t = 4017}, -- Handful of Cobalt Bolts
        [56357] = {t = 4014}, -- Titanium Shield Spike
        [56400] = {t = 4014}, -- Titansteel Shield Wall
        [56459] = {t = 4017}, -- Hammer Pick
        [56460] = {t = 4017}, -- Cobalt Frag Bomb
        [56461] = {t = 4017}, -- Bladed Pickaxe
        [56462] = {t = 4017}, -- Gnomish Army Knife
        [56463] = {t = 4017}, -- Explosive Decoy
        [56464] = {t = 4017}, -- Overcharged Capacitor
        [56465] = {t = 4017}, -- Mechanized Snow Goggles
        [56466] = {t = 4017}, -- Sonic Booster
        [56467] = {t = 4017}, -- Noise Machine
        [56468] = {t = 4017}, -- Box of Bombs
        [56469] = {t = 4017}, -- Gnomish Lightning Generator
        [56470] = {t = 4017}, -- Sun Scope
        [56471] = {t = 4017}, -- Froststeel Tube
        [56472] = {t = 4017}, -- MOLL-E
        [56473] = {t = 4021}, -- Gnomish X-Ray Specs
        [56474] = {t = 4016}, -- Mammoth Cutters
        [56475] = {t = 4016}, -- Saronite Razorheads
        [56476] = {t = 4017}, -- Healing Injector Kit
        [56477] = {t = 4017}, -- Mana Injector Kit
        [56478] = {t = 4017}, -- Heartseeker Scope
        [56479] = {t = 4017}, -- Armor Plated Combat Shotgun
        [56480] = {t = 4016}, -- Armored Titanium Goggles
        [56481] = {t = 4016}, -- Weakness Spectralizers
        [56483] = {t = 4016}, -- Charged Titanium Specs
        [56484] = {t = 4017}, -- Visage Liquification Goggles
        [56486] = {t = 4016}, -- Greensight Gogs
        [56487] = {t = 4016}, -- Electroflux Sight Enhancers
        [56514] = {t = 4020}, -- Global Thermal Sapper Charge
        [56530] = {t = 4024}, -- Enchanted Pearl
        [56531] = {t = 4024}, -- Enchanted Tear
        [56549] = {t = 4014}, -- Ornate Saronite Bracers
        [56550] = {t = 4014}, -- Ornate Saronite Pauldrons
        [56551] = {t = 4014}, -- Ornate Saronite Waistguard
        [56552] = {t = 4014}, -- Ornate Saronite Walkers
        [56553] = {t = 4014}, -- Ornate Saronite Gauntlets
        [56554] = {t = 4014}, -- Ornate Saronite Legplates
        [56555] = {t = 4014}, -- Ornate Saronite Hauberk
        [56556] = {t = 4014}, -- Ornate Saronite Skullshield
        [56574] = {t = 4016}, -- Truesight Ice Blinders
        [56943] = {t = 4026}, -- Glyph of Frenzied Regeneration
        [56945] = {t = 4026}, -- Glyph of Healing Touch
        [56948] = {t = 4026}, -- Glyph of the Orca
        [56951] = {t = 4026}, -- Glyph of Savagery
        [56952] = {t = 4026}, -- Glyph of Pounce
        [56953] = {t = 4026}, -- Glyph of Rebirth
        [56955] = {t = 4026}, -- Glyph of Rejuvenation
        [56956] = {t = 4026}, -- Glyph of Prowl
        [56957] = {t = 4026}, -- Glyph of Shred
        [56959] = {t = 4026}, -- Glyph of Guided Stars
        [56961] = {t = 4026}, -- Glyph of Maul
        [56963] = {t = 4026}, -- Glyph of Nature's Grasp
        [56968] = {t = 4025}, -- Glyph of Arcane Explosion
        [56971] = {t = 4026}, -- Glyph of Loose Mana
        [56972] = {t = 4026}, -- Glyph of Arcane Explosion
        [56973] = {t = 4026}, -- Glyph of Blink
        [56974] = {t = 4026}, -- Glyph of Evocation
        [56976] = {t = 4026}, -- Glyph of Frost Nova
        [56978] = {t = 4026}, -- Glyph of Momentum
        [56979] = {t = 4026}, -- Glyph of Ice Block
        [56980] = {t = 4026, d = {61177, 61756}}, -- Glyph of Splitting Ice
        [56981] = {t = 4026}, -- Glyph of Cone of Cold
        [56982] = {t = 4025}, -- Glyph of Scorch
        [56984] = {t = 4026}, -- Glyph of Mana Gem
        [56985] = {t = 4025}, -- Glyph of Mana Gem
        [56987] = {t = 4026, d = {61177, 61756}}, -- Glyph of Polymorph
        [56991] = {t = 4026}, -- Glyph of Arcane Power
        [56994] = {t = 4026}, -- Glyph of Aspects
        [56995] = {t = 4026}, -- Glyph of Camouflage
        [56997] = {t = 4026}, -- Glyph of Mending
        [57000] = {t = 4026}, -- Glyph of Deterrence
        [57001] = {t = 4026}, -- Glyph of Disengage
        [57002] = {t = 4026}, -- Glyph of Freezing Trap
        [57003] = {t = 4026}, -- Glyph of Ice Trap
        [57004] = {t = 4026}, -- Glyph of Misdirection
        [57005] = {t = 4026}, -- Glyph of Explosive Trap
        [57006] = {t = 4026, d = {61177, 61756}}, -- Glyph of Animal Bond
        [57007] = {t = 4026}, -- Glyph of No Escape
        [57008] = {t = 4026}, -- Glyph of Pathfinding
        [57009] = {t = 4026}, -- Glyph of Tame Beast
        [57020] = {t = 4026}, -- Glyph of Final Wrath
        [57022] = {t = 4026}, -- Glyph of Divine Protection
        [57023] = {t = 4026}, -- Glyph of Consecration
        [57024] = {t = 4026}, -- Glyph of Avenging Wrath
        [57025] = {t = 4026}, -- Glyph of Blinding Light
        [57026] = {t = 4026}, -- Glyph of Word of Glory
        [57027] = {t = 4026}, -- Glyph of Holy Wrath
        [57029] = {t = 4026}, -- Glyph of Illumination
        [57030] = {t = 4026}, -- Glyph of Double Jeopardy
        [57031] = {t = 4026}, -- Glyph of Divinity
        [57032] = {t = 4025}, -- Glyph of the Luminous Charger
        [57033] = {t = 4026}, -- Glyph of Devotion Aura
        [57036] = {t = 4026, d = {61177, 61756}}, -- Glyph of Turn Evil
        [57113] = {t = 4026}, -- Glyph of Ambush
        [57114] = {t = 4026}, -- Glyph of Decoy
        [57119] = {t = 4026}, -- Glyph of Evasion
        [57120] = {t = 4026}, -- Glyph of Recovery
        [57121] = {t = 4026}, -- Glyph of Expose Armor
        [57122] = {t = 4026}, -- Glyph of Feint
        [57123] = {t = 4026}, -- Glyph of Garrote
        [57125] = {t = 4026}, -- Glyph of Gouge
        [57129] = {t = 4026}, -- Glyph of Hemorraghing Veins
        [57131] = {t = 4026}, -- Glyph of Redirect
        [57132] = {t = 4026}, -- Glyph of Shiv
        [57133] = {t = 4026}, -- Glyph of Sprint
        [57151] = {t = 4025}, -- Glyph of Barbaric Insults
        [57154] = {t = 4026}, -- Glyph of Hindering Strikes
        [57156] = {t = 4026}, -- Glyph of Bloodthirst
        [57157] = {t = 4026}, -- Glyph of Rude Interruption
        [57158] = {t = 4026}, -- Glyph of Gag Order
        [57161] = {t = 4026}, -- Glyph of Die by the Sword
        [57162] = {t = 4026}, -- Glyph of Enraged Speed
        [57163] = {t = 4026}, -- Glyph of Hamstring
        [57165] = {t = 4026}, -- Glyph of Hold the Line
        [57167] = {t = 4026}, -- Glyph of Hoarse Voice
        [57168] = {t = 4026}, -- Glyph of Sweeping Strikes
        [57172] = {t = 4026}, -- Glyph of Raging Wind
        [57183] = {t = 4026}, -- Glyph of Purify
        [57184] = {t = 4026}, -- Glyph of Fade
        [57185] = {t = 4026}, -- Glyph of Fear Ward
        [57186] = {t = 4026}, -- Glyph of Inner Sanctum
        [57187] = {t = 4026}, -- Glyph of Holy Nova
        [57188] = {t = 4026}, -- Glyph of Inner Fire
        [57192] = {t = 4026}, -- Glyph of Holy Fire
        [57194] = {t = 4026}, -- Glyph of Power Word: Shield
        [57196] = {t = 4026}, -- Glyph of Psychic Scream
        [57197] = {t = 4026}, -- Glyph of Renew
        [57198] = {t = 4026, d = {61177, 61756}}, -- Glyph of Scourge Imprisonment
        [57200] = {t = 4026}, -- Glyph of Dispel Magic
        [57201] = {t = 4026}, -- Glyph of Smite
        [57210] = {t = 4026}, -- Glyph of Icebound Fortitude
        [57213] = {t = 4026}, -- Glyph of Death Grip
        [57216] = {t = 4026}, -- Glyph of Shifting Presences
        [57219] = {t = 4026}, -- Glyph of Icy Touch
        [57221] = {t = 4026}, -- Glyph of Pestilence
        [57222] = {t = 4026}, -- Glyph of Mind Freeze
        [57224] = {t = 4026}, -- Glyph of Foul Menagerie
        [57225] = {t = 4026, d = {61177, 61756}}, -- Glyph of Strangulate
        [57226] = {t = 4026}, -- Glyph of Pillar of Frost
        [57227] = {t = 4026}, -- Glyph of Vampiric Blood
        [57231] = {t = 4025}, -- Death Knight Glyph 25
        [57236] = {t = 4026}, -- Glyph of Purge
        [57238] = {t = 4026}, -- Glyph of Fire Nova
        [57239] = {t = 4026}, -- Glyph of Flame Shock
        [57240] = {t = 4026}, -- Glyph of Wind Shear
        [57241] = {t = 4026}, -- Glyph of Frost Shock
        [57242] = {t = 4026}, -- Glyph of Healing Stream Totem
        [57244] = {t = 4026}, -- Glyph of Totemic Recall
        [57245] = {t = 4026}, -- Glyph of Telluric Currents
        [57246] = {t = 4026}, -- Glyph of the Lakestrider
        [57248] = {t = 4026, d = {61177, 61756}}, -- Glyph of Spiritwalker's Grace
        [57249] = {t = 4026}, -- Glyph of Lava Lash
        [57251] = {t = 4026}, -- Glyph of Water Shield
        [57252] = {t = 4026}, -- Glyph of Cleansing Waters
        [57257] = {t = 4026}, -- Glyph of Hand of Gul'dan
        [57259] = {t = 4026}, -- Glyph of Siphon Life
        [57262] = {t = 4026}, -- Glyph of Fear
        [57265] = {t = 4026}, -- Glyph of Health Funnel
        [57266] = {t = 4026}, -- Glyph of Healthstone
        [57269] = {t = 4026}, -- Glyph of Imp Swarm
        [57270] = {t = 4026}, -- Glyph of Havoc
        [57271] = {t = 4026}, -- Glyph of Shadow Bolt
        [57274] = {t = 4026}, -- Glyph of Soulstone
        [57275] = {t = 4026}, -- Glyph of Carrion Swarm
        [57277] = {t = 4026}, -- Glyph of Falling Meteor
        [57425] = {t = 4013}, -- Transmute: Skyflare Diamond
        [57427] = {t = 4013}, -- Transmute: Earthsiege Diamond
        [57692] = {t = 4002}, -- Fur Lining - Fire Resist
        [57694] = {t = 4002}, -- Fur Lining - Frost Resist
        [57696] = {t = 4002}, -- Fur Lining - Shadow Resist
        [57699] = {t = 4002}, -- Fur Lining - Nature Resist
        [57701] = {t = 4002}, -- Fur Lining - Arcane Resist
        [57703] = {t = 4026}, -- Hunter's Ink
        [57704] = {t = 4026}, -- Lion's Ink
        [57706] = {t = 4026}, -- Dawnstar Ink
        [57707] = {t = 4026}, -- Jadefire Ink
        [57708] = {t = 4026}, -- Royal Ink
        [57709] = {t = 4026}, -- Celestial Ink
        [57710] = {t = 4026}, -- Fiery Ink
        [57711] = {t = 4026}, -- Shimmering Ink
        [57712] = {t = 4026}, -- Ink of the Sky
        [57713] = {t = 4026}, -- Ethereal Ink
        [57714] = {t = 4026}, -- Darkflame Ink
        [57715] = {t = 4026}, -- Ink of the Sea
        [57716] = {t = 4026}, -- Snowfall Ink
        [58065] = {t = 4007}, -- Dalaran Clam Chowder
        [58141] = {t = 4024}, -- Crystal Citrine Necklace
        [58142] = {t = 4024}, -- Crystal Chalcedony Amulet
        [58143] = {t = 4024}, -- Earthshadow Ring
        [58144] = {t = 4024}, -- Jade Ring of Slaying
        [58145] = {t = 4024}, -- Stoneguard Band
        [58146] = {t = 4024}, -- Shadowmight Ring
        [58322] = {d = {61288, 61177, 61756}}, -- Glyph of Dark Archangel
        [58341] = {d = {61288, 61177, 61756}}, -- Glyph of Soulwell
        [58344] = {t = 4026, d = {61288}}, -- Glyph of Long Charge
        [58346] = {t = 4026, d = {61288}}, -- Glyph of Unending Rage
        [58472] = {t = 4026}, -- Scroll of Agility
        [58473] = {t = 4026}, -- Scroll of Agility II
        [58476] = {t = 4026}, -- Scroll of Agility III
        [58478] = {t = 4026}, -- Scroll of Agility IV
        [58480] = {t = 4026}, -- Scroll of Agility V
        [58481] = {t = 4026}, -- Scroll of Agility VI
        [58482] = {t = 4026}, -- Scroll of Agility VII
        [58483] = {t = 4026}, -- Scroll of Agility VIII
        [58484] = {t = 4026}, -- Scroll of Strength
        [58485] = {t = 4026}, -- Scroll of Strength II
        [58486] = {t = 4026}, -- Scroll of Strength III
        [58487] = {t = 4026}, -- Scroll of Strength IV
        [58488] = {t = 4026}, -- Scroll of Strength V
        [58489] = {t = 4026}, -- Scroll of Strength VI
        [58490] = {t = 4026}, -- Scroll of Strength VII
        [58491] = {t = 4026}, -- Scroll of Strength VIII
        [58565] = {t = 4026}, -- Mystic Tome
        [58868] = {t = 4013}, -- Endless Mana Potion
        [58871] = {t = 4013}, -- Endless Healing Potion
        [59326] = {t = 4026, d = {61288}}, -- Glyph of Ghost Wolf
        [59338] = {t = 4026}, -- Glyph of Unholy Command
        [59339] = {t = 4026}, -- Glyph of Outbreak
        [59340] = {t = 4026}, -- Glyph of Corpse Explosion
        [59387] = {t = 4026}, -- Certificate of Ownership
        [59405] = {t = 4014}, -- Cobalt Skeleton Key
        [59406] = {t = 4014}, -- Titanium Skeleton Key
        [59436] = {t = 4014}, -- Brilliant Saronite Belt
        [59438] = {t = 4014}, -- Brilliant Saronite Bracers
        [59440] = {t = 4014}, -- Brilliant Saronite Pauldrons
        [59441] = {t = 4014}, -- Brilliant Saronite Helm
        [59442] = {t = 4014}, -- Saronite Spellblade
        [59475] = {t = 4026}, -- Tome of the Dawn
        [59478] = {t = 4026}, -- Book of Survival
        [59480] = {t = 4026}, -- Strange Tarot
        [59484] = {t = 4026}, -- Tome of Kings
        [59486] = {t = 4026}, -- Royal Guide of Escape Routes
        [59487] = {t = 4026}, -- Arcane Tarot
        [59488] = {t = 4025}, -- Weapon Vellum II
        [59489] = {t = 4026}, -- Fire Eater's Guide
        [59490] = {t = 4026}, -- Book of Stars
        [59491] = {t = 4026}, -- Shadowy Tarot
        [59493] = {t = 4026}, -- Stormbound Tome
        [59494] = {t = 4026}, -- Manual of Clouds
        [59495] = {t = 4026}, -- Hellfire Tome
        [59496] = {t = 4026}, -- Book of Clever Tricks
        [59497] = {t = 4026}, -- Iron-bound Tome
        [59498] = {t = 4026}, -- Faces of Doom
        [59499] = {t = 4025}, -- Armor Vellum II
        [59500] = {t = 4025}, -- Armor Vellum III
        [59501] = {t = 4025}, -- Weapon Vellum III
        [59502] = {t = 4026}, -- Darkmoon Card
        [59503] = {t = 4026}, -- Greater Darkmoon Card
        [59504] = {t = 4026}, -- Darkmoon Card of the North
        [59582] = {t = 4015}, -- Frostsavage Belt
        [59583] = {t = 4015}, -- Frostsavage Bracers
        [59584] = {t = 4015}, -- Frostsavage Shoulders
        [59585] = {t = 4015}, -- Frostsavage Boots
        [59586] = {t = 4015}, -- Frostsavage Gloves
        [59587] = {t = 4015}, -- Frostsavage Robe
        [59588] = {t = 4015}, -- Frostsavage Leggings
        [59589] = {t = 4015}, -- Frostsavage Cowl
        [59636] = {t = 4019}, -- Enchant Ring - Lesser Stamina
        [59759] = {t = 4024}, -- Figurine - Monarch Crab
        [60336] = {t = 4026}, -- Scroll of Recall II
        [60337] = {t = 4026}, -- Scroll of Recall III
        [60350] = {t = 4013}, -- Transmute: Titanium
        [60367] = {t = 4013}, -- Elixir of Mighty Thoughts
        [60396] = {t = 4013}, -- Mercurial Alchemist Stone
        [60403] = {t = 4013}, -- Indestructible Alchemist Stone
        [60405] = {t = 4013}, -- Mighty Alchemist Stone
        [60583] = {t = 4002}, -- Jormungar Leg Reinforcements
        [60584] = {t = 4002}, -- Nerubian Leg Reinforcements
        [60606] = {t = 4019}, -- Enchant Boots - Assault
        [60609] = {t = 4019}, -- Enchant Cloak - Speed
        [60616] = {t = 4019}, -- Enchant Bracer - Assault
        [60621] = {t = 4019}, -- Enchant Weapon - Greater Potency
        [60623] = {t = 4019}, -- Enchant Boots - Icewalker
        [60645] = {t = 4002}, -- Dragonscale Ammo Pouch
        [60647] = {t = 4002}, -- Nerubian Reinforced Quiver
        [60653] = {t = 4019}, -- Enchant Shield - Greater Intellect
        [60663] = {t = 4019}, -- Enchant Cloak - Major Agility
        [60668] = {t = 4019}, -- Enchant Gloves - Crusher
        [60874] = {t = 4017}, -- Nesingwary 4000
        [60893] = {t = 4013}, -- Northrend Alchemy Research
        [60969] = {t = 4015}, -- Flying Carpet
        [60971] = {t = 4015}, -- Magnificent Flying Carpet
        [60990] = {t = 4015}, -- Glacial Waistband
        [60993] = {t = 4015}, -- Glacial Robe
        [60994] = {t = 4015}, -- Glacial Slippers
        [61008] = {t = 4014}, -- Icebane Chestguard
        [61009] = {t = 4014}, -- Icebane Girdle
        [61010] = {t = 4014}, -- Icebane Treads
        [61117] = {t = 4026}, -- Master's Inscription of the Axe
        [61118] = {t = 4026}, -- Master's Inscription of the Crag
        [61119] = {t = 4026}, -- Master's Inscription of the Pinnacle
        [61120] = {t = 4026}, -- Master's Inscription of the Storm
        [61177] = {t = 4026}, -- Northrend Inscription Research
        [61288] = {t = 4026}, -- Minor Inscription Research
        [61471] = {t = 4017}, -- Diamond-cut Refractor Scope
        [61481] = {t = 4016}, -- Mechanized Snow Goggles
        [61482] = {t = 4016}, -- Mechanized Snow Goggles
        [61483] = {t = 4016}, -- Mechanized Snow Goggles
        [62162] = {t = 4026}, -- Glyph of the Master Shapeshifter
        [62213] = {t = 4003}, -- Lesser Flask of Resistance
        [62242] = {t = 4024}, -- Icy Prism
        [62271] = {t = 4016}, -- Unbreakable Healing Amplifiers
        [62409] = {t = 4013}, -- Ethereal Oil
        [62941] = {t = 4024}, -- Prismatic Black Diamond
        [62959] = {t = 4019}, -- Enchant Staff - Spellpower
        [63182] = {t = 4014}, -- Titansteel Spellblade
        [63732] = {t = 4004}, -- Elixir of Minor Accuracy
        [63742] = {t = 4005}, -- Spidersilk Drape
        [63743] = {t = 4024}, -- Amulet of Truesight
        [63750] = {t = 4017}, -- High-powered Flashlight
        [63765] = {t = 4016}, -- Springy Arachnoweave
        [63770] = {t = 4017}, -- Reticulated Armor Webbing
        [64053] = {t = 4026}, -- Twilight Tome
        [64258] = {t = 4026}, -- Glyph of Cyclone
        [64259] = {t = 4026}, -- Glyph of Binding Heal
        [64260] = {t = 4026}, -- Glyph of Disguise
        [64261] = {t = 4026}, -- Glyph of Deluge
        [64262] = {t = 4026}, -- Glyph of Shamanistic Rage
        [64266] = {t = 4026}, -- Glyph of Death Coil
        [64267] = {t = 4025}, -- Glyph of Disease
        [64358] = {t = 4007}, -- Black Jelly
        [64725] = {t = 4024}, -- Emerald Choker
        [64726] = {t = 4024}, -- Sky Sapphire Amulet
        [64727] = {t = 4024}, -- Runed Mana Band
        [64728] = {t = 4024}, -- Scarlet Signet
        [64729] = {t = 4015}, -- Frostguard Drape
        [64730] = {t = 4015}, -- Cloak of Crimson Snow
        [66430] = {t = 4023}, -- Purified Dreadstone
        [66433] = {t = 4023}, -- Purified Dreadstone
        [66436] = {t = 4023}, -- Misty Eye of Zul
        [66437] = {t = 4023}, -- Lightning Eye of Zul
        [66438] = {t = 4023}, -- Radiant Eye of Zul
        [66440] = {t = 4023}, -- Energized Eye of Zul
        [66444] = {t = 4023}, -- Turbid Eye of Zul
        [66449] = {t = 4023}, -- Delicate Cardinal Ruby
        [66451] = {t = 4023}, -- Smooth King's Amber
        [66500] = {t = 4023}, -- Sparkling Majestic Zircon
        [66503] = {t = 4023}, -- Brilliant Cardinal Ruby
        [66504] = {t = 4023}, -- Subtle King's Amber
        [66553] = {t = 4023}, -- Shifting Dreadstone
        [66555] = {t = 4023}, -- Timeless Dreadstone
        [66558] = {t = 4023}, -- Purified Dreadstone
        [66559] = {t = 4023}, -- Regal Eye of Zul
        [66563] = {t = 4023}, -- Jagged Eye of Zul
        [66564] = {t = 4023}, -- Glinting Dreadstone
        [66565] = {t = 4023}, -- Glinting Dreadstone
        [66566] = {t = 4023}, -- Purified Dreadstone
        [66575] = {t = 4023}, -- Glinting Dreadstone
        [66577] = {t = 4023}, -- Deadly Ametrine
        [66578] = {t = 4023}, -- Stalwart Ametrine
        [66580] = {t = 4023}, -- Lucent Ametrine
        [66587] = {t = 4023}, -- Deft Ametrine
        [66658] = {t = 4013}, -- Transmute: Ametrine
        [66660] = {t = 4013}, -- Transmute: King's Amber
        [66662] = {t = 4013}, -- Transmute: Dreadstone
        [66663] = {t = 4013}, -- Transmute: Majestic Zircon
        [66664] = {t = 4013}, -- Transmute: Eye of Zul
        [67025] = {t = 4003}, -- Flask of the North
        [67326] = {t = 4017}, -- Goblin Beam Welder
        [67600] = {t = 4026}, -- Glyph of Ferocious Bite
        [67790] = {t = 4016}, -- Dimensional Folder: K3
        [67839] = {t = 4017}, -- Mind Amplification Dish
        [67920] = {t = 4017}, -- Wormhole Generator: Northrend
        [69385] = {t = 4026}, -- Runescroll of Fortitude
        [69412] = {t = 4019}, -- Abyssal Shatter
        [70524] = {t = 4009}, -- Enchanted Thorium Bar
        [71015] = {t = 4025}, -- Glyph of Rapid Rejuvenation
        [72952] = {t = 4016}, -- Shatter Rounds
        [72953] = {t = 4016}, -- Iceblade Arrow
        [73222] = {t = 4024}, -- Bold Carnelian
        [73223] = {t = 4024}, -- Delicate Carnelian
        [73225] = {t = 4024}, -- Brilliant Carnelian
        [73226] = {t = 4024}, -- Precise Carnelian
        [73227] = {t = 4024}, -- Solid Zephyrite
        [73228] = {t = 4024}, -- Sparkling Zephyrite
        [73230] = {t = 4024}, -- Rigid Zephyrite
        [73232] = {t = 4024}, -- Smooth Alicite
        [73233] = {t = 4023}, -- Mystic Alicite
        [73234] = {t = 4024}, -- Quick Alicite
        [73239] = {t = 4024}, -- Fractured Alicite
        [73240] = {t = 4024}, -- Sovereign Nightstone
        [73241] = {t = 4024}, -- Shifting Nightstone
        [73243] = {t = 4024}, -- Timeless Nightstone
        [73246] = {t = 4024}, -- Etched Nightstone
        [73247] = {t = 4024}, -- Glinting Nightstone
        [73249] = {t = 4024}, -- Veiled Nightstone
        [73250] = {t = 4024}, -- Accurate Nightstone
        [73259] = {t = 4023}, -- Resolute Hessonite
        [73266] = {t = 4024}, -- Reckless Hessonite
        [73267] = {t = 4024}, -- Skillful Hessonite
        [73268] = {t = 4024}, -- Adept Hessonite
        [73270] = {t = 4024}, -- Artful Hessonite
        [73274] = {t = 4024}, -- Jagged Jasper
        [73279] = {t = 4024}, -- Puissant Jasper
        [73281] = {t = 4024}, -- Sensei's Jasper
        [73478] = {t = 4024}, -- Fire Prism
        [73494] = {t = 4024}, -- Jasper Ring
        [73495] = {t = 4024}, -- Hessonite Band
        [73496] = {t = 4024}, -- Alicite Pendant
        [73497] = {t = 4024}, -- Nightstone Choker
        [73620] = {t = 4024}, -- Carnelian Spikes
        [73621] = {t = 4024}, -- The Perforator
        [73622] = {t = 4024}, -- Stardust
        [74132] = {t = 4019}, -- Enchant Gloves - Mastery
        [74189] = {t = 4019}, -- Enchant Boots - Earthen Vitality
        [74191] = {t = 4019}, -- Enchant Chest - Mighty Stats
        [74192] = {t = 4019}, -- Enchant Cloak - Lesser Power
        [74193] = {t = 4019}, -- Enchant Bracer - Speed
        [74195] = {t = 4019}, -- Enchant Weapon - Mending
        [74197] = {t = 4019}, -- Enchant Weapon - Avalanche
        [74198] = {t = 4019}, -- Enchant Gloves - Haste
        [74199] = {t = 4019}, -- Enchant Boots - Haste
        [74200] = {t = 4019}, -- Enchant Chest - Stamina
        [74201] = {t = 4019}, -- Enchant Bracer - Critical Strike
        [74202] = {t = 4019}, -- Enchant Cloak - Intellect
        [74207] = {t = 4019}, -- Enchant Shield - Protection
        [74211] = {t = 4019}, -- Enchant Weapon - Elemental Slayer
        [74212] = {t = 4019}, -- Enchant Gloves - Exceptional Strength
        [74213] = {t = 4019}, -- Enchant Boots - Major Agility
        [74214] = {t = 4019}, -- Enchant Chest - Mighty Resilience
        [74215] = {t = 4019}, -- Enchant Ring - Strength
        [74216] = {t = 4019}, -- Enchant Ring - Agility
        [74217] = {t = 4019}, -- Enchant Ring - Intellect
        [74218] = {t = 4019}, -- Enchant Ring - Stamina
        [74220] = {t = 4019}, -- Enchant Gloves - Greater Expertise
        [74223] = {t = 4019}, -- Enchant Weapon - Hurricane
        [74225] = {t = 4019}, -- Enchant Weapon - Heartsong
        [74226] = {t = 4019}, -- Enchant Shield - Mastery
        [74229] = {t = 4019}, -- Enchant Bracer - Superior Dodge
        [74230] = {t = 4019}, -- Enchant Cloak - Critical Strike
        [74231] = {t = 4019}, -- Enchant Chest - Exceptional Spirit
        [74232] = {t = 4019}, -- Enchant Bracer - Precision
        [74234] = {t = 4019}, -- Enchant Cloak - Protection
        [74235] = {t = 4019}, -- Enchant Off-Hand - Superior Intellect
        [74236] = {t = 4019}, -- Enchant Boots - Precision
        [74237] = {t = 4019}, -- Enchant Bracer - Exceptional Spirit
        [74238] = {t = 4019}, -- Enchant Boots - Mastery
        [74239] = {t = 4019}, -- Enchant Bracer - Greater Expertise
        [74240] = {t = 4019}, -- Enchant Cloak - Greater Intellect
        [74493] = {t = 4002}, -- Savage Leather
        [74529] = {t = 4009}, -- Smelt Pyrite
        [74530] = {t = 4009}, -- Smelt Elementium
        [74537] = {t = 4009}, -- Smelt Hardened Elementium
        [74556] = {t = 4012}, -- Embersilk Bandage
        [74557] = {t = 4012}, -- Heavy Embersilk Bandage
        [74558] = {t = 4012}, -- Field Bandage: Dense Embersilk
        [74964] = {t = 4015}, -- Bolt of Embersilk Cloth
        [75141] = {t = 4015}, -- Dream of Skywall
        [75142] = {t = 4015}, -- Dream of Deepholm
        [75144] = {t = 4015}, -- Dream of Hyjal
        [75145] = {t = 4015}, -- Dream of Ragnaros
        [75146] = {t = 4015}, -- Dream of Azshara
        [75154] = {t = 4015, a = true}, -- Master's Spellthread
        [75155] = {t = 4015, a = true}, -- Sanctified Spellthread
        [75172] = {t = 4015, a = true}, -- Lightweave Embroidery
        [75175] = {t = 4015, a = true}, -- Darkglow Embroidery
        [75178] = {t = 4015, a = true}, -- Swordguard Embroidery
        [75247] = {t = 4015}, -- Embersilk Net
        [75248] = {t = 4015}, -- Deathsilk Belt
        [75249] = {t = 4015}, -- Deathsilk Bracers
        [75250] = {t = 4015}, -- Enchanted Spellthread
        [75251] = {t = 4015}, -- Deathsilk Shoulders
        [75252] = {t = 4015}, -- Deathsilk Boots
        [75253] = {t = 4015}, -- Deathsilk Gloves
        [75254] = {t = 4015}, -- Deathsilk Leggings
        [75255] = {t = 4015}, -- Ghostly Spellthread
        [75256] = {t = 4015}, -- Deathsilk Cowl
        [75257] = {t = 4015}, -- Deathsilk Robe
        [75258] = {t = 4015}, -- Spiritmend Belt
        [75259] = {t = 4015}, -- Spiritmend Bracers
        [75260] = {t = 4015}, -- Spiritmend Shoulders
        [75261] = {t = 4015}, -- Spiritmend Boots
        [75262] = {t = 4015}, -- Spiritmend Gloves
        [75263] = {t = 4015}, -- Spiritmend Leggings
        [75264] = {t = 4015}, -- Embersilk Bag
        [75265] = {t = 4015}, -- Otherworldly Bag
        [75266] = {t = 4015}, -- Spiritmend Cowl
        [75267] = {t = 4015}, -- Spiritmend Robe
        [75268] = {t = 4015}, -- Hyjal Expedition Bag
        [75269] = {t = 4015}, -- Bloodthirsty Fireweave Belt
        [75270] = {t = 4015}, -- Bloodthirsty Embersilk Bracers
        [75290] = {t = 4015}, -- Bloodthirsty Fireweave Bracers
        [75291] = {t = 4015}, -- Bloodthirsty Embersilk Shoulders
        [75292] = {t = 4015}, -- Bloodthirsty Fireweave Shoulders
        [75293] = {t = 4015}, -- Bloodthirsty Embersilk Belt
        [75294] = {t = 4015}, -- Bloodthirsty Fireweave Boots
        [75295] = {t = 4015}, -- Bloodthirsty Embersilk Gloves
        [75296] = {t = 4015}, -- Bloodthirsty Fireweave Gloves
        [75297] = {t = 4015}, -- Bloodthirsty Embersilk Boots
        [76178] = {t = 4014}, -- Folded Obsidium
        [76179] = {t = 4014}, -- Hardened Obsidium Bracers
        [76180] = {t = 4014}, -- Hardened Obsidium Gauntlets
        [76181] = {t = 4014}, -- Hardened Obsidium Belt
        [76182] = {t = 4014}, -- Hardened Obsidium Boots
        [76258] = {t = 4014}, -- Hardened Obsidium Shoulders
        [76259] = {t = 4014}, -- Hardened Obsidium Legguards
        [76260] = {t = 4014}, -- Hardened Obsidium Helm
        [76261] = {t = 4014}, -- Hardened Obsidium Breastplate
        [76262] = {t = 4014}, -- Redsteel Bracers
        [76263] = {t = 4014}, -- Redsteel Gauntlets
        [76264] = {t = 4014}, -- Redsteel Belt
        [76265] = {t = 4014}, -- Redsteel Boots
        [76266] = {t = 4014}, -- Redsteel Shoulders
        [76267] = {t = 4014}, -- Redsteel Legguards
        [76269] = {t = 4014}, -- Redsteel Helm
        [76270] = {t = 4014}, -- Redsteel Breastplate
        [76280] = {t = 4014}, -- Stormforged Bracers
        [76281] = {t = 4014}, -- Stormforged Gauntlets
        [76283] = {t = 4014}, -- Stormforged Belt
        [76285] = {t = 4014}, -- Stormforged Boots
        [76286] = {t = 4014}, -- Stormforged Shoulders
        [76287] = {t = 4014}, -- Stormforged Legguards
        [76288] = {t = 4014}, -- Stormforged Helm
        [76289] = {t = 4014}, -- Stormforged Breastplate
        [76291] = {t = 4014}, -- Hardened Obsidium Shield
        [76293] = {t = 4014}, -- Stormforged Shield
        [76433] = {t = 4014}, -- Decapitator's Razor
        [76434] = {t = 4014}, -- Cold-Forged Shank
        [76435] = {t = 4014}, -- Fire-Etched Dagger
        [76436] = {t = 4014}, -- Lifeforce Hammer
        [76437] = {t = 4014}, -- Obsidium Executioner
        [76438] = {t = 4014}, -- Obsidium Skeleton Key
        [76441] = {t = 4014}, -- Elementium Shield Spike
        [76474] = {t = 4014}, -- Obsidium Bladespear
        [78866] = {t = 4013}, -- Transmute: Living Elements
        [80237] = {t = 4013}, -- Transmute: Shadowspirit Diamond
        [80243] = {t = 4013}, -- Transmute: Truegold
        [80244] = {t = 4013}, -- Transmute: Pyrium Bar
        [80245] = {t = 4013}, -- Transmute: Inferno Ruby
        [80246] = {t = 4013}, -- Transmute: Ocean Sapphire
        [80247] = {t = 4013}, -- Transmute: Amberjewel
        [80248] = {t = 4013}, -- Transmute: Demonseye
        [80250] = {t = 4013}, -- Transmute: Ember Topaz
        [80251] = {t = 4013}, -- Transmute: Dream Emerald
        [80269] = {t = 4013}, -- Potion of Illusion
        [80477] = {t = 4013}, -- Ghost Elixir
        [80478] = {t = 4013}, -- Earthen Potion
        [80479] = {t = 4013}, -- Deathblood Venom
        [80480] = {t = 4013}, -- Elixir of the Naga
        [80481] = {t = 4013}, -- Volcanic Potion
        [80482] = {t = 4013}, -- Potion of Concentration
        [80484] = {t = 4013}, -- Elixir of the Cobra
        [80486] = {t = 4013}, -- Deepstone Oil
        [80487] = {t = 4013}, -- Mysterious Potion
        [80488] = {t = 4013}, -- Elixir of Deep Earth
        [80490] = {t = 4013}, -- Mighty Rejuvenation Potion
        [80491] = {t = 4013}, -- Elixir of Impossible Accuracy
        [80492] = {t = 4013}, -- Prismatic Elixir
        [80493] = {t = 4013}, -- Elixir of Mighty Speed
        [80494] = {t = 4013}, -- Mythical Mana Potion
        [80495] = {t = 4013}, -- Potion of the Tol'vir
        [80496] = {t = 4013}, -- Golemblood Potion
        [80497] = {t = 4013}, -- Elixir of the Master
        [80498] = {t = 4013}, -- Mythical Healing Potion
        [80508] = {t = 4013}, -- Lifebound Alchemist Stone
        [80719] = {t = 4013}, -- Flask of Steelskin
        [80720] = {t = 4013}, -- Flask of the Draconic Mind
        [80721] = {t = 4013}, -- Flask of the Winds
        [80723] = {t = 4013}, -- Flask of Titanic Strength
        [80725] = {t = 4013}, -- Potion of Deepholm
        [80726] = {t = 4013}, -- Potion of Treasure Finding
        [81714] = {t = 4016}, -- Reinforced Bio-Optic Killshades
        [81715] = {t = 4016}, -- Specialized Bio-Optic Killshades
        [81716] = {t = 4016}, -- Deadly Bio-Optic Killshades
        [81720] = {t = 4016}, -- Energized Bio-Optic Killshades
        [81722] = {t = 4016}, -- Agile Bio-Optic Killshades
        [81724] = {t = 4016}, -- Camouflage Bio-Optic Killshades
        [81725] = {t = 4017}, -- Lightweight Bio-Optic Killshades
        [82175] = {t = 4016}, -- Synapse Springs
        [82177] = {t = 4016}, -- Quickflip Deflection Plates
        [82180] = {t = 4016}, -- Tazik Shocker
        [82200] = {t = 4016}, -- Spinal Healing Injector
        [82207] = {t = 4016}, -- Explosive Bolts
        [84038] = {t = 4009}, -- Smelt Obsidium
        [84403] = {t = 4017}, -- Handful of Obsidium Bolts
        [84406] = {t = 4017}, -- Authentic Jr. Engineer Goggles
        [84408] = {t = 4017}, -- R19 Threatfinder
        [84409] = {t = 4017}, -- Volatile Seaforium Blastpack
        [84410] = {t = 4017}, -- Safety Catch Removal Kit
        [84411] = {t = 4017}, -- High-Powered Bolt Gun
        [84412] = {t = 4020}, -- Personal World Destroyer
        [84413] = {t = 4021}, -- De-Weaponized Mechanical Companion
        [84415] = {t = 4017}, -- Lure Master Tackle Box
        [84416] = {t = 4017}, -- Elementium Toolbox
        [84417] = {t = 4017}, -- Volatile Thunderstick
        [84418] = {t = 4017}, -- Elementium Dragonling
        [84420] = {t = 4017}, -- Finely-Tuned Throat Needler
        [84421] = {t = 4017}, -- Loot-a-Rang
        [84424] = {t = 4016}, -- Invisibility Field
        [84425] = {t = 4016}, -- Cardboard Assassin
        [84427] = {t = 4016}, -- Grounded Plasma Shield
        [84428] = {t = 4017}, -- Gnomish X-Ray Scope
        [84429] = {t = 4017}, -- Goblin Barbecue
        [84430] = {t = 4017}, -- Heat-Treated Spinning Lure
        [84431] = {t = 4017}, -- Overpowered Chicken Splitter
        [84432] = {t = 4017}, -- Kickback 5000
        [85785] = {t = 4026}, -- Runescroll of Fortitude II
        [86004] = {t = 4026}, -- Blackfallow Ink
        [86005] = {t = 4026}, -- Inferno Ink
        [86375] = {t = 4026}, -- Swiftsteel Inscription
        [86401] = {t = 4026}, -- Lionsmane Inscription
        [86402] = {t = 4026}, -- Inscription of the Earth Prince
        [86403] = {t = 4026}, -- Felfire Inscription
        [86609] = {t = 4026}, -- Mysterious Fortune Card
        [86615] = {t = 4026}, -- Darkmoon Card of Destruction
        [86616] = {t = 4026}, -- Book of Blood
        [86640] = {t = 4026}, -- Lord Rottington's Pressed Wisp Book
        [86641] = {t = 4026}, -- Dungeoneering Guide
        [86642] = {t = 4026}, -- Divine Companion
        [86643] = {t = 4026}, -- Battle Tome
        [86648] = {t = 4026}, -- Key to the Planes
        [86649] = {t = 4026}, -- Runed Staff
        [86652] = {t = 4026}, -- Rosethorn Staff
        [86653] = {t = 4026}, -- Silver Inlaid Staff
        [86654] = {t = 4025}, -- Forged Documents
        [88006] = {t = 4007}, -- Blackened Surprise
        [88015] = {t = 4007}, -- Darkbrew Lager
        [88893] = {t = 4012}, -- Dense Embersilk Bandage
        [89244] = {t = 4026}, -- Forged Documents
        [89368] = {t = 4026}, -- Scroll of Intellect IX
        [89369] = {t = 4026}, -- Scroll of Strength IX
        [89370] = {t = 4026}, -- Scroll of Agility IX
        [89371] = {t = 4026}, -- Scroll of Spirit IX
        [89372] = {t = 4026}, -- Scroll of Stamina IX
        [89373] = {t = 4026}, -- Scroll of Protection IX
        [92026] = {t = 4026}, -- Vanishing Powder
        [92027] = {t = 4026}, -- Dust of Disappearance
        [92579] = {t = 4026}, -- Glyph of Blind
        [93741] = {t = 4007}, -- Venison Jerky
        [93935] = {t = 4013}, -- Draught of War
        [94000] = {t = 4025}, -- Glyph of Inferno Blast
        [94162] = {t = 4013}, -- Flask of Flowing Water
        [94401] = {t = 4026}, -- Glyph of Cat Form
        [94402] = {t = 4026}, -- Glyph of Fae Silence
        [94403] = {t = 4026}, -- Glyph of Faerie Fire
        [94404] = {t = 4026}, -- Glyph of the Predator
        [94405] = {t = 4026}, -- Glyph of Recklessness
        [94406] = {t = 4026}, -- Glyph of Bull Rush
        [94711] = {t = 4025}, -- Glyph of Vanish
        [94743] = {t = 4015}, -- Dream of Destruction
        [94748] = {t = 4017}, -- Electrified Ether
        [95215] = {t = 4025}, -- Glyph of the Treant
        [95471] = {t = 4019}, -- Enchant 2H Weapon - Mighty Agility
        [95703] = {t = 4017}, -- Electrostatic Condenser
        [95705] = {t = 4021}, -- Gnomish Gravity Well
        [95707] = {t = 4020}, -- Big Daddy
        [95710] = {t = 4025}, -- Glyph of Rapid Teleportation
        [95825] = {t = 4025}, -- Glyph of Protector of the Innocent
        [96252] = {t = 4013}, -- Volatile Alchemist Stone
        [96253] = {t = 4013}, -- Quicksilver Alchemist Stone
        [96254] = {t = 4013}, -- Vibrant Alchemist Stone
        [96284] = {t = 4026}, -- Glyph of Dark Succor
        [98398] = {t = 4025}, -- Glyph of Armors
        [99537] = {t = 4015}, -- Vicious Embersilk Cape
        [99539] = {t = 4024}, -- Vicious Sapphire Ring
        [99540] = {t = 4024}, -- Vicious Amberjewel Band
        [99541] = {t = 4024}, -- Vicious Ruby Signet
        [99542] = {t = 4024}, -- Vicious Sapphire Necklace
        [99543] = {t = 4024}, -- Vicious Amberjewel Pendant
        [99544] = {t = 4024}, -- Vicious Ruby Choker
        [101057] = {t = 4025}, -- Glyph of Lightning Shield
        [102165] = {t = 4008}, -- Smelt Ghost Iron
        [102167] = {t = 4008}, -- Smelt Trillium
        [102366] = {t = 4002}, -- Mist-Touched Leather
        [102697] = {t = 4027}, -- Windwool Bandage
        [102698] = {t = 4027}, -- Heavy Windwool Bandage
        [103461] = {t = 4018}, -- Enchant Ring - Greater Agility
        [103462] = {t = 4018}, -- Enchant Ring - Greater Intellect
        [103463] = {t = 4018}, -- Enchant Ring - Greater Stamina
        [103465] = {t = 4018}, -- Enchant Ring - Greater Strength
        [104237] = {t = 4001}, -- Golden Carp Consomme
        [104297] = {t = 4001}, -- Fish Cake
        [104338] = {t = 4018}, -- Enchant Bracer - Mastery
        [104385] = {t = 4018}, -- Enchant Bracer - Major Dodge
        [104392] = {t = 4018}, -- Enchant Chest - Super Resilience
        [104393] = {t = 4018}, -- Enchant Chest - Mighty Spirit
        [104395] = {t = 4018}, -- Enchant Chest - Glorious Stats
        [104397] = {t = 4018}, -- Enchant Chest - Superior Stamina
        [104398] = {t = 4018}, -- Enchant Cloak - Accuracy
        [104401] = {t = 4018}, -- Enchant Cloak - Greater Protection
        [104403] = {t = 4018}, -- Enchant Cloak - Superior Intellect
        [104404] = {t = 4018}, -- Enchant Cloak - Superior Critical Strike
        [104407] = {t = 4018}, -- Enchant Boots - Greater Haste
        [104408] = {t = 4018}, -- Enchant Boots - Greater Precision
        [104409] = {t = 4018}, -- Enchant Boots - Blurred Speed
        [104414] = {t = 4018}, -- Enchant Boots - Pandaren's Step
        [104416] = {t = 4018}, -- Enchant Gloves - Greater Haste
        [104417] = {t = 4018}, -- Enchant Gloves - Superior Expertise
        [104419] = {t = 4018}, -- Enchant Gloves - Super Strength
        [104420] = {t = 4018}, -- Enchant Gloves - Superior Mastery
        [104425] = {t = 4018}, -- Enchant Weapon - Windsong
        [104430] = {t = 4018}, -- Enchant Weapon - Elemental Force
        [104440] = {t = 4018}, -- Enchant Weapon - Colossus
        [104445] = {t = 4018}, -- Enchant Off-Hand - Major Intellect
        [104698] = {t = 4019}, -- Maelstrom Shatter
        [106947] = {d = {131593}}, -- Rigid River's Heart
        [106948] = {d = {131593}}, -- Stormy River's Heart
        [106949] = {d = {131593}}, -- Sparkling River's Heart
        [106950] = {d = {131593}}, -- Solid River's Heart
        [106953] = {d = {131593}}, -- Misty Wild Jade
        [106954] = {d = {131593}}, -- Piercing Wild Jade
        [106955] = {d = {131593}}, -- Lightning Wild Jade
        [106956] = {d = {131593}}, -- Sensei's Wild Jade
        [106957] = {d = {131593}}, -- Effulgent Wild Jade
        [106958] = {d = {131593}}, -- Zen Wild Jade
        [106960] = {d = {131593}}, -- Balanced Wild Jade
        [106961] = {d = {131593}}, -- Vivid Wild Jade
        [106962] = {d = {131593}}, -- Turbid Wild Jade
        [107598] = {t = 4028}, -- Balanced Alexandrite
        [107599] = {t = 4029}, -- Effulgent Alexandrite
        [107600] = {t = 4029}, -- Energized Alexandrite
        [107601] = {t = 4029}, -- Forceful Alexandrite
        [107602] = {t = 4029}, -- Jagged Alexandrite
        [107604] = {t = 4029}, -- Lightning Alexandrite
        [107605] = {t = 4029}, -- Misty Alexandrite
        [107606] = {t = 4029}, -- Nimble Alexandrite
        [107607] = {t = 4029}, -- Piercing Alexandrite
        [107608] = {t = 4029}, -- Puissant Alexandrite
        [107609] = {t = 4029}, -- Radiant Alexandrite
        [107610] = {t = 4029}, -- Regal Alexandrite
        [107611] = {t = 4029}, -- Sensei's Alexandrite
        [107612] = {t = 4029}, -- Shattered Alexandrite
        [107613] = {t = 4029}, -- Steady Alexandrite
        [107614] = {t = 4029}, -- Turbid Alexandrite
        [107615] = {t = 4029}, -- Vivid Alexandrite
        [107616] = {t = 4029}, -- Zen Alexandrite
        [107617] = {t = 4029}, -- Rigid Lapis Lazuli
        [107619] = {t = 4029}, -- Solid Lapis Lazuli
        [107620] = {t = 4029}, -- Sparkling Lapis Lazuli
        [107621] = {t = 4029}, -- Stormy Lapis Lazuli
        [107622] = {t = 4028}, -- Bold Pandarian Garnet
        [107623] = {t = 4029}, -- Brilliant Pandarian Garnet
        [107624] = {t = 4029}, -- Delicate Pandarian Garnet
        [107625] = {t = 4029}, -- Flashing Pandarian Garnet
        [107626] = {t = 4029}, -- Precise Pandarian Garnet
        [107627] = {t = 4029}, -- Accurate Roguestone
        [107628] = {t = 4029}, -- Defender's Roguestone
        [107630] = {t = 4029}, -- Etched Roguestone
        [107631] = {t = 4029}, -- Glinting Roguestone
        [107632] = {t = 4029}, -- Guardian's Roguestone
        [107633] = {t = 4029}, -- Mysterious Roguestone
        [107634] = {t = 4029}, -- Purified Roguestone
        [107635] = {t = 4029}, -- Retaliating Roguestone
        [107636] = {t = 4029}, -- Shifting Roguestone
        [107637] = {t = 4029}, -- Sovereign Roguestone
        [107638] = {t = 4029}, -- Timeless Roguestone
        [107639] = {t = 4029}, -- Veiled Roguestone
        [107640] = {t = 4029}, -- Fractured Sunstone
        [107641] = {t = 4029}, -- Mystic Sunstone
        [107642] = {t = 4029}, -- Quick Sunstone
        [107643] = {t = 4029}, -- Smooth Sunstone
        [107644] = {t = 4029}, -- Subtle Sunstone
        [107645] = {t = 4028}, -- Adept Tiger Opal
        [107646] = {t = 4029}, -- Artful Tiger Opal
        [107647] = {t = 4029}, -- Champion's Tiger Opal
        [107648] = {t = 4029}, -- Crafty Tiger Opal
        [107649] = {t = 4029}, -- Deadly Tiger Opal
        [107650] = {t = 4029}, -- Deft Tiger Opal
        [107651] = {t = 4029}, -- Fierce Tiger Opal
        [107652] = {t = 4029}, -- Fine Tiger Opal
        [107653] = {t = 4029}, -- Inscribed Tiger Opal
        [107654] = {t = 4029}, -- Keen Tiger Opal
        [107655] = {t = 4029}, -- Lucent Tiger Opal
        [107656] = {t = 4029}, -- Polished Tiger Opal
        [107657] = {t = 4029}, -- Potent Tiger Opal
        [107658] = {t = 4029}, -- Reckless Tiger Opal
        [107659] = {t = 4029}, -- Resolute Tiger Opal
        [107660] = {t = 4029}, -- Resplendent Tiger Opal
        [107661] = {t = 4029}, -- Skillful Tiger Opal
        [107662] = {t = 4029}, -- Splendid Tiger Opal
        [107663] = {t = 4029}, -- Stalwart Tiger Opal
        [107665] = {t = 4029}, -- Tenuous Tiger Opal
        [107666] = {t = 4029}, -- Wicked Tiger Opal
        [107667] = {t = 4029}, -- Willful Tiger Opal
        [107693] = {d = {131593}}, -- Accurate Imperial Amethyst
        [107694] = {d = {131593}}, -- Defender's Imperial Amethyst
        [107695] = {d = {131593}}, -- Etched Imperial Amethyst
        [107696] = {d = {131593}}, -- Glinting Imperial Amethyst
        [107697] = {d = {131593}}, -- Guardian's Imperial Amethyst
        [107698] = {d = {131593}}, -- Mysterious Imperial Amethyst
        [107699] = {d = {131593}}, -- Purified Imperial Amethyst
        [107700] = {d = {131593}}, -- Retaliating Imperial Amethyst
        [107701] = {d = {131593}}, -- Shifting Imperial Amethyst
        [107702] = {d = {131593}}, -- Sovereign Imperial Amethyst
        [107703] = {d = {131593}}, -- Timeless Imperial Amethyst
        [107704] = {d = {131593}}, -- Veiled Imperial Amethyst
        [107705] = {d = {131593}}, -- Bold Primordial Ruby
        [107706] = {d = {131593}}, -- Brilliant Primordial Ruby
        [107707] = {d = {131593}}, -- Delicate Primordial Ruby
        [107708] = {d = {131593}}, -- Flashing Primordial Ruby
        [107709] = {d = {131593}}, -- Precise Primordial Ruby
        [107710] = {d = {131593}}, -- Fractured Sun's Radiance
        [107711] = {d = {131593}}, -- Mystic Sun's Radiance
        [107712] = {d = {131593}}, -- Quick Sun's Radiance
        [107713] = {d = {131593}}, -- Smooth Sun's Radiance
        [107714] = {d = {131593}}, -- Subtle Sun's Radiance
        [107715] = {d = {131593}}, -- Adept Vermilion Onyx
        [107716] = {d = {131593}}, -- Artful Vermilion Onyx
        [107717] = {d = {131593}}, -- Champion's Vermilion Onyx
        [107718] = {d = {131593}}, -- Crafty Vermilion Onyx
        [107719] = {d = {131593}}, -- Deadly Vermilion Onyx
        [107720] = {d = {131593}}, -- Deft Vermilion Onyx
        [107721] = {d = {131593}}, -- Fierce Vermilion Onyx
        [107722] = {d = {131593}}, -- Fine Vermilion Onyx
        [107723] = {d = {131593}}, -- Inscribed Vermilion Onyx
        [107724] = {d = {131593}}, -- Keen Vermilion Onyx
        [107725] = {d = {131593}}, -- Lucent Vermilion Onyx
        [107726] = {d = {131593}}, -- Polished Vermilion Onyx
        [107727] = {d = {131593}}, -- Potent Vermilion Onyx
        [107728] = {d = {131593}}, -- Reckless Vermilion Onyx
        [107729] = {d = {131593}}, -- Resolute Vermilion Onyx
        [107730] = {d = {131593}}, -- Resplendent Vermilion Onyx
        [107731] = {d = {131593}}, -- Skillful Vermilion Onyx
        [107732] = {d = {131593}}, -- Splendid Vermilion Onyx
        [107733] = {d = {131593}}, -- Stalwart Vermilion Onyx
        [107734] = {d = {131593}}, -- Tenuous Vermilion Onyx
        [107735] = {d = {131593}}, -- Wicked Vermilion Onyx
        [107736] = {d = {131593}}, -- Willful Vermilion Onyx
        [107737] = {d = {131593}}, -- Energized Wild Jade
        [107738] = {d = {131593}}, -- Forceful Wild Jade
        [107739] = {d = {131593}}, -- Jagged Wild Jade
        [107740] = {d = {131593}}, -- Nimble Wild Jade
        [107742] = {d = {131593}}, -- Puissant Wild Jade
        [107743] = {d = {131593}}, -- Radiant Wild Jade
        [107744] = {d = {131593}}, -- Regal Wild Jade
        [107745] = {d = {131593}}, -- Shattered Wild Jade
        [107746] = {d = {131593}}, -- Steady Wild Jade
        [107907] = {t = 4025}, -- Glyph of Shadow
        [108789] = {t = 4016}, -- Phase Fingers
        [109077] = {t = 4016}, -- Incendiary Fireworks Launcher
        [111645] = {t = 4025}, -- Ink of Dreams
        [111646] = {t = 4025}, -- Starlight Ink
        [111830] = {t = 4025}, -- Darkmoon Card of Mists
        [111908] = {t = 4025}, -- Inscribed Fan
        [111909] = {t = 4025}, -- Inscribed Jade Fan
        [111910] = {t = 4025}, -- Inscribed Red Fan
        [111917] = {t = 4025}, -- Rain Poppy Staff
        [111918] = {t = 4025}, -- Inscribed Crane Staff
        [111919] = {t = 4025}, -- Inscribed Serpent Staff
        [111920] = {t = 4025}, -- Ghost Iron Staff
        [111921] = {t = 4025}, -- Inscribed Tiger Staff
        [112045] = {t = 4025}, -- Runescroll of Fortitude III
        [112264] = {t = 4025}, -- Glyph of the Falling Avenger
        [112265] = {t = 4025}, -- Glyph of Righteous Retreat
        [112266] = {t = 4025}, -- Glyph of Bladed Judgment
        [112429] = {t = 4025}, -- Glyph of Crow Feast
        [112430] = {t = 4025}, -- Glyph of Burning Anger
        [112437] = {t = 4025}, -- Glyph of Nimble Brew
        [112440] = {t = 4025}, -- Glyph of Paralysis
        [112442] = {t = 4025}, -- Glyph of Life Cocoon
        [112444] = {t = 4025}, -- Glyph of Touch of Karma
        [112450] = {t = 4025}, -- Glyph of Leer of the Ox
        [112451] = {t = 4025}, -- Glyph of Afterlife
        [112452] = {t = 4025}, -- Glyph of Sparring
        [112454] = {t = 4025}, -- Glyph of Detox
        [112457] = {t = 4025}, -- Glyph of Fortifying Brew
        [112458] = {t = 4025}, -- Glyph of Targeted Expulsion
        [112460] = {t = 4025}, -- Glyph of Zen Flight
        [112461] = {t = 4025}, -- Glyph of Water Roll
        [112462] = {t = 4025}, -- Glyph of Crackling Tiger Lightning
        [112463] = {t = 4025}, -- Glyph of Flying Serpent Kick
        [112464] = {t = 4025}, -- Glyph of Honor
        [112465] = {t = 4025}, -- Glyph of Jab
        [112466] = {t = 4025}, -- Glyph of Rising Tiger Kick
        [112468] = {t = 4025}, -- Glyph of Spirit Roll
        [112469] = {t = 4025}, -- Glyph of Fighting Pose
        [112883] = {t = 4025}, -- Tome of the Clear Mind
        [112996] = {t = 4025}, -- Scroll of Wisdom
        [113263] = {t = 4010, a = true}, -- Socket Bracer
        [114112] = {t = 4010, a = true}, -- Socket Gloves
        [114751] = {t = 4003}, -- Alchemist's Rejuvenation
        [114752] = {t = 4003}, -- Master Healing Potion
        [114753] = {t = 4003}, -- Potion of the Mountains
        [114754] = {t = 4003}, -- Mad Hozen Elixir
        [114755] = {t = 4003}, -- Mantid Elixir
        [114756] = {t = 4003}, -- Elixir of Weaponry
        [114757] = {t = 4003}, -- Potion of the Jade Serpent
        [114758] = {t = 4003}, -- Monk's Elixir
        [114759] = {t = 4003}, -- Elixir of the Rapids
        [114760] = {t = 4003}, -- Potion of Mogu Power
        [114761] = {t = 4003}, -- Desecrated Oil
        [114762] = {t = 4003}, -- Elixir of Perfection
        [114763] = {t = 4003}, -- Elixir of Mirrors
        [114764] = {t = 4003}, -- Elixir of Peace
        [114765] = {t = 4003}, -- Virmen's Bite
        [114766] = {t = 4003}, -- Transmute: River's Heart
        [114767] = {t = 4003}, -- Transmute: Wild Jade
        [114769] = {t = 4003}, -- Flask of Spring Blossoms
        [114770] = {t = 4003}, -- Flask of the Earth
        [114771] = {t = 4003}, -- Flask of the Warm Sun
        [114772] = {t = 4003}, -- Flask of Falling Leaves
        [114773] = {t = 4003}, -- Flask of Winter's Bite
        [114774] = {t = 4003}, -- Darkwater Potion
        [114775] = {t = 4003}, -- Master Mana Potion
        [114776] = {t = 4003}, -- Transmute: Vermilion Onyx
        [114777] = {t = 4003}, -- Transmute: Imperial Amethyst
        [114778] = {t = 4003}, -- Transmute: Sun's Radiance
        [114779] = {t = 4003}, -- Potion of Luck
        [114780] = {t = 4003}, -- Transmute: Living Steel
        [114781] = {t = 4003}, -- Transmute: Primal Diamond
        [114782] = {t = 4003}, -- Potion of Focus
        [114783] = {t = 4003}, -- Transmute: Trillium Bar
        [114784] = {t = 4003}, -- Transmute: Primordial Ruby
        [114786] = {t = 4003}, -- Alchemist's Flask
        [116497] = {t = 4018}, -- Mysterious Essence
        [116498] = {t = 4018}, -- Ethereal Shard
        [116499] = {t = 4018}, -- Sha Crystal
        [118237] = {t = 4018}, -- Mysterious Diffusion
        [118238] = {t = 4018}, -- Ethereal Shatter
        [118239] = {t = 4018}, -- Sha Shatter
        [119481] = {t = 4025}, -- Glyph of the Battle Healer
        [122015] = {t = 4025}, -- Glyph of Incite
        [122030] = {t = 4025}, -- Glyph of Mass Exorcism
        [122568] = {u = true}, -- Spiritguard Helm
        [122569] = {u = true}, -- Spiritguard Shoulders
        [122570] = {u = true}, -- Spiritguard Breastplate
        [122571] = {u = true}, -- Spiritguard Gauntlets
        [122572] = {u = true}, -- Spiritguard Legplates
        [122573] = {u = true}, -- Spiritguard Bracers
        [122574] = {u = true}, -- Spiritguard Boots
        [122575] = {u = true}, -- Spiritguard Belt
        [122576] = {t = 4010}, -- Ghost-Forged Helm
        [122577] = {t = 4010}, -- Ghost-Forged Shoulders
        [122578] = {t = 4010}, -- Ghost-Forged Breastplate
        [122579] = {t = 4010}, -- Ghost-Forged Gauntlets
        [122580] = {t = 4010}, -- Ghost-Forged Legplates
        [122581] = {t = 4010}, -- Ghost-Forged Bracers
        [122582] = {t = 4010}, -- Ghost-Forged Boots
        [122583] = {t = 4010}, -- Ghost-Forged Belt
        [122584] = {u = true}, -- Lightsteel Helm
        [122585] = {u = true}, -- Lightsteel Shoulders
        [122586] = {u = true}, -- Lightsteel Breastplate
        [122587] = {u = true}, -- Lightsteel Gauntlets
        [122588] = {u = true}, -- Lightsteel Legplates
        [122589] = {u = true}, -- Lightsteel Bracers
        [122590] = {u = true}, -- Lightsteel Boots
        [122591] = {u = true}, -- Lightsteel Belt
        [122600] = {u = true}, -- Masterwork Ghost-Forged Helm
        [122601] = {u = true}, -- Masterwork Ghost-Forged Shoulders
        [122602] = {u = true}, -- Masterwork Ghost-Forged Breastplate
        [122603] = {u = true}, -- Masterwork Ghost-Forged Gauntlets
        [122604] = {u = true}, -- Masterwork Ghost-Forged Legplates
        [122605] = {u = true}, -- Masterwork Ghost-Forged Bracers
        [122606] = {u = true}, -- Masterwork Ghost-Forged Boots
        [122607] = {u = true}, -- Masterwork Ghost-Forged Belt
        [122608] = {u = true}, -- Masterwork Lightsteel Helm
        [122609] = {u = true}, -- Masterwork Lightsteel Shoulders
        [122610] = {u = true}, -- Masterwork Lightsteel Breastplate
        [122611] = {u = true}, -- Masterwork Lightsteel Gauntlets
        [122612] = {u = true}, -- Masterwork Lightsteel Legplates
        [122613] = {u = true}, -- Masterwork Lightsteel Bracers
        [122614] = {u = true}, -- Masterwork Lightsteel Boots
        [122615] = {u = true}, -- Masterwork Lightsteel Belt
        [122633] = {t = 4010}, -- Ghostly Skeleton Key
        [122635] = {t = 4010}, -- Lightsteel Shield
        [122636] = {t = 4010}, -- Spiritguard Shield
        [122637] = {t = 4010}, -- Forgewire Axe
        [122638] = {t = 4010}, -- Ghost-Forged Blade
        [122639] = {t = 4010}, -- Phantasmal Hammer
        [122640] = {t = 4010}, -- Spiritblade Decimator
        [122641] = {t = 4010}, -- Ghost Shard
        [122661] = {t = 4030}, -- Ornate Band
        [122662] = {t = 4030}, -- Shadowfire Necklace
        [122663] = {t = 4029}, -- Scrying Roguestone
        [122664] = {t = 4029}, -- Heart of the Earth
        [122665] = {t = 4029}, -- Roguestone Shadowband
        [122666] = {t = 4029}, -- Lord's Signet
        [122667] = {t = 4029}, -- Lionsfall Ring
        [122668] = {t = 4029}, -- Band of Blood
        [122669] = {t = 4029}, -- Reflection of the Sea
        [122670] = {t = 4029}, -- Golembreaker Amulet
        [122671] = {t = 4029}, -- Widow Chain
        [122672] = {t = 4029}, -- Skymage Circle
        [122673] = {t = 4029}, -- Tiger Opal Pendant
        [122674] = {t = 4029}, -- Delicate Serpent's Eye
        [122675] = {t = 4029}, -- Bold Serpent's Eye
        [122676] = {t = 4029}, -- Brilliant Serpent's Eye
        [122677] = {t = 4029}, -- Sparkling Serpent's Eye
        [122678] = {t = 4029}, -- Solid Serpent's Eye
        [122679] = {t = 4029}, -- Subtle Serpent's Eye
        [122680] = {t = 4029}, -- Smooth Serpent's Eye
        [122681] = {t = 4029}, -- Rigid Serpent's Eye
        [122682] = {t = 4029}, -- Quick Serpent's Eye
        [122683] = {t = 4029}, -- Precise Serpent's Eye
        [122684] = {t = 4029}, -- Fractured Serpent's Eye
        [122685] = {t = 4029}, -- Flashing Serpent's Eye
        [123781] = {t = 4025}, -- Glyph of the Blazing Trail
        [124124] = {t = 4002}, -- Sha-Touched Leg Armor
        [124125] = {t = 4002}, -- Toughened Leg Armor
        [124126] = {t = 4002}, -- Brutal Leg Armor
        [124223] = {t = 4031}, -- Pounded Rice Cake
        [124224] = {t = 4031}, -- Yak Cheese Curds
        [124225] = {t = 4031}, -- Toasted Fish Jerky
        [124226] = {t = 4031}, -- Dried Peaches
        [124227] = {t = 4031}, -- Dried Needle Mushrooms
        [124228] = {t = 4031}, -- Boiled Silkworm Pupa
        [124229] = {t = 4031}, -- Red Bean Bun
        [124230] = {t = 4031}, -- Tangy Yogurt
        [124231] = {t = 4032}, -- Green Curry Fish
        [124232] = {t = 4032}, -- Peach Pie
        [124233] = {t = 4032}, -- Blanched Needle Mushrooms
        [124234] = {t = 4032}, -- Skewered Peanut Chicken
        [124442] = {t = 4025}, -- Glyph of Aspect of the Beast
        [124443] = {t = 4025}, -- Glyph of Black Ice
        [124444] = {t = 4025}, -- Glyph of Breath of Fire
        [124445] = {t = 4025}, -- Glyph of Fists of Fury
        [124446] = {t = 4025}, -- Glyph of Clash
        [124447] = {t = 4025}, -- Glyph of Enduring Healing Sphere
        [124448] = {t = 4025}, -- Glyph of Rapid Rolling
        [124449] = {t = 4025}, -- Glyph of Guard
        [124450] = {t = 4025}, -- Glyph of Mana Tea
        [124451] = {t = 4025}, -- Glyph of Zen Meditation
        [124452] = {t = 4025}, -- Glyph of Renewing Mists
        [124453] = {t = 4025}, -- Glyph of Spinning Crane Kick
        [124454] = {t = 4025}, -- Glyph of Spinning Fire Blossom
        [124455] = {t = 4025}, -- Glyph of Surging Mist
        [124456] = {t = 4025}, -- Glyph of Touch of Death
        [124457] = {t = 4025}, -- Glyph of Transcendence
        [124459] = {t = 4025}, -- Glyph of Mind Flay
        [124460] = {t = 4025}, -- Glyph of Vampiric Embrace
        [124461] = {t = 4025}, -- Glyph of Shadow Word: Death
        [124463] = {t = 4025}, -- Glyph of Fortuitous Spheres
        [124466] = {t = 4025}, -- Glyph of the Heavens
        [124549] = {t = 4002}, -- Fur Lining - Strength
        [124551] = {t = 4002, a = true}, -- Fur Lining - Agility
        [124552] = {t = 4002, a = true}, -- Fur Lining - Intellect
        [124553] = {t = 4002, a = true}, -- Fur Lining - Stamina
        [124554] = {t = 4002, a = true}, -- Fur Lining - Strength
        [124559] = {t = 4002, a = true}, -- Primal Leg Reinforcements
        [124561] = {t = 4002, a = true}, -- Draconic Leg Reinforcements
        [124563] = {t = 4002, a = true}, -- Heavy Leg Reinforcements
        [124564] = {t = 4002, a = true}, -- Primal Leg Reinforcements
        [124565] = {t = 4002, a = true}, -- Heavy Leg Reinforcements
        [124566] = {t = 4002, a = true}, -- Draconic Leg Reinforcements
        [124567] = {t = 4002}, -- Primal Leg Reinforcements
        [124568] = {t = 4002}, -- Heavy Leg Reinforcements
        [124569] = {t = 4002}, -- Draconic Leg Reinforcements
        [124571] = {t = 4002}, -- Misthide Helm
        [124572] = {t = 4002}, -- Misthide Shoulders
        [124573] = {t = 4002}, -- Misthide Chestguard
        [124574] = {t = 4002}, -- Misthide Gloves
        [124575] = {t = 4002}, -- Misthide Leggings
        [124576] = {t = 4002}, -- Misthide Bracers
        [124577] = {t = 4002}, -- Misthide Boots
        [124578] = {t = 4002}, -- Misthide Belt
        [124579] = {t = 4002}, -- Stormscale Helm
        [124580] = {t = 4002}, -- Stormscale Shoulders
        [124581] = {t = 4002}, -- Stormscale Chestguard
        [124582] = {t = 4002}, -- Stormscale Gloves
        [124583] = {t = 4002}, -- Stormscale Leggings
        [124584] = {t = 4002}, -- Stormscale Bracers
        [124585] = {t = 4002}, -- Stormscale Boots
        [124586] = {t = 4002}, -- Stormscale Belt
        [124627] = {t = 4002}, -- Mist-Touched Leather
        [124628] = {t = 4002}, -- Sha Armor Kit
        [124635] = {t = 4002}, -- Misthide Drape
        [124636] = {t = 4002}, -- Stormscale Drape
        [124637] = {t = 4002}, -- Quick Strike Cloak
        [125067] = {t = 4032}, -- Perfectly Cooked Instant Noodles
        [125078] = {t = 4032}, -- Roasted Barley Tea
        [125080] = {t = 4032}, -- Pearl Milk Tea
        [125117] = {t = 4032}, -- Sliced Peaches
        [125121] = {t = 4032}, -- Wildfowl Ginseng Soup
        [125122] = {t = 4032}, -- Rice Pudding
        [125481] = {t = 4006, a = true}, -- Lightweave Embroidery
        [125482] = {t = 4006, a = true}, -- Darkglow Embroidery
        [125483] = {t = 4006, a = true}, -- Swordguard Embroidery
        [125496] = {t = 4006, a = true}, -- Master's Spellthread
        [125497] = {t = 4006, a = true}, -- Sanctified Spellthread
        [125523] = {t = 4006}, -- Windwool Hood
        [125524] = {t = 4006}, -- Windwool Shoulders
        [125525] = {t = 4006}, -- Windwool Tunic
        [125526] = {t = 4006}, -- Windwool Gloves
        [125527] = {t = 4006}, -- Windwool Pants
        [125528] = {t = 4006}, -- Windwool Bracers
        [125529] = {t = 4006}, -- Windwool Boots
        [125530] = {t = 4006}, -- Windwool Belt
        [125551] = {t = 4006}, -- Bolt of Windwool Cloth
        [125552] = {t = 4006}, -- Pearlescent Spellthread
        [125553] = {t = 4006}, -- Cerulean Spellthread
        [125557] = {t = 4006}, -- Imperial Silk
        [126153] = {t = 4025}, -- Glyph of Confession
        [126392] = {t = 4016}, -- Goblin Glider
        [126687] = {t = 4025}, -- Glyph of Holy Resurrection
        [126696] = {t = 4025}, -- Glyph of the Val'kyr
        [126701] = {t = 4025}, -- Glyph of Direction
        [126704] = {t = 4025}, -- Glyph of Marking
        [126731] = {t = 4016}, -- Synapse Springs
        [126800] = {t = 4025}, -- Glyph of Shadowy Friends
        [126801] = {t = 4025}, -- Glyph of Fetch
        [126869] = {t = 4010}, -- Folded Ghost Iron
        [126988] = {t = 4025}, -- Origami Crane
        [126989] = {t = 4025}, -- Origami Frog
        [126994] = {t = 4025}, -- Greater Ox Horn Inscription
        [126995] = {t = 4025}, -- Greater Crane Wing Inscription
        [126996] = {t = 4025}, -- Greater Tiger Claw Inscription
        [126997] = {t = 4025}, -- Greater Tiger Fang Inscription
        [127007] = {t = 4025}, -- Yu'lon Kite
        [127009] = {t = 4025}, -- Chi-ji Kite
        [127016] = {t = 4025}, -- Tiger Fang Inscription
        [127017] = {t = 4025}, -- Tiger Claw Inscription
        [127018] = {t = 4025}, -- Crane Wing Inscription
        [127019] = {t = 4025}, -- Ox Horn Inscription
        [127020] = {t = 4025}, -- Secret Tiger Fang Inscription
        [127021] = {t = 4025}, -- Secret Tiger Claw Inscription
        [127023] = {t = 4025}, -- Secret Crane Wing Inscription
        [127024] = {t = 4025}, -- Secret Ox Horn Inscription
        [127113] = {t = 4016}, -- Ghost Iron Bolts
        [127114] = {t = 4016}, -- High-Explosive Gunpowder
        [127378] = {t = 4025}, -- Commissioned Painting
        [127391] = {t = 4025}, -- Engraved Jade Disk
        [127481] = {t = 4025}, -- Inscribed Monument
        [127625] = {t = 4025}, -- Glyph of Lightspring
        [128922] = {t = 4025}, -- Portrait of Madam Goya
        [130325] = {t = 4006}, -- Song of Harmony
        [130326] = {t = 4003}, -- Riddle of Steel
        [130407] = {t = 4025}, -- Mystery of the Mists
        [130655] = {t = 4029}, -- Tense Roguestone
        [130656] = {t = 4029}, -- Assassin's Roguestone
        [130657] = {d = {131593}}, -- Assassin's Imperial Amethyst
        [130658] = {d = {131593}}, -- Tense Imperial Amethyst
        [130758] = {t = 4018}, -- Enchant Shield - Greater Parry
        [131152] = {t = 4025}, -- Glyph of the Cheetah
        [131211] = {t = 4016}, -- Flashing Tinker's Gear
        [131212] = {t = 4016}, -- Fractured Tinker's Gear
        [131213] = {t = 4016}, -- Precise Tinker's Gear
        [131214] = {t = 4016}, -- Quick Tinker's Gear
        [131215] = {t = 4016}, -- Rigid Tinker's Gear
        [131216] = {t = 4016}, -- Smooth Tinker's Gear
        [131217] = {t = 4016}, -- Sparkling Tinker's Gear
        [131218] = {t = 4016}, -- Subtle Tinker's Gear
        [131353] = {t = 4016}, -- Pandaria Fireworks
        [131563] = {t = 4016}, -- Tinker's Kit
        [131593] = {t = 4023}, -- River's Heart
        [131686] = {t = 4023}, -- Primordial Ruby
        [131688] = {t = 4023}, -- Wild Jade
        [131690] = {t = 4023}, -- Vermilion Onyx
        [131691] = {t = 4023}, -- Imperial Amethyst
        [131695] = {t = 4023}, -- Sun's Radiance
        [131759] = {t = 4023}, -- Secrets of the Stone
        [131865] = {t = 4002}, -- Magnificent Hide
        [132167] = {t = 4025}, -- Glyph of Blackout Kick
        [134585] = {t = 4006}, -- Bipsi's Gloves
        [135561] = {t = 4025}, -- Glyph of Gateway Attunement
        [136197] = {t = 4003}, -- Zen Alchemist Stone
        [136269] = {t = 4023}, -- Resplendent Serpent's Eye
        [136270] = {t = 4023}, -- Lucent Serpent's Eye
        [136272] = {t = 4023}, -- Willful Serpent's Eye
        [136273] = {t = 4023}, -- Tense Serpent's Eye
        [136274] = {t = 4023}, -- Assassin's Serpent's Eye
        [136275] = {t = 4023}, -- Mysterious Serpent's Eye
        [137766] = {t = 4010}, -- Haunted Steel Greaves
        [137767] = {t = 4010}, -- Haunted Steel Headcover
        [137768] = {t = 4010}, -- Haunted Steel Treads
        [137769] = {t = 4010}, -- Haunted Steel Greathelm
        [137770] = {t = 4010}, -- Haunted Steel Warboots
        [137771] = {t = 4010}, -- Haunted Steel Headguard
        [137772] = {t = 4010}, -- Crafted Dreadful Gladiator's Scaled Gauntlets
        [137773] = {t = 4010}, -- Crafted Dreadful Gladiator's Scaled Helm
        [137774] = {t = 4010}, -- Crafted Dreadful Gladiator's Scaled Legguards
        [137775] = {t = 4010}, -- Crafted Dreadful Gladiator's Scaled Shoulders
        [137776] = {t = 4010}, -- Crafted Dreadful Gladiator's Clasp of Cruelty
        [137777] = {t = 4010}, -- Crafted Dreadful Gladiator's Clasp of Meditation
        [137778] = {t = 4010}, -- Crafted Dreadful Gladiator's Greaves of Alacrity
        [137779] = {t = 4010}, -- Crafted Dreadful Gladiator's Greaves of Meditation
        [137780] = {t = 4010}, -- Crafted Dreadful Gladiator's Bracers of Prowess
        [137781] = {t = 4010}, -- Crafted Dreadful Gladiator's Bracers of Meditation
        [137782] = {t = 4010}, -- Crafted Dreadful Gladiator's Ornamented Chestguard
        [137783] = {t = 4010}, -- Crafted Dreadful Gladiator's Ornamented Gloves
        [137784] = {t = 4010}, -- Crafted Dreadful Gladiator's Ornamented Headcover
        [137785] = {t = 4010}, -- Crafted Dreadful Gladiator's Ornamented Legplates
        [137786] = {t = 4010}, -- Crafted Dreadful Gladiator's Ornamented Spaulders
        [137787] = {t = 4010}, -- Crafted Dreadful Gladiator's Girdle of Accuracy
        [137788] = {t = 4010}, -- Crafted Dreadful Gladiator's Girdle of Prowess
        [137789] = {t = 4010}, -- Crafted Dreadful Gladiator's Warboots of Cruelty
        [137790] = {t = 4010}, -- Crafted Dreadful Gladiator's Warboots of Alacrity
        [137791] = {t = 4010}, -- Crafted Dreadful Gladiator's Armplates of Proficiency
        [137792] = {t = 4010}, -- Crafted Dreadful Gladiator's Armplates of Alacrity
        [137793] = {t = 4010}, -- Crafted Dreadful Gladiator's Plate Chestpiece
        [137794] = {t = 4010}, -- Crafted Dreadful Gladiator's Plate Gauntlets
        [137795] = {t = 4010}, -- Crafted Dreadful Gladiator's Plate Helm
        [137796] = {t = 4010}, -- Crafted Dreadful Gladiator's Plate Legguards
        [137797] = {t = 4010}, -- Crafted Dreadful Gladiator's Plate Shoulders
        [137809] = {t = 4002}, -- Crafted Dreadful Gladiator's Dragonhide Gloves
        [137810] = {t = 4002}, -- Crafted Dreadful Gladiator's Dragonhide Helm
        [137811] = {t = 4002}, -- Crafted Dreadful Gladiator's Dragonhide Legguards
        [137812] = {t = 4002}, -- Crafted Dreadful Gladiator's Dragonhide Robes
        [137813] = {t = 4002}, -- Crafted Dreadful Gladiator's Dragonhide Spaulders
        [137814] = {t = 4002}, -- Crafted Dreadful Gladiator's Belt of Meditation
        [137815] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Footguards of Meditation
        [137816] = {t = 4002}, -- Crafted Dreadful Gladiator's Bindings of Meditation
        [137817] = {t = 4002}, -- Crafted Dreadful Gladiator's Kodohide Gloves
        [137818] = {t = 4002}, -- Crafted Dreadful Gladiator's Kodohide Helm
        [137819] = {t = 4002}, -- Crafted Dreadful Gladiator's Kodohide Legguards
        [137820] = {t = 4002}, -- Crafted Dreadful Gladiator's Kodohide Robes
        [137821] = {t = 4002}, -- Crafted Dreadful Gladiator's Kodohide Spaulders
        [137822] = {t = 4002}, -- Crafted Dreadful Gladiator's Belt of Cruelty
        [137823] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Footguards of Alacrity
        [137824] = {t = 4002}, -- Crafted Dreadful Gladiator's Bindings of Prowess
        [137825] = {t = 4002}, -- Crafted Dreadful Gladiator's Wyrmhide Gloves
        [137826] = {t = 4002}, -- Crafted Dreadful Gladiator's Wyrmhide Helm
        [137827] = {t = 4002}, -- Crafted Dreadful Gladiator's Wyrmhide Legguards
        [137828] = {t = 4002}, -- Crafted Dreadful Gladiator's Wyrmhide Robes
        [137829] = {t = 4002}, -- Crafted Dreadful Gladiator's Wyrmhide Spaulders
        [137830] = {t = 4002}, -- Crafted Dreadful Gladiator's Waistband of Cruelty
        [137831] = {t = 4002}, -- Crafted Dreadful Gladiator's Boots of Alacrity
        [137832] = {t = 4002}, -- Crafted Dreadful Gladiator's Armwraps of Accuracy
        [137833] = {t = 4002}, -- Crafted Dreadful Gladiator's Ironskin Gloves
        [137834] = {t = 4002}, -- Crafted Dreadful Gladiator's Ironskin Helm
        [137835] = {t = 4002}, -- Crafted Dreadful Gladiator's Ironskin Legguards
        [137836] = {t = 4002}, -- Crafted Dreadful Gladiator's Ironskin Spaulders
        [137837] = {t = 4002}, -- Crafted Dreadful Gladiator's Ironskin Tunic
        [137838] = {t = 4002}, -- Crafted Dreadful Gladiator's Copperskin Gloves
        [137839] = {t = 4002}, -- Crafted Dreadful Gladiator's Copperskin Helm
        [137840] = {t = 4002}, -- Crafted Dreadful Gladiator's Copperskin Legguards
        [137841] = {t = 4002}, -- Crafted Dreadful Gladiator's Copperskin Spaulders
        [137842] = {t = 4002}, -- Crafted Dreadful Gladiator's Copperskin Tunic
        [137843] = {t = 4002}, -- Crafted Dreadful Gladiator's Waistband of Accuracy
        [137844] = {t = 4002}, -- Crafted Dreadful Gladiator's Boots of Cruelty
        [137845] = {t = 4002}, -- Crafted Dreadful Gladiator's Armwraps of Alacrity
        [137846] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Tunic
        [137847] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Gloves
        [137848] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Helm
        [137849] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Legguards
        [137850] = {t = 4002}, -- Crafted Dreadful Gladiator's Leather Spaulders
        [137851] = {t = 4002}, -- Crafted Dreadful Gladiator's Links of Cruelty
        [137852] = {t = 4002}, -- Crafted Dreadful Gladiator's Links of Accuracy
        [137853] = {t = 4002}, -- Crafted Dreadful Gladiator's Sabatons of Cruelty
        [137854] = {t = 4002}, -- Crafted Dreadful Gladiator's Sabatons of Alacrity
        [137855] = {t = 4002}, -- Crafted Dreadful Gladiator's Wristguards of Alacrity
        [137856] = {t = 4002}, -- Crafted Dreadful Gladiator's Wristguards of Accuracy
        [137857] = {t = 4002}, -- Crafted Dreadful Gladiator's Chain Armor
        [137858] = {t = 4002}, -- Crafted Dreadful Gladiator's Chain Gauntlets
        [137859] = {t = 4002}, -- Crafted Dreadful Gladiator's Chain Helm
        [137860] = {t = 4002}, -- Crafted Dreadful Gladiator's Chain Leggings
        [137861] = {t = 4002}, -- Crafted Dreadful Gladiator's Chain Spaulders
        [137862] = {t = 4002}, -- Crafted Dreadful Gladiator's Waistguard of Meditation
        [137863] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Footguards of Alacrity
        [137864] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Footguards of Meditation
        [137865] = {t = 4002}, -- Crafted Dreadful Gladiator's Armbands of Prowess
        [137866] = {t = 4002}, -- Crafted Dreadful Gladiator's Armbands of Meditation
        [137867] = {t = 4002}, -- Crafted Dreadful Gladiator's Ringmail Armor
        [137868] = {t = 4002}, -- Crafted Dreadful Gladiator's Ringmail Gauntlets
        [137869] = {t = 4002}, -- Crafted Dreadful Gladiator's Ringmail Helm
        [137870] = {t = 4002}, -- Crafted Dreadful Gladiator's Ringmail Leggings
        [137871] = {t = 4002}, -- Crafted Dreadful Gladiator's Ringmail Spaulders
        [137872] = {t = 4002}, -- Crafted Dreadful Gladiator's Linked Armor
        [137873] = {t = 4002}, -- Crafted Dreadful Gladiator's Linked Gauntlets
        [137874] = {t = 4002}, -- Crafted Dreadful Gladiator's Linked Helm
        [137875] = {t = 4002}, -- Crafted Dreadful Gladiator's Linked Leggings
        [137876] = {t = 4002}, -- Crafted Dreadful Gladiator's Linked Spaulders
        [137877] = {t = 4002}, -- Crafted Dreadful Gladiator's Waistguard of Cruelty
        [137878] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Armor
        [137879] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Gauntlets
        [137880] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Helm
        [137881] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Leggings
        [137882] = {t = 4002}, -- Crafted Dreadful Gladiator's Mail Spaulders
        [137907] = {t = 4006}, -- Crafted Dreadful Gladiator's Cape of Cruelty
        [137908] = {t = 4006}, -- Crafted Dreadful Gladiator's Cape of Prowess
        [137909] = {t = 4006}, -- Crafted Dreadful Gladiator's Cord of Cruelty
        [137910] = {t = 4006}, -- Crafted Dreadful Gladiator's Cord of Accuracy
        [137911] = {t = 4006}, -- Crafted Dreadful Gladiator's Cord of Meditation
        [137912] = {t = 4006}, -- Crafted Dreadful Gladiator's Treads of Cruelty
        [137913] = {t = 4006}, -- Crafted Dreadful Gladiator's Treads of Alacrity
        [137914] = {t = 4006}, -- Crafted Dreadful Gladiator's Treads of Meditation
        [137915] = {t = 4006}, -- Crafted Dreadful Gladiator's Cuffs of Accuracy
        [137916] = {t = 4006}, -- Crafted Dreadful Gladiator's Cuffs of Prowess
        [137917] = {t = 4006}, -- Crafted Dreadful Gladiator's Cuffs of Meditation
        [137918] = {t = 4006}, -- Crafted Dreadful Gladiator's Drape of Cruelty
        [137919] = {t = 4006}, -- Crafted Dreadful Gladiator's Drape of Prowess
        [137920] = {t = 4006}, -- Crafted Dreadful Gladiator's Drape of Meditation
        [137921] = {t = 4006}, -- Crafted Dreadful Gladiator's Silk Handguards
        [137922] = {t = 4006}, -- Crafted Dreadful Gladiator's Silk Cowl
        [137923] = {t = 4006}, -- Crafted Dreadful Gladiator's Silk Trousers
        [137924] = {t = 4006}, -- Crafted Dreadful Gladiator's Silk Robe
        [137925] = {t = 4006}, -- Crafted Dreadful Gladiator's Silk Amice
        [137926] = {t = 4006}, -- Crafted Dreadful Gladiator's Mooncloth Gloves
        [137927] = {t = 4006}, -- Crafted Dreadful Gladiator's Mooncloth Helm
        [137928] = {t = 4006}, -- Crafted Dreadful Gladiator's Mooncloth Leggings
        [137929] = {t = 4006}, -- Crafted Dreadful Gladiator's Mooncloth Robe
        [137930] = {t = 4006}, -- Crafted Dreadful Gladiator's Mooncloth Mantle
        [137931] = {t = 4006}, -- Crafted Dreadful Gladiator's Satin Gloves
        [137932] = {t = 4006}, -- Crafted Dreadful Gladiator's Satin Hood
        [137933] = {t = 4006}, -- Crafted Dreadful Gladiator's Satin Leggings
        [137934] = {t = 4006}, -- Crafted Dreadful Gladiator's Satin Robe
        [137935] = {t = 4006}, -- Crafted Dreadful Gladiator's Satin Mantle
        [137936] = {t = 4006}, -- Crafted Dreadful Gladiator's Cloak of Alacrity
        [137937] = {t = 4006}, -- Crafted Dreadful Gladiator's Cloak of Prowess
        [137938] = {t = 4006}, -- Crafted Dreadful Gladiator's Felweave Handguards
        [137939] = {t = 4006}, -- Crafted Dreadful Gladiator's Felweave Cowl
        [137940] = {t = 4006}, -- Crafted Dreadful Gladiator's Felweave Trousers
        [137941] = {t = 4006}, -- Crafted Dreadful Gladiator's Felweave Raiment
        [137942] = {t = 4006}, -- Crafted Dreadful Gladiator's Felweave Amice
        [138589] = {t = 4002}, -- Quilen Hide Boots
        [138590] = {t = 4002}, -- Quilen Hide Helm
        [138591] = {t = 4002}, -- Dreadrunner Sabatons
        [138592] = {t = 4002}, -- Dreadrunner Helm
        [138593] = {t = 4002}, -- Spirit Keeper Footguards
        [138594] = {t = 4002}, -- Spirit Keeper Helm
        [138595] = {t = 4002}, -- Cloud Serpent Sabatons
        [138596] = {t = 4002}, -- Cloud Serpent Helm
        [138597] = {t = 4006}, -- Falling Blossom Treads
        [138598] = {t = 4006}, -- Falling Blossom Cowl
        [138599] = {t = 4006}, -- Falling Blossom Sandals
        [138600] = {t = 4006}, -- Falling Blossom Hood
        [138878] = {t = 4010}, -- Black Planar Edge, Reborn
        [138879] = {t = 4010}, -- Mooncleaver, Reborn
        [138880] = {t = 4010}, -- Wicked Edge of the Planes, Reborn
        [138881] = {t = 4010}, -- Bloodmoon, Reborn
        [138884] = {t = 4010}, -- Deep Thunder, Reborn
        [138885] = {t = 4010}, -- Dragonmaw, Reborn
        [138886] = {t = 4010}, -- Dragonstrike, Reborn
        [138887] = {t = 4010}, -- Stormherald, Reborn
        [138890] = {t = 4010}, -- Blazeguard, Reborn
        [138891] = {t = 4010}, -- Lionheart Champion, Reborn
        [138892] = {t = 4010}, -- Blazefury, Reborn
        [138893] = {t = 4010}, -- Lionheart Executioner, Reborn
        [139745] = {t = 4010}, -- Training Project: Ghost Iron Pins
        [139746] = {t = 4010}, -- Training Project: Simple Eating Utensils
        [139747] = {t = 4010}, -- Training Project: Ghost Iron Wok
        [139748] = {t = 4010}, -- Training Project: Ghost Iron Ladle
        [139749] = {t = 4010}, -- Training Project: Ghost Iron Poker
        [139750] = {t = 4010}, -- Training Project: Ghost Iron Hook
        [139751] = {t = 4010}, -- Training Project: Ghost Iron Spatulas
        [139753] = {t = 4010}, -- Training Project: Decorative Spoons
        [139754] = {t = 4010}, -- Training Project: Ghost Iron Spade
        [139755] = {t = 4010}, -- Training Project: Ghost Iron Needles
        [139756] = {t = 4010}, -- Training Project: Ghost Iron Barrel
        [139757] = {t = 4010}, -- Training Project: Ghost Iron Saw
        [139759] = {t = 4010}, -- Training Project: Ghost Iron Wire
        [139760] = {t = 4010}, -- Training Project: Ghost Iron Pot
        [139761] = {t = 4010}, -- Training Project: Ghost Iron Cups
        [139762] = {t = 4010}, -- Training Project: Ghost Iron Bowls
        [139763] = {t = 4010}, -- Training Project: Ghost Iron Bells
        [139764] = {t = 4010}, -- Training Project: Ghost Iron Crate
        [140165] = {t = 4010}, -- Training Project: Ghost Iron Picks
        [140166] = {t = 4010}, -- Training Project: Ghost Iron Frames
        [140167] = {t = 4010}, -- Training Project: Ghost Iron Pans
        [140168] = {t = 4010}, -- Training Project: Ghost Iron Statue
        [140185] = {t = 4002}, -- Magnificent Hide Pack
        [140841] = {t = 4010}, -- Crafted Dreadful Gladiator's Scaled Chestpiece
        [140842] = {t = 4010}, -- Crafted Dreadful Gladiator's Dreadplate Shoulders
        [140843] = {t = 4010}, -- Crafted Dreadful Gladiator's Dreadplate Legguards
        [140844] = {t = 4010}, -- Crafted Dreadful Gladiator's Dreadplate Helm
        [140845] = {t = 4010}, -- Crafted Dreadful Gladiator's Dreadplate Gauntlets
        [140846] = {t = 4010}, -- Crafted Dreadful Gladiator's Dreadplate Chestpiece
        [142951] = {t = 4006}, -- White Cloud Leggings
        [142952] = {t = 4002}, -- Pennyroyal Leggings
        [142953] = {t = 4002}, -- Krasari Prowler Britches
        [142954] = {t = 4010}, -- Blessed Trillium Greaves
        [142955] = {t = 4006}, -- Leggings of the Night Sky
        [142956] = {t = 4002}, -- Snow Lily Britches
        [142957] = {t = 4002}, -- Gorge Stalker Legplates
        [142958] = {t = 4010}, -- Protector's Trillium Legguards
        [142959] = {t = 4010}, -- Avenger's Trillium Legplates
        [142960] = {t = 4006}, -- White Cloud Belt
        [142961] = {t = 4002}, -- Pennyroyal Belt
        [142962] = {t = 4002}, -- Krasari Prowler Belt
        [142963] = {t = 4010}, -- Blessed Trillium Belt
        [142964] = {t = 4006}, -- Belt of the Night Sky
        [142965] = {t = 4002}, -- Snow Lily Belt
        [142966] = {t = 4002}, -- Gorge Stalker Belt
        [142967] = {t = 4010}, -- Protector's Trillium Waistguard
        [142968] = {t = 4010}, -- Avenger's Trillium Waistplate
        [142976] = {t = 4002}, -- Hardened Magnificent Hide
        [143011] = {t = 4006}, -- Celestial Cloth
        [143053] = {t = 4006}, -- Crafted Malevolent Gladiator's Cape of Cruelty
        [143054] = {t = 4006}, -- Crafted Malevolent Gladiator's Cape of Prowess
        [143055] = {t = 4006}, -- Crafted Malevolent Gladiator's Cord of Cruelty
        [143056] = {t = 4006}, -- Crafted Malevolent Gladiator's Cord of Accuracy
        [143057] = {t = 4006}, -- Crafted Malevolent Gladiator's Cord of Meditation
        [143058] = {t = 4006}, -- Crafted Malevolent Gladiator's Treads of Cruelty
        [143059] = {t = 4006}, -- Crafted Malevolent Gladiator's Treads of Alacrity
        [143060] = {t = 4006}, -- Crafted Malevolent Gladiator's Treads of Meditation
        [143061] = {t = 4006}, -- Crafted Malevolent Gladiator's Cuffs of Accuracy
        [143062] = {t = 4006}, -- Crafted Malevolent Gladiator's Cuffs of Prowess
        [143063] = {t = 4006}, -- Crafted Malevolent Gladiator's Cuffs of Meditation
        [143064] = {t = 4006}, -- Crafted Malevolent Gladiator's Drape of Cruelty
        [143065] = {t = 4006}, -- Crafted Malevolent Gladiator's Drape of Prowess
        [143066] = {t = 4006}, -- Crafted Malevolent Gladiator's Drape of Meditation
        [143067] = {t = 4006}, -- Crafted Malevolent Gladiator's Silk Handguards
        [143068] = {t = 4006}, -- Crafted Malevolent Gladiator's Silk Cowl
        [143069] = {t = 4006}, -- Crafted Malevolent Gladiator's Silk Trousers
        [143070] = {t = 4006}, -- Crafted Malevolent Gladiator's Silk Robe
        [143071] = {t = 4006}, -- Crafted Malevolent Gladiator's Silk Amice
        [143072] = {t = 4006}, -- Crafted Malevolent Gladiator's Mooncloth Gloves
        [143073] = {t = 4006}, -- Crafted Malevolent Gladiator's Mooncloth Helm
        [143074] = {t = 4006}, -- Crafted Malevolent Gladiator's Mooncloth Leggings
        [143075] = {t = 4006}, -- Crafted Malevolent Gladiator's Mooncloth Robe
        [143076] = {t = 4006}, -- Crafted Malevolent Gladiator's Mooncloth Mantle
        [143077] = {t = 4006}, -- Crafted Malevolent Gladiator's Satin Gloves
        [143078] = {t = 4006}, -- Crafted Malevolent Gladiator's Satin Hood
        [143079] = {t = 4006}, -- Crafted Malevolent Gladiator's Satin Leggings
        [143080] = {t = 4006}, -- Crafted Malevolent Gladiator's Satin Robe
        [143081] = {t = 4006}, -- Crafted Malevolent Gladiator's Satin Mantle
        [143082] = {t = 4006}, -- Crafted Malevolent Gladiator's Cloak of Alacrity
        [143083] = {t = 4006}, -- Crafted Malevolent Gladiator's Cloak of Prowess
        [143084] = {t = 4006}, -- Crafted Malevolent Gladiator's Felweave Handguards
        [143085] = {t = 4006}, -- Crafted Malevolent Gladiator's Felweave Cowl
        [143086] = {t = 4006}, -- Crafted Malevolent Gladiator's Felweave Trousers
        [143087] = {t = 4006}, -- Crafted Malevolent Gladiator's Felweave Raiment
        [143088] = {t = 4006}, -- Crafted Malevolent Gladiator's Felweave Amice
        [143089] = {t = 4002}, -- Crafted Malevolent Gladiator's Dragonhide Gloves
        [143090] = {t = 4002}, -- Crafted Malevolent Gladiator's Dragonhide Helm
        [143091] = {t = 4002}, -- Crafted Malevolent Gladiator's Dragonhide Legguards
        [143092] = {t = 4002}, -- Crafted Malevolent Gladiator's Dragonhide Robes
        [143093] = {t = 4002}, -- Crafted Malevolent Gladiator's Dragonhide Spaulders
        [143094] = {t = 4002}, -- Crafted Malevolent Gladiator's Belt of Meditation
        [143095] = {t = 4002}, -- Crafted Malevolent Gladiator's Footguards of Meditation
        [143096] = {t = 4002}, -- Crafted Malevolent Gladiator's Bindings of Meditation
        [143097] = {t = 4002}, -- Crafted Malevolent Gladiator's Kodohide Gloves
        [143098] = {t = 4002}, -- Crafted Malevolent Gladiator's Kodohide Helm
        [143099] = {t = 4002}, -- Crafted Malevolent Gladiator's Kodohide Legguards
        [143100] = {t = 4002}, -- Crafted Malevolent Gladiator's Kodohide Robes
        [143101] = {t = 4002}, -- Crafted Malevolent Gladiator's Kodohide Spaulders
        [143102] = {t = 4002}, -- Crafted Malevolent Gladiator's Belt of Cruelty
        [143103] = {t = 4002}, -- Crafted Malevolent Gladiator's Footguards of Alacrity
        [143104] = {t = 4002}, -- Crafted Malevolent Gladiator's Bindings of Prowess
        [143105] = {t = 4002}, -- Crafted Malevolent Gladiator's Wyrmhide Gloves
        [143106] = {t = 4002}, -- Crafted Malevolent Gladiator's Wyrmhide Helm
        [143107] = {t = 4002}, -- Crafted Malevolent Gladiator's Wyrmhide Legguards
        [143108] = {t = 4002}, -- Crafted Malevolent Gladiator's Wyrmhide Robes
        [143109] = {t = 4002}, -- Crafted Malevolent Gladiator's Wyrmhide Spaulders
        [143110] = {t = 4002}, -- Crafted Malevolent Gladiator's Waistband of Cruelty
        [143111] = {t = 4002}, -- Crafted Malevolent Gladiator's Boots of Alacrity
        [143112] = {t = 4002}, -- Crafted Malevolent Gladiator's Armwraps of Accuracy
        [143113] = {t = 4002}, -- Crafted Malevolent Gladiator's Ironskin Gloves
        [143114] = {t = 4002}, -- Crafted Malevolent Gladiator's Ironskin Helm
        [143115] = {t = 4002}, -- Crafted Malevolent Gladiator's Ironskin Legguards
        [143116] = {t = 4002}, -- Crafted Malevolent Gladiator's Ironskin Spaulders
        [143117] = {t = 4002}, -- Crafted Malevolent Gladiator's Ironskin Tunic
        [143118] = {t = 4002}, -- Crafted Malevolent Gladiator's Copperskin Gloves
        [143119] = {t = 4002}, -- Crafted Malevolent Gladiator's Copperskin Helm
        [143120] = {t = 4002}, -- Crafted Malevolent Gladiator's Copperskin Legguards
        [143121] = {t = 4002}, -- Crafted Malevolent Gladiator's Copperskin Spaulders
        [143122] = {t = 4002}, -- Crafted Malevolent Gladiator's Copperskin Tunic
        [143123] = {t = 4002}, -- Crafted Malevolent Gladiator's Waistband of Accuracy
        [143124] = {t = 4002}, -- Crafted Malevolent Gladiator's Boots of Cruelty
        [143125] = {t = 4002}, -- Crafted Malevolent Gladiator's Armwraps of Alacrity
        [143126] = {t = 4002}, -- Crafted Malevolent Gladiator's Leather Tunic
        [143127] = {t = 4002}, -- Crafted Malevolent Gladiator's Leather Gloves
        [143128] = {t = 4002}, -- Crafted Malevolent Gladiator's Leather Helm
        [143129] = {t = 4002}, -- Crafted Malevolent Gladiator's Leather Legguards
        [143130] = {t = 4002}, -- Crafted Malevolent Gladiator's Leather Spaulders
        [143131] = {t = 4002}, -- Crafted Malevolent Gladiator's Links of Cruelty
        [143132] = {t = 4002}, -- Crafted Malevolent Gladiator's Links of Accuracy
        [143133] = {t = 4002}, -- Crafted Malevolent Gladiator's Sabatons of Cruelty
        [143134] = {t = 4002}, -- Crafted Malevolent Gladiator's Sabatons of Alacrity
        [143135] = {t = 4002}, -- Crafted Malevolent Gladiator's Wristguards of Alacrity
        [143136] = {t = 4002}, -- Crafted Malevolent Gladiator's Wristguards of Accuracy
        [143137] = {t = 4002}, -- Crafted Malevolent Gladiator's Chain Armor
        [143138] = {t = 4002}, -- Crafted Malevolent Gladiator's Chain Gauntlets
        [143139] = {t = 4002}, -- Crafted Malevolent Gladiator's Chain Helm
        [143140] = {t = 4002}, -- Crafted Malevolent Gladiator's Chain Leggings
        [143141] = {t = 4002}, -- Crafted Malevolent Gladiator's Chain Spaulders
        [143142] = {t = 4002}, -- Crafted Malevolent Gladiator's Waistguard of Meditation
        [143143] = {t = 4002}, -- Crafted Malevolent Gladiator's Footguards of Alacrity
        [143144] = {t = 4002}, -- Crafted Malevolent Gladiator's Footguards of Meditation
        [143145] = {t = 4002}, -- Crafted Malevolent Gladiator's Armbands of Prowess
        [143146] = {t = 4002}, -- Crafted Malevolent Gladiator's Armbands of Meditation
        [143147] = {t = 4002}, -- Crafted Malevolent Gladiator's Ringmail Armor
        [143148] = {t = 4002}, -- Crafted Malevolent Gladiator's Ringmail Gauntlets
        [143149] = {t = 4002}, -- Crafted Malevolent Gladiator's Ringmail Helm
        [143150] = {t = 4002}, -- Crafted Malevolent Gladiator's Ringmail Leggings
        [143151] = {t = 4002}, -- Crafted Malevolent Gladiator's Ringmail Spaulders
        [143152] = {t = 4002}, -- Crafted Malevolent Gladiator's Linked Armor
        [143153] = {t = 4002}, -- Crafted Malevolent Gladiator's Linked Gauntlets
        [143154] = {t = 4002}, -- Crafted Malevolent Gladiator's Linked Helm
        [143155] = {t = 4002}, -- Crafted Malevolent Gladiator's Linked Leggings
        [143156] = {t = 4002}, -- Crafted Malevolent Gladiator's Linked Spaulders
        [143157] = {t = 4002}, -- Crafted Malevolent Gladiator's Waistguard of Cruelty
        [143158] = {t = 4002}, -- Crafted Malevolent Gladiator's Mail Armor
        [143159] = {t = 4002}, -- Crafted Malevolent Gladiator's Mail Gauntlets
        [143160] = {t = 4002}, -- Crafted Malevolent Gladiator's Mail Helm
        [143161] = {t = 4002}, -- Crafted Malevolent Gladiator's Mail Leggings
        [143162] = {t = 4002}, -- Crafted Malevolent Gladiator's Mail Spaulders
        [143163] = {t = 4010}, -- Crafted Malevolent Gladiator's Dreadplate Chestpiece
        [143164] = {t = 4010}, -- Crafted Malevolent Gladiator's Dreadplate Gauntlets
        [143165] = {t = 4010}, -- Crafted Malevolent Gladiator's Dreadplate Helm
        [143166] = {t = 4010}, -- Crafted Malevolent Gladiator's Dreadplate Legguards
        [143167] = {t = 4010}, -- Crafted Malevolent Gladiator's Dreadplate Shoulders
        [143168] = {t = 4010}, -- Crafted Malevolent Gladiator's Scaled Chestpiece
        [143169] = {t = 4010}, -- Crafted Malevolent Gladiator's Scaled Gauntlets
        [143170] = {t = 4010}, -- Crafted Malevolent Gladiator's Scaled Helm
        [143171] = {t = 4010}, -- Crafted Malevolent Gladiator's Scaled Legguards
        [143172] = {t = 4010}, -- Crafted Malevolent Gladiator's Scaled Shoulders
        [143173] = {t = 4010}, -- Crafted Malevolent Gladiator's Clasp of Cruelty
        [143174] = {t = 4010}, -- Crafted Malevolent Gladiator's Clasp of Meditation
        [143175] = {t = 4010}, -- Crafted Malevolent Gladiator's Greaves of Alacrity
        [143176] = {t = 4010}, -- Crafted Malevolent Gladiator's Greaves of Meditation
        [143177] = {t = 4010}, -- Crafted Malevolent Gladiator's Bracers of Prowess
        [143178] = {t = 4010}, -- Crafted Malevolent Gladiator's Bracers of Meditation
        [143179] = {t = 4010}, -- Crafted Malevolent Gladiator's Ornamented Chestguard
        [143180] = {t = 4010}, -- Crafted Malevolent Gladiator's Ornamented Gloves
        [143181] = {t = 4010}, -- Crafted Malevolent Gladiator's Ornamented Headcover
        [143182] = {t = 4010}, -- Crafted Malevolent Gladiator's Ornamented Legplates
        [143183] = {t = 4010}, -- Crafted Malevolent Gladiator's Ornamented Spaulders
        [143184] = {t = 4010}, -- Crafted Malevolent Gladiator's Girdle of Accuracy
        [143185] = {t = 4010}, -- Crafted Malevolent Gladiator's Girdle of Prowess
        [143186] = {t = 4010}, -- Crafted Malevolent Gladiator's Warboots of Cruelty
        [143187] = {t = 4010}, -- Crafted Malevolent Gladiator's Warboots of Alacrity
        [143188] = {t = 4010}, -- Crafted Malevolent Gladiator's Armplates of Proficiency
        [143189] = {t = 4010}, -- Crafted Malevolent Gladiator's Armplates of Alacrity
        [143190] = {t = 4010}, -- Crafted Malevolent Gladiator's Plate Chestpiece
        [143191] = {t = 4010}, -- Crafted Malevolent Gladiator's Plate Gauntlets
        [143192] = {t = 4010}, -- Crafted Malevolent Gladiator's Plate Helm
        [143193] = {t = 4010}, -- Crafted Malevolent Gladiator's Plate Legguards
        [143194] = {t = 4010}, -- Crafted Malevolent Gladiator's Plate Shoulders
        [143195] = {t = 4010}, -- Crafted Malevolent Gladiator's Barrier
        [143196] = {t = 4010}, -- Crafted Malevolent Gladiator's Redoubt
        [143197] = {t = 4010}, -- Crafted Malevolent Gladiator's Shield Wall
        [143255] = {t = 4010}, -- Balanced Trillium Ingot
        [145038] = {q = {{33022, 64231, 5805}}}, -- Noodle Cart Kit
        [145061] = {q = {{33024, 64231, 5805}}}, -- Deluxe Noodle Cart Kit
        [145062] = {q = {{33027, 64231, 5805}}}, -- Pandaren Treasure Noodle Cart Kit
        [146921] = {t = 4010}, -- Accelerated Balanced Trillium Ingot
        [146923] = {t = 4002}, -- Accelerated Hardened Magnificent Hide
        [146925] = {t = 4006}, -- Accelerated Celestial Cloth
        [148488] = {t = 4025}, -- Glyph of Focused Fire
    },
};

_G.professionMaster:CreateModel("skill-sources-mop", mopSkillSources);
