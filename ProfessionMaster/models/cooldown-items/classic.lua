--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create cooldown items model of the classic clients (vanilla to mop)
-- maps item IDs that have profession-related use-cooldowns (scanned from bags)
-- format: [itemId] = { professionId = skillLineId, spellId = spellId }
local addon = _G.professionMaster;
local cooldownItems = {};

-- Vanilla/TBC: Salt Shaker (Leatherworking, creates Refined Deeprock Salt)
if (addon.isVanilla or addon.isBcc) then
    cooldownItems[15846] = { professionId = 165, spellId = 19566, maxDuration = 259200 }; -- 3 days
end

addon:CreateModel("cooldown-items", cooldownItems);
