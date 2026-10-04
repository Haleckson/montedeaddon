local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton = UI.makeTexture, UI.makeButton

-- Main window: title bar, tab bar and the registered panels (see Widgets.lua).
local frame
local panels = {}      -- key -> panel frame
local tabButtons = {}  -- key -> tab button
local activeTab = "general"

local function setPanelTab(tab)
  activeTab = tab or "general"
  for key, panel in pairs(panels) do
    if key == activeTab then panel:Show() else panel:Hide() end
  end
  for key, b in pairs(tabButtons) do
    if key == activeTab then b:LockHighlight() else b:UnlockHighlight() end
  end
end

-- Window scaling: the layout is built for 1040x650 and scaled as a whole
-- (SetScale), so every tab keeps its proportions. Scale and position are
-- saved account-wide in ForeverCompanionDB.window.
local BASE_W, BASE_H = 1040, 650
local MIN_SCALE, MAX_SCALE = 0.6, 1.4
-- The height can additionally be stretched (bottom-edge grip) so lists show
-- more rows; stored in ForeverCompanionDB.window.height.

local applyHeight -- defined below; used by the scale grip as well

local function windowDB()
  if type(ForeverCompanionDB) ~= "table" then return {} end
  ForeverCompanionDB.window = ForeverCompanionDB.window or {}
  return ForeverCompanionDB.window
end

local function clampScale(s)
  s = tonumber(s) or 1
  if s < MIN_SCALE then s = MIN_SCALE elseif s > MAX_SCALE then s = MAX_SCALE end
  return math.floor(s * 100 + 0.5) / 100
end

local function savePosition()
  local left, top = frame:GetLeft(), frame:GetTop()
  if not left or not top then return end
  local db = windowDB()
  db.left, db.top = left, top
end

-- Keeps the top-left corner in place on screen while the scale changes.
local function applyScale(newScale)
  newScale = clampScale(newScale)
  local oldScale = frame:GetScale() or 1
  local left, top = frame:GetLeft(), frame:GetTop()
  frame:SetScale(newScale)
  if left and top then
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / newScale, top * oldScale / newScale)
    savePosition()
  end
  windowDB().scale = newScale
  return newScale
end

local function createResizeGrip()
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", -4, 4)
  grip:SetFrameLevel(frame:GetFrameLevel() + 20)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

  local dragging
  grip:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    dragging = true
    self:SetScript("OnUpdate", function()
      if not dragging then return end
      local cx = GetCursorPosition()                       -- screen pixels
      local parentScale = UIParent:GetEffectiveScale()
      local left = frame:GetLeft() * frame:GetEffectiveScale() -- screen pixels
      local width = cx - left
      if width > 0 then
        local s = clampScale(width / (BASE_W * parentScale))
        if math.abs(s - (frame:GetScale() or 1)) >= 0.01 then applyScale(s) end
      end
    end)
  end)
  local function stop(self)
    dragging = false
    self:SetScript("OnUpdate", nil)
    savePosition()
  end
  grip:SetScript("OnMouseUp", function(self) stop(self); applyHeight(frame:GetHeight()) end)
  grip:SetScript("OnHide", stop)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Resize window", 1, 0.82, 0)
    GameTooltip:AddLine("Drag to scale the whole window. /ofa scale resets it.", 1, 1, 1, true)
    GameTooltip:AddLine(string.format("Current size: %d%%", math.floor((frame:GetScale() or 1) * 100 + 0.5)), 0.72, 0.72, 0.72)
    GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Largest height that still fits on screen at the current scale.
local function maxHeight()
  local screenH = UIParent:GetHeight() * UIParent:GetEffectiveScale()
  return math.max(BASE_H, math.floor(screenH / frame:GetEffectiveScale()) - 20)
end

local function clampHeight(h)
  h = tonumber(h) or BASE_H
  if h < BASE_H then h = BASE_H end
  if frame then local m = maxHeight(); if h > m then h = m end end
  return math.floor(h + 0.5)
end

applyHeight = function(h)
  h = clampHeight(h)
  frame:SetHeight(h)
  windowDB().height = (h > BASE_H) and h or nil
  return h
end

local function createHeightGrip()
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(140, 10)
  grip:SetPoint("BOTTOM", 0, 2)
  grip:SetFrameLevel(frame:GetFrameLevel() + 20)
  local bar = grip:CreateTexture(nil, "ARTWORK")
  bar:SetSize(60, 3); bar:SetPoint("CENTER")
  bar:SetColorTexture(0.72, 0.50, 0.12, 0.55)
  local hi = grip:CreateTexture(nil, "HIGHLIGHT")
  hi:SetSize(80, 4); hi:SetPoint("CENTER")
  hi:SetColorTexture(1, 0.82, 0.20, 0.85)

  local dragging
  grip:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    dragging = true
    self:SetScript("OnUpdate", function()
      if not dragging then return end
      local _, cy = GetCursorPosition()                      -- screen pixels
      local eff = frame:GetEffectiveScale()
      local top = frame:GetTop() * eff                        -- screen pixels
      local h = (top - cy) / eff
      if math.abs(h - frame:GetHeight()) >= 1 then applyHeight(h) end
    end)
  end)
  local function stop(self)
    dragging = false
    self:SetScript("OnUpdate", nil)
  end
  grip:SetScript("OnMouseUp", stop)
  grip:SetScript("OnHide", stop)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Window height", 1, 0.82, 0)
    GameTooltip:AddLine("Drag up or down to make the window taller and show more rows. /ofa scale resets it.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Tab visibility is stored per character (ForeverCompanionCharDB.tabs).
-- Without a saved choice a tab is shown, unless its panel spec lists the
-- classes it is meant for (spec.classes, e.g. Mage Scrolls -> MAGE).
local function playerClass()
  if not UnitClass then return nil end
  local _, token = UnitClass("player")
  return token
end

function UI.IsTabVisible(key)
  if key == "general" or key == "settings" then return true end
  local saved = type(ForeverCompanionCharDB) == "table" and ForeverCompanionCharDB.tabs and ForeverCompanionCharDB.tabs[key]
  if saved ~= nil then return saved and true or false end
  for _, spec in ipairs(UI.panels) do
    if spec.key == key and spec.classes then
      local cls = playerClass()
      for _, c in ipairs(spec.classes) do if c == cls then return true end end
      return false
    end
  end
  return true
end

function UI.SetTabVisible(key, visible)
  if key == "general" or key == "settings" or type(ForeverCompanionCharDB) ~= "table" then return end
  ForeverCompanionCharDB.tabs = ForeverCompanionCharDB.tabs or {}
  ForeverCompanionCharDB.tabs[key] = visible and true or false
  UI.LayoutTabs()
end

function UI.ResetTabs()
  if type(ForeverCompanionCharDB) == "table" then ForeverCompanionCharDB.tabs = nil end
  UI.LayoutTabs()
end

function UI.LayoutTabs()
  if not frame then return end
  local x = 18
  for _, spec in ipairs(UI.panels) do
    local b = tabButtons[spec.key]
    if b then
      b:ClearAllPoints()
      if UI.IsTabVisible(spec.key) then
        b:SetPoint("TOPLEFT", x, -35); b:Show()
        x = x + (spec.tabWidth or 130) + 6
      else
        b:Hide()
      end
    end
  end
  if not UI.IsTabVisible(activeTab) and panels[activeTab] then setPanelTab("general") end
end

local function createUI()
  frame = CreateFrame("Frame", "OneForAllFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(BASE_W, BASE_H)
  frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePosition() end)

  local db = windowDB()
  frame:SetScale(clampScale(db.scale or 1))
  if db.left and db.top then
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.left, db.top)
  else
    frame:SetPoint("CENTER")
  end
  createResizeGrip()
  createHeightGrip()
  applyHeight(db.height or BASE_H)
  frame.TitleText:SetText(UI.DISPLAY_NAME .. "  |cffb8b0a0- made by Smoergi|r")

  if frame.TitleBg then frame.TitleBg:SetVertexColor(0.70, 0.48, 0.14, 0.95) end
  if frame.Inset and frame.Inset.Bg then frame.Inset.Bg:SetVertexColor(0.11, 0.085, 0.055, 0.98) end

  -- Close with Escape.
  if UISpecialFrames then
    local found = false
    for _, name in ipairs(UISpecialFrames) do
      if name == frame:GetName() then found = true; break end
    end
    if not found then table.insert(UISpecialFrames, frame:GetName()) end
  end

  -- Tabs sit directly below the title bar, in the order given by each
  -- panel's "order" value. Hidden tabs (General tab settings) are skipped.
  for _, spec in ipairs(UI.panels) do
    local key = spec.key
    local b = makeButton(frame, spec.icon and "" or spec.label, spec.tabWidth or 130, 27)
    if spec.icon then
      local ic = b:CreateTexture(nil, "OVERLAY")
      ic:SetSize(19, 19); ic:SetPoint("CENTER"); ic:SetTexture(spec.icon)
      b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(spec.label); GameTooltip:Show()
      end)
      b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    b:SetScript("OnClick", function() setPanelTab(key) end)
    tabButtons[key] = b
  end
  UI.LayoutTabs()

  local tabLine = makeTexture(frame, "ARTWORK", 0.72, 0.50, 0.12, 0.45)
  tabLine:SetPoint("TOPLEFT", 12, -66)
  tabLine:SetPoint("TOPRIGHT", -12, -66)
  tabLine:SetHeight(1)

  for _, spec in ipairs(UI.panels) do
    local panel = spec.create(frame)
    if panel then panels[spec.key] = panel end
  end

  setPanelTab("general")
  frame:SetScript("OnShow", function() FLT:Refresh() end)
  frame:Hide()
end

function FLT:UIRefresh()
  -- Bag/bank events fire often; there is nothing to update while the window
  -- is closed. The frame's OnShow handler refreshes it when it is opened.
  if not frame or not frame:IsShown() then return end
  for _, panel in pairs(panels) do
    if panel.Refresh then panel:Refresh() end
  end
end

-- /ofa scale [value]: without a value resets to 100 %; accepts 0.6-1.4 or 60-140.
function UI.ResetWindow() FLT:SetWindowScale(nil) end

function FLT:SetWindowScale(value)
  local s = tonumber(value) or 1
  if s > 5 then s = s / 100 end
  if not frame then createUI() end
  local applied = applyScale(s)
  if not value then
    applyHeight(BASE_H)
    frame:ClearAllPoints(); frame:SetPoint("CENTER"); savePosition()
  else
    applyHeight(frame:GetHeight()) -- keep it on screen at the new scale
  end
  return applied
end

function FLT:ToggleUI()
  if not frame then createUI() end
  if frame:IsShown() then frame:Hide(); return end
  -- Inside a dungeon: open straight on that dungeon's bosses & loot.
  local d = FLT.FindCurrentDungeon and FLT.FindCurrentDungeon()
  if d and panels.dungeons and UI.IsTabVisible("dungeons") and UI.OpenDungeon then
    setPanelTab("dungeons")
    UI.OpenDungeon(d)
  end
  frame:Show()
end
