-- P2PSession.lua
-- Generalized P2P inventory-sync session manager for DeltaSync.
-- Ported from TOGBankClassic's P2PSession.lua (P2P-006 redesign).
--
-- Implements a broadcast / collect / dispatch loop so any peer with fresh data
-- can serve as a provider — no single "banker" bottleneck required.
--
--   Phase 1 (T+0):       host:BroadcastItemHashes(myHashes) sends a hash-list-broadcast
--                         to GUILD via the OFFER channel and opens the collect window.
--   Phase 2 (T+0..W):    Peers whose data for any listed item is newer whisper back a
--                         hash-offer (also on the OFFER channel).
--   Phase 3 (T+W):        Dispatch: for each stale item pick the peer with the highest
--                         updatedAt, send a sync-request whisper (HANDSHAKE channel).
--   Phase 4 (handshake):  Peer replies sync-accept (has capacity → host callback fires
--                         to initiate data delivery) or sync-busy (at cap → next peer).
--
-- Host addon integration
-- ─────────────────────
-- Call host:InitP2P(config) once, after creating the host (lib:NewHost), with:
--
--   config.collectWindow    number   seconds to accumulate offers (default 10)
--   config.maxActiveSessions number  concurrent inbound data streams (default 3)
--   config.maxActiveSends    number  concurrent outbound sends (default 3)
--   config.retryDelay        number  seconds between retry cycles (default 20)
--   config.catchUpDelay      number  seconds before re-broadcasting (default 45)
--   config.maxCatchUpCycles  number  max re-broadcast attempts (default 5)
--   config.deliveryTimeout   number  seconds to wait for data after accept (default 180)
--
--   config.getMyHashes()     → {itemKey → {hash, updatedAt}}
--       Return your full hash map so DeltaSync can build an offer for inbound
--       hash-list-broadcasts.
--
--   config.hasContent(itemKey)  → bool
--       Return true if you have full data for itemKey (used on sender side).
--
--   config.hasMissingItems()  → bool
--       Return true if you still need data from peers (drives catch-up logic).
--
--   config.onSyncAccepted(itemKey, sender)
--       Called when a peer accepted your sync-request.  Initiate data exchange
--       here.  Full post-accept sequence:
--         1. Send a QUERY (your current baseline) to the provider:
--                host:RequestData(sender, myBaseline)
--         2. Provider's onDataRequest fires → it calls host:SendData(you, myDelta, true)
--         3. Your onDataReceived fires → apply the payload, then call:
--                host.p2p:OnItemCompleted(itemKey, sender)
--
-- When your data pipeline receives and applies data for an item you MUST call:
--   host.p2p:OnItemCompleted(itemKey, sender)   — frees the session slot
-- If delivery fails:
--   host.p2p:OnItemFailed(itemKey, reason)
--
-- On the SENDER side, call after the actual wire send completes:
--   host.p2p:ReleaseSendSlot(requester)         — frees the outbound send slot immediately
-- (A safety timer auto-releases the slot after SEND_TIMEOUT seconds as a fallback.)
--
-- Trust boundary — who gates inbound traffic, and why (AUDIT finding 13)
-- ─────────────────────────────────────────────────────────────────────
-- DeltaSync holds three layers with three different gates, and the line between
-- them is a RULE, not a set of accidents:
--
--   * The TRANSPORT (DeltaSync.lua's seven OnComm_* handlers, and the CHANNEL
--     transport) normalises the sender, drops our own echo, and FORWARDS. It
--     commits nothing and discloses nothing of its own, so it applies no
--     eligibility check: the HOST gates in its onDataRequest / onDataReceived
--     callbacks, where it knows its own rank/role rules.
--   * This P2P layer gates with config.isValidPeer on EVERY inbound path, because
--     every one of them either COMMITS a scarce resource (HandleSyncRequest
--     acquires a capped, 90-second send slot) or DISCLOSES what we hold
--     (OnHashListReceived answers with our hashes; OnOffer records a peer as a
--     provider we will later ask for data).
--   * RosterSync (DeltaSyncRoster.lua) gates with ITS OWN, separately scoped
--     isValidPeer -- default accept-all, because a guild roster is already public
--     via /who, so serving it discloses nothing new. Its receive side gates on
--     PROVENANCE instead (the provider must appear in the roster it served).
--
-- The rule: gate wherever the LIBRARY commits or discloses, and choose the
-- default from what the disclosure is worth; forward everything else to the
-- host. The two isValidPeer callbacks are deliberately separate and must not be
-- merged -- different scopes, different defaults, different reasons.

local MAJOR = "DeltaSync-1.0"
local lib   = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then
    -- error() never returns; the `return` that used to follow it was dead by
    -- construction and showed up as a coverage gap for as long as it existed.
    error("DeltaSync P2PSession: DeltaSync-1.0 must be loaded first")
end

-- ─── Class table (methods + read-only default constants) ──────────────────────
-- MINOR 15+: P2P is now a persistent *class* — the shared methods and numeric
-- defaults — kept on lib across LibStub upgrades. Each host owns its own INSTANCE
-- (host.p2p = setmetatable({ _host = host }, { __index = P2P })), created in
-- lib:InitP2P, so all mutable session/offer/slot state is per-host. Storing the
-- class on lib (rather than a fresh file-local table each load) means a hot
-- upgrade redefines methods on the SAME table, so existing host.p2p instances
-- transparently pick up the new code through their metatable.
lib._P2PClass = lib._P2PClass or {}
local P2P = lib._P2PClass

-- LibGuildRoster-1.0 is the roster engine (a required standalone-addon
-- dependency declared in .toc/.pkgmeta; replaced the retired GuildCache-1.0).
-- Soft dep in code — if it's somehow absent, Norm()/Me() degrade gracefully and
-- isValidPeer must be supplied by the host addon.
local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

-- ─── Session state constants ──────────────────────────────────────────────────
local STATE = {
    DISPATCHED = "DISPATCHED",  -- sync-request sent, awaiting ACK
    ACTIVE     = "ACTIVE",      -- sync-accept received, data in-flight
    COMPLETE   = "COMPLETE",
    FAILED     = "FAILED",
}

-- ─── Configurable default constants (shared, read-only) ───────────────────────
-- These live on the class as defaults. Instances read them through __index and
-- only shadow one with an instance-local value when config overrides it in Init.
P2P.COLLECT_WINDOW     = P2P.COLLECT_WINDOW     or 10
P2P.DISPATCH_TIMEOUT   = P2P.DISPATCH_TIMEOUT   or 15
P2P.DELIVERY_TIMEOUT   = P2P.DELIVERY_TIMEOUT   or 180  -- wait for data after sync-accept
P2P.SEND_TIMEOUT       = P2P.SEND_TIMEOUT       or 90   -- outbound-slot safety release
P2P.MAX_ACTIVE_SESSIONS= P2P.MAX_ACTIVE_SESSIONS or 3
P2P.MAX_ACTIVE_SENDS   = P2P.MAX_ACTIVE_SENDS   or 3
P2P.MAX_RETRY_CYCLES   = P2P.MAX_RETRY_CYCLES   or 5
P2P.RETRY_CYCLE_DELAY  = P2P.RETRY_CYCLE_DELAY  or 20
P2P.CATCH_UP_DELAY     = P2P.CATCH_UP_DELAY     or 45
P2P.MAX_CATCH_UP_CYCLES= P2P.MAX_CATCH_UP_CYCLES or 5

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function Norm(name)
    if GuildRoster then return GuildRoster:NormalizeName(name) or name end
    return name
end

local function Me()
    if GuildRoster and GuildRoster.GetNormalizedPlayer then return GuildRoster:GetNormalizedPlayer() end
    return UnitName and UnitName("player") or ""
end

-- Do two hash entries describe different content?
--
-- Compares on the highest hash revision BOTH ends advertise. That is what makes
-- revision 2 deployable without a flag day: a peer on an older build sends only
-- `hash` (revision 1), so the pair falls back to v1 and still agrees; two peers
-- that both send `hashV2` get the collision-free comparison. Mixed guilds never
-- see the false "content differs" that would have them offering each other data
-- forever.
--
-- Retiring revision 1 later is a two-step with no coordination needed: stop
-- emitting `hash` in MakeHashEntry, then delete the fallback below.
local function HashesDiffer(mine, theirs)
    if mine.hashV2 ~= nil and theirs.hashV2 ~= nil then
        return mine.hashV2 ~= theirs.hashV2
    end
    return mine.hash ~= theirs.hash
end
P2P.HashesDiffer = HashesDiffer   -- exposed for tests / host diagnostics

local function MakeSessionId(itemKey)
    -- Millisecond precision prevents collisions on rapid back-to-back cycles.
    local ts = GetTime and math.floor(GetTime() * 1000) or 0
    return Me() .. ":" .. itemKey .. ":" .. tostring(ts)
end

-- Per-host debug: route through the owning host so each addon's P2P traffic lands
-- in ITS debug tab / SavedVariables, not the shared lib's. (Was a file-local Dbg
-- that hard-called lib:Debug — that misrouted every non-default host's logs.)
function P2P:Dbg(tag, fmt, ...)
    local host = self._host
    if host and host.Debug then
        host:Debug("P2P", tag .. " " .. string.format(fmt, ...))
    end
end

-- ─── Init ─────────────────────────────────────────────────────────────────────

--- Initialize this host's P2P session manager.
-- Called by lib:InitP2P() — do not call directly.
-- @param config  see module header for fields
function P2P:Init(config)
    config = config or {}

    -- Re-resolve LibGuildRoster at init (post-load) so Norm/Me and the default
    -- isValidPeer use a live handle even if the file-load-time upvalue captured
    -- nil (load-order / clobber / embedder). Reassigns the shared upvalue.
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))

    -- Tunables: shadow the class default with an instance-local value only when
    -- config supplies one. Reads elsewhere fall through __index to the default.
    if config.collectWindow     then self.COLLECT_WINDOW      = config.collectWindow     end
    if config.maxActiveSessions then self.MAX_ACTIVE_SESSIONS = config.maxActiveSessions end
    if config.maxActiveSends    then self.MAX_ACTIVE_SENDS    = config.maxActiveSends    end
    if config.retryDelay        then self.RETRY_CYCLE_DELAY   = config.retryDelay        end
    if config.catchUpDelay      then self.CATCH_UP_DELAY      = config.catchUpDelay      end
    if config.maxCatchUpCycles  then self.MAX_CATCH_UP_CYCLES = config.maxCatchUpCycles  end
    if config.deliveryTimeout   then self.DELIVERY_TIMEOUT    = config.deliveryTimeout   end

    -- Per-instance mutable state. Use rawget so a re-Init (or hot upgrade that
    -- re-runs InitP2P) preserves in-flight state instead of wiping it, and so the
    -- checks never fall through __index to a sibling/class value.
    if not rawget(self, "sessions")        then self.sessions        = {} end  -- sessionId → session
    if not rawget(self, "sessionsByItem")  then self.sessionsByItem  = {} end  -- itemKey → sessionId
    if not rawget(self, "offers")          then self.offers          = {} end  -- itemKey → [{peer,updatedAt,hash}]
    if not rawget(self, "activeSends")     then self.activeSends     = {} end  -- peerName → count
    if not rawget(self, "sendTimers")      then self.sendTimers      = {} end  -- peerName → [safety timer handles]
    if not rawget(self, "pendingDispatch") then self.pendingDispatch = {} end
    if rawget(self, "activeSessions") == nil then self.activeSessions = 0 end
    if rawget(self, "catchUpCycles")  == nil then self.catchUpCycles  = 0 end
    if rawget(self, "isCollecting")   == nil then self.isCollecting   = false end
    self.collectTimer = rawget(self, "collectTimer") or nil
    self.catchUpTimer = rawget(self, "catchUpTimer") or nil
    self.cb = rawget(self, "cb") or {}

    -- Default stubs take (...) so the LSP doesn't infer a 0-arg signature from
    -- them and then flag the real call sites (hasContent(itemKey),
    -- onSyncAccepted(itemKey,sender), …) as passing redundant parameters.
    self.cb.getMyHashes    = config.getMyHashes    or function(...) return {} end
    self.cb.hasContent     = config.hasContent     or function(...) return false end
    self.cb.hasMissingItems= config.hasMissingItems or function(...) return false end
    self.cb.onSyncAccepted = config.onSyncAccepted or function(...) end
    -- isValidPeer: host addon decides whether a peer is eligible to participate.
    -- Defaults to a guild-membership check via LibGuildRoster-1.0 — only current
    -- guild members can offer/request. Pass a custom function to use PARTY, RAID,
    -- or any other criteria. If LibGuildRoster-1.0 is not loaded, the default
    -- accepts any peer and the host addon is responsible for supplying isValidPeer.
    --
    -- NOTE on semantics: the retired GuildCache:IsInGuild returned true on an
    -- empty/not-yet-built roster so non-guild / early-login peers were never
    -- blocked. LibGuildRoster:IsInGuild is instead a strict membership check, so
    -- we restore the prior behavior here: accept any peer when we're not in a
    -- guild or the roster isn't ready yet, and only filter once it is.
    self.cb.isValidPeer    = config.isValidPeer    or lib._SendSlotMixin.DefaultIsValidPeer()

    self:Dbg("INIT", "P2PSession initialized (collectWindow=%ds, maxSessions=%d, maxSends=%d)",
        self.COLLECT_WINDOW, self.MAX_ACTIVE_SESSIONS, self.MAX_ACTIVE_SENDS)
end

-- ─── Catch-up ─────────────────────────────────────────────────────────────────

--- Schedule a full broadcast/collect/dispatch re-run after CATCH_UP_DELAY seconds.
-- Guards against double-scheduling and runaway loops.
-- @param reason  string label for debug output
function P2P:ScheduleCatchUp(reason)
    if self.catchUpTimer then return end

    self.catchUpCycles = (self.catchUpCycles or 0) + 1
    if self.catchUpCycles > self.MAX_CATCH_UP_CYCLES then
        self:Dbg("CATCHUP", "Max catch-up cycles (%d) reached (%s) — giving up",
            self.MAX_CATCH_UP_CYCLES, reason)
        self.catchUpCycles = 0
        return
    end

    if not self.cb.hasMissingItems() then
        self:Dbg("CATCHUP", "No missing items (%s) — catch-up not needed", reason)
        self.catchUpCycles = 0
        return
    end

    self:Dbg("CATCHUP", "Scheduling catch-up in %ds (%s, cycle %d/%d)",
        self.CATCH_UP_DELAY, reason, self.catchUpCycles, self.MAX_CATCH_UP_CYCLES)

    -- NewTimer, like every other timer in this file. This was the one holdout on
    -- C_Timer.After with `catchUpTimer = true` as a boolean sentinel -- safe only
    -- because the callback re-checks hasMissingItems(), but it meant a scheduled
    -- catch-up could not be cancelled by anything (AUDIT finding 10). The three
    -- conversions above each record what a nil handle cost them; this one keeps
    -- the same shape so the next reason to cancel a catch-up has a handle to use.
    -- The sentinel semantics survive: a live handle is truthy, and the callback
    -- clears the field before it does anything else.
    local inst = self
    self.catchUpTimer = C_Timer.NewTimer(self.CATCH_UP_DELAY, function()
        inst.catchUpTimer = nil
        if inst.cb.hasMissingItems() then
            inst:Dbg("CATCHUP", "Cycle %d: re-broadcasting item hashes", inst.catchUpCycles)
            local hashes = inst.cb.getMyHashes()
            inst._host:BroadcastItemHashes(hashes, "BULK")
        else
            inst:Dbg("CATCHUP", "Cycle %d: all items present — done", inst.catchUpCycles)
            inst.catchUpCycles = 0
        end
    end)
end

-- ─── Collect window ───────────────────────────────────────────────────────────

--- Open (or extend) the offer collect window.
-- Called automatically by host:BroadcastItemHashes().
-- @param myHashes  {itemKey → {hash, updatedAt}} — our broadcast payload (informational)
function P2P:BeginCollectWindow(myHashes) -- luacheck: ignore myHashes
    local inst = self
    if self.isCollecting then
        -- Already open: reset the deadline so late arrivals still count.
        -- NewTimer, not After: only NewTimer returns a cancellable handle, and
        -- without a real cancel here every extension STACKED another Dispatch on
        -- top of the original deadline — so an "extended" window still fired
        -- early, then fired a second time with the window already closed.
        if self.collectTimer then self.collectTimer:Cancel() end
        self.collectTimer = C_Timer.NewTimer(self.COLLECT_WINDOW, function()
            inst:Dispatch()
        end)
        self:Dbg("OFFER", "Collect window extended (%ds)", self.COLLECT_WINDOW)
        return
    end

    self.isCollecting = true
    self.offers       = {}
    self.collectTimer = C_Timer.NewTimer(self.COLLECT_WINDOW, function()
        inst:Dispatch()
    end)
    self:Dbg("OFFER", "Collect window started (%ds)", self.COLLECT_WINDOW)
end

--- Called when we receive a hash-list-broadcast from a peer (OFFER channel, GUILD dist).
-- If we have newer data for any of their listed items, whisper them an offer.
-- @param sender  string: normalized sender name
-- @param items   {itemKey → {hash, updatedAt}} or nil
function P2P:OnHashListReceived(sender, items)
    if not items then return end
    local normSender = Norm(sender)

    -- Reject broadcasts from peers the host considers ineligible (e.g. not in guild).
    if not self.cb.isValidPeer(normSender) then
        self:Dbg("OFFER", "Hash list from %s ignored (isValidPeer=false)", normSender)
        return
    end

    local myHashes   = self.cb.getMyHashes()
    local offerItems = {}
    local count      = 0

    for itemKey, peerEntry in pairs(items) do
        local mine = myHashes[itemKey]
        -- Offer whenever our hash differs from the peer's, regardless of updatedAt.
        -- Old behavior gated on `mine.updatedAt > peer.updatedAt`, which suppressed
        -- legitimate offers from the actual data owner whenever a relayer's
        -- updatedAt happened to be higher (e.g. bumped on RebuildAll even when
        -- content didn't change). Consumers in MINOR>=9 must merge content-aware
        -- on receive (max-wins for monotonic data, union for sets) so receiving
        -- from any peer converges to the correct answer. updatedAt remains in the
        -- wire format for backwards compat but is no longer load-bearing for
        -- correctness here.
        if mine and HashesDiffer(mine, peerEntry)
                and self.cb.hasContent(itemKey) then
            -- Carry hashV2 through so the peer's own comparison can use it too;
            -- it is simply absent when the host still builds entries by hand.
            offerItems[itemKey] = {
                hash      = mine.hash,
                hashV2    = mine.hashV2,
                updatedAt = mine.updatedAt,
            }
            count = count + 1
        end
    end

    if count > 0 then
        self:Dbg("OFFER", "Offering %d item(s) to %s", count, normSender)
        self._host:SendHashOffer(normSender, offerItems)
    end
end

--- Called when a hash-offer whisper arrives (OFFER channel, WHISPER dist).
-- Records the candidate during the collect window.
-- @param peerName  string: normalized sender name
-- @param items     {itemKey → {hash, updatedAt}} or nil
function P2P:OnOffer(peerName, items)
    if not items then return end
    local normPeer = Norm(peerName)

    if not self.isCollecting then
        self:Dbg("OFFER", "OnOffer from %s ignored (not collecting)", normPeer)
        return
    end

    -- Reject offers from peers the host considers ineligible.
    if not self.cb.isValidPeer(normPeer) then
        self:Dbg("OFFER", "OnOffer from %s ignored (isValidPeer=false)", normPeer)
        return
    end

    for itemKey, summary in pairs(items) do
        -- Skip items that already have an in-flight session.
        if not self.sessionsByItem[itemKey] then
            self.offers[itemKey] = self.offers[itemKey] or {}
            local entry = {
                peer      = normPeer,
                updatedAt = summary.updatedAt or 0,
                hash      = summary.hash      or 0,
            }
            -- NOTE: This descending-updatedAt sort is a heuristic-only ordering hint
            -- and is no longer load-bearing for correctness — consumers in MINOR>=9
            -- merge content-aware on receive, so receiving from any candidate
            -- converges to the right answer. Kept for stable iteration order and
            -- as a "try the most-recently-updated peer first" tiebreak when load
            -- is equal.
            local inserted = false
            for i, existing in ipairs(self.offers[itemKey]) do
                if entry.updatedAt > existing.updatedAt then
                    table.insert(self.offers[itemKey], i, entry)
                    inserted = true
                    break
                end
            end
            if not inserted then
                table.insert(self.offers[itemKey], entry)
            end
            self:Dbg("OFFER", "  offer: %s from %s (updatedAt=%s)", itemKey, normPeer, tostring(summary.updatedAt))
        end
    end
end

-- ─── Dispatch ─────────────────────────────────────────────────────────────────

-- Pick the least-loaded untried peer from the candidate list.
local function PickPeer(candidates, triedPeers, peerLoad)
    local best, bestIdx = nil, nil
    local bestLoad      = math.huge
    for i, c in ipairs(candidates) do
        if not triedPeers[c.peer] then
            local load = peerLoad[c.peer] or 0
            if load < bestLoad then
                bestLoad = load
                best     = c.peer
                bestIdx  = i
            end
        end
    end
    return best, bestIdx
end

--- Fire at end of collect window: create sessions for each stale item.
function P2P:Dispatch()
    self.collectTimer = nil
    self.isCollecting = false

    local altList = {}
    for itemKey, offerList in pairs(self.offers) do
        if #offerList > 0 and not self.sessionsByItem[itemKey] then
            table.insert(altList, { itemKey = itemKey, candidates = offerList })
        end
    end

    if #altList == 0 then
        self:Dbg("DISPATCH", "No offers to dispatch")
        self:ScheduleCatchUp("no_offers")
        return
    end

    self:Dbg("DISPATCH", "Dispatching %d item(s)", #altList)
    self:DispatchList(altList)
end

--- Queue an item for dispatch once a session slot frees, keyed by itemKey.
--
-- pendingDispatch used to be a plain array with no de-duplication, and an item
-- sitting in it has no sessionsByItem entry (that is only set when a session is
-- actually created). So under sustained cap pressure the loop closed on itself:
-- Dispatch() rebuilt altList from every offered item without a session -- which
-- included everything already queued -- and DispatchList appended all of them
-- AGAIN; each catch-up cycle added another copy. The flush-time skip on
-- sessionsByItem kept correctness (an item was never dispatched twice), but the
-- table grew without bound through a long night with one slow provider (AUDIT
-- finding 9). A later offer for a queued item now REPLACES the entry, so the
-- freshest candidate list is the one that dispatches.
function P2P:_QueuePending(item)
    local pending = self.pendingDispatch
    for i, existing in ipairs(pending) do
        if existing.itemKey == item.itemKey then
            pending[i] = item
            return false
        end
    end
    pending[#pending + 1] = item
    return true
end

--- Schedule sessions from a list, respecting the active-session cap.
function P2P:DispatchList(altList)
    local slots = self.MAX_ACTIVE_SESSIONS - self.activeSessions
    if slots <= 0 then
        self:Dbg("DISPATCH", "At cap (%d active) — queuing %d items", self.activeSessions, #altList)
        for _, item in ipairs(altList) do
            self:_QueuePending(item)
        end
        return
    end

    local peerLoad   = {}
    local dispatched = 0

    for _, item in ipairs(altList) do
        -- luacheck: ignore 542
        if self.sessionsByItem[item.itemKey] then
            -- Deliberately empty: a session was created for this item between
            -- Dispatch() and DispatchList(), so it is already in flight and must
            -- be skipped rather than queued or re-dispatched.
        elseif dispatched >= slots then
            self:_QueuePending(item)
        else
            local peer = PickPeer(item.candidates, {}, peerLoad)
            if peer then
                peerLoad[peer] = (peerLoad[peer] or 0) + 1
                local sid = MakeSessionId(item.itemKey)
                self.sessions[sid] = {
                    sessionId  = sid,
                    itemKey    = item.itemKey,
                    state      = STATE.DISPATCHED,
                    peer       = peer,
                    candidates = item.candidates,
                    triedPeers = { [peer] = true },
                    timers     = {},
                }
                self.sessionsByItem[item.itemKey] = sid
                self.activeSessions = self.activeSessions + 1
                self:SendSyncRequest(sid)
                dispatched = dispatched + 1
                self:Dbg("DISPATCH", "  → %s to %s (sid=%s)", item.itemKey, peer, sid)
            end
        end
    end
end

function P2P:SendSyncRequest(sessionId)
    local s = self.sessions[sessionId]
    if not s then return end

    self._host:SendHandshake(s.peer, {
        type      = "sync-request",
        sessionId = sessionId,
        itemKey   = s.itemKey,
        requester = Me(),
    }, "NORMAL")

    -- Timeout: if no ACK arrives, advance to next candidate.
    -- NewTimer so OnSyncAccept / AdvanceCandidate can actually cancel it; with
    -- After the handle was nil and every cancel silently no-op'd, leaving a stale
    -- timeout queued for the lifetime of the session.
    local inst    = self
    local timeout = self.DISPATCH_TIMEOUT
    s.timers.dispatch = C_Timer.NewTimer(timeout, function()
        local live = inst.sessions[sessionId]
        if live and live.state == STATE.DISPATCHED then
            inst:Dbg("HANDSHAKE", "Dispatch timeout for %s/%s — next candidate", live.itemKey, live.peer)
            inst:AdvanceCandidate(sessionId, "timeout")
        end
    end)
end

-- ─── ACK handling ─────────────────────────────────────────────────────────────

--- Provider accepted our sync-request.
function P2P:OnSyncAccept(sessionId, sender)
    local s = self.sessions[sessionId]
    if not s then
        self:Dbg("HANDSHAKE", "OnSyncAccept: unknown session %s from %s", tostring(sessionId), sender)
        return
    end
    if s.state ~= STATE.DISPATCHED then
        self:Dbg("HANDSHAKE", "OnSyncAccept: wrong state %s for %s", s.state, sessionId)
        return
    end

    if s.timers.dispatch then
        s.timers.dispatch:Cancel()
        s.timers.dispatch = nil
    end

    s.state = STATE.ACTIVE
    self:Dbg("HANDSHAKE", "ACTIVE: %s ← %s (activeSessions=%d)", s.itemKey, sender, self.activeSessions)

    -- Delivery watchdog in case peer accepts but data never arrives.
    --
    -- Uses DELIVERY_TIMEOUT (180s default). That number came from an observed
    -- ~70s worst-case AceCommQueue drain at 3 concurrent sends, with 180s as
    -- headroom.
    --
    -- CAVEAT — that measurement predates AceCommQueue-1.0 v1.0.5, and its
    -- maintainer flagged the interaction rather than letting us find it. A
    -- REFUSED message is now retried with a doubling backoff (1+2+4 = ~7s) and
    -- holds its queue for the duration, deliberately, so ordering survives and a
    -- refusing channel is not hammered. Under sustained refusal that compounds:
    -- roughly 16 refused messages on one key adds ~112s to the 70s baseline and
    -- reaches this watchdog.
    --
    -- The 180s has NOT been re-tuned, because the right number needs a real
    -- measurement under the new behaviour and guessing a bigger one would just
    -- move the cliff. The better fix is to stop waiting for the watchdog at all:
    -- MINOR 17 gives us a delivery verdict per send, so a session whose QUERY or
    -- DATA was refused could be failed immediately instead of 180s later. That
    -- is a behaviour change and is not in this release.
    -- NewTimer so _CancelTimers can retire it when the item completes; with
    -- After the watchdog outlived every finished session (harmless only because
    -- the callback re-checks live state, but it kept firing for 180s regardless).
    local inst = self
    s.timers.delivery = C_Timer.NewTimer(self.DELIVERY_TIMEOUT, function()
        local live = inst.sessions[sessionId]
        if live and live.state == STATE.ACTIVE then
            inst:Dbg("COMPLETE", "Delivery timeout for %s", live.itemKey)
            inst:OnItemFailed(sessionId, "delivery_timeout")
        end
    end)

    -- Notify host addon to initiate data exchange (e.g. send state-summary to provider).
    self.cb.onSyncAccepted(s.itemKey, sender)
end

--- Provider is at capacity; try the next candidate.
function P2P:OnSyncBusy(sessionId, sender)
    local s = self.sessions[sessionId]
    if not s then return end
    self:Dbg("HANDSHAKE", "BUSY: %s from %s — advancing", s.itemKey, sender)
    self:AdvanceCandidate(sessionId, "busy")
end

--- Move to the next untried candidate, with retry-cycle logic.
function P2P:AdvanceCandidate(sessionId, reason)
    local s = self.sessions[sessionId]
    if not s then return end

    if s.timers.dispatch then
        s.timers.dispatch:Cancel()
        s.timers.dispatch = nil
    end

    local nextPeer = nil
    for _, candidate in ipairs(s.candidates) do
        if not s.triedPeers[candidate.peer] then
            nextPeer = candidate.peer
            break
        end
    end

    if not nextPeer then
        s.retryCount = (s.retryCount or 0) + 1
        if s.retryCount <= self.MAX_RETRY_CYCLES then
            self:Dbg("HANDSHAKE", "All candidates busy for %s (%s), retry %d/%d in %ds",
                s.itemKey, reason, s.retryCount, self.MAX_RETRY_CYCLES, self.RETRY_CYCLE_DELAY)
            s.triedPeers = {}  -- reset: allow all candidates to be retried
            s.state      = STATE.DISPATCHED
            -- NewTimer so _CancelTimers can retire a pending retry when the
            -- session completes or fails in the meantime.
            local inst   = self
            s.timers.retry = C_Timer.NewTimer(self.RETRY_CYCLE_DELAY, function()
                local live = inst.sessions[sessionId]
                if not live or live.state ~= STATE.DISPATCHED then return end
                local peer = PickPeer(live.candidates, live.triedPeers, {})
                if peer then
                    live.peer               = peer
                    live.triedPeers[peer]   = true
                    inst:SendSyncRequest(sessionId)
                else
                    inst:_FailSession(sessionId, "no_candidates_on_retry")
                end
            end)
        else
            self:Dbg("HANDSHAKE", "All candidates exhausted for %s (%s) after %d retry cycles",
                s.itemKey, reason, s.retryCount)
            self:_FailSession(sessionId, "no_candidates")
        end
        return
    end

    s.peer             = nextPeer
    s.triedPeers[nextPeer] = true
    s.state            = STATE.DISPATCHED
    self:SendSyncRequest(sessionId)
end

-- ─── Sender side: the SHARED slot-accounting mixin ────────────────────────────
--
-- Used by BOTH P2P classes -- this one and DeltaSyncP2PNumbered.lua's -- which
-- copy these methods onto themselves at load. One implementation, because the
-- numbered protocol shipped with a second copy of every function below and the
-- self-audit of 2026-09-15 filed it: the next fix to one copy would have been
-- missed in the other, which is exactly how finding 11a happened once. Kept on
-- lib so a hot upgrade redefines it once and both classes re-copy.
--
-- The two classes differ in two places, both expressed as optional hooks:
--   * self.servingSends  -- the numbered class tracks how many acquired slots a
--                           QUERY has claimed; decremented alongside when present
--   * self.ServeQueue    -- the numbered class hands a freed slot to the next
--                           queued requester; called when present
lib._SendSlotMixin = lib._SendSlotMixin or {}
local Slots = lib._SendSlotMixin

--- Total outbound sends in flight, across every requester.
function Slots:GetActiveSendTotal()
    local total = 0
    for _, count in pairs(self.activeSends) do total = total + count end
    return total
end

--- Try to acquire an outbound send slot for a requester.
-- Returns true if under cap (slot incremented + safety timer set); false if at cap.
-- The host addon SHOULD call host.p2p:ReleaseSendSlot(requester) when the actual
-- wire send completes (e.g. in the AceComm chunk-sent callback) so the slot is
-- freed immediately.  The safety timer fires after SEND_TIMEOUT seconds as a
-- fallback to prevent permanent leaks if ReleaseSendSlot is never called.
function Slots:TryAcquireSendSlot(requester)
    local total = self:GetActiveSendTotal()
    if total >= self.MAX_ACTIVE_SENDS then
        return false
    end
    self.activeSends[requester] = (self.activeSends[requester] or 0) + 1
    self:Dbg("HANDSHAKE", "TryAcquireSendSlot: acquired for %s (total=%d)", requester, total + 1)

    -- Safety release, bound to THIS acquisition.
    --
    -- It used to be a bare C_Timer.After whose callback ran unconditionally, so a
    -- send that completed normally still left a timer armed; when it fired it
    -- decremented a slot belonging to a LATER send from the same requester. That
    -- is an over-release, not an underflow, so the `> 0` guard never caught it
    -- and MAX_ACTIVE_SENDS could be quietly exceeded under sustained load.
    -- Holding the handle lets ReleaseSendSlot retire exactly one of these.
    local inst = self
    local timers = self.sendTimers[requester]
    if not timers then
        timers = {}
        self.sendTimers[requester] = timers
    end
    local handle
    handle = C_Timer.NewTimer(self.SEND_TIMEOUT, function()
        -- Drop our own handle BEFORE releasing, or the release below would also
        -- retire a sibling timer that is still guarding a live send.
        for i = 1, #timers do
            if timers[i] == handle then
                table.remove(timers, i)
                break
            end
        end
        inst:_DecrementSendSlot(requester, "timeout")
    end)
    timers[#timers + 1] = handle
    return true
end

-- Find the activeSends key a host-supplied requester name refers to.
--
-- Slots are acquired under the TRANSPORT sender -- lib:NormalizeSender only
-- strips whitespace from the realm half, so a same-realm whisper acquires under
-- a bare "Foo" while a cross-realm one acquires under "Foo-Realm". The host, by
-- contrast, holds whatever spelling ITS data model uses -- typically the
-- canonical "Name-Realm" LibGuildRoster hands out -- and nothing told it which
-- one to pass. A mismatch was a silent no-op: the `<= 0` guard returned early,
-- the slot leaked until SEND_TIMEOUT, and a host that consistently passed the
-- "wrong" spelling stalled its outbound path in three sends and recovered only
-- on the 90s timer, every time (AUDIT finding 11a). So the library reconciles
-- the spellings itself: exact key first, then the canonical form, then the bare
-- name as a last resort when no roster library is present to canonicalise.
-- (The bare-name match can pick the wrong slot only when two same-named peers
-- on different realms both hold slots AND the host passes a bare name.)
local function BareName(name)
    return type(name) == "string" and (string.match(name, "^([^%-]+)") or name) or name
end

function Slots:_ResolveSlotKey(requester)
    if requester == nil then return nil end
    if (self.activeSends[requester] or 0) > 0 then return requester end

    -- Resolved at call time rather than through this file's load-time upvalue,
    -- because the OTHER class that carries this mixin re-resolves its own.
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))
    local want = Norm(requester)
    for key, count in pairs(self.activeSends) do
        if count > 0 and Norm(key) == want then return key end
    end

    local bare = BareName(requester)
    for key, count in pairs(self.activeSends) do
        if count > 0 and BareName(key) == bare then return key end
    end
    return nil
end

--- Release an outbound send slot for a requester.
-- Call this from your send-completion callback so the slot is freed as soon as
-- the wire send finishes, rather than waiting for the SEND_TIMEOUT safety timer.
-- Any spelling of the requester's name is accepted -- bare, "Name-Realm", or
-- the transport's own -- and matched to the slot that was acquired.
-- Safe to call redundantly — the > 0 guard prevents underflow, and a release
-- with nothing outstanding is logged rather than raised.
function Slots:ReleaseSendSlot(requester, reason)
    local key = self:_ResolveSlotKey(requester)
    if not key then
        -- Say so: before this the only sign a host was releasing under the wrong
        -- name was a stall 90 seconds later.
        self:Dbg("HANDSHAKE", "ReleaseSendSlot: no outstanding slot for %s (%s) — nothing released",
            tostring(requester), reason or "complete")
        return
    end

    -- Retire the OLDEST outstanding safety timer for this requester (FIFO). The
    -- remaining ones keep their own acquisitions' deadlines, so a slot that
    -- genuinely leaked is still reclaimed on schedule rather than early.
    local timers = self.sendTimers and self.sendTimers[key]
    if timers and #timers > 0 then
        local handle = table.remove(timers, 1)
        if handle and handle.Cancel then handle:Cancel() end
    end

    self:_DecrementSendSlot(key, reason)
end

-- Give back one slot without touching the safety-timer list. Both the host's
-- ReleaseSendSlot and a fired safety timer funnel through here; each has already
-- dealt with its own timer, so neither may retire another's.
function Slots:_DecrementSendSlot(requester, reason)
    if (self.activeSends[requester] or 0) > 0 then
        self.activeSends[requester] = self.activeSends[requester] - 1
        -- The serving mark (a QUERY's claim on the slot) goes back with it, where
        -- the class keeps one.
        if self.servingSends and (self.servingSends[requester] or 0) > 0 then
            self.servingSends[requester] = self.servingSends[requester] - 1
        end
        self:Dbg("HANDSHAKE", "ReleaseSendSlot: %s (%s, remaining=%d)",
            requester, reason or "complete", self.activeSends[requester])
        -- A freed slot goes to whoever has been waiting longest, where the class
        -- keeps a queue.
        if self.ServeQueue then self:ServeQueue() end
    end
end

--- The default eligibility predicate both classes share. Defaults to a
-- guild-membership check via LibGuildRoster-1.0; accepts every peer while not in
-- a guild or while the roster is still building (the retired GuildCache did the
-- same), and accepts everyone when no roster library is present -- the host
-- must then supply its own.
function Slots.DefaultIsValidPeer()
    local GR = LibStub and LibStub("LibGuildRoster-1.0", true)
    if not GR then return function() return true end end
    return function(name)
        if not (IsInGuild and IsInGuild()) then return true end
        if GR.IsReady and not GR:IsReady() then return true end
        return GR:IsInGuild(name)
    end
end

-- Copy the mixin onto this class. Done with pairs() rather than a metatable
-- chain so a method defined on the class itself still wins if one ever must.
for name, fn in pairs(Slots) do P2P[name] = fn end

--- Handle an inbound sync-request (we are the data provider).
-- Replies sync-accept if we have capacity and content; sync-busy otherwise.
-- @param sessionId  string
-- @param requester  string: normalized requester name
-- @param itemKey    string: key of the item requested
function P2P:HandleSyncRequest(sessionId, requester, itemKey)
    if not sessionId or not requester or not itemKey then return false end

    -- Eligibility gate, matching OnHashListReceived and OnOffer. This was the
    -- ONE inbound P2P path without it -- and the only one that commits a
    -- resource: a send slot is capped (MAX_ACTIVE_SENDS, default 3) and held for
    -- up to SEND_TIMEOUT (90s), so three well-formed whispers from one
    -- ineligible sender filled the outbound cap and every legitimate peer was
    -- answered sync-busy for ninety seconds (AUDIT finding 11). The rule this
    -- library follows, stated in the header: the transport forwards and the host
    -- gates, EXCEPT where the library itself commits or discloses -- there it
    -- gates with isValidPeer. Reply sync-busy rather than dropping silently, so a
    -- legitimate peer on a stale roster advances to its next candidate instead
    -- of waiting out DISPATCH_TIMEOUT.
    if not self.cb.isValidPeer(Norm(requester)) then
        self:Dbg("HANDSHAKE", "HandleSyncRequest from %s rejected (isValidPeer=false) — busy", requester)
        self._host:SendHandshake(requester, { type = "sync-busy", sessionId = sessionId }, "NORMAL")
        return false
    end

    -- Verify we actually have content for this item (race guard).
    if not self.cb.hasContent(itemKey) then
        self:Dbg("HANDSHAKE", "HandleSyncRequest: no content for %s — busy to %s", itemKey, requester)
        self._host:SendHandshake(requester, { type = "sync-busy", sessionId = sessionId }, "NORMAL")
        return false
    end

    -- Check outbound capacity via shared slot helper.
    if not self:TryAcquireSendSlot(requester) then
        local total = 0
        for _, count in pairs(self.activeSends) do total = total + count end
        self:Dbg("HANDSHAKE", "At send cap (%d) — busy to %s for %s", total, requester, itemKey)
        self._host:SendHandshake(requester, { type = "sync-busy", sessionId = sessionId }, "NORMAL")
        return false
    end

    -- Accept — slot already acquired by TryAcquireSendSlot.
    self._host:SendHandshake(requester, { type = "sync-accept", sessionId = sessionId }, "NORMAL")
    self:Dbg("HANDSHAKE", "Accepted %s for %s", itemKey, requester)
    return true
end

-- ─── Completion / failure ─────────────────────────────────────────────────────

--- Call this when data delivery for itemKey is confirmed complete.
-- Frees the active session slot and flushes any pending dispatches.
-- @param itemKey  string
-- @param sender   string: who delivered the data (for logging)
function P2P:OnItemCompleted(itemKey, sender)
    local sessionId = self.sessionsByItem[itemKey]
    if not sessionId then return end  -- not session-backed (legacy path)

    local s = self.sessions[sessionId]
    if not s then
        self.sessionsByItem[itemKey] = nil
        return
    end

    self:_CancelTimers(s)
    self.activeSessions          = math.max(0, self.activeSessions - 1)
    s.state                      = STATE.COMPLETE
    self.sessions[sessionId]     = nil
    self.sessionsByItem[itemKey] = nil
    self:Dbg("COMPLETE", "COMPLETE: %s from %s (activeSessions=%d)", itemKey, tostring(sender), self.activeSessions)

    self:_FlushPendingDispatch()
end

--- Call this when data delivery for itemKey failed permanently.
-- Schedules a catch-up broadcast and flushes pending dispatches.
-- Also used internally by AdvanceCandidate when candidates are exhausted.
-- @param sessionIdOrItemKey  may be a sessionId (internal) or itemKey (external)
-- @param reason              string
function P2P:OnItemFailed(sessionIdOrItemKey, reason)
    -- Accept either a session ID or an itemKey for external callers.
    local s = self.sessions[sessionIdOrItemKey]
    if not s then
        -- Treat as itemKey
        local sid = self.sessionsByItem[sessionIdOrItemKey]
        if sid then s = self.sessions[sid] end
    end
    if s then
        self:_FailSession(s.sessionId, reason)
    end
end

function P2P:_FailSession(sessionId, reason)
    local s = self.sessions[sessionId]
    if not s then return end

    self:_CancelTimers(s)
    self.activeSessions              = math.max(0, self.activeSessions - 1)
    local itemKey                    = s.itemKey
    s.state                          = STATE.FAILED
    self.sessions[sessionId]         = nil
    self.sessionsByItem[itemKey]     = nil
    self:Dbg("COMPLETE", "FAILED (%s): %s (activeSessions=%d)", reason, itemKey, self.activeSessions)

    self:ScheduleCatchUp("session_failed")
    self:_FlushPendingDispatch()
end

function P2P:_CancelTimers(s)
    for _, timer in pairs(s.timers or {}) do
        if timer and type(timer) == "table" and timer.Cancel then
            timer:Cancel()
        end
    end
    s.timers = {}
end

function P2P:_FlushPendingDispatch()
    local pending = self.pendingDispatch
    if not pending or #pending == 0 then return end
    self.pendingDispatch = {}
    self:DispatchList(pending)
end

-- ─── Query helpers ────────────────────────────────────────────────────────────

--- True if itemKey has an in-flight (DISPATCHED or ACTIVE) session.
function P2P:HasActiveSession(itemKey)
    local sessionId = self.sessionsByItem[itemKey]
    if not sessionId then return false end
    local s = self.sessions[sessionId]
    return s ~= nil and (s.state == STATE.DISPATCHED or s.state == STATE.ACTIVE)
end

-- ─── lib-level initializer ────────────────────────────────────────────────────

--- Initialize this host's P2P layer. Call once per host, after lib:NewHost()
-- (or after lib:Initialize() on the legacy default host).
--
-- MULTI-HOST (MINOR 15+):
--   Each host owns an isolated P2P instance at host.p2p, so multiple consuming
--   addons in one client run independent sync loops without sharing sessions,
--   offers, or send slots. (Pre-15 this was a single shared lib.p2p singleton —
--   two consumers clobbered each other; that constraint is gone.)
--
-- @param config  see module header for field documentation
function lib:InitP2P(config)
    -- MINOR 18+: config.mode = "numbered" selects the numbered protocol class
    -- (DeltaSyncP2PNumbered.lua, LIBREQ-DS-008). Every other host gets this
    -- class exactly as before -- the two never mix on one host, so a host whose
    -- existing instance is the other class gets a fresh one.
    local class = P2P
    if config and config.mode == "numbered" then
        class = lib._P2PNumberedClass
        if not class then
            error("DeltaSync:InitP2P(mode='numbered') requires DeltaSyncP2PNumbered.lua to be loaded", 2)
        end
    end
    -- rawget so a host doesn't pick up lib's default-host p2p through __index; if
    -- absent, mint a fresh instance bound to this host via _host.
    local inst = rawget(self, "p2p")
    local mt = inst and getmetatable(inst)
    if not inst or not mt or mt.__index ~= class then
        inst = setmetatable({ _host = self }, { __index = class })
        self.p2p = inst
    else
        inst._host = self  -- keep the back-reference correct across re-init
    end
    inst:Init(config)
    return inst
end
