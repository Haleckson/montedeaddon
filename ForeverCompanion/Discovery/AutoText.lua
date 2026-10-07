--[[
  Forever Companion - Discovery/AutoText.lua
  Generated descriptions and tags, so automatic discoveries read like
  written entries without the player typing anything. Detectors may set
  their own description; AutoText only fills what is still empty.
]]

local _, FC = ...

local AutoText = {}
FC.AutoText = AutoText

local L = FC.L
local Categories = FC.Categories

local function levelText(fields)
    if not fields.lvl then return "??" end
    if fields.lvl == -1 then return "??" end
    if fields.lx and fields.lx > fields.lvl then return fields.lvl .. "-" .. fields.lx end
    return tostring(fields.lvl)
end

local function classification(cls)
    if not cls or cls == "normal" or cls == "minus" or cls == "trivial" then return "" end
    return " (" .. L["CLASS_" .. cls] .. ")"
end

local function where(fields)
    return fields.sz and fields.sz ~= fields.z and (fields.sz .. ", " .. (fields.z or "?")) or (fields.z or L.UNKNOWN_ZONE)
end

local function professionName(key)
    return key and L[Categories:Profession(key).label] or nil
end

--- Summary line for a vendor inventory.
function AutoText:VendorSummary(inventory)
    local recipes, limited = 0, 0
    for _, item in ipairs(inventory or {}) do
        if item.rc then recipes = recipes + 1 end
        if item.l then limited = limited + 1 end
    end
    local text = string.format(L.AUTO_VENDOR, #(inventory or {}))
    if recipes > 0 then text = text .. " " .. string.format(L.AUTO_VENDOR_RECIPES, recipes) end
    if limited > 0 then text = text .. " " .. string.format(L.AUTO_VENDOR_LIMITED, limited) end
    return text, recipes, limited
end

local DESCRIBE = {
    rare = function(f)
        return string.format(L.AUTO_RARE, levelText(f), L["CLASS_" .. (f.cls or "rare")], where(f)), { "rare-spawn", f.cls == "rareelite" and "elite" or nil }
    end,
    creature = function(f)
        return string.format(L.AUTO_CREATURE, levelText(f), f.ct or L.CAT_CREATURE, classification(f.cls), where(f)), { f.ct and f.ct:lower() or nil, (f.cls == "elite") and "elite" or nil }
    end,
    npc = function(f)
        return string.format(L.AUTO_NPC, where(f)), { f.cls == "worldboss" and "world-boss" or nil }
    end,
    vendor = function(f)
        local text, recipes, limited = AutoText:VendorSummary(f.inv)
        return text, { recipes > 0 and "recipes" or nil, limited > 0 and "limited-stock" or nil }
    end,
    trainer = function(f)
        return string.format(L.AUTO_TRAINER, where(f)), { "trainer", f.pr }
    end,
    travel = function(f)
        return string.format(L.AUTO_TRAVEL, where(f)), { "flight-master" }
    end,
    recipe = function(f)
        local prof = professionName(f.pr) or L.PROF_OTHER
        local text = f.sk and string.format(L.AUTO_RECIPE_SKILL, prof, f.sk) or string.format(L.AUTO_RECIPE, prof)
        if f.src then text = text .. " " .. string.format(L.SOURCE_FORMAT, f.src) .. "." end
        return text, { "recipe", f.pr }
    end,
    item = function(f)
        return f.src and string.format(L.AUTO_ITEM_SOURCE, f.src, where(f)) or string.format(L.AUTO_ITEM, where(f)), { "loot" }
    end,
    quest = function(f)
        return f.gv and string.format(L.AUTO_QUEST_GIVER, f.gv, where(f)) or string.format(L.AUTO_QUEST, where(f)), { "quest" }
    end,
    treasure = function(f)
        return string.format(L.AUTO_TREASURE, where(f)), { "treasure" }
    end,
    object = function(f)
        return string.format(L.AUTO_OBJECT, where(f)), { "interactive" }
    end,
    secret = function(f)
        return string.format(L.AUTO_SECRET, where(f)), { "secret" }
    end,
    cave = function(f)
        return string.format(L.AUTO_CAVE, where(f)), { "cave" }
    end,
    landmark = function(f)
        return string.format(L.AUTO_LANDMARK, f.z or L.UNKNOWN_ZONE), { "explored" }
    end,
    dungeon = function(f)
        return f.z and string.format(L.AUTO_DUNGEON_IN, f.z) or L.AUTO_DUNGEON, { "dungeon" }
    end,
    entrance = function(f)
        return string.format(L.AUTO_ENTRANCE, f.inn or "?", where(f)), { "entrance" }
    end,
    boss = function(f)
        return string.format(L.AUTO_BOSS, f.inn or where(f)), { "boss" }
    end,
    room = function(f)
        return string.format(L.AUTO_ROOM, f.inn or "?"), { "dungeon-area" }
    end,
}

--- Fills description and tags of automatic discoveries in place.
function AutoText:Enrich(fields)
    if not FC.Config:Get("discovery.autoText") then return fields end
    local describe = DESCRIBE[fields.t]
    if not describe then return fields end
    local ok, text, tags = pcall(describe, fields)
    if not ok then return fields end
    if not fields.d and text then fields.d = text end
    if not fields.tg and tags then
        local clean = {}
        for i = 1, 4 do
            if tags[i] then clean[#clean + 1] = tags[i] end
        end
        if #clean > 0 then fields.tg = clean end
    end
    return fields
end

AutoText.LevelText = levelText
