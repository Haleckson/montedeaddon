--[[
  Forever Companion - Discovery/DiscoveryEngine.lua
  Turns game events into discoveries.

  Detectors (NPC, vendor, quest, loot, dungeon, exploration) register here with
  the events they need and the setting that enables them. The engine only
  registers a game event while at least one enabled detector wants it, so
  disabling "Detect vendors" really removes the MERCHANT_SHOW listener.

  All automatic discoveries go through Engine:Record, which provides:
    * a per-id cooldown (target spam never floods the store)
    * combat deferral (queued, flushed on PLAYER_REGEN_ENABLED)
    * independent-encounter handling: finding something a guild member already
      documented marks it personally discovered and adds a verification
]]

local _, FC = ...

local Engine = FC:NewModule("DiscoveryEngine")

local U = FC.Utils
local C = FC.C
local Compat = FC.Compat

Engine.detectors = {}
Engine.recent = {}
Engine.recentCount = 0
Engine.queue = {}
Engine.queued = {}

--- def = { setting = "discovery.vendors" | function() return bool end,
---         events = { EVENT_NAME = function(detector, event, ...) end },
---         OnEnable = optional function(detector) }
function Engine:RegisterDetector(name, def)
    def.name = name
    self.detectors[name] = def
    return def
end

local function detectorEnabled(def)
    if type(def.setting) == "function" then return def.setting() end
    if type(def.setting) == "string" then return FC.Config:Get(def.setting) == true end
    return true
end

function Engine:OnEnable()
    for _, def in pairs(self.detectors) do
        if def.OnEnable then FC:SafeCall(def.name .. ":OnEnable", def.OnEnable, def) end
    end
    self:Refresh()
    FC.Events:Register("PLAYER_REGEN_ENABLED", self, self.FlushQueue)
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^discovery") then self:Refresh() end
    end)
end

--- (Re)registers detector events according to the current settings.
function Engine:Refresh()
    for _, def in pairs(self.detectors) do
        local enabled = detectorEnabled(def)
        for event, handler in pairs(def.events or {}) do
            if enabled then
                FC.Events:Register(event, def, function(_, ev, ...) handler(def, ev, ...) end)
            else
                FC.Events:Unregister(event, def)
            end
        end
        def.active = enabled
    end
end

local function pruneRecent(self, now)
    if self.recentCount < 300 then return end
    local count = 0
    for id, ts in pairs(self.recent) do
        if now - ts > C.DISCOVERY.RECORD_COOLDOWN then
            self.recent[id] = nil
        else
            count = count + 1
        end
    end
    self.recentCount = count
end

--- Records an automatic discovery. Returns rec, isNew, announced (a toast
--- went out: a new find, or one this character had not come across).
--- opts: id (explicit id), force (skip cooldown), onExisting(rec) callback,
---       deferInCombat (default true)
function Engine:Record(fields, opts)
    opts = opts or {}
    local store = FC.Store
    if opts.deferInCombat ~= false and Compat.InCombat() then
        -- each thing once: a creature seen all through a fight takes one place, not fifty
        local id = opts.id or store:MakeId(fields)
        if not self.queued[id] and #self.queue < C.DISCOVERY.COMBAT_QUEUE then
            self.queued[id] = true
            opts.id = id
            self.queue[#self.queue + 1] = { fields = fields, opts = opts }
        end
        return nil, false, false
    end
    local id = opts.id or store:MakeId(fields)
    local now = U.Now()
    if not opts.force and self.recent[id] and now - self.recent[id] < C.DISCOVERY.RECORD_COOLDOWN then
        local cached = store:Get(id)
        if cached and opts.onExisting then FC:SafeCall("onExisting", opts.onExisting, cached) end
        return cached, false, false
    end
    if not self.recent[id] then self.recentCount = self.recentCount + 1 end
    self.recent[id] = now
    pruneRecent(self, now)

    if not store:Get(id) then FC.AutoText:Enrich(fields) end
    local rec, isNew = store:Create(fields, { id = id, source = "auto", personal = true })
    if not rec then return nil, false, false end
    if not isNew then
        -- counts for the character you play; the toast depends on the progress mode
        local _, _, announced = store:Encounter(rec, now)
        if opts.onExisting then FC:SafeCall("onExisting", opts.onExisting, rec) end
        return rec, false, announced
    end
    return rec, true, true
end

function Engine:FlushQueue()
    if #self.queue == 0 then return end
    local pending = self.queue
    self.queue, self.queued = {}, {}
    for _, item in ipairs(pending) do
        item.opts.deferInCombat = false
        self:Record(item.fields, item.opts)
    end
end

--- The id of a world object found at a place: the entry already filed for
--- that object within a stone's throw (the same chest, looted from the
--- other side; the mark on the minimap and the chest itself), else a new
--- one keyed by the place. prefix: everything of the id before the place.
function Engine:ObjectId(prefix, mapID, x, y)
    if mapID and x and y then
        local near = C.DISCOVERY.OBJECT_NEAR
        for _, rec in ipairs(FC.Store:ForMap(mapID)) do
            if rec.x and rec.y and type(rec.id) == "string" and rec.id:sub(1, #prefix) == prefix
                and math.abs(rec.x - x) <= near and math.abs(rec.y - y) <= near then
                return rec.id
            end
        end
    end
    return prefix .. U.GridKey(x, y, C.DISCOVERY.OBJECT_GRID)
end

--- Context for quick capture: location, target, time and a suggested type.
function Engine:GetCaptureContext()
    local loc = FC.Location:Capture()
    local target = Compat.GetUnitInfo("target")
    if target and target.isPlayer then target = nil end
    local suggested = "note"
    if target and target.npcID then
        local cls = target.classification
        if cls == "rare" or cls == "rareelite" then
            suggested = "rare"
        else
            suggested = "npc"
        end
    elseif loc.inst then
        suggested = "mechanic"
    end
    return { loc = loc, target = target, time = U.Now(), suggested = suggested }
end

--- Id of the dungeon discovery for the current instance, if any.
function Engine:CurrentDungeonID()
    local instance = Compat.GetInstance()
    if instance and instance.instanceID then
        return "dungeon:" .. instance.instanceID, instance
    end
    return nil
end

--- Common location fields for detectors.
function Engine:LocationFields()
    local loc = FC.Location:Capture()
    local fields = { m = loc.m, x = loc.x, y = loc.y, z = loc.z, sz = loc.sz }
    if loc.inst then
        fields["in"] = loc.inst
        fields.inn = loc.instName
        fields.pa = "dungeon:" .. loc.inst
    end
    return fields
end
