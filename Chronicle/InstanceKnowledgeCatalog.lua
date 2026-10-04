local C = _G.Chronicle

-- The hand-curated early dungeons remain authoritative. The client's Encounter
-- Journal supplies additional dungeons and raids for the current Forever build.
C.raidKnowledge = C.raidKnowledge or {}
C.raidKnowledgeOrder = C.raidKnowledgeOrder or {}
local canonicalNames = { ["The Hall of Thanes"] = "Hall of Thanes",
    ["Deadmines"] = "The Deadmines",
    ["Excavation Site"] = "Excavation Site: Wetlands",
    ["The Stockade"] = "Stormwind Stockade",
    ["The Stockades"] = "Stormwind Stockade" }

local function journalEntries(raid)
    local entries = {}
    local seen = {}
    if not EJ_GetInstanceByIndex then return entries end
    for index = 1, 200 do
        local ok, id, name, description, background, buttonImage, loreImage =
            pcall(EJ_GetInstanceByIndex, index, raid)
        if not ok or not id then break end
        if type(name) == "string" and name ~= "" and not seen[id] then
            seen[id] = true
            local art = (background and background ~= 0 and background) or
                (loreImage and loreImage ~= 0 and loreImage) or
                (buttonImage and buttonImage ~= 0 and buttonImage) or
                "Interface\\AddOns\\Chronicle\\Motif_Dungeons"
            entries[#entries + 1] = {
                id = id, name = name, description = description,
                icon = art,
            }
        end
    end
    return entries
end

local function encounterLoot(encounterID)
    local loot = {}
    local modern = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex
    if not EJ_SelectEncounter or not EJ_GetNumLoot or
        (not EJ_GetLootInfoByIndex and not modern) then
        return loot
    end
    if not pcall(EJ_SelectEncounter, encounterID) then return loot end
    local ok, count = pcall(EJ_GetNumLoot)
    if not ok or type(count) ~= "number" then return loot end
    for index = 1, math.min(count, 100) do
        local got, first, _, third, _, fifth, _, seventh
        if modern then
            got, first = pcall(modern, index)
        else
            got, first, _, third, _, fifth, _, seventh = pcall(EJ_GetLootInfoByIndex, index)
        end
        if got then
            local itemID = type(first) == "table" and first.itemID or
                type(first) == "number" and first or
                type(seventh) == "number" and seventh or nil
            local name = type(first) == "table" and first.name or
                type(third) == "string" and third or
                type(first) == "string" and first or nil
            local link = type(first) == "table" and first.link or
                type(seventh) == "string" and seventh or ""
            if itemID then
                loot[#loot + 1] = { itemID, name or (GetItemInfo and GetItemInfo(itemID)) or
                    ("Item #" .. itemID), link }
            end
        end
    end
    return loot
end

local function encounters(instanceID)
    local bosses = {}
    if not EJ_SelectInstance or not EJ_GetEncounterInfoByIndex then return bosses end
    if not pcall(EJ_SelectInstance, instanceID) then return bosses end
    for index = 1, 60 do
        local ok, name, description, encounterID =
            pcall(EJ_GetEncounterInfoByIndex, index, instanceID)
        if not ok or not name or not encounterID then
            ok, name, description, encounterID = pcall(EJ_GetEncounterInfoByIndex, index)
        end
        if not ok or not name or not encounterID then break end
        local displayID
        if EJ_GetCreatureInfo then
            local creatureOK, _, _, _, creatureDisplayID =
                pcall(EJ_GetCreatureInfo, 1, encounterID)
            if creatureOK and type(creatureDisplayID) == "number" and creatureDisplayID > 0 then
                displayID = creatureDisplayID
            end
        end
        bosses[#bosses + 1] = {
            name = name, description = description, encounterID = encounterID,
            displayID = displayID, loot = {},
        }
    end
    return bosses
end

function C:RefreshInstanceKnowledge()
    if not EJ_GetInstanceByIndex then
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal")
        elseif LoadAddOn then
            pcall(LoadAddOn, "Blizzard_EncounterJournal")
        end
    end
    if self.instanceKnowledgeReady or not EJ_GetInstanceByIndex then return end
    local oldTier = EJ_GetCurrentTier and EJ_GetCurrentTier()
    local found = 0
    local ok = pcall(function()
        local tiers = EJ_GetNumTiers and EJ_GetNumTiers() or 1
        for tier = 1, math.max(1, tiers) do
            if EJ_SelectTier then pcall(EJ_SelectTier, tier) end
            for _, raid in ipairs({ false, true }) do
                local catalog = raid and self.raidKnowledge or self.dungeonKnowledge
                local order = raid and self.raidKnowledgeOrder or self.dungeonKnowledgeOrder
                local known = {}
                for _, name in ipairs(order) do known[name:lower()] = true end
                for _, info in ipairs(journalEntries(raid)) do
                    local name = canonicalNames[info.name] or info.name
                    local liveBosses = encounters(info.id)
                    if not catalog[name] then
                        catalog[name] = {
                            description = info.description, icon = info.icon,
                            bosses = liveBosses, quests = {},
                            instanceID = info.id, journalTier = tier,
                            journalSource = true,
                        }
                    elseif catalog[name].atlasSource and #liveBosses > 0 then
                        local entry = catalog[name]
                        local matched = {}
                        for _, liveBoss in ipairs(liveBosses) do
                            for _, savedBoss in ipairs(entry.bosses or {}) do
                                if liveBoss.name:lower() == savedBoss.name:lower() then
                                    liveBoss.loot = savedBoss.loot or {}
                                    liveBoss.displayID = liveBoss.displayID or savedBoss.displayID
                                    matched[savedBoss] = true
                                    break
                                end
                            end
                        end
                        for _, savedBoss in ipairs(entry.bosses or {}) do
                            if not matched[savedBoss] then liveBosses[#liveBosses + 1] = savedBoss end
                        end
                        entry.bosses = liveBosses
                        entry.description = info.description
                        entry.icon = info.icon
                        entry.instanceID = info.id
                        entry.journalTier = tier
                        entry.journalSource = true
                        entry.atlasSource = nil
                        entry.preview = nil
                    end
                    if not known[name:lower()] then
                        order[#order + 1] = name
                        known[name:lower()] = true
                    end
                    found = found + 1
                end
            end
        end
    end)
    if oldTier and EJ_SelectTier then pcall(EJ_SelectTier, oldTier) end
    self.instanceKnowledgeReady = ok and found > 0
end

function C:PopulateInstanceKnowledgeLoot(data)
    if not data or not data.journalSource or data.lootReady then return end
    local oldTier = EJ_GetCurrentTier and EJ_GetCurrentTier()
    if data.journalTier and EJ_SelectTier then pcall(EJ_SelectTier, data.journalTier) end
    if EJ_SelectInstance then pcall(EJ_SelectInstance, data.instanceID) end
    local found = 0
    for _, boss in ipairs(data.bosses or {}) do
        local liveLoot = boss.encounterID and encounterLoot(boss.encounterID) or {}
        if #liveLoot > 0 then
            local known = {}
            for _, item in ipairs(liveLoot) do known[item[1]] = true end
            for _, item in ipairs(boss.loot or {}) do
                if not known[item[1]] then liveLoot[#liveLoot + 1] = item end
            end
            boss.loot = liveLoot
        end
        found = found + #boss.loot
    end
    if oldTier and EJ_SelectTier then pcall(EJ_SelectTier, oldTier) end
    -- The journal can deliver item data later; retry when the detail is reopened.
    data.lootReady = found > 0
end
