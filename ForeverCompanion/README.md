# Forever Companion: Discovery Journal

**A collaborative exploration journal for World of Warcraft: Forever.**

Current release: **3.0.2**, for **WoW Forever 1.60.1** (interface 16001).
[Official CurseForge project](https://www.curseforge.com/wow/addons/forever-companion-discovery-journal).

Your journal holds what you, or a guild member who chose to share it, discovered: rares, vendors, recipes, caves, hidden paths, dungeon secrets. It grows with you, and your guild writes its own guide to Azeroth together. Alongside it, the addon ships a reference of the whole world of WoW Forever (every quest and who gives it, the creatures quests need, treasure, flight paths, dungeons and what each zone holds), so tooltips and the zone guide know every NPC and every zone from the first day.

> This is deliberately not Questie. The addon never reveals the world before someone discovers it.

---

## Core philosophy

- **Discovery first.** Every entry exists because a player found it.
- **We discovered this.** Every shared discovery carries the name of the person who found it and the people who confirmed it.
- **Mystery is a feature.** The *Discovery Fog* can keep guild discoveries veiled as rumors until you visit them yourself.
- **Your data, your choice.** Nothing is shared unless you allow it, per category and per entry.

## Features

### Languages

- Choose **English, French, Spanish, Russian or German** in the illustrated first-run language window or the separate **Language** category in the settings sidebar. All options are visible directly on that page. The choice is saved for the whole account, independently of profiles.
- Both language panels use their dedicated illustration of weathered journals, maps and a compass in an Azeroth inn.
- **Game language** follows the client automatically. Both Spanish client locales (`esES` and `esMX`) use the Spanish translation; unsupported client locales fall back to English. An explicit selection can differ from the game's language.
- Every one of the 1,325 interface strings is translated in each of the four new languages: journal pages, settings, pin styles, notifications, progress, autobiography, onboarding, tooltips, help and player-facing error messages.
- Search supports accented and Cyrillic capitals. Russian uses a Cyrillic font for built-in font choices and for its language preview, including on non-Russian clients. Long settings labels, headings, tooltips and profile buttons adapt to the available space. Dialogs and onboarding resize with translated text; the discovery editor scrolls while its actions remain accessible.
- Recognized automatic discovery titles and descriptions display in the reader's language, including older English entries and entries shared by another supported language. Saved discoveries, personal notes, profile identifiers, import codes and guild messages keep their data and format.
- An offline name dictionary translates supported quests, NPCs, items, objects, zones and subzones into the selected addon language even on an English game client. Toasts, map tooltips, NPC/item tooltip additions, completed quests, the zone guide and journal details use these display names. No other addon is required.
- Map tooltips wrap the complete discovery description. NPC/item tooltip additions keep the same sections, quest progress, status icons, coordinates and character names in every language. Native tooltip measurements are checked for protected values before use.
- Personal notes, edited titles, character names and arbitrary server dialogue remain as written. Names missing from the dictionary retain the available original name; this also covers some custom server content. Translation never rewrites saved discoveries, quest IDs or guild payloads.
- Selecting a language previews it without saving. **Apply and reload** saves a different display language and reloads the UI; first-run setup then continues with progress and sharing. The same display language can be saved without a reload. Existing users keep their automatic language until they choose another in Settings. NPC and area recognition still follows the game client's language.

### Map and journal narration

- Narration starts **enabled in new profiles**, at **50% volume**. Saved on/off preferences are preserved. Use the visible **Narrator** checkbox below the journal logo to turn it on or off for the world map and journal entries. Select **English** in the Language page for this first audio pack.
- An original deep, warm male chronicler reads a pin's name and description. Catalog rares, dungeons and caves use their canonical name and brief lore or field notes. The coordinates, discovery credit, date and mouse instructions are excluded.
- Hover a world-map pin or the description or lore in an open journal entry. Speech starts after an adjustable delay and stops when you leave, close the relevant window, switch entries or turn narration off. Returning to the pin or description restarts the recording after the same delay, without reopening the window. Only one recording plays at a time, and it does not loop while the pointer stays over the entry. Minimap pins show a compact name-and-icon tooltip without narration or lore. Hidden discovery details remain silent.
- Adjust **Narrator volume** directly in **Settings > Narrator**: 0%, 25%, 50%, 75% or 100%. The default is 50%; 0% mutes narration. This changes only the narrator. The game's Dialog and Master settings also affect playback.
- Audio plays locally through the game's **Dialog** channel. The addon needs no ElevenLabs account, API key or internet connection for playback.
- This release includes **1,188 English recordings**, covering every category represented in the current discovery collection, **370 rares, 30 dungeons/raids and 106 cave, mine, den and underground entrance entries**. Catalog recordings work for future discoveries too. Other interface languages have translated text but no audio pack yet. Other new or edited descriptions need a matching recording. Personal notes are excluded from the distributed pack.
- **Read discoveries aloud**, **Listen to a sample**, **Stop narration** and the hover delay are available in **Settings > Narrator** (`/fc settings narrator`). The settings checkbox and journal switch stay synchronized.
- After installing the audio files for the first time, fully restart WoW so the client can find them.

### Brief discovery lore

- Every catalog rare, dungeon and cave has concise context in English, French, Spanish, Russian and German, shown in world-map tooltips and journal details. Minimap tooltips show just the discovery name and icon.
- The cave catalog covers 106 named entries, including mines, burrows, silithid hives, druid barrows and cave entrances to dungeons. Coverage was checked against Classic/Forever area names and manually reviewed locations whose names do not include "cave". Unused beta area names are excluded. New custom locations may need an additional catalog entry.
- Known cave lore replaces the repetitive automatic "A large indoor area entered from..." line. Personal notes remain alongside the sourced account. Where no specific history was confirmed, regional context is used without inventing inhabitants or events.
- All 30 dungeon/raid entries and 32 rare entries have short sourced stories or background. The remaining 338 rares have factual field notes about their creature type, location and, where confirmed, affiliation; no invented biographies are presented as lore.
- **Sources** in the journal opens the entry's source links for copying into a browser. The catalog was checked on 11 October 2026 and keeps Classic context separate from later expansions.
- Entrance pins share their dungeon's account and recording. Lower/Upper Blackrock Spire and Dire Maul wings use their shared instance account.
- The catalog does not mark places as discovered, add pins, reveal fog or rewrite saved discoveries.

### Link discoveries in chat

- **Link in chat** and journal **Shift-click** insert a discovery link into an already open, focused chat box when the client permits it.
- Otherwise, a copy window opens: press **Ctrl+C**, close it, open chat with **Enter**, and paste with **Ctrl+V**. This avoids activating protected Blizzard chat controls from addon code.

### Choose your pin style

- **Settings > Map > Pin appearance** shows clickable examples for Dark Warcraft, Cartographer's Engravings, Painted Adventure (the previous Midjourney artwork), Heraldic Emblems and Original game icons. **Browse pin styles** opens a larger gallery with its own illustrated header.
- Each custom style includes all 26 map symbols, including caves, rares, treasure, quests, NPCs, vendors, professions, dungeon areas and unknown discoveries. The three examples on each card represent the complete set.
- A selection applies immediately to the world map, minimap, journal entries, tooltips and notifications, and is saved per profile. Existing users keep their current Dark or Original choice.
- World-map and minimap pin sizes remain independent, from **25% to 500%**, under Map settings. Artwork changes keep the selected sizes and all discovery data.

### Discovery Journal
- An adventurer's expedition journal: leather and brass, cards and details on parchment, a painting at the top of every page (or a flat look in color themes). Sidebar navigation, rich discovery cards, a full detail page.
- Pages: Overview, Recent, Quests, Completed quests, NPCs, Rares, Bestiary, Vendors, Recipes, Items, Secrets, Explored caves, Opened chests, Exploration, Dungeons, Professions, Guild discoveries, Favorites, My notes, Archived, Progress, Statistics, Autobiography.
- **Secrets** uses a reviewed catalogue of 14 hidden activities matched by explicit IDs, with source links on each matching entry. Ordinary caves, chests, paths and interactive objects have separate pages. Unsupported older secret entries remain in Exploration, preserving their saved data.
- **Opened chests** requires a confirmed, identifiable world-container loot window and tracks openings per character. **All recorded** also shows sightings and older records without proof of opening. `is:secret` searches the catalogue across quests, items and objects; `is:opened` finds confirmed openings.
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
| Open a chest or cache | **Treasure**, with private opening evidence when the loot source is identifiable; verified chest IDs override misleading herbs/ore-only loot, while ordinary quest props remain objects |
| Gather herbs, ore or fish | **Gathering spots** per resource and zone (up to 40 spots each) |
| Use an object, read a book or plaque | **World object**, or **Secret** only when its ID belongs to a documented hidden activity |
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
- How it counts, also in the tooltip of each headline number: distance and time are sampled once a second while the journal runs (loading screens and teleports are left out); *With the journal* is that time, not `/played`. The game's own `/played` is asked for at login without a line in the chat and shown beside it in the *Time* section, with the time at the current level; typing `/played` refreshes it. *All characters* lists each character's `/played` on its own, then all together. Kills come from the experience messages (kills that give no experience are not counted), quests from the game's own list of completed quests, money from what was open when it changed (loot, a vendor, mail, the auction house, a trade, a trainer, a flight master), supplies from the consumables used out of your bags.
- The autobiography lives in the saved variables (`WTF`), per character; an update of the addon never touches it, and a backup (Settings > Data) carries it along.

### Zone guide
- A zone at a glance, with foldable sections and progress counts. Quests are grouped by quest giver and live status. Rares track defeats; caves, documented secrets and chests have separate sections. Journal chests require confirmed openings for completion, while other discoveries track encounters. Flight paths, dungeons, exploration and recipe vendors are included too.
- Click the addon's button on the world map to open it for the zone the map shows; it follows the map while you browse it, and goes back to your zone when the map closes. `/fc zone` or a middle-click on the minimap button opens it for the zone you are in.
- Click a section title to fold it, a quest giver to fold its quests; one button hides everything already done, and a section with nothing left goes with it. Click a line for a waypoint, right-click to open it in the journal. It can open by itself when you enter a zone.

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
- Discovery pins on the world map with dark, transparent category artwork, guild markers and rich tooltips. Only the finds that matter by default (rares, secrets, caves, treasure, dungeons, your notes), so the map stays readable; everything else can be switched on.
- Small pins on the minimap for the finds around you, with the same filters; they rotate with a rotating minimap and work on round and square minimaps.
- World-map and minimap pin sizes are adjustable separately from **25% to 500%** in the journal's **Map** page or **Settings > Map**. Changes appear immediately.
- **Map > Pin appearance > Transparent symbols** selects the 26 dark category icons across maps, journal cards/details, tooltips and discovery notifications. **Original game icons** selects the game artwork. Known caves have a cave symbol; veiled discoveries keep the unknown symbol.
- The addon's button on the map: click for the zone at a glance, right-click for the filters (my / guild discoveries, per-category toggles).
- **Discovery Fog**: show only what you found, yours plus verified guild discoveries, or everything your guild knows; optionally veil guild discoveries until you get close.
- Waypoints through the game's own waypoint system, or TomTom if installed and preferred.

### Customization
- Two styles: the painted expedition journal (default) or flat, one click apart (the palette button at the top of the journal; Settings > Appearance). The flat style has 8 themes (Forever Dark, Classic, Midnight, Minimal, Horde, Alliance, Forest, Arcane), custom colors per role, custom themes with copy, export and import.
- Font selection (client fonts, plus LibSharedMedia fonts if installed), size, outline, shadow, spacing, with a live preview.
- UI scale, opacity, background opacity, border size, panel style, button style, card density, tooltip style, animations, high contrast mode.
- Resizable journal with a draggable split between list and detail. Drag the journal by any part that is not a button or a list (its frame, header, sidebar or footer) to move it; *Settings > Appearance > Window* can lock it in place.
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

1. Download from the [official CurseForge project](https://www.curseforge.com/wow/addons/forever-companion-discovery-journal) or install through the CurseForge app for **WoW Forever 1.60.1**.
2. For a manual install, close the game and extract the `ForeverCompanion` folder into the Forever client's `Interface\AddOns\` folder. On the beta client, that is `World of Warcraft\_classic_beta_\Interface\AddOns\`. The resulting path must be `Interface\AddOns\ForeverCompanion\ForeverCompanion.toc`.
3. For an update, replace the addon files and keep the existing `WTF` folder and SavedVariables; your discoveries and settings stay there.
4. Start the game and open the journal with `/fc`. A first-time welcome guide asks for your language, how progress counts and how you want to share. The journal starts in the painted look; the palette button at its top switches to a flat color theme.

## Moving from the beta to the release

Your journal is a file on your computer, not on the server. The release client has its own folder, so nothing moves by itself.

1. Before the first login on the release client, copy `World of Warcraft\_classic_beta_\WTF\Account\<your account>\SavedVariables\ForeverCompanion.lua` to the same place under the release client's folder (the account folder has the same name). This file holds the whole journal: every discovery, the guild's shared entries, your characters' progress, autobiographies and settings. The per-character files (`WTF\Account\<account>\<realm>\<character>\SavedVariables\ForeverCompanion.lua`) hold only quest chains and a last position; they can stay behind.
2. A text backup works as well: `/fc export` on the beta, `/fc import` on the release (Settings > Data). Importing merges and never deletes.
3. If the game marks the addon *out of date* on the first day of the release, tick *Load out of date AddOns* in the addon list; an update with the new interface number follows (the first line of `ForeverCompanion.toc`).
4. A character you create again with the same name is recognized as new (the game tells characters apart by their GUID): its completed quests, flight paths and defeated rares start over from what the game lists, and the journal asks once whether it continues the previous character's journal (finds, milestones, autobiography) or starts fresh. Fresh keeps the previous character on the Progress and Autobiography pages as "(previous)", with everything it did; the new one starts at nothing. The journal's entries stay either way.
5. Characters you do not create again can be forgotten (right-click their row on the Progress page, or `/fc forget <name>`): they leave the lists; what they found stays in the journal.
6. Realm names may change: a character's profile follows it to the renamed realm. Guild members who did not copy their file get the shared entries back from yours through guild sync.

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
- Some categories are detected by heuristics, because no addon API names them directly: unusual NPCs (quest givers, services, guards and everyone in towns and inns are left out; guards and service roles are recognized with localized keywords), caves (a long indoor stretch outside towns; halls, abbeys, towers and other buildings are left out by localized keywords), routes (your last minutes of movement before a hidden place), secrets (objects you use out in the wild) and mechanics (boss emotes and yells). English recognition words stay available on localized clients for custom-server names. These heuristics can produce the occasional odd entry; archive or hide it.
- Hidden paths that are not caves, and shortcuts, cannot be recognized automatically; Quick Capture covers them.
- Respawn times are never claimed as exact. The journal shows observed intervals and labels any range as an estimate.
- Midnight-era restrictions apply: some unit values are hidden in combat or restricted content, so automatic detection waits until combat ends, and addon messages pause while the client locks communication.
- Positions are not available inside instances, so dungeon entries are listed under their dungeon instead of on the map.
- Guild sync reaches only guild members who run Forever Companion. Chat links become clickable only for them; others see readable text.
- The combat log is closed to addons on this client, so the autobiography counts kills from the experience messages (kills that give no experience are not counted) and does not track damage or healing.
- Addons cannot read screenshots or reach the internet. The text export format is the bridge for future external tools.
- The Forever beta build 69913 had a client bug that did not reload SavedVariables; it is fixed in 1.60.1.70009. The addon is built against build 1.60.1.70170 and says so once in the chat when the game moves to another build. Keep a text backup (`/fc export`) during the beta anyway.
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

Created by Duta. Copyright (c) 2026 IAMTHEDOT, all rights reserved: IAMTHEDOT owns every right in the addon, and modifying it (or redistributing it) requires IAMTHEDOT's written permission. See `LICENSE` for the full terms (`LICENSE.txt` holds the short notice: all rights reserved unless otherwise explicitly stated); your own journal data stays yours. The addon includes custom interface artwork and 26 category icons created with an AI image generator. Fonts and fallback game icons are loaded from the game client.

The WoW Forever reference data in `Data/Reference/` is derived from the database of AllTheThings (MIT License, Copyright (c) 2026 AllTheThings WoW Addon) by `tools/import_att.lua`, which reads it as text; that data keeps its MIT license, see `THIRD_PARTY_NOTICES.md`. Quest titles and levels, the quests and rares AllTheThings does not list yet, and the English names of the creatures and objects that give quests are facts taken from the listings and the tooltip service of Wowhead's WoW Forever database by `Tools/import_wowhead.py` and `Tools/fetch_wowhead_names.py`. No third-party code or libraries are bundled.
