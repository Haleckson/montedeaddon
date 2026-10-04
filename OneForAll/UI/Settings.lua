local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton = UI.makeTexture, UI.makeButton

-- Settings tab (gear icon, leftmost). Collects all options of the addon.

local function db()
  if type(ForeverCompanionDB) ~= "table" then return {} end
  return ForeverCompanionDB
end

local function createSettingsPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", 15, -76)
  panel:SetPoint("BOTTOMRIGHT", -35, 15)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -10); title:SetText("Settings"); title:SetTextColor(1, 0.82, 0.20)

  local refreshers = {}

  -- A titled box; returns the box and a function that adds checkboxes in a grid.
  local function section(label, x, y, w, h)
    local box = CreateFrame("Frame", nil, panel)
    box:SetPoint("TOPLEFT", x, y); box:SetSize(w, h)
    local bg = makeTexture(box, "BACKGROUND", 0.055, 0.052, 0.047, 0.88); bg:SetAllPoints()
    local top = makeTexture(box, "ARTWORK", 0.72, 0.50, 0.12, 0.55); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
    local t = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 12, -10); t:SetText(label); t:SetTextColor(1, 0.82, 0.20)
    local row = 0
    local function add(text, tooltip, get, set, col)
      local cb = CreateFrame("CheckButton", nil, box, "UICheckButtonTemplate")
      cb:SetSize(24, 24)
      local cx = 10 + (col or 0) * 220
      cb:SetPoint("TOPLEFT", cx, -32 - row * 26)
      local l = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      l:SetPoint("LEFT", cb, "RIGHT", 4, 0); l:SetText(text)
      cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
      if tooltip then
        cb:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(text, 1, 0.82, 0)
          GameTooltip:AddLine(tooltip, 1, 1, 1, true); GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
      end
      refreshers[#refreshers + 1] = function() cb:SetChecked(get()) end
      return cb
    end
    local function nextRow() row = row + 1 end
    return box, add, nextRow
  end

  -- Tabs ---------------------------------------------------------------------
  local _, addTab, nextTab = section("Shown tabs (this character)", 8, -40, 470, 220)
  local n = 0
  for _, spec in ipairs(UI.panels) do
    if spec.key ~= "general" and spec.key ~= "settings" then
      local key = spec.key
      addTab(spec.label, "Show or hide this tab for the current character.",
        function() return UI.IsTabVisible(key) end,
        function(v) UI.SetTabVisible(key, v) end, n % 2)
      n = n + 1
      if n % 2 == 0 then nextTab() end
    end
  end

  -- Dungeons -----------------------------------------------------------------
  local _, addDungeon, nextDungeon = section("Dungeon list: level brackets", 8, -270, 470, 150)
  local function browseCfg()
    local d = db()
    d.dungeonBrowse = d.dungeonBrowse or {}
    d.dungeonBrowse.hiddenBrackets = d.dungeonBrowse.hiddenBrackets or {}
    return d.dungeonBrowse
  end
  local used = {}
  for _, d in ipairs(FLT.DUNGEONS or {}) do
    for _, br in ipairs(UI.DUNGEON_BRACKETS or {}) do
      if (d.minLevel or 0) >= br.min and (d.minLevel or 0) <= br.max then used[br.id] = true end
    end
  end
  local m = 0
  for _, br in ipairs(UI.DUNGEON_BRACKETS or {}) do
    if used[br.id] then
      local id = br.id
      addDungeon("Show " .. br.label, "Hide a bracket you no longer need, e.g. once you have outleveled it.",
        function() return not browseCfg().hiddenBrackets[id] end,
        function(v) browseCfg().hiddenBrackets[id] = (not v) or nil; if UI.RefreshDungeonList then UI.RefreshDungeonList() end end, m % 2)
      m = m + 1
      if m % 2 == 0 then nextDungeon() end
    end
  end

  -- General -------------------------------------------------------------------
  local _, addMisc, nextMisc = section("General", 492, -40, 470, 72)
  addMisc("Welcome message on login", "Prints the short OneForAll greeting in the chat when you log in.",
    function() return db().showWelcome ~= false end,
    function(v) db().showWelcome = v end); nextMisc()

  -- Popups & alerts -------------------------------------------------------------
  local _, addAlert, nextAlert = section("Popups & alerts", 492, -122, 470, 138)
  addAlert("Nearby Library Book alerts", "Shows a popup when you are close to a missing library book.",
    function() return FLT.IsNearbyAlertsEnabled and FLT:IsNearbyAlertsEnabled() end,
    function(v) if FLT.SetNearbyAlertsEnabled then FLT:SetNearbyAlertsEnabled(v) end end); nextAlert()
  addAlert("Pet ability alerts (Hunter)", "Shows a popup when a beast nearby teaches a higher ability rank that your active or stabled pet's family can learn.",
    function() return FLT.IsPetTeachAlertsEnabled and FLT:IsPetTeachAlertsEnabled() end,
    function(v) if FLT.SetPetTeachAlertsEnabled then FLT:SetPetTeachAlertsEnabled(v) end end); nextAlert()
  local function shareCfg()
    local d = db(); d.questShare = d.questShare or {}
    return d.questShare
  end
  addAlert("Quest share popup in dungeons", "Opens automatically when a group member can still accept one of your dungeon quests.",
    function() return shareCfg().popup ~= false end,
    function(v) shareCfg().popup = v end); nextAlert()
  addAlert("Emote when sharing a quest", "Posts an emote such as \"shares the quest ... (OneForAll addon)\".",
    function() return shareCfg().emote ~= false end,
    function(v) shareCfg().emote = v end); nextAlert()

  -- Window --------------------------------------------------------------------
  local win = section("Window", 492, -270, 470, 150)
  local reset = makeButton(win, "Reset size & position", 190, 26)
  reset:SetPoint("TOPLEFT", 14, -36)
  reset:SetScript("OnClick", function() if UI.ResetWindow then UI.ResetWindow() end end)
  local wt = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  wt:SetPoint("TOPLEFT", 14, -72); wt:SetWidth(440); wt:SetJustifyH("LEFT")
  wt:SetText("Drag the grip in the bottom-right corner to scale the window (60-140 %), or the grip in the middle of the bottom edge to change its height.")

  local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  footer:SetPoint("BOTTOMLEFT", 14, 8)
  footer:SetText("Like OneForAll or have an idea? Leave a comment on CurseForge - feedback and suggestions are always welcome.")

  panel:SetScript("OnShow", function() for _, f in ipairs(refreshers) do f() end end)
  panel:Hide()
  return panel
end

UI.RegisterPanel({ key="settings", label="Settings", order=0, tabWidth=27, icon="Interface\\Icons\\INV_Misc_Gear_01", create=createSettingsPanel })
