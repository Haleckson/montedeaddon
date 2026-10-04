# DeltaSync-1.0

**An embeddable LibStub library for efficient, guild-scoped data synchronization in World of Warcraft Classic Era addons (Lua 5.1).**

DeltaSync handles the hard parts of keeping data in sync across guild members — version comparison, **delta compression** (90–99% bandwidth reduction vs. full re-sends), peer-to-peer catch-up, and CRC message integrity — over AceComm-3.0. It's the sync stack that powers **TOGBankClassic** and **TOGProfessionMaster**, extracted into a reusable library you embed in a few lines.

This is a **library, not an addon**: no GUI, no SavedVariables of its own, no slash commands. All persistent state lives in the host addon and is passed in/out through config callbacks.

---

## Contents

- [Features](#features)
- [Dependencies](#dependencies)
- [Supported game versions](#supported-game-versions)
- [Installing / embedding](#installing--embedding)
- [Quick start](#quick-start)
- [How a sync actually happens](#how-a-sync-actually-happens)
- [Communication channels](#communication-channels)
- [API reference](#api-reference)
  - [Lifecycle](#lifecycle)
  - [Sending](#sending)
  - [Serialization](#serialization)
  - [Delta operations](#delta-operations)
  - [Hashing](#hashing)
  - [Canonical hashes — compute once, at save, and never again](#canonical-hashes--compute-once-at-save-and-never-again)
  - [P2P catch-up](#p2p-catch-up)
  - [Numbered P2P (MINOR 18+, optional)](#numbered-p2p-minor-18-optional)
  - [RosterSync (optional)](#rostersync-optional)
  - [Guild-mode (optional)](#guild-mode-optional)
- [Guild roster queries](#guild-roster-queries)
- [Adoption checklist for consuming addons](#adoption-checklist-for-consuming-addons)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Versioning](#versioning)
- [License](#license)

---

## Features

- **Multi-host** -- `NewHost(config)` returns an isolated per-host object, so multiple addons in one client each run independent sync with no shared state to clobber (v4.0.0+; the legacy `Initialize` singleton remains as backward-compatible sugar).
- **Delta sync** -- transmits only the differences between states, **deletions included** (MINOR 18+: a field the sender removed arrives as a removal, at both the record and the array-entry level); full sync is always available as a fallback for new peers or major changes. The three ways an array diff can go quietly wrong (records keyed by table address, a `keyFields` list that does not cover what `keyFunc` reads, two records sharing one key) are detected at compute time and warned about once; `options.strictKeys` turns them into errors for development builds.
- **Two peer-to-peer catch-up protocols, one per host, your choice:**
  - **Hash P2P** (the default) -- a logging-in player broadcasts its item hashes and any peer whose hash differs steps up. No single "banker" bottleneck; busy peers decline and the next-best peer takes over. What TOGProfessionMaster runs.
  - **Numbered P2P** (MINOR 18+, `mode = "numbered"`) -- for hosts whose items carry a version identity (a *canon*): items are named on the wire by a 4-digit **number** agreed guild-wide, a peer offers only when it holds a **strictly newer** version, offerers are asked *which* version they hold before anyone is asked for data, the fetch goes to the **newest** holders only and **waits in their queue** rather than settling for an older copy, and a busy provider **queues** requests instead of refusing them. The item's **author** is the authority: if the author has already advertised its canon the version query is skipped, and when one runs the author is asked first and its answer settles it (MINOR 20 fixes this for a same-realm author, whom the client names without a realm). MINOR 19+ also offers a key a broadcast leaves out, and holds an offer that arrives before the number table it depends on instead of dropping it. MINOR 22+ reads a peer's numbers only through the table that minted them (`host.numbers:Reads(v)`), so two tables never map one number to two keys; a broadcast numbered on a table not yet held is parked (`ParkBroadcast`) and replayed once it lands. TOGBankClassic's protocol, generalised.
- **Version reporting** -- the standalone DeltaSync addon registers with **VersionCheck-1.0** (MINOR 19+), so guild members see who runs which DeltaSync in `/vc` and players who are behind are told to update. Bundled copies of the library never register.
- **Delivery verdicts** -- every send is checked for whether the client actually accepted it, counted, and reported per send (`onSendComplete`: delivered / refused / not-attempted, exactly once, including sends the library declined before the transport), so a stalled sync is never mistaken for an idle one.
- **CRC wire integrity** -- every message is wrapped with a checksum and a stop-marker, so truncation and corruption are detected separately instead of silently applying garbage.
- **Content hashes that agree across clients** -- deterministic over Lua tables regardless of iteration order, and two logically equal structures hash equal whether or not they share sub-tables. Revision 1 (`ComputeHash`) is frozen because its output is compared between clients; revision 2 (`ComputeHashV2`) additionally tells `1` from `"1"`, and `MakeHashEntry` carries both so a mixed-build guild negotiates the highest revision each pair shares.
- **Auto-generated prefixes** -- 7 unique AceComm prefixes derived from your addon name, so you never pick unique strings yourself. Every protocol above rides those seven; a registration the client *refuses* (`Enum.RegisterAddonMessagePrefixResult.MaxPrefixes` or `InvalidPrefix`) is reported by name instead of becoming a silently dead channel -- working from MINOR 20; earlier revisions tested for a boolean the client never returns, so the report could not fire in game.
- **Pluggable roster, one spelling per player** -- consumes `LibGuildRoster-1.0` for player identity, online state, and the default peer-eligibility check; feature-detected so it degrades gracefully. Every sender your callbacks receive and every peer name in DeltaSync's tables is LibGuildRoster's canonical `Name-Realm` (MINOR 21+), normalised at the comm boundary, so a consumer compares names against the roster directly and never strips or appends a realm itself. The whisper online-guard covers sister-guild members through LibGuildRoster's scoped presence (MINOR 22+), and a sister member who messages you is recorded online. On WoW: Forever, where the server refuses a realm-suffixed whisper target, a WHISPER is addressed as the bare full name (MINOR 23+, through `LibGuildRoster:WhisperTarget`); the name your callbacks and completions see stays `Name-Realm`.
- **Optional modules, all inert until you opt in** -- cross-guild roster sharing (**RosterSync**), a WHISPER-to-GUILD fallback for whisper-broken servers (**Guild-mode**), the guild-wide **item-number table** (`InitNumbers`) the numbered protocol is built on, and a **CHANNEL transport** for addons that must use a custom chat channel (which must be named; a nameless CHANNEL prefix is refused rather than listening everywhere). Modules claim their own directed traffic through **leaf-type routing** (`RegisterLeafType`), so a host's data callbacks never see another module's QUERY/RESPONSE messages.
- **Diagnostics you can route into your own addon** -- `host:DebugStatus()` prints identity, prefixes, channel config, whether P2P is loaded, roster readiness and the delivery counters in one block. Debug output is organised by category and tag with per-tag toggles and an optional chat tab; register your own categories into it (`RegisterDebugCategory`), take logging over entirely (`config.logger`), or tap every line into your persistent log (`config.onDebugMessage`). `GetPrefixInfo` / `GetPeerStates` / `GetCommStats` expose the same state to a debug panel.
- **Supported everywhere the client runs** -- one TOC covers Classic Era, World of Warcraft: Forever, TBC/Wrath/Cata/Mists Classic and Retail; see [Supported game versions](#supported-game-versions).
- **Offline test suite** -- 722 specs on the shared WoWAPITesting harness. Every peer is a simulated client with its **own** copy of DeltaSync, LibGuildRoster and the real Ace3 comm stack (AceComm, ChatThrottleLib, AceCommQueue), so two- and three-peer syncs run end to end through the real libraries over the harness's wire -- GUILD to the sender's guild, WHISPER to the named player, senders spelled as the client spells them. 100% line coverage of every reachable line, and the eight lines that cannot execute are listed individually with the reason.

## Dependencies

All declared as hard `## Dependencies` in the TOC, so WoW loads them before DeltaSync; CurseForge auto-installs them:

| Dependency | Role |
| --- | --- |
| **Ace3** | provides LibStub, AceComm-3.0, AceSerializer-3.0, AceTimer/AceEvent, CallbackHandler |
| **AceCommQueue-1.0** | serializes outgoing messages so chunked payloads don't interleave and corrupt each other (embedded by your host addon) |
| **LibGuildRoster** (`LibGuildRoster-1.0`, MINOR 6+) | the guild-roster engine — identity, online state, sister-roster store. The sister-guild send guard (MINOR 22) uses `IsInAnyRoster`, `GetOnlineMembersScoped` and `MarkOnline`, each feature-detected, so an older copy skips that guard rather than failing. Forever whisper addressing (MINOR 23) uses `WhisperTarget` (LibGuildRoster 1.1.2, MINOR 29) and falls back to the client's own `RegionalUniqueNamesEnabled()` check without it |
| **VersionCheck-1.0** | lets guildmates see which DeltaSync version each player runs, and prompts out-of-date players to update |

## Supported game versions

One package and one TOC cover every flavour. `DeltaSync.toc` declares `## Interface: 11509, 16001, 20506, 30405, 38000, 40402, 50504, 120005, 120007, 120100` -- Classic Era, **World of Warcraft: Forever** (v4.2.1+; the Classic Era beta on the modern client, Battle.net product `wow_classic_beta`), Burning Crusade Classic, Wrath Classic, Cataclysm Classic, Mists Classic and Retail (three current retail builds, v4.4.0+, so retail does not mark DeltaSync -- or an addon that requires it -- out of date). `## Category: Library` (v4.4.0+) files it under Library, beside the fleet's other libraries and with its title in the same orange (`|cffFF8000Lib: DeltaSync|r`), in the in-game addon list on clients whose list reads that field (Classic Era and live do). `38000` is the build the **Whitemane** private server reports (the reason [Guild-mode](#guild-mode-optional) exists) and is deliberate; it is not a stale Wrath value. The library is developed and tested on Classic Era; the other flavours load and are believed to work but are not exercised by the author. Nothing has yet run on a Forever client. Forever characters have no realm, and the server refuses a whisper addressed to `First Last-Realm` (seen by a FastGuildInvite player as repeated "No player named ..." lines); since v4.4.1 DeltaSync addresses every WHISPER there without the realm, and leaves every other flavour's addressing unchanged. One Forever property is known and not yet handled: the beta forgets SavedVariables between sessions, so a host's persisted baseline is empty on every login.

## Installing / embedding

DeltaSync is published on CurseForge as a **nolib library addon**, so consuming addons embed it. In your addon's `.pkgmeta`:

```yaml
externals:
  libs/DeltaSync-1.0:
    url: https://repos.curseforge.com/wow/deltasync   # or vendor the source
```

…and load it from your TOC **before** your own files. Declare the runtime dependencies so they load first:

```text
## Dependencies: Ace3, VersionCheck-1.0, AceCommQueue-1.0, GuildRoster
```

DeltaSync's own files load in this order, from `DeltaSync.toc`. If you vendor the library, list files 1-8 in this order; every file after the first errors at load if `DeltaSync.lua` has not registered the library yet:

1. `DeltaSync.lua` -- core: channel config, prefixes, (de)serialization, send/receive
2. `DeltaSyncChannel.lua` -- optional CHANNEL transport (`SendChatMessage`)
3. `DeltaOperations.lua` -- delta compute/apply
4. `P2PSession.lua` -- hash P2P session manager, and the send-slot accounting both P2P protocols share
5. `DeltaSyncRoster.lua` -- optional RosterSync module
6. `DeltaSyncGuildMode.lua` -- optional Guild-mode module
7. `DeltaSyncNumbers.lua` -- optional item-number table (MINOR 18+)
8. `DeltaSyncP2PNumbered.lua` -- optional numbered P2P protocol (MINOR 18+); needs file 4 first
9. `DeltaSyncVersionCheck.lua` -- **not part of the library.** The standalone addon's VersionCheck-1.0 registration (MINOR 19+). Do not vendor it: it would report a DeltaSync version from inside your addon

## Quick start

```lua
-- In your addon's OnInitialize / OnEnable:
local AceAddon     = LibStub("AceAddon-3.0")
local AceCommQueue = LibStub("AceCommQueue-1.0")
local DeltaSync    = LibStub("DeltaSync-1.0")

-- 1. Your AceAddon instance must embed AceComm and AceCommQueue.
local MyAddon = AceAddon:NewAddon("MyAddon", "AceComm-3.0")
AceCommQueue:Embed(MyAddon)

-- 2. Create your isolated DeltaSync host (v4.0.0+). Hold the returned handle and
--    call every DeltaSync method on it. NewHost registers your comm channels for
--    you. The callbacks may reference `host` since they only fire later.
local host
host = DeltaSync:NewHost({
    namespace = "MyAddon",
    aceAddon  = MyAddon,   -- REQUIRED — DeltaSync sends through your addon
    onVersionReceived = function(sender, version, hash)
        if hash ~= MyAddon.currentHash then
            host:RequestData(sender, MyAddon:GetBaseline())
        end
    end,
    onDataRequest = function(sender, baseline)
        host:SendData(sender, MyAddon:GetData(), false)   -- or a computed delta
    end,
    onDataReceived = function(sender, data, len)
        MyAddon:Apply(data)
    end,
})
```

```lua
-- Announce your state to the guild
host:BroadcastVersion(myVersion, myHash)

-- Respond to a request
host:SendData(sender, myData,  false)   -- full sync
host:SendData(sender, myDelta, true)    -- delta sync
```

## How a sync actually happens

Worth reading once — most integration bugs come from wiring the callbacks in the wrong order rather than from any single API call.

**The simple case (two peers, one of them has newer data):**

1. You call `host:BroadcastVersion(myVersion, myHash)`. Every guild member running your addon gets `onVersionReceived(sender, version, hash)`.
2. A peer notices its hash differs from yours and calls `host:RequestData(you, itsBaseline)`.
3. Your `onDataRequest(sender, baseline)` fires. You reply with `host:SendData(sender, data, isDelta)` — full data, or a delta you computed against the baseline they sent.
4. Their `onDataReceived(sender, data, len)` fires. They apply it. Done.

**Every `sender` your callbacks receive is canonical `Name-Realm`** (MINOR 21+) -- the spelling LibGuildRoster keys its roster by -- whether the client delivered it bare (a same-realm player) or qualified. Compare it directly against `LibGuildRoster:GetMember` keys, `GetNormalizedPlayer()`, and the peer names in `host.p2p` tables; never strip or append a realm yourself. (Before MINOR 21 the P2P tables were canonical but the transport callbacks passed the client's spelling through, so a consumer had to normalise before comparing.)

**The P2P case (a player logs in missing several items and nobody is the designated "banker"):**

```text
T+0        you    → GUILD    BroadcastItemHashes(myHashes)     "here is everything I have, and its hashes"
T+0..W     peers  → you      hash-offer (whisper)              "my hash for item X differs — I can serve it"
T+W        you    → provider sync-request (whisper)            "send me X" — one provider per item, least-loaded first
handshake  peer   → you      sync-accept | sync-busy           busy → you try the next candidate automatically
delivery   you    → provider RequestData(...)                  your onSyncAccepted fires; ask for the payload
           peer   → you      SendData(...)                     their onDataRequest fires; they answer
complete   you              p2p:OnItemCompleted(key, sender)   YOU MUST CALL THIS — it frees the session slot
```

`W` is `collectWindow` (default 10s). Three things are easy to get wrong:

- **`OnItemCompleted` is not optional.** Nothing else frees the inbound session slot. Miss it and after three items your peer stops requesting anything until the 180-second delivery watchdog reclaims the slots.
- **On the provider side, call `p2p:ReleaseSendSlot(requester)`** once your send completes. A safety timer releases it after 90s regardless, but until then that slot is spent.
- **Merge content-aware, not timestamp-aware.** Since MINOR 9 a peer offers whenever its hash *differs*, not when it is newer — so you can legitimately receive an older copy. Use max-wins for monotonic values and union for sets, and convergence takes care of itself.

## Communication channels

Each consuming addon gets 7 auto-generated prefixes of the form `{shortName}-{suffix}` (`shortName` = first 6 alphanumeric lowercase chars of the addon name). Defaults can be overridden per-channel via `config.channels`:

| Channel   | Suffix | Default dist | Default priority | Purpose                                   |
|-----------|--------|--------------|------------------|-------------------------------------------|
| VERSION   | `v`    | GUILD        | NORMAL           | Version/hash-list broadcast               |
| DATA      | `d`    | GUILD        | BULK             | Full data sync payload                    |
| QUERY     | `q`    | WHISPER      | NORMAL           | Requester sends baseline → provider       |
| RESPONSE  | `r`    | WHISPER      | NORMAL           | Query response / no-change signal         |
| DELTA     | `x`    | WHISPER      | NORMAL           | Computed delta reply                      |
| OFFER     | `o`    | WHISPER      | NORMAL           | Hash-offer (or GUILD hash-list broadcast) |
| HANDSHAKE | `h`    | WHISPER      | NORMAL           | sync-request / sync-accept / sync-busy    |

Every message is a checksum-wrapped envelope: `<AceSerializer payload>\030<checksum>\031END`.

**On the "16 prefixes" number.** Earlier versions of this README said DeltaSync's 7 channels spend 7 of "WoW's 16-prefix budget". That was wrong: AceComm's 16 is a prefix-string **length** limit (`if #prefix > 16 then error(...)`, [AceComm-3.0.lua:61](../Ace3/AceComm-3.0/AceComm-3.0.lua#L61)), not a count. Blizzard does cap how many prefixes a client may register, but the exact number for Classic Era 1.15.x is **not verified here** — treat it as unknown rather than 16. What matters practically is that AceComm discards `RegisterAddonMessagePrefix`'s return value, so hitting any cap yields messages that silently never arrive; DeltaSync checks that return itself and reports a refusal by name. Thanks to TOGBankClassic's library audit for catching the error.

Override any channel's `distribution` (`GUILD` / `RAID` / `PARTY` / `WHISPER` / `CHANNEL`) and `priority` (`ALERT` / `NORMAL` / `BULK`) via `config.channels` in `NewHost`/`Initialize`, or at runtime with `SetChannelConfig(type, config)`. `CHANNEL` distribution uses a named chat channel (`SendChatMessage`) for realm-wide/cross-guild reach and requires the optional `DeltaSyncChannel.lua`, a `channel` name in that channel's config, **and** `config.channelModule = { enabled = true, serializer = fn(payload) -> string|nil, deserializer = fn(message, sender) -> payload|nil }` on `NewHost`. Without `channelModule.enabled` no `CHAT_MSG_CHANNEL` receiver is installed, so a CHANNEL prefix can send but never receives. The client caps these messages at 255 bytes, which is what the compact serializer is for; a `nil` from it drops the message.

## API reference

All instance methods are called on the **host** returned by `NewHost` (or, under the legacy `Initialize` sugar, on the `DeltaSync-1.0` LibStub handle directly). Roster queries are the exception — they live on `LibGuildRoster-1.0` (see below).

### Lifecycle

- `NewHost(config)` → `host` (v4.0.0+) — creates an isolated per-host object. `config` takes `namespace` (string), `aceAddon` (**required** AceAddon handle), optional `channels`, `channelModule` (the CHANNEL transport, see [Communication channels](#communication-channels)), `debug = { enabled, addonName, savedVariables, categories }`, `logger`, `onDebugMessage`, and the `onVersionReceived` / `onDataRequest` / `onDataReceived` / `onOfferReceived` / `onSendFailed` / `onSendComplete` callbacks. `onOfferReceived(sender, data)` sees every decoded OFFER message **before** the P2P code acts on it (MINOR 19+; it ran after before that), so it is the place to record what a message says about its sender. Registers the comm prefixes for you. Multiple hosts coexist fully isolated. (`hashStrategy` is accepted and ignored — deprecated, pending removal.)
- `Initialize(config)` — backward-compatible sugar: same `config`, but inits onto the shared handle (an implicit default host). A lone consumer is unaffected; two consumers on `Initialize` clobber each other, so prefer `NewHost`.
- `RegisterCommChannels()` — registers the AceComm prefixes; called automatically by `NewHost`/`Initialize` (rarely called directly).
- `GetChannelConfig(type)` / `SetChannelConfig(type, config)` — read/update a channel's `distribution` + `priority` at runtime.
- `DebugStatus()` — prints a diagnostic block (namespace, MINOR, prefixes, wiring).
- `InitP2P(config)` -- the P2P session manager; `config.mode = "numbered"` (MINOR 18+) selects the numbered protocol, anything else the hash protocol. See [P2P catch-up](#p2p-catch-up) and [Numbered P2P](#numbered-p2p-minor-18-optional).
- `InitNumbers(config)` (MINOR 18+) -- the guild-wide item-number table at `host.numbers`; required before `InitP2P({ mode = "numbered" })`.
- `InitRosterSync(config)` / `InitGuildMode(config)` -- the other optional modules, below.

### Did my message actually arrive? (MINOR 17+)

**WoW silently discards addon messages under congestion.** AceComm-3.0 forwards only ChatThrottleLib's `didSend` boolean, and everything else — a refusal because you're not in a guild, a channel throttle, a bad target — is dropped with no error. If nobody checks, a refused message is indistinguishable from a delivered one, and a sync that has quietly stopped working looks identical to one that's idle.

DeltaSync checks on every send and records the result on the host:

| Field | Meaning |
| --- | --- |
| `host.sendsDelivered` | count of sends the client accepted in full |
| `host.sendFailures` | count of sends the client **refused** — those messages did not arrive |
| `host.lastSendFailure` | `{ prefix, channelType, distribution, target, bytes, reason, at }` for the most recent refusal, or `nil` -- the same table `onSendFailed` receives |
| `host.sendsNotAttempted` | count of sends that **never happened** — see the three states below |
| `host.lastSendNotAttempted` | `{ prefix, channelType, distribution, target, reason, at }`, or `nil` |

Add `config.onSendFailed` to be told at the moment it happens, so you can re-send, degrade, or warn the user rather than assume delivery:

```lua
host = DeltaSync:NewHost({
    namespace = "MyAddon",
    aceAddon  = MyAddon,
    onSendFailed = function(info)
        MyAddon:Warn("Sync message to %s was refused — it did not arrive", tostring(info.target))
    end,
})
```

`host:DebugStatus()` prints `sends: delivered=N refused=N not-attempted=N`, the last refusal, the last not-attempted send with its reason, and whether AceCommQueue is embedded. A non-zero **refused** count is usually the fastest answer to "why isn't sync working".

**Three things worth knowing, because they surprise people:**

- **A failure is a `false` verdict, or a `nil` verdict with `reason` `"rejected"` or `"error"`; any other `nil` is not-attempted.** AceCommQueue-1.0 v1.0.5+ supplies a fifth `reason` argument, and it matters because *three different situations* share the `nil` verdict:

  | `delivered` | `reason` | DeltaSync counts it as |
  | --- | --- | --- |
  | `true` | — | delivered |
  | `false` | `"refused"` | **failure** — the client refused it |
  | `nil` | `"rejected"` | **failure** — bad argument; the message never went out |
  | `nil` | `"error"` | **failure** — the send raised |
  | `nil` | `"suppressed"` | *not attempted* — your wrapper did this on purpose |
  | `nil` | *(absent)* | *not attempted* — an older queue can't tell us; we don't guess |

  `"suppressed"` and an absent reason stay out of `sendFailures`. Counting it would give an addon with a raid-guard wrapper a forever-climbing error count for behaving correctly. `"rejected"` and `"error"` are logged as **defects** rather than a busy client, because they indicate a bug rather than congestion.
- **A refusal is message-level, not chunk-level.** If any chunk of a multipart send was refused, the whole message failed: a partial stream reassembles into a corrupt payload on the receiver. DeltaSync never counts a partially-refused send as delivered.
- **It is a boolean, not an enum.** AceComm discards ChatThrottleLib's `Enum.SendAddonMessageResult`, so there is no way to learn *why* the client refused — only that it did.

If your addon embeds **AceCommQueue-1.0** (it should — see the note in the [adoption checklist](#adoption-checklist-for-consuming-addons)), that library also retries a refused send 3× with backoff before reporting failure, so a `false` verdict means it already tried and gave up. DeltaSync handles both the queued and unqueued callback shapes; you don't need to care which you have, but `DebugStatus` will tell you.

#### Per-send completion (MINOR 18+)

`onSendFailed` reports refusals only, and `sendsDelivered` is a counter with no identity. A host that meters its own sends -- a P2P provider that took a slot on accept and must give it back when the reply has **drained**, not when it was queued (under AceCommQueue a BULK snapshot drains over up to ~70 s) -- needs to know, per send, that it reached a terminal state. Two ways to get that, both carrying the same `info`:

```lua
-- Per call: an optional trailing argument on SendMessage / RequestData / SendData.
host:SendData(requester, payload, false, "BULK", function(info)
    host.p2p:ReleaseSendSlot(requester)           -- the reply has left the client
end)

-- Host-wide: every send, after the per-call callback.
host = DeltaSync:NewHost({ ..., onSendComplete = function(info) ... end })
```

`info = { prefix, channelType, distribution, target, bytes, at, verdict, reason, unverified }`. The contract:

- **Exactly one completion per send**, whatever happened -- under the unqueued shape the transport fires per chunk; you still get one.
- **`verdict`** is `"delivered"` (every chunk accepted), `"refused"` (the client refused after the queue's retries, or the queue rejected the call / the send raised -- either way the message did **not** arrive), or `"not-attempted"` (nothing was sent, and that was not a defect). When an older AceCommQueue gives no reason, `reason` is `nil` on the completion too (MINOR 22; before that it read `"suppressed"`, a cause nobody had reported).
- **`target` is the target as you passed it**, so you can key on it.
- **A send DeltaSync declines before the transport reports too**, as `not-attempted` with a `reason` naming the guard: `target-offline` (the roster online-guard), `unknown-channel`, `no-channel-target`, `no-send-api`. So a caller waiting on a completion never waits on one that cannot come.
- **`unverified = true`** marks the two transports that have no delivery callback at all -- the CHANNEL transport's `SendChatMessage` and the raw `SendAddonMessage` fallback -- where the verdict is read from the synchronous return and means "the client accepted the call", not "somebody received it". Under AceComm it is `nil`.

A callback that raises is routed to `geterrorhandler()` and does not take the transport down.

**Logging — pick one, don't build two.** DeltaSync ships a debug system (category/tag filtering, a chat tab, a buffer, SV persistence). If your addon has one too, resolve the duplication rather than running both:

- **Adopt DeltaSync's** (recommended) — register your own categories and log through it. One tab, one registry, and because DeltaSync is shared across many addons, every consumer's diagnostics end up in the same shape:

  ```lua
  host:RegisterDebugCategory("STORE", { SCAN = "local data scans", MERGE = "peer merge decisions" })
  host:Debug("STORE", "SCAN", "scanned %d records", n)
  ```

  Registered categories behave exactly like the built-in `INIT` / `COMMS` / `DELTA` / `P2P` ones, and are per-host.

- **Or take it over** — pass `config.logger` and DeltaSync hands you every line's raw arguments, then stops filtering, buffering and claiming a tab:

  ```lua
  host = DeltaSync:NewHost({ namespace = "MyAddon", aceAddon = MyAddon, logger = MyAddon.Output })
  ```

  Accepts a function or any object with a `:Debug(fmt, ...)` method. Choose this only if you already own a logger for other reasons (levels, user-facing `Info`/`Warn`/`Error`) — not to avoid registering categories.

**Persistence and export stay yours either way.** DeltaSync's buffer is session-only, in-memory, capped at 1000 messages, with no export — it never writes messages to SavedVariables. Retention costs *your* SV file, so it's your policy to set. If you keep a persistent log, take a copy through the tap:

```lua
onDebugMessage = function(message, category, tag) MyAddon.Output:PersistToLog(message, category, tag) end
```

`config.onDebugMessage` fires **alongside** DeltaSync's own tab and buffer (unlike `logger`, which replaces them), receives the structured category and tag as well as the text, skips anything your filtering suppressed, and routes a throwing sink to `geterrorhandler()` rather than swallowing it.

### Sending

- `BroadcastVersion(version, hash[, distribution, priority])`
- `RequestData(target, baseline[, priority[, onComplete]])` (MINOR 18+: optional per-send completion, see above)
- `SendData(target, data, isDelta[, priority[, onComplete]])`
- `BroadcastData(data[, distribution, priority])` → `ok, byteSize` (MINOR 14+: second return is the serialized payload size)
- `BroadcastItemHashes(items[, priority])` → `ok, byteSize` (MINOR 14+) / `SendHashOffer(target, items[, priority])` / `SendHandshake(target, payload[, priority])` (hash P2P)
- `BroadcastNumbered([priority[, extra]])` -> `ok, byteSize` (MINOR 18+, numbered P2P) -- the numbered counterpart of `BroadcastItemHashes`

### Serialization

- `SerializeBaseline` / `DeserializeBaseline` — baseline `{hash, version, keys, type, parent}`
- `SerializeData` / `DeserializeData` — arbitrary data tables
- `SerializeWithChecksum` — raw checksum-wrapped envelope

### Delta operations

- `ComputeArrayDelta` / `ApplyArrayDelta`
- `ComputeStructuredDelta` / `ApplyStructuredDelta`
- `ValidateDelta` / `GetDeltaStats`

**Four keying rules worth reading before you diff arrays.** The first three used to fail silently; since MINOR 16 they report themselves, and `options.strictKeys` turns them into errors.

1. **Records need a stable key.** With no `options.keyFunc`, records are keyed by `id` / `ID` / `key` / `name`, falling back to the table's *address*. Addresses are stable neither across sessions nor between clients, so every diff would report everything added and everything removed and never converge. **Positional records (`{id, count, suffix}`) have none of those fields — always pass a `keyFunc` for them.**

2. **No two records in the new array may share a key.** Two records claiming the same identity is a source-data defect the engine can't resolve. The last one is kept and one entry is emitted — but two clients whose array order differs would otherwise keep *different* records and re-sync forever, so de-duplicate before diffing.

3. **`keyFields` must cover every field your `keyFunc` reads.** A removal is reduced to just `keyFields` on the wire, and the receiver re-keys that reduced entry. Drop a field the key depends on and the removal matches nothing, so deleted items linger forever:

```lua
-- WRONG — the key needs suffix, but the removal entry won't carry it
{ keyFunc = function(o) return o.id .. ":" .. o.suffix end, keyFields = { "id" } }

-- RIGHT
{ keyFunc = function(o) return o.id .. ":" .. o.suffix end, keyFields = { "id", "suffix" } }
```

And a fourth, which is about the same `keyFunc`: **key from the record's fields, never from the index.** `keyFunc` receives a second `index` argument only when the record sits in an array being scanned; for a `removed` or `modified` delta entry on the receiving side it is `nil`. A key that reads it computes differently on the two sides and removals silently never match -- and positional identity is not stable across clients in any case.

**Deletions are transmitted (MINOR 18+).** Lua cannot store `nil` in a table, so before MINOR 18 a field the sender deleted was detected and then dropped by the assignment `changes[field] = nil` -- the receiver kept it forever and both sides believed they were in sync. The format now has a tombstone at both levels:

- A structured delta carries a top-level `removed = { fieldName, ... }` beside `changes`, and `ApplyStructuredDelta` nils each.
- A `modified` array entry carries `_removed = { fieldName, ... }` (`lib.REMOVED_FIELDS_KEY`), which `ApplyArrayDelta` consumes **before** calling your `mergeFunc` -- a custom merge never sees it. Do not use `_removed` as a record field name.

Both lists are omitted when nothing was deleted, so a delta with no deletions is byte-identical on the wire to one from an older build. `GetDeltaStats` counts them under `removed`, and `ValidateDelta` checks them. **Mixed builds:** an older receiver ignores the top-level list and its default merge copies `_removed` onto the record as an inert field -- it keeps the stale field either way, exactly as it did before. While builds are mixed, a pre-18 client keeps disagreeing with upgraded peers on that record's hash and re-syncing it until it upgrades -- exactly as it already did for any deleted field before this release; the inert `_removed` key adds nothing to a divergence the stale field already caused. Nothing is lost; some bandwidth is spent until the last client upgrades.

### Hashing

- `ComputeHash(value)` — revision 1 content hash. **Frozen**; stable across clients regardless of table iteration order.
- `ComputeHashV2(value)` — revision 2 (MINOR 16+). Same algorithm, but each scalar carries its type.
- `MakeHashEntry(value, updatedAt)` — builds a P2P hash-list entry carrying **both** revisions. Use this.
- `ComputeArrayHash(items)` / `ComputeStructuredHash(sections)` — shortcuts for `{ID=, Count=}` arrays and named sections.

Revision 1 renders a number and its string form identically, so `{v = 1}` and `{v = "1"}` hash the same (likewise `true` and `"true"`). If a field in your data can hold either type, that difference is invisible and the sync is skipped. Revision 2 fixes it.

**Both revisions ship side by side, so there is no flag day and nothing to coordinate.** Build your hash-list entries with `MakeHashEntry` and DeltaSync handles the rest:

```lua
getMyHashes = function()
    local out = {}
    for key, value in pairs(myData) do
        out[key] = host:MakeHashEntry(value, value.updatedAt)
    end
    return out
end
```

Each entry then carries `hash` (revision 1) *and* `hashV2`, and `P2PSession` compares on **the highest revision both ends advertise**:

| Your peer | Their peer | Compared on | Result |
| --- | --- | --- | --- |
| new build | new build | revision 2 | type collisions caught |
| new build | old build | revision 1 | agrees — no phantom differences |
| old build | new build | revision 1 | agrees — old peers ignore the extra field |

An un-upgraded peer simply never sends `hashV2`, and its absence *is* the signal to fall back. Upgrade your guild one player at a time; the collision fix switches itself on for each pair as both ends arrive.

Because consumers call `MakeHashEntry` rather than picking a revision themselves, **retiring revision 1 later costs them nothing**: drop `hash` from the entry and delete the fallback, and no call site changes.

The same pattern is available on the VERSION channel, where *you* own the comparison: `BroadcastVersion(version, hash, distribution, priority, hashV2)` sends both, and `onVersionReceived(sender, version, hash, hashV2)` delivers both — compare on `hashV2` only when both you and the sender have one.

### Canonical hashes — compute once, at save, and never again

The functions above tell you *how* to hash. This section is about *when*, and it matters more. Get it wrong and the sync misbehaves in ways that look like transport bugs and aren't.

A hash is not a checksum you recalculate whenever you need one. **It is the identity of a version of a record** — and identity only works if every client holding that version reports the same number. That is achievable in exactly one way: the number is produced **once, by the client that authored the version**, stored **on the record**, and carried along with it thereafter.

#### The rules

1. **Generate the hash at SAVE time**, in the editor's client, at the moment the change is committed. That is the only place a hash is ever produced.
2. **Store it on the record**, so it travels with the data it describes.
3. **The version identity must distinguish two publishes of identical content.** A hash identifies a *publish event*, not just a payload -- two saves of coincidentally identical content are two different versions, and the identity has to be able to say so. Two spellings satisfy this, and which one you want depends on what else the hash does for you:
   - **Datestamp inside the hashed input** (the example below). Simplest when every save is a new version.
   - **A composite canon: `<publish time><content hash>`**, with the content hash computed over the payload *alone*. This is the one to use when the content hash is also your **change detector** -- "only bump the version if the content actually moved". Feeding the datestamp into that hash would make every save look like a change, so keep it out and carry the time *beside* it, stamped in the same save. TOGBankClassic's 20-digit canon is this shape.

   What the rule forbids is an identity that *cannot* tell two publishes apart -- not one particular way of building it.
4. **Everywhere else, read and forward.** Advertising a hash list, building a query baseline, answering a peer, receiving a record -- all of these *carry* the hash. None of them computes one.
5. **A receiver stores the author's hash verbatim**, even if it could recompute it, and even if it looks wrong. It is the author's statement about their own version.
6. **Never maintain a second version identity that can DRIFT from the first.** The datestamp still *travels* -- rule 7 needs it at apply time, and the example below forwards `updatedAt` beside the hash. What is forbidden is a version marker that is written by a different code path, at a different moment, or from a different input than the hash, because the moment the two disagree the behaviour depends on which one the code happened to consult. Stamp both in one place, in one operation, and forward both together.
7. **Ordering is a different question from identity.** The hash says *whether* two clients differ; it cannot say whose is newer. Decide that at apply time, from the timestamp **inside the record that arrived** -- one rule, in one place.

#### Why — the failure modes each rule prevents

| If you… | What happens |
| --- | --- |
| recompute on read or send | The number can drift between clients for the same logical data — one side wrote a field the other never did, or stored a count as text. Two clients that agree perfectly report different hashes and diverge **permanently**. |
| recompute on receipt | You overwrite the author's statement with your own opinion of their data. Now nobody is authoritative and every client can disagree with every other. |
| compute at send time | The hash changes when nothing changed. Peers see churn on every broadcast and re-sync data they already have. |
| leave the datestamp out of the identity | Two distinct publishes with identical content collide as one version. A guild reports "converged" across a change that really happened. |
| hash the datestamp when the hash is also your change detector | Every save is a new version whether or not anything moved -- a banker closing an unchanged bank republishes guild-wide. Use the composite canon instead (rule 3). |
| maintain a version marker that can drift from the hash | Version identity now lives in two fields written by two code paths. The moment they disagree -- and they will -- the behaviour depends on which one the code happened to consult. Forwarding a timestamp stamped in the same save as the hash is not this; a second timestamp bumped by a refresh helper is. |
| decide ordering on the provider side | The "who wins" rule now exists in two places and drifts apart. Keep it at the apply step, where the record and its timestamp are both in hand. |

The recurring symptom of getting this wrong is the worst kind: **a sync that reports itself healthy while clients run different data.** Hashes match when they shouldn't, or mismatch forever when they shouldn't, and no error is ever raised.

#### What it looks like

```lua
-- SAVE — the one and only place a hash is generated.
function SavePolicy(record)
    record.setAt       = time()          -- stamp the datestamp FIRST…
    record.contentHash = nil             -- …exclude the field from its own input…
    record.contentHash = host:ComputeHashV2(record)   -- …then stamp the canon.
end

-- ADVERTISE — forwarded, not computed.
getMyHashes = function()
    local r = myRecord
    if not (r and r.contentHash) then return {} end   -- no canon → advertise nothing
    return { policy = { hash = r.contentHash, hashV2 = r.contentHash, updatedAt = r.setAt } }
end

-- ANSWER A QUERY — one comparison, because one number is the whole answer.
onDataRequest = function(sender, baseline)
    if myRecord and myRecord.contentHash == baseline.hash then return end  -- same version
    host:SendData(sender, { record = myRecord })   -- differs: let THEM decide if it wins
end

-- RECEIVE — stored verbatim, ordering decided here and only here.
onDataReceived = function(sender, data)
    local incoming = data.record
    if (incoming.setAt or 0) >= (myRecord and myRecord.setAt or -1) then
        myRecord = incoming        -- contentHash rides along; never re-derived
    end
end
```

A record that carries no canon (saved before you adopted this, or never published) should **advertise nothing** rather than a number invented on the spot. "I have no version to offer" is true and harmless; a fabricated one is neither.

#### Checking yourself

Grep your addon for assignments to the hash field. There should be **exactly one**, in your save path. Anything else — a refresh helper, a "make sure it's up to date" call before sending, a UI file recomputing to compare — is a bug, and it is worth an automated test that asserts the count, because this is the kind of rule that erodes one well-meaning call site at a time.

A good test plants a deliberately *wrong* value in the hash field, runs every read/send/receive path, and asserts the wrong value survived. Comparing against the correct hash instead is a weaker test: a path that quietly recomputes produces the right number and passes.

### P2P catch-up

`InitP2P(config)` enables the broadcast/collect/dispatch session manager. Config callbacks:

```lua
host:InitP2P({
    -- {itemKey → {hash, hashV2, updatedAt}} — build entries with MakeHashEntry so
    -- both hash revisions ride along and mixed-build guilds keep agreeing.
    getMyHashes     = function()
        local out = {}
        for key, value in pairs(myData) do
            out[key] = host:MakeHashEntry(value, value.updatedAt)
        end
        return out
    end,
    hasContent      = function(key)     return myData[key] ~= nil     end,
    hasMissingItems = function()        return nextMissing ~= nil     end,
    onSyncAccepted  = function(key, sender) host:RequestData(sender, myBaseline) end,
    isValidPeer     = function(name)    return true end,  -- rank/role filter
})
host:BroadcastItemHashes(myItemHashes)
```

The full-data callbacks (`onDataRequest` → `host:SendData`, `onDataReceived` → apply) are the ones you passed to `NewHost`. Tunables, each an optional `InitP2P` key with its default: `collectWindow` 10s, `maxActiveSessions` 3 (inbound), `maxActiveSends` 3 (outbound), `retryDelay` 20s, `catchUpDelay` 45s, `maxCatchUpCycles` 5, `deliveryTimeout` 180s. The dispatch timeout (15s), the outbound safety release (90s) and the retry-cycle count (5) are fixed. Host signals completion via `host.p2p:OnItemCompleted(itemKey, sender)` / `:OnItemFailed(...)` / `:ReleaseSendSlot()`.

### Numbered P2P (MINOR 18+, optional)

A second, opt-in P2P protocol -- TOGBankClassic's P2P-035, generalised -- for hosts whose items have a **canon** (a version identity, `<10-digit publish time><10-digit content hash>`) and a **change detector** of their own. It names items by a 4-digit **number** agreed guild-wide, offers only when strictly newer, asks offerers *which* version they hold before asking anyone for data, fetches from the newest holders only, and **queues** rather than refuses when a provider is at capacity. Hosts that do not ask for it get the hash protocol above, unchanged.

Two modules, two init calls, in this order:

```lua
-- 1. The number table. Storage is YOURS: three fields (numbers, numbersNext,
--    numbersVersion) are written onto the table you return. Numbers are minted
--    alphabetically, for life, only by clients you say may mint; peers converge
--    on one table by version over the HANDSHAKE channel.
host:InitNumbers({
    table   = function() return MyAddon.db.numbers end,
    keys    = function() return MyAddon:ItemKeys() end,        -- every key eligible for a number
    canMint = function() return MyAddon:OwnsAnItem() end,
    -- optional: normalize(key), me(), canonTime(canon) -> time|nil, onChanged(reason), onExhausted(key)
})

-- 2. The protocol.
host:InitP2P({
    mode          = "numbered",
    servableCanon = function(key) return MyAddon:CanonICanServe(key) end,   -- REQUIRED
    onDeliver     = function(key, canon, provider)                          -- REQUIRED: the data leg
        host:RequestData(provider, { type = "leaf-data", parent = key, hash = MyAddon:HeldCanon(key) })
    end,
    -- optional judgement: heldCanon(key), canServe(key), canonImproves(key, canon), isOwnKey(key)
    -- optional gates:     isValidPeer(name), peerCapable(name) -> ok, why
    -- optional catch-up:  hasMissingItems() -> bool; default false, and while it is false
    --                     the library never re-broadcasts on its own
    -- optional observers: onAdvertised(key, canon, peer), onNewerOffered(key, peer),
    --                     onNewerCleared(key), onSelfConsulted(reason)
    -- optional (MINOR 19+): broadcastExtra() -> table, merged into the library's own
    --                     catch-up broadcasts the way BroadcastNumbered's `extra` is into yours
    -- every timing constant is overridable: collectWindow, dispatchTimeout, deliveryTimeout,
    -- sendTimeout, versionQueryMax, versionQueryWindow, maxSessionsPerPeer, maxActiveSends,
    -- stateWait, queueTtl, maxRetryCycles, retryCycleDelay, catchUpDelay, maxCatchUpCycles
})
host:BroadcastNumbered("BULK", { addon = MyAddon.version })   -- instead of BroadcastItemHashes
```

**The provider's data leg** has one more step than the hash protocol, because the accept carries a promise the reply must keep: in your `onDataRequest`, call `host.p2p:QueryArrived(requester, key)` first -- `true` claims the slot the accept granted, `false` means no accept covers this query and you should not send a BULK reply outside the handshake. Then either `host.p2p:ServeReply(requester, key, data, isDelta)` (a `SendData` whose DS-009 completion releases the slot when the reply has **drained**) or `host.p2p:ReplyNoChange(requester, key)`.

**What the observers are for**, since each is a real consumer need: `onAdvertised` fires from *every* message that names a canon for a key -- broadcasts, version replies -- including keys you author, so a shared account on two PCs learns from it that it is behind on its own character; `onNewerOffered` / `onNewerCleared` bracket the interval where a peer has claimed newer but nothing has landed yet (a tab colour, typically); `onSelfConsulted` fires once the first cycle has settled what the guild holds for your own keys (`host.p2p:IsSelfConsulted()` reads it; `MarkSelfConsulted(reason)` lets your own fallback force it). `peerCapable` is a callback rather than a lookup inside the library because the verdict is consumer memory -- release skew, a peer that behaved like an old wire -- that the library cannot have.

**Three delivery rules added in MINOR 19** (raised by TOGBankClassic from its live guild and its throttled test fleet): a key a broadcast does **not** list is one its sender holds nothing for, so it is offered back like a newer one -- with our number table sent first when the broadcaster is behind on it; a bare offer naming numbers our table cannot resolve yet is **parked** and replayed the moment a table that resolves them lands, because on a real wire the one-chunk offer overtakes the multi-chunk table; and `onOfferReceived` fires **before** the protocol judges an OFFER, so what a broadcast says about its sender (an `addon` version for `peerCapable`) is known before that sender is judged. A raising `onOfferReceived` is reported through `geterrorhandler()` and does not stop the protocol.

**Detecting a library too old for those rules.** CurseForge's required dependency guarantees DeltaSync is *installed*, not *current*. If your addon relies on the MINOR 19 delivery rules -- say you deleted your own stand-ins for them -- feature-detect `host.p2p.OnNumbersChanged` on your numbered instance (or compare `LibStub("DeltaSync-1.0").MINOR >= 19`). `OnNumbersChanged(reason)` is the method the number table calls on every mint and adopt to replay parked offers; its name is kept stable for exactly this use, because TOGBankClassic warns its players on its absence.

Wire, all on existing prefixes: `hlb2 { v, e }` on OFFER/GUILD (a run of 24-char `<number><canon>` entries), `hash-offer2 { v, n }` on OFFER/WHISPER (a run of bare numbers), `ver-query { v, n }` / `ver-reply { v, e, n }`, `sync-request { sessionId, itemKey, canon, requester }`, `sync-accept`, `sync-queued { position }`, `sync-busy { reason }` (`"version"` = "not this candidate", never "wait"), `sync-cancel`, and `numbers-request` / `numbers-reply` on HANDSHAKE.

Every `v` is the sender's numbers-table version, and a message's numbers are read only through a table that minted them: our own version, or one our table extends by minting. A broadcast or offer from a peer AHEAD of us is parked until we adopt their table and replayed then (`p2p:ParkBroadcast`); a peer BEHIND us is sent our table and, if it broadcast, offered every key we serve. A broadcast naming numbers we cannot resolve on our own table is acted on in part and replayed in full once they resolve -- after our own re-mint, so the offer-back includes the keys we just numbered. `onNewerCleared` fires on completion, on "nobody holds newer", when a fetch session fails, and when a queried peer answers from another table (its canons are not read, so it counts as holding nothing). An unasked numbers table goes to any one peer at most once per `REQUEST_COOLDOWN` (30s).

### RosterSync (optional)

Cross-guild "sister roster" sharing for confederated guilds, over the existing WHISPER channels (no new prefix, no broadcast). Inert until `InitRosterSync` is called.

```lua
host:InitRosterSync({
    onSisterRosterUpdated = function(guildKey) --[[ persist + refresh ]] end,
    -- optional: isValidPeer(name) -- who may pull OUR roster. Scoped to RosterSync only,
    -- independent of the P2P isValidPeer; accepts everyone when omitted.
})
host:RequestRosterSync(peerName)   -- peerName from your /who discovery of an online allied-guild member
```

DeltaSync writes membership (`LibGuildRoster:SetSisterRoster`); your addon owns presence (its `/who` poll → `LibGuildRoster:MarkOnline`) and persistence (re-feed `SetSisterRoster` from your SavedVariables on login). Single round trip, provider-authoritative guild key.

### Guild-mode (optional)

For private/emulated servers (e.g. **Whitemane**) that don't deliver addon messages over WHISPER. A user toggle that reroutes the five directed channels (QUERY/RESPONSE/DELTA/OFFER/HANDSHAKE) from WHISPER to GUILD, stamping each directed send with its intended recipient so every other guild member drops it on receipt — directed behaviour over a broadcast transport. Inert until `InitGuildMode` is called.

```lua
-- Once, after NewHost() — restore the persisted toggle and persist future flips:
host:InitGuildMode({
    enabled   = MyAddonDB.guildMode,
    onChanged = function(on) MyAddonDB.guildMode = on end,
})

-- Wire your settings checkbox to:
host:SetGuildMode(true)   -- reroute WHISPER → GUILD (and back on false)
host:IsGuildMode()        -- current state
```

The **host owns the settings UI and persistence** — the library ships no GUI/SavedVariables/slash commands. Notes: it's a broadcast (every member receives + reassembles before dropping, so keep directed payloads small); RosterSync self-disables while active (cross-guild whisper can't work on whisper-dead servers); the offline-member guard applies to directed GUILD sends too.

## Guild roster queries

Roster lookups are **not** on the DeltaSync handle — they live on `LibGuildRoster-1.0`:

```lua
local GuildRoster = LibStub("LibGuildRoster-1.0")
GuildRoster:IsOnline(name); GuildRoster:GetOnlineMembers(); GuildRoster:GetMember(name)
GuildRoster.RegisterCallback(self, "OnMemberOnline", function(_, name) ... end)
```

## Adoption checklist for consuming addons

**If you are starting fresh, read [Quick start](#quick-start) instead — this section is for addons that already embed DeltaSync.** Everything below is additive: nothing here forces a change, and an addon that ignores this entire section keeps working exactly as it does today. The point is to make it obvious which capabilities you are *not yet using*, and what each one costs to adopt.

Nothing in this list is specific to any particular addon. DeltaSync knows nothing about your data model — it moves opaque tables between guild members and calls you back. If your addon needs guild-scoped sync of *anything* (inventories, professions, rosters, attendance, DKP, crafting queues), the integration is the same.

Check what revision you have first:

```lua
local DS = LibStub("DeltaSync-1.0")
print(DS.MINOR)          -- 23 as of v4.4.1
```

| # | Capability | Since | If you do nothing | To adopt |
| --- | --- | --- | --- | --- |
| 00000 | **Forever whisper addressing** | MINOR 23 | Works -- on WoW: Forever a WHISPER goes to `First Last` instead of `First Last-Realm`, which the server refused. Every other client is addressed exactly as before, and callbacks and completions still carry `Name-Realm` | Nothing. If your addon sends its own whispers to a DeltaSync sender, address them through `LibGuildRoster:WhisperTarget(name)` too |
| 0000 | **Numbers read only through their own table; `ParkBroadcast`; `onNewerCleared` on a failed fetch; sister-guild send guard** | MINOR 22 | Works -- a numbered host stops misreading numbers across tables, a guild's first sync is replayed instead of wasted, and `onNewerCleared` now also fires when a fetch fails. A directed send to a sister-guild member LibGuildRoster does not see online completes `not-attempted` / `target-offline` | Delete any stand-in that parked broadcasts (feature-detect `host.p2p.ParkBroadcast`). If your UI treated `onNewerCleared` as "the item arrived", treat it as "the offer is over" |
| 000 | **Canonical `Name-Realm` senders in every callback** | MINOR 21 | Works -- but `onDataReceived` / `onDataRequest` / `onVersionReceived` / `peerCapable` / `onAdvertised` / `onNewerOffered` now receive `Bob-Realm` where a same-realm peer used to arrive as `Bob`. A consumer that compared the raw sender to a bare name, or that appended the realm itself, sees a different string | Delete any sender normalisation of your own; compare callback senders directly against LibGuildRoster keys and `host.p2p` peer names. Nothing to do if you already normalised through LibGuildRoster (idempotent) |
| 00 | **Numbered P2P: unmentioned keys offered, unresolved offers parked, `onOfferReceived` first, `broadcastExtra`** | MINOR 19 | Works -- a numbered host gets the first three for free. `onOfferReceived` now runs before P2P on every OFFER, both protocols | Delete any host-side stand-in for them. Pass `broadcastExtra` if your `BroadcastNumbered` carries `extra` fields, so catch-up broadcasts carry them too |
| 0 | **`config.onSendComplete` / trailing `onComplete`** | MINOR 18 | Works -- you learn about refusals (item 5) but not about WHICH send finished | If you meter your own sends (a provider giving back a slot when the reply has drained), release from the completion, not from `SendData`'s return |
| 0a | **Deletions propagate** | MINOR 18 | Works -- and a field you delete now reaches peers instead of lingering on them. No call-site change; see the mixed-build note under [Delta operations](#delta-operations) | Nothing. If your `mergeFunc` is custom it never sees the `_removed` marker; do not use `_removed` as a record field name |
| 0b | **`InitNumbers` + `InitP2P({ mode = "numbered" })`** | MINOR 18 | Inert -- you keep the hash protocol | Only if your items carry a canon (a version identity) and you want TOGBank's newest-holder-only, queue-not-refuse protocol; see [Numbered P2P](#numbered-p2p-minor-18-optional) |
| 1 | **`NewHost` instead of `Initialize`** | MINOR 15 | Works — *unless a second addon in the client also calls `Initialize`, in which case you clobber each other* | `host = DS:NewHost{…}`, then call everything on `host` |
| 2 | **`MakeHashEntry` for P2P hash lists** | MINOR 16 | Works — you keep revision-1 hashing and its type collision | Build `getMyHashes` entries with `host:MakeHashEntry(value, updatedAt)` |
| 3 | **`RegisterDebugCategory`** | MINOR 16 | Works — but if you own a debug tab too, players get two | Register your categories, delete your tab/buffer/registry |
| 4 | **`config.logger`** | MINOR 16 | Works — DeltaSync keeps its own tab | Pass your logger *only if you already own one for other reasons* |
| 5 | **`config.onSendFailed`** + the delivery counters | MINOR 17 | Works — refused sends are already counted and logged, but nothing tells you at the moment it happens | Add the callback to re-send, degrade, or warn the user; optionally surface `host.sendsDelivered` / `sendFailures` / `sendsNotAttempted` in your own diagnostics |
| 6 | **`config.onDebugMessage`** | MINOR 16 | Works — DeltaSync's diagnostics stay in its session-only buffer and never reach your persistent log | Take a copy into your own log/export if you keep one |
| 7 | **`options.strictKeys`** | MINOR 16 | Works — keying mistakes warn instead of erroring | Pass `strictKeys = true` in development builds |
| 8 | **`prefixRegistrationFailed`** | MINOR 16 (fires in game from MINOR 20) | Works — a refused prefix is reported in chat automatically | Optionally surface `host.prefixRegistrationFailed` in your own diagnostics |
| 9 | **Send-size second return** | MINOR 14 | Works — you ignore the extra value | `local ok, bytes = host:BroadcastData(…)` |
| 10 | **`RegisterLeafType`** | MINOR 12 | Works — all traffic goes to your data callbacks | Claim a `type` prefix to route a sub-protocol without spending new prefixes |
| 11 | **`InitRosterSync`** | MINOR 12 | Inert | Only if you need cross-guild rosters |
| 12 | **`InitGuildMode`** | MINOR 13 | Inert | Only if your players are on a whisper-broken server |

**One thing that is not optional:** your addon must embed **AceCommQueue-1.0** on the AceAddon instance you hand to `aceAddon`, *after* AceComm and after any `SendCommMessage` wrapper of your own. Without it, AceComm hands all of a large message's chunks to ChatThrottleLib at once and a second message on the same prefix can interleave, corrupting the receiver's spool — the CRC failures the envelope then reports are a symptom, not the cause. `host:DebugStatus()` says plainly whether the queue is embedded.

### Auditing your addon in a few minutes

Grep your own source for these signals:

| Grep for | Means |
| --- | --- |
| `DS:Initialize` / `DeltaSync:Initialize` | Item 1 — check whether any *other* addon in the client also does this |
| `getMyHashes` | Item 2 — are the entries hand-built `{hash=…, updatedAt=…}`? |
| `CreateDebugTab`, `AddMessage`, a category/tag table | Items 3–4 — you have a second debug system |
| A persistent debug log or an export/report command | Item 6 — DeltaSync's own diagnostics are missing from it |
| `ComputeArrayDelta`, `ApplyArrayDelta` | Item 7 — and read the four keying rules under [Delta operations](#delta-operations) |
| `BroadcastData(`, `BroadcastItemHashes(` | Item 9 |
| `AceCommQueue`, `ACQ:Embed` | Not optional — see the note above the audit table |

### Behaviour changes you get whether you adopt anything or not

**v4.4.1** -- on WoW: Forever only, every WHISPER is addressed without the realm; see adoption item 00000.

**v4.4.0** -- under every existing consumer, with no call-site edit:

- **Numbered hosts read a peer's numbers only through a table that minted them.** A broadcast or offer on a newer table waits until that table is adopted; a peer on an older table ours did not grow from is sent ours and, if it broadcast, is offered every key we serve. Expect a burst of offers and version queries to such a player, instead of wrong fetches -- and an `onNewerOffered` on every key it is offered until each version query answers.
- **Mixed builds:** a pre-22 requester asking a MINOR 22 peer on another table gets an empty `ver-reply`, which it cannot tell from "holds nothing", so it can clear an offer that peer could have served. It resolves once both are on MINOR 22.
- **`onNewerCleared` fires when a numbered fetch session fails, or when a queried peer answers from another numbers table**, not only on completion or "nobody holds newer". A later genuine offer raises `onNewerOffered` again.
- **Directed sends to a sister-guild member LibGuildRoster does not see online are declined** (`target-offline`), and every sister-guild sender you hear from is recorded online in LibGuildRoster (`MarkOnline`), so replies to them still go out.
- **A `not-attempted` completion carries `reason = nil` when the queue gave none**, where it used to read `"suppressed"`.
- **`GetCommStats().peerCount` counts peers.** It was always 0, because it took the length of a table keyed by name.

**v4.3.0** -- every `sender` your callbacks receive is canonical `Name-Realm`; see adoption item 000.

**v4.2.0** -- three things change under every existing consumer, with no call-site edit:

- **`onOfferReceived` now runs BEFORE the P2P code acts on an OFFER message**, on both protocols. It used to run after, which contradicted the documentation. If your hook assumed the P2P instance had already recorded the offer when it ran, it no longer has. A hook that raises is reported through `geterrorhandler()` and no longer stops anything.
- **Numbered hosts offer keys a broadcast leaves out** (the sender holds nothing for them), with the number table sent first to a broadcaster behind on it, and **park** a bare offer whose numbers the table cannot resolve yet instead of dropping it. Expect more `hash-offer2` whispers after a guildmate's broadcast, and a sync that starts when the table lands rather than on the next catch-up cycle.
- **The standalone DeltaSync addon registers with VersionCheck-1.0** and now requires it. An addon that bundles the library files is unaffected: the registration lives in `DeltaSyncVersionCheck.lua`, which is not a library file.

**v4.1.0** -- five things change under every existing consumer, with no call-site edit:

- **A deleted field now propagates.** Before, a field you removed from a record (or a top-level field you removed from a structured payload) was detected and then dropped before sending, so every peer kept it forever while reporting itself in sync. It now arrives as a removal. While builds are mixed, a pre-18 peer keeps re-syncing that record until it upgrades -- exactly as it already did for any deleted field.
- **Aliased sub-tables hash like copies.** `{ x = T, y = T }` and `{ x = T, y = copy(T) }` used to hash differently, so peers offered each other data across a difference that did not exist. Fixed in both hash revisions; a plain tree's revision-1 value is unchanged.
- **`HandleSyncRequest` now applies `isValidPeer`.** A sync request from a peer your filter rejects is answered `sync-busy` and takes no send slot. If your `isValidPeer` is stricter than you remembered, you may see requests refused that used to be served.
- **`ReleaseSendSlot` accepts any spelling of the requester** -- bare, `Name-Realm`, or the transport's -- and matches the slot that was acquired. A host that was releasing under the "wrong" spelling and stalling for 90 seconds stops stalling.
- **A CHANNEL-distributed prefix must name its channel.** `channel = ""` is refused at init; a wildcard must be spelled `channel = "*"`.

**v4.0.3** — delivery accounting is automatic. `host.sendsDelivered` / `sendFailures` / `sendsNotAttempted` populate on every send with no config change, and `DebugStatus()` reports them. Nothing about *sending* changed; you simply now have an answer to "did it arrive". Two things to know:

- **A refused send is logged plainly** (*"the message did NOT arrive"*) rather than as a soft warning. If your addon broadcasts on `GUILD` while the player is guildless, you will start seeing that line — it was always happening, it just wasn't visible.
- **`P2PSession`'s 180s delivery watchdog has *not* been re-tuned**, and that is deliberate. AceCommQueue-1.0 v1.0.5+ retries a refused message with a doubling backoff and holds its queue for the duration, which under sustained refusal can compound toward the watchdog. The right number needs a real measurement under the new behaviour; guessing a larger one would only move the cliff. If you drive heavy P2P traffic, this is the knob to watch.

**v4.0.2** — two bug fixes in the P2P session layer, so they apply to any addon calling `InitP2P`:

- **Outbound send slots are now capped correctly.** A stale safety timer used to release a slot belonging to a *later* send, so `maxActiveSends` was silently exceeded under load. You may now see fewer concurrent sends — that is the cap working as configured. If you had tuned `maxActiveSends` around the old behaviour, re-check that number.
- **The offer collect window now actually extends.** Re-opening it used to leave the original deadline armed, dispatching early *and* a second time. It now dispatches once, at the extended deadline, having collected more offers.

None of these needs a code change.

### What is *not* changing

- `ComputeHash` (revision 1) is **frozen** and byte-identical. Its output is compared between clients, so it can never change.
- The wire envelope `<payload>\030<checksum>\031END` and the checksum function are frozen for the same reason.
- No API has been removed, renamed or reordered in the 4.x line. (v4.2.0 moved *when* `onOfferReceived` fires relative to P2P; MINOR 21 changed the *spelling* of every callback's `sender` to canonical `Name-Realm` -- see item 000 above; MINOR 22 made a reason-less `not-attempted` completion carry `reason = nil`; signatures and argument order are unchanged.) Every addition is a new function, a new config key, or a trailing parameter — so upgrading the library never breaks a consumer's calls, and two consumers on different MINORs interoperate on the wire.

## Testing

DeltaSync ships an **offline unit-test suite** -- 722 specs covering all eight library files and the VersionCheck bootstrap, running in milliseconds with no game client. Line coverage is 100% of every reachable line; the eight lines the gate still reports are documented as unreachable by construction (a guard whose every caller cannot pass the value it guards against, a prefix-truncation branch the 6+1 prefix shape can never reach, a body shadowed by a later file in load order). It is built on the shared [WoWAPITesting](https://github.com/Pimptasty/WoWAPITesting) harness, included here as a git submodule.

```sh
git clone --recurse-submodules https://github.com/Pimptasty/DeltaSync
# (or, in an existing clone)
git submodule update --init Tests/wowapi
```

Run it from the addon root. No LuaRocks, no busted, no C modules — just a Lua 5.1 interpreter:

```sh
lua Tests/wowapi/run.lua                       # the whole suite
lua Tests/wowapi/run.lua Tests/p2p_spec.lua    # one file
busted                                         # or real busted, if you have it
```

Line coverage, exact (read from Lua bytecode debug info, not guessed from source text):

```sh
lua Tests/run_coverage.lua                    # every library file, gated at 99.77% (see below)
COVERAGE_MIN=100 lua Tests/run_coverage.lua   # the strict gate: shows the eight exempt lines
lua Tests/wowapi/coverage.lua DeltaOperations.lua   # the harness tool directly, one target
```

| Spec file | Covers |
| --- | --- |
| `smoke_spec.lua` | the environment itself — real AceSerializer + LibGuildRoster load, one peer's real AceComm whispers another's over the harness wire |
| `codec_spec.lua` | the checksum envelope: round trip, corruption, truncation, legacy pre-CRC peers |
| `prefix_spec.lua` | prefix generation, the 16-byte limit, cross-addon collisions |
| `config_spec.lua` | host init, channel defaults, config validation |
| `hash_spec.lua` | content hashing and its cross-client determinism |
| `delta_spec.lua` | array + structured delta compute/apply round trips, validation, stats |
| `comms_spec.lua` | send routing, the offline guard, every `OnComm_*` handler, leaf-type routing |
| `multihost_spec.lua` | `NewHost` isolation and the legacy default host |
| `p2p_spec.lua` | the full session lifecycle: collect, dispatch, handshake, retry, slots, catch-up |
| `guildmode_spec.lua` | recipient stamping and inbound filtering |
| `roster_spec.lua` | RosterSync request/serve/apply, including a real cross-guild exchange |
| `channel_spec.lua` | the `SendChatMessage` transport |
| `debug_spec.lua` | the debug system, and every degrade-without-LibGuildRoster path |
| `loadorder_spec.lua` | TOC-order guards and LibStub upgrade safety |
| `integration_spec.lua` | two and three real peers completing a sync end to end through the real Ace3 comm stack |
| `numbers_spec.lua`, `numbered_p2p_spec.lua` | the item-number table and the numbered protocol, three-peer scenarios included |
| `deletion_spec.lua`, `hash_aliasing_spec.lua`, `sendslots_spec.lua` | the v4.1.0 peer-review fixes, each pinned red-first |
| `versioncheck_spec.lua` | the standalone addon's VersionCheck-1.0 registration, against the real VersionCheck |
| `coverage_exemptions_spec.lua` | the exemption table above still points at the code it excuses |

**Every peer is a real client.** `env.newHost{ player = "Bob" }` creates a harness client (`wow.client`) and loads that player's OWN DeltaSync, LibGuildRoster, AceCommQueue and VersionCheck on the client's own LibStub registry, under a real AceAddon with AceComm and AceCommQueue embedded. Sends go out through the real ChatThrottleLib onto the harness wire, which delivers GUILD to every online client in the sender's guild (sender included) and WHISPER to the named client only, and each receiver's real AceComm dispatches to its own DeltaSync. The old hand-written loopback network and its LibGuildRoster state-swap were deleted in v4.2.2 once the harness carried this (contracts threads 37f9b220 / eb10e337). One stub remains on purpose: hosts created without a `player` use a fake AceComm object that models the delivery-callback shapes of AceComm-3.0 and of older AceCommQueue revisions, which the installed real library can no longer produce; those hosts never touch the wire.

The environment models the WoW API **faithfully rather than conveniently** — `C_Timer.After` returns nothing (only `NewTimer` gives you a cancellable handle), a GUILD addon message is echoed back to its own sender, and a same-realm sender arrives on the wire as `UnitName("player")` spells it, bare. Each exists because a friendlier stub would hide real bug classes: the first caught the timer defect fixed in v4.0.2, and the third caught two defects in v4.2.2 that the old realm-qualifying network had masked -- and is what makes the MINOR 21 boundary canonicalisation testable at all (a network that already qualified every sender could never show whether the library does).

### Coverage: the eight lines deliberately left uncovered

The harness tool reports `3562/3570 (99.78%)`; `Tests/run_coverage.lua` sets the bar at **99.77%**, chosen so that one more missed line fails it at today's size (re-derive as `(executable - 8) / executable`, rounded down, when the library grows). The eight lines are **unreachable by construction, not untested** -- each one was checked by reading every caller (and, for a name assigned in more than one file, the load order first). Listed so nobody re-derives this. `Tests/coverage_exemptions_spec.lua` reads this table and fails, naming the row, if a recorded line no longer holds the recorded code -- so when code moves, update the number here and the suite goes green again.

| File | Line | Code | Why it cannot execute |
| --- | --- | --- | --- |
| `DeltaSync.lua` | 476 | `prefix = string.sub(prefix, 1, MAX_PREFIX_LENGTH)` | `GenerateShortName` always returns exactly 6 chars and the suffix is 1, so a prefix is always 8 -- never over the 16 limit. A spec asserts the outcome. |
| `DeltaSync.lua` | 489 | `return 0` | `ComputeChecksum`'s non-string guard. Both call sites pass an AceSerializer result. |
| `DeltaSync.lua` | 525 | `return "nil"` | `SerializeForHash(nil)`. A Lua table never yields a nil value from `pairs`. |
| `DeltaSync.lua` | 2009 | `self.p2p:Init(config)` | `P2PSession.lua` unconditionally redefines `lib:InitP2P` later in load order, so this body only runs when that file is absent -- in which case `self.p2p` is false and the line above raises. Dead by construction; pinned by `loadorder_spec.lua` and `comms_spec.lua`. |
| `DeltaSync.lua` | 2087 | `return nil` | `AceSerializer:Serialize` never returns nil. |
| `DeltaSync.lua` | 2557 | `return` | `if not frame` after `frameIndex` was found by indexing that very frame. |
| `DeltaOperations.lua` | 36 | `return index` | `BuildIndex(nil)`. `ComputeArrayDelta` does `oldArray = oldArray or {}` before either call. |
| `DeltaOperations.lua` | 117 | `return obj1 == obj2` | `ObjectsEqual` on two non-tables. Every call site guards so at least one side is a table; a non-table on the other side hits the type-mismatch return first. |

Two `return`-after-`error()` lines that used to be on this list were deleted in v4.1.0 rather than excused.

`Tests` is excluded from the packaged zip via `.pkgmeta`, so none of it reaches players.

## Troubleshooting

| Symptom | Usual cause |
| --- | --- |
| Nothing is ever sent | `aceAddon` was omitted from the config. It is required — DeltaSync sends through *your* AceAddon instance. `host:DebugStatus()` prints `aceAddon: NIL` in red. |
| Messages send but never arrive | Two consumers both called `Initialize`. There is only one default-host slot and the second clobbers the first — migrate to `NewHost`. |
| Sync stalls after exactly 3 items | `p2p:OnItemCompleted(itemKey, sender)` is not being called, so no inbound session slot is ever freed. |
| Sync silently stops working | Check `host:DebugStatus()` for `refused=N`. The client is rejecting your sends — commonly broadcasting on `GUILD` while not in a guild. Those messages never arrived. |
| Whispers vanish on a private server | The realm doesn't deliver addon whispers. That is what [Guild-mode](#guild-mode-optional) is for. |
| Peers loop, re-syncing the same item forever | Your merge is timestamp-based. Merge content-aware (max-wins / union) — see [How a sync actually happens](#how-a-sync-actually-happens). |
| CRC mismatches under load | Outgoing sends aren't queued. Your host addon must `LibStub("AceCommQueue-1.0"):Embed(MyAddon)` right after `NewAddon`. |

`host:DebugStatus()` prints identity, prefixes, channel config, whether P2P is loaded and roster readiness — start there, and paste it into any bug report.

## Versioning

Two distinct version numbers:

- **Package version** (`## Version` in the TOC, e.g. `v4.0.0`) — the CurseForge release tag, semver. New API surface → minor; breaking API/wire change → major.
- **LibStub MINOR** (integer in `DeltaSync.lua`) — the library revision LibStub compares when multiple addons embed a copy; the highest wins. Because the highest MINOR present serves *every* consumer in the client, feature-detect rather than assuming the revision you shipped with:

  | Detect | Gets you |
  | --- | --- |
  | `MINOR >= 12` | `InitRosterSync`, `RegisterLeafType` |
  | `MINOR >= 13` | `InitGuildMode` |
  | `MINOR >= 14` | the send-size second return from `BroadcastData` / `BroadcastItemHashes` |
  | `MINOR >= 15` | multi-host `NewHost` |
  | `MINOR >= 16` | `ComputeHashV2`, `MakeHashEntry`, `RegisterDebugCategory`, `config.logger`, `config.onDebugMessage`, `options.strictKeys`, `prefixRegistrationFailed` |
  | `MINOR >= 17` | delivery verdicts — `sendsDelivered` / `sendFailures` / `sendsNotAttempted`, `config.onSendFailed` |
  | `MINOR >= 18` | `InitNumbers` and `host.numbers`, `InitP2P({ mode = "numbered" })`, `BroadcastNumbered`, per-send completion (`config.onSendComplete` / trailing `onComplete`), deletions in deltas (`removed`, `lib.REMOVED_FIELDS_KEY`) |
  | `MINOR >= 19` | numbered P2P: `broadcastExtra`, unmentioned keys offered back, parked offers, `host.p2p.OnNumbersChanged`; `onOfferReceived` fires before P2P; the standalone addon registers with VersionCheck-1.0 |
  | `MINOR >= 20` | no new symbols -- two fixes: `prefixRegistrationFailed` actually fires in game (reads `Enum.RegisterAddonMessagePrefixResult`), and numbered P2P recognises a same-realm author |
  | `MINOR >= 21` | no new symbols -- every callback `sender` is canonical `Name-Realm` (`NormalizeSender` canonicalises through LibGuildRoster at the comm boundary) |
  | `MINOR >= 22` | `host.p2p.ParkBroadcast` (numbered) -- a broadcast our table cannot read yet is held and replayed; numbers are read only through the table that minted them (`host.numbers:Reads(v)`); `ver-query` / `ver-reply` carry `v`; `onNewerCleared` also fires when a fetch session fails; directed sends to an offline sister-guild member complete `target-offline`, and an inbound sister sender is `MarkOnline`d in LibGuildRoster; `GetCommStats().peerCount` counts peers (it was always 0) |
  | `MINOR >= 23` | no new symbols -- a WHISPER is addressed without the realm on regional-unique-name clients (WoW: Forever), through `LibGuildRoster:WhisperTarget` |

  Testing for the symbol works just as well and reads better: `if host.MakeHashEntry then`, `if lib.NewHost then`.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

MIT — see [LICENSE](LICENSE).

Author: **Pimptasty** (Ian Plamondon). Questions or bugs: [Discord](https://discord.com/invite/bY2R5TmBSz).
