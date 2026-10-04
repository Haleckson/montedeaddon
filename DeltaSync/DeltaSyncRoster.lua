-- DeltaSyncRoster.lua
-- Optional RosterSync module for DeltaSync-1.0 (MINOR 12+).
--
-- Cross-guild "sister roster" sharing for confederated guilds. A consuming
-- addon's /who discovery finds an online member of an allied guild and hands
-- the peer name to host:RequestRosterSync(peerName); DeltaSync then does the
-- rest over the existing WHISPER QUERY/RESPONSE channels (NO new prefix, NO
-- broadcast, NO P2P-offer participation):
--
--   1. Requester whispers the peer a QUERY carrying its cached
--      {guildKey -> membershipHash} map (built from LibGuildRoster).
--   2. Provider looks up ITS OWN home guild key in that map; if the requester's
--      cached hash already matches the provider's current LibGuildRoster:
--      GetRosterHash(homeKey), it replies "no-change". Otherwise it replies
--      with the full membership list + its canonical guild key + provenance.
--   3. Requester feeds the result to LibGuildRoster:SetSisterRoster(theirKey,
--      members, meta) and fires onSisterRosterUpdated so the host can persist
--      and refresh UI.
--
-- DIVISION OF LABOUR (deliberate):
--   * RosterSync owns the WIRE and writes MEMBERSHIP (SetSisterRoster).
--   * LibGuildRoster-1.0 owns the STORE (membership + hashing + sister API).
--   * The consuming addon owns PRESENCE (its /who poll calls MarkOnline) and
--     PERSISTENCE (re-feeds SetSisterRoster from its SavedVariables on login).
--   RosterSync is membership-pure: it never touches presence and holds no
--   SavedVariables of its own.
--
-- ISOLATION GUARANTEES:
--   * roster traffic is type-routed via host:RegisterLeafType("roster", ...) so
--     it coexists with the host's own leaves (e.g. "cooldowns:"/"recipes:")
--     without either seeing the other's messages.
--   * roster hashes are NEVER placed in the P2P getMyHashes map — they are
--     directed-whisper-only. (In getMyHashes they would broadcast guild-wide
--     over the OFFER channel — the exact thing confederation must not do.)
--   * the module registers NOTHING until host:InitRosterSync is called, so a
--     consumer that never opts in (e.g. TOGBankClassic) is byte-identical to a
--     build without this file.
--
-- MULTI-HOST (MINOR 15+): RosterSync is a persistent class (lib._RosterClass)
-- and each host owns its own instance at host.rosterSync (created by
-- host:InitRosterSync), with a _host back-reference. The leaf handlers a host
-- registers route to ITS instance, so two consuming addons keep independent
-- sister-roster wiring.
--
-- LibGuildRoster-1.0 is a soft dependency here, feature-detected per method:
-- InitRosterSync no-ops gracefully if the sister-roster API (MINOR 6+) is
-- absent.

local MAJOR = "DeltaSync-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then
    error("DeltaSyncRoster.lua requires DeltaSync.lua to load first (LibStub('DeltaSync-1.0') is nil). Check TOC order.")
end

-- LibGuildRoster-1.0 — the roster store. Soft upvalue; every call site guards.
local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

-- Persistent class table (methods only). Kept on lib across LibStub upgrades so
-- existing host.rosterSync instances pick up redefined methods via __index.
lib._RosterClass = lib._RosterClass or {}
local RS = lib._RosterClass

local LEAF_TYPE = "roster"

-- Per-host debug: route through the owning host so each addon's RosterSync log
-- lands in ITS debug tab, not the shared lib's.
function RS:Dbg(fmt, ...)
    local h = self._host
    if h and h.Debug then h:Debug("ROSTER", fmt, ...) end
end

-- True only when LibGuildRoster exposes the full MINOR 6+ sister-roster API
-- this module relies on. Feature-detected so an older vendored/installed copy
-- degrades to a clean no-op instead of erroring.
local function HasSisterAPI()
    return GuildRoster
        and GuildRoster.GetHomeGuildKey
        and GuildRoster.GetRoster
        and GuildRoster.GetRosterHash
        and GuildRoster.SetSisterRoster
        and GuildRoster.GetKnownRosters
        and true or false
end

-- ─── Init ───────────────────────────────────────────────────────────────────

--- Opt-in initialization for a host. Until this is called, RosterSync registers
-- nothing and adds zero comm traffic or events for that host.
-- @param config table
--   config.onSisterRosterUpdated(guildKey)  -- fired after a sister roster is
--                                              applied; host persists / refreshes.
--   config.isValidPeer(name) -> bool        -- OPTIONAL inbound gate: may we
--                                              serve our home roster to this
--                                              requester? Defaults to accept-all
--                                              (a roster is already exposed via
--                                              /who, so serving it leaks nothing
--                                              new). SCOPED TO RosterSync — it
--                                              must NOT be confused with the P2P
--                                              isValidPeer; the two are separate.
function lib:InitRosterSync(config)
    config = config or {}

    -- Load-order / clobber / embedder resilience: re-resolve the LibGuildRoster
    -- handle now. InitRosterSync runs at/after PLAYER_LOGIN, by which point a
    -- standalone GuildRoster addon (even one loaded after us) is present; the
    -- file-load-time upvalue is nil only if our TOC dependency wasn't honored.
    -- HasSisterAPI() below reads this refreshed handle.
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))

    -- Per-host instance. rawget so a NewHost host doesn't pick up the legacy
    -- default host's rosterSync through __index; mint one bound to this host.
    local inst = rawget(self, "rosterSync")
    if not inst then
        inst = setmetatable({ _host = self }, { __index = RS })
        self.rosterSync = inst
    else
        inst._host = self
    end
    inst.cb = inst.cb or {}

    if not HasSisterAPI() then
        inst.initialized = false
        self:Debug("ROSTER", "InitRosterSync: LibGuildRoster-1.0 sister API (MINOR 6+) not present — RosterSync disabled.")
        return
    end

    -- Optional host callbacks. Left nil when not supplied; the call sites
    -- guard, so the effective defaults are "accept every peer" and "no update
    -- notification".
    inst.cb.onSisterRosterUpdated = config.onSisterRosterUpdated
    inst.cb.isValidPeer           = config.isValidPeer
    inst.initialized = true

    -- Claim the "roster" leaf type so directed roster QUERY/RESPONSE route to
    -- THIS host's instance instead of the host's onDataRequest/onDataReceived.
    self:RegisterLeafType(LEAF_TYPE, {
        onDataRequest  = function(sender, baseline) inst:OnRequest(sender, baseline) end,
        onDataReceived = function(sender, data)     inst:OnResponse(sender, data)    end,
    })

    self:Debug("ROSTER", "InitRosterSync: ready (leaf type '%s' registered).", LEAF_TYPE)
end

-- ─── Requester side ─────────────────────────────────────────────────────────

--- Pull an allied guild's roster from one of its online members.
-- The host's /who discovery supplies `peerName`; RosterSync does everything
-- else. It advertises the requester's currently-cached sister hashes so the
-- provider can short-circuit with "no-change" when nothing has changed.
-- @param peerName string  an online sister-guild member ("Name" or "Name-Realm")
function lib:RequestRosterSync(peerName)
    local inst = rawget(self, "rosterSync")
    if not inst or not inst.initialized then
        self:Debug("ROSTER", "RequestRosterSync ignored: InitRosterSync not called (or sister API absent).")
        return
    end
    -- Guild-mode is incompatible with RosterSync: it reroutes the directed
    -- QUERY/RESPONSE channels to GUILD, which cannot reach a member of ANOTHER
    -- guild. On a whisper-dead server (the only place guild-mode is used)
    -- cross-guild sync is impossible regardless, so we self-disable rather than
    -- broadcast undeliverable roster queries onto the shared GUILD channel.
    if self.IsGuildMode and self:IsGuildMode() then
        self:Debug("ROSTER", "RequestRosterSync ignored: guild-mode active (cross-guild whisper unavailable on this server).")
        return
    end
    if not peerName or peerName == "" then return end

    -- Build {guildKey -> membershipHash} from everything LibGuildRoster knows.
    -- The provider matches its OWN home key against this; an absent key (first
    -- contact) means "send me the full roster". Rides in baseline.keys because
    -- SerializeBaseline only carries {hash, version, keys, type, parent}.
    local known = {}
    for _, key in ipairs(GuildRoster:GetKnownRosters()) do
        local h = GuildRoster:GetRosterHash(key)
        if h then known[key] = h end
    end

    self:Debug("ROSTER", "RequestRosterSync -> %s (advertising %d known roster hash(es)).",
        tostring(peerName), self:_CountKeys(known))
    self:RequestData(peerName, { type = LEAF_TYPE, keys = known })
end

-- tiny helper: count map entries (no # on hash maps).
function lib:_CountKeys(t)
    local n = 0
    if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    return n
end

-- ─── Provider side ──────────────────────────────────────────────────────────

--- A peer asked for our home roster (routed here by leaf type "roster").
function RS:OnRequest(sender, baseline)
    if not self.initialized or not HasSisterAPI() then return end
    local host = self._host
    -- Guild-mode active → RosterSync disabled (see RequestRosterSync). Don't
    -- serve our home roster over a channel that's been rerouted to GUILD.
    if host.IsGuildMode and host:IsGuildMode() then return end

    -- Inbound serve gate (RosterSync-scoped; default accept-all when unset).
    if self.cb.isValidPeer and not self.cb.isValidPeer(sender) then
        self:Dbg("OnRequest from %s rejected by RosterSync isValidPeer.", tostring(sender))
        return
    end

    local homeKey = GuildRoster:GetHomeGuildKey()
    if not homeKey then
        self:Dbg("OnRequest from %s: no home guild key yet (guildless / login window) — not serving.", tostring(sender))
        return
    end

    local myHash    = GuildRoster:GetRosterHash(homeKey)
    local theirHash = (type(baseline) == "table" and type(baseline.keys) == "table") and baseline.keys[homeKey] or nil

    if theirHash and myHash and theirHash == myHash then
        -- Requester already holds our current membership — reply no-change.
        self:Dbg("OnRequest from %s: %s up-to-date (hash %s), replying no-change.", tostring(sender), homeKey, tostring(myHash))
        host:SendData(sender, { type = LEAF_TYPE, guildKey = homeKey, hash = myHash }, false)
        return
    end

    -- Serve the full membership: { name = charKey, class, level } per member.
    -- rank/notes/presence are deliberately excluded (rank is unused cross-guild;
    -- notes are sensitive; presence is the consumer's /who job).
    local roster  = GuildRoster:GetRoster(homeKey) or {}
    local members = {}
    for charKey, m in pairs(roster) do
        members[#members + 1] = { name = charKey, class = m and m.class, level = m and m.level }
    end

    local me = (GuildRoster.GetNormalizedPlayer and GuildRoster:GetNormalizedPlayer())
        or (UnitName and UnitName("player"))
    local ts = (GetServerTime and GetServerTime()) or (time and time()) or 0

    self:Dbg("OnRequest from %s: serving %s (%d members, hash %s).", tostring(sender), homeKey, #members, tostring(myHash))
    host:SendData(sender, {
        type            = LEAF_TYPE,
        guildKey        = homeKey,
        hash            = myHash,
        members         = members,
        providerCharKey = me,
        ts              = ts,
    }, false)
end

-- ─── Requester side (apply) ─────────────────────────────────────────────────

--- The provider replied (routed here by leaf type "roster").
function RS:OnResponse(sender, data)
    if not self.initialized or not HasSisterAPI() then return end
    local host = self._host
    -- Guild-mode active → RosterSync disabled (see RequestRosterSync). Ignore any
    -- stray roster reply rather than applying a sister roster while inert.
    if host.IsGuildMode and host:IsGuildMode() then return end
    if type(data) ~= "table" then return end

    local guildKey = data.guildKey
    if not guildKey or guildKey == "" then
        self:Dbg("OnResponse from %s: missing guildKey, ignoring.", tostring(sender))
        return
    end

    -- No-change reply (no members): peer confirmed we are already current.
    if data.members == nil then
        self:Dbg("OnResponse from %s: %s no-change.", tostring(sender), guildKey)
        return
    end
    if type(data.members) ~= "table" then return end

    -- Cheap trust guard: the provider should appear in the roster it served
    -- (a member serves its own guild). Self-asserted data otherwise — see the
    -- file header's cooperative-confederation note. Skipped if the provider
    -- didn't stamp its charKey (older sender); the worst a liar can do is
    -- corrupt its OWN guild's roster, since it serves only its GetHomeGuildKey.
    if data.providerCharKey then
        local np = (GuildRoster.NormalizeName and GuildRoster:NormalizeName(data.providerCharKey)) or data.providerCharKey
        local present = false
        for _, mem in ipairs(data.members) do
            local mn = (type(mem) == "table") and mem.name or mem
            if mn == np or mn == data.providerCharKey then present = true break end
        end
        if not present then
            self:Dbg("OnResponse from %s REJECTED: provider %s not in served roster for %s.",
                tostring(sender), tostring(data.providerCharKey), guildKey)
            return
        end
    end

    GuildRoster:SetSisterRoster(guildKey, data.members, {
        provider = data.providerCharKey,
        ts       = data.ts,
        via      = sender,
    })

    self:Dbg("OnResponse from %s: applied %s (%d members).", tostring(sender), guildKey, #data.members)
    if self.cb.onSisterRosterUpdated then self.cb.onSisterRosterUpdated(guildKey) end
end
