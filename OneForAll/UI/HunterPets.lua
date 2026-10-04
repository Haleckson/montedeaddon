local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton = UI.makeTexture, UI.makeButton
local createPanelBanner = UI.createPanelBanner

-- Hunter Pets tab: pet families, pet abilities (ranks, where to learn them)
-- and notable rare tames. Data: Data/HunterPets.lua.

local FAMILY_ICON = {
  ["Bat"]="Ability_Hunter_Pet_Bat", ["Bear"]="Ability_Hunter_Pet_Bear", ["Boar"]="Ability_Hunter_Pet_Boar",
  ["Carrion Bird"]="Ability_Hunter_Pet_Vulture", ["Cat"]="Ability_Hunter_Pet_Cat", ["Crab"]="Ability_Hunter_Pet_Crab",
  ["Crocolisk"]="Ability_Hunter_Pet_Crocolisk", ["Gorilla"]="Ability_Hunter_Pet_Gorilla", ["Hyena"]="Ability_Hunter_Pet_Hyena",
  ["Owl"]="Ability_Hunter_Pet_Owl", ["Raptor"]="Ability_Hunter_Pet_Raptor", ["Scorpid"]="Ability_Hunter_Pet_Scorpid",
  ["Spider"]="Ability_Hunter_Pet_Spider", ["Tallstrider"]="Ability_Hunter_Pet_TallStrider", ["Turtle"]="Ability_Hunter_Pet_Turtle",
  ["Wind Serpent"]="Ability_Hunter_Pet_WindSerpent", ["Wolf"]="Ability_Hunter_Pet_Wolf",
}
local ABILITY_ICON = {
  ["Bite"]="Ability_Racial_Cannibalize", ["Claw"]="Ability_Druid_Rake", ["Charge"]="Ability_Hunter_Pet_Boar",
  ["Cower"]="Ability_Druid_Cower", ["Dash"]="Ability_Druid_Dash", ["Dive"]="Spell_Shadow_BurningSpirit",
  ["Furious Howl"]="Ability_Hunter_Pet_Wolf", ["Lightning Breath"]="Spell_Nature_Lightning",
  ["Prowl"]="Ability_Druid_SupriseAttack", ["Scorpid Poison"]="Ability_PoisonSting", ["Screech"]="Ability_Hunter_Pet_Bat",
  ["Shell Shield"]="Ability_Hunter_Pet_Turtle", ["Thunderstomp"]="Ability_Hunter_Pet_Gorilla",
  ["Growl"]="Ability_Physical_Taunt", ["Arcane Resistance"]="Spell_Nature_StarFall",
  ["Fire Resistance"]="Spell_Fire_FireArmor", ["Frost Resistance"]="Spell_Frost_FrostWard",
  ["Nature Resistance"]="Spell_Nature_ResistNature", ["Shadow Resistance"]="Spell_Shadow_AntiShadow",
  ["Great Stamina"]="Spell_Nature_UnyeildingStamina", ["Natural Armor"]="Spell_Nature_SpiritArmor",
}
-- Icons come from the data (Petopia icon names); the tables above are fallbacks.
local dataIcon = {}
local function icon(map, name)
  return "Interface\\Icons\\" .. (dataIcon[name] or map[name] or "INV_Misc_QuestionMark")
end
local function indexIcons()
  for _, f in ipairs(FLT.PET_FAMILIES or {}) do if f.icon then dataIcon[f.name] = f.icon end end
  for _, a in ipairs(FLT.PET_ABILITIES or {}) do if a.icon then dataIcon[a.name] = a.icon end end
end

-- Round portrait look (like the boss portraits): circular alpha mask, with
-- SetPortraitToTexture as fallback on clients without mask textures.
local function makeRound(parentFrame, tex, path)
  if tex.AddMaskTexture and parentFrame.CreateMaskTexture then
    tex:SetTexture(path)
    local mask = parentFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(tex)
    tex:AddMaskTexture(mask)
  elseif SetPortraitToTexture then
    SetPortraitToTexture(tex, path)
  else
    tex:SetTexture(path)
  end
end

local GOLD = {1, 0.82, 0.20}
local LIST_W, ROW_W = 350, 338

-- Known pet abilities ---------------------------------------------------------
-- Hunters keep every pet ability rank they have learned; it is listed in the
-- Beast Training window. We read that window when it opens, plus the active
-- pet's spellbook, and store the highest known rank per ability per character
-- (ForeverCompanionCharDB.petAbilities). A known rank implies all lower ranks.
local petUI -- set by the panel; refreshed after a scan

local function knownTable()
  if type(ForeverCompanionCharDB) ~= "table" then return nil end
  ForeverCompanionCharDB.petAbilities = ForeverCompanionCharDB.petAbilities or {}
  return ForeverCompanionCharDB.petAbilities
end

local function rankNumber(sub)
  return tonumber(type(sub) == "string" and sub:match("(%d+)") or nil) or 1
end

local function noteKnown(name, rank)
  local t = knownTable()
  if not t or not name or name == "" then return false end
  rank = rank or 1
  if (t[name] or 0) < rank then t[name] = rank; return true end
  return false
end

function FLT:GetKnownPetRank(name)
  local t = knownTable()
  return t and t[name] or 0
end

local function scanBeastTraining()
  if not (GetNumCrafts and GetCraftInfo) then return end
  local line = GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()
  if line and line ~= "Beast Training" and line ~= (BEAST_TRAINING or "") then return end
  local changed = false
  for i = 1, GetNumCrafts() or 0 do
    local name, sub, kind = GetCraftInfo(i)
    if name and kind ~= "header" then
      if noteKnown(name, rankNumber(sub)) then changed = true end
    end
  end
  if knownTable() then ForeverCompanionCharDB.petAbilitiesScanned = true end
  if petUI and petUI.refreshKnown then petUI.refreshKnown() end
  return changed
end

-- Pet spellbook: the Forever client uses the modern C_SpellBook API (new
-- spellbook with search box); older clients have the global functions.
local function petSpellCount()
  if C_SpellBook and C_SpellBook.HasPetSpells then
    local ok, n = pcall(C_SpellBook.HasPetSpells)
    if ok and n then return n end
  end
  if HasPetSpells then local ok, n = pcall(HasPetSpells); if ok then return n end end
  return nil
end

local function petSpellName(i)
  if C_SpellBook then
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or 1
    if C_SpellBook.GetSpellBookItemName then
      local ok, name, sub = pcall(C_SpellBook.GetSpellBookItemName, i, bank)
      if ok and name then return name, sub end
    end
    if C_SpellBook.GetSpellBookItemInfo then
      local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
      if ok and type(info) == "table" and info.name then return info.name, info.subName end
    end
  end
  if GetSpellBookItemName then
    local ok, name, sub = pcall(GetSpellBookItemName, i, BOOKTYPE_PET or "pet")
    if ok and name then return name, sub end
  end
  if GetSpellName then
    local ok, name, sub = pcall(GetSpellName, i, BOOKTYPE_PET or "pet")
    if ok and name then return name, sub end
  end
end

local function scanPetSpellbook()
  local n = petSpellCount()
  if not n or n == 0 then return end
  local found = false
  for i = 1, n do
    local name, sub = petSpellName(i)
    if name and type(sub) == "string" and sub:match("%d") then
      noteKnown(name, rankNumber(sub)); found = true
    end
  end
  if found and knownTable() then ForeverCompanionCharDB.petAbilitiesScanned = true end
  if petUI and petUI.refreshKnown then petUI.refreshKnown() end
end
FLT.ScanPetAbilities = function() scanPetSpellbook(); scanBeastTraining() end

-- Stabled pets are only readable while the stable master window is open, so
-- the last seen list is stored per character (ForeverCompanionCharDB.stablePets).
local FAMILY_ALIAS_GLOBAL = { ["Owl"] = "Bird of Prey" }
local function scanStable()
  if type(ForeverCompanionCharDB) ~= "table" then return end
  local list = {}
  local function add(name, level, family)
    if name and family then list[#list + 1] = { name = name, level = level, family = FAMILY_ALIAS_GLOBAL[family] or family } end
  end
  if C_StableInfo and C_StableInfo.GetStablePetInfo then
    for i = 1, 10 do
      local ok, info = pcall(C_StableInfo.GetStablePetInfo, i)
      if ok and type(info) == "table" then add(info.name, info.level, info.familyName or info.family) end
    end
  elseif GetStablePetInfo then
    local slots = (GetNumStableSlots and GetNumStableSlots()) or 2
    for i = 1, math.max(slots, 2) do
      local ok, _, name, level, family = pcall(GetStablePetInfo, i)
      if ok then add(name, level, family) end
    end
  else
    return
  end
  ForeverCompanionCharDB.stablePets = list
  if petUI and petUI.refreshKnown then petUI.refreshKnown() end
end

function FLT:GetStabledPets()
  return type(ForeverCompanionCharDB) == "table" and ForeverCompanionCharDB.stablePets or {}
end

-- Nearby teacher alert ---------------------------------------------------------
-- When a tameable beast shows up (nameplate, target or mouseover) that teaches
-- an ability rank higher than you know, and that ability can be learned by the
-- family of your active pet or a stabled pet, show an alert.
local teacherIndex
local alerted = {}
local ALERT_REPEAT = 900 -- seconds before the same beast may alert again

function FLT:IsPetTeachAlertsEnabled()
  return not (type(ForeverCompanionDB) == "table" and ForeverCompanionDB.petTeachAlerts == false)
end
function FLT:SetPetTeachAlertsEnabled(v)
  if type(ForeverCompanionDB) == "table" then ForeverCompanionDB.petTeachAlerts = v and true or false end
end

-- Abilities that never trigger the alert (ForeverCompanionDB.petAlertIgnore).
-- Cower is hardly ever trained, so it is ignored by default.
local DEFAULT_IGNORE = { ["Cower"] = true }
local function ignoreTable()
  if type(ForeverCompanionDB) ~= "table" then return DEFAULT_IGNORE end
  if not ForeverCompanionDB.petAlertIgnore then
    ForeverCompanionDB.petAlertIgnore = {}
    for k in pairs(DEFAULT_IGNORE) do ForeverCompanionDB.petAlertIgnore[k] = true end
  end
  return ForeverCompanionDB.petAlertIgnore
end
function FLT:IsPetAlertIgnored(name) return ignoreTable()[name] and true or false end
function FLT:SetPetAlertIgnored(name, ignored)
  ignoreTable()[name] = ignored and true or nil
  if petUI and petUI.refreshKnown then petUI.refreshKnown() end
end

local function buildTeacherIndex()
  teacherIndex = {}
  for _, a in ipairs(FLT.PET_ABILITIES or {}) do
    for _, r in ipairs(a.ranks or {}) do
      for _, b in ipairs(r.learnFrom or {}) do
        if b.npcID then
          teacherIndex[b.npcID] = teacherIndex[b.npcID] or {}
          table.insert(teacherIndex[b.npcID], { ability = a, rank = r, beast = b })
        end
      end
    end
  end
end

local function myPetFamilies()
  local fams = {}
  if UnitExists and UnitExists("pet") and UnitCreatureFamily then
    local fam = UnitCreatureFamily("pet")
    if fam then fam = FAMILY_ALIAS_GLOBAL[fam] or fam; fams[fam] = (UnitName and UnitName("pet")) or "your pet" end
  end
  for _, sp in ipairs(FLT:GetStabledPets()) do
    if sp.family and not fams[sp.family] then fams[sp.family] = (sp.name or "?") .. ", stable" end
  end
  return fams
end

local function abilityFits(a, fams)
  local out = {}
  for _, fam in ipairs(a.families or {}) do
    if fam == "All families" then
      for f, who in pairs(fams) do out[#out + 1] = f .. " (" .. who .. ")" end
      return out
    elseif fams[fam] then
      out[#out + 1] = fam .. " (" .. fams[fam] .. ")"
    end
  end
  return out
end

local function npcIDFromGUID(guid)
  if type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "Creature" then return nil end
  return tonumber(id)
end

local snoozeUntil = 0

local function checkTeacher(unit)
  if not FLT:IsPetTeachAlertsEnabled() or not FLT.ShowAlert then return end
  if (GetTime and GetTime() or 0) < snoozeUntil then return end
  if not (UnitExists and UnitExists(unit)) or (UnitIsDead and UnitIsDead(unit)) then return end
  local npcID = npcIDFromGUID(UnitGUID and UnitGUID(unit))
  if not npcID then return end
  if not teacherIndex then buildTeacherIndex() end
  local entries = teacherIndex[npcID]
  if not entries then return end
  local now = GetTime and GetTime() or 0
  if alerted[npcID] and now - alerted[npcID] < ALERT_REPEAT then return end
  -- You can only tame beasts up to your own level.
  local ul, pl = UnitLevel and UnitLevel(unit), UnitLevel and UnitLevel("player")
  if ul and pl and ul > 0 and ul > pl then return end
  local fams = myPetFamilies()
  if not next(fams) then return end
  local best
  for _, e in ipairs(entries) do
    local known = FLT:GetKnownPetRank(e.ability.name)
    if (e.rank.rank or 1) > known and not FLT:IsPetAlertIgnored(e.ability.name) then
      local fits = abilityFits(e.ability, fams)
      if #fits > 0 and (not best or e.rank.rank > best.e.rank.rank) then best = { e = e, known = known, fits = fits } end
    end
  end
  if not best then return end
  alerted[npcID] = now
  local e = best.e
  local guid = UnitGUID and UnitGUID(unit)
  local beastName = (UnitName and UnitName(unit)) or e.beast.name
  FLT:ShowAlert({
    eyebrow = "PET ABILITY NEARBY",
    icon = "Interface\\Icons\\" .. (e.ability.icon or "INV_Misc_QuestionMark"),
    title = string.format("%s teaches %s %d", (UnitName and UnitName(unit)) or e.beast.name or "?", e.ability.name, e.rank.rank or 1),
    where = string.format("You know %s. For: %s",
      best.known > 0 and ("rank " .. best.known) or "no rank yet", table.concat(best.fits, ", ")),
    buttons = {
      { text = "Target", keepOpen = true, secureMacro = "/targetexact " .. (beastName or "") },
      { text = "Snooze 15 min", onClick = function()
        snoozeUntil = (GetTime and GetTime() or 0) + 900
        if FLT.Msg then FLT.Msg("Pet ability alerts paused for 15 minutes.") end
      end },
      { text = "Ignore " .. e.ability.name, onClick = function()
        FLT:SetPetAlertIgnored(e.ability.name, true)
        if FLT.Msg then FLT.Msg(e.ability.name .. " no longer triggers pet alerts. Re-enable it in Hunter Pets > Abilities.") end
      end },
    },
  })
end

do
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_LOGIN")
  ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
      local _, cls = UnitClass("player")
      if cls ~= "HUNTER" then self:UnregisterAllEvents(); return end
      for _, e in ipairs({"CRAFT_SHOW", "CRAFT_UPDATE", "UNIT_PET", "PET_BAR_UPDATE", "SPELLS_CHANGED", "PET_SPELL_POWER_UPDATE", "LEARNED_SPELL_IN_TAB", "PET_STABLE_SHOW", "PET_STABLE_UPDATE", "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT"}) do pcall(self.RegisterEvent, self, e) end
      scanPetSpellbook()
    elseif event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
      scanBeastTraining()
    elseif event == "PET_STABLE_SHOW" or event == "PET_STABLE_UPDATE" then
      scanStable()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
      checkTeacher(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
      checkTeacher("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
      checkTeacher("mouseover")
    else
      scanPetSpellbook()
      if petUI and petUI.refreshKnown then petUI.refreshKnown() end
    end
  end)
end

local function createPetsPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", 15, -76)
  panel:SetPoint("BOTTOMRIGHT", -35, 15)
  createPanelBanner(panel, "pets", -8, 8, -18)

  local modeButtons = {}
  local modes = { {key="families", label="Families"}, {key="abilities", label="Abilities"}, {key="rares", label="Rare Tames"} }
  local x = 8
  for _, m in ipairs(modes) do
    local b = makeButton(panel, m.label, 120, 26); b:SetPoint("TOPLEFT", x, -70); x = x + 126
    modeButtons[m.key] = b
  end
  local line = makeTexture(panel, "ARTWORK", 0.72, 0.50, 0.12, 0.42)
  line:SetPoint("TOPLEFT", 8, -104); line:SetPoint("TOPRIGHT", -10, -104); line:SetHeight(1)

  local body = CreateFrame("Frame", nil, panel)
  body:SetPoint("TOPLEFT", 8, -114); body:SetPoint("BOTTOMRIGHT", -8, 4)

  local function text(parentFrame, template, w)
    local f = parentFrame:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    if w then f:SetWidth(w); f:SetJustifyH("LEFT") end
    return f
  end

  -- A "where" line with a Map button for beasts that have coordinates.
  local function beastRow(parentFrame, b, y, width)
    local row = CreateFrame("Frame", nil, parentFrame); row:SetSize(width, 24); row:SetPoint("TOPLEFT", 0, y)
    local t = text(row, "GameFontHighlightSmall", width - 70); t:SetPoint("LEFT", 6, 0)
    t:SetText(string.format("%s  |cff9d9d9d(%s)|r  -  %s", b.name or "?", b.level or "?", b.zone or "?"))
    if b.mapID and b.x and b.y then
      local mb = makeButton(row, "Map", 54, 20); mb:SetPoint("RIGHT", -4, 0)
      mb:SetScript("OnClick", function() FLT:ShowOnMap({mapID=b.mapID, x=b.x, y=b.y, zone=b.zone, name=b.name}) end)
    end
    return row
  end

  -- Master/detail view: a list on the left, a scrollable detail pane right.
  local function masterDetail(listItems, buildDetail)
    local view = CreateFrame("Frame", nil, body); view:SetAllPoints()
    local left = CreateFrame("Frame", nil, view); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(390)
    local lbg = makeTexture(left, "BACKGROUND", 0.10, 0.072, 0.030, 0.88); lbg:SetAllPoints()
    local lsf = CreateFrame("ScrollFrame", nil, left, "UIPanelScrollFrameTemplate"); lsf:SetPoint("TOPLEFT", 10, -10); lsf:SetPoint("BOTTOMRIGHT", -3, 8)
    local lchild = CreateFrame("Frame", nil, lsf); lchild:SetSize(LIST_W, 1); lsf:SetScrollChild(lchild)

    local right = CreateFrame("Frame", nil, view); right:SetPoint("TOPLEFT", 405, 0); right:SetPoint("BOTTOMRIGHT")
    local rbg = makeTexture(right, "BACKGROUND", 0.034, 0.044, 0.056, 0.93); rbg:SetAllPoints()

    local rows, panes = {}, {}
    local function select(i)
      for j, r in ipairs(rows) do
        if j == i then r.bg:SetColorTexture(0.24, 0.17, 0.055, 0.98); r.label:SetTextColor(unpack(GOLD))
        else r.bg:SetColorTexture(0.115, 0.082, 0.038, 0.78); r.label:SetTextColor(0.92, 0.90, 0.84) end
      end
      for _, p in pairs(panes) do p:Hide() end
      if not panes[i] then
        local sf = CreateFrame("ScrollFrame", nil, right, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 12, -10); sf:SetPoint("BOTTOMRIGHT", -26, 8)
        local child = CreateFrame("Frame", nil, sf); child:SetSize(520, 1); sf:SetScrollChild(child)
        local h = buildDetail(child, listItems[i])
        if h then child:SetHeight(math.max(1, h)) end
        sf.child = child
        panes[i] = sf
      end
      panes[i]:Show()
      if panes[i].child.refresh then panes[i].child.refresh() end
      view.selected = i
    end
    local y = -2
    for i, item in ipairs(listItems) do
      local b = CreateFrame("Button", nil, lchild); b:SetSize(ROW_W, 34); b:SetPoint("TOPLEFT", 0, y); y = y - 36
      local bg = makeTexture(b, "BACKGROUND", 0.115, 0.082, 0.038, 0.78); bg:SetAllPoints()
      local hi = makeTexture(b, "HIGHLIGHT", 0.55, 0.36, 0.10, 0.22); hi:SetAllPoints()
      local ic = b:CreateTexture(nil, "ARTWORK"); ic:SetSize(26, 26); ic:SetPoint("LEFT", 6, 0); ic:SetTexture(item.icon)
      local label = text(b, "GameFontHighlight", 200); label:SetPoint("LEFT", 40, 0); label:SetText(item.label)
      local sub = text(b, "GameFontDisableSmall", 110); sub:SetPoint("RIGHT", -8, 0); sub:SetJustifyH("RIGHT"); sub:SetText(item.sub or "")
      b:SetScript("OnClick", function() select(i) end)
      rows[i] = {bg=bg, label=label, sub=sub, button=b}
    end
    lchild:SetHeight(math.max(1, -y + 2))
    view.select = select
    view.rows, view.items = rows, listItems
    view.refreshCurrent = function() local p = view.selected and panes[view.selected]; if p and p.child.refresh then p.child.refresh() end end
    select(1)
    return view
  end

  local views, current = {}, nil
  local abilityIndex = {}

  local function heading(child, s, y)
    local h = text(child, "GameFontNormal"); h:SetPoint("TOPLEFT", 0, y); h:SetText(s); h:SetTextColor(unpack(GOLD))
    return y - 20
  end
  local function para(child, s, y, template, r, g, b)
    local p = text(child, template or "GameFontHighlightSmall", 510); p:SetPoint("TOPLEFT", 0, y); p:SetText(s)
    if r then p:SetTextColor(r, g, b) end
    return y - math.max(16, (p:GetStringHeight() or 14) + 4)
  end

  local showMode -- forward

  -- Families -----------------------------------------------------------------
  -- The hunter's active pet (family name as the client reports it).
  local FAMILY_ALIAS = { ["Owl"] = "Bird of Prey" }
  local function activePet()
    if not (UnitExists and UnitExists("pet") and UnitCreatureFamily) then return nil end
    local fam = UnitCreatureFamily("pet")
    if not fam then return nil end
    return FAMILY_ALIAS[fam] or fam, UnitName and UnitName("pet"), UnitLevel and UnitLevel("pet")
  end

  local function buildFamilies()
    local items = {}
    for _, f in ipairs(FLT.PET_FAMILIES or {}) do
      items[#items + 1] = { label=f.name, icon=icon(FAMILY_ICON, f.name), sub=table.concat(f.diet or {}, ", "), data=f }
    end
    local view = masterDetail(items, function(child, item)
      local f = item.data
      local y = 0
      -- Header: large family portrait with the name next to it.
      local ring = UI.CreateRingFrame(child, 64, "gold"); ring:SetPoint("TOPLEFT", 3, -3)
      local pic = ring.portrait; pic:SetTexCoord(0.07, 0.93, 0.07, 0.93); pic:SetTexture(icon(FAMILY_ICON, f.name))
      local t = text(child, "GameFontNormalLarge"); t:SetPoint("TOPLEFT", 80, -10); t:SetText(f.name); t:SetTextColor(unpack(GOLD))
      local petTag = text(child, "GameFontHighlight", 440); petTag:SetPoint("TOPLEFT", 80, -36); petTag:SetTextColor(0.35, 1, 0.45)
      y = y - 74
      child.refresh = function()
        local fam, pname, plevel = activePet()
        local parts = {}
        if fam == f.name then
          parts[#parts + 1] = "Your pet: " .. (pname or "?") .. (plevel and plevel > 0 and (", level " .. plevel) or "")
        end
        for _, sp in ipairs(FLT:GetStabledPets()) do
          if sp.family == f.name then
            parts[#parts + 1] = "|cff7fbfffIn stable: " .. (sp.name or "?") .. (sp.level and (", level " .. sp.level) or "") .. "|r"
          end
        end
        petTag:SetText(table.concat(parts, "   "))
      end
      child.refresh()
      y = para(child, "Diet: " .. table.concat(f.diet or {}, ", "), y, nil, 0.85, 0.85, 0.80)
      if f.modifiers then
        y = para(child, string.format("Modifiers: health x%s, armor x%s, damage x%s", f.modifiers.health or "?", f.modifiers.armor or "?", f.modifiers.damage or "?"), y, nil, 0.85, 0.85, 0.80)
      end
      if f.note and f.note ~= "" and not f.note:match("^Stat modifiers") then y = para(child, f.note, y) end
      y = y - 6
      y = heading(child, "Family abilities", y)
      for _, name in ipairs(f.abilities or {}) do
        local b = CreateFrame("Button", nil, child); b:SetSize(250, 22); b:SetPoint("TOPLEFT", 0, y); y = y - 24
        local ic = b:CreateTexture(nil, "ARTWORK"); ic:SetSize(18, 18); ic:SetPoint("LEFT", 2, 0); ic:SetTexture(icon(ABILITY_ICON, name))
        local l = text(b, "GameFontHighlightSmall", 220); l:SetPoint("LEFT", 26, 0); l:SetText(name)
        local hi = makeTexture(b, "HIGHLIGHT", 0.55, 0.36, 0.10, 0.22); hi:SetAllPoints()
        b:SetScript("OnClick", function() showMode("abilities", abilityIndex[name]) end)
      end
      if f.trainer and #f.trainer > 0 then
        y = para(child, "Pet Trainer: " .. table.concat(f.trainer, ", ") .. ".", y - 2, "GameFontDisableSmall")
      end
      y = y - 6
      y = heading(child, "Where to tame", y)
      if #(f.tames or {}) == 0 then
        y = para(child, "No tameable beasts confirmed in Forever yet.", y, "GameFontDisableSmall")
      end
      for _, b in ipairs(f.tames or {}) do beastRow(child, b, y, 510); y = y - 26 end
      return -y + 10
    end)
    view.markPet = function()
      local fam = activePet()
      local found
      for k, it in ipairs(view.items) do
        local r = view.rows[k]
        if r then
          local mine = fam and it.data.name == fam
          local stabled = 0
          for _, sp in ipairs(FLT:GetStabledPets()) do if sp.family == it.data.name then stabled = stabled + 1 end end
          if mine then found = k end
          if not r.petMark then
            r.petMark = makeTexture(r.button, "ARTWORK", 0.35, 1, 0.45, 0.95)
            r.petMark:SetPoint("TOPLEFT", 0, 0); r.petMark:SetPoint("BOTTOMLEFT", 0, 0); r.petMark:SetWidth(4)
          end
          if mine then
            r.petMark:SetColorTexture(0.35, 1, 0.45, 0.95); r.petMark:Show()
            r.sub:SetText("|cff59ff73Your pet|r" .. (stabled > 0 and "\n|cff7fbfffIn stable|r" or ""))
          elseif stabled > 0 then
            r.petMark:SetColorTexture(0.50, 0.75, 1, 0.95); r.petMark:Show()
            r.sub:SetText("|cff7fbfffIn stable" .. (stabled > 1 and (" (" .. stabled .. ")") or "") .. "|r")
          else
            r.petMark:Hide(); r.sub:SetText(it.sub or "")
          end
        end
      end
      view.refreshCurrent()
      return found
    end
    view.markPet()
    return view
  end

  -- Abilities ----------------------------------------------------------------
  local function buildAbilities()
    local items = {}
    -- Only abilities learned from tameable beasts; Pet Trainer skills
    -- (resistances, Great Stamina, ...) are listed on each family instead.
    for _, a in ipairs(FLT.PET_ABILITIES or {}) do
      if a.source ~= "trainer" then
      items[#items + 1] = { label=a.name, icon=icon(ABILITY_ICON, a.name), sub=(a.source == "trainer") and "Pet Trainer" or (#(a.ranks or {}) .. " ranks"), data=a }
      abilityIndex[a.name] = #items
      end
    end
    local function subText(a)
      if a.source == "trainer" then
        local k = FLT:GetKnownPetRank(a.name)
        return k > 0 and ("|cff59ff73Rank " .. k .. "|r  Pet Trainer") or "Pet Trainer"
      end
      local k = FLT:GetKnownPetRank(a.name)
      local mute = FLT:IsPetAlertIgnored(a.name) and "  |cff808080(no alert)|r" or ""
      if k > 0 then return string.format("|cff59ff73%d/%d learned|r", math.min(k, #(a.ranks or {})), #(a.ranks or {})) .. mute end
      return #(a.ranks or {}) .. " ranks" .. mute
    end
    for _, it in ipairs(items) do it.sub = subText(it.data) end

    local view = masterDetail(items, function(child, item)
      local a = item.data
      local blocks, open = {}, {}
      -- Header: large ability icon with the name next to it.
      local ring = UI.CreateActionFrame(child, 62); ring:SetPoint("TOPLEFT", 4, -4)
      local pic = ring.portrait; pic:SetTexCoord(0.07, 0.93, 0.07, 0.93); pic:SetTexture(icon(ABILITY_ICON, a.name))
      local t = text(child, "GameFontNormalLarge"); t:SetPoint("TOPLEFT", 80, -10); t:SetText(a.name); t:SetTextColor(unpack(GOLD))
      local headSub = text(child, "GameFontHighlightSmall", 440); headSub:SetPoint("TOPLEFT", 80, -36)
      headSub:SetText((a.families and #a.families > 0) and ("Families: " .. table.concat(a.families, ", ")) or ""); headSub:SetTextColor(0.85, 0.85, 0.80)
      local alertCB = CreateFrame("CheckButton", nil, child, "UICheckButtonTemplate")
      alertCB:SetSize(22, 22); alertCB:SetPoint("TOPRIGHT", -4, -4)
      local alertLbl = text(child, "GameFontHighlightSmall"); alertLbl:SetPoint("RIGHT", alertCB, "LEFT", -2, 0); alertLbl:SetText("Alert for this ability")
      alertCB:SetScript("OnClick", function(self) FLT:SetPetAlertIgnored(a.name, not self:GetChecked()) end)
      alertCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Pet ability alert", 1, 0.82, 0)
        GameTooltip:AddLine("Untick to never get a popup for beasts teaching this ability.", 1, 1, 1, true); GameTooltip:Show()
      end)
      alertCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
      local intro = {}
      local function addIntro(str, r, g, b)
        local p = text(child, "GameFontHighlightSmall", 510); p:SetText(str)
        if r then p:SetTextColor(r, g, b) end
        intro[#intro + 1] = p
      end
      if a.effect and a.effect ~= "" then addIntro(a.effect) end
      if a.source == "trainer" then
        addIntro("Learned from any Pet Trainer.", 0.65, 0.85, 1)
      end
      local noneKnown = a.source ~= "trainer" and #(a.ranks or {}) > 0
      for _, r in ipairs(a.ranks or {}) do if #(r.learnFrom or {}) > 0 then noneKnown = false end end
      if noneKnown then addIntro("New in WoW Forever: no beast that teaches this ability is known yet.", 0.65, 0.85, 1) end
      local scanHint = text(child, "GameFontDisableSmall", 510)
      scanHint:SetText("Green = rank you already know. Summon your pet (or open Beast Training) so OneForAll can read your known ranks.")

      -- One clickable row per rank; the teaching beasts fold out below it.
      for ri, r in ipairs(a.ranks or {}) do
        local hasBeasts = a.source ~= "trainer" and #(r.learnFrom or {}) > 0
        local hdr = CreateFrame("Button", nil, child); hdr:SetSize(510, 26)
        local bg = makeTexture(hdr, "BACKGROUND", 0.10, 0.075, 0.035, 0.85); bg:SetAllPoints()
        local hi = makeTexture(hdr, "HIGHLIGHT", 0.55, 0.36, 0.10, 0.22); hi:SetAllPoints()
        local tog = text(hdr, "GameFontNormal", 16); tog:SetPoint("LEFT", 6, 0); tog:SetText(hasBeasts and "+" or "")
        local label = text(hdr, "GameFontNormal", 300); label:SetPoint("LEFT", 24, 0)
        label:SetText(string.format("Rank %d  |cffbbbbbb- pet level %s, %s TP|r", r.rank, tostring(r.level or "?"), tostring(r.tp or "?")))
        local right = text(hdr, "GameFontHighlightSmall", 180); right:SetPoint("RIGHT", -8, 0); right:SetJustifyH("RIGHT")
        local body = CreateFrame("Frame", nil, child); body:SetSize(510, 1)
        local by = 0
        if r.desc and r.desc ~= "" and r.desc ~= a.effect then
          local d = text(body, "GameFontHighlightSmall", 490); d:SetPoint("TOPLEFT", 14, by - 2); d:SetText(r.desc); d:SetTextColor(0.80, 0.80, 0.74)
          by = by - math.max(16, (d:GetStringHeight() or 14) + 6)
        end
        local beastsTop = by
        body.beasts = {}
        if hasBeasts then
          for _, b in ipairs(r.learnFrom) do
            local row = beastRow(body, b, by, 496); row:SetPoint("TOPLEFT", 14, by); by = by - 26
            body.beasts[#body.beasts + 1] = row
          end
        elseif a.source ~= "trainer" and not noneKnown then
          local d = text(body, "GameFontDisableSmall", 490); d:SetPoint("TOPLEFT", 14, by - 2); d:SetText("No beast known that teaches this rank."); by = by - 18
        end
        body.fullH, body.descH = -by + 4, -beastsTop
        hdr:SetScript("OnClick", function()
          if not hasBeasts then return end
          open[ri] = not open[ri]
          child.relayout()
        end)
        blocks[ri] = { hdr = hdr, bg = bg, tog = tog, label = label, right = right, body = body, rank = r, hasBeasts = hasBeasts }
      end

      child.relayout = function()
        local y = -74
        for _, p in ipairs(intro) do
          p:ClearAllPoints(); p:SetPoint("TOPLEFT", 0, y)
          y = y - math.max(16, (p:GetStringHeight() or 14) + 4)
        end
        scanHint:ClearAllPoints(); scanHint:SetPoint("TOPLEFT", 0, y - 2)
        y = y - math.max(16, (scanHint:GetStringHeight() or 14) + 8)
        for ri, bl in ipairs(blocks) do
          bl.hdr:ClearAllPoints(); bl.hdr:SetPoint("TOPLEFT", 0, y); y = y - 28
          local expanded = open[ri] or not bl.hasBeasts
          bl.tog:SetText(bl.hasBeasts and (open[ri] and "-" or "+") or "")
          for _, row in ipairs(bl.body.beasts) do if expanded then row:Show() else row:Hide() end end
          -- Collapsed rows keep the rank's effect line and hide the beast list.
          local h = expanded and bl.body.fullH or (bl.body.descH > 0 and bl.body.descH + 4 or 0)
          bl.body:ClearAllPoints()
          if h > 4 then
            bl.body:SetPoint("TOPLEFT", 0, y); bl.body:SetHeight(h); bl.body:Show(); y = y - h
          else
            bl.body:Hide()
          end
        end
        child:SetHeight(math.max(1, -y + 10))
      end

      child.refresh = function()
        alertCB:SetChecked(not FLT:IsPetAlertIgnored(a.name))
        local known = FLT:GetKnownPetRank(a.name)
        local scanned = type(ForeverCompanionCharDB) == "table" and ForeverCompanionCharDB.petAbilitiesScanned
        if scanned then scanHint:Hide() else scanHint:Show() end
        for _, bl in ipairs(blocks) do
          local learned = known >= (bl.rank.rank or 1)
          if learned then
            bl.bg:SetColorTexture(0.035, 0.20, 0.065, 0.92); bl.label:SetTextColor(0.35, 1, 0.45)
            bl.right:SetText("|cff59ff73Learned|r")
          else
            bl.bg:SetColorTexture(0.10, 0.075, 0.035, 0.85); bl.label:SetTextColor(unpack(GOLD))
            bl.right:SetText(bl.hasBeasts and ("|cff9d9d9d" .. #bl.rank.learnFrom .. " beasts|r") or "")
          end
        end
        child.relayout()
      end
      child.refresh()
      return nil
    end)

    view.refreshKnown = function()
      for i, it in ipairs(view.items) do
        it.sub = subText(it.data)
        if view.rows[i] and view.rows[i].sub then view.rows[i].sub:SetText(it.sub) end
      end
      view.refreshCurrent()
    end
    return view
  end

  -- Rare tames ---------------------------------------------------------------
  local function buildRares()
    local view = CreateFrame("Frame", nil, body); view:SetAllPoints()
    local bg = makeTexture(view, "BACKGROUND", 0.034, 0.044, 0.056, 0.93); bg:SetAllPoints()
    local sf = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 10, -8); sf:SetPoint("BOTTOMRIGHT", -28, 8)
    local child = CreateFrame("Frame", nil, sf); child:SetSize(920, 1); sf:SetScrollChild(child)
    local y = -2
    for i, r in ipairs(FLT.PET_RARES or {}) do
      local row = CreateFrame("Frame", nil, child); row:SetSize(920, 44); row:SetPoint("TOPLEFT", 0, y); y = y - 46
      local rb = makeTexture(row, "BACKGROUND", 0.10, 0.075, 0.035, (i % 2 == 0) and 0.90 or 0.75); rb:SetAllPoints()
      local ic = row:CreateTexture(nil, "ARTWORK"); ic:SetSize(28, 28); ic:SetPoint("LEFT", 8, 0); ic:SetTexture(icon(FAMILY_ICON, r.family))
      local n = text(row, "GameFontNormal", 300); n:SetPoint("TOPLEFT", 44, -6)
      n:SetText(string.format("%s  |cffbbbbbb%s, level %s%s|r", r.name or "?", r.family or "?", r.level or "?", r.speed and (", speed " .. r.speed) or ""))
      local w = text(row, "GameFontHighlightSmall", 560); w:SetPoint("TOPLEFT", 44, -25); w:SetText(r.why or "")
      local z = text(row, "GameFontHighlightSmall", 180); z:SetPoint("RIGHT", -76, 0); z:SetJustifyH("RIGHT"); z:SetText(r.zone or "")
      if r.mapID and r.x and r.y then
        local mb = makeButton(row, "Map", 58, 22); mb:SetPoint("RIGHT", -10, 0)
        mb:SetScript("OnClick", function() FLT:ShowOnMap({mapID=r.mapID, x=r.x, y=r.y, zone=r.zone, name=r.name}) end)
      end
    end
    child:SetHeight(math.max(1, -y + 4))
    return view
  end

  local builders = { families=buildFamilies, abilities=buildAbilities, rares=buildRares }
  showMode = function(key, selectIndex)
    -- Abilities must exist before a family links to one.
    if key == "families" and not views.abilities then views.abilities = buildAbilities(); views.abilities:Hide() end
    for k, v in pairs(views) do if k ~= key then v:Hide() end end
    views[key] = views[key] or builders[key]()
    views[key]:Show()
    if selectIndex and views[key].select then views[key].select(selectIndex) end
    for k, b in pairs(modeButtons) do if k == key then b:LockHighlight() else b:UnlockHighlight() end end
    current = key
  end
  for k, b in pairs(modeButtons) do b:SetScript("OnClick", function() showMode(k) end) end

  petUI = { refreshKnown = function()
    if views.abilities and views.abilities.refreshKnown then views.abilities.refreshKnown() end
    if views.families and views.families.markPet then views.families.markPet() end
  end }
  panel:SetScript("OnShow", function()
    if not current then
      indexIcons(); showMode("families")
      -- Start on the family of the active pet.
      local idx = views.families and views.families.markPet and views.families.markPet()
      if idx then views.families.select(idx) end
    end
    scanPetSpellbook()
    petUI.refreshKnown()
  end)
  panel:Hide()
  return panel
end

UI.RegisterPanel({ key="pets", label="Hunter Pets", order=7, tabWidth=122, classes={"HUNTER"}, create=createPetsPanel })
