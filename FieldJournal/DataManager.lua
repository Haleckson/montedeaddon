local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.DataManager = FieldJournal.DataManager or {}

local DM = FieldJournal.DataManager

function DM:Init()
    FieldJournalDB = FieldJournalDB or {}
    FieldJournalDB.encounters = FieldJournalDB.encounters or {}
    FieldJournalDB.subjects = FieldJournalDB.subjects or {}
    FieldJournalDB.zones = FieldJournalDB.zones or {}
    FieldJournalDB.config = FieldJournalDB.config or {}
    FieldJournalDB.chronicle = FieldJournalDB.chronicle or {}
end

function DM:GetEncounter(npcID)
    if not npcID then return nil end
    FieldJournalDB.encounters = FieldJournalDB.encounters or {}
    return FieldJournalDB.encounters[npcID]
end

function DM:GetOrCreateEncounter(npcID, npcName)
    if not npcID then return nil end

    FieldJournalDB.encounters = FieldJournalDB.encounters or {}

    FieldJournalDB.encounters[npcID] = FieldJournalDB.encounters[npcID] or {
        npcID = npcID,
        name = npcName or "Unknown",
        killCount = 0,
        observationCount = 0,
        firstEncounter = nil,
        lastEncounter = nil,
        knownHabitats = {},
        subjectID = nil,
    }

    local encounter = FieldJournalDB.encounters[npcID]

    if npcName and npcName ~= "" then
        if not encounter.name or encounter.name == "Unknown" or encounter.name == ("NPC " .. tostring(npcID)) then
            encounter.name = npcName
        end
    end

    return encounter
end

function DM:GetSubject(subjectID)
    if not subjectID then return nil end
    FieldJournalDB.subjects = FieldJournalDB.subjects or {}
    return FieldJournalDB.subjects[subjectID]
end

function DM:GetZone(zoneID, zoneName)
    if not zoneID then return nil end

    FieldJournalDB.zones = FieldJournalDB.zones or {}

    FieldJournalDB.zones[zoneID] = FieldJournalDB.zones[zoneID] or {
        zoneID = zoneID,
        name = zoneName or zoneID or "Unknown Zone",
        encounteredSubjects = {},
        encounteredNPCs = {},
        totalKills = 0,
        totalObservations = 0,
        uniqueCreatures = {},
    }

    return FieldJournalDB.zones[zoneID]
end
