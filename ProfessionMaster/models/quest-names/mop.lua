--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Quest name lookup for mop (english fallback; the client resolves localized titles at runtime)
local questNames = {
    [32621] = "Lightning Steel",
    [33022] = "Catch and Carry",
    [33024] = "Is That A Real Measurement?",
    [33027] = "The Secret Ingredient Is...",
};

_G.professionMaster:CreateModel("quest-names-mop", questNames);
