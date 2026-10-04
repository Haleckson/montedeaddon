local _, ns = ...

-- Turquoise marks on the minimap: the nearest undiscovered figures and unread
-- writings around the reader. No library: the position comes from the zone
-- map's size in yards and the minimap's zoom.
--
-- A tracked target, or the waypoint, beyond the minimap's edge stays pinned to
-- the edge, pointing the way. Everything else beyond the edge is hidden.
-- When Questie draws Lorever's marks (Use Questie icons), these step aside.

local MinimapPins = {}
ns.MinimapPins = MinimapPins

local Theme, Track, P = ns.Theme, ns.Track, ns.Progress
local MAX = 24
local BOOK_ICON = "Interface\\Icons\\INV_Misc_Book_11"

-- The minimap's diameter in yards, per zoom level (the game's own fixed sizes).
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }
local INDOOR = { [0] = 300, 240, 180, 120, 80, 50 }

local pins, holder = {}, nil

local function indoors()
	local zoom = Minimap:GetZoom()
	local inside = tonumber(GetCVar and GetCVar("minimapInsideZoom"))
	local outside = tonumber(GetCVar and GetCVar("minimapZoom"))
	-- The cvar that matches the current zoom tells where the reader is.
	if inside and outside and inside ~= outside then return zoom == inside end
	return false
end

-- Minimap offset (pixels) of a point dx, dy yards east and south of the reader.
function MinimapPins.Offset(dx, dy, zoom, inside, width, rotate, facing)
	local diameter = (inside and INDOOR or OUTDOOR)[zoom] or OUTDOOR[0]
	local scale = width / diameter
	local x, y = dx * scale, -dy * scale
	if rotate and facing then
		local s, c = math.sin(facing), math.cos(facing)
		x, y = x * c - y * s, x * s + y * c
	end
	local r = math.sqrt(x * x + y * y)
	return x, y, r > width / 2, r
end

local function pin(i)
	local p = pins[i]
	if p then return p end
	p = CreateFrame("Button", nil, holder)
	p:SetSize(11, 11)
	p.icon = p:CreateTexture(nil, "OVERLAY")
	p.icon:SetAllPoints()
	p:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(self.entry.title, 1, 1, 1)
		GameTooltip:AddLine(self.entry.kind == "book" and ns.T(ns.Library.Category(self.entry).one) or ns.T("Undiscovered Lore"), unpack(Theme.TURQUOISE))
		if self.distance then GameTooltip:AddLine(string.format(ns.T("%d yards"), self.distance), 0.7, 0.7, 0.7) end
		GameTooltip:Show()
	end)
	p:SetScript("OnLeave", GameTooltip_Hide)
	p:SetScript("OnClick", function(self) Track.SetWaypoint(self.entry) end)
	pins[i] = p
	return p
end

local function hideFrom(i)
	for j = i, #pins do pins[j]:Hide() end
end

function MinimapPins.Update()
	if not holder then return end
	local s = ns.db.settings
	if not s.minimapPins or (ns.QuestieBridge and ns.QuestieBridge.Active()) then return hideFrom(1) end
	local mapID, px, py = Track.PlayerPos()
	local w, h = 0, 0
	if mapID and C_Map.GetMapWorldSize then
		local ok, mw, mh = pcall(C_Map.GetMapWorldSize, mapID)
		if ok and mw then w, h = mw, mh end
	end
	if not mapID or w == 0 then return hideFrom(1) end
	local zoom, inside, width = Minimap:GetZoom(), indoors(), Minimap:GetWidth()
	local rotate = GetCVar and GetCVar("rotateMinimap") == "1"
	local facing = rotate and GetPlayerFacing and -(GetPlayerFacing() or 0) or nil
	local shown = 0
	local function place(entry, spot, pinned)
		if shown >= MAX or spot.map ~= mapID then return end
		local wanted = (entry.kind == "book" and s.bookPins) or (entry.kind == "figure" and s.mapPins)
		if not wanted then return end
		local dx, dy = (spot.x - px) / 100 * w, (spot.y - py) / 100 * h
		local x, y, outside, r = MinimapPins.Offset(dx, dy, zoom, inside, width, rotate, facing)
		if outside then
			if not pinned then return end
			local k = (width / 2 - 4) / r -- to the edge
			x, y = x * k, y * k
		end
		shown = shown + 1
		local p = pin(shown)
		p.entry, p.distance = entry, math.floor(math.sqrt(dx * dx + dy * dy))
		if entry.kind == "book" then
			p.icon:SetTexture(BOOK_ICON)
			p.icon:SetVertexColor(1, 1, 1)
			Theme.Round(p, p.icon, true)
		else
			Theme.Round(p, p.icon, false)
			Theme.Marker(p.icon)
		end
		p.icon:SetAlpha((outside and 0.7 or 1) * (entry.kind == "book" and 0.75 or 1))
		p:ClearAllPoints()
		p:SetPoint("CENTER", Minimap, "CENTER", x, y)
		p:Show()
	end
	-- Which targets to draw changes slowly: it is worked out once a second (or when
	-- asked). Between, only their positions on the minimap move.
	local now = GetTime()
	if not MinimapPins.candidates or now - (MinimapPins.pickedAt or 0) >= 1 then
		local list, done = {}, {}
		for _, item in ipairs(Track.List()) do
			if item.spot and not item.auto then
				list[#list + 1] = { entry = item.entry, spot = item.spot, pinned = true }
				done[item.entry.id] = true
			end
		end
		for _, item in ipairs(Track.Nearby(MAX)) do
			if not done[item.entry.id] then list[#list + 1] = { entry = item.entry, spot = item.spot } end
		end
		MinimapPins.candidates, MinimapPins.pickedAt = list, now
	end
	for _, c in ipairs(MinimapPins.candidates) do
		if c.pinned or not P.IsFound(c.entry.id) then place(c.entry, c.spot, c.pinned) end
	end
	hideFrom(shown + 1)
end

-- Something changed (a discovery, a new target): pick again at the next update.
function MinimapPins.Invalidate() MinimapPins.candidates = nil end

ns.Listen("FL_LOGIN", function()
	if not Minimap then return end
	holder = CreateFrame("Frame", nil, Minimap)
	holder:SetAllPoints()
	holder:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 5)
	local elapsed = 0
	holder:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed >= 0.1 then
			elapsed = 0
			MinimapPins.Update()
		end
	end)
	MinimapPins.holder = holder
end)
ns.Listen("FL_SETTINGS_CHANGED", function() MinimapPins.Invalidate() MinimapPins.Update() end)
ns.Listen("FL_TRACK_CHANGED", function() MinimapPins.Invalidate() end)
ns.Listen("FL_UNLOCKED", function() MinimapPins.Invalidate() end)
ns.Listen("FL_ZONE", function() MinimapPins.Invalidate() end)
