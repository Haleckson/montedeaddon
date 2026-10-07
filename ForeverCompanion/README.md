# Forever Companion: Discovery Journal

**A collaborative exploration journal for World of Warcraft: Forever.**

Your journal holds what you, or a guild member who chose to share it, discovered: rares, vendors, recipes, caves, hidden paths, dungeon secrets. It grows with you, and your guild writes its own guide to Azeroth together. Alongside it, the addon ships a reference of the whole world of WoW Forever (every quest and who gives it, the creatures quests need, treasure, flight paths, dungeons and what each zone holds), so tooltips and the zone guide know every NPC and every zone from the first day.

> This is deliberately not Questie. The addon never reveals the world before someone discovers it.

---

## Core philosophy

- **Discovery first.** Every entry exists because a player found it.
- **We discovered this.** Every shared discovery carries the name of the person who found it and the people who confirmed it.
- **Mystery is a feature.** The *Discovery Fog* can keep guild discoveries veiled as rumors until you visit them yourself.
- **Your data, your choice.** Nothing is shared unless you allow it, per category and per entry.

## Features

### Discovery Journal
- An adventurer's expedition journal: leather and brass, cards and details on parchment, a painting at the top of every page (or a flat look in color themes). Sidebar navigation, rich discovery cards, a full detail page.
- Pages: Overview, Recent, Quests, Completed quests, NPCs, Rares, Bestiary, Vendors, Recipes, Items, Secrets, Dungeons, Professions, Guild discoveries, Favorites, My notes, Archived, Progress, Statistics, Autobiography.
- Cards show icon, type, zone, coordinates, discoverer, time, tags, favorite, verification count and a status badge (icon + text + color, never color alone). Compact and comfortable density.
- Detail page: location, discoverer and dates, NPC data, **vendor inventory** (limited stock and recipes marked, flag items as interesting), **rare respawn observations** with clearly labelled estimates, **dungeon hierarchy** (entrance, bosses, NPCs, quests, secrets, recipes, loot, mechanics, shortcuts, notes), related discoveries, tags, personal note, guild notes and verification history.
- Actions: show on map, waypoint, favorite (with groups), share, link in chat, edit, note, tag, confirm, archive, export, delete.
- Search with filters: `rare ashenvale`, `vendor engineering`, `type:secret`, `by:gingasul`, `tag:important`, `prof:alchemy`, `in:deadmines`, `is:fav`, `is:verified`, `is:guild`, `is:new`.
- Filter menu (scope, verified, favorites, archived, date, zone) with removable chips, six sort orders, profession and favorite-group chips.
- Recent discoveries feed, exploration activity and milestones on the Overview.

### Fully automatic documentation
You never have to type anything. Every category of the journal is filled from what happens in the game, with a generated description and search tags:

| What you do | What the journal writes |
| --- | --- |
| Target, hover or see a nameplate of a creature | **Bestiary** entry: level range, type, classification, where; every item it drops is added to its loot table |
| Meet a rare or a world boss | **Rare** with sightings and deaths, respawn intervals and a labelled estimate |
| Talk to an unusual NPC (no quests, no service, not a guard, outside towns and inns) | **Unusual NPC** with subtitle and greeting |
| Open a vendor, a trainer or a flight map | **Vendor** with stock (limited items and recipes marked), **Trainer** with profession, **Flight master** |
| Explore a new area ("Discovered: ...") | **Landmark** (or a dungeon area inside instances) |
| Reach a mine or cave (the game names it: "Discovered: Echo Ridge Mine"), or go indoors outside a town and move deep inside | **Cave** at its entrance, plus the **route** that led you there, drawn on the map |
| Open a chest or cache | **Treasure** (and its route); herbs, ore veins and fishing spots are told apart by the gathering spell and by what they give, and quest-only objects are ignored |
| Gather herbs, ore or fish | **Gathering spots** per resource and zone (up to 40 spots each) |
| Use a strange object, read a book or plaque | **Secret** (in the wild) or **World object**, with the text |
| Loot unusual items or recipes | **Item** / **Recipe** with source, profession and required skill |
| Learn a recipe | **Profession** entry (private) |
| Accept quests, especially in a row | **Quest** with giver; follow-up quests are linked into a **Quest chain** |
| Enter a dungeon, walk its areas, fight its bosses | **Dungeon**, **Entrance**, **Dungeon areas**, **Bosses**, and **Mechanics** from the boss emotes and yells |
| Die | a private **Dangerous spot** note with the count and what killed you |

Every detector can be switched off in *Settings > Discovery*. Quick Capture (`/fc add`, Alt+Right-click on the map) stays available for anything you want to add by hand.

### Completed quests, and what the game remembers
- The **Completed quests** page lists every quest the game says a character completed, by name, with its zone, level and quest giver: grouped by zone or sorted by name, level or date, searched with the journal's search box, for any of your characters or all of them. It is the list behind the *Quests completed* number of the Progress page (its tile opens it; so does `/fc quests`).
- The game keeps completed quests on the server, so the list is complete after a reinstall and for a character that played without the addon. Those quests have their name, zone and quest giver, but no date: only quests turned in while the journal watches are dated. Quests accepted while it watched open their journal entry.
- Names come from the game, from what the journal learned, or from the English titles the addon ships. A quest the game has not loaded is asked for in the background; one it has no name for stays listed as *Unknown completed quest* with its ID until a name arrives. On a client in another language a shipped English title gives way to the game's own once the quest is loaded.
- **Who gives a quest** is on every line and in its tooltip, with the place it starts at: the creature (the one of your faction when each has its own), the object (a wanted poster, a corpse) or the item. The addon ships the English names of the quest givers, so they are there at once; the game's own names, in your language, replace them for the lines you look at. Search for a giver's name to find his quests. A quest nobody has seen start yet (many of the quests WoW Forever added) says so, until you or a guild member picks it up.
- The **areas a character explored** are read back as well, once per character: the game remembers which parts of every zone map are uncovered. They are filed as explored areas (or caves), private, without a toast and without a date.
- `/fc rescan` (also in *Settings > Data*) reads both again and reports what it found; nothing is deleted.
- What cannot be read back, because the game does not keep it: when and where a quest was done, the creatures a character met, vendors, chests, routes, the rares it defeated and the numbers of the autobiography. Those start when the journal starts watching. Flight paths are read again the next time a flight map opens.

### Progress: account-wide or per character
- Everyone chooses once how progress counts (new players in the welcome guide, players who had the addon before in a question at login); the journal's *Progress* page and *Settings > General* change it any time.
- **Account-wide**: your characters share one progress. A discovery any of them made is not announced again when another one comes across it, but it still counts for the character that finds it.
- **Per character**: every character starts with an empty journal, as if it were the first to use the addon: it lists only what it found itself (on the map and in the zone guide too), has its own milestones and gets every toast as if everything were new. Your other characters are only counted, in the Overview's *All characters* block and on the Progress page.
- The **Progress** page (Insights) shows the whole account whatever you chose, and any of your characters, alone or added together: discoveries by category, zones, quests completed, rares defeated, flight paths, milestones, and a table with every character side by side. *Show in journal* lists what they found.

### Autobiography
- A page in the journal with each character's story: distance travelled in km (on foot, mounted, swimming, flying, as a ghost), deaths and their killers, kills, quests, food and potions used, money earned and spent, items, gathering, duels, time spent, and a timeline of level ups, deaths, first visits, bosses and more.
- Recorded quietly in the background; nothing is on screen unless you open the page. *All characters* adds up your account.

### Zone guide
- A zone at a glance, with your progress: the zone's done / total and percentage on a thin bar, then foldable sections with their own counts. Quests are grouped under the quest giver (done / total per giver), with each quest's state: done, ready to turn in, in progress, not done. Rares count as done once this character defeated them (with respawn estimate or last kill), treasure, secrets and caves once you found them, flight paths once this character learned them; dungeons and exploration too. Vendors with recipes are listed for reference.
- Click the addon's button on the world map to open it for the zone the map shows; it follows the map while you browse it, and goes back to your zone when the map closes. `/fc zone` or a middle-click on the minimap button opens it for the zone you are in.
- Click a section title to fold it, a quest giver to fold its quests; one button hides everything already done. Click a line for a waypoint, right-click to open it in the journal. It can open by itself when you enter a zone.

### Tooltips
- NPC tooltips in the style of a collection addon: the quests the NPC gives with your progress on each (done, ready to turn in, in progress, not done) and a done / total count, the quests you turn in to it, the quest items it drops and the quest each one starts, plus what the journal knows (vendor stock, trainer, flight master, rare respawn, bestiary level and loot, notes, who found it) and the NPC ID.
- Quest-starting items name the quest they start and the creatures that drop them.
- Item tooltips show where the item drops (creatures, with level and place) and who sells it, from what you and your guild documented.
- Rares and world bosses show how long ago they spawned and your layer.
- Quests your other characters already did carry their names, in grey.
- A brass exclamation mark with a crimson gem floats above the nameplate of every creature an active quest still needs you to fight (to kill or loot it), until that objective is done. Friendly NPCs a quest sends you to talk to keep the game's own marks. It steps aside while you are in combat; its size is set in *Settings > Quest marker*, with a preview.
- Every creature shows its NPC ID; quests the game has not loaded yet read "Quest #ID" until their title arrives.
- Creatures show the quests they are needed for (to kill, loot or talk to), with live progress such as 7/12 while the quest is active and its state afterwards, also on your other characters. The addon learns these links from the quest lines the game puts in the creature's tooltip and nameplate.
- Every NPC and creature in the game is covered by the WoW Forever reference that ships with the addon, filtered to what the character you play can do (faction, class, race). On top of it the addon learns as you play, on every character and with your guild: quests offered in an NPC's dialog, quests you turn in, quest items you loot.

### Notifications
- A toast for the finds that matter: rares, bosses and world bosses, dungeons on the first visit, treasure, secrets, caves, rare loot, recipes found or learned.
- *Which discoveries show a notification* (first in Settings > Notifications) switches any category on or off, and the cog on a notification turns its kind off at once; routine finds such as quests, explored areas or gathering spots are recorded quietly by default.
- *RARE DEFEATED* when you loot a rare or world boss from your journal, with its respawn estimate.
- *RARE NEARBY* when the game marks a rare (or treasure) on your minimap, even one you already know; new ones are recorded without targeting them.
- Big finds have sounds of their own (game sound kits), with a preview button; other toasts use the sound you pick.
- A find is announced once: not again to the character that made it, not as a guild discovery when the guild gives your own entry back, and a rare on the minimap that is new to you is one toast, not two. A burst of routine finds (a town's vendors and trainers) folds into one *N new discoveries* toast; rares, bosses, treasure, dungeon finds, secrets and caves keep their own. Finds made in a fight are filed and announced when it ends.

### Guild Discovery
- Shared discoveries show who found them and who confirmed them.
- *NEW GUILD DISCOVERY* notifications with the discoverer's name.
- Independent discoveries of the same thing merge automatically and count as verification.
- Guild notes on any shared discovery.
- Clickable `[FC: ...]` chat links for guild members with the addon.
- **The guild's quest database, built together**: what any member learns about quests (which NPC gives and takes which quest, which creatures a quest needs, which items start a quest) reaches everyone, live and when they come online. Tooltips and the zone guide then show it for every NPC someone in the guild has met. Nothing personal travels; *Settings > Guild sync* can turn it off.

### Map integration
- Discovery pins on the world map with category rings, guild markers and rich tooltips. Only the finds that matter by default (rares, secrets, caves, treasure, dungeons, your notes), so the map stays readable; everything else can be switched on.
- Small pins on the minimap for the finds around you, with the same filters; they rotate with a rotating minimap and work on round and square minimaps.
- The addon's button on the map: click for the zone at a glance, right-click for the filters (my / guild discoveries, per-category toggles).
- **Discovery Fog**: show only what you found, yours plus verified guild discoveries, or everything your guild knows; optionally veil guild discoveries until you get close.
- Waypoints through the game's own waypoint system, or TomTom if installed and preferred.

### Customization
- Two styles: the painted expedition journal (default) or flat, one click apart (the palette button at the top of the journal; Settings > Appearance). The flat style has 8 themes (Forever Dark, Classic, Midnight, Minimal, Horde, Alliance, Forest, Arcane), custom colors per role, custom themes with copy, export and import.
- Font selection (client fonts, plus LibSharedMedia fonts if installed), size, outline, shadow, spacing, with a live preview.
- UI scale, opacity, background opacity, border size, panel style, button style, card density, tooltip style, animations, high contrast mode.
- Resizable journal with a draggable split between list and detail.
- ElvUI-style profiles: shared default, per character, per class, or custom; create, copy, rename, delete, reset, export, import.
- Everything applies instantly. No reload needed.

## Commands

| Command | Action |
| --- | --- |
| `/fc` | Open or close the journal |
| `/fc journal [page]` | Open the journal (e.g. `/fc journal rares`) |
| `/fc add [type]` | Quick capture at your position |
| `/fc map` | Open the world map |
| `/fc zone` | Show or hide the zone guide |
| `/fc quests` | Open the list of completed quests |
| `/fc rescan` | Read completed quests and explored areas again from the game |
| `/fc search <text>` | Search the journal |
| `/fc settings` | Open settings |
| `/fc sync [status\|ping]` | Sync with your guild, show status, ping |
| `/fc export` / `/fc import` | Back up or restore the journal as text |
| `/fc profile <name>` | Switch profile |
| `/fc minimap` | Show or hide the minimap button |
| `/fc reset window` | Reset the journal window |
| `/fc debug` | Debug mode and developer tools |

Aliases: `/fcj`, `/forevercompanion`. Minimap button: left-click journal, right-click settings, shift-click quick capture. Also available in the addon compartment.

## Installation

1. Download from CurseForge (or the CurseForge app, game version *WoW Forever*).
2. Extract the `ForeverCompanion` folder to `World of Warcraft\_classic_beta_\Interface\AddOns\` (the Forever client folder).
3. Start the game. A short welcome guide asks how progress counts and how you want to share. The journal starts in the painted look; the palette button at its top switches to a flat color theme.

## Privacy and guild sharing

- Sharing can be turned off entirely, or limited to guild, party or raid.
- New discoveries follow your settings: automatic sharing on or off, quest discoveries private by default, map notes private by default, coordinates can be withheld.
- Every discovery has its own **Private / Guild shared** flag.
- Personal notes, personal tags, favorites and archive state are never sent.
- Deleting only removes your own private entries. Shared guild history is hidden locally, never destroyed; only the original author can retract a shared discovery.
- Sync is incremental and throttled: on login the addon announces itself once and asks one guild member for changes made while you were away. The full database is never broadcast.

## Known limitations

- **World of Warcraft: Forever runs the Retail (12.x) client engine** while reporting interface 16001. Forever Companion targets that API; it does not load on Classic Era.
- Tooltip quest lists only contain what one of your characters saw an NPC offer (or what your guild shared); talk to an NPC once and its quests are known. When the client keeps a unit's GUID secret, the NPC is recognized by its name if the journal knows only one NPC with that name.
- Some categories are detected by heuristics, because no addon API names them directly: unusual NPCs (quest givers, services, guards and everyone in towns and inns are left out; guards and service roles are recognized by English names and subtitles), caves (a long indoor stretch outside towns; halls, abbeys, towers and other buildings are left out by their English names), routes (your last minutes of movement before a hidden place), secrets (objects you use out in the wild) and mechanics (boss emotes and yells). They can produce the occasional odd entry; archive or hide it.
- Hidden paths that are not caves, and shortcuts, cannot be recognized automatically; Quick Capture covers them.
- Respawn times are never claimed as exact. The journal shows observed intervals and labels any range as an estimate.
- Midnight-era restrictions apply: some unit values are hidden in combat or restricted content, so automatic detection waits until combat ends, and addon messages pause while the client locks communication.
- Positions are not available inside instances, so dungeon entries are listed under their dungeon instead of on the map.
- Guild sync reaches only guild members who run Forever Companion. Chat links become clickable only for them; others see readable text.
- The combat log is closed to addons on this client, so the autobiography counts kills from the experience messages (kills that give no experience are not counted) and does not track damage or healing.
- Addons cannot read screenshots or reach the internet. The text export format is the bridge for future external tools.
- The Forever beta build 69913 had a client bug that did not reload SavedVariables; it is fixed in 1.60.1.70009. Version 0.7.3 targets build 1.60.1.70170. Keep a text backup (`/fc export`) during the beta anyway.
- In a few caves (and at a new character's first login) the game names the continent as your map. Discoveries made there are filed on the zone map they lie in, so they show on the zone map, the minimap and in the zone guide.

## Roadmap

- Translations: German, French, Spanish, Romanian (the localization system is ready).
- Dungeon route notes, favorite group management.
- Shared exploration objectives and guild treasure hunts.
- Web atlas and Discord tooling through the export format.

## Bug reporting

Please open an issue on the project page with:
- the addon version (`/fc help` shows it) and the game build,
- what you did and what you expected,
- the output of `/fc debug on`, then `/fc debug log 40` after reproducing the problem;
- for completed quests without a name or a wrong count: the lines of `/fc rescan` and of `/fc debug quests`.

## Credits and license

Created by Duta. Copyright (c) 2026 IAMTHEDOT, all rights reserved: IAMTHEDOT owns every right in the addon, and modifying it (or redistributing it) requires IAMTHEDOT's written permission. See `LICENSE` for the full terms (`LICENSE.txt` holds the short notice: all rights reserved unless otherwise explicitly stated); your own journal data stays yours. The emblem and the quest marker are original artwork, and all fonts and icons are loaded from the game client.

The WoW Forever reference data in `Data/Reference/` is derived from the database of AllTheThings (MIT License, Copyright (c) 2026 AllTheThings WoW Addon) by `tools/import_att.lua`, which reads it as text; that data keeps its MIT license, see `THIRD_PARTY_NOTICES.md`. Quest titles and levels, the quests and rares AllTheThings does not list yet, and the English names of the creatures and objects that give quests are facts taken from the listings and the tooltip service of Wowhead's WoW Forever database by `Tools/import_wowhead.py` and `Tools/fetch_wowhead_names.py`. No third-party code or libraries are bundled.
