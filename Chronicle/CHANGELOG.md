# Changelog

## 1.5.65 – 2026-10-03

- Raidwissen bietet nun einen Kartenreiter für alle sieben klassischen Raids im Katalog.
- 17 Raidkarten-Etagen aus dem lokal installierten AzerothCompendium als Chronicle-Dateien eingebunden; das Addon wird zur Laufzeit nicht benötigt.

## 1.5.64 – 2026-10-03

- Registrierung des im Beta-Client gesperrten Kampflog-Ereignisses entfernt, das die Blizzard-Sperrmeldung auslösen konnte.
- Gesundheitswert-Abfrage entfernt, die bei geschützten Werten Fehler erzeugte. Todesfälle werden weiterhin über `PLAYER_DEAD` erfasst; detaillierte Kampflog-Treffer sind bis zu einer zulässigen API nicht verfügbar.

## 1.5.63 – 2026-10-03

- Karten für Halle der Thane und Ruinen von Lordaeron mit Erlaubnis des Urhebers Santiago Reyes direkt eingebunden. Die Karten funktionieren ohne AzerothCompendium.
- Urheber und Projekt der beiden künstlerischen Beta-Karten in der Dokumentation genannt.

## 1.5.62 – 2026-10-03
- Instanzwissen kann lokale persönliche Kartenkopien direkt aus dem Chronicle-Ordner anzeigen; AzerothCompendium muss danach nicht installiert oder aktiv sein.
- Die lokale Beta-Installation erhält die vorhandenen AzerothCompendium-Karten mit einem eigenen Ladeeintrag. Das veröffentlichbare ZIP enthält keine fremden Kartenbilder.
- Ohne persönliche Kartenkopien bleiben Clientkarte und schematische Bossübersicht verfügbar.

## 1.5.61 – 2026-10-03
- AzerothCompendium als Laufzeitvoraussetzung für Boss-Porträts und Karten entfernt. Bekannte Bossmodelle werden direkt aus dem WoW-Client gerendert.
- Die Instanzkarte zeigt verfügbare Client-Etagen auch ohne weiteres Addon. Für Instanzen ohne Client-Kartenbild gibt es eine eigenständige, als schematisch gekennzeichnete Bossübersicht statt einer leeren Karte.
- Überschriften und Hinweise der Kartenansicht in allen unterstützten Addon-Sprachen ergänzt.

## 1.5.60 – 2026-10-03
- Boss-Porträts in Instanzwissen mit den Anzeigen-IDs des installierten AzerothCompendium verbunden, einschließlich aller vier Bosse der Halle der Thanen.
- Instanzkarten und Etagen aus dem installierten AzerothCompendium angezeigt, wenn es aktiv ist. Die Karte der Halle der Thanen ist dadurch erreichbar.
- Bei fehlendem AzerothCompendium bleiben die Karten des WoW-Clients als Ersatz verfügbar; fremde Bilddateien werden nicht ins Chronicle-Paket kopiert.

## 1.5.59 – 2026-10-03
- Vorhandene Dungeonbeute aus AtlasLoot Forever ergänzt: 27 Dungeon-Tabellen mit 1.702 Gegenstands-IDs; vorhandene Chronicle-Daten bleiben erhalten.
- Boss-Porträts aus den erfassten Anzeigen-IDs und Itemnamen in ihrer Qualitätsfarbe in Instanzwissen ergänzt. Die Darstellung aktualisiert sich, sobald Itemdaten des Clients geladen sind.
- Neuer Reiter „Instanzkarte“ mit mehreren Etagen, soweit der Forever-Client Kartenbilder bereitstellt. Keine Grafiken aus AzerothCompendium kopiert.
- Datenherkunft AtlasLoot Forever (GPLv2) in der Oberfläche angegeben; Lizenz dem Paket beigelegt.

## 1.5.58 – 2026-10-02
- Dungeonkatalog an die Stufe-30-Beta angepasst: Excavation Site: Wetlands (26–31), Razorfen Downs (25+) und Uldaman (30+).
- Beute aus dem aktuellen Begegnungsjournal unterstützt jetzt auch die neue Journal-API und wird beim erneuten Öffnen nachgeladen, falls der Client Gegenstände zunächst verzögert liefert.
- Live-Journaleinträge ersetzen die älteren Classic-Referenzlisten; alternative Instanznamen werden dem vorhandenen Katalog zugeordnet.
- Für die neue Excavation Site werden keine unbestätigten Gegenstände als Beute ausgegeben.

## 1.5.57 – 2026-09-30
- Goldenen Rahmen und Eckmarkierungen um die hervorgehobene Instanzkarte in „Dungeons & Bosse“ wiederhergestellt.
- Dieselbe Kartendarstellung gilt für hervorgehobene Boss- und Beuteeinträge; normale Listenzeilen bleiben offen.

## 1.5.56 – 2026-09-30
- Questdossier der Zugangswege an die gerahmten Detailansichten angepasst: Questicon, dezentes Motiv und klar getrennte Abschnitte für Ziele, Questtext und Auftrag.
- Vollständige Clienttexte angenommener oder beim Questgeber geöffneter Zugangsquests werden angezeigt und für die spätere Ansicht gespeichert. Für noch nie gesehene Quests bleibt der historische Aufgabenhinweis sichtbar.
- Bildkarten in Instanzwissen und Raidwissen auf 88 Pixel Höhe verkleinert und Abstände sowie Bildausschnitte angepasst.

## 1.5.55 – 2026-09-30
- Goldene Dossierrahmen und Eckmarkierungen in Zugangswegen, Lehrer- und Waffenansichten sowie Quest-, NPC-, Charakter-, Inventar-, Chronik-, Todes- und Golddetails wiederhergestellt.
- Listenzeilen behalten die schlichte Gestaltung ohne zusätzliche Kästen.

## 1.5.54 – 2026-09-30
- Questliste und Questdossier der Zugangswege an die offene Gestaltung der übrigen Chronicle-Ansichten angepasst; zusätzliche Kästen entfernt.
- Höhe der Detailansicht an den sichtbaren Inhaltsbereich angepasst, damit der Aktionsknopf erreichbar bleibt.

## 1.5.53 – 2026-09-30
- Zugangswege zeigen Questschritte links und die ausgewählte Quest mit Zielen und verfügbarem Questtext rechts.
- Fehlende Rahmen der Questliste und Detailansicht ergänzt; Questgeber-Markierung und Gegenstandslinks bleiben erreichbar.

## 1.5.52 – 2026-09-30
- Fehler behoben, durch den sich aufgeklappte Questziele nicht wieder schließen ließen.

## 1.5.51 – 2026-09-30
- Gegenstands-Tooltips in den Zugangswegen am Mauszeiger verankert.
- Questschritte mit bestätigtem Abschluss dezent grün und offene Schritte rot hinterlegt; unprüfbare Zustände bleiben neutral.
- Questschritte lassen sich aufklappen: aktive Quests zeigen ihre aktuellen Ziele aus dem Questlog, noch nicht angenommene Quests einen kurzen historischen Aufgabenhinweis.

## 1.5.50 – 2026-09-30
- Schlüssel und andere Zugangsgegenstände in Questreihen als anklickbare WoW-Gegenstandslinks ergänzt: Tooltip beim Darüberfahren, Gegenstandsfenster per Klick und Chatlink per Umschalt-Klick.
- Quest- und Gegenstandsnamen werden bei Bedarf asynchron vom WoW-Client geladen und anschließend in der Zugangsansicht aktualisiert.
- Texte der Zugangswege in sieben Sprachen geprüft und Bezeichnungen für Gegenstände, Kartenaktionen und reine Schlüsselwege korrigiert.

## 1.5.49 – 2026-09-30
- Die Dungeon-Übersicht der Zugangswege zeigt nur noch Bereiche mit historischem Schlüssel oder Zugangsweg: Scharlachrotes Kloster (Waffenkammer/Kathedrale), Scholomance, Obere Schwarzfelsspitze und Düsterbruch (Nord/West).
- Wege für Abkürzungen, Seiteneingänge und Bossbeschwörungen aus der Dungeon-Übersicht entfernt; Raid-Übersicht unverändert.
- Der Beschreibungstext der Dungeon-Übersicht erläutert diese Auswahl in allen sieben Addon-Sprachen.

## 1.5.48 – 2026-09-30
- Bildkarten in der Zugangswege-Übersicht auf etwa halbe Höhe verkleinert; Bildausschnitt, Schrift und Abstände entsprechend angepasst.

## 1.5.47 – 2026-09-30
- Die Übersicht der Zugangswege zeigt Dungeons und Raids als zweispaltige Bildkarten mit den vorhandenen Chronicle-Ladebildern.
- Ein Klick auf eine Bildkarte öffnet direkt die zugehörige Questreihe.
- Questschritte erscheinen als ruhige Listenzeilen mit Trennlinien und einem Textlink zur Kartenmarkierung; Kopfbereich und Zurückknopf verwenden die Gestaltung der anderen Chronicle-Kategorien.

## 1.5.46 – 2026-09-30
- Zugangswege öffnen als eigene Detailansicht im Chronicle-Hauptfenster mit passendem Kopfbereich, Questkarten und Zurückknopf.
- Kartenknöpfe setzen für erfasste Questgeber einen WoW-Wegpunkt und öffnen die passende Gebietskarte, auch wenn die Quest noch nicht angenommen wurde.
- Für alle drei Naxxramas-Varianten führt der Kartenknopf zum Startpunkt bei der Kapelle des Hoffnungsvollen Lichts.
- Questgeber-Wegpunkte werden ausdrücklich als Startpunkte statt Questziele beschrieben; fehlende verlässliche Positionen erhalten einen klaren Hinweis.

## 1.5.45 – 2026-09-30
- Historische Zugangs- und Schlüsselketten um die relevanten Questschritte für Onyxia, Scholomance, Maraudon, Schwarzfelstiefen und weitere Instanzen ergänzt.
- Allianz- und Hordevarianten werden getrennt; alternative Questfassungen für Geschmolzener Kern und Naxxramas sind als Alternativen gekennzeichnet.
- Eigene Quest- und Gegenstandstitel ersetzen leere Anzeigen wie „Quest #7848“, wenn der Client keinen Namen liefert.
- Detailfenster für lange Questketten scrollbar gemacht; jede Quest behält ihren Kartenknopf.
- Schlüssel und Gegenstände ohne Questweg separat als historische Hinweise angezeigt.

## 1.5.44 – 2026-09-30
- Klick auf einen Dungeon oder Raid in „Zugangswege“ öffnet ein eigenes, verschiebbares Detailfenster.
- Zugehörige Questschritte und Schlüssel werden dort mit dem erfassten Status angezeigt.
- Jede Quest besitzt einen Kartenknopf. Aktive Quests öffnen ihre Details auf der WoW-Karte; ohne Kartendaten erscheint ein verständlicher Hinweis.

## 1.5.43 – 2026-09-30
- Neue Wissensseite „Zugangswege“ für alle Dungeons und Raids im Katalog ergänzt.
- Historische Quest- und Schlüsselwege zeigen belegbare Questabschlüsse, aktive Quests und vorhandene Gegenstände sowie den nächsten prüfbaren Schritt.
- Forever-Zugangsregeln werden ausdrücklich als unbestätigt gekennzeichnet; fehlende Beta-Daten bleiben offen statt einen gesperrten oder freigeschalteten Zugang vorzutäuschen.
- Seite und Statushinweise in allen sieben Addon-Sprachen ergänzt.

## 1.5.42 – 2026-09-30
- Leere Ziele-Ansicht: rotes Standardsymbol durch ein eigenes goldbraunes Ziele-Medaillon ersetzt.
- Medaillon und Zierlinien entsprechen nun dem Layout der Notizen-Ansicht.

## 1.5.41 – 2026-09-30
- Verschiebbaren Minimap-Button mit Lotus-Symbol ergänzt; Linksklick öffnet oder schließt Chronicle.
- Tooltip für Klick und Verschieben folgt der gewählten Addon-Sprache in allen sieben unterstützten Sprachen.
- Position des Minimap-Buttons wird accountweit gespeichert.

## 1.5.40 – 2026-09-30
- Kampflog: Nicht-Schadensereignisse werden vor der Abfrage der Spieler-GUID verworfen.
- Inventar und Bank: unveränderte Taschen-Snapshots lösen keine unnötige Neuzeichnung aus; neue Beute wird weiterhin erfasst.
- Release-Paket und TOC-Dateien auf Vollständigkeit geprüft; persönliche Recovery-Daten bleiben außerhalb des Pakets.
- Öffentliche README entfernt Verweise auf lokale Recovery-Helfer mit fest eingetragenem Windows-Accountpfad.

## 1.5.39 – 2026-09-29
- Sichtbarer Addon-Name in Fenster, Addon-Liste, Chatmeldungen und Stufenhinweis: Chronicle Forever.
- Characters: Karten, Charakterprofil, Talente und gespeicherte Ereignis-Präfixe folgen der gewählten Sprache.
- Inventory & Bank: Filter, Fundgruppen und Besitzdossier folgen der gewählten Sprache.
- Death Journal: unveränderte historische Kampflog-Daten und gespeicherte Ortsnamen bleiben erhalten.
- Release-ZIP enthält die beiden leeren Recovery-Vorlagen, die in den TOC-Dateien geladen werden; persönliche Sicherungen gehören nicht ins Paket.

## 1.5.38 – 2026-09-29
- Notes: eigenes goldbraunes Medaillon mit Schriftrolle, Buch und Feder im Stil der Dungeon-Medaillons ergänzt.
- Leere Notes-Ansicht zeigt das Medaillon größer und mit dezenten Zierlinien.

## 1.5.37 – 2026-09-29
- Berufe & Rezepte: Berufsnamen, Fortschritt, Rezeptzahlen und Tooltips folgen der Sprachauswahl; gespeicherte Berufs- und Rezeptdaten bleiben erhalten.
- Leere Rezeptansicht und zuletzt gelernte Rezepte aktualisieren ihre festen Texte nach einem Sprachwechsel.

## 1.5.36 – 2026-09-29
- Beute & Rares: Filter, Platzhalter für unbekannte Orte und leere Beuteansicht folgen der gewählten Sprache.
- Kopfzeile und Suchhinweis der Beuteansicht werden nach einem Sprachwechsel aktualisiert.

## 1.5.35 – 2026-09-29
- Namen aller 34 festen Dungeon- und neun Raid-Einträge für die sieben wählbaren Sprachen ergänzt.
- Instanz- und Raidwissen zeigt die übersetzten Namen auf Karten und Detailseiten; interne Katalogschlüssel bleiben für Bilder und Daten erhalten.
- Erfasste Instanzen lassen sich auch über ihren übersetzten Namen suchen.

## 1.5.34 – 2026-09-29
- Waffenfertigkeiten: anklickbare Waffenmeister der eigenen Fraktion mit Kartenmarkierung ergänzt.
- Besuche beim Waffenmeister ersetzen die ungefähre Katalogposition durch die im Spiel erfasste Position.

## 1.5.33 – 2026-09-29
- Sammeln: Die drei Berufskarten für Bergbau, Kräuterkunde und Kürschnerei folgen nun ebenfalls der gewählten Sprache.

## 1.5.32 – 2026-09-29
- Abenteueransicht: Filter, Ereigniskategorien, Dossier, Erklärungstexte, Tooltips und Aktionen folgen nun der gewählten Sprache.
- Fehlende Übersetzungen für seltene Kreaturen und weitere Ereignisarten ergänzt.

## 1.5.31 – 2026-09-29
- Sprachprüfung der Ansichten: weitere feste Texte in Sammeln, Trainern, Notizen, Zielen, Inventar, Statistik, Instanzchronik, Suche und Tooltips lokalisiert.
- Offensichtliche Fehlübersetzungen in den festen Sprachtexten korrigiert; gespeicherte Ereignisse bleiben intern unverändert.
- Technische Prüfergebnisse und verbleibende Grenzen in `LOCALIZATION-AUDIT.md` dokumentiert.

## 1.5.30 – 2026-09-29
- Waffenfertigkeiten: Katalogwaffen, Gruppen, Zähler, Lernstufe, Preis und Status in allen sieben Sprachen übersetzt.
- Die Suche berücksichtigt den lokalisierten und den gespeicherten Waffennamen; interne Namen und erfasste Daten bleiben erhalten.

## 1.5.29 – 2026-09-29
- Der Eintrag „Русский“ im Sprachmenü verwendet immer eine kyrillische Schrift, auch wenn aktuell eine andere Addon-Sprache gewählt ist.

## 1.5.28 – 2026-09-29
- Der Hinweis der Sprachauswahl verwendet die zum Addon passende Schrift und kann damit kyrillischen Text anzeigen.
- Das Standardziel „Level X werden.“ wird in der Reiseübersicht in der gewählten Sprache dargestellt; frei verfasste Ziele bleiben unverändert.

## 1.5.27 – 2026-09-29
- Die Reiseübersicht übersetzt nun Abschnittstitel, Zähler und die festen Textteile der zuletzt gespeicherten Ereignisse entsprechend der gewählten Sprache.
- Ereignistexte werden nur für die Anzeige übersetzt; die gespeicherten Originaltexte bleiben für Questzuordnung und Filter erhalten.
- Nicht darstellbares Pfeilsymbol an der Sprachauswahl durch ein lesbares Zeichen ersetzt.

## 1.5.26 – 2026-09-29
- Sieben eigene Flaggen in der Sprachauswahl: neben der aktuellen Sprache und jedem Eintrag im Auswahlmenü.
- Weitere feste und zusammengesetzte Beschriftungen in den Chronicle-Ansichten übersetzt; Sprachstand und verbleibende Grenzen in `LOCALIZATION.md` aktualisiert.

## 1.5.25 – 2026-09-29
- Sprachauswahl für Englisch, Deutsch, Französisch, Spanisch, Italienisch, Portugiesisch und Russisch im Kopfbereich; die Wahl wird gespeichert und lädt die Oberfläche neu.
- Navigation, häufige Beschriftungen, Death Journal und Instanzwissen erweitert lokalisiert; russische Schrift nutzt die Kyrillisch-Variante der WoW-Schrift.
- Katalogbeschreibungen und weitere feste Texte mit Offline-Übersetzungen ergänzt. Der aktuelle Abdeckungsstand und Grenzen stehen in `LOCALIZATION.md`.

## 1.5.24 – 2026-09-29
- Death Journal: Das störende Motiv neben dem Datum wurde aus dem Kopfbereich entfernt. Zeitpunkt und Uhrzeit stehen nun in einer ruhigen, klar getrennten Spalte.

## 1.5.23 – 2026-09-29
- Death Journal als großzügige Gedenkseite neu gewichtet: größerer Kopfbereich, besser lesbare Kennzahlen und höhere Einträge an der gepunkteten Reisespur.
- Die Gedenktafel nutzt ein größeres Motiv und erklärt bei älteren Fällen ohne Kampflog die Datenlücke sichtbar.

## 1.5.22 – 2026-09-29
- Death Journal: Die Todeschronik verwendet jetzt große zweistellige Nummern und eine feine, gepunktete Reisespur wie in der Übersicht.
- Der ausgewählte Fall bleibt durch goldenen Wegpunkt und dezente Hervorhebung erkennbar.

## 1.5.21 – 2026-09-29
- Death Journal speichert jetzt bis zu sechs letzte Schadensereignisse aus dem Kampflog pro Tod, inklusive Gegner, Fähigkeit, Schaden und Markierung des tödlichen Treffers.
- Ein tödliches Ereignis hat Vorrang vor späteren Treffern; ältere Todesfälle ohne Kampflog bleiben klar gekennzeichnet.
- Die Todeschronik zeigt nun auch den letzten Fall als auswählbaren Eintrag. Die Gedenktafel stellt bei neuen Fällen den Trefferverlauf dar.

## 1.5.20 – 2026-09-29
- Eigenes bronzenes Gedenkmedaillon für das Death Journal, die Navigation, Todesereignisse und Todesstatistik.
- Das grelle grün-violette Zaubersymbol im Kopfbereich wurde ersetzt; der zusätzliche eckige Rahmen entfällt.

## 1.5.19 – 2026-09-29
- Death Journal: größeres Motiv im Kopfbereich, drei klar lesbare Kennzahlen und stärkere Gedenktafel mit Goldakzent.
- Zeitleiste und Detailbereich beginnen unter dem erweiterten Kopfbereich und bleiben aufeinander ausgerichtet.

## 1.5.18 – 2026-09-29
- Instanz- und Raidkarten ohne eigenes Bild zeigen ein kleines, dezentes Motiv auf dunklem Grund statt eines über die ganze Karte vergrößerten Platzhalterbildes.
- Auch die Detailkopfzeile solcher Inhalte verwendet das zurückhaltende Motiv.

## 1.5.17 – 2026-09-28
- Instanzwissen enthält jetzt alle 34 im installierten AtlasLootContinued-Forever-Katalog aufgeführten Dungeons, einschließlich angekündigter Instanzen ohne Boss- oder Beutedaten.
- Fehlende Daten erscheinen ausdrücklich als Vorschau; verfügbare Boss- und Beutedaten werden aus dem lokalen Forever-Referenzkatalog eingebunden.
- Raidwissen ergänzt die zwei dort angekündigten Forever-Raids Mount Hyjal und Barrow Deeps als Vorschau.

## 1.5.16 – 2026-09-28
- Raidwissen zeigt auch ohne Raid-Einträge im Encounter Journal sieben Classic-Raids mit Bossen und Beute aus dem eingebauten AtlasLootContinued-Referenzkatalog.
- Liefert der Client Raidbegegnungen selbst, haben diese Vorrang vor dem Referenzkatalog.

## 1.5.15 – 2026-09-28
- Instanzwissen ergänzt den bisherigen Detailkatalog um alle im Forever Encounter Journal angebotenen Dungeons.
- Neuer Bereich Raidwissen mit Coverbildern, Begegnungen und vom Client gelieferten Beutestücken.
- Die sieben handgepflegten Dungeon-Seiten mit Fraktionsquests und Belohnungen bleiben erhalten; der Encounter Journal liefert für weitere Inhalte keine Questlisten.

## 1.5.14 – 2026-09-28
- Die letzte Instanzkarte bleibt bei ungerader Kataloggröße im zweispaltigen Raster. Blackfathom Deeps hat dieselbe Breite und Höhe wie die übrigen Karten.

## 1.5.13 – 2026-09-28
- Instanzbilder im Header verwenden jetzt eine durchgehende Alphamaske. Die störenden senkrechten Streifen der bisherigen Bildsegmente entfallen.

## 1.5.12 – 2026-09-28
- Instanzübersicht: zu große Lücke vor der letzten breiten Karte verkleinert und überschüssigen Platz am Ende der scrollbaren Liste entfernt.

## 1.5.11 – 2026-09-28
- Instanzübersicht: die einzelnen Schattenstreifen unter den Kartentiteln durch eine einzige glatte, transparente Verlaufstextur ersetzt; die waagerechten Linien entfallen.

## 1.5.10 – 2026-09-28
- Instanzübersicht: harte schwarze Balken unter den Kartentiteln durch einen gleichmäßigen Verlauf mit transparenter Oberkante ersetzt.

## 1.5.09 – 2026-09-28
- Aktions-, Filter- und Reiterknöpfe in Chronicle auf den dunklen Stil mit Goldrahmen und Hover-Rahmen des Instanzwissen-Zurück-Knopfs vereinheitlicht. Verbliebene Blizzard-Standardknöpfe für Zurück, Geldanzeige, Notizen, Ziele und Namensspeicherung ersetzt.

## 1.5.08 – 2026-09-28
- Abrupte linke Bildkanten in Instanzwissen und den Instanzkarten von Dungeons & Bosse durch einen echten transparenten Übergang aus einzelnen Bildstreifen ersetzt. Andere Header-Motive nutzen bereits transparente freigestellte Grafik.

## 1.5.07 – 2026-09-28
- Dungeon-Quests: Erfahrung, Geld und Ruf als getrennte, lesbare Angaben; mögliche Gegenstände stehen darunter. Die Questliste zeigt den Erfahrungswert, und nicht erfasste Werte werden klar benannt.
- Instanzübersicht: siebte Karte als breite Abschlusskarte mit Abstand zu den ersten drei Reihen.

## 1.5.06 – 2026-09-28
- Instanzwissen: rechtes Dungeon-Motiv in der Übersicht auf die volle Höhe der Kopfkarte vergrößert und am oberen und unteren Innenrand beschnitten.

## 1.5.05 – 2026-09-28
- Instanzkarten: harte dunkle Fläche hinter den Kartentiteln durch weichen Verlauf ersetzt.
- Instanzwissen: Schriften für Karten, Tabs, Boss-, Quest- und Beutelisten und Detailtexte vergrößert; Nebeninformationen kontrastreicher. Katalogkarte erklärt null Quests für die eigene Fraktion.

## 1.5.04 – 2026-09-28
- Instanzwissen: Instanzbild selbst erhält einen transparenten Verlauf von links nach rechts; die zuvor hart beginnende Bildtönung entfällt.

## 1.5.03 – 2026-09-28
- Instanzwissen: Instanzbild am linken Rand weich in die Kopfkarte überblendet. Zurück-Knopf in die Seitenkopfzeile verschoben, sodass Titel und Bild frei bleiben.

## 1.5.02 – 2026-09-28
- Instanzwissen: Zurück-Knopf aus dem Dungeonbild in den freien linken Headerbereich versetzt und den Titel darunter ausgerichtet.

## 1.5.01 – 2026-09-28
- Instanzwissen: deutlich sichtbaren Zurück-Knopf zur Instanzübersicht ergänzt.
- Dungeon-Quests nach der Fraktion des aktuellen Charakters gefiltert; Zähler in Übersicht und Instanzkopf angepasst.

## 1.5.00 – 2026-09-28
- Instanzwissen: Bossbeschreibung und Beuteliste näher zusammengerückt. Questdetails behalten Platz für Questgeber und Abgabe, Gegenstandsdetails nutzen die kompakte Anordnung.

## 1.4.99 – 2026-09-28
- Instanzwissen vollständig in Chronicle integriert: bebilderte Instanzübersicht, eigene Detailansicht mit Bossen, Quests, Beute und Gegenstands-Tooltips. Der Knopf zum Öffnen von Forever Dungeon Journal entfällt.
- Ladebild-Zuordnungen für Hall of Thanes und The Deadmines ergänzt. Katalogquelle: das vom Nutzer bereitgestellte Forever Dungeon Journal v1.3.0 von Exehn.

## 1.4.98 – 2026-09-28
- WoW-Ladefehler behoben: UI.lua bleibt wieder innerhalb der Lua-5.1-Grenze von 200 lokalen Variablen.
- Neue Wissensseite „Instanzwissen“ mit sieben Instanzen, Bossen, Quests und Beute aus dem vom Nutzer bereitgestellten Forever Dungeon Journal v1.3.0 von Exehn; optionaler Knopf zum vollständigen Journal.

## 1.4.97 – 2026-09-28
- Geldbuchungen gleicher Minute, gleichen Orts und gleicher Richtung als aufklappbare Sammelbuchung gebündelt. Einzelbeträge und Kontostände bleiben einsehbar.
- Beschriftung der angezeigten letzten Buchungen und der Tagesbilanz präzisiert.

## 1.4.96 – 2026-09-28
- Gold & Wirtschaft als offenes Kassenbuch verfeinert: Buchungen mit Zeitlinie statt dunkler Zeilenflächen, ausgewählter Eintrag dezent hervorgehoben.

## 1.4.95 – 2026-09-28
- Gold & Wirtschaft als klares Buchungsjournal überarbeitet: kompaktere Zeilen ohne Ziersymbole und ausführlichere Buchungsdetails mit Kontostand davor und Tagesbilanz.

## 1.4.94 – 2026-09-28
- Eigene Boss- und Bossbeute-Medaillons im Stil des Instanzmedaillons erstellt und in Leeransichten, Zählern und Bosszeilen eingebaut.

## 1.4.93 – 2026-09-28
- Boss- und Bossbeute-Ansichten korrigiert: sichtbare Symbole und das große Leerzustandsmotiv wechseln nun tatsächlich mit dem Tab.

## 1.4.92 – 2026-09-28
- Sichtbare Boss- und Bossbeute-Symbole in Leeransichten, Bosszeilen und Zählern ersetzt; die großen Hintergrundmotive wechseln passend zur Auswahl.

## 1.4.91 – 2026-09-28
- Bosse und Bossbeute zeigen eigene passende Motive im Kopfbereich.

## 1.4.90 – 2026-09-28
- Inhaltsflächen, Listen und Detailbereiche addonweit auf offene Darstellung ohne Kartenrahmen vereinheitlicht. Fenster, Kopfbereiche und Bedienelemente bleiben klar abgegrenzt.

## 1.4.89 – 2026-09-28

- Lehrer mit Koordinaten lassen sich aus der Detailansicht als Wegpunkt auf der Weltkarte markieren.
- Bekannte Start-Waffenfertigkeiten werden als erlernt statt als kostenpflichtige Trainerangebote gezeigt.
- Symbol der Stangenwaffen angepasst.

## 1.4.88 – 2026-09-28

- Lehrerorte und Waffenfertigkeiten als Wissensatlas mit Kennzahlen, kompakter Liste und großem Detailbereich gestaltet.
- Anklickbare Einträge zeigen Herkunft, Lernstufe, Preis oder Koordinaten im rechten Bereich.

## 1.4.87 – 2026-09-28

- Lehrerorte und Waffenfertigkeiten zeigen nun auf neuen Charakteren einen mitgelieferten Grundbestand für alle neun Klassen.
- Paladin-Lehrerorte aus der Vorlage mit Koordinaten ergänzt; beobachtete Trainerdaten ersetzen Vorschauwerte.

## 1.4.86 – 2026-09-28

- Unter Wissen neue Seiten für besuchte Klassenlehrer und Waffenfertigkeiten ergänzt.
- Trainerbesuche erfassen Lehrerort mit Koordinaten sowie Waffenangebote, Lernstufen und Preise automatisch.
- Waffenangebote werden getrennt vom Klassenzauberkatalog gespeichert.

## 1.4.85 – 2026-09-28

- Trainergruppen per Klick ein- und ausklappbar; spätere und bereits bekannte Zauber starten eingeklappt.
- Gruppenzustand bleibt beim Filterwechsel erhalten; Suchtreffer werden auch in eingeklappten Gruppen gezeigt.

## 1.4.84 – 2026-09-28

- Das große Hintergrundmotiv auf der Trainerseite entfernt, damit Stufen und Preise frei lesbar sind.
- Nächste Freischaltung vor Katalog-Vorschau einsortiert und spätere Lernstufen deutlicher markiert.

## 1.4.83 – 2026-09-28

- Traineransicht als breite Zauberliste mit Gruppen, Symbolen sowie festen Spalten für Lernstufe und Preis gestaltet.
- Gruppen zeigen Zauberzahl und bekannte Gesamtkosten; unbestätigte Katalogeinträge bleiben gesondert gekennzeichnet.

## 1.4.82 – 2026-09-28

- Die Übersicht erhält mehr Platz für den zweiten Schritt und zeigt alle fünf Einträge der Reisespur innerhalb der sichtbaren Fläche.
- Abstände und Linienführung der Reisespur an die neue Höhe angepasst.

## 1.4.81 – 2026-09-28

- Abstände zwischen Meilenstein, Questlog und Reisespur vergrößert; Klick-Hervorhebung des Zieltexts repariert.
- Rechte Kennzahlen kompakter gesetzt und das Buchmotiv unterhalb der Werte kleiner und dezenter gehalten.
- Auf der Startseite nur noch eine Reise-Fortsetzung anzeigen, damit andere Erinnerungen sichtbar bleiben.

## 1.4.80 – 2026-09-27

- Abbruch beim Aufbau des ersten Reiseatlas-Schritts behoben: Titelzeile unabhängig initialisiert, damit Ziel, Kennzahlen und Reisespur erscheinen.
- Eingabezeile der vorherigen Seite vor dem Rendern ausgeblendet.

## 1.4.79 – 2026-09-27

- Startseite als Reiseatlas neu aufgebaut: persönliches Ziel und vertikale Reisespur links, Kennzahlen als Randnotizen rechts.
- Eine geschwungene goldene Punktspur verbindet die jüngsten Ereignisse; wiederholte kleine Motive entfernt.
- Großes Chronicle-Buchmotiv unten rechts als einzelner Hintergrundakzent hervorgehoben; alle Rubriken bleiben anklickbar.

## 1.4.78 – 2026-09-27

- Startseite als offene Chronik gestaltet: Einzelrahmen und Flächen hinter Kennzahlen, nächsten Schritten und Erinnerungen entfernt.
- Motive, große Zahlen und nummerierte Einträge bleiben als Orientierung erhalten; Hover hebt Text dezent hervor.
- Abschnittstrennlinien auf der Startseite entfernt.

## 1.4.77 – 2026-09-27

- Startseite mit einem stärkeren Kapitelkopf und Klasse, Stufe und Ort des Charakters ergänzt.
- Vier Kennzahl-Karten und nächste Schritte mit passenden Chronicle-Motiven rechts versehen.
- Letzte Erinnerungen als nummerierte Chronik mit feinen Trennmarken gestaltet.

## 1.4.76 – 2026-09-27

- Auf der Startseite identische Erinnerungen derselben Minute nur einmal anzeigen, etwa wiederholte Händlerbesuche. Die vollständige Chronik bleibt erhalten.
- Verschiedene direkt aufeinanderfolgende Ereignisse derselben Art bleiben nun sichtbar.

## 1.4.75 – 2026-09-27

- Motiv im Startseiten-Header rechts auf die volle Innenhöhe skaliert und an obere und untere Kante angepasst.
- Leere Leuchtrahmen in den Kennzahlen entfernt; goldene Zahlen, Akzente und Chronicle-Material an den übrigen Stil angeglichen.
- Karten für nächste Schritte und Erinnerungen mit derselben warmen Materialoberfläche versehen.

## 1.4.74 – 2026-09-27

- Startseite neu arrangiert: größere persönliche Heldenkarte mit vollem Charakternamen, Stufe, Ort und Vermögen.
- Vier Kennzahlen als markante, anklickbare Kacheln mit farbigen Akzenten gestaltet.
- Nächste Schritte als zwei hervorgehobene Karten und letzte Erinnerungen in einer kompakten Zweispaltenansicht aufgebaut.

## 1.4.73 – 2026-09-27

- Chronicle-Meldung zum Stufenaufstieg unter die Blizzard-Anzeige versetzt und kompakter gestaltet.
- Doppelte Stufenüberschrift entfernt; die Chronicle-Meldung zeigt nun direkt neue Klassenzauber oder die nächste Freischaltung.

## 1.4.72 – 2026-09-27

- Ladefehler behoben: Die neue Nachnamen-Funktion überschritt in UI.lua WoWs Limit für lokale Variablen der Hauptfunktion. Editor und Anzeige verwenden nun vorhandene Strukturen.
- Lua-5.1-Kompilierung aller Addon-Dateien ergänzt.

## 1.4.71 – 2026-09-27

- Im Charakterprofil kann pro Charakter ein Nachname eingetragen werden; vollständige Namen erscheinen auf Charakterkarten, in Details, Tooltips und der Suche.
- Ein Klick auf eine Charakterkarte öffnet das Profil mit dem Namensfeld.

## 1.4.70 – 2026-09-27

- Kleine linke Symbole aus den drei Sammelberuf-Karten entfernt; Berufsname und Rang links ausgerichtet. Die großen Berufsmotive rechts bleiben erhalten.

## 1.4.69 – 2026-09-27

- Die drei Sammelberuf-Motive füllen die rechte Seite ihrer Rangtafeln nun fast über die ganze Höhe; auf schmalen Karten bleiben sie dezent hinter den Zahlen.
- Die gemeinsamen Header-Motive nutzen die verfügbare Höhe rechts besser und passen sich der Höhe des jeweiligen Kopfbereichs an.

## 1.4.68 – 2026-09-27

- Drei eigene transparente Motive für Bergbau, Kräuterkunde und Kürschnerei erstellt und rechts in den Rangtafeln eingebaut.
- Header-Motive weniger stark beschnitten; bei schmalen geteilten Kopfkarten ausgeblendet und Überschneidungen mit Datum, Kennzahlen und Text entfernt.

## 1.4.67 – 2026-09-27

- Fortschrittsbalken der drei Sammelberufe tiefer gesetzt, damit die Punktzahlen nicht darüber liegen.

## 1.4.66 – 2026-09-27

- Stufenaufstieg-Meldung an Blizzards schlichte Anzeige angeglichen: oben mittig, transparente Fläche, zentrierte Schrift und sanftes Ausblenden.

## 1.4.65 – 2026-09-27

- Rechte Header-Motive einheitlich skaliert und oben rechts auf den Titelbereich begrenzt; Zählerzeilen bleiben frei.

## 1.4.64 – 2026-09-27

- Kürschnerei als dritten Sammelberuf ergänzt: Lederfunde, Sitzungswerte, Rangfortschritt, eigene Berufstafel und Fundfilter.

## 1.4.63 – 2026-09-27

- Sammelfunde auf echte Erze und Kräuter begrenzt; Steine und andere Begleitbeute aus früheren Aufzeichnungen werden in Liste und Rangwertung ausgeblendet.

## 1.4.62 – 2026-09-27

- Sammelansicht neu angeordnet: Sitzungszahlen in der Kopfkarte, anklickbare Berufstafeln mit Rangfortschritt und kompakteres Funddossier.

## 1.4.61 – 2026-09-27

- Wegweiser unter Wissen samt eigener Ansicht und Suchindex entfernt; Sammeln und Trainer bleiben eigenständig erreichbar.

## 1.4.60 – 2026-09-27

- Abenteuer optisch an die übrigen Chronicle-Seiten angeglichen: Zahlen in der Kopfkarte statt dunkler Kennzahl-Kästen.
- Ereignisse als ruhige Liste mit Auswahl und Trennlinien statt Einzelrahmen; Detaildossier bei kurzen Erinnerungen verkleinert.

## 1.4.59 – 2026-09-27

- Abenteuer-Ansicht mit Kennzahlen, kompakter Tageschronik links und Detaildossier rechts neu gestaltet.
- Questserien bleiben aufklappbar; aktive Quests lassen sich aus dem Dossier im WoW-Questlog öffnen.
- Die Wissensseiten behalten wieder ihre Gestaltung aus 1.4.56.

## 1.4.58 – 2026-09-27

- Die irrtümliche Neugestaltung der Wissensseiten aus 1.4.57 zurückgenommen; Wegweiser, Sammeln und Trainer behalten ihre getrennten Navigationseinträge.

## 1.4.57 – 2026-09-27

- Die drei Wissensseiten an die übrigen Chronicle-Seiten angeglichen: gerahmte Eintragskarten, Kennzahl-Karten und Abschnittsüberschriften.
- Auswahl und Mouseover klarer hervorgehoben; Listenhöhe und Scrollbereich an die größeren Karten angepasst.

## 1.4.56 – 2026-09-27

- Wegweiser, Sammeln und Trainer als drei eigene Einträge unter Wissen in der linken Navigation anzeigen.
- Gemeinsame Reiterleiste entfernen, Inhalte nach oben rücken und die linke Navigation bei kleinen Fenstern scrollbar machen.

## 1.4.55 – 2026-09-27

- Doppelte Händlerablage entfernt. Vorhandene Händlereinträge werden beim Laden in das NPC-Journal übernommen.
- Addon-Dateien, Ereignisse, Funktionsnamen, Bilddateien und Trainerkatalog auf weitere Duplikate geprüft; die zwei benötigten Client-TOCs behalten.

## 1.4.54 – 2026-09-27

- Wegweiser zeigt automatisch auch abgeschlossene Quests sowie entdeckte Gebiete, Händler und seltene Kreaturen aus der Chronicle.
- Questzeilen kennzeichnen aktive und abgeschlossene Aufgaben eindeutig; Entdeckungen haben einen eigenen Filter.

## 1.4.53 – 2026-09-27

- Stufenaufstiegsmeldungen als Chronicle-Tafel in der Bildschirmmitte mit Lotus-Symbol, Goldschimmer und Ein-/Ausblendeffekt anzeigen.
- Bei neuen Klassenzaubern die Namen, sonst die nächste Katalog-Freischaltung zeigen; Chat-Eintrag zum Nachlesen beibehalten.

## 1.4.52 – 2026-09-27

- „Vorschau“ zeigt alle noch nicht bestätigten Katalogzauber einschließlich künftiger Lernstufen; bekannte Zauber werden ausgeblendet.
- Doppelte Stufenangaben in den Katalogzeilen entfernt und die Leermeldung präzisiert.

## 1.4.51 – 2026-09-27

- Die Trainerliste zeigt jetzt alle Zauber bis Stufe 60; das frühere 100-Zeilen-Limit und die dazu passende zu geringe Scrollhöhe wurden entfernt.

## 1.4.50 – 2026-09-27

- Zauber-Tooltips beim Überfahren der Trainerliste und des Symbols in der Detailtafel am Mauszeiger anzeigen.
- Levelmeldung über den bereits funktionierenden Stufenaufstieg-Sammler auslösen; neue Zauber sichtbar im Chat und auf dem Bildschirm melden.
- Auch bei Stufen ohne neue Katalogzauber einmalig die nächste Freischaltstufe im Chat nennen.

## 1.4.49 – 2026-09-27

- Unbestätigte Katalogzauber aus „Prüfen“ in eine eigene „Vorschau“ verschieben; fehlende Trainerpreise klar kennzeichnen.
- Niedrigere Ränge als bekannt anzeigen, wenn ein höherer Rang nachweislich erlernt wurde; erfasste Trainer-Stufe 0 durch die Katalog-Lernstufe ersetzen.
- Levelmeldung präzisieren: Der Katalog zeigt mögliche Klassenzauber, das Trainerangebot bestätigt deren Verfügbarkeit.

## 1.4.48 – 2026-09-27

- Trainerübersicht für neue Charaktere mit einem integrierten Forever-Zauberkatalog aller neun Klassen vorbelegen; Ränge, Stufen und Symbole erscheinen vor dem ersten Trainerbesuch.
- Bekannte Zauber über die Spiel-API erkennen und beobachtete Trainerpreise und Statuswerte über die Vorschau legen.
- Levelhinweise berücksichtigen nun auch die Katalogdaten; Quellen und Grenzen des Beta-Datensatzes dokumentiert.

## 1.4.47 – 2026-09-27

- Trainerangebote nach tatsächlicher Lernstufe und Status in „Jetzt“, „Prüfen“, „Später“ und „Bekannt“ gliedern; nächste Freischaltstufe anzeigen.
- Alle Trainerfilter zeitversetzt einlesen, damit der Client die geänderte Angebotsliste vor dem Scan aktualisieren kann; danach die ursprünglichen Filter wiederherstellen.

## 1.4.46 – 2026-09-27

- Trainerzauber mit ihren Rängen aus dem Forever-Client erfassen und nach Rang getrennt speichern.
- Beim Trainerbesuch vorübergehend alle Angebotskategorien einlesen und die bisherigen Filter anschließend wiederherstellen.
- Beim Stufenaufstieg einmalig auf neu erreichbare, bereits erfasste Trainerzauber hinweisen.

## 1.4.45 – 2026-09-27

- Wegweiser, Sammelübersicht und Traineransicht als eigene Chronicle-Oberflächen mit Filtern, Kennzahlen, Rangtafeln und Detailfeldern gestaltet.
- Forever-Trainerstatus korrekt ausgelesen; fehlerhaft gespeicherte Statuswörter im Zaubernamen werden beim Öffnen bereinigt.

## 1.4.44 – 2026-09-26

- Wegweiser-Suchindex zwischengespeichert und bei Datenänderungen aktualisiert; unveränderte Trainerabfragen lösen keine Neuzeichnung mehr aus.
- Veröffentlichungspaket enthält nur Laufzeitdateien und Dokumentation, keine unbearbeiteten PNG-Arbeitsdateien.

## 1.4.43 – 2026-09-26

- Eigenständigen Wegweiser mit Suche über Chronicle-Daten, Sammelchronik für Erz und Kräuter sowie Trainerchronik ergänzt. Alle drei Bereiche sind in die Chronicle-Oberfläche eingebettet und benötigen kein weiteres Addon.

## 1.4.42 – 2026-09-26

- Alle großen Seitenköpfe mit passenden Chronicle-Motiven rechts im Zuschnitt des Questjournals gestaltet; vorhandene Porträts und lesbare Kennzahlen berücksichtigt.

## 1.4.41 – 2026-09-25

- Das Questmotiv im rechten Bereich des Journal-Kopfs größer und besser sichtbar dargestellt, innerhalb des Rahmens beschnitten.

## 1.4.40 – 2026-09-25

- Zusätzliche obere und untere Innenlinien aus der gemeinsamen Chronicle-Rahmengestaltung entfernt; gilt für alle damit gestalteten Seiten und Dossiers.
- Dieselbe zusätzliche Innenlinie aus den leeren Seiten entfernt; Umrandungen und Eckornamente bleiben bestehen.

## 1.4.39 – 2026-09-25

- Die zusätzlichen oberen und unteren Innenlinien im Questjournal-Kopf entfernt; Rahmen und Eckornamente bleiben erhalten.
- Rechts das vorhandene Questmotiv als dezente Hintergrundillustration eingesetzt.

## 1.4.38 – 2026-09-25

- Questjournal-Kopf verschlankt: doppeltes Symbol und wiederholte Zähler entfernt, Untertitel nach Ansicht angepasst.
- Tabs, Suche, Questliste und Dossier rücken nach oben; die gewonnenen 30 Pixel stehen den Aufgaben zur Verfügung.

## 1.4.37 – 2026-09-25

- Questdossier ordnet aktuelle Ziele vor Geschichte und Auftrag an, damit der Fortschritt sofort sichtbar ist.
- Längere Questtexte sind größer gesetzt und erhalten einen Weiterlese-Hinweis, sobald der Textbereich scrollbar ist.

## 1.4.36 – 2026-09-25

- Questtext im Forever-Client: direkter Abruf über Questlog-Index funktioniert jetzt auch ohne die dort nicht vorhandene ältere Auswahlfunktion.
- Anhand der Ingame-Diagnose für Quest 868 mit 596 Zeichen Beschreibung und 64 Zeichen Auftrag geprüft.

## 1.4.35 – 2026-09-25

- /chr questdebug ergänzt: zeigt ohne benutzerdefiniertes Skript, welche Questtext-Funktionen und Rückgaben der laufende Client für die gewählte Quest liefert.

## 1.4.34 – 2026-09-25

- Questtexte werden auf unterstützten Clients direkt über den Questlog-Index gelesen, ohne die Auswahl im WoW-Questlog zu ändern.
- Ein Vergleich mit dem aktuellen Eintrag verhindert, dass ältere Clients versehentlich den Text einer anderen Quest zeigen.

## 1.4.33 – 2026-09-25

- Questtext-Abruf für das moderne Questlog ergänzt und den Fall ohne vorausgewählte Quest berücksichtigt.
- Die vorherige Questlog-Auswahl wird auch bei diesen Client-Varianten nach dem Lesen wiederhergestellt.

## 1.4.32 – 2026-09-25

- Das Questdossier liest jetzt den Erzähl- und Auftragstext aktiver Quests aus dem klassischen WoW-Questlog, wenn der Client ihn bereitstellt. Die vorherige Questlog-Auswahl wird wiederhergestellt.
- Kurze Questdossiers werden niedriger dargestellt; lange Texte lassen sich innerhalb des Dossiers mit dem Mausrad lesen.

## 1.4.31 – 2026-09-25

- Questgebiete im Journal als schlanke, aufklappbare Überschriften mit Zähler und feiner Trennlinie statt gerahmter Karten gestaltet.
- Aufgaben unter den Gebietstiteln eingerückt, damit die Questlog-Hierarchie klarer lesbar ist.

## 1.4.30 – 2026-09-25

- Questjournal: Aufgaben als ruhige Zeilen mit feinen Trennlinien statt einzelner Karten gestaltet; die Auswahl bleibt hervorgehoben.
- Questdossier verkürzt, damit die Schaltfläche zum WoW-Questlog sichtbar bleibt; vorhandene Questziele stehen ohne Platzhaltertext im Fokus.

## 1.4.29 – 2026-09-25

- Questseite als zweispaltiges Questjournal gestaltet: kompakte Gebietsliste und ausgewähltes Questdossier im Chronicle-Stil.
- Questbeschreibung und Ziele werden angezeigt, sofern die WoW-Questlog-API sie bereitstellt. Das originale Questlog bleibt per Schaltfläche erreichbar.

## 1.4.28 – 2026-09-25

- Gebiete als größere offene Reisekapitel gestaltet: prominenter Gebietsname, Untergebiet und getrennte Werte für ersten und letzten Besuch. Einzahl und Mehrzahl der Besuchszahlen korrigiert.

## 1.4.27 – 2026-09-25

- Datumsangaben und Untergebiet in den Gebietszeilen linksbündig ausgerichtet; die Spalten schließen nun sauber an Titel und Nummerierung an.

## 1.4.26 – 2026-09-25

- Gebiete-Seite repariert: Eine undefinierte Kartenbreite verhinderte die Anzeige gespeicherter Gebiete. Gebiete erscheinen jetzt als offene Chronicle-Zeilen mit Goldakzenten und feinen Trennlinien.

## 1.4.25 – 2026-09-25

- Death Journal: Neue PLAYER_DEAD-Ereignisse werden auch bei einer hängen gebliebenen Todessperre erfasst; kurz aufeinanderfolgende doppelte Meldungen bleiben unterdrückt. PLAYER_UNGHOST setzt die Sperre zuverlässig zurück.

## 1.4.24 – 2026-09-25

- Kontaktdossier: Umrandung wiederhergestellt und ausschließlich die zusätzliche horizontale Goldlinie unter der Oberkante ausgeblendet.

## 1.4.23 – 2026-09-25

- Zusätzliche schwere Oberkante am Kontaktdossier entfernt. Die dünne Chronicle-Linie und die ornamentalen Ecken bleiben; der Porträtrahmen ist wiederhergestellt.

## 1.4.22 – 2026-09-25

- Den schweren Backdrop-Rahmen um die NPC-Porträtbühne im Kontaktdossier entfernt. Dadurch entfällt der breite horizontale Balken direkt über dem Porträt.

## 1.4.21 – 2026-09-25

- NPC-Begegnungsliste auf offene Chronicle-Zeilen mit feinen Trennlinien umgestellt. Kräftige Kartenrahmen, senkrechte Balken und Verbindungslinien entfernt; die Auswahl bleibt dezent hervorgehoben.

## 1.4.20 – 2026-09-25

- Verifizierte Iconpfade für Giftschlag und Gamaschen des Sumpfgräbers als Rückfall ergänzt. Neu erfasste Bossbeute speichert verfügbare Icons mit dem Fund, damit das Instanzkapitel sie später zuverlässig anzeigen kann.

## 1.4.19 – 2026-09-25

- Bossbeute-Icons im Instanzkapitel direkt in den Loot-Zeilen gezeichnet statt in einem eigenen Backdrop-Rahmen. Ein sichtbares Platzhalterbild liegt darunter, falls eine Icon-Textur fehlt.

## 1.4.18 – 2026-09-25

- Bossbeute-Icons im Instanzkapitel lesen die Gegenstands-ID auch aus gespeicherten Itemlinks. Fehlende Itemdaten werden zur Nachladung angefordert; bis dahin erscheint ein sichtbares Platzhalter-Icon.

## 1.4.17 – 2026-09-25

- Instanzkapitel als breiteres Bildkapitel gestaltet: größeres Instanzbild mit weichem Übergang zum Titel, mehr Raum für Besuche, Bosse und Siege. Das Fenster bietet mehr Platz für die Bossliste.

## 1.4.16 – 2026-09-25

- Kopfbereich des Instanzkapitels neu gestaltet: Titel, erster und letzter Besuch sowie große Kennzahlen für Besuche, Bosse und Siege bilden mit dem Instanzbild ein zusammenhängendes Kapitel.

## 1.4.15 – 2026-09-25

- Queststufen als eigene goldene Kennzahl hervorgehoben. Berufe zeigen Fortschrittslinien und sauber getrennte Ränge; Besitzkennzahlen sind größer gesetzt. Das Hintergrundmotiv auf der Charakterseite ist dezenter.

## 1.4.14 – 2026-09-25

- Charakterprofil mit großen Kennzahlen und klar gesetzten Talentzeilen samt separatem Rang aufgewertet. Das Live-Porträt ist wieder stärker auf den Kopf fokussiert.

## 1.4.13 – 2026-09-25

- Charakterdetails in Profil, Quests und Sammlung als offene Einträge mit feinen Trennlinien statt Einzelkarten dargestellt. Das Kopfporträt erhält wieder einen schmalen Rahmen, der die Bildkante sauber fasst.

## 1.4.12 – 2026-09-25

- Charakterchronik von einzelnen Karten auf offene Einträge mit feinen Trennlinien umgestellt; wiederholte Buch-Icons entfernt. Der Rahmen um das Kopfporträt entfällt, das Porträt bleibt sichtbar.

## 1.4.11 – 2026-09-25

- Charakterporträt weiter herausgezoomt und zum Betrachter gedreht, damit Kopf und Hörner im Rahmen besser sichtbar sind.

## 1.4.10 – 2026-09-25

- Charakterprofil als Chronicle-Kapitel neu gegliedert: goldene Überschrift, ruhige Informationsspalte und größeres, gerahmtes Live-Porträt. Technische Talentbalken im Kopfbereich entfernt.

## 1.4.09 – 2026-09-25

- Charakterdetail mit gerahmtem, lebendigem Kopfporträt des aktiven Charakters erweitert. Gespeicherte Charaktere zeigen ein farblich passendes Klassenporträt; Profilangaben und Talentbalken sind auf das neue Layout abgestimmt.

## 1.4.08 – 2026-09-25

- NPC- und Händlerseite als zweigeteilte Chronicle-Ansicht neu gestaltet: Kontaktliste links, goldgerahmtes Dossier mit echtem NPC-Modell, Ort und Begegnungsdaten rechts. Die Modellbühne nutzt den Lotus als dezente Rückfallebene.

## 1.4.07 – 2026-09-25

- NPC-Seite mit großen Kennzahlen und ausgeprägtem Kontaktprofil gestaltet. Begegnungen erscheinen als verbundene Chronikspur; bei gemeinsamem Gebiet zeigen die Zeilen den ersten und letzten Kontakt statt den Ort zu wiederholen.

## 1.4.06 – 2026-09-25

- Kontaktdossier sauber linksbündig ausgerichtet und Datumsangaben in eigene Spalten gesetzt. Gemeinsame Begegnungsorte werden als Kapitel benannt; normale NPC-Zeilen verzichten auf das wiederholte Platzhalter-Icon.

## 1.4.05 – 2026-09-25

- NPC-Einträge sind auswählbar. Ein Kontakt-Dossier im Kopfbereich zeigt Ort, Typ, Begegnungszahl und letzten Besuch; die ausgewählte Zeile ist hervorgehoben.

## 1.4.04 – 2026-09-25

- NPC- und Händlerseite als ruhige Begegnungschronik überarbeitet: letzte Begegnung im Kopfbereich, volle Listenbreite, nummerierte Einträge und einheitliche Goldtöne.

## 1.4.03 – 2026-09-25

- Charakterdaten werden bei wechselnder Realm-Bezeichnung anhand der stabilen Charakter-ID wiedergebunden. So bleiben gespeicherte Instanzen und Bosse sichtbar.

## 1.4.02 – 2026-09-25

- Beutesymbole im Bosskapitel erhalten einen eigenen sichtbaren Rahmen, zusätzliche Icon-Abfragen und eine sichere Ersatzgrafik.

## 1.4.01 – 2026-09-25

- Bosskapitel zeigt leere Beutezeilen kompakter und ermittelt Beutesymbole auch direkt über die Gegenstands-ID.

## 1.4.00 – 2026-09-25

- Das Instanzkapitel zeigt erfasste Bossbeute ab seltener Qualität direkt unter dem jeweiligen Boss, mit Symbol, Menge und Gegenstands-Tooltip.

## 1.3.99 – 2026-09-25

- Das separate Bosskapitel besitzt nun eine deckende Oberfläche, damit die Hauptseite nicht durchscheint.

## 1.3.98 – 2026-09-25

- Instanzkarte weist sichtbar auf das separate, per Klick erreichbare Bosskapitel hin.

## 1.3.97 – 2026-09-25

- Originalbilder liegen nun ohne inneren Kasten direkt in der Instanzkarte und blenden weich in deren Hintergrund ein.
- Klick auf eine Instanzkarte öffnet ein separates, verschiebbares Fenster mit dem Bosskapitel.
- Bosskapitel aus der Instanzliste entfernt.

## 1.3.96 – 2026-09-25

- Instanzkarte zeigt die Besuchszahl als prägnantes Kapitelmotiv neben dem Originalbild.
- Bildrahmen erhält die Zierecken der Chronicle; doppelte Besuchszahl aus der Kapitelzeile entfernt.

## 1.3.95 – 2026-09-25

- Instanzbesuch als größere Titelkarte mit breitem Originalbild und klar getrennten Besuchsdaten gestaltet.
- Platzierung des einklappbaren Bosskapitels an die neue Kartenhöhe angepasst.

## 1.3.94 – 2026-09-25

- Instanzbild als klar gerahmte Miniatur statt gestreiftem Blendeffekt dargestellt.
- Bosskapitel jeder einzelnen Instanz lässt sich auf- und zuklappen; standardmäßig geschlossen.

## 1.3.93 – 2026-09-25

- Schlüsselsymbole aus Kopfbereich und Instanzkarte entfernt.
- Instanzbilder mit transparenter Streifenüberblendung statt harter linker Bildkante dargestellt.

## 1.3.92 – 2026-09-25

- Original-Ladebilder gehen in der Instanzkarte nun weich in den dunklen Hintergrund über.

## 1.3.91 – 2026-09-25

- 37 echte Ladebilder aus den Forever-Clientdateien für Instanzkarten eingebunden.
- Deutsche und englische Instanznamen auf die jeweiligen Bilder abgebildet; fehlende Clientbilder nutzen weiter das Standardmotiv.

## 1.3.90 – 2026-09-25

- Instanzkarten verwenden echte World-of-Warcraft-Bilder aus dem Begegnungsjournal des Spielclients.
- Bildwahl erfolgt über Instanz-ID oder lokalisierten Namen; fehlende Journalbilder behalten das bisherige Motiv.

## 1.3.89 – 2026-09-25

- Bosskapitel auf der Instanzseite zeigt dezente Nummern statt acht identischer Symbole.

## 1.3.88 – 2026-09-25

- Laufzeitfehler in der Dungeonansicht behoben: Nummerierung wird nun an den Bosszeilen erzeugt.
- Instanzkarte und Bosschronik werden wieder vollständig gezeichnet.

## 1.3.87 – 2026-09-25

- Bosschronik beim Wechsel zwischen Instanzen, Bossen und Bossbeute zuverlässig ausblenden.
- Kapitelkennung der Bossansicht korrigiert.

## 1.3.86 – 2026-09-25

- Bossansicht als ruhige, nummerierte Chronik statt wiederholter Karten gestaltet.
- Kapitelüberschrift und klare Trennung der Begegnungen ergänzt.

## 1.3.85 – 2026-09-25
- Bossbeute als kompakte Fundliste mit Gegenstandssymbol, Boss, Zeitpunkt und Empfänger statt als Kartenraster dargestellt.
- Gegenstandssymbole über die Classic-Beta-kompatible Item-API geladen und rekonstruierte Zuordnungen sichtbar gekennzeichnet.
- Bossbeute-Kopfbereich und Seitenmotiv an die neue Liste angepasst.

## 1.3.84 – 2026-09-25
- Instanzkarte um ein Bosskapitel mit den zugehörigen Begegnungen erweitert.
- Instanznamen mit und ohne führenden deutschen Artikel abgeglichen; vorhandene acht Boss-Siege erscheinen damit bei den Höhlen des Wehklagens.
- Neues Classic-Beta-Gegenstandslinkformat im Loot-Chat erkannt und blaues historisches Inventar-Loot anhand von Zeit und Gebiet vorsichtig Bossen zugeordnet.

## 1.3.83 – 2026-09-25
- Einzelne Instanz als Expeditionschronik mit erstem und letztem Besuch sowie zugeordneten Boss-Siegen gestaltet.
- Neue Boss-Einträge speichern ihren Instanznamen, damit Siege künftig zuverlässig der Instanz zugeordnet werden.

## 1.3.82 – 2026-09-25
- Einzelne Instanzen als kompakte Chronikkarte statt als übergroße Bühne dargestellt.
- Bossbeute aus eigenen Inventarzugängen ab seltener Qualität kurz nach einem Boss-Sieg als Rückfall erfasst.
- Encounter-Beute nutzt bei fehlendem Boss-Schlüssel den letzten besiegten Boss und löst fehlende Gegenstandslinks nach Möglichkeit auf.

## 1.3.81 – 2026-09-25
- Seltene Kreaturen zusätzlich über Zielwechsel und seltene Namensplaketten erfasst; neue Sichtungen aktualisieren die Chronik.
- Rare-Filter zeigt die zuletzt gesichtete Kreatur im Kopfbereich mit Mouseover-Details.
- Rare-Elite und Sichtungszahl in der Liste hervorgehoben.

## 1.3.80 – 2026-09-25
- Wertvollster Fund zeigt am Mauszeiger Gegenstands-Tooltip, Stück- und Gesamtwert sowie ersten und letzten Fund.
- Beutezahl und Rare-Zahl im linken Kopfbereich linksbündig ausgerichtet.

## 1.3.79 – 2026-09-25
- Überlappung im Beute-Kopfbereich behoben: Beutefunde bleiben als große Zahl, Rare-Zahl steht darunter.
- Textbreite der linken Kopfbereichshälfte begrenzt.

## 1.3.78 – 2026-09-25
- Wertvollsten verkäuflichen Fund des aktiven Filters im Kopfbereich hervorgehoben.
- Händlerwert in Beutezeilen größer und deutlicher dargestellt; nicht verkäufliche Funde bleiben zurückhaltend.

## 1.3.77 – 2026-09-25
- Händlerverkaufspreis bei Beutefunden gespeichert und in der gebündelten Liste als Gesamtwert angezeigt.
- Tooltip zeigt Stückpreis und Gesamtwert; nicht verkäufliche und noch unbekannte Werte werden getrennt dargestellt.

## 1.3.76 – 2026-09-25
- Wiederholte Beutefunde in der Ansicht pro Gegenstand zusammengefasst, ohne die gespeicherten Einzelereignisse zu verändern.
- Gesamtmenge und Anzahl der Funde sichtbar gemacht; Tooltip zeigt ersten und letzten Fund.

## 1.3.75 – 2026-09-25
- Befüllte Beute- und Rare-Listen von schweren Karten auf kompakte Chronikzeilen mit feinen Trennlinien umgestellt.
- Seltene Begegnungen deutsch benannt und Hover-Verhalten bei Filterwechsel stabilisiert.

## 1.3.74 – 2026-09-25
- Leere Beute- und Rare-Sammlung als zwei große Chroniktafeln gestaltet, die den Platz für künftige Funde erklären.
- Tafeln verschwinden bei vorhandenen Funden oder beim Seitenwechsel; Filter und Suche behalten ihre bisherigen Listen.

## 1.3.73 – 2026-09-25
- Berufsdossier in den rechten Teil des oberen Handwerksbereichs verlegt.
- Separates Dossier unter dem Rezeptarchiv entfernt, damit die Rezeptliste höher beginnt.

## 1.3.72 – 2026-09-25
- Rezeptzahl direkt an jedem Beruf ergänzt und den ausgewählten Beruf sichtbar markiert.
- Rezeptarchiv vor das Berufsdossier gesetzt, damit erfasste Rezepte im sichtbaren Bereich erscheinen.

## 1.3.71 – 2026-09-25
- Anklickbares Berufsdossier mit Fertigkeit, Ausbildungsgrenze und zuletzt erfasstem Rezept ergänzt. Rechtsklick öffnet weiterhin das WoW-Berufsfenster.
- Berufsstand nutzt den Zeitpunkt der letzten Erfassung als Rückfallwert; der Rezept-Leerzustand erklärt die Erfassung.

## 1.3.70 – 2026-09-25
- Berufszeilen ohne schwere Kästen, mit feinen Trennlinien und sanfter Hervorhebung beim Darüberfahren gestaltet.
- Fortschrittsanzeigen auf schmale Goldlinien reduziert und vertikale Abstände verkürzt, damit das Rezeptarchiv besser ins Fenster passt.

## 1.3.69 – 2026-09-25
- Berufsseite als Handwerkschronik mit getrennten Kapiteln für Handwerkswege und Nebenkünste sowie breiten Fortschrittszeilen aufgebaut.
- Fortschritt zeigt die verbleibenden Punkte bis zur aktuellen Ausbildungsgrenze.
- Vorhandene Rezepte erscheinen wieder im Rezeptarchiv; ohne Rezepte wird ein gestalteter Leerzustand gezeigt.

## 1.3.68 – 2026-09-25
- Titelbereich mit Addonname, Version und Suche als eigenes Panel mit derselben Hintergrund- und Materialbehandlung wie die übrigen Chronicle-Flächen aufgebaut.

## 1.3.67 – 2026-09-25
- Oberen Chronicle-Header mit dezenten Eckmarkierungen an den Stil der Kapitel-Panels angeglichen.
- Materialstärke des Headers an die übrigen Inhaltsflächen angepasst.

## 1.3.66 – 2026-09-25
- Linken Akzentbalken an der Highlight-Loot-Vitrine entfernt.

## 1.3.65 – 2026-09-25
- Dicke Qualitätsbalken links an den Gegenstandszeilen entfernt.

## 1.3.64 – 2026-09-25
- Einzelne Fundstücke ohne geschlossene Kastenrahmen dargestellt; feine Trennlinien sowie dezente Auswahl- und Hoverflächen erhalten die Orientierung.
- Besitzdossier und Highlight-Loot mit goldenen Eckmarkierungen wie im Kapitelheader versehen.

## 1.3.63 – 2026-09-25
- Inventar- und Banklisten als Kapitel gegliedert: Questrelikte, besondere Funde, wertvolle Fundstücke und Reisegepäck.
- Kapitelüberschriften zeigen die Anzahl der Fundstücke und erhalten Mauszeiger-Tooltips.

## 1.3.62 – 2026-09-25
- Highlight-Loot und Besitzdossier rechts getauscht: besonderer Fund oben, ausgewählter Gegenstand darunter.
- Dezente Inventar- und Beutemotive innerhalb der beiden Karten sichtbar gemacht.

## 1.3.61 – 2026-09-25
- Zusätzliche Chronicle-Hinweiszeile aus Gegenstands-Tooltips entfernt, damit WoW-Gegenstandsdaten am Mauszeiger kompakter bleiben.

## 1.3.60 – 2026-09-25
- Doppelte Inventarillustration im Seitenhintergrund entfernt; Motive bleiben gezielt in Besitzdossier und Highlight-Loot-Vitrine.

## 1.3.59 – 2026-09-25
- Besitzarchiv mit Mauszeiger-Tooltips für Kopfbereich, Filter, Abschnittsüberschriften, Leerzustände, Fundstücke, Dossier und Highlight-Loot ergänzt.
- Bestehende Tooltips der Schnellnavigation und Charakterkarten an den Mauszeiger gesetzt.
- Highlight-Loot-Vitrine mit dezentem Beutemotiv, Qualitätslinie und ruhigerem Leerzustand verfeinert.

## 1.3.58 – 2026-09-25
- Besitzdossier kompakter angeordnet und Highlight-Loot nach oben verschoben, damit die Vitrine im sichtbaren Fenster Platz findet.

## 1.3.57 – 2026-09-25
- Rechts im Besitzarchiv eine Vitrine für Beute ab seltener (blauer) Qualität ergänzt.
- Die Vitrine zeigt den hochwertigsten Fund, bei gleicher Qualität den jüngsten; Klick öffnet Beute & Rares.
- Solange kein passender Fund erfasst ist, erscheint ein zurückhaltender Leerzustand.

## 1.3.56 – 2026-09-25
- Inventar und Bank als Besitzarchiv mit Fundstückliste und ausgewähltem Gegenstandsdossier gestaltet.
- Das Dossier zeigt Menge, Aufbewahrung, letzten Erfassungszeitpunkt und Händlerwert vor einem dezenten Inventarmotiv.
- Filter und Gegenstands-Tooltips bleiben erhalten.

## 1.3.55 – 2026-09-25
- Besitzübersicht mit Queststücken, wertvolleren Gegenständen und verkäuflichen Stapeln ergänzt.
- Questgegenstände erhalten eine warme goldene Kartenbehandlung; Qualitätsfarben bleiben für übrige Funde erhalten.

## 1.3.54 – 2026-09-25
- Inventar und Bank als zweispaltige Fundstück-Karten mit größeren Symbolen gestaltet.
- Qualitätsfarbe am Kartenrand und klarere Kennzeichnung von Quest-, ungewöhnlichen, seltenen und epischen Gegenständen ergänzt.

## 1.3.53 – 2026-09-25
- Klick auf eine Charakterkarte öffnet direkt die persönliche Chronik.
- Erinnerungen erscheinen nach Tagen gegliedert mit Uhrzeit, Ereignistyp und passendem Symbol; bis zu 50 Einträge werden angezeigt.

## 1.3.52 – 2026-09-25
- Charakterkarten erhalten kurze, individuelle Klassentitel über dem Namen.
- Ein dezenter Hinweis im Kartenfuß macht die anklickbare Charakterchronik sichtbar.

## 1.3.51 – 2026-09-25
- Eigenes transparentes Hexenmeister-Klassensiegel ergänzt: gehörntes Grimoire mit dämonischem Feuer.
- In die Charakterkarte mit derselben dezenten Sepia-Hintergrundbehandlung wie die anderen Klassensiegel eingebunden.

## 1.3.50 – 2026-09-25
- Klassensiegel nach visueller Referenz als große, entsättigte Sepia-Illustrationen in die Charakterkarten eingebettet.
- Niedrige Deckkraft lässt die Motive wie Teil des Kartenhintergrunds wirken, statt als separate Wappen zu erscheinen.

## 1.3.49 – 2026-09-25
- Klassensiegel nach Spiel-Screenshot auf den freien Kartenkörper begrenzt; Kopfzeile und Stufenanzeige bleiben frei.
- Größe und Deckkraft für bessere Einbindung in den Hintergrund angepasst.

## 1.3.48 – 2026-09-25
- Eigene Klassensiegel in den Charakterkarten deutlich vergrößert und als transparente Hintergrundillustration eingebettet.
- Separate Klassenbeschriftung bei eigenen Siegeln entfernt; Text bleibt über der Illustration lesbar.

## 1.3.47 – 2026-09-24
- Sechs weitere eigene Klassensiegel erstellt: Paladin, Krieger, Magier, Jäger, Schurke und Priester.
- Transparente TGA-Dateien in die Charakterkarten eingebunden; PNG-Originale unter artwork aufbewahrt.

## 1.3.46 – 2026-09-24
- Eigene transparente Chronicle-Klassensiegel für Druide und Schamane erstellt und in die Charakterkarten eingebunden.
- Originalgrafiken liegen unter artwork; weitere Klassen nutzen bis zu eigenen Siegeln die bisherigen Motive.

## 1.3.45 – 2026-09-24
- Charakterkarten zeigen ein dezentes Klassensiegel mit passendem Motiv für die neun klassischen Klassen.
- Siegel übernimmt die Klassenfarbe und wird bei schmalem Fenster ausgeblendet, damit Angaben lesbar bleiben.

## 1.3.44 – 2026-09-24
- Charakterübersicht mit Kennzeichnung des aktuellen Helden und nummerierten Gefährten erweitert.
- Klassenwappen, Name und Stufe stärker inszeniert; Inhalte und Klick-Navigation bleiben erhalten.

## 1.3.43 – 2026-09-24
- Charakterkarten mit Klassenwappen im farbigen Rahmen, stärkerem Namensauftakt und separatem Erinnerungsabschluss verfeinert.
- Abstände und Textbreiten an die neue Hierarchie angepasst; Charakterdetails bleiben per Klick erreichbar.

## 1.3.42 – 2026-09-24
- Charakterkarten als Heldenchronik neu gegliedert: Identität und Stufe, Reise, Chronik und Können sowie letzte Erinnerung.
- Talentzweige als Text statt der drei breiten Fortschrittsbalken; Charakterdetails per Klick bleiben erhalten.

## 1.3.41 – 2026-09-24
- Blasse quadratische Gegenstandssymbole aus den großen Statistikwerten entfernt; ruhigeres Chronikbild.
- Nicht mehr benötigte Symbol-Frames entfallen.

## 1.3.40 – 2026-09-24
- Statistikseite als Chronikübersicht neu gestaltet: Lotus-Siegel im Kopf, drei nummerierte Kapitel und stärkere Leitkennzahlen.
- Wiederholte Gegenstandssymbole aus den Nebenwerten entfernt; offene Typografie und feine Linien statt Tabellenanmutung.
- Alle Statistikwerte bleiben anklickbar und führen zu ihren Rubriken.

## 1.3.39 – 2026-09-24
- Statistikwerte als offene Chronik statt umrandetem Kachelraster dargestellt.
- Feine Trennlinien und dezente Hervorhebung beim Darüberfahren; Kennzahlen und Navigation bleiben erhalten.

## 1.3.38 – 2026-09-24
- Statistiklayout nach Spiel-Screenshot ausgerichtet: Leitkarte und Nebenwerte in einreihigen Bereichen gleich hoch.
- Farbige Kartenakzente bei Nebenwerten dezenter gesetzt, damit die Leitkennzahlen klarer wirken.

## 1.3.37 – 2026-09-24
- Statistiklayout nach Spiel-Screenshot verdichtet: flachere Leitkarten und alle Nebenwerte in kompakten Reihen.
- Breitenabhängige Spaltenzahl hält Einträge bei schmalem Fenster lesbar und zeigt auf großen Fenstern mehr Inhalt ohne Scrollen.

## 1.3.36 – 2026-09-24
- Statistikseite neu gesetzt: pro Bereich eine große Leitkennzahl und kompakte Einträge statt gleichförmigem Kartenraster.
- Mehr Gewicht für die wichtigsten Zahlen und ruhigere Kapitelüberschriften; Navigation per Klick bleibt erhalten.

## 1.3.35 – 2026-09-24
- Statistikseite: großes Chronikmotiv im Kopfbereich und drei Kapitel mit eigenen Symbolen.
- Erste Kennzahl jedes Kapitels stärker hervorgehoben; Karten bleiben anklickbar.

## 1.3.34 – 2026-09-24

- Statistikseite als Chronik-Kapitel überarbeitet: gerahmtes Buch im Kopfbereich, größere Gesamtzahl und freie Kapitelüberschriften mit farbigen Markierungen.
- Kennzahlen auf wärmeren Tafeln mit feineren Rahmen, klarer Typografie und farbigen Symbolfassungen statt schwerer schwarzer Rasterflächen.
- Kennzahlen öffnen beim Anklicken die zugehörige Rubrik; ein Tooltip weist darauf hin.

## 1.3.33 – 2026-09-24

- Rechter Buchungstafel ein gerahmtes Münzsymbol hinzugefügt; Rahmenfarbe folgt Einnahme, Ausgabe oder neutraler Korrektur.
- Wirtschaftsmotiv in der Tafel dezent sichtbar gemacht.

## 1.3.32 – 2026-09-24

- Nullbeträge in Summen, Tagesbilanzen und Buchungen neutral ohne Plus- oder Minuszeichen dargestellt.
- Positive Geldbewegungen bleiben grün, negative rot.

## 1.3.31 – 2026-09-24

- Gold & Wirtschaft im Stil des Death Journals aufgebaut: anklickbare Buchungszeitlinie links und Detailtafel mit Betrag, Zeit, Ort und Kontostand rechts.
- Tagesbilanzen bleiben in der Zeitlinie sichtbar; Plusbeträge grün und Minusbeträge rot.

## 1.3.30 – 2026-09-24

- Plusbeträge im Wirtschaftsverlauf einschließlich Summen und Tagesbilanz vollständig grün, Minusbeträge rot eingefärbt.
- Kopfbereich mit größeren Verlaufswerten; Buchungen als ruhigere Journalzeilen mit farbigen Wegpunkten und feinen Trennlinien gestaltet.

## 1.3.29 – 2026-09-24

- Gold & Wirtschaft als kompaktere Wirtschaftschronik gestaltet: gerahmte Münze, größere Vermögenszahl und Übersicht für Einnahmen, Ausgaben und Bilanz der angezeigten Buchungen.
- Tagesabschnitte zeigen ihre Bilanz; Buchungen erhalten stärkere Beträge, farbige Kennzeichnung und weniger Höhe.

## 1.3.28 – 2026-09-24

- Sichtbaren Spalt zwischen Header und Inhaltsfläche geschlossen.
- Deckende Headerfläche vor die transparente Fenstertextur gelegt; Schrift, Lotus und Trennlinie bleiben darüber.

## 1.3.27 – 2026-09-24

- Warmen Braunton und die leichte Papierstruktur im Header wiederhergestellt.
- Header-Fläche auf eine sichtbare, deckende Ebene gesetzt und bis zur Trennlinie verlängert; Hauptfläche auf denselben Ton abgestimmt.

## 1.3.26 – 2026-09-24

- Header-Hintergrund auf denselben deckenden Braunton wie der Inhaltsbereich gesetzt.
- Zusätzliche farbige Aufhellung am oberen Rand des Inhaltsbereichs entfernt.

## 1.3.25 – 2026-09-24

- Gedenktafel für historische Fälle ohne Kampfdaten verkürzt; das doppelte Todesmotiv unter der Tafel entfernt.
- Tafelmotiv abgeschwächt, damit die vorhandenen Details im Vordergrund bleiben.

## 1.3.24 – 2026-09-24

- Gedenktafel linksbündig ausgerichtet und Ort aus derselben Quelle wie in der Zeitlinie angezeigt.
- Bei älteren Fällen nur noch ein klarer Hinweis auf fehlende Kampfdaten statt wiederholter Platzhalter; Hintergrundmotiv dezenter.

## 1.3.23 – 2026-09-24

- Death Journal mit anklickbarer Zeitlinie und dezenten Wegpunkten links sowie Gedenktafel rechts. Ausgewählter Fall zeigt vollständigen Ort, Zeitpunkt, Gegner, Todesursache und erfassten Schaden.
- Frühere Fälle ohne Kampfdaten werden in der Detailtafel ausdrücklich als solche gekennzeichnet.

## 1.3.22 – 2026-09-24

- Death Journal als Gedenktafel verfeinert: gerahmtes Todessymbol, großes Datum, Tageskapitel mit Markierungen und bronzene Fassungen in der Chronik.
- Die kompakte Anordnung sowie die Erfassung von Gegner und Ursache bleiben erhalten.

## 1.3.21 – 2026-09-24

- Death Journal mit flachem Kopfbereich und schmaler Kennzahlenzeile neu geordnet; die Chronik beginnt früher.
- Fehlende historische Todesursachen werden in den Zeilen nicht mehr wiederholt. Der Tooltip kennzeichnet sie weiterhin.

## 1.3.20 – 2026-09-24

- Death Journal kompakter gestaltet; Gegner und Todesursache erscheinen bei neuen Fällen direkt in der Chronik und ausführlich im Tooltip.
- Letzten Schaden aus dem Kampflog nur kurz im Speicher gehalten und beim Tod gesichert. Ältere Fälle bleiben ohne nachträglich erfundene Ursache.

## 1.3.19 – 2026-09-24

- Death Journal zeigt den jüngsten Tod nur noch im großen Kopfbereich; die Zeitlinie enthält frühere Fälle ohne Dopplung.

## 1.3.18 – 2026-09-24

- Death Journal vollständig als Gedenk-Zeitlinie neu aufgebaut: großer letzter Fall, drei kompakte Kennzahlen, Tagesabschnitte und Einträge an einer Chronik-Linie.
- Tagesüberschriften und Einträge werden beim Rubrikwechsel sauber ausgeblendet.

## 1.3.17 – 2026-09-24

- Death Journal mit neuer Abschnittsüberschrift und Gedenkkarten: eindeutige Lesereihenfolge für Eintragsnummer, Gebiet, Zeitpunkt und Untergebiet.
- Linksbündige Ausrichtung im Kopfbereich und in den Karten korrigiert; Kartenabstände vergrößert.

## 1.3.16 – 2026-09-24

- Zusätzlichen oberen Innenstrich aus der großen leeren Dungeon- und Bossbeute-Karte entfernt.

## 1.3.15 – 2026-09-24

- Beim Wechsel von der großen Einzelkarte zur Bossliste werden wiederverwendete Eckornamente korrekt ausgeblendet.

## 1.3.14 – 2026-09-24

- Inventar- und Bankscan prüft alle verfügbaren Behälterplätze, bevor Daten aktualisiert werden.
- Oberflächenaktualisierungen werden kurz gebündelt; bereits gebundene Charakterdaten werden nicht bei jedem Rendern erneut gesucht.
- Unsichtbare Textlisten werden bei Seiten mit eigener Kartenansicht nicht mehr berechnet.
- Scrollposition bleibt bei Datenaktualisierungen auf derselben Seite erhalten.
- Bossbeute ist nun auch über die globale Suche auffindbar.

## 1.3.13 – 2026-09-24

- Statistik: äußere Gruppenrahmen entfernt und alle Kacheln mit einheitlichem Innenabstand und größeren Zeilenabständen angeordnet.

## 1.3.12 – 2026-09-24

- Fehlendes Symbol in der Statistik-Kachel Bosssiege durch ein verfügbares Boss-Symbol ersetzt.
- Statistik-Gruppen und Kacheln auf einheitliche, feine Rahmen umgestellt; Hover-Rahmen abgeschwächt.

## 1.3.11 – 2026-09-24

- Dicke farbige Akzentbalken auf Karten und Kacheln in allen Rubriken entfernt.
- Goldene Eckmarkierungen aus Version 1.3.9 wiederhergestellt.

## 1.3.10 – 2026-09-24

- Goldene Eckmarkierungen auf Kapitelkarten und großen Inhaltskarten entfernt.

## 1.3.9 – 2026-09-24

- Neuer Reiter Bossbeute mit Gegenstand, Empfänger, Boss und Zeitpunkt sowie WoW-Gegenstandstooltip.
- Erfassung über ENCOUNTER_LOOT_RECEIVED und vorsichtigen CHAT_MSG_LOOT-Fallback nach Boss-Siegen.

## 1.3.8 – 2026-09-24

- Dungeons & Bosse: höhere Kapitelkarte, größere Überschriften und Register, überarbeitete Abstände zur Annäherung an das Designkonzept.

## 1.3.7 – 2026-09-24

- Dungeons & Bosse: rundes Goldmedaillon für Instanzen, flankierende Ornamentlinien und neu ausgerichtete Texte in der großen Karte und im Leerzustand.

## 1.3.6 – 2026-09-24

- Behebt die zu kurze Instanzkarte und versetzte Navigation durch eine falsch platzierte Höhenberechnung.
- Das Instanzmotiv bleibt innerhalb der großen Karte; Titel und Kennzahlen werden wieder korrekt umrahmt.

## 1.3.5 – 2026-09-24

- Leere Rubriken füllen die verfügbare Inhaltsfläche wie im Mockup und zentrieren ihren Hinweis entsprechend.
- Das Rubrikmotiv erscheint in diesen Ansichten nur noch einmal innerhalb der gerahmten Fläche.
- Die großen Hinweiskarten erhalten dieselben goldenen Eckdetails wie die Kapitelkarten.
- Eine dezente Leder-Pergament-Textur verbindet Fensterkopf, Navigation, Seitenflächen und Kapitelkarten.

## 1.3.4 – 2026-09-24

- Behebt einen Ladefehler durch das Lua-Limit von 200 lokalen Variablen in UI.lua.
- Der Instanz-Umbau aus 1.3.3 ist wieder enthalten und wurde zusätzlich vom Lua-Compiler geprüft.

## 1.3.3 – 2026-09-24

- Die Instanzseite wurde direkt gegen den Mockup-Aufbau angepasst: höhere Kopfkarte, größere Reiter und eine bildschirmfüllende Inhaltskarte.
- Einzelne Instanzen und Bosse erscheinen als zentrierte Kapitel mit großem Symbol, Titel, Kennzahlen und einem einzigen großen Hintergrundmotiv.
- Goldene Eckornamente vereinheitlichen die Kopfkarten aller Rubriken und die Instanzfläche.

## 1.3.2 – 2026-09-24

- Jede Haupt-Rubrik besitzt jetzt eine Kapitelkarte mit Titel, Beschreibung, Kennzahlen und passendem Symbol.
- Charaktere, Inventar & Bank, Ziele und Notizen wurden auf das Mockup-Raster umgestellt; leere Charakterlisten erhalten eine gestaltete Karte.
- Charakterdetails nutzen denselben Rahmenstil wie die übrigen Kapitelkarten.

## 1.3.1 – 2026-09-24

- Gemeinsame Mockup-Sprache für alle Rubriken: größere Seitentitel, Suchsymbol, gerahmte aktive Navigation und einheitliche Kopfkarten.
- Ziele und Notizen verwenden hervorgehobene Karten; leere Seiten zeigen gestaltete Hinweiskarten mit passendem Motiv.
- Einträge der Instanzrubrik passen sich der verfügbaren Fläche an.

## 1.3.0 – 2026-09-24

- Ein einzelner Instanz- oder Bosseintrag wird als breite Kapitelkarte dargestellt und nutzt die zuvor leere Fläche.
- Kapitelkarte mit größerem Symbol, sauber linksbündigen Angaben, Trennlinie und dezentem Instanzmotiv.
- Die Kennzahlensymbole in der Kopfkarte sind besser lesbar.

## 1.2.99 – 2026-09-24

- Größerer Lotus und höhere Kopfzeile bringen die Fensterproportionen näher an den Entwurf.
- Statistikgruppen liegen auf eigenen ruhigen Tafeln statt direkt auf dem Seitenhintergrund.
- Hintergrundmotive sind hinter dichten Inhalten dezenter; die Instanz-Leeransicht behält ihr hervorgehobenes Motiv.

## 1.2.98 – 2026-09-24

- Ein eigenes Lotus-Emblem steht im Fensterkopf und in der Addon-Liste.
- Dungeons & Bosse zeigt seine drei Kennzahlen als klare Symbolreihe.
- Leere Instanz- und Bosslisten erhalten eine große gestaltete Karte mit Rubrikmotiv und hilfreichem Hinweis.

## 1.2.97 – 2026-09-24

- Sichtbarer Addon-Name in Fenster, Addon-Liste und Tooltip: Schwarzer Lotus Chronicle.
- Die Versionsnummer steht jetzt auch direkt im Fensterkopf und im Tooltip.
- Technischer Addon-Ordner und SavedVariables-Namen bleiben für bestehende Daten kompatibel.

## 1.2.96 – 2026-09-23

- Alle Rubriken verwenden eine einheitliche warme Grundfläche für Karten und Steuerelemente.
- Die großen Kopfkarten teilen sich denselben Chronicle-Hintergrund; Rubrikfarben bleiben als Akzent erhalten.
- Die Illustrationen und Seitenstruktur bleiben in allen Rubriken konsistent.

## 1.2.95 – 2026-09-23

- Death Journal führt Todesfälle aus Charakterdaten und einer separaten lokalen Sicherung ohne Duplikate zusammen.
- Der Chronicle-Wächter sichert neue Todesfälle nach vollständigen SavedVariables-Schreibvorgängen in DeathRecovery.lua.
- Bereits verlorene Todesfälle aus vorhandenen Sicherungen werden wiederhergestellt.
- Dungeons & Bosse zeigt bei fehlenden Daten eine gestaltete Infokarte.

## 1.2.94 – 2026-09-23

- Alle 15 Hintergrundmotive wurden durch handgemalte, transparente Stillleben im Stil der WoW-Vorlage ersetzt.
- Jede Rubrik behält ein eigenes Thema; die Motive bleiben dezent hinter den Inhalten.
- Die PNG-Originale liegen im Projektordner artwork, die TGA-Dateien im Addon.

## 1.2.93 – 2026-09-23

- Alle 15 Rubrikmotive wurden als reichere Gravuren mit Zierrahmen, Skalen und feinen Schraffuren neu gezeichnet.
- Die Motive sind etwas größer und besser sichtbar, bleiben aber dezent hinter dem Inhalt.

## 1.2.92 – 2026-09-23

- Berufskarten zeigen am Mauszeiger Fertigkeit, Fortschritt und erfasste Rezeptzahl.
- Zuletzt gelernte Rezepte zeigen nach Möglichkeit den WoW-Gegenstands- oder Zaubertooltip, ergänzt um Beruf und Erfassungsdatum.
- Falls der Client keinen nativen Tooltip liefert, erscheint ein eigener Rezepttooltip.

## 1.2.91 – 2026-09-23

- Alle 15 Rubriken verwenden nun eigene, transparent gezeichnete Hintergrundmotive statt vergrößerter Icons.
- Die Motive sitzen dezent im unteren rechten Inhaltsbereich und bleiben beim Scrollen an Ort und Stelle.

## 1.2.90 – 2026-09-23

- Death Journal zeigt eine eigene Übersicht und Karten für gespeicherte Todesfälle.
- Die Karten enthalten Gebiet, Untergebiet beziehungsweise Instanz und Zeitpunkt; ohne Einträge erscheint ein gestalteter Leerzustand.

## 1.2.89 – 2026-09-23

- Inhaltsbereich und Seitennavigation erhalten warme Braunwerte statt nahezu schwarzer Flächen.
- Ein dezenter Farbauftrag oben und eine untere Linie verbinden freie Flächen optisch mit den Karten und dem Rahmen.

## 1.2.88 – 2026-09-23

- Jede Rubrik erhält ein eigenes, dezentes Hintergrundmotiv aus drei thematisch passenden WoW-Symbolen.
- Die Motive sind entsättigt und zurückhaltend eingefärbt, damit Texte und Karten lesbar bleiben.

## 1.2.87 – 2026-09-23

- Todesfälle werden zusätzlich über den Gesundheitsstatus erkannt, falls PLAYER_DEAD ausbleibt.
- Mehrfach-Events desselben Todes erzeugen nur einen Journaleintrag; die Charakterübersicht wird sofort aktualisiert.

## 1.2.86 – 2026-09-23

- Dungeons & Bosse zeigt Instanzen und Bosskämpfe in getrennten Registern mit Suche und Karten.
- Bosskarten unterscheiden Siege von Versuchen; Instanzkarten zeigen Besuche und Zeitpunkte.
- Die Navigation schreibt NPC & Händler nun einheitlich mit Umlaut.

## 1.2.85 – 2026-09-23

- NPC & Händler zeigt Begegnungen als Karten mit Ort, Häufigkeit und letztem Kontakt.
- Register trennen alle NPCs, Händler und andere Begegnungen.
- Suche und Sortierung nach letztem Kontakt, Häufigkeit oder Name erleichtern die Übersicht.

## 1.2.84 – 2026-09-23

- Gebiete zeigt eine Reiseübersicht und Gebietskarten mit Erstbesuch, letztem Besuch, Besuchszahl und Untergebiet.
- Suche und Sortierung nach zuletzt besucht, häufig besucht oder Name erleichtern die Orientierung.

## 1.2.83 – 2026-09-23

- Das Questjournal-Symbol sitzt mittig im oberen rechten Kopfbereich und berührt den Querstrich nicht mehr.
- Die Trennlinie endet vor dem Symbolbereich.

## 1.2.82 – 2026-09-23

- Das Questjournal-Symbol sitzt mittig im rechten Symbolbereich des Kopfes.

## 1.2.81 – 2026-09-23

- Das Questjournal-Symbol ist wieder klein und klar sichtbar, rechts im Kopfbereich vertikal mittig ausgerichtet.

## 1.2.80 – 2026-09-23

- Das Questmotiv erscheint im Journal-Kopf als größeres, dezentes Wasserzeichen.
- Rubrikmotive liegen nun im scrollbaren Inhalt, damit sie hinter freien Flächen sichtbar werden.

## 1.2.79 – 2026-09-23

- Gebietssymbole sind in einem einheitlichen Feld mittig ausgerichtet.
- Jede Rubrik erhält ein zurückhaltendes Hintergrundmotiv passend zu ihrem Symbol.

## 1.2.78 – 2026-09-23

- Die Quest-Historie zeigt Tagesabschnitte und sortiert neue Einträge nach oben.
- Filter für Alle, Abgeschlossen und Angenommen erleichtern die Suche.
- Angenommene und abgeschlossene Einträge haben eigene Farben und Statusplaketten.

## 1.2.77 – 2026-09-23

- Gebietsnamen in den aufklappbaren Questgruppen sind linksbündig ausgerichtet.
- Questgebiete verwenden das bereits in Chronicle genutzte Gebietssymbol.
- Kapitelnummern, Queststatus und ein klarer Aufklapphinweis geben den Gebietsgruppen mehr Struktur.

## 1.2.76 – 2026-09-23

- Questgebiete haben eigene hervorgehobene Kopfzeilen mit Symbol, Questzahl und Abgabestatus.
- Gebietsköpfe lassen sich wie im WoW-Questlog auf- und zuklappen.
- Questkarten erhalten ein klareres Statusfeld und eine Stufenplakette.

## 1.2.75 – 2026-09-23

- Aktive Quests werden nach den Gebietsrubriken des WoW-Questlogs sortiert und gruppiert.
- Ein Filter zeigt nur Quests, die zur Abgabe bereit sind.

## 1.2.74 – 2026-09-23

- Questjournal mit stärkerem Kopfbereich und getrennten Zahlen für aktive, abgeschlossene und gespeicherte Quests.
- Questkarten zeigen Stufe und Bearbeitungsstatus; zur Abgabe bereite Quests erhalten einen grünen Akzent.
- Verfeinerte Abstände und Linien geben der Ansicht mehr Struktur.

## 1.2.73 – 2026-09-23

- Quests trennt aktive Aufgaben und Historie in direkt erreichbare Register.
- Die Suche filtert die gewählte Ansicht; die Gesamtzahlen bleiben dabei sichtbar.

## 1.2.72 – 2026-09-23

- Quests zeigt aktive Aufgaben und die Quest-Historie als Karten.
- Eigene Quest-Suche filtert beide Bereiche nach Namen.
- Aktive Questkarten öffnen die passende Quest im WoW-Questlog.

## 1.2.71 – 2026-09-23

- Questkarten in Abenteuer öffnen aktive Quests direkt im WoW-Questlog.
- Neue Questereignisse speichern die Quest-ID; ältere Einträge werden anhand des Titels abgeglichen.
- Für abgeschlossene oder nicht eindeutig zuordenbare Quests erscheint ein Hinweis statt einer falschen Quest.

## 1.2.70 – 2026-09-23

- Abenteuer fasst Serien gleichzeitig angenommener Quests in einer aufklappbaren Karte zusammen.
- Die einzelnen Questnamen bleiben gespeichert und sind per Klick und Tooltip zugänglich.
## 1.2.69 – 2026-09-23

- Abenteuer ist jetzt eine Chronik mit Tagesabschnitten, Ereigniskarten, Symbolen und verständlichen Kategorien.
- Filter für Alle, Quests & Ziele, Reise, Berufe und Weitere erleichtern die Übersicht.
- Ältere Einträge lassen sich in Blöcken von 100 nachladen; Ereigniskarten zeigen Details im Mauszeiger-Tooltip.
## 1.2.68 – 2026-09-22

- Nicht darstellbare Pfeilzeichen auf „Wo war ich?“ entfernt.
## 1.2.67 – 2026-09-22

- Startseite: Begrüßung, Metadaten und Kennzahlen sind einheitlich linksbündig ausgerichtet.
- Fehlende Kartentexturen wurden gegen verfügbare WoW-Symbole ausgetauscht.
- Bei fehlenden persönlichen Zielen führt eine zusätzliche Karte zu den aktiven Quests.
- Erinnerungen zeigen ihre Art und vermeiden direkt aufeinanderfolgende gleichartige Meldungen.
## 1.2.66 – 2026-09-22

- Beute & Rares: Filter für Alle, Quest, Grün+ und Rares sowie eine lokale Suche nach Name und Fundort.
- Rare-Karten zeigen per Mauszeiger-Tooltip Gebiet, erste und letzte Sichtung sowie Sichtungszahl.
- „Wo war ich?“ wurde als Startseite mit Reiseübersicht, anklickbaren Kennzahlen, Zielen und Erinnerungen neu gestaltet.
## 1.2.65 – 2026-09-22

- Der Beute-Gegenstands-Tooltip erscheint jetzt am Mauszeiger.

## 1.2.64 – 2026-09-22

- Beute & Rares besitzt jetzt eine vollständig gestaltete Fundstückübersicht.
- Beutekarten zeigen Gegenstandssymbol, Qualitätsfarbe, Menge, Fundzeit und Fundort.
- Beim Darüberfahren erscheint der originale WoW-Gegenstands-Tooltip mit zusätzlichem Chronicle-Fundkontext.
- Das Rare Journal verwendet eigene Karten für Kreatur, Gebiet, letzte Sichtung und Sichtungszahl.
## 1.2.63 – 2026-09-22

- Die gesamte Seitenreiterleiste wird jetzt vertikal exakt am Chronicle-Fenster zentriert.
- Die Metallreiter schließen bündig ohne sichtbaren Abstand am rechten Fensterrahmen an.
- Die Symbole bleiben innerhalb ihrer Reiter mittig ausgerichtet.
## 1.2.62 – 2026-09-22

- Der Metallrahmen der Seitenreiter liegt nun korrekt hinter den Symbolen und verdeckt sie nicht mehr.
- Der goldene Auswahlglanz bleibt als transparente obere Ebene erhalten.
## 1.2.61 – 2026-09-22

- Die Seitenreiter verwenden jetzt die originale WoW-Zauberbuchreiter-Textur SpellBook-SkillLineTab.
- Rahmenform, Symbolfläche, seitlicher Versatz und goldene Auswahl entsprechen dadurch dem Referenzbild wesentlich genauer.
## 1.2.60 – 2026-09-22

- Der leere schwarze Gebiete-Reiter verwendet jetzt eine in dieser WoW-Version verfügbare Kartentextur.
## 1.2.59 – 2026-09-22

- Die Rubrikreiter verwenden jetzt den klassischen WoW-Aktionsleistenstil.
- Größere quadratische Symbole, Metallrahmen, überlappende Anordnung und goldener Auswahlglanz entsprechen dem Referenzbild.
- Die Reitergröße passt sich automatisch an die Fensterhöhe an.
## 1.2.58 – 2026-09-22

- Alle Chronicle-Rubriken besitzen jetzt einen Symbolreiter am rechten Fensterrand.
- Die aktive Rubrik wird gold hervorgehoben; Tooltips zeigen Name und Funktion.
- Die bestehende Textnavigation bleibt vollständig erhalten.
## 1.2.57 – 2026-09-22

- Die vollständigen Rezeptlisten pro Beruf wurden aus der Berufsseite entfernt.
- Unter den Berufskarten folgt jetzt direkt der kompakte Bereich "Zuletzt gelernt".
## 1.2.56 – 2026-09-22

- Am Ende der Berufsseite werden die sechs zuletzt erfassten Rezepte aller Berufe gemeinsam angezeigt.
- Die Einträge zeigen Rezeptsymbol, Beruf sowie Datum und Uhrzeit der ersten Erfassung.

## 1.2.55 – 2026-09-22

- Ein Klick auf eine Berufskarte öffnet jetzt das zugehörige WoW-Berufsfenster.
- Berufskarten zeigen beim Darüberfahren eine goldene Hervorhebung und einen Bedienhinweis.

## 1.2.54 – 2026-09-22

- Berufe und Rezepte besitzen jetzt eine vollständig gestaltete Übersichtsseite.
- Berufskarten zeigen Rang, Fortschritt und ein passendes Symbol.
- Gelernte Rezepte erscheinen gruppiert in einem zweispaltigen Kartenraster.

## 1.2.53 – 2026-09-22

- Die Sammlung auf der Statistikseite verwendet jetzt ein gleichmäßiges 3×3-Raster.
- Die Statistikseite springt beim Öffnen zuverlässig an den Anfang.

## 1.2.52 – 2026-09-22

- Statistik-Karten mit individuellen Symbolen und farbigem Leuchteffekt aufgewertet
- Nullwerte visuell zurueckgenommen und erreichte Werte staerker hervorgehoben
- Statistik-Kopfbereich um eine kompakte Reise-, Quest- und Begegnungszusammenfassung erweitert
- Karten reagieren beim Darueberfahren mit hervorgehobenem Rahmen

## 1.2.51 – 2026-09-22

- Seiteninhalt an die veraenderte Fensterbreite angepasst
- Statistik-Karten, Charakterkarten, Dossier, Inventar und Goldverlauf responsiv verbreitert
- Spalten, Filter, Talentbalken und Textbreiten nach dem Loslassen eines Ziehgriffs neu berechnet

## 1.2.50 – 2026-09-22

- Chronicle-Fenster an allen vier Kanten und vier Ecken skalierbar gemacht
- sichtbaren Ziehgriff unten rechts ergaenzt
- Fenstergroesse accountweit gespeichert und bei erneutem Laden wiederhergestellt
- `/chr resetpos` setzt nun Position und Groesse zurueck

## 1.2.49 – 2026-09-22

- Statistikseite als Dashboard mit grosser Chronikzahl neu gestaltet
- Reise, Quests und Sammlung in farblich getrennte Kennzahlenkarten aufgeteilt
- Statistikwerte fuer schnelleres Erfassen deutlich hervorgehoben

## 1.2.48 – 2026-09-22

- einzelne Talentnamen von den Charakterkarten entfernt und Karten kompakter gemacht
- vollstaendige Talentliste weiterhin im Profil des Charakterdossiers angezeigt

## 1.2.47 – 2026-09-22

- Goldbetrag im Charakterdossier eindeutig beschriftet
- Innenabstand der Detailkarten fuer ruhigere Darstellung vergroessert

## 1.2.46 – 2026-09-22

- Charakterdetailseite als umfangreiches Charakterdossier neu gestaltet
- grosser Kopfbereich mit Klassenfarbe, Gilde, Gold, Aufenthaltsort und Talentverteilung ergaenzt
- Detailreiter fuer Profil, Quests, Sammlung und Chronik eingebaut
- Quests, Ziele, Talente, Berufe, Besitz und Erinnerungen in eigene Karten aufgeteilt

## 1.2.45 – 2026-09-22

- Geldstand waehrend des Spielens regelmaessig geprueft, damit fehlende PLAYER_MONEY-Ereignisse keine Buchungen verschlucken
- kurzzeitige 0-Kupfer-Werte vor dem Aufzeichnen erneut bestaetigt
- Goldkarte bezeichnet die letzte Buchung als letzte erfasste Bewegung

## 1.2.44 – 2026-09-22

- Goldseite mit grossem Kontostand und eigenen Tagesabschnitten neu gestaltet
- Einnahmen und Ausgaben als Karten mit farbigem Akzent, Zeit, Ort, Betrag und Kontostand dargestellt
- Nullwert-Schalter und ausgeblendete historische Fehlbuchungen beibehalten

## 1.2.43 – 2026-09-22

- bestaetigte aeltere falsche Nullbuchungen aus der Zeit vor der Logout-Korrektur ausgeblendet
- Schalter zum Ein- und Ausblenden dieser gespeicherten Buchungen auf der Goldseite ergaenzt
- mehr Abstand zwischen Buchungen im Geldverlauf

## 1.2.42 – 2026-09-22

- fehlerhafte 0-Kupfer-Momentaufnahme beim Logout nicht mehr als Ausgabe gespeichert
- bekannte falsche Logout-Buchungen im Goldverlauf und in der Suche ausgeblendet, ohne gespeicherte Daten zu loeschen
- Geldverlauf nach Tagen gegliedert und Einnahmen sowie Ausgaben farblich unterschieden

## 1.2.41 – 2026-09-22

- Inventar und Bank nach Alle, Quest, Gruen+ und Verkaeuflich filterbar gemacht
- Summen beziehen sich bei aktivem Filter auf sichtbare Gegenstaende
- fuehrende Nullmuenzen in Geldbetraegen ausgeblendet

## 1.2.40 – 2026-09-22

- Gold, Silber und Kupfer in allen Chronicle-Betraegen mit eigenen Farben dargestellt
- Geldsuche weiterhin auf dem unformatierten Betrag ausgefuehrt

## 1.2.39 – 2026-09-22

- Haendlerverkaufspreis pro Stueck und Wert des gesamten Stapels unter Inventar- und Bankgegenstaenden ergaenzt
- Verkaufspreise bei der Erfassung gespeichert; fehlende oder unverkaeufliche Preise gekennzeichnet

## 1.2.38 – 2026-09-22

- Inventar und Bank als getrennte Bereiche mit Erfassungszeit und Summen gestaltet
- Gegenstaende mit Icon, Qualitaetsfarbe, Menge und Tooltip aufgelistet
- Questgegenstaende und wertvolle Gegenstaende deutlich markiert

## 1.2.37 – 2026-09-22

- farbige Umrandung der Klassenicons auf den Charakterkarten entfernt

## 1.2.36 – 2026-09-22

- Charakterkarten mit Klassenfarben, breiterem Kopfbereich und groesserem Klassenicon gestaltet
- Talentzweige durch drei Balken visualisiert und Karten beim Darueberfahren hervorgehoben
- Abstaende der Charakterdaten fuer bessere Lesbarkeit erweitert

## 1.2.35 – 2026-09-22

- Absturz der Talentzweig-Berechnung durch eine nicht initialisierte Tabelle behoben
- gelernte Talente und Punkte werden nach erneutem Laden wieder erfasst

## 1.2.34 – 2026-09-22

- bei eindeutig getrennten Talentzweigen die gekauften Punkte pro Zweig erfasst
- Charakterkarten zeigen Zweignamen, Punktverteilung und den stärksten Zweig beziehungsweise Hybrid

## 1.2.33 – 2026-09-22

- gelernte Talente und Ränge direkt auf den Charakterkarten sichtbar gemacht
- Talentpositionen für die spätere Zuordnung zu den Forever-Talentzweigen im Snapshot ergänzt

## 1.2.32 – 2026-09-22

- generischen Klassennamen nicht mehr als Skillung ausgegeben
- tatsächlich gekaufte Talentpunkte aus lesbaren Trait-Knoten erfasst; committed Talent-Einträge bevorzugt
- fehlende Talentdaten deutlich gekennzeichnet

## 1.2.31 – 2026-09-22

- anklickbare Charakterkarten mit Detailansicht für Quests, Ziele, Berufe, Inventar, Bank und Erinnerungen ergänzt
- Gilde und Rang sowie Skillung, Vorlage und lesbare Talente bei verfügbarer Forever-API gespeichert
- Gilden- und Talentdaten in die universelle Suche aufgenommen

## 1.2.30 – 2026-09-22

- Charakterseite mit getrennten Karten, Klassenicons und Klassenfarben neu gestaltet
- Gold, Aktivitäten, Berufe und letzte Erinnerung pro Charakter klarer angeordnet

## 1.2.29 – 2026-09-22

- Charakterübersicht um Rasse, Fraktion, aktive Quests, offene Ziele, Notizen, Berufe und letzte Erinnerung erweitert
- Summe der zuletzt bekannten Goldstände aller erfassten Charaktere ergänzt

## 1.2.28 – 2026-09-22

- Hauptfenster mit klassischem WoW-Dialograhmen und dunklem Titelstreifen gestaltet
- linke Navigation in Reise, Sammlung und Charakter gegliedert und kompakter gesetzt

## 1.2.27 – 2026-09-21

- optionalen lokalen Monitor für versionierte Backups jeder vollständigen Chronicle-SavedVariables-Datei ergänzt
- Sync-Skript verweigert jetzt auch Saves mit weniger Chronik-Einträgen

## 1.2.26 – 2026-09-21

- vorheriges echtes Sitzungsende separat von Reload-Speicherzeiten gemerkt
- Startseite zeigt bei unklaren Altdaten keinen fälschlichen Reload-Zeitpunkt als letzte Sitzung

## 1.2.25 – 2026-09-21

- UI-Reload nicht mehr als neue Spielsitzung in der Chronik erfasst
- vorherige Sitzungszeit bei einem Reload beibehalten

## 1.2.24 – 2026-09-21

- Recovery ergänzt fehlende Charaktere auch bei teilweise geladener Datenbank
- Sync-Skript schützt vor dem Überschreiben eines Snapshots mit weniger Charakteren

## 1.2.23 – 2026-09-21

- Charakterjournal nur noch übernommen, wenn es zum aktuellen Charakter gehört
- Verwechslung von Alt-Journalen beim Wechsel auf einen zweiten Charakter verhindert
- doppelte Charakterzusammenfassungen anhand von GUID oder Name und Realm bereinigt
- aktuelle Figur und Gesamtzahl in der Charakterübersicht gekennzeichnet

## 1.2.22 – 2026-09-21

- Startseite zeigt bis zu drei selbst gesetzte offene Ziele als nächste Schritte
- Leerer Zielbestand und weitere offene Ziele erhalten klare Hinweise

## 1.2.21 – 2026-09-21

- Statistikseite nach Reise, Quests und Sammlung gegliedert
- Instanzbesuche, Bossversuche und Boss-Siege getrennt und korrekt gezählt
- Händlerzahl mit NPC-Ansicht abgeglichen; seltene Kreaturen und Ziele ergänzt
- Questabschlüsse nur aus tatsächlich abgeschlossenen Einträgen berechnet

## 1.2.20 – 2026-09-21

- Goldseite liest den aktuellen Spielgeldstand direkt aus dem Client
- Geldstand bei Login ohne künstliche Transaktion abgeglichen
- Verpasste Geldänderungen beim Öffnen des Journals oder beim Logout nachgetragen

## 1.2.19 – 2026-09-21

- Negative Geldänderungen mit korrekt zerlegten Gold-, Silber- und Kupferbeträgen angezeigt
- Unlesbares Pfeilsymbol im Goldjournal durch eindeutige Beschriftung des Kontostands ersetzt

## 1.2.18 – 2026-09-21

- Instanzbesuche bei geladenen Gebietsdaten erfasst und UI-Reloads nicht als neue Besuche gezählt
- Dungeon- und Boss-Seite nach letztem Besuch sortiert und mit verständlichen Leerzuständen versehen
- Bossbegegnungen mit Ort und Zeitpunkt ergänzt; ungültige Ereignisse ignoriert

## 1.2.17 – 2026-09-21

- Suche zeigt bei Einträgen ohne Zeitstempel kein falsches Datum mehr an

## 1.2.6 – 2026-09-21

- Beuteansicht, Beutesuche und Beutestatistik auf Questgegenstände und Qualität Grün oder besser gefiltert
- Questkennzeichnung über die Container-Questinfo erfasst
- Qualität aus Containerdaten gespeichert, mit Forever-Item-Link als Fallback

## 1.2.5 – 2026-09-21

- Gegenstandsgewinne aus positiven Änderungen im eigenen Inventar erfasst
- Forever-Item-Links im Format `|cnIQ...` ohne Chat-Parser unterstützt
- fremde Gruppenbeute nicht mehr versehentlich in der persönlichen Historie erfasst
- Bankbewegungen während geöffneter Bank nicht als Beute protokolliert

## 1.2.4 – 2026-09-21

- neu erkannte Berufe zunächst nur als Ausgangsstand gespeichert
- Berufsereignisse ausschließlich bei späteren Rang- oder Maximalrangänderungen erzeugt

## 1.2.3 – 2026-09-21

- unbekannte Gebiete nicht mehr als persönliche Entdeckungen erfasst
- Login-Eintrag ohne Ortsangabe, falls der Client das Gebiet noch nicht kennt
- Berufsereignisse nur bei geänderten Rängen oder neu erkannten Berufen protokolliert
- alte Platzhalter- und Berufs-Störeinträge in der Startübersicht ausgeblendet, ohne die Historie zu löschen

## 1.2.2 – 2026-09-21

- Fenster, Seitenleiste und Inhaltsbereich mit nahezu deckendem dunkelbraunem Hintergrund lesbarer gestaltet
- ausgewählten Navigationspunkt mit goldener Markierung dauerhaft sichtbar gemacht
- Notizen mit klar getrennten Einträgen, größerer Schrift und besserem Kontrast dargestellt
- Öffnen des Fensters aktualisiert die Startseite sofort; Escape schließt das Fenster

## 1.2.1 – 2026-09-21

- optionalen lokalen Wiederherstellungssnapshot für den Forever-Beta-Fehler beim Laden von SavedVariables ergänzt
- vorhandene Chronik nur dann wiederhergestellt, wenn der Client keine nutzbaren gespeicherten Daten bereitstellt
- Synchronisierungsskript für die Zeit bis zu einer Clientkorrektur beigefügt

## 1.2.0 – 2026-09-21

- eigenständige accountweite SavedVariable `ChronicleNotesDB` für Notizen eingeführt
- Notizen aus allen passenden älteren Datenquellen ohne Duplikate zusammengeführt
- leere Journale können gespeicherte Notizen nicht mehr verdrängen
- Diagnose zeigt Journal- und Notizspeicher getrennt an

## 1.1.1 – 2026-09-21

- Charakterjournal unmittelbar vor jeder Seitenanzeige erneut gebunden
- Diagnose, Notizen und Ziele wählen automatisch die inhaltsreichste gespeicherte Tabelle
- veraltete leere Laufzeitreferenzen nach einem Forever-Reload selbständig ersetzt

## 1.1.0 – 2026-09-21

- Datenhaltung auf GUID-basierte Charakterjournale umgestellt
- ältere Name-Realm-Daten und `ChronicleCharDB` nach Inhalt bewertet und automatisch zusammengeführt
- leere Frühladetabellen können vorhandene Journale nicht mehr verdrängen
- accountweite Datenbank und Charakterbindung klar getrennt
- Collector-Ereignisse gegen noch nicht verfügbare Charakterdaten abgesichert
- `/chr repair` für eine sofortige erneute Bindung ergänzt

## 1.0.5 – 2026-09-21

- SavedVariables mit `LoadSavedVariablesFirst` vor der Addon-Ausführung laden lassen
- Charakterjournal bei `PLAYER_ENTERING_WORLD` und nochmals verzögert neu gebunden
- vorhandene Einzelchronik bei abweichender Forever-Namensform automatisch wiederhergestellt

## 1.0.4 – 2026-09-21

- Charakterjournal erst bei `PLAYER_LOGIN` an einen stabilen Namen-und-Realm-Schlüssel gebunden
- vorzeitige leere Datenbank unter einem unvollständigen Forever-Login-Schlüssel verhindert
- aktiven Datenschlüssel zu `/chr debug` ergänzt

## 1.0.3 – 2026-09-21

- Seitenschlüssel direkt am Navigationsbutton gespeichert, ohne Lua-Schleifen-Closure
- `/chr notes` zum direkten Öffnen der Notizseite ergänzt
- `/chr debug` zur Anzeige der geladenen Version und gespeicherten Notizanzahl ergänzt

## 1.0.2 – 2026-09-21

- Navigation unter Lua 5.1 korrigiert; jeder Seitenbutton bindet nun seinen eigenen Seitenschlüssel
- Anzeige bereits gespeicherter Notizen nach einem Reload wiederhergestellt

## 1.0.1 – 2026-09-21

- Notizen und alle übrigen Charakterdaten zusätzlich in `ChronicleDB.characterData` nach Name und Realm gespeichert
- vorhandene Daten aus `ChronicleCharDB` automatisch in den accountweiten Speicher migriert
- `ChronicleCharDB` als kompatiblen Spiegel beibehalten
- Persistenzproblem einzelner Forever-Betaversionen mit charakterbezogenen SavedVariables umgangen

## 1.0.0 – 2026-09-20

- modulare Architektur mit Datenbank, API Kompatibilität, Sammlern, Suche und UI eingeführt
- Migration der SavedVariables aus Version 0.1.0 ergänzt
- Ziele, Notizen, Timeline, Quests, Gebiete, NPCs, Händler, Dungeons, Bosse, Loot, Inventar, Bank, Wirtschaft und Death Journal umgesetzt
- accountweite Charakterübersicht, Statistiken und universelle Suche ergänzt
- klassisches dunkles WoW Fenster mit goldenen Rahmen und linker Navigation erstellt
- Laufzeitprüfungen für optionale Forever APIs und feste Größenlimits ergänzt
- `_Camelot.toc`, Addon Compartment und Release Dokumentation ergänzt





























































