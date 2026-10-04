--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Skill sources for bcc: trainer groups, trainer npcs (zone, side) and per skill sources
-- Format: skills[spellId] = {t = groupId, q = {{questId, giverId, zoneId, side, flags, giverType}}, d = {researchSpellId}, a = true (learned with the profession), u = true (not available)}
-- flags: 1 daily, 2 weekly, 4 repeatable; giverType: nil npc, "o" object, "i" item
local bccSkillSources = {
    groups = {
        [1001] = {1355, 1382, 1430, 1699, 2942, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19186, 19369},
        [1002] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087},
        [1003] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7868, 7869, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087},
        [1004] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087},
        [1005] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 16161, 16588, 16642, 16723, 17215, 18802, 19052},
        [1006] = {1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487, 18749, 18772},
        [1007] = {1103, 1300, 1346, 1703, 2399, 2627, 2855, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11048, 11050, 11051, 11052, 16366, 16639, 16640, 16729, 16746, 17487, 18749, 18772},
        [1008] = {1355, 1382, 1430, 1699, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19369},
        [1009] = {2942},
        [1010] = {1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 16663, 16752, 17488, 18747, 18779, 18804},
        [1011] = {1384, 1681, 1701, 2222, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 12035, 16663, 16752, 17488, 18747, 18779, 18804},
        [1012] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125},
        [1013] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 21209},
        [1014] = {2325, 2326, 2327, 2329, 2798, 3181, 3373, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 16272, 16662, 16731, 17214, 17424, 18990, 18991, 19184, 19478, 22477},
        [1015] = {4160},
        [1016] = {4258},
        [1017] = {1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487},
        [1018] = {1676, 1702, 3290, 3494, 5174, 5518, 7406, 7944, 8126, 8736, 8738, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 24868, 25099},
        [1019] = {1676, 1702, 3290, 3494, 5174, 5518, 8736, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576},
        [1020] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540},
        [1021] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725},
        [1022] = {5164, 7230, 11177, 20125},
        [1023] = {7231, 7232, 11146, 11178, 20124},
        [1024] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087},
        [1025] = {7866, 7867, 7870, 7871, 11097},
        [1026] = {7870, 7871, 11097},
        [1027] = {7868, 7869, 7870, 7871, 11097},
        [1028] = {1386, 4160, 7948},
        [1029] = {7406, 7944},
        [1030] = {11097},
        [1031] = {15501, 16702, 16727, 16744, 18751, 18774, 19063, 19539, 19774, 19775, 19778},
        [1032] = {15501, 16703, 16727, 16744, 18751, 18774, 19063, 19539, 19775, 19777, 19778},
        [1033] = {15501, 16702, 16703, 16727, 16744, 18751, 18774, 19063, 19539, 19775, 19777, 19778},
        [1034] = {15501, 16702, 18751, 18774, 19063, 19539, 19775, 19777, 19778},
        [1035] = {15501, 16702, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778},
        [1036] = {15501, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778},
        [1037] = {18749, 18772},
        [1038] = {15501, 18751, 18774, 19063, 19539, 19775, 19777, 19778},
        [1039] = {18751, 18774, 19063, 19539, 19777},
        [1040] = {18753, 18773, 19251, 19252, 19540},
        [1041] = {18753, 18773, 19252, 19540},
        [1042] = {16588, 18802, 19052},
        [1043] = {18747, 18779},
        [1044] = {16583, 16823, 19341},
        [1045] = {17634, 17637, 18752, 18775, 19576},
        [1046] = {8126, 8738},
        [1047] = {11557, 18749, 18772},
        [1048] = {18754, 18771, 19187, 21087},
        [1049] = {514, 1241, 1383, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 10276, 15400, 16583, 16669, 16724, 16823, 17245, 19341, 21209},
        [1050] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 15400, 16583, 16669, 16724, 16823, 17245, 19341, 21209},
        [1051] = {7866, 7867},
        [1052] = {7870, 7871},
        [1053] = {7868, 7869},
        [1054] = {21493},
        [1055] = {21494},
        [1056] = {18751, 18774, 19063, 19539},
        [1057] = {17634, 17637, 18752},
        [1058] = {17634},
        [1059] = {17634, 18752},
        [1060] = {19186},
        [1061] = {24868, 25099},
    },
    npcs = {
        [514] = {12, "A"}, -- Smith Argus
        [1103] = {12, "A"}, -- Eldrin
        [1215] = {12, "A"}, -- Alchemist Mallory
        [1241] = {1, "A"}, -- Tognus Flintfire
        [1300] = {1519, "A"}, -- Lawrence Schneider
        [1317] = {1519, "A"}, -- Lucan Cordell
        [1346] = {1519, "A"}, -- Georgio Bolero
        [1355] = {1, "A"}, -- Cook Ghilm
        [1382] = {33, "H"}, -- Mudduk
        [1383] = {1637, "H"}, -- Snarl
        [1384] = {nil, "H"}, -- Z'tark
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
        [1703] = {1537, "A"}, -- Uthrar Threx
        [2132] = {85, "H"}, -- Carolai Anise
        [2222] = {nil, "H"}, -- Undead Mining Trainer
        [2325] = {nil, "H"}, -- Undead First Aid Trainer
        [2326] = {1, "A"}, -- Thamner Pol
        [2327] = {1519, "A"}, -- Shaina Fuller
        [2329] = {12, "A"}, -- Michelle Belle
        [2391] = {267, "H"}, -- Serge Hinott
        [2399] = {267, "H"}, -- Daryl Stack
        [2627] = {33}, -- Grarnik Goodstitch
        [2798] = {1638, "H"}, -- Pand Stonebinder
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
        [3136] = {41, "A"}, -- Clarise Gnarltree
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
        [3478] = {215, "H"}, -- Traugh
        [3484] = {17, "H"}, -- Kil'hala
        [3494] = {17}, -- Tinkerwiz
        [3523] = {85, "H"}, -- Bowen Brisboise
        [3549] = {85, "H"}, -- Shelene Rhobart
        [3555] = {130, "H"}, -- Johan Focht
        [3557] = {130, "H"}, -- Guillaume Sorouy
        [3603] = {141, "A"}, -- Cyndra Kindwhisper
        [3605] = {141, "A"}, -- Nadyia Maneweaver
        [3606] = {141, "A"}, -- Alanna Raveneye
        [3703] = {17, "H"}, -- Krulmoo Fullmoon
        [3704] = {17, "H"}, -- Mahani
        [3964] = {331, "A"}, -- Kylanna
        [3967] = {331, "A"}, -- Aayndia Floralwind
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
        [5695] = {85, "H"}, -- Vance Undergloom
        [5759] = {85, "H"}, -- Nurse Neela
        [5784] = {17}, -- Waldor
        [5939] = {215, "H"}, -- Vira Younghoof
        [5943] = {14, "H"}, -- Rawrk
        [6094] = {141, "A"}, -- Byancie
        [6286] = {141, "A"}, -- Zarrin
        [6297] = {148, "A"}, -- Kurdram Stonehammer
        [6299] = {361, "A"}, -- Delfrum Flintbeard
        [7230] = {1637, "H"}, -- Shayis Steelfury
        [7231] = {1637, "H"}, -- Kelgruk Bloodaxe
        [7232] = {1519, "A"}, -- Borgus Steelhand
        [7406] = {33}, -- Oglethorpe Obnoticus
        [7866] = {16, "A"}, -- Peter Galen
        [7867] = {3, "H"}, -- Thorkaf Dragoneye
        [7868] = {51, "A"}, -- Sarah Tanner
        [7869] = {267, "H"}, -- Brumn Winterhoof
        [7870] = {400, "A"}, -- Caryssia Moonhunter
        [7871] = {33, "H"}, -- Se'Jib
        [7944] = {1537, "A"}, -- Tinkmaster Overspark
        [7948] = {357, "A"}, -- Kylanna Windwhisper
        [7949] = {357, "A"}, -- Xylinnia Starshine
        [8126] = {440}, -- Nixx Sprocketspring
        [8128] = {440}, -- Pikkle
        [8153] = {405, "H"}, -- Narv Hidecrafter
        [8306] = {215, "H"}, -- Duhng
        [8736] = {440}, -- Buzzek Bracketswing
        [8738] = {14}, -- Vazario Linkgrease
        [9584] = {1519, "A"}, -- Jalane Ayrole
        [10276] = {1537, "A"}, -- Rotgath Stonebeard
        [10993] = {215}, -- Twizwick Sprocketgrind
        [11017] = {1637, "H"}, -- Roxxik
        [11025] = {14, "H"}, -- Mukdrak
        [11031] = {1497, "H"}, -- Franklin Lloyd
        [11037] = {148, "A"}, -- Jenna Lemkenilli
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
        [12035] = {nil, "A"}, -- Aerie Peak Mining Trainer
        [15400] = {3430, "H"}, -- Arathel Sunforge
        [15501] = {3487, "H"}, -- Aleinia
        [16160] = {3430, "H"}, -- Magistrix Eredania
        [16161] = {3430, "H"}, -- Arcanist Sheynathren
        [16190] = {}, -- Expansion Enchanting Trainer
        [16253] = {3433, "H"}, -- Master Chef Mouldier
        [16265] = {nil, "H"}, -- Smith Daelarin
        [16272] = {3430, "H"}, -- Kanaria
        [16277] = {3487, "H"}, -- Quarelestra
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
        [16702] = {nil, "H"}, -- Telia
        [16703] = {3487, "H"}, -- Amin
        [16719] = {3557, "A"}, -- Mumman
        [16723] = {3557, "A"}, -- Lucc
        [16724] = {3557, "A"}, -- Miall
        [16725] = {3557, "A"}, -- Nahogg
        [16726] = {3557, "A"}, -- Ockil
        [16727] = {3557, "A"}, -- Padaar
        [16728] = {3557, "A"}, -- Akham
        [16729] = {3557, "A"}, -- Refik
        [16731] = {3557, "A"}, -- Nus
        [16744] = {3518, "A"}, -- Driaan
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
        [19341] = {3519, "H"}, -- Grutah
        [19369] = {3519, "A"}, -- Celie Steelwing
        [19478] = {3522, "H"}, -- Fera Palerunner
        [19539] = {3523}, -- Jazdalaad
        [19540] = {3523}, -- Asarnan
        [19576] = {3522}, -- Xyrol
        [19774] = {3487, "H"}, -- Toban
        [19775] = {3487, "H"}, -- Kalinda
        [19777] = {3557}, -- Elaando
        [19778] = {3557, "A"}, -- Farii
        [20124] = {3703}, -- Kradu Grimblade
        [20125] = {3703}, -- Zula Slagfury
        [21087] = {3522, "H"}, -- Grikka
        [21209] = {3483, "A"}, -- Dumphry
        [21493] = {3522}, -- Kablamm Farflinger
        [21494] = {3522}, -- Smiles O'Byron
        [22477] = {3519}, -- Anchorite Ensham
        [24868] = {3519}, -- Niobe Whizzlespark
        [25099] = {3519, "H"}, -- Jonathan Garrett
    },
    skills = {
        [818] = {t = 1001, a = true}, -- Basic Campfire
        [2149] = {t = 1002, a = true}, -- Handstitched Leather Boots
        [2152] = {t = 1002, a = true}, -- Light Armor Kit
        [2153] = {t = 1003}, -- Handstitched Leather Pants
        [2159] = {t = 1003}, -- Fine Leather Cloak
        [2160] = {t = 1003}, -- Embossed Leather Vest
        [2161] = {t = 1003}, -- Embossed Leather Boots
        [2162] = {t = 1004}, -- Embossed Leather Cloak
        [2165] = {t = 1004}, -- Medium Armor Kit
        [2166] = {t = 1003}, -- Toughened Leather Armor
        [2167] = {t = 1003}, -- Dark Leather Boots
        [2168] = {t = 1004}, -- Dark Leather Cloak
        [2329] = {t = 1005, a = true}, -- Elixir of Lion's Strength
        [2330] = {t = 1005, a = true}, -- Minor Healing Potion
        [2331] = {t = 1005}, -- Minor Mana Potion
        [2332] = {t = 1005}, -- Minor Rejuvenation Potion
        [2334] = {t = 1005}, -- Elixir of Minor Fortitude
        [2337] = {t = 1005}, -- Lesser Healing Potion
        [2385] = {t = 1006}, -- Brown Linen Vest
        [2386] = {t = 1006}, -- Linen Boots
        [2387] = {t = 1007, a = true}, -- Linen Cloak
        [2392] = {t = 1006}, -- Red Linen Shirt
        [2393] = {t = 1006}, -- White Linen Shirt
        [2394] = {t = 1006}, -- Blue Linen Shirt
        [2395] = {t = 1006}, -- Barbaric Linen Vest
        [2396] = {t = 1006}, -- Green Linen Shirt
        [2397] = {t = 1006}, -- Reinforced Linen Cape
        [2399] = {t = 1006}, -- Green Woolen Vest
        [2401] = {t = 1006}, -- Woolen Boots
        [2402] = {t = 1006}, -- Woolen Cape
        [2406] = {t = 1006}, -- Gray Woolen Shirt
        [2538] = {t = 1001, a = true}, -- Charred Wolf Meat
        [2539] = {t = 1008}, -- Spiced Wolf Meat
        [2540] = {t = 1001, a = true}, -- Roasted Boar Meat
        [2541] = {t = 1008}, -- Coyote Steak
        [2544] = {t = 1008}, -- Crab Cake
        [2546] = {t = 1008}, -- Dry Pork Ribs
        [2549] = {t = 1009}, -- Seasoned Wolf Kabob
        [2657] = {t = 1010, a = true}, -- Smelt Copper
        [2658] = {t = 1011}, -- Smelt Silver
        [2659] = {t = 1011}, -- Smelt Bronze
        [2660] = {t = 1012, a = true}, -- Rough Sharpening Stone
        [2661] = {t = 1013}, -- Copper Chain Belt
        [2662] = {t = 1013}, -- Copper Chain Pants
        [2663] = {t = 1012, a = true}, -- Copper Bracers
        [2664] = {t = 1013}, -- Runed Copper Bracers
        [2665] = {t = 1013}, -- Coarse Sharpening Stone
        [2666] = {t = 1013}, -- Runed Copper Belt
        [2668] = {t = 1013}, -- Rough Bronze Leggings
        [2670] = {t = 1013}, -- Rough Bronze Cuirass
        [2672] = {t = 1013}, -- Patterned Bronze Bracers
        [2674] = {t = 1013}, -- Heavy Sharpening Stone
        [2675] = {t = 1013}, -- Shining Silver Breastplate
        [2737] = {t = 1013}, -- Copper Mace
        [2738] = {t = 1013}, -- Copper Axe
        [2739] = {t = 1013}, -- Copper Shortsword
        [2740] = {t = 1013}, -- Bronze Mace
        [2741] = {t = 1013}, -- Bronze Axe
        [2742] = {t = 1013}, -- Bronze Shortsword
        [2881] = {t = 1002, a = true}, -- Light Leather
        [2963] = {t = 1007, a = true}, -- Bolt of Linen Cloth
        [2964] = {t = 1006}, -- Bolt of Woolen Cloth
        [3115] = {t = 1012, a = true}, -- Rough Weightstone
        [3116] = {t = 1013}, -- Coarse Weightstone
        [3117] = {t = 1013}, -- Heavy Weightstone
        [3170] = {t = 1005}, -- Weak Troll's Blood Potion
        [3171] = {t = 1005}, -- Elixir of Wisdom
        [3173] = {t = 1005}, -- Lesser Mana Potion
        [3176] = {t = 1005}, -- Strong Troll's Blood Potion
        [3177] = {t = 1005}, -- Elixir of Defense
        [3275] = {t = 1007, a = true}, -- Linen Bandage
        [3276] = {t = 1014, a = true}, -- Heavy Linen Bandage
        [3277] = {t = 1014, a = true}, -- Wool Bandage
        [3278] = {t = 1014, a = true}, -- Heavy Wool Bandage
        [3292] = {t = 1013}, -- Heavy Copper Broadsword
        [3293] = {t = 1013}, -- Copper Battle Axe
        [3294] = {t = 1013}, -- Thick War Axe
        [3296] = {t = 1013}, -- Heavy Bronze Mace
        [3304] = {t = 1011}, -- Smelt Tin
        [3307] = {t = 1011}, -- Smelt Iron
        [3308] = {t = 1011}, -- Smelt Gold
        [3319] = {t = 1013}, -- Copper Chain Boots
        [3320] = {t = 1013}, -- Rough Grinding Stone
        [3323] = {t = 1013}, -- Runed Copper Gauntlets
        [3324] = {t = 1013}, -- Runed Copper Pants
        [3326] = {t = 1013}, -- Coarse Grinding Stone
        [3328] = {t = 1013}, -- Rough Bronze Shoulders
        [3331] = {t = 1013}, -- Silvered Bronze Boots
        [3333] = {t = 1013}, -- Silvered Bronze Gauntlets
        [3337] = {t = 1013}, -- Heavy Grinding Stone
        [3447] = {t = 1005}, -- Healing Potion
        [3448] = {t = 1005}, -- Lesser Invisibility Potion
        [3449] = {t = 1015}, -- Shadow Oil
        [3450] = {t = 1005}, -- Elixir of Fortitude
        [3452] = {t = 1005}, -- Mana Potion
        [3454] = {t = 1015}, -- Frost Oil
        [3491] = {t = 1013}, -- Big Bronze Knife
        [3492] = {t = 1016}, -- Hardened Iron Shortsword
        [3494] = {t = 1016}, -- Solid Iron Maul
        [3496] = {t = 1016}, -- Moonsteel Broadsword
        [3498] = {t = 1016}, -- Massive Iron Axe
        [3501] = {t = 1013}, -- Green Iron Bracers
        [3502] = {t = 1013}, -- Green Iron Helm
        [3506] = {t = 1013}, -- Green Iron Leggings
        [3508] = {t = 1013}, -- Green Iron Hauberk
        [3569] = {t = 1011}, -- Smelt Steel
        [3753] = {t = 1003}, -- Handstitched Leather Belt
        [3755] = {t = 1006}, -- Linen Bag
        [3756] = {t = 1004}, -- Embossed Leather Gloves
        [3757] = {t = 1006}, -- Woolen Bag
        [3759] = {t = 1004}, -- Embossed Leather Pants
        [3760] = {t = 1004}, -- Hillman's Cloak
        [3761] = {t = 1004}, -- Fine Leather Tunic
        [3763] = {t = 1004}, -- Fine Leather Belt
        [3764] = {t = 1004}, -- Hillman's Leather Gloves
        [3766] = {t = 1004}, -- Dark Leather Belt
        [3768] = {t = 1004}, -- Hillman's Shoulders
        [3770] = {t = 1004}, -- Toughened Leather Gloves
        [3774] = {t = 1004}, -- Green Leather Belt
        [3776] = {t = 1004}, -- Green Leather Bracers
        [3780] = {t = 1004}, -- Heavy Armor Kit
        [3813] = {t = 1006}, -- Small Silk Pack
        [3816] = {t = 1003}, -- Cured Light Hide
        [3817] = {t = 1004}, -- Cured Medium Hide
        [3818] = {t = 1004}, -- Cured Heavy Hide
        [3839] = {t = 1006}, -- Bolt of Silk Cloth
        [3840] = {t = 1006}, -- Heavy Linen Gloves
        [3841] = {t = 1006}, -- Green Linen Bracers
        [3842] = {t = 1006}, -- Handstitched Linen Britches
        [3843] = {t = 1006}, -- Heavy Woolen Gloves
        [3845] = {t = 1006}, -- Soft-soled Linen Boots
        [3848] = {t = 1006}, -- Double-stitched Woolen Shoulders
        [3850] = {t = 1006}, -- Heavy Woolen Pants
        [3852] = {t = 1006}, -- Gloves of Meditation
        [3855] = {t = 1006}, -- Spidersilk Boots
        [3859] = {t = 1006}, -- Azure Silk Vest
        [3861] = {t = 1006}, -- Long Silken Cloak
        [3865] = {t = 1006}, -- Bolt of Mageweave
        [3866] = {t = 1006}, -- Stylish Red Shirt
        [3871] = {t = 1006}, -- Formal White Shirt
        [3914] = {t = 1006}, -- Brown Linen Pants
        [3915] = {t = 1017, a = true}, -- Brown Linen Shirt
        [3918] = {t = 1018, a = true}, -- Rough Blasting Powder
        [3919] = {t = 1018, a = true}, -- Rough Dynamite
        [3920] = {t = 1018, a = true}, -- Crafted Light Shot
        [3922] = {t = 1019}, -- Handful of Copper Bolts
        [3923] = {t = 1019}, -- Rough Copper Bomb
        [3924] = {t = 1019}, -- Copper Tube
        [3925] = {t = 1019}, -- Rough Boomstick
        [3926] = {t = 1019}, -- Copper Modulator
        [3929] = {t = 1019}, -- Coarse Blasting Powder
        [3930] = {t = 1019}, -- Crafted Heavy Shot
        [3931] = {t = 1019}, -- Coarse Dynamite
        [3932] = {t = 1019}, -- Target Dummy
        [3934] = {t = 1019}, -- Flying Tiger Goggles
        [3936] = {t = 1019}, -- Deadly Blunderbuss
        [3937] = {t = 1019}, -- Large Copper Bomb
        [3938] = {t = 1019}, -- Bronze Tube
        [3941] = {t = 1019}, -- Small Bronze Bomb
        [3942] = {t = 1019}, -- Whirring Bronze Gizmo
        [3945] = {t = 1019}, -- Heavy Blasting Powder
        [3946] = {t = 1019}, -- Heavy Dynamite
        [3947] = {t = 1019}, -- Crafted Solid Shot
        [3949] = {t = 1019}, -- Silver-plated Shotgun
        [3950] = {t = 1019}, -- Big Bronze Bomb
        [3953] = {t = 1019}, -- Bronze Framework
        [3955] = {t = 1019}, -- Explosive Sheep
        [3956] = {t = 1019}, -- Green Tinted Goggles
        [3958] = {t = 1019}, -- Iron Strut
        [3961] = {t = 1019}, -- Gyrochronatom
        [3962] = {t = 1019}, -- Iron Grenade
        [3963] = {t = 1019}, -- Compact Harvest Reaper Kit
        [3965] = {t = 1019}, -- Advanced Target Dummy
        [3967] = {t = 1019}, -- Big Iron Bomb
        [3973] = {t = 1019}, -- Silver Contact
        [3977] = {t = 1019}, -- Crude Scope
        [3978] = {t = 1019}, -- Standard Scope
        [6458] = {t = 1019}, -- Ornate Spyglass
        [6499] = {t = 1008}, -- Boiled Clams
        [6500] = {t = 1008}, -- Goblin Deviled Clams
        [6517] = {t = 1013}, -- Pearl-handled Dagger
        [6521] = {t = 1006}, -- Pearl-clasped Cloak
        [6661] = {t = 1004}, -- Barbaric Harness
        [6690] = {t = 1006}, -- Lesser Wizard's Robe
        [7126] = {t = 1002, a = true}, -- Handstitched Leather Vest
        [7135] = {t = 1004}, -- Dark Leather Pants
        [7147] = {t = 1004}, -- Guardian Pants
        [7151] = {t = 1004}, -- Barbaric Shoulders
        [7156] = {t = 1004}, -- Guardian Gloves
        [7179] = {t = 1005}, -- Elixir of Water Breathing
        [7181] = {t = 1005}, -- Greater Healing Potion
        [7183] = {t = 1005, a = true}, -- Elixir of Minor Defense
        [7223] = {t = 1013}, -- Golden Scale Bracers
        [7408] = {t = 1013}, -- Heavy Copper Maul
        [7418] = {t = 1020, a = true}, -- Enchant Bracer - Minor Health
        [7420] = {t = 1020}, -- Enchant Chest - Minor Health
        [7421] = {t = 1020, a = true}, -- Runed Copper Rod
        [7426] = {t = 1020}, -- Enchant Chest - Minor Absorption
        [7428] = {t = 1021, a = true}, -- Enchant Bracer - Minor Deflection
        [7430] = {t = 1019}, -- Arclight Spanner
        [7454] = {t = 1020}, -- Enchant Cloak - Minor Resistance
        [7457] = {t = 1020}, -- Enchant Bracer - Minor Stamina
        [7623] = {t = 1006}, -- Brown Linen Robe
        [7624] = {t = 1006}, -- White Linen Robe
        [7745] = {t = 1020}, -- Enchant 2H Weapon - Minor Impact
        [7748] = {t = 1020}, -- Enchant Chest - Lesser Health
        [7771] = {t = 1020}, -- Enchant Cloak - Minor Protection
        [7779] = {t = 1020}, -- Enchant Bracer - Minor Agility
        [7788] = {t = 1020}, -- Enchant Weapon - Minor Striking
        [7795] = {t = 1020}, -- Runed Silver Rod
        [7817] = {t = 1013}, -- Rough Bronze Boots
        [7818] = {t = 1013}, -- Silver Rod
        [7836] = {t = 1005}, -- Blackmouth Oil
        [7837] = {t = 1005}, -- Fire Oil
        [7841] = {t = 1005}, -- Swim Speed Potion
        [7845] = {t = 1005}, -- Elixir of Firepower
        [7857] = {t = 1020}, -- Enchant Chest - Health
        [7861] = {t = 1020}, -- Enchant Cloak - Lesser Fire Resistance
        [7863] = {t = 1020}, -- Enchant Boots - Minor Stamina
        [7928] = {t = 1014, a = true}, -- Silk Bandage
        [7929] = {t = 1007, a = true}, -- Heavy Silk Bandage
        [7934] = {t = 1014, a = true}, -- Anti-Venom
        [8334] = {t = 1019}, -- Practice Lock
        [8465] = {t = 1006}, -- Simple Dress
        [8467] = {t = 1006}, -- White Woolen Dress
        [8483] = {t = 1006}, -- White Swashbuckler's Shirt
        [8489] = {t = 1006}, -- Red Swashbuckler's Shirt
        [8604] = {t = 1001, a = true}, -- Herb Baked Egg
        [8758] = {t = 1006}, -- Azure Silk Pants
        [8760] = {t = 1006}, -- Azure Silk Hood
        [8762] = {t = 1006}, -- Silk Headband
        [8764] = {t = 1006}, -- Earthen Vest
        [8766] = {t = 1006}, -- Azure Silk Belt
        [8768] = {t = 1013}, -- Iron Buckle
        [8770] = {t = 1006}, -- Robe of Power
        [8772] = {t = 1006}, -- Crimson Silk Belt
        [8774] = {t = 1006}, -- Green Silken Shoulders
        [8776] = {t = 1006}, -- Linen Belt
        [8791] = {t = 1006}, -- Crimson Silk Vest
        [8799] = {t = 1006}, -- Crimson Silk Pantaloons
        [8804] = {t = 1006}, -- Crimson Silk Gloves
        [8880] = {t = 1013}, -- Copper Dagger
        [9058] = {t = 1002, a = true}, -- Handstitched Leather Cloak
        [9059] = {t = 1002, a = true}, -- Handstitched Leather Bracers
        [9060] = {t = 1003}, -- Light Leather Quiver
        [9062] = {t = 1004}, -- Small Leather Ammo Pouch
        [9065] = {t = 1003}, -- Light Leather Bracers
        [9068] = {t = 1003}, -- Light Leather Pants
        [9074] = {t = 1004}, -- Nimble Leather Gloves
        [9145] = {t = 1004}, -- Fletcher's Gloves
        [9193] = {t = 1004}, -- Heavy Quiver
        [9194] = {t = 1004}, -- Heavy Leather Ammo Pouch
        [9196] = {t = 1004}, -- Dusky Leather Armor
        [9198] = {t = 1004}, -- Frost Leather Cloak
        [9201] = {t = 1004}, -- Dusky Bracers
        [9206] = {t = 1004}, -- Dusky Belt
        [9271] = {t = 1019}, -- Aquadynamic Fish Attractor
        [9916] = {t = 1013}, -- Steel Breastplate
        [9918] = {t = 1013}, -- Solid Sharpening Stone
        [9920] = {t = 1013}, -- Solid Grinding Stone
        [9921] = {t = 1013}, -- Solid Weightstone
        [9926] = {t = 1013}, -- Heavy Mithril Shoulder
        [9928] = {t = 1013}, -- Heavy Mithril Gauntlet
        [9931] = {t = 1013}, -- Mithril Scale Pants
        [9935] = {t = 1013}, -- Steel Plate Helm
        [9954] = {t = 1022}, -- Truesilver Gauntlets
        [9959] = {t = 1013}, -- Heavy Mithril Breastplate
        [9961] = {t = 1013}, -- Mithril Coif
        [9968] = {t = 1013}, -- Heavy Mithril Boots
        [9974] = {t = 1022}, -- Truesilver Breastplate
        [9983] = {t = 1013}, -- Copper Claymore
        [9985] = {t = 1013}, -- Bronze Warhammer
        [9986] = {t = 1013}, -- Bronze Greatsword
        [9987] = {t = 1013}, -- Bronze Battle Axe
        [9993] = {t = 1013}, -- Heavy Mithril Axe
        [10001] = {t = 1013}, -- Big Black Mace
        [10003] = {t = 1023}, -- The Shatterer
        [10007] = {t = 1023}, -- Phantom Blade
        [10011] = {t = 1023}, -- Blight
        [10015] = {t = 1023}, -- Truesilver Champion
        [10097] = {t = 1011}, -- Smelt Mithril
        [10098] = {t = 1011}, -- Smelt Truesilver
        [10482] = {t = 1004}, -- Cured Thick Hide
        [10487] = {t = 1004}, -- Thick Armor Kit
        [10499] = {t = 1004}, -- Nightscape Tunic
        [10507] = {t = 1004}, -- Nightscape Headband
        [10511] = {t = 1024}, -- Turtle Scale Breastplate
        [10518] = {t = 1024}, -- Turtle Scale Bracers
        [10548] = {t = 1024}, -- Nightscape Pants
        [10552] = {t = 1024}, -- Turtle Scale Helm
        [10556] = {t = 1024}, -- Turtle Scale Leggings
        [10558] = {t = 1024}, -- Nightscape Boots
        [10619] = {t = 1025}, -- Dragonscale Gauntlets
        [10621] = {t = 1026}, -- Wolfshead Helm
        [10630] = {t = 1027}, -- Gauntlets of the Sea
        [10632] = {t = 1027}, -- Helm of Fire
        [10647] = {t = 1026}, -- Feathered Breastplate
        [10650] = {t = 1025}, -- Dragonscale Breastplate
        [10840] = {t = 1007, a = true}, -- Mageweave Bandage
        [10841] = {t = 1014, a = true}, -- Heavy Mageweave Bandage
        [11448] = {t = 1005}, -- Greater Mana Potion
        [11449] = {t = 1005}, -- Elixir of Agility
        [11450] = {t = 1005}, -- Elixir of Greater Defense
        [11451] = {t = 1005}, -- Oil of Immolation
        [11456] = {t = 1028}, -- Goblin Rocket Fuel
        [11457] = {t = 1005}, -- Superior Healing Potion
        [11459] = {t = 1028}, -- Philosopher's Stone
        [11460] = {t = 1005}, -- Elixir of Detect Undead
        [11461] = {t = 1005}, -- Arcane Elixir
        [11465] = {t = 1005}, -- Elixir of Greater Intellect
        [11467] = {t = 1005}, -- Elixir of Greater Agility
        [11473] = {t = 1028}, -- Ghost Dye
        [11476] = {t = 1028}, -- Elixir of Shadow Power
        [11478] = {t = 1005}, -- Elixir of Detect Demon
        [11479] = {t = 1015}, -- Transmute: Iron to Gold
        [11480] = {t = 1015}, -- Transmute: Mithril to Truesilver
        [12044] = {t = 1017, a = true}, -- Simple Linen Pants
        [12045] = {t = 1006}, -- Simple Linen Boots
        [12046] = {t = 1006}, -- Simple Kilt
        [12048] = {t = 1006}, -- Black Mageweave Vest
        [12049] = {t = 1006}, -- Black Mageweave Leggings
        [12050] = {t = 1006}, -- Black Mageweave Robe
        [12053] = {t = 1006}, -- Black Mageweave Gloves
        [12061] = {t = 1006}, -- Orange Mageweave Shirt
        [12065] = {t = 1006}, -- Mageweave Bag
        [12067] = {t = 1006}, -- Dreamweave Gloves
        [12069] = {t = 1006}, -- Cindercloth Robe
        [12070] = {t = 1006}, -- Dreamweave Vest
        [12072] = {t = 1006}, -- Black Mageweave Headband
        [12073] = {t = 1006}, -- Black Mageweave Boots
        [12074] = {t = 1006}, -- Black Mageweave Shoulders
        [12077] = {t = 1006}, -- Simple Black Dress
        [12079] = {t = 1006}, -- Red Mageweave Bag
        [12088] = {t = 1006}, -- Cindercloth Boots
        [12092] = {t = 1006}, -- Dreamweave Circlet
        [12260] = {t = 1012, a = true}, -- Rough Copper Vest
        [12584] = {t = 1019}, -- Gold Power Core
        [12585] = {t = 1019}, -- Solid Blasting Powder
        [12586] = {t = 1019}, -- Solid Dynamite
        [12589] = {t = 1019}, -- Mithril Tube
        [12590] = {t = 1019}, -- Gyromatic Micro-Adjustor
        [12591] = {t = 1019}, -- Unstable Trigger
        [12594] = {t = 1019}, -- Fire Goggles
        [12595] = {t = 1019}, -- Mithril Blunderbuss
        [12596] = {t = 1019}, -- Hi-Impact Mithril Slugs
        [12599] = {t = 1019}, -- Mithril Casing
        [12603] = {t = 1019}, -- Mithril Frag Bomb
        [12609] = {t = 1005}, -- Catseye Elixir
        [12615] = {t = 1019}, -- Spellpower Goggles Xtreme
        [12618] = {t = 1019}, -- Rose Colored Goggles
        [12619] = {t = 1019}, -- Hi-Explosive Bomb
        [12621] = {t = 1019}, -- Mithril Gyro-Shot
        [12622] = {t = 1019}, -- Green Lens
        [12895] = {t = 1029}, -- Inlaid Mithril Cylinder Plans
        [13378] = {t = 1020}, -- Enchant Shield - Minor Stamina
        [13421] = {t = 1020}, -- Enchant Cloak - Lesser Protection
        [13485] = {t = 1020}, -- Enchant Shield - Lesser Spirit
        [13501] = {t = 1020}, -- Enchant Bracer - Lesser Stamina
        [13503] = {t = 1020}, -- Enchant Weapon - Lesser Striking
        [13529] = {t = 1020}, -- Enchant 2H Weapon - Lesser Impact
        [13538] = {t = 1020}, -- Enchant Chest - Lesser Absorption
        [13607] = {t = 1020}, -- Enchant Chest - Mana
        [13622] = {t = 1020}, -- Enchant Bracer - Lesser Intellect
        [13626] = {t = 1020}, -- Enchant Chest - Minor Stats
        [13628] = {t = 1020}, -- Runed Golden Rod
        [13631] = {t = 1020}, -- Enchant Shield - Lesser Stamina
        [13635] = {t = 1020}, -- Enchant Cloak - Defense
        [13637] = {t = 1020}, -- Enchant Boots - Lesser Agility
        [13640] = {t = 1020}, -- Enchant Chest - Greater Health
        [13642] = {t = 1020}, -- Enchant Bracer - Spirit
        [13644] = {t = 1020}, -- Enchant Boots - Lesser Stamina
        [13648] = {t = 1020}, -- Enchant Bracer - Stamina
        [13657] = {t = 1020}, -- Enchant Cloak - Fire Resistance
        [13659] = {t = 1020}, -- Enchant Shield - Spirit
        [13661] = {t = 1020}, -- Enchant Bracer - Strength
        [13663] = {t = 1020}, -- Enchant Chest - Greater Mana
        [13693] = {t = 1020}, -- Enchant Weapon - Striking
        [13695] = {t = 1020}, -- Enchant 2H Weapon - Impact
        [13700] = {t = 1020}, -- Enchant Chest - Lesser Stats
        [13702] = {t = 1020}, -- Runed Truesilver Rod
        [13746] = {t = 1020}, -- Enchant Cloak - Greater Defense
        [13794] = {t = 1020}, -- Enchant Cloak - Resistance
        [13815] = {t = 1020}, -- Enchant Gloves - Agility
        [13822] = {t = 1020}, -- Enchant Bracer - Intellect
        [13836] = {t = 1020}, -- Enchant Boots - Stamina
        [13858] = {t = 1020}, -- Enchant Chest - Superior Health
        [13887] = {t = 1020}, -- Enchant Gloves - Strength
        [13890] = {t = 1020}, -- Enchant Boots - Minor Speed
        [13905] = {t = 1020}, -- Enchant Shield - Greater Spirit
        [13917] = {t = 1020}, -- Enchant Chest - Superior Mana
        [13935] = {t = 1020}, -- Enchant Boots - Agility
        [13937] = {t = 1020}, -- Enchant 2H Weapon - Greater Impact
        [13939] = {t = 1020}, -- Enchant Bracer - Greater Strength
        [13941] = {t = 1020}, -- Enchant Chest - Stats
        [13943] = {t = 1020}, -- Enchant Weapon - Greater Striking
        [13948] = {t = 1020}, -- Enchant Gloves - Minor Haste
        [14293] = {t = 1020}, -- Lesser Magic Wand
        [14379] = {t = 1013}, -- Golden Rod
        [14380] = {t = 1013}, -- Truesilver Rod
        [14807] = {t = 1020}, -- Greater Magic Wand
        [14809] = {t = 1020}, -- Lesser Mystic Wand
        [14810] = {t = 1020}, -- Greater Mystic Wand
        [14930] = {t = 1024}, -- Quickdraw Quiver
        [14932] = {t = 1024}, -- Thick Leather Ammo Pouch
        [15255] = {t = 1019}, -- Mechanical Repair Kit
        [15833] = {t = 1005}, -- Dreamless Sleep Potion
        [15853] = {t = 1009}, -- Lean Wolf Steak
        [15856] = {t = 1009}, -- Hot Wolf Ribs
        [15972] = {t = 1013}, -- Glinting Steel Dagger
        [16153] = {t = 1011}, -- Smelt Thorium
        [16639] = {t = 1013}, -- Dense Grinding Stone
        [16640] = {t = 1013}, -- Dense Weightstone
        [16641] = {t = 1013}, -- Dense Sharpening Stone
        [17180] = {t = 1020}, -- Enchanted Thorium
        [17181] = {t = 1020}, -- Enchanted Leather
        [17551] = {t = 1005}, -- Stonescale Oil
        [17552] = {t = 1005}, -- Mighty Rage Potion
        [17553] = {t = 1005}, -- Superior Mana Potion
        [17555] = {t = 1005}, -- Elixir of the Sages
        [17556] = {t = 1005}, -- Major Healing Potion
        [17557] = {t = 1005}, -- Elixir of Brute Force
        [17572] = {t = 1005}, -- Purification Potion
        [17573] = {t = 1005}, -- Greater Arcane Elixir
        [18401] = {t = 1006}, -- Bolt of Runecloth
        [18402] = {t = 1006}, -- Runecloth Belt
        [18403] = {t = 1006}, -- Frostweave Tunic
        [18406] = {t = 1006}, -- Runecloth Robe
        [18407] = {t = 1006}, -- Runecloth Tunic
        [18409] = {t = 1006}, -- Runecloth Cloak
        [18410] = {t = 1006}, -- Ghostweave Belt
        [18411] = {t = 1006}, -- Frostweave Gloves
        [18413] = {t = 1006}, -- Ghostweave Gloves
        [18414] = {t = 1006}, -- Brightcloth Robe
        [18415] = {t = 1006}, -- Brightcloth Gloves
        [18416] = {t = 1006}, -- Ghostweave Vest
        [18417] = {t = 1006}, -- Runecloth Gloves
        [18420] = {t = 1006}, -- Brightcloth Cloak
        [18421] = {t = 1006}, -- Wizardweave Leggings
        [18423] = {t = 1006}, -- Runecloth Boots
        [18424] = {t = 1006}, -- Frostweave Pants
        [18437] = {t = 1006}, -- Felcloth Boots
        [18438] = {t = 1006}, -- Runecloth Pants
        [18441] = {t = 1006}, -- Ghostweave Pants
        [18442] = {t = 1006}, -- Felcloth Hood
        [18444] = {t = 1006}, -- Runecloth Headband
        [18446] = {t = 1006}, -- Wizardweave Robe
        [18449] = {t = 1006}, -- Runecloth Shoulders
        [18450] = {t = 1006}, -- Wizardweave Turban
        [18451] = {t = 1006}, -- Felcloth Robe
        [18453] = {t = 1006}, -- Felcloth Shoulders
        [18629] = {t = 1014, a = true}, -- Runecloth Bandage
        [18630] = {t = 1014, a = true}, -- Heavy Runecloth Bandage
        [19047] = {t = 1024}, -- Cured Rugged Hide
        [19052] = {t = 1004}, -- Wicked Leather Bracers
        [19055] = {t = 1004}, -- Runic Leather Gauntlets
        [19058] = {t = 1024}, -- Rugged Armor Kit
        [19065] = {t = 1004}, -- Runic Leather Bracers
        [19071] = {t = 1004}, -- Wicked Leather Headband
        [19072] = {t = 1004}, -- Runic Leather Belt
        [19082] = {t = 1004}, -- Runic Leather Headband
        [19083] = {t = 1004}, -- Wicked Leather Pants
        [19091] = {t = 1004}, -- Runic Leather Pants
        [19092] = {t = 1004}, -- Wicked Leather Belt
        [19098] = {t = 1004}, -- Wicked Leather Armor
        [19102] = {t = 1004}, -- Runic Leather Armor
        [19103] = {t = 1004}, -- Runic Leather Shoulders
        [19567] = {t = 1019}, -- Salt Shaker
        [19666] = {t = 1013}, -- Silver Skeleton Key
        [19667] = {t = 1013}, -- Golden Skeleton Key
        [19668] = {t = 1013}, -- Truesilver Skeleton Key
        [19669] = {t = 1013}, -- Arcanite Skeleton Key
        [19788] = {t = 1019}, -- Dense Blasting Powder
        [19790] = {t = 1019}, -- Thorium Grenade
        [19791] = {t = 1019}, -- Thorium Widget
        [19792] = {t = 1019}, -- Thorium Rifle
        [19794] = {t = 1019}, -- Spellpower Goggles Xtreme Plus
        [19795] = {t = 1019}, -- Thorium Tube
        [19800] = {t = 1019}, -- Thorium Shells
        [19825] = {t = 1019}, -- Master Engineer's Goggles
        [20008] = {t = 1020}, -- Enchant Bracer - Greater Intellect
        [20012] = {t = 1020}, -- Enchant Gloves - Greater Agility
        [20013] = {t = 1020}, -- Enchant Gloves - Greater Strength
        [20014] = {t = 1020}, -- Enchant Cloak - Greater Resistance
        [20016] = {t = 1020}, -- Enchant Shield - Superior Spirit
        [20023] = {t = 1020}, -- Enchant Boots - Greater Agility
        [20028] = {t = 1020}, -- Enchant Chest - Major Mana
        [20201] = {t = 1013}, -- Arcanite Rod
        [20648] = {t = 1004}, -- Medium Leather
        [20649] = {t = 1004}, -- Heavy Leather
        [20650] = {t = 1004}, -- Thick Leather
        [21175] = {t = 1008}, -- Spider Sausage
        [22331] = {t = 1004}, -- Rugged Leather
        [22480] = {t = 1009}, -- Tender Wolf Steak
        [22808] = {t = 1005}, -- Elixir of Greater Water Breathing
        [22815] = {t = 1030}, -- Gordok Ogre Suit
        [23070] = {t = 1019}, -- Dense Dynamite
        [23071] = {t = 1019}, -- Truesilver Transformer
        [25255] = {t = 1031, a = true}, -- Delicate Copper Wire
        [25278] = {t = 1032}, -- Bronze Setting
        [25280] = {t = 1032}, -- Elegant Silver Ring
        [25283] = {t = 1032}, -- Inlaid Malachite Ring
        [25284] = {t = 1033}, -- Simple Pearl Ring
        [25287] = {t = 1033}, -- Gloom Band
        [25305] = {t = 1034}, -- Heavy Silver Ring
        [25317] = {t = 1034}, -- Ring of Silver Might
        [25318] = {t = 1034}, -- Ring of Twilight Shadows
        [25321] = {t = 1034}, -- Moonsoul Crown
        [25490] = {t = 1032}, -- Solid Bronze Ring
        [25493] = {t = 1031, a = true}, -- Braided Copper Ring
        [25498] = {t = 1034}, -- Barbaric Iron Collar
        [25613] = {t = 1035}, -- Golden Dragon Ring
        [25615] = {t = 1036}, -- Mithril Filigree
        [25620] = {t = 1036}, -- Engraved Truesilver Ring
        [25621] = {t = 1036}, -- Citrine Ring of Rapid Healing
        [26745] = {t = 1037}, -- Bolt of Netherweave
        [26746] = {t = 1037}, -- Netherweave Bag
        [26764] = {t = 1037}, -- Netherweave Bracers
        [26765] = {t = 1037}, -- Netherweave Belt
        [26770] = {t = 1037}, -- Netherweave Gloves
        [26771] = {t = 1037}, -- Netherweave Pants
        [26772] = {t = 1037}, -- Netherweave Boots
        [26872] = {t = 1036}, -- Figurine - Jade Owl
        [26874] = {t = 1038}, -- Aquamarine Signet
        [26876] = {t = 1038}, -- Aquamarine Pendant of the Warrior
        [26880] = {t = 1038}, -- Thorium Setting
        [26883] = {t = 1038}, -- Ruby Pendant of Fire
        [26885] = {t = 1038}, -- Truesilver Healing Ring
        [26902] = {t = 1038}, -- Simple Opal Ring
        [26903] = {t = 1038}, -- Sapphire Signet
        [26907] = {t = 1038}, -- Onslaught Ring
        [26908] = {t = 1038}, -- Sapphire Pendant of Winter Night
        [26911] = {t = 1038}, -- Living Emerald Pendant
        [26916] = {t = 1039}, -- Band of Natural Fire
        [26925] = {t = 1031, a = true}, -- Woven Copper Ring
        [26926] = {t = 1032}, -- Heavy Copper Ring
        [26927] = {t = 1032}, -- Thick Bronze Necklace
        [26928] = {t = 1032}, -- Ornate Tigerseye Necklace
        [27899] = {t = 1040}, -- Enchant Bracer - Brawn
        [27905] = {t = 1040}, -- Enchant Bracer - Stats
        [27944] = {t = 1040}, -- Enchant Shield - Tough Shield
        [27957] = {t = 1040}, -- Enchant Chest - Exceptional Health
        [27958] = {u = true}, -- Enchant Chest - Exceptional Mana
        [27961] = {t = 1040}, -- Enchant Cloak - Major Armor
        [28027] = {t = 1041}, -- Prismatic Sphere
        [28028] = {t = 1041}, -- Void Sphere
        [28544] = {t = 1042}, -- Elixir of Major Strength
        [28545] = {t = 1042}, -- Elixir of Healing Power
        [28551] = {t = 1042}, -- Super Healing Potion
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
        [29356] = {t = 1043}, -- Smelt Fel Iron
        [29358] = {t = 1043}, -- Smelt Adamantite
        [29359] = {t = 1043}, -- Smelt Eternium
        [29360] = {t = 1043}, -- Smelt Felsteel
        [29361] = {t = 1043}, -- Smelt Khorium
        [29545] = {t = 1044}, -- Fel Iron Plate Gloves
        [29547] = {t = 1044}, -- Fel Iron Plate Belt
        [29548] = {t = 1044}, -- Fel Iron Plate Boots
        [29549] = {t = 1044}, -- Fel Iron Plate Pants
        [29550] = {t = 1044}, -- Fel Iron Breastplate
        [29551] = {t = 1044}, -- Fel Iron Chain Coif
        [29552] = {t = 1044}, -- Fel Iron Chain Gloves
        [29553] = {t = 1044}, -- Fel Iron Chain Bracers
        [29556] = {t = 1044}, -- Fel Iron Chain Tunic
        [29557] = {t = 1044}, -- Fel Iron Hatchet
        [29558] = {t = 1044}, -- Fel Iron Hammer
        [29565] = {t = 1044}, -- Fel Iron Greatsword
        [29654] = {t = 1044}, -- Fel Sharpening Stone
        [29686] = {t = 1043}, -- Smelt Hardened Adamantite
        [30303] = {t = 1045}, -- Elemental Blasting Powder
        [30304] = {t = 1045}, -- Fel Iron Casing
        [30305] = {t = 1045}, -- Handful of Fel Iron Bolts
        [30306] = {t = 1045}, -- Adamantite Frame
        [30307] = {t = 1045}, -- Hardened Adamantite Tube
        [30308] = {t = 1045}, -- Khorium Power Core
        [30309] = {t = 1045}, -- Felsteel Stabilizer
        [30310] = {t = 1045}, -- Fel Iron Bomb
        [30311] = {t = 1045}, -- Adamantite Grenade
        [30312] = {t = 1045}, -- Fel Iron Musket
        [30342] = {u = true}, -- Red Smoke Flare
        [30343] = {u = true}, -- Blue Smoke Flare
        [30346] = {t = 1045}, -- Fel Iron Shells
        [30349] = {u = true}, -- Khorium Toolbox
        [30549] = {u = true}, -- Critter Enlarger
        [30558] = {t = 1046}, -- The Bigger One
        [30560] = {t = 1046}, -- Super Sapper Charge
        [30561] = {u = true}, -- Goblin Tonk Controller
        [30563] = {t = 1046}, -- Goblin Rocket Launcher
        [30565] = {t = 1046}, -- Foreman's Enchanted Helmet
        [30566] = {t = 1046}, -- Foreman's Reinforced Helmet
        [30568] = {t = 1029}, -- Gnomish Flame Turret
        [30569] = {t = 1029}, -- Gnomish Poultryizer
        [30570] = {t = 1029}, -- Nigh-Invulnerability Belt
        [30573] = {u = true}, -- Gnomish Tonk Controller
        [30574] = {t = 1029}, -- Gnomish Power Goggles
        [30575] = {t = 1029}, -- Gnomish Battle Goggles
        [31048] = {t = 1039}, -- Fel Iron Blood Ring
        [31049] = {t = 1039}, -- Golden Draenite Ring
        [31050] = {t = 1039}, -- Azure Moonstone Ring
        [31051] = {t = 1039}, -- Thick Adamantite Necklace
        [31052] = {t = 1039}, -- Heavy Adamantite Ring
        [31460] = {t = 1047}, -- Netherweave Net
        [31461] = {u = true}, -- Heavy Netherweave Net
        [32178] = {t = 1032}, -- Malachite Pendant
        [32179] = {t = 1032}, -- Tigerseye Band
        [32259] = {t = 1031, a = true}, -- Rough Stone Statue
        [32284] = {t = 1044}, -- Lesser Rune of Warding
        [32454] = {t = 1048}, -- Knothide Leather
        [32456] = {t = 1048}, -- Knothide Armor Kit
        [32462] = {t = 1048}, -- Felscale Gloves
        [32463] = {t = 1048}, -- Felscale Boots
        [32464] = {t = 1048}, -- Felscale Pants
        [32465] = {t = 1048}, -- Felscale Breastplate
        [32466] = {t = 1048}, -- Scaled Draenic Pants
        [32467] = {t = 1048}, -- Scaled Draenic Gloves
        [32468] = {t = 1048}, -- Scaled Draenic Vest
        [32469] = {t = 1048}, -- Scaled Draenic Boots
        [32470] = {t = 1048}, -- Thick Draenic Gloves
        [32471] = {t = 1048}, -- Thick Draenic Pants
        [32472] = {t = 1048}, -- Thick Draenic Boots
        [32473] = {t = 1048}, -- Thick Draenic Vest
        [32478] = {t = 1048}, -- Wild Draenish Boots
        [32479] = {t = 1048}, -- Wild Draenish Gloves
        [32480] = {t = 1048}, -- Wild Draenish Leggings
        [32481] = {t = 1048}, -- Wild Draenish Vest
        [32655] = {t = 1044}, -- Fel Iron Rod
        [32664] = {t = 1041}, -- Runed Fel Iron Rod
        [32801] = {t = 1032}, -- Coarse Stone Statue
        [32807] = {t = 1034}, -- Heavy Stone Statue
        [32808] = {t = 1036}, -- Solid Stone Statue
        [32809] = {t = 1038}, -- Dense Stone Statue
        [32810] = {u = true}, -- Primal Stone Statue
        [33732] = {t = 1042}, -- Volatile Healing Potion
        [33733] = {t = 1042}, -- Unstable Mana Potion
        [33738] = {t = 1042}, -- Onslaught Elixir
        [33740] = {t = 1042}, -- Adept's Elixir
        [33741] = {t = 1042}, -- Elixir of Mastery
        [33990] = {t = 1040}, -- Enchant Chest - Major Spirit
        [33991] = {t = 1040}, -- Enchant Chest - Restore Mana Prime
        [33993] = {t = 1040}, -- Enchant Gloves - Blasting
        [33995] = {t = 1040}, -- Enchant Gloves - Major Strength
        [33996] = {t = 1040}, -- Enchant Gloves - Assault
        [34001] = {t = 1040}, -- Enchant Bracer - Major Intellect
        [34002] = {t = 1040}, -- Enchant Bracer - Assault
        [34004] = {t = 1040}, -- Enchant Cloak - Greater Agility
        [34529] = {t = 1022}, -- Nether Chain Shirt
        [34530] = {t = 1022}, -- Twisting Nether Chain Shirt
        [34533] = {t = 1022}, -- Breastplate of Kings
        [34534] = {t = 1022}, -- Bulwark of Kings
        [34535] = {t = 1023}, -- Fireguard
        [34537] = {t = 1023}, -- Blazeguard
        [34538] = {t = 1023}, -- Lionheart Blade
        [34540] = {t = 1023}, -- Lionheart Champion
        [34541] = {t = 1023}, -- The Planar Edge
        [34542] = {t = 1023}, -- Black Planar Edge
        [34543] = {t = 1023}, -- Lunar Crescent
        [34544] = {t = 1023}, -- Mooncleaver
        [34545] = {t = 1023}, -- Drakefist Hammer
        [34546] = {t = 1023}, -- Dragonmaw
        [34547] = {t = 1023}, -- Thunder
        [34548] = {t = 1023}, -- Deep Thunder
        [34607] = {t = 1044}, -- Fel Weightstone
        [34955] = {t = 1036}, -- Golden Ring of Power
        [34959] = {t = 1036}, -- Truesilver Commander's Ring
        [34960] = {t = 1038}, -- Glowing Thorium Band
        [34961] = {t = 1038}, -- Emerald Lion Ring
        [34979] = {t = 1049}, -- Thick Bronze Darts
        [34981] = {t = 1050}, -- Whirling Steel Axes
        [34982] = {t = 1050}, -- Enchanted Thorium Blades
        [34983] = {t = 1044}, -- Felsteel Whisper Knives
        [35540] = {t = 1048}, -- Drums of War
        [35575] = {t = 1051}, -- Ebon Netherscale Breastplate
        [35576] = {t = 1051}, -- Ebon Netherscale Belt
        [35577] = {t = 1051}, -- Ebon Netherscale Bracers
        [35580] = {t = 1051}, -- Netherstrike Breastplate
        [35582] = {t = 1051}, -- Netherstrike Belt
        [35584] = {t = 1051}, -- Netherstrike Bracers
        [35585] = {t = 1052}, -- Windhawk Hauberk
        [35587] = {t = 1052}, -- Windhawk Belt
        [35588] = {t = 1052}, -- Windhawk Bracers
        [35589] = {t = 1053}, -- Primalstrike Vest
        [35590] = {t = 1053}, -- Primalstrike Belt
        [35591] = {t = 1053}, -- Primalstrike Bracers
        [35750] = {t = 1043}, -- Earth Shatter
        [35751] = {t = 1043}, -- Fire Sunder
        [36074] = {t = 1053}, -- Blackstorm Leggings
        [36075] = {t = 1052}, -- Wildfeather Leggings
        [36076] = {t = 1051}, -- Dragonstrike Leggings
        [36077] = {t = 1053}, -- Primalstorm Breastplate
        [36078] = {t = 1052}, -- Living Crystal Breastplate
        [36079] = {t = 1051}, -- Golden Dragonstrike Breastplate
        [36122] = {t = 1022}, -- Earthforged Leggings
        [36124] = {t = 1022}, -- Windforged Leggings
        [36125] = {t = 1023}, -- Light Earthforged Blade
        [36126] = {t = 1023}, -- Light Skyforged Axe
        [36128] = {t = 1023}, -- Light Emberforged Hammer
        [36129] = {t = 1022}, -- Heavy Earthforged Breastplate
        [36130] = {t = 1022}, -- Stormforged Hauberk
        [36131] = {t = 1023}, -- Windforged Rapier
        [36133] = {t = 1023}, -- Stoneforged Claymore
        [36134] = {t = 1023}, -- Stormforged Axe
        [36135] = {t = 1023}, -- Skyforged Great Axe
        [36136] = {t = 1023}, -- Lavaforged Warhammer
        [36137] = {t = 1023}, -- Great Earthforged Hammer
        [36256] = {t = 1022}, -- Embrace of the Twisting Nether
        [36257] = {t = 1022}, -- Bulwark of the Ancient Kings
        [36258] = {t = 1023}, -- Blazefury
        [36259] = {t = 1023}, -- Lionheart Executioner
        [36260] = {t = 1023}, -- Wicked Edge of the Planes
        [36261] = {t = 1023}, -- Bloodmoon
        [36262] = {t = 1023}, -- Dragonstrike
        [36263] = {t = 1023}, -- Stormherald
        [36523] = {t = 1034}, -- Brilliant Necklace
        [36524] = {t = 1034}, -- Heavy Jade Ring
        [36525] = {t = 1038}, -- Red Ring of Destruction
        [36526] = {t = 1038}, -- Diamond Focus Ring
        [36665] = {u = true}, -- Netherflame Robe
        [36667] = {u = true}, -- Netherflame Belt
        [36668] = {u = true}, -- Netherflame Boots
        [36669] = {u = true}, -- Lifeblood Leggings
        [36670] = {u = true}, -- Lifeblood Belt
        [36672] = {u = true}, -- Lifeblood Bracers
        [36954] = {t = 1054}, -- Dimensional Ripper - Area 52
        [36955] = {t = 1055}, -- Ultrasafe Transporter - Toshley's Station
        [37818] = {t = 1034}, -- Bronze Band of Force
        [37836] = {t = 1008}, -- Spice Bread
        [38068] = {t = 1039}, -- Mercurial Adamantite
        [38070] = {t = 1042}, -- Mercurial Stone
        [38175] = {t = 1034}, -- Bronze Torc
        [39636] = {t = 1042}, -- Elixir of Major Fortitude
        [39638] = {t = 1042}, -- Elixir of Draenic Wisdom
        [39971] = {t = 1045}, -- Icy Blasting Primers
        [39973] = {t = 1045}, -- Frost Grenades
        [40274] = {t = 1045}, -- Furious Gizmatic Goggles
        [40514] = {t = 1056}, -- Necklace of the Deep
        [41307] = {t = 1045}, -- Gyro-balanced Khorium Destroyer
        [41311] = {t = 1045}, -- Justicebringer 2000 Specs
        [41312] = {t = 1045}, -- Tankatronic Goggles
        [41314] = {t = 1045}, -- Surestrike Goggles v2.0
        [41315] = {t = 1057}, -- Gadgetstorm Goggles
        [41316] = {t = 1057}, -- Living Replicator Specs
        [41317] = {t = 1045}, -- Deathblow X11 Goggles
        [41318] = {t = 1058}, -- Wonderheal XT40 Shades
        [41319] = {t = 1058}, -- Magnified Moon Specs
        [41320] = {t = 1045}, -- Destruction Holo-gogs
        [41321] = {t = 1059}, -- Powerheal 4000 Lens
        [41414] = {t = 1056}, -- Brilliant Pearl Band
        [41415] = {t = 1056}, -- The Black Pearl
        [41418] = {t = 1056}, -- Crown of the Sea Witch
        [41420] = {t = 1056}, -- Purified Jaggal Pearl
        [41429] = {t = 1056}, -- Purified Shadow Pearl
        [41458] = {d = {28575}}, -- Cauldron of Major Arcane Protection
        [41500] = {d = {28571}}, -- Cauldron of Major Fire Protection
        [41501] = {d = {28572}}, -- Cauldron of Major Frost Protection
        [41502] = {d = {28573}}, -- Cauldron of Major Nature Protection
        [41503] = {d = {28576}}, -- Cauldron of Major Shadow Protection
        [42296] = {t = 1060}, -- Stewed Trout
        [42302] = {t = 1060}, -- Fisherman's Feast
        [42305] = {t = 1060}, -- Hot Buttered Trout
        [42613] = {t = 1041}, -- Nexus Transformation
        [42615] = {t = 1041}, -- Small Prismatic Shard
        [44155] = {t = 1061}, -- Flying Machine
        [44157] = {t = 1061}, -- Turbo-Charged Flying Machine
        [44343] = {t = 1048}, -- Knothide Ammo Pouch
        [44344] = {t = 1048}, -- Knothide Quiver
        [44383] = {t = 1040}, -- Enchant Shield - Resilience
        [44770] = {t = 1048}, -- Glove Reinforcements
        [44970] = {t = 1048}, -- Heavy Knothide Armor Kit
        [45061] = {t = 1042}, -- Mad Alchemist's Potion
        [45100] = {t = 1048}, -- Leatherworker's Satchel
        [47280] = {t = 1056}, -- Brilliant Glass
        [351766] = {u = true}, -- Greater Drums of War
    },
};

_G.professionMaster:CreateModel("skill-sources-bcc", bccSkillSources);
