local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.SubjectSystem = FieldJournal.SubjectSystem or {}

local SS = FieldJournal.SubjectSystem

local function NormalizeSubjectID(subjectID)
    if type(subjectID) ~= "string" then
        return nil
    end

    return string.upper(subjectID)
end

local function GetSubjectDisplayName(subjectID)
    subjectID = NormalizeSubjectID(subjectID)
    if not subjectID then return "Unknown" end

    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    if entry and entry.displayName then
        return entry.displayName
    end

    local name = subjectID:gsub("_", " ")
    return (name:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function GetLore(subjectID, tier)
    subjectID = NormalizeSubjectID(subjectID)
    if not subjectID then return nil end

    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    return entry and entry.lore and entry.lore[tier]
end

local function ShowKnowledgeIncrease(subjectID)
    local displayName = GetSubjectDisplayName(subjectID)
    local text = displayName .. " Knowledge Increased!"

    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(
            RaidWarningFrame,
            text,
            { r = 1.0, g = 0.82, b = 0.0 },
            2.5
        )
    end

    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(text, 1.0, 0.82, 0.0)
    end
end

local function PrintLore(subjectID, tier)
    local lore = GetLore(subjectID, tier)
    if lore and lore ~= "" then
        print("|cff33ff99[Field Journal]|r New Observation:")
        print(lore)
    elseif FieldJournal.Config and FieldJournal.Config.debug then
        print("No lore found for", subjectID, "Knowledge Level", tier)
    end
end

function SS:GetOrCreateSubject(subjectID)
    subjectID = NormalizeSubjectID(subjectID)
    if not subjectID then return nil end

    FieldJournalDB.subjects = FieldJournalDB.subjects or {}

    FieldJournalDB.subjects[subjectID] = FieldJournalDB.subjects[subjectID] or {
        id = subjectID,
        observationLevel = 0,
        totalKills = 0,
        totalObservations = 0,
        unlockedTiers = {},
        knownZones = {},
        firstDiscovery = nil,
        lastUpdated = nil,
    }

    return FieldJournalDB.subjects[subjectID]
end

function SS:UnlockTier(subject, tier)
    if not subject or not tier then return false end

    subject.observationLevel = tier
    subject.unlockedTiers = subject.unlockedTiers or {}
    subject.unlockedTiers[tier] = true
    subject.lastUpdated = date("%Y-%m-%d %H:%M:%S")

    ShowKnowledgeIncrease(subject.id)
    PrintLore(subject.id, tier)

    return true
end

function SS:RecordProgress(npcID, subjectID, sourceType, zoneName)
    subjectID = NormalizeSubjectID(subjectID)
    if not subjectID then return false end

    local subject = self:GetOrCreateSubject(subjectID)
    if not subject then return false end

    sourceType = sourceType or "unknown"

    if sourceType == "kill" then
        subject.totalKills = (subject.totalKills or 0) + 1
    elseif sourceType == "observation" then
        subject.totalObservations = (subject.totalObservations or 0) + 1
    end

    if zoneName and zoneName ~= "" then
        subject.knownZones = subject.knownZones or {}
        subject.knownZones[zoneName] = true
    end

    if not subject.firstDiscovery then
        subject.firstDiscovery = date("%Y-%m-%d %H:%M:%S")

        if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.RecordSubjectDiscovery then
            FieldJournal.ChronicleSystem:RecordSubjectDiscovery(subjectID, zoneName)
        end
    end

    local currentLevel = subject.observationLevel or 0

    if currentLevel <= 0 then
        return self:UnlockTier(subject, 1)
    end

    if currentLevel >= 5 then
        return false
    end

    local nextTier = currentLevel + 1

    local chances = {
        [2] = 5,
        [3] = 2.5,
        [4] = 1,
        [5] = 0.5,
    }

    local chance = chances[nextTier]
    if not chance then
        return false
    end

    local roll = math.random() * 100

if roll <= chance then
    return self:UnlockTier(subject, nextTier)
end

    return false
end

function SS:OnEncounter(npcID, subjectID, zoneName)
    return self:RecordProgress(npcID, subjectID, "kill", zoneName)
end

function SS:OnObservation(subjectID, npcID, zoneName)
    return self:RecordProgress(npcID, subjectID, "observation", zoneName)
end