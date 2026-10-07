--[[
  Forever Companion - Data/DiscoveryStore.lua
  The single owner of discovery data.

    * validation of every record (SavedVariables, sync, import use the same code)
    * creation, author-only editing, retraction and personal deletion
    * merge rules for guild sync (revision, author, unions for verifications,
      guild notes and rare observations)
    * personal state (favorites, archive, notes, tags) kept apart from shared data
    * indexes by map, NPC, item, quest giver, parent and dedupe key, plus the
      items creatures were seen dropping and vendors were seen selling
    * derived status (personal / guild / verified / rumored)

  The store never touches frames and never sends messages. It emits bus
  messages and the UI, map and sync layers react:
    DISCOVERY_ADDED(rec, source)      DISCOVERY_UPDATED(rec, source)
    DISCOVERY_REMOVED(id, reason)     DISCOVERY_STATE(id)
    DISCOVERY_VERIFIED(rec, name, source)
    DISCOVERY_NOTE(rec, note, source) DISCOVERY_OBSERVATION(rec, kind, ts, source)
    DISCOVERY_RETRACTED(rec)          STORE_RESET()
  Sources: "local" (user action), "auto" (detector), "sync", "import", "dev".
]]

local _, FC = ...

local Store = FC:NewModule("Store")

local U = FC.Utils
local C = FC.C
local LIM = C.LIMITS
local Categories = FC.Categories
local floor = math.floor

------------------------------------------------------------------------
-- Field validators
------------------------------------------------------------------------

local function vString(maxLen)
    return function(v)
        if type(v) ~= "string" then return nil end
        v = U.CleanText(v, maxLen)
        if v == nil or v == "" then return nil end
        return v
    end
end

local function vInt(low, high)
    return function(v)
        if type(v) ~= "number" or v ~= v then return nil end
        v = floor(v)
        if v < low or v > high then return nil end
        return v
    end
end

local function vCoord(v)
    if type(v) ~= "number" or v ~= v or v < 0 or v > 1 then return nil end
    return U.Round(v, 4)
end

local function vTrue(v)
    if v == true then return true end
    return nil
end

local function vTime(v)
    if type(v) ~= "number" or v ~= v or v < 0 or v > 4102444800 then return nil end
    return floor(v)
end

local function vTags(v)
    if type(v) ~= "table" then return nil end
    local out, seen = {}, {}
    for i = 1, math.min(#v, LIM.TAGS) do
        local tag = type(v[i]) == "string" and U.CleanText(v[i]:lower(), LIM.TAG)
        if tag and tag ~= "" and not seen[tag] then
            seen[tag] = true
            out[#out + 1] = tag
        end
    end
    if #out == 0 then return nil end
    return out
end

local function vIcon(v)
    if type(v) == "number" and v > 0 and v == floor(v) then return v end
    if type(v) == "string" and #v <= 160 and v:match("^[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee][\\/][%w_%-\\/%.]+$") then
        return v
    end
    return nil
end

local function vHex(v)
    if U.IsValidHex(v) then return v:lower() end
    return nil
end

local function vVisibility(v)
    if v == "g" or v == "p" then return v end
    return nil
end

local function vType(v)
    if Categories:IsValid(v) then return v end
    if type(v) == "string" then return "other" end -- unknown type from a newer version
    return nil
end

local vName = vString(LIM.NAME)
local vItemID = vInt(1, 2147483647)

local function vInventory(v)
    if type(v) ~= "table" then return nil end
    local out = {}
    for i = 1, math.min(#v, LIM.INVENTORY) do
        local entry = v[i]
        if type(entry) == "table" then
            local itemID = vItemID(entry.i)
            if itemID then
                out[#out + 1] = {
                    i = itemID,
                    n = vName(entry.n),
                    l = vInt(-1, 100000)(entry.l),
                    rc = vTrue(entry.rc),
                    q = vInt(0, 8)(entry.q),
                }
            end
        end
    end
    if #out == 0 then return nil end
    return out
end

local function vTimeList(list, limit)
    if type(list) ~= "table" then return nil end
    local out = {}
    for i = 1, #list do
        local t = vTime(list[i])
        if t then out[#out + 1] = t end
    end
    table.sort(out)
    while #out > limit do table.remove(out, 1) end
    if #out == 0 then return nil end
    return out
end

local function vObservations(v)
    if type(v) ~= "table" then return nil end
    local deaths = vTimeList(v.d, LIM.OBSERVATIONS)
    local seen = vTimeList(v.s, LIM.OBSERVATIONS)
    if not deaths and not seen then return nil end
    return { d = deaths, s = seen }
end

-- A player is one name everywhere: the journal key ("First-Surname" on
-- Forever), also for verifications and notes that older versions filed under
-- the name an addon message came from ("First Surname-Realm").
local function vPlayer(v)
    local name = vName(v)
    return name and U.CharacterKey(name) or nil
end

local function vVerifiers(v)
    if type(v) ~= "table" then return nil end
    local out, count = {}, 0
    for name, ts in pairs(v) do
        local cleanName = vPlayer(name)
        local cleanTs = vTime(ts)
        if cleanName and cleanTs and (out[cleanName] or count < LIM.VERIFIERS) then
            if not out[cleanName] then count = count + 1 end
            out[cleanName] = math.min(out[cleanName] or cleanTs, cleanTs)
        end
    end
    if count == 0 then return nil end
    return out
end

local function vGuildNotes(v)
    if type(v) ~= "table" then return nil end
    local out = {}
    for i = 1, #v do
        local note = v[i]
        if type(note) == "table" then
            local a, t, x = vPlayer(note.a), vTime(note.t), vString(LIM.GUILD_NOTE)(note.x)
            if a and t and x then out[#out + 1] = { a = a, t = t, x = x } end
        end
    end
    table.sort(out, function(p, q) return p.t < q.t end)
    while #out > LIM.GUILD_NOTES do table.remove(out, 1) end
    if #out == 0 then return nil end
    return out
end

local function vIntList(limit, low, high)
    local check = vInt(low, high)
    return function(v)
        if type(v) ~= "table" then return nil end
        local out, seen = {}, {}
        for i = 1, #v do
            local value = check(v[i])
            if value and not seen[value] then
                seen[value] = true
                out[#out + 1] = value
                if #out >= limit then break end
            end
        end
        if #out == 0 then return nil end
        return out
    end
end

local vPoints = vIntList(C.DISCOVERY.MAX_POINTS, 0, 100010000)

local SPEC = {
    id = vString(LIM.ID),
    t = vType,
    n = vString(LIM.TITLE),
    d = vString(LIM.DESCRIPTION),
    m = vInt(1, 100000),
    x = vCoord,
    y = vCoord,
    z = vString(LIM.ZONE),
    sz = vString(LIM.ZONE),
    a = vName,
    c = vTime,
    u = vTime,
    r = vInt(1, 1000000),
    v = vVisibility,
    tg = vTags,
    ic = vIcon,
    col = vHex,
    npc = vInt(1, 2147483647),
    lvl = vInt(-1, 200),
    lx = vInt(-1, 200),
    ct = vString(24),
    cnt = vInt(1, 1000000),
    dr = vIntList(C.DISCOVERY.MAX_DROPS, 1, 2147483647),
    pts = vPoints,
    tr = vIntList(C.DISCOVERY.ROUTE_POINTS + 2, 0, 100010000),
    cls = vString(16),
    q = vInt(1, 2147483647),
    gv = vName,
    gvi = vInt(1, 2147483647),
    it = vItemID,
    iq = vInt(0, 8),
    pr = vString(24),
    sk = vInt(0, 1000),
    ["in"] = vInt(1, 2147483647),
    inn = vString(LIM.ZONE),
    pa = vString(LIM.ID),
    src = vString(LIM.NAME),
    inv = vInventory,
    obs = vObservations,
    ver = vVerifiers,
    gn = vGuildNotes,
    del = vTrue,
    dev = vTrue,
    -- recovered: read back from what the game remembers (an area explored
    -- before the journal watched). Its date is when the journal learned of
    -- it, so it is not "new" and not part of the recent activity.
    rcv = vTrue,
}
Store.SPEC = SPEC

-- Fields that belong to the author and change only through revisions.
local SHARED_FIELDS = {
    "t", "n", "d", "m", "x", "y", "z", "sz", "v", "tg", "ic", "col", "npc", "lvl", "lx", "ct", "cnt", "tr", "cls",
    "q", "gv", "gvi", "it", "iq", "pr", "sk", "in", "inn", "pa", "src", "inv", "del", "rcv",
}
Store.SHARED_FIELDS = SHARED_FIELDS

--- Validates a record. Returns true + cleaned copy, or false + reason.
function Store:Validate(rec)
    if type(rec) ~= "table" then return false, "not a table" end
    local clean = {}
    for key, check in pairs(SPEC) do
        local value = rec[key]
        if value ~= nil then
            clean[key] = check(value)
        end
    end
    if not clean.id then return false, "missing id" end
    if not clean.t then return false, "missing type" end
    if not clean.a then return false, "missing author" end
    if not clean.c or not clean.u or not clean.r then return false, "missing revision data" end
    if not clean.n and not clean.del then return false, "missing title" end
    if (clean.x == nil) ~= (clean.y == nil) then clean.x, clean.y = nil, nil end
    -- nobody confirms their own discovery
    if clean.ver and clean.ver[clean.a] then
        clean.ver[clean.a] = nil
        if next(clean.ver) == nil then clean.ver = nil end
    end
    clean.v = clean.v or "g"
    return true, clean
end

local STATE_SPEC = {
    fav = vTrue,
    fg = vString(24),
    arch = vTrue,
    hidden = vTrue,
    done = vTrue,
    note = vString(LIM.NOTE),
    tags = vTags,
    seen = vTime,
}

local function validateState(state)
    if type(state) ~= "table" then return nil end
    local clean = {}
    for key, check in pairs(STATE_SPEC) do
        if state[key] ~= nil then clean[key] = check(state[key]) end
    end
    if type(state.flags) == "table" then
        local flags, count = {}, 0
        for itemID, on in pairs(state.flags) do
            if vItemID(itemID) and on == true and count < LIM.INVENTORY then
                flags[itemID] = true
                count = count + 1
            end
        end
        if count > 0 then clean.flags = flags end
    end
    if next(clean) == nil then return nil end
    return clean
end

------------------------------------------------------------------------
-- Lifecycle and indexes
------------------------------------------------------------------------

function Store:OnInitialize()
    self.records = FC.db.discoveries
    self.state = FC.db.userState
    self.me = U.PlayerFullName()
    self.statsDirty = true
    self.feedDirty = true
    self:ValidateAll()
    self:RebuildIndexes()
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^knowledge") or path:find("^discovery%.verify") then
            self:MarkDirty()
        end
    end)
end

function Store:OnEnable()
    self.me = U.PlayerFullName()
    FC.db.myChars[self.me] = true
    -- what this character found used to live in its own SavedVariables; it is
    -- account-wide now, so every character's progress can be shown on any of them
    local found = self:FoundSet()
    for id, ts in pairs(FC.cdb.discovered) do
        if type(id) == "string" and type(ts) == "number" and (found[id] == nil or ts < found[id]) then found[id] = ts end
    end
    wipe(FC.cdb.discovered)
    -- what this character recorded, it found when it did: an entry written before
    -- that was kept (or one the guild gave back) is not a new find the next time
    -- the character comes across it
    for id, rec in pairs(self.records) do
        if rec.a == self.me and not rec.del and found[id] == nil then found[id] = rec.c or U.Now() end
    end
end

--- Drops invalid records and state entries. Returns the number removed.
function Store:ValidateAll()
    local removed = 0
    for id, rec in pairs(self.records) do
        local ok, clean = self:Validate(rec)
        if ok and clean.id == id then
            self.records[id] = clean
        else
            self.records[id] = nil
            removed = removed + 1
            FC.Log:Warn("Removed a damaged journal entry (%s): %s", tostring(id), tostring(clean))
        end
    end
    for id, state in pairs(self.state) do
        local clean = self.records[id] and validateState(state)
        self.state[id] = clean
    end
    local discovered = FC.cdb.discovered
    for id, ts in pairs(discovered) do
        if type(id) ~= "string" or type(ts) ~= "number" then discovered[id] = nil end
    end
    if removed > 0 then
        FC:Print(FC.L.MSG_REPAIRED_ENTRIES, removed)
    end
    return removed
end

local function addToSet(index, key, id)
    if key == nil then return end
    local set = index[key]
    if not set then
        set = {}
        index[key] = set
    end
    set[id] = true
end

local function removeFromSet(index, key, id)
    if key == nil then return end
    local set = index[key]
    if set then
        set[id] = nil
        if next(set) == nil then index[key] = nil end
    end
end

function Store:DedupeKey(rec)
    if not rec.id:find("^u:") then return nil end
    return table.concat({ rec.t, rec.m or 0, U.GridKey(rec.x, rec.y, C.DISCOVERY.OBJECT_GRID), U.NormalizeTitle(rec.n) }, "|")
end

function Store:Index(rec)
    if rec.del then return end
    local id = rec.id
    addToSet(self.byMap, rec.m, id)
    addToSet(self.byNpc, rec.npc, id)
    addToSet(self.byItem, rec.it, id)
    addToSet(self.children, rec.pa, id)
    if rec.t == "quest" then
        -- entries written before the giver's NPC ID was kept are found by name
        addToSet(self.byGiver, rec.gvi or (rec.gv and rec.gv:lower()), id)
    end
    for _, itemID in ipairs(rec.dr or {}) do addToSet(self.byDrop, itemID, id) end
    for _, item in ipairs(rec.inv or {}) do addToSet(self.bySold, item.i, id) end
    local key = self:DedupeKey(rec)
    if key then self.byDedupe[key] = id end
end

function Store:Unindex(rec)
    local id = rec.id
    removeFromSet(self.byMap, rec.m, id)
    removeFromSet(self.byNpc, rec.npc, id)
    removeFromSet(self.byItem, rec.it, id)
    removeFromSet(self.children, rec.pa, id)
    if rec.t == "quest" then removeFromSet(self.byGiver, rec.gvi or (rec.gv and rec.gv:lower()), id) end
    for _, itemID in ipairs(rec.dr or {}) do removeFromSet(self.byDrop, itemID, id) end
    for _, item in ipairs(rec.inv or {}) do removeFromSet(self.bySold, item.i, id) end
    local key = self:DedupeKey(rec)
    if key and self.byDedupe[key] == id then self.byDedupe[key] = nil end
end

function Store:RebuildIndexes()
    self.byMap, self.byNpc, self.byItem, self.children, self.byDedupe, self.byGiver = {}, {}, {}, {}, {}, {}
    self.byDrop, self.bySold = {}, {}
    for _, rec in pairs(self.records) do
        self:Index(rec)
    end
    self:MarkDirty()
end

function Store:MarkDirty()
    self.statsDirty = true
    self.feedDirty = true
    self.version = (self.version or 0) + 1
end

------------------------------------------------------------------------
-- Reading
------------------------------------------------------------------------

function Store:Get(id)
    local rec = self.records[id]
    if rec and not rec.del then return rec end
    return nil
end

function Store:GetRaw(id)
    return self.records[id]
end

--- Iterates live (non-retracted) records.
function Store:Iterate()
    local records = self.records
    local key
    return function()
        local rec
        repeat
            key, rec = next(records, key)
        until key == nil or not rec.del
        return key, rec
    end
end

function Store:ForMap(mapID)
    local set = self.byMap[mapID]
    local out = {}
    if set then
        for id in pairs(set) do
            local rec = self.records[id]
            if rec and not rec.del then out[#out + 1] = rec end
        end
    end
    return out
end

function Store:ForNpc(npcID)
    local out = {}
    local set = npcID and self.byNpc[npcID]
    if set then
        for id in pairs(set) do
            local rec = self:Get(id)
            if rec then out[#out + 1] = rec end
        end
    end
    return out
end

function Store:ForItem(itemID)
    local out = {}
    local set = itemID and self.byItem[itemID]
    if set then
        for id in pairs(set) do
            local rec = self:Get(id)
            if rec then out[#out + 1] = rec end
        end
    end
    return out
end

--- Creatures seen dropping an item, and vendors seen selling it.
function Store:ItemSources(itemID)
    local drops, sellers = {}, {}
    for id in pairs(itemID and self.byDrop[itemID] or {}) do
        local rec = self:Get(id)
        if rec then drops[#drops + 1] = rec end
    end
    for id in pairs(itemID and self.bySold[itemID] or {}) do
        local rec = self:Get(id)
        if rec then sellers[#sellers + 1] = rec end
    end
    local byName = function(a, b) return (a.n or "") < (b.n or "") end
    table.sort(drops, byName)
    table.sort(sellers, byName)
    return drops, sellers
end

--- Quest entries given by this NPC (by NPC ID, or by name for older entries).
function Store:QuestsByGiver(npcID, name)
    local out, seen = {}, {}
    for _, key in ipairs({ npcID or false, type(name) == "string" and name:lower() or false }) do
        for id in pairs(key and self.byGiver[key] or {}) do
            local rec = self:Get(id)
            if rec and not seen[id] and (key == npcID or not rec.gvi) then
                seen[id] = true
                out[#out + 1] = rec
            end
        end
    end
    return out
end

function Store:Children(id)
    local out = {}
    local set = self.children[id]
    if set then
        for childID in pairs(set) do
            local rec = self:Get(childID)
            if rec then out[#out + 1] = rec end
        end
    end
    table.sort(out, function(a, b) return (a.c or 0) < (b.c or 0) end)
    return out
end

------------------------------------------------------------------------
-- Status
------------------------------------------------------------------------

function Store:GetState(id)
    return self.state[id]
end

function Store:EnsureState(id)
    local state = self.state[id]
    if not state then
        state = {}
        self.state[id] = state
    end
    return state
end

function Store:IsMine(rec)
    return rec and FC.db.myChars[rec.a] == true or false
end

--- Progress per character (chosen at login, Settings > General): "personal"
--- then means found by the character you play, not by any of yours.
function Store:PerCharacter()
    return FC.db.progressMode == "character"
end

--- What a character of yours found, { [id] = time }; the one you play by default.
function Store:FoundSet(key)
    key = key or self.me
    local set = FC.db.found[key]
    if not set then
        set = {}
        FC.db.found[key] = set
    end
    return set
end

--- When a character of yours came across a discovery, or nil.
function Store:FoundAt(id, key)
    local set = FC.db.found[key or self.me]
    return set and set[id] or nil
end

--- Whether a character of yours found a discovery: it recorded it first, or
--- came across it later.
function Store:IsFoundBy(rec, key)
    key = key or self.me
    return rec.a == key or self:FoundAt(rec.id, key) ~= nil
end

function Store:IsPersonal(rec)
    if self:PerCharacter() then return self:IsFoundBy(rec) end
    if self:IsMine(rec) then return true end
    local state = self.state[rec.id]
    return state and state.seen ~= nil or false
end

--- Progress per character: a discovery only your other characters made. The
--- character you play does not know it; its journal starts as if it were
--- the first to use the addon (the Progress page still counts every character).
function Store:IsAltOnly(rec)
    return self:PerCharacter() and self:IsMine(rec) and not self:IsFoundBy(rec)
end

--- Who found a discovery and when, as the journal tells it. Per character,
--- what is yours is told as the find of the character you play, at the
--- moment it found it.
function Store:Credit(rec)
    if self:PerCharacter() and self:IsMine(rec) and self:IsFoundBy(rec) then
        return self.me, self:FoundAt(rec.id) or rec.c
    end
    return rec.a, rec.c
end

function Store:VerifyCount(rec)
    return 1 + U.Count(rec.ver)
end

function Store:IsVerified(rec)
    local threshold = FC.Config:Get("discovery.verifyThreshold") or 2
    return self:VerifyCount(rec) >= threshold
end

function Store:IsRumored(rec)
    if not FC.Config:Get("knowledge.veil") or self:IsPersonal(rec) then return false end
    -- per character, what your other characters found stays veiled as well
    return rec.v == "g" or self:IsMine(rec)
end

--- Derived status. primary is one of personal / alt / guild / verified / rumored.
function Store:GetStatus(rec)
    local state = self.state[rec.id]
    local status = {
        personal = self:IsPersonal(rec),
        mine = self:IsMine(rec),
        verified = self:IsVerified(rec),
        rumored = self:IsRumored(rec),
        favorite = state and state.fav or false,
        archived = state and state.arch or false,
        private = rec.v == "p",
    }
    status.guild = not status.mine
    status.alt = status.mine and not status.personal -- only with progress per character
    if status.rumored then
        status.primary = C.STATUS.RUMORED
    elseif status.verified then
        status.primary = C.STATUS.VERIFIED
    elseif status.personal then
        status.primary = C.STATUS.PERSONAL
    elseif status.alt then
        status.primary = C.STATUS.ALT
    else
        status.primary = C.STATUS.GUILD
    end
    return status
end

--- Knowledge layer ("Discovery Fog"): is this record part of what the
--- player currently wants to see? Per character, what only your other
--- characters found is never shown: not in the journal, on the map, in the
--- zone guide or in tooltips, until this character finds it too.
function Store:IsKnown(rec)
    if rec.del then return false end
    local state = self.state[rec.id]
    if state and state.hidden then return false end
    if self:IsAltOnly(rec) then return false end
    local mode = FC.Config:Get("knowledge.mode")
    if mode == "mine" then
        return self:IsPersonal(rec)
    elseif mode == "verified" then
        return self:IsPersonal(rec) or self:IsVerified(rec)
    end
    return true
end

------------------------------------------------------------------------
-- Creating and editing
------------------------------------------------------------------------

function Store:DefaultVisibility(typeKey)
    local P = FC.P
    if not P.sync.enabled or P.sync.channel == "NONE" then return "p" end
    if typeKey == "note" then return P.sync.shareNotes and "g" or "p" end
    if typeKey == "quest" or typeKey == "questchain" then return P.sync.shareQuests and "g" or "p" end
    return P.sync.autoShare and "g" or "p"
end

function Store:MakeId(fields)
    local def = Categories:Get(fields.t)
    local anchor = def.anchor
    if anchor == "npc" and fields.npc then return fields.t .. ":" .. fields.npc end
    if anchor == "q" and fields.q then return "quest:" .. fields.q end
    if anchor == "it" and fields.it then return fields.t .. ":" .. fields.it end
    if anchor == "in" and fields["in"] then return "dungeon:" .. fields["in"] end
    return "u:" .. self.me .. ":" .. U.ToBase36(U.Now()) .. ":" .. U.RandomToken(4)
end

--- Creates a discovery. Returns rec, isNew. When the id (or, for manual
--- entries, the dedupe key) already exists, the existing record is returned
--- with isNew = false and nothing is overwritten.
function Store:Create(fields, opts)
    opts = opts or {}
    local now = U.Now()
    local rec = {}
    for key in pairs(SPEC) do
        if fields[key] ~= nil then rec[key] = fields[key] end
    end
    rec.id = opts.id or rec.id or self:MakeId(rec)
    rec.a = rec.a or self.me
    rec.c = rec.c or now
    rec.u = rec.u or now
    rec.r = rec.r or 1
    rec.v = rec.v or self:DefaultVisibility(rec.t)

    local ok, clean = self:Validate(rec)
    if not ok then
        FC.Log:Warn("Discovery rejected: %s", tostring(clean))
        return nil, false
    end

    local existing = self.records[clean.id]
    if existing and not existing.del then
        return existing, false
    end
    if existing and clean.r <= existing.r then
        clean.r = existing.r + 1 -- found again after a retraction: newer than the tombstone
    end
    local dedupe = self:DedupeKey(clean)
    if dedupe and self.byDedupe[dedupe] then
        local match = self:Get(self.byDedupe[dedupe])
        if match then return match, false end
    end

    self.records[clean.id] = clean
    self:Index(clean)
    self:MarkDirty()
    if self:IsMine(clean) or opts.personal then
        self:MarkSeen(clean.id, now, true)
    end
    FC.Bus:Emit("DISCOVERY_ADDED", clean, opts.source or "local")
    return clean, true
end

--- Author-only edit of shared fields. Returns true on success. A correction
--- the addon makes (sameRevision) keeps the revision, so the entry still
--- counts as never edited; guild members take it as the newer copy anyway.
function Store:Update(id, changes, source, sameRevision)
    local rec = self:Get(id)
    if not rec or not self:IsMine(rec) then return false end
    local candidate = U.CopyTable(rec)
    for key, value in pairs(changes) do
        if SPEC[key] and key ~= "id" and key ~= "a" and key ~= "c" then
            if value == false then candidate[key] = nil else candidate[key] = value end
        end
    end
    candidate.r = (rec.r or 1) + (sameRevision and 0 or 1)
    candidate.u = U.Now()
    local ok, clean = self:Validate(candidate)
    if not ok then
        FC.Log:Warn("Edit rejected: %s", tostring(clean))
        return false
    end
    self:Unindex(rec)
    self.records[id] = clean
    self:Index(clean)
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_UPDATED", clean, source or "local")
    return true
end

--- Changes visibility to guild-shared (manual share). Author only.
function Store:MakeShared(id)
    local rec = self:Get(id)
    if not rec or not self:IsMine(rec) then return false end
    if rec.v == "g" then return true end
    return self:Update(id, { v = "g" }, "local")
end

------------------------------------------------------------------------
-- Merge (sync and import)
------------------------------------------------------------------------

local function mergeTimeList(target, source, limit, window)
    if not source then return target, false end
    target = target or {}
    local changed = false
    for _, ts in ipairs(source) do
        local duplicate = false
        for _, existing in ipairs(target) do
            if math.abs(existing - ts) <= window then duplicate = true break end
        end
        if not duplicate then
            target[#target + 1] = ts
            changed = true
        end
    end
    table.sort(target)
    while #target > limit do table.remove(target, 1) end
    return target, changed
end

local function mergeUnions(existing, incoming)
    local changed = false
    if incoming.ver then
        existing.ver = existing.ver or {}
        for name, ts in pairs(incoming.ver) do
            if name ~= existing.a and not existing.ver[name] and U.Count(existing.ver) < LIM.VERIFIERS then
                existing.ver[name] = ts
                changed = true
            end
        end
    end
    if incoming.gn then
        existing.gn = existing.gn or {}
        for _, note in ipairs(incoming.gn) do
            local found = false
            for _, mine in ipairs(existing.gn) do
                if mine.a == note.a and mine.t == note.t then found = true break end
            end
            if not found then
                existing.gn[#existing.gn + 1] = note
                changed = true
            end
        end
        table.sort(existing.gn, function(p, q) return p.t < q.t end)
        while #existing.gn > LIM.GUILD_NOTES do table.remove(existing.gn, 1) end
    end
    for _, field in ipairs(Store.SET_FIELDS) do
        if incoming[field] then
            for _, value in ipairs(incoming[field]) do
                if Store:SetInsert(existing, field, value) then changed = true end
            end
        end
    end
    if incoming.obs then
        existing.obs = existing.obs or {}
        local c1, c2
        existing.obs.d, c1 = mergeTimeList(existing.obs.d, incoming.obs.d, LIM.OBSERVATIONS, C.DISCOVERY.DEATH_DEDUPE)
        existing.obs.s, c2 = mergeTimeList(existing.obs.s, incoming.obs.s, LIM.OBSERVATIONS, C.DISCOVERY.SIGHTING_DEDUPE)
        changed = changed or c1 or c2
    end
    return changed
end

-- Deterministic canonical owner when two players found the same anchored
-- id independently: earliest creation wins, then author name.
local function incomingWinsOwnership(existing, incoming)
    if incoming.c ~= existing.c then return incoming.c < existing.c end
    return incoming.a < existing.a
end

--- Merges a record from another client or an import.
--- Returns rec, result ("added" | "updated" | "verified" | "unchanged" | "rejected").
function Store:Upsert(incoming, source)
    local ok, rec = self:Validate(incoming)
    if not ok then return nil, "rejected" end
    local existing = self.records[rec.id]

    if not existing then
        if rec.del then
            self.records[rec.id] = rec -- remember the tombstone so an old copy cannot resurrect it
            return rec, "unchanged"
        end
        local dedupe = self:DedupeKey(rec)
        local match = dedupe and self.byDedupe[dedupe] and self:Get(self.byDedupe[dedupe])
        if match and match.a ~= rec.a then
            self:AddVerification(match.id, rec.a, rec.c, source)
            return match, "verified"
        end
        self.records[rec.id] = rec
        self:Index(rec)
        -- a find of one of your characters, back from the guild: its author found it then
        if self:IsMine(rec) then
            local found = self:FoundSet(rec.a)
            if found[rec.id] == nil then found[rec.id] = rec.c end
        end
        self:MarkDirty()
        FC.Bus:Emit("DISCOVERY_ADDED", rec, source)
        return rec, "added"
    end

    local changed = false
    local wasDeleted = existing.del
    if rec.a == existing.a then
        if rec.r > existing.r or (rec.r == existing.r and rec.u > existing.u) then
            self:Unindex(existing)
            for _, key in ipairs(SHARED_FIELDS) do existing[key] = rec[key] end
            existing.r, existing.u = rec.r, rec.u
            self:Index(existing)
            changed = true
        end
    elseif not existing.del and not rec.del then
        -- independent discovery of the same anchored thing
        if incomingWinsOwnership(existing, rec) then
            local previousAuthor, previousTime = existing.a, existing.c
            self:Unindex(existing)
            for _, key in ipairs(SHARED_FIELDS) do existing[key] = rec[key] end
            existing.a, existing.c, existing.r, existing.u = rec.a, rec.c, rec.r, rec.u
            existing.ver = existing.ver or {}
            if existing.ver[previousAuthor] == nil then existing.ver[previousAuthor] = previousTime end
            existing.ver[existing.a] = nil
            self:Index(existing)
        else
            existing.ver = existing.ver or {}
            if existing.ver[rec.a] == nil then existing.ver[rec.a] = rec.c end
        end
        changed = true
    end
    if not existing.del and mergeUnions(existing, rec) then changed = true end

    if not changed then return existing, "unchanged" end
    self:MarkDirty()
    if existing.del and not wasDeleted then
        self:Unindex(existing)
        FC.Bus:Emit("DISCOVERY_REMOVED", existing.id, "retracted")
    else
        FC.Bus:Emit("DISCOVERY_UPDATED", existing, source)
    end
    return existing, "updated"
end

------------------------------------------------------------------------
-- Collaborative additions (any guild member)
------------------------------------------------------------------------

function Store:AddVerification(id, name, ts, source)
    local rec = self:Get(id)
    name = vPlayer(name)
    if not rec or not name or name == rec.a then return false end
    rec.ver = rec.ver or {}
    if rec.ver[name] or U.Count(rec.ver) >= LIM.VERIFIERS then return false end
    rec.ver[name] = vTime(ts) or U.Now()
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_VERIFIED", rec, name, source or "local")
    FC.Bus:Emit("DISCOVERY_UPDATED", rec, source or "local")
    return true
end

function Store:AddGuildNote(id, author, text, ts, source)
    local rec = self:Get(id)
    author = vPlayer(author)
    text = vString(LIM.GUILD_NOTE)(text)
    ts = vTime(ts) or U.Now()
    if not rec or not author or not text then return false end
    rec.gn = rec.gn or {}
    for _, note in ipairs(rec.gn) do
        if note.a == author and note.t == ts then return false end
    end
    local note = { a = author, t = ts, x = text }
    rec.gn[#rec.gn + 1] = note
    table.sort(rec.gn, function(p, q) return p.t < q.t end)
    while #rec.gn > LIM.GUILD_NOTES do table.remove(rec.gn, 1) end
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_NOTE", rec, note, source or "local")
    FC.Bus:Emit("DISCOVERY_UPDATED", rec, source or "local")
    return true
end

--- Union list fields: dr (items dropped), pts (packed positions).
Store.SET_FIELDS = { "dr", "pts" }
local SET_LIMIT = { dr = C.DISCOVERY.MAX_DROPS, pts = C.DISCOVERY.MAX_POINTS }

--- Inserts a value into a union list of a record table. Points closer than
--- ~1% of the map to an existing point are treated as the same spot.
function Store:SetInsert(rec, field, value)
    if type(value) ~= "number" then return false end
    local list = rec[field]
    if not list then
        list = {}
        rec[field] = list
    end
    if #list >= SET_LIMIT[field] then return false end
    for _, existing in ipairs(list) do
        if existing == value then return false end
        if field == "pts" then
            local x1, y1 = U.UnpackPoint(existing)
            local x2, y2 = U.UnpackPoint(value)
            if math.abs(x1 - x2) < 0.01 and math.abs(y1 - y2) < 0.01 then return false end
        end
    end
    list[#list + 1] = value
    if field == "dr" and self.byDrop and rec.id and self.records[rec.id] == rec and not rec.del then
        addToSet(self.byDrop, value, rec.id)
    end
    return true
end

--- Adds to a union field (any guild member may contribute).
function Store:AddToSet(id, field, value, source)
    local rec = self:Get(id)
    if not rec or not SET_LIMIT[field] then return false end
    if not self:SetInsert(rec, field, value) then return false end
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_SETADD", rec, field, value, source or "local")
    FC.Bus:Emit("DISCOVERY_UPDATED", rec, source or "local")
    return true
end

--- Rare observations: kind "d" (seen dead) or "s" (seen alive).
function Store:AddObservation(id, kind, ts, source)
    local rec = self:Get(id)
    ts = vTime(ts)
    if not rec or not ts or (kind ~= "d" and kind ~= "s") then return false end
    rec.obs = rec.obs or {}
    local window = kind == "d" and C.DISCOVERY.DEATH_DEDUPE or C.DISCOVERY.SIGHTING_DEDUPE
    local list, changed = mergeTimeList(rec.obs[kind], { ts }, LIM.OBSERVATIONS, window)
    rec.obs[kind] = list
    if not changed then return false end
    FC.Bus:Emit("DISCOVERY_OBSERVATION", rec, kind, ts, source or "local")
    FC.Bus:Emit("DISCOVERY_UPDATED", rec, source or "local")
    return true
end

--- Death-to-sighting intervals and a labelled estimate. Intervals are upper
--- bounds of the respawn time: the rare was seen alive that long after a death.
function Store:RespawnEstimate(rec)
    local obs = rec.obs
    if not obs or not obs.d or not obs.s then return nil end
    local intervals = {}
    for _, seen in ipairs(obs.s) do
        local latestDeath
        for _, death in ipairs(obs.d) do
            if death < seen and (not latestDeath or death > latestDeath) then latestDeath = death end
        end
        if latestDeath and seen - latestDeath <= C.DISCOVERY.MAX_RESPAWN_WINDOW then
            intervals[#intervals + 1] = seen - latestDeath
        end
    end
    if #intervals == 0 then return nil end
    local result = { intervals = intervals }
    if #intervals >= C.DISCOVERY.ESTIMATE_MIN_SAMPLES then
        local sorted = {}
        for i, v in ipairs(intervals) do sorted[i] = v end
        table.sort(sorted)
        local low = sorted[math.max(1, floor(#sorted * 0.25 + 0.5))]
        local high = sorted[math.max(1, floor(#sorted * 0.75 + 0.5))]
        result.low, result.high = low, high
    end
    return result
end

------------------------------------------------------------------------
-- Removal
------------------------------------------------------------------------

--- Author retraction: the record becomes a tombstone everywhere.
function Store:Retract(id)
    local rec = self:Get(id)
    if not rec or not self:IsMine(rec) then return false end
    self:Unindex(rec)
    local tombstone = { id = rec.id, t = rec.t, n = rec.n, a = rec.a, c = rec.c, u = U.Now(), r = rec.r + 1, v = rec.v, del = true }
    self.records[id] = tombstone
    self.state[id] = nil
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_RETRACTED", tombstone)
    FC.Bus:Emit("DISCOVERY_REMOVED", id, "retracted")
    return true
end

-- A discovery that is gone for good leaves every character's progress.
local function forgetFound(id)
    for _, set in pairs(FC.db.found) do set[id] = nil end
end

--- "Delete personal entry". Private entries of your own are removed; shared
--- entries of other players are only hidden locally, so guild history is
--- never destroyed by accident. Returns the action taken.
function Store:DeletePersonal(id)
    local rec = self:Get(id)
    if not rec then return nil end
    if self:IsMine(rec) and rec.v == "p" then
        self:Unindex(rec)
        self.records[id] = nil
        self.state[id] = nil
        forgetFound(id)
        self:MarkDirty()
        FC.Bus:Emit("DISCOVERY_REMOVED", id, "deleted")
        return "deleted"
    end
    local state = self:EnsureState(id)
    state.hidden = true
    self:MarkDirty()
    FC.Bus:Emit("DISCOVERY_REMOVED", id, "hidden")
    return "hidden"
end

--- Removes an entry of your own: a shared one is retracted (guild members
--- drop their copy too), a private one is deleted. Returns true on success.
function Store:Withdraw(id)
    local rec = self:Get(id)
    if not rec or not self:IsMine(rec) then return false end
    if rec.v == "g" then return self:Retract(id) end
    return self:DeletePersonal(id) == "deleted"
end

--- Folds an entry of your own into another one for the same thing: who
--- found it and when you first saw it move over, then it is withdrawn.
function Store:MergeInto(id, keepID)
    local rec, keep = self:Get(id), self:Get(keepID)
    if not rec or not keep or id == keepID or not self:IsMine(rec) then return false end
    for _, set in pairs(FC.db.found) do
        if set[id] then set[keepID] = math.min(set[keepID] or set[id], set[id]) end
    end
    local state = self.state[id]
    if state and state.seen then
        local kept = self:EnsureState(keepID)
        kept.seen = math.min(kept.seen or state.seen, state.seen)
    end
    return self:Withdraw(id)
end

function Store:UnhideAll()
    local count = 0
    for _, state in pairs(self.state) do
        if state.hidden then
            state.hidden = nil
            count = count + 1
        end
    end
    if count > 0 then
        self:MarkDirty()
        FC.Bus:Emit("STORE_RESET")
    end
    return count
end

function Store:ClearGuildCache()
    local count = 0
    for id, rec in pairs(self.records) do
        if not self:IsMine(rec) then
            self.records[id] = nil
            self.state[id] = nil
            count = count + 1
        end
    end
    FC.db.sync.lastOnline = nil
    self:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    return count
end

function Store:RemoveWhere(predicate)
    local count = 0
    for id, rec in pairs(self.records) do
        if predicate(rec) then
            self.records[id] = nil
            self.state[id] = nil
            forgetFound(id)
            count = count + 1
        end
    end
    self:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    return count
end

------------------------------------------------------------------------
-- Personal state
------------------------------------------------------------------------

local function emitState(id)
    Store:MarkDirty()
    FC.Bus:Emit("DISCOVERY_STATE", id)
end

--- The character you play has this discovery now. Returns changed,
--- newForAccount (none of your characters had it) and newForCharacter.
function Store:MarkSeen(id, ts, silent)
    ts = ts or U.Now()
    local found = self:FoundSet()
    local newForCharacter = found[id] == nil
    if newForCharacter then found[id] = ts end
    local state = self:EnsureState(id)
    local newForAccount = state.seen == nil
    if newForAccount then state.seen = ts end
    local changed = newForCharacter or newForAccount
    if changed then
        if silent then self:MarkDirty() else emitState(id) end
    end
    return changed, newForAccount, newForCharacter
end

--- The character you play came across a discovery that already exists. It
--- counts for this character either way. Account-wide progress announces
--- only what none of your characters had yet (a guild member's find);
--- progress per character announces everything this character had not
--- found, as if it were new. A discovery this character recorded itself is
--- never told again. Returns newForAccount, newForCharacter, announced.
function Store:Encounter(rec, ts)
    ts = ts or U.Now()
    local own = rec.a == self.me
    if own and self:FoundAt(rec.id) == nil then self:FoundSet()[rec.id] = rec.c or ts end
    local _, newForAccount, newForCharacter = self:MarkSeen(rec.id, ts)
    if own then return newForAccount, newForCharacter, false end
    if newForAccount and not self:IsMine(rec) then
        self:AddVerification(rec.id, self.me, ts, "local")
        FC.Bus:Emit("DISCOVERY_ENCOUNTERED", rec)
        return newForAccount, newForCharacter, true
    elseif newForCharacter and self:PerCharacter() then
        FC.Bus:Emit("DISCOVERY_FOUND", rec)
        return newForAccount, newForCharacter, true
    end
    return newForAccount, newForCharacter, false
end

function Store:SetFavorite(id, on, group)
    if not self:Get(id) then return end
    local state = self:EnsureState(id)
    state.fav = on and true or nil
    state.fg = on and vString(24)(group) or nil
    emitState(id)
end

function Store:SetArchived(id, on)
    if not self:Get(id) then return end
    self:EnsureState(id).arch = on and true or nil
    emitState(id)
end

function Store:SetNote(id, text)
    if not self:Get(id) then return end
    self:EnsureState(id).note = vString(LIM.NOTE)(text)
    emitState(id)
end

function Store:SetDone(id, on)
    if not self:Get(id) then return end
    self:EnsureState(id).done = on and true or nil
    emitState(id)
end

function Store:AddUserTag(id, tag)
    tag = type(tag) == "string" and U.CleanText(tag:lower(), LIM.TAG)
    if not tag or tag == "" or not self:Get(id) then return false end
    local state = self:EnsureState(id)
    state.tags = state.tags or {}
    if U.Contains(state.tags, tag) or #state.tags >= LIM.TAGS then return false end
    state.tags[#state.tags + 1] = tag
    emitState(id)
    return true
end

function Store:RemoveUserTag(id, tag)
    local state = self.state[id]
    if not state or not state.tags then return end
    for i = #state.tags, 1, -1 do
        if state.tags[i] == tag then table.remove(state.tags, i) end
    end
    if #state.tags == 0 then state.tags = nil end
    emitState(id)
end

function Store:ToggleItemFlag(id, itemID)
    if not self:Get(id) then return end
    local state = self:EnsureState(id)
    state.flags = state.flags or {}
    state.flags[itemID] = (not state.flags[itemID]) and true or nil
    emitState(id)
end

--- All tags on a record: shared (author) + personal.
function Store:AllTags(rec)
    local out, seen = {}, {}
    for _, tag in ipairs(rec.tg or {}) do
        if not seen[tag] then seen[tag] = true out[#out + 1] = tag end
    end
    local state = self.state[rec.id]
    for _, tag in ipairs(state and state.tags or {}) do
        if not seen[tag] then seen[tag] = true out[#out + 1] = tag end
    end
    return out
end

function Store:TagUsage()
    local counts = {}
    for _, rec in self:Iterate() do
        for _, tag in ipairs(self:AllTags(rec)) do
            counts[tag] = (counts[tag] or 0) + 1
        end
    end
    local list = {}
    for tag, count in pairs(counts) do list[#list + 1] = { tag = tag, count = count } end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.tag < b.tag
    end)
    return list
end

------------------------------------------------------------------------
-- Statistics and feed (cached, rebuilt only when data changed)
------------------------------------------------------------------------

function Store:Stats()
    if not self.statsDirty and self.statsCache then return self.statsCache end
    local now = U.Now()
    local dayStart = now - (now % 86400)
    local stats = {
        total = 0, personal = 0, guild = 0, verified = 0, private = 0, favorites = 0,
        character = 0, alts = 0, -- found by the character you play / only by your other characters
        byType = {}, zones = {}, zoneCount = 0, explorers = {}, today = 0, week = 0,
        secrets = 0, recipes = 0, rares = 0, notes = 0, hidden = 0,
    }
    for _, rec in self:Iterate() do
        local state = self.state[rec.id]
        if state and state.hidden then
            stats.hidden = stats.hidden + 1
        elseif self:IsAltOnly(rec) then
            -- per character: not part of this character's journal
            stats.alts = stats.alts + 1
        else
            stats.total = stats.total + 1
            local mine, foundHere = self:IsMine(rec), self:IsFoundBy(rec)
            if mine then stats.personal = stats.personal + 1 else stats.guild = stats.guild + 1 end
            if foundHere then stats.character = stats.character + 1 end
            if mine and not foundHere then stats.alts = stats.alts + 1 end
            if self:IsVerified(rec) then stats.verified = stats.verified + 1 end
            if rec.v == "p" then stats.private = stats.private + 1 end
            if state and state.fav then stats.favorites = stats.favorites + 1 end
            stats.byType[rec.t] = (stats.byType[rec.t] or 0) + 1
            local zone = rec.z or (rec.m and tostring(rec.m))
            if zone and not stats.zones[zone] then
                stats.zones[zone] = true
                stats.zoneCount = stats.zoneCount + 1
            end
            local by, at = self:Credit(rec)
            if by then stats.explorers[by] = (stats.explorers[by] or 0) + 1 end
            -- a recovered entry was not found today: the journal only learned of it
            if not rec.rcv then
                if at >= dayStart then stats.today = stats.today + 1 end
                if at >= now - 7 * 86400 then stats.week = stats.week + 1 end
            end
            local group = Categories:Get(rec.t).group
            if group == "secrets" then stats.secrets = stats.secrets + 1 end
            if rec.t == "recipe" or rec.t == "profession" then stats.recipes = stats.recipes + 1 end
            if rec.t == "rare" then stats.rares = stats.rares + 1 end
            if rec.t == "note" then stats.notes = stats.notes + 1 end
        end
    end
    local explorers = {}
    for name, count in pairs(stats.explorers) do explorers[#explorers + 1] = { name = name, count = count } end
    table.sort(explorers, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    stats.topExplorers = explorers
    self.statsCache = stats
    self.statsDirty = false
    return stats
end

--- Recent activity: discoveries, verifications and guild notes, newest first.
--- Per character, only this character's finds and nothing your other
--- characters did.
function Store:Feed()
    if not self.feedDirty and self.feedCache then return self.feedCache end
    local events = {}
    local myChars, me = FC.db.myChars, self.me
    local perCharacter = self:PerCharacter()
    local function otherCharacter(name) return perCharacter and myChars[name] and name ~= me end
    for _, rec in self:Iterate() do
        if self:IsKnown(rec) then
            local by, at = self:Credit(rec)
            -- recovered entries are no recent activity (their date is not when they were found)
            if not rec.rcv then events[#events + 1] = { ts = at, kind = "discovered", actor = by, rec = rec } end
            if rec.ver then
                for name, ts in pairs(rec.ver) do
                    if not otherCharacter(name) then
                        events[#events + 1] = { ts = ts, kind = "verified", actor = name, rec = rec }
                    end
                end
            end
            if rec.gn then
                for _, note in ipairs(rec.gn) do
                    if not otherCharacter(note.a) then
                        events[#events + 1] = { ts = note.t, kind = "note", actor = note.a, rec = rec }
                    end
                end
            end
        end
    end
    table.sort(events, function(a, b) return a.ts > b.ts end)
    for i = #events, LIM.FEED + 1, -1 do events[i] = nil end
    self.feedCache = events
    self.feedDirty = false
    return events
end
