-- DeltaSyncNumbers.lua
-- Optional ITEM-NUMBER table for DeltaSync-1.0 (MINOR 18+). Part 1 of LIBREQ-DS-008:
-- every item key a host syncs gets a 4-digit number, for life, agreed on every
-- client, so the wire can name "0001, 0015, 0023" instead of repeating long keys
-- and their hashes in every offer and broadcast.
--
-- THE DESIGN is the operator's (TOGBankClassic, 2026-09-10), generalised from
-- banker names to any string key:
--   * A number is issued ONCE and never reused. A key that goes away keeps its
--     entry; one that comes back has the same number. `numbersNext` only rises.
--   * MINTING is done only by a client for which config.canMint() is true (for
--     TOGBank: an account that owns a banker), for EVERY unnumbered key in
--     config.keys(), in ALPHABETICAL order from `numbersNext`. Two minters working
--     from the same key list therefore produce the identical table, which is why
--     this does not depend on "only one online" -- unknowable at mint time.
--     Clients that may not mint only adopt.
--   * SYNC: `numbersVersion` rides in every numbered message. A client that sees
--     a higher version whispers the sender `numbers-request` and adopts the reply
--     wholesale; equal version + different table adopts only from a sender whose
--     name sorts LOWER, so two independent mints converge on one and the loser
--     re-mints its stragglers under a higher version. A numbered message stamped
--     with a version our table does not extend (NUM:Reads) is never read through
--     it (DeltaSyncP2PNumbered.lua TableMatches / OnTableMismatch): the same number can name two
--     keys on two tables for as long as they differ, so reading across versions
--     misattributed canons for the whole divergence, not one broadcast (TOGBank,
--     inbox 17a1ee39). KNOWN COST, still open: two DIFFERENT tables under the SAME
--     version (two independent mints in one second) are indistinguishable by
--     version and are read until the tie-break adopts one.
--   * WIRE: an entry is <4-digit number><20-digit canon>, 24 chars, digits only,
--     no separator (AceSerializer escapes nothing). A broadcast is a run of
--     entries; an offer is a run of bare numbers; a version reply is a run of
--     entries. A CANON is the consumer's version identity -- <10-digit publish
--     time><10-digit content hash> -- opaque here except that its first ten
--     digits order publishes (config.canonTime overrides that parse).
--
-- STORAGE is the HOST's: config.table() returns the consumer's persisted table
-- (typically a SavedVariables sub-table) and this module writes exactly three
-- fields on it -- numbers[key] = n, numbersNext, numbersVersion -- creating them
-- on demand. The library holds no SavedVariables of its own (CLAUDE.md rule).
--
-- TRANSPORT: numbers-request / numbers-reply ride the existing HANDSHAKE
-- whisper channel (no eighth prefix). DeltaSync.lua's OnComm_HANDSHAKE routes
-- them here when host.numbers exists.
--
-- MULTI-HOST: a persistent class (lib._NumbersClass) with a per-host instance at
-- host.numbers (created by host:InitNumbers), carrying a _host back-reference,
-- exactly like P2P / RosterSync / GuildMode.

local MAJOR = "DeltaSync-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then
    error("DeltaSyncNumbers.lua requires DeltaSync.lua to load first (LibStub('DeltaSync-1.0') is nil). Check TOC order.")
end

local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

lib._NumbersClass = lib._NumbersClass or {}
local NUM = lib._NumbersClass

NUM.MAX         = 9999
NUM.WIDTH       = 4
NUM.CANON_WIDTH = 20
NUM.ENTRY_WIDTH = NUM.WIDTH + NUM.CANON_WIDTH
-- A second request for the same version is not sent inside this many seconds:
-- every broadcast from a client on a newer table would otherwise trigger one.
NUM.REQUEST_COOLDOWN = 30

function NUM:Dbg(fmt, ...)
    local h = self._host
    if h and h.Debug then h:Debug("P2P", "NUMBERS " .. string.format(fmt, ...)) end
end

-- ─── Init ───────────────────────────────────────────────────────────────────

--- Opt-in per host. Until this is called, host.numbers is false and no
-- numbered message is understood or produced.
-- @param config table
--   config.table()            -> table|nil  REQUIRED. The persisted table the three
--                                fields live on; nil while the host has no store yet.
--   config.keys()             -> { key, ... } REQUIRED. Every key eligible for a
--                                number, right now. Order is irrelevant; minting sorts.
--   config.canMint()          -> bool  REQUIRED. May THIS client issue numbers?
--   config.normalize(key)     -> key   optional; identity by default.
--   config.me()               -> string optional; the local identity for the
--                                equal-version tie-break. Defaults to LibGuildRoster's
--                                GetNormalizedPlayer, then UnitName("player").
--   config.canonTime(canon)   -> number optional; default reads the first ten digits.
--   config.onChanged(reason)  optional; fired after a mint or an adopt changed the table.
--   config.onExhausted(key)   optional; fired once when numbersNext passes MAX.
--                                Default prints a warning.
function lib:InitNumbers(config)
    config = config or {}
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))

    local inst = rawget(self, "numbers")
    if not inst then
        inst = setmetatable({ _host = self }, { __index = NUM })
        self.numbers = inst
    else
        inst._host = self
    end
    inst.cb = inst.cb or {}
    inst.cb.table       = config.table
    inst.cb.keys        = config.keys
    inst.cb.canMint     = config.canMint
    inst.cb.normalize   = config.normalize
    inst.cb.me          = config.me
    inst.cb.canonTime   = config.canonTime
    inst.cb.onChanged   = config.onChanged
    inst.cb.onExhausted = config.onExhausted

    if type(inst.cb.table) ~= "function" or type(inst.cb.keys) ~= "function"
       or type(inst.cb.canMint) ~= "function" then
        error("DeltaSync:InitNumbers: config.table, config.keys and config.canMint are required functions", 2)
    end

    inst.initialized = true
    inst:Dbg("initialized (version %d)", inst:Version())
    return inst
end

-- ─── Helpers ────────────────────────────────────────────────────────────────

function NUM:Norm(key)
    if self.cb.normalize then return self.cb.normalize(key) or key end
    return key
end

function NUM:Me()
    if self.cb.me then return self.cb.me() end
    if GuildRoster and GuildRoster.GetNormalizedPlayer then return GuildRoster:GetNormalizedPlayer() end
    return UnitName and UnitName("player") or ""
end

--- The publish time inside a canon, or NIL when the canon carries none -- a
-- revision-1 numeric hash, a malformed string, nothing at all. nil is "no
-- version": it never improves, never sorts newer, is never advertised. It is
-- deliberately not 0, which would sort as "the oldest version there is" and
-- let a version-less offer be judged against real ones (TOGBank, DS-008
-- thread). Consumers whose canon is not the <10-digit time><10-digit hash>
-- shape supply config.canonTime with the same nil contract.
function NUM:CanonTime(canon)
    if self.cb.canonTime then return self.cb.canonTime(canon) end
    if type(canon) ~= "string" or #canon ~= self.CANON_WIDTH or not canon:match("^%d+$") then
        return nil
    end
    return tonumber(canon:sub(1, 10))
end

--- The host table the numbers live on, with the three fields created on demand.
-- nil while the host has no store yet.
function NUM:Table()
    local r = self.cb.table()
    if type(r) ~= "table" then return nil end
    r.numbers        = r.numbers        or {}
    r.numbersNext    = r.numbersNext    or 1
    r.numbersVersion = r.numbersVersion or 0
    return r
end

function NUM:Version()
    local r = self:Table()
    return r and r.numbersVersion or 0
end

--- Can a number stamped with table version `v` be read through OUR table?
-- True for our own version, and for every version our table EXTENDS: a mint only
-- appends, so after adopting v5 and minting to v6 every v5 number still means
-- what it meant. An adopt replaces the table, so it resets the lineage. Session
-- memory only -- after a reload just the current version reads, which is the
-- safe side. (TOGBank, inbox 17a1ee39.)
function NUM:Reads(v)
    v = tonumber(v) or 0
    return v == self:Version() or (self.lineage ~= nil and self.lineage[v] == true)
end

--- Four zero-padded digits, the only spelling a number has on the wire.
function NUM:Format(n)
    return string.format("%04d", n)
end

--- The number for a key, as a 4-digit string, or nil when it has none.
function NUM:NumberOf(key)
    local r = self:Table()
    if not r or key == nil then return nil end
    local n = r.numbers[self:Norm(key)]
    return n and self:Format(n) or nil
end

--- The key a 4-digit number names, or nil. The reverse map is rebuilt when the
-- table identity or version changes.
function NUM:KeyOf(numStr)
    local r = self:Table()
    if not r then return nil end
    local n = tonumber(numStr)
    if not n then return nil end
    if not self.byNumber or self.byNumberVersion ~= r.numbersVersion or self.byNumberTable ~= r.numbers then
        self.byNumber = {}
        for key, num in pairs(r.numbers) do self.byNumber[num] = key end
        self.byNumberVersion = r.numbersVersion
        self.byNumberTable   = r.numbers
    end
    return self.byNumber[n]
end

local function invalidate(self)
    self.byNumber = nil
end

-- The numbered P2P parks offers and broadcasts naming numbers this table could
-- not resolve; a table that now can completes them (DeltaSyncP2PNumbered.lua
-- OnNumbersChanged).
local function notifyP2P(self, reason)
    local p2p = self._host and rawget(self._host, "p2p")
    if type(p2p) == "table" and p2p.OnNumbersChanged then p2p:OnNumbersChanged(reason) end
end

local function changed(self, reason, holdP2P)
    invalidate(self)
    if self.cb.onChanged then self.cb.onChanged(reason) end
    if not holdP2P then notifyP2P(self, reason) end
end

-- ─── Minting ────────────────────────────────────────────────────────────────

function NUM:CanMint()
    return self.cb.canMint() and true or false
end

--- Assign numbers to every eligible key that has none, alphabetically from
-- numbersNext. Returns how many were minted (0 when this client may not mint,
-- or nothing was unnumbered).
function NUM:Mint()
    local r = self:Table()
    if not r or not self:CanMint() then return 0 end
    local unnumbered = {}
    for _, key in ipairs(self.cb.keys() or {}) do
        local norm = self:Norm(key)
        if norm ~= nil and not r.numbers[norm] then unnumbered[#unnumbered + 1] = norm end
    end
    if #unnumbered == 0 then return 0 end
    table.sort(unnumbered)

    local minted = 0
    for _, norm in ipairs(unnumbered) do
        if r.numbersNext > self.MAX then
            if not self.warnedExhausted then
                self.warnedExhausted = true
                if self.cb.onExhausted then
                    self.cb.onExhausted(norm)
                else
                    print(string.format("|cffff8800[DeltaSync]|r item numbers exhausted (%d): %s and later keys cannot be numbered.",
                        self.MAX, tostring(norm)))
                end
            end
            break
        end
        r.numbers[norm] = r.numbersNext
        r.numbersNext   = r.numbersNext + 1
        minted = minted + 1
        self:Dbg("minted %s = %s", tostring(norm), self:Format(r.numbers[norm]))
    end
    if minted > 0 then
        -- The table we minted onto stays readable: a mint only appends.
        self.lineage = self.lineage or {}
        self.lineage[r.numbersVersion] = true
        -- Strictly monotonic even when two mints land in one second.
        local now = (GetServerTime and GetServerTime()) or (time and time()) or 0
        r.numbersVersion = math.max(r.numbersVersion + 1, now)
        self.lineage[r.numbersVersion] = true
        changed(self, "mint")
        self:Dbg("minted %d number(s); version %d, next %s", minted, r.numbersVersion, self:Format(r.numbersNext))
    end
    return minted
end

--- The whole table, for the wire.
function NUM:Snapshot()
    local r = self:Table()
    if not r then return nil end
    local t = {}
    for key, n in pairs(r.numbers) do t[key] = n end
    return { v = r.numbersVersion, n = r.numbersNext, t = t }
end

-- Names sort as the tie-break, and the comparison must be the same on both sides.
local function senderWins(sender, me)
    return type(sender) == "string" and type(me) == "string" and sender < me
end

--- Take a peer's table when it is authoritative. Returns true when ours changed.
--   newer version            -> adopt wholesale
--   same version, same table -> nothing
--   same version, different  -> adopt only from a lower-sorting sender
--   older version            -> ignore
-- After adopting, a client that may mint numbers any eligible key the peer's
-- table lacks, which raises the version so the peer adopts back and the two
-- converge.
function NUM:Adopt(snap, sender)
    local r = self:Table()
    if not r or type(snap) ~= "table" or type(snap.t) ~= "table" then return false end
    local v = tonumber(snap.v) or 0
    if v < r.numbersVersion then return false end
    if v == r.numbersVersion then
        local same = true
        for key, n in pairs(snap.t) do if r.numbers[key] ~= n then same = false break end end
        if same then for key, n in pairs(r.numbers) do if snap.t[key] ~= n then same = false break end end end
        if same then return false end
        if not senderWins(sender, self:Me()) then return false end
    end

    local numbers, maxN = {}, 0
    for key, n in pairs(snap.t) do
        n = tonumber(n)
        if type(key) == "string" and n and n >= 1 and n <= self.MAX and n == math.floor(n) then
            numbers[key] = n
            if n > maxN then maxN = n end
        end
    end
    r.numbers        = numbers
    r.numbersNext    = math.max(tonumber(snap.n) or 1, maxN + 1)
    r.numbersVersion = v
    self.lineage = { [v] = true }
    -- The P2P hears of it only AFTER our own re-mint: a parked broadcast replayed
    -- before it would offer back without the keys we are about to number
    -- (Questbook, inbox 12ca628b). A mint that numbers something notifies it.
    changed(self, "adopt", true)
    self:Dbg("adopted numbers v%d from %s (%d entries, next %s)", v, tostring(sender), maxN, self:Format(r.numbersNext))
    if self:Mint() == 0 then notifyP2P(self, "adopt") end
    return true
end

-- ─── Sync over HANDSHAKE ────────────────────────────────────────────────────

--- Every numbered message carries the sender's table version. Behind it, ask
-- them for the table -- once per version per cooldown, so a burst of broadcasts
-- does not fan out into a burst of requests. Returns true when a request went out.
function NUM:OnAdvertisedVersion(sender, v)
    v = tonumber(v)
    if not v or not sender or v <= self:Version() then return false end
    local now = (GetTime and GetTime()) or 0
    if self.requested and self.requested.v >= v and now - self.requested.at < self.REQUEST_COOLDOWN then
        return false
    end
    self.requested = { v = v, at = now }
    self._host:SendHandshake(sender, { type = "numbers-request", v = self:Version() }, "NORMAL")
    self:Dbg("behind on numbers (mine %d, %s has %d) -- requested", self:Version(), tostring(sender), v)
    return true
end

--- A peer asked for our table (routed from OnComm_HANDSHAKE).
function NUM:HandleRequest(sender)
    local snap = self:Snapshot()
    if not snap or not sender then return false end
    self._host:SendHandshake(sender, { type = "numbers-reply", numbers = snap }, "NORMAL")
    self:Dbg("sent numbers v%d to %s", snap.v, tostring(sender))
    return true
end

--- A peer answered with its table (routed from OnComm_HANDSHAKE).
function NUM:HandleReply(sender, snap)
    return self:Adopt(snap, sender)
end

-- ─── Wire ───────────────────────────────────────────────────────────────────

local function isDigits(s, n)
    return type(s) == "string" and #s == n and s:match("^%d+$") ~= nil
end

--- { {number="0007", canon="<20 digits>"}, ... } -> one fixed-width string.
-- Entries that are not exactly a 4-digit number beside a 20-digit canon are
-- dropped, because one malformed entry would shift every one after it.
function NUM:EncodeEntries(entries)
    local parts = {}
    for _, e in ipairs(entries or {}) do
        if isDigits(e.number, self.WIDTH) and isDigits(e.canon, self.CANON_WIDTH) then
            parts[#parts + 1] = e.number .. e.canon
        end
    end
    return table.concat(parts)
end

--- The inverse. A string whose length is not a multiple of 24, or that carries
-- a non-digit, decodes to NOTHING rather than to a prefix -- a truncated payload
-- must not read as a shorter valid one.
function NUM:DecodeEntries(s)
    local out = {}
    if type(s) ~= "string" or #s % self.ENTRY_WIDTH ~= 0 or (s ~= "" and not s:match("^%d+$")) then
        return out
    end
    for i = 1, #s, self.ENTRY_WIDTH do
        out[#out + 1] = {
            number = s:sub(i, i + self.WIDTH - 1),
            canon  = s:sub(i + self.WIDTH, i + self.ENTRY_WIDTH - 1),
        }
    end
    return out
end

--- { "0001", "0004", ... } -> "00010004..."
function NUM:EncodeNumbers(numbers)
    local parts = {}
    for _, n in ipairs(numbers or {}) do
        if isDigits(n, self.WIDTH) then parts[#parts + 1] = n end
    end
    return table.concat(parts)
end

function NUM:DecodeNumbers(s)
    local out = {}
    if type(s) ~= "string" or #s % self.WIDTH ~= 0 or (s ~= "" and not s:match("^%d+$")) then
        return out
    end
    for i = 1, #s, self.WIDTH do
        out[#out + 1] = s:sub(i, i + self.WIDTH - 1)
    end
    return out
end

--- Decode a run of entries into the advertised-summary shape every receive path
-- already reads: { [key] = { hashV2 = canon, updatedAt = <publish time> } }.
-- Entries whose number this client cannot name are skipped and COUNTED, so the
-- caller can ask for the table.
-- @return items, unknown
function NUM:EntriesToItems(entries)
    local items, unknown = {}, 0
    for _, e in ipairs(entries or {}) do
        local key = self:KeyOf(e.number)
        if key then
            items[key] = { hashV2 = e.canon, updatedAt = self:CanonTime(e.canon) }
        else
            unknown = unknown + 1
        end
    end
    return items, unknown
end
