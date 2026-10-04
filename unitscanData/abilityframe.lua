if showmobinfo == nil then
    showmobinfo = 1
end

local seasonId = C_Seasons and C_Seasons.GetActiveSeason and C_Seasons.GetActiveSeason()

local UnitBuff = UnitBuff or function(unit, index)
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, unit, index)
        if ok and aura then
            return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId
        end
    end
end

--wow forever compability fix(temp)
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture

local function GetDataByID(dataType, dataId)
    local data = _G[dataType]
    if not data then return nil end

    local convertedId = tonumber(dataId)
    if not convertedId then return nil end

    if dataType == "unitscanhardcorenpcs" then
        return data[convertedId]
    else
        local clientLocale = GetLocale():sub(1,2)
        local validLangs = { en = true, de = true, es = true, fr = true, ko = true, pt = true, ru = true, zh = true }
        if not validLangs[clientLocale] then
            clientLocale = "en"
        end
        if data[clientLocale] then
            return data[clientLocale][convertedId]
        end
    end

    return nil
end

local function BuildAbilitiesText(npcData)
    local text = ""
    local addedAbilityNames = {}
    local firstAbility = true

    if seasonId == 2 and npcData.sod_spell_ids then
        for _, abilityId in ipairs(npcData.sod_spell_ids) do
            local abilityData = GetDataByID('unitscanhardcoreabilities', abilityId)
            if abilityData then
                local name = abilityData.name
                local description = abilityData.description or ""
                local mechanic = abilityData.mechanic or ""
                addedAbilityNames[name] = true

                local texture = GetSpellTexture(abilityId) or ""
                local icon = "|T" .. texture .. ":12:12:0:0:64:64:4:60:4:60|t"
                local mechanicText = ""
                if mechanic ~= "" then
                    mechanicText = " - " .. mechanic
                end

                if not firstAbility then
                    text = text .. "\n\n"
                end
                text = text .. icon .. " " .. name .. mechanicText .. "\n" .. description
                firstAbility = false
            end
        end
    end

    if npcData.classic_spell_ids then
        for _, abilityId in ipairs(npcData.classic_spell_ids) do
            local abilityData = GetDataByID('unitscanhardcoreabilities', abilityId)
            if abilityData then
                local name = abilityData.name
                if not addedAbilityNames[name] then
                    local description = abilityData.description or ""
                    local mechanic = abilityData.mechanic or ""
                    local texture = GetSpellTexture(abilityId) or ""
                    local icon = "|T" .. texture .. ":12:12:0:0:64:64:4:60:4:60|t"
                    local mechanicText = ""
                    if mechanic ~= "" then
                        mechanicText = " - " .. mechanic
                    end

                    if not firstAbility then
                        text = text .. "\n\n"
                    end
                    text = text .. icon .. " " .. name .. mechanicText .. "\n" .. description
                    firstAbility = false
                end
            end
        end
    end

    return text
end

local npcAbilitiesFrame = CreateFrame("Frame", "NpcAbilitiesFrame", UIParent, "BackdropTemplate")
npcAbilitiesFrame.lastNpcId = nil
npcAbilitiesFrame:SetSize(300, 15)  -- initial
npcAbilitiesFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
npcAbilitiesFrame:Hide()

npcAbilitiesFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\unitscan\\black.tga", -- Keep
    edgeFile = "Interface\\Addons\\unitscanData\\assets\\border", 
    tile = true, tileSize = 16, 
    edgeSize = 16, 
    insets = { left = 4, right = 4, top = 4, bottom = 4 } 
})

npcAbilitiesFrame:SetMovable(true)
npcAbilitiesFrame:EnableMouse(true)
npcAbilitiesFrame:RegisterForDrag("LeftButton")
npcAbilitiesFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
npcAbilitiesFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local headerTexture = npcAbilitiesFrame:CreateTexture(nil, "ARTWORK")
headerTexture:SetTexture("Interface\\AddOns\\unitscan\\title_dark.tga")
headerTexture:ClearAllPoints() 

local insetTop = 4
local insetLeft = 4
local insetRight = 4

headerTexture:SetPoint("TOPLEFT", npcAbilitiesFrame, "TOPLEFT", insetLeft, -insetTop)
headerTexture:SetPoint("TOPRIGHT", npcAbilitiesFrame, "TOPRIGHT", -insetRight, -insetTop)
headerTexture:SetHeight(40) -- Keep

local headerText = npcAbilitiesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
headerText:SetText("Unitscan Hardcore")
headerText:SetTextColor(1, 1, 0)
headerText:SetPoint("CENTER", headerTexture, "CENTER", 10, 0)

local logoTexture = npcAbilitiesFrame:CreateTexture(nil, "OVERLAY")
logoTexture:SetTexture("Interface\\AddOns\\unitscan\\unitscanhardcore_b.tga")
logoTexture:SetSize(32, 32)
logoTexture:SetPoint("RIGHT", headerText, "LEFT", -5, 0)

local targetNameText = npcAbilitiesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
targetNameText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
targetNameText:SetTextColor(1, 1, 1)
targetNameText:SetPoint("TOP", headerText, "BOTTOM", 0, -2)

local abilitiesText = npcAbilitiesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
abilitiesText:SetFont((GetLocale():sub(1,2) == "ko") and "Interface\\AddOns\\unitscanData\\Orbit-Regular.ttf" or "Fonts\\FRIZQT__.TTF", 12, "")
abilitiesText:SetJustifyH("LEFT")
abilitiesText:SetJustifyV("TOP")
abilitiesText:SetPoint("TOPLEFT", npcAbilitiesFrame, "TOPLEFT", 4 + 10, -60) 
abilitiesText:SetWidth(300 - (4+10)*2)

local function AnimateFrame(frame, targetHeight, duration)
    frame.isHiding = false
    local isShown = frame:IsShown()
    local startHeight = isShown and frame:GetHeight() or 15
    local startAlpha = isShown and frame:GetAlpha() or 0
    local endAlpha = 1
    local startTime = GetTime()

    if isShown then
        abilitiesText:SetAlpha(0)
        targetNameText:SetAlpha(0)
    else
        abilitiesText:SetAlpha(1)
        targetNameText:SetAlpha(1)
    end

    frame:Show()

    frame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local progress = (now - startTime) / duration
        
        if progress >= 1 then
            progress = 1
            self:SetScript("OnUpdate", nil)
            abilitiesText:SetAlpha(1)
            targetNameText:SetAlpha(1)
        end
        
        local newHeight = startHeight + (targetHeight - startHeight) * progress
        local newAlpha = startAlpha + (endAlpha - startAlpha) * progress
        
        self:SetHeight(newHeight)
        self:SetAlpha(newAlpha)
        
        if isShown then
            abilitiesText:SetAlpha(progress)
            targetNameText:SetAlpha(progress)
        end
    end)
end

local function AnimateFrameReverse(frame, duration)
    if frame.isHiding then return end
    frame.isHiding = true
    frame.lastNpcId = nil
    abilitiesText:Hide()

    local startHeight = frame:GetHeight()
    local targetHeight = 15
    local startAlpha = frame:GetAlpha()
    local endAlpha = 0
    local startTime = GetTime()

    frame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local progress = (now - startTime) / duration
        if progress >= 1 then
            progress = 1
            self:SetScript("OnUpdate", nil)
            self.isHiding = false
            self:Hide()
        end
        local newHeight = startHeight - (startHeight - targetHeight) * progress
        local newAlpha = startAlpha - (startAlpha - endAlpha) * progress
        self:SetHeight(newHeight)
        self:SetAlpha(newAlpha)
    end)
end

local function UpdateNpcAbilitiesDisplay()
    -- disabled
    if showmobinfo == 0 then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    -- combat
    if UnitAffectingCombat("player") then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end
	
	-- instance/raid combat
    if IsInInstance() and IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, GetNumGroupMembers() do
            if UnitAffectingCombat(prefix .. i) then
                if npcAbilitiesFrame:IsShown() then
                    AnimateFrameReverse(npcAbilitiesFrame, 0.5)
                end
                return
            end
        end
    end
	
	-- buffs
    for i = 1, 40 do
        -- grab id
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        
        -- break on nil
        if not name then
            break 
        end

        -- petri, feign, vanish, block
        if spellId == 17624 or spellId == 5384 or spellId == 1856 or spellId == 1857 or spellId == 11958 then
            if npcAbilitiesFrame:IsShown() then
                AnimateFrameReverse(npcAbilitiesFrame, 0.5)
            end
            return
        end
    end

    -- exist
    if not UnitExists("target") then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    -- dead
    if UnitIsFriend("player", "target") or UnitIsDead("target") then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    local unitId = "target"

    local unitGUID = UnitGUID(unitId)
    if not unitGUID or (issecretvalue and issecretvalue(unitGUID)) then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    -- Update
    local targetName = UnitName(unitId)
    targetNameText:SetText((not (issecretvalue and issecretvalue(targetName)) and targetName) or "")

    local unitType, _, _, _, _, npcId = strsplit("-", unitGUID)
    if unitType ~= "Creature" then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    local npcData = GetDataByID('unitscanhardcorenpcs', npcId)
    if not npcData then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end
	
	if npcAbilitiesFrame:IsShown() and npcAbilitiesFrame.lastNpcId == npcId then
        targetNameText:SetText((not (issecretvalue and issecretvalue(targetName)) and targetName) or "")
        return
    end

    npcAbilitiesFrame.lastNpcId = npcId

    local abilitiesStr = BuildAbilitiesText(npcData)
    if abilitiesStr == "" then
        if npcAbilitiesFrame:IsShown() then
            AnimateFrameReverse(npcAbilitiesFrame, 0.5)
        end
        return
    end

    abilitiesText:SetText(abilitiesStr)
    abilitiesText:Show()

    -- frame size mathx
    local textHeight = abilitiesText:GetStringHeight() or 0
    local fullHeight = 40 + 20 + textHeight + 10 + (4 * 2) -- Add inset height

    -- placeholder
    abilitiesText:ClearAllPoints()
    abilitiesText:SetPoint("TOPLEFT", npcAbilitiesFrame, "TOPLEFT", 4 + 10, -60) -- ins

    AnimateFrame(npcAbilitiesFrame, fullHeight, 0.5)
end

npcAbilitiesFrame:SetPropagateKeyboardInput(true)

npcAbilitiesFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
npcAbilitiesFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
npcAbilitiesFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
npcAbilitiesFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
npcAbilitiesFrame:RegisterEvent("UNIT_AURA")

npcAbilitiesFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        if not UnitExists("target") then
            if self:IsShown() then
                AnimateFrameReverse(self, 0.5)
            end
        else
            UpdateNpcAbilitiesDisplay()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if self:IsShown() then
            AnimateFrameReverse(self, 0.5)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateNpcAbilitiesDisplay()
    elseif event == "UNIT_AURA" then
        local unit = ...
        -- buff change check
        if unit == "player" then
            UpdateNpcAbilitiesDisplay()
        end
    elseif event == "MODIFIER_STATE_CHANGED" then
        -- placeholder
    end
end)

local mobInfoTooltip = CreateFrame("Frame", "MobInfoTooltip", UIParent, "BackdropTemplate")
mobInfoTooltip:SetSize(200, 40)  -- 200 40
mobInfoTooltip:SetFrameStrata("TOOLTIP")
mobInfoTooltip:Hide()
mobInfoTooltip:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- default
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
mobInfoTooltip:SetBackdropColor(0, 0, 0, 1)
mobInfoTooltip:SetBackdropBorderColor(1, 1, 1, 1) -- Default

local mobInfoTooltipText = mobInfoTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mobInfoTooltipText:SetAllPoints()
mobInfoTooltipText:SetJustifyH("CENTER")
mobInfoTooltipText:SetJustifyV("MIDDLE")
mobInfoTooltipText:SetText("|cFF00FF00Drag me to move!\nTo disable type |cFFFF0000/hcscan|cFF00FF00 & click the green Mob Info Toggle|r")

local function ShowMobInfoTooltip()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale; y = y / scale;
    mobInfoTooltip:ClearAllPoints()
    mobInfoTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    mobInfoTooltip:SetAlpha(0)
    mobInfoTooltip:Show()
    mobInfoTooltip.fadeStart = GetTime()
    mobInfoTooltip:SetScript("OnUpdate", function(self, elapsed)
        local progress = (GetTime() - self.fadeStart) / 0.5
        if progress >= 1 then
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        else
            self:SetAlpha(progress)
        end
    end)
end

local function HideMobInfoTooltip()
    mobInfoTooltip:Hide()
    mobInfoTooltip:SetScript("OnUpdate", nil)
end

npcAbilitiesFrame:SetScript("OnEnter", function(self)
    self.mouseIsOver = true
    self.tooltipTimer = C_Timer.After(0.15, function()
        if self.mouseIsOver then
            ShowMobInfoTooltip()
        end
    end)
end)

npcAbilitiesFrame:SetScript("OnLeave", function(self)
    self.mouseIsOver = false
    if self.tooltipTimer then
        C_Timer.Cancel(self.tooltipTimer)
        self.tooltipTimer = nil
    end
    HideMobInfoTooltip()
end)