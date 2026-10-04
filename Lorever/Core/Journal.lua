local _, ns = ...

-- The reader's own marks on the book: favorite pages and a note on a page.
-- Kept in LoreverDB on the reader's computer, shared by their characters.
-- Nothing here leaves the computer (COMPLIANCE.md, R10).

local Journal = {}
ns.Journal = Journal

local Lore = ns.Lore

Journal.NOTE_MAX = 500

local function favorites()
	ns.db.favorites = ns.db.favorites or {}
	return ns.db.favorites
end

local function notes()
	ns.db.notes = ns.db.notes or {}
	return ns.db.notes
end

function Journal.IsFavorite(id)
	return favorites()[id] ~= nil
end

function Journal.ToggleFavorite(id)
	local f = favorites()
	if f[id] then f[id] = nil else f[id] = time() end
	ns.Fire("FL_JOURNAL", id)
	return f[id] ~= nil
end

-- Favorite pages that still exist, A to Z.
function Journal.Favorites()
	local out = {}
	for id in pairs(favorites()) do
		local entry = Lore.Get(id)
		if entry then out[#out + 1] = entry end
	end
	table.sort(out, function(a, b) return a.title < b.title end)
	return out
end

function Journal.Note(id)
	return notes()[id]
end

-- An empty note removes it.
function Journal.SetNote(id, text)
	-- No "|": the game reads it as the start of a color or link code.
	text = type(text) == "string" and text:gsub("|", ""):gsub("^%s+", ""):gsub("%s+$", "") or ""
	if #text > Journal.NOTE_MAX then
		-- Cut between letters, never inside one (a letter can be several bytes).
		local n = Journal.NOTE_MAX
		while n > 0 do
			local b = text:byte(n + 1)
			if not b or b < 128 or b >= 192 then break end
			n = n - 1
		end
		text = text:sub(1, n)
	end
	notes()[id] = text ~= "" and text or nil
	ns.Fire("FL_JOURNAL", id)
end
