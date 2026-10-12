-- Localize addon-generated record text when displaying it. Stored discoveries,
-- player notes, IDs and guild/export payloads are never rewritten by this layer.
local _, FC = ...
local Locale, L = FC.Locale, FC.L
local matchers, professions, classes, creatureLabels, cache, cacheSize = nil, nil, nil, nil, {}, 0
function Locale:ResetDisplayCache()
    matchers, professions, classes, creatureLabels, cache, cacheSize = nil, nil, nil, nil, {}, 0
end
local function keySet(words)
    local result = {}
    for key in words:gmatch("%S+") do result[key] = true end
    return result
end
-- A Spanish NPC and item can have the same source sentence. The record type
-- supplies the meaning; it also prevents a personal note matching a recipe.
local TITLES = {
    cave = keySet("AUTO_CAVE_TITLE"), entrance = keySet("AUTO_ENTRANCE_TITLE"),
    object = keySet("AUTO_OBJECT_TITLE"), treasure = keySet("AUTO_OBJECT_TITLE"),
    path = keySet("AUTO_ROUTE_TITLE"), shortcut = keySet("AUTO_ROUTE_TITLE"),
    note = keySet("AUTO_DEATH_TITLE"), profession = keySet("AUTO_LEARNED_TITLE AUTO_FISHING_SPOT"),
    questchain = keySet("AUTO_CHAIN_TITLE"),
}
local DESCRIPTIONS = {
    -- A creature can later be identified as rare while retaining its earlier
    -- automatic observation. Both templates are safe for these two types.
    rare = keySet("AUTO_RARE AUTO_CREATURE"), creature = keySet("AUTO_CREATURE AUTO_RARE"), npc = keySet("AUTO_NPC"),
    vendor = keySet("AUTO_VENDOR AUTO_VENDOR_RECIPES AUTO_VENDOR_LIMITED ROLE"),
    trainer = keySet("AUTO_TRAINER ROLE"), travel = keySet("AUTO_TRAVEL"),
    recipe = keySet("AUTO_RECIPE AUTO_RECIPE_SKILL SOURCE_FORMAT"), item = keySet("AUTO_ITEM AUTO_ITEM_SOURCE"),
    quest = keySet("AUTO_QUEST AUTO_QUEST_GIVER"), treasure = keySet("AUTO_TREASURE"),
    object = keySet("AUTO_OBJECT"), secret = keySet("AUTO_SECRET"),
    cave = keySet("AUTO_CAVE AUTO_RECOVERED_AREA"), landmark = keySet("AUTO_LANDMARK AUTO_RECOVERED_AREA"),
    dungeon = keySet("AUTO_DUNGEON AUTO_DUNGEON_IN"), entrance = keySet("AUTO_ENTRANCE"),
    boss = keySet("AUTO_BOSS"), room = keySet("AUTO_ROOM"),
    path = keySet("AUTO_ROUTE"), shortcut = keySet("AUTO_ROUTE"),
    note = keySet("AUTO_DEATH AUTO_DEATH_KILLER"), profession = keySet("AUTO_GATHER AUTO_LEARNED"),
    questchain = keySet("AUTO_CHAIN"),
}
-- Previously saved/shared 2.2.6 descriptions remain readable after wording fixes.
local LEGACY = {
    { "AUTO_BOSS", "Побеждён: %s." },
    { "AUTO_RECOVERED_AREA", "Исследовано в %s до ведения дневника. Игра это помнит; метка указывает область на карте." },
    { "AUTO_LEARNED", "Изучено в %s." },
    { "AUTO_DEATH_KILLER", "Has muerto aquí %d veces. La última ante %s." },
    { "AUTO_ROUTE", "Путь: %d точек до %s." },
    { "AUTO_ROUTE_TITLE", "Путь к %s" },
    { "AUTO_ROOM", "Область внутри %s." },
    { "AUTO_ENTRANCE", "Вход в %s, место: %s." },
    { "AUTO_DUNGEON_IN", "Подземелье, вход со стороны %s." },
    { "AUTO_CAVE_TITLE", "Пещера у %s" },
    { "AUTO_CAVE", "Большая внутренняя область, вход со стороны %s." },
    { "AUTO_ITEM_SOURCE", "Добыча с %s, место: %s." },
    { "AUTO_TRAVEL", "Распорядитель полётов: %s." },
    { "AUTO_TRAINER", "Учитель: %s." },
    { "AUTO_RECIPE", "Recette de %s." },
    { "AUTO_RECIPE_SKILL", "Recette de %s, compétence %d requise." },
    { "AUTO_GATHER", "Points de %s dans %s." },
}
local function escaped(s)
    return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end
local function prepare()
    matchers, professions, classes, creatureLabels = {}, {}, {}, {}
    local function add(key, value)
        if type(value) ~= "string" then return end
        local parts, kinds, from, literal = { "^" }, {}, 1, 0
        while true do
            local first, last, kind = value:find("%%([sd])", from)
            local chunk = first and value:sub(from, first - 1) or value:sub(from)
            parts[#parts + 1], literal = escaped(chunk), literal + #chunk
            if not first then break end
            parts[#parts + 1] = kind == "d" and "(%d+)" or "(.-)"
            kinds[#kinds + 1] = kind
            from = last + 1
        end
        parts[#parts + 1] = "$"
        matchers[#matchers + 1] = { key = key, source = value, pattern = table.concat(parts), kinds = kinds, literal = literal }
    end
    local keys = {}
    for key in pairs(Locale.tables.enUS) do
        if key:match("^AUTO_") or key == "SOURCE_FORMAT" then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for _, locale in ipairs({ "enUS", "frFR", "esES", "ruRU", "deDE" }) do
        local strings = Locale.tables[locale] or {}
        for key, value in pairs(strings) do
            if key:match("^CLASS_") then classes[value] = L[key] end
            if key:match("^PROF_") then professions[value] = L[key] end
        end
        if strings.CAT_CREATURE then creatureLabels[strings.CAT_CREATURE] = true end
        for _, key in ipairs(keys) do
            add(key, strings[key])
            if key == "SOURCE_FORMAT" and strings[key] then add(key, strings[key] .. ".") end
        end
    end
    for _, entry in ipairs(LEGACY) do add(entry[1], entry[2]) end
    classes["Poco común"], classes["Élite poco común"] = L.CLASS_rare, L.CLASS_rareelite
    -- Match the most specific sentence first: "Recipe ..., skill ..." must
    -- win over "Recipe ...", including when both are translated.
    table.sort(matchers, function(a, b)
        if a.literal ~= b.literal then return a.literal > b.literal end
        if a.key ~= b.key then return a.key < b.key end
        return a.source < b.source
    end)
end
local PLACE_ARGS = {
    AUTO_RARE = 3, AUTO_CREATURE = 4, AUTO_NPC = 1, AUTO_TRAINER = 1, AUTO_TRAVEL = 1,
    AUTO_ITEM = 1, AUTO_ITEM_SOURCE = 2, AUTO_QUEST = 1, AUTO_QUEST_GIVER = 2,
    AUTO_TREASURE = 1, AUTO_OBJECT = 1, AUTO_SECRET = 1, AUTO_CAVE = 1, AUTO_CAVE_TITLE = 1,
    AUTO_LANDMARK = 1, AUTO_DUNGEON_IN = 1, AUTO_ENTRANCE = 2, AUTO_ENTRANCE_TITLE = 1,
    AUTO_BOSS = 1, AUTO_ROOM = 1, AUTO_DEATH_TITLE = 1, AUTO_GATHER = 2,
    AUTO_LEARNED = 1, AUTO_RECOVERED_AREA = 1,
}
local function localizeArgs(key, args, rec)
    if key == "AUTO_RECIPE" or key == "AUTO_RECIPE_SKILL" or key == "AUTO_GATHER" then
        args[1] = professions[args[1]] or args[1]
    elseif key == "AUTO_RARE" then
        args[2] = classes[args[2]] or args[2]
    elseif key == "AUTO_CREATURE" then
        -- Adjacent %s%s do not delimit the creature type and classification.
        local combined = args[2] .. args[3]
        local creature, class = combined:match("^(.-) %((.-)%)$")
        if creature and classes[class] then args[2], args[3] = creature, " (" .. classes[class] .. ")"
        else args[2], args[3] = combined, "" end
        if creatureLabels[args[2]] then args[2] = L.CAT_CREATURE end
        args[2] = Locale:ContentName("creature", args[2])
    end
    local place = PLACE_ARGS[key]
    if place then args[place] = Locale:Place(args[place]) end
    if key == "AUTO_ENTRANCE" then args[1] = Locale:Place(args[1])
    elseif key == "AUTO_ITEM_SOURCE" or key == "AUTO_QUEST_GIVER" or key == "SOURCE_FORMAT" then
        args[1] = Locale:ContentName("npc", args[1])
    elseif key == "AUTO_DEATH_KILLER" then args[2] = Locale:ContentName("npc", args[2])
    elseif key == "AUTO_CHAIN_TITLE" then args[1] = Locale:ContentName("quest", args[1])
    elseif key == "AUTO_CHAIN" then args[2] = Locale:ContentName("quest", args[2])
    elseif key == "AUTO_LEARNED_TITLE" then args[1] = Locale:ContentName("item", args[1])
    elseif key == "AUTO_ROUTE_TITLE" then args[1] = Locale:DiscoveryName(args[1], rec)
    elseif key == "AUTO_ROUTE" then args[2] = Locale:DiscoveryName(args[2], rec) end
end
local NAME_FIELDS = { "z", "sz", "src", "gv", "inn", "ct" }
local function isKnownName(value, rec)
    if not rec then return false end
    for _, field in ipairs(NAME_FIELDS) do if rec[field] == value then return true end end
    return rec.sz and rec.z and value == rec.sz .. ", " .. rec.z
end
local function translate(text, allowed, rec)
    for _, item in ipairs(matchers) do
        if not allowed or allowed[item.key] then
        if #item.kinds == 0 then
            if text == item.source then return L[item.key], true end
        else
            local args = { text:match(item.pattern) }
            if #args == #item.kinds then
                local singleSentence = true
                for i, kind in ipairs(item.kinds) do
                    -- A capture must not absorb a following player-written
                    -- sentence just because the whole text ends with a dot.
                    if args[i]:find("\n", 1, true) or (args[i]:find("%.[ ]+") and not isKnownName(args[i], rec)) then singleSentence = false end
                    if kind == "d" then args[i] = tonumber(args[i]) end
                end
                if singleSentence then
                    localizeArgs(item.key, args, rec)
                    local ok, result = pcall(string.format, L[item.key], unpack(args))
                    if ok and item.key == "SOURCE_FORMAT" and item.source:sub(-1) == "." then result = result .. "." end
                    if ok then return result, true end
                end
            end
        end
        end
    end
    if allowed and allowed.ROLE then
        local dot = text:sub(-1) == "."
        local value, known = Locale:ContentName("role", dot and text:sub(1, -2) or text)
        if known then return value .. (dot and "." or ""), true end
    end
    return text, false
end
function Locale:GeneratedText(text, allowed, context, rec)
    if type(text) ~= "string" or text == "" then return text end
    local cacheKey = (context or "*") .. "\031" .. text
    if cache[cacheKey] then return cache[cacheKey] end
    if not matchers then prepare() end
    local result, matched = translate(text, allowed, rec)
    -- Vendor/recipe summaries can concatenate several generated sentences.
    -- Only replace them if EVERY sentence is a recognized addon template.
    if not matched then
        local parts, at, all = {}, 1, true
        while at <= #text do
            local _, last = text:find("%.[ ]+", at)
            local stop = last and last - 1 or #text
            local sentence = text:sub(at, stop):gsub(" +$", "")
            local converted, known = translate(sentence, allowed, rec)
            if not known then all = false; break end
            parts[#parts + 1] = converted
            at = last and last + 1 or #text + 1
        end
        if all and #parts > 1 then result = table.concat(parts, " ") end
    end
    if cacheSize >= 2048 then cache, cacheSize = {}, 0 end
    cache[cacheKey], cacheSize = result, cacheSize + 1
    return result
end

function Locale:IsGeneratedCaveDescription(rec)
    if not rec or rec.t ~= "cave" then return false end
    if not rec.d or rec.d == "" then return true end
    if not matchers then prepare() end
    local _, matched = translate(rec.d, DESCRIPTIONS.cave, rec)
    return matched
end

function Locale:RecordText(rec, field)
    if not rec then return nil end
    local allowed = (field == "n" and TITLES or DESCRIPTIONS)[rec.t]
    if not allowed then return field == "n" and self:RecordName(rec) or rec[field] end
    local context = rec.t .. ":" .. field
    for _, nameField in ipairs(NAME_FIELDS) do context = context .. "\030" .. (rec[nameField] or "") end
    local text = self:GeneratedText(rec[field], allowed, context, rec)
    if field == "n" and text == rec[field] then return self:RecordName(rec) end
    return text
end

local TAGS = {
    ["rare-spawn"] = "CAT_RARE", elite = "CLASS_elite", ["world-boss"] = "CLASS_worldboss",
    recipes = "CAT_RECIPE", ["limited-stock"] = "TAG_LIMITED", trainer = "CAT_TRAINER",
    ["flight-master"] = "CAT_TRAVEL", recipe = "CAT_RECIPE", loot = "DUNGEON_LOOT",
    quest = "CAT_QUEST", treasure = "CAT_TREASURE", interactive = "TAG_INTERACTIVE",
    secret = "CAT_SECRET", cave = "CAT_CAVE", explored = "MAPGROUP_EXPLORED",
    dungeon = "CAT_DUNGEON", entrance = "CAT_ENTRANCE", boss = "CAT_BOSS",
    ["dungeon-area"] = "NOTIFYCAT_ROOM", route = "FIELD_ROUTE", mechanic = "CAT_MECHANIC",
    gathering = "NOTIFYCAT_GATHERING", learned = "TAG_LEARNED", ["quest-chain"] = "CAT_QUESTCHAIN",
    recovered = "TAG_RECOVERED", danger = "ROLE_DANGER", lore = "TAG_LORE", readable = "TAG_READABLE",
}
function Locale:TagLabel(rec, tag)
    local state = FC.Store and FC.Store:GetState(rec.id)
    for _, custom in ipairs(state and state.tags or {}) do if custom == tag then return tag end end
    if TAGS[tag] then return L[TAGS[tag]] end
    for _, profession in ipairs(FC.Categories.PROFESSIONS) do
        if profession.key == tag then return L[profession.label] end
    end
    return tag
end
