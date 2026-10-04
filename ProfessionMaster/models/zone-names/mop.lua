--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Zone name lookup for mop
-- Keyed by zoneId (areaID), used to resolve zone names from recipe-sources data
local zoneNames = {
    [5736] = "The Wandering Isle",
    [5785] = "The Jade Forest",
    [5805] = "Valley of the Four Winds",
    [5840] = "Vale of Eternal Blossoms",
    [5841] = "Kun-Lai Summit",
    [5842] = "Townlong Steppes",
    [5918] = "Shado-Pan Monastery",
    [5956] = "Temple of the Jade Serpent",
    [5963] = "Stormstout Brewery",
    [6006] = "The Veiled Stair",
    [6052] = "Scarlet Halls",
    [6066] = "Scholomance",
    [6067] = "Terrace of Endless Spring",
    [6109] = "Scarlet Monastery",
    [6125] = "Mogu'shan Vaults",
    [6134] = "Krasarang Wilds",
    [6138] = "Dread Wastes",
    [6182] = "Mogu'shan Palace",
    [6208] = "Crypt of Forgotten Kings",
    [6214] = "Siege of Niuzao Temple",
    [6297] = "Heart of Fear",
    [6500] = "Dustwallow Marsh",
    [6507] = "Isle of Thunder",
    [6622] = "Throne of Thunder",
    [6661] = "Isle of Giants",
    [6716] = "Thunder King's Citadel",
    [6141] = "Shrine of Two Moons",
    [6142] = "Shrine of Seven Stars",
    [6757] = "Timeless Isle",
};

_G.professionMaster:CreateModel("zone-names-mop", zoneNames);
