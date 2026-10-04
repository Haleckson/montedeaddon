local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.ChronicleSystem = FieldJournal.ChronicleSystem or {}

local CS = FieldJournal.ChronicleSystem

-- Exact NPC names confirmed by ID. A Forever death recap can include an
-- unrelated nearby player's name in a creature's sourceName.
local CHRONICLE_NPC_NAMES = {
    [3124] = "Scorpid Worker",
}

CS.initialized = false
CS.pendingMilestones = CS.pendingMilestones or {}

local FINALIZE_DELAY = 1.5

local NEAR_DEATH_THRESHOLD = 10

local NEAR_DEATH_TEMPLATES = {
    "For a moment, I was certain my journey had reached its end. {enemy} left me barely standing in {location}, and whatever confidence I carried into the fight disappeared quickly. Somehow, I remained on my feet.",
    "Death brushed close in {location}. {enemy} nearly ended my travels there, and I escaped with little more than breath and stubbornness to spare.",
    "There are lessons learned through careful study, and then there are lessons learned while desperately trying not to die. My encounter with {enemy} in {location} was very much the latter.",
    "I have had difficult fights before, but this one came far too close to becoming my last. {enemy} pressed me to the edge in {location}; I survived, though not comfortably.",
    "Today the road offered a sharp reminder that experience is not the same thing as invincibility. {enemy} nearly brought my travels to an abrupt end in {location}.",
    "I walked away from {location} under my own power, which for several terrible moments seemed unlikely. {enemy} came closer to finishing me than I care to admit.",
    "A narrow margin separated another journal entry from a final one today. {enemy} had me badly wounded in {location}, but the fight turned before my strength gave out completely.",
    "I will remember {location} for reasons beyond its roads and landmarks. {enemy} nearly made it the place where my journey ended, and I survived by a margin too small for pride.",
    "The world seemed suddenly very quiet when the fight turned against me. In {location}, {enemy} pushed me frighteningly close to death before I found a way through.",
    "I have recorded creatures, places, and quests in these pages. Today I record something simpler: {enemy} nearly killed me in {location}, and I am still here to write about it.",
    "For all the maps and observations in this journal, there was no clever lesson in this encounter. {enemy} nearly ended me in {location}. Surviving was lesson enough.",
    "My steps were considerably less steady after this fight than before it. {enemy} brought me within a breath of defeat in {location}, and I left with a renewed respect for caution.",
    "Some victories feel triumphant. This one felt mostly like relief. I survived {enemy} in {location}, though the distance between survival and disaster was uncomfortably small.",
    "I found the edge of my strength today and very nearly went beyond it. {enemy} forced the lesson upon me in {location}; fortunately, I lived long enough to remember it.",
    "There are moments when survival feels earned, and others when it feels borrowed. After what happened with {enemy} in {location}, I am increasingly convinced this was the latter.",
}

local function NowTimestamp()
    if GetServerTime then
        return GetServerTime()
    end

    if time then
        return time()
    end

    return 0
end

local function NowText()
    return date("%Y-%m-%d %H:%M:%S")
end

local function Trim(value)
    if not value then return nil end
    value = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return nil end
    return value
end

local function AddUnique(list, seen, value)
    value = Trim(value)
    if not value or seen[value] then
        return
    end

    seen[value] = true
    table.insert(list, value)
end

local function CopyArray(source)
    local result = {}
    for i, value in ipairs(source or {}) do
        result[i] = value
    end
    return result
end

local function JoinNatural(list)
    local count = #list

    if count == 0 then
        return ""
    elseif count == 1 then
        return list[1]
    elseif count == 2 then
        return list[1] .. " and " .. list[2]
    end

    local parts = {}
    for i = 1, count - 1 do
        table.insert(parts, list[i])
    end

    return table.concat(parts, ", ") .. ", and " .. list[count]
end

local function GetSubjectDisplayName(subjectID)
    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    if entry and entry.displayName then
        return entry.displayName
    end

    if not subjectID then
        return "Unknown Subject"
    end

    local name = tostring(subjectID):gsub("_", " ")
    return (name:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function GetQuestTitle(questID, questDef)
    if questDef and questDef.title and questDef.title ~= "" then
        return questDef.title
    end

    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if title and title ~= "" then
            return title
        end
    end

    return "Quest " .. tostring(questID)
end

local function CaptureLocation()
    local zone = Trim(GetRealZoneText and GetRealZoneText()) or "Unknown Zone"
    local subzone = Trim(GetSubZoneText and GetSubZoneText())
    local minimapZone = Trim(GetMinimapZoneText and GetMinimapZoneText())

    if subzone == zone then
        subzone = nil
    end

    if minimapZone == zone then
        minimapZone = nil
    end

    local precise = minimapZone or subzone
    local mapID = nil
    local x = nil
    local y = nil

    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        mapID = C_Map.GetBestMapForUnit("player")

        if mapID then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if position and position.GetXY then
                x, y = position:GetXY()
            end
        end
    end

    return {
        zone = zone,
        subzone = subzone,
        minimapZone = minimapZone,
        precise = precise,
        mapID = mapID,
        x = x,
        y = y,
    }
end

local function CollectBetween(records, startTimestamp, endTimestamp)
    local results = {}

    for _, record in ipairs(records or {}) do
        local stamp = record.timestamp or 0
        if stamp > startTimestamp and stamp <= endTimestamp then
            table.insert(results, record)
        end
    end

    table.sort(results, function(a, b)
        return (a.timestamp or 0) < (b.timestamp or 0)
    end)

    return results
end

-- =========================================================
-- CHRONICLE APPEARANCE SNAPSHOTS
-- Chapter portraits store only compact equipped-item links. The game client
-- continues to provide the character model itself, so no image or model data
-- is written into SavedVariables.
-- =========================================================
local CHAPTER_APPEARANCE_LEVELS = {
    [1] = true,
    [10] = true,
    [11] = true,
    [20] = true,
    [21] = true,
    [30] = true,
    [31] = true,
    [40] = true,
    [41] = true,
    [50] = true,
    [51] = true,
    [59] = true,
    [60] = true,
}

-- Visible equipment slots. Neck, rings, trinkets, and ammo are intentionally
-- omitted because they do not alter the character model. The ranged slot is
-- retained in the snapshot for future use, although the portrait renderer
-- favors main-hand/off-hand weapons when both are present.
local APPEARANCE_EQUIPMENT_SLOTS = {
    1,  -- Head
    3,  -- Shoulder
    4,  -- Shirt
    5,  -- Chest
    6,  -- Waist
    7,  -- Legs
    8,  -- Feet
    9,  -- Wrist
    10, -- Hands
    15, -- Back
    16, -- Main hand
    17, -- Off hand
    18, -- Ranged
    19, -- Tabard
}

local function CaptureEquippedAppearance(level)
    local snapshot = {
        level = tonumber(level) or (UnitLevel and UnitLevel("player")) or 0,
        capturedAt = NowText(),
        timestamp = NowTimestamp(),
        captureVersion = 2,
        items = {},
        itemIDs = {},
    }

    if UnitName then
        snapshot.characterName = UnitName("player")
    end

    if UnitClass then
        local className, classToken = UnitClass("player")
        snapshot.className = className
        snapshot.classToken = classToken
    end

    if UnitRace then
        local raceName, raceToken = UnitRace("player")
        snapshot.raceName = raceName
        snapshot.raceToken = raceToken
    end

    if UnitSex then
        snapshot.sex = UnitSex("player")
    end

    if ShowingHelm then
        snapshot.showHelm = ShowingHelm() and true or false
    end

    if ShowingCloak then
        snapshot.showCloak = ShowingCloak() and true or false
    end

    -- Item IDs are the primary snapshot source. They are available directly
    -- from the equipped inventory and do not depend on the full item hyperlink
    -- being cached yet. DressUpModel:TryOn accepts the resulting "item:<id>"
    -- string. A full link is retained only as a fallback for older clients.
    for _, slotID in ipairs(APPEARANCE_EQUIPMENT_SLOTS) do
        local itemID = nil
        if GetInventoryItemID then
            itemID = GetInventoryItemID("player", slotID)
        end

        if itemID then
            snapshot.itemIDs[slotID] = itemID
            snapshot.items[slotID] = "item:" .. tostring(itemID)
        elseif GetInventoryItemLink then
            local itemLink = GetInventoryItemLink("player", slotID)
            if itemLink then
                snapshot.items[slotID] = itemLink
            end
        end
    end

    return snapshot
end

-- Beta preview uses the same equipment capture as a real chapter portrait,
-- but returns it only to the UI. It never occupies a historical level slot.
function CS:CaptureTestAppearance()
    return CaptureEquippedAppearance((UnitLevel and UnitLevel("player")) or 0)
end

function CS:CaptureAppearanceSnapshot(level, options)
    level = tonumber(level)
    if not level or not CHAPTER_APPEARANCE_LEVELS[level] then
        return nil
    end

    local chronicle = self:GetChronicle()
    chronicle.appearanceSnapshots = chronicle.appearanceSnapshots or {}

    -- Historical chapter appearances are immutable. If the snapshot already
    -- exists, never replace it with later equipment.
    if chronicle.appearanceSnapshots[level] then
        return chronicle.appearanceSnapshots[level]
    end

    local snapshot = CaptureEquippedAppearance(level)

    -- A bootstrap snapshot is used only for characters who first install this
    -- portrait feature after already entering a chapter. The portrait is saved
    -- into the most appropriate empty chapter slot, but we also retain the
    -- character's real level at capture time so the SavedVariables remain
    -- honest about when that appearance was actually observed.
    if options and options.bootstrap then
        snapshot.bootstrap = true
        snapshot.capturedCharacterLevel = tonumber(options.currentLevel)
            or ((UnitLevel and UnitLevel("player")) or level)
    end

    chronicle.appearanceSnapshots[level] = snapshot
    return snapshot
end

local function GetBootstrapAppearanceLevel(playerLevel)
    playerLevel = tonumber(playerLevel) or 0

    if playerLevel <= 0 then
        return nil
    elseif playerLevel <= 9 then
        return 1
    elseif playerLevel == 10 then
        return 10
    elseif playerLevel <= 19 then
        return 11
    elseif playerLevel == 20 then
        return 20
    elseif playerLevel <= 29 then
        return 21
    elseif playerLevel == 30 then
        return 30
    elseif playerLevel <= 39 then
        return 31
    elseif playerLevel == 40 then
        return 40
    elseif playerLevel <= 49 then
        return 41
    elseif playerLevel == 50 then
        return 50
    elseif playerLevel <= 58 then
        return 51
    elseif playerLevel == 59 then
        return 59
    else
        return 60
    end
end

local function SnapshotHasEquippedItems(snapshot)
    if not snapshot then
        return false
    end

    if type(snapshot.itemIDs) == "table" and next(snapshot.itemIDs) ~= nil then
        return true
    end

    return type(snapshot.items) == "table" and next(snapshot.items) ~= nil
end

function CS:BootstrapChapterAppearance()
    local chronicle = self:GetChronicle()
    local currentLevel = (UnitLevel and UnitLevel("player")) or 0
    local targetLevel = GetBootstrapAppearanceLevel(currentLevel)
    if not targetLevel then
        return nil, nil
    end

    chronicle.appearanceSnapshots = chronicle.appearanceSnapshots or {}
    chronicle.portraitBootstrapLastAttemptAt = NowText()
    chronicle.portraitBootstrapLastAttemptLevel = currentLevel
    chronicle.portraitBootstrapLastTargetLevel = targetLevel

    local snapshot = chronicle.appearanceSnapshots[targetLevel]

    -- A genuine milestone portrait is permanent and must never be replaced by
    -- compatibility logic from a later addon install/update.
    if snapshot and not snapshot.bootstrap and SnapshotHasEquippedItems(snapshot) then
        chronicle.portraitBootstrapVersion = 4
        chronicle.portraitBootstrapAt = chronicle.portraitBootstrapAt or NowText()
        chronicle.portraitBootstrapTargetLevel = targetLevel
        chronicle.portraitBootstrapCharacterLevel = chronicle.portraitBootstrapCharacterLevel or currentLevel
        return snapshot, targetLevel
    end

    -- A valid bootstrap snapshot is also permanent once it contains actual
    -- equipped-item data. Do not keep rewriting it on subsequent logins.
    if snapshot and snapshot.bootstrap and SnapshotHasEquippedItems(snapshot) then
        chronicle.portraitBootstrapVersion = 4
        chronicle.portraitBootstrapAt = chronicle.portraitBootstrapAt or NowText()
        chronicle.portraitBootstrapTargetLevel = targetLevel
        chronicle.portraitBootstrapCharacterLevel = chronicle.portraitBootstrapCharacterLevel or currentLevel
        return snapshot, targetLevel
    end

    -- No usable snapshot exists. Capture the character as they are now. This
    -- runs at login, after short delays, and again when a Chronicle chapter is
    -- opened. Empty/failed bootstrap data is allowed to be replaced until a
    -- real equipped-item set has been stored.
    local fresh = CaptureEquippedAppearance(targetLevel)
    fresh.bootstrap = true
    fresh.capturedCharacterLevel = currentLevel
    fresh.captureVersion = 4

    if SnapshotHasEquippedItems(fresh) then
        chronicle.appearanceSnapshots[targetLevel] = fresh
        chronicle.portraitBootstrapVersion = 4
        chronicle.portraitBootstrapAt = NowText()
        chronicle.portraitBootstrapTargetLevel = targetLevel
        chronicle.portraitBootstrapCharacterLevel = currentLevel
        return fresh, targetLevel
    end

    -- Do not save an empty historical portrait. Widgets can temporarily show
    -- the live player model in the appropriate current-chapter slot while the
    -- next retry attempts to persist the equipment snapshot.
    return nil, targetLevel
end

function CS:RefreshCurrentAppearance()
    local chronicle = self:GetChronicle()

    -- "Current" is deliberately overwritten at login. It is not a historical
    -- milestone and therefore should reflect the character at the start of the
    -- present play session.
    chronicle.currentAppearance = CaptureEquippedAppearance(
        (UnitLevel and UnitLevel("player")) or 0
    )

    return chronicle.currentAppearance
end

function CS:GetAppearanceSnapshot(level)
    local chronicle = self:GetChronicle()
    chronicle.appearanceSnapshots = chronicle.appearanceSnapshots or {}
    return chronicle.appearanceSnapshots[tonumber(level)]
end

function CS:GetCurrentAppearance()
    local chronicle = self:GetChronicle()
    return chronicle.currentAppearance
end

function CS:Init()
    if self.initialized then
        return
    end

    FieldJournalDB = FieldJournalDB or {}
    FieldJournalDB.chronicle = FieldJournalDB.chronicle or {}

    local chronicle = FieldJournalDB.chronicle
    chronicle.version = chronicle.version or 1
    chronicle.milestones = chronicle.milestones or {}
    chronicle.questHistory = chronicle.questHistory or {}
    chronicle.subjectDiscoveries = chronicle.subjectDiscoveries or {}
    chronicle.subregionDiscoveries = chronicle.subregionDiscoveries or {}
    chronicle.nearDeaths = chronicle.nearDeaths or {}
    chronicle.deaths = chronicle.deaths or {}
    for _, death in ipairs(chronicle.deaths) do
        self:NormalizeDeathKillerName(death)
    end
    chronicle.nearDeathTemplateBag = chronicle.nearDeathTemplateBag or {}
    chronicle.mobEncountersCurrent = chronicle.mobEncountersCurrent or {}
    chronicle.levelReflectionBags = chronicle.levelReflectionBags or {}
    chronicle.levelReflectionLast = chronicle.levelReflectionLast or {}
    chronicle.appearanceSnapshots = chronicle.appearanceSnapshots or {}
    chronicle.portraitSystemCodeVersion = 4

    if not chronicle.startedTimestamp then
        chronicle.startedTimestamp = NowTimestamp()
        chronicle.startedAt = NowText()
        chronicle.startedLevel = UnitLevel("player") or 1
    end

    self.initialized = true
    self.deathRecorded = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") and true or false

    -- Refresh the non-historical Current portrait every time the addon loads.
    self:RefreshCurrentAppearance()

    -- On the first load of the portrait feature, establish one useful
    -- historical baseline for the character's current chapter. For example, a
    -- Level 10 character fills Level 10; a Level 24 character fills Level 21;
    -- and a Level 60 character fills Level 60. Earlier chapters remain empty.
    -- After this one-time bootstrap, all future portraits are captured only at
    -- their real chapter-boundary level-up events.

    -- Re-read equipped links shortly after login in case item data finished
    -- loading a fraction of a second after PLAYER_LOGIN. Current may be safely
    -- overwritten, while the compatibility portrait remains immutable once
    -- captured.
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
            if CS.initialized then
                CS:RefreshCurrentAppearance()
                CS:BootstrapChapterAppearance()
            end
        end)

        -- A second delayed pass makes first-load migration resilient on clients
        -- where equipped item links are not ready during the first half-second.
        C_Timer.After(2.0, function()
            if CS.initialized then
                CS:RefreshCurrentAppearance()
                CS:BootstrapChapterAppearance()
            end
        end)
    else
        self:BootstrapChapterAppearance()
    end

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r ChronicleSystem initialized.")
    end
end

function CS:GetChronicle()
    if not self.initialized then
        self:Init()
    end

    return FieldJournalDB.chronicle
end

function CS:RecordQuestTurnIn(questID, questDef)
    if not questID then
        return
    end

    local chronicle = self:GetChronicle()
    local now = NowTimestamp()

    -- QUEST_TURNED_IN can occasionally be observed more than once by addons.
    -- Preserve repeatable quests, but suppress an immediate duplicate event.
    local previous = chronicle.questHistory[#chronicle.questHistory]
    if previous
        and previous.questID == questID
        and math.abs((previous.timestamp or 0) - now) <= 2 then
        return
    end

    local location = CaptureLocation()

    table.insert(chronicle.questHistory, {
        questID = questID,
        title = GetQuestTitle(questID, questDef),
        npcName = questDef and questDef.npcName or nil,
        npcID = questDef and questDef.npcID or nil,
        curated = questDef and true or false,
        playerLevel = UnitLevel("player") or 0,
        zone = (questDef and questDef.zone) or location.zone,
        subregion = (questDef and questDef.subregion) or location.precise,
        completedAt = NowText(),
        timestamp = now,
    })
end

function CS:RecordSubjectDiscovery(subjectID, zoneName)
    if not subjectID then
        return
    end

    local chronicle = self:GetChronicle()

    table.insert(chronicle.subjectDiscoveries, {
        subjectID = subjectID,
        displayName = GetSubjectDisplayName(subjectID),
        zone = zoneName or (GetRealZoneText and GetRealZoneText()) or "Unknown Zone",
        discoveredAt = NowText(),
        timestamp = NowTimestamp(),
    })
end

function CS:RecordSubregionDiscovery(zoneName, subregionName)
    if not zoneName or not subregionName then
        return
    end

    local chronicle = self:GetChronicle()

    table.insert(chronicle.subregionDiscoveries, {
        zone = zoneName,
        subregion = subregionName,
        discoveredAt = NowText(),
        timestamp = NowTimestamp(),
    })
end

function CS:RecordMobKill(npcID, mobName, zoneName)
    mobName = Trim(mobName)
    if not mobName then
        return
    end

    local chronicle = self:GetChronicle()
    chronicle.mobEncountersCurrent = chronicle.mobEncountersCurrent or {}

    local key = npcID and ("npc:" .. tostring(npcID)) or ("name:" .. string.lower(mobName))
    local record = chronicle.mobEncountersCurrent[key]

    if not record then
        record = {
            npcID = npcID,
            name = mobName,
            zone = zoneName,
            count = 0,
            firstTimestamp = NowTimestamp(),
        }
        chronicle.mobEncountersCurrent[key] = record
    end

    record.name = mobName
    record.zone = zoneName or record.zone
    record.count = (record.count or 0) + 1
    record.lastTimestamp = NowTimestamp()
end


local function RefreshDeathChapter()
    local journalFrame = FieldJournal.UI and FieldJournal.UI.JournalFrame
    if journalFrame and journalFrame.IsShown and journalFrame:IsShown()
        and journalFrame.state and journalFrame.state.mode == "chronicleChapter"
        and journalFrame.ShowChronicleChapter then
        journalFrame:ShowChronicleChapter(journalFrame.state.chapter)
    end
end

-- A recap label alone is not a trustworthy NPC name on the Forever beta: it
-- can include a nearby player's name. Require a separately known name for
-- creature, vehicle, or pet GUIDs; otherwise retain the raw label privately
-- and leave the visible death attribution blank.
function CS:NormalizeDeathKillerName(death)
    local compat = FieldJournal.Compat
    if not compat or not death then return false end
    local guid = death.killerGUID
    if compat:IsSafe(guid, "string") and guid:sub(1, 7) == "Player-" then return true end
    local npcID = compat:GetNPCID(guid)
    local recapLabel = death.killerRecapName or death.killerName

    local name = npcID and CHRONICLE_NPC_NAMES[npcID]
    if not name then
        local encounterSystem = FieldJournal.EncounterSystem
        name = compat:IsSafe(guid, "string") and encounterSystem
            and encounterSystem.targetNames and encounterSystem.targetNames[guid]
    end
    if not name and npcID and FieldJournalDB and FieldJournalDB.encounters then
        local encounter = FieldJournalDB.encounters[npcID]
        local candidate = encounter and encounter.name
        if compat:IsSafe(candidate, "string") and candidate ~= "Unknown"
            and candidate ~= ("NPC " .. npcID)
            and compat:IsSafe(recapLabel, "string")
            and (recapLabel == candidate
                or recapLabel:sub(1, #candidate + 1) == candidate .. " ") then
            name = candidate
        end
    end
    if compat:IsSafe(name, "string") and name ~= "" then
        if compat:IsSafe(recapLabel, "string") and recapLabel ~= name then
            death.killerRecapName = recapLabel
        end
        death.killerName = name
        death.killerNameSource = "creatureGUID"
        death.killerClass = nil
        return true
    end
    if compat:IsSafe(recapLabel, "string") then death.killerRecapName = recapLabel end
    death.killerName = nil
    death.killerNameSource = nil
    death.killerClass = nil
    return false
end

-- The recap can arrive after PLAYER_DEAD. Only an accessible killing blow
-- timestamped for this death can add a name; an earlier recap is never used.
function CS:EnrichDeathFromRecap(death)
    local compat = FieldJournal.Compat
    local recap = C_DeathRecap
    if not compat or not recap or not recap.HasRecapEvents or not recap.GetRecapEvents then return false end

    local ready, hasEvents = pcall(recap.HasRecapEvents)
    if not ready or not compat:IsSafe(hasEvents, "boolean") or not hasEvents then return false end
    local ok, events = pcall(recap.GetRecapEvents)
    if not ok or not compat:IsSafe(events, "table") then return false end

    local count = #events
    for i = count, 1, -1 do
        local entry = events[i]
        if compat:IsSafe(entry, "table") then
            local overkill, stamp = entry.overkill, entry.timestamp
            local name, guid = entry.sourceName, entry.sourceGUID
            if compat:IsSafe(overkill, "number") and overkill >= 0
                and compat:IsSafe(stamp, "number") and math.abs(stamp - death.timestamp) <= 5
                and compat:IsSafe(name, "string") and name ~= ""
                and compat:IsSafe(guid, "string") then
                death.killerName = name
                death.killerGUID = guid
                if guid:sub(1, 7) == "Player-" and GetPlayerInfoByGUID then
                    local classOK, className = pcall(GetPlayerInfoByGUID, guid)
                    if classOK and compat:IsSafe(className, "string") and className ~= "" then
                        death.killerClass = className
                    end
                end
                if self:NormalizeDeathKillerName(death) then
                    death.killerSource = "deathRecap"
                    RefreshDeathChapter()
                    return true
                end
            end
        end
    end
    return false
end

function CS:ScheduleDeathRecap(death)
    self.deathSerial = (self.deathSerial or 0) + 1
    local serial = self.deathSerial
    if self:EnrichDeathFromRecap(death) or not C_Timer or not C_Timer.After then return end
    for _, delay in ipairs({ 0.3, 1, 2 }) do
        C_Timer.After(delay, function()
            if self.deathSerial == serial and not death.killerSource then
                self:EnrichDeathFromRecap(death)
            end
        end)
    end
end

-- Existing near-death history stays readable but is no longer produced.
function CS:OnPlayerDead()
    if self.deathRecorded then return false end
    self.deathRecorded = true

    local chronicle = self:GetChronicle()
    chronicle.deaths = chronicle.deaths or {}
    local death = {
        type = "death",
        level = UnitLevel("player") or 0,
        occurredAt = NowText(),
        timestamp = NowTimestamp(),
        location = CaptureLocation(),
    }
    table.insert(chronicle.deaths, death)
    self:ScheduleDeathRecap(death)

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[Field Journal]|r Chronicle entry recorded: Death at level "
            .. tostring(death.level) .. ".")
    end

    RefreshDeathChapter()
    return true
end

function CS:OnPlayerAlive()
    self.deathRecorded = false
end

function CS:GetPreviousMilestoneTimestamp(level)
    local chronicle = self:GetChronicle()
    local bestLevel = nil
    local bestTimestamp = nil

    for recordedLevel, milestone in pairs(chronicle.milestones) do
        local numericLevel = tonumber(recordedLevel)
        if numericLevel and numericLevel < level then
            if not bestLevel or numericLevel > bestLevel then
                bestLevel = numericLevel
                bestTimestamp = milestone.timestamp
            end
        end
    end

    if bestTimestamp then
        return bestTimestamp
    end

    -- Chronicle-specific activity arrays begin at installation, so making the
    -- first boundary one second earlier safely includes same-second activity.
    return (chronicle.startedTimestamp or 0) - 1
end

function CS:BuildMilestoneFacts(level, context)
    local chronicle = self:GetChronicle()
    local endTimestamp = NowTimestamp()
    local startTimestamp = self:GetPreviousMilestoneTimestamp(level)

    local questRecords = CollectBetween(chronicle.questHistory, startTimestamp, endTimestamp)
    local subjectRecords = CollectBetween(chronicle.subjectDiscoveries, startTimestamp, endTimestamp)
    local subregionRecords = CollectBetween(chronicle.subregionDiscoveries, startTimestamp, endTimestamp)

    local questTitles = {}
    local questTitleSeen = {}
    local questGivers = {}
    local questGiverSeen = {}
    local subjects = {}
    local subjectSeen = {}
    local subregions = {}
    local subregionSeen = {}

    for _, record in ipairs(questRecords) do
        AddUnique(questTitles, questTitleSeen, record.title)
        AddUnique(questGivers, questGiverSeen, record.npcName)
    end

    for _, record in ipairs(subjectRecords) do
        AddUnique(subjects, subjectSeen, record.displayName or GetSubjectDisplayName(record.subjectID))
    end

    for _, record in ipairs(subregionRecords) do
        AddUnique(subregions, subregionSeen, record.subregion)
    end

    -- Mob encounters are tracked as a compact per-level bucket rather than as
    -- a permanent event for every kill. Keep the most representative creatures
    -- first so the factual milestone data remains useful for future summaries.
    local mobRecords = {}
    local mobKillCount = 0
    for _, record in pairs(chronicle.mobEncountersCurrent or {}) do
        if type(record) == "table" and Trim(record.name) then
            table.insert(mobRecords, record)
            mobKillCount = mobKillCount + (tonumber(record.count) or 0)
        end
    end

    table.sort(mobRecords, function(a, b)
        local aCount = tonumber(a.count) or 0
        local bCount = tonumber(b.count) or 0
        if aCount ~= bCount then
            return aCount > bCount
        end
        return tostring(a.name or "") < tostring(b.name or "")
    end)

    local mobNames = {}
    local mobNameSeen = {}
    for _, record in ipairs(mobRecords) do
        AddUnique(mobNames, mobNameSeen, record.name)
    end

    return {
        level = level,
        previousLevel = math.max(1, level - 1),
        reachedAt = context.reachedAt,
        timestamp = endTimestamp,
        location = context.location,
        questCount = #questRecords,
        questTitles = questTitles,
        questGivers = questGivers,
        discoveredSubjects = subjects,
        discoveredSubregions = subregions,
        mobNames = mobNames,
        mobKillCount = mobKillCount,
    }
end

function CS:FinalizeLevelUp(level, context)
    if not level then
        return
    end

    local chronicle = self:GetChronicle()

    if chronicle.milestones[level] then
        self.pendingMilestones[level] = nil
        return
    end

    local milestone = self:BuildMilestoneFacts(level, context)
    self:AssignMilestoneReflection(milestone)
    chronicle.milestones[level] = milestone
    chronicle.mobEncountersCurrent = {}
    self.pendingMilestones[level] = nil

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[Field Journal]|r Chronicle entry recorded: Level " .. tostring(level) .. ".")
    end

    local journalFrame = FieldJournal.UI and FieldJournal.UI.JournalFrame
    if journalFrame
        and journalFrame.IsShown
        and journalFrame:IsShown()
        and journalFrame.state then

        if journalFrame.state.mode == "chronicleChapter"
            and journalFrame.state.chapter
            and journalFrame.ShowChronicleChapter then

            journalFrame:ShowChronicleChapter(journalFrame.state.chapter)
        elseif journalFrame.state.mode == "chronicle"
            and journalFrame.ShowChronicle then

            journalFrame:ShowChronicle()
        end
    end
end

function CS:OnPlayerLevelUp(level)
    level = tonumber(level)
    if not level then
        return
    end

    -- Chapter-boundary portraits are captured at the actual level-up event,
    -- before the player has a chance to replace the gear they were wearing.
    if CHAPTER_APPEARANCE_LEVELS[level] then
        self:CaptureAppearanceSnapshot(level)
    end

    local chronicle = self:GetChronicle()
    if chronicle.milestones[level] or self.pendingMilestones[level] then
        return
    end

    local context = {
        level = level,
        reachedAt = NowText(),
        location = CaptureLocation(),
    }

    self.pendingMilestones[level] = context

    if C_Timer and C_Timer.After then
        C_Timer.After(FINALIZE_DELAY, function()
            if self.pendingMilestones[level] then
                self:FinalizeLevelUp(level, context)
            end
        end)
    else
        self:FinalizeLevelUp(level, context)
    end
end

function CS:GetSortedMilestones()
    local chronicle = self:GetChronicle()
    local levels = {}

    for level in pairs(chronicle.milestones) do
        local numericLevel = tonumber(level)
        if numericLevel then
            table.insert(levels, numericLevel)
        end
    end

    table.sort(levels)

    local milestones = {}
    for _, level in ipairs(levels) do
        table.insert(milestones, chronicle.milestones[level])
    end

    return milestones
end


function CS:GetSortedChronicleEntries()
    local chronicle = self:GetChronicle()
    local entries = {}

    for _, milestone in ipairs(self:GetSortedMilestones()) do
        table.insert(entries, {
            entryType = "level",
            timestamp = milestone.timestamp or 0,
            data = milestone,
        })
    end

    for _, incident in ipairs(chronicle.nearDeaths or {}) do
        table.insert(entries, {
            entryType = "nearDeath",
            timestamp = incident.timestamp or 0,
            data = incident,
        })
    end

    for _, death in ipairs(chronicle.deaths or {}) do
        table.insert(entries, {
            entryType = "death",
            timestamp = death.timestamp or 0,
            data = death,
        })
    end

    table.sort(entries, function(a, b)
        if (a.timestamp or 0) == (b.timestamp or 0) then
            -- Stable, deterministic ordering for same-second entries.
            return a.entryType == "level" and b.entryType ~= "level"
        end

        return (a.timestamp or 0) < (b.timestamp or 0)
    end)

    return entries
end

function CS:GetEraTitle(level)
    level = tonumber(level) or 1

    if level >= 60 then
        return "A Defining Milestone"
    elseif level >= 58 then
        return "Nearing Mastery"
    elseif level >= 50 then
        return "Hardened Traveler"
    elseif level >= 40 then
        return "Veteran of the Road"
    elseif level >= 30 then
        return "Seasoned Adventurer"
    elseif level >= 20 then
        return "Proven Traveler"
    elseif level >= 10 then
        return "Finding My Way"
    end

    return "First Steps"
end

function CS:FormatLocation(location)
    location = location or {}

    local zone = Trim(location.zone) or "Unknown Zone"
    local precise = Trim(location.precise) or Trim(location.subzone) or Trim(location.minimapZone)

    if precise and precise ~= zone then
        return precise .. ", " .. zone
    end

    return zone
end

function CS:FormatReachedAt(value)
    if not value then
        return "Unknown date"
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
        suffix = "PM"
    elseif hourNumber > 12 then
        displayHour = hourNumber - 12
        suffix = "PM"
    end

    return month .. "/" .. day .. "/" .. year .. ", " .. tostring(displayHour) .. ":" .. minute .. " " .. suffix
end


function CS:GetNearDeathTitle(incident)
    local lowest = tonumber(incident and incident.lowestHealthPct) or NEAR_DEATH_THRESHOLD

    if lowest <= 3 then
        return "Brush with Death"
    elseif lowest <= 7 then
        return "Narrow Escape"
    end

    return "Close Call"
end

function CS:GetNearDeathNarrative(incident)
    if not incident then
        return "A dangerous encounter was survived, though the details were lost."
    end

    local templateID = tonumber(incident.templateID) or 1
    local template = NEAR_DEATH_TEMPLATES[templateID] or NEAR_DEATH_TEMPLATES[1]
    local enemy = Trim(incident.attackerName) or "the danger before me"
    local location = self:FormatLocation(incident.location)

    local text = template
    text = text:gsub("{enemy}", function() return enemy end)
    text = text:gsub("{location}", function() return location end)

    return text
end

local CLASS_REFLECTIONS = {
    ["WARRIOR"] = {
        [1] = {
            "The first fights felt louder than they needed to. I am starting to hear the rhythm beneath the noise and trust my hands when steel is drawn.",
            "In {location}, I learned that strength matters less when it is spent badly. A steady stance and a clear head have carried me farther than anger ever did.",
            "My shield, blade, or axe no longer feels like something I am carrying. It is beginning to feel like an extension of the choices I make in a fight.",
            "I used to brace for every blow as if it might end the journey. Now I meet them with better footing, better timing, and less panic.",
            "There is a difference between being willing to fight and knowing how to fight. I am only beginning to understand how wide that distance can be.",
            "The bruises are becoming less memorable than the lessons behind them. I can feel clumsy habits giving way to something more deliberate.",
            "Every road seems to offer another reason to keep my guard up. I am learning to conserve strength for the moments when it actually matters.",
            "I left {location} more certain of my footing than when I arrived. Confidence still feels new, but it no longer feels borrowed.",
        },
        [2] = {
            "I am beginning to recognize a bad fight before the first weapon swings. That may be worth more than any amount of raw strength.",
            "The road beyond familiar ground has sharpened me. I waste less motion now, and I recover from mistakes before they become disasters.",
            "In {location}, patience proved as useful as force. There are battles won by holding firm long enough for the right opening to appear.",
            "I once thought courage meant rushing toward danger. Experience is teaching me that courage can also mean standing still when everything in me wants to move.",
            "My body has learned things my mind no longer needs to explain. Blocks, turns, and strikes arrive more naturally than they did a few levels ago.",
            "The weight of armor bothers me less now. Perhaps that is because I have learned how much worse the weight of a poor decision can be.",
            "I have stopped measuring every fight by how hard I hit. Position, breath, and restraint are beginning to matter just as much.",
            "The farther I travel, the more I respect anyone who survives by discipline rather than luck. I am trying to become one of them.",
        },
        [3] = {
            "There is less hesitation in me now. I still respect danger, but I no longer need fear to tell me when a fight is serious.",
            "In {location}, I caught myself reacting before I had time to think. Years ago that would have been panic. Now it felt like training finally taking root.",
            "I have learned that endurance is not simply taking punishment. It is knowing how to remain useful after the easy strength is gone.",
            "A strong arm can end a fight, but a strong mind decides which fight is worth ending. That distinction feels clearer with every mile.",
            "The road has stripped away some of my early bravado. What remains feels sturdier and much easier to trust.",
            "I am becoming harder to surprise. The world is no more predictable than before. I have simply made enough mistakes to recognize trouble on its approach.",
            "Some victories leave no story worth telling. A clean stance, a timely guard, and everyone still standing afterward can be enough.",
            "I used to think seasoned fighters looked fearless. Now I suspect they simply know where to put the fear so it does not control their hands.",
        },
        [4] = {
            "Experience has made combat quieter in my head. I notice angles, distance, and breathing now where I once noticed only the threat in front of me.",
            "In {location}, I was reminded that a veteran is still only one poor choice away from being carried off the field. Skill is no excuse for carelessness.",
            "My strength has grown, but restraint has grown with it. I trust myself more when I know I can stop as readily as I can strike.",
            "The first instinct is no longer always the right one, and I finally have enough experience to wait for the second.",
            "I can feel old battles living in the way I move. Each scar has become a small instruction I no longer need to read aloud.",
            "There are moments now when I know exactly what an opponent wants me to do. Refusing them that satisfaction has become its own kind of victory.",
            "The road has taught me to spend energy like coin. Waste it early and the final stretch becomes expensive.",
            "I no longer need every victory to feel dramatic. Walking away with my equipment intact and my judgment improved is reward enough.",
        },
        [5] = {
            "I have fought long enough to know that confidence is useful only while it remains honest. The dangerous moments are the ones when experience starts calling itself certainty.",
            "In {location}, I felt the old temptation to rely on strength alone. The wiser part of me knew better, and for once it spoke first.",
            "There is a veteran's economy to battle that I am only now appreciating. Fewer wasted steps, fewer wasted swings, fewer chances handed freely to the enemy.",
            "I have become more comfortable carrying responsibility when others are nearby. Holding the line means little if I forget who is standing behind it.",
            "Somewhere along the road, surviving stopped feeling accidental. I do not take that for granted. The work has changed me, and I no longer doubt it.",
            "My armor has gathered scratches faster than I can remember where each came from. The habits beneath it matter more than the marks on the surface.",
            "Old dangers still deserve respect. The difference now is that I have answers ready before panic starts asking questions.",
            "I have learned to trust the quiet moments before a fight. They tell me more than boasting ever did about whether I am prepared.",
        },
        [6] = {
            "The body remembers a long road. I feel every old lesson in the way I plant my feet, conserve my breath, and refuse to be hurried.",
            "In {location}, I realized how rarely I think about the basics anymore. They have become part of me, which is probably the closest thing to mastery I trust.",
            "I no longer expect battle to make me feel heroic. Most often it makes me careful, tired, and grateful for the discipline that brought me through.",
            "There are fewer mysteries in a weapon than there once were. The mystery now is whether I will keep making the right choice when the stakes grow heavier.",
            "I have reached the point where younger mistakes are easy to recognize in others. Remembering how often I made them keeps the judgment from becoming contempt.",
            "Strength fades during a long fight. Habit does not. That truth has carried me through more than any burst of fury ever could.",
            "I used to chase the feeling of being unstoppable. I would rather be dependable now.",
            "The road toward mastery has not made danger smaller. It has made my response to danger more measured, and that feels like the greater achievement.",
        },
        [7] = {
            "Sixty levels of battle have left me with fewer illusions and better instincts. I do not feel finished. I feel prepared for harder truths.",
            "The climb ends here only on paper. My hands are steadier, my judgment sharper, and the road ahead still has plenty left to teach me.",
            "I once imagined mastery would feel like certainty. Instead it feels like knowing exactly how much can still go wrong and standing ready anyway.",
            "This milestone carries the weight of every mistake I survived long enough to correct. That may be the truest measure of how far I have come.",
            "I have become the fighter I was trying to imitate in those first uncertain days. That realization is satisfying and a little unsettling.",
            "There is no single battle behind this moment. It was built from hundreds of small decisions, many of them made while tired, hurt, or afraid.",
            "I can look back now and see where strength became discipline. That change matters more to me than the number beside my name.",
            "Level sixty feels less like a crown and more like a well-earned place to stand. From here, whatever comes next will meet someone tested.",
        },
    },
    ["PALADIN"] = {
        [1] = {
            "The Light feels different when it must be carried into danger instead of spoken about in safety. I am beginning to understand that distinction.",
            "In {location}, I found that conviction is easier to claim than to practice. Holding to it when afraid is the part that matters.",
            "I expected righteousness to feel certain. Instead, these first steps have asked me to think carefully about when strength serves a good purpose.",
            "My armor is still new enough to feel heavy, but the duty behind it already feels heavier. I am learning not to resent that weight.",
            "There is comfort in prayer, but the road asks for action after the prayer ends. I am getting better at answering both.",
            "I have begun to understand why restraint belongs beside courage. Power used carelessly can betray the very cause it was meant to defend.",
            "The first victories have not made me feel chosen or invincible. They have made me more aware of how much trust can be placed in someone who wears this calling openly.",
            "I left {location} with stronger faith in my purpose, though perhaps less certainty in myself. That feels healthier than the reverse.",
        },
        [2] = {
            "The farther I travel from familiar walls, the more my convictions have to stand on their own. There is no instructor beside me now to explain every choice.",
            "In {location}, mercy and firmness did not point in the same direction. I am learning that duty sometimes begins where easy answers end.",
            "I have stopped expecting the Light to remove doubt. More often it gives me enough clarity to move through doubt without becoming paralyzed by it.",
            "Protection is becoming more than a spell or a shield. It is a habit of noticing who will suffer first if I choose poorly.",
            "I once imagined a paladin's path as a straight road. Experience has revealed more crossroads than I expected.",
            "My strength is growing, but so is my awareness of when not to use it. I trust that lesson more than any new technique.",
            "The symbol I carry means something to strangers before they know anything about me. I am trying to become worthy of the assumptions they make.",
            "Faith has become quieter with experience. I need fewer grand declarations and more honest choices.",
        },
        [3] = {
            "I am beginning to understand that courage is not a feeling granted by the Light. It is a decision I keep making while fear remains present.",
            "In {location}, I had reason to question my judgment and no reason to abandon my principles. Learning the difference has been important.",
            "There are people who see armor and expect certainty. I have learned to offer steadiness instead, which is something I can actually provide.",
            "My prayers have changed. I ask less often for an easy victory and more often for the wisdom to recognize what victory should mean.",
            "I have become more comfortable standing between danger and someone who cannot meet it alone. The responsibility feels natural now, though never light.",
            "Righteous anger is still anger. I have learned to inspect it before trusting where it wants to lead me.",
            "The road has made my faith less decorative and more practical. It lives in choices, patience, and the willingness to remain when leaving would be easier.",
            "I used to think purity meant never wavering. Now I think it may mean noticing when I have wandered and choosing the path again.",
        },
        [4] = {
            "Experience has made my convictions more durable because they have survived disagreement, fear, and failure. Untested certainty seems fragile by comparison.",
            "In {location}, I was reminded that being able to punish wrongdoing does not always mean punishment is the best service I can offer.",
            "I have carried the Light into enough dark places to know that darkness rarely announces itself clearly. Sometimes it arrives dressed as certainty.",
            "The shield has become a symbol I understand better now. It asks me to absorb consequences, not merely avoid them.",
            "My judgment feels steadier than it once did, but I guard against becoming too pleased with that fact. Pride can wear respectable armor.",
            "There are days when duty feels noble and days when it simply feels inconvenient. Keeping faith on the second kind of day matters more.",
            "I have learned to value quiet decency. The grand gestures are remembered, but most good is done when nobody is keeping score.",
            "The road has given me fewer simple enemies and more complicated choices. I suspect that is part of becoming worthy of greater strength.",
        },
        [5] = {
            "I have seen enough suffering to know that justice without compassion can become another kind of cruelty. Holding both in balance remains difficult.",
            "In {location}, I felt the old certainty of a younger version of myself. I do not miss how easy the world looked from there.",
            "People sometimes look to me for hope before I have found any for myself. I have learned that offering steadiness can be enough until hope catches up.",
            "My faith no longer depends on every outcome making sense. It has become something I practice even when the reason for a hardship stays hidden.",
            "The Light answers, but it does not excuse poor judgment. Experience has taught me to prepare carefully before asking faith to cover my mistakes.",
            "Protection has become the clearest part of my calling. I know what I am willing to endure so that someone else does not have to.",
            "I am less interested in appearing righteous than I once was. The work itself has become more important than being seen doing it.",
            "Conviction has survived enough testing that I trust it more quietly now. I no longer need every stranger to agree with me before I can stand firm.",
        },
        [6] = {
            "The road has worn away much of the ceremony I once attached to this calling. What remains is duty, faith, and the choice to keep showing up.",
            "In {location}, I understood how much of my strength now comes from habits nobody sees. Prayer, restraint, preparation, and the refusal to surrender judgment to anger.",
            "I have learned that a veteran paladin can still fail the people who trust them. Experience is a responsibility, not an exemption from mistakes.",
            "The Light feels less like a distant answer and more like an old companion. I still have to choose where we walk.",
            "I carry fewer doubts about what I can do and more questions about what I should do. That seems like progress.",
            "There was a time when I wanted to be admired for standing against darkness. Now I would rather make the darkness smaller and leave quietly.",
            "My shield has taken enough blows to become familiar with sacrifice. I hope I have learned the same lesson without growing fond of suffering for its own sake.",
            "I no longer think holiness looks like perfection. It looks more like returning to one's principles after every moment that tests them.",
        },
        [7] = {
            "Level sixty does not make me righteous. It gives me more power, more experience, and fewer excuses for using either carelessly.",
            "I have carried the Light through fear, anger, doubt, and triumph. It has survived all four, and so have I.",
            "This milestone feels less like a reward than a promise renewed. Whatever strength I have earned now belongs partly to those who will need it.",
            "I once wanted certainty from this path. I have found conviction instead, and conviction has proven much more useful.",
            "The road behind me contains mistakes I would gladly undo. It also contains the lessons that keep me from making them again.",
            "I can finally see how much of a paladin's work happens before the weapon is drawn. Judgment decides whether strength becomes service or vanity.",
            "I stand at sixty with faith that has been questioned enough to become my own. That means more than the polished certainty I began with.",
            "The journey has made me harder to shake and slower to condemn. If that is what experience was meant to teach, I am grateful for the long road.",
        },
    },
    ["HUNTER"] = {
        [1] = {
            "The wild has started speaking in details I used to miss. Tracks, broken grass, nervous birds, and sudden silence all tell their own small stories.",
            "In {location}, I learned that patience is often more useful than speed. The creature that rushes first usually reveals the most.",
            "My aim is improving, but awareness matters more. A good shot begins long before the bowstring moves.",
            "I used to watch only what I meant to hunt. Now I watch the ground, the wind, and everything watching me back.",
            "There is comfort in traveling with fewer walls around me. The open road makes sense when I remember to pay attention.",
            "I am learning the difference between being alone and being unprepared. The first can be peaceful. The second gets a hunter killed.",
            "Animals rarely waste movement without reason. I have started trying to follow their example.",
            "The first lessons have been practical ones: keep distance, read the terrain, and never assume a quiet patch of brush is empty.",
        },
        [2] = {
            "The farther I travel, the more local habits matter. A trail that means safety in one region can lead straight into danger in another.",
            "In {location}, I trusted the wind before I trusted my eyes. It proved the better guide.",
            "My shots are cleaner now because I am choosing them more carefully. Haste wastes arrows and sometimes much more.",
            "I have become better at noticing when the wild suddenly changes its behavior. Silence can be a warning as clear as any shout.",
            "Distance is a hunter's ally only if the ground allows it. I am learning to choose my battles with the landscape in mind.",
            "The road has taught me to respect unfamiliar beasts without inventing monsters where ordinary hunger explains enough.",
            "I carry more confidence than I did before, but I still check the tracks twice. Pride leaves poor footprints.",
            "Survival is starting to feel less like luck and more like a collection of habits practiced until they no longer need thought.",
        },
        [3] = {
            "I can read a trail with more patience now. What once looked like scattered marks often becomes a clear sequence when I stop forcing an answer.",
            "In {location}, I was reminded that the hunter who knows when not to pursue usually returns with the better story.",
            "My bond with the wild feels less romantic than it once did and more respectful. Nature is beautiful, but it has no obligation to be kind.",
            "I have become comfortable waiting. That may be the strangest change of all, because waiting used to feel like doing nothing.",
            "A clean hunt begins with understanding the creature, not with drawing a weapon. The more I learn, the less often I need to improvise.",
            "The road has sharpened my sense of distance. I know when something is too close, when it is about to become too close, and when I should already be moving.",
            "I notice other travelers stomping through signs I would once have missed myself. Remembering that keeps me from feeling too clever.",
            "Each region adds another set of tracks to memory. The world is becoming easier to read without becoming any less wild.",
        },
        [4] = {
            "Experience has made me quieter. I move with more purpose now and disturb less of what I am trying to understand.",
            "In {location}, the safest route was not the shortest one. A younger version of me would have learned that lesson the expensive way.",
            "I trust instinct more than I used to, but only because instinct has been corrected by enough mistakes to become useful.",
            "The wild rarely repeats itself exactly. Familiar patterns help, but attention still matters more than memory.",
            "I have learned that a hunter's pride can be dangerous when it turns every creature into a test. Some things are better observed from a respectful distance.",
            "My gear is more familiar, my aim steadier, and my decisions slower in the right ways. That combination has kept me alive.",
            "Tracking has taught me something about people as well. Everyone leaves signs when they move through the world, even when they believe otherwise.",
            "I am no longer surprised by how quickly a calm trail can become a fight. Preparation has replaced surprise with something closer to readiness.",
        },
        [5] = {
            "I have spent enough time outdoors to know that mastery is mostly attention sustained longer than other people find comfortable.",
            "In {location}, I caught the warning signs early and changed course without regret. Avoiding trouble can be a finer skill than surviving it.",
            "My respect for dangerous creatures has grown with my ability to kill them. Knowing how vulnerable something is makes carelessness feel less impressive.",
            "The road has made me independent without making me foolish enough to think I need no one. Even the best tracker benefits from another set of eyes.",
            "I can feel years of practice in the speed of small decisions. Which path, which target, which distance, which moment to stop moving.",
            "The wild has stopped feeling like a backdrop to my travels. It is part of every decision I make once the road leaves the town behind.",
            "I have learned to value a quiet return more than a dramatic hunt. Bringing everyone home is a skill worth cultivating.",
            "My senses feel trained rather than merely sharp. The difference is discipline, and discipline holds up better when I am tired.",
        },
        [6] = {
            "The signs are subtle now, but I notice them without effort. A bent stem or frightened animal can redirect an entire day before danger ever appears.",
            "In {location}, I realized how rarely I need to force the world to reveal itself. Most things become obvious when given enough time and silence.",
            "I no longer measure myself by the hardest beast I can bring down. Judgment about what deserves pursuit matters more.",
            "Long travel has made me comfortable with uncertainty. A hunter rarely knows everything ahead, only enough to choose the next sensible step.",
            "My hands know the tools, my eyes know the ground, and my patience has finally caught up with both.",
            "There are creatures I once feared that I now understand, and creatures I understand well enough to fear properly. Experience has improved both categories.",
            "I have become harder to surprise because I assume the world is always leaving clues. Usually, it is.",
            "The road toward mastery has made me less eager to prove myself. The wild does not care about reputation, and I have come to appreciate that.",
        },
        [7] = {
            "At sixty, the world still feels larger than my knowledge. That is exactly how I hoped it would feel.",
            "I have followed enough trails to know there is always another one beyond the last ridge. Mastery has not cured my curiosity.",
            "The hunter I was at the beginning chased signs. The hunter I am now reads the whole landscape before deciding which signs matter.",
            "This milestone was earned one careful choice at a time. Most of them were too small for anyone else to notice.",
            "I can travel farther, see more, and survive worse than I once could. The greatest improvement may simply be knowing when none of that needs proving.",
            "The wild has been teacher, adversary, shelter, and warning. I have learned something useful from every role it played.",
            "Level sixty feels less like reaching the end of a hunt and more like reaching high ground. From here, there is simply more to see.",
            "My aim has improved, but my patience has improved more. I would not trade the second for the first.",
        },
    },
    ["ROGUE"] = {
        [1] = {
            "I am learning that the best mistake is the one nobody notices because I corrected it before it became a problem.",
            "In {location}, keeping my eyes open proved more useful than keeping my blade ready. Information tends to arrive before danger if I am patient enough.",
            "Speed helps, but timing matters more. I am starting to understand why experienced rogues seem calm right before everything becomes chaotic.",
            "I used to think stealth meant not being seen. It also means knowing who is watching, where they are looking, and why.",
            "My hands are becoming surer around locks, pockets, and weapons. Confidence is useful, provided it stays quieter than I am.",
            "There is a certain freedom in knowing I do not have to meet every problem head-on. The side door is often there for a reason.",
            "I am beginning to trust preparation more than improvisation. Improvisation is still useful, but it is nicer when it is optional.",
            "A careless person notices danger when it arrives. I am trying to notice it while it is still considering the invitation.",
        },
        [2] = {
            "The road has taught me that every place has a rhythm. Once I understand who moves where and when, most problems become simpler.",
            "In {location}, I avoided a fight that would have been easy to start and expensive to finish. I count that as progress.",
            "My instincts are sharper now, though I suspect that is mostly experience wearing a more flattering name.",
            "People reveal a great deal when they believe nobody important is listening. I have become better at being nobody important.",
            "I am learning to treat escape routes as part of the plan instead of an embarrassing backup.",
            "A clean success often looks uneventful from the outside. I have developed a healthy appreciation for uneventful work.",
            "The difference between bold and reckless is sometimes only whether you checked the room first.",
            "I trust my hands more than I did before, but I trust a well-timed pause even more.",
        },
        [3] = {
            "I have stopped hurrying simply because I can move quickly. Waiting for the better moment saves more trouble than speed fixes.",
            "In {location}, the obvious path was watched and the ugly path was empty. Experience made the choice easy.",
            "I am getting better at reading people before they decide whether I am useful, dangerous, or forgettable. Forgettable remains underrated.",
            "A blade is only one tool among many. Attention, patience, and a convincing expression have solved problems steel would have made worse.",
            "The road has taught me not to confuse secrecy with mystery. Most hidden things become ordinary once you learn where to look.",
            "I still enjoy a clever solution, but I have become suspicious of cleverness that creates three new problems afterward.",
            "Survival has become less dramatic. I prefer it that way.",
            "I am starting to recognize traps built by people who think exactly as I used to. That is uncomfortable and extremely useful.",
        },
        [4] = {
            "Experience has made me less impressed by locked doors. The interesting question is usually why someone thought the door needed locking.",
            "In {location}, I learned more by watching for a minute than I would have learned by charging in for ten.",
            "I have become more comfortable leaving no proof that a problem ever existed. Quiet solutions age well.",
            "Risk is not the same thing as danger. The useful skill is knowing which risks I chose and which ones chose me.",
            "I trust my instincts, but I still count exits. Experience has made me careful, not magical.",
            "The best advantage is often small enough that nobody else notices it until it is too late to matter.",
            "I have learned that confidence draws attention. Sometimes that is useful. More often, I would rather let someone else have it.",
            "My younger self liked plans that sounded impressive. I prefer plans that work even when nobody applauds them.",
        },
        [5] = {
            "I have enough experience now to know when someone is trying to appear harmless. Familiarity recognizes its own tricks.",
            "In {location}, restraint saved me from turning a manageable problem into a memorable disaster. That may be the least glamorous skill I have earned.",
            "Success has become more about control than speed. I want to decide when the situation changes, not merely react when it does.",
            "I have grown less interested in proving I can enter dangerous places. Leaving them cleanly is the harder part.",
            "Trust remains complicated. I have learned that caution and loyalty can coexist if both are earned honestly.",
            "A veteran rogue should know when the prize is bait. I am pleased to say I recognize the hook more often now.",
            "My tools feel ordinary in my hands, which is exactly how practiced tools should feel. The thinking is where the real work has moved.",
            "I can spot nervous guards, lazy routines, and badly hidden valuables almost without trying. I make a point not to look too pleased about it.",
        },
        [6] = {
            "I have survived enough clever plans to respect simple ones. Complexity should earn its place.",
            "In {location}, I found myself ten steps ahead without consciously counting them. That kind of instinct took a very long time to build.",
            "Experience has made me harder to corner, partly because I stopped entering rooms without first wondering how I would leave them.",
            "I have become patient with locks and impatient with people who assume force is the only honest tool.",
            "The quiet skills have lasted. Timing, observation, restraint, and knowing when a problem does not need my name attached to it.",
            "I used to enjoy surprising people. These days I prefer when nothing surprises me.",
            "The road has taught me that reputation can open doors and close them just as quickly. Anonymity still has its charms.",
            "I no longer need every success to feel clever. Clean, safe, and finished is satisfying enough.",
        },
        [7] = {
            "At sixty, I have learned that surviving unseen is only one kind of success. Knowing when to step into the light matters too.",
            "The best proof of experience is how many disasters never happened because I noticed them early.",
            "I can look back on a long trail of locks, lies, narrow exits, and choices nobody else saw. That seems appropriately private.",
            "Mastery has made me less reckless, not more fearless. I consider that an excellent trade.",
            "I once wanted to be the cleverest person in every room. Now I would rather know who actually is.",
            "Level sixty feels like finally having enough experience to distrust easy opportunities on sight.",
            "My hands are quick, but judgment has become quicker. That is the skill I trust most.",
            "The road ahead will still contain traps. The difference is that I have become rather difficult to surprise twice.",
        },
    },
    ["PRIEST"] = {
        [1] = {
            "Faith feels simple in quiet places. The road is teaching me what it looks like when someone is frightened, hurting, or angry enough to test it.",
            "In {location}, I discovered that helping someone does not always mean knowing what to say. Presence can be its own kind of service.",
            "I expected prayer to bring answers. So far it has often brought enough calm to ask better questions.",
            "The power I carry can mend, protect, and harm. Learning when each is appropriate already feels more important than learning how.",
            "I am beginning to understand how much responsibility comes with being trusted in someone's weakest moment.",
            "Compassion sounds gentle until it requires patience with someone who has made it difficult. Those are the lessons I remember.",
            "The first steps of this path have made me more attentive to suffering than I was before. I cannot say that makes travel easier. It does make the journey more meaningful.",
            "I left {location} with fewer assumptions about what people need from me. Listening has become part of the discipline.",
        },
        [2] = {
            "The farther I travel, the more forms faith seems to take. I am learning to recognize sincerity even when it looks nothing like my own practice.",
            "In {location}, I could not fix everything that was wrong. Accepting that without becoming indifferent was its own challenge.",
            "I have become steadier around pain. Not numb, I hope. Simply less likely to let another person's fear become my panic.",
            "Prayer has become less about asking for certainty and more about making room for courage.",
            "I am learning that healing is not the same as undoing what happened. Some wounds close while the memory remains.",
            "The road offers plenty of reasons to become cynical. I would rather become discerning.",
            "I have begun to notice how much comfort people take from simple acts of attention. That kind of power deserves as much care as any spell.",
            "Faith does not make every decision easier. Sometimes it only prevents me from choosing carelessly.",
        },
        [3] = {
            "I have stopped expecting wisdom to arrive before the difficult moment. Often it is something I recognize afterward and try to carry into the next one.",
            "In {location}, kindness and caution were both necessary. I am getting better at holding two truths without forcing one to erase the other.",
            "My strength has grown, but so has my awareness of how easily spiritual authority can become arrogance.",
            "I am learning to offer guidance without pretending I can see every path clearly myself.",
            "Some people need healing. Others need permission to grieve. Knowing the difference has become part of the work.",
            "The more suffering I witness, the less interested I am in tidy explanations for it.",
            "I have found that faith survives questions better than fear suggests it will. Mine feels stronger for having been examined.",
            "There are moments when I cannot change the outcome. I can still decide what kind of person stands beside it.",
        },
        [4] = {
            "Experience has made my prayers quieter and my attention sharper. I spend less time reaching for perfect words.",
            "In {location}, I was reminded that people often reveal what hurts only after they decide they are safe enough to do so.",
            "I have learned that compassion needs boundaries or it becomes exhaustion dressed as virtue.",
            "My calling asks me to care without assuming ownership of every burden I encounter. That lesson has taken time.",
            "Faith has become something I practice rather than something I merely possess. The difference matters most when I am tired.",
            "I am less frightened by doubt now. Honest doubt has led me toward better convictions than borrowed certainty ever did.",
            "There is power in being the calmest person in a frightened group. I try not to mistake that calm for superiority.",
            "Some wounds are spiritual, some physical, and many refuse to stay in only one category. Experience has made me slower to simplify them.",
        },
        [5] = {
            "I have seen enough suffering to know that easy judgments are usually made from too far away.",
            "In {location}, I could offer help without taking control. That felt like a small but important victory.",
            "My faith has endured disappointment, which has made it sturdier and less decorative.",
            "I have become more careful with certainty. People listen differently when they believe the speaker carries sacred authority.",
            "Healing still feels miraculous, but I no longer expect miracles to remove every consequence.",
            "The road has taught me that hope can be quiet. Sometimes it is simply the decision to return tomorrow.",
            "I carry more confidence in my abilities and less confidence in my ability to understand every person's story at first glance.",
            "There are days when compassion costs more than power. Those days have shaped me most.",
        },
        [6] = {
            "I no longer measure faith by how untroubled I feel. I measure it by what remains when trouble has finished asking its questions.",
            "In {location}, I found myself listening before preparing an answer. Years of practice have finally made that instinctive.",
            "I have learned that spiritual strength can look like gentleness, refusal, endurance, or grief honestly faced.",
            "The people I could not save have taught me as much about this calling as the ones I could.",
            "I carry fewer illusions about my limits, which has made the help I can offer more honest.",
            "Experience has made me less interested in being seen as wise. Wisdom is useful only when it helps someone live through the next hard thing.",
            "My prayers now include gratitude for uncertainty. It keeps me humble enough to keep listening.",
            "I have become comfortable admitting when I do not know. The strange thing is that people often trust me more afterward.",
        },
        [7] = {
            "At sixty, my faith feels less like an answer and more like a way of walking through questions without abandoning compassion.",
            "I have healed wounds, witnessed losses, and carried doubts I once thought would break me. None of them left me unchanged.",
            "This milestone does not make me wise. It reminds me how long I have been practicing the habits that make wisdom possible.",
            "I once wanted to know exactly what the Light, the Shadow, or the divine expected. I have learned to pay closer attention to the person in front of me.",
            "The road behind me is full of people whose names I may forget but whose pain changed how I serve.",
            "I stand at sixty with stronger power and a deeper respect for the harm careless certainty can cause.",
            "My calling has become more human with experience, not less sacred. I think that is why it finally feels like mine.",
            "I have learned that faith can be both shelter and question. Carrying both has made the journey richer.",
        },
    },
    ["SHAMAN"] = {
        [1] = {
            "The elements do not feel like tools. They feel like voices I am only beginning to hear clearly enough to answer.",
            "In {location}, the wind changed before the danger did. I noticed too late, but I noticed. That feels like a beginning.",
            "I expected power to come from speaking. Much of this path seems to begin with listening.",
            "Earth has patience I do not yet possess. Fire has certainty I should probably possess less often.",
            "The first lessons have made the world feel crowded in a comforting way. Stone, rain, flame, and air all carry their own presence.",
            "I am learning that asking the elements for aid is different from commanding them. Respect changes the nature of the answer.",
            "My steps feel more deliberate now. The land beneath them has stopped feeling silent.",
            "In {location}, I felt how quickly balance can change. A small disturbance can become a larger one if nobody is paying attention.",
        },
        [2] = {
            "The farther I travel, the more distinct each land feels. The elements speak with different tempers depending on where I stand.",
            "In {location}, water taught patience while fire demanded action. I am learning that balance is not the same thing as stillness.",
            "I have become more careful about asking for power before understanding the need.",
            "The spirits and elements rarely offer simple instructions. They offer signs, and I am getting better at living with interpretation.",
            "Thunder once felt like spectacle. Now I hear warning, distance, and the shape of weather inside it.",
            "My connection to the world feels stronger because I have stopped trying to make every force behave according to my preference.",
            "I am beginning to understand why elders speak in stories. Direct answers often fail to carry the whole truth.",
            "The road has made me more aware of what a place has endured. Land remembers disturbance in ways travelers often ignore.",
        },
        [3] = {
            "I can feel when something in a place is out of balance more quickly now. Knowing what to do about it remains the harder lesson.",
            "In {location}, I asked less and listened longer. The answer came slowly, but it was better for the waiting.",
            "The elements are not moral in the way people are. Fire can warm or destroy. Wisdom lies in the relationship, not the force itself.",
            "I have learned to respect change without worshiping chaos. Rivers move, winds turn, and even mountains break in time.",
            "My confidence has grown alongside a healthy fear of forcing what should be persuaded.",
            "Ancestral wisdom feels less distant than it once did. Perhaps I finally have enough experience to understand parts of what I was told.",
            "The road has taught me that harmony can include conflict. Storms are part of the world too.",
            "I am becoming more comfortable admitting when I do not understand what the land is telling me. Listening poorly is worse than asking again.",
        },
        [4] = {
            "Experience has made the elements feel less mysterious without making them ordinary. Familiarity has deepened the respect rather than weakened it.",
            "In {location}, the ground itself seemed to warn against haste. I listened this time.",
            "I have learned that balance is active work. Left alone, many forces do not settle into harmony. They simply continue pulling.",
            "My bond with the spirits feels steadier because I no longer expect constant signs. Silence can be part of the conversation.",
            "Fire answers quickly, earth slowly, water indirectly, and air whenever it pleases. I have stopped expecting one lesson to fit them all.",
            "The road has taught me to look for consequences beyond the immediate moment. Every disturbance travels somewhere.",
            "I am less impressed by raw elemental force than I once was. Control without relationship feels hollow.",
            "Some of the best guidance arrives as a feeling that something is wrong long before I can explain why. I have learned not to dismiss that.",
        },
        [5] = {
            "I have traveled enough to recognize places that have been wounded by greed, war, or careless magic. The elements carry those injuries plainly.",
            "In {location}, I felt how much easier it is to call for strength than to repair what strength has damaged.",
            "My understanding of balance has become less tidy. Sometimes preserving one thing means allowing another to change.",
            "I have become more patient with the slow work of restoration. Earth rarely hurries, yet it outlasts nearly everything.",
            "The spirits do not flatter experience. They remain perfectly capable of reminding me when I have grown arrogant.",
            "I listen more carefully before I act now, especially when anger makes fire seem like the obvious answer.",
            "The farther I travel, the more I understand why a shaman belongs partly to place and partly to people. Both require attention.",
            "I have learned that respect is not passivity. Sometimes harmony needs someone willing to confront the force breaking it.",
        },
        [6] = {
            "The elements feel like old companions now, though companions with their own wills and no obligation to make my path easy.",
            "In {location}, I recognized imbalance almost immediately. Years of listening have turned some truths into instinct.",
            "I no longer seek signs simply to reassure myself that I am heard. The relationship has become steadier than that.",
            "The ancestors feel closer when I make choices they would have understood, and sharper when I repeat mistakes they already warned against.",
            "Experience has taught me to value quiet ground after a storm. Restoration deserves as much reverence as power.",
            "I have become less interested in commanding nature and more interested in standing where my effort can help competing forces find room.",
            "The road has made me humble about scale. A shaman can influence the elements, but the world remains vastly larger than any one will.",
            "I trust my connection more because it has survived places where the land felt alien, damaged, or nearly silent.",
        },
        [7] = {
            "At sixty, I do not feel above the elements. I feel more deeply responsible for how I stand among them.",
            "The long road has taught me that balance is never finished. It is renewed one choice, one place, and one relationship at a time.",
            "I can hear more now than I could at the beginning, but the world has also taught me how much remains beyond my understanding.",
            "This milestone feels like a conversation continuing rather than a lesson completed.",
            "I have called wind, flame, water, and stone through danger and grief. None of them became mine, and I am grateful for that.",
            "Level sixty has given me confidence in the bond and humility about the power behind it. I hope to keep both.",
            "The ancestors gave me stories. Experience has finally given me enough context to hear what some of them were trying to say.",
            "I stand here stronger, but the greater change is quieter. I listen before I reach.",
        },
    },
    ["MAGE"] = {
        [1] = {
            "Magic feels less like a collection of spells now and more like a discipline with consequences for every careless assumption.",
            "In {location}, one small mistake in timing taught me more than several clean successes. Arcane study can be an unforgiving tutor.",
            "I am beginning to understand why experienced mages seem obsessed with preparation. Power is much easier to admire before it misbehaves.",
            "The first spells felt remarkable because they worked. Now I am starting to care about why they worked.",
            "I have learned to slow down before reaching for the most impressive solution. Simpler magic often leaves fewer problems behind.",
            "Control is becoming more satisfying than spectacle. That is probably a healthy development.",
            "The world looks different once everything becomes a possible interaction of energy, distance, and timing. I need to remember that people are not equations.",
            "In {location}, curiosity nearly outran caution. I managed to catch up before either became a disaster.",
        },
        [2] = {
            "The farther I travel, the more I appreciate how local conditions change even familiar magic. Theory travels better than practice.",
            "In {location}, careful preparation saved me from having to improvise under pressure. I would like to make that a habit.",
            "I have begun keeping better mental notes about what fails, not only what succeeds. Failure is annoyingly informative.",
            "Arcane power rewards precision and punishes vanity with equal enthusiasm.",
            "I used to measure progress by how impressive a spell looked. Reliability has become a much more attractive standard.",
            "The road has turned abstract lessons into practical ones. Range, line of sight, and timing feel more important outside a classroom.",
            "I am learning that curiosity needs boundaries if I want to remain alive long enough to satisfy it.",
            "Magic still delights me. Experience has simply added the useful question of what it will cost before I begin.",
        },
        [3] = {
            "I can feel patterns in spellwork that once required deliberate thought. The basics are becoming instinct, leaving more room for judgment.",
            "In {location}, I solved a problem with less power than I first intended. Efficiency can be surprisingly elegant.",
            "The difference between confidence and carelessness is often one assumption left unchecked.",
            "I have become comfortable abandoning a clever approach when the evidence says it is wrong. Pride is a terrible research method.",
            "The world keeps presenting phenomena that refuse to fit neatly into what I already know. I find that encouraging.",
            "I am learning to treat magical limits as useful information rather than personal insults.",
            "Some of my best decisions now happen before the first spell is cast. Preparation is finally becoming part of the magic rather than something that delays it.",
            "I once wanted every mystery to have a clean answer. These days I am satisfied when I can ask the next question more precisely.",
        },
        [4] = {
            "Experience has made spellcasting quieter in my mind. The calculations still happen, but fewer of them need conscious attention.",
            "In {location}, a familiar technique behaved differently enough to demand respect. The world remains better at experimentation than I am.",
            "I have grown more skeptical of elegant theories that have never been tested under pressure.",
            "Power is abundant compared with judgment. I have spent more time cultivating the second lately.",
            "I am beginning to appreciate restraint as a form of mastery. The spell not cast can matter as much as the one that lands perfectly.",
            "My curiosity has survived danger, which is fortunate. My recklessness has survived less well.",
            "The farther I travel, the more I understand that magical traditions are shaped by place, history, and need. There is no single classroom large enough for Azeroth.",
            "I have become better at noticing when I do not know enough. That realization arrives earlier now, which has saved me trouble.",
        },
        [5] = {
            "I have enough experience to make difficult magic look easier than it is. I try to remember how dangerous that illusion can be for me and for anyone learning from me.",
            "In {location}, precision mattered more than force. I enjoyed that outcome more than I expected.",
            "My notes are full of corrections to ideas I once defended confidently. That may be the most honest record of progress I possess.",
            "Magic offers endless ways to solve a problem and nearly as many ways to create a new one.",
            "I have become less interested in proving what I can cast and more interested in understanding what the situation actually requires.",
            "The arcane still rewards curiosity, but I have finally learned to make curiosity bring proper equipment.",
            "Experience has made me quicker at recognizing unstable assumptions before they become unstable spells.",
            "I trust my knowledge more because I have seen it fail, revised it, and watched it hold up afterward.",
        },
        [6] = {
            "Much of what once felt difficult now feels familiar, which makes unfamiliar problems more interesting and more dangerous.",
            "In {location}, I noticed myself adjusting a spell almost without thought. Years of study have become muscle memory in ways I never expected.",
            "I no longer mistake complexity for sophistication. The clean solution is often the one that required the deepest understanding.",
            "Mastery has not reduced the number of questions. It has improved their quality.",
            "I have learned to respect the gap between knowing a principle and applying it while something is trying to kill me.",
            "The arcane feels less like a force I wield and more like a language I speak with increasing fluency. Poor grammar can still explode.",
            "I have become patient with problems that resist immediate answers. That patience may be the least flashy and most useful spell I have learned.",
            "The road has given me a laboratory with terrible safety standards and excellent variety.",
        },
        [7] = {
            "At sixty, I know enough magic to understand how much of it remains beyond me. That is a satisfying place to stand.",
            "The early fascination never left. It simply acquired discipline, caution, and a much longer list of questions.",
            "I once thought mastery would mean having answers. It seems to mean recognizing the important uncertainties sooner.",
            "This milestone is built from study, failed assumptions, careful revisions, and a few experiments I will not repeat.",
            "My control has grown with my power, which is fortunate for everyone nearby.",
            "Level sixty feels less like graduation and more like being trusted with a larger library key.",
            "I can look back and see where curiosity became scholarship. I hope it never becomes complacency.",
            "The arcane still surprises me. After this long, I consider that one of its best qualities.",
        },
    },
    ["WARLOCK"] = {
        [1] = {
            "Power answered more readily than I expected. The unsettling part is how quickly that can start to feel normal.",
            "In {location}, curiosity opened a door I was not entirely prepared to close. I managed it, but the lesson stayed with me.",
            "I am learning that dangerous knowledge rarely announces itself as dangerous. Usually it presents itself as useful.",
            "Control is the word I keep returning to. Power without it is merely another threat in the room.",
            "The first summons and curses carried a thrill I would be foolish to deny. I am trying to keep fascination from becoming hunger.",
            "I used to think the greatest risk was that something would refuse to answer. Now I suspect the worse risk is when it answers too eagerly.",
            "There is a difference between studying darkness and admiring it. I intend to keep that line visible.",
            "In {location}, I learned that preparation matters even more when the thing being prepared for has opinions of its own.",
        },
        [2] = {
            "The farther I travel, the more tempting shortcuts appear. I am beginning to understand why so many warnings are written by people who once considered themselves exceptions.",
            "In {location}, restraint proved more useful than ambition. I do not expect that lesson to become comfortable.",
            "My command is improving, but so is my respect for what happens when command slips.",
            "I have learned to negotiate with power in the broadest sense. Demons, fear, secrets, and my own curiosity all demand terms.",
            "Forbidden knowledge is often forbidden for reasons less simple than cowards claim and more serious than fools admit.",
            "The road has shown me enough consequences to make caution feel less like weakness.",
            "I am becoming better at recognizing when a useful secret is trying to become an obsession.",
            "Power has stopped feeling rare. Judgment still does, which makes it the more valuable resource.",
        },
        [3] = {
            "I can call on darker forces with steadier hands now. That steadiness matters because the forces themselves have not become safer.",
            "In {location}, I knew exactly how much power I could take before control became uncertain. Knowing the boundary was more satisfying than crossing it.",
            "I have become suspicious of anyone who claims dangerous knowledge leaves the knower unchanged.",
            "Demons respect strength, bargains, leverage, and weakness in varying proportions. I have learned not to confuse any of those with loyalty.",
            "The path has made me less frightened of darkness and more attentive to what it reveals about me.",
            "I used to collect secrets because they were hidden. Now I ask whether knowing them improves my position or merely feeds appetite.",
            "Control is beginning to feel less like force and more like discipline maintained over time.",
            "I have survived enough mistakes to know that confidence around fel power should always leave room for an exit.",
        },
        [4] = {
            "Experience has made the dangerous arts feel familiar, which may be the most dangerous development yet. Familiarity deserves its own precautions.",
            "In {location}, I felt the pull to use more power than the situation required. Refusing was easier than it once would have been.",
            "I have learned that corruption is rarely a single dramatic choice. More often it is a series of convenient exceptions.",
            "My summons obey more reliably now, but I trust them exactly as far as the binding requires.",
            "Knowledge has given me leverage, and leverage has given me responsibility whether I wanted it or not.",
            "I am less impressed by displays of forbidden power than I used to be. Control under pressure is harder and far more interesting.",
            "The line between ambition and compulsion can become thin when results keep rewarding both.",
            "I have begun recording what works and what it makes me willing to attempt next. The second result can matter more.",
        },
        [5] = {
            "I have seen enough reckless practitioners to recognize the habits that lead toward ruin. The uncomfortable part is noticing some of them in myself.",
            "In {location}, I chose the slower method because it left fewer things capable of betraying me afterward.",
            "My relationship with power has become more transactional and less romantic. That is probably healthy.",
            "I have learned that fear is useful information until it becomes the one making decisions.",
            "The darkness offers many truths people would rather not examine. It also offers lies tailored for those who enjoy feeling clever.",
            "I am more careful with bargains now. The most expensive clause is often the one nobody bothers to read.",
            "Experience has not made temptation weaker. It has made the pattern easier to recognize before I call it necessity.",
            "I can wield forces that once intimidated me. I make a point of remembering they remain capable of earning that intimidation back.",
        },
        [6] = {
            "The dangerous arts have become ordinary tools in my hands. I refuse to let ordinary mean harmless.",
            "In {location}, I recognized a familiar temptation and declined it before the argument could begin. That may be what maturity looks like on this path.",
            "I have stopped believing mastery means domination. Sometimes mastery is knowing what never deserves to be unleashed.",
            "Demons still test boundaries. So do I. Experience has taught me to notice which side of the line is actually moving.",
            "I carry secrets now that would have terrified the novice I once was. Some still terrify the person I am, which I consider reassuring.",
            "Power is easier to acquire than perspective. I have spent years earning the latter the difficult way.",
            "The road has taught me to distrust the thought that only one more risk will finally be enough.",
            "I know how to reach farther into darkness now. More importantly, I know how to return.",
        },
        [7] = {
            "At sixty, I possess power that once would have seemed impossible. The fact that I still respect it may be the achievement I value most.",
            "The path did not consume me, though I understand better now how easily it could have.",
            "I have learned enough forbidden things to stop believing that knowledge itself is the danger. Hunger without limits is.",
            "This milestone is built from bargains kept, bindings tested, temptations refused, and a few mistakes that remain private for good reason.",
            "I once wanted to prove that I could control anything I summoned. Experience has given me more realistic ambitions.",
            "Level sixty does not make the darkness safe. It makes me harder to fool about what safety would require.",
            "I can look back and see where curiosity became discipline. There are still doors I intend to open, but not without checking the hinges.",
            "Power has become familiar. Consequence has become clearer. I consider both developments useful.",
        },
    },
    ["DRUID"] = {
        [1] = {
            "The first changes of shape taught me how strange it is to borrow another creature's instincts without losing my own.",
            "In {location}, I noticed how quickly the land reveals whether I am moving with it or simply across it.",
            "I expected nature to feel peaceful. Instead it feels alive, which includes hunger, struggle, growth, and decay.",
            "Learning to shift perspective has become as important as shifting form. The world looks different close to the ground.",
            "I am beginning to understand that balance is not a quiet state. It is constant adjustment.",
            "The wild does not care whether I feel ready. That has made it an excellent teacher.",
            "My connection to living things feels less abstract now. Every place has its own pace, damage, and resilience.",
            "In {location}, I learned that healing and growth cannot be hurried simply because I want the result.",
        },
        [2] = {
            "The farther I travel, the more varied nature becomes. Forest, plain, snow, and swamp each ask for a different kind of attention.",
            "In {location}, one form solved what another could not. Flexibility is becoming more than a talent. It is a way of thinking.",
            "I have stopped imagining balance as equal parts of everything. Some moments require claws, others patience.",
            "The wild teaches through consequence. Ignore the weather, the terrain, or the creature in front of you and the lesson arrives quickly.",
            "My shifting feels more natural now, though I remain aware that each form carries instincts worth respecting.",
            "I am learning to heal without trying to freeze things exactly as they were. Recovery often changes what it restores.",
            "The road has made me suspicious of anyone who calls nature gentle simply because they admire it from a safe distance.",
            "I feel more at home in unfamiliar country because I know how to watch before deciding what kind of place it is.",
        },
        [3] = {
            "I can move between roles with less hesitation now. The situation changes, and I change with it.",
            "In {location}, patience did more than force could have managed. The land has a way of rewarding those who stop trying to hurry it.",
            "Balance has become practical rather than philosophical. Food, rest, aggression, healing, and retreat all have their season.",
            "I am beginning to understand how much damage people can do when they see land only as a resource.",
            "The forms feel less like disguises and more like different truths about the same self.",
            "I have learned that adaptation is not surrender. Sometimes changing is the strongest way to remain true to a purpose.",
            "The wild contains no shame in retreat, sleep, hunger, or ferocity. I have started questioning which human judgments are actually useful.",
            "I notice cycles now that I once treated as isolated events. Decay feeds growth. Predators shape herds. Fire can clear space for return.",
        },
        [4] = {
            "Experience has made shifting almost conversational. I no longer ask which form is strongest, only which one belongs in this moment.",
            "In {location}, the damage to the land told a clearer story than any traveler could have.",
            "I have become more comfortable with nature's harsher truths. Balance includes death, but it should not include needless destruction.",
            "The road has taught me to distinguish wildness from neglect. A healthy wilderness and a wounded one do not feel the same.",
            "My instincts in each form are stronger now, and so is my responsibility not to let instinct make every decision.",
            "I am learning that restoration often begins with removing the thing preventing recovery, not with forcing growth.",
            "Some places recover quickly after harm. Others carry scars for generations. I have become slower to assume resilience means invulnerability.",
            "I feel less divided between civilization and wilderness than I once did. Both can nurture, both can destroy, and both need wise limits.",
        },
        [5] = {
            "I have seen enough damaged places to know that balance can be broken deliberately. Restoring it may require more than patience.",
            "In {location}, I found signs of recovery where I expected only ruin. Nature remains capable of surprising me in kinder ways.",
            "My shifting has become effortless enough that the harder question is who I am choosing to be before the change begins.",
            "I no longer romanticize the wild. Respect has replaced admiration that was too simple.",
            "The road has shown me forests, plains, and creatures shaped by war. Healing a world is slower than winning a battle inside it.",
            "I have learned to value boundaries. Growth without limits can become as destructive as decay.",
            "Experience has made me more protective of living systems I once barely noticed. Small losses accumulate.",
            "I feel increasingly responsible for the spaces between great events, where ordinary life either returns or quietly disappears.",
        },
        [6] = {
            "The forms are old companions now. Each carries a different answer, and I have learned not to ask one shape to solve every problem.",
            "In {location}, I felt the land's condition before I consciously understood it. Years of attention have become instinct.",
            "Balance still resists simple definitions. I trust that more than the tidy answers I began with.",
            "I have learned that restoration may take longer than the druid who begins it. Some work is done for people who will never know my name.",
            "The wild has made me humble about permanence. Everything changes, including the things we swear will last.",
            "I carry the strength of different forms without believing strength alone is the purpose of any of them.",
            "The road has taught me to protect what can heal itself and intervene where harm has exceeded that ability.",
            "I am less interested in controlling nature than in understanding when my presence helps and when it merely adds another disturbance.",
        },
        [7] = {
            "At sixty, I feel less like a master of nature than a more attentive participant in it. That distinction matters.",
            "The long road has taught me to change without losing the center I return to.",
            "I have worn many forms and walked many landscapes. None of them made balance simple, but all of them made it real.",
            "This milestone feels like another season turning. Important, earned, and still part of a much larger cycle.",
            "I once wanted harmony to mean peace. Experience has taught me that healthy systems can be fierce.",
            "Level sixty has given me greater power to protect, heal, and adapt. It has also made me more cautious about deciding what needs my interference.",
            "I can look back and see how often growth required letting an older version of myself fall away.",
            "The wild remains larger than my understanding. I am glad mastery did not make it smaller.",
        },
    },
}

local GENERIC_REFLECTIONS = {
    [1] = {
        "The road still feels new enough to surprise me. I am beginning to trust the person making the decisions more than the beginner who first set out.",
        "In {location}, a small success felt larger than it should have. Perhaps that is what early progress is supposed to feel like.",
        "I am making fewer mistakes for the same reasons. New mistakes have taken their place, which at least means I am moving forward.",
        "Confidence has begun to replace hesitation in small, useful amounts.",
        "The world has not become safer. I have simply become less unprepared for it.",
        "These first levels have taught me that experience is mostly a collection of lessons I would rather not pay for twice.",
        "I can feel the difference between where I started and where I stand now, even if the distance on the map is small.",
        "I am still learning what kind of adventurer I will become. For now, surviving long enough to find out seems worthwhile.",
    },
    [2] = {
        "The road beyond familiar ground has made me more independent and more aware of the limits of independence.",
        "In {location}, experience mattered more than enthusiasm. That is becoming a familiar lesson.",
        "I make decisions with less hesitation now, though I hope I have not confused speed with wisdom.",
        "The wider world is beginning to feel less overwhelming and more complicated. I prefer complicated.",
        "I have learned to prepare for trouble without expecting trouble to follow the plan.",
        "Confidence has become useful now that it is backed by enough mistakes to know its limits.",
        "I am starting to recognize the difference between a hard day and a bad decision.",
        "The journey has become less about proving I belong on the road and more about deciding what I want to do with it.",
    },
    [3] = {
        "Experience is settling into habit. I notice it most when an old problem no longer requires an argument with myself.",
        "In {location}, I handled something calmly that would once have made me panic. That change feels more meaningful than the level itself.",
        "The road has made me more capable without making me certain. I think that is a good balance.",
        "I am beginning to trust instincts that have survived enough correction to earn it.",
        "Some lessons only become visible when an old challenge suddenly feels ordinary.",
        "I have learned that independence is not the same thing as refusing help.",
        "My choices feel more deliberate now. Even mistakes tend to be new ones.",
        "The person writing these pages is starting to feel different from the one who began them.",
    },
    [4] = {
        "Experience has made the road quieter in my head. I spend less time reacting and more time choosing.",
        "In {location}, I was reminded that being seasoned is not the same as being safe.",
        "Old habits have become instincts, and instincts have finally learned to listen to judgment.",
        "I no longer need every challenge to prove something about me. Solving it cleanly is enough.",
        "The journey has grown larger, but so has my sense of what I can handle.",
        "I have become better at noticing the moment when confidence starts turning into carelessness.",
        "Somewhere along the way, preparation stopped feeling cautious and started feeling professional.",
        "I can look back at earlier pages and recognize the mistakes before I reach the sentence where I made them.",
    },
    [5] = {
        "The road has tested enough versions of me that I trust the one still standing more than I used to.",
        "In {location}, patience solved what force would have complicated. I am learning to appreciate uneventful success.",
        "Experience has made me less eager to impress and more interested in getting things right.",
        "I carry more responsibility now because people tend to expect competence from someone who has survived this long.",
        "The dangers are familiar enough to recognize and serious enough not to underestimate.",
        "I have stopped measuring progress only by what I can defeat. Judgment has become part of the record.",
        "Old mistakes still travel with me, but most have been converted into useful warnings.",
        "The journey feels substantial now. There is enough road behind me to have shaped the way I meet what comes next.",
    },
    [6] = {
        "Mastery seems to be built from ordinary habits performed correctly when everything becomes difficult.",
        "In {location}, I noticed how little conscious effort some old lessons require now. They have become part of how I move through the world.",
        "I have fewer illusions about danger and more confidence in my ability to respond to it.",
        "The road has made me steadier, not invulnerable. I value the first far more.",
        "I am less interested in proving how far I have come than I am in making the experience useful.",
        "Old challenges still deserve respect. The difference is that I arrive with more answers and fewer excuses.",
        "I can feel the weight of a long journey without wishing it had been easier.",
        "The summit is close enough to see, but experience has cured me of assuming the final steps will be simple.",
    },
    [7] = {
        "Level sixty feels earned, which is more satisfying than it feeling grand.",
        "The road does not end here. I simply meet the next part of it with a great deal more experience.",
        "I can look back and see a chain of small decisions that somehow became a life of adventure.",
        "Mastery has not removed uncertainty. It has made uncertainty easier to carry.",
        "This milestone belongs to every mistake corrected, every lesson remembered, and every day I chose to continue.",
        "I am not the adventurer who began these pages. I am glad the journal kept enough evidence to prove it.",
        "The number is impressive, but the habits behind it matter more.",
        "I have reached sixty with scars, stories, and enough perspective to know that none of them make me finished.",
    },
}

local REFLECTION_CHAPTERS = {
    { minLevel = 1,  maxLevel = 10 },
    { minLevel = 11, maxLevel = 20 },
    { minLevel = 21, maxLevel = 30 },
    { minLevel = 31, maxLevel = 40 },
    { minLevel = 41, maxLevel = 50 },
    { minLevel = 51, maxLevel = 59 },
    { minLevel = 60, maxLevel = 60 },
}

local function GetReflectionChapterIndex(level)
    level = tonumber(level)
    if not level then
        return 1
    end

    for index, chapter in ipairs(REFLECTION_CHAPTERS) do
        if level >= chapter.minLevel and level <= chapter.maxLevel then
            return index
        end
    end

    if level > 60 then
        return 7
    end

    return 1
end

local function GetCurrentClassInfo()
    if UnitClass then
        local className, classToken = UnitClass("player")
        return classToken or "UNKNOWN", className or classToken or "Adventurer"
    end

    return "UNKNOWN", "Adventurer"
end

local function ShuffleArray(array)
    for i = #array, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
end

function CS:GetReflectionPool(classToken, level)
    local chapterIndex = GetReflectionChapterIndex(level)
    local classPools = CLASS_REFLECTIONS[classToken]
    local pool = classPools and classPools[chapterIndex]

    if not pool or #pool == 0 then
        pool = GENERIC_REFLECTIONS[chapterIndex] or GENERIC_REFLECTIONS[1]
    end

    return pool, chapterIndex
end

function CS:RenderLevelReflection(template, milestone)
    template = template or "Another hard-earned step has become part of the journey."
    local location = self:FormatLocation(milestone and milestone.location)

    return (template:gsub("{location}", function()
        return location
    end))
end

function CS:GetNextLevelReflection(classToken, level, milestone)
    local chronicle = self:GetChronicle()
    chronicle.levelReflectionBags = chronicle.levelReflectionBags or {}
    chronicle.levelReflectionLast = chronicle.levelReflectionLast or {}

    local pool, chapterIndex = self:GetReflectionPool(classToken, level)
    local bagKey = tostring(classToken or "UNKNOWN") .. ":" .. tostring(chapterIndex)
    local bag = chronicle.levelReflectionBags[bagKey]

    if type(bag) ~= "table" or #bag == 0 then
        bag = {}

        for i = 1, #pool do
            table.insert(bag, i)
        end

        ShuffleArray(bag)

        -- Avoid an immediate repeat when a bag refills. This matters in the
        -- 10-level chapters because each hand-written pool contains 8 entries.
        local lastID = chronicle.levelReflectionLast[bagKey]
        if #bag > 1 and lastID and bag[#bag] == lastID then
            bag[#bag], bag[#bag - 1] = bag[#bag - 1], bag[#bag]
        end

        chronicle.levelReflectionBags[bagKey] = bag
    end

    local reflectionID = table.remove(bag)
    chronicle.levelReflectionLast[bagKey] = reflectionID

    local template = pool[reflectionID] or pool[1]
    local rendered = self:RenderLevelReflection(template, milestone)

    return reflectionID, rendered, chapterIndex
end

function CS:AssignMilestoneReflection(milestone)
    if not milestone then
        return nil
    end

    if type(milestone.reflectionText) == "string" and milestone.reflectionText ~= "" then
        return milestone.reflectionText
    end

    local classToken = milestone.classToken
    local className = milestone.className

    if not classToken or classToken == "" then
        classToken, className = GetCurrentClassInfo()
    end

    local level = tonumber(milestone.level) or 1
    local pool, chapterIndex = self:GetReflectionPool(classToken, level)
    local reflectionID = tonumber(milestone.reflectionID)

    local rendered
    if reflectionID and pool[reflectionID] then
        rendered = self:RenderLevelReflection(pool[reflectionID], milestone)
    else
        reflectionID, rendered, chapterIndex = self:GetNextLevelReflection(
            classToken,
            level,
            milestone
        )
    end

    -- Store both the reference and the rendered prose. Saving the final text
    -- makes the character's history stable even if reflection pools change in
    -- a later addon version.
    milestone.classToken = classToken
    milestone.className = className
    milestone.reflectionChapter = chapterIndex
    milestone.reflectionID = reflectionID
    milestone.reflectionText = rendered

    return rendered
end

function CS:GetMilestoneNarrative(milestone)
    if not milestone then
        return "No chronicle entry was recorded."
    end

    return self:AssignMilestoneReflection(milestone)
        or "Another hard-earned step has become part of the journey."
end
