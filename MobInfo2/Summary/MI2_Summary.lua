local _, MI2 = ...
MI2_SummaryFrameMixin = {}

-- Save both data providers to the per-character SavedVariable,
-- including frame visibility, active tab, sort state, and column visibility.
function MI2.SaveSummaryDB()
  local dp  = MI2_SummaryFrame.DataProvider
  local sdp = MI2_SummaryFrame.SourceDataProvider
  MI2_SummaryDB = {
    version       = 1,
    loot          = dp:SaveToDB(),
    source        = sdp:SaveToDB(),
    isShown       = MI2_SummaryFrame:IsShown(),
    activeTab     = MI2_SummaryFrame.Tabs:GetTab(),
    lootSort      = { key = dp.presetSort.key,  direction = dp.presetSort.direction },
    sourceSort    = { key = sdp.presetSort.key, direction = sdp.presetSort.direction },
    lootColumns   = CopyTable(dp:GetColumnHideStates()),
    sourceColumns = CopyTable(sdp:GetColumnHideStates()),
    lootFilter    = CopyTable(MI2_SummaryFrame.LootListing.FilterDropDown:GetQualityFilter()),
    isMinimized   = MI2_SummaryFrame.isMinimized == true,
    frameWidth    = MI2_SummaryFrame.isMinimized
                      and MI2_SummaryFrame.previousWidth
                      or  (MI2_SummaryFrame:GetSize()),
    frameHeight   = MI2_SummaryFrame.isMinimized
                      and MI2_SummaryFrame.previousHeight
                      or  select(2, MI2_SummaryFrame:GetSize()),
    framePosX     = MI2_SummaryFrame:GetLeft(),
    framePosY     = MI2_SummaryFrame:GetTop(),
  }
end

-- Restore both data providers from the per-character SavedVariable,
-- including column visibility and sort. Tab and visibility are restored
-- by the caller (MI2_Player_Login) after this returns.
function MI2.LoadSummaryDB()
  if not MI2_SummaryDB then return end
  if MI2_SummaryDB.version ~= 1 then MI2_SummaryDB = nil; return end
  local dp  = MI2_SummaryFrame.DataProvider
  local sdp = MI2_SummaryFrame.SourceDataProvider
  -- Apply column states before LoadFromDB so the first SetDirty uses them.
  if MI2_SummaryDB.lootColumns then
    local hs = dp:GetColumnHideStates()
    for k, v in pairs(MI2_SummaryDB.lootColumns) do hs[k] = v end
  end
  if MI2_SummaryDB.sourceColumns then
    local hs = sdp:GetColumnHideStates()
    for k, v in pairs(MI2_SummaryDB.sourceColumns) do hs[k] = v end
  end
  dp:LoadFromDB(MI2_SummaryDB.loot)
  sdp:LoadFromDB(MI2_SummaryDB.source)
  -- Restore sort arrow visuals.
  local ls = MI2_SummaryDB.lootSort
  if ls and ls.key then
    dp:SetPresetSort(ls.key, ls.direction)
    dp:Sort(ls.key, ls.direction)
    MI2_SummaryFrame.LootListing:RestoreSortVisual(ls.key, ls.direction)
  end
  local ss = MI2_SummaryDB.sourceSort
  if ss and ss.key then
    sdp:SetPresetSort(ss.key, ss.direction)
    sdp:Sort(ss.key, ss.direction)
    MI2_SummaryFrame.SourceListing:RestoreSortVisual(ss.key, ss.direction)
  end
  -- Restore loot quality filter state.
  if MI2_SummaryDB.lootFilter then
    local fd = MI2_SummaryFrame.LootListing.FilterDropDown
    for k, v in pairs(MI2_SummaryDB.lootFilter) do
      fd.qualityFilter[k] = v
    end
    dp:SetOnFilterCallback(function(entry) return fd.qualityFilter[entry.Quality] end)
    dp:SetDirty()
  end
end

-- Restore only the frame's layout state (min/max, size, tab, visibility) from
-- MI2_SummaryDB. Called regardless of AlwaysResetSummary so the frame geometry
-- survives a reset-on-login.
function MI2.RestoreLayoutFromDB()
  if not MI2_SummaryDB then return end
  if MI2_SummaryDB.version ~= 1 then return end
  -- Configure min/max state BEFORE Show() so OnShow sees the correct flag.
  if MI2_SummaryDB.isMinimized then
    MI2_SummaryFrame:ConfigureSize(true)
    MI2_SummaryFrame.previousWidth  = MI2_SummaryDB.frameWidth
    MI2_SummaryFrame.previousHeight = MI2_SummaryDB.frameHeight
    if MI2_SummaryFrame.MaximizeMinimizeFrame then
      MI2_SummaryFrame.MaximizeMinimizeFrame:Minimize(true)
    end
  else
    if MI2_SummaryDB.activeTab then
      MI2_SummaryFrame.Tabs:SetTab(MI2_SummaryDB.activeTab)
    end
  end
  if MI2_SummaryDB.framePosX and MI2_SummaryDB.framePosY then
    MI2_SummaryFrame:ClearAllPoints()
    MI2_SummaryFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
      MI2_SummaryDB.framePosX,
      MI2_SummaryDB.framePosY - UIParent:GetHeight())
  end
  if MI2_SummaryDB.isShown then
    MI2_SummaryFrame:Show()
    if not MI2_SummaryDB.isMinimized and MI2_SummaryDB.frameWidth then
      MI2_SummaryFrame:SetSize(MI2_SummaryDB.frameWidth, MI2_SummaryDB.frameHeight)
    end
  end
end

function MI2_SummaryFrameMixin:OnClose()
	self:Hide()
end

function MI2_SummaryFrameMixin:OnReset()
	self.DataProvider:Reset()
	self.SourceDataProvider:Reset()
end

function MI2_SummaryFrameMixin:OnLoad()
	self:ApplyBackdrop()

	self.Tabs:SetTabSystem(self.TabSystem);
	self.Title:SetText(MI2_TXT_Summary)

	self.lootTabID = self.Tabs:AddNamedTab("Loots", self.LootListing);
	self.mobTabID = self.Tabs:AddNamedTab("Mobs", self.SourceListing);

	self:SetResizable(true)

	if self.SettingsButton then
    	self.SettingsButton:SetOnCallback( function(...) self:OnSettings(...) end)
	end

	self.LootListing:Init(self.DataProvider)
	self.LootListing:SetOnUpdateCallback(function(...) self:Update(...) end)
	self.LootListing.FilterDropDown:SetOnCallback( function(qualityFilter)
		self.DataProvider:SetOnFilterCallback( function(entry) return qualityFilter[entry.Quality] end)
		self.DataProvider:SetDirty()
	end)

	self.SourceListing:Init(self.SourceDataProvider)
	-- No filtering support for Sources
	self.SourceListing.FilterDropDown:Hide()

	if self.MaximizeMinimizeFrame then
		local function OnMaximize(frame)
			frame:GetParent():ConfigureSize( false );
		end

		self.MaximizeMinimizeFrame:SetOnMaximizedCallback(OnMaximize);

		local function OnMinimize(frame)
			frame:GetParent():ConfigureSize( true );
		end

		self.MaximizeMinimizeFrame:SetOnMinimizedCallback(OnMinimize);
	end
	self.Tabs:SetTab(self.lootTabID)
	
	if not MI2.WOW_MODERN then
		if self.CloseButton then
			self.CloseButton:SetSize(28, 28)
			self.CloseButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", 4, 1 )
		end
		if self.MaximizeMinimizeFrame then
			self.MaximizeMinimizeFrame:SetSize(28,28)
			self.MaximizeMinimizeFrame:SetPoint("RIGHT", self.CloseButton, "LEFT", 11, 0 )
		end
	end
end

function MI2_SummaryFrameMixin:OnSettings( value, font)
	if value == 1 then self:OnReset() end
	if value == 2 then
		MobInfoConfig.SummaryFont = font:GetName()
		MI2.SummaryFont.Normal = font
		self:OnSizeChanged(self:GetSize())
		self:SetMinMax(true)
    end
	if value == 3 then
		MobInfoConfig.AlwaysResetSummary = 1 - (MobInfoConfig.AlwaysResetSummary or 0)
	end
end

function MI2_SummaryFrameMixin:OnHide()
	-- force Maximize when hiding, some issue when restoring a minimized frame after hiding
	-- and then maximzing it
	if self.MaximizeMinimizeFrame then
		self.MaximizeMinimizeFrame:Maximize(true);
	end
end

function MI2_SummaryFrameMixin:OnShow()
  if MobInfoConfig.SummaryFont then
    MI2.SummaryFont.Normal = _G[MobInfoConfig.SummaryFont]
  end

  self:OnSizeChanged(self:GetSize())
  self:SetMinMax(true)
end

function MI2_SummaryFrameMixin:OnMouseDown(button)
	if button == "LeftButton" then
		self:StartMoving()
	end
end

function MI2_SummaryFrameMixin:OnMouseUp(button)
	if button == "LeftButton" then
		self:StopMovingOrSizing()
	end
end

function MI2_SummaryFrameMixin:Update(entries)
	if entries then
		local earliestTime = 2147483640
		local totalAmount = 0
		local totalVendor = 0
		local totalQuantity = 0
		local totalMobs = 0

		for _, entry in pairs(entries) do
			earliestTime = math.min(earliestTime,entry.FirstTime)
			totalMobs = totalMobs + (entry.NumMobs or 0)
			totalAmount = totalAmount + entry.Amount
			totalVendor = totalVendor + entry.Vendor
			if entry.Quality>0 then
				totalQuantity = totalQuantity + entry.Quantity
			end
		end

		local elapsedFactor = 0.36/(GetTime()-earliestTime)
		self.TotalAmount:SetText(GetMoneyString(totalAmount).." ("..GetMoneyString(10000*floor(totalAmount*elapsedFactor)).. "/h)")
		self.TotalVendor:SetText(GetMoneyString(totalVendor).." ("..GetMoneyString(10000*floor(totalVendor*elapsedFactor)).. "/h)")
		self.TotalQuantity:SetText(totalQuantity)

		self.TotalMobs:SetText(self.DataProvider:GetNumMobs())
	end
end

function MI2_SummaryFrameMixin:OnSizeChanged(width,height)
  local fontHeight = MI2.SummaryFont:GetHeight()
  local adjustedHeight = fontHeight+10+math.floor(((height - 130 - 10 - fontHeight)/(fontHeight+1)))*(fontHeight+1)
  self.LootListing:Resize(width,math.max(10+(fontHeight+1)*6,adjustedHeight))
  self.SourceListing:Resize(width,math.max(10+(fontHeight+1)*6,adjustedHeight))
  self.Tabs:SetSize(width,math.max(10+(fontHeight+1)*6,adjustedHeight))
  if not self.isMinimized then
	self.previousWidth, self.previousHeight = self:GetSize()
  end
end

function MI2_SummaryFrameMixin:SetMinMax(resize)
  if not self.isMinimized then
	local minRowHeight = 25+MI2.SummaryFont:GetHeight()*5
    local minRowWidth = math.max(self.LootListing.minWidth or 0, self.SourceListing.minWidth or 0)+10
	if self.ResizeButton then
    	self.ResizeButton:Init(self, math.max(250,minRowWidth),minRowHeight+35);
	end

	local currentWidth, currentHeight = self:GetSize()
	if resize and minRowWidth> currentWidth then
	  self:SetSize(minRowWidth,currentHeight)
	end
  end
end

function MI2_SummaryFrameMixin:ConfigureSize(isMinimized)
	MobInfoConfig.isSummaryMinimized = isMinimized
	local lootButton = self.TabSystem:GetTabButton(self.lootTabID)
	local mobButton = self.TabSystem:GetTabButton(self.mobTabID)
	if isMinimized == true then
		self.LootListing:Hide()
		self.SourceListing:Hide()
		lootButton:Hide()
		mobButton:Hide()
		self.ResizeButton:Init(self, 250,103,250,103);
		self:SetSize(250,103);
		self.ResizeButton:Hide()
	else
		lootButton:Show()
		mobButton:Show()
		if lootButton.LeftActive:IsShown() then
			self.LootListing:Show()
		end

		if mobButton.LeftActive:IsShown() then
			self.SourceListing:Show()
		end

		local oldWidth, oldHeight = self.previousWidth, self.previousHeight
		local currentWidth, currentHeight = self:GetSize()
		self:SetSize(oldWidth or currentWidth, oldHeight or currentHeight);
	end

	self.isMinimized = isMinimized
end

function MI2_SummaryFrameMixin:OnEnter()
  if self.ResizeButton and not self.isMinimized then
    self.ResizeButton:Show()
  end
end

function MI2_SummaryFrameMixin:OnLeave()
  if self.ResizeButton and not self.ResizeButton:IsMouseOver() and not self.isMinimized then
    self.ResizeButton:Hide()
  end
end
