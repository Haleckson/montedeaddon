-- Additional verified boss levels from local item and dungeon records.
local C = _G.Chronicle
local rows = {
    {"Blackrock Depths","Chest of The Seven",55},
    {"Blackrock Depths","Dark Coffer",55},
    {"Blackrock Depths","Verek",55},
    {"Blackrock Depths","Warder Stilgiss",56},
    {"Blackrock Depths","Watchman Doomgrip",55},
    {"Excavation Site: Wetlands","Relic Guardian",31},
    {"Excavation Site: Wetlands","Saltspine",28},
    {"Excavation Site: Wetlands","Shadetooth",29},
    {"Gnomeregan","Techbot",26},
    {"Razorfen Kraul","Razorfen Spearhide",29},
    {"Stratholme","Postmaster Malown",60},
    {"Sunken Temple","Spawn of Hakkar",51},
    {"The Deadmines","Sneed",20},
    {"The Deadmines","Sneed's Shredder",20},
    {"Uldaman","Baelog",41},
    {"Uldaman","Obsidian Sentinel",42},
    {"Uldaman","Olaf",40},
    {"Upper Blackrock Spire","General Drakkisath",62},
    {"Upper Blackrock Spire","Pyroguard Emberseer",60},
    {"Upper Blackrock Spire","The Beast",62},
    {"Upper Blackrock Spire","Warchief Rend Blackhand",62},
    {"Zul'Farrak","Sandfury Executioner",46},
}
for _, row in ipairs(rows) do
    local name, bossName, level = unpack(row)
    local instance = (C.dungeonKnowledge and C.dungeonKnowledge[name]) or
        (C.raidKnowledge and C.raidKnowledge[name])
    if instance then
        for _, boss in ipairs(instance.bosses or {}) do
            if boss.name == bossName then
                boss.level = level
                C.bossMetadata[name] = C.bossMetadata[name] or {}
                local old = C.bossMetadata[name][bossName]
                C.bossMetadata[name][bossName] = {level,old and old[2] or 1,old and old[3]}
                break
            end
        end
    end
end
