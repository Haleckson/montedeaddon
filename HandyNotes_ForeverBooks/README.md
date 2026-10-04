# HandyNotes - Forever Books

Version 1.1.3 · Recherche: 28.09.2026 · Ziel: WoW Forever Beta 1.60.1 / Interface 16001

## Installation

1. WoW vollständig beenden.
2. Die ZIP direkt in den Ordner `Interface/AddOns` deiner Forever-Installation entpacken (in der Battle.net-Beta gewöhnlich `_classic_beta_/Interface/AddOns`).
3. Danach muss `Interface/AddOns/HandyNotes_ForeverBooks/HandyNotes_ForeverBooks.toc` existieren. Keine zusätzliche ZIP- oder Versions-Unterordnerebene verwenden.
4. HandyNotes und „HandyNotes - Forever Books“ in der Addon-Liste aktivieren. HandyNotes muss bereits in einer für deinen Forever-Client funktionierenden Version installiert sein; es ist nicht im ZIP enthalten.

## Verwendung

Die Weltkarte einer Zone oder eines Kontinents öffnen oder auf der Minimap nach dem blauen Zauberbuch suchen. Darüberfahren zeigt Titel, Zone, Koordinaten und Fundorthinweis. Zwei Bücher am selben Orientierungspunkt teilen sich einen Tooltip.

Einstellungen: HandyNotes → Plugins → Forever Books. Einstellbar sind Weltkarte, Minimap, Kontinentkarten, Symbolgröße, Deckkraft, SoD-Fraktionsfilter und der unbestätigte Feralas-Eintrag. Standardmäßig sind alle Fraktionen und alle Einträge sichtbar. HandyNotes' globale Symbolgröße/Deckkraft wirkt zusätzlich.

`/fbooks` zeigt Hilfe, `/fbooks status` die Interface-Version und `/fbooks map` die aktuelle UiMapID. Die Fundorthinweise sind überwiegend englisch, einzelne Hinweise und die Einstellungen deutsch. Buchtitel bleiben im englischen Original. Zonennamen kommen lokalisiert aus dem Client.

## Bücher abhaken (neu in 1.1.0)

- **Shift + Linksklick auf einen Weltkartenpin:** als gefunden markieren. Erneut klicken, um die Markierung zurückzunehmen. Das funktioniert auch auf Kontinentkarten.
- **Grüner Haken:** dieses Buch wurde gefunden. Bei einem gemeinsamen Pin erscheint der Haken erst, wenn alle darin angezeigten Bücher gefunden wurden.
- **Blackrock-Sammelpin:** Shift-Linksklick öffnet eine Auswahl, damit du die beiden Bücher einzeln markieren kannst.
- **Automatisch:** Beim Einloggen und nach Taschenänderungen werden bekannte Bücher und Schriftrollen in deinen eigenen Taschen erkannt. Looten eines passenden Gegenstands setzt den Status. Die Erkennung ist in den Einstellungen abschaltbar. Gegenstände aus Handel/Post zählen ebenfalls als erhalten.
- **Sammelliste:** Unter HandyNotes → Plugins → Forever Books → Sammelliste kannst du alle 40 Bücher einzeln an- und abhaken, auch ausgeblendete Einträge.
- **Ausblenden:** „Gefundene Bücher ausblenden“ entfernt erledigte Pins. Zum erneuten Anzeigen diese Option deaktivieren oder den Eintrag in der Sammelliste zurücksetzen.
- **Pro Charakter:** Fortschritt wird getrennt gespeichert; allgemeine Anzeigeoptionen bleiben accountweit. Beide Rumi-Fundorte teilen denselben Buchstatus.

Manuelles Zurücksetzen hat Vorrang: Ein ausdrücklich abgewähltes Buch wird durch spätere Taschenscans nicht sofort wieder abgehakt, auch wenn es noch im Inventar liegt. Markiere es bei Bedarf erneut manuell.

Die automatische Zuordnung verwendet die 40 Gegenstands-IDs des WoWHead-Guides, unabhängig von der Sprache des Clients. Ob Forever alle diese SoD-IDs unverändert verwendet, wurde nicht im Spiel geprüft. Bei abweichenden IDs funktioniert weiterhin die manuelle Markierung; die Zuordnung ist in `items.lua` wartbar. Bereits vor der Installation verbrauchte oder abgegebene Bücher werden nicht rückwirkend erkannt. Das bloße Öffnen eines Beutefensters zählt nicht als Fund; das Buch muss im Inventar ankommen. Bankfächer werden nicht durchsucht.

Minimap-Pins zeigen denselben Fortschritt. Das manuelle Klicken ist für die Weltkarte implementiert, da HandyNotes Minimap-Klicks nicht in allen Versionen an Plugins weitergibt.

Zum Aktualisieren WoW beenden und den vorhandenen Addon-Ordner mit Version 1.1.3 überschreiben. Bestehende Anzeigeeinstellungen bleiben erhalten.

## Umfang und Datenqualität

Enthalten sind **40 verschiedene Buchtitel, 41 Standort-/Referenzeinträge und 40 Kartenpins**. Rumi hat zwei alternative Standorte. Die zwei Blackrock-Bücher teilen sich einen ausdrücklich gekennzeichneten Orientierungspin. Der Zugang zu Secrets of the Dreamers ist ebenfalls als solcher bezeichnet. A Study of the Light verwendet die vom Nutzer auf der Forever-Beta-Weltkarte beobachtete ungefähre Kapellenposition 71.0 / 49.0 als Orientierungspunkt; die Buchposition ist nicht vor Ort bestätigt. Gefundene Bücher werden pro Charakter gespeichert. Der Status bedeutet „erhalten / manuell bestätigt“, nicht „gelesen oder abgegeben“. SoD-Quest-IDs werden nicht ungeprüft auf Forever übertragen.

Die SoD-Fundorte werden entsprechend deiner Vorgabe für Forever verwendet. Ein Sonderfall ist **The Liminal and the Arcane**: Die Quelle verortet es in einer SoD-Alptraum-Phase. Sein Forever-Vorkommen ist unbestätigt; der Pin weist darauf hin und kann ausgeblendet werden. Fraktionsbeschränkungen sind ebenfalls Angaben aus SoD.

Die Forever-Kartentabelle enthält keine eigene Blackrock-/Cavern-of-Mists-Karte. Deshalb sind Innenkoordinaten nicht einfach auf die Außenkarte übertragen. Die Blackrock-Markierung ist nur ein ungefährer Orientierungspunkt; beide Tooltips beschreiben den Weg. Einzelheiten und Quellen stehen in [SOURCES.md](SOURCES.md), alle Einträge in [LOCATIONS.md](LOCATIONS.md).

## Kompatibilität und Prüfung

Implementiert mit HandyNotes' `RegisterPluginDB`, `GetNodes2`, Pin-Tooltips und `HandyNotes_NotifyUpdate`. Keine mitgelieferten Bibliothekskopien, kein veraltetes `GetCurrentMapAreaID` und keine Retail-Zonenkoordinaten. Die UiMapIDs wurden gegen die veröffentlichten Clientdaten für Forever **1.60.1.70009** geprüft. Fehlende Karten werden mit einer Meldung ausgelassen.

Lua-5.1-Syntax und Verhalten wurden mit nachgebildeten WoW-/HandyNotes-Schnittstellen getestet: Initialisierung, Shift-Klicks, automatische Inventarerkennung, manuelle Ausnahmen, charakterbezogene Speicherung, Blackrock-Auswahl, Fortschrittsfilter, Koordinatenkodierung, Karten- und Minimap-Iteratoren, Filter, Tooltips, gemeinsame Pins und beschädigte Einstellungen. **Ein Test im laufenden WoW-Forever-Client war hier nicht möglich.** Die tatsächliche Darstellung hängt auch von der installierten HandyNotes-/HereBeDragons-Version ab.

Nach einem Beta-Update kann die Interface-Version wechseln. Mit `/dump (select(4, GetBuildInfo()))` prüfen. Bei bloßer Versionswarnung kann „Veraltete Addons laden“ helfen; das behebt keine API-Änderungen. Bei einem Fehler bitte die erste Lua-Fehlermeldung, `/fbooks status` und die HandyNotes-Version erfassen.

## Wartung

- `nodes.lua`: Titel, stabile Buch-IDs, UiMapIDs, Koordinaten und Fundorthinweise.
- `core.lua`: Registrierung, gruppierte Pins, Karten-Iteratoren, Tooltips, Diagnose.
- `items.lua`: sprachunabhängige Gegenstands-ID-Zuordnung.
- `tracking.lua`: charakterbezogener Fortschritt, Taschenscan und Buchauswahl.
- `options.lua`: Standardwerte und HandyNotes-Konfiguration.
- `media/ForeverBooks.tga`: eingebundenes 128 × 128 RGBA-Icon; PNG-Dateien als Vorschau und Original.
- `SOURCES.md`: Quellen und nachvollziehbare Entscheidungen bei Widersprüchen.

Neue Fundorte als `book(...)`-Zeile hinzufügen. Koordinaten sind Prozentwerte von 0 bis unter 100. Alternative Fundorte desselben Buches behalten dieselbe Buch-ID. `reference`, `entrance` oder `uncertain` als Typ verwenden, wenn kein gesicherter normaler Fundort vorliegt.
