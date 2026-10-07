--[[
  Forever Companion - Discovery/GatheringDiscovery.lua
  Professions and world containers, told apart by the spell that opened them
  and by what they give:

    gathering nodes   herbs, ore, fishing spots: one "profession" entry per
                      node name and zone, collecting up to 40 spots
    treasure          chests and caches (loot made only of quest items is
                      ignored)
    recipes learned   new recipes the character learns

  The last spell cast on a target (UNIT_SPELLCAST_SENT) tells the node or
  chest name and whether it was a gathering action. Some clients cast no
  gathering spell the addon can see, so the loot decides as well: a world
  object that gives only herbs, or only ore, stone and gems, is a gathering
  node. Objects once found to be nodes are remembered and never become
  treasure; treasure entries filed for them by mistake are withdrawn.
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local L = FC.L
local C = FC.C
local Categories = FC.Categories

local Gathering = {}
FC.GatheringDiscovery = Gathering

-- Spell IDs of gathering actions across client generations; resolved to
-- localized names at login, with English names as a fallback.
local GATHER_SPELLS = {
    herbalism = { 2366, 2368, 3570, 11993, 28695, 50300, 74519, 110413, 158745, 195114, 265819, 366252 },
    mining = { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161, 158754, 195122, 265837, 366260 },
    fishing = { 7620, 7731, 7732, 18248, 33095, 51294, 88868, 110410, 131474, 131490 },
    skinning = { 8613, 8617, 8618, 10768, 32678, 50305, 74522, 102216, 158756, 194174, 265855 },
}
local FALLBACK_NAMES = { herbalism = "Herb Gathering", mining = "Mining", fishing = "Fishing", skinning = "Skinning" }

function Gathering:BuildSpellNames()
    self.byName = {}
    for profession, ids in pairs(GATHER_SPELLS) do
        self.byName[FALLBACK_NAMES[profession]] = profession
        for _, id in ipairs(ids) do
            local name = Compat.GetSpellName(id)
            if name then self.byName[name] = profession end
        end
    end
end

--- The cast is still the one that opens the loot when it ends later than
--- the gathering window after it started (long casts).
function Gathering:OnSpellSucceeded(unit, spellID)
    local cast = self.lastCast
    if unit ~= "player" or not cast then return end
    spellID = Compat.Safe(spellID)
    if cast.spellID and spellID == cast.spellID then cast.time = GetTime() end
end

function Gathering:OnSpellSent(unit, target, spellID)
    if unit ~= "player" then return end
    target, spellID = Compat.Safe(target), Compat.Safe(spellID)
    local name = Compat.GetSpellName(spellID)
    if not self.byName then self:BuildSpellNames() end
    self.lastCast = {
        time = GetTime(),
        spellID = type(spellID) == "number" and spellID or nil,
        target = type(target) == "string" and target ~= "" and target or nil,
        profession = name and self.byName[name] or nil,
    }
end

function Gathering:RecentCast()
    local cast = self.lastCast
    if cast and GetTime() - cast.time <= C.DISCOVERY.GATHER_WINDOW then return cast end
    return nil
end

------------------------------------------------------------------------
-- Loot from world objects
------------------------------------------------------------------------

local function objectSource(items)
    for _, item in ipairs(items) do
        for _, source in ipairs(item.sources) do
            if source.guidType == "GameObject" and source.id then return source.id end
        end
    end
    return nil
end

-- What a loot item says about where it came from: Trade Goods (class 7)
-- herbs (subclass 9) come from herbs, metal and stone (subclass 7) from ore
-- veins, and gems (class 3, or trade goods subclass 4) come with ore.
local TRADE_GOODS, GEMS = 7, 3
local function gatheredKind(itemID)
    local info = itemID and Compat.GetItemInfoInstant(itemID)
    if not info then return nil end
    if info.classID == TRADE_GOODS and info.subClassID == 9 then return "herbalism" end
    if info.classID == TRADE_GOODS and info.subClassID == 7 then return "mining" end
    if info.classID == GEMS or (info.classID == TRADE_GOODS and info.subClassID == 4) then return "gem" end
    return nil
end

--- The profession behind a loot, from the items alone: only herbs, or only
--- ore, stone and gems. Anything else (a potion, a coin purse, gear) is what
--- a chest holds. Returns the profession and the name of its first item.
function Gathering.LootProfession(items)
    local profession, name
    for _, item in ipairs(items) do
        if not item.isQuestItem then
            local kind = gatheredKind(item.itemID)
            if not kind then return nil end
            if kind ~= "gem" then
                if profession and profession ~= kind then return nil end
                profession = kind
                name = name or item.name
            end
        end
    end
    return profession, name
end

local function onlyQuestItems(items)
    if #items == 0 then return false end
    for _, item in ipairs(items) do
        if not item.isQuestItem then return false end
    end
    return true
end

function Gathering:RecordNode(profession, name, fields)
    if not FC.Config:Get("discovery.gathering") or profession == "skinning" then return end
    if not fields.m or not fields.x then return end
    local id = "gather:" .. profession .. ":" .. U.NormalizeTitle(name) .. ":" .. fields.m
    local point = U.PackPoint(fields.x, fields.y)
    local existing = FC.Store:Get(id)
    if existing then
        FC.Store:AddToSet(id, "pts", point, "local")
        FC.Store:Encounter(existing)
        return
    end
    local node = U.CopyTable(fields)
    node.t = "profession"
    node.n = name
    node.pr = profession
    node.pts = { point }
    node.d = string.format(L.AUTO_GATHER, L[Categories:Profession(profession).label], fields.z or L.UNKNOWN_ZONE)
    node.tg = { "gathering", profession }
    node.ic = Categories:Profession(profession).icon
    Engine:Record(node, { id = id })
end

function Gathering:RecordTreasure(objectID, name, fields)
    if not FC.Config:Get("discovery.objects") then return end
    local treasure = U.CopyTable(fields)
    treasure.t = "treasure"
    treasure.n = name or L.AUTO_OBJECT_TITLE
    treasure.ic = Categories:Get("treasure").icon
    local id = Engine:ObjectId("u:obj:" .. objectID .. ":" .. (fields.m or 0) .. ":", fields.m, fields.x, fields.y)
    local rec, isNew = Engine:Record(treasure, { id = id })
    if rec and isNew and not fields.pa then FC.WorldDiscovery:RecordRoute(rec) end
end

--- A world object turned out to be a gathering node: remember it, and take
--- back the treasure entries filed for it by mistake (your untouched ones
--- are withdrawn, a guild member's copies are hidden here).
function Gathering:LearnNode(objectID, profession)
    local known = FC.db.gatherObjects
    if known[objectID] == profession then return end
    local first = known[objectID] == nil
    known[objectID] = profession
    if first then self:ForgetTreasure(objectID) end
end

function Gathering:ForgetTreasure(objectID)
    local store = FC.Store
    local prefix = "u:obj:" .. objectID .. ":"
    local ids = {}
    for id, rec in pairs(store.records) do
        if not rec.del and rec.t == "treasure" and id:sub(1, #prefix) == prefix then ids[#ids + 1] = id end
    end
    for _, id in ipairs(ids) do
        local rec = store:Get(id)
        local state = store.state[id]
        local gone = false
        if rec and store:IsMine(rec) then
            if not (state and (state.fav or state.note or state.tags)) then gone = store:Withdraw(id) end
        elseif rec then
            gone = store:DeletePersonal(id) ~= nil
        end
        -- the route that led to it goes too ("Route to Unknown container")
        if gone then FC.WorldDiscovery:ForgetRoute(id) end
    end
    return #ids
end

function Gathering:OnLoot()
    local items = Compat.GetLootItems()
    local objectID = objectSource(items)
    -- a catch: fishing is channeled, so its cast is long over when the
    -- bobber is looted, and fish are no herbs or ore; the game says it is one
    local fishing = Compat.IsFishingLoot() == true
    if not objectID and not fishing then return end
    local cast = self:RecentCast()
    local fields = Engine:LocationFields()
    local lootProfession, lootName = Gathering.LootProfession(items)
    local remembered = objectID and FC.db.gatherObjects[objectID]
    local profession = (fishing and "fishing") or (cast and cast.profession) or lootProfession or (remembered ~= "node" and remembered) or nil
    if profession then
        if objectID then self:LearnNode(objectID, profession) end
        FC.Bus:Emit("GATHERED", profession)
        local name = cast and cast.profession and cast.target
            or (profession == "fishing" and L.AUTO_FISHING_SPOT) or lootName or (items[1] and items[1].name)
        if name then self:RecordNode(profession, name, fields) end
        return
    end
    -- a node whose profession the addon could not tell this time is still no treasure
    if remembered or onlyQuestItems(items) then return end
    self:RecordTreasure(objectID, cast and cast.target, fields)
end

Engine:RegisterDetector("world-loot", {
    setting = function() return FC.Config:Get("discovery.objects") or FC.Config:Get("discovery.gathering") end,
    events = {
        UNIT_SPELLCAST_SENT = function(_, _, unit, target, _, spellID)
            Gathering:OnSpellSent(unit, target, spellID)
        end,
        UNIT_SPELLCAST_SUCCEEDED = function(_, _, unit, _, spellID)
            Gathering:OnSpellSucceeded(unit, spellID)
        end,
        LOOT_OPENED = function() Gathering:OnLoot() end,
    },
})

------------------------------------------------------------------------
-- Recipes learned
------------------------------------------------------------------------

Engine:RegisterDetector("recipes-learned", {
    setting = "discovery.recipesLearned",
    events = {
        NEW_RECIPE_LEARNED = function(_, _, recipeID)
            recipeID = Compat.Safe(recipeID)
            if type(recipeID) ~= "number" then return end
            local name = Compat.GetSpellName(recipeID)
            if not name then return end
            local fields = Engine:LocationFields()
            fields.t = "profession"
            fields.n = string.format(L.AUTO_LEARNED_TITLE, name)
            fields.d = string.format(L.AUTO_LEARNED, fields.z or L.UNKNOWN_ZONE)
            fields.v = "p"
            fields.tg = { "learned" }
            fields.ic = "Interface\\Icons\\INV_Scroll_05"
            Engine:Record(fields, { id = "learned:" .. recipeID })
        end,
    },
})
