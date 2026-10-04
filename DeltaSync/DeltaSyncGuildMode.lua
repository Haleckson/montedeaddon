-- DeltaSyncGuildMode.lua
-- Optional "guild-mode" transport module for DeltaSync-1.0 (MINOR 13+).
--
-- Some servers (notably Whitemane and other private/emulated cores) do NOT
-- deliver addon messages over the WHISPER distribution — CHAT_MSG_ADDON simply
-- never fires for whispers — which silently breaks every DIRECTED DeltaSync
-- channel (QUERY / RESPONSE / DELTA, the directed OFFER reply, HANDSHAKE). The
-- only reliable directed-capable transport left is GUILD, but GUILD is a
-- BROADCAST: a single send reaches every guild member, and that shared addon
-- channel is used by every other addon too, so we must not flood it with traffic
-- that isn't meant for the reader.
--
-- Guild-mode solves this WITHOUT a new prefix and WITHOUT touching the wire
-- format, by:
--   1. Rerouting the five directed channels from WHISPER to GUILD (via
--      SetChannelConfig) when the user opts in.
--   2. Stamping each directed GUILD send with its intended recipient (Stamp).
--   3. Having every receiver drop a message stamped for someone else, and strip
--      the stamp from one addressed to itself (FilterInbound), BEFORE the
--      payload reaches its OnComm_ handler. The net behaviour is identical to a
--      whisper: exactly one peer acts on each directed message.
--
-- DESIGN NOTES:
--   * This is a USER toggle, not server detection. There is no official API that
--     names the server, and maintaining an allowlist of private realms is a
--     losing game — so the player on a whisper-broken realm flips the toggle
--     (the HOST addon owns the settings UI + persistence; this library never
--     ships GUI/SavedVariables/slash commands). Coordinate per guild: on a realm
--     where whispers are dead, everyone enables it.
--   * The recipient stamp is an out-of-band header PREPENDED to the wire message
--     ("\029<recipient>\029<original>"), so it sits entirely outside the
--     existing "<payload>\030<checksum>\031END" envelope and is stripped before
--     any deserialization. \029 (ASCII Unit Separator) never begins an
--     AceSerializer payload, so detection is unambiguous and collision-free.
--   * The stamp can only make non-recipients DROP early; it cannot stop GUILD
--     from delivering the bytes to every member (that is inherent to losing the
--     directed whisper transport). Every member still RECEIVES and fully
--     reassembles a multi-fragment payload before the filter drops it — the drop
--     is post-reassembly (AceComm exposes no per-fragment hook), not free. So the
--     stamp buys correctness (one actor, no N^2 response storms), NOT bandwidth.
--     Hosts should keep directed payloads (esp. DELTA/RESPONSE) small under
--     guild-mode to limit load on the shared addon channel.
--   * The module registers NOTHING and changes NO behaviour until
--     host:InitGuildMode() is called, so a consumer that never opts in (e.g.
--     TOGBankClassic) is byte-identical to a build without this file. The core
--     seams in DeltaSync.lua (SendMessage stamp / lib:_GuildModeInbound) are
--     nil/false-guarded no-ops until this host's guildMode instance exists.
--
-- MULTI-HOST (MINOR 15+): guild-mode is a persistent class (lib._GuildModeClass)
-- and each host owns its own instance at host.guildMode (created by
-- host:InitGuildMode), carrying its own active flag / captured distributions /
-- callbacks and a _host back-reference. Two consuming addons toggle guild-mode
-- independently.

local MAJOR = "DeltaSync-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then
    error("DeltaSyncGuildMode.lua requires DeltaSync.lua to load first (LibStub('DeltaSync-1.0') is nil). Check TOC order.")
end

-- Persistent class table (methods only). Kept on lib across LibStub upgrades so
-- existing host.guildMode instances pick up redefined methods via __index. The
-- live state (active flag, captured distributions, callbacks) lives per-host on
-- the instance and survives independently.
lib._GuildModeClass = lib._GuildModeClass or {}
local GM = lib._GuildModeClass

-- LibGuildRoster-1.0 — the roster engine, used for canonical (realm-qualified)
-- name matching in IsForMe. Soft upvalue resolved at file-load; re-resolved
-- lazily because GuildRoster may load after us. Every use feature-detects.
local GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true)

-- The directed channels: WHISPER by default, rerouted to GUILD under guild-mode.
-- VERSION and DATA are deliberately excluded — they are already legitimate
-- broadcasts and must reach every member unstamped.
local DIRECTED_CHANNELS = { "QUERY", "RESPONSE", "DELTA", "OFFER", "HANDSHAKE" }

-- Address header delimiter. \029 (Unit Separator) is not emitted by
-- AceSerializer and never begins a DeltaSync wire payload, so a message that
-- starts with it is unambiguously guild-mode-addressed.
local ADDR_SEP  = "\029"
local ADDR_BYTE = 29

-- ─── Wire stamping (send side) ───────────────────────────────────────────────

--- Prepend the intended recipient to a directed message bound for GUILD.
-- Called from DeltaSync.lua's SendMessage only when this host's guild-mode is
-- active and the send is directed (target ~= nil, non-empty) over GUILD.
--
-- The target is realm-qualified HERE, at send time, via GuildRoster:NormalizeName
-- (which qualifies a bare "Foo" to the SENDER's realm). For a same-realm target
-- addressed bare — the common case — the sender's realm IS the target's realm, so
-- the stamp becomes fully qualified ("Foo-SenderRealm"). That is what actually
-- disambiguates same-named characters across connected realms: a bare stamp would
-- otherwise be re-qualified to the LOCAL realm by every receiver and match them
-- all. (Receive-side IsForMe is then an idempotent qualified compare.)
-- @param message string  the fully-built wire message (CRC envelope)
-- @param target  string  recipient player name ("Name" or "Name-Realm")
-- @return string  "\029<recipient>\029<message>"
function GM:Stamp(message, target)
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))
    local recipient = (GuildRoster and GuildRoster.NormalizeName and GuildRoster:NormalizeName(target))
        or target or ""
    return ADDR_SEP .. recipient .. ADDR_SEP .. message
end

-- ─── Recipient matching ──────────────────────────────────────────────────────

--- Is `recipient` (a stamped name) addressed to this character?
-- The stamp is already realm-qualified at SEND time (see GM:Stamp), so this is an
-- idempotent qualified compare against our own canonical identity
-- (GuildRoster:GetNormalizedPlayer / host.playerFullName). NormalizeName here only
-- re-canonicalizes (idempotent on an already-qualified name) and covers a peer
-- that somehow stamped bare. The bare host.playerName fallback is a last resort for
-- the pre-login / no-roster window before a realm-qualified identity exists; with
-- a properly qualified stamp it never triggers (qualified ~= bare), so it does NOT
-- reintroduce the cross-realm ambiguity on the normal path.
function GM:IsForMe(recipient)
    if type(recipient) ~= "string" or recipient == "" then return false end
    GuildRoster = GuildRoster or (LibStub and LibStub("LibGuildRoster-1.0", true))
    local host = self._host
    local nr = (GuildRoster and GuildRoster.NormalizeName and GuildRoster:NormalizeName(recipient))
        or (host and host.NormalizeSender and host:NormalizeSender(recipient))
        or recipient
    local me = (GuildRoster and GuildRoster.GetNormalizedPlayer and GuildRoster:GetNormalizedPlayer())
        or (host and host.playerFullName)
    -- Canonical full-name match first; bare playerName is the last-resort fallback
    -- for the pre-login / no-roster window before a realm-qualified identity exists.
    return (me ~= nil and nr == me) or (nr == (host and host.playerName))
end

-- ─── Wire filtering (receive side) ───────────────────────────────────────────

--- Inspect an inbound message's recipient stamp.
-- @return string  the inner payload (stamp stripped) when addressed to us OR the
--                 message unchanged when it carries no stamp (broadcast / a peer
--                 not in guild-mode); nil when stamped for another player (drop).
function GM:FilterInbound(message)
    if type(message) ~= "string" or message:byte(1) ~= ADDR_BYTE then
        return message  -- not guild-mode-addressed → pass through untouched
    end
    local sep2 = message:find(ADDR_SEP, 2, true)
    if not sep2 then
        -- Malformed header; hand it on unchanged so the normal CRC path rejects it.
        return message
    end
    local recipient = message:sub(2, sep2 - 1)
    if self:IsForMe(recipient) then
        return message:sub(sep2 + 1)  -- ours: strip the header, deliver the payload
    end
    return nil  -- someone else's: drop before any deserialization
end

-- ─── Toggle ──────────────────────────────────────────────────────────────────

--- Enable or disable guild-mode for this host at runtime. The HOST settings menu
-- calls this and persists the choice in its own SavedVariables.
-- Enabling captures each directed channel's current distribution (so it can be
-- restored) and reroutes them to GUILD; disabling restores the captured values.
-- @param enabled boolean
-- @return boolean success
function lib:SetGuildMode(enabled)
    local gm = self.guildMode
    if not gm or not gm.initialized then
        self:Debug("COMMS", "SetGuildMode called before InitGuildMode — ignoring")
        return false
    end
    -- channelConfig is built by the host init; SetChannelConfig/GetChannelConfig
    -- below index it. Guard so an out-of-order InitGuildMode({enabled=true}) before
    -- the host is initialized degrades to a no-op instead of erroring on a nil index.
    if not self.channelConfig then
        self:Debug("COMMS", "SetGuildMode called before host init (no channelConfig) — ignoring")
        return false
    end
    enabled = enabled and true or false
    if gm.active == enabled then return true end

    if enabled then
        for _, ch in ipairs(DIRECTED_CHANNELS) do
            local cfg = self:GetChannelConfig(ch)
            gm.savedDist[ch] = (cfg and cfg.distribution) or "WHISPER"
            self:SetChannelConfig(ch, { distribution = "GUILD" })
        end
    else
        for _, ch in ipairs(DIRECTED_CHANNELS) do
            local d = gm.savedDist[ch]
            if d then self:SetChannelConfig(ch, { distribution = d }) end
        end
    end
    gm.active = enabled

    self:Debug("COMMS", "Guild-mode %s — directed channels (%s) now route over %s",
        enabled and "ENABLED" or "DISABLED",
        table.concat(DIRECTED_CHANNELS, ", "),
        enabled and "GUILD (recipient-stamped)" or "their saved distribution")

    if gm.cb.onChanged then gm.cb.onChanged(enabled) end
    return true
end

--- @return boolean  whether guild-mode is currently active for this host.
function lib:IsGuildMode()
    return (self.guildMode and self.guildMode.active) or false
end

-- ─── Init ────────────────────────────────────────────────────────────────────

--- Opt-in initialization for a host. Until this is called, guild-mode is fully
-- inert for that host: the core send/receive seams are no-ops and no channel
-- distribution is touched. Call after creating the host (lib:NewHost) or after
-- lib:Initialize() on the legacy default host.
-- @param config table (all optional)
--   config.enabled    boolean   apply the persisted toggle immediately (the host
--                                reads this from its SavedVariables).
--   config.onChanged  fn(bool)  fired whenever the toggle flips, so the host can
--                                persist the new value / refresh its menu.
-- @return boolean success
function lib:InitGuildMode(config)
    config = config or {}

    -- Per-host instance. rawget so a NewHost host doesn't pick up the legacy
    -- default host's guildMode through __index; mint one bound to this host.
    local gm = rawget(self, "guildMode")
    if not gm then
        gm = setmetatable({ _host = self, cb = {}, savedDist = {}, active = false, initialized = false },
            { __index = GM })
        self.guildMode = gm
    else
        gm._host = self
    end
    gm.cb = gm.cb or {}
    gm.cb.onChanged = config.onChanged
    gm.initialized  = true
    self:Debug("COMMS", "InitGuildMode: ready (currently %s)", gm.active and "ENABLED" or "disabled")
    if config.enabled then
        self:SetGuildMode(true)
    end
    return true
end
