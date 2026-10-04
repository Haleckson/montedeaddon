--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Skill sources for WoW Forever: trainer groups, trainer npcs (zone, side) and per skill sources (Classic Era knowledge)
-- Format: skills[spellId] = {t = groupId, q = {{questId, giverId, zoneId, side, flags, giverType}}, d = {researchSpellId}, a = true (learned with the profession), u = true (not available)}
-- flags: 1 daily, 2 weekly, 4 repeatable; giverType: nil npc, "o" object, "i" item
local foreverSkillSources = {
    groups = {
        [1] = {1355, 1382, 1430, 1699, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306},
        [2] = {223, 1385, 1466, 1632, 3007, 3008, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 5811, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11081, 11083, 11084, 11096, 11097, 11098},
        [7] = {1215, 1246, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4609, 4611, 4900, 5177, 5499, 5500, 7948, 11041, 11042, 11044, 11046, 11047},
        [11] = {1103, 1300, 1346, 1703, 2264, 2399, 2627, 2855, 3004, 3363, 3484, 3523, 3530, 3704, 4159, 4193, 4576, 4578, 5153, 5567, 9584, 11048, 11049, 11050, 11051, 11052},
        [13] = {1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128},
        [14] = {514, 957, 1241, 1383, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 4605, 5164, 5511, 6299, 7230, 7231, 7232, 10266, 10276, 10277, 10278, 11146, 11177, 11178},
        [21] = {3347},
        [22] = {2836, 3355, 4258},
        [23] = {3007, 4212},
        [25] = {1103, 1300, 1703, 2264, 2855, 3484, 3523, 3530, 3531, 4193, 11048, 11050, 11051},
        [26] = {1676, 1702, 2857, 3290, 3412, 3494, 4586, 5174, 5518, 7406, 7944, 8126, 8736, 8738, 10993, 11017, 11025, 11026, 11028, 11029, 11031, 11037},
        [29] = {1676, 3412, 5174, 5518, 8736, 11017, 11029, 11031},
        [30] = {5174, 8736, 11017},
        [31] = {2818},
        [32] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11065, 11066, 11067, 11068, 11070, 11071, 11072, 11073, 11074},
        [33] = {3011, 3345, 4213, 4616, 5157, 7949},
        [35] = {8126, 8738},
        [36] = {5164, 7230, 11177},
        [37] = {2836},
        [38] = {7231, 7232, 11146, 11178},
        [39] = {11097, 11098},
        [40] = {7870, 11097, 11098},
        [41] = {7866, 7867},
        [42] = {7870, 7871},
        [43] = {7868, 7869},
        [44] = {7870, 7871, 11097, 11098},
        [45] = {12920, 12939},
        [46] = {1386, 7948},
        [47] = {4578, 9584},
        [48] = {2399, 11052, 11557},
        [49] = {2399, 11052},
        [50] = {8736},
        [51] = {7406, 7944},
        [52] = {7406, 7944, 8738},
        [53] = {8696},
        [56] = {11073},
        [57] = {14338},
        [58] = {14401},
        [59] = {14742},
        [60] = {14743},
        [61] = {16365},
        [5001] = {223, 1466, 1632, 3008, 3069, 3365, 3549, 3605, 4588, 5127, 5564, 5784, 5811, 11081, 11083, 11084, 11096, 251993, 252376},
        [5002] = {2855, 3004, 3363, 3484, 3523, 3704, 11048, 11049, 11051, 251991, 252380},
        [5003] = {1292, 6287, 6289, 6290, 6291, 6292, 6295, 6306, 6387, 7087, 7088, 7089, 257003, 257024},
        [5004] = {812, 1218, 1473, 2114, 3013, 3185, 3404, 3604, 4614, 5137, 5566, 254345, 257021},
        [5005] = {1355, 1430, 1699, 3026, 3067, 3087, 3191, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 251905, 252084, 257006, 265944},
        [5006] = {1651, 1680, 1683, 1700, 2367, 2834, 3028, 3179, 3332, 3607, 4156, 4573, 5161, 5493, 5690, 5938, 5941, 251992, 257008},
        [5007] = {2326, 2327, 2329, 2798, 3373, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 251977, 257007, 257018},
        [5008] = {1681, 1701, 3001, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 252388, 255891, 257022},
        [5009] = {514, 957, 1241, 1383, 2998, 3174, 3478, 3557, 4596, 4605, 5511, 6299, 10266, 10276, 10277, 10278, 251913, 252479, 259250, 276067},
        [5010] = {1215, 1246, 1470, 2132, 2391, 3009, 3184, 3347, 3603, 4160, 4609, 5177, 5499, 5500, 11041, 11042, 11044, 11046, 11047, 246795, 253004, 257005, 257019, 275322},
        [5011] = {1317, 3345, 3606, 4213, 4616, 5157, 5695, 11065, 11066, 11067, 11068, 11070, 11071, 251978, 257004, 257020, 266881},
        [5012] = {1702, 2857, 3412, 3494, 4586, 5518, 11025, 11026, 11028, 11029, 11031, 11037, 251684},
        [5013] = {1937},
        [5014] = {3009, 3347, 4609, 5177, 5499, 11042, 246795, 275322},
        [5015] = {246795, 275322},
        [5016] = {1215, 1246, 1470, 2132, 3009, 3184, 3347, 3603, 4609, 5177, 5499, 5500, 11041, 11042, 11044, 11046, 11047, 246795, 253004, 257005, 257019, 275322},
        [5017] = {1681, 1701, 3001, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 252388, 255891, 257022},
        [5018] = {2326, 2327, 2329, 2798, 3181, 3373, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 251977, 257007, 257018},
        [5019] = {1103, 1300, 1703, 4193, 5153, 5567, 11050, 251972, 251991, 252380},
        [5020] = {223, 1466, 1632, 3008, 3069, 3549, 3605, 5784, 5811, 7866, 7867, 7868, 7869, 11083, 11096, 251993, 252376},
        [5021] = {1385, 3365, 3703, 3967, 4588, 5127, 5564, 7866, 7867, 7868, 7869, 8153, 11081, 11084, 252376},
        [5022] = {223, 1466, 1632, 3008, 3069, 3549, 3605, 5784, 5811, 11083, 11096, 251993, 252376},
        [5023] = {1385, 3365, 3703, 3967, 4588, 5127, 5564, 8153, 11081, 11084, 252376},
        [5024] = {1215, 1246, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4609, 4611, 4900, 5177, 5499, 5500, 7948, 11041, 11042, 11044, 11046, 11047, 246795, 253004, 257005, 257019, 275322},
        [5025] = {1215, 1246, 1386, 1470, 2132, 2391, 2837, 3184, 3347, 3603, 3964, 4160, 4609, 4611, 4900, 5177, 5499, 5500, 7948, 11041, 11042, 11044, 11046, 11047, 246795, 253004, 257005, 257019, 275322},
        [5026] = {1103, 1300, 1346, 1703, 2399, 2627, 2855, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 5567, 11048, 11049, 11050, 11051, 11052, 11557, 251972, 251991, 252380},
        [5027] = {1346, 2399, 2627, 3004, 3363, 3704, 4159, 4576, 5153, 5567, 11049, 11052, 11557, 251972, 251991, 252380},
        [5028] = {1355, 1382, 1430, 1699, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 251905, 252084, 257006, 265944},
        [5029] = {1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 252388, 255891, 257022},
        [5030] = {514, 957, 1241, 1383, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4605, 5511, 6299, 10266, 10276, 10277, 10278, 251913, 252479, 259250, 276067},
        [5031] = {514, 957, 1241, 3174, 3557, 4605, 6299, 10266, 10277, 10278, 251913, 252479, 259250, 276067},
        [5032] = {1383, 2836, 2998, 3136, 3355, 3478, 4258, 4596, 5511, 10276, 252479, 276067},
        [5033] = {1215, 1246, 1386, 1470, 2132, 2391, 2837, 3184, 3347, 3603, 3964, 4160, 4609, 4611, 4900, 5177, 5499, 5500, 7948, 11041, 11042, 11044, 11046, 11047, 246795, 275322},
        [5034] = {1383, 2998, 3136, 3478, 4596, 5511, 10276, 252479, 276067},
        [5035] = {1386, 4160, 4611, 7948, 246795, 275322},
        [5036] = {1385, 3365, 3703, 3967, 4588, 5127, 5564, 8153, 11081, 11084, 251993, 252376},
        [5037] = {3007, 4212, 252376},
        [5038] = {1346, 2399, 4576, 11052, 11557, 251972},
        [5039] = {1702, 2857, 3290, 3412, 3494, 4586, 5174, 5518, 8736, 10993, 11017, 11025, 11026, 11028, 11029, 11031, 11037, 251684},
        [5040] = {1676, 1702, 2857, 3290, 3412, 3494, 4586, 5174, 5518, 8736, 10993, 11017, 11025, 11026, 11028, 11029, 11031, 11037, 251684},
        [5041] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11065, 11066, 11067, 11068, 11070, 11071, 11072, 11073, 11074, 251978, 257004, 257020, 266881},
        [5042] = {1317, 3011, 3345, 4213, 4616, 5157, 7949, 11072, 11073, 11074, 251978},
        [5043] = {1385, 3365, 3703, 3967, 4588, 5127, 5564, 7866, 7867, 7868, 7869, 8153, 11081, 11084, 251993, 252376},
        [5044] = {1386, 7948, 246795, 275322},
        [5045] = {1317, 11072, 11074, 251978},
        [5046] = {11072, 11073, 11074, 251978},
        [5047] = {251913, 252479, 259250, 276067},
        [5048] = {252479, 276067},
        [5049] = {252376},
        [5050] = {251993, 252376},
        [5051] = {251972, 251991, 252380},
    },
    npcs = {
        [223] = {1497, "H"}, -- Dan Golthas
        [514] = {12, "A"}, -- Smith Argus
        [812] = {44, "A"}, -- Alma Jainrose
        [957] = {1519, "A"}, -- Dane Lindgren
        [1103] = {12, "A"}, -- Eldrin
        [1215] = {12, "A"}, -- Alchemist Mallory
        [1218] = {12, "A"}, -- Herbalist Pomeroy
        [1241] = {1, "A"}, -- Tognus Flintfire
        [1246] = {1537, "A"}, -- Vosur Brakthel
        [1292] = {1519, "A"}, -- Maris Granger
        [1300] = {1519, "A"}, -- Lawrence Schneider
        [1317] = {1519, "A"}, -- Lucan Cordell
        [1346] = {1519, "A"}, -- Georgio Bolero
        [1355] = {1, "A"}, -- Cook Ghilm
        [1382] = {33, "H"}, -- Mudduk
        [1383] = {1637, "H"}, -- Snarl
        [1385] = {33, "H"}, -- Brawn
        [1386] = {8, "H"}, -- Rogvar
        [1430] = {12, "A"}, -- Tomas
        [1466] = {1537, "A"}, -- Gretta Finespindle
        [1470] = {38, "A"}, -- Ghak Healtouch
        [1473] = {38, "A"}, -- Kali Healtouch
        [1632] = {12, "A"}, -- Adele Fielder
        [1651] = {12, "A"}, -- Lee Brown
        [1676] = {10, "A"}, -- Finbus Geargrind
        [1680] = {44, "A"}, -- Matthew Hooper
        [1681] = {38, "A"}, -- Brock Stoneseeker
        [1683] = {38, "A"}, -- Warg Deepwater
        [1699] = {1, "A"}, -- Gremlock Pilsnor
        [1700] = {1, "A"}, -- Paxton Ganter
        [1701] = {1, "A"}, -- Dank Drizzlecut
        [1702] = {1, "A"}, -- Bronk Guzzlegear
        [1703] = {1537, "A"}, -- Uthrar Threx
        [1937] = {130, "H"}, -- Apothecary Renferrel
        [2114] = {85, "H"}, -- Faruza
        [2132] = {85, "H"}, -- Carolai Anise
        [2264] = {267, "A"}, -- Hillsbrad Tailor
        [2326] = {1, "A"}, -- Thamner Pol
        [2327] = {1519, "A"}, -- Shaina Fuller
        [2329] = {12, "A"}, -- Michelle Belle
        [2367] = {267, "A"}, -- Donald Rabonne
        [2391] = {267, "H"}, -- Serge Hinott
        [2399] = {267, "H"}, -- Daryl Stack
        [2627] = {33}, -- Grarnik Goodstitch
        [2798] = {1638, "H"}, -- Pand Stonebinder
        [2818] = {45, "H"}, -- Slagg
        [2834] = {33}, -- Myizz Luckycatch
        [2836] = {33}, -- Brikk Keencraft
        [2837] = {33}, -- Jaxin Chong
        [2855] = {1637, "H"}, -- Snang
        [2857] = {1637, "H"}, -- Thund
        [2998] = {1638, "H"}, -- Karn Stonehoof
        [3001] = {1638, "H"}, -- Brek Stonehoof
        [3004] = {1638, "H"}, -- Tepa
        [3007] = {1638, "H"}, -- Una
        [3008] = {1638, "H"}, -- Mak
        [3009] = {1638, "H"}, -- Bena Winterhoof
        [3011] = {1638, "H"}, -- Teg Dawnstrider
        [3013] = {1638, "H"}, -- Komin Winterhoof
        [3026] = {1638, "H"}, -- Aska Mistrunner
        [3028] = {1638, "H"}, -- Kah Mistrunner
        [3067] = {215, "H"}, -- Pyall Silentstride
        [3069] = {215, "H"}, -- Chaw Stronghide
        [3087] = {44, "A"}, -- Crystal Boughman
        [3136] = {10, "A"}, -- Clarise Gnarltree
        [3137] = {10, "A"}, -- Matt Johnson
        [3174] = {14, "H"}, -- Dwukk
        [3175] = {14, "H"}, -- Krunn
        [3179] = {11, "A"}, -- Harold Riggs
        [3181] = {11, "A"}, -- Fremal Doohickey
        [3184] = {14, "H"}, -- Miao'zan
        [3185] = {14, "H"}, -- Mishiki
        [3191] = {14, "H"}, -- Cook Torka
        [3290] = {38, "A"}, -- Deek Fizzlebizz
        [3332] = {1637, "H"}, -- Lumak
        [3345] = {1637, "H"}, -- Godan
        [3347] = {1637, "H"}, -- Yelmak
        [3355] = {1637, "H"}, -- Saru Steelfury
        [3357] = {1637, "H"}, -- Makaru
        [3363] = {1637, "H"}, -- Magar
        [3365] = {1637, "H"}, -- Karolek
        [3373] = {1637, "H"}, -- Arnok
        [3399] = {1637, "H"}, -- Zamja
        [3404] = {1637, "H"}, -- Jandi
        [3412] = {1637, "H"}, -- Nogg
        [3478] = {17, "H"}, -- Traugh
        [3484] = {17, "H"}, -- Kil'hala
        [3494] = {17}, -- Tinkerwiz
        [3523] = {85, "H"}, -- Bowen Brisboise
        [3530] = {130, "A"}, -- Pyrewood Tailor
        [3531] = {130}, -- Moonrage Tailor
        [3549] = {85, "H"}, -- Shelene Rhobart
        [3555] = {130, "H"}, -- Johan Focht
        [3557] = {130, "H"}, -- Guillaume Sorouy
        [3603] = {141, "A"}, -- Cyndra Kindwhisper
        [3604] = {141, "A"}, -- Malorne Bladeleaf
        [3605] = {141, "A"}, -- Nadyia Maneweaver
        [3606] = {141, "A"}, -- Alanna Raveneye
        [3607] = {141, "A"}, -- Androl Oakhand
        [3703] = {17, "H"}, -- Krulmoo Fullmoon
        [3704] = {17, "H"}, -- Mahani
        [3964] = {331, "A"}, -- Kylanna
        [3967] = {331, "A"}, -- Aayndia Floralwind
        [4156] = {1657, "A"}, -- Astaia
        [4159] = {1657, "A"}, -- Me'lynn
        [4160] = {1657, "A"}, -- Ainethil
        [4193] = {148, "A"}, -- Grondal Moonbreeze
        [4210] = {1657, "A"}, -- Alegorn
        [4211] = {1657, "A"}, -- Dannelor
        [4212] = {1657, "A"}, -- Telonis
        [4213] = {1657, "A"}, -- Taladan
        [4254] = {1537, "A"}, -- Geofram Bouldertoe
        [4258] = {1537, "A"}, -- Bengus Deepforge
        [4552] = {1497, "H"}, -- Eunice Burch
        [4573] = {1497, "H"}, -- Armand Cromwell
        [4576] = {1497, "H"}, -- Josef Gregorian
        [4578] = {1497, "H"}, -- Josephine Lister
        [4586] = {1497, "H"}, -- Graham Van Talen
        [4588] = {1497, "H"}, -- Arthur Moore
        [4591] = {1497, "H"}, -- Mary Edras
        [4596] = {1497, "H"}, -- James Van Brunt
        [4598] = {1497, "H"}, -- Brom Killian
        [4605] = {1497, "H"}, -- Basil Frye
        [4609] = {1497, "H"}, -- Doctor Marsh
        [4611] = {1497, "H"}, -- Doctor Herbert Halsey
        [4614] = {1497, "H"}, -- Martha Alliestar
        [4616] = {1497, "H"}, -- Lavinia Crowe
        [4900] = {15, "A"}, -- Alchemist Narett
        [5127] = {1537, "A"}, -- Fimble Finespindle
        [5137] = {1537, "A"}, -- Reyna Stonebranch
        [5150] = {1537, "A"}, -- Nissa Firestone
        [5153] = {1537, "A"}, -- Jormund Stonebrow
        [5157] = {1537, "A"}, -- Gimble Thistlefuzz
        [5159] = {1537, "A"}, -- Daryl Riknussun
        [5161] = {1537, "A"}, -- Grimnur Stonebrand
        [5164] = {1537, "A"}, -- Grumnus Steelshaper
        [5174] = {1537, "A"}, -- Springspindle Fizzlegear
        [5177] = {1537, "A"}, -- Tally Berryfizz
        [5392] = {1, "A"}, -- Yarr Hammerstone
        [5482] = {1519, "A"}, -- Stephen Ryback
        [5493] = {1519, "A"}, -- Arnold Leland
        [5499] = {1519, "A"}, -- Lilyssia Nightbreeze
        [5500] = {1519, "A"}, -- Tel'Athir
        [5511] = {1519, "A"}, -- Therum Deepforge
        [5513] = {1519, "A"}, -- Gelman Stonehand
        [5518] = {1519, "A"}, -- Lilliam Sparkspindle
        [5564] = {1519, "A"}, -- Simon Tanner
        [5566] = {1519, "A"}, -- Tannysa
        [5567] = {1519, "A"}, -- Sellandus
        [5690] = {85, "H"}, -- Clyde Kellen
        [5695] = {28, "H"}, -- Vance Undergloom
        [5759] = {85, "H"}, -- Nurse Neela
        [5784] = {17}, -- Waldor
        [5811] = {1637, "H"}, -- Kamari
        [5938] = {215, "H"}, -- Uthan Stillwater
        [5939] = {215, "H"}, -- Vira Younghoof
        [5941] = {14, "H"}, -- Lau'Tiki
        [5943] = {14, "H"}, -- Rawrk
        [6094] = {141, "A"}, -- Byancie
        [6286] = {141, "A"}, -- Zarrin
        [6287] = {141, "A"}, -- Radnaal Maneweaver
        [6289] = {85, "H"}, -- Rand Rhobart
        [6290] = {215, "H"}, -- Yonn Deepcut
        [6291] = {1537, "A"}, -- Balthus Stoneflayer
        [6292] = {1657, "A"}, -- Eladriel
        [6295] = {44, "A"}, -- Wilma Ranthal
        [6297] = {148, "A"}, -- Kurdram Stonehammer
        [6299] = {148, "A"}, -- Delfrum Flintbeard
        [6306] = {12, "A"}, -- Helene Peltskinner
        [6387] = {17, "H"}, -- Dranh
        [7087] = {1497, "H"}, -- Killian Hagey
        [7088] = {1637, "H"}, -- Thuwd
        [7089] = {1638, "H"}, -- Mooranta
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
        [8696] = {722}, -- Henry Stern
        [8736] = {440}, -- Buzzek Bracketswing
        [8738] = {17}, -- Vazario Linkgrease
        [9584] = {1519, "A"}, -- Jalane Ayrole
        [10266] = {1637, "H"}, -- Ug'thok
        [10276] = {1537, "A"}, -- Rotgath Stonebeard
        [10277] = {1537, "A"}, -- Groum Stonebeard
        [10278] = {1638, "H"}, -- Thrag Stonehoof
        [10993] = {215}, -- Twizwick Sprocketgrind
        [11017] = {1637, "H"}, -- Roxxik
        [11025] = {14, "H"}, -- Mukdrak
        [11026] = {1519, "A"}, -- Sprite Jumpsprocket
        [11028] = {1537, "A"}, -- Jemma Quikswitch
        [11029] = {1537, "A"}, -- Trixie Quikswitch
        [11031] = {1497, "H"}, -- Franklin Lloyd
        [11037] = {148, "A"}, -- Jenna Lemkenilli
        [11041] = {1657, "A"}, -- Milla Fairancora
        [11042] = {1657, "A"}, -- Sylvanna Forestmoon
        [11044] = {1497, "H"}, -- Doctor Martin Felben
        [11046] = {1637, "H"}, -- Whuut
        [11047] = {1638, "H"}, -- Kray
        [11048] = {1497, "H"}, -- Victor Ward
        [11049] = {1497, "H"}, -- Rhiannon Davis
        [11050] = {1657, "A"}, -- Trianna
        [11051] = {1638, "H"}, -- Vhan
        [11052] = {15, "A"}, -- Timothy Worthington
        [11065] = {1537, "A"}, -- Thonys Pillarstone
        [11066] = {1637, "H"}, -- Jhag
        [11067] = {1497, "H"}, -- Malcomb Wynn
        [11068] = {1519, "A"}, -- Betty Quin
        [11070] = {1657, "A"}, -- Lalina Summermoon
        [11071] = {1638, "H"}, -- Mot Dawnstrider
        [11072] = {12, "A"}, -- Kitta Firewind
        [11073] = {1337}, -- Annora
        [11074] = {406, "H"}, -- Hgarth
        [11081] = {1657, "A"}, -- Faldron
        [11083] = {1657, "A"}, -- Darianna
        [11084] = {1638, "H"}, -- Tarn
        [11096] = {1519, "A"}, -- Randal Worth
        [11097] = {47, "A"}, -- Drakk Stonehand
        [11098] = {357, "H"}, -- Hahrana Ironhide
        [11146] = {1537, "A"}, -- Ironus Coldsteel
        [11177] = {1637, "H"}, -- Okothos Ironrager
        [11178] = {1637, "H"}, -- Borgosh Corebender
        [11557] = {493}, -- Meilosh
        [12920] = {45, "H"}, -- Doctor Gregory Victor
        [12939] = {15, "A"}, -- Doctor Gustaf VanHowzen
        [14338] = {2557}, -- Knot Thimblejack
        [14401] = {2677}, -- Master Elemental Shaper Krixix
        [14742] = {618}, -- Zap Farflinger
        [14743] = {440}, -- Jhordy Lapforge
        [16365] = {3456}, -- Master Craftsman Omarion
        [246795] = {36}, -- Linzy Blackbolt
        [251684] = {16593}, -- Strange Hermit
        [251905] = {16593}, -- Zerril Softbreeze
        [251913] = {16593}, -- Aedi Thriceforged
        [251972] = {36, "A"}, -- Charles Worth
        [251977] = {36, "A"}, -- Angelique Butler
        [251978] = {36, "A"}, -- Vanessa Sellers
        [251991] = {16593}, -- Taleen Shimmerthread
        [251992] = {16593}, -- Fenn Fairweather
        [251993] = {16593}, -- Indari Sunseam
        [252084] = {36}, -- Katherine Lee
        [252376] = {16593}, -- Emerii Tallgust
        [252380] = {16593, "A"}, -- Othesia Evengale
        [252388] = {16593}, -- Halavuul Cragwind
        [252479] = {16593}, -- Daeann Steelwind
        [253004] = {16593, "A"}, -- Iaadaria Bitterwind
        [254345] = {16593}, -- Syriel Nightrain
        [255891] = {16591}, -- Grungle
        [257003] = {16593}, -- Ishlee Breezewhisper
        [257004] = {16593}, -- Eaysaa Brightgust
        [257005] = {16593}, -- Valiena Swiftgale
        [257006] = {16593}, -- Nyalah Brightfire
        [257007] = {16593}, -- Melasa Fairmend
        [257008] = {16593}, -- Baelann Swiftcurrent
        [257018] = {16593}, -- Naleeia Tattermend
        [257019] = {16593}, -- Nyassa Swiftdraught
        [257020] = {16593}, -- Nasalanna Windsinger
        [257021] = {16593}, -- Halassa Fernbreeze
        [257022] = {16593}, -- Messana Crestwind
        [257024] = {16593}, -- Mendalass Tattermend
        [259250] = {16591}, -- Alphonse Dumas
        [265944] = {85, "H"}, -- William Pickman
        [266881] = {14, "H"}, -- Pa'zula
        [275322] = {36}, -- Patricia Egan
        [276067] = {85, "H"}, -- Angus Hammerhand
    },
    skills = {
        [2149] = {t = 2, a = true}, -- Handstitched Leather Boots
        [2152] = {t = 2, a = true}, -- Light Armor Kit
        [2153] = {t = 5020}, -- Handstitched Leather Pants
        [2159] = {t = 5021}, -- Fine Leather Cloak
        [2160] = {t = 5020}, -- Embossed Leather Vest
        [2161] = {t = 5020}, -- Embossed Leather Boots
        [2162] = {t = 5022}, -- Embossed Leather Cloak
        [2165] = {t = 5023}, -- Medium Armor Kit
        [2166] = {t = 5021}, -- Toughened Leather Armor
        [2167] = {t = 5021}, -- Dark Leather Boots
        [2168] = {t = 5023}, -- Dark Leather Cloak
        [2329] = {t = 5024, a = true}, -- Elixir of Lion's Strength
        [2331] = {t = 5025}, -- Minor Mana Potion
        [2332] = {t = 5025}, -- Minor Rejuvenation Potion
        [2334] = {t = 5025}, -- Elixir of Minor Fortitude
        [2385] = {t = 5026}, -- Brown Linen Vest
        [2386] = {t = 5026}, -- Linen Boots
        [2387] = {t = 11, a = true}, -- Linen Cloak
        [2392] = {t = 5026}, -- Red Linen Shirt
        [2393] = {t = 5026}, -- White Linen Shirt
        [2394] = {t = 5026}, -- Blue Linen Shirt
        [2395] = {t = 5026}, -- Barbaric Linen Vest
        [2396] = {t = 5026}, -- Green Linen Shirt
        [2397] = {t = 5026}, -- Reinforced Linen Cape
        [2399] = {t = 5027}, -- Green Woolen Vest
        [2401] = {t = 5027}, -- Woolen Boots
        [2402] = {t = 5026}, -- Woolen Cape
        [2406] = {t = 5027}, -- Gray Woolen Shirt
        [2538] = {t = 1, a = true}, -- Charred Wolf Meat
        [2539] = {t = 5028}, -- Spiced Wolf Meat
        [2540] = {t = 1, a = true}, -- Roasted Boar Meat
        [2541] = {t = 5028}, -- Coyote Steak
        [2544] = {t = 5028}, -- Crab Cake
        [2546] = {t = 5028}, -- Dry Pork Ribs
        [2657] = {t = 13, a = true}, -- Smelt Copper
        [2658] = {t = 5029}, -- Smelt Silver
        [2659] = {t = 5029}, -- Smelt Bronze
        [2660] = {t = 14, a = true}, -- Rough Sharpening Stone
        [2661] = {t = 5030}, -- Copper Chain Belt
        [2662] = {t = 5031}, -- Copper Chain Pants
        [2663] = {t = 14, a = true}, -- Copper Bracers
        [2664] = {t = 5032}, -- Runed Copper Bracers
        [2665] = {t = 5030}, -- Coarse Sharpening Stone
        [2666] = {t = 5030}, -- Runed Copper Belt
        [2668] = {t = 5032}, -- Rough Bronze Leggings
        [2670] = {t = 5032}, -- Rough Bronze Cuirass
        [2671] = {u = true}, -- Rough Bronze Bracers
        [2672] = {t = 5032}, -- Patterned Bronze Bracers
        [2674] = {t = 5032}, -- Heavy Sharpening Stone
        [2675] = {t = 5032}, -- Shining Silver Breastplate
        [2737] = {t = 5030}, -- Copper Mace
        [2738] = {t = 5030}, -- Copper Axe
        [2739] = {t = 5030}, -- Copper Shortsword
        [2740] = {t = 5032}, -- Bronze Mace
        [2741] = {t = 5032}, -- Bronze Axe
        [2742] = {t = 5032}, -- Bronze Shortsword
        [2881] = {t = 2, a = true}, -- Light Leather
        [2963] = {t = 11, a = true}, -- Bolt of Linen Cloth
        [2964] = {t = 5026}, -- Bolt of Woolen Cloth
        [3115] = {t = 14, a = true}, -- Rough Weightstone
        [3116] = {t = 5030}, -- Coarse Weightstone
        [3117] = {t = 5032}, -- Heavy Weightstone
        [3170] = {t = 5025}, -- Weak Troll's Blood Potion
        [3171] = {t = 5033}, -- Elixir of Wisdom
        [3173] = {t = 5033}, -- Lesser Mana Potion
        [3176] = {t = 5033}, -- Strong Troll's Blood Potion
        [3177] = {t = 5033}, -- Elixir of Defense
        [3275] = {t = 11, a = true}, -- Linen Bandage
        [3276] = {t = 5018, a = true}, -- Heavy Linen Bandage
        [3277] = {t = 5018, a = true}, -- Wool Bandage
        [3278] = {t = 5018, a = true}, -- Heavy Wool Bandage
        [3292] = {t = 5032}, -- Heavy Copper Broadsword
        [3293] = {t = 5030}, -- Copper Battle Axe
        [3294] = {t = 5030}, -- Thick War Axe
        [3296] = {t = 5032}, -- Heavy Bronze Mace
        [3304] = {t = 5029}, -- Smelt Tin
        [3307] = {t = 5029}, -- Smelt Iron
        [3308] = {t = 5029}, -- Smelt Gold
        [3319] = {t = 5030}, -- Copper Chain Boots
        [3320] = {t = 5030}, -- Rough Grinding Stone
        [3323] = {t = 5030}, -- Runed Copper Gauntlets
        [3324] = {t = 5030}, -- Runed Copper Pants
        [3326] = {t = 5030}, -- Coarse Grinding Stone
        [3328] = {t = 5034}, -- Rough Bronze Shoulders
        [3331] = {t = 5032}, -- Silvered Bronze Boots
        [3333] = {t = 5032}, -- Silvered Bronze Gauntlets
        [3337] = {t = 5032}, -- Heavy Grinding Stone
        [3448] = {t = 5035}, -- Lesser Invisibility Potion
        [3451] = {t = 21}, -- Mighty Troll's Blood Potion
        [3452] = {t = 5035}, -- Mana Potion
        [3491] = {t = 5034}, -- Big Bronze Knife
        [3501] = {t = 22}, -- Green Iron Bracers
        [3502] = {t = 22}, -- Green Iron Helm
        [3506] = {t = 22}, -- Green Iron Leggings
        [3508] = {t = 22}, -- Green Iron Hauberk
        [3569] = {t = 5029}, -- Smelt Steel
        [3753] = {t = 5020}, -- Handstitched Leather Belt
        [3755] = {t = 5026}, -- Linen Bag
        [3756] = {t = 5022}, -- Embossed Leather Gloves
        [3757] = {t = 5027}, -- Woolen Bag
        [3759] = {t = 5036}, -- Embossed Leather Pants
        [3760] = {t = 5037}, -- Hillman's Cloak
        [3761] = {t = 5023}, -- Fine Leather Tunic
        [3763] = {t = 5023}, -- Fine Leather Belt
        [3764] = {t = 5037}, -- Hillman's Leather Gloves
        [3766] = {t = 5037}, -- Dark Leather Belt
        [3768] = {t = 5037}, -- Hillman's Shoulders
        [3770] = {t = 5037}, -- Toughened Leather Gloves
        [3774] = {t = 23}, -- Green Leather Belt
        [3776] = {t = 23}, -- Green Leather Bracers
        [3780] = {t = 5037}, -- Heavy Armor Kit
        [3813] = {t = 5027}, -- Small Silk Pack
        [3816] = {t = 5020}, -- Cured Light Hide
        [3817] = {t = 5023}, -- Cured Medium Hide
        [3818] = {t = 5037}, -- Cured Heavy Hide
        [3839] = {t = 5027}, -- Bolt of Silk Cloth
        [3840] = {t = 5026}, -- Heavy Linen Gloves
        [3841] = {t = 5026}, -- Green Linen Bracers
        [3842] = {t = 5026}, -- Handstitched Linen Britches
        [3843] = {t = 5027}, -- Heavy Woolen Gloves
        [3845] = {t = 5027}, -- Soft-soled Linen Boots
        [3848] = {t = 5027}, -- Double-stitched Woolen Shoulders
        [3850] = {t = 5027}, -- Heavy Woolen Pants
        [3852] = {t = 5027}, -- Gloves of Meditation
        [3855] = {t = 5027}, -- Spidersilk Boots
        [3859] = {t = 5027}, -- Azure Silk Vest
        [3861] = {t = 5038}, -- Long Silken Cloak
        [3865] = {t = 5038}, -- Bolt of Mageweave
        [3866] = {t = 5027}, -- Stylish Red Shirt
        [3871] = {t = 5038}, -- Formal White Shirt
        [3914] = {t = 5026}, -- Brown Linen Pants
        [3915] = {t = 25, a = true}, -- Brown Linen Shirt
        [3918] = {t = 26, a = true}, -- Rough Blasting Powder
        [3919] = {t = 26, a = true}, -- Rough Dynamite
        [3920] = {t = 26, a = true}, -- Crafted Light Shot
        [3922] = {t = 5039}, -- Handful of Copper Bolts
        [3923] = {t = 5039}, -- Rough Copper Bomb
        [3924] = {t = 5039}, -- Copper Tube
        [3925] = {t = 5039}, -- Rough Boomstick
        [3926] = {t = 5039}, -- Copper Modulator
        [3929] = {t = 5039}, -- Coarse Blasting Powder
        [3930] = {t = 5040}, -- Crafted Heavy Shot
        [3931] = {t = 5040}, -- Coarse Dynamite
        [3932] = {t = 29}, -- Target Dummy
        [3934] = {t = 29}, -- Flying Tiger Goggles
        [3936] = {t = 29}, -- Deadly Blunderbuss
        [3937] = {t = 29}, -- Large Copper Bomb
        [3938] = {t = 29}, -- Bronze Tube
        [3941] = {t = 29}, -- Small Bronze Bomb
        [3942] = {t = 29}, -- Whirring Bronze Gizmo
        [3945] = {t = 29}, -- Heavy Blasting Powder
        [3946] = {t = 29}, -- Heavy Dynamite
        [3947] = {t = 29}, -- Crafted Solid Shot
        [3949] = {t = 29}, -- Silver-plated Shotgun
        [3950] = {t = 29}, -- Big Bronze Bomb
        [3953] = {t = 29}, -- Bronze Framework
        [3955] = {t = 29}, -- Explosive Sheep
        [3956] = {t = 29}, -- Green Tinted Goggles
        [3958] = {t = 30}, -- Iron Strut
        [3961] = {t = 30}, -- Gyrochronatom
        [3962] = {t = 30}, -- Iron Grenade
        [3963] = {t = 30}, -- Compact Harvest Reaper Kit
        [3965] = {t = 30}, -- Advanced Target Dummy
        [3967] = {t = 30}, -- Big Iron Bomb
        [3973] = {t = 29}, -- Silver Contact
        [3977] = {t = 5039}, -- Crude Scope
        [3978] = {t = 29}, -- Standard Scope
        [4094] = {t = 31}, -- Barbecued Buzzard Wing
        [6458] = {t = 29}, -- Ornate Spyglass
        [6499] = {t = 5028}, -- Boiled Clams
        [6500] = {t = 5028}, -- Goblin Deviled Clams
        [6517] = {t = 5032}, -- Pearl-handled Dagger
        [6521] = {t = 5027}, -- Pearl-clasped Cloak
        [6661] = {t = 23}, -- Barbaric Harness
        [6690] = {t = 5027}, -- Lesser Wizard's Robe
        [7126] = {t = 2, a = true}, -- Handstitched Leather Vest
        [7135] = {t = 5023}, -- Dark Leather Pants
        [7147] = {t = 23}, -- Guardian Pants
        [7151] = {t = 23}, -- Barbaric Shoulders
        [7156] = {t = 23}, -- Guardian Gloves
        [7179] = {t = 5033}, -- Elixir of Water Breathing
        [7183] = {t = 7, a = true}, -- Elixir of Minor Defense
        [7223] = {t = 22}, -- Golden Scale Bracers
        [7408] = {t = 5030}, -- Heavy Copper Maul
        [7418] = {t = 32, a = true}, -- Enchant Bracer - Minor Health
        [7420] = {t = 5041}, -- Enchant Chest - Minor Health
        [7421] = {t = 32, a = true}, -- Runed Copper Rod
        [7426] = {t = 5041}, -- Enchant Chest - Minor Absorption
        [7428] = {t = 33, a = true}, -- Enchant Bracer - Minor Deflect
        [7430] = {t = 5039}, -- Arclight Spanner
        [7454] = {t = 5041}, -- Enchant Cloak - Minor Resistance
        [7457] = {t = 5041}, -- Enchant Bracer - Minor Stamina
        [7623] = {t = 5026}, -- Brown Linen Robe
        [7624] = {t = 5026}, -- White Linen Robe
        [7636] = {u = true}, -- Green Woolen Robe
        [7745] = {t = 5042}, -- Enchant 2H Weapon - Minor Impact
        [7748] = {t = 5041}, -- Enchant Chest - Lesser Health
        [7771] = {t = 5041}, -- Enchant Cloak - Minor Protection
        [7779] = {t = 5042}, -- Enchant Bracer - Minor Agility
        [7788] = {t = 5042}, -- Enchant Weapon - Minor Striking
        [7795] = {t = 5042}, -- Runed Silver Rod
        [7817] = {t = 5032}, -- Rough Bronze Boots
        [7818] = {t = 5032}, -- Silver Rod
        [7836] = {t = 5033}, -- Blackmouth Oil
        [7837] = {t = 5033}, -- Fire Oil
        [7841] = {t = 5033}, -- Swim Speed Potion
        [7845] = {t = 5033}, -- Elixir of Firepower
        [7857] = {t = 5042}, -- Enchant Chest - Health
        [7861] = {t = 5042}, -- Enchant Cloak - Lesser Fire Resistance
        [7863] = {t = 5042}, -- Enchant Boots - Minor Stamina
        [7928] = {t = 5018, a = true}, -- Silk Bandage
        [7929] = {t = 11, a = true}, -- Heavy Silk Bandage
        [7934] = {t = 5018, a = true}, -- Anti-Venom
        [8334] = {t = 29}, -- Practice Lock
        [8366] = {u = true}, -- Ironforge Chain
        [8368] = {u = true}, -- Ironforge Gauntlets
        [8465] = {t = 5026}, -- Simple Dress
        [8467] = {t = 5027}, -- White Woolen Dress
        [8483] = {t = 5038}, -- White Swashbuckler's Shirt
        [8489] = {t = 5038}, -- Red Swashbuckler's Shirt
        [8604] = {t = 1, a = true}, -- Herb Baked Egg
        [8758] = {t = 5027}, -- Azure Silk Pants
        [8760] = {t = 5027}, -- Azure Silk Hood
        [8762] = {t = 5038}, -- Silk Headband
        [8764] = {t = 5038}, -- Earthen Vest
        [8766] = {t = 5038}, -- Azure Silk Belt
        [8768] = {t = 5032}, -- Iron Buckle
        [8770] = {t = 5038}, -- Robe of Power
        [8772] = {t = 5038}, -- Crimson Silk Belt
        [8774] = {t = 5038}, -- Green Silken Shoulders
        [8776] = {t = 5026}, -- Linen Belt
        [8778] = {u = true}, -- Boots of Darkness
        [8791] = {t = 5038}, -- Crimson Silk Vest
        [8799] = {t = 5038}, -- Crimson Silk Pantaloons
        [8804] = {t = 5038}, -- Crimson Silk Gloves
        [8880] = {t = 5030}, -- Copper Dagger
        [8895] = {t = 35}, -- Goblin Rocket Boots
        [9058] = {t = 2, a = true}, -- Handstitched Leather Cloak
        [9059] = {t = 2, a = true}, -- Handstitched Leather Bracers
        [9060] = {t = 5020}, -- Light Leather Quiver
        [9062] = {t = 5022}, -- Small Leather Ammo Pouch
        [9065] = {t = 5043}, -- Light Leather Bracers
        [9068] = {t = 5021}, -- Light Leather Pants
        [9074] = {t = 5023}, -- Nimble Leather Gloves
        [9145] = {t = 5037}, -- Fletcher's Gloves
        [9193] = {t = 5037}, -- Heavy Quiver
        [9194] = {t = 5037}, -- Heavy Leather Ammo Pouch
        [9196] = {t = 23}, -- Dusky Leather Armor
        [9198] = {t = 23}, -- Frost Leather Cloak
        [9201] = {t = 23}, -- Dusky Bracers
        [9206] = {t = 23}, -- Dusky Belt
        [9271] = {t = 29}, -- Aquadynamic Fish Attractor
        [9916] = {t = 22}, -- Steel Breastplate
        [9918] = {t = 22}, -- Solid Sharpening Stone
        [9920] = {t = 22}, -- Solid Grinding Stone
        [9921] = {t = 22}, -- Solid Weightstone
        [9926] = {t = 22}, -- Heavy Mithril Shoulder
        [9928] = {t = 22}, -- Heavy Mithril Gauntlet
        [9931] = {t = 22}, -- Mithril Scale Pants
        [9935] = {t = 22}, -- Steel Plate Helm
        [9942] = {u = true}, -- Mithril Scale Gloves
        [9954] = {t = 36}, -- Truesilver Gauntlets
        [9957] = {q = {{2756, 7792, 1637, "H"}}}, -- Orcish War Leggings
        [9959] = {t = 22}, -- Heavy Mithril Breastplate
        [9961] = {t = 37}, -- Mithril Coif
        [9968] = {t = 37}, -- Heavy Mithril Boots
        [9972] = {q = {{2773, 7804, 440}}}, -- Ornate Mithril Breastplate
        [9974] = {t = 36}, -- Truesilver Breastplate
        [9979] = {q = {{2772, 7804, 440}}}, -- Ornate Mithril Boots
        [9980] = {q = {{2771, 7804, 440}}}, -- Ornate Mithril Helm
        [9983] = {t = 5030}, -- Copper Claymore
        [9985] = {t = 5032}, -- Bronze Warhammer
        [9986] = {t = 5032}, -- Bronze Greatsword
        [9987] = {t = 5032}, -- Bronze Battle Axe
        [9993] = {t = 22}, -- Heavy Mithril Axe
        [10001] = {t = 22}, -- Big Black Mace
        [10003] = {t = 38}, -- The Shatterer
        [10007] = {t = 38}, -- Phantom Blade
        [10011] = {t = 38}, -- Blight
        [10015] = {t = 38}, -- Truesilver Champion
        [10097] = {t = 5029}, -- Smelt Mithril
        [10098] = {t = 5029}, -- Smelt Truesilver
        [10482] = {t = 23}, -- Cured Thick Hide
        [10487] = {t = 23}, -- Thick Armor Kit
        [10499] = {t = 39}, -- Nightscape Tunic
        [10507] = {t = 39}, -- Nightscape Headband
        [10511] = {t = 40}, -- Turtle Scale Breastplate
        [10518] = {t = 40}, -- Turtle Scale Bracers
        [10548] = {t = 40}, -- Nightscape Pants
        [10550] = {u = true}, -- Nightscape Cloak
        [10552] = {t = 40}, -- Turtle Scale Helm
        [10556] = {t = 40}, -- Turtle Scale Leggings
        [10558] = {t = 40}, -- Nightscape Boots
        [10619] = {t = 41}, -- Dragonscale Gauntlets
        [10621] = {t = 42}, -- Wolfshead Helm
        [10630] = {t = 43}, -- Gauntlets of the Sea
        [10632] = {t = 43}, -- Helm of Fire
        [10647] = {t = 44}, -- Feathered Breastplate
        [10650] = {t = 41}, -- Dragonscale Breastplate
        [10840] = {t = 11, a = true}, -- Mageweave Bandage
        [10841] = {t = 45, a = true}, -- Heavy Mageweave Bandage
        [11447] = {u = true}, -- Elixir of Waterwalking
        [11448] = {t = 5044}, -- Greater Mana Potion
        [11449] = {t = 5035}, -- Elixir of Agility
        [11450] = {t = 5035}, -- Elixir of Greater Defense
        [11451] = {t = 5044}, -- Oil of Immolation
        [11452] = {q = {{2203, 6868, 3, "H"}, {2501, 1470, 38, "A"}}}, -- Restorative Potion
        [11460] = {t = 46}, -- Elixir of Detect Undead
        [11461] = {t = 46}, -- Arcane Elixir
        [11465] = {t = 46}, -- Elixir of Greater Intellect
        [11467] = {t = 46}, -- Elixir of Greater Agility
        [11478] = {t = 46}, -- Elixir of Detect Demon
        [12044] = {t = 25, a = true}, -- Simple Linen Pants
        [12045] = {t = 5026}, -- Simple Linen Boots
        [12046] = {t = 5026}, -- Simple Kilt
        [12048] = {t = 5038}, -- Black Mageweave Vest
        [12049] = {t = 5038}, -- Black Mageweave Leggings
        [12050] = {t = 5038}, -- Black Mageweave Robe
        [12052] = {t = 47}, -- Shadoweave Pants
        [12053] = {t = 5038}, -- Black Mageweave Gloves
        [12055] = {t = 47}, -- Shadoweave Robe
        [12061] = {t = 5038}, -- Orange Mageweave Shirt
        [12062] = {u = true}, -- Stormcloth Pants
        [12063] = {u = true}, -- Stormcloth Gloves
        [12065] = {t = 5038}, -- Mageweave Bag
        [12067] = {t = 5038}, -- Dreamweave Gloves
        [12068] = {u = true}, -- Stormcloth Vest
        [12069] = {t = 5038}, -- Cindercloth Robe
        [12070] = {t = 5038}, -- Dreamweave Vest
        [12071] = {t = 47}, -- Shadoweave Gloves
        [12072] = {t = 48}, -- Black Mageweave Headband
        [12073] = {t = 48}, -- Black Mageweave Boots
        [12074] = {t = 49}, -- Black Mageweave Shoulders
        [12076] = {t = 47}, -- Shadoweave Shoulders
        [12077] = {t = 48}, -- Simple Black Dress
        [12079] = {t = 48}, -- Red Mageweave Bag
        [12082] = {t = 47}, -- Shadoweave Boots
        [12083] = {u = true}, -- Stormcloth Headband
        [12087] = {u = true}, -- Stormcloth Shoulders
        [12088] = {t = 48}, -- Cindercloth Boots
        [12090] = {u = true}, -- Stormcloth Boots
        [12092] = {t = 48}, -- Dreamweave Circlet
        [12260] = {t = 14, a = true}, -- Rough Copper Vest
        [12584] = {t = 29}, -- Gold Power Core
        [12585] = {t = 30}, -- Solid Blasting Powder
        [12586] = {t = 30}, -- Solid Dynamite
        [12589] = {t = 30}, -- Mithril Tube
        [12590] = {t = 30}, -- Gyromatic Micro-Adjustor
        [12591] = {t = 30}, -- Unstable Trigger
        [12594] = {t = 30}, -- Fire Goggles
        [12595] = {t = 30}, -- Mithril Blunderbuss
        [12596] = {t = 30}, -- Hi-Impact Mithril Slugs
        [12599] = {t = 30}, -- Mithril Casing
        [12603] = {t = 30}, -- Mithril Frag Bomb
        [12609] = {t = 5035}, -- Catseye Elixir
        [12618] = {t = 50}, -- Rose Colored Goggles
        [12619] = {t = 50}, -- Hi-Explosive Bomb
        [12621] = {t = 50}, -- Mithril Gyro-Shot
        [12622] = {t = 50}, -- Green Lens
        [12715] = {t = 35}, -- Goblin Rocket Fuel Recipe
        [12716] = {t = 35}, -- Goblin Mortar
        [12717] = {t = 35}, -- Goblin Mining Helmet
        [12718] = {t = 35}, -- Goblin Construction Helmet
        [12719] = {u = true}, -- Explosive Arrow
        [12720] = {u = true}, -- Goblin "Boom" Box
        [12722] = {u = true}, -- Goblin Radio
        [12754] = {t = 35}, -- The Big One
        [12755] = {t = 35}, -- Goblin Bomb Dispenser
        [12758] = {t = 35}, -- Goblin Rocket Helmet
        [12759] = {t = 51}, -- Gnomish Death Ray
        [12760] = {t = 35}, -- Goblin Sapper Charge
        [12895] = {t = 52}, -- Inlaid Mithril Cylinder Plans
        [12897] = {t = 51}, -- Gnomish Goggles
        [12899] = {t = 51}, -- Gnomish Shrink Ray
        [12900] = {u = true}, -- Mobile Alarm
        [12902] = {t = 51}, -- Gnomish Net-o-Matic Projector
        [12903] = {t = 51}, -- Gnomish Harm Prevention Belt
        [12904] = {u = true}, -- Gnomish Ham Radio
        [12905] = {t = 51}, -- Gnomish Rocket Boots
        [12906] = {t = 51}, -- Gnomish Battle Chicken
        [12907] = {t = 51}, -- Gnomish Mind Control Cap
        [12908] = {t = 35}, -- Goblin Dragon Gun
        [13028] = {t = 53}, -- Goldthorn Tea
        [13240] = {t = 35}, -- The Mortar: Reloaded
        [13378] = {t = 5042}, -- Enchant Shield - Minor Stamina
        [13421] = {t = 5042}, -- Enchant Cloak - Lesser Protection
        [13485] = {t = 5042}, -- Enchant Shield - Lesser Spirit
        [13501] = {t = 5042}, -- Enchant Bracer - Lesser Stamina
        [13503] = {t = 5042}, -- Enchant Weapon - Lesser Striking
        [13529] = {t = 5042}, -- Enchant 2H Weapon - Lesser Impact
        [13538] = {t = 5042}, -- Enchant Chest - Lesser Absorption
        [13607] = {t = 5042}, -- Enchant Chest - Mana
        [13622] = {t = 5045}, -- Enchant Bracer - Lesser Intellect
        [13626] = {t = 5042}, -- Enchant Chest - Minor Stats
        [13628] = {t = 5042}, -- Runed Golden Rod
        [13631] = {t = 5046}, -- Enchant Shield - Lesser Stamina
        [13635] = {t = 5046}, -- Enchant Cloak - Defense
        [13637] = {t = 5046}, -- Enchant Boots - Lesser Agility
        [13640] = {t = 5046}, -- Enchant Chest - Greater Health
        [13642] = {t = 5046}, -- Enchant Bracer - Spirit
        [13644] = {t = 5046}, -- Enchant Boots - Lesser Stamina
        [13648] = {t = 5046}, -- Enchant Bracer - Stamina
        [13657] = {t = 5046}, -- Enchant Cloak - Fire Resistance
        [13659] = {t = 5046}, -- Enchant Shield - Spirit
        [13661] = {t = 5046}, -- Enchant Bracer - Strength
        [13663] = {t = 5046}, -- Enchant Chest - Greater Mana
        [13693] = {t = 5046}, -- Enchant Weapon - Striking
        [13695] = {t = 5046}, -- Enchant 2H Weapon - Impact
        [13700] = {t = 5046}, -- Enchant Chest - Lesser Stats
        [13702] = {t = 5046}, -- Runed Truesilver Rod
        [13746] = {t = 5046}, -- Enchant Cloak - Greater Defense
        [13794] = {t = 5046}, -- Enchant Cloak - Resistance
        [13815] = {t = 5046}, -- Enchant Gloves - Agility
        [13822] = {t = 5046}, -- Enchant Bracer - Intellect
        [13836] = {t = 5046}, -- Enchant Boots - Stamina
        [13858] = {t = 5046}, -- Enchant Chest - Superior Health
        [13887] = {t = 5046}, -- Enchant Gloves - Strength
        [13890] = {t = 5046}, -- Enchant Boots - Minor Speed
        [13905] = {t = 56}, -- Enchant Shield - Greater Spirit
        [13917] = {t = 56}, -- Enchant Chest - Superior Mana
        [13935] = {t = 56}, -- Enchant Boots - Agility
        [13937] = {t = 56}, -- Enchant 2H Weapon - Greater Impact
        [13939] = {t = 56}, -- Enchant Bracer - Greater Strength
        [13941] = {t = 56}, -- Enchant Chest - Stats
        [13943] = {t = 56}, -- Enchant Weapon - Greater Striking
        [13948] = {t = 56}, -- Enchant Gloves - Minor Haste
        [14293] = {t = 5041}, -- Lesser Magic Wand
        [14379] = {t = 5032}, -- Golden Rod
        [14380] = {t = 22}, -- Truesilver Rod
        [14807] = {t = 5041}, -- Greater Magic Wand
        [14809] = {t = 5046}, -- Lesser Mystic Wand
        [14810] = {t = 5046}, -- Greater Mystic Wand
        [14891] = {q = {{4083, 9037, 1585}}}, -- Smelt Dark Iron
        [14930] = {t = 40}, -- Quickdraw Quiver
        [14932] = {t = 40}, -- Thick Leather Ammo Pouch
        [15255] = {t = 30}, -- Mechanical Repair Kit
        [15833] = {t = 46}, -- Dreamless Sleep Potion
        [15972] = {t = 22}, -- Glinting Steel Dagger
        [16153] = {t = 5029}, -- Smelt Thorium
        [16639] = {t = 37}, -- Dense Grinding Stone
        [16640] = {t = 37}, -- Dense Weightstone
        [16641] = {t = 37}, -- Dense Sharpening Stone
        [16965] = {u = true}, -- Bleakwood Hew
        [16967] = {u = true}, -- Inlaid Thorium Hammer
        [16986] = {u = true}, -- Blood Talon
        [16987] = {u = true}, -- Darkspear
        [17180] = {t = 56}, -- Enchanted Thorium
        [17181] = {t = 56}, -- Enchanted Leather
        [17551] = {t = 46}, -- Stonescale Oil
        [17632] = {u = true}, -- Alchemist's Stone
        [18401] = {t = 48}, -- Bolt of Runecloth
        [18402] = {t = 48}, -- Runecloth Belt
        [18629] = {t = 45, a = true}, -- Runecloth Bandage
        [18630] = {t = 45, a = true}, -- Heavy Runecloth Bandage
        [19047] = {t = 40}, -- Cured Rugged Hide
        [19058] = {t = 40}, -- Rugged Armor Kit
        [19093] = {q = {{7493, 14392, 1637, "H"}, {7497, 14394, 1519, "A"}}}, -- Onyxia Scale Cloak
        [19106] = {u = true}, -- Onyxia Scale Breastplate
        [19435] = {q = {{6032, 11557, 493}}}, -- Mooncloth Boots
        [19567] = {t = 50}, -- Salt Shaker
        [19666] = {t = 5034}, -- Silver Skeleton Key
        [19667] = {t = 5032}, -- Golden Skeleton Key
        [19668] = {t = 22}, -- Truesilver Skeleton Key
        [19669] = {t = 37}, -- Arcanite Skeleton Key
        [19788] = {t = 50}, -- Dense Blasting Powder
        [19790] = {t = 50}, -- Thorium Grenade
        [19791] = {t = 50}, -- Thorium Widget
        [20201] = {t = 37}, -- Arcanite Rod
        [20648] = {t = 5023}, -- Medium Leather
        [20649] = {t = 5037}, -- Heavy Leather
        [20650] = {t = 23}, -- Thick Leather
        [21175] = {t = 5028}, -- Spider Sausage
        [22331] = {t = 39}, -- Rugged Leather
        [22430] = {u = true}, -- Refined Scale of Onyxia
        [22808] = {t = 5044}, -- Elixir of Greater Water Breathing
        [22813] = {t = 57}, -- Gordok Ogre Suit
        [22815] = {t = 57}, -- Gordok Ogre Suit
        [22967] = {t = 58}, -- Smelt Elementium
        [23070] = {t = 50}, -- Dense Dynamite
        [23486] = {t = 59}, -- Dimensional Ripper - Everlook
        [23489] = {t = 60}, -- Ultrasafe Transporter - Gadgetzan
        [24266] = {o = {{180368, 1977}}}, -- Gurubashi Mojo Madness
        [24654] = {t = 41}, -- Blue Dragonscale Leggings
        [24655] = {t = 41}, -- Green Dragonscale Gauntlets
        [24801] = {q = {{8313}}}, -- Smoked Desert Dumplings
        [26011] = {q = {{8798, 10305, 618}}}, -- Tranquil Mechanical Yeti
        [28205] = {t = 61}, -- Glacial Gloves
        [28207] = {t = 61}, -- Glacial Vest
        [28208] = {t = 61}, -- Glacial Cloak
        [28209] = {t = 61}, -- Glacial Wrists
        [28219] = {t = 61}, -- Polar Tunic
        [28220] = {t = 61}, -- Polar Gloves
        [28221] = {t = 61}, -- Polar Bracers
        [28222] = {t = 61}, -- Icy Scale Breastplate
        [28223] = {t = 61}, -- Icy Scale Gauntlets
        [28224] = {t = 61}, -- Icy Scale Bracers
        [28242] = {t = 61}, -- Icebane Breastplate
        [28243] = {t = 61}, -- Icebane Gauntlets
        [28244] = {t = 61}, -- Icebane Bracers
        [28327] = {u = true}, -- Steam Tonk Controller
        [1229432] = {t = 5001, q = {{96031, 265813, 1, "A"}, {97906, 265809, 14, "H"}, {97922, 263399, 12, "A"}, {97934, 265810, 215, "H"}, {97946, 265811, 141, "A"}, {97958, 265812, 85, "H"}, {97969, 263664, 16593}}}, -- Camp Tent
        [1229504] = {t = 5002, q = {{96102, 265809, 14, "H"}, {97961, 265812, 85, "H"}, {97972, 263664, 16593, "H"}}}, -- Faction Banner
        [1229517] = {t = 5003, q = {{96056, 265813, 1, "A"}, {97908, 265809, 14, "H"}, {97924, 263399, 12, "A"}, {97936, 265810, 215, "H"}, {97949, 265811, 141, "A"}, {97960, 265812, 85, "H"}, {97971, 263664, 16593}}}, -- Camp Chair
        [1229705] = {t = 5004, q = {{96055, 265813, 1, "A"}, {97905, 265809, 14, "H"}, {97921, 263399, 12, "A"}, {97933, 265810, 215, "H"}, {97944, 265811, 141, "A"}, {97957, 265812, 85, "H"}, {97968, 263664, 16593}}}, -- Incense Candle
        [1229737] = {t = 5005}, -- Basic Campfire
        [1229745] = {t = 5006, q = {{96050, 265813, 1, "A"}, {97904, 265809, 14, "H"}, {97920, 263399, 12, "A"}, {97932, 265810, 215, "H"}, {97943, 265811, 141, "A"}, {97956, 265812, 85, "H"}, {97967, 263664, 16593}}}, -- Fish Bowl
        [1230117] = {t = 5007, q = {{96047, 265813, 1, "A"}, {97903, 265809, 14, "H"}, {97919, 263399, 12, "A"}, {97931, 265810, 215, "H"}, {97942, 265811, 141, "A"}, {97955, 265812, 85, "H"}, {97965, 263664, 16593}}}, -- First Aid Kit
        [1230161] = {t = 5008, q = {{96046, 265813, 1, "A"}, {97907, 265809, 14, "H"}, {97923, 263399, 12, "A"}, {97935, 265810, 215, "H"}, {97948, 265811, 141, "A"}, {97959, 265812, 85, "H"}, {97970, 263664, 16593}}}, -- Lodestone
        [1230171] = {t = 5009}, -- Sharpening Wheel
        [1230564] = {t = 5010, q = {{96045, 1246, 1537, "A"}, {97899, 265809, 14, "H"}, {97915, 263399, 12, "A"}, {97927, 265810, 215, "H"}, {97938, 265811, 141, "A"}, {97951, 265812, 85, "H"}, {97963, 263664, 16593}}}, -- Mana Well
        [1230643] = {t = 5011, q = {{96059, 11065, 1537, "A"}, {97901, 265809, 14, "H"}, {97917, 263399, 12, "A"}, {97940, 265811, 141, "A"}, {97953, 265812, 85, "H"}, {98286, 263664, 16593, "A"}}}, -- Enchanted Lute
        [1230656] = {t = 5012, q = {{96058, 265813, 1, "A"}, {97902, 265809, 14, "H"}, {97918, 263399, 12, "A"}, {97954, 265812, 85, "H"}, {98285, 251684, 16593}}}, -- Reagent Bot
        [1244431] = {t = 5007}, -- Minor Healing Potion
        [1244432] = {t = 5007}, -- Lesser Healing Potion
        [1244433] = {t = 5007}, -- Healing Potion
        [1244645] = {t = 5013}, -- Lesser Discolored Healing Potion
        [1244646] = {t = 5013}, -- Discolored Healing Potion
        [1244647] = {t = 5013}, -- Greater Discolored Healing Potion
        [1244648] = {t = 5013}, -- Superior Discolored Healing Potion
        [1249630] = {t = 5010}, -- Cerulean Dye
        [1249631] = {t = 5014}, -- Magenta Dye
        [1249632] = {t = 5015}, -- Viridian Dye
        [1249633] = {t = 5016}, -- Sulfuric Acid
        [1249637] = {t = 5017}, -- Smelt Azerothium
        [1259342] = {t = 5018}, -- Simple Poultice
        [1259347] = {t = 5007}, -- Woolen Tourniquet
        [1263425] = {t = 5019, q = {{96057, 265813, 1, "A"}, {97925, 263399, 12, "A"}, {97950, 265811, nil, "A"}, {97973, 263664, 16593, "A"}}}, -- Faction Banner
        [1306126] = {t = 5008}, -- Smelt Heavy Thorium
        [3450] = {t = 5015},
        [1252229] = {t = 5047}, -- Gemmed Copper Boots
        [1252230] = {t = 5047}, -- Strange Copper Boots
        [1252231] = {t = 5047}, -- Glowing Copper Boots
        [1252305] = {t = 5048}, -- Officer's Belt
        [1252306] = {t = 5048}, -- Sentinel's Belt
        [1252307] = {t = 5048}, -- Warder's Belt
        [1252308] = {t = 5048}, -- Prefect's Belt
        [1252309] = {t = 5048}, -- Justicar's Belt
        [1255075] = {t = 5049}, -- Mender's Leather Belt
        [1255076] = {t = 5049}, -- Skycaller's Leather Belt
        [1255077] = {t = 5049}, -- Skirmisher's Leather Belt
        [1255078] = {t = 5049}, -- Warden's Leather Belt
        [1255079] = {t = 5049}, -- Stalker's Leather Belt
        [1255080] = {t = 5049}, -- Skulker's Leather Belt
        [1255081] = {t = 5049}, -- Prowler's Leather Belt
        [1255143] = {t = 5050}, -- Moonglow Boots
        [1255144] = {t = 5050}, -- Murloc Scale Shoes
        [1255145] = {t = 5050}, -- Dark Leather Boots
        [1255146] = {t = 5050}, -- Black Whelp Slippers
        [1257368] = {t = 5051}, -- Novice Arcanist's Sash
        [1257369] = {t = 5051}, -- Novice Ardent's Sash
        [1257426] = {t = 5051}, -- Gilded Slippers
        [1257427] = {t = 5051}, -- Frothing Slippers
        [1257428] = {t = 5051}, -- Fiery Slippers
        [1257429] = {t = 5051}, -- Black Slippers
        [1257430] = {t = 5051}, -- Golden Slippers
        [1257431] = {t = 5051}, -- Radiant Slippers
    },
};

_G.professionMaster:CreateModel("skill-sources-forever", foreverSkillSources);
