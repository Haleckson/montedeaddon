local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.ObserveSystem = FieldJournal.ObserveSystem or {}

local OS = FieldJournal.ObserveSystem
local Compat = FieldJournal.Compat

local OBSERVE_DURATION = 12
local PROMPT_MIN = 5
local PROMPT_MAX = 10
local PROMPT_WINDOW = 1.5

local ACTION_LABELS = {
    [1] = "Scope",
    [2] = "Paper",
    [3] = "Food",
}

local function GetCurrentZoneName()
    return GetRealZoneText() or "Unknown Zone"
end

local function GetCreatureNPCID(guid)
    return Compat:GetNPCID(guid)
end

local function CancelTimer(timer)
    if timer and timer.Cancel then
        timer:Cancel()
    end
end

function OS:CanObserveCurrentTarget()
    if Compat:UnitFlag(UnitExists, "target") ~= true then
        return false, "Target information unavailable."
    end

    if Compat:UnitFlag(UnitIsDeadOrGhost, "target") ~= false then
        return false, "That target is dead."
    end

    if Compat:CanAttack("target") ~= true then
        return false, "Target is not hostile."
    end

    return true, nil
end

function OS:Init()
    self.session = nil

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.SetSystem then
        FieldJournal.ObserveFrame:SetSystem(self)
    end

    self:RefreshTargetState()
end

function OS:GetTargetContext()
    local guid = Compat:UnitGUID("target")
    local npcID = GetCreatureNPCID(guid)

    if not npcID then
        return nil
    end

    local targetName = Compat:UnitName("target") or ("NPC " .. npcID)
    local subjectID = FieldJournal.SubjectIndex and FieldJournal.SubjectIndex:Get(npcID, GetCurrentZoneName())

    return npcID, subjectID, targetName, guid
end

function OS:RefreshTargetState()
    if self.session then
        return
    end

    local npcID, subjectID, targetName = self:GetTargetContext()
    local canObserve, reason = self:CanObserveCurrentTarget()

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.UpdateTargetState then
        FieldJournal.ObserveFrame:UpdateTargetState(
            npcID ~= nil,
            targetName,
            canObserve and subjectID ~= nil,
            reason
        )
    end
end

function OS:ValidateActiveSession()
    if not self.session then
        return
    end

    local _, _, _, guid = self:GetTargetContext()

    if not guid or guid ~= self.session.targetGUID then
        self:CancelObservation("Target changed.")
        return
    end

    if Compat:UnitFlag(UnitIsDeadOrGhost, "target") ~= false then
        self:CancelObservation("Target died.")
        return
    end

    if Compat:CanAttack("target") ~= true then
        self:CancelObservation("Target is no longer hostile.")
        return
    end
end

function OS:OnTargetChanged()
    if self.session then
        local _, _, _, guid = self:GetTargetContext()
        if not guid or guid ~= self.session.targetGUID then
            self:CancelObservation("Target changed.")
            return
        end
    end

    self:RefreshTargetState()
end

function OS:OnPlayerEnteringWorld()
    self:RefreshTargetState()
end

function OS:CancelTimers()
    if not self.session or not self.session.timers then
        return
    end

    for _, timer in pairs(self.session.timers) do
        CancelTimer(timer)
    end

    self.session.timers = {}
end

function OS:CancelObservation(reason)
    if not self.session then
        return
    end

    self:CancelTimers()
    self.session = nil

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.EndSession then
        FieldJournal.ObserveFrame:EndSession(false, reason or "Observation interrupted.")
    end

    self:RefreshTargetState()
end

function OS:_BeginPrompt()
    if not self.session or self.session.promptActive then
        return
    end

    self.session.promptActive = true

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.ShowPrompt then
        FieldJournal.ObserveFrame:ShowPrompt(
            self.session.promptIndex,
            ACTION_LABELS[self.session.promptIndex],
            PROMPT_WINDOW
        )
    end

    self.session.timers.promptFail = C_Timer.NewTimer(PROMPT_WINDOW, function()
        if self.session and self.session.promptActive and not self.session.promptResolved then
            self:CancelObservation("Too slow.")
        end
    end)
end

function OS:PressPromptButton(actionIndex)
    if not self.session or not self.session.promptActive or self.session.promptResolved then
        return
    end

    if actionIndex ~= self.session.promptIndex then
        self.session.promptResolved = true
        self:CancelObservation("Wrong tool.")
        return
    end

    self.session.promptResolved = true
    self:CompleteObservation()
end

function OS:CompleteObservation()
    if not self.session then
        return
    end

    local subjectID = self.session.subjectID
    local npcID = self.session.npcID
    local targetName = self.session.targetName
    local targetGUID = self.session.targetGUID
    local zoneName = GetCurrentZoneName()

    self:CancelTimers()
    self.session = nil

    local progressed = false

    if FieldJournal.SubjectSystem and FieldJournal.SubjectSystem.OnObservation then
        progressed = FieldJournal.SubjectSystem:OnObservation(subjectID, npcID, zoneName) and true or false
    end

    -- A completed study records the exact creature, even when no lore tier unlocks.
    local manager = FieldJournal.DataManager
    local encounter = manager and manager.GetOrCreateEncounter
        and manager:GetOrCreateEncounter(npcID, targetName)
    if encounter then
        encounter.subjectID = encounter.subjectID or subjectID
        encounter.observationCount = (encounter.observationCount or 0) + 1
        encounter.knownHabitats = encounter.knownHabitats or {}
        encounter.knownHabitats[zoneName] = true
        encounter.subjectData = encounter.subjectData or {}
        local subjectData = encounter.subjectData[subjectID] or {}
        encounter.subjectData[subjectID] = subjectData
        subjectData.killCount = subjectData.killCount or 0
        subjectData.observationCount = (subjectData.observationCount or 0) + 1
        subjectData.knownHabitats = subjectData.knownHabitats or {}
        subjectData.knownHabitats[zoneName] = true
    end

    local widgets = FieldJournal.UI and FieldJournal.UI.Widgets
    if widgets and widgets.CaptureCreatureAppearanceFromUnit
        and Compat:UnitGUID("target") == targetGUID then
        widgets:CaptureCreatureAppearanceFromUnit("target", npcID, targetName, subjectID)
    end
    if widgets and widgets.QueueCreatureAppearanceByNPCID and C_Timer and C_Timer.After then
        C_Timer.After(0.40, function()
            if not widgets.HasCreatureAppearanceForNPC
                or not widgets:HasCreatureAppearanceForNPC(subjectID, npcID) then
                widgets:QueueCreatureAppearanceByNPCID(npcID, targetName, subjectID, "observation")
            end
        end)
    end

    local zone = manager and manager:GetZone(zoneName, zoneName)
    if zone then
        zone.totalObservations = (zone.totalObservations or 0) + 1
        zone.encounteredSubjects = zone.encounteredSubjects or {}
        zone.encounteredSubjects[subjectID] = true
    end

    local journal = FieldJournal.UI and FieldJournal.UI.JournalFrame
    if journal and journal.RefreshActiveSubject then
        journal:RefreshActiveSubject(subjectID)
    end

    if not progressed then
        print("Observations complete, unfortunately, nothing noteworthy was observed")
    end

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.EndSession then
        FieldJournal.ObserveFrame:EndSession(true, "Observation complete.")
    end

    self:RefreshTargetState()
end

function OS:StartObservation()
    if self.session then
        return
    end

    local canObserve, reason = self:CanObserveCurrentTarget()

    if not canObserve then
        print("|cff33ff99[Field Journal]|r " .. (reason or "You cannot observe this target right now."))
        return
    end

    local npcID, subjectID, targetName, guid = self:GetTargetContext()

    if not npcID then
        print("|cff33ff99[Field Journal]|r Select a hostile creature first.")
        return
    end

    if not subjectID then
        print("|cff33ff99[Field Journal]|r No journal subject is mapped to this creature.")
        return
    end

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.PlayStartEmote then
        FieldJournal.ObserveFrame:PlayStartEmote()
    end

    local promptDelay = math.random(PROMPT_MIN, PROMPT_MAX)

    self.session = {
        npcID = npcID,
        subjectID = subjectID,
        targetName = targetName,
        targetGUID = guid,
        startTime = GetTime(),
        endTime = GetTime() + OBSERVE_DURATION,
        promptDelay = promptDelay,
        promptIndex = math.random(1, 3),
        promptActive = false,
        promptResolved = false,
        timers = {},
    }

    if FieldJournal.ObserveFrame and FieldJournal.ObserveFrame.StartSession then
        FieldJournal.ObserveFrame:StartSession(targetName, OBSERVE_DURATION, promptDelay)
    end

    self.session.timers.finish = C_Timer.NewTimer(OBSERVE_DURATION, function()
        if self.session then
            self:CancelObservation("Time expired.")
        end
    end)

    self.session.timers.prompt = C_Timer.NewTimer(promptDelay, function()
        if self.session then
            self:_BeginPrompt()
        end
    end)
end

-- The native binding entries call the same actions as the target button and
-- the three tool buttons. Only these binding entry points need to be global.
function FieldJournal_StartObservation()
    OS:StartObservation()
end

function FieldJournal_UseObservationTool(index)
    OS:PressPromptButton(index)
end
