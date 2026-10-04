--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create self only skills model
-- recipes that only work on the equipment of the crafter: the game marks them
-- as "enchant own item only" and most of them also require the profession to
-- wear, so nobody can make them for someone else. the !who answers leave them
-- out. format: [spellId] = true
_G.professionMaster:CreateModel("self-only-skills", {
    -- blacksmithing
    [55628] = true, -- Socket Bracer
    [55641] = true, -- Socket Gloves
    [113263] = true, -- Socket Bracer
    [114112] = true, -- Socket Gloves
    -- leatherworking
    [57683] = true, -- Fur Lining - Agility
    [57690] = true, -- Fur Lining - Stamina
    [57691] = true, -- Fur Lining - Intellect
    [57692] = true, -- Fur Lining - Fire Resist
    [57694] = true, -- Fur Lining - Frost Resist
    [57696] = true, -- Fur Lining - Shadow Resist
    [57699] = true, -- Fur Lining - Nature Resist
    [57701] = true, -- Fur Lining - Arcane Resist
    [60583] = true, -- Jormungar Leg Reinforcements
    [60584] = true, -- Nerubian Leg Reinforcements
    [85007] = true, -- Fur Lining - Stamina
    [85008] = true, -- Fur Lining - Agility
    [85009] = true, -- Fur Lining - Strength
    [85010] = true, -- Fur Lining - Intellect
    [124549] = true, -- Fur Lining - Strength
    [124551] = true, -- Fur Lining - Agility
    [124552] = true, -- Fur Lining - Intellect
    [124553] = true, -- Fur Lining - Stamina
    [124554] = true, -- Fur Lining - Strength
    [124559] = true, -- Primal Leg Reinforcements
    [124561] = true, -- Draconic Leg Reinforcements
    [124563] = true, -- Heavy Leg Reinforcements
    [124564] = true, -- Primal Leg Reinforcements
    [124565] = true, -- Heavy Leg Reinforcements
    [124566] = true, -- Draconic Leg Reinforcements
    [124567] = true, -- Primal Leg Reinforcements
    [124568] = true, -- Heavy Leg Reinforcements
    [124569] = true, -- Draconic Leg Reinforcements
    -- tailoring
    [55642] = true, -- Lightweave Embroidery
    [55769] = true, -- Darkglow Embroidery
    [55777] = true, -- Swordguard Embroidery
    [56034] = true, -- Master's Spellthread
    [56039] = true, -- Sanctified Spellthread
    [75154] = true, -- Master's Spellthread
    [75155] = true, -- Sanctified Spellthread
    [75172] = true, -- Lightweave Embroidery
    [75175] = true, -- Darkglow Embroidery
    [75178] = true, -- Swordguard Embroidery
    [125481] = true, -- Lightweave Embroidery
    [125482] = true, -- Darkglow Embroidery
    [125483] = true, -- Swordguard Embroidery
    [125496] = true, -- Master's Spellthread
    [125497] = true, -- Sanctified Spellthread
    -- engineering
    [1226210] = true, -- Tinker: Teleport
    [1226211] = true, -- Tinker: Nitro Boosts
    [1226212] = true, -- Tinker: Magnetic Displacement
    [54736] = true, -- EMP Generator
    [54793] = true, -- Frag Belt
    [54998] = true, -- Hand-Mounted Pyro Rocket
    [54999] = true, -- Hyperspeed Accelerators
    [55002] = true, -- Flexweave Underlay
    [55016] = true, -- Nitro Boosts
    [63765] = true, -- Springy Arachnoweave
    [63770] = true, -- Reticulated Armor Webbing
    [67839] = true, -- Mind Amplification Dish
    [82175] = true, -- Synapse Springs
    [82177] = true, -- Quickflip Deflection Plates
    [82180] = true, -- Tazik Shocker
    [82200] = true, -- Spinal Healing Injector
    [84424] = true, -- Invisibility Field
    [84425] = true, -- Cardboard Assassin
    [84427] = true, -- Grounded Plasma Shield
    [108789] = true, -- Phase Fingers
    [109077] = true, -- Incendiary Fireworks Launcher
    [109099] = true, -- Watergliding Jets
    [126392] = true, -- Goblin Glider
    [126731] = true, -- Synapse Springs
    -- enchanting
    [27920] = true, -- Enchant Ring - Striking
    [27924] = true, -- Enchant Ring - Minor Intellect
    [27926] = true, -- Enchant Ring - Healing Power
    [27927] = true, -- Enchant Ring - Stats
    [44636] = true, -- Enchant Ring - Lesser Intellect
    [44645] = true, -- Enchant Ring - Assault
    [59636] = true, -- Enchant Ring - Lesser Stamina
    [74215] = true, -- Enchant Ring - Strength
    [74216] = true, -- Enchant Ring - Agility
    [74217] = true, -- Enchant Ring - Intellect
    [74218] = true, -- Enchant Ring - Stamina
    [103461] = true, -- Enchant Ring - Greater Agility
    [103462] = true, -- Enchant Ring - Greater Intellect
    [103463] = true, -- Enchant Ring - Greater Stamina
    [103465] = true, -- Enchant Ring - Greater Strength
    -- inscription
    [61117] = true, -- Master's Inscription of the Axe
    [61118] = true, -- Master's Inscription of the Crag
    [61119] = true, -- Master's Inscription of the Pinnacle
    [61120] = true, -- Master's Inscription of the Storm
    [86375] = true, -- Swiftsteel Inscription
    [86401] = true, -- Lionsmane Inscription
    [86402] = true, -- Inscription of the Earth Prince
    [86403] = true, -- Felfire Inscription
});
