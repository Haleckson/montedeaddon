local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.Events = FieldJournal.Events or {}

local Events = FieldJournal.Events
local eventFrame = CreateFrame("Frame")

Events.initialized = false

function Events:Init()
    if self.initialized then
        return
    end

    self.initialized = true

    if FieldJournal.Compat and FieldJournal.Compat.isForever then
        eventFrame:RegisterEvent("PARTY_KILL")
        eventFrame:RegisterEvent("UNIT_DIED")
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("PLAYER_ALIVE")
    eventFrame:RegisterEvent("PLAYER_UNGHOST")

    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    eventFrame:RegisterEvent("QUEST_TURNED_IN")
    eventFrame:RegisterEvent("QUEST_DETAIL")
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("PLAYER_LEVEL_UP")

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        Events:HandleEvent(event, ...)
    end)

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r Events initialized.")
    end
end

function Events:HandleEvent(event, ...)
    if event == "PARTY_KILL" then
        if FieldJournal.EncounterSystem and FieldJournal.EncounterSystem.OnPartyKill then
            FieldJournal.EncounterSystem:OnPartyKill(...)
        end
        return
    end

    if event == "UNIT_DIED" then
        if FieldJournal.EncounterSystem and FieldJournal.EncounterSystem.OnUnitDied then
            FieldJournal.EncounterSystem:OnUnitDied(...)
        end
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if FieldJournal.EncounterSystem and FieldJournal.EncounterSystem.OnCombatLogEvent then
            FieldJournal.EncounterSystem:OnCombatLogEvent(...)
        end

        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        if FieldJournal.EncounterSystem and FieldJournal.EncounterSystem.RememberTarget then
            FieldJournal.EncounterSystem:RememberTarget()
        end
        if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.OnTargetChanged then
            FieldJournal.ObserveSystem:OnTargetChanged()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if FieldJournal.ZoneSystem and FieldJournal.ZoneSystem.OnZoneChanged then
            FieldJournal.ZoneSystem:OnZoneChanged()
        end

        if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.OnPlayerEnteringWorld then
            FieldJournal.ObserveSystem:OnPlayerEnteringWorld()
        end
        return
    end

    if event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" then

        if FieldJournal.ZoneSystem and FieldJournal.ZoneSystem.OnZoneChanged then
            FieldJournal.ZoneSystem:OnZoneChanged()
        end
        return
    end

    if event == "QUEST_DETAIL" then
        if FieldJournal.QuestSystem and FieldJournal.QuestSystem.OnQuestDetail then
            FieldJournal.QuestSystem:OnQuestDetail()
        end
        return
    end

    if event == "QUEST_ACCEPTED" then
        if FieldJournal.QuestSystem and FieldJournal.QuestSystem.OnQuestAccepted then
            FieldJournal.QuestSystem:OnQuestAccepted(...)
        end
        return
    end

    if event == "QUEST_TURNED_IN" then
        local questID = ...

        if FieldJournal.QuestSystem and FieldJournal.QuestSystem.RecordQuestTurnIn then
            FieldJournal.QuestSystem:RecordQuestTurnIn(questID)
        end

        return
    end

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...

        if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.OnPlayerLevelUp then
            FieldJournal.ChronicleSystem:OnPlayerLevelUp(newLevel)
        end

        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if FieldJournal.ObserveSystem and FieldJournal.ObserveSystem.CancelObservation then
            FieldJournal.ObserveSystem:CancelObservation("Combat started.")
        end
        return
    end

    if event == "PLAYER_DEAD" then
        if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.OnPlayerDead then
            FieldJournal.ChronicleSystem:OnPlayerDead()
        end
        return
    end

    if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.OnPlayerAlive then
            FieldJournal.ChronicleSystem:OnPlayerAlive()
        end
        return
    end
end
