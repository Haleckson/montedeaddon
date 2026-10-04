--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Zone name lookup for Season of Discovery
-- Keyed by zoneId (areaID), used to resolve zone names from recipe-sources data
local zoneNames = {
    [16236] = "Scarlet Enclave",
};

_G.professionMaster:CreateModel("zone-names-sod", zoneNames);
