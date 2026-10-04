local _, GQ = ...

GQ.Map = GQ.Map or {}

local PREFIX = "|cff66ccffGearQuest|r: "
local zoneCache = {}

local KIND_FOR = {
    quest_reward = "q",
    seasonal_quest = "q",
    boss_drop = "b",
    profession = "p",
    vendor = "v",
}

local function FindMapId(zoneName)
    if not zoneName or zoneName == "" then
        return nil
    end
    if zoneCache[zoneName] ~= nil then
        return zoneCache[zoneName] or nil
    end
    local found = false
    if C_Map and C_Map.GetMapInfo then
        for id = 1, 3000 do
            local info = C_Map.GetMapInfo(id)
            if info and info.name == zoneName then
                found = id
                break
            end
        end
    end
    zoneCache[zoneName] = found
    return found or nil
end

function GQ.Map:ZoneMap(zoneName)
    return FindMapId(zoneName)
end

function GQ.Map:KindFor(entry)
    return KIND_FOR[entry and entry.sourceType] or "w"
end

-- Faction-matching coordinate, before the zone name is turned into a map id.
function GQ.Map:DisplaySpot(entry)
    if not entry or not entry.itemId or not GQ.Data or not GQ.Data.coordinates then
        return nil
    end
    local row = GQ.Data.coordinates[entry.itemId]
    if not row or not row.spots or #row.spots == 0 then
        return nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or nil
    local openWorld = row.note == "where this rare spawns" or row.note == "a farming spot"
    for i = 1, #row.spots do
        local spot = row.spots[i]
        if spot.x and spot.y and GQ.Data:SpotVisible(spot, faction, openWorld) then
            return spot
        end
    end
    return nil
end

function GQ.Map:HasSpot(entry)
    return self:DisplaySpot(entry) ~= nil
end

-- The same spot the coordinate line shows for this faction. One pin.
function GQ.Map:SpotForEntry(entry)
    local spot = self:DisplaySpot(entry)
    if not spot then
        return nil
    end
    local mapId = spot.mapId or self:ZoneMap(spot.map)
    if not mapId then
        return nil
    end
    return {
        mapId = mapId,
        x = spot.x,
        y = spot.y,
        map = spot.map,
        kind = self:KindFor(entry),
        entry = entry,
    }
end

local function SetPin(mapId, x, y, label)
    x, y = x / 100, y / 100
    if TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(mapId, x, y, { title = "GearQuest: " .. label })
        return true
    end
    if C_Map.SetUserWaypoint and UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapId) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        return true
    end
    return false
end

function GQ.Map:Show(entry)
    if not entry then
        return
    end
    local spot = self:SpotForEntry(entry)
    local mapId = spot and spot.mapId or self:ZoneMap(entry.zone)
    local label = entry.questName or entry.npc or entry.zone or "GearQuest"

    if WorldMapFrame then
        if not WorldMapFrame:IsShown() then
            ShowUIPanel(WorldMapFrame)
        end
        if mapId then
            WorldMapFrame:SetMapID(mapId)
            C_Timer.After(0, function()
                if WorldMapFrame and WorldMapFrame:IsShown() and mapId then
                    WorldMapFrame:SetMapID(mapId)
                end
            end)
        end
    elseif OpenWorldMap and mapId then
        OpenWorldMap(mapId)
    end

    if not spot then
        print(PREFIX .. "No exact spot for this item.")
        return
    end

    local pinned = SetPin(spot.mapId, spot.x, spot.y, label)
    local where = string.format("%s %.1f, %.1f", spot.map or label, spot.x, spot.y)
    print(PREFIX .. where .. (pinned and " — pin placed" or ""))
end
