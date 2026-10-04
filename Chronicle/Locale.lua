local C = _G.Chronicle

-- The saved choice overrides the game client language. Unsupported client locales
-- use German until the player explicitly chooses another language.
C.languages = {
    { code = "enUS", name = "English" },
    { code = "deDE", name = "Deutsch" },
    { code = "frFR", name = "Français" },
    { code = "esES", name = "Español" },
    { code = "itIT", name = "Italiano" },
    { code = "ptBR", name = "Português" },
    { code = "ruRU", name = "Русский" },
}

-- Columns: English, German, French, Spanish, Italian, Portuguese, Russian.
-- Keep these as UTF-8: WoW's FontStrings accept the same encoding.
local rows = {
    language = {"Language", "Sprache", "Langue", "Idioma", "Lingua", "Idioma", "Язык"},
    journey = {"JOURNEY", "REISE", "VOYAGE", "VIAJE", "VIAGGIO", "JORNADA", "ПУТЕШЕСТВИЕ"},
    knowledge = {"KNOWLEDGE", "WISSEN", "SAVOIR", "CONOCIMIENTO", "CONOSCENZA", "CONHECIMENTO", "ЗНАНИЯ"},
    collection = {"COLLECTION", "SAMMLUNG", "COLLECTION", "COLECCIÓN", "COLLEZIONE", "COLEÇÃO", "КОЛЛЕКЦИЯ"},
    characterGroup = {"CHARACTER", "CHARAKTER", "PERSONNAGE", "PERSONAJE", "PERSONAGGIO", "PERSONAGEM", "ПЕРСОНАЖ"},
    overview = {"Where was I?", "Wo war ich?", "Où en étais-je ?", "¿Dónde estaba?", "Dov'ero rimasto?", "Onde eu estava?", "На чём я остановился?"},
    goals = {"Goals", "Ziele", "Objectifs", "Objetivos", "Obiettivi", "Objetivos", "Цели"},
    timeline = {"Adventures", "Abenteuer", "Aventures", "Aventuras", "Avventure", "Aventuras", "Приключения"},
    quests = {"Quests", "Quests", "Quêtes", "Misiones", "Missioni", "Missões", "Задания"},
    zones = {"Zones", "Gebiete", "Zones", "Zonas", "Zone", "Zonas", "Зоны"},
    npcs = {"NPCs & Merchants", "NPC & Händler", "PNJ et marchands", "PNJ y comerciantes", "PNG e mercanti", "PNJs e comerciantes", "НПС и торговцы"},
    dungeons = {"Dungeons & Bosses", "Dungeons & Bosse", "Donjons et boss", "Mazmorras y jefes", "Spedizioni e boss", "Masmorras e chefes", "Подземелья и боссы"},
    gathering = {"Gathering", "Sammeln", "Récolte", "Recolección", "Raccolta", "Coleta", "Собирательство"},
    training = {"Trainers", "Trainer", "Maîtres", "Instructores", "Istruttori", "Instrutores", "Учителя"},
    teachers = {"Trainer locations", "Lehrerorte", "Emplacements des maîtres", "Ubicación de instructores", "Sedi degli istruttori", "Locais dos instrutores", "Местонахождение учителей"},
    weapons = {"Weapon skills", "Waffenfertigkeiten", "Compétences d'armes", "Habilidades con armas", "Competenze con le armi", "Perícias com armas", "Навыки владения оружием"},
    dungeonknowledge = {"Dungeon guide", "Instanzwissen", "Guide des donjons", "Guía de mazmorras", "Guida alle spedizioni", "Guia de masmorras", "Справочник подземелий"},
    raidknowledge = {"Raid guide", "Raidwissen", "Guide des raids", "Guía de bandas", "Guida alle incursioni", "Guia de raides", "Справочник рейдов"},
    attunements = {"Access paths", "Zugangswege", "Voies d'accès", "Vías de acceso", "Percorsi di accesso", "Caminhos de acesso", "Пути доступа"},
    loot = {"Loot & Rares", "Beute & Rares", "Butin et monstres rares", "Botín y enemigos raros", "Bottino e nemici rari", "Saque e inimigos raros", "Добыча и редкие враги"},
    professions = {"Professions & Recipes", "Berufe & Rezepte", "Métiers et recettes", "Profesiones y recetas", "Professioni e ricette", "Profissões e receitas", "Профессии и рецепты"},
    alts = {"Characters", "Charaktere", "Personnages", "Personajes", "Personaggi", "Personagens", "Персонажи"},
    inventory = {"Inventory & Bank", "Inventar & Bank", "Inventaire et banque", "Inventario y banco", "Inventario e banca", "Inventário e banco", "Сумки и банк"},
    economy = {"Gold & Economy", "Gold & Wirtschaft", "Or et économie", "Oro y economía", "Oro ed economia", "Ouro e economia", "Золото и экономика"},
    deaths = {"Death Journal", "Todestagebuch", "Journal des morts", "Diario de muertes", "Diario delle morti", "Diário de mortes", "Дневник смертей"},
    notes = {"Notes", "Notizen", "Notes", "Notas", "Note", "Notas", "Заметки"},
    stats = {"Statistics", "Statistiken", "Statistiques", "Estadísticas", "Statistiche", "Estatísticas", "Статистика"},
    search = {"Search Chronicle ...", "Chronicle durchsuchen ...", "Rechercher dans Chronicle ...", "Buscar en Chronicle ...", "Cerca in Chronicle ...", "Pesquisar no Chronicle ...", "Поиск по Chronicle ..."},
    subtitle = {"YOUR JOURNEY. FOREVER.", "DEINE REISE. FÜR IMMER.", "VOTRE VOYAGE. POUR TOUJOURS.", "TU VIAJE. PARA SIEMPRE.", "IL TUO VIAGGIO. PER SEMPRE.", "SUA JORNADA. PARA SEMPRE.", "ВАШ ПУТЬ. НАВСЕГДА."},
    back = {"Back", "Zurück", "Retour", "Volver", "Indietro", "Voltar", "Назад"},
    cancel = {"Cancel", "Abbruch", "Annuler", "Cancelar", "Annulla", "Cancelar", "Отмена"},
    add = {"Add", "Hinzufügen", "Ajouter", "Añadir", "Aggiungi", "Adicionar", "Добавить"},
    save = {"Save", "Speichern", "Enregistrer", "Guardar", "Salva", "Salvar", "Сохранить"},
    change = {"Edit", "Ändern", "Modifier", "Editar", "Modifica", "Editar", "Изменить"},
    showZeros = {"Show zero values", "Nullwerte anzeigen", "Afficher les valeurs nulles", "Mostrar valores cero", "Mostra valori zero", "Mostrar valores zero", "Показать нулевые значения"},
    hideZeros = {"Hide zero values", "Nullwerte ausblenden", "Masquer les valeurs nulles", "Ocultar valores cero", "Nascondi valori zero", "Ocultar valores zero", "Скрыть нулевые значения"},
    openSection = {"Open Chronicle section", "Chronicle-Rubrik öffnen", "Ouvrir la section Chronicle", "Abrir sección de Chronicle", "Apri sezione Chronicle", "Abrir seção do Chronicle", "Открыть раздел Chronicle"},
    noResults = {"No results.", "Keine Treffer.", "Aucun résultat.", "Sin resultados.", "Nessun risultato.", "Nenhum resultado.", "Ничего не найдено."},
    dungeonBossLoot = {"Bosses & loot", "Bosse & Beute", "Boss et butin", "Jefes y botín", "Boss e bottino", "Chefes e saque", "Боссы и добыча"},
    dungeonQuests = {"Dungeon quests", "Dungeon-Quests", "Quêtes du donjon", "Misiones de mazmorra", "Missioni della spedizione", "Missões da masmorra", "Задания подземелья"},
    allLoot = {"All loot", "Alle Fundstücke", "Tout le butin", "Todo el botín", "Tutto il bottino", "Todo o saque", "Вся добыча"},
    dungeonMap = {"Dungeon map", "Instanzkarte", "Carte du donjon", "Mapa de mazmorra", "Mappa della spedizione", "Mapa da masmorra", "Карта подземелья"},
    mapOverview = {"Overview", "Übersicht", "Vue d’ensemble", "Vista general", "Panoramica", "Visão geral", "Обзор"},
    mapFloor = {"Floor", "Ebene", "Étage", "Planta", "Piano", "Andar", "Уровень"},
    mapSchematic = {"Boss overview · schematic, not a floor plan", "Bossübersicht · schematisch, kein Grundriss", "Vue des boss · schéma, pas un plan", "Vista de jefes · esquema, no plano", "Panoramica dei boss · schema, non pianta", "Visão dos chefes · esquema, não planta", "Обзор боссов · схема, не план"},
    encounters = {"ENCOUNTERS", "BEGEGNUNGEN", "RENCONTRES", "ENCUENTROS", "INCONTRI", "ENCONTROS", "ПРОТИВНИКИ"},
    lootCatalog = {"LOOT CATALOG", "BEUTEKATALOG", "CATALOGUE DU BUTIN", "CATÁLOGO DE BOTÍN", "CATALOGO DEL BOTTINO", "CATÁLOGO DE SAQUE", "КАТАЛОГ ДОБЫЧИ"},
    backOverview = {"<  BACK TO OVERVIEW", "<  ZURÜCK ZUR ÜBERSICHT", "<  RETOUR À L'APERÇU", "<  VOLVER AL RESUMEN", "<  TORNA ALLA PANORAMICA", "<  VOLTAR À VISÃO GERAL", "<  К ОБЗОРУ"},
    level = {"LEVEL", "STUFE", "NIVEAU", "NIVEL", "LIVELLO", "NÍVEL", "УРОВЕНЬ"},
    bosses = {"BOSSES", "BOSSE", "BOSS", "JEFES", "BOSS", "CHEFES", "БОССЫ"},
    questCount = {"QUESTS", "QUESTS", "QUÊTES", "MISIONES", "MISSIONI", "MISSÕES", "ЗАДАНИЯ"},
    raidsCatalog = {" RAIDS IN CATALOG", " RAIDS IM KATALOG", " RAIDS AU CATALOGUE", " BANDAS EN EL CATÁLOGO", " INCURSIONI NEL CATALOGO", " RAIDES NO CATÁLOGO", " РЕЙДОВ В КАТАЛОГЕ"},
    dungeonsCatalog = {" DUNGEONS IN CATALOG", " INSTANZEN IM KATALOG", " DONJONS AU CATALOGUE", " MAZMORRAS EN EL CATÁLOGO", " SPEDIZIONI NEL CATALOGO", " MASMORRAS NO CATÁLOGO", " ПОДЗЕМЕЛИЙ В КАТАЛОГЕ"},
    unavailable = {"Not yet recorded", "Noch nicht erfasst", "Pas encore répertorié", "Aún no registrado", "Non ancora registrato", "Ainda não registrado", "Пока не записано"},
    hallsOfJourney = {"Halls of your journey", "Die Hallen deiner Reise", "Les salles de votre voyage", "Las salas de tu viaje", "Le sale del tuo viaggio", "Os salões da sua jornada", "Залы вашего путешествия"},
    raidsOfJourney = {"Raids of your journey", "Die Raids deiner Reise", "Les raids de votre voyage", "Las bandas de tu viaje", "Le incursioni del tuo viaggio", "Os raides da sua jornada", "Рейды вашего путешествия"},
    noFactionQuests = {"No quests for your faction", "Keine Quests für deine Fraktion", "Aucune quête pour votre faction", "Sin misiones para tu facción", "Nessuna missione per la tua fazione", "Nenhuma missão para sua facção", "Нет заданий для вашей фракции"},
    questsUnrecorded = {"Quests not yet recorded", "Quests noch nicht erfasst", "Quêtes non répertoriées", "Misiones aún no registradas", "Missioni non ancora registrate", "Missões ainda não registradas", "Задания ещё не записаны"},
    encountersUnrecorded = {"Preview · encounters not yet recorded", "Vorschau · Begegnungen noch nicht erfasst", "Aperçu · rencontres non répertoriées", "Vista previa · encuentros aún no registrados", "Anteprima · incontri non ancora registrati", "Prévia · encontros ainda não registrados", "Предпросмотр · противники ещё не записаны"},
    lootPieces = {" loot items", " Beutestücke", " objets de butin", " objetos de botín", " oggetti di bottino", " itens de saque", " предметов добычи"},
    noEntries = {"No entries", "Keine Einträge", "Aucune entrée", "Sin entradas", "Nessuna voce", "Nenhuma entrada", "Нет записей"},
    bossLoot = {"Loot from this boss", "Beute dieses Bosses", "Butin de ce boss", "Botín de este jefe", "Bottino di questo boss", "Saque deste chefe", "Добыча с этого босса"},
    rewards = {"Rewards", "Belohnungen", "Récompenses", "Recompensas", "Ricompense", "Recompensas", "Награды"},
    chooseItem = {"Choose an item", "Einen Gegenstand auswählen", "Choisir un objet", "Elegir un objeto", "Scegli un oggetto", "Escolher um item", "Выбрать предмет"},
    items = {"Items", "Gegenstände", "Objets", "Objetos", "Oggetti", "Itens", "Предметы"},
    item = {"Item", "Gegenstand", "Objet", "Objeto", "Oggetto", "Item", "Предмет"},
    rareEnemy = {"RARE ENEMY", "SELTENER GEGNER", "ENNEMI RARE", "ENEMIGO POCO COMÚN", "NEMICO RARO", "INIMIGO RARO", "РЕДКИЙ ВРАГ"},
    questGiver = {"QUEST GIVER: ", "QUESTGEBER: ", "DONNEUR DE QUÊTE : ", "OTORGA LA MISIÓN: ", "ASSEGNA LA MISSIONE: ", "CONCEDENTE DA MISSÃO: ", "ЗАДАНИЕ ВЫДАЁТ: "},
    turnIn = {"TURN IN: ", "ABGABE: ", "REMISE : ", "ENTREGA: ", "CONSEGNA: ", "ENTREGA: ", "СДАТЬ: "},
    hint = {"NOTE: ", "HINWEIS: ", "REMARQUE : ", "NOTA: ", "NOTA: ", "NOTA: ", "ПРИМЕЧАНИЕ: "},
    notRecorded = {"not recorded", "nicht erfasst", "non répertorié", "no registrado", "non registrato", "não registrado", "не записано"},
    noObjective = {"No objective recorded.", "Kein Ziel erfasst.", "Aucun objectif répertorié.", "No se ha registrado ningún objetivo.", "Nessun obiettivo registrato.", "Nenhum objetivo registrado.", "Цель не записана."},
    equipmentSlot = {"EQUIPMENT SLOT: ", "AUSRÜSTUNGSPLATZ: ", "EMPLACEMENT : ", "RANURA DE EQUIPO: ", "SLOT EQUIPAGGIAMENTO: ", "ESPAÇO DE EQUIPAMENTO: ", "ЯЧЕЙКА ЭКИПИРОВКИ: "},
    previewDetail = {"This dungeon is listed in the Forever catalog. Boss and loot data are not available yet.", "Diese Instanz ist im Forever-Katalog aufgeführt. Boss- und Beutedaten sind noch nicht verfügbar.", "Ce donjon figure dans le catalogue Forever. Les données sur les boss et le butin ne sont pas encore disponibles.", "Esta mazmorra figura en el catálogo Forever. Aún no hay datos de jefes ni botín.", "Questa spedizione è nel catalogo Forever. I dati sui boss e sul bottino non sono ancora disponibili.", "Esta masmorra está no catálogo Forever. Os dados de chefes e saque ainda não estão disponíveis.", "Это подземелье есть в каталоге Forever. Данные о боссах и добыче пока недоступны."},
    noSelectionEntries = {"No entries recorded for this selection.", "Für diese Auswahl sind noch keine Einträge erfasst.", "Aucune entrée pour cette sélection.", "No hay entradas registradas para esta selección.", "Nessuna voce registrata per questa selezione.", "Não há registros para esta seleção.", "Для этого выбора записей пока нет."},
    experienceCatalog = {"EXPERIENCE · CATALOG", "ERFAHRUNG · KATALOG", "EXPÉRIENCE · CATALOGUE", "EXPERIENCIA · CATÁLOGO", "ESPERIENZA · CATALOGO", "EXPERIÊNCIA · CATÁLOGO", "ОПЫТ · КАТАЛОГ"},
    money = {"MONEY", "GELD", "ARGENT", "DINERO", "DENARO", "DINHEIRO", "ДЕНЬГИ"},
    reputation = {"REPUTATION", "RUF", "RÉPUTATION", "REPUTACIÓN", "REPUTAZIONE", "REPUTAÇÃO", "РЕПУТАЦИЯ"},
    xpUnit = {" XP", " EP", " EXP", " EXP", " PE", " EXP", " ОП"},
    openAddon = {"Click to open the addon.", "Klicken, um das Addon zu öffnen.", "Cliquez pour ouvrir l'addon.", "Haz clic para abrir el complemento.", "Fai clic per aprire l'addon.", "Clique para abrir o addon.", "Нажмите, чтобы открыть дополнение."},
    minimapToggle = {"Left-click to open or close Chronicle.", "Linksklick: Chronicle öffnen oder schließen.", "Clic gauche : ouvrir ou fermer Chronicle.", "Clic izquierdo: abrir o cerrar Chronicle.", "Clic sinistro: apri o chiudi Chronicle.", "Clique esquerdo: abrir ou fechar o Chronicle.", "ЛКМ: открыть или закрыть Chronicle."},
    minimapDrag = {"Drag to move the minimap button.", "Ziehen: Minimap-Button verschieben.", "Faites glisser pour déplacer le bouton de la minicarte.", "Arrastra para mover el botón del minimapa.", "Trascina per spostare il pulsante della minimappa.", "Arraste para mover o botão do minimapa.", "Перетащите кнопку у мини-карты."},
    noCharacterData = {"Character data is not available yet.", "Charakterdaten sind noch nicht verfügbar.", "Les données du personnage ne sont pas encore disponibles.", "Los datos del personaje aún no están disponibles.", "I dati del personaggio non sono ancora disponibili.", "Os dados do personagem ainda não estão disponíveis.", "Данные персонажа пока недоступны."},
    searchPrefix = {"Search: ", "Suche: ", "Recherche : ", "Búsqueda: ", "Ricerca: ", "Busca: ", "Поиск: "},
    gameLanguageNotice = {"Quest, item and creature names follow the WoW client language.",
        "Quest-, Gegenstands- und Kreaturennamen folgen der Sprache des WoW-Clients.",
        "Les noms des quêtes, objets et créatures suivent la langue du client WoW.",
        "Los nombres de misiones, objetos y criaturas siguen el idioma del cliente de WoW.",
        "I nomi di missioni, oggetti e creature seguono la lingua del client di WoW.",
        "Os nomes de missões, itens e criaturas seguem o idioma do cliente WoW.",
        "Названия заданий, предметов и существ зависят от языка клиента WoW."},
    searchEntries = {"Search entries ...", "Einträge durchsuchen ...", "Rechercher des entrées ...",
        "Buscar entradas ...", "Cerca voci ...", "Pesquisar registros ...", "Поиск записей ..."},
    gatherDescription = {"Finds, records and ranks for your gathering professions",
        "Funde, Bestleistungen und Ränge deiner Sammelberufe",
        "Découvertes, records et rangs de vos métiers de récolte",
        "Hallazgos, récords y rangos de tus profesiones de recolección",
        "Ritrovamenti, record e gradi delle professioni di raccolta",
        "Descobertas, recordes e graus das suas profissões de coleta",
        "Находки, рекорды и уровни ваших собирательных профессий"},
    trainerDescription = {"Class spells and ranks with trainer prices",
        "Klassenzauber und Ränge mit Preisen beim Trainer",
        "Sorts et rangs de classe avec les prix des maîtres",
        "Hechizos y rangos de clase con precios de instructores",
        "Incantesimi e gradi di classe con i prezzi degli istruttori",
        "Magias e graus de classe com preços dos instrutores",
        "Классовые заклинания и ранги с ценами у учителей"},
    teacherDescription = {"Trainer locations from the catalog and your visits",
        "Lehrerorte aus Katalog und deinen Besuchen",
        "Emplacements des maîtres du catalogue et de vos visites",
        "Ubicaciones de instructores del catálogo y tus visitas",
        "Sedi degli istruttori dal catalogo e dalle tue visite",
        "Locais dos instrutores do catálogo e das suas visitas",
        "Местонахождение учителей из каталога и ваших посещений"},
    weaponDescription = {"Your class's weapon types; trainer visits confirm offers and prices",
        "Waffenarten deiner Klasse; Trainerbesuche bestätigen Angebote und Preise",
        "Types d'armes de votre classe ; les visites aux maîtres confirment les offres et les prix",
        "Tipos de armas de tu clase; las visitas a instructores confirman ofertas y precios",
        "Armi della tua classe; le visite agli istruttori confermano offerte e prezzi",
        "Tipos de armas da sua classe; visitas aos instrutores confirmam ofertas e preços",
        "Виды оружия вашего класса; посещения учителей подтверждают обучение и цены"},
    deathCases = {"DEATHS", "FÄLLE", "MORTS", "MUERTES", "MORTI", "MORTES", "СМЕРТИ"},
    deathPlaces = {"PLACES", "ORTE", "LIEUX", "LUGARES", "LUOGHI", "LOCAIS", "МЕСТА"},
    combatRecords = {"COMBAT LOGS", "KAMPFPROTOKOLLE", "JOURNAUX DE COMBAT", "REGISTROS DE COMBATE",
        "REGISTRI DI COMBATTIMENTO", "REGISTROS DE COMBATE", "БОЕВЫЕ ЖУРНАЛЫ"},
    noDeathRecorded = {"No death recorded yet", "Noch kein Fall verzeichnet", "Aucune mort enregistrée",
        "Aún no hay muertes registradas", "Nessuna morte registrata", "Nenhuma morte registrada", "Смерти пока не записаны"},
    timeSuffix = {"", " UHR", "", "", "", "", ""},
    placeUnknown = {"Location not recorded", "Ort nicht erfasst", "Lieu non enregistré",
        "Lugar no registrado", "Luogo non registrato", "Local não registrado", "Место не записано"},
    deathEmptyDetail = {"Each death adds a chapter to your journey.", "Jeder Fall schreibt ein Kapitel deiner Reise.",
        "Chaque mort ajoute un chapitre à votre voyage.", "Cada muerte añade un capítulo a tu viaje.",
        "Ogni morte aggiunge un capitolo al tuo viaggio.", "Cada morte acrescenta um capítulo à sua jornada.",
        "Каждая смерть добавляет главу к вашему путешествию."},
    memorialCase = {"MEMORIAL  /  DEATH ", "GEDENKTAFEL  /  FALL ", "MÉMORIAL  /  MORT ",
        "MEMORIAL  /  MUERTE ", "MEMORIALE  /  MORTE ", "MEMORIAL  /  MORTE ", "ПАМЯТЬ  /  СМЕРТЬ "},
    environment = {"Environment", "Umgebung", "Environnement", "Entorno", "Ambiente", "Ambiente", "Окружение"},
    logNotRecorded = {"Combat log not recorded for this death", "Kampflog für diesen Fall nicht aufgezeichnet",
        "Journal de combat non enregistré pour cette mort", "Registro de combate no guardado para esta muerte",
        "Registro di combattimento non salvato per questa morte", "Registro de combate não salvo para esta morte",
        "Боевой журнал для этой смерти не записан"},
    fatalHits = {"Fatal blow and recent damage", "Tödlicher Treffer und letzte Schadensereignisse",
        "Coup fatal et derniers dégâts", "Golpe mortal y daños recientes", "Colpo fatale e danni recenti",
        "Golpe fatal e danos recentes", "Смертельный удар и последние повреждения"},
}

local indexes = { enUS = 1, enGB = 1, deDE = 2, frFR = 3, esES = 4, esMX = 4,
    itIT = 5, ptBR = 6, ptPT = 6, ruRU = 7 }

function C:FlagCode(code)
    if code == "enGB" then return "enUS" end
    if code == "esMX" then return "esES" end
    if code == "ptPT" then return "ptBR" end
    return code
end

function C:GetLanguage()
    local database = self.db or _G.ChronicleDB
    local choice = database and database.settings and database.settings.language or "auto"
    if choice ~= "auto" and indexes[choice] then return choice end
    local client = GetLocale and GetLocale() or "deDE"
    return indexes[client] and client or "deDE"
end

function C:L(key)
    local row = rows[key]
    if not row then return key end
    return row[indexes[self:GetLanguage()] or 2] or row[2]
end

-- Journal entries are stored in German for stable matching with the collectors.
-- Translate them only when displayed; never change saved event text.
local eventPrefixes = {
    {"Abenteuer fortgesetzt in ", "Adventure resumed in ", "Aventure reprise à ", "Aventura retomada en ", "Avventura ripresa a ", "Aventura retomada em ", "Приключение продолжено в "},
    {"Haendler besucht: ", "Merchant visited: ", "Marchand rencontré : ", "Mercader visitado: ", "Mercante visitato: ", "Mercador visitado: ", "Посещён торговец: "},
    {"Händler besucht: ", "Merchant visited: ", "Marchand rencontré : ", "Mercader visitado: ", "Mercante visitato: ", "Mercador visitado: ", "Посещён торговец: "},
    {"Quest angenommen: ", "Quest accepted: ", "Quête acceptée : ", "Misión aceptada: ", "Missione accettata: ", "Missão aceita: ", "Задание принято: "},
    {"Quest abgeschlossen: ", "Quest completed: ", "Quête terminée : ", "Misión completada: ", "Missione completata: ", "Missão concluída: ", "Задание выполнено: "},
    {"Gebiet entdeckt: ", "Zone discovered: ", "Zone découverte : ", "Zona descubierta: ", "Zona scoperta: ", "Área descoberta: ", "Открыта зона: "},
    {"Gestorben in ", "Died in ", "Mort à ", "Murió en ", "Morto a ", "Morreu em ", "Погиб в "},
    {"Instanz betreten: ", "Dungeon entered: ", "Donjon exploré : ", "Mazmorra visitada: ", "Spedizione visitata: ", "Masmorra visitada: ", "Посещено подземелье: "},
    {"Boss besiegt: ", "Boss defeated: ", "Boss vaincu : ", "Jefe derrotado: ", "Boss sconfitto: ", "Chefe derrotado: ", "Босс побеждён: "},
    {"Bossversuch: ", "Boss attempt: ", "Tentative contre le boss : ", "Intento contra el jefe: ", "Tentativo contro il boss: ", "Tentativa contra o chefe: ", "Попытка победить босса: "},
    {"Seltene Kreatur entdeckt: ", "Rare creature discovered: ", "Créature rare découverte : ", "Criatura rara descubierta: ", "Creatura rara scoperta: ", "Criatura rara descoberta: ", "Обнаружено редкое существо: "},
    {"Neues Ziel: ", "New goal: ", "Nouvel objectif : ", "Nuevo objetivo: ", "Nuovo obiettivo: ", "Novo objetivo: ", "Новая цель: "},
    {"Ziel erreicht: ", "Goal reached: ", "Objectif atteint : ", "Objetivo alcanzado: ", "Obiettivo raggiunto: ", "Objetivo alcançado: ", "Цель достигнута: "},
    {"Ziel reaktiviert: ", "Goal reactivated: ", "Objectif réactivé : ", "Objetivo reactivado: ", "Obiettivo riattivato: ", "Objetivo reativado: ", "Цель возобновлена: "},
    {"Notiz erstellt: ", "Note created: ", "Note créée : ", "Nota creada: ", "Nota creata: ", "Nota criada: ", "Заметка создана: "},
    {"Beruf aktualisiert: ", "Profession updated: ", "Métier mis à jour : ", "Profesión actualizada: ", "Professione aggiornata: ", "Profissão atualizada: ", "Профессия обновлена: "},
    {"Neue Rezepte erfasst: ", "New recipes recorded: ", "Nouvelles recettes enregistrées : ", "Recetas nuevas registradas: ", "Nuove ricette registrate: ", "Novas receitas registradas: ", "Новые рецепты записаны: "},
}

function C:LocalizeEventText(value)
    if type(value) ~= "string" then return value end
    local language = self:GetLanguage()
    if language == "deDE" then return value end
    local eventColumns = {enUS = 2, enGB = 2, frFR = 3, esES = 4, esMX = 4,
        itIT = 5, ptBR = 6, ptPT = 6, ruRU = 7}
    local column = eventColumns[language] or 2
    if value == "Abenteuer fortgesetzt" then
        return ({"Abenteuer fortgesetzt", "Adventure resumed", "Aventure reprise", "Aventura retomada", "Avventura ripresa", "Aventura retomada", "Приключение продолжено"})[column]
    end
    for _, row in ipairs(eventPrefixes) do
        if value:sub(1, #row[1]) == row[1] then
            return row[column] .. value:sub(#row[1] + 1)
        end
    end
    local level = value:match("^Stufe (%d+) erreicht$")
    if level then
        local formats = {"Stufe %s erreicht", "Level %s reached", "Niveau %s atteint", "Nivel %s alcanzado", "Livello %s raggiunto", "Nível %s alcançado", "Достигнут уровень %s"}
        return formats[column]:format(level)
    end
    return value
end

-- Recognize a few standard goal phrases without translating arbitrary player text.
function C:LocalizeGoalText(value)
    if type(value) ~= "string" then return value end
    local level = value:match("^Level (%d+) werden%.$")
    if not level then return value end
    local formats = {
        enUS = "Reach level %s.", enGB = "Reach level %s.", deDE = "Level %s werden.",
        frFR = "Atteindre le niveau %s.", esES = "Alcanzar el nivel %s.", esMX = "Alcanzar el nivel %s.",
        itIT = "Raggiungere il livello %s.", ptBR = "Alcançar o nível %s.", ptPT = "Alcançar o nível %s.",
        ruRU = "Достичь уровня %s.",
    }
    return (formats[self:GetLanguage()] or formats.deDE):format(level)
end

function C:FontPath()
    return self:GetLanguage() == "ruRU" and "Fonts\\FRIZQT___CYR.TTF" or "Fonts\\FRIZQT__.TTF"
end

function C:ShowLocalizedTooltip()
    if not GameTooltip then return end
    local count = GameTooltip.NumLines and GameTooltip:NumLines() or 0
    for index = 1, count do
        for _, side in ipairs({"Left", "Right"}) do
            local line = _G["GameTooltipText" .. side .. index]
            if line and line.GetFont and line.SetFont then
                local _, size, flags = line:GetFont()
                line:SetFont(self:FontPath(), size or 12, flags)
            end
        end
    end
    GameTooltip:Show()
end

function C:FitNavLabel(label)
    if not label or not label.GetStringWidth then return end
    for size = 11, 9, -1 do
        label:SetFont(self:FontPath(), size)
        if label:GetStringWidth() <= 153 then break end
    end
end

function C:SetLanguage(code)
    if code ~= "auto" and not indexes[code] then return false end
    if not self.db then self:InitializeAccountDatabase() end
    self.db.settings.language = code
    -- Several pages create their labels only once. Rebuild the UI to update
    -- those labels and to retain the selected language in SavedVariables.
    if ReloadUI then ReloadUI()
    elseif self.RefreshLanguage then self:RefreshLanguage() end
    return true
end
