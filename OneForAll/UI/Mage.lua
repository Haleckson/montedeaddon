local _, FLT = ...
local UI = FLT.UI
local makeTexture, addDivider = UI.makeTexture, UI.addDivider
local createPanelBanner = UI.createPanelBanner
local DISPLAY_NAME = UI.DISPLAY_NAME

local function createMagePanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", 15, -76)
  panel:SetPoint("BOTTOMRIGHT", -35, 15)

  createPanelBanner(panel, "mage", -8, 8, -18)

  local explain = CreateFrame("Frame", nil, panel)
  explain:SetPoint("TOPLEFT", 8, -70); explain:SetPoint("TOPRIGHT", -18, -70); explain:SetHeight(70)
  local ebg = makeTexture(explain, "BACKGROUND", 0.025, 0.035, 0.050, 0.94); ebg:SetAllPoints()
  local etop = makeTexture(explain, "ARTWORK", 0.72, 0.50, 0.12, 0.45); etop:SetPoint("TOPLEFT"); etop:SetPoint("TOPRIGHT"); etop:SetHeight(1)
  local ebottom = makeTexture(explain, "ARTWORK", 0.72, 0.50, 0.12, 0.30); ebottom:SetPoint("BOTTOMLEFT"); ebottom:SetPoint("BOTTOMRIGHT"); ebottom:SetHeight(1)
  local eicon = explain:CreateTexture(nil, "ARTWORK"); eicon:SetSize(34,34); eicon:SetPoint("LEFT",12,0); eicon:SetTexture("Interface\\Icons\\INV_Scroll_03")
  local etitle = explain:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  etitle:SetPoint("TOPLEFT", 58, -9); etitle:SetText("How Mage Scrolls work"); etitle:SetTextColor(1,0.82,0.20)
  local intro = explain:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  intro:SetPoint("TOPLEFT", 58, -29); intro:SetPoint("RIGHT", -12, 0); intro:SetJustifyH("LEFT")
  intro:SetText("Encrypted Mage-only world drops are deciphered with Comprehension and the required resource. The decoded result comes from the current tier/pool, so one encrypted scroll does not guarantee one fixed spell. Comprehension is a separate Mage skill, not your character level.")
  intro:SetTextColor(0.82, 0.84, 0.88)

  local head = CreateFrame("Frame", nil, panel)
  head:SetPoint("TOPLEFT", 0, -148); head:SetPoint("TOPRIGHT", -18, -148); head:SetHeight(28)
  local hbg = makeTexture(head, "BACKGROUND", 0.05,0.05,0.05,0.96); hbg:SetAllPoints()
  local cols={{x=14,t="Status"},{x=118,t="Scroll"},{x=540,t="Comprehension"},{x=680,t="Tier"},{x=790,t="Source"}}
  for _,c in ipairs(cols) do local f=head:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f:SetPoint("LEFT",c.x,0); f:SetText(c.t); f:SetTextColor(0.90,0.78,0.53) end
  addDivider(head,106); addDivider(head,526); addDivider(head,666); addDivider(head,776)

  local sf=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT",0,-177); sf:SetPoint("BOTTOMRIGHT",0,0)
  local child=CreateFrame("Frame",nil,sf); child:SetSize(940,1); sf:SetScrollChild(child)
  local mageRows={}
  local y=-2
  for i,sc in ipairs(FLT.MAGE_SCROLLS or {}) do
    local row=CreateFrame("Button",nil,child); row:SetSize(930,32); row:SetPoint("TOPLEFT",0,y); y=y-33; row.scroll=sc
    local bg=makeTexture(row,"BACKGROUND",0.055,0.052,0.047,(i%2==0) and 0.94 or 0.78); bg:SetAllPoints()
    local hover=makeTexture(row,"HIGHLIGHT",0.42,0.30,0.10,0.22); hover:SetAllPoints()
    local dot=row:CreateTexture(nil,"ARTWORK"); dot:SetSize(11,11); dot:SetPoint("LEFT",14,0); row.dot=dot
    local st=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); st:SetPoint("LEFT",34,0); st:SetWidth(68); st:SetJustifyH("LEFT"); row.state=st
    local nm=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nm:SetPoint("LEFT",118,0); nm:SetWidth(400); nm:SetJustifyH("LEFT"); nm:SetText(sc.name)
    local req=row:CreateFontString(nil,"OVERLAY","GameFontNormal"); req:SetPoint("LEFT",540,0); req:SetWidth(120); req:SetJustifyH("LEFT"); req:SetText(tostring(sc.comprehension or "?")); req:SetTextColor(0.65,0.85,1)
    local tier=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); tier:SetPoint("LEFT",680,0); tier:SetWidth(95); tier:SetJustifyH("LEFT"); tier:SetText(sc.tier or "-")
    local src=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); src:SetPoint("LEFT",790,0); src:SetWidth(135); src:SetJustifyH("LEFT"); src:SetText(sc.source or "World drop")
    addDivider(row,106); addDivider(row,526); addDivider(row,666); addDivider(row,776)
    row:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      local native=false
      if sc.itemId then
        if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID,sc.itemId) end
        if GameTooltip.SetHyperlink then native=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..tostring(sc.itemId)) end
      end
      if not native then
        GameTooltip:ClearLines(); GameTooltip:AddLine(sc.name,1,0.82,0)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(DISPLAY_NAME,1,0.82,0.20)
      GameTooltip:AddDoubleLine("Comprehension",tostring(sc.comprehension or "?"),0.65,0.85,1,1,1,1)
      GameTooltip:AddDoubleLine("Tier",sc.tier or "Unknown",0.80,0.80,0.80,1,0.82,0.20)
      GameTooltip:AddLine("What does it do?",1,0.82,0.20)
      GameTooltip:AddLine("This encrypted scroll does not teach one fixed spell directly. A Mage uses Comprehension/Decipher Scroll to decode it, consuming the required deciphering resource (currently a Comprehension Charm).",0.90,0.90,0.90,true)
      GameTooltip:AddLine("The result is a decoded Mage scroll from the current tier/pool. Current beta reports include utility and buff scrolls; the exact result is not fixed and the pool can change.",0.72,0.82,1.00,true)
      GameTooltip:AddLine("Comprehension is a separate Mage skill requirement, not a character-level requirement. Library/Research progression for Mages supplies Comprehension-related rewards and charms in the current beta.",0.72,0.72,0.72,true)
      if sc.itemId then GameTooltip:AddLine("Item ID: "..sc.itemId,0.55,0.55,0.55) end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    mageRows[#mageRows+1]=row
  end
  child:SetHeight(math.max(1,-y+8))

  function panel:Refresh()
    for _, row in ipairs(mageRows) do
      local st = FLT:GetItemStorageState(row.scroll.itemId)
      local stateText, color
      if st == "bag" then stateText, color = "Bag", {1.00,0.84,0.20}
      elseif st == "bank" then stateText, color = "Bank", {0.25,0.72,1.00}
      elseif st == "unknown" then stateText, color = "ID pending", {1.00,0.55,0.15}
      else stateText, color = "Missing", {0.62,0.62,0.62} end
      row.state:SetText(stateText); row.state:SetTextColor(unpack(color)); row.dot:SetColorTexture(color[1],color[2],color[3],1)
    end
  end

  panel:Hide(); return panel
end


UI.RegisterPanel({ key="mage", label="Mage Scrolls", order=4, tabWidth=132, classes={"MAGE"}, create=createMagePanel })
