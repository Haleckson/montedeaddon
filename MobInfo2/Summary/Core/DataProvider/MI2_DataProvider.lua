MI2_DataProviderMixin = {}

function MI2_DataProviderMixin:OnLoad()
  self.results = {}
  self.cachedResults = {}
  self.insertedKeys = {}
  self.entriesToProcess = {}
  self.processCountPerUpdate = 200
  self.presetSort = {key = nil, direction = nil}
  self.processingIndex = 0

  self.onUpdate = function() end
  self.onPreserveScroll = function() end
  self.onResetScroll = function() end
end

function MI2_DataProviderMixin:OnUpdate(elapsed)
  if elapsed >= 0 then
    self:CheckForEntriesToProcess()
  end
end

function MI2_DataProviderMixin:Reset()
   -- Last set of results passed to self.onUpdate. Used to avoid errors with out
   -- of range indexes if :GetEntry is called before the OnUpdate fires.
  self.cachedResults = self.cachedResults or self.results or {}

  self.results = {}
  self.insertedKeys = {}
  self.entriesToProcess = {}
  self.processingIndex = 0

  self:SetDirty()
end

-- Derive: This will be used to help with sorting and filtering unique entries
function MI2_DataProviderMixin:UniqueKey(entry)
end

-- Derive: This is the template for sorting the dataset contained by this provider
function MI2_DataProviderMixin:Sort(fieldName, sortDirection)
end

-- Derive: This is the template for filtering the dataset contained by this provider
function MI2_DataProviderMixin:Filter( entries )
  return entries
end

-- Sets sorting fieldName/sortDirection to use as data is being processed. Set
-- either to nil to disable any sorting.
function MI2_DataProviderMixin:SetPresetSort(fieldName, sortDirection)
  self.presetSort.key = fieldName
  self.presetSort.direction = sortDirection
end

-- Uses sortingIndex to restore original order before sorting
function MI2_DataProviderMixin:ClearSort()
  self:SetPresetSort(nil, nil)
  table.sort(self.results, function(left, right)
    return left.sortingIndex < right.sortingIndex
  end)
  self:SetDirty()
end

function MI2_DataProviderMixin:GetTableLayout()
  return {}
end

-- Derive: This sets table which stores the options for saving the customized
-- column view.  If this is nil, it won't be possible to Customize the columns.
function MI2_DataProviderMixin:GetColumnHideStates()
  return nil
end

function MI2_DataProviderMixin:GetRowTemplate()
  return "MI2_ResultsRowTemplate"
end

function MI2_DataProviderMixin:GetEntryAt(index)
  return self.cachedResults[index]
end

function MI2_DataProviderMixin:GetCount()
  return #self.cachedResults
end

function MI2_DataProviderMixin:SetOnUpdateCallback(onUpdateCallback)
  self.onUpdate = onUpdateCallback
end

function MI2_DataProviderMixin:SetDirty()
  self.isDirty = true
end

function MI2_DataProviderMixin:SetOnPreserveScrollCallback(onPreserveScrollCallback)
  self.onPreserveScroll = onPreserveScrollCallback
end

function MI2_DataProviderMixin:SetOnResetScrollCallback(onResetScrollCallback)
  self.onResetScroll = onResetScrollCallback
end

function MI2_DataProviderMixin:ProcessEntries(entries, isLastSetOfResults)
  for _, entry in ipairs(entries) do
    table.insert(self.entriesToProcess, entry)
  end
end

-- We process a limited number of entries every frame to avoid freezing the
-- client.
function MI2_DataProviderMixin:CheckForEntriesToProcess()
  if #self.entriesToProcess == 0 then
    if self.isDirty then
      self.cachedResults = self:Filter(self.results)
      self.onUpdate(self.results)
      self.isDirty = false
    end
    return
  end

  local processCount = 0
  local entry
  local key

  while processCount < self.processCountPerUpdate and self.processingIndex < #self.entriesToProcess do
    self.processingIndex = self.processingIndex + 1
    entry = self.entriesToProcess[self.processingIndex]

    key = self:UniqueKey(entry)

    if self.insertedKeys[key] == nil then
      processCount = processCount + 1
      self.insertedKeys[key] = entry
      table.insert(self.results, entry)

      --Used to keep items in a consistent order when fields are identical and sorting
      entry.sortingIndex = #self.results

      self:onEntryProcessed(entry)
    else
      self:onEntryUpdate( self.insertedKeys[key], entry )
    end
  end

  if self.presetSort.key ~= nil and self.presetSort.direction ~= nil then
    self:Sort(self.presetSort.key, self.presetSort.direction)
  end

  local resetQueue = false
  if self.processingIndex == #self.entriesToProcess then
    self.entriesToProcess = {}
    self.processingIndex = 0
    resetQueue = true
  end

  self.cachedResults = self:Filter(self.results)
  self.onUpdate(self.results)
  self.isDirty = false
end

function MI2_DataProviderMixin:onEntryProcessed(entry)
end

function MI2_DataProviderMixin:onEntryUpdate(rowData, entry)
end
