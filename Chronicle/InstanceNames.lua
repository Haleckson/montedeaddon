local C = _G.Chronicle

-- Display names only. English catalog keys remain stable for artwork and saves.
-- Columns: German, French, Spanish, Italian, Portuguese, Russian.
local names = {
    ["Hall of Thanes"] = {"Halle der Thanen", "Salle des thanes", "Salón de los thanes", "Sala dei thane", "Salão dos Thanes", "Зал танов"},
    ["Ragefire Chasm"] = {"Flammenschlund", "Gouffre de Ragefeu", "Sima Ígnea", "Baratro di Fiamma Furente", "Cavernas Ígneas", "Огненная пропасть"},
    ["Ruins of Lordaeron"] = {"Ruinen von Lordaeron", "Ruines de Lordaeron", "Ruinas de Lordaeron", "Rovine di Lordaeron", "Ruínas de Lordaeron", "Руины Лордерона"},
    ["The Deadmines"] = {"Die Todesminen", "Les Mortemines", "Las Minas de la Muerte", "Le Miniere della Morte", "As Minas Mortas", "Мёртвые копи"},
    ["Wailing Caverns"] = {"Höhlen des Wehklagens", "Cavernes des Lamentations", "Cuevas de los Lamentos", "Caverne dei Lamenti", "Caverna Ululante", "Пещеры Стенаний"},
    ["Shadowfang Keep"] = {"Burg Schattenfang", "Donjon d'Ombrecroc", "Castillo de Colmillo Oscuro", "Forte di Zannaombra", "Fortaleza Presa Negra", "Крепость Тёмного Клыка"},
    ["Blackfathom Deeps"] = {"Tiefschwarze Grotte", "Profondeurs de Brassenoire", "Cavernas de Brazanegra", "Abissi di Fondocupo", "Profundezas Negras", "Непроглядная Пучина"},
    ["Excavation Site: Wetlands"] = {"Ausgrabungsstätte: Sumpfland", "Site de fouilles : Paluns", "Excavación: Los Humedales", "Scavi: Paludi Grigie", "Escavação: Pantanal", "Раскопки: Болотина"},
    ["Stormwind Stockade"] = {"Verlies von Sturmwind", "Prison de Hurlevent", "Las Mazmorras de Ventormenta", "Segrete di Roccavento", "Cárcere de Ventobravo", "Тюрьма Штормграда"},
    ["Scarlet Monastery: Graveyard"] = {"Scharlachrotes Kloster: Friedhof", "Monastère écarlate : Cimetière", "Monasterio Escarlata: Cementerio", "Monastero Scarlatto: Cimitero", "Monastério Escarlate: Cemitério", "Монастырь Алого ордена: Кладбище"},
    ["City of Dalaran"] = {"Stadt Dalaran", "Cité de Dalaran", "Ciudad de Dalaran", "Città di Dalaran", "Cidade de Dalaran", "Город Даларан"},
    ["Razorfen Kraul"] = {"Kral der Klingenhauer", "Kraal de Tranchebauge", "Horado Rajacieno", "Gallerie di Lamaspina", "Urzal dos Tuscos", "Лабиринты Иглошкурых"},
    ["Gnomeregan"] = {"Gnomeregan", "Gnomeregan", "Gnomeregan", "Gnomeregan", "Gnomeregan", "Гномреган"},
    ["Scarlet Monastery: Library"] = {"Scharlachrotes Kloster: Bibliothek", "Monastère écarlate : Bibliothèque", "Monasterio Escarlata: Biblioteca", "Monastero Scarlatto: Biblioteca", "Monastério Escarlate: Biblioteca", "Монастырь Алого ордена: Библиотека"},
    ["Scarlet Monastery: Armory"] = {"Scharlachrotes Kloster: Waffenkammer", "Monastère écarlate : Armurerie", "Monasterio Escarlata: Armería", "Monastero Scarlatto: Armeria", "Monastério Escarlate: Arsenal", "Монастырь Алого ордена: Оружейная"},
    ["The Drowned City"] = {"Die versunkene Stadt", "La cité engloutie", "La ciudad sumergida", "La città sommersa", "A cidade submersa", "Затонувший город"},
    ["Scarlet Monastery: Cathedral"] = {"Scharlachrotes Kloster: Kathedrale", "Monastère écarlate : Cathédrale", "Monasterio Escarlata: Catedral", "Monastero Scarlatto: Cattedrale", "Monastério Escarlate: Catedral", "Монастырь Алого ордена: Собор"},
    ["Razorfen Downs"] = {"Hügel der Klingenhauer", "Souilles de Tranchebauge", "Zahúrda Rajacieno", "Bassi Fondi di Lamaspina", "Urzal dos Mortos", "Курганы Иглошкурых"},
    ["Krol'dok Stronghold"] = {"Festung Krol'dok", "Forteresse de Krol'dok", "Fortaleza de Krol'dok", "Roccaforte di Krol'dok", "Fortaleza de Krol'dok", "Крепость Крол'док"},
    ["Uldaman"] = {"Uldaman", "Uldaman", "Uldaman", "Uldaman", "Uldaman", "Ульдаман"},
    ["Zul'Farrak"] = {"Zul'Farrak", "Zul'Farrak", "Zul'Farrak", "Zul'Farrak", "Zul'Farrak", "Зул'Фаррак"},
    ["Maraudon"] = {"Maraudon", "Maraudon", "Maraudon", "Maraudon", "Maraudon", "Мародон"},
    ["Alcaz Prison"] = {"Gefängnis von Alcaz", "Prison d'Alcaz", "Prisión de Alcaz", "Prigione di Alcaz", "Prisão de Alcaz", "Тюрьма Алькац"},
    ["Sunken Temple"] = {"Versunkener Tempel", "Temple englouti", "Templo Sumergido", "Tempio Sommerso", "Templo Submerso", "Затонувший храм"},
    ["Blackrock Depths"] = {"Schwarzfelstiefen", "Profondeurs de Rochenoire", "Profundidades de Roca Negra", "Sotterranei di Roccianera", "Abismo Rocha Negra", "Глубины Чёрной горы"},
    ["Lower Blackrock Spire"] = {"Untere Schwarzfelsspitze", "Pic Rochenoire inférieur", "Cumbre de Roca Negra inferior", "Bastioni di Roccianera inferiori", "Pico da Rocha Negra Inferior", "Нижняя часть Пика Чёрной горы"},
    ["Blackmaw Hold"] = {"Feste Schwarzschlund", "Fort de Gueulenoire", "Bastión Fauces Negras", "Fortezza delle Fauci Nere", "Fortaleza Presanegra", "Крепость Чёрной Пасти"},
    ["Dire Maul East"] = {"Düsterbruch: Ost", "Hache-Tripes : Est", "La Masacre: Este", "Maglio Infausto: Est", "Gládio Cruel: Leste", "Забытый Город: Восток"},
    ["Upper Blackrock Spire"] = {"Obere Schwarzfelsspitze", "Pic Rochenoire supérieur", "Cumbre de Roca Negra superior", "Bastioni di Roccianera superiori", "Pico da Rocha Negra Superior", "Верхняя часть Пика Чёрной горы"},
    ["Shaper's Terrace"] = {"Terrasse der Former", "Terrasse des façonneurs", "Terraza de los moldeadores", "Terrazza dei Plasmatori", "Terraço dos Moldadores", "Терраса Создателей"},
    ["Dire Maul West"] = {"Düsterbruch: West", "Hache-Tripes : Ouest", "La Masacre: Oeste", "Maglio Infausto: Ovest", "Gládio Cruel: Oeste", "Забытый Город: Запад"},
    ["Dire Maul North"] = {"Düsterbruch: Nord", "Hache-Tripes : Nord", "La Masacre: Norte", "Maglio Infausto: Nord", "Gládio Cruel: Norte", "Забытый Город: Север"},
    ["Scholomance"] = {"Scholomance", "Scholomance", "Scholomance", "Scholomance", "Scolomântia", "Некроситет"},
    ["Stratholme"] = {"Stratholme", "Stratholme", "Stratholme", "Stratholme", "Stratholme", "Стратхольм"},
    ["Molten Core"] = {"Geschmolzener Kern", "Cœur du Magma", "Núcleo de Magma", "Nucleo Ardente", "Núcleo Derretido", "Огненные Недра"},
    ["Onyxia's Lair"] = {"Onyxias Hort", "Repaire d'Onyxia", "Guarida de Onyxia", "Antro di Onyxia", "Covil da Onyxia", "Логово Ониксии"},
    ["Zul'Gurub"] = {"Zul'Gurub", "Zul'Gurub", "Zul'Gurub", "Zul'Gurub", "Zul'Gurub", "Зул'Гуруб"},
    ["Blackwing Lair"] = {"Pechschwingenhort", "Repaire de l'Aile noire", "Guarida Alanegra", "Fortezza dell'Ala Nera", "Covil Asa Negra", "Логово Крыла Тьмы"},
    ["Ruins of Ahn'Qiraj"] = {"Ruinen von Ahn'Qiraj", "Ruines d'Ahn'Qiraj", "Ruinas de Ahn'Qiraj", "Rovine di Ahn'Qiraj", "Ruínas de Ahn'Qiraj", "Руины Ан'Киража"},
    ["Ahn'Qiraj Temple"] = {"Tempel von Ahn'Qiraj", "Temple d'Ahn'Qiraj", "Templo de Ahn'Qiraj", "Tempio di Ahn'Qiraj", "Templo de Ahn'Qiraj", "Храм Ан'Киража"},
    ["Naxxramas"] = {"Naxxramas", "Naxxramas", "Naxxramas", "Naxxramas", "Naxxramas", "Наксрамас"},
    ["Mount Hyjal"] = {"Hyjalberg", "Mont Hyjal", "Monte Hyjal", "Monte Hyjal", "Monte Hyjal", "Гора Хиджал"},
    ["Barrow Deeps"] = {"Hügelgruft-Tiefen", "Profondeurs des tertres", "Profundidades del túmulo", "Profondità dei tumuli", "Profundezas dos Túmulos", "Глубины курганов"},
}

local columns = {deDE = 1, frFR = 2, esES = 3, esMX = 3, itIT = 4,
    ptBR = 5, ptPT = 5, ruRU = 6}

function C:LocalizeInstanceName(name)
    if type(name) ~= "string" then return name end
    local row = names[name]
    local column = columns[self:GetLanguage()]
    return row and column and row[column] or name
end
