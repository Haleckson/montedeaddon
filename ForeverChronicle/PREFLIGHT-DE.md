Historisches Prüfprotokoll für 0.9.0-beta.6; kein aktueller Teststatus.

# Forever Chronicle – Technischer Preflight vor Test 1

Stand: 0.9.0-beta.6 · Datenbankschema 10 · Zielclient: WoW Forever Beta, Interface 16001

## 1. Ergebnis in einem Satz

Der Neustart und die Addon-seitigen Schutzmaßnahmen sind vorbereitet und automatisiert geprüft. **Ein verlustfreier Echtbetrieb ist noch nicht belegt**, weil SavedVariables vom WoW-Client geladen und geschrieben werden. Der beobachtete Fehler kann außerhalb des Addons liegen. Test 1 muss deshalb zuerst die Clientversion und den tatsächlichen Datei-Roundtrip bestätigen.

## 2. Erkenntnisse zum verlorenen Verlauf

Andere Forever-Beta-Spieler beschrieben im Blizzard-Forum denselben Fehler: SavedVariables-Dateien enthielten gespeicherte Daten, die beim nächsten Start im Lua-Addon nicht verfügbar waren. In diesem Bericht wurde am 25. September bestätigt, dass das Verhalten ab Clientbuild `1.60.1.70009` nicht mehr auftrat. Das ist ein Bericht von Spielern im Blizzard-Forum, keine formelle Blizzard-Fehleranalyse. Es passt aber eng zu „gestern vorhanden, heute im Addon leer“ und muss beim Test ausdrücklich geprüft werden.

Quelle: [WOWF Beta: SavedVariables appear to write correctly to disk but are not restored at startup](https://us.forums.blizzard.com/en/wow/t/wowf-beta-addon-savedvariables-appear-to-write-correctly-to-disk-but-are-not-restored-at-startup/2356559)

## 3. Speicherregeln und Grenzen

- Addons bearbeiten SavedVariables im Speicher. Der Client serialisiert sie bei einem regulären UI-Neuladen, Logout oder Beenden. Das Addon besitzt keine unterstützte Funktion, die dieselbe SavedVariables-Datei während des Spielens zuverlässig auf die Festplatte schreibt.
- Ein Disconnect ist kein Addon-Logout: die lokale UI kann weiterlaufen, der Client kann später speichern. Ein harter Clientabbruch kann Änderungen seit dem letzten erfolgreichen Schreibvorgang verlieren.
- Ein Addon kann die `.bak`-Datei und andere Dateien auf dem Computer nicht direkt lesen. Lua darf keine beliebigen Dateien öffnen oder schreiben.
- Ein extern kopierter Account-Export ist daher weiterhin der belastbarste vom Addon unterstützte Wiederherstellungsweg. Den Export außerhalb des WoW-Ordners aufbewahren.
- In-Addon-Snapshots können Migrationsfehler auffangen. Sie können einen Clientfehler, der die gesamte SavedVariables-Datei nicht lädt, keinen Festplattenausfall und keine ungültige Lua-Datei vollständig kompensieren.

## 4. Umgesetzte Schutzregeln

| Schutz | Verhalten in 0.9.0-beta.6 | Nachweis |
|---|---|---|
| Frischer Neustart | `ForeverChronicleDB_v2` beginnt leer. `ForeverChronicleDB` bleibt im Addon unangetastet. Kein stiller Autoimport. | Mocktest prüft alten Sentinel unverändert. |
| Stabile Charakterzuordnung | GUID ist der interne Schlüssel; Name und Realm sind Anzeigeinformationen. Umbenennen ändert den Schlüssel nicht. | Mocktest mit Namens-/Realmänderung. |
| Alte Sicherung importieren | Eine namensbasierte Charakterzeile wird anhand der mitgelieferten GUID auf den GUID-Schlüssel gelegt; erneuter Import ist idempotent. | Backup-Roundtrip und Legacy-Key-Test. |
| Upgrade | Vor einem Schema-Upgrade wird ein einzelner Snapshot des vorherigen Datenstands erzeugt. Der Upgradezustand wird als `pending` markiert und erst nach fertiger Initialisierung abgeschlossen. | Schema-7→10 Test und unterbrochene Migration. |
| Fehlerhafte Struktur | Typfalsche gespeicherte Werte werden vor dem Ersetzen unter `recovery.quarantined` aufgehoben; ungültige Event-/Notizzeilen werden dort ebenfalls abgelegt. | Quarantäne-Test. |
| Downgrade | Erkennt die installierte Version ein höheres Datenbankschema, blockiert sie Aufzeichnung und Speicherung, statt die neuere Chronik herunterzustufen. | Future-schema Read-only-Test. |
| Langzeitverlauf | Events, Entdeckungen und Sitzungen werden nicht mehr automatisch am Listenlimit gelöscht. Die frühere Grenze löst eine einmalige Warnung aus. | Test prüft Ereignisse über dem Grenzwert. |
| Kartenatlas | Sammelfund-Suche prüft nur Einträge derselben Karten-ID statt den gesamten Atlas. | Verhaltenstest der Gathering-Module. |
| Chronikoberfläche | Die Chronik erstellt maximal 50 Verlaufszeilen pro Seite; ältere Einträge bleiben über Seitennavigation erreichbar. | UI-Test mit 125 Ereignissen. |
| Tagebuchkapitel | Aus Sitzungen werden Tages-, Wochen-, Monats- und Jahreskapitel gebildet. Die Originalereignisse bleiben pro Charakter erhalten; der Zeitmaßstab ist umschaltbar. | Mocktest für Wochen/Monate/Jahre und Sitzungswechsel. |
| Händler/Gegner | Händlername und beobachtete Warenkategorien gehen in die Geschichte ein. Gegner werden nur erfasst, wenn Spieler oder Gruppe kürzlich Schaden verursacht haben und der NPC anschließend stirbt. | Template-, Positions- und Combatlog-Mocktest; Live-Build offen. |
| Tagebuchoptik | Parchment-Fläche an der Spielreferenz ausgerichtet; wechselnde dunkle Kartenflächen entfallen im Tagebuch. | Code-/Locale-Prüfung; Darstellung im echten Client und bei Skalierungen offen. |

### Einschränkung der Upgrade-Sicherung

Der Snapshot wird innerhalb derselben SavedVariables-Datenbank gehalten und verdoppelt während einer Schemaumstellung zeitweise einen großen Teil des Speicherbedarfs. Nach einem erfolgreichen regulären Speichern wird er beim folgenden Start freigegeben. Bei sehr großen Datenbeständen muss die reale Lade- und Dateigröße vor jedem Schema-Upgrade gemessen werden.

## 5. Funktions- und API-Prüfung

| Bereich | Derzeitige Erfassung | Datenlücken und Verhalten bei fehlenden API-Werten | Status vor Test 1 |
|---|---|---|---|
| Charakteridentität | `UnitGUID("player")`; Name, Realm, Klasse, Rasse, Fraktion, Stufe als Profilmetadaten | Ohne GUID wird vorübergehend Name-Realm als Ersatz benutzt. Der erste spätere GUID-Wechsel muss am Client geprüft werden. | Automatisiert geprüft; Client-Roundtrip offen |
| Quests | Quest-ID, lokalisierter Name, Annahme/Abschluss, Ziele soweit Questlog sie bereitstellt | Events können doppelt/verspätet eintreffen; ohne Quest-ID kann kein sprachübergreifender sicherer Schlüssel entstehen. ID ist maßgebend, Name ist Anzeige. Questkettenbeziehungen werden nicht vollständig vom Client geliefert. | ID und Import geprüft; Live-Events offen |
| Stufen | Level-Up-Event, Level und beim Event ermittelte Position | Zonen-/Koordinatenwerte können während Ladebildschirm oder Übergang fehlen. Spielzeit bis zur nächsten Stufe wird nicht zuverlässig aus der API abgeleitet. | Handler vorhanden; Übergangsfall offen |
| Gebiete | Zonenwechsel und Karten-/Positionsabfrage | Karten-ID, Subzone oder Position kann nil sein; dann darf kein erfundener Pin entstehen. Lokalisierte Gebietsname können sich ändern. | Unit/Target-Koordinaten getestet; echte Karten offen |
| Dungeons/Instanzen | Zonen-/Weltwechsel und Instanzinformationen | Eintritt kann mehrfach gemeldet werden; Instanz-API und Ereignisse müssen im Forever-Build bestätigt werden. Bossbegegnungen sind keine vollständige Encounter-Aufzeichnung. | Implementiert; Live-Test offen |
| Rare/NPC | Target, Mouseover, Nameplates und Vignette, soweit verfügbar; ID aus GUID | Nicht jeder Mob liefert eine Vignette. Gewöhnliche feindliche Mobs werden gefiltert; neutrale/freundliche NPCs können erst bei Sichtkontakt erkannt werden. Beobachtungsdrossel verhindert Spam. | Filterlogik vorhanden; Fehlklassifikation live offen |
| Besiegte Gegner | Combat-Log: jüngster Schaden durch Spieler/Gruppe; danach `UNIT_DIED`/`UNIT_DESTROYED`; Name und NPC-ID aus Ereignis/GUID | Ein Gegner wird nicht zugeschrieben, wenn kein passender Gruppenschaden im letzten 20-Sekunden-Fenster erkannt wurde. Kämpfe anderer Spieler ohne eigene Gruppenbeteiligung fehlen. Der Combat-Log-Event muss im Forever-Build verfügbar sein. | Offline-Handler getestet; echte Client-Events offen |
| Erz/Kräuter/Schätze | Zauber-/Interaktionsereignisse und Lootmeldungen; Ressourcenart aus ID/Name des Zaubers | Der Client stellt nicht für jeden Sammelknoten eine vollständige, eindeutige Node-ID bereit. Sprachabhängige Zaubernamen und nicht gelieferte Eventargumente bleiben ein Risiko. Fundposition stammt aus dem Spieler-/Zielkontext, nicht aus einer offiziellen Rohstoffdatenbank. | Heuristik und Atlasindex vorhanden; nicht garantiert, live prüfen |
| Gegenstände | Item-ID, Link, Qualität, Loot-/Inventar-/Händlerbeobachtung | Iteminfos können asynchron eintreffen. Gegenstände ohne ID/Link können nur über Namen zusammengeführt werden. Tasche/Bank sind Momentaufnahmen, nicht vollständiger historischer Besitz. | Import/Qualität geprüft; Client-Lootfälle offen |
| Händler/Trainer | Erkennung beim Öffnen des jeweiligen Dialogs; Position der Interaktion | Kein Besuch wird aufgezeichnet, wenn der Spieler nur vorbeiläuft. Warenbestand kann beim Öffnen verzögert sein; erneuter Scan darf keinen zweiten Besuch erzeugen. | Mock-Positions- und Retry-Test vorhanden; Live offen |
| Gruppe/Begleiter | Gruppenroster zum Zeitpunkt bestimmter Ereignisse | Namen können fehlen oder sich bei Realms unterscheiden. Daraus folgt keine verlässliche dauerhafte Spieler-GUID. Keine automatische vollständige Gruppengeschichte. | Teilweise; Live offen |
| Tod | `PLAYER_DEAD`, falls aktiviert | Wiederbelebung und Tode durch Client-/Szenario-Sonderfälle separat prüfen. | Handler vorhanden; Live offen |
| PvP/Gilde/Raid/Bosse/Rezepte | Nicht vollständig aufgezeichnet | Nicht als fertige Funktion bewerben, solange Events, IDs und Clientfreigaben nicht implementiert und geprüft sind. | Ausdrücklich unvollständig |
| Suche/Journal | Ereignis- und Funddaten werden lokal durchsucht; Listen sind teilweise paginiert | Ein großer Verlauf kann weiterhin Such-/Gruppierungszeit beanspruchen. Questketten sind derzeit keine vollständig rekonstruierte Blizzard-Beziehungsdatenbank. | Basis vorhanden; 100k-Benchmark offen |
| Karte/Marker | Gespeicherte Positionen und Layerfilter | Karten-ID ist client-/datenbankabhängig. API kann auf der Weltkarte andere Koordinaten liefern als Ziel-/Spielerposition. Ungültige Position wird verworfen statt angezeigt. | Mock geprüft; tatsächliche Forever-Karte offen |
| Export/Import | Textbasierter Account-Export mit Wiederherstellung/Merge | Manuelle Kopie erforderlich; Import nicht automatisch beim Start. Exporte können groß werden. | Roundtrip, Wiederholungsimport, ungültige Koordinaten geprüft |
| UI/Locales | Deutsch bei `deDE`, Englisch als Fallback; paginierte Ansichten | Fremde Schriftgrößen, UI-Skalierung, Addon-Konflikte und kleine Auflösungen benötigen echte Clientprüfung. | Schlüsselparität und Mock-UI geprüft |

## 6. Testmatrix vor Freigabe

| ID | Ausgangszustand | Aktion | Erwartetes Ergebnis | Prüfmethode / Gate |
|---|---|---|---|---|
| P01 | Clientbuild sichtbar | Buildnummer im Launcher/Spiel prüfen | mindestens der Build mit bestätigter SavedVariables-Korrektur; derzeitiger Forumsbericht nennt `1.60.1.70009` | Screenshot/Buildtext festhalten; andernfalls Test als Clientblocker markieren |
| P02 | 0.8-Daten vorhanden | 0.9.0-beta.6 installieren | neue Chronik leer; alte globale Variable bleibt in derselben SavedVariables-Datei erhalten | Datei vor/nachher vergleichen; keine Dateien löschen |
| P03 | Neue Chronik leer | Quest, Gebiet und Ort aufzeichnen; `/reload`; erneut öffnen | Einträge nach Reload vorhanden | UI plus SavedVariables-Datei prüfen |
| P04 | Einträge nach P03 | normal ausloggen, Client schließen, neu starten | identische GUID-Chronik wird geladen | UI und gespeicherte Datei prüfen |
| P05 | Daten nach P04 vorhanden | denselben Charakter nach Namens-/Realm-Anzeigeänderung öffnen | derselbe GUID-Schlüssel, kein zweites Profil | `/fc diagnose`, Charakterübersicht, Datei |
| P06 | Zwei neue Charaktere/Realms | beide getrennt spielen und aufrufen | Einträge bleiben dem richtigen GUID-Profil zugeordnet | `/fc diagnose` und UI pro Charakter |
| P07 | Einträge vorhanden | Sprache deDE→enUS wechseln, Quest erneut suchen | Quest bleibt über ID erkennbar; Anzeigename darf lokalisiert sein | gleiche Quest-ID und kein Duplikat prüfen |
| P08 | Leerer Testcharakter | Quest annehmen, Ziel aktualisieren, abgeben | Annahme/Abschluss einmalig, ID und plausible Position | Addon-Ereignis und Questarchiv prüfen |
| P09 | Level kurz vor Aufstieg | Level-Up in Zone und nahe Ladebildschirm | Level genau einmal; ungültige Position bleibt leer | Ereigniszahl/Koordinaten prüfen |
| P10 | Sammelberuf erlernt | Erz und Blume mehrfach sammeln | richtige Kategorie/Symbolik; Fundorte je Ressourcentyp, keine Duplikatflut | Karte nach jedem Fund öffnen; Atlasdaten prüfen |
| P11 | Loot testbar | weißes, grünes, blaues, episches Item looten | Item-ID/Qualität korrekt; Fundposition passt | Suche, Itemfilter, Kartenpin prüfen |
| P12 | Händler und Trainer | beide öffnen, Ware/Trainerdaten laden lassen | Rolle getrennt gespeichert; Position am angesprochenen NPC | Journal/Atlas und Koordinaten prüfen |
| P13 | Rare plus normaler Mob | beide ansehen/targeten, Rare-Vignette betreten | Rare getrennt; nicht jeder Mob als NPC-Pin | Kategorie und Pinfilter prüfen |
| P14 | Gruppe bilden | Quest/Dungeon mit Gruppe absolvieren | verfügbare Begleiter am Ereignis; fehlende Namen erzeugen keinen Fehler | Ereignisdetails prüfen |
| P15 | Dungeon verfügbar | hinein, innerhalb wechseln, verlassen | keine doppelten Eintrittsereignisse; korrekte Instanz | Chronik und Tagesbericht prüfen |
| P16 | Todesaufzeichnung aktiv | einmal sterben und wiederbeleben | ein Todeseintrag | Ereignis-ID und Statisik prüfen |
| P17 | Aktive Sitzung | Disconnect und Reconnect | Sitzung wird nicht als absichtliches Logout doppelt erzeugt | Diary-Tagesansicht prüfen |
| P18 | Neue Einträge seit letztem Save | Alt+F4/Clientabbruch nur im entbehrlichen Testprofil | Verlustfenster dokumentieren; keine Wiederherstellungsgarantie behaupten | Datei vor/nachher sichern; niemals produktive Chronik riskieren |
| P19 | Schema 9-Datenbank | Upgrade auf Schema 10, regulär speichern | Snapshot vorhanden bis ein erfolgreicher Save und Folge-Start bestätigt sind | `recovery.migration` und Snapshot im Testdump prüfen |
| P20 | Migration `pending` simuliert | Addon initialisieren | letzter kompatibler Snapshot zurückgespielt; Upgrade erneut abgeschlossen | automatisierter Rollbacktest plus Datei-Roundtrip |
| P21 | Schema neuer als Addon | ältere Addonversion starten | Aufzeichnung pausiert; neuer Datensatz unverändert | automatisierter Future-schema-Test |
| P22 | Typfalsche SavedVariable | fehlerhaften Feldtyp im Testdatensatz setzen | Originalwert quarantänisiert, kein stilles Löschen | `recovery.quarantined` und Diagnose prüfen |
| P23 | Account-Export aus 0.8 | zweimal importieren | GUID-Zuordnung, keine Duplikate | automatisierter und Client-Roundtrip-Test |
| P24 | 10k, 50k, 100k Ereignisse | Chronik/Suche/Tagesbuch öffnen, Atlasfunde hinzufügen | UI-Zeilen begrenzt, keine minutenlange Blockade, Verlauf bleibt vollständig | CPU-/Ladezeit und Dateigröße messen |
| P25 | Karte noch nie geöffnet | Item aus Suche anklicken | Weltkarte lädt, korrekte Zone/Position, kein Chat-Spam | echter Client; Null-/Fallbackkarten notieren |
| P26 | UI-Skalierung 0.8/1.0/1.2, kleinere Auflösung | alle Tabs/Filter/Export öffnen | keine Überdeckung, lesbare Buttons/Schrift | Screenshots je Skalierung |
| P27 | andere Addons aktiv | Karten- und Fensterhooks gemeinsam verwenden | keine Lua-Fehler/Taint, keine fremde UI blockiert | Fehlerzähler plus `/console taintLog 1` falls verfügbar |
| P28 | fünfzig Charakterprofile | Charakterübersicht, Accountsuche, Export | korrekte Zuordnung; akzeptable Laufzeit | Benchmark und Profilvergleich |
| P29 | Tagebuch mit mehreren Sitzungen | zwischen Reise/Tag/Woche/Monat/Jahr wechseln; nach `/reload` erneut öffnen | dieselben Ereignisse bleiben im richtigen Charakter und Zeitabschnitt, Sitzungstexte werden nicht dupliziert | UI und SavedVariables prüfen |
| P30 | Händlerbesuch plus Kampf | Händlerfenster öffnen, Gegner selbst oder mit Gruppe bekämpfen und besiegen | Händlername/Kategorien sowie Gegnername/Anzahl korrekt; keine fremden Kämpfe erfunden | echter Client, Tagebuch und Suche prüfen |
| P31 | Tagebuchseite geöffnet | Referenzoptik mit UI-Skalierung und 100+ Einträgen ansehen | Parchment bleibt lesbar, keine Überschneidung; Einträge wachsen passend zur Textmenge | Screenshots bei mehreren Skalierungen |

**Sicherheitsregel:** P18 nur mit entbehrlichem Testcharakter und extern gesicherter Datei. Niemals einen echten Langzeitverlauf für einen Absturztest riskieren.

## 7. Automatisierte Prüfungen in 0.9.0-beta.6

`test_fc_08.py` prüft Lua-Syntax aller Addonmodule, deutsche/englische Schlüsselparität und Formatplatzhalter der Tagebuchtexte, TOC-/Versionskonsistenz, alte Datenbank-Unverändertheit, GUID-Schlüssel, Quarantäne typfalscher Werte, Schema-Snapshot, Rollback unterbrochener Migration, Read-only bei neuerem Schema, UI-Paginierung und Zeitmaßstab-Auswahl, Wochen-/Monats-/Jahreskapitel, Gather-/Vendor-/Trainerpositionen, benannte Gegner aus simuliertem Combat-Log, Kartenfilter und wiederholbaren Export/Import.

Beta 6 zeichnet außerdem Kontinenterstbesuche und die erste Entdeckung jeder Zone getrennt pro Charakter auf. Die Erzählbibliothek umfasst pro Sprache je 24 Varianten für Kontinent-/Gebietsentdeckungen, Questannahme/-abschluss und seltene Begegnungen; 20 Varianten für Sitzungsrahmen, Stufen, Dungeons, Sammeln, Gegenstände, Händler, NPCs, Lehrer, Gefährten, Niederlagen, Notizen und Kämpfe; gemeinsame Questabschlüsse haben 14. Nur direkt aufeinanderfolgende Ereignisse gleicher Art am selben Ort werden zusammengefasst. Das muss zusätzlich im Forever-Client geprüft werden.

Diese Mocktests können keine Forever-Client-APIs, echten SavedVariables-Dateien, Blizzard-Ladefehler, andere Addons, UI-Skalierung oder echte Sammel-/Questereignisse bestätigen.

## 8. Preflight-Bewertung

| Bereich | Bewertung | Warum |
|---|---:|---|
| GUID-Datenzuordnung | 9/10 | Schlüssel stabil und automatisiert geprüft; echter Client-Roundtrip offen. |
| Datenbankform/Quarantäne | 8/10 | Typfehler bleiben erhalten; unbekannte semantische Beschädigungen brauchen echte Dateien. |
| Migration/Downgrade | 9/10 | Snapshot, pending rollback und Future-schema-Block automatisiert getestet. |
| Externe Wiederherstellung | 7/10 | Export/Import funktioniert; kein direkter Addonzugriff auf Dateien oder `.bak`. |
| Quest/Level/Gebiet | 7/10 | Handler und ID-Prinzip geprüft; Eventverfügbarkeit/Timing im Forever-Client offen. |
| Ressourcen | 5/10 | Erkennung ist eine Clientevent-Heuristik; Blizzard stellt keine vollständige Ressourcenknoten-ID bereit. |
| Händler/Gegenstände | 7/10 | strukturierte Daten und Positionsmock geprüft; asynchrone Clientinfos live offen. |
| Journal/Chronik | 8/10 | narrative Ebenen und begrenzte Zeilen getestet; sehr große Historien noch nicht live gemessen. |
| Karte/Koordinaten | 6/10 | ungültige Koordinaten werden verworfen; reale Forever-Kartenprojektion offen. |
| UI/Filter/Lokalisierung | 8/10 | Übersetzung und Mock-Paginierung geprüft; echte Skalierungen und Konflikte offen. |
| Performance bis 100k+ | 5/10 | Eventlisten werden nicht gekürzt und Chronikzeilen sind begrenzt; 100k-Such-/Journalbenchmark offen. |
| API-/Build-Kompatibilität | 5/10 | nur Interface 16001/Forever als Ziel; PTR, Retail und andere Classic-Clients sind nicht zugesichert. |

## 9. Freigabegate

Der erste echte Test ist jetzt eng definiert: **P01–P05 zuerst**, dann erst Quests, Ressourcen, Items und Karte. Besteht der SavedVariables-Roundtrip nicht, wird kein produktiver Langzeitverlauf aufgebaut und kein Release als datensicher bezeichnet. Die übrigen Tests prüfen danach die Addonfunktionen, nicht den grundlegenden Speicher-Ladepfad.

Dieser Preflight nutzt dokumentierte WoW-Addon-Erfahrungen und bekannte Fehlerklassen. Er behauptet ausdrücklich nicht, jede API und jeden Fehler aller Addons der vergangenen 20 Jahre vollständig untersucht zu haben. Neue Forever-Beta-Builds können Verhalten ändern; jedes Versionsupdate muss P01–P05 erneut bestehen.
