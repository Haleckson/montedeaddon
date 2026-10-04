-- DeltaSyncP2PNumbered.lua
-- The NUMBERED P2P session protocol for DeltaSync-1.0 (MINOR 18+). Part 2 of
-- LIBREQ-DS-008: TOGBankClassic's P2P-035, generalised. Selected per host with
--
--     host:InitP2P({ mode = "numbered", ... })
--
-- and requires host:InitNumbers(...) first (DeltaSyncNumbers.lua). Hosts that do
-- not ask for it get P2PSession.lua's hash-based protocol exactly as before --
-- this file adds a second class (lib._P2PNumberedClass) and changes nothing in
-- the first, because TOGProfessionMaster, PersonalShopper and FastGuildInvite
-- run the hash protocol today.
--
-- WHAT IS DIFFERENT FROM THE HASH PROTOCOL, and none of it is to be softened --
-- each line is an operator directive from TOGBank's live guild:
--   * The wire names items by NUMBER (host.numbers), never by key + hash. A
--     broadcast is a run of <number><canon> entries; an offer is a run of bare
--     numbers; nothing else travels in the collect phase.
--   * A peer offers only when it holds a STRICTLY NEWER canon (by publish time)
--     for a number the broadcaster listed. Never when merely different.
--   * A bare offer names WHO, not WHAT. Before asking anyone for data the
--     requester asks up to VERSION_QUERY_MAX offerers which canon they hold
--     (ver-query / ver-reply); the AUTHOR answering ends the wait early and wins.
--   * Dispatch goes to holders of the NEWEST canon only. If they are all busy the
--     requester WAITS in their queue (sync-queued { position }); it never falls
--     back to a peer holding an older copy.
--   * The request NAMES the canon it wants. A provider serves when it holds that
--     canon OR A NEWER one; it answers sync-busy { reason = "version" } only when
--     it holds an OLDER one, and the requester treats that as "not this
--     candidate", not "wait here".
--   * At send capacity the provider QUEUES, never refuses. An accept that is
--     never followed by the requester's QUERY releases after STATE_WAIT; an accept
--     the requester can no longer use is answered sync-cancel so the slot goes
--     back at once.
--   * No global cap on our own fetches -- MAX_SESSIONS_PER_PEER (1) is the only
--     cap, because a second request to one peer only sits in that peer's queue.
--   * Hearing ANYONE's broadcast advertise a newer canon for a key we hold is an
--     offer: it dispatches to that sender directly, no collect window.
--   * A key a broadcast does NOT list is one its sender holds nothing for, and is
--     offered back like a newer one -- with our numbers table sent first when the
--     broadcaster is behind on it.
--   * A bare offer naming numbers our table cannot resolve yet is PARKED, not
--     dropped, and replayed the moment a table that resolves them lands.
--   * A number means something only in the table that minted it. A broadcast,
--     offer or version reply stamped with a table version OTHER than ours is
--     never read through our table: from a peer AHEAD of us it is parked until we
--     adopt their table; from a peer BEHIND us it is not read -- they are sent our
--     table, and a behind BROADCASTER is offered every key we serve, since what it
--     listed cannot be known. (TOGBank, inbox 17a1ee39: reading it through ours attributed one
--     banker's canon to another and asked the guild for versions nobody held.)
--
-- HOST HOOKS (config to InitP2P). Required: servableCanon, onDeliver. Storage and
-- the wire codec come from host.numbers.
--   servableCanon(key) -> canon|nil   the canon this client can SERVE for key
--   heldCanon(key)     -> canon|nil   the canon this client HOLDS (default servableCanon)
--   canServe(key)      -> bool        default: servableCanon(key) ~= nil
--   canonImproves(key, canon) -> bool "strictly newer than what I hold"; default
--                                     compares canonTime; a nil time never improves
--   isOwnKey(key)      -> bool        a key this client AUTHORS (never fetched;
--                                     default key == local player)
--   isValidPeer(name)  -> bool        eligibility, as in the hash protocol
--   peerCapable(name)  -> ok, why     can this peer complete the data leg with us?
--                                     default accept-all. A CALLBACK on purpose:
--                                     the verdict is consumer memory (release skew,
--                                     a peer that behaved like the old wire) that
--                                     the library cannot have.
--   hasMissingItems()  -> bool        drives catch-up re-broadcasts
--   broadcastExtra()   -> table|nil   fields merged into a CATCH-UP broadcast, the
--                                     same `extra` the host passes BroadcastNumbered
--                                     (the library starts that one, so it asks)
--   onDeliver(key, canon, provider)   REQUESTER: the provider accepted; start the
--                                     data leg (host:RequestData naming your held canon)
--   Observers, all optional, all called with the peer AS RECEIVED:
--   onAdvertised(key, canon, peer)    EVERY message that names a canon for a key,
--                                     including keys this client authors (a shared
--                                     account on two PCs learns it is behind here)
--   onNewerOffered(key, peer)         a bare offer named this key (tab goes red)
--   onNewerCleared(key)               the offer was checked and found empty, the
--                                     item completed, or the fetch session FAILED
--                                     (nobody could deliver it; a later offer
--                                     raises onNewerOffered again)
--   onSelfConsulted(reason)           the first cycle has settled what the guild
--                                     holds for keys this client authors
--
-- PROVIDER DATA LEG: on accept the library arms a STATE_WAIT for the requester's
-- QUERY. The host's onDataRequest calls host.p2p:QueryArrived(requester, key) --
-- true means a slot is claimed and the reply may be sent -- and gives the slot
-- back when the reply has DRAINED via host.p2p:ServeReply(requester, key, data,
-- isDelta, priority) (SendData with the DS-009 completion wired to ReleaseSendSlot),
-- or by calling ReleaseSendSlot itself from SendData's onComplete.

local MAJOR = "DeltaSync-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then
    error("DeltaSyncP2PNumbered.lua requires DeltaSync.lua to load first (LibStub('DeltaSync-1.0') is nil). Check TOC order.")
end

local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

lib._P2PNumberedClass = lib._P2PNumberedClass or {}
local NP = lib._P2PNumberedClass

local STATE = {
    DISPATCHED = "DISPATCHED",
    ACTIVE     = "ACTIVE",
    COMPLETE   = "COMPLETE",
    FAILED     = "FAILED",
}

-- ─── Defaults (class-level, overridable per instance through config) ────────
NP.COLLECT_WINDOW        = NP.COLLECT_WINDOW        or 60
NP.DISPATCH_TIMEOUT      = NP.DISPATCH_TIMEOUT      or 15
NP.DELIVERY_TIMEOUT      = NP.DELIVERY_TIMEOUT      or 180
NP.SEND_TIMEOUT          = NP.SEND_TIMEOUT          or 210   -- > DELIVERY_TIMEOUT, so the safety release never races the watchdog
NP.VERSION_QUERY_MAX     = NP.VERSION_QUERY_MAX     or 5
NP.VERSION_QUERY_WINDOW  = NP.VERSION_QUERY_WINDOW  or 5
NP.MAX_SESSIONS_PER_PEER = NP.MAX_SESSIONS_PER_PEER or 1
NP.MAX_ACTIVE_SENDS      = NP.MAX_ACTIVE_SENDS      or 3
NP.STATE_WAIT            = NP.STATE_WAIT            or 30
NP.QUEUE_TTL             = NP.QUEUE_TTL             or 180
NP.MAX_RETRY_CYCLES      = NP.MAX_RETRY_CYCLES      or 5
NP.RETRY_CYCLE_DELAY     = NP.RETRY_CYCLE_DELAY     or 20
NP.CATCH_UP_DELAY        = NP.CATCH_UP_DELAY        or 45
NP.MAX_CATCH_UP_CYCLES   = NP.MAX_CATCH_UP_CYCLES   or 5

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function Norm(name)
    if GuildRoster then return GuildRoster:NormalizeName(name) or name end
    return name
end

local function Me()
    if GuildRoster and GuildRoster.GetNormalizedPlayer then return GuildRoster:GetNormalizedPlayer() end
    return UnitName and UnitName("player") or ""
end

local function now()
    return (GetTime and GetTime()) or 0
end

-- Is `peer` the AUTHOR of `key` -- the character the key names? A key is a canonical
-- "Name-Realm"; the sender the wire hands us is UnitName("player") of the sending client,
-- BARE for a same-realm peer. Comparing the two raw never matched an author on a real
-- client, so the "author already advertised, skip the version query" rule could not fire
-- (found 2026-09-20 when the suite moved onto the real wire). Canonicalise first.
local function IsAuthor(peer, key)
    return peer == key or Norm(peer) == key
end

function NP:Dbg(tag, fmt, ...)
    local host = self._host
    if host and host.Debug then
        host:Debug("P2P", tag .. " " .. string.format(fmt, ...))
    end
end

local function MakeSessionId(key)
    return Me() .. ":" .. tostring(key) .. ":" .. tostring(math.floor(now() * 1000))
end

-- Fire an optional observer, never letting a host error break the protocol.
function NP:Observe(name, ...)
    local cb = self.cb[name]
    if not cb then return end
    local ok, err = pcall(cb, ...)
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
        self:Dbg("OBSERVE", "%s raised: %s", name, tostring(err))
    end
end

-- ─── Init ───────────────────────────────────────────────────────────────────

function NP:Init(config)
    config = config or {}
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))

    local host = self._host
    if not (host and rawget(host, "numbers")) then
        error("DeltaSync:InitP2P(mode='numbered') requires host:InitNumbers(...) first", 3)
    end
    if type(config.servableCanon) ~= "function" or type(config.onDeliver) ~= "function" then
        error("DeltaSync:InitP2P(mode='numbered') requires config.servableCanon and config.onDeliver", 3)
    end

    for _, name in ipairs({ "COLLECT_WINDOW", "DISPATCH_TIMEOUT", "DELIVERY_TIMEOUT", "SEND_TIMEOUT",
        "VERSION_QUERY_MAX", "VERSION_QUERY_WINDOW", "MAX_SESSIONS_PER_PEER", "MAX_ACTIVE_SENDS",
        "STATE_WAIT", "QUEUE_TTL", "MAX_RETRY_CYCLES", "RETRY_CYCLE_DELAY", "CATCH_UP_DELAY",
        "MAX_CATCH_UP_CYCLES" }) do
        local lower = name:lower():gsub("_(%l)", function(c) return c:upper() end)
        if config[lower] ~= nil then self[name] = config[lower] end
    end

    -- Per-instance state, rawget-preserved across a re-init.
    local function keep(field, default)
        if rawget(self, field) == nil then self[field] = default end
    end
    keep("sessions", {})          -- sessionId -> session
    keep("sessionsByKey", {})     -- key -> sessionId
    keep("offers", {})            -- key -> { {peer, canon, updatedAt, queried, answered}, ... }
    keep("pendingDispatch", {})   -- items parked because every holder is busy with us
    keep("versionQueries", {})    -- key -> item awaiting ver-reply
    keep("activeSends", {})       -- requester -> count
    keep("servingSends", {})      -- requester -> count of slots a QUERY has claimed
    keep("sendTimers", {})        -- requester -> [safety timer handles]
    keep("sendQueue", {})         -- FIFO of { sessionId, requester, key, at }
    keep("stateWaits", {})        -- requester|key -> timer
    keep("stateWaitSids", {})     -- sessionId -> requester|key
    keep("parkedOffers", {})      -- sender -> { v, numbers, at }: offered numbers the table cannot resolve yet
    keep("parkedBroadcasts", {})  -- sender -> { data, at }: a broadcast on a newer table than ours
    keep("tableSentTo", {})       -- sender -> time we last sent our table to a peer behind us
    keep("activeSessions", 0)
    keep("catchUpCycles", 0)
    keep("isCollecting", false)
    keep("selfConsulted", false)
    keep("consultBegun", false)
    self.cb = rawget(self, "cb") or {}

    local cb = self.cb
    cb.servableCanon   = config.servableCanon
    cb.heldCanon       = config.heldCanon or config.servableCanon
    cb.canServe        = config.canServe or function(key) return cb.servableCanon(key) ~= nil end
    cb.canonImproves   = config.canonImproves
    cb.isOwnKey        = config.isOwnKey or function(key) return key == Me() end
    cb.isValidPeer     = config.isValidPeer or lib._SendSlotMixin.DefaultIsValidPeer()
    cb.peerCapable     = config.peerCapable or function() return true end
    cb.hasMissingItems = config.hasMissingItems or function() return false end
    cb.onDeliver       = config.onDeliver
    cb.onAdvertised    = config.onAdvertised
    cb.onNewerOffered  = config.onNewerOffered
    cb.onNewerCleared  = config.onNewerCleared
    cb.onSelfConsulted = config.onSelfConsulted
    cb.broadcastExtra  = config.broadcastExtra

    self:Dbg("INIT", "numbered P2P initialized (collect=%ds, perPeer=%d, maxSends=%d)",
        self.COLLECT_WINDOW, self.MAX_SESSIONS_PER_PEER, self.MAX_ACTIVE_SENDS)
end

-- ─── Canon judgement ────────────────────────────────────────────────────────

function NP:CanonTime(canon)
    return self._host.numbers:CanonTime(canon)
end

--- Is `canon` strictly newer than what this client holds for `key`?
-- A canon with no readable time never improves anything; a key we hold nothing
-- for is improved by any dated canon.
function NP:Improves(key, canon)
    if self.cb.canonImproves then return self.cb.canonImproves(key, canon) and true or false end
    local t = self:CanonTime(canon)
    if not t then return false end
    local mineT = self:CanonTime(self.cb.heldCanon(key))
    return mineT == nil or t > mineT
end

--- Newer, by publish time, with nil sorting as "no version" (never newer).
function NP:CanonIsNewer(a, b)
    local ta, tb = self:CanonTime(a), self:CanonTime(b)
    if ta == nil then return false end
    if tb == nil then return true end
    return ta > tb
end

-- ─── Broadcast / offer ──────────────────────────────────────────────────────

--- The entries this client can SERVE: one per numbered key with a servable canon.
function NP:ServableEntries()
    local N = self._host.numbers
    local entries = {}
    for _, key in ipairs(N.cb.keys() or {}) do
        local num = N:NumberOf(key)
        local canon = num and self.cb.servableCanon(N:Norm(key))
        if num and canon then entries[#entries + 1] = { number = num, canon = canon } end
    end
    table.sort(entries, function(a, b) return a.number < b.number end)
    return entries
end

--- Broadcast what we can serve (hlb2) and open the collect window. `extra`
-- fields are merged into the message for the host's own use (e.g. its addon
-- version) and are visible to peers through onOfferReceived.
function NP:Broadcast(priority, extra)
    local host, N = self._host, self._host.numbers
    N:Mint()
    self:BeginConsult()
    local msg = { type = "hlb2", v = N:Version(), e = N:EncodeEntries(self:ServableEntries()) }
    if type(extra) == "table" then
        for k, v in pairs(extra) do if msg[k] == nil then msg[k] = v end end
    end
    local message = host:SerializeWithChecksum(msg)
    if not message then return false end
    local ok = host:SendMessage("OFFER", message, "GUILD", nil, priority or "BULK")
    if ok then self:BeginCollectWindow() end
    return ok, #message
end

function NP:BeginConsult()
    self.consultBegun = true
end

function NP:BeginCollectWindow()
    local inst = self
    if self.isCollecting then
        if self.collectTimer then self.collectTimer:Cancel() end
        self.collectTimer = C_Timer.NewTimer(self.COLLECT_WINDOW, function() inst:Dispatch() end)
        self:Dbg("OFFER", "collect window extended (%ds)", self.COLLECT_WINDOW)
        return
    end
    self.isCollecting = true
    self.offers = {}
    self.collectTimer = C_Timer.NewTimer(self.COLLECT_WINDOW, function() inst:Dispatch() end)
    self:Dbg("OFFER", "collect window started (%ds)", self.COLLECT_WINDOW)
end

--- Record one candidate for a key. Canon-bearing mentions refresh a bare one;
-- a fresh bare offer from a peer that answered "nothing" is a new claim.
function NP:RecordCandidate(key, peer, canon)
    self.offers[key] = self.offers[key] or {}
    local list = self.offers[key]
    local entry
    for _, e in ipairs(list) do if e.peer == peer then entry = e break end end
    local updatedAt = self:CanonTime(canon) or 0
    if entry then
        if canon then entry.canon = canon end
        if updatedAt > (entry.updatedAt or 0) then entry.updatedAt = updatedAt end
        if not canon and not entry.canon then entry.queried, entry.answered = nil, nil end
        return entry
    end
    entry = { peer = peer, canon = canon, updatedAt = updatedAt }
    local inserted = false
    for i, e in ipairs(list) do
        if updatedAt > (e.updatedAt or 0) then table.insert(list, i, entry) inserted = true break end
    end
    if not inserted then list[#list + 1] = entry end
    return entry
end

--- Does a message stamped with table version `v` number items the way we do?
function NP:TableMatches(v)
    return self._host.numbers:Reads(v)
end

--- A per-instance table created on first use. Init's keep() creates these, but
-- an instance from an older MINOR that survives a LibStub upgrade without a
-- re-Init never ran the new keep() lines, and indexing the missing field would
-- raise mid-session (Peer Review on self-audit 716a6ebc).
function NP:_Own(field)
    local t = rawget(self, field)
    if t == nil then t = {}; self[field] = t end
    return t
end

--- Send our numbers table to `sender`, at most once per REQUEST_COOLDOWN. The one
-- gate for every unasked table send, so a peer that keeps broadcasting from an
-- old table is not sent the whole table each time.
function NP:SendTableTo(sender)
    local N = self._host.numbers
    local sent = self:_Own("tableSentTo")
    local last = sent[sender]
    if last and now() - last <= N.REQUEST_COOLDOWN then return false end
    sent[sender] = now()
    return N:HandleRequest(sender)
end

--- Keep a broadcast we could not read in full, one per sender (a later one is
-- its sender's current word and replaces it), for OnNumbersChanged to replay once
-- a table that resolves every entry lands. Two cases: the sender is on a table
-- AHEAD of ours, or on ours but naming numbers we lack (the bootstrap window, a
-- guild's first sync). THE NAME IS A CONSUMER CONTRACT: Questbook feature-detects
-- it to retire its own stand-in (inbox 12ca628b).
function NP:ParkBroadcast(sender, data)
    self:_Own("parkedBroadcasts")[sender] = { data = data, at = now() }
    self:Dbg("OFFER", "parked %s's broadcast (table v%s) until our table resolves it", sender, tostring(data.v))
end

--- A bare offer came stamped with a table version other than ours, so its
-- numbers cannot be read through our table. A sender AHEAD of us was already
-- asked for its table (OnAdvertisedVersion); returns true so the caller parks the
-- offer for OnNumbersChanged. A sender BEHIND us is sent our table, once per
-- REQUEST_COOLDOWN, and the offer is dropped (returns false): its numbering is one
-- we will never hold.
function NP:OnTableMismatch(sender, v)
    local N = self._host.numbers
    local theirs = tonumber(v) or 0
    if theirs > N:Version() then
        self:Dbg("OFFER", "%s numbers on table v%d, ours is v%d -- parked until we adopt theirs", sender, theirs, N:Version())
        return true
    end
    self:SendTableTo(sender)
    self:Dbg("OFFER", "%s numbers on table v%d, behind our v%d -- not read; sent our table", sender, theirs, N:Version())
    return false
end

--- A peer broadcast what it can serve (OFFER / GUILD, type hlb2).
--   1. Numbers-table sync: behind their version -> ask for the table.
--   2. Every entry names a canon for a key -> onAdvertised (self included).
--   3. Strictly newer than what WE hold -> it is an OFFER from that sender: fold
--      into the collect window, or dispatch now if none is open.
--   4. For every listed key where WE hold strictly newer -> whisper a bare offer.
function NP:OnBroadcast(sender, data)
    local N = self._host.numbers
    if type(data) ~= "table" then return end
    N:OnAdvertisedVersion(sender, data.v)
    -- Their entries are numbered in THEIR table and are read only when it is ours.
    --   AHEAD of us: parked whole until we adopt theirs (already requested above).
    --   BEHIND us (a wipe, a fresh install at v0, a straggler): not read at all, so
    --   every key we serve counts as unmentioned -- they get our table first and the
    --   offer, which they park until that table lands. An equal key costs them one
    --   version-query answer; a misread one cost the guild a wrong fetch.
    local theirs = tonumber(data.v) or 0
    local readable = self:TableMatches(theirs)
    if not readable and theirs > N:Version() then
        self:ParkBroadcast(sender, data)
        return
    end

    local entries = readable and N:DecodeEntries(data.e) or {}
    local unknown = 0
    local offerBack = {}
    local improving = {}
    local named = {}
    local capable = self.cb.peerCapable(sender)

    for _, e in ipairs(entries) do
        named[e.number] = true
        local key = N:KeyOf(e.number)
        if not key then
            unknown = unknown + 1
        else
            self:Observe("onAdvertised", key, e.canon, sender)
            local own = self.cb.isOwnKey(key)
            -- 3. their copy improves ours -> an offer we can act on (never for a key we author)
            if not own and capable and self.cb.isValidPeer(Norm(sender)) and self:Improves(key, e.canon) then
                improving[#improving + 1] = { key = key, canon = e.canon }
            end
            -- 4. our copy is strictly newer than theirs -> offer it
            local mine = self.cb.servableCanon(key)
            if mine and self:CanonIsNewer(mine, e.canon) then
                offerBack[#offerBack + 1] = e.number
            end
        end
    end

    if unknown > 0 then
        -- They name numbers we cannot on a table we read (the bootstrap window),
        -- which the version gate above cannot see. What resolved was acted on
        -- above; the whole line is kept and replayed once every entry resolves,
        -- so the entries we could not name are judged too. Replaying repeats the
        -- resolved part: candidates de-dup per peer and no second session or
        -- version query opens for a key already in one; at worst an offer-back is
        -- whispered twice.
        self:ParkBroadcast(sender, data)
        self.requestedForUnknown = self.requestedForUnknown or {}
        if not self.requestedForUnknown[sender] or now() - self.requestedForUnknown[sender] > N.REQUEST_COOLDOWN then
            self.requestedForUnknown[sender] = now()
            self._host:SendHandshake(sender, { type = "numbers-request", v = N:Version() }, "NORMAL")
            self:Dbg("OFFER", "%s named %d number(s) we cannot -- asked for its table", sender, unknown)
        end
    end

    -- 5. Every key we can serve that the broadcast did NOT list. A broadcast lists
    --    what its sender can SERVE, so an absent key is one it holds nothing for --
    --    wipe recovery, a fresh install -- and step 4 can never offer it. Only to a
    --    peer we would talk to and that can complete the data leg: its OnOffer
    --    would refuse anyone else at the door. (TOGBank, DS-008 thread, ask 1.)
    local unmentioned = 0
    if capable and self.cb.isValidPeer(Norm(sender)) then
        for _, e in ipairs(self:ServableEntries()) do
            if not named[e.number] then
                offerBack[#offerBack + 1] = e.number
                unmentioned = unmentioned + 1
            end
        end
    end

    if #offerBack > 0 then
        table.sort(offerBack)
        -- A broadcaster BEHIND on the table cannot resolve what we are about to
        -- offer, and its own numbers-request (sent on this offer's `v`) is answered
        -- after the offer has left. So the table goes FIRST, unasked -- the same
        -- reply that request would draw; adopting it twice changes nothing. On a
        -- throttled wire the offer can still overtake it, which is what parking in
        -- OnOffer is for.
        if theirs < N:Version() then self:SendTableTo(sender) end
        if unmentioned > 0 then
            self:Dbg("OFFER", "%s's broadcast left out %d key(s) we can serve -- offering them", sender, unmentioned)
        end
        local message = self._host:SerializeWithChecksum({ type = "hash-offer2", v = N:Version(), n = N:EncodeNumbers(offerBack) })
        if message then
            self:Dbg("OFFER", "offering %d number(s) to %s", #offerBack, sender)
            self._host:SendMessage("OFFER", message, nil, sender, "NORMAL")
        end
    end

    if #improving > 0 then
        local touched = {}
        for _, it in ipairs(improving) do
            local sid = self.sessionsByKey[it.key]
            if sid and self.sessions[sid] then
                -- A live session learns the new version and this holder.
                local s = self.sessions[sid]
                local found
                for _, c in ipairs(s.candidates) do if c.peer == sender then found = c break end end
                if found then found.canon = it.canon; found.updatedAt = self:CanonTime(it.canon) or 0
                else s.candidates[#s.candidates + 1] = { peer = sender, canon = it.canon, updatedAt = self:CanonTime(it.canon) or 0 } end
                self:Dbg("OFFER", "%s: %s advertises %s -- folded into live session %s", it.key, sender, it.canon, sid)
            else
                self:RecordCandidate(it.key, sender, it.canon)
                touched[#touched + 1] = it.key
            end
        end
        if #touched > 0 and not self.isCollecting then
            self:Dbg("DISPATCH", "%s advertises newer for %d key(s) outside a window -- acting now", sender, #touched)
            self:DispatchOrQuery(self:OffersToList(touched))
        end
    end
end

--- A peer whispered a bare offer (OFFER / WHISPER, type hash-offer2): "I hold
-- newer for these numbers." It names WHO, not WHAT; the version query decides.
function NP:OnOffer(sender, data)
    local N = self._host.numbers
    if type(data) ~= "table" then return end
    N:OnAdvertisedVersion(sender, data.v)
    local normSender = Norm(sender)
    if not self.cb.isValidPeer(normSender) then
        self:Dbg("OFFER", "offer from %s ignored (isValidPeer=false)", sender)
        return
    end
    local ok, why = self.cb.peerCapable(sender)
    if not ok then
        self:Dbg("OFFER", "offer from %s ignored (%s): cannot complete the data leg with us", sender, tostring(why))
        return
    end
    if not self:TableMatches(data.v) then
        -- Their numbers, not ours: every one waits for their table.
        if self:OnTableMismatch(sender, data.v) then
            self:ParkUnresolved(sender, data.v, N:DecodeNumbers(data.n))
        end
        return
    end
    local late = not self.isCollecting
    local touched = {}
    local unresolved = {}
    for _, num in ipairs(N:DecodeNumbers(data.n)) do
        local key = N:KeyOf(num)
        if not key then
            unresolved[#unresolved + 1] = num
        elseif not self.sessionsByKey[key] then
            -- A bare offer for a key WE author is let through to the version
            -- query: it is the only prompt signal a second PC on the account
            -- gets that it is behind on itself. Nothing is ever fetched for it.
            self:RecordCandidate(key, sender, nil)
            touched[#touched + 1] = key
            if not self.cb.isOwnKey(key) then
                self:Observe("onNewerOffered", key, sender)
            end
            self:Dbg("OFFER", "  offer: %s from %s (version unknown)", key, sender)
        end
    end
    self:ParkUnresolved(sender, data.v, unresolved)
    if late and #touched > 0 then
        self:Dbg("DISPATCH", "late offer from %s outside the collect window: acting on %d key(s) now", sender, #touched)
        self:DispatchOrQuery(self:OffersToList(touched))
    end
end

--- Keep the numbers a bare offer named that our table cannot resolve yet, until
-- a table that can arrives (OnNumbersChanged). One park per sender: a peer's
-- later offer is its current word and replaces the earlier one, so a chatty peer
-- cannot grow it. (TOGBank, DS-008 thread, ask 2.)
--
-- WHY NOT DROP IT: the offerer sends its table (five chunks, HANDSHAKE) and the
-- offer (one chunk, OFFER) in that order, but ChatThrottleLib round-robins the
-- two prefixes a chunk at a time, so the offer ARRIVES first. Measured on
-- TOGBank's throttled fleet: table +10..+13 s, offer +11 s -- dropped, the window
-- closed empty, and the sync waited for the catch-up broadcast at +111 s.
function NP:ParkUnresolved(sender, v, numbers)
    if #numbers == 0 then
        self.parkedOffers[sender] = nil
        return 0
    end
    self.parkedOffers[sender] = { v = v, numbers = numbers, at = now() }
    self:Dbg("OFFER", "parked %d number(s) %s offered that table v%d cannot resolve yet",
        #numbers, sender, self._host.numbers:Version())
    return #numbers
end

--- The numbers table was minted or adopted (called by DeltaSyncNumbers.lua):
-- every parked number it now resolves goes back through OnOffer as if the offer
-- had arrived after the table -- recorded with the rest inside a collect window,
-- acted on at once after one. A park older than QUEUE_TTL is dropped: by then the
-- catch-up cycle has asked again. Returns how many numbers were replayed.
--
-- THE NAME IS A CONSUMER CONTRACT -- do not rename it without telling
-- TOGBankClassic. It feature-detects THIS METHOD as its proxy for all three
-- MINOR 19 delivery rules (unmentioned offers, parking, onOfferReceived first)
-- and warns the player their DeltaSync is out of date when it is absent
-- (TOGBank P2P:WarnIfLibraryBehind, DS-008 thread, 2026-09-16). A rename would
-- make every up-to-date player see that warning. Pinned by numbered_p2p_spec,
-- which calls it by name.
function NP:OnNumbersChanged(reason)
    local N = self._host.numbers
    local replayed = 0
    local senders = {}
    for sender in pairs(self.parkedOffers) do senders[#senders + 1] = sender end
    table.sort(senders)
    for _, sender in ipairs(senders) do
        local park = self.parkedOffers[sender]
        local pv = tonumber(park.v) or 0
        if now() - park.at > self.QUEUE_TTL then
            self.parkedOffers[sender] = nil
            self:Dbg("OFFER", "dropped %s's parked offer: older than %ds", sender, self.QUEUE_TTL)
        elseif not N:Reads(pv) and pv < N:Version() then
            -- Our table moved to a lineage theirs is not in: never readable now.
            self.parkedOffers[sender] = nil
            self:Dbg("OFFER", "dropped %s's parked offer: numbered on v%d, we are on v%d", sender, pv, N:Version())
        elseif N:Reads(pv) then
            local ready, still = {}, {}
            for _, num in ipairs(park.numbers) do
                if N:KeyOf(num) then ready[#ready + 1] = num else still[#still + 1] = num end
            end
            if #ready > 0 then
                self:Dbg("OFFER", "table %s (v%d): replaying %d parked number(s) from %s",
                    tostring(reason), N:Version(), #ready, sender)
                self:OnOffer(sender, { type = "hash-offer2", v = park.v, n = N:EncodeNumbers(ready) })
                replayed = replayed + #ready
                -- OnOffer re-parked nothing (every number it saw resolves) and so
                -- cleared this sender's park; the still-unresolved remainder stays.
                if #still > 0 then
                    self.parkedOffers[sender] = { v = park.v, numbers = still, at = park.at }
                end
            end
        end
    end
    -- Parked broadcasts (ParkBroadcast): replayed once our table reads theirs AND
    -- names every entry; dropped once our table has moved to a lineage theirs is
    -- not in, or after QUEUE_TTL. A newer table than ours keeps waiting.
    local bsenders = {}
    for sender in pairs(self:_Own("parkedBroadcasts")) do bsenders[#bsenders + 1] = sender end
    table.sort(bsenders)
    for _, sender in ipairs(bsenders) do
        local park = self.parkedBroadcasts[sender]
        local pv = tonumber(park.data.v) or 0
        local reads = N:Reads(pv)
        if now() - park.at > self.QUEUE_TTL or (not reads and pv < N:Version()) then
            self.parkedBroadcasts[sender] = nil
            self:Dbg("OFFER", "dropped %s's parked broadcast (v%d, ours v%d)", sender, pv, N:Version())
        elseif reads then
            local all = true
            for _, e in ipairs(N:DecodeEntries(park.data.e)) do
                if not N:KeyOf(e.number) then all = false break end
            end
            if all then
                self.parkedBroadcasts[sender] = nil
                self:Dbg("OFFER", "table %s (v%d): replaying %s's parked broadcast", tostring(reason), N:Version(), sender)
                self:OnBroadcast(sender, park.data)
            end
        end
    end
    return replayed
end

--- The offers recorded for `keys`, canon-first, as a dispatch list.
function NP:OffersToList(keys)
    local list = {}
    for _, key in ipairs(keys) do
        local offerList = self.offers[key]
        if offerList and #offerList > 0 and not self.sessionsByKey[key] then
            table.sort(offerList, function(a, b)
                if (a.canon ~= nil) ~= (b.canon ~= nil) then return a.canon ~= nil end
                return (a.updatedAt or 0) > (b.updatedAt or 0)
            end)
            list[#list + 1] = { key = key, candidates = offerList }
        end
    end
    table.sort(list, function(a, b)
        local ac, bc = a.candidates[1].canon ~= nil, b.candidates[1].canon ~= nil
        if ac ~= bc then return ac end
        return tostring(a.key) < tostring(b.key)
    end)
    return list
end

-- ─── Collect window closes ──────────────────────────────────────────────────

function NP:Dispatch()
    self.collectTimer = nil
    self.isCollecting = false
    local keys = {}
    for key in pairs(self.offers) do keys[#keys + 1] = key end
    local list = self:OffersToList(keys)
    if #list == 0 then
        self:Dbg("DISPATCH", "no offers to dispatch")
        self:MarkSelfConsulted("collect window closed, no offers")
        self:ScheduleCatchUp("no_offers")
        return
    end
    self:Dbg("DISPATCH", "%d key(s) with offers", #list)
    self:DispatchOrQuery(list)
    local ownQueried = false
    for key in pairs(self.versionQueries) do
        if self.cb.isOwnKey(key) then ownQueried = true break end
    end
    if not ownQueried then
        self:MarkSelfConsulted("collect window closed, nobody offered our own key")
    end
end

--- Drop candidates that cannot complete the data leg with us.
function NP:CapableCandidates(candidates, key)
    local kept, dropped, sample = {}, 0, {}
    for _, c in ipairs(candidates or {}) do
        local ok, why = self.cb.peerCapable(c.peer)
        if ok then kept[#kept + 1] = c
        else
            dropped = dropped + 1
            if #sample < 3 then sample[#sample + 1] = c.peer .. "(" .. tostring(why) .. ")" end
        end
    end
    if dropped > 0 then
        self:Dbg("DISPATCH", "%s: not asking %d holder(s) that cannot complete the data leg: %s%s",
            tostring(key), dropped, table.concat(sample, ", "),
            dropped > #sample and (" +" .. (dropped - #sample) .. " more") or "")
    end
    return kept
end

--- Items whose candidates all carry a canon dispatch now; the rest have their
-- version-less candidates asked. The AUTHOR already among the candidates with
-- its canon ends the question -- nothing anyone else says can beat it.
function NP:DispatchOrQuery(list)
    local ready, query = {}, {}
    for _, item in ipairs(list) do
        item.candidates = self:CapableCandidates(item.candidates, item.key)
        if #item.candidates == 0 then
            -- Every offer came from a peer we will not ask: nobody we can hear
            -- from has claimed newer.
            self:Observe("onNewerCleared", item.key)
        else
            local needs, authorKnown = false, false
            for _, c in ipairs(item.candidates) do
                if c.canon == nil then needs = true end
                if c.canon ~= nil and IsAuthor(c.peer, item.key) then authorKnown = true end
            end
            if needs and authorKnown then
                local kept = {}
                for _, c in ipairs(item.candidates) do if c.canon ~= nil then kept[#kept + 1] = c end end
                item.candidates = kept
                needs = false
            end
            if needs then query[#query + 1] = item else ready[#ready + 1] = item end
        end
    end
    if #ready > 0 then self:JudgeAndDispatch(ready) end
    if #query > 0 then self:BeginVersionQuery(query) end
end

--- For items whose every candidate carries a canon: keep only the holders of
-- the newest canon that improves ours, and dispatch to them.
function NP:JudgeAndDispatch(items)
    local dispatchable = {}
    for _, item in ipairs(items) do
        -- Nothing is fetched for a key we author; the observers have already
        -- said what the guild holds.
        if not self.cb.isOwnKey(item.key) then
            local live = {}
            for _, c in ipairs(item.candidates) do
                if c.canon and self:Improves(item.key, c.canon) then live[#live + 1] = c end
            end
            if #live == 0 then
                self:Dbg("VERSION", "%s: nobody holds a version newer than ours", item.key)
                self:Observe("onNewerCleared", item.key)
            else
                local inst = self
                table.sort(live, function(a, b)
                    local ta, tb = inst:CanonTime(a.canon) or 0, inst:CanonTime(b.canon) or 0
                    if ta ~= tb then return ta > tb end
                    return IsAuthor(a.peer, item.key) and not IsAuthor(b.peer, item.key)
                end)
                local want = live[1].canon
                local chosen = {}
                for _, c in ipairs(live) do if c.canon == want then chosen[#chosen + 1] = c end end
                item.candidates = chosen
                item.canon = want
                dispatchable[#dispatchable + 1] = item
            end
        end
    end
    if #dispatchable > 0 then self:DispatchList(dispatchable) end
end

-- ─── Version query ──────────────────────────────────────────────────────────

local function authorFirst(candidates, key)
    local out = {}
    for _, c in ipairs(candidates) do if IsAuthor(c.peer, key) then out[#out + 1] = c end end
    for _, c in ipairs(candidates) do if not IsAuthor(c.peer, key) then out[#out + 1] = c end end
    return out
end

function NP:BeginVersionQuery(items)
    local N = self._host.numbers
    local perPeer = {}
    for _, item in ipairs(items) do
        local key = item.key
        if not self.sessionsByKey[key] and not self.versionQueries[key] then
            local num = N:NumberOf(key)
            if not num then
                self:Dbg("VERSION", "%s has no number yet; cannot ask who holds which version", key)
            else
                local asked = 0
                for _, c in ipairs(authorFirst(item.candidates, key)) do
                    if asked >= self.VERSION_QUERY_MAX then break end
                    if c.canon == nil and not c.queried then
                        c.queried = true
                        asked = asked + 1
                        perPeer[c.peer] = perPeer[c.peer] or {}
                        table.insert(perPeer[c.peer], num)
                    end
                end
                self.versionQueries[key] = item
                if asked > 0 then
                    self:Dbg("VERSION", "%s: asking %d peer(s) which version they hold", key, asked)
                else
                    -- Everyone version-less was already asked and never answered.
                    self:FinishVersionQuery(key)
                end
            end
        end
    end
    for peer, numbers in pairs(perPeer) do
        table.sort(numbers)
        self._host:SendHandshake(peer, { type = "ver-query", v = N:Version(), n = N:EncodeNumbers(numbers) }, "ALERT")
    end
    if not self.versionQueryTimer and next(self.versionQueries) then
        local inst = self
        self.versionQueryTimer = C_Timer.NewTimer(self.VERSION_QUERY_WINDOW, function()
            inst.versionQueryTimer = nil
            inst:FinishVersionQueries()
        end)
    end
end

--- A peer asked what we hold. Always answer, even with nothing, so it stops waiting.
-- `v` is the table the asked numbers are in (nil from a build that did not send
-- it, read the old way). On a different table we answer nothing and say which
-- table we are on, so the asker neither reads our canons against its keys nor
-- takes "nothing" for an answer (OnVersionReply ignores a mismatched reply).
function NP:HandleVersionQuery(sender, encoded, v)
    local N = self._host.numbers
    if not sender then return end
    local entries = {}
    local asked = N:DecodeNumbers(encoded)
    if v ~= nil then
        N:OnAdvertisedVersion(sender, v)
        if not self:TableMatches(v) then asked = {} end
    end
    for _, num in ipairs(asked) do
        local key = N:KeyOf(num)
        local canon = key and self.cb.servableCanon(key)
        if canon then entries[#entries + 1] = { number = num, canon = canon } end
    end
    -- `n` echoes the numbers that were ASKED, so the requester can tell "asked
    -- and holds nothing" from "was never asked about this key in this reply".
    -- Without it, a reply to a query about key Y marked a SEPARATE outstanding
    -- query about key X to the same peer as answered-with-nothing. A peer on a
    -- build that does not echo `n` is read the old way.
    self._host:SendHandshake(sender, { type = "ver-reply", v = N:Version(), e = N:EncodeEntries(entries), n = encoded }, "ALERT")
    self:Dbg("VERSION", "ver-query from %s: answered %d of %d", sender, #entries, #asked)
end

--- A queried peer answered. A key whose author answered, or whose every asked
-- peer has answered, is judged at once.
-- @param askedEncoded  optional run of the numbers this reply answers (see
--   HandleVersionQuery); when present, only those keys are marked answered.
-- @param v  optional: the replier's table version. A reply on another table is
--   not read -- its numbers are not ours -- and counts as "holds nothing" for
--   every query outstanding to that peer. Waiting on it instead left the offer
--   raised with nothing to clear it (Peer Review on self-audit 716a6ebc, F1).
--   A later genuine offer raises it again.
function NP:OnVersionReply(sender, encoded, askedEncoded, v)
    local N = self._host.numbers
    if not sender then return end
    if v ~= nil then
        N:OnAdvertisedVersion(sender, v)
        if not self:TableMatches(v) then
            self:Dbg("VERSION", "ver-reply from %s on table v%d, ours v%d -- not read; counted as holding nothing",
                sender, tonumber(v) or 0, N:Version())
            encoded, askedEncoded = "", nil
        end
    end
    local held = {}
    for _, e in ipairs(N:DecodeEntries(encoded)) do
        local key = N:KeyOf(e.number)
        if key then
            held[key] = e.canon
            self:Observe("onAdvertised", key, e.canon, sender)
        end
    end
    local askedKeys
    if type(askedEncoded) == "string" then
        askedKeys = {}
        for _, num in ipairs(N:DecodeNumbers(askedEncoded)) do
            local key = N:KeyOf(num)
            if key then askedKeys[key] = true end
        end
    end
    local done = {}
    for key, item in pairs(self.versionQueries) do
        local touched, allAnswered = false, true
        local answersThisKey = (askedKeys == nil) or askedKeys[key] or held[key] ~= nil
        for _, c in ipairs(item.candidates) do
            if answersThisKey and c.peer == sender and c.queried and not c.answered then
                c.answered = true
                c.canon = held[key]
                c.updatedAt = self:CanonTime(held[key]) or 0
                touched = true
            end
            if c.queried and not c.answered then allAnswered = false end
        end
        if touched then
            self:Dbg("VERSION", "%s: %s holds %s", key, sender, held[key] or "nothing servable")
            if IsAuthor(sender, key) or allAnswered then done[#done + 1] = key end
        end
    end
    for _, key in ipairs(done) do self:FinishVersionQuery(key) end
end

function NP:FinishVersionQuery(key)
    local item = self.versionQueries[key]
    if not item then return end
    self.versionQueries[key] = nil
    -- Every query settled early: the window timer has nothing left to judge.
    if not next(self.versionQueries) and self.versionQueryTimer then
        self.versionQueryTimer:Cancel()
        self.versionQueryTimer = nil
    end
    local function stillWaiting(c)
        return c.queried and not c.answered and (self.cb.peerCapable(c.peer))
    end
    if self.cb.isOwnKey(key) then
        for _, c in ipairs(item.candidates) do
            if stillWaiting(c) then
                self:Dbg("VERSION", "%s is ours: a peer that offered newer never answered -- not settled", key)
                return
            end
        end
        self:MarkSelfConsulted("version query answered")
        return
    end
    local live = {}
    for _, c in ipairs(item.candidates) do
        if c.canon and self:Improves(key, c.canon) then live[#live + 1] = c end
    end
    if #live == 0 then
        self:Dbg("VERSION", "%s: nobody who offered holds a version newer than ours", key)
        local unanswered = false
        for _, c in ipairs(item.candidates) do if stillWaiting(c) then unanswered = true break end end
        if not unanswered then self:Observe("onNewerCleared", key) end
        return
    end
    self:JudgeAndDispatch({ item })
end

function NP:FinishVersionQueries()
    local keys = {}
    for key in pairs(self.versionQueries) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do self:FinishVersionQuery(key) end
end

-- ─── Self-consult (a shared account on several PCs) ─────────────────────────

function NP:MarkSelfConsulted(reason)
    if self.selfConsulted then return end
    self.selfConsulted = true
    self:Dbg("VERSION", "own-key check settled (%s)", tostring(reason))
    self:Observe("onSelfConsulted", reason)
end

--- May a partial local read trust that nobody holds a newer version of a key we
-- author? True once the cycle has answered -- and before it has been ASKED.
function NP:IsSelfConsulted()
    return self.selfConsulted == true or not self.consultBegun
end

-- ─── Dispatch ───────────────────────────────────────────────────────────────

local function PickPeer(candidates, tried, peerLoad)
    local best, bestLoad = nil, math.huge
    for _, c in ipairs(candidates) do
        if not tried[c.peer] then
            local load = peerLoad[c.peer] or 0
            if load < bestLoad then bestLoad, best = load, c.peer end
        end
    end
    return best
end

--- Park one item per key; the newest candidates replace the old.
function NP:QueuePending(item)
    for i, parked in ipairs(self.pendingDispatch) do
        if parked.key == item.key then self.pendingDispatch[i] = item return end
    end
    self.pendingDispatch[#self.pendingDispatch + 1] = item
end

--- Open sessions IN PARALLEL ACROSS PEERS: the only cap is per peer.
function NP:DispatchList(list)
    local peerLoad = {}
    for _, s in pairs(self.sessions) do
        if s.state == STATE.DISPATCHED or s.state == STATE.ACTIVE then
            peerLoad[s.peer] = (peerLoad[s.peer] or 0) + 1
        end
    end
    for _, item in ipairs(list) do
        item.candidates = self:CapableCandidates(item.candidates, item.key)
        if not self.sessionsByKey[item.key] and #item.candidates > 0 then
            local busy = {}
            for _, c in ipairs(item.candidates) do
                if (peerLoad[c.peer] or 0) >= self.MAX_SESSIONS_PER_PEER then busy[c.peer] = true end
            end
            local peer = PickPeer(item.candidates, busy, peerLoad)
            if not peer then
                self:QueuePending(item)
            else
                peerLoad[peer] = (peerLoad[peer] or 0) + 1
                local sid = MakeSessionId(item.key)
                self.sessions[sid] = {
                    sessionId  = sid,
                    key        = item.key,
                    canon      = item.canon,
                    state      = STATE.DISPATCHED,
                    peer       = peer,
                    candidates = item.candidates,
                    triedPeers = { [peer] = true },
                    timers     = {},
                }
                self.sessionsByKey[item.key] = sid
                self.activeSessions = self.activeSessions + 1
                self:SendSyncRequest(sid)
                self:Dbg("DISPATCH", "  -> %s to %s (sid=%s)", tostring(item.key), peer, sid)
            end
        end
    end
end

function NP:ArmSessionTimer(s, name, delay, callback)
    s.timers = s.timers or {}
    local existing = s.timers[name]
    if existing and type(existing) == "table" and existing.Cancel then existing:Cancel() end
    s.timers[name] = C_Timer.NewTimer(delay, callback)
    return s.timers[name]
end

function NP:CancelTimers(s)
    for _, t in pairs(s.timers or {}) do
        if t and type(t) == "table" and t.Cancel then t:Cancel() end
    end
    s.timers = {}
end

function NP:SendSyncRequest(sessionId)
    local s = self.sessions[sessionId]
    if not s then return end
    local canon
    for _, c in ipairs(s.candidates or {}) do if c.peer == s.peer then canon = c.canon break end end
    self._host:SendHandshake(s.peer, {
        type = "sync-request", sessionId = sessionId, itemKey = s.key, requester = Me(), canon = canon,
    }, "ALERT")
    local inst = self
    self:ArmSessionTimer(s, "dispatch", self.DISPATCH_TIMEOUT, function()
        local live = inst.sessions[sessionId]
        if live and live.state == STATE.DISPATCHED then
            inst:Dbg("HANDSHAKE", "dispatch timeout for %s/%s -- next candidate", tostring(live.key), live.peer)
            inst:AdvanceCandidate(sessionId, "timeout")
        end
    end)
end

-- ─── Requester side: handshake replies ──────────────────────────────────────

function NP:OnSyncAccept(sessionId, sender)
    local s = self.sessions[sessionId]
    if not s or s.state ~= STATE.DISPATCHED then
        -- An accept we cannot use: the peer took a slot for us. Give it back now
        -- rather than letting it wait out STATE_WAIT.
        self:Dbg("HANDSHAKE", "accept for %s from %s cannot be used (%s) -- cancelling", tostring(sessionId), sender,
            s and ("state " .. s.state) or "unknown session")
        self._host:SendHandshake(sender, { type = "sync-cancel", sessionId = sessionId }, "ALERT")
        return
    end
    if s.timers.dispatch then s.timers.dispatch:Cancel(); s.timers.dispatch = nil end
    s.state = STATE.ACTIVE
    self:Dbg("HANDSHAKE", "ACTIVE: %s <- %s", tostring(s.key), sender)
    local inst = self
    self:ArmSessionTimer(s, "delivery", self.DELIVERY_TIMEOUT, function()
        local live = inst.sessions[sessionId]
        if live and live.state == STATE.ACTIVE then
            inst:Dbg("COMPLETE", "delivery timeout for %s", tostring(live.key))
            inst:_FailSession(sessionId, "delivery_timeout")
        end
    end)
    local canon
    for _, c in ipairs(s.candidates or {}) do if c.peer == sender then canon = c.canon break end end
    self.cb.onDeliver(s.key, canon or s.canon, sender)
end

--- sync-busy. reason="version" means "that candidate does not hold that canon":
-- treated exactly like any other busy -- the next candidate -- and never as a
-- reason to wait in that peer's queue.
function NP:OnSyncBusy(sessionId, sender, reason)
    local s = self.sessions[sessionId]
    if not s then return end
    self:Dbg("HANDSHAKE", "BUSY (%s): %s from %s -- advancing", reason or "busy", tostring(s.key), sender)
    self:AdvanceCandidate(sessionId, reason == "version" and "version" or "busy")
end

--- The peer queued us. Another untried holder of the same canon -> move on and
-- let the queuing peer forget us; otherwise wait for our turn, past the normal
-- ACK timeout.
function NP:OnSyncQueued(sessionId, sender, position)
    local s = self.sessions[sessionId]
    if not s or s.state ~= STATE.DISPATCHED then return end
    local untried = 0
    for _, c in ipairs(s.candidates or {}) do if not s.triedPeers[c.peer] then untried = untried + 1 end end
    if untried > 0 then
        self._host:SendHandshake(sender, { type = "sync-cancel", sessionId = sessionId }, "ALERT")
        self:Dbg("HANDSHAKE", "QUEUED at %s (position %s) for %s -- %d other holder(s) untried, advancing",
            sender, tostring(position), tostring(s.key), untried)
        self:AdvanceCandidate(sessionId, "queued")
        return
    end
    self:Dbg("HANDSHAKE", "QUEUED at %s (position %s) for %s -- nobody else holds it, waiting", sender, tostring(position), tostring(s.key))
    local inst = self
    self:ArmSessionTimer(s, "dispatch", self.QUEUE_TTL + 10, function()
        local live = inst.sessions[sessionId]
        if live and live.state == STATE.DISPATCHED then
            inst:Dbg("HANDSHAKE", "queue wait expired for %s/%s -- next candidate", tostring(live.key), live.peer)
            inst:AdvanceCandidate(sessionId, "queue_timeout")
        end
    end)
end

--- The provider refused our data QUERY (its accept lapsed). Only the session
-- waiting on THAT peer advances.
function NP:OnQueryRefused(key, sender)
    local sid = self.sessionsByKey[key]
    local s = sid and self.sessions[sid]
    if s then
        if s.peer ~= sender or s.state ~= STATE.ACTIVE then return end
        self:Dbg("HANDSHAKE", "REFUSED: %s from %s (no room for our query) -- advancing", tostring(key), sender)
        self:AdvanceCandidate(sid, "query_refused")
        return
    end
    self:ScheduleCatchUp("query_refused")
end

function NP:AdvanceCandidate(sessionId, reason)
    local s = self.sessions[sessionId]
    if not s then return end
    for _, name in ipairs({ "dispatch", "retry", "delivery" }) do
        if s.timers[name] then s.timers[name]:Cancel(); s.timers[name] = nil end
    end
    s.candidates = self:CapableCandidates(s.candidates, s.key)
    local nextPeer
    for _, c in ipairs(s.candidates) do
        if not s.triedPeers[c.peer] then nextPeer = c.peer break end
    end
    if not nextPeer then
        s.retryCount = (s.retryCount or 0) + 1
        if s.retryCount <= self.MAX_RETRY_CYCLES then
            self:Dbg("HANDSHAKE", "all holders busy for %s (%s), retry %d/%d in %ds",
                tostring(s.key), reason, s.retryCount, self.MAX_RETRY_CYCLES, self.RETRY_CYCLE_DELAY)
            s.triedPeers = {}
            s.state = STATE.DISPATCHED
            local inst = self
            self:ArmSessionTimer(s, "retry", self.RETRY_CYCLE_DELAY, function()
                local live = inst.sessions[sessionId]
                if not live or live.state ~= STATE.DISPATCHED then return end
                local peer = PickPeer(live.candidates, live.triedPeers, {})
                if peer then
                    live.peer = peer
                    live.triedPeers[peer] = true
                    inst:SendSyncRequest(sessionId)
                else
                    inst:_FailSession(sessionId, "no_candidates_on_retry")
                end
            end)
        else
            self:Dbg("HANDSHAKE", "all holders exhausted for %s (%s) after %d retry cycles", tostring(s.key), reason, s.retryCount)
            self:_FailSession(sessionId, "no_candidates")
        end
        return
    end
    s.peer = nextPeer
    s.triedPeers[nextPeer] = true
    s.state = STATE.DISPATCHED
    self:SendSyncRequest(sessionId)
end

-- ─── Completion / failure ───────────────────────────────────────────────────

function NP:OnItemCompleted(key, sender)
    local sid = self.sessionsByKey[key]
    if not sid then return end
    local s = self.sessions[sid]
    if not s then self.sessionsByKey[key] = nil return end
    self:CancelTimers(s)
    self.activeSessions = math.max(0, self.activeSessions - 1)
    s.state = STATE.COMPLETE
    self.sessions[sid] = nil
    self.sessionsByKey[key] = nil
    self:Observe("onNewerCleared", key)
    self:Dbg("COMPLETE", "COMPLETE: %s from %s", tostring(key), tostring(sender))
    self:_FlushPendingDispatch()
end

function NP:OnItemFailed(sessionIdOrKey, reason)
    local s = self.sessions[sessionIdOrKey]
    if not s then
        local sid = self.sessionsByKey[sessionIdOrKey]
        if sid then s = self.sessions[sid] end
    end
    if s then self:_FailSession(s.sessionId, reason) end
end

function NP:_FailSession(sessionId, reason)
    local s = self.sessions[sessionId]
    if not s then return end
    self:CancelTimers(s)
    self.activeSessions = math.max(0, self.activeSessions - 1)
    s.state = STATE.FAILED
    self.sessions[sessionId] = nil
    self.sessionsByKey[s.key] = nil
    self:Dbg("COMPLETE", "FAILED (%s): %s", reason, tostring(s.key))
    -- The offer that started this session is spent: nobody delivered it. Leaving
    -- it raised kept the consumer showing "update offered" until a reload
    -- (TOGBank, inbox 68a67be9). A later genuine offer raises it again.
    self:Observe("onNewerCleared", s.key)
    self:ScheduleCatchUp("session_failed")
    self:_FlushPendingDispatch()
end

function NP:_FlushPendingDispatch()
    local pending = self.pendingDispatch
    if not pending or #pending == 0 then return end
    self.pendingDispatch = {}
    self:DispatchList(pending)
end

function NP:HasActiveSession(key)
    local sid = self.sessionsByKey[key]
    local s = sid and self.sessions[sid]
    return s ~= nil and (s.state == STATE.DISPATCHED or s.state == STATE.ACTIVE)
end

-- ─── Catch-up ───────────────────────────────────────────────────────────────

function NP:ScheduleCatchUp(reason)
    if self.catchUpTimer then return end
    self.catchUpCycles = (self.catchUpCycles or 0) + 1
    if self.catchUpCycles > self.MAX_CATCH_UP_CYCLES then
        self:Dbg("CATCHUP", "max catch-up cycles (%d) reached (%s) -- giving up", self.MAX_CATCH_UP_CYCLES, reason)
        self.catchUpCycles = 0
        return
    end
    if not self.cb.hasMissingItems() then
        self.catchUpCycles = 0
        return
    end
    self:Dbg("CATCHUP", "scheduling catch-up in %ds (%s, cycle %d/%d)",
        self.CATCH_UP_DELAY, reason, self.catchUpCycles, self.MAX_CATCH_UP_CYCLES)
    local inst = self
    self.catchUpTimer = C_Timer.NewTimer(self.CATCH_UP_DELAY, function()
        inst.catchUpTimer = nil
        if inst.cb.hasMissingItems() then
            inst:Dbg("CATCHUP", "cycle %d: re-broadcasting", inst.catchUpCycles)
            -- The host's broadcastExtra carries what its own Broadcast call would
            -- (an addon version, say) -- asked for at send time, never replayed
            -- stale from an earlier broadcast.
            inst:Broadcast("NORMAL", inst.cb.broadcastExtra and inst.cb.broadcastExtra() or nil)
        else
            inst.catchUpCycles = 0
        end
    end)
end

-- ─── Provider side ──────────────────────────────────────────────────────────

-- Slot accounting -- GetActiveSendTotal, TryAcquireSendSlot, ReleaseSendSlot,
-- _ResolveSlotKey, _DecrementSendSlot -- is the SHARED mixin defined in
-- P2PSession.lua (lib._SendSlotMixin), copied onto this class below. It honours
-- this class's `servingSends` and calls `ServeQueue` when a slot frees. One
-- implementation for both protocols, so a fix lands in both.
if not lib._SendSlotMixin then
    error("DeltaSyncP2PNumbered.lua requires P2PSession.lua to load first (lib._SendSlotMixin is nil). Check TOC order.")
end
for name, fn in pairs(lib._SendSlotMixin) do NP[name] = fn end

--- An inbound sync-request. Accept (slot + STATE_WAIT), queue at capacity, or
-- busy: nothing servable, an incapable requester, or we hold an OLDER canon
-- than the one asked for.
function NP:HandleSyncRequest(sessionId, requester, key, canon)
    if not sessionId or not requester or not key then return false end
    local host = self._host
    local function busy(reason)
        local msg = { type = "sync-busy", sessionId = sessionId }
        if reason then msg.reason = reason end
        host:SendHandshake(requester, msg, "ALERT")
        return false
    end
    if not self.cb.isValidPeer(Norm(requester)) then
        self:Dbg("HANDSHAKE", "request from %s rejected (isValidPeer=false) -- busy", requester)
        return busy()
    end
    if not self.cb.canServe(key) then
        self:Dbg("HANDSHAKE", "nothing servable for %s -- busy to %s", tostring(key), requester)
        return busy()
    end
    local capable, why = self.cb.peerCapable(requester)
    if not capable then
        self:Dbg("HANDSHAKE", "%s cannot complete the data leg (%s) -- busy (version)", requester, tostring(why))
        return busy("version")
    end
    if canon ~= nil then
        local mine = self.cb.servableCanon(key)
        if mine ~= canon and not self:CanonIsNewer(mine, canon) then
            self:Dbg("HANDSHAKE", "%s wants %s at %s, we hold %s -- busy (version)", requester, tostring(key), tostring(canon), tostring(mine))
            return busy("version")
        end
    end
    if self:GetActiveSendTotal() >= self.MAX_ACTIVE_SENDS then
        local position = self:EnqueueSend(sessionId, requester, key)
        self:Dbg("HANDSHAKE", "at capacity -- queued %s for %s at position %d", requester, tostring(key), position)
        host:SendHandshake(requester, { type = "sync-queued", sessionId = sessionId, position = position }, "ALERT")
        return false
    end
    return self:AcceptSend(sessionId, requester, key)
end

function NP:AcceptSend(sessionId, requester, key)
    if not self:TryAcquireSendSlot(requester) then return false end
    self._host:SendHandshake(requester, { type = "sync-accept", sessionId = sessionId }, "ALERT")
    self:Dbg("HANDSHAKE", "accepted %s for %s", tostring(key), requester)
    self:ArmStateWait(requester, key, sessionId)
    return true
end

function NP:EnqueueSend(sessionId, requester, key)
    for i, e in ipairs(self.sendQueue) do
        if e.requester == requester and e.key == key then
            e.sessionId, e.at = sessionId, now()
            return i
        end
    end
    self.sendQueue[#self.sendQueue + 1] = { sessionId = sessionId, requester = requester, key = key, at = now() }
    return #self.sendQueue
end

function NP:DequeueSend(sessionId, requester)
    for i = #self.sendQueue, 1, -1 do
        local e = self.sendQueue[i]
        if e.requester == requester and (sessionId == nil or e.sessionId == sessionId) then
            table.remove(self.sendQueue, i)
        end
    end
end

--- A slot freed: accept the next live entries while there is capacity. The
-- capability and content checks run again HERE -- the queue can hold entries
-- from before we learned a peer's version or lost the content.
function NP:ServeQueue()
    while #self.sendQueue > 0 and self:GetActiveSendTotal() < self.MAX_ACTIVE_SENDS do
        local e = table.remove(self.sendQueue, 1)
        if now() - e.at <= self.QUEUE_TTL then
            local capable = self.cb.peerCapable(e.requester)
            if not capable then
                self._host:SendHandshake(e.requester, { type = "sync-busy", sessionId = e.sessionId, reason = "version" }, "ALERT")
            elseif self.cb.canServe(e.key) then
                self:AcceptSend(e.sessionId, e.requester, e.key)
            else
                self._host:SendHandshake(e.requester, { type = "sync-busy", sessionId = e.sessionId }, "ALERT")
            end
        else
            self:Dbg("HANDSHAKE", "dropping stale queue entry for %s/%s", e.requester, tostring(e.key))
        end
    end
end

--- The requester withdrew: forget its queue entry, and release an accept still
-- waiting on its query.
function NP:OnSyncCancel(sessionId, requester)
    self:DequeueSend(sessionId, requester)
    local key = sessionId and self.stateWaitSids[sessionId]
    if not key then return false end
    self.stateWaitSids[sessionId] = nil
    local t = self.stateWaits[key]
    if not t then return false end
    t:Cancel()
    self.stateWaits[key] = nil
    self:Dbg("HANDSHAKE", "accept %s withdrawn by %s before its query -- releasing slot", key, tostring(requester))
    self:ReleaseSendSlot(requester, "accept_cancelled")
    return true
end

--- After an accept, the requester's QUERY follows within seconds when it is
-- coming at all. Keyed by requester AND key: two accepts to one requester are
-- two waits.
function NP:ArmStateWait(requester, key, sessionId)
    local wkey = requester .. "|" .. tostring(key)
    local prior = self.stateWaits[wkey]
    if prior then prior:Cancel() end
    if sessionId then self.stateWaitSids[sessionId] = wkey end
    local inst = self
    self.stateWaits[wkey] = C_Timer.NewTimer(self.STATE_WAIT, function()
        inst.stateWaits[wkey] = nil
        inst:_ForgetStateWaitSids(wkey)
        inst:Dbg("HANDSHAKE", "no query from %s for %s within %ds of accept -- releasing slot", requester, tostring(key), inst.STATE_WAIT)
        inst:ReleaseSendSlot(requester, "no_query")
    end)
end

function NP:_ForgetStateWaitSids(wkey)
    for sid, k in pairs(self.stateWaitSids) do
        if k == wkey then self.stateWaitSids[sid] = nil end
    end
end

--- The requester's QUERY arrived (call from onDataRequest). Ends the STATE_WAIT
-- and CLAIMS the accepted slot for the reply. Returns true when a slot was
-- claimed and the reply may be sent; false means no accept covers this query
-- (it lapsed, or never happened) and the host should refuse rather than send a
-- BULK reply outside the handshake.
function NP:QueryArrived(requester, key)
    local slotKey = self:_ResolveSlotKey(requester) or requester
    local wkey = slotKey .. "|" .. tostring(key)
    local t = self.stateWaits[wkey]
    if t then t:Cancel(); self.stateWaits[wkey] = nil end
    self:_ForgetStateWaitSids(wkey)
    local held, serving = self.activeSends[slotKey] or 0, self.servingSends[slotKey] or 0
    if held <= serving then return false end
    self.servingSends[slotKey] = serving + 1
    return true
end

--- Send the reply for a claimed slot and give the slot back when it has DRAINED
-- (DS-009 completion), not when it was queued.
function NP:ServeReply(requester, key, data, isDelta, priority)
    local inst = self
    return self._host:SendData(requester, data, isDelta, priority or "BULK", function(info)
        inst:ReleaseSendSlot(requester, string.format("%s drained:%s", tostring(key), tostring(info and info.verdict)))
    end)
end

--- Nothing to send (no-change): give the claimed slot back now.
function NP:ReplyNoChange(requester, key)
    self:ReleaseSendSlot(requester, "no_change:" .. tostring(key))
end

-- Exposed for tests and host diagnostics.
NP.STATE = STATE

--- Host-level entry point: broadcast what this client can serve and open the
-- collect window. The numbered counterpart of BroadcastItemHashes.
-- @param priority  "BULK" (default) / "NORMAL" / "ALERT"
-- @param extra     optional table of host fields merged into the message
function lib:BroadcastNumbered(priority, extra)
    local p2p = rawget(self, "p2p")
    if not p2p or not p2p.Broadcast then
        self:Debug("P2P", "BroadcastNumbered ignored: InitP2P(mode='numbered') has not been called on this host")
        return false
    end
    return p2p:Broadcast(priority, extra)
end
