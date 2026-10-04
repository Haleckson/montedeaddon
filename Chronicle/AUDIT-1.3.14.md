# Technische Prüfung – Version 1.3.14

## Geprüft

- Alle neun Lua-Dateien mit einer Lua-VM kompiliert.
- Beide TOC-Dateien und referenzierte lokale UI-Texturen auf vorhandene Dateien geprüft.
- Ereignis-Simulationen: Inventar und Bank aus späteren Behältern, Inventarzugang, Bossbeute, Dublettenfilter und Chat-Fallback.
- Datenbank-Neuladung simuliert: Ziele, Notizen und Tode bleiben erhalten.
- Globale Suche mit Bossbeute sowie Such- und Statistikfunktionen mit großen synthetischen Datensätzen geprüft.
- Aktuelles FrameXML-Log: keine Chronicle-Meldung; vorhandene Meldungen stammen von AtlasLoot.
- Aktuelle SavedVariables: etwa 128 KB pro Charakter und 134 KB accountweit; keine auffällige Größe.

## Behoben

- Scan wurde zuvor abgebrochen, wenn der erste abgefragte Behälter 0 Plätze meldete. Jetzt werden alle passenden Behälter berücksichtigt; nur wenn insgesamt keine Plätze verfügbar sind, bleibt der vorherige Schnappschuss unangetastet.
- Häufige Datenereignisse lösen bei geöffnetem Fenster nur noch eine gebündelte Aktualisierung nach 0,05 Sekunden aus.
- Seiten mit eigener Kartenansicht erzeugen keine unsichtbaren Textlisten mehr; die Charakterdatenbank wird bei vorhandener Bindung nicht erneut gesucht.
- Datenaktualisierungen setzen die Scrollposition auf derselben Seite nicht mehr zurück.

## Noch im Spiel zu prüfen

- Jeder Navigationspunkt, jede Interaktion und Tooltips bei echter Eingabe.
- Bossloot-Ereignisse und Empfänger in einer echten Gruppe; der Chat-Fallback ist versionsabhängig und ordnet nur Beute kurz nach einem Boss-Sieg zu.
- Kampf, Fenstergrößen und lange Spielsitzungen auf Ruckler oder Lua-Fehler.
- Die gemessenen VM-Zeiten sind kein FPS-Wert des WoW-Clients.
