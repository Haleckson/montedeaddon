local _, MI2 = ...
MI2_SourceKeyCellTemplateMixin = CreateFromMixins(TableBuilderCellMixin)

function MI2_SourceKeyCellTemplateMixin:Init(justifyH)
  self.Text:SetJustifyH( justifyH or "LEFT")
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
end

local function GetText(rowData, withID)
  local text = rowData.Link or rowData.Name or rowData.ID or ""

  if withID then
    text = rowData.ID..": "..text
  end

  if rowData.Type == "Creature" or rowData.Type == "Vehicle" then
    return "["..text.."]"
  end
  return text
end

function MI2_SourceKeyCellTemplateMixin:Populate(rowData, index)
  self.Text:SetText(GetText(rowData))

  if rowData.iconTexture ~= nil then
    self.Icon:SetTexture(rowData.iconTexture)
    self.Icon:SetSize(14,14)
    self.Icon:Show()
  else
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
    self.Icon:SetSize(-2,-1)
  end
end

function MI2_SourceKeyCellTemplateMixin:OnEnter()
  if IsShiftKeyDown() then
    self.Text:SetText(GetText(self.rowData,true))
  end
  if self.rowData.Type == "Creature" or self.rowData.Type == "Vehicle" then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    MI2.CreateTooltip( self.rowData.ID, self.rowData.Level or 0, nil, true, false, true )
  end
end

function MI2_SourceKeyCellTemplateMixin:OnLeave()
  self.Text:SetText(GetText(self.rowData))
  MI2.HideTooltip()
end
