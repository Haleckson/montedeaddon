# LibQuestDB

A standalone, **offline quest database** library for World of Warcraft Classic,
for addon authors. It answers the questions Questie does not: what a quest
**pays**, how much **XP** it gives a character of a given level, what its
**text** says, and which **route** a character can actually take to get
there. All of it is static data shipped with the addon and read through
LibStub, so nothing has to be in the player's log or the client's cache, and no
server round-trip is ever made.

It is the quest counterpart to LibItemDB and LibProfessionDB. The folder on
disk is `QuestDB`; the CurseForge project is **LibQuestDB** (project id
1700352, slug `questdb`).

**Not to be confused with QuestieDB.** Questie ships its own database as a
separate addon named `QuestieDB` (globals `QuestieDB`, `NpcDB`,
`LibQuestieDB`, whose quest table is aliased `QuestDB`). That is Questie's
data, for Questie. This library is the `QuestDB` folder with LibStub major
`LibQuestDB-1.0`; it defines no global at all, so the two do not collide,
depend on or replace each other.

## Features

- **Rewards for every quest that has any:** items always given, items the
  player chooses one of, money, reputation, spells, and the item handed to the
  player when the quest is accepted.
- **The reverse lookup:** which quests give, offer or start with an item, so an
  item tooltip or a bank list can say "quest reward" and name the quest.
- **Quest structure:** givers, finishers, objectives, prerequisites, chains,
  exclusivity, breadcrumbs, race and class masks, zone, flags -- in Questie's
  field names, measured against Questie's curated data at 92 to 100% per
  field, with the reverse links from an NPC, object or item to its quests.
- **NPCs and objects: who and where.** Every creature and object template's
  name, title, level range, rank, flags, faction side and -- for a trainer --
  which kind it is and which class it teaches, by column rather than by
  reading its title; and where each one stands as
  zone-map percentages in Questie's shape, converted from the source's world
  yards with the client's own zone rectangles; the spawn zones agree with
  Questie's 90% of the time and 94% of its points are ours within 1% of the
  map.
- **Drop rates for every quest item,** from every creature, chest and
  container that can drop it, derived the way the server rolls its loot
  tables and agreeing with Questie's own resolution of the same tables on
  100% of shared pairs.
- **Zones and dungeons:** every area's parent and map, so a spawn's
  coordinates can be placed on the world; every dungeon's outdoor entrances;
  the quest-sort category names; where every "explore" objective's trigger
  stands.
- **Enough to stand in for Questie as a quest addon's data source:** every
  NPC, object and quest-item id can be listed; every quest an id is involved
  in -- as a giver, a finisher **or an objective** -- can be looked up; a kill
  objective names the other mobs that count for it; and the quests the raw
  data says nobody can take today (nothing starts them, the game has retired
  them, or they exist only while a game event runs) are flagged, with the
  reason.
- **Breadcrumbs kept optional.** Where the source stores an optional lead-in
  quest as a required pre-quest, a hand-kept list of pairs verified in game
  puts it back as a breadcrumb. See
  [Regenerating the data](#regenerating-the-data).
- **Quest XP, derived the way the server derives it,** with a call that scales
  it to any player level and knows a capped character earns none.
- **Signed money and reputation.** A quest that costs 300 gold or loses standing
  with a faction says so; nothing on the path applies `abs()`.
- **Quest text, per locale:** title, the quest-giver's speech, the objectives
  summary, both turn-in texts, the end text and per-objective overrides. English
  ships now; the framework takes other languages as separate files.
- **Locale-independent reward data.** Every reward value is an id or an integer,
  so one table serves every client language. Item names and icons are
  LibItemDB's job; resolve them from the ids.
- **A path graph per continent** for route-following HUDs: named places,
  directed links typed walk, transport (boats, zeppelins, elevators), flight
  and portal, the polyline the emulator's bots actually walk for every walk
  link, the gryphon's own route for every flight and the ship's route for
  every boat and zeppelin, so a route goes round cliffs and water and a ride
  draws as the curve it takes. Inside the capital cities walks are kept to
  within 2 yards of the route, so a line follows the streets rather than
  crossing buildings. Boats and flights are routable links, because
  from some places they are the only way, and each carries the faction that
  can take it.
- **Routes off the road, into caves and buildings.** Where a quest target
  stands somewhere a straight line from the path graph would cross rock,
  `GetSpawnApproach` gives the walking route from a graph node to it, built
  from where creatures and objects actually stand. See
  [Off the graph](#off-the-graph-routes-into-caves-and-buildings).
- **Why a quest is missing.** `GetCoverage` tells a quest the client lists
  but nothing offline describes from an id nothing knows, so a consumer can
  explain a gap instead of showing a blank that looks like a bug.
- **WoW Forever's own quests,** from the Forever client itself: 775 of them
  with title, level, group size, log summary and objective lines. No world
  database has them, so their givers, locations, rewards and required level
  are not known. See
  [WoW Forever](#wow-forever).
- **Questie when you have it, QuestDB when you don't.** Where Questie is
  installed, its hand-curated rows answer `GetQuest`; where it is not, the
  shipped tables do, and no consumer has to know which. See
  [Where the answers come from](#where-the-answers-come-from).
- **Classic Era, TBC and WoW Forever**, each with its own TOC. Era and TBC
  each have their own data capture. Forever reads Classic's, placed with its
  own client's zone maps.
- **No required dependency.** The library loads and answers with LibStub
  alone; Questie is an `OptionalDeps`.

## Depending on it

Two names, both required, and they differ:

| Where | Value | Why |
| --- | --- | --- |
| Your `.toc`, `## Dependencies:` | `QuestDB` | the **folder** name; makes the client load it before you |
| Your `.pkgmeta`, `required-dependencies:` | `questdb` | the CurseForge **slug**; makes the app install it for your users |

Then resolve the library where you use it:

```lua
local QuestDB = LibStub("LibQuestDB-1.0")
```

Every call is nil-safe and accepts a quest id as a number or a numeric string.

**Feature-gate by name, not by number** (MINOR 17). If you must run against an
older copy another addon may have bundled, ask for the thing you need:

```lua
if QuestDB.HasCapability and QuestDB:HasCapability("trainer-fields") then
    local n = QuestDB:GetNPC(npcId)
    ...
end
```

That degrades correctly against a copy too old to have the reader at all, which
a number comparison cannot, and it does not ask you to remember which release
carried which feature. `QuestDB:GetCapabilities()` lists them, ascending, in a
fresh table. The names so far:

| Capability | What it means |
| --- | --- |
| `townsfolk-enumeration` | `GetNPCIds` / `GetObjectIds` / `GetQuestItemIds` and the `GetQuestsInvolving*` links: the whole roster, not only the ids some quest named |
| `trainer-fields` | `trainerType` / `trainerClass` on `GetNPC`, with `QuestDB.TRAINER_TYPE` naming them, instead of matching a localised subtitle |
| `quest-list-header` | `GetQuestHeader`: the few fields a quest **list** shows, read off the packed row |
| `quest-coverage` | `GetCoverage`: tells an id the **client** lists but nothing offline describes from an id nothing knows, so a missing quest can be explained rather than silently omitted |
| `spawn-approach` | `GetSpawnApproach`: a walking route from the path graph **into** a cave, mine or building where a straight line from the graph would cross rock |
| `retired-quests` | `"retired"` as a hidden reason: a quest a giver still starts that the game has retired -- see [Hidden quests](#hidden-quests) |

The set only grows -- a name is never removed or repurposed once it ships. A
capability describes **the code**, not the data: it is true on a client where
the matching Data file was never loaded, and there the reader answers its own
documented "no data" value. So ask `HasCapability` before **calling**, and the
reader's own `nil` contract before **believing** an empty answer. For anything
with no name yet, `QuestDB.MINOR` still works; the history of what each number
added is the comment at the top of `LibQuestDB-1.0.lua`.

## Where the answers come from

**Questie is preferred when it is installed** (MINOR 12 added this, MINOR 13
widened it, MINOR 20 added the id lists): `GetQuest`, `HasQuest`,
`GetQuestIds`, `GetNPC`, `HasNPC`, `GetNPCIds`, `GetObject`, `HasObject`,
`GetObjectIds`, `GetNPCSpawns` and `GetObjectSpawns` answer from
Questie's hand-curated rows on a player who has Questie, and from the shipped
tables on a player who does not. That is the whole design -- Questie is an
`OptionalDeps`, never required, and the shipped data is what makes the library
work without it.

```lua
print(QuestDB:GetDataSource())          -- "questie" or "questdb"

QuestDB:RegisterSourceChanged(function(source)
    -- Called at once with the current source, and again whenever it changes.
    myIndex = nil                       -- rebuild anything cached from GetQuest
end)

-- The shipped row on its own, whatever the source is: a deterministic offline
-- answer for a parity check or a bug report.
local raw = QuestDB:GetShippedQuest(questId)
```

**Two things a consumer must know:**

- **Answers can change mid-session.** Questie's data is not valid until after
  login (its own handshake, `Questie.API.isReady`), so a list built at
  `ADDON_LOADED` comes from the shipped tables and one built later may not.
  `RegisterSourceChanged` is the notification; it fires once immediately, so
  registering and rebuilding is one code path rather than two.
- **Not everything switches.** Rewards, XP, quest text, the path graph, drop
  rates, zones, trainers and `hidden` are always the shipped data, because
  Questie has no counterpart for them. What does switch:
  - Within `GetQuest`, every field Questie carries is Questie's when Questie
    answers. `hidden` stays ours, and so does **`preQuestActive`** -- the "a
    pre-quest must be **in your log**" list, which Questie folds into
    `preQuestGroup` as a signed id and so cannot express. All 45 Era quests
    that have one are also in Questie's set, so it is kept deliberately rather
    than by accident.
  - Within `GetNPC`, Questie's `name`, `subName`, `minLevel`, `maxLevel`,
    `rank`, `npcFlags` and `friendlyToFaction` -- the fields where its curation
    measures better than this dump (level ranges agree on 94.6%, `npcFlags`
    99.1%, `friendlyToFaction` 96.9%). `killCredit` and the trainer columns
    stay ours; Questie has no counterpart.
  - **`GetNPCSpawns` and `GetObjectSpawns` answer whole**, and the `zoneID` on
    both headers moves with them, because it names one of that row's own
    areas. A spawn table is one answer about where a thing is, so the two
    derivations are never mixed. See the known cost below.
  - **The reverse links do NOT follow, and this is the one place the library
    knowingly disagrees with itself.** `GetQuestsStartedByNPC`,
    `GetQuestsInvolvingNPC` and the rest are always built from the shipped
    rows, so on Era there are **96 quests** where `GetQuest` names a giver the
    reverse index does not, or the reverse. Making them source-aware means a
    whole-dataset pass inside the first `GetQuest` -- and a consumer's list
    build calls `GetQuest` once per quest in the game, so that is a frozen
    client, not a slow call. It was built, it shipped, it froze, it was
    reverted; the measurements are in the changelog. **If you need the two to
    agree, intersect them yourself.**
  - **`GetQuestHeader` ignores the source entirely**, by design and by the
    asking consumer's request: a source read per quest is what makes a
    whole-dataset walk expensive, and this reader exists to be cheap. So on a
    Questie player a list built from `GetQuestHeader` and a pane built from
    `GetQuest` can differ -- `name` agrees on 99.8% of shared Era quests and
    the four numeric fields on 98-100%. **The pattern to copy:** gate on
    `GetDataSource() == "questdb"` and take the fast path only there, where
    the two reads are the same bytes and the divergence is zero; fall back to
    `GetQuest` when a source is answering. That puts the speed on the player
    without Questie, who is the one the shipped data exists for, and the
    accuracy where a disagreement would be invisible.
  - Within `GetObject`, **only `zoneID`**. Questie's object `name` and
    `factionID` were measured and would lose: 80 of its 83 name differences
    are an empty string where this dump has a name, and its `factionID` is
    absent on 681 objects the dump gives a faction for while disagreeing on
    none.

**Known cost of the spawn switch, stated rather than hidden.** Questie's
placements are not a superset of ours. On Era, taking them drops 990 NPC areas
and 664 object areas this dump has, and gains 700 and 646 of Questie's -- most
rows agree exactly (6,615 of 7,620 NPCs), and the rest is a trade rather than
an upgrade. It is still the right answer under "use Questie if it's available":
those are the placements a Questie user already sees today, so this is parity
with Questie, which is the stated goal.

**But no entity is orphaned by it**, which is the number that matters to a
consumer building a list: of the 7,540 NPCs and 7,880 objects the shipped data
places, **zero** become placeless when Questie answers. The resolver falls back
**per id**, so anything Questie does not place keeps this library's points --
2,964 of those objects have no Questie row at all. Exactly 5 NPCs lose their
last usable map coordinate (all elite or boss mobs Questie marks instance-only)
and no objects do.

Where a judgement about a player's intent is involved, this library ships the
fact and the consumer makes the decision -- it will tell you a quest is
`seasonal`, not whether your list should hide it.

`GetShippedQuest(questId)` is the shipped row with no source over it, for a
consumer that wants the deterministic offline answer. There is no
`GetShippedNPC`: nothing has needed one.

A source other than Questie can register itself with
`RegisterDataSource(name, resolver)`; the contract is in the library's own
comments, and `QuestieSource.lua` is the worked example. A resolver returns a
**partial** table -- only the fields it means to replace -- and a field it
means to be **nil** is set to `QuestDB.NONE`, because an absent key means
"keep the shipped value" and a Lua table cannot carry an explicit nil. Without
that sentinel a source could add and change values but never remove one. A
resolver that wants something from the shipped row must call
`GetShippedQuest`, never `GetQuest`, which would re-enter it.

## Rewards

```lua
local r = QuestDB:GetRewards(questId)
if r then
    for _, e in ipairs(r.items)   do print("always:", e.id, "x", e.count) end
    for _, e in ipairs(r.choices) do print("pick one:", e.id, "x", e.count) end
    for _, e in ipairs(r.rep)     do print("rep:", e.faction, e.value) end   -- value may be < 0
    if r.money then
        if r.money < 0 then print("costs", -r.money, "copper")
        else print("pays", r.money, "copper") end
    end
    if r.srcItem then print("handed on accept:", r.srcItem.id, "x", r.srcItem.count) end
end
```

`GetRewards(questId)` returns `nil` when the quest has no rewards or is unknown,
otherwise a fresh table you may keep or mutate:

| Field | Meaning |
| --- | --- |
| `items` | `{ {id=, count=}, ... }` always given; empty table when none |
| `choices` | `{ {id=, count=}, ... }` the player picks **one**; empty table when none |
| `money` | copper paid at turn-in. **Signed:** negative means the player pays. `nil` means the quest pays no money at turn-in below the level cap, which is most quests |
| `moneyMaxLevel` | copper paid **instead of XP** to a character at the level cap, **on top of** `money`: six copper per point of full XP, so the quest window at the cap shows `money + moneyMaxLevel`. `nil` when nothing is paid there, including the quests flagged not to convert XP to money. Measured against the live client (see below) |
| `xp` | the quest's **full-value** XP, for a player within five levels of it: Blizzard's tier for the level, rounded as the game shows it (see below). Label it "up to"; use `GetQuestXP` for a specific player |
| `questLevel` | the quest's level, or `nil` where the source stores none |
| `rep` | `{ {faction=, value=}, ... }`. **Signed:** a negative value is standing lost |
| `spell` | the spell **shown** as the reward, or `nil` |
| `spellCast` | the spell **cast on the player** at turn-in, or `nil` |
| `srcItem` | `{id=, count=}` handed to the player when the quest is **accepted**, or `nil` |

`QuestDB:HasRewards(questId)` is the cheap existence check.

### Which quests reward an item

The reverse lookup, for an item tooltip, a bank or loot list that wants to
say "quest reward" and link to the quest:

```lua
if QuestDB:IsQuestReward(itemId) then                -- the badge: no list allocated
    for _, q in ipairs(QuestDB:GetQuestsRewarding(itemId)) do
        print(q.questId, q.kind, "x", q.count)       -- kind: "reward" | "choice" | "source"
    end
end
```

`GetQuestsRewarding(itemId)` returns every quest that names the item,
ascending by quest id so two clients list the same first quest, one entry per
place the quest names it: `"reward"` for an item always given, `"choice"` for
one of the pick-one rewards, `"source"` for the item the quest is **accepted**
with. It returns an **empty table** for an item no quest touches and `nil`
only before any data has loaded, the same contract as `GetRewards`. The
table is the library's cached index entry, shared between calls: treat it as
read-only, copy it to keep it. The index is built on the first call, one pass
over the rows, and rebuilt if more data loads.

`IsQuestReward(itemId)` is `true` when some quest gives the item, always or as
a choice; an item that only starts a quest answers `false`. Always a boolean.

## Quest structure

Who gives a quest, who takes it back, what it wants, what it needs first and
what it excludes -- in Questie's field names, because that is what a quest
addon already reads:

```lua
local q = QuestDB:GetQuest(questId)
if q then
    print(q.name, "level", q.questLevel, "needs", q.requiredLevel)
    for _, npc in ipairs(q.startedBy.npcs) do print("start at NPC", npc) end
    for _, npc in ipairs(q.finishedBy.npcs) do print("turn in at NPC", npc) end
    for _, o in ipairs(q.objectives.npcs) do print("kill", o.count, "of", o.id) end
    for _, o in ipairs(q.objectives.items) do print("collect", o.count, "of", o.id) end
    for _, id in ipairs(q.preQuestSingle) do print("after quest", id) end
end
for _, questId in ipairs(QuestDB:GetQuestsStartedByNPC(npcId)) do ... end
```

`GetQuest(questId)` returns `nil` for an unknown quest, otherwise a fresh
table:

| Field | Meaning |
| --- | --- |
| `name` | the title, when the quest text has loaded; `nil` otherwise |
| `requiredLevel`, `questLevel` | the level to take it (0 = none; **`nil` = not known**, MINOR 20, which only WoW Forever's own harvested quests answer -- never treat it as 0, or a level filter shows the quest at level 1) and its level (`-1` = scales with the player) |
| `zoneOrSort` | `> 0` an area id, `< 0` a QuestSort category, `nil` for none |
| `requiredRaces`, `requiredClasses` | the game's bitmasks; 0 = any |
| `questFlags`, `specialFlags`, `suggestedPlayers` | raw flags (`specialFlags` 1 repeatable, 2 needs an event, 4 monthly); suggested group size or `nil` |
| `startedBy` | `{ npcs = {ids}, objects = {ids}, items = {ids} }`, always tables |
| `finishedBy` | `{ npcs = {ids}, objects = {ids} }` |
| `objectives` | `{ npcs = {{id=,count=,alsoCounts=}}, objects = {{id=,count=}}, items = {{id=,count=}}, spells = {ids}, explore = {areaTriggerIds}, rep = {faction=,value=} or nil }`; the quest's own source item is not an objective. `alsoCounts` (MINOR 10) is the other NPCs whose kills credit that objective -- the source's `KillCredit` columns, set on no Vanilla row and 80 TBC rows -- absent when none; `explore` ids are placed by `GetAreaTrigger` |
| `hidden` | MINOR 10: `"unobtainable"` (no creature, object or item starts it), `"retired"` (MINOR 20: a giver still starts it but the game has retired it), `"seasonal"` (bound to a game event, or every giver is an event spawn) or `nil` -- see [Hidden quests](#hidden-quests) |
| `preQuestSingle` | quests that must be **complete** (from the source's one prerequisite column) |
| `preQuestActive` | quests that must be **in the log** (the source's negative `PrevQuestId`, per the cmangos wiki; 45 Vanilla quests). **No parity number exists for it**: Questie folds it into a signed `preQuestGroup` entry, so the tool checks only that the id is among Questie's prerequisites, not the "in the log" meaning |
| `preQuestGroup` | quests that must **all** be complete |
| `exclusiveTo` | taking one of these closes this quest, and vice versa |
| `nextQuestInChain` | the next quest, or `nil`. **Partly derived:** where the source's own column is 0, it falls back to the single quest whose prerequisite names this one, so it can point at a quest the raw column does not |
| `breadcrumbForQuestId`, `breadcrumbs` | the quest this optional lead-in points at; the lead-ins that point here (the shared index list, read-only) |
| `requiredSkill`, `requiredMinRep`, `requiredMaxRep` | `{skill=,value=}` / `{faction=,value=}` or `nil` |

`HasQuest(questId)`, `GetQuestIds()` (ascending), and the reverse links
`GetQuestsStartedByNPC(id)`, `GetQuestsEndedByNPC(id)`,
`GetQuestsStartedByObject(id)`, `GetQuestsEndedByObject(id)`,
`GetQuestsStartedByItem(id)`: ascending quest ids, the shared index list
(read-only), empty for a stranger, `nil` only before any structure data has
loaded. Text (the objectives summary, the per-objective texts) is
`GetQuestText`'s.

### Involved in, and every id (MINOR 10)

```lua
for _, questId in ipairs(QuestDB:GetQuestsInvolvingNPC(npcId)) do ... end     -- start, end OR objective
for _, questId in ipairs(QuestDB:GetQuestsInvolvingObject(objectId)) do ... end
for _, questId in ipairs(QuestDB:GetQuestsInvolvingItem(itemId)) do ... end   -- objective, starter or source item
local npcIds, objectIds, itemIds = QuestDB:GetNPCIds(), QuestDB:GetObjectIds(), QuestDB:GetQuestItemIds()
```

What a search index or a "who is this?" tooltip needs. The three `Involving`
lookups keep the reverse links' contract (ascending, shared, read-only, empty
for a stranger, `nil` before any structure data) and list a quest once
however many places name the id. They cover more than Questie's own search,
which reads only `questStarts` / `questEnds`: on Era 598 NPCs are findable
here that Questie's index cannot reach, because they are only ever an
objective. The three enumerations are fresh ascending tables -- **every**
header id for NPCs and objects (so a consumer can build its own townsfolk
lists from `npcFlags` and `subName`), and every item some quest wants, starts
with or hands over (2,736 Era, 3,810 TBC). Item names are LibItemDB's.

### Hidden quests

```lua
local hidden = QuestDB:GetHiddenQuests()   -- { [questId] = "unobtainable" | "retired" | "seasonal", ... }, cached
local why = QuestDB:IsQuestHidden(questId) -- the reason, or nil for an ordinary quest
```

The quests the data says a player cannot take today, so a browse list does
not show dead ends. Three reasons, one per quest, in this order of precedence:

- **`"unobtainable"`** -- no creature, object or item starts it (85 Era, 447
  TBC): Blizzard test entries, duplicates of a re-numbered quest, content the
  server never wired up.
- **`"retired"`** (MINOR 20, capability `retired-quests`) -- something still
  starts it, but the game has retired it. Either a text field carries
  Blizzard's `[PH]` placeholder marker, or every item it rewards is named
  "DEPRECATED ITEM" by **that game version's own client**. Era flags 7, the
  mount-exchange quests 7671-7678, whose turn-in text is `[PH]`. Forever flags
  those 7 plus 8788, the duplicate "A Gently Shaken Gift", because Forever's
  client renames its reward 21271; Era's client still calls it "Gently Shaken
  Gift", so Era does not flag 8788. TBC flags none: its three `[PH]` quests
  have no giver and are already `"unobtainable"`. All ten `[PH]` quests are on
  Questie's blacklist. A library older than MINOR 20 never answers
  `"retired"`, so check the capability before treating its absence as "not
  retired".
- **`"seasonal"`** -- the quest is bound to a game event, or no item starts it
  and every one of its givers is an event spawn (Hallow's End, Children's
  Week, the Ahn'Qiraj war effort; 327 Era, 656 TBC, 326 Forever, where 8788
  is retired instead).

This is **not** Questie's hidden-quest list. That list is hand-curated and
Questie's repository declares no licence, so it is not copied; the two are
measured against each other by `tools/verify-parity.lua`. On Era, Questie's
blacklist names 2,392 ids, 336 of which have a quest row at all; these
signals hide **266 of those 336 (79%)** and show 70 -- removed content the
dump still wires up, such as _The New Horde_, or a duplicate with a live
giver -- while hiding 146 quests Questie shows, nearly all event-bound
content Questie handles under its own rules (the AQ war effort, the Scourge
Invasion). TBC: 928 of 1,021 (91%), 175 the other way -- against Questie's
literal list only; on a TBC client Questie also applies a per-phase
blacklist that the verifier does not evaluate. A real quest Questie merely
keeps off its map (its `HIDE_ON_MAP`, 38 with an Era row) is not hidden
here, by design. Every parity number in this README is a summary; the
`CHANGELOG.md` entry for the feature is the canonical copy. **Most parity
numbers in this README were measured against Questie before version 12**, which
moved Questie's data into the separate QuestieDB addon. The Questie 12
re-measurement (2026-09-29) is in `CHANGELOG.md` under v0.1.0. Most figures
moved by under a point; the NPC spawn ones fell by about five.

### NPCs and objects

```lua
local n = QuestDB:GetNPC(npcId)      -- { name, subName, minLevel, maxLevel, rank, npcFlags, factionId,
                                     --   friendlyToFaction, zoneID, killCredit = {ids},
                                     --   trainerType, trainerClass,
                                     --   questStarts = {ids}, questEnds = {ids} } or nil
local o = QuestDB:GetObject(objectId) -- { name, type, factionId, friendlyToFaction, zoneID,
                                     --   questStarts = {ids}, questEnds = {ids} } or nil
local also = QuestDB:GetKillCredits(npcId) -- the NPCs whose kills count as this one (MINOR 10)
```

Every creature and object template has a header (`rank`: 0 normal, 1 elite,
2 rare elite, 3 boss, 4 rare; `npcFlags` the game's bitmask; `factionId` the
FactionTemplate id, raw; `friendlyToFaction` `"A"`, `"H"`, `"AH"` or `nil`
for hostile to both -- which player faction NEITHER SIDE is hostile to, from
the client's `FactionTemplate` table with the emulator's own test run both ways,
since a kobold's Monster template carries no enemy mask and it is the player's
that is hostile to Monsters; `zoneID` the area it is most often placed in,
`nil` when it is placed nowhere; `killCredit` the templates a kill of this
one also counts as, the source's `KillCredit1/2`). An **object** carries the
same `factionId` and `friendlyToFaction` from the same client table and rule
(MINOR 11): 689 Era objects have a faction, 76 of them mailboxes, which is
what lets a list show a player only the mailboxes their side can use; the
rest have none and serve everyone. Names and subtitles are
per-locale text (`Data/<Version>/<locale>/NPCText.lua`, `ObjectText.lua`,
English today) and are `nil` until that file has loaded; the quest links are
the shared index lists. `HasNPC(id)` and `HasObject(id)` are the existence
checks; `GetNPCIds()` and `GetObjectIds()` list every header.

**Kill credits** are `killCredit` inverted: `GetKillCredits(npcId)` is every
NPC whose kill counts as `npcId`, and `GetQuest` puts the same list on each
NPC objective as `alsoCounts` ("Defias Looter or Defias Trapper"), so a pane
can say "also counts" and a HUD can aim at the nearest of any of them. The
Vanilla dump sets the column on **no** row, so on Era every list is empty and
Questie's one hand-curated group (Pyrewood Ambush) stays Questie's; the TBC
dump sets it on 80 templates folding onto 17 bases, which reproduces 19 of
Questie's 26 TBC groups (`tools/verify-parity.lua`).

**Trainers** (MINOR 11) are a column, not a title. `trainerType` is a
`QuestDB.TRAINER_TYPE` value -- `CLASS` **0**, `MOUNT` 1, `PROFESSION` 2,
`PET` 3 -- so test it with `~= nil`, never for truthiness, because a class
trainer is zero. `trainerClass` is the class a class trainer teaches, as the
game's class id (what `UnitClass`'s third return gives), so nothing has to
match a localised word. Both are `nil` unless the row carries trainer data:
every TRAINER-flagged row does, and so do **45 Era rows that lack the flag**
(113 on TBC), two of them class trainers Questie's own list names -- which is
why the generator does not gate on the flag; `npcFlags` is on the same row if
you want only flagged ones. Era carries 584 trainer rows in all: 260 class, 8
mount, 284 profession, 32 pet.

**`PET` does not mean "hunter".** Of those 32 Era rows, 15 are `<Pet
Trainer>`, **11 are the warlock `<Demon Trainer>`s this dump mis-types**, and
the rest are the tamer quests' beast trainers. **`trainerClass` does not
separate them**: the demon trainers and the two `<Wintersaber Trainers>`
(10618, 11696) are class 3 too, and four `PET` rows carry no class at all. So
"a hunter's trainers are `CLASS` class 3 plus every `PET` row" swallows all
eleven demon trainers, and narrowing it to "plus class 3" still takes the
Wintersabers -- match the demon trainers by `subName` first. (Questbook hit
both and its own specs caught them, 2026-09-22.)

**How close to Questie's hand-maintained lists** (`ClassTrainers.lua`,
`ProfessionTrainers.lua`, whose header names the query it came from):
`(type 0, class X)` plus `type 3` for hunters contains **218 of its 231** Era
class ids, and `type 2` contains **258 of its 259** professions. Every id it
has that the columns place elsewhere is a warlock **Demon Trainer**, which
this dump types as a pet trainer (11), a profession (1) or a class trainer
with no class (1) -- all present, just not under warlock; take `type 0,
class 9` plus the "Demon Trainer" subName for Questie's exact list. Going the
other way we carry 64 class and 26 profession ids it does not, 21 and 25 of
them actually placed in the world (the six mage `<Portal Trainer>`s, Fahrad
`<Grand Master Rogue>`, cooks and fishing trainers its word lists miss); the
rest are the dump's never-placed `World <Class> Trainer` and `[UNUSED]`
templates, so filtering on `GetNPCSpawns` removes them.

### Spawns

```lua
local s = QuestDB:GetNPCSpawns(npcId)       -- { [areaId] = { {x, y}, {x, y}, ... }, ... }
local s = QuestDB:GetObjectSpawns(objectId) -- the same shape
```

Where each one stands, in Questie's shape: keyed by the AreaTable id of the
zone (the same ids `zoneOrSort > 0` uses), `x` and `y` percentages (0..100,
two decimals) on that zone's map -- what `C_Map.GetWorldPosFromMapPos` takes
once you have the zone's uiMapID -- and `{-1, -1}` for a placement inside an
instance, keyed by the instance's own area id (no map coordinate exists; track
it at the entrance). An empty table for a template nothing **ships** a point
for; `nil` only before any spawn data has loaded. The table is decoded once and
shared, so treat it as read-only.

The source stores every spawn as a map id plus server world yards.
`tools/build-spawns.py` turns those into zone-map percentages with the
client's own zone rectangles (wago's `UiMapAssignment` for the pinned build),
which lands Kobold Vermin's first row on Questie's exact `(48.89, 36.44)` in
Elwynn. Where two zone maps overlap at a border, the point goes to the zone
whose exploration overlay (`WorldMapOverlay`) names it, else to the zone of
the entity's quests or of its other spawns, else to the map it is deepest
inside; the generator's docstring has the measured effect of each step. So an
`areaId` at a border is **derived, not stored**, and nothing in the row marks
which ones were decided that way.

Two more things a point can be. One lying just off every rectangle -- a
shoreline mob a hair past the edge, 16 Era points, none more than 2% out -- is
**clamped** onto the nearest map, so its coordinate is a projection rather than
the spawn's own position; one further out (GM Island, the open sea) is
**dropped**, which is why the empty table above means "nothing shipped" and not
"the source places it nowhere". And a spawn **pool** -- several templates
sharing one placement, the server picking between them -- gives its point to
every template in it, so two NPCs can each list a spot where only one of them
stands at a time.

### Drop rates

```lua
local d = QuestDB:GetItemDrops(itemId)    -- { npcs = { {id=, percent=, questOnly=}, ... },
                                          --   objects = { ... }, containers = { ... } }
local percent, questOnly = QuestDB:GetDropRate(itemId, npcId)          -- nil when no path is listed
local percent, questOnly = QuestDB:GetObjectDropRate(itemId, objectId)  -- chests, fishing holes
local percent, questOnly = QuestDB:GetContainerDropRate(itemId, containerItemId)
```

Who drops a quest item and how often -- the "32.5% drop" a quest pane shows.
`percent` is 0..100 with two decimals; `questOnly` is true when the drop only
happens for a player on the quest (most quest items). Lists are highest chance
first. Only quest items ship -- every item a quest wants, starts with or is
started by, and every item some loot row drops only for a quest -- from every
loot table that can hand them out: the creature's, the chest's or fishing
hole's, and the container item's. Empty lists for an item nothing drops; `nil`
only before any drop data has loaded; decoded once and shared, so read-only.

The percentages are derived the way the emulator rolls its loot tables --
independent rolls for plain entries, one item per group with equal-chance
entries sharing what the explicit chances leave, references followed as many
times as the row says -- and `tools/verify-parity.lua` checks them against
Questie's own resolution of the same tables: **100% of Questie's 3,827
Vanilla and 4,530 TBC pairs agree to two decimals**, and we carry six times as
many pairs, because Questie keeps only the quest-chance rows. Against
Wowhead's observed rates (a sample, not the roll) the median gap is 2 points.

Three things the number is not. It is the **published rate**: every server-side
`RATE_DROP_*` multiplier is taken as 1, so a realm that tunes drops will not
match. A group whose explicit chances sum past 100 is **not renormalised**,
following the emulator rather than the arithmetic, so its later entries are
really worth less than shown -- rare, and the source's own validator warns
about those rows. And a source whose combined chance rounds below **0.01%** is
not listed at all, so an absent source is not proof the item cannot come from
it.

### Zones and dungeons

```lua
local a = QuestDB:GetArea(areaId)          -- { parentAreaId, uiMapId, mapId } or nil
local zone = QuestDB:GetZoneAreaId(areaId) -- Goldshire (87) -> Elwynn Forest (12)
local uiMapId = QuestDB:GetUiMapId(areaId) -- the map a spawn's 0..100 is on; nil when the client draws none
local d = QuestDB:GetDungeon(areaId)       -- { mapId, parentZone, entrances = { {zoneId=, x=, y=}, ... } } or nil
local ids = QuestDB:GetDungeons()          -- ascending dungeon / raid area ids
local name = QuestDB:GetQuestSortName(-22) -- "Seasonal": the negative zoneOrSort categories, English
local at = QuestDB:GetAreaTrigger(triggerId) -- { [areaId] = { {x, y} } }: where an "explore" objective is (MINOR 10)
```

Every area of the client build (`AreaTable`, 1,212 on Era) with its parent
and, for a zone, the UiMap that is its map (`UiMapAssignment`) -- so a spawn
in Goldshire is placed on Elwynn's map through `C_Map.GetWorldPosFromMapPos`.
Zone **names** are not shipped: `C_Map.GetAreaInfo(areaId)` answers in the
client's language. The Era client draws no dungeon maps at all, so a dungeon
area has no `uiMapId` there; TBC's client does, and the first floor is
shipped. Each dungeon and raid the source knows (26 Era, 51 TBC) carries the
outdoor points where the instance is entered -- the world position of every
teleport trigger leading into it, converted like a spawn -- and the zone the
first listed one stands in; a raid entered from inside another instance (Molten
Core from Blackrock Depths) lists that one's. Battlegrounds are zones with maps
of their own and are not in the dungeon table.

Two caveats on that table. `GetDungeons()` lists only instance maps the source
actually **uses** -- something spawns on it, or a teleport leads into it -- so
an instance the server never opens (Season of Discovery's, on the Era build) is
absent rather than present and empty. And `entrances` is not one point per
doorway: a dungeon has a trigger per doorway and some doorways have two, so
points within 1% of each other on the same zone are collapsed. The list is then
in the source's own row order, which makes `parentZone` -- the first entry's
zone -- a pick rather than a judgement: for a dungeon entered from two zones it
names whichever the source happens to list first. The quest-sort names come from
the client's `QuestSort` table as per-locale text (`enUS/SortText.lua`),
since the client has no API for them.

**Explore triggers.** A "be at this place" objective (`objectives.explore`,
45 quests on Era, 61 on TBC) names an areatrigger; `GetAreaTrigger(id)`
places it in the spawn shape -- one point on the zone's map, `{-1, -1}`
inside an instance -- from the client's `AreaTrigger` row through the same
conversion as a spawn, so a HUD guides to it exactly as to a spawn. The
objective's line ("Scout through the Fargodeep Mine") is the quest's
`GetQuestText().endText`. Against Questie's `triggerEnd`: 41 of 41 Era
points within 1% of the map (TBC 56 of 57), the text 33 of 35 (50 of 52).

**How close to Questie:** `areaId -> uiMapId` agrees on 49 of 49 Era zones
(TBC 103 of 106: three multi-floor dungeons where Questie picks a different
floor), sub-area -> zone on 99.7%. Dungeon entrances differ by design:
Questie hand-places the cave mouth (Deadmines at Westfall 42.5, 71.7), the
trigger stands where the instance begins (38.0, 77.5) -- 14 of 25 Era
dungeons are within 5 points, the rest 5 to 13 points deeper along the
tunnel: Gnomeregan, the Deadmines, Maraudon, the Stockade and the Ruins of
Ahn'Qiraj by 5 to 8 points, Dire Maul by 10, and the Temple of Ahn'Qiraj and
the four Blackrock Mountain instances (Depths, Spire, Molten Core, Blackwing
Lair) by 13 -- Questie marks the mountain's outer mouth in Burning Steppes or
Searing Gorge, the triggers stand at the instance portals inside it. Every
dungeon is keyed by a real `AreaTable` id (the generator picks the instance's
own top-level row), so `C_Map.GetAreaInfo` names all of them.

**How close to Questie:** `tools/verify-parity.lua` compares every field
above against Questie's curated rows. Measured 2026-09-21 on Vanilla: names
99.8%, givers and finishers 98.0 to 99.9%, objectives 99.7 to 100%, classes
100%, races 98.4%, zone 99.9%, flags 99.6%, `preQuestGroup` 99.2%,
`nextQuestInChain` 95.1%, `exclusiveTo` 94.8%, prerequisites 91.8% exact
(96.8% contained); NPC name, subName, rank and questEnds 100%, questStarts
99.8%, npcFlags 99.1%, level ranges 94.6%, `friendlyToFaction` 96.9% (TBC
97.6%); object names 98.8%, quest links 99.6 to 99.8%. Spawns: the set of zones an NPC is placed in agrees 90.1%
(objects 90.0%), `zoneID` 91.7% (90.3%), and 93.6% of Questie's NPC points
have one of ours within 1% of the map (objects 79.0% -- herb and ore nodes
are pooled differently in the two captures). TBC: NPC zones 91.2%, points
93.9%; objects 88.8% and 59.2%. The structural gaps are Questie's
hand-curation, which the tool lists id by id; the spawn gap is the terrain's
own area id, which no client table carries.

## Experience

```lua
local level = UnitLevel("player")
local xp = QuestDB:GetQuestXP(questId, level)        -- nil at the cap, or when the quest gives none
if xp then
    print("XP:", xp)
elseif level >= (QuestDB:GetLevelCap() or 60) then
    local r = QuestDB:GetRewards(questId)
    if r and r.moneyMaxLevel then
        print("at the cap:", (r.money or 0) + r.moneyMaxLevel, "copper, XP included as money")
    end
end
```

`GetQuestXP(questId, playerLevel)` returns what a player of that level receives;
with no level, the full value. It returns `nil` when the quest gives no XP, is
unknown, or the player is **at or above the level cap**, because the server pays
`moneyMaxLevel` instead. `GetLevelCap()` is 60 on Vanilla data and 70 on TBC
data. That is the data's cap; the live client can cap a character lower during
a pre-patch, so prefer `GetMaxPlayerLevel()` for what a player is subject to
right now.

### How XP is derived

The game pays quest XP from **Blizzard's own tier table**: the client ships
`QuestXP`, one row per quest level with nine difficulty tiers (rounded to
fives), and the server pays the tier that a per-quest difficulty id selects.
The world database carries neither an XP column nor that id; the emulator
derives XP from the max-level money and the quest level (`Quest::XPValue` in
`src/game/Quests/QuestDef.cpp`, identical in `mangos-classic` and
`mangos-tbc`):

```text
formula = RewMoneyMaxLevel / d     d = 0.6 for quest level 1-60, 1.2 (61),
                                     2.4 (62), 3.6 (63), 4.8 (64), 6.0 (65+)
fullXP  = the tier of the quest's level nearest to formula, ties to the higher
paid    = round(fullXP * m)        m = 1.0 while playerLevel <= questLevel + 5,
                                     0.8 / 0.6 / 0.4 / 0.2 at +6 / +7 / +8 / +9,
                                     0.1 beyond; round = to 5s up to 100, 10s to
                                     500, 25s to 1,000, 50s beyond
```

The tier table ships as `Data/<Version>/_core/QuestXP.lua` (from wago's
export of the client's table, `tools/build-questxp.py`); without it the
library answers the bare formula, scaled with a ceil as the emulator does.

**Why the snap:** measured against Questie's per-quest XP table, which is the
same client table indexed by the difficulty id from a server extract, the
emulator's value is a tier for 72% of Vanilla quests and lies beside one for
the rest, and the nearest tier reproduces Questie's stored value for **3,485
of 3,485 Vanilla and 4,775 of 4,775 TBC quests** (`tools/verify-xp-parity.lua`
runs the shipped library against Questie's file and exits non-zero on any
disagreement). The rounding of the paid value is Questie's (`QuestieXP.lua`,
the one implementation read for it), and it matches what Questie displays on
100% of shared quests, so a Questie user and a LibQuestDB consumer see the
same number for every quest.

**Measured on the live Classic Era client** (six level-60 quest-log windows,
2026-09-20): the money paid at the cap is **six copper per XP point**, added
to the quest's ordinary money, six quests out of six: The Royal Rescue (8,050
XP) shows 4g 83s; Operation: Death to Angerforge (7,750 XP plus 2g 65s) shows
7g 30s; To Serve Kum'isha (8,450) 5g 7s; Uniting the Shattered Amulet and
Unfinished Gordok Business (8,300 each) 4g 98s. What has not been read off
the live client is an XP line below the cap; Questie's table is the reference
for those.

## Quest text

```lua
local t = QuestDB:GetQuestText(questId)
if t then
    print(t.title)
    print(expandMarkup(t.details))        -- your function; see Markup below
end
if QuestDB:GetTextLocale() ~= GetLocale() then
    print("Quest text is shown in English; no translation is available yet.")
end
```

`GetQuestText(questId)` returns `nil` for an unknown quest, otherwise a fresh
table. Every string is `nil` when empty:

| Field | Meaning |
| --- | --- |
| `title` | the quest's name |
| `details` | the quest-giver's speech (the "description") |
| `objectives` | the summary shown under the title in the log |
| `offerReward` | what the finisher says when you can turn in |
| `requestItems` | what the finisher says when you cannot yet |
| `endText` | rarely set |
| `objectiveTexts` | `{ "...", ... }` the override texts this quest has; empty table when none |

**`objectiveTexts` is not indexed by objective.** The dump carries one slot per
objective and the empty slots are dropped, so entry 1 is the first slot that
_has_ text rather than objective 1. Measured on the shipped files: 93 Vanilla
and 347 TBC quests carry any override text, and 7 and 43 of those have a gap --
quest 532's only text sits on slot 3 and arrives as `objectiveTexts[1]`. Do not
zip the list against `GetQuest().objectives`; that table regroups the slots into
`creatures` / `objects` / `items`, so the slot number does not survive there
either. Render them as the quest's own objective lines, unattached.

`QuestDB:HasText(questId)` is the existence check. `QuestDB:GetTextLocale()`
is the locale the loaded text is mostly in: the translation's once one has
loaded, else `"enUS"`. On Vanilla that is always `"enUS"`, since it ships no
translations; on TBC a client running one of the eight shipped languages gets
that locale, and the reading is **mostly** rather than **only** for a reason --
those files carry titles, so every description under them is still English.

### Markup

Text is stored as the server stores it, so your renderer expands WoW's markup
for the character it is drawing for:

| Code | Meaning |
| --- | --- |
| `$N` / `$n` | player name |
| `$C` / `$c` | class (upper-case form capitalised) |
| `$R` / `$r` | race |
| `$B` / `$b` | line break (more common than a real newline in this data) |
| `$G male:female;` / `$g` | gender branch; spacing varies (`$gLord:Lady;`, `$g lad : lass;`) and a branch may contain `$N` |
| `$<id>w` | a world-state counter only the live server can fill (three Vanilla quests, the Ahn'Qiraj war effort); render a quantity word, never the raw code |

Real newlines in the data are real newlines.

### The locale framework

Text ships as **one file per language**, `Data/<Version>/<locale>/Text.lua`.
Each file asks the library whether it is wanted before loading: yes for the
client's own locale, and **always** yes for `enUS`. An `enGB` client is treated
as `enUS`. `Data/<Version>/_core/Locales.lua` declares which locales ship; it
is a manifest, not a gate, and stays first in the TOC so
`GetShippedLocales()` is answerable before any text arrives.

**A translation is a patch, not a replacement** (`MINOR 16`). English always
loads and a locale file is laid over it **field by field**: a row that carries
a title and no description shows the English description rather than an empty
pane. Before this, one file per locale was all-or-nothing, which meant a
language had to be near-complete before it could ship at all.

**TBC ships all eight of its languages, titles only** -- 1.60 MB for the set,
against roughly 25 MB for their full text. A player on one of those clients
reads quest **names** in their own language and descriptions in English, which
is precisely what the field-by-field overlay makes possible: before `MINOR 16`
a partial locale blanked the description pane, so none of these was shippable.
Only the client's own language loads; the other seven return at their first
line. Vanilla ships English only, because its source has no translations at all.

| Locale | Quest titles | Shipped size |
| --- | --- | --- |
| `ruRU` | 6,515 of 6,599 | 320 KB |
| `frFR` | 6,515 | 233 KB |
| `esES` | 6,515 | 226 KB |
| `esMX` | 6,481 | 225 KB |
| `deDE` | 6,515 | 221 KB |
| `koKR` | 5,051 | 170 KB |
| `zhCN` | 6,036 | 170 KB |
| `zhTW` | 1,337 | 38 KB |

Full text for a language is one regeneration without `--fields titles` and no
other change -- the TOC line is already there. For scale, `deDE` in full is
3.85 MB and `koKR` 2.34 MB.

The overlay's cost was measured rather than reasoned about, because the suite
never merges six thousand rows and so says nothing about it: loading `deDE` over
the English base takes **0.129s**, against 0.052s for the base file on its own.
Every row is split twice and re-joined, which is why the overlay costs more than
the larger file it lays over. (Measured in the offline harness on desktop Lua
5.1, not in the client.)

Vanilla has no translations at all -- every `locales_*` table in the source is
empty. TBC's source carries 6,517 localized quests in the eight languages
above, and the generator builds any of them, in full or titles-only:

```sh
python tools/build-text.py TBC --locale deDE
python tools/build-text.py TBC --locale zhTW --fields titles
```

A row with no text at all in that language is not written -- the base already
answers it. A field that merely happens to match the English one **is** shipped:
dropping it would make the locale file valid only against an `enUS` file built
from the same dump, and across all eight locales that saves at most 1,798 bytes.
Adding a language is then one TOC line; the library does not change.

`Tests/data_spec.lua` asserts that `Locales.lua` lists **exactly** the locales
its flavour's TOC loads, in both directions -- a manifest entry with no TOC line
promises text that never arrives, and a TOC line the manifest omits still loads
(the manifest is not a gate) while `GetShippedLocales()` under-reports it.

## Path graph

```lua
local g = QuestDB:GetPathGraph(continent)      -- 0 Eastern Kingdoms, 1 Kalimdor, 530 Outland (TBC)
if g then
    for id, n in pairs(g.nodes) do             -- n.x, n.y, n.z (server yards), n.name, n.continent
        if n.continent ~= g.continent then print(n.name, "is the far end of a boat or zeppelin") end
    end
    local myside = UnitFactionGroup("player") == "Horde" and "H" or "A"
    for _, l in ipairs(g.links) do             -- DIRECTED
        if l.side and l.side ~= myside then
            -- the other faction's boat, zeppelin or flight master: skip it
        elseif l.type == QuestDB.PATH_TYPE.WALK then
            local pts = g.path(l.from, l.to)   -- { {x=,y=,z=}, ... }, thinned, ordered from -> to
                                               -- (begins at `from`; a few ship routes stop short
                                               --  of `to` -- see below)
        elseif l.type == QuestDB.PATH_TYPE.FLIGHT then
            local route = g.path(l.from, l.to) -- the gryphon's route, same shape
            -- l.object is the TaxiPath id; l.distance is 0: weight it yourself
        elseif l.type == QuestDB.PATH_TYPE.TRANSPORT then
            local route = g.path(l.from, l.to) -- the ship's route on THIS continent (see below)
            -- l.object is the transport's GameObject entry (the boat, the zeppelin)
            -- l.transport says WHICH KIND, and the three are not interchangeable:
            --   VESSEL a boat or zeppelin, on a timer you wait for
            --   LIFT   an elevator you step onto -- no timetable, seconds not minutes
            --   STEP   the two-yard step on and off; no travel at all
        end
    end
end
```

`GetPathGraph(continent)` returns `nil` when no graph is loaded for that
continent, otherwise one table, decoded on first call and **cached**, so treat
it as read-only:

| Field | Meaning |
| --- | --- |
| `continent` | the server map id you asked for |
| `nodes` | `{ [id] = { x=, y=, z=, name=, continent= } }`. Server world yards, x north / y west. A node whose `continent` differs from the graph's is the far end of a cross-continent link -- **and its coordinates are in that continent's own frame, never translated into this graph's.** `continent` names the frame each node is in. Comparing a far node against a near-continent position compares two coordinate systems, which is how a correctly-oriented far half gets reversed |
| `links` | `{ { from=, to=, type=, object=, distance=, swim=, side=, transport= }, ... }`, **directed**. `type` is a `PATH_TYPE` value; `object` is raw: the transport's GameObject entry, the TaxiPath id, the portal entry, or 0 for a walk. `swim` is the yards of the walk spent swimming. `side` is `"A"`, `"H"` or `nil` (either faction), set on flights and transports only. `transport` is a `TRANSPORT_KIND` value on a `TRANSPORT` link and `nil` on every other type |
| `path(from, to)` | the route of a **walk** (the bots' walk, thinned at 8 yards, or 2 yards when either end is inside a capital city), a **flight** (the gryphon's route) or a **transport** (the ship's route, both thinned at 30 yards), `{ {x=,y=,z=}, ... }` with endpoints included, decoded lazily; `nil` for a portal, a dock step with no route, or a pair that is not a link. **A route that changes continent is split:** this graph's copy holds only the points on this continent, from its node to the map edge or from the edge to its node; the other continent's graph holds the rest |

`QuestDB:GetPathContinents()` lists the loaded continents. `QuestDB.PATH_TYPE`
names the link types: `WALK` 1, `AREA_TRIGGER` 2 (continent portals such as
the Dark Portal; instance doors are not shipped), `TRANSPORT` 3, `FLIGHT` 4,
`TELEPORT_SPELL` 5 (no rows), `STATIC_PORTAL` 6 (TBC's Shattrath portals).

**`TRANSPORT` is three different things, and pricing them alike routes a player
badly.** `QuestDB.TRANSPORT_KIND` names them, and `l.transport` says which:
`VESSEL` a boat or zeppelin on a timer you wait for, `LIFT` an elevator or
scaffold car you step onto, `STEP` the two-yard step between a vehicle node and
its entry node with no travel at all. Vanilla ships 16 vessels, 43 lifts and 95
steps; TBC 18 / 57 / 115 -- so **the majority of `TRANSPORT` links are steps**,
and a single boarding wait charged to all of them is charged several times over
on one boarding. That is not hypothetical: charging a zeppelin's 90-second wait
to the four Undercity lift links made the 936-yard walk-in score worse than a
3,213-yard loop through the hills, so the route drawn for a player looking for
the Undercity entrance went round the long way and never showed it. The kind
comes from `gameobject_template.type` in the dump -- 15 is a map-object
transport, 11 a local mover -- not from the node's name.

**A vessel's speed is 30 yards per second, and it accelerates at 1 yd/s/s.**
Nothing needs timing with a stopwatch. `gameobject_template.data1` is
`moTransport.moveSpeed` and `data2` is `accelRate`, per the type-15 struct in
CMaNGOS `src/game/Entities/GameObject.h`, and `Transports.cpp`'s
`CalculateSegmentPos` consumes them as plain kinematics against inter-node
distances in world yards, so the units are yards and seconds. **Every rideable
vessel in both dumps carries the same 30 / 1** -- 8 of 9 Vanilla rows and 9 of 10
TBC, the exception being Naxxramas, which is not a route anyone rides -- so one
constant is right and per-vessel pricing would be inventing a difference that is
not there.

The acceleration is the part that bites, and it is not a small correction: at
1 yd/s/s a vessel needs **30 seconds and 450 yards** to reach cruising speed, so a
dock-to-dock leg shorter than 900 yards never reaches 30 at all. Pricing a leg of
`D` yards as `D / 30` is therefore wrong for every short hop. From the emulator's
own arithmetic the leg takes `2 * sqrt(D)` seconds below 900 yards and
`60 + (D - 900) / 30` above it -- a 2,000-yard leg is 97 seconds, an effective
21 yd/s rather than 30. (That formula is derived from the code cited above, not
measured against a running server.)

**The dock wait is the bigger term, and unlike the speed it differs per vessel.**
`data0` is the vessel's `TaxiPathId`; its `TaxiPathNode` rows carry the waypoints
and, at each stop, a `Delay` in seconds. The emulator builds the full cycle from
exactly those (`TransportMgr::GenerateWaypoints` sets
`pathTime = keyFrames.back().DepartureTime` -- every leg's travel plus every
stop's delay). A vessel sits at a given dock for its `Delay` out of each cycle,
so a player arriving at a random moment waits
`(period - delay)^2 / (2 * period)` on average:

| Entry | Vessel (Classic Era) | Cycle | Mean wait |
| --- | --- | --- | --- |
| 176244 | Moonspray (Rut'theran - Auberdine) | 360s | **125s** |
| 177233 | Feathermoon Ferry | 373s | 131s or 158s |
| 176231 | Proudmore's Treasure | 584s | 235s |
| 176310 | Serenity's Shore | 635s | 260s |
| 164871 | Orgrimmar - Undercity zeppelin | 653s | 269s |
| 176495 | Grom'Gol - Undercity zeppelin | 832s | 358s |
| 175080 | Grom'Gol - Orgrimmar zeppelin | 851s | 368s |
| 20808 | Booty Bay - Ratchet ship | 877s | **381s** |

The entry is `gameobject_template.entry`, which is what a `TRANSPORT` link's
`object` carries -- so a consumer can key a table on it directly. Note 20808 is
named `TEST Ship` in the Vanilla dump and `Booty Bay Ship` in TBC; it is the
Booty Bay - Ratchet run either way.

So the wait is three times the speed's contribution on most routes, and the
spread between the shortest and longest is a factor of three -- a single boarding
constant is wrong for every route it is not tuned to.

**Every dock is a 60-second stop except the Feathermoon Ferry, which is the one
asymmetric vessel**: its Vanilla path has three stops at 30, 60 and 30 seconds,
so the wait depends on which dock you board at -- 158s at a 30-second dock, 131s
at the 60-second one. Every other vessel's two docks are identical, so one number
per entry is right for them. (TBC's Feathermoon is a different path, 777, with
two symmetric 30-second stops.)

Two things to keep with those numbers. The cycle is a **lower bound**: the
distances are straight lines between waypoints and the emulator splines them.
And `Naxxramas` is a type-15 row with a path but is not a route anyone boards --
skip it rather than letting it into an average.

QuestDB does not ship any of this as a field; it is a property of the vessel, and
the path graph already gives you `l.object` to key it on.

`LIFT` has no speed to read: the type-11 struct is `pause` / `startOpen` /
`autoCloseTime` with no movement fields at all, and every type-11 row in both
dumps leaves its data columns empty. A lift's timing is an animation, not a
speed.

**A lift cannot be routed TO by position; it is something you pass through.**
Questbook's observation, measured here before repeating it: a `LIFT` link's two
nodes are at the same x and y **to the yard** on 40 of 43 Vanilla links and 49 of
57 TBC, while differing by as much as 130 yards in z. So a nearest-node query on
x/y answers both ends of a shaft identically and cannot tell the top from the
bottom. What makes Undercity's Undervator routable at all is the flight master
_below_ it -- you route to that, and the lift is on the way.

The exceptions are small but real, so do not code the absolute form: two
`Elevator` pairs sit 1 yard apart, `Undervatorentryentry` -> `Undervatorentry` 1-2
yards, and TBC's Zangarmarsh `Doodad_mushroombase_elevator01` cluster spreads up
to 21 yards horizontally. None of those separations is big enough to route by
with any confidence.

**Sides.** A flight's `side` is the faction allowed at both of its taxi nodes,
from the faction flags in the client's own taxi tables (Orgrimmar is flagged
Horde, Aerie Peak Alliance; a neutral town such as Booty Bay has a node for
each faction, so "either" only arises between two nodes flagged for both, such
as the Shattered Sun Staging Area). A transport's side is dock ownership:
zeppelins and the Undercity, Thunder Bluff and Freewind Post lifts are Horde,
the Menethil, Auberdine, Feathermoon and Azuremyst boats Alliance, the Booty
Bay goblin ship, the Great Lift between the Barrens and Thousand Needles, and
the remaining lifts open to both. Walks never carry a side, so a route that
walks into an enemy capital is not caught by this.

**What the data does not carry, and you must supply:** transport and flight
links have `distance` 0. There is no travel time in the source, so a router that
uses distance alone will treat every flight as free. Weight boats by a boarding
wait plus crossing time, flights by a boarding cost plus distance at flight
speed. Nothing in the data knows which flight paths a character has learned;
the client only reports that at a flight master, so offer a walk-and-boat-only
mode or assume the paths are known.

**Where it comes from.** The playerbot module's travel graph, shipped inside
the CMaNGOS world database: routes the emulator's bots actually walk, so they
avoid cliffs and water by construction, the route every gryphon flies and the
route every ship sails. The source stores the ships' routes backwards relative
to their link, so the generator orients every route by which end lies nearer
which node, **in three dimensions**: a lift's two nodes share x and y to the
yard and differ only in height, so a flat comparison scores both ends the same
against both nodes and leaves the route in whatever order the dump held. That
shipped seven routes per flavour back-to-front until 2026-09-22, every one a
lift or a dock step. Polylines are thinned with Douglas-Peucker, walks at 8
yards and rides at 30; every kept point is an original point. **A sharp vertex
is re-thinned at a quarter tolerance on both sides**, because Douglas-Peucker
keeps the apex of a turn and drops the rounding around it -- which draws a
switchback the bot walked as a curve into a zero-width spike, and a road full of
those reads as a sawtooth. It costs about 5% more points and takes the largest
out-and-back in the shipped walk data from 116 yards to 64 (Vanilla) and 92
(TBC). **The out-and-backs that remain are mostly real** -- the bots' routes do
double back around a ridge -- so do not smooth them downstream: nothing in the
shipped data distinguishes a real switchback from an artefact, and flattening
one cuts the line through whatever the hairpin was going around.

**A polyline starts at its `from` node; it does not always reach its `to`
node.** The first guarantee is the one to build on, and a spec pins it for every
route on every continent. The second is not ours to give: a few of the dump's
transport "routes" are the vehicle's own movement points and do not span their
link at all -- Gnomeregan's Scaffold Cars `1139->1140` runs z 213 to 238 while
node 1140 sits at 193. Two such routes ship on Vanilla and four on TBC, all
`TRANSPORT`, and a further 12 Vanilla / 16 TBC stop more than 20 yards short of
their `to` node. Draw the last leg to the node itself rather than assuming the
line ends there.
Cross-continent links appear in both continents' lists. On Vanilla only boats
and zeppelins cross; on TBC so do the Dark Portal, the Shattrath portals and a
few flights, because the Blood Elf zones sit on the Outland map. A walk link
never crosses. The whole graph is loaded at login as packed
strings and decoded per continent on first use, because WoW cannot load a file
on demand.

### Off the graph: routes into caves and buildings

The graph ends at the road. A quest target inside a cave is reached from it by
a straight line over the rock unless something says otherwise, and the graph has
no node inside any cave. `GetSpawnApproach` is that something:

```lua
local a = QuestDB:GetSpawnApproach("npc", 808, 1, 30.48, 80.15)   -- kind, id, areaId, x, y
-- a = { continent = 0, fromNode = 545, points = { {x=,y=,z=}, ... }, area = 1, x = 30.48, y = 80.15 }
```

Ask with a spawn point exactly as `GetNPCSpawns` / `GetObjectSpawns` return it
(`kind` is `"npc"` or `"object"`, `x` and `y` 0-100). You get back the route from
`fromNode`, a node of `GetPathGraph(continent)`, to that spawn, in server world
yards like a path's points. The point the route was built for is the nearest one
within **one map percent** of what you asked. That tolerance is what lets a
consumer holding **Questie's** spawn table find ours, because its points are in a
different order and a few differ slightly.

**`nil` means nothing better than a straight line is known, never
"unreachable".** A route ships only when it bends: when its off-road part strays
more than **25 yards** from the straight line between where it leaves the road
and the spawn. **Join the route where the player is** rather than walking them
back to `fromNode`: pick up the point nearest to them.

**How the routes are made, and so how far to trust them.** The dump has no
navigation mesh. It does have every creature, object and patrol point, and each
is somewhere a thing actually stands: walkable ground, inside caves too.
`tools/build-approaches.py` chains those points outward from the graph's walk
routes. Each step is at most 22 yards and no steeper than a walkable slope. Where
nothing stands in a gap, usually a tunnel's empty mouth, it **bridges** up to 120
yards in a straight line. A bridge is the weak part: it is usually the tunnel,
and it could be rock. Built for the Frostmane troll cave in Coldridge Valley,
where the route to Grik'nir the Cold (NPC 808) runs from the Dwarf and Gnome
start across the valley and in at the cave mouth. **Not verified in game beyond
that cave.**

The routes cover every spawn point of an NPC or object that gives or ends a quest,
is a quest objective, or drops a quest item. They are shipped for 10,346 of 65,528
such points on Vanilla, 16,107 of 92,000 on TBC and the same count as Vanilla on
Forever, which uses Classic's dump. The files are 1.1 MB (Vanilla, Forever) and
1.9 MB (TBC).

## The rest of the API

| Call | Returns |
| --- | --- |
| `QuestDB:IsReady()` | `true` once reward data has loaded. A flavour without a capture answers `false` and every lookup `nil` |
| `QuestDB:GetRewardCount()` | number of quests with a reward row |
| `QuestDB:GetSource()` | `"Vanilla"` / `"TBC"`, and the source dump's content fingerprint |
| `QuestDB:WantsLocale(locale)` | used by the generated text files; `true` for the client's locale and ALWAYS for `enUS`, which every translation is laid over field by field |
| `QuestDB:GetShippedLocales()` | the locales this flavour ships text for, sorted, `enUS` first |
| `QuestDB:GetTextLocale()` | the locale the loaded text is mostly in -- the translation's once one has loaded, else `"enUS"` |
| `QuestDB:GetDataSource()` | `"questie"` when Questie is installed and answering, else `"questdb"` |
| `QuestDB:ClearDataSource()` | withdraw a registered source and go back to the shipped tables, announcing the change like any other. For a source that finds itself unusable AFTER registering; a no-op when none is registered |
| `QuestDB:RegisterSourceChanged(cb)` | `cb(source)` now and on every change; rebuild anything cached from `GetQuest` |
| `QuestDB:GetShippedQuest(id)` | the shipped row with no registered source over it, or `nil` |
| `QuestDB:GetQuestHeader(id)` | just the seven fields a quest LIST shows -- `name`, `questLevel`, `requiredLevel`, `zoneOrSort`, `requiredRaces`, `requiredClasses`, `hidden` -- read off the packed row, 6-8x cheaper than `GetQuest`. Ignores a registered source (see below). `requiredLevel` is `nil` when not known, as on `GetQuest` |
| `QuestDB:GetCoverage(id)` | `"shipped"` when `GetQuest` answers, `"uncovered"` when this flavour's CLIENT lists the id and nothing offline describes it, `"unknown"` otherwise. Read the limits below before acting on `"unknown"` |
| `QuestDB:HasCapability(name)` | `true` when this copy implements the named capability; always a boolean, `false` for an unknown name or a non-string. Describes the CODE, not whether data has loaded |
| `QuestDB:GetCapabilities()` | every capability name this copy implements, ascending, in a fresh table |
| `QuestDB.CAPABILITY` | the names as constants, so you never type the string |
| `QuestDB.NONE` | the sentinel a resolver sets on a field it means to be `nil` |
| `QuestDB.MAJOR` | the LibStub name, `"LibQuestDB-1.0"` -- the string you would pass to `LibStub()`, exposed so a consumer logging or re-resolving the library does not hard-code it |
| `QuestDB.MINOR` | feature gate: 2 = rewards, 3 = `xp`, `questLevel`, `GetQuestXP`, 4 = `GetQuestXP` is `nil` at the cap, `GetLevelCap`, 5 = quest text and the locale framework, 6 = the path graph, 7 = flight routes on it, 8 = ship routes, split crossings and link sides, 9 = `GetQuestsRewarding`, `IsQuestReward`, `xp` on Blizzard's tiers, `moneyMaxLevel` at the live rate, the quest structure (`GetQuest` and the reverse links), NPC and object headers (`GetNPC`, `GetObject`) and spawns (`GetNPCSpawns`, `GetObjectSpawns`, `zoneID`), drop rates (`GetItemDrops`, `GetDropRate`, `GetObjectDropRate`, `GetContainerDropRate`), zones (`GetArea`, `GetZoneAreaId`, `GetUiMapId`, `GetDungeon`, `GetDungeons`, `GetQuestSortName`), 10 = enumeration (`GetNPCIds`, `GetObjectIds`, `GetQuestItemIds`), involved-in links (`GetQuestsInvolvingNPC`, `GetQuestsInvolvingObject`, `GetQuestsInvolvingItem`), kill credits (`killCredit`, `GetKillCredits`, `alsoCounts`), explore trigger positions (`GetAreaTrigger`) and hidden quests (`hidden`, `GetHiddenQuests`, `IsQuestHidden`); a MINOR 9 `Quests.lua` is refused at load, 11 = `trainerType` / `trainerClass` on `GetNPC` with `QuestDB.TRAINER_TYPE`, and `factionId` / `friendlyToFaction` on `GetObject`, 12 = Questie is preferred when installed (`GetDataSource`, `RegisterSourceChanged`, `RegisterDataSource`, `GetShippedQuest`, `QuestDB.NONE`), for `GetQuest`, `HasQuest`, `GetQuestIds`, `GetNPC` and `HasNPC`, 13 = the source also answers `GetNPCSpawns`, `GetObjectSpawns`, `GetObject`, `HasObject` and the `zoneID` on both headers, 14 = `GetQuestHeader`, 15 = `transport` on a path-graph `TRANSPORT` link with `QuestDB.TRANSPORT_KIND` naming the three kinds (`VESSEL`, `LIFT`, `STEP`), 16 = a translation is a PATCH, not a replacement -- `enUS` always loads and every other locale is overlaid on it field by field, plus `GetShippedLocales`, 17 = named capabilities (`HasCapability`, `GetCapabilities`, `QuestDB.CAPABILITY`), so a consumer asks for what it needs by name instead of knowing which release carried it, 18 = quest coverage (`GetCoverage`), telling an id the client lists but nothing offline describes from an id nothing knows, 19 = spawn approaches (`GetSpawnApproach`), a walking route from the path graph to a quest spawn a straight line would reach over rock, 20 = `"retired"` as a third `hidden` reason (capability `retired-quests`), `GetNPCIds` / `GetObjectIds` list a registered source's ids too (the `npcIds` / `objectIds` resolver readers), and `requiredLevel` is `nil` where the row says it is not known |

The returned shapes are versioned by `MINOR`: a change to any of them bumps
the number and is announced to consumers. Fields are only ever added.

The `Load*` methods, `SetSource` and `SetShippedLocales` are also on the
library table. The generated `Data` files call them to hand their rows over
at login. They are not for consumers; nothing a consumer reads needs them.

### Why a quest is missing: `GetCoverage`

`GetQuest` returning `nil` cannot tell a player whether the id is nonsense or
whether it is a real quest nobody has offline data for -- so from their side a
gap looks exactly like a bug. `GetCoverage(id)` separates the two:

| Answer | Means | What to tell a player |
| --- | --- | --- |
| `"shipped"` | `GetQuest` answers, from the shipped rows or a registered source | show the quest |
| `"uncovered"` | this flavour's **client** lists the id and nothing offline describes it | "this quest exists, but there is no offline data for it" |
| `"unknown"` | neither knows the id | "nothing here knows this quest" -- **not** "no such quest" |

The ids come from the client's `QuestV2` table: **1,275** on Era, **372** on
TBC and **3,065** on Forever, where they include its own ~1,795 new quests that
no world database covers at all.

**Two limits, and a consumer that ignores them will be wrong in both
directions.** `QuestV2` **under-lists** -- 713 of the quests this library ships
are absent from Era's own `QuestV2`, 819 from TBC's and 710 from Forever's --
so a real quest can answer `"unknown"` purely by never having been listed.
That is why `"unknown"` must never be rendered as "no such quest". And the set
is **not a count of missing content**: what `QuestV2` membership means is not
verified, and it starts at id 1 on two flavours, which suggests it carries ids
that were never obtainable. It is sound for answering about an id you already
have -- a quest a player is holding is real whatever the table says -- and
unsound as a figure to show anybody.

**Scope the explanation to a quest the player actually holds.** Questbook's
first cut explained every `"unknown"` id and broke its own public `ShowQuest`
contract with another addon, turning four specs red on the first run (inbox
`4f8ac6cf`). Gating on "is this in the player's log" fixed it -- and a held
quest is also the only case where silence is actively **misleading** rather than
merely unhelpful, because the player can see the quest and your addon cannot.

## Supported versions

| Flavour | TOC | Quests (structure / rewards / text) | NPCs / objects | Spawns (placed NPCs / objects) | Drops (quest items / sources) | Zones (areas / dungeons) | Path graph | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Classic Era (Era / Hardcore) | `QuestDB.toc` (11509) | 4,245 / 4,140 / 4,245 (490 KB structure) | 10,384 / 10,744 (1.1 MB with names) | 7,540 / 7,880 (1.27 MB) | 1,744 / 26,657 (270 KB) | 1,212 / 26 (30 KB) | 1,245 nodes, 4,489 links, 877 KB | `cmangos/classic-db` |
| TBC (Anniversary) | `QuestDB_TBC.toc` (20506) | 6,599 / 6,270 / 6,599 enUS + 8 title locales, 1.60 MB (770 KB structure) | 18,799 / 14,216 (1.8 MB with names) | 12,301 / 11,824 (2.0 MB) | 2,384 / 30,218 (315 KB) | 1,643 / 51 (41 KB) | 1,972 nodes, 7,191 links, 1.32 MB | `cmangos/tbc-db` |
| WoW Forever (`camelot`) | `QuestDB_Camelot.toc` (16001) | 4,245 / 4,140 / 4,245 (490 KB structure), plus 775 of Forever's own from the client (level and text only, 130 KB) | 10,384 / 10,744 (1.1 MB with names) | 7,540 / 7,880 (1.27 MB) | 1,744 / 26,657 (270 KB) | 1,372 / 26 (34 KB) | 1,245 nodes, 4,489 links, 877 KB | `cmangos/classic-db` + client 1.60.1.69913 |

### WoW Forever

Forever is the unified client's **`camelot`** game type. It is Classic **plus**:
its client keeps Classic's ids -- of Era's 4,807 `QuestV2` ids exactly **two**
are absent from it, all 87 `TaxiNodes` ids survive, and all 1,212 `AreaTable` ids
survive -- and adds **1,795 quests, 160 areas and 13 flight nodes** of its own.

**There is no CMaNGOS world database for Forever**, and the client ships no quest
content at all (`QuestObjective` and `QuestPackageItem` are absent from its DB2
tables, and `QuestV2` carries ids and flags rather than rewards or text). So this
flavour is **Classic's server data on Forever's client tables**:

- Rewards, structure, text, spawn positions, drop rates and the route graph come
  from `cmangos/classic-db`, which is sound because the ids match.
- Everything the **client** decides is generated at Forever's own build: the zone
  rectangles that turn a world position into a map coordinate, the area, map and
  quest-sort tables, the XP tiers and the faction templates behind every `side`.
- **One client table is filled from Era's where Forever's lacks a row**, and only
  one: `AreaTrigger`, whose ids are named by the **Classic dump**. A trigger that
  dump names is a Classic doorway standing in the Classic world -- the world
  Forever ships -- so Era's row is the same door. Measured over both builds: all
  42 doorways the dump names are in Era's table, none is in neither, and the two
  agree on 336 of the 342 rows they share. Of the six that disagree, one (trigger
  608) is named by `areatrigger_teleport` and differs only in the last digit of
  one float; none of the six is borrowed, because the fill adds only ids
  Forever's client lacks. The world-to-map conversion still uses
  **Forever's own rectangles**, so nothing about the fill touches the four that
  moved. See `questdb_common.wago_rows_for_dump_ids`, which states why this
  covers `AreaTrigger` and must never be used for `AreaTable`, `Map` or `UiMap`.

That split is not a formality. **Four of the 54 zone-map rectangles moved between
the two builds** -- Mulgore, Eastern Plaguelands, Redridge and Stormwind City --
so shipping Vanilla's files to a Forever client would put every spawn in those
four zones in the wrong place, while 50 of 54 looked perfect.

**What Forever does not have**, stated plainly because it is a real gap:

- **Most of what its own 1,795 quests need.** No world database describes them,
  so what ships is what the **client itself** answers. TOGTools walks the
  Forever client over every id `GetCoverage` calls `"uncovered"`, and
  `tools/build-forever-harvest.py` turns that walk into
  `Data/Forever/_core/Harvest.lua` and `Data/Forever/enUS/HarvestText.lua`.
  From the 2026-09-28 walk, **775 quests** ship with a title, level, suggested
  group size, log summary, and whatever objective lines survived. Blizzard's
  placeholders (`<UNUSED>`, `<NYI>`, test quests) are dropped.
  **Givers, finishers, objective targets, zone, prerequisites and rewards stay
  empty**, because the walk cannot see them, and **`requiredLevel` is `nil`**
  (not 0) for the same reason, on `GetQuest` and `GetQuestHeader` alike. So
  such a quest has a name and something to do, but no map pin. Kill and item
  objectives lost their names in the walk ("0/10 slain": the client had not
  loaded the creature), so those lines are dropped rather than shipped blank. An
  id the walk did not return still answers `nil` and `"uncovered"`. The
  harvest files never share an id with the dump's, and `data_spec.lua` pins
  that. Re-running is the TOGTools walk, `/reload`, then the converter.
- Apart from that, Forever ships **26 of 26 dungeon entrances and 45 of 45
  explore triggers**, the same as Vanilla. It shipped 6 and 43 until the
  `AreaTrigger` fill above, because Forever's client positions just 9 of the 42
  doorways the dump names. Both counts stay pinned by exact number in
  `data_spec.lua` -- they used to guard the size of the gap and now guard the
  fill, so dropping or misaiming it goes red loudly rather than quietly.
- `GetLevelCap()` answers **60**, the cap Forever's _data_ is defined against.
  What the live realm caps a character at is **not verified** -- its client
  decides that at runtime and no Forever client is installed here. Prefer
  `GetMaxPlayerLevel()` for what a player is subject to now, as on every flavour.

The build is **pinned** (`1.60.1.69913`) because Forever is a beta that moves
every few days and nothing here anchors it; move it forward deliberately and
regenerate the whole `Data/Forever` tree in the same change.

## Regenerating the data

```sh
python tools/build-rewards.py Vanilla     # Data/Vanilla/_core/Rewards.lua
python tools/build-quests.py Vanilla      # Data/Vanilla/_core/Quests.lua (the structure)
python tools/build-npcs.py Vanilla        # _core/NPCs.lua, _core/Objects.lua, enUS/NPCText.lua, enUS/ObjectText.lua
python tools/build-spawns.py Vanilla      # _core/NPCSpawns.lua, _core/ObjectSpawns.lua
python tools/build-drops.py Vanilla       # _core/Drops.lua (--all for every item, not only quest items)
python tools/build-zones.py Vanilla       # _core/Zones.lua (areas, dungeons, explore triggers), enUS/SortText.lua
python tools/build-text.py Vanilla        # Data/Vanilla/enUS/Text.lua + _core/Locales.lua (--locale, --fields)
python tools/build-paths.py Vanilla       # Data/Vanilla/_core/Paths.lua (--tolerance 8, --city-tolerance 2, --ride-tolerance 30, --corner-angle 60)
python tools/build-approaches.py Vanilla  # Data/Vanilla/_core/Approaches.lua (--deviation 25); about 1.5 minutes
python tools/build-rewards.py TBC
python tools/build-quests.py TBC
python tools/build-npcs.py TBC
python tools/build-spawns.py TBC
python tools/build-drops.py TBC
python tools/build-zones.py TBC
python tools/build-text.py TBC
python tools/build-paths.py TBC
python tools/build-approaches.py TBC
python tools/build-rewards.py Forever     # ... and the same nine for Forever
python tools/build-forever-harvest.py     # Data/Forever/_core/Harvest.lua + enUS/HarvestText.lua, from TOGTools' walk
python tools/build-questxp.py             # Data/<Version>/_core/QuestXP.lua, every version
lua tools/verify-xp-parity.lua            # XP against Questie's table; non-zero on any disagreement
python tools/verify-client-levels.py --version Vanilla --write   # refresh the level corrections
python tools/export-parity.py Vanilla     # raw item snapshot -> tools/parity_cache/ (gitignored)
lua tools/verify-parity.lua Vanilla       # every quest/NPC/object/spawn/item/drop/zone field, the kill credits, triggers, hidden set and involved links against Questie
```

The eight CMaNGOS generators read the SQLite world database that **LibItemDB**
already caches at `ItemDB/tools/cmangos_cache/` (its `build-proc-rates.py`
downloads it). The path generator additionally reads wago's `TaxiNodes` and
`TaxiPath` tables for the flight sides, the XP generator wago's `QuestXP`,
the spawn generator wago's `UiMap`, `UiMapAssignment`, `UiMapXMapArt`,
`WorldMapOverlay`, `Map` and `AreaTable` for the zone conversion, and the
zone generator those plus `AreaTrigger` and `QuestSort`, all cached under
`tools/wago_cache/` and fetched on a miss; nothing else is ever downloaded. Each generated file records its source in its header, the
CMaNGOS ones the dump's content fingerprint, because `cmangos/<x>-db`
publishes only a moving `latest` asset.

**Forever's own quests come from the Forever client, not a database.**
TOGTools' developer tab "Quest DB" walks every id `GetCoverage` answers
`"uncovered"` for and saves what the client says into its SavedVariables. After
a `/reload` or logout writes that file, `build-forever-harvest.py` finds it
under any installed flavour's `WTF` folder (or takes `--sv <path>`), drops
Blizzard's placeholder and test quests, and prints every title it dropped. It
never ships an id the dump already has.

**Through writ, the builders run as two approved desk tools, not a shell.**
`qdb-build-data` takes a builder from a fixed list and a version of Vanilla,
TBC or Forever, nothing else. `qdb-forever-harvest` takes no input. Both refuse
to run if a builder file changed since the operator approved them. A locale
build (`build-text.py TBC --locale deDE`) is not covered and stays a stated
shell run.

**Quest levels have a second source, and it wins.** Where the dump disagrees
with the WoW client's own `questcache.wdb` -- the bytes the live server sent --
the dump is wrong: 46 Vanilla levels are corrected (39 `MinLevel`, 7
`QuestLevel`), TBC none. `tools/verify-client-levels.py` finds them and
`--write` records them in **`tools/client-level-corrections.json`**, which is
**committed on purpose**: a cache is one player's, on one machine, so reading it
at generation time would make the generators produce different data for whoever
ran them. Both `build-quests.py` and `build-rewards.py` apply the file, because
each ships a level and a spec asserts the two rows agree. The tool arbitrates a
dump with **one** install -- the one that disagrees least, Era for Vanilla at
2.7% and the Anniversary client for TBC at 0.0% -- since a cache from another
expansion reports Blizzard's rebalancing as an error.

**Breadcrumbs have a hand-kept list too.** The dump sometimes stores an
optional breadcrumb as the destination's **required** pre-quest: quest 33's
`PrevQuestId` is 5261, and 5261 has no `BreadcrumbForQuestId`. Nothing in the
dump tells that apart from a real chain step. On Era, 37 of Questie's 204
breadcrumb pairs have this shape, and the best rule based on the dump alone
flags about 450 pairs to find 34 of them. So `build-quests.py` applies
**`tools/breadcrumb-corrections.json`**: per game version, each breadcrumb and
the quest it leads to. Each pair has been verified in game, and the entry says
who verified it. Questie's list is measured against and never copied. Add a
pair when a player confirms they took the destination quest without the
breadcrumb.

Run the Lua suite and the Python suites after a regeneration:
`lua Tests/wowapi/run.lua`, whose `Tests/data_spec.lua` checks the shipped
tables; `python Tests/test_build_paths.py` and
`python Tests/test_build_approaches.py`, which check the two route generators'
geometry directly; `python Tests/test_questdb_common.py` for the shared
version tables; and `python Tests/test_build_forever_harvest.py` for the
Forever converter.

## For developers

- `CHANGELOG.md` is the full technical history and is published verbatim as the
  GitHub release body.
- Releases are tagged and packaged by the BigWigs packager through the GitHub
  workflow in `.github/workflows/release.yml`.
- **There are FIVE test suites and the gate is ALL of them.** Running one and
  reporting green is the specific mistake this note exists to stop -- each
  runner reports only on itself, truthfully, and says nothing about the others:
  1. `lua Tests/wowapi/run.lua` -- the Lua suite on the WoWAPITesting harness
     (`Tests/wowapi`, a submodule). Coverage with
     `lua Tests/wowapi/coverage.lua LibQuestDB-1.0.lua QuestieSource.lua`, which
     must stay at 100%. `--order reverse` and `--order shuffle` re-run it in
     other file orders, which is what catches a spec that only passes because of
     where its file sits in the alphabet.
  2. `python Tests/test_build_paths.py` -- 34 unit tests over the path
     generator's geometry (`oriented`, `douglas_peucker`, `halves`, the
     transport-kind tables, the capital-city node test), stdlib `unittest`, no
     third-party import.
  3. `python Tests/test_questdb_common.py` -- the version tables every generator
     resolves a flavour through. The failure it guards is the silent one: a
     flavour present in both `CMANGOS_DB` and `WAGO_BUILD` but pointing at the
     wrong pair builds a complete, green, wrong dataset.
  4. `python Tests/test_build_approaches.py` -- 13 tests over the cave-route
     search on made-up geometry: a cliff is not climbed, a tunnel is bridged,
     a chain beats a shorter bridge.
  5. `python Tests/test_build_forever_harvest.py` -- 15 tests over the Forever
     converter: the SavedVariables reader, the placeholder filter in both
     directions, and both row shapes.

  All five are declared in `.writ-suites.json`, so a writ session can run any by
  name; the file is a dotfile and the packager prunes those unconditionally, so
  it can never ship and must **not** be added to `.pkgmeta`'s `ignore:`, where a
  dot-entry is a silent no-op. Dev-only; neither suite ships.
- **Why a Python suite exists at all**, sanctioned by the harness on 2026-09-22
  (contract `98ff1c15`, answered NOT A HARNESS GAP -- the runner already existed
  and nothing had said a consumer could use it): the Lua specs check the
  _shipped output_ and cannot reach a case the dump does not happen to contain.
  The orientation bug of 2026-09-22 needed two nodes at the same x/y and 97 yards
  apart in z. Two of these tests are worth copying into any addon that grows a
  generator suite, because they are what keeps a test honest: one asserts that a
  FLAT comparison _cannot_ decide the Undervator's geometry -- it tests the
  premise, so if it ever passes, the elevator tests have quietly stopped being
  about the bug they exist for -- and one asserts the rounded hairpin thins to a
  bare spike _without_ the corner pass, which is what makes "and not with it"
  mean anything. A third checks the generator's V/L/S letters against
  `LibQuestDB-1.0`'s `TRANSPORT_KIND` decoding: nothing else joins those two
  sides, and a drift there loads fine while every transport silently loses its
  kind.
- Coverage is Lua-only by design, not by omission: `coverage.lua` reads the
  executable-line set out of Lua 5.1 bytecode debug info and cannot see Python.
  A generator is judged by whether its output is right, which is what the unit
  tests over its pure functions establish.
- `tools/` holds the data generators. Dev-only; it never ships.
- `QuestieSource.lua` is the only file that names Questie, and the reason is
  written at the top of it: Questie's database is **not** part of its public
  API (`Questie/Public/README.md:3` promises stability only for
  `Questie.API`), so a Questie release can change the rows under us. Keeping
  every such call in one file means such a change breaks one file with its own
  specs, and its feature detection then registers nothing -- leaving every
  consumer on the shipped data rather than broken.

### In-game checks still open

Everything above is verified offline against the sources and against Questie.
Three questions only a live client answers; whoever next has one open can close
them in a minute each:

- **Is the at-cap money six times the shown (rounded) XP or six times the raw
  tier?** They differ on ~28% of quests, and the six live readings so far were
  all quests where they agree. A level 60 opening the offer window of **The New
  Frontier** (Alliance: quest 1015 from Crier Goodman, NPC 2198, in
  Stormwind; Horde: quest 1000 from Bluff Runner Windstrider, NPC 10881, in
  Thunder Bluff; level 55, no ordinary money) sees **33s** if rounded (550 XP)
  or **33s 60c** if the raw tier (560). The New Frontier is the candidate both
  factions share; whichever it is, `moneyMaxLevel` in `GetRewards` changes
  one line.
- **What the data costs at login.** Both flavours now load about 5 MB of
  Lua source (see the table above) as packed strings. Expected order of
  magnitude in the AddOns list's memory column: **single-digit megabytes** --
  the strings themselves plus Lua's table overhead per row; an
  uncharacteristic number (tens of MB) means a row is being decoded eagerly
  somewhere. Not yet measured.
- **Do the cave routes walk?** Track Grik'nir the Cold (NPC 808) in the
  Frostmane troll cave, Coldridge Valley, with Questbook and follow the HUD from
  the valley floor. It should lead to the cave mouth and down through the cave,
  not over the hill. If it walks into a wall, the wall is a bridge
  (see "Off the graph" above).

Flight sides are derived from the client's `TaxiNodes` and `TaxiPath` tables as
exported by **[wago.tools](https://wago.tools)**. Quest reward and text data,
and the path graph (the playerbot module's travel graph), are derived from the
**[CMaNGOS](https://github.com/cmangos)** world databases
([classic-db](https://github.com/cmangos/classic-db) /
[tbc-db](https://github.com/cmangos/tbc-db), GPL-3.0; the server _core_ is
GPL-2.0, but only the database repos are read), which reverse-engineered and
tested them. The facts are extracted and re-expressed in this library's own
format; no CMaNGOS file is redistributed. WoW Forever's own quests are the
Forever client's own answers, collected in game by TOGTools.

## License

MIT. See `LICENSE`.
