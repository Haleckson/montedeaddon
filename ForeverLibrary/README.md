# Forever Library Scout

A standalone WoW Forever (Interface 16001) addon. Includes the same LibDataBroker / LibDBIcon libraries as Forever Dungeon Scout; no other addons required.

Reload the client after enabling **Forever Library Scout**, then use `/books` or `/flibrary`.
The journal is also available in Blizzard Settings → AddOns → Forever Library Scout.

The draggable minimap button opens the journal on left-click and toggles the tracker on right-click. Its position and visibility are saved per character. `/books minimap` toggles its visibility. The `ForeverLibrary` LibDataBroker launcher remains available to broker displays and minimap button collectors even when the minimap icon is hidden.

- Search 40 unique books by name, zone or location notes. Current-zone books sort first.
- Missing, Carried, Tracked and All views.
- Select a book to see field notes, then **Show map & navigate** or **Track**.
- Shift-click journal rows to toggle tracking. The compact draggable tracker shows up to six books, while every tracked book gets a world map pin.
- Map pins use Blizzard's MapCanvas data provider and pin pooling. Left-click to navigate; right-click to toggle tracking. Continental pins project through the native C_Map coordinate APIs when supported.
- Navigation uses C_Map user waypoints and C_SuperTrack when the client accepts them. Otherwise, the book remains marked on the world map, with a chat message explaining the fallback.
- Reward previews show the two necklace choices at 10 turn-ins and the two ring choices at 20. Hover for the native item tooltip, Shift-click for the item link when cached.
- `/books tracker` toggles the compact tracker. Both journal and tracker positions are saved per character.

## Progress meaning

**Returned**: a completed book quest reported by Blizzard, or a turn-in observed by this addon. Completed quest flags restore earlier donations after installation.

**Carried**: the book is currently in your bags. Banked books are recorded as looted history rather than shown as ready to bring.

**Looted**: the addon observed your own loot message, found the item in bags/bank, or recorded a turn-in. The book is no longer in your bags. It may be banked or destroyed; this is not a confirmed donation.

**Marked**: an explicit manual note for a book collected before installation. This is kept separate from automatic evidence and never contributes to confirmed reward progress.

**Missing**: no collection evidence is available. Blizzard does not provide a general historical item-loot API, so a book destroyed before installation cannot be recovered from item history alone. Use the manual note if needed.

Rumi's two locations share one item and one quest, so the book counts once.
Ataeric and The Liminal and the Arcane have unknown Forever locations; they remain in the journal, their old SoD coordinates are clearly labeled, and their pins appear only when explicitly tracked.
Wailing Caverns and Blackrock Mountain use outdoor approach pins and separate interior notes to avoid plotting cave coordinates onto a zone map.

## Sources and validation

Cave approaches, reward item IDs and additional notes: [ForeverChanges](https://foreverchanges.pro/library-books).
Quest/item mappings cross-referenced with Wowhead Forever and [Questie-Forever's public SoD base quest data](https://github.com/tysongoulding/Questie-Forever/blob/main/Database/Corrections/Automatic/sodBaseQuests.lua). Only the required identifiers and book facts are included; no Questie code or libraries are bundled.
Blizzard frame and MapCanvas contracts checked against [Blizzard UI source mirror](https://github.com/Gethe/wow-ui-source/tree/classic_beta/Interface/AddOns/Blizzard_MapCanvas).

Lua 5.1 syntax, state restoration, self-loot ownership, completion persistence, pin filtering, waypoint/fallback paths, journal filtering, tracker cap, XML structure and TOC file references verified with a mocked-client harness. Actual game rendering and beta server behavior require in-game validation.

Suggested in-game check: open `/books`, search a known nearby book, track it, open the zone map, hover/click its pin, loot it and return it to your librarian. Reload and confirm progress persists. Hover all reward previews and check the unknown-location labels.

## Controller support

With Blizzard native gamepad input enabled, the journal and rewards window support a visible focus outline and controller navigation. Set the journal and tracker-navigation shortcuts in WoW Key Bindings under **Forever Library Scout**; no existing bindings are replaced. `/books nav` enters or exits tracker navigation. Tracker input is captured only when you explicitly enter that mode.

- D-pad: move focus (mapped left-stick directional buttons also work).
- A / Cross: select or activate the focused button; tracker entries open their map location.
- X / Square: track or untrack the focused book.
- B / Circle: close rewards, close the journal, or leave tracker navigation.
- Y / Triangle: rewards from the journal, journal from the tracker, or librarian map from rewards.
- LB / RB: cycle journal filters.
- LT / RT: previous or next book, with automatic scrolling.
- Right-stick click: toggle field-note scrolling; LT / RT scroll long notes in this mode.

The addon releases input in combat and while the world map is open. Map movement and supertracked waypoint navigation use Blizzard's native controls. Search text entry uses the game's normal cursor/keyboard input. ConsolePort retains its own cursor handling; native addon capture is disabled when ConsolePort is loaded.

Controller behavior has been tested with a mocked-client harness; controller hardware and the live game still need in-game validation.

## Creator and appearance

Created by **Kushen**. The journal uses the same Blizzard marble background as Forever Dungeon Scout. The Theme button switches classic and dark backgrounds and frame borders, saved per character. Librarian & rewards combines the faction-selected turn-in location and reward previews.

## Suggested pickups and pin colors

The Suggested filter highlights missing easy pickups (green check) and low-level combat options (yellow clock). Suggestions adapt to faction. These are conservative priorities, not a fastest route or a guarantee of 20 safe books. Travel can still be hazardous.

Thin map borders are green for easy pickups, yellow for moderate risk, and red for hard or unknown locations. Estimates consider faction, current level, rough zone levels and guarded locations. An explicitly instanced dungeon location is always hard. Current cave and dungeon-adjacent books are outside instances; their pins and notes identify the approach correctly.

