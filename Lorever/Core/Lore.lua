local _, ns = ...

-- The lore registry.
-- Every entry (region, figure, group) is split into parts. Each part
-- unlocks on its own and grants Lore experience:
--   base     "marshal-dughan"          the entry itself
--   chapter  "marshal-dughan#beneath-the-hills"
--   mention  "marshal-dughan@2"
-- Data files call Lore.Add(); the build tool writes them from content/.

local Lore = {
	entries = {},   -- [id] = entry
	parts = {},     -- [partKey] = part
	order = {},     -- entries in load order
	regionFigures = {}, -- [regionID] = { figure, ... }
	regionPlaces = {},  -- [regionID] = { place, ... } (regions with a parent)
	regionTopics = {},  -- [regionID] = { topic, ... } (topics that name a region)
	regionBooks = {},   -- [regionID] = { book, ... }
	books = {},         -- every book, in load order
	index = {
		quest = {}, encounter = {}, book = {}, subzone = {}, subzoneArea = {},
		zoneMap = {}, zoneName = {}, openMap = {},
		interact = {}, target = {}, always = {},
	},
}
ns.Lore = Lore

-- Lore experience for each kind of discovery.
Lore.XP = {
	region = { world = 20, continent = 20, zone = 40, city = 40, place = 10, dungeon = 40, raid = 60, plane = 40 },
	figure = { A = 50, B = 30, C = 15 },
	topic = { group = 25, people = 25, event = 25, default = 20 },
	chapter = { A = 25, B = 15, C = 10, region = 15, topic = 15 },
	mention = 5,
	book = { book = 25, legend = 25, journal = 20, letter = 15, inscription = 10 },
}

-- Two separate progressions: "lore" (regions, figures, topics) and "books"
-- (Literature: books, letters, journals, legends and inscriptions read in the world). Each has its own experience bar and level.
function Lore.PoolOf(entry)
	return entry.kind == "book" and "books" or "lore"
end

local function baseXP(entry)
	local XP = Lore.XP
	if entry.kind == "region" then return XP.region[entry.regionKind] or 20 end
	if entry.kind == "figure" then return XP.figure[entry.tier] or 15 end
	if entry.kind == "book" then return XP.book[entry.category or "book"] or XP.book.book end
	return XP.topic[entry.category] or XP.topic.default
end

local function chapterXP(entry)
	local XP = Lore.XP.chapter
	if entry.kind == "figure" then return XP[entry.tier] or 10 end
	return XP[entry.kind] or 10
end

local function push(map, key, part)
	if key == nil then return end
	local list = map[key]
	if not list then
		list = {}
		map[key] = list
	end
	list[#list + 1] = part
end

local function indexRules(part)
	local entry, idx = part.entry, Lore.index
	for _, rule in ipairs(part.unlock or {}) do
		local t = rule.type
		if t == "quest" then push(idx.quest, rule.id, part)
		elseif t == "encounter" then push(idx.encounter, rule.id, part)
		elseif t == "book" then push(idx.book, rule.name, part)
		elseif t == "subzone" then
			push(idx.subzone, rule.name, part)
			for _, area in ipairs(rule.areas or {}) do push(idx.subzoneArea, area, part) end
		elseif t == "always" then table.insert(idx.always, part)
		elseif t == "zone" then
			for _, mapID in ipairs(entry.maps or {}) do push(idx.zoneMap, mapID, part) end
			push(idx.zoneName, entry.zone or entry.title, part)
		elseif t == "map" then
			for _, mapID in ipairs(entry.maps or {}) do push(idx.openMap, mapID, part) end
		elseif t == "interact" or t == "target" then
			for _, npcID in ipairs(entry.npc or {}) do push(idx[t], npcID, part) end
		end
	end
end

local function addPart(entry, key, kind, unlock, xp, extra)
	local part = { key = key, entry = entry, kind = kind, unlock = unlock, xp = xp, pool = Lore.PoolOf(entry) }
	for k, v in pairs(extra or {}) do part[k] = v end
	Lore.parts[key] = part
	indexRules(part)
	return part
end

function Lore.Add(entry)
	assert(type(entry) == "table" and entry.id and entry.kind, "Lorever: bad entry")
	if Lore.entries[entry.id] then
		geterrorhandler()("Lorever: duplicate entry " .. entry.id)
		return
	end
	Lore.entries[entry.id] = entry
	Lore.order[#Lore.order + 1] = entry

	entry.basePart = addPart(entry, entry.id, "base", entry.unlock, baseXP(entry))
	entry.partKeys = { entry.id }
	for _, chapter in ipairs(entry.chapters or {}) do
		local key = entry.id .. "#" .. chapter.key
		chapter.part = addPart(entry, key, "chapter", chapter.unlock, chapterXP(entry), { chapter = chapter })
		table.insert(entry.partKeys, key)
	end
	for i, mention in ipairs(entry.mentions or {}) do
		local key = entry.id .. "@" .. i
		mention.part = addPart(entry, key, "mention", mention.unlock, Lore.XP.mention, { mention = mention })
		table.insert(entry.partKeys, key)
	end
	if entry.kind == "figure" and entry.region then
		push(Lore.regionFigures, entry.region, entry)
	end
	if entry.kind == "region" and entry.parent then
		push(Lore.regionPlaces, entry.parent, entry)
	end
	if entry.kind == "topic" and entry.region then
		push(Lore.regionTopics, entry.region, entry)
	end
	if entry.kind == "book" then
		table.insert(Lore.books, entry)
		if entry.region then push(Lore.regionBooks, entry.region, entry) end
	end
end

-- Translations ---------------------------------------------------------------------------
-- Data/<locale>/*.lua call Lore.Translate(locale, id, texts). Once the saved
-- settings are known, Lore.ApplyLanguage swaps the texts of every translated
-- page. Unlock rules, ids and names used to match the game stay in English.

Lore.translations = {} -- [locale] = { [id] = texts }

function Lore.Translate(locale, id, t)
	Lore.translations[locale] = Lore.translations[locale] or {}
	Lore.translations[locale][id] = t
end

local function overlay(list, texts, keys)
	for i, t in ipairs(texts or {}) do
		local item = list and list[i]
		if item then
			for _, k in ipairs(keys) do
				if t[k] ~= nil then item[k] = t[k] end
			end
		end
	end
end

Lore.language = "enUS"

-- The name the game itself showed for a page, in the reader's language (a figure
-- met, a book opened). It replaces our own rendering of that name: in the
-- page's title, and wherever a link to the page shows it.
function Lore.SetLocalName(id, name)
	local e = Lore.entries[id]
	if not e or type(name) ~= "string" or name == "" or e.title == name then return false end
	e.ours = e.ours or e.title
	e.title = name
	return true
end

-- The text of a link to a page: our name for it gives way to the game's.
function Lore.Label(id, label)
	local e = Lore.entries[id]
	if not e or not e.ours or e.ours == "" then return label end
	local a, b = label:find(e.ours, 1, true)
	if not a then return label end
	return label:sub(1, a - 1) .. e.title .. label:sub(b + 1)
end

function Lore.ApplyLanguage(locale)
	local set = Lore.translations[locale]
	if not set or Lore.language == locale then return 0 end
	local n = 0
	for id, t in pairs(set) do
		local e = Lore.entries[id]
		if e then
			e.english = e.english or { title = e.title }
			for _, k in ipairs({ "title", "subtitle", "found", "hint", "allegiance" }) do
				if t[k] then e[k] = t[k] end
			end
			if e.kind == "book" then
				if t.zone then e.zone = t.zone end
				if t.continent then e.continent = t.continent end
			end
			if t.aliases then e.aliases = t.aliases end
			overlay(e.sections, t.sections, { "title", "text" })
			overlay(e.chapters, t.chapters, { "title", "text", "hint" })
			overlay(e.mentions, t.mentions, { "text" })
			overlay(e.bonds, t.bonds, { "name", "note" })
			n = n + 1
		end
	end
	Lore.language = locale
	return n
end

function Lore.BooksOf(regionID)
	return Lore.regionBooks[regionID] or {}
end

-- Encyclopedia categories, in display order.
local N = ns.N
Lore.CATEGORIES = {
	{ key = "realm", label = N("Worlds and Continents"), test = function(e) return e.kind == "region" and (e.regionKind == "world" or e.regionKind == "continent" or e.regionKind == "plane") end },
	{ key = "zone", label = N("Zones and Cities"), test = function(e) return e.kind == "region" and (e.regionKind == "zone" or e.regionKind == "city") end },
	{ key = "instance", label = N("Dungeons and Raids"), test = function(e) return e.kind == "region" and (e.regionKind == "dungeon" or e.regionKind == "raid") end },
	{ key = "place", label = N("Places"), test = function(e) return e.kind == "region" and e.regionKind == "place" end },
	{ key = "figure", label = N("Figures"), test = function(e) return e.kind == "figure" end },
	{ key = "people", label = N("Peoples") },
	{ key = "group", label = N("Orders and Factions") },
	{ key = "event", label = N("Events and Wars") },
	{ key = "structure", label = N("Structures and Constructions") },
	{ key = "artifact", label = N("Artifacts and Relics") },
	{ key = "force", label = N("Forces and Magic") },
	{ key = "mechanism", label = N("Mechanisms and Devices") },
	{ key = "creature", label = N("Creatures") },
	{ key = "concept", label = N("Customs and Knowledge") },
}

function Lore.CategoryOf(entry)
	for _, cat in ipairs(Lore.CATEGORIES) do
		if cat.test then
			if cat.test(entry) then return cat end
		elseif entry.kind == "topic" and entry.category == cat.key then
			return cat
		end
	end
end

-- Entries of a category, A to Z.
function Lore.InCategory(key)
	local out = {}
	for _, entry in ipairs(Lore.order) do
		local cat = Lore.CategoryOf(entry)
		if cat and cat.key == key then out[#out + 1] = entry end
	end
	table.sort(out, function(a, b) return a.title < b.title end)
	return out
end

-- Entries whose title or alias contains the text, A to Z.
function Lore.Search(text)
	local out, needle = {}, (text or ""):lower()
	for _, entry in ipairs(Lore.order) do
		local hit = entry.kind ~= "book" and (needle == "" or entry.title:lower():find(needle, 1, true))
		for _, alias in ipairs(entry.aliases or {}) do
			if entry.kind ~= "book" and alias:lower():find(needle, 1, true) then hit = true end
		end
		if hit then out[#out + 1] = entry end
	end
	table.sort(out, function(a, b) return a.title < b.title end)
	return out
end

function Lore.HasRule(entry, ruleType)
	for _, rule in ipairs(entry.unlock or {}) do
		if rule.type == ruleType then return true end
	end
	return false
end

function Lore.Get(id) return Lore.entries[id] end
function Lore.Part(key) return Lore.parts[key] end

function Lore.FiguresOf(regionID)
	return Lore.regionFigures[regionID] or {}
end

function Lore.PlacesOf(regionID)
	return Lore.regionPlaces[regionID] or {}
end

function Lore.TopicsOf(regionID)
	return Lore.regionTopics[regionID] or {}
end

-- The region an entry belongs to: a figure's region or a place's parent.
function Lore.Owner(entry)
	return Lore.Get(entry.region or entry.parent)
end

-- Regions grouped by continent, in load order.
function Lore.Continents()
	local out, byName = {}, {}
	for _, entry in ipairs(Lore.order) do
		if entry.kind == "region" and not entry.parent then
			local name = entry.continent or "Other"
			local group = byName[name]
			if not group then
				group = { name = name, regions = {} }
				byName[name] = group
				out[#out + 1] = group
			end
			table.insert(group.regions, entry)
		end
	end
	return out
end

-- Figures with lore for a creature ID.
function Lore.FiguresForNpc(npcID)
	local out = {}
	if not npcID then return out end
	for _, entry in ipairs(Lore.order) do
		if entry.npc then
			for _, id in ipairs(entry.npc) do
				if id == npcID then out[#out + 1] = entry end
			end
		end
	end
	return out
end

-- The hint shown while an entry is still locked.
function Lore.Hint(entry)
	if entry.hint then return entry.hint end
	local rule = entry.unlock and entry.unlock[1]
	local t = rule and rule.type
	if entry.kind == "region" and entry.parent then
		local owner = Lore.Get(entry.parent)
		if owner then return string.format(ns.T("Find %s in %s."), entry.title, owner.title) end
		return string.format(ns.T("Find %s."), entry.title)
	end
	if entry.kind == "region" then return string.format(ns.T("Travel to %s to uncover its history."), entry.title) end
	if t == "interact" then return string.format(ns.T("Speak with %s."), entry.title) end
	if t == "target" then return string.format(ns.T("Face %s."), entry.title) end
	if t == "read" then return ns.T("Follow a reference to this page from lore you already know.") end
	return ns.T("Not yet discovered.")
end
