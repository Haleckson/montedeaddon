local ADDON, FLT = ...
local UI = FLT.UI
local makeTexture = UI.makeTexture
local createPanelBanner = UI.createPanelBanner
local DISPLAY_NAME = UI.DISPLAY_NAME

local function createGeneralPanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", 15, -76)
  panel:SetPoint("BOTTOMRIGHT", -35, 15)

  createPanelBanner(panel, "general", -8, 8, -18)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -74)
  title:SetText("About "..DISPLAY_NAME)
  title:SetTextColor(1, 0.82, 0.20)

  local version = "?"
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    version = C_AddOns.GetAddOnMetadata(ADDON, "Version") or version
  elseif GetAddOnMetadata then
    version = GetAddOnMetadata(ADDON, "Version") or version
  end
  local v = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  v:SetPoint("TOPRIGHT", -16, -16)
  v:SetText("Version "..version.."  |  WoW Forever beta")
  v:SetTextColor(0.65, 0.85, 1)

  local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", 14, -112)
  intro:SetWidth(930)
  intro:SetJustifyH("LEFT")
  intro:SetText("OneForAll is an all-in-one reference and tracker for systems introduced or changed in WoW Forever. It is designed to keep the most useful beta information in one place without requiring external data addons.")
  intro:SetTextColor(0.90, 0.88, 0.82)

  local warning = CreateFrame("Frame", nil, panel)
  warning:SetPoint("TOPLEFT", 14, -156); warning:SetPoint("TOPRIGHT", -14, -156); warning:SetHeight(76)
  local wbg = makeTexture(warning, "BACKGROUND", 0.20, 0.11, 0.03, 0.84); wbg:SetAllPoints()
  local wline = makeTexture(warning, "ARTWORK", 0.95, 0.58, 0.12, 0.65); wline:SetPoint("LEFT",0,0); wline:SetWidth(3); wline:SetPoint("TOP",0,0); wline:SetPoint("BOTTOM",0,0)
  local wt = warning:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  wt:SetPoint("TOPLEFT", 16, -10); wt:SetText("Beta notice"); wt:SetTextColor(1,0.72,0.16)
  local wb = warning:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  wb:SetPoint("TOPLEFT", 16, -31); wb:SetWidth(885); wb:SetJustifyH("LEFT")
  wb:SetText("This is a temporary beta-focused version of the addon. WoW Forever is still in active beta, so quests, rewards, item stats, locations, profession costs and dungeon loot can change at any time. Data should be treated as a practical guide, not as a permanent final database.")
  wb:SetTextColor(0.92,0.86,0.72)

  local features = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  features:SetPoint("TOPLEFT", 14, -246); features:SetText("Modules"); features:SetTextColor(1,0.82,0.20)

  local modules = {
    {"Dungeons", key="dungeons", "Bosses, boss-specific loot, dungeon quests and quest rewards for all Forever dungeons up to level 38, grouped by level."},
    {"Library Books", key="books", "Tracks all known library books, bag/bank ownership, turn-ins, map locations and nearby coordinate alerts."},
    {"Mage Scrolls", key="mage", "Tracks encrypted Mage Comprehension scrolls, required skill tiers and explains how deciphering turns them into decoded Mage scrolls."},
    {"Professions", key="professions", "Merchant's Favor, camping profession objects/buffs, embedded profession recipes and crafted-result tooltips."},
    {"Talent Trees", key="talents", "In-addon class talent planner with live client icons/tooltips, point allocation, prerequisites and reset."},
    {"Hunter Pets", key="pets", "Pet families, pet abilities with all ranks and where to learn them, and notable rare tames with map locations."},
  }
  local y=-282
  for _,m in ipairs(modules) do
    local box=CreateFrame("Frame",nil,panel); box:SetPoint("TOPLEFT",14,y); box:SetPoint("TOPRIGHT",-14,y); box:SetHeight(38); y=y-41
    local bg=makeTexture(box,"BACKGROUND",0.055,0.052,0.047,0.88); bg:SetAllPoints()
    local h=box:CreateFontString(nil,"OVERLAY","GameFontNormal"); h:SetPoint("LEFT",14,0); h:SetText(m[1]); h:SetTextColor(1,0.82,0.20)
    local d=box:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); d:SetPoint("LEFT",160,0); d:SetWidth(735); d:SetJustifyH("LEFT"); d:SetText(m[2]); d:SetTextColor(0.82,0.80,0.74)
  end
  local hint=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  hint:SetPoint("TOPLEFT",14,y-2); hint:SetText("Choose which tabs are shown in the settings (gear icon, top left).")

  local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  footer:SetPoint("BOTTOMLEFT", 14, 8)
  footer:SetWidth(920); footer:SetJustifyH("LEFT")
  footer:SetText("If you find changed beta data, an incorrect reward or a missing item, update OneForAll to the newest build before relying on the entry.")
  footer:SetTextColor(0.62,0.62,0.62)

  panel:Hide()
  return panel
end


UI.RegisterPanel({ key="general", label="General", order=1, tabWidth=118, create=createGeneralPanel })
