# Recherche und Entscheidungen

Abruf: **28. September 2026**. Die Hauptseite nennt als redaktionelles Aktualisierungsdatum 05.04.2024; der aktuell abrufbare Inhalt enthält auch Phase-4-Bücher. „Aktuell recherchiert“ bedeutet hier erneuter Abruf, nicht eine neue redaktionelle Veröffentlichung.

## Fundorte

- Hauptquelle, sämtliche 40 Buchtitel und regulären Koordinaten: https://www.wowhead.com/classic/guide/season-of-discovery/classes/mage/icy-veins-rune
- Phasenbedingung für The Liminal and the Arcane: https://www.wowhead.com/classic/item=220347/the-liminal-and-the-arcane
- Stonewrought Design, Kommentar zum Altar: https://www.wowhead.com/classic/item=220349/stonewrought-design
- Magma or Lava?, Beschreibung nahe Lothos: https://www.wowhead.com/classic/item=228133/magma-or-lava
- A Study of the Light, Bestätigung der Kapelle: https://www.wowhead.com/classic/item=228135/a-study-of-the-light
- Ergänzende, nicht als präziser Buchfundort verifizierte Blackrock-Referenz 29.0 / 28.9 in Burning Steppes: https://wow4ever.quest/en/articles/libros-de-la-biblioteca-wow-forever (aktuell indexierter Seitenauszug; direkter Abruf nicht verfügbar). Diese Quelle kennzeichnet den Eintrag selbst als noch zu bestätigen.

## Bewusst behandelte Unstimmigkeiten

1. **A Study of the Light:** Ab Version 1.1.3 wird die vom Nutzer auf der Weltkarte der Forever-Beta beobachtete Kapellenposition ca. 71.0 / 49.0 auf Karte 1423 verwendet. Der Nutzer war noch nicht vor Ort. Deshalb ist dies ein Orientierungspunkt für die Kapelle, keine bestätigte Buchposition. Der Buchhinweis bleibt: hinten links in der Kapelle. Frühere SoD-Angaben (Tabelle 81.7 / 57.8, Fließtext 73.0 / 65.0) werden für diesen Pin nicht mehr verwendet.
2. **Rumi:** Thelsamar 35.6 / 48.9 gehört zu Loch Modan (1432), Sentinel Hill 52.7 / 53.8 zu Westfall (1436). Ein Benutzerkommentar vertauscht diese Zonen. Verwendet werden die Angaben im Haupttext. Beide Orte stehen im Datensatz, zählen aber als ein Buch.
3. **Secrets of the Dreamers:** 52.8 / 54.7 wird im Detailtext als Innenkoordinate genannt. Der Außenkartenpin nutzt den dort ausdrücklich genannten Zugang 46.0 / 36.5 auf 1413. Die Innenkoordinate bleibt im Tooltip. Kein Pin bei 52.8 / 54.7 im Freiland oder auf der Kontinentkarte 1414.
4. **Blackrock:** Stonewrought Design hat im Guide keine numerische Koordinate; Magma or Lava? nennt 48.4 / 63.6 ohne Forever-UiMapID. Beide liegen laut Detailtext außerhalb der Instanz. Der geprüfte Forever-UiMap-Datensatz enthält keine passende Innenkarte. Beide Bücher teilen sich daher die als ungefähr gekennzeichnete Referenz 1428:29.0/28.9. Keine erfundene Dungeon-MapID und kein Anspruch auf exakte Minimap-Position im Inneren.
5. **Searing Gorge:** A Mind of Metal steht im Guide versehentlich in der Kalimdor-Tabelle. Die Zuordnung ist 1427, Östliche Königreiche.
6. **The Liminal and the Arcane:** Der Gegenstandskommentar präzisiert die SoD-Alptraum-Version von Feralas. Die Benutzerannahme identischer Fundorte genügt nicht zur Bestätigung dieser Phase in Forever. Ein gekennzeichneter, abschaltbarer Referenzeintrag bleibt enthalten.
7. **Crimes Against Anatomy:** 16.7 / 28.5 aus dem Haupttext; fehlerhafte Koordinaten aus der Kommentar-Sammelliste werden nicht übernommen.
8. Rune Broker und Bibliotheks-NPCs sind keine Buch-/Scroll-Fundorte und gehören nicht zum Datensatz. Keine SoD-Runenbelohnungen oder SoD-Questabschlüsse werden für Forever versprochen.

## Technische Primärquellen

- HandyNotes API-Vertrag und Callback-Aufrufe im Maintainer-Quellcode: https://github.com/Nevcairiel/HandyNotes/blob/master/HandyNotes.lua
- Forever-Addon mit Interface 16001: https://github.com/cjber/shortest-path-forever/blob/main/ShortestPathForever.toc
- Aktuelle Build-Liste: https://wago.tools/api/builds (neuester gefundener 1.60-Build: 1.60.1.70009 vom 24.09.2026).
- Extrahierte Client-UiMap-Tabelle: https://wago.tools/db2/UiMap/csv?build=1.60.1.70009

Die UiMap-Tabelle bestätigt die Nummern und Elternkarten der verwendeten Zonen, nicht das tatsächliche Vorhandensein einzelner Bücher im Spiel. Die Koordinaten bleiben SoD-Daten, sofern nicht ausdrücklich als ergänzende Referenz ausgewiesen.

## Eigenes Icon

Erstellt mit dem eingebauten Imagegen-Werkzeug; keine übernommenen Blizzard-Icon-Dateien. Das generierte PNG wurde nur für die Addon-Verwendung auf 128 × 128 skaliert und als unkomprimiertes 32-bit-TGA mit Alpha gespeichert. Das Original ist mitgeliefert.

Finaler Generierungsprompt:

> Create one original square fantasy spellbook addon icon for HandyNotes - Forever Books. Single closed deep blue leather grimoire, aged gold corner clasps, luminous cyan rune shaped like a simple star on the cover, a small violet ribbon bookmark, slight three-quarter perspective. Hand-painted polished fantasy game inventory art, bold readable silhouette at 32 pixels, centered object occupying 85% of canvas, restrained magical glow, clean transparent background. No text, no letters, no watermark, no existing game logo. Output square raster image.


## Fortschrittserkennung, Version 1.1.0 (29.09.2026)

Die 40 Gegenstands-IDs wurden aus den strukturierten Item-Daten des erneut abgerufenen WoWHead-Guides extrahiert und eindeutig den Buchtiteln zugeordnet. Keine Quest- oder Objekt-ID wird als Item-ID verwendet. Die Zuordnung liegt in `items.lua`. Die Verwendung dieser IDs in Forever ist noch nicht im Spiel verifiziert.

Primärquelle für den Inventarzugriff und BAG_UPDATE_DELAYED:
https://github.com/Gethe/wow-ui-source/blob/classic_beta/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua

Die automatische Erkennung verwendet C_Container.GetContainerNumSlots und C_Container.GetContainerItemID für die getragenen Taschen. Fremde Beutemeldungen werden nicht ausgewertet. Ein grüner Haken verwendet die eingebaute WoW-Textur Interface/RaidFrame/ReadyCheck-Ready. Die Lua-5.1-Verhaltenstests wurden um Inventaränderungen, ignorierte Fremd-Items, manuelle Ausnahmen, Klick-Guards, getrennte Charakterdaten, alternative Fundorte und die getrennte Auswahl am Blackrock-Pin erweitert und bestanden. Ingame-Test weiterhin ausstehend.
