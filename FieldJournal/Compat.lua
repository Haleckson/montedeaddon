local _, FieldJournal = ...

FieldJournal.Compat = FieldJournal.Compat or {}
local Compat = FieldJournal.Compat

local interface = select(4, GetBuildInfo())
-- The beta's TOC is 16001; keep the event gate on later 16xxx beta builds.
Compat.isForever = tonumber(interface) and tonumber(interface) >= 16000 and tonumber(interface) < 17000

function Compat:IsSafe(value, expectedType)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return false end
    return not expectedType or type(value) == expectedType
end

function Compat:UnitValue(api, unit, expectedType)
    if not api then return nil end
    local ok, value = pcall(api, unit)
    if ok and self:IsSafe(value, expectedType) then return value end
    return nil
end

function Compat:UnitGUID(unit)
    return self:UnitValue(_G.UnitGUID, unit, "string")
end

function Compat:UnitName(unit)
    return self:UnitValue(_G.UnitName, unit, "string")
end

function Compat:UnitFlag(api, unit)
    return self:UnitValue(api, unit, "boolean")
end

function Compat:CanAttack(unit)
    if not UnitCanAttack then return nil end
    local ok, value = pcall(UnitCanAttack, "player", unit)
    if ok and self:IsSafe(value, "boolean") then return value end
    return nil
end

function Compat:GetNPCID(guid)
    if not self:IsSafe(guid, "string") then return nil end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

function Compat:Debug(message)
    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[Field Journal]|r " .. message)
    end
end
