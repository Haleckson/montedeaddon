-- Curated factual starter entries; trainer visits provide the authoritative offers.
local C = _G.Chronicle

local teachers = {
    WARRIOR = {
        { "Sorek", "Orgrimmar", nil, nil, "H" },
        { "Wu Shen", "Stormwind City", nil, nil, "A" },
    },
    PALADIN = {
        { "Alodan the Hopeful", "Thunder Bluff", 25.4, 14.6, "H", 1456 },
        { "Aramis Hammerhand", "Tirisfal", 31.0, 66.2, "H", 1420 },
        { "Hilda the Breaker", "Tirisfal", 22.0, 47.2, "H", 1420 },
        { "Shari Stilwell", "Tirisfal", 60.2, 52.6, "H", 1420 },
        { "Garen Largo", "Undercity", 47.6, 14.8, "H", 1458 },
        { "Brother Wilhelm", "Elwynn Forest", nil, nil, "A" },
        { "Arthur the Faithful", "Stormwind City", nil, nil, "A" },
    },
    DRUID = {
        { "Turak Runetotem", "Thunder Bluff", 76.5, 27.2, "H", 1456 },
        { "Gennia Runetotem", "Mulgore", 47.5, 63.0, "H", 1412 },
        { "Mathrengyl Bearwalker", "Darnassus", 35.0, 8.0, "A", 1457 },
    },
    MAGE = {
        { "Deino", "Orgrimmar", nil, nil, "H" },
        { "Anastasia Hartwell", "Undercity", nil, nil, "H" },
        { "Elsharin", "Stormwind City", nil, nil, "A" },
    },
    HUNTER = {
        { "Ormak Grimshot", "Orgrimmar", nil, nil, "H" },
        { "Thorfin Stoneshield", "Stormwind City", nil, nil, "A" },
    },
    ROGUE = {
        { "Shenthul", "Orgrimmar", nil, nil, "H" },
        { "Hulfdan Blackbeard", "Ironforge", nil, nil, "A" },
    },
    SHAMAN = {
        { "Kardris Dreamseeker", "Orgrimmar", nil, nil, "H" },
        { "Eldrun Stormbreaker", "Ironforge", nil, nil, "A" },
    },
    PRIEST = {
        { "Father Lankester", "Undercity", nil, nil, "H" },
        { "High Priestess Mims", "Ironforge", nil, nil, "A" },
    },
    WARLOCK = {
        { "Grol'dar", "Orgrimmar", nil, nil, "H" },
        { "Demisette Cloyce", "Stormwind City", nil, nil, "A" },
    },
}

-- Classic capital city locations are starting points. A trainer visit can
-- replace these coordinates with the position observed in this client.
local weaponMasters = {
    { "Woo Ping", "Stormwind City", 57.0, 57.0, "A", 1453 },
    { "Buliwyf Stonehand", "Ironforge", 62.0, 89.0, "A", 1455 },
    { "Bixi Wobblebonk", "Ironforge", 62.0, 89.0, "A", 1455 },
    { "Ilyenia Moonfire", "Darnassus", 57.0, 46.0, "A", 1457 },
    { "Hanashi", "Orgrimmar", 81.0, 19.0, "H", 1454 },
    { "Sayoc", "Orgrimmar", 81.0, 19.0, "H", 1454 },
    { "Ansekhwa", "Thunder Bluff", 41.0, 62.0, "H", 1456 },
    { "Archibald", "Undercity", 57.0, 32.0, "H", 1458 },
}

function C:GetKnowledgeWeaponMasters()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    faction = faction == "Alliance" and "A" or (faction == "Horde" and "H" or nil)
    local result = {}
    for _, row in ipairs(weaponMasters) do
        if not faction or row[5] == faction then
            result[#result + 1] = { name = row[1], zone = row[2], x = row[3], y = row[4],
                mapID = row[6], kind = "weapon", source = "catalog" }
        end
    end
    return result
end

-- Weapon types a class can use in the Forever beta. Levels/prices are previews.
local weapons = {
    { "Einhandäxte", "Interface\\Icons\\INV_Axe_01", 1, 1000 },
    { "Zweihandäxte", "Interface\\Icons\\INV_Axe_09", 1, 1000 },
    { "Einhandschwerter", "Interface\\Icons\\INV_Sword_04", 1, 1000 },
    { "Zweihandschwerter", "Interface\\Icons\\INV_Sword_21", 1, 1000 },
    { "Einhandstreitkolben", "Interface\\Icons\\INV_Mace_01", 1, 1000 },
    { "Zweihandstreitkolben", "Interface\\Icons\\INV_Mace_10", 1, 1000 },
    { "Dolche", "Interface\\Icons\\INV_Weapon_ShortBlade_01", 1, 1000 },
    { "Faustwaffen", "Interface\\Icons\\INV_Weapon_Hand_01", 1, 1000 },
    { "Stäbe", "Interface\\Icons\\INV_Staff_01", 1, 1000 },
    { "Stangenwaffen", "Interface\\Icons\\INV_Spear_01", 20, 10000 },
    { "Bogen", "Interface\\Icons\\INV_Weapon_Bow_01", 1, 1000 },
    { "Armbrüste", "Interface\\Icons\\INV_Weapon_Crossbow_01", 1, 1000 },
    { "Schusswaffen", "Interface\\Icons\\INV_Weapon_Rifle_01", 1, 1000 },
    { "Wurfwaffen", "Interface\\Icons\\INV_ThrowingKnife_01", 1, 1000 },
}
local byClass = {
    WARRIOR = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
    PALADIN = { 1, 2, 3, 4, 5, 6, 10 },
    HUNTER = { 1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14 },
    ROGUE = { 1, 3, 5, 7, 8, 11, 12, 13, 14 },
    SHAMAN = { 1, 2, 5, 6, 7, 8, 9 },
    DRUID = { 5, 6, 7, 8, 9, 10 },
    PRIEST = { 5, 7, 9 },
    MAGE = { 3, 7, 9 },
    WARLOCK = { 3, 7, 9 },
}
local classStarts = {
    PALADIN = { [5] = true, [6] = true },
    ROGUE = { [7] = true, [14] = true },
    SHAMAN = { [5] = true, [9] = true },
    DRUID = { [5] = true, [9] = true },
    PRIEST = { [5] = true },
    MAGE = { [9] = true },
    WARLOCK = { [7] = true },
}

function C:GetKnowledgeTeachers()
    if not UnitClass then return {} end
    local _, class = UnitClass("player")
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    faction = faction == "Alliance" and "A" or (faction == "Horde" and "H" or nil)
    local result = {}
    for _, row in ipairs(teachers[class] or {}) do
        if not faction or row[5] == faction then
            result[#result + 1] = { name = row[1], zone = row[2], x = row[3], y = row[4], mapID = row[6],
                kind = "class", source = "catalog" }
        end
    end
    return result
end

function C:GetKnowledgeWeapons()
    if not UnitClass then return {} end
    local _, class = UnitClass("player")
    local race = UnitRace and select(2, UnitRace("player"))
    local skillLines = {}
    if GetNumSkillLines and GetSkillLineInfo then
        local ok, count = pcall(GetNumSkillLines)
        if ok then
            for index = 1, tonumber(count) or 0 do
                local infoOK, name, isHeader = pcall(GetSkillLineInfo, index)
                if infoOK and type(name) == "string" and not isHeader then
                    skillLines[name:lower()] = true
                end
            end
        end
    end
    local result = {}
    for _, index in ipairs(byClass[class] or {}) do
        local row = weapons[index]
        local starts = classStarts[class] and classStarts[class][index]
        if class == "PALADIN" and race == "Human" and (index == 3 or index == 4) then starts = true end
        local known = starts or skillLines[row[1]:lower()]
        local cost = row[4]
        if known then cost = nil end
        result[#result + 1] = { name = row[1], icon = row[2], level = row[3],
            cost = cost, status = known and "used" or "preview",
            source = "catalog" }
    end
    return result
end
