# Chronicle Forever 1.5.249

## Dungeon and raid loot

- Boss loot and the All Loot list are now organized into expandable item-type groups. Shared raid drops have their own groups, so they remain visible without being mistaken for boss-exclusive rewards.
- Loot rows show item quality through colored names and markers, with equipment categories and known drop chances placed clearly beside the item. Mouseover tooltips continue to show the available client or reference details.
- Boss loot counts now include shared drops and count each item only once per encounter.
- Selecting an item in All Loot shows the recorded boss sources and known chance for each source.
- When the Encounter Journal supplies an item already present in Chronicle's catalog, its saved quality, equipment slot, and drop chance are retained. Chronicle retries journal loot that has not loaded yet.
- The existing catalogs were checked for resolvable item names. Unknown IDs are requested from the game client and remain hidden until they can be identified.

This update uses Chronicle's existing licensed catalog and game-client data. Loot that has not been documented or loaded remains unknown rather than receiving an estimated item name or drop chance.
