local C = _G.Chronicle

-- Artwork by Santiago Reyes, Atlas de Azeroth: Forever. Used with permission.
local creatorMaps = {
    ["Hall of Thanes"] = "3065",
    ["Ruins of Lordaeron"] = "2999",
}

local raidMaps = {
    ["Molten Core"] = { { "232" } },
    ["Onyxia's Lair"] = { { "248" } },
    ["Zul'Gurub"] = { { "233" } },
    ["Blackwing Lair"] = {
        { "287", "Dragonmaw Garrison" }, { "288", "Halls of Strife" },
        { "289", "Crimson Laboratories" }, { "290", "Nefarian's Lair" },
    },
    ["Ruins of Ahn'Qiraj"] = { { "247" } },
    ["Ahn'Qiraj Temple"] = {
        { "319", "The Hive Undergrounds" }, { "320", "The Temple Gates" },
        { "321", "Vault of C'Thun" },
    },
    ["Naxxramas"] = {
        { "162", "The Construct Quarter" }, { "163", "The Arachnid Quarter" },
        { "164", "The Military Quarter" }, { "165", "The Plague Quarter" },
        { "166", "The Lower Necropolis" }, { "167", "The Upper Necropolis" },
    },
}

-- Client UiMapIDs. Chronicle draws its own overview when a client floor is absent.
local floors = {
    ["Hall of Thanes"] = {3065}, ["Ruins of Lordaeron"] = {2999},
    ["Ragefire Chasm"] = {213}, ["The Deadmines"] = {291, 292},
    ["Wailing Caverns"] = {279}, ["Shadowfang Keep"] = {310, 311, 316, 312, 313, 314, 315},
    ["Stormwind Stockade"] = {225}, ["Blackfathom Deeps"] = {221, 222, 223},
    ["Gnomeregan"] = {226, 227, 228, 229}, ["Razorfen Kraul"] = {301},
    ["Scarlet Monastery: Graveyard"] = {302}, ["Scarlet Monastery: Library"] = {303},
    ["Scarlet Monastery: Armory"] = {304}, ["Scarlet Monastery: Cathedral"] = {305},
    ["Razorfen Downs"] = {300}, ["Uldaman"] = {230, 231},
    ["Zul'Farrak"] = {219}, ["Maraudon"] = {280, 281},
    ["Sunken Temple"] = {220}, ["Blackrock Depths"] = {242, 243},
    ["Blackrock Spire"] = {250, 251, 252, 253, 254, 255},
    ["Dire Maul"] = {234, 235, 236, 237, 238, 239, 240},
    ["Scholomance"] = {306, 307, 308, 309}, ["Stratholme"] = {317, 318},
}

local aliases = { ["Hall of Thanes"] = "The Hall of Thanes",
    ["The Deadmines"] = "The Deadmines",
    ["Stormwind Stockade"] = "The Stockade" }

function C:GetAzerothCompendiumInstance(name)
    local wanted = (aliases[name] or name):lower()
    for id, instance in pairs(self.azerothInstanceRefs or {}) do
        if instance.name and instance.name:lower() == wanted then
            return instance, id
        end
    end
end

function C:GetAzerothBossDisplayID(instanceName, bossName)
    local instance = self:GetAzerothCompendiumInstance(instanceName)
    if not instance or not bossName then return nil end
    for name, displayID in pairs(instance.bosses or {}) do
        if name:lower() == bossName:lower() then
            return displayID
        end
    end
end

function C:GetDungeonMapFloors(name)
    local raid = raidMaps[name]
    if raid then
        local result = {}
        for index, map in ipairs(raid) do
            local info
            if C_Map and C_Map.GetMapInfo then
                local ok, value = pcall(C_Map.GetMapInfo, tonumber(map[1]))
                if ok then info = value end
            end
            result[index] = { name = (info and info.name) or map[2] or name,
                file = "Interface\\AddOns\\Chronicle\\DungeonMapArt\\" .. map[1],
                width = 1024, height = 683, fileWidth = 1024, fileHeight = 1024 }
        end
        return result
    end
    local creatorMap = creatorMaps[name]
    if creatorMap then
        return {{ name = name, file = "Interface\\AddOns\\Chronicle\\DungeonMapArt\\" .. creatorMap,
            width = 1024, height = 683, fileWidth = 1024, fileHeight = 1024 }}
    end
    local ids = floors[name]
    local result = {}
    if not ids then
        result[1] = { name = self:L("mapOverview") }
        return result
    end
    for index, id in ipairs(ids) do
        local info
        if C_Map and C_Map.GetMapInfo then
            local ok, value = pcall(C_Map.GetMapInfo, id)
            if ok then info = value end
        end
        result[#result + 1] = { id = id, name = info and info.name or
            (#ids == 1 and self:L("mapOverview") or self:L("mapFloor") .. " " .. index) }
    end
    return result
end
