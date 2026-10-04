local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.QuestSystem = FieldJournal.QuestSystem or {}

local QS = FieldJournal.QuestSystem

QS.initialized = false

local function SafeCallString(api)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api)
    if ok and FieldJournal.Compat and FieldJournal.Compat:IsSafe(value, "string")
        and value ~= "" then
        return value
    end
    return nil
end

local function SafeCallID(api)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api)
    if ok and FieldJournal.Compat and FieldJournal.Compat:IsSafe(value, "number")
        and value > 0 then
        return value
    end
    return nil
end

function QS:Init()
    if self.initialized then
        return
    end

    self.initialized = true

    FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}
    FieldJournalDB.acceptedQuestText = FieldJournalDB.acceptedQuestText or {}

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r QuestSystem initialized.")
    end
end

function QS:OnQuestDetail()
    -- These APIs describe the offer currently on the screen. Keep it only in
    -- memory until QUEST_ACCEPTED confirms that this character took the quest.
    local questID = SafeCallID(_G.GetQuestID)
    local title = SafeCallString(_G.GetTitleText)
    local description = SafeCallString(_G.GetQuestText)
    local objectives = SafeCallString(_G.GetObjectiveText)
    if not questID and not title then
        self.pendingOffer = nil
        return
    end
    local compat = FieldJournal.Compat
    local npcName = compat and compat:UnitName("npc")
    local npcGUID = compat and compat:UnitGUID("npc")
    self.pendingOffer = {
        questID = questID,
        title = title,
        description = description,
        objectives = objectives,
        npcName = npcName,
        npcID = npcGUID and compat:GetNPCID(npcGUID) or nil,
    }
end

function QS:OnQuestAccepted(questLogIndex, eventQuestID)
    local questID
    local compat = FieldJournal.Compat
    if compat and compat:IsSafe(eventQuestID, "number") and eventQuestID > 0 then
        questID = eventQuestID
    elseif C_QuestLog and type(C_QuestLog.GetInfo) == "function"
        and compat and compat:IsSafe(questLogIndex, "number") then
        local ok, info = pcall(C_QuestLog.GetInfo, questLogIndex)
        if ok and compat:IsSafe(info, "table") and compat:IsSafe(info.questID, "number") then
            questID = info.questID
        end
    end

    local offer = self.pendingOffer
    -- An unrelated accepted quest must never inherit another NPC's words.
    if not questID and offer then questID = offer.questID end
    if not questID or questID <= 0 then return end
    self.pendingOffer = nil
    if offer and offer.questID and offer.questID ~= questID then offer = nil end
    if offer and not offer.questID and offer.title and C_QuestLog
        and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if not ok or not compat:IsSafe(title, "string") or title ~= offer.title then
            offer = nil
        end
    end

    FieldJournalDB.acceptedQuestText = FieldJournalDB.acceptedQuestText or {}
    FieldJournalDB.acceptedQuestText[questID] = {
        title = offer and offer.title or nil,
        description = offer and offer.description or nil,
        objectives = offer and offer.objectives or nil,
        npcName = offer and offer.npcName or nil,
        npcID = offer and offer.npcID or nil,
    }
end

function QS:GetQuestDefinition(questID)
    if not questID then return nil end
    return FieldJournal_QuestDB and FieldJournal_QuestDB[questID]
end

function QS:RecordQuestTurnIn(questID)
    if not questID then
        return false
    end

    local questDef = self:GetQuestDefinition(questID)
    local hasWrittenSummary = questDef and type(questDef.summary) == "string"
        and questDef.summary ~= ""

    -- Chronicle keeps a lightweight history of every quest turn-in, even when
    -- that quest does not yet have a handcrafted Field Journal entry.
    if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.RecordQuestTurnIn then
        FieldJournal.ChronicleSystem:RecordQuestTurnIn(questID, questDef)
    end

    FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}
    FieldJournalDB.acceptedQuestText = FieldJournalDB.acceptedQuestText or {}
    local offer = FieldJournalDB.acceptedQuestText[questID]
    FieldJournalDB.acceptedQuestText[questID] = nil
    local questTitle
    if C_QuestLog and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and FieldJournal.Compat and FieldJournal.Compat:IsSafe(title, "string")
            and title ~= "" then
            questTitle = title
        end
    end

    -- Do not overwrite the original level/time if the event fires twice.
    if FieldJournalDB.completedQuests[questID] then
        return false
    end

    FieldJournalDB.completedQuests[questID] = {
        questID = questID,
        title = (questDef and questDef.title) or (offer and offer.title) or questTitle,
        zone = questDef and questDef.zone or (GetRealZoneText and GetRealZoneText()),
        subregion = questDef and questDef.subregion or (GetSubZoneText and GetSubZoneText()),
        npcName = (questDef and questDef.npcName) or (offer and offer.npcName),
        npcID = (questDef and questDef.npcID) or (offer and offer.npcID),
        description = not hasWrittenSummary and offer and offer.description or nil,
        objectives = not hasWrittenSummary and offer and offer.objectives or nil,
        playerLevel = UnitLevel("player"),
        completedAt = date("%Y-%m-%d %H:%M:%S"),
    }

    if not hasWrittenSummary and FieldJournal.UI and FieldJournal.UI.QuestReport then
        FieldJournal.UI.QuestReport:ShowUnknownQuest(
            questID, FieldJournalDB.completedQuests[questID])
    end

    if questDef then
        print("|cff33ff99[Field Journal]|r Quest recorded: " .. (questDef.title or ("Quest " .. tostring(questID))))
    end

    return true
end

function QS:GetCompletedQuestsForSubregion(zoneName, subregionName)
    local results = {}

    if not zoneName or not subregionName then
        return results
    end

    FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}

    for questID, record in pairs(FieldJournalDB.completedQuests) do
        local questDef = self:GetQuestDefinition(questID)

        if questDef
            and questDef.zone == zoneName
            and questDef.subregion == subregionName then

            table.insert(results, {
                questID = questID,
                record = record,
                definition = questDef,
            })
        end
    end

    table.sort(results, function(a, b)
        local aTitle = a.definition.title or ""
        local bTitle = b.definition.title or ""
        return aTitle < bTitle
    end)

    return results
end

function QS:GetCompletedQuestNPCsForSubregion(zoneName, subregionName)
    local quests = self:GetCompletedQuestsForSubregion(zoneName, subregionName)
    local byNPC = {}
    local list = {}

    for _, data in ipairs(quests) do
        local npcName = data.definition.npcName or "Unknown"
        local npcID = data.definition.npcID or 0
        local key = npcName .. ":" .. tostring(npcID)

        if not byNPC[key] then
            byNPC[key] = {
                npcName = npcName,
                npcID = npcID,
                quests = {},
            }

            table.insert(list, byNPC[key])
        end

        table.insert(byNPC[key].quests, data)
    end

    table.sort(list, function(a, b)
        return a.npcName < b.npcName
    end)

    return list
end
