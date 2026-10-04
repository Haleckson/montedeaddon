local _, ns = ...

-- Discovery state, Lore experience and Lore level.
-- The level has no cap. XP is always recounted from what is unlocked, so
-- new lore added in a later version simply adds more XP to earn.

local P = {}
ns.Progress = P

local Lore = ns.Lore
local floor = math.floor

-- XP needed to go from `level` to `level + 1`.
-- Level 1 -> 2 needs 100, then each level a little more:
-- 100, 130, 155, 180, 205 ... level 10: 310 ... level 20: 500 ... level 40: 825
-- Total XP to reach: level 6 = 770, level 11 = 2120, level 21 = 6290, level 41 = 19775
function P.Need(level)
	return 5 * floor((60 + 40 * level ^ 0.8) / 5 + 0.5)
end

-- Returns level, xp into this level, xp needed for the next level.
function P.LevelFor(totalXP)
	local level, rest = 1, totalXP
	while true do
		local need = P.Need(level)
		if rest < need then return level, rest, need end
		rest = rest - need
		level = level + 1
	end
end

local function charStore()
	local key = ns.U.CharKey()
	local c = ns.db.chars[key]
	if not c then
		c = { unlocked = {} }
		ns.db.chars[key] = c
	end
	c.unlocked = c.unlocked or {}
	return c
end

-- The set the player sees: the account or this character.
local function view()
	if ns.db.settings.accountWide then return ns.db.account.unlocked end
	return charStore().unlocked
end

-- Really discovered by the player.
function P.IsFound(key)
	return view()[key] ~= nil
end

-- Shown as discovered: really found, or everything while the showcase is on.
-- The showcase is a tool for the project (the narration generator reads every
-- page with it). Nothing turns it on in the game. It writes nothing: the
-- real progress stays untouched.
function P.IsUnlocked(key)
	return view()[key] ~= nil or (ns.db.showcase == true and Lore.Part(key) ~= nil)
end

function P.SetShowcase(on)
	ns.db.showcase = on and true or nil
	P.Invalidate()
	ns.Fire("FL_SETTINGS_CHANGED", "showcase")
end

local cachedXP = {}
function P.TotalXP(pool)
	pool = pool or "lore"
	if cachedXP[pool] then return cachedXP[pool] end
	local total = 0
	if ns.db.showcase then
		for _, part in pairs(Lore.parts) do
			if part.pool == pool then total = total + part.xp end
		end
	else
		for key in pairs(view()) do
			local part = Lore.Part(key)
			if part and part.pool == pool then total = total + part.xp end
		end
	end
	cachedXP[pool] = total
	return total
end

function P.Level(pool)
	return P.LevelFor(P.TotalXP(pool))
end

function P.Invalidate()
	wipe(cachedXP)
end

-- Unlocks a part. `quiet` skips toasts (used when catching up at login).
-- Unlocking a chapter or a mention also unlocks its entry, and unlocking a
-- figure also unlocks its region: you cannot learn of a man without
-- learning where he stands.
-- Returns the XP gained (0 when nothing new).
function P.Unlock(key, quiet)
	local part = Lore.Part(key)
	if not part or P.IsFound(key) then return 0 end
	local pool = part.pool
	local levelBefore = P.Level(pool)

	-- The part, then what it implies: its entry, then the figure's region.
	local chain = { part }
	local entry = part.entry
	if part.kind ~= "base" then chain[#chain + 1] = entry.basePart end
	-- Books stay in their own progression: reading one opens no lore page.
	local owner = entry.kind ~= "book" and Lore.Owner(entry)
	if owner then
		chain[#chain + 1] = owner.basePart
		local top = Lore.Owner(owner) -- a place inside a place
		if top then chain[#chain + 1] = top.basePart end
	end

	local now, newly, gained = time(), {}, 0
	local account, char = ns.db.account.unlocked, charStore().unlocked
	for _, p in ipairs(chain) do
		if not P.IsFound(p.key) then
			account[p.key] = account[p.key] or now
			char[p.key] = char[p.key] or now
			newly[#newly + 1] = p
			gained = gained + p.xp
		end
	end
	P.Invalidate()

	-- Announce in story order: region, entry, then the part itself.
	for i = #newly, 1, -1 do
		ns.Fire("FL_UNLOCKED", newly[i], newly[i].xp, quiet)
	end
	local levelAfter = P.Level(pool)
	if levelAfter > levelBefore then ns.Fire("FL_LEVEL_UP", levelAfter, levelBefore, quiet, pool) end
	return gained
end

function P.UnlockAll(parts, quiet)
	local gained = 0
	for _, part in ipairs(parts or {}) do gained = gained + P.Unlock(part.key, quiet) end
	return gained
end

-- Unlocked parts / all parts of an entry.
function P.EntryProgress(entry)
	local done = 0
	for _, key in ipairs(entry.partKeys) do
		if P.IsUnlocked(key) then done = done + 1 end
	end
	return done, #entry.partKeys
end

-- Discovered entries / all entries of a pool ("lore" or "books").
function P.Totals(pool)
	pool = pool or "lore"
	local found, total = 0, 0
	for _, entry in ipairs(Lore.order) do
		if Lore.PoolOf(entry) == pool then
			total = total + 1
			if P.IsUnlocked(entry.id) then found = found + 1 end
		end
	end
	return found, total
end

-- Share of a region already uncovered, 0..100 (the "fog" of a zone):
-- the region's own parts plus its places, figures and topics.
function P.RegionPercent(region)
	local found, total = P.RegionProgress(region)
	local done, parts = P.EntryProgress(region)
	found, total = found + done, total + parts
	if total == 0 then return 0 end
	return math.floor(found * 100 / total + 0.5)
end

-- Regions: figures and places discovered / listed.
function P.RegionProgress(region)
	local found, total = 0, 0
	for _, list in ipairs({ Lore.FiguresOf(region.id), Lore.PlacesOf(region.id), Lore.TopicsOf(region.id) }) do
		for _, entry in ipairs(list) do
			total = total + 1
			if P.IsUnlocked(entry.id) then found = found + 1 end
		end
	end
	return found, total
end

-- "New" = unlocked but not yet opened in the panel.
function P.IsNew(key)
	return P.IsFound(key) and not ns.db.read[key]
end

function P.EntryHasNew(entry)
	for _, key in ipairs(entry.partKeys) do
		if P.IsNew(key) then return true end
	end
	return false
end

function P.MarkRead(entry)
	for _, key in ipairs(entry.partKeys) do
		if P.IsFound(key) then ns.db.read[key] = true end
	end
	ns.Fire("FL_READ", entry)
end

ns.Listen("FL_DB_READY", P.Invalidate)
