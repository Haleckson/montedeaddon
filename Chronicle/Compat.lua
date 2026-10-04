local C = _G.Chronicle
local U = C.Util
local A = {}
C.API = A

local TALENT_BRANCHES = {
    DRUID = { "Gleichgewicht", "Wilder Kampf", "Wiederherstellung" },
    HUNTER = { "Tierherrschaft", "Treffsicherheit", "Ueberleben" },
    MAGE = { "Arkan", "Feuer", "Frost" },
    PALADIN = { "Heilig", "Schutz", "Vergeltung" },
    PRIEST = { "Disziplin", "Heilig", "Schatten" },
    ROGUE = { "Meucheln", "Kampf", "Taeuschung" },
    SHAMAN = { "Elementar", "Verstaerkung", "Wiederherstellung" },
    WARLOCK = { "Gebrechen", "Daemologie", "Zerstoerung" },
    WARRIOR = { "Waffen", "Furor", "Schutz" },
}

local function talentTreeCuts(positions)
    table.sort(positions)
    local distinct, gaps = {}, {}
    for _, x in ipairs(positions) do
        if distinct[#distinct] ~= x then distinct[#distinct + 1] = x end
    end
    for i = 2, #distinct do
        gaps[#gaps + 1] = { width = distinct[i] - distinct[i - 1],
            cut = (distinct[i] + distinct[i - 1]) / 2 }
    end
    table.sort(gaps, function(a, b) return a.width > b.width end)
    if #gaps < 2 or gaps[2].width < 800 or (#gaps > 2 and gaps[2].width < gaps[3].width * 1.5) then
        return nil
    end
    local left, right = gaps[1].cut, gaps[2].cut
    if left > right then left, right = right, left end
    return left, right
end

function A.TalentSnapshot()
    local snapshot = { learned = {}, totalPoints = 0 }
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecializationInfo then
        local indexOK, index = pcall(C_SpecializationInfo.GetSpecialization)
        if indexOK and type(index) == "number" and index > 0 then
            local infoOK, specID, name, description, icon, role, primaryStat, points = pcall(C_SpecializationInfo.GetSpecializationInfo, index)
            if infoOK and type(name) == "string" and name ~= "" then
                snapshot.specID, snapshot.name, snapshot.icon = specID, name, icon
                snapshot.points = type(points) == "number" and points or nil
            end
        end
    end
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo) then
        return snapshot.name and snapshot or nil
    end
    local configOK, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not configOK or type(configID) ~= "number" or configID <= 0 then
        return snapshot.name and snapshot or nil
    end
    local infoOK, config = pcall(C_Traits.GetConfigInfo, configID)
    if not infoOK or type(config) ~= "table" then return snapshot.name and snapshot or nil end
    if type(config.name) == "string" and config.name ~= "" then snapshot.loadout = config.name end
    if type(config.treeIDs) ~= "table" or not (C_Traits.GetTreeNodes and C_Traits.GetNodeInfo) then
        return (snapshot.name or snapshot.loadout) and snapshot or nil
    end
    local seen, scanned, readNodes, hasPurchaseField = {}, 0, 0, false
    local positions, purchasedNodes = {}, {}
    for _, treeID in ipairs(config.treeIDs) do
        local nodesOK, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
        if nodesOK and type(nodeIDs) == "table" then
            for _, nodeID in ipairs(nodeIDs) do
                scanned = scanned + 1
                if scanned > 300 then break end
                local nodeOK, node = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                if nodeOK and type(node) == "table" and type(node.ID) == "number" and node.ID > 0 then
                    readNodes = readNodes + 1
                    if type(node.ranksPurchased) == "number" then hasPurchaseField = true end
                    local purchased = tonumber(node.ranksPurchased) or 0
                    snapshot.totalPoints = snapshot.totalPoints + purchased
                    local x = tonumber(node.posX)
                    if x then positions[#positions + 1] = x end
                    if x and purchased > 0 then purchasedNodes[#purchasedNodes + 1] = { x = x, points = purchased } end
                    local rank = purchased > 0 and purchased or tonumber(node.currentRank) or tonumber(node.activeRank) or 0
                    local selected = node.activeEntry
                    local entryID = type(node.entryIDsWithCommittedRanks) == "table" and
                        node.entryIDsWithCommittedRanks[1] or nil
                    if not entryID then entryID = type(selected) == "table" and selected.entryID or nil end
                    if rank > 0 and type(entryID) == "number" and not seen[entryID] and
                        C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo then
                        local entryOK, entry = pcall(C_Traits.GetEntryInfo, configID, entryID)
                        if entryOK and type(entry) == "table" and type(entry.definitionID) == "number" then
                            local definitionOK, definition = pcall(C_Traits.GetDefinitionInfo, entry.definitionID)
                            if definitionOK and type(definition) == "table" then
                                local talentName = definition.overrideName
                                if (type(talentName) ~= "string" or talentName == "") and type(definition.spellID) == "number" then
                                    if C_Spell and C_Spell.GetSpellName then
                                        local spellOK, spellName = pcall(C_Spell.GetSpellName, definition.spellID)
                                        if spellOK then talentName = spellName end
                                    elseif GetSpellInfo then
                                        local spellOK, spellName = pcall(GetSpellInfo, definition.spellID)
                                        if spellOK then talentName = spellName end
                                    end
                                end
                                if type(talentName) == "string" and talentName ~= "" then
                                    snapshot.learned[#snapshot.learned + 1] = {
                                        name = talentName, rank = rank, treeID = treeID,
                                        posX = tonumber(node.posX), posY = tonumber(node.posY),
                                    }
                                    seen[entryID] = true
                                end
                            end
                        end
                    end
                end
            end
        end
        if scanned > 300 then break end
    end
    snapshot.traitsRead = readNodes > 0 and hasPurchaseField
    local classFile
    if UnitClass then local className; className, classFile = UnitClass("player") end
    local names = TALENT_BRANCHES[classFile]
    local leftCut, rightCut
    if names then leftCut, rightCut = talentTreeCuts(positions) end
    if leftCut and rightCut then
        snapshot.treeCuts = { leftCut, rightCut }
        local branches = {
            { name = names[1], points = 0 }, { name = names[2], points = 0 }, { name = names[3], points = 0 },
        }
        local assigned = 0
        for _, node in ipairs(purchasedNodes) do
            local index = node.x <= leftCut and 1 or (node.x <= rightCut and 2 or 3)
            branches[index].points = branches[index].points + node.points
            assigned = assigned + node.points
        end
        if assigned == snapshot.totalPoints then snapshot.branches = branches end
    end
    table.sort(snapshot.learned, function(left, right) return left.name < right.name end)
    return (snapshot.name or snapshot.loadout or #snapshot.learned > 0) and snapshot or nil
end

function A.ItemSellPrice(itemID)
    if not itemID then return nil end
    local function read(getter)
        if type(getter) ~= "function" then return nil end
        local ok, _, _, _, _, _, _, _, _, _, _, price = pcall(getter, itemID)
        if ok and type(price) == "number" and price >= 0 then return price end
        return nil
    end
    return read(C_Item and C_Item.GetItemInfo) or read(GetItemInfo)
end

function A.QuestTitle(questID)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, value = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and value and value ~= "" then return value end
    end
    return questID and ("Quest #" .. tostring(questID)) or "Unbekannte Quest"
end

-- Read by index when the client supports it. Older clients may need a
-- temporary selection; restore that selection immediately afterward.
function A.QuestText(questID)
    if not (questID and GetQuestLogQuestText) then return nil end
    local index
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, value = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok then index = value end
    end
    if (not index or index < 1) and GetQuestLogIndexByID then
        local ok, value = pcall(GetQuestLogIndexByID, questID)
        if ok then index = value end
    end
    if type(index) ~= "number" or index < 1 then return nil end
    local previous
    if GetQuestLogSelection then
        local ok, value = pcall(GetQuestLogSelection)
        if ok and type(value) == "number" then previous = value end
    end
    if previous == nil and C_QuestLog and C_QuestLog.GetSelectedQuest then
        local ok, selectedID = pcall(C_QuestLog.GetSelectedQuest)
        if ok and selectedID == 0 then previous = 0
        elseif ok and selectedID and C_QuestLog.GetLogIndexForQuestID then
            local indexOK, value = pcall(C_QuestLog.GetLogIndexForQuestID, selectedID)
            if indexOK then previous = value end
        end
    end
    -- Some clients accept a log index directly. Compare it with the current
    -- selection because older clients silently ignore the extra argument.
    local directOK, directDescription, directObjectives = pcall(GetQuestLogQuestText, index)
    if directOK and ((type(directDescription) == "string" and directDescription ~= "") or
        (type(directObjectives) == "string" and directObjectives ~= "")) then
        local currentOK, currentDescription, currentObjectives = pcall(GetQuestLogQuestText)
        if previous == index or (currentOK and
            (directDescription ~= currentDescription or directObjectives ~= currentObjectives)) then
            return directDescription, directObjectives
        end
    end
    if previous == nil or not SelectQuestLogEntry then return nil end
    local selected = pcall(SelectQuestLogEntry, index)
    if not selected then return nil end
    local textOK, description, objectives = pcall(GetQuestLogQuestText)
    pcall(SelectQuestLogEntry, previous)
    if textOK then return description, objectives end
    return nil
end

function A.ActiveQuests()
    local modern = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
    local legacy = GetNumQuestLogEntries and GetQuestLogTitle
    if not modern and not legacy then return nil end
    local ok, count = pcall(modern and C_QuestLog.GetNumQuestLogEntries or GetNumQuestLogEntries)
    if not ok or type(count) ~= "number" then return nil end
    local quests = {}
    local currentHeader = "Weitere Quests"
    for index = 1, count do
        local infoOK, title, isHeader, questID, level
        if modern then
            local result
            infoOK, result = pcall(C_QuestLog.GetInfo, index)
            if infoOK and type(result) == "table" then
                title, isHeader, questID, level = result.title, result.isHeader, result.questID, result.level
            end
        else
            local result = { pcall(GetQuestLogTitle, index) }
            infoOK, title, level, isHeader, questID = result[1], result[2], result[3], result[5], result[9]
        end
        if infoOK and isHeader then
            currentHeader = U.SafeText(title, "Weitere Quests")
        elseif infoOK and type(questID) == "number" and questID > 0 then
            quests[tostring(questID)] = { id = questID, title = U.SafeText(title, "Quest #" .. questID),
                level = level, zone = currentHeader }
        end
    end
    return quests
end

function A.KnownRecipes()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetBaseProfessionInfo) then return nil end
    for _, method in ipairs({ "IsNPCCrafting", "IsTradeSkillLinked" }) do
        if C_TradeSkillUI[method] then
            local ok, restricted = pcall(C_TradeSkillUI[method])
            if not ok or restricted then return nil end
        end
    end
    if C_TradeSkillUI.IsTradeSkillReady then
        local ok, ready = pcall(C_TradeSkillUI.IsTradeSkillReady)
        if not ok or not ready then return nil end
    end
    local infoOK, profession = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
    if not infoOK or type(profession) ~= "table" or type(profession.professionName) ~= "string" or profession.professionName == "" then return nil end
    local listOK, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if not listOK or type(ids) ~= "table" or #ids == 0 then return nil end
    local recipes = {}
    for _, id in ipairs(ids) do
        if type(id) == "number" then
            local recipeOK, recipe = pcall(C_TradeSkillUI.GetRecipeInfo, id)
            if recipeOK and type(recipe) == "table" and recipe.learned == true and type(recipe.name) == "string" and recipe.name ~= "" then
                recipes[tostring(id)] = { id = id, name = recipe.name, icon = recipe.icon }
            end
        end
    end
    return { profession = profession.professionName, recipes = recipes }
end

function A.ContainerItemInfo(bag, slot)
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if not ok then return nil end
    return info
end

function A.ContainerSlots(bag)
    if not (C_Container and C_Container.GetContainerNumSlots) then return 0 end
    local ok, count = pcall(C_Container.GetContainerNumSlots, bag)
    return ok and count or 0
end

function A.ContainerQuestInfo(bag, slot)
    if not (C_Container and C_Container.GetContainerItemQuestInfo) then return nil end
    local ok, info = pcall(C_Container.GetContainerItemQuestInfo, bag, slot)
    return ok and type(info) == "table" and info or nil
end

function A.ItemInfo(link)
    if not link or not C_Item or not C_Item.GetItemInfo then return nil end
    local ok, name, itemLink, quality, level, _, _, _, _, icon = pcall(C_Item.GetItemInfo, link)
    if not ok then return nil end
    return { name = name, link = itemLink or link, quality = quality, level = level, icon = icon }
end

function A.InstanceInfo()
    if not GetInstanceInfo then return nil end
    local ok, name, instanceType, difficultyID, difficultyName, _, _, instanceID = pcall(GetInstanceInfo)
    if not ok then return nil end
    return { name = name, instanceType = instanceType, difficultyID = difficultyID, difficulty = difficultyName, id = instanceID }
end

function A.IsInCombat()
    return InCombatLockdown and InCombatLockdown() or false
end
