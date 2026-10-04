local _, MI2 = ...
MI2_SettingsDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

function MI2_SettingsDropDownMixin:OnLoad()

  local function InitializeDropDown(self, level)
    self:GetParent():InitializeDropDown(level)
  end

  LibDD:Create_UIDropDownMenu(self.DropDown)
  LibDD:UIDropDownMenu_SetInitializeFunction(self.DropDown, InitializeDropDown)
  LibDD:UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU")

end

function MI2_SettingsDropDownMixin:SetOnCallback(onCallback)
  self.onCallback = onCallback
end

function MI2_SettingsDropDownMixin:OnMouseDown(button)
  LibDD:ToggleDropDownMenu(1, nil, self.DropDown, self, 0, -5)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function MI2_SettingsDropDownMixin:InitializeDropDown(level)
  local function OnSelection(button, ...)
    if self.onCallback then self.onCallback(button.value, ...) end
    LibDD:CloseDropDownMenus()
  end

  local info = LibDD:UIDropDownMenu_CreateInfo()
  info.tooltipOnButton = true

  if level == 1 then
    info.text = MI2_TXT_SummaryReset.text
    info.tooltipTitle = MI2_TXT_SummaryReset.text
    info.tooltipText = MI2_TXT_SummaryReset.tooltipText
    info.notCheckable = true;
    info.value = 1
    info.func = OnSelection
    LibDD:UIDropDownMenu_AddButton(info)
    LibDD:UIDropDownMenu_AddSeparator()

    info.text = "Font"
    info.tooltipOnButton = nil
    info.value = nil
    info.hasArrow = true
    info.func = nil
    info.keepShownOnClick = true
    LibDD:UIDropDownMenu_AddButton(info)
    LibDD:UIDropDownMenu_AddSeparator()

    local cbInfo = LibDD:UIDropDownMenu_CreateInfo()
    cbInfo.tooltipOnButton = true
    cbInfo.text = MI2_TXT_ResetOnLogin.text
    cbInfo.tooltipTitle = MI2_TXT_ResetOnLogin.text
    cbInfo.tooltipText = MI2_TXT_ResetOnLogin.tooltipText
    cbInfo.isNotRadio = true
    cbInfo.value = 3
    cbInfo.func = OnSelection
    cbInfo.checked = function() return MobInfoConfig.AlwaysResetSummary == 1 end
    LibDD:UIDropDownMenu_AddButton(cbInfo)
  elseif level == 2 then
    info.isNotRadio = true
    info.value = 2
    info.func = OnSelection

    for _, v in ipairs(MI2_TXT_SummaryFont) do
      info.text = v.text
      info.tooltipTitle = v.text
      info.tooltipText = v.tooltipText
      info.checked = v.font == MI2.SummaryFont.Normal
      info.arg1 = v.font
      LibDD:UIDropDownMenu_AddButton(info, 2)
    end
  end
end

function MI2_SettingsDropDownMixin:HandlesGlobalMouseEvent(buttonID, event)
  return (event == "GLOBAL_MOUSE_UP" or event == "GLOBAL_MOUSE_DOWN") and buttonID == "LeftButton";
end
