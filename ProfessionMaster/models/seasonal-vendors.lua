--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create seasonal vendors model
-- npc ids of holiday vendors (Winter Veil, Lunar Festival, Day of the Dead, ...),
-- their recipes count as seasonal in the source lists and tooltips; a vendor
-- tuple with the "E" flag in models/recipe-sources marks a single entry instead
_G.professionMaster:CreateModel("seasonal-vendors", {
    -- Feast of Winter Veil (Smokywood Pastures)
    [13420] = true, -- Penney Copperpinch
    [13429] = true, -- Nardstrum Copperpinch
    [13432] = true, -- Seersa Copperpinch
    [13433] = true, -- Wulmort Jinglepocket
    [13435] = true, -- Khole Jinglepocket
    [23010] = true, -- Wolgren Jinglepocket
    [23012] = true, -- Hotoppik Copperpinch
    [23064] = true, -- Eebee Jinglepocket
    -- Lunar Festival
    [15909] = true, -- Fariel Starsong
    [15864] = true, -- Valadar Starsong
    -- Day of the Dead
    [34382] = true, -- Chapman
});
