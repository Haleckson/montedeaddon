-- WW

local frame = CreateFrame("Frame")
local fallingStart = nil
local updateInterval = 0.7
local timeSinceLastUpdate = 0
local waterWalkingSpellID = 546

local UnitBuff = UnitBuff or function(unit, index)
    local aura = C_UnitAuras and (C_UnitAuras.GetBuffDataByIndex and C_UnitAuras.GetBuffDataByIndex(unit, index) or C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL"))
    if aura then
        return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    local faction = UnitFactionGroup("player")
    if faction ~= "Horde" or select(2, UnitClass("player")) == "SHAMAN" then
        --print("Alliance")
        return
    end

    -- update
    self:SetScript("OnUpdate", function(self, elapsed)
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        if timeSinceLastUpdate < updateInterval then
            return
        end
        timeSinceLastUpdate = 0

        if not IsFalling() then
            fallingStart = nil
            return
        end

        if IsFalling() and not fallingStart then
            fallingStart = GetTime()
            return
        end

        if fallingStart and (GetTime() - fallingStart) > 1.8 then
            for i = 1, 40 do
                local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)
                if spellId == waterWalkingSpellID then
                    print("|cffFFFF00|| |cffFF0000Unitscan Hardcore|r |cffFFFF00|||r |cff00FF00Water-Walk Buff Grief detected, auto cancelling Buff now|r")
                    CancelUnitBuff("player", i)
                    break
                end
            end
        end
    end)
end)
