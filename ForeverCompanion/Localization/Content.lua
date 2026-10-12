-- Display-only game names. Saved records, quest matching and guild payloads
-- retain their original values and IDs, even with a different display language.
local _, FC = ...
local Locale = FC.Locale
local columns = { enUS = 1, frFR = 2, esES = 3, ruRU = 4, deDE = 5 }
local indexes = {}

local function mergeNames(a, b)
    if a[1] ~= b[1] then return false end
    local merged = { a[1] }
    for i = 2, 5 do
        local left, right = a[i] or a[1], b[i] or b[1]
        if left ~= right and left ~= a[1] and right ~= a[1] then return false end
        merged[i] = left ~= a[1] and left or right
    end
    return merged
end

local function indexFor(kind)
    if indexes[kind] then return indexes[kind] end
    local index = {}
    for _, row in pairs(Locale.content[kind] or {}) do
        for _, name in ipairs(row) do
            local previous = index[name]
            if previous == nil then
                index[name] = row
            elseif previous and previous ~= row then
                -- An ambiguous name must not silently select another entity.
                if kind == "place" and previous[1] == row[1] .. " Entrance" then
                    index[name] = row
                elseif not (kind == "place" and row[1] == previous[1] .. " Entrance") then
                    -- Duplicate server IDs often carry English placeholders.
                    -- Fill those gaps, but keep genuinely conflicting names ambiguous.
                    index[name] = mergeNames(previous, row)
                end
            end
        end
    end
    indexes[kind] = index
    return index
end

function Locale:ContentName(kind, text, id)
    local rows = self.content[kind]
    if not rows then return text, false end
    local row = (id and rows[tonumber(id)]) or (type(text) == "string" and rows[text])
    if row and text then
        local known = false
        for _, name in ipairs(row) do if name == text then known = true; break end end
        -- An edited title or a server-specific entity with a reused ID wins.
        if not known then row = nil end
    end
    if not row and type(text) == "string" then row = indexFor(kind)[text] end
    if row then
        local column = columns[self.active] or 1
        local value = row[column] or row[1]
        if column ~= 1 and value == row[1] then
            local complete = indexFor(kind)[row[1]]
            if complete and complete[1] == row[1] then value = complete[column] or value end
        end
        return value, true
    end
    return text, false
end

function Locale:Place(text)
    if type(text) ~= "string" then return text end
    local value, known = self:ContentName("place", text)
    if known then return value end
    -- Discovery locations can combine a subzone and its parent zone.
    local parts = {}
    for part in text:gmatch("[^,]+") do
        local name = part:match("^%s*(.-)%s*$")
        parts[#parts + 1] = self:ContentName("place", name)
    end
    return #parts > 1 and table.concat(parts, ", ") or text
end

local nameKinds = {
    rare = "npc", creature = "npc", npc = "npc", vendor = "npc", trainer = "npc", travel = "npc", boss = "npc",
    quest = "quest", item = "item", recipe = "item", treasure = "object", object = "object",
    cave = "place", landmark = "place", dungeon = "place", room = "place",
}
function Locale:RecordName(rec)
    local kind = nameKinds[rec.t]
    if not kind then return rec.n end
    local id = kind == "npc" and rec.npc or kind == "quest" and rec.q or kind == "item" and rec.it or rec.obj
    return self:ContentName(kind, rec.n, id)
end

function Locale:DiscoveryName(text, rec)
    if rec and rec.pa and FC.Store then
        local parent = FC.Store:Get(rec.pa)
        if parent and parent ~= rec and parent.t ~= "path" and parent.t ~= "shortcut" and parent.n == text then
            return self:RecordText(parent, "n")
        end
    end
    for _, kind in ipairs({ "place", "object", "quest", "item", "npc" }) do
        local value, known = self:ContentName(kind, text)
        if known then return value end
    end
    -- Older paths can refer to an automatically named cave without a parent.
    return self:GeneratedText(text, { AUTO_CAVE_TITLE = true, AUTO_ENTRANCE_TITLE = true }, "destination")
end

-- Creature types are client strings rather than addon category labels.
local types = {
    { "Beast", "Bête", "Bestia", "Животное", "Wildtier" },
    { "Humanoid", "Humanoïde", "Humanoide", "Гуманоид", "Humanoid" },
    { "Undead", "Mort-vivant", "No-muerto", "Нежить", "Untoter" },
    { "Demon", "Démon", "Demonio", "Демон", "Dämon" },
    { "Dragonkin", "Draconien", "Dragonante", "Дракон", "Drachkin" },
    { "Elemental", "Élémentaire", "Elemental", "Элементаль", "Elementar" },
    { "Giant", "Géant", "Gigante", "Великан", "Riese" },
    { "Mechanical", "Mécanique", "Mecánico", "Механизм", "Mechanisch" },
    { "Critter", "Bestiole", "Alimaña", "Зверек", "Kleintier" },
    { "Not specified", "Non spécifié", "Sin especificar", "Не указано", "Nicht spezifiziert" },
    { "Totem", "Totem", "Tótem", "Тотем", "Totem" },
}
Locale.content.creature = types
