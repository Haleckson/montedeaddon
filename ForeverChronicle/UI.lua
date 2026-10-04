local _, namespace = ...
local FC = namespace.FC

local frame
local content
local scrollFrame
local scrollChild
local searchBox
local backupPanel
local helpText
local contentTitle
local contentSubtitle
local accountSummaryText
local characterIdentityText
local rows = {}
local continentNameCache = {}
local categoryButtons = {}
local quickButtons = {}
local settingChecks = {}
local activeView = "journey"
local diaryOffset = 0
local chronicleOffset = 0
local diaryMode = "sessions"
local diaryModes = { "sessions", "days", "weeks", "months", "years" }
local diaryModeLocaleKeys = {
    sessions = "DIARY_MODE_SESSIONS", days = "DIARY_MODE_DAYS", weeks = "DIARY_MODE_WEEKS",
    months = "DIARY_MODE_MONTHS", years = "DIARY_MODE_YEARS",
}
local memoryQuery = ""
local memoryOffset = 0
local selectedMerchantKey
local selectedMerchantCharacter
local merchantStockOffset = 0
local merchantContinent, merchantZone, merchantCategory, merchantFaction = "", "", "", ""
local merchantFilterButtons = {}
local worldOffset = 0
local diaryQuery = ""
local searchContextChanging = false
local searchGeneration = 0
local memoryKind = "all"
local memoryFilterButtons = {}
local memoryFilterNames = { "all", "quests", "items", "atlas", "rares", "note", "npc", "merchant", "trainer", "companion", "profession" }
local worldKind = "all"
local worldZones = {}
local worldZone = ""
local worldContinent = ""
local worldCharacter = ""
local worldAreaChoices = {}
local worldContinentChoices = {}
local worldFilterButtons = {}
local worldFilterNames = { "all", "ore", "herb", "fishing", "treasure", "quests", "questflow", "items", "item_uncommon", "item_rare", "item_epic", "rares", "npcs", "merchant", "trainer", "dungeons", "notes" }
local worldContinentButton
local worldZoneButton
local worldCharacterButton
local worldChoiceMenu
local worldChoiceScroll
local worldChoiceChild
local worldChoiceRows = {}
local worldZoneHint
local worldSearchBox
local worldRows = {}
local mapSettingsButton
local diaryLengthButton
local memorySectionButtons = {}
local diaryLengthLocaleKeys = { "DIARY_LENGTH_SHORT", "DIARY_LENGTH_COMPACT", "DIARY_LENGTH_DETAILED", "DIARY_LENGTH_VERY_DETAILED" }
local function lower(text) return FC:LowerText(text) end

local function updateDiaryLengthButton()
    if not diaryLengthButton then return end
    local length = tonumber(FC.profile and FC.profile.diaryLength) or 4
    length = math.max(1, math.min(4, math.floor(length)))
    diaryLengthButton:SetText(string.format(FC.L.DIARY_LENGTH_BUTTON, FC.L[diaryLengthLocaleKeys[length]]))
end

local function validFilter(value, options)
    for _, option in ipairs(options) do
        if value == option then return true end
    end
    return false
end

local function persistUIState()
    if not FC.profile then return end
    FC.profile.uiState = FC.profile.uiState or {}
    local state = FC.profile.uiState
    state.view = activeView
    state.memoryKind = memoryKind
    state.worldKind = worldKind
    state.memoryQuery = memoryQuery
    state.diaryQuery = diaryQuery
    if worldSearchBox then state.worldQuery = worldSearchBox:GetText() or "" end
    state.worldZone = worldZone or ""
    state.worldContinent = worldContinent or ""
    state.worldCharacter = worldCharacter or ""
    state.diaryOffset = diaryOffset
    state.chronicleOffset = chronicleOffset
    state.diaryMode = diaryMode
    state.merchantContinent = merchantContinent
    state.merchantZone = merchantZone
    state.merchantCategory = merchantCategory
    state.merchantFaction = merchantFaction
    state.memoryOffset = memoryOffset
    state.worldOffset = worldOffset
end

local function mapLocationsForResult(result)
    local locations, seen = {}, {}
    local function add(location)
        if type(location) ~= "table" or not location.mapID or location.x == nil or location.y == nil then return end
        local key = table.concat({ tostring(location.mapID), tostring(location.x), tostring(location.y) }, ":")
        if not seen[key] then
            seen[key] = true
            table.insert(locations, location)
        end
    end
    for _, location in ipairs(result and result.locations or {}) do add(location) end
    for _, location in ipairs(result and result.record and result.record.locations or {}) do add(location) end
    add(result and result.location)
    add(result and result.record and result.record.location)
    return locations
end

local function continentForLocation(location)
    if not location then return "" end
    if type(location.continent) == "string" and location.continent ~= "" then return location.continent end
    if FC.GetContinentName and location.mapID then
        local mapID = tostring(location.mapID)
        local cached = continentNameCache[mapID]
        if cached == nil then
            local ok, name = pcall(FC.GetContinentName, FC, location.mapID)
            cached = ok and type(name) == "string" and name or ""
            continentNameCache[mapID] = cached
        end
        return cached
    end
    return ""
end

local function showWorldChoiceMenu(anchor, options, onSelect, selectedValue)
    if not worldChoiceMenu then
        local template = BackdropTemplateMixin and "BackdropTemplate" or nil
        worldChoiceMenu = CreateFrame("Frame", nil, content, template)
        worldChoiceMenu:SetFrameStrata("DIALOG")
        worldChoiceMenu:SetFrameLevel(content:GetFrameLevel() + 10)
        worldChoiceMenu:SetClampedToScreen(true)
        if worldChoiceMenu.SetBackdrop then
            worldChoiceMenu:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            worldChoiceMenu:SetBackdropColor(0.025, 0.043, 0.069, 0.99)
            worldChoiceMenu:SetBackdropBorderColor(0.74, 0.58, 0.30, 1)
        end
        worldChoiceScroll = CreateFrame("ScrollFrame", nil, worldChoiceMenu, "UIPanelScrollFrameTemplate")
        worldChoiceScroll:SetPoint("TOPLEFT", 5, -5)
        worldChoiceScroll:SetPoint("BOTTOMRIGHT", -25, 5)
        worldChoiceChild = CreateFrame("Frame", nil, worldChoiceScroll)
        worldChoiceChild:SetSize(220, 1)
        worldChoiceScroll:SetScrollChild(worldChoiceChild)
        worldChoiceMenu:Hide()
    end

    local rowHeight = 23
    local height = math.min(330, math.max(74, (#options * rowHeight) + 10))
    worldChoiceMenu:ClearAllPoints()
    worldChoiceMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    worldChoiceMenu:SetSize(math.max(220, anchor:GetWidth() + 18), height)
    worldChoiceScroll:SetWidth(worldChoiceMenu:GetWidth() - 30)
    worldChoiceChild:SetWidth(worldChoiceMenu:GetWidth() - 34)
    worldChoiceChild:SetHeight(math.max(1, #options * rowHeight))

    for index, option in ipairs(options) do
        local row = worldChoiceRows[index]
        if not row then
            row = CreateFrame("Button", nil, worldChoiceChild)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", 7, 0)
            row.label:SetPoint("RIGHT", -7, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)
            row.selected = row:CreateTexture(nil, "BACKGROUND")
            row.selected:SetAllPoints()
            row.selected:SetColorTexture(0.48, 0.32, 0.10, 0.48)
            row.selected:Hide()
            row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(0.88, 0.65, 0.18, 0.2)
            worldChoiceRows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", worldChoiceChild, "TOPLEFT", 0, -((index - 1) * rowHeight))
        row:SetPoint("TOPRIGHT", worldChoiceChild, "TOPRIGHT", 0, -((index - 1) * rowHeight))
        row:SetHeight(rowHeight)
        row.option = option
        row.label:SetText(option.label or "")
        local isHeader = option.header == true
        local isSelected = option.value == selectedValue
        row.selected:SetShown(isSelected and not isHeader)
        row.label:SetTextColor(isHeader and 0.92 or isSelected and 1 or 0.78,
            isHeader and 0.72 or isSelected and 0.84 or 0.72,
            isHeader and 0.38 or isSelected and 0.38 or 0.58)
        row:EnableMouse(not isHeader)
        row:SetScript("OnClick", function(self)
            if self.option and not self.option.header then
                onSelect(self.option)
                worldChoiceMenu:Hide()
            end
        end)
        row:Show()
    end
    for index = #options + 1, #worldChoiceRows do worldChoiceRows[index]:Hide() end
    worldChoiceScroll:SetVerticalScroll(0)
    worldChoiceMenu:Show()
end

local VIEWS = {
    { key = "journey", label = "MY_JOURNEY", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "chronicle", label = "CHRONICLE", icon = "Interface\\Icons\\INV_Misc_Book_04" },
    { key = "diary", label = "DIARY_TAB", icon = "Interface\\Icons\\INV_Misc_Book_08" },
    { key = "memory", label = "WHERE_WAS_IT", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    { key = "quests", label = "QUEST_ARCHIVE_SHORT", icon = "Interface\\Icons\\INV_Misc_Note_02" },
    { key = "companions", label = "COMPANIONS", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
    { key = "statistics", label = "STATISTICS", icon = "Interface\\Icons\\Achievement_General_18" },
}

local EVENT_COLORS = {
    LEVEL = { 1.00, 0.82, 0.20 }, QUEST_ACCEPTED = { 0.95, 0.78, 0.25 },
    QUEST_COMPLETED = { 0.30, 0.90, 0.35 }, ZONE = { 0.35, 0.70, 1.00 },
    BOSS_DEFEATED = { 1.00, 0.63, 0.26 },
    DUNGEON = { 0.72, 0.45, 1.00 }, RARE = { 1.00, 0.45, 0.20 },
    DEATH = { 0.90, 0.20, 0.20 }, NOTE = { 0.30, 0.85, 0.90 },
    ITEM = { 0.65, 0.45, 1.00 }, GATHER = { 1.00, 0.66, 0.18 },
    LOGIN = { 0.65, 0.65, 0.65 },
}

local EVENT_ICONS = {
    LEVEL = "Interface\\Icons\\Ability_Warrior_InnerRage",
    QUEST_ACCEPTED = "Interface\\Icons\\INV_Misc_Note_01",
    QUEST_COMPLETED = "Interface\\Icons\\INV_Misc_Note_02",
    ZONE = "Interface\\Icons\\INV_Misc_Map_01",
    BOSS_DEFEATED = "Interface\\Icons\\Achievement_Boss_Illidan",
    DUNGEON = "Interface\\Icons\\Ability_DualWield",
    RARE = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    DEATH = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    NOTE = "Interface\\Icons\\INV_Misc_Book_09",
    ITEM = "Interface\\Icons\\INV_Misc_Bag_10",
    GATHER = "Interface\\Icons\\Trade_Mining",
    LOGIN = "Interface\\Icons\\INV_Misc_PocketWatch_01",
}

local function formatTime(timestamp)
    return timestamp and timestamp > 0 and date("%d.%m.%Y  %H:%M", timestamp) or ""
end

local function todayKey(timestamp)
    return date("%Y%m%d", timestamp or FC:Now())
end

local function durationText(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    return string.format("%d:%02d h", math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
end

local function clearRows()
    for _, row in ipairs(rows) do
        row:Hide()
        row:SetScript("OnClick", nil)
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row:SetScript("OnUpdate", nil)
    end
end

local function acquireRow(index)
    local row = rows[index]
    if row then
        row:Show()
        return row
    end

    row = CreateFrame("Button", nil, scrollChild)
    row:SetHeight(58)
    row.rowHeight = 58

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()
    row.background:SetColorTexture(0.075, 0.055, 0.035, index % 2 == 0 and 0.94 or 0.86)

    row.borderTop = row:CreateTexture(nil, "BORDER")
    row.borderTop:SetPoint("TOPLEFT")
    row.borderTop:SetPoint("TOPRIGHT")
    row.borderTop:SetHeight(1)
    row.borderTop:SetColorTexture(0.42, 0.36, 0.24, 0.75)

    row.sideRule = row:CreateTexture(nil, "ARTWORK")
    row.sideRule:SetPoint("TOPLEFT", 3, -3)
    row.sideRule:SetPoint("BOTTOMLEFT", 3, 3)
    row.sideRule:SetWidth(2)
    row.sideRule:SetColorTexture(0.72, 0.55, 0.27, 0.70)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(0.90, 0.68, 0.20, 0.14)

    row.iconBorder = row:CreateTexture(nil, "ARTWORK")
    row.iconBorder:SetPoint("LEFT", 9, 0)
    row.iconBorder:SetSize(36, 36)
    row.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    row.iconBorder:SetBlendMode("ADD")
    row.iconBorder:SetAlpha(0.35)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER", row.iconBorder, "CENTER")
    row.icon:SetSize(28, 28)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 60, -10)
    row.title:SetPoint("RIGHT", -118, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)

    row.subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.subtitle:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
    row.subtitle:SetPoint("RIGHT", -118, 0)
    row.subtitle:SetJustifyH("LEFT")
    row.subtitle:SetTextColor(0.78, 0.83, 0.87)
    row.subtitle:SetWordWrap(false)

    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -12, 0)
    row.right:SetWidth(102)
    row.right:SetJustifyH("RIGHT")
    row.right:SetTextColor(0.96, 0.78, 0.40)

    rows[index] = row
    return row
end

local function addRow(index, title, subtitle, color, icon, rightText, onClick, style)
    local row = acquireRow(index)
    row.rowHeight = 58
    row.subtitle:SetWordWrap(false)
    row.subtitle:SetHeight(16)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * 61))
    row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -((index - 1) * 61))
    row.title:SetText(title or "")
    row.subtitle:SetText(subtitle or "")
    row.subtitle:SetFontObject("GameFontHighlightSmall")
    row.subtitle:ClearAllPoints()
    row.subtitle:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
    row.subtitle:SetPoint("RIGHT", row, "RIGHT", -118, 0)
    row.subtitle:SetHeight(16)
    row.right:SetText(rightText or "")
    row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Book_09")
    color = color or { 0.85, 0.68, 0.30 }
    row.title:SetTextColor(color[1], color[2], color[3])
    row.iconBorder:SetVertexColor(color[1], color[2], color[3])
    row.sideRule:SetColorTexture(color[1], color[2], color[3], 0.80)
    row.background:SetShown(true)
    row.subtitle:SetTextColor(0.78, 0.75, 0.67)
    row.right:SetTextColor(0.96, 0.78, 0.40)
    row.iconBorder:SetAlpha(0.55)
    row:SetScript("OnClick", onClick)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:EnableMouse(onClick ~= nil)
    return row
end

local function finishRows(count)
    local offset = 0
    for index = 1, count do
        local row = rows[index]
        if row and row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -offset)
            row:SetHeight(row.rowHeight or 58)
            offset = offset + (row.rowHeight or 58) + 5
        end
    end
    scrollChild:SetHeight(math.max(1, offset + 8))
end

local function updateAccountSummary()
    if not accountSummaryText or not FC.db then
        return
    end
    local summary = FC:GetAccountSummary()
    accountSummaryText:SetText(string.format(
        "%s\n|cffffffff%d|r %s\n|cffffffff%d|r %s\n|cffffffff%d|r %s",
        FC.L.ACCOUNT_MEMORY,
        summary.characters, FC.L.CHARACTERS,
        summary.events, FC.L.EVENTS,
        summary.locations, FC.L.WORLD_PLACES
    ))
end

local function setHeader(title, subtitle)
    contentTitle:SetText(title or "")
    contentSubtitle:ClearAllPoints()
    contentSubtitle:SetPoint("TOPLEFT", contentTitle, "BOTTOMLEFT", 0, -4)
    contentSubtitle:SetPoint("RIGHT", content, "RIGHT", activeView == "journey" and -170 or -18, 0)
    contentSubtitle:SetJustifyH("LEFT")
    contentSubtitle:SetWordWrap(false)
    if FC.demoMode then subtitle = FC.L.DEMO_BANNER .. ((subtitle and subtitle ~= "") and ("  •  " .. subtitle) or "") end
    contentSubtitle:SetText(subtitle or "")
end

local function safeHeaderSubtitle(text)
    contentSubtitle:ClearAllPoints()
    contentSubtitle:SetPoint("TOPLEFT", contentTitle, "BOTTOMLEFT", 0, -5)
    contentSubtitle:SetPoint("RIGHT", content, "RIGHT", -18, 0)
    contentSubtitle:SetJustifyH("LEFT")
    contentSubtitle:SetWordWrap(false)
    if FC.demoMode then text = FC.L.DEMO_BANNER .. ((text and text ~= "") and ("  •  " .. text) or "") end
    contentSubtitle:SetText(text or "")
end

local function setListLayout(hasSearch)
    if backupPanel then backupPanel:Hide() end
    scrollFrame:Show()
    searchBox:SetShown(hasSearch and activeView ~= "world")
    scrollFrame:ClearAllPoints()
    local topOffset = activeView == "world" and -283 or (activeView == "memory" and ((memoryKind == "merchant" or memoryKind == "trainer") and -257 or -168) or (activeView == "chronicle" and -84 or (hasSearch and -136 or -58)))
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 14, topOffset)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -31, 12)
end

local function eventSubtitle(event)
    local parts = { formatTime(event.ts) }
    local location = FC:FormatLocation(event.location)
    if location ~= "" then
        table.insert(parts, location)
    end
    if event.detail and event.detail ~= "" then
        table.insert(parts, event.detail)
    end
    return table.concat(parts, "  •  ")
end

local function renderOverview()
    setListLayout(false)
    clearRows()
    local identity = FC.profile and FC.profile.identity or {}
    local currentName = UnitName and UnitName("player")
    if FC:IsSecret(currentName) or type(currentName) ~= "string" or currentName == ""
        or currentName == "Unknown" or currentName == "Unbekannt" then currentName = nil end
    local displayName = currentName or identity.name or FC.L.UNKNOWN_CHARACTER
    setHeader(FC.L.MY_JOURNEY, string.format("%s · %s %s", displayName, FC.L.LEVEL_SHORT,
        tostring((FC.demoMode and identity.level) or FC:GetPlayerLevel() or identity.level or 0)))
    local profile = FC.profile
    if not profile then
        finishRows(0)
        return
    end
    local events = profile.events or {}
    local currentSummary = FC:BuildSessionSummary(FC.activeSession)
    local level = (FC.demoMode and profile.identity.level) or FC:GetPlayerLevel() or profile.identity.level or 0
    addRow(1, string.format("%s — %s %d", FC.L.CURRENT_JOURNEY, FC.L.LEVEL_REACHED, level),
        FC:FormatSessionSummary(currentSummary), { 1.00, 0.82, 0.20 },
        "Interface\\Icons\\INV_Misc_PocketWatch_01", date("%H:%M"))
    local rowIndex = 2
    local previous = FC:GetPreviousSession()
    if previous then
        local previousSummary = previous.summary or FC:BuildSessionSummary(previous)
        local levelText = previousSummary and previousSummary.startLevel and previousSummary.endLevel
            and string.format("%s %s → %s", FC.L.LEVEL_REACHED, previousSummary.startLevel, previousSummary.endLevel) or ""
        addRow(rowIndex, FC.L.LAST_JOURNEY, FC:FormatSessionSummary(previousSummary),
            { 0.82, 0.72, 0.52 }, "Interface\\Icons\\INV_Misc_Book_04", levelText)
        rowIndex = rowIndex + 1
    end
    local storyRow = addRow(rowIndex, FC.L.RECENT_CHAPTERS, FC:BuildCharacterStory(),
        { 0.75, 0.66, 0.48 }, "Interface\\Icons\\INV_Misc_Book_04")
    storyRow.rowHeight = 84
    storyRow.subtitle:ClearAllPoints()
    storyRow.subtitle:SetPoint("TOPLEFT", storyRow.title, "BOTTOMLEFT", 0, -4)
    storyRow.subtitle:SetPoint("RIGHT", storyRow, "RIGHT", -14, 0)
    storyRow.subtitle:SetHeight(48)
    storyRow.subtitle:SetWordWrap(true)
    rowIndex = rowIndex + 1
    local shown = 0
    for index = #events, 1, -1 do
        local event = events[index]
        if event.type ~= "LOGIN" then
            local location = event.location
            local gatherNode = event.type == "GATHER" and event.data and FC.db.atlas.nodes[tostring(event.data.nodeID)]
            local markerKind = gatherNode and gatherNode.kind or event.type
            local markerIcon = gatherNode and gatherNode.icon or EVENT_ICONS[event.type]
            addRow(rowIndex, event.title or event.type, eventSubtitle(event), EVENT_COLORS[event.type], EVENT_ICONS[event.type],
                location and location.x and FC.L.WORLD_PLACES or "", location and location.x and function()
                    FC:ShowLocationsOnMap(event.title or event.type, markerKind,
                        gatherNode and { gatherNode } or { location }, markerIcon)
                end or nil)
            rowIndex = rowIndex + 1
            shown = shown + 1
            if shown >= 8 then break end
        end
    end
    if #events == 0 then
        addRow(rowIndex, FC.L.NO_EVENTS, "", { 0.60, 0.60, 0.60 })
        rowIndex = rowIndex + 1
    end
    finishRows(rowIndex - 1)
end

local function chapterRecapText(chapter)
    local parts = {}
    local counts = chapter.counts or {}
    if counts.quests and counts.quests > 0 then table.insert(parts, string.format(FC.L.STORY_QUESTS, counts.quests)) end
    if counts.dungeons and counts.dungeons > 0 then table.insert(parts, string.format(FC.L.STORY_DUNGEONS, counts.dungeons)) end
    if counts.rares and counts.rares > 0 then table.insert(parts, string.format(FC.L.STORY_RARES, counts.rares)) end
    if counts.gatherings and counts.gatherings > 0 then table.insert(parts, string.format(FC.L.STORY_GATHERINGS, counts.gatherings)) end
    if counts.deaths and counts.deaths > 0 then table.insert(parts, string.format(FC.L.STORY_DEATHS, counts.deaths)) end
    if chapter.firstTs and chapter.lastTs then
        local startDate, endDate = date("%d.%m.%Y", chapter.firstTs), date("%d.%m.%Y", chapter.lastTs)
        table.insert(parts, startDate == endDate and startDate or string.format(FC.L.CHAPTER_PERIOD, startDate, endDate))
    end
    if chapter.highlights and #chapter.highlights > 0 then
        table.insert(parts, table.concat(chapter.highlights, " · "))
    end
    return #parts > 0 and table.concat(parts, "  •  ") or FC.L.CHAPTER_EXPLORATION
end

local function addChapterRecap(rowIndex, chapter)
    if not chapter or (chapter.events or 0) == 0 then return rowIndex end
    addRow(rowIndex, string.format(FC.L.CHAPTER_RECAP, chapter.events), chapterRecapText(chapter),
        { 0.75, 0.66, 0.48 }, "Interface\\Icons\\INV_Misc_Book_04")
    return rowIndex + 1
end

local function renderChronicle()
    setListLayout(true)
    clearRows()
    local events = FC.profile and FC.profile.events or {}
    setHeader(FC.L.CHRONICLE, "")
    local story = FC:BuildCharacterStory()
    if story and story ~= "" then
        addRow(1, FC.L.MY_JOURNEY, story, {0.92, 0.79, 0.43}, "Interface\\Icons\\INV_Misc_Book_09")
        rows[1].rowHeight = 104
        rows[1].subtitle:SetWordWrap(true)
        rows[1].subtitle:SetHeight(70)
    end
    local pageSize, total = 50, #events
    local maxOffset = math.max(0, math.floor((total - 1) / pageSize) * pageSize)
    chronicleOffset = math.min(math.max(0, chronicleOffset), maxOffset)
    local last = math.max(0, total - chronicleOffset)
    local first = math.max(1, last - pageSize + 1)
    local rowIndex = 2
    local function addChroniclePager(label, nextOffset)
        addRow(rowIndex, label, "", { 0.92, 0.76, 0.38 }, "Interface\\Icons\\INV_Misc_Book_04",
            total > 0 and string.format(FC.L.MEMORY_PAGE_RANGE, first, last, total) or "", function()
                chronicleOffset = nextOffset
                if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
                persistUIState()
                renderChronicle()
            end)
        rowIndex = rowIndex + 1
    end
    if chronicleOffset > 0 then addChroniclePager(FC.L.MEMORY_SHOW_NEWER, math.max(0, chronicleOffset - pageSize)) end
    local currentArea, currentLevel, chapter = nil, nil, nil
    for index = 1, first - 1 do
        local event = events[index]
        if event.type == "ZONE" then
            currentArea = { place = event.location and (event.location.zone or event.location.subZone) or event.title or "" }
            currentLevel = nil
        elseif event.type == "LEVEL" then
            currentLevel = event.data and event.data.level or event.title
        end
    end
    for index = first, last do
        local event = events[index]
        if event.type ~= "LOGIN" then
            if event.type == "ZONE" and currentArea and currentArea.place == ((event.location and (event.location.zone or event.location.subZone)) or event.title) then
                -- Ignore duplicate area notifications; only a real area change
                -- starts a new chapter in the narrative.
            elseif event.type == "ZONE" or event.type == "LEVEL" then
                rowIndex = addChapterRecap(rowIndex, chapter)
                chapter = { events = 0, counts = {}, highlights = {} }
                if event.type == "ZONE" then
                    local place = event.location and (event.location.zone or event.location.subZone) or ""
                    currentArea = { place = place }
                    currentLevel = nil
                    local title = string.format(FC.L.AREA_CHAPTER, place ~= "" and place or (event.title or FC.L.AREA_LABEL))
                    addRow(rowIndex, title, eventSubtitle(event), { 1.00, 0.82, 0.20 }, EVENT_ICONS.ZONE)
                    rowIndex = rowIndex + 1
                elseif not currentArea then
                    local place = event.location and (event.location.zone or event.location.subZone) or ""
                    currentArea = { place = place }
                    addRow(rowIndex, string.format(FC.L.AREA_CHAPTER, place ~= "" and place or FC.L.AREA_LABEL),
                        FC.L.STORY_BEGAN_UNKNOWN, { 1.00, 0.82, 0.20 }, EVENT_ICONS.ZONE)
                    rowIndex = rowIndex + 1
                end
                if event.type == "LEVEL" then
                    currentLevel = event.data and event.data.level or event.title
                    addRow(rowIndex, string.format(FC.L.LEVEL_CHAPTER, tostring(currentLevel or "")), eventSubtitle(event),
                        { 0.94, 0.77, 0.27 }, EVENT_ICONS.LEVEL)
                    rowIndex = rowIndex + 1
                end
            else
                if not chapter then chapter = { events = 0, counts = {}, highlights = {} } end
                chapter.events = chapter.events + 1
                chapter.firstTs = chapter.firstTs or event.ts
                chapter.lastTs = event.ts or chapter.lastTs
                local countKey = event.type == "QUEST_COMPLETED" and "quests"
                    or event.type == "DUNGEON" and "dungeons"
                    or event.type == "RARE" and "rares"
                    or event.type == "GATHER" and "gatherings"
                    or event.type == "DEATH" and "deaths"
                if countKey then chapter.counts[countKey] = (chapter.counts[countKey] or 0) + 1 end
                if (event.type == "QUEST_COMPLETED" or event.type == "DUNGEON" or event.type == "RARE")
                    and #chapter.highlights < 3 then
                    table.insert(chapter.highlights, event.title or event.type)
                end
                local location = event.location
                local gatherNode = event.type == "GATHER" and event.data and FC.db.atlas.nodes[tostring(event.data.nodeID)]
                local markerKind = gatherNode and gatherNode.kind or event.type
                local markerIcon = gatherNode and gatherNode.icon or EVENT_ICONS[event.type]
                addRow(rowIndex, event.title or event.type, eventSubtitle(event), EVENT_COLORS[event.type], EVENT_ICONS[event.type],
                    currentArea and (currentArea.place .. (currentLevel and (" · " .. FC.L.LEVEL_REACHED .. " " .. tostring(currentLevel)) or "")) or event.type or "", location and location.x and function()
                        FC:ShowLocationsOnMap(event.title or event.type, markerKind,
                            gatherNode and { gatherNode } or { location }, markerIcon)
                    end or nil)
                rowIndex = rowIndex + 1
            end
        end
    end
    rowIndex = addChapterRecap(rowIndex, chapter)
    if first > 1 then addChroniclePager(FC.L.MEMORY_SHOW_OLDER, chronicleOffset + pageSize) end
    if #events == 0 then
        addRow(1, FC.L.NO_EVENTS, "", { 0.55, 0.55, 0.55 })
        rowIndex = 2
    end
    finishRows(rowIndex - 1)
end

local function renderDiary()
    setListLayout(true)
    clearRows()
    local query = (diaryQuery or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local entries = {}
    local sourceEntries = FC:GetDiaryPeriodEntries(diaryMode)
    for _, entry in ipairs(sourceEntries) do
        if FC:DiaryEntryMatchesQuery(entry, query) then
            table.insert(entries, entry)
        end
    end
    local pageSize = 20
    local total = #entries
    setHeader(FC.L.DIARY_TAB, string.format(FC.L.DIARY_PERIOD_HEADER, total, FC.L[diaryModeLocaleKeys[diaryMode]]))
    local maxOffset = math.max(0, math.floor((total - 1) / pageSize) * pageSize)
    diaryOffset = math.min(math.max(0, diaryOffset), maxOffset)
    local first = diaryOffset + 1
    local last = math.min(total, diaryOffset + pageSize)
    local rowIndex = 1

    local function addPager(label, nextOffset)
        local rangeStart = total > 0 and first or 0
        local rangeEnd = total > 0 and last or 0
        local rangeLabel = FC.L[diaryModeLocaleKeys[diaryMode]]
        addRow(rowIndex, label, "", { 0.92, 0.76, 0.38 }, "Interface\\Icons\\INV_Misc_Book_04",
            total > 0 and string.format(FC.L.DIARY_PERIOD_PAGE_RANGE, rangeLabel, rangeStart, rangeEnd, total) or "",
            function()
                diaryOffset = nextOffset
                if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
                persistUIState()
                renderDiary()
            end)
        rowIndex = rowIndex + 1
    end

    local modeIndex = 1
    for index, mode in ipairs(diaryModes) do if mode == diaryMode then modeIndex = index; break end end
    local nextMode = diaryModes[(modeIndex % #diaryModes) + 1]
    local switchRow = addRow(rowIndex, string.format(FC.L.DIARY_MODE_CURRENT, FC.L[diaryModeLocaleKeys[diaryMode]]),
        FC.L.DIARY_MODE_HELP, { 0.40, 0.28, 0.14 },
        "Interface\\Icons\\INV_Misc_Book_04", "", function()
            diaryMode = nextMode
            diaryOffset = 0
            if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
            persistUIState()
            renderDiary()
        end)
    switchRow.rowHeight = 42
    switchRow.iconBorder:SetSize(32, 32)
    switchRow.icon:SetSize(24, 24)
    rowIndex = rowIndex + 1

    if total == 0 then
        local message = query ~= "" and FC.L.DIARY_NO_RESULTS or FC.L.DIARY_EMPTY
        addRow(rowIndex, message, "", { 0.30, 0.22, 0.12 }, "Interface\\Icons\\INV_Misc_Book_08", nil, nil)
        finishRows(rowIndex)
        return
    end
    if diaryOffset > 0 then addPager(FC.L.DIARY_SHOW_NEWER, math.max(0, diaryOffset - pageSize)) end

    for entryIndex = first, last do
        local entry = entries[entryIndex]
        local session = entry.session
        local startedAt = session.startedAt or entry.summary.startedAt or FC:Now()
        local endedAt = session.endedAt or FC:Now()
        local title
        if diaryMode == "sessions" then
            title = string.format(FC.L.DIARY_ENTRY_TITLE, date(FC.L.DIARY_DATE_FORMAT, startedAt))
        elseif diaryMode == "days" then
            title = string.format(FC.L.DIARY_DAY_ENTRY_TITLE, date(FC.L.DIARY_DAY_DATE_FORMAT, startedAt))
        elseif diaryMode == "weeks" then
            title = string.format(FC.L.DIARY_WEEK_ENTRY_TITLE, date(FC.L.DIARY_DATE_FORMAT, startedAt), date(FC.L.DIARY_DATE_FORMAT, endedAt))
        elseif diaryMode == "months" then
            title = string.format(FC.L.DIARY_MONTH_ENTRY_TITLE, date("%B %Y", startedAt))
        else
            title = string.format(FC.L.DIARY_YEAR_ENTRY_TITLE, date("%Y", startedAt))
        end
        if diaryMode ~= "sessions" and (entry.entryCount or 1) > 1 then
            title = title .. " · " .. string.format(FC.L.DIARY_PERIOD_SESSIONS_FORMAT, entry.entryCount)
        end
        local narrative = entry.narrative or ""
        local timeRange = string.format("%s–%s", date("%H:%M", startedAt), date("%H:%M", endedAt))
        local row = addRow(rowIndex, title, narrative, { 0.86, 0.75, 0.51 },
            "Interface\\Icons\\INV_Misc_Book_08", timeRange, nil)
        row.right:ClearAllPoints()
        row.right:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -11)
        row.right:SetHeight(16)
        row.subtitle:SetFontObject("GameFontHighlightSmall")
        local narrativeFont, narrativeSize = row.subtitle:GetFont()
        if narrativeFont then row.subtitle:SetFont(narrativeFont, math.max(13, narrativeSize or 0)) end
        row.subtitle:SetTextColor(0.86, 0.82, 0.72)
        row.subtitle:SetSpacing(1)
        row.subtitle:ClearAllPoints()
        row.subtitle:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
        row.subtitle:SetPoint("RIGHT", row, "RIGHT", -24, 0)
        local childWidth = tonumber(scrollChild:GetWidth()) or 0
        if childWidth <= 0 then childWidth = 630 end
        local measuredWidth = math.max(240, childWidth - 88)
        row.subtitle:SetWidth(measuredWidth)
        local font, fontSize = row.subtitle:GetFont()
        local averageCharacterWidth = math.max(5.5, (fontSize or 12) * 0.55)
        local estimatedLines = 0
        for paragraph in (narrative .. "\n"):gmatch("(.-)\n") do
            if paragraph ~= "" then
                local characters = #paragraph - select(2, paragraph:gsub("[\128-\191]", ""))
                estimatedLines = estimatedLines + math.max(1, math.ceil(characters * averageCharacterWidth / measuredWidth))
            end
        end
        local estimatedHeight = math.max(1, estimatedLines) * 18
        row.subtitle:SetHeight(estimatedHeight)
        row.subtitle:SetWordWrap(true)
        row.subtitle:SetJustifyH("LEFT")
        row.rowHeight = 52 + estimatedHeight
        rowIndex = rowIndex + 1
    end

    if last < total then addPager(FC.L.DIARY_SHOW_OLDER, diaryOffset + pageSize) end
    finishRows(rowIndex - 1)
end

local renderMemory
local function renderMerchantStock()
    local profile = FC.db and FC.db.characters and FC.db.characters[selectedMerchantCharacter]
    local merchant = profile and profile.merchants and profile.merchants[selectedMerchantKey]
    if not merchant then
        selectedMerchantKey, selectedMerchantCharacter = nil, nil
        return false
    end
    clearRows()
    setHeader(merchant.name or selectedMerchantKey, FC:FormatLocation(merchant.location) .. "  •  " .. selectedMerchantCharacter)
    local stock, seen = {}, {}
    for id, item in pairs(merchant.items or {}) do
        local name = item.name or string.format(FC.L.ITEM_ID, tostring(id))
        seen[lower(name)] = true
        table.insert(stock, { name = name, category = item.itemSubType or item.itemType or FC.L.ITEM_LABEL,
            id = id, link = item.link })
    end
    for name, item in pairs(merchant.itemsByName or {}) do
        if not seen[lower(name)] then
            table.insert(stock, { name = name, category = item.itemSubType or FC.L.ITEM_LABEL })
        end
    end
    table.sort(stock, function(a, b)
        if lower(a.category) ~= lower(b.category) then return lower(a.category) < lower(b.category) end
        return lower(a.name) < lower(b.name)
    end)
    local rowIndex = 1
    addRow(rowIndex, FC.L.MERCHANT_STOCK_BACK, FC.L.WHERE_WAS_IT,
        { 0.92, 0.76, 0.38 }, "Interface\\Icons\\INV_Misc_Book_04", "", function()
            selectedMerchantKey, selectedMerchantCharacter = nil, nil
            renderMemory()
        end)
    rowIndex = rowIndex + 1
    local pageSize = 30
    merchantStockOffset = math.min(math.max(0, merchantStockOffset),
        math.max(0, math.floor((#stock - 1) / pageSize) * pageSize))
    if merchantStockOffset > 0 then
        addRow(rowIndex, FC.L.MEMORY_SHOW_NEWER, "", nil, "Interface\\Icons\\INV_Misc_Book_04", "", function()
            merchantStockOffset = math.max(0, merchantStockOffset - pageSize)
            renderMerchantStock()
        end)
        rowIndex = rowIndex + 1
    end
    for index = merchantStockOffset + 1, math.min(#stock, merchantStockOffset + pageSize) do
        local item = stock[index]
        local itemID = not FC:IsSecret(item.id) and tonumber(item.id) or nil
        local icon
        local function validIcon(value)
            if FC:IsSecret(value) or type(value) ~= "string" and type(value) ~= "number" then return nil end
            return value
        end
        if itemID then
            if C_Item and C_Item.GetItemIconByID then icon = validIcon(C_Item.GetItemIconByID(itemID)) end
            if not icon and GetItemIcon then icon = validIcon(GetItemIcon(itemID)) end
            if not icon and GetItemInfoInstant then icon = validIcon(select(5, GetItemInfoInstant(itemID))) end
            if not icon and GetItemInfo then icon = validIcon(select(10, GetItemInfo(itemID))) end
        end
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        local function safeItemLink()
            local link = item.link
            if FC:IsSecret(link) or type(link) ~= "string" then link = nil end
            if not link and GetItemInfo then
                local ok, _, candidate = pcall(GetItemInfo, itemID)
                if ok and not FC:IsSecret(candidate) and type(candidate) == "string" then link = candidate end
            end
            return link
        end
        local row = addRow(rowIndex, item.name, item.category, { 0.84, 0.80, 0.66 },
            icon, "", function()
                if IsShiftKeyDown and IsShiftKeyDown() and itemID and ChatEdit_InsertLink then
                    local link = safeItemLink()
                    if not FC:IsSecret(link) and type(link) == "string" and ChatEdit_InsertLink(link) then return end
                end
                selectedMerchantKey, selectedMerchantCharacter = nil, nil
                memoryKind = "merchant"
                FC:SetUISearch(item.name)
            end)
        if itemID then
            local function placeTooltip()
                if not GetCursorPosition then return end
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                GameTooltip:ClearAllPoints()
                GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x / scale - 14, y / scale + 16)
            end
            row:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                local link = safeItemLink()
                local ok = link and pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                if not ok then
                    ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. itemID)
                end
                if ok then
                    placeTooltip()
                    GameTooltip:Show()
                    self:SetScript("OnUpdate", function() if GameTooltip:IsShown() then placeTooltip() end end)
                else GameTooltip:Hide() end
            end)
            row:SetScript("OnLeave", function(self)
                self:SetScript("OnUpdate", nil)
                if GameTooltip then GameTooltip:Hide() end
            end)
        end
        rowIndex = rowIndex + 1
    end
    if merchantStockOffset + pageSize < #stock then
        addRow(rowIndex, FC.L.MEMORY_SHOW_OLDER, "", nil, "Interface\\Icons\\INV_Misc_Book_04", "", function()
            merchantStockOffset = merchantStockOffset + pageSize
            renderMerchantStock()
        end)
        rowIndex = rowIndex + 1
    end
    if #stock == 0 then
        addRow(rowIndex, FC.L.MERCHANT_STOCK_EMPTY, "", nil, "Interface\\Icons\\INV_Misc_QuestionMark")
        rowIndex = rowIndex + 1
    end
    finishRows(rowIndex - 1)
    return true
end

local function merchantChoices()
    local continents, zones, categories = {}, {}, {}
    local seenContinents, seenZones = {}, {}
    for _, profile in pairs(FC.db and FC.db.characters or {}) do
        for _, kind in ipairs({ "merchants", "trainers" }) do
            for _, record in pairs(profile[kind] or {}) do
                local loc = record.location or {}
                local continent = continentForLocation(loc)
                local zone = loc.zone or ""
                if continent ~= "" and not seenContinents[continent] then
                    continents[#continents + 1] = continent; seenContinents[continent] = true
                end
                if zone ~= "" and (merchantContinent == "" or continent == merchantContinent) and not seenZones[zone] then
                    zones[#zones + 1] = zone; seenZones[zone] = true
                end
                if kind == "merchants" then
                    for _, item in pairs(record.items or {}) do
                        local category = item.itemSubType or item.itemType
                        if category and category ~= "" then categories[category] = true end
                    end
                    for _, item in pairs(record.itemsByName or {}) do
                        local category = item.itemSubType or item.itemType
                        if category and category ~= "" then categories[category] = true end
                    end
                end
            end
        end
    end
    local categoryList = {}
    for category in pairs(categories) do categoryList[#categoryList + 1] = category end
    local byName = function(a, b) return lower(a) < lower(b) end
    table.sort(continents, byName); table.sort(zones, byName); table.sort(categoryList, byName)
    return continents, zones, categoryList
end

local function merchantHasCategory(record, category)
    if category == "" then return true end
    for _, items in ipairs({ record.items or {}, record.itemsByName or {} }) do
        for _, item in pairs(items) do
            if item.itemSubType == category or item.itemType == category then return true end
        end
    end
    return false
end

renderMemory = function()
    setListLayout(true)
    if selectedMerchantKey and renderMerchantStock() then return end
    clearRows()
    setHeader(FC.L.WHERE_WAS_IT, FC.L.SEARCH_ACCOUNT .. "  •  " .. FC.L.SEARCH_FILTER_HELP)
    local _, zones = merchantChoices()
    if merchantZone ~= "" then
        local found = false
        for _, zone in ipairs(zones) do if zone == merchantZone then found = true; break end end
        if not found then merchantZone = "" end
    end
    for index, button in ipairs(merchantFilterButtons) do
        button:SetShown(memoryKind == "merchant" or (memoryKind == "trainer" and index ~= 3))
    end
    merchantFilterButtons[1]:SetText(merchantContinent ~= "" and merchantContinent or FC.L.WORLD_ALL_CONTINENTS)
    merchantFilterButtons[2]:SetText(merchantZone ~= "" and merchantZone or FC.L.ZONE_ALL)
    merchantFilterButtons[3]:SetText(merchantCategory ~= "" and merchantCategory or FC.L.MERCHANT_ALL_GOODS)
    merchantFilterButtons[4]:SetText(merchantFaction ~= "" and merchantFaction or FC.L.MERCHANT_ALL_FACTIONS)
    local allResults = FC:SearchMemory(searchBox:GetText() or "")
    local results = {}
    for _, result in ipairs(allResults) do
        if memoryKind == "all" or result.kind == memoryKind
            or (memoryKind == "items" and result.kind == "items_account") then
            local relevant = result.kind == "merchant" or result.kind == "trainer"
            local loc = result.location or {}
            local matchesPlace = (merchantContinent == "" or continentForLocation(loc) == merchantContinent)
                and (merchantZone == "" or loc.zone == merchantZone)
            local matchesGoods = merchantCategory == "" or result.kind == "trainer" or
                (result.kind == "merchant" and result.record and merchantHasCategory(result.record, merchantCategory))
            local profile = FC.db and FC.db.characters and FC.db.characters[result.characterKey]
            local observedFaction = profile and profile.identity and profile.identity.faction or ""
            local matchesFaction = merchantFaction == "" or observedFaction == merchantFaction
            if not relevant or (matchesPlace and matchesGoods and matchesFaction) then table.insert(results, result) end
        end
    end
    table.sort(results, function(a, b)
        if memoryKind == "merchant" and a.kind == "merchant" and b.kind == "merchant" then
            if lower(a.title) ~= lower(b.title) then return lower(a.title) < lower(b.title) end
            return lower(a.characterKey) < lower(b.characterKey)
        end
        if (a.score or 0) ~= (b.score or 0) then return (a.score or 0) > (b.score or 0) end
        if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
        return lower(a.title) < lower(b.title)
    end)
    local pageSize, total = 30, #results
    local maxOffset = math.max(0, math.floor((total - 1) / pageSize) * pageSize)
    memoryOffset = math.min(math.max(0, memoryOffset), maxOffset)
    local first, last = memoryOffset + 1, math.min(total, memoryOffset + pageSize)
    local matched = 0
    for key, button in pairs(memoryFilterButtons) do
        local selected = key == memoryKind
        button:SetAlpha(selected and 1 or 0.58)
        button.selected:SetShown(selected)
        button.label:SetTextColor(selected and 1 or 0.83, selected and 0.88 or 0.86, selected and 0.57 or 0.89)
        button:Disable()
        if not selected then button:Enable() end
    end
    local rowIndex = 1
    local function addMemoryPager(label, nextOffset)
        addRow(rowIndex, label, "", { 0.92, 0.76, 0.38 }, "Interface\\Icons\\INV_Misc_Book_04",
            total > 0 and string.format(FC.L.MEMORY_PAGE_RANGE, first, last, total) or "", function()
                memoryOffset = nextOffset
                if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
                persistUIState()
                renderMemory()
            end)
        rowIndex = rowIndex + 1
    end
    if memoryOffset > 0 then addMemoryPager(FC.L.MEMORY_SHOW_NEWER, math.max(0, memoryOffset - pageSize)) end
    for resultIndex = first, last do
        local result = results[resultIndex]
        local color = (result.kind == "items_account" and { 1.00, 0.82, 0.30 })
            or result.kind == "note" and EVENT_COLORS.NOTE
            or (result.kind == "rares" and EVENT_COLORS.RARE)
            or (result.kind == "atlas" and EVENT_COLORS.GATHER)
            or (result.kind == "quests" and EVENT_COLORS.QUEST_COMPLETED)
            or ((result.kind == "merchant" or result.kind == "trainer") and { 1.00, 0.78, 0.28 })
            or (result.kind == "companion" and { 0.55, 0.88, 0.65 })
            or { 0.45, 0.78, 1.00 }
        local icon = (result.kind == "profession" and "Interface\\Icons\\Trade_Engineering")
            or (result.kind == "items_account" and result.record and result.record.icon)
            or (result.kind == "items_account" and "Interface\\Icons\\INV_Misc_Bag_10")
            or result.kind == "items" and result.record and result.record.icon
            or result.kind == "items" and "Interface\\Icons\\INV_Misc_Bag_10"
            or result.kind == "note" and "Interface\\Icons\\INV_Misc_Book_09"
            or result.kind == "rares" and "Interface\\Icons\\INV_Misc_Head_Dragon_01"
            or result.kind == "atlas" and "Interface\\Icons\\Trade_Mining"
            or result.kind == "quests" and "Interface\\Icons\\INV_Misc_Note_02"
            or result.kind == "merchant" and "Interface\\Icons\\INV_Misc_Coin_05"
            or result.kind == "trainer" and "Interface\\Icons\\INV_Misc_Book_11"
            or result.kind == "companion" and "Interface\\Icons\\INV_Misc_GroupNeedMore"
            or "Interface\\Icons\\INV_Misc_Spyglass_03"
        local location = result.location
        local resultMapLocations = mapLocationsForResult(result)
        local subtitle = result.subtitle
        if (result.kind == "merchant" or result.kind == "trainer") and location then
            local place = table.concat({ continentForLocation(location), location.zone or "" }, " · ")
            if place ~= " · " then subtitle = place .. "  •  " .. (subtitle or "") end
        end
        addRow(rowIndex, result.title, subtitle, color, icon, location and location.x and FC.L.WORLD_PLACES or "",
            function(_, button)
                if result.kind == "merchant" and button ~= "RightButton" then
                    selectedMerchantKey = result.id
                    selectedMerchantCharacter = result.characterKey
                    merchantStockOffset = 0
                    renderMemory()
                elseif button == "RightButton" then
                    local recordName = result.record and (result.record.name or result.record.currentName)
                    FC:OpenMemory(recordName or result.title or "")
                elseif #resultMapLocations > 0 then
                    local mapKind = result.kind == "atlas" and result.record and result.record.kind or result.kind
                    FC:ShowLocationsOnMap(result.title, mapKind, resultMapLocations, icon,
                        result.record and result.record.quality)
                end
            end)
        rowIndex = rowIndex + 1
        matched = matched + 1
    end
    if last < total then addMemoryPager(FC.L.MEMORY_SHOW_OLDER, memoryOffset + pageSize) end
    if matched == 0 then
        addRow(1, FC.L.NO_CATEGORY_RESULTS, FC.L.QUICK_SEARCH, { 0.55, 0.55, 0.55 }, "Interface\\Icons\\INV_Misc_QuestionMark")
        rowIndex = 2
    end
    finishRows(rowIndex - 1)
end

local function renderWorld()
    setListLayout(true)
    clearRows()
    local locations = FC:GetRecentLocations()
    if worldCharacter == "" then worldCharacter = FC.characterKey or "account" end
    if worldCharacter ~= "account" and not FC.db.characters[worldCharacter] then
        worldCharacter = FC.characterKey or "account"
    end
    local selectedCharacter = worldCharacter
    local areaChoices, seenAreas, continentChoices, seenContinents = {}, {}, {}, {}
    local function addArea(location)
        if type(location) ~= "table" then return end
        local continent = continentForLocation(location)
        local zone = location.zone or location.subZone or ""
        if zone == "" then return end
        local areaKey = lower(continent) .. "\t" .. lower(zone)
        if not seenAreas[areaKey] then
            seenAreas[areaKey] = true
            table.insert(areaChoices, { continent = continent, zone = zone })
        end
        if continent ~= "" and not seenContinents[lower(continent)] then
            seenContinents[lower(continent)] = true
            table.insert(continentChoices, continent)
        end
    end
    for _, result in ipairs(locations) do
        if result.characterKey == selectedCharacter or selectedCharacter == "account" then
            addArea(result.location)
            for _, saved in ipairs(result.locations or {}) do addArea(saved) end
        end
    end
    for characterKey, profile in pairs(FC.db.characters or {}) do
        if type(profile) == "table" and (selectedCharacter == "account" or characterKey == selectedCharacter) then
            for _, event in ipairs(type(profile.events) == "table" and profile.events or {}) do if type(event) == "table" then addArea(event.location) end end
            for _, discovery in ipairs(type(profile.discoveries) == "table" and profile.discoveries or {}) do if type(discovery) == "table" then addArea(discovery.location) end end
            for _, note in ipairs(type(profile.notes) == "table" and profile.notes or {}) do if type(note) == "table" then addArea(note.location) end end
            for _, records in pairs(type(profile.observed) == "table" and profile.observed or {}) do
                if type(records) == "table" then
                    for _, record in pairs(records) do
                        if type(record) == "table" then
                            addArea(record.location)
                            for _, saved in ipairs(type(record.locations) == "table" and record.locations or {}) do addArea(saved) end
                        end
                    end
                end
            end
            for _, recordType in ipairs({ "merchants", "trainers", "companions" }) do
                for _, record in pairs(type(profile[recordType]) == "table" and profile[recordType] or {}) do
                    if type(record) == "table" then
                        addArea(record.location)
                        for _, saved in ipairs(type(record.locations) == "table" and record.locations or {}) do addArea(saved) end
                    end
                end
            end
        end
    end
    for _, node in pairs(FC.db.atlas and FC.db.atlas.nodes or {}) do
        if selectedCharacter == "account" or (type(node.characters) == "table" and node.characters[selectedCharacter]) then
            addArea({ continent = node.continent, zone = node.zone, subZone = node.subZone })
        end
    end
    for _, quest in ipairs(FC:GetQuestArchive()) do
        local record = quest.record or {}
        local belongs = selectedCharacter == "account"
            or (type(record.completedBy) == "table" and record.completedBy[selectedCharacter] ~= nil)
        if not belongs then
            for _, saved in ipairs(record.locations or {}) do
                if type(saved.characters) == "table" and saved.characters[selectedCharacter] then belongs = true; break end
            end
        end
        if belongs then
            if selectedCharacter == "account" or (quest.location and type(quest.location.characters) == "table" and quest.location.characters[selectedCharacter]) then
                addArea(quest.location)
            end
            for _, saved in ipairs(record.locations or {}) do
                if selectedCharacter == "account" or (type(saved.characters) == "table" and saved.characters[selectedCharacter]) then addArea(saved) end
            end
        end
    end
    table.sort(continentChoices, function(a, b) return lower(a) < lower(b) end)
    table.sort(areaChoices, function(a, b)
        if lower(a.continent) ~= lower(b.continent) then return lower(a.continent) < lower(b.continent) end
        return lower(a.zone) < lower(b.zone)
    end)
    local selectedZone = worldZone or ""
    local selectedContinent = worldContinent or ""
    local textQuery = lower((worldSearchBox and worldSearchBox:GetText()) or "")
    worldZones = seenAreas
    worldAreaChoices = areaChoices
    worldContinentChoices = continentChoices
    local scopeTitle = selectedZone ~= "" and selectedZone or selectedContinent ~= "" and selectedContinent or FC.L.ZONE_ALL
    setHeader(FC.L.WHERE_WAS_IT, FC.L.WORLD_TAB .. "  •  " .. scopeTitle)
    safeHeaderSubtitle((selectedZone ~= "" or selectedContinent ~= "") and FC.L.ZONE_RESULTS or FC.L.ZONE_OVERVIEW)
    if worldZoneHint then worldZoneHint:Hide() end
    if worldContinentButton then
        worldContinentButton:SetText(selectedContinent ~= "" and selectedContinent or FC.L.WORLD_ALL_CONTINENTS)
        worldContinentButton:SetShown(activeView == "world")
    end
    if worldZoneButton then
        worldZoneButton:SetText(selectedZone ~= "" and selectedZone or FC.L.ZONE_ALL)
        worldZoneButton:SetShown(activeView == "world")
    end
    if worldCharacterButton then
        local label = FC.L.WORLD_ALL_CHARACTERS
        if selectedCharacter ~= "account" then
            local profile = FC.db.characters[selectedCharacter]
            label = profile and profile.identity and profile.identity.name or selectedCharacter
        end
        worldCharacterButton:SetText(label)
        worldCharacterButton:SetShown(activeView == "world")
    end
    if worldSearchBox then worldSearchBox:SetShown(activeView == "world") end
    for key, button in pairs(worldFilterButtons) do
        button:SetAlpha(key == worldKind and 1 or 0.58)
        button:SetShown(activeView == "world")
        button.selected:SetShown(key == worldKind)
        button.label:SetTextColor(key == worldKind and 1 or 0.83, key == worldKind and 0.88 or 0.86, key == worldKind and 0.57 or 0.89)
        if worldKind == key then button:Disable() else button:Enable() end
    end
    local rowIndex = 1
    local shown, count = 0, 0
    local function addWorldResult(result, title, subtitle, kind, locationsForMap, icon)
        local location = result.location
        local savedLocations = locationsForMap or mapLocationsForResult(result)
        if selectedZone ~= "" or selectedContinent ~= "" then
            local matchingLocations = {}
            for _, saved in ipairs(savedLocations) do
                local zoneMatches = selectedZone == "" or lower(saved.zone or saved.subZone or "") == lower(selectedZone)
                local continentMatches = selectedContinent == "" or lower(continentForLocation(saved)) == lower(selectedContinent)
                if zoneMatches and continentMatches then
                    table.insert(matchingLocations, saved)
                end
            end
            if #matchingLocations > 0 then
                savedLocations = matchingLocations
                location = matchingLocations[1]
            elseif location and (selectedZone == "" or lower(location.zone or location.subZone or "") == lower(selectedZone))
                and (selectedContinent == "" or lower(continentForLocation(location)) == lower(selectedContinent)) then
                savedLocations = { location }
            else
                return
            end
        end
        if textQuery ~= "" and not lower((title or "") .. " " .. (subtitle or "")):find(textQuery, 1, true) then return end
        local mappedKind = kind or result.kind
        if selectedCharacter ~= "account" then
            local record = result.record or {}
            local belongsToCharacter = result.characterKey == selectedCharacter
                or (type(record.characters) == "table" and record.characters[selectedCharacter] ~= nil)
                or (type(record.completedBy) == "table" and record.completedBy[selectedCharacter] ~= nil)
                or (type(record.acceptedBy) == "table" and record.acceptedBy[selectedCharacter] ~= nil)
            if not belongsToCharacter then
                for _, saved in ipairs(savedLocations) do
                    if saved.characterKey == selectedCharacter
                        or (type(saved.characters) == "table" and saved.characters[selectedCharacter]) then
                        belongsToCharacter = true
                        break
                    end
                end
            end
            if not belongsToCharacter then return end
            local ownedLocations = {}
            for _, saved in ipairs(savedLocations) do
                if saved.characterKey == selectedCharacter
                    or (type(saved.characters) == "table" and saved.characters[selectedCharacter]) then
                    table.insert(ownedLocations, saved)
                end
            end
            if #ownedLocations > 0 then savedLocations = ownedLocations; location = ownedLocations[1] end
        end
        local quality = tonumber(result.record and result.record.quality)
        local accepted = worldKind == "all"
            or (worldKind == "ore" and mappedKind == "ore")
            or (worldKind == "herb" and mappedKind == "herb")
            or (worldKind == "fishing" and mappedKind == "fishing")
            or (worldKind == "treasure" and mappedKind == "treasure")
            or (worldKind == "quests" and mappedKind == "quests")
            or (worldKind == "questflow" and mappedKind == "questflow")
            or (worldKind == "items" and mappedKind == "items")
            or (worldKind == "item_uncommon" and mappedKind == "items" and quality == 2)
            or (worldKind == "item_rare" and mappedKind == "items" and quality == 3)
            or (worldKind == "item_epic" and mappedKind == "items" and quality == 4)
            or (worldKind == "rares" and mappedKind == "rares")
            or (worldKind == "npcs" and mappedKind == "npcs")
            or (worldKind == "merchant" and mappedKind == "merchant")
            or (worldKind == "trainer" and mappedKind == "trainer")
            or (worldKind == "dungeons" and mappedKind == "dungeons")
            or (worldKind == "notes" and mappedKind == "note")
        if not accepted then return end
        count = count + 1
        if mappedKind == "questflow" then title = string.format("%s · %s", formatTime(result.ts), title or FC.L.QUEST_COMPLETED) end
        local sortKey = table.concat({ location and location.continent or "", location and location.zone or "", title or "" }, "\t")
        table.insert(worldRows, { result = result, title = title or result.title or result.kind, subtitle = subtitle or "", kind = mappedKind,
            locations = savedLocations, icon = icon, sortKey = sortKey })
    end

    worldRows = {}
    local function categoryOfResource(node)
        return node.kind == "ore" and "ore" or node.kind == "herb" and "herb" or node.kind == "fishing" and "fishing"
            or node.kind == "treasure" and "treasure" or "atlas"
    end
    for _, node in pairs(FC.db.atlas and FC.db.atlas.nodes or {}) do
        local location = { mapID=node.mapID, continent=node.continent, zone=node.zone, subZone=node.subZone, x=node.x, y=node.y }
        addWorldResult({ location=location, ts=node.lastSeen, kind=categoryOfResource(node), locations={location}, record=node }, node.name,
            table.concat({node.continent or "", node.zone or "", FC:FormatLocation(location), string.format(FC.L.FINDS, node.count or 1)}, "  •  "),
            categoryOfResource(node), {location}, node.icon)
    end
    local allMemoryResults = FC:SearchMemory("")
    for _, result in ipairs(allMemoryResults) do
        if result.kind == "rares" or result.kind == "npcs"
            or result.kind == "dungeons" or result.kind == "note" or result.kind == "merchant" or result.kind == "trainer" then
            local kind = result.kind
            addWorldResult(result, result.title, result.subtitle, kind, result.locations or (result.record and result.record.locations) or {result.location},
                kind == "rares" and "Interface\\Icons\\INV_Misc_Head_Dragon_01"
                    or kind == "note" and "Interface\\Icons\\INV_Misc_Book_09")
        end
    end

    -- Present account items once, with their real loot/vendor locations merged
    -- across characters. Inventory scans never contribute map coordinates.
    local mergedItems = {}
    for characterKey, profile in pairs(FC.db.characters or {}) do
        for itemID, record in pairs(profile.observed and profile.observed.items or {}) do
            local key = tostring(itemID)
            local merged = mergedItems[key]
            if not merged then
                merged = { id = itemID, name = record.name or key, quality = tonumber(record.quality), icon = record.icon,
                    locations = {}, characters = {}, count = 0, lastSeen = 0 }
                mergedItems[key] = merged
            end
            merged.name = merged.name ~= key and merged.name or record.name or merged.name
            merged.quality = merged.quality or tonumber(record.quality)
            merged.icon = merged.icon or record.icon
            merged.characters[characterKey] = true
            merged.count = merged.count + (tonumber(record.count) or 0)
            merged.lastSeen = math.max(merged.lastSeen, tonumber(record.lastSeen) or 0)
            for _, location in ipairs(FC.GetItemMapLocations and FC:GetItemMapLocations(record) or {}) do
                local duplicate = false
                for _, previous in ipairs(merged.locations) do
                    if previous.mapID == location.mapID and previous.x == location.x and previous.y == location.y then
                        previous.characters = previous.characters or {}
                        previous.characters[characterKey] = true
                        duplicate = true
                        break
                    end
                end
                if not duplicate then
                    local copy = {}
                    for field, value in pairs(location) do copy[field] = value end
                    copy.characters = { [characterKey] = true }
                    table.insert(merged.locations, copy)
                end
            end
        end
    end
    for itemID, item in pairs(mergedItems) do
        table.sort(item.locations, function(a, b)
            if a.mapID ~= b.mapID then return (a.mapID or 0) < (b.mapID or 0) end
            if a.y ~= b.y then return (a.y or 0) < (b.y or 0) end
            return (a.x or 0) < (b.x or 0)
        end)
        local characters = {}
        for characterKey in pairs(item.characters) do table.insert(characters, characterKey) end
        table.sort(characters)
        local location = item.locations[#item.locations]
        local record = { id = itemID, name = item.name, quality = item.quality, icon = item.icon,
            locations = item.locations, count = item.count, characters = item.characters }
        local result = { id = itemID, kind = "items", title = "[" .. FC.L.ACCOUNT_ITEM .. "] " .. item.name,
            subtitle = table.concat({ table.concat(characters, ", "), string.format(FC.L.LOCATIONS_COUNT, #item.locations) }, "  •  "),
            ts = item.lastSeen, location = location, locations = item.locations, record = record,
            characterKey = "account", accountWide = true }
        addWorldResult(result, result.title, result.subtitle, "items", item.locations, item.icon)
    end
    for _, result in ipairs(locations) do
        if result.kind ~= "atlas" and result.kind ~= "zones" and result.kind ~= "rares" and result.kind ~= "npcs"
            and result.kind ~= "items" and result.kind ~= "dungeons" and result.kind ~= "note"
            and result.kind ~= "merchant" and result.kind ~= "trainer" then addWorldResult(result, result.title,
            table.concat({result.characterKey or "", FC:FormatLocation(result.location), result.detail or ""}, "  •  "), result.kind) end
    end
    for _, quest in ipairs(FC:GetQuestArchive()) do
        local record = quest.record or {}
        local allLocations = record.locations or {}
        local mapLocations, location = {}, nil
        for _, saved in ipairs(allLocations) do
            local belongs = selectedCharacter == "account"
                or (type(saved.characters) == "table" and saved.characters[selectedCharacter])
            local zoneMatches = selectedZone == "" or lower(saved.zone or saved.subZone or "") == lower(selectedZone)
            local continentMatches = selectedContinent == "" or lower(continentForLocation(saved)) == lower(selectedContinent)
            if belongs and zoneMatches and continentMatches then
                table.insert(mapLocations, saved)
                location = location or saved
            end
        end
        if not location and selectedCharacter == "account" and #allLocations == 0 then location = quest.location end
        if location and (worldKind == "quests" or worldKind == "all") then
            addWorldResult({location=location, ts=quest.lastCompleted, kind="quests", locations=mapLocations,
                    record=record, characterKey="account"}, quest.name,
                table.concat({location.continent or quest.continent or "", location.zone or quest.zone or "", FC:FormatLocation(location), formatTime(quest.lastCompleted)}, "  •  "), "quests", mapLocations, "Interface\\Icons\\INV_Misc_Note_02")
        end
    end
    if worldKind == "questflow" then
        for characterKey, sourceProfile in pairs(FC.db.characters or {}) do
            if selectedCharacter == "account" or characterKey == selectedCharacter then
                for index = #(sourceProfile.events or {}), 1, -1 do
                    local event = sourceProfile.events[index]
                    if event.type == "QUEST_COMPLETED" and event.location
                        and (selectedZone == "" or lower(event.location.zone or event.location.subZone or "") == lower(selectedZone)) then
                        local title = event.title or FC.L.QUEST_COMPLETED
                        local synthetic = {location=event.location, ts=event.ts, kind="questflow", characterKey=characterKey}
                        addWorldResult(synthetic, title,
                            table.concat({characterKey, FC.L.ZONE_QUEST_FLOW, formatTime(event.ts), FC:FormatLocation(event.location)}, "  •  "),
                            "questflow", {event.location}, "Interface\\Icons\\INV_Misc_Note_02")
                    end
                end
            end
        end
    end
    table.sort(worldRows, function(a,b)
        if a.kind == "questflow" and b.kind == "questflow" and a.result.ts ~= b.result.ts then
            return (a.result.ts or 0) < (b.result.ts or 0)
        end
        return lower(a.sortKey) < lower(b.sortKey)
    end)
    local pageSize, total = 30, #worldRows
    local maxOffset = math.max(0, math.floor((total - 1) / pageSize) * pageSize)
    worldOffset = math.min(math.max(0, worldOffset), maxOffset)
    local first, last = worldOffset + 1, math.min(total, worldOffset + pageSize)
    local function addWorldPager(label, nextOffset)
        addRow(rowIndex, label, "", {0.92,0.76,0.38}, "Interface\\Icons\\INV_Misc_Map_01",
            total > 0 and string.format(FC.L.WORLD_PAGE_RANGE, first, last, total) or "", function()
                worldOffset = nextOffset
                if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
                persistUIState()
                renderWorld()
            end)
        rowIndex = rowIndex + 1
    end
    if worldOffset > 0 then addWorldPager(FC.L.WORLD_SHOW_NEWER, math.max(0, worldOffset - pageSize)) end
    for itemIndex = first, last do
        local item = worldRows[itemIndex]
        local color = item.kind == "note" and EVENT_COLORS.NOTE or (item.kind == "quests" or item.kind == "questflow") and EVENT_COLORS.QUEST_COMPLETED
            or ((item.kind == "atlas" or item.kind == "ore" or item.kind == "herb" or item.kind == "fishing" or item.kind == "treasure") and EVENT_COLORS.GATHER)
            or item.kind == "rares" and EVENT_COLORS.RARE or {0.40,0.72,1.00}
        addRow(rowIndex, item.title, item.subtitle, color, item.icon or (item.kind == "ore" and "Interface\\Icons\\Trade_Mining")
            or item.kind == "herb" and "Interface\\Icons\\INV_Misc_Flower_02" or item.kind == "quests" and "Interface\\Icons\\INV_Misc_Note_02"
            or item.kind == "note" and "Interface\\Icons\\INV_Misc_Book_09" or "Interface\\Icons\\INV_Misc_Map_01",
            formatTime(item.result.ts), function()
                if item.locations and #item.locations > 0 then
                    FC:ShowLocationsOnMap(item.title, item.kind, item.locations, item.icon,
                        item.result.record and item.result.record.quality)
                end
            end)
        rowIndex, shown = rowIndex + 1, shown + 1
    end
    if last < total then addWorldPager(FC.L.WORLD_SHOW_OLDER, worldOffset + pageSize) end
    if shown == 0 then
        addRow(1, FC.L.ZONE_EMPTY, selectedZone == "" and FC.L.ZONE_OVERVIEW or selectedZone, {0.55,0.55,0.55}, "Interface\\Icons\\INV_Misc_Map_01")
        rowIndex = 2
    end
    finishRows(rowIndex - 1)
end

local function renderQuests()
    setListLayout(false)
    clearRows()
    local quests = FC:GetQuestArchive()
    setHeader(FC.L.QUEST_ARCHIVE, string.format("%d %s", #quests, FC.L.QUEST_COMPLETED))
    local rowIndex = 1
    for _, quest in ipairs(quests) do
        local record = quest.record or {}
        local completedBy = {}
        for characterKey, character in pairs(record.completedBy or {}) do
            table.insert(completedBy, character.name or characterKey)
        end
        table.sort(completedBy)
        local name = quest.name or string.format(FC.L.QUEST_ID, tostring(quest.id))
        if quest.englishName and quest.englishName ~= name then
            name = name .. "  |cffaaaaaa(" .. quest.englishName .. ")|r"
        end
        local location = quest.location
        local locationText = location and FC:FormatLocation(location) or ""
        local acceptedLocations = record.acceptedLocations or {}
        local acceptedLocation = acceptedLocations[#acceptedLocations]
        local acceptedText = acceptedLocation and FC:FormatLocation(acceptedLocation) or ""
        local objectiveText = {}
        for _, objective in pairs(record.objectives or {}) do
            if objective.text and objective.text ~= "" then
                table.insert(objectiveText, objective.text)
            end
        end
        table.sort(objectiveText)
        local subtitle = table.concat({
            quest.continent or "", quest.zone or "", locationText,
            acceptedText ~= "" and (FC.L.QUEST_ACCEPTED_AT .. ": " .. acceptedText) or "",
            FC.L.QUEST_COMPLETED_BY .. ": " .. table.concat(completedBy, ", "),
            #objectiveText > 0 and table.concat(objectiveText, ", ") or "",
        }, "  •  ")
        addRow(rowIndex, name, subtitle, EVENT_COLORS.QUEST_COMPLETED,
            "Interface\\Icons\\INV_Misc_Note_02", "#" .. tostring(quest.id),
            function(_, button)
                if button == "RightButton" then
                    FC:OpenMemory(name)
                elseif location and location.x then
                    FC:ShowLocationsOnMap(name, "quests", record.locations or { location }, "Interface\\Icons\\INV_Misc_Note_02")
                end
            end)
        rowIndex = rowIndex + 1
    end
    if #quests == 0 then
        addRow(1, FC.L.NO_RESULTS, FC.L.QUEST_TRANSLATION_PENDING, { 0.55, 0.55, 0.55 },
            "Interface\\Icons\\INV_Misc_Note_02")
        rowIndex = 2
    end
    finishRows(rowIndex - 1)
end

local function renderCompanions()
    setListLayout(false)
    clearRows()
    local companions = FC:GetCompanions(250)
    setHeader(FC.L.COMPANIONS, string.format("%d %s", #companions, FC.L.COMPANIONS))
    local rowIndex = 1
    for _, companion in ipairs(companions) do
        local characters = {}
        for characterName in pairs(companion.characters or {}) do table.insert(characters, characterName) end
        table.sort(characters)
        local subtitle = #characters > 0
            and string.format(FC.L.COMPANION_WITH_CHARACTER, table.concat(characters, ", ")) or ""
        addRow(rowIndex, companion.name or companion.key, subtitle, { 0.55, 0.88, 0.65 },
            "Interface\\Icons\\INV_Misc_GroupNeedMore", formatTime(companion.lastSeen), function()
                FC:OpenMemory(companion.name or companion.key)
            end)
        rowIndex = rowIndex + 1
    end
    if #companions == 0 then
        addRow(1, FC.L.NO_COMPANIONS, "", { 0.55, 0.55, 0.55 }, "Interface\\Icons\\INV_Misc_GroupNeedMore")
        rowIndex = 2
    end
    finishRows(rowIndex - 1)
end

local function renderStatistics()
    setListLayout(false)
    clearRows()
    local events = FC.profile and FC.profile.events or {}
    local counts = {}
    for _, event in ipairs(events) do
        counts[event.type] = (counts[event.type] or 0) + 1
    end
    local areaCount = (counts.ZONE or 0) + (counts.SUBZONE_DISCOVERED or 0)
        + (counts.CONTINENT_DISCOVERED or 0)
    local activity = {}
    local function activityFor(kind, name)
        if not name or name == "" then return nil end
        local key = kind .. ":" .. name
        activity[key] = activity[key] or { kind = kind, name = name, visits = 0, deaths = 0, resurrections = 0 }
        return activity[key]
    end
    for _, event in ipairs(events) do
        local data = event.data or {}
        if event.type == "DUNGEON" then
            local kind = data.instanceType == "raid" and "raid" or "instance"
            local item = activityFor(kind, data.instanceName or (event.title or ""):match(":%s*(.+)$"))
            if item then item.visits = item.visits + 1 end
        elseif event.type == "BOSS_DEFEATED" then
            local kind = data.instanceType == "raid" and "raid" or "instance"
            activityFor(kind, data.instanceName)
        elseif event.type == "BATTLEGROUND" or event.type == "ARENA" then
            local kind = event.type == "BATTLEGROUND" and "battleground" or "arena"
            local item = activityFor(kind, data.instanceName or (event.title or ""):match(":%s*(.+)$"))
            if item then item.visits = item.visits + 1 end
        elseif event.type == "DEATH" or event.type == "RESURRECTION" then
            local kind = data.instanceType == "pvp" and "battleground"
                or data.instanceType == "arena" and "arena"
                or data.instanceType == "raid" and "raid"
                or (data.instanceType == "party" and "instance" or nil)
            local place = data.instanceName or (event.location and event.location.zone)
            if not kind and place then
                for _, candidate in ipairs({ "instance", "raid", "battleground", "arena" }) do
                    if activity[candidate .. ":" .. place] then kind = candidate; break end
                end
            end
            local item = kind and activityFor(kind, place)
            if item then
                if event.type == "DEATH" then item.deaths = item.deaths + 1
                else item.resurrections = item.resurrections + 1 end
            end
        end
    end
    local rows = {
        { "STAT_LEVELS", counts.LEVEL or 0, "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { "STAT_QUESTS", counts.QUEST_COMPLETED or 0, "Interface\\Icons\\INV_Misc_Note_02" },
        { "STAT_AREAS", areaCount, "Interface\\Icons\\INV_Misc_Map_01" },
        { "STAT_BOSS_VICTORIES", counts.BOSS_DEFEATED or 0, "Interface\\Icons\\Achievement_Boss_Illidan" },
        { "STAT_INSTANCES", counts.DUNGEON or 0, "Interface\\Icons\\Ability_DualWield" },
        { "STAT_RAIDS", (function() local n=0; for _, event in ipairs(events) do if event.type == "DUNGEON" and event.data and event.data.instanceType == "raid" then n=n+1 end end; return n end)(), "Interface\\Icons\\Achievement_GuildPerk_MonsterSlaying" },
        { "STAT_BATTLEGROUNDS", counts.BATTLEGROUND or 0, "Interface\\Icons\\INV_BannerPVP_02" },
        { "STAT_ARENAS", counts.ARENA or 0, "Interface\\Icons\\Achievement_Arena_2v2_7" },
        { "STAT_RARES", counts.RARE or 0, "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
        { "STAT_KILLS", counts.KILL or 0, "Interface\\Icons\\Ability_Creature_Cursed_03" },
        { "STAT_GATHERING", counts.GATHER or 0, "Interface\\Icons\\Trade_Herbalism" },
        { "STAT_ITEMS", counts.ITEM or 0, "Interface\\Icons\\INV_Misc_Bag_10" },
        { "STAT_MERCHANTS", counts.MERCHANT or 0, "Interface\\Icons\\INV_Misc_Coin_01" },
        { "STAT_TRAINERS", counts.TRAINER or 0, "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" },
        { "STAT_DEATHS", counts.DEATH or 0, "Interface\\Icons\\Ability_Rogue_FeignDeath" },
        { "STAT_RESURRECTIONS", counts.RESURRECTION or 0, "Interface\\Icons\\Spell_Holy_Resurrection" },
        { "STAT_HEALING", counts.HEALTH_RECOVERY or 0, "Interface\\Icons\\Spell_Holy_FlashHeal" },
        { "STAT_EATING", counts.EAT or 0, "Interface\\Icons\\INV_Misc_Food_15" },
        { "STAT_DRINKING", counts.DRINK or 0, "Interface\\Icons\\INV_Drink_07" },
    }
    setHeader(FC.L.STATISTICS, FC.L.STATISTICS_HELP)
    for index, item in ipairs(rows) do
        addRow(index, FC.L[item[1]], "", { 0.88, 0.78, 0.52 }, item[3], tostring(item[2]))
    end
    local rowIndex = #rows + 1
    addRow(rowIndex, FC.L.STAT_ACTIVITY, "", { 0.98, 0.79, 0.34 }, "Interface\\Icons\\INV_Misc_Map_01")
    rowIndex = rowIndex + 1
    local activities = {}
    for _, item in pairs(activity) do table.insert(activities, item) end
    table.sort(activities, function(a,b)
        if a.kind ~= b.kind then return a.kind < b.kind end
        return a.name < b.name
    end)
    local kindLabels = {
        instance = FC.L.STAT_INSTANCE_LABEL, raid = FC.L.STAT_RAID_LABEL,
        battleground = FC.L.STAT_BATTLEGROUND_LABEL, arena = FC.L.STAT_ARENA_LABEL,
    }
    for _, item in ipairs(activities) do
        local detail = string.format(FC.L.STAT_ACTIVITY_DETAIL, kindLabels[item.kind],
            item.visits, item.deaths, item.resurrections)
        addRow(rowIndex, item.name, detail, { 0.82, 0.76, 0.62 }, "Interface\\Icons\\INV_Misc_Map_01", tostring(item.visits))
        rowIndex = rowIndex + 1
        if item.kind == "instance" or item.kind == "raid" then
            local bosses = {}
            for _, dungeon in pairs(FC.profile.observed and FC.profile.observed.dungeons or {}) do
                if dungeon.name == item.name then
                    for _, boss in pairs(dungeon.bosses or {}) do bosses[#bosses + 1] = boss end
                end
            end
            table.sort(bosses, function(a, b) return lower(a.name) < lower(b.name) end)
            for _, boss in ipairs(bosses) do
                addRow(rowIndex, "  " .. (boss.name or "?"),
                    string.format(FC.L.STAT_BOSS_DETAIL, boss.victories or 0,
                        boss.lastDefeated and date("%d.%m.%Y", boss.lastDefeated) or "?"),
                    { 0.95, 0.69, 0.37 }, "Interface\\Icons\\Achievement_Boss_Illidan")
                rowIndex = rowIndex + 1
            end
        end
    end
    if #activities == 0 then
        addRow(rowIndex, FC.L.STAT_ACTIVITY_EMPTY, "", { 0.55, 0.55, 0.55 }, "Interface\\Icons\\INV_Misc_Map_01")
        rowIndex = rowIndex + 1
    end
    finishRows(rowIndex - 1)
end

local function renderDiscoveries()
    setListLayout(false)
    clearRows()
    local discoveries = FC.profile and FC.profile.discoveries or {}
    setHeader(FC.L.DISCOVERIES, string.format("%d %s", #discoveries, FC.L.DISCOVERIES))
    addRow(1, FC.L.COLLECTOR_MODE, string.format(FC.L.DATABASE_VERSION, tostring(FC.db.databaseVersion or 0)), { 0.75, 0.58, 1.00 }, "Interface\\Icons\\INV_Misc_QuestionMark")
    local rowIndex = 2
    for index = #discoveries, 1, -1 do
        local discovery = discoveries[index]
        local title = string.format("[%s] %s  (#%s)", discovery.kind or "?", discovery.name or FC.L.UNKNOWN, tostring(discovery.id or "?"))
        local subtitle = table.concat({ formatTime(discovery.ts), FC:FormatLocation(discovery.location), discovery.source or "" }, "  •  ")
        local location = discovery.location
        addRow(rowIndex, title, subtitle, { 0.72, 0.48, 1.00 }, "Interface\\Icons\\INV_Misc_QuestionMark", discovery.kind,
            location and location.x and function()
                FC:ShowLocationsOnMap(title, discovery.kind or "event", { location },
                    "Interface\\Icons\\INV_Misc_QuestionMark")
            end or nil)
        rowIndex = rowIndex + 1
    end
    if #discoveries == 0 then
        addRow(rowIndex, FC.L.NO_DISCOVERIES, "", { 0.55, 0.55, 0.55 })
        rowIndex = rowIndex + 1
    end
    finishRows(rowIndex - 1)
end

local function renderCharacters()
    setListLayout(false)
    clearRows()
    local characters = FC:GetCharacters()
    setHeader(FC.L.CHARACTERS, FC.L.ACCOUNT_MEMORY)
    local rowIndex = 1
    for _, character in ipairs(characters) do
        local identity = character.identity
        local title = string.format("%s — %s %s", identity.name or character.key, identity.className or identity.classFile or "", identity.level or "?")
        local subtitle = table.concat({
            FC:FormatLocation(character.location),
            string.format("%d %s", character.events, FC.L.EVENTS),
            string.format("%d %s", character.discoveries, FC.L.DISCOVERIES),
        }, "  •  ")
        addRow(rowIndex, title, subtitle, character.key == FC.characterKey and { 1.00, 0.82, 0.20 } or { 0.84, 0.78, 0.65 },
            "Interface\\Icons\\INV_Misc_GroupNeedMore", formatTime(character.lastSeen), function()
                FC:OpenUI("memory")
                FC:SetUISearch(character.key)
            end)
        rowIndex = rowIndex + 1
    end
    finishRows(rowIndex - 1)
end

local function renderBackup()
    clearRows()
    scrollFrame:Hide()
    searchBox:Hide()
    backupPanel:Show()
    setHeader(FC.L.SETTINGS, FC.L.LOCAL_DATA)
    for key, check in pairs(settingChecks) do
        check:SetChecked(FC.db.settings[key])
    end
    updateDiaryLengthButton()
    if mapSettingsButton then mapSettingsButton:Hide() end
end

local function renderHelp()
    setListLayout(false)
    clearRows()
    setHeader(FC.L.HELP_TITLE, FC.L.HELP_SUBTITLE)
    if not helpText then
        helpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        helpText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -8)
        helpText:SetJustifyH("LEFT")
        helpText:SetJustifyV("TOP")
        helpText:SetWordWrap(true)
        helpText:SetSpacing(3)
        helpText:SetTextColor(0.88, 0.86, 0.78)
    end
    helpText:SetWidth(math.max(200, scrollFrame:GetWidth() - 34))
    helpText:SetText(FC.L.HELP_GUIDE)
    helpText:SetHeight(math.max(1, helpText:GetStringHeight()))
    scrollChild:SetHeight(helpText:GetStringHeight() + 24)
    helpText:Show()
end

local renderers = {
    journey = renderOverview, overview = renderOverview, chronicle = renderChronicle,
    diary = renderDiary,
    memory = renderMemory, world = renderWorld, companions = renderCompanions,
    quests = renderQuests,
    statistics = renderStatistics,
    discoveries = renderDiscoveries, characters = renderCharacters,
    settings = renderBackup, backup = renderBackup, help = renderHelp,
}

function FC:RenderUI(view)
    if not frame or not frame:IsShown() then
        return
    end
    if searchBox then
        local currentQuery = searchBox:GetText() or ""
        if activeView == "diary" then diaryQuery = currentQuery
        elseif activeView == "memory" then memoryQuery = currentQuery end
    end
    if view == "today" or view == "overview" then view = "journey" end
    if view == "export" or view == "backup" then view = "settings" end
    if view == "characters" then view = "companions" end
    if self.RefreshCharacterIdentity then self:RefreshCharacterIdentity() end
    activeView = renderers[view] and view or activeView
    if activeView == "chronicle" and self.profile then
        local savedOffset = self.profile.uiState and tonumber(self.profile.uiState.chronicleOffset)
        if savedOffset then chronicleOffset = savedOffset end
    end
    if searchBox then
        local nextQuery = activeView == "diary" and diaryQuery or activeView == "memory" and memoryQuery or ""
        if searchBox:GetText() ~= nextQuery then
            searchContextChanging = true
            searchBox:SetText(nextQuery)
            searchContextChanging = false
        end
        if searchBox.Instructions then
            searchBox.Instructions:SetText(activeView == "diary" and FC.L.DIARY_SEARCH or FC.L.SEARCH_PLACEHOLDER)
            searchBox.Instructions:SetShown(nextQuery == "")
        end
    end
    persistUIState()
    for key, button in pairs(categoryButtons) do
        local selected = key == (activeView == "world" and "memory" or activeView)
        button.selected:SetShown(selected)
        button.selectedEdge:SetShown(selected)
        button.label:SetTextColor(selected and 1.00 or 0.82, selected and 0.84 or 0.78, selected and 0.42 or 0.68)
    end
    for key, button in pairs(quickButtons) do
        button:SetEnabled(key ~= (activeView == "world" and "memory" or activeView))
    end
    updateAccountSummary()
    if characterIdentityText and FC.profile then
        local identity = FC.profile.identity or {}
        local name = UnitName("player")
        if FC:IsSecret(name) or type(name) ~= "string" or name == "" then name = identity.name end
        if FC:IsSecret(name) or type(name) ~= "string" or name == "" or name:lower() == "unknown" or name:lower() == "unbekannt" then name = FC.L.UNKNOWN_CHARACTER end
        local class = identity.className
        if not class and UnitClass then class = UnitClass("player") end
        if FC:IsSecret(class) or type(class) ~= "string" then class = "" end
        local level = (FC.demoMode and identity.level) or FC:GetPlayerLevel() or identity.level or 0
        if FC:IsSecret(level) or type(level) ~= "number" then level = type(identity.level) == "number" and identity.level or 0 end
        characterIdentityText:SetText(string.format("%s\n|cffffd36a%s %d · %s|r", name, FC.L.LEVEL_SHORT, level, class))
    end
    if helpText then helpText:Hide() end
    renderers[activeView]()
    for key, button in pairs(memorySectionButtons) do
        local selected = key == activeView
        button:SetShown(activeView == "memory" or activeView == "world")
        if button.SetEnabled then button:SetEnabled(not selected) end
    end
    if mapSettingsButton then mapSettingsButton:SetShown(activeView ~= "settings" and activeView ~= "help") end
    for _, button in pairs(memoryFilterButtons) do button:SetShown(activeView == "memory") end
    for index, button in ipairs(merchantFilterButtons) do
        button:SetShown(activeView == "memory" and (memoryKind == "merchant" or (memoryKind == "trainer" and index ~= 3)))
    end
    if worldContinentButton then worldContinentButton:SetShown(activeView == "world") end
    if worldZoneButton then worldZoneButton:SetShown(activeView == "world") end
    if worldCharacterButton then worldCharacterButton:SetShown(activeView == "world") end
    if worldChoiceMenu and activeView ~= "world" and activeView ~= "memory" then worldChoiceMenu:Hide() end
    for _, button in pairs(worldFilterButtons) do button:SetShown(activeView == "world") end
    if worldSearchBox then worldSearchBox:SetShown(activeView == "world") end
end

function FC:RefreshUI()
    -- Recording can happen from combat-log events. Never rebuild the visible
    -- interface from those callbacks during combat; keep the data immediately
    -- and redraw once protected Blizzard UI has returned to its normal state.
    if InCombatLockdown and InCombatLockdown() then
        self.pendingUIRefresh = true
        return
    end
    self.pendingUIRefresh = false
    if frame and frame:IsShown() then
        self:RenderUI(activeView)
    end
end

FC:RegisterEvent("PLAYER_REGEN_ENABLED", function(self)
    if self.pendingUIRefresh then self:RefreshUI() end
end)

function FC:SetUISearch(query)
    if not searchBox then
        return
    end
    searchBox:SetText(query or "")
    searchBox:SetCursorPosition(0)
    memoryOffset = 0
    persistUIState()
    if activeView == "memory" then
        renderMemory()
    end
end

local function createCategory(key, label, icon, index)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(180, 38)
    -- Leave a dedicated two-line identity area beneath the portrait. The old
    -- first navigation row started inside the level/class text and covered it.
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -132 - ((index - 1) * 41))

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetAllPoints()
    button.background:SetColorTexture(0.075, 0.055, 0.035, 0.94)
    button.selected = button:CreateTexture(nil, "BORDER")
    button.selected:SetPoint("TOPLEFT", 2, -2)
    button.selected:SetPoint("BOTTOMRIGHT", -2, 2)
    button.selected:SetColorTexture(0.34, 0.23, 0.085, 0.96)
    button.selected:Hide()
    button.selectedEdge = button:CreateTexture(nil, "OVERLAY")
    button.selectedEdge:SetPoint("TOPLEFT", 2, -5)
    button.selectedEdge:SetPoint("BOTTOMLEFT", 2, 5)
    button.selectedEdge:SetWidth(3)
    button.selectedEdge:SetColorTexture(0.96, 0.70, 0.22, 1)
    button.selectedEdge:Hide()
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.90, 0.68, 0.20, 0.18)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("LEFT", 7, 0)
    button.icon:SetSize(26, 26)
    button.icon:SetTexture(icon)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 9, 0)
    button.label:SetPoint("RIGHT", button, "RIGHT", -7, 0)
    button.label:SetWordWrap(false)
    button.label:SetText(label)
    button.label:SetTextColor(0.86, 0.88, 0.91)

    button:SetScript("OnClick", function()
        FC:RenderUI(key)
    end)
    categoryButtons[key] = button
end

local function createSettingCheck(key, label, x, y, onClick)
    local check = CreateFrame("CheckButton", nil, backupPanel, "UICheckButtonTemplate")
    check:SetPoint("BOTTOMLEFT", backupPanel, "BOTTOMLEFT", x, y)
    check:SetSize(24, 24)
    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.text:SetPoint("LEFT", check, "RIGHT", 3, 0)
    check.text:SetWidth(255)
    check.text:SetJustifyH("LEFT")
    check.text:SetText(label)
    check:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        if onClick then
            onClick(checked)
        else
            FC.db.settings[key] = checked
        end
        FC:TouchData("setting:" .. tostring(key))
        if FC.RefreshUI then FC:RefreshUI() end
    end)
    settingChecks[key] = check
end

local function createUIFilters()
    local filterLabels = {
        all = FC.L.CATEGORY_ALL, quests = FC.L.QUESTS_SHORT, items = FC.L.ITEM_LABEL,
        atlas = FC.L.ATLAS, rares = FC.L.RARES_SHORT, note = FC.L.NOTE_LABEL,
        npc = FC.L.NPC, merchant = FC.L.MERCHANT, trainer = FC.L.TRAINER,
        companion = FC.L.COMPANION_LABEL, profession = FC.L.PROFESSION,
    }
    local memoryFilterWidth, memoryFilterStep = 112, 116
    for index, key in ipairs(memoryFilterNames) do
        local button = CreateFrame("Button", nil, content)
        local column = (index - 1) % 5
        local row = math.floor((index - 1) / 5)
        button:SetSize(memoryFilterWidth, 22)
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 16 + (column * memoryFilterStep), -117 - (row * 24))
        button.background = button:CreateTexture(nil, "BACKGROUND")
        button.background:SetAllPoints()
        button.background:SetColorTexture(0.075, 0.055, 0.035, 0.94)
        button.selected = button:CreateTexture(nil, "BORDER")
        button.selected:SetAllPoints()
        button.selected:SetColorTexture(0.55, 0.37, 0.12, 0.60)
        button.selected:Hide()
        button.edge = button:CreateTexture(nil, "BORDER")
        button.edge:SetPoint("BOTTOMLEFT")
        button.edge:SetPoint("BOTTOMRIGHT")
        button.edge:SetHeight(1)
        button.edge:SetColorTexture(0.53, 0.42, 0.24, 1)
        button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
        button.highlight:SetAllPoints()
        button.highlight:SetColorTexture(0.90, 0.68, 0.20, 0.20)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER")
        button.label:SetWidth(memoryFilterWidth - 4)
        button.label:SetWordWrap(false)
        button.label:SetTextColor(0.88, 0.90, 0.91)
        button.label:SetText(filterLabels[key] or key)
        button:SetScript("OnClick", function()
            memoryKind = key
            memoryOffset = 0
            selectedMerchantKey, selectedMerchantCharacter = nil, nil
            persistUIState()
            if activeView == "memory" then renderMemory() end
        end)
        memoryFilterButtons[key] = button
        button:SetScript("OnShow", function(self)
            local selected = memoryKind == key
            self:SetAlpha(selected and 1 or 0.76)
            self.selected:SetShown(selected)
            self.label:SetTextColor(selected and 1 or 0.83, selected and 0.88 or 0.86, selected and 0.57 or 0.89)
        end)
        button:Hide()
    end

    for index = 1, 4 do
        local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 16 + ((index - 1) % 3) * 192, -190 - math.floor((index - 1) / 3) * 30)
        button:SetSize(185, 27)
        button:SetScript("OnClick", function(self)
            local continents, zones, categories = merchantChoices()
            local values = index == 1 and continents or (index == 2 and zones or (index == 3 and categories or { "Alliance", "Horde" }))
            local emptyLabel = index == 1 and FC.L.WORLD_ALL_CONTINENTS or
                (index == 2 and FC.L.ZONE_ALL or (index == 3 and FC.L.MERCHANT_ALL_GOODS or FC.L.MERCHANT_ALL_FACTIONS))
            local options = { { label = emptyLabel, value = "" } }
            for _, value in ipairs(values) do options[#options + 1] = { label = value, value = value } end
            local selected = index == 1 and merchantContinent or (index == 2 and merchantZone or (index == 3 and merchantCategory or merchantFaction))
            showWorldChoiceMenu(self, options, function(option)
                if index == 1 then merchantContinent = option.value; merchantZone = ""
                elseif index == 2 then merchantZone = option.value
                elseif index == 3 then merchantCategory = option.value
                else merchantFaction = option.value end
                memoryOffset = 0; persistUIState(); renderMemory()
            end, selected)
        end)
        button:Hide()
        merchantFilterButtons[index] = button
    end

    worldContinentButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    worldContinentButton:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -87)
    worldContinentButton:SetSize(154, 27)
    worldContinentButton:SetText(FC.L.WORLD_ALL_CONTINENTS)
    worldContinentButton:SetScript("OnClick", function(self)
        local options = { { label = FC.L.WORLD_ALL_CONTINENTS, value = "" } }
        for _, continent in ipairs(worldContinentChoices) do
            table.insert(options, { label = continent, value = continent })
        end
        showWorldChoiceMenu(self, options, function(option)
            worldOffset = 0
            worldContinent = option.value or ""
            worldZone = ""
            persistUIState()
            renderWorld()
        end, worldContinent)
    end)

    worldZoneButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    worldZoneButton:SetPoint("TOPLEFT", worldContinentButton, "TOPRIGHT", 5, 0)
    worldZoneButton:SetSize(180, 27)
    worldZoneButton:SetText(FC.L.ZONE_ALL)
    worldZoneButton:SetScript("OnClick", function(self)
        local options = { { label = FC.L.ZONE_ALL, value = "" } }
        for _, area in ipairs(worldAreaChoices) do
            if worldContinent == "" or area.continent == worldContinent then
                local label = area.zone
                if worldContinent == "" and area.continent ~= "" then
                    label = area.continent .. "  ·  " .. area.zone
                end
                table.insert(options, { label = label, value = area.zone, continent = area.continent })
            end
        end
        showWorldChoiceMenu(self, options, function(option)
            worldOffset = 0
            worldZone = option.value or ""
            if option.value ~= "" and worldContinent == "" then worldContinent = option.continent or "" end
            persistUIState()
            renderWorld()
        end, worldZone)
    end)

    worldCharacterButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    worldCharacterButton:SetPoint("TOPLEFT", worldZoneButton, "TOPRIGHT", 5, 0)
    worldCharacterButton:SetSize(180, 27)
    worldCharacterButton:SetText(FC.L.WORLD_ALL_CHARACTERS)
    worldCharacterButton:SetScript("OnClick", function(self)
        local options = { { label = FC.L.WORLD_ALL_CHARACTERS, value = "account" } }
        for _, character in ipairs(FC:GetCharacters()) do
            local identity = character.identity or {}
            local label = identity.name or character.key
            if identity.realm and identity.realm ~= "" then label = label .. " · " .. identity.realm end
            table.insert(options, { label = label, value = character.key })
        end
        showWorldChoiceMenu(self, options, function(option)
            worldOffset = 0
            worldCharacter = option.value or "account"
            persistUIState()
            renderWorld()
        end, worldCharacter)
    end)

    local worldLabels = {
        all = FC.L.CATEGORY_ALL, ore = FC.L.MAP_ORE, herb = FC.L.MAP_HERBS,
        fishing = FC.L.MAP_FISHING, treasure = FC.L.MAP_TREASURES, quests = FC.L.QUESTS_SHORT,
        questflow = FC.L.ZONE_QUEST_FLOW_SHORT, items = FC.L.ITEM_LABEL, rares = FC.L.MAP_RARES, npcs = FC.L.MAP_NPCS,
        item_uncommon = FC.L.ITEM_QUALITY_UNCOMMON, item_rare = FC.L.ITEM_QUALITY_RARE,
        item_epic = FC.L.ITEM_QUALITY_EPIC, merchant = FC.L.MERCHANT, trainer = FC.L.TRAINER,
        dungeons = FC.L.MAP_DUNGEONS, entrances = FC.L.MAP_ENTRANCES, notes = FC.L.MAP_NOTES,
    }
    worldSearchBox = CreateFrame("EditBox", nil, content, "SearchBoxTemplate")
    worldSearchBox:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -117)
    worldSearchBox:SetSize(320, 27)
    worldSearchBox:SetAutoFocus(false)
    if worldSearchBox.Instructions then
        worldSearchBox.Instructions:SetText(FC.L.WORLD_NAME_PLACEHOLDER)
        worldSearchBox.Instructions:ClearAllPoints()
        worldSearchBox.Instructions:SetPoint("LEFT", worldSearchBox, "LEFT", 22, 0)
        worldSearchBox.Instructions:SetPoint("RIGHT", worldSearchBox, "RIGHT", -8, 0)
        worldSearchBox.Instructions:SetWordWrap(false)
        worldSearchBox.Instructions:SetJustifyH("LEFT")
    end
    worldSearchBox:SetScript("OnTextChanged", function(self)
        if activeView == "world" then worldOffset = 0 end
        persistUIState()
        if self.Instructions then
            self.Instructions:SetShown(self:GetText() == "")
        end
        if activeView == "world" then
            worldOffset = 0
            searchGeneration = searchGeneration + 1
            local generation = searchGeneration
            local function update() if generation == searchGeneration and activeView == "world" then renderWorld() end end
            if C_Timer and C_Timer.After then C_Timer.After(0.12, update) else update() end
        end
    end)
    worldSearchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    worldSearchBox:Hide()
    for index, key in ipairs(worldFilterNames) do
        local button = CreateFrame("Button", nil, content)
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        button:SetSize(152, 23)
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 16 + column * 160, -147 - row * 26)
        button.background = button:CreateTexture(nil, "BACKGROUND")
        button.background:SetAllPoints()
        button.background:SetColorTexture(0.075, 0.055, 0.035, 0.94)
        button.selected = button:CreateTexture(nil, "BORDER")
        button.selected:SetAllPoints()
        button.selected:SetColorTexture(0.55, 0.37, 0.12, 0.60)
        button.selected:Hide()
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER")
        button.label:SetWidth(148)
        button.label:SetWordWrap(false)
        button.label:SetText(worldLabels[key] or key)
        button.label:SetTextColor(0.88, 0.90, 0.91)
        button:SetScript("OnClick", function() worldKind = key; worldOffset = 0; persistUIState(); if activeView == "world" then renderWorld() end end)
        worldFilterButtons[key] = button
        button:Hide()
    end
    worldSearchBox:ClearAllPoints()
    worldSearchBox:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -117)
    worldSearchBox:SetSize(320, 27)

end

local function createUIPanels()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -283)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -31, 12)
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(630, 1)
    scrollFrame:SetScrollChild(scrollChild)

    backupPanel = CreateFrame("Frame", nil, content)
    backupPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -58)
    backupPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -14, 12)
    backupPanel:Hide()

    local backupCard = CreateFrame("Frame", nil, backupPanel, template)
    backupCard:SetPoint("TOPLEFT", backupPanel, "TOPLEFT", 0, -8)
    backupCard:SetPoint("BOTTOMRIGHT", backupPanel, "BOTTOMRIGHT", -27, 238)
    if backupCard.SetBackdrop then
        backupCard:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        backupCard:SetBackdropColor(0.018, 0.030, 0.050, 0.98)
        backupCard:SetBackdropBorderColor(0.56, 0.43, 0.23, 0.88)
    end

    local backupTitle = backupCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    backupTitle:SetPoint("TOPLEFT", backupCard, "TOPLEFT", 14, -13)
    backupTitle:SetText(FC.L.BACKUP_TITLE)
    backupTitle:SetTextColor(1.00, 0.82, 0.34)

    local backupDescription = backupCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    backupDescription:SetPoint("TOPLEFT", backupTitle, "BOTTOMLEFT", 0, -8)
    backupDescription:SetPoint("RIGHT", backupCard, "RIGHT", -14, 0)
    backupDescription:SetHeight(39)
    backupDescription:SetJustifyH("LEFT")
    backupDescription:SetJustifyV("TOP")
    backupDescription:SetWordWrap(true)
    backupDescription:SetText(FC.L.BACKUP_DESCRIPTION)
    backupDescription:SetTextColor(0.78, 0.80, 0.80)

    local backupPathLabel = backupCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    backupPathLabel:SetPoint("TOPLEFT", backupDescription, "BOTTOMLEFT", 0, -7)
    backupPathLabel:SetText(FC.L.BACKUP_PATH_LABEL)
    backupPathLabel:SetTextColor(0.82, 0.70, 0.47)

    local backupPath = backupCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    backupPath:SetPoint("TOPLEFT", backupPathLabel, "BOTTOMLEFT", 0, -3)
    backupPath:SetPoint("RIGHT", backupCard, "RIGHT", -14, 0)
    backupPath:SetWordWrap(false)
    backupPath:SetText(FC.L.BACKUP_PATH)
    backupPath:SetTextColor(0.68, 0.84, 0.98)

    local backupSteps = backupCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    backupSteps:SetPoint("TOPLEFT", backupPath, "BOTTOMLEFT", 0, -7)
    backupSteps:SetPoint("RIGHT", backupCard, "RIGHT", -14, 0)
    backupSteps:SetHeight(51)
    backupSteps:SetJustifyH("LEFT")
    backupSteps:SetJustifyV("TOP")
    backupSteps:SetWordWrap(true)
    backupSteps:SetText(FC.L.BACKUP_STEPS)
    backupSteps:SetTextColor(0.88, 0.88, 0.84)

    local backupNote = backupCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    backupNote:SetPoint("BOTTOMLEFT", backupCard, "BOTTOMLEFT", 14, 10)
    backupNote:SetPoint("RIGHT", backupCard, "RIGHT", -14, 0)
    backupNote:SetJustifyH("LEFT")
    backupNote:SetWordWrap(true)
    backupNote:SetText(FC.L.BACKUP_NOTE)
    backupNote:SetTextColor(0.48, 0.78, 0.62)

    local recordingSurface = CreateFrame("Frame", nil, backupPanel, template)
    recordingSurface:SetPoint("BOTTOMLEFT", backupPanel, "BOTTOMLEFT", 0, -2)
    recordingSurface:SetPoint("TOPRIGHT", backupPanel, "BOTTOMRIGHT", 0, 224)
    if recordingSurface.SetBackdrop then
        recordingSurface:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        recordingSurface:SetBackdropColor(0.028, 0.045, 0.071, 0.99)
        recordingSurface:SetBackdropBorderColor(0.62, 0.48, 0.25, 0.94)
    end

    local trackingTitle = backupPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    trackingTitle:SetPoint("BOTTOMLEFT", backupPanel, "BOTTOMLEFT", 12, 196)
    trackingTitle:SetText(FC.L.SETTINGS_RECORDING)
    trackingTitle:SetTextColor(1.00, 0.82, 0.34)
    local displayTitle = backupPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    displayTitle:SetPoint("BOTTOMLEFT", backupPanel, "BOTTOMLEFT", 315, 196)
    displayTitle:SetText(FC.L.SETTINGS_DISPLAY)
    displayTitle:SetTextColor(1.00, 0.82, 0.34)
    local collectorButton = CreateFrame("Button", nil, backupPanel, "UIPanelButtonTemplate")
    collectorButton:SetSize(135, 24)
    collectorButton:SetPoint("BOTTOMRIGHT", backupPanel, "BOTTOMRIGHT", -12, 191)
    collectorButton:SetText(FC.L.COLLECTOR_DATA)
    collectorButton:SetScript("OnClick", function() FC:RenderUI("discoveries") end)

    createSettingCheck("minimap", FC.L.MINIMAP_BUTTON_OPTION, 315, 35, function(checked)
        if FC.SetMinimapButtonVisible then
            FC:SetMinimapButtonVisible(checked)
        else
            FC.db.settings.minimap = checked
        end
    end)
    diaryLengthButton = CreateFrame("Button", nil, backupPanel, "UIPanelButtonTemplate")
    diaryLengthButton:SetSize(280, 24)
    diaryLengthButton:SetPoint("BOTTOMLEFT", backupPanel, "BOTTOMLEFT", 315, 7)
    updateDiaryLengthButton()
    diaryLengthButton:SetScript("OnClick", function()
        if not FC.profile then return end
        local length = tonumber(FC.profile.diaryLength) or 4
        length = math.floor(length) % 4 + 1
        FC.profile.diaryLength = length
        FC:TouchData("diary-length")
        updateDiaryLengthButton()
        if activeView == "diary" and FC.RefreshUI then FC:RefreshUI() end
    end)
    diaryLengthButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(FC.L.DIARY_LENGTH_HELP, 1.00, 0.82, 0.20, true)
        GameTooltip:Show()
    end)
    diaryLengthButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    createSettingCheck("trackQuests", FC.L.QUEST_OPTION, 12, 148)
    createSettingCheck("trackZones", FC.L.ZONE_OPTION, 12, 119)
    createSettingCheck("trackNPCs", FC.L.NPC_OPTION, 12, 90)
    createSettingCheck("trackTrainers", FC.L.TRAINER_OPTION, 12, 61)
    createSettingCheck("trackProfessions", FC.L.PROFESSION_OPTION, 12, 32)
    createSettingCheck("trackCompanions", FC.L.COMPANION_OPTION, 12, 3)
    createSettingCheck("trackInventory", FC.L.INVENTORY_OPTION, 315, 148)
    createSettingCheck("showTooltips", FC.L.TOOLTIP_OPTION, 315, 119)
    createSettingCheck("zoneReminders", FC.L.REMINDER_OPTION, 315, 90)
    createSettingCheck("showLoginRecap", FC.L.RECAP_OPTION, 315, 61)

end

local function restoreUIState()
    local saved = FC.profile and FC.profile.uiState or {}
    if type(saved) == "table" then
        if renderers[saved.view] then activeView = saved.view end
        if validFilter(saved.memoryKind, memoryFilterNames) then memoryKind = saved.memoryKind end
        if diaryModeLocaleKeys[saved.diaryMode] then diaryMode = saved.diaryMode end
        if validFilter(saved.worldKind, worldFilterNames) then worldKind = saved.worldKind end
        diaryOffset = math.max(0, tonumber(saved.diaryOffset) or 0)
        memoryOffset = math.max(0, tonumber(saved.memoryOffset) or 0)
        worldOffset = math.max(0, tonumber(saved.worldOffset) or 0)
        if type(saved.merchantContinent) == "string" then merchantContinent = saved.merchantContinent end
        if type(saved.merchantZone) == "string" then merchantZone = saved.merchantZone end
        if type(saved.merchantCategory) == "string" then merchantCategory = saved.merchantCategory end
        if type(saved.merchantFaction) == "string" then merchantFaction = saved.merchantFaction end
        if type(saved.memoryQuery) == "string" then memoryQuery = saved.memoryQuery end
        if type(saved.diaryQuery) == "string" then diaryQuery = saved.diaryQuery end
        if worldSearchBox and type(saved.worldQuery) == "string" then worldSearchBox:SetText(saved.worldQuery) end
        if type(saved.worldZone) == "string" then worldZone = saved.worldZone end
        if type(saved.worldContinent) == "string" then worldContinent = saved.worldContinent end
        if type(saved.worldCharacter) == "string" then worldCharacter = saved.worldCharacter end
    end
    if searchBox then
        local query = activeView == "diary" and diaryQuery or activeView == "memory" and memoryQuery or ""
        searchContextChanging = true
        searchBox:SetText(query)
        searchContextChanging = false
        if searchBox.Instructions then
            searchBox.Instructions:SetText(activeView == "diary" and FC.L.DIARY_SEARCH or FC.L.SEARCH_PLACEHOLDER)
            searchBox.Instructions:SetShown(query == "")
        end
    end
end

local function createUI()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    frame = CreateFrame("Frame", "ForeverChronicleFrame", UIParent, template)
    frame:SetSize(900, 650)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()

    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 9, right = 9, top = 9, bottom = 9 } })
        frame:SetBackdropColor(0.055, 0.035, 0.020, 0.98)
        frame:SetBackdropBorderColor(0.72, 0.56, 0.28, 1)
    end

    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", 75, -3)
    header:SetPoint("TOPRIGHT", -75, -3)
    header:SetHeight(58)
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetTexCoord(0.02, 0.98, 0.02, 0.98)

    local portrait = frame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 15, -14)
    portrait:SetSize(52, 52)
    portrait:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local portraitBorder = frame:CreateTexture(nil, "OVERLAY")
    portraitBorder:SetPoint("CENTER", portrait)
    portraitBorder:SetSize(70, 70)
    portraitBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    -- FontString glyphs sit visually below their region center in this font;
    -- lift the text so the lettering itself centers in the ornament.
    title:SetPoint("CENTER", header, "CENTER", 0, 14)
    title:SetText(FC.L.TITLE)
    title:SetTextColor(1.00, 0.82, 0.26)
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", header, "BOTTOM", 0, -2)
    subtitle:SetText(FC.L.SUBTITLE)
    subtitle:SetTextColor(0.72, 0.65, 0.50)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local settingsButton = CreateFrame("Button", nil, frame)
    settingsButton:SetSize(28, 28)
    settingsButton:SetPoint("TOPRIGHT", -38, -10)
    local settingsIcon = settingsButton:CreateTexture(nil, "ARTWORK")
    settingsIcon:SetAllPoints()
    settingsIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    settingsIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    settingsButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    settingsButton:SetScript("OnClick", function() FC:RenderUI("settings") end)
    settingsButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(FC.L.SETTINGS, 1.00, 0.82, 0.20)
        GameTooltip:AddLine(FC.L.SETTINGS_TOOLTIP, 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    settingsButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    settingsButton:HookScript("OnClick", function()
        if mapSettingsButton then mapSettingsButton:Hide() end
    end)

    local helpButton = CreateFrame("Button", nil, frame)
    helpButton:SetSize(28, 28)
    helpButton:SetPoint("TOPRIGHT", -68, -10)
    local helpIcon = helpButton:CreateTexture(nil, "ARTWORK")
    helpIcon:SetPoint("CENTER")
    helpIcon:SetSize(24, 24)
    helpIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    helpIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    helpButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    helpButton:SetScript("OnClick", function() FC:RenderUI("help") end)
    helpButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(FC.L.HELP_TITLE, 1.00, 0.82, 0.20)
        GameTooltip:AddLine(FC.L.HELP_TOOLTIP, 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    helpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local leftBackground = frame:CreateTexture(nil, "BACKGROUND")
    leftBackground:SetPoint("TOPLEFT", 13, -77)
    leftBackground:SetPoint("BOTTOMLEFT", 13, 48)
    leftBackground:SetWidth(190)
    leftBackground:SetColorTexture(0.045, 0.030, 0.018, 0.96)

    characterIdentityText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    characterIdentityText:SetPoint("TOP", leftBackground, "TOP", 0, -9)
    characterIdentityText:SetWidth(176)
    characterIdentityText:SetSpacing(2)
    local characterName = UnitName and UnitName("player")
    if FC:IsSecret(characterName) or type(characterName) ~= "string" then characterName = FC.profile.identity.name or "" end
    local className = FC.profile.identity.className
    if not className and UnitClass then className = UnitClass("player") end
    if FC:IsSecret(className) or type(className) ~= "string" then className = "" end
    characterIdentityText:SetText(string.format("%s\n|cffffd36a%s %d · %s|r", characterName,
        FC.L.LEVEL_SHORT, FC:GetPlayerLevel() or FC.profile.identity.level or 0, className))
    characterIdentityText:SetJustifyH("CENTER")

    for index, definition in ipairs(VIEWS) do
        createCategory(definition.key, FC.L[definition.label], definition.icon, index)
    end

    mapSettingsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mapSettingsButton:SetSize(164, 25)
    mapSettingsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 40)
    mapSettingsButton:SetText(FC.L.MAP_FILTERS)
    mapSettingsButton:SetScript("OnClick", function()
        if not FC.ToggleMapFilterPanel or not FC:ToggleMapFilterPanel() then
            FC:Print(FC.L.MAP_FILTER_OPEN_MANUALLY)
        end
    end)

    accountSummaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    accountSummaryText:SetPoint("BOTTOMLEFT", 27, 72)
    accountSummaryText:SetWidth(160)
    accountSummaryText:SetJustifyH("LEFT")
    accountSummaryText:SetSpacing(3)

    content = CreateFrame("Frame", nil, frame, template)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 207, -77)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 49)
    mapSettingsButton:SetParent(content)
    mapSettingsButton:ClearAllPoints()
    mapSettingsButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, -8)
    mapSettingsButton:SetSize(132, 24)
    if content.SetBackdrop then
        content:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        content:SetBackdropColor(0.055, 0.045, 0.035, 0.98)
        content:SetBackdropBorderColor(0.47, 0.37, 0.23, 1)
    end

    contentTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    contentTitle:SetPoint("TOPLEFT", 16, -15)
    contentTitle:SetTextColor(1.00, 0.84, 0.48)
    contentSubtitle = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    contentSubtitle:SetPoint("TOPRIGHT", content, "TOPRIGHT", -17, -20)
    contentSubtitle:SetJustifyH("RIGHT")
    contentSubtitle:SetTextColor(0.72, 0.78, 0.82)

    local headerLine = content:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("TOPLEFT", 13, -54)
    headerLine:SetPoint("TOPRIGHT", -13, -54)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(0.52, 0.42, 0.24, 0.85)

    searchBox = CreateFrame("EditBox", nil, content, "SearchBoxTemplate")
    searchBox:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -87)
    searchBox:SetPoint("RIGHT", content, "RIGHT", -17, 0)
    searchBox:SetHeight(28)
    searchBox:SetAutoFocus(false)
    if searchBox.Instructions then
        searchBox.Instructions:SetText(FC.L.SEARCH_PLACEHOLDER)
    end
    searchBox:SetScript("OnTextChanged", function(self)
        if SearchBoxTemplate_OnTextChanged then
            SearchBoxTemplate_OnTextChanged(self)
        end
        if self.Instructions then
            self.Instructions:SetShown(self:GetText() == "")
        end
        if activeView == "diary" then diaryQuery = self:GetText() or ""
        elseif activeView == "memory" then memoryQuery = self:GetText() or ""; memoryOffset = 0 end
        if activeView == "memory" then selectedMerchantKey, selectedMerchantCharacter = nil, nil end
        persistUIState()
        if searchContextChanging or (activeView ~= "memory" and activeView ~= "diary") then
            return
        end
        searchGeneration = searchGeneration + 1
        local generation = searchGeneration
        local targetView = activeView
        local function update()
            if generation == searchGeneration and activeView == targetView then
                if targetView == "memory" then
                    memoryOffset = 0
                    renderMemory()
                else
                    diaryOffset = 0
                    if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
                    renderDiary()
                end
                persistUIState()
            end
        end
        if C_Timer and C_Timer.After then C_Timer.After(0.10, update) else update() end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    searchBox:Hide()

    createUIFilters()

    local memorySectionDefinitions = {
        { key = "memory", label = FC.L.DISCOVERIES_TAB },
        { key = "world", label = FC.L.WORLD_TAB },
    }
    for index, definition in ipairs(memorySectionDefinitions) do
        local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        button:SetSize(132, 24)
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 16 + ((index - 1) * 138), -60)
        button:SetText(definition.label)
        button:SetScript("OnClick", function() FC:RenderUI(definition.key) end)
        memorySectionButtons[definition.key] = button
        button:Hide()
    end

    createUIPanels()

    local noteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    noteButton:SetSize(125, 25)
    noteButton:SetPoint("BOTTOMLEFT", 17, 17)
    noteButton:SetText(FC.L.ADD_NOTE)
    noteButton:SetScript("OnClick", function() StaticPopup_Show("FOREVER_CHRONICLE_ADD_NOTE") end)

    local closeBottom = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBottom:SetSize(105, 25)
    closeBottom:SetPoint("BOTTOMRIGHT", -17, 17)
    closeBottom:SetText(FC.L.CLOSE)
    closeBottom:SetScript("OnClick", function() frame:Hide() end)

    local quickDefinitions = {
        { key = "journey", label = FC.L.MY_JOURNEY },
        { key = "memory", label = FC.L.MEMORY },
        { key = "companions", label = FC.L.COMPANIONS },
    }
    for index, definition in ipairs(quickDefinitions) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(112, 24)
        button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 218 + ((index - 1) * 116), 17)
        button:SetText(definition.label)
        button:SetScript("OnClick", function() FC:RenderUI(definition.key) end)
        quickButtons[definition.key] = button
    end

    restoreUIState()
    frame:SetScript("OnHide", persistUIState)
    frame:SetScript("OnShow", function() FC:RenderUI(activeView) end)
    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverChronicleFrame") end
end

StaticPopupDialogs["FOREVER_CHRONICLE_ADD_NOTE"] = {
    text = FC.L.ADD_NOTE_PROMPT,
    button1 = ACCEPT, button2 = CANCEL, hasEditBox = true, hasCheckButton = true,
    checkButtonText = FC.L.REMIND_ON_RETURN, maxLetters = 240,
    OnAccept = function(dialog)
        local editBox = dialog.editBox or dialog.EditBox
        local checkButton = dialog.CheckButton or dialog.checkButton
        if editBox then FC:AddNote(editBox:GetText(), not checkButton or checkButton:GetChecked()) end
    end,
    OnShow = function(dialog)
        local editBox = dialog.editBox or dialog.EditBox
        local checkButton = dialog.CheckButton or dialog.checkButton
        if checkButton then checkButton:SetChecked(true) end
        if editBox then editBox:SetText(""); editBox:SetFocus() end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local checkButton = dialog.CheckButton or dialog.checkButton
        FC:AddNote(editBox:GetText(), not checkButton or checkButton:GetChecked())
        dialog:Hide()
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function FC:OpenUI(view)
    if not frame then createUI() end
    if view == "today" or view == "overview" then view = "journey" end
    if view == "export" or view == "backup" then view = "settings" end
    if view == "characters" then view = "companions" end
    activeView = renderers[view] and view or activeView
    if contentTitle then contentTitle:SetTextColor(0.95, 0.82, 0.49) end
    if contentSubtitle then
        contentSubtitle:SetTextColor(0.70, 0.64, 0.52)
    end
    frame:Show()
    self:RenderUI(activeView)
end

function FC:ToggleUI()
    if not frame then createUI() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

FC:RegisterEvent("PLAYER_LOGIN", function()
    if not frame then createUI() end
end)
