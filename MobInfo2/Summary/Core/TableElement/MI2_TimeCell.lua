local _, MI2 = ...
MI2_TimeCellTemplateMixin = CreateFromMixins(TableBuilderCellMixin)

local function GetTimeString(time)
  time =floor(time)
  local timeString = ""
  local t = floor(time/86400)
  if t > 0 then timeString = tostring(t)..":" end

  time = time %86400
  t = floor(time/3600)
  if t > 0 then
     if t < 10 then timeString = timeString.."0" end
     timeString = timeString..tostring(t)..":"
  end

  time = time %3600
  t = floor(time/60)
  if t > 0 then
     if t < 10 then timeString = timeString.."0" end
     timeString = timeString..tostring(t)..":"
  else
     timeString = "00:"
  end

  t = time %60
  if t < 10 then timeString = timeString.."0" end
  timeString = timeString..tostring(t)

  return timeString
end

function MI2_TimeCellTemplateMixin:SetValue()
  if self.rowData then
    local time = self.rowData[self.columnName]
    if time then
      self.Text:SetText(GetTimeString(GetTime() - time))
    else
      self.Text:SetText(" ")
   end
  end
end

function MI2_TimeCellTemplateMixin:Init(columnName)
  self.Text:SetFontObject(MI2.SummaryFont.Normal)
  self.Text:SetJustifyH("RIGHT")
  self.columnName = columnName
end

function MI2_TimeCellTemplateMixin:Populate(rowData, index)
  self:SetValue()
end

function MI2_TimeCellTemplateMixin:OnHide()
  self.Text:Hide()
  if self.ticker then
    self.ticker:Cancel()
    self.ticker = nil
  end
end

function MI2_TimeCellTemplateMixin:OnShow()
  self.Text:Show()
  if not self.ticker then
    self.ticker = C_Timer.NewTicker(1,function() self:SetValue() end)
  end
end
