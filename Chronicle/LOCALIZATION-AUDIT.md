# Sprachprüfung 1.5.31

## Technisch geprüft

- Alle 22 Lua-Dateien mit Lua 5.1 auf Syntax geprüft.
- Beide TOC-Dateien laden `Locale.lua` vor `LocaleText.lua` und vor den Ansichten.
- Alle 46 direkt verwendeten Schlüssel aus `C:L(...)` sind definiert.
- 411 verschiedene feste Aufrufe von `C:LocalizeDisplay(...)` in UI, Wissensansichten und Suche erfasst. Bei allen Aufrufen mit nicht-ASCII-Zeichen liefert jede der sechs zusätzlichen Sprachen einen anderen Wert als der deutsche Quelltext.
- Stichproben in allen sieben Sprachen für Navigation, Waffen, Übersicht, Instanzüberschriften, Statistik und gespeicherte Ereignisse ausgeführt.
- Die Suche zeigt übersetzte Ereignisüberschriften, ohne die gespeicherten deutschen Ereignisse zu verändern.
- Sieben Flaggen-Dateien vorhanden.

## Behobene Fundstellen

- Sichtbare Texte der Waffen- und Traineransichten, Sammelansicht, Notizen, Ziele, Inventar, Statistik, Instanzkapitel und Suche erweitert.
- Feste Tooltip-Texte und kyrillische Tooltip-Schrift ergänzt.
- Offensichtliche Fehlübersetzungen wie „Angenommen“ als „Assumed“, „Preis offen“ als „Price open“ und portugiesisch „Zuletzt“ als „Durar“ korrigiert.

## Noch offen

- Ein visueller Durchgang durch jede Seite in jeder Sprache im laufenden Forever-Client ist weiterhin nötig. Hier wurden Quelltext und Lua-Laufzeit geprüft, keine Spieloberfläche ferngesteuert.
- Namen und Beschreibungen aus WoW-APIs folgen der Sprache des Spielclients. Spielertexte wie freie Ziele und Notizen werden nicht automatisch übersetzt.
- Der Katalog enthält maschinell übersetzte Beschreibungen. Vollständige sprachliche Richtigkeit kann ohne Lektorat durch Sprecher der jeweiligen Sprachen nicht bestätigt werden.
