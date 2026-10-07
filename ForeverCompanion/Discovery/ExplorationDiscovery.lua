--[[
  Forever Companion - Discovery/ExplorationDiscovery.lua
  Discovery Fog reveal: with "veil" on, guild discoveries stay rumored until
  the player gets close to them. The position heartbeat checks only records
  on the current map (indexed), so the cost does not grow with the database.
  Explored areas are recorded by WorldDiscovery from the game's own message.
]]

local _, FC = ...

local Compat = FC.Compat
local U = FC.Utils
local C = FC.C

local Exploration = {}
FC.ExplorationDiscovery = Exploration

function Exploration:OnPosition(mapID, x, y)
    if not FC.Config:Get("knowledge.veil") then return end
    local width, height = Compat.GetMapWorldSize(mapID)
    local radius = width and C.DISCOVERY.VEIL_RADIUS_YARDS or C.DISCOVERY.VEIL_RADIUS_NORMALIZED
    for _, rec in ipairs(FC.Store:ForMap(mapID)) do
        if rec.x and FC.Store:IsRumored(rec) then
            local distance = U.MapDistance(x, y, rec.x, rec.y, width, height)
            if distance <= radius then
                FC.Store:MarkSeen(rec.id)
                FC.Bus:Emit("DISCOVERY_REVEALED", rec)
            end
        end
    end
end

FC.Bus:On("PLAYER_POSITION", Exploration, function(self, mapID, x, y)
    self:OnPosition(mapID, x, y)
end)
