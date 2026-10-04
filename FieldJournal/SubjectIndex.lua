local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.SubjectIndex = FieldJournal.SubjectIndex or {}

local SI = FieldJournal.SubjectIndex

SI.initialized = false
SI.npcToSubjects = {}

local function BelongsToZone(data, zoneName)
    if not zoneName then return false end
    -- Older Dun Morogh subjects predate the explicit zones field.
    if not data.zones then return zoneName == "Dun Morogh" end
    for _, zone in ipairs(data.zones) do
        if zone == zoneName then return true end
    end
    return false
end

function SI:Build()
    local LoreDB = FieldJournal_LoreDB

    self.npcToSubjects = {}

    if not LoreDB then
        print("|cffcc0000[FieldJournal]|r SubjectIndex failed: LoreDB missing.")
        self.initialized = false
        return
    end

    local count = 0

    for subjectID, data in pairs(LoreDB) do
        if data.npcs then
            for _, npcID in ipairs(data.npcs) do
                local subjects = self.npcToSubjects[npcID]
                if not subjects then
                    subjects = {}
                    self.npcToSubjects[npcID] = subjects
                end
                subjects[#subjects + 1] = subjectID
                count = count + 1
            end
        end
    end

    self.initialized = true

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r SubjectIndex built. NPC mappings:", count)
    end

    for _, subjects in pairs(self.npcToSubjects) do
        table.sort(subjects)
    end
end

function SI:Get(npcID, zoneName)
    if not self.initialized then
        self:Build()
    end

    local subjects = self.npcToSubjects and self.npcToSubjects[npcID]
    if not subjects then return nil end
    zoneName = zoneName or (GetRealZoneText and GetRealZoneText())
    local matched
    for _, subjectID in ipairs(subjects) do
        if BelongsToZone(FieldJournal_LoreDB[subjectID], zoneName) then
            if matched then return nil end -- Ambiguous data must not choose at random.
            matched = subjectID
        end
    end
    if matched then return matched end
    -- One mapped creature may occasionally wander outside its listed area.
    -- A shared NPC ID without a matching zone has no safe interpretation.
    return #subjects == 1 and subjects[1] or nil
end

function SI:RepairSavedSubjects()
    -- Early Mulgore data filed the beast Bristleback Battleboar under the
    -- humanoid Bristleback subject. Move its exact saved counts once when
    -- introducing the separate Battleboars subject.
    local db = FieldJournalDB
    local battleboar = db and db.encounters and (db.encounters[2954] or db.encounters["2954"])
    if battleboar then
        battleboar.subjectData = battleboar.subjectData or {}
        local oldID, newID = "MULGORE_BRISTLEBACK", "MULGORE_BATTLEBOARS"
        local oldData = battleboar.subjectData[oldID]
        if not oldData and battleboar.subjectID == oldID then
            oldData = {
                killCount = battleboar.killCount or 0,
                observationCount = battleboar.observationCount or 0,
                knownHabitats = battleboar.knownHabitats or {},
            }
        end
        if oldData then
            local kills = oldData.killCount or 0
            local observations = oldData.observationCount or 0
            local newData = battleboar.subjectData[newID] or {
                killCount = 0, observationCount = 0, knownHabitats = {},
            }
            newData.killCount = (newData.killCount or 0) + kills
            newData.observationCount = (newData.observationCount or 0) + observations
            newData.knownHabitats = newData.knownHabitats or {}
            for zone in pairs(oldData.knownHabitats or {}) do
                newData.knownHabitats[zone] = true
            end
            newData.knownHabitats.Mulgore = true
            battleboar.subjectData[newID] = newData
            battleboar.subjectData[oldID] = nil
            battleboar.subjectID = newID

            local oldSubject = db.subjects and db.subjects[oldID]
            if oldSubject then
                oldSubject.totalKills = math.max(0, (oldSubject.totalKills or 0) - kills)
                oldSubject.totalObservations = math.max(0, (oldSubject.totalObservations or 0) - observations)
                if oldSubject.totalKills == 0 and oldSubject.totalObservations == 0 then
                    local hasOtherRecord = false
                    for otherID, other in pairs(db.encounters) do
                        if tonumber(otherID) ~= 2954 and (
                            (other.subjectData and other.subjectData[oldID])
                            or (not other.subjectData and other.subjectID == oldID)) then
                            hasOtherRecord = true
                            break
                        end
                    end
                    if not hasOtherRecord then
                        db.subjects[oldID] = nil
                        local zone = db.zones and db.zones.Mulgore
                        if zone and zone.encounteredSubjects then
                            zone.encounteredSubjects[oldID] = nil
                        end
                    end
                end
            end
            local subjectSystem = FieldJournal.SubjectSystem
            local newSubject = subjectSystem and subjectSystem:GetOrCreateSubject(newID)
            if newSubject then
                newSubject.totalKills = (newSubject.totalKills or 0) + kills
                newSubject.totalObservations = (newSubject.totalObservations or 0) + observations
                newSubject.knownZones = newSubject.knownZones or {}
                newSubject.knownZones.Mulgore = true
                if (newSubject.observationLevel or 0) < 1 then
                    newSubject.observationLevel = 1
                    newSubject.unlockedTiers = newSubject.unlockedTiers or {}
                    newSubject.unlockedTiers[1] = true
                end
                newSubject.firstDiscovery = newSubject.firstDiscovery
                    or battleboar.firstEncounter or date("%Y-%m-%d %H:%M:%S")
            end
        end
    end

    -- Snagglespear is a Palemane gnoll, previously filed with Venture Co.
    local snagglespear = db and db.encounters and (db.encounters[5786] or db.encounters["5786"])
    if snagglespear then
        snagglespear.subjectData = snagglespear.subjectData or {}
        local oldID, newID = "MULGORE_VENTURE_CO", "MULGORE_PALEMANE"
        local oldData = snagglespear.subjectData[oldID]
        if not oldData and snagglespear.subjectID == oldID then
            oldData = {
                killCount = snagglespear.killCount or 0,
                observationCount = snagglespear.observationCount or 0,
                knownHabitats = snagglespear.knownHabitats or {},
            }
        end
        if oldData then
            local kills, observations = oldData.killCount or 0, oldData.observationCount or 0
            local newData = snagglespear.subjectData[newID] or {
                killCount = 0, observationCount = 0, knownHabitats = {},
            }
            newData.killCount = (newData.killCount or 0) + kills
            newData.observationCount = (newData.observationCount or 0) + observations
            newData.knownHabitats = newData.knownHabitats or {}
            for zone in pairs(oldData.knownHabitats or {}) do newData.knownHabitats[zone] = true end
            newData.knownHabitats.Mulgore = true
            snagglespear.subjectData[newID] = newData
            snagglespear.subjectData[oldID] = nil
            snagglespear.subjectID = newID

            local oldSubject = db.subjects and db.subjects[oldID]
            if oldSubject then
                oldSubject.totalKills = math.max(0, (oldSubject.totalKills or 0) - kills)
                oldSubject.totalObservations = math.max(0, (oldSubject.totalObservations or 0) - observations)
                if oldSubject.totalKills == 0 and oldSubject.totalObservations == 0 then
                    local other = false
                    for otherID, encounter in pairs(db.encounters) do
                        if tonumber(otherID) ~= 5786 and (
                            (encounter.subjectData and encounter.subjectData[oldID])
                            or (not encounter.subjectData and encounter.subjectID == oldID)) then
                            other = true
                            break
                        end
                    end
                    if not other then
                        db.subjects[oldID] = nil
                        local zone = db.zones and db.zones.Mulgore
                        if zone and zone.encounteredSubjects then zone.encounteredSubjects[oldID] = nil end
                    end
                end
            end
            local subjectSystem = FieldJournal.SubjectSystem
            local newSubject = subjectSystem and subjectSystem:GetOrCreateSubject(newID)
            if newSubject then
                newSubject.totalKills = (newSubject.totalKills or 0) + kills
                newSubject.totalObservations = (newSubject.totalObservations or 0) + observations
                newSubject.knownZones = newSubject.knownZones or {}
                newSubject.knownZones.Mulgore = true
                if (newSubject.observationLevel or 0) < 1 then
                    newSubject.observationLevel = 1
                    newSubject.unlockedTiers = newSubject.unlockedTiers or {}
                    newSubject.unlockedTiers[1] = true
                end
                newSubject.firstDiscovery = newSubject.firstDiscovery
                    or snagglespear.firstEncounter or date("%Y-%m-%d %H:%M:%S")
            end
        end
    end

    -- Correct exact NPC IDs previously credited to an unrelated lore subject.
    -- Removing the old per-NPC bucket makes this safe to run on every login.
    local corrections = {
        { 2173, "DARKSHORE_SATYR", "SILVERPINE_REEF_FRENZY", "Silverpine Forest" },
        { 428, "REDRIDGE_DRAGON_WHELPS", "REDRIDGE_CONDORS", "Redridge Mountains" },
        { 430, "REDRIDGE_BLACKROCK_ORCS", "REDRIDGE_GNOLLS", "Redridge Mountains" },
        { 440, "REDRIDGE_DRAGON_WHELPS", "REDRIDGE_BLACKROCK_ORCS", "Redridge Mountains" },
        { 446, "REDRIDGE_TARANTULAS", "REDRIDGE_GNOLLS", "Redridge Mountains" },
        { 4005, "STONETALON_VENTURE_CO", "STONETALON_DEEPMOSS_SPIDERS", "Stonetalon Mountains" },
        { 4006, "STONETALON_VENTURE_CO", "STONETALON_DEEPMOSS_SPIDERS", "Stonetalon Mountains" },
        { 3258, "BARRENS_RAPTORS", "BARRENS_BRISTLEBACK", "The Barrens" },
    }
    for _, correction in ipairs(corrections) do
        local npcID, oldID, newID, zoneName = unpack(correction)
        local encounter = db and db.encounters
            and (db.encounters[npcID] or db.encounters[tostring(npcID)])
        if encounter then
            encounter.subjectData = encounter.subjectData or {}
            local oldData = encounter.subjectData[oldID]
            if not oldData and encounter.subjectID == oldID then
                oldData = {
                    killCount = encounter.killCount or 0,
                    observationCount = encounter.observationCount or 0,
                    knownHabitats = encounter.knownHabitats or {},
                }
            end
            if oldData then
                local kills = oldData.killCount or 0
                local observations = oldData.observationCount or 0
                local newData = encounter.subjectData[newID] or {
                    killCount = 0, observationCount = 0, knownHabitats = {},
                }
                newData.killCount = (newData.killCount or 0) + kills
                newData.observationCount = (newData.observationCount or 0) + observations
                newData.knownHabitats = newData.knownHabitats or {}
                for habitat in pairs(oldData.knownHabitats or {}) do
                    newData.knownHabitats[habitat] = true
                end
                newData.knownHabitats[zoneName] = true
                encounter.subjectData[newID] = newData
                encounter.subjectData[oldID] = nil
                if encounter.subjectID == oldID then encounter.subjectID = newID end

                local previous = db.subjects and db.subjects[oldID]
                if previous then
                    previous.totalKills = math.max(0, (previous.totalKills or 0) - kills)
                    previous.totalObservations = math.max(0, (previous.totalObservations or 0) - observations)
                end
                local current = FieldJournal.SubjectSystem
                    and FieldJournal.SubjectSystem:GetOrCreateSubject(newID)
                if current then
                    current.totalKills = (current.totalKills or 0) + kills
                    current.totalObservations = (current.totalObservations or 0) + observations
                    current.knownZones = current.knownZones or {}
                    current.knownZones[zoneName] = true
                    current.observationLevel = math.max(1, current.observationLevel or 0)
                    current.unlockedTiers = current.unlockedTiers or {}
                    current.unlockedTiers[1] = true
                    current.firstDiscovery = current.firstDiscovery or encounter.firstEncounter
                end
                local zone = db.zones and db.zones[zoneName]
                if zone then
                    zone.encounteredSubjects = zone.encounteredSubjects or {}
                    zone.encounteredSubjects[newID] = true
                end
            end
        end
    end
    for _, correction in ipairs(corrections) do
        local oldID, zoneName = correction[2], correction[4]
        local previous = db and db.subjects and db.subjects[oldID]
        if previous and (previous.totalKills or 0) == 0
            and (previous.totalObservations or 0) == 0 then
            local stillEncountered = false
            for _, encounter in pairs(db.encounters or {}) do
                if (encounter.subjectData and encounter.subjectData[oldID])
                    or (not encounter.subjectData and encounter.subjectID == oldID) then
                    stillEncountered = true
                    break
                end
            end
            if not stillEncountered then
                db.subjects[oldID] = nil
                local zone = db.zones and db.zones[zoneName]
                if zone and zone.encounteredSubjects then
                    zone.encounteredSubjects[oldID] = nil
                end
            end
        end
    end

    -- Earlier builds retained only one subject per NPC ID. The saved zone and
    -- encountered NPC together identify credited kills that were filed under
    -- a different zone's subject. Restore a minimum count when the exact split
    -- between two zones cannot be reconstructed.
    if not FieldJournalDB or not FieldJournalDB.zones then return end
    for zoneName, zone in pairs(FieldJournalDB.zones) do
        for npcID in pairs(zone.encounteredNPCs or {}) do
            local subjectID = self:Get(tonumber(npcID), zoneName)
            local encounter = FieldJournalDB.encounters and FieldJournalDB.encounters[npcID]
            if subjectID and encounter then
                encounter.subjectData = encounter.subjectData or {}
                if not encounter.subjectData[subjectID] then
                    local oneHabitat = encounter.knownHabitats
                        and encounter.knownHabitats[zoneName]
                    if oneHabitat then
                        for habitat in pairs(encounter.knownHabitats) do
                            if habitat ~= zoneName then oneHabitat = false; break end
                        end
                    end
                    local count = oneHabitat and (encounter.killCount or 1) or 1
                    encounter.subjectData[subjectID] = {
                        killCount = count,
                        knownHabitats = { [zoneName] = true },
                    }
                    local subject = FieldJournal.SubjectSystem
                        and FieldJournal.SubjectSystem:GetOrCreateSubject(subjectID)
                    if subject then
                        subject.knownZones = subject.knownZones or {}
                        subject.knownZones[zoneName] = true
                        if encounter.subjectID ~= subjectID then
                            subject.totalKills = (subject.totalKills or 0) + count
                        end
                        if (subject.observationLevel or 0) < 1 then
                            subject.observationLevel = 1
                            subject.unlockedTiers = subject.unlockedTiers or {}
                            subject.unlockedTiers[1] = true
                            subject.firstDiscovery = subject.firstDiscovery
                                or encounter.firstEncounter or date("%Y-%m-%d %H:%M:%S")
                        end
                    end
                end
                zone.encounteredSubjects = zone.encounteredSubjects or {}
                zone.encounteredSubjects[subjectID] = true
                local onlyZone = true
                for habitat in pairs(encounter.knownHabitats or {}) do
                    if habitat ~= zoneName then onlyZone = false; break end
                end
                if onlyZone then encounter.subjectID = subjectID end
            end
        end
    end
end
