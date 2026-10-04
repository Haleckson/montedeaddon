local _, MI2 = ...
MI2_StringCellTemplateMixin = CreateFromMixins(TableBuilderCellMixin)

function MI2_StringCellTemplateMixin:Init(columnName, justifyH)
  self.columnName = columnName
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
  self.Text:SetJustifyH( justifyH or "LEFT")
end

function MI2_StringCellTemplateMixin:Populate(rowData, index)
  self.Text:SetText(rowData[self.columnName])
end
