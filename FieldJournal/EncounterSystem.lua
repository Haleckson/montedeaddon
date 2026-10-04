local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.EncounterSystem = FieldJournal.EncounterSystem or {}

local ES = FieldJournal.EncounterSystem
local Compat = FieldJournal.Compat

if FieldJournal.Config and FieldJournal.Config.debug then
    print(">>> FIELD JOURNAL EncounterSystem LOADED <<<")
end

local function GetCurrentZoneName()
    return GetRealZoneText() or "Unknown Zone"
end

local function GetCreatureNPCID(guid)
    return Compat:GetNPCID(guid)
end

-- Forever's PARTY_KILL contains GUIDs but no NPC name. Retain the name only
-- when the player has targeted the same safe GUID.
function ES:RememberTarget()
    local guid = Compat:UnitGUID("target")
    local npcID = GetCreatureNPCID(guid)
    if not npcID then return end
    local name = Compat:UnitName("target")
    if name then
        self.targetNames = self.targetNames or {}
        self.targetNames[guid] = name
        self.targetNameCount = (self.targetNameCount or 0) + 1
        if self.targetNameCount > 64 then
            self.targetNames = { [guid] = name }
            self.targetNameCount = 1
        end
    end
end

function ES:OnPartyKill(attackerGUID, targetGUID)
    if not FieldJournal.isReady or not Compat:IsSafe(targetGUID, "string") then
        Compat:Debug("PARTY_KILL skipped: target GUID unavailable.")
        return
    end
    if not GetCreatureNPCID(targetGUID) then return end

    self.recentKills = self.recentKills or {}
    local now = GetTime()
    if self.recentKills[targetGUID] and now - self.recentKills[targetGUID] < 3 then return end
    self.recentKills[targetGUID] = now
    if self.lastKillTime and now - self.lastKillTime > 15 then
        self.recentKills = { [targetGUID] = now }
    end
    self.lastKillTime = now

    self:RememberTarget()
    local npcID = GetCreatureNPCID(targetGUID)
    local name = (self.targetNames and self.targetNames[targetGUID]) or ("NPC " .. npcID)
    Compat:Debug("PARTY_KILL: NPC " .. npcID .. " (party credit; name " .. name .. ").")

    local widgets = FieldJournal.UI and FieldJournal.UI.Widgets
    if widgets and widgets.CaptureCreatureAppearanceFromUnit
        and Compat:UnitGUID("target") == targetGUID then
        widgets:CaptureCreatureAppearanceFromUnit("target", npcID, name)
    end
    self:RecordKill(targetGUID, name)
end

-- UNIT_DIED alone gives no proof that the player or party earned the kill.
function ES:OnUnitDied(unitGUID)
    if not Compat:IsSafe(unitGUID, "string") then return end
    if Compat:UnitGUID("target") == unitGUID then self:RememberTarget() end
end

function ES:OnCombatLogEvent()
    if not FieldJournal.isReady then
        return
    end

    local _, subevent, _, sourceGUID, _, _, _, destGUID, destName =
        CombatLogGetCurrentEventInfo()

    if subevent == "SWING_DAMAGE"
        or subevent == "SPELL_DAMAGE"
        or subevent == "RANGE_DAMAGE"
        or subevent == "SPELL_PERIODIC_DAMAGE" then

        if sourceGUID == UnitGUID("player") then
            ES.playerTouched = ES.playerTouched or {}
            ES.playerTouched[destGUID] = true

            -- When the damaged creature is the player's current target, capture
            -- its exact live CreatureDisplayID. This preserves rare skins and
            -- other visual variants that share a broader lore subject.
            ES.appearanceCapturedGUIDs = ES.appearanceCapturedGUIDs or {}
            if not ES.appearanceCapturedGUIDs[destGUID] then
                ES.appearanceCapturedGUIDs[destGUID] = true
                local npcID = GetCreatureNPCID(destGUID)
                local subjectID = npcID and FieldJournal.SubjectIndex and FieldJournal.SubjectIndex:Get(npcID, GetCurrentZoneName())
                local widgets = FieldJournal.UI and FieldJournal.UI.Widgets
                if subjectID and widgets and widgets.CaptureCreatureAppearanceFromUnit
                    and UnitGUID("target") == destGUID then
                    widgets:CaptureCreatureAppearanceFromUnit("target", npcID, destName, subjectID)
                end
            end
        end

        return
    end

    if subevent ~= "UNIT_DIED" then
        return
    end

    if not ES.playerTouched or not ES.playerTouched[destGUID] then
        return
    end

    ES.playerTouched[destGUID] = nil
    if ES.appearanceCapturedGUIDs then
        ES.appearanceCapturedGUIDs[destGUID] = nil
    end

    self:RecordKill(destGUID, destName)
end

function ES:RecordKill(destGUID, destName)
    local npcID = GetCreatureNPCID(destGUID)
    if not npcID then return end

    -- Chronicle level summaries use only creatures the player actually helped
    -- kill. Record the mob before the curated-subject check so ordinary NPCs
    -- can still contribute factual context to the next level-up entry.
    if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.RecordMobKill then
        FieldJournal.ChronicleSystem:RecordMobKill(npcID, destName, GetCurrentZoneName())
    end

    local zoneName = GetCurrentZoneName()
    local subjectID = FieldJournal.SubjectIndex and FieldJournal.SubjectIndex:Get(npcID, zoneName)

    if not subjectID then
        if FieldJournal.Config and FieldJournal.Config.debug then
            print("DEBUG: No journal subject for NPC", npcID, destName or "")
        end
        return
    end

    local encounter = FieldJournal.DataManager:GetOrCreateEncounter(npcID, destName)
    if encounter then
        encounter.name = encounter.name or destName or ("NPC " .. tostring(npcID))
        encounter.subjectID = subjectID
        encounter.killCount = (encounter.killCount or 0) + 1
        encounter.lastEncounter = date("%Y-%m-%d %H:%M:%S")
        encounter.firstEncounter = encounter.firstEncounter or encounter.lastEncounter
        encounter.knownHabitats = encounter.knownHabitats or {}
        encounter.knownHabitats[zoneName] = true
        encounter.subjectData = encounter.subjectData or {}
        local subjectData = encounter.subjectData[subjectID] or { killCount = 0, knownHabitats = {} }
        encounter.subjectData[subjectID] = subjectData
        subjectData.killCount = (subjectData.killCount or 0) + 1
        subjectData.knownHabitats = subjectData.knownHabitats or {}
        subjectData.knownHabitats[zoneName] = true
    end

    -- If an exact live target capture was not available (for example an AoE
    -- kill), resolve a representative display from the NPC ID after a short
    -- delay. The delayed check avoids adding a default model when the exact
    -- live capture is still finishing.
    local widgets = FieldJournal.UI and FieldJournal.UI.Widgets
    if widgets and widgets.QueueCreatureAppearanceByNPCID and C_Timer and C_Timer.After then
        C_Timer.After(0.40, function()
            if not widgets.HasCreatureAppearanceForNPC
                or not widgets:HasCreatureAppearanceForNPC(subjectID, npcID) then
                widgets:QueueCreatureAppearanceByNPCID(npcID, destName, subjectID, "kill")
            end
        end)
    end

    local zone = FieldJournal.DataManager:GetZone(zoneName, zoneName)
    if zone then
        zone.totalKills = (zone.totalKills or 0) + 1
        zone.encounteredNPCs = zone.encounteredNPCs or {}
        zone.encounteredSubjects = zone.encounteredSubjects or {}
        zone.uniqueCreatures = zone.uniqueCreatures or {}

        zone.encounteredNPCs[npcID] = true
        zone.encounteredSubjects[subjectID] = true
        zone.uniqueCreatures[npcID] = true
    end

    if FieldJournal.SubjectSystem and FieldJournal.SubjectSystem.OnEncounter then
        FieldJournal.SubjectSystem:OnEncounter(npcID, subjectID, zoneName)
    end

    local journal = FieldJournal.UI and FieldJournal.UI.JournalFrame
    if journal and journal.RefreshActiveSubject then
        journal:RefreshActiveSubject(subjectID)
    end

end
