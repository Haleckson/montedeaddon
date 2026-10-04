--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create cooldown items model of wow forever
-- maps item IDs that have profession-related use-cooldowns (scanned from bags)
-- format: [itemId] = { professionId = skillLineId, spellId = spellId }
local cooldownItems = {};

-- Salt Shaker (Leatherworking, creates Refined Deeprock Salt)
cooldownItems[15846] = { professionId = 165, spellId = 19566, maxDuration = 255600 }; -- 71 hours

_G.professionMaster:CreateModel("cooldown-items", cooldownItems);
