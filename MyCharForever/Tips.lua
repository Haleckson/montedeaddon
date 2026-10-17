local addonName, MCF = ...
-- Rare, quiet reminders in the chat (no popups): make a character portrait, visit the website.
-- Rules (all numbers live in MCF.Tips): at most one tip per login, never in combat, never while the welcome window is
-- still pending, a pause between tips of the same kind and a fixed number of repeats, then the tip stays silent.
-- Setting showTips (default on) switches all of it off. State (counts, last time) lives in settings.tips.

MCF.Tips = {
  delay = 40,                 -- seconds after login (after the welcome window and the login spam)
  portraitMinLevel = 10,      -- before that the character is not worth a portrait
  portraitPauseDays = 14, portraitMax = 3,
  sitePauseDays = 30, siteMax = 3,
  siteMinScreenshots = 10,    -- the photo book needs something to show: this many screenshots, or the first death
}
local T = MCF.Tips

local function de() return MCF:GetLanguage() == "deDE" end
local DAY = 86400

local function hasPortrait()
  for _, s in ipairs((MyCharForeverDB and MyCharForeverDB.screenshots) or {}) do
    if s.reason == "PORTRAIT" then return true end
  end
  return false
end

local function due(state, kind, pauseDays, max)
  local count = tonumber(state[kind .. "Count"]) or 0
  if count >= max then return false end
  local last = tonumber(state[kind .. "Last"]) or 0
  return last == 0 or time() - last >= pauseDays * DAY
end

local function say(text) print("|cff00ccffMyCharForever|r: " .. text) end

function MCF:ShowTip()
  local db = MyCharForeverDB
  if not db then return false end
  local st = db.settings
  if not st or st.showTips == false then return false end
  if InCombatLockdown and InCombatLockdown() then return false end
  if not (db.character and db.character.welcomeShown) then return false end
  st.tips = type(st.tips) == "table" and st.tips or {}
  local state = st.tips
  local level = UnitLevel("player") or 1
  if level >= T.portraitMinLevel and not hasPortrait() and due(state, "portrait", T.portraitPauseDays, T.portraitMax) then
    state.portraitCount = (tonumber(state.portraitCount) or 0) + 1; state.portraitLast = time()
    say(de() and "Tipp: Mit |cffffffff/mcf portrait|r machst du ein Porträt deines Charakters für die Webseite. Die Erinnerung kommt nur selten; abschalten in den Einstellungen („Tipps und Erinnerungen“)."
      or "Tip: |cffffffff/mcf portrait|r takes a portrait of your character for the website. This reminder is rare; switch it off in the settings (“Show tips and reminders”).")
    return true
  end
  local shots = #(db.screenshots or {})
  local ready = (tonumber(db.stats and db.stats.deaths) or 0) >= 1 or shots >= T.siteMinScreenshots
  if ready and due(state, "site", T.sitePauseDays, T.siteMax) then
    state.siteCount = (tonumber(state.siteCount) or 0) + 1; state.siteLast = time()
    say(de() and string.format("Tipp: Auf %s wird deine Chronik zum Fotobuch, schöner als im Spiel (|cffffffff/mcf website|r zeigt die Adresse). Die Erinnerung kommt nur selten; abschalten in den Einstellungen („Tipps und Erinnerungen“).", MCF.Website and MCF.Website.host or "mycharforever.com")
      or string.format("Tip: on %s your chronicle becomes a photo book, nicer than in the game (|cffffffff/mcf website|r shows the address). This reminder is rare; switch it off in the settings (“Show tips and reminders”).", MCF.Website and MCF.Website.host or "mycharforever.com"))
    return true
  end
  return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
  C_Timer.After(T.delay, function() MCF:SafeCall("Tips", function() MCF:ShowTip() end) end)
end)
