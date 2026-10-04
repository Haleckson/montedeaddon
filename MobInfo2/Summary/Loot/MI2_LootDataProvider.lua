local _, MI2 = ...
local TABLE_LAYOUT = {
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "Name",MI2_TXT_LootName.text, MI2_TXT_LootName.tooltipText  },
    headerText = MI2_TXT_LootName.text,
    cellTemplate = "MI2_LootKeyCellTemplate",
    cellParameters = { "LEFT" },
    canHide = false
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "NumLoots", MI2_TXT_Quantity.text, MI2_TXT_Quantity.tooltipText },
    headerText = MI2_TXT_Quantity.text,
    cellTemplate = "MI2_StringCellTemplate",
    cellParameters = { "NumLoots", "RIGHT" },
    width = 40
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "Amount", MI2_TXT_Price.text, MI2_TXT_Price.tooltipText },
    headerText = MI2_TXT_Price.text,
    cellTemplate = "MI2_PriceCellTemplate",
    cellParameters = { "Amount" },
    width = 120
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "Vendor", MI2_TXT_Vendor.text, MI2_TXT_Vendor.tooltipText },
    headerText = MI2_TXT_Vendor.text,
    cellTemplate = "MI2_PriceCellTemplate",
    cellParameters = { "Vendor" },
    defaultHide = true,
    width = 120,
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "NumMobs", MI2_TXT_NumMobs.text, MI2_TXT_NumMobs.tooltipText },
    headerText = MI2_TXT_NumMobs.text,
    cellTemplate = "MI2_StringCellTemplate",
    cellParameters = { "NumMobs", "RIGHT" },
    defaultHide = true,
    width = 40,
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "NumNonMobs", MI2_TXT_NumMobs.text, MI2_TXT_NumMobs.tooltipText },
    headerText = MI2_TXT_NumNonMobs.text,
    cellTemplate = "MI2_StringCellTemplate",
    cellParameters = { "NumNonMobs", "RIGHT" },
    defaultHide = true,
    width = 40,
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "ID", MI2_TXT_ID.text, MI2_TXT_ID.tooltipText },
    headerText = MI2_TXT_ID.text,
    cellTemplate = "MI2_StringCellTemplate",
    cellParameters = { "ID" },
    defaultHide = true,
    width = 60
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "Time", MI2_TXT_Time.text, MI2_TXT_Time.tooltipText },
    headerText = MI2_TXT_Time.text,
    cellTemplate = "MI2_TimeCellTemplate",
    cellParameters = { "Time" },
    width = 60
  },
  {
    headerTemplate = "MI2_StringColumnHeaderTemplate",
    headerParameters = { "DropRate", MI2_TXT_DropRate.text, MI2_TXT_DropRate.tooltipText },
    headerText = MI2_TXT_DropRate.text,
    cellTemplate = "MI2_StringCellTemplate",
    cellParameters = { "DropRate", "RIGHT" },
    defaultHide = true,
    width = 50
  }
}

local COMPARATORS = {
  Amount = MI2.NumberComparator,
  Name = MI2.StringComparator,
  NumLoots = MI2.NumberComparator,
  Vendor = MI2.NumberComparator,
  Time = MI2.NumberComparator,
  NumMobs = MI2.NumberComparator,
  NumNonMobs = MI2.NumberComparator,
  ID = MI2.NumberComparator,
  DropRate = function(order, _) return MI2.NumberComparator(order, "DropRateNum") end
}

MI2_LootDataProviderMixin = CreateFromMixins(MI2_DataProviderMixin)

function MI2_LootDataProviderMixin:OnLoad()
  MI2_DataProviderMixin.OnLoad(self)
  self.mobs = {}
  self.uniqueMobs = {}
  self.uniqueNumMobs = 0
  self.hideStates = {}
  self:SetUpEvents()
end

function MI2_LootDataProviderMixin:Reset()
  MI2_DataProviderMixin.Reset(self)
  self.uniqueMobs = {}
  self.uniqueNumMobs = 0
end

function MI2_LootDataProviderMixin:SetOnFilterCallback(onfilterCallback)
  self.onFilter = onfilterCallback
end

function MI2_LootDataProviderMixin:Filter(entries)
  if self.onFilter then
    local filteredResults = {}
    for _, entry in pairs(entries) do
      if self.onFilter(entry) then
        table.insert(filteredResults, entry)
      end
    end
    return filteredResults
  end
  return entries
end

function MI2_LootDataProviderMixin:SetUpEvents()
  MI2.EventBus:RegisterSource(self, "LootDataProvider")

  MI2.EventBus:Register(self, { "NEW_LOOT" })
end

function MI2_LootDataProviderMixin:ReceiveEvent(eventName, eventData, ...)
  if eventName == "NEW_LOOT" then
    self:ProcessEntries({ eventData }, true)
  end
end

function MI2_LootDataProviderMixin:UniqueKey(entry)
  return entry.ID
end

function MI2_LootDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function MI2_LootDataProviderMixin:GetTableLayout()
  return TABLE_LAYOUT
end

function MI2_LootDataProviderMixin:GetColumnHideStates()
  return self.hideStates
end

local function MI2_ProcessMobs(self, rowData, entry)
  if entry.Mobs then
    for _, mob in pairs(entry.Mobs) do
      if mob.isCreature then
        if not self.uniqueMobs[mob.GUID] then
          self.uniqueNumMobs = self.uniqueNumMobs + 1
          self.uniqueMobs[mob.GUID] = true
        end

        if mob.Id then
          local mobItems = self.mobs[mob.Id]
          if mobItems == nil then
            mobItems = {}
            self.mobs[mob.Id] = mobItems
          end
          table.insert(mobItems, rowData)
        end
      end
    end
  end
end

function MI2_LootDataProviderMixin:onEntryProcessed(entry)
  entry.FirstTime = entry.Time
  local numLoots = 1
  if entry.Mobs and #entry.Mobs > 0 then
    numLoots = #entry.Mobs
    if entry.Mobs[1].isCreature then
      entry.NumMobs = numLoots
    else
      entry.NumNonMobs = numLoots
    end
  end
  if entry.Quality == -1 then
    entry.Amount = entry.Quantity
    entry.Vendor = entry.Quantity
    entry.NumLoots = numLoots
  elseif entry and entry.ID then
    entry.Amount = 0
    entry.Vendor = 0
    entry.NumLoots = entry.Quantity
    local item = Item:CreateFromItemLink(entry.Link)
    if item:IsItemEmpty() then
      -- check for currency without checking link
      local currency = C_CurrencyInfo.GetCurrencyInfoFromLink(entry.Link)
      if not currency then return end
      entry.iconTexture = currency.iconFileID
    else
      item:ContinueOnItemLoad(function()
        entry.iconTexture = item:GetItemIcon()
        entry.vendorPrice = MI2.FindItemValue(entry.Link)
        if Auctionator then
          local auctionPrice = Auctionator.API.v1.GetAuctionPriceByItemLink("MI2", entry.Link)
          if entry.vendorPrice and auctionPrice and auctionPrice > entry.vendorPrice then
            entry.auctionPrice = auctionPrice
          end
        end
        self:setAmount(entry)
        self:SetDirty()
      end)
    end
  end
  MI2_ProcessMobs(self, entry, entry)
end

function MI2_LootDataProviderMixin:setAmount(entry)
  entry.Amount = entry.Quantity
  entry.Vendor = entry.Quantity
  if entry.Quality == 1 then
    entry.Amount = entry.Quantity * (entry.vendorPrice or 0)
    entry.Vendor = entry.Amount
  elseif entry.Quality > 1 then
    entry.Amount = entry.Quantity * (entry.auctionPrice or entry.vendorPrice or 0)
    entry.Vendor = entry.Quantity * (entry.vendorPrice or 0)
  end
end

function MI2_LootDataProviderMixin:onEntryUpdate(rowData, entry)
  local numLoots = 1
  rowData.Quantity = rowData.Quantity + entry.Quantity
  rowData.Time = entry.Time
  if entry.Mobs and #entry.Mobs > 0 then
    numLoots = #entry.Mobs
    if entry.Mobs[1].isCreature then
      rowData.NumMobs = (rowData.NumMobs or 0) + numLoots
    else
      rowData.NumNonMobs = (rowData.NumNonMobs or 0) + numLoots
    end
  end
  self:setAmount(rowData)
  if entry.Quality ~= -1 then
    rowData.NumLoots = rowData.NumLoots + entry.Quantity
  else
    rowData.NumLoots = rowData.NumLoots + numLoots
  end
  MI2_ProcessMobs(self, rowData, entry)
end

function MI2_LootDataProviderMixin:GetNumMobs()
  return self.uniqueNumMobs
end

function MI2_LootDataProviderMixin:SetDirty()
  if self.uniqueNumMobs and self.uniqueNumMobs > 0 then
    for _, entry in pairs(self.results) do
      if entry.NumMobs and entry.NumMobs > 0 then
        local rate = ceil(entry.NumMobs / self.uniqueNumMobs * 100)
        entry.DropRate = rate .. "%"
        entry.DropRateNum = rate
      else
        entry.DropRate = nil
        entry.DropRateNum = 0
      end
    end
  end
  MI2_DataProviderMixin.SetDirty(self)
end

-- Serialize current results to a plain table for SavedVariables.
-- Times are stored as "seconds ago" so they survive session restarts.
function MI2_LootDataProviderMixin:SaveToDB()
  local savedAt = GetServerTime()
  local currentGetTime = GetTime()
  local savedResults = {}
  local skipFields = { Mobs = true, DropRate = true, DropRateNum = true }
  for _, entry in ipairs(self.results) do
    local saved = {}
    for k, v in pairs(entry) do
      if type(v) ~= "function" and type(v) ~= "table"
          and not skipFields[k] and k ~= "Time" and k ~= "FirstTime" then
        saved[k] = v
      end
    end
    saved.secondsAgo      = currentGetTime - (entry.Time      or currentGetTime)
    saved.firstSecondsAgo = currentGetTime - (entry.FirstTime or currentGetTime)
    table.insert(savedResults, saved)
  end
  return { results = savedResults, uniqueNumMobs = self.uniqueNumMobs, savedAt = savedAt }
end

-- Restore results from a previously saved plain table.
-- Bypasses ProcessEntries since all computed fields are already stored.
function MI2_LootDataProviderMixin:LoadFromDB(data)
  self:Reset()
  if not data or not data.results then return end
  local elapsedSinceSave = math.max(0, GetServerTime() - (data.savedAt or GetServerTime()))
  local currentGetTime = GetTime()
  for _, saved in ipairs(data.results) do
    local entry = {}
    for k, v in pairs(saved) do
      entry[k] = v
    end
    entry.Time      = currentGetTime - ((saved.secondsAgo      or 0) + elapsedSinceSave)
    entry.FirstTime = currentGetTime - ((saved.firstSecondsAgo or 0) + elapsedSinceSave)
    entry.secondsAgo      = nil
    entry.firstSecondsAgo = nil
    table.insert(self.results, entry)
    self.insertedKeys[entry.ID] = entry
  end
  self.uniqueNumMobs = data.uniqueNumMobs or 0
  self:SetDirty()
end
