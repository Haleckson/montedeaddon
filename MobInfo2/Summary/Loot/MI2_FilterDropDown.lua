MI2_FilterDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local function GetQualityFilterString(itemQuality)
	local hex = select(4, GetItemQualityColor(itemQuality));
	local text = _G["ITEM_QUALITY"..itemQuality.."_DESC"];
	return "|c"..hex..text.."|r";
end

local defaultFilters = 
{
  [-1] = true,
  [ 1] = true,
  [ 2] = true,
  [ 3] = true,
  [ 4] = true,
  [ 5] = true,
  [ 6] = true,
  [ 7] = true,
}

function MI2_FilterDropDownMixin:OnLoad()

  self.qualityFilter = {}
  for itemQuality,checked in pairs(defaultFilters) do
    self.qualityFilter[itemQuality] = checked
  end

  local function InitializeDropDown(self)
    self:GetParent():InitializeDropDown()
  end
  LibDD:Create_UIDropDownMenu(self.DropDown)
  LibDD:UIDropDownMenu_SetInitializeFunction(self.DropDown, InitializeDropDown)
  LibDD:UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU")

end

function MI2_FilterDropDownMixin:GetQualityFilter()
  return self.qualityFilter
end

function MI2_FilterDropDownMixin:SetOnCallback(onCallback)
  self.onCallback = onCallback
end

function MI2_FilterDropDownMixin:OnMouseDown(button)
  self.IconOverlay:Show()
  LibDD:ToggleDropDownMenu(1, nil, self.DropDown, self, 0, -5)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function MI2_FilterDropDownMixin:OnMouseUp()
  self.IconOverlay:Hide()
end

function MI2_FilterDropDownMixin:OnSelection(value, checked)
	if (checked) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	end
  self.qualityFilter[value] = checked
  if self.onCallback then self.onCallback(self.qualityFilter) end
end

function MI2_FilterDropDownMixin:InitializeDropDown()
  local function OnSelection(button)
    self:OnSelection(button.value, button.checked)
  end

  local info = LibDD:UIDropDownMenu_CreateInfo()

  info.text = MI2_TXT_FilterMoney
  info.isNotRadio = true
  info.checked = self.qualityFilter[-1]
  info.disabled = false
  info.keepShownOnClick = true
  info.value = -1
  info.func = OnSelection
  LibDD:UIDropDownMenu_AddButton(info)
  LibDD:UIDropDownMenu_AddSeparator();

  for idx,checked in ipairs(self.qualityFilter) do
    info.text = GetQualityFilterString(idx-1)
    info.checked = checked
    info.value = idx
    LibDD:UIDropDownMenu_AddButton(info)
  end
end

function MI2_FilterDropDownMixin:HandlesGlobalMouseEvent(buttonID, event)
	return (event == "GLOBAL_MOUSE_UP" or event == "GLOBAL_MOUSE_DOWN") and buttonID == "LeftButton";
end

function MI2_FilterDropDownMixin:OnEnter()
	self.IconOverlay:Show()
end

function MI2_FilterDropDownMixin:OnLeave()
  self.IconOverlay:Hide()
end
