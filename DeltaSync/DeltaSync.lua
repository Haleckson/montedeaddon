-- DeltaSync Library
-- Author: ianplamondon
-- Version: 1.0.0
-- A standalone, embeddable Lua library for efficient data synchronization using delta compression

-- MINOR 6: CHANNEL prefixes fully excluded from AceComm registration.
-- MINOR 7: merged P2P (OFFER/HANDSHAKE) + CRC-wrapped AceSerializer wire format.
--          Imported into the standalone DeltaSync repo in v2.0.0 (2026-04-20).
-- MINOR 8: shipped DeltaSyncChannel.lua (CHANNEL transport: SendChatMessage send +
--          CHAT_MSG_CHANNEL receive, compact serializer/deserializer codec). The
--          integration hooks landed in v2.0.0 but the implementation file was
--          missing from the repo until v2.0.1 (2026-04-27).
-- MINOR 9: hash-mismatch offer condition. P2PSession:OnHashListReceived now offers
--          whenever the local hash differs from the peer's, instead of gating on
--          updatedAt > peer.updatedAt. Required by content-aware-merge consumers
--          (TOGProfessionMaster v0.2.0). Wire format unchanged.
-- MINOR 10: SerializeBaseline / DeserializeBaseline now carry `type` and `parent`
--          fields end-to-end. Prior versions silently dropped any field outside
--          {hash, version, keys}, which broke v0.2.0 protocols that encode the
--          request shape on the QUERY baseline (e.g. type="leaf-data" /
--          type="subhashes" parent="guild:cooldowns"). Receivers saw an empty
--          baseline and silently no-op'd, leaving sessions stuck in ACTIVE state
--          until DELIVERY_TIMEOUT. Wire format is forward-compatible: MINOR<10
--          peers ignore the extra fields, MINOR>=10 peers honor them.
-- MINOR 11: retired the embedded GuildCache-1.0 library; the roster engine is now
--          LibGuildRoster-1.0, a required standalone-addon dependency (the
--          GuildRoster addon, CF slug libguildroster) declared in .toc/.pkgmeta
--          rather than vendored. DeltaSync consumes it for player identity, the
--          whisper online-guard, and the default isValidPeer. No wire-format
--          change. Breaking for any consumer that resolved LibStub("GuildCache-1.0")
--          from DeltaSync's bundle — see CHANGELOG v3.0.0 migration notes.
-- MINOR 12: optional RosterSync module (DeltaSyncRoster.lua) for cross-guild
--          sister-roster sharing, plus a generic leaf-type router
--          (RegisterLeafType) that dispatches typed QUERY/RESPONSE traffic to an
--          opt-in module before the host data callbacks. Purely additive — a
--          consumer that never calls InitRosterSync is byte-identical to MINOR 11.
-- MINOR 13: optional guild-mode module (DeltaSyncGuildMode.lua) — a user toggle
--          that reroutes the five directed channels (QUERY/RESPONSE/DELTA/OFFER/
--          HANDSHAKE) from WHISPER to GUILD for servers (e.g. Whitemane) that
--          don't deliver addon whispers, stamping each directed send with its
--          recipient so every other guild member drops it. Adds two nil-guarded
--          core seams (SendMessage recipient stamp + lib:_GuildModeInbound filter
--          on both inbound dispatch paths) plus target-deferred distribution at
--          the directed call sites; all no-ops until lib:InitGuildMode is called,
--          so a non-consumer is byte-identical to MINOR 12. RosterSync (cross-
--          guild) self-disables while guild-mode is active.
-- MINOR 14: BroadcastData / BroadcastItemHashes now return the serialized payload
--          size (bytes) as an additive second value alongside the existing ok
--          boolean, letting hosts log accurate send sizes. Single-return callers
--          are unaffected.
-- MINOR 15: MULTI-HOST. DeltaSync is no longer a singleton. lib:NewHost(config)
--          returns an isolated per-host object (own namespace/prefixes/callbacks/
--          peerStates/localState/p2p/rosterSync/guildMode/leafHandlers and its own
--          RegisterComm registrations); multiple consuming addons in one client now
--          coexist without clobbering each other. Every instance method
--          (BroadcastVersion, RequestData, SendData, InitP2P, InitRosterSync,
--          InitGuildMode, DebugStatus, delta ops, …) is called on the host object.
--          lib:Initialize(config) is kept as backward-compatible SUGAR that inits
--          onto the shared lib table itself (an implicit "default host"), so a lone
--          un-migrated consumer is byte-compatible — but two consumers both calling
--          Initialize still share the one default-host slot and clobber, so all but
--          at most one consumer must migrate to NewHost. The P2P/RosterSync/GuildMode
--          modules moved from file-local singletons to persistent class tables
--          (lib._P2PClass / lib._RosterClass / lib._GuildModeClass) whose per-host
--          instances carry a _host back-reference. Wire format unchanged; feature-
--          detect with `DS.NewHost and DS.MINOR >= 15`.
-- MINOR 16: timer-cancel fix + offline test suite. Four P2PSession timers were
--          created with C_Timer.After and stored for later cancellation, but
--          only C_Timer.NewTimer returns a handle carrying :Cancel() — so every
--          cancel was a silent no-op behind an `if timer then` guard. Most
--          visibly, extending the offer collect window did not extend it: the
--          original timer survived, Dispatch fired at the old deadline (dropping
--          offers that arrived in the extension) and then fired again later.
--          All four now use NewTimer. Also switched DeltaOperations.lua's
--          load-order guard to the silent LibStub form so its own error message
--          is reachable. No wire-format or API change.
-- MINOR 17: delivery verdicts. Every send now passes a callback to
--          SendCommMessage and records whether the client actually accepted it
--          (host.sendsDelivered / host.sendFailures / host.lastSendFailure, plus
--          the new config.onSendFailed). Previously DeltaSync passed no
--          callback, so a refused send was reported by AceCommQueue-1.0 through
--          geterrorhandler() — attributed to the comm layer, invisible to
--          DebugStatus and to the host. The handler is correct under BOTH
--          callback shapes AceCommQueue documents: one terminal callback when
--          the host embedded the queue, one per chunk when it did not.
--          DebugStatus also reports whether the queue is embedded at all.
--          Additive; no wire-format or behavioural change to sending itself.
-- MINOR 18: deletions propagate, per-send completions, and the peer-review
--          fixes. WIRE FORMAT (additive): a structured delta may carry a
--          top-level `removed` list and a modified array entry a `_removed`
--          list -- both omitted when nothing was deleted, so a delta without
--          deletions is byte-identical to MINOR 17's. Before this a deleted
--          field was detected and dropped by `changes[field] = nil`, and the
--          receiver kept it forever. API (additive): config.onSendComplete and
--          a trailing onComplete on SendMessage / RequestData / SendData --
--          exactly one terminal verdict per send, including sends declined
--          before the transport (LIBREQ-DS-009). HASH: SerializeForHash tracks
--          the ancestor path instead of every visited table, so an aliased
--          sub-table hashes like two equal copies; output changes only for
--          inputs whose hash was already unstable. P2P: HandleSyncRequest
--          gates on isValidPeer; ReleaseSendSlot reconciles name spellings;
--          pendingDispatch is de-duplicated; ScheduleCatchUp uses NewTimer.
--          CHANNEL: a CHANNEL prefix must name its channel ("*" for wildcard).
--          NEW MODULES (both optional, both inert until initialised):
--          DeltaSyncNumbers.lua -- host:InitNumbers -- a guild-wide 4-digit
--          number per item key, minted for life, synced by version over
--          HANDSHAKE (numbers-request / numbers-reply). DeltaSyncP2PNumbered.lua
--          -- host:InitP2P({ mode = "numbered" }) -- TOGBankClassic's P2P-035
--          protocol: items named by number on the wire, offer only when strictly
--          newer, a version query before dispatch, newest holders only with
--          queueing, sync-busy{reason="version"}, provider queues at capacity.
--          The hash protocol in P2PSession.lua is unchanged; the send-slot
--          accounting both classes share is lib._SendSlotMixin.
-- MINOR 19: VersionCheck-1.0 registration (DeltaSyncVersionCheck.lua, standalone
--          addon only). Numbered P2P: unmentioned keys offered back, the number
--          table sent before an offer to a broadcaster behind on it, unresolved
--          offers parked until the table lands, broadcastExtra(); onOfferReceived
--          fires BEFORE P2P acts, both protocols (v4.2.0, 2026-09-16).
-- MINOR 20: two fixes the real wire exposed once the suite ran every peer as a
--          harness client. _RegisterPrefix reads Enum.RegisterAddonMessagePrefixResult
--          (the client never returns a boolean, so the refusal report advertised
--          since v4.0.2 could not fire); numbered P2P's IsAuthor canonicalises the
--          sender before comparing to the item key (a same-realm author arrives
--          bare, so the author rules never applied on-realm) (v4.2.2, 2026-09-20).
-- MINOR 21: every sender a consumer sees is canonical Name-Realm. lib:NormalizeSender
--          canonicalises through GuildRoster:NormalizeName at the comm boundary
--          (inline realm fallback without the library), so the transport callbacks
--          agree with the P2P tables and LibGuildRoster's keys. Operator directive:
--          "we need to use name normalization and send the names with realms, because
--          we should not check if we need to normalize it or not based on the
--          recipient." Behaviour change for consumers, no signature or wire change
--          (v4.3.0, 2026-09-20).
-- MINOR 22: numbered P2P reads a number only through a table that minted it
--          (NUM:Reads; ver-query/ver-reply carry v), parks unreadable broadcasts
--          (p2p:ParkBroadcast) and replays them after the adopt's own mint, fires
--          onNewerCleared when a fetch fails; directed sends to an offline sister-
--          guild member are declined and inbound sister senders are MarkOnline'd
--          (lib:_InboundSender) (v4.4.0, 2026-09-27).
-- MINOR 23: a WHISPER is addressed without the realm on regional-unique-name
--          clients (WoW: Forever), through LibGuildRoster:WhisperTarget; every
--          other client and every callback keeps Name-Realm (v4.4.1, 2026-09-29).
local MAJOR, MINOR = "DeltaSync-1.0", 23
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then
    return -- Already loaded
end

-- Expose MINOR on the handle so consumers can feature-detect the multi-host API
-- (`DS.NewHost and DS.MINOR >= 15`) without poking LibStub internals.
lib.MINOR = MINOR

-- AceSerializer-3.0 is referenced via LibStub at call-time — never embedded
-- into `lib`. Embedding would couple DeltaSync to Ace's MINOR upgrades and
-- duplicate Serialize/Deserialize methods that the host addon already has.
-- The lookup is cached in a file-local upvalue on first use.
local _AceSer
local function AceSer()
    if not _AceSer then
        _AceSer = LibStub("AceSerializer-3.0")
    end
    return _AceSer
end

-- LibGuildRoster-1.0 is the roster engine — a required standalone-addon
-- dependency (the GuildRoster addon, declared in .toc/.pkgmeta), not vendored
-- here. It replaced the retired GuildCache-1.0. Consumed via LibStub with the
-- soft-dep presence check kept so DeltaSync still degrades gracefully if it's
-- absent — it falls back to inline realm derivation and skips the whisper guard.
local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

-- ============================================================================
-- LEAF-TYPE ROUTING (additive; no-op until a module registers a handler)
-- ============================================================================
-- An optional module (e.g. DeltaSyncRoster) can claim a leaf-key *type* prefix
-- so its directed QUERY/RESPONSE traffic is dispatched to it instead of the
-- host's onDataRequest/onDataReceived. Routing keys on the payload's `type`
-- field (baseline.type on QUERY, data.type on RESPONSE/DATA/DELTA): a message
-- whose type equals a registered prefix, or starts with "<prefix>:", is handed
-- to that module and never reaches the host callback. When no handler is
-- registered (the default — e.g. TOGBankClassic), routing is a no-op and the
-- host callbacks fire exactly as before.
lib.leafHandlers = lib.leafHandlers or {}

--- Register handlers for a leaf-type prefix.
-- @param prefix    string  e.g. "roster" (matches type=="roster" or "roster:*")
-- @param handlers  table   { onDataRequest=fn(sender,baseline), onDataReceived=fn(sender,data,len) }
function lib:RegisterLeafType(prefix, handlers)
    if type(prefix) == "string" and prefix ~= "" then
        self.leafHandlers[prefix] = handlers
    end
end

-- Internal: route a payload to a registered leaf handler by its `type` field.
-- Returns true if claimed by a leaf module (host must not see it), false to
-- fall through to the host callback.
function lib:_RouteLeaf(kind, sender, payload, ...)
    local handlers = self.leafHandlers
    if not handlers or not next(handlers) then return false end
    local t = (type(payload) == "table") and payload.type
    if type(t) ~= "string" then return false end
    for prefix, h in pairs(handlers) do
        if t == prefix or t:sub(1, #prefix + 1) == prefix .. ":" then
            local fn = h and h[kind]
            if fn then fn(sender, payload, ...) end
            return true  -- claimed: a leaf-typed message never reaches the host
        end
    end
    return false
end

-- Internal: dispatch inbound request/data — leaf router first, host callback
-- otherwise. Centralizes the route-then-host decision so the hook lives in
-- exactly one place per direction.
function lib:_DispatchRequest(sender, baseline)
    if self:_RouteLeaf("onDataRequest", sender, baseline) then return end
    if self.callbacks and self.callbacks.onDataRequest then
        self.callbacks.onDataRequest(sender, baseline)
    end
end

function lib:_DispatchData(sender, payload, len)
    if self:_RouteLeaf("onDataReceived", sender, payload, len) then return end
    if self.callbacks and self.callbacks.onDataReceived then
        self.callbacks.onDataReceived(sender, payload, len)
    end
end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Communication channel types
-- VERSION, DATA, QUERY, RESPONSE, DELTA: core sync channels (5 prefixes)
-- OFFER, HANDSHAKE: P2P session negotiation channels (2 prefixes, 7 total)
local CHANNEL_TYPES = {
    VERSION   = "v",  -- Version/hash-list broadcast
    DATA      = "d",  -- Full data sync
    QUERY     = "q",  -- Data query/request
    RESPONSE  = "r",  -- Query response
    DELTA     = "x",  -- Delta sync
    OFFER     = "o",  -- Hash-offer (peer → broadcaster) or hash-list-broadcast (GUILD)
    HANDSHAKE = "h",  -- P2P handshake: sync-request / sync-accept / sync-busy
}

-- Wire format for checksum-wrapped messages:
--   <AceSerializer payload> \030 <checksum> \031END
-- \030 = ASCII Record Separator (not emitted by AceSerializer)
-- \031END = stop-marker confirming message was fully delivered (not truncated)
local CHECKSUM_SEPARATOR = "\030"
local STOP_MARKER        = "\031END"

-- Default channel configuration
-- Host addons can override these during Initialize()
local DEFAULT_CHANNEL_CONFIG = {
    VERSION = {
        distribution = "GUILD",
        priority = "NORMAL",
        channel = nil,
    },
    DATA = {
        distribution = "GUILD",
        priority = "BULK",
        channel = nil,
    },
    QUERY = {
        distribution = "WHISPER",
        priority = "NORMAL",
        channel = nil,
    },
    RESPONSE = {
        distribution = "WHISPER",
        priority = "NORMAL",
        channel = nil,
    },
    DELTA = {
        distribution = "WHISPER",
        priority = "NORMAL",
        channel = nil,
    },
    -- P2P negotiation channels
    OFFER = {
        distribution = "WHISPER",  -- whisper by default; BroadcastItemHashes overrides to GUILD
        priority = "NORMAL",
        channel = nil,
    },
    HANDSHAKE = {
        distribution = "WHISPER",
        priority = "NORMAL",
        channel = nil,
    },
}

-- Valid distribution types
local VALID_DISTRIBUTIONS = {
    GUILD = true,
    RAID = true,
    PARTY = true,
    WHISPER = true,
    CHANNEL = true,
}

-- Valid priority levels (AceComm/ChatThrottleLib)
local VALID_PRIORITIES = {
    ALERT = true,   -- Highest priority, bypasses throttling
    NORMAL = true,  -- Standard priority
    BULK = true,    -- Lowest priority, background tasks
}

-- Maximum prefix length enforced by WoW
local MAX_PREFIX_LENGTH = 16

-- Debug categories for filtering
local DEBUG_CATEGORY = {
    INIT = "INIT",           -- Library initialization
    HASH = "HASH",           -- Hash computation
    COMMS = "COMMS",         -- Communication layer
    DELTA = "DELTA",         -- Delta operations
    VALIDATE = "VALIDATE",   -- Validation/sanitization
    SERIALIZE = "SERIALIZE", -- Serialization layer
    P2P = "P2P",             -- P2P session / offer / handshake activity
    ROSTER = "ROSTER",       -- RosterSync cross-guild sister-roster activity
}

-- Debug sub-tags for fine-grained filtering
-- nil entry in host SV = tag is ALLOWED by default (opt-out model)
local DEBUG_TAGS = {
    COMMS = {
        SEND = "message sends",
        RECEIVE = "message receives",
        HANDLER = "handler invocations",
        REGISTER = "channel registration",
        SKIP = "message skipped (e.g. offline whisper)",
    },
    DELTA = {
        COMPUTE = "delta computation",
        APPLY = "delta application",
        VALIDATE = "delta validation",
    },
    HASH = {
        ARRAY = "array hash computation",
        STRUCTURED = "structured hash computation",
    },
    P2P = {
        OFFER = "hash offers sent / received",
        HANDSHAKE = "sync-request / accept / busy",
        SESSION = "session lifecycle",
    },
}

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

-- Generate a shortened addon name for prefix generation
-- Creates a 6-character prefix from the addon name
-- @param addonName: full addon name
-- @return: 6-character prefix
local function GenerateShortName(addonName)
    if not addonName or addonName == "" then
        return "dltsyn"  -- Default: "dltsyn" (deltasync shortened)
    end

    -- Lowercase and remove spaces/special chars
    local cleaned = string.lower(addonName)
    cleaned = string.gsub(cleaned, "[^a-z0-9]", "")

    -- Always truncate to exactly 6 characters
    if #cleaned > 6 then
        cleaned = string.sub(cleaned, 1, 6)
    elseif #cleaned < 6 then
        -- Pad with 'x' if too short (rare case)
        while #cleaned < 6 do
            cleaned = cleaned .. "x"
        end
    end

    return cleaned
end

-- Validate channel configuration
-- @param channelConfig: table of channel configurations
-- @return: true if valid, or nil + error message
local function ValidateChannelConfig(channelConfig)
    if not channelConfig then
        return true -- nil config is valid, will use defaults
    end

    if type(channelConfig) ~= "table" then
        return nil, "Channel configuration must be a table"
    end

    for channelName, config in pairs(channelConfig) do
        -- Validate channel name
        if not CHANNEL_TYPES[channelName] then
            return nil, string.format("Unknown channel type: %s", channelName)
        end

        -- Validate config structure
        if type(config) ~= "table" then
            return nil, string.format("Channel %s config must be a table", channelName)
        end

        -- Validate distribution
        if config.distribution then
            if not VALID_DISTRIBUTIONS[config.distribution] then
                return nil, string.format("Channel %s: Invalid distribution '%s'", channelName, config.distribution)
            end

            -- CHANNEL distribution requires a channel NAME. "*" is accepted as
            -- an explicit listen-on-every-channel (see DeltaSyncChannel.lua);
            -- an omitted or empty name is refused rather than read as one.
            if config.distribution == "CHANNEL" and
               (type(config.channel) ~= "string" or config.channel == "") then
                return nil, string.format("Channel %s: CHANNEL distribution requires 'channel' parameter", channelName)
            end
        end

        -- Validate priority
        if config.priority then
            if not VALID_PRIORITIES[config.priority] then
                return nil, string.format("Channel %s: Invalid priority '%s' (must be ALERT, NORMAL, or BULK)", channelName, config.priority)
            end
        end
    end

    return true
end

-- Merge channel configuration with defaults
-- @param userConfig: user-provided configuration (may be partial)
-- @return: complete configuration with defaults filled in
local function MergeChannelConfig(userConfig)
    local merged = {}

    -- Start with defaults
    for channelName, defaultConfig in pairs(DEFAULT_CHANNEL_CONFIG) do
        merged[channelName] = {
            distribution = defaultConfig.distribution,
            priority = defaultConfig.priority,
            channel = defaultConfig.channel,
        }
    end

    -- Override with user config
    if userConfig then
        for channelName, userChannelConfig in pairs(userConfig) do
            if merged[channelName] then
                if userChannelConfig.distribution then
                    merged[channelName].distribution = userChannelConfig.distribution
                end
                if userChannelConfig.priority then
                    merged[channelName].priority = userChannelConfig.priority
                end
                if userChannelConfig.channel then
                    merged[channelName].channel = userChannelConfig.channel
                end
            end
        end
    end

    return merged
end

-- Generate all communication prefixes for an addon
-- @param addonName: full addon name
-- @return: table of prefixes { version="...", data="...", etc. }
local function GeneratePrefixes(addonName)
    local shortName = GenerateShortName(addonName)
    local prefixes = {}

    for channelName, suffix in pairs(CHANNEL_TYPES) do
        local prefix = shortName .. "-" .. suffix
        if #prefix > MAX_PREFIX_LENGTH then
            -- Should never happen with our truncation, but safety check
            prefix = string.sub(prefix, 1, MAX_PREFIX_LENGTH)
        end
        prefixes[channelName] = prefix
    end

    return prefixes
end

-- Compute a simple but effective checksum/hash of a string
-- Uses multiplicative hashing with prime number (31) for good distribution
-- Returns: numeric hash value (0 to 2147483647)
local function ComputeChecksum(str)
    if not str or type(str) ~= "string" then
        return 0
    end

    local sum = 0
    local len = #str
    for i = 1, len do
        local byte = string.byte(str, i)
        sum = (sum * 31 + byte) % 2147483647
    end
    -- Include length to detect truncation
    sum = (sum * 31 + len) % 2147483647

    return sum
end

-- Serialize a Lua value to a string for hashing
-- Handles tables, strings, numbers, booleans, nil
--
-- @param tagTypes  revision 2 only — prefix each scalar with its type.
--   Revision 1 renders a number with tostring() and a string as itself, so
--   1 and "1" produce identical bytes and therefore identical hashes (and the
--   boolean true collides with the string "true"). A consumer storing a count
--   as text looks unchanged to a peer storing it as a number, and the sync is
--   skipped. Revision 2 tags each scalar ("n:1" vs "s:1") and has no such
--   collision.
--
--   Both revisions ship SIDE BY SIDE — see lib:MakeHashEntry. A peer advertises
--   both, and the comparison uses the highest revision BOTH ends advertise, so a
--   v1-only peer and a v2 peer still agree via v1. Revision 1 is retired by
--   dropping the `hash` field once no v1-only peers remain, not by a flag day.
-- Returns: string representation
local function SerializeForHash(value, seen, tagTypes)
    seen = seen or {}
    local valueType = type(value)

    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "number" then
        return tagTypes and ("n:" .. tostring(value)) or tostring(value)
    elseif valueType == "string" then
        return tagTypes and ("s:" .. value) or value
    elseif valueType == "table" then
        -- Detect circular references. `seen` holds the ANCESTOR PATH -- the
        -- tables currently open above this one -- and each table is cleared on
        -- the way out (below). It used to hold every table ever visited, which
        -- detects REVISITS rather than cycles: a sub-table referenced twice in a
        -- DAG serialised in full the first time and as the literal "circular"
        -- the second, so { x = T, y = T } hashed differently from
        -- { x = T, y = copy(T) } over identical content, and two peers offered
        -- each other data across a difference that did not exist (AUDIT finding
        -- 12). Aliasing is a table-level property, so revision 2's scalar type
        -- tags could not reach it; this fixes both revisions, and changes the
        -- output only for inputs whose hash was already unstable.
        if seen[value] then
            return "circular"
        end
        seen[value] = true

        -- Collect and sort keys for consistent ordering
        local keys = {}
        for k in pairs(value) do
            table.insert(keys, k)
        end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then
                return ta < tb
            end
            return tostring(a) < tostring(b)
        end)

        -- Build serialized representation
        local parts = {}
        for _, k in ipairs(keys) do
            local keyStr = SerializeForHash(k, seen, tagTypes)
            local valStr = SerializeForHash(value[k], seen, tagTypes)
            table.insert(parts, keyStr .. "=" .. valStr)
        end

        -- Leaving this table: it is no longer an ancestor, so a later sibling
        -- reference to it is an alias, not a cycle, and serialises in full.
        seen[value] = nil

        return "{" .. table.concat(parts, ",") .. "}"
    else
        -- Unsupported type (function, userdata, thread)
        return "unsupported:" .. valueType
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Initialize the library with configuration options
-- @param config: table with optional fields:
--   - namespace: string, unique identifier for your addon (REQUIRED)
--   - aceAddon: AceAddon instance with AceComm-3.0 embedded via NewAddon (REQUIRED for AceComm path)
--   - debug: table with debug configuration:
--       - enabled: boolean, enable debug logging (default: false)
--       - addonName: string, name for debug tab (default: namespace)
--       - savedVariables: table, reference to host addon's SV table (REQUIRED for persistence)
--       - categories: table, initial category states (optional, uses SV if available)
--   - hashStrategy: DEPRECATED and INERT. Never read by anything; accepted and
--       ignored. Slated for removal after ~2026-08-24 (see InitHost).
--   - onVersionReceived: function(sender, version, hash), called when version broadcast received
--   - onDataRequest: function(sender, baseline), called when data request received
--   - onDataReceived: function(sender, data), called when full data or delta received
--   - onOfferReceived: function(sender, data), raw OFFER message received (P2P inspection hook)
--   - channelModule: optional table for CHANNEL transport (SendChatMessage + CHAT_MSG_CHANNEL)
--       see DeltaSyncChannel.lua companion for details.
-- Internal: run all per-host initialization onto `host` — an object whose
-- metatable __index is `lib`, so it inherits every DeltaSync method while its
-- own fields hold this host's isolated state. Shared by both the multi-host
-- factory (lib:NewHost) and the legacy singleton entry point (lib:Initialize,
-- which inits onto the shared lib table itself). Returns `host`.
local function InitHost(host, config)
    config = config or {}

    -- Load-order / clobber / embedder resilience: re-resolve the LibGuildRoster
    -- handle at init (runs post-PLAYER_LOGIN, when every addon is loaded). The
    -- file-load-time upvalue is nil only if our `## Dependencies: GuildRoster`
    -- wasn't honored (e.g. an embedder vendoring our source without declaring
    -- it, or a TOC whose dependency line was lost). Reassigning the shared
    -- upvalue updates every call site (player identity, whisper online-guard).
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))

    if not config.namespace then
        error("DeltaSync: NewHost/Initialize requires 'namespace' parameter (your addon name)")
    end

    host.namespace = config.namespace

    -- Validate and merge channel configuration
    local valid, err = ValidateChannelConfig(config.channels)
    if not valid then
        error("DeltaSync: Invalid channel configuration: " .. err)
    end
    host.channelConfig = MergeChannelConfig(config.channels)

    -- Optional injected host logger (LIBREQ-DS-003).
    --
    -- A sync library should not own a chat frame. When the host supplies a
    -- logger, DeltaSync hands it every debug line verbatim and stops filtering,
    -- buffering and claiming a tab entirely — one category registry and one tab,
    -- the host's. Accepts either a plain function or an object with :Debug, so a
    -- host can pass its existing logger module straight in.
    --
    -- `false` rather than nil so a NewHost host never inherits the legacy default
    -- host's logger through __index.
    host.logger = config.logger or false

    -- Optional debug TAP: fn(message, category, tag), fired for every message
    -- DeltaSync logs, ALONGSIDE its own tab and buffer rather than instead of
    -- them. Lets a host persist or export the library's diagnostics while
    -- DeltaSync's own buffer stays session-only and capped — retention policy
    -- costs the HOST's SavedVariables, so the host owns it.
    --
    -- Ignored when config.logger is set, since that already routes everything.
    host.onDebugMessage = config.onDebugMessage or false

    -- Initialize debug system
    local debugConfig = config.debug or {}
    host.debugEnabled = debugConfig.enabled or false
    host.debugAddonName = debugConfig.addonName or host.namespace
    host.debugSV = debugConfig.savedVariables

    -- Initialize debug storage in host SV if not exists
    if host.debugEnabled and host.debugSV then
        if not host.debugSV.deltaSyncDebug then
            host.debugSV.deltaSyncDebug = {
                categories = {},
                tags = {},
            }
        end

        -- Apply initial category states if provided
        if debugConfig.categories then
            for category, enabled in pairs(debugConfig.categories) do
                host.debugSV.deltaSyncDebug.categories[category] = enabled
            end
        end
    end

    -- Initialize debug frame and buffer
    host.debugFrame = nil
    host.debugMessageBuffer = {}
    host.maxBufferSize = 1000

    -- DEPRECATED, INERT — commented out 2026-08-03, remove after ~2026-08-24.
    --
    -- `hashStrategy` was stored here and then read by absolutely nothing: no
    -- code path in any of the six files ever branched on it, so "deep" and
    -- "shallow" behaved identically. Documenting a knob that does nothing is
    -- worse than not having one, because a consumer sets it and believes it took
    -- effect.
    --
    -- Commented rather than deleted so the field can come back cheaply if a
    -- consumer turns out to be READING `host.hashStrategy` (nothing in this
    -- workspace does — checked TOGProfessionMaster, PersonalShopper, FGI and
    -- TOGBankClassic). Passing `config.hashStrategy` remains harmless: it is
    -- simply ignored, exactly as it always effectively was.
    -- host.hashStrategy = config.hashStrategy or "deep"
    host.callbacks = {
        onVersionReceived  = config.onVersionReceived,
        onDataRequest      = config.onDataRequest,
        onDataReceived     = config.onDataReceived,
        -- P2P callbacks
        onOfferReceived    = config.onOfferReceived,   -- (sender, data) raw OFFER message received
        -- (info) a send the CLIENT REFUSED — the message did not arrive. See
        -- OnSendResult. info = { prefix, channelType, distribution, target, bytes, at }
        onSendFailed       = config.onSendFailed,
        -- (info) MINOR 18+: EVERY send's terminal state, exactly once per send,
        -- whatever the verdict. info = { prefix, channelType, distribution,
        -- target, bytes, at, verdict = "delivered" | "refused" | "not-attempted",
        -- reason, unverified }. See CompleteSend. A host that meters its own
        -- sends (a provider giving back a slot when the reply has DRAINED, not
        -- when it was queued) needs this; onSendFailed reports refusals only.
        onSendComplete     = config.onSendComplete,
    }

    -- Per-host leaf-type router. MUST be its own fresh table — never the shared
    -- lib.leafHandlers — or two hosts' RegisterLeafType calls (e.g. both claiming
    -- "roster") would collide on the shared table. RegisterLeafType/_RouteLeaf
    -- index self.leafHandlers, so this per-host table keeps them isolated.
    host.leafHandlers = {}

    -- Optional-module slots. Set to `false` (an own field) rather than left nil
    -- so the core seams that read them — OnComm_OFFER/HANDSHAKE's `if self.p2p`,
    -- SendMessage / _GuildModeInbound's `self.guildMode` — see this host's own
    -- falsy value and never fall through __index to the legacy default host's
    -- instance on `lib`. Their Init methods (InitP2P/InitRosterSync/InitGuildMode)
    -- replace the sentinel with a real per-host instance via rawget.
    -- rawget-preserve so a *re-init* (legacy Initialize called twice on lib, after
    -- InitP2P already ran) keeps the live instance instead of nuking it back to
    -- false; a fresh NewHost object has no own field, so this yields false there.
    host.p2p        = rawget(host, "p2p")        or false
    host.rosterSync = rawget(host, "rosterSync") or false
    host.guildMode  = rawget(host, "guildMode")  or false
    host.numbers    = rawget(host, "numbers")    or false   -- DeltaSyncNumbers.lua (MINOR 18+)

    -- Generate and store communication prefixes
    host.prefixes = GeneratePrefixes(host.namespace)

    -- Initialize state storage
    host.localState = {
        version = 0,
        hash = 0,
        data = nil,
    }

    -- Peer state tracking
    host.peerStates = {} -- [sender] = { version, hash, lastSeen }

    -- Store player name for self-ignore.
    -- LibGuildRoster-1.0 (if loaded) provides canonical Name-Realm form via
    -- GuildRoster:GetNormalizedPlayer(); otherwise we fall back to an inline
    -- compose that strips realm spaces (e.g. "Old Blanchy" → "OldBlanchy") to
    -- match what CHAT_MSG_CHANNEL sender strings look like.
    host.playerName = UnitName and UnitName("player") or ""
    if GuildRoster and GuildRoster.GetNormalizedPlayer then
        host.playerFullName = GuildRoster:GetNormalizedPlayer()
    end
    -- Inline fallback when LibGuildRoster is absent OR returned nil (e.g.
    -- init called before UnitName resolves): compose Name-Realm with realm
    -- spaces stripped to match CHAT_MSG_CHANNEL sender strings.
    if not host.playerFullName then
        local realm = GetRealmName and GetRealmName()
        if realm then
            realm = realm:gsub("%s+", "")
            host.playerFullName = host.playerName .. "-" .. realm
        end
    end

    -- Store host addon reference (must have AceComm-3.0 embedded via NewAddon).
    host.aceAddon = config.aceAddon

    -- -------------------------------------------------------------------------
    -- CHANNEL MODULE (optional)
    -- -------------------------------------------------------------------------
    -- WoW Classic does not fire CHAT_MSG_ADDON for custom channel numbers, so
    -- the normal AceComm/SendAddonMessage path is silently broken for CHANNEL
    -- distribution.  When channelModule.enabled = true, DeltaSync switches to
    -- raw SendChatMessage (send) + CHAT_MSG_CHANNEL (receive) for every prefix
    -- whose channelConfig.distribution == "CHANNEL".
    --
    -- Because SendChatMessage is capped at 255 bytes, the host addon must also
    -- supply a compact serializer/deserializer pair that keeps payloads small:
    --
    --   channelModule = {
    --       enabled      = true,
    --       serializer   = function(payload) -> string | nil,
    --       deserializer = function(message, sender) -> payload | nil,
    --   }
    --
    -- If serializer returns nil the message is silently dropped.
    -- If channelModule is omitted or enabled=false, the standard AceComm path
    -- is used (suitable for GUILD/PARTY/RAID/WHISPER).
    -- -------------------------------------------------------------------------
    host.channelModule = nil  -- populated below if enabled
    local cm = config.channelModule
    if cm and cm.enabled then
        host.channelModule = {
            enabled      = true,
            serializer   = cm.serializer,
            deserializer = cm.deserializer,
            frame        = nil,  -- CHAT_MSG_CHANNEL frame, set in InitChannelModule
        }
    end

    -- Register communication channels
    host:RegisterCommChannels()

    -- Boot the channel module after RegisterCommChannels so channelConfig is ready.
    if host.channelModule then
        if not host.InitChannelModule then
            error("DeltaSync: channelModule.enabled = true but DeltaSyncChannel.lua was not loaded. Add it to your TOC after DeltaSync.lua.")
        end
        host:InitChannelModule()
    end

    -- Create debug chat frame if enabled. An injected logger owns the tab, so we
    -- never claim one — but the init lines are still emitted and it decides
    -- whether to show them.
    if host.debugEnabled or host.logger then
        if host.debugEnabled and not host.logger then
            host:CreateDebugTab()
        end
        host:Debug("INIT", "Initialized DeltaSync for %s (MINOR=%d)", host.namespace, MINOR)
        host:Debug("INIT", "Prefixes: v=%s, d=%s, q=%s, r=%s, x=%s, o=%s, h=%s",
            host.prefixes.VERSION,
            host.prefixes.DATA,
            host.prefixes.QUERY,
            host.prefixes.RESPONSE,
            host.prefixes.DELTA,
            host.prefixes.OFFER,
            host.prefixes.HANDSHAKE)

        -- Log channel configuration
        for channelName, chCfg in pairs(host.channelConfig) do
            host:Debug("INIT", "Channel %s: distribution=%s, priority=%s%s",
                channelName,
                chCfg.distribution,
                chCfg.priority,
                chCfg.channel and (", channel=" .. chCfg.channel) or "")
        end

        -- Log channel module status
        if host.channelModule then
            host:Debug("INIT", "ChannelModule: ENABLED (compact SendChatMessage transport)")
        else
            host:Debug("INIT", "ChannelModule: disabled (AceComm/SendAddonMessage transport)")
        end
    end

    return host
end

--- Create an isolated DeltaSync host (MINOR 15+).
-- Each consuming addon calls this once and holds the returned object; all
-- instance methods (BroadcastVersion, RequestData, SendData, InitP2P,
-- InitRosterSync, InitGuildMode, DebugStatus, delta ops, …) are invoked on it.
-- Multiple hosts coexist fully isolated: distinct namespaces → distinct prefixes
-- → no cross-talk, each with its own callbacks/peerStates/localState/p2p and its
-- own RegisterComm registrations on its own config.aceAddon.
-- @param config  see the field docs on lib:Initialize above (identical shape)
-- @return host   the per-host object
function lib:NewHost(config)
    local host = setmetatable({}, { __index = lib })
    return InitHost(host, config)
end

-- Legacy singleton entry point — now backward-compatible SUGAR over the
-- multi-host core. Initializes onto the shared lib table itself (the implicit
-- "default host"), so a single un-migrated consumer is byte-compatible with
-- pre-MINOR-15 behavior. CAVEAT: there is only one default-host slot, so two
-- consumers both calling Initialize still clobber each other's namespace/
-- prefixes/callbacks — migrate all but at most one consumer to NewHost. New
-- code should prefer lib:NewHost and feature-detect via `DS.NewHost and
-- DS.MINOR >= 15`.
function lib:Initialize(config)
    return InitHost(self, config)
end

-- ============================================================================
-- CHANNEL MODULE HOOK POINTS
-- ============================================================================
-- The CHANNEL transport (SendChatMessage send + CHAT_MSG_CHANNEL receive) lives in
-- DeltaSyncChannel.lua.  That file is optional — addons that only use GUILD/PARTY/
-- RAID/WHISPER distribution never need to load it.
--
-- When DeltaSyncChannel.lua IS loaded it adds two methods to this lib object:
--   lib:InitChannelModule()   called automatically by Initialize()
--   lib:SendViaChannel()      called automatically by SendMessage() for CHANNEL dist
--
-- If channelModule.enabled = true but DeltaSyncChannel.lua was not loaded,
-- Initialize() will raise a descriptive error rather than silently misbehaving.

-- ============================================================================
-- COMMUNICATION REGISTRATION
-- ============================================================================

-- Register all communication channels with AceComm.
-- For CHANNEL-distribution prefixes the ChannelModule (SendChatMessage transport)
-- handles send/receive; AceComm is still registered for GUILD/PARTY/RAID/WHISPER
-- (including OFFER and HANDSHAKE, which are WHISPER/GUILD by default).
-- Requires host addon to have AceComm-3.0 embedded via NewAddon (passed as config.aceAddon).
-- Register one addon-message prefix and REPORT a refusal.
--
-- AceComm calls C_ChatInfo.RegisterAddonMessagePrefix and discards the result.
-- Past the client's registered-prefix cap, or for an invalid prefix, registration
-- is refused — after which messages on that prefix never arrive. No error, no
-- warning, just a dead channel, which is the worst failure mode available and
-- exactly the class this codebase keeps getting bitten by.
--
-- WHAT THE CLIENT ACTUALLY RETURNS, from ChatConstantsDocumentation.lua (Classic
-- Era, identical on every flavour): a NUMBER from Enum.RegisterAddonMessagePrefixResult,
-- never a boolean and never nil (ChatInfoDocumentation.lua:334, Nilable = false):
--   Success = 0, DuplicatePrefix = 1, InvalidPrefix = 2, MaxPrefixes = 3.
-- 0 is truthy in Lua, so the guard this function carried from v4.0.2 to v4.2.1 --
-- `if accepted == false` -- could NEVER fire in game: MaxPrefixes came back as 3.
-- The offline env returned true/false and the spec passed. Found 2026-09-20 when
-- the suite moved onto the harness's real C_ChatInfo model.
--
-- DuplicatePrefix is NOT a refusal: AceComm registers each prefix on our behalf
-- first, so our own registration answers DuplicatePrefix on every login, forever.
-- Reporting it would be a warning that fires every time. An explicit `false` is
-- still honoured for a pre-enum client or a stub; nil is "no answer", not failure.
-- @return boolean  false only if the client actively refused
function lib:_RegisterPrefix(registerFn, prefix, chType)
    local result = registerFn(prefix)
    local R = Enum and Enum.RegisterAddonMessagePrefixResult
    local why
    if result == false then
        why = "the client refused it"
    elseif type(result) == "number" and R then
        if result == R.MaxPrefixes then
            why = "the client's registered-prefix limit has been reached (MaxPrefixes) -- " ..
                  "check how many addons are registering prefixes"
        elseif result == R.InvalidPrefix then
            why = "the client rejected the prefix string itself (InvalidPrefix)"
        end
    end
    if why then
        local msg = string.format(
            "the client REFUSED to register addon-message prefix '%s' (%s channel). Messages on " ..
            "that channel will NEVER arrive: %s.",
            tostring(prefix), tostring(chType), why)
        self:Debug("COMMS", "REGISTER", "%s", msg)
        print("|cffff0000[DeltaSync]|r " .. msg)
        self.prefixRegistrationFailed = self.prefixRegistrationFailed or {}
        self.prefixRegistrationFailed[prefix] = chType or true
        return false
    end
    return true
end

function lib:RegisterCommChannels()
    local aceAddon = self.aceAddon

    -- Build sets: which prefixes are CHANNEL-distribution (ChannelModule owns those),
    -- and which need AceComm/CHAT_MSG_ADDON (everything else).
    local channelDistPrefixes = {}  -- prefix -> true  (skip AceComm for these)
    for chType, chConfig in pairs(self.channelConfig) do
        if chConfig.distribution == "CHANNEL" and self.prefixes[chType] then
            channelDistPrefixes[self.prefixes[chType]] = true
        end
    end

    -- CHAT_MSG_ADDON sniffer: only log non-CHANNEL prefixes (CHANNEL msgs never arrive here).
    local myPrefixes = {}
    for chType, prefix in pairs(self.prefixes) do
        if not channelDistPrefixes[prefix] then
            myPrefixes[prefix] = chType
        end
    end
    local snifferFrame = CreateFrame("Frame")
    snifferFrame:RegisterEvent("CHAT_MSG_ADDON")
    snifferFrame:SetScript("OnEvent", function(_, _, prefix, message, distribution, sender)
        if myPrefixes[prefix] then
            self:Debug("COMMS", "RECEIVE",
                ">>> [RAW SNIFFER] OUR prefix=%s dist=%s sender=%s bytes=%d",
                tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)
        end
    end)
    self.snifferFrame = snifferFrame

    -- Register addon message prefixes only for non-CHANNEL distributions
    -- (CHANNEL prefixes use SendChatMessage — RegisterAddonMessagePrefix is irrelevant for them).
    local RegisterPrefix = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
    if RegisterPrefix then
        for chType, prefix in pairs(self.prefixes) do
            if not channelDistPrefixes[prefix] then
                self:_RegisterPrefix(RegisterPrefix, prefix, chType)
                self:Debug("COMMS", "REGISTER", "RegisterAddonMessagePrefix: '%s' (%s)", prefix, chType)
            else
                self:Debug("COMMS", "REGISTER", "Skipping RegisterAddonMessagePrefix for CHANNEL prefix '%s' (%s) — ChannelModule owns this", prefix, chType)
            end
        end
    end

    if aceAddon and aceAddon.RegisterComm then
        self:Debug("COMMS", "REGISTER",
            "aceAddon: name=%s RegisterComm=%s SendCommMessage=%s",
            tostring(aceAddon.name or "(no .name)"),
            tostring(type(aceAddon.RegisterComm)),
            tostring(type(aceAddon.SendCommMessage)))

        -- Register AceComm only for non-CHANNEL prefixes.
        -- CHANNEL prefixes are received via CHAT_MSG_CHANNEL (ChannelModule); AceComm
        -- would never fire for them in WoW Classic anyway.
        for chType, prefix in pairs(self.prefixes) do
            if not channelDistPrefixes[prefix] then
                local handlerName = "OnComm_" .. chType
                aceAddon:RegisterComm(prefix, function(rcvPrefix, message, distribution, sender)
                    self:Debug("COMMS", "RECEIVE",
                        ">>> [AceComm] prefix=%s dist=%s sender=%s bytes=%d",
                        tostring(rcvPrefix), tostring(distribution), tostring(sender), message and #message or 0)
                    -- Guild-mode: drop messages stamped for another player; strip
                    -- the stamp from ours. No-op unless DeltaSyncGuildMode loaded.
                    message = self:_GuildModeInbound(message, sender)
                    if message == nil then return end
                    self[handlerName](self, rcvPrefix, message, distribution, sender)
                end)
                self:Debug("COMMS", "REGISTER", "AceComm:RegisterComm('%s') -> %s", prefix, handlerName)
            else
                self:Debug("COMMS", "REGISTER", "Skipping AceComm:RegisterComm for CHANNEL prefix '%s' — ChannelModule owns this", prefix)
            end
        end
    else
        -- No AceComm: fall back to raw CHAT_MSG_ADDON for non-CHANNEL prefixes only.
        local API = C_ChatInfo or {}
        local RegPrefix = API.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
        if not RegPrefix then
            -- Only fatal if there are non-CHANNEL prefixes that need this path.
            local needsRaw = false
            for _, prefix in pairs(self.prefixes) do
                if not channelDistPrefixes[prefix] then needsRaw = true; break end
            end
            if needsRaw then
                error("DeltaSync: No AceComm-3.0 and no C_ChatInfo — cannot register non-CHANNEL prefixes")
            end
        else
            for chType, prefix in pairs(self.prefixes) do
                if not channelDistPrefixes[prefix] then
                    self:_RegisterPrefix(RegPrefix, prefix, chType)
                end
            end
        end
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("CHAT_MSG_ADDON")
        frame:SetScript("OnEvent", function(_, _, prefix, message, distribution, sender)
            if myPrefixes[prefix] then
                self:Debug("COMMS", "RECEIVE",
                    "[RAW HANDLER] prefix=%s dist=%s sender=%s bytes=%d",
                    prefix, tostring(distribution), tostring(sender), #message)
                self:OnAddonMessage(prefix, message, distribution, sender)
            end
        end)
        self.commFrame = frame
        self:Debug("COMMS", "REGISTER", "Using raw CHAT_MSG_ADDON handler for non-CHANNEL prefixes (no aceAddon)")
    end

    self.commsRegistered = true
end

-- Get the current channel configuration
-- @param channelType: specific channel (optional, returns all if nil)
-- @return: channel config table or full config
function lib:GetChannelConfig(channelType)
    if channelType then
        return self.channelConfig[channelType]
    end
    return self.channelConfig
end

-- Update channel configuration at runtime (not recommended)
-- @param channelType: channel to update
-- @param config: new configuration { distribution, priority, channel }
-- @return: true if successful, or nil + error message
function lib:SetChannelConfig(channelType, config)
    if not CHANNEL_TYPES[channelType] then
        return nil, "Unknown channel type: " .. channelType
    end

    -- Validate the configuration
    local tempConfig = { [channelType] = config }
    local valid, err = ValidateChannelConfig(tempConfig)
    if not valid then
        return nil, err
    end

    -- Update configuration
    if not self.channelConfig[channelType] then
        self.channelConfig[channelType] = {}
    end

    if config.distribution then
        self.channelConfig[channelType].distribution = config.distribution
    end
    if config.priority then
        self.channelConfig[channelType].priority = config.priority
    end
    if config.channel ~= nil then
        self.channelConfig[channelType].channel = config.channel
    end

    self:Debug("COMMS", "Updated %s channel config: dist=%s, priority=%s%s",
        channelType,
        self.channelConfig[channelType].distribution,
        self.channelConfig[channelType].priority,
        self.channelConfig[channelType].channel and (", channel=" .. self.channelConfig[channelType].channel) or "")

    return true
end

-- ============================================================================
-- SEND-RESULT REPORTING
-- ============================================================================
-- WoW silently discards addon messages under congestion, and AceComm-3.0
-- forwards only ChatThrottleLib's `didSend` boolean — so a refused send is
-- invisible unless somebody checks it. DeltaSync passes a callback on every send
-- and records the verdict here, following AceCommQueue-1.0's guidance for a
-- library sitting between a host addon and the queue: without a callback, a
-- refusal is reported by THAT library through geterrorhandler(), which
-- attributes the failure to the comm layer rather than to DeltaSync and leaves
-- the host with no structured way to see it.
--
-- THE CALLBACK SHAPE DEPENDS ON THE HOST, which is why this is not simply
-- "check argument four":
--
--   * Host embedded AceCommQueue-1.0 → fires ONCE, at the end, and `delivered`
--     is the verdict for the WHOLE message (any refused chunk ⇒ false).
--   * Host did not                   → fires once PER CHUNK, and `delivered` is
--     that chunk's didSend.
--
-- Handling only one shape misbehaves under the other — counting a multipart
-- send as several failures, or waiting for a terminal callback that never
-- arrives. This handler is correct under both: any `delivered == false` means
-- the message did not arrive (true either way, since one refused chunk leaves
-- the receiver's spool corrupt), and it is reported only once per send.
--
-- `delivered` is a BOOLEAN, never an Enum.SendAddonMessageResult member —
-- AceComm discards the enum — so there is no way to learn *why* from up here.
-- @param reason  OPTIONAL 5th argument, supplied by newer AceCommQueue-1.0
--   revisions to distinguish the three situations that collapse into a `nil`
--   verdict ("suppressed" / "rejected" / "error"). Read nil-guarded, so this
--   works unchanged against a queue that does not supply it.
-- Report a send's TERMINAL state -- once, whatever it was.
--
-- Three verdicts, and the distinction that matters is not the obvious one:
--   "delivered"     every chunk was accepted by the client
--   "refused"       the client refused it (after the queue's retries, if any),
--                   or the queue rejected the call / the send raised -- in every
--                   case the message did NOT arrive
--   "not-attempted" nothing was sent, and that was not a defect: the host's own
--                   wrapper suppressed it, or DeltaSync itself declined before
--                   the transport (offline target, unknown channel, ...)
--
-- `unverified = true` marks a transport that cannot confirm delivery at all
-- (the CHANNEL transport's SendChatMessage, the raw SendAddonMessage fallback);
-- the verdict there is the best available reading, not an observation.
--
-- Fires the per-call `onComplete` (the optional trailing argument to
-- SendMessage / RequestData / SendData) and then the host-wide
-- config.onSendComplete. Both are wrapped: this runs inside the transport's own
-- callback chain, and a host callback that raises must not take the queue down
-- with it -- the error goes to geterrorhandler so it is still seen.
-- `ctx.completed` is the exactly-once guard; the LIBREQ-DS-009 contract is one
-- completion per send, and under the unqueued shape the transport callback
-- fires per chunk.
local function CompleteSend(ctx, verdict, reason, unverified)
    if not ctx or ctx.completed then return end
    ctx.completed = true
    local host = ctx.host
    local info = {
        prefix       = ctx.prefix,
        channelType  = ctx.channelType,
        distribution = ctx.distribution,
        target       = ctx.target,
        bytes        = ctx.bytes,
        at           = GetServerTime and GetServerTime() or 0,
        verdict      = verdict,
        reason       = reason,
        unverified   = unverified or nil,
    }
    local function fire(cb)
        if not cb then return end
        local ok, err = pcall(cb, info)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
            if host and host.Debug then
                host:Debug("COMMS", "SEND", "onSendComplete callback raised: %s", tostring(err))
            end
        end
    end
    fire(ctx.onComplete)
    fire(host and host.callbacks and host.callbacks.onSendComplete)
end
lib._CompleteSend = CompleteSend   -- exposed for tests

local function OnSendResult(ctx, sent, total, delivered, reason)
    local host = ctx and ctx.host
    if not host then return end

    -- A message that did NOT arrive. Two ways to learn that:
    --
    --   * `delivered == false` — the client refused it. If the host embedded
    --     AceCommQueue it has already retried with backoff before saying so.
    --   * `reason` is "rejected" or "error" — the queue refused the call (bad
    --     prefix, nil text, unknown priority) or the send raised. Both mean the
    --     message never went out, so both are genuine non-delivery even though
    --     `delivered` is nil for them.
    --
    -- The rule is deliberately NOT "delivered == false": that would miss the
    -- last two. Nor is it "any nil": `"suppressed"` is also nil and is the host
    -- doing exactly what it meant to. AceCommQueue-1.0's maintainer proposed
    -- this split and it is the right one — the distinguishing value is
    -- `"suppressed"`, not the verdict.
    local defective = (reason == "rejected" or reason == "error")
    if delivered == false or defective then
        if not ctx.reported then
            ctx.reported = true
            host.sendFailures = (host.sendFailures or 0) + 1
            host.lastSendFailure = {
                prefix       = ctx.prefix,
                channelType  = ctx.channelType,
                distribution = ctx.distribution,
                target       = ctx.target,
                bytes        = ctx.bytes,
                reason       = reason,
                at           = GetServerTime and GetServerTime() or 0,
            }
            if defective then
                -- Our own fault, not the client's: DeltaSync generates its own
                -- prefix and validates distribution and priority at config time,
                -- so "rejected" should be impossible and "error" means something
                -- in the send chain raised.
                host:Debug("COMMS", "SEND",
                    "[NOT DELIVERED: %s] %s (%s) — the message did NOT arrive, and '%s' indicates " ..
                    "a DEFECT rather than a busy client",
                    reason, tostring(ctx.prefix), tostring(ctx.channelType), reason)
            else
                host:Debug("COMMS", "SEND",
                    "[NOT DELIVERED] %s (%s dist=%s target=%s bytes=%d) — the client refused it; " ..
                    "the message did NOT arrive",
                    tostring(ctx.prefix), tostring(ctx.channelType), tostring(ctx.distribution),
                    tostring(ctx.target), ctx.bytes or 0)
            end

            local cb = host.callbacks and host.callbacks.onSendFailed
            if cb then cb(host.lastSendFailure) end
            CompleteSend(ctx, "refused", reason)
        end
    elseif delivered == nil then
        -- The send never happened, and it was NOT a defect — either the host's
        -- own wrapper suppressed it deliberately (a raid guard, say), or we are
        -- talking to an AceCommQueue revision old enough not to report a reason,
        -- in which case we cannot tell and must not guess.
        --
        -- Counted separately rather than folded into sendFailures: a suppression
        -- is the host working exactly as designed, and counting it as a failure
        -- would show a forever-climbing error count for correct behaviour. The
        -- defective cases are handled above, where they belong.
        if not ctx.reported then
            ctx.reported = true
            host.sendsNotAttempted = (host.sendsNotAttempted or 0) + 1
            host.lastSendNotAttempted = {
                prefix       = ctx.prefix,
                channelType  = ctx.channelType,
                distribution = ctx.distribution,
                target       = ctx.target,
                reason       = reason,
                at           = GetServerTime and GetServerTime() or 0,
            }
            host:Debug("COMMS", "SEND",
                "[NOT SENT] %s (%s) — never attempted (%s)",
                tostring(ctx.prefix), tostring(ctx.channelType),
                reason or "reason not reported by this AceCommQueue revision")
            -- The reason as reported: nil when this AceCommQueue revision gives
            -- none. Filling in "suppressed" here claimed a cause nobody knew.
            CompleteSend(ctx, "not-attempted", reason)
        end
    elseif delivered and sent and total and sent >= total and not ctx.reported then
        -- `not ctx.reported` matters only in the UNQUEUED shape, and it is easy
        -- to get wrong: there the callback fires per chunk, so a send whose 3rd
        -- of 5 chunks was refused still ends with a final chunk reporting
        -- `true`. Counting that as delivered would record one message as both
        -- failed and delivered — and a partial multipart stream reassembles into
        -- a corrupt payload on the receiver, so the correct reading is that it
        -- did NOT arrive. Under the queued shape this can never fire, because
        -- there is exactly one callback carrying the whole-message verdict.
        -- `total == 0` (an empty message) is terminal too.
        ctx.reported = true
        host.sendsDelivered = (host.sendsDelivered or 0) + 1
        CompleteSend(ctx, "delivered")
    end
end

-- Send a message on a specific channel
-- @param channelType: one of CHANNEL_TYPES keys (VERSION, DATA, QUERY, etc.)
-- @param message: serialized message string
-- @param distribution: "GUILD", "RAID", "PARTY", "WHISPER", "CHANNEL" (optional, uses config if nil)
-- @param target: target player name (for WHISPER only) or channel name (for CHANNEL)
-- @param priority: "ALERT", "NORMAL", "BULK" (optional, uses config if nil)
-- @param onComplete: OPTIONAL function(info) -- MINOR 18+ -- called exactly
--   once when THIS send reaches its terminal state (see CompleteSend for the
--   info shape and the three verdicts). Fires for sends DeltaSync declines
--   before the transport too (verdict "not-attempted"), so a caller metering
--   its sends never waits on a completion that cannot come. The host-wide
--   config.onSendComplete fires as well, after this one.
function lib:SendMessage(channelType, message, distribution, target, priority, onComplete)
    -- The completion context is built BEFORE any guard so that every way out of
    -- this function reports (LIBREQ-DS-009 point 4): a callback that fires for
    -- some refusals and not others is the trap.
    local ctx = {
        host        = self,
        channelType = channelType,
        target      = target,
        bytes       = type(message) == "string" and #message or 0,
        onComplete  = onComplete,
    }
    local function declined(reason)
        CompleteSend(ctx, "not-attempted", reason)
        return false
    end

    local prefix = self.prefixes[channelType]
    if not prefix then
        self:Debug("ERROR: Unknown channel type: %s", channelType)
        return declined("unknown-channel")
    end
    ctx.prefix = prefix

    -- Use configured distribution/priority if not explicitly provided
    local channelConfig = self.channelConfig[channelType]
    distribution = distribution or (channelConfig and channelConfig.distribution) or "GUILD"
    priority     = priority     or (channelConfig and channelConfig.priority)     or "NORMAL"
    ctx.distribution = distribution

    -- For CHANNEL distribution, use configured channel name if target not provided
    if distribution == "CHANNEL" and not target and channelConfig then
        target = channelConfig.channel
        ctx.target = target
    end

    -- Validate CHANNEL distribution has a target
    if distribution == "CHANNEL" and not target then
        self:Debug("COMMS", "ERROR: CHANNEL distribution requires target channel name")
        return declined("no-channel-target")
    end

    -- Online guard for DIRECTED player sends (optional, requires LibGuildRoster-1.0):
    -- skip only if the roster confirms the target is a known guild member who is
    -- currently offline. Targets not in the roster (cross-realm, non-guild use
    -- cases) return a nil member and are allowed through so the library stays
    -- generic. Applies to WHISPER and to guild-mode's directed GUILD sends (a
    -- GUILD send carries a player target only under guild-mode; a real broadcast
    -- has target == nil) — suppressing a guild-wide broadcast that no online peer
    -- would act on keeps the shared addon channel quiet. CHANNEL's target is a
    -- channel name, not a player, so it's excluded.
    local directedToPlayer = (distribution == "WHISPER") or (distribution == "GUILD" and target ~= nil)
    if directedToPlayer and target and GuildRoster and GuildRoster.GetMember then
        local normTarget = GuildRoster:NormalizeName(target) or self:NormalizeSender(target)
        local entry = normTarget and GuildRoster:GetMember(normTarget)
        if entry and not entry.isOnline then
            self:Debug("COMMS", "SKIP", "Skipping directed send to offline member: %s", target)
            return declined("target-offline")
        end
        -- A SISTER-guild member is not in GetMember's home roster, so without this
        -- every send to one went through unguarded, and a session with a peer who
        -- had logged off kept whispering into "No player named X" (LibGuildRoster,
        -- inbox 69fba6d7). Sister presence is LibGuildRoster's scoped set: the
        -- baton stream, sightings, and the whisper-failure clear. A sister member
        -- not in it is declined -- on an older LibGuildRoster the set is sightings
        -- only and sparse, and declining there is the side the spam concern wants.
        if not entry and normTarget and GuildRoster.IsInAnyRoster and GuildRoster.GetOnlineMembersScoped then
            local key = GuildRoster:IsInAnyRoster(normTarget)
            local homeKey = GuildRoster.GetHomeGuildKey and GuildRoster:GetHomeGuildKey()
            if key and key ~= homeKey then
                local online = false
                for _, name in ipairs(GuildRoster:GetOnlineMembersScoped(key)) do
                    if name == normTarget then online = true break end
                end
                if not online then
                    self:Debug("COMMS", "SKIP", "Skipping directed send to offline sister member: %s (%s)", target, key)
                    return declined("target-offline")
                end
            end
        end
    end

    -- Guild-mode recipient addressing (no-op unless DeltaSyncGuildMode is active).
    -- On servers where whispers don't work, guild-mode flips the directed
    -- channels to GUILD; since a GUILD send hits every guild member, we stamp the
    -- intended recipient onto the message so all other members drop it on receipt
    -- (see DeltaSyncGuildMode.lua / lib:_GuildModeInbound). Only DIRECTED sends
    -- (target ~= nil) routed over GUILD are stamped — genuine broadcasts
    -- (VERSION, DATA, the OFFER hash-list) carry target == nil and are untouched.
    -- Guard target ~= "" too: "" is truthy in Lua, and an empty recipient would
    -- stamp a message no one matches → a silent guild-wide drop.
    if target and target ~= "" and distribution == "GUILD" and self.guildMode and self.guildMode.active then
        message = self.guildMode:Stamp(message, target)
    end
    ctx.bytes = type(message) == "string" and #message or 0

    -- The name the WIRE is addressed to. Every target here is canonical
    -- Name-Realm (MINOR 21), and on WoW: Forever the server refuses a
    -- realm-suffixed whisper target ("No player named 'First Last-Realm' is
    -- currently playing", FastGuildInvite inbox dd611b26). So a WHISPER drops
    -- the realm there, and only there: LibGuildRoster:WhisperTarget, or the
    -- same client switch inline without it. Every other client, and every
    -- non-WHISPER send, is addressed exactly as before. ctx.target keeps the
    -- canonical name, so completions still report the identity callers use.
    local wireTarget = target
    if distribution == "WHISPER" and type(target) == "string" then
        if GuildRoster and GuildRoster.WhisperTarget then
            wireTarget = GuildRoster:WhisperTarget(target)
        elseif RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() == true then
            wireTarget = target:match("^(.-)%-") or target
        end
    end

    -- The CHANNEL transport (SendChatMessage) has no delivery callback at all,
    -- so its completion is the synchronous return read as a verdict, and it is
    -- marked unverified: `true` means the client accepted the call, not that
    -- anyone received the message.
    local function viaChannel()
        local ok = self:SendViaChannel(prefix, message, target)
        if ok then
            CompleteSend(ctx, "delivered", "channel-transport", true)
        else
            CompleteSend(ctx, "refused", "channel-transport", true)
        end
        return ok
    end

    if self.aceAddon and self.aceAddon.SendCommMessage then
        -- Use host addon's embedded AceComm-3.0
        if distribution == "CHANNEL" then
            -- Route through the ChannelModule (SendChatMessage transport).
            -- The body is already serialized by BroadcastData via channelModule.serializer.
            return viaChannel()
        else
            self:Debug("COMMS", "SEND",
                "[PRE-SEND] AceComm %s: prefix='%s' target='%s' priority=%s bytes=%d",
                distribution, prefix, tostring(target), priority, #message)
            -- Arguments 6 and 7 are the delivery callback and its context. See
            -- OnSendResult: without them a refused send is reported by
            -- AceCommQueue through geterrorhandler() and attributed to the comm
            -- layer, so neither DeltaSync nor the host ever learns the message
            -- did not arrive. The completion (CompleteSend) rides the same ctx.
            self.aceAddon:SendCommMessage(prefix, message, distribution, wireTarget, priority,
                OnSendResult, ctx)
            self:Debug("COMMS", "SEND", "[SEND-OK] AceComm prefix='%s' dist=%s bytes=%d",
                prefix, distribution, #message)
        end
    else
        -- Use raw API (no priority support)
        local API = C_ChatInfo or {}
        local SendMsg = API.SendAddonMessage or SendAddonMessage
        if distribution == "CHANNEL" then
            -- Route through the ChannelModule (SendChatMessage transport).
            return viaChannel()
        else
            self:Debug("COMMS", "SEND",
                "[PRE-SEND] Raw %s: prefix='%s' target='%s' bytes=%d",
                distribution, prefix, tostring(target), #message)
            if SendMsg then
                SendMsg(prefix, message, distribution, wireTarget)
                self:Debug("COMMS", "SEND", "[SEND-OK] Raw prefix='%s' dist=%s bytes=%d",
                    prefix, distribution, #message)
                -- No callback exists on this path; the verdict is unverified.
                CompleteSend(ctx, "delivered", "raw-api", true)
            else
                self:Debug("COMMS", "SEND", "[SEND-FAIL] No SendAddonMessage API available")
                return declined("no-send-api")
            end
        end
    end

    return true
end

-- ============================================================================
-- MESSAGE HANDLERS
-- ============================================================================

-- Canonicalise a sender name to "Name-Realm" -- the spelling LibGuildRoster keys
-- its roster by -- so every handler, every consumer callback and every P2P table
-- agrees on one identity per player.
--
-- MINOR 21 (operator directive, 2026-09-20): "we need to use name normalization
-- and send the names with realms, because we should not check if we need to
-- normalize it or not based on the recipient." Before this, a bare same-realm
-- sender reached the consumer callbacks (onDataReceived, onDataRequest,
-- peerCapable, onAdvertised, onNewerOffered) as the client spelled it, while the
-- P2P layers keyed the same player as Name-Realm -- consistent inside a client,
-- but every consumer comparing a callback's sender against roster names had to
-- know which spelling it held. Now nobody downstream has to.
--
-- The client does not document the format of CHAT_MSG_ADDON's `sender`
-- (ChatInfoDocumentation.lua types it only as cstring), so this must accept both
-- spellings: qualified is kept (spaces stripped from the realm), bare gets THIS
-- client's realm appended. Appending the receiver's realm is the right inference
-- here and only here: the transport sender is a name the LOCAL client rendered for
-- this viewer, and the client leaves it bare exactly when the player is on the
-- viewer's own realm. It is NOT right for a name carried inside a payload, which
-- may have been composed on another realm of a connected cluster -- those go
-- through GuildRoster:CanonName, never through this.
--
-- "Foo-Old Blanchy" → "Foo-OldBlanchy"     "Foo" → "Foo-<our realm>"
-- A bare name stays bare only while the realm is unresolved (pre-login window).
-- With LibGuildRoster present this is its NormalizeName, exactly as the P2P layers'
-- Norm() helpers already were; a name it rejects (empty, "-Realm") comes back as
-- given rather than being dressed up with a realm. The inline rules below are the
-- no-LibGuildRoster build only.
function lib:NormalizeSender(name)
    if not name or type(name) ~= "string" then return name end
    if GuildRoster and GuildRoster.NormalizeName then
        return GuildRoster:NormalizeName(name) or name
    end
    local base, realm = name:match("^([^%-]+)%-(.+)$")
    if base and realm then
        return base .. "-" .. realm:gsub("%s+", "")
    end
    local myRealm = GetNormalizedRealmName and GetNormalizedRealmName()
    if (not myRealm or myRealm == "") and GetRealmName then
        myRealm = GetRealmName()
        if myRealm then myRealm = myRealm:gsub("%s+", "") end
    end
    if myRealm and myRealm ~= "" then
        return name .. "-" .. myRealm
    end
    return name
end

--- The inbound boundary: NormalizeSender, plus one fact only a receive knows --
-- the sender is online right now. For a SISTER-guild member that is a first-hand
-- sighting, and it is handed to LibGuildRoster (MarkOnline's array form is
-- exactly "the client just heard from them"). Without it the sister online guard
-- in SendMessage refused to answer a sister peer that had just whispered us
-- (LibGuildRoster, inbox 69fba6d7). Home members are left alone: their presence
-- is the roster scan's. Every OnComm_* handler, OnAddonMessage and the CHANNEL
-- receive path call this first; outbound code calls NormalizeSender.
function lib:_InboundSender(sender)
    sender = self:NormalizeSender(sender)
    if type(sender) == "string" and GuildRoster and GuildRoster.MarkOnline and GuildRoster.IsInAnyRoster then
        local key = GuildRoster:IsInAnyRoster(sender)
        local homeKey = GuildRoster.GetHomeGuildKey and GuildRoster:GetHomeGuildKey()
        if key and key ~= homeKey then GuildRoster:MarkOnline(key, { sender }) end
    end
    return sender
end

-- Guild-mode inbound filter seam (no-op until DeltaSyncGuildMode loads).
-- Run on every inbound message before it reaches its OnComm_ handler. When the
-- guild-mode module is present it inspects the recipient stamp added by Stamp():
--   * stamped for ANOTHER player → returns nil (caller drops it; this is what
--     keeps the shared GUILD addon channel quiet — non-recipients never process
--     the directed traffic that whisper-dead servers force onto GUILD).
--   * stamped for US → returns the inner payload with the stamp stripped.
--   * unstamped (a real broadcast, or a peer not in guild-mode) → unchanged.
-- Gated on module PRESENCE, not the active toggle, so a peer that has guild-mode
-- toggled off still correctly drops/strips stamped traffic addressed elsewhere.
function lib:_GuildModeInbound(message, sender)
    local gm = self.guildMode
    if gm and gm.FilterInbound then
        return gm:FilterInbound(message, sender)
    end
    return message
end

-- Handle raw addon messages (non-AceComm fallback)
function lib:OnAddonMessage(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        "[OnAddonMessage] ENTRY: prefix=%s sender=%s dist=%s bytes=%d",
        tostring(prefix), tostring(sender), tostring(distribution), #message)
    -- Route to appropriate handler based on prefix
    for channelName, channelPrefix in pairs(self.prefixes) do
        if prefix == channelPrefix then
            local handlerName = "OnComm_" .. channelName
            self:Debug("COMMS", "RECEIVE", "[OnAddonMessage] Routing to %s", handlerName)
            if self[handlerName] then
                -- Guild-mode recipient filter (no-op unless DeltaSyncGuildMode loaded).
                local accepted = self:_GuildModeInbound(message, sender)
                if accepted ~= nil then
                    self[handlerName](self, prefix, accepted, distribution, sender)
                end
            end
            return
        end
    end
    self:Debug("COMMS", "RECEIVE", "[OnAddonMessage] No handler for prefix='%s'", tostring(prefix))
end

-- Handle VERSION channel messages (version broadcasts)
function lib:OnComm_VERSION(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        ">>> [OnComm_VERSION] ENTRY prefix=%s dist=%s sender=%s bytes=%d",
        tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)

    -- Ignore own messages
    if sender == self.playerName or sender == self.playerFullName then
        self:Debug("COMMS", "RECEIVE", "[OnComm_VERSION] Ignoring own message (sender=%s)", tostring(sender))
        return
    end

    self:Debug("COMMS", "RECEIVE", "[OnComm_VERSION] Processing from %s (%d bytes)", sender, #message)

    -- Deserialize checksum-wrapped payload (SerializeWithChecksum format).
    -- Falls back gracefully to the old plain "version|hash" wire format for pre-CRC peers.
    local version, hash, hashV2
    local ok, data = self:DeserializeWithChecksum(message)
    if ok and type(data) == "table" then
        version = tonumber(data.version)
        hash    = tonumber(data.hash)
        -- Absent from peers on older builds; nil then, which is exactly the
        -- signal to fall back to the revision-1 comparison.
        hashV2  = tonumber(data.hashV2)
    else
        -- Old-format fallback: plain "version|hash" string
        local vs, hs = string.match(message, "^(%d+)|(%d+)$")
        version = vs and tonumber(vs)
        hash    = hs and tonumber(hs)
    end

    if not version or not hash then
        self:Debug("COMMS", "ERROR: Invalid VERSION message from %s", sender)
        return
    end

    -- Update peer state
    self.peerStates[sender] = {
        version  = version,
        hash     = hash,
        hashV2   = hashV2,   -- nil for peers on pre-MINOR-16 builds
        lastSeen = GetServerTime(),
    }

    -- Notify host addon
    if self.callbacks.onVersionReceived then
        self.callbacks.onVersionReceived(sender, version, hash, hashV2)
    end
end

-- Handle QUERY channel messages (data requests)
function lib:OnComm_QUERY(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        ">>> [OnComm_QUERY] ENTRY prefix=%s dist=%s sender=%s bytes=%d",
        tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)

    -- Ignore own messages
    if sender == self.playerName or sender == self.playerFullName then
        self:Debug("COMMS", "RECEIVE", "[OnComm_QUERY] Ignoring own message (sender=%s)", tostring(sender))
        return
    end

    self:Debug("COMMS", "RECEIVE", "[OnComm_QUERY] Processing from %s", sender)

    -- Parse baseline information from query
    local baseline = self:DeserializeBaseline(message)

    -- Route to a leaf module (e.g. RosterSync) by baseline.type, else the host.
    self:_DispatchRequest(sender, baseline)
end

-- Handle RESPONSE channel messages (query responses)
function lib:OnComm_RESPONSE(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        ">>> [OnComm_RESPONSE] ENTRY prefix=%s dist=%s sender=%s bytes=%d",
        tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)

    -- Ignore own messages
    if sender == self.playerName or sender == self.playerFullName then
        self:Debug("COMMS", "RECEIVE", "[OnComm_RESPONSE] Ignoring own message (sender=%s)", tostring(sender))
        return
    end

    self:Debug("COMMS", "RECEIVE", "[OnComm_RESPONSE] Processing from %s (%d bytes)", sender, #message)

    -- Deserialize data
    local data = self:DeserializeData(message)

    if not data then
        self:Debug("COMMS", "ERROR: Failed to deserialize RESPONSE from %s", sender)
        return
    end

    -- Route to a leaf module (e.g. RosterSync) by data.type, else the host.
    self:_DispatchData(sender, data, #message)
end

-- Handle DATA channel messages (full sync)
function lib:OnComm_DATA(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        ">>> [OnComm_DATA] ENTRY prefix=%s dist=%s sender=%s bytes=%d",
        tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)

    -- Ignore own messages
    if sender == self.playerName or sender == self.playerFullName then
        self:Debug("COMMS", "RECEIVE", "[OnComm_DATA] Ignoring own message (sender=%s)", tostring(sender))
        return
    end

    self:Debug("COMMS", "RECEIVE", "[OnComm_DATA] Processing from %s (%d bytes)", sender, #message)

    -- Full data sync — use compact decoder when ChannelModule is active, CRC decoder otherwise.
    local data
    local cm = self.channelModule
    if distribution == "CHANNEL" and cm and cm.enabled and cm.deserializer then
        data = cm.deserializer(message, sender)
    else
        data = self:DeserializeData(message)
    end

    if not data then
        self:Debug("COMMS", "ERROR: Failed to deserialize DATA from %s (dist=%s)",
            sender, tostring(distribution))
        return
    end

    -- Route to a leaf module (e.g. RosterSync) by data.type, else the host.
    self:_DispatchData(sender, data, #message)
end

-- Handle DELTA channel messages (delta sync)
function lib:OnComm_DELTA(prefix, message, distribution, sender)
    sender = self:_InboundSender(sender)
    self:Debug("COMMS", "RECEIVE",
        ">>> [OnComm_DELTA] ENTRY prefix=%s dist=%s sender=%s bytes=%d",
        tostring(prefix), tostring(distribution), tostring(sender), message and #message or 0)

    -- Ignore own messages
    if sender == self.playerName or sender == self.playerFullName then
        self:Debug("COMMS", "RECEIVE", "[OnComm_DELTA] Ignoring own message (sender=%s)", tostring(sender))
        return
    end

    self:Debug("COMMS", "RECEIVE", "[OnComm_DELTA] Processing from %s (%d bytes)", sender, #message)

    -- Deserialize delta
    local delta = self:DeserializeData(message)

    if not delta then
        self:Debug("DELTA", "ERROR: Failed to deserialize DELTA from %s", sender)
        return
    end

    -- Validate delta structure
    local valid, err = self:ValidateDelta(delta)
    if not valid then
        self:Debug("DELTA", "VALIDATE", "Invalid DELTA from %s: %s", sender, err)
        return
    end

    -- Route to a leaf module (e.g. RosterSync) by delta.type, else the host.
    self:_DispatchData(sender, delta, #message)
end

-- Handle OFFER channel messages (hash-list broadcast OR hash-offer whisper)
-- GUILD distribution: peer is broadcasting their item hashes; if we have newer
--   data for any listed item we send a hash-offer whisper back.
-- WHISPER distribution: peer is offering data for specific items; P2PSession
--   records the offer during the collect window.
function lib:OnComm_OFFER(_, message, distribution, sender)
    sender = self:_InboundSender(sender)
    if sender == self.playerName or sender == self.playerFullName then
        return
    end

    self:Debug("COMMS", "RECEIVE", "Received OFFER from %s (%s, %d bytes)", sender, tostring(distribution), #message)

    local ok, data = self:DeserializeWithChecksum(message)
    if not ok or type(data) ~= "table" then
        self:Debug("COMMS", "ERROR: Invalid OFFER from %s: %s", sender, tostring(data))
        return
    end

    -- The raw inspection hook fires FIRST, before P2P acts on the message. A host
    -- reads what the message carries about its sender here -- an hlb2's `addon`
    -- version is the fallback source for the numbered protocol's peerCapable --
    -- and P2P asks peerCapable while judging the message. Fired after, a peer's
    -- FIRST broadcast was judged with nothing known about it and dispatched to a
    -- release that cannot serve (TOGBank, DS-008 thread, ask 3). A raising hook
    -- is reported and does not stop P2P.
    if self.callbacks.onOfferReceived then
        local okCb, err = pcall(self.callbacks.onOfferReceived, sender, data)
        if not okCb then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
            self:Debug("COMMS", "ERROR: onOfferReceived raised: %s", tostring(err))
        end
    end

    if self.p2p then
        if data.type == "hash-list" and self.p2p.OnHashListReceived then
            -- Peer broadcast their hashes; let P2PSession decide whether to offer data.
            self.p2p:OnHashListReceived(sender, data.items)
        elseif data.type == "hash-offer" and self.p2p.OnHashListReceived then
            -- Peer is offering data; record during collect window.
            self.p2p:OnOffer(sender, data.items)
        elseif data.type == "hlb2" and self.p2p.OnBroadcast then
            -- Numbered protocol (MINOR 18+): a run of <number><canon> entries.
            self.p2p:OnBroadcast(sender, data)
        elseif data.type == "hash-offer2" and self.p2p.OnBroadcast then
            -- Numbered protocol: a run of bare numbers -- "I hold newer for these".
            self.p2p:OnOffer(sender, data)
        end
    end
end

-- Handle HANDSHAKE channel messages (P2P session negotiation)
-- All three subtypes travel on the same whisper prefix:
--   sync-request  (requester → provider): "please send me data for itemKey"
--   sync-accept   (provider → requester): "OK, data incoming"
--   sync-busy     (provider → requester): "at capacity, try another peer"
function lib:OnComm_HANDSHAKE(_, message, _, sender)
    sender = self:_InboundSender(sender)
    if sender == self.playerName or sender == self.playerFullName then
        return
    end

    self:Debug("COMMS", "RECEIVE", "Received HANDSHAKE from %s (%d bytes)", sender, #message)

    local ok, data = self:DeserializeWithChecksum(message)
    if not ok or type(data) ~= "table" then
        self:Debug("COMMS", "ERROR: Invalid HANDSHAKE from %s: %s", sender, tostring(data))
        return
    end

    -- Item-number table sync (DeltaSyncNumbers.lua, MINOR 18+). Routed before the
    -- P2P types because a numbered P2P depends on the table being current.
    if self.numbers then
        if data.type == "numbers-request" then
            self.numbers:HandleRequest(sender)
            return
        elseif data.type == "numbers-reply" then
            self.numbers:HandleReply(sender, data.numbers)
            return
        end
    end

    if self.p2p then
        local p2p = self.p2p
        if data.type == "sync-request" then
            -- The 4th argument (the canon the requester wants) is read only by the
            -- numbered protocol; the hash protocol ignores it.
            p2p:HandleSyncRequest(data.sessionId, sender, data.itemKey, data.canon)
        elseif data.type == "sync-accept" then
            p2p:OnSyncAccept(data.sessionId, sender)
        elseif data.type == "sync-busy" then
            p2p:OnSyncBusy(data.sessionId, sender, data.reason)
        -- Numbered protocol only (MINOR 18+); feature-detected on the instance so
        -- a hash-protocol host ignores traffic it does not speak.
        elseif data.type == "sync-queued" and p2p.OnSyncQueued then
            p2p:OnSyncQueued(data.sessionId, sender, data.position)
        elseif data.type == "sync-cancel" and p2p.OnSyncCancel then
            p2p:OnSyncCancel(data.sessionId, sender)
        elseif data.type == "ver-query" and p2p.HandleVersionQuery then
            p2p:HandleVersionQuery(sender, data.n, data.v)
        elseif data.type == "ver-reply" and p2p.OnVersionReply then
            p2p:OnVersionReply(sender, data.e, data.n, data.v)
        end
    end
end

-- ============================================================================
-- HIGH-LEVEL API
-- ============================================================================

-- Broadcast your current version and hash to the network
-- @param version: numeric version number
-- @param hash: numeric content hash
-- @param distribution: "GUILD", "RAID", "PARTY", "CHANNEL" (optional, uses config if nil)
-- @param priority: "ALERT", "NORMAL", "BULK" (optional, uses config if nil)
-- @param hashV2  optional revision-2 hash (lib:ComputeHashV2). Sent alongside
--   `hash`, never instead of it, so a peer on an older build still reads the
--   revision-1 value it understands. It arrives as the 4th argument to
--   onVersionReceived; compare on it only when BOTH ends have one — the same
--   rule P2PSession applies to the hash list.
function lib:BroadcastVersion(version, hash, distribution, priority, hashV2)
    local message = self:SerializeWithChecksum({
        type = "version", version = version, hash = hash, hashV2 = hashV2 })
    if not message then return false end
    return self:SendMessage("VERSION", message, distribution, nil, priority)
end

-- Request data from a peer
-- @param target: player name
-- @param baseline: your current baseline { version, hash, keys }
-- @param priority: "ALERT", "NORMAL", "BULK" (optional, uses config if nil)
-- @param onComplete: OPTIONAL function(info), MINOR 18+ -- see SendMessage
function lib:RequestData(target, baseline, priority, onComplete)
    local message = self:SerializeBaseline(baseline)
    -- distribution nil → resolve from channelConfig (WHISPER by default; flipped
    -- to GUILD by DeltaSyncGuildMode on servers where whispers don't work).
    return self:SendMessage("QUERY", message, nil, target, priority, onComplete)
end

-- Send data to a peer in response to a request
-- @param target: player name
-- @param data: data structure or delta to send
-- @param isDelta: boolean, true if sending delta instead of full data
-- @param priority: "ALERT", "NORMAL", "BULK" (optional, uses config if nil)
-- @param onComplete: OPTIONAL function(info), MINOR 18+ -- see SendMessage. A
--   P2P provider that took a send slot on accept gives it back HERE, when the
--   reply has drained -- not on SendData's return, which under AceCommQueue is
--   up to ~70s before the last chunk leaves.
function lib:SendData(target, data, isDelta, priority, onComplete)
    local channelType = isDelta and "DELTA" or "RESPONSE"
    local message = self:SerializeData(data)
    -- distribution nil → resolve from channelConfig (see RequestData).
    return self:SendMessage(channelType, message, nil, target, priority, onComplete)
end

-- Broadcast full data to the network.
-- When distribution resolves to CHANNEL and the channel module is enabled with a
-- serializer, uses the compact codec; otherwise uses the CRC-wrapped serializer.
function lib:BroadcastData(data, distribution, priority)
    local channelCfg = self.channelConfig["DATA"]
    local actualDist = distribution or (channelCfg and channelCfg.distribution) or "GUILD"
    local message
    local cm = self.channelModule
    if actualDist == "CHANNEL" and cm and cm.enabled and cm.serializer then
        message = cm.serializer(data)
        if not message then
            self:Debug("COMMS", "SEND",
                "[BroadcastData] channelModule.serializer returned nil for type=%s, dropping",
                tostring(data and data.type))
            return false
        end
    else
        message = self:SerializeData(data)
    end
    local ok = self:SendMessage("DATA", message, distribution, nil, priority)
    -- Second return: serialized payload size (bytes), the same #message metric the
    -- receive path reports as `len`. Additive/backward-compatible — callers that
    -- expect a single boolean are unaffected. Lets a host log accurate send sizes.
    return ok, message and #message or 0
end

-- ── P2P API ──────────────────────────────────────────────────────────────────

-- Broadcast item hashes to the guild, then open the P2P collect window.
-- Peers who have newer data for any listed item will whisper back a hash-offer.
-- @param items     {itemKey → {hash, updatedAt}} — the caller's known item hashes
-- @param priority  "BULK" recommended (large broadcast, not time-critical)
function lib:BroadcastItemHashes(items, priority)
    local message = self:SerializeWithChecksum({ type = "hash-list", items = items })
    if not message then
        self:Debug("COMMS", "ERROR: BroadcastItemHashes — serialization failed")
        return false
    end
    self:Debug("P2P", "OFFER", "Broadcasting hash-list to GUILD (%d bytes)", #message)
    local ok = self:SendMessage("OFFER", message, "GUILD", nil, priority or "BULK")
    if ok and self.p2p then
        self.p2p:BeginCollectWindow(items)
    end
    return ok, #message  -- second return: serialized size (bytes), for host send-logging
end

-- Whisper a hash-offer to a peer who just broadcast their hash-list.
-- Caller (P2PSession:OnHashListReceived in MINOR>=9) selects items where our
-- hash differs from the peer's. updatedAt is included in each entry for
-- backwards compat with older receivers, but is no longer load-bearing for
-- correctness — consumers must merge content-aware on receive.
-- @param target    player name (the broadcaster)
-- @param items     {itemKey → {hash, updatedAt}} — items we can supply
-- @param priority  "NORMAL" (default)
function lib:SendHashOffer(target, items, priority)
    local message = self:SerializeWithChecksum({ type = "hash-offer", items = items })
    if not message then return false end
    self:Debug("P2P", "OFFER", "Whispering hash-offer to %s (%d bytes)", tostring(target), #message)
    -- distribution nil → resolve from channelConfig (see RequestData). The OFFER
    -- *broadcast* (BroadcastItemHashes) still passes "GUILD" with no target, so
    -- only this directed reply is rerouted/stamped under guild-mode.
    return self:SendMessage("OFFER", message, nil, target, priority or "NORMAL")
end

-- Send a P2P handshake message (internal; used by P2PSession).
-- @param target    player name
-- @param payload   table with { type, sessionId, ... }
-- @param priority  "NORMAL" (default)
function lib:SendHandshake(target, payload, priority)
    local message = self:SerializeWithChecksum(payload)
    if not message then return false end
    self:Debug("P2P", "HANDSHAKE", "Whispering handshake(%s) to %s (%d bytes)",
        tostring(payload and payload.type), tostring(target), #message)
    -- distribution nil → resolve from channelConfig (see RequestData).
    return self:SendMessage("HANDSHAKE", message, nil, target, priority or "NORMAL")
end

-- Initialize the P2P session manager.
-- Must be called after lib:Initialize().  Delegates to P2PSession.lua's P2P:Init().
-- @param config  see P2PSession.lua module header for full field list:
--   config.getMyHashes()         → {itemKey → {hash, updatedAt}}
--   config.hasContent(itemKey)   → bool
--   config.hasMissingItems()     → bool
--   config.onSyncAccepted(itemKey, sender)
--   config.isValidPeer(name)     → bool  (optional; defaults to LibGuildRoster:IsInGuild — gated to keep the accept-when-not-in-guild/not-ready behavior — when LibGuildRoster-1.0 is loaded, else accept-all)
--   config.collectWindow         number  (default 10)
--   config.maxActiveSessions     number  (default 3)
--   config.maxActiveSends        number  (default 3)
--   config.retryDelay            number  (default 20)
--   config.catchUpDelay          number  (default 45)
--   config.maxCatchUpCycles      number  (default 5)
--   config.deliveryTimeout       number  (default 180)
function lib:InitP2P(config)
    if not self.p2p then
        error("DeltaSync:InitP2P() — P2PSession module not loaded (P2PSession.lua missing)")
    end
    self.p2p:Init(config)
end

-- ============================================================================
-- SERIALIZATION HELPERS
-- ============================================================================

-- Serialize baseline information for transmission.
-- Uses the same checksum-wrapped AceSer format as all other channels.
-- @param baseline  { hash, version, keys, type, parent }
--   hash, version, keys: legacy fields (default 0/0/{}).
--   type, parent:        v0.2.0 protocol additions for request-shape dispatch
--                        (e.g. type="leaf-data" / type="subhashes" parent=...).
--                        MINOR 10 added end-to-end carriage of these fields;
--                        MINOR<10 silently dropped them.
-- @return  wire-format string, or nil on failure
function lib:SerializeBaseline(baseline)
    local payload = {
        hash    = (baseline and baseline.hash)    or 0,
        version = (baseline and baseline.version) or 0,
        keys    = (baseline and baseline.keys)    or {},
        type    = baseline and baseline.type    or nil,
        parent  = baseline and baseline.parent  or nil,
    }
    return self:SerializeWithChecksum(payload)
end

-- Deserialize baseline information received on the QUERY channel.
-- @param message  wire-format string from SerializeBaseline
-- @return  { hash, version, keys, type, parent } or nil on integrity failure
function lib:DeserializeBaseline(message)
    local ok, payload = self:DeserializeWithChecksum(message)
    if not ok or type(payload) ~= "table" then
        return nil
    end
    return {
        hash    = payload.hash    or 0,
        version = payload.version or 0,
        keys    = payload.keys    or {},
        type    = payload.type,
        parent  = payload.parent,
    }
end

-- Serialize data for transmission
-- Uses checksum-wrapped format for integrity verification
function lib:SerializeData(data)
    return self:SerializeWithChecksum(data)
end

-- Deserialize data from transmission
-- Verifies checksum integrity; returns nil on failure
function lib:DeserializeData(message)
    local ok, result = self:DeserializeWithChecksum(message)
    if not ok then
        return nil
    end
    return result
end

-- ============================================================================
-- CRC / CHECKSUM FRAMEWORK
-- ============================================================================
-- Wire format:  <AceSerialized payload> \030 <checksum> \031END
--
-- Two independent integrity checks run on receive:
--   1. Stop-marker check (O(k)):  was the message fully delivered (not truncated)?
--   2. CRC check (O(N)):          was the message content uncorrupted?
--
-- When both checks disagree (stop present but CRC fails) the message experienced
-- genuine bit-corruption rather than truncation — the O(N) CRC cannot be dropped.

--- Serialize a value and append checksum + stop-marker.
-- @param data  any Lua value
-- @return      wire-format string, or nil on serialization failure
function lib:SerializeWithChecksum(data)
    local serialized = AceSer():Serialize(data)
    if not serialized then
        return nil
    end
    local checksum = ComputeChecksum(serialized)
    self:Debug("SERIALIZE", "SEND bytes=%d checksum=%d", #serialized, checksum)
    return serialized .. CHECKSUM_SEPARATOR .. tostring(checksum) .. STOP_MARKER
end

--- Deserialize a checksum-wrapped message and verify integrity.
-- Falls back gracefully to raw deserialize for pre-CRC (old-format / legacy
-- TOGPM wire format) messages.
-- @param message  wire-format string from the network
-- @param ctx      optional {sender, prefix, distribution} for diagnostics
-- @return         true + value  on success
--                 false + errmsg on structural failure
function lib:DeserializeWithChecksum(message, ctx)
    if not message or type(message) ~= "string" then
        return false, "invalid message"
    end

    -- === Stop-marker check (O(k)) ===
    local stopMarkerLen = #STOP_MARKER
    local stopPresent   = (string.sub(message, -stopMarkerLen) == STOP_MARKER)
    local body          = stopPresent and string.sub(message, 1, #message - stopMarkerLen) or message

    -- === CRC check (O(N)): locate checksum separator from the end ===
    local sepPos  = nil
    local sepByte = string.byte(CHECKSUM_SEPARATOR)
    for i = #body, 1, -1 do
        if string.byte(body, i) == sepByte then
            sepPos = i
            break
        end
    end

    if not sepPos then
        -- Old-format message (no checksum) — fall back gracefully to plain AceSer.
        return AceSer():Deserialize(message)
    end

    local serialized       = string.sub(body, 1, sepPos - 1)
    local checksumStr      = string.sub(body, sepPos + 1)
    local expectedChecksum = tonumber(checksumStr)

    if not expectedChecksum then
        return false, "invalid checksum format"
    end

    local actualChecksum = ComputeChecksum(serialized)
    local crcValid       = (actualChecksum == expectedChecksum)

    -- Log disagreement: stop present but CRC fails = genuine corruption
    if stopPresent and not crcValid then
        local sender = ctx and ctx.sender or "?"
        local pfx    = ctx and ctx.prefix or "?"
        self:Debug("COMMS", string.format(
            "INTEGRITY-MISMATCH stop=PASS crc=FAIL from=%s prefix=%s bytes=%d expected=%d got=%d",
            sender, pfx, #message, expectedChecksum, actualChecksum))
        -- Best-effort: decode the corrupt payload to log its type field.
        local _ok, _decoded = AceSer():Deserialize(serialized)
        local msgType = _ok and (type(_decoded) == "table" and _decoded.type) or "unknown"
        self:Debug("COMMS", "INTEGRITY-MISMATCH PAYLOAD-TYPE '%s'", tostring(msgType))
    end

    if not crcValid then
        return false, string.format("CRC mismatch: expected %d, got %d", expectedChecksum, actualChecksum)
    end

    return AceSer():Deserialize(serialized)
end

-- ============================================================================
-- HASH FUNCTIONS
-- ============================================================================

-- Compute a content hash of any Lua table/value
-- This detects actual content changes, not just timestamp updates
-- @param data: any Lua value (table, string, number, etc.)
-- @return: numeric hash (0 to 2147483647)
-- REVISION 1 — FROZEN. Its output is compared between clients, so the algorithm
-- can never change: an altered v1 would make upgraded peers disagree with
-- un-upgraded ones forever. It has a known type collision (1 vs "1", true vs
-- "true") which is fixed in ComputeHashV2, NOT here. Keep emitting it alongside
-- v2 until no v1-only peers remain — see MakeHashEntry.
function lib:ComputeHash(data)
    if not data then
        return 0
    end

    -- Serialize the data structure to a string
    local serialized = SerializeForHash(data)

    -- Compute checksum of serialized representation
    return ComputeChecksum(serialized)
end

--- Revision 2 content hash — same algorithm, but each scalar carries its type,
-- so a number never collides with its string form (nor a boolean with its name).
-- Prefer this for any NEW comparison. For the P2P hash list use MakeHashEntry,
-- which emits both revisions so mixed-version guilds keep working.
-- @param data  any Lua value
-- @return numeric hash (0 to 2147483647)
function lib:ComputeHashV2(data)
    if not data then
        return 0
    end
    return ComputeChecksum(SerializeForHash(data, nil, true))
end

--- Build one entry for the P2P hash list, carrying BOTH hash revisions.
--
-- This is the recommended way to populate config.getMyHashes():
--
--     getMyHashes = function()
--         local out = {}
--         for key, value in pairs(myData) do
--             out[key] = host:MakeHashEntry(value, value.updatedAt)
--         end
--         return out
--     end
--
-- Emitting both is what makes the revision-2 rollout safe with no coordination:
-- P2PSession compares on the highest revision BOTH ends advertise, so a peer on
-- an older build (which sends only `hash`) still agrees with a peer on a newer
-- one, while two newer peers get the collision-free comparison. An older peer
-- simply ignores the extra field.
--
-- Using this helper also means the eventual retirement of revision 1 costs
-- consumers nothing: when `hash` is dropped, this function changes and their
-- call sites do not.
-- @param data       the value to hash
-- @param updatedAt  the caller's freshness stamp (ordering hint; optional)
-- @return table  { hash = <v1>, hashV2 = <v2>, updatedAt = updatedAt }
function lib:MakeHashEntry(data, updatedAt)
    return {
        hash      = self:ComputeHash(data),
        hashV2    = self:ComputeHashV2(data),
        updatedAt = updatedAt,
    }
end

-- Compute hash for a simple array of items with ID and Count fields
-- This is optimized for common inventory-like structures
-- @param items: array of tables with ID and Count fields
-- @return: numeric hash
function lib:ComputeArrayHash(items)
    if not items or type(items) ~= "table" then
        return 0
    end

    -- Build sorted representation for consistent hashing
    local sorted = {}
    for _, item in ipairs(items) do
        if item and item.ID then
            table.insert(sorted, string.format("%d:%d", item.ID, item.Count or 0))
        end
    end
    table.sort(sorted)

    local combined = table.concat(sorted, ",")
    return ComputeChecksum(combined)
end

-- Compute hash for a structured data object with named sections
-- @param sections: table where keys are section names and values are arrays
--   Example: { bank = {...}, bags = {...}, mail = {...}, money = 1000 }
-- @return: numeric hash
function lib:ComputeStructuredHash(sections)
    if not sections or type(sections) ~= "table" then
        return 0
    end

    local parts = {}

    -- Process each section in sorted order for consistency
    local sortedKeys = {}
    for key in pairs(sections) do
        table.insert(sortedKeys, key)
    end
    table.sort(sortedKeys)

    for _, key in ipairs(sortedKeys) do
        local value = sections[key]
        local valueType = type(value)

        if valueType == "number" then
            -- Simple numeric value
            table.insert(parts, key .. ":" .. tostring(value))
        elseif valueType == "table" then
            -- Array of items - hash them
            local arrayHash = self:ComputeArrayHash(value)
            table.insert(parts, key .. ":" .. tostring(arrayHash))
        end
    end

    local combined = table.concat(parts, "|")
    return ComputeChecksum(combined)
end

-- Get the protocol version.
-- "1.1.0" indicates CRC-wrapped AceSerializer wire format + P2P (OFFER/HANDSHAKE).
-- @return: string version number
function lib:GetProtocolVersion()
    return "1.1.0"
end

-- Print a comprehensive communication status report to the default chat frame.
-- Call this from a slash command to diagnose receive issues.
function lib:DebugStatus()
    local function p(fmt, ...)
        print("|cff00ccff[DeltaSync]|r " .. string.format(fmt, ...))
    end

    p("=== DeltaSync Status ===")
    p("namespace: %s  MINOR=%d", tostring(self.namespace), MINOR)
    p("debugEnabled: %s  logger: %s", tostring(self.debugEnabled),
        self.logger and ("host-injected (" .. type(self.logger) .. ")") or "own (DeltaSync tab)")
    p("playerName: %s  playerFullName: %s",
        tostring(self.playerName), tostring(self.playerFullName))

    -- aceAddon capability
    if self.aceAddon then
        p("aceAddon: present  RegisterComm=%s  SendCommMessage=%s",
            tostring(type(self.aceAddon.RegisterComm)),
            tostring(type(self.aceAddon.SendCommMessage)))
        -- Part of AceCommQueue-1.0's documented contract, not an internal: it
        -- tells us whether our send callback fires once with a whole-message
        -- verdict, or once per chunk. Worth showing because an unqueued host is
        -- also the one at risk of the chunk-interleaving corruption the queue
        -- exists to prevent.
        p("sendQueue: %s", self.aceAddon.__AceCommQueue_embedded
            and "AceCommQueue embedded (one terminal callback)"
            or "|cffff8800NOT queued — host has not embedded AceCommQueue-1.0|r")
    else
        p("|cffff0000aceAddon: NIL — AceComm not available!|r")
    end

    -- Prefixes
    if self.prefixes then
        for name, pfx in pairs(self.prefixes) do
            p("prefix[%s] = '%s'", name, pfx)
        end
    end

    -- Channel config and channel membership
    if self.channelConfig then
        for name, cfg in pairs(self.channelConfig) do
            local extra = ""
            if cfg.distribution == "CHANNEL" and cfg.channel then
                local num = GetChannelName(cfg.channel)
                extra = string.format("  channelNum=%s", tostring(num))
                if not num or num == 0 then
                    extra = extra .. " |cffff0000(NOT JOINED!)|r"
                end
            end
            p("channel[%s]: dist=%s pri=%s ch=%s%s",
                name, tostring(cfg.distribution), tostring(cfg.priority),
                tostring(cfg.channel), extra)
        end
    end

    -- P2P / companions
    p("p2p: %s", self.p2p and "loaded" or "not loaded")
    local grStatus = "not loaded"
    if GuildRoster then
        grStatus = (GuildRoster.IsReady and GuildRoster:IsReady()) and "ready" or "loaded (not ready)"
    end
    p("guildRoster: %s", grStatus)

    -- Delivery verdicts. A non-zero refusal count is the single most useful
    -- line in a "sync isn't working" report: those messages did NOT arrive.
    p("sends: delivered=%d refused=%d not-attempted=%d",
        self.sendsDelivered or 0, self.sendFailures or 0, self.sendsNotAttempted or 0)
    local fail = self.lastSendFailure
    if fail then
        p("|cffff0000last refused send:|r %s (%s) dist=%s target=%s bytes=%d",
            tostring(fail.prefix), tostring(fail.channelType), tostring(fail.distribution),
            tostring(fail.target), fail.bytes or 0)
    end
    -- Usually benign (a host wrapper suppressing on purpose), so it is not
    -- coloured as an error — but a `rejected`/`error` reason here is a defect.
    local skipped = self.lastSendNotAttempted
    if skipped then
        p("last not-attempted send: %s (%s) reason=%s",
            tostring(skipped.prefix), tostring(skipped.channelType),
            tostring(skipped.reason or "not reported"))
    end

    -- commsRegistered flag
    p("commsRegistered: %s", tostring(self.commsRegistered))
    p("snifferFrame: %s", self.snifferFrame and "installed" or "MISSING")
    p("=== End DeltaSync Status ===")
end

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================

--- Register a debug category the HOST owns, so a consumer can route its own
-- output through DeltaSync's debug system instead of building a second one.
--
-- This is the other half of `config.logger`. That one lets a host that already
-- owns a mature output layer take logging over; this one lets a host that does
-- NOT drop its duplicate tab/buffer/registry and adopt the shared one. With ~20
-- consuming addons, one debug system that everybody's traffic lands in is worth
-- more than twenty bespoke ones — support can say "screenshot the DeltaSync
-- tab" and have it mean the same thing everywhere.
--
-- Registered categories behave exactly like the built-in ones (INIT, COMMS,
-- DELTA, P2P, …): same opt-out filtering, same `[CATEGORY.TAG]` prefixing, same
-- SavedVariables persistence.
--
--     host:RegisterDebugCategory("BANK", { SCAN = "bag scans", MAIL = "mail parsing" })
--     host:Debug("BANK", "SCAN", "scanned %d slots", n)
--
-- Per-host, so two consumers never see each other's categories.
-- @param category string  the category name, e.g. "BANK"
-- @param tags     table|nil  optional {TAG = "description"} map for sub-filtering
-- @return boolean success
function lib:RegisterDebugCategory(category, tags)
    if type(category) ~= "string" or category == "" then
        return false
    end
    -- rawget: a NewHost host must not append to the default host's registry.
    local own = rawget(self, "debugCategories")
    if not own then
        own = {}
        self.debugCategories = own
    end
    own[category] = tags or {}
    return true
end

-- Is `name` a category — built in, or registered by this host?
local function HostCategory(host, name)
    if type(name) ~= "string" then return nil end
    if DEBUG_CATEGORY[name] then return DEBUG_TAGS[name] or false end
    local own = rawget(host, "debugCategories")
    if own and own[name] then return own[name] end
    return nil
end

-- Check if a debug category is enabled
function lib:IsCategoryEnabled(category)
    if not self.debugEnabled then
        return false
    end
    -- No SV configured: show everything (opt-out model, no saved state yet)
    if not self.debugSV then
        return true
    end

    local debugData = self.debugSV.deltaSyncDebug
    if not debugData or not debugData.categories then
        return true  -- no per-category settings yet: show all
    end

    -- nil entry = never explicitly set → show by default
    if debugData.categories[category] == nil then
        return true
    end
    return debugData.categories[category] == true
end

-- Enable/disable a debug category
function lib:SetCategoryEnabled(category, enabled)
    if not self.debugSV then
        return
    end

    if not self.debugSV.deltaSyncDebug then
        self.debugSV.deltaSyncDebug = { categories = {}, tags = {} }
    end

    self.debugSV.deltaSyncDebug.categories[category] = enabled
end

-- Check if a debug tag is enabled (opt-out model: nil = enabled)
function lib:IsTagEnabled(category, tag)
    if not self.debugEnabled or not self.debugSV then
        return true
    end

    local debugData = self.debugSV.deltaSyncDebug
    if not debugData or not debugData.tags then
        return true
    end

    local catTags = debugData.tags[category]
    if not catTags then
        return true  -- No per-tag settings for this category
    end

    if catTags[tag] == nil then
        return true  -- Unknown/new tag → show by default
    end

    return catTags[tag] == true
end

-- Enable/disable a debug tag
function lib:SetTagEnabled(category, tag, enabled)
    if not self.debugSV then
        return
    end

    if not self.debugSV.deltaSyncDebug then
        self.debugSV.deltaSyncDebug = { categories = {}, tags = {} }
    end

    local debugData = self.debugSV.deltaSyncDebug
    if not debugData.tags[category] then
        debugData.tags[category] = {}
    end

    debugData.tags[category][tag] = enabled
end

-- Get or create debug chat frame
function lib:GetDebugFrame()
    if self.debugFrame then
        return self.debugFrame
    end

    -- Search for existing frame by name
    local tabName = self.debugAddonName .. " Debug"
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame and frame.name == tabName then
            self.debugFrame = frame
            return frame
        end
    end

    return nil
end

-- Create dedicated debug chat tab
function lib:CreateDebugTab()
    if self.debugFrame then
        return  -- Already created
    end

    local tabName = self.debugAddonName .. " Debug"

    -- Check if tab already exists
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame and frame.name == tabName then
            self.debugFrame = frame
            return
        end
    end

    -- Find first available chat frame slot
    local frameIndex = nil
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame and not frame:IsShown() and frame.name == "" then
            frameIndex = i
            break
        end
    end

    if not frameIndex then
        -- No available slots, use default chat
        return
    end

    local frame = _G["ChatFrame" .. frameIndex]
    if not frame then
        return
    end

    -- Configure the frame
    FCF_SetWindowName(frame, tabName)
    FCF_DockFrame(frame)
    frame:Show()

    self.debugFrame = frame

    -- Hook OnShow to redraw messages when tab becomes visible
    frame:HookScript("OnShow", function()
        self:RedrawDebugMessages()
    end)
end

-- Remove debug chat tab
function lib:RemoveDebugTab()
    local frame = self:GetDebugFrame()
    if not frame then
        return
    end

    -- Clear the frame
    FCF_Close(frame)
    self.debugFrame = nil
end

-- Store debug message in buffer
function lib:BufferDebugMessage(message)
    table.insert(self.debugMessageBuffer, message)

    -- Simple circular buffer: remove oldest if we exceed max
    while #self.debugMessageBuffer > self.maxBufferSize do
        table.remove(self.debugMessageBuffer, 1)
    end
end

-- Redraw all buffered debug messages
function lib:RedrawDebugMessages()
    local frame = self:GetDebugFrame()
    if not frame then
        return
    end

    -- Clear and redraw
    frame:Clear()
    for _, message in ipairs(self.debugMessageBuffer) do
        frame:AddMessage(message)
    end
end

-- Debug logging with category and optional tag support
-- Usage:
--   Debug("CATEGORY", "TAG", "message %s", arg)  -- [CATEGORY.TAG] prefix
--   Debug("CATEGORY", "message %s", arg)         -- [CATEGORY] prefix
--   Debug("message %s", arg)                     -- Simple debug (no category)
-- @param fmt: category string or format string
-- @param ...: tag + format + args, or format + args, or just args
function lib:Debug(fmt, ...)
    -- An injected host logger owns everything: filtering, formatting, buffering
    -- and the chat tab (LIBREQ-DS-003). The RAW arguments are forwarded —
    -- category, tag, format, args — rather than a pre-formatted string, so the
    -- host can apply its own category/tag policy instead of receiving text it
    -- can no longer filter. Accepts a plain function or an object with :Debug,
    -- the latter so a host can pass its existing logger module straight in.
    local logger = self.logger
    if logger then
        if type(logger) == "function" then
            return logger(fmt, ...)
        elseif logger.Debug then
            return logger:Debug(fmt, ...)
        end
        return
    end

    if not self.debugEnabled then
        return
    end

    local prefix, actualFmt, args
    -- Kept for the host tap below, so a host's persistent log can store the
    -- structured category/tag rather than having to re-parse the rendered text.
    local tapCategory, tapTag

    -- Check if first arg is a category — built in, or one this host registered
    -- through RegisterDebugCategory. `categoryTags` is that category's tag map
    -- (possibly empty), or nil when `fmt` is not a category at all.
    local categoryTags = HostCategory(self, fmt)
    if categoryTags ~= nil then
        local category = fmt
        tapCategory = category

        -- Check if category is enabled
        if not self:IsCategoryEnabled(category) then
            return
        end

        local firstArg = select(1, ...)

        -- Check if second arg is a known tag for this category
        if type(firstArg) == "string"
                and categoryTags
                and categoryTags[firstArg] ~= nil then
            local tag = firstArg
            tapTag = tag

            -- Check if tag is enabled
            if not self:IsTagEnabled(category, tag) then
                return
            end

            prefix = string.format("|cff888888[%s.%s]|r", category, tag)
            actualFmt = select(2, ...)
            args = {select(3, ...)}
        else
            -- No tag, just category
            prefix = string.format("|cff888888[%s]|r", category)
            actualFmt = firstArg
            args = {select(2, ...)}
        end
    else
        -- No category, simple debug message
        prefix = string.format("|cff888888[%s]|r", self.namespace)
        actualFmt = fmt
        args = {...}
    end

    -- Format the message
    local message
    if actualFmt and #args > 0 then
        message = string.format("%s %s", prefix, string.format(actualFmt, unpack(args)))
    elseif actualFmt then
        message = string.format("%s %s", prefix, actualFmt)
    else
        message = prefix
    end

    -- Store in buffer
    self:BufferDebugMessage(message)

    -- Host tap (MINOR 16+): hand a copy to the host ALONGSIDE our own tab and
    -- buffer, so a consumer can persist or export the library's diagnostics
    -- without DeltaSync owning retention policy. DeltaSync's buffer is
    -- deliberately session-only and capped at maxBufferSize — a library that
    -- ships in ~20 addons has no business deciding how much of each host's
    -- SavedVariables to spend on a log, or for how long. The host does.
    --
    -- Distinct from config.logger, which REPLACES this whole path.
    local tap = self.onDebugMessage
    if tap then
        local ok, err = pcall(tap, message, tapCategory, tapTag)
        if not ok then
            -- Surfaced, never swallowed — a broken sink is a defect. But it must
            -- not take the library's own logging down with it, which is why the
            -- error is routed rather than propagated.
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
        end
    end

    -- Output to debug frame if available
    local debugFrame = self:GetDebugFrame()
    if debugFrame then
        debugFrame:AddMessage(message)
    else
        -- Fall back to default chat
        print(message)
    end
end

-- ============================================================================
-- CONVENIENCE API (wraps DeltaOperations.lua)
-- ============================================================================

-- Compute delta between old and new data structures
-- @param oldData: previous data state
-- @param newData: current data state
-- @param metadata: optional { version, timestamp, hash }
-- @param options: optional delta options (see ComputeStructuredDelta)
-- @return: delta structure ready for transmission
function lib:ComputeDelta(oldData, newData, metadata, options)
    return self:ComputeStructuredDelta(oldData, newData, metadata, options)
end

-- Apply a received delta to current data
-- @param currentData: your current data state
-- @param delta: delta received from peer
-- @param options: optional apply options (see ApplyStructuredDelta)
-- @return: true if successful, false + error message if failed
function lib:ApplyDelta(currentData, delta, options)
    return self:ApplyStructuredDelta(currentData, delta, options)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get information about auto-generated prefixes for an addon name
-- Useful for debugging and documentation
-- @param addonName: full addon name
-- @return: table with prefix information
function lib:GetPrefixInfo(addonName)
    addonName = addonName or self.namespace
    local shortName = GenerateShortName(addonName)
    local prefixes = GeneratePrefixes(addonName)

    return {
        addonName = addonName,
        shortName = shortName,
        prefixes = prefixes,
        maxLength = MAX_PREFIX_LENGTH,
        usage = {},
    }
end

-- Check if a specific prefix would conflict with existing prefixes
-- @param prefix: prefix to check
-- @return: boolean (true if available, false if conflict)
function lib:IsPrefixAvailable(prefix)
    if not prefix or #prefix > MAX_PREFIX_LENGTH then
        return false
    end

    -- Check against our registered prefixes
    for _, registeredPrefix in pairs(self.prefixes or {}) do
        if registeredPrefix == prefix then
            return false
        end
    end

    return true
end

-- Get current peer states (for debugging)
-- @return: table of peer states
function lib:GetPeerStates()
    return self.peerStates or {}
end

-- Get communication statistics
-- @return: table with stats
function lib:GetCommStats()
    -- peerStates is keyed by sender name, so `#` is always 0 on it; count keys.
    local peerCount = 0
    for _ in pairs(self.peerStates or {}) do peerCount = peerCount + 1 end
    return {
        registered    = self.commsRegistered  or false,
        prefixes      = self.prefixes         or {},
        peerCount     = peerCount,
        useAceComm    = self.aceAddon         ~= nil,
        -- Truthiness, not ~= nil: an un-initialized host carries the `false`
        -- p2p sentinel (see InitHost), which is non-nil but not enabled.
        p2pEnabled    = (self.p2p and true) or false,
    }
end
