-- ForeverBiSData.lua
-- Curated / verified BiS data.
-- Curated entries placed here override ForeverBiSGenerated.lua.

ForeverBiSData = ForeverBiSData or {}
ForeverBiSData.version = "Beta v1.013"
ForeverBiSData.lists = ForeverBiSData.lists or {}

-- Example format for future verified lists:
--
-- ForeverBiSData.lists["WARRIOR"] = {
--     ["FURY"] = {
--         ["PRE_RAID"] = {
--             HEAD = {
--                 itemID = 12345,
--                 name = "Item Name",
--                 source = "Boss / Quest / Vendor / Location",
--                 alternatives = {23456, 34567},
--             },
--         },
--     },
-- }
--
-- Leave this file empty until a list has been curated/verified.
-- ForeverBiS.lua will automatically fall back to ForeverBiSGenerated.lua.
