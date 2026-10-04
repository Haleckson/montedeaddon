--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Quest name lookup for cata (english fallback; the client resolves localized titles at runtime)
local questNames = {
    [26620] = "Seasoned Wolf Kabobs",
    [26623] = "Dusky Crab Cakes",
    [26860] = "Thelsamar Blood Sausages",
};

_G.professionMaster:CreateModel("quest-names-cata", questNames);
