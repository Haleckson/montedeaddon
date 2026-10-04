local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.UI = FieldJournal.UI or {}

local UI = FieldJournal.UI

local frame = CreateFrame("Frame", "FieldJournalJournalFrame", UIParent, "BackdropTemplate")
UI.JournalFrame = frame

frame:SetSize(1100, 500)
function frame:ApplyJournalScale()
    local requested = FieldJournal.Config and FieldJournal.Config.GetJournalScale
        and FieldJournal.Config:GetJournalScale() or 1.2
    -- Keep the whole book on screen at smaller resolutions or larger UI scales.
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local applied = requested
    if screenWidth and screenHeight and screenWidth > 0 and screenHeight > 0 then
        applied = math.min(requested,
            screenWidth * 0.94 / self:GetWidth(),
            screenHeight * 0.94 / self:GetHeight())
    end
    self:SetScale(applied)
    return applied
end
frame:ApplyJournalScale()
frame:SetPoint("CENTER")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame:SetBackdrop({
    bgFile = nil,
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
})
frame:SetBackdropBorderColor(0.55, 0.42, 0.12, 1)

-- =========================
-- PAPER BACKGROUND
-- =========================
frame.paperLeft = frame:CreateTexture(nil, "BACKGROUND")
frame.paperLeft:SetPoint("TOPLEFT", frame, "TOPLEFT")
frame.paperLeft:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", 0, 0)
frame.paperLeft:SetAtlas("spellbook-Page-Left-C60", false)

frame.paperRight = frame:CreateTexture(nil, "BACKGROUND")
frame.paperRight:SetPoint("TOPLEFT", frame, "TOP")
frame.paperRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
frame.paperRight:SetAtlas("spellbook-Page-Right-C60", false)

frame:Hide()

local JOURNAL_SOUNDS = {
    open = { "IG_SPELLBOOK_OPEN", 829 },
    close = { "IG_SPELLBOOK_CLOSE", 830 },
    button = { "IG_ABILITY_PAGE_TURN", 836 },
    page = { "IG_ABILITY_PAGE_TURN", 836 },
}

function UI:PlayJournalSound(kind)
    local cue = JOURNAL_SOUNDS[kind]
    if not cue then return false, "unknown cue" end

    local id = (SOUNDKIT and SOUNDKIT[cue[1]]) or cue[2]
    local failure = "sound API unavailable"
    local function TryPlay(play, api)
        local ok, willPlay = pcall(play, id, "Master")
        if ok and willPlay ~= false then
            return true, api, id
        end
        failure = ok and "client rejected sound kit" or tostring(willPlay)
    end

    -- Forever's UI uses the modern sound namespace; keep the global for
    -- clients where it is still the only available entry point.
    local modern = C_Sound and C_Sound.PlaySound
    if type(modern) == "function" then
        local played, api, soundID = TryPlay(modern, "C_Sound.PlaySound")
        if played then return played, api, soundID end
    end
    if type(PlaySound) == "function" and PlaySound ~= modern then
        local played, api, soundID = TryPlay(PlaySound, "PlaySound")
        if played then return played, api, soundID end
    end
    return false, failure, id
end

frame:SetScript("OnShow", function() UI:PlayJournalSound("open") end)
frame:SetScript("OnHide", function() UI:PlayJournalSound("close") end)

-- =========================
-- CLOSE BUTTON
-- =========================
frame.closeBtn = CreateFrame("Button", nil, frame)
frame.closeBtn:SetSize(24, 24)
frame.closeBtn:SetPoint("TOPRIGHT", -6, -6)
frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.closeBtn.text:SetAllPoints()
frame.closeBtn.text:SetText("X")
frame.closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

-- =========================
-- TITLE
-- =========================
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.title:SetText("Field Journal")
frame.title:SetFont("Fonts\\MORPHEUS.ttf", 20, "")
frame.title:SetTextColor(1.0, 0.82, 0.0, 1)

-- =========================
-- BACK BUTTON
-- =========================
frame.backBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.backBtn:SetSize(70, 20)
frame.backBtn:SetPoint("TOPLEFT", 12, -10)
frame.backBtn:SetText("Back")
frame.backBtn:Hide()

-- =========================
-- HELPERS
-- =========================
local function FormatName(id)
    if not id then return "Unknown" end

    local name = tostring(id):gsub("_", " ")

    return (name:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function GetSubjectDisplayName(subjectID)
    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    return (entry and entry.displayName) or FormatName(subjectID)
end
local function PlayJournalPageSound()
    UI:PlayJournalSound("page")
end

local function PlayJournalButtonSound()
    UI:PlayJournalSound("button")
end

local function GetDB()
    FieldJournalDB = FieldJournalDB or {}
    FieldJournalDB.subjects = FieldJournalDB.subjects or {}
    FieldJournalDB.zones = FieldJournalDB.zones or {}
    FieldJournalDB.encounters = FieldJournalDB.encounters or {}
    FieldJournalDB.completedQuests = FieldJournalDB.completedQuests or {}
    return FieldJournalDB
end

local function GetSubjectProgress(subject)
    if not subject then
        return 0
    end

    local level = subject.observationLevel or 0
    return math.min(level / 5, 1)
end

local function GetLore(subjectID, tier)
    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    return entry and entry.lore and entry.lore[tier]
end

local function GetSubjectIcon(subjectID)
    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]

    if entry and entry.icon then
        return entry.icon
    end

    return "Interface\\Icons\\INV_Misc_Book_09"
end

-- =========================
-- SUBJECT / ZONE HELPERS
-- =========================
local function SubjectBelongsToZone(subjectID, zoneName)
    local entry = FieldJournal_LoreDB and FieldJournal_LoreDB[subjectID]
    if not entry then
        return false
    end

    if entry.zones then
        for _, listedZone in ipairs(entry.zones) do
            if listedZone == zoneName then
                return true
            end
        end

        return false
    end

    -- Current fallback:
    -- All currently defined subject groups are treated as Dun Morogh groups
    -- unless a future LoreDB entry specifies zones = { ... }.
    if zoneName == "Dun Morogh" then
        return true
    end

    return false
end

local function GetDefinedSubjectsForZone(zoneName)
    local subjects = {}

    if not FieldJournal_LoreDB then
        return subjects
    end

    for subjectID in pairs(FieldJournal_LoreDB) do
        if SubjectBelongsToZone(subjectID, zoneName) then
            table.insert(subjects, subjectID)
        end
    end

    table.sort(subjects, function(a, b)
        return GetSubjectDisplayName(a) < GetSubjectDisplayName(b)
    end)

    return subjects
end

local function IsSubjectObservedInZone(subject, zoneName)
    return subject
        and subject.knownZones
        and subject.knownZones[zoneName]
end

local function GetZoneProgress(zoneName, db)
    local definedSubjects = GetDefinedSubjectsForZone(zoneName)

    if #definedSubjects > 0 then
        local total = 0

        for _, subjectID in ipairs(definedSubjects) do
            local subject = db.subjects[subjectID]

            if IsSubjectObservedInZone(subject, zoneName) then
                total = total + GetSubjectProgress(subject)
            end
        end

        return total / #definedSubjects
    end

    local total = 0
    local count = 0

    for _, subject in pairs(db.subjects) do
        if IsSubjectObservedInZone(subject, zoneName) then
            total = total + GetSubjectProgress(subject)
            count = count + 1
        end
    end

    if count == 0 then
        return 0
    end

    return total / count
end

-- =========================
-- SUBREGION HELPERS
-- =========================
local function GetDefinedSubregionsForZone(zoneName)
    if FieldJournal.ZoneSystem and FieldJournal.ZoneSystem.GetDefinedSubregions then
        return FieldJournal.ZoneSystem:GetDefinedSubregions(zoneName)
    end

    local zoneDef = FieldJournal_ZoneDB and FieldJournal_ZoneDB[zoneName]
    return (zoneDef and zoneDef.subregions) or {}
end

local function IsSubregionDiscovered(zoneName, subregionName)
    local db = GetDB()
    local zone = db.zones and db.zones[zoneName]

    return zone
        and zone.discoveredSubregions
        and zone.discoveredSubregions[subregionName]
end

local function BuildKnownSubregionPages(zoneName)
    local subregions = GetDefinedSubregionsForZone(zoneName)

    if #subregions == 0 then
        return "|cffffd100Known Subregions:|r\n\n",
            { "|cff8a6a55No subregion records exist for this zone yet.|r\n\n" }
    end

    local discovered = {}

    for _, data in ipairs(subregions) do
        if IsSubregionDiscovered(zoneName, data.name) then
            table.insert(discovered, data)
        end
    end

    table.sort(discovered, function(a, b)
        return a.name < b.name
    end)

    local header = "|cffffd100Known Subregions:|r\n"
        .. "|cff8a6a55Discovered: " .. tostring(#discovered) .. "/" .. tostring(#subregions) .. "|r\n\n"

    if #discovered == 0 then
        return header, { "|c88888888No subregions discovered yet.|r\n\n" }
    end

    local entries = {}
    for _, data in ipairs(discovered) do
        entries[#entries + 1] = "|cffffd100" .. data.name .. "|r\n"
            .. "|cff8a6a55" .. (data.description or "No field note recorded.") .. "|r\n\n"
    end
    return header, entries
end

local function BuildKnownSubregionText(zoneName)
    local header, entries = BuildKnownSubregionPages(zoneName)
    return header .. table.concat(entries)
end

-- =========================
-- QUEST / ADVENTURE HELPERS
-- =========================
local function FormatQuestTimestamp(record)
    if not record or not record.completedAt then
        return "an unknown time"
    end

    -- completedAt format from QuestSystem:
    -- YYYY-MM-DD HH:MM:SS
    local year, month, day, hour, minute = string.match(
        record.completedAt,
        "^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)"
    )

    if not year then
        return record.completedAt
    end

    local hourNumber = tonumber(hour) or 0
    local suffix = "AM"
    local displayHour = hourNumber

    if hourNumber == 0 then
        displayHour = 12
        suffix = "AM"
    elseif hourNumber == 12 then
        displayHour = 12
        suffix = "PM"
    elseif hourNumber > 12 then
        displayHour = hourNumber - 12
        suffix = "PM"
    end

    return month .. "/" .. day .. "/" .. year .. ", " .. tostring(displayHour) .. ":" .. minute .. " " .. suffix
end

local function GetCompletedQuestEntriesForZone(zoneName)
    local db = GetDB()
    local entries = {}

    if not FieldJournal_QuestDB then
        return entries
    end

    for questID, record in pairs(db.completedQuests) do
        local questDef = FieldJournal_QuestDB[questID]

        if questDef and questDef.zone == zoneName then
            table.insert(entries, {
                questID = questID,
                record = record,
                definition = questDef,
            })
        end
    end

    -- Earliest completed quests first, so the journal reads like a timeline.
    table.sort(entries, function(a, b)
        local aTime = a.record.completedAt or ""
        local bTime = b.record.completedAt or ""
        return aTime < bTime
    end)

    return entries
end

local function BuildAdventureText(zoneName)
    local entries = GetCompletedQuestEntriesForZone(zoneName)

    local text = "\n|cffffd100ADVENTURES IN " .. string.upper(zoneName) .. "|r\n\n"

    if #entries == 0 then
        text = text .. "|c88888888No adventures recorded here yet.|r\n\n"
        return text
    end

    for _, data in ipairs(entries) do
        local record = data.record
        local questDef = data.definition

        local levelText = tostring(record.playerLevel or "?")
        local timeText = FormatQuestTimestamp(record)
        local questTitle = questDef.title or ("Quest " .. tostring(data.questID))
        local summary = questDef.summary or "No field account recorded."

        text = text .. "|cffffd100" .. questTitle .. "|r\n"
        text = text .. "|cff8a6a55Level " .. levelText .. ", " .. timeText .. " - " .. summary .. "|r\n\n"
    end

    return text
end

local function BuildZonePageText(zoneName)
    local text = ""

    text = text .. BuildKnownSubregionText(zoneName)
    text = text .. "\n"
    text = text .. BuildAdventureText(zoneName)

    return text
end

-- =========================
-- CHRONICLE HELPERS
-- =========================
local function BuildChroniclePageText()
    if not FieldJournal.ChronicleSystem then
        return "|c88888888Chronicle records are unavailable.|r"
    end

    local chronicle = FieldJournal.ChronicleSystem:GetChronicle()
    local entries = FieldJournal.ChronicleSystem:GetSortedChronicleEntries()
    local text = ""

    if chronicle.startedLevel and chronicle.startedLevel > 1 then
        text = text .. "|cffffd100Earlier Travels|r\n"
        text = text .. "|cff8a6a55The earliest chapters of this journey were traveled before I began keeping proper milestone records. My Chronicle begins from Level "
            .. tostring(chronicle.startedLevel) .. ".|r\n\n"
    elseif chronicle.startedAt then
        text = text .. "|cff8a6a55These pages record the moments when experience became growth and where the journey was interrupted.|r\n\n"
    end

    if #entries == 0 then
        text = text .. "|c88888888No Chronicle entries have been recorded yet. Level milestones and deaths will be written here as they occur.|r\n"
        return text
    end

    for _, entry in ipairs(entries) do
        if entry.entryType == "level" then
            local milestone = entry.data
            local level = milestone.level or "?"
            local location = FieldJournal.ChronicleSystem:FormatLocation(milestone.location)
            local reachedAt = FieldJournal.ChronicleSystem:FormatReachedAt(milestone.reachedAt)
            local narrative = FieldJournal.ChronicleSystem:GetMilestoneNarrative(milestone)

            text = text .. "|cffffd100LEVEL " .. tostring(level) .. "|r\n"
            text = text .. "|cffffffff" .. location .. "|r\n"
            text = text .. "|cff8a6a55" .. reachedAt .. "|r\n\n"
            text = text .. "|cff8a6a55" .. narrative .. "|r\n\n"

        elseif entry.entryType == "nearDeath" then
            local incident = entry.data
            local title = FieldJournal.ChronicleSystem:GetNearDeathTitle(incident)
            local location = FieldJournal.ChronicleSystem:FormatLocation(incident.location)
            local occurredAt = FieldJournal.ChronicleSystem:FormatReachedAt(incident.occurredAt)
            local narrative = FieldJournal.ChronicleSystem:GetNearDeathNarrative(incident)
            local threat = incident.attackerName or "Unknown danger"

            text = text .. "|cffff6b6bNEAR-DEATH - " .. string.upper(title) .. "|r\n"
            text = text .. "|cffffffff" .. location .. "|r\n"
            text = text .. "|cff8a6a55" .. occurredAt .. "|r\n"
            text = text .. "|cff8a6a55Level " .. tostring(incident.level or "?") .. " - Threat: " .. threat .. "|r\n\n"
            text = text .. "|cff8a6a55" .. narrative .. "|r\n\n"
        elseif entry.entryType == "death" then
            local death = entry.data
            local location = FieldJournal.ChronicleSystem:FormatLocation(death.location)
            local occurredAt = FieldJournal.ChronicleSystem:FormatReachedAt(death.occurredAt)
            text = text .. "|cffff6b6bDEATH|r\n"
            text = text .. "|cffffffff" .. location .. "|r\n"
            text = text .. "|cff8a6a55" .. occurredAt .. "|r\n"
            text = text .. "|cff8a6a55Level " .. tostring(death.level or "?") .. "|r\n"
            if death.killerName and death.killerName ~= "" then
                text = text .. "|cffff6b6bDied to: " .. death.killerName
                    .. (death.killerClass and (" (" .. death.killerClass .. ")") or "") .. "|r\n"
            end
            text = text .. "\n"
        end

        text = text .. "|cff8a6a55--------------------------------|r\n\n"
    end

    return text
end

-- =========================
-- UI STATE
-- =========================
frame.state = {
    mode = "landing",
    zone = nil,
    subject = nil,
}

-- =========================
-- LEFT PANEL
-- =========================
frame.left = CreateFrame("Frame", nil, frame)
frame.left:SetSize(360, 420)
frame.left:SetPoint("LEFT", 92, 0)
frame.left:SetPoint("TOP", 0, -65)

frame.leftHeader = frame.left:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.leftHeader:SetPoint("TOP", frame.left, "TOP", 0, -18)
frame.leftHeader:SetWidth(330)
frame.leftHeader:SetJustifyH("CENTER")
frame.leftHeader:SetText("Journal")
frame.leftHeader:SetFont("Fonts\\MORPHEUS.ttf", 16, "")
frame.leftHeader:SetTextColor(1.0, 0.82, 0.0, 1)

frame.landingGuide = frame.left:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.landingGuide:SetPoint("TOPLEFT", frame.left, "TOPLEFT", 12, -68)
frame.landingGuide:SetWidth(330)
frame.landingGuide:SetJustifyH("LEFT")
frame.landingGuide:SetJustifyV("TOP")
frame.landingGuide:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
frame.landingGuide:SetTextColor(0.29, 0.19, 0.12, 1)
frame.landingGuide:Hide()

frame.landingGuidePages = {
    {
        title = "Getting Started",
        text = "Field Journal keeps a personal record as you explore. Open it with |cffffd100/fj|r or click the minimap book button. Drag that button to move it; you can drag the journal window too.\n\n"
            .. "Choose |cffffd100Field Notes|r or |cffffd100Chronicle|r in the top bar. Use Back to retrace your views; arrows turn through longer pages.\n\n"
            .. "Your records save for this character through reloads and logouts. Use |cffffd100/fj scale X|r, where X is a number from 0.8 to 1.6, to adjust the window.",
    },
    {
        title = "Field Notes",
        text = "Field Notes organizes creature discoveries by zone. Choose a known zone in the left-page grid; its right page lists the subregions you have discovered. Visit supported areas to add their notes.\n\n"
            .. "Choose a subject from the left page to see its lore and Knowledge Level (1-5), plus kill and observation counts. Creature lore is researched from the WoW wiki and saved in the addon; the game does not fetch wiki pages while you play. After the lore pages, each known creature has its own model page with separate counts.\n\n"
            .. "Unseen subjects appear as |cffffd100Not Yet Observed|r. The arrows on either page let you move through a long list or entry.",
    },
    {
        title = "Observing Creatures",
        text = "Target a living hostile creature covered by the journal. An |cffffd100Observe|r button appears beside its target frame. Click it to begin a 12-second field study.\n\n"
            .. "Wait for a tool to glow, then click that tool quickly. Changing targets, entering combat, or choosing the wrong tool interrupts the study.\n\n"
            .. "A successful study or a credited kill records the subject. Its first discovery unlocks Knowledge Level 1; later pieces of its saved lore can unlock by chance, up to Level 5. The lore is about that creature, while the counts and habitats come from your own adventures.\n\n"
            .. "For keyboard or gamepad play, bind Observe and the three tools under Key Bindings > AddOns > Field Journal.",
    },
    {
        title = "Chronicle",
        text = "Chronicle records completed quests, level milestones, and deaths as your character's story. A death may name its cause when the game provides a reliable source.\n\n"
            .. "The Roman numerals across the top choose level-based chapters; Chapter VII is |cffffd100Forever|r. The left page holds appearances saved at chapter milestones. The right page shows the entries, with arrows for more pages.\n\n"
            .. "On first use, a current appearance can fill a missing starting portrait. Use |cffffd100/fj snapshot|r to preview your current look without recording a new milestone.",
    },
}
frame.landingGuidePage = 1

frame.landingGuidePageLabel = frame.left:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.landingGuidePageLabel:SetPoint("BOTTOM", frame.left, "BOTTOM", 0, 5)
frame.landingGuidePageLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
frame.landingGuidePageLabel:Hide()

local function MakeGuideArrow(direction, xOffset, delta)
    local button = CreateFrame("Button", nil, frame.left)
    button:SetSize(28, 28)
    button:SetPoint("BOTTOM", frame.left, "BOTTOM", xOffset, -3)
    local texture = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
    button:SetNormalTexture(texture .. "Up")
    button:SetPushedTexture(texture .. "Down")
    button:SetDisabledTexture(texture .. "Disabled")
    button:SetScript("OnClick", function()
        frame:ShowLandingGuidePage(frame.landingGuidePage + delta)
        PlayJournalPageSound()
    end)
    button:Hide()
    return button
end
frame.landingGuidePrevious = MakeGuideArrow("Prev", -60, -1)
frame.landingGuideNext = MakeGuideArrow("Next", 60, 1)

function frame:ShowLandingGuidePage(index)
    local count = #self.landingGuidePages
    self.landingGuidePage = math.max(1, math.min(index, count))
    local page = self.landingGuidePages[self.landingGuidePage]
    self.leftHeader:SetFont("Fonts\\MORPHEUS.ttf", 22, "")
    self.leftHeader:SetText(page.title)
    self.landingGuide:SetText(page.text)
    self.landingGuidePageLabel:SetText("Guide " .. self.landingGuidePage .. "/" .. count)
    self.landingGuidePrevious:SetEnabled(self.landingGuidePage > 1)
    self.landingGuideNext:SetEnabled(self.landingGuidePage < count)
    self.landingGuide:Show()
    self.landingGuidePageLabel:Show()
    self.landingGuidePrevious:Show()
    self.landingGuideNext:Show()
end

function frame:HideLandingGuide()
    self.leftHeader:SetFont("Fonts\\MORPHEUS.ttf", 16, "")
    self.landingGuide:Hide()
    self.landingGuidePageLabel:Hide()
    self.landingGuidePrevious:Hide()
    self.landingGuideNext:Hide()
end

frame.buttons = {}

local function CreateButton(i)
    local b = CreateFrame("Button", nil, frame.left, "UIPanelButtonTemplate")
    b:SetSize(166, 23)
    return b
end

local function SetButtonEnabledStyle(button, enabled)
    local fontString = button:GetFontString()

    if enabled then
        button:Enable()
        if fontString then
            fontString:SetTextColor(1.0, 0.82, 0.0, 1)
        end
    else
        button:Disable()
        if fontString then
            fontString:SetTextColor(0.45, 0.45, 0.45, 1)
        end
    end
end

function frame:HideAllButtons()
    for _, btn in ipairs(self.buttons) do
        btn:Hide()
        btn:SetScript("OnClick", nil)
    end
end

-- Permanent section tabs in the spellbook's top strip.
frame.navButtons = {}

-- The client draws the Game Menu's red face through the button template, but
-- its warm outer trim is separate. Add that trim to the journal's top tabs.
function UI:AddGoldMenuTrim(button)
    if button.goldMenuTrim then return end
    local trim = CreateFrame("Frame", nil, button, "BackdropTemplate")
    trim:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    trim:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    trim:SetFrameLevel(button:GetFrameLevel() + 1)
    trim:EnableMouse(false)
    trim:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    trim:SetBackdropBorderColor(0.95, 0.73, 0.30, 1)
    button.goldMenuTrim = trim
end

local function CreateNavButton(label, xOffset)
    local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    button:SetSize(130, 30)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -8)
    button:SetText(label)
    UI:AddGoldMenuTrim(button)
    return button
end

frame.navButtons.zones = CreateNavButton("Field Notes", 102)
frame.navButtons.chronicle = CreateNavButton("Chronicle", 240)

function frame:SetActiveSection(section)
    for key, button in pairs(self.navButtons) do
        local selected = key == section
        button:SetAlpha(selected and 1 or .82)
    end
end

function frame:ShowNavigationButtons()
    self.navButtons.zones:Show()
    self.navButtons.chronicle:Show()
end

function frame:HideNavigationButtons()
    -- Section tabs remain available on every journal page.
    self:ShowNavigationButtons()
end

frame.grid = { page = 1, key = nil, entries = {}, pageByKey = {} }
frame.grid.label = frame.left:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.grid.label:SetPoint("BOTTOM", frame.left, "BOTTOM", 0, 4)
frame.grid.label:Hide()

local function MakeGridArrow(direction, xOffset, delta)
    local button = CreateFrame("Button", nil, frame.left)
    button:SetSize(28, 28)
    button:SetPoint("BOTTOM", frame.left, "BOTTOM", xOffset, -3)
    local texture = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
    button:SetNormalTexture(texture .. "Up")
    button:SetPushedTexture(texture .. "Down")
    button:SetDisabledTexture(texture .. "Disabled")
    button:SetScript("OnClick", function()
        frame.grid.page = frame.grid.page + delta
        frame:RenderGrid()
        PlayJournalPageSound()
    end)
    button:Hide()
    return button
end
frame.grid.previous = MakeGridArrow("Prev", -56, -1)
frame.grid.next = MakeGridArrow("Next", 56, 1)

function frame:HideGrid()
    self:HideAllButtons()
    self.grid.label:Hide()
    self.grid.previous:Hide()
    self.grid.next:Hide()
end

function frame:RenderGrid()
    self:HideAllButtons()
    local grid = self.grid
    local subjectGrid = type(grid.key) == "string" and grid.key:match("^subjects:") ~= nil
    local perPage = subjectGrid and 18 or 22 -- Three-line subject heading needs more room.
    local count = math.max(1, math.ceil(#grid.entries / perPage))
    grid.page = math.max(1, math.min(grid.page, count))
    grid.pageByKey[grid.key] = grid.page
    local first = (grid.page - 1) * perPage + 1
    local visible = math.min(perPage, #grid.entries - first + 1)
    local rows = math.ceil(visible / 2)
    local firstY = subjectGrid
        and (-105 - math.max(0, math.floor((9 - rows) * 13)))
        or (-67 - math.max(0, math.floor((11 - rows) * 12)))

    for slot = 1, visible do
        local item = grid.entries[first + slot - 1]
        if not self.buttons[slot] then self.buttons[slot] = CreateButton(slot) end
        local button = self.buttons[slot]
        local column = (slot - 1) % 2
        local row = math.floor((slot - 1) / 2)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.left, "TOPLEFT", 10 + column * 174, firstY - row * 27)
        button:SetText(item.label)
        SetButtonEnabledStyle(button, item.enabled)
        button:SetScript("OnClick", item.onClick)
        button:Show()
    end

    grid.label:SetText("Page " .. grid.page .. "/" .. count)
    grid.previous:SetEnabled(grid.page > 1)
    grid.next:SetEnabled(grid.page < count)
    grid.label:SetShown(count > 1)
    grid.previous:SetShown(count > 1)
    grid.next:SetShown(count > 1)
end

function frame:ShowGrid(key, entries)
    self.grid.page = self.grid.key == key and self.grid.page
        or (self.grid.pageByKey[key] or 1)
    self.grid.key = key
    self.grid.entries = entries
    self:RenderGrid()
end

-- =========================
-- RIGHT PAGE VIEWPORT
-- =========================
frame.right = CreateFrame("Frame", nil, frame)
frame.right:SetSize(360, 420)
frame.right:SetPoint("RIGHT", -90, 0)
frame.right:SetPoint("TOP", 0, -55)

frame.scrollFrame = CreateFrame("ScrollFrame", "FieldJournalJournalScrollFrame", frame.right)
frame.scrollFrame:EnableMouseWheel(false)
frame.scrollFrame:SetPoint("TOPLEFT", frame.right, "TOPLEFT", 0, -4)
frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame.right, "BOTTOMRIGHT", -26, 4)

frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
frame.scrollChild:SetSize(330, 800)
frame.scrollFrame:SetScrollChild(frame.scrollChild)

-- Separate subject title so it can have its own font, size, and color.
frame.subjectTitle = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.subjectTitle:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, 0)
frame.subjectTitle:SetWidth(320)
frame.subjectTitle:SetJustifyH("LEFT")
frame.subjectTitle:SetFont("Fonts\\MORPHEUS.ttf", 18, "")
frame.subjectTitle:SetTextColor(1.0, 0.82, 0.0, 1)
frame.subjectTitle:Hide()

frame.right.text = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.right.text:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, 0)
frame.right.text:SetWidth(320)
frame.right.text:SetJustifyH("LEFT")
frame.right.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

-- =========================
-- TEXT STYLE RESET HELPERS
-- =========================
function frame:UseNormalRightText()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, 0)
    self.right.text:SetWidth(320)
    self.right.text:SetJustifyH("LEFT")

    -- Explicitly restore the normal journal/body font.
    -- Do not rely on SetFontObject here because SetFont() from the landing page can persist.
    self.right.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    self.right.text:SetTextColor(1, 1, 1, 1)
end

function frame:UseLandingRightText()
    self.right.text:ClearAllPoints()

    self.right.text:SetPoint("CENTER", self.scrollFrame, "CENTER", -10, 20)

    self.right.text:SetWidth(320)
    self.right.text:SetJustifyH("CENTER")

    -- Landing page only.
    self.right.text:SetFont("Fonts\\MORPHEUS.ttf", 42, "")
    self.right.text:SetTextColor(1.0, 0.82, 0.0, 1)
end

-- One creature per page after the subject lore. The viewer is separate from
-- the text FontString so the 3D model is never treated as a paginated line.
frame.creatureViewer = CreateFrame("Frame", nil, frame.right)
frame.creatureViewer:SetSize(320, 320)
frame.creatureViewer:SetPoint("TOP", frame.subjectTitle, "BOTTOM", 0, -18)
frame.creatureViewer.model = CreateFrame("PlayerModel", nil, frame.creatureViewer)
frame.creatureViewer.model:SetSize(300, 270)
frame.creatureViewer.model:SetPoint("TOP", frame.creatureViewer, "TOP", 0, 0)
frame.creatureViewer.icon = frame.creatureViewer:CreateTexture(nil, "ARTWORK")
frame.creatureViewer.icon:SetSize(96, 96)
frame.creatureViewer.icon:SetPoint("CENTER", frame.creatureViewer.model, "CENTER")
frame.creatureViewer.icon:Hide()
frame.creatureViewer.counts = frame.creatureViewer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.creatureViewer.counts:SetPoint("TOP", frame.creatureViewer.model, "BOTTOM", 0, -4)
frame.creatureViewer.counts:SetWidth(300)
frame.creatureViewer.counts:SetJustifyH("CENTER")
frame.creatureViewer.counts:SetTextColor(0.54, 0.42, 0.33, 1)
frame.creatureViewer:Hide()

function frame:ShowCreaturePage(creature)
    self.creatureViewer:Hide()
    if self.state.mode ~= "lore" then return end

    self.subjectTitle:SetText(creature and creature.name
        or GetSubjectDisplayName(self.state.subject))
    if not creature then return end

    local viewer = self.creatureViewer
    local model = viewer.model
    local npcID = tonumber(creature.npcID)
    local displayID = tonumber(creature.displayID)
    if model.ClearModel then model:ClearModel() end
    local shown = false
    -- SetCreature is also used by the existing appearance backfill to resolve
    -- a representative model from an NPC ID on this client.
    if npcID and model.SetCreature then
        shown = pcall(model.SetCreature, model, npcID)
    end
    if not shown and displayID and model.SetDisplayInfo then
        shown = pcall(model.SetDisplayInfo, model, displayID)
    end
    model:SetShown(shown)
    viewer.icon:SetShown(not shown)
    if not shown then viewer.icon:SetTexture(GetSubjectIcon(self.state.subject)) end
    if shown then
        if model.SetPortraitZoom then model:SetPortraitZoom(0) end
        if model.SetCamDistanceScale then model:SetCamDistanceScale(1.25) end
        if model.SetRotation then
            model:SetRotation(math.rad(15))
        elseif model.SetFacing then
            model:SetFacing(math.rad(15))
        end
    end
    viewer.counts:SetText("Kills: " .. tostring(creature.killCount or 0)
        .. "\nObservations: " .. tostring(creature.observationCount or 0))
    viewer:Show()
end

-- =========================
-- KNOWN CREATURE ICON ROWS
-- =========================
frame.creatureRows = {}

local function CreateCreatureRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(320, 54)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(38, 38)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetWidth(260)
    row.name:SetJustifyH("LEFT")

    row.kills = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.kills:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.kills:SetWidth(260)
    row.kills:SetJustifyH("LEFT")

    row.observations = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.observations:SetPoint("TOPLEFT", row.kills, "BOTTOMLEFT", 0, -2)
    row.observations:SetWidth(260)
    row.observations:SetJustifyH("LEFT")

    return row
end

function frame:HideCreatureRows()
    for _, row in ipairs(self.creatureRows) do
        row:Hide()
    end
end

function frame:GetEncountersForSubject(subjectID)
    local db = GetDB()
    local results = {}

    for npcID, encounter in pairs(db.encounters) do
        local subjectData = encounter.subjectData and encounter.subjectData[subjectID]
        if subjectData or (not encounter.subjectData and encounter.subjectID == subjectID) then
            table.insert(results, {
                npcID = npcID,
                encounter = subjectData and {
                    name = encounter.name,
                    killCount = subjectData.killCount,
                    observationCount = subjectData.observationCount,
                    knownHabitats = subjectData.knownHabitats,
                    appearanceDisplayID = encounter.appearanceDisplayID,
                } or encounter,
            })
        end
    end

    table.sort(results, function(a, b)
        local aName = a.encounter.name or ""
        local bName = b.encounter.name or ""
        return aName < bName
    end)

    return results
end

function frame:ShowKnownCreatures(subjectID, startY)
    self:HideCreatureRows()

    local encounters = self:GetEncountersForSubject(subjectID)
    local iconPath = GetSubjectIcon(subjectID)

    if #encounters == 0 then
        return 0
    end

    for i, data in ipairs(encounters) do
        if not self.creatureRows[i] then
            self.creatureRows[i] = CreateCreatureRow(self.scrollChild, i)
        end

        local row = self.creatureRows[i]
        local encounter = data.encounter
        local npcID = data.npcID

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, startY - ((i - 1) * 58))

        row.icon:SetTexture(iconPath)

        row.name:SetText(encounter.name or "Unknown Creature")
        row.kills:SetText("Kills: " .. tostring(encounter.killCount or 0))
        row.observations:SetText("Observations: " .. tostring(encounter.observationCount or 0))

        row:Show()
    end

    return #encounters
end

function frame:ResizeScrollContent(extraHeight)
    local titleHeight = 0

    if self.subjectTitle and self.subjectTitle:IsShown() then
        titleHeight = (self.subjectTitle:GetStringHeight() or 0) + 14
    end

    local textHeight = self.right.text:GetStringHeight() or 0
    local height = math.max(400, titleHeight + textHeight + (extraHeight or 0) + 40)

    self.scrollChild:SetHeight(height)
    self.scrollFrame:SetVerticalScroll(0)
end

function frame:ResetSubjectTitle()
    self.subjectTitle:SetText("")
    self.subjectTitle:SetFont("Fonts\\MORPHEUS.ttf", 18, "")
    self.subjectTitle:SetJustifyH("LEFT")
    self.subjectTitle:Hide()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, 0)
end

-- =========================
-- SHOW LANDING PAGE
-- =========================
function frame:ShowLanding()
    if UI.Pagination then UI.Pagination:Clear(self) end
    self.state.mode = "landing"
    self.state.zone = nil
    self.state.subject = nil

    self.title:Show()
    self:ShowLandingGuidePage(1)
    self:SetActiveSection(nil)

    self.backBtn:Hide()
    self:ShowNavigationButtons()
    self:HideGrid()
    self:HideCreatureRows()
    self:ResetSubjectTitle()
    self:UseLandingRightText()

    local characterName = UnitName("player") or "Adventurer"
    self.right.text:SetText("|cffffd100" .. characterName .. "'s Field Journal|r")
    self:ResizeScrollContent(0)
end

-- =========================
-- SHOW ZONES
-- =========================
function frame:ShowZones()
    if UI.Pagination then UI.Pagination:Clear(self) end
    self:HideLandingGuide()
    local db = GetDB()

    self.state.mode = "zones"
    self.state.zone = nil
    self.state.subject = nil

    self.title:Show()
    self.title:SetText("Field Journal")
    self.leftHeader:SetFont("Fonts\\MORPHEUS.ttf", 22, "")
    self.leftHeader:SetText("Field Notes")
    self:SetActiveSection("zones")

    self.backBtn:Show()
    self:HideNavigationButtons()
    self:HideGrid()
    self:HideCreatureRows()
    self:ResetSubjectTitle()
    self:UseNormalRightText()

    self.subjectTitle:SetText("Known Zones")
    self.subjectTitle:Show()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.subjectTitle, "BOTTOMLEFT", 0, -12)
    self.right.text:SetText("|cff8a6a55Select a discovered zone from the left to review its field notes, subjects, and adventures.|r")

    local zoneNames = {}
    for zoneName in pairs(db.zones) do
        table.insert(zoneNames, zoneName)
    end

    table.sort(zoneNames, function(a, b)
        local aData = db.zones[a]
        local bData = db.zones[b]
        return (aData and aData.name or a) < (bData and bData.name or b)
    end)

    local gridEntries = {}
    for _, zoneName in ipairs(zoneNames) do
        local zoneData = db.zones[zoneName]
        local progress = GetZoneProgress(zoneName, db) * 100
        gridEntries[#gridEntries + 1] = {
            label = (zoneData.name or zoneName) .. string.format(" (%.0f%%)", progress),
            enabled = true,
            onClick = function()
                PlayJournalButtonSound()
                frame:ShowZone(zoneName)
            end,
        }
    end
    self:ShowGrid("zones", gridEntries)

    self:ResizeScrollContent(0)
end

-- =========================
-- SHOW CHRONICLE
-- =========================
function frame:ShowChronicle()
    if UI.Pagination then UI.Pagination:Clear(self) end
    self:HideLandingGuide()
    self.state.mode = "chronicle"
    self.state.zone = nil
    self.state.subject = nil

    self.title:Show()
    self.title:SetText("Field Journal")
    self.leftHeader:SetText("Chronicle")
    self:SetActiveSection("chronicle")

    self.backBtn:Show()
    self:HideNavigationButtons()
    self:HideGrid()
    self:HideCreatureRows()
    self:ResetSubjectTitle()

    local characterName = UnitName("player") or "Adventurer"
    self.subjectTitle:SetText(characterName .. "'s Chronicle")
    self.subjectTitle:Show()

    self:UseNormalRightText()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.subjectTitle, "BOTTOMLEFT", 0, -12)
    self.right.text:SetText(BuildChroniclePageText())

    self:ResizeScrollContent(0)
end

-- =========================
-- SHOW SUBJECTS IN ZONE
-- =========================
function frame:SetSubjectsHeader(zoneName)
    local db = GetDB()
    local zone = zoneName and db.zones[zoneName]
    self.leftHeader:SetFont("Fonts\\MORPHEUS.ttf", 22, "")
    self.leftHeader:SetText("Subjects\nof\n" .. ((zone and zone.name) or zoneName or "Unknown Zone"))
end

function frame:ShowZone(zoneName)
    self:HideLandingGuide()
    local db = GetDB()

    self.state.mode = "subjects"
    self.state.zone = zoneName
    self.state.subject = nil

    self.title:Show()
    self.title:SetText("Field Journal")

    self:SetSubjectsHeader(zoneName)
    self:SetActiveSection("zones")

    self.backBtn:Show()
    self:HideNavigationButtons()
    self:ResetSubjectTitle()
    self:UseNormalRightText()
    self:HideGrid()
    self:HideCreatureRows()
    local zone = db.zones[zoneName]
    self.subjectTitle:SetFont("Fonts\\MORPHEUS.ttf", 24, "")
    self.subjectTitle:SetText((zone and zone.name) or zoneName)
    self.subjectTitle:Show()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.subjectTitle, "BOTTOMLEFT", 0, -10)
    local header, entries = BuildKnownSubregionPages(zoneName)
    if UI.Pagination then
        UI.Pagination:Show(self, "zone:" .. zoneName, header, entries)
    else
        self.right.text:SetText(BuildZonePageText(zoneName))
        self:ResizeScrollContent(0)
    end

    local observedSubjects = {}
    local unobservedSubjects = {}
    local definedSubjects = GetDefinedSubjectsForZone(zoneName)

    if #definedSubjects > 0 then
        for _, subjectID in ipairs(definedSubjects) do
            local subject = db.subjects[subjectID]
            local observed = IsSubjectObservedInZone(subject, zoneName)

            if observed then
                table.insert(observedSubjects, subjectID)
            else
                table.insert(unobservedSubjects, subjectID)
            end
        end
    else
        for subjectID, subject in pairs(db.subjects) do
            if IsSubjectObservedInZone(subject, zoneName) then
                table.insert(observedSubjects, subjectID)
            end
        end
    end

    table.sort(observedSubjects, function(a, b)
        return GetSubjectDisplayName(a) < GetSubjectDisplayName(b)
    end)

    table.sort(unobservedSubjects, function(a, b)
        return GetSubjectDisplayName(a) < GetSubjectDisplayName(b)
    end)

    local gridEntries = {}

    for _, subjectID in ipairs(observedSubjects) do
        local subject = db.subjects[subjectID]
        local progress = GetSubjectProgress(subject) * 100
        gridEntries[#gridEntries + 1] = {
            label = GetSubjectDisplayName(subjectID) .. string.format(" (%.0f%%)", progress),
            enabled = true,
            onClick = function()
                PlayJournalButtonSound()
                frame:ShowSubject(subjectID)
            end,
        }
    end

    for _ in ipairs(unobservedSubjects) do
        gridEntries[#gridEntries + 1] = { label = "Not Yet Observed", enabled = false }
    end
    self:ShowGrid("subjects:" .. zoneName, gridEntries)
end

-- =========================
-- SHOW SUBJECT DETAIL
-- =========================
function frame:ShowSubject(subjectID)
    local db = GetDB()
    local subject = db.subjects[subjectID]
    if not subject then return end
    self:HideLandingGuide()

    self.state.mode = "lore"
    self.state.subject = subjectID

    self.title:Show()
    self.title:SetText("Field Journal")

    self:SetSubjectsHeader(self.state.zone)
    self:SetActiveSection("zones")

    self.backBtn:Show()
    self:HideNavigationButtons()
    self:HideCreatureRows()

    local level = subject.observationLevel or 0

    self.subjectTitle:SetFont("Fonts\\MORPHEUS.ttf", 24, "")
    self.subjectTitle:SetJustifyH("CENTER")
    self.subjectTitle:SetText(GetSubjectDisplayName(subjectID))
    self.subjectTitle:Show()

    self:UseNormalRightText()
    self.right.text:ClearAllPoints()
    self.right.text:SetPoint("TOPLEFT", self.subjectTitle, "BOTTOMLEFT", 0, -12)

    local header = "|cffffd100Knowledge Level: " .. tostring(level) .. "/5|r\n"
        .. "|cffffd100Kills: " .. tostring(subject.totalKills or 0) .. "|r\n"
        .. "|cffffd100Observations: " .. tostring(subject.totalObservations or 0) .. "|r\n\n"
    local entries = {}

    for tier = 1, 5 do
        local lore = GetLore(subjectID, tier)

        if tier <= level then
            entries[#entries + 1] = "|cffffd100Knowledge Level " .. tier .. ":|r\n"
                .. "|cff8a6a55" .. (lore or "No recorded observation.") .. "|r\n\n"
        else
            entries[#entries + 1] = "|c88888888Knowledge Level " .. tier .. ": Not yet learned|r\n\n"
        end
    end

    local creaturePages = {}
    for _, data in ipairs(self:GetEncountersForSubject(subjectID)) do
        local encounter = data.encounter
        creaturePages[#creaturePages + 1] = {
            npcID = data.npcID,
            name = encounter.name or "Unknown Creature",
            displayID = encounter.appearanceDisplayID,
            killCount = encounter.killCount or 0,
            observationCount = encounter.observationCount or 0,
        }
    end

    if UI.Pagination then
        UI.Pagination:Show(self, "subject:" .. subjectID, header, entries, nil, creaturePages)
    else
        self.right.text:SetText(header .. table.concat(entries))
        self:ResizeScrollContent(0)
    end
end

function frame:RefreshActiveSubject(subjectID)
    if not self:IsShown() or self.state.mode ~= "lore" or self.state.subject ~= subjectID then
        return
    end

    local pages = self.journalPages
    local currentCreature = pages and pages.pageMeta and pages.pageMeta[pages.page]
    local currentNPCID = currentCreature and tonumber(currentCreature.npcID)
    self:ShowSubject(subjectID)

    -- A newly observed subtype can sort before the current page. Keep the
    -- same creature selected rather than showing a different model.
    if currentNPCID and UI.Pagination and self.journalPages then
        for page, creature in pairs(self.journalPages.pageMeta or {}) do
            if tonumber(creature.npcID) == currentNPCID then
                self.journalPages.page = page
                UI.Pagination:Render(self)
                break
            end
        end
    end
end

-- =========================
-- MAIN NAVIGATION BUTTONS
-- =========================
frame.navButtons.zones:SetScript("OnClick", function()
    PlayJournalButtonSound()
    frame:ShowZones()
end)

frame.navButtons.chronicle:SetScript("OnClick", function()
    PlayJournalButtonSound()
    frame:ShowChronicle()
end)

-- =========================
-- BACK BUTTON
-- =========================
frame.backBtn:SetScript("OnClick", function()
    PlayJournalButtonSound()

    if frame.state.mode == "lore" and frame.state.zone then
        frame:ShowZone(frame.state.zone)
    elseif frame.state.mode == "subjects" then
        frame:ShowZones()
    else
        frame:ShowLanding()
    end
end)

-- =========================
-- TOGGLE
-- =========================
function frame:Toggle()
    if self:IsShown() then
        self:Hide()
    else
        self:Show()
        self:ShowLanding()
    end
end
