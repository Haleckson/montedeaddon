--[[
  Forever Companion - Data/Categories.lua
  Registry of discovery types, their journal groups, map filter groups and the
  profession list. New types are added with FC.Categories:Register(key, def)
  from any module (or a future plugin) without touching the rest of the addon.

  def fields:
    label     localized name
    icon      texture path or fileID used on cards and pins
    color     "rrggbb" accent for rings and chips
    group     journal page group (see GROUPS)
    mapGroup  map filter group (see MAP_GROUPS)
    notify    notification category (rare, recipe, secret, dungeon, personal)
    special   true for types with the "secret" presentation
    anchor    field that makes the id stable ("npc", "q", "it", "in") or nil for generated ids
]]

local _, FC = ...

local Categories = { types = {}, order = {} }
FC.Categories = Categories

local L = FC.L
local ICON = "Interface\\Icons\\"

Categories.GROUPS = {
    quests = { "quest", "questchain" },
    npcs = { "npc", "trainer", "travel" },
    bestiary = { "creature" },
    rares = { "rare" },
    vendors = { "vendor" },
    recipes = { "recipe", "profession" },
    items = { "item" },
    secrets = { "secret", "cave", "path", "landmark", "treasure", "object", "shortcut" },
    dungeons = { "dungeon", "entrance", "boss", "mechanic", "room" },
    professions = { "recipe", "profession", "trainer" },
    notes = { "note" },
}

Categories.MAP_GROUPS = {
    { key = "quest", label = "MAPGROUP_QUEST" },
    { key = "rare", label = "MAPGROUP_RARE" },
    { key = "vendor", label = "MAPGROUP_VENDOR" },
    { key = "recipe", label = "MAPGROUP_RECIPE" },
    { key = "npc", label = "MAPGROUP_NPC" },
    { key = "creature", label = "MAPGROUP_CREATURE" },
    { key = "secret", label = "MAPGROUP_SECRET" },
    { key = "treasure", label = "MAPGROUP_TREASURE" },
    { key = "explored", label = "MAPGROUP_EXPLORED" },
    { key = "dungeon", label = "MAPGROUP_DUNGEON" },
    { key = "profession", label = "MAPGROUP_PROFESSION" },
    { key = "path", label = "MAPGROUP_PATH" },
    { key = "note", label = "MAPGROUP_NOTE" },
    { key = "other", label = "MAPGROUP_OTHER" },
}

function Categories:Register(key, def)
    assert(type(key) == "string" and key:match("^[%l%d]+$"), "category key must be lowercase alphanumeric")
    def.key = key
    def.group = def.group or "other"
    def.mapGroup = def.mapGroup or "other"
    def.notify = def.notify or "personal"
    def.color = def.color or "c9b27c"
    if not self.types[key] then
        self.order[#self.order + 1] = key
    end
    self.types[key] = def
end

function Categories:Get(key)
    return self.types[key] or self.types.other
end

function Categories:IsValid(key)
    return type(key) == "string" and self.types[key] ~= nil
end

function Categories:Label(key)
    local def = self:Get(key)
    return L[def.label]
end

function Categories:TypesInGroup(group)
    return self.GROUPS[group]
end

--- Types offered in the quick-capture picker, in display order.
Categories.QUICK = { "rare", "vendor", "quest", "secret", "dungeon", "recipe", "npc", "treasure", "note" }

local defs = {
    { "quest", "CAT_QUEST", ICON .. "INV_Misc_Note_02", "f2d15c", "quests", "quest", "personal", nil, "q" },
    { "questchain", "CAT_QUESTCHAIN", ICON .. "INV_Scroll_03", "f2d15c", "quests", "quest", "personal" },
    { "rare", "CAT_RARE", ICON .. "INV_Misc_Head_Dragon_01", "e0a040", "rares", "rare", "rare", nil, "npc" },
    { "npc", "CAT_NPC", ICON .. "INV_Misc_Head_Human_01", "9fb7d9", "npcs", "npc", "personal", nil, "npc" },
    { "creature", "CAT_CREATURE", ICON .. "Ability_Hunter_Pet_Wolf", "b0977a", "bestiary", "creature", "bestiary", nil, "npc" },
    { "travel", "CAT_TRAVEL", ICON .. "Ability_Mount_Gryphon_01", "8fc3e8", "npcs", "npc", "explore", nil, "npc" },
    { "trainer", "CAT_TRAINER", ICON .. "INV_Misc_Book_11", "7fc9a5", "npcs", "profession", "recipe", nil, "npc" },
    { "vendor", "CAT_VENDOR", ICON .. "INV_Misc_Bag_10", "d9a066", "vendors", "vendor", "personal", nil, "npc" },
    { "recipe", "CAT_RECIPE", ICON .. "INV_Scroll_04", "6fd3c2", "recipes", "recipe", "recipe", nil, "it" },
    { "profession", "CAT_PROFESSION", ICON .. "Trade_BlackSmithing", "6fd3c2", "recipes", "profession", "recipe" },
    { "item", "CAT_ITEM", ICON .. "INV_Misc_Gem_01", "b48cf2", "items", "other", "personal", nil, "it" },
    { "object", "CAT_OBJECT", ICON .. "INV_Misc_Gear_01", "a0a7b4", "secrets", "other", "secret" },
    { "treasure", "CAT_TREASURE", ICON .. "INV_Box_02", "f0c05a", "secrets", "treasure", "secret" },
    { "secret", "CAT_SECRET", ICON .. "INV_Misc_QuestionMark", "e8c35a", "secrets", "secret", "secret", true },
    { "cave", "CAT_CAVE", ICON .. "INV_Torch_Lit", "c28f5c", "secrets", "secret", "secret", true },
    { "path", "CAT_PATH", ICON .. "Ability_Tracking", "8fbf6a", "secrets", "path", "explore", true },
    { "landmark", "CAT_LANDMARK", ICON .. "INV_Misc_Map_01", "a7c4e0", "secrets", "explored", "explore" },
    { "shortcut", "CAT_SHORTCUT", ICON .. "Ability_Rogue_Sprint", "8fbf6a", "secrets", "secret", "secret", true },
    { "dungeon", "CAT_DUNGEON", ICON .. "INV_Misc_Key_03", "c77dff", "dungeons", "dungeon", "dungeon", nil, "in" },
    { "entrance", "CAT_ENTRANCE", ICON .. "Spell_Shadow_Teleport", "c77dff", "dungeons", "dungeon", "dungeon" },
    { "boss", "CAT_BOSS", ICON .. "INV_Misc_Bone_HumanSkull_01", "e06060", "dungeons", "dungeon", "dungeon" },
    { "mechanic", "CAT_MECHANIC", ICON .. "INV_Gizmo_02", "c77dff", "dungeons", "dungeon", "dungeon" },
    { "room", "CAT_ROOM", ICON .. "INV_Misc_Key_01", "e8c35a", "dungeons", "dungeon", "dungeon" },
    { "note", "CAT_NOTE", ICON .. "INV_Misc_Note_01", "d8d0b8", "notes", "note", "personal" },
    { "other", "CAT_OTHER", ICON .. "Spell_Holy_MindVision", "c9b27c", "other", "other", "personal" },
}

for _, d in ipairs(defs) do
    Categories:Register(d[1], {
        label = d[2], icon = d[3], color = d[4], group = d[5],
        mapGroup = d[6], notify = d[7], special = d[8] or false, anchor = d[9],
    })
end

------------------------------------------------------------------------
-- Professions (the 1-60 set; the list is data, extend it when Forever adds more)
------------------------------------------------------------------------

Categories.PROFESSIONS = {
    { key = "alchemy", label = "PROF_ALCHEMY", icon = ICON .. "Trade_Alchemy", subclass = 6 },
    { key = "blacksmithing", label = "PROF_BLACKSMITHING", icon = ICON .. "Trade_BlackSmithing", subclass = 4 },
    { key = "cooking", label = "PROF_COOKING", icon = ICON .. "INV_Misc_Food_15", subclass = 5 },
    { key = "enchanting", label = "PROF_ENCHANTING", icon = ICON .. "Trade_Engraving", subclass = 8 },
    { key = "engineering", label = "PROF_ENGINEERING", icon = ICON .. "Trade_Engineering", subclass = 3 },
    { key = "firstaid", label = "PROF_FIRSTAID", icon = ICON .. "Spell_Holy_SealOfSacrifice", subclass = 7 },
    { key = "fishing", label = "PROF_FISHING", icon = ICON .. "Trade_Fishing", subclass = 9 },
    { key = "herbalism", label = "PROF_HERBALISM", icon = ICON .. "Trade_Herbalism" },
    { key = "leatherworking", label = "PROF_LEATHERWORKING", icon = ICON .. "Trade_LeatherWorking", subclass = 1 },
    { key = "mining", label = "PROF_MINING", icon = ICON .. "Trade_Mining" },
    { key = "skinning", label = "PROF_SKINNING", icon = ICON .. "INV_Misc_Pelt_Wolf_01" },
    { key = "tailoring", label = "PROF_TAILORING", icon = ICON .. "Trade_Tailoring", subclass = 2 },
    { key = "other", label = "PROF_OTHER", icon = ICON .. "INV_Misc_Gear_01" },
}

Categories.professionByKey = {}
Categories.professionBySubclass = {}
for _, p in ipairs(Categories.PROFESSIONS) do
    Categories.professionByKey[p.key] = p
    if p.subclass then Categories.professionBySubclass[p.subclass] = p end
end

function Categories:ProfessionFromSubclass(subClassID)
    local p = self.professionBySubclass[subClassID]
    return p and p.key or "other"
end

--- Matches a free text (e.g. an NPC subtitle "Alchemy Trainer") to a profession key.
function Categories:ProfessionFromText(text)
    if type(text) ~= "string" then return nil end
    local lowered = text:lower()
    for _, p in ipairs(self.PROFESSIONS) do
        if p.key ~= "other" and lowered:find(L[p.label]:lower(), 1, true) then
            return p.key
        end
    end
    return nil
end

function Categories:Profession(key)
    return self.professionByKey[key] or self.professionByKey.other
end

--- Built-in note icons for the editor's icon picker.
Categories.NOTE_ICONS = {
    ICON .. "INV_Misc_Note_01", ICON .. "INV_Misc_Map_01", ICON .. "INV_Misc_QuestionMark",
    ICON .. "INV_Box_02", ICON .. "INV_Misc_Key_03", ICON .. "INV_Torch_Lit",
    ICON .. "INV_Misc_Head_Dragon_01", ICON .. "INV_Misc_Bag_10", ICON .. "INV_Scroll_04",
    ICON .. "INV_Misc_Gem_01", ICON .. "Ability_Tracking", ICON .. "INV_Misc_Bone_HumanSkull_01",
    ICON .. "Spell_Shadow_Teleport", ICON .. "INV_Misc_Spyglass_03", ICON .. "Spell_Holy_MindVision",
    ICON .. "INV_Misc_Coin_01", ICON .. "INV_Gizmo_02", ICON .. "Ability_Rogue_Sprint",
}
