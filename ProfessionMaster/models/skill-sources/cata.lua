--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Skill sources for cata: trainer groups, trainer npcs (zone, side) and per skill sources
-- Format: skills[spellId] = {t = groupId, q = {{questId, giverId, zoneId, side, flags, giverType}}, d = {researchSpellId}, a = true (learned with the profession), u = true (not available)}
-- flags: 1 daily, 2 weekly, 4 repeatable; giverType: nil npc, "o" object, "i" item
local cataSkillSources = {
    groups = {
        [3001] = {1355, 1382, 1430, 1699, 2818, 3026, 3067, 3087, 3399, 3966, 4210, 4552, 4894, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 18987, 18988, 18993, 19185, 19186, 19369, 26905, 26953, 26972, 26989, 28705, 29631, 33587, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786, 42288, 42506, 45550, 46709, 47405, 49789, 50567, 54232},
        [3002] = {1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 7866, 7867, 7868, 7869, 7870, 7871, 8153, 11097, 11098, 16278, 16688, 16728, 17442, 18754, 18771, 19187, 21087, 26911, 26961, 26996, 26998, 28400, 28700, 29507, 29508, 29509, 33581, 33635, 33681, 53436},
        [3003] = {1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 12020, 16161, 16487, 16588, 16642, 16723, 17215, 18802, 19052, 26903, 26951, 26975, 26987, 27023, 27029, 28703, 33588, 33630, 33674},
        [3004] = {1215, 1470, 2132, 2391, 2837, 3184, 3347, 3603, 4160, 4900, 5177, 5499, 7948, 16161, 16642, 16723, 28703},
        [3005] = {1103, 1346, 2399, 2627, 3363, 3484, 3523, 3704, 4159, 4576, 9584, 11052, 11557, 16366, 16640, 16729, 17487, 18749, 44783, 45559},
        [3006] = {996, 1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 4578, 5153, 9584, 11052, 16366, 16640, 16729, 17487, 18749, 18772, 26914, 26964, 26969, 27001, 28699, 33580, 33636, 33684, 43428, 44783, 45559},
        [3007] = {1355, 1382, 1430, 1699, 2818, 3067, 3087, 3399, 4210, 4552, 4894, 5159, 5482, 6286, 10296, 10299, 16253, 16277, 16676, 16719, 17246, 19186, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786, 42288, 42506, 45550, 45563, 46709, 47405, 50567, 54232},
        [3008] = {1384, 1681, 1701, 3001, 3137, 3175, 3357, 3555, 4254, 4598, 5392, 5513, 6297, 8128, 12035, 16663, 16752, 17488, 18747, 18779, 26912, 26962, 26976, 26999, 28698, 33640, 33682, 43431, 46357, 52170, 52642, 53409},
        [3009] = {5513},
        [3010] = {514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 4888, 5164, 5511, 6299, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16265, 16583, 16669, 16724, 16823, 17245, 19341, 20124, 20125, 21209, 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29505, 29506, 29924, 33591, 33631, 33675, 37072, 43429, 44781, 45548, 52640, 55684},
        [3011] = {514, 1241, 2836, 3136, 3355, 3478, 3557, 4258, 4596, 4888, 5164, 5511, 7230, 7231, 7232, 11146, 11177, 11178, 15400, 16669, 16724, 17245, 37072, 44781, 45548, 55684},
        [3012] = {56796},
        [3013] = {1676, 1702, 3290, 3494, 4941, 5174, 5518, 7406, 7944, 8126, 8736, 8738, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 17637, 18752, 18775, 19576, 24868, 25099, 25277, 26907, 26955, 26991, 28697, 29513, 29514, 33586, 33634, 33677, 45545, 52636, 52651},
        [3014] = {1676, 1702, 3290, 4941, 5174, 5518, 8736, 11017, 11025, 11031, 11037, 16667, 16726, 17222, 17634, 45545, 52636, 52651},
        [3015] = {1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16190, 16633, 16725, 18753, 18773, 19251, 19252, 19540, 26906, 26954, 26980, 26990, 28693, 33583, 33633, 33676, 48685, 53410},
        [3016] = {1317},
        [3017] = {5388, 15501, 16702, 16744, 18751, 18774, 19063, 19539, 19774, 19775, 19777, 19778, 26915, 26960, 26982, 26997, 28701, 33590, 33637, 33680, 44582, 46675, 52586, 52587, 52645, 52657},
        [3018] = {44582},
        [3019] = {26916, 26959, 26977, 26995, 28702, 30706, 30709, 30710, 30711, 30713, 30715, 30716, 30717, 30721, 30722, 33603, 33638, 33679, 46716, 53415},
        [3020] = {30713},
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
        [2391] = {267, "H"}, -- Serge Hinott
        [2399] = {267, "H"}, -- Daryl Stack
        [2627] = {5287}, -- Grarnik Goodstitch
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
        [4212] = {1657, "A"}, -- Telonis
        [4213] = {1657, "A"}, -- Taladan
        [4254] = {1537, "A"}, -- Geofram Bouldertoe
        [4258] = {1537, "A"}, -- Bengus Deepforge
        [4552] = {1497, "H"}, -- Eunice Burch
        [4576] = {1497, "H"}, -- Josef Gregorian
        [4578] = {1497, "H"}, -- Josephine Lister
        [4588] = {1497, "H"}, -- Arthur Moore
        [4596] = {1497, "H"}, -- James Van Brunt
        [4598] = {1497, "H"}, -- Brom Killian
        [4611] = {1497, "H"}, -- Doctor Herbert Halsey
        [4616] = {1497, "H"}, -- Lavinia Crowe
        [4888] = {15, "A"}, -- Marie Holdston
        [4894] = {15, "A"}, -- Craig Nollward
        [4900] = {15, "A"}, -- Alchemist Narett
        [4941] = {15, "A"}, -- Caz Twosprocket
        [5127] = {1537, "A"}, -- Fimble Finespindle
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
        [5784] = {nil, "H"}, -- Waldor
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
        [10296] = {}, -- Acride
        [10299] = {1583}, -- Acride
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
        [11557] = {361}, -- Meilosh
        [12020] = {}, -- Moonglade Alchemy Trainer
        [12035] = {}, -- Aerie Peak Mining Trainer
        [15400] = {3430, "H"}, -- Arathel Sunforge
        [15501] = {3430, "H"}, -- Aleinia
        [16160] = {3430, "H"}, -- Magistrix Eredania
        [16161] = {3430, "H"}, -- Arcanist Sheynathren
        [16190] = {}, -- Expansion Enchanting Trainer
        [16253] = {3433, "H"}, -- Master Chef Mouldier
        [16265] = {}, -- Smith Daelarin
        [16277] = {3430, "H"}, -- Quarelestra
        [16278] = {3430, "H"}, -- Sathein
        [16366] = {3430, "H"}, -- Sempstress Ambershine
        [16487] = {}, -- Master Alchemist
        [16583] = {3483, "H"}, -- Rohok
        [16588] = {3483, "H"}, -- Apothecary Antonivich
        [16633] = {3487, "H"}, -- Sedana
        [16640] = {3487, "H"}, -- Keelen Sheets
        [16642] = {3487, "H"}, -- Camberon
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
        [16744] = {nil, "A"}, -- Driaan
        [16752] = {3557, "A"}, -- Muaat
        [16823] = {3483, "A"}, -- Humphry
        [17215] = {3524, "A"}, -- Daedal
        [17222] = {3524, "A"}, -- Artificer Daelo
        [17245] = {3524, "A"}, -- Blacksmith Calypso
        [17246] = {3524, "A"}, -- "Cookie" McWeaksauce
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
        [18993] = {3521}, -- Naka
        [19052] = {3703}, -- Lorokeem
        [19063] = {3703}, -- Hamanar
        [19185] = {3703}, -- Jack Trapper
        [19186] = {3703}, -- Kylene
        [19187] = {3703}, -- Darmari
        [19251] = {3703}, -- Enchantress Volali
        [19252] = {3703}, -- High Enchanter Bardolan
        [19341] = {3520, "H"}, -- Grutah
        [19369] = {3520, "A"}, -- Celie Steelwing
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
        [37072] = {1637, "H"}, -- Rogg
        [42288] = {1519, "A"}, -- Robby Flay
        [42506] = {1637, "H"}, -- Marogg
        [43428] = {148, "A"}, -- Faeyrin Willowmoon
        [43429] = {148, "A"}, -- Taryel Firestrike
        [43431] = {148, "A"}, -- Periale
        [44582] = {1519, "A"}, -- Theresa Denman
        [44781] = {1637, "H"}, -- Opuno Ironhorn
        [44783] = {1637, "H"}, -- Hiwahi Three-Feathers
        [45545] = {1637, "H"}, -- "Jack" Pisarek Slamfix
        [45548] = {1637, "H"}, -- Kark Helmbreaker
        [45550] = {1637, "H"}, -- Zarbo Porkpatty
        [45559] = {1637, "H"}, -- Nivi Weavewell
        [45563] = {1637, "H"}, -- Tinza Silvermug
        [46357] = {1637, "H"}, -- Gonto
        [46675] = {1637, "H"}, -- Lugrah
        [46709] = {1637, "H"}, -- Arugi
        [46716] = {1637, "H"}, -- Nerog
        [47405] = {85, "H"}, -- The Chef
        [48685] = {}, -- Cataclysm Shard Vendor
        [49789] = {3483, "H"}, -- Allison
        [50567] = {4714, "A"}, -- Fielding Chesterhill
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
        [55684] = {1519, "A"}, -- Jordan Smith
        [56796] = {1519, "A"}, -- Angela Leifeld
    },
    skills = {
        [818] = {t = 3001, a = true}, -- Cooking Fire
        [2149] = {t = 3002, a = true}, -- Handstitched Leather Boots
        [2152] = {t = 3002, a = true}, -- Light Armor Kit
        [2153] = {t = 3002}, -- Handstitched Leather Pants
        [2159] = {t = 3002}, -- Fine Leather Cloak
        [2160] = {t = 3002}, -- Embossed Leather Vest
        [2161] = {t = 3002}, -- Embossed Leather Boots
        [2162] = {t = 3002}, -- Embossed Leather Cloak
        [2165] = {t = 3002}, -- Medium Armor Kit
        [2166] = {t = 3002}, -- Toughened Leather Armor
        [2167] = {t = 3002}, -- Dark Leather Boots
        [2168] = {t = 3002}, -- Dark Leather Cloak
        [2329] = {t = 3003, a = true}, -- Elixir of Lion's Strength
        [2330] = {t = 3003, a = true}, -- Minor Healing Potion
        [2331] = {t = 3004}, -- Minor Mana Potion
        [2332] = {t = 3004}, -- Minor Rejuvenation Potion
        [2333] = {t = 3003}, -- Elixir of Lesser Agility
        [2334] = {t = 3004}, -- Elixir of Minor Fortitude
        [2337] = {t = 3004}, -- Lesser Healing Potion
        [2385] = {t = 3005}, -- Brown Linen Vest
        [2386] = {t = 3005}, -- Linen Boots
        [2387] = {t = 3006, a = true}, -- Linen Cloak
        [2392] = {t = 3005}, -- Red Linen Shirt
        [2393] = {t = 3005}, -- White Linen Shirt
        [2394] = {t = 3005}, -- Blue Linen Shirt
        [2395] = {t = 3005}, -- Barbaric Linen Vest
        [2396] = {t = 3005}, -- Green Linen Shirt
        [2397] = {t = 3005}, -- Reinforced Linen Cape
        [2399] = {t = 3005}, -- Green Woolen Vest
        [2401] = {t = 3005}, -- Woolen Boots
        [2402] = {t = 3005}, -- Woolen Cape
        [2406] = {t = 3005}, -- Gray Woolen Shirt
        [2538] = {t = 3001, a = true}, -- Charred Wolf Meat
        [2539] = {t = 3007}, -- Spiced Wolf Meat
        [2540] = {t = 3001, a = true}, -- Roasted Boar Meat
        [2541] = {t = 3007}, -- Coyote Steak
        [2544] = {t = 3007}, -- Crab Cake
        [2546] = {t = 3007}, -- Dry Pork Ribs
        [2657] = {t = 3008, a = true}, -- Smelt Copper
        [2658] = {t = 3009}, -- Smelt Silver
        [2659] = {t = 3009}, -- Smelt Bronze
        [2660] = {t = 3010, a = true}, -- Rough Sharpening Stone
        [2661] = {t = 3011}, -- Copper Chain Belt
        [2662] = {t = 3011}, -- Copper Chain Pants
        [2663] = {t = 3010, a = true}, -- Copper Bracers
        [2664] = {t = 3011}, -- Runed Copper Bracers
        [2665] = {t = 3011}, -- Coarse Sharpening Stone
        [2666] = {t = 3011}, -- Runed Copper Belt
        [2668] = {t = 3011}, -- Rough Bronze Leggings
        [2670] = {t = 3011}, -- Rough Bronze Cuirass
        [2672] = {t = 3011}, -- Patterned Bronze Bracers
        [2674] = {t = 3011}, -- Heavy Sharpening Stone
        [2675] = {t = 3011}, -- Shining Silver Breastplate
        [2737] = {t = 3011}, -- Copper Mace
        [2738] = {t = 3011}, -- Copper Axe
        [2739] = {t = 3011}, -- Copper Shortsword
        [2740] = {t = 3011}, -- Bronze Mace
        [2741] = {t = 3011}, -- Bronze Axe
        [2742] = {t = 3011}, -- Bronze Shortsword
        [2881] = {t = 3002, a = true}, -- Light Leather
        [2963] = {t = 3006, a = true}, -- Bolt of Linen Cloth
        [2964] = {t = 3005}, -- Bolt of Woolen Cloth
        [3115] = {t = 3010, a = true}, -- Rough Weightstone
        [3116] = {t = 3011}, -- Coarse Weightstone
        [3117] = {t = 3011}, -- Heavy Weightstone
        [3170] = {t = 3004}, -- Weak Troll's Blood Elixir
        [3171] = {t = 3004}, -- Elixir of Wisdom
        [3172] = {t = 3003}, -- Minor Magic Resistance Potion
        [3173] = {t = 3004}, -- Lesser Mana Potion
        [3175] = {t = 3003}, -- Limited Invulnerability Potion
        [3176] = {t = 3004}, -- Strong Troll's Blood Elixir
        [3177] = {t = 3004}, -- Elixir of Defense
        [3275] = {t = 3006, a = true}, -- Linen Bandage
        [3276] = {t = 3012, a = true}, -- Heavy Linen Bandage
        [3277] = {t = 3012, a = true}, -- Wool Bandage
        [3278] = {t = 3012, a = true}, -- Heavy Wool Bandage
        [3292] = {t = 3011}, -- Heavy Copper Broadsword
        [3293] = {t = 3011}, -- Copper Battle Axe
        [3294] = {t = 3011}, -- Thick War Axe
        [3296] = {t = 3011}, -- Heavy Bronze Mace
        [3304] = {t = 3009}, -- Smelt Tin
        [3307] = {t = 3009}, -- Smelt Iron
        [3308] = {t = 3009}, -- Smelt Gold
        [3319] = {t = 3011}, -- Copper Chain Boots
        [3320] = {t = 3011}, -- Rough Grinding Stone
        [3323] = {t = 3011}, -- Runed Copper Gauntlets
        [3324] = {t = 3011}, -- Runed Copper Pants
        [3326] = {t = 3011}, -- Coarse Grinding Stone
        [3328] = {t = 3011}, -- Rough Bronze Shoulders
        [3331] = {t = 3011}, -- Silvered Bronze Boots
        [3333] = {t = 3011}, -- Silvered Bronze Gauntlets
        [3337] = {t = 3011}, -- Heavy Grinding Stone
        [3399] = {t = 3007}, -- Tasty Lion Steak
        [3400] = {t = 3007}, -- Soothing Turtle Bisque
        [3447] = {t = 3004}, -- Healing Potion
        [3448] = {t = 3004}, -- Lesser Invisibility Potion
        [3449] = {t = 3004}, -- Shadow Oil
        [3450] = {t = 3004}, -- Elixir of Fortitude
        [3452] = {t = 3004}, -- Mana Potion
        [3491] = {t = 3011}, -- Big Bronze Knife
        [3501] = {t = 3011}, -- Green Iron Bracers
        [3502] = {t = 3011}, -- Green Iron Helm
        [3506] = {t = 3011}, -- Green Iron Leggings
        [3508] = {t = 3011}, -- Green Iron Hauberk
        [3569] = {t = 3009}, -- Smelt Steel
        [3753] = {t = 3002}, -- Handstitched Leather Belt
        [3755] = {t = 3005}, -- Linen Bag
        [3756] = {t = 3002}, -- Embossed Leather Gloves
        [3757] = {t = 3005}, -- Woolen Bag
        [3759] = {t = 3002}, -- Embossed Leather Pants
        [3760] = {t = 3002}, -- Hillman's Cloak
        [3761] = {t = 3002}, -- Fine Leather Tunic
        [3763] = {t = 3002}, -- Fine Leather Belt
        [3764] = {t = 3002}, -- Hillman's Leather Gloves
        [3766] = {t = 3002}, -- Dark Leather Belt
        [3768] = {t = 3002}, -- Hillman's Shoulders
        [3770] = {t = 3002}, -- Toughened Leather Gloves
        [3774] = {t = 3002}, -- Green Leather Belt
        [3776] = {t = 3002}, -- Green Leather Bracers
        [3780] = {t = 3002}, -- Heavy Armor Kit
        [3813] = {t = 3005}, -- Small Silk Pack
        [3816] = {t = 3002}, -- Cured Light Hide
        [3817] = {t = 3002}, -- Cured Medium Hide
        [3818] = {t = 3002}, -- Cured Heavy Hide
        [3839] = {t = 3005}, -- Bolt of Silk Cloth
        [3840] = {t = 3005}, -- Heavy Linen Gloves
        [3841] = {t = 3005}, -- Green Linen Bracers
        [3842] = {t = 3005}, -- Handstitched Linen Britches
        [3843] = {t = 3005}, -- Heavy Woolen Gloves
        [3845] = {t = 3005}, -- Soft-soled Linen Boots
        [3848] = {t = 3005}, -- Double-stitched Woolen Shoulders
        [3850] = {t = 3005}, -- Heavy Woolen Pants
        [3852] = {t = 3005}, -- Gloves of Meditation
        [3855] = {t = 3005}, -- Spidersilk Boots
        [3859] = {t = 3005}, -- Azure Silk Vest
        [3861] = {t = 3005}, -- Long Silken Cloak
        [3865] = {t = 3005}, -- Bolt of Mageweave
        [3866] = {t = 3005}, -- Stylish Red Shirt
        [3871] = {t = 3005}, -- Formal White Shirt
        [3914] = {t = 3005}, -- Brown Linen Pants
        [3915] = {t = 3006, a = true}, -- Brown Linen Shirt
        [3918] = {t = 3013, a = true}, -- Rough Blasting Powder
        [3919] = {t = 3013, a = true}, -- Rough Dynamite
        [3920] = {t = 3013, a = true}, -- Crafted Light Shot
        [3922] = {t = 3014}, -- Handful of Copper Bolts
        [3923] = {t = 3014}, -- Rough Copper Bomb
        [3924] = {t = 3013}, -- Copper Tube
        [3925] = {t = 3014}, -- Rough Boomstick
        [3926] = {t = 3013}, -- Copper Modulator
        [3929] = {t = 3014}, -- Coarse Blasting Powder
        [3930] = {t = 3013}, -- Crafted Heavy Shot
        [3931] = {t = 3014}, -- Coarse Dynamite
        [3932] = {t = 3014}, -- Target Dummy
        [3934] = {t = 3014}, -- Flying Tiger Goggles
        [3936] = {t = 3014}, -- Deadly Blunderbuss
        [3937] = {t = 3014}, -- Large Copper Bomb
        [3938] = {t = 3014}, -- Bronze Tube
        [3939] = {t = 3014}, -- Lovingly Crafted Boomstick
        [3941] = {t = 3014}, -- Small Bronze Bomb
        [3942] = {t = 3014}, -- Whirring Bronze Gizmo
        [3945] = {t = 3014}, -- Heavy Blasting Powder
        [3946] = {t = 3014}, -- Heavy Dynamite
        [3947] = {t = 3013}, -- Crafted Solid Shot
        [3949] = {t = 3014}, -- Silver-plated Shotgun
        [3950] = {t = 3014}, -- Big Bronze Bomb
        [3953] = {t = 3014}, -- Bronze Framework
        [3955] = {t = 3014}, -- Explosive Sheep
        [3956] = {t = 3014}, -- Green Tinted Goggles
        [3958] = {t = 3014}, -- Iron Strut
        [3961] = {t = 3014}, -- Gyrochronatom
        [3962] = {t = 3014}, -- Iron Grenade
        [3963] = {t = 3014}, -- Compact Harvest Reaper Kit
        [3965] = {t = 3014}, -- Advanced Target Dummy
        [3967] = {t = 3014}, -- Big Iron Bomb
        [3973] = {t = 3014}, -- Silver Contact
        [3977] = {t = 3014}, -- Crude Scope
        [3978] = {t = 3014}, -- Standard Scope
        [4094] = {t = 3007}, -- Barbecued Buzzard Wing
        [6412] = {t = 3007}, -- Kaldorei Spider Kabob
        [6415] = {t = 3007}, -- Fillet of Frenzy
        [6458] = {t = 3014}, -- Ornate Spyglass
        [6499] = {t = 3007}, -- Boiled Clams
        [6500] = {t = 3007}, -- Goblin Deviled Clams
        [6517] = {t = 3011}, -- Pearl-handled Dagger
        [6521] = {t = 3005}, -- Pearl-clasped Cloak
        [6619] = {t = 3003}, -- Cowardly Flight Potion
        [6661] = {t = 3002}, -- Barbaric Harness
        [6690] = {t = 3005}, -- Lesser Wizard's Robe
        [7126] = {t = 3002, a = true}, -- Handstitched Leather Vest
        [7135] = {t = 3002}, -- Dark Leather Pants
        [7147] = {t = 3002}, -- Guardian Pants
        [7151] = {t = 3002}, -- Barbaric Shoulders
        [7156] = {t = 3002}, -- Guardian Gloves
        [7179] = {t = 3004}, -- Elixir of Water Breathing
        [7181] = {t = 3004}, -- Greater Healing Potion
        [7183] = {t = 3003, a = true}, -- Elixir of Minor Defense
        [7223] = {t = 3011}, -- Golden Scale Bracers
        [7408] = {t = 3011}, -- Heavy Copper Maul
        [7418] = {t = 3015, a = true}, -- Enchant Bracer - Minor Health
        [7420] = {t = 3016}, -- Enchant Chest - Minor Health
        [7421] = {t = 3015, a = true}, -- Runed Copper Rod
        [7426] = {t = 3016}, -- Enchant Chest - Minor Absorption
        [7428] = {t = 3015, a = true}, -- Enchant Bracer - Minor Dodge
        [7430] = {t = 3014}, -- Arclight Spanner
        [7454] = {t = 3016}, -- Enchant Cloak - Minor Resistance
        [7457] = {t = 3016}, -- Enchant Bracer - Minor Stamina
        [7623] = {t = 3005}, -- Brown Linen Robe
        [7624] = {t = 3005}, -- White Linen Robe
        [7745] = {t = 3016}, -- Enchant 2H Weapon - Minor Impact
        [7748] = {t = 3016}, -- Enchant Chest - Lesser Health
        [7771] = {t = 3016}, -- Enchant Cloak - Minor Protection
        [7779] = {t = 3016}, -- Enchant Bracer - Minor Agility
        [7788] = {t = 3016}, -- Enchant Weapon - Minor Striking
        [7795] = {t = 3016}, -- Runed Silver Rod
        [7817] = {t = 3011}, -- Rough Bronze Boots
        [7818] = {t = 3011}, -- Silver Rod
        [7836] = {t = 3004}, -- Blackmouth Oil
        [7837] = {t = 3004}, -- Fire Oil
        [7841] = {t = 3004}, -- Swim Speed Potion
        [7845] = {t = 3004}, -- Elixir of Firepower
        [7857] = {t = 3016}, -- Enchant Chest - Health
        [7861] = {t = 3016}, -- Enchant Cloak - Lesser Fire Resistance
        [7863] = {t = 3016}, -- Enchant Boots - Minor Stamina
        [7928] = {t = 3012, a = true}, -- Silk Bandage
        [7929] = {t = 3012, a = true}, -- Heavy Silk Bandage
        [7934] = {t = 3012, a = true}, -- Anti-Venom
        [8334] = {t = 3014}, -- Clockwork Box
        [8465] = {t = 3005}, -- Simple Dress
        [8467] = {t = 3005}, -- White Woolen Dress
        [8483] = {t = 3005}, -- White Swashbuckler's Shirt
        [8489] = {t = 3005}, -- Red Swashbuckler's Shirt
        [8604] = {t = 3001, a = true}, -- Herb Baked Egg
        [8758] = {t = 3005}, -- Azure Silk Pants
        [8760] = {t = 3005}, -- Azure Silk Hood
        [8762] = {t = 3005}, -- Silk Headband
        [8764] = {t = 3005}, -- Earthen Vest
        [8766] = {t = 3005}, -- Azure Silk Belt
        [8768] = {t = 3011}, -- Iron Buckle
        [8770] = {t = 3005}, -- Robe of Power
        [8772] = {t = 3005}, -- Crimson Silk Belt
        [8774] = {t = 3005}, -- Green Silken Shoulders
        [8776] = {t = 3005}, -- Linen Belt
        [8791] = {t = 3005}, -- Crimson Silk Vest
        [8799] = {t = 3005}, -- Crimson Silk Pantaloons
        [8804] = {t = 3005}, -- Crimson Silk Gloves
        [8880] = {t = 3011}, -- Copper Dagger
        [8895] = {t = 3014}, -- Goblin Rocket Boots
        [9058] = {t = 3002, a = true}, -- Handstitched Leather Cloak
        [9059] = {t = 3002, a = true}, -- Handstitched Leather Bracers
        [9060] = {t = 3002}, -- Light Leather Quiver
        [9062] = {t = 3002}, -- Small Leather Ammo Pouch
        [9065] = {t = 3002}, -- Light Leather Bracers
        [9068] = {t = 3002}, -- Light Leather Pants
        [9074] = {t = 3002}, -- Nimble Leather Gloves
        [9145] = {t = 3002}, -- Fletcher's Gloves
        [9193] = {t = 3002}, -- Heavy Quiver
        [9194] = {t = 3002}, -- Heavy Leather Ammo Pouch
        [9196] = {t = 3002}, -- Dusky Leather Armor
        [9198] = {t = 3002}, -- Frost Leather Cloak
        [9201] = {t = 3002}, -- Dusky Bracers
        [9206] = {t = 3002}, -- Dusky Belt
        [9271] = {t = 3014}, -- Aquadynamic Fish Attractor
        [9916] = {t = 3011}, -- Steel Breastplate
        [9918] = {t = 3011}, -- Solid Sharpening Stone
        [9920] = {t = 3011}, -- Solid Grinding Stone
        [9921] = {t = 3011}, -- Solid Weightstone
        [9926] = {t = 3011}, -- Heavy Mithril Shoulder
        [9928] = {t = 3011}, -- Heavy Mithril Gauntlet
        [9931] = {t = 3011}, -- Mithril Scale Pants
        [9935] = {t = 3011}, -- Steel Plate Helm
        [9954] = {t = 3010}, -- Truesilver Gauntlets
        [9957] = {q = {{2756}}}, -- Orcish War Leggings
        [9959] = {t = 3011}, -- Heavy Mithril Breastplate
        [9961] = {t = 3011}, -- Mithril Coif
        [9968] = {t = 3011}, -- Heavy Mithril Boots
        [9972] = {q = {{2773}}}, -- Ornate Mithril Breastplate
        [9974] = {t = 3010}, -- Truesilver Breastplate
        [9979] = {q = {{2772}}}, -- Ornate Mithril Boots
        [9980] = {q = {{2771}}}, -- Ornate Mithril Helm
        [9983] = {t = 3011}, -- Copper Claymore
        [9985] = {t = 3011}, -- Bronze Warhammer
        [9986] = {t = 3011}, -- Bronze Greatsword
        [9987] = {t = 3011}, -- Bronze Battle Axe
        [9993] = {t = 3011}, -- Heavy Mithril Axe
        [10001] = {t = 3011}, -- Big Black Mace
        [10003] = {t = 3010}, -- The Shatterer
        [10011] = {t = 3010}, -- Blight
        [10015] = {t = 3010}, -- Truesilver Champion
        [10097] = {t = 3009}, -- Smelt Mithril
        [10098] = {t = 3009}, -- Smelt Truesilver
        [10482] = {t = 3002}, -- Cured Thick Hide
        [10487] = {t = 3002}, -- Thick Armor Kit
        [10499] = {t = 3002}, -- Nightscape Tunic
        [10507] = {t = 3002}, -- Nightscape Headband
        [10511] = {t = 3002}, -- Turtle Scale Breastplate
        [10518] = {t = 3002}, -- Turtle Scale Bracers
        [10548] = {t = 3002}, -- Nightscape Pants
        [10552] = {t = 3002}, -- Turtle Scale Helm
        [10556] = {t = 3002}, -- Turtle Scale Leggings
        [10558] = {t = 3002}, -- Nightscape Boots
        [10619] = {t = 3002}, -- Dragonscale Gauntlets
        [10621] = {t = 3002}, -- Wolfshead Helm
        [10630] = {t = 3002}, -- Gauntlets of the Sea
        [10632] = {t = 3002}, -- Helm of Fire
        [10647] = {t = 3002}, -- Feathered Breastplate
        [10650] = {t = 3002}, -- Dragonscale Breastplate
        [10840] = {t = 3012, a = true}, -- Mageweave Bandage
        [10841] = {t = 3012, a = true}, -- Heavy Mageweave Bandage
        [11447] = {t = 3003}, -- Elixir of Waterwalking
        [11448] = {t = 3004}, -- Greater Mana Potion
        [11449] = {t = 3004}, -- Elixir of Agility
        [11450] = {t = 3004}, -- Elixir of Greater Defense
        [11451] = {t = 3004}, -- Oil of Immolation
        [11452] = {t = 3003}, -- Restorative Potion
        [11453] = {t = 3003}, -- Magic Resistance Potion
        [11457] = {t = 3004}, -- Superior Healing Potion
        [11460] = {t = 3004}, -- Elixir of Detect Undead
        [11461] = {t = 3004}, -- Arcane Elixir
        [11465] = {t = 3004}, -- Elixir of Greater Intellect
        [11467] = {t = 3004}, -- Elixir of Greater Agility
        [11478] = {t = 3004}, -- Elixir of Detect Demon
        [12044] = {t = 3006, a = true}, -- Simple Linen Pants
        [12045] = {t = 3005}, -- Simple Linen Boots
        [12046] = {t = 3005}, -- Simple Kilt
        [12048] = {t = 3005}, -- Black Mageweave Vest
        [12049] = {t = 3005}, -- Black Mageweave Leggings
        [12050] = {t = 3005}, -- Black Mageweave Robe
        [12052] = {t = 3005}, -- Shadoweave Pants
        [12053] = {t = 3005}, -- Black Mageweave Gloves
        [12055] = {t = 3005}, -- Shadoweave Robe
        [12061] = {t = 3005}, -- Orange Mageweave Shirt
        [12065] = {t = 3005}, -- Mageweave Bag
        [12067] = {t = 3005}, -- Dreamweave Gloves
        [12069] = {t = 3005}, -- Cindercloth Robe
        [12070] = {t = 3005}, -- Dreamweave Vest
        [12071] = {t = 3005}, -- Shadoweave Gloves
        [12072] = {t = 3005}, -- Black Mageweave Headband
        [12073] = {t = 3005}, -- Black Mageweave Boots
        [12074] = {t = 3005}, -- Black Mageweave Shoulders
        [12076] = {t = 3005}, -- Shadoweave Shoulders
        [12077] = {t = 3005}, -- Simple Black Dress
        [12079] = {t = 3005}, -- Red Mageweave Bag
        [12082] = {t = 3005}, -- Shadoweave Boots
        [12088] = {t = 3005}, -- Cindercloth Boots
        [12092] = {t = 3005}, -- Dreamweave Circlet
        [12260] = {t = 3010, a = true}, -- Rough Copper Vest
        [12584] = {t = 3014}, -- Gold Power Core
        [12585] = {t = 3014}, -- Solid Blasting Powder
        [12586] = {t = 3014}, -- Solid Dynamite
        [12589] = {t = 3014}, -- Mithril Tube
        [12590] = {t = 3014}, -- Gyromatic Micro-Adjustor
        [12591] = {t = 3014}, -- Unstable Trigger
        [12594] = {t = 3014}, -- Fire Goggles
        [12595] = {t = 3014}, -- Mithril Blunderbuss
        [12596] = {t = 3013}, -- Hi-Impact Mithril Slugs
        [12599] = {t = 3014}, -- Mithril Casing
        [12603] = {t = 3014}, -- Mithril Frag Bomb
        [12609] = {t = 3004}, -- Catseye Elixir
        [12615] = {t = 3014}, -- Spellpower Goggles Xtreme
        [12617] = {t = 3014}, -- Deepdive Helmet
        [12618] = {t = 3014}, -- Rose Colored Goggles
        [12619] = {t = 3014}, -- Hi-Explosive Bomb
        [12621] = {t = 3013}, -- Mithril Gyro-Shot
        [12622] = {t = 3014}, -- Green Lens
        [12715] = {t = 3014}, -- Goblin Rocket Fuel Recipe
        [12716] = {t = 3014}, -- Goblin Mortar
        [12717] = {t = 3014}, -- Goblin Mining Helmet
        [12718] = {t = 3014}, -- Goblin Construction Helmet
        [12719] = {t = 3013}, -- Explosive Arrow
        [12720] = {t = 3013}, -- Goblin "Boom" Box
        [12722] = {t = 3013}, -- Goblin Radio
        [12754] = {t = 3014}, -- The Big One
        [12755] = {t = 3014}, -- Goblin Bomb Dispenser
        [12758] = {t = 3014}, -- Goblin Rocket Helmet
        [12759] = {t = 3014}, -- Gnomish Death Ray
        [12760] = {t = 3014}, -- Goblin Sapper Charge
        [12895] = {t = 3014}, -- Inlaid Mithril Cylinder Plans
        [12897] = {t = 3014}, -- Gnomish Goggles
        [12899] = {t = 3014}, -- Gnomish Shrink Ray
        [12900] = {t = 3013}, -- Mobile Alarm
        [12902] = {t = 3014}, -- Gnomish Net-o-Matic Projector
        [12903] = {t = 3014}, -- Gnomish Harm Prevention Belt
        [12904] = {t = 3013}, -- Gnomish Ham Radio
        [12905] = {t = 3014}, -- Gnomish Rocket Boots
        [12906] = {t = 3014}, -- Gnomish Battle Chicken
        [12907] = {t = 3014}, -- Gnomish Mind Control Cap
        [12908] = {t = 3014}, -- Goblin Dragon Gun
        [13240] = {t = 3013}, -- The Mortar: Reloaded
        [13378] = {t = 3016}, -- Enchant Shield - Minor Stamina
        [13421] = {t = 3016}, -- Enchant Cloak - Lesser Protection
        [13485] = {t = 3016}, -- Enchant Shield - Lesser Spirit
        [13501] = {t = 3016}, -- Enchant Bracer - Lesser Stamina
        [13503] = {t = 3016}, -- Enchant Weapon - Lesser Striking
        [13529] = {t = 3016}, -- Enchant 2H Weapon - Lesser Impact
        [13538] = {t = 3016}, -- Enchant Chest - Lesser Absorption
        [13607] = {t = 3016}, -- Enchant Chest - Mana
        [13622] = {t = 3016}, -- Enchant Bracer - Lesser Intellect
        [13626] = {t = 3016}, -- Enchant Chest - Minor Stats
        [13628] = {t = 3016}, -- Runed Golden Rod
        [13631] = {t = 3016}, -- Enchant Shield - Lesser Stamina
        [13635] = {t = 3016}, -- Enchant Cloak - Defense
        [13637] = {t = 3016}, -- Enchant Boots - Lesser Agility
        [13640] = {t = 3016}, -- Enchant Chest - Greater Health
        [13642] = {t = 3016}, -- Enchant Bracer - Spirit
        [13644] = {t = 3016}, -- Enchant Boots - Lesser Stamina
        [13646] = {t = 3016}, -- Enchant Bracer - Lesser Dodge
        [13648] = {t = 3016}, -- Enchant Bracer - Stamina
        [13657] = {t = 3016}, -- Enchant Cloak - Fire Resistance
        [13659] = {t = 3016}, -- Enchant Shield - Spirit
        [13661] = {t = 3016}, -- Enchant Bracer - Strength
        [13663] = {t = 3016}, -- Enchant Chest - Greater Mana
        [13693] = {t = 3016}, -- Enchant Weapon - Striking
        [13695] = {t = 3016}, -- Enchant 2H Weapon - Impact
        [13700] = {t = 3016}, -- Enchant Chest - Lesser Stats
        [13702] = {t = 3016}, -- Runed Truesilver Rod
        [13746] = {t = 3016}, -- Enchant Cloak - Greater Defense
        [13794] = {t = 3016}, -- Enchant Cloak - Resistance
        [13815] = {t = 3016}, -- Enchant Gloves - Agility
        [13822] = {t = 3016}, -- Enchant Bracer - Intellect
        [13836] = {t = 3016}, -- Enchant Boots - Stamina
        [13858] = {t = 3016}, -- Enchant Chest - Superior Health
        [13887] = {t = 3016}, -- Enchant Gloves - Strength
        [13890] = {t = 3016}, -- Enchant Boots - Minor Speed
        [13905] = {t = 3016}, -- Enchant Shield - Greater Spirit
        [13917] = {t = 3016}, -- Enchant Chest - Superior Mana
        [13935] = {t = 3016}, -- Enchant Boots - Agility
        [13937] = {t = 3016}, -- Enchant 2H Weapon - Greater Impact
        [13939] = {t = 3016}, -- Enchant Bracer - Greater Strength
        [13941] = {t = 3016}, -- Enchant Chest - Stats
        [13943] = {t = 3016}, -- Enchant Weapon - Greater Striking
        [13948] = {t = 3016}, -- Enchant Gloves - Minor Haste
        [14293] = {t = 3016}, -- Lesser Magic Wand
        [14379] = {t = 3011}, -- Golden Rod
        [14380] = {t = 3011}, -- Truesilver Rod
        [14807] = {t = 3016}, -- Greater Magic Wand
        [14809] = {t = 3016}, -- Lesser Mystic Wand
        [14810] = {t = 3016}, -- Greater Mystic Wand
        [14891] = {t = 3008}, -- Smelt Dark Iron
        [14930] = {t = 3002}, -- Quickdraw Quiver
        [14932] = {t = 3002}, -- Thick Leather Ammo Pouch
        [15255] = {t = 3014}, -- Mechanical Repair Kit
        [15833] = {t = 3004}, -- Dreamless Sleep Potion
        [15972] = {t = 3011}, -- Glinting Steel Dagger
        [16153] = {t = 3009}, -- Smelt Thorium
        [16639] = {t = 3011}, -- Dense Grinding Stone
        [16640] = {t = 3011}, -- Dense Weightstone
        [16641] = {t = 3011}, -- Dense Sharpening Stone
        [16642] = {t = 3011}, -- Thorium Armor
        [16643] = {t = 3011}, -- Thorium Belt
        [16644] = {t = 3011}, -- Thorium Bracers
        [16646] = {t = 3011}, -- Imperial Plate Shoulders
        [16647] = {t = 3011}, -- Imperial Plate Belt
        [16649] = {t = 3011}, -- Imperial Plate Bracers
        [16652] = {t = 3011}, -- Thorium Boots
        [16653] = {t = 3011}, -- Thorium Helm
        [16657] = {t = 3011}, -- Imperial Plate Boots
        [16658] = {t = 3011}, -- Imperial Plate Helm
        [16662] = {t = 3011}, -- Thorium Leggings
        [16663] = {t = 3011}, -- Imperial Plate Chest
        [16730] = {t = 3011}, -- Imperial Plate Leggings
        [16969] = {t = 3011}, -- Ornate Thorium Handaxe
        [16971] = {t = 3011}, -- Huge Thorium Battleaxe
        [17180] = {t = 3016}, -- Enchanted Thorium Bar
        [17181] = {t = 3016}, -- Enchanted Leather
        [17551] = {t = 3004}, -- Stonescale Oil
        [17552] = {t = 3004}, -- Mighty Rage Potion
        [17553] = {t = 3004}, -- Superior Mana Potion
        [17555] = {t = 3004}, -- Elixir of the Sages
        [17556] = {t = 3004}, -- Major Healing Potion
        [17557] = {t = 3004}, -- Elixir of Brute Force
        [17572] = {t = 3004}, -- Purification Potion
        [17573] = {t = 3004}, -- Greater Arcane Elixir
        [17638] = {t = 3003}, -- Flask of Chromatic Resistance
        [18238] = {t = 3007}, -- Spotted Yellowtail
        [18240] = {t = 3007}, -- Grilled Squid
        [18243] = {t = 3007}, -- Nightfin Soup
        [18244] = {t = 3007}, -- Poached Sunscale Salmon
        [18401] = {t = 3005}, -- Bolt of Runecloth
        [18402] = {t = 3005}, -- Runecloth Belt
        [18403] = {t = 3005}, -- Frostweave Tunic
        [18406] = {t = 3005}, -- Runecloth Robe
        [18407] = {t = 3005}, -- Runecloth Tunic
        [18409] = {t = 3005}, -- Runecloth Cloak
        [18410] = {t = 3005}, -- Ghostweave Belt
        [18411] = {t = 3005}, -- Frostweave Gloves
        [18413] = {t = 3005}, -- Ghostweave Gloves
        [18414] = {t = 3005}, -- Brightcloth Robe
        [18415] = {t = 3005}, -- Brightcloth Gloves
        [18416] = {t = 3005}, -- Ghostweave Vest
        [18417] = {t = 3005}, -- Runecloth Gloves
        [18420] = {t = 3005}, -- Brightcloth Cloak
        [18421] = {t = 3005}, -- Wizardweave Leggings
        [18423] = {t = 3005}, -- Runecloth Boots
        [18424] = {t = 3005}, -- Frostweave Pants
        [18437] = {t = 3005}, -- Felcloth Boots
        [18438] = {t = 3005}, -- Runecloth Pants
        [18441] = {t = 3005}, -- Ghostweave Pants
        [18442] = {t = 3005}, -- Felcloth Hood
        [18444] = {t = 3005}, -- Runecloth Headband
        [18446] = {t = 3005}, -- Wizardweave Robe
        [18449] = {t = 3005}, -- Runecloth Shoulders
        [18450] = {t = 3005}, -- Wizardweave Turban
        [18451] = {t = 3005}, -- Felcloth Robe
        [18453] = {t = 3005}, -- Felcloth Shoulders
        [18629] = {t = 3012, a = true}, -- Runecloth Bandage
        [18630] = {t = 3012, a = true}, -- Heavy Runecloth Bandage
        [19047] = {t = 3002}, -- Cured Rugged Hide
        [19058] = {t = 3002}, -- Rugged Armor Kit
        [19093] = {q = {{7493, 14392, 1637, "H"}, {7497, 14394, 1519, "A"}}}, -- Onyxia Scale Cloak
        [19435] = {q = {{6032, 11557, 361}}}, -- Mooncloth Boots
        [19567] = {t = 3014}, -- Salt Shaker
        [19666] = {t = 3011}, -- Silver Skeleton Key
        [19667] = {t = 3011}, -- Golden Skeleton Key
        [19668] = {t = 3011}, -- Truesilver Skeleton Key
        [19669] = {t = 3011}, -- Arcanite Skeleton Key
        [19788] = {t = 3014}, -- Dense Blasting Powder
        [19790] = {t = 3014}, -- Thorium Grenade
        [19791] = {t = 3014}, -- Thorium Widget
        [19792] = {t = 3014}, -- Thorium Rifle
        [19794] = {t = 3014}, -- Spellpower Goggles Xtreme Plus
        [19795] = {t = 3014}, -- Thorium Tube
        [19800] = {t = 3013}, -- Thorium Shells
        [19825] = {t = 3014}, -- Master Engineer's Goggles
        [20008] = {t = 3016}, -- Enchant Bracer - Greater Intellect
        [20012] = {t = 3016}, -- Enchant Gloves - Greater Agility
        [20013] = {t = 3016}, -- Enchant Gloves - Greater Strength
        [20014] = {t = 3016}, -- Enchant Cloak - Greater Resistance
        [20016] = {t = 3016}, -- Enchant Shield - Vitality
        [20023] = {t = 3016}, -- Enchant Boots - Greater Agility
        [20028] = {t = 3016}, -- Enchant Chest - Major Mana
        [20051] = {t = 3016}, -- Runed Arcanite Rod
        [20201] = {t = 3011}, -- Arcanite Rod
        [20648] = {t = 3002}, -- Medium Leather
        [20649] = {t = 3002}, -- Heavy Leather
        [20650] = {t = 3002}, -- Thick Leather
        [21175] = {t = 3007}, -- Spider Sausage
        [22331] = {t = 3002}, -- Rugged Leather
        [22430] = {t = 3003}, -- Refined Scale of Onyxia
        [22808] = {t = 3004}, -- Elixir of Greater Water Breathing
        [23070] = {t = 3014}, -- Dense Dynamite
        [23071] = {t = 3014}, -- Truesilver Transformer
        [24266] = {t = 3003}, -- Gurubashi Mojo Madness
        [24801] = {q = {{8313}}}, -- Smoked Desert Dumplings
        [25081] = {t = 3015}, -- Enchant Cloak - Greater Fire Resistance
        [25082] = {t = 3015}, -- Enchant Cloak - Greater Nature Resistance
        [25255] = {t = 3017, a = true}, -- Delicate Copper Wire
        [25278] = {t = 3018}, -- Bronze Setting
        [25280] = {t = 3018}, -- Elegant Silver Ring
        [25283] = {t = 3018}, -- Inlaid Malachite Ring
        [25284] = {t = 3018}, -- Simple Pearl Ring
        [25287] = {t = 3018}, -- Gloom Band
        [25305] = {t = 3018}, -- Heavy Silver Ring
        [25317] = {t = 3018}, -- Ring of Silver Might
        [25318] = {t = 3018}, -- Ring of Twilight Shadows
        [25321] = {t = 3018}, -- Moonsoul Crown
        [25490] = {t = 3018}, -- Solid Bronze Ring
        [25493] = {t = 3017, a = true}, -- Braided Copper Ring
        [25498] = {t = 3018}, -- Barbaric Iron Collar
        [25610] = {t = 3018}, -- Pendant of the Agate Shield
        [25612] = {t = 3018}, -- Heavy Iron Knuckles
        [25613] = {t = 3018}, -- Golden Dragon Ring
        [25615] = {t = 3018}, -- Mithril Filigree
        [25617] = {t = 3018}, -- Blazing Citrine Ring
        [25620] = {t = 3018}, -- Engraved Truesilver Ring
        [25621] = {t = 3018}, -- Citrine Ring of Rapid Healing
        [26011] = {t = 3013}, -- Tranquil Mechanical Yeti
        [26745] = {t = 3005}, -- Bolt of Netherweave
        [26746] = {t = 3005}, -- Netherweave Bag
        [26764] = {t = 3005}, -- Netherweave Bracers
        [26765] = {t = 3005}, -- Netherweave Belt
        [26770] = {t = 3005}, -- Netherweave Gloves
        [26771] = {t = 3005}, -- Netherweave Pants
        [26772] = {t = 3005}, -- Netherweave Boots
        [26872] = {t = 3018}, -- Figurine - Jade Owl
        [26874] = {t = 3018}, -- Aquamarine Signet
        [26876] = {t = 3018}, -- Aquamarine Pendant of the Warrior
        [26880] = {t = 3018}, -- Thorium Setting
        [26883] = {t = 3018}, -- Ruby Pendant of Fire
        [26885] = {t = 3018}, -- Truesilver Healing Ring
        [26902] = {t = 3018}, -- Simple Opal Ring
        [26903] = {t = 3018}, -- Sapphire Signet
        [26907] = {t = 3018}, -- Onslaught Ring
        [26908] = {t = 3018}, -- Sapphire Pendant of Winter Night
        [26911] = {t = 3018}, -- Living Emerald Pendant
        [26916] = {t = 3018}, -- Band of Natural Fire
        [26925] = {t = 3017, a = true}, -- Woven Copper Ring
        [26926] = {t = 3018}, -- Heavy Copper Ring
        [26927] = {t = 3018}, -- Thick Bronze Necklace
        [26928] = {t = 3018}, -- Ornate Tigerseye Necklace
        [27032] = {t = 3012}, -- Netherweave Bandage
        [27033] = {t = 3012}, -- Heavy Netherweave Bandage
        [27899] = {t = 3016}, -- Enchant Bracer - Brawn
        [27905] = {t = 3016}, -- Enchant Bracer - Stats
        [27944] = {t = 3016}, -- Enchant Shield - Lesser Dodge
        [27947] = {t = 3015}, -- Enchant Shield - Resistance
        [27957] = {t = 3016}, -- Enchant Chest - Exceptional Health
        [27958] = {t = 3016}, -- Enchant Chest - Exceptional Mana
        [27961] = {t = 3016}, -- Enchant Cloak - Major Armor
        [27962] = {t = 3015}, -- Enchant Cloak - Major Resistance
        [28027] = {t = 3016}, -- Prismatic Sphere
        [28028] = {t = 3016}, -- Void Sphere
        [28544] = {t = 3004}, -- Elixir of Major Strength
        [28545] = {t = 3004}, -- Elixir of Healing Power
        [28551] = {t = 3004}, -- Super Healing Potion
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
        [28905] = {t = 3018}, -- Bold Blood Garnet
        [28906] = {t = 3017}, -- Brilliant Blood Garnet
        [28907] = {t = 3017}, -- Delicate Blood Garnet
        [28910] = {t = 3018}, -- Inscribed Flame Spessarite
        [28914] = {t = 3018}, -- Glinting Shadow Draenite
        [28916] = {t = 3018}, -- Radiant Deep Peridot
        [28917] = {t = 3018}, -- Jagged Deep Peridot
        [28924] = {t = 3017}, -- Purified Shadow Draenite
        [28925] = {t = 3018}, -- Timeless Shadow Draenite
        [28936] = {t = 3018}, -- Sovereign Shadow Draenite
        [28938] = {t = 3017}, -- Brilliant Blood Garnet
        [28948] = {t = 3018}, -- Rigid Azure Moonstone
        [28950] = {t = 3018}, -- Solid Azure Moonstone
        [28953] = {t = 3018}, -- Sparkling Azure Moonstone
        [28957] = {t = 3017}, -- Sparkling Azure Moonstone
        [29356] = {t = 3009}, -- Smelt Fel Iron
        [29358] = {t = 3009}, -- Smelt Adamantite
        [29359] = {t = 3009}, -- Smelt Eternium
        [29360] = {t = 3009}, -- Smelt Felsteel
        [29361] = {t = 3009}, -- Smelt Khorium
        [29545] = {t = 3011}, -- Fel Iron Plate Gloves
        [29547] = {t = 3011}, -- Fel Iron Plate Belt
        [29548] = {t = 3011}, -- Fel Iron Plate Boots
        [29549] = {t = 3011}, -- Fel Iron Plate Pants
        [29550] = {t = 3011}, -- Fel Iron Breastplate
        [29551] = {t = 3011}, -- Fel Iron Chain Coif
        [29552] = {t = 3011}, -- Fel Iron Chain Gloves
        [29553] = {t = 3011}, -- Fel Iron Chain Bracers
        [29556] = {t = 3011}, -- Fel Iron Chain Tunic
        [29557] = {t = 3011}, -- Fel Iron Hatchet
        [29558] = {t = 3011}, -- Fel Iron Hammer
        [29565] = {t = 3011}, -- Fel Iron Greatsword
        [29654] = {t = 3011}, -- Fel Sharpening Stone
        [29686] = {t = 3009}, -- Smelt Hardened Adamantite
        [30047] = {t = 3001}, -- Crystal Throat Lozenge
        [30303] = {t = 3014}, -- Elemental Blasting Powder
        [30304] = {t = 3014}, -- Fel Iron Casing
        [30305] = {t = 3014}, -- Handful of Fel Iron Bolts
        [30306] = {t = 3014}, -- Adamantite Frame
        [30307] = {t = 3014}, -- Hardened Adamantite Tube
        [30308] = {t = 3014}, -- Khorium Power Core
        [30309] = {t = 3014}, -- Felsteel Stabilizer
        [30310] = {t = 3014}, -- Fel Iron Bomb
        [30311] = {t = 3014}, -- Adamantite Grenade
        [30312] = {t = 3014}, -- Fel Iron Musket
        [30346] = {t = 3013}, -- Fel Iron Shells
        [30347] = {t = 3013}, -- Adamantite Shell Machine
        [30558] = {t = 3014}, -- The Bigger One
        [30560] = {t = 3014}, -- Super Sapper Charge
        [30561] = {t = 3013}, -- Goblin Tonk Controller
        [30563] = {t = 3014}, -- Goblin Rocket Launcher
        [30565] = {t = 3014}, -- Foreman's Enchanted Helmet
        [30566] = {t = 3014}, -- Foreman's Reinforced Helmet
        [30568] = {t = 3014}, -- Gnomish Flame Turret
        [30569] = {t = 3014}, -- Gnomish Poultryizer
        [30570] = {t = 3014}, -- Nigh-Invulnerability Belt
        [30573] = {t = 3013}, -- Gnomish Tonk Controller
        [30574] = {t = 3014}, -- Gnomish Power Goggles
        [30575] = {t = 3014}, -- Gnomish Battle Goggles
        [31048] = {t = 3018}, -- Fel Iron Blood Ring
        [31049] = {t = 3018}, -- Golden Draenite Ring
        [31050] = {t = 3018}, -- Azure Moonstone Ring
        [31051] = {t = 3018}, -- Thick Adamantite Necklace
        [31052] = {t = 3018}, -- Heavy Adamantite Ring
        [31087] = {t = 3017}, -- Brilliant Living Ruby
        [31089] = {t = 3017}, -- Delicate Living Ruby
        [31094] = {t = 3017}, -- Sparkling Star of Elune
        [31096] = {t = 3017}, -- Brilliant Living Ruby
        [31099] = {t = 3017}, -- Smooth Dawnstone
        [31100] = {t = 3017}, -- Subtle Dawnstone
        [31105] = {t = 3017}, -- Purified Nightseye
        [31110] = {t = 3017}, -- Regal Talasite
        [31460] = {t = 3005}, -- Netherweave Net
        [32178] = {t = 3018}, -- Malachite Pendant
        [32179] = {t = 3018}, -- Tigerseye Band
        [32259] = {t = 3017, a = true}, -- Rough Stone Statue
        [32284] = {t = 3011}, -- Lesser Rune of Warding
        [32454] = {t = 3002}, -- Knothide Leather
        [32456] = {t = 3002}, -- Knothide Armor Kit
        [32462] = {t = 3002}, -- Felscale Gloves
        [32463] = {t = 3002}, -- Felscale Boots
        [32464] = {t = 3002}, -- Felscale Pants
        [32465] = {t = 3002}, -- Felscale Breastplate
        [32466] = {t = 3002}, -- Scaled Draenic Pants
        [32467] = {t = 3002}, -- Scaled Draenic Gloves
        [32468] = {t = 3002}, -- Scaled Draenic Vest
        [32469] = {t = 3002}, -- Scaled Draenic Boots
        [32470] = {t = 3002}, -- Thick Draenic Gloves
        [32471] = {t = 3002}, -- Thick Draenic Pants
        [32472] = {t = 3002}, -- Thick Draenic Boots
        [32473] = {t = 3002}, -- Thick Draenic Vest
        [32478] = {t = 3002}, -- Wild Draenish Boots
        [32479] = {t = 3002}, -- Wild Draenish Gloves
        [32480] = {t = 3002}, -- Wild Draenish Leggings
        [32481] = {t = 3002}, -- Wild Draenish Vest
        [32655] = {t = 3011}, -- Fel Iron Rod
        [32656] = {t = 3010}, -- Adamantite Rod
        [32657] = {t = 3010}, -- Eternium Rod
        [32664] = {t = 3016}, -- Runed Fel Iron Rod
        [32665] = {t = 3016}, -- Runed Adamantite Rod
        [32667] = {t = 3016}, -- Runed Eternium Rod
        [32801] = {t = 3018}, -- Coarse Stone Statue
        [32807] = {t = 3018}, -- Heavy Stone Statue
        [32808] = {t = 3018}, -- Solid Stone Statue
        [32809] = {t = 3018}, -- Dense Stone Statue
        [33285] = {t = 3001}, -- Sporeling Snack
        [33732] = {t = 3004}, -- Volatile Healing Potion
        [33733] = {t = 3004}, -- Unstable Mana Potion
        [33738] = {t = 3004}, -- Onslaught Elixir
        [33740] = {t = 3004}, -- Adept's Elixir
        [33741] = {t = 3004}, -- Elixir of Mastery
        [33990] = {t = 3016}, -- Enchant Chest - Major Spirit
        [33991] = {t = 3016}, -- Enchant Chest - Restore Mana Prime
        [33993] = {t = 3016}, -- Enchant Gloves - Blasting
        [33995] = {t = 3016}, -- Enchant Gloves - Major Strength
        [33996] = {t = 3016}, -- Enchant Gloves - Assault
        [34001] = {t = 3016}, -- Enchant Bracer - Major Intellect
        [34002] = {t = 3016}, -- Enchant Bracer - Lesser Assault
        [34004] = {t = 3016}, -- Enchant Cloak - Greater Agility
        [34005] = {t = 3015}, -- Enchant Cloak - Greater Arcane Resistance
        [34006] = {t = 3015}, -- Enchant Cloak - Greater Shadow Resistance
        [34069] = {t = 3017}, -- Smooth Golden Draenite
        [34529] = {t = 3010}, -- Nether Chain Shirt
        [34530] = {t = 3010}, -- Twisting Nether Chain Shirt
        [34533] = {t = 3010}, -- Breastplate of Kings
        [34534] = {t = 3010}, -- Bulwark of Kings
        [34535] = {t = 3010}, -- Fireguard
        [34537] = {t = 3010}, -- Blazeguard
        [34538] = {t = 3010}, -- Lionheart Blade
        [34540] = {t = 3010}, -- Lionheart Champion
        [34541] = {t = 3010}, -- The Planar Edge
        [34542] = {t = 3010}, -- Black Planar Edge
        [34543] = {t = 3010}, -- Lunar Crescent
        [34544] = {t = 3010}, -- Mooncleaver
        [34545] = {t = 3010}, -- Drakefist Hammer
        [34546] = {t = 3010}, -- Dragonmaw
        [34547] = {t = 3010}, -- Thunder
        [34548] = {t = 3010}, -- Deep Thunder
        [34590] = {t = 3018}, -- Delicate Blood Garnet
        [34607] = {t = 3011}, -- Fel Weightstone
        [34955] = {t = 3018}, -- Golden Ring of Power
        [34959] = {t = 3018}, -- Truesilver Commander's Ring
        [34960] = {t = 3018}, -- Glowing Thorium Band
        [34961] = {t = 3018}, -- Emerald Lion Ring
        [34979] = {t = 3011}, -- Thick Bronze Darts
        [34981] = {t = 3011}, -- Whirling Steel Axes
        [34982] = {t = 3011}, -- Enchanted Thorium Blades
        [34983] = {t = 3011}, -- Felsteel Whisper Knives
        [35520] = {t = 3002}, -- Shadow Armor Kit
        [35521] = {t = 3002}, -- Flame Armor Kit
        [35522] = {t = 3002}, -- Frost Armor Kit
        [35523] = {t = 3002}, -- Nature Armor Kit
        [35524] = {t = 3002}, -- Arcane Armor Kit
        [35540] = {t = 3002}, -- Drums of War
        [35750] = {t = 3009}, -- Earth Shatter
        [35751] = {t = 3009}, -- Fire Sunder
        [36122] = {t = 3010}, -- Earthforged Leggings
        [36124] = {t = 3010}, -- Windforged Leggings
        [36125] = {t = 3010}, -- Light Earthforged Blade
        [36126] = {t = 3010}, -- Light Skyforged Axe
        [36128] = {t = 3010}, -- Light Emberforged Hammer
        [36129] = {t = 3010}, -- Heavy Earthforged Breastplate
        [36130] = {t = 3010}, -- Stormforged Hauberk
        [36131] = {t = 3010}, -- Windforged Rapier
        [36133] = {t = 3010}, -- Stoneforged Claymore
        [36134] = {t = 3010}, -- Stormforged Axe
        [36135] = {t = 3010}, -- Skyforged Great Axe
        [36136] = {t = 3010}, -- Lavaforged Warhammer
        [36137] = {t = 3010}, -- Great Earthforged Hammer
        [36256] = {t = 3010}, -- Embrace of the Twisting Nether
        [36257] = {t = 3010}, -- Bulwark of the Ancient Kings
        [36258] = {t = 3010}, -- Blazefury
        [36259] = {t = 3010}, -- Lionheart Executioner
        [36260] = {t = 3010}, -- Wicked Edge of the Planes
        [36261] = {t = 3010}, -- Bloodmoon
        [36262] = {t = 3010}, -- Dragonstrike
        [36263] = {t = 3010}, -- Stormherald
        [36523] = {t = 3018}, -- Brilliant Necklace
        [36524] = {t = 3018}, -- Heavy Jade Ring
        [36525] = {t = 3018}, -- Red Ring of Destruction
        [36526] = {t = 3018}, -- Diamond Focus Ring
        [37818] = {t = 3018}, -- Bronze Band of Force
        [37836] = {t = 3007}, -- Spice Bread
        [38068] = {t = 3018}, -- Mercurial Adamantite
        [38070] = {t = 3004}, -- Mercurial Stone
        [38175] = {t = 3018}, -- Bronze Torc
        [39451] = {t = 3017}, -- Rigid Azure Moonstone
        [39452] = {t = 3017}, -- Rigid Star of Elune
        [39455] = {t = 3017}, -- Shifting Shadow Draenite
        [39458] = {t = 3017}, -- Shifting Shadow Draenite
        [39462] = {t = 3017}, -- Glinting Nightseye
        [39463] = {t = 3017}, -- Shifting Nightseye
        [39636] = {t = 3004}, -- Elixir of Major Fortitude
        [39638] = {t = 3004}, -- Elixir of Draenic Wisdom
        [39710] = {t = 3017}, -- Brilliant Crimson Spinel
        [39712] = {t = 3017}, -- Delicate Crimson Spinel
        [39717] = {t = 3017}, -- Sparkling Empyrean Sapphire
        [39719] = {t = 3017}, -- Brilliant Crimson Spinel
        [39722] = {t = 3017}, -- Smooth Lionseye
        [39723] = {t = 3017}, -- Subtle Lionseye
        [39725] = {t = 3017}, -- Rigid Empyrean Sapphire
        [39729] = {t = 3017}, -- Shifting Shadowsong Amethyst
        [39730] = {t = 3017}, -- Glinting Shadowsong Amethyst
        [39732] = {t = 3017}, -- Purified Shadowsong Amethyst
        [39735] = {t = 3017}, -- Reckless Pyrestone
        [39971] = {t = 3014}, -- Icy Blasting Primers
        [39973] = {t = 3014}, -- Frost Grenade
        [40000] = {t = 3002}, -- Bracers of Shackled Souls
        [40274] = {t = 3013}, -- Furious Gizmatic Goggles
        [40514] = {t = 3018}, -- Necklace of the Deep
        [41307] = {t = 3014}, -- Gyro-balanced Khorium Destroyer
        [41311] = {t = 3013}, -- Justicebringer 2000 Specs
        [41312] = {t = 3013}, -- Tankatronic Goggles
        [41314] = {t = 3014}, -- Surestrike Goggles v2.0
        [41315] = {t = 3014}, -- Gadgetstorm Goggles
        [41316] = {t = 3014}, -- Living Replicator Specs
        [41317] = {t = 3013}, -- Deathblow X11 Goggles
        [41318] = {t = 3013}, -- Wonderheal XT40 Shades
        [41319] = {t = 3013}, -- Magnified Moon Specs
        [41320] = {t = 3013}, -- Destruction Holo-gogs
        [41321] = {t = 3013}, -- Powerheal 4000 Lens
        [41414] = {t = 3018}, -- Brilliant Pearl Band
        [41415] = {t = 3018}, -- The Black Pearl
        [41418] = {t = 3018}, -- Crown of the Sea Witch
        [41420] = {t = 3018}, -- Purified Jaggal Pearl
        [41429] = {t = 3018}, -- Purified Shadow Pearl
        [41458] = {d = {28575}}, -- Cauldron of Major Arcane Protection
        [41500] = {d = {28571}}, -- Cauldron of Major Fire Protection
        [41501] = {d = {28572}}, -- Cauldron of Major Frost Protection
        [41502] = {d = {28573}}, -- Cauldron of Major Nature Protection
        [41503] = {d = {28576}}, -- Cauldron of Major Shadow Protection
        [42296] = {t = 3007}, -- Stewed Trout
        [42302] = {t = 3007}, -- Fisherman's Feast
        [42305] = {t = 3007}, -- Hot Buttered Trout
        [42613] = {t = 3016}, -- Nexus Transformation
        [42615] = {t = 3016}, -- Small Prismatic Shard
        [42736] = {t = 3003}, -- Flask of Chromatic Wonder
        [43676] = {t = 3013}, -- Adamantite Arrow Maker
        [44155] = {t = 3014}, -- Flying Machine
        [44157] = {t = 3014}, -- Turbo-Charged Flying Machine
        [44343] = {t = 3002}, -- Knothide Ammo Pouch
        [44344] = {t = 3002}, -- Knothide Quiver
        [44359] = {t = 3002}, -- Quiver of a Thousand Feathers
        [44383] = {t = 3016}, -- Enchant Shield - Resilience
        [44483] = {t = 3015}, -- Enchant Cloak - Superior Frost Resistance
        [44484] = {t = 3016}, -- Enchant Gloves - Expertise
        [44488] = {t = 3016}, -- Enchant Gloves - Precision
        [44489] = {t = 3016}, -- Enchant Shield - Dodge
        [44492] = {t = 3016}, -- Enchant Chest - Mighty Health
        [44494] = {t = 3015}, -- Enchant Cloak - Superior Nature Resistance
        [44500] = {t = 3016}, -- Enchant Cloak - Superior Agility
        [44506] = {t = 3016}, -- Enchant Gloves - Gatherer
        [44508] = {t = 3016}, -- Enchant Boots - Greater Spirit
        [44509] = {t = 3016}, -- Enchant Chest - Greater Mana Restoration
        [44510] = {t = 3016}, -- Enchant Weapon - Exceptional Spirit
        [44513] = {t = 3016}, -- Enchant Gloves - Greater Assault
        [44528] = {t = 3016}, -- Enchant Boots - Greater Fortitude
        [44529] = {t = 3016}, -- Enchant Gloves - Major Agility
        [44555] = {t = 3016}, -- Enchant Bracer - Exceptional Intellect
        [44556] = {t = 3015}, -- Enchant Cloak - Superior Fire Resistance
        [44582] = {t = 3016}, -- Enchant Cloak - Spell Piercing
        [44584] = {t = 3016}, -- Enchant Boots - Greater Vitality
        [44589] = {t = 3016}, -- Enchant Boots - Superior Agility
        [44590] = {t = 3015}, -- Enchant Cloak - Superior Shadow Resistance
        [44592] = {t = 3016}, -- Enchant Gloves - Exceptional Spellpower
        [44593] = {t = 3016}, -- Enchant Bracer - Major Spirit
        [44596] = {t = 3015}, -- Enchant Cloak - Superior Arcane Resistance
        [44598] = {t = 3016}, -- Enchant Bracer - Expertise
        [44616] = {t = 3016}, -- Enchant Bracer - Greater Stats
        [44623] = {t = 3016}, -- Enchant Chest - Super Stats
        [44629] = {t = 3016}, -- Enchant Weapon - Exceptional Spellpower
        [44630] = {t = 3016}, -- Enchant 2H Weapon - Greater Savagery
        [44633] = {t = 3016}, -- Enchant Weapon - Exceptional Agility
        [44635] = {t = 3016}, -- Enchant Bracer - Greater Spellpower
        [44636] = {t = 3016}, -- Enchant Ring - Greater Spellpower
        [44645] = {t = 3016}, -- Enchant Ring - Assault
        [44768] = {t = 3002}, -- Netherscale Ammo Pouch
        [44770] = {t = 3002}, -- Glove Reinforcements
        [44970] = {t = 3002}, -- Heavy Knothide Armor Kit
        [45061] = {t = 3004}, -- Mad Alchemist's Potion
        [45100] = {t = 3002}, -- Leatherworker's Satchel
        [45382] = {t = 3019, a = true}, -- Scroll of Stamina
        [45545] = {t = 3012}, -- Frostweave Bandage
        [45546] = {t = 3012}, -- Heavy Frostweave Bandage
        [45549] = {t = 3007}, -- Mammoth Meal
        [45550] = {t = 3007}, -- Shoveltusk Steak
        [45551] = {t = 3007}, -- Worm Delight
        [45552] = {t = 3007}, -- Roasted Worg
        [45553] = {t = 3007}, -- Rhino Dogs
        [45554] = {t = 3007}, -- Great Feast
        [45560] = {t = 3007}, -- Smoked Rockfin
        [45561] = {t = 3007}, -- Grilled Bonescale
        [45562] = {t = 3007}, -- Sauteed Goby
        [45563] = {t = 3007}, -- Grilled Sculpin
        [45564] = {t = 3007}, -- Smoked Salmon
        [45565] = {t = 3007}, -- Poached Nettlefish
        [45566] = {t = 3007}, -- Pickled Fangtooth
        [45569] = {t = 3007}, -- Baked Manta Ray
        [46404] = {t = 3017}, -- Reckless Noble Topaz
        [46684] = {t = 3007}, -- Charred Bear Kabobs
        [46688] = {t = 3007}, -- Juicy Bear Burger
        [47280] = {t = 3018}, -- Brilliant Glass
        [47766] = {t = 3016}, -- Enchant Chest - Greater Dodge
        [47900] = {t = 3016}, -- Enchant Chest - Super Health
        [48114] = {t = 3019, a = true}, -- Scroll of Intellect
        [48116] = {t = 3019, a = true}, -- Scroll of Spirit
        [48121] = {t = 3020}, -- Glyph of Entangling Roots
        [48247] = {t = 3020}, -- Mysterious Tarot
        [48248] = {t = 3020}, -- Scroll of Recall
        [48789] = {t = 3017}, -- Purified Shadowsong Amethyst
        [49252] = {t = 3009}, -- Smelt Cobalt
        [49258] = {t = 3009}, -- Smelt Saronite
        [50598] = {t = 3020}, -- Scroll of Intellect II
        [50599] = {t = 3020}, -- Scroll of Intellect III
        [50600] = {t = 3020}, -- Scroll of Intellect IV
        [50601] = {t = 3020}, -- Scroll of Intellect V
        [50602] = {t = 3020}, -- Scroll of Intellect VI
        [50603] = {t = 3020}, -- Scroll of Intellect VII
        [50604] = {t = 3020}, -- Scroll of Intellect VIII
        [50605] = {t = 3020}, -- Scroll of Spirit II
        [50606] = {t = 3020}, -- Scroll of Spirit III
        [50607] = {t = 3020}, -- Scroll of Spirit IV
        [50608] = {t = 3020}, -- Scroll of Spirit V
        [50609] = {t = 3020}, -- Scroll of Spirit VI
        [50610] = {t = 3020}, -- Scroll of Spirit VII
        [50611] = {t = 3020}, -- Scroll of Spirit VIII
        [50612] = {t = 3020}, -- Scroll of Stamina II
        [50614] = {t = 3020}, -- Scroll of Stamina III
        [50616] = {t = 3020}, -- Scroll of Stamina IV
        [50617] = {t = 3020}, -- Scroll of Stamina V
        [50618] = {t = 3020}, -- Scroll of Stamina VI
        [50619] = {t = 3020}, -- Scroll of Stamina VII
        [50620] = {t = 3020}, -- Scroll of Stamina VIII
        [50936] = {t = 3002}, -- Heavy Borean Leather
        [50938] = {t = 3002}, -- Iceborne Chestguard
        [50939] = {t = 3002}, -- Iceborne Leggings
        [50940] = {t = 3002}, -- Iceborne Shoulderpads
        [50941] = {t = 3002}, -- Iceborne Gloves
        [50942] = {t = 3002}, -- Iceborne Boots
        [50943] = {t = 3002}, -- Iceborne Belt
        [50944] = {t = 3002}, -- Arctic Chestpiece
        [50945] = {t = 3002}, -- Arctic Leggings
        [50946] = {t = 3002}, -- Arctic Shoulderpads
        [50947] = {t = 3002}, -- Arctic Gloves
        [50948] = {t = 3002}, -- Arctic Boots
        [50949] = {t = 3002}, -- Arctic Belt
        [50950] = {t = 3002}, -- Frostscale Chestguard
        [50951] = {t = 3002}, -- Frostscale Leggings
        [50952] = {t = 3002}, -- Frostscale Shoulders
        [50953] = {t = 3002}, -- Frostscale Gloves
        [50954] = {t = 3002}, -- Frostscale Boots
        [50955] = {t = 3002}, -- Frostscale Belt
        [50956] = {t = 3002}, -- Nerubian Chestguard
        [50957] = {t = 3002}, -- Nerubian Legguards
        [50958] = {t = 3002}, -- Nerubian Shoulders
        [50959] = {t = 3002}, -- Nerubian Gloves
        [50960] = {t = 3002}, -- Nerubian Boots
        [50961] = {t = 3002}, -- Nerubian Belt
        [50962] = {t = 3002}, -- Borean Armor Kit
        [50963] = {t = 3002}, -- Heavy Borean Armor Kit
        [50964] = {t = 3002}, -- Jormungar Leg Armor
        [50965] = {t = 3002}, -- Frosthide Leg Armor
        [50966] = {t = 3002}, -- Nerubian Leg Armor
        [50967] = {t = 3002}, -- Icescale Leg Armor
        [51568] = {t = 3002}, -- Black Chitinguard Boots
        [51569] = {t = 3002}, -- Dark Arctic Leggings
        [51570] = {t = 3002}, -- Dark Arctic Chestpiece
        [51571] = {t = 3002}, -- Arctic Wristguards
        [51572] = {t = 3002}, -- Arctic Helm
        [52567] = {t = 3011}, -- Cobalt Legplates
        [52568] = {t = 3011}, -- Cobalt Belt
        [52569] = {t = 3011}, -- Cobalt Boots
        [52570] = {t = 3011}, -- Cobalt Chestpiece
        [52571] = {t = 3011}, -- Cobalt Helm
        [52572] = {t = 3011}, -- Cobalt Shoulders
        [52738] = {t = 3019, a = true}, -- Ivory Ink
        [52739] = {t = 3020}, -- Enchanting Vellum
        [52840] = {t = 3019}, -- Weapon Vellum
        [52843] = {t = 3020}, -- Moonglow Ink
        [53056] = {q = {{13571, 32516, 4395}}}, -- Kungaloosh
        [53281] = {t = 3014}, -- Volatile Blasting Trigger
        [53462] = {t = 3020}, -- Midnight Ink
        [53770] = {t = 3003}, -- Scourge Haunt Visual
        [53771] = {d = {60350}}, -- Transmute: Eternal Life to Shadow
        [53772] = {t = 3003}, -- Scourge Haunt Visual, Face Player and give GUID
        [53773] = {d = {60350}}, -- Transmute: Eternal Life to Fire
        [53774] = {d = {60350}}, -- Transmute: Eternal Fire to Water
        [53775] = {d = {60350}}, -- Transmute: Eternal Fire to Life
        [53776] = {d = {60350}}, -- Transmute: Eternal Air to Water
        [53777] = {d = {60350}}, -- Transmute: Eternal Air to Earth
        [53778] = {t = 3003}, -- Lay On Hands
        [53779] = {d = {60350}}, -- Transmute: Eternal Shadow to Earth
        [53780] = {d = {60350}}, -- Transmute: Eternal Shadow to Life
        [53781] = {d = {60350}}, -- Transmute: Eternal Earth to Air
        [53782] = {d = {60350}}, -- Transmute: Eternal Earth to Shadow
        [53783] = {d = {60350}}, -- Transmute: Eternal Water to Air
        [53784] = {d = {60350}}, -- Transmute: Eternal Water to Fire
        [53812] = {t = 3004}, -- Pygmy Oil
        [53831] = {t = 3018}, -- Bold Bloodstone
        [53832] = {t = 3018}, -- Delicate Bloodstone
        [53834] = {t = 3017}, -- Brilliant Bloodstone
        [53835] = {t = 3017}, -- Delicate Bloodstone
        [53836] = {t = 3004}, -- Runic Healing Potion
        [53837] = {t = 3004}, -- Runic Mana Potion
        [53838] = {t = 3004}, -- Resurgent Healing Potion
        [53839] = {t = 3004}, -- Icy Mana Potion
        [53840] = {t = 3004}, -- Elixir of Mighty Agility
        [53841] = {t = 3004}, -- Wrath Elixir
        [53842] = {t = 3004}, -- Spellpower Elixir
        [53843] = {t = 3018}, -- Subtle Sun Crystal
        [53844] = {t = 3018}, -- Flashing Bloodstone
        [53845] = {t = 3018}, -- Smooth Sun Crystal
        [53847] = {t = 3004}, -- Elixir of Spirit
        [53848] = {t = 3004}, -- Guru's Elixir
        [53852] = {t = 3018}, -- Brilliant Bloodstone
        [53853] = {t = 3017}, -- Smooth Sun Crystal
        [53854] = {t = 3018}, -- Rigid Chalcedony
        [53855] = {t = 3017}, -- Subtle Sun Crystal
        [53856] = {t = 3018}, -- Quick Sun Crystal
        [53859] = {t = 3018}, -- Sovereign Shadow Crystal
        [53860] = {t = 3018}, -- Shifting Shadow Crystal
        [53861] = {t = 3018}, -- Glinting Shadow Crystal
        [53862] = {t = 3017}, -- Timeless Shadow Crystal
        [53863] = {t = 3017}, -- Purified Shadow Crystal
        [53864] = {t = 3017}, -- Purified Shadow Crystal
        [53866] = {t = 3017}, -- Shifting Shadow Crystal
        [53867] = {t = 3017}, -- Glinting Shadow Crystal
        [53868] = {t = 3017}, -- Regal Dark Jade
        [53870] = {t = 3018}, -- Jagged Dark Jade
        [53871] = {t = 3018}, -- Guardian's Shadow Crystal
        [53872] = {t = 3018}, -- Inscribed Huge Citrine
        [53873] = {t = 3018}, -- Etched Shadow Crystal
        [53874] = {t = 3018}, -- Champion's Huge Citrine
        [53876] = {t = 3018}, -- Fierce Huge Citrine
        [53878] = {t = 3017}, -- Glinting Shadow Crystal
        [53880] = {t = 3018}, -- Deft Huge Citrine
        [53881] = {t = 3017}, -- Reckless Huge Citrine
        [53882] = {t = 3018}, -- Potent Huge Citrine
        [53883] = {t = 3018}, -- Veiled Shadow Crystal
        [53886] = {t = 3017}, -- Deadly Huge Citrine
        [53887] = {t = 3017}, -- Glinting Shadow Crystal
        [53888] = {t = 3017}, -- Lucent Huge Citrine
        [53889] = {t = 3017}, -- Deft Huge Citrine
        [53890] = {t = 3017}, -- Stalwart Huge Citrine
        [53891] = {t = 3018}, -- Stalwart Huge Citrine
        [53892] = {t = 3018}, -- Accurate Shadow Crystal
        [53893] = {t = 3018}, -- Resolute Huge Citrine
        [53894] = {t = 3018}, -- Timeless Shadow Crystal
        [53895] = {d = {60893}}, -- Crazy Alchemist's Potion
        [53898] = {t = 3004}, -- Elixir of Mighty Fortitude
        [53899] = {t = 3004}, -- Lesser Flask of Toughness
        [53900] = {t = 3004}, -- Potion of Nightmares
        [53901] = {t = 3004}, -- Flask of the Frost Wyrm
        [53902] = {t = 3004}, -- Flask of Stoneblood
        [53903] = {t = 3004}, -- Flask of Endless Rage
        [53904] = {d = {60893}}, -- Powerful Rejuvenation Potion
        [53905] = {t = 3004}, -- Indestructible Potion
        [53916] = {t = 3017}, -- Jagged Dark Jade
        [53918] = {t = 3018}, -- Regal Dark Jade
        [53920] = {t = 3018}, -- Forceful Dark Jade
        [53922] = {t = 3018}, -- Misty Dark Jade
        [53923] = {t = 3018}, -- Lightning Dark Jade
        [53925] = {t = 3018}, -- Energized Dark Jade
        [53926] = {t = 3017}, -- Purified Shadow Crystal
        [53927] = {t = 3017}, -- Misty Dark Jade
        [53928] = {t = 3017}, -- Lightning Dark Jade
        [53929] = {t = 3017}, -- Turbid Dark Jade
        [53930] = {t = 3017}, -- Energized Dark Jade
        [53931] = {t = 3017}, -- Radiant Dark Jade
        [53934] = {t = 3018}, -- Solid Chalcedony
        [53940] = {t = 3017}, -- Sparkling Chalcedony
        [53941] = {t = 3018}, -- Sparkling Chalcedony
        [53947] = {t = 3017}, -- Delicate Scarlet Ruby
        [53950] = {t = 3017}, -- Smooth Autumn's Glow
        [53953] = {t = 3017}, -- Sparkling Sky Sapphire
        [53956] = {t = 3017}, -- Brilliant Scarlet Ruby
        [53959] = {t = 3017}, -- Subtle Autumn's Glow
        [53964] = {t = 3017}, -- Glinting Twilight Opal
        [53967] = {t = 3017}, -- Purified Twilight Opal
        [53969] = {t = 3017}, -- Shifting Twilight Opal
        [53970] = {t = 3017}, -- Glinting Twilight Opal
        [53971] = {t = 3017}, -- Regal Forest Emerald
        [53973] = {t = 3017}, -- Jagged Forest Emerald
        [53979] = {t = 3017}, -- Deadly Monarch Topaz
        [53982] = {t = 3017}, -- Deft Monarch Topaz
        [53983] = {t = 3017}, -- Reckless Monarch Topaz
        [53989] = {t = 3017}, -- Glinting Twilight Opal
        [53990] = {t = 3017}, -- Lucent Monarch Topaz
        [53992] = {t = 3017}, -- Stalwart Monarch Topaz
        [53995] = {t = 3017}, -- Timeless Twilight Opal
        [54002] = {t = 3017}, -- Purified Twilight Opal
        [54004] = {t = 3017}, -- Lightning Forest Emerald
        [54006] = {t = 3017}, -- Energized Forest Emerald
        [54007] = {t = 3017}, -- Purified Twilight Opal
        [54008] = {t = 3017}, -- Misty Forest Emerald
        [54010] = {t = 3017}, -- Turbid Forest Emerald
        [54013] = {t = 3017}, -- Radiant Forest Emerald
        [54017] = {t = 3018}, -- Precise Bloodstone
        [54020] = {t = 3003}, -- Transmute: Eternal Might
        [54213] = {t = 3004}, -- Flask of Pure Mojo
        [54218] = {t = 3004}, -- Elixir of Mighty Strength
        [54220] = {d = {60893}}, -- Elixir of Protection
        [54221] = {d = {60893}}, -- Potion of Speed
        [54222] = {d = {60893}}, -- Potion of Wild Magic
        [54353] = {t = 3014}, -- Mark "S" Boomstick
        [54550] = {t = 3011}, -- Cobalt Triangle Shield
        [54551] = {t = 3011}, -- Tempered Saronite Belt
        [54552] = {t = 3011}, -- Tempered Saronite Boots
        [54553] = {t = 3011}, -- Tempered Saronite Breastplate
        [54554] = {t = 3011}, -- Tempered Saronite Legplates
        [54555] = {t = 3011}, -- Tempered Saronite Helm
        [54556] = {t = 3011}, -- Tempered Saronite Shoulders
        [54557] = {t = 3011}, -- Saronite Defender
        [54736] = {t = 3014}, -- Personal Electromagnetic Pulse Generator
        [54793] = {t = 3014}, -- Frag Belt
        [54917] = {t = 3011}, -- Spiked Cobalt Helm
        [54918] = {t = 3011}, -- Spiked Cobalt Boots
        [54941] = {t = 3011}, -- Spiked Cobalt Shoulders
        [54944] = {t = 3011}, -- Spiked Cobalt Chestpiece
        [54945] = {t = 3011}, -- Spiked Cobalt Gauntlets
        [54946] = {t = 3011}, -- Spiked Cobalt Belt
        [54947] = {t = 3011}, -- Spiked Cobalt Legplates
        [54948] = {t = 3011}, -- Spiked Cobalt Bracers
        [54949] = {t = 3011}, -- Horned Cobalt Helm
        [54998] = {t = 3014}, -- Hand-Mounted Pyro Rocket
        [54999] = {t = 3014}, -- Hyperspeed Accelerators
        [55002] = {t = 3014}, -- Flexweave Underlay
        [55013] = {t = 3011}, -- Saronite Protector
        [55014] = {t = 3011}, -- Saronite Bulwark
        [55015] = {t = 3011}, -- Tempered Saronite Gauntlets
        [55016] = {t = 3014}, -- Nitro Boosts
        [55017] = {t = 3011}, -- Tempered Saronite Bracers
        [55055] = {t = 3011}, -- Brilliant Saronite Legplates
        [55056] = {t = 3011}, -- Brilliant Saronite Gauntlets
        [55057] = {t = 3011}, -- Brilliant Saronite Boots
        [55058] = {t = 3011}, -- Brilliant Saronite Breastplate
        [55174] = {t = 3011}, -- Honed Cobalt Cleaver
        [55177] = {t = 3011}, -- Savage Cobalt Slicer
        [55179] = {t = 3011}, -- Saronite Ambusher
        [55181] = {t = 3011}, -- Saronite Shiv
        [55182] = {t = 3011}, -- Furious Saronite Beatstick
        [55183] = {t = 3010}, -- Corroded Saronite Edge
        [55184] = {t = 3010}, -- Corroded Saronite Woundbringer
        [55185] = {t = 3011}, -- Saronite Mindcrusher
        [55186] = {t = 3010}, -- Chestplate of Conquest
        [55187] = {t = 3010}, -- Legplates of Conquest
        [55199] = {t = 3002}, -- Cloak of Tormented Skies
        [55200] = {t = 3011}, -- Sturdy Cobalt Quickblade
        [55201] = {t = 3011}, -- Cobalt Tenderizer
        [55202] = {t = 3011}, -- Sure-fire Shuriken
        [55203] = {t = 3011}, -- Forged Cobalt Claymore
        [55204] = {t = 3011}, -- Notched Cobalt War Axe
        [55206] = {t = 3011}, -- Deadly Saronite Dirk
        [55208] = {t = 3009}, -- Smelt Titansteel
        [55211] = {t = 3009}, -- Smelt Titanium
        [55243] = {t = 3002}, -- Bracers of Deflection
        [55252] = {q = {{12889, 29806, 67}, {13843}}}, -- Scrapbot Construction Kit
        [55298] = {t = 3011}, -- Vengeance Bindings
        [55300] = {t = 3011}, -- Righteous Gauntlets
        [55301] = {t = 3011}, -- Daunting Handguards
        [55302] = {t = 3011}, -- Helm of Command
        [55303] = {t = 3011}, -- Daunting Legplates
        [55304] = {t = 3011}, -- Righteous Greaves
        [55305] = {t = 3011}, -- Savage Saronite Bracers
        [55306] = {t = 3011}, -- Savage Saronite Pauldrons
        [55307] = {t = 3011}, -- Savage Saronite Waistguard
        [55308] = {t = 3011}, -- Savage Saronite Walkers
        [55309] = {t = 3011}, -- Savage Saronite Gauntlets
        [55310] = {t = 3011}, -- Savage Saronite Legplates
        [55311] = {t = 3011}, -- Savage Saronite Hauberk
        [55312] = {t = 3011}, -- Savage Saronite Skullshield
        [55369] = {t = 3011}, -- Titansteel Destroyer
        [55370] = {t = 3011}, -- Titansteel Bonecrusher
        [55371] = {t = 3011}, -- Titansteel Guardian
        [55372] = {t = 3011}, -- Spiked Titansteel Helm
        [55373] = {t = 3011}, -- Tempered Titansteel Helm
        [55374] = {t = 3011}, -- Brilliant Titansteel Helm
        [55375] = {t = 3011}, -- Spiked Titansteel Treads
        [55376] = {t = 3011}, -- Tempered Titansteel Treads
        [55377] = {t = 3011}, -- Brilliant Titansteel Treads
        [55386] = {t = 3018}, -- Tireless Skyflare Diamond
        [55394] = {t = 3018}, -- Swift Skyflare Diamond
        [55399] = {t = 3018}, -- Powerful Earthsiege Diamond
        [55402] = {t = 3018}, -- Persistent Earthsiege Diamond
        [55628] = {t = 3011}, -- Socket Bracer
        [55641] = {t = 3011}, -- Socket Gloves
        [55642] = {t = 3005}, -- Lightweave Embroidery
        [55656] = {t = 3011}, -- Eternal Belt Buckle
        [55732] = {t = 3011}, -- Titanium Rod
        [55769] = {t = 3005}, -- Darkglow Embroidery
        [55777] = {t = 3005}, -- Swordguard Embroidery
        [55834] = {t = 3011}, -- Cobalt Bracers
        [55835] = {t = 3011}, -- Cobalt Gauntlets
        [55839] = {t = 3011}, -- Titanium Weapon Chain
        [55898] = {t = 3005}, -- Frostweave Net
        [55899] = {t = 3005}, -- Bolt of Frostweave
        [55900] = {t = 3005}, -- Bolt of Imbued Frostweave
        [55901] = {t = 3005}, -- Duskweave Leggings
        [55902] = {t = 3005}, -- Frostwoven Shoulders
        [55903] = {t = 3005}, -- Frostwoven Robe
        [55904] = {t = 3005}, -- Frostwoven Gloves
        [55906] = {t = 3005}, -- Frostwoven Boots
        [55907] = {t = 3005}, -- Frostwoven Cowl
        [55908] = {t = 3005}, -- Frostwoven Belt
        [55910] = {t = 3005}, -- Mystic Frostwoven Shoulders
        [55911] = {t = 3005}, -- Mystic Frostwoven Robe
        [55913] = {t = 3005}, -- Mystic Frostwoven Wristwraps
        [55914] = {t = 3005}, -- Duskweave Belt
        [55919] = {t = 3005}, -- Duskweave Cowl
        [55920] = {t = 3005}, -- Duskweave Wristwraps
        [55921] = {t = 3005}, -- Duskweave Robe
        [55922] = {t = 3005}, -- Duskweave Gloves
        [55923] = {t = 3005}, -- Duskweave Shoulders
        [55924] = {t = 3005}, -- Duskweave Boots
        [55925] = {t = 3005}, -- Black Duskweave Leggings
        [55941] = {t = 3005}, -- Black Duskweave Robe
        [55943] = {t = 3005}, -- Black Duskweave Wristwraps
        [55995] = {t = 3005}, -- Yellow Lumberjack Shirt
        [56000] = {t = 3005}, -- Green Workman's Shirt
        [56001] = {t = 3005}, -- Moonshroud
        [56002] = {t = 3005}, -- Ebonweave
        [56003] = {t = 3005}, -- Spellweave
        [56007] = {t = 3005}, -- Frostweave Bag
        [56008] = {t = 3005}, -- Shining Spellthread
        [56010] = {t = 3005}, -- Azure Spellthread
        [56014] = {t = 3005}, -- Cloak of the Moon
        [56015] = {t = 3005}, -- Cloak of Frozen Spirits
        [56018] = {t = 3005}, -- Hat of Wintry Doom
        [56019] = {t = 3005}, -- Silky Iceshard Boots
        [56020] = {t = 3005}, -- Deep Frozen Cord
        [56021] = {t = 3005}, -- Frostmoon Pants
        [56022] = {t = 3005}, -- Light Blessed Mittens
        [56023] = {t = 3005}, -- Aurora Slippers
        [56024] = {t = 3005}, -- Moonshroud Robe
        [56025] = {t = 3005}, -- Moonshroud Gloves
        [56026] = {t = 3005}, -- Ebonweave Robe
        [56027] = {t = 3005}, -- Ebonweave Gloves
        [56028] = {t = 3005}, -- Spellweave Robe
        [56029] = {t = 3005}, -- Spellweave Gloves
        [56030] = {t = 3005}, -- Frostwoven Leggings
        [56031] = {t = 3005}, -- Frostwoven Wristwraps
        [56034] = {t = 3005}, -- Master's Spellthread
        [56039] = {t = 3005}, -- Sanctified Spellthread
        [56048] = {t = 3006}, -- Duskweave Boots
        [56054] = {t = 3017}, -- Delicate Dragon's Eye
        [56074] = {t = 3017}, -- Brilliant Dragon's Eye
        [56076] = {t = 3017}, -- Smooth Dragon's Eye
        [56077] = {t = 3017}, -- Sparkling Dragon's Eye
        [56089] = {t = 3017}, -- Subtle Dragon's Eye
        [56193] = {t = 3018}, -- Bloodstone Band
        [56194] = {t = 3018}, -- Sun Rock Ring
        [56195] = {t = 3018}, -- Jade Dagger Pendant
        [56196] = {t = 3018}, -- Blood Sun Necklace
        [56197] = {t = 3018}, -- Dream Signet
        [56199] = {t = 3018}, -- Figurine - Ruby Hare
        [56201] = {t = 3018}, -- Figurine - Twilight Serpent
        [56202] = {t = 3018}, -- Figurine - Sapphire Owl
        [56203] = {t = 3018}, -- Figurine - Emerald Boar
        [56205] = {t = 3018}, -- Dark Jade Focusing Lens
        [56206] = {t = 3018}, -- Shadow Crystal Focusing Lens
        [56208] = {t = 3018}, -- Shadow Jade Focusing Lens
        [56234] = {t = 3011}, -- Titansteel Shanker
        [56280] = {t = 3011}, -- Cudgel of Saronite Justice
        [56349] = {t = 3014}, -- Handful of Cobalt Bolts
        [56357] = {t = 3011}, -- Titanium Shield Spike
        [56400] = {t = 3011}, -- Titansteel Shield Wall
        [56459] = {t = 3014}, -- Hammer Pick
        [56460] = {t = 3014}, -- Cobalt Frag Bomb
        [56461] = {t = 3014}, -- Bladed Pickaxe
        [56462] = {t = 3014}, -- Gnomish Army Knife
        [56463] = {t = 3014}, -- Explosive Decoy
        [56464] = {t = 3014}, -- Overcharged Capacitor
        [56465] = {t = 3013}, -- Mechanized Snow Goggles
        [56466] = {t = 3014}, -- Sonic Booster
        [56467] = {t = 3014}, -- Noise Machine
        [56468] = {t = 3014}, -- Box of Bombs
        [56469] = {t = 3014}, -- Gnomish Lightning Generator
        [56470] = {t = 3014}, -- Sun Scope
        [56471] = {t = 3014}, -- Froststeel Tube
        [56472] = {t = 3014}, -- MOLL-E
        [56473] = {t = 3014}, -- Gnomish X-Ray Specs
        [56474] = {t = 3013}, -- Mammoth Cutters
        [56475] = {t = 3013}, -- Saronite Razorheads
        [56476] = {t = 3014}, -- Healing Injector Kit
        [56477] = {t = 3014}, -- Mana Injector Kit
        [56478] = {t = 3014}, -- Heartseeker Scope
        [56479] = {t = 3014}, -- Armor Plated Combat Shotgun
        [56480] = {t = 3013}, -- Armored Titanium Goggles
        [56481] = {t = 3013}, -- Weakness Spectralizers
        [56483] = {t = 3013}, -- Charged Titanium Specs
        [56484] = {t = 3013}, -- Visage Liquification Goggles
        [56486] = {t = 3013}, -- Greensight Gogs
        [56487] = {t = 3014}, -- Electroflux Sight Enhancers
        [56514] = {t = 3014}, -- Global Thermal Sapper Charge
        [56519] = {d = {60893}}, -- Elixir of Mighty Mageblood
        [56530] = {t = 3018}, -- Enchanted Pearl
        [56531] = {t = 3018}, -- Enchanted Tear
        [56549] = {t = 3011}, -- Ornate Saronite Bracers
        [56550] = {t = 3011}, -- Ornate Saronite Pauldrons
        [56551] = {t = 3011}, -- Ornate Saronite Waistguard
        [56552] = {t = 3011}, -- Ornate Saronite Walkers
        [56553] = {t = 3011}, -- Ornate Saronite Gauntlets
        [56554] = {t = 3011}, -- Ornate Saronite Legplates
        [56555] = {t = 3011}, -- Ornate Saronite Hauberk
        [56556] = {t = 3011}, -- Ornate Saronite Skullshield
        [56574] = {t = 3014}, -- Truesight Ice Blinders
        [56943] = {t = 3020}, -- Glyph of Frenzied Regeneration
        [56944] = {d = {61177, 61756}}, -- Glyph of Solar Beam
        [56945] = {t = 3020}, -- Glyph of Healing Touch
        [56946] = {d = {61177, 61756}}, -- Glyph of Hurricane
        [56947] = {d = {61177, 61756}}, -- Glyph of Innervate
        [56948] = {t = 3020}, -- Glyph of Insect Swarm
        [56949] = {d = {61177, 61756}}, -- Glyph of Lifebloom
        [56950] = {d = {61177, 61756}}, -- Glyph of Mangle
        [56951] = {t = 3020}, -- Glyph of Moonfire
        [56952] = {t = 3020}, -- Glyph of Pounce
        [56953] = {t = 3020}, -- Glyph of Rebirth
        [56954] = {d = {61177, 61756}}, -- Glyph of Regrowth
        [56955] = {t = 3020}, -- Glyph of Rejuvenation
        [56956] = {t = 3020}, -- Glyph of Rip
        [56957] = {t = 3020}, -- Glyph of Bloodletting
        [56958] = {d = {61177, 61756}}, -- Glyph of Starfall
        [56959] = {t = 3020}, -- Glyph of Starfire
        [56960] = {d = {61177, 61756}}, -- Glyph of Swiftmend
        [56961] = {t = 3020}, -- Glyph of Maul
        [56963] = {t = 3020}, -- Glyph of Wrath
        [56965] = {d = {61288}}, -- Glyph of Typhoon
        [56968] = {t = 3019}, -- Glyph of Arcane Explosion
        [56971] = {t = 3020}, -- Glyph of Arcane Missiles
        [56972] = {t = 3020}, -- Glyph of Arcane Power
        [56973] = {t = 3020}, -- Glyph of Blink
        [56974] = {t = 3020}, -- Glyph of Evocation
        [56975] = {d = {61177, 61756}}, -- Glyph of Fireball
        [56976] = {t = 3020}, -- Glyph of Frost Nova
        [56977] = {d = {61177, 61756}}, -- Glyph of Frostbolt
        [56978] = {t = 3020}, -- Glyph of Pyroblast
        [56979] = {t = 3020}, -- Glyph of Ice Block
        [56980] = {t = 3020, d = {61177, 61756}}, -- Glyph of Ice Lance
        [56981] = {t = 3020}, -- Glyph of Icy Veins
        [56982] = {t = 3019}, -- Glyph of Scorch
        [56983] = {d = {61177, 61756}}, -- Glyph of Invisibility
        [56984] = {t = 3020}, -- Glyph of Mage Armor
        [56985] = {t = 3019}, -- Glyph of Mana Gem
        [56986] = {d = {61177, 61756}}, -- Glyph of Molten Armor
        [56987] = {t = 3020, d = {61177, 61756}}, -- Glyph of Polymorph
        [56988] = {d = {61177, 61756}}, -- Glyph of Cone of Cold
        [56989] = {d = {61177, 61756}}, -- Glyph of Dragon's Breath
        [56990] = {d = {61288}}, -- Glyph of Blast Wave
        [56991] = {t = 3020}, -- Glyph of Arcane Blast
        [56994] = {t = 3020}, -- Glyph of Aimed Shot
        [56995] = {t = 3020}, -- Glyph of Arcane Shot
        [56996] = {d = {61177, 61756}}, -- Glyph of Trap Launcher
        [56997] = {t = 3020}, -- Glyph of Mending
        [56998] = {d = {61177, 61756}}, -- Glyph of Concussive Shot
        [56999] = {d = {61177, 61756}}, -- Glyph of Bestial Wrath
        [57000] = {t = 3020}, -- Glyph of Deterrence
        [57001] = {t = 3020}, -- Glyph of Disengage
        [57002] = {t = 3020}, -- Glyph of Freezing Trap
        [57003] = {t = 3020}, -- Glyph of Ice Trap
        [57004] = {t = 3020}, -- Glyph of Misdirection
        [57005] = {t = 3020}, -- Glyph of Immolation Trap
        [57006] = {t = 3020, d = {61177, 61756}}, -- Glyph of the Dazzled Prey
        [57007] = {t = 3020}, -- Glyph of Silencing Shot
        [57008] = {t = 3020}, -- Glyph of Rapid Fire
        [57009] = {t = 3020}, -- Glyph of Serpent Sting
        [57010] = {d = {61177, 61756}}, -- Glyph of Snake Trap
        [57011] = {d = {61177, 61756}}, -- Glyph of Steady Shot
        [57012] = {d = {61177, 61756}}, -- Glyph of Kill Command
        [57013] = {d = {61177, 61756}}, -- Glyph of Volley
        [57014] = {d = {61177, 61756}}, -- Glyph of Wyvern Sting
        [57019] = {d = {61177, 61756}}, -- Glyph of Focused Shield
        [57020] = {t = 3020}, -- Glyph of Cleansing
        [57021] = {d = {61177, 61756}}, -- Glyph of the Ascetic Crusader
        [57022] = {t = 3020}, -- Glyph of Divine Protection
        [57023] = {t = 3020}, -- Glyph of Consecration
        [57024] = {t = 3020}, -- Glyph of Crusader Strike
        [57025] = {t = 3020}, -- Glyph of Exorcism
        [57026] = {t = 3020}, -- Glyph of Word of Glory
        [57027] = {t = 3020}, -- Glyph of Hammer of Justice
        [57028] = {d = {61177, 61756}}, -- Glyph of Hammer of Wrath
        [57029] = {t = 3020}, -- Glyph of Divine Favor
        [57030] = {t = 3020}, -- Glyph of Judgement
        [57031] = {t = 3020}, -- Glyph of Divinity
        [57032] = {t = 3019}, -- Glyph of Righteousness
        [57033] = {t = 3020}, -- Glyph of Rebuke
        [57034] = {d = {61177, 61756}}, -- Glyph of Seal of Insight
        [57035] = {d = {61177, 61756}}, -- Glyph of Light of Dawn
        [57036] = {t = 3020, d = {61177, 61756}}, -- Glyph of Turn Evil
        [57112] = {d = {61177, 61756}}, -- Glyph of Adrenaline Rush
        [57113] = {t = 3020}, -- Glyph of Ambush
        [57114] = {t = 3020}, -- Glyph of Backstab
        [57115] = {d = {61177, 61756}}, -- Glyph of Blade Flurry
        [57116] = {d = {61177, 61756}}, -- Glyph of Crippling Poison
        [57117] = {d = {61177, 61756}}, -- Glyph of Deadly Throw
        [57119] = {t = 3020}, -- Glyph of Evasion
        [57120] = {t = 3020}, -- Glyph of Eviscerate
        [57121] = {t = 3020}, -- Glyph of Expose Armor
        [57122] = {t = 3020}, -- Glyph of Feint
        [57123] = {t = 3020}, -- Glyph of Garrote
        [57124] = {d = {61177, 61756}}, -- Glyph of Revealing Strike
        [57125] = {t = 3020}, -- Glyph of Gouge
        [57126] = {d = {61177, 61756}}, -- Glyph of Hemorrhage
        [57127] = {d = {61177, 61756}}, -- Glyph of Preparation
        [57128] = {d = {61177, 61756}}, -- Glyph of Rupture
        [57129] = {t = 3020}, -- Glyph of Sap
        [57130] = {d = {61177, 61756}}, -- Glyph of Kick
        [57131] = {t = 3020}, -- Glyph of Sinister Strike
        [57132] = {t = 3020}, -- Glyph of Slice and Dice
        [57133] = {t = 3020}, -- Glyph of Sprint
        [57151] = {t = 3019}, -- Glyph of Barbaric Insults
        [57152] = {d = {61177, 61756}}, -- Glyph of Shield Slam
        [57153] = {d = {61177, 61756}}, -- Glyph of Bloody Healing
        [57154] = {t = 3020}, -- Glyph of Cleaving
        [57155] = {d = {61177, 61756}}, -- Glyph of Devastate
        [57156] = {t = 3020}, -- Glyph of Bloodthirst
        [57157] = {t = 3020}, -- Glyph of Piercing Howl
        [57158] = {t = 3020}, -- Glyph of Heroic Throw
        [57159] = {d = {61177, 61756}}, -- Glyph of Intervene
        [57160] = {d = {61177, 61756}}, -- Glyph of Mortal Strike
        [57161] = {t = 3020}, -- Glyph of Overpower
        [57162] = {t = 3020}, -- Glyph of Rapid Charge
        [57163] = {t = 3020}, -- Glyph of Slam
        [57164] = {d = {61177, 61756}}, -- Glyph of Resonating Power
        [57165] = {t = 3020}, -- Glyph of Revenge
        [57166] = {d = {61177, 61756}}, -- Glyph of Last Stand
        [57167] = {t = 3020}, -- Glyph of Sunder Armor
        [57168] = {t = 3020}, -- Glyph of Sweeping Strikes
        [57169] = {d = {61177, 61756}}, -- Glyph of Taunt
        [57170] = {d = {61177, 61756}}, -- Glyph of Victory Rush
        [57172] = {t = 3020}, -- Glyph of Raging Blow
        [57181] = {d = {61177, 61756}}, -- Glyph of Circle of Healing
        [57183] = {t = 3020}, -- Glyph of Dispel Magic
        [57184] = {t = 3020}, -- Glyph of Fade
        [57185] = {t = 3020}, -- Glyph of Fear Ward
        [57186] = {t = 3020}, -- Glyph of Flash Heal
        [57187] = {t = 3020}, -- Glyph of Holy Nova
        [57188] = {t = 3020}, -- Glyph of Inner Fire
        [57189] = {d = {61177, 61756}}, -- Glyph of Lightwell
        [57190] = {d = {61177, 61756}}, -- Glyph of Mass Dispel
        [57191] = {d = {61177, 61756}}, -- Glyph of Psychic Horror
        [57192] = {t = 3020}, -- Glyph of Shadow Word: Pain
        [57193] = {d = {61177, 61756}}, -- Glyph of Power Word: Barrier
        [57194] = {t = 3020}, -- Glyph of Power Word: Shield
        [57195] = {d = {61177, 61756}}, -- Glyph of Prayer of Healing
        [57196] = {t = 3020}, -- Glyph of Psychic Scream
        [57197] = {t = 3020}, -- Glyph of Renew
        [57198] = {t = 3020, d = {61177, 61756}}, -- Glyph of Scourge Imprisonment
        [57199] = {d = {61177, 61756}}, -- Glyph of Shadow Word: Death
        [57200] = {t = 3020}, -- Glyph of Mind Flay
        [57201] = {t = 3020}, -- Glyph of Smite
        [57202] = {d = {61177, 61756}}, -- Glyph of Prayer of Mending
        [57207] = {d = {61177, 61756}}, -- Glyph of Anti-Magic Shell
        [57208] = {d = {61177, 61756}}, -- Glyph of Heart Strike
        [57209] = {d = {61288}}, -- Glyph of Blood Tap
        [57210] = {t = 3020}, -- Glyph of Bone Shield
        [57211] = {d = {61177, 61756}}, -- Glyph of Chains of Ice
        [57212] = {d = {61177, 61756}}, -- Glyph of Dark Command
        [57213] = {t = 3020}, -- Glyph of Death Grip
        [57214] = {d = {61177, 61756}}, -- Glyph of Death and Decay
        [57215] = {d = {61288}}, -- Glyph of Death's Embrace
        [57216] = {t = 3020}, -- Glyph of Frost Strike
        [57217] = {d = {61288}}, -- Glyph of Horn of Winter
        [57218] = {d = {61177, 61756}}, -- Glyph of Icebound Fortitude
        [57219] = {t = 3020}, -- Glyph of Icy Touch
        [57220] = {d = {61177, 61756}}, -- Glyph of Obliterate
        [57221] = {t = 3020}, -- Glyph of Pestilence
        [57222] = {t = 3020}, -- Glyph of Raise Dead
        [57223] = {d = {61177, 61756}}, -- Glyph of Rune Strike
        [57224] = {t = 3020}, -- Glyph of Scourge Strike
        [57225] = {t = 3020, d = {61177, 61756}}, -- Glyph of Strangulate
        [57226] = {t = 3020}, -- Glyph of Pillar of Frost
        [57227] = {t = 3020}, -- Glyph of Vampiric Blood
        [57228] = {d = {61288}}, -- Glyph of Death Gate
        [57229] = {d = {61288}}, -- Glyph of Path of Frost
        [57230] = {d = {61288}}, -- Glyph of Resilient Grip
        [57231] = {t = 3019}, -- Death Knight Glyph 25
        [57232] = {d = {61177, 61756}}, -- Glyph of Chain Heal
        [57233] = {d = {61177, 61756}}, -- Glyph of Chain Lightning
        [57234] = {d = {61177, 61756}}, -- Glyph of Lava Burst
        [57235] = {d = {61177, 61756}}, -- Glyph of Shocking
        [57236] = {t = 3020}, -- Glyph of Earthliving Weapon
        [57237] = {d = {61177, 61756}}, -- Glyph of Fire Elemental Totem
        [57238] = {t = 3020}, -- Glyph of Fire Nova
        [57239] = {t = 3020}, -- Glyph of Flame Shock
        [57240] = {t = 3020}, -- Glyph of Flametongue Weapon
        [57241] = {t = 3020}, -- Glyph of Frost Shock
        [57242] = {t = 3020}, -- Glyph of Healing Stream Totem
        [57243] = {d = {61177, 61756}}, -- Glyph of Healing Wave
        [57244] = {t = 3020}, -- Glyph of Totemic Recall
        [57245] = {t = 3020}, -- Glyph of Lightning Bolt
        [57246] = {t = 3020}, -- Glyph of Lightning Shield
        [57247] = {d = {61177, 61756}}, -- Glyph of Grounding Totem
        [57248] = {t = 3020, d = {61177, 61756}}, -- Glyph of Stormstrike
        [57249] = {t = 3020}, -- Glyph of Lava Lash
        [57250] = {d = {61177, 61756}}, -- Glyph of Elemental Mastery
        [57251] = {t = 3020}, -- Glyph of Water Shield
        [57252] = {t = 3020}, -- Glyph of Windfury Weapon
        [57253] = {d = {61288}}, -- Glyph of Thunderstorm
        [57257] = {t = 3020}, -- Glyph of Incinerate
        [57258] = {d = {61177, 61756}}, -- Glyph of Conflagrate
        [57259] = {t = 3020}, -- Glyph of Corruption
        [57260] = {d = {61177, 61756}}, -- Glyph of Bane of Agony
        [57261] = {d = {61177, 61756}}, -- Glyph of Death Coil
        [57262] = {t = 3020}, -- Glyph of Fear
        [57263] = {d = {61177, 61756}}, -- Glyph of Felguard
        [57264] = {d = {61177, 61756}}, -- Glyph of Felhunter
        [57265] = {t = 3020}, -- Glyph of Health Funnel
        [57266] = {t = 3020}, -- Glyph of Healthstone
        [57267] = {d = {61177, 61756}}, -- Glyph of Howl of Terror
        [57268] = {d = {61177, 61756}}, -- Glyph of Immolate
        [57269] = {t = 3020}, -- Glyph of Imp
        [57270] = {t = 3020}, -- Glyph of Soul Swap
        [57271] = {t = 3020}, -- Glyph of Shadow Bolt
        [57272] = {t = 3020}, -- Glyph of Shadowburn
        [57273] = {d = {61177, 61756}}, -- Glyph of Siphon Life
        [57274] = {t = 3020}, -- Glyph of Soulstone
        [57275] = {t = 3020}, -- Glyph of Seduction
        [57276] = {d = {61177, 61756}}, -- Glyph of Unstable Affliction
        [57277] = {t = 3020}, -- Glyph of Voidwalker
        [57421] = {q = {{13087, 26905, 495, "A"}, {13088, 26989, 3537, "A"}, {13089, 26953, 495, "H"}, {13090, 26972, 3537, "H"}}}, -- Northern Stew
        [57425] = {t = 3004}, -- Transmute: Skyflare Diamond
        [57427] = {t = 3004}, -- Transmute: Earthsiege Diamond
        [57683] = {t = 3002}, -- Fur Lining - Attack Power
        [57690] = {t = 3002}, -- Fur Lining - Stamina
        [57691] = {t = 3002}, -- Fur Lining - Spell Power
        [57692] = {t = 3002}, -- Fur Lining - Fire Resist
        [57694] = {t = 3002}, -- Fur Lining - Frost Resist
        [57696] = {t = 3002}, -- Fur Lining - Shadow Resist
        [57699] = {t = 3002}, -- Fur Lining - Nature Resist
        [57701] = {t = 3002}, -- Fur Lining - Arcane Resist
        [57703] = {t = 3020}, -- Hunter's Ink
        [57704] = {t = 3020}, -- Lion's Ink
        [57706] = {t = 3020}, -- Dawnstar Ink
        [57707] = {t = 3020}, -- Jadefire Ink
        [57708] = {t = 3020}, -- Royal Ink
        [57709] = {t = 3020}, -- Celestial Ink
        [57710] = {t = 3020}, -- Fiery Ink
        [57711] = {t = 3020}, -- Shimmering Ink
        [57712] = {t = 3020}, -- Ink of the Sky
        [57713] = {t = 3020}, -- Ethereal Ink
        [57714] = {t = 3020}, -- Darkflame Ink
        [57715] = {t = 3020}, -- Ink of the Sea
        [57716] = {t = 3020}, -- Snowfall Ink
        [57719] = {d = {61177, 61756}}, -- Glyph of Fire Blast
        [58065] = {t = 3007}, -- Dalaran Clam Chowder
        [58141] = {t = 3018}, -- Crystal Citrine Necklace
        [58142] = {t = 3018}, -- Crystal Chalcedony Amulet
        [58143] = {t = 3018}, -- Earthshadow Ring
        [58144] = {t = 3018}, -- Jade Ring of Slaying
        [58145] = {t = 3018}, -- Stoneguard Band
        [58146] = {t = 3018}, -- Shadowmight Ring
        [58286] = {d = {61288}}, -- Glyph of Aquatic Form
        [58287] = {d = {61288}}, -- Glyph of Challenging Roar
        [58288] = {d = {61288}}, -- Glyph of Unburdened Rebirth
        [58289] = {d = {61288}}, -- Glyph of Thorns
        [58296] = {d = {61288}}, -- Glyph of Mark of the Wild
        [58297] = {d = {61288}}, -- Glyph of Aspect of the Pack
        [58298] = {d = {61288}}, -- Glyph of Scare Beast
        [58299] = {d = {61288}}, -- Glyph of Revive Pet
        [58300] = {d = {61288}}, -- Glyph of Possessed Strength
        [58301] = {d = {61288}}, -- Glyph of Lesser Proportion
        [58302] = {d = {61288}}, -- Glyph of Feign Death
        [58303] = {d = {61288}}, -- Glyph of Arcane Brilliance
        [58305] = {d = {61288}}, -- Glyph of Fire Ward
        [58306] = {d = {61288}}, -- Glyph of Conjuring
        [58307] = {d = {61288}}, -- Glyph of the Monkey
        [58308] = {d = {61288}}, -- Glyph of Slow Fall
        [58310] = {d = {61288}}, -- Glyph of the Penguin
        [58311] = {d = {61288}}, -- Glyph of Blessing of Kings
        [58312] = {d = {61288}}, -- Glyph of Insight
        [58313] = {d = {61288}}, -- Glyph of Lay on Hands
        [58314] = {d = {61288}}, -- Glyph of Blessing of Might
        [58315] = {d = {61288}}, -- Glyph of Truth
        [58316] = {d = {61288}}, -- Glyph of Justice
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
        [58328] = {d = {61288}}, -- Glyph of Poisons
        [58329] = {d = {61288}}, -- Glyph of Astral Recall
        [58330] = {d = {61288}}, -- Glyph of Renewed Life
        [58331] = {d = {61288}}, -- Glyph of Water Breathing
        [58332] = {d = {61288}}, -- Glyph of the Arctic Wolf
        [58333] = {d = {61288}}, -- Glyph of Water Walking
        [58336] = {d = {61288}}, -- Glyph of Unending Breath
        [58337] = {d = {61288}}, -- Glyph of Drain Soul
        [58338] = {d = {61288}}, -- Glyph of Curse of Exhaustion
        [58339] = {d = {61288}}, -- Glyph of Subjugate Demon
        [58340] = {d = {61288}}, -- Glyph of Eye of Kilrogg
        [58341] = {d = {61177, 61288, 61756}}, -- Glyph of Ritual of Souls
        [58342] = {d = {61288}}, -- Glyph of Battle
        [58343] = {d = {61288}}, -- Glyph of Berserker Rage
        [58344] = {t = 3020, d = {61288}}, -- Glyph of Long Charge
        [58345] = {d = {61288}}, -- Glyph of Demoralizing Shout
        [58346] = {t = 3020, d = {61288}}, -- Glyph of Thunder Clap
        [58347] = {d = {61288}}, -- Glyph of Enduring Victory
        [58472] = {t = 3020}, -- Scroll of Agility
        [58473] = {t = 3020}, -- Scroll of Agility II
        [58476] = {t = 3020}, -- Scroll of Agility III
        [58478] = {t = 3020}, -- Scroll of Agility IV
        [58480] = {t = 3020}, -- Scroll of Agility V
        [58481] = {t = 3020}, -- Scroll of Agility VI
        [58482] = {t = 3020}, -- Scroll of Agility VII
        [58483] = {t = 3020}, -- Scroll of Agility VIII
        [58484] = {t = 3020}, -- Scroll of Strength
        [58485] = {t = 3020}, -- Scroll of Strength II
        [58486] = {t = 3020}, -- Scroll of Strength III
        [58487] = {t = 3020}, -- Scroll of Strength IV
        [58488] = {t = 3020}, -- Scroll of Strength V
        [58489] = {t = 3020}, -- Scroll of Strength VI
        [58490] = {t = 3020}, -- Scroll of Strength VII
        [58491] = {t = 3020}, -- Scroll of Strength VIII
        [58565] = {t = 3020}, -- Mystic Tome
        [58868] = {t = 3004}, -- Endless Mana Potion
        [58871] = {t = 3004}, -- Endless Healing Potion
        [59315] = {d = {61288}}, -- Glyph of Dash
        [59326] = {t = 3020, d = {61288}}, -- Glyph of Ghost Wolf
        [59338] = {t = 3020}, -- Glyph of Rune Tap
        [59339] = {t = 3020}, -- Glyph of Blood Boil
        [59340] = {t = 3020}, -- Glyph of Death Strike
        [59387] = {t = 3020}, -- Certificate of Ownership
        [59405] = {t = 3011}, -- Cobalt Skeleton Key
        [59406] = {t = 3011}, -- Titanium Skeleton Key
        [59436] = {t = 3011}, -- Brilliant Saronite Belt
        [59438] = {t = 3011}, -- Brilliant Saronite Bracers
        [59440] = {t = 3011}, -- Brilliant Saronite Pauldrons
        [59441] = {t = 3011}, -- Brilliant Saronite Helm
        [59442] = {t = 3011}, -- Saronite Spellblade
        [59475] = {t = 3020}, -- Tome of the Dawn
        [59478] = {t = 3020}, -- Book of Survival
        [59480] = {t = 3020}, -- Strange Tarot
        [59484] = {t = 3020}, -- Tome of Kings
        [59486] = {t = 3020}, -- Royal Guide of Escape Routes
        [59487] = {t = 3020}, -- Arcane Tarot
        [59488] = {t = 3019}, -- Weapon Vellum II
        [59489] = {t = 3020}, -- Fire Eater's Guide
        [59490] = {t = 3020}, -- Book of Stars
        [59491] = {t = 3020}, -- Shadowy Tarot
        [59493] = {t = 3020}, -- Stormbound Tome
        [59494] = {t = 3020}, -- Manual of Clouds
        [59495] = {t = 3020}, -- Hellfire Tome
        [59496] = {t = 3020}, -- Book of Clever Tricks
        [59497] = {t = 3020}, -- Iron-bound Tome
        [59498] = {t = 3020}, -- Faces of Doom
        [59499] = {t = 3019}, -- Armor Vellum II
        [59500] = {t = 3019}, -- Armor Vellum III
        [59501] = {t = 3019}, -- Weapon Vellum III
        [59502] = {t = 3020}, -- Darkmoon Card
        [59503] = {t = 3020}, -- Greater Darkmoon Card
        [59504] = {t = 3020}, -- Darkmoon Card of the North
        [59559] = {d = {61177, 61756}}, -- Glyph of Holy Wrath
        [59560] = {d = {61177, 61756}}, -- Glyph of Dazing Shield
        [59561] = {d = {61177, 61756}}, -- Glyph of Seal of Truth
        [59582] = {t = 3005}, -- Frostsavage Belt
        [59583] = {t = 3005}, -- Frostsavage Bracers
        [59584] = {t = 3005}, -- Frostsavage Shoulders
        [59585] = {t = 3005}, -- Frostsavage Boots
        [59586] = {t = 3005}, -- Frostsavage Gloves
        [59587] = {t = 3005}, -- Frostsavage Robe
        [59588] = {t = 3005}, -- Frostsavage Leggings
        [59589] = {t = 3005}, -- Frostsavage Cowl
        [59636] = {t = 3016}, -- Enchant Ring - Stamina
        [59759] = {t = 3018}, -- Figurine - Monarch Crab
        [60336] = {t = 3020}, -- Scroll of Recall II
        [60337] = {t = 3020}, -- Scroll of Recall III
        [60350] = {t = 3004}, -- Transmute: Titanium
        [60354] = {d = {60893}}, -- Elixir of Accuracy
        [60355] = {d = {60893}}, -- Elixir of Deadly Strikes
        [60356] = {d = {60893}}, -- Elixir of Mighty Defense
        [60357] = {d = {60893}}, -- Elixir of Expertise
        [60365] = {d = {60893}}, -- Elixir of Armor Piercing
        [60366] = {d = {60893}}, -- Elixir of Lightning Speed
        [60367] = {t = 3004}, -- Elixir of Mighty Thoughts
        [60396] = {t = 3004}, -- Mercurial Alchemist Stone
        [60403] = {t = 3004}, -- Indestructible Alchemist Stone
        [60405] = {t = 3004}, -- Mighty Alchemist Stone
        [60583] = {t = 3002}, -- Jormungar Leg Reinforcements
        [60584] = {t = 3002}, -- Nerubian Leg Reinforcements
        [60599] = {t = 3002}, -- Frostscale Bracers
        [60600] = {t = 3002}, -- Frostscale Helm
        [60601] = {t = 3002}, -- Dark Frostscale Leggings
        [60604] = {t = 3002}, -- Dark Frostscale Breastplate
        [60605] = {t = 3002}, -- Dragonstompers
        [60606] = {t = 3016}, -- Enchant Boots - Assault
        [60607] = {t = 3002}, -- Iceborne Wristguards
        [60608] = {t = 3002}, -- Iceborne Helm
        [60609] = {t = 3016}, -- Enchant Cloak - Speed
        [60611] = {t = 3002}, -- Dark Iceborne Leggings
        [60613] = {t = 3002}, -- Dark Iceborne Chestguard
        [60616] = {t = 3016}, -- Enchant Bracer - Assault
        [60619] = {t = 3016}, -- Runed Titanium Rod
        [60620] = {t = 3002}, -- Bugsquashers
        [60621] = {t = 3016}, -- Enchant Weapon - Greater Potency
        [60622] = {t = 3002}, -- Nerubian Bracers
        [60623] = {t = 3016}, -- Enchant Boots - Icewalker
        [60624] = {t = 3002}, -- Nerubian Helm
        [60627] = {t = 3002}, -- Dark Nerubian Leggings
        [60629] = {t = 3002}, -- Dark Nerubian Chestpiece
        [60630] = {t = 3002}, -- Scaled Icewalkers
        [60631] = {t = 3002}, -- Cloak of Harsh Winds
        [60637] = {t = 3002}, -- Ice Striker's Cloak
        [60640] = {t = 3002}, -- Durable Nerubhide Cape
        [60643] = {t = 3002}, -- Pack of Endless Pockets
        [60645] = {t = 3002}, -- Dragonscale Ammo Pouch
        [60647] = {t = 3002}, -- Nerubian Reinforced Quiver
        [60649] = {t = 3002}, -- Razorstrike Breastplate
        [60651] = {t = 3002}, -- Virulent Spaulders
        [60652] = {t = 3002}, -- Eaglebane Bracers
        [60653] = {t = 3016}, -- Enchant Shield - Greater Intellect
        [60655] = {t = 3002}, -- Nightshock Hood
        [60658] = {t = 3002}, -- Nightshock Girdle
        [60660] = {t = 3002}, -- Leggings of Visceral Strikes
        [60663] = {t = 3016}, -- Enchant Cloak - Major Agility
        [60665] = {t = 3002}, -- Seafoam Gauntlets
        [60666] = {t = 3002}, -- Jormscale Footpads
        [60668] = {t = 3016}, -- Enchant Gloves - Crusher
        [60669] = {t = 3002}, -- Wildscale Breastplate
        [60671] = {t = 3002}, -- Purehorn Spaulders
        [60874] = {t = 3014}, -- Nesingwary 4000
        [60893] = {t = 3004}, -- Northrend Alchemy Research
        [60969] = {t = 3005}, -- Flying Carpet
        [60971] = {t = 3005}, -- Magnificent Flying Carpet
        [60990] = {t = 3005}, -- Glacial Waistband
        [60993] = {t = 3005}, -- Glacial Robe
        [60994] = {t = 3005}, -- Glacial Slippers
        [61008] = {t = 3011}, -- Icebane Chestguard
        [61009] = {t = 3011}, -- Icebane Girdle
        [61010] = {t = 3011}, -- Icebane Treads
        [61117] = {t = 3020}, -- Master's Inscription of the Axe
        [61118] = {t = 3020}, -- Master's Inscription of the Crag
        [61119] = {t = 3020}, -- Master's Inscription of the Pinnacle
        [61120] = {t = 3020}, -- Master's Inscription of the Storm
        [61177] = {t = 3020}, -- Northrend Inscription Research
        [61288] = {t = 3020}, -- Minor Inscription Research
        [61471] = {t = 3014}, -- Diamond-cut Refractor Scope
        [61481] = {t = 3013}, -- Mechanized Snow Goggles
        [61482] = {t = 3014}, -- Mechanized Snow Goggles
        [61483] = {t = 3013}, -- Mechanized Snow Goggles
        [61677] = {d = {61177, 61756}}, -- Glyph of Frostfire
        [62162] = {t = 3020}, -- Glyph of Focus
        [62213] = {t = 3004}, -- Lesser Flask of Resistance
        [62242] = {t = 3018}, -- Icy Prism
        [62271] = {t = 3013}, -- Unbreakable Healing Amplifiers
        [62409] = {t = 3004}, -- Ethereal Oil
        [62410] = {d = {60893}}, -- Elixir of Water Walking
        [62448] = {t = 3002}, -- Earthen Leg Armor
        [62941] = {t = 3018}, -- Prismatic Black Diamond
        [62959] = {t = 3016}, -- Enchant Staff - Spellpower
        [63182] = {t = 3011}, -- Titansteel Spellblade
        [63732] = {t = 3004}, -- Elixir of Minor Accuracy
        [63742] = {t = 3005}, -- Spidersilk Drape
        [63743] = {t = 3018}, -- Amulet of Truesight
        [63746] = {t = 3016}, -- Enchant Boots - Lesser Accuracy
        [63750] = {t = 3014}, -- High-powered Flashlight
        [63765] = {t = 3013}, -- Springy Arachnoweave
        [63770] = {t = 3014}, -- Reticulated Armor Webbing
        [64053] = {t = 3020}, -- Twilight Tome
        [64054] = {q = {{6610, 40589, 440}, {13825, 40589, 440}}}, -- Clamlette Magnifique
        [64246] = {d = {64323}}, -- Glyph of Raptor Strike
        [64247] = {d = {64323}}, -- Glyph of Stoneclaw Totem
        [64248] = {d = {64323}}, -- Glyph of Life Tap
        [64249] = {d = {64323}}, -- Glyph of Scatter Shot
        [64250] = {d = {64323}}, -- Glyph of Soul Link
        [64251] = {d = {64323}}, -- Glyph of Salvation
        [64252] = {d = {64323}}, -- Glyph of Shield Wall
        [64253] = {d = {64323}}, -- Glyph of Master's Call
        [64254] = {d = {64323}}, -- Glyph of Holy Shock
        [64255] = {d = {64323}}, -- Glyph of Furious Sundering
        [64256] = {d = {64323}}, -- Glyph of Barkskin
        [64257] = {d = {64323}}, -- Glyph of Ice Barrier
        [64258] = {t = 3020}, -- Glyph of Monsoon
        [64259] = {t = 3020}, -- Glyph of Desperation
        [64260] = {t = 3020}, -- Glyph of Mutilate
        [64261] = {t = 3020}, -- Glyph of Earth Shield
        [64262] = {t = 3020}, -- Glyph of Shamanistic Rage
        [64266] = {t = 3020}, -- Glyph of Death Coil
        [64267] = {t = 3019}, -- Glyph of Disease
        [64268] = {d = {64323}}, -- Glyph of Berserk
        [64270] = {d = {64323}}, -- Glyph of Wild Growth
        [64271] = {d = {64323}}, -- Glyph of Chimera Shot
        [64273] = {d = {64323}}, -- Glyph of Explosive Shot
        [64274] = {d = {64323}}, -- Glyph of Deep Freeze
        [64275] = {d = {64323}}, -- Glyph of Slow
        [64276] = {d = {64323}}, -- Glyph of Arcane Barrage
        [64277] = {d = {64323}}, -- Glyph of Beacon of Light
        [64278] = {d = {64323}}, -- Glyph of Hammer of the Righteous
        [64279] = {d = {64323}}, -- Glyph of Templar's Verdict
        [64280] = {d = {64323}}, -- Glyph of Dispersion
        [64281] = {d = {64323}}, -- Glyph of Guardian Spirit
        [64282] = {d = {64323}}, -- Glyph of Penance
        [64283] = {d = {64323}}, -- Glyph of Divine Accuracy
        [64284] = {d = {64323}}, -- Glyph of Vendetta
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
        [64308] = {d = {64323}}, -- Glyph of Shield of the Righteous
        [64309] = {d = {64323}}, -- Glyph of Spirit Tap
        [64310] = {d = {64323}}, -- Glyph of Tricks of the Trade
        [64311] = {d = {64323}}, -- Glyph of Shadowflame
        [64312] = {d = {64323}}, -- Glyph of Intimidating Shout
        [64313] = {d = {64323}}, -- Glyph of Starsurge
        [64314] = {d = {64323}}, -- Glyph of Mirror Image
        [64315] = {d = {64323}}, -- Glyph of Fan of Knives
        [64316] = {d = {64323}}, -- Glyph of Hex
        [64317] = {d = {64323}}, -- Glyph of Demonic Circle
        [64318] = {d = {64323}}, -- Glyph of Metamorphosis
        [64358] = {t = 3007}, -- Black Jelly
        [64661] = {t = 3002}, -- Borean Leather
        [64725] = {t = 3018}, -- Emerald Choker
        [64726] = {t = 3018}, -- Sky Sapphire Amulet
        [64727] = {t = 3018}, -- Runed Mana Band
        [64728] = {t = 3018}, -- Scarlet Signet
        [64729] = {t = 3005}, -- Frostguard Drape
        [64730] = {t = 3005}, -- Cloak of Crimson Snow
        [65245] = {d = {64323}}, -- Glyph of Survival Instincts
        [66430] = {t = 3017}, -- Purified Dreadstone
        [66433] = {t = 3017}, -- Purified Dreadstone
        [66436] = {t = 3017}, -- Misty Eye of Zul
        [66437] = {t = 3017}, -- Lightning Eye of Zul
        [66438] = {t = 3017}, -- Radiant Eye of Zul
        [66440] = {t = 3017}, -- Energized Eye of Zul
        [66444] = {t = 3017}, -- Turbid Eye of Zul
        [66449] = {t = 3017}, -- Delicate Cardinal Ruby
        [66451] = {t = 3017}, -- Smooth King's Amber
        [66500] = {t = 3017}, -- Sparkling Majestic Zircon
        [66503] = {t = 3017}, -- Brilliant Cardinal Ruby
        [66504] = {t = 3017}, -- Subtle King's Amber
        [66553] = {t = 3017}, -- Shifting Dreadstone
        [66555] = {t = 3017}, -- Timeless Dreadstone
        [66558] = {t = 3017}, -- Purified Dreadstone
        [66559] = {t = 3017}, -- Regal Eye of Zul
        [66563] = {t = 3017}, -- Jagged Eye of Zul
        [66564] = {t = 3017}, -- Glinting Dreadstone
        [66565] = {t = 3017}, -- Glinting Dreadstone
        [66566] = {t = 3017}, -- Purified Dreadstone
        [66575] = {t = 3017}, -- Glinting Dreadstone
        [66577] = {t = 3017}, -- Deadly Ametrine
        [66578] = {t = 3017}, -- Stalwart Ametrine
        [66580] = {t = 3017}, -- Lucent Ametrine
        [66587] = {t = 3017}, -- Deft Ametrine
        [66658] = {t = 3004}, -- Transmute: Ametrine
        [66659] = {q = {{14151, 28703, 4395}}}, -- Transmute: Cardinal Ruby
        [66660] = {t = 3004}, -- Transmute: King's Amber
        [66662] = {t = 3004}, -- Transmute: Dreadstone
        [66663] = {t = 3004}, -- Transmute: Majestic Zircon
        [66664] = {t = 3004}, -- Transmute: Eye of Zul
        [67025] = {t = 3004}, -- Flask of the North
        [67326] = {t = 3014}, -- Goblin Beam Welder
        [67600] = {t = 3020}, -- Glyph of Ferocious Bite
        [67790] = {t = 3013}, -- Dimensional Folder: K3
        [67839] = {t = 3014}, -- Mind Amplification Dish
        [67920] = {t = 3014}, -- Wormhole Generator: Northrend
        [68166] = {d = {61288}}, -- Glyph of Command
        [69385] = {t = 3020}, -- Runescroll of Fortitude
        [69386] = {t = 3002}, -- Drums of Forgotten Kings
        [69388] = {t = 3002}, -- Drums of the Wild
        [69412] = {t = 3016}, -- Abyssal Shatter
        [70524] = {t = 3009}, -- Enchanted Thorium Bar
        [71015] = {t = 3019}, -- Glyph of Rapid Rejuvenation
        [72952] = {t = 3013}, -- Shatter Rounds
        [72953] = {t = 3013}, -- Iceblade Arrow
        [73222] = {t = 3018}, -- Bold Carnelian
        [73223] = {t = 3018}, -- Delicate Carnelian
        [73225] = {t = 3018}, -- Brilliant Carnelian
        [73226] = {t = 3018}, -- Precise Carnelian
        [73227] = {t = 3018}, -- Solid Zephyrite
        [73228] = {t = 3018}, -- Sparkling Zephyrite
        [73230] = {t = 3018}, -- Rigid Zephyrite
        [73232] = {t = 3018}, -- Smooth Alicite
        [73233] = {t = 3017}, -- Mystic Alicite
        [73234] = {t = 3018}, -- Quick Alicite
        [73239] = {t = 3018}, -- Fractured Alicite
        [73240] = {t = 3018}, -- Sovereign Nightstone
        [73241] = {t = 3018}, -- Shifting Nightstone
        [73243] = {t = 3018}, -- Timeless Nightstone
        [73246] = {t = 3018}, -- Etched Nightstone
        [73247] = {t = 3018}, -- Glinting Nightstone
        [73249] = {t = 3018}, -- Veiled Nightstone
        [73250] = {t = 3018}, -- Accurate Nightstone
        [73259] = {t = 3017}, -- Resolute Hessonite
        [73266] = {t = 3018}, -- Reckless Hessonite
        [73267] = {t = 3018}, -- Skillful Hessonite
        [73268] = {t = 3018}, -- Adept Hessonite
        [73270] = {t = 3018}, -- Artful Hessonite
        [73274] = {t = 3018}, -- Jagged Jasper
        [73279] = {t = 3018}, -- Puissant Jasper
        [73281] = {t = 3018}, -- Sensei's Jasper
        [73478] = {t = 3018}, -- Fire Prism
        [73494] = {t = 3018}, -- Jasper Ring
        [73495] = {t = 3018}, -- Hessonite Band
        [73496] = {t = 3018}, -- Alicite Pendant
        [73497] = {t = 3018}, -- Nightstone Choker
        [73620] = {t = 3018}, -- Carnelian Spikes
        [73621] = {t = 3018}, -- The Perforator
        [73622] = {t = 3018}, -- Stardust
        [74132] = {t = 3016}, -- Enchant Gloves - Mastery
        [74189] = {t = 3016}, -- Enchant Boots - Earthen Vitality
        [74191] = {t = 3016}, -- Enchant Chest - Mighty Stats
        [74192] = {t = 3016}, -- Enchant Cloak - Greater Spell Piercing
        [74193] = {t = 3016}, -- Enchant Bracer - Speed
        [74195] = {t = 3016}, -- Enchant Weapon - Mending
        [74197] = {t = 3016}, -- Enchant Weapon - Avalanche
        [74198] = {t = 3016}, -- Enchant Gloves - Haste
        [74199] = {t = 3016}, -- Enchant Boots - Haste
        [74200] = {t = 3016}, -- Enchant Chest - Stamina
        [74201] = {t = 3016}, -- Enchant Bracer - Critical Strike
        [74202] = {t = 3016}, -- Enchant Cloak - Intellect
        [74207] = {t = 3016}, -- Enchant Shield - Protection
        [74211] = {t = 3016}, -- Enchant Weapon - Elemental Slayer
        [74212] = {t = 3016}, -- Enchant Gloves - Exceptional Strength
        [74213] = {t = 3016}, -- Enchant Boots - Major Agility
        [74214] = {t = 3016}, -- Enchant Chest - Mighty Resilience
        [74215] = {t = 3016}, -- Enchant Ring - Strength
        [74216] = {t = 3016}, -- Enchant Ring - Agility
        [74217] = {t = 3016}, -- Enchant Ring - Intellect
        [74218] = {t = 3016}, -- Enchant Ring - Greater Stamina
        [74220] = {t = 3016}, -- Enchant Gloves - Greater Expertise
        [74223] = {t = 3016}, -- Enchant Weapon - Hurricane
        [74225] = {t = 3016}, -- Enchant Weapon - Heartsong
        [74226] = {t = 3016}, -- Enchant Shield - Mastery
        [74229] = {t = 3016}, -- Enchant Bracer - Superior Dodge
        [74230] = {t = 3016}, -- Enchant Cloak - Critical Strike
        [74231] = {t = 3016}, -- Enchant Chest - Exceptional Spirit
        [74232] = {t = 3016}, -- Enchant Bracer - Precision
        [74234] = {t = 3016}, -- Enchant Cloak - Protection
        [74235] = {t = 3016}, -- Enchant Off-Hand - Superior Intellect
        [74236] = {t = 3016}, -- Enchant Boots - Precision
        [74237] = {t = 3016}, -- Enchant Bracer - Exceptional Spirit
        [74238] = {t = 3016}, -- Enchant Boots - Mastery
        [74239] = {t = 3016}, -- Enchant Bracer - Greater Expertise
        [74240] = {t = 3016}, -- Enchant Cloak - Greater Intellect
        [74493] = {t = 3002}, -- Savage Leather
        [74529] = {t = 3009}, -- Smelt Pyrite
        [74530] = {t = 3009}, -- Smelt Elementium
        [74537] = {t = 3009}, -- Smelt Hardened Elementium
        [74556] = {t = 3012}, -- Embersilk Bandage
        [74557] = {t = 3012}, -- Heavy Embersilk Bandage
        [74558] = {t = 3012}, -- Field Bandage: Dense Embersilk
        [74964] = {t = 3005}, -- Bolt of Embersilk Cloth
        [75141] = {t = 3005}, -- Dream of Skywall
        [75142] = {t = 3005}, -- Dream of Deepholm
        [75144] = {t = 3005}, -- Dream of Hyjal
        [75145] = {t = 3005}, -- Dream of Ragnaros
        [75146] = {t = 3005}, -- Dream of Azshara
        [75154] = {t = 3005, a = true}, -- Master's Spellthread
        [75155] = {t = 3005, a = true}, -- Sanctified Spellthread
        [75172] = {t = 3005, a = true}, -- Lightweave Embroidery
        [75175] = {t = 3005, a = true}, -- Darkglow Embroidery
        [75178] = {t = 3005, a = true}, -- Swordguard Embroidery
        [75247] = {t = 3005}, -- Embersilk Net
        [75248] = {t = 3005}, -- Deathsilk Belt
        [75249] = {t = 3005}, -- Deathsilk Bracers
        [75250] = {t = 3005}, -- Enchanted Spellthread
        [75251] = {t = 3005}, -- Deathsilk Shoulders
        [75252] = {t = 3005}, -- Deathsilk Boots
        [75253] = {t = 3005}, -- Deathsilk Gloves
        [75254] = {t = 3005}, -- Deathsilk Leggings
        [75255] = {t = 3005}, -- Ghostly Spellthread
        [75256] = {t = 3005}, -- Deathsilk Cowl
        [75257] = {t = 3005}, -- Deathsilk Robe
        [75258] = {t = 3005}, -- Spiritmend Belt
        [75259] = {t = 3005}, -- Spiritmend Bracers
        [75260] = {t = 3005}, -- Spiritmend Shoulders
        [75261] = {t = 3005}, -- Spiritmend Boots
        [75262] = {t = 3005}, -- Spiritmend Gloves
        [75263] = {t = 3005}, -- Spiritmend Leggings
        [75264] = {t = 3005}, -- Embersilk Bag
        [75265] = {t = 3005}, -- Otherworldly Bag
        [75266] = {t = 3005}, -- Spiritmend Cowl
        [75267] = {t = 3005}, -- Spiritmend Robe
        [75268] = {t = 3005}, -- Hyjal Expedition Bag
        [75269] = {t = 3005}, -- Bloodthirsty Fireweave Belt
        [75270] = {t = 3005}, -- Bloodthirsty Embersilk Bracers
        [75290] = {t = 3005}, -- Bloodthirsty Fireweave Bracers
        [75291] = {t = 3005}, -- Bloodthirsty Embersilk Shoulders
        [75292] = {t = 3005}, -- Bloodthirsty Fireweave Shoulders
        [75293] = {t = 3005}, -- Bloodthirsty Embersilk Belt
        [75294] = {t = 3005}, -- Bloodthirsty Fireweave Boots
        [75295] = {t = 3005}, -- Bloodthirsty Embersilk Gloves
        [75296] = {t = 3005}, -- Bloodthirsty Fireweave Gloves
        [75297] = {t = 3005}, -- Bloodthirsty Embersilk Boots
        [76178] = {t = 3011}, -- Folded Obsidium
        [76179] = {t = 3011}, -- Hardened Obsidium Bracers
        [76180] = {t = 3011}, -- Hardened Obsidium Gauntlets
        [76181] = {t = 3011}, -- Hardened Obsidium Belt
        [76182] = {t = 3011}, -- Hardened Obsidium Boots
        [76258] = {t = 3011}, -- Hardened Obsidium Shoulders
        [76259] = {t = 3011}, -- Hardened Obsidium Legguards
        [76260] = {t = 3011}, -- Hardened Obsidium Helm
        [76261] = {t = 3011}, -- Hardened Obsidium Breastplate
        [76262] = {t = 3011}, -- Redsteel Bracers
        [76263] = {t = 3011}, -- Redsteel Gauntlets
        [76264] = {t = 3011}, -- Redsteel Belt
        [76265] = {t = 3011}, -- Redsteel Boots
        [76266] = {t = 3011}, -- Redsteel Shoulders
        [76267] = {t = 3011}, -- Redsteel Legguards
        [76269] = {t = 3011}, -- Redsteel Helm
        [76270] = {t = 3011}, -- Redsteel Breastplate
        [76280] = {t = 3011}, -- Stormforged Bracers
        [76281] = {t = 3011}, -- Stormforged Gauntlets
        [76283] = {t = 3011}, -- Stormforged Belt
        [76285] = {t = 3011}, -- Stormforged Boots
        [76286] = {t = 3011}, -- Stormforged Shoulders
        [76287] = {t = 3011}, -- Stormforged Legguards
        [76288] = {t = 3011}, -- Stormforged Helm
        [76289] = {t = 3011}, -- Stormforged Breastplate
        [76291] = {t = 3011}, -- Hardened Obsidium Shield
        [76293] = {t = 3011}, -- Stormforged Shield
        [76433] = {t = 3011}, -- Decapitator's Razor
        [76434] = {t = 3011}, -- Cold-Forged Shank
        [76435] = {t = 3011}, -- Fire-Etched Dagger
        [76436] = {t = 3011}, -- Lifeforce Hammer
        [76437] = {t = 3011}, -- Obsidium Executioner
        [76438] = {t = 3011}, -- Obsidium Skeleton Key
        [76441] = {t = 3011}, -- Elementium Shield Spike
        [76474] = {t = 3011}, -- Obsidium Bladespear
        [78379] = {t = 3002}, -- Savage Armor Kit
        [78380] = {t = 3002}, -- Savage Cloak
        [78388] = {t = 3002}, -- Tsunami Bracers
        [78396] = {t = 3002}, -- Tsunami Belt
        [78398] = {t = 3002}, -- Darkbrand Bracers
        [78399] = {t = 3002}, -- Darkbrand Gloves
        [78405] = {t = 3002}, -- Hardened Scale Cloak
        [78406] = {t = 3002}, -- Tsunami Gloves
        [78407] = {t = 3002}, -- Darkbrand Boots
        [78410] = {t = 3002}, -- Tsunami Boots
        [78411] = {t = 3002}, -- Darkbrand Shoulders
        [78415] = {t = 3002}, -- Tsunami Shoulders
        [78416] = {t = 3002}, -- Darkbrand Belt
        [78419] = {t = 3002}, -- Scorched Leg Armor
        [78420] = {t = 3002}, -- Twilight Leg Armor
        [78423] = {t = 3002}, -- Tsunami Chestguard
        [78424] = {t = 3002}, -- Darkbrand Helm
        [78427] = {t = 3002}, -- Tsunami Leggings
        [78428] = {t = 3002}, -- Darkbrand Chestguard
        [78432] = {t = 3002}, -- Tsunami Helm
        [78433] = {t = 3002}, -- Darkbrand Leggings
        [78436] = {t = 3002}, -- Heavy Savage Leather
        [78437] = {t = 3002}, -- Heavy Savage Armor Kit
        [78438] = {t = 3002}, -- Cloak of Beasts
        [78439] = {t = 3002}, -- Cloak of War
        [78866] = {t = 3004}, -- Transmute: Living Elements
        [80237] = {t = 3004}, -- Transmute: Shadowspirit Diamond
        [80243] = {t = 3004}, -- Transmute: Truegold
        [80244] = {t = 3004}, -- Transmute: Pyrium Bar
        [80245] = {t = 3004}, -- Transmute: Inferno Ruby
        [80246] = {t = 3004}, -- Transmute: Ocean Sapphire
        [80247] = {t = 3004}, -- Transmute: Amberjewel
        [80248] = {t = 3004}, -- Transmute: Demonseye
        [80250] = {t = 3004}, -- Transmute: Ember Topaz
        [80251] = {t = 3004}, -- Transmute: Dream Emerald
        [80269] = {t = 3004}, -- Potion of Illusion
        [80477] = {t = 3004}, -- Ghost Elixir
        [80478] = {t = 3004}, -- Earthen Potion
        [80479] = {t = 3004}, -- Deathblood Venom
        [80480] = {t = 3004}, -- Elixir of the Naga
        [80481] = {t = 3004}, -- Volcanic Potion
        [80482] = {t = 3004}, -- Potion of Concentration
        [80484] = {t = 3004}, -- Elixir of the Cobra
        [80486] = {t = 3004}, -- Deepstone Oil
        [80487] = {t = 3004}, -- Mysterious Potion
        [80488] = {t = 3004}, -- Elixir of Deep Earth
        [80490] = {t = 3004}, -- Mighty Rejuvenation Potion
        [80491] = {t = 3004}, -- Elixir of Impossible Accuracy
        [80492] = {t = 3004}, -- Prismatic Elixir
        [80493] = {t = 3004}, -- Elixir of Mighty Speed
        [80494] = {t = 3004}, -- Mythical Mana Potion
        [80495] = {t = 3004}, -- Potion of the Tol'vir
        [80496] = {t = 3004}, -- Golemblood Potion
        [80497] = {t = 3004}, -- Elixir of the Master
        [80498] = {t = 3004}, -- Mythical Healing Potion
        [80508] = {t = 3004}, -- Lifebound Alchemist Stone
        [80719] = {t = 3004}, -- Flask of Steelskin
        [80720] = {t = 3004}, -- Flask of the Draconic Mind
        [80721] = {t = 3004}, -- Flask of the Winds
        [80723] = {t = 3004}, -- Flask of Titanic Strength
        [80725] = {t = 3004}, -- Potion of Deepholm
        [80726] = {t = 3004}, -- Potion of Treasure Finding
        [81714] = {t = 3013}, -- Reinforced Bio-Optic Killshades
        [81715] = {t = 3013}, -- Specialized Bio-Optic Killshades
        [81716] = {t = 3014}, -- Deadly Bio-Optic Killshades
        [81720] = {t = 3014}, -- Energized Bio-Optic Killshades
        [81722] = {t = 3013}, -- Agile Bio-Optic Killshades
        [81724] = {t = 3013}, -- Camouflage Bio-Optic Killshades
        [81725] = {t = 3013}, -- Lightweight Bio-Optic Killshades
        [82175] = {t = 3013}, -- Synapse Springs
        [82177] = {t = 3013}, -- Quickflip Deflection Plates
        [82180] = {t = 3013}, -- Tazik Shocker
        [82200] = {t = 3013}, -- Spinal Healing Injector
        [82207] = {t = 3013}, -- Explosive Bolts
        [84038] = {t = 3009}, -- Smelt Obsidium
        [84403] = {t = 3014}, -- Handful of Obsidium Bolts
        [84406] = {t = 3014}, -- Authentic Jr. Engineer Goggles
        [84408] = {t = 3014}, -- R19 Threatfinder
        [84409] = {t = 3014}, -- Volatile Seaforium Blastpack
        [84410] = {t = 3014}, -- Safety Catch Removal Kit
        [84411] = {t = 3014}, -- High-Powered Bolt Gun
        [84412] = {t = 3014}, -- Personal World Destroyer
        [84413] = {t = 3014}, -- De-Weaponized Mechanical Companion
        [84415] = {t = 3014}, -- Lure Master Tackle Box
        [84416] = {t = 3014}, -- Elementium Toolbox
        [84417] = {t = 3014}, -- Volatile Thunderstick
        [84418] = {t = 3014}, -- Elementium Dragonling
        [84420] = {t = 3014}, -- Finely-Tuned Throat Needler
        [84421] = {t = 3014}, -- Loot-a-Rang
        [84424] = {t = 3013}, -- Invisibility Field
        [84425] = {t = 3013}, -- Cardboard Assassin
        [84427] = {t = 3013}, -- Grounded Plasma Shield
        [84428] = {t = 3014}, -- Gnomish X-Ray Scope
        [84429] = {t = 3014}, -- Goblin Barbecue
        [84430] = {t = 3014}, -- Heat-Treated Spinning Lure
        [84431] = {t = 3014}, -- Overpowered Chicken Splitter
        [84432] = {t = 3014}, -- Kickback 5000
        [84950] = {t = 3002}, -- Savage Leather
        [85007] = {t = 3002, a = true}, -- Draconic Embossment - Stamina
        [85008] = {t = 3002, a = true}, -- Draconic Embossment - Agility
        [85009] = {t = 3002, a = true}, -- Draconic Embossment - Strength
        [85010] = {t = 3002, a = true}, -- Draconic Embossment - Intellect
        [85785] = {t = 3020}, -- Runescroll of Fortitude II
        [86004] = {t = 3020}, -- Blackfallow Ink
        [86005] = {t = 3020}, -- Inferno Ink
        [86375] = {t = 3020}, -- Swiftsteel Inscription
        [86401] = {t = 3020}, -- Lionsmane Inscription
        [86402] = {t = 3020}, -- Inscription of the Earth Prince
        [86403] = {t = 3020}, -- Felfire Inscription
        [86609] = {t = 3020}, -- Mysterious Fortune Card
        [86615] = {t = 3020}, -- Darkmoon Card of Destruction
        [86616] = {t = 3020}, -- Book of Blood
        [86640] = {t = 3020}, -- Lord Rottington's Pressed Wisp Book
        [86641] = {t = 3020}, -- Dungeoneering Guide
        [86642] = {t = 3020}, -- Divine Companion
        [86643] = {t = 3020}, -- Battle Tome
        [86648] = {t = 3020}, -- Manual of the Planes
        [86649] = {t = 3020}, -- Runed Dragonscale
        [86652] = {t = 3020}, -- Tattooed Eyeball
        [86653] = {t = 3020}, -- Silver Inlaid Leaf
        [86654] = {t = 3019}, -- Forged Documents
        [88006] = {t = 3007}, -- Blackened Surprise
        [88015] = {t = 3007}, -- Darkbrew Lager
        [88893] = {t = 3012}, -- Dense Embersilk Bandage
        [89244] = {t = 3020}, -- Forged Documents
        [89368] = {t = 3020}, -- Scroll of Intellect IX
        [89369] = {t = 3020}, -- Scroll of Strength IX
        [89370] = {t = 3020}, -- Scroll of Agility IX
        [89371] = {t = 3020}, -- Scroll of Spirit IX
        [89372] = {t = 3020}, -- Scroll of Stamina IX
        [89373] = {t = 3020}, -- Scroll of Protection IX
        [92026] = {t = 3020}, -- Vanishing Powder
        [92027] = {t = 3020}, -- Dust of Disappearance
        [92579] = {t = 3020}, -- Glyph of Blind
        [93741] = {t = 3007}, -- Venison Jerky
        [93935] = {t = 3004}, -- Draught of War
        [94000] = {t = 3019}, -- Glyph of Living Bomb
        [94162] = {t = 3004}, -- Flask of Flowing Water
        [94401] = {t = 3020}, -- Glyph of Tiger's Fury
        [94402] = {t = 3020}, -- Glyph of Lacerate
        [94403] = {t = 3020}, -- Glyph of Faerie Fire
        [94404] = {t = 3020}, -- Glyph of Feral Charge
        [94405] = {t = 3020}, -- Glyph of Death Wish
        [94406] = {t = 3020}, -- Glyph of Intercept
        [94711] = {t = 3019}, -- Glyph of Vanish
        [94743] = {t = 3005}, -- Dream of Destruction
        [94748] = {t = 3014}, -- Electrified Ether
        [95215] = {t = 3019}, -- Glyph of the Treant
        [95471] = {t = 3016}, -- Enchant 2H Weapon - Mighty Agility
        [95703] = {t = 3014}, -- Electrostatic Condenser
        [95705] = {t = 3014}, -- Gnomish Gravity Well
        [95707] = {t = 3014}, -- Big Daddy
        [95710] = {t = 3019}, -- Glyph of Armors
        [95825] = {t = 3019}, -- Glyph of the Long Word
        [96252] = {t = 3004}, -- Volatile Alchemist Stone
        [96253] = {t = 3004}, -- Quicksilver Alchemist Stone
        [96254] = {t = 3004}, -- Vibrant Alchemist Stone
        [96284] = {t = 3020}, -- Glyph of Dark Succor
        [98398] = {t = 3019}, -- Glyph of Frost Armor
        [99535] = {t = 3002}, -- Vicious Hide Cloak
        [99536] = {t = 3002}, -- Vicious Fur Cloak
        [99537] = {t = 3005}, -- Vicious Embersilk Cape
        [99539] = {t = 3018}, -- Vicious Sapphire Ring
        [99540] = {t = 3018}, -- Vicious Amberjewel Band
        [99541] = {t = 3018}, -- Vicious Ruby Signet
        [99542] = {t = 3018}, -- Vicious Sapphire Necklace
        [99543] = {t = 3018}, -- Vicious Amberjewel Pendant
        [99544] = {t = 3018}, -- Vicious Ruby Choker
        [101057] = {t = 3019}, -- Glyph of Unleashed Lightning
        [104698] = {t = 3016}, -- Maelstrom Shatter
        [107907] = {t = 3019}, -- Glyph of Shadow
    },
};

_G.professionMaster:CreateModel("skill-sources-cata", cataSkillSources);
