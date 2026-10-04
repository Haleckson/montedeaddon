-------------------------------
-- Object Mouseover Alert Module (Revisedx)
-------------------------------

local RED = {1, 0, 0}

local objectAlertFrame = CreateFrame("Frame", "unitscan_objectalert", UIParent, "BackdropTemplate")
objectAlertFrame:Hide()
unitscan = unitscan or {}
unitscan.objectAlertFrame = objectAlertFrame

if _G["unitscan_button"] then
    objectAlertFrame:SetPoint("CENTER", unitscan_button, "CENTER", 0, 0)
else
    objectAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

objectAlertFrame:SetWidth(177)
objectAlertFrame:SetHeight(37)
objectAlertFrame:SetScale(1.25)
objectAlertFrame:SetMovable(true)
objectAlertFrame:EnableMouse(true)

objectAlertFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
objectAlertFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
    end
end)
objectAlertFrame:SetFrameStrata("FULLSCREEN_DIALOG")

objectAlertFrame:SetBackdrop({
    bgFile   = nil,  
    edgeFile = [[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]],
    edgeSize = 16,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 }
})
objectAlertFrame:SetBackdropBorderColor(unpack(RED))

local background = objectAlertFrame:CreateTexture(nil, "BACKGROUND")
background:SetTexture([[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]])
background:SetAllPoints(objectAlertFrame)
background:SetTexCoord(0, 1, 0, 0.25)

local title_background = objectAlertFrame:CreateTexture(nil, "BORDER")
title_background:SetTexture([[Interface\AddOns\unitscan\UI-Achievement-Title]])
title_background:SetPoint("TOPRIGHT", objectAlertFrame, -5, -5)
title_background:SetPoint("LEFT", objectAlertFrame, 5, 0)
title_background:SetHeight(18)
title_background:SetTexCoord(0, 0.9765625, 0, 0.3125)
title_background:SetAlpha(0.8)

local title = objectAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
title:SetWordWrap(false)
title:SetPoint("TOPLEFT", title_background, 0, 0)
title:SetPoint("RIGHT", title_background)
objectAlertFrame.title = title

local subtitle = objectAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
subtitle:SetPoint("RIGHT", title)
subtitle:SetText("This summons Elites!")

local model = CreateFrame("PlayerModel", nil, objectAlertFrame)
objectAlertFrame.model = model
model:SetPoint("BOTTOMLEFT", objectAlertFrame, "TOPLEFT", 0, -4)
model:SetPoint("RIGHT", objectAlertFrame, "RIGHT", 0, 0)
model:SetHeight(objectAlertFrame:GetWidth() * 0.6)

local close = CreateFrame("Button", nil, objectAlertFrame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", objectAlertFrame, 0, 0)
close:SetWidth(0)
close:SetHeight(0)
close:SetHitRectInsets(0, 0, 0, 0)
close:Hide()

do
    local glow = objectAlertFrame.model:CreateTexture(nil, "OVERLAY")
    objectAlertFrame.glow = glow
    glow:SetPoint("CENTER", objectAlertFrame, "CENTER")
    glow:SetWidth(400 / 300 * objectAlertFrame:GetWidth())
    glow:SetHeight(171 / 70 * objectAlertFrame:GetHeight())
    glow:SetTexture([[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]])
    glow:SetBlendMode("ADD")
    glow:SetTexCoord(0, 0.78125, 0, 0.66796875)
    glow:SetAlpha(0)
    
    glow.animation = CreateFrame("Frame")
    glow.animation:Hide()
    glow.animation:SetScript("OnUpdate", function(self)
        local t = GetTime() - self.t0
        if t <= 0.2 then
            glow:SetAlpha(t * 5)
        elseif t <= 0.7 then
            glow:SetAlpha(1 - (t - 0.2) * 2)
        else
            glow:SetAlpha(0)
            self:Hide()
        end
    end)
    function glow.animation:Play()
        self.t0 = GetTime()
        self:Show()
    end
end

do
    local shine = objectAlertFrame:CreateTexture(nil, "ARTWORK")
    objectAlertFrame.shine = shine
    shine:SetPoint("TOPLEFT", objectAlertFrame, 0, 8)
    shine:SetWidth(67 / 300 * objectAlertFrame:GetWidth())
    shine:SetHeight(1.28 * objectAlertFrame:GetHeight())
    shine:SetTexture([[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]])
    shine:SetBlendMode("ADD")
    shine:SetTexCoord(0.78125, 0.912109375, 0, 0.28125)
    shine:SetAlpha(0)
    
    shine.animation = CreateFrame("Frame")
    shine.animation:Hide()
    shine.animation:SetScript("OnUpdate", function(self)
        local t = GetTime() - self.t0
        if t <= 0.3 then
            shine:SetPoint("TOPLEFT", objectAlertFrame, 0, 8)
        elseif t <= 0.7 then
            shine:SetPoint("TOPLEFT", objectAlertFrame, (t - 0.3) * 2.5 * self.distance, 8)
        end
        if t <= 0.3 then
            shine:SetAlpha(0)
        elseif t <= 0.5 then
            shine:SetAlpha(1)
        elseif t <= 0.7 then
            shine:SetAlpha(1 - (t - 0.5) * 5)
        else
            shine:SetAlpha(0)
            self:Hide()
        end
    end)
    function shine.animation:Play()
        self.t0 = GetTime()
        self.distance = objectAlertFrame:GetWidth() - shine:GetWidth() + 8
        self:Show()
    end
end

function objectAlertFrame:set_target(name)
    self.title:SetText(name)
    self:Show()
    self.glow.animation:Play()
    self.shine.animation:Play()
    
    PlaySoundFile("Interface\\AddOns\\unitscan\\alarmx.wav", "Master")

    C_Timer.After(1, function()
        PlaySoundFile("Interface\\AddOns\\unitscan\\alarmx.wav", "Master")
    end)
    

    C_Timer.After(10, function()
        self:Hide()
    end)
end

local lastAlertTime = 0 

local validObjects = {
    --["Wooden Chair"]    = true,
    ["Blood of Heroes"] = true,
    ["Fire of Aku'mai"] = true,
	["Blut von Helden"] = true,
	["Feuer von Aku'mai"] = true,
	["Кровь героев"] = true,
	["Sang des héros"] = true,
	["Sangre de héroes"] = true,
}

GameTooltip:HookScript("OnUpdate", function(self)
    if not self:IsVisible() then return end
    
    -- avoid false alert
    local _, itemLink = self:GetItem()
    if itemLink then return end
    
    local line = _G[self:GetName().."TextLeft1"]
    local text = line and line:GetText()
    if not text then return end

    -- Guard against WoW 12.0+ Secret Values
    if (issecretvalue and issecretvalue(text)) or (canaccessvalue and not canaccessvalue(text)) then
        return
    end

    if validObjects[text] then
        if (GetTime() - lastAlertTime) >= 300 then  -- 5m
            lastAlertTime = GetTime()
            objectAlertFrame:set_target(text)
        end
    end
end)

local regenFrame = CreateFrame("Frame")
regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
regenFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        objectAlertFrame:Hide()
    end
end)
