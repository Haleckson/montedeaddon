# Credits

## Lore text

All lore text in Lorever is original writing by the Lorever project, set down in
the voice of the Warcraft chronicles. Facts are checked against the game itself,
*World of Warcraft: Chronicle*, Blizzard's novels and official articles, with the
Warcraft Wiki (warcraft.wiki.gg) as a guide to those sources. No text is copied
from the Warcraft Wiki or Wowpedia.

## Books and writings

Lorever ships no text of any in-game book, letter or inscription. When a player
reads one in the game, the game shows its pages, and the add-on keeps a copy on
that player's own computer only.

## Data sources (facts only)

The Literature catalogue (titles, kinds, places and map positions) and the map
pins of the figures were built by `tools/literature.py` and `tools/repin.py` from:

- **CMaNGOS classic-db** (github.com/cmangos/classic-db, GPL-3.0): object and NPC
  spawns, readable items, quests, loot and vendors. Only facts are used (IDs,
  names, positions); no SQL or table layout is shipped. Its `locales/Chinese`
  tables give the Chinese (zhCN) names of people, world books and quests used in
  the Chinese pages (`tools/zh_official.py`): names only, no quest or book text.
- **The game's own map and area tables** (UiMap, UiMapAssignment, AreaTable, as
  published by wago.tools), to turn world positions into map positions and to
  know every subzone in every client language.

No website is scraped, and no data is taken from other add-ons. Places these
sources do not know come from Lorever players' own community reports.

## Trademarks

World of Warcraft, Warcraft and Blizzard Entertainment are trademarks or
registered trademarks of Blizzard Entertainment, Inc. Lorever is not made,
endorsed or supported by Blizzard Entertainment.
