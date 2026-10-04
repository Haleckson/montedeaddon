MI2_ResultsRowTemplateMixin = {}

function MI2_ResultsRowTemplateMixin:OnClick(...)
end

function MI2_ResultsRowTemplateMixin:OnEnter(...)
  self.HighlightTexture:Show()
end

function MI2_ResultsRowTemplateMixin:OnLeave(...)
  self.HighlightTexture:Hide()
end

function MI2_ResultsRowTemplateMixin:Populate(rowData, dataIndex)
  self.rowData = rowData
  self.dataIndex = dataIndex
end
