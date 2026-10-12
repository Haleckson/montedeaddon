-- Reviewed Forever additions, 2026-10-11. Kept apart from generated imports.
-- Source: https://www.wowhead.com/forever/item=282047/baby-crocolisk
-- https://www.wowhead.com/forever/news/earn-two-new-pets-in-capital-cities-in-wow-forever-383170
local _, FC = ...
local R = FC.ReferenceData
-- Common containers missing from the imported object list. No invented
-- fixed coordinates: these object IDs spawn at many different locations.
-- Each ID checked in Wowhead's /forever/object=<id> database.
local chests = { [2843]="Battered Chest", [2849]="Battered Chest",
    [2850]="Solid Chest", [4149]="Solid Chest", [74448]="Large Solid Chest" }
R.reviewedContainers = chests
for id, name in pairs(chests) do
    R.objects[id] = R.objects[id] or {n=name,t=1}
    R.objectNames[id] = R.objectNames[id] or name
end
-- A creature drop belongs in its loot table, not in the Secrets catalogue.
local beast = R.npcs[3581]
if beast then
    beast.d = beast.d or {}
    local present = false
    for _, id in ipairs(beast.d) do if id == 282047 then present = true end end
    if not present then beast.d[#beast.d + 1] = 282047 end
end
