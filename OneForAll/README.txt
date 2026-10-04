OneForAll
=========

Standalone WoW Forever companion addon: dungeons (bosses, loot, quests),
Library Books tracker, Mage Comprehension scrolls, Merchant's Favor recipes,
camping buffs and an in-addon talent planner. No other addons are required.

Commands
--------
/oneforall or /ofa       Open/close the addon
/oneforall debug         Show unverified Library Book quest flags
/oneforall bank          Explain bank scanning
/oneforall profdata      Show embedded profession-data status
/oneforall portraits     Show which source each boss portrait came from
/oneforall where         Print the current map and coordinates (to report wrong map pins)
/oneforall reset         Reset manual Library Book marks
/oneforall tabs reset    Show the default tabs again for this character
/oneforall share test    Preview the quest share popup without a group
/oneforall share         Open the quest share popup (inside a dungeon, in a group)
/oneforall talentdump    Save all talent IDs to the SavedVariables (for the addon author)
/oneforall scale [n]     Set the window size (60-140 or 0.6-1.4); without a value: reset to 100 %

Third-party data attribution is in THIRD_PARTY_LICENSES.txt.
Dungeon data sources are listed in DUNGEON_DATA_SOURCES.txt.


Code layout
-----------
Data files       Data.lua, ExtraData.lua, ProfessionData.lua, DungeonData.lua
Dungeons         Data/Dungeons/<Name>.lua - one file per dungeon (quests, bosses, loot);
                 Data/DungeonQuestChains.lua - prerequisite chains (optional = true marks
                 lead-ins that do not block); DungeonData.lua - entrance, territory,
                 level sorting. New dungeon: add a file, list it in OneForAll.toc,
                 add its META entry in DungeonData.lua and its art in UI/Dungeons.lua.
Logic            Core.lua (events, bags/bank, slash commands), ProfessionRuntime.lua,
                 Map.lua (world-map pin), Proximity.lua (nearby book alerts), Minimap.lua
UI/Widgets.lua   Shared buttons/textures/banners + panel registry
UI/MainFrame.lua Main window and tab bar
UI/<Tab>.lua     One file per tab: General, Dungeons (+ DungeonHelpers, DungeonPortraits),
                 Books, Mage, Professions
Talents          TalentData.lua (layouts of all 9 classes), TalentSpellIDs.lua (spell ID ->
                 talent name; regenerate from /ofa talentdump after a talent patch), TalentPlanner.lua (the tab), TalentLayoutFallback.lua
                 (only used if the client talents cannot be matched to TalentData.lua)
New tab: create a file, call FLT.UI.RegisterPanel{key=, label=, order=, tabWidth=, create=}
and add the file to OneForAll.toc before UI\MainFrame.lua.


Changelog (newest first)
========================

4.17.7 - fix
------------------------------------------------------------
- Fixed a Lua error when a pet ability alert appeared.

4.17.6 - target button
------------------------------------------------------------
- Pet ability alert: "Mark" (raid marking is protected on this client and caused
  an error) is replaced by "Target", which targets the beast. Not available
  while in combat.

4.17.5 - pet alert buttons
------------------------------------------------------------
- Pet ability alert: "Mark" puts a skull on the beast, "Snooze 15 min" pauses
  pet alerts, "Ignore <ability>" excludes the ability. No map/dismiss buttons
  (close with the X).
- Alerts stay open for 20 seconds before closing automatically.

4.17.4 - portrait frames
------------------------------------------------------------
- Boss portraits get a gold frame that runs into a point at the bottom right
  (like the player frame); the large portrait shows the boss level in a badge.
- Hunter Pets: round gold ring for families, action-bar style rounded icon frame for abilities.

4.17.3 - pet alert exceptions
------------------------------------------------------------
- Pet ability alerts: abilities can be excluded. Untick "Alert for this ability"
  in Hunter Pets > Abilities, or click "Ignore <ability>" on the alert itself.
  Cower is excluded by default. Excluded abilities show "(no alert)" in the list.

4.17.2 - round pet portraits
------------------------------------------------------------
- Hunter Pets: the large family and ability portraits are round, like the boss
  portraits.

4.17.1 - layout polish
------------------------------------------------------------
- Boss list: the level line lines up exactly under the boss name.
- Hunter Pets: families and abilities show a large portrait/icon with the name
  next to it.

4.17.0 - dungeon quality of life
------------------------------------------------------------
- Opening the window inside a dungeon jumps straight to that dungeon's bosses
  and loot.
- Boss level shown below the boss name and in the boss header. Levels of
  Forever-only bosses are learned when you target or mouse over them.
- Boss portraits that the game resolved once are saved, so they no longer
  disappear in later sessions.

4.16.4 - abilities list
------------------------------------------------------------
- Hunter Pets > Abilities only lists abilities learned from tameable beasts.
  Pet Trainer skills (Growl, resistances, Great Stamina, ...) are shown on
  each family instead.

4.16.3 - logo centered
------------------------------------------------------------
- Minimap logo: the "1" is now exactly centered.

4.16.2 - bolder logo
------------------------------------------------------------
- Minimap logo: thicker "1" that stays readable at minimap size.

4.16.1 - new logo, settings groups
------------------------------------------------------------
- New minimap button logo (golden "1"); also used as the icon in the addon list.
- Settings: popups and alerts have their own "Popups & alerts" group.

4.16.0 - pet ability alerts
------------------------------------------------------------
- Hunter: alert when a beast nearby (nameplate, target or mouseover) teaches a
  higher ability rank than you know, for an ability your active or stabled pet's
  family can learn. Same popup style as the library book alerts, with a Map
  button. Toggle: Settings > General > "Pet ability alerts (Hunter)".

4.15.0 - your pets
------------------------------------------------------------
- Hunter Pets: the family of your active pet is marked green ("Your pet") and
  selected when you open the tab; the detail view shows its name and level.
- Stabled pets are marked blue ("In stable"). The list is updated whenever you
  open the stable master window.

4.14.2 - pet ability scan fix
------------------------------------------------------------
- Hunter Pets: known ranks are read from the pet spellbook with the client's
  modern spellbook API, so your pet's abilities are marked green. Also scanned
  when you open the tab. /ofa petscan prints what was found.

4.14.1 - quest share fix
------------------------------------------------------------
- Fixed: the quest share window kept reopening in dungeons and ignored the
  "open automatically" setting. It now opens automatically at most once per
  dungeon visit (and again only when a new member joins), never when the option
  is off, and stays closed after you close it. /ofa share still opens it.
- Group members only send their quest status when it actually changes.

4.14.0 - known pet abilities
------------------------------------------------------------
- Hunter Pets: OneForAll reads your known pet ability ranks from the Beast
  Training window (open it once) and from your pet's spellbook. Learned ranks
  are green; knowing a higher rank also marks all lower ranks. The ability list
  shows e.g. "3/8 learned".
- Abilities: each rank is a row you can click to fold out the beasts that teach
  it, instead of one long list.

4.13.2 - fix
------------------------------------------------------------
- Fixed a Lua error when scaling the window with the corner grip.

4.13.1 - clickable section headers
------------------------------------------------------------
- Dungeons (level brackets) and Library Books (sets): click anywhere on the
  header bar to collapse or expand it, not only on the +/- button.

4.13.0 - adjustable window height
------------------------------------------------------------
- New grip in the middle of the bottom edge: drag it to make the window taller
  (lists and detail panes show more rows). The corner grip still scales the
  whole window. The height is saved; /ofa scale resets size, height and position.

4.12.7 - compact quest details
------------------------------------------------------------
- Quest details hide the "Prerequisite" and "Turn in" lines when there is no
  information (the quest chain already shows required steps).

4.12.6 - reward layout
------------------------------------------------------------
- Follow-up rewards and the XP/reputation line under quest rewards are
  left-aligned like the other rewards (they were centered).

4.12.5 - steady tooltip position
------------------------------------------------------------
- Item tooltips open right after the item name (or left of the row if there is
  no room), no matter where the mouse enters the row.

4.12.4 - comparison tooltips
------------------------------------------------------------
- The game's "Equipped" comparison tooltips stay on the same side as the loot
  tooltip (right of the mouse, or left if there is no room), so they no longer
  cover the loot list.

4.12.3 - tooltip position
------------------------------------------------------------
- Item tooltips (boss loot, trash, quest rewards) open next to the mouse instead
  of at the far right edge of the row.

4.12.2 - pet ability fixes
------------------------------------------------------------
- Hunter Pets: Forever-only abilities without a known teaching beast show one
  note instead of repeating it for every rank.
- Fixed missing closing bracket on dungeon beasts, e.g. "Scarlet Monastery (Dungeon)".

4.12.1 - quest chain progress
------------------------------------------------------------
- Dungeon quest list: a quest counts as "In log" while you are on an earlier
  step of its chain and shows the step, e.g. "Chain 1/3".
- Quest chain: the last row is labelled "Dungeon quest" instead of "Current".

4.12.0 - Forever loot, Dalaran quests and Forever pets
------------------------------------------------------------
- Dungeon loot updated from wowtbc.gg (Forever loot tables): The Stockade bosses
  now have their real Forever drops instead of "world drops only"; more drops for
  Excavation Site, Blackfathom Deeps, Shadowfang Keep and Gnomeregan; trash loot
  lists for Stockade, BFD, SFK, Deadmines, Gnomeregan and SM Graveyard; event
  bosses Sever (SFK) and Scorn (SM Graveyard).
- City of Dalaran: 5 quests (A Green Sample, Power Overwhelming, The Grave Knight,
  Source of Power, Opportunistic Education); "Mana Elemental" is Arcanic Enigma.
- New quests: Baron Aquanis (BFD, Horde), In Nightmares (WC, both factions),
  The Test of Righteousness (Paladin, DM/SFK/BFD).
- Class-only dungeon quests (e.g. The Orb of Soran'ruk) are only counted for
  that class.
- Hunter Pets: data switched to WoW Forever (wow-petopia.com/forever). New family
  abilities (e.g. Dismember, Savage Rend, Web, Swipe, Pinch), Demoralizing
  Screech replaces Screech, new trainer passives Faster/Slower Attack, Owls are
  now Birds of Prey, Core Hounds and Foxes added. Every rank shows its effect.
- Dungeons: quests in shared-name chains (e.g. Hidden Enemies) are matched by
  quest ID, so the wrong chain step no longer shows as "In log"; the quest chain
  marks the step you currently have.

4.11.0 - level-30 beta update
------------------------------------------------------------
- Excavation Site: 14 quests (Alliance and Horde, incl. chains and rewards) and
  the first recorded boss drops. Some quest givers are not on Wowhead yet.
- Library Books: the rewards window shows all three reward tiers with the real
  items and tooltips (10 books: necklace, 20: ring, new third tier: bow / shield /
  off-hand). Values updated to the current beta (weaker necklaces, ilvl 35 rings).
- Professions: Merchant's Favor overview redesigned - steps, trade hub and the
  crate reward table fit on one page without the small scroll box.

4.10.5 - talent update (beta build 70170)
------------------------------------------------------------
- Talent trees updated to beta build 1.60.1.70170:
  Druid Feral: new Shifting Power and Improved Shifting Power, King of the Jungle
  removed, Shredding Attacks and Predatory Instincts moved.
  Mage: Hot Streak renamed to Heating Up. Warlock: Soul Harvesting renamed to Soul Harvest.

4.10.4 - Hunter Pets banner
------------------------------------------------------------
- The Hunter Pets tab has its own banner.

4.10.3 - map pin
------------------------------------------------------------
- Map pin is now the plain gold variant and a bit smaller.

4.10.2 - title and map pin
------------------------------------------------------------
- Window title shows "made by Smoergi".
- New, simpler map pin (dark with gold rim) that matches the addon style.

4.10.1 - quest share test
------------------------------------------------------------
- /ofa share test opens the quest share popup with two made-up group members,
  outside a group too. Share only shows a local preview of the emote and fakes
  the replies; nothing is shared or posted.

4.10.0 - Settings tab
------------------------------------------------------------
- New Settings tab (gear icon, far left; the window still opens on General):
  shown tabs, dungeon level brackets to show/hide, welcome message, nearby book
  alerts, quest share popup and emote, window reset.
- Welcome message now also invites feedback on CurseForge; can be turned off.
- Tab checkboxes moved from the General tab to Settings.

4.9.0 - Hunter Pets tab
------------------------------------------------------------
- New tab "Hunter Pets" (shown by default on hunters):
  Families - diet, stat modifiers, learnable abilities and where to tame them;
  Abilities - every rank with pet level, training points and beasts that teach
  it (Map button); Rare Tames - notable rare/unique-looking pets.
- Data: Classic pet rules (no Forever pet changes known so far), compiled from
  wow-petopia.com/classic and Wowhead Classic, spawn points from QuestieDB.

4.8.0 - choose your tabs
------------------------------------------------------------
- Every module has a "Show tab" checkbox (now in the Settings tab). The choice is saved per
  character; hidden tabs disappear from the tab bar.
- Mage Scrolls is shown by default only on mages. /ofa tabs reset restores the
  defaults.

4.7.0 - quest sharing in dungeons
------------------------------------------------------------
- Inside a dungeon, a popup lists your shareable quests of that dungeon that a
  group member does not have yet and can take (level/faction checked). One click
  shares the quest and posts an emote, e.g.
  "Kaelin shares the quest "Crime and Punishment" with Anna (OneForAll addon)".
- The game's replies (accepted, already completed, not eligible, too far ...)
  are shown in the popup; players who completed a quest are not offered again.
- Group members with OneForAll exchange which dungeon quests they completed.
- /ofa share opens the popup manually; /ofa share off|on and
  /ofa share emote off|on change the settings (also as checkboxes in the popup).

4.6.3 - boss list width
------------------------------------------------------------
- Boss list now has the same width as the quest list, so switching between
  Bosses & Loot and Quests keeps the layout steady.

4.6.2 - dungeon art and boss list
------------------------------------------------------------
- Simpler thumbnails for Excavation Site, City of Dalaran, Gnomeregan and
  SM: Graveyard (closer to the style of the original dungeon images).
- Wider boss list in the dungeon view.

4.6.1 - talent tooltips
------------------------------------------------------------
- Talent tooltips show the description on the first hover: if the client has
  not loaded the talent's spell data yet, it is loaded and the tooltip redrawn.

4.6.0 - language-independent talent planner
------------------------------------------------------------
- Talent planner matches client talents by spell ID (new TalentSpellIDs.lua,
  read from build 70124 with /ofa talentdump) and only falls back to names.
  It now uses the fixed layouts on German, French, Spanish and other clients too.
- All 466 reference talents of the 9 classes were confirmed against the client.

4.5.1 - talent dump
------------------------------------------------------------
- New command /ofa talentdump: saves node, entry and spell IDs of all talents of
  all classes (preparation for a language-independent talent planner).

4.5.0 - scalable window
------------------------------------------------------------
- The main window can be resized with the grip in the bottom-right corner
  (60-140 %). Size and position are remembered; /ofa scale resets them,
  /ofa scale 80 sets a size directly.
- Four Forever enchanting recipes now require skill 300 (Classic cap).

4.4.1 - dungeon list polish
------------------------------------------------------------
- Zone column and dungeon header show only the zone; coordinates are left to
  the Map button.
- Boss loot tooltips refresh automatically once the client has loaded the item
  (no more stuck "Retrieving item information").
- Stockade bosses without own loot say so; Kam's Walking Stick added.
- City of Dalaran bosses use fixed model IDs for their portraits.

4.4.0 - dungeons up to level 38
------------------------------------------------------------
- New dungeons: The Stockade, Gnomeregan, Scarlet Monastery: Graveyard (Forever
  quests and boss loot from Wowhead Forever), Excavation Site: Wetlands and City of
  Dalaran (boss lists only - loot and quests are not published yet).
- Dungeon list is grouped into collapsible level brackets like Library Books,
  with an "Only dungeons for my level" filter and level colors for your character.
- Level ranges now use the WoW Forever recommended ranges for all dungeons.
- Quest chains: optional lead-in quests are shown as "Optional" and no longer
  block a quest. Fixed Researching the Corruption, Returning the Lost Satchel,
  Allegiance to the Old Gods and Destruction in Deadmines (which blocked itself).
- Gnomeregan Horde quests count for Horde characters.
- Dungeon data split into one file per dungeon.

4.3.1 - talent data, per-character books, map pin check
------------------------------------------------------------
- Talent planner: all 9 classes now use fixed layouts from talentsforever.com
  (build 1.60.1.70009) for tree, row, column and prerequisites instead of guessing
  them from client coordinates. The client still provides icons, tooltips and IDs.
  If client talents are missing from the data, the footer says so; if nothing
  matches (e.g. a localized client), the old estimated layout is used.
- Talent planner: same-row prerequisites are drawn correctly; trees that use only
  three columns are centered; connection lines are reused instead of recreated.
- Library Books: turn-ins, manual marks and the bank scan are now stored per
  character. Existing turn-ins/marks move to the first character that logs in;
  the bank status of each character is rebuilt on its next bank visit.
- Minimap button uses the standard LibDBIcon size, matching other buttons.
- Talent trees: equal horizontal and vertical spacing; class list moved down.
- Removed the caption text from all banners and the profession-data status line.
- Map pins: all dungeon quest starts re-checked against Wowhead (Wilder
  Thistlenettle and Shoni used retail coordinates, "The Glowing Shard" pointed to
  Thunder Bluff, several small corrections); added Destruction in Deadmines.
  Ruins of Lordaeron entrance now uses the Undercity map.
- New command /ofa where.

4.2.0 - UI split into modules
-----------------------------
- The 2,400-line UI.lua is split into one file per tab under UI/ plus shared
  widgets and the main window. No visible changes in game.
- Tabs register themselves; the tab bar is built from that registry.

4.1.2 - code cleanup / bug fixes
--------------------------------
- Fixed: Redridge Mountains was shown as "Contested" (territory table held a map ID).
- Fixed: the golden world-map pin stayed visible when browsing to another zone.
  It is now only shown on the map it was placed on.
- Fixed: the "Quests x / y" column in the dungeon list was only calculated once
  per session. It now updates whenever the list is shown; quest states in the
  dungeon detail view also refresh when the window is reopened.
- Fixed: Blackfathom Deeps "Map" button on non-English clients (added explicit
  map IDs for Ashenvale and other starting zones/cities instead of relying on
  English zone-name matching).
- Performance: UI rows are now created once and reused. Previously every click
  in Dungeons, Professions and Camping Buffs created a new set of frames that
  WoW can never free, so memory kept growing the longer the window was used.
- Performance: the window no longer refreshes itself on bag updates while closed.
- Talent planner: plans are now saved per class (SavedVariables) and survive
  /reload and logout. Removed a duplicate preview call per click.
- Removed dead code: merchant recipe scanning (all 310 recipes ship with
  embedded IDs), unused helper functions and variables.

3.2.0 - Talent Trees data note
------------------------------
Tree structure, row gating and prerequisite behavior are cross-checked against talentsforever.com, whose published JSON is sourced from the WoW Forever beta client. Live client APIs remain the primary runtime source for talent icons and tooltips.

3.1.3
-----
- Reworked Talent Tree buttons to use a Blizzard-style Quickslot frame with rounded/dark corners, inset icons and a subtle shadow/depth effect.
- Increased talent icon breathing room while preserving the four-column planner layout.
- Updated prerequisite connection placement for the new button geometry.
- Fixed the Hunter tree splitter to prefer client-provided tree/subtree membership instead of incorrectly treating local talent X coordinates as three specialization columns.
- Added safer fallback grouping when a class exposes more than three client tree groups.

3.1.2
-----
- Talent rows now unlock in 5-point steps and unavailable talents are visibly greyed out.
- Planner level now follows spent talent points: first point = level 10, up to level 60 at 51 points.
- Added visible prerequisite connection lines using the live client talent graph; linked talents require their prerequisite at full rank.
- Prevented point removal when it would invalidate a lower-row or dependent talent.
- Centered the per-tree point summary in the footer, moved the Left + / Right - hint to the right edge, and removed the redundant Total value.

3.1.1
-----
- Enlarged and rebuilt the golden world-map marker and removed the old glow layer that could render as a dark edge.
- Reworked Talent Trees into a compact four-column grid per specialization to reduce excess spacing.
- Added collision handling for malformed/duplicate client talent coordinates, including Hunter/Priest fallbacks.
- Fixed planner interaction so left-click adds ranks and right-click removes ranks without depending on the client accepting a synthetic preview loadout.
- Replaced the stretched Quickslot overlay with clean 1px borders and cropped talent textures to remove the inner dark rectangle effect.
- Kept the planner-only safety model: no real character talents are changed.

2.9.0 - visual preview
----------------------
- Bundled lightweight dungeon artwork thumbnails for the starter-dungeon list and detail headers.
- Decorative beta-content art strip on the General page.
- Profession icons in Camping Buffs headers.
All bundled artwork is stored locally in OneForAll/Assets; no external addon is required.

2.8.4 - dungeon quality pass
----------------------------
- Rebuilt the embedded dungeon boss/loot and quest/reward data from the user-supplied Forever Dungeon Journal data set.
- Boss loot and quest rewards now use explicit item IDs wherever provided by that data set.
- Dungeon overview now mirrors Library Books: Dungeon, Level, Territory, Zone / Coordinates, Quests, Actions.
- Quest list owns its own scroll position; selecting a quest no longer jumps the list to the top.
- Quest details now include objective, turn-in, notes, item rewards and follow-up reward items when present.

2.7.0
-----
Completed the starter-dungeon boss loot tables used by the Dungeon browser.

Highlights:
- Ragefire Chasm: completed Taragaman and Jergosh loot sets.
- The Deadmines: completed the main boss loot sets, split Sneed and Sneed's Shredder, and added Miner Johnson.
- Wailing Caverns: completed the listed boss and rare loot sets.
- Shadowfang Keep: completed the main boss loot sets and added Deathsworn Captain.
- Blackfathom Deeps: completed the listed boss loot sets and added Lorgus Jett.
- Boss detail pane now shows the number of known loot items for the selected boss.

Dungeon data is beta information and can change during WoW Forever testing.

Version 2.7.0 data/UI follow-up
-------------------------------
- Re-audited starter-dungeon boss loot against current Forever beta/community records.
- Corrected Wailing Caverns and Blackfathom Deeps loot counts where older rows were incomplete or over-inclusive.
- Dungeon quest rewards now use the actual item-quality color reported by the client instead of a hard-coded green label.
- Mage Comprehension scroll hover text now uses the native item tooltip where possible and appends requirements and deciphering guidance.
- Added a Camping Buffs page under Professions with profession-related camping objects, skill requirements, effects and reagents.
- The General page always shows the current addon version from the TOC metadata.


2.7.0 highlights:
- Dungeon overview now uses a compact Library Books-style table with Map buttons.
- Dungeon quests can be filtered by Alliance or Horde and use a boss-style master/detail layout.
- Expanded current-known boss loot and quest rewards.
- Mage scroll tooltips explain Comprehension and deciphering.
- Camping Buffs include gathering and secondary professions such as Fishing and First Aid.

2.5.1
-----
Added a Dungeons tab focused on the early Forever beta dungeon bracket.
Included: The Hall of Thanes, Ragefire Chasm, Ruins of Lordaeron, The Deadmines,
Wailing Caverns, Shadowfang Keep and Blackfathom Deeps.

Each dungeon has:
- level range and faction/area context
- boss list
- current-known / beta loot list
- quest list with required level, faction/class restrictions, pickup location,
  prerequisites and notable rewards where verified
- automatic highlight when a listed quest is currently in your quest log

Dungeon and loot data is beta information and may change during WoW Forever testing.

2.4.0
-----
- Library Books tracker with bag/bank state, confirmed turn-ins, map markers and nearby alerts.
- Mage Comprehension scroll overview.
- Merchant's Favor overview and profession recipe browser with embedded WoW Forever
  recipe IDs, craft spell IDs, crafted item IDs, reagent IDs and enchant metadata.
