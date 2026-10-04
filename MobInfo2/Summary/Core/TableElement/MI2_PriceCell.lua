local _, MI2 = ...
MI2_PriceCellTemplateMixin = CreateFromMixins(TableBuilderCellMixin)

function MI2_PriceCellTemplateMixin:Init(columnName)
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
  self.columnName = columnName
end

function MI2_PriceCellTemplateMixin:Populate(rowData, index)
  if rowData[self.columnName] ~= nil and rowData[self.columnName] > 0 then
    self.Text:SetText(GetMoneyString(rowData[self.columnName]))
  else
    self.Text:SetText(" ")
  end
end
