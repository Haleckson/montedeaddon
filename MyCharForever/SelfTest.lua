local addonName, MCF = ...
-- Self test and bug report, made for testers who do not read code.
--   /mcf selftest  checks the assumptions the addon makes about the game (interfaces, emote names, gathering
--                  spells, capital maps, chat texts) and whether the trackers have recorded anything.
--   /mcf report    one text with versions, settings, data size, errors and the self test, to paste into a bug report.
-- The report contains no character name and no realm. Nothing is sent anywhere; the tester copies the text.
-- Every limit lives in MCF.SelfTest below.

MCF.SelfTest = {
  emoteScanMax = 1500,   -- EMOTE<n>_TOKEN globals are read up to this n
  recentEvents = 10,     -- event types listed in the report (type and level only)
  sizeRows = 8,          -- biggest saved-data groups listed in the report
}
local S = MCF.SelfTest

local function de() return MCF:GetLanguage() == "deDE" end
local function tbl(v) return type(v) == "table" and v or {} end
local function db() return MyCharForeverDB end

-- Status words, one place.
local STATUS = {ok = "OK", warn = "WARN", fail = "FAIL", info = "INFO"}

-- Interfaces the addon calls. A missing one is named in the result.
local API_CHECKS = {
  {"C_Map.GetBestMapForUnit", function() return C_Map and C_Map.GetBestMapForUnit end},
  {"C_Map.GetMapInfo", function() return C_Map and C_Map.GetMapInfo end},
  {"C_Timer.NewTicker", function() return C_Timer and C_Timer.NewTicker end},
  {"C_UnitAuras.GetAuraDataByIndex", function() return C_UnitAuras and C_UnitAuras.GetAuraDataByIndex end},
  {"C_Reputation / GetFactionInfo", function() return (C_Reputation and C_Reputation.GetFactionDataByIndex) or GetFactionInfo end},
  {"GetUnitSpeed", function() return GetUnitSpeed end},
  {"UnitPosition", function() return UnitPosition end},
  {"TransmogUtil", function() return TransmogUtil end},
  {"C_Item.GetItemQualityByID", function() return C_Item and C_Item.GetItemQualityByID end},
  {"C_TradeSkillUI.GetRecipeInfo", function() return C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo end},
  {"C_Spell.GetSpellName", function() return (C_Spell and C_Spell.GetSpellName) or GetSpellInfo end},
  {"C_FriendList.GetNumFriends", function() return C_FriendList and C_FriendList.GetNumFriends end},
  {"C_AddOns.GetAddOnCPUUsage", function() return (C_AddOns and C_AddOns.GetAddOnCPUUsage) or GetAddOnCPUUsage end},
  {"debugstack", function() return debugstack end},
}

local function spellName(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, name = pcall(C_Spell.GetSpellName, id)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  if GetSpellInfo then
    local ok, name = pcall(GetSpellInfo, id)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
end

local function clientEmoteTokens()
  local set, n = {}, 0
  for i = 1, S.emoteScanMax do
    local token = _G["EMOTE" .. i .. "_TOKEN"]
    if type(token) == "string" then set[token:upper()] = true; n = n + 1 end
  end
  return set, n
end

-- One check = {name_de, name_en, run}; run returns status, detail.
local CHECKS = {
  {"Spiel-Schnittstellen", "Game interfaces", function()
    local missing = {}
    for _, c in ipairs(API_CHECKS) do
      local ok, v = pcall(c[2])
      if not (ok and v) then missing[#missing + 1] = c[1] end
    end
    if #missing == 0 then return STATUS.ok, #API_CHECKS .. " / " .. #API_CHECKS end
    return STATUS.warn, (de() and "fehlen: " or "missing: ") .. table.concat(missing, ", ")
  end},

  {"Gespeicherte Daten", "Saved data", function()
    local d = db()
    if not d then return STATUS.fail, de() and "keine Datenbank geladen" or "no database loaded" end
    local problems = {}
    if tonumber(d.dbVersion) ~= MCF.DB_VERSION then problems[#problems + 1] = "dbVersion " .. tostring(d.dbVersion) .. " / " .. tostring(MCF.DB_VERSION) end
    if d.newerThanAddon then problems[#problems + 1] = de() and "Daten stammen von einer neueren Addon-Version" or "data written by a newer addon version" end
    if d.recovered and next(d.recovered) then
      local keys = {}
      for k in pairs(d.recovered) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      problems[#problems + 1] = (de() and "repariert: " or "repaired: ") .. table.concat(keys, ",")
    end
    if #problems == 0 then return STATUS.ok, "dbVersion " .. tostring(d.dbVersion) end
    return STATUS.warn, table.concat(problems, "; ")
  end},

  {"Fehlerprotokoll", "Error log", function()
    local distinct, total = MCF:GetErrorCount()
    if distinct == 0 then return STATUS.ok, de() and "keine Fehler" or "no errors" end
    return STATUS.warn, string.format(de() and "%d verschiedene, %d Vorfälle (/mcf errors)" or "%d distinct, %d occurrences (/mcf errors)", distinct, total)
  end},

  {"Tastenkürzel", "Key binding", function()
    -- The action only exists when Bindings.xml was loaded. A key stored for an unknown action does nothing.
    local action = "MYCHARFOREVER_CHRONICLE_SCREENSHOT"
    local declared = false
    if GetNumBindings and GetBinding then
      for i = 1, GetNumBindings() do
        if (GetBinding(i)) == action then declared = true; break end
      end
    else
      return STATUS.info, "-"
    end
    if not declared then
      return STATUS.fail, de() and "Aktion unbekannt: Bindings.xml wurde nicht geladen (Spiel neu starten)" or "action unknown: Bindings.xml was not loaded (restart the game)"
    end
    local key = MCF.GetChronicleScreenshotBinding and MCF:GetChronicleScreenshotBinding()
    local keyText = key and MCF:FormatBindingKey(key) or (de() and "keine Taste zugewiesen" or "no key assigned")
    local hasFn = type(_G.MyCharForever_TakeManualChronicleScreenshot) == "function"
    if not hasFn then return STATUS.fail, de() and "Funktion fehlt" or "function missing" end
    return STATUS.ok, keyText
  end},

  {"Addon-Nachrichten", "Addon messages", function()
    -- Used to find other MyCharForever users (Social.lua). The last result per channel shows what the game allows.
    local P = MCF.Presence
    if not P then return STATUS.info, "-" end
    if not ((C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage) then
      return STATUS.fail, de() and "Schnittstelle fehlt" or "interface missing"
    end
    local parts = {}
    for channel, result in pairs(P.lastResult or {}) do parts[#parts + 1] = channel .. "=" .. result end
    table.sort(parts)
    local last = #parts > 0 and table.concat(parts, ", ") or (de() and "noch nichts gesendet (/mcf ping)" or "nothing sent yet (/mcf ping)")
    if not P.registered then return STATUS.warn, (de() and "Kürzel nicht angemeldet; " or "prefix not registered; ") .. last end
    return STATUS.ok, last
  end},

  {"Aufzeichnung läuft", "Recording is running", function()
    local d = db() or {}
    local empty = {}
    local function need(name, cond) if not cond then empty[#empty + 1] = name end end
    need("sessions", #tbl(d.sessions) > 0)
    need("levels", next(tbl(d.levels)) ~= nil)
    need("levelActivity", next(tbl(d.levelActivity)) ~= nil)
    need("gearByLevel", next(tbl(d.gearByLevel)) ~= nil)
    need("reputation", next(tbl(tbl(d.reputation).current)) ~= nil)
    need("professions", next(tbl(tbl(d.professions).current)) ~= nil)
    need("locationTime", next(tbl(tbl(d.locationTime).zones)) ~= nil)
    need("firstVisitedZones", next(tbl(d.firstVisitedZones)) ~= nil)
    need("journey", #tbl(d.journey) > 0 or #tbl(tbl(d.journey).segments) > 0 or d.settings and d.settings.trackJourney == false)
    if #empty == 0 then return STATUS.ok, "" end
    return STATUS.warn, (de() and "noch leer: " or "still empty: ") .. table.concat(empty, ", ")
      .. (de() and " (evtl. noch nicht gespielt)" or " (maybe not played yet)")
  end},

  {"Emote-Namen", "Emote names", function()
    if not MCF.GetAchievementEmoteTokens then return STATUS.info, "-" end
    local client, n = clientEmoteTokens()
    if n == 0 then return STATUS.warn, de() and "Emote-Liste des Clients nicht lesbar" or "client emote list not readable" end
    local bad, tokens = {}, MCF:GetAchievementEmoteTokens()
    for _, token in ipairs(tokens) do if not client[token] then bad[#bad + 1] = token end end
    if #bad == 0 then return STATUS.ok, #tokens .. " / " .. #tokens end
    return STATUS.fail, (de() and "unbekannt im Spiel: " or "unknown in game: ") .. table.concat(bad, ", ")
  end},

  {"Sammel-Zauber", "Gathering spells", function()
    local g = MCF.GatherSpells
    if not g then return STATUS.info, "-" end
    local lines, bad = {}, 0
    for id, kind in pairs(g.ids) do
      local name = spellName(id)
      local matches = false
      if name then
        local low = name:lower()
        for _, word in ipairs(g.words[kind] or {}) do if low:find(word, 1, true) then matches = true end end
      end
      if not name and g.optional and g.optional[kind] then
        lines[#lines + 1] = kind .. (de() and "=nicht im Spiel (ok)" or "=not in this game (ok)")
      else
        if not name or not matches then bad = bad + 1 end
        lines[#lines + 1] = string.format("%s=%s%s", kind, tostring(name or "?"), matches and "" or " (!)")
      end
    end
    table.sort(lines)
    return bad == 0 and STATUS.ok or STATUS.warn, table.concat(lines, ", ")
  end},

  {"Hauptstadt-Karten", "Capital maps", function()
    if not MCF.GetCapitalMapIDs then return STATUS.info, "-" end
    local names, bad = {}, 0
    for _, id in ipairs(MCF:GetCapitalMapIDs()) do
      local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
      if info and info.name then names[#names + 1] = id .. "=" .. info.name else bad = bad + 1; names[#names + 1] = id .. "=?" end
    end
    return bad == 0 and STATUS.ok or STATUS.fail, table.concat(names, ", ")
  end},

  {"Chat-Texte (Rezepte, Beute)", "Chat texts (recipes, loot)", function()
    local missing = {}
    for _, key in ipairs({"ERR_LEARN_RECIPE_S", "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF"}) do
      if type(_G[key]) ~= "string" then missing[#missing + 1] = key end
    end
    if #missing > 0 then return STATUS.fail, (de() and "fehlen: " or "missing: ") .. table.concat(missing, ", ") end
    if MCF.RecipeNameFromMessage then
      local ok, name = pcall(MCF.RecipeNameFromMessage, string.format(ERR_LEARN_RECIPE_S, "|cff1eff00|Hspell:1|h[Testrezept]|h|r"))
      if not (ok and name == "Testrezept") then return STATUS.fail, de() and "Rezept-Meldung wird nicht erkannt" or "recipe message not recognised" end
    end
    return STATUS.ok, ""
  end},

  {"Chat-Ausgabe", "Chat output", function()
    local st = tbl(db() and db().settings)
    if st.chatMessages == true or st.debugChat == true then
      return STATUS.info, de() and "Status- oder Debug-Meldungen im Chat sind eingeschaltet" or "status or debug chat messages are switched on"
    end
    return STATUS.ok, de() and "aus (Standard)" or "off (default)"
  end},

  {"CPU-Messung", "CPU profiling", function()
    local on = GetCVar and GetCVar("scriptProfile")
    return STATUS.info, on == "1" and (de() and "an" or "on") or (de() and "aus (/console scriptProfile 1 + /reload, dann /mcf cpu)" or "off (/console scriptProfile 1 + /reload, then /mcf cpu)")
  end},
}

-- Runs every check. Returns a list of {name, status, detail} and the counts per status.
function MCF:RunSelfTest()
  local results, counts = {}, {OK = 0, WARN = 0, FAIL = 0, INFO = 0}
  for _, c in ipairs(CHECKS) do
    local ok, status, detail = pcall(c[3])
    if not ok then status, detail = STATUS.fail, tostring(status) end
    status = status or STATUS.info
    counts[status] = (counts[status] or 0) + 1
    results[#results + 1] = {name = de() and c[1] or c[2], status = status, detail = detail or ""}
  end
  return results, counts
end

function MCF:BuildSelfTestText()
  local results, counts = self:RunSelfTest()
  local lines = {string.format(de() and "Selbsttest: %d OK, %d Warnungen, %d Fehler" or "Self test: %d OK, %d warnings, %d failures",
    counts.OK, counts.WARN, counts.FAIL)}
  for _, r in ipairs(results) do
    lines[#lines + 1] = string.format("[%-4s] %s%s", r.status, r.name, r.detail ~= "" and (": " .. r.detail) or "")
  end
  return table.concat(lines, "\n"), counts
end

local function scalarSettings()
  local out = {}
  for k, v in pairs(tbl(db() and db().settings)) do
    local t = type(v)
    if t == "boolean" or t == "number" or t == "string" then out[#out + 1] = k .. "=" .. tostring(v) end
  end
  table.sort(out)
  return table.concat(out, ", ")
end

function MCF:BuildBugReport()
  local d = db() or {}
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  local _, _, _, toc = GetBuildInfo()
  local ch = tbl(d.character)
  add("== MyCharForever " .. (de() and "Fehlerbericht" or "bug report") .. " ==")
  add("Addon " .. tostring(self.VERSION) .. " | Interface " .. tostring(toc) .. " | DB " .. tostring(d.dbVersion)
    .. " | " .. tostring(GetLocale and GetLocale()) .. " | " .. (de() and "Addon-Sprache deDE" or "addon language enUS"))
  add(string.format("%s %s, Level %s | UI scale %s", tostring(ch.race), tostring(ch.class), tostring(UnitLevel("player")),
    tostring(UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or "?")))
  add("")
  add("-- " .. (de() and "Einstellungen" or "Settings"))
  add(scalarSettings())
  add("")
  add("-- " .. (de() and "Datenumfang" or "Data size"))
  local rows, total = self:GetDataSizeReport()
  add(self:FormatBytes(total))
  for i = 1, math.min(S.sizeRows, #rows) do add(string.format("  %-18s %10s (%d)", rows[i].key, self:FormatBytes(rows[i].bytes), rows[i].count)) end
  add(self:DescribeMaintenance(tbl(d.maintenance).last))
  add("")
  add("-- " .. (de() and "Letzte Ereignisse (nur Art und Level)" or "Recent events (type and level only)"))
  local events = tbl(d.events)
  local parts = {}
  for i = math.max(1, #events - S.recentEvents + 1), #events do
    parts[#parts + 1] = tostring(tbl(events[i]).type or tbl(events[i]).kind or "?") .. "@" .. tostring(tbl(events[i]).level or "?")
  end
  add(#parts > 0 and table.concat(parts, ", ") or "-")
  add("")
  add("-- " .. (de() and "Selbsttest" or "Self test"))
  add((self:BuildSelfTestText()))
  add("")
  add("-- " .. (de() and "Fehlerprotokoll" or "Error log"))
  add(self:BuildErrorReport())
  return table.concat(lines, "\n")
end

MCF:AddCommand{group="main", usage="/mcf selftest", key="selftest",
  de="Prüft die Annahmen des Addons über das Spiel (für Tester)",
  en="Checks the addon's assumptions about the game (for testers)",
  run=function()
    local _, counts = MCF:BuildSelfTestText()
    print(string.format("|cff00ccffMyCharForever|r: " .. (de() and "Selbsttest: %d OK, %d Warnungen, %d Fehler. Details im Fenster."
      or "Self test: %d OK, %d warnings, %d failures. Details in the window."), counts.OK, counts.WARN, counts.FAIL))
    if MCF.ShowSelfTestExport then MCF:ShowSelfTestExport() end
  end}

MCF:AddCommand{group="main", usage="/mcf report", key="report",
  de="Fehlerbericht zum Kopieren erstellen (für Tester)",
  en="Create a bug report to copy (for testers)",
  run=function() if MCF.ShowBugReportExport then MCF:ShowBugReportExport() end end}
