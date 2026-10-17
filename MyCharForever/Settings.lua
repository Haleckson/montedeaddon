local addonName, MCF = ...
-- Settings window. Same look as the main window and the dungeon view: opaque dark-brown window,
-- every topic is a bordered card with a gold header band (click to fold). Cards are stacked by one
-- layout function from their real heights, so folding a card never leaves a gap and nothing is
-- placed with hand-counted pixel offsets across the whole page.
--
-- The Blizzard options list only gets a small entry with a button that opens this window.

local function DB()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.settings = MyCharForeverDB.settings or {}
    return MyCharForeverDB.settings
end
local function De() return MCF.GetLanguage and MCF:GetLanguage() == "deDE" end
local function L(de, en) return De() and de or en end

local Kit = MCF.Kit
local WINDOW_W, WINDOW_H = 660, 680
local CARD_W = 590
local HEADER_H = 96

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local window = Kit.Window("MyCharForeverSettingsWindow", {w = WINDOW_W, h = WINDOW_H, scroll = true,
    scrollName = "MyCharForeverSettingsScrollFrame", childName = "MyCharForeverSettingsScrollChild"})
MCF.settingsFontRoot = window
window:HookScript("OnShow", function() if MCF.ApplyFontScale then MCF:ApplyFontScale() end end)
local windowTitle = window.title
local closeButton = window.closeButton
local scrollFrame = window.scroll
local panel = window.child
panel:SetSize(WINDOW_W - 50, 1400)

-- Texts that depend on the language: registered once, refreshed from one place.
local binds = {}
local function Bind(fs, getter)
    binds[#binds + 1] = {fs = fs, get = getter}
    fs:SetText(getter())
    return fs
end
local function RefreshBinds()
    for _, b in ipairs(binds) do b.fs:SetText(b.get()) end
end

---------------------------------------------------------------------------
-- Header (logo, name, version)
---------------------------------------------------------------------------
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
title:SetPoint("TOPLEFT", 14, -10); title:SetTextColor(1, 0.9, 0.5); title:SetText("MyCharForever")
local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sub:SetPoint("TOPLEFT", 14, -42); sub:SetTextColor(0.7, 0.7, 0.7)
Bind(sub, function() return MCF:T("Chronicle settings") end)
local brandIcon = panel:CreateTexture(nil, "ARTWORK")
brandIcon:SetTexture(MCF.LOGO_PATH)
brandIcon:SetSize(56, 56); brandIcon:SetPoint("TOPRIGHT", -14, -8)
local authorText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
authorText:SetPoint("TOPRIGHT", brandIcon, "BOTTOMRIGHT", 0, -2); authorText:SetText("cinedevchris")
local versionText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
versionText:SetPoint("TOPRIGHT", authorText, "BOTTOMRIGHT", 0, -2); versionText:SetTextColor(0.7, 0.7, 0.7)
Bind(versionText, function() return "v" .. tostring(MCF.VERSION or "unknown") end)

---------------------------------------------------------------------------
-- Cards
---------------------------------------------------------------------------
local cards = {}
local layout

local function Check(parent, label, key, x, y, default, onChange)
    local c = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y)
    c.Text:SetText(label)
    c:SetScript("OnShow", function(self)
        local s = DB(); if not s then return end
        if s[key] == nil then s[key] = default end
        self:SetChecked(s[key])
    end)
    c:SetScript("OnClick", function(self)
        local s = DB(); if s then s[key] = self:GetChecked() and true or false end
        if onChange then onChange() end
    end)
    return c
end

local function NewCard(getTitle, startExpanded)
    local c = {expanded = startExpanded ~= false}
    local f = Kit.Card(panel, function() c.expanded = not c.expanded; layout() end)
    f:SetWidth(CARD_W)
    local body, text = f.body, f.band.label
    c.frame, c.body, c.titleText, c.getTitle = f, body, text, getTitle
    c.y = -8
    c.bodyHeight = 1

    -- Row helpers: every control advances the card's own cursor, so a card is as tall as its content.
    function c:Check(label, key, default, onChange, indent)
        local ck = Check(body, type(label) == "function" and label() or label, key, 10 + (indent or 0), self.y, default, onChange)
        if type(label) == "function" then binds[#binds + 1] = {fs = ck.Text, get = label} end
        self.y = self.y - 26
        return ck
    end
    function c:Text(getter, indent, height, font, color)
        local fs = body:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 14 + (indent or 0), self.y); fs:SetWidth(CARD_W - 30 - (indent or 0)); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
        if color then fs:SetTextColor(color[1], color[2], color[3]) end
        if type(getter) == "function" then Bind(fs, getter) else fs:SetText(getter) end
        self.y = self.y - (height or 16)
        return fs
    end
    function c:Gap(h) self.y = self.y - (h or 6) end
    function c:Finish() self.bodyHeight = -self.y + 8; body:SetHeight(self.bodyHeight) end
    cards[#cards + 1] = c
    return c
end

layout = function()
    local y = -HEADER_H
    for _, c in ipairs(cards) do
        c.titleText:SetText((c.expanded and "-  " or "+  ") .. c.getTitle())
        c.frame:ClearAllPoints(); c.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
        local h = 34 + (c.expanded and c.bodyHeight or 0)
        c.frame:SetHeight(h)
        if c.expanded then c.body:Show() else c.body:Hide() end
        y = y - h - 12
    end
    panel:SetHeight(-y + 10)
end

-- Dropdown with one code path: choices(), current() and pick(value, text) are supplied by the caller.
local function Dropdown(name, parent, x, y, width, choices, current, pick)
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, width)
    local function refresh()
        for _, v in ipairs(choices()) do
            if v[1] == current() then UIDropDownMenu_SetText(dd, v[2]); break end
        end
    end
    UIDropDownMenu_Initialize(dd, function(_, level)
        for _, v in ipairs(choices()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v[2]; info.checked = (current() == v[1])
            local value, text = v[1], v[2]
            info.func = function() pick(value, text); CloseDropDownMenus(); refresh() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dd:SetScript("OnShow", refresh)
    dd.refresh = refresh
    return dd
end
local dropdowns = {}
-- A labeled dropdown row inside a card.
local function DropdownRow(card, getLabel, name, choices, current, pick, indent)
    local label = card.body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 14 + (indent or 0), card.y - 6)
    Bind(label, getLabel)
    local dd = Dropdown(name, card.body, 230, card.y + 2, 150, choices, current, pick)
    dropdowns[#dropdowns + 1] = dd
    card.y = card.y - 34
    return dd
end

---------------------------------------------------------------------------
-- Card: General
---------------------------------------------------------------------------
local general = NewCard(function() return L("Allgemein", "General") end)

local function LanguageOptions()
    return {{"auto", MCF:T("Automatic (client language)")}, {"deDE", MCF:T("German")}, {"enUS", MCF:T("English")}}
end
DropdownRow(general, function() return MCF:T("Language") end, "MyCharForeverLanguageDropdown", LanguageOptions,
    function() local st = DB(); return (st and st.language) or "auto" end,
    function(value)
        local st = DB(); if st then st.language = value end
        if MCF.RefreshLocalizedUI then MCF:RefreshLocalizedUI() end
        if MCF.RefreshSettingsLocalization then MCF:RefreshSettingsLocalization() end
        if MCF.RefreshUI then MCF:RefreshUI() end
    end)

-- Display time of the achievement / iconic-moment popups (setting toastSeconds). Single source for default and choices.
MCF.ToastSeconds = {default = 8, choices = {3, 5, 8, 10, 12, 15}}
local function ToastSecondsChoices()
    local out = {}
    for _, n in ipairs(MCF.ToastSeconds.choices) do out[#out + 1] = {n, L(n .. " Sekunden", n .. " seconds")} end
    return out
end

local function FontScaleChoices()
    local out = {}
    for _, c in ipairs(MCF.FontScaleChoices) do out[#out + 1] = {c[1], L(c[2], c[3])} end
    return out
end
DropdownRow(general, function() return L("Schriftgröße", "Font size") end, "MyCharForeverFontScaleDropdown", FontScaleChoices,
    function() local st = DB(); return st and tonumber(st.fontScale) or 1 end,
    function(value) MCF:SetFontScale(value) end)

general:Check(function() return MCF:T("Show minimap button") end, "showMinimapButton", true, function() MCF:UpdateMinimapButton() end)
-- The popup for an unlocked achievement; the chat line is a separate setting (chatMessages, Diagnostics).
general:Check(function() return L("Erfolge aktivieren (aus: keine Erfolge, Popups, Töne und Registerkarte)", "Enable achievements (off: no achievements, popups, sounds or tab)") end, "achievementsEnabled", true,
    function() if MCF.ApplyAchievementsSetting then MCF:ApplyAchievementsSetting() end end)
general:Check(function() return L("Ikonische Momente aktivieren (aus: keine Momente, Popups, Screenshots, Tagebucheinträge, Kartensterne und Registerkarte)", "Enable iconic moments (off: no moments, popups, screenshots, journal entries, map stars or tab)") end, "iconicEnabled", true,
    function() if MCF.ApplyIconicSetting then MCF:ApplyIconicSetting() end end)
general:Check(function() return L("Erfolgs-Popups anzeigen", "Show achievement popups") end, "achievementNotify", true, nil, 20)
DropdownRow(general, function() return L("Anzeigedauer der Popups", "Popup display time") end, "MyCharForeverToastSecondsDropdown", ToastSecondsChoices,
    function() local st = DB(); return st and tonumber(st.toastSeconds) or MCF.ToastSeconds.default end,
    function(value) local st = DB(); if st then st.toastSeconds = tonumber(value) or MCF.ToastSeconds.default end end, 20)
general:Check(function() return L("Kurzer Ton bei Erfolgen", "Short sound for achievements") end, "achievementSound", true, nil, 20)
general:Check(function() return L("Pop-up bei ikonischen Momenten (erstes Mal)", "Popup for iconic moments (first time)") end, "iconicPopup", true)
general:Check(function() return L("Tipps und Erinnerungen anzeigen (Porträt, Webseite)", "Show tips and reminders (portrait, website)") end, "showTips", true)
-- Addon messages only (no chat text): other copies of the addon learn that you use it. Nothing but the version is sent.
general:Check(function() return L("Anderen MyCharForever-Nutzern zeigen, dass ich das Addon nutze", "Let other MyCharForever users know I use the addon") end, "presenceEnabled", true)
general:Check(function() return L("Gegenstandsstufe der Dungeon-Gruppe automatisch auslesen (Inspektion der Mitspieler)", "Read the party's item level automatically in dungeons (inspects party members)") end, "inspectParty", true)
general:Finish()

---------------------------------------------------------------------------
-- Card: Screenshots
---------------------------------------------------------------------------
local shots = NewCard(function() return MCF:T("Screenshots") end)

-- shortcut row
local shortcutLabel = shots.body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
shortcutLabel:SetPoint("TOPLEFT", 14, shots.y - 6)
Bind(shortcutLabel, function() return MCF:T("Shortcut") .. ":" end)
local shortcutButton = CreateFrame("Button", nil, shots.body, "UIPanelButtonTemplate")
shortcutButton:SetSize(160, 24); shortcutButton:SetPoint("TOPLEFT", 230, shots.y - 2)
local RefreshShortcutButton = MCF:AttachShortcutCapture(shortcutButton, function() if MCF.RefreshUI then MCF:RefreshUI() end end)
-- hint: the addon lists screenshots but cannot show the pictures (short text, one source in Widgets.lua)
Kit.Hint.Button(shots.body, true):SetPoint("LEFT", shortcutButton, "RIGHT", 8, 0)
shots.y = shots.y - 34

shots:Check(function() return L("Auch normale Spiel-Screenshots (Druck-Taste) in der Chronik vermerken", "Also log normal game screenshots (Print Screen) in the chronicle") end, "screenshotLogAll", true)
shots:Check(function() return MCF:T("Enable automatic screenshots") end, "screenshotEnabled", true)
shots:Check(function() return MCF:T("At level up") end, "screenshotLevelUp", true, nil, 20)
shots:Check(function() return MCF:T("At login") end, "screenshotLogin", false, nil, 20)
shots:Check(function() return MCF:T("At death") end, "screenshotDeath", false, nil, 20)
shots:Check(function() return MCF:T("At dungeon completion") end, "screenshotDungeon", true, nil, 20)
shots:Check(function() return MCF:T("At achievement") end, "screenshotAchievement", true, nil, 20)
shots:Check(function() return MCF:T("Periodic screenshots") end, "screenshotPeriodic", false, nil, 20)
shots:Check(function() return L("Bei ikonischen Ereignissen (erstes Mal)", "At iconic moments (first time)") end, "screenshotIconic", true, nil, 20)
shots:Check(function() return L("Ikonische Ereignisse automatisch ins Tagebuch eintragen", "Add iconic moments to the journal automatically") end, "iconicJournal", true, nil, 20)
shots:Check(function() return L("Bei Gilden-Einladung und Gilden-Beitritt", "On guild invitation and joining a guild") end, "screenshotGuild", true, nil, 20)
shots:Check(function() return L("Gilden-Einladung, -Beitritt und -Austritt automatisch ins Tagebuch eintragen", "Add guild invitation, joining and leaving to the journal automatically") end, "guildJournal", true, nil, 20)
shots:Check(function() return L("Beim ersten Tod und bei der Rückkehr nach langer Pause", "At the first death and when coming back after a long break") end, "screenshotMoments", true, nil, 20)
shots:Check(function() return L("Ersten Tod und Rückkehr automatisch ins Tagebuch eintragen", "Add the first death and coming back to the journal automatically") end, "momentsJournal", true, nil, 20)

local intLabel = shots.body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
intLabel:SetPoint("TOPLEFT", 54, shots.y - 6)
Bind(intLabel, function() return MCF:T("Interval minutes") end)
local intEdit = CreateFrame("EditBox", nil, shots.body, "InputBoxTemplate")
intEdit:SetSize(45, 22); intEdit:SetPoint("LEFT", intLabel, "RIGHT", 12, 0)
intEdit:SetNumeric(true); intEdit:SetAutoFocus(false); intEdit:SetMaxLetters(2)
intEdit:SetScript("OnShow", function(self) local s = DB(); self:SetText(tostring((s and s.screenshotInterval) or 5)) end)
intEdit:SetScript("OnEnterPressed", function(self)
    local s = DB(); if s then s.screenshotInterval = math.max(1, math.min(60, tonumber(self:GetText()) or 5)); self:SetText(s.screenshotInterval) end
    self:ClearFocus()
end)
shots.y = shots.y - 34

shots:Check(function() return MCF:T("When equipping quality item") end, "screenshotEquip", true)
shots:Check(function() return L("Erste Ausrüstung je Slot und Qualität ins Tagebuch eintragen", "Add the first item per slot and quality to the journal") end, "equipJournal", true, nil, 20)
shots:Check(function() return L("Beute (Weltdrops, Quest- und Dungeon-Belohnungen) mit einem Kommentar versehen", "Add a comment to loot (world drops, quest and dungeon rewards)") end, "lootComments", true, nil, 20)
local function QualityOptions()
    return {
        {2, "|cff1eff00" .. MCF:T("Uncommon") .. "|r"},
        {3, "|cff0070dd" .. MCF:T("Rare") .. "|r"},
        {4, "|cffa335ee" .. MCF:T("Epic") .. "|r"},
        {5, "|cffff8000" .. MCF:T("Legendary") .. "|r"},
    }
end
DropdownRow(shots, function() return MCF:T("Minimum item quality") end, "MyCharForeverQualityDropdown", QualityOptions,
    function() local st = DB(); return (st and st.screenshotMinQuality) or 2 end,
    function(value) local st = DB(); if st then st.screenshotMinQuality = value end end, 20)

shots:Gap(4)
shots:Text(function() return L("SCREENSHOT-MEILENSTEINE", "SCREENSHOT MILESTONES") end, 0, 20, "GameFontNormal")
shots:Text(function() return L("Ereignisse oben aktivieren; Hinweisfenster separat steuern.", "Enable events above; configure the notice separately.") end, 0, 18)
shots:Check(function() return L("Hinweisfenster bei Ausrüstungs-Meilensteinen", "Show notice for equipment milestones") end, "screenshotEquipNotice", true)
shots:Text(function() return L("Levelaufstieg: nur WoW-Originalmeldung (kein Zusatzfenster).", "Level up: WoW's original notification only (no extra notice).") end, 0, 18)
shots:Finish()

---------------------------------------------------------------------------
-- Card: Journey recording
---------------------------------------------------------------------------
local journey = NewCard(function() return MCF:T("Journey recording") end)
journey:Check(function() return MCF:T("Record journey path") end, "trackJourney", true, function()
    if MCF.StartJourneyTracking then MCF:StartJourneyTracking() end
end)
-- Fixed five-second sampling. RecordJourneyPoint already discards stationary samples and simplifies
-- near-straight paths.
journey:Text(function() return L("Automatisch alle 5 Sek. (nur bei Bewegung)", "Automatic every 5 sec (only while moving)") end, 26, 18)
journey:Finish()

---------------------------------------------------------------------------
-- Card: World drops
---------------------------------------------------------------------------
local drops = NewCard(function() return L("Besondere Weltdrops", "Notable world drops") end)
drops:Check(function() return L("Besondere Drops außerhalb von Instanzen aufzeichnen (Karten-Icon)", "Record notable drops outside instances (map icon)") end, "recordWorldDrops", true)
drops:Check(function() return L("Automatisch einen Journal-Eintrag anlegen", "Create a journal entry automatically") end, "worldDropJournal", true)
local function DropMinQuality()
    local st = DB()
    return (st and tonumber(st.worldDropMinQuality)) or (MCF.WorldDrops and MCF.WorldDrops.defaultMinQuality) or 3
end
DropdownRow(drops, function() return L("Mindestqualität", "Minimum quality") end, "MyCharForeverDropQualityDropdown", QualityOptions,
    DropMinQuality, function(value) local st = DB(); if st then st.worldDropMinQuality = value end end, 20)
drops:Finish()

---------------------------------------------------------------------------
-- Card: PvP and item journal
---------------------------------------------------------------------------
local pvp = NewCard(function() return L("PvP und Ausrüstungs-Tagebuch", "PvP and equipment journal") end)
pvp:Check(function() return L("PvP in der offenen Welt aufzeichnen (Karten-Icon: gekreuzte Schwerter)", "Record world PvP (map icon: crossed swords)") end, "recordPvp", true)
pvp:Check(function() return L("Screenshot beim ersten Spielerkill und beim ersten Tod durch einen Spieler", "Screenshot on the first player kill and the first death by a player") end, "screenshotPvp", true)
pvp:Check(function() return L("Journal-Eintrag dazu anlegen", "Create a journal entry for them") end, "pvpJournal", true)
pvp:Text(function() return L("Schlachtfelder und Arenen werden nur gezählt. Es werden keine Spielernamen gespeichert.", "Battlegrounds and arenas are only counted. No player names are stored.") end, 0, 30, "GameFontHighlightSmall", {0.75, 0.75, 0.75})
pvp:Gap(4)
pvp:Check(function() return L("Journal-Eintrag für gute Ausrüstung aus Quests und Dungeons (automatisch)", "Automatic journal entry for good equipment from quests and dungeons") end, "itemJournal", true)
DropdownRow(pvp, function() return L("Mindestqualität", "Minimum quality") end, "MyCharForeverItemJournalQualityDropdown", QualityOptions,
    function() local st = DB(); return (st and tonumber(st.itemJournalMinQuality)) or (MCF.ItemJournal and MCF.ItemJournal.defaultMinQuality) or 3 end,
    function(value) local st = DB(); if st then st.itemJournalMinQuality = value end end, 20)
pvp:Finish()

---------------------------------------------------------------------------
-- Card: Contact & support (single source for the address; WoW cannot open a mail client, so it is a selectable field)
---------------------------------------------------------------------------
MCF.CONTACT_EMAIL = "wow@cinechris.de"
local contact = NewCard(function() return L("Kontakt & Support", "Contact & Support") end)
contact:Text(function()
    return L("Falls du Fragen, Wünsche oder Probleme mit meinem Addon hast, scheue dich nicht, mich zu kontaktieren: ",
             "If you have questions, wishes or problems with my addon, don't hesitate to contact me: ") .. "|cff66ccff" .. MCF.CONTACT_EMAIL .. "|r"
end, 0, 46, "GameFontHighlight")
local mailBox = CreateFrame("EditBox", nil, contact.body, "InputBoxTemplate")
mailBox:SetSize(220, 22); mailBox:SetPoint("TOPLEFT", 20, contact.y)
mailBox:SetAutoFocus(false); mailBox:SetFontObject("GameFontHighlight")
local function ResetMail() mailBox:SetText(MCF.CONTACT_EMAIL); mailBox:SetCursorPosition(0) end
mailBox:SetScript("OnShow", ResetMail)
mailBox:SetScript("OnTextChanged", function(self) if self:GetText() ~= MCF.CONTACT_EMAIL then ResetMail() end end)
mailBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
mailBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
mailBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
ResetMail()
contact.y = contact.y - 28
contact:Text(function() return L("Zum Kopieren anklicken und Strg+C drücken.", "Click to select, then press Ctrl+C to copy.") end, 0, 18, "GameFontHighlightSmall", {0.75, 0.75, 0.75})
contact:Gap(2)
contact:Text(function() return L("MyCharForever soll ein lebendes Projekt sein, so wie WoW: Forever auch :)", "MyCharForever is meant to be a living project, just like WoW: Forever :)") end, 0, 20, "GameFontHighlight")
contact:Finish()

---------------------------------------------------------------------------
-- Card: Database
---------------------------------------------------------------------------
local data = NewCard(function() return MCF:T("Database") end)
local dataInfo = data:Text("", 0, 34)
local maintenanceButton = CreateFrame("Button", nil, data.body, "UIPanelButtonTemplate")
maintenanceButton:SetSize(210, 26); maintenanceButton:SetPoint("TOPLEFT", 14, data.y)
Bind(maintenanceButton, function() return L("Daten jetzt bereinigen", "Clean up data now") end)
local maintenanceResult = data.body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
maintenanceResult:SetPoint("TOPLEFT", maintenanceButton, "TOPRIGHT", 12, -2)
maintenanceResult:SetWidth(CARD_W - 250); maintenanceResult:SetJustifyH("LEFT"); maintenanceResult:SetWordWrap(true)
data.y = data.y - 48
data:Check(function() return L("Automatische Wartung (Login und Levelaufstieg)", "Automatic maintenance (login and level-up)") end, "autoMaintenance", true)
local maintenanceHint = data:Text(function() return MCF.MaintenanceDescription and MCF:MaintenanceDescription() or "" end, 0, 90, "GameFontHighlightSmall", {0.75, 0.75, 0.75})
data:Finish()

local function RefreshDataInfo()
    if not MyCharForeverDB then return end
    local _, bytes = MCF:GetDataSizeReport()
    local points = MyCharForeverDB.journey and #MyCharForeverDB.journey or 0
    local events = MyCharForeverDB.events and #MyCharForeverDB.events or 0
    local shotCount = MyCharForeverDB.screenshots and #MyCharForeverDB.screenshots or 0
    dataInfo:SetText(
        MCF:T("Estimated SavedVariables size") .. ": ~ " .. MCF:FormatBytes(bytes) .. "   |   " ..
        MCF:T("Journey points short") .. ": " .. points .. "   |   " ..
        MCF:T("Events short") .. ": " .. events .. "   |   " ..
        MCF:T("Screenshots short") .. ": " .. shotCount)
    local last = MyCharForeverDB.maintenance and MyCharForeverDB.maintenance.last
    maintenanceResult:SetText(MCF:DescribeMaintenance(last))
end
function MCF:RefreshSettingsInfo() RefreshDataInfo() end

maintenanceButton:SetScript("OnClick", function()
    StaticPopupDialogs["MCF_MAINTENANCE_CONFIRM"] = {
        text = MCF.Branded(MCF:MaintenanceDescription() .. "\n\n" .. L("Jetzt ausführen?", "Run now?")),
        button1 = YES, button2 = NO, timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function() MCF:RunMaintenance(true); RefreshDataInfo() end,
        preferredIndex = 3,
    }
    StaticPopup_Show("MCF_MAINTENANCE_CONFIRM")
end)
maintenanceButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L("Wartung", "Maintenance"), 1, 0.82, 0)
    GameTooltip:AddLine(MCF:MaintenanceDescription(), 1, 1, 1, true)
    GameTooltip:Show()
end)
maintenanceButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

---------------------------------------------------------------------------
-- Card: Diagnostics
---------------------------------------------------------------------------
local diag = NewCard(function() return L("Diagnose & Debugging", "Diagnostics & Debugging") end, false)
diag:Check(function() return L("Status-Meldungen im Chat anzeigen (Level, Dungeon, Erfolge ...)", "Show status messages in chat (level, dungeon, achievements ...)") end, "chatMessages", false)
diag:Check(function() return L("Debug-Meldungen im Chat anzeigen", "Show debug messages in chat") end, "debugChat", false)
local errorLogButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
errorLogButton:SetSize(210, 26); errorLogButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(errorLogButton, function()
    local distinct = MCF.GetErrorCount and select(1, MCF:GetErrorCount()) or 0
    return L("Fehlerprotokoll", "Error log") .. " (" .. distinct .. ")"
end)
errorLogButton:SetScript("OnClick", function() if MCF.ShowErrorsExport then MCF:ShowErrorsExport() end end)
diag.y = diag.y - 34
local welcomeButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
welcomeButton:SetSize(210, 26); welcomeButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(welcomeButton, function() return L("Willkommensfenster anzeigen", "Show welcome window") end)
welcomeButton:SetScript("OnClick", function() if MCF.ShowWelcome then MCF:ShowWelcome() end end)
diag.y = diag.y - 34
local reportButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
reportButton:SetSize(210, 26); reportButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(reportButton, function() return L("Fehlerbericht erstellen", "Create bug report") end)
reportButton:SetScript("OnClick", function() if MCF.ShowBugReportExport then MCF:ShowBugReportExport() end end)
diag.y = diag.y - 34
local selfTestButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
selfTestButton:SetSize(210, 26); selfTestButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(selfTestButton, function() return L("Selbsttest ausführen", "Run self test") end)
selfTestButton:SetScript("OnClick", function() if MCF.ShowSelfTestExport then MCF:ShowSelfTestExport() end end)
diag.y = diag.y - 34
local debugButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
debugButton:SetSize(210, 26); debugButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(debugButton, function() return L("Debug Center öffnen", "Open Debug Center") end)
debugButton:SetScript("OnClick", function()
    if MCF.OpenDebugCenter then MCF:OpenDebugCenter() else print("MyCharForever: Debug Center is not available.") end
end)
diag.y = diag.y - 34
local toastTestButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
toastTestButton:SetSize(210, 26); toastTestButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(toastTestButton, function() return L("Test-Erfolg anzeigen", "Show test achievement") end)
toastTestButton:SetScript("OnClick", function() if MCF.TestAchievementToast then MCF:TestAchievementToast() end end)
diag.y = diag.y - 34
local cmdListButton = CreateFrame("Button", nil, diag.body, "UIPanelButtonTemplate")
cmdListButton:SetSize(210, 26); cmdListButton:SetPoint("TOPLEFT", 14, diag.y)
Bind(cmdListButton, function() return L("Test- und Debug-Befehle anzeigen", "Show test and debug commands") end)
cmdListButton:SetScript("OnClick", function() if MCF.ShowCommandList then MCF:ShowCommandList() end end)
diag.y = diag.y - 34
diag:Finish()

---------------------------------------------------------------------------
-- Refresh, open, Blizzard entry
---------------------------------------------------------------------------
function MCF:RefreshSettingsLocalization()
    windowTitle:SetText("MyCharForever - " .. L("Einstellungen", "Settings"))
    closeButton:SetText(L("Schließen", "Close"))
    RefreshBinds()
    RefreshShortcutButton()
    for _, dd in ipairs(dropdowns) do dd.refresh() end
    layout()
    RefreshDataInfo()
    if MCF.ApplyFontScale then MCF:ApplyFontScale() end
end

window:SetScript("OnShow", function() MCF:RefreshSettingsLocalization() end)
layout()

function MCF:OpenAddonSettings()
    window:Show(); window:Raise()
end

MCF:AddCommand{group="main", usage="/mcf settings", key="settings",
    de="Einstellungen öffnen", en="Open the settings",
    run=function() MCF:OpenAddonSettings() end}

-- Entry in the Blizzard options list: just a button that opens the window above.
local launcher = CreateFrame("Frame")
launcher.name = "MyCharForever"
local launcherTitle = launcher:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
launcherTitle:SetPoint("TOPLEFT", 16, -16); launcherTitle:SetText("MyCharForever")
local launcherButton = CreateFrame("Button", nil, launcher, "UIPanelButtonTemplate")
launcherButton:SetSize(220, 26); launcherButton:SetPoint("TOPLEFT", 16, -52)
launcher:SetScript("OnShow", function() launcherButton:SetText(L("Einstellungen öffnen", "Open settings")) end)
launcherButton:SetScript("OnClick", function()
    if HideUIPanel and SettingsPanel then pcall(HideUIPanel, SettingsPanel) end
    MCF:OpenAddonSettings()
end)
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(launcher, "MyCharForever")
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(launcher)
end
