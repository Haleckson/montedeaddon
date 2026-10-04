local _, ns = ...

-- Coordinates are percentages on Classic/Forever UiMapIDs, NOT old MapAreaIDs.
-- Research: 2026-09-28. See SOURCES.md for conflicts and cave reference pins.
-- Stable book IDs are independent of coordinates; Rumi has two locations.
ns.books = {}
ns.locations = {}
local function book(id, title, map, x, y, description, faction, kind)
    ns.books[id] = ns.books[id] or { id = id, title = title, faction = faction }
    ns.locations[#ns.locations + 1] = {
        book = id, map = map, x = x, y = y,
        description = description, kind = kind or "book",
    }
end

book("defensive", "Defensive Magics 101", 1416, 48.5, 57.6, "Gallows' Corner: The first tower that you encounter entering the ogre fortress from either the Tarren Mill direction or the Strahnbrad direction is the one you are looking for.")

book("web", "A Web of Lies: Debunking Myths and Legends", 1417, 73.0, 65.0, "Witherbark Village: Loot the Scrolls outside a tent, toward the hut.")

book("mummies", "Mummies: A Guide to the Unsavory Undead", 1418, 57.0, 39.0, "Loot Scrolls from the Crypt on the south foothills of the butte to receive Mummies: A Guide to the Unsavory Undead Mummies: A Guide to the Unsavory Undead. The path to the Crypt starts at around /way 56.0, 45.0. If you find a small dwarven camp, the Crypt is directly above it.")
-- Shared reference point: the guide supplies no usable Forever map coordinate
-- for these interiors. Never put 48.4/63.6 on the Burning Steppes zone map.

book("stonewrought", "Stonewrought Design", 1428, 29.0, 28.9, "Center Vault, Blackrock Mountain, Enter the center vault in Blackrock Mountain.\nHead down one floor. The book is on a large platform in the middle of the room.", nil, "reference")

book("conjurer", "Conjurer's Codex", 1419, 55.3, 32.2, "Fundort laut Übersicht des WoWHead-Guides.")

book("magma", "Magma or Lava?", 1428, 29.0, 28.9, "Blackrock Mountain: From the center vault, head past the summoning stone and down the chain.\nTurn through the doorway on your right before you reach (but as you face) Lothos Riftwaker. Hug the wall to the right and a few steps in the book will be on the platform in front of you.", nil, "reference")

book("anatomy", "Crimes Against Anatomy", 1431, 16.7, 28.5, "Raven Hill: Loot the Spellbook in the Dawning Wood Catacombs after entering from the crypt on the west side of the map")

book("light", "A Study of the Light", 1423, 71.0, 49.0, "Light's Hope Chapel. Approximate chapel location from the Forever beta world map; exact book position not verified. Inside the chapel, at the back on the left side.", nil, "reference")

book("scourge", "Scourge: Undead Menace or Misunderstood?", 1423, 31.3, 21.0, "Before you cross the bridge to the entrance of Stratholme, there is a table by some gibbets on the right.")

book("knight", "The Knight and the Lady", 1423, 54.5, 50.8, "Just there")

book("theocritus", "Archmage Theocritus's Research Journal", 1429, 65.4, 70.1, "Tower of Azora: Loot the Library Book from a table about halfway up the tower", "Alliance")

book("venomous", "Venomous Journeys", 1425, 36.0, 72.7, "Shadra'Alor.")

book("antonidas", "Archmage Antonidas: The Unabridged Autobiography", 1455, 76.3, 10.8, "Hall of Explorers: Loot Library Book from a table in the center of the Hall.", "Alliance")

book("rumi", "Rumi of Gnomeregan: The Collected Works", 1432, 35.6, 48.9, "Thelsamar: Loot the Gnomish Tome from the upstairs floor in the inn. ", "Alliance")

book("rumi", "Rumi of Gnomeregan: The Collected Works", 1436, 52.7, 53.8, "Sentinel Hill: Loot Gnomish Tome from the Inn, on a table behind the innkeeper.", "Alliance")

book("runes", "Runes of the Sorcerer-Kings", 1432, 77.5, 14.1, "Mo'Grosh Stronghold: Loot the Scrolls from the Ogre cave.")

book("ataeric", "Ataeric: On Arcane Curiosities", 1421, 43.4, 41.2, "The Sepulcher: Loot the Arcane Secrets from inside the tomb, on the table near Sebastian Meloche.", "Horde")

book("digest", "The Dalaran Digest, Vol. 23", 1421, 63.5, 63.1, "Amber Mill: Loot the Dalaran Digest from a bookshelf in the north east corner of the main hall.")

book("basilisks", "Basilisks: Should Petrification be Feared?", 1434, 41.5, 50.8, "Crystalvein Mine: Loot the Research Notes from a wooden platform to the right of the cave entrance.")

book("ludite", "A Ludite's Guide to Caring for Your Demonic Pet", 1435, 61.0, 22.0, "Fallow Sanctuary: Farm Lost Ones to get a Rusted Cage Key Rusted Cage Key to open a cage at the location. Loot the Book from inside the cage.")

book("sanguine", "Sanguine Sorcery", 1435, 70.0, 51.0, "Pool of Tears.")

book("apothecary", "The Apothecary's Metaphysical Primer", 1420, 59.5, 52.3, "Brill: Loot the Apothecary Society Primer from the Alchemy Shop, on the shelf next to Apothecary Johaan.", "Horde")

book("necromancy", "Necromancy 101", 1422, 69.4, 72.8, "Caer Darrow; On the very top of Scholomance. Enter the main building and turn right. Then take every opportunity to go up. The book is on a table, in a room at the top.")

book("potatoes", "Undead Potatoes", 1422, 38.3, 54.6, "Felstone Field: In Janice Felstone's Farmhouse, at the top of the stairs.")

book("bewitchments", "Bewitchments and Glamours", 1436, 45.4, 70.5, "Moonbrook: Loot the Spellbook from the bookshelf in the first house on the left as you enter Moonbrook.")

book("goaz", "Goaz Scrolls", 1437, 33.6, 47.9, "Whelgar's Excavation Site: Loot the Scrolls from inside an urn on the lowest level of the Excavation Site.")

book("etiquette", "Everyday Etiquette", 1447, 20.7, 62.0, "Haldarr Encampment.")

book("almanac", "Nar'thalas Almanac, Vol. 74", 1439, 59.6, 22.2, "Ruins of Mathystra: Loot the Scrolls from down the stairs, on the 3rd landing, within the ruins.")

book("demons", "Demons and You", 1443, 55.0, 28.0, "Thunder Axe Fortress: Loot the Mysterious Book from inside the big building, on a bench against a wall.")

book("rwl", "RwlRwlRwlRwl!", 1445, 57.0, 21.0, "Witch Hill: Loot the Waterlogged Book from the ground at the eastern edge of the Murloc camp.")

book("northern", "Northern Kalimdor - A Comprehensive Guide", 1448, 65.2, 3.2, "Timbermaw Hold: Inside Timbermaw Hold next to the bridge above the vendor.")

book("liminal", "The Liminal and the Arcane", 1444, 50.6, 15.7, "SoD: Alptraum-/Smaragdtraum-Version von Feralas. Vorkommen in Forever unbestätigt; kein gesicherter Fundort im normalen Feralas.", nil, "uncertain")

book("tazo", "The Lessons of Ta'zo", 1454, 38.7, 78.4, "Valley of Spirits: Interact with the large tablet just before the Darkbriar Lodge sign to  Trace Ta'zo Mural.", "Horde")
-- Searing Gorge is Eastern Kingdoms, despite the guide's Kalimdor table.

book("metal", "A Mind of Metal", 1427, 37.8, 49.6, "The Cauldron.")

book("fury", "Fury of the Land", 1442, 74.4, 85.7, "Grimtotem Camp: Loot the Scrolls from on top of a barrel inside one of the tents.")

book("tidesages", "Legends of the Tidesages", 1446, 72.6, 47.8, "Lost Rigger Cove.")

book("arcanic", "Arcanic Systems Manual", 1413, 56.3, 8.8, "The Sludge Fen: Loot the Manual from a chair in the control room at the top of the Oil Rig.")

book("baxtan", "Baxtan: On Destructive Magics", 1413, 62.7, 36.3, "Ratchet: Loot the Goblin Tome which is next to Gazlowe in the Engineering building.")
-- 52.8/54.7 is an interior reference, not a Barrens surface coordinate.

book("dreamers", "Secrets of the Dreamers", 1413, 46.0, 36.5, "Make your way to the cave system that houses the Wailing Caverns dungeon in Lushwater Oasis, the Barrens. Once you enter the cave system, make your way to the Cavern of Mists which is where the dungeon entrance is. On the Minimap, the Book is at the eastern site of the cave.", nil, "entrance")

book("geomancy", "Geomancy: The Stone-Cold Truth", 1441, 34.0, 40.0, "Darkcloud Pinnacle: Loot the Scrolls from inside the largest hut on Darkcloud Pinnacle; Aufstieg bei 31.0 / 37.0.")

book("kaboom", "Ka-Boom!", 1452, 60.7, 37.7, "Everlook: Inside the Alchemy building.")
