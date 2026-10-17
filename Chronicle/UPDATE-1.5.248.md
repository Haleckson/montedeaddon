# Chronicle Forever 1.5.248

Changes since 1.5.105, the latest release with an English update post in this project.

## Highlights

- Explore class questlines in a new questbook, with 801 quests across all nine classes, visible rewards, and class-themed artwork.
- View each character's last recorded equipment and statistics from any character on the same account.
- Browse redesigned profession pages, rare enemy dossiers, dungeon and raid guides, and a collectible gallery with rare, epic, and legendary previews.
- See more reliable item names, quality colors, equipment categories, tooltips, and known drop chances throughout Chronicle.
- Configure Chronicle in a clearer Settings menu with visible switches and page controls.

## Class questbook

- Organized class quests into numbered chains and steps. Each step can show its objective, starting and turn-in points, prerequisites, progress, and item or spell rewards. Reward icons open tooltips.
- Checked all 801 class quests against the available quest reference data, including chain order, level requirements, objectives, repeatability, and rewards. Search, race and faction filters, and completed-chain controls make the chapters easier to browse.
- Added nine illustrated class banners with class-colored names and frames. The artwork in an open chapter now follows the selected class. Quest chains and steps can be opened and closed with another click.
- Expanded dungeon and raid quest entries with known level, faction, XP, money, reputation, item rewards, and place in a quest chain. Active quests use text from the player's quest log where available.

## Characters and journey

- Added an account-wide equipment record with all 19 slots arranged around the character. Each character's last recorded gear and captured statistics can be viewed from another character after logging in once with the character being recorded.
- Added quality-colored item names and borders, visible item bonuses, and a statistics panel for health, mana, armor, attributes, combat, and spell values when those values were captured.
- Protected valid equipment records from empty snapshots during loading or logout, and prevented invalid zero-value statistics from replacing saved values.
- Added an account-wide journey summary with links to character, event, and discovered-place pages.
- Added Travel Companions for players met in groups or raids, with meeting history, last known details, shared events, search, and available group actions. Class colors, Chronicle class crests, and an unsaved demo make the companion pages easier to scan.
- Improved the character profile, memory and milestone cards, talent details, shared journey timeline, and level-up notice. Goals and Notes now open from the header instead of appearing twice in the sidebar.

## Professions, collectibles, and rare enemies

- Rebuilt Professions & Recipes around twelve illustrated profession banners, searchable recipes, and recipe details. Available skill thresholds, materials, results, and item tooltips appear when their data has been recorded. Returning from the game's profession window preserves the selected chapter.
- Rebuilt Collectibles as a gallery for recorded rare-quality or better drops. Each dossier can show source, location, time found, description, vendor value, and item tooltip. Epic finds stand out; the unsaved demo now includes rare, epic, and legendary examples plus a Legendary-only filter.
- Added a searchable Rare Database with location and map links, filters, sightings, abilities, models, and known loot. Observed deaths can start a respawn countdown; a new live sighting clears an outdated timer.

## Dungeons, raids, and loot

- Expanded dungeon and raid guides with encounters, maps, access routes, quest lists, and known boss loot. Shared raid drops appear under All Collectibles instead of being assigned to a single boss.
- Checked item displays across encounters, rare enemies, quest rewards, professions, possessions, equipment, collectibles, and boss history. Client item data takes priority; saved links and verified reference data fill gaps while the client is still loading an item.
- Restored known rare drops and consistent quality colors. Loot rows and fallback tooltips show item categories such as “One-Hand Weapon” and “Waist Armor,” plus known equipment slots and vendor values.
- Added known drop chances to item rows and loaded tooltips. Other item tooltips can list up to three known drop sources and their chances. Unknown chances remain unestimated, and actual drops may differ from reference data.
- Removed unresolved imported item IDs from visible boss-loot lists and counts. Fallback tooltips identify their source and clear old text before showing a different item.

## Settings and fixes

- Rebuilt Settings with section navigation, an overview, readable on/off switches, active-function counts, page visibility controls, a rare-level-range selector, and Restore Defaults. The welcome hint has its own switch.
- Fixed a companion guild-sync error caused by multiple API return values reaching `tonumber`. The same safeguard covers group levels and inspected specializations.
- Fixed a Lua local-variable limit that could prevent Chronicle from loading. The minimap button now follows resized minimaps more reliably, and layouts and decorative lines scale more cleanly.

## After updating

Saved account-wide records are retained. Log in once with each character whose current equipment and statistics you want Chronicle to capture.
