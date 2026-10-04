--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create cooldown spells model of the classic clients (vanilla to mop)
-- maps spell IDs that have crafting cooldowns, filtered by expansion
-- each expansion only contains its own cooldowns (previous ones are removed)
-- format: [spellId] = professionSkillLineId
local addon = _G.professionMaster;
local cooldownSpells = {};

-- Vanilla cooldowns (only active in Vanilla)
if (addon.isVanilla) then
    cooldownSpells[18560] = 197;      -- Mooncloth (Tailoring)
    cooldownSpells[17187] = 171;      -- Transmute: Arcanite (Alchemy)
    cooldownSpells[11479] = 171;      -- Transmute: Iron to Gold (Alchemy)
    cooldownSpells[11480] = 171;      -- Transmute: Mithril to Truesilver (Alchemy)
    cooldownSpells[17559] = 171;      -- Transmute: Air to Fire (Alchemy)
    cooldownSpells[17560] = 171;      -- Transmute: Fire to Earth (Alchemy)
    cooldownSpells[17561] = 171;      -- Transmute: Earth to Water (Alchemy)
    cooldownSpells[17562] = 171;      -- Transmute: Water to Air (Alchemy)
    cooldownSpells[17563] = 171;      -- Transmute: Undeath to Water (Alchemy)
    cooldownSpells[17564] = 171;      -- Transmute: Water to Undeath (Alchemy)
    cooldownSpells[17565] = 171;      -- Transmute: Life to Earth (Alchemy)
    cooldownSpells[17566] = 171;      -- Transmute: Earth to Life (Alchemy)
end

-- TBC cooldowns (only active in TBC)
if (addon.isBcc) then
    cooldownSpells[31373] = 197;      -- Spellcloth (Tailoring)
    cooldownSpells[36686] = 197;      -- Shadowcloth (Tailoring)
    cooldownSpells[26751] = 197;      -- Primal Mooncloth (Tailoring)
    cooldownSpells[29688] = 171;      -- Transmute: Primal Might (Alchemy)
    cooldownSpells[28566] = 171;      -- Transmute: Primal Air to Fire (Alchemy)
    cooldownSpells[28567] = 171;      -- Transmute: Primal Earth to Water (Alchemy)
    cooldownSpells[28568] = 171;      -- Transmute: Primal Fire to Earth (Alchemy)
    cooldownSpells[28569] = 171;      -- Transmute: Primal Water to Air (Alchemy)
    cooldownSpells[28580] = 171;      -- Transmute: Primal Shadow to Water (Alchemy)
    cooldownSpells[28581] = 171;      -- Transmute: Primal Water to Shadow (Alchemy)
    cooldownSpells[28582] = 171;      -- Transmute: Primal Mana to Fire (Alchemy)
    cooldownSpells[28583] = 171;      -- Transmute: Primal Fire to Mana (Alchemy)
    cooldownSpells[28584] = 171;      -- Transmute: Primal Life to Earth (Alchemy)
    cooldownSpells[28585] = 171;      -- Transmute: Primal Earth to Life (Alchemy)
    cooldownSpells[32765] = 171;      -- Transmute: Earthstorm Diamond (Alchemy)
    cooldownSpells[32766] = 171;      -- Transmute: Skyfire Diamond (Alchemy)
    cooldownSpells[47280] = 755;      -- Brilliant Glass (Jewelcrafting)
    cooldownSpells[28027] = 333;      -- Prismatic Sphere (Enchanting)
    cooldownSpells[28028] = 333;      -- Void Sphere (Enchanting)
end

-- Wrath cooldowns (only active in Wrath)
if (addon.isWrath) then
    cooldownSpells[56001] = 197;      -- Spellweave (Tailoring)
    cooldownSpells[56002] = 197;      -- Ebonweave (Tailoring)
    cooldownSpells[56003] = 197;      -- Moonshroud (Tailoring)
    cooldownSpells[55208] = 186;      -- Smelt Titansteel (Mining)
    cooldownSpells[53777] = 171;      -- Transmute: Eternal Life to Shadow (Alchemy)
    cooldownSpells[53776] = 171;      -- Transmute: Eternal Life to Fire (Alchemy)
    cooldownSpells[53774] = 171;      -- Transmute: Eternal Fire to Water (Alchemy)
    cooldownSpells[53773] = 171;      -- Transmute: Eternal Fire to Life (Alchemy)
    cooldownSpells[53771] = 171;      -- Transmute: Eternal Earth to Air (Alchemy)
    cooldownSpells[53775] = 171;      -- Transmute: Eternal Earth to Shadow (Alchemy)
    cooldownSpells[53779] = 171;      -- Transmute: Eternal Shadow to Earth (Alchemy)
    cooldownSpells[53778] = 171;      -- Transmute: Eternal Shadow to Life (Alchemy)
    cooldownSpells[53770] = 171;      -- Transmute: Eternal Air to Earth (Alchemy)
    cooldownSpells[53772] = 171;      -- Transmute: Eternal Air to Water (Alchemy)
    cooldownSpells[53783] = 171;      -- Transmute: Eternal Water to Air (Alchemy)
    cooldownSpells[53784] = 171;      -- Transmute: Eternal Water to Fire (Alchemy)
    cooldownSpells[66658] = 171;      -- Transmute: Ametrine (Alchemy)
    cooldownSpells[66659] = 171;      -- Transmute: Cardinal Ruby (Alchemy)
    cooldownSpells[66660] = 171;      -- Transmute: King's Amber (Alchemy)
    cooldownSpells[66662] = 171;      -- Transmute: Dreadstone (Alchemy)
    cooldownSpells[66663] = 171;      -- Transmute: Majestic Zircon (Alchemy)
    cooldownSpells[66664] = 171;      -- Transmute: Eye of Zul (Alchemy)
    cooldownSpells[60893] = 171;      -- Northrend Alchemy Research (Alchemy)
    cooldownSpells[61177] = 773;      -- Northrend Inscription Research (Inscription)
    cooldownSpells[61288] = 773;      -- Minor Inscription Research (Inscription)
    cooldownSpells[62242] = 755;      -- Icy Prism (Jewelcrafting)
    cooldownSpells[56005] = 197;      -- Glacial Bag (Tailoring)
end

-- Cata cooldowns (only active in Cata)
if (addon.isCata) then
    cooldownSpells[75141] = 197;      -- Dream of Skywall (Tailoring)
    cooldownSpells[75142] = 197;      -- Dream of Deepholm (Tailoring)
    cooldownSpells[75144] = 197;      -- Dream of Hyjal (Tailoring)
    cooldownSpells[75145] = 197;      -- Dream of Ragnaros (Tailoring)
    cooldownSpells[75146] = 197;      -- Dream of Azshara (Tailoring)
    cooldownSpells[80243] = 171;      -- Transmute: Truegold (Alchemy)
    cooldownSpells[80244] = 171;      -- Transmute: Pyrium Bar (Alchemy)
    cooldownSpells[78866] = 171;      -- Transmute: Living Elements (Alchemy)
    cooldownSpells[73478] = 755;      -- Fire Prism (Jewelcrafting)
end

-- MoP cooldowns (only active in MoP)
if (addon.isMop) then
    -- note: the "Accelerated" 5.4 variants (146921/146923/146925) have no cooldown
    -- by design (they consume a Spirit of War instead), so they are not tracked
    cooldownSpells[125557] = 197;     -- Imperial Silk (Tailoring)
    cooldownSpells[143011] = 197;     -- Celestial Cloth (Tailoring)
    cooldownSpells[138646] = 164;     -- Lightning Steel Ingot (Blacksmithing)
    cooldownSpells[143255] = 164;     -- Balanced Trillium Ingot (Blacksmithing)
    cooldownSpells[140040] = 165;     -- Magnificence of Leather (Leatherworking)
    cooldownSpells[140041] = 165;     -- Magnificence of Scales (Leatherworking)
    cooldownSpells[142976] = 165;     -- Hardened Magnificent Hide (Leatherworking)
    cooldownSpells[112996] = 773;     -- Scroll of Wisdom (Inscription)
    cooldownSpells[139176] = 202;     -- Jard's Peculiar Energy Source (Engineering)
    cooldownSpells[114780] = 171;     -- Transmute: Living Steel (Alchemy)
    cooldownSpells[140050] = 755;     -- Serpent's Heart (Jewelcrafting)
end

addon:CreateModel("cooldown-spells", cooldownSpells);
