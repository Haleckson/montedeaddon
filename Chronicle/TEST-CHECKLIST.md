# Test Checkliste für Chronicle Forever 1.5.40

## Release-Smoketest im Forever-Beta-Client

- [x] Nach Installation und `/reload` läuft Chronicle Forever 1.5.40 ohne Lua-Fehler. Vom Nutzer am 30.09.2026 im Forever-Beta-Client bestätigt.
- [x] Die Seiten und die Sprachumschaltung wurden im Spiel geprüft; die Übersetzungen sind vollständig. Vom Nutzer am 30.09.2026 bestätigt.
- [x] Wiederholtes Öffnen, Scrollen und Filtern bleibt flüssig. Vom Nutzer am 30.09.2026 bestätigt.
- [ ] Ein Gegenstandszuwachs wird genau einmal erfasst; wiederholte Taschenereignisse ohne Änderung ändern den Stand nicht.
- [x] Eine Testnotiz und ein Ziel bleiben nach `/reload` und vollständigem Neustart erhalten. Vom Nutzer am 30.09.2026 im Forever-Beta-Client bestätigt.
- [ ] Nach einem neuen Todesfall zeigt das Death Journal den gespeicherten Kampflog; ältere Fälle bleiben unverändert.

## Installation und Start

- [ ] Ordner liegt als `Interface/AddOns/Chronicle/` vor, ohne zusätzliche Zwischenebene.
- [ ] Chronicle erscheint in der Addon Liste ohne „Abhängigkeit fehlt“.
- [ ] Login erzeugt keine Lua Fehlermeldung.
- [ ] `/chronicle`, `/chr` und der Addon Compartment Eintrag öffnen dasselbe Fenster.
- [ ] Fenster lässt sich verschieben, schließen und mit `/chr resetpos` zentrieren.

## Daten und Oberfläche

- [ ] Instanzwissen zeigt 34 Forever-Dungeons aus dem Referenzkatalog, einschließlich der bisherigen sieben Detailseiten und Vorschauen ohne Beute.
- [ ] Raidwissen zeigt die Raids des Clients; Bossliste und Beute öffnen sich ohne externes Addon.
- [ ] Waffenfertigkeiten zeigt nur Waffenmeister der eigenen Fraktion; ein Klick auf einen Ort öffnet die Stadtkarte und setzt die Wegmarkierung. Nach einem Trainerbesuch wird die erfasste Position verwendet.

- [ ] Aktions-, Filter- und Reiterknöpfe haben einen dunklen Hintergrund, Goldrahmen und einen helleren Rahmen beim Überfahren; Karten und Listeneinträge bleiben als eigene Bedienelemente erkennbar.

- [ ] Beim Stufenaufstieg erscheint die Chronicle-Zaubermeldung unter der Blizzard-Anzeige ohne Überlappung und blendet nach einigen Sekunden aus.

- [ ] Rechte Header-Motive bleiben auf allen Seiten innerhalb der Kopfkarte und überdecken weder Zähler, Datum noch Text; bei schmalen geteilten Karten werden sie ausgeblendet.

- [ ] Abenteuer zeigt eine Kopfkarte mit integrierten Zahlen, Filter, Tagesgruppen, ruhige Listeneinträge links und ein dem Inhalt angepasstes Detaildossier rechts. Questserien lassen sich öffnen und schließen; aktive Quests öffnen per Dossier das WoW-Questlog.

- [ ] Alte Händler aus früheren Versionen bleiben nach dem Update unter NPC & Händler sichtbar; neue Händler werden nur noch im NPC-Journal gespeichert.

- [ ] Unter Wissen erscheinen Sammeln, Trainer, Lehrerorte, Waffenfertigkeiten und Instanzwissen; die sieben Instanzen öffnen ihre Boss-, Quest- und Beutelisten.
- [ ] Instanzwissen zeigt sieben bebilderte Instanzkarten. Jede Karte öffnet innerhalb von Chronicle Boss-, Quest- und Beutedetails; Der Zurück-Knopf führt zur Übersicht; Quests anderer Fraktionen fehlen in Liste und Zähler. Die Questansicht zeigt Erfahrung, Geld, Ruf und mögliche Gegenstände getrennt; die letzte Instanzkarte nutzt die ganze Zeile. Das separate Dungeon-Journal wird nicht geöffnet.
- [ ] Sammeln zeigt Zahlen in der Kopfkarte, drei anklickbare Rangtafeln für Bergbau, Kräuterkunde und Kürschnerei mit eigenen rechten Motiven und freistehenden Fortschrittszahlen, Fundfilter, Bestfunde und eine verständliche Leerseite.
- [ ] Trainer gruppiert lernbare, spätere und bekannte Zauber; Statuswörter stehen nicht im Zaubernamen.
- [ ] Auch bei vielen Rezepten reagiert die Suche flüssig und wiederholtes Öffnen vermehrt die Karten nicht.
- [ ] Nach erfolgreichem Erz-, Kräuter- und Kürschnerfund steigen Mengen und Sammelaktionen genau einmal; Steine, Rüstungen und andere Begleitbeute erscheinen nicht unter Funde.
- [ ] Nach Besuch eines Klassentrainers zeigt Trainer angebotene Zauber, Stufen und Preise.
- [ ] Alle drei Trainerkategorien werden erfasst; vorhandene Filter bleiben danach erhalten und Zauber mit mehreren Rängen erscheinen getrennt.
- [ ] Beim Stufenaufstieg meldet Chronicle neu erreichbare, zuvor erfasste Trainerzauber genau einmal.
- [ ] Trainer zeigt „Jetzt“, „Prüfen“, „Später“ und „Bekannt“ getrennt sowie die nächste Freischaltstufe; die Liste ist nach Stufen gegliedert.
- [ ] Ein neuer Charakter sieht den Zauberkatalog seiner Klasse schon vor dem ersten Trainerbesuch; fremde Klassen und fremde Priester-Rassenzauber fehlen.
- [ ] Katalogeinträge zeigen ohne Trainerbesuch keinen erfundenen Preis; echte Trainerwerte ersetzen die Vorschau.
- [ ] „Prüfen“ enthält nur tatsächlich erfasste Trainerangebote; unbestätigte Katalogeinträge stehen unter „Vorschau“.
- [ ] Ist ein höherer Zauberrang bekannt, erscheinen niedrigere Ränge ebenfalls als bekannt.
- [ ] Beim Überfahren eines Trainerzaubers oder seines Symbols in der Detailtafel erscheint der Spiel-Tooltip am Mauszeiger.
- [ ] Bei Stufen ohne neue Zauber erscheint ein kurzer Hinweis mit der nächsten Katalogstufe; bei neuen Zaubern erscheinen Chat- und Bildschirmmeldung genau einmal.
- [ ] Trainerliste scrollt bei Klassen mit mehr als 100 Einträgen bis zu den Zaubern auf Stufe 60; die letzten Einträge bleiben anklickbar.
- [ ] „Vorschau“ zeigt auch künftige, noch nicht beim Trainer bestätigte Katalogzauber; bekannte Einträge fehlen dort.
- [ ] Beim Stufenaufstieg erscheint mittig eine Chronicle-Tafel mit Lotus und Ein-/Ausblendeffekt; sie zeigt neue Zauber oder die nächste Freischaltung und verschwindet nach sechs Sekunden.

- [ ] Statistikseite: Kennzahlen zeigen einen Öffnen-Tooltip und wechseln beim Anklicken zur passenden Rubrik.

- [ ] Gold & Wirtschaft: Summen für Einnahmen, Ausgaben und Tagesbilanz entsprechen den angezeigten Buchungen; ausgeblendete Abmeldewerte verändern die Summen nicht.
- [ ] Gold & Wirtschaft: Buchung links anklicken; die Detailtafel rechts zeigt Betrag, Zeitpunkt, Ort und Kontostand dieser Buchung. Beim Rubrikwechsel verschwindet die Tafel.

- [ ] Alle 16 Navigationspunkte lassen sich anklicken und scrollen.
- [ ] Abenteuer zeigt Ereignisse nach Tagen, Kategorien und Uhrzeit; Filter für Quests, Reise, Berufe und Weitere sowie „Weitere Erinnerungen anzeigen“ funktionieren.
- [ ] Mehrere gleichzeitig angenommene Quests erscheinen als eine aufklappbare Questserie; nach dem Aufklappen bleiben alle einzelnen Quests lesbar.
- [ ] „Wo war ich?“ zeigt Ort, letzte Sitzung, Vermögen, Kennzahlen, Ziele und Erinnerungen ohne Überlappung; Kennzahlen und Karten öffnen die passende Rubrik.
- [ ] Auf „Wo war ich?“ sind Begrüßung, Sitzungszeit und Kennzahl-Beschriftungen linksbündig; Symbole werden ohne Platzhalter angezeigt.
- [ ] Ohne eigene Ziele führt die zusätzliche Quest-Karte zu aktiven Quests; aufeinanderfolgende gleichartige Erinnerungen füllen die Startseite nicht mehrfach.
- [ ] Beute & Rares: Alle, Quest, Grün+ und Rares filtern korrekt; die lokale Suche findet Namen und Orte, und leere Treffer zeigen einen Hinweis.
- [ ] Beutefunde zeigen WoW-Gegenstands-Tooltips am Mauszeiger; Rare-Karten zeigen erste und letzte Sichtung sowie Sichtungszahl.
- [ ] Charakterkarten zeigen Klassenicon, Namen, Gold und Erinnerung ohne Überlappung; beim Seitenwechsel verschwinden die Karten.
- [ ] Klick auf eine Charakterkarte öffnet deren Detailseite; „Zurueck“ zeigt wieder alle Karten.
- [ ] Charakterkarte öffnet direkt die Chronik; Ereignisse sind nach Tagen gruppiert und mit passenden Symbolen versehen.
- [ ] Gilde und Rang erscheinen nach dem Login, Skillung und gelernte Talente nur bei verfügbaren Talentdaten.
- [ ] Auf der Charakterkarte steht eine echte Anzahl gekaufter Talentpunkte oder ausdrücklich „Talentdaten nicht erfasst“, nicht bloß der Klassenname.
- [ ] Charakterkarte zeigt konkrete gelernte Talente mit Rang; die vollständige Liste ist in der Detailansicht lesbar.
- [ ] Bei eindeutig getrennten Talentzweigen stimmen die drei Punktzahlen mit dem WoW-Talentfenster überein.
- [ ] Inventar und Bank zeigen getrennte Bereiche, Icon, Menge und Gegenstandsfarbe; Mouseover zeigt den Gegenstandstooltip.
- [ ] Verkaufspreis pro Stück und Stapel erscheinen unter verkaufbaren Gegenständen; unverkäufliche und nicht geladene Gegenstände sind klar gekennzeichnet.
- [ ] Gold-, Silber- und Kupferbeträge tragen in allen Chronicle-Ansichten ihre Münzfarben; Geldbeträge bleiben durchsuchbar.
- [ ] Die vier Inventarfilter zeigen passende Einträge in Inventar und Bank; Summen und Leerzustände passen zum Filter.
- [ ] Geldbeträge lassen führende Nullmünzen weg, während 0 Kupfer weiterhin sichtbar bleibt.
- [ ] Goldverlauf trennt Tage, Einnahmen und Ausgaben; bekannte Nullwerte vom Logout werden nur ausgeblendet.
- [ ] „Nullwerte anzeigen“ blendet alte volle Sprünge auf 0c wieder ein und „Nullwerte ausblenden“ verbirgt sie erneut.
- [ ] Goldseite zeigt grossen Kontostand, Tagesabschnitte und getrennte Buchungskarten ohne Ueberlappung beim Scrollen.
- [ ] Neue Geldbewegungen erscheinen spaetestens nach einigen Sekunden im Verlauf; ein kurzzeitiger 0c-Wert erzeugt keine falsche Ausgabe.
- [ ] Charakterdetails zeigen Kopfbereich, Klassenfarbe und die vier Reiter Profil, Quests, Sammlung und Chronik.
- [ ] Alle Detailreiter scrollen korrekt; ein Klick auf Zurueck stellt die Charakterkarten wieder her.
- [ ] Statistik-Dashboard zeigt Chronikzahl und Karten fuer Reise, Quests sowie Sammlung ohne abgeschnittene Beschriftungen.
- [ ] Fenster laesst sich an allen vier Kanten und Ecken skalieren; der Griff unten rechts ist sichtbar.
- [ ] Fenstergroesse bleibt nach `/reload` erhalten; `/chr resetpos` stellt 960 x 650 wieder her.
- [ ] Nach breiterem oder schmalerem Ziehen nutzen Statistik, Charaktere, Dossier, Inventar und Goldverlauf die neue Inhaltsbreite.
- [ ] Statistik-Karten zeigen passende Symbole; Nullwerte sind gedimmt und Karten reagieren auf Mouseover.
- [ ] Das Fenster zeigt den klassischen Dialograhmen; die drei Navigationsgruppen passen vollständig ins Fenster.
- [ ] Ziel per Oberfläche und `/chr goal Test` anlegen, per Klick erledigen und wieder öffnen, per `Entf.` entfernen.
- [ ] Notiz per Oberfläche und `/chr note Test` anlegen, bearbeiten und löschen. Nach `/reload` die geladenen Notizen prüfen.
- [ ] Suche findet Ziel, Notiz, Quest, Gebiet, NPC, Beute, Rezept, Dungeon, Boss, Todesort, Goldänderung, Alt, Inventar und Bank.
- [ ] Sonderzeichen und lange Texte verursachen keinen Fehler.

## Automatische Erfassung

- [ ] Nach einem neuen Tod stehen Gegner, Fähigkeit, Schaden und letzte Treffer im Death Journal; Sturzschaden erscheint als Umgebung / Sturz.
- [ ] Ältere Todesfälle ohne Kampflog zeigen keine erfundenen Kampfdaten.

- [ ] Nach Tod durch NPC: Death Journal zeigt Gegner, Fähigkeit/Nahkampfangriff und Tooltip; nach Reload bleiben Angaben erhalten.
- [ ] Death Journal: Eintrag in der linken Zeitlinie anklicken; die Gedenktafel rechts zeigt genau diesen Fall. Der letzte Fall oben lässt sich ebenfalls auswählen. Beim Rubrikwechsel verschwindet die Tafel.
- [ ] Bei Sturz/Umweltschaden erscheint die Ursache ohne erfundenen Gegner; alte Einträge zeigen „nicht erfasst“.

- [ ] Erstbesuch eines Gebiets erscheint einmal als Entdeckung; Rückkehr erhöht nur die Besuchszahl.
- [ ] Gebietsansicht zeigt Erstbesuch, letzten Besuch und letztes Untergebiet.
- [ ] Alte Platzhaltereinträge für „Unbekannt“ fehlen in Gebietsansicht, Suche und Statistik.
- [ ] Aktuelle Quests erscheinen in der Questseite; Annahme und Abgabe erscheinen jeweils einmal mit Titel oder stabiler Questnummer.
- [ ] Aufgehobene Beute erscheint im Beutejournal.
- [ ] Weiße und graue Gegenstände bleiben aus der Beuteansicht ausgeblendet.
- [ ] Weiße Questgegenstände und grüne oder bessere Gegenstände erscheinen im Beutejournal.
- [ ] Geldänderung wird mit Delta und neuem Kontostand gespeichert.
- [ ] Tod erhöht die Statistik und erzeugt einen Eintrag mit Gebiet.
- [ ] Nach einem Tod und `/reload` bleiben Death-Journal-Eintrag und Todeszahl erhalten; bei der Forever-Beta-Ladelücke nach erneuter Wächter-Sicherung noch einmal `/reload` prüfen.
- [ ] Betreten einer Instanz und ein beendeter Bosskampf werden gespeichert.
- [ ] Klick auf eine Instanzkarte öffnet ein eigenes Bosskapitel-Fenster; Schließen und erneutes Öffnen funktionieren.
- [ ] Neue Bossbeute zeigt Gegenstand, Boss und Empfänger; Mouseover öffnet den WoW-Gegenstandstooltip.
- [ ] Eine doppelte Loot-Meldung erzeugt keinen zweiten identischen Eintrag.
- [ ] Beim Aktualisieren einer geöffneten Rubrik bleibt die Scrollposition erhalten.
- [ ] NPC Mouseover und Händlerbesuch erscheinen getrennt im NPC Gedächtnis.
- [ ] Eigenes Berufsfenster öffnen: gelernte Rezepte erscheinen unter „Berufe & Rezepte“ und in der Suche.
- [ ] Mehrfaches Mouseover derselben Rare erhöht die Sichtungszahl in einer Sitzung nur einmal.
- [ ] Begleiter mit Pet-GUID erscheinen nicht in NPC-Ansicht, Suche oder NPC-Statistik.
- [ ] Inventar wird nach Taschenänderung aktualisiert; Bank nach dem Öffnen.
- [ ] Wiederholte Taschen- und Bankereignisse ohne geänderten Inhalt erzeugen keine zusätzliche Neuzeichnung; Beutezuwachs erscheint weiterhin genau einmal.
- [ ] Bankliste enthält keine normalen Taschengegenstände; beide Ansichten zeigen Erfassungszeit und Stückzahlen.

## Persistenz und Migration

- [ ] Mit leeren SavedVariables startet Chronicle fehlerfrei.
- [ ] Eine vorhandene 0.1.0 Datenbank wird ohne Datenverlust geladen.
- [ ] Zweiter Charakter erscheint nach Login in der accountweiten Übersicht.
- [ ] Logout, Client Neustart und erneuter Login erhalten die Daten.

## Leistung und Grenzen

- [ ] Mehrere schnelle Taschen-, Zonen- und Geldereignisse erzeugen keine merkliche Verzögerung.
- [ ] Im Kampf sind Öffnen, Lesen und Schließen fehlerfrei; das Fenster startet keine geschützte Aktion.
- [ ] Nach dem Test `WTF/.../SavedVariables/Chronicle.lua` auf plausible Größe und gültige Tabellen prüfen.























- [ ] Aktuelle Quests und Inventartreffer ohne Zeitstempel zeigen in der Suche kein Datum 01.01. an.

- [ ] In einer Instanz erhöht ein UI-Reload die Besuchszahl nicht; Bosskämpfe zeigen Ort, Zeitpunkt, Siege und Versuche.

- [ ] Kauf unter einem Gold zeigt im Goldjournal einen negativen Betrag mit 0g und korrekten Silber-/Kupferwerten.

- [ ] Goldseite zeigt denselben aktuellen Betrag wie das Inventar; Kauf wird einmalig als negative Änderung erfasst.

- [ ] Statistik zeigt Händler wie die NPC-Seite, getrennte Instanzbesuche und Bossversuche sowie offene/erledigte Ziele.

- [ ] Bis zu drei offene Ziele erscheinen auf „Wo war ich?“; erledigte Ziele verschwinden dort, bleiben aber unter „Ziele“ erhalten.

- [ ] Zweiten Charakter anmelden: beide erscheinen genau einmal und ihre Journale bleiben getrennt; danach zum ersten zurückwechseln.

- [ ] Bei zwei gespeicherten Charakteren ergänzt Recovery fehlende Alts; Sync bricht ab, wenn eine neue Datei einen Charakter vermissen lässt.

- [ ] `/reload` erzeugt keinen neuen Eintrag „Abenteuer fortgesetzt“ und setzt „Letzte Sitzung“ nicht auf die Reload-Zeit.

- [ ] „Letzte Sitzung“ bleibt nach `/reload` beim vorherigen echten Sitzungsende oder zeigt „nicht erfasst“ für alte unklare Daten.

- [ ] Beta-Monitor sichert bei einem SavedVariables-Schreibvorgang eine vollständige Datei außerhalb des Release-ZIP; Sync verweigert einen kleineren Chronikstand.



















- [ ] Inventar und Bank zeigen zweispaltige Karten ohne überlappende Namen, Mengen und Verkaufswerte; alle Filter funktionieren.

- [ ] Besitzarchiv: Klick auf ein Fundstück aktualisiert das Dossier; Filter und Bank zeigen nur passende Einträge.

- [ ] Highlight-Loot rechts zeigt nur Beute ab blau; höchstwertiger und bei Gleichstand jüngster Fund wird gewählt.
- [ ] Klick auf Highlight-Loot öffnet Beute & Rares; ohne passenden Fund erscheint der Leerzustand.

- [ ] Besitzarchiv: Tooltips erscheinen am Mauszeiger für Filter, Listen, Fundstücke, Dossier und Highlight-Loot.

- [ ] Besitzarchiv gruppiert Fundstücke je Inventar und Bank in passende Kapitel, auch nach Filterwechsel ohne überlappende Zeilen.

- [ ] Berufe & Rezepte: Haupt- und Nebenberufe stehen in getrennten Kapiteln; Fortschritt und verbleibende Punkte stimmen.
- [ ] Erfasste Rezepte erscheinen im Rezeptarchiv; bei null Rezepten erscheint der Leerzustand.




















