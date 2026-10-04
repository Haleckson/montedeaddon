# Changelog

<!-- charset-ok: no WoW client font ever renders this file -- nothing loads a .md, and the
     packager publishes it verbatim as the GitHub release body, which is read in a browser. The
     stronger reason is that released entries MUST NEVER BE EDITED (repo law), and the em dashes
     are spread through every shipped version back to v0.1.0, so transliterating them would mean
     rewriting release history to satisfy a rule about in-game glyphs. New text here is written
     ASCII anyway; this declaration exists so the linter's report stays about the current entry
     instead of being permanently non-empty, which is how a report stops being read. -->

## [v1.1.4] - 2026-09-29

### Fixed -- ordinary vendor goods read "PvP" on TBC and Mists

Refreshing Spring Water (159) showed only "Alterac Valley / PvP" as its source on TBC, with none
of its innkeepers, vendors or quests (SmexyMats peer review `60e304d70cab`, found while generating
its tooltip data from ours). The cause was in `tools/build-item-sources.py`: the battleground
reward-vendor pass REPLACED an item's whole location set with the battleground whenever a
`BG_VENDORS` NPC sold it, exempting only ammo. TBC's Stormpike Quartermaster (12096) stocks common
food, water, reagents and flasks, so every one of those lost its real sources. The pass now skips
any item a vendor outside a battleground also sells (`sold_outside_bg`).

- **TBC:** about 60 items corrected (water, bread, flasks, reagents, arrows), e.g. 159 now reads
  Vendor and Quest. Item 1 (a placeholder id, "World Drop") also left the file on this rebuild.
- **Mists:** about 70 items corrected, the same pattern.
- **Vanilla:** unaffected -- the classic DB's quartermaster stocks none of them, and 159 already
  read Vendor and Quest. Not rebuilt: `.build.info` no longer lists the Era product, so the builder
  needs `--wago-build`, which the desk's `itemdb-build` tool cannot pass.
- **A trade-off, stated:** the battleground-only healing draughts (17348, 17349, 17351, 17352) on
  TBC and Mists, and the Warsong tabards (19505, 19506) on Mists, now read Vendor instead of their
  battleground, because the CMaNGOS / SkyFire DB has a vendor outside a battleground selling them.

### Changed -- the "Which click" chooser is LibAceGUIWidgets' capture widget

The /itemdb Tooltip tab's "Which click" control is now `LAGW-ClickBinding` (LibAceGUIWidgets
MINOR 38, built for this at TOGProfessionMaster's request, contract `e0f3923e3548`): the player
clicks it, then performs the combination. It has a Default button that restores Alt + Left Click,
read from the tooltip defaults through a new private `lib:_GetTooltipDefault(key)`. It also allows
the middle and extra mouse buttons, which `ParseClickBinding` already accepted. On an older
LibAceGUIWidgets the dropdown of 14 combinations stays. Both store the same canonical string, so no
saved value changes. `win.clickDropdown` is renamed `win.clickChooser`.

### Changed -- test harness pinned at b1d9bd5 (was 20453ac)

From 9c6c874 on, the harness's `libs.load("LibAceGUIWidgets-1.0")` includes the ClickBinding file,
so the spec no longer loads it itself. No other Adoption entry in that range needed a change here;
the suite is 777/777 at the new pin. The new `pkgmeta.lua` checker (a desk tool from 6eb30e0, asked
for on inbox `d6eb270e8b4f`) reports no FAIL on `.pkgmeta`. Its three WARNs were left as they are:
the `"*.sh"` and `"*.bat"` ignores match no tracked file today, but they are guards against a
future script shipping; and `curseforge-project-id:` is not needed in `.pkgmeta` because every TOC
carries `X-Curse-Project-ID: 1558208`.

### Changed -- release docs

README: the source-locations pipeline paragraph states the battleground-vendor rule, and the
tooltip-settings row says `whereClick` is set on the `LAGW-ClickBinding` control (dropdown on an
older LibAceGUIWidgets). The CurseForge page gains the v1.1.4 notes. Checked against both files
for this release's changes: no item count, build number or feature row they quote moved.

### Fixed -- a stale comment about VersionCheck-1.0

`ItemDB.lua` and `CLAUDE.md` said VersionCheck-1.0 is Classic-only. Its TOC declares Retail too
(120005, 120007, 120100); both comments now say so (SmexyMats peer review `34ee062fd221`).

## [v1.1.3] - 2026-09-28

### Changed -- WoW Forever's items now come from the client's own item walk

Until now Forever's `_core` was synthesized by `tools/build-core-wowsims.py`: structure from wago,
stats from WoWSims' `db.json`, because no Forever client had been walked. The operator ran the
TOG Tools Item DB walk on Forever, and `tools/build-core.py Forever` now builds the core from it,
as every other flavour's is. What that changed, measured against the WoWSims build:

- **23,596 items, up from 19,171.** The first walk stopped at item ID 240,000 while Forever's run
  to 287,090; TOG Tools raised its ceiling (inbox `500e4ce2`) and the re-walk carries them.
- **Weapon DPS on every weapon.** The WoWSims build left most white weapons with no stats at all,
  so they scored 0 EP for every spec (Dibs, DIBSREQ-IDB-009: Copper Mace over Anvilmar Hammer
  showed "Dibs EP: 0").
- **Spell power on 1,098 items that had none**, and other stats WoWSims simply lacked -- e.g.
  item 20341 shipped with armor only and now carries its +39 frost damage and 28 Intellect.
- **249 school-tagged spell-damage items, up from 171.**
- **131 items removed**: placeholder IDs with no name (1-19 and similar) and two unused Vanilla
  rings (18674, 18678) that the Forever client does not return. Their rows left the side tables
  with them (`ReqLevels`, `SellPrices`, `ConsumableGroups`, `Sources`).

### Added -- `build-core.py` translates a Forever walk into the keys its scoring reads

Forever loads `Scoring/Vanilla.lua`, which prices crit and hit as flat percentages, mp5 as
`ITEM_MOD_POWER_REGEN0_SHORT` and damage-and-healing as `ITEM_MOD_SPELL_POWER` -- the Classic Era
walk's own spellings. The Forever client reports ratings and `_SHORT` keys instead, and shipped raw
every rating stat would have scored 0. `WALK_VOCAB` / `FOREVER_KEYS` / `normalize_forever` map each
walk key onto the Classic one. The mapping was derived from data, not names: every walk key was
cross-tabulated against the WoWSims-built core over the 19,161 items both carry (crit 14:1 onto
`CRIT_PCT` on 488 of 521 items, hit 10:1 on 172 of 183), and the divisors are read from wowsims'
own constants, which agree exactly. Per-school damage folds onto `ITEM_MOD_SPELL_DAMAGE_DONE` with
a `SpellSchools.lua` tag, as the Era walk ships it; the client's doubled resistance keys count once.

**Hit and crit now score for casters on Forever.** Forever merged them ("one stat now covers every
attack", outputlag.com), and item 21624 is +1% spell crit in Era's data and crit rating 14 in
Forever's. The WoWSims build mapped them to the melee key alone, so a caster got nothing for them;
each now lands on both `HIT_PCT`/`SPELL_HIT_PCT` and `CRIT_PCT`/`SPELL_CRIT_PCT`.

**Weapon skill on Forever items is priced.** The walk reports it as `ITEM_MOD_DAGGERS_SHORT` and
so on, in skill points -- the same unit as Classic: Death's Sting (21126) is dagger 3 and Hands of
Thero-shan (7951) dagger 4 in both clients, while items Forever retuned shrank (Huge Thorium
Battleaxe 10 to 2). The seven spellings the walk carries map onto `WEAPON_SKILL_*`, reaching nine
items; other spellings are unverified (the client's string table is not in the UI source) and
stay unmapped. `Tests/forever_scoring_spec.lua`'s weapon-skill tripwire was re-decided to eleven.

`rating_divisors`, `RATING_CONST`, the school fold (`fold_school_damage`) and the SpellSchools
writer moved from `build-core-wowsims.py` to `itemdb_common.py`, so the two builders cannot
disagree. `build-core-wowsims.py` now refuses to overwrite a walk-built core.
`Tests/forever_vocab_check.py` (new, declared in `.writ-suites.json`) pins the translation.

### Added -- drop sources for three of Forever's new dungeons

`tools/build-sources-imenso.py` had never shipped: the README said the new dungeons' item ids
were not in Forever's item table. The walk carries them, and it now writes
`Data/Forever/_core/SourcesImenso.lua` + `SourceNamesImenso.lua` (added to `ItemDB_Camelot.toc`):
33 items across The Hall of Thanes, City of Dalaran and Ruins of Lordaeron, 11 bosses, under the
source `"imenso"` with synthetic encounter ids. Excavation Site resolves too but none of its loot
is in the walk yet.

Two of the three only resolved after a second tie-breaker in `resolve_area`: a name shared by two
areas used to need the shipped `Sources.lua` to settle it, and a new dungeon is by definition not
there. `instance_areas` now reads the client's own `Map` table -- the area on a dungeon/raid map
(`AreaTable.ContinentID` whose `Map.InstanceType` is 1 or 2) beats its outdoor namesake (Ruins of
Lordaeron 16611 over 153), and two areas on one dungeon map are settled by `Map.AreaTableID`
(City of Dalaran 16544 over 16560). Still a refusal unless it narrows to exactly one; the shipped
file still wins when it has committed. Five cases added to `Tests/imenso_reference_check.py`.

### Fixed -- `core_ids` let removed items back in through the side tables

`itemdb_common.core_ids` read every `_core` file except a hand-kept exclusion list, so side tables
(`SellPrices`, `ReqLevels`, ...) fed their own ids back into the item set every builder gates on.
After the walk rebuild it still returned the 131 removed ids, and a removed item could never
leave. It now reads only files that call `lib:LoadCore`.

### Fixed -- two builder guards that misread the rebuild

- `build-locales.py` refused Italian for "losing" one localized name. The name was English: the
  client's `'Formula: Powerful Smelling Salts '` carries a trailing space and wago's does not. The
  localized-count comparison now ignores surrounding whitespace.
- `build-sources-wowsims.py`'s expected-leak list gains seven TBC/Wrath instances (Shadow
  Labyrinth, Auchenai Crypts, The Botanica, The Mechanar, The Oculus, The Nexus, Ahn'kahet). Each
  was refused because Forever's AreaTable lacks it -- the same id-collision leak as the two before.

### New -- the "Where to get it" click is the player's choice, Alt+Click by default (MINOR 38)

TOGProfessionMaster's contract `060eb26d`, from a player on Discord: Alt+click "collides with
gargul". The operator: _"we make it alt+click by default, but make it so the users can change it"_.

- New tooltip option `whereClick`, default `"ALT-LeftButton"`, in WoW's binding spelling.
  `SetTooltipOption` validates it through the new `ParseClickBinding` and stores it canonical;
  a binding with no modifier is refused, because an unmodified item click is the game's own.
- `_WhereOnModifiedClick` now asks the new `IsWhereClick` instead of `IsAltKeyDown`. Modifiers
  match **exactly**, so a player's Alt binding does not fire on Shift+Alt. The button is compared
  where `GetMouseButtonClicked` answers (documented in the forever tree's
  `InputDocumentation.lua`; listed in the classic and anniversary restricted environments), and
  the modifiers decide alone where it does not, since `HandleModifiedItemClick` hands its hook only
  the link. Not verified in game on any client.
- `altClick` stays the on/off switch, so a player who saved it off before this is still off.
- The tooltip heading's hint names the player's click (`ClickBindingText`): "Ctrl+Shift+Click:
  where to get it", not a fixed "Alt+Click".
- The `/itemdb` Tooltip tab gains a "Which click" dropdown beside the switch, filling that row's
  empty half so the tab still fits. It offers every modifier combination with the left or right
  button. The contract asks for a click-capture widget from LibAceGUIWidgets (their contract
  `e0f3923e3548`); the dropdown stores the same value, so that widget can replace it later
  without a data change.
- Specs: a non-default combination opens it and the old default no longer does, an extra
  modifier does not, the button is honoured when known, an old `altClick = false` stays off, bad
  bindings are refused, an unreadable stored value never matches, the hint and the dropdown.

### Fixed -- a full Auction House scan on Forever raised an error and stored no prices

The operator hit it on Forever: `Frame:UnregisterEvent(): Attempt to unregister unknown event
"AUCTION_ITEM_LIST_UPDATE"`, from `fullUnregisterEvents` inside `fullStore`. The modern
`ReplicateItems` scan never registers the legacy full-scan events, but `fullStore` unregistered
them unconditionally, and a client with the modern Auction House has no `AUCTION_ITEM_LIST_UPDATE`
to unregister. The error fired before a single price was written, so every full scan on that
client was discarded. That covers Forever; Mists takes the same modern path and is very likely
affected too (not verified in game). `fullRegisterEvents` now sets `S.fullEventsRegistered` and
`fullUnregisterEvents` undoes only what it registered. The spec's `FrameUtil` stub accepted any
unregister, which is why the suite never saw it; the modern full-scan spec now raises exactly as
the client does, and fails with the old line put back.

### Fixed -- the Auction House scan button sat below the title bar on Forever and Mists

The operator's screenshot, Forever: the "ItemDB Scan" button hung half under the title bar, over
the Browse pane. `showScanButton` in `Price/Scanner.lua` anchored it at a fixed `TOPLEFT 72,-15`,
an offset laid out for Classic Era's legacy `AuctionFrame`. The modern `AuctionHouseFrame` (Mists
and Forever) is a `PortraitFrameTemplate` whose title bar is a 20-high `TitleContainer` at
`TOPLEFT 58,-1` (`SharedUIPanelTemplates.xml` in the forever tree; `PortraitFrame.lua`'s
`SetTitleOffsets` in the classic tree gives the same 58/-1). The button now centres on that bar,
4 px in from its left edge, whenever the frame has one; the legacy frame keeps its offset. Two
assertions in `Tests/pricescan_spec.lua` pin both placements. Not yet seen in game.

### Fixed -- the dev replication watcher deleted live files from the other installs

`wow-version-replication.ps1` (dev-only; never packaged) treated a save-by-replace as a delete. An
editor that saves by replacing the file raises `Deleted` and `Created`/`Changed` for one save, in
either order, and when `Deleted` landed last the file was removed from every replica install while
the source still had it. `Sync-File` now honours a delete only when the source file is really gone
and otherwise copies it.

### Changed -- docs brought up to date for the walk-built Forever core

`README.md` and `docs/Curseforge_Description.html` state Forever's item count as 23,596 (was
19,171), say its stats come from the client walk rather than WoWSims, and list the three new
dungeons' drops in the per-version feature tables.

### Tests

- `Tests/forever_weapon_dps_spec.lua` (new): Copper Mace and Anvilmar Hammer carry the client's
  DPS and both score above 0 for a protection paladin on the shipped Forever data, the mace higher.
- `Tests/forever_scoring_spec.lua`: Forever's weapon-skill population is now two -- the rebuilt
  `Sets.lua` (150 to 261 sets) adds Defias Leather's +1 dagger bonus. Re-decided and accepted, as
  that spec asks: same gated function, one attack shape.

## [v1.1.2] - 2026-09-27

### Fixed -- opening a vendor raised "attempt to call a nil value" on WoW Forever

The operator hit it on Forever: `Price/Sources.lua:1076`, inside `GetMerchantItemInfo`, fired
from the `MERCHANT_SHOW` merchant capture. Forever still defines the bare global, but calling it
fails inside the C function; the Forever client's own `MerchantFrame.lua` (Mainline) calls only
`C_MerchantFrame.GetItemInfo`, which `MerchantFrameDocumentation.lua` documents as returning a
`MerchantItemInfo` table (`price`, `stackCount`, `numAvailable`, ...). I had written the capture
against the bare global only, so every vendor visit on Forever errored and cached no prices.
`captureMerchant` now reads through a `merchantItem` helper that prefers the namespaced function
wherever it exists and falls back to the global on the flavours without it, and skips a slot when
neither exists. Two specs in `Tests/price_spec.lua` pin it: the namespaced call wins over a global
that raises, and a client with neither API skips the slot. `.luacheckrc` gains `C_MerchantFrame`.

Checked per flavour in `F:\Blizzard API Docs`: the `classic_era`, `classic` (Mists) and
`classic_anniversary` trees all declare the `C_MerchantFrame` namespace, but with
`GetBuybackItemID` as its only function -- no `GetItemInfo` -- so those clients still take the
bare-global branch exactly as before. Only Forever takes the new one.

### Changed -- the feature tables split vendor prices into shipped and captured

`README.md` "Features by version" and the CurseForge "What works on which version" table had one
"Vendor buy and sell prices" row, which covers the shipped vendor price data only (Mists: No). The
merchant capture above is a second, separate source -- `GetVendorBuyPrice` answers
`source = "merchant"` from it on every flavour, Mists included -- and was listed nowhere. Both
tables now carry it as its own row; the README marks Forever's cell "from v1.1.2".

## [v1.1.1] - 2026-09-27

### Changed -- a per-version feature table in the README and on the CurseForge page

The operator asked for the docs to state feature parity across versions. `README.md` gains
"Features by version" and `docs/Curseforge_Description.html` "What works on which version": one row
per feature, one column per shipped flavour (Classic, TBC, Mists, Forever). Every cell was read
from which `Data/<Version>/_core/*.lua` files exist and which each TOC loads, not from the prose
that was already there. That makes explicit what the prose only implied: Mists ships no class,
faction or required-level data, no sets, buffs, talents, consumable groups, scoring, BiS, mounts
or vendor prices, and Forever has no gathering source and no "Where to get it" data.

### Fixed -- every item link raised "attempt to call a nil value" on WoW Forever

The operator hit it on Forever, through Questbook's search: `LibItemDB-1.0.lua:370`, inside
`qualityHex`, called from `buildLink`. I captured `GetItemQualityColor` as the bare global only,
and Forever (1.60.x) ships just `C_Item.GetItemQualityColor` -- same four returns, the fourth the
hex string (`wow-ui-source-forever` `ItemDocumentation.lua:920`). The capture now prefers
`C_Item` and falls back to the global, like the class-info captures beside it. Every caller of
`buildLink` was affected on Forever: `GetLink`, `Search` rows, suffix links and scoring rows.
`Tests/forever_api_spec.lua` (new) loads the library into a Forever-shaped environment through
`wow.loadAddonFile`'s `env` argument and builds a link; with the old line put back it fails.

### New -- `Search` takes `loose`, a punctuation-insensitive name match (MINOR 37)

Asked for by TOGBankClassic (inbox e860cddb848a): its List Setup tab searches LibItemDB, and the
operator could not find the E'kos (12430-12436) by typing "eko", because `Search` did a plain
substring find on the lowered name. `opts.loose = true` now strips `' - : ,` and folds whitespace
runs on both the query and the name (`looseForm` in `LibItemDB-1.0.lua`). The loose names are
built once into `lib._looseNames` on the first loose search and dropped by `LoadNames`, so the
name-first early-out stays cheap on Mists' 88,259 items. Without the flag the result is unchanged.
Five examples in `Tests/libitemdb_spec.lua` (`opts.loose`) pin both halves and the index rebuild.

### Changed -- six spec assertions that could not fail

Writ's new spec check (inbox 676ec4263aeb) flagged six `is_nil` assertions on a literal key, which
still pass when the literal is misspelled. Each now checks something that can fail:

- `itemdb_spec`: the bare `GetAddOnMetadata` is a counting trap that must never be called.
- `libitemdb_spec`: every library key containing "sell" is listed and compared to the known set.
- `libitemdb_spec`: the whole stored tooltip table stays unchanged after a refused write.
- `libitemdb_spec`: a stand-in `GameTooltip` must receive no lines.
- `price_spec`: the store's realm keys are exactly the player's own scope.

## [v1.1.0] - 2026-09-24

### New -- "Where to get it" on Mists, from SkyFire 5.4.8's world database; Mists stats re-walked

The operator, 2026-09-24, after I had called Mists blocked three times without searching: _"i
think YOU need to do better web research, this data has to be out there"_. It was. The CMaNGOS
projects stop at Wrath, but **SkyFire 5.4.8** publishes a full world database as a GitHub release
(`ProjectSkyfire/SkyFire_548`, tag `sf_db_26`, `SFDB_full_548_26.002_2026_008_18_Release.zip`,
21.6 MB, one 121 MB MySQL dump). Other 5.4.8 cores (Legends-of-Azeroth, PandariaCore) were
checked: none publishes a full dump; Legends-of-Azeroth builds on a local SkyFire copy.

- **`tools/mysqldump-to-sqlite.py`** (new) turns the dump into `tools/cmangos_cache/mistsskyfire.sqlite`
  without a MySQL server: 224,734 creature spawns, 368,727 creature loot rows, 47,208 vendor rows,
  70,934 object spawns, 9,453 conditions. Its value reader is pinned in `item_places_check.py`.
- **`build-item-places.py Mists`**. SkyFire's schema differs from CMaNGOS in four places, each
  detected from the tables rather than keyed on the version: faction is `faction_A`/`faction_H`
  (`creature_sides`); loot conditions are TrinityCore-style rows keyed by loot entry and item,
  ANDed within an `ElseGroup` and ORed across them, with "quest not started" as type 14 where
  CMaNGOS uses 22 (`trinity_loot_tags`; the other type numbers checked against the DB's own
  `Comment` text); `npc_vendor` carries currencies (`type` 2, skipped) and negative items that
  reference another vendor's list (expanded; TrinityCore-lineage behaviour, not verified in
  SkyFire's source); and there is no vendor-template table (`cmangos_vendor_rows` now checks).
  Open-world maps now come from the client's `Map.InstanceType` (0) where the map has zone
  rectangles, instead of the four pre-Cataclysm continents alone, so Pandaria, Deepholm and the
  other later maps place their spawns. Classic and Burning Crusade rebuild to the same counts.
- **SkyFire's Pandaria gathering nodes have no loot link** (`gameobject_template.data1 = 0`):
  36 Mining/Herbalism nodes, among them Ghost Iron Deposit's 265 spawns and Green Tea Leaf's
  287, and no table names Ghost Iron Ore as a node's yield. Searched for a fix upstream and in
  Legends-of-Azeroth's patches; none. A lootless gathering node now yields the item named after
  it (`node_yield_names`: a herb node is its herb, a deposit yields `<name> Ore`, Kyparite and
  Trillium listed), with **no chance** rather than an invented one; 23 of the 36 resolve, and the
  13 that do not are quest or event herbs. An object token with no chance ships as a bare `g<id>`.
- **Built:** `Data/Mists/_core/ItemPlaces.lua`, 25,270 items and 10,215 creatures and objects
  (drops 42,634, of which 843 conditional; vendors 28,102; objects 11,470), plus eight Mists
  `PlaceNames.lua` files borrowing the TBC translations through the rename guard. All nine are in
  `ItemDB_Mists.toc`. Spot-checked: Ghost Iron Ore (72092) lists its Ghost Iron veins besides two
  creature drops and two vendors, and the veins sit in The Jade Forest (155 spawns), Kun-Lai
  Summit, Dread Wastes, Krasarang Wilds and Townlong Steppes with map points. **The first Mists
  build placed them as `@Pandaria:263`**, the whole continent named like an instance: the
  open-world set read the client's `Map` table a second time from `wago_csv`, which returns a
  one-pass `csv.DictReader` already consumed by the line above, so only the four old continents
  counted. Caught by reading the built file; the rows are now read once into a list. Not tried in
  game.
- **Mists gets `ItemLocations.lua` too** (the tooltip's Source line and `GetSources`' quest /
  vendor / crafted / drop / gathered rows): `build-item-sources.py Mists`, 37,228 items (crafted
  5,898, drop 11,046, gathered 864, quest 8,632, reputation 1,579, vendor 12,136, pvp 348), in
  `ItemDB_Mists.toc`. Its SkyFire differences, again detected from the tables: quests hang off
  `creature_queststarter`/`creature_questender` with `Reward*ItemId` columns keyed `Id`; there is
  no `spell_template` (a 5.x server reads the client's DBCs), so crafted items come from the
  client's own `SpellEffect` on wago (`create_item_spells`); skinning is `skinloot`/`type_flags`;
  and the lootless Pandaria nodes use the same `node_yield_names` as the places builder. The
  open-world test and the node rule moved into `itemdb_common` (`open_world_maps`,
  `node_yield_names`) so the two builders cannot disagree; Classic and TBC `ItemLocations.lua`
  rebuild byte-for-byte the same size and `ItemPlaces.lua` to the same counts. Spot-checked:
  Ghost Iron Ore reads Mining, Ghost Iron Bar Mining (smelting), Green Tea Leaf Herbalism,
  Mist-Touched Leather Skinning and Leatherworking. **Known SkyFire gap:** a few creatures that
  are mined or herb-gathered are not flagged so in its data (Vengeful Hui, Quilen Statue, Doom
  Bloom), so Ghost Iron Ore and Green Tea Leaf also read Skinning. Windwool Cloth reads only
  Vendor, because the drop fill only places items nothing else did -- the same rule every version
  uses. **Forever still has no gathering source**: it is Blizzard's own game, releasing November
  2026, with no emulator database, and Wowhead's Forever data is web pages, not a download.
- **Mists item stats re-walked** on the operator's fresh 5.5.4 walk: 88,265 items (6 new), about
  67 Armor and 16 Weapon rows changed. Four new items wago's `Item` table does not know yet went to
  an `Unknown.lua` no TOC loads; `build-core.py` now files such an item under the class the walk
  itself recorded (`parse_walk(..., item_class)`), and that file is gone. `provenance_spec`'s
  list of unstamped files loses `Data/Mists/enUS/Names.lua`, which the rebuild stamped. The other
  Mists languages do not have the 6 new names yet.

### Changed -- harness pin moved to `20453ac`; the changelog's v1.0.0 section archived

**Harness.** WoWAPITesting delivered the FontString fix this workspace asked for (thread
0633f2ae): regions now have `SetScript`, and anything that is not a Button refuses `OnClick` with
the client's message, so the crash the operator hit in the search strip would now go red offline.
The pin moved from `5a75f26` to `20453ac`. The adoption entries in between ask only for stubs to
be deleted for APIs ItemDB does not stub. 755 examples pass on it, with `LibItemDB-1.0.lua`,
`Where.lua`, `Tooltip.lua` and `Price/Window.lua` at 100% line coverage. `where_spec`'s ban on
`RowList:SetColumns` stays: the window uses two lists by design, not as a stand-in.

**Changelog.** The live file reached 119,581 characters, 419 under the 120,000 working ceiling.
The released v1.0.0 section (1,214 lines) moved byte-for-byte to the top of
`CHANGELOG_ARCHIVE.md`, directly above v1.0.0's already-archived earlier entries, so the two halves
now sit together. Both joins were read back and both files lint clean.

### Fixed -- the `/itemdb` Tooltip tab ran past the bottom of the window

Seen in game by the operator, 2026-09-24: _"the tooltip tab extendes beyond the window
borders"_. Nine full-width checkboxes, the icon-size slider and both colour pickers were stacked
in the TabGroup's `List` layout, taller than the 400-px window, so the two pickers were drawn over
the status bar. `buildTooltipTab` now uses two columns: `_PaintPriceWindow` sets the TabGroup to
`Flow` on the Tooltip tab and back to `List` on the others. The checkboxes are
`SetRelativeWidth(0.5)`, and the slider (0.4) shares a row with the two pickers (0.3 each). A new
`pricewindow_spec` example asserts every control's bottom edge sits inside the tab's content
frame. It was red-checked by putting the one-column layout back, which fails that check.
`Price/Window.lua` stays at 100% line coverage. **Verified in game** by the operator, 2026-09-24:
_"tooltip is fine now"_, and a picked colour survives `/reload`: _"the color stays"_.

### Fixed -- a drop the server only gives under a condition read as a plain chance (MINOR 36)

Peer Review, thread f73d04403a2c finding 7: `build-item-places.py` shipped `creature_loot_template`
rows that carry a `condition_id` (2,314 Vanilla, 3,886 TBC, measured) as ordinary chances, so a
Horde-only quest drop or a Blacksmithing plan read as something anyone gets. Measured what the
conditions are before labelling them, by type and by each condition row's own `comments` text:
team (Horde 1,242 / Alliance 147 rows on Vanilla), a profession skill (435 are Blacksmithing), quest
rewarded / taken / not started, a game event or holiday, and a long tail (items carried, auras,
Argent Dawn commissions, AND/OR combinations).

- **Builder:** `condition_code` turns a condition into a short tag -- `A` / `H`, `s<skill line>`,
  `e`, `qd`, `qt`, `qn`, or `c` -- and an AND/OR takes its halves' tag when they agree. A drop
  with a tag ships it as a third field, `d<creature>:<chance>:<tag>` (`drop_token`). No creature
  carries the same item on both a conditional and a plain row (measured, 0 pairs on both DBs), so
  the winning row's tag is the drop's. Pinned in `item_places_check.py` (46 cases).
- **Built:** 407 of Classic's 11,552 shipped drops carry a tag, and 709 of TBC's 13,948. Item and
  place counts are unchanged; the data-shrink check passes.
- **Library:** `GetItemPlaces` rows gain `condition` (`"Alliance"`, `"Horde"`, `"skill"` with
  `conditionSkill`, `"event"`, `"questDone"`, `"questTaken"`, `"questNotStarted"`, `"other"`).
- **Window:** the Chance column reads e.g. `3.0% (Horde)`, `<0.1% (Blacksmithing)`,
  `25.0% (after a quest)`, `5.0% (event)`, `1.0% (conditional)`. The profession is named by
  `C_TradeSkillUI.GetTradeSkillDisplayName`, which every flavour's API docs list, so it reads in
  the client's language; the factions use `FACTION_ALLIANCE` / `FACTION_HORDE`. The other labels
  are English, like the existing `(quest)`. A quest-taken condition on a quest-only drop still
  reads `(quest)` once. The window's "i" explains each label.
- **Faction-only drops follow the faction switch.** With "My faction's vendors" on, a drop tagged
  for the other faction is left out of `BuildWhereRows` along with that faction's vendors. Peer
  Review asked for this over shipping it as a known gap (thread c66dfa1ad14c); pinned in
  `where_spec`. The switch's label still names vendors only.

### New -- translated creature, vendor and node names in "Where to get it" (MINOR 36)

Peer Review, thread f73d04403a2c finding 6: the window showed "Rock Elemental" in "Ödland" on a
German client, because `build-item-places.py` read only `creature_template.Name` and
`gameobject_template.name`. It now also reads the CMaNGOS `locales_creature` and
`locales_gameobject` tables and writes `Data/<V>/<locale>/PlaceNames.lua` for deDE, esES, esMX,
frFR, koKR, ruRU, zhCN and zhTW on Vanilla and TBC (16 files, each guarded on `GetLocale()`,
listed in `ItemDB.toc` and `ItemDB_TBC.toc`). A file holds only names that differ from English.
`lib:LoadPlaceNames` fills `lib.placeName`, and `GetItemPlaces` rows now carry `name` in the
client's language with English as the fallback, plus `englishName`, always English. The
boss-deduplication in `BuildWhereRows` compares `englishName`, because the drop graph's boss names
are English. Coverage on Vanilla, measured from the build: 4,710 of 4,723 entities in Russian.
**Both versions take their translations from the TBC database**: `classicmangos.sqlite`'s locale
tables are empty (0 rows, measured), and entries are the same numbers in both. **A creature or
object TBC renamed would have shown its TBC-era translation on a Classic client.** Measured at
Peer Review's request (thread c66dfa1ad14c): 16 shipped Classic entities, among them Horde Grunt
(TBC: Warsong Grunt), Ghoul (Rotten Ghoul), Draka (Drakan) and six "Alliance Chest"s (Tattered
Chest). `place_name_rows` now drops a translation whenever the translating database's own English
name differs from this version's, so those 16 stay English; each Classic language file lost
exactly 16 rows (ruRU 4,710 -> 4,694). Pinned in `item_places_check.py`.
These 16 files, and the 10 new Mists files (`ItemLocations.lua`, `ItemPlaces.lua` and eight
`PlaceNames.lua`), are NOT yet in `Tests/data_baseline.json`; that file's floors are set with
`--record`, which is the operator's.

### New -- Italian item names on Forever (12 languages)

`tools/build-locales.py Forever --locales itIT` wrote `Data/Forever/itIT/Names.lua`: 17,779 of
19,171 names in Italian and 1,392 (7.3%) English fallback. The guard reported the fallback rate
and wrote the file anyway, as designed, because nothing was on disk to lose. The run exits 1
because the RandomProps step got a 404 from wago for `ItemRandomProperties` at 1.60.1.69913.
That's expected: Forever has no random-suffix table, and no Forever language ships a
RandomProps file. The file is in `ItemDB_Camelot.toc`, and the data-shrink floor now records it
along with the two new `ItemPlaces.lua` files. Those three floor entries were added by hand
rather than with `--record`, which would have re-set every existing floor too.

This waited a day on a blocker I invented: "a builder with arguments needs an approved writ
tool". No law says that. The builder runs in the shell like any build tool.

### New -- the "Where to get it" window, opened by Alt+click or a key binding (MINOR 36)

The operator's design, 2026-09-24: _"use libaceguiwidgets for the UI and lets make it like FGI, a
strip on the top and zebra stripped rows to show the info with columns"_.

- **`Where.lua`** (new, in every TOC after `Price\Window.lua`, and in `toc_spec`'s `CORE_ORDER`).
  It uses LibAceGUIWidgets' ClearFrame for the chrome. A strip across the top of the content holds
  the item's icon and link, a place count, and a text button that switches between "My faction's
  vendors" and "Every vendor". It's built the way FGI's `GUI/Tabs/Scan.lua` builds its strip.
  `W.RowList` sits below on its own area frame, as FGI's `rowsArea` does. Columns: Source, Name,
  Zone, Chance, Spawns. Hovering a row lists its map coordinates. Clicking one calls `WhereTrack`.
- **No timer for the first paint.** My first draft carried the price window's `C_Timer.After(0)`
  refresh, and writ refused it. RowList already hooks its parent's `OnSizeChanged` and refreshes
  when the client first sizes the new frame, so the timer was never needed here. The spec asserts
  that the rows draw on the first open.
- **`BuildWhereRows(id, faction)`** is frame-free and merges `GetItemPlaces` with `GetSources`.
  Boss rows with their rate come first, then place rows, then quest / crafted / reputation / PvP.
  A generic "World Drop" or "Vendor" location row, or a gathering profession an object row
  already names, is not repeated. Forever, which has no places data, still shows them.
- **`WhereTrack(row)`** converts the chosen point with `C_Map.GetWorldPosFromMapPos` and hands
  `{ name, kind, world = { continent, x, y }, location = { zoneName } }` to Questbook's
  `TrackPlace` when that method exists. That's the target shape Questbook's private
  `Tracker:Track` already takes (`Modules/Tracker.lua:115-127`). Requested as contract
  LIBREQ-QB-TRACKPLACE; Questbook has since shipped it (`Questbook/Core.lua:333`) with exactly
  that signature and a boolean return, so no change was needed here. On a Questbook without it,
  clicking a row does nothing and the hover shows no "click to be guided" line. **Verified in
  game** by the operator, 2026-09-24: _"validated tracking is working"_.
- **Stop icon** (`WhereStopTracking`, `_WhereShowStop`): Questbook's own stop, beside the window's
  "i", dressed with `W:DressBottomRow` the way Questbook's `Chrome:Dress` dresses its row, with
  Questbook's texture and its 0.4 idle alpha. Lit while Questbook is guiding, dimmed otherwise,
  and the tooltip reads the state at hover. It is dressed only when Questbook offers a public
  `StopTracking` when the window is built. Requested as LIBREQ-QB-STOPTRACKING (thread
  96906d235c7b) with `IsTracking`; Questbook shipped both under those names (`Questbook/Core.lua:354`
  and `:362`), uncommitted there as of this entry. **Verified in game** by the operator,
  2026-09-24: _"the stop button is there and working"_. The alpha does not follow a stop made
  inside Questbook while this window is open (there is no listener); the tooltip is still right.
- **Search strip** (operator, 2026-09-24: _"add a strip across the top to let you search ItemDB
  for an item too in the popup"_). LibAceGUIWidgets' own `CreateSearchBox` (magnifier,
  placeholder, clear-X) spans a strip across the very top, above the item strip. My first cut
  hand-built an `InputBoxTemplate` box instead, and the operator pointed at the library's.
  Typing three letters, or pressing Enter, calls `WhereSearch`. That runs `lib:Search` on the name
  (any case, capped at 100, "100+ matches" when cut) and shows the results in a **second
  RowList** with Item / Type / Subtype / Level columns, on its own area frame. The two lists'
  area frames are shown and hidden in turn. **My first cut switched one list with
  `RowList:SetColumns`, and it raised on the operator's first search**:
  `FontString:SetScript(): Doesn't have a "OnClick" script` at `LibAceGUIWidgets-RowList.lua:1368`.
  That's a library defect, reported to LibAceGUIWidgets (thread 91e50ebd7ba7). The harness lets
  the call through, so 745 green tests missed it; reported to WoWAPITesting (thread 0633f2ae1eea).
  `where_spec` now fails if either list's `SetColumns` is ever called. Clicking a result opens its
  places. Hovering a result shows the game's own item tooltip. Clearing the box returns to the
  item.
- **`lib:Search` tests the name before unpacking the row.** It used to unpack every item's core
  row first. Measured offline on the real Mists data (88,259 items, plain Lua 5.1): a search that
  misses took ~270 ms and now ~35 ms, and one that fills the 100-row cap went from ~21 ms to
  ~3 ms. The search strip pays this on every keystroke. Same results for every query. Also
  noticed and not changed: when a query hits the cap, which 100 are kept follows `pairs` order,
  and only those are then sorted by name.
- **A boss is not listed twice.** The drop graph's Boss row and the places data's Drop row for
  the same creature collapse to the Boss row. They match on the creature id, which is what the
  drop graph's encounter key is, and fall back to the name (Peer Review, thread f73d04403a2c).
- **Tooltip hint:** the "ItemDB" heading on a material's tooltip now reads `ItemDB (Alt+Click:
  where to get it)`, the hint in grey, while the Alt+click setting is on. `/itemdb where [id,
  link or name]` opens the window from chat, empty when given nothing. `BuildWhereSearchRows` is
  the frame-free half. The search runs on each typed letter from the third on, with no delay,
  because writ refuses a timer; its cost on Mists is measured in the `lib:Search` bullet above.
- **Alt+click:** one `hooksecurefunc("HandleModifiedItemClick", ...)` for the session, guarded so
  a library upgrade reloading the file doesn't hook twice. On Era that function acts on the
  CHATLINK and DRESSUP modifiers only (`ItemButtonTemplate.lua:137-159`), so the default UI gives
  Alt+click on an item no job. It's a new tooltip setting, `altClick`, on by default, with a
  checkbox on the `/itemdb` Tooltip tab. Whether any other installed addon uses Alt+click is not
  verified.
- **Key binding:** a new `Bindings.xml` declares `LIBITEMDB_WHERE`, unbound, under AddOns >
  LibItemDB. It opens the window on whatever item `GameTooltip` is showing (`WhereHovered`).
- The window's position and the faction switch live under a `where` key in `LibItemDB_PriceDB`,
  the library's only SavedVariables table.
- **Tests:** `Tests/where_spec.lua`, 32 examples (the suite went from 704 to 736), covering the row builder, the point picker,
  the Questbook hand-off, the window's geometry and data, the Alt+click gate, the key binding
  and the one-hook guard. `Where.lua`, `Tooltip.lua`, `Price/Window.lua` and
  `LibItemDB-1.0.lua` are all at 100% line coverage. `verify-manifest` is now a declared suite in
  `.writ-suites.json`, because the desk's `run_check` won't pass it its `.` argument.

### New -- `GetItemPlaces`: where to get an item, with zones, chances and map points (MINOR 36)

The first half of the "Where to get it" window. `GetSources` says what KIND of source an item has
(Drop, Vendor, Mining). `GetItemPlaces` says where to go: the creatures that drop it and their
drop chance, the vendors that sell it, and the objects (ore veins, herbs, fishing pools, chests)
that yield it. Each one lists the zones it stands in, with up to three map points per zone.

- **`tools/build-item-places.py`** reads both CMaNGOS databases. Drops use the loot table's own
  rows with `ChanceOrQuestChance`. An equal-chance group row (chance 0 inside a group) gets its
  share of what the group's explicit rows leave. A negative chance ships as negative and the
  library reports it as `questOnly`. Reference-loot rows are not followed for creatures, because
  those are the shared world-drop pools every mob of a level range rolls. Objects do follow them,
  because that is where a node's gems are.
- **Vendors include `npc_vendor_template`.** It is keyed by `creature_template.VendorTemplateId`
  and holds 5,167 TBC rows and 242 Vanilla ones. **`build-item-sources.py` never read it, which is
  my defect.** Measured: 74 items on Vanilla and 1,721 on TBC are sold only through a template,
  and 124 of TBC's shipped location rows (22 on Vanilla) lack the Vendor entry they should have.
  Both builders now read vendors through one shared `itemdb_common.cmangos_vendor_rows`, pinned
  in `item_places_check.py`. `ItemLocations.lua` is rebuilt for Classic and TBC. Reading the
  templates put "Alterac Valley" on common food such as Dalaran Sharp, because a template vendor
  stands inside the battleground. So a battleground vendor place is now dropped whenever ordinary
  vendors also sell the item. That also removed such labels that direct stock had already added:
  Classic vendor rows went from 1,445 to 1,306. The data-shrink check passes, so no item lost its
  last source.
- **Built:** `Data/Vanilla/_core/ItemPlaces.lua` has 6,476 items and 4,723 creatures and objects
  (539 KB). `Data/TBC/_core/ItemPlaces.lua` has 11,157 items and 6,509 creatures and objects
  (775 KB). Both are listed in their TOCs next to `ItemLocations.lua`.
- **Two defects in my first build, caught by reading the file rather than trusting the green
  suite.** First, the separator was written as the Python literal `"\031"`, which is an octal
  escape and so byte 25, not the library's byte 31. Every entity would have decoded as one long
  name. Second, the side came from `EnemyGroup` alone, which marked monsters with an empty
  `EnemyGroup` (Kobold Vermin, Timber Wolf) as friendly to both factions; `FactionGroup` bit 8
  (monster) now means no side. Both are now small functions (`pack_entity`, `lua_literal`,
  `side_of`) pinned in `item_places_check.py`.
- **Zones come from the client's own `UiMapAssignment`**, because `creature_zone` is empty in both
  databases. Neighbouring zones' rectangles overlap at their borders. A spawn in two of them goes
  to the zone that creature's unambiguous spawns use, otherwise to the smaller rectangle (a city
  inside its zone). Coordinates are that zone's 0-100 map coordinates. Measured: Tharynn Bouden
  (creature 66) comes out at Elwynn Forest 41.8, 67.2, her known Goldshire spot. A consumer gets
  world yards from `C_Map.GetWorldPosFromMapPos`, so the handover's open question about whether
  CMaNGOS and Questbook use the same axes no longer arises. The client does the conversion.
- **Faction side** comes from `FactionTemplate.EnemyGroup` bits (1 players, 2 Alliance, 4 Horde).
  Per-faction `Enemies_n` lists are not read, so it can only err toward listing a vendor a side
  can't use.
- `CONTINENTS` and the instance-name aliases moved from `build-item-sources.py` into
  `itemdb_common` as `CONTINENTS` / `INSTANCE_NAME_ALIAS`, because both builders must agree on
  what an instance is and how it's spelled.
- **Tests:** eight new specs in `libitemdb_spec.lua`. `Tests/item_places_check.py` pins the
  conversion on the real Elwynn rectangle and Tharynn Bouden's real spawn. Red-checked by swapping
  the axes, which only that case catches. It also pins the border tie-break, the point thinning and
  the chance format. It's declared in `.writ-suites.json` and CLAUDE.md.

### Fixed -- the reagent tooltip never appeared on Classic Era

The operator hovered Runecloth on Classic Era and saw SmexyMats' lines but none of ours. v1.0.0
shipped the "Used by" line to a client that never drew it, and there were two defects.

**It hooked the wrong mechanism.** `EnableReagentTooltip` registered a
`TooltipDataProcessor.AddTooltipPostCall` because the global exists. When the registration
succeeded, it returned without hooking `OnTooltipSetItem`. Era's UI source does define it
(`TooltipDataHandler.lua:199`). But post-calls run only from
`TooltipDataHandlerMixin:ProcessInfo` (`:298`), which builds a tooltip from a `C_TooltipInfo`
getter (`:251`), and Era's `C_TooltipInfo` has no functions. Era draws bag, link and vendor
tooltips natively, so the registered function was never called. I reasoned from "the function is
defined" to "the behaviour happens", wrote that into the spec as fact, and the spec asserted
exactly one post-call, which pinned the bug as passing. The data-driven path is now taken only
when `C_TooltipInfo.GetBagItem` exists. Otherwise the per-frame `OnTooltipSetItem` hook on
`GameTooltip` / `ItemRefTooltip` is used, the same hook SmexyMats uses. On the data-driven path,
the post-call now passes the item id from `tooltipData.id` instead of resolving a link.

**The same item never got its line twice.** The per-tooltip memory that prevents duplicate lines
was never reset, so hovering the same item again (the tooltip rebuilt from nothing) was refused as
"already added". It is now cleared on `OnTooltipCleared`, hooked once per frame.

**The spec could not have seen either one.** `libitemdb_spec.lua` runs without the widget layer,
so there was no `GameTooltip` when `Tooltip.lua` loaded. The classic hook had nothing
to attach to, and nothing noticed. The file now stages a `GameTooltip` for the load and restores it
afterwards. A file-scope `frames.reset()` was tried first and reverted, because the widget layer
leaked into `pricescan_spec.lua` and broke its AH-button example. The load is now pinned for both
client shapes: Era-shaped (classic hook, no post-call) and data-driven (a single Item post-call
carrying the id). Re-showing the same item and hooking `OnTooltipCleared` once are pinned too.

**Harness pin moved to `5a75f26`.** The harness had the same wrong belief in `env/wow.lua`'s comment.
I reported it (inbox `495fd48f`), and it corrected the comment and added two specs proving that
`SetHyperlink` fires no post-call on the Era shape. The harness's behaviour did not change, so there
was nothing to adopt in code. The whole suite is green against it, with every shipped Lua file at
100%.

### New -- the reagent tooltip says where a material comes from, and the data knows about gathering

This finishes the SmexyMats fold-in. v1.0.0 shipped its "used by" half. Its "sourced from" half
was still missing, even though the operator's 2026-09-22 directive asked for full parity. Checking
the gap turned up a data hole underneath it: `ItemLocations` had no gathering source at all.
Light Leather read only `Crafted`, Copper Ore only `World Drop`, and Peacebloom only `Vendor`.
Mining, Herbalism, Skinning and Fishing were invisible to `GetSources`.

**Data.** `tools/build-item-sources.py` gains `gathered_items()`, which reads the same CMaNGOS DB it
already reads:

- Gathering nodes are `gameobject_template` chests (type 3). The node's lock (`data0`) is resolved
  through the client's wago `Lock` table: a slot with `Type = 2` (a skill key) names a LockType in
  its `_Index`, and LockType 2 is Herbalism and 3 is Mining on both builds read. Lock ids are never
  hard-coded. It is a whitelist of those two LockTypes, because chest locks (Open / Treasure) are
  skill-typed too and would otherwise read as gathering.
- Fishing holes (type 25), `fishing_loot_template` and `skinning_loot_template` are read as well.
- Reference rows (`mincountOrRef < 0`) are expanded recursively, with a cycle guard. That is where
  the gems off a mining node live.

The rows are **additive**, written after the drop fill, so nothing already placed changes. This was
verified against HEAD by parsing both files: 0 non-gathered rows changed, and 0 new items without a
gathered row. Vanilla goes from 8,594 to 8,742 located items (257 gathered). TBC goes from 13,226
to 13,458 (427 gathered). One known imprecision is stated in the builder: the server also uses
`skinning_loot_template` for the few creatures gathered with Herbalism, Mining or Engineering (TBC
motes), so those read `Skinning`.

**Display.** `AddReagentLines` adds `Source: Mining, Skinning, Drop, Vendor` under the Used-by line.
Gathering professions come first, and a boss-graph row reads `Drop`. A kind with no display word is
skipped rather than printed raw. The line appears only on reagents, as SmexyMats did. There is no
new API and no MINOR bump. `GetSources` gains a `gathered` kind, which the README documents for
consumers that switch on `source`.

**The Source line names the profession that MAKES an item, and disenchanting counts.** SmexyMats'
"Source(s)" line named the producing profession, and ours said "Crafted".
`build-item-sources.py` now resolves each create-item spell through the client's
`SkillLineAbility` to the profession that teaches it, using the same `SkillLine.CategoryID` 9/11
rule and `[DNT]` exclusion that `build-reagents.py` uses. The crafted row's location becomes
`Tailoring`, `Blacksmithing`, or `Mining` for smelting. A spell no profession teaches still reads
`Crafted`, but only when no named profession also makes the item. Copper Bar read
"Mining, Crafted" until that rule was added. `disenchant_loot_template` adds `Enchanting` as a
gathered source for dusts, essences and shards. Vanilla now has 538 of 1,668 crafted rows still
generic, and TBC 573 of 2,534. Measured samples: Bolt of Linen `Tailoring`, Copper Bar `Mining`,
Strange Dust `Enchanting`, Light Leather `Leatherworking` + `Skinning`, Runecloth `World Drop`
(which matches SmexyMats' single Drop icon for it). **Consumer-visible:** a crafted row's
`instance` changes from `"Crafted"` to a profession name. Dibs matches crafted gear by kind
(`IsCrafted`), not by that string, so it keeps working and has been told.

**Profession icons, on by default, as SmexyMats drew them (MINOR 35).** Both lines draw professions
and source kinds as game icons at size 20, using SmexyMats' own defaults (`IconsEnabled = true`,
`TooltipIconSize = 20`). Icons are referenced by **file data id**, never by path. Every id was read
from the client's `ManifestInterfaceData` on Vanilla 1.15.9 and TBC 2.5.6 under `Interface\ICONS\`,
and the professions use the textures SmexyMats named. A word with no verified icon (Inscription,
Archaeology, the bare "Crafted") stays a word. Quest, PvP and Reputation have no SmexyMats icon, so
those three are our choice of existing icons. `achievement_pvp_a_01` was rejected because TBC's
manifest lacks it. New `GetTooltipOption(key)` / `SetTooltipOption(key, value)` hold `enabled`,
`icons` and `iconSize` (clamped 8..64). `Is/SetReagentTooltipEnabled` now delegate to `enabled`.
**Caught by the new spec before it shipped:** the first `GetTooltipOption` read the saved settings
through an `a and b` chain. With no saved settings, that chain yields `false`, not `nil`, so every
setting would have read as off on a fresh install, including `enabled`.

**An "Expansion:" line leads the tooltip, as SmexyMats' did (MINOR 35).** New `GetExpansion(itemID)`
and `Data/<Version>/_core/Expansion.lua`, built by the new `tools/build-expansions.py`. The client's
own `ItemSparse.ExpansionID` was measured and rejected: it reads 254 ("unset") for 17,602 of 17,682
Vanilla items and 29,931 of 30,084 TBC items. An item's expansion is instead the first game whose
data ships it. Everything in `Data/Vanilla/_core` is Classic (17,682). A TBC item that Vanilla does
not ship is The Burning Crusade (12,516 of TBC's 30,084). Mists is refused by the builder rather
than guessed, because with no Wrath or Cata item set, everything past TBC is indistinguishable
there. The line uses SmexyMats' colours (Classic `E6CC80`, TBC `1EFF00`) and can be turned off
through the `expansion` setting. The tooltip now follows SmexyMats' order: Expansion, Source,
Used by. Moving Source above Used by is a visible change. The file uses packed strings rather than
`[id]=` rows, and `core_ids()` lists it as a non-item file, so it can never be counted as items.

**An "Item ID:" line on every item, last, as SmexyMats' `ItemIDs` option drew it** (default on,
like SmexyMats). It is the one line not gated on the item being a material, so `AddReagentLines`
now always records the tooltip in its de-duplication memory. It returns true when either the
material lines or the id line was added. **Known overlap, not a defect:** AllTheThings also prints
an Item ID line, so a player running both sees two until they switch ours off with `itemID`.

**A Tooltip tab in `/itemdb`, with SmexyMats' `/sm` switches.** The window gains a third tab. It
has one checkbox per line (all lines, Expansion, Source, Used by, Item ID), one for icons versus
words, and an icon-size slider (8-64) that is disabled while icons are off. Each control writes
through `SetTooltipOption`. The tab is rebuilt on every visit, so it always shows what is stored. A
price event arriving while the tab is open no longer repaints the hidden sources list, and the
deferred first-open refresh now fires only on the Sources tab (it used to fire on anything that was
not Scan). New `source` and `usedBy` settings let each of those lines be switched off on its own.
`Tests/env_price.lua` now loads `Tooltip.lua` in TOC order, so the window spec passes when run
alone. **Not carried over from SmexyMats, on purpose:** the `[SM]` label prefix (its own branding),
its load message and chat error reporting (both about SmexyMats' own internals) and its Reset
button. **Colour-blind mode is carried over.** New `colorblind` setting (default off) and `color1` /
`color2` settings (six hex digits, stored lower-case; anything else is refused). When the mode is
on, every label takes colour #1 and every value colour #2, overriding the expansion's own colour as
SmexyMats did. The Tooltip tab has the switch and two colour pickers, and the pickers stay disabled
until the mode is on. A picker's 0..1 channels are rounded, not truncated, to hex, so a colour is
stored as exactly the colour it will be read back as. All four tooltip lines now go through one
helper that picks their colours, so a line added later cannot miss the mode.

**Our lines open with an "ItemDB" heading, because the operator could not find them.** On Deeprock
Salt they were drawn correctly but sat directly under TSM's block with nothing marking them as
ours: _"i don't see the item DB lines in here"_. The suite's other addons open their block with a
blank line and their name (TOGPM, TOGBankClassic), and SmexyMats prefixed every line with `[SM]`
(its `SMText` option, on by default). The heading is drawn once, only when at least one line
follows, only on a frame that has `AddLine`, and it can be switched off through the new `header`
setting or the Tooltip tab.

**Found in this session's self-audit and fixed.** `PROFESSION_CATEGORIES` was defined in both
`build-reagents.py` and `build-item-sources.py`, and it now lives once in `itemdb_common.py`. If the
two copies had drifted, the tooltip's "Used by" and "Source" lines would disagree about what counts
as a profession. The colour pickers saved only on `OnValueConfirmed`, which AceGUI fires only from
the picker's opacity callback (`AceGUIWidget-ColorPicker.lua:39-40`). These pickers have no opacity,
so a picked colour could be shown and never kept. They now save on `OnValueChanged` too. New
`GetTooltipSwitches()` lets the window spec require a checkbox for every on/off setting, so an option
added to the defaults cannot silently never appear in the window.

**The labels are localised, as SmexyMats' were.** Expansion, Source, Used by and Item ID use
SmexyMats' own translations (its `Locales/*.lua`: deDE, frFR, esES, esMX, ruRU, koKR), and every
other language falls back to English. The expansion NAME is the client's own `EXPANSION_NAME<n>`
string when it has one, read at call time, with English as the fallback. **Not verified:** that the
Classic Era client defines `EXPANSION_NAME0/1`. They were read from the GlobalStrings of the
reference tree, which is not the Era tree, and the English fallback covers their absence. The
profession and source WORDS (words mode, and professions with no icon) are translated too, again
from SmexyMats' tables. Words SmexyMats never translated (First Aid in most languages, Quest, PvP,
Reputation, Crafted) stay English. A spec reloads `Tooltip.lua` under `GetLocale() = "deDE"` and
pins the German lines. The `/itemdb` window's own text stays English, as SmexyMats' options page
did (its `Data/Options/Options.lua` names are hard-coded English).

**SmexyMats' layout, because it is easier to read.** The operator compared the two tooltips side by
side: _"it's easier to people read"_. Every line is now left-aligned. With icons on, Source and
Used by each put the icon row on a line of its own under the label (`SmexyCore.lua:233`, `:246`).
Expansion and Item ID, and every line when icons are off, keep the value on the label's line in
its own colour. A frame with no `AddLine` falls back to the two-column `AddDoubleLine` form.

**A corpse gathered with Herbalism or Mining no longer reads "Skinning".** The server keeps that
loot in `skinning_loot_template` too, and `creature_template.CreatureTypeFlags` says which
profession gathers it. This was verified from the data: on TBC, the 33 creatures flagged `0x100`
(Bog Giant, Underbog Lord) carry Felweed and the other herbs, and the 36 flagged `0x200`
(Shattered Rumbler, Tavarok) carry ore and gems. This replaces the
imprecision stated above. TBC's gathered rows go from 457 to 432, as items that read both Mining and
a wrong Skinning now read Mining only. Classic's database flags no creature this way, so Vanilla is
unchanged. **Deeprock Salt (8150) correctly reads Drop only on Classic, where SmexyMats shows a
Mining pick.** In the Classic CMaNGOS database it comes from creature drops (Rock Elemental, Stone
Fury, Stone Golem, and others, none of them gather-flagged) and from Knot Thimblejack's Cache
(gameobject 179501, a keyed Dire Maul cache). The operator confirmed it in game on 2026-09-24:
_"you can't mine them in classic, so you're data is right then for classic"_. SmexyMats' Mining
comes from its Wowhead-parsed tables (`SmexyCore.lua:2`), which carry later expansions'
mineable-corpse sources. This is a case where parity would have meant copying a wrong answer.

**Scope:** gathering ships for Vanilla and TBC from their CMaNGOS DBs, and for Mists from
SkyFire's (see the Mists section at the top of this release). Forever's sources come from
`build-sources-wowsims.py` (crafted plus chest/object/trash drops), and WoWSims has no gathering
data, so gathering is not shown there.

---

Older releases (v1.0.0 and earlier) are in [CHANGELOG_ARCHIVE.md](CHANGELOG_ARCHIVE.md). Nothing
was edited or dropped, only moved.
