--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Game object name lookup for WoW Forever
local objectNames = {
    [2560] = "Half-Buried Bottle",
    [153451] = "Solid Chest",
    [153453] = "Solid Chest",
    [153454] = "Solid Chest",
    [153462] = "Large Solid Chest",
    [173232] = "Blacksmithing Plans",
    [173234] = "Blacksmithing Plans",
    [176325] = "Blacksmithing Plans",
    [176327] = "Blacksmithing Plans",
    [179501] = "Knot Thimblejack's Cache",
    [179552] = "Schematic: Field Repair Bot 74A",
    [179564] = "Gordok Tribute",
    [179697] = "Arena Treasure Chest",
    [180368] = "Tablet of Madness",
    [180794] = "Journal of Jandice Barov",
    [181798] = "Fel Iron Chest",
};

_G.professionMaster:CreateModel("object-names-forever", objectNames);
