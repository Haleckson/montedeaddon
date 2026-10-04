local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.UI = FieldJournal.UI or {}
FieldJournal.UI.Widgets = FieldJournal.UI.Widgets or {}

_G.FieldJournalPortraitVisualVersion = "frameless-v20-static-icons-displayid-2026-08-25"
_G.FieldJournalCreatureModelVersion = "displayid-tracking-icons-ui-2026-08-25"

-- =========================================================
-- CHRONICLE CHAPTERS / FIELD NOTES PATCH
-- Loaded through the existing Widgets.lua TOC entry, so no TOC change
-- is required. The patch is applied on PLAYER_LOGIN, after JournalFrame
-- and ChronicleSystem have been loaded.
-- =========================================================

local CHAPTERS = {
    { minLevel = 1,  maxLevel = 10, title = "Chapter I: Beginnings" },
    { minLevel = 11, maxLevel = 20, title = "Chapter II: Beyond Home" },
    { minLevel = 21, maxLevel = 30, title = "Chapter III: The Open Road" },
    { minLevel = 31, maxLevel = 40, title = "Chapter IV: Distant Lands" },
    { minLevel = 41, maxLevel = 50, title = "Chapter V: Trials of Azeroth" },
    { minLevel = 51, maxLevel = 59, title = "Chapter VI: Veteran's Path" },
    { minLevel = 60, maxLevel = 60, title = "Chapter VII: Forever" },
}

local function GetDB()
    FieldJournalDB = FieldJournalDB or {}
    FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}
    FieldJournalDB.encounters = FieldJournalDB.encounters or {}
    FieldJournalDB.creatureAppearances = FieldJournalDB.creatureAppearances or {}
    return FieldJournalDB
end

-- =========================================================
-- CREATURE APPEARANCE COLLECTION
-- Distinct lore-creature appearances are keyed by CreatureDisplayID.
-- Existing encounter records can be backfilled from their saved NPC IDs,
-- while future combat captures the exact live target DisplayID when possible.
-- =========================================================
local W = FieldJournal.UI.Widgets
local Compat = FieldJournal.Compat
local appearanceBackfillQueue = {}
local appearanceBackfillQueued = {}
local appearanceBackfillBusy = false
local liveCaptureModel = nil
local backfillCaptureModel = nil

local function GetCreatureNPCIDFromGUID(guid)
    return Compat:GetNPCID(guid)
end

local function GetAppearanceBucket(subjectID)
    if not subjectID then return nil end
    local db = GetDB()
    db.creatureAppearances[subjectID] = db.creatureAppearances[subjectID] or {}
    return db.creatureAppearances[subjectID]
end

local function GetOrCreateCaptureModel(kind)
    local model = kind == "live" and liveCaptureModel or backfillCaptureModel
    if model then return model end

    local ok, created = pcall(CreateFrame, "PlayerModel", nil, UIParent)
    if not ok or not created then
        return nil
    end

    created:SetSize(2, 2)
    created:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -100, -100)
    created:SetAlpha(0)
    created:EnableMouse(false)
    if created.SetKeepModelOnHide then
        created:SetKeepModelOnHide(true)
    end
    created:Show()

    if kind == "live" then
        liveCaptureModel = created
    else
        backfillCaptureModel = created
    end

    return created
end

function W:RecordCreatureAppearance(subjectID, displayID, npcID, npcName, source)
    displayID = tonumber(displayID)
    npcID = tonumber(npcID)
    if not subjectID or not displayID or displayID <= 0 then
        return nil, false
    end

    local bucket = GetAppearanceBucket(subjectID)
    if not bucket then return nil, false end

    local record = bucket[displayID]
    local isNew = false
    if not record then
        record = {
            displayID = displayID,
            npcID = npcID,
            name = npcName or (npcID and ("NPC " .. tostring(npcID))) or "Unknown Creature",
            firstSeen = date("%Y-%m-%d %H:%M:%S"),
            firstSeenTimestamp = time and time() or 0,
            source = source or "live",
            npcIDs = {},
        }
        bucket[displayID] = record
        isNew = true
    end

    record.npcIDs = record.npcIDs or {}
    if npcID then
        record.npcIDs[npcID] = true
        record.npcID = record.npcID or npcID
    end
    if npcName and npcName ~= "" and (not record.name or record.name == "Unknown Creature") then
        record.name = npcName
    end

    local encounter = npcID and GetDB().encounters[npcID] or nil
    if encounter then
        encounter.appearanceDisplayID = encounter.appearanceDisplayID or displayID
    end

    if isNew and self.RefreshCreatureAppearanceViewer then
        C_Timer.After(0, function()
            if W.RefreshCreatureAppearanceViewer then
                W:RefreshCreatureAppearanceViewer(subjectID)
            end
        end)
    end

    return record, isNew
end

function W:HasCreatureAppearanceForNPC(subjectID, npcID)
    npcID = tonumber(npcID)
    if not subjectID or not npcID then return false end

    local bucket = GetAppearanceBucket(subjectID)
    for _, record in pairs(bucket or {}) do
        if record.npcID == npcID or (record.npcIDs and record.npcIDs[npcID]) then
            return true
        end
    end
    return false
end

function W:CaptureCreatureAppearanceFromUnit(unit, expectedNPCID, npcName, subjectID)
    unit = unit or "target"
    if Compat:UnitFlag(UnitExists, unit) ~= true then return false end

    local guid = Compat:UnitGUID(unit)
    local npcID = GetCreatureNPCIDFromGUID(guid)
    if not npcID then return false end
    if expectedNPCID and tonumber(expectedNPCID) ~= npcID then return false end

    subjectID = subjectID or (FieldJournal.SubjectIndex
        and FieldJournal.SubjectIndex:Get(npcID, GetRealZoneText and GetRealZoneText()))
    if not subjectID then return false end

    local model = GetOrCreateCaptureModel("live")
    if not model or not model.SetUnit then return false end

    if model.ClearModel then model:ClearModel() end
    local ok = pcall(model.SetUnit, model, unit)
    if not ok then return false end

    local function TryRead()
        if Compat:UnitGUID(unit) ~= guid then return false end
        if not model.GetDisplayInfo then return false end
        local ok, displayID = pcall(model.GetDisplayInfo, model)
        if ok and Compat:IsSafe(displayID, "number") and displayID > 0 then
            W:RecordCreatureAppearance(subjectID, displayID, npcID, npcName or Compat:UnitName(unit), "live")
            return true
        end
        return false
    end

    if TryRead() then return true end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.08, TryRead)
        C_Timer.After(0.25, TryRead)
    end
    return true
end

local function ProcessAppearanceBackfillQueue()
    if appearanceBackfillBusy or #appearanceBackfillQueue == 0 then
        return
    end

    appearanceBackfillBusy = true
    local request = table.remove(appearanceBackfillQueue, 1)
    appearanceBackfillQueued[request.key] = nil

    if W:HasCreatureAppearanceForNPC(request.subjectID, request.npcID) then
        appearanceBackfillBusy = false
        ProcessAppearanceBackfillQueue()
        return
    end

    local model = GetOrCreateCaptureModel("backfill")
    if not model or not model.SetCreature then
        appearanceBackfillBusy = false
        return
    end

    if model.ClearModel then model:ClearModel() end
    local ok = pcall(model.SetCreature, model, request.npcID)
    if not ok then
        appearanceBackfillBusy = false
        C_Timer.After(0.05, ProcessAppearanceBackfillQueue)
        return
    end

    local completed = false
    local function Finish(success)
        if completed then return end
        if success then completed = true end
        if completed then
            appearanceBackfillBusy = false
            C_Timer.After(0.05, ProcessAppearanceBackfillQueue)
        end
    end

    local function TryRead(finalAttempt)
        if completed then return end
        local displayID = model.GetDisplayInfo and model:GetDisplayInfo() or nil
        if displayID and displayID > 0 then
            W:RecordCreatureAppearance(request.subjectID, displayID, request.npcID, request.name, request.source or "backfill")
            Finish(true)
            return
        end
        if finalAttempt then
            completed = true
            appearanceBackfillBusy = false
            C_Timer.After(0.05, ProcessAppearanceBackfillQueue)
        end
    end

    C_Timer.After(0.08, function() TryRead(false) end)
    C_Timer.After(0.25, function() TryRead(false) end)
    C_Timer.After(0.60, function() TryRead(true) end)
end

function W:QueueCreatureAppearanceByNPCID(npcID, npcName, subjectID, source)
    npcID = tonumber(npcID)
    if not npcID then return false end
    subjectID = subjectID or (FieldJournal.SubjectIndex
        and FieldJournal.SubjectIndex:Get(npcID, GetRealZoneText and GetRealZoneText()))
    if not subjectID or self:HasCreatureAppearanceForNPC(subjectID, npcID) then
        return false
    end

    local key = tostring(subjectID) .. ":" .. tostring(npcID)
    if appearanceBackfillQueued[key] then return false end
    appearanceBackfillQueued[key] = true
    table.insert(appearanceBackfillQueue, {
        key = key,
        npcID = npcID,
        name = npcName,
        subjectID = subjectID,
        source = source or "backfill",
    })
    ProcessAppearanceBackfillQueue()
    return true
end

function W:BootstrapExistingCreatureAppearances(subjectFilter)
    local db = GetDB()
    for npcID, encounter in pairs(db.encounters or {}) do
        if encounter and encounter.subjectData then
            for subjectID in pairs(encounter.subjectData) do
                if not subjectFilter or subjectID == subjectFilter then
                    self:QueueCreatureAppearanceByNPCID(npcID, encounter.name, subjectID, "legacy")
                end
            end
        else
            local subjectID = encounter and encounter.subjectID
            if subjectID and (not subjectFilter or subjectID == subjectFilter) then
                self:QueueCreatureAppearanceByNPCID(npcID, encounter.name, subjectID, "legacy")
            end
        end
    end
end

local function GetChapterIndexForLevel(level)
    level = tonumber(level)
    if not level then
        return nil
    end

    for i, chapter in ipairs(CHAPTERS) do
        if level >= chapter.minLevel and level <= chapter.maxLevel then
            return i
        end
    end

    return nil
end

FieldJournal.ChronicleChapters = FieldJournal.ChronicleChapters or {}
FieldJournal.ChronicleChapters.definitions = CHAPTERS
FieldJournal.ChronicleChapters.GetChapterIndexForLevel = GetChapterIndexForLevel

local function FormatTimestampString(value)
    if not value or value == "" then
        return nil
    end

    if type(value) == "number" then
        return date("%m/%d/%Y, %I:%M %p", value)
    end

    if type(value) ~= "string" then
        return tostring(value)
    end

    local year, month, day, hour, minute = string.match(
        value,
        "^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)"
    )

    if not year then
        return value
    end

    local hourNumber = tonumber(hour) or 0
    local suffix = "AM"
    local displayHour = hourNumber

    if hourNumber == 0 then
        displayHour = 12
    elseif hourNumber == 12 then
        displayHour = 12
        suffix = "PM"
    elseif hourNumber > 12 then
        displayHour = hourNumber - 12
        suffix = "PM"
    end

    return month .. "/" .. day .. "/" .. year .. ", " .. tostring(displayHour) .. ":" .. minute .. " " .. suffix
end

local function GetQuestDefinition(questID, record)
    local questDef = FieldJournal_QuestDB and FieldJournal_QuestDB[questID]
    if questDef then
        return questDef
    end

    return {
        title = record and record.title,
        zone = record and record.zone,
        subregion = record and record.subregion,
        npcName = record and record.npcName,
        npcID = record and record.npcID,
        summary = nil,
    }
end

local function ParseSortableTimestamp(value)
    if value == nil or value == "" then
        return nil
    end

    -- Chronicle entries and quest entries do not necessarily store their
    -- timestamps in the same representation. Normalize them to a comparable
    -- YYYYMMDDHHMMSS number without changing the SavedVariables themselves.
    if type(value) == "number" then
        local ok, normalized = pcall(date, "%Y%m%d%H%M%S", value)
        if ok and normalized then
            return tonumber(normalized)
        end
        return value
    end

    if type(value) ~= "string" then
        return nil
    end

    local numericValue = tonumber(value)
    if numericValue and string.match(value, "^%d+$") then
        local ok, normalized = pcall(date, "%Y%m%d%H%M%S", numericValue)
        if ok and normalized then
            return tonumber(normalized)
        end
    end

    local year, month, day, hour, minute, second = string.match(
        value,
        "^(%d%d%d%d)%-(%d%d)%-(%d%d)[ T](%d%d):(%d%d):?(%d?%d?)"
    )

    if year then
        second = (second and second ~= "") and second or "00"
        return tonumber(year .. month .. day .. hour .. minute .. second)
    end

    year, month, day = string.match(value, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if year then
        return tonumber(year .. month .. day .. "000000")
    end

    local m, d, y, h, min, ampm = string.match(
        value,
        "^(%d%d?)/(%d%d?)/(%d%d%d%d),?%s+(%d%d?):(%d%d)%s*([AaPp][Mm])"
    )

    if y then
        local hourNumber = tonumber(h) or 0
        local suffix = string.upper(ampm or "")

        if suffix == "PM" and hourNumber < 12 then
            hourNumber = hourNumber + 12
        elseif suffix == "AM" and hourNumber == 12 then
            hourNumber = 0
        end

        return tonumber(string.format(
            "%04d%02d%02d%02d%02d00",
            tonumber(y) or 0,
            tonumber(m) or 0,
            tonumber(d) or 0,
            hourNumber,
            tonumber(min) or 0
        ))
    end

    return nil
end

local function GetQuestEntriesForChapter(chapterIndex)
    local db = GetDB()
    local entries = {}

    for questID, record in pairs(db.completedQuests) do
        if GetChapterIndexForLevel(record and record.playerLevel) == chapterIndex then
            table.insert(entries, {
                source = "quest",
                level = tonumber(record.playerLevel),
                timestamp = record.completedAt or "",
                sortTimestamp = ParseSortableTimestamp(record.completedAt),
                questID = questID,
                record = record,
                definition = GetQuestDefinition(questID, record),
            })
        end
    end

    return entries
end

local function BuildQuestEntryText(item)
    local record = item.record or {}
    local questDef = item.definition or {}

    local levelText = tostring(record.playerLevel or "?")
    local timeText = FormatTimestampString(record.completedAt) or "an unknown time"
    local questTitle = questDef.title or record.title or ("Quest " .. tostring(item.questID))
    local summary = questDef.summary
    if not summary and record.description and record.description ~= "" then
        summary = "Quest giver's account: " .. record.description
        if record.objectives and record.objectives ~= "" then
            summary = summary .. "\nObjectives: " .. record.objectives
        end
    end
    summary = summary or "No field account recorded."

    local text = ""
    text = text .. "|cffffd100" .. questTitle .. "|r\n"
    text = text .. "|cff8a6a55Level " .. levelText .. ", " .. timeText .. " - " .. summary .. "|r\n\n"
    return text
end

-- =========================================================
-- EXISTING CHRONICLE ENTRY SUPPORT
-- Kept intentionally tolerant so it can read the v0.2.x Chronicle data
-- without migrating or rewriting SavedVariables.
-- =========================================================
local function LooksLikeChronicleEntry(value)
    if type(value) ~= "table" then
        return false
    end

    return value.type ~= nil
        or value.entryType ~= nil
        or value.timestamp ~= nil
        or value.completedAt ~= nil
        or value.level ~= nil
        or value.playerLevel ~= nil
        or value.characterLevel ~= nil
        or value.text ~= nil
        or value.narrative ~= nil
        or value.description ~= nil
        or value.rpText ~= nil
end

local function AddEntriesFromTable(results, sourceTable)
    if type(sourceTable) ~= "table" then
        return
    end

    -- Chronicle milestone tables are keyed by character level and can be
    -- sparse (for example [2], [3], [4] with no [1]). Always use pairs()
    -- so those entries are not skipped by ipairs() or the length operator.
    -- Chapter entries are explicitly sorted later, so table iteration order
    -- does not determine how they appear in the journal.
    for _, entry in pairs(sourceTable) do
        if LooksLikeChronicleEntry(entry) then
            table.insert(results, entry)
        end
    end
end

local function GetExistingChronicleEntries()
    local db = GetDB()
    local entries = {}
    local seen = {}

    local function AddUnique(sourceTable)
        local temp = {}
        AddEntriesFromTable(temp, sourceTable)

        for _, entry in ipairs(temp) do
            if not seen[entry] then
                seen[entry] = true
                table.insert(entries, entry)
            end
        end
    end

    local function AddDirectEntries(sourceTable)
        if type(sourceTable) ~= "table" then return end
        local direct = {}
        for key, entry in pairs(sourceTable) do
            -- Preserve old flat numeric Chronicle entries. Named fields such
            -- as currentAppearance are state, not historical entries, even
            -- when they contain a level and a refresh timestamp.
            if type(key) == "number"
                or (type(key) == "string" and key:match("^%d+$")) then
                table.insert(direct, entry)
            end
        end
        AddUnique(direct)
    end

    AddUnique(db.chronicleEntries)
    AddUnique(db.ChronicleEntries)
    AddUnique(db.levelMilestones)
    AddUnique(db.nearDeathEntries)
    AddUnique(db.nearDeaths)

    if type(db.chronicle) == "table" then
        AddUnique(db.chronicle.entries)
        AddUnique(db.chronicle.levelEntries)
        AddUnique(db.chronicle.milestones)
        AddUnique(db.chronicle.nearDeathEntries)
        AddUnique(db.chronicle.nearDeaths)
        AddUnique(db.chronicle.deaths)
        AddDirectEntries(db.chronicle)
    end

    if type(db.Chronicle) == "table" then
        AddUnique(db.Chronicle.entries)
        AddUnique(db.Chronicle.levelEntries)
        AddUnique(db.Chronicle.nearDeathEntries)
        AddUnique(db.Chronicle.nearDeaths)
        AddDirectEntries(db.Chronicle)
    end

    local CS = FieldJournal.ChronicleSystem
    if CS then
        local accessors = {
            "GetEntries",
            "GetChronicleEntries",
            "GetAllEntries",
            "GetHistory",
        }

        for _, methodName in ipairs(accessors) do
            local method = CS[methodName]
            if type(method) == "function" then
                local ok, returned = pcall(method, CS)
                if ok and type(returned) == "table" then
                    AddUnique(returned)
                    break
                end
            end
        end
    end

    return entries
end

local function GetEntryLevel(entry)
    if not entry then return nil end

    return tonumber(
        entry.level
        or entry.playerLevel
        or entry.characterLevel
        or entry.levelReached
        or entry.newLevel
    )
end

local function GetEntryType(entry)
    if not entry then return "" end
    local value = entry.type or entry.entryType or entry.kind or ""
    return type(value) == "string" and string.upper(value) or ""
end

local function IsQuestChronicleEntry(entry)
    local entryType = GetEntryType(entry)
    return entryType == "QUEST"
        or entryType == "QUEST_COMPLETED"
        or entryType == "QUEST_TURNED_IN"
        or entryType == "QUESTTURNEDIN"
end

local function GetEntryTimestampValue(entry)
    if not entry then return nil end

    local value = entry.completedAt
        or entry.timestampText
        or entry.dateTime
        or entry.createdAt
        or entry.recordedAt
        or entry.timestamp
        or entry.eventTime

    -- Some Chronicle implementations store the calendar date and clock time
    -- separately. Combine them only for display/sorting; do not modify entry.
    if not value and entry.date and entry.time then
        value = tostring(entry.date) .. " " .. tostring(entry.time)
    end

    return value or entry.time or entry.date or ""
end

local function GetEntryTimestamp(entry)
    local value = GetEntryTimestampValue(entry)

    if type(value) == "number" then
        return tostring(value)
    end

    return tostring(value or "")
end

local function CallStringMethod(owner, method, ...)
    if type(method) ~= "function" then
        return nil
    end

    local ok, result = pcall(method, owner, ...)
    if ok and type(result) == "string" and result ~= "" then
        return result
    end

    -- Also support helper functions that were defined with dot syntax rather
    -- than colon syntax. This is read-only and preserves the existing system.
    ok, result = pcall(method, ...)
    if ok and type(result) == "string" and result ~= "" then
        return result
    end

    return nil
end

local function GetChronicleFormatterOwners()
    local owners = {}
    local seen = {}

    local function Add(owner)
        if type(owner) == "table" and not seen[owner] then
            seen[owner] = true
            table.insert(owners, owner)
        end
    end

    Add(FieldJournal.ChronicleSystem)
    Add(FieldJournal.NearDeathSystem)
    Add(FieldJournal.NearDeath)
    Add(FieldJournal.Chronicle)

    if FieldJournal.UI then
        Add(FieldJournal.UI.JournalFrame)
    end

    return owners
end

local function IsNearDeathFallbackText(text)
    if type(text) ~= "string" or text == "" then
        return false
    end

    local lower = string.lower(text)

    -- These are generic failure/fallback messages, not the RP account itself.
    -- Do not let one formatter returning a fallback prevent a later formatter
    -- from resolving the saved near-death template correctly.
    if string.find(lower, "dangerous encounter", 1, true)
        and string.find(lower, "details were lost", 1, true) then
        return true
    end

    if string.find(lower, "no account was recorded", 1, true) then
        return true
    end

    return false
end

local function TryChronicleSystemFormatter(entry, rejectNearDeathFallbacks)
    local formatters = {
        "FormatEntry",
        "BuildEntryText",
        "GetEntryText",
        "FormatChronicleEntry",
        "FormatNearDeathEntry",
        "BuildNearDeathEntryText",
        "GetNearDeathEntryText",
    }

    for _, owner in ipairs(GetChronicleFormatterOwners()) do
        for _, methodName in ipairs(formatters) do
            local result = CallStringMethod(owner, owner[methodName], entry)
            if result then
                if not rejectNearDeathFallbacks or not IsNearDeathFallbackText(result) then
                    return result
                end
            end
        end
    end

    return nil
end

local function ExtractNarrativeText(value)
    if type(value) == "string" and value ~= "" then
        return value
    end

    if type(value) ~= "table" then
        return nil
    end

    local fields = {
        "text",
        "narrative",
        "description",
        "summary",
        "message",
        "rpText",
        "flavorText",
        "flavor",
        "body",
    }

    for _, fieldName in ipairs(fields) do
        local text = value[fieldName]
        if type(text) == "string" and text ~= "" then
            return text
        end
    end

    if type(value[1]) == "string" and value[1] ~= "" then
        return value[1]
    end

    return nil
end

local function LookupTemplateValue(container, templateID)
    if type(container) ~= "table" or templateID == nil then
        return nil
    end

    local candidates = { templateID }
    local numericID = tonumber(templateID)
    local stringID = tostring(templateID)

    if numericID ~= nil and numericID ~= templateID then
        table.insert(candidates, numericID)
    end
    if stringID ~= templateID then
        table.insert(candidates, stringID)
    end

    for _, key in ipairs(candidates) do
        local value = container[key]
        local text = ExtractNarrativeText(value)
        if text then
            return text
        end
    end

    return nil
end

local function ResolveNearDeathNarrative(entry)
    if not entry or entry.templateID == nil then
        return nil
    end

    local templateID = entry.templateID
    local getterNames = {
        "GetNearDeathNarrative",
        "GetNearDeathTemplate",
        "GetNarrativeByID",
        "GetTemplateByID",
        "GetTemplateText",
        "ResolveNarrative",
        "ResolveTemplate",
        "GetNarrative",
        "GetTemplate",
    }

    -- JournalFrame's native Chronicle rendering passes the entire incident to
    -- GetNearDeathNarrative(). Preserve that exact calling convention first.
    -- Other template helpers may accept the template ID directly.
    for _, owner in ipairs(GetChronicleFormatterOwners()) do
        for _, methodName in ipairs(getterNames) do
            local method = owner[methodName]
            if type(method) == "function" then
                local result

                if methodName == "GetNearDeathNarrative" then
                    result = CallStringMethod(owner, method, entry)
                    if result and IsNearDeathFallbackText(result) then
                        result = nil
                    end
                end

                if not result then
                    result = CallStringMethod(owner, method, templateID)
                    if result and IsNearDeathFallbackText(result) then
                        result = nil
                    end
                end

                if not result and methodName ~= "GetNearDeathNarrative" then
                    result = CallStringMethod(owner, method, entry)
                    if result and IsNearDeathFallbackText(result) then
                        result = nil
                    end
                end

                if result then
                    return result
                end
            end
        end
    end

    -- If the templates are exposed as a table instead of through a getter,
    -- read the matching template directly. We intentionally inspect only
    -- template/narrative-named containers to avoid matching unrelated arrays.
    local specificContainerNames = {
        "NearDeathTemplates",
        "nearDeathTemplates",
        "NEAR_DEATH_TEMPLATES",
        "NearDeathNarratives",
        "nearDeathNarratives",
        "NEAR_DEATH_NARRATIVES",
        "RPNarratives",
        "rpNarratives",
        "RPTemplates",
        "rpTemplates",
    }

    for _, owner in ipairs(GetChronicleFormatterOwners()) do
        for _, containerName in ipairs(specificContainerNames) do
            local text = LookupTemplateValue(owner[containerName], templateID)
            if text then
                return text
            end
        end

        for fieldName, value in pairs(owner) do
            if type(fieldName) == "string" and type(value) == "table" then
                local lowerName = string.lower(fieldName)
                if string.find(lowerName, "template", 1, true)
                    or string.find(lowerName, "narrative", 1, true)
                    or string.find(lowerName, "flavor", 1, true) then

                    local text = LookupTemplateValue(value, templateID)
                    if text then
                        return text
                    end
                end
            end
        end
    end

    for _, containerName in ipairs(specificContainerNames) do
        local text = LookupTemplateValue(FieldJournal[containerName], templateID)
        if text then
            return text
        end
    end

    local globalContainerNames = {
        "FieldJournal_NearDeathTemplates",
        "FieldJournal_NearDeathNarratives",
        "FIELDJOURNAL_NEAR_DEATH_TEMPLATES",
        "FIELDJOURNAL_NEAR_DEATH_NARRATIVES",
    }

    for _, globalName in ipairs(globalContainerNames) do
        local text = LookupTemplateValue(_G and _G[globalName], templateID)
        if text then
            return text
        end
    end

    return nil
end

local function GetEntryTitle(entry)
    if entry.title and entry.title ~= "" then
        return entry.title
    end

    local entryType = GetEntryType(entry)

    if entryType == "NEAR_DEATH" or entryType == "NEARDEATH" or entryType == "NEAR-DEATH" then
        return "A Narrow Escape"
    elseif entryType == "LEVEL" or entryType == "LEVEL_UP" or entryType == "LEVELUP" or entryType == "MILESTONE" then
        return "A New Milestone"
    elseif entryType == "SUBREGION" or entryType == "SUBREGION_DISCOVERED" then
        return "A Place Discovered"
    elseif entryType == "SUBJECT" or entryType == "SUBJECT_DISCOVERED" then
        return "A New Discovery"
    end

    return "Chronicle Entry"
end

local function IsLevelMilestoneEntry(entry)
    if type(entry) ~= "table" or not GetEntryLevel(entry) then
        return false
    end

    -- ChronicleSystem milestones are stored in chronicle.milestones and do not
    -- carry a type/entryType field. Identify the native milestone structure so
    -- chapter pages can render it with the same RP formatting as JournalFrame.
    return entry.reachedAt ~= nil
        and entry.location ~= nil
        and (
            entry.previousLevel ~= nil
            or entry.questCount ~= nil
            or entry.questTitles ~= nil
            or entry.questGivers ~= nil
            or entry.discoveredSubjects ~= nil
            or entry.discoveredSubregions ~= nil
        )
end

local function BuildLevelMilestoneText(milestone)
    local CS = FieldJournal.ChronicleSystem
    if not CS then
        return nil
    end

    local level = GetEntryLevel(milestone) or "?"
    local location = CS.FormatLocation and CS:FormatLocation(milestone.location) or "Unknown Zone"
    local reachedAt = CS.FormatReachedAt and CS:FormatReachedAt(milestone.reachedAt) or FormatTimestampString(milestone.reachedAt) or "Unknown date"
    local narrative = CS.GetMilestoneNarrative and CS:GetMilestoneNarrative(milestone) or "No account was recorded."

    local text = ""
    text = text .. "|cffffd100LEVEL " .. tostring(level) .. "|r\n"
    text = text .. "|cffffffff" .. tostring(location) .. "|r\n"
    text = text .. "|cff8a6a55" .. tostring(reachedAt) .. "|r\n"
    text = text .. "|cff8a6a55" .. tostring(narrative) .. "|r\n\n"

    return text
end

local function BuildGenericChronicleEntryText(entry)
    if GetEntryType(entry) == "DEATH" then
        local CS = FieldJournal.ChronicleSystem
        local location = CS and CS.FormatLocation and CS:FormatLocation(entry.location) or "Unknown Zone"
        local occurredAt = CS and CS.FormatReachedAt and CS:FormatReachedAt(entry.occurredAt)
            or FormatTimestampString(entry.occurredAt) or "Unknown date"
        local killer = entry.killerName and entry.killerName ~= ""
            and ("|cffff6b6bDied to: " .. entry.killerName
                .. (entry.killerClass and (" (" .. entry.killerClass .. ")") or "") .. "|r\n") or ""
        return "|cffff6b6bDEATH|r\n"
            .. "|cffffffff" .. location .. "|r\n"
            .. "|cff8a6a55" .. occurredAt .. "|r\n"
            .. "|cff8a6a55Level " .. tostring(entry.level or "?") .. "|r\n"
            .. killer .. "\n"
    end

    if IsLevelMilestoneEntry(entry) then
        local milestoneText = BuildLevelMilestoneText(entry)
        if milestoneText then
            return milestoneText
        end
    end
    local entryType = GetEntryType(entry)
    local isNearDeath = entryType:find("NEAR") ~= nil

    -- Near-death entries have a deliberate resolution order so an old generic
    -- formatter fallback cannot hide a still-valid saved templateID:
    -- saved RP text -> saved templateID -> existing formatter -> factual fallback.
    local narrative = entry.text
        or entry.narrative
        or entry.description
        or entry.summary
        or entry.message
        or entry.rpText
        or entry.flavorText

    -- Never treat one of the Chronicle system's generic failure messages as
    -- the saved RP account. Continue to the template/incident recovery path.
    if isNearDeath and narrative and IsNearDeathFallbackText(narrative) then
        narrative = nil
    end

    if isNearDeath and not narrative then
        narrative = ResolveNearDeathNarrative(entry)
    end

    if isNearDeath and not narrative then
        local formatted = TryChronicleSystemFormatter(entry, true)
        if formatted then
            if string.sub(formatted, -1) ~= "\n" then
                formatted = formatted .. "\n"
            end
            return formatted .. "\n"
        end
    elseif not isNearDeath then
        local formatted = TryChronicleSystemFormatter(entry, false)
        if formatted then
            if string.sub(formatted, -1) ~= "\n" then
                formatted = formatted .. "\n"
            end
            return formatted .. "\n"
        end
    end

    local title = GetEntryTitle(entry)

    if not narrative then
        if isNearDeath then
            narrative = "The encounter was recorded, but its original account could not be recovered."
        else
            narrative = "No account was recorded."
        end
    end

    local details = {}
    local level = GetEntryLevel(entry)
    local timestamp = FormatTimestampString(
        entry.completedAt
        or entry.dateTime
        or entry.createdAt
        or entry.recordedAt
        or entry.timestamp
        or entry.time
    )
    local zone = entry.zone or entry.zoneName
    local subzone = entry.subZone or entry.subzone or entry.subregion or entry.minimapArea

    if level then
        table.insert(details, "Level " .. tostring(level))
    end

    if timestamp and timestamp ~= "" then
        table.insert(details, timestamp)
    end

    if zone and zone ~= "" then
        local location = zone
        if subzone and subzone ~= "" and subzone ~= zone then
            location = location .. " - " .. subzone
        end
        table.insert(details, location)
    end

    local attacker = entry.attacker or entry.attackerName or entry.mobName or entry.enemyName
    if attacker and attacker ~= "" and (GetEntryType(entry):find("NEAR") ~= nil) then
        table.insert(details, "Last struck by " .. tostring(attacker))
    end

    local text = "|cffffd100" .. title .. "|r\n"

    if #details > 0 then
        text = text .. "|cff8a6a55" .. table.concat(details, ", ") .. " - " .. tostring(narrative) .. "|r\n\n"
    else
        text = text .. "|cff8a6a55" .. tostring(narrative) .. "|r\n\n"
    end

    return text
end

local function GetChronicleEntriesForChapter(chapterIndex)
    local results = {}

    for _, entry in ipairs(GetExistingChronicleEntries()) do
        if not IsQuestChronicleEntry(entry)
            and GetChapterIndexForLevel(GetEntryLevel(entry)) == chapterIndex then

            table.insert(results, {
                source = "chronicle",
                level = GetEntryLevel(entry),
                timestamp = GetEntryTimestamp(entry),
                sortTimestamp = ParseSortableTimestamp(GetEntryTimestampValue(entry)),
                entry = entry,
            })
        end
    end

    return results
end

local function GetCombinedChapterEntries(chapterIndex)
    local entries = GetQuestEntriesForChapter(chapterIndex)

    for _, item in ipairs(GetChronicleEntriesForChapter(chapterIndex)) do
        table.insert(entries, item)
    end

    table.sort(entries, function(a, b)
        local aLevel = tonumber(a.level) or math.huge
        local bLevel = tonumber(b.level) or math.huge

        -- Chronicle chapters read as a character progression first.
        if aLevel ~= bLevel then
            return aLevel < bLevel
        end

        -- Within the same character level, preserve the actual event order.
        local aSortTime = a.sortTimestamp
        local bSortTime = b.sortTimestamp

        if aSortTime ~= nil and bSortTime ~= nil and aSortTime ~= bSortTime then
            return aSortTime < bSortTime
        elseif aSortTime ~= nil and bSortTime == nil then
            return true
        elseif aSortTime == nil and bSortTime ~= nil then
            return false
        end

        local aTime = tostring(a.timestamp or "")
        local bTime = tostring(b.timestamp or "")
        if aTime ~= bTime then
            return aTime < bTime
        end

        return tostring(a.source or "") < tostring(b.source or "")
    end)

    return entries
end

local function BuildChapterContent(chapterIndex)
    local chapter = CHAPTERS[chapterIndex]
    if not chapter then
        return "", {}
    end

    local entries = GetCombinedChapterEntries(chapterIndex)
    local rangeText

    if chapter.minLevel == chapter.maxLevel then
        rangeText = "Level " .. tostring(chapter.minLevel)
    else
        rangeText = "Levels " .. tostring(chapter.minLevel) .. "-" .. tostring(chapter.maxLevel)
    end

    local header = "|cff8a6a55" .. rangeText .. "|r\n\n"
    local blocks = {}

    if #entries == 0 then
        blocks[1] = "|c88888888No Chronicle entries recorded in this chapter yet.|r\n\n"
        return header, blocks
    end

    for _, item in ipairs(entries) do
        if item.source == "quest" then
            blocks[#blocks + 1] = BuildQuestEntryText(item)
        elseif item.source == "chronicle" then
            blocks[#blocks + 1] = BuildGenericChronicleEntryText(item.entry)
        end
    end

    return header, blocks
end

local function ApplyPatch()
    if FieldJournal.UI.Widgets.chronicleChaptersApplied then
        return
    end

    local frame = FieldJournal.UI and FieldJournal.UI.JournalFrame
    if not frame then
        return
    end

    FieldJournal.UI.Widgets.chronicleChaptersApplied = true
    FieldJournal.UI.Widgets.chapterPortraitLayoutVersion = "frameless-v20-static-icons-displayid-2026-08-25"
    frame.chapterButtons = frame.chapterButtons or {}
    frame.chapterPortraits = frame.chapterPortraits or {}

    -- The portrait area uses two reusable DressUpModel frames. Historical
    -- equipment is reconstructed from the item links captured by
    -- ChronicleSystem at chapter boundaries. No screenshot files are loaded.
    local PORTRAIT_CLOTHING_SLOTS = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 19 }
    local PORTRAIT_CAMERA_DISTANCE = 0.8103375 -- Another 5% farther than 0.77175.
    -- frame.left is centered three units left of the book's left-page midpoint.
    local PAGE_CENTER_OFFSET = 3
    local PORTRAIT_SPREAD = 125


    local function CreatePortraitPanel(centerOffset)
        -- Invisible positioning holder only. No BackdropTemplate and no
        -- backdrop/border textures are created for chapter portraits.
        local panel = CreateFrame("Frame", nil, frame.left)
        panel:SetSize(180, 350)
        panel:SetPoint("TOP", frame.left, "TOP", centerOffset, -63)
        panel:EnableMouse(false)

        local ok, model = pcall(CreateFrame, "DressUpModel", nil, panel)
        if ok and model then
            panel.model = model
            -- Larger equal viewports, centered symmetrically on the page.
            model:SetSize(180, 300)
            model:SetPoint("TOP", panel, "TOP", 0, -1)
            model:EnableMouse(false)
            model:Hide()
        end

        panel.label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if panel.model then
            panel.label:SetPoint("TOP", panel.model, "BOTTOM", 0, -2)
        else
            panel.label:SetPoint("BOTTOM", panel, "BOTTOM", 0, 5)
        end
        panel.label:SetWidth(180)
        panel.label:SetJustifyH("CENTER")
        panel.label:SetTextColor(1.0, 0.82, 0.0, 1)

        panel.snapshot = nil
        panel:Hide()
        return panel
    end

    if not frame.chapterPortraits.start then
        frame.chapterPortraits.start = CreatePortraitPanel(PAGE_CENTER_OFFSET - PORTRAIT_SPREAD)
    end

    if not frame.chapterPortraits.finish then
        frame.chapterPortraits.finish = CreatePortraitPanel(PAGE_CENTER_OFFSET + PORTRAIT_SPREAD)
    end

    local function HideChapterPortraits()
        for _, panel in pairs(frame.chapterPortraits) do
            panel.snapshot = nil
            if panel.model then
                panel.model:Hide()
            end
            panel:Hide()
        end
    end

    local function TryOnSnapshot(model, snapshot)
        if not model or not snapshot then
            return
        end

        if model.SetAutoDress then
            model:SetAutoDress(false)
        end

        if model.ClearModel then
            model:ClearModel()
        end

        if model.SetUnit then
            model:SetUnit("player")
        end

        if model.Undress then
            model:Undress()
        end

        local items = snapshot.items or {}

        for _, slotID in ipairs(PORTRAIT_CLOTHING_SLOTS) do
            local itemLink = items[slotID]

            if slotID == 1 and snapshot.showHelm == false then
                itemLink = nil
            elseif slotID == 15 and snapshot.showCloak == false then
                itemLink = nil
            end

            if itemLink and model.TryOn then
                model:TryOn(itemLink)
            end
        end

        -- Apply weapons after clothing. Main/off-hand are preferred because
        -- they match the ordinary paper-doll presentation. If no melee weapon
        -- was equipped, fall back to the ranged slot for classes that use one.
        local mainHand = items[16]
        local offHand = items[17]
        local ranged = items[18]

        if mainHand and model.TryOn then
            model:TryOn(mainHand, (_G and _G.MAINHANDSLOT) or "Main Hand")
        end

        if offHand and model.TryOn then
            model:TryOn(offHand, (_G and _G.SECONDARYHANDSLOT) or "Off Hand")
        end

        if not mainHand and not offHand and ranged and model.TryOn then
            model:TryOn(ranged)
        end

        if model.SetSheathed then
            model:SetSheathed(false, false)
        end

        if model.SetPortraitZoom then
            model:SetPortraitZoom(0)
        end
        if model.SetCamDistanceScale then
            model:SetCamDistanceScale(PORTRAIT_CAMERA_DISTANCE)
        end

        if model.SetRotation then
            model:SetRotation(math.rad(10))
        end
    end

    local function ShowLivePlayerInPanel(panel, label)
        if not panel then
            return
        end

        panel.label:SetText(label or "")
        panel.snapshot = "__FIELDJOURNAL_LIVE__"
        panel:Show()

        local model = panel.model
        if not model then
            return
        end

        model:Show()
        if model.SetAutoDress then
            model:SetAutoDress(true)
        end
        if model.ClearModel then
            model:ClearModel()
        end
        if model.SetUnit then
            model:SetUnit("player")
        end
        if model.SetSheathed then
            model:SetSheathed(false, false)
        end
        if model.SetPortraitZoom then
            model:SetPortraitZoom(0)
        elseif model.SetCamera then
            model:SetCamera(1)
        end
        if model.SetCamDistanceScale then
            model:SetCamDistanceScale(PORTRAIT_CAMERA_DISTANCE)
        end
        if model.SetRotation then
            model:SetRotation(math.rad(10))
        elseif model.SetFacing then
            model:SetFacing(0)
        end
    end

    local function ShowSnapshotInPanel(panel, label, snapshot)
        if not panel then
            return
        end

        panel.label:SetText(label or "")
        panel.snapshot = snapshot
        panel:Show()

        if not snapshot or not panel.model then
            if panel.model then
                panel.model:Hide()
            end
            return
        end

        TryOnSnapshot(panel.model, snapshot)
        panel.model:Show()

        -- A second dress pass handles item appearances whose data was still
        -- pending during the first frame after the chapter was opened.
        if C_Timer and C_Timer.After then
            C_Timer.After(0.25, function()
                if panel:IsShown() and panel.snapshot == snapshot and panel.model then
                    TryOnSnapshot(panel.model, snapshot)
                    panel.model:Show()
                end
            end)
        end
    end

    local function ShowChapterPortraits(chapterIndex)
        local chapter = CHAPTERS[chapterIndex]
        local CS = FieldJournal.ChronicleSystem

        if not chapter or not CS then
            HideChapterPortraits()
            return
        end

        -- Establish/repair the one compatibility portrait for the character's
        -- current chapter before reading the snapshots used by this page.
        local bootstrapSnapshot, bootstrapTarget
        if CS.BootstrapChapterAppearance then
            bootstrapSnapshot, bootstrapTarget = CS:BootstrapChapterAppearance()
        end

        if chapterIndex == 7 then
            local level60 = CS.GetAppearanceSnapshot and CS:GetAppearanceSnapshot(60) or nil
            local current

            if CS.RefreshCurrentAppearance then
                current = CS:RefreshCurrentAppearance()
            elseif CS.GetCurrentAppearance then
                current = CS:GetCurrentAppearance()
            end

            if level60 then
                ShowSnapshotInPanel(frame.chapterPortraits.start, "Level 60", level60)
            elseif bootstrapTarget == 60 and (UnitLevel and UnitLevel("player") or 0) >= 60 then
                -- First-install fallback: show the live player immediately even
                -- if Classic has not yet returned inventory data for persistence.
                ShowLivePlayerInPanel(frame.chapterPortraits.start, "Level 60")
            else
                ShowSnapshotInPanel(frame.chapterPortraits.start, "Level 60", nil)
            end

            if (UnitLevel and UnitLevel("player") or 0) >= 60 then
                if current then
                    ShowSnapshotInPanel(frame.chapterPortraits.finish, "Current", current)
                else
                    ShowLivePlayerInPanel(frame.chapterPortraits.finish, "Current")
                end
            else
                ShowSnapshotInPanel(frame.chapterPortraits.finish, "Current", nil)
            end
            return
        end

        local startLevel = chapter.minLevel
        local endLevel = chapter.maxLevel
        local startSnapshot = CS.GetAppearanceSnapshot and CS:GetAppearanceSnapshot(startLevel) or nil
        local endSnapshot = CS.GetAppearanceSnapshot and CS:GetAppearanceSnapshot(endLevel) or nil

        if startSnapshot then
            ShowSnapshotInPanel(frame.chapterPortraits.start, "Level " .. tostring(startLevel), startSnapshot)
        elseif bootstrapTarget == startLevel then
            ShowLivePlayerInPanel(frame.chapterPortraits.start, "Level " .. tostring(startLevel))
        else
            ShowSnapshotInPanel(frame.chapterPortraits.start, "Level " .. tostring(startLevel), nil)
        end

        if endSnapshot then
            ShowSnapshotInPanel(frame.chapterPortraits.finish, "Level " .. tostring(endLevel), endSnapshot)
        elseif bootstrapTarget == endLevel then
            ShowLivePlayerInPanel(frame.chapterPortraits.finish, "Level " .. tostring(endLevel))
        else
            ShowSnapshotInPanel(frame.chapterPortraits.finish, "Level " .. tostring(endLevel), nil)
        end
    end

    function W:PreviewAppearanceSnapshot(snapshot)
        if not snapshot or not frame.chapterPortraits.finish
            or not frame.chapterPortraits.finish.model then
            return false
        end

        local level = tonumber(snapshot.level) or 1
        local chapterIndex = 1
        for i, chapter in ipairs(CHAPTERS) do
            if level >= chapter.minLevel then chapterIndex = i end
        end

        if not frame:IsShown() then frame:Show() end
        frame:ShowChronicleChapter(chapterIndex)
        ShowSnapshotInPanel(frame.chapterPortraits.finish, "Test (Lv " .. level .. ")", snapshot)
        return true
    end

    local function PlayButtonSound()
        if FieldJournal.UI.PlayJournalSound then
            FieldJournal.UI:PlayJournalSound("button")
        elseif PlaySound then
            PlaySound((SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN) or 836)
        end
    end

    local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII" }
    local function CreateChapterButton(index)
        local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        button:SetSize(38, 34)
        -- Center the seven chapter tabs over the right-hand page.
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 675 + (index - 1) * 44, -6)
        button:SetText(ROMAN[index])
        if FieldJournal.UI.AddGoldMenuTrim then
            FieldJournal.UI:AddGoldMenuTrim(button)
        end
        button:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(CHAPTERS[index].title)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        return button
    end

    local function HideChapterButtons()
        for _, button in ipairs(frame.chapterButtons) do
            button:Hide()
            button:SetScript("OnClick", nil)
        end

        HideChapterPortraits()
    end

    local function HideStandardButtons()
        if frame.HideGrid then
            frame:HideGrid()
        elseif frame.HideAllButtons then
            frame:HideAllButtons()
        elseif frame.buttons then
            for _, button in ipairs(frame.buttons) do
                button:Hide()
            end
        end
    end

    local function HideChronicleNavigationButtons()
        -- The two section tabs now belong to the permanent top navigation.
        if frame.ShowNavigationButtons then frame:ShowNavigationButtons() end
    end

    local function ResetRightSideForChronicle()
        if frame.ResetSubjectTitle then
            frame:ResetSubjectTitle()
        elseif frame.subjectTitle then
            frame.subjectTitle:SetText("")
            frame.subjectTitle:Hide()
        end

        if frame.HideCreatureRows then
            frame:HideCreatureRows()
        end

        if frame.UseNormalRightText then
            frame:UseNormalRightText()
        end
    end

    local function ResizeChronicleText()
        if frame.ResizeScrollContent then
            frame:ResizeScrollContent(0)
        elseif frame.scrollChild and frame.right and frame.right.text then
            local textHeight = frame.right.text:GetStringHeight() or 0
            frame.scrollChild:SetHeight(math.max(400, textHeight + 40))
        end

        if frame.scrollFrame then
            frame.scrollFrame:SetVerticalScroll(0)
        end
    end

    local function RenameZoneButtons(parent, depth)
        depth = depth or 0
        if not parent or depth > 4 or not parent.GetChildren then
            return
        end

        local children = { parent:GetChildren() }
        for _, child in ipairs(children) do
            if child.GetText and child.SetText then
                local text = child:GetText()
                if text == "Zones" then
                    child:SetText("Field Notes")
                end
            end
            RenameZoneButtons(child, depth + 1)
        end
    end

    local function ApplyFieldNotesLabel()
        if frame.leftHeader and frame.leftHeader:GetText() == "Zones" then
            frame.leftHeader:SetText("Field Notes")
        end
        RenameZoneButtons(frame, 0)
    end

    local function StripAdventureBlockFromZonePage()
        if not frame.right or not frame.right.text then
            return
        end

        local text = frame.right.text:GetText()
        if type(text) ~= "string" or text == "" then
            return
        end

        local marker = "|cffffd100ADVENTURES IN "
        local markerStart = string.find(text, marker, 1, true)

        if markerStart then
            local trimmed = string.sub(text, 1, markerStart - 1)
            trimmed = trimmed:gsub("%s+$", "") .. "\n\n"
            frame.right.text:SetText(trimmed)
            ResizeChronicleText()
        end
    end

    function frame:ShowChronicleChapter(chapterIndex, requestedPage)
        local chapter = CHAPTERS[chapterIndex]
        if not chapter then
            return
        end

        self.state = self.state or {}
        self.state.mode = "chronicleChapter"
        self.state.chapter = chapterIndex
        self.state.zone = nil
        self.state.subject = nil

        if self.title then
            self.title:Show()
            self.title:SetText("Field Journal")
        end

        if self.leftHeader then
            self.leftHeader:SetText("")
        end
        if self.HideLandingGuide then self:HideLandingGuide() end
        if self.SetActiveSection then self:SetActiveSection("chronicle") end

        if self.backBtn then
            self.backBtn:Show()
        end

        HideStandardButtons()
        HideChronicleNavigationButtons()
        HideChapterButtons()
        ResetRightSideForChronicle()

        if self.subjectTitle then
            self.subjectTitle:SetFont("Fonts\\MORPHEUS.ttf", 24, "")
            self.subjectTitle:SetText(chapter.title)
            self.subjectTitle:Show()
            self.right.text:ClearAllPoints()
            self.right.text:SetPoint("TOPLEFT", self.subjectTitle, "BOTTOMLEFT", 0, -10)
        end

        if self.right and self.right.text then
            local header, blocks = BuildChapterContent(chapterIndex)
            local pages = FieldJournal.UI and FieldJournal.UI.Pagination
            if pages then
                pages:Show(self, "chapter:" .. chapterIndex, header, blocks, requestedPage)
            else
                self.right.text:SetText(header .. table.concat(blocks))
                ResizeChronicleText()
            end
        end

        for i in ipairs(CHAPTERS) do
            if not self.chapterButtons[i] then
                self.chapterButtons[i] = CreateChapterButton(i)
            end

            local button = self.chapterButtons[i]
            button:SetAlpha(i == chapterIndex and 1 or .76)
            button:SetScript("OnClick", function()
                PlayButtonSound()
                frame:ShowChronicleChapter(i, 1)
            end)
            button:Show()
        end

        ShowChapterPortraits(chapterIndex)

    end

    local originalShowChronicle = frame.ShowChronicle

    function frame:ShowChronicle()
        -- Enter directly on a chapter, with the two portraits filling the left page.
        local index = self.state and self.state.chapter
        if not index or not CHAPTERS[index] then
            local level = UnitLevel and UnitLevel("player") or 1
            index = 1
            for i, chapter in ipairs(CHAPTERS) do
                if level >= chapter.minLevel then index = i end
            end
        end
        self:ShowChronicleChapter(index, 1)
    end

    local originalShowZones = frame.ShowZones
    if type(originalShowZones) == "function" then
        function frame:ShowZones(...)
            HideChapterButtons()
            local results = { originalShowZones(self, ...) }
            ApplyFieldNotesLabel()
            return unpack(results)
        end
    end

    local originalShowZone = frame.ShowZone
    if type(originalShowZone) == "function" then
        function frame:ShowZone(...)
            HideChapterButtons()
            local results = { originalShowZone(self, ...) }
            StripAdventureBlockFromZonePage()
            return unpack(results)
        end
    end

    local originalShowSubject = frame.ShowSubject
    if type(originalShowSubject) == "function" then
        function frame:ShowSubject(...)
            HideChapterButtons()
            return originalShowSubject(self, ...)
        end
    end

    -- Main/landing page wrappers, if present in the current Chronicle UI.
    local mainMethods = { "ShowMain", "ShowLanding", "ShowHome", "ShowJournalHome" }
    for _, methodName in ipairs(mainMethods) do
        local original = frame[methodName]
        if type(original) == "function" then
            frame[methodName] = function(self, ...)
                HideChapterButtons()
                local results = { original(self, ...) }
                ApplyFieldNotesLabel()
                return unpack(results)
            end
        end
    end

    if frame.backBtn then
        local originalBackHandler = frame.backBtn:GetScript("OnClick")

        frame.backBtn:SetScript("OnClick", function(button, ...)
            if frame.state and frame.state.mode == "chronicleChapter" then
                PlayButtonSound()
                frame:ShowLanding()
                return
            end

            if originalBackHandler then
                originalBackHandler(button, ...)
                ApplyFieldNotesLabel()
            end
        end)
    end

    local originalToggle = frame.Toggle
    if type(originalToggle) == "function" then
        function frame:Toggle(...)
            HideChapterButtons()
            local results = { originalToggle(self, ...) }
            ApplyFieldNotesLabel()
            return unpack(results)
        end
    end

    -- Keep the original Chronicle function reachable for troubleshooting.
    frame.ShowChronicleLegacy = originalShowChronicle

    ApplyFieldNotesLabel()

    -- Preserve CreatureDisplayID discovery in the background while the lore
    -- pages continue using their original static icon rows. This also backfills
    -- appearances for curated creatures recorded before DisplayID tracking.
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            W:BootstrapExistingCreatureAppearances()
        end)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    ApplyPatch()
end)
