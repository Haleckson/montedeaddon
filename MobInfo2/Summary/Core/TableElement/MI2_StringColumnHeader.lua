local _, MI2 = ...
MI2_StringColumnHeaderTemplateMixin = CreateFromMixins(TableBuilderElementMixin)

function MI2_StringColumnHeaderTemplateMixin:Init(name, customizeFunction, sortFunction, clearSortFunction, sortKey, tooltipTitle, tooltipText )
  self.tooltipTitle = tooltipTitle
  self.tooltipText = tooltipText
  self.sortKey = sortKey
  self.customizeFunction = customizeFunction
  self.clearSortFunction = clearSortFunction
  self.sortFunction = sortFunction
  self.sortDirection = nil
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
  self.Left:SetHeight(MI2.SummaryFont:GetHeight()+4)
  self.Right:SetHeight(MI2.SummaryFont:GetHeight()+4)
  self.Middle:SetHeight(MI2.SummaryFont:GetHeight()+4)
  self:SetText(name)
end

function MI2_StringColumnHeaderTemplateMixin:DoSort()
  if self.sortKey then
    if self.sortDirection == 0 or self.sortDirection == nil then
      self.sortDirection = 1
    else
      self.sortDirection =0
    end

    self.sortFunction(self.sortKey, self.sortDirection)

    if self.sortDirection == 0 then
      self.Arrow:SetTexCoord(0, 1, 1, 0)
    else
      self.Arrow:SetTexCoord(0, 1, 0, 1)
    end

    self.Arrow:Show()
  end

  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function MI2_StringColumnHeaderTemplateMixin:OnClick(button, ...)
  if button == "LeftButton" then
    if IsShiftKeyDown() then
      self.clearSortFunction()
    else
      self:DoSort()
    end
  end
end

function MI2_StringColumnHeaderTemplateMixin:OnMouseUp(button, ...)
  if button == "RightButton" then
    self.customizeFunction()
  end
end

function MI2_StringColumnHeaderTemplateMixin:OnEnter()
  if self.tooltipTitle then
    local tooltip = GetAppropriateTooltip()
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(tooltip, self.tooltipTitle)
    if self.tooltipText then
      GameTooltip_AddNormalLine(tooltip, self.tooltipText, true);
    end
    tooltip:Show()
  end
end

function MI2_StringColumnHeaderTemplateMixin:OnLeave()
  GetAppropriateTooltip():Hide()
end
