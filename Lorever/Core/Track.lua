local _, ns = ...

-- Tracking: the figures and writings the reader wants to find, shown in the
-- Lore tracker (UI/Tracker.lua) and pointed at with a waypoint.
--
--   Track.Toggle(id)       track or stop tracking an entry
--   Track.List()           what the tracker shows: tracked entries, then the
--                          nearest ones in this zone when "auto" is on
--   Track.SetWaypoint(e)   TomTom's arrow when TomTom is there, else the game's

local Track = {}
ns.Track = Track

local Lore, P = ns.Lore, ns.Progress

-- Places ---------------------------------------------------------------------------

-- Every place of an entry: { maps = { uiMapID, ... }, x, y } (x, y in 0-100).
function Track.Spots(entry)
	local out = {}
	if entry.pin then
		local region = entry.region and Lore.Get(entry.region)
		if region and region.maps then out[#out + 1] = { maps = region.maps, x = entry.pin.x, y = entry.pin.y } end
	end
	for _, pin in ipairs(entry.pins or {}) do out[#out + 1] = pin end
	return out
end

-- The maps the player stands in, from the zone up to the continent.
local function playerMaps()
	local out = {}
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local guard = 0
	while mapID and mapID > 0 and guard < 5 do
		out[#out + 1] = mapID
		local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
		mapID = info and info.parentMapID
		guard = guard + 1
	end
	return out
end

local function has(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then return true end
	end
	return false
end

-- Where the player stands: mapID, x, y (0-100), or nil.
function Track.PlayerPos()
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	if not (pos and pos.GetXY) then return nil end
	local x, y = pos:GetXY()
	if not x or ns.U.IsSecret(x) then return nil end
	return mapID, x * 100, y * 100
end

-- Distance in yards between two map points, when the game can tell (same continent).
-- World positions of map points. Lore places never move, so each is asked of the
-- game once and remembered (the tracker and the minimap ask often).
local worldCache, worldCached = {}, 0
local function worldPos(mapID, x, y, remember)
	if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
	local key = mapID .. ":" .. x .. ":" .. y
	local hit = remember and worldCache[key]
	if hit then return hit[1], hit[2], hit[3] end
	local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x / 100, y / 100))
	if not ok or not pos then return nil end
	if remember and worldCached < 5000 then
		worldCache[key] = { continent, pos.x, pos.y }
		worldCached = worldCached + 1
	end
	return continent, pos.x, pos.y
end

function Track.Distance(mapA, xA, yA, mapB, xB, yB)
	-- A is usually where the reader stands (it moves); B is a lore place (it does not).
	local cA, wxA, wyA = worldPos(mapA, xA, yA, false)
	local cB, wxB, wyB = worldPos(mapB, xB, yB, true)
	if cA and cB and cA == cB then
		return math.sqrt((wxA - wxB) ^ 2 + (wyA - wyB) ^ 2)
	end
	if mapA == mapB then
		-- No world positions: the map's size in yards, else roughly 1000 yards a zone.
		local w, h = 1000, 1000
		if C_Map and C_Map.GetMapWorldSize then
			local ok, mw, mh = pcall(C_Map.GetMapWorldSize, mapA)
			if ok and mw and mw > 0 then w, h = mw, mh end
		end
		return math.sqrt(((xA - xB) / 100 * w) ^ 2 + ((yA - yB) / 100 * h) ^ 2)
	end
end

-- The spot of an entry on the player's map, nearest first: spot, distance (or nil).
function Track.NearestSpot(entry)
	local mapID, px, py = Track.PlayerPos()
	local maps = playerMaps()
	local best, bestD
	for _, spot in ipairs(Track.Spots(entry)) do
		local here
		for _, m in ipairs(maps) do
			if has(spot.maps, m) then here = m break end
		end
		if here then
			local d = mapID and Track.Distance(mapID, px, py, here, spot.x, spot.y)
			if not best or (d and (not bestD or d < bestD)) then
				best, bestD = { map = here, x = spot.x, y = spot.y }, d
			end
		end
	end
	return best, bestD
end

-- A map ID the game knows, from a spot's list (Forever may use either numbering).
local function knownMap(maps)
	for _, id in ipairs(maps or {}) do
		if not (C_Map and C_Map.GetMapInfo) or C_Map.GetMapInfo(id) then return id end
	end
end

-- Tracking list -----------------------------------------------------------------------

-- A tracked item: a lore page.
function Track.Get(id)
	return Lore.Get(id)
end

local function tracked()
	ns.db.tracked = ns.db.tracked or {}
	return ns.db.tracked
end

function Track.IsTracked(id)
	return has(tracked(), id)
end

function Track.Toggle(id)
	local list = tracked()
	for i, v in ipairs(list) do
		if v == id then
			table.remove(list, i)
			ns.Fire("FL_TRACK_CHANGED")
			return false
		end
	end
	list[#list + 1] = id
	ns.Fire("FL_TRACK_CHANGED")
	return true
end

function Track.Clear()
	wipe(tracked())
	ns.Fire("FL_TRACK_CHANGED")
end

-- [mapID] = { { entry, spot }, ... }, built once: the tracker asks every second.
local byMap
local function mapIndex()
	if byMap then return byMap end
	byMap = {}
	for _, entry in ipairs(Lore.order) do
		if entry.kind == "figure" or entry.kind == "book" then
			for _, spot in ipairs(Track.Spots(entry)) do
				for _, m in ipairs(spot.maps) do
					byMap[m] = byMap[m] or {}
					table.insert(byMap[m], { entry = entry, spot = spot, map = m })
				end
			end
		end
	end
	return byMap
end

-- How many figures and writings are left to find on a map (for continent maps),
-- following the map filters.
function Track.CountOn(mapID)
	local s, seen, n = ns.db.settings, {}, 0
	for _, it in ipairs(mapIndex()[mapID] or {}) do
		local entry = it.entry
		local wanted = (entry.kind == "book" and s.bookPins) or (entry.kind == "figure" and s.mapPins)
		if wanted and not seen[entry.id] and not P.IsFound(entry.id) then
			seen[entry.id] = true
			n = n + 1
		end
	end
	return n
end

-- Undiscovered targets in the player's zone, nearest first: { entry, spot, distance }.
function Track.Nearby(limit)
	local out, seen = {}, {}
	local mapID, px, py = Track.PlayerPos()
	for _, m in ipairs(playerMaps()) do
		for _, it in ipairs(mapIndex()[m] or {}) do
			local entry = it.entry
			if not P.IsFound(entry.id) then
				local d = mapID and Track.Distance(mapID, px, py, m, it.spot.x, it.spot.y)
				local prev = seen[entry.id]
				if not prev then
					prev = { entry = entry, spot = { map = m, x = it.spot.x, y = it.spot.y }, distance = d }
					seen[entry.id] = prev
					out[#out + 1] = prev
				elseif d and (not prev.distance or d < prev.distance) then
					prev.spot, prev.distance = { map = m, x = it.spot.x, y = it.spot.y }, d
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a.distance and b.distance then return a.distance < b.distance end
		return a.distance ~= nil
	end)
	if limit then
		for i = #out, limit + 1, -1 do out[i] = nil end
	end
	return out
end

-- What the tracker shows: { entry, spot, distance, auto }.
function Track.List()
	local out, seen = {}, {}
	for _, id in ipairs(tracked()) do
		local entry = Track.Get(id)
		if entry then
			local spot, d = Track.NearestSpot(entry)
			out[#out + 1] = { entry = entry, spot = spot, distance = d }
			seen[id] = true
		end
	end
	local s = ns.db.settings
	if s.trackerAuto then
		local extra = 0
		for _, item in ipairs(Track.Nearby()) do
			if extra >= (s.trackerAutoCount or 3) then break end
			if not seen[item.entry.id] then
				item.auto = true
				out[#out + 1] = item
				extra = extra + 1
			end
		end
	end
	return out
end

-- Waypoint ------------------------------------------------------------------------------

local tomtomUID

-- Points the arrow at an entry's nearest place. Returns true when set.
function Track.SetWaypoint(entry)
	local spot = entry and Track.NearestSpot(entry)
	if not spot then
		local first = entry and Track.Spots(entry)[1]
		if first then spot = { map = knownMap(first.maps), x = first.x, y = first.y } end
	end
	if not (spot and spot.map) then return false end
	Track.waypoint = entry.id
	local TomTom = _G.TomTom
	if TomTom and TomTom.AddWaypoint then
		if tomtomUID and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, tomtomUID) end
		local ok, uid = pcall(TomTom.AddWaypoint, TomTom, spot.map, spot.x / 100, spot.y / 100,
			{ title = entry.title, from = "Lorever", persistent = false, crazy = true })
		if ok then
			tomtomUID = uid
			return true
		end
	end
	if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
		local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(spot.map, spot.x / 100, spot.y / 100))
		if ok and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
			pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
		end
		return ok
	end
	return false
end

function Track.ClearWaypoint()
	Track.waypoint = nil
	local TomTom = _G.TomTom
	if tomtomUID and TomTom and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, tomtomUID) end
	tomtomUID = nil
	if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
end

-- A page that is found leaves the list, and its arrow goes away.
function Track.Finish(id)
	if not Track.IsTracked(id) and Track.waypoint ~= id then return end
	local list = tracked()
	for i = #list, 1, -1 do
		if list[i] == id then table.remove(list, i) end
	end
	if Track.waypoint == id then Track.ClearWaypoint() end
	ns.Fire("FL_TRACK_CHANGED")
end

ns.Listen("FL_UNLOCKED", function(_, part)
	if part.kind == "base" then Track.Finish(part.entry.id) end
end)

-- Older versions kept routes: their quest stops leave the list.
ns.Listen("FL_DB_READY", function()
	local db = ns.db
	db.routing, db.questStops = nil, nil
	local list = db.tracked
	for i = #(list or {}), 1, -1 do
		if type(list[i]) == "string" and list[i]:find("^quest:") then table.remove(list, i) end
	end
end)
