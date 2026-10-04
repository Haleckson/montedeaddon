
MI2_TabbedFrameMixin = {};

function MI2_TabbedFrameMixin:OnLoad()
	self:Init();
end

function MI2_TabbedFrameMixin:Init()
	self.tabbedElements = {};
	self.tabKeyToElementSet = {};
end

function MI2_TabbedFrameMixin:AddTab(tabKey, ...)
	self.tabKeyToElementSet[tabKey] = {};

	for i = 1, select("#", ...) do
		self:AddElementToTab(tabKey, select(i, ...));
	end
end

function MI2_TabbedFrameMixin:AddElementToTab(tabKey, element)
	table.insert(self.tabbedElements, element);

	local elementSet = GetOrCreateTableEntry(self.tabKeyToElementSet, tabKey);
	elementSet[element] = true;
end

function MI2_TabbedFrameMixin:SetTab(tabKey)
	self.tabKey = tabKey;

	local elementSet = self.tabKeyToElementSet[tabKey];
	for i, tabbedElement in ipairs(self.tabbedElements) do
		tabbedElement:SetShown(elementSet and elementSet[tabbedElement]);
	end
end

function MI2_TabbedFrameMixin:GetTab()
	return self.tabKey;
end

function MI2_TabbedFrameMixin:GetTabSet()
	return GetKeysArray(self.tabKeyToElementSet);
end

function MI2_TabbedFrameMixin:GetElementsForTab(tabKey)
	return GetKeysArray(self.tabKeyToElementSet[tabKey]);
end


MI2_TabSystemOwnerMixin = CreateFromMixins(MI2_TabbedFrameMixin);

function MI2_TabSystemOwnerMixin:OnLoad()
	self.internalTabTracker = CreateAndInitFromMixin(MI2_TabbedFrameMixin);
end

function MI2_TabSystemOwnerMixin:SetTabSystem(tabSystem)
	self.tabSystem = tabSystem;
	tabSystem:SetTabSelectedCallback(GenerateClosure(self.SetTab, self));
end

function MI2_TabSystemOwnerMixin:AddNamedTab(tabName, ...)
	local tabID = self.tabSystem:AddTab(tabName);
	self.internalTabTracker:AddTab(tabID, ...);

	return tabID;
end

function MI2_TabSystemOwnerMixin:SetTab(tabID)
	self.internalTabTracker:SetTab(tabID);
	self.tabSystem:SetTabVisuallySelected(tabID);
end

function MI2_TabSystemOwnerMixin:GetTab()
	return self.internalTabTracker:GetTab();
end

function MI2_TabSystemOwnerMixin:GetTabSet()
	return self.internalTabTracker:GetTabSet();
end

function MI2_TabSystemOwnerMixin:GetElementsForTab(tabKey)
	return self.internalTabTracker:GetElementsForTab(tabKey);
end

function MI2_TabSystemOwnerMixin:GetTabButton(tabID)
	return self.tabSystem:GetTabButton(tabID);
end
