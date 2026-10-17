local addonName, MCF = ...

local button
local dragging=false

local function Settings()
    if not MyCharForeverDB then return nil end
    MyCharForeverDB.settings=MyCharForeverDB.settings or {}
    return MyCharForeverDB.settings
end

local function PlaceButton()
    if not button then return end
    local st=Settings()
    local angle=(st and tonumber(st.minimapAngle)) or 225
    local radius=105
    local rad=math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER",Minimap,"CENTER",math.cos(rad)*radius,math.sin(rad)*radius)
end

local function UpdateDrag()
    if not dragging then return end
    local mx,my=Minimap:GetCenter()
    local scale=Minimap:GetEffectiveScale()
    local cx,cy=GetCursorPosition()
    cx,cy=cx/scale,cy/scale
    local angle=math.deg(math.atan2(cy-my,cx-mx))
    local st=Settings()
    if st then st.minimapAngle=angle end
    PlaceButton()
end

function MCF:UpdateMinimapButton()
    if not button then return end
    local st=Settings()
    if st and st.showMinimapButton==false then button:Hide() else button:Show(); PlaceButton() end
end

function MCF:CreateMinimapButton()
    if button then self:UpdateMinimapButton(); return end
    button=CreateFrame("Button","MyCharForeverMinimapButton",Minimap)
    button:SetSize(32,32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel()+8)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local border=button:CreateTexture(nil,"OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54,54)
    border:SetPoint("TOPLEFT",0,0)

    local icon=button:CreateTexture(nil,"BACKGROUND")
    icon:SetTexture(MCF.LOGO_PATH)
    icon:SetSize(20,20)
    icon:SetPoint("CENTER",1,0) -- the round logo carries its own gold ring, so it is shown whole; the border texture's opening sits right/below the button centre
    button.icon=icon

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnClick",function(_,mouseButton)
        if mouseButton=="LeftButton" then
            if MCF.ToggleMainWindow then
                MCF:ToggleMainWindow()
            elseif SlashCmdList and SlashCmdList["MYCHARFOREVER"] then
                SlashCmdList["MYCHARFOREVER"]("")
            end
        end
    end)
    button:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("MyCharForever",1,0.82,0.1)
        GameTooltip:AddLine(MCF:T("Click to open"),1,1,1)
        GameTooltip:AddLine(MCF:T("Drag to move"),0.75,0.75,0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart",function(self)
        dragging=true
        self:SetScript("OnUpdate",UpdateDrag)
    end)
    button:SetScript("OnDragStop",function(self)
        dragging=false
        self:SetScript("OnUpdate",nil)
        PlaceButton()
    end)

    self:UpdateMinimapButton()
end
