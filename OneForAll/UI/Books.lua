local _, FLT = ...
local UI = FLT.UI
local makeTexture, makeButton, addDivider = UI.makeTexture, UI.makeButton, UI.addDivider
local createPanelBanner = UI.createPanelBanner
local LAYOUT = UI.LAYOUT

-- Re-positions the book sections; assigned in createBooksPanel and used by
-- the collapse buttons of the section headers.
local relayout

local STATE = {
  done={text="Turned in", color={0.25,1.00,0.35}},
  manual={text="Manual", color={0.78,0.58,1.00}},
  bag={text="Bag", color={1.00,0.84,0.20}},
  bank={text="Bank", color={0.25,0.72,1.00}},
  questflag={text="Quest flagged", color={1.00,0.55,0.15}},
  missing={text="Missing", color={0.62,0.62,0.62}},
}
local TERRITORY = {
  Alliance={text="Alliance", short="A", color={0.30,0.62,1.00}},
  Horde={text="Horde", short="H", color={1.00,0.28,0.23}},
  Contested={text="Contested", short="C", color={1.00,0.74,0.18}},
}


local function showBookTooltip(row, book)
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine(book.name, 1, 0.82, 0)
  GameTooltip:AddLine((book.zone or "?") .. (book.subzone and (" - " .. book.subzone) or ""), 0.84, 0.84, 0.84)

  local territory = FLT:GetTerritory(book.zone)
  local t = TERRITORY[territory] or TERRITORY.Contested
  GameTooltip:AddLine("Territory: " .. t.text, unpack(t.color))

  if book.x then GameTooltip:AddLine(string.format("Coordinates: %.1f, %.1f", book.x, book.y), 0.95, 0.88, 0.40) end
  GameTooltip:AddLine("Object: " .. (book.container or "Unknown"), 0.65, 0.85, 1)
  if book.note then GameTooltip:AddLine(book.note, 1, 0.82, 0, true) end

  if book.status == "unknown" then GameTooltip:AddLine("Location status: unconfirmed", 1, 0.35, 0.2)
  elseif book.status == "not-in-forever" then GameTooltip:AddLine("Location status: currently unavailable", 1, 0.35, 0.2)
  elseif book.status == "reported" then GameTooltip:AddLine("Location status: player report", 1, 0.75, 0.2)
  elseif book.status == "confirmed" then GameTooltip:AddLine("Location status: confirmed in Forever beta", 0.2, 1, 0.2)
  elseif book.status == "wowhead" then GameTooltip:AddLine("Location status: database location", 0.65, 0.85, 1) end

  GameTooltip:AddLine(" ")
  local apiDone = FLT:IsQuestDone(book.questId)
  GameTooltip:AddLine(string.format("Quest ID: %d   Item ID: %d", book.questId or 0, book.itemId or 0), 0.65, 0.65, 0.65)
  GameTooltip:AddLine("Server completion flag: " .. (apiDone and "true" or "false"), apiDone and 1 or 0.65, apiDone and 0.55 or 0.65, apiDone and 0.15 or 0.65)
  if apiDone and not ForeverCompanionCharDB.confirmedDone[book.itemId] then
    GameTooltip:AddLine("Unverified: the server reports this quest completed, but this addon did not observe the turn-in.", 1, 0.55, 0.15, true)
  end
  GameTooltip:AddLine("Right-click: toggle a manual ownership/completion note", 0.7, 0.7, 0.7, true)
  GameTooltip:Show()
end

local function createSectionHeader(parent, text, setId)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(LAYOUT.BOOK_CONTENT_WIDTH, 38)

  local bg = makeTexture(holder, "BACKGROUND", 0.16, 0.11, 0.045, 0.95)
  bg:SetAllPoints()
  local top = makeTexture(holder, "ARTWORK", 0.72, 0.50, 0.12, 0.65)
  top:SetPoint("TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", 0, 0); top:SetHeight(1)
  local bottom = makeTexture(holder, "ARTWORK", 0.72, 0.50, 0.12, 0.40)
  bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(1)

  -- Use a normal WoW button with ASCII +/- instead of a font glyph.
  -- This avoids the empty square seen on clients whose font lacks the old symbol.
  local toggle = makeButton(holder, "-", 22, 22)
  toggle:SetPoint("LEFT", 12, 0)
  holder.toggle = toggle

  local title = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", 44, 0)
  title:SetText(text)
  title:SetTextColor(1.00, 0.82, 0.20)

  toggle:SetScript("OnClick", function()
    ForeverCompanionDB.collapsedSets = ForeverCompanionDB.collapsedSets or {}
    ForeverCompanionDB.collapsedSets[setId] = not ForeverCompanionDB.collapsedSets[setId] or nil
    if relayout then relayout() end
  end)
  -- The whole header bar toggles too, not just the +/- button.
  holder:EnableMouse(true)
  local hhi = makeTexture(holder, "ARTWORK", 0.55, 0.36, 0.10, 0.18)
  hhi:SetAllPoints(); hhi:Hide()
  holder:SetScript("OnEnter", function() hhi:Show() end)
  holder:SetScript("OnLeave", function() hhi:Hide() end)
  holder:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then toggle:Click() end end)

  return holder
end

local function createColumnHeader(parent, y)
  local h = CreateFrame("Frame", nil, parent)
  h:SetPoint("TOPLEFT", 0, y)
  h:SetSize(LAYOUT.BOOK_CONTENT_WIDTH, 28)
  local bg = makeTexture(h, "BACKGROUND", 0.05, 0.05, 0.05, 0.96)
  bg:SetAllPoints()
  local bot = makeTexture(h, "ARTWORK", 0.72, 0.50, 0.12, 0.45)
  bot:SetPoint("BOTTOMLEFT", 0, 0); bot:SetPoint("BOTTOMRIGHT", 0, 0); bot:SetHeight(1)

  local cols = {
    {x=14, text="Status"},
    {x=138, text="Book Title"},
    {x=560, text="Territory"},
    {x=686, text="Zone / Coordinates"},
    {x=868, text="Actions"},
  }
  for _, c in ipairs(cols) do
    local fs = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", c.x, 0)
    fs:SetText(c.text)
    fs:SetTextColor(0.90, 0.78, 0.53)
  end
  addDivider(h, 126); addDivider(h, 548); addDivider(h, 674); addDivider(h, 832)
  return h
end



local bookRewardsPopup
local function showBookRewardsPopup(frame)
  if not frame then return end
  if not bookRewardsPopup then
    local p = CreateFrame("Frame", "OneForAllLibraryInfoPopup", frame)
    bookRewardsPopup = p
    p:SetSize(640, 500)
    p:SetPoint("CENTER", frame, "CENTER", 0, 8)
    p:SetFrameStrata("DIALOG")
    p:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)
    p:EnableMouse(true)

    local shadow = makeTexture(p, "BACKGROUND", 0, 0, 0, 0.88)
    shadow:SetPoint("TOPLEFT", -5, 5); shadow:SetPoint("BOTTOMRIGHT", 5, -5)
    local bg = makeTexture(p, "BACKGROUND", 0.025, 0.022, 0.018, 0.99); bg:SetAllPoints()
    local inner = makeTexture(p, "BORDER", 0.11, 0.075, 0.025, 0.72)
    inner:SetPoint("TOPLEFT", 3, -3); inner:SetPoint("BOTTOMRIGHT", -3, 3)
    for _,spec in ipairs({
      {"TOPLEFT","TOPRIGHT",nil,2}, {"BOTTOMLEFT","BOTTOMRIGHT",nil,2},
      {"TOPLEFT","BOTTOMLEFT",2,nil}, {"TOPRIGHT","BOTTOMRIGHT",2,nil},
    }) do
      local e=makeTexture(p,"ARTWORK",0.75,0.52,0.14,0.90)
      e:SetPoint(spec[1],p,spec[1]); e:SetPoint(spec[2],p,spec[2])
      if spec[3] then e:SetWidth(spec[3]) end; if spec[4] then e:SetHeight(spec[4]) end
    end

    local iconBG = CreateFrame("Frame", nil, p); iconBG:SetSize(48,48); iconBG:SetPoint("TOPLEFT",18,-16)
    local ibg=makeTexture(iconBG,"BACKGROUND",0.13,0.09,0.03,1); ibg:SetAllPoints()
    local icon=iconBG:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",4,-4); icon:SetPoint("BOTTOMRIGHT",-4,4); icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local ib=iconBG:CreateTexture(nil,"OVERLAY"); ib:SetAllPoints(); ib:SetTexture("Interface\\Buttons\\UI-Quickslot2"); ib:SetVertexColor(0.9,0.65,0.2,1)

    local title=p:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",78,-18); title:SetText("Library Books"); title:SetTextColor(1,0.82,0.20)
    local sub=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sub:SetPoint("TOPLEFT",78,-43); sub:SetText("Turn-ins, rewards and librarian locations"); sub:SetTextColor(0.78,0.76,0.70)
    local line=makeTexture(p,"ARTWORK",0.72,0.50,0.12,0.52); line:SetPoint("TOPLEFT",18,-78); line:SetPoint("TOPRIGHT",-18,-78); line:SetHeight(1)

    local body=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); body:SetPoint("TOPLEFT",24,-90); body:SetPoint("TOPRIGHT",-24,-90); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetSpacing(3)
    body:SetText("|cffffd35aTurn in:|r  Alliance: Garion Wendell, Stormwind Mage Quarter (37.6, 80.8)   |   Horde: Owen Thadd, Undercity Magic Quarter (73.4, 33.0)\nEvery different book is its own turn-in. Each reward tier is a separate quest at the librarian - pick one item per tier. Mages can also unlock Research Access / Study.")
    body:SetTextColor(0.86,0.84,0.78)

    local H=FLT.UI.DungeonHelpers
    local y=-140
    for _,tier in ipairs(FLT.BOOK_REWARD_TIERS or {}) do
      local head=p:CreateFontString(nil,"OVERLAY","GameFontNormal"); head:SetPoint("TOPLEFT",24,y)
      head:SetText(string.format("%s  |cffbbbbbb- %s%s|r", tier.books, tier.quest, (tier.req and tier.req>1) and (", requires level "..tier.req) or ""))
      head:SetTextColor(1,0.82,0.20)
      y=y-22
      local x=24
      for _,it in ipairs(tier.items) do
        local rec={id=it[1],name=it[2],quality=it[3]}
        local b=CreateFrame("Button",nil,p); b:SetSize(190,40); b:SetPoint("TOPLEFT",x,y); x=x+196
        local bg=makeTexture(b,"BACKGROUND",0.07,0.06,0.045,0.95); bg:SetAllPoints()
        local hi=makeTexture(b,"HIGHLIGHT",0.55,0.36,0.10,0.22); hi:SetAllPoints()
        local ic=b:CreateTexture(nil,"ARTWORK"); ic:SetSize(30,30); ic:SetPoint("LEFT",5,0)
        ic:SetTexture((H and H.dungeonItemIcon and H.dungeonItemIcon(rec)) or "Interface\\Icons\\INV_Misc_QuestionMark")
        local n=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); n:SetPoint("TOPLEFT",40,-5); n:SetWidth(146); n:SetJustifyH("LEFT"); n:SetText(it[2]); n:SetTextColor(0.25,0.55,1)
        local d=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); d:SetPoint("TOPLEFT",40,-21); d:SetWidth(146); d:SetJustifyH("LEFT"); d:SetWordWrap(false); d:SetText(it[4] or "")
        b:SetScript("OnEnter",function(self)
          if not (H and H.tryShowItemTooltip and H.tryShowItemTooltip(self,rec)) then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(it[2],0.25,0.55,1); GameTooltip:AddLine(it[4] or "",1,1,1); GameTooltip:Show()
          end
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        b:SetScript("OnClick",function(_,button) if H and H.handleDungeonItemClick then H.handleDungeonItemClick(rec,button) end end)
      end
      y=y-52
    end
    local note=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); note:SetPoint("TOPLEFT",24,y-2); note:SetPoint("RIGHT",-24,0); note:SetJustifyH("LEFT")
    note:SetText("The book count for the third tier is not confirmed yet. WoW Forever is still in beta, so rewards may change. Ctrl-click an item to try it on.")

    local okay=makeButton(p,"Okay",120,28); okay:SetPoint("BOTTOM",0,18); okay:SetScript("OnClick",function() p:Hide() end)
    local close=makeButton(p,"X",28,28); close:SetPoint("TOPRIGHT",-10,-10); close:SetScript("OnClick",function() p:Hide() end)
    p:SetScript("OnHide",function() GameTooltip:Hide() end)
    p:Hide()
  end
  bookRewardsPopup:Show()
end


local function createBooksPanel(frame)
  -- Container covering the whole window, so all offsets below are identical
  -- to the pre-4.2 layout (they used to be anchored to the main window).
  local panel = CreateFrame("Frame", nil, frame)
  panel:SetAllPoints(frame)
  local content, rows, progress, sections, nearbyCheck

  createPanelBanner(panel, "books", -84, 23, -53)

  -- Library-specific information panel.
  local info = CreateFrame("Frame", nil, panel)
  info:SetPoint("TOPLEFT", 12, -144)
  info:SetPoint("TOPRIGHT", -12, -144)
  info:SetHeight(106)
  local infoBg = makeTexture(info, "BACKGROUND", 0.035, 0.030, 0.022, 0.96)
  infoBg:SetAllPoints()
  local infoLine = makeTexture(info, "ARTWORK", 0.72, 0.50, 0.12, 0.55)
  infoLine:SetPoint("BOTTOMLEFT", 0, 0); infoLine:SetPoint("BOTTOMRIGHT", 0, 0); infoLine:SetHeight(1)

  local sub = info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", 16, -14)
  sub:SetText("Status from observed turn-ins + bags + last scanned bank.")
  sub:SetTextColor(0.86, 0.84, 0.78)

  local help = info:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  help:SetPoint("TOPLEFT", 16, -34)
  help:SetText("Orange Quest flagged = server says completed, but not verified by this addon. Use /oneforall debug for IDs.")
  help:SetTextColor(0.66, 0.63, 0.57)

  progress = info:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  progress:SetPoint("TOPRIGHT", -18, -16)
  progress:SetJustifyH("RIGHT")
  progress:SetTextColor(1.00, 0.82, 0.20)

  local reward = makeButton(info, "What can I do with the books?", 250, 28)
  reward:SetPoint("BOTTOMLEFT", 14, 12)
  reward:SetScript("OnClick", function()
    showBookRewardsPopup(frame)
  end)

  nearbyCheck = CreateFrame("CheckButton", nil, info, "UICheckButtonTemplate")
  nearbyCheck:SetSize(24, 24)
  nearbyCheck:SetPoint("LEFT", reward, "RIGHT", 24, 0)
  nearbyCheck:SetChecked(FLT:IsNearbyAlertsEnabled())
  nearbyCheck:SetScript("OnClick", function(self)
    FLT:SetNearbyAlertsEnabled(self:GetChecked())
  end)
  nearbyCheck:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Nearby book alerts", 1, 0.82, 0)
    GameTooltip:AddLine("Shows a popup when your map coordinates are close to a missing library book.", 1, 1, 1, true)
    GameTooltip:AddLine("The alert uses saved coordinates, not direct object detection.", 0.72, 0.72, 0.72, true)
    GameTooltip:Show()
  end)
  nearbyCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local nearbyLabel = info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nearbyLabel:SetPoint("LEFT", nearbyCheck, "RIGHT", 4, 0)
  nearbyLabel:SetText("Nearby book alerts")
  nearbyLabel:SetTextColor(0.88, 0.84, 0.73)

  local bookScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  bookScroll:SetPoint("TOPLEFT", 15, -256)
  bookScroll:SetPoint("BOTTOMRIGHT", -35, 15)

  content = CreateFrame("Frame", nil, bookScroll)
  content:SetSize(LAYOUT.BOOK_CONTENT_WIDTH, 1)
  bookScroll:SetScrollChild(content)

  rows = {}
  sections = {}
  ForeverCompanionDB.collapsedSets = ForeverCompanionDB.collapsedSets or {}

  local lastSet
  local rowIndex = 0
  local currentSection
  for _, book in ipairs(FLT.BOOKS) do
    if lastSet ~= book.set then
      currentSection = {
        id = book.set,
        header = createSectionHeader(content, FLT.SETS[book.set] or book.set, book.set),
        columns = createColumnHeader(content, 0),
        rows = {},
      }
      sections[#sections + 1] = currentSection
      lastSet = book.set
    end

    rowIndex = rowIndex + 1
    local row = CreateFrame("Button", nil, content)
    row:SetSize(LAYOUT.BOOK_CONTENT_WIDTH, 32)
    row.book = book

    local bg = makeTexture(row, "BACKGROUND", 0.055, 0.052, 0.047, (rowIndex % 2 == 0) and 0.94 or 0.78)
    bg:SetAllPoints()
    local hover = makeTexture(row, "HIGHLIGHT", 0.42, 0.30, 0.10, 0.22)
    hover:SetAllPoints()

    local statusDot = row:CreateTexture(nil, "ARTWORK")
    statusDot:SetSize(11, 11)
    statusDot:SetPoint("LEFT", 14, 0)
    statusDot:SetColorTexture(0.6, 0.6, 0.6, 1)
    row.statusDot = statusDot

    local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("LEFT", 34, 0)
    status:SetWidth(88)
    status:SetJustifyH("LEFT")
    row.statusText = status

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", 138, 0)
    name:SetWidth(400)
    name:SetJustifyH("LEFT")
    name:SetText(book.name)

    local territory = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    territory:SetPoint("LEFT", 560, 0)
    territory:SetWidth(110)
    territory:SetJustifyH("LEFT")
    row.territoryText = territory

    local loc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    loc:SetPoint("LEFT", 686, 0)
    loc:SetWidth(140)
    loc:SetJustifyH("LEFT")
    loc:SetText(book.x and string.format("%s %.1f, %.1f", book.zone, book.x, book.y) or (book.zone .. " ?"))

    local map = makeButton(row, "Map", 72, 23)
    map:SetPoint("CENTER", row, "LEFT", 895, 0)
    map:SetScript("OnClick", function() FLT:ShowOnMap(book) end)
    if not book.x then map:Disable() end

    addDivider(row, 126); addDivider(row, 548); addDivider(row, 674); addDivider(row, 832)
    local bottom = makeTexture(row, "ARTWORK", 0.55, 0.42, 0.18, 0.16)
    bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(1)

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(_, button)
      if button == "RightButton" then
        ForeverCompanionCharDB.manualDone[book.itemId] = not ForeverCompanionCharDB.manualDone[book.itemId] or nil
        FLT:Refresh()
      end
    end)
    row:SetScript("OnEnter", function() showBookTooltip(row, book) end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[#rows + 1] = row
    currentSection.rows[#currentSection.rows + 1] = row
  end

  relayout = function()
    local y = -2
    for i, section in ipairs(sections) do
      if i > 1 then y = y - 10 end
      section.header:ClearAllPoints()
      section.header:SetPoint("TOPLEFT", 0, y)
      section.header:Show()
      y = y - 40

      local collapsed = ForeverCompanionDB.collapsedSets and ForeverCompanionDB.collapsedSets[section.id]
      section.header.toggle:SetText(collapsed and "+" or "-")
      section.header.toggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(collapsed and "Expand set" or "Collapse set")
        GameTooltip:Show()
      end)
      section.header.toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

      if collapsed then
        section.columns:Hide()
        for _, row in ipairs(section.rows) do row:Hide() end
      else
        section.columns:ClearAllPoints()
        section.columns:SetPoint("TOPLEFT", 0, y)
        section.columns:Show()
        y = y - 29
        for _, row in ipairs(section.rows) do
          row:ClearAllPoints()
          row:SetPoint("TOPLEFT", 0, y)
          row:Show()
          y = y - 33
        end
      end
    end
    content:SetHeight(math.max(1, -y + 12))
  end


  function panel:Refresh()
    if nearbyCheck then nearbyCheck:SetChecked(FLT:IsNearbyAlertsEnabled()) end
    local done, owned = FLT:GetCounts()
    progress:SetText(string.format("Confirmed turn-ins: %d/%d   |   Owned/confirmed: %d/%d", done, #FLT.BOOKS, owned, #FLT.BOOKS))

    for _, row in ipairs(rows) do
      local st = FLT:GetBookState(row.book)
      local s = STATE[st] or STATE.missing
      row.statusText:SetText(s.text)
      row.statusText:SetTextColor(unpack(s.color))
      row.statusDot:SetColorTexture(s.color[1], s.color[2], s.color[3], 1)

      local territory = FLT:GetTerritory(row.book.zone)
      local t = TERRITORY[territory] or TERRITORY.Contested
      row.territoryText:SetText(t.text)
      row.territoryText:SetTextColor(unpack(t.color))
    end
  end

  relayout()
  panel:Hide()
  return panel
end

UI.RegisterPanel({ key="books", label="Library Books", order=3, tabWidth=140, create=createBooksPanel })
