--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Quest name lookup for Season of Discovery (english fallback; the client resolves localized titles at runtime)
local questNames = {
    [1559] = "Flash Bomb Recipe",
    [1578] = "Supplying the Front",
    [89381] = "Pin Cushion",
    [89421] = "Bullet Heaven",
    [89463] = "Nondisclosure Arguement",
    [89471] = "Goblin Tinkering",
    [89485] = "Whimsical Horrors",
    [89486] = "A Pinch of Gunpowder",
    [89487] = "Much Ado About Magnets",
    [90116] = "Holy Threads",
    [90120] = "Red is Not Dead",
};

_G.professionMaster:CreateModel("quest-names-sod", questNames);
