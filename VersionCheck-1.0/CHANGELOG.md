# VersionCheck-1.0

## [v1.5.3] (2026-09-29) -- WoW Forever regional names, brand-coloured title, replication-script guard (MINOR 17)

MINOR **16 -> 17**: player identity and whisper targets change on WoW Forever, so an embedded copy
of 17 must win LibStub registration over a copy of 16. **405 specs green, 770/770 executable lines
(100.00%)**. Nothing changes on any other client: every new branch is gated on the client's own
`RegionalUniqueNamesEnabled()`, which is absent everywhere but Forever.

### Fixed -- WoW Forever's "First Last" names (FastGuildInvite `833800a6`)

On Forever a character is `First Last`, unique across the region, with no realm. Four things were
wrong there. `SelfName` sent `First-Realm` in `__from`: `UnitName`'s first return plus an internal
realm, with the surname missing. `PeerKey` kept AceComm's `-Realm` suffix, so a peer never matched
their roster row. `QualifyName` appended our realm to the RSP and `RequestFrom` whisper targets, and
the server refuses those (`No player named ... is currently playing`). `WhisperUpdate` sent to the
stored name unmodified. The fix, all gated on `RegionalUniqueNamesEnabled()`:

- `SelfName` builds the name from `UnitName("player")`'s two returns, joined with the engine's
  `CHARACTERNAME_SURNAME_SEPARATOR` (`" "` when the client does not define one). It does not ask
  the roster library, because older copies of it answer `First-Realm`.
- `PeerKey` drops a realm suffix after the roster library's `CanonName`. That is a no-op on a
  LibGuildRoster new enough to do it itself.
- `QualifyName` drops the realm instead of adding ours. `WhisperUpdate` now goes through it too.
- `TransportIdentity` prefers the transport's sender over `__from`, because a pre-17 peer's
  `__from` is the first name alone.
- Like LibGuildRoster, a hyphen surname separator leaves names untouched.

`Tests/forever_spec.lua` covers each path, plus two specs pinning that the switch set to false
behaves exactly like the switch absent. Not verified in a Forever client. The internal realm
spelling of a sender comes from FastGuildInvite's player reports, not from a measurement of mine.

### Changed -- TOC title in the fleet's brand colour (DeltaSync `9e1172c1`)

`## Title: |cffFF8000Lib: VersionCheck-1.0|r`. `## Category: Library` was already present.

### Fixed -- `Tests/push_spec.lua` built our own name from `GetRealmName()` (Peer Review `1dafe6d7`)

It passed only because the harness realm has no space. It now uses `GetNormalizedRealmName()`, the
spelling the library itself sends.

### Fixed -- `wow-version-replication.ps1` could delete a live file from every replica (TOGProfessionMaster `1da2daf9`)

A save-by-replace raises Deleted and Created/Changed for one save, in either order. `Sync-File` now
treats a Deleted event as Changed while the source file still exists. Dev tooling only; not shipped.

## [v1.5.2] (2026-09-27) -- a login warning for a missing required library, names qualified with the normalized realm, retail 120005/120007 (MINOR 16)

MINOR **15 -> 16**: two library behaviour changes (a chat line at login when a required library is
absent; names qualified with the normalized realm), so an embedded copy of 16 must win LibStub
registration over a copy of 15. **387 specs green, 750/750 executable lines (100.00%)** on the run
after the last change, on harness `bd91de2`. The TOC gains the two missing retail numbers -- see
below; the dependency lines are unchanged, see the withdrawn item at the end of this section.

### Fixed -- names were qualified with the realm's DISPLAY name, space included (Peer Review `1dafe6d7`)

`SelfName`'s fallback and `QualifyName` built `Name-Realm` from `GetRealmName()`, which keeps the
space: on Old Blanchy that is `"Bob-Old Blanchy"`, a name the client never produces. Measured by the
operator on Old Blanchy, 2026-09-20: `GetRealmName()` is `"Old Blanchy"`, `GetNormalizedRealmName()`
is `"OldBlanchy"`, and AceComm senders, the unit popup (`UnitPopupUtils.lua`) and LibGuildRoster all
use the second. The cost: a same-realm guildmate on an older copy was keyed `"Bob-Old Blanchy"` and
never merged with the roster's `"Bob-OldBlanchy"` row, and without the roster library we named
ourselves on the wire under the spaced form. Both now call `GetNormalizedRealmName()`, which every
flavour tree carries (`PlayerScriptDocumentation.lua`, including `forever`). Two specs in
`Tests/identity_spec.lua` stub a spaced realm and fail on the old code; every earlier spec ran on a
realm with no space, which is why 385 green specs could not see it.

`Tests/env_vc.lua` stands in `GetNormalizedRealmName` (off the harness's own `normalizeRealm`) because
the harness's base env does not define it -- only its opt-in guild layer does. Requested on writ's
harness channel; delete the stand-in when it lands.

### Changed -- TOC declares retail 120005 and 120007 (FastGuildInvite `50ec78a8`)

`## Interface:` now lists `120005, 120007, 120100` for retail, matching DeltaSync (the reference
list) and every sibling that hard-depends on this library. With only `120100`, retail flagged it out
of date, and FastGuildInvite -- which lists it under `## Dependencies:` -- loaded only for a player
allowing out-of-date addons. 38000 (Whitemane) stays.

### Changed -- listed under "Library" in the AddOns list (`## Category: Library`)

The TOC had no `## Category:`, so the in-game AddOns list showed VersionCheck loose among the
uncategorized addons while LibAceGUIWidgets, LibLocaleOverride, AceCommQueue-1.0, ItemDB and
ProfessionDB sat under a "Library" heading. It now declares the same category. One TOC serves every
client, so this applies on all of them; a client that does not group by category ignores the line.

### Docs -- the CurseForge description links to Discord only

The harness's `cfhtml.lua` checker found three offsite links in `docs/Curseforge_Description.html`
(the Ace3 and GreenWall CurseForge pages, and opensource.org for the licence). These projects allow
Discord links only, so the names stay as plain text and the links are gone.

Both release documents were then read against the library as it stands. The description gains the
login warning under "What you'll see" and a "What v1.5.2 changes for your addon" note (the normalized
realm in keys; no own missing-library check needed), and loses two claims that went stale in v1.5.1
("names are shown as they arrive rather than realm-qualified", "compares names as the transport
spells them") -- a bare same-realm name has gained the player's realm since MINOR 15. The README gets
the same corrections plus: the login warning in the end-user list, a `ReportMissingLibraries` row in
the API table, the normalized realm under "How a row gets its name", the Retail interface rule
rewritten (it said one number per client and replace-rather-than-append, which is what dropped
120005/120007 in v1.3.1), the Forever note (installed on the dev box now, still not verified in the
client), and the tests note (one local stand-in again, `GetNormalizedRealmName`).

### Tests -- harness pin `69c727d` -> `bd91de2`, and eleven weak absence checks made real

212 harness commits adopted to `18e0f0e`; the whole suite was green on it before any other change.
Then `bd91de2` (harness thread `6c619d98`), which restores the client-measured `inherit="prepend"` /
`"append"` order that `7f2fd3f`..`18e0f0e` had reversed. This addon has no XML using either and no
spec was changed to fit the reversed order, so there was nothing to revert; still 387 green. Writ's
new spec-shape check flagged eleven `is_nil` assertions on a literal key (`Tests/harvest_spec.lua`
x3, `identity_spec` x2, `lifecycle_spec`, `push_spec`, `required_libs_spec`, `trigger_spec`,
`window_spec`, `zzz_probe_spec`): a misspelt key passes them for ever. Each now derives the key it
checks from the same variable the test sent, pairs the absence with a positive check that the same
key IS written in the case that sets it (`host` on an addon object, `collectionTimer` after
`FireBatch`, `IsInGuild` refusing once installed), or -- for `VC.window` -- asks the library's own
reader (`RefreshRoster()` returns false with no window) instead of naming the field.

### New -- a chat line at login naming a required library that is missing

The user, 2026-09-20: _"if CF doesn't install it like it should, the UI would silently never work
in VC and the user would never know why"_ -- and _"CF shits the bed on this all the time"_. The
client only flags what the standalone TOC hard-requires, which is LibAceGUIWidgets: GuildRoster is
`## OptionalDeps:` (v1.5.0, the cycle), so its absence is silent, and an embedded copy of the
library runs inside a host whose TOC may require neither. In both cases the CurseForge relation is
the only thing installing them, and the one message that said the roster window needs
LibAceGUIWidgets was printed only when the player typed `/vc`.

`VC:ReportMissingLibraries()` runs from the `PLAYER_ENTERING_WORLD` handler, after every addon has
loaded -- the first moment a LibStub miss means "absent" rather than "not yet". One red line per
missing library, naming it, what it costs, and what to do: LibAceGUIWidgets absent (the roster
window cannot open), LibAceGUIWidgets present without RowList (too old, update it), GuildRoster
absent (answered players only, no ranks or class colours). Once per session
(`VC.requiredLibsReported`, guarded across LibStub upgrades like the other flags). **Not gated on
debug and not on the dev-build sentinel** -- a missing dependency is what an author running from
source wants to see first. Says nothing when both are present, so a normal login is as quiet as
before. `Tests/required_libs_spec.lua` pins all of it, including the once-only and the silence.

### Withdrawn -- the TOC dependency lines were dropped and put back within the hour (thread `e55d0406`)

LibAceGUIWidgets diagnosed a `LUA_WARNING: AddOn [LibAceGUIWidgets] failure to load: missing`
report as a load-order cycle (its TOC hard-requiring `VersionCheck-1.0` while this one hard-required
`LibAceGUIWidgets`) and asked this repo to drop the line; I did, then dropped `## OptionalDeps:
GuildRoster` on the same reasoning. **Both were wrong and both are back exactly as v1.5.1 shipped:**
`## Dependencies: Ace3, LibAceGUIWidgets` and `## OptionalDeps: GuildRoster`. The user's
observation settled it -- the report was from a World of Warcraft: Forever player who had v1.5.1
(which claims `16001`) without a LibAceGUIWidgets that claimed it, so "missing" meant the folder was
not loaded there, and every other client had been fine with the lines as they were for ten days.
The user's words: _"put the toc's back to the way they were, and tell VC the same"_. Recorded so the
next reader of that thread does not re-drop them. Nothing in the Lua was ever changed for it.

## [v1.5.1] (2026-09-20) -- sister-guild ranks, a same-realm peer keyed bare, and WoW Forever (MINOR 15)

MINOR **14 -> 15**: two library behaviour changes (both in how a roster row is filled), so an
embedded copy of 15 must win LibStub registration over a copy of 14. **378 specs green, 727/727
executable lines (100.00%)** on the run after the last change. Harness pin **799ae17 -> 69c727d**.
**Tested in game by the user on 2026-09-20: working, no Lua errors.** (The Forever entry below is
the exception -- no Forever client on this box.)

### Fixed -- a guildmate on OUR realm running an older VersionCheck was two roster rows

Found by adopting the harness pin: on 2026-09-16 the harness started delivering same-realm AceComm
senders **bare**, as the client does -- AceComm-3.0 runs every sender through `Ambiguate(sender,
"none")`, which strips the realm exactly when it is ours -- and 35 specs went red because the store
keyed such a peer as `Bob` while LibGuildRoster's `GetAllMembers` names them `Bob-Testrealm`. That
was an in-game defect, not a spec artefact: a guildmate on our realm running MINOR 12 or earlier (no
`__from`) got a row with a version and a second row, from the guild roster, that read "Not seen"
for ever -- and neither the right-click whisper nor the update popup could name them by their full
name. Peers at MINOR 13+ were already exact, because they qualify themselves.

`TransportIdentity(from, sender)` is now the one place a message's sender becomes a store key:
`__from` when the peer sent it, otherwise the transport's string **qualified with our realm when it
arrived bare** (`QualifyName`, the same inference the whisper target has always made). A bare name
is never ambiguous about its realm: AceComm strips it only for our own realm, and GreenWall's
`gw.GlobalName` (`Utility.lua:136`) appends the local realm to a bare name before any handler sees
it, so nothing bare arrives on that leg at all. A name that already carries a realm is untouched,
so this cannot re-introduce the old base-name collapse. `Tests/identity_spec.lua` now delivers a
genuinely bare sender (the in-game shape) for request and reply, and a cross-realm one that must
stay as it arrived.

### New -- a sister-guild member's rank and class fill from LibGuildRoster's sister rosters (thread `befd118e`)

The user's screenshot of 2026-09-16: a confederation member in the DeltaSync tab with a version and
a **blank Rank** beside home members with ranks. `VC:GetRoster` filled rank/rankIndex/classFile
from `GR:GetMember`, which is home-only; a sister member only ever reached the rows through the
observed-peer pass, which set version/via/at and nothing else. GuildRoster 0.8.2 (MINOR 21) now
carries `rankName`/`rankIndex` on the sister sync, so there is something to read.

`FillFromSisterRoster` runs for an observed row the home pass left without a rank: `GR:IsInAnyRoster`
for the guild key, `GR:GetRoster(key)` for that guild's members, the member under
`GR:NormalizeName`'s spelling; then `rank`, `rankIndex`, `classFile`, and a new row field **`guild`**
(the sister's key) because a sister "Officer" is not our officer and a view that wants to say so
needs to know whose. Feature-detected per method, so an older GuildRoster and a sister fed by a
provider before 0.8.2 (no `rankName`) leave the rank blank exactly as before. Home members never
consult the sister store and keep our rank even when a sister feed also lists them. No column was
added for `guild`; the field is on the row for a consumer. Sends nothing.

### Changed -- `## Interface:` gains `16001` (World of Warcraft: Forever) (thread `27d44d6d`)

FastGuildInvite v2.14.0 ships a `_Camelot` TOC and hard-depends on this library; on Forever a
dependency the client will not load stops FGI loading. This addon ships one TOC, which is the last
fallback the client reads on every flavour, so the number in the list is what stops Forever flagging
it out of date. **Not verified on a Forever client** -- there is no install on this box. Known cost,
told to FGI: this TOC's hard dependencies are `Ace3` and `LibAceGUIWidgets`, and LibAceGUIWidgets'
TOC does not carry `16001` today, so VersionCheck still cannot load there until it does.

Nothing in the code names the flavour, and the two things Forever changes that touch this file
degrade rather than break: `GetRealmName()` empty leaves a bare name bare (`QualifyName`,
`SelfName` omits `__from`), and `WOW_PROJECT_ID` is never read.

### Tests

- Harness pin **799ae17 -> 69c727d** (the whole log from 2026-09-16 on). The Ambiguate change above
  was the only red; the epsilon-timer fix (2026-09-16) let `Tests/peers_spec.lua` drop every 0.5s
  margin, so its advances now land on the exact due time and verify that fix.
- `Tests/roster_spec.lua` uses `env_vc.installRoster` instead of a fourth private copy of it, and
  gains six sister-roster cases (fills; provider predates ranks; home member untouched and the
  sister store never consulted; no roster knows them; normalized spelling and the key as `guild`
  when the record has none; no `NormalizeName`).

## [v1.5.0] (2026-09-16) -- `RequestFrom`, `RequestAbout`, the GreenWall leg fixed, and two copies of the library finally talk (MINOR 14)

MINOR **13 -> 14**: three public methods and one reserved wire key added, so an embedded copy of 14
must win LibStub registration over a copy of 13. **370 specs green, 713/713 executable lines
(100.00%)** on the run after the last change. Harness pin **226c0e0 -> 799ae17**.

### The API surface added at MINOR 14, in one place

Additive and feature-detectable, like MINOR 13's. Nothing at MINOR 13 changed meaning.

| Name | What it is |
| --- | --- |
| `VC:RequestFrom(name)` | The request, whispered to ONE player; `true` when handed to the transport |
| `VC:RequestAbout(addonName)` | The broadcast, naming ONE registered host; `RequestCheck`'s return shape and clock |
| `VC:FlushGreenWall()` | Release the parked GreenWall request from the caller's own hardware event |
| `__all` | Reserved wire key: "answer about everything you have" -- the GreenWall trigger |

### Changed -- GuildRoster is `## OptionalDeps:`, not `## Dependencies:` (thread `1b732c42`)

The user asked GuildRoster (2026-09-15) to make VersionCheck a hard dependency: its sister-guild
sync now finds a peer through `RequestAbout`, so a GuildRoster without VersionCheck cannot sync.
This repo's standing directive made GuildRoster a hard dependency of VersionCheck. Both at once is a
TOC cycle, and the client answers a cycle by loading NEITHER addon -- so one side had to move, and
the newer instruction decides which. `VersionCheck-1.0.toc` now reads `## Dependencies: Ace3,
LibAceGUIWidgets` and `## OptionalDeps: GuildRoster`.

What that keeps: load order (GuildRoster still loads first whenever present) and the CurseForge
install (`libguildroster` stays in `.pkgmeta`'s `required-dependencies` -- CurseForge's install list
has no cycle rule, and the `.pkgmeta` comment now says so, since it used to say the two lists must
agree). What it costs: nothing in the code, because every use of LibGuildRoster was already
`LibStub("LibGuildRoster-1.0", true)` at call time with a nil branch; a player who somehow has
VersionCheck without GuildRoster gets a roster window of answered players only and transport-spelled
names, which is what an embedded copy without it already got.

**RELEASE ORDER, and it matters for players this time:** v1.5.0 must be published BEFORE (or the
same day as) the GuildRoster release that makes VersionCheck a hard dependency. A player holding
released v1.4.0 (hard on GuildRoster) who updates to that GuildRoster has the cycle on their machine
and loads neither addon. Said on the GuildRoster thread as well.

### New -- `VC:FlushGreenWall()`: send the parked GreenWall request from a caller's click (thread `ec8f7fed`)

The GreenWall half of a request is parked until the player's next chat keystroke, because
GreenWall's send bottoms out in `SendChatMessage` and the client only allows that from a hardware
event. That is right for the login batch and wrong for LibGuildRoster's sister sync, which the user
designed around a click overlay ("i don't want anything waiting for someone to say something"). GR
had been reaching into `VC.gwPendingPayload` from outside and sending our bytes under our name;
`VC:FlushGreenWall()` is those three lines as a method, and the `ChatEdit_ParseText` hook now calls
it too, so the two cannot drift. Returns `true` when something went out. **The caller guarantees the
hardware event**; the library cannot check it and does nothing else.

### Fixed -- the GreenWall leg was truncated and answered by nobody

Found by LibGuildRoster on 2026-09-15 (inbox thread `73cb2669`), measured against GreenWall's source
and confirmed here: GreenWall wraps our payload as `E#<guild id>##VersionCheck-1.0:<base64>` and
cuts the segment at 255 characters with `strsub` (`Channel.lua:322`, `GW_MAX_MESSAGE_LENGTH`) --
no chunking, no reassembly. With the user's 17 registered hosts the full batch is 444 bytes, 592 in
base64. So every login broadcast on the GreenWall leg since the transport was added had been cut
mid-payload, failed `Deserialize` on arrival, stamped the receiver's dedup clock on the way, and
been answered by nobody. The confederation reach this changelog has described since v1.2 was dead
for any player with more than a handful of hosts, and nothing said so. My defect; the AceComm leg
chunks and never had it.

The user's direction: _"the broadcast doesn't need to be comprehensive, you just need to elicit
whisper responses."_ So the GreenWall leg is now a **trigger**: the control fields, a new reserved
key **`__all`**, and as many hosts as still fit a 150-byte budget, in name order (`GreenWallTrigger`;
the budget is derived on the constant from GreenWall's envelope with room for a 32-character guild
id, since the id is not readable through `GreenWallAPI`). The AceComm leg is unchanged and still
carries everything.

**Receiver side, at MINOR 14:** `HandleRequest` answers a request carrying `__all` about every host
it has, under the same answer-on-change gate, in addition to the intersection for the names it did
carry. **At MINOR 13 and earlier:** the key is ignored (reserved-prefix filtering at 13, hosts
lookup at 12) and the receiver answers the intersection with the names that fit -- what it would
have done with a full batch that arrived intact, and more than it did with one that never arrived.
Replies go by AceComm whisper, which chunks, so nothing about their size changes.

**A push on a trigger is about every host.** `HandleRequest`'s push loop iterated the request's
keys, so a Notify carried on the GreenWall leg would have made confederation peers decide only about
the three or four names that fit. With `__all` present it iterates the receiver's hosts instead; a
push without `__all` decides about the names carried, as before. Both pinned in `trigger_spec`.
Found by my own honesty pass, not by the thread.

**KNOWN COST, pre-existing and now reaching more players, stated rather than hidden.** The login
batch carries `__resync`, and so does its trigger. A guildmate hears the AceComm leg at login and the
GreenWall leg whenever the user next types in chat; inside 20 seconds their dedup drops the second,
after that they answer it -- in full, because of `__resync` -- so one duplicate round of whispers
per login is possible from same-guild peers. This was already the behaviour for any player whose
batch fitted the segment; it now applies to everyone, because the trigger always fits. Dropping
`__resync` from the trigger would silence confederation-only peers after a reload, which is the
case the key exists for, so it stays. Re-fires (TPM's scanner) carry no `__resync` and are
answered on change only. The 20-second dedup TTL is unchanged.

### New -- `VC:RequestAbout(addonName)`: the broadcast, about one addon

The second half of the same thread. LibGuildRoster's question is "who runs GuildRoster, and which
version", asked of the guild AND the confederation before it syncs a roster with someone -- and a
one-addon request fits GreenWall's segment with room to spare, so no trigger mechanism is needed:
every receiver at every MINOR answers the intersection, which is exactly that one addon.

Same two transports and the same return shape and clock as `RequestCheck` (`true, 0`; `false, N`
seconds to wait; `false, 0` for nothing to send). `false, 0` also covers an addon that is not a
registered host: the request carries our own version of it, and we have none for an addon we do not
run. `__resync` is always set, as for `RequestFrom`. Not a round of the popup decision -- no
collection window, `VersionResponses` untouched; answers arrive through `OnPeerVersion`.
`BroadcastRefusal` is the shared guard, and `SendRequest` the shared send, so `RequestCheck` and
`RequestAbout` cannot drift on either.

### New -- `VC:RequestFrom(name)`: the request, whispered to one player

Asked for by LibGuildRoster (inbox thread `754c66fd`, 2026-09-15). Before it pulls a roster from a
player `/who` listed, it asks THEM what they run and pulls from the most compatible responder -- and
a sister-guild member never hears our GUILD batch. Until now GR built the request itself, from a
copy of `VC10_REQ` and the `__v` / `__resync` / `__from` keys: this library's private wire,
maintained in two places. GR already feature-detects `VC.RequestFrom`, so the copy can go the moment
this ships.

`VC:RequestFrom(name)` sends the same payload `FireBatch` broadcasts, on `VC10_REQ` over `WHISPER`
to `name`, and returns `true` when a request was handed to the transport. `RESYNC_KEY` is always
set: a targeted ask wants a full answer, and without it a MINOR 13+ peer we had already heard from
would stay quiet by design. A bare name gains our own realm through the same branch the reply path
uses; a realm-qualified one is sent as given. It refuses (`false`) with no name, no registered
hosts, or our own name in either spelling -- the receiving side would drop that as an own echo, so
false now beats sending and hearing nothing.

Deliberately NOT done, and documented on the function: it does not touch `VC.lastBatchAt` (the GUILD
dedup clock, which is about what guildmates suppress), and it does not open a collection window or
clear `VersionResponses` -- it is not a round of the popup decision. The answer arrives through
`HandleResponse` -> `RecordPeerVersion` -> `OnPeerVersion`, which is what a consumer reads. **Known
and documented rather than worked around:** a guildmate asked inside `GW_REQ_DEDUP_TTL` of our own
broadcast drops the whisper as a duplicate. That is their dedup working, and a spec pins it.

### Changed -- one request builder for both transports

`FireBatch` built the payload inline. `BuildRequest(opts)` now builds it for the GUILD broadcast and
the targeted whisper alike -- every host's version, then `__v`, `__from`, and `__resync` / `__push`
on request -- so the two can never carry different shapes. The reply path's realm-qualifying branch
is `QualifyName`, shared with `RequestFrom` for the same reason. No wire change: every payload the
broadcast sends is byte-for-byte what it sent at MINOR 13.

### Tests -- two REAL copies of the library answer each other (`Tests/peers_spec.lua`)

The harness delivered `wow.client()` to this repo's request (thread `9bade997`, pin `1037beb`), and
this is the test the suite could never write: Alice's copy broadcasts, Bob's REAL copy answers by
whisper after HIS jitter to a name HIS code built, and Alice pops exactly one dialog naming
`Bob-Testrealm`. Then the negatives self-replay cannot reach: Bob older (Alice not warned, Bob is --
by Alice's real code), Bob without the addon (no reply, no dialog), a peer with addons we do not
have (answers only about the shared one; we still harvest the rest from his broadcast), three
peers (only the highest named, on every copy behind it), and neither copy answering its own echo.
`RequestFrom` is specced the same way, against a Bob who never heard Alice's broadcast, and
`RequestAbout` against a Bob with more addons than were asked about. `Tests/trigger_spec.lua` pins
the GreenWall trigger's shape and budget, the `__all` receiver rule, and `RequestAbout` on one
instance.

Three things learned building it, recorded in the spec's header so nobody re-derives them:

- **Load everyone, then let everyone enter the world.** `freshVC` advances the clock 10s for
  ChatThrottleLib's start-up throttle, so a client that enters before the next one loads has its
  login batch fire mid-load, before the peer's `RegisterComm` -- the peer never sees it and the
  version arrives by REQ harvest from THEIR batch, not by RSP. A real late-login shape, not the one
  under test. Measured with a probe.
- **`_G.AceComm30Frame` keeps the last client's whole world alive across `frames.reset()`.** AceComm
  names its frame; the widget registry is weak by design and keeps whatever is still referenced;
  a global the harness does not own is such a reference, and through the frame's OnEvent it holds
  that client's AceComm, its callbacks and this library, all still listening. The stale copy heard
  the NEXT example's GUILD echo and answered by whisper into its own dead `sent` log, routed to the
  live Alice. Nil it in `after_each`, with `ace.reset()` on the host so later spec files get a fresh
  Ace3 load.
- **`env.deserialize` resolves AceSerializer through LibStub**, so after that teardown the host has
  none and a payload is read as the client that owns a registry.

### Docs

- `README.md`: `RequestFrom`, `RequestAbout` and `FlushGreenWall` in the API table, each with its
  own section; the GreenWall section says what now travels on that leg and when it goes out;
  Requirements says what GuildRoster's optional declaration means.
- `docs/Curseforge_Description.html`: the v1.5.0 entry (New / Changed / Fixed), the Requirements
  wording, GuildRoster in the "who depends on this" list, and the developer paragraph for MINOR 14.
- `CLAUDE.md`: the GreenWall budget rule and the two-client spec's traps.

### Inbox

Six threads read. The retracted `38000` finding needed nothing -- the changelog already records the
retraction. `frames.layerMismatch()` and `GetMouseButtonClicked` were already adopted on the
previous pin; the RowList `onRowClick(…, button, rowFrame)` delivery (LibAceGUIWidgets at MINOR 29
on disk) is consumed, and the two feature-detected fallbacks STAY: two lines that keep right-click
working on a stale standalone widget library, per the backwards-compatibility directive.

## [v1.4.0] (2026-09-10) -- the peer-review findings, answered (MINOR 13)

All seven open findings in `docs/AUDIT.md`, answered, and the roster window built. **330 specs
green, 645/645 executable lines (100.00%)** -- observed on the run after the last change, not
carried forward. MINOR **12 -> 13**: the API surface grew, so an embedded copy of 13 must win
LibStub registration over a copy of 12.

### The API surface added at MINOR 13, in one place

Everything below is additive. Every name is feature-detectable (`if VC.GetRoster then`) for a
consumer that may be loaded beside an older embedded copy, and nothing at MINOR 12 changed meaning.

| Name | What it is |
| --- | --- |
| `VC:RegisterCheck(nameOrHost[, version])` | `Enable` plus an explicit version |
| `VC.version`, `VC.minor` | The loaded LibStub minor, as a number |
| `VC:GetPeerVersions([addonName])` | Every observation this session: `sender -> { version, via, at }` |
| `VC:GetRoster(addonName)` | One row per player with a four-state `state`; the window's model |
| `VC:RequestCheck([push])` | Rate-limited broadcast; `true`, or `false` plus seconds remaining |
| `VC:IsLeadership()` | LibGuildRoster's officer-permission predicate, for the player |
| `VC:NewestKnownVersion(addonName)` | Highest build anyone (us included) is known to run |
| `VC:IsBehind(entry, addonName)` | `true`/`false`, or `nil` when the row has no version |
| `VC:WhisperUpdate(entry, addonName)` | The canned whisper; returns the text sent |
| `VC:ToggleRoster()` | Open or close the roster window; what `/vc` calls |
| `VC:RefreshRoster()` | Repaint an open window from the model; sends nothing |
| `VC.callbacks` | CallbackHandler: `OnPeerVersion`, `OnCheckComplete`, `OnRosterChanged` |
| `__v`, `__resync`, `__from`, `__push` | Reserved wire keys; consumers must not name an addon `__…` |

### New -- `RegisterCheck`, a name two consumers were already calling

`VC:RegisterCheck(nameOrHost[, version])` registers a host exactly as `Enable` does, and records the
version string you hand it.

The name had never existed here, but Grouper and BijouRR both open with
`if VC.RegisterCheck then VC:RegisterCheck(NAME, VERSION) elseif VC.Enable then VC:Enable(self) end`.
The `elseif` rescued both, so the dead branch was invisible and every version check worked -- which
made it **a trap that would arm itself the moment this library defined the name for any purpose at
all**. Both consumers would have switched to the first branch, stopped calling `Enable`, registered
no host and never warned again, with nothing erroring, nothing logged, and no spec here able to see
it (every one of them drives `Enable`). Defining it to mean what those call sites plainly intend is
what makes the name impossible to re-purpose underneath them.

The version is recorded as `hostEntry.declaredVersion`, **not** stamped onto `hostEntry.host`: for
the object form that table is the caller's own addon object, and a library assigning a `Version`
field into it is a side effect nobody asked for. `HostVersion` precedence is now the live addon
object, then `declaredVersion`, then the TOC, then `"unknown"`.

### New -- the library learns from traffic that was already on the wire

`VC.peerVersions[sender][addonName] = { version, at, via }`, read through
`VC:GetPeerVersions([addonName])`. Every REQ is broadcast to the whole guild carrying the sender's
complete addon-and-version list, and `HandleRequest` iterated it as `for addonName in pairs(batch)`
-- key only -- discarding the versions at the language level. They are recorded now.

**It costs no traffic.** Not one extra message is sent; this is pure listening, and a spec asserts
it. That is the whole reason it is allowed to exist: the library was already receiving a complete
version announcement from every player who logs in, and throwing it away.

Four things it fixes, none of which needed a protocol change:

- **Late loggers.** Someone who logs in after your collection window closed previously never
  appeared at all. They now announce themselves by doing nothing but logging in.
- **Addons you do not have.** Their REQ lists _their_ hosts, not the overlap, so this is where you
  learn a guildmate runs something you have never installed. The reply is still limited to the
  intersection -- that is a property of the reply, not of what we may learn, and conflating the two
  is what discarded the data.
- **Confederation peers.** A REQ arriving over GreenWall from a non-connected realm gets a WHISPER
  reply that can never reach them. Their versions still arrive here, so they are no longer invisible.
- **Late replies.** `HandleResponse` records the observation even when `VersionCheckActive` is
  false. A reply landing outside a window is useless to the popup decision, not untrue.

`VersionResponses` is untouched and remains the popup's current-round input, which is why
`FireBatch` still empties it. The accumulated view and the decision input are now two tables with
two jobs, rather than one table doing both.

### Changed -- one identity model, borrowed rather than invented

VersionCheck had three opinions about who a player is: `GW_StripRealm`, a realm-appending branch in
`HandleRequest`, and raw sender strings as store keys. That is how two characters sharing a base
name on different realms came to suppress each other. LibGuildRoster already solves this properly,
so VC now uses it: **`CanonName`** for names arriving over the wire, feature-detected on the method
rather than the library, falling back to the raw string when an older embedded copy lacks it.

**Adopting it alone made things worse, and four specs caught that within a minute.** `CanonName` is
_pure_ -- a bare name stays bare and never gains a realm, which is exactly right for something you
persist and exactly wrong on its own here. One player arriving as `Bob` over GreenWall and
`Bob-Whitemane` over AceComm stopped merging and became two rows.

The rule needs both halves. LibGuildRoster's own phrasing is _"the sender qualifies, the receiver
canonicalizes"_, and VC was doing neither: it never put its own qualified name on the wire, because
the sender string always came from the transport. It does now, in a reserved `__from` field, from
`GetNormalizedPlayer()` where the roster library is present and built by hand from `UnitName` and
`GetRealmName` otherwise. If the realm has not resolved yet -- a real window at login -- the field is
**omitted rather than guessed**: a half-built identity is worse than none, because peers would key
us under a name that is not ours and never merge it later.

Backwards compatible in both directions. An older copy ignores `__from` exactly as it ignores every
other reserved key, and a peer too old to send one is keyed on the transport's string, which is what
VC has always used.

**The two heuristics were NOT deleted, and that is deliberate.** They answer a different question.
The transport dedup runs _before_ the payload is deserialized -- pinned by a spec, because parsing
first would let a peer flooding unreadable messages make us deserialize every one -- so it cannot
see `__from` and must work from the transport's sender string alone. Heuristic for the cheap
rate-limiting question, canonical identity for the stored answer.

### Changed -- `__`-prefixed keys are reserved on the wire, from this release onward

Nothing sends one. This is here so that a future version _can_, without breaking any copy of the
library already installed -- and it only works if it lands in the same release as harvesting.

The REQ payload is a flat `addonName -> version` map, so the only compatible way to add a protocol
control field is to put it in that map and rely on every reader ignoring it. A copy at MINOR 12 or
earlier already does: it looks the key up in `VC.hosts`, finds nothing, and neither replies about it
nor records it. **A copy at MINOR 13 harvests every key it receives**, so without this guard the day
any control field were introduced, every MINOR 13 client in every guild would begin showing a
phantom addon named after it -- in a roster window whose entire value is being trustworthy.

Filtered on _receive_, deliberately, because that is what protects clients which will never be
upgraded from a decision nobody has made yet. `Enable` is untouched, so a host that registers such a
name still works locally; peers simply do not harvest it. Replies about real addons in the same
payload are unaffected, so introducing a control field later cannot look like the version check
breaking.

### New -- callbacks, and a refresh entry point that will not fire into silence

`VC.callbacks` (CallbackHandler-1.0, which ships with Ace3 and which AceComm already depends on --
no new dependency, and the same idiom LibGuildRoster uses):

- **`OnPeerVersion(sender, addonName, version, via, changed)`** as each observation arrives, so a
  roster view fills in live instead of sitting blank until a window closes. `changed` is the
  argument that matters: re-hearing the same version from someone who logged in twice is the
  ordinary case and should not read as news.
- **`OnCheckComplete()`** when the collection window has closed and every host has been processed.
  Deliberately not "we found everyone" -- nothing can know that. It means we stopped waiting.

**`VC:RequestCheck()`** returns `true` when it broadcast, or `false` plus the seconds remaining.
The cooldown is `GW_REQ_DEDUP_TTL` and it is not a taste decision: peers suppress a repeat REQ from
the same player for that long, so an earlier broadcast is answered by nobody _and_ leaves the roster
emptier than before it was pressed, because `FireBatch` clears `VersionResponses` on the way out.
It counts the **login** batch too, not just manual refreshes -- a peer's dedup does not care why we
sent, so a cooldown tracking only manual checks would let the very first press fire into silence.

### New -- `GetRoster`, the four-state roster model, and `OnRosterChanged`

`VC:GetRoster(addonName)` returns one row per player for one addon, sorted by name: the model the
window renders, and the thing a consumer building its own view should read instead of
`GetPeerVersions`. Each row carries `name`, `account` (the alt-grouping key from LibGuildRoster,
supplied rather than acted on -- the view decides whether to collapse alts), `rank`, `rankIndex`,
`classFile` (named for what RowList's class colouring reads), `online`, `isSelf`, and when a
version is known `version`, `via` and `at`.

**Every row has a `state`, and the four values are the point.** A version checker that cannot
separate them lies -- RCLootCouncil's window collapses everything without a version into one "Not
installed ?", which reads as fact and is a guess:

- `reported` -- we have a version for them.
- `silent` -- in the guild, ONLINE, has never reported. Probably has not got the addon, but that is
  an inference and the UI renders it as one.
- `offline` -- in the guild, offline, never reported. Says nothing either way.
- `unknown` -- not in the roster at all: a confederation peer, someone who has left, or the roster
  library absent.

Guild membership is read first so a player who has never answered still gets a row -- without that
a window can only ever show people who replied, which is the question nobody is asking. The roster
is read here and NOWHERE in the popup path: a guildless player must still be told they are out of
date, and a spec pins it.

**`OnRosterChanged`** fires on `VC.callbacks` whenever LibGuildRoster reports a member joining,
leaving, coming online, going offline, changing rank, or the roster being rebuilt -- seven of its
events folded into one "repaint" signal, so a consumer does not have to learn that library's
vocabulary. Two things in the wiring came from LibGuildRoster's own answer and are easy to get
wrong: register on the library with a DOT (`GR.RegisterCallback(VC, ...)`), and there is NO REPLAY
of `OnRosterReady` -- VersionCheck wires up at `PLAYER_ENTERING_WORLD`, routinely after the roster
is ready, so it asks `IsReady()` and does the first fill itself. The library also calls its own
repaint directly rather than registering itself on `VC.callbacks`: CallbackHandler keys
registrations by target, so the library registering itself would silently replace any consumer
that used `VC` as its target -- which is what happened, and three specs caught it.

### New -- the roster window, and `/vc` to open it

`/vc`, `/versioncheck` and `/vcroster` all open it. Registered by the library rather than by each
host: the window is inherently cross-addon and no single host knows the others exist, so none of
them could own the command.

LibAceGUIWidgets' `ClearFrame` -- the suite's main window, the same chrome FGI and Dibs open --
with one tab per registered host and a sortable, virtual-scrolling list of everyone in the guild:
name, rank, and either their version or which _kind_ of not-knowing this is (`Not seen`, `Offline`,
`Unknown`). Four states rather than one "not installed", because collapsing them turns three
different facts into one confident guess; the info icon on the status bar explains them.

`ClearFrame` and not AceGUI's stock `Frame`, on instruction -- _"use the gui lib for this, all that
functionality is in the lib"_ -- and the difference is not cosmetic: it exposes its bottom bar
(`statusbg`, `info`, `settings`, `statustext`) on the widget table, so nothing here reaches into an
AceGUI internal. A draft on the stock Frame had to find the bar through `statustext:GetParent()` and
hand-measure Close's geometry to sit a button beside it. Both reaches are gone.

**It is built on first open and never before.** ~20 addons embed this library and most of their
users will never type the command; they should not pay for a window they do not open.

**And it adds no traffic.** Every row comes from observations the library was already receiving --
the login REQ every peer broadcasts, and the replies to our own. `RefreshRoster` sends nothing, and
a spec asserts it; switching tabs sends nothing either, since one request already fills every tab
and a second inside the peer dedup window would be answered by nobody while clearing what we had.
Rows appear live off `OnPeerVersion` and off LibGuildRoster's own roster events.

The list is **LibAceGUIWidgets' `RowList`**, not a hand-rolled stack of labels -- that was the plan
until its author pointed out `RowList` existed. Tabs are sorted: `pairs` order is not stable between
sessions, so they would silently rearrange on every login otherwise.

**Every column has a header and every header sorts.** Click Name, Rank or Version; click again to
flip. The list opens sorted by Version. The rank and version columns sort on a composite
`<value>\0<name>` field and display the plain value through `RowList`'s display-only `format`,
because the healthy case for a guild is that everybody runs the same build and most people share a
rank -- both columns are almost entirely ties, and `RowList`'s comparator is deterministic but not
stable, so without a unique secondary the rows would swap places on every repaint. The version
column is 170 wide because a _released_ host reports the packager's substitution of
`VersionCheck-v1.5.3`, which is the whole git tag (`TOGBankClassic-v1.2.3`); at 90 every one of them
truncated to the addon's own name.

**The status bar shows the library's version** -- the TOC version when the standalone addon is
loaded (`VersionCheck-v1.5.3` on a dev build, as FGI shows it), or the LibStub minor when only an
embedded copy is present and there is no TOC of our own to read.

**`LibGuildRoster-1.0` and `LibAceGUIWidgets-1.0` are now hard dependencies**, alongside Ace3 --
on the TOC's `## Dependencies:` line, which the client enforces, AND in `.pkgmeta`'s
`required-dependencies`, which is what CurseForge installs. The second was missed until the
release check: with only the TOC changed, a player installing from CurseForge would have got an
addon that refuses to load for want of two libraries CurseForge never fetched.

### New -- a refresh button that will not lie to you

The window's refresh button, on the bottom row beside the info icon and Close, rate-limited through
LibAceGUIWidgets' named cooldowns: while the cooldown runs the caption becomes the seconds
remaining, the text dims, the highlight is hidden and the click is refused at the UI layer rather
than fired and discarded somewhere deeper. It hangs off ClearFrame's exposed `info` and the status
bar is re-anchored to end at it -- the same 6 px and the same anchor ClearFrame's own
`SetSettingsButton` uses when it parks a control there.

**It does not start a cooldown for a request that never left.** `RequestCheck` declines for reasons
that are not always the clock -- a guildless player has no GUILD channel to send on -- and stamping
regardless would leave the button dead for twenty seconds having sent nothing, which reads to the
user as the button being broken. The cooldown length is supplied as a function precisely because the
widget library evaluates it _after_ the click, so it can report what the send actually did.

The cooldown key is namespaced with the library's major version: those cooldowns live in one
library-wide table shared by every addon using LibAceGUIWidgets, so a bare `"refresh"` would have
this button and some other addon's counting each other down.

Older embedded copies of LibAceGUIWidgets that predate named cooldowns simply get no button; the
window still opens and still works.

### Fixed before release -- what a self-audit of the window found

Found by reading `RequestCheck` against the three documents describing it, the evening the release
was declared ready. All fixed and specced; the counts at the top of this entry are post-fix.

- **`RequestCheck` only ever refused for the clock**, yet its comment, this changelog, the README
  and the CurseForge page all described a second refusal -- "nothing to send to", a player outside a
  guild -- that did not exist. With no hosts registered it returned `true, 0` for a request that
  never went out. Now: `IsInGuild()` (feature-detected -- an absent global reads as "cannot tell",
  never as "guildless") and an empty batch both answer `false, 0`; `FireBatch` returns whether it
  sent. `Tests/callbacks_spec.lua` had asserted the `true` -- a spec that had ratified the defect --
  and is corrected with the reason beside it.
- **A click inside the dedup window did nothing visible.** `RequestCheck` returns the seconds
  remaining precisely so a button can count down for them, and the button threw the number away:
  for twenty seconds after every login batch, Refresh was a dead click. It now counts down for the
  real remainder (a spec pins `19s` at t+6), and stays available only when nothing could be sent.
- **The info tooltip described `Unknown` wrongly** as "reported, but not for this addon". It means
  not in the guild roster at all -- a confederation member or someone who has left.
- **Right-clicking your own row offered to whisper you** that you were out of date whenever a
  peer was ahead. It now says "This is you".
- **A dev build was "behind" everyone.** `VersionCheck-v1.5.3` carries no digits and
  `CompareVersion` reads a digitless string as `0.0.0`, so `IsBehind` flagged a developer running
  from source and the menu offered to whisper them about it. The popup path already treats the
  sentinel specially; the whisper path now does too: a digitless version is never a candidate for
  newest and never compared -- `IsBehind` answers `nil`, the menu says "No version known".
- **Our own request, echoed back, was answered.** Some server cores deliver a player's own GUILD
  addon message to them. `HandleRequest` had no self check, so on those cores we whispered a reply
  to ourselves on every login (pre-existing) and, with `__push`, ran the update decision against
  our own version (harmless, noise). Identity is compared against `SelfName()` after the payload
  is read, so a realm-qualified echo still matches. Two `transport_spec` examples that replayed OUR
  OWN chunks "as Bob" stopped passing the moment this landed -- the same fiction the reply-side
  identity fix had already exposed on the other path -- and now send a genuinely foreign payload
  through the real AceComm chunking.
- **The roster fake lived in three spec files** and the third copy had already diverged from the
  first. One `env.installRoster(fields)` / `env.removeRoster()` in `Tests/env_vc.lua`.

### New -- right-click a name to whisper them about it

Right-click any row and the menu offers one thing, decided by whether that player is behind the
newest build anyone is known to run (ours included): _"Whisper: Alpha is out of date"_, which sends
_"Your Alpha is out of date (you have 1.0.0, latest is 1.5.0), please update."_ -- the user's words,
with both versions added so the recipient can see at a glance whether it is true. A player who is
level gets _"Up to date"_; a player we have never heard from gets _"No version known"_, because "not
behind" would be a claim about someone who has never told us anything.

The whisper goes through `C_ChatInfo.SendChatMessage` when the client has it and the bare global
otherwise -- on Classic Era the bare global is a deprecation fallback that forwards to the
namespaced one, so the order is the client's own preference. Specs drive both branches.

From LibAceGUIWidgets MINOR 28, `onRowClick` passes the mouse button and the row frame -- asked
as thread `ddb1caf9af5a` and delivered the same hour. An older embedded copy passes neither, so
both are feature-detected per call: the button falls back to the client's `GetMouseButtonClicked`
(which Classic Era's restricted environment whitelists) and the anchor to the row most recently
hovered. Specs drive both shapes. The harness delivered `GetMouseButtonClicked` with a
`wow.mouseButton` tunable in the same hour (thread `64fa224f3a25`), unpushed; `Tests/env_vc.lua`
staged it until the pin moved, which it did the same evening (see the `226c0e0` adoption below).

### New -- a Notify button for guild leadership, and the `__push` key behind it

For the player only when LibGuildRoster's `IsOfficer()` says so -- the officer-note _permission_,
which a GM granted deliberately, not a rank index, which is a position in a list the GM can arrange
any way at all. GMs hold every permission, so it covers them.

**What it does, and why a plain refresh could not.** A peer already harvests every version a REQ
carries, but it only _decides_ -- compares and pops the update popup -- when its own collection
window closes, at its own login or when one of its hosts re-triggers a batch. So an officer's
refresh could not make an out-of-date guildmate see anything until that guildmate's next batch.
Notify sends the same REQ with one extra reserved key, `__push = "1"`, and a receiver that
understands it runs `ProcessVersionResponsesForHost` on receipt for the addons it shares with the
sender. **No new popup path.** Same comparison, same `lastShown` dedup, same dev-build suppression,
same combat deferral -- only _when_ the existing decision runs changes. `OnCheckComplete` is not
fired, because no window of ours closed.

**Backwards compatible** the same way `__from` is: a MINOR 12 receiver looks the key up in its
hosts table, finds nothing, and ignores it -- it answers as it always has and decides at its own
next window, which is exactly what it did before the key existed. A receiver at this MINOR filters
it out of harvesting like every other `__` key.

**Both buttons carry a tooltip** in LibAceGUIWidgets' title-and-body shape (`AttachTooltip`), saying
the one thing a caption cannot: what a click costs, and for Notify who it reaches and who sees it.
Attached before the cooldown binding and asserted through a real hover while the caption is
counting down, since the library's hooks and the cooldown's caption both live on the same button.

**Refresh and Notify share one cooldown**, on purpose. The thing being rate-limited is the peers'
dedup window, keyed on us, which does not care which button we pressed; two independent cooldowns
would let Notify fire five seconds after Refresh and be dropped unread by everyone. Both buttons
count down together the moment either sends.

### New -- the library can report its own version

`VC.version` and `VC.minor` both carry the loaded `MINOR` as a number.

`LibStub:NewLibrary` records the minor in `LibStub.minors[major]` and never writes it onto the
library table, so a consumer holding only that table could not ask. Three spellings across two
consumers all read `nil`, permanently -- `/grouper libs` printed `Loaded but version unknown` on
every client, in every session. That is the fleet's one diagnostic whose subject is versions.

Both field names are populated because both are read in the wild. `_G.VersionCheck` is still **not**
assigned and will not be; the library stays reachable only through LibStub.

### Changed -- the update popup says what you are running

Was: `Player 'Bob' is using version 2.0.0. / Please update to 2.0.0` -- the newer version twice and
the player's own never, so a popup for a version they had since installed read identically to a live
one. Now: `You have 1.0.0; player 'Bob' has 2.0.0.`

`ShowUpdatePopup`'s fourth parameter was threaded through the entire combat-deferral state machine
and then discarded. Every popup spec passed `"1.0.0"` as that argument and **no assertion anywhere
mentioned it** -- a fixture constant nothing read, including the spec whose title enumerates the
message's contents. It is asserted now, through the deferral round trip as well. Where our own
version cannot be resolved (`HostVersion` returns the literal `"unknown"`), the old single-version
phrasing is kept: "You have unknown" is worse than not saying it.

### Fixed -- two different players who share a base name

`GW_StripRealm` reduces `Bob-Whitemane` to `Bob` and the 20-second REQ suppression was keyed on
that. The strip is correct for the case it exists for -- one player arriving over both AceComm GUILD
and GreenWall in two name shapes -- but character names are unique per **realm**, not per
connected-realm group, so `Bob-Whitemane` and `Bob-Faerlina` collapsed to one key. Whichever asked
second inside the TTL was dropped **before their payload was read**: no reply, no retry (this
library has none), and the only trace was a debug line calling them a duplicate. Their collection
window closed without our version in it.

The full name is now stored alongside the expiry. Two senders sharing a base name are the same
person only when either arrived without a realm suffix (the realmless spelling of the other) or the
realms match. When a bare name is suppressed against a realm-qualified one the stored spelling is
**upgraded** to the qualified form, so a third character on a different realm is compared against a
realm we know rather than against a base name that matches everybody.

### Unchanged -- `38000` stays, and this entry records an attempt to "fix" it that was WRONG

**`38000` is still `38000`.** It was briefly changed to `38002` during this session and changed
back. Recorded rather than quietly reverted, because the reasoning that produced the change was
persuasive, wrong, and will look persuasive again.

**The argument for changing it, which was all true and still insufficient:** reading every
`## Interface:` in the installed AddOns tree, `38000`/`38001`/`38002` appear across roughly sixty
TOCs, essentially all `*_Wrath.toc` -- DBM, WeakAuras, Details, Questie, Ace3, `!BugGrabber`,
TomTom, LibSharedMedia. The actively-maintained ones are all on `38002` while the stale ones sit on
`38000`, and `DeltaSync.toc` already carries `38002`.

**Why it was wrong anyway.** Every one of those facts is about what OTHER addons target. None of
them is evidence about which build **the operator's server reports**, and that is the only thing
this number has to match. Asked directly, the answer was that Whitemane does report `38000`. So
`38002` would have flagged this addon as out of date on the one server it was "corrected" for.

**v1.3.1's warning was right and is restated here rather than weakened:** `38000` is the Whitemane
private server, it appears in no Blizzard product list by design, and a pass that verifies each
number against Blizzard's own products -- or against what the rest of the fleet declares -- will
conclude it is bogus and silently drop support for a live target. **Absence from Blizzard's sources
is not evidence against a private server; it is what a private server looks like.**

**The transferable rule, which the fleet-wide sweep did not supply:** a private server's build
number is a fact about that server. It cannot be derived from other addons, from Blizzard's docs, or
from the number's neighbours -- only from the operator or from the client itself. Ask.

### Fixed -- five luacheck warnings on correct code

`.luacheckrc` listed `SlashCmdList` and `StaticPopupDialogs` as `read_globals`, with a comment
asserting that luacheck permits assigning their fields. It does not -- W122 "setting read-only
field" fired on all five sites, which are the normal and only way an addon registers a slash command
or a dialog. Both are now in `globals`. The stale comment claiming otherwise is corrected in place.

This surfaced only because luacheck is in fact runnable here, through writ. `CLAUDE.md` said it was
not installed on this box and that the language server's diagnostics were the working check; that is
no longer true and the note is updated.

### Adopted the WoWAPITesting harness at `226c0e0`

Pin moved `c9f3199` -> `226c0e0` the same day, once the harness pushed the two things this session
asked it for. `226c0e0` is a docs-only commit naming `2406895`, which carries the code; both are on
the harness's `origin/main`. Suite re-run against the new pin: 320 passed, 0 failed, 625/625
executable lines (100.00%) -- unchanged by the move itself.

Two adoptions, both from that entry:

- **`frames.layerMismatch()`**, now asserted nil in the setup of both widget-layer spec files. It
  is an identity check on `_G.CreateFrame`, built by the harness from this repo's own report: the
  one probe that can see a `wow.reset()` run after `frames.reset()`, which a capability probe
  cannot and which cost an afternoon here.
- **`GetMouseButtonClicked()` with `wow.mouseButton`**, to the exact contract this repo filed. The
  stand-in in `Tests/env_vc.lua` is deleted and the two right-click specs set `wow.mouseButton`.

Checked the rest of the entry for branches that would run for the first time: this library
feature-detects neither `GetPlayerInfoByGUID` nor `canaccessvalue`, asserts no bank-slot or
pinned-object count, and classifies no invite outcome. Nothing else reaches here.

### Adopted the WoWAPITesting harness at `c9f3199`

Pin moved `f58da5e` -> `c9f3199` (2026-09-09), **103 commits**, a clean ancestor. Suite re-run
against the new pin at the time of the move: 171 passed, 0 failed, 292/292 executable lines
(100.00%) -- unchanged by the adoption itself, and no stand-in in `Tests/env_vc.lua` became
redundant, so nothing was deleted. (The release figure at the top of this entry is higher
because the window and its specs landed after this.)

`c9f3199` is reachable from the harness's `origin/main` and that repo has nothing unpushed, so the
submodule pointer resolves for anyone cloning this one -- checked rather than assumed, because the
newest Adoption log entry sitting in the harness's working tree makes "is this pinnable" a live
question rather than a formality.

**Finding 6 measured this as `0813bf6`, 136 commits behind main `59c4280`. That was already stale
when it was written** -- v1.3.1 moved the pin to `f58da5e` on 2026-08-13. Same as the finding's TOC
quote showing `120007` where the file said `120100`: round 2 was written against the pre-v1.3.1
tree. The real gap was 103 commits, not 136.

`c9f3199` rather than "latest" on purpose. The harness's newest Adoption log entry (2026-09-10, two
guild-invite refusal strings) is marked **IN THE WORKING TREE ONLY, NOT PUSHED, DO NOT PIN FOR THIS
YET**, and those changes are uncommitted in the harness repo -- so `c9f3199`, which is both `HEAD`
and `origin/main`, is the newest pinnable commit and correctly excludes them.

Two adoption entries in that range could have reached this library, and neither does:

- **`RegisterAddonMessagePrefix` now returns `Enum.RegisterAddonMessagePrefixResult`, not `true`.**
  Consumers asserting a truthy return go red. Nothing here calls it -- AceComm registers on our
  behalf -- and no spec of ours asserts on it. The one `assert.is_true(...)` on that call lives in
  the harness's own `spec/messaging_spec.lua` and was fixed inside the pin we just took.
- **`GetServerTime`, `wow.pendingTimerCount()`, `wow.flushTimers()`,** carrying a 2026-09-10
  correction that an earlier "delete your stand-in" instruction was unsafe for any consumer driving
  its own clock. `Tests/env_vc.lua` drives no clock of its own (that stand-in went in August), so
  there was nothing to keep and nothing to delete.

Checked by reading `Tests/env_vc.lua` and every `Tests/*_spec.lua` for those four names, not by
trusting that a green suite meant a clean adoption.

### Still open

**Nothing.** All seven findings from `docs/AUDIT.md` are answered and closed.

### Not part of the download

`Tests/api_spec.lua` is new -- the outward-facing API contract, which is the surface a spec suite
cannot reach on its own because the consumers live in other repos. New dedup and popup cases went
into `Tests/request_spec.lua` and `Tests/popup_spec.lua`. All excluded from the packaged zip.

This repo was also onboarded to writ, and `docs/AUDIT.md` and `Tests/HARNESS_CONTRACT.md` became the
historical record: findings and contracts now travel as threads in writ's inbox rather than as
writes to a markdown board somebody has to be watching. Neither file was edited. There is no
watcher.

## [v1.3.1] (2026-08-13) — Retail 12.1.0 compatibility (no MINOR bump)

**No library behaviour changed.** `VersionCheck-1.0.lua` is untouched and `MINOR` stays at **12** —
deliberately, because a MINOR bump exists to make LibStub prefer a newer embedded copy, and there is
nothing here for it to prefer. The only shipped file that moved is the `.toc`.

### Fix — flagged out of date on the current Retail client

`## Interface:` declared **`120007`** (Retail 12.0.7). The installed Retail client is **12.1.0**, so
the addon list showed VersionCheck as out of date on every Retail install. Now `120100`.

Verified against `C:\Program Files (x86)\World of Warcraft\.build.info`, which reports the real
version of each installed product, rather than from memory. The other six entries are unchanged and
**`38000` in particular must not be "corrected"** — it is the Whitemane private server, it appears in
no Blizzard product list by design, and a pass that verifies each number against Blizzard's own
products will conclude it is bogus and silently drop support for a live target.

### Not part of the download

Everything below is `Tests/` and `docs/`, both excluded from the packaged zip by `.pkgmeta`.
Recorded because the test suite is how the last two shipped bugs were found, and it is worth knowing
what state it is in.

### Adopted the WoWAPITesting harness at `0813bf6`

Pin moved `47dd048` → `0813bf6`. All five contracts this addon raised on 2026-08-04 came back
DELIVERED, so their local reference implementations in `Tests/env_vc.lua` are **deleted** rather
than kept alongside the harness's own — a local copy that survives adoption is a second source of
truth that drifts silently while the suite stays green. `env_vc.lua` drops from 287 to 199 lines;
the specs now use `wow.inCombat`, `wow.popups` and `wow.advanceTime` directly.

Two of the five needed more than deletion:

- **`wow.popups` records `info`** — the live dialog table — rather than a copied `text` field, so
  assertions moved to `popups[i].info.text`. It is a reference, so it reads the dialog's _current_
  text rather than a snapshot taken at show time.
- **`StaticPopup_Show` raises on an unregistered dialog name**, it does not return `nil`. The
  harness checked Blizzard's current Classic Era `StaticPopup.lua`; the `return nil` this addon's
  contract quoted came from older FrameXML and was wrong. The correction is stricter in exactly the
  direction the contract asked for — a registered/shown name mismatch now fails loudly at the call
  site instead of returning a nil somebody forgot to check.

The monotonic-clock change, flagged upstream as the one that can break a green suite, broke nothing
here: no spec asserted an absolute `GetTime()`.

### Found while adopting — a harness defect, raised as a contract

`wow.reset()` empties `wow.frames`, the registry `advanceTime` ticks `OnUpdate` on. But
ChatThrottleLib's frame is created **once**, when Ace3 first loads inside whichever spec asks
first. From the second reset onward nothing ticks it, so a message CTL chooses to **queue** is
never despooled: `bQueueing` latches true and `wow.sent` stays empty with no error.

It hides almost perfectly, because CTL sends directly whenever it has bandwidth — every ordinary
spec passes. It bites only when CTL genuinely queues, which is precisely the case the OnUpdate
ticking was added to make testable. Written up in `Tests/HARNESS_CONTRACT.md`;
`Tests/env_vc.lua` re-registers that one frame as a deliberately narrow local workaround until it
lands.

Suite: 151 specs, 100% line coverage of `VersionCheck-1.0.lua` (269/269), unchanged by the move.

### Adopted the harness at `f58da5e` — and the sixth contract came back DELIVERED

Pin moved `0813bf6` → `f58da5e`, nine days and 138 commits. The suite is **151 passed, 0 failed**
and **269/269 executable lines (100.00%)** both before and after, so nothing upstream broke us.

**The CTL workaround above is deleted — it landed in `9f0dd38`.** That commit was authored on
2026-08-04 but sits _after_ the `0813bf6` pin adopted the same day, which is why the local
re-registration in `Tests/env_vc.lua` stayed live for nine days rather than being an oversight.
`wow.frames` is now **weak-valued** and `reset()` **compacts** it instead of emptying it, so a frame
lives exactly as long as something holds it — which is what the client does.

Deleting it was not merely tidying: with the harness fixed, the stand-in was actively wrong.
`compactFrames()` leaves the registry dense up to a private `frameHigh`, so
`wow.frames[#wow.frames + 1] = CTL.Frame` wrote one slot _past_ it — a slot `forEachFrame` never
visits and the next `CreateFrame` silently overwrites. The regression guard for the harness's fix is
`messaging_spec`'s _"delivers the batch once a throttled client stops refusing"_, which still passes
with the stand-in gone. `Tests/env_vc.lua` now holds only what is genuinely this addon's own: the
GreenWall API fake, the jitter freeze, the payload helpers, and the library reload.

Checked and **not** applicable, rather than assumed: the `strsplit` behaviour change (`c3129ba`,
which stopped dropping a trailing empty field and would shift every field in a packed record) does
not reach this library — it never calls it, and neither does AceComm-3.0 or AceSerializer-3.0, the
only two libraries it loads. Same for `securecall` and `strlenutf8`, both new upstream and neither
used here.

**Protocol adoption, both overdue.** `Tests/HARNESS_CONTRACT.md` had all six contracts sitting under
`## Open` with not one answer — the file is an _outbox_, and responses are only ever written into the
harness's `docs/contracts/VersionCheck-1.0.md`, so a delivered contract was indistinguishable from an
ignored one. Each request now carries an appended `> **Delivered — …**` pointer and the file opens
with a status table; nothing was moved or re-titled, because the order is part of the record. And
`docs/AUDIT.md` — the standing peer-review file, carrying **seven open findings from two rounds, none
of them answered** — is now tracked and pointed at from `CLAUDE.md`, which is the only file loaded
unconditionally every session.

`.luacheckrc` gained `122/math` under `files["Tests"]`: `env_vc.fixJitter` deliberately swaps
`math.random` to make a jittered reply's timing assertable, and `env_vc.reset` puts the real function
back.

## [v1.3.0] (2026-08-04) — offline test suite, and a version-reporting fix it found (MINOR 12)

First release with an offline unit-test suite. 151 specs, 100% line coverage of
`VersionCheck-1.0.lua` (269/269 executable lines), run locally with `lua Tests/wowapi/run.lua`.

### Fix — hosts registered by name reported `unknown` to everyone else

`VC:Enable("MyAddon")` (the plain-string form, documented in the README and used by hosts that have
no AceAddon object) produced a host entry with no `.host`. Three places needed that host's version
and each resolved it differently:

- `FireBatch` fell back to the TOC — `hostEntry.host.Version` **or** `GetAddOnMetadata(name, "Version")` **or** `"unknown"`;
- `ProcessVersionResponsesForHost` did the same;
- `HandleRequest` did **not** — it went straight from `hostEntry.host.Version` to `"unknown"`.

So a string-registered host announced its real version in its own request and answered `"unknown"`
to every request it received. `"unknown"` contains no digits, so `CompareVersion` parses it as
`0.0.0` and sorts it below every real version: such a host could never be the highest version any
guildmate saw, and nobody was ever prompted to update on account of it. Silent, and it only affected
other people's clients, which is why it survived this long.

All three sites now call one `HostVersion(hostEntry)` helper, so they cannot drift again. The helper
is also nil-guarded on `GetAddOnMetadata` — `FireBatch` and `ProcessVersionResponsesForHost` called
it unguarded, which would have been a hard error on any client carrying neither the `C_AddOns`
namespace nor the bare global (the `IS_DEV_BUILD` check already guarded; those two did not).

### Fix — the "no version responses" notice was chat spam, not a diagnostic

`ProcessVersionResponsesForHost` printed `"[VersionCheck] No version responses received for <addon>."`
with a bare `print`, so it went to the user's chat window unconditionally. Every other diagnostic in
the file goes through the debug-gated `VCPrint`; this one line did not, which reads as an oversight
rather than a decision.

It fires whenever nobody else in the guild answers — the **normal** state for a niche addon, and
nothing the user can act on. And it is not a one-off login notice: hosts re-trigger `FireBatch`
periodically (TOGProfessionMaster's scanner every ~10 minutes) and each batch clears
`noResponseLogged`, so it repeated for the whole session, once per host. A user with three
VC-hosting addons and no guildmates running them saw three lines every ten minutes.

Now routed through `VCPrint`, so it is still there under `/vcdon` where it is actually useful. This
restores the library's stated contract that its only user-facing output is the update popup.

### Not changed — the response jitter

Recorded here because it was investigated and the answer is worth not re-deriving. `HandleRequest`
spreads replies with `math.random(0, 8)` and never seeds the RNG, which looks like a bug: an
unseeded Lua 5.1 RNG yields the same sequence every run, which would defeat the whole point.

Checked against Blizzard's global API listing rather than assumed: **`math.randomseed` is not
exposed to addons at all** — the list runs `math.rad`, `math.random`, `math.sin`. No addon can seed
it, so the common `math.randomseed(time())` defence is impossible in WoW. Blizzard's own UI relies
on `math.random` varying across sessions (`/castrandom` picks a spell with it) and never seeds it
either, so the client must seed it internally. That last step is inference about the binary, which
the Lua source cannot prove — but it is the only reading under which Blizzard's own features work.

`fastrandom` exists as a client global and Blizzard use it for exactly this kind of jitter, but
swapping to it buys nothing over a seeded `math.random` and its range semantics are not something
this session verified. Left alone, with the finding recorded in a comment at the call site.

### Test suite

Built on the shared [WoWAPITesting](https://github.com/Pimptasty/WoWAPITesting) harness, added as
the submodule `Tests/wowapi` (pinned at `47dd048`). Specs drive the **real** event and comm paths —
`PLAYER_ENTERING_WORLD` on the library's own frame, the real AceComm `CHAT_MSG_ADDON` receive
handler, real AceSerializer payloads, real ChatThrottleLib — rather than calling methods directly.
That distinction matters here: `TriggerVersionCheck` is a shim that deliberately does nothing until
PEW has fired, so calling it proves nothing and firing the event proves everything.

Covered: LibStub registration and upgrade-in-place, the PEW wiring, `Enable`'s input handling,
batch construction and the 12s collection window, request answering with its 20s cross-transport
dedup and 0-8s reply jitter, response collection, `CompareVersion`, the warn/stay-quiet decision
including `lastShown` and both dev-build suppressions, the popup and its per-host combat deferral,
the whole GreenWall transport including the echo-driven second round, the slash commands, and the
three legacy shims.

**Line coverage is not branch coverage**, and two of the spec files exist because of that gap rather
than to raise a percentage:

- `Tests/metadata_spec.lua` — `local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata` is one line with three outcomes, and the harness defines **both** spellings, so every other spec took the `C_AddOns` branch and only that. The line read as covered while two of its three paths had never run — including the nil guard added in this release. That line is the v1.2.8 fix for a login crash on WoW 11.x clients, so getting the fallback wrong breaks older clients silently. Now exercised on a modern client (namespace only), a legacy client (bare global only), and a client with neither.
- `Tests/transport_spec.lua` — the batch on a real wire. A payload above 255 bytes (about a dozen registered hosts, which is a realistic install) is split by AceComm into multipart chunks; the split, the reassembly and the equally-multipart reply are now round-tripped through the real AceComm rather than asserted on a hand-built payload. Alongside it, the sends the client refuses: `NotInGroup` for a player who is not in a guild — every login for anyone who installs a host addon before joining one — and a throttled send, which is the normal case at login when every addon broadcasts at once. The library never inspects a send result, so what mattered was that it degrades quietly and still closes its collection window rather than stranding every host in `VersionCheckActive` for the session.

`Tests/env_vc.lua` carries local reference implementations of four things the shared harness does
not provide yet — `InCombatLockdown`, the StaticPopup surface, WoW's chat-frame `print`, and a clock
that ticks frame `OnUpdate` so ChatThrottleLib despools. All four are written up in
`Tests/HARNESS_CONTRACT.md` and are waiting on a harness session; the suite runs green without them.

### TOC interface versions refreshed

`## Interface:` was `11509, 11507, 20505, 30405, 38000, 40402, 50503, 50502, 120001, 110207, 120000`
and is now `11509, 20506, 30405, 38000, 40402, 50504, 120007` — one current number per target,
which is what the packager's `enable-toc-creation` needs to emit one TOC per flavour. This matches
the list `DeltaSync` already carries, so the two libraries no longer disagree about which clients
the suite supports.

| Target | Was | Now | Why |
| --- | --- | --- | --- |
| Retail | `120001`, `120000`, `110207` | `120007` | The installed client is **12.0.7**. Nothing in the old list reached it |
| Anniversary / TBC | `20505` | `20506` | The installed client is **2.5.6** |
| Mists | `50503`, `50502` | `50504` | `50504` is current; both old entries are superseded and same-family |
| Classic Era | `11509`, `11507` | `11509` | Installed client is **1.15.9**; `11507` is superseded and same-family |
| Whitemane | `38000` | `38000` | **Kept.** A private server, so it appears in no Blizzard product list — see below |
| Wrath | `30405` | `30405` | Unchanged — not installed here, so left as found |
| Cataclysm | `40402` | `40402` | Unchanged — not installed here, so left as found |

Retail and Anniversary were checked against the installed clients' own `.build.info`; Mists and
Whitemane against the interface numbers the rest of the AddOns tree already uses.

**`38000` is Whitemane, a private server, and was very nearly deleted from this list on the grounds
that no Blizzard client has that interface number.** That is true and irrelevant: verifying against
`.build.info` and Blizzard's UI source can only ever see Blizzard's own products, so a private
server is invisible to that method by construction, and "I could not find it" is not "it does not
exist". The corroborating evidence was on disk the whole time — sibling addons in the tree carry
`## Interface: 38000` on its own and as `30405, 38000`, which is what a Wrath-era private server
target looks like.

Duplicate numbers within one flavour family are still worth avoiding: the packager generates a
per-flavour TOC from this list, so two Mainline entries make which one it picks a coin toss. That
reasoning does not extend to `38000`, which is its own target rather than a duplicate of `30405`.

### Repository maintenance

- `.pkgmeta` — added `Tests`; removed nine dot-entries (`.git`, `.github`, `.vscode`, `.claude`, `.luarc.json`, `.markdownlint.json`, `.markdownlintignore`) that were no-ops, since the packager prunes everything beginning with `.` unconditionally.
- `wow-version-replication.ps1` — two fixes, both verified with `-DryRun`. A bare folder name in `.pkgmeta` compiled to `^docs$`, which matches only a _file_ named `docs`, so `docs/` had been replicating into every other WoW flavor despite being listed; bare entries are now resolved against the repo and treated as a prefix match. And the always-skip list now covers **any** path component beginning with a dot, which is the script's own responsibility (dot-entries in `.pkgmeta` are no-ops, so it cannot learn them from there) — without it the `.pkgmeta` cleanup above would have started replicating `.claude/`, `.vscode/`, `.busted` and the `.git` gitdir pointer.
- Added `.busted` (the two-line shared-config shim) and `.luacheckrc`; `.luarc.json` gained the busted DSL globals and `Tests/wowapi` in `workspace.ignoreDir`.

## [v1.2.9] (2026-07-28) — Classic Era interface bump to 11509

TOC-only change. The leading Classic Era interface number in `VersionCheck-1.0.toc` moved `11508` → `11509` to match the current Classic Era client build; the rest of the multi-flavor interface list (including the `11507` fallback) is unchanged.

No library code changed, so `MINOR` stays at 11.

## [v1.2.8] (2026-05-23) — fix `GetAddOnMetadata` crash on WoW 11.x clients (MINOR 11)

Login-time crash reported from Silvermoon:

```text
VersionCheck-1.0/VersionCheck-1.0.lua:39: attempt to call a nil value
```

WoW 11.x moved `GetAddOnMetadata` into the `C_AddOns` namespace and removed the bare global. Classic Era picked up the same change in its current client build, so every call site that hit the global was nil-dereferencing — first at chunk-load time (the `IS_DEV_BUILD` check at line 39), and then at `FireBatch` ([VersionCheck-1.0.lua:191](VersionCheck-1.0.lua#L191)) and `ProcessVersionResponsesForHost` ([VersionCheck-1.0.lua:375](VersionCheck-1.0.lua#L375)).

Resolved once at chunk-load with a local shim: `local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata`. The three downstream call sites bind to the local naturally and need no further changes. `_G.GetAddOnMetadata` fallback keeps older clients (where `C_AddOns` doesn't exist) working. The `IS_DEV_BUILD` check additionally gates on `GetAddOnMetadata and …` so a hypothetical client missing both APIs degrades to "not a dev build" rather than crashing chunk-load.

`.luarc.json` updated: `C_AddOns` added to `Lua.diagnostics.globals`.

## [v1.2.7] (2026-05-23) — GreenWall transport, popup hardening, debug-state SV fix (MINOR 10)

Bundles a long-paused feature branch with three bug fixes in the popup and debug-state paths. First release on MINOR 10.

### GreenWall optional confederation transport

Version checks now reach every linked co-guild in a GreenWall confederation, not just the player's literal `<guild>`. AceComm GUILD remains the sole transport for users without GreenWall installed.

Implementation rides `hooksecurefunc("ChatEdit_ParseText")` to issue `GreenWallAPI.SendMessage` from inside the user's chat-keystroke scope. An echo of our own segment re-arms a fresh 12s collection window so confederation peers' RSPs land in round 2 of `ProcessAllHosts`. A 20s REQ dedup window suppresses the same sender arriving on both transports (which happens for peers in the user's own guild AND the confederation).

Same-realm-cluster reach is unchanged. Confederation peers on a different server cluster will receive the REQ but their WHISPER reply won't reach back — an acknowledged design limitation of AceComm WHISPER, not a bug.

### Popup bug 1 — `lastShown` now persists across batches

Pre-2.2.7 the in-progress popup-dedup work wiped `hostEntry.lastShown = nil` at the top of every `FireBatch`. Hosts that re-trigger `FireBatch` periodically (TOGProfessionMaster's scanner does this every ~10 minutes for its own user-count refresh) were re-popping the same outdated-version popup on every cycle. The `lastShown` reset is gone; the field persists across batches and a strictly-newer version still surfaces via the strict-greater check in `ProcessVersionResponsesForHost`. UI reload clears the field naturally (in-memory only, no SavedVariable).

### Popup bug 2 — popups defer in combat

`ShowUpdatePopup` now checks `InCombatLockdown()` and stashes pending args on `hostEntry._pendingPopup`. A single library-scoped frame registers `PLAYER_REGEN_ENABLED` and drains all hosts' pending entries in one pass when combat ends. Per-host (not library-scoped) stash matters: simultaneous hosts queued in the same combat would otherwise clobber each other.

### Debug-state SavedVariable fix

The debug flag now reads `VersionCheck10_DebugEnabled` lazily on every access (`isDebug()` helper) instead of caching a `VC.debugEnabled` field at chunk-load. When both standalone and embedded copies of the library coexist at the same MINOR, and the embedded copy wins LibStub registration first, the standalone chunk that owns the SV declaration never runs past its `if not VC then return end` guard — so a cached read at the embedded chunk's load time saw the SV as nil and `/vcdon` silently reverted to off on every `/reload`. Lazy reads sidestep the race entirely: whichever code path eventually populates the global takes effect immediately for all subsequent prints and toggles.

### Other

Debug-state migrated from `_G.VC_DebugEnabled` (bare global) to the `VersionCheck10_DebugEnabled` SavedVariable, with a proper `SetDebug()` helper. Standalone TOC declares the SV; embedded hosts that want `/vcdon` to survive `/reload` need to declare it in their own TOC (documented in [README.md](README.md)).

Removed leftover `[VersionCheck-DIAG]` chunk-load prints from the earlier SV-load-order investigation that produced the lazy-read fix.

Repo maintenance: added `CLAUDE.md`, `.claude/`, `LICENSE` (MIT), `CHANGELOG.md`, `docs/Curseforge_Description.html`. Renamed `read.me` → `README.md`. Updated `.pkgmeta` ignores accordingly.

## [v1.2.6] (2026-04-02)

TOC interface-version line refresh — adds support for the then-current WoW Classic and retail Interface numbers.

## [v1.2.5] (2026-03-30) — fix `VersionCheck-v1.5.3` detection when `:Enable` is called with a string

When `VC:Enable` was called with a plain string name (instead of an addon object), `hostEntry.host` was nil and `myVersion` fell back to `"unknown"`, bypassing the `VersionCheck-v1.5.3` dev-build suppression check. Now both `FireBatch` and `ProcessVersionResponsesForHost` fall back to `GetAddOnMetadata(addonName, "Version")` so dev builds are detected correctly regardless of which `:Enable` form the host used.

## [v1.2.4] (2026-03-04) — split `RegisterComm` from `FireBatch`, add 5s broadcast delay (MINOR 9)

Two bugs causing "no responses received" when both clients had the newer code:

1. `RegisterComm` was inside `FireBatch`, called at the same time as the broadcast. If another player's `VC10_REQ` arrived during the startup window (before `FireBatch` ran), we were not yet registered to receive it and silently missed it. Fix: `RegisterComm` now happens immediately at `PLAYER_ENTERING_WORLD` so incoming broadcasts are never missed.

2. `FireBatch` was called directly from `PLAYER_ENTERING_WORLD` with no delay. The GUILD addon-message channel is not guaranteed to be fully available at that exact moment in Classic Era — the broadcast was going out into nothing. Fix: 5s `C_Timer.After` delay before the broadcast only; `RegisterComm` still happens immediately.

## [v1.2.3] (2026-03-03)

Workspace config cleanup — removed stale folder reference, updated WoW API extension to ketho.wow-api-0.22.3.

## [v1.2.2] (2026-03-03) — performance: stuttering, thundering herd, init freeze

- Defer `RegisterComm` calls into `C_Timer.After(10)` to prevent `C_ChatInfo.RegisterAddonMessagePrefix` from causing a 2–5s freeze during the post-login addon-load phase.
- Add random 0–8s jitter before each client sends its `VCRESP` whisper to spread responses over time (thundering-herd fix).
- Move collection timer to the broadcast site (12s window = 8s jitter + 4s buffer); `OnCommReceived` now just accumulates responses.
- Extract `ProcessVersionResponsesForHost` helper to clean up result logic.
- Guard `debugstack()` behind `VC_DebugEnabled` to avoid unnecessary call-stack walking in production.

## [v1.2.1] (2026-03-03)

Packaging metadata fixes — `.pkgmeta`, workspace, and TOC adjustments to align with the standalone-addon release flow.

## [v1.2.0] (2026-03-02) — Ace3 dependency, not embedded

Removed embedded Ace3 from the library. VersionCheck-1.0 now uses the global Ace3 libraries provided by users' standalone Ace3 install. Reduces zip size and avoids version conflicts when other addons embed Ace3 at a different version.

## Pre-history (v1.1.0 and earlier)

Initial public releases of the batched cross-guild version-check library. See git tag history for commit-level detail.
