local ADDON_NAME, FieldJournal = ...

FieldJournal = FieldJournal or {}
FieldJournal.ZoneSystem = FieldJournal.ZoneSystem or {}

local ZS = FieldJournal.ZoneSystem

ZS.initialized = false

local function GetCurrentZone()
    return GetRealZoneText() or "Unknown Zone"
end

local function GetCurrentSubzone()
    local zoneName = GetCurrentZone()
    local subzoneName = GetSubZoneText()

    if not subzoneName or subzoneName == "" then
        return nil
    end

    if subzoneName == zoneName then
        return nil
    end

    return subzoneName
end

function ZS:Init()
    if self.initialized then
        return
    end

    self.initialized = true
    self:RecordCurrentSubregion()

    if FieldJournal.Config and FieldJournal.Config.debug then
        print("|cff33ff99[FieldJournal]|r ZoneSystem initialized.")
    end
end

function ZS:GetZoneDefinition(zoneName)
    if not zoneName then return nil end
    return FieldJournal_ZoneDB and FieldJournal_ZoneDB[zoneName]
end

function ZS:GetDefinedSubregions(zoneName)
    local zoneDef = self:GetZoneDefinition(zoneName)
    if not zoneDef or not zoneDef.subregions then
        return {}
    end

    return zoneDef.subregions
end

function ZS:IsDefinedSubregion(zoneName, subregionName)
    if not zoneName or not subregionName then
        return false
    end

    local subregions = self:GetDefinedSubregions(zoneName)

    for _, data in ipairs(subregions) do
        if data.name == subregionName then
            return true
        end
    end

    return false
end

function ZS:GetSubregionDescription(zoneName, subregionName)
    if not zoneName or not subregionName then
        return nil
    end

    local subregions = self:GetDefinedSubregions(zoneName)

    for _, data in ipairs(subregions) do
        if data.name == subregionName then
            return data.description
        end
    end

    return nil
end

function ZS:GetOrCreateZone(zoneName)
    if not zoneName then return nil end

    FieldJournalDB.zones = FieldJournalDB.zones or {}

    local zone = FieldJournalDB.zones[zoneName]

    if not zone then
        if FieldJournal.DataManager and FieldJournal.DataManager.GetZone then
            zone = FieldJournal.DataManager:GetZone(zoneName, zoneName)
        else
            FieldJournalDB.zones[zoneName] = {
                zoneID = zoneName,
                name = zoneName,
                encounteredSubjects = {},
                encounteredNPCs = {},
                totalKills = 0,
                totalObservations = 0,
                uniqueCreatures = {},
            }

            zone = FieldJournalDB.zones[zoneName]
        end
    end

    zone.discoveredSubregions = zone.discoveredSubregions or {}

    return zone
end

function ZS:RecordSubregion(zoneName, subregionName)
    if not zoneName or not subregionName then
        return false
    end

    if not self:IsDefinedSubregion(zoneName, subregionName) then
        return false
    end

    local zone = self:GetOrCreateZone(zoneName)
    if not zone then
        return false
    end

    zone.discoveredSubregions = zone.discoveredSubregions or {}

    if zone.discoveredSubregions[subregionName] then
        return false
    end

    zone.discoveredSubregions[subregionName] = {
        discoveredAt = date("%Y-%m-%d %H:%M:%S"),
    }

    print("|cff33ff99[Field Journal]|r Subregion discovered: " .. subregionName)

    if FieldJournal.ChronicleSystem and FieldJournal.ChronicleSystem.RecordSubregionDiscovery then
        FieldJournal.ChronicleSystem:RecordSubregionDiscovery(zoneName, subregionName)
    end

    return true
end

function ZS:RecordCurrentSubregion()
    local zoneName = GetCurrentZone()
    local subregionName = GetCurrentSubzone()

    if not zoneName or not subregionName then
        return false
    end

    return self:RecordSubregion(zoneName, subregionName)
end

function ZS:OnZoneChanged()
    self:RecordCurrentSubregion()
end