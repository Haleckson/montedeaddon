local C = _G.Chronicle
local ui = { kind = "dungeons", selected = nil, rows = {}, detailRows = {} }
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- These are historical quest/key references, not assertions about Forever's gates.
-- Entries without a dependable identifier remain explicitly unverified.
local routes = {
    ["Gnomeregan"] = { item = 6893 },
    ["Zul'Farrak"] = { item = 9240 },
    ["Sunken Temple"] = { quests = {3520, 3527, 4787, 3528}, item = 10818 },
    ["Maraudon"] = { quests = {7044, 7046}, item = 17191 },
    ["Upper Blackrock Spire"] = { quests = {4742, 4743}, item = 12344 },
    ["Blackrock Depths"] = { quests = {3801, 3802}, item = 11000 },
    ["Scholomance"] = { factionQuests = {
        Alliance = {5092, 5097, 5533, 5537, 5538, 5801, 5803, 5505},
        Horde = {5096, 5098, 838, 964, 5514, 5802, 5804, 5511},
    }, item = 13704 },
    ["Stratholme"] = { items = {7146, 12382} },
    ["Scarlet Monastery: Armory"] = { item = 7146 },
    ["Scarlet Monastery: Cathedral"] = { item = 7146 },
    ["Dire Maul North"] = { item = 18249 },
    ["Dire Maul West"] = { item = 18249 },
    ["Molten Core"] = { anyQuest = {7487, 7848} },
    ["Blackwing Lair"] = { quests = {7761} },
    ["Onyxia's Lair"] = { factionQuests = {
        Alliance = {4182, 4183, 4184, 4185, 4186, 4223, 4224, 4241, 4242, 4264, 4282, 4322, 6402, 6403, 6501, 6502},
        Horde = {4903, 4941, 4974, 6566, 6567, 6568, 6569, 6570, 6584, 6582, 6583, 6585, 6601, 6602},
    }, item = 16309 },
    ["Naxxramas"] = { anyQuest = {9121, 9122, 9123} },
}
-- Only gates to a dungeon wing or upper section appear in the dungeon overview.
-- Shortcuts, alternate entrances and boss summons stay out of that overview.
-- This is a Classic reference; Forever may use different access rules.
local dungeonGateRoutes = {
    ["Scarlet Monastery: Armory"] = true,
    ["Scarlet Monastery: Cathedral"] = true,
    ["Scholomance"] = true,
    ["Upper Blackrock Spire"] = true,
    ["Dire Maul North"] = true,
    ["Dire Maul West"] = true,
}
local questNames = {
    [7487] = "Attunement to the Core", [7848] = "Attunement to the Core", [7761] = "Blackhand's Command",
    [9121] = "The Dread Citadel - Naxxramas", [9122] = "The Dread Citadel - Naxxramas", [9123] = "The Dread Citadel - Naxxramas",
    [3520] = "Screecher Spirits", [3527] = "The Prophecy of Mosh'aru", [4787] = "The Ancient Egg", [3528] = "The God Hakkar",
    [7044] = "Legends of Maraudon", [7046] = "The Scepter of Celebras",
    [4742] = "Seal of Ascension", [4743] = "Seal of Ascension",
    [3801] = "Dark Iron Legacy", [3802] = "Dark Iron Legacy",
    [5092] = "Clear the Way", [5096] = "Scarlet Diversions", [5097] = "All Along the Watchtowers", [5098] = "All Along the Watchtowers",
    [5533] = "Scholomance", [838] = "Scholomance", [5537] = "Skeletal Fragments", [964] = "Skeletal Fragments",
    [5538] = "Mold Rhymes With...", [5514] = "Mold Rhymes With...", [5801] = "Fire Plume Forged", [5802] = "Fire Plume Forged",
    [5803] = "Araj's Scarab", [5804] = "Araj's Scarab", [5505] = "The Key to Scholomance", [5511] = "The Key to Scholomance",
    [4182] = "Dragonkin Menace", [4183] = "The True Masters", [4184] = "The True Masters", [4185] = "The True Masters",
    [4186] = "The True Masters", [4223] = "The True Masters", [4224] = "The True Masters", [4241] = "Marshal Windsor",
    [4242] = "Abandoned Hope", [4264] = "A Crumpled Up Note", [4282] = "A Shred of Hope", [4322] = "Jail Break!",
    [6402] = "Stormwind Rendezvous", [6403] = "The Great Masquerade", [6501] = "The Dragon's Eye", [6502] = "Drakefire Amulet",
    [4903] = "Warlord's Command", [4941] = "Eitrigg's Wisdom", [4974] = "For The Horde!", [6566] = "What the Wind Carries",
    [6567] = "The Champion of the Horde", [6568] = "The Testament of Rexxar", [6569] = "Oculus Illusions", [6570] = "Emberstrife",
    [6584] = "The Test of Skulls, Chronalis", [6582] = "The Test of Skulls, Scryer", [6583] = "The Test of Skulls, Somnus",
    [6585] = "The Test of Skulls, Axtroz", [6601] = "Ascension...", [6602] = "Blood of the Black Dragon Champion",
}
local itemNames = {
    [6893] = "Workshop Key", [9240] = "Mallet of Zul'Farrak", [10818] = "Yeh'kinya's Scroll",
    [17191] = "Scepter of Celebras", [12344] = "Seal of Ascension", [11000] = "Shadowforge Key",
    [13704] = "Skeleton Key", [7146] = "The Scarlet Key", [12382] = "Key to the City",
    [18249] = "Crescent Key", [16309] = "Drakefire Amulet",
}
-- Short historical Classic objective hints. Live quest-log objectives take priority.
-- The first string is English; the second is German. Other UI languages use the
-- English reference when the WoW client has no localized objective data.
local objectiveHints = {
    [838]={"Speak to Apothecary Dithers at the Bulwark.","Sprich mit Apotheker Dithers am Bollwerk."},
    [964]={"Collect 15 Skeletal Fragments for Apothecary Dithers.","Sammle 15 Skelettfragmente für Apotheker Dithers."},
    [3520]={"Capture three screecher spirits in Feralas and return to Yeh'kinya.","Fange drei Kreischergeister in Feralas und kehre zu Yeh'kinya zurück."},
    [3527]={"Bring both Mosh'aru tablets to Yeh'kinya in Tanaris.","Bringe beide Mosh'aru-Tafeln zu Yeh'kinya in Tanaris."},
    [3528]={"Bring the filled Egg of Hakkar to Yeh'kinya.","Bringe das gefüllte Ei von Hakkar zu Yeh'kinya."},
    [3801]={"Speak to Franclorn Forgewright for the Shadowforge Key task.","Sprich für den Schattenschmiedeschlüssel mit Franclorn Forgewright."},
    [3802]={"Defeat Fineous Darkvire; place Ironfel on Franclorn's statue.","Besiege Fineous Darkvire und lege Eisenhauer auf Franclorns Statue."},
    [4182]={"Defeat the required black dragonkin in the Burning Steppes.","Besiege die verlangten schwarzen Drachkin in der Brennenden Steppe."},
    [4183]={"Deliver Helendis Riverhorn's letter to Magistrate Solomon.","Bringe Helendis Riverhorns Brief zu Magistrat Solomon."},
    [4184]={"Deliver Solomon's plea to Bolvar Fordragon in Stormwind.","Bringe Solomons Bitte zu Bolvar Fordragon in Sturmwind."},
    [4185]={"Speak with Lady Katrana Prestor, then Bolvar Fordragon.","Sprich mit Lady Katrana Prestor und dann mit Bolvar Fordragon."},
    [4186]={"Take Bolvar's decree back to Magistrate Solomon.","Bringe Bolvars Erlass zurück zu Magistrat Solomon."},
    [4223]={"Report to Marshal Maxwell in the Burning Steppes.","Melde dich bei Marschall Maxwell in der Brennenden Steppe."},
    [4224]={"Ask Ragged John about Windsor and report to Marshal Maxwell.","Befrage Ragged John zu Windsor und berichte Marschall Maxwell."},
    [4241]={"Find Marshal Windsor inside Blackrock Depths.","Finde Marschall Windsor in den Schwarzfelstiefen."},
    [4242]={"Bring the news about Windsor to Marshal Maxwell.","Überbringe Marschall Maxwell die Nachricht über Windsor."},
    [4264]={"Take the crumpled note to Marshal Windsor.","Bringe die zerknitterte Notiz zu Marschall Windsor."},
    [4282]={"Recover Windsor's information from Argelmach and Angerforge.","Hole Windsors Informationen von Argelmach und Zornesschmied."},
    [4322]={"Free Windsor and his allies, then report to Marshal Maxwell.","Befreie Windsor und seine Verbündeten; melde dich bei Marschall Maxwell."},
    [4742]={"Collect the three command gemstones and the Unadorned Seal for Vaelan.","Sammle die drei Befehlsedelsteine und das schmucklose Siegel für Vaelan."},
    [4743]={"Subdue Emberstrife in Dustwallow Marsh and forge the seal with his flame.","Bezwinge Emberstrife in den Düstermarschen und schmiede das Siegel mit seiner Flamme."},
    [4787]={"Bring the Ancient Egg to Yeh'kinya in Tanaris.","Bringe das Uralte Ei zu Yeh'kinya in Tanaris."},
    [4903]={"Complete Warlord Goretooth's assignment in Blackrock Spire.","Erledige Kriegsfürst Bluthauers Auftrag in der Schwarzfelsspitze."},
    [4941]={"Speak with Eitrigg and then Thrall in Orgrimmar.","Sprich in Orgrimmar mit Eitrigg und danach mit Thrall."},
    [4974]={"Defeat Warchief Rend Blackhand in Upper Blackrock Spire.","Besiege Kriegshäuptling Rend Schwarzfaust in der Oberen Schwarzfelsspitze."},
    [5092]={"Defeat Skeletal Flayers and Slavering Ghouls at Sorrow Hill.","Besiege Skelettschinder und sabbernde Ghule am Trauerhügel."},
    [5096]={"Destroy the Scarlet camp's command tent and plant the Scourge banner.","Zerstöre das Kommandozelt des Scharlachroten Kreuzzugs und stelle das Geißelbanner auf."},
    [5097]={"Mark all four towers in Andorhal with the Beacon Torch.","Markiere alle vier Türme in Andorhal mit der Signalfeuerfackel."},
    [5098]={"Mark all four towers in Andorhal with the Beacon Torch.","Markiere alle vier Türme in Andorhal mit der Signalfeuerfackel."},
    [5505]={"Collect the finished Skeleton Key from Alchemist Arbington.","Hole den fertigen Skelettschlüssel bei Alchemist Arbington ab."},
    [5511]={"Collect the finished Skeleton Key from Apothecary Dithers.","Hole den fertigen Skelettschlüssel bei Apotheker Dithers ab."},
    [5514]={"Take the imbued fragments and 15 gold to Krinkle Goodsteel.","Bringe die erfüllten Fragmente und 15 Gold zu Krinkle Goodsteel."},
    [5533]={"Speak to Alchemist Arbington at Chillwind Camp.","Sprich mit Alchemist Arbington am Eiswindlager."},
    [5537]={"Collect 15 Skeletal Fragments for Alchemist Arbington.","Sammle 15 Skelettfragmente für Alchemist Arbington."},
    [5538]={"Take the imbued fragments and 15 gold to Krinkle Goodsteel.","Bringe die erfüllten Fragmente und 15 Gold zu Krinkle Goodsteel."},
    [5801]={"Forge the key mold with two Thorium Bars at Fire Plume Ridge.","Schmiede die Schlüsselform mit zwei Thoriumbarren am Feuerfederberg."},
    [5802]={"Forge the key mold with two Thorium Bars at Fire Plume Ridge.","Schmiede die Schlüsselform mit zwei Thoriumbarren am Feuerfederberg."},
    [5803]={"Defeat Araj the Summoner and bring his scarab to Arbington.","Besiege Araj den Beschwörer und bringe seinen Skarabäus zu Arbington."},
    [5804]={"Defeat Araj the Summoner and bring his scarab to Dithers.","Besiege Araj den Beschwörer und bringe seinen Skarabäus zu Dithers."},
    [6402]={"Meet Squire Rowe at the gates of Stormwind.","Triff Knappe Rowe an den Toren von Sturmwind."},
    [6403]={"Follow and protect Windsor through Stormwind.","Folge Windsor durch Sturmwind und beschütze ihn."},
    [6501]={"Find someone who can restore the Dragon's Eye fragment.","Finde jemanden, der das Fragment des Drachenauges erneuern kann."},
    [6502]={"Defeat General Drakkisath and bring back his blood.","Besiege General Drakkisath und bringe sein Blut zurück."},
    [6566]={"Listen to Thrall in Orgrimmar.","Höre Thrall in Orgrimmar zu."},
    [6567]={"Find Rexxar on the roads of Desolace.","Finde Rexxar auf den Wegen durch Desolace."},
    [6568]={"Deliver Rexxar's testament to Myranda in Western Plaguelands.","Bringe Rexxars Testament zu Myranda in den Westlichen Pestländern."},
    [6569]={"Collect 20 Black Dragonspawn Eyes in Blackrock Spire.","Sammle 20 Augen schwarzer Drachkin in der Schwarzfelsspitze."},
    [6570]={"Wear the amulet and speak with Emberstrife in his lair.","Trage das Amulett und sprich in seiner Höhle mit Emberstrife."},
    [6582]={"Defeat Scryer in Winterspring and bring his skull to Emberstrife.","Besiege Scryer in Winterquell und bringe seinen Schädel zu Emberstrife."},
    [6583]={"Defeat Somnus and bring his skull to Emberstrife.","Besiege Somnus und bringe seinen Schädel zu Emberstrife."},
    [6584]={"Defeat Chronalis near the Caverns of Time and bring his skull back.","Besiege Chronalis bei den Höhlen der Zeit und bringe seinen Schädel zurück."},
    [6585]={"Defeat Axtroz near Grim Batol and bring his skull to Emberstrife.","Besiege Axtroz bei Grim Batol und bringe seinen Schädel zu Emberstrife."},
    [6601]={"Show the dull Drakefire Amulet to Rexxar.","Zeige Rexxar das matte Drachenfeueramulett."},
    [6602]={"Defeat General Drakkisath and bring his blood to Rexxar.","Besiege General Drakkisath und bringe sein Blut zu Rexxar."},
    [7044]={"Find both parts of Celebras's scepter and speak with him.","Finde beide Teile von Celebras' Szepter und sprich mit ihm."},
    [7046]={"Help Celebras complete the scepter ritual.","Hilf Celebras, das Szepterritual abzuschließen."},
    [7487]={"Recover a Core Fragment at the Molten Core portal in Blackrock Depths.","Hole ein Kernfragment am Portal zum Geschmolzenen Kern in den Schwarzfelstiefen."},
    [7761]={"Gain the Mark of Drakkisath to use the Orb of Command.","Erlange das Mal von Drakkisath, um die Befehlskugel zu nutzen."},
    [7848]={"Recover a Core Fragment at the Molten Core portal in Blackrock Depths.","Hole ein Kernfragment am Portal zum Geschmolzenen Kern in den Schwarzfelstiefen."},
    [9121]={"Reach Honored with Argent Dawn; bring 5 Arcane Crystals, 2 Nexus Crystals, 1 Righteous Orb and 60 gold.","Erreiche Wohlwollend bei der Argentumdämmerung; bringe 5 Arkankristalle, 2 Nexuskristalle, 1 Rechtschaffene Kugel und 60 Gold."},
    [9122]={"Reach Revered with Argent Dawn; bring 2 Arcane Crystals, 1 Nexus Crystal and 30 gold.","Erreiche Respektvoll bei der Argentumdämmerung; bringe 2 Arkankristalle, 1 Nexuskristall und 30 Gold."},
    [9123]={"Reach Exalted with Argent Dawn; speak with Archmage Angela Dosantos.","Erreiche Ehrfürchtig bei der Argentumdämmerung und sprich mit Erzmagierin Angela Dosantos."},
}
-- Quest giver positions are reference points, not quest objective markers.
-- Coordinates are a small curated subset of the public in-game quest catalog.
local questGivers = {
    [3520]={1446,67,22.4}, [3527]={1446,67,22.4}, [3528]={1446,67,22.4}, [4787]={1446,67,22.4},
    [3801]={1415,48.6,64.2}, [4182]={1428,85.6,69}, [4183]={1428,85.6,69},
    [4184]={1433,30,44.2}, [4185]={1453,78,18}, [4186]={1453,78,18},
    [4223]={1433,30,44.2}, [4224]={1428,84.6,68.8}, [4241]={1428,84.6,68.8},
    [4903]={1418,3,47.6}, [4941]={1418,5.8,47.4}, [4974]={1454,32,37.8},
    [6402]={1428,84.74,69.02}, [6403]={1429,32,49.2}, [6501]={1453,78,18}, [6502]={1452,54.4,51.2},
    [6566]={1454,32,37.8}, [6567]={1454,32,37.8}, [6568]={1444,45.2,2.6},
    [6569]={1422,50.8,77.8}, [6570]={1422,50.79,77.85},
    [6582]={1445,56.66,87.72}, [6583]={1445,56.66,87.72}, [6584]={1445,56.66,87.72},
    [6585]={1445,56.6,87.6}, [6601]={1445,56.6,87.6}, [6602]={1444,45.2,2.6},
    [7044]={1414,38.8,58}, [7487]={1415,48.4,63.8}, [7848]={1415,48.4,63.8},
    [9121]={1423,81.5,59}, [9122]={1423,81.5,59}, [9123]={1423,81.5,59},
}
local function routeQuests(route)
    if not route then return {} end
    local quests = {}
    for _, id in ipairs(route.quests or {}) do quests[#quests + 1] = id end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    for _, id in ipairs(route.factionQuests and route.factionQuests[faction] or {}) do quests[#quests + 1] = id end
    return quests
end
local function routeItems(route)
    if not route then return {} end
    if route.items then return route.items end
    return route.item and {route.item} or {}
end

local strings = {
    enUS = {"Dungeons", "Raids", "Historical quest and key references", "Forever access rules may differ. A quest or key state does not confirm entry.", "Reference path", "No verified access path in the beta catalog", "Quest", "Item", "Completed", "Active", "Not completed", "Owned", "Not detected", "Not verified", "Next check", "Continue the active quest", "Check this quest in game", "Check this key in game", "No further step recorded", "The client cannot verify this state", "of"},
    deDE = {"Dungeons", "Raids", "Historische Quest- und Schlüsselwege", "Forever-Zugangsregeln können abweichen. Quest- oder Schlüsselstand bestätigt keinen Zutritt.", "Referenzweg", "Kein verifizierter Zugangsweg im Beta-Katalog", "Quest", "Gegenstand", "Abgeschlossen", "Aktiv", "Nicht abgeschlossen", "Vorhanden", "Nicht gefunden", "Nicht verifiziert", "Nächste Prüfung", "Aktive Quest fortsetzen", "Diese Quest im Spiel prüfen", "Diesen Schlüssel im Spiel prüfen", "Kein weiterer Schritt erfasst", "Der Client kann diesen Stand nicht prüfen", "von"},
    frFR = {"Donjons", "Raids", "Références historiques des quêtes et clés", "Les règles d'accès de Forever peuvent différer. Une quête ou une clé ne confirme pas l'entrée.", "Parcours de référence", "Aucun accès vérifié dans le catalogue bêta", "Quête", "Objet", "Terminée", "Active", "Non terminée", "Possédé", "Non détecté", "Non vérifié", "Prochaine vérification", "Poursuivre la quête active", "Vérifier cette quête en jeu", "Vérifier cette clé en jeu", "Aucune autre étape connue", "État non vérifiable par le client", "sur"},
    esES = {"Mazmorras", "Bandas", "Referencias históricas de misiones y llaves", "Las reglas de acceso de Forever pueden variar. Una misión o llave no confirma la entrada.", "Ruta de referencia", "No hay acceso verificado en el catálogo beta", "Misión", "Objeto", "Completada", "Activa", "Sin completar", "En posesión", "No detectado", "Sin verificar", "Siguiente comprobación", "Continúa la misión activa", "Consulta esta misión en el juego", "Consulta esta llave en el juego", "No hay más pasos registrados", "El cliente no puede verificar el estado", "de"},
    itIT = {"Spedizioni", "Incursioni", "Riferimenti storici di missioni e chiavi", "Le regole di accesso di Forever possono differire. Missioni e chiavi non confermano l'ingresso.", "Percorso di riferimento", "Nessun accesso verificato nel catalogo beta", "Missione", "Oggetto", "Completata", "Attiva", "Non completata", "Posseduto", "Non rilevato", "Non verificato", "Prossima verifica", "Continua la missione attiva", "Controlla questa missione nel gioco", "Controlla questa chiave nel gioco", "Nessun altro passo registrato", "Il client non può verificare lo stato", "di"},
    ptBR = {"Masmorras", "Raides", "Referências históricas de missões e chaves", "As regras de acesso de Forever podem variar. Missão ou chave não confirma entrada.", "Caminho de referência", "Nenhum acesso verificado no catálogo beta", "Missão", "Item", "Concluída", "Ativa", "Não concluída", "Possuído", "Não detectado", "Não verificado", "Próxima verificação", "Continue a missão ativa", "Verifique esta missão no jogo", "Verifique esta chave no jogo", "Nenhuma outra etapa registrada", "O cliente não pode verificar o estado", "de"},
    ruRU = {"Подземелья", "Рейды", "Исторические задания и ключи", "Правила доступа в Forever могут отличаться. Задание или ключ не подтверждают вход.", "Справочный путь", "Нет подтверждённого пути в каталоге беты", "Задание", "Предмет", "Завершено", "Активно", "Не завершено", "Есть", "Не обнаружен", "Не проверено", "Следующая проверка", "Продолжить активное задание", "Проверить задание в игре", "Проверить ключ в игре", "Других шагов нет", "Клиент не может проверить состояние", "из"},
}
local function T(n)
    local code = C:GetLanguage()
    if code == "esMX" then code = "esES" elseif code == "ptPT" then code = "ptBR" end
    return (strings[code] or strings.deDE)[n]
end
local dialogText = {
    enUS = {map = "Show on map", close = "Close", unavailable = "No map marker is available for this quest in the current client. Accept it first, then try again.", select = "Select an instance to open its access path.", key = "Item reference", variant = "Alternative quest variants"},
    deDE = {map = "Auf Karte anzeigen", close = "Schließen", unavailable = "Für diese Quest ist im aktuellen Client keine Kartenmarkierung verfügbar. Nimm sie zuerst an und versuche es erneut.", select = "Wähle eine Instanz, um ihren Zugangsweg zu öffnen.", key = "Gegenstand", variant = "Alternative Questvarianten"},
    frFR = {map = "Afficher sur la carte", close = "Fermer", unavailable = "Aucun repère de carte disponible pour cette quête. Acceptez-la, puis réessayez.", select = "Choisissez une instance pour ouvrir son parcours d'accès.", key = "Objet de référence", variant = "Variantes de quête"},
    esES = {map = "Mostrar en el mapa", close = "Cerrar", unavailable = "No hay marcador para esta misión en el cliente. Acéptala y vuelve a intentarlo.", select = "Elige una instancia para abrir su ruta de acceso.", key = "Objeto de referencia", variant = "Variantes de misión"},
    itIT = {map = "Mostra sulla mappa", close = "Chiudi", unavailable = "Nessun indicatore disponibile per questa missione. Accettala e riprova.", select = "Seleziona un'istanza per aprire il percorso di accesso.", key = "Oggetto di riferimento", variant = "Varianti della missione"},
    ptBR = {map = "Mostrar no mapa", close = "Fechar", unavailable = "Não há marcador para esta missão no cliente. Aceite-a e tente novamente.", select = "Selecione uma instância para abrir o caminho de acesso.", key = "Item de referência", variant = "Variantes da missão"},
    ruRU = {map = "Показать на карте", close = "Закрыть", unavailable = "Для этого задания нет метки на карте. Примите его и попробуйте снова.", select = "Выберите подземелье или рейд для просмотра пути.", key = "Предмет", variant = "Альтернативные варианты задания"},
}
local function D(key)
    local code = C:GetLanguage()
    if code == "esMX" then code = "esES" elseif code == "ptPT" then code = "ptBR" end
    return (dialogText[code] or dialogText.deDE)[key]
end
local extraText = {
    enUS = {back="Back", giver="Mark quest giver", unavailable="No reliable position is recorded for this step. An active quest can still be opened in the quest log.", marked="Quest giver marked on the map. This is a starting point, not the quest objective.", markerFailed="The client could not set the map waypoint.", questPath="Quest steps", keyPath="Keys and items", overview="Choose an instance to see its access path.", gates="Dungeon wings with a historical key or entry route"},
    deDE = {back="Zurück", giver="Questgeber markieren", unavailable="Für diesen Schritt ist keine verlässliche Position erfasst. Eine aktive Quest kann im Questlog geöffnet werden.", marked="Questgeber auf der Karte markiert. Dies ist der Startpunkt, nicht das Questziel.", markerFailed="Der Client konnte keinen Kartenwegpunkt setzen.", questPath="Questschritte", keyPath="Schlüssel und Gegenstände", overview="Wähle eine Instanz, um ihren Zugangsweg zu sehen.", gates="Dungeon-Bereiche mit historischem Schlüssel oder Zugangsweg"},
    frFR = {back="Retour", giver="Marquer le donneur de quête", unavailable="Aucune position fiable pour cette étape. Une quête active peut être ouverte dans le journal.", marked="Donneur de quête marqué sur la carte. C'est le départ, pas l'objectif.", markerFailed="Impossible de placer un point sur la carte.", questPath="Étapes de quête", keyPath="Clés et objets", overview="Choisissez une instance pour voir son accès.", gates="Sections de donjon avec clé ou accès historique"},
    esES = {back="Volver", giver="Marcar al iniciador", unavailable="No hay posición fiable para este paso. Puedes abrir una misión activa en el diario.", marked="Iniciador marcado en el mapa. Es el inicio, no el objetivo.", markerFailed="No se pudo crear un punto en el mapa.", questPath="Pasos de misión", keyPath="Llaves y objetos", overview="Elige una instancia para ver su ruta.", gates="Secciones de mazmorra con llave o acceso histórico"},
    itIT = {back="Indietro", giver="Segna chi assegna la missione", unavailable="Nessuna posizione affidabile per questo passo. Puoi aprire una missione attiva nel diario.", marked="Il personaggio che assegna la missione è segnato sulla mappa. È il punto di partenza, non l'obiettivo.", markerFailed="Impossibile impostare un punto sulla mappa.", questPath="Passi della missione", keyPath="Chiavi e oggetti", overview="Seleziona un'istanza per vedere il percorso.", gates="Sezioni con chiave o percorso d'accesso storico"},
    ptBR = {back="Voltar", giver="Marcar início", unavailable="Não há posição confiável para esta etapa. Uma missão ativa pode ser aberta no diário.", marked="Início marcado no mapa. Este é o ponto de partida, não o objetivo.", markerFailed="Não foi possível definir um ponto no mapa.", questPath="Etapas da missão", keyPath="Chaves e itens", overview="Selecione uma instância para ver o caminho.", gates="Áreas de masmorra com chave ou acesso histórico"},
    ruRU = {back="Назад", giver="Отметить место выдачи", unavailable="Для этого шага нет надёжных координат. Активное задание можно открыть в журнале.", marked="Место выдачи задания отмечено. Это начало, а не цель задания.", markerFailed="Не удалось установить точку на карте.", questPath="Этапы заданий", keyPath="Ключи и предметы", overview="Выберите подземелье или рейд, чтобы увидеть путь.", gates="Части подземелий с историческим ключом или доступом"},
}
local function E(key)
    local code = C:GetLanguage()
    if code == "esMX" then code = "esES" elseif code == "ptPT" then code = "ptBR" end
    return (extraText[code] or extraText.deDE)[key]
end
local objectiveText = {
    enUS={show="Show objectives", hide="Hide objectives", live="Current quest objectives", reference="Historical objective reference", story="Quest text", assignment="Assignment", missing="No objective details are available for this quest."},
    deDE={show="Aufgaben anzeigen", hide="Aufgaben ausblenden", live="Aktuelle Questziele", reference="Historischer Aufgabenhinweis", story="Questtext", assignment="Auftrag", missing="Für diese Quest sind keine Aufgabendetails verfügbar."},
    frFR={show="Afficher les objectifs", hide="Masquer les objectifs", live="Objectifs actuels", reference="Objectifs historiques", story="Texte de quête", assignment="Mission", missing="Aucun détail d'objectif disponible pour cette quête."},
    esES={show="Mostrar objetivos", hide="Ocultar objetivos", live="Objetivos actuales", reference="Objetivos históricos", story="Texto de la misión", assignment="Encargo", missing="No hay detalles de objetivos para esta misión."},
    itIT={show="Mostra obiettivi", hide="Nascondi obiettivi", live="Obiettivi attuali", reference="Obiettivi storici", story="Testo della missione", assignment="Incarico", missing="Nessun dettaglio disponibile per questa missione."},
    ptBR={show="Mostrar objetivos", hide="Ocultar objetivos", live="Objetivos atuais", reference="Objetivos históricos", story="Texto da missão", assignment="Tarefa", missing="Não há detalhes de objetivos para esta missão."},
    ruRU={show="Показать цели", hide="Скрыть цели", live="Текущие цели задания", reference="Историческая справка", story="Текст задания", assignment="Поручение", missing="Для этого задания нет сведений о целях."},
}
local function O(key)
    local code = C:GetLanguage()
    if code == "esMX" then code = "esES" elseif code == "ptPT" then code = "ptBR" end
    return (objectiveText[code] or objectiveText.deDE)[key]
end
local function font(parent, size, color)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont(C:FontPath(), size)
    f:SetTextColor(unpack(color or { .96, .89, .72 }))
    f:SetJustifyH("LEFT")
    return f
end
local function questState(id)
    local completionKnown = false
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, completed = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
        if ok then completionKnown = true end
        if ok and completed then return "done" end
    end
    for _, q in ipairs(C.char and C.char.quests or {}) do
        if tonumber(q.id) == id and q.status == "completed" then return "done" end
    end
    if C.char and C.char.activeQuests and (C.char.activeQuests[tostring(id)] or C.char.activeQuests[id]) then return "active" end
    return completionKnown and "incomplete" or "unknown"
end
local function itemState(id)
    if GetItemCount then
        local ok, count = pcall(GetItemCount, id, true)
        if ok and type(count) == "number" then return count > 0 and "owned" or "absent" end
    end
    return "unknown"
end
local pendingQuestTitles, pendingItemNames = {}, {}
local function titleForQuest(id)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, id)
        if ok and type(title) == "string" and title ~= "" then return title end
    end
    if not pendingQuestTitles[id] and C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        pendingQuestTitles[id] = true
        pcall(C_QuestLog.RequestLoadQuestByID, id)
    end
    return questNames[id] or (T(7) .. " #" .. id)
end
local function titleForItem(id)
    if C_Item and C_Item.GetItemNameByID then
        local ok, title = pcall(C_Item.GetItemNameByID, id)
        if ok and type(title) == "string" and title ~= "" then return title end
    end
    if GetItemInfo then
        local ok, title = pcall(GetItemInfo, id)
        if ok and type(title) == "string" and title ~= "" then return title end
    end
    if not pendingItemNames[id] and C_Item and C_Item.RequestLoadItemDataByID then
        pendingItemNames[id] = true
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
    return itemNames[id] or (T(8) .. " #" .. id)
end
local function objectiveForQuest(id)
    if questState(id) == "active" and C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives,id)
        if ok and type(objectives) == "table" then
            local lines = {}
            for _,objective in ipairs(objectives) do
                if type(objective.text) == "string" and objective.text ~= "" then
                    lines[#lines+1] = (objective.finished and "✓  " or "•  ") .. objective.text
                end
            end
            if #lines > 0 then return table.concat(lines,"\n"),true end
        end
    end
    if questState(id) == "active" and C_QuestLog and C_QuestLog.GetLogIndexForQuestID and GetQuestLogQuestText then
        local ok,index = pcall(C_QuestLog.GetLogIndexForQuestID,id)
        if ok and type(index) == "number" and index > 0 then
            local textOK,_,summary = pcall(GetQuestLogQuestText,index)
            if textOK and type(summary) == "string" and summary ~= "" then return summary,true end
        end
    end
    local hint = objectiveHints[id]
    if hint then return hint[C:GetLanguage() == "deDE" and 2 or 1],false end
    return O("missing"),false
end
local titleLoader = CreateFrame("Frame")
titleLoader:RegisterEvent("QUEST_DATA_LOAD_RESULT")
titleLoader:RegisterEvent("ITEM_DATA_LOAD_RESULT")
titleLoader:SetScript("OnEvent",function(_,event,id,success)
    local pending = event == "QUEST_DATA_LOAD_RESULT" and pendingQuestTitles or pendingItemNames
    if pending[id] ~= true then return end
    pending[id] = "loaded"
    if success and ui.parent and ui.width and ui.detailName and ui.detailRoot and ui.detailRoot:IsShown() then
        C:ShowAttunements(ui.parent,ui.width)
    end
end)
local function linkForItem(id)
    if GetItemInfo then
        local ok, _, link = pcall(GetItemInfo, id)
        if ok and type(link) == "string" and link ~= "" then return link end
    end
    return "|Hitem:" .. id .. "|h[" .. titleForItem(id) .. "]|h"
end
local function showItemTooltip(button)
    if not button.itemID or not GameTooltip then return end
    GameTooltip:SetOwner(button,"ANCHOR_CURSOR")
    local ok = GameTooltip.SetHyperlink and pcall(GameTooltip.SetHyperlink,GameTooltip,"item:" .. button.itemID)
    if not ok then GameTooltip:SetText(titleForItem(button.itemID)) end
    GameTooltip:Show()
end
local function openItemLink(button)
    if not button.itemID then return end
    local link = linkForItem(button.itemID)
    if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
    elseif SetItemRef then
        SetItemRef("item:" .. button.itemID,link,"LeftButton")
    end
end
local function linesFor(route)
    if not route then return T(6), T(19) end
    local lines, nextStep = {}, nil
    local function addQuest(id)
        local state = questState(id)
        local label = state == "done" and T(9) or state == "active" and T(10) or state == "incomplete" and T(11) or T(14)
        lines[#lines + 1] = titleForQuest(id) .. "  [" .. label .. "]"
        if not nextStep and state ~= "done" then nextStep = state == "active" and T(16) or T(17) end
    end
    for _, id in ipairs(routeQuests(route)) do addQuest(id) end
    if route.anyQuest then
        local anyDone = false
        for _, id in ipairs(route.anyQuest) do if questState(id) == "done" then anyDone = true end end
        lines[#lines + 1] = T(7) .. " " .. table.concat(route.anyQuest, " / ") .. "  [" .. (anyDone and T(9) or T(14)) .. "]"
        if not anyDone then nextStep = T(17) end
    end
    for _, id in ipairs(routeItems(route)) do
        local state = itemState(id)
        lines[#lines + 1] = titleForItem(id) .. "  [" .. (state == "owned" and T(12) or state == "absent" and T(13) or T(14)) .. "]"
        if not nextStep and state ~= "owned" then nextStep = T(18) end
    end
    return table.concat(lines, "\n\n"), nextStep or T(19)
end
local function showQuestOnMap(id)
    local point = questGivers[id]
    if point and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local ok, marker = pcall(UiMapPoint.CreateFromCoordinates, point[1], point[2] / 100, point[3] / 100)
        if ok and marker and pcall(C_Map.SetUserWaypoint, marker) then
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
            end
            if C_Map.OpenWorldMap then
                pcall(C_Map.OpenWorldMap, point[1])
            elseif ToggleWorldMap then
                if not WorldMapFrame or not WorldMapFrame:IsShown() then pcall(ToggleWorldMap) end
                if WorldMapFrame and WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, point[1]) end
            end
            C:Print(E("marked"))
            return
        end
        C:Print(E("markerFailed"))
        return
    end
    if questState(id) == "active" and QuestMapFrame_OpenToQuestDetails then
        local ok = pcall(QuestMapFrame_OpenToQuestDetails, id)
        if ok then return end
    end
    C:Print(E("unavailable"))
end
local function makeCard(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({bgFile=WHITE, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=13, insets={left=3,right=3,top=3,bottom=3}})
    card:SetBackdropColor(.16,.105,.052,1)
    card:SetBackdropBorderColor(.59,.44,.17,1)
    if C.ApplyMaterial then C:ApplyMaterial(card,.3) end
    if C.OrnateCorners then C:OrnateCorners(card) end
    return card
end
local function makeButton(parent, width)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width,25)
    button.label = font(button,11,{1,.82,.12})
    button.label:SetPoint("CENTER")
    C:StyleChronicleButton(button)
    return button
end
local function insetPanel(parent)
    return CreateFrame("Frame",nil,parent)
end
local function buildDetail(parent)
    local root = CreateFrame("Frame",nil,parent)
    root:SetPoint("TOPLEFT",4,0)
    root.hero = makeCard(root); root.hero:SetPoint("TOPLEFT",12,-12)
    root.hero.kicker = font(root.hero,10,{1,.81,.12}); root.hero.kicker:SetPoint("TOPLEFT",15,-12)
    root.hero.title = font(root.hero,22,{1,.86,.61}); root.hero.title:SetPoint("TOPLEFT",15,-32)
    root.hero.note = font(root.hero,11,{.76,.69,.55}); root.hero.note:SetPoint("TOPLEFT",15,-66)
    root.back = makeButton(root,90); root.back:SetPoint("TOPRIGHT",-24,-140)
    root.back:SetScript("OnClick",function()
        ui.detailName=nil; ui.selectedEntry=nil
        C:ShowAttunements(parent,root:GetWidth()+8)
        if parent:GetParent() and parent:GetParent().SetVerticalScroll then parent:GetParent():SetVerticalScroll(0) end
    end)
    root.path = font(root,13,{1,.82,.1}); root.path:SetPoint("TOPLEFT",27,-144)
    root.next = font(root,11,{.78,.7,.54}); root.next:SetPoint("TOPLEFT",27,-171)
    root.list = insetPanel(root)
    root.divider = root:CreateTexture(nil,"ARTWORK"); root.divider:SetTexture(WHITE)
    root.divider:SetVertexColor(.5,.34,.13,.75); root.divider:SetWidth(1)
    root.list.heading = font(root.list,12,{1,.82,.1}); root.list.heading:SetPoint("TOPLEFT",16,-13)
    root.list.count = font(root.list,10,{.72,.65,.52}); root.list.count:SetPoint("TOPRIGHT",-17,-15)
    root.list.rule = root.list:CreateTexture(nil,"ARTWORK"); root.list.rule:SetTexture(WHITE)
    root.list.rule:SetVertexColor(.54,.37,.15,.8); root.list.rule:SetHeight(1)
    root.list.rule:SetPoint("TOPLEFT",15,-37); root.list.rule:SetPoint("TOPRIGHT",-15,-37)
    root.list.scroll = CreateFrame("ScrollFrame",nil,root.list)
    root.list.scroll:SetPoint("TOPLEFT",14,-44); root.list.scroll:SetPoint("BOTTOMRIGHT",-16,14)
    root.list.scroll:EnableMouseWheel(true)
    root.list.scroll:SetScript("OnMouseWheel",function(self,delta)
        self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*34)))
    end)
    root.list.child = CreateFrame("Frame",nil,root.list.scroll)
    root.list.child:SetSize(100,1); root.list.scroll:SetScrollChild(root.list.child)
    root.rows={}
    root.dossier = CreateFrame("Frame",nil,root,"BackdropTemplate")
    root.dossier:SetBackdrop({bgFile=WHITE,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=13,insets={left=3,right=3,top=3,bottom=3}})
    root.dossier:SetBackdropColor(.105,.071,.045,.98)
    root.dossier:SetBackdropBorderColor(.59,.44,.17,1)
    if C.OrnateCorners then C:OrnateCorners(root.dossier) end
    root.dossier.art = root.dossier:CreateTexture(nil,"ARTWORK")
    root.dossier.art:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Quests")
    root.dossier.art:SetPoint("BOTTOMRIGHT",-8,7); root.dossier.art:SetSize(190,190)
    root.dossier.art:SetAlpha(.1)
    root.dossier.icon = root.dossier:CreateTexture(nil,"ARTWORK")
    root.dossier.icon:SetSize(40,40); root.dossier.icon:SetPoint("TOPRIGHT",-17,-17)
    root.dossier.icon:SetTexCoord(.07,.93,.07,.93)
    root.dossier.caption = font(root.dossier,10,{1,.82,.1}); root.dossier.caption:SetPoint("TOPLEFT",18,-15)
    root.dossier.title = font(root.dossier,21,{.96,.91,.78}); root.dossier.title:SetPoint("TOPLEFT",18,-43)
    root.dossier.meta = font(root.dossier,11,{.72,.65,.52}); root.dossier.meta:SetPoint("TOPLEFT",19,-82)
    root.dossier.rule = root.dossier:CreateTexture(nil,"ARTWORK"); root.dossier.rule:SetTexture(WHITE)
    root.dossier.rule:SetVertexColor(.57,.39,.15,.85); root.dossier.rule:SetHeight(1)
    root.dossier.rule:SetPoint("TOPLEFT",18,-111); root.dossier.rule:SetPoint("TOPRIGHT",-18,-111)
    root.dossier.status = font(root.dossier,12,{1,.82,.1}); root.dossier.status:SetPoint("TOPLEFT",19,-129)
    root.dossier.textScroll = CreateFrame("ScrollFrame",nil,root.dossier)
    root.dossier.textScroll:SetPoint("TOPLEFT",19,-164)
    root.dossier.textScroll:SetPoint("BOTTOMRIGHT",-20,60)
    root.dossier.textScroll:EnableMouseWheel(true)
    root.dossier.textScroll:SetScript("OnMouseWheel",function(self,delta)
        self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*30)))
    end)
    root.dossier.textChild = CreateFrame("Frame",nil,root.dossier.textScroll)
    root.dossier.textChild:SetSize(100,1); root.dossier.textScroll:SetScrollChild(root.dossier.textChild)
    root.dossier.info = font(root.dossier.textChild,13,{.84,.77,.63})
    root.dossier.info:SetPoint("TOPLEFT",0,0); root.dossier.info:SetJustifyV("TOP")
    root.dossier.action = makeButton(root.dossier,220)
    root.dossier.action:SetPoint("BOTTOMLEFT",18,17); root.dossier.action:SetPoint("BOTTOMRIGHT",-18,17)
    root.dossier.action:SetHeight(28)
    root.dossier.action:SetScript("OnClick",function(self)
        if self.questID then showQuestOnMap(self.questID)
        elseif self.itemID then openItemLink(self) end
    end)
    root.dossier.action:SetScript("OnEnter",function(self)
        if self.itemID then showItemTooltip(self) end
    end)
    root.dossier.action:SetScript("OnLeave",function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return root
end
local function ensureDetailRow(root,index)
    local row = root.rows[index]
    if row then return row end
    row = CreateFrame("Button",nil,root.list.child,"BackdropTemplate")
    row:SetHeight(52); row:SetBackdrop({bgFile=WHITE})
    row.number = font(row,13,{1,.82,.1}); row.number:SetPoint("TOPLEFT",8,-9)
    row.title = font(row,12,{.96,.91,.78}); row.title:SetPoint("TOPLEFT",42,-8)
    row.status = font(row,10,{.72,.65,.52}); row.status:SetPoint("TOPLEFT",42,-29)
    row.rule = row:CreateTexture(nil,"ARTWORK"); row.rule:SetTexture(WHITE)
    row.rule:SetVertexColor(.48,.32,.12,.7); row.rule:SetHeight(1)
    row.rule:SetPoint("BOTTOMLEFT",40,1); row.rule:SetPoint("BOTTOMRIGHT",-5,1)
    row:SetScript("OnClick",function(self)
        ui.selectedEntry=self.entryKey
        C:ShowAttunements(root:GetParent(),root:GetWidth()+8)
    end)
    row:SetScript("OnEnter",function(self)
        self:SetBackdropColor(.27,.17,.06,.35)
        if self.itemID then showItemTooltip(self) end
    end)
    row:SetScript("OnLeave",function(self)
        self:SetBackdropColor(self.isSelected and .24 or 0,self.isSelected and .15 or 0,
            self.isSelected and .055 or 0,self.isSelected and .42 or 0)
        if GameTooltip then GameTooltip:Hide() end
    end)
    root.rows[index]=row
    return row
end
local function questNarrative(id)
    local locale=GetLocale and GetLocale() or "enUS"
    local cache=C.char and C.char.attunementQuestTexts
    local saved=cache and cache[locale] and cache[locale][id]
    local story,assignment
    if C_QuestLog and C_QuestLog.GetQuestDescription then
        local ok,description=pcall(C_QuestLog.GetQuestDescription,id)
        if ok and type(description)=="string" and description~="" then story=description end
    end
    if C.API and C.API.QuestText then
        local ok,description,objectives=pcall(C.API.QuestText,id)
        if ok then
            if not story and type(description)=="string" and description~="" then story=description end
            if type(objectives)=="string" and objectives~="" then assignment=objectives end
        end
    end
    if (story or assignment) and C.char then
        C.char.attunementQuestTexts=C.char.attunementQuestTexts or {}
        local localized=C.char.attunementQuestTexts
        localized[locale]=localized[locale] or {}
        local record=localized[locale][id] or {}
        record.story=story or record.story
        record.assignment=assignment or record.assignment
        localized[locale][id]=record
    end
    return story or (saved and saved.story),assignment or (saved and saved.assignment)
end
local trackedQuests={}
for _,route in pairs(routes) do
    for _,id in ipairs(route.quests or {}) do trackedQuests[id]=true end
    for _,id in ipairs(route.anyQuest or {}) do trackedQuests[id]=true end
    for _,factionQuests in pairs(route.factionQuests or {}) do
        for _,id in ipairs(factionQuests) do trackedQuests[id]=true end
    end
end
local questTextCapture=CreateFrame("Frame")
local lastQuestTextCapture=0
questTextCapture:RegisterEvent("QUEST_LOG_UPDATE")
questTextCapture:RegisterEvent("PLAYER_ENTERING_WORLD")
questTextCapture:RegisterEvent("QUEST_DETAIL")
questTextCapture:SetScript("OnEvent",function(_,event)
    if not C.char or not C.API or not C.API.ActiveQuests then return end
    if event=="QUEST_DETAIL" then
        local id=GetQuestID and GetQuestID()
        if not (id and trackedQuests[id]) then return end
        local story=GetQuestText and GetQuestText()
        local assignment=GetObjectiveText and GetObjectiveText()
        if (type(story)=="string" and story~="") or
            (type(assignment)=="string" and assignment~="") then
            local locale=GetLocale and GetLocale() or "enUS"
            C.char.attunementQuestTexts=C.char.attunementQuestTexts or {}
            local localized=C.char.attunementQuestTexts
            localized[locale]=localized[locale] or {}
            local record=localized[locale][id] or {}
            if type(story)=="string" and story~="" then record.story=story end
            if type(assignment)=="string" and assignment~="" then record.assignment=assignment end
            localized[locale][id]=record
        end
        return
    end
    local now=GetTime and GetTime() or 0
    if now>0 and now-lastQuestTextCapture<2 then return end
    lastQuestTextCapture=now
    local active=C.API.ActiveQuests()
    if type(active)~="table" then return end
    local locale=GetLocale and GetLocale() or "enUS"
    local cached=C.char.attunementQuestTexts and C.char.attunementQuestTexts[locale]
    for key in pairs(active) do
        local id=tonumber(key)
        local record=cached and cached[id]
        if id and trackedQuests[id] and not (record and record.story and record.assignment) then
            questNarrative(id)
        end
    end
end)
local function showDetail(parent,width,name)
    if not ui.detailRoot or ui.parent~=parent then ui.detailRoot=buildDetail(parent) end
    local root=ui.detailRoot
    local route=routes[name]
    root:Show(); root:SetWidth(width-8)
    root.hero:SetSize(width-32,112)
    if C.SetHeroMotif then C:SetHeroMotif(root.hero,"Dungeons",.25) end
    root.hero.kicker:SetText("CHRONICLE  /  "..C:L("attunements"))
    root.hero.title:SetText(C:LocalizeInstanceName(name))
    root.hero.note:SetWidth(width-205); root.hero.note:SetText(T(4))
    root.back.label:SetText(E("back"))
    local hasQuests=route and (#routeQuests(route)+#(route.anyQuest or {})>0)
    root.path:SetText(route and (T(5).."  /  "..E(hasQuests and "questPath" or "keyPath")..
        (route.anyQuest and ("  •  "..D("variant")) or "")) or T(6))
    local _,nextStep=linesFor(route)
    root.next:SetText(T(15)..": "..nextStep)
    local entries={}
    if route then
        for _,id in ipairs(routeQuests(route)) do entries[#entries+1]={quest=id,key="q:"..id} end
        for _,id in ipairs(route.anyQuest or {}) do entries[#entries+1]={quest=id,key="q:"..id} end
        for _,id in ipairs(routeItems(route)) do entries[#entries+1]={item=id,key="i:"..id} end
    end
    if not ui.selectedEntry or not (function()
        for _,entry in ipairs(entries) do if entry.key==ui.selectedEntry then return true end end
    end)() then ui.selectedEntry=entries[1] and entries[1].key or nil end
    local panelWidth=width-34
    local gap=12
    local listWidth=math.floor((panelWidth-gap)*.49)
    local dossierWidth=panelWidth-listWidth-gap
    local viewport=parent:GetParent()
    local panelHeight=math.max(310,math.min(520,(viewport and viewport:GetHeight() or 650)-240))
    root.list:ClearAllPoints(); root.list:SetPoint("TOPLEFT",17,-214); root.list:SetSize(listWidth,panelHeight)
    root.dossier:ClearAllPoints(); root.dossier:SetPoint("TOPLEFT",17+listWidth+gap,-214)
    root.dossier:SetSize(dossierWidth,panelHeight)
    root.divider:ClearAllPoints(); root.divider:SetPoint("TOPLEFT",root, "TOPLEFT",17+listWidth+math.floor(gap/2),-214)
    root.divider:SetHeight(panelHeight)
    root.list.heading:SetText(E(hasQuests and "questPath" or "keyPath"))
    root.list.count:SetText(#entries.." "..(hasQuests and C:L("quests") or C:L("item")))
    root.list.child:SetWidth(listWidth-32)
    root.list.child:SetHeight(math.max(1,#entries*53+4))
    local selectedEntry
    for index,entry in ipairs(entries) do
        local row=ensureDetailRow(root,index)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(index-1)*53)
        row:SetWidth(listWidth-32)
        row.number:SetText(string.format("%02d",index))
        row.title:SetWidth(listWidth-105); row.status:SetWidth(listWidth-105)
        row.entryKey=entry.key; row.itemID=entry.item
        row.isSelected=entry.key==ui.selectedEntry
        local state=entry.quest and questState(entry.quest) or itemState(entry.item)
        row.title:SetText(entry.quest and titleForQuest(entry.quest) or titleForItem(entry.item))
        row.status:SetText(entry.quest and (T(7).." #"..entry.quest.."  •  "..
            (state=="done" and T(9) or state=="active" and T(10) or state=="incomplete" and T(11) or T(14))) or
            (D("key").."  •  "..(state=="owned" and T(12) or state=="absent" and T(13) or T(14))))
        if entry.quest and state=="done" then
            row.status:SetTextColor(.45,.82,.48)
        elseif entry.quest and (state=="active" or state=="incomplete") then
            row.status:SetTextColor(.93,.48,.39)
        else
            row.status:SetTextColor(.76,.69,.55)
        end
        row:SetBackdropColor(row.isSelected and .24 or 0,row.isSelected and .15 or 0,
            row.isSelected and .055 or 0,row.isSelected and .42 or 0)
        if row.isSelected then selectedEntry=entry end
        row:Show()
    end
    for index=#entries+1,#root.rows do root.rows[index]:Hide() end
    local dossier=root.dossier
    dossier.caption:SetText("CHRONICLE  /  "..(selectedEntry and selectedEntry.quest and T(7) or T(8)))
    dossier.title:SetWidth(dossierWidth-95); dossier.meta:SetWidth(dossierWidth-40)
    dossier.info:SetWidth(dossierWidth-50)
    dossier.textChild:SetWidth(dossierWidth-50)
    dossier.action.questID=nil; dossier.action.itemID=nil
    if selectedEntry and selectedEntry.quest then
        local id=selectedEntry.quest
        local state=questState(id)
        local title=titleForQuest(id)
        dossier.title:SetFont(C:FontPath(),#title>29 and 17 or 21)
        dossier.title:SetText(title)
        dossier.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
        dossier.meta:SetText(T(7).." #"..id)
        dossier.status:SetText(state=="done" and T(9) or state=="active" and T(10) or state=="incomplete" and T(11) or T(14))
        dossier.status:SetTextColor(state=="done" and .45 or (state=="unknown" and 1 or .93),
            state=="done" and .82 or (state=="unknown" and .82 or .48),
            state=="done" and .48 or (state=="unknown" and .1 or .39))
        local objective,isLive=objectiveForQuest(id)
        local story,assignment=questNarrative(id)
        local parts={"|cffffd100"..(isLive and O("live") or O("reference")).."|r\n"..objective}
        if story and story~=objective then parts[#parts+1]="|cffffd100"..O("story").."|r\n"..story end
        if assignment and assignment~=objective and assignment~=story then
            parts[#parts+1]="|cffffd100"..O("assignment").."|r\n"..assignment
        end
        local text=table.concat(parts,"\n\n")
        dossier.info:SetText(text)
        dossier.action.questID=id
        dossier.action.label:SetText((questGivers[id] and E("giver") or D("map")))
        dossier.action:Show()
    elseif selectedEntry and selectedEntry.item then
        local id=selectedEntry.item
        local icon
        if C_Item and C_Item.GetItemIconByID then
            local ok,value=pcall(C_Item.GetItemIconByID,id)
            if ok then icon=value end
        end
        dossier.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local title=titleForItem(id)
        dossier.title:SetFont(C:FontPath(),#title>29 and 17 or 21)
        dossier.title:SetText(title)
        dossier.meta:SetText(T(8).." #"..id)
        local state=itemState(id)
        dossier.status:SetText(state=="owned" and T(12) or state=="absent" and T(13) or T(14))
        dossier.status:SetTextColor(1,.82,.1)
        dossier.info:SetText(D("key"))
        dossier.action.itemID=id; dossier.action.label:SetText(titleForItem(id))
        dossier.action:Show()
    else
        dossier.title:SetText(T(6)); dossier.meta:SetText(""); dossier.status:SetText("")
        dossier.info:SetText(O("missing")); dossier.action:Hide()
    end
    dossier.textChild:SetHeight(math.max(1,(dossier.info:GetStringHeight() or 1)+8))
    dossier.textScroll:SetVerticalScroll(0)
    root:SetHeight(214+panelHeight+28)
    parent:SetHeight(root:GetHeight()+12)
end
local function build(parent)
    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", 4, 0)
    root.hero = makeCard(root); root.hero:SetPoint("TOPLEFT",12,-12)
    root.kicker = font(root.hero,10,{1,.81,.12}); root.kicker:SetPoint("TOPLEFT",15,-11)
    root.title = font(root.hero,22,{1,.86,.61}); root.title:SetPoint("TOPLEFT",15,-32)
    root.note = font(root.hero,11,{.76,.69,.55}); root.note:SetPoint("TOPLEFT",15,-69); root.note:SetJustifyV("TOP")
    root.count = font(root.hero,11,{1,.82,.1}); root.count:SetPoint("BOTTOMLEFT",15,13)
    root.tabs = {}
    for n = 1, 2 do
        local b = CreateFrame("Button", nil, root, "BackdropTemplate")
        b:SetHeight(25); b:SetPoint("TOPLEFT", 12 + (n - 1) * 190, -158); b:SetWidth(180)
        b.label = font(b, 12, {1, .81, .13}); b.label:SetPoint("CENTER")
        C:StyleChronicleButton(b)
        local kind = n == 1 and "dungeons" or "raids"
        b:SetScript("OnClick", function()
            ui.kind = kind; ui.selected = nil; C:ShowAttunements(parent, root:GetWidth())
        end)
        root.tabs[n] = b
    end
    return root
end
local function ensureCover(root,index)
    local card = ui.rows[index]
    if card then return card end
    card = CreateFrame("Button",nil,root,"BackdropTemplate")
    card:SetBackdrop({bgFile=WHITE,edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    card:SetBackdropColor(.07,.05,.03,1)
    card:SetBackdropBorderColor(.5,.36,.15,1)
    card.art = card:CreateTexture(nil,"ARTWORK")
    card.art:SetPoint("TOPLEFT",4,-4); card.art:SetPoint("BOTTOMRIGHT",-4,4)
    card.art:SetTexCoord(.05,.95,.26,.74)
    card.placeholder = card:CreateTexture(nil,"ARTWORK")
    card.placeholder:SetTexture("Interface\\AddOns\\Chronicle\\Motif_Dungeons")
    card.placeholder:SetSize(88,88); card.placeholder:SetPoint("RIGHT",-20,0); card.placeholder:SetAlpha(.18)
    card.shade = card:CreateTexture(nil,"ARTWORK")
    card.shade:SetTexture("Interface\\AddOns\\Chronicle\\CardBottomFade")
    card.shade:SetPoint("BOTTOMLEFT",4,4); card.shade:SetPoint("BOTTOMRIGHT",-4,4); card.shade:SetHeight(80)
    card.title = font(card,17,{1,.82,.1})
    card.title:SetPoint("BOTTOMLEFT",15,27)
    card.title:SetShadowColor(0,0,0,1); card.title:SetShadowOffset(1,-1)
    card.meta = font(card,11,{.96,.91,.78})
    card.meta:SetPoint("BOTTOMLEFT",16,10)
    card.meta:SetShadowColor(0,0,0,1); card.meta:SetShadowOffset(1,-1)
    card.level = font(card,11,{1,.82,.1})
    card.level:SetPoint("TOPRIGHT",-12,-10); card.level:SetJustifyH("RIGHT")
    card.level:SetShadowColor(0,0,0,1); card.level:SetShadowOffset(1,-1)
    card:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(1,.76,.23,1) end)
    card:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(.5,.36,.15,1) end)
    card:SetScript("OnClick",function(self)
        ui.selected = self.instanceName; ui.detailName = self.instanceName
        local content = root:GetParent()
        C:ShowAttunements(content,root:GetWidth()+8)
        if content:GetParent() and content:GetParent().SetVerticalScroll then content:GetParent():SetVerticalScroll(0) end
    end)
    ui.rows[index]=card
    return card
end
function C:HideAttunements()
    if ui.root then ui.root:Hide() end
    if ui.detailRoot then ui.detailRoot:Hide() end
end
function C:ShowAttunements(parent, width)
    if not ui.root or ui.parent ~= parent then ui.root = build(parent); ui.parent = parent; ui.rows = {} end
    ui.width = width
    local root = ui.root
    if ui.detailName then
        root:Hide()
        showDetail(parent,width,ui.detailName)
        return
    end
    if ui.detailRoot then ui.detailRoot:Hide() end
    root:Show(); root:SetWidth(width - 8)
    root.hero:SetSize(width-32,132)
    if C.SetHeroMotif then C:SetHeroMotif(root.hero,"Dungeons",.35) end
    root.kicker:SetText("CHRONICLE  /  " .. C:L("attunements"))
    root.title:SetText(C:L("attunements"))
    root.note:SetWidth(width - 215); root.note:SetText((ui.kind == "dungeons" and E("gates") or T(3)) .. "\n" .. T(4))
    for n, tab in ipairs(root.tabs) do
        tab.label:SetText(T(n))
        C:StyleChronicleButton(tab, ui.kind == (n == 1 and "dungeons" or "raids"))
    end
    local catalogOrder = ui.kind == "dungeons" and C.dungeonKnowledgeOrder or C.raidKnowledgeOrder
    local order = {}
    for _,name in ipairs(catalogOrder or {}) do
        if ui.kind == "raids" or dungeonGateRoutes[name] then order[#order+1]=name end
    end
    root.count:SetText(#order .. " " .. T(ui.kind == "dungeons" and 1 or 2))
    local catalog = ui.kind == "dungeons" and C.dungeonKnowledge or C.raidKnowledge
    local gap = 12
    local cardWidth = math.floor((width-30-gap)/2)
    for i, name in ipairs(order) do
        local card = ensureCover(root,i)
        local data = catalog and catalog[name] or {}
        local col,row = (i-1)%2, math.floor((i-1)/2)
        card:ClearAllPoints(); card:SetPoint("TOPLEFT",12+col*(cardWidth+gap),-199-row*96)
        card:SetSize(cardWidth,88); card.instanceName=name
        local art = C:GetPackagedInstanceArt(data.artName or name) or data.icon
        if art == "Interface\\AddOns\\Chronicle\\Motif_Dungeons" then art=nil end
        card.art:SetShown(art~=nil)
        if art then card.art:SetTexture(art) end
        card.placeholder:SetShown(art==nil)
        card.title:SetText(C:LocalizeInstanceName(name)); card.title:SetWidth(cardWidth-35)
        local route = routes[name]
        local questCount = #routeQuests(route)+#(route and route.anyQuest or {})
        local itemCount = #routeItems(route)
        card.meta:SetText(route and (questCount.." "..C:L("quests").."  ·  "..itemCount.." "..C:L("item")) or T(14))
        card.level:SetText(data.level and (C:L("level").." "..tostring(data.level)) or "")
        card:Show()
    end
    for i = #order + 1, #ui.rows do ui.rows[i]:Hide() end
    root:SetHeight(199+math.ceil(#order/2)*96+8)
    parent:SetHeight(root:GetHeight() + 12)
end
