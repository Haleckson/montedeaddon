local _, MI2 = ...
MI2_LootKeyCellTemplateMixin = CreateFromMixins(TableBuilderCellMixin)

function MI2_LootKeyCellTemplateMixin:Init(justifyH)
  self.Text:SetJustifyH( justifyH or "LEFT")
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
end

function MI2_LootKeyCellTemplateMixin:Populate(rowData, index)

  self.Text:SetText(rowData.Link or rowData.Name or "")

  if rowData.iconTexture ~= nil then
    local _,fontSize = MI2.SummaryFont.Normal:GetFont()
    self.Icon:SetTexture(rowData.iconTexture)
    self.Icon:SetSize(fontSize-1,fontSize-1)
    self.Icon:Show()
  else
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
    self.Icon:SetSize(-2,-1)
  end
end

function MI2_LootKeyCellTemplateMixin:OnEnter()
  self:GetParent():OnEnter()
  if self.rowData.Link then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.rowData.Link)
    GameTooltip:Show()
  end
end

function MI2_LootKeyCellTemplateMixin:OnLeave()
  self:GetParent():OnLeave()
  if self.rowData.Link then
    GameTooltip:Hide()
  end
end
