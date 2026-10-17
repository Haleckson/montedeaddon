local addonName, MCF = ...
-- Welcome window, shown once per character. No automatic pop-up at login.
--   * It opens the first time the player opens the chronicle (minimap button, /mcf, anything that shows the main window),
--     on top of the chronicle.
--   * Fallback: if the chronicle was not opened by the first level-up, the window appears right after the level-up
--     screenshot (the chronicle itself stays closed until the player clicks "Open chronicle").
--   * Character at level 1: says the chronicle is complete from the start.
--   * Character that is already past level 1: says exactly what is only recorded from now on.
--   * Always: what can be recorded, and how to open the addon.
--   * Two stages: a short first page (what it is, the website hint, one button for more) and the full text behind "Learn more",
--     because a long first page tends to be clicked away unread.
-- `/mcf welcome` (or the button in Settings > Diagnostics) shows it again.
-- State lives on the character record: welcomeShown. Every character that has not seen the window yet gets it once
-- (also characters whose data was created by an older version, which never had a pending flag).
-- Every number and wording lives in MCF.Welcome below.

MCF.Welcome = {
  width = 560,
  height = 540,
  retryEvery = 3,    -- seconds between tries while combat or a hidden UI is in the way
  retryMax = 400,    -- number of tries (about 20 minutes), then it opens with the next trigger
  afterOpen = 0.2,   -- seconds after the chronicle was opened for the first time (so the window lies on top of it)
  mainDimAlpha = 0.3, -- the chronicle window below is dimmed to this opacity while the welcome window is open (readability)
  afterScreenshot = 3, -- seconds after the level-up screenshot was taken (MCF.LevelScreenshotDelay + this)
}
local W = MCF.Welcome

local function de() return MCF:GetLanguage() == "deDE" end
local function tbl(v) return type(v) == "table" and v or {} end

local GOLD, WHITE, GREY, END = "|cffffd200", "|cffffffff", "|cffaaaaaa", "|r"

local function section(title, body) return GOLD .. title .. END .. "\n" .. body .. "\n\n" end

-- Friendly note about own screenshots and journal entries: automatic first, the personal part is a bonus (never a duty).
local function momentsSection()
  if de() then
    return section("Die Chronik schreibt sich von allein",
      "Level-Ups, Dungeons, Erfolge und Reisen hält MyCharForever automatisch fest. Du musst nichts tun.\n"
      .. "Wenn dir ein Moment besonders gefällt, machst du mit der Taste oben jederzeit einen Chronik-Screenshot. "
      .. "Das ist freiwillig: ein einziges Bild pro Spielabend reicht schon, und später liest du deine Geschichte wie ein Buch. "
      .. "Eigene Notizen kannst du jederzeit im Journal ergänzen.")
  end
  return section("Your chronicle writes itself",
    "MyCharForever records level-ups, dungeons, achievements and travels automatically. You do not have to do anything.\n"
    .. "If a moment is special to you, take a chronicle screenshot with the key above at any time. "
    .. "It is entirely optional: a single picture per evening already makes the story yours, and later you read it like a book. "
    .. "You can add your own notes in the journal whenever you like.")
end

-- Builds the whole text for the current character.
function MCF:BuildWelcomeText()
  local db = MyCharForeverDB or {}
  local ch = tbl(db.character)
  local first = tonumber(ch.firstSeenLevel) or 1
  local hasStats = tbl(db.statistics).baseline ~= nil
  local out = {}
  local function add(s) out[#out + 1] = s end
  if de() then
    add(section("Deine Chronik", "MyCharForever führt ein Tagebuch für deinen Charakter: wann du welches Level erreicht hast, wo du warst und was du erlebt hast. "
      .. "Alles wird nur lokal auf deinem Rechner gespeichert und nirgends hin gesendet."))
    add(momentsSection())
    if first > 1 then
      add(section("Wichtig: Du startest mitten im Spiel",
        "Dein Charakter ist schon Level " .. first .. ". Aufgezeichnet wird ab jetzt. Für Level 1 bis " .. (first - 1) .. " gibt es deshalb nicht:\n"
        .. "• keinen Reisepfad auf der Karte\n• keine Level-Screenshots und keine Ausrüstung pro Level\n"
        .. "• keine Zeitpunkte und Einzelereignisse (Tode, Quests, Dungeons, Bosse, Beute)\n• keinen Berufsverlauf, nur den aktuellen Stand\n"
        .. (hasStats and "Übernommen werden nur die Gesamtwerte aus der Statistik des Spiels (Kills, Tode, Quests, Gold usw.)."
            or "Gesamtwerte aus der Statistik des Spiels (Kills, Tode, Quests, Gold usw.) werden übernommen, sobald sie gelesen wurden.")))
    else
      add(section("Du startest am Anfang", "Dein Charakter ist noch ganz neu, deshalb wird deine Chronik von Level 1 an vollständig."))
    end
    add(section("Das wird aufgezeichnet",
      "• Level-Up-Infos: Zeitpunkt, Ort, Dauer und Ausrüstung pro Level\n"
      .. "• Dungeons: Besuche, Bosse und Beute\n"
      .. "• Reisepfad: deine Route als Linie auf der Weltkarte, mit Flugrouten sowie Todes- und Journalmarkern\n"
      .. "• Berufe: Skill-Verlauf, gelernte Rezepte, Sammeln und Herstellen\n"
      .. "• Automatische Screenshots zu Meilensteinen: bei jedem Level-Up, optional auch bei Tod, Login oder wertvoller Ausrüstung (in den Einstellungen wählbar)\n"
      .. "Dazu kommen Erfolge und Geheimnisse, ein Journal, Statistiken und ein Export deiner Daten."))
    add(section("Hinweis zu Screenshots", "WoW erlaubt Addons nicht, Screenshots anzuzeigen. Deine Bilder siehst du als Fotobuch auf der Website (/mcf website)."))
    add(section("Die Website", MCF:GetWebsiteText()))
    add(section("Mehr Einstellungen", "Screenshots, Reisepfad, Weltdrops, Wartung und mehr stellst du hier ein: " .. WHITE
      .. "Übersicht > Einstellungen" .. END .. " (Button unten rechts im Hauptfenster), " .. WHITE .. "/mcf settings" .. END
      .. " oder " .. WHITE .. "Spielmenü > Optionen > AddOns > MyCharForever" .. END .. "."))
  else
    add(section("Your chronicle", "MyCharForever keeps a diary for your character: when you reached each level, where you were and what you experienced. "
      .. "Everything is stored locally on your computer and is not sent anywhere."))
    add(momentsSection())
    if first > 1 then
      add(section("Important: you are starting mid-game",
        "Your character is already level " .. first .. ". Recording starts now. For levels 1 to " .. (first - 1) .. " there will therefore be no:\n"
        .. "• travel path on the map\n• level screenshots or gear per level\n"
        .. "• timestamps or individual events (deaths, quests, dungeons, bosses, loot)\n• profession history, only the current state\n"
        .. (hasStats and "Only the totals from the game's Statistics pane are taken over (kills, deaths, quests, gold, etc.)."
            or "Totals from the game's Statistics pane (kills, deaths, quests, gold, etc.) are taken over as soon as they have been read.")))
    else
      add(section("You are starting at the beginning", "Your character is brand new, so your chronicle will be complete from level 1."))
    end
    add(section("What is recorded",
      "• Level-up info: time, place, duration and gear per level\n"
      .. "• Dungeons: visits, bosses and loot\n"
      .. "• Travel path: your route as a line on the world map, with flight paths and death and journal markers\n"
      .. "• Professions: skill history, learned recipes, gathering and crafting\n"
      .. "• Automatic screenshots at milestones: on every level-up, optionally also on death, login or valuable gear (selectable in the settings)\n"
      .. "Also: achievements and secrets, a journal, statistics and an export of your data."))
    add(section("Note on screenshots", "WoW does not allow addons to display screenshots. You can see your pictures as a photo book on the website (/mcf website)."))
    add(section("The website", MCF:GetWebsiteText()))
    add(section("More settings", "Screenshots, travel path, world drops, maintenance and more are set here: " .. WHITE
      .. "Overview > Settings" .. END .. " (button at the bottom right of the main window), " .. WHITE .. "/mcf settings" .. END
      .. " or " .. WHITE .. "Game Menu > Options > AddOns > MyCharForever" .. END .. "."))
  end
  return table.concat(out)
end

-- Stage one: short, with the website hint.
function MCF:BuildWelcomeIntro()
  local ch = tbl(tbl(MyCharForeverDB).character)
  local first = tonumber(ch.firstSeenLevel) or 1
  local out = {}
  local function add(s) out[#out + 1] = s end
  if de() then
    add(section("Deine Chronik", "MyCharForever führt ein Tagebuch für deinen Charakter: Level-Ups, Reisepfad, Dungeons, Screenshots und mehr. "
      .. "Alles bleibt lokal auf deinem Rechner."))
    add(momentsSection())
    if first > 1 then
      add(section("Du startest mitten im Spiel", "Aufgezeichnet wird ab Level " .. first .. ". Was für die Level davor fehlt, steht unter \"Mehr erfahren\"."))
    end
    add(section("Schönere Darstellung im Browser", MCF:GetWebsiteText()
      .. "\n" .. GREY .. "Adresse: " .. END .. WHITE .. MCF.Website.host .. END .. GREY .. "  (Button \"Website\" unten)" .. END))
    add(GREY .. "Die ganze Erklärung, was aufgezeichnet wird und wo du alles einstellst, findest du unter \"Mehr erfahren\"." .. END)
  else
    add(section("Your chronicle", "MyCharForever keeps a diary for your character: level-ups, travel path, dungeons, screenshots and more. "
      .. "Everything stays local on your computer."))
    add(momentsSection())
    if first > 1 then
      add(section("You are starting mid-game", "Recording starts at level " .. first .. ". What is missing for the earlier levels is explained under \"Learn more\"."))
    end
    add(section("Nicer display in your browser", MCF:GetWebsiteText()
      .. "\n" .. GREY .. "Address: " .. END .. WHITE .. MCF.Website.host .. END .. GREY .. "  (\"Website\" button below)" .. END))
    add(GREY .. "The full explanation of what is recorded and where to change settings is under \"Learn more\"." .. END)
  end
  return table.concat(out)
end

local stage = 1 -- 1 = short page, 2 = full text
local window, body, openButton, moreButton, siteButton, sizeLabel, popupCheck, popupLabel, keyLabel, keyButton
local sizeButtons = {}
local CONTROLS_H = 108 -- height of the three rows above the text (font size, popups, screenshot key)

local function scaledFont(fs, template)
  local path, size, flags = _G[template]:GetFont()
  if path then fs:SetFont(path, (size or 12) * (MCF.GetFontScale and MCF:GetFontScale() or 1), flags) end
end

local function layoutText()
  scaledFont(body, "GameFontHighlight")
  scaledFont(sizeLabel, "GameFontNormal")
  scaledFont(popupLabel, "GameFontNormal")
  scaledFont(keyLabel, "GameFontNormal")
  body:SetText(stage == 1 and MCF:BuildWelcomeIntro() or MCF:BuildWelcomeText())
  window.child:SetHeight(math.max(100, CONTROLS_H + body:GetStringHeight() + 16))
end

local function refreshControls()
  sizeLabel:SetText(de() and "Schriftgröße:" or "Font size:")
  popupLabel:SetText(de() and "Pop-ups für Erfolge und ikonische Momente anzeigen" or "Show popups for achievements and iconic moments")
  popupCheck:SetHitRectInsets(0, -(popupLabel:GetStringWidth() + 8), 0, 0) -- the label is part of the clickable / hoverable area
  local current = MCF:GetFontScale()
  for _, b in ipairs(sizeButtons) do
    local c = b.choice
    local name = de() and c[2] or c[3]
    b:SetText(c[1] == current and (GOLD .. name .. END) or name) -- the chosen size is gold
  end
  moreButton:SetText(stage == 1 and (de() and "Mehr erfahren" or "Learn more") or (de() and "Zurück" or "Back"))
  siteButton:SetText("Website")
  keyLabel:SetText(de() and "Chronik-Screenshot-Taste:" or "Chronicle screenshot key:")
  if keyButton.RefreshKey then keyButton.RefreshKey() end
  local st = tbl(tbl(MyCharForeverDB).settings)
  popupCheck:SetChecked(st.achievementNotify ~= false or st.iconicPopup ~= false)
end

local function build()
  if window then return end
  window = MCF.Kit.Window("MyCharForeverWelcomeFrame", {w = W.width, h = W.height, level = 870, scroll = true})
  window:HookScript("OnHide", function() if MCF.mainFrame then MCF.mainFrame:SetAlpha(1) end end)
  -- Own logo next to the title (same picture as the minimap button and the achievement popup).
  window.logo = window:CreateTexture(nil, "ARTWORK")
  window.logo:SetSize(30, 30); window.logo:SetPoint("TOPLEFT", 14, -5)
  window.logo:SetTexture(MCF.LOGO_PATH)
  window.title:ClearAllPoints(); window.title:SetPoint("LEFT", window.logo, "RIGHT", 10, 0)
  sizeLabel = window.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  sizeLabel:SetPoint("TOPLEFT", 8, -8)
  local previous
  for _, c in ipairs(MCF.FontScaleChoices) do
    local b = CreateFrame("Button", nil, window.child, "UIPanelButtonTemplate")
    b.choice = c
    b:SetSize(130, 24)
    if previous then b:SetPoint("LEFT", previous, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 8, -28) end
    b:SetScript("OnClick", function()
      MCF:SetFontScale(c[1])
      refreshControls(); layoutText() -- the window itself follows the new size right away
    end)
    sizeButtons[#sizeButtons + 1] = b
    previous = b
  end
  popupCheck = CreateFrame("CheckButton", nil, window.child, "UICheckButtonTemplate")
  popupCheck:SetPoint("TOPLEFT", 4, -50)
  popupLabel = window.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  popupLabel:SetPoint("LEFT", popupCheck, "RIGHT", 4, 0)
  popupCheck:SetScript("OnClick", function(self)
    -- one switch for both kinds of popups (each one can still be set separately in the settings)
    local st = tbl(MyCharForeverDB).settings
    if st then
      local on = self:GetChecked() and true or false
      st.achievementNotify = on
      st.iconicPopup = on
    end
  end)
  popupCheck:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(de() and "Erfolge und ikonische Momente" or "Achievements and iconic moments", 1, 0.82, 0)
    GameTooltip:AddLine(de()
      and "Das Addon hat eigene Erfolge eingebaut und blendet bei Erreichen ein Achievement ein. Wenn du das nicht willst, kannst du es hier deaktivieren. Dann bleiben auch die Pop-ups für ikonische Momente aus."
      or "The addon has its own achievements and shows a popup when you earn one. If you do not want that, you can switch it off here. The popups for iconic moments stay off as well.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  popupCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
  keyLabel = window.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  keyLabel:SetPoint("TOPLEFT", 8, -84)
  keyButton = CreateFrame("Button", nil, window.child, "UIPanelButtonTemplate")
  keyButton:SetSize(150, 22); keyButton:SetPoint("LEFT", keyLabel, "RIGHT", 10, 0)
  keyButton.RefreshKey = MCF:AttachShortcutCapture(keyButton) -- same picker as in the settings
  body = window.child:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  body:SetPoint("TOPLEFT", 8, -CONTROLS_H - 4)
  body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetSpacing(2)
  body:SetWidth(W.width - 70)
  openButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  openButton:SetSize(130, 24); openButton:SetPoint("RIGHT", window.closeButton, "LEFT", -8, 0)
  siteButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  siteButton:SetSize(100, 24); siteButton:SetPoint("RIGHT", openButton, "LEFT", -8, 0)
  siteButton:SetScript("OnClick", function() if MCF.ShowWebsite then MCF:ShowWebsite() end end)
  moreButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  moreButton:SetSize(120, 24); moreButton:SetPoint("RIGHT", siteButton, "LEFT", -8, 0)
  moreButton:SetScript("OnClick", function()
    stage = stage == 1 and 2 or 1
    refreshControls(); layoutText()
    window.scroll:SetVerticalScroll(0)
  end)
  openButton:SetScript("OnClick", function()
    window:Hide()
    -- never toggle: when the chronicle is already open (first-open case) it simply stays open
    if MCF.mainFrame and MCF.mainFrame:IsShown() then MCF.mainFrame:Raise()
    elseif MCF.ShowMainWindow then MCF:ShowMainWindow() end
  end)
end

function MCF:ShowWelcome()
  build()
  window.title:SetText(de() and "Willkommen bei MyCharForever" or "Welcome to MyCharForever")
  openButton:SetText(de() and "Chronik öffnen" or "Open chronicle")
  stage = 1
  refreshControls()
  layoutText()
  window:Show(); window:Raise()
  if MCF.mainFrame and window:IsVisible() then MCF.mainFrame:SetAlpha(W.mainDimAlpha) end
  -- "seen" only counts when the window can really be seen (not while the UI is hidden behind an intro movie)
  if window:IsVisible() then
    local ch = tbl(MyCharForeverDB).character
    if ch then ch.welcomeShown = true end
  end
end

local function pending()
  local ch = tbl(tbl(MyCharForeverDB).character)
  return not ch.welcomeShown
end

-- Hidden UI or combat: the window would open behind something or in the way, so it waits.
local function busy()
  if UIParent and not UIParent:IsShown() then return true end
  if InCombatLockdown and InCombatLockdown() then return true end
  return false
end

local ticker
local function tryShow()
  if not pending() then
    if ticker then ticker:Cancel(); ticker = nil end
    return
  end
  if busy() then return end -- the ticker below tries again
  if ticker then ticker:Cancel(); ticker = nil end
  MCF:ShowWelcome()
end

local function startWaiting()
  if ticker or not pending() then return end
  ticker = C_Timer.NewTicker(W.retryEvery, function() MCF:SafeCall("Welcome", tryShow) end, W.retryMax)
end

local function trigger(delay)
  C_Timer.After(delay, function() MCF:SafeCall("Welcome", function() if pending() then startWaiting(); tryShow() end end) end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    -- the chronicle window is created later (UI.lua), so hook it once the addon has loaded completely
    MCF:SafeCall("Welcome", function()
      local main = MCF.mainFrame
      if main and main.HookScript then
        main:HookScript("OnShow", function() if pending() then trigger(W.afterOpen) end end)
      end
    end)
  elseif event == "PLAYER_LEVEL_UP" then
    -- fallback: the chronicle was not opened yet; remind after the level-up screenshot
    if pending() then trigger((MCF.LevelScreenshotDelay or 2) + W.afterScreenshot) end
  end
end)

MCF:AddCommand{group="main", usage="/mcf welcome", key="welcome",
  de="Willkommensfenster anzeigen", en="Show the welcome window",
  run=function() MCF:ShowWelcome() end}
