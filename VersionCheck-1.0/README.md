# VersionCheck-1.0

A LibStub library for World of Warcraft addons that performs a single batched cross-guild version check at login and pops a one-time "you're out of date" alert per addon that needs updating. Designed to coexist with many host addons without exceeding Blizzard's 8-prefix-per-session cap on addon-message channels.

## For end users

You only need this addon installed if another addon you use depends on it (TOGProfessionMaster, Grouper, TOGBankClassic, FastGuildInvite, GuildRoster, etc.). If you're not running any of those, you can ignore VersionCheck — on its own there is nothing for it to check.

If you DO have it installed, the only things you'll ever notice are:

- A popup that appears at most once per session, per host addon, telling you that a guildmate is running a newer version and where to download it (CurseForge).
- A roster window, opened with `/vc` (or `/vcroster`, or `/versioncheck`), showing who in your guild is running which version of each addon.
- A red line in chat at login if GuildRoster or LibAceGUIWidgets is missing or too old, saying which one, what will not work without it, and to install and enable it. With both installed you see nothing.
- Slash commands:

| Command | What it does |
|---|---|
| `/vc` | Open (or close) the guild version roster. `/versioncheck` and `/vcroster` do the same |
| `/vcd` | Toggle debug logging |
| `/vcdon` | Enable debug logging (verbose log to chat) |
| `/vcdoff` | Disable debug logging |

### The roster window

Open it with `/vc`, `/vcroster` or `/versioncheck`; the same command closes it. One tab per addon that uses VersionCheck, and a list of your guild: name, rank, and their version. A member of a linked guild in your GreenWall confederation who has reported a version is listed too, with their rank *in their own guild* (when that guild's GuildRoster is recent enough to share it). Click a column header to sort by it, and again to flip the order; the list opens sorted by version. Where a version is missing the window says which kind of missing it is, rather than guessing -- `Not seen` (online, but has never told us), `Offline`, or `Unknown`. The status bar along the bottom shows which version of VersionCheck you are running, and the **i** icon beside it explains what each of those three states means.

**Opening it does not send anything, and neither does switching tabs.** The window is filled from the version announcements that were already arriving as guildmates log in, so leaving it open costs nothing and adds no chat traffic.

The **Refresh** button asks the guild again. It counts down for twenty seconds afterwards, because your guildmates ignore a repeat request inside that window -- pressing it sooner would send a message nobody answers and leave the list emptier than before you pressed it. Press it while they are still ignoring you (in the first twenty seconds after logging in, say) and it counts down the time actually left rather than doing nothing. If a refresh could not be sent at all (you are not in a guild, for instance) the button stays available rather than counting down for a request that never left. Every button has a tooltip saying what it does and what a click costs.

**Right-click a name** to whisper that player that their copy is out of date. The whisper names the addon and both versions -- theirs and the newest anyone in the guild is running -- so they can see at a glance whether it is true. The option only appears for someone who is actually behind; a player who is level, or one you have no version for, gets a note saying so instead, and your own row says "This is you". An addon author running an unreleased copy from source is never treated as out of date, in either direction.

**Guild leadership** -- anyone the guild master has granted officer permissions to, and the guild master -- gets a second button, **Notify guild**. It asks everyone at once and tells their VersionCheck to check *now*, so anyone running an older copy of one of your addons sees the normal update popup straight away instead of at their next login. Refresh and Notify share the same twenty-second countdown. Guildmates on an older VersionCheck simply answer as usual and check at their next login, as they always did.

Debug state persists across `/reload` via the `VersionCheck10_DebugEnabled` SavedVariable.

The popup is suppressed automatically if you're in combat — it will appear when combat ends.

## For addon developers

### Requirements

- Lua 5.1 (WoW addon environment)
- [Ace3](https://www.curseforge.com/wow/addons/ace3) installed as a separate addon (provides AceComm-3.0 and AceSerializer-3.0). VersionCheck does not embed Ace3.
- **LibAceGUIWidgets**, installed as a separate addon. A hard dependency of VersionCheck itself, declared in its own `.toc` -- you do not need to declare it in yours, and VersionCheck does not embed it.
- **GuildRoster** (LibGuildRoster-1.0), installed as a separate addon. From v1.5.0 it is `## OptionalDeps:` in VersionCheck's `.toc` and `required-dependencies` in its `.pkgmeta`: CurseForge still installs it alongside VersionCheck and the client still loads it first whenever it is present, but VersionCheck loads without it. The reason is a cycle: GuildRoster requires VersionCheck (its sister-guild sync finds a peer through it), and two addons that each hard-require the other are loaded by the client as neither.

A note on what those two are for, since they are the reason the dependency list grew. LibGuildRoster owns the one identity model: it decides what a player's qualified name is, so `Bob-Whitemane` and `Bob-Faerlina` stay two people instead of suppressing each other, and it is what fills the roster window with your guild. LibAceGUIWidgets supplies the roster window's list widget and its rate-limited button. Every use of LibGuildRoster in the library is resolved lazily and nil-safe, which is what makes the optional declaration safe; without it the window lists only players who have answered, with no rank or class colouring, and names are keyed without LibGuildRoster's canonicalizing (a bare same-realm name still gains your realm; see "How a row gets its name").

From v1.5.2 **VersionCheck also checks for both libraries itself once the world is entered and prints one line in chat per missing library** -- which it is, what stops working, and to install and enable it. The client only flags what the standalone `.toc` hard-requires, which does not cover GuildRoster (optional) or a copy of the library embedded in your addon, and the CurseForge relation that should install them is not reliable. A normal login with both present prints nothing.

### Supported clients

One `.toc` covers Classic Era, **World of Warcraft: Forever** (`16001`), Anniversary/TBC, Wrath, Cataclysm, Mists, Retail and the **Whitemane** private server (`38000`). There are no per-flavour code paths — everything the library calls exists on all of them, and the one API that genuinely moved between clients is feature-detected:

```lua
local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
```

WoW 11.x moved `GetAddOnMetadata` into `C_AddOns` and removed the bare global; Classic Era took the same change. Both branches, and the case where a client has neither, are covered by the test suite.

`## Interface:` carries **one number per client except Retail, which carries every current Mainline number** -- `120005, 120007, 120100` from v1.5.2, the same list as `DeltaSync`. A player's client flags an addon out of date unless its own exact number is listed, and v1.3.1's replace-rather-than-append (`120007` → `120100`) left players still on 12.0.5 and 12.0.7 flagged -- including anyone running an addon that hard-requires this one, which then loaded only with out-of-date addons allowed.

Verify a number against `C:\Program Files (x86)\World of Warcraft\.build.info` — it lists the real version of every installed product — and against the reference list in `DeltaSync`, rather than from memory.

**Not every entry is a Blizzard client.** `38000` is Whitemane, a private server. It will not appear in `.build.info` or anywhere in Blizzard's UI source, so a "verify against the official product list" pass will conclude it is bogus and delete it — it is not, and it must stay. Cross-check the rest of the AddOns tree (`DeltaSync` carries the same list) before removing any number you cannot account for.

**`16001` is World of Warcraft: Forever** (Battle.net product `wow_classic_beta`, codename Camelot): the Retail client running Classic Era content. It reports `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` -- there is no project constant for it -- so only the interface number tells it from Retail. This library never reads the project id. Its one Forever code path keys off the client's own switch, `RegionalUniqueNamesEnabled()`, which Blizzard's UI branches on and which is absent everywhere else: see "Names on WoW Forever" below. The beta also forgets SavedVariables between sessions, so `/vcdon` may not persist there. Forever is installed on the development machine (`_classic_beta_`) and the dev sync copies the library into it, but behaviour there has not yet been verified in the client. Added for FastGuildInvite v2.14.0, which hard-depends on this library and ships a `_Camelot` TOC.

#### Names on WoW Forever (MINOR 17)

A Forever character is `First Last`, unique across the region, with no realm. `UnitName` returns `(first, surname)` there, AceComm's sender still carries an internal realm (`First Last-Realm`), and a whisper to that realm-suffixed form is refused by the server while the player is online. So when `RegionalUniqueNamesEnabled()` is true:

- The library names itself on the wire (`__from`) as first name, the client's surname separator, and surname (`Me Myself`).
- Every key in `GetPeerVersions` and `GetRoster` is the full name with any `-Realm` suffix dropped. That includes a key from an older LibGuildRoster whose `CanonName` keeps the realm.
- Every whisper the library sends goes to the full name with no realm: replies, `RequestFrom`, and `WhisperUpdate`.
- A peer is keyed by the transport's sender name, not by its `__from`. VersionCheck copies before MINOR 17 on Forever send `First-Realm` there, the first name alone.

On every other client none of this runs, and names behave exactly as described under "How a row gets its name".

### Install + declare the dependency

```
## Dependencies: Ace3, VersionCheck-1.0
```

Add the dependency to your addon's `.toc`. VersionCheck-1.0 will auto-install on CurseForge when users install your addon.

**You do not declare GuildRoster or LibAceGUIWidgets yourself.** VersionCheck's own `.toc` and `.pkgmeta` declare them, so CurseForge installs them alongside it and the client loads them before it (LibAceGUIWidgets as a requirement, GuildRoster as an optional dependency -- see Requirements). Your addon's dependency line stays as above. If your addon already depends on either directly, nothing changes.

### The public API: the one correct wiring

Read this before writing your bootstrap. Copy the block below rather than inventing one -- four
consumers wrote four different bootstraps, and two of them guessed the same wrong pair of names.

**`VC:Enable(nameOrHost)` is the whole integration surface.** Feature-detecting `VC.Enable` is the
correct and sufficient guard:

```lua
local VC = LibStub and LibStub("VersionCheck-1.0", true)
if VC and VC.Enable then
    VC:Enable(self)
end
```

Use `VC:RegisterCheck(name, version)` instead only when you have **no addon object** to hand and
need to state your version explicitly:

```lua
local VC = LibStub and LibStub("VersionCheck-1.0", true)
if VC and VC.RegisterCheck then
    VC:RegisterCheck("MyAddon", GetAddOnMetadata("MyAddon", "Version"))
end
```

**Pass the RAW `## Version:` string, sentinel and all.** If your addon is running from unpackaged
source that value is the literal `VersionCheck-v1.5.3`, and that is exactly how this library
recognises a dev build and suppresses the update popup. Tidying it into something friendlier
re-enables update popups on every developer's machine, including yours.

#### What each name does

| Name | Status |
|---|---|
| `VC:Enable(nameOrHost)` | The primary entry point. Accepts an addon object with `:GetName()` and `.Version`, or a plain name string |
| `VC:RegisterCheck(nameOrHost[, version])` | Alias for `Enable` that also records an explicit version. **Added in MINOR 13** |
| `VC.version` / `VC.minor` | The loaded LibStub minor, as a number. Both spellings carry the same value. **Added in MINOR 13** |
| `VC:GetPeerVersions([addonName])` | What we have observed about other players' versions. **Added in MINOR 13** |
| `VC:GetRoster(addonName)` | One row per player for one addon, with a four-state `state`. The roster window's model. **Added in MINOR 13** |
| `VC:RequestCheck([push])` | Rate-limited refresh. Returns `true` when it broadcast, or `false` plus seconds remaining. `push` asks receivers to decide now. **Added in MINOR 13** |
| `VC:RequestFrom(name)` | Ask ONE player what they run, by whisper. Returns `true` when a request was handed to the client. **Added in MINOR 14** |
| `VC:RequestAbout(addonName)` | Ask the guild and confederation about ONE registered addon. Same return shape and clock as `RequestCheck`. **Added in MINOR 14** |
| `VC:FlushGreenWall()` | Send the parked GreenWall half of a request now, from YOUR hardware event. `true` when something went out. **Added in MINOR 14** |
| `VC:IsLeadership()` | Whether the player holds officer permissions, by LibGuildRoster's predicate. **Added in MINOR 13** |
| `VC:NewestKnownVersion(addonName)` | The highest build anyone, us included, is known to run. **Added in MINOR 13** |
| `VC:IsBehind(entry, addonName)` | Whether a roster row is behind the newest known; `nil` when it has no version. **Added in MINOR 13** |
| `VC:WhisperUpdate(entry, addonName)` | Whisper a player the canned out-of-date message; returns the text. **Added in MINOR 13** |
| `VC:ToggleRoster()` / `VC:RefreshRoster()` | Open or close the roster window; repaint it from the model. **Added in MINOR 13** |
| `VC.callbacks` | CallbackHandler registry: `OnPeerVersion`, `OnCheckComplete`, `OnRosterChanged`. **Added in MINOR 13** |
| `VC:ReportMissingLibraries()` | The login check for GuildRoster and LibAceGUIWidgets; runs itself at `PLAYER_ENTERING_WORLD`, once per session. Returns the number of lines printed, or `nil` once already reported. You do not need to call it. **Added in MINOR 16** |
| `_G.VersionCheck` | **Never assigned**, and will not be. Reach the library through `LibStub("VersionCheck-1.0", true)` |

Everything marked MINOR 13, 14 or 16 is additive and feature-detectable. Guard on the name if your addon
may load beside an older embedded copy -- LibStub keeps only the highest minor, and you cannot
assume it is this one.

#### Reading what other players are running

`VC:GetPeerVersions()` returns everything observed this session, and
`VC:GetPeerVersions("MyAddon")` narrows it to one addon:

```lua
for sender, observation in pairs(VC:GetPeerVersions("MyAddon")) do
    print(sender, observation.version, observation.via, observation.at)
end
```

`via` is `"REQ"` or `"RSP"` -- how we came to know it -- and `at` is the `GetTime()` when we last
heard it. Show them if you build a roster view: a value learned four hours ago is not the same claim
as one confirmed ten seconds ago, and presenting them identically is how version checkers end up
lying quietly.

**This includes addons you do not have installed.** A player's request lists their own registered
addons, so it is how you discover a guildmate runs something you have never seen. It also reaches
GreenWall confederation members who can never whisper you back.

**It costs nothing.** Version data is only ever read from broadcasts and replies the library was
already receiving -- asking for it sends no messages.

#### The roster model: one row per player, four states

`VC:GetRoster("MyAddon")` is what the built-in window renders, and what you should read if you build
your own view. It merges the guild roster (from LibGuildRoster) with everything observed, so a
player who has never answered still has a row -- a view that can only show people who replied is
answering the question nobody asked.

```lua
for _, row in ipairs(VC:GetRoster("MyAddon")) do
    -- row.name       "Bob-Whitemane", realm-qualified
    -- row.state      "reported" | "silent" | "offline" | "unknown"
    -- row.version    only when state == "reported"; also row.via ("REQ"/"RSP") and row.at
    -- row.rank, row.rankIndex, row.classFile, row.online   from the guild roster
    -- row.guild      MINOR 15+: set ONLY for a sister-guild member (LibGuildRoster's key for that
    --                guild); nil for your own guildmates. Their rank is their rank THERE.
    -- row.account    the alt-grouping key; collapse alts or not, your call
    -- row.isSelf     true on our own row
end
```

A member of a sister guild (a GreenWall confederation peer whose roster LibGuildRoster holds) gets
`rank`, `rankIndex` and `classFile` from that sister roster once they have reported, and `guild`
says which one. Needs GuildRoster 0.8.2 (MINOR 21) on the *provider's* side for the rank; before
that the rank is nil, as it always was. `online` is never set for them.

**How a row gets its name.** A peer at MINOR 13 or later names itself on the wire (`__from`,
realm-qualified), and that is the row. A peer too old to do so is keyed on the transport's sender
string -- and from MINOR 15 a *bare* one gains your own realm, because the client hands a name
bare exactly when it is on your realm (AceComm's `Ambiguate(sender, "none")`), so `Bob` and the
guild roster's `Bob-Whitemane` are one row. A name that arrives with a realm is never altered.
The realm added -- here and in the library's own `__from` -- is `GetNormalizedRealmName()` from
MINOR 16: `Bob-OldBlanchy`, the spelling every client API uses, never the display name
`Bob-Old Blanchy` with its space, which matched no roster row. On WoW Forever no realm is ever
added and any realm is dropped; see "Names on WoW Forever".

**Render the four states differently.** `reported` is a fact. `silent` -- online, never reported --
is *probably* "does not have the addon", but that is an inference; `offline` says nothing either
way; `unknown` is someone outside the roster (a confederation peer, an ex-member, or the roster
library absent). Collapsing the last three into one "Not installed" is how version checkers end up
stating guesses as facts.

Rows are sorted by name and the order is stable across sessions. Reading the roster sends nothing.

#### Refreshing, and why it sometimes refuses

```lua
local fired, wait = VC:RequestCheck()
if not fired then
    print(("Try again in %.0f seconds."):format(wait))
end
```

Peers ignore a repeat request from the same player for 20 seconds, so a broadcast sooner than that
is answered by nobody and clears the results you already had. `RequestCheck` refuses rather than
firing into silence, and counts the automatic login check against the same cooldown. Wire it to a
button and use the returned seconds to disable that button, rather than calling `FireBatch`
directly.

Two kinds of `false`, and a button should tell them apart: `false, N` with `N > 0` is the clock --
count down for `N`. `false, 0` means there was nothing to send: no hosts registered, or the player
is not in a guild (`IsInGuild()`, feature-detected). Do not start a countdown for that one; nothing
went out. The built-in Refresh button does exactly this.

#### Asking the guild to decide now: `RequestCheck(true)`

A peer records every version a request carries, but it only *decides* -- compares against its own
and shows the update popup -- when its own collection window closes, at its login or when one of its
hosts re-triggers a check. So a plain refresh from you cannot make an out-of-date guildmate see
anything until their next check.

`VC:RequestCheck(true)` sends the same request with one extra reserved key, `__push`. A receiver at
MINOR 13 or later runs its existing decision on receipt, for the addons it shares with you: same
comparison, same once-per-version dedup, same dev-build suppression, same combat deferral. No new
popup path -- only *when* the one that exists runs. A receiver on an older copy ignores the key and
behaves exactly as before.

The built-in window exposes this as the **Notify guild** button, shown only when
`VC:IsLeadership()` is true -- LibGuildRoster's officer-permission predicate, which covers the GM.
The wire itself does not check rank; it cannot, since a peer has no way to verify another member's
permissions. The rate limit is shared with the plain refresh, because the receivers' dedup does not
care which button you pressed.

#### Asking one player: `RequestFrom(name)`

```lua
if VC.RequestFrom and VC:RequestFrom("Bob") then
    -- their answer arrives as an OnPeerVersion callback, and in GetPeerVersions / GetRoster
end
```

The guild broadcast never reaches a player outside your guild -- a sister-guild member on a
GreenWall confederation, or anyone `/who` listed. `VC:RequestFrom(name)` sends the same request
the broadcast carries, by whisper, to that one player. Their copy answers exactly as it would a
broadcast, by whisper, and the versions land where every other answer lands: `OnPeerVersion`
fires, `GetPeerVersions` and `GetRoster` show them. A bare name gains your own realm; a
realm-qualified one is sent as given. On WoW Forever the realm is dropped instead of added.

It is one whisper per call and nothing more: no retry, no polling, no collection window, and it
does not count against `RequestCheck`'s 20-second clock, which is about what your guildmates
suppress. Two things to know before relying on it. The answer is always in full, even from a
player who already told you everything, because a targeted ask means you want it. And a
**guildmate** asked inside 20 seconds of your own broadcast drops it as a duplicate -- that is
their dedup working, and it is not the case this exists for. `true` means the request was handed
to the client, not that the player is online or will answer; a player who is not on a connected
realm cannot be whispered at all.

Built for LibGuildRoster, which asks a candidate what they run before pulling a roster from them.

#### Asking everyone about one addon: `RequestAbout(addonName)`

```lua
local fired, wait = VC:RequestAbout("MyAddon")   -- MyAddon must be one of your registered hosts
```

The same broadcast as `RequestCheck` -- AceComm to the guild, and the GreenWall confederation when
GreenWall is present -- but the request names one addon, so every receiver answers about exactly
that one and the GreenWall message fits with room to spare. Same two kinds of `false` as
`RequestCheck`, and the same 20-second clock, shared: peers drop a repeat request from you inside
that window whatever it asks. `false, 0` also covers an addon that is not a registered host -- the
request carries your own version of it, and you have none for an addon you do not run. Like
`RequestFrom`, it opens no collection window and clears nothing; answers arrive through
`OnPeerVersion`. Built for LibGuildRoster's "who runs GuildRoster, and which version".

#### Who is behind, and telling them

```lua
local newest = VC:NewestKnownVersion("MyAddon")      -- highest anyone, us included, is known to run
for _, row in ipairs(VC:GetRoster("MyAddon")) do
    local behind = VC:IsBehind(row, "MyAddon")       -- true, false, or nil when row.version is nil
    if behind then VC:WhisperUpdate(row, "MyAddon") end
end
```

`IsBehind` answers `nil`, not `false`, for a row with no version -- or with a dev build's
`VersionCheck-v1.5.3`, which is not a version: "not behind" would be a claim about something you
cannot measure. Dev builds are never candidates for newest either, so a developer running from
source is neither whispered nor whispered about. `WhisperUpdate` sends *"Your MyAddon is out of date (you
have 1.0.0, latest is 1.5.0), please update."* to `row.name` (realm dropped on WoW Forever, from
MINOR 17) and returns the text, or `nil` when
the client offers no way to whisper. It prefers `C_ChatInfo.SendChatMessage` and falls back to the
bare global, which on Classic Era is a deprecation shim for the namespaced one. The built-in window
offers this from a right-click on any row.

#### Reacting as answers arrive

```lua
VC.RegisterCallback(myAddon, "OnPeerVersion", function(_, sender, addonName, version, via, changed)
    if changed then myAddon:RefreshRow(sender, addonName, version) end
end)

VC.RegisterCallback(myAddon, "OnCheckComplete", function() myAddon:StopSpinner() end)

VC.RegisterCallback(myAddon, "OnRosterChanged", function() myAddon:Repaint() end)
```

`changed` is false when a player re-announces a version you already had, which is the common case
every time someone logs in -- gate any visible reaction on it. `OnCheckComplete` means the
collection window closed, not that everyone answered; nothing can know that. `OnRosterChanged`
fires when a guild member joins, leaves, comes online, goes offline or changes rank -- LibGuildRoster's
seven roster events folded into one repaint signal, so you do not have to learn that library's
vocabulary. `GetRoster` already reflects the change by the time it fires.

Register with the **dot** form, `VC.RegisterCallback(target, ...)`, as CallbackHandler expects.

#### The built-in window

`VC:ToggleRoster()` is what `/vc` calls: it builds the window on first use (LibAceGUIWidgets'
ClearFrame, one tab per registered host, a RowList) and toggles it thereafter. `VC:RefreshRoster()`
repaints an open window from the model and is safe to call at any time -- it returns `false` and
does nothing if no window has been opened. Neither sends anything. If your addon wants a "versions"
button, call `ToggleRoster` rather than building a second window.

#### The wire, and the keys you must not use

A request is a serialized table of `addonName -> version`. Five keys are reserved control fields
and are never treated as addon names: `__v` (protocol version), `__resync` (asker has no memory --
send everything), `__from` (the sender's realm-qualified name), `__push` (decide now), and `__all`
(answer about everything you have -- the GreenWall trigger, MINOR 14). **Every key beginning with
`__` is reserved from MINOR 13 onward** -- do not register an addon whose name
starts that way. Older copies look a reserved key up in their hosts table, find nothing, and ignore
it, which is what keeps every addition backwards compatible.

`RegisterCheck`, `VC.version` and `VC.minor` did not exist before MINOR 13, so **guard for them** if
you support older embedded copies -- LibStub keeps only the highest minor loaded, and you cannot
assume that is this one:

```lua
if VC.RegisterCheck then ... else VC:Enable(self) end
```

The reason these three exist at all is worth stating, because it is the failure they prevent.
Shipped consumers were already writing `if VC.RegisterCheck then VC:RegisterCheck(NAME, VERSION)
elseif VC.Enable then VC:Enable(self) end` against a library where the name had never been defined.
The `elseif` rescued them, so every version check worked and the dead branch was invisible -- but
the day this library defined `RegisterCheck` for *any* purpose, those addons would have taken the
first branch, stopped calling `Enable`, registered no host, and never warned again, with nothing
erroring and nothing logged. Defining the name to mean what those call sites plainly intend is what
makes it impossible to re-purpose underneath them.

The minor is also still available from LibStub itself, which is where it has always lived:

```lua
local VC, minor = LibStub:GetLibrary("VersionCheck-1.0", true)
```

### Integrate from an AceAddon

```lua
-- In your :OnEnable() or :OnInitialize()
local VC = LibStub and LibStub("VersionCheck-1.0", true)
if VC and VC.Enable then
    VC:Enable(self)
end
```

VersionCheck reads `self:GetName()` for the addon name and `self.Version` for the version string. Make sure your `.toc` has a `## Version:` line.

### Integrate from a non-AceAddon

```lua
local VC = LibStub("VersionCheck-1.0", true)
if VC and VC.Enable then
    VC:Enable({
        GetName = function() return "YourAddonName" end,
        Version = GetAddOnMetadata("YourAddonName", "Version"),
    })
end
```

Or pass the addon name directly as a string (VersionCheck falls back to `GetAddOnMetadata(name, "Version")` for the version):

```lua
VC:Enable("YourAddonName")
```

Both forms report the same version to other players. That was not true before v1.3.0: the string form answered other players' checks with `"unknown"`, which sorts below every real version, so a string-registered host could never be the newest version anyone saw and nobody was ever prompted to update it. If you use the string form, make sure your `.toc` has a `## Version:` line — it is the only source.

### Make `/vcdon` survive `/reload` in embedded-only setups

If your addon embeds VersionCheck-1.0 (rather than depending on the standalone copy from CurseForge), add this line to your `.toc`:

```
## SavedVariables: VersionCheck10_DebugEnabled
```

Without this declaration, the SavedVariable has no owning addon and the debug toggle resets to off on every `/reload`. Standalone VersionCheck installs handle this declaration themselves.

**Embedding no longer removes the need for the two standalone libraries.** From v1.4.0 the library resolves LibGuildRoster-1.0 and LibAceGUIWidgets-1.0 at load; an embedded copy running without them still answers version checks and still shows the update popup, but has no roster window, and names are keyed without LibGuildRoster's canonicalizing. Depending on the standalone VersionCheck-1.0 is the supported path.

### GreenWall confederation transport

If [GreenWall](https://www.curseforge.com/wow/addons/greenwall) is installed and the bridge channel is connected, VersionCheck will additionally broadcast its REQ over GreenWall's confederation bridge — so the check reaches every linked co-guild, not just your literal `<guild>`. Responses still come back as AceComm whispers (which work across connected-realm clusters, but not across separate server clusters).

No host-side change is required to opt into this. The transport is fully internal to the library; if GreenWall isn't installed or its bridge isn't connected, VersionCheck falls back silently to AceComm GUILD only.

**What goes over GreenWall is a trigger, not the inventory.** GreenWall carries one chat-channel
message of at most 255 characters and does not split a longer one, so a full batch of more than a
handful of addons never fitted -- from MINOR 14 the GreenWall leg carries the control fields, a
`__all` key, and as many addon names as fit, in name order. A receiver at MINOR 14 or later answers
about every addon it has; an older one answers about the names that fit, as it always did. The
AceComm leg is unchanged and still carries everything. Nothing in the reply path changed: replies
are AceComm whispers, which split as needed.

**When it goes out.** GreenWall's send bottoms out in `SendChatMessage`, which the client only
allows from a hardware event, so the GreenWall half of every request is *parked* and released by
the player's next chat keystroke. If your addon already has the player clicking something -- a
button, an overlay -- call `VC:FlushGreenWall()` from that click and it goes out then instead:

```lua
if VC.FlushGreenWall then VC:FlushGreenWall() end   -- inside your OnClick / OnMouseDown
```

Returns `true` when a parked request was sent, `false` when nothing was parked or GreenWall is
absent. **You guarantee the hardware event**; the library cannot check it and does nothing else --
no rate limit (the parked request already passed one), no collection window. Guildmates who heard
the AceComm half inside the last 20 seconds drop this one as a duplicate; that is their dedup
working, and the confederation, which never heard the AceComm half, answers.

### Running the tests

The library has an offline unit-test suite that runs without the game client, built on the shared
[WoWAPITesting](https://github.com/Pimptasty/WoWAPITesting) harness. It needs a **Lua 5.1
interpreter and nothing else** — no LuaRocks, no busted, no C modules.

```sh
git clone --recurse-submodules …          # or: git submodule update --init
lua Tests/wowapi/run.lua                  # from the repo root
lua Tests/wowapi/coverage.lua VersionCheck-1.0.lua
```

Run the **whole** suite, not just the file you changed: every spec shares one Lua state, so a global
left reassigned corrupts *later spec files* in a way a single-file run cannot reproduce.

`coverage.lua` also takes spec files, auto-detected by the `_spec.lua` suffix — pass the ones that
cover your target and it measures only those, instead of running the entire suite to measure one
file. Use that for the edit loop and one unscoped run before a release, since a scoped figure is
lower than the truth:

```sh
lua Tests/wowapi/coverage.lua VersionCheck-1.0.lua Tests/popup_spec.lua Tests/request_spec.lua
```

The specs load the **installed** Ace3 from `../Ace3`, so the sibling addon has to be present — they
exercise the exact library code that ships to players rather than a vendored copy. Tests are run
locally, by hand; there is deliberately no CI workflow for them. `Tests/` is excluded from the
packaged release.

`Tests/HARNESS_CONTRACT.md` is the **historical record** of what this library asked of the shared
harness through August 2026 — all six delivered. Requests since then travel as threads in writ's
inbox rather than as writes to that file, and it is no longer appended to. `Tests/env_vc.lua` holds
what is genuinely this addon's own -- the GreenWall API fake (GreenWall is a third-party addon, not a
Blizzard API), the jitter freeze, the payload helpers, and the library reload -- plus ONE local
stand-in: `GetNormalizedRealmName`, which the harness's base env does not define yet. It is marked
for deletion in the file and requested on writ's harness channel.

The specs that build the real window (`Tests/zz_windowbuild_spec.lua`, `Tests/zzz_probe_spec.lua`)
opt into the harness's widget layer and load the **installed** LibAceGUIWidgets and its RowList; they
`pending()` rather than fail when that sibling is not present. Note that this loads the sibling's
live working tree, uncommitted edits included — a green run there is evidence about this disk, not
about a release.

`Tests/wowapi` is a submodule shared by ~20 addons — **never edit it from here**; the next pull
discards the change and it would apply to all of them. Read its `README.md` "Adoption log" at the
start of any session that touches tests, and check the pin against it.

The specs drive the **real** paths rather than calling methods: `PLAYER_ENTERING_WORLD` on the
library's own frame, AceComm's actual `CHAT_MSG_ADDON` receive handler, real AceSerializer payloads,
real ChatThrottleLib. That matters here — `TriggerVersionCheck` is a compatibility shim that
deliberately does nothing until PEW has fired, so calling it proves nothing.

Two things worth knowing before adding specs:

- **`FireBatch` is already scheduled.** `PLAYER_ENTERING_WORLD` queues one 5 seconds out. A spec that
  calls `VC:FireBatch()` by hand while that is pending will have it land mid-test, empty
  `VersionResponses` and restart the collection window underneath the assertions. Drive the login
  sequence (`env.firePEW(VC)` then `wow.advanceTime(5)`) instead.
- **Advance the clock with `wow.advanceTime`.** AceComm hands every message to ChatThrottleLib,
  whose queue drains only from its frame's `OnUpdate` — so a message CTL chose to **queue** is never
  delivered unless something ticks that frame: `wow.sent` stays empty with no error, and `bQueueing`
  latches so every later send in the session is stuck behind it. `wow.advanceTime` slices the clock
  and ticks `OnUpdate` after each slice, which is what makes the despool happen.

  There used to be an `env.advance` helper here that did the ticking itself. **It no longer exists**
  — it was a local stand-in for a harness gap, that gap was closed on 2026-08-04, and keeping a copy
  alongside the real thing is how two sources of truth drift apart while the suite stays green. Call
  `wow.advanceTime` directly.

## License

[MIT](LICENSE). See `CHANGELOG.md` for version history.

## Community / bug reports

Open an issue on the [CurseForge project page](https://www.curseforge.com/wow/addons/versioncheck-1-0).
