local _, A = ...

function A.CreateScrollFrame(parent)
    local scroll=CreateFrame("ScrollFrame",nil,parent)
    local slider=CreateFrame("Slider",nil,parent)
    slider:SetWidth(7)
    slider:SetPoint("TOPLEFT",scroll,"TOPRIGHT",6,-2)
    slider:SetPoint("BOTTOMLEFT",scroll,"BOTTOMRIGHT",6,2)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0,0)
    slider:SetValueStep(1)
    local rail=slider:CreateTexture(nil,"BACKGROUND")
    rail:SetAllPoints(slider)
    rail:SetColorTexture(0.12,0.11,0.09,0.8)
    local thumb=slider:CreateTexture(nil,"ARTWORK")
    thumb:SetSize(7,34)
    thumb:SetColorTexture(0.66,0.53,0.32,1)
    slider:SetThumbTexture(thumb)
    local updating=false
    function scroll:SyncScrollBar()
        if updating then return end
        updating=true
        local range=math.max(0,self:GetVerticalScrollRange())
        local offset=math.min(range,math.max(0,self:GetVerticalScroll()))
        slider:SetMinMaxValues(0,range)
        slider:SetShown(range>1 and self:IsShown())
        slider:SetValue(offset)
        if self:GetVerticalScroll()~=offset then self:SetVerticalScroll(offset) end
        updating=false
    end
    slider:SetScript("OnValueChanged",function(_,value)
        if not updating then scroll:SetVerticalScroll(value) end
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(self,delta)
        self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*32)))
    end)
    scroll:SetScript("OnVerticalScroll",function(self) self:SyncScrollBar() end)
    scroll:SetScript("OnScrollRangeChanged",function(self) self:SyncScrollBar() end)
    scroll:SetScript("OnShow",function(self) self:SyncScrollBar() end)
    scroll:SetScript("OnHide",function() slider:Hide() end)
    scroll.bar=slider
    return scroll
end
