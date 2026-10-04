# QuestDB Changelog

## [v0.1.0] (2026-09-29) - Routes into caves, WoW Forever's own quests, and Questie 12's QuestieDB split checked

### WoW Forever's own quests, from the client itself

- **The report.** The operator found a Forever quest the library did not know,
  "Grund and Gozwin" (97277). Forever adds about 1,795 quests of its own, and
  nothing offline describes them. QuestieDB 1.0.4's Forever store holds exactly
  Vanilla's 4,257 ids, and Forever's QuestV2 table carries no titles.
- **The source is an in-game walk.** TOGTools (inbox 76745964) asks the Forever
  client about every id `GetCoverage` answers "uncovered" for, and saves what comes
  back. The first walk capped ids at 65000 while Forever's own run to 99234, so it
  found only 64 leftovers. That cap was in my request, not in their code. The second
  walk, finished 2026-09-28, returned 833 quests.
- **New `tools/build-forever-harvest.py`** reads that SavedVariables file and writes
  two new Forever files, both in `QuestDB_Camelot.toc`:
  - `Data/Forever/_core/Harvest.lua` gives each quest a structure row carrying
    its level and suggested group size.
  - `Data/Forever/enUS/HarvestText.lua` carries the title, the log summary, and
    every objective line that still says something.
- **775 quests ship; 58 were dropped:**
  - 57 were Blizzard placeholders the client still answers for: `<UNUSED>`,
    `<NYI>`, `[Never used]`, test quests, and the two Wabbit quests on Designer
    Island.
  - 1 ("Toast!?") came back with no level. An empty structure row is skipped on
    load, so its title would have had no quest behind it.

  The run prints every dropped title, so a real quest caught by the filter shows up.
- **Required level is "not known", not 0 (MINOR 20).** The walk cannot see it.
  An empty field would read as 0, which a quest list's level filter takes as
  "open at level 1". Harvested rows carry `?`, which `GetQuest` and
  `GetQuestHeader` return as `requiredLevel = nil`, so a consumer must handle
  nil there. Dump rows are unchanged. This came from Peer Review, audit
  36140a10.
- **What the walk cannot see is left empty:** givers, finishers, objective
  targets, zone, prerequisites and rewards. These
  quests have a name, a level and what to do. They have no map pin.
- **Kill and item objectives lose their names.** The client had not loaded the
  creature or item, so it answered "0/10  slain". Those lines are dropped. Custom
  lines such as "Listen to Elaadrin" are kept.
- **Separate files on purpose.** `Quests.lua` and `Text.lua` are built from the
  dump, and the specs pin their counts. The harvest never shares an id with them:
  the converter only accepts ids `Coverage.lua` lists as uncovered.
- **Specs.** A new Python suite, `Tests/test_build_forever_harvest.py`, has 15
  tests. They cover the SavedVariables reader, the filter in both directions
  ("Testing the Wells" is a real quest and is kept), and both row shapes.
  `data_spec` has 4 new Forever specs: the header counts match what loads, every
  id was uncovered and overrides nothing, no placeholder title ships, and "A Grand
  Adventure" (92709) reads as the client describes it. `toc_spec` accepts
  `HarvestText.lua` as a per-locale text file.

### Retired quests: a third hidden reason (MINOR 20)

- **Asked for by a consumer.** Questbook (inbox fc73aa34) found quest 8788 "A
  Gently Shaken Gift" listed as Ready. Its only reward, item 21271, is named
  "DEPRECATED ITEM"; its twin 8767 is the live one. Both start from the same
  gift object, so 8788 was not "unobtainable".
- **`hidden = "retired"`**, capability `retired-quests`, on `GetQuest`,
  `GetQuestHeader`, `IsQuestHidden` and `GetHiddenQuests`. It means something
  still starts the quest, but the game has retired it. Precedence is
  unobtainable, then retired, then seasonal.
- **Two signals, both measured before use:**
  - A text field carries Blizzard's `[PH]` placeholder marker. Era: 7 quests,
    the mount-exchange quests 7671-7678, all in the turn-in text. TBC: 3, but
    none has a giver, so they stay "unobtainable".
  - Every item the quest rewards is named "DEPRECATED ..." by **that game
    version's own client** item table. Only Forever's client renames 21271, so
    only Forever flags 8788. The Classic dump and Era's and TBC's clients all
    call it "Gently Shaken Gift". So on Era, 8788 still shows. Questie hides
    both 8788 and 8767 on Era; that list is compared against, never copied.
- **Result.** Era 7 retired, TBC 0, Forever 8. Forever's seasonal count drops
  from 327 to 326, because 8788 was seasonal before.
- **7674 "Black Ram Exchange"**, the second quest Questbook named, is one of the
  seven.
- **`build-quests.py` now reads the client item table** (wago `ItemSparse`, one
  per version). Specs: one new reader spec for all four readers, the capability
  lists, and an exact per-version id list in `data_spec`. Coverage on
  `LibQuestDB-1.0.lua` is 960/960.

### City routes follow the streets

- **The report.** Questbook (inbox 684f18d9) relayed the operator, in Ironforge:
  "still having issues following routes in towns, like ironforge, we need to
  follow usable routes". The drawn route crossed the buildings between the
  Commons and the Great Forge.
- **The cause was my thinning, not missing data.** Every Ironforge walk link
  already carries the route the bots walked (26 links between 8 nodes, 9 to 70
  raw points each). But walks were thinned to within 8 yards of that route, and
  a city street is narrower than that. The innkeeper to King Magni walk shipped 7
  points over 350 yards, one of them a straight 125-yard chord.
- **Fixed.** `build-paths.py --city-tolerance` (default 2 yards) now thins every
  walk with either end inside a capital city. A capital is found by name in the
  client's own AreaTable, through the same zone placement the spawns use. A node
  counts when ANY zone map showing it is the city, so a node at the city's edge,
  such as Ironforge's gate, counts on its own (Peer Review, audit 36140a10;
  pinned in `Tests/test_build_paths.py`). That walk now keeps 14 points, and no
  stretch is longer than 90 yards. It is pinned in `data_spec` on all three
  game versions; TBC numbers the same two nodes 740 and 1347. Sizes: Vanilla
  and Forever `Paths.lua` 877,509 to 901,007 bytes, TBC 1,324,145 to
  1,357,933.
- **Cave routes unaffected, checked.** `build-approaches.py` reads the dump, not
  `Paths.lua`. Rebuilt on Vanilla after the change, it gave the same 10,346
  routes and the same 1,141,656 bytes. That was compared by size and count, not
  byte for byte.
- **Not more nodes.** The dump has no other Ironforge street nodes, so none can
  be added from it. The leg from the player to the first node, and from the last
  node to a target, is still the consumer's to draw. Not verified in game.

### Breadcrumbs the dump stores as required pre-quests

- **The report.** Questbook (inbox 68f14a22): a player on Classic Era, with
  other addons off, took 33 "Wolves Across the Border" without 5261 "Eagan
  Peltskinner", and got no "this closes a breadcrumb" warning. The dump sets
  33's `PrevQuestId` to 5261 and leaves 5261's `BreadcrumbForQuestId` empty. So
  5261 shipped as a required pre-quest, and anyone who skipped it saw 33 marked
  as needing it.
- **Fixed for that pair** on Vanilla and Forever: 33 has no pre-quest, 5261 is
  a breadcrumb for 33, and 33's `breadcrumbs` lists 5261. TBC's dump has the
  same shape, but nobody has reported it there, so TBC is unchanged.
- **The class is 37 pairs on Era, and only this one is fixed.** Decoding
  Questie 12's QuestieDB store gives 204 breadcrumb pairs. The dump already
  marks 113 as breadcrumbs, stores 37 as the destination's required pre-quest
  like 5261, and links 54 some other way.
- **No rule based on the dump alone can find them.** The best one tried, "a
  quest with no objectives whose finisher gives the next quest", flags about
  450 pairs to catch 34 of the 37. The dump stores an optional "go talk to X"
  quest exactly like a required chain step. Questie's list is measured against
  and not copied, so the fix is a hand-kept list:
  `tools/breadcrumb-corrections.json`. Each entry is a pair verified in game
  and names who verified it. `build-quests.py` applies it.
- **Players with Questie installed were not affected.** With Questie present,
  `preQuestSingle` and `breadcrumbForQuestId` come from Questie
  (`QuestieSource.lua`).

### Spawn approaches: a walking route into a cave, not a line over it (MINOR 19)

- **Asked for by a consumer.** Questbook (inbox 7ad98754) relayed the operator,
  in game on Forever, tracking a target in the Frostmane troll cave in Coldridge
  Valley: "drawing a straight line to the guy, when it should guide me to the cave
  entrance, then through the cave". The path graph has no node near that cave, so
  no router could do better; the route had to be data.
- **`QuestDB:GetSpawnApproach(kind, id, areaId, x, y)`**, capability
  `spawn-approach`, new file `Data/<Flavour>/_core/Approaches.lua` in all three
  TOCs. It answers a route from a walk node of `GetPathGraph(continent)` to a
  quest spawn point, in world yards, or `nil` when nothing better than a straight
  line is known.
- **Keyed by the spawn's map position, not the index the contract suggested.**
  With Questie installed, `GetNPCSpawns` answers from Questie's rows, whose points
  are in a different order, so an index would name the wrong spawn. The reader takes
  the nearest shipped point within one map percent. 93.6% of Questie's points have
  one of ours that close.
- **The source is where things stand.** The dump has no navigation mesh. It does
  have every creature, object and patrol point, each somewhere a thing actually
  stands. The new `tools/build-approaches.py` chains them outward from the graph's
  walk routes, in steps of at most 22 yards on a walkable slope. It bridges gaps up
  to 120 yards at a steep cost where nothing stands in between. The Coldridge
  cave's mouth is 87 yards from the nearest valley spawn, so it needed a bridge. A
  route ships only when it strays more than 25 yards from a straight line.
- **Measured.** Vanilla: 10,346 of 65,528 quest spawn points get a route (320 out
  of every reach), 1.14 MB. TBC: 16,107 of 92,000 (671), 1.93 MB. Forever is the
  same as Vanilla because it reads Classic's dump. Generation takes about 1.5
  minutes per flavour. On all three, Grik'nir the Cold's route enters the cave at
  (-6466, 368) and runs down to his spawn.
- **What it does not know.** It does not detect a cave: it detects that the ground
  route bends, which is the case a straight line gets wrong. A bridge is a
  straight line across a gap nothing occupied. That is usually a tunnel and could
  be rock. Not verified in game.
- **Specs.** The reader has 7 new specs. The shipped data gets 4 per flavour:
  every route starts at its node, names a shipped spawn point, and matches the
  pinned count, and the Coldridge route goes in through the mouth. The new Python
  suite `Tests/test_build_approaches.py` has 13 tests over the search on synthetic
  geometry: a cliff is not climbed, a tunnel is bridged, and a chain beats a
  shorter bridge. Coverage on `LibQuestDB-1.0.lua` is 959/959.
- **One placement, one thinning, one continent table.** The generators now share
  code instead of each keeping a copy:
  - Spawn placement moved from `build-spawns.py` into
    `questdb_common.place_spawns`, which also returns each point's world position.
  - `douglas_peucker` moved from `build-paths.py` to `questdb_common`.
  - `CONTINENTS` moved to `questdb_common`.
  - `build-drops.py` gained `sources_by_item`.

  `NPCSpawns`, `ObjectSpawns`, `Paths` and `Drops` regenerate byte-identical on all
  three flavours after the move.

### Everything else

- **The replication watcher never deletes a replica while the source still has the
  file.** This was TOGProfessionMaster's finding (inbox 6d593ab7): an editor that
  saves by replacing a file can make it vanish for an instant. Our copy polls, so
  the most it could have lost was one 2-second poll. The guard went in anyway.
  Dev tooling only.
- **Dev sync reaches WoW Forever.** `wow-version-replication.ps1` already listed
  `_classic_beta_`, and the Forever client is now installed there, so the
  watcher copies into it. Its comment no longer says nothing is installed, and
  now says the destination list is built once at startup: restart the watcher
  after installing a client. Dev tooling only, nothing ships.
- **Questie 12.0.1 split its data into a separate `QuestieDB` addon; no code
  change is needed.** Read against the installed copies: `QuestieSource.lua`
  reaches Questie through `QuestieLoader:ImportModule("QuestieDB")`, which still
  exposes `QueryQuest` / `QueryNPC` / `QueryObject` (now bound to
  `LibQuestieDB.<Type>.GetAll`, still one positional table per call) and a
  `QuestPointers` id map. Every field name we request is still a key. Load order
  holds: Questie has `RequiredDeps: QuestieDB`. Not verified in game.
- **QuestieDB's Forever store does not carry Forever's own quests either.**
  Decoded every `X-Quest-<id>` row of `QuestieDB_Forever.toc` and
  `QuestieDB_Vanilla.toc` (1.0.4): 4,257 quests each, the identical id set, zero
  Forever-only ids. So preferring Questie cannot close the Forever gap. Found
  from "Grund and Gozwin" (Dun Morogh, level 6), a Forever quest built on two NPC
  ids our Classic data lists as unused (2756, 6046). Forever's client DB2s carry
  no quest titles either (`QuestV2` is id and flags only). The one remaining
  source is the Forever client itself: `C_QuestLog.RequestLoadQuestByID` plus
  `QUEST_DATA_LOAD_RESULT` can load a quest by id. That is what the TOGTools walk
  in "WoW Forever's own quests" above uses. The walk showed objective text does
  come back for a quest nobody holds, though kill and item names often do not.
- **The data builders run through two writ desk tools.** `qdb-build-data`
  accepts only one of ten builders and one of Vanilla, TBC or Forever.
  `qdb-forever-harvest` takes no input. Writ fingerprints every builder file and
  refuses a run after one changes, until the operator approves again. So the
  tools cannot be used to run an edited script. Dev tooling only; not yet
  approved or run.
- **The suite is green again against Questie 12.** WoWAPITesting delivered a
  loader for the real QuestieDB addon (835bc59, inbox ca4893c4), pinned through
  the new `wowapi-pin` desk tool. It is now at ec71c24, whose
  `forgetQuestieDB()` the spec calls in teardown so QuestieDB's globals do not
  leak into later spec files (inbox 35888ec6). One of those globals is
  `ItemDB`, which is also LibItemDB's. `Tests/questie_source_spec.lua` now builds
  its Questie rows through Questie 12's own query module. Result: 333 passed,
  0 failed; coverage is 957/957 on `LibQuestDB-1.0.lua` and 221/221 on
  `QuestieSource.lua`.
- **`GetNPCIds` / `GetObjectIds` list a source's ids too (MINOR 20).** The spec
  guarding this went red on its first run against Questie 12: QuestieDB knows
  NPCs 185333-185335, which the dump does not. So `HasNPC` answered for ids
  `GetNPCIds` never listed. There are two new source readers, `npcIds` and
  `objectIds`. `QuestieSource.lua` answers them from Questie 12's `NPCPointers`
  / `ObjectPointers`, and the three id readers now share one function.
- **Parity re-measured against Questie 12** (2026-09-29, through the new
  read-only `qdb-verify-parity` desk tool). `tools/verify-parity.lua` now reads
  Questie 12's QuestieDB through the harness loader instead of the pre-12
  reader. Headline figures, Era then TBC:
  - breadcrumbs 97.6% and 97.3%;
  - chain pointers 94.7% and 95.6%;
  - exclusivity 94.8% and 94.7%;
  - prerequisites, exact, 91.8% and 90.6%;
  - Questie's hidden quests we also hide: 81.2% (273 of 336) and 90.9% (930 of 1,023);
  - NPC spawn areas 85.7% and 88.0%;
  - Questie's NPC spawn points with one of ours within 1% of the map: 87.3% and
    89.4%.

  The NPC spawn figures fell from 90.1% and 93.6% under pre-12 Questie. Our data
  did not change, so Questie's did; which rows moved was not examined. Questie
  12 moved its zone, drop-table and item-fix files, so the checks that read them
  now find nothing to compare.
- **Docs brought level with the code for the release.** The README's WoW
  Forever section said a harvested quest's required level "reads as 0". That
  was wrong: since MINOR 20 it is `nil`. I corrected it and added the `nil` to
  the `GetQuest` and `GetQuestHeader` tables. The MINOR table gained its
  missing entry 20. The source-preferred list now names `GetNPCIds` and
  `GetObjectIds`. The walk row notes the 2-yard city thinning. The Features
  list gained retired quests and breadcrumb corrections. A note says the
  `Load*` / `SetSource` / `SetShippedLocales` methods are for the Data files
  only. The CurseForge page gained the reverse item lookup, hidden-quest
  reasons, `RegisterSourceChanged` and the nil required level in its example
  and rules.

Older releases have been moved to
[CHANGELOG_ARCHIVE.md](CHANGELOG_ARCHIVE.md) so this file stays under the
125,000-character limit GitHub imposes on a release body.
