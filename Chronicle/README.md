# Chronicle Forever 1.5.65 für World of Warcraft: Forever

Dungeonbeute und Boss-Anzeigen-IDs in `AtlasLootForeverData.lua` wurden aus AtlasLoot Forever übernommen (GPLv2; siehe `ATLASLOOT-LICENSE.txt`). Boss-Porträts und Instanzkarten benötigen kein anderes Addon: Chronicle verwendet Grafiken des WoW-Clients und zeigt eine eigene schematische Bossübersicht, wenn für eine Instanz kein Kartenbild verfügbar ist. Die Karten für Halle der Thane und Ruinen von Lordaeron stammen von Santiago Reyes, Projekt „Atlas de Azeroth: Forever“, und sind mit Erlaubnis des Urhebers enthalten. Sie sind künstlerische Interpretationen der Beta-Instanzen und keine offiziellen Blizzard-Karten.

Weitere bereits vorhandene AzerothCompendium-Karten können für eine persönliche lokale Installation mit `work/install_personal_compendium_maps.py` in den eigenen Chronicle-Ordner kopiert werden. Diese zusätzlichen Karten sind nicht Teil des Release-Pakets.

Chronicle Forever ist das persönliche Gedächtnis deines Charakters. Es sammelt Reiseereignisse automatisch, soweit die öffentliche Addon API sie bereitstellt, und zeigt sie in einem kompakten Fenster im klassischen WoW Stil.

## Installation

1. Den Ordner `Chronicle` nach `World of Warcraft/_classic_beta_/Interface/AddOns/` kopieren.
2. Prüfen, dass `Chronicle/Chronicle_Camelot.toc` direkt in diesem Ordner liegt.
3. In der Charakterauswahl Chronicle aktivieren und die Option für veraltete Addons nur verwenden, falls ein späterer Beta Build eine neue Interface Nummer trägt.
4. Im Spiel `/chronicle` oder `/chr` eingeben.

## Funktionen

- Death Journal: erfasst neue Todesfälle über das Spielereignis `PLAYER_DEAD`. Ältere Einträge mit Kampflog-Daten bleiben erhalten; neue Kampflog-Treffer sind wegen der Beta-API-Sperre derzeit nicht verfügbar.

- Instanzwissen und Raidwissen: Inhalte des Forever Encounter Journal mit Bildern, Bossen und Beute; sieben Classic-Raids sind zusätzlich als eingebauter Referenzkatalog mit 17 Kartenetagen enthalten. Die Raidkarten benötigen kein installiertes AzerothCompendium. Alle 34 im lokalen Forever-Katalog aufgeführten Dungeons erscheinen; fehlende Boss- und Beutedaten sind als Vorschau markiert. Für sieben frühe Instanzen enthält der handgepflegte Katalog zusätzlich Fraktionsquests und Belohnungen.

- Eigene Wissensseiten für Sammeln und Trainer mit Suche, Rangtafeln und Zauberübersicht. Sammeln erfasst Erze, Kräuter und Kürschnerfunde; jeder Beruf hat ein eigenes Motiv in der Rangtafel.
- „Instanzwissen“ unter Wissen zeigt sieben Instanzen mit Bossen, Quests und Beute aus dem vom Nutzer bereitgestellten Forever Dungeon Journal v1.3.0 von Exehn. Chronicle zeigt die Instanzen mit eigenen Ladebildern sowie Boss-, Quest- und Beutedetails vollständig im eigenen Fenster. Dungeon-Quests zeigen Erfahrung, Geld und Ruf getrennt; Erfahrungswerte stammen aus dem Katalog und können im Spiel abweichen. Das separate Addon ist dafür nicht erforderlich. Es erscheinen nur Quests der eigenen Fraktion und fraktionsübergreifende Quests. Ein sichtbarer Zurück-Knopf führt zur Instanzübersicht. Die Quelltexte zu Quests und Gegenständen sind überwiegend englisch.
- Sammelübersicht mit getrennten Rangtafeln für Erz und Kräuter, Chronikpunkten, Sitzungswerten und Funddetails.
- Trainerübersicht mit integrierten Klassenzaubern, Rängen und Lernstufen schon vor dem ersten Trainerbesuch. Preise und tatsächliche Verfügbarkeit werden beim Klassentrainer ergänzt. Datenquelle und Grenzen stehen in `TRAINER-DATA-SOURCES.md`.

- „Wo war ich?“ Startseite mit Ort, Sitzung, Vermögen, anklickbaren Kennzahlen, bis zu drei offenen Zielen und letzten Erinnerungen
- Dungeons und Bosskämpfe mit neuer Bossbeute-Ansicht, Empfänger und Gegenstands-Tooltips; Instanzkarten öffnen ein eigenes Bosskapitel-Fenster
- Instanzkarten mit zugeschnittenen Original-Ladebildern aus dem Forever-Client; die 37 im aktuellen Build verfügbaren Bilder stammen aus der Client-Auswertung auf https://wowforevertalents.com/dungeons/. Für Instanzen ohne Ladebild bleibt das bisherige Motiv.
- Ziele mit anklickbarem Erledigt-Status und Entfernen sowie persönliche Notizen mit Bearbeiten und Löschen
- Eigene goldbraune Medaillons für die leeren Ziele- und Notizenseiten
- Abenteuer-Chronik mit Tagesabschnitten, Ereigniskarten, Kategorien, Filtern und aufklappbaren Serien gleichzeitig angenommener Quests
- Beute & Rares mit Filtern, eigener Suche, Gegenstands-Tooltips und Rare-Journal mit Sichtungsdetails; Begleiter werden nicht als NPC gezählt
- Gebietserinnerungen mit Erstbesuch, Besuchszahl, letztem Besuch und Untergebiet
- Gelernte Rezepte werden beim Öffnen des eigenen Berufsfensters erfasst und durchsuchbar gespeichert.
- Inventar- und Bank-Schnappschüsse mit Erfassungszeit, Stückzahlen, Händlerverkaufspreisen, Gegenstandsicons, Qualitätsfarben und Filtern
- Kompaktes Death Journal mit anklickbarer Zeitlinie und Gedenktafel für Ort und Zeitpunkt; ältere Einträge behalten vorhandene Gegner- und Kampfdaten
- Goldänderungen und Wirtschaftsverlauf als anklickbare Zeitlinie mit Detailtafel, grünen Plusbeträgen, roten Minusbeträgen sowie Einnahmen, Ausgaben, Bilanz und Tagesbilanzen der angezeigten Buchungen
- accountweite Übersicht der bereits geladenen Charaktere mit Gilde, Skillung, Quests, Zielen, Berufen, Erinnerungen und Goldständen; Charakterkarten öffnen Detailansichten
- Statistiken und Suche über die Chronicle Module
- Addon Compartment Eintrag und Slash Befehle
- Verschiebbarer Minimap-Button mit Lotus-Symbol; Klick öffnet oder schließt Chronicle. Der Tooltip folgt der gewählten Addon-Sprache.
- frei an allen Kanten und Ecken skalierbares Fenster mit gespeicherter Groesse
- Datenmigration vom enthaltenen 0.1.0 MVP

## Befehle

- `/chronicle` oder `/chr` – Fenster öffnen oder schließen
- `/chr goal Text` – Ziel anlegen
- `/chr note Text` – Notiz speichern
- `/chr notes` – Notizseite direkt öffnen
- `/chr debug` – geladene Version und Anzahl der Notizen anzeigen
- `/chr repair` – Charakterjournal neu erkennen und die Notizseite öffnen
- `/chr resetpos` – Fenster zentrieren
- `/chr help` – Hilfe anzeigen

## API und Grenzen

Das Paket zielt auf Forever Beta mit Interface `16001` und dem Client Suffix `_Camelot`. Unsichere APIs werden vor Verwendung geprüft. Chronicle liest nur öffentlich angebotene Ereignisse und Daten und führt keine Aktionen im Kampf aus.

Einige Informationen entstehen erst, wenn der Spieler sie sieht: Die Bank wird beim Öffnen gespeichert, NPCs beim Anvisieren und Händler beim Besuch. Historische Daten von vor der Installation können nicht rückwirkend ermittelt werden. Die Rezeptliste wird aufgebaut, wenn das eigene Berufsfenster geöffnet wird und Forever die TradeSkill-API bereitstellt. Vor der ersten Erfassung sind noch keine Rezepte sichtbar.

Die Beutehistorie erfasst positive Änderungen in den eigenen Taschen. Dazu gehören auch gekaufte oder als Questbelohnung erhaltene Gegenstände; sie ist daher genauer als ein ungefilterter Loot-Chat, aber keine reine Gegnerbeute-Liste. Beim ersten Taschenereignis nach dem Login wird nur ein Ausgangsstand erstellt, falls die Container-API beim Login noch nicht bereit war.
In **Beute & Rares** werden nur Questgegenstände und Gegenstände mindestens grüner Qualität angezeigt. Gewöhnliche Gegenstände bleiben für das Inventargedächtnis verfügbar, erscheinen aber nicht in der Beuteansicht, der Beutesuche oder der Beutestatistik.

## Datenspeicherung

`ChronicleDB` speichert accountweite Charakterzusammenfassungen, Einstellungen und die nach Charakter getrennten Journale. `ChronicleNotesDB` hält Notizen zusätzlich als eigenständige accountweite SavedVariable vor und wird bei jedem Laden mit dem Journal abgeglichen. `ChronicleCharDB` bleibt als kompatibler Spiegel erhalten. Listen besitzen Obergrenzen, damit die SavedVariables über längere Spielzeit kontrolliert wachsen.

`Recovery.lua` und `DeathRecovery.lua` sind optionale lokale Sicherheitsnetze. Das Release-ZIP enthält nur leere Vorlagen. Wenn diese Dateien in einer vorhandenen Installation persönliche Sicherungsdaten enthalten, vor einem Update separat sichern und die Vorlagen nicht darüber kopieren.

### Forever Beta: Datensicherung

In der für Version 1.5.40 getesteten Forever-Beta-Installation bleiben Notizen und Ziele nach `/reload` und vollständigem Neustart erhalten. Frühere Beta-Builds hatten zeitweise Probleme beim erneuten Laden von SavedVariables. Sichere vor Updates den `WTF`-Ordner und gegebenenfalls vorhandene `Recovery.lua`- und `DeathRecovery.lua`-Dateien.

Lokale Windows-Recovery-Skripte mit fest eingetragenen Installations- und Accountpfaden gehören nicht zum öffentlichen Paket. Das ZIP enthält weder diese Skripte noch persönliche Spielstände.

## Fehler melden

Bitte Forever Build, Sprache, genaue Handlung, Lua Fehlermeldung und die Schritte zur Reproduktion angeben. Vor Tests eine Sicherung von `WTF/Account/.../SavedVariables/Chronicle.lua` anlegen.
