--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Game object name lookup for cata
local objectNames = {
    [75296] = "Large Iron Bound Chest",
    [75299] = "Large Solid Chest",
    [75300] = "Large Solid Chest",
    [131978] = "Large Mithril Bound Chest",
    [142184] = "Captain's Chest",
    [153468] = "Large Mithril Bound Chest",
    [153469] = "Large Mithril Bound Chest",
    [193603] = "Cache of Eregos",
};

_G.professionMaster:CreateModel("object-names-cata", objectNames);
