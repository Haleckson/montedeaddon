--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Quest name lookup for bcc (english fallback; the client resolves localized titles at runtime)
local questNames = {
    [9171] = "Culinary Crunch",
    [9249] = "40 Tickets - Schematic: Steam Tonk Controller",
    [9356] = "Smooth as Butter",
    [9454] = "The Great Moongraze Hunt",
    [9635] = "The Zapthrottle Mote Extractor!",
    [9636] = "The Zapthrottle Mote Extractor!",
    [10860] = "Mok'Nathal Treats",
};

_G.professionMaster:CreateModel("quest-names-bcc", questNames);
