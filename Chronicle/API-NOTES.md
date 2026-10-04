# API Notizen für WoW: Forever

Stand: 20. September 2026

## Verifizierte Client Basis

- Forever Beta verwendet aktuell die Interface Nummer `16001`.
- Der Client spezifische TOC Suffix lautet `_Camelot`; der Ordnername und die Basis TOC müssen weiterhin `Chronicle` heißen.
- Forever enthält laut der dokumentierten TOC Historie die moderne UI Infrastruktur. Chronicle erkennt einzelne APIs dennoch zur Laufzeit, weil Betaversionen sich kurzfristig ändern können.

Quellen:

- [Warcraft Wiki: TOC Format und aktuelle Interface Versionen](https://warcraft.wiki.gg/wiki/TOC_format)
- [Warcraft Wiki: World of Warcraft API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [Blizzard Support: Addon Richtlinie](https://us.support.blizzard.com/article/000013948)

## Technische Entscheidungen

- `Chronicle_Camelot.toc` ist die bevorzugte Forever TOC; `Chronicle.toc` bleibt als Fallback enthalten.
- Item-, Container-, Quest- und Instanzzugriffe liegen in `Compat.lua` und werden mit Funktions- und Fehlerprüfungen aufgerufen.
- Es gibt keine geschützten Klicks, Makroausführung, Zielwahl, Zaubersteuerung oder Combat Automation.
- Informationen werden ausschließlich nach öffentlich ausgelösten Events oder sichtbaren Spieleraktionen protokolliert.
- Daten, die ein Build nicht sicher anbietet, bleiben leer und verursachen keinen Ladefehler.

## Bekannte Beta Grenzen

Die API Dokumentation und die öffentlich beobachtete Forever Beta können auseinanderlaufen. Deshalb muss die beiliegende Test Checkliste im tatsächlichen Forever Client ausgeführt werden. Besonders Berufsrezepte, Bank Container und Ereignisdetails können sich zwischen Builds ändern.

## Charakterdaten in Chronicle 1.2.31

Gilde und Rang kommen aus `GetGuildInfo("player")`. Beim Login kann die Antwort noch fehlen; Chronicle versucht es bei Gildenereignissen und kurz nach dem Betreten der Welt erneut. Die Skillung wird über `C_SpecializationInfo` gelesen. Falls vorhanden, ergänzt Chronicle die aktive Talentkonfiguration über `C_ClassTalents` und nur lesbare, aktive Talente aus `C_Traits`. Jeder Zugriff wird zur Laufzeit geprüft; der Addon-Code kauft, ändert oder aktiviert keine Talente.

Forever liefert im getesteten Druiden-Fall über `C_SpecializationInfo` nur den Klassennamen. Chronicle 1.2.35 zählt deshalb gekaufte `C_Traits`-Ränge und trennt Zweige anhand eindeutig separierter horizontaler Knotenpositionen. Fehlt diese eindeutige Trennung, bleibt die Zweigverteilung leer; die erfassten Talente und Ränge bleiben sichtbar. Die Zuordnung der Zweignamen folgt der im Client angezeigten Reihenfolge und muss für weitere Klassen im Spiel geprüft werden.

- [GetGuildInfo](https://warcraft.wiki.gg/wiki/API_GetGuildInfo)
- [C_ClassTalents.GetActiveConfigID](https://warcraft.wiki.gg/wiki/API_C_ClassTalents.GetActiveConfigID)
- [C_Traits.GetConfigInfo](https://warcraft.wiki.gg/wiki/API_C_Traits.GetConfigInfo)


## Questlog in Chronicle 1.2.9

Chronicle prueft "C_QuestLog.GetNumQuestLogEntries" und "C_QuestLog.GetInfo" zur Laufzeit; bei aelteren Clients dienen "GetNumQuestLogEntries" und "GetQuestLogTitle" als Fallback. Die aktive Questliste wird aus lesbaren Questlog-Eintraegen mit Quest-ID aufgebaut. "QUEST_LOG_UPDATE" kann sehr haeufig ausloesen; die Erfassung ist deshalb gebuendelt und protokolliert nur neue Quest-IDs. Historische Annahmen von vor der Installation koennen nicht rekonstruiert werden.


## Rezeptdaten in Chronicle 1.2.14

Chronicle nutzt "C_TradeSkillUI.GetAllRecipeIDs", "GetRecipeInfo" und "GetBaseProfessionInfo" nur, wenn diese Funktionen im Client vorhanden sind. Nur Rezepte mit "learned == true" werden gespeichert. Verlinkte Berufsfenster und NPC-Handwerk werden uebersprungen. Die Erfassung erfolgt bei "TRADE_SKILL_SHOW" und relevanten Listenupdates; ohne geoeffnetes Berufsfenster kann das Addon keine vollstaendige Liste ableiten.

