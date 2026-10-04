--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create cooldown spells model of wow forever
-- maps spell IDs that have crafting cooldowns: the vanilla ones, each an hour
-- shorter, iron to gold and mithril to truesilver down to one hour on their own
-- format: [spellId] = professionSkillLineId
local cooldownSpells = {};

cooldownSpells[18560] = 197;      -- Mooncloth (Tailoring)
cooldownSpells[17187] = 171;      -- Transmute: Arcanite (Alchemy)
cooldownSpells[1317279] = 171;    -- Transmute: Legionite (Alchemy)
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

_G.professionMaster:CreateModel("cooldown-spells", cooldownSpells);
