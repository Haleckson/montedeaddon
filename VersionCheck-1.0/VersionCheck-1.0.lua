local MAJOR, MINOR = "VersionCheck-1.0", 17
local VC = LibStub:NewLibrary(MAJOR, MINOR)
if not VC then return end

-- Export our own MINOR onto the library table. LibStub records it in
-- LibStub.minors[MAJOR] and never writes it onto the library, so a consumer
-- holding only the library table had no way to ask what it was running --
-- in a library whose entire job is reporting versions. Both spellings are
-- populated because consumers in the wild read both (Grouper's /grouper libs
-- diagnostic reads .version and .minor and printed "version unknown" on every
-- client, always). Assigned unconditionally on every chunk-load, unlike the
-- frame guards below: this is a plain number derived from the chunk being
-- loaded, so a LibStub upgrade MUST overwrite it or the table would report
-- the version of the copy it replaced.
VC.version = MINOR
VC.minor   = MINOR

-- Debug state lives in the SavedVariable VersionCheck10_DebugEnabled
-- (declared in this addon's TOC for standalone installs; embedded hosts
-- must declare it themselves to get persistence). Read lazily on every
-- access: when both standalone and embedded copies of the library exist
-- and the embedded copy wins LibStub registration first, the standalone
-- chunk that owns the SV declaration never runs past the LibStub guard
-- to populate a cached field. Reading the global at each call site means
-- whichever code path eventually loads the SV file (the standalone
-- addon's own load step) takes effect immediately for all subsequent
-- prints and toggles.
local function isDebug()
    return VersionCheck10_DebugEnabled == true
end

local function VCPrint(msg)
    if isDebug() then
        print("[VersionCheck] " .. tostring(msg))
    end
end

local function SetDebug(value)
    VersionCheck10_DebugEnabled = value and true or false
    print("[VersionCheck] Debugging " .. (VersionCheck10_DebugEnabled and "enabled" or "disabled"))
end

SLASH_VCD1    = "/vcd"
SLASH_VCDON1  = "/vcdon"
SLASH_VCDOFF1 = "/vcdoff"

-- The roster window. `/vc` and `/versioncheck`, registered by the library itself rather than by
-- each host: the window is inherently cross-addon (a tab per registered host) and no single host
-- knows the others exist, so none of them could own this command.
SLASH_VCROSTER1 = "/vc"
SLASH_VCROSTER2 = "/versioncheck"
SLASH_VCROSTER3 = "/vcroster"

SlashCmdList["VCD"]    = function() SetDebug(not isDebug()) end
SlashCmdList["VCDON"]  = function() SetDebug(true) end
SlashCmdList["VCDOFF"] = function() SetDebug(false) end

-- Deferred through VC rather than bound directly, because the window code is defined much later in
-- this file and a slash command registered at load must not capture a nil.
SlashCmdList["VCROSTER"] = function() VC:ToggleRoster() end

-- WoW 11.x moved GetAddOnMetadata into the C_AddOns namespace and removed
-- the bare global. Classic Era picked up the same change, so the global is
-- nil on current clients. Resolve once and shim back to the global on any
-- older client that still has it.
local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata

-- True when the library itself is running from unpackaged source.
local IS_DEV_BUILD = (GetAddOnMetadata and GetAddOnMetadata(MAJOR, "Version") == "VersionCheck-v1.5.3")

-- The ONE way a host's version is resolved, used by every site that needs it: the live addon
-- object's field first (a host can bump it at runtime), then the TOC the packager stamped, then a
-- marker. Nil-guarded because GetAddOnMetadata resolves to nil on a client that has neither
-- spelling, and an unguarded call there is a hard error rather than a missing version.
--
-- This is a single function rather than three copies of the same expression because it was three
-- copies and they diverged: HandleRequest skipped the TOC fallback, so a host registered by NAME
-- (VC:Enable("MyAddon"), which has no addon object) advertised its real version in its own request
-- and answered "unknown" to everyone else's. "unknown" carries no digits, so CompareVersion sorts
-- it below every real version — those hosts could never be the highest version anyone saw, and
-- nobody was ever told to update because of them.
-- declaredVersion sits between the two: a host that registered by NAME through RegisterCheck told
-- us its version outright, which beats reading a TOC (an embedded host's own TOC may not even name
-- it), but it must NOT beat the live addon object, whose field a host can bump at runtime.
local function HostVersion(hostEntry)
    return (hostEntry.host and hostEntry.host.Version)
        or hostEntry.declaredVersion
        or (GetAddOnMetadata and GetAddOnMetadata(hostEntry.addonName, "Version"))
        or "unknown"
end

-- Two fixed library-level prefixes shared by ALL host addons.
-- This stays within Blizzard's hard cap of 8 registered prefixes per session
-- regardless of how many addons embed this library.
local LIBRARY_REQ_PREFIX = "VC10_REQ"
local LIBRARY_RSP_PREFIX = "VC10_RSP"

local AceComm       = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Callbacks, so a UI can fill in live instead of polling this library or waiting for a terminal
-- result. CallbackHandler-1.0 ships with Ace3 and AceComm already depends on it, so this adds no
-- dependency; it is also the idiom LibGuildRoster uses, and a consumer wiring both should not have
-- to learn two.
--
-- `or CBH:New(VC)` for the same reason as the frame guards below: LibStub preserves the VC table
-- across an upgrade and re-runs this chunk, and a fresh registry would silently drop every
-- consumer's registration.
local CBH = LibStub("CallbackHandler-1.0")
VC.callbacks = VC.callbacks or CBH:New(VC)

-- Per-host state, keyed by addon name.
VC.hosts = VC.hosts or {}

-- Library-level state.
VC.commRegistered  = VC.commRegistered  or false
VC.batchFired      = VC.batchFired      or false
VC.collectionTimer = VC.collectionTimer or nil

-- GreenWall optional-transport state.
VC.gwHandlerId      = VC.gwHandlerId      or nil
VC.gwHookInstalled  = VC.gwHookInstalled  or false
VC.gwPendingPayload = VC.gwPendingPayload or nil   -- set by FireBatch, drained by ChatEdit_ParseText hook
VC.gwReqSeen        = VC.gwReqSeen        or {}    -- senderKey -> expiry GetTime() for REQ dedup

-- Registered-with-LibGuildRoster guard. Survives a LibStub upgrade like the frame guards, because
-- re-registering would fan every roster event to a consumer twice.
VC.rosterHooked = VC.rosterHooked or false
VC.requiredLibsReported = VC.requiredLibsReported or false

local GW_REQ_DEDUP_TTL = 20   -- seconds

-- The key the refresh button's cooldown is filed under. NAMESPACED with MAJOR deliberately:
-- LibAceGUIWidgets keeps every named cooldown in one library-wide table shared by every addon that
-- uses it, so a bare "refresh" would have this button and some other addon's counting each other
-- down.
local REFRESH_COOLDOWN = MAJOR .. ":refresh"

-- LibGuildRoster, resolved lazily and cached ONLY ON A HIT.
--
-- Caching a miss is the defect LibAceGUIWidgets found in its own copy of this idiom and removed on
-- 2026-09-10: `x = LibStub(major, true) or false` never re-resolves, because `false` is not `nil`.
-- The first caller to look before the library has loaded freezes the miss for the whole session,
-- and the symptom is a silently missing feature nobody attributes to load order. A miss here costs
-- one table index on the next call, which is not worth a permanent wrong answer.
--
-- Lazy rather than a file-scope upvalue because an EMBEDDED copy of this library runs inside a host
-- whose own TOC we do not control -- our `## OptionalDeps:` line guarantees load order for the
-- standalone addon only.
local GuildRoster
local function Roster()
    if not GuildRoster then
        GuildRoster = LibStub and LibStub("LibGuildRoster-1.0", true) or nil
    end
    return GuildRoster
end

-- The two required libraries, checked HERE because the TOC alone does not cover every install.
--
-- The standalone TOC hard-requires LibAceGUIWidgets, so the client flags THAT absence itself and
-- this library never runs. But GuildRoster is `## OptionalDeps:` (it hard-depends on us, and a hard
-- dependency both ways is a cycle), so the client never says a word when it is missing -- and an
-- EMBEDDED copy of this library runs inside a host whose TOC may require neither. In both cases the
-- CurseForge relation is the only thing installing them, and it is not reliable -- the user,
-- 2026-09-20: "CF shits the bed on this all the time" -- so a player could end up with a roster
-- window that silently never works and no idea why, because the one message that said so was
-- printed only when they typed /vc. So at PLAYER_ENTERING_WORLD -- after every addon has loaded,
-- which is the first moment a miss means "not installed" rather than "not yet" -- each missing
-- library gets one plain line in chat naming it, what it costs, and what to do. Once per session;
-- NOT gated on debug, and NOT on the dev-build sentinel, because a missing dependency is exactly
-- what an author running from source wants to see first.
function VC:ReportMissingLibraries()
    if VC.requiredLibsReported then return nil end
    VC.requiredLibsReported = true

    local missing = {}
    local W = LibStub and LibStub("LibAceGUIWidgets-1.0", true) or nil
    if not W then
        missing[#missing + 1] = "LibAceGUIWidgets is not installed or not loaded.|r VersionCheck requires it: "
            .. "the roster window (/vc) cannot open without it. Install LibAceGUIWidgets from CurseForge "
            .. "and make sure it is enabled in the AddOns list."
    elseif not W.RowList then
        missing[#missing + 1] = "LibAceGUIWidgets is too old for VersionCheck.|r The roster window (/vc) "
            .. "needs its RowList. Update LibAceGUIWidgets from CurseForge."
    end
    if not Roster() then
        missing[#missing + 1] = "GuildRoster (LibGuildRoster) is not installed or not loaded.|r VersionCheck "
            .. "requires it: without it the roster window lists only players who have answered, with no "
            .. "ranks or class colours. Install GuildRoster from CurseForge and make sure it is enabled "
            .. "in the AddOns list."
    end

    for _, line in ipairs(missing) do
        print("[VersionCheck] |cffff2020" .. line)
    end
    return #missing
end

-- WoW Forever's REGIONAL UNIQUE NAMES. A character there is "First Last", unique across the region,
-- with no realm: UnitName returns (first, surname), AceComm's sender still carries an internal realm
-- ("First Last-Realm"), and a WHISPER to that realm-suffixed form fails with "No player named ... is
-- currently playing" while the player is online (FastGuildInvite, thread 833800a6, 2026-09-29). So on
-- Forever the identity AND the whisper target are the full name with any realm suffix dropped.
--
-- Read from the client's own switch, never a flavour check: `RegionalUniqueNamesEnabled` is what
-- Blizzard's UI branches on (wow-ui-source-forever NameUtil.lua:46, UnitPopupUtils.lua:128), and it
-- is absent -- so false -- on every other client, which stays on the Name-Realm path unchanged. The
-- same rule as LibGuildRoster's RegionalNames/CanonName; done here too because an embedder can hand
-- us an older roster library that predates it.
local function RegionalNames()
    return RegionalUniqueNamesEnabled ~= nil and RegionalUniqueNamesEnabled() == true
end

-- The engine owns the first-name/surname separator (Constants.CharacterNameSeparatorConsts); " " is
-- LibGuildRoster's fallback without it.
local function SurnameSeparator()
    local consts = Constants and Constants.CharacterNameSeparatorConsts
    local sep = consts and consts.CHARACTERNAME_SURNAME_SEPARATOR
    if type(sep) == "string" and sep ~= "" then return sep end
    return " "
end

-- "First Last-Realm" -> "First Last". Left alone if the client ever separates the surname with a
-- hyphen, where the cut would eat the surname (LibGuildRoster keeps the same guard).
local function DropRealm(name)
    if SurnameSeparator() == "-" then return name end
    return (name:gsub("%-.*$", ""))
end

-- THE one way a player name becomes a key. Every store in this file is keyed on its output.
--
-- `CanonName` is the wire-side function and this library is entirely a wire consumer: version
-- reports arrive over AceComm and GreenWall. Its sibling `NormalizeName` appends OUR OWN realm to a
-- bare name, which is right for a name read from a local client API and catastrophic here -- every
-- client in a connected-realm cluster would key the same peer differently, with no way back.
-- CanonName is pure: no realm lookup, no cache, no state, identical on every client and across
-- sister rosters, which is what makes it safe to key on and to persist. (LibGuildRoster's own
-- answer, 2026-09-10: "the sender qualifies, the receiver canonicalizes".)
--
-- Feature-detected on the METHOD, not the library: LibStub keeps only the highest MINOR, so a host
-- embedding an older copy can hand us a table without it. Falling back to the raw name is
-- deliberate and is NOT a second identity model -- it is the same string, uncleaned. What it is
-- explicitly not is a re-introduction of the old realm-stripping heuristic, which collapsed two
-- different characters who happened to share a base name.
local function PeerKey(name)
    if not name or name == "" then return "" end
    local GR = Roster()
    local key = name
    if GR and GR.CanonName then
        key = GR:CanonName(name) or name
    end
    -- Forever: after the library, not instead of it -- a roster copy older than its own Forever
    -- support returns the realm-suffixed form, and dropping it again is a no-op for a newer one.
    if RegionalNames() then key = DropRealm(key) end
    return key
end

-- Everything we have OBSERVED about other players' addon versions, keyed by the sender string as it
-- arrived: VC.peerVersions[sender][addonName] = { version, at, via }.
--
-- A superset of any single host's VersionResponses. It records addons we do NOT have installed, and
-- it accumulates for the whole session instead of being emptied by every FireBatch, so it is the
-- table a roster view reads.
--
-- IT COSTS NO TRAFFIC, which is the entire reason it can exist. Every REQ is already broadcast to
-- the whole guild carrying the sender's complete addon-and-version list, and HandleRequest used to
-- iterate it as `for addonName in pairs(batch)` -- key only -- discarding the versions at the
-- language level. Recording them is pure listening: no extra message is sent, and a guildmate who
-- logs in an hour from now announces themselves to us by doing nothing but logging in.
VC.peerVersions = VC.peerVersions or {}

-- Keys beginning with "__" are RESERVED for protocol control fields and are never addon names.
--
-- Nothing sends one yet. This exists so that something CAN, later, without breaking any copy of the
-- library already in the wild -- and it has to land in the same release as harvesting or it is too
-- late. The REQ payload is a flat addonName -> version map, so the only way to add a control field
-- compatibly is to put it in that map and rely on every reader ignoring it:
--
--   * A copy at MINOR 12 or earlier ignores it already. It looks the key up in VC.hosts, finds
--     nothing, and neither replies about it nor records it. Nothing to do for those.
--   * A copy at MINOR 13 HARVESTS every key it receives. Without this guard, the day any future
--     version introduces a control field, every MINOR 13 client in every guild would start showing
--     a phantom addon named after it -- in a roster window whose whole job is to be trustworthy.
--
-- Filtering on receive rather than on send is deliberate: it protects clients that will never be
-- upgraded from a decision that has not been made yet. Enable() is left alone, so a host that
-- somehow registers such a name still works locally; peers simply will not harvest it.
local function IsReservedKey(name)
    return name:sub(1, 2) == "__"
end

-- The two control fields that reservation exists for.
--
-- PROTOCOL_KEY is how a responder tells a NEW asker from an OLD one, and that distinction is the
-- whole reason this is safe. A copy at MINOR 12 or 13 never sends it, so its absence means "this
-- peer cannot ask for a resync and has no memory I can rely on" -- answer in full, exactly as
-- before. Without it, "asker already knows" and "asker is too old to say" are indistinguishable,
-- and suppressing the second breaks the version check for every older client in the guild.
--
-- RESYNC_KEY is a new asker saying "I have nothing, send me everything." VC.peerVersions is
-- in-memory, so a session that has just started, or one that has been reloaded, knows nothing and
-- must say so or be met with silence.
local PROTOCOL_KEY     = "__v"
local RESYNC_KEY       = "__resync"
local FROM_KEY         = "__from"
local PROTOCOL_VERSION = "1"

-- PUSH_KEY is guild leadership saying "decide NOW". A peer already harvests every version a REQ
-- carries, but it only DECIDES -- compares, and pops the update popup -- when its own collection
-- window closes, which is at its own login or when one of its hosts re-triggers a batch. So an
-- officer's ordinary refresh cannot make an out-of-date guildmate see anything until that
-- guildmate's next batch. A REQ carrying this key asks the receiver to run the same decision on
-- receipt: same comparison, same lastShown dedup, same dev-build suppression, same combat deferral.
-- No new popup path exists; this only changes WHEN the existing one runs.
--
-- Backwards compatible for the same reason FROM_KEY is: a peer at MINOR 12 looks the key up in its
-- hosts table, finds nothing, and ignores it. It simply answers as it always has and decides at its
-- own next window -- no worse than before, and exactly what it did before this key existed.
local PUSH_KEY         = "__push"

-- ALL_KEY is a request that could not carry the sender's inventory saying "answer about EVERYTHING
-- you have, not just what I named". It exists for the GreenWall leg, which is one chat-channel
-- message of at most 255 characters and cannot hold a full batch (see GW_PAYLOAD_BUDGET); the
-- broadcast there is a TRIGGER whose only job is to elicit whisper replies -- the user's words,
-- 2026-09-15: "the broadcast doesn't need to be comprehensive, you just need to elicit whisper
-- responses". A receiver at MINOR 14+ answers with every host it has; a receiver at MINOR 13 or
-- earlier ignores the key and answers the intersection with whatever names the trigger did carry,
-- exactly as it always has -- which is why the trigger still carries as many names as fit.
local ALL_KEY          = "__all"

-- Our own realm-qualified name, for FROM_KEY.
--
-- This is the "sender qualifies" half of LibGuildRoster's rule, and without it the receiver half is
-- not merely incomplete, it REGRESSES: CanonName is pure, so a bare "Bob" from GreenWall and
-- "Bob-Whitemane" from AceComm canonicalize to two different keys and become two roster rows for
-- one person. The sender is the only party that knows its own realm, so it is the only party that
-- can settle this.
local function SelfName()
    -- Forever: the full name, no realm. Built here rather than asked of the roster library, whose
    -- older copies answer "First-Realm" -- the first name alone with an internal realm, which is
    -- nobody's name.
    if RegionalNames() then
        if not UnitName then return nil end
        local first, surname = UnitName("player")
        if not first or first == "" then return nil end
        if surname and surname ~= "" then return first .. SurnameSeparator() .. surname end
        return first
    end
    local GR = Roster()
    if GR and GR.GetNormalizedPlayer then
        local name = GR:GetNormalizedPlayer()
        if name and name ~= "" then return name end
    end
    -- No roster library: build the same shape by hand rather than sending a bare name, which is the
    -- ambiguity this field exists to remove. The realm can be empty very early in login.
    --
    -- NORMALIZED, never GetRealmName: that keeps the space ("Old Blanchy"), while the client spells
    -- every Name-Realm it hands out -- AceComm senders, the unit popup, LibGuildRoster's keys --
    -- with the normalized form ("OldBlanchy"). Measured on Old Blanchy by the operator, 2026-09-20.
    local me    = UnitName and UnitName("player")
    local realm = GetNormalizedRealmName()
    if me and me ~= "" and realm and realm ~= "" then
        return me .. "-" .. realm
    end
    return nil
end

-- A WHISPER target must be realm-qualified or the client sends it to nobody on a connected realm.
-- The one place a bare name gains OUR realm, and it is the right realm to add: a bare name here
-- came from a same-realm source -- AceComm's sender string, or a name a consumer read off /who.
-- (Not PeerKey, which is pure by design and never adds a realm; see the note on it above.)
local function QualifyName(name)
    -- Forever: the opposite. The server refuses a realm-suffixed whisper target, so the realm goes.
    if RegionalNames() then return DropRealm(name) end
    if not name:find("-") then
        -- The realm can be empty very early in login. A bare name then stays bare rather than
        -- becoming "Bob-" -- the same shape the transport gave us, which a same-realm whisper still
        -- reaches. Normalized for the reason given at SelfName: "Bob-Old Blanchy" is not a name
        -- the client ever produces.
        local realm = GetNormalizedRealmName()
        if realm and realm ~= "" then
            return name .. "-" .. realm
        end
    end
    return name
end

-- WHO a message is from, as a store key: the name the sender qualified for us (FROM_KEY) when it
-- sent one, otherwise the transport's sender string qualified with our realm.
--
-- The fallback qualifies rather than keying the raw string because a BARE sender is never
-- ambiguous about its realm. AceComm hands every sender through `Ambiguate(sender, "none")`, which
-- strips the realm exactly when it is our own (AceComm-3.0.lua; the harness models the documented
-- context table); GreenWall's `gw.GlobalName` (Utility.lua:136) appends the local realm to a bare
-- name before its handlers ever see it, so nothing bare arrives on that leg at all. So a bare name
-- here means "on our realm", the same inference QualifyName already makes for the whisper target.
--
-- Keying it bare split one guildmate into two roster rows: LibGuildRoster's GetAllMembers is
-- Name-Realm, a MINOR 12 peer on our realm arrived as "Bob", and the two never merged -- their
-- row stayed "Not seen" with a second "Bob" row beside it carrying the version. The suite could
-- not see it until the harness delivered same-realm senders bare, as the client does (harness
-- Adoption log, 2026-09-16). It only ever affected peers too old to send FROM_KEY; everyone else
-- was already exact.
--
-- Forever inverts the preference. The transport's sender is the full name there (with a realm that
-- PeerKey drops), while `__from` from a copy older than MINOR 17 is "First-Realm" -- the first name
-- without its surname -- which would key the player as somebody else. Nothing about a realm needs
-- settling on Forever, which is the only reason `__from` is preferred anywhere else.
local function TransportIdentity(from, sender)
    if RegionalNames() and sender and sender ~= "" then return PeerKey(sender) end
    return PeerKey(from or QualifyName(sender))
end

-- THE request payload -- every registered host's version, then the control fields -- built in one
-- place so the GUILD broadcast and the targeted WHISPER can never carry different shapes. A receiver
-- at any MINOR reads both through the same HandleRequest, and a shape that only the broadcast had
-- would be a request some copies answer and others do not.
--
-- Returns the batch and the host count. The control fields are added only when there is at least
-- one host, so they can never make an empty batch look non-empty.
--
--   opts.resync  -- "I have nothing, send me everything" (RESYNC_KEY)
--   opts.push    -- "decide NOW" (PUSH_KEY); leadership only, at the UI
local function BuildRequest(opts)
    local batch, count = {}, 0
    for addonName, hostEntry in pairs(VC.hosts) do
        batch[addonName] = HostVersion(hostEntry)
        count = count + 1
    end
    if count == 0 then return batch, 0 end

    batch[PROTOCOL_KEY] = PROTOCOL_VERSION

    -- Who we are, realm-qualified. The receiver keys its store on this rather than on whatever
    -- shape the transport handed it, so one player reaching a peer over both AceComm and GreenWall
    -- is one row rather than two. Omitted rather than guessed if the realm has not resolved yet.
    local me = SelfName()
    if me then batch[FROM_KEY] = me end

    -- Strings, not booleans, like every other control field: the one shape every copy of the
    -- serializer on the wire has always carried.
    if opts.resync then batch[RESYNC_KEY] = "1" end
    if opts.push   then batch[PUSH_KEY]   = "1" end
    return batch, count
end

-- How many bytes of OUR payload the GreenWall leg can carry. MEASURED against GreenWall's source,
-- not guessed: Channel.lua:322 builds `E#<guild id>##VersionCheck-1.0:<base64 of our payload>` and
-- cuts the segment at GW_MAX_MESSAGE_LENGTH = 255 with `strsub` -- no chunking, no reassembly on
-- the far side. The envelope is 21 characters plus the guild id, base64 is 4 characters per 3
-- bytes, and the id is not readable through GreenWallAPI, so this leaves room for one up to 32
-- characters: 255 - 21 - 32 = 202 characters of base64 = 151 bytes, rounded down to a whole group.
--
-- Found by LibGuildRoster on 2026-09-15 (inbox thread 73cb2669): with the user's 17 hosts the full
-- batch is 444 bytes -- 592 in base64 -- and every login broadcast on the GreenWall leg had been
-- truncated, failed to deserialize on arrival, and been answered by nobody, while stamping the
-- receiver's dedup clock on the way. The confederation reach this file describes was dead for any
-- player with more than a handful of hosts, and nothing said so.
local GW_PAYLOAD_BUDGET = 150

local function FitsGreenWall(batch)
    return #AceSerializer:Serialize(batch) <= GW_PAYLOAD_BUDGET
end

-- The GreenWall leg of a request: the control fields, ALL_KEY, and as many hosts as still fit --
-- in name order, so which ones ride along is the same on every login rather than whatever `pairs`
-- produced. A receiver at MINOR 14+ answers about everything it has because of ALL_KEY; an older
-- one answers about the names that fit, which is what it would have done with a full batch that
-- arrived intact, and more than it did with one that never arrived at all.
local function GreenWallTrigger(batch)
    local trigger = {}
    local names   = {}
    for key, value in pairs(batch) do
        if IsReservedKey(key) then
            trigger[key] = value
        else
            names[#names + 1] = key
        end
    end
    trigger[ALL_KEY] = "1"

    table.sort(names)
    for _, name in ipairs(names) do
        trigger[name] = batch[name]
        if not FitsGreenWall(trigger) then
            trigger[name] = nil
            break
        end
    end
    return trigger
end

-- One broadcast, both transports. `batch` goes out by AceComm GUILD now; `gwBatch` is parked for
-- the GreenWall leg, which the ChatEdit_ParseText hook installed at PEW flushes from inside the
-- user's next chat keystroke -- the hardware-event scope GreenWall's own SendChatMessage needs.
-- Until the user types, it waits here; if they never type that session, no confederation reach
-- (acceptable) and the AceComm leg is unaffected. The two payloads differ on purpose: GreenWall
-- cannot carry a full batch (GW_PAYLOAD_BUDGET), so FireBatch hands it a trigger.
--
-- Stamps VC.lastBatchAt on EVERY broadcast, not just manual ones, because the thing being
-- rate-limited is what our PEERS will suppress: their gwReqSeen entry is keyed on us and does not
-- care why we sent. A refresh 3 seconds after the login batch would be answered by nobody.
local function SendRequest(batch, gwBatch)
    VC.lastBatchAt = GetTime()

    AceComm:SendCommMessage(LIBRARY_REQ_PREFIX, AceSerializer:Serialize(batch), "GUILD")
    VCPrint("SendRequest: AceComm GUILD sent.")

    if GreenWallAPI then
        VC.gwPendingPayload = AceSerializer:Serialize(gwBatch)
        VCPrint("SendRequest: GreenWall payload parked, awaiting next chat input for HW-scope send.")
    else
        VC.gwPendingPayload = nil
        VCPrint("GreenWall not detected; using AceComm GUILD only.")
    end
end

-- What we have already told each peer: sender -> { [addonName] = version we last sent them }.
-- Session-scoped and deliberately not persisted -- forgetting makes us answer again, which is the
-- safe direction to fail in.
VC.toldPeers = VC.toldPeers or {}

-- Keyed by the RAW sender on purpose. Collapsing "Bob" and "Bob-Whitemane" needs a real identity
-- model rather than a second heuristic -- GW_SameSender below is deliberately narrow and lossy, and
-- exists for transport dedup, not identity. LibGuildRoster's CanonName is the intended source of
-- truth and will rekey this table once, in one place. Storing a lossy key here now would only have
-- to be undone then.
function VC:RecordPeerVersion(sender, addonName, version, via)
    if not sender or sender == "" then return end
    if not addonName or not version then return end
    if IsReservedKey(addonName) then return end

    -- Canonicalized here rather than at each call site, so there is exactly one place a wire name
    -- becomes a key and no caller can forget.
    sender = PeerKey(sender)
    if sender == "" then return end

    local seen = VC.peerVersions[sender]
    if not seen then
        seen = {}
        VC.peerVersions[sender] = seen
    end

    -- `changed` is the argument a consumer actually wants. Re-hearing the same version from a
    -- player who logs in twice is the ordinary case and should not repaint a row or move it to the
    -- top of anything; an actual version change is the event worth reacting to.
    local previous = seen[addonName]
    local changed  = (previous == nil) or (previous.version ~= version)

    seen[addonName] = { version = version, at = GetTime(), via = via }
    -- Repaint an open window, then tell consumers. Direct rather than through our own callback
    -- registry, for the target-collision reason documented in HookRoster. Costs nothing when no
    -- window is open, and sends nothing either way.
    VC:RefreshRoster()
    VC.callbacks:Fire("OnPeerVersion", sender, addonName, version, via, changed)
    return seen[addonName]
end

-- Every observation, or just those for one addon (sender -> observation). Returns the live table
-- when called with no argument; callers must not mutate it.
function VC:GetPeerVersions(addonName)
    if not addonName then return VC.peerVersions end
    local out = {}
    for sender, addons in pairs(VC.peerVersions) do
        if addons[addonName] then out[sender] = addons[addonName] end
    end
    return out
end

-- Rank and class for a player who is not in OUR guild but is in a sister roster LibGuildRoster
-- holds -- a GreenWall confederation member, typically. GetAllMembers and GetMember are home-only,
-- so a sister member reaches the rows only through what we have heard, and until this existed
-- their row carried a version and a BLANK rank beside home members with ranks (the user's
-- screenshot of 2026-09-16; GuildRoster thread befd118e, which added rankName/rankIndex to the
-- sister sync in its 0.8.2 / MINOR 21 for exactly this).
--
-- Feature-detected per METHOD, like everything else asked of that library: an older copy has no
-- IsInAnyRoster, and a sister fed by a provider on 0.8.1 or earlier carries no rankName -- blank,
-- exactly as before. `guild` is carried because a sister "Officer" is not our officer, and a view
-- that wants to say so needs to know whose. Nothing here sends anything.
local function FillFromSisterRoster(GR, entry)
    if not (GR and GR.IsInAnyRoster and GR.GetRoster) then return end
    local key    = GR:IsInAnyRoster(entry.name)
    local roster = key and GR:GetRoster(key)
    if not roster then return end
    local member = roster[(GR.NormalizeName and GR:NormalizeName(entry.name)) or entry.name]
    if not member then return end
    entry.rank      = member.rankName
    entry.rankIndex = member.rankIndex
    entry.classFile = member.class
    entry.guild     = member.guild or key
end

-- One row per player for one addon: what a roster view renders, sorted by name so the order is
-- stable across sessions (`pairs` order is not).
--
-- Rows carry a `state`, and the four values are the whole point of this function. A version checker
-- that cannot separate them lies: RCLootCouncil's window collapses everything without a version
-- into one "Not installed ?", which reads as fact and is a guess.
--
--   reported      we have a version for them, from `via` at `at`
--   silent        in the guild, ONLINE, and has never reported -- probably has not got the addon,
--                 but that is an inference and the UI should render it as one
--   offline       in the guild, offline, never reported -- says nothing either way
--   unknown       not in the roster at all: a GreenWall confederation peer, someone who has left
--                 the guild, or the roster library not being present
--
-- `account` is the alt-grouping key: a version check is really about whether a PERSON has the
-- build, and an alt answering proves the account has it. Supplied rather than acted on, so the view
-- decides whether to collapse -- this library has no business deciding presentation.
--
-- The roster is read here and NOWHERE in the popup path. A guildless player must still be told they
-- are out of date, and there is a spec pinning that.
function VC:GetRoster(addonName)
    if not addonName then return {} end

    local observed = VC:GetPeerVersions(addonName)
    local GR       = Roster()
    local ready    = GR and GR.IsReady and GR:IsReady()

    local byName, rows = {}, {}
    local function row(name)
        local existing = byName[name]
        if existing then return existing end
        local created = { name = name, account = name, state = "unknown" }
        byName[name] = created
        rows[#rows + 1] = created
        return created
    end

    -- Guild membership first, so someone who has never reported still gets a row. Without this the
    -- window can only ever show people who answered, which is the question nobody is asking.
    if ready and GR.GetAllMembers then
        for _, member in ipairs(GR:GetAllMembers()) do
            local entry = row(member)
            entry.state = "offline"
            local info  = GR.GetMember and GR:GetMember(member)
            if info then
                entry.rank      = info.rankName
                entry.rankIndex = info.rankIndex
                -- `classFile` rather than `class`, because that is the field name LibAceGUIWidgets'
                -- RowList reads to class-colour a cell (`color = "class"` on the column spec). Same
                -- value, and naming it anything else means the colouring silently does nothing.
                entry.classFile = info.class
                entry.online    = info.isOnline == true
                if entry.online then entry.state = "silent" end
            end
        end
    end

    -- Then what we have actually heard, which can include people the roster does not have.
    for sender, observation in pairs(observed) do
        local entry   = row(sender)
        entry.version = observation.version
        entry.via     = observation.via
        entry.at      = observation.at
        entry.state   = "reported"
        -- Not one of ours (the pass above filled every home member's rank): maybe a sister's.
        if entry.rank == nil then FillFromSisterRoster(GR, entry) end
    end

    -- Ourselves. We are running the addon, we know our own version exactly, and a roster that omits
    -- the person reading it invites them to wonder whether they are in it.
    local hostEntry = VC.hosts[addonName]
    if hostEntry then
        local me = SelfName()
        if me then
            local entry   = row(PeerKey(me))
            entry.version = HostVersion(hostEntry)
            entry.isSelf  = true
            entry.state   = "reported"
        end
    end

    if GR and GR.GetAltOwner then
        for _, entry in ipairs(rows) do
            entry.account = GR:GetAltOwner(entry.name) or entry.name
        end
    end

    table.sort(rows, function(a, b) return a.name < b.name end)
    return rows
end

-- THE TRANSPORT-LEVEL DEDUP KEY, which is deliberately NOT the identity key.
--
-- These two heuristics were nearly deleted in favour of PeerKey and must not be: they answer a
-- different question. PeerKey answers "who is this player", using LibGuildRoster's CanonName, which
-- is PURE -- a bare name stays bare and never gains a realm. That is the correct property for an
-- identity you store, and it is exactly the wrong one here, because the case this dedup exists for
-- is ONE player arriving as "Bob" on GreenWall and "Bob-Whitemane" on AceComm within seconds. Under
-- CanonName those are two keys and we answer twice.
--
-- The other half of LibGuildRoster's rule -- "the sender qualifies" -- is what closes that properly,
-- and VC now does it: FireBatch puts our own qualified name in the payload as `__from`. But the
-- dedup runs BEFORE the payload is deserialized, on purpose (see the ordering note in
-- HandleRequest, and request_spec's case for it: an unreadable message must not buy a free parse),
-- so it cannot see `__from` and must work from the transport's sender string alone.
--
-- So: heuristic for the cheap rate-limiting question, canonical identity for the stored answer.
local function GW_StripRealm(name)
    if not name then return "" end
    return (name:gsub("%-.*$", ""))
end

-- Two sender strings sharing a base name: same person? If either arrived without a realm suffix it
-- is the realmless spelling of the other; if both carry a realm they must match. Without this the
-- strip collapses "Bob-Whitemane" and "Bob-Faerlina", two different people, and drops one of them.
local function GW_SameSender(a, b)
    if a == b then return true end
    return a:match("%-(.+)$") == nil or b:match("%-(.+)$") == nil
end

-- ---------------------------------------------------------------------------
-- PLAYER_ENTERING_WORLD frame
-- Fires once after all addons have loaded and the player is fully in the world.
-- This is the correct hook point for RegisterComm and the initial broadcast:
--   • All addons have already called Enable() by the time this fires.
--   • The guild channel is available.
--   • No arbitrary timer guessing required.
-- ---------------------------------------------------------------------------
if not VC._frame then
    VC._frame = CreateFrame("Frame")
end
VC._frame:UnregisterAllEvents()
VC._frame:RegisterEvent("PLAYER_ENTERING_WORLD")
VC._frame:SetScript("OnEvent", function(self, _event)
    -- Only fire once per session; ignore subsequent zone transitions.
    self:UnregisterAllEvents()

    -- Register comm handlers immediately so we can receive other players'
    -- broadcasts that arrive during our own startup delay.
    if not VC.commRegistered then
        VC.commRegistered = true
        AceComm:RegisterComm(LIBRARY_REQ_PREFIX, function(prefix, message, distribution, sender)
            VC:OnCommReceived(prefix, message, distribution, sender)
        end)
        AceComm:RegisterComm(LIBRARY_RSP_PREFIX, function(prefix, message, distribution, sender)
            VC:OnCommReceived(prefix, message, distribution, sender)
        end)
        VCPrint("PLAYER_ENTERING_WORLD: library comm prefixes registered.")

        -- Optional GreenWall transport. Registering the handler is harmless
        -- even if the bridge channel never gets joined.
        if GreenWallAPI ~= nil and not VC.gwHandlerId then
            VC.gwHandlerId = GreenWallAPI.AddMessageHandler(function(addon, sender, message, echo, guild)
                VC:OnGreenWallMessage(addon, sender, message, echo, guild)
            end, MAJOR, 0)
            VCPrint("GreenWall API present; handler registered for '" .. MAJOR .. "'.")
        end

        -- Hook ChatEdit_ParseText with hooksecurefunc so we can call
        -- GreenWallAPI.SendMessage from inside the user's chat-keystroke
        -- secure scope. Calling SendMessage from automation (PEW timer,
        -- C_Timer, slash command) trips Blizzard's no-HW-event protection
        -- on SendChatMessage. Riding the same hook GreenWall itself uses
        -- for chat bridging is the only reliable path. Installed once
        -- per session; fires only when there's a pending payload.
        if not VC.gwHookInstalled then
            VC.gwHookInstalled = true
            hooksecurefunc("ChatEdit_ParseText", function(_editBox, send)
                if send ~= 1 then return end
                if VC:FlushGreenWall() then
                    VCPrint("ChatEdit_ParseText hook: GreenWall REQ sent in HW scope.")
                end
            end)
            VCPrint("Installed ChatEdit_ParseText hook for GreenWall send.")
        end
    end
    -- Follow the guild roster, if it is installed. Here rather than at file scope because the
    -- roster library may register with LibStub after this one does, and because this is the point
    -- at which the client is far enough along for IsReady() to mean something.
    VC:HookRoster()

    -- Every addon has loaded by now, so a library LibStub cannot find is genuinely absent. Say so.
    VC:ReportMissingLibraries()

    -- Short delay before broadcasting to ensure the guild roster and
    -- addon message channel are fully available.
    C_Timer.After(5, function()
        VC:FireBatch()
    end)
end)

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Host addon must call this once after loading.
-- hostAddon should be a table with :GetName() and a .Version field.
-- Also accepts a plain string addon name for simpler callers.
function VC:Enable(hostAddon)
    local hostName, hostObj

    if type(hostAddon) == "string" and hostAddon ~= "" then
        -- Caller passed a string name directly.
        hostName = hostAddon
        hostObj  = nil
    elseif type(hostAddon) == "table" and hostAddon.GetName then
        -- Caller passed a proper addon object.
        hostName = hostAddon:GetName()
        hostObj  = hostAddon
    else
        VCPrint("Enable: hostAddon has no usable name. Pass the addon object or a name string.")
        return
    end

    if not hostName or hostName == "" then
        VCPrint("Enable: resolved name is empty. Skipping.")
        return
    end

    -- Idempotent registration.
    VC.hosts[hostName] = VC.hosts[hostName] or {}
    local hostEntry = VC.hosts[hostName]
    hostEntry.host             = hostObj
    hostEntry.addonName        = hostName
    hostEntry.VersionResponses  = hostEntry.VersionResponses or {}
    hostEntry.VersionCheckActive = false

    VCPrint("Enable: registered " .. hostName)
    return hostEntry
end

-- Documented alias for Enable, claiming a name two shipped consumers already call FIRST.
--
-- Grouper and BijouRR both open with `if VC.RegisterCheck then VC:RegisterCheck(NAME, VERSION)
-- elseif VC.Enable then VC:Enable(self) end`. The name had never existed here, so the elseif
-- rescued them and every version check worked. That made it a trap that would arm itself the day
-- this library defined RegisterCheck for ANY purpose: both consumers would switch to the first
-- branch, stop calling Enable, register no host, and silently never show an update popup again --
-- no error, no log, and this library's own suite could not have seen it because every spec drives
-- Enable. Claiming the name with the meaning those call sites plainly intend is what makes it
-- impossible to re-purpose underneath them.
--
-- Pass the RAW TOC version string, sentinel included: an unsubstituted "VersionCheck-v1.5.3" is how
-- dev-build suppression recognises a host running from unpackaged source. Sanitising it to
-- something "nicer" defeats that.
function VC:RegisterCheck(nameOrHost, version)
    local hostEntry = VC:Enable(nameOrHost)
    if not hostEntry then return end

    -- Recorded on the entry rather than stamped onto hostEntry.host, because for the object form
    -- that table is the CALLER'S addon object and writing a Version field into it would mutate a
    -- consumer's own state from inside a library.
    if version ~= nil and version ~= "" then
        hostEntry.declaredVersion = version
    end
    return hostEntry
end

-- ---------------------------------------------------------------------------
-- Batch broadcast
-- ---------------------------------------------------------------------------

-- Registers the two shared comm prefixes (once) then sends a single GUILD
-- broadcast containing every registered addon's name and version.
--
-- `push` (boolean) adds PUSH_KEY, asking every receiver to run its update decision on receipt
-- rather than at its own next window. Leadership-only at the UI; the wire does not check rank,
-- because it cannot -- a peer has no way to verify another member's permissions.
function VC:FireBatch(push)
    VC.batchFired = true

    -- RegisterComm is handled at PLAYER_ENTERING_WORLD time.
    -- Guard here covers the legacy shim re-fire path.

    -- A new collection round for every host.
    for _, hostEntry in pairs(VC.hosts) do
        hostEntry.VersionResponses     = {}
        hostEntry.VersionCheckActive   = true
        hostEntry.noResponseLogged     = false
        -- lastShown deliberately persists across batches: hosts (e.g. TPM
        -- scanner) re-trigger FireBatch periodically, and resetting here
        -- would re-pop the same outdated-version alert every cycle.
        -- A genuinely-newer version still surfaces via the strict-greater
        -- check in ProcessVersionResponsesForHost. UI reload clears it
        -- naturally (in-memory only, no SavedVariable).
    end

    -- The control fields are reserved keys and invisible to every reader that does not know them: a
    -- peer at MINOR 12 looks them up in its hosts table, finds nothing, and ignores them; a peer at
    -- MINOR 13 filters them out of harvesting.
    --
    -- resync: "I have nothing, send me everything." Derived from the store rather than from a flag,
    -- so it is true whenever it is true -- at the first batch of a session, and after anything that
    -- leaves us with no observations. VC.peerVersions is in-memory, so a reload genuinely does know
    -- nothing.
    local batch, count = BuildRequest({ resync = (next(VC.peerVersions) == nil), push = push })

    if count == 0 then
        VCPrint("FireBatch: no registered hosts, nothing to broadcast.")
        return false
    end

    VCPrint("FireBatch: broadcasting batch for " .. count .. " addon(s)" .. (push and ", PUSH" or "") .. ".")

    -- The AceComm leg carries the full batch -- AceComm chunks it -- and the GreenWall leg carries
    -- the trigger built from it, because GreenWall does not chunk (see GW_PAYLOAD_BUDGET).
    SendRequest(batch, GreenWallTrigger(batch))

    if VC.collectionTimer then VC.collectionTimer:Cancel(); VC.collectionTimer = nil end

    -- AceComm 12s collection window for in-guild RSPs. Always runs.
    VC:StartCollectionWindow()

    -- True means a request went out. The empty-batch return above is the false; RequestCheck turns
    -- it into "nothing was sent, so nothing is owed" for a button.
    return true
end

-- Release the parked GreenWall request NOW. Returns true when something was sent, false when nothing
-- was parked or GreenWall is absent. The ChatEdit_ParseText hook is one caller; the other is a
-- consumer running inside ITS OWN hardware event -- a click on a frame it owns -- which is exactly
-- as good a scope as a chat keystroke and does not wait for the player to say something.
--
-- THE CALLER GUARANTEES THE HARDWARE EVENT. This function cannot check it, and does nothing else:
-- no rate limit (the parked payload already passed one), no collection window. Asked for by
-- LibGuildRoster (thread ec8f7fed, 2026-09-15), whose sister-guild sync is driven from a click
-- overlay and, until this existed, reached into VC.gwPendingPayload from outside to do the same
-- three lines -- our bytes under our name, from someone else's code.
function VC:FlushGreenWall()
    local payload = VC.gwPendingPayload
    if not payload or not GreenWallAPI then return false end
    VC.gwPendingPayload = nil
    GreenWallAPI.SendMessage(MAJOR, payload)
    return true
end

-- Why a broadcast would be refused right now, as RequestCheck's two kinds of false: `false, 0` when
-- there is nothing to send to (not in a guild), `false, N` when peers would still drop it (their
-- dedup, keyed on us, has N seconds to run). Nil when a broadcast can go. One function because
-- RequestCheck and RequestAbout share the clock -- a targeted broadcast 5 seconds after the login
-- batch is dropped unread by everyone, exactly like a refresh.
local function BroadcastRefusal(what)
    -- Feature-detected: the harness installs IsInGuild only in its opt-in guild layer, and an
    -- absent global must read as "cannot tell" rather than "not in a guild".
    if IsInGuild and not IsInGuild() then
        VCPrint(what .. ": not in a guild, nothing to send to.")
        return false, 0
    end
    if VC.lastBatchAt then
        local since = GetTime() - VC.lastBatchAt
        if since < GW_REQ_DEDUP_TTL then
            local wait = GW_REQ_DEDUP_TTL - since
            VCPrint(what .. ": suppressed, " .. string.format("%.1f", wait) .. "s remaining.")
            return false, wait
        end
    end
    return nil
end

-- The refresh entry point for a UI. Rate-limited, and the limit is not a taste decision: peers
-- suppress a repeat REQ from the same player for GW_REQ_DEDUP_TTL seconds, so a broadcast sooner
-- than that is answered by nobody and spends bandwidth to make the roster look emptier than it did
-- before the user pressed the button.
--
-- Returns true when it fired, or false plus the seconds remaining -- so a caller can grey the
-- button and say when, rather than firing into silence and looking broken.
--
-- TWO KINDS OF FALSE, and a button must tell them apart. `false, N` with N > 0 is the clock: peers
-- would drop the request, wait N seconds. `false, 0` is "there was nothing to send" -- no GUILD
-- channel because the player is not in a guild, or no hosts registered -- and a button must NOT
-- start a countdown for it, because nothing went out and nothing is owed. A self-audit found the
-- first draft of this function only ever refused for the clock while three documents described
-- the second case; the case exists now, and the docs are true.
--
-- `push` is forwarded to FireBatch. It shares this rate limit rather than having its own, and the
-- reason is the receiver's dedup, not ours: a peer drops a second REQ from the same sender inside
-- GW_REQ_DEDUP_TTL before it has even parsed it, so a push sent 5 seconds after a refresh would be
-- dropped unread by everyone -- exactly the "fired into silence" this function exists to prevent.
function VC:RequestCheck(push)
    local refused, wait = BroadcastRefusal("RequestCheck")
    if refused == false then return false, wait or 0 end
    if not VC:FireBatch(push) then
        return false, 0
    end
    return true, 0
end

-- Ask the guild -- and, through GreenWall, the confederation -- about ONE registered host. Same
-- two transports as FireBatch, same return shape and the same clock as RequestCheck, but the batch
-- names one addon, so it fits GreenWall's single segment with room to spare and every receiver at
-- every MINOR answers about exactly that addon (HandleRequest replies the intersection of the
-- request's names with its hosts). Asked for by LibGuildRoster (thread 73cb2669, 2026-09-15): "who
-- runs GuildRoster, and which version" is the question it needs answered before it syncs a roster
-- with someone, and the full batch is measured never to fit the GreenWall leg.
--
-- RESYNC_KEY is always set, for the reason RequestFrom sets it: a targeted ask wants a full answer,
-- and a MINOR 13+ peer that already told us would otherwise stay quiet. `addonName` must be a
-- registered host -- the request carries our own version of it, and we have none for an addon we
-- do not run -- so an unregistered name is `false, 0`, the same "nothing to send" a button must not
-- count down for.
--
-- Like RequestFrom, this is not a round of the popup decision: no collection window is opened and
-- no VersionResponses are cleared. Answers arrive through HandleResponse and OnPeerVersion. (The
-- GreenWall echo of the parked trigger still re-arms a window, as it does for every parked payload;
-- that path sends nothing.)
function VC:RequestAbout(addonName)
    local hostEntry = type(addonName) == "string" and VC.hosts[addonName]
    if not hostEntry then
        VCPrint("RequestAbout: " .. tostring(addonName) .. " is not a registered host, nothing to ask about.")
        return false, 0
    end

    local refused, wait = BroadcastRefusal("RequestAbout")
    if refused == false then return false, wait or 0 end

    -- Every control field the full batch carries, then the one host. Built by hand rather than
    -- through BuildRequest because that function's job is "every host", and this is the one place
    -- that wants exactly one.
    local batch = {}
    batch[PROTOCOL_KEY] = PROTOCOL_VERSION
    batch[RESYNC_KEY]   = "1"
    local me = SelfName()
    if me then batch[FROM_KEY] = me end
    batch[addonName] = HostVersion(hostEntry)

    VCPrint("RequestAbout: asking about " .. addonName .. ".")
    SendRequest(batch, batch)
    return true, 0
end

-- Ask ONE player what they run: the same request FireBatch broadcasts, sent by WHISPER to `name`
-- instead of to GUILD. Returns true when a request was handed to the transport, false when nothing
-- could be sent (no name, no registered hosts, or the name is our own).
--
-- Built for LibGuildRoster (thread 754c66fd, 2026-09-15): before it pulls a roster from someone a
-- /who listed, it asks THEM what they run and pulls from the most compatible responder. A sister-
-- guild member never hears our GUILD batch, so this is the only way to reach them -- and until it
-- existed GR built the request itself, from a copy of this library's prefix and control keys,
-- which was VC's private wire maintained in two places.
--
-- WHAT IT COSTS: one whisper, once, when a consumer calls it. Nothing here polls, retries or
-- schedules; a consumer must not call it in a loop.
--
-- WHAT THE OTHER SIDE DOES, at every MINOR in the wild: HandleRequest ignores the distribution, so
-- a WHISPER request is answered exactly as a GUILD one -- by WHISPER, into HandleResponse, which
-- records the versions and fires OnPeerVersion. RESYNC_KEY is always set, because a targeted ask
-- wants a full answer: without it a MINOR 13+ peer we had already heard from would stay quiet, by
-- design, and the consumer asking would learn nothing.
--
-- TWO THINGS IT DELIBERATELY DOES NOT DO. It does not touch the GUILD dedup clock (VC.lastBatchAt),
-- which is about what our guildmates suppress and has nothing to do with a whisper to one player;
-- and it does not open a collection window or clear VersionResponses, because it is not a round of
-- the popup decision -- the answer is an observation, and observations are what OnPeerVersion is
-- for. Known and documented rather than worked around: a GUILDMATE asked inside GW_REQ_DEDUP_TTL
-- of our own broadcast drops this as a duplicate, which is their dedup working as designed.
function VC:RequestFrom(name)
    if type(name) ~= "string" or name == "" then return false end

    local batch, count = BuildRequest({ resync = true })
    if count == 0 then
        VCPrint("RequestFrom: no registered hosts, nothing to ask about.")
        return false
    end

    -- Asking ourselves is pointless, and the receiving side would drop it as an own echo anyway
    -- (HandleRequest's identity check) -- so say false now rather than send and hear nothing.
    local recipient = QualifyName(name)
    local me        = SelfName()
    if me and PeerKey(recipient) == PeerKey(me) then
        VCPrint("RequestFrom: " .. recipient .. " is us, nothing to ask.")
        return false
    end

    VCPrint("RequestFrom: asking " .. recipient .. " about " .. count .. " addon(s).")
    AceComm:SendCommMessage(LIBRARY_REQ_PREFIX, AceSerializer:Serialize(batch), "WHISPER", recipient)
    return true
end

-- Leadership, by the roster library's one predicate for it: the officer-note PERMISSION, which a
-- GM granted deliberately, not a rank index, which is a position in a list the GM can arrange any
-- way at all. GMs hold every permission, so this covers them. Only answerable for the player.
function VC:IsLeadership()
    local GR = Roster()
    if not (GR and GR.IsOfficer) then return false end
    return GR:IsOfficer() and true or false
end

-- A version string that can be compared at all. `VersionCheck-v1.5.3` (an unpackaged dev build) and
-- "unknown" carry no digits, and CompareVersion reads a digitless string as 0.0.0 -- so without
-- this guard a developer running from source is "behind" everyone and gets whispered about it.
-- The popup path already treats the sentinel specially; this is the same rule applied here.
local function IsComparableVersion(v)
    return type(v) == "string" and v:find("%d") ~= nil
end

-- The newest build of an addon anyone is known to run, OURS INCLUDED -- a leader on the current
-- build is exactly who whispers about it, and the popup decision counts us the same way. Dev builds
-- and "unknown" are skipped as candidates; they are not builds anyone can be behind.
function VC:NewestKnownVersion(addonName)
    local hostEntry = VC.hosts[addonName]
    local mine      = hostEntry and HostVersion(hostEntry)
    local newest    = IsComparableVersion(mine) and mine or nil
    for _, addons in pairs(VC.peerVersions) do
        local observation = addons[addonName]
        local version = observation and observation.version
        if IsComparableVersion(version) and (not newest or VC:CompareVersion(version, newest) > 0) then
            newest = version
        end
    end
    return newest
end

-- Is this roster row behind the newest known build? nil when there is nothing to compare -- the
-- three not-known states, and a dev build, whose sentinel is not a version -- because "behind"
-- and "not behind" would both be claims about something we cannot measure.
function VC:IsBehind(entry, addonName)
    if not (entry and IsComparableVersion(entry.version)) then return nil end
    local newest = VC:NewestKnownVersion(addonName)
    if not newest then return false end
    return VC:CompareVersion(entry.version, newest) < 0
end

-- The canned whisper. The user's words, with the two versions added so the recipient can see at a
-- glance whether it is true.
local WHISPER_TEXT = "Your %s is out of date (you have %s, latest is %s), please update."

-- Whisper one guildmate that their copy is behind. Returns the text sent, or nil when the client
-- offers no way to send. Feature-detects the namespaced form first: on Classic Era the bare global
-- is a deprecation fallback that forwards to it (Blizzard_DeprecatedChatInfo), not the API proper.
function VC:WhisperUpdate(entry, addonName)
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if not (send and entry and entry.name) then return nil end
    local text = string.format(WHISPER_TEXT, tostring(addonName), tostring(entry.version),
                               tostring(VC:NewestKnownVersion(addonName)))
    send(text, "WHISPER", nil, QualifyName(entry.name))
    return text
end

-- Roster events, forwarded as one VC-level "the roster changed, repaint" signal.
--
-- A consumer of this library should not have to learn LibGuildRoster's event vocabulary to keep a
-- window current, and every one of these means the same thing to a version roster: a row appeared,
-- vanished, or changed.
--
-- TWO THINGS HERE ARE EASY TO GET WRONG AND BOTH COME FROM LibGuildRoster'S OWN ANSWER (2026-09-10).
--
-- Register on the LIBRARY with a DOT -- `GR.RegisterCallback(VC, ...)` -- not on `GR.callbacks`.
--
-- And there is NO REPLAY. `OnRosterReady` fires at exactly one site, once per session, and since
-- that library's 0.5.0 the roster is built once at login and maintained from events -- there is no
-- later rebuild to rescue a late registrant. VersionCheck wires up at PLAYER_ENTERING_WORLD, which
-- is routinely after the roster is ready, so a registrant that merely waits waits for ever. Asking
-- IsReady() and doing the first fill ourselves is not belt-and-braces; it is the only path that
-- works on a normal login, and getting it wrong is a window that is empty for the whole session.
local ROSTER_EVENTS = {
    "OnRosterReady", "OnRosterUpdated", "OnMemberOnline", "OnMemberOffline",
    "OnMemberJoined", "OnMemberLeft", "OnMemberRankChanged",
}

function VC:HookRoster()
    if VC.rosterHooked then return false end
    local GR = Roster()
    if not (GR and GR.RegisterCallback) then return false end

    VC.rosterHooked = true
    -- Repaint first, then tell consumers. Called directly rather than by registering VC on its own
    -- callback registry: CallbackHandler keys registrations by TARGET, so the library registering
    -- itself would silently REPLACE any consumer that also used VC as its target -- which is what
    -- happened, and three specs caught it as a callback that simply stopped arriving.
    local function changed()
        VC:RefreshRoster()
        VC.callbacks:Fire("OnRosterChanged")
    end
    for _, event in ipairs(ROSTER_EVENTS) do
        GR.RegisterCallback(VC, event, changed)
    end

    if GR.IsReady and GR:IsReady() then changed() end
    VCPrint("HookRoster: following LibGuildRoster for live roster changes.")
    return true
end

-- 12s collection window. Responses (from either transport) keep landing in
-- VersionResponses. When the timer fires, ProcessAllHosts runs once.
function VC:StartCollectionWindow()
    if VC.collectionTimer then VC.collectionTimer:Cancel() end
    VC.collectionTimer = C_Timer.NewTimer(12, function()
        VC.collectionTimer = nil
        VC:ProcessAllHosts()
    end)
end

-- ---------------------------------------------------------------------------
-- Comm handler
-- ---------------------------------------------------------------------------

function VC:OnCommReceived(prefix, message, _distribution, sender)
    if prefix == LIBRARY_REQ_PREFIX then
        VC:HandleRequest(message, sender, "ACECOMM")
    elseif prefix == LIBRARY_RSP_PREFIX then
        VC:HandleResponse(message, sender)
    end
end

-- Inbound handler registered with GreenWallAPI. An echo of our own segment
-- is the proof that GreenWall finally flushed our queued REQ — at that
-- point we (re-)arm the collection window so confederation RSPs can land
-- in it. A non-echo from another player is a real REQ; treat it as such.
function VC:OnGreenWallMessage(addon, sender, message, echo, _guild)
    if addon ~= MAJOR then return end
    if echo then
        VCPrint("OnGreenWallMessage: own echo received, (re-)arming collection window.")
        for _, hostEntry in pairs(VC.hosts) do
            hostEntry.VersionCheckActive = true
        end
        VC:StartCollectionWindow()
        return
    end
    VC:HandleRequest(message, sender, "GREENWALL")
end

-- Process an incoming REQ from either transport. Same player can arrive on
-- both AceComm GUILD and GreenWall when in our own guild; respond once.
function VC:HandleRequest(message, sender, transport)
    -- Rate-limiting, on the transport's own sender string. Runs BEFORE the payload is deserialized,
    -- deliberately: parsing first would let a peer flooding unreadable messages make us deserialize
    -- every one. That ordering is why this cannot use `__from` and must stay heuristic.
    local senderKey = GW_StripRealm(sender)
    local now       = GetTime()
    local seen      = VC.gwReqSeen[senderKey]
    if seen and seen.expires > now then
        if GW_SameSender(seen.full, sender) then
            -- Upgrade the stored spelling to the realm-qualified one when that is what arrived, so
            -- a THIRD sender on a different realm is compared against a realm we know rather than
            -- against a bare base name that matches everybody.
            if seen.full:match("%-(.+)$") == nil then seen.full = sender end
            VCPrint("HandleRequest: suppressing duplicate REQ from " .. tostring(sender)
                    .. " via " .. transport .. " (already responded).")
            return
        end
        VCPrint("HandleRequest: " .. tostring(sender) .. " shares a base name with "
                .. tostring(seen.full) .. " but is a different character; responding.")
    end
    VC.gwReqSeen[senderKey] = { expires = now + GW_REQ_DEDUP_TTL, full = sender }

    local success, batch = AceSerializer:Deserialize(message)
    if not success then
        VCPrint("HandleRequest REQ via " .. transport .. ": deserialize failed from " .. tostring(sender))
        return
    end

    -- Two jobs in one pass over the payload.
    --
    -- HARVEST every entry, including addons we do not have -- their REQ lists THEIR hosts, so this
    -- is where we learn that a guildmate runs something we have never installed. It also reaches
    -- confederation peers whose WHISPER replies could never come back to us (GreenWall extends who
    -- hears our REQ, not who can whisper us), so their versions arrive here or nowhere.
    --
    -- REPLY only about addons we also have. That intersection is a property of the reply, not of
    -- what we are allowed to learn, and conflating the two is what threw the versions away before.
    -- ANSWER ON CHANGE, not on request -- but only for a peer that can cope with it.
    --
    -- PROTOCOL_KEY absent means the asker is MINOR 12 or 13: it cannot request a resync and has no
    -- memory we could rely on, so it gets the full answer it has always got. That branch is what
    -- makes this safe to ship into guilds full of older copies, and it is why the protocol marker
    -- exists at all -- without it, "this peer already knows" and "this peer is too old to say" are
    -- the same observation, and suppressing the second silently breaks their version check.
    local wantsFull = (batch[PROTOCOL_KEY] == nil) or (batch[RESYNC_KEY] ~= nil)

    -- Prefer the name the sender qualified for us over the shape the transport happened to use. A
    -- peer too old to send it (MINOR 12 or earlier) falls back to the transport's string, QUALIFIED
    -- with our realm when it arrived bare -- see TransportIdentity.
    local identity = TransportIdentity(batch[FROM_KEY], sender)

    -- Our own request, echoed back. Some server cores deliver a player's own GUILD addon message
    -- to them; without this we would answer ourselves with a WHISPER on every login and, with
    -- PUSH_KEY, run the update decision against our own version. Neither is harmful, both are
    -- noise. GreenWall's echo is already filtered in OnGreenWallMessage; this is the AceComm side.
    -- Decided by identity, not by the raw sender, so a realm-qualified echo still matches.
    -- `__from` is sender-controlled, so a peer that writes OUR name into it is dropped here too.
    -- That is spoofable only in the direction of "make VersionCheck ignore me" -- they lose their
    -- own answer and nobody else does -- and it is why this filter must never be "hardened" by
    -- trusting `__from` for anything more than the identity of a peer talking about themselves.
    local me = SelfName()
    if me and identity == PeerKey(me) then
        VCPrint("HandleRequest: own request echoed back via " .. transport .. ", ignoring.")
        return
    end

    local told = VC.toldPeers[identity]
    if not told then
        told = {}
        VC.toldPeers[identity] = told
    end

    local response = {}
    local shared, hasAny = false, false
    local function offer(addonName, hostEntry)
        shared = true
        local mine = HostVersion(hostEntry)
        if wantsFull or told[addonName] ~= mine then
            response[addonName] = mine
            hasAny = true
        end
    end
    for addonName, version in pairs(batch) do
        VC:RecordPeerVersion(identity, addonName, version, "REQ")
        local hostEntry = VC.hosts[addonName]
        if hostEntry then offer(addonName, hostEntry) end
    end

    -- A TRIGGER: the sender could not fit its inventory (the GreenWall leg) and asks about
    -- everything we have instead. The intersection above still ran for the names it did carry;
    -- this adds the rest, under the same answer-on-change gate. Nothing about the reply's size is
    -- a concern -- it goes by AceComm WHISPER, which chunks.
    if batch[ALL_KEY] ~= nil then
        for addonName, hostEntry in pairs(VC.hosts) do
            if response[addonName] == nil then offer(addonName, hostEntry) end
        end
    end

    -- Leadership asked everyone to decide now. AFTER the harvest, so the sender's versions are in
    -- the store the decision reads; BEFORE the reply gate below, because a push from someone we
    -- answered a minute ago is still a push. Only the hosts we share can be out of date here, and
    -- ProcessVersionResponsesForHost is the existing decision unchanged -- it reads the store,
    -- compares, dedups on lastShown, suppresses dev builds and defers in combat. OnCheckComplete is
    -- NOT fired: no window of ours closed.
    -- A push on a TRIGGER (ALL_KEY) is about every host, not just the names that fit: the leader
    -- pressed one button for the whole guild and the confederation, and the trigger's name list is
    -- an artefact of the message size, not of what they meant.
    if batch[PUSH_KEY] ~= nil then
        VCPrint("HandleRequest REQ from " .. tostring(sender) .. " via " .. transport .. ": PUSH, deciding now.")
        for addonName in pairs(batch[ALL_KEY] ~= nil and VC.hosts or batch) do
            local hostEntry = VC.hosts[addonName]
            if hostEntry then VC:ProcessVersionResponsesForHost(hostEntry) end
        end
    end

    if not hasAny then
        -- Two different silences, kept apart in the log because they mean opposite things: one is
        -- "we have nothing in common", the other is "you already have everything I could tell you".
        if shared then
            VCPrint("HandleRequest REQ from " .. tostring(sender) .. " via " .. transport
                    .. ": nothing has changed since we last answered them, staying quiet.")
        else
            VCPrint("HandleRequest REQ from " .. tostring(sender) .. " via " .. transport
                    .. ": no matching addons, not responding.")
        end
        return
    end

    local recipient = QualifyName(sender)

    -- Jitter 0-8s so all responders don't whisper back simultaneously (thundering herd fix).
    --
    -- Deliberately NOT seeded, and deliberately not switched to fastrandom. Checked in Blizzard's
    -- own global API listing (F:\Blizzard API Docs\GlobalAPI.lua): math.randomseed is NOT exposed
    -- to addons at all — the list runs math.rad, math.random, math.sin — so no addon can seed it
    -- even if it wanted to, and the usual `math.randomseed(time())` defence is impossible here.
    -- Blizzard's own UI depends on math.random varying across sessions (/castrandom picks a spell
    -- with it, ChatFrameUtil picks random responses) and never seeds it either, so the client must
    -- seed it internally — that is inference about the binary rather than something the Lua source
    -- can prove, but it is the only reading under which Blizzard's own features work.
    -- Recorded now rather than inside the jittered send, so a second REQ arriving during the jitter
    -- window cannot queue a duplicate answer. Failing this way round is safe: if the send is later
    -- refused by the client we will have recorded telling them something we did not, and the worst
    -- case is one round of silence until our version changes -- against the alternative, which is
    -- answering the same peer twice for every request that overlaps a jitter.
    for addonName, version in pairs(response) do
        told[addonName] = version
    end

    -- Added AFTER the `told` loop so it is never mistaken for an addon we have promised somebody.
    --
    -- The REPLY has to name us too. Without it the identity model covered requests only: our REQ
    -- arrives keyed by `__from` while our RSP arrives keyed by whatever shape the transport used, so
    -- one player occupied TWO rows in a peer's roster and they could never merge. That is the
    -- collapse-versus-split defect this whole mechanism exists to remove, and it survived on the
    -- reply path until a self-audit read the two call sites next to each other. `me` was resolved
    -- above, for the own-echo check.
    if me then response[FROM_KEY] = me end

    local jitter = math.random(0, 8)
    VCPrint("HandleRequest REQ via " .. transport .. ": responding to " .. tostring(recipient)
            .. " in " .. jitter .. "s.")
    C_Timer.After(jitter, function()
        AceComm:SendCommMessage(LIBRARY_RSP_PREFIX, AceSerializer:Serialize(response), "WHISPER", recipient)
    end)
end

-- Process an incoming RSP whisper.
function VC:HandleResponse(message, sender)
    local success, batch = AceSerializer:Deserialize(message)
    if not success then
        VCPrint("HandleResponse RSP: deserialize failed from " .. tostring(sender))
        return
    end

    -- Same identity rule as HandleRequest: prefer the name the sender qualified for us over the
    -- shape the transport used. Both tables are keyed on it -- VersionResponses was keyed on the raw
    -- string until a self-audit found it, which meant the popup could name one spelling of a player
    -- while the roster named another, for the same person in the same session.
    local identity = TransportIdentity(batch[FROM_KEY], sender)

    for addonName, version in pairs(batch) do
        -- Harvested unconditionally, unlike the VersionResponses write below. A reply that lands
        -- outside a collection window is still a true observation about that player; it is only
        -- useless to the popup decision, which is what VersionCheckActive gates.
        VC:RecordPeerVersion(identity, addonName, version, "RSP")
        local hostEntry = VC.hosts[addonName]
        if hostEntry and hostEntry.VersionCheckActive then
            hostEntry.VersionResponses[identity] = version
            VCPrint("HandleResponse RSP: " .. addonName .. " v" .. tostring(version) .. " from " .. tostring(sender))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Result processing
-- ---------------------------------------------------------------------------

-- Runs after the collection window closes. Processes every registered host.
function VC:ProcessAllHosts()
    for _, hostEntry in pairs(VC.hosts) do
        VC:ProcessVersionResponsesForHost(hostEntry)
    end
    -- Fired after every host has been processed, so a UI knows the window has closed and can stop
    -- showing a spinner. Deliberately not "we found everyone" -- nothing can know that; it only
    -- means we have stopped waiting.
    VC.callbacks:Fire("OnCheckComplete")
end

function VC:ProcessVersionResponsesForHost(hostEntry)
    -- VersionCheckActive deliberately stays true across rounds — round 2
    -- (post-GreenWall-echo) RSPs need to be able to land in VersionResponses.
    -- It's reset to true at next FireBatch.

    -- Considers THIS ROUND's replies and everything observed earlier in the session, because
    -- neither is sufficient alone.
    --
    -- VersionResponses is emptied by every FireBatch, and hosts re-trigger batches routinely -- so
    -- once peers stop repeating themselves, a decision reading only this round sees an empty table
    -- and concludes nobody runs the addon. That is what answering-on-change would otherwise have
    -- broken, and the whole suite passed while it was broken.
    --
    -- It also fixes something older: a GreenWall confederation peer can send a request we can never
    -- whisper back to, so their version arrives in that broadcast and nowhere else. It could never
    -- reach this decision before; now it can.
    --
    -- Stale entries are not a hazard here. A version we were told is a version that exists, the
    -- comparison only ever looks for the highest, and lastShown still stops the same alert firing
    -- twice.
    local highestSender, highestVersion = nil, nil
    local function consider(sender, version)
        if not version then return end
        if not highestVersion or VC:CompareVersion(version, highestVersion) > 0 then
            highestSender, highestVersion = sender, version
        end
    end

    for sender, version in pairs(hostEntry.VersionResponses) do
        consider(sender, version)
    end
    for sender, addons in pairs(VC.peerVersions) do
        local observation = addons[hostEntry.addonName]
        if observation then consider(sender, observation.version) end
    end

    if not highestSender then
        -- Debug-gated, like every other diagnostic here. This used a bare `print`, which put it in
        -- the user's chat window unconditionally — and "nobody else in your guild runs this addon"
        -- is the NORMAL state for a niche addon, not a problem the user can act on. Worse than a
        -- one-off login notice: hosts re-trigger FireBatch periodically (TOGProfessionMaster's
        -- scanner every ~10 min) and each batch clears noResponseLogged, so it repeated all session,
        -- once per host. The library's only intended user-facing output is the update popup.
        if not hostEntry.noResponseLogged then
            VCPrint("No version responses received for " .. tostring(hostEntry.addonName) .. ".")
            hostEntry.noResponseLogged = true
        end
        return
    end

    VCPrint("Highest version for " .. hostEntry.addonName .. ": " .. highestVersion .. " (" .. highestSender .. ")")
    local myVersion = HostVersion(hostEntry)

    -- Local already at or above the highest seen — nothing to popup.
    if VC:CompareVersion(myVersion, highestVersion) >= 0 then
        return
    end

    -- Already popped at this version (or higher) earlier this batch — don't
    -- show the same popup twice. Round 2 only refreshes if it surfaces a
    -- strictly higher version than what was already shown.
    if hostEntry.lastShown and VC:CompareVersion(highestVersion, hostEntry.lastShown) <= 0 then
        VCPrint(hostEntry.addonName .. ": already popped at " .. hostEntry.lastShown
                .. "; new highest " .. highestVersion .. " not higher, skipping.")
        return
    end

    if IS_DEV_BUILD or myVersion == "VersionCheck-v1.5.3" then
        VCPrint("Suppressing popup: dev build (lib=" .. tostring(IS_DEV_BUILD) .. ", host=" .. tostring(myVersion) .. ").")
        return
    end

    VC:ShowUpdatePopup(hostEntry, highestSender, highestVersion, myVersion)
    hostEntry.lastShown = highestVersion
end

function VC:CompareVersion(ver1, ver2)
    local function split(v)
        local t = {}
        for s in string.gmatch(v, "[0-9]+") do table.insert(t, tonumber(s)) end
        return t
    end
    local v1, v2 = split(ver1), split(ver2)
    for i = 1, math.max(#v1, #v2) do
        local a, b = v1[i] or 0, v2[i] or 0
        if a < b then return -1 elseif a > b then return 1 end
    end
    return 0
end

-- ---------------------------------------------------------------------------
-- Popup
-- ---------------------------------------------------------------------------

function VC:ShowUpdatePopup(hostEntry, sender, highestVersion, myVersion)
    -- Defer if in combat: popups are disruptive mid-fight and the user
    -- can't act on them anyway. Pending args are stashed per-host so that
    -- multiple hosts queued during the same combat don't clobber each
    -- other. PLAYER_REGEN_ENABLED drains all pending popups in one pass;
    -- a single library-scoped frame handles the event for every host.
    if InCombatLockdown() then
        hostEntry._pendingPopup = { sender = sender, highest = highestVersion, mine = myVersion }
        if not VC._combatDeferFrame then
            VC._combatDeferFrame = CreateFrame("Frame")
            VC._combatDeferFrame:SetScript("OnEvent", function()
                for _, h in pairs(VC.hosts) do
                    local p = h._pendingPopup
                    if p then
                        h._pendingPopup = nil
                        VC:ShowUpdatePopup(h, p.sender, p.highest, p.mine)
                    end
                end
            end)
        end
        VC._combatDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        VCPrint(hostEntry.addonName .. ": in combat, deferring popup until PLAYER_REGEN_ENABLED.")
        return
    end

    local addonName = hostEntry.addonName or "This addon"

    -- Say what the player is running as well as what is available. Without it the popup names the
    -- newer version twice and never the user's own, so a popup for a version they have since
    -- installed reads identically to a live one -- and the fourth parameter was threaded through
    -- the whole combat-deferral state machine only to be discarded here.
    --
    -- Falls back to the old single-version phrasing when we genuinely do not know: HostVersion
    -- returns the literal "unknown" on a client where neither GetAddOnMetadata spelling resolves,
    -- and "You have unknown" is worse than not saying it.
    local haveLine
    if myVersion and myVersion ~= "" and myVersion ~= "unknown" then
        haveLine = "You have " .. tostring(myVersion) .. "; player '" .. tostring(sender)
                   .. "' has " .. tostring(highestVersion) .. "."
    else
        haveLine = "Player '" .. tostring(sender) .. "' is using version "
                   .. tostring(highestVersion) .. "."
    end

    local message = addonName .. " may be out of date!\n" .. haveLine
                    .. "\nPlease update to " .. tostring(highestVersion) .. " through CurseForge."
    local safe      = tostring(addonName):gsub("[^%w_]", "_"):upper()
    local popupName = "VC_UPDATE_WARNING_" .. safe

    if not StaticPopupDialogs[popupName] then
        StaticPopupDialogs[popupName] = {
            button1      = "OK",
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end
    StaticPopupDialogs[popupName].text = message
    StaticPopup_Show(popupName)
end

-- ---------------------------------------------------------------------------
-- The roster window
--
-- Everything here is built on FIRST OPEN and never before. ~20 addons embed this library and most
-- of their users will never type the command; they should not pay for a window they do not open.
--
-- The list is LibAceGUIWidgets' RowList -- a virtual-scrolling list with a sortable header -- and
-- NOT a hand-rolled stack of labels. That was the plan until its author pointed out RowList existed,
-- and hand-rolling it would have been the duplicate-behaviour finding this fleet's review keeps
-- raising. The window owns no data of its own: rows come from VC:GetRoster and it repaints on the
-- library's own callbacks.
-- ---------------------------------------------------------------------------

local function Widgets()
    return LibStub and LibStub("LibAceGUIWidgets-1.0", true) or nil
end

-- Sorted host names. `pairs` order is not stable between sessions, so tabs would silently reorder
-- themselves on every login without this.
local function SortedHostNames()
    local names = {}
    for addonName in pairs(VC.hosts) do names[#names + 1] = addonName end
    table.sort(names)
    return names
end

-- What a row shows in the version column. The four states exist so this does not have to lie: only
-- "reported" carries a version, and the rest say which KIND of not-knowing this is.
local STATE_TEXT = {
    reported = nil,          -- replaced by the version itself
    silent   = "Not seen",
    offline  = "Offline",
    unknown  = "Unknown",
}

function VC:BuildRosterRows(addonName)
    local rows = VC:GetRoster(addonName)
    for _, entry in ipairs(rows) do
        entry.shown = entry.version or STATE_TEXT[entry.state] or "Unknown"
        -- The sort keys that break ties. RowList's comparator is deterministic but NOT stable --
        -- equal values land wherever quicksort leaves them, and its own header says so -- and the
        -- healthy case for a guild is that everybody runs the same build and most people share a
        -- rank. So both of those columns are mostly ties, and rows would swap places on every
        -- repaint without a unique secondary. Each sortable column therefore sorts on a composite
        -- `<value>\0<name>` field and DISPLAYS the plain value through the column's `format`, which
        -- RowList documents as display-only. `name` is unique already and sorts on itself.
        entry.rankSort  = tostring(entry.rank  or "") .. "\0" .. entry.name
        entry.shownSort = tostring(entry.shown)       .. "\0" .. entry.name
    end
    return rows
end

VC.window = VC.window or nil

-- What the status bar shows. The TOC version when the standalone addon is loaded -- which is
-- `VersionCheck-v1.5.3` on a dev build, exactly as FGI's status bar shows it -- and the LibStub minor
-- when only an embedded copy is present and there is no TOC of our own to read.
local function LibVersionText()
    local toc = GetAddOnMetadata and GetAddOnMetadata(MAJOR, "Version")
    return "VersionCheck " .. (toc or ("lib r" .. MINOR))
end

-- What the info "i" on the status bar says. The four version-column states are the one thing a
-- user cannot work out from the window alone, so this is where they are explained.
local ROSTER_HELP = "One tab per addon that uses VersionCheck.\n\n"
    .. "Click a column header to sort by it; click again to flip.\n\n"
    .. "Not seen -- in the guild and online, but has never told us a version\n"
    .. "Offline  -- in the guild, not logged in\n"
    .. "Unknown  -- not in the guild roster: a confederation member, or someone who has left\n\n"
    .. "Opening the window and switching tabs send nothing. Refresh asks the guild again."

-- Tooltips for the two bottom-row buttons, in the library's title + body shape. The body says the
-- one thing the caption cannot: what a click costs, and -- for Notify -- who it reaches.
local REFRESH_TIP = "Ask the guild for their versions again.\n\n"
    .. "Counts down for " .. GW_REQ_DEDUP_TTL .. " seconds afterwards: guildmates ignore a repeat "
    .. "request inside that window, so a sooner one would be answered by nobody."
local NOTIFY_TIP  = "Ask the guild again, and tell everyone's VersionCheck to check NOW.\n\n"
    .. "Anyone running an older copy of one of these addons sees the normal update popup "
    .. "immediately, instead of at their next login. Guildmates on an older VersionCheck simply "
    .. "answer as usual.\n\n"
    .. "Shares Refresh's " .. GW_REQ_DEDUP_TTL .. "-second countdown. Guild leadership only."

-- The window itself: LibAceGUIWidgets' ClearFrame with a tab per registered host, a RowList, and a
-- refresh button that grey-outs for as long as peers would ignore us anyway.
--
-- ClearFrame rather than AceGUI's stock Frame, and the difference is not cosmetic. It is the suite's
-- main window -- the same chrome FGI and Dibs open -- and it EXPOSES its bottom bar on the widget
-- table: `statusbg`, `info`, `settings`, `statustext`, `content`. An earlier draft built on the stock
-- Frame and had to reach `statustext:GetParent()` to find the bar and hand-measure Close's geometry
-- to sit a button beside it; every one of those reaches is gone.
function VC:CreateRosterWindow(W)
    local AceGUI = LibStub("AceGUI-3.0")
    local win    = { addonName = SortedHostNames()[1] }

    -- The language server's AceGUI annotation enumerates only the STOCK widget types, so a type
    -- LibAceGUIWidgets registers reads as a mismatch. It is a real registered type (Version 29).
    ---@diagnostic disable-next-line: param-type-mismatch
    local frame = AceGUI:Create("ClearFrame")
    frame:SetTitle("VersionCheck")
    frame:SetStatusText(LibVersionText())
    frame:SetInfoTooltip(ROSTER_HELP)
    frame:SetLayout("Fill")
    win.widget = frame
    -- `.frame` is the raw frame every AceGUI widget carries and every consumer in the fleet reads;
    -- the language server's annotation marks it protected, which is not how AceGUI treats it.
    ---@diagnostic disable-next-line: invisible
    win.frame  = frame.frame

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Fill")
    local tabList = {}
    for _, addonName in ipairs(SortedHostNames()) do
        tabList[#tabList + 1] = { text = addonName, value = addonName }
    end
    tabs:SetTabs(tabList)
    -- Branded so the strip matches the rest of the suite, which is the whole reason this library
    -- was chosen over raw frames.
    if W.BrandTabGroup then W:BrandTabGroup(tabs) end
    tabs:SetCallback("OnGroupSelected", function(_, _, value)
        -- Switching tabs must NOT broadcast. One request already fills every tab, and a request
        -- inside the peer dedup window would be answered by nobody while clearing what we had.
        win.addonName = value
        VC:RefreshRoster()
    end)
    frame:AddChild(tabs)
    win.tabs = tabs

    local function showRank(_, entry)  return entry.rank  or "" end
    local function showShown(_, entry) return entry.shown or "" end
    local list = W.RowList:New(tabs.content or win.frame, {
        rowCount = 20,
        columns  = {
            -- Exactly one column may omit `width`; it takes whatever is left. A second is a
            -- construction-time error in RowList, deliberately, because there is no sensible way to
            -- split the remainder between two.
            --
            -- A `header` string is what makes a column sortable: RowList wires the click itself. The
            -- rank and version columns sort on their composite `*Sort` fields (see BuildRosterRows)
            -- and display the plain value through `format`, which RowList documents as display-only.
            --
            -- 170 wide for the version, because a RELEASED host reports the packager's substitution
            -- of `VersionCheck-v1.5.3`, which is the whole git tag -- `TOGBankClassic-v1.2.3` -- and
            -- 90 truncated every one of them to the addon's own name.
            { key = "name",      header = "Name",    justify = "LEFT", color = "class" },
            { key = "rankSort",  header = "Rank",    justify = "LEFT", width = 100, format = showRank },
            { key = "shownSort", header = "Version", justify = "LEFT", width = 170, format = showShown },
        },
        -- Right-click on a row opens the whisper menu.
        --
        -- From LibAceGUIWidgets MINOR 28 the handler receives the mouse button and the row frame
        -- (thread ddb1caf9af5a, delivered the same hour it was asked). An older embedded copy
        -- passes neither, so both have fallbacks: the button from the client (GetMouseButtonClicked
        -- is valid inside a mouse handler, and Classic Era's restricted environment whitelists
        -- it), and the anchor from the row most recently hovered, which OnEnter delivers before
        -- OnMouseDown can fire on it. Feature-detected per call, like everything else this window
        -- asks of that library, rather than gated on a MINOR.
        onRowEnter = function(_, _, _, rowFrame) win.hoverRow = rowFrame end,
        onRowClick = function(entry, _, _, button, rowFrame)
            button = button or (GetMouseButtonClicked and GetMouseButtonClicked())
            if button == "RightButton" then
                VC:OpenRowMenu(W, win, entry, rowFrame)
            end
        end,
    })
    -- BEFORE SetData, or the first render is not sorted at all -- the only other writer of the sort
    -- is a header click by the user, so an unsorted open stays unsorted until someone clicks. The
    -- version column, so the arrow on the header shows what the list opened sorted by.
    list:SetSort("shownSort")
    win.list = list

    -- Bottom row, right to left: Close, the info "i", Refresh, and -- for guild leadership only --
    -- Notify. Each hangs off the one to its right and the status bar ends at the leftmost.
    win.refresh = VC:CreateBottomButton(W, win, "Refresh", win.widget.info, false, REFRESH_TIP)
    if win.refresh and VC:IsLeadership() then
        win.notify = VC:CreateBottomButton(W, win, "Notify guild", win.refresh, true, NOTIFY_TIP)
    end

    if win.addonName then tabs:SelectTab(win.addonName) end
    return win
end

-- A bottom-row button that broadcasts, and the whole of its rate limiting is LibAceGUIWidgets'
-- named-cooldown machinery rather than anything of ours: `BindCooldownButton` refuses the click at
-- the UI layer, turns the caption into the seconds remaining, dims it and hides the highlight.
--
-- `push` is what separates Refresh from Notify. Refresh asks the guild for versions so THIS window
-- fills in. Notify does the same and additionally asks every receiver to run its own update
-- decision on receipt -- so a guildmate who is behind gets the normal VersionCheck popup now rather
-- than at their next login. Same request, one extra reserved key; see PUSH_KEY.
--
-- BOTH BUTTONS SHARE ONE COOLDOWN, on purpose. The thing being rate-limited is the peers' dedup
-- window, which is keyed on us and does not care which button we pressed; two independent
-- cooldowns would let Notify fire 5 seconds after Refresh and be dropped unread by everyone.
--
-- THE ONE THING THIS DOES NOT DO IS STAMP A COOLDOWN FOR A REQUEST THAT NEVER LEFT. `RequestCheck`
-- returns false when a broadcast this soon would be suppressed by every peer's dedup window, and it
-- can also decline for a reason that has nothing to do with the clock -- a guildless player has no
-- GUILD channel to send on. Stamping regardless would leave the button dead for the dedup TTL having
-- sent nothing, which reads to the user as "I pressed it and it broke".
--
-- `seconds` is a function precisely because the library evaluates it AFTER `onClick`, so it can
-- report what the send actually did; a `seconds` of 0 is documented there as a STOP rather than an
-- error, which is exactly "nothing went out, so nothing is owed".
function VC:CreateBottomButton(W, win, label, leftOf, push, tip)
    if not W.BindCooldownButton then return nil end

    -- Immediately left of `leftOf` on ClearFrame's bottom row, and the status bar is re-anchored to
    -- end at this button -- the same 6 px gap and the same anchor ClearFrame's own
    -- SetSettingsButton uses when IT parks a control there. `info` and `statusbg` are fields
    -- ClearFrame exposes on purpose; nothing here is an internal. The settings gear is not used by
    -- this window, so nothing else will re-anchor the bar.
    local btn = CreateFrame("Button", nil, win.frame, "UIPanelButtonTemplate")
    btn:SetSize(90, 20)
    btn:SetPoint("RIGHT", leftOf, "LEFT", -6, 0)
    win.widget.statusbg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMLEFT", -6, -2)

    -- The library's tooltip shape -- title, then a wrapped body -- attached BEFORE the cooldown
    -- binding, so the hover handlers are on the button whatever the caption is showing. Feature-
    -- detected like everything else asked of the library; an older copy just has no tooltip.
    if W.AttachTooltip then W:AttachTooltip(btn, label, tip) end

    -- The options table is a local rather than an inline argument so the call fits on one line.
    -- A multi-line call puts its CALL opcode on the closing `})`, which the coverage hook never
    -- reports a hit for -- an uncoverable line, in a file the gate holds at 100%.
    -- `wait` is RequestCheck's second return: the seconds until peers would listen again when the
    -- clock refused, 0 when nothing could be sent at all. Counting the button down for `wait` is
    -- the whole reason that value is returned -- the first draft threw it away, so a click inside
    -- the 20 seconds after the login batch did nothing visible at all. A dead click reads as broken.
    local sent, wait = false, 0
    local opts = {
        label   = label,
        onClick = function() sent, wait = VC:RequestCheck(push) end,
        seconds = function() return sent and GW_REQ_DEDUP_TTL or wait end,
        format  = function(n) return n .. "s" end,
    }
    return W:BindCooldownButton(btn, REFRESH_COOLDOWN, opts)
end

-- What a right-click on a row offers. One item, and it says one of three things: whisper them
-- (they are behind), they are up to date, or we have no version of theirs to compare. Items with
-- no onClick are LibAceGUIWidgets' informational rows -- clicking one just closes the menu.
function VC:RowMenuItems(entry, addonName)
    -- Our own row first: whispering yourself that you are out of date is not a feature.
    if entry and entry.isSelf then
        return { { text = "This is you" } }
    end
    local behind = VC:IsBehind(entry, addonName)
    if behind == nil then
        return { { text = "No version known for " .. tostring(entry and entry.name) } }
    elseif not behind then
        return { { text = "Up to date" } }
    end
    return {
        {
            text    = "Whisper: " .. tostring(addonName) .. " is out of date",
            onClick = function() VC:WhisperUpdate(entry, addonName) end,
        },
    }
end

-- `rowFrame` is the clicked row when the widget library passes it (MINOR 28+); otherwise the last
-- hovered row, and failing that the window, so a menu always has something to hang off.
function VC:OpenRowMenu(W, win, entry, rowFrame)
    if not (W.OpenMenu and entry) then return nil end
    local anchor = rowFrame or win.hoverRow or win.frame
    return W:OpenMenu(anchor, VC:RowMenuItems(entry, win.addonName), { width = 240 })
end

function VC:ToggleRoster()
    local W = Widgets()
    if not (W and W.RowList) then
        print("[VersionCheck] The roster window needs LibAceGUIWidgets with RowList.")
        return nil
    end

    local win = VC.window
    if win and win.frame and win.frame:IsShown() then
        win.frame:Hide()
        return win
    end
    if not win then
        win = VC:CreateRosterWindow(W)
        VC.window = win
    end
    win.frame:Show()
    VC:RefreshRoster()
    return win
end

-- Repaint from the model. Cheap and idempotent, so every callback can just call it: it sends
-- nothing, which is the property that keeps the window inside the traffic budget.
function VC:RefreshRoster()
    local win = VC.window
    if not (win and win.list) then return false end

    local names = SortedHostNames()
    win.addonName = win.addonName or names[1]

    win.list:SetData(VC:BuildRosterRows(win.addonName), true)
    return true
end

-- ---------------------------------------------------------------------------
-- Legacy compatibility shims
-- Addons calling these directly still work; they re-arm the batch mechanism.
-- ---------------------------------------------------------------------------

function VC:TriggerVersionCheck()
    VCPrint("TriggerVersionCheck (legacy shim): re-arming batch.")
    if not VC.batchFired then return end -- PLAYER_ENTERING_WORLD hasn't fired yet; FireBatch will run automatically
    VC:FireBatch()
end

function VC:SendVersionCheck(_version)
    VCPrint("SendVersionCheck (legacy shim): delegating to TriggerVersionCheck.")
    VC:TriggerVersionCheck()
end

function VC:TriggerVersionCheckForHost(_hostEntry)
    VCPrint("TriggerVersionCheckForHost (legacy shim): delegating to TriggerVersionCheck.")
    VC:TriggerVersionCheck()
end
