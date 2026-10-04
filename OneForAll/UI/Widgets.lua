local ADDON, FLT = ...

-- Shared UI building blocks and the panel registry used by every tab.
-- Each tab lives in its own file under UI/ and registers itself with
-- UI.RegisterPanel(); MainFrame.lua builds the window and tab bar from that.
local UI = {}
FLT.UI = UI

UI.DISPLAY_NAME = FLT.DISPLAY_NAME or "OneForAll"
UI.ASSET_ROOT = FLT.ASSET_ROOT or ("Interface\\AddOns\\" .. ADDON .. "\\Assets\\")
local ASSET_ROOT = UI.ASSET_ROOT

local LAYOUT = {
  BOOK_CONTENT_WIDTH = 958,
  DUNGEON_BROWSE_WIDTH = 950,
  DUNGEON_ROW_WIDTH = 930,
  QUEST_LIST_WIDTH = 350,
  QUEST_ROW_WIDTH = 338,
  QUEST_DETAIL_CHILD_WIDTH = 450,
}
UI.LAYOUT = LAYOUT

local function makeTexture(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(r, g, b, a)
  return t
end

local function makeButton(parent, text, w, h)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)

  local bg = makeTexture(b, "BACKGROUND", 0.075, 0.065, 0.050, 0.98)
  bg:SetAllPoints()
  b._bg = bg

  local inner = makeTexture(b, "BORDER", 0.30, 0.22, 0.10, 0.28)
  inner:SetPoint("TOPLEFT", 2, -2)
  inner:SetPoint("BOTTOMRIGHT", -2, 2)
  b._inner = inner

  local function edge(point1, point2, x1, y1, x2, y2, width, height)
    local t = makeTexture(b, "ARTWORK", 0.72, 0.50, 0.16, 0.72)
    t:SetPoint(point1, b, point1, x1, y1)
    t:SetPoint(point2, b, point2, x2, y2)
    if width then t:SetWidth(width) end
    if height then t:SetHeight(height) end
    return t
  end
  edge("TOPLEFT", "TOPRIGHT", 0, 0, 0, 0, nil, 1)
  edge("BOTTOMLEFT", "BOTTOMRIGHT", 0, 0, 0, 0, nil, 1)
  edge("TOPLEFT", "BOTTOMLEFT", 0, 0, 0, 0, 1, nil)
  edge("TOPRIGHT", "BOTTOMRIGHT", 0, 0, 0, 0, 1, nil)

  local highlight = makeTexture(b, "HIGHLIGHT", 0.78, 0.55, 0.18, 0.18)
  highlight:SetPoint("TOPLEFT", 1, -1)
  highlight:SetPoint("BOTTOMRIGHT", -1, 1)
  b:SetHighlightTexture(highlight)

  local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("CENTER", 0, 0)
  label:SetText(text)
  label:SetTextColor(0.96, 0.78, 0.34)
  b:SetFontString(label)
  b._label = label

  b:SetScript("OnMouseDown", function(self)
    if self:IsEnabled() then
      self._bg:SetColorTexture(0.11, 0.085, 0.050, 1.00)
      self._label:SetPoint("CENTER", 1, -1)
    end
  end)
  b:SetScript("OnMouseUp", function(self)
    self._bg:SetColorTexture(0.075, 0.065, 0.050, 0.98)
    self._label:ClearAllPoints()
    self._label:SetPoint("CENTER", 0, 0)
  end)

  return b
end

local function addDivider(parent, x)
  local line = makeTexture(parent, "ARTWORK", 0.55, 0.42, 0.18, 0.35)
  line:SetPoint("TOPLEFT", x, -2)
  line:SetPoint("BOTTOMLEFT", x, 2)
  line:SetWidth(1)
end


local TAB_BANNERS = {
  general={
    texture=ASSET_ROOT.."general_banner",
  },
  dungeons={
    texture=ASSET_ROOT.."dungeons_banner",
  },
  books={
    texture=ASSET_ROOT.."books_banner",
  },
  mage={
    texture=ASSET_ROOT.."mage_banner",
  },
  professions={
    texture=ASSET_ROOT.."professions_banner",
  },
  talents={
    texture=ASSET_ROOT.."talents_banner",
  },
  pets={
    texture=ASSET_ROOT.."pets_banner",
  },
}

local function createPanelBanner(parent, kind, topOffset, leftInset, rightInset)
  local cfg = TAB_BANNERS[kind] or TAB_BANNERS.general
  local banner = CreateFrame("Frame", nil, parent)
  banner:SetPoint("TOPLEFT", leftInset or 8, topOffset or -8)
  banner:SetPoint("TOPRIGHT", rightInset or -8, topOffset or -8)
  banner:SetHeight(56)

  local bg = makeTexture(banner, "BACKGROUND", 0.06, 0.045, 0.025, 0.98)
  bg:SetAllPoints()
  local top = makeTexture(banner, "ARTWORK", 0.72, 0.50, 0.12, 0.62)
  top:SetPoint("TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", 0, 0); top:SetHeight(1)
  local bottom = makeTexture(banner, "ARTWORK", 0.72, 0.50, 0.12, 0.45)
  bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(1)
  local left = makeTexture(banner, "ARTWORK", 0.72, 0.50, 0.12, 0.35)
  left:SetPoint("TOPLEFT", 0, 0); left:SetPoint("BOTTOMLEFT", 0, 0); left:SetWidth(1)
  local right = makeTexture(banner, "ARTWORK", 0.72, 0.50, 0.12, 0.35)
  right:SetPoint("TOPRIGHT", 0, 0); right:SetPoint("BOTTOMRIGHT", 0, 0); right:SetWidth(1)

  if cfg.texture then
    local art = banner:CreateTexture(nil, "ARTWORK")
    art:SetAllPoints()
    art:SetTexture(cfg.texture)
    art:SetTexCoord(0, 1, 0, 1)
    local shade = makeTexture(banner, "OVERLAY", 0.02, 0.02, 0.02, 0.28)
    shade:SetAllPoints()
  end

  return banner
end


UI.makeTexture = makeTexture
UI.makeButton = makeButton
UI.addDivider = addDivider
UI.createPanelBanner = createPanelBanner

-- Panel registry ------------------------------------------------------------
-- spec = { key=, label=, order=, tabWidth=, create=function(parent) return frame end }
-- A panel may define panel:Refresh(), which runs whenever the window refreshes.
UI.panels = {}
function UI.RegisterPanel(spec)
  UI.panels[#UI.panels + 1] = spec
  table.sort(UI.panels, function(a, b) return (a.order or 99) < (b.order or 99) end)
end
