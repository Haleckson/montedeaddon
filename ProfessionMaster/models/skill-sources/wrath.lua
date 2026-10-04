--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Skill sources for wrath: trainer groups, trainer npcs (zone, side) and per skill sources
-- Format: skills[spellId] = {t = groupId, q = {{questId, giverId, zoneId, side, flags, giverType}}, d = {researchSpellId}, a = true (learned with the profession), u = true (not available)}
-- flags: 1 daily, 2 weekly, 4 repeatable; giverType: nil npc, "o" object, "i" item
local wrathSkillSources = {
    groups = {
        [2001] = {1355, 1382, 1430, 1699, 2818, 2942, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19186, 19369, 26905, 26953, 26972, 26989, 28705, 29631, 33587, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786},
        [2002] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26911, 26961, 26996, 26998, 28700, 29507, 29508, 29509, 33581, 33635, 33681},
        [2003] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7868, 7869, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26996, 33635, 33681},
        [2004] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26996, 33635, 33681},
        [2005] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 16161, 16588, 16642, 16723, 17215, 18802, 19052, 26903, 26951, 26975, 26987, 27023, 27029, 28703, 33588, 33630, 33674},
        [2006] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 16161, 16588, 16642, 16723, 17215, 18802, 19052, 27023, 27029, 33630, 33674},
        [2007] = {1103, 1346, 2399, 2627, 2670, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684},
        [2008] = {1103, 1300, 1346, 1703, 2399, 2627, 2855, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11048, 11050, 11051, 11052, 16366, 16639, 16640, 16729, 16746, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684},
        [2009] = {1355, 1382, 1430, 1699, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19369, 26905, 26953, 26972, 26989, 28705, 29631, 33587, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786},
        [2010] = {1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 16663, 16752, 17488, 18747, 18779, 18804, 26912, 26962, 26976, 26999, 28698, 33640, 33682},
        [2011] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29505, 29506, 29924, 33591, 33631, 33675},
        [2012] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29924, 33591, 33631, 33675},
        [2013] = {2326, 2327, 2329, 2798, 3181, 3373, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 16272, 16662, 16731, 17214, 17424, 18990, 18991, 19184, 19478, 22477, 23734, 26956, 26992, 28706, 29233, 33589},
        [2014] = {1676, 1702, 3290, 3494, 5174, 5518, 7406, 7944, 8126, 8736, 8738, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 21493, 21494, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 29513, 29514, 33586, 33634, 33677},
        [2015] = {1676, 1702, 3290, 3494, 5174, 5518, 8736, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 25277, 26907, 26955, 26991, 28697, 33586, 33634, 33677},
        [2016] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 26906, 26954, 26980, 26990, 28693, 33583, 33633, 33676},
        [2017] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 33633, 33676},
        [2018] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 33633, 33676},
        [2019] = {8126, 8738, 29513},
        [2020] = {5164, 7230, 11177, 20125, 29506},
        [2021] = {7231, 7232, 11146, 11178, 20124, 29505},
        [2022] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26996, 33635, 33681},
        [2023] = {7866, 7867, 7870, 7871, 11097, 29508},
        [2024] = {7870, 7871, 11097, 29509},
        [2025] = {7868, 7869, 7870, 7871, 11097, 29507},
        [2026] = {1103, 1346, 2399, 2627, 2670, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487},
        [2027] = {7406, 7944, 29514},
        [2028] = {7406, 7944, 8126, 8738, 29513, 29514},
        [2029] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 15400, 16583, 16669, 16724, 16823, 17245, 19341, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29924, 33591, 33631, 33675},
        [2030] = {7866, 7867, 29508},
        [2031] = {15501, 16702, 16727, 16744, 18751, 18774, 19063, 19539, 19774, 19775, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2032] = {15501, 16727, 16744, 18751, 18774, 19063, 19539, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2033] = {15501, 16702, 16727, 16744, 18751, 18774, 19063, 19539, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2034] = {15501, 16702, 18751, 18774, 19063, 19539, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2035] = {15501, 16702, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2036] = {15501, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2037] = {18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684},
        [2038] = {15501, 18751, 18774, 19063, 19539, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2039] = {18751, 18774, 19063, 19539, 19777, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2040] = {18990, 18991, 19184, 23734, 26956, 26992, 28706, 29233, 33589},
        [2041] = {18753, 18773, 19251, 19252, 19540, 33633, 33676},
        [2042] = {26906, 26954, 26980, 26990, 28693, 33583},
        [2043] = {16588, 18802, 19052, 27023, 27029, 33630, 33674},
        [2044] = {18751, 18774, 19063, 19539, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2045] = {18747, 18779, 26912, 26962, 26976, 26999, 28698, 33640, 33682},
        [2046] = {16583, 16823, 19341, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29924, 33591, 33631, 33675},
        [2047] = {17634, 17637, 18752, 18775, 19576, 25277, 26907, 26955, 26991, 28697, 33586, 33634, 33677},
        [2048] = {18754, 18771, 19187, 21087, 26996, 33635, 33681},
        [2049] = {7870, 7871, 29509},
        [2050] = {7868, 7869, 29507},
        [2051] = {17634, 17637, 18752, 18775, 19576, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 33586, 33634, 33677},
        [2052] = {26916, 26959, 26977, 26995, 28702, 30706, 30709, 30710, 30711, 30713, 30715, 30716, 30717, 30721, 30722, 33603, 33638, 33679},
        [2053] = {23734, 26956, 26992, 28706, 29233, 33589},
        [2054] = {26905, 26953, 26972, 26989, 28705, 29631, 33587},
        [2055] = {26912, 26962, 26976, 26999, 28698},
        [2056] = {26916, 26959, 26977, 26995, 28702, 33603},
        [2057] = {26911, 26961, 26996, 26998, 28700, 33581},
        [2058] = {26564, 26904, 26952, 26981, 26988, 27034, 28694, 29924, 33591},
        [2059] = {25277, 26907, 26955, 26991, 28697, 33586},
        [2060] = {26903, 26951, 26975, 26987, 28703, 33588},
        [2061] = {19063, 26915, 26960, 26982, 26997, 28701, 33590},
        [2062] = {26915, 26960, 26982, 26997, 28701, 33590},
        [2063] = {26960, 26982, 28701},
        [2064] = {26914, 26964, 26969, 27001, 28699, 33580},
        [2065] = {26914, 26964, 26969, 27001, 28699},
        [2066] = {28699},
        [2067] = {25277, 26907, 26955, 26991, 26995, 28697, 33586},
        [2068] = {26916, 26959, 26977, 26995, 28702, 30721, 30722, 33603, 33638, 33679},
        [2069] = {30706, 30709, 30710, 30711, 30717},
        [2070] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 16161, 16588, 16642, 16723, 18802, 19052, 27023, 27029, 33630, 33674},
        [2071] = {1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684},
        [2072] = {15501, 18751, 18774, 19063, 19539, 19775, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680},
        [2073] = {1676, 1702, 3290, 3494, 5174, 5518, 8736, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 25277, 26907, 26955, 26991, 28697, 33586, 33634, 33677},
    },
    npcs = {
        [514] = {12, "A"}, -- Smith Argus
        [1103] = {12, "A"}, -- Eldrin
        [1215] = {1519, "A"}, -- Alchemist Mallory
        [1241] = {1, "A"}, -- Tognus Flintfire
        [1300] = {1519, "A"}, -- Lawrence Schneider
        [1317] = {1519, "A"}, -- Lucan Cordell
        [1346] = {1519, "A"}, -- Georgio Bolero
        [1355] = {1, "A"}, -- Cook Ghilm
        [1382] = {33, "H"}, -- Mudduk
        [1385] = {33, "H"}, -- Brawn
        [1386] = {8, "H"}, -- Rogvar
        [1430] = {12, "A"}, -- Tomas
        [1470] = {38, "A"}, -- Ghak Healtouch
        [1632] = {12, "A"}, -- Adele Fielder
        [1676] = {41, "A"}, -- Finbus Geargrind
        [1681] = {38, "A"}, -- Brock Stoneseeker
        [1699] = {1, "A"}, -- Gremlock Pilsnor
        [1701] = {1, "A"}, -- Dank Drizzlecut
        [1702] = {1, "A"}, -- Bronk Guzzlegear
        [1703] = {1537, "A"}, -- Uthrar Threx
        [2132] = {28, "H"}, -- Carolai Anise
        [2326] = {1, "A"}, -- Thamner Pol
        [2327] = {1519, "A"}, -- Shaina Fuller
        [2329] = {12, "A"}, -- Michelle Belle
        [2391] = {36, "H"}, -- Serge Hinott
        [2399] = {36, "H"}, -- Daryl Stack
        [2627] = {33}, -- Grarnik Goodstitch
        [2670] = {33}, -- Xizk Goodstitch
        [2798] = {1638, "H"}, -- Pand Stonebinder
        [2818] = {45, "H"}, -- Slagg
        [2836] = {33}, -- Brikk Keencraft
        [2837] = {33}, -- Jaxin Chong
        [2855] = {1637, "H"}, -- Snang
        [2942] = {}, -- Dylan Bissel
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
        [3373] = {1637, "H"}, -- Arnok
        [3399] = {1637, "H"}, -- Zamja
        [3478] = {17, "H"}, -- Traugh
        [3484] = {215, "H"}, -- Kil'hala
        [3494] = {14}, -- Tinkerwiz
        [3523] = {85, "H"}, -- Bowen Brisboise
        [3549] = {85, "H"}, -- Shelene Rhobart
        [3555] = {130, "H"}, -- Johan Focht
        [3557] = {130, "H"}, -- Guillaume Sorouy
        [3603] = {141, "A"}, -- Cyndra Kindwhisper
        [3605] = {141, "A"}, -- Nadyia Maneweaver
        [3606] = {141, "A"}, -- Alanna Raveneye
        [3703] = {17, "H"}, -- Krulmoo Fullmoon
        [3704] = {215, "H"}, -- Mahani
        [3964] = {406, "A"}, -- Kylanna
        [3967] = {331, "A"}, -- Aayndia Floralwind
        [4159] = {1657, "A"}, -- Me'lynn
        [4160] = {1657, "A"}, -- Ainethil
        [4193] = {361, "A"}, -- Grondal Moonbreeze
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
        [4900] = {15, "A"}, -- Alchemist Narett
        [5127] = {1537, "A"}, -- Fimble Finespindle
        [5150] = {1537, "A"}, -- Nissa Firestone
        [5153] = {1537, "A"}, -- Jormund Stonebrow
        [5157] = {1537, "A"}, -- Gimble Thistlefuzz
        [5159] = {1537, "A"}, -- Daryl Riknussun
        [5164] = {1537, "A"}, -- Grumnus Steelshaper
        [5174] = {1537, "A"}, -- Springspindle Fizzlegear
        [5177] = {1537, "A"}, -- Tally Berryfizz
        [5392] = {1, "A"}, -- Yarr Hammerstone
        [5482] = {1519, "A"}, -- Stephen Ryback
        [5499] = {1519, "A"}, -- Lilyssia Nightbreeze
        [5511] = {1519, "A"}, -- Therum Deepforge
        [5513] = {1519, "A"}, -- Gelman Stonehand
        [5518] = {1519, "A"}, -- Lilliam Sparkspindle
        [5564] = {1519, "A"}, -- Simon Tanner
        [5695] = {28, "H"}, -- Vance Undergloom
        [5759] = {85, "H"}, -- Nurse Neela
        [5784] = {17}, -- Waldor
        [5939] = {215, "H"}, -- Vira Younghoof
        [5943] = {14, "H"}, -- Rawrk
        [6094] = {141, "A"}, -- Byancie
        [6286] = {141, "A"}, -- Zarrin
        [6297] = {148, "A"}, -- Kurdram Stonehammer
        [6299] = {148, "A"}, -- Delfrum Flintbeard
        [7230] = {1637, "H"}, -- Shayis Steelfury
        [7231] = {1637, "H"}, -- Kelgruk Bloodaxe
        [7232] = {1519, "A"}, -- Borgus Steelhand
        [7406] = {33}, -- Oglethorpe Obnoticus
        [7866] = {16, "A"}, -- Peter Galen
        [7867] = {3, "H"}, -- Thorkaf Dragoneye
        [7868] = {51, "A"}, -- Sarah Tanner
        [7869] = {45, "H"}, -- Brumn Winterhoof
        [7870] = {357, "A"}, -- Caryssia Moonhunter
        [7871] = {33, "H"}, -- Se'Jib
        [7944] = {1537, "A"}, -- Tinkmaster Overspark
        [7948] = {357, "A"}, -- Kylanna Windwhisper
        [7949] = {357, "A"}, -- Xylinnia Starshine
        [8126] = {440}, -- Nixx Sprocketspring
        [8128] = {440}, -- Pikkle
        [8153] = {405, "H"}, -- Narv Hidecrafter
        [8306] = {17, "H"}, -- Duhng
        [8736] = {440}, -- Buzzek Bracketswing
        [8738] = {14}, -- Vazario Linkgrease
        [9584] = {1519, "A"}, -- Jalane Ayrole
        [10993] = {215}, -- Twizwick Sprocketgrind
        [11017] = {1637, "H"}, -- Roxxik
        [11025] = {14, "H"}, -- Mukdrak
        [11031] = {1497, "H"}, -- Franklin Lloyd
        [11037] = {361, "A"}, -- Jenna Lemkenilli
        [11048] = {1497, "H"}, -- Victor Ward
        [11050] = {1657, "A"}, -- Trianna
        [11051] = {1638, "H"}, -- Vhan
        [11052] = {15, "A"}, -- Timothy Worthington
        [11072] = {12, "A"}, -- Kitta Firewind
        [11073] = {1337}, -- Annora
        [11074] = {406, "H"}, -- Hgarth
        [11097] = {47, "A"}, -- Drakk Stonehand
        [11098] = {357, "H"}, -- Hahrana Ironhide
        [11146] = {1537, "A"}, -- Ironus Coldsteel
        [11177] = {1637, "H"}, -- Okothos Ironrager
        [11178] = {1637, "H"}, -- Borgosh Corebender
        [11557] = {493}, -- Meilosh
        [15400] = {3430, "H"}, -- Arathel Sunforge
        [15501] = {3487, "H"}, -- Aleinia
        [16160] = {3430, "H"}, -- Magistrix Eredania
        [16161] = {3430, "H"}, -- Arcanist Sheynathren
        [16190] = {}, -- Expansion Enchanting Trainer
        [16253] = {3433, "H"}, -- Master Chef Mouldier
        [16265] = {}, -- Smith Daelarin
        [16272] = {3430, "H"}, -- Kanaria
        [16277] = {3430, "H"}, -- Quarelestra
        [16278] = {3430, "H"}, -- Sathein
        [16366] = {3430, "H"}, -- Sempstress Ambershine
        [16583] = {3483, "H"}, -- Rohok
        [16588] = {3483, "H"}, -- Apothecary Antonivich
        [16633] = {3487, "H"}, -- Sedana
        [16639] = {3487, "H"}, -- Galana
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
        [16727] = {3557, "A"}, -- Padaar
        [16728] = {3557, "A"}, -- Akham
        [16729] = {3557, "A"}, -- Refik
        [16731] = {3557, "A"}, -- Nus
        [16744] = {}, -- Driaan
        [16746] = {3557, "A"}, -- Kayaart
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
        [18804] = {3525, "A"}, -- Prospector Nachlan
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
        [19576] = {3522}, -- Xyrol
        [19774] = {}, -- Toban
        [19775] = {3487, "H"}, -- Kalinda
        [19777] = {}, -- Elaando
        [19778] = {3557, "A"}, -- Farii
        [20124] = {3703}, -- Kradu Grimblade
        [20125] = {3703}, -- Zula Slagfury
        [21087] = {3522, "H"}, -- Grikka
        [21209] = {3483, "A"}, -- Dumphry
        [21493] = {3523}, -- Kablamm Farflinger
        [21494] = {3522}, -- Smiles O'Byron
        [22477] = {3519}, -- Anchorite Ensham
        [23734] = {495, "A"}, -- Anchorite Yazmina
        [24868] = {3520}, -- Niobe Whizzlespark
        [25099] = {3520, "H"}, -- Jonathan Garrett
        [25277] = {3537, "H"}, -- Chief Engineer Leveny
        [26564] = {4197, "H"}, -- Borus Ironbender
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
        [27023] = {4197, "H"}, -- Apothecary Bressa
        [27029] = {65, "H"}, -- Apothecary Wormwick
        [27034] = {65, "H"}, -- Josric Fame
        [28693] = {2817}, -- Enchanter Nalthanis
        [28694] = {2817}, -- Alard Schmied
        [28697] = {2817}, -- Timofey Oshenko
        [28698] = {2817}, -- Jedidiah Handers
        [28699] = {2817}, -- Charles Worth
        [28700] = {2817}, -- Diane Cannings
        [28701] = {2817}, -- Timothy Jones
        [28702] = {2817}, -- Professor Pallin
        [28703] = {2817}, -- Linzy Blackbolt
        [28705] = {2817, "A"}, -- Katherine Lee
        [28706] = {2817}, -- Olisarra the Kind
        [29233] = {3537, "H"}, -- Nurse Applewood
        [29505] = {2817}, -- Imindril Spearsong
        [29506] = {2817}, -- Orland Schaeffer
        [29507] = {4395}, -- Manfred Staller
        [29508] = {4395}, -- Andellion
        [29509] = {4395}, -- Namha Moonwater
        [29513] = {2817}, -- Didi the Wrench
        [29514] = {2817}, -- Findle Whistlesteam
        [29631] = {2817, "H"}, -- Awilo Lon'gomba
        [29924] = {210, "A"}, -- Brandig
        [30706] = {1637, "H"}, -- Jo'mah
        [30709] = {1638, "H"}, -- Poshken Hardbinder
        [30710] = {3487}, -- Zantasia
        [30711] = {1497, "H"}, -- Margaux Parchley
        [30713] = {1519, "A"}, -- Catarina Stanford
        [30715] = {1657, "A"}, -- Feyden Darkin
        [30716] = {3557, "A"}, -- Thoth
        [30717] = {1537, "A"}, -- Elise Brightletter
        [30721] = {3483, "A"}, -- Michael Schwan
        [30722] = {3483, "H"}, -- Neferatti
        [33580] = {4742}, -- Dustin Vail
        [33581] = {4742}, -- Kul'de
        [33583] = {4742}, -- Fael Morningsong
        [33586] = {4742}, -- Binkie Brightgear
        [33587] = {4742}, -- Bethany Cromwell
        [33588] = {4742}, -- Crystal Brightspark
        [33589] = {4742}, -- Joseph Wilson
        [33590] = {4742}, -- Oluros
        [33591] = {4742}, -- Rekka the Hammer
        [33603] = {4742}, -- Arthur Denny
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
        [34708] = {}, -- Caitrin Ironkettle
        [34710] = {}, -- Ellen Moore
        [34711] = {}, -- Mary Allerton
        [34712] = {}, -- Roberta Carter
        [34713] = {}, -- Ondani Greatmill
        [34714] = {}, -- Mahara Goldwheat
        [34785] = {}, -- Alnar Whitebough
        [34786] = {}, -- Alice Rigsdale
    },
    skills = {
        [818] = {t = 2001, a = true}, -- Basic Campfire
        [2149] = {t = 2002, a = true}, -- Handstitched Leather Boots
        [2152] = {t = 2002, a = true}, -- Light Armor Kit
        [2153] = {t = 2003}, -- Handstitched Leather Pants
        [2159] = {t = 2003}, -- Fine Leather Cloak
        [2160] = {t = 2003}, -- Embossed Leather Vest
        [2161] = {t = 2003}, -- Embossed Leather Boots
        [2162] = {t = 2004}, -- Embossed Leather Cloak
        [2165] = {t = 2004}, -- Medium Armor Kit
        [2166] = {t = 2003}, -- Toughened Leather Armor
        [2167] = {t = 2003}, -- Dark Leather Boots
        [2168] = {t = 2004}, -- Dark Leather Cloak
        [2329] = {t = 2005, a = true}, -- Elixir of Lion's Strength
        [2330] = {t = 2005, a = true}, -- Minor Healing Potion
        [2331] = {t = 2006}, -- Minor Mana Potion
        [2332] = {t = 2006}, -- Minor Rejuvenation Potion
        [2334] = {t = 2006}, -- Elixir of Minor Fortitude
        [2337] = {t = 2006}, -- Lesser Healing Potion
        [2385] = {t = 2007}, -- Brown Linen Vest
        [2386] = {t = 2007}, -- Linen Boots
        [2387] = {t = 2008, a = true}, -- Linen Cloak
        [2392] = {t = 2007}, -- Red Linen Shirt
        [2393] = {t = 2007}, -- White Linen Shirt
        [2394] = {t = 2007}, -- Blue Linen Shirt
        [2395] = {t = 2007}, -- Barbaric Linen Vest
        [2396] = {t = 2007}, -- Green Linen Shirt
        [2397] = {t = 2007}, -- Reinforced Linen Cape
        [2399] = {t = 2007}, -- Green Woolen Vest
        [2401] = {t = 2007}, -- Woolen Boots
        [2402] = {t = 2007}, -- Woolen Cape
        [2406] = {t = 2007}, -- Gray Woolen Shirt
        [2538] = {t = 2001, a = true}, -- Charred Wolf Meat
        [2539] = {t = 2009}, -- Spiced Wolf Meat
        [2540] = {t = 2001, a = true}, -- Roasted Boar Meat
        [2541] = {t = 2009}, -- Coyote Steak
        [2544] = {t = 2009}, -- Crab Cake
        [2546] = {t = 2009}, -- Dry Pork Ribs
        [2657] = {t = 2010, a = true}, -- Smelt Copper
        [2658] = {t = 2010}, -- Smelt Silver
        [2659] = {t = 2010}, -- Smelt Bronze
        [2660] = {t = 2011, a = true}, -- Rough Sharpening Stone
        [2661] = {t = 2012}, -- Copper Chain Belt
        [2662] = {t = 2012}, -- Copper Chain Pants
        [2663] = {t = 2011, a = true}, -- Copper Bracers
        [2664] = {t = 2012}, -- Runed Copper Bracers
        [2665] = {t = 2012}, -- Coarse Sharpening Stone
        [2666] = {t = 2012}, -- Runed Copper Belt
        [2668] = {t = 2012}, -- Rough Bronze Leggings
        [2670] = {t = 2012}, -- Rough Bronze Cuirass
        [2672] = {t = 2012}, -- Patterned Bronze Bracers
        [2674] = {t = 2012}, -- Heavy Sharpening Stone
        [2675] = {t = 2012}, -- Shining Silver Breastplate
        [2737] = {t = 2012}, -- Copper Mace
        [2738] = {t = 2012}, -- Copper Axe
        [2739] = {t = 2012}, -- Copper Shortsword
        [2740] = {t = 2012}, -- Bronze Mace
        [2741] = {t = 2012}, -- Bronze Axe
        [2742] = {t = 2012}, -- Bronze Shortsword
        [2881] = {t = 2002, a = true}, -- Light Leather
        [2963] = {t = 2008, a = true}, -- Bolt of Linen Cloth
        [2964] = {t = 2007}, -- Bolt of Woolen Cloth
        [3115] = {t = 2011, a = true}, -- Rough Weightstone
        [3116] = {t = 2012}, -- Coarse Weightstone
        [3117] = {t = 2012}, -- Heavy Weightstone
        [3170] = {t = 2006}, -- Weak Troll's Blood Elixir
        [3171] = {t = 2006}, -- Elixir of Wisdom
        [3173] = {t = 2006}, -- Lesser Mana Potion
        [3176] = {t = 2006}, -- Strong Troll's Blood Elixir
        [3177] = {t = 2006}, -- Elixir of Defense
        [3275] = {t = 2008, a = true}, -- Linen Bandage
        [3276] = {t = 2013, a = true}, -- Heavy Linen Bandage
        [3277] = {t = 2013, a = true}, -- Wool Bandage
        [3278] = {t = 2013, a = true}, -- Heavy Wool Bandage
        [3292] = {t = 2012}, -- Heavy Copper Broadsword
        [3293] = {t = 2012}, -- Copper Battle Axe
        [3294] = {t = 2012}, -- Thick War Axe
        [3296] = {t = 2012}, -- Heavy Bronze Mace
        [3304] = {t = 2010}, -- Smelt Tin
        [3307] = {t = 2010}, -- Smelt Iron
        [3308] = {t = 2010}, -- Smelt Gold
        [3319] = {t = 2012}, -- Copper Chain Boots
        [3320] = {t = 2012}, -- Rough Grinding Stone
        [3323] = {t = 2012}, -- Runed Copper Gauntlets
        [3324] = {t = 2012}, -- Runed Copper Pants
        [3326] = {t = 2012}, -- Coarse Grinding Stone
        [3328] = {t = 2012}, -- Rough Bronze Shoulders
        [3331] = {t = 2012}, -- Silvered Bronze Boots
        [3333] = {t = 2012}, -- Silvered Bronze Gauntlets
        [3337] = {t = 2012}, -- Heavy Grinding Stone
        [3447] = {t = 2006}, -- Healing Potion
        [3448] = {t = 2006}, -- Lesser Invisibility Potion
        [3450] = {t = 2006}, -- Elixir of Fortitude
        [3452] = {t = 2006}, -- Mana Potion
        [3491] = {t = 2012}, -- Big Bronze Knife
        [3501] = {t = 2012}, -- Green Iron Bracers
        [3502] = {t = 2012}, -- Green Iron Helm
        [3506] = {t = 2012}, -- Green Iron Leggings
        [3508] = {t = 2012}, -- Green Iron Hauberk
        [3569] = {t = 2010}, -- Smelt Steel
        [3753] = {t = 2003}, -- Handstitched Leather Belt
        [3755] = {t = 2007}, -- Linen Bag
        [3756] = {t = 2004}, -- Embossed Leather Gloves
        [3757] = {t = 2007}, -- Woolen Bag
        [3759] = {t = 2004}, -- Embossed Leather Pants
        [3760] = {t = 2004}, -- Hillman's Cloak
        [3761] = {t = 2004}, -- Fine Leather Tunic
        [3763] = {t = 2004}, -- Fine Leather Belt
        [3764] = {t = 2004}, -- Hillman's Leather Gloves
        [3766] = {t = 2004}, -- Dark Leather Belt
        [3768] = {t = 2004}, -- Hillman's Shoulders
        [3770] = {t = 2004}, -- Toughened Leather Gloves
        [3774] = {t = 2004}, -- Green Leather Belt
        [3776] = {t = 2004}, -- Green Leather Bracers
        [3780] = {t = 2004}, -- Heavy Armor Kit
        [3813] = {t = 2007}, -- Small Silk Pack
        [3816] = {t = 2003}, -- Cured Light Hide
        [3817] = {t = 2004}, -- Cured Medium Hide
        [3818] = {t = 2004}, -- Cured Heavy Hide
        [3839] = {t = 2007}, -- Bolt of Silk Cloth
        [3840] = {t = 2007}, -- Heavy Linen Gloves
        [3841] = {t = 2007}, -- Green Linen Bracers
        [3842] = {t = 2007}, -- Handstitched Linen Britches
        [3843] = {t = 2007}, -- Heavy Woolen Gloves
        [3845] = {t = 2007}, -- Soft-soled Linen Boots
        [3848] = {t = 2007}, -- Double-stitched Woolen Shoulders
        [3850] = {t = 2007}, -- Heavy Woolen Pants
        [3852] = {t = 2007}, -- Gloves of Meditation
        [3855] = {t = 2007}, -- Spidersilk Boots
        [3859] = {t = 2007}, -- Azure Silk Vest
        [3861] = {t = 2007}, -- Long Silken Cloak
        [3865] = {t = 2007}, -- Bolt of Mageweave
        [3866] = {t = 2007}, -- Stylish Red Shirt
        [3871] = {t = 2007}, -- Formal White Shirt
        [3914] = {t = 2007}, -- Brown Linen Pants
        [3915] = {t = 2007, a = true}, -- Brown Linen Shirt
        [3918] = {t = 2014, a = true}, -- Rough Blasting Powder
        [3919] = {t = 2014, a = true}, -- Rough Dynamite
        [3920] = {t = 2014, a = true}, -- Crafted Light Shot
        [3922] = {t = 2015}, -- Handful of Copper Bolts
        [3923] = {t = 2015}, -- Rough Copper Bomb
        [3924] = {t = 2015}, -- Copper Tube
        [3925] = {t = 2015}, -- Rough Boomstick
        [3926] = {t = 2015}, -- Copper Modulator
        [3929] = {t = 2015}, -- Coarse Blasting Powder
        [3930] = {t = 2015}, -- Crafted Heavy Shot
        [3931] = {t = 2015}, -- Coarse Dynamite
        [3932] = {t = 2015}, -- Target Dummy
        [3934] = {t = 2015}, -- Flying Tiger Goggles
        [3936] = {t = 2015}, -- Deadly Blunderbuss
        [3937] = {t = 2015}, -- Large Copper Bomb
        [3938] = {t = 2015}, -- Bronze Tube
        [3941] = {t = 2015}, -- Small Bronze Bomb
        [3942] = {t = 2015}, -- Whirring Bronze Gizmo
        [3945] = {t = 2015}, -- Heavy Blasting Powder
        [3946] = {t = 2015}, -- Heavy Dynamite
        [3947] = {t = 2015}, -- Crafted Solid Shot
        [3949] = {t = 2015}, -- Silver-plated Shotgun
        [3950] = {t = 2015}, -- Big Bronze Bomb
        [3953] = {t = 2015}, -- Bronze Framework
        [3955] = {t = 2015}, -- Explosive Sheep
        [3956] = {t = 2015}, -- Green Tinted Goggles
        [3958] = {t = 2015}, -- Iron Strut
        [3961] = {t = 2015}, -- Gyrochronatom
        [3962] = {t = 2015}, -- Iron Grenade
        [3963] = {t = 2015}, -- Compact Harvest Reaper Kit
        [3965] = {t = 2015}, -- Advanced Target Dummy
        [3967] = {t = 2015}, -- Big Iron Bomb
        [3973] = {t = 2015}, -- Silver Contact
        [3977] = {t = 2015}, -- Crude Scope
        [3978] = {t = 2015}, -- Standard Scope
        [6458] = {t = 2015}, -- Ornate Spyglass
        [6499] = {t = 2009}, -- Boiled Clams
        [6500] = {t = 2009}, -- Goblin Deviled Clams
        [6517] = {t = 2012}, -- Pearl-handled Dagger
        [6521] = {t = 2007}, -- Pearl-clasped Cloak
        [6661] = {t = 2004}, -- Barbaric Harness
        [6690] = {t = 2007}, -- Lesser Wizard's Robe
        [7126] = {t = 2002, a = true}, -- Handstitched Leather Vest
        [7135] = {t = 2004}, -- Dark Leather Pants
        [7147] = {t = 2004}, -- Guardian Pants
        [7151] = {t = 2004}, -- Barbaric Shoulders
        [7156] = {t = 2004}, -- Guardian Gloves
        [7179] = {t = 2006}, -- Elixir of Water Breathing
        [7181] = {t = 2006}, -- Greater Healing Potion
        [7183] = {t = 2005, a = true}, -- Elixir of Minor Defense
        [7223] = {t = 2012}, -- Golden Scale Bracers
        [7408] = {t = 2012}, -- Heavy Copper Maul
        [7418] = {t = 2016, a = true}, -- Enchant Bracer - Minor Health
        [7420] = {t = 2017}, -- Enchant Chest - Minor Health
        [7421] = {t = 2016, a = true}, -- Runed Copper Rod
        [7426] = {t = 2017}, -- Enchant Chest - Minor Absorption
        [7428] = {t = 2018, a = true}, -- Enchant Bracer - Minor Deflection
        [7430] = {t = 2015}, -- Arclight Spanner
        [7454] = {t = 2017}, -- Enchant Cloak - Minor Resistance
        [7457] = {t = 2017}, -- Enchant Bracer - Minor Stamina
        [7623] = {t = 2007}, -- Brown Linen Robe
        [7624] = {t = 2007}, -- White Linen Robe
        [7745] = {t = 2017}, -- Enchant 2H Weapon - Minor Impact
        [7748] = {t = 2017}, -- Enchant Chest - Lesser Health
        [7771] = {t = 2017}, -- Enchant Cloak - Minor Protection
        [7779] = {t = 2017}, -- Enchant Bracer - Minor Agility
        [7788] = {t = 2017}, -- Enchant Weapon - Minor Striking
        [7795] = {t = 2017}, -- Runed Silver Rod
        [7817] = {t = 2012}, -- Rough Bronze Boots
        [7818] = {t = 2012}, -- Silver Rod
        [7836] = {t = 2006}, -- Blackmouth Oil
        [7837] = {t = 2006}, -- Fire Oil
        [7841] = {t = 2006}, -- Swim Speed Potion
        [7845] = {t = 2006}, -- Elixir of Firepower
        [7857] = {t = 2017}, -- Enchant Chest - Health
        [7861] = {t = 2017}, -- Enchant Cloak - Lesser Fire Resistance
        [7863] = {t = 2017}, -- Enchant Boots - Minor Stamina
        [7928] = {t = 2013, a = true}, -- Silk Bandage
        [7929] = {t = 2013, a = true}, -- Heavy Silk Bandage
        [7934] = {t = 2013, a = true}, -- Anti-Venom
        [8334] = {t = 2015}, -- Practice Lock
        [8465] = {t = 2007}, -- Simple Dress
        [8467] = {t = 2007}, -- White Woolen Dress
        [8483] = {t = 2007}, -- White Swashbuckler's Shirt
        [8489] = {t = 2007}, -- Red Swashbuckler's Shirt
        [8604] = {t = 2001, a = true}, -- Herb Baked Egg
        [8758] = {t = 2007}, -- Azure Silk Pants
        [8760] = {t = 2007}, -- Azure Silk Hood
        [8762] = {t = 2007}, -- Silk Headband
        [8764] = {t = 2007}, -- Earthen Vest
        [8766] = {t = 2007}, -- Azure Silk Belt
        [8768] = {t = 2012}, -- Iron Buckle
        [8770] = {t = 2007}, -- Robe of Power
        [8772] = {t = 2007}, -- Crimson Silk Belt
        [8774] = {t = 2007}, -- Green Silken Shoulders
        [8776] = {t = 2007}, -- Linen Belt
        [8791] = {t = 2007}, -- Crimson Silk Vest
        [8799] = {t = 2007}, -- Crimson Silk Pantaloons
        [8804] = {t = 2007}, -- Crimson Silk Gloves
        [8880] = {t = 2012}, -- Copper Dagger
        [8895] = {t = 2019}, -- Goblin Rocket Boots
        [9058] = {t = 2002, a = true}, -- Handstitched Leather Cloak
        [9059] = {t = 2002, a = true}, -- Handstitched Leather Bracers
        [9060] = {t = 2003}, -- Light Leather Quiver
        [9062] = {t = 2004}, -- Small Leather Ammo Pouch
        [9065] = {t = 2003}, -- Light Leather Bracers
        [9068] = {t = 2003}, -- Light Leather Pants
        [9074] = {t = 2004}, -- Nimble Leather Gloves
        [9145] = {t = 2004}, -- Fletcher's Gloves
        [9193] = {t = 2004}, -- Heavy Quiver
        [9194] = {t = 2004}, -- Heavy Leather Ammo Pouch
        [9196] = {t = 2004}, -- Dusky Leather Armor
        [9198] = {t = 2004}, -- Frost Leather Cloak
        [9201] = {t = 2004}, -- Dusky Bracers
        [9206] = {t = 2004}, -- Dusky Belt
        [9271] = {t = 2015}, -- Aquadynamic Fish Attractor
        [9916] = {t = 2012}, -- Steel Breastplate
        [9918] = {t = 2012}, -- Solid Sharpening Stone
        [9920] = {t = 2012}, -- Solid Grinding Stone
        [9921] = {t = 2012}, -- Solid Weightstone
        [9926] = {t = 2012}, -- Heavy Mithril Shoulder
        [9928] = {t = 2012}, -- Heavy Mithril Gauntlet
        [9931] = {t = 2012}, -- Mithril Scale Pants
        [9935] = {t = 2012}, -- Steel Plate Helm
        [9954] = {t = 2020}, -- Truesilver Gauntlets
        [9957] = {q = {{2756, 7792, 1637, "H"}, {2756, 7792, 1637, "H"}}}, -- Orcish War Leggings
        [9959] = {t = 2012}, -- Heavy Mithril Breastplate
        [9961] = {t = 2012}, -- Mithril Coif
        [9968] = {t = 2012}, -- Heavy Mithril Boots
        [9972] = {q = {{2773, 7804, 440}, {2773, 7804, 440}}}, -- Ornate Mithril Breastplate
        [9974] = {t = 2020}, -- Truesilver Breastplate
        [9979] = {q = {{2772, 7804, 440}, {2772, 7804, 440}}}, -- Ornate Mithril Boots
        [9980] = {q = {{2771, 7804, 440}, {2771, 7804, 440}}}, -- Ornate Mithril Helm
        [9983] = {t = 2012}, -- Copper Claymore
        [9985] = {t = 2012}, -- Bronze Warhammer
        [9986] = {t = 2012}, -- Bronze Greatsword
        [9987] = {t = 2012}, -- Bronze Battle Axe
        [9993] = {t = 2012}, -- Heavy Mithril Axe
        [10001] = {t = 2012}, -- Big Black Mace
        [10003] = {t = 2021}, -- The Shatterer
        [10007] = {t = 2021}, -- Phantom Blade
        [10011] = {t = 2021}, -- Blight
        [10015] = {t = 2021}, -- Truesilver Champion
        [10097] = {t = 2010}, -- Smelt Mithril
        [10098] = {t = 2010}, -- Smelt Truesilver
        [10482] = {t = 2004}, -- Cured Thick Hide
        [10487] = {t = 2004}, -- Thick Armor Kit
        [10499] = {t = 2004}, -- Nightscape Tunic
        [10507] = {t = 2004}, -- Nightscape Headband
        [10511] = {t = 2022}, -- Turtle Scale Breastplate
        [10518] = {t = 2022}, -- Turtle Scale Bracers
        [10548] = {t = 2022}, -- Nightscape Pants
        [10552] = {t = 2022}, -- Turtle Scale Helm
        [10556] = {t = 2022}, -- Turtle Scale Leggings
        [10558] = {t = 2022}, -- Nightscape Boots
        [10619] = {t = 2023}, -- Dragonscale Gauntlets
        [10621] = {t = 2024}, -- Wolfshead Helm
        [10630] = {t = 2025}, -- Gauntlets of the Sea
        [10632] = {t = 2025}, -- Helm of Fire
        [10647] = {t = 2024}, -- Feathered Breastplate
        [10650] = {t = 2023}, -- Dragonscale Breastplate
        [10840] = {t = 2013, a = true}, -- Mageweave Bandage
        [10841] = {t = 2013, a = true}, -- Heavy Mageweave Bandage
        [11448] = {t = 2006}, -- Greater Mana Potion
        [11449] = {t = 2006}, -- Elixir of Agility
        [11450] = {t = 2006}, -- Elixir of Greater Defense
        [11451] = {t = 2006}, -- Oil of Immolation
        [11452] = {q = {{2203, 6868, 3, "H"}, {2501, 1470, 38, "A"}, {2203, 6868, 3, "H"}, {2501, 1470, 38, "A"}}}, -- Restorative Potion
        [11457] = {t = 2006}, -- Superior Healing Potion
        [11460] = {t = 2006}, -- Elixir of Detect Undead
        [11461] = {t = 2006}, -- Arcane Elixir
        [11465] = {t = 2006}, -- Elixir of Greater Intellect
        [11467] = {t = 2006}, -- Elixir of Greater Agility
        [11478] = {t = 2006}, -- Elixir of Detect Demon
        [12044] = {t = 2026, a = true}, -- Simple Linen Pants
        [12045] = {t = 2007}, -- Simple Linen Boots
        [12046] = {t = 2007}, -- Simple Kilt
        [12048] = {t = 2007}, -- Black Mageweave Vest
        [12049] = {t = 2007}, -- Black Mageweave Leggings
        [12050] = {t = 2007}, -- Black Mageweave Robe
        [12053] = {t = 2007}, -- Black Mageweave Gloves
        [12061] = {t = 2007}, -- Orange Mageweave Shirt
        [12065] = {t = 2007}, -- Mageweave Bag
        [12067] = {t = 2007}, -- Dreamweave Gloves
        [12069] = {t = 2007}, -- Cindercloth Robe
        [12070] = {t = 2007}, -- Dreamweave Vest
        [12072] = {t = 2007}, -- Black Mageweave Headband
        [12073] = {t = 2007}, -- Black Mageweave Boots
        [12074] = {t = 2007}, -- Black Mageweave Shoulders
        [12077] = {t = 2007}, -- Simple Black Dress
        [12079] = {t = 2007}, -- Red Mageweave Bag
        [12088] = {t = 2007}, -- Cindercloth Boots
        [12092] = {t = 2007}, -- Dreamweave Circlet
        [12260] = {t = 2011, a = true}, -- Rough Copper Vest
        [12584] = {t = 2015}, -- Gold Power Core
        [12585] = {t = 2015}, -- Solid Blasting Powder
        [12586] = {t = 2015}, -- Solid Dynamite
        [12589] = {t = 2015}, -- Mithril Tube
        [12590] = {t = 2015}, -- Gyromatic Micro-Adjustor
        [12591] = {t = 2015}, -- Unstable Trigger
        [12594] = {t = 2015}, -- Fire Goggles
        [12595] = {t = 2015}, -- Mithril Blunderbuss
        [12596] = {t = 2015}, -- Hi-Impact Mithril Slugs
        [12599] = {t = 2015}, -- Mithril Casing
        [12603] = {t = 2015}, -- Mithril Frag Bomb
        [12609] = {t = 2006}, -- Catseye Elixir
        [12615] = {t = 2015}, -- Spellpower Goggles Xtreme
        [12618] = {t = 2015}, -- Rose Colored Goggles
        [12619] = {t = 2015}, -- Hi-Explosive Bomb
        [12621] = {t = 2015}, -- Mithril Gyro-Shot
        [12622] = {t = 2015}, -- Green Lens
        [12715] = {t = 2019}, -- Goblin Rocket Fuel Recipe
        [12716] = {t = 2019}, -- Goblin Mortar
        [12717] = {t = 2019}, -- Goblin Mining Helmet
        [12718] = {t = 2019}, -- Goblin Construction Helmet
        [12754] = {t = 2019}, -- The Big One
        [12755] = {t = 2019}, -- Goblin Bomb Dispenser
        [12758] = {t = 2019}, -- Goblin Rocket Helmet
        [12759] = {t = 2027}, -- Gnomish Death Ray
        [12760] = {t = 2019}, -- Goblin Sapper Charge
        [12895] = {t = 2027}, -- Inlaid Mithril Cylinder Plans
        [12897] = {t = 2027}, -- Gnomish Goggles
        [12899] = {t = 2027}, -- Gnomish Shrink Ray
        [12902] = {t = 2027}, -- Gnomish Net-o-Matic Projector
        [12903] = {t = 2027}, -- Gnomish Harm Prevention Belt
        [12905] = {t = 2027}, -- Gnomish Rocket Boots
        [12906] = {t = 2027}, -- Gnomish Battle Chicken
        [12907] = {t = 2027}, -- Gnomish Mind Control Cap
        [12908] = {t = 2019}, -- Goblin Dragon Gun
        [13240] = {t = 2028}, -- The Mortar: Reloaded
        [13378] = {t = 2017}, -- Enchant Shield - Minor Stamina
        [13421] = {t = 2017}, -- Enchant Cloak - Lesser Protection
        [13485] = {t = 2017}, -- Enchant Shield - Lesser Spirit
        [13501] = {t = 2017}, -- Enchant Bracer - Lesser Stamina
        [13503] = {t = 2017}, -- Enchant Weapon - Lesser Striking
        [13529] = {t = 2017}, -- Enchant 2H Weapon - Lesser Impact
        [13538] = {t = 2017}, -- Enchant Chest - Lesser Absorption
        [13607] = {t = 2017}, -- Enchant Chest - Mana
        [13622] = {t = 2017}, -- Enchant Bracer - Lesser Intellect
        [13626] = {t = 2017}, -- Enchant Chest - Minor Stats
        [13628] = {t = 2017}, -- Runed Golden Rod
        [13631] = {t = 2017}, -- Enchant Shield - Lesser Stamina
        [13635] = {t = 2017}, -- Enchant Cloak - Defense
        [13637] = {t = 2017}, -- Enchant Boots - Lesser Agility
        [13640] = {t = 2017}, -- Enchant Chest - Greater Health
        [13642] = {t = 2017}, -- Enchant Bracer - Spirit
        [13644] = {t = 2017}, -- Enchant Boots - Lesser Stamina
        [13648] = {t = 2017}, -- Enchant Bracer - Stamina
        [13657] = {t = 2017}, -- Enchant Cloak - Fire Resistance
        [13659] = {t = 2017}, -- Enchant Shield - Spirit
        [13661] = {t = 2017}, -- Enchant Bracer - Strength
        [13663] = {t = 2017}, -- Enchant Chest - Greater Mana
        [13693] = {t = 2017}, -- Enchant Weapon - Striking
        [13695] = {t = 2017}, -- Enchant 2H Weapon - Impact
        [13700] = {t = 2017}, -- Enchant Chest - Lesser Stats
        [13702] = {t = 2017}, -- Runed Truesilver Rod
        [13746] = {t = 2017}, -- Enchant Cloak - Greater Defense
        [13794] = {t = 2017}, -- Enchant Cloak - Resistance
        [13815] = {t = 2017}, -- Enchant Gloves - Agility
        [13822] = {t = 2017}, -- Enchant Bracer - Intellect
        [13836] = {t = 2017}, -- Enchant Boots - Stamina
        [13858] = {t = 2017}, -- Enchant Chest - Superior Health
        [13887] = {t = 2017}, -- Enchant Gloves - Strength
        [13890] = {t = 2017}, -- Enchant Boots - Minor Speed
        [13905] = {t = 2017}, -- Enchant Shield - Greater Spirit
        [13917] = {t = 2017}, -- Enchant Chest - Superior Mana
        [13935] = {t = 2017}, -- Enchant Boots - Agility
        [13937] = {t = 2017}, -- Enchant 2H Weapon - Greater Impact
        [13939] = {t = 2017}, -- Enchant Bracer - Greater Strength
        [13941] = {t = 2017}, -- Enchant Chest - Stats
        [13943] = {t = 2017}, -- Enchant Weapon - Greater Striking
        [13948] = {t = 2017}, -- Enchant Gloves - Minor Haste
        [14293] = {t = 2017}, -- Lesser Magic Wand
        [14379] = {t = 2012}, -- Golden Rod
        [14380] = {t = 2012}, -- Truesilver Rod
        [14807] = {t = 2017}, -- Greater Magic Wand
        [14809] = {t = 2017}, -- Lesser Mystic Wand
        [14810] = {t = 2017}, -- Greater Mystic Wand
        [14930] = {t = 2022}, -- Quickdraw Quiver
        [14932] = {t = 2022}, -- Thick Leather Ammo Pouch
        [15255] = {t = 2015}, -- Mechanical Repair Kit
        [15833] = {t = 2006}, -- Dreamless Sleep Potion
        [15972] = {t = 2012}, -- Glinting Steel Dagger
        [16153] = {t = 2010}, -- Smelt Thorium
        [16639] = {t = 2012}, -- Dense Grinding Stone
        [16640] = {t = 2012}, -- Dense Weightstone
        [16641] = {t = 2012}, -- Dense Sharpening Stone
        [16642] = {t = 2029}, -- Thorium Armor
        [16643] = {t = 2029}, -- Thorium Belt
        [16644] = {t = 2029}, -- Thorium Bracers
        [16652] = {t = 2029}, -- Thorium Boots
        [16653] = {t = 2029}, -- Thorium Helm
        [16662] = {t = 2029}, -- Thorium Leggings
        [16969] = {t = 2029}, -- Ornate Thorium Handaxe
        [16971] = {t = 2029}, -- Huge Thorium Battleaxe
        [17180] = {t = 2017}, -- Enchanted Thorium
        [17181] = {t = 2017}, -- Enchanted Leather
        [17551] = {t = 2006}, -- Stonescale Oil
        [17552] = {t = 2006}, -- Mighty Rage Potion
        [17553] = {t = 2006}, -- Superior Mana Potion
        [17555] = {t = 2006}, -- Elixir of the Sages
        [17556] = {t = 2006}, -- Major Healing Potion
        [17557] = {t = 2006}, -- Elixir of Brute Force
        [17572] = {t = 2006}, -- Purification Potion
        [17573] = {t = 2006}, -- Greater Arcane Elixir
        [18401] = {t = 2007}, -- Bolt of Runecloth
        [18402] = {t = 2007}, -- Runecloth Belt
        [18403] = {t = 2007}, -- Frostweave Tunic
        [18406] = {t = 2007}, -- Runecloth Robe
        [18407] = {t = 2007}, -- Runecloth Tunic
        [18409] = {t = 2007}, -- Runecloth Cloak
        [18410] = {t = 2007}, -- Ghostweave Belt
        [18411] = {t = 2007}, -- Frostweave Gloves
        [18413] = {t = 2007}, -- Ghostweave Gloves
        [18414] = {t = 2007}, -- Brightcloth Robe
        [18415] = {t = 2007}, -- Brightcloth Gloves
        [18416] = {t = 2007}, -- Ghostweave Vest
        [18417] = {t = 2007}, -- Runecloth Gloves
        [18420] = {t = 2007}, -- Brightcloth Cloak
        [18421] = {t = 2007}, -- Wizardweave Leggings
        [18423] = {t = 2007}, -- Runecloth Boots
        [18424] = {t = 2007}, -- Frostweave Pants
        [18437] = {t = 2007}, -- Felcloth Boots
        [18438] = {t = 2007}, -- Runecloth Pants
        [18441] = {t = 2007}, -- Ghostweave Pants
        [18442] = {t = 2007}, -- Felcloth Hood
        [18444] = {t = 2007}, -- Runecloth Headband
        [18446] = {t = 2007}, -- Wizardweave Robe
        [18449] = {t = 2007}, -- Runecloth Shoulders
        [18450] = {t = 2007}, -- Wizardweave Turban
        [18451] = {t = 2007}, -- Felcloth Robe
        [18453] = {t = 2007}, -- Felcloth Shoulders
        [18629] = {t = 2013, a = true}, -- Runecloth Bandage
        [18630] = {t = 2013, a = true}, -- Heavy Runecloth Bandage
        [19047] = {t = 2022}, -- Cured Rugged Hide
        [19052] = {t = 2004}, -- Wicked Leather Bracers
        [19055] = {t = 2004}, -- Runic Leather Gauntlets
        [19058] = {t = 2022}, -- Rugged Armor Kit
        [19065] = {t = 2004}, -- Runic Leather Bracers
        [19071] = {t = 2004}, -- Wicked Leather Headband
        [19072] = {t = 2004}, -- Runic Leather Belt
        [19082] = {t = 2004}, -- Runic Leather Headband
        [19083] = {t = 2004}, -- Wicked Leather Pants
        [19091] = {t = 2004}, -- Runic Leather Pants
        [19092] = {t = 2004}, -- Wicked Leather Belt
        [19093] = {q = {{7493, 14392, 1637, "H"}, {7497, 14394, 1519, "A"}, {7493, 14392, 1637, "H"}, {7497, 14394, 1519, "A"}}}, -- Onyxia Scale Cloak
        [19098] = {t = 2004}, -- Wicked Leather Armor
        [19102] = {t = 2004}, -- Runic Leather Armor
        [19103] = {t = 2004}, -- Runic Leather Shoulders
        [19435] = {q = {{6032, 11557, 493}, {6032, 11557, 493}}}, -- Mooncloth Boots
        [19567] = {t = 2015}, -- Salt Shaker
        [19666] = {t = 2012}, -- Silver Skeleton Key
        [19667] = {t = 2012}, -- Golden Skeleton Key
        [19668] = {t = 2012}, -- Truesilver Skeleton Key
        [19669] = {t = 2012}, -- Arcanite Skeleton Key
        [19788] = {t = 2015}, -- Dense Blasting Powder
        [19790] = {t = 2015}, -- Thorium Grenade
        [19791] = {t = 2015}, -- Thorium Widget
        [19792] = {t = 2015}, -- Thorium Rifle
        [19794] = {t = 2015}, -- Spellpower Goggles Xtreme Plus
        [19795] = {t = 2015}, -- Thorium Tube
        [19800] = {t = 2015}, -- Thorium Shells
        [19825] = {t = 2015}, -- Master Engineer's Goggles
        [20008] = {t = 2017}, -- Enchant Bracer - Greater Intellect
        [20012] = {t = 2017}, -- Enchant Gloves - Greater Agility
        [20013] = {t = 2017}, -- Enchant Gloves - Greater Strength
        [20014] = {t = 2017}, -- Enchant Cloak - Greater Resistance
        [20016] = {t = 2017}, -- Enchant Shield - Vitality
        [20023] = {t = 2017}, -- Enchant Boots - Greater Agility
        [20028] = {t = 2017}, -- Enchant Chest - Major Mana
        [20201] = {t = 2012}, -- Arcanite Rod
        [20648] = {t = 2004}, -- Medium Leather
        [20649] = {t = 2004}, -- Heavy Leather
        [20650] = {t = 2004}, -- Thick Leather
        [21175] = {t = 2009}, -- Spider Sausage
        [22331] = {t = 2004}, -- Rugged Leather
        [22808] = {t = 2006}, -- Elixir of Greater Water Breathing
        [23070] = {t = 2015}, -- Dense Dynamite
        [23071] = {t = 2015}, -- Truesilver Transformer
        [24654] = {t = 2030}, -- Blue Dragonscale Leggings
        [24655] = {t = 2030}, -- Green Dragonscale Gauntlets
        [24801] = {q = {{8313}, {8313}}}, -- Smoked Desert Dumplings
        [25255] = {t = 2031, a = true}, -- Delicate Copper Wire
        [25278] = {t = 2032}, -- Bronze Setting
        [25280] = {t = 2032}, -- Elegant Silver Ring
        [25283] = {t = 2032}, -- Inlaid Malachite Ring
        [25284] = {t = 2033}, -- Simple Pearl Ring
        [25287] = {t = 2033}, -- Gloom Band
        [25305] = {t = 2034}, -- Heavy Silver Ring
        [25317] = {t = 2034}, -- Ring of Silver Might
        [25318] = {t = 2034}, -- Ring of Twilight Shadows
        [25321] = {t = 2034}, -- Moonsoul Crown
        [25490] = {t = 2032}, -- Solid Bronze Ring
        [25493] = {t = 2031, a = true}, -- Braided Copper Ring
        [25498] = {t = 2034}, -- Barbaric Iron Collar
        [25613] = {t = 2035}, -- Golden Dragon Ring
        [25615] = {t = 2036}, -- Mithril Filigree
        [25620] = {t = 2036}, -- Engraved Truesilver Ring
        [25621] = {t = 2036}, -- Citrine Ring of Rapid Healing
        [26011] = {q = {{8798, 10305, 618}, {8798, 10305, 618}}}, -- Tranquil Mechanical Yeti
        [26745] = {t = 2037}, -- Bolt of Netherweave
        [26746] = {t = 2037}, -- Netherweave Bag
        [26764] = {t = 2037}, -- Netherweave Bracers
        [26765] = {t = 2037}, -- Netherweave Belt
        [26770] = {t = 2037}, -- Netherweave Gloves
        [26771] = {t = 2037}, -- Netherweave Pants
        [26772] = {t = 2037}, -- Netherweave Boots
        [26872] = {t = 2036}, -- Figurine - Jade Owl
        [26874] = {t = 2038}, -- Aquamarine Signet
        [26876] = {t = 2038}, -- Aquamarine Pendant of the Warrior
        [26880] = {t = 2038}, -- Thorium Setting
        [26883] = {t = 2038}, -- Ruby Pendant of Fire
        [26885] = {t = 2038}, -- Truesilver Healing Ring
        [26902] = {t = 2038}, -- Simple Opal Ring
        [26903] = {t = 2038}, -- Sapphire Signet
        [26907] = {t = 2038}, -- Onslaught Ring
        [26908] = {t = 2038}, -- Sapphire Pendant of Winter Night
        [26911] = {t = 2038}, -- Living Emerald Pendant
        [26916] = {t = 2039}, -- Band of Natural Fire
        [26925] = {t = 2031, a = true}, -- Woven Copper Ring
        [26926] = {t = 2032}, -- Heavy Copper Ring
        [26927] = {t = 2032}, -- Thick Bronze Necklace
        [26928] = {t = 2032}, -- Ornate Tigerseye Necklace
        [27032] = {t = 2040}, -- Netherweave Bandage
        [27033] = {t = 2040}, -- Heavy Netherweave Bandage
        [27899] = {t = 2041}, -- Enchant Bracer - Brawn
        [27905] = {t = 2041}, -- Enchant Bracer - Stats
        [27944] = {t = 2041}, -- Enchant Shield - Tough Shield
        [27957] = {t = 2041}, -- Enchant Chest - Exceptional Health
        [27958] = {t = 2042}, -- Enchant Chest - Exceptional Mana
        [27961] = {t = 2041}, -- Enchant Cloak - Major Armor
        [28027] = {t = 2041}, -- Prismatic Sphere
        [28028] = {t = 2041}, -- Void Sphere
        [28544] = {t = 2043}, -- Elixir of Major Strength
        [28545] = {t = 2043}, -- Elixir of Healing Power
        [28551] = {t = 2043}, -- Super Healing Potion
        [28580] = {d = {0}}, -- Transmute: Primal Shadow to Water
        [28581] = {d = {0}}, -- Transmute: Primal Water to Shadow
        [28582] = {d = {0}}, -- Transmute: Primal Mana to Fire
        [28583] = {d = {0}}, -- Transmute: Primal Fire to Mana
        [28584] = {d = {0}}, -- Transmute: Primal Life to Earth
        [28585] = {d = {0}}, -- Transmute: Primal Earth to Life
        [28586] = {d = {0}}, -- Super Rejuvenation Potion
        [28587] = {d = {0}}, -- Flask of Fortification
        [28588] = {d = {0}}, -- Flask of Mighty Restoration
        [28589] = {d = {0}}, -- Flask of Relentless Assault
        [28590] = {d = {0}}, -- Flask of Blinding Light
        [28591] = {d = {0}}, -- Flask of Pure Death
        [28903] = {t = 2044}, -- Teardrop Blood Garnet
        [28905] = {t = 2044}, -- Bold Blood Garnet
        [28910] = {t = 2044}, -- Inscribed Flame Spessarite
        [28914] = {t = 2044}, -- Glinting Flame Spessarite
        [28916] = {t = 2044}, -- Radiant Deep Peridot
        [28917] = {t = 2044}, -- Jagged Deep Peridot
        [28925] = {t = 2044}, -- Glowing Shadow Draenite
        [28936] = {t = 2044}, -- Sovereign Shadow Draenite
        [28938] = {t = 2044}, -- Brilliant Golden Draenite
        [28948] = {t = 2044}, -- Rigid Golden Draenite
        [28950] = {t = 2044}, -- Solid Azure Moonstone
        [28953] = {t = 2044}, -- Sparkling Azure Moonstone
        [29356] = {t = 2045}, -- Smelt Fel Iron
        [29358] = {t = 2045}, -- Smelt Adamantite
        [29359] = {t = 2045}, -- Smelt Eternium
        [29360] = {t = 2045}, -- Smelt Felsteel
        [29361] = {t = 2045}, -- Smelt Khorium
        [29545] = {t = 2046}, -- Fel Iron Plate Gloves
        [29547] = {t = 2046}, -- Fel Iron Plate Belt
        [29548] = {t = 2046}, -- Fel Iron Plate Boots
        [29549] = {t = 2046}, -- Fel Iron Plate Pants
        [29550] = {t = 2046}, -- Fel Iron Breastplate
        [29551] = {t = 2046}, -- Fel Iron Chain Coif
        [29552] = {t = 2046}, -- Fel Iron Chain Gloves
        [29553] = {t = 2046}, -- Fel Iron Chain Bracers
        [29556] = {t = 2046}, -- Fel Iron Chain Tunic
        [29557] = {t = 2046}, -- Fel Iron Hatchet
        [29558] = {t = 2046}, -- Fel Iron Hammer
        [29565] = {t = 2046}, -- Fel Iron Greatsword
        [29654] = {t = 2046}, -- Fel Sharpening Stone
        [29686] = {t = 2045}, -- Smelt Hardened Adamantite
        [30303] = {t = 2047}, -- Elemental Blasting Powder
        [30304] = {t = 2047}, -- Fel Iron Casing
        [30305] = {t = 2047}, -- Handful of Fel Iron Bolts
        [30306] = {t = 2047}, -- Adamantite Frame
        [30307] = {t = 2047}, -- Hardened Adamantite Tube
        [30308] = {t = 2047}, -- Khorium Power Core
        [30309] = {t = 2047}, -- Felsteel Stabilizer
        [30310] = {t = 2047}, -- Fel Iron Bomb
        [30311] = {t = 2047}, -- Adamantite Grenade
        [30312] = {t = 2047}, -- Fel Iron Musket
        [30346] = {t = 2047}, -- Fel Iron Shells
        [30558] = {t = 2019}, -- The Bigger One
        [30560] = {t = 2019}, -- Super Sapper Charge
        [30563] = {t = 2019}, -- Goblin Rocket Launcher
        [30565] = {t = 2019}, -- Foreman's Enchanted Helmet
        [30566] = {t = 2019}, -- Foreman's Reinforced Helmet
        [30568] = {t = 2027}, -- Gnomish Flame Turret
        [30569] = {t = 2027}, -- Gnomish Poultryizer
        [30570] = {t = 2027}, -- Nigh-Invulnerability Belt
        [30574] = {t = 2027}, -- Gnomish Power Goggles
        [30575] = {t = 2027}, -- Gnomish Battle Goggles
        [31048] = {t = 2039}, -- Fel Iron Blood Ring
        [31049] = {t = 2039}, -- Golden Draenite Ring
        [31050] = {t = 2039}, -- Azure Moonstone Ring
        [31051] = {t = 2039}, -- Thick Adamantite Necklace
        [31052] = {t = 2039}, -- Heavy Adamantite Ring
        [31460] = {t = 2037}, -- Netherweave Net
        [32178] = {t = 2032}, -- Malachite Pendant
        [32179] = {t = 2032}, -- Tigerseye Band
        [32259] = {t = 2031, a = true}, -- Rough Stone Statue
        [32284] = {t = 2046}, -- Lesser Rune of Warding
        [32454] = {t = 2048}, -- Knothide Leather
        [32455] = {t = 2048}, -- Heavy Knothide Leather
        [32456] = {t = 2048}, -- Knothide Armor Kit
        [32462] = {t = 2048}, -- Felscale Gloves
        [32463] = {t = 2048}, -- Felscale Boots
        [32464] = {t = 2048}, -- Felscale Pants
        [32465] = {t = 2048}, -- Felscale Breastplate
        [32466] = {t = 2048}, -- Scaled Draenic Pants
        [32467] = {t = 2048}, -- Scaled Draenic Gloves
        [32468] = {t = 2048}, -- Scaled Draenic Vest
        [32469] = {t = 2048}, -- Scaled Draenic Boots
        [32470] = {t = 2048}, -- Thick Draenic Gloves
        [32471] = {t = 2048}, -- Thick Draenic Pants
        [32472] = {t = 2048}, -- Thick Draenic Boots
        [32473] = {t = 2048}, -- Thick Draenic Vest
        [32478] = {t = 2048}, -- Wild Draenish Boots
        [32479] = {t = 2048}, -- Wild Draenish Gloves
        [32480] = {t = 2048}, -- Wild Draenish Leggings
        [32481] = {t = 2048}, -- Wild Draenish Vest
        [32655] = {t = 2046}, -- Fel Iron Rod
        [32664] = {t = 2041}, -- Runed Fel Iron Rod
        [32667] = {t = 2042}, -- Runed Eternium Rod
        [32801] = {t = 2032}, -- Coarse Stone Statue
        [32807] = {t = 2034}, -- Heavy Stone Statue
        [32808] = {t = 2036}, -- Solid Stone Statue
        [32809] = {t = 2038}, -- Dense Stone Statue
        [33732] = {t = 2043}, -- Volatile Healing Potion
        [33733] = {t = 2043}, -- Unstable Mana Potion
        [33738] = {t = 2043}, -- Onslaught Elixir
        [33740] = {t = 2043}, -- Adept's Elixir
        [33741] = {t = 2043}, -- Elixir of Mastery
        [33990] = {t = 2041}, -- Enchant Chest - Major Spirit
        [33991] = {t = 2041}, -- Enchant Chest - Restore Mana Prime
        [33993] = {t = 2041}, -- Enchant Gloves - Blasting
        [33995] = {t = 2041}, -- Enchant Gloves - Major Strength
        [33996] = {t = 2041}, -- Enchant Gloves - Assault
        [34001] = {t = 2041}, -- Enchant Bracer - Major Intellect
        [34002] = {t = 2041}, -- Enchant Bracer - Assault
        [34004] = {t = 2041}, -- Enchant Cloak - Greater Agility
        [34069] = {t = 2044}, -- Smooth Golden Draenite
        [34529] = {t = 2020}, -- Nether Chain Shirt
        [34530] = {t = 2020}, -- Twisting Nether Chain Shirt
        [34533] = {t = 2020}, -- Breastplate of Kings
        [34534] = {t = 2020}, -- Bulwark of Kings
        [34535] = {t = 2021}, -- Fireguard
        [34537] = {t = 2021}, -- Blazeguard
        [34538] = {t = 2021}, -- Lionheart Blade
        [34540] = {t = 2021}, -- Lionheart Champion
        [34541] = {t = 2021}, -- The Planar Edge
        [34542] = {t = 2021}, -- Black Planar Edge
        [34543] = {t = 2021}, -- Lunar Crescent
        [34544] = {t = 2021}, -- Mooncleaver
        [34545] = {t = 2021}, -- Drakefist Hammer
        [34546] = {t = 2021}, -- Dragonmaw
        [34547] = {t = 2021}, -- Thunder
        [34548] = {t = 2021}, -- Deep Thunder
        [34590] = {t = 2044}, -- Bright Blood Garnet
        [34607] = {t = 2046}, -- Fel Weightstone
        [34955] = {t = 2036}, -- Golden Ring of Power
        [34959] = {t = 2036}, -- Truesilver Commander's Ring
        [34960] = {t = 2038}, -- Glowing Thorium Band
        [34961] = {t = 2038}, -- Emerald Lion Ring
        [34979] = {t = 2012}, -- Thick Bronze Darts
        [34981] = {t = 2012}, -- Whirling Steel Axes
        [34982] = {t = 2012}, -- Enchanted Thorium Blades
        [34983] = {t = 2046}, -- Felsteel Whisper Knives
        [35540] = {t = 2048}, -- Drums of War
        [35575] = {t = 2030}, -- Ebon Netherscale Breastplate
        [35576] = {t = 2030}, -- Ebon Netherscale Belt
        [35577] = {t = 2030}, -- Ebon Netherscale Bracers
        [35580] = {t = 2030}, -- Netherstrike Breastplate
        [35582] = {t = 2030}, -- Netherstrike Belt
        [35584] = {t = 2030}, -- Netherstrike Bracers
        [35585] = {t = 2049}, -- Windhawk Hauberk
        [35587] = {t = 2049}, -- Windhawk Belt
        [35588] = {t = 2049}, -- Windhawk Bracers
        [35589] = {t = 2050}, -- Primalstrike Vest
        [35590] = {t = 2050}, -- Primalstrike Belt
        [35591] = {t = 2050}, -- Primalstrike Bracers
        [35750] = {t = 2045}, -- Earth Shatter
        [35751] = {t = 2045}, -- Fire Sunder
        [36074] = {t = 2050}, -- Blackstorm Leggings
        [36075] = {t = 2049}, -- Wildfeather Leggings
        [36076] = {t = 2030}, -- Dragonstrike Leggings
        [36077] = {t = 2050}, -- Primalstorm Breastplate
        [36078] = {t = 2049}, -- Living Crystal Breastplate
        [36079] = {t = 2030}, -- Golden Dragonstrike Breastplate
        [36122] = {t = 2020}, -- Earthforged Leggings
        [36124] = {t = 2020}, -- Windforged Leggings
        [36125] = {t = 2021}, -- Light Earthforged Blade
        [36126] = {t = 2021}, -- Light Skyforged Axe
        [36128] = {t = 2021}, -- Light Emberforged Hammer
        [36129] = {t = 2020}, -- Heavy Earthforged Breastplate
        [36130] = {t = 2020}, -- Stormforged Hauberk
        [36131] = {t = 2021}, -- Windforged Rapier
        [36133] = {t = 2021}, -- Stoneforged Claymore
        [36134] = {t = 2021}, -- Stormforged Axe
        [36135] = {t = 2021}, -- Skyforged Great Axe
        [36136] = {t = 2021}, -- Lavaforged Warhammer
        [36137] = {t = 2021}, -- Great Earthforged Hammer
        [36256] = {t = 2020}, -- Embrace of the Twisting Nether
        [36257] = {t = 2020}, -- Bulwark of the Ancient Kings
        [36258] = {t = 2021}, -- Blazefury
        [36259] = {t = 2021}, -- Lionheart Executioner
        [36260] = {t = 2021}, -- Wicked Edge of the Planes
        [36261] = {t = 2021}, -- Bloodmoon
        [36262] = {t = 2021}, -- Dragonstrike
        [36263] = {t = 2021}, -- Stormherald
        [36523] = {t = 2034}, -- Brilliant Necklace
        [36524] = {t = 2034}, -- Heavy Jade Ring
        [36525] = {t = 2038}, -- Red Ring of Destruction
        [36526] = {t = 2038}, -- Diamond Focus Ring
        [37818] = {t = 2034}, -- Bronze Band of Force
        [37836] = {t = 2009}, -- Spice Bread
        [38068] = {t = 2039}, -- Mercurial Adamantite
        [38070] = {t = 2043}, -- Mercurial Stone
        [38175] = {t = 2034}, -- Bronze Torc
        [39636] = {t = 2043}, -- Elixir of Major Fortitude
        [39638] = {t = 2043}, -- Elixir of Draenic Wisdom
        [39971] = {t = 2047}, -- Icy Blasting Primers
        [39973] = {t = 2047}, -- Frost Grenades
        [40000] = {u = true}, -- Bracers of Shackled Souls
        [40274] = {t = 2047}, -- Furious Gizmatic Goggles
        [40514] = {t = 2044}, -- Necklace of the Deep
        [41307] = {t = 2047}, -- Gyro-balanced Khorium Destroyer
        [41311] = {t = 2047}, -- Justicebringer 2000 Specs
        [41312] = {t = 2047}, -- Tankatronic Goggles
        [41314] = {t = 2047}, -- Surestrike Goggles v2.0
        [41315] = {t = 2047}, -- Gadgetstorm Goggles
        [41316] = {t = 2047}, -- Living Replicator Specs
        [41317] = {t = 2047}, -- Deathblow X11 Goggles
        [41318] = {t = 2047}, -- Wonderheal XT40 Shades
        [41319] = {t = 2047}, -- Magnified Moon Specs
        [41320] = {t = 2047}, -- Destruction Holo-gogs
        [41321] = {t = 2047}, -- Powerheal 4000 Lens
        [41414] = {t = 2044}, -- Brilliant Pearl Band
        [41415] = {t = 2044}, -- The Black Pearl
        [41418] = {t = 2044}, -- Crown of the Sea Witch
        [41420] = {t = 2044}, -- Purified Jaggal Pearl
        [41429] = {t = 2044}, -- Purified Shadow Pearl
        [41458] = {d = {28575}}, -- Cauldron of Major Arcane Protection
        [41500] = {d = {28571}}, -- Cauldron of Major Fire Protection
        [41501] = {d = {28572}}, -- Cauldron of Major Frost Protection
        [41502] = {d = {28573}}, -- Cauldron of Major Nature Protection
        [41503] = {d = {28576}}, -- Cauldron of Major Shadow Protection
        [42613] = {t = 2041}, -- Nexus Transformation
        [42615] = {t = 2041}, -- Small Prismatic Shard
        [44155] = {t = 2051}, -- Flying Machine
        [44343] = {t = 2048}, -- Knothide Ammo Pouch
        [44344] = {t = 2048}, -- Knothide Quiver
        [44383] = {t = 2041}, -- Enchant Shield - Resilience
        [44484] = {t = 2042}, -- Enchant Gloves - Expertise
        [44488] = {t = 2042}, -- Enchant Gloves - Precision
        [44489] = {t = 2042}, -- Enchant Shield - Defense
        [44492] = {t = 2042}, -- Enchant Chest - Mighty Health
        [44500] = {t = 2042}, -- Enchant Cloak - Superior Agility
        [44506] = {t = 2042}, -- Enchant Gloves - Gatherer
        [44508] = {t = 2042}, -- Enchant Boots - Greater Spirit
        [44509] = {t = 2042}, -- Enchant Chest - Greater Mana Restoration
        [44510] = {t = 2042}, -- Enchant Weapon - Exceptional Spirit
        [44513] = {t = 2042}, -- Enchant Gloves - Greater Assault
        [44528] = {t = 2042}, -- Enchant Boots - Greater Fortitude
        [44529] = {t = 2042}, -- Enchant Gloves - Major Agility
        [44555] = {t = 2042}, -- Enchant Bracers - Exceptional Intellect
        [44582] = {t = 2042}, -- Enchant Cloak - Spell Piercing
        [44584] = {t = 2042}, -- Enchant Boots - Greater Vitality
        [44589] = {t = 2042}, -- Enchant Boots - Superior Agility
        [44592] = {t = 2042}, -- Enchant Gloves - Exceptional Spellpower
        [44593] = {t = 2042}, -- Enchant Bracers - Major Spirit
        [44598] = {t = 2042}, -- Enchant Bracers - Expertise
        [44616] = {t = 2042}, -- Enchant Bracers - Greater Stats
        [44623] = {t = 2042}, -- Enchant Chest - Super Stats
        [44629] = {t = 2042}, -- Enchant Weapon - Exceptional Spellpower
        [44630] = {t = 2042}, -- Enchant 2H Weapon - Greater Savagery
        [44633] = {t = 2042}, -- Enchant Weapon - Exceptional Agility
        [44635] = {t = 2042}, -- Enchant Bracers - Greater Spellpower
        [44636] = {t = 2042}, -- Enchant Ring - Greater Spellpower
        [44645] = {t = 2042}, -- Enchant Ring - Assault
        [44770] = {t = 2048}, -- Glove Reinforcements
        [44970] = {t = 2048}, -- Heavy Knothide Armor Kit
        [45061] = {t = 2043}, -- Mad Alchemist's Potion
        [45100] = {t = 2048}, -- Leatherworker's Satchel
        [45382] = {t = 2052, a = true}, -- Scroll of Stamina
        [45545] = {t = 2053}, -- Frostweave Bandage
        [45549] = {t = 2054}, -- Mammoth Meal
        [45550] = {t = 2054}, -- Shoveltusk Steak
        [45551] = {t = 2054}, -- Worm Delight
        [45552] = {t = 2054}, -- Roasted Worg
        [45553] = {t = 2054}, -- Rhino Dogs
        [45554] = {t = 2054}, -- Great Feast
        [45560] = {t = 2054}, -- Smoked Rockfin
        [45561] = {t = 2054}, -- Grilled Bonescale
        [45562] = {t = 2054}, -- Sauteed Goby
        [45563] = {t = 2054}, -- Grilled Sculpin
        [45564] = {t = 2054}, -- Smoked Salmon
        [45565] = {t = 2054}, -- Poached Nettlefish
        [45566] = {t = 2054}, -- Pickled Fangtooth
        [45569] = {t = 2054}, -- Baked Manta Ray
        [47280] = {t = 2044}, -- Brilliant Glass
        [47766] = {t = 2042}, -- Enchant Chest - Greater Defense
        [47900] = {t = 2042}, -- Enchant Chest - Super Health
        [48114] = {t = 2052, a = true}, -- Scroll of Intellect
        [48116] = {t = 2052, a = true}, -- Scroll of Spirit
        [48121] = {t = 2052}, -- Glyph of Entangling Roots
        [48247] = {t = 2052}, -- Mysterious Tarot
        [48248] = {t = 2052}, -- Scroll of Recall
        [49252] = {t = 2055}, -- Smelt Cobalt
        [49258] = {t = 2055}, -- Smelt Saronite
        [50598] = {t = 2052}, -- Scroll of Intellect II
        [50599] = {t = 2052}, -- Scroll of Intellect III
        [50600] = {t = 2052}, -- Scroll of Intellect IV
        [50601] = {t = 2052}, -- Scroll of Intellect V
        [50602] = {t = 2052}, -- Scroll of Intellect VI
        [50603] = {t = 2056}, -- Scroll of Intellect VII
        [50604] = {t = 2056}, -- Scroll of Intellect VIII
        [50605] = {t = 2052}, -- Scroll of Spirit II
        [50606] = {t = 2052}, -- Scroll of Spirit III
        [50607] = {t = 2052}, -- Scroll of Spirit IV
        [50608] = {t = 2052}, -- Scroll of Spirit V
        [50609] = {t = 2052}, -- Scroll of Spirit VI
        [50610] = {t = 2056}, -- Scroll of Spirit VII
        [50611] = {t = 2056}, -- Scroll of Spirit VIII
        [50612] = {t = 2052}, -- Scroll of Stamina II
        [50614] = {t = 2052}, -- Scroll of Stamina III
        [50616] = {t = 2052}, -- Scroll of Stamina IV
        [50617] = {t = 2052}, -- Scroll of Stamina V
        [50618] = {t = 2052}, -- Scroll of Stamina VI
        [50619] = {t = 2056}, -- Scroll of Stamina VII
        [50620] = {t = 2056}, -- Scroll of Stamina VIII
        [50936] = {t = 2057}, -- Heavy Borean Leather
        [50938] = {t = 2057}, -- Iceborne Chestguard
        [50939] = {t = 2057}, -- Iceborne Leggings
        [50940] = {t = 2057}, -- Iceborne Shoulderpads
        [50941] = {t = 2057}, -- Iceborne Gloves
        [50942] = {t = 2057}, -- Iceborne Boots
        [50943] = {t = 2057}, -- Iceborne Belt
        [50944] = {t = 2057}, -- Arctic Chestpiece
        [50945] = {t = 2057}, -- Arctic Leggings
        [50946] = {t = 2057}, -- Arctic Shoulderpads
        [50947] = {t = 2057}, -- Arctic Gloves
        [50948] = {t = 2057}, -- Arctic Boots
        [50949] = {t = 2057}, -- Arctic Belt
        [50950] = {t = 2057}, -- Frostscale Chestguard
        [50951] = {t = 2057}, -- Frostscale Leggings
        [50952] = {t = 2057}, -- Frostscale Shoulders
        [50953] = {t = 2057}, -- Frostscale Gloves
        [50954] = {t = 2057}, -- Frostscale Boots
        [50955] = {t = 2057}, -- Frostscale Belt
        [50956] = {t = 2057}, -- Nerubian Chestguard
        [50957] = {t = 2057}, -- Nerubian Legguards
        [50958] = {t = 2057}, -- Nerubian Shoulders
        [50959] = {t = 2057}, -- Nerubian Gloves
        [50960] = {t = 2057}, -- Nerubian Boots
        [50961] = {t = 2057}, -- Nerubian Belt
        [50962] = {t = 2057}, -- Borean Armor Kit
        [50963] = {t = 2057}, -- Heavy Borean Armor Kit
        [50964] = {t = 2057}, -- Jormungar Leg Armor
        [50965] = {t = 2057}, -- Frosthide Leg Armor
        [50966] = {t = 2057}, -- Nerubian Leg Armor
        [50967] = {t = 2057}, -- Icescale Leg Armor
        [51568] = {t = 2057}, -- Black Chitinguard Boots
        [51569] = {t = 2057}, -- Dark Arctic Leggings
        [51570] = {t = 2057}, -- Dark Arctic Chestpiece
        [51571] = {t = 2057}, -- Arctic Wristguards
        [51572] = {t = 2057}, -- Arctic Helm
        [52567] = {t = 2058}, -- Cobalt Legplates
        [52568] = {t = 2058}, -- Cobalt Belt
        [52569] = {t = 2058}, -- Cobalt Boots
        [52570] = {t = 2058}, -- Cobalt Chestpiece
        [52571] = {t = 2058}, -- Cobalt Helm
        [52572] = {t = 2058}, -- Cobalt Shoulders
        [52738] = {t = 2052, a = true}, -- Ivory Ink
        [52739] = {t = 2052}, -- Armor Vellum
        [52840] = {t = 2052}, -- Weapon Vellum
        [52843] = {t = 2052}, -- Moonglow Ink
        [53056] = {q = {{13571, 32516, 4395}, {13571, 32516, 4395}}}, -- Kungaloosh
        [53281] = {t = 2059}, -- Volatile Blasting Trigger
        [53462] = {t = 2052}, -- Midnight Ink
        [53770] = {u = true}, -- Scourge Haunt Visual
        [53771] = {d = {60350}}, -- Transmute: Eternal Life to Shadow
        [53772] = {u = true}, -- Scourge Haunt Visual, Face Player and give GUID
        [53773] = {d = {60350}}, -- Transmute: Eternal Life to Fire
        [53774] = {d = {60350}}, -- Transmute: Eternal Fire to Water
        [53775] = {d = {60350}}, -- Transmute: Eternal Fire to Life
        [53776] = {d = {60350}}, -- Transmute: Eternal Air to Water
        [53777] = {d = {60350}}, -- Transmute: Eternal Air to Earth
        [53778] = {u = true}, -- Lay On Hands
        [53779] = {d = {60350}}, -- Transmute: Eternal Shadow to Earth
        [53780] = {d = {60350}}, -- Transmute: Eternal Shadow to Life
        [53781] = {d = {60350}}, -- Transmute: Eternal Earth to Air
        [53782] = {d = {60350}}, -- Transmute: Eternal Earth to Shadow
        [53783] = {d = {60350}}, -- Transmute: Eternal Water to Air
        [53784] = {d = {60350}}, -- Transmute: Eternal Water to Fire
        [53812] = {t = 2060}, -- Pygmy Oil
        [53831] = {t = 2061}, -- Bold Bloodstone
        [53832] = {t = 2061}, -- Delicate Bloodstone
        [53834] = {t = 2061}, -- Runed Bloodstone
        [53835] = {t = 2061}, -- Bright Bloodstone
        [53836] = {t = 2060}, -- Runic Healing Potion
        [53837] = {t = 2060}, -- Runic Mana Potion
        [53838] = {t = 2060}, -- Resurgent Healing Potion
        [53839] = {t = 2060}, -- Icy Mana Potion
        [53840] = {t = 2060}, -- Elixir of Mighty Agility
        [53841] = {t = 2060}, -- Wrath Elixir
        [53842] = {t = 2060}, -- Spellpower Elixir
        [53843] = {t = 2061}, -- Subtle Bloodstone
        [53844] = {t = 2061}, -- Flashing Bloodstone
        [53845] = {t = 2061}, -- Fractured Bloodstone
        [53847] = {t = 2060}, -- Elixir of Spirit
        [53848] = {t = 2060}, -- Guru's Elixir
        [53852] = {t = 2061}, -- Brilliant Sun Crystal
        [53853] = {t = 2061}, -- Smooth Sun Crystal
        [53854] = {t = 2061}, -- Rigid Sun Crystal
        [53855] = {t = 2061}, -- Thick Sun Crystal
        [53856] = {t = 2061}, -- Quick Sun Crystal
        [53859] = {t = 2061}, -- Sovereign Shadow Crystal
        [53860] = {t = 2061}, -- Shifting Shadow Crystal
        [53861] = {t = 2061}, -- Tenuous Shadow Crystal
        [53862] = {t = 2061}, -- Glowing Shadow Crystal
        [53863] = {t = 2061}, -- Purified Shadow Crystal
        [53864] = {t = 2061}, -- Royal Shadow Crystal
        [53866] = {t = 2061}, -- Balanced Shadow Crystal
        [53867] = {t = 2061}, -- Infused Shadow Crystal
        [53868] = {t = 2061}, -- Regal Shadow Crystal
        [53870] = {t = 2061}, -- Puissant Shadow Crystal
        [53871] = {t = 2061}, -- Guardian's Shadow Crystal
        [53872] = {t = 2061}, -- Inscribed Huge Citrine
        [53873] = {t = 2061}, -- Etched Huge Citrine
        [53874] = {t = 2061}, -- Champion's Huge Citrine
        [53876] = {t = 2061}, -- Fierce Huge Citrine
        [53878] = {t = 2061}, -- Glinting Huge Citrine
        [53880] = {t = 2061}, -- Deft Huge Citrine
        [53881] = {t = 2061}, -- Luminous Huge Citrine
        [53882] = {t = 2061}, -- Potent Huge Citrine
        [53883] = {t = 2061}, -- Veiled Huge Citrine
        [53886] = {t = 2061}, -- Wicked Huge Citrine
        [53887] = {t = 2061}, -- Pristine Huge Citrine
        [53889] = {t = 2061}, -- Stark Huge Citrine
        [53890] = {t = 2061}, -- Stalwart Huge Citrine
        [53891] = {t = 2061}, -- Glimmering Huge Citrine
        [53892] = {t = 2061}, -- Accurate Huge Citrine
        [53893] = {t = 2061}, -- Resolute Huge Citrine
        [53894] = {t = 2061}, -- Timeless Dark Jade
        [53895] = {d = {60893}}, -- Crazy Alchemist's Potion
        [53898] = {t = 2060}, -- Elixir of Mighty Fortitude
        [53899] = {t = 2060}, -- Lesser Flask of Toughness
        [53900] = {t = 2060}, -- Potion of Nightmares
        [53901] = {t = 2060}, -- Flask of the Frost Wyrm
        [53902] = {t = 2060}, -- Flask of Stoneblood
        [53903] = {t = 2060}, -- Flask of Endless Rage
        [53904] = {d = {60893}}, -- Powerful Rejuvenation Potion
        [53905] = {t = 2060}, -- Indestructible Potion
        [53916] = {t = 2061}, -- Jagged Dark Jade
        [53918] = {t = 2061}, -- Enduring Dark Jade
        [53920] = {t = 2061}, -- Forceful Dark Jade
        [53922] = {t = 2061}, -- Misty Dark Jade
        [53923] = {t = 2061}, -- Shining Dark Jade
        [53925] = {t = 2061}, -- Intricate Dark Jade
        [53926] = {t = 2061}, -- Dazzling Dark Jade
        [53927] = {t = 2061}, -- Sundered Dark Jade
        [53928] = {t = 2061}, -- Lambent Dark Jade
        [53930] = {t = 2061}, -- Energized Dark Jade
        [53931] = {t = 2061}, -- Radiant Dark Jade
        [53934] = {t = 2061}, -- Solid Chalcedony
        [53940] = {t = 2061}, -- Sparkling Chalcedony
        [53941] = {t = 2061}, -- Lustrous Chalcedony
        [53947] = {t = 2062}, -- Bright Scarlet Ruby
        [53953] = {t = 2062}, -- Sparkling Sky Sapphire
        [53956] = {t = 2062}, -- Brilliant Autumn's Glow
        [53969] = {t = 2062}, -- Balanced Twilight Opal
        [53989] = {t = 2062}, -- Pristine Monarch Topaz
        [54007] = {t = 2062}, -- Dazzling Forest Emerald
        [54017] = {t = 2061}, -- Precise Bloodstone
        [54020] = {d = {60893}}, -- Transmute: Eternal Might
        [54213] = {t = 2060}, -- Flask of Pure Mojo
        [54218] = {t = 2060}, -- Elixir of Mighty Strength
        [54220] = {d = {60893}}, -- Elixir of Protection
        [54221] = {d = {60893}}, -- Potion of Speed
        [54222] = {d = {60893}}, -- Potion of Wild Magic
        [54353] = {t = 2059}, -- Mark "S" Boomstick
        [54550] = {t = 2058}, -- Cobalt Triangle Shield
        [54551] = {t = 2058}, -- Tempered Saronite Belt
        [54552] = {t = 2058}, -- Tempered Saronite Boots
        [54553] = {t = 2058}, -- Tempered Saronite Breastplate
        [54554] = {t = 2058}, -- Tempered Saronite Legplates
        [54555] = {t = 2058}, -- Tempered Saronite Helm
        [54556] = {t = 2058}, -- Tempered Saronite Shoulders
        [54557] = {t = 2058}, -- Saronite Defender
        [54736] = {t = 2059}, -- Personal Electromagnetic Pulse Generator
        [54793] = {t = 2059}, -- Frag Belt
        [54917] = {t = 2058}, -- Spiked Cobalt Helm
        [54918] = {t = 2058}, -- Spiked Cobalt Boots
        [54941] = {t = 2058}, -- Spiked Cobalt Shoulders
        [54944] = {t = 2058}, -- Spiked Cobalt Chestpiece
        [54945] = {t = 2058}, -- Spiked Cobalt Gauntlets
        [54946] = {t = 2058}, -- Spiked Cobalt Belt
        [54947] = {t = 2058}, -- Spiked Cobalt Legplates
        [54948] = {t = 2058}, -- Spiked Cobalt Bracers
        [54949] = {t = 2058}, -- Horned Cobalt Helm
        [54998] = {t = 2059}, -- Hand-Mounted Pyro Rocket
        [54999] = {t = 2059}, -- Hyperspeed Accelerators
        [55002] = {t = 2059}, -- Flexweave Underlay
        [55013] = {t = 2058}, -- Saronite Protector
        [55014] = {t = 2058}, -- Saronite Bulwark
        [55015] = {t = 2058}, -- Tempered Saronite Gauntlets
        [55016] = {t = 2059}, -- Nitro Boosts
        [55017] = {t = 2058}, -- Tempered Saronite Bracers
        [55055] = {t = 2058}, -- Brilliant Saronite Legplates
        [55056] = {t = 2058}, -- Brilliant Saronite Gauntlets
        [55057] = {t = 2058}, -- Brilliant Saronite Boots
        [55058] = {t = 2058}, -- Brilliant Saronite Breastplate
        [55174] = {t = 2058}, -- Honed Cobalt Cleaver
        [55177] = {t = 2058}, -- Savage Cobalt Slicer
        [55179] = {t = 2058}, -- Saronite Ambusher
        [55181] = {t = 2058}, -- Saronite Shiv
        [55182] = {t = 2058}, -- Furious Saronite Beatstick
        [55183] = {t = 2021}, -- Corroded Saronite Edge
        [55184] = {t = 2021}, -- Corroded Saronite Woundbringer
        [55185] = {t = 2021}, -- Saronite Mindcrusher
        [55186] = {t = 2020}, -- Chestplate of Conquest
        [55187] = {t = 2020}, -- Legplates of Conquest
        [55199] = {t = 2057}, -- Cloak of Tormented Skies
        [55200] = {t = 2058}, -- Sturdy Cobalt Quickblade
        [55201] = {t = 2058}, -- Cobalt Tenderizer
        [55202] = {t = 2058}, -- Sure-fire Shuriken
        [55203] = {t = 2058}, -- Forged Cobalt Claymore
        [55204] = {t = 2058}, -- Notched Cobalt War Axe
        [55206] = {t = 2058}, -- Deadly Saronite Dirk
        [55208] = {t = 2055}, -- Smelt Titansteel
        [55211] = {t = 2055}, -- Smelt Titanium
        [55243] = {u = true}, -- Bracers of Deflection
        [55252] = {q = {{12889, 29806, 67}, {13843}, {12889, 29806, 67}, {13843}}}, -- Scrapbot Construction Kit
        [55298] = {t = 2058}, -- Vengeance Bindings
        [55300] = {t = 2058}, -- Righteous Gauntlets
        [55301] = {t = 2058}, -- Daunting Handguards
        [55302] = {t = 2058}, -- Helm of Command
        [55303] = {t = 2058}, -- Daunting Legplates
        [55304] = {t = 2058}, -- Righteous Greaves
        [55305] = {t = 2058}, -- Savage Saronite Bracers
        [55306] = {t = 2058}, -- Savage Saronite Pauldrons
        [55307] = {t = 2058}, -- Savage Saronite Waistguard
        [55308] = {t = 2058}, -- Savage Saronite Walkers
        [55309] = {t = 2058}, -- Savage Saronite Gauntlets
        [55310] = {t = 2058}, -- Savage Saronite Legplates
        [55311] = {t = 2058}, -- Savage Saronite Hauberk
        [55312] = {t = 2058}, -- Savage Saronite Skullshield
        [55369] = {t = 2058}, -- Titansteel Destroyer
        [55370] = {t = 2058}, -- Titansteel Bonecrusher
        [55371] = {t = 2058}, -- Titansteel Guardian
        [55372] = {t = 2058}, -- Spiked Titansteel Helm
        [55373] = {t = 2058}, -- Tempered Titansteel Helm
        [55374] = {t = 2058}, -- Brilliant Titansteel Helm
        [55375] = {t = 2058}, -- Spiked Titansteel Treads
        [55376] = {t = 2058}, -- Tempered Titansteel Treads
        [55377] = {t = 2058}, -- Brilliant Titansteel Treads
        [55386] = {t = 2063}, -- Tireless Skyflare Diamond
        [55394] = {t = 2063}, -- Swift Skyflare Diamond
        [55399] = {t = 2063}, -- Powerful Earthsiege Diamond
        [55402] = {t = 2063}, -- Persistent Earthsiege Diamond
        [55628] = {t = 2058}, -- Socket Bracer
        [55641] = {t = 2058}, -- Socket Gloves
        [55642] = {t = 2064}, -- Lightweave Embroidery
        [55656] = {t = 2058}, -- Eternal Belt Buckle
        [55732] = {t = 2058}, -- Titanium Rod
        [55769] = {t = 2064}, -- Darkglow Embroidery
        [55777] = {t = 2064}, -- Swordguard Embroidery
        [55834] = {t = 2058}, -- Cobalt Bracers
        [55835] = {t = 2058}, -- Cobalt Gauntlets
        [55839] = {t = 2058}, -- Titanium Weapon Chain
        [55898] = {t = 2064}, -- Frostweave Net
        [55899] = {t = 2064}, -- Bolt of Frostweave
        [55900] = {t = 2064}, -- Bolt of Imbued Frostweave
        [55901] = {t = 2064}, -- Duskweave Leggings
        [55902] = {t = 2064}, -- Frostwoven Shoulders
        [55903] = {t = 2064}, -- Frostwoven Robe
        [55904] = {t = 2064}, -- Frostwoven Gloves
        [55906] = {t = 2064}, -- Frostwoven Boots
        [55907] = {t = 2064}, -- Frostwoven Cowl
        [55908] = {t = 2064}, -- Frostwoven Belt
        [55910] = {t = 2064}, -- Mystic Frostwoven Shoulders
        [55911] = {t = 2064}, -- Mystic Frostwoven Robe
        [55913] = {t = 2064}, -- Mystic Frostwoven Wristwraps
        [55914] = {t = 2064}, -- Duskweave Belt
        [55919] = {t = 2064}, -- Duskweave Cowl
        [55920] = {t = 2064}, -- Duskweave Wristwraps
        [55921] = {t = 2064}, -- Duskweave Robe
        [55922] = {t = 2064}, -- Duskweave Gloves
        [55923] = {t = 2064}, -- Duskweave Shoulders
        [55924] = {t = 2065}, -- Duskweave Boots
        [55925] = {t = 2064}, -- Black Duskweave Leggings
        [55941] = {t = 2064}, -- Black Duskweave Robe
        [55943] = {t = 2064}, -- Black Duskweave Wristwraps
        [55995] = {t = 2064}, -- Yellow Lumberjack Shirt
        [56000] = {t = 2064}, -- Green Workman's Shirt
        [56001] = {t = 2064}, -- Moonshroud
        [56002] = {t = 2064}, -- Ebonweave
        [56003] = {t = 2064}, -- Spellweave
        [56007] = {t = 2064}, -- Frostweave Bag
        [56008] = {t = 2064}, -- Shining Spellthread
        [56010] = {t = 2064}, -- Azure Spellthread
        [56014] = {t = 2064}, -- Cloak of the Moon
        [56015] = {t = 2064}, -- Cloak of Frozen Spirits
        [56016] = {t = 2066}, -- Wispcloak
        [56017] = {t = 2066}, -- Deathchill Cloak
        [56018] = {t = 2064}, -- Hat of Wintry Doom
        [56019] = {t = 2064}, -- Silky Iceshard Boots
        [56020] = {t = 2064}, -- Deep Frozen Cord
        [56021] = {t = 2064}, -- Frostmoon Pants
        [56022] = {t = 2064}, -- Light Blessed Mittens
        [56023] = {t = 2064}, -- Aurora Slippers
        [56024] = {t = 2064}, -- Moonshroud Robe
        [56025] = {t = 2064}, -- Moonshroud Gloves
        [56026] = {t = 2064}, -- Ebonweave Robe
        [56027] = {t = 2064}, -- Ebonweave Gloves
        [56028] = {t = 2064}, -- Spellweave Robe
        [56029] = {t = 2064}, -- Spellweave Gloves
        [56030] = {t = 2064}, -- Frostwoven Leggings
        [56031] = {t = 2064}, -- Frostwoven Wristwraps
        [56034] = {t = 2064}, -- Master's Spellthread
        [56039] = {t = 2064}, -- Sanctified Spellthread
        [56048] = {t = 2065, u = true}, -- Duskweave Boots
        [56193] = {t = 2062}, -- Bloodstone Band
        [56194] = {t = 2062}, -- Sun Rock Ring
        [56195] = {t = 2062}, -- Jade Dagger Pendant
        [56196] = {t = 2062}, -- Blood Sun Necklace
        [56197] = {t = 2062}, -- Dream Signet
        [56199] = {t = 2062}, -- Ruby Hare
        [56201] = {t = 2062}, -- Twilight Serpent
        [56202] = {t = 2062}, -- Sapphire Owl
        [56203] = {t = 2062}, -- Emerald Boar
        [56205] = {t = 2062}, -- Dark Jade Focusing Lens
        [56206] = {t = 2062}, -- Shadow Crystal Focusing Lens
        [56208] = {t = 2062}, -- Shadow Jade Focusing Lens
        [56234] = {t = 2058}, -- Titansteel Shanker
        [56280] = {t = 2058}, -- Cudgel of Saronite Justice
        [56349] = {t = 2059}, -- Handful of Cobalt Bolts
        [56357] = {t = 2058}, -- Titanium Shield Spike
        [56400] = {t = 2058}, -- Titansteel Shield Wall
        [56459] = {t = 2059}, -- Hammer Pick
        [56460] = {t = 2059}, -- Cobalt Frag Bomb
        [56461] = {t = 2059}, -- Bladed Pickaxe
        [56462] = {t = 2059}, -- Gnomish Army Knife
        [56463] = {t = 2059}, -- Explosive Decoy
        [56464] = {t = 2059}, -- Overcharged Capacitor
        [56465] = {t = 2059}, -- Mechanized Snow Goggles
        [56466] = {t = 2059}, -- Sonic Booster
        [56467] = {t = 2059}, -- Noise Machine
        [56468] = {t = 2067}, -- Box of Bombs
        [56469] = {t = 2059}, -- Gnomish Lightning Generator
        [56470] = {t = 2059}, -- Sun Scope
        [56471] = {t = 2059}, -- Froststeel Tube
        [56472] = {t = 2059}, -- MOLL-E
        [56473] = {t = 2027}, -- Gnomish X-Ray Specs
        [56474] = {t = 2059}, -- Mammoth Cutters
        [56475] = {t = 2059}, -- Saronite Razorheads
        [56476] = {t = 2059}, -- Healing Injector Kit
        [56477] = {t = 2059}, -- Mana Injector Kit
        [56478] = {t = 2059}, -- Heartseeker Scope
        [56479] = {t = 2059}, -- Armor Plated Combat Shotgun
        [56480] = {t = 2059}, -- Armored Titanium Goggles
        [56481] = {t = 2059}, -- Weakness Spectralizers
        [56483] = {t = 2059}, -- Charged Titanium Specs
        [56484] = {t = 2059}, -- Visage Liquification Goggles
        [56486] = {t = 2059}, -- Greensight Gogs
        [56487] = {t = 2059}, -- Electroflux Sight Enhancers
        [56514] = {t = 2019}, -- Global Thermal Sapper Charge
        [56519] = {d = {60893}}, -- Elixir of Mighty Mageblood
        [56530] = {t = 2062}, -- Enchanted Pearl
        [56531] = {t = 2062}, -- Enchanted Tear
        [56549] = {t = 2058}, -- Ornate Saronite Bracers
        [56550] = {t = 2058}, -- Ornate Saronite Pauldrons
        [56551] = {t = 2058}, -- Ornate Saronite Waistguard
        [56552] = {t = 2058}, -- Ornate Saronite Walkers
        [56553] = {t = 2058}, -- Ornate Saronite Gauntlets
        [56554] = {t = 2058}, -- Ornate Saronite Legplates
        [56555] = {t = 2058}, -- Ornate Saronite Hauberk
        [56556] = {t = 2058}, -- Ornate Saronite Skullshield
        [56574] = {t = 2059}, -- Truesight Ice Blinders
        [56943] = {t = 2068}, -- Glyph of Frenzied Regeneration
        [56944] = {d = {61177, 61756}}, -- Glyph of Growl
        [56945] = {t = 2052}, -- Glyph of Healing Touch
        [56946] = {d = {61177, 61756}}, -- Glyph of Hurricane
        [56947] = {d = {61177, 61756}}, -- Glyph of Innervate
        [56948] = {t = 2052}, -- Glyph of Insect Swarm
        [56949] = {d = {61177, 61756}}, -- Glyph of Lifebloom
        [56950] = {d = {61177, 61756}}, -- Glyph of Mangle
        [56951] = {t = 2052}, -- Glyph of Moonfire
        [56952] = {t = 2068}, -- Glyph of Rake
        [56953] = {t = 2052}, -- Glyph of Rebirth
        [56954] = {d = {61177, 61756}}, -- Glyph of Regrowth
        [56955] = {t = 2052}, -- Glyph of Rejuvenation
        [56956] = {t = 2052}, -- Glyph of Rip
        [56957] = {t = 2052}, -- Glyph of Shred
        [56958] = {d = {61177, 61756}}, -- Glyph of Starfall
        [56959] = {t = 2052}, -- Glyph of Starfire
        [56960] = {d = {61177, 61756}}, -- Glyph of Swiftmend
        [56961] = {t = 2052}, -- Glyph of Maul
        [56963] = {t = 2052}, -- Glyph of Wrath
        [56965] = {d = {61288}}, -- Glyph of Typhoon
        [56968] = {t = 2052}, -- Glyph of Arcane Explosion
        [56971] = {t = 2052}, -- Glyph of Arcane Missiles
        [56972] = {t = 2068}, -- Glyph of Arcane Power
        [56973] = {t = 2052}, -- Glyph of Blink
        [56974] = {t = 2052}, -- Glyph of Evocation
        [56975] = {d = {61177, 61756}}, -- Glyph of Fireball
        [56976] = {t = 2052}, -- Glyph of Frost Nova
        [56977] = {d = {61177, 61756}}, -- Glyph of Frostbolt
        [56978] = {t = 2052}, -- Glyph of Ice Armor
        [56979] = {t = 2052}, -- Glyph of Ice Block
        [56980] = {t = 2056, d = {61177, 61756}}, -- Glyph of Ice Lance
        [56981] = {t = 2052}, -- Glyph of Icy Veins
        [56982] = {t = 2052}, -- Glyph of Scorch
        [56983] = {d = {61177, 61756}}, -- Glyph of Invisibility
        [56984] = {t = 2068}, -- Glyph of Mage Armor
        [56985] = {t = 2052}, -- Glyph of Mana Gem
        [56986] = {d = {61177, 61756}}, -- Glyph of Molten Armor
        [56987] = {t = 2056, d = {61177, 61756}}, -- Glyph of Polymorph
        [56988] = {d = {61177, 61756}}, -- Glyph of Remove Curse
        [56989] = {d = {61177, 61756}}, -- Glyph of Water Elemental
        [56990] = {d = {61288}}, -- Glyph of Blast Wave
        [56991] = {t = 2068}, -- Glyph of Arcane Blast
        [56994] = {t = 2052}, -- Glyph of Aimed Shot
        [56995] = {t = 2052}, -- Glyph of Arcane Shot
        [56996] = {d = {61177, 61756}}, -- Glyph of the Beast
        [56997] = {t = 2052}, -- Glyph of Mending
        [56998] = {d = {61177, 61756}}, -- Glyph of Aspect of the Viper
        [56999] = {d = {61177, 61756}}, -- Glyph of Bestial Wrath
        [57000] = {t = 2052}, -- Glyph of Deterrence
        [57001] = {t = 2052}, -- Glyph of Disengage
        [57002] = {t = 2052}, -- Glyph of Freezing Trap
        [57003] = {t = 2068}, -- Glyph of Frost Trap
        [57004] = {t = 2052}, -- Glyph of Hunter's Mark
        [57005] = {t = 2052}, -- Glyph of Immolation Trap
        [57006] = {t = 2056, d = {61177, 61756}}, -- Glyph of the Hawk
        [57007] = {t = 2052}, -- Glyph of Multi-Shot
        [57008] = {t = 2068}, -- Glyph of Rapid Fire
        [57009] = {t = 2052}, -- Glyph of Serpent Sting
        [57010] = {d = {61177, 61756}}, -- Glyph of Snake Trap
        [57011] = {d = {61177, 61756}}, -- Glyph of Steady Shot
        [57012] = {d = {61177, 61756}}, -- Glyph of Trueshot Aura
        [57013] = {d = {61177, 61756}}, -- Glyph of Volley
        [57014] = {d = {61177, 61756}}, -- Glyph of Wyvern Sting
        [57019] = {d = {61177, 61756}}, -- Glyph of Avenger's Shield
        [57020] = {t = 2052}, -- Glyph of Cleansing
        [57021] = {d = {61177, 61756}}, -- Glyph of Avenging Wrath
        [57022] = {t = 2052}, -- Glyph of Spiritual Attunement
        [57023] = {t = 2052}, -- Glyph of Consecration
        [57024] = {t = 2052}, -- Glyph of Crusader Strike
        [57025] = {t = 2052}, -- Glyph of Exorcism
        [57026] = {t = 2068}, -- Glyph of Flash of Light
        [57027] = {t = 2052}, -- Glyph of Hammer of Justice
        [57028] = {d = {61177, 61756}}, -- Glyph of Hammer of Wrath
        [57029] = {t = 2052}, -- Glyph of Holy Light
        [57030] = {t = 2052}, -- Glyph of Judgement
        [57031] = {t = 2052}, -- Glyph of Divinity
        [57032] = {t = 2052}, -- Glyph of Righteous Defense
        [57033] = {t = 2068}, -- Glyph of Seal of Command
        [57034] = {d = {61177, 61756}}, -- Glyph of Seal of Light
        [57035] = {d = {61177, 61756}}, -- Glyph of Seal of Wisdom
        [57036] = {t = 2056, d = {61177, 61756}}, -- Glyph of Turn Evil
        [57112] = {d = {61177, 61756}}, -- Glyph of Adrenaline Rush
        [57113] = {t = 2068}, -- Glyph of Ambush
        [57114] = {t = 2052}, -- Glyph of Backstab
        [57115] = {d = {61177, 61756}}, -- Glyph of Blade Flurry
        [57116] = {d = {61177, 61756}}, -- Glyph of Crippling Poison
        [57117] = {d = {61177, 61756}}, -- Glyph of Deadly Throw
        [57119] = {t = 2052}, -- Glyph of Evasion
        [57120] = {t = 2052}, -- Glyph of Eviscerate
        [57121] = {t = 2052}, -- Glyph of Expose Armor
        [57122] = {t = 2068}, -- Glyph of Feint
        [57123] = {t = 2052}, -- Glyph of Garrote
        [57124] = {d = {61177, 61756}}, -- Glyph of Ghostly Strike
        [57125] = {t = 2052}, -- Glyph of Gouge
        [57126] = {d = {61177, 61756}}, -- Glyph of Hemorrhage
        [57127] = {d = {61177, 61756}}, -- Glyph of Preparation
        [57128] = {d = {61177, 61756}}, -- Glyph of Rupture
        [57129] = {t = 2052}, -- Glyph of Sap
        [57130] = {d = {61177, 61756}}, -- Glyph of Vigor
        [57131] = {t = 2052}, -- Glyph of Sinister Strike
        [57132] = {t = 2052}, -- Glyph of Slice and Dice
        [57133] = {t = 2052}, -- Glyph of Sprint
        [57151] = {t = 2052}, -- Glyph of Barbaric Insults
        [57152] = {d = {61177, 61756}}, -- Glyph of Blocking
        [57153] = {d = {61177, 61756}}, -- Glyph of Bloodthirst
        [57154] = {t = 2052}, -- Glyph of Cleaving
        [57155] = {d = {61177, 61756}}, -- Glyph of Devastate
        [57156] = {t = 2052}, -- Glyph of Execution
        [57157] = {t = 2052}, -- Glyph of Hamstring
        [57158] = {t = 2052}, -- Glyph of Heroic Strike
        [57159] = {d = {61177, 61756}}, -- Glyph of Intervene
        [57160] = {d = {61177, 61756}}, -- Glyph of Mortal Strike
        [57161] = {t = 2052}, -- Glyph of Overpower
        [57162] = {t = 2052}, -- Glyph of Rapid Charge
        [57163] = {t = 2052}, -- Glyph of Rending
        [57164] = {d = {61177, 61756}}, -- Glyph of Resonating Power
        [57165] = {t = 2052}, -- Glyph of Revenge
        [57166] = {d = {61177, 61756}}, -- Glyph of Last Stand
        [57167] = {t = 2052}, -- Glyph of Sunder Armor
        [57168] = {t = 2068}, -- Glyph of Sweeping Strikes
        [57169] = {d = {61177, 61756}}, -- Glyph of Taunt
        [57170] = {d = {61177, 61756}}, -- Glyph of Victory Rush
        [57172] = {t = 2068}, -- Glyph of Whirlwind
        [57181] = {d = {61177, 61756}}, -- Glyph of Circle of Healing
        [57183] = {t = 2052}, -- Glyph of Dispel Magic
        [57184] = {t = 2052}, -- Glyph of Fade
        [57185] = {t = 2052}, -- Glyph of Fear Ward
        [57186] = {t = 2052}, -- Glyph of Flash Heal
        [57187] = {t = 2068}, -- Glyph of Holy Nova
        [57188] = {t = 2052}, -- Glyph of Inner Fire
        [57189] = {d = {61177, 61756}}, -- Glyph of Lightwell
        [57190] = {d = {61177, 61756}}, -- Glyph of Mass Dispel
        [57191] = {d = {61177, 61756}}, -- Glyph of Mind Control
        [57192] = {t = 2052}, -- Glyph of Shadow Word: Pain
        [57193] = {d = {61177, 61756}}, -- Glyph of Shadow
        [57194] = {t = 2052}, -- Glyph of Power Word: Shield
        [57195] = {d = {61177, 61756}}, -- Glyph of Prayer of Healing
        [57196] = {t = 2052}, -- Glyph of Psychic Scream
        [57197] = {t = 2052}, -- Glyph of Renew
        [57198] = {t = 2056, d = {61177, 61756}}, -- Glyph of Scourge Imprisonment
        [57199] = {d = {61177, 61756}}, -- Glyph of Shadow Word: Death
        [57200] = {t = 2052}, -- Glyph of Mind Flay
        [57201] = {t = 2052}, -- Glyph of Smite
        [57202] = {d = {61177, 61756}}, -- Glyph of Spirit of Redemption
        [57207] = {d = {61177, 61756}}, -- Glyph of Anti-Magic Shell
        [57208] = {d = {61177, 61756}}, -- Glyph of Heart Strike
        [57209] = {d = {61288}}, -- Glyph of Blood Tap
        [57210] = {t = 2052}, -- Glyph of Bone Shield
        [57211] = {d = {61177, 61756}}, -- Glyph of Chains of Ice
        [57212] = {d = {61177, 61756}}, -- Glyph of Dark Command
        [57213] = {t = 2052}, -- Glyph of Death Grip
        [57214] = {d = {61177, 61756}}, -- Glyph of Death and Decay
        [57215] = {d = {61288}}, -- Glyph of Death's Embrace
        [57216] = {t = 2052}, -- Glyph of Frost Strike
        [57217] = {d = {61288}}, -- Glyph of Horn of Winter
        [57218] = {d = {61177, 61756}}, -- Glyph of Icebound Fortitude
        [57219] = {t = 2052}, -- Glyph of Icy Touch
        [57220] = {d = {61177, 61756}}, -- Glyph of Obliterate
        [57221] = {t = 2068}, -- Glyph of Plague Strike
        [57222] = {t = 2068}, -- Glyph of the Ghoul
        [57223] = {d = {61177, 61756}}, -- Glyph of Rune Strike
        [57224] = {t = 2068}, -- Glyph of Scourge Strike
        [57225] = {t = 2056, d = {61177, 61756}}, -- Glyph of Strangulate
        [57226] = {t = 2068}, -- Glyph of Unbreakable Armor
        [57227] = {t = 2068}, -- Glyph of Vampiric Blood
        [57228] = {d = {61288}}, -- Glyph of Raise Dead
        [57229] = {d = {61288}}, -- Glyph of Corpse Explosion
        [57230] = {d = {61288}}, -- Glyph of Pestilence
        [57231] = {u = true}, -- Death Knight Glyph 25
        [57232] = {d = {61177, 61756}}, -- Glyph of Chain Heal
        [57233] = {d = {61177, 61756}}, -- Glyph of Chain Lightning
        [57234] = {d = {61177, 61756}}, -- Glyph of Lava
        [57235] = {d = {61177, 61756}}, -- Glyph of Shocking
        [57236] = {t = 2068}, -- Glyph of Earthliving Weapon
        [57237] = {d = {61177, 61756}}, -- Glyph of Fire Elemental Totem
        [57238] = {t = 2052}, -- Glyph of Fire Nova
        [57239] = {t = 2052}, -- Glyph of Flame Shock
        [57240] = {t = 2052}, -- Glyph of Flametongue Weapon
        [57241] = {t = 2052}, -- Glyph of Frost Shock
        [57242] = {t = 2052}, -- Glyph of Healing Stream Totem
        [57243] = {d = {61177, 61756}}, -- Glyph of Healing Wave
        [57244] = {t = 2052}, -- Glyph of Lesser Healing Wave
        [57245] = {t = 2052}, -- Glyph of Lightning Bolt
        [57246] = {t = 2052}, -- Glyph of Lightning Shield
        [57247] = {d = {61177, 61756}}, -- Glyph of Mana Tide Totem
        [57248] = {t = 2056, d = {61177, 61756}}, -- Glyph of Stormstrike
        [57249] = {t = 2052}, -- Glyph of Lava Lash
        [57250] = {d = {61177, 61756}}, -- Glyph of Elemental Mastery
        [57251] = {t = 2052}, -- Glyph of Water Mastery
        [57252] = {t = 2068}, -- Glyph of Windfury Weapon
        [57253] = {d = {61288}}, -- Glyph of Thunderstorm
        [57257] = {t = 2068}, -- Glyph of Incinerate
        [57258] = {d = {61177, 61756}}, -- Glyph of Conflagrate
        [57259] = {t = 2052}, -- Glyph of Corruption
        [57260] = {d = {61177, 61756}}, -- Glyph of Curse of Agony
        [57261] = {d = {61177, 61756}}, -- Glyph of Death Coil
        [57262] = {t = 2052}, -- Glyph of Fear
        [57263] = {d = {61177, 61756}}, -- Glyph of Felguard
        [57264] = {d = {61177, 61756}}, -- Glyph of Felhunter
        [57265] = {t = 2052}, -- Glyph of Health Funnel
        [57266] = {t = 2052}, -- Glyph of Healthstone
        [57267] = {d = {61177, 61756}}, -- Glyph of Howl of Terror
        [57268] = {d = {61177, 61756}}, -- Glyph of Immolate
        [57269] = {t = 2052}, -- Glyph of Imp
        [57270] = {t = 2052}, -- Glyph of Searing Pain
        [57271] = {t = 2052}, -- Glyph of Shadow Bolt
        [57272] = {t = 2052}, -- Glyph of Shadowburn
        [57273] = {d = {61177, 61756}}, -- Glyph of Siphon Life
        [57274] = {t = 2052}, -- Glyph of Soulstone
        [57275] = {t = 2068}, -- Glyph of Succubus
        [57276] = {d = {61177, 61756}}, -- Glyph of Unstable Affliction
        [57277] = {t = 2052}, -- Glyph of Voidwalker
        [57421] = {q = {{13087, 26905, 495, "A"}, {13088, 26989, 3537, "A"}, {13089, 26953, 495, "H"}, {13090, 26972, 3537, "H"}, {13087, 26905, 495, "A"}, {13088, 26989, 3537, "A"}, {13089, 26953, 495, "H"}, {13090, 26972, 3537, "H"}}}, -- Northern Stew
        [57425] = {t = 2060}, -- Transmute: Skyflare Diamond
        [57427] = {t = 2060}, -- Transmute: Earthsiege Diamond
        [57683] = {t = 2057}, -- Fur Lining - Attack Power
        [57690] = {t = 2057}, -- Fur Lining - Stamina
        [57691] = {t = 2057}, -- Fur Lining - Spell Power
        [57703] = {t = 2052}, -- Hunter's Ink
        [57704] = {t = 2052}, -- Lion's Ink
        [57706] = {t = 2052}, -- Dawnstar Ink
        [57707] = {t = 2052}, -- Jadefire Ink
        [57708] = {t = 2052}, -- Royal Ink
        [57709] = {t = 2052}, -- Celestial Ink
        [57710] = {t = 2052}, -- Fiery Ink
        [57711] = {t = 2052}, -- Shimmering Ink
        [57712] = {t = 2052}, -- Ink of the Sky
        [57713] = {t = 2052}, -- Ethereal Ink
        [57714] = {t = 2068}, -- Darkflame Ink
        [57715] = {t = 2056}, -- Ink of the Sea
        [57716] = {t = 2056}, -- Snowfall Ink
        [57719] = {d = {61177, 61756}}, -- Glyph of Fire Blast
        [58065] = {t = 2054}, -- Dalaran Clam Chowder
        [58141] = {t = 2062}, -- Crystal Citrine Necklace
        [58142] = {t = 2062}, -- Crystal Chalcedony Amulet
        [58143] = {t = 2062}, -- Earthshadow Ring
        [58144] = {t = 2062}, -- Jade Ring of Slaying
        [58145] = {t = 2062}, -- Stoneguard Band
        [58146] = {t = 2062}, -- Shadowmight Ring
        [58286] = {d = {61288}}, -- Glyph of Aquatic Form
        [58287] = {d = {61288}}, -- Glyph of Challenging Roar
        [58288] = {d = {61288}}, -- Glyph of Unburdened Rebirth
        [58289] = {d = {61288}}, -- Glyph of Thorns
        [58296] = {d = {61288}}, -- Glyph of the Wild
        [58297] = {d = {61288}}, -- Glyph of the Pack
        [58298] = {d = {61288}}, -- Glyph of Scare Beast
        [58299] = {d = {61288}}, -- Glyph of Revive Pet
        [58300] = {d = {61288}}, -- Glyph of Possessed Strength
        [58301] = {d = {61288}}, -- Glyph of Mend Pet
        [58302] = {d = {61288}}, -- Glyph of Feign Death
        [58303] = {d = {61288}}, -- Glyph of Arcane Intellect
        [58305] = {d = {61288}}, -- Glyph of Fire Ward
        [58306] = {d = {61288}}, -- Glyph of Frost Armor
        [58307] = {d = {61288}}, -- Glyph of Frost Ward
        [58308] = {d = {61288}}, -- Glyph of Slow Fall
        [58310] = {d = {61288}}, -- Glyph of the Penguin
        [58311] = {d = {61288}}, -- Glyph of Blessing of Kings
        [58312] = {d = {61288}}, -- Glyph of Blessing of Wisdom
        [58313] = {t = 2069, d = {61288}}, -- Glyph of Lay on Hands
        [58314] = {d = {61288}}, -- Glyph of Blessing of Might
        [58315] = {d = {61288}}, -- Glyph of Sense Undead
        [58316] = {d = {61288}}, -- Glyph of the Wise
        [58317] = {d = {61288}}, -- Glyph of Fading
        [58318] = {d = {61288}}, -- Glyph of Fortitude
        [58319] = {d = {61288}}, -- Glyph of Levitate
        [58320] = {d = {61288}}, -- Glyph of Shackle Undead
        [58321] = {d = {61288}}, -- Glyph of Shadow Protection
        [58322] = {d = {61177, 61288, 61756}}, -- Glyph of Shadowfiend
        [58323] = {d = {61288}}, -- Glyph of Blurred Speed
        [58324] = {d = {61288}}, -- Glyph of Distract
        [58325] = {d = {61288}}, -- Glyph of Pick Lock
        [58326] = {d = {61288}}, -- Glyph of Pick Pocket
        [58327] = {d = {61288}}, -- Glyph of Safe Fall
        [58328] = {d = {61288}}, -- Glyph of Vanish
        [58329] = {d = {61288}}, -- Glyph of Astral Recall
        [58330] = {d = {61288}}, -- Glyph of Renewed Life
        [58331] = {d = {61288}}, -- Glyph of Water Breathing
        [58332] = {d = {61288}}, -- Glyph of Water Shield
        [58333] = {d = {61288}}, -- Glyph of Water Walking
        [58336] = {d = {61288}}, -- Glyph of Unending Breath
        [58337] = {d = {61288}}, -- Glyph of Drain Soul
        [58338] = {d = {61288}}, -- Glyph of Curse of Exhaustion
        [58339] = {d = {61288}}, -- Glyph of Subjugate Demon
        [58340] = {d = {61288}}, -- Glyph of Kilrogg
        [58341] = {d = {61177, 61288, 61756}}, -- Glyph of Souls
        [58342] = {d = {61288}}, -- Glyph of Battle
        [58343] = {d = {61288}}, -- Glyph of Bloodrage
        [58344] = {d = {61288}}, -- Glyph of Charge
        [58345] = {d = {61288}}, -- Glyph of Mocking Blow
        [58346] = {d = {61288}}, -- Glyph of Thunder Clap
        [58347] = {d = {61288}}, -- Glyph of Enduring Victory
        [58472] = {t = 2052}, -- Scroll of Agility
        [58473] = {t = 2052}, -- Scroll of Agility II
        [58476] = {t = 2052}, -- Scroll of Agility III
        [58478] = {t = 2052}, -- Scroll of Agility IV
        [58480] = {t = 2052}, -- Scroll of Agility V
        [58481] = {t = 2052}, -- Scroll of Agility VI
        [58482] = {t = 2056}, -- Scroll of Agility VII
        [58483] = {t = 2056}, -- Scroll of Agility VIII
        [58484] = {t = 2052}, -- Scroll of Strength
        [58485] = {t = 2052}, -- Scroll of Strength II
        [58486] = {t = 2052}, -- Scroll of Strength III
        [58487] = {t = 2052}, -- Scroll of Strength IV
        [58488] = {t = 2052}, -- Scroll of Strength V
        [58489] = {t = 2052}, -- Scroll of Strength VI
        [58490] = {t = 2056}, -- Scroll of Strength VII
        [58491] = {t = 2056}, -- Scroll of Strength VIII
        [58565] = {t = 2052}, -- Mystic Tome
        [58868] = {t = 2060}, -- Endless Mana Potion
        [58871] = {t = 2060}, -- Endless Healing Potion
        [59315] = {d = {61288}}, -- Glyph of Dash
        [59326] = {d = {61288}}, -- Glyph of Ghost Wolf
        [59338] = {t = 2068}, -- Glyph of Rune Tap
        [59339] = {t = 2068}, -- Glyph of Blood Strike
        [59340] = {t = 2068}, -- Glyph of Death Strike
        [59387] = {t = 2052}, -- Certificate of Ownership
        [59405] = {t = 2058}, -- Cobalt Skeleton Key
        [59406] = {t = 2058}, -- Titanium Skeleton Key
        [59436] = {t = 2058}, -- Brilliant Saronite Belt
        [59438] = {t = 2058}, -- Brilliant Saronite Bracers
        [59440] = {t = 2058}, -- Brilliant Saronite Pauldrons
        [59441] = {t = 2058}, -- Brilliant Saronite Helm
        [59442] = {t = 2058}, -- Saronite Spellblade
        [59475] = {t = 2052}, -- Tome of the Dawn
        [59478] = {t = 2052}, -- Book of Survival
        [59480] = {t = 2052}, -- Strange Tarot
        [59484] = {t = 2052}, -- Tome of Kings
        [59486] = {t = 2052}, -- Royal Guide of Escape Routes
        [59487] = {t = 2052}, -- Arcane Tarot
        [59488] = {t = 2052}, -- Weapon Vellum II
        [59489] = {t = 2052}, -- Fire Eater's Guide
        [59490] = {t = 2052}, -- Book of Stars
        [59491] = {t = 2052}, -- Shadowy Tarot
        [59493] = {t = 2052}, -- Stormbound Tome
        [59494] = {t = 2052}, -- Manual of Clouds
        [59495] = {t = 2068}, -- Hellfire Tome
        [59496] = {t = 2068}, -- Book of Clever Tricks
        [59497] = {t = 2056}, -- Iron-bound Tome
        [59498] = {t = 2056}, -- Faces of Doom
        [59499] = {t = 2052}, -- Armor Vellum II
        [59500] = {t = 2056}, -- Armor Vellum III
        [59501] = {t = 2056}, -- Weapon Vellum III
        [59502] = {t = 2052}, -- Darkmoon Card
        [59503] = {t = 2068}, -- Greater Darkmoon Card
        [59504] = {t = 2056}, -- Darkmoon Card of the North
        [59559] = {d = {61177, 61756}}, -- Glyph of Holy Wrath
        [59560] = {d = {61177, 61756}}, -- Glyph of Seal of Righteousness
        [59561] = {d = {61177, 61756}}, -- Glyph of Seal of Vengeance
        [59582] = {t = 2064}, -- Frostsavage Belt
        [59583] = {t = 2064}, -- Frostsavage Bracers
        [59584] = {t = 2064}, -- Frostsavage Shoulders
        [59585] = {t = 2064}, -- Frostsavage Boots
        [59586] = {t = 2064}, -- Frostsavage Gloves
        [59587] = {t = 2064}, -- Frostsavage Robe
        [59588] = {t = 2064}, -- Frostsavage Leggings
        [59589] = {t = 2064}, -- Frostsavage Cowl
        [59636] = {t = 2042}, -- Enchant Ring - Stamina
        [59759] = {t = 2062}, -- Monarch Crab
        [60336] = {t = 2052}, -- Scroll of Recall II
        [60337] = {t = 2056}, -- Scroll of Recall III
        [60350] = {t = 2055}, -- Transmute: Titanium
        [60354] = {d = {60893}}, -- Elixir of Accuracy
        [60355] = {d = {60893}}, -- Elixir of Deadly Strikes
        [60356] = {d = {60893}}, -- Elixir of Mighty Defense
        [60357] = {d = {60893}}, -- Elixir of Expertise
        [60365] = {d = {60893}}, -- Elixir of Armor Piercing
        [60366] = {d = {60893}}, -- Elixir of Lightning Speed
        [60367] = {t = 2060}, -- Elixir of Mighty Thoughts
        [60396] = {t = 2060}, -- Mercurial Alchemist Stone
        [60403] = {t = 2060}, -- Indestructible Alchemist Stone
        [60405] = {t = 2060}, -- Mighty Alchemist Stone
        [60583] = {t = 2057}, -- Jormungar Leg Reinforcements
        [60584] = {t = 2057}, -- Nerubian Leg Reinforcements
        [60599] = {t = 2057}, -- Frostscale Bracers
        [60600] = {t = 2057}, -- Frostscale Helm
        [60601] = {t = 2057}, -- Dark Frostscale Leggings
        [60604] = {t = 2057}, -- Dark Frostscale Breastplate
        [60605] = {t = 2057}, -- Dragonstompers
        [60606] = {t = 2042}, -- Enchant Boots - Assault
        [60607] = {t = 2057}, -- Iceborne Wristguards
        [60608] = {t = 2057}, -- Iceborne Helm
        [60609] = {t = 2042}, -- Enchant Cloak - Speed
        [60611] = {t = 2057}, -- Dark Iceborne Leggings
        [60613] = {t = 2057}, -- Dark Iceborne Chestguard
        [60616] = {t = 2042}, -- Enchant Bracers - Striking
        [60619] = {t = 2042}, -- Runed Titanium Rod
        [60620] = {t = 2057}, -- Bugsquashers
        [60621] = {t = 2042}, -- Enchant Weapon - Greater Potency
        [60622] = {t = 2057}, -- Nerubian Bracers
        [60623] = {t = 2042}, -- Enchant Boots - Icewalker
        [60624] = {t = 2057}, -- Nerubian Helm
        [60627] = {t = 2057}, -- Dark Nerubian Leggings
        [60629] = {t = 2057}, -- Dark Nerubian Chestpiece
        [60630] = {t = 2057}, -- Scaled Icewalkers
        [60631] = {t = 2057}, -- Cloak of Harsh Winds
        [60637] = {t = 2057}, -- Ice Striker's Cloak
        [60640] = {t = 2057}, -- Durable Nerubhide Cape
        [60643] = {t = 2057}, -- Pack of Endless Pockets
        [60649] = {t = 2057}, -- Razorstrike Breastplate
        [60651] = {t = 2057}, -- Virulent Spaulders
        [60652] = {t = 2057}, -- Eaglebane Bracers
        [60653] = {t = 2042}, -- Enchant Shield - Greater Intellect
        [60655] = {t = 2057}, -- Nightshock Hood
        [60658] = {t = 2057}, -- Nightshock Girdle
        [60660] = {t = 2057}, -- Leggings of Visceral Strikes
        [60663] = {t = 2042}, -- Enchant Cloak - Major Agility
        [60665] = {t = 2057}, -- Seafoam Gauntlets
        [60666] = {t = 2057}, -- Jormscale Footpads
        [60668] = {t = 2042}, -- Enchant Gloves - Crusher
        [60669] = {t = 2057}, -- Wildscale Breastplate
        [60671] = {t = 2057}, -- Purehorn Spaulders
        [60874] = {t = 2059}, -- Nesingwary 4000
        [60893] = {t = 2060}, -- Northrend Alchemy Research
        [60969] = {t = 2037}, -- Flying Carpet
        [60971] = {t = 2064}, -- Magnificent Flying Carpet
        [60990] = {t = 2064}, -- Glacial Waistband
        [60993] = {t = 2064}, -- Glacial Robe
        [60994] = {t = 2064}, -- Glacial Slippers
        [61008] = {t = 2058}, -- Icebane Chestguard
        [61009] = {t = 2058}, -- Icebane Girdle
        [61010] = {t = 2058}, -- Icebane Treads
        [61117] = {t = 2056}, -- Master's Inscription of the Axe
        [61118] = {t = 2056}, -- Master's Inscription of the Crag
        [61119] = {t = 2056}, -- Master's Inscription of the Pinnacle
        [61120] = {t = 2056}, -- Master's Inscription of the Storm
        [61177] = {t = 2056}, -- Northrend Inscription Research
        [61288] = {t = 2052}, -- Minor Inscription Research
        [61471] = {t = 2059}, -- Diamond-cut Refractor Scope
        [61481] = {t = 2059}, -- Mechanized Snow Goggles
        [61482] = {t = 2059}, -- Mechanized Snow Goggles
        [61483] = {t = 2059}, -- Mechanized Snow Goggles
        [61677] = {d = {61177, 61756}}, -- Glyph of Frostfire
        [62162] = {t = 2056}, -- Glyph of Focus
        [62213] = {t = 2060}, -- Lesser Flask of Resistance
        [62242] = {t = 2062}, -- Icy Prism
        [62257] = {u = true}, -- Enchant Weapon - Titanguard
        [62271] = {t = 2059}, -- Unbreakable Healing Amplifiers
        [62409] = {t = 2060}, -- Ethereal Oil
        [62410] = {d = {60893}}, -- Elixir of Water Walking
        [62448] = {t = 2057}, -- Earthen Leg Armor
        [62941] = {t = 2044}, -- Prismatic Black Diamond
        [62959] = {t = 2042}, -- Enchant Staff - Spellpower
        [63182] = {t = 2058}, -- Titansteel Spellblade
        [63732] = {t = 2070}, -- Elixir of Minor Accuracy
        [63742] = {t = 2071}, -- Spidersilk Drape
        [63743] = {t = 2072}, -- Amulet of Truesight
        [63746] = {t = 2018}, -- Enchant Boots - Lesser Accuracy
        [63750] = {t = 2073}, -- High-powered Flashlight
        [63765] = {t = 2059}, -- Springy Arachnoweave
        [63770] = {t = 2059}, -- Reticulated Armor Webbing
        [64053] = {t = 2056}, -- Twilight Tome
        [64054] = {q = {{6610, 8125, 440}, {13825}, {6610, 8125, 440}, {13825}}}, -- Clamlette Magnifique
        [64246] = {d = {64323}}, -- Glyph of Raptor Strike
        [64247] = {d = {64323}}, -- Glyph of Stoneclaw Totem
        [64248] = {d = {64323}}, -- Glyph of Life Tap
        [64249] = {d = {64323}}, -- Glyph of Scatter Shot
        [64250] = {d = {64323}}, -- Glyph of Soul Link
        [64251] = {d = {64323}}, -- Glyph of Salvation
        [64252] = {d = {64323}}, -- Glyph of Shield Wall
        [64253] = {d = {64323}}, -- Glyph of Explosive Trap
        [64254] = {d = {64323}}, -- Glyph of Holy Shock
        [64255] = {d = {64323}}, -- Glyph of Vigilance
        [64256] = {d = {64323}}, -- Glyph of Barkskin
        [64257] = {d = {64323}}, -- Glyph of Ice Barrier
        [64258] = {t = 2052}, -- Glyph of Monsoon
        [64259] = {t = 2052}, -- Glyph of Pain Suppression
        [64260] = {t = 2052}, -- Glyph of Mutilate
        [64261] = {t = 2052}, -- Glyph of Earth Shield
        [64262] = {t = 2052}, -- Glyph of Totem of Wrath
        [64266] = {t = 2052}, -- Glyph of Dark Death
        [64267] = {t = 2052}, -- Glyph of Disease
        [64268] = {d = {64323}}, -- Glyph of Berserk
        [64270] = {d = {64323}}, -- Glyph of Wild Growth
        [64271] = {d = {64323}}, -- Glyph of Chimera Shot
        [64273] = {d = {64323}}, -- Glyph of Explosive Shot
        [64274] = {d = {64323}}, -- Glyph of Deep Freeze
        [64275] = {d = {64323}}, -- Glyph of Living Bomb
        [64276] = {d = {64323}}, -- Glyph of Arcane Barrage
        [64277] = {d = {64323}}, -- Glyph of Beacon of Light
        [64278] = {d = {64323}}, -- Glyph of Hammer of the Righteous
        [64279] = {d = {64323}}, -- Glyph of Divine Storm
        [64280] = {d = {64323}}, -- Glyph of Dispersion
        [64281] = {d = {64323}}, -- Glyph of Guardian Spirit
        [64282] = {d = {64323}}, -- Glyph of Penance
        [64283] = {d = {64323}}, -- Glyph of Hymn of Hope
        [64284] = {d = {64323}}, -- Glyph of Hunger for Blood
        [64285] = {d = {64323}}, -- Glyph of Killing Spree
        [64286] = {d = {64323}}, -- Glyph of Shadow Dance
        [64287] = {d = {64323}}, -- Glyph of Thunder
        [64288] = {d = {64323}}, -- Glyph of Feral Spirit
        [64289] = {d = {64323}}, -- Glyph of Riptide
        [64291] = {d = {64323}}, -- Glyph of Haunt
        [64294] = {d = {64323}}, -- Glyph of Chaos Bolt
        [64295] = {d = {64323}}, -- Glyph of Bladestorm
        [64296] = {d = {64323}}, -- Glyph of Shockwave
        [64297] = {d = {64323}}, -- Glyph of Dancing Rune Weapon
        [64298] = {d = {64323}}, -- Glyph of Hungering Cold
        [64299] = {d = {64323}}, -- Glyph of Unholy Blight
        [64300] = {d = {64323}}, -- Glyph of Howling Blast
        [64302] = {d = {64323}}, -- Glyph of Spell Reflection
        [64303] = {d = {64323}}, -- Glyph of Cloak of Shadows
        [64304] = {d = {64323}}, -- Glyph of Kill Shot
        [64305] = {d = {64323}}, -- Glyph of Divine Plea
        [64307] = {d = {64323}}, -- Glyph of Savage Roar
        [64308] = {d = {64323}}, -- Glyph of Shield of Righteousness
        [64309] = {d = {64323}}, -- Glyph of Mind Sear
        [64310] = {d = {64323}}, -- Glyph of Tricks of the Trade
        [64311] = {d = {64323}}, -- Glyph of Shadowflame
        [64312] = {d = {64323}}, -- Glyph of Enraged Regeneration
        [64313] = {d = {64323}}, -- Glyph of Nourish
        [64314] = {d = {64323}}, -- Glyph of Mirror Image
        [64315] = {d = {64323}}, -- Glyph of Fan of Knives
        [64316] = {d = {64323}}, -- Glyph of Hex
        [64317] = {d = {64323}}, -- Glyph of Demonic Circle
        [64318] = {d = {64323}}, -- Glyph of Metamorphosis
        [64358] = {t = 2054}, -- Black Jelly
        [64661] = {t = 2057}, -- Borean Leather
        [64725] = {t = 2062}, -- Emerald Choker
        [64726] = {t = 2062}, -- Sky Sapphire Amulet
        [64727] = {t = 2062}, -- Runed Mana Band
        [64728] = {t = 2062}, -- Scarlet Signet
        [64729] = {t = 2064}, -- Frostguard Drape
        [64730] = {t = 2064}, -- Cloak of Crimson Snow
        [65245] = {d = {64323}}, -- Glyph of Survival Instincts
        [66658] = {t = 2060}, -- Transmute: Ametrine
        [66659] = {q = {{14151, 28703, 2817}, {14151, 28703, 2817}}}, -- Transmute: Cardinal Ruby
        [66660] = {t = 2060}, -- Transmute: King's Amber
        [66662] = {t = 2060}, -- Transmute: Dreadstone
        [66663] = {t = 2060}, -- Transmute: Majestic Zircon
        [66664] = {t = 2060}, -- Transmute: Eye of Zul
        [67025] = {t = 2060}, -- Flask of the North
        [67326] = {t = 2059}, -- Goblin Beam Welder
        [67600] = {t = 2052}, -- Glyph of Claw
        [67790] = {u = true}, -- Dimensional Folder: K3
        [67839] = {t = 2059}, -- Mind Amplification Dish
        [67920] = {t = 2059}, -- Wormhole Generator: Northrend
        [68166] = {d = {61288}}, -- Glyph of Command
        [69385] = {t = 2056}, -- Runescroll of Fortitude
        [69386] = {t = 2057}, -- Drums of Forgotten Kings
        [69388] = {t = 2057}, -- Drums of the Wild
        [69412] = {t = 2042}, -- Abyssal Shatter
        [70524] = {t = 2018}, -- Enchanted Thorium
    },
};

_G.professionMaster:CreateModel("skill-sources-wrath", wrathSkillSources);
