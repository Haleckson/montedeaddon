--[[
  Forever Companion - Map/Waypoints.lua
  "Show on map" and "Create waypoint". Uses the client's native user
  waypoint + super tracking when available; TomTom is used only when it is
  installed and preferred in settings. No addon is a hard dependency.
]]

local _, FC = ...

local Waypoints = FC:NewModule("Waypoints")

local L = FC.L
local Compat = FC.Compat
local U = FC.Utils

local function tomtom()
    local tt = _G.TomTom
    if tt and type(tt.AddWaypoint) == "function" then return tt end
    return nil
end

function Waypoints:HasTomTom()
    return tomtom() ~= nil
end

function Waypoints:Set(rec)
    if not rec or not rec.m or not rec.x then
        FC:Print(L.MSG_NO_COORDS)
        return false
    end
    local title = rec.n or "Forever Companion"
    local tt = tomtom()
    if tt and (FC.P.map.preferTomTom or not Compat.CanSetUserWaypoint(rec.m)) then
        local ok = pcall(tt.AddWaypoint, tt, rec.m, rec.x, rec.y, { title = title, from = "Forever Companion", persistent = false })
        if ok then
            FC:Print(L.MSG_WAYPOINT_SET, U.Escape(title), U.FormatCoords(rec.x, rec.y))
            return true
        end
    end
    if Compat.SetUserWaypoint(rec.m, rec.x, rec.y) then
        FC:Print(L.MSG_WAYPOINT_SET, U.Escape(title), U.FormatCoords(rec.x, rec.y))
        return true
    end
    FC:Print(L.MSG_WAYPOINT_UNAVAILABLE)
    return false
end

function Waypoints:ShowOnMap(rec)
    if not rec or not rec.m then
        FC:Print(L.MSG_NO_COORDS)
        return
    end
    Compat.OpenWorldMap(rec.m)
    if FC.MapIntegration then FC.MapIntegration:Highlight(rec.id) end
end
