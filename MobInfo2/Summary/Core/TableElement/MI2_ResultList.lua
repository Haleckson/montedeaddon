local _, MI2 = ...
-- Used AuctionatorLootListingMixin as starting point for MobInfo2 specific needs. Credit goes
-- Auctionator addon authors for getting this started.
--
MI2_ResultListMixin = {}

function MI2_ResultListMixin:SetOnUpdateCallback(onUpdateCallback)
  self.onUpdate = onUpdateCallback
end

function MI2_ResultListMixin:Init(dataProvider)
  if self.isInitialized == true then
    self:InitializeTable()
    return
  end

  self.isInitialized = false
  self.dataProvider = dataProvider

  self.columnSpecification = self.dataProvider:GetTableLayout()

  local view = CreateScrollBoxListLinearView()
  local _, fontHeight = MI2.SummaryFont.Normal:GetFont()
  view:SetElementExtent(fontHeight + 1)

  view:SetElementInitializer(dataProvider:GetRowTemplate(), function(frame, index)
    frame:Populate(self.dataProvider:GetEntryAt(index), index)
  end)

  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollArea.ScrollBox, self.ScrollArea.ScrollBar, view)

  self.ScrollArea.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnDataRangeChanged, self.ApplyHiding, self)

  -- Create an instance of table builder - note that the ScrollFrame we reference
  -- mixes a TableBuilder implementation in
  self.tableBuilder = CreateTableBuilder()
  -- Set the frame that will be used for header columns for this tableBuilder
  self.tableBuilder:SetHeaderContainer(self.HeaderContainer)

  self:InitializeTable()
  self:InitializeDataProvider()
end

function MI2_ResultListMixin:InitializeDataProvider()
  self.dataProvider:SetOnUpdateCallback(function(...) self:UpdateTable(...) end)

  self.dataProvider:SetOnPreserveScrollCallback(function()
    self.savedScrollPosition = self.ScrollArea.ScrollBox:GetScrollPercentage()
  end)

  self.dataProvider:SetOnResetScrollCallback(function()
    self.savedScrollPosition = nil
  end)
end

function MI2_ResultListMixin:RestoreScrollPosition()
  if self.savedScrollPosition ~= nil then
    self:UpdateTable()
    self.ScrollArea.ScrollBox:SetScrollPercentage(self.savedScrollPosition)
  end
end

function MI2_ResultListMixin:OnShow()
  if not self.isInitialized then
    return
  end

  self:UpdateDimensionsForHiding()
  self:ApplyHiding()
  self:UpdateTable()
end

function MI2_ResultListMixin:SetupColumns()
  self.fontScale = MI2.SummaryFont:GetScale()
  for _, columnEntry in ipairs(self.columnSpecification) do
    local column = self.tableBuilder:AddColumn()
    column:ConstructHeader(
      "BUTTON",
      columnEntry.headerTemplate,
      columnEntry.headerText,
      function()
        self:CustomizeColumns()
      end,
      function(sortKey, sortDirection)
        self:ClearColumnSorts()

        self.dataProvider:SetPresetSort(sortKey, sortDirection)
        self.dataProvider:Sort(sortKey, sortDirection)
      end,
      function()
        self:ClearColumnSorts()

        self.dataProvider:ClearSort()
      end,
      unpack((columnEntry.headerParameters or {}))
    )
    column:SetCellPadding(5, 5)
    column:ConstructCells("FRAME", columnEntry.cellTemplate, unpack((columnEntry.cellParameters or {})))

    if columnEntry.width ~= nil then
      column:SetFixedConstraints(columnEntry.width * self.fontScale, 0)
    else
      column:SetFillConstraints(1.0, 0)
    end
  end
end

function MI2_ResultListMixin:InitializeTable()
  self.tableBuilder:Reset()
  self.tableBuilder:SetTableMargins(-3, 12)
  self.tableBuilder:SetDataProvider(function(index)
    return self.dataProvider:GetEntryAt(index)
  end)

  ScrollUtil.RegisterTableBuilder(self.ScrollArea.ScrollBox, self.tableBuilder, function(a) return a end)

  self:SetupColumns()

  self.isInitialized = true
  self:UpdateDimensionsForHiding()
  self:ApplyHiding()
end

function MI2_ResultListMixin:Resize(width, height)
  if not self.isInitialized then
    return
  end

  local _, fontHeight = MI2.SummaryFont.Normal:GetFont()
  self.HeaderContainer:SetHeight(fontHeight + 4)
  self.FilterDropDown.Icon:SetSize(fontHeight + 6, fontHeight + 6)
  self.ScrollArea.ScrollBox:GetView():SetElementExtent(fontHeight + 1)

  self.tableBuilder:Reset()
  self:SetHeight(height)
  self.ScrollArea.ScrollBox:OnSizeChanged(width, height)
  self:SetupColumns()
  self.tableBuilder:SetHeaderContainer(self.HeaderContainer)
  self:UpdateDimensionsForHiding()
  self:ApplyHiding()
  self:UpdateTable()
end

function MI2_ResultListMixin:UpdateTable(entries)
  if not self.isInitialized then
    return
  end

  local tmpDataProvider = CreateIndexRangeDataProvider(self.dataProvider:GetCount())

  local shouldPreserveScroll = self.savedScrollPosition ~= nil

  self.ScrollArea.ScrollBox:SetDataProvider(tmpDataProvider, shouldPreserveScroll)
  if self.onUpdate then
    self.onUpdate(entries)
  end
end

function MI2_ResultListMixin:ClearColumnSorts()
  for _, col in ipairs(self.tableBuilder:GetColumns()) do
    col.headerFrame.Arrow:Hide()
  end
end

-- Restore the sort arrow visual after a data reload (e.g. login persistence).
-- sortKey and sortDirection must match what was previously saved.
function MI2_ResultListMixin:RestoreSortVisual(sortKey, sortDirection)
  self:ClearColumnSorts()
  if sortKey == nil then return end
  for _, col in ipairs(self.tableBuilder:GetColumns()) do
    local hf = col.headerFrame
    if hf.sortKey == sortKey then
      hf.sortDirection = sortDirection
      if sortDirection == 0 then
        hf.Arrow:SetTexCoord(0, 1, 1, 0)
      else
        hf.Arrow:SetTexCoord(0, 1, 0, 1)
      end
      hf.Arrow:Show()
      return
    end
  end
end

function MI2_ResultListMixin:CustomizeColumns()
  if self.dataProvider:GetColumnHideStates() ~= nil then
    self.CustomizeDropDown:Callback(
      self.columnSpecification,
      self.dataProvider:GetColumnHideStates(),
      function()
        self:UpdateDimensionsForHiding(true)
        self:ApplyHiding()
      end)
  end
end

-- Hide cells and column header
local function SetColumnShown(column, isShown)
  column:GetHeaderFrame():SetShown(isShown)
  for _, cell in pairs(column.cells) do
    cell:SetShown(isShown)
  end
end

-- Prevent hidden columns displaying and overlapping visible ones
function MI2_ResultListMixin:ApplyHiding()

  local hidingDetails = self.dataProvider:GetColumnHideStates()
  if hidingDetails ~= nil then
    for index, column in ipairs(self.tableBuilder:GetColumns()) do
      SetColumnShown(column, not hidingDetails[self.columnSpecification[index].headerText])
    end
  end
end

function MI2_ResultListMixin:UpdateDimensionsForHiding(isInternal)
  self.minWidth = 0
  local hidingDetails = self.dataProvider:GetColumnHideStates()

  if hidingDetails == nil then
    self.tableBuilder:Arrange()
    return
  end

  local anyFlexibleWidths = false
  local visibleColumn

  for index, column in ipairs(self.tableBuilder:GetColumns()) do
    local columnEntry = self.columnSpecification[index]
    -- Import default value if hidden state not already set.
    if hidingDetails[columnEntry.headerText] == nil then
      hidingDetails[columnEntry.headerText] = columnEntry.defaultHide or false
    end

    if hidingDetails[columnEntry.headerText] then
      SetColumnShown(column, false)
      column:SetFixedConstraints(0.001, 0)
      column:SetCellPadding(0, 0)
    else
      SetColumnShown(column, true)

      if columnEntry.width ~= nil then
        local columnWidth = columnEntry.width * self.fontScale
        self.minWidth = self.minWidth + columnWidth
        column:SetFixedConstraints(columnWidth, 0)
      else
        self.minWidth = self.minWidth + 90
        anyFlexibleWidths = true
        column:SetFillConstraints(1.0, 0)
      end

      column:SetCellPadding(5, 5)

      if visibleColumn == nil then
        visibleColumn = column
      end
    end
  end

  -- Checking that at least one column will fill up empty space, if there isn't
  -- one, the first visible column is modified to do so.
  if not anyFlexibleWidths then
    visibleColumn:SetFillConstraints(1.0, 0)
  end
  self.tableBuilder:Arrange()

  self:GetParent():SetMinMax(isInternal)
end
