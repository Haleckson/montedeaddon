--[[
  Forever Companion - Data/Query.lua
  Search and filtering for the journal.

  Text syntax (all parts optional, combined with AND):
    rare ashenvale          plain words match anywhere (title, zone, type, tags,
                            author, profession, items, notes, dungeon)
    "hidden door"           quoted phrase
    type:vendor  t:rare     discovery type (key or label)
    zone:feralas  z:...     zone or subzone
    by:gingasul             discoverer (also discovered:, author:)
    tag:important  #weird   tag
    prof:engineering        profession
    in:deadmines            dungeon / instance name
    is:fav is:verified is:guild is:mine is:archived is:private is:secret is:rumored is:new

  Filter specs come from the UI (page, chips, filter panel, the Progress
  page's "found by" characters) and are merged
  with the parsed text. Haystacks are cached per record and invalidated by
  bus messages, so typing in the search box never rebuilds all strings.
]]

local _, FC = ...

local Query = FC:NewModule("Query")

local U = FC.Utils
local L = FC.L
local Categories = FC.Categories
local lower, find = string.lower, string.find

local haystacks = {}

function Query:OnInitialize()
    local Bus = FC.Bus
    local function forget(_, rec) if type(rec) == "table" then haystacks[rec.id] = nil end end
    local function forgetID(_, id) haystacks[id] = nil end
    Bus:On("DISCOVERY_UPDATED", self, forget)
    Bus:On("DISCOVERY_STATE", self, forgetID)
    Bus:On("DISCOVERY_REMOVED", self, forgetID)
    Bus:On("STORE_RESET", self, function() wipe(haystacks) end)
    Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^knowledge") then wipe(haystacks) end
    end)
end

local function add(parts, value)
    if type(value) == "string" and value ~= "" then parts[#parts + 1] = value end
end

--- Lowercased searchable text of a record. Rumored records expose only their
--- type and zone, so searching cannot leak what the veil hides.
function Query:Haystack(rec)
    local cached = haystacks[rec.id]
    if cached then return cached end
    local parts = {}
    local def = Categories:Get(rec.t)
    add(parts, rec.t)
    add(parts, L[def.label])
    add(parts, rec.z)
    add(parts, rec.sz)
    if not FC.Store:IsRumored(rec) then
        add(parts, rec.n)
        add(parts, rec.d)
        add(parts, rec.a)
        add(parts, U.ShortName(rec.a))
        add(parts, rec.inn)
        add(parts, rec.src)
        add(parts, rec.gv)
        if rec.pr then add(parts, L[Categories:Profession(rec.pr).label]) end
        for _, tag in ipairs(FC.Store:AllTags(rec)) do add(parts, tag) end
        if rec.inv then
            for _, item in ipairs(rec.inv) do add(parts, item.n) end
        end
        if rec.gn then
            for _, note in ipairs(rec.gn) do add(parts, note.x) end
        end
        if rec.ver then
            for name in pairs(rec.ver) do add(parts, name) end
        end
        local state = FC.Store:GetState(rec.id)
        if state then add(parts, state.note) end
    end
    cached = lower(table.concat(parts, "\n"))
    haystacks[rec.id] = cached
    return cached
end

------------------------------------------------------------------------
-- Parsing
------------------------------------------------------------------------

local KEY_ALIASES = {
    type = "type", t = "type",
    zone = "zone", z = "zone",
    by = "author", discovered = "author", author = "author", a = "author",
    tag = "tag",
    prof = "prof", profession = "prof",
    ["in"] = "instance", dungeon = "instance",
    is = "is",
}

local function resolveType(value)
    if Categories:IsValid(value) then return value end
    for _, key in ipairs(Categories.order) do
        local label = lower(L[Categories:Get(key).label])
        if find(label, value, 1, true) then return key end
    end
    return nil
end

local function resolveProfession(value)
    for _, p in ipairs(Categories.PROFESSIONS) do
        if p.key == value or find(lower(L[p.label]), value, 1, true) then return p.key end
    end
    return nil
end

--- Parses search text into a structured query.
function Query:Parse(text)
    local q = { terms = {}, is = {} }
    if type(text) ~= "string" then return q end
    text = lower(U.Trim(text))
    if text == "" then return q end

    local tokens = {}
    text = text:gsub('"([^"]*)"', function(phrase)
        tokens[#tokens + 1] = U.Trim(phrase)
        return " "
    end)
    for word in text:gmatch("%S+") do tokens[#tokens + 1] = word end

    for _, token in ipairs(tokens) do
        local key, value = token:match("^(%a+):(.+)$")
        local alias = key and KEY_ALIASES[key]
        if token:sub(1, 1) == "#" and #token > 1 then
            q.tag = token:sub(2)
        elseif alias == "type" then
            q.type = resolveType(value)
            if not q.type then q.impossible = true end
        elseif alias == "zone" then
            q.zone = value
        elseif alias == "author" then
            q.author = value
        elseif alias == "tag" then
            q.tag = value
        elseif alias == "prof" then
            q.prof = resolveProfession(value)
            if not q.prof then q.impossible = true end
        elseif alias == "instance" then
            q.instance = value
        elseif alias == "is" then
            q.is[value] = true
        elseif token ~= "" then
            q.terms[#q.terms + 1] = token
        end
    end
    return q
end

------------------------------------------------------------------------
-- Matching
------------------------------------------------------------------------

local function containsLower(value, needle)
    return type(value) == "string" and find(lower(value), needle, 1, true) ~= nil
end

local function matchesTag(rec, tag)
    for _, t in ipairs(FC.Store:AllTags(rec)) do
        if find(t, tag, 1, true) then return true end
    end
    return false
end

local function matchesIs(rec, status, flags)
    local state = FC.Store:GetState(rec.id)
    for flag in pairs(flags) do
        if flag == "fav" or flag == "favorite" then
            if not status.favorite then return false end
        elseif flag == "verified" then
            if not status.verified then return false end
        elseif flag == "guild" then
            if status.mine then return false end
        elseif flag == "mine" or flag == "personal" then
            if not status.personal then return false end
        elseif flag == "archived" then
            if not status.archived then return false end
        elseif flag == "private" then
            if not status.private then return false end
        elseif flag == "secret" then
            if Categories:Get(rec.t).group ~= "secrets" then return false end
        elseif flag == "rumored" then
            if not status.rumored then return false end
        elseif flag == "new" then
            local _, at = FC.Store:Credit(rec)
            if rec.rcv or (at or 0) < U.Now() - 86400 then return false end
        elseif flag == "done" then
            -- turned in by any of your characters, also while the addon was away
            local done = state and state.done
            if not done and rec.t == "quest" and rec.q then done = FC.QuestHistory:CompletedByAny(rec.q) end
            if not done then return false end
        elseif flag == "recovered" then
            if not rec.rcv then return false end
        end
    end
    return true
end

local function typeAllowed(rec, spec, parsed)
    if parsed.type and rec.t ~= parsed.type then return false end
    if spec.types then return spec.types[rec.t] == true end
    return true
end

--- True if the record passes the UI filter spec and the parsed text.
function Query:Matches(rec, spec, parsed)
    if parsed.impossible then return false end
    if not FC.Store:IsKnown(rec) then return false end
    if not typeAllowed(rec, spec, parsed) then return false end

    local status = FC.Store:GetStatus(rec)
    local archivedMode = spec.archived or (FC.Config:Get("journal.showArchived") and "include" or "hide")
    if parsed.is.archived then archivedMode = "only" end
    if archivedMode == "hide" and status.archived then return false end
    if archivedMode == "only" and not status.archived then return false end

    if spec.scope == "mine" and not status.personal then return false end
    if spec.scope == "guild" and status.mine then return false end
    if spec.verified and not status.verified then return false end
    if spec.favorites and not status.favorite then return false end
    if spec.favoriteGroup then
        local state = FC.Store:GetState(rec.id)
        if not (state and state.fg == spec.favoriteGroup) then return false end
    end
    if spec.profession and rec.pr ~= spec.profession then return false end
    if spec.zone and rec.z ~= spec.zone then return false end
    if spec.author and rec.a ~= spec.author then return false end
    if spec.foundBy and not FC.Progress:FoundByAny(rec, spec.foundBy) then return false end
    if spec.since then
        local _, at = FC.Store:Credit(rec)
        if (at or 0) < spec.since then return false end
    end
    if spec.parent and rec.pa ~= spec.parent then return false end

    if parsed.prof and rec.pr ~= parsed.prof then return false end
    if parsed.zone and not (containsLower(rec.z, parsed.zone) or containsLower(rec.sz, parsed.zone)) then return false end
    if parsed.author and not containsLower(rec.a, parsed.author) then return false end
    if parsed.instance and not containsLower(rec.inn, parsed.instance) then return false end
    if parsed.tag and not matchesTag(rec, parsed.tag) then return false end
    if next(parsed.is) and not matchesIs(rec, status, parsed.is) then return false end

    if #parsed.terms > 0 then
        local hay = self:Haystack(rec)
        for _, term in ipairs(parsed.terms) do
            if not find(hay, term, 1, true) then return false end
        end
    end
    return true
end

-- when each result was found, as the journal tells it (filled by Query:Run)
local foundTime = {}

-- recovered entries (read back from the game) have no date of their own:
-- they come after everything that was found while the journal watched
local function foundAt(rec)
    if rec.rcv then return 0 end
    return foundTime[rec.id] or rec.c
end

local SORTERS = {
    recent = function(a, b)
        local at, bt = foundAt(a), foundAt(b)
        if at ~= bt then return at > bt end
        return a.id < b.id
    end,
    updated = function(a, b)
        if a.u ~= b.u then return a.u > b.u end
        return a.id < b.id
    end,
    name = function(a, b)
        local an, bn = lower(a.n or ""), lower(b.n or "")
        if an ~= bn then return an < bn end
        return a.id < b.id
    end,
    zone = function(a, b)
        local az, bz = lower(a.z or "~"), lower(b.z or "~")
        if az ~= bz then return az < bz end
        return lower(a.n or "") < lower(b.n or "")
    end,
    type = function(a, b)
        if a.t ~= b.t then return a.t < b.t end
        return lower(a.n or "") < lower(b.n or "")
    end,
    verified = function(a, b)
        local av, bv = U.Count(a.ver), U.Count(b.ver)
        if av ~= bv then return av > bv end
        return a.c > b.c
    end,
}
Query.SORTS = { "recent", "updated", "name", "zone", "type", "verified" }

--- Runs a query. Returns an array of records.
function Query:Run(spec, text)
    spec = spec or {}
    local parsed = self:Parse(text)
    local results = {}
    for _, rec in FC.Store:Iterate() do
        if self:Matches(rec, spec, parsed) then
            results[#results + 1] = rec
        end
    end
    -- per character, "newest first" means what this character found last
    wipe(foundTime)
    if FC.Store:PerCharacter() then
        for _, rec in ipairs(results) do
            local _, at = FC.Store:Credit(rec)
            foundTime[rec.id] = at
        end
    end
    table.sort(results, SORTERS[spec.sort or "recent"] or SORTERS.recent)
    return results, parsed
end

--- Distinct values for filter dropdowns (zones and authors in the store).
function Query:DistinctValues(field)
    local seen, list = {}, {}
    for _, rec in FC.Store:Iterate() do
        local value = rec[field]
        if value and not seen[value] and FC.Store:IsKnown(rec) then
            seen[value] = true
            list[#list + 1] = value
        end
    end
    table.sort(list)
    return list
end
