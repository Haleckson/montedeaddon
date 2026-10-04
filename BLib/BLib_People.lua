-- BLib_People.lua
-- Other players, keyed by GUID: one store for every addon that remembers people.
--
-- Met Before, Officer's Desk, Raidmaster and Chronicle each want to know who
-- somebody is. Built four times, that is four stores that disagree -- and each
-- would be tempted into the one mistake Forever makes easy: keying on a name.
--
-- FIRST NAMES COLLIDE ON FOREVER, BY DESIGN. There is no realm; every
-- character has a surname instead, and it is the pair that is unique, not the
-- first name (measured 2026-09-19). The surname is also missing from much of
-- what an addon is handed: UnitName gives another player's first name alone,
-- chat links show first names (the surname survives only in the link target),
-- and from build 70009 even your own UnitName comes back in two halves. So a
-- record is keyed by GUID, the first name and the surname are separate
-- fields, and a first name on its own is a question with several answers,
-- never a key.
--
--   BLib.People:Get(guid)                    the record, or nil
--   BLib.People:Update(guid, fields)         merge fields, creating the record
--   BLib.People:FindByName(name)             GUIDs, most recently seen first
--   BLib.People:UpdateFromUnit(unit, extra)  read a unit and Update from it
--
-- A record: first, surname, class (UnitClass's file name, the same in every
-- locale), level, firstSeen, lastSeen (server time), where, notes (the
-- player's own words, shared by every addon that shows them).
--
-- Kept in BLibDB.people, account-wide, created by the first write and not
-- before. Reading a store that was never written finds nothing and creates
-- nothing.

BLib = BLib or {}
BLib.People = {}
local P = BLib.People

local STORE_VERSION = 1

local IsSecret = issecretvalue or function(_) return false end

-- Between first name and surname: " " on Forever, read from build 70009's
-- Constants on 2026-09-25.
local SEPARATOR = Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR
if type(SEPARATOR) ~= "string" or SEPARATOR == "" then SEPARATOR = " " end

-- ============================================================
-- HELPERS
-- ============================================================

-- The value, or nil if it is a secret. A secret is never stored or compared:
-- not even with nil, so it is tested first.
local function Readable(value)
    if IsSecret(value) or value == nil then return nil end
    return value
end

-- Server time, so records written on different machines sort together.
local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function Yes(fn)
    if type(fn) ~= "function" then return false end
    local ok, value = pcall(fn)
    return ok and not IsSecret(value) and value == true
end

-- Whether a unit's second name is a SURNAME. The API dump calls UnitName's
-- second return the server, and on retail it is; Forever's own NameUtil joins
-- it on as the surname. ShouldDisplaySurname read true on Forever
-- (2026-09-19); RegionalUniqueNamesEnabled is what Blizzard's chat box asks,
-- and has not been measured here.
local function SurnamesInUse()
    return Yes(C_PlayerInfo and C_PlayerInfo.ShouldDisplaySurname)
        or Yes(RegionalUniqueNamesEnabled)
end

-- "First Surname" -> "First", "Surname"; "First" -> "First", nil. Blizzard's
-- chat box also takes "First-Surname" where surnames are in use; anywhere
-- else the hyphen starts a realm, which is dropped.
local function SplitName(name)
    name = Readable(name)
    if type(name) ~= "string" then return nil end
    name = string.match(name, "^%s*(.-)%s*$")

    local first, surname
    local at, stop = string.find(name, SEPARATOR, 1, true)
    if at then
        first, surname = string.sub(name, 1, at - 1), string.sub(name, stop + 1)
    else
        local dash = string.find(name, "-", 1, true)
        if dash then
            first = string.sub(name, 1, dash - 1)
            if SurnamesInUse() then surname = string.sub(name, dash + 1) end
        else
            first = name
        end
    end

    if first == "" then return nil end
    if surname == "" then surname = nil end
    return first, surname
end

-- A unit's first name and surname. UnitNameUnmodified is what Forever's
-- NameUtil joins for Blizzard's own full names; its second value only counts
-- as a surname where surnames are in use. "Unknown" is a name not loaded
-- yet, and is refused rather than filed.
local function UnitNames(unit)
    local read = UnitNameUnmodified or UnitName
    if type(read) ~= "function" then return nil end
    local ok, first, second = pcall(read, unit)
    if not ok then return nil end
    first, second = Readable(first), Readable(second)
    if type(first) ~= "string" or first == "" or first == UNKNOWNOBJECT then return nil end
    if type(second) == "string" and second ~= "" and SurnamesInUse() then
        return first, second
    end
    -- One string holding both, as the player's own name did before 70009.
    return SplitName(first)
end

-- ============================================================
-- THE STORE
-- ============================================================

local function Store()
    local people = type(BLibDB) == "table" and BLibDB.people
    if type(people) == "table" and type(people.records) == "table" then return people end
    return nil
end

-- Only ever called by a write. Something else already under the key is left
-- alone and reported, rather than replaced by an empty store.
local function CreateStore()
    if type(BLibDB) ~= "table" then return nil, "BLibDB is not loaded yet" end
    local people = BLibDB.people
    if people == nil then
        people = { version = STORE_VERSION, records = {} }
        BLibDB.people = people
    elseif type(people) ~= "table" or type(people.records) ~= "table" then
        return nil, "BLibDB.people holds something else; left alone"
    end
    return people
end

-- What Update accepts. `name` is "First Surname" (or a first name), split on
-- the way in; `first` is taken the same way and wins over `name`.
local function IsText(v) return type(v) == "string" and v ~= "" end
local function IsTime(v) return type(v) == "number" and v > 0 end

local FIELDS = {
    name      = IsText,
    first     = IsText,
    surname   = IsText,
    class     = IsText,
    level     = function(v) return type(v) == "number" and v >= 1 and v % 1 == 0 end,
    where     = IsText,
    notes     = function(v) return type(v) == "string" or v == false end,
    firstSeen = IsTime,
    lastSeen  = IsTime,
}

-- ============================================================
-- THE NAME INDEX
--
-- Lower-case first name -> set of GUIDs, built on the first lookup rather than
-- at load, and kept in step by Update. Session-only: it is derived from the
-- records, so saving it would only give it a way to be wrong. A search per
-- chat line must not walk every record; a tooltip once did that in BQL, and
-- the stutter was measured at 10ms a frame.
-- ============================================================

local index   = nil
local indexOf = nil   -- the records table the index describes

local function Unindex(guid, first)
    local set = index and type(first) == "string" and index[string.lower(first)]
    if set then set[guid] = nil end
end

local function Reindex(guid, first)
    if not index or type(first) ~= "string" then return end
    local key = string.lower(first)
    index[key] = index[key] or {}
    index[key][guid] = true
end

local function IndexOf(records)
    if index and indexOf == records then return index end
    index, indexOf = {}, records
    for guid, record in pairs(records) do
        if type(record) == "table" then Reindex(guid, record.first) end
    end
    return index
end

-- ============================================================
-- API
-- ============================================================

-- The stored record, not a copy: read it freely, change it only through
-- Update, which keeps the index true.
function P:Get(guid)
    if IsSecret(guid) or type(guid) ~= "string" then return nil end
    local store = Store()
    return store and store.records[guid]
end

-- Merges fields into guid's record, creating it (and the store) if needed.
-- A value left out is left alone: nil never erases. notes = "" or false
-- clears the notes. firstSeen only moves earlier and lastSeen only later, so
-- the same sighting merged twice, or merged late, changes nothing.
-- Returns the record, or nil and why nothing was written.
function P:Update(guid, fields)
    guid = Readable(guid)
    if type(guid) ~= "string" or not string.find(guid, "^Player%-") then
        return nil, "not a player GUID"
    end
    if type(fields) ~= "table" then return nil, "fields must be a table" end

    -- Everything is checked before anything is written, so a refused update
    -- leaves no trace: not a half-written record, not even an empty store.
    for key, value in pairs(fields) do
        local check = FIELDS[key]
        if not check then return nil, "unknown field " .. tostring(key) end
        if IsSecret(value) then return nil, tostring(key) .. " is a secret" end
        if not check(value) then return nil, "bad value for " .. tostring(key) end
    end

    local first, surname = fields.first or fields.name, fields.surname
    if first then
        local splitFirst, splitSurname = SplitName(first)
        first, surname = splitFirst, surname or splitSurname
    end

    local store = Store()
    local record = store and store.records[guid]
    if not record and not first then return nil, "a new record needs a name" end
    if not store then
        local made, why = CreateStore()
        if not made then return nil, why end
        store = made
    end

    if not record then
        local start = fields.firstSeen or fields.lastSeen or Now()
        record = { firstSeen = start, lastSeen = start }
        store.records[guid] = record
    end

    local oldFirst = record.first
    if first then record.first = first end
    if surname then record.surname = surname end
    if fields.class then record.class = fields.class end
    if fields.level then record.level = fields.level end
    if fields.where then record.where = fields.where end
    if fields.notes ~= nil then
        record.notes = (fields.notes ~= "" and fields.notes) or nil
    end
    if fields.firstSeen and fields.firstSeen < (record.firstSeen or math.huge) then
        record.firstSeen = fields.firstSeen
    end
    if fields.lastSeen and fields.lastSeen > (record.lastSeen or 0) then
        record.lastSeen = fields.lastSeen
    end

    if index and indexOf == store.records and record.first ~= oldFirst then
        Unindex(guid, oldFirst)
        Reindex(guid, record.first)
    end
    return record
end

-- "First Surname" (or "First-Surname") finds that character exactly; a first
-- name alone finds everyone recorded under it, which on Forever can be
-- several people. A record whose surname was never learned matches only the
-- first-name search. Case does not matter. Returns a list of GUIDs, most
-- recently seen first, possibly empty.
function P:FindByName(name)
    local found = {}
    local first, surname = SplitName(name)
    local store = Store()
    if not (first and store) then return found end

    local records = store.records
    local set = IndexOf(records)[string.lower(first)]
    if not set then return found end

    local wantFirst   = string.lower(first)
    local wantSurname = surname and string.lower(surname)
    for guid in pairs(set) do
        local record = records[guid]
        if type(record) == "table" and type(record.first) == "string"
            and string.lower(record.first) == wantFirst
            and (not wantSurname or (type(record.surname) == "string"
                and string.lower(record.surname) == wantSurname)) then
            found[#found + 1] = guid
        end
    end

    table.sort(found, function(a, b)
        return (tonumber(records[a].lastSeen) or 0) > (tonumber(records[b].lastSeen) or 0)
    end)
    return found
end

-- Reads a player unit -- a group member, target or mouseover -- and records
-- it as seen now, here. `where` is where YOU are, which for a party member
-- across the world is not where they are; pass extra.where to say otherwise.
-- `extra` is merged in as more fields (notes, say). Anything that reads back
-- secret is left out rather than stored.
function P:UpdateFromUnit(unit, extra)
    if type(unit) ~= "string" or not (UnitExists and UnitIsPlayer and UnitGUID) then
        return nil, "no unit"
    end
    local okExists, exists = pcall(UnitExists, unit)
    if not okExists or IsSecret(exists) or not exists then return nil, "no such unit" end
    local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
    if not okPlayer or IsSecret(isPlayer) or not isPlayer then return nil, "not a player" end

    local okGuid, guid = pcall(UnitGUID, unit)
    guid = okGuid and Readable(guid)
    if not guid then return nil, "the GUID is not readable" end
    local okMe, myGuid = pcall(UnitGUID, "player")
    if okMe and guid == Readable(myGuid) then return nil, "that is you" end

    local first, surname = UnitNames(unit)
    if not first then return nil, "the name is not readable" end

    local fields = { first = first, surname = surname, lastSeen = Now() }

    local okClass, _, classFile = pcall(UnitClass, unit)
    classFile = okClass and Readable(classFile)
    if IsText(classFile) then fields.class = classFile end

    local okLevel, level = pcall(UnitLevel, unit)
    level = okLevel and Readable(level)
    if FIELDS.level(level) then fields.level = level end

    local zone = GetRealZoneText and Readable(GetRealZoneText())
    if IsText(zone) then fields.where = zone end

    if type(extra) == "table" then
        for key, value in pairs(extra) do fields[key] = value end
    end
    return self:Update(guid, fields)
end
