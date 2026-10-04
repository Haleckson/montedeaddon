--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Quest name lookup for wrath (english fallback; the client resolves localized titles at runtime)
local questNames = {
    [6610] = "Clamlette Surprise",
    [12889] = "The Prototype Console",
    [13087] = "Northern Cooking",
    [13088] = "Northern Cooking",
    [13089] = "Northern Cooking",
    [13090] = "Northern Cooking",
    [13571] = "Fletcher's Lost and Found",
    [13825] = "Clamlette Surprise",
    [13843] = "The Scrapbot Construction Kit",
    [14151] = "Cardinal Ruby",
};

_G.professionMaster:CreateModel("quest-names-wrath", questNames);
