local _, ns = ...

-- The library of Literature: books, letters, journals, legends and inscriptions.
--
-- The addon ships no text of any book. When the reader opens one in the world,
-- the game shows its pages, and each page the reader sees is kept in
-- LoreverDB.texts. From then on it can be read again inside the panel.
-- Where the reader stood is kept too (LoreverDB.foundAt): it tells where a
-- writing with no known place was found.

local Library = {}
ns.Library = Library

local Lore, U = ns.Lore, ns.U

local N = ns.N
Library.CATEGORIES = {
	{ key = "book", label = N("Books"), one = N("Book") },
	{ key = "letter", label = N("Letters and Notes"), one = N("Letter") },
	{ key = "journal", label = N("Journals"), one = N("Journal") },
	{ key = "legend", label = N("Legends"), one = N("Legend") },
	{ key = "inscription", label = N("Inscriptions"), one = N("Inscription") },
}
local byKey = {}
for _, cat in ipairs(Library.CATEGORIES) do byKey[cat.key] = cat end

function Library.Category(book)
	return byKey[book.category or "book"] or byKey.book
end

function Library.Zone(book)
	if book.zone then return book.zone end
	local region = book.region and Lore.Get(book.region)
	return region and region.title or ns.T("Place unknown")
end

-- Every land that holds a copy: { { zone = name, continent = name }, ... }, from
-- the map of each of the writing's places. A writing with one place gives one.
local mapRegion
local function regionOfMap(mapID)
	if not mapRegion then
		mapRegion = {}
		for _, item in ipairs(Lore.order) do
			local e = type(item) == "table" and item or Lore.Get(item)
			if e and e.kind == "region" and e.regionKind ~= "place" then
				for _, id in ipairs(e.maps or {}) do
					if not mapRegion[id] then mapRegion[id] = e end
				end
			end
		end
	end
	return mapRegion[mapID]
end

function Library.Places(book)
	local out, seen = {}, {}
	for _, pin in ipairs(book.pins or {}) do
		for _, id in ipairs(pin.maps or {}) do
			local region = regionOfMap(id)
			if region then
				if not seen[region.id] then
					seen[region.id] = true
					out[#out + 1] = { zone = region.title, continent = region.continent or Library.Continent(book), region = region }
				end
				break
			end
		end
	end
	if #out == 0 then out[1] = { zone = Library.Zone(book), continent = Library.Continent(book) } end
	return out
end

function Library.Continent(book)
	if book.continent then return book.continent end
	local region = book.region and Lore.Get(book.region)
	return region and region.continent or "Unknown"
end

-- Every title that opens this entry (a book can gather loose pages and chapters).
function Library.Titles(book)
	local out = {}
	for _, rule in ipairs(book.unlock or {}) do
		if rule.type == "book" then out[#out + 1] = rule.name end
	end
	return out
end

-- The kept text of a title: { pages = { [n] = text }, count = n } or nil.
function Library.Text(title)
	return ns.db and ns.db.texts[title]
end

-- Kept texts of an entry, in the order of its titles.
function Library.TextsOf(book)
	local out = {}
	for _, title in ipairs(Library.Titles(book)) do
		local text = Library.Text(title)
		if text then out[#out + 1] = { title = title, text = text } end
	end
	return out
end

-- Pages kept, and pages known to exist (nil when unknown).
function Library.PageCount(book)
	local kept = 0
	for _, t in ipairs(Library.TextsOf(book)) do
		for _ in pairs(t.text.pages) do kept = kept + 1 end
	end
	return kept, book.pages
end

-- Where the reader first opened a title, or nil.
function Library.FoundAt(book)
	for _, title in ipairs(Library.Titles(book)) do
		local at = ns.db and ns.db.foundAt[title]
		if at then return at end
	end
end

-- Titles read in the world that the catalogue does not know yet.
function Library.Unlisted()
	local out = {}
	for title in pairs(ns.db and ns.db.texts or {}) do
		if not Lore.index.book[title] then out[#out + 1] = title end
	end
	table.sort(out)
	return out
end

-- Reading in the world ---------------------------------------------------------------

-- A writing read from the bags has no place worth keeping. Using a bag item just
-- before the text opens tells the two apart, and tells which item it is.
local lastBagUse, lastBagItem = -10, nil
local function noteBagUse(bag, slot)
	lastBagUse = GetTime()
	local getID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
	local ok, id = pcall(getID or function() end, bag, slot)
	lastBagItem = ok and id or nil
end
if C_Container and C_Container.UseContainerItem then hooksecurefunc(C_Container, "UseContainerItem", noteBagUse) end
if UseContainerItem then hooksecurefunc("UseContainerItem", noteBagUse) end

-- Which catalogued writing is open, in any client language.
-- 1. its title, as written in the catalogue (English clients);
-- 2. an item just used from the bags: its item ID;
-- 3. a book, plaque or stone in the world: the one whose place is where the reader stands.
local NEAR = 2.0 -- map percent
function Library.Resolve(title, fromBag)
	if title and Lore.index.book[title] then return nil, title end
	if fromBag and lastBagItem then
		for _, book in ipairs(Lore.books) do
			for _, id in ipairs(book.items or {}) do
				if id == lastBagItem then return book, Library.Titles(book)[1] end
			end
		end
		return nil
	end
	local mapID, x, y = ns.Track.PlayerPos()
	if not mapID then return nil end
	local best, bestD
	for _, book in ipairs(Lore.books) do
		if book.objects then
			for _, spot in ipairs(ns.Track.Spots(book)) do
				for _, m in ipairs(spot.maps) do
					if m == mapID then
						local d = math.max(math.abs(spot.x - x), math.abs(spot.y - y))
						if d <= NEAR and (not bestD or d < bestD) then best, bestD = book, d end
					end
				end
			end
		end
	end
	if best then return best, Library.Titles(best)[1] end
end

local reading -- the title on screen

local function playerPlace()
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	if not (pos and pos.GetXY) then return nil end
	local x, y = pos:GetXY()
	if not x or U.IsSecret(x) then return nil end
	return {
		map = mapID, x = math.floor(x * 1000 + 0.5) / 10, y = math.floor(y * 1000 + 0.5) / 10,
		zone = GetRealZoneText and GetRealZoneText() or nil, subzone = GetSubZoneText and GetSubZoneText() or nil,
	}
end

ns.On("ITEM_TEXT_BEGIN", function()
	local title = ItemTextGetItem and ItemTextGetItem()
	if not title or U.IsSecret(title) or title == "" then
		reading = nil
		return
	end
	local fromBag = GetTime() - lastBagUse <= 1.5
	local book, english = Library.Resolve(title, fromBag)
	if book then
		ns.Progress.Unlock(book.id) -- the title alone did not tell (another language)
		-- Keep the title the game showed, in the reader's language, for the page.
		if Lore.language ~= "enUS" and title ~= book.title then
			ns.db.localNames[book.id] = title
			Lore.SetLocalName(book.id, title)
		end
	end
	title = english or title
	reading = title
	do
		local known = Lore.index.book[title]
		Library.reading = book or (known and known[1] and known[1].entry) or nil
	end
	local db = ns.db
	local place = not fromBag and playerPlace() or nil
	if place and not db.foundAt[title] then
		place.at = time()
		db.foundAt[title] = place
	end
	-- For the community reports (Core/Reports.lua): which writing, and where.
	local parts = Lore.index.book[title]
	ns.Fire("FL_WRITING_READ", {
		title = title, entry = book or (parts and parts[1] and parts[1].entry) or nil,
		place = place, fromBag = fromBag,
	})
end)

ns.On("ITEM_TEXT_READY", function()
	local title = reading
	if not title then return end
	local page = ItemTextGetPage and ItemTextGetPage() or 1
	local text = ItemTextGetText and ItemTextGetText()
	if not text or U.IsSecret(text) or text == "" then return end
	local db = ns.db
	local kept = db.texts[title]
	if not kept then
		kept = { pages = {}, count = 0, at = time() }
		db.texts[title] = kept
	end
	if not kept.pages[page] then kept.count = kept.count + 1 end
	kept.pages[page] = text
	ns.Fire("FL_TEXT_KEPT", title, page)
end)

ns.On("ITEM_TEXT_CLOSED", function()
	reading = nil
	Library.reading = nil
end)

-- A writing in the bags is found: the reader picked it up. Only item ids are
-- read, and only when the bags change (R3: light work, never every frame).
local byItem
function Library.ScanBags()
	if not (ns.db and ns.db.settings.bagBooks) then return 0 end
	local C = C_Container
	local slots = (C and C.GetContainerNumSlots) or GetContainerNumSlots
	local itemID = (C and C.GetContainerItemID) or GetContainerItemID
	if not (slots and itemID) then return 0 end
	if not byItem then
		byItem = {}
		for _, book in ipairs(Lore.books) do
			for _, id in ipairs(book.items or {}) do byItem[id] = byItem[id] or book end
		end
	end
	local found = 0
	for bag = 0, 4 do
		for slot = 1, slots(bag) or 0 do
			local book = byItem[itemID(bag, slot) or 0]
			if book and not ns.Progress.IsFound(book.id) then
				ns.Progress.Unlock(book.id)
				found = found + 1
			end
		end
	end
	return found
end
ns.On("BAG_UPDATE_DELAYED", function() Library.ScanBags() end)
