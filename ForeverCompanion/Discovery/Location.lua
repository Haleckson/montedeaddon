--[[
  Forever Companion - Discovery/Location.lua
  Where is the player? Snapshot capture for new discoveries, the last known
  outdoor position (dungeon entrances) and a slow position heartbeat used by
  the Discovery Fog reveal. The heartbeat runs every few seconds and only
  emits PLAYER_POSITION when the player actually moved.
]]

local _, FC = ...

local Location = FC:NewModule("Location")

local U = FC.Utils
local Compat = FC.Compat
local HEARTBEAT = 3

--- Returns a table suitable for Store:Create fields (m, x, y, z, sz) plus
--- instance data (inst, instName) when inside a dungeon or raid.
function Location:Capture()
    local zone, subzone = Compat.GetZoneTexts()
    local snapshot = { z = zone ~= "" and zone or nil, sz = subzone ~= "" and subzone or nil }
    local mapID, x, y = Compat.GetPlayerPosition()
    snapshot.m = mapID or Compat.GetPlayerMapID()
    if x and y then
        snapshot.x, snapshot.y = U.Round(x, 4), U.Round(y, 4)
    end
    if not snapshot.z and snapshot.m then
        snapshot.z = Compat.GetMapName(snapshot.m)
    end
    local instance = Compat.GetInstance()
    if instance then
        snapshot.inst = instance.instanceID
        snapshot.instName = instance.name
        snapshot.instType = instance.type
    end
    return snapshot
end

------------------------------------------------------------------------
-- Trail: recent positions, used to document the route to hidden places
------------------------------------------------------------------------

Location.trail = {}

function Location:AddTrailPoint(mapID, x, y)
    local trail = self.trail
    trail[#trail + 1] = { m = mapID, x = x, y = y, t = GetTime() }
    while #trail > FC.C.DISCOVERY.TRAIL_POINTS do table.remove(trail, 1) end
end

--- Packed points of the recent route on this map, oldest first, downsampled.
function Location:RecentRoute(mapID, maxPoints)
    local now = GetTime()
    local points = {}
    for _, p in ipairs(self.trail) do
        if p.m == mapID and now - p.t <= FC.C.DISCOVERY.TRAIL_SECONDS then
            points[#points + 1] = p
        elseif p.m ~= mapID then
            points = {} -- the route starts after the last map change
        end
    end
    maxPoints = maxPoints or FC.C.DISCOVERY.ROUTE_POINTS
    local out = {}
    if #points == 0 then return out end
    local step = math.max(1, #points / maxPoints)
    local i = 1
    while i <= #points and #out < maxPoints do
        local p = points[math.floor(i)]
        out[#out + 1] = U.PackPoint(p.x, p.y)
        i = i + step
    end
    return out
end

------------------------------------------------------------------------
-- Discoveries filed on a continent map (before 0.7.3)
------------------------------------------------------------------------

-- In some caves, and at a new character's first login, the game names the
-- continent as the player's map. What was recorded there moves, once, to the
-- zone map it lies in. A cave's entrance was a spot of the zone map outside,
-- so such a cave moves to the zone it was found in, or to where the explored
-- area of the same name is.

-- discoveries whose name is the place itself (a death spot's title is not)
local NAMED_PLACES = { cave = true, landmark = true }

local function zoneNamed(continentID, name)
    if type(name) ~= "string" or name == "" then return nil end
    for _, child in ipairs(Compat.GetZoneChildren(continentID)) do
        if Compat.Safe(child.name) == name then return Compat.Safe(child.mapID) end
    end
    return nil
end

-- Packed points of a continent map as points of a zone map; nil when one of
-- them lies outside that zone.
local function zonePoints(list, mapID, zoneID)
    local out = {}
    for i, packed in ipairs(list) do
        local x, y = U.UnpackPoint(packed)
        local inZone, zx, zy = Compat.ZonePosition(mapID, x, y)
        if inZone ~= zoneID then return nil end
        out[i] = U.PackPoint(zx, zy)
    end
    return out
end

function Location:RepairContinentRecords()
    local meta = FC.db.meta
    if meta.zoneRepair then return 0 end
    if not (C_Map and C_Map.GetMapInfoAtPosition and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos) then return 0 end
    local store = FC.Store
    local candidates, places = {}, {}
    for id, rec in store:Iterate() do
        local kind = Compat.GetMapType(rec.m)
        if kind and kind >= 1 and kind < Compat.ZONE_MAP_TYPE and type(rec.x) == "number" and type(rec.y) == "number" then
            -- caves keyed by the spot they were entered from took that spot from the map outside
            local entered = rec.t == "cave" and id:find("^u:cave:%d+:%d+%.%d+$") ~= nil
            local key = rec.m .. ":" .. U.NormalizeTitle(rec.n)
            if not entered and not places[key] then places[key] = { x = rec.x, y = rec.y } end
            if store:IsMine(rec) then candidates[#candidates + 1] = { id = id, rec = rec, entered = entered, key = key } end
        end
    end
    local moved = 0
    for _, item in ipairs(candidates) do
        local rec = item.rec
        local continent = Compat.GetMapName(rec.m)
        local zoneID, x, y = Compat.ZonePosition(rec.m, rec.x, rec.y)
        local zone = zoneID and Compat.GetMapName(zoneID)
        if item.entered and not (zoneID and (rec.z == nil or rec.z == zone or rec.z == continent)) then
            zoneID, x, y = zoneNamed(rec.m, rec.z), rec.x, rec.y
            local place = places[item.key]
            if not zoneID and place then zoneID, x, y = Compat.ZonePosition(rec.m, place.x, place.y) end
            zone = zoneID and Compat.GetMapName(zoneID)
        end
        local changes = zoneID and { m = zoneID, x = U.Round(x, 4), y = U.Round(y, 4) }
        if changes and (rec.z == nil or rec.z == continent) then changes.z = zone end
        if changes and rec.tr then changes.tr = zonePoints(rec.tr, rec.m, zoneID) or nil end
        if changes and rec.pts then changes.pts = zonePoints(rec.pts, rec.m, zoneID) or nil end
        if changes and (not rec.tr or changes.tr) and (not rec.pts or changes.pts) then
            -- a place already in the journal on that zone (found there later): one entry
            local same = NAMED_PLACES[rec.t] and FC.WorldDiscovery:FindNamed(zoneID, rec.t, rec.n)
            if same and same.id ~= item.id and FC.WorldDiscovery:IsUntouched(rec) then
                if store:MergeInto(item.id, same.id) then
                    FC.WorldDiscovery:ForgetRoute(item.id)
                    moved = moved + 1
                end
            elseif store:Update(item.id, changes, "repair", true) then
                moved = moved + 1
            end
        end
    end
    meta.zoneRepair = 1
    if moved > 0 then FC:Print(FC.L.MSG_ZONE_REPAIR, moved) end
    return moved
end

function Location:OnEnable()
    FC.Events:Register("ZONE_CHANGED_NEW_AREA", self, self.OnZoneChanged)
    FC.Events:Register("ZONE_CHANGED", self, self.OnZoneChanged)
    FC.Events:Register("ZONE_CHANGED_INDOORS", self, self.OnZoneChanged)
    -- before anything new is recorded where the old entries are looked up by name
    FC:SafeCall("Location:RepairContinentRecords", self.RepairContinentRecords, self)
    self.ticker = C_Timer.NewTicker(HEARTBEAT, function() FC:SafeCall("Location:Tick", self.Tick, self) end)
    self:OnZoneChanged()
end

function Location:OnZoneChanged()
    self:RememberOutdoor()
    FC.Bus:Emit("ZONE_UPDATED")
end

function Location:RememberOutdoor()
    if Compat.GetInstance() then return end
    local mapID, x, y = Compat.GetPlayerPosition()
    if mapID and x then
        local zone = Compat.GetZoneTexts()
        FC.cdb.lastOutdoor = { m = mapID, x = U.Round(x, 4), y = U.Round(y, 4), z = zone ~= "" and zone or Compat.GetMapName(mapID) }
    end
end

function Location:Tick()
    local mapID, x, y = Compat.GetPlayerPosition()
    if not mapID or not x then return end
    local last = self.last
    if last and last.m == mapID and math.abs(last.x - x) < 0.0015 and math.abs(last.y - y) < 0.0015 then
        return
    end
    self.last = { m = mapID, x = x, y = y }
    self:AddTrailPoint(mapID, x, y)
    if not Compat.GetInstance() then
        FC.cdb.lastOutdoor = FC.cdb.lastOutdoor or {}
        local outdoor = FC.cdb.lastOutdoor
        outdoor.m, outdoor.x, outdoor.y = mapID, U.Round(x, 4), U.Round(y, 4)
    end
    FC.Bus:Emit("PLAYER_POSITION", mapID, x, y)
end
