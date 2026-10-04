MI2_CustomizeColumnsDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

function MI2_CustomizeColumnsDropDownMixin:OnLoad()
  LibDD:Create_UIDropDownMenu(self)
  LibDD:UIDropDownMenu_SetInitializeFunction(self, MI2_CustomizeColumnsDropDownMixin.Initialize)
  LibDD:UIDropDownMenu_SetDisplayMode(self, "MENU")
end

function MI2_CustomizeColumnsDropDownMixin:Callback(columns, hideStates, applyChanges)
  self.columns = columns
  self.hideStates = hideStates
  self.applyChanges = applyChanges

  self:Toggle()
end

function MI2_CustomizeColumnsDropDownMixin:MoreThanOneVisible()
  local count = 0
  for _, column in ipairs(self.columns) do
    if not self.hideStates[column.headerText] then
      count = count + 1
    end
  end

  return count >= 2
end

function MI2_CustomizeColumnsDropDownMixin:Initialize()
  if not self.columns then
    LibDD:HideDropDownMenu(1)
    return
  end

  for _, column in ipairs(self.columns) do
    local info = LibDD:UIDropDownMenu_CreateInfo()
    info.text = column.headerText
    info.isNotRadio = true
    info.checked = not self.hideStates[column.headerText]
    info.keepShownOnClick = true
    info.disabled = not (column.canHide == nil or column.canHide)
    if #column.headerParameters > 1 then
      info.tooltipOnButton = true
      info.tooltipTitle = column.headerParameters[2]
      if #column.headerParameters > 2 then
        info.tooltipText = column.headerParameters[3]
      end
      info.tooltipWhileDisabled = true
    end
    info.func = (function(column)
      return function()
        self.hideStates[column.headerText] = self:MoreThanOneVisible() and not self.hideStates[column.headerText]
        self.applyChanges()
      end
    end)(column)
    LibDD:UIDropDownMenu_AddButton(info)
  end
end

function MI2_CustomizeColumnsDropDownMixin:Toggle()
  LibDD:ToggleDropDownMenu(1, nil, self, "cursor", 0, 0)
end
