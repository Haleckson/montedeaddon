# Chronicle Forever — Changelog

Release highlights and update notes for Chronicle Forever.

## 1.5.256 — 2026-10-16

- Moved Chronicle's level-up notice below the XP bar and fixed suppression of the overlapping default display. The result was confirmed in game.

## 1.5.255 — 2026-10-14

- Unified the dark interface palette across Chronicle, including buttons, selected rows, and loot groups.
- Improved character counters and equipment details: up to three attributes per item, no armor in item summaries, and melee and spell hit in the statistics panel.
- Recipe clicks now open the matching profession window and select the recipe after it loads; unsupported events no longer interrupt the transition.
- Made initial adjustments to the level-up notice position and default-display handling.

## 1.5.254 — 2026-10-13

- Restored documented loot across 131 boss encounters, completed the City of Dalaran roster, and added verified boss levels.
- Preserved catalog loot, levels, and boss identity when live Encounter Journal data arrives.

## 1.5.253 — 2026-10-13

- Added 205 missing trash-loot assignments across 26 dungeons, deduplicated shared drops, and made loot groups selectable.
- Marked loot without a confirmed wing as complex-wide.

## 1.5.252 — 2026-10-13

- Kept recorded dungeon and raid loot, counts, and quest rewards visible while item names load; unresolved items show their IDs.
- Audited all 35 reference instances for missing boss and trash loot.

## 1.5.251 — 2026-10-13

- Removed loot-source and catalog footers from dungeon and raid pages.

## 1.5.250 — 2026-10-13

- Added verified names and quality colors for documented dungeon drops and instance quest rewards.
- Audited item references without inventing names for unverified IDs.

## 1.5.249 — 2026-10-13

- Grouped boss and All Loot drops by item type, with quality colors, equipment categories, tooltips, and known drop chances.
- Corrected shared-drop counts and sources, and preserved item details when Encounter Journal data arrives.

## 1.5.248 — 2026-10-11

- Added an illustrated class questbook covering 801 quests across nine classes, with chains, rewards, search, and filters.
- Added account-wide equipment and statistics snapshots, journey summaries, and Travel Companions.
- Rebuilt professions, collectibles, rare enemy dossiers, and Settings; expanded dungeon and raid guides.
- Improved item names, quality colors, categories, tooltips, and known drop chances throughout Chronicle.
- Fixed companion data conversion, empty equipment snapshots, and a Lua limit that could prevent the addon from loading.

## 1.5.105 — 2026-10-05

Changes since the last CurseForge release, 1.5.87.

### Dungeon quests

- Audited all 50 recorded quests across seven detailed dungeon guides. Corrected faction assignments and minimum levels where needed.

- Updated quest XP fallback values using the local Forever Dungeon Journal data. Values supplied by the game client take priority.

- Dungeon quest lists and details now display bundled Alliance and Horde emblems. Quests available to both factions show both emblems.

- Dungeons without recorded quest data now say "Quests not yet recorded" instead of showing a misleading zero.

### Goals and Notes

- Rebuilt Goals and Notes with larger writing areas, clearer empty states, and editing controls.

- Saved entries now appear as cards with short previews. A single entry uses the full width; multiple entries use two columns.

- Clicking an entry opens its full text in a separate, movable window. Notes can be edited or deleted there; goals can also be marked complete or reopened.

- Moved the New Note and New Goal buttons beside their collection headings. The writing area opens when needed.

- Refined card spacing, borders, dates, status labels, and Open buttons. The current single-entry cards use a compact action area without overlapping artwork.

- Added localized journal labels and controls in all seven supported interface languages.

### Reliability

- Fixed a Lua local-variable limit error that prevented Chronicle from loading.

- Added a Lua compilation check to release verification and expanded the Goals and Notes interaction checks, including opening entries and handling saved notes after a reload.

## 1.5.65–1.5.87 — 2026-10-03 to 2026-10-04

- Added a map tab to Raid Knowledge for all seven classic raids, with 17 bundled raid map floors.

- Enlarged dungeon maps now open in a separate window with clickable boss portraits at documented locations. Clicking a marker opens that boss's details and loot.

- Reworked the dungeon chapter with a compact header, boss list, and scrollable boss details. Boss portraits now appear in the chapter and in the Dungeons & Bosses history.

- Updated boss portraits, elite and rare frames, level badges, and map markers across Dungeon Knowledge and Raid Knowledge. Boss level colors now reflect the current character level and refresh after leveling up.

- Checked 294 boss levels and classifications against a reference addon. Bosses without a documented level display a question mark instead of a misleading number.

- Added missing dungeon map images and bundled the maps and portrait frames with Chronicle, so the map view works without another addon. The small map explains in all seven supported languages that clicking it opens the larger map.

- Removed loot categories such as trash drops and shared loot from boss encounter lists while keeping their items under All Items.

- Improved item tooltips when live item data is unavailable: catalog names and item IDs appear until the game client provides the full tooltip.

- Made the visited dungeon card more compact and improved the dungeon chapter artwork, including a softer fade that shows more of the image.

- Fixed the minimap button's icon, background, and border for button collection addons.

- Added hover tooltips to profession recipe rows and fixed a Lua error when an empty loot filter is displayed.

## 1.5.45 — 2026-09-30

- Expanded historical access and key routes with the relevant quest chains for Onyxia, Scholomance, Maraudon, Blackrock Depths and other instances.

- Separated Alliance and Horde quest chains and identified alternative quest variants.

- Added readable fallback titles when the client does not return a quest or key name.

- Made the detail window scrollable so every quest in a long chain retains its own map button.

- Added separate historical references for keys and boss summon items that have no quest chain.

Forever access requirements may differ from the historical routes. Personal SavedVariables and Recovery files remain untouched by the update.

## Earlier releases

- Established Chronicle's modular architecture, account-wide character archive, journey timeline, Goals and Notes, quest and zone tracking, NPCs and merchants, dungeons and bosses, loot, inventory and bank records, economy pages, death journal, statistics, and search.

- Added the classic dark WoW-style window with gold trim, sidebar navigation, translations, minimap access, and compatibility handling for available game APIs.

- Expanded dungeon and raid knowledge, maps, boss details, access routes, quest information, and item references through the 1.5 series.

