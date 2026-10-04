local _, ns = ...

-- Community reports, v1: Literature only.
--
-- The addon watches every writing read in the world (not from the bags) and
-- keeps a sighting when it tells the catalogue something new:
--   "place"  a catalogued writing with no known place, or read far from every
--            known place (another copy somewhere else);
--   "new"    a title the catalogue does not know at all.
-- Sightings close together (CLUSTER map percent) are one place. A place counts
-- one witness per character per day, so reading the same book three times in
-- a row proves nothing, while three characters or three days do.
-- At REPORT_AT witnesses a report is ready. Reports wait in LoreverDB.reports
-- for the uploader (see plano/FASE-6-mundo-vivo.md); /lorever export shows
-- them as text too.
--
-- Nothing personal is kept: each character gets a random witness code, drawn once,
-- with no link to its name.

local Reports = {}
ns.Reports = Reports

local Lore = ns.Lore
local CLUSTER = 1.5      -- map percent: one place
local FAR = 3.0          -- map percent: farther than this from every known place is a new place
local REPORT_AT = 3      -- witnesses (character-days) for a report
local MAX_KEYS = 300     -- titles followed
local MAX_PLACES = 8     -- places per title
Reports.REPORT_AT = REPORT_AT

local function store()
	local db = ns.db
	db.sightings = db.sightings or {}
	db.reports = db.reports or {}
	return db.sightings, db.reports
end

-- This character's random witness code (drawn once, kept with the character).
function Reports.WitnessCode()
	local key = ns.U.CharKey()
	local c = ns.db.chars[key]
	if not c then
		c = { unlocked = {} }
		ns.db.chars[key] = c
	end
	if not c.witness then
		c.witness = string.format("%06x%06x", math.random(0, 0xffffff), math.random(0, 0xffffff))
	end
	return c.witness
end

-- What this reading tells, or nil when the catalogue already knows it.
function Reports.Kind(info)
	if not info.place then return nil end
	local entry = info.entry
	if not entry then return "new" end
	local spots = ns.Track.Spots(entry)
	if #spots == 0 then return "place" end
	for _, spot in ipairs(spots) do
		for _, m in ipairs(spot.maps) do
			if m == info.place.map and math.abs(spot.x - info.place.x) <= FAR and math.abs(spot.y - info.place.y) <= FAR then
				return nil -- a known place
			end
		end
	end
	return "place"
end

local function count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

function Reports.Record(info)
	local kind = Reports.Kind(info)
	if not kind then return end
	local sightings, reports = store()
	local key = kind .. ":" .. info.title
	local s = sightings[key]
	if not s then
		if count(sightings) >= MAX_KEYS then return end
		s = { kind = kind, title = info.title, id = info.entry and info.entry.id or nil, places = {} }
		sightings[key] = s
	end
	local p = info.place
	local place
	for _, c in ipairs(s.places) do
		if c.map == p.map and math.abs(c.x - p.x) <= CLUSTER and math.abs(c.y - p.y) <= CLUSTER then place = c break end
	end
	if not place then
		if #s.places >= MAX_PLACES then return end
		place = { map = p.map, x = p.x, y = p.y, zone = p.zone, subzone = p.subzone, w = {}, n = 0, first = time() }
		table.insert(s.places, place)
	end
	local witness = Reports.WitnessCode() .. date("%Y%m%d")
	if place.w[witness] then return end
	place.w[witness] = true
	place.n = place.n + 1
	-- The place drifts to the average of its readings.
	place.x = math.floor(((place.x * (place.n - 1)) + p.x) / place.n * 10 + 0.5) / 10
	place.y = math.floor(((place.y * (place.n - 1)) + p.y) / place.n * 10 + 0.5) / 10
	place.last = time()
	if place.n >= REPORT_AT and not place.reported then
		place.reported = time()
		table.insert(reports, {
			v = 1, kind = kind, title = s.title, id = s.id, map = place.map, x = place.x, y = place.y,
			zone = place.zone, n = place.n, first = place.first, last = place.last,
			locale = GetLocale and GetLocale() or "?", version = ns.version, sent = nil,
		})
		ns.Print(string.format(kind == "new"
			and ns.T("Thank you: a new writing for \"%s\" is confirmed. It will be shared with the Lorever community.")
			or ns.T("Thank you: a new place for \"%s\" is confirmed. It will be shared with the Lorever community."), s.title))
		ns.Fire("FL_REPORT_READY", reports[#reports])
	end
end

ns.Listen("FL_WRITING_READ", function(_, info) Reports.Record(info) end)

-- Reports not yet sent.
function Reports.Pending()
	local _, reports = store()
	local out = {}
	for _, r in ipairs(reports) do
		if not r.sent then out[#out + 1] = r end
	end
	return out
end

-- Text form: "LRV1" header, one line per report, and a checksum line.
local function field(v)
	return (tostring(v or ""):gsub("[;\n|]", " "))
end

function Reports.Text(list)
	local lines = { "LRV1;" .. field(ns.version) .. ";" .. field(GetLocale and GetLocale() or "?") }
	for _, r in ipairs(list or Reports.Pending()) do
		lines[#lines + 1] = table.concat({ "B", r.kind, field(r.title), field(r.id), r.map, r.x, r.y, r.n,
			date("%Y-%m-%d", r.first or 0), date("%Y-%m-%d", r.last or 0), field(r.zone) }, ";")
	end
	local body = table.concat(lines, "\n")
	local sum = 0
	for i = 1, #body do sum = (sum + body:byte(i) * i) % 65536 end
	return body .. "\nEND;" .. string.format("%04x", sum)
end

-- Once the catalogue knows a place, its pending report is no longer needed.
ns.Listen("FL_LOGIN", function()
	local _, reports = store()
	for _, r in ipairs(reports) do
		local entry = r.id and Lore.Get(r.id)
		if entry and not r.sent and not Reports.Kind({ entry = entry, place = { map = r.map, x = r.x, y = r.y } }) then
			r.sent = "known"
		end
	end
end)

-- /lorever export: the pending reports as text, in a box ready to copy.
local box
function Reports.ShowExport()
	local text = Reports.Text()
	if not box then
		box = CreateFrame("Frame", "LoreverExportFrame", UIParent)
		box:SetSize(460, 220)
		box:SetPoint("CENTER")
		box:SetFrameStrata("DIALOG")
		box:EnableMouse(true)
		local bg = box:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.08, 0.07, 0.05, 0.95)
		local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", 10, -8)
		title:SetText(ns.T("Lorever reports: press Ctrl+C to copy"))
		local where = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		where:SetPoint("BOTTOMLEFT", 10, 8)
		where:SetText(ns.T("Share them at github.com/acappa221b/Lorever-Community (Issues, New issue, Literature report)."))
		local close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT")
		local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 10, -30)
		scroll:SetPoint("BOTTOMRIGHT", -30, 26)
		local edit = CreateFrame("EditBox", nil, scroll)
		edit:SetMultiLine(true)
		edit:SetFontObject("ChatFontNormal")
		edit:SetWidth(410)
		edit:SetAutoFocus(false)
		edit:SetScript("OnEscapePressed", function() box:Hide() end)
		scroll:SetScrollChild(edit)
		box.edit = edit
	end
	box.edit:SetText(text)
	box.edit:HighlightText()
	box.edit:SetFocus()
	box:Show()
	return text
end
