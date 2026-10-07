--[[
  Forever Companion - Discovery/NearbyDiscovery.lua
  Rares and treasure the game marks on the minimap (vignettes): recorded as
  soon as they appear, without targeting them, and announced with a
  "nearby" toast (and optionally a taskbar flash) even when the journal
  already knows them, so a respawned rare is not missed.

  Only active on clients that have vignettes; everything is feature-detected.
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local Categories = FC.Categories

local Nearby = { announced = {} }
FC.NearbyDiscovery = Nearby

local ANNOUNCE_AGAIN = 600 -- the same vignette is announced again after ten minutes

--- What a mark on the minimap stands for: "rare", "treasure" or nil. The
--- game marks more than rares and chests this way (events, quest spots,
--- services), and names the kind in the mark's picture: a skull star for
--- something to kill, a chest for loot. A creature whose mark says neither
--- is a rare only when the reference data knows it as one; without any
--- picture name, a creature counts as a rare and an object as treasure.
function Nearby.KindOf(guidType, id, vignetteType, atlas)
    local creature = guidType == "Creature" or guidType == "Vehicle"
    local types = Enum and Enum.VignetteType
    if types and types.Treasure and vignetteType == types.Treasure then return "treasure" end
    if type(atlas) == "string" and atlas ~= "" then
        local name = atlas:lower()
        if name:find("loot", 1, true) or name:find("treasure", 1, true) or name:find("chest", 1, true) then return "treasure" end
        if creature and (name:find("kill", 1, true) or name:find("rare", 1, true) or name:find("boss", 1, true)) then return "rare" end
        if creature and FC.Reference and (FC.Reference:Is(id, "r") or FC.Reference:Is(id, "w")) then return "rare" end
        return nil
    end
    if guidType == "GameObject" then return "treasure" end
    if creature then return "rare" end
    return nil
end

--- A vignette as a plain table: name, what it is ("rare" or "treasure"), its
--- NPC or object ID, whether it is dead, and where it is.
function Compat.GetVignette(guid)
    local V = _G.C_VignetteInfo
    if not (V and V.GetVignetteInfo) then return nil end
    local ok, info = pcall(V.GetVignetteInfo, guid)
    if not ok or type(info) ~= "table" then return nil end
    local name = Compat.Safe(info.name)
    local objectGUID = Compat.Safe(info.objectGUID)
    if type(name) ~= "string" or name == "" then return nil end
    local guidType, id = Compat.ParseGUID(objectGUID)
    local kind = Nearby.KindOf(guidType, id, Compat.Safe(info.type), Compat.Safe(info.atlasName))
    if not kind then return nil end
    local vignette = { guid = guid, name = name, kind = kind, id = id, dead = Compat.Safe(info.isDead) and true or false }
    local mapID = Compat.GetPlayerMapID()
    if mapID and V.GetVignettePosition then
        local okPos, pos = pcall(V.GetVignettePosition, guid, mapID)
        if okPos and type(pos) == "table" and pos.GetXY then
            local x, y = pos:GetXY()
            x, y = Compat.Safe(x), Compat.Safe(y)
            if type(x) == "number" and type(y) == "number" and x > 0 and y > 0 then
                vignette.m, vignette.x, vignette.y = mapID, U.Round(x, 4), U.Round(y, 4)
            end
        end
    end
    return vignette
end

--- Records the vignette in the journal; returns its record.
function Nearby:Record(v)
    local base = Engine:LocationFields()
    local fields = { m = v.m or base.m, x = v.x or base.x, y = v.y or base.y, z = base.z, sz = base.sz, n = v.name }
    if v.kind == "rare" then
        if not v.id then return nil end
        fields.t, fields.npc = "rare", v.id
        fields.ic = Categories:Get("rare").icon
        return Engine:Record(fields, { deferInCombat = false })
    end
    if not FC.Config:Get("discovery.objects") then return nil end
    fields.t = "treasure"
    fields.ic = Categories:Get("treasure").icon
    local id = Engine:ObjectId("u:obj:" .. (v.id or 0) .. ":" .. (fields.m or 0) .. ":", fields.m, fields.x, fields.y)
    return Engine:Record(fields, { id = id, deferInCombat = false })
end

function Nearby:OnVignette(guid, onMinimap)
    guid = Compat.Safe(guid)
    if type(guid) ~= "string" or Compat.Safe(onMinimap) == false then return end
    local v = Compat.GetVignette(guid)
    if not v or v.dead then return end
    local rec, isNew, announced = self:Record(v)
    local now = GetTime()
    local last = self.announced[guid]
    if last and now - last < ANNOUNCE_AGAIN then return end
    self.announced[guid] = now
    -- a first find has its "new discovery" toast already (so has one this
    -- character just came across for the first time)
    if isNew or announced then return end
    FC.Bus:Emit("NEARBY_FOUND", rec or { t = v.kind, n = v.name, id = "vignette:" .. guid, m = v.m, x = v.x, y = v.y }, v.kind)
end

Engine:RegisterDetector("nearby", {
    setting = "discovery.rares",
    events = {
        VIGNETTE_MINIMAP_UPDATED = function(_, _, guid, onMinimap) Nearby:OnVignette(guid, onMinimap) end,
        VIGNETTES_UPDATED = function()
            local V = _G.C_VignetteInfo
            if not (V and V.GetVignettes) then return end
            local ok, list = pcall(V.GetVignettes)
            if not ok or type(list) ~= "table" then return end
            for _, guid in ipairs(list) do Nearby:OnVignette(guid, true) end
        end,
    },
})
