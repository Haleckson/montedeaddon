# AllTheThings

## [5.3.15](https://github.com/ATTWoWAddon/AllTheThings/tree/5.3.15) (2026-10-04)
[Full Changelog](https://github.com/ATTWoWAddon/AllTheThings/compare/5.3.14...5.3.15) [Previous Releases](https://github.com/ATTWoWAddon/AllTheThings/releases)

- parse  
- [FOREVER] Added Alther's Mill to Redridge.  
- [FOREVER] Added placeholder data for the City of Dalaran dungeon.  
- Fix a few reported errors  
- [FOREVER] Fixed the name of Excavation Site: Wetlands using the areaID of the same name.  
- [FOREVER] Added Excavation Site: Wetlands. (missing icon and map zone data)  
- [MOP] Fix Theramore's Fall scenario map (#2628) Fixes #1670  
- [Misc] Classic: Note for Crieve to adjust Achievement collection logic (I have no data to test this properly)  
- [FOREVER] Added a couple of things to Ironforge and Loch Modan.  
- [MOP] update celestial bags (#2627)  
    Update with latest data from wowhead  
- more missing timelines added (#2622)  
    * Vanilla stuff  
    * Legendaries  
    * Darkmoon faire  
    * Fishing extravaganza  
- Fixed a bug with the unsorted window if it has nothing in it.  
- Grassy Dunecloth Transmog will be removed half a day before 12.1.5  
- Grassy Dunecloth Transmog is only until October 12th  
- Fixed a bad comment in the last commit  
- [Classic] Fixed a lot of incorrect timelines related to Revantusk Village as part of the corrections to the commit beb7527c16fa9baf4e8fbe53dde00047fc8281ee  
- [FOREVER] Updated Wago DB to 1.60.1.70205. (No changes detected.)  
- [DB] Separate CN Classic/Retail promo content by flavor  
- Regenerate Missing Files for Forever  
- Merge branch 'master' of https://github.com/ATTWoWAddon/AllTheThings  
- Generate Forever Missing Files  
- Merge branch 'master' of https://github.com/ATTWoWAddon/AllTheThings  
- [DB] Blizzard fixed Garsecg  
- Sort recipes  
- Harvest: 1.60.1.70178  
- Harvest: 1.60.1.70170  
- Harvest: 1.60.1.70124  
- Harvest: 1.60.1.70094  
- Harvest: 1.60.1.70058  
- Harvest: 1.60.1.70009  
- Harvest: 1.60.1.69977  
- Harvest: 1.60.1.69913  
- Harvest: 1.60.1.69893  
- Harvest: 1.60.1.69876  
- Harvest: 1.15.9.70003  
- Merge branch 'master' of https://github.com/ATTWoWAddon/AllTheThings  
- Some harvester updates for forever  
- [DB] Fix Thunderhoof Celestial more better  
- Some more prep for Forever missing  
- Reverted some Forever harvesters  
- [DB] Fix Thunderhoof Celestial spellID  
- [Parser] Adjusted debug.config use for consistency  
- [DB] Stop ignoring Parse errors in forever builds  
    * Fixed missing global use of LOWER\_BLACKROCK\_SPIRE (which is actually a custom header) with MAPS.LBRS  
    * Commented sourceQuest 7633 since it doesn't exist in Forever (yet)  
- [DB] Gazillions of new objects in ObjectDB showed up?  
- [Parser] Fixed not capturing DebugDB info for Converted Types (i.e. toyID and others)  
    [Parser] Use no-logging by default for Debug builds to improve time  
- [Parser] Added a Debug build for Forever  
- [Parser] Fixed all the Debug Parser batch files that lost their debug when migrated (probably magic idk :eyes:)  
- [Parser] Fixed Parser using [" "] wrapped string-field table assignments where raw assignment works fine  
    [Parser] Reparsed Retail  
- Adding forever seperate in data harvester  
- [FOREVER] World drops  
- Added some missing timelines (#2621)  
- [FOREVER] Clean-up, field re-ordering and removal of redundant fields  
- [FOREVER] Added the Banner of the Fallen quest.  
- [FOREVER] darkshore  
- Be a bit more realistic  
- [FOREVER] Imported vendor data from the debugger play sessions using AI.  
- [Logic] Removed IsQuestFlaggedCompletedForObject since it isn't utilized anywhere  
- Removed the "Export New" button. AI can take the readable data without much issue and filter accordingly.  
- [FOREVER] Duplicate in ironforge  
- [FOREVER] Added some new loot to BFD.  
- [Tools] Preserve Lua integers (#2618)  
    [Tools] Preserve Lua integer values  
    Keep Int64 values when converting Profession Automator Lua tables so  
    profession, recipe, and category IDs reach the generated output.  
    Verify x64 Debug and Release on Windows with integer and floating-number  
    fixtures, including nested recipes and rank sorting. Integer output now  
    matches the existing floating-number output.  
    Assisted-by: GPT Sol 6.1.  
- removed duplicate meta ach in wrong xpac category, correct one already exists in the BFA list on line 224 (#2619)  
    Co-authored-by: alderwhim <alderwhim@gmail.com>  
- [Parser] Reparsed Retail with fixed default timelines for WOD/LEG  
- [DB] 93466 is account-wide daily  
- [Logic] Adjust expansion filters slightly to allow quick escape on direct awp assignment & ignore the default 10000 awp currently applied on root  
- Removal of obsolete and bugged filter logic, fixes #2609 (#2620)  
    Co-authored-by: alderwhim <alderwhim@gmail.com>  
- [DB] Fixed WOD/LEG expansion-based content literally having the wrong default timeline for the last 2 weeks  
- [FOREVER] Enchanting added  
- [FOREVER] Imported object localization data from my data cache using AI.  
- [FOREVER] Imported object localization data from the play sessions using AI.  
- [FOREVER] Imported data from additional play sessions using AI.  
- [FOREVER] Imported data from Moon's 2nd play session using AI.  
- [FOREVER] Imported data from Moon's play session using AI.  
- [FOREVER] Imported data from Fiamma's play session using AI. Currently training my future replacement...  
- Shifted a number of misaligned fields using AI.  
- Add source quest name comments  
- [FOREVER] Fill gaps in quest metadata and rewards. (#2617)  
    Populate missing requirements, starters, coordinates, and reward entries  
    across 143 existing quests and update the generated database.  
- [FOREVER] Rethban Ore no longer drops outside of the quest.  
- [FOREVER] Fixed the quest giver for Destruction in Deadmines (2/2).  
- Added the "Export New" button for the Debugger. Not sure if it works or the data is wrong.  
- [FOREVER] The dynamite used for 'A Dynamite Plan' has been changed to Rough Dynamite rather than Coarse Dynamite.  
- Add October 2026 Trading Post, timeline out old promos, add new Shop promo, fix some reported errors  
- [FOREVER] Updated Wago DB to 1.60.1.70170.  
- [Classic] [Brewfest] Added objectives to bark quests   
- [FOREVER] Added Gezzy Gunkgear to Stranglethorn Vale.  
- [FOREVER] Added Recipe: Breakfast Omelet to Dire Condors in Redridge Mountains.  
- [Logic] Fixed Export window to work as a Root Command (/att export)  
- [Debug] Adjust PrintTable to accept more intial arguments for preface context  
- [Logic] Skip building a fresh event cache if in combat (Calendar variables seem to be secrets while in combat :clown:)  
- [Logic] Fixed a potential issue if any group defined an OnPopout function which failed to return itself (this use case doesn't exist anywhere in ATT currently)  
- [Logic] Fixed an issue where Global Window settings would not be applied to new popouts, or windows not already defined in a Profile  
- [Logic] Fixed an issue loading ATT when never having any Profiles originally  
- [Logic] Simplify settings.GetWindowSettingsFromProfile (allow the window settings to be copied without the window needing to exist)  
- [Tools] Align x64 tool builds  
    Align Parser and CSVCleaner x64 Debug/Release mappings, temporarily remove x86/Any CPU mappings, and reject unsupported platforms. Isolate their Debug outputs under .tools and include rebuilt Release binaries. Configure CSVCleaner without AOT publishing and ignore Debug output directories.  
    Replace x86 configurations with x64 for ATT Sync Tool, Database and Profession Automator, including existing Classic variants. Update default platforms, remove conflicting Prefer32Bit flags, and correct solution ActiveCfg/Build.0 mappings.  
    Map the shared Any CPU tools to their existing configurations, using Release for Classic/Retail flavors. Align Database output and XML documentation paths and optimize Release/Classic builds with TRACE, no DEBUG, and no debug symbols.  
    Assisted-by: GPT Sol 6.1.  
- [Logic] Minor cleanup  
    [Logic] Moved some saved var table setup to the respective modules  
    [Logic] Character dupe check moved to OnLoad event (removed Faction copy since Factions are fully-refreshed already)  
- [Misc] Some editor settings adjusted based on new paths  
- [Logic] We can keep 'true' unlock values for Artifacts (related #2597)  
- [FOREVER] Finished exploring Riverglades.  
- [FOREVER] Added most of the exploration nodes for the Riverglades and started working on Zephras Isle nodes. Also added objectives and source quests to several of the starting quests.  
    [FOREVER] Removed all HQTs from the mainline expansions.  
- [FOREVER] Moved the Black Market Auction House to Expansion Features so that it can be given a root timeline.  
- [FOREVER] Added Shal'ma to Durotar.  
- [FOREVER] Added placeholder data for the Black Market Auction House.  
- [FOREVER] Added vendors to the Riverglades.  
- [FOREVER] Added a placeholder structure for engineering.  
- [FOREVER] Added Miranda Turner and Paige Armstrong to the Riverglades.  
    Added Tumi to pre-cata Orgrimmar.  
- [FOREVER] Added the Brotherhood of the Horse faction.  
- [FOREVER] Updated more coordinates for Redridge.  
- Added the Boot Knife to World Drops.  
- [FOREVER] Added Captain Sander's Locker to the Captain Sanders' Hidden Treasure quest chain.  
- Adjusted Lonebrow's Journal to use qs/qi/treasures.  
    [FOREVER] Moved Razorfen Kraul to the forever database and added a bunch of new items.  
    [FOREVER] Added the loot added to the Alliance Outrunners in the Barrens.  
- Patch 12.1.5 launches on October 13th  
- Updated ALL\_GNOMISH\_ENGINEERING with cata/mop gnomish engineering (#2610)  
    Gnomish cata/mop items to all gnomish engineering, Oglethorpe list now correct  
    Co-authored-by: alderwhim <alderwhim@gmail.com>  
- [FOREVER]: Newlines  
- PTR: Parse  
- PTR: Update Wago  
- [FOREVER] Added the Baby Crocolisk and Excitable Slime pets.  
- [Git] Remove obsolete Parser ignore rules  
    Remove seven ignore entries for the retired .contrib/Parser/ directory.  
    Assisted-by: GPT Sol 6.  
- [FOREVER] Updated Wago DB to 1.60.1.70124 (no changes). Added objectIDs for the Stolen Weapons objective.  
- [FOREVER] Moved redridge mountains into the forever database.  
- [FOREVER] Added the Nightclaw Mantle and a couple quests to Elwynn Forest.  
- [Tools] Define tools modernization targets  
    Document the modernization plan for ATT contributor tooling.  
    - Define .NET 8 as the migration baseline, with migration targeted for completion by October 10, 2026, one month before .NET 8 reaches end of support.  
    - Define .NET 10 as the next-generation framework target after the initial migration is complete.  
    - Establish the supported desktop platform matrix:  
      - Windows x86, x64, and ARM64  
      - Linux x64 and ARM64  
      - macOS x64 and ARM64  
    - Consolidate maintained tool source code under `.contrib/src/`.  
    - Define shared build configuration and dedicated build/publish artifact locations.  
    - Require RID-aware handling of platform-specific and native dependencies.  
    - Document the planned phase-out of `.contrib/.tools/` as a combined source, dependency, and binary output directory.  
    - Identify ATT Sync Tool and Database as temporarily excluded from the cross-platform requirement due to their Windows-specific dependencies.  
    - Document platforms and runtime targets that are intentionally outside the supported desktop matrix.  
    AI-assisted: This documentation was drafted and refined with the assistance of ChatGPT.  
- [FOREVER] Added the Matriarch Bristlefur to Elwynn Forest.  
- [FOREVER] Moved the world events to their own folder and commented them out for future reference. There's no guarantee these events will happen in this version of the game, but when/if they do, this data will be available to work with and update.  
- Removed some leftover phase assignments. (Phase selection isn't supported in Forever.)  
- [Parser] Remove Debug symbols from Release parser & rebuild solution  
- Timelined and commented out some blacksmithing recipes  
- Added Merchants Favor Recipes to structure  
- Added Discolored Potions  
- [FOREVER] Updated Forever's Wago DB to build 1.60.1.70094.  
- Cleaned up Forever release  
- Cleaned up some blacksmithing structure  
- Fix a few reported errors  
- [FOREVER] Blacksmithing updated  
- Fixed the itemID assignments for the "Honorary Brewer" Hand Stamp.  
- [Logic] Small improvement to Legion Artifact refresh logic (~15% speed increase) (related #2597)  
- Bump wago MoP files to 5.5.4.70032  
- [FOREVER] Updated the report message localization string to direct reports to the correct channel.  
- [Logic] Artifact caching improvements (~200% faster refresh check) (related #2597)  
- [FOREVER] More icons for dungeons  
- [FOREVER] Finished Categorizing Crafted Items. (These files will likely be significantly alterred for Forever eventually.)  
- [FOREVER] Moved the crafted items added with Phase 5 (which happened before AQ in Classic) to their own file.  
- Dreamscale is from the world dragons or from ST after 10.1.5. No need for the description or the data in Crafted Items.  
- [FOREVER] Moved the crafted items added before Phase 6 for Catch Up in Phase 5 to their own file.  
- [FOREVER] Moved the crafted items added with Phase 3 (which happened somewhere between BWL and ZG in Classic) to their own file.  
- [FOREVER] Moved the crafted items added with Naxxramas to their own file.  
- Removed Primal Bat Leather and Primal Tiger Leather from Crafted Items. (If its sourced in the raid, then that's the only place it needs to exist...)  
- [FOREVER] Moved the crafted items added with Dire Maul and AQ to their own files.  
- [FOREVER] Arclight Spanner is not collectible yet.  
- [FOREVER] Working on changing crafted items to segregate data based on the release for BWL and ZG. Also stripped out a bunch of unnecessary timeline data for this environment.  
- [VSC] restore library path.  
- [VSC] Update DBs path for new struct.  
- [FOREVER] Working on changing crafted items to segregate data based on the release.  
- [Anniversary] brewfest fixes  
    Brew of the Month" Club Membership Form items source are the same of retail  
    Now This is Ram Racing... Almost objectives added  
- Removed the SavedVariable Shenanigans.  
- specific mobs drop specific bots  
- Deleted the GlobalStrings file. Please use https://www.townlong-yak.com/framexml/live/Helix/GlobalStrings.lua instead for a more up-to-date and relevant version of this file if necessary.  
- Deleted the unused Localization Converter tool. (It was used one time to build the localization structures, running it a second time would probably be a bad idea)  
- Last trace of PAT.  
- Goodbye, PAT. Hello, Claude Code & Copilot.  
- Updated CSVCleaner.exe to build into the .tools folder.  
    Updated all wago build tools to always use the downloadcleaned function when cleaning using the tool.  
- Deleted the unused Build Tool. (We use a GitHub Action now, don't want anyone to accidentally run this)  
- [Retail] Remaining Quel'Thalas QI conversions  
- Migrate datas to standard (#2604)  
    * Converted tools to reference the new .db/standard folder.  
    * Moved /DATAS to .db/standard  
    * Migrated all build batch files into the .db/standard folder.  
    Migrated all wago files into the .db/standard folder.  
    Migrated all lib files into the .db/shared/lib folder (temporarily)  
    * Deleted an unused batch file.  
    * Updated workflows paths.  
    * [DB] Rebuilt all dbs using new build scripts.  
    * Moved the build batch files up one level into the root .db folder based on a suggestion to keep the data itself separate from the build tools.  
    * Renamed the + debug mode batch files to "debug - " rather than "build - " so there's less confusion as to what it does  
- Revert "[Parser] Align x64 builds"  
- Clean-up: Newlines, Tabs, etc  
- [Parser] Align x64 builds  
    Use x64 for this first build configuration. Keep Parser Release in .contrib/Parser and put Debug in .contrib/Parser/Debug with its native Lua DLL. Preserve CSVCleaner output paths and ignore generated Parser Debug files.  
    Remove redundant project settings while retaining the application icon and RETAIL define. Omit Release debug symbols and include rebuilt Release executables with their runtime files.  
    Validated Debug|x64 and Release|x64 solution builds on the Windows VM. Parser Retail exited 0 in both configurations and produced identical Lua output. CSVCleaner samples exited 0 and retained only matching rows.  
    Assisted-by: GPT Sol 6.  
- [DB] Added TODO note for Love in the Air adjustment  
    [DB] Fix a parser warning on a coord  
- [DB] Some ObjectDB updates  
- [DB] Moved some HQTs to Prey file (still not 100% on what they represent)  
- [Logic] inaccurate-quest report now always uses the "Quest" report type (the object type is already added to report data as 'type')  
    [Logic] 'Quest' report types now include the player's current map name in the report title to help aid in searching for reports  
- Shifted around some database files to prevent retail data from polluting the flight path map IDs and likewise.  
    [FOREVER] Added flight path map IDs and more coordinate adjustments for redridge.  
    [SOD] Moved the FOR\_CRAFTER Update function to a more appropriate location.  
- [Parser] Fix item count  
    The previous counter incremented before ConcurrentDictionary.GetOrAdd.  
    Parallel callers could lose increments or count duplicate insert attempts.  
    Read the dictionary count after processing instead.  
    Rebuild Parser.exe with the master Parser.sln Release|x86 configuration  
    (which targets x64). Two isolated Windows Retail parses both exited 0,  
    reported 188,207 items, and produced byte-identical db/Standard output.  
    Assisted-by: GPT Sol 6.  
- [FOREVER] Adjusted a bunch of redridge coordinates. Objects that don't use bracket notation have updated coordinates. Objects that still have them need to be adjusted.  
- Update World Quests.lua  
    Missing WQ  
- Battle Pets now track correctly in Forever.  
- [FOREVER] Westfall Chicken is actually "Prairie Chicken" in this game flavor.  
    Turned on the Retail Mount & Battle Pets handlers.  
- [Parser] (non-Forever) SelfAutoTable is now a global defined in shared .main.lua  
    [Parser] MAP (non-Forever) uses a slightly-different setup to allow for auto-keyed grouping (we have too many .main.lua files)  
    [Parser] MAP auto-key self-metatable no longer triggers the unknown Global metatable check error  
    [Parser] Using a non-existent MAP as an actual mapID will still result in a parser ERROR since it will now receive an empty table instead of an assigned numeric value. Either way, contrib needs to fix :)  
    [Parser] Rebuild as Release so it's no so gigaslow  
- Moved some database modules to the shared db folder.  
    [FOREVER] Pets, Toys, and Mounts in Forever should now correctly be marked as such.  
- [FOREVER] Added some quests started by drops to Elwynn Forest.  
- [FOREVER] Added some Stormwind City quests.  
- [Parser] Now supports object harvesting from wowhead for forever. (if wowhead had the object data to begin with, which it doesn't currently.)  
- [FOREVER] Updated Gnomeregan. (Loot tables not yet known.)  
- [Contrib] Ignore Object checks on Things linked to those Objects which are not Objects themselves  
- [FOREVER] Added the Shipping Label quests.  
- [FOREVER] Reviewed and cleaned up a good portion of the log.txt file's reports.  
- Fix a few reported errors  
- Move of dark iron mole machine location list (#2595)  
    Dark iron mole machine list moved to allied races  
    Co-authored-by: alderwhim <alderwhim@gmail.com>  
- [FOREVER] Added the mount vendor Genn Fairweather to Zephras Isle (#2603)  
    [FOREVER] Added the mount vendor Genn Fairweather to Zephras Isle.  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Added the Pitted Defias Shortsword and Sharpened Cirrusfly Stinger as drops in Zephras Isle (#2599)  
    * [FOREVER] Added the Pitted Defias Shortsword and Sharpened Cirrusfly Stinger as drops in Zephras Isle.  
    * [FOREVER] Set the 1.60.1 timeline on the Sharpened Cirrusfly Stinger.  
    ---------  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Added Janna Brightmoon as a vendor in Shadowglen (#2602)  
    [FOREVER] Added Janna Brightmoon as a vendor in Shadowglen.  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Added the Fang of Githyiss, Nature's Call and The Goddess Provides quests in Shadowglen (#2601)  
    [FOREVER] Added the Fang of Githyiss, Nature's Call and The Goddess Provides quests in Shadowglen.  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Added Andiss, Freja Nightwing, Keina and Khardan Proudblade as vendors in Shadowglen (#2600)  
    [FOREVER] Added Andiss, Freja Nightwing, Keina and Khardan Proudblade as vendors in Shadowglen.  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- The MAP global now has a metatable that grabs the global mapID if it is ever referenced.  
- Misc. fixes  
    * Fix Parse to no Forever flavors  
    * [Vanilla] Fixed A Collection of Heads (8201)  
    * [Forever] SoD removed from Zul'gurub file  
- Added Crisp Spider Meat as a World Drop.  
- Added Spider Ichor as a World Drop.  
- [FOREVER] Added Brother Zendraas as a vendor in Zephras Isle (#2593)  
    * [FOREVER] Added Destin Thriceforged, Fevrath Skyhammer and Jolee Brightmeadows as vendors in Zephras Isle.  
    * [FOREVER] Added the Zephrali gear vendors in Valanaar, Zephras Isle.  
    * [FOREVER] Added Brother Zendraas as a vendor in Zephras Isle.  
    ---------  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Sourced the Chainmail set on Mangorn Flinthammer and added two patterns to Bombus Finespindle in Ironforge (#2589)  
    [FOREVER] Sourced the Chainmail set on Mangorn Flinthammer and added two patterns to Bombus Finespindle in Ironforge.  
    Co-authored-by: AlisterGreg <16710508+AlisterGreg@users.noreply.github.com>  
- [FOREVER] Fix Zephras Isle quest requirements (#2592)  