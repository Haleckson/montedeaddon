--[[
  Forever Companion - Discovery/WorldDiscovery.lua
  The world itself, documented without player input:

    explored areas   the game's own "Discovered: <area>" message
    dungeon areas    named areas you walk into inside an instance
    caves            the game naming a mine or cave you reach, or a long indoor
                     stretch outside towns (enter, then move deep inside)
    routes           the path you walked to reach a cave, a treasure or a secret
    death spots      where you died and to what (private by default)
    readables        books, plaques and notes in the world
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local L = FC.L
local C = FC.C
local Categories = FC.Categories

local World = {}
FC.WorldDiscovery = World

local D = C.DISCOVERY

local function positionNow()
    local mapID, x, y = Compat.GetPlayerPosition()
    if mapID and x then return mapID, U.Round(x, 4), U.Round(y, 4) end
    return nil
end

------------------------------------------------------------------------
-- Routes
------------------------------------------------------------------------

--- Documents the route that led to a hidden place as a "path" discovery.
function World:RecordRoute(target, route)
    if not FC.Config:Get("discovery.routes") or not target or not target.m then return end
    route = route or FC.Location:RecentRoute(target.m, D.ROUTE_POINTS)
    if #route < 3 then return end
    local startX, startY = U.UnpackPoint(route[1])
    local zone, subzone = Compat.GetZoneTexts()
    Engine:Record({
        t = "path",
        n = string.format(L.AUTO_ROUTE_TITLE, target.n or "?"),
        d = string.format(L.AUTO_ROUTE, #route, target.n or "?"),
        m = target.m, x = startX, y = startY,
        z = target.z or zone, sz = subzone ~= "" and subzone or nil,
        tr = route,
        pa = target.id,
        tg = { "route" },
        ic = Categories:Get("path").icon,
    }, { id = "path:" .. target.id })
end

--- An entry of yours that you never edited, starred, noted or tagged.
function World:IsUntouched(rec)
    local store = FC.Store
    if not rec or rec.del or not store:IsMine(rec) or (tonumber(rec.r) or 1) > 1 then return false end
    local state = store:GetState(rec.id)
    return not (state and (state.fav or state.note or state.tags))
end

--- Takes back the route to a discovery that was taken back itself: yours
--- if untouched; a guild member's is hidden.
function World:ForgetRoute(targetID)
    local store = FC.Store
    local id = "path:" .. tostring(targetID)
    local rec = store:Get(id)
    if not rec then return false end
    if not store:IsMine(rec) then return store:DeletePersonal(id) ~= nil end
    return self:IsUntouched(rec) and store:Withdraw(id)
end

------------------------------------------------------------------------
-- Explored areas and dungeon areas
------------------------------------------------------------------------

local exploredPatterns

local function areaFromMessage(message)
    if type(message) ~= "string" then return nil end
    exploredPatterns = exploredPatterns or {
        Compat.PatternFromGlobal("ERR_ZONE_EXPLORED"),
        Compat.PatternFromGlobal("ERR_ZONE_EXPLORED_XP"),
    }
    for _, pattern in ipairs(exploredPatterns) do
        local area = pattern and message:match(pattern)
        if area then return area end
    end
    return nil
end

function World:OnExplored(area)
    local fields = Engine:LocationFields()
    local instance = Compat.GetInstance()
    -- a mine or a cave is a cave, announced as one, not a quiet explored area
    if not instance and fields.m and FC.Config:Get("discovery.caves") and self:LooksLikeCave(area) then
        self:RecordCave(fields.m, fields.x, fields.y, area)
        return
    end
    fields.n = area
    if instance then
        fields.t = "room"
    else
        fields.t = "landmark"
        fields.sz = area
    end
    fields.ic = Categories:Get(fields.t).icon
    -- the same area under the same name is one entry, however it was keyed
    -- (moved here from a continent map, or found by a guild member)
    local existing = self:FindNamed(fields.m, fields.t, area)
    local key = (fields.m or 0) .. ":" .. U.NormalizeTitle(area)
    Engine:Record(fields, { id = existing and existing.id or ("u:landmark:" .. key) })
end

Engine:RegisterDetector("explored", {
    setting = "discovery.explored",
    events = {
        UI_INFO_MESSAGE = function(_, _, _, message)
            local area = areaFromMessage(Compat.Safe(message))
            if area then World:OnExplored(area) end
        end,
        CHAT_MSG_SYSTEM = function(_, _, message)
            local area = areaFromMessage(Compat.Safe(message))
            if area then World:OnExplored(area) end
        end,
    },
})

local function onInstanceArea()
    local instance = Compat.GetInstance()
    if not instance or not instance.instanceID then return end
    local zone, subzone = Compat.GetZoneTexts()
    if subzone == "" or subzone == zone or subzone == instance.name then return end
    local fields = Engine:LocationFields()
    fields.t = "room"
    fields.n = subzone
    fields.ic = Categories:Get("room").icon
    Engine:Record(fields, { id = "room:" .. instance.instanceID .. ":" .. U.NormalizeTitle(subzone) })
end

Engine:RegisterDetector("dungeon-areas", {
    setting = "discovery.dungeonAreas",
    events = {
        ZONE_CHANGED = onInstanceArea,
        ZONE_CHANGED_INDOORS = onInstanceArea,
    },
})

------------------------------------------------------------------------
-- Caves
------------------------------------------------------------------------

-- Whether a name has one of the words of a comma separated list, as a whole word.
local function hasWord(name, list)
    if type(name) ~= "string" then return false end
    local padded = " " .. name:lower():gsub("[%p%s]+", " ") .. " "
    for _, word in ipairs(U.Split(list, ",")) do
        if padded:find(" " .. word:lower() .. " ", 1, true) then return true end
    end
    return false
end

--- A building's name (Main Hall, Northshire Abbey, Tower ...), not a cave's.
function World:IsBuildingName(name)
    return hasWord(name, L.BUILDING_WORDS) and not hasWord(name, L.CAVE_WORDS)
end

--- An explored area that is a cave: its name says so (Mine, Cave, Cavern ...),
--- or you are indoors when the game names it (outside towns and inns) and
--- the name is not a building's.
function World:LooksLikeCave(area)
    if hasWord(area, L.CAVE_WORDS) then return true end
    if hasWord(area, L.BUILDING_WORDS) or hasWord(area, L.SETTLEMENT_WORDS) then return false end
    -- indoors, and walked there: below deck on a ship that reaches a harbor,
    -- or in a zeppelin's cabin, the game names the place too
    if Compat.IsTraveling() or Compat.IsMovingOnFoot() == false then return false end
    return Compat.IsIndoors() and not Compat.IsResting()
end

--- The discovery of this type already on this map under this name, if any.
function World:FindNamed(mapID, typeKey, name)
    local key = U.NormalizeTitle(name)
    if not mapID or key == "" then return nil end
    for _, rec in ipairs(FC.Store:ForMap(mapID)) do
        if rec.t == typeKey and U.NormalizeTitle(rec.n) == key then return rec end
    end
    return nil
end

--- The cave already on this map under this name, if any (older entries were
--- keyed by the spot they were entered from).
function World:FindCave(mapID, name)
    return self:FindNamed(mapID, "cave", name)
end

--- Records a cave, and the route that led to it. A named cave has a single
--- entry however it is found: the game naming it at the mouth, or a long
--- walk inside.
function World:RecordCave(mapID, x, y, name, route)
    local zone, subzone = Compat.GetZoneTexts()
    local existing = name and self:FindCave(mapID, name)
    local id = existing and existing.id
        or (name and ("u:cave:" .. mapID .. ":" .. U.NormalizeTitle(name)))
        or ("u:cave:" .. mapID .. ":" .. U.GridKey(x, y, D.OBJECT_GRID))
    local rec = Engine:Record({
        t = "cave", n = name or string.format(L.AUTO_CAVE_TITLE, zone ~= "" and zone or "?"),
        m = mapID, x = x, y = y,
        z = zone ~= "" and zone or nil, sz = subzone ~= "" and subzone or nil,
        ic = Categories:Get("cave").icon,
    }, { id = id })
    if rec then self:RecordRoute(rec, route) end
    return rec
end

function World:CaveCheck()
    local indoors = Compat.IsIndoors()
    if not indoors or Compat.GetInstance() or Compat.IsResting() or Compat.IsTraveling() then
        if not indoors then
            self.lastOutdoorPoint = { positionNow() }
            self.cave = nil
        end
        return
    end
    local mapID, x, y = positionNow()
    if not mapID then return end
    local cave = self.cave
    if not cave or cave.m ~= mapID then
        -- the entrance is the last spot outside, when it lies on the same map
        -- (a point of another map would land somewhere else entirely)
        local entry = self.lastOutdoorPoint
        if entry and entry[1] ~= mapID then entry = nil end
        cave = { m = mapID, x = entry and entry[2] or x, y = entry and entry[3] or y, lastX = x, lastY = y, since = GetTime(), far = 0, route = FC.Location:RecentRoute(mapID) }
        self.cave = cave
        return
    end
    if cave.done then return end
    -- carried along while standing still (below deck on a ship, in a
    -- zeppelin's cabin): the entrance moves with the player, so only the
    -- player's own steps take them "deep inside"
    if Compat.IsMovingOnFoot() == false then
        cave.x, cave.y = cave.x + (x - cave.lastX), cave.y + (y - cave.lastY)
    end
    cave.lastX, cave.lastY = x, y
    cave.far = math.max(cave.far, U.MapDistance(cave.x, cave.y, x, y))
    if GetTime() - cave.since >= D.CAVE_MIN_SECONDS and cave.far >= D.CAVE_MIN_DISTANCE then
        cave.done = true
        local zone, subzone = Compat.GetZoneTexts()
        local name = (subzone ~= "" and subzone ~= zone) and subzone or nil
        if name and self:IsBuildingName(name) then return end -- a long walk through a hall or an abbey
        self:RecordCave(mapID, cave.x, cave.y, name, cave.route)
    end
end

FC.Bus:On("PLAYER_POSITION", World, function(self)
    if FC.Config:Get("discovery.caves") then FC:SafeCall("World:CaveCheck", self.CaveCheck, self) end
end)

Engine:RegisterDetector("caves", {
    setting = "discovery.caves",
    events = {
        ZONE_CHANGED_INDOORS = function() World:CaveCheck() end,
    },
})

------------------------------------------------------------------------
-- Explored areas the game still remembers
------------------------------------------------------------------------

-- A character explores with or without the journal, and the game keeps
-- which areas of every zone map are uncovered. They are read once per
-- character (and again with /fc rescan), a zone map per tick, and filed
-- like the areas found while the journal watches, marked as recovered
-- (rcv): the journal then knows the area and its place on the map, not when
-- it was explored. They are private, make no toast and are not "new".
-- Nothing else of a character's past can be read back: the creatures it
-- met, vendors, chests, routes and the rares it defeated are known only
-- from the moment the journal watches.
local RECOVERY_VERSION = 1
local RECOVERY_TICK = 0.2   -- seconds between two zone maps
local RECOVERY_LIMIT = 2000 -- areas filed in one pass at most

--- The zone maps to read: the reference data's zones and the one you are in.
function World:ExploredMaps()
    local maps, seen = {}, {}
    local function add(mapID)
        if type(mapID) == "number" and not seen[mapID] and Compat.GetMapType(mapID) == Compat.ZONE_MAP_TYPE then
            seen[mapID] = true
            maps[#maps + 1] = mapID
        end
    end
    add(Compat.GetPlayerMapID())
    for mapID in pairs(FC.Reference.zones) do add(mapID) end
    table.sort(maps)
    return maps
end

--- Files one explored area ({ name, x, y }) of a zone map. Returns "new",
--- or "known" for an area the journal already has under that name (found
--- while it watched, by another of your characters, or by the guild); it
--- then counts for the character you play, quietly.
function World:FileExplored(mapID, area, now)
    local store = FC.Store
    local name = area.name
    local key = U.NormalizeTitle(name)
    if key == "" then return nil end
    local existing = self:FindNamed(mapID, "cave", name) or self:FindNamed(mapID, "landmark", name)
    if existing then
        store:MarkSeen(existing.id, now, true)
        return "known"
    end
    local cave = FC.Config:Get("discovery.caves") and hasWord(name, L.CAVE_WORDS) and not hasWord(name, L.BUILDING_WORDS)
    local typeKey = cave and "cave" or "landmark"
    local zone = Compat.GetMapName(mapID)
    local rec, isNew = store:Create({
        t = typeKey, n = name, m = mapID, x = area.x, y = area.y, z = zone, sz = name,
        d = string.format(L.AUTO_RECOVERED_AREA, zone or L.UNKNOWN_ZONE),
        tg = { "explored", "recovered" }, v = "p", rcv = true,
        ic = Categories:Get(typeKey).icon,
    }, { id = "u:" .. typeKey .. ":" .. mapID .. ":" .. key, source = "recovery", personal = true })
    if not rec then return nil end
    if not isNew then
        store:MarkSeen(rec.id, now, true)
        return "known"
    end
    return "new"
end

--- Reads the explored areas of every zone map and files the ones the
--- journal lacks. force (/fc rescan): also for a character read before,
--- and the result is printed. Returns whether a pass was started.
function World:RecoverExplored(force)
    if self.recovery then return false end
    if not FC.Config:Get("discovery.explored") then
        if force then FC:Print(L.MSG_EXPLORED_OFF) end
        return false
    end
    local state = type(FC.cdb.explored) == "table" and FC.cdb.explored or nil
    if not force and state and state.v == RECOVERY_VERSION then return false end
    local run = { maps = self:ExploredMaps(), index = 0, read = 0, areas = 0, new = 0, manual = force and true or false }
    self.recovery = run
    run.ticker = C_Timer.NewTicker(RECOVERY_TICK, function() FC:SafeCall("World:RecoverTick", self.RecoverTick, self) end)
    return true
end

function World:RecoverTick()
    local run = self.recovery
    if not run then return end
    if Compat.InCombat() then return end -- goes on after the fight
    run.index = run.index + 1
    local mapID = run.maps[run.index]
    if not mapID or run.new >= RECOVERY_LIMIT then return self:RecoverDone() end
    local areas = Compat.GetExploredAreas(mapID)
    if not areas then return end
    run.read = run.read + 1
    local now = U.Now()
    for _, area in ipairs(areas) do
        run.areas = run.areas + 1
        if self:FileExplored(mapID, area, now) == "new" then run.new = run.new + 1 end
    end
end

function World:RecoverDone()
    local run = self.recovery
    self.recovery = nil
    if not run then return end
    if run.ticker then run.ticker:Cancel() end
    FC.Log:Debug("Explored areas: %d zone maps read of %d, %d areas explored, %d new to the journal", run.read, #run.maps, run.areas, run.new)
    if run.read == 0 then
        -- the client could not tell (not ready, or it has no such data): tried again at the next login
        if run.manual then FC:Print(L.MSG_EXPLORED_UNAVAILABLE) end
        return
    end
    FC.cdb.explored = { v = RECOVERY_VERSION, t = U.Now(), n = run.areas }
    if run.new > 0 then
        -- what the areas unlock is filled in quietly, like a character's first check
        FC.Milestones:Evaluate(true)
        FC:Print(L.MSG_EXPLORED_RECOVERED, run.new, run.areas)
    elseif run.manual then
        FC:Print(L.MSG_EXPLORED_NONE, run.areas)
    end
end

Engine:RegisterDetector("explored-recovery", {
    OnEnable = function()
        -- after the completed quests were read and the first screens settled
        U.After(12, function() World:RecoverExplored(false) end)
    end,
})

------------------------------------------------------------------------
-- Death spots (private by default)
------------------------------------------------------------------------

function World:OnDeath()
    local mapID, x, y = positionNow()
    if not mapID then
        local last = FC.Location.last
        if not last then return end
        mapID, x, y = last.m, U.Round(last.x, 4), U.Round(last.y, 4)
    end
    local target = Compat.GetUnitInfo("target")
    local killer = target and not target.isPlayer and target.name or nil
    local id = "u:death:" .. mapID .. ":" .. U.GridKey(x, y, D.OBJECT_GRID)
    local existing = FC.Store:Get(id)
    if existing and FC.Store:IsMine(existing) then
        local count = (existing.cnt or 1) + 1
        FC.Store:Update(id, {
            cnt = count,
            d = killer and string.format(L.AUTO_DEATH_KILLER, count, killer) or string.format(L.AUTO_DEATH, count),
        }, "auto")
        return
    end
    local zone, subzone = Compat.GetZoneTexts()
    Engine:Record({
        t = "note",
        n = string.format(L.AUTO_DEATH_TITLE, (subzone ~= "" and subzone) or zone),
        d = killer and string.format(L.AUTO_DEATH_KILLER, 1, killer) or string.format(L.AUTO_DEATH, 1),
        m = mapID, x = x, y = y, z = zone ~= "" and zone or nil, sz = subzone ~= "" and subzone or nil,
        cnt = 1, v = "p", tg = { "danger" },
        ic = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    }, { id = id, deferInCombat = false })
end

Engine:RegisterDetector("deaths", {
    setting = "discovery.deaths",
    events = {
        PLAYER_DEAD = function() World:OnDeath() end,
    },
})

------------------------------------------------------------------------
-- Readable texts in the world
------------------------------------------------------------------------

Engine:RegisterDetector("readables", {
    setting = "discovery.readables",
    events = {
        ITEM_TEXT_READY = function()
            local source = Compat.GetUnitInfo("npc")
            local guidType, objectID = Compat.ParseGUID(source and source.guid)
            if guidType ~= "GameObject" or not objectID then return end -- books in your bags are not world discoveries
            local title, text = Compat.GetReadableText()
            if not title then return end
            local fields = Engine:LocationFields()
            fields.t = "object"
            fields.n = title
            if text then
                text = text:gsub("<[^>]+>", ""):gsub("%s+", " ")
                fields.d = #text > 400 and (text:sub(1, 397) .. "...") or text
            end
            fields.tg = { "lore", "readable" }
            fields.ic = "Interface\\Icons\\INV_Misc_Book_09"
            Engine:Record(fields, { id = "u:read:" .. objectID .. ":" .. (fields.m or 0) })
        end,
    },
})
