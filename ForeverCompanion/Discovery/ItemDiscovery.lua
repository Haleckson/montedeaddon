--[[
  Forever Companion - Discovery/ItemDiscovery.lua
  Loot from creatures:

    * unusual items at or above the configured quality become item discoveries
    * looted recipes become recipe discoveries (with profession and skill)
    * every item a creature drops is added to its bestiary / rare entry, so
      the journal builds loot tables as you play

  World containers and gathering nodes are handled by GatheringDiscovery.
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local Categories = FC.Categories

local CREATURE_TYPES = { "rare", "creature", "boss", "npc" }

local function creatureRecord(npcID)
    for _, t in ipairs(CREATURE_TYPES) do
        local rec = FC.Store:Get(t .. ":" .. npcID)
        if rec then return rec end
    end
    return nil
end

local function sourceOf(sources)
    for _, source in ipairs(sources) do
        if (source.guidType == "Creature" or source.guidType == "Vehicle") and source.id then
            local rec = creatureRecord(source.id)
            if rec then return rec.n, rec.id, source.id end
            return nil, nil, source.id
        end
    end
    -- the loot names where it comes from, and it is no creature (a chest, a
    -- herb, a fishing bobber, a lockbox): a corpse that happens to be
    -- targeted did not drop it
    if #sources > 0 then return nil end
    local target = Compat.GetLootCreatureFallback()
    if target and target.name then
        local rec = target.npcID and creatureRecord(target.npcID)
        return target.name, rec and rec.id, target.npcID
    end
    return nil
end

local function onLoot()
    local minQuality = FC.Config:Get("discovery.lootQuality") or 3
    local wantItems = FC.Config:Get("discovery.loot")
    local wantRecipes = FC.Config:Get("discovery.recipes")
    local wantDrops = FC.Config:Get("discovery.creatures")
    local items = Compat.GetLootItems()
    if #items == 0 then return end

    local base = Engine:LocationFields()
    for _, item in ipairs(items) do
        local instant = Compat.GetItemInfoInstant(item.itemID) or {}
        local isRecipe = instant.classID == Compat.ITEM_CLASS_RECIPE
        local sourceName, parentID = sourceOf(item.sources)
        if parentID and wantDrops then
            FC.Store:AddToSet(parentID, "dr", item.itemID, "local")
        end
        if (isRecipe and wantRecipes) or (wantItems and ((item.quality or 0) >= minQuality or FC.SecretCatalog.items[item.itemID])) then
            local fields = U.CopyTable(base)
            fields.t = isRecipe and "recipe" or "item"
            fields.n = item.name
            fields.it = item.itemID
            fields.iq = item.quality
            fields.ic = item.icon or instant.icon
            fields.src = sourceName
            fields.pa = parentID or base.pa
            if isRecipe then
                fields.pr = Categories:ProfessionFromSubclass(instant.subClassID)
                local profession, skill = FC.VendorDiscovery:RecipeRequirement(item.itemID)
                fields.pr = profession or fields.pr
                fields.sk = skill
            end
            if fields.n then Engine:Record(fields) end
        end
    end
end

Engine:RegisterDetector("loot", {
    setting = function()
        return FC.Config:Get("discovery.loot") or FC.Config:Get("discovery.recipes") or FC.Config:Get("discovery.creatures")
    end,
    events = {
        LOOT_OPENED = function() onLoot() end,
    },
})

-- Hidden rewards can be common quality and arrive from an emote or a quest,
-- without LOOT_OPENED. Recover only catalogued items actually in the bags.
-- Possession does not prove where or when they were acquired: no map pin.
local function scanSecretItems()
    if not FC.Config:Get("discovery.loot") then return end
    local countItem = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
    if not countItem then return end
    for itemID in pairs(FC.SecretCatalog.items) do
        local count = Compat.SafeCall(countItem, itemID, false)
        if type(count) == "number" and count > 0 then
            local existing = FC.Store:Get("item:" .. itemID)
            if not existing or not FC.Store:IsFoundBy(existing) then
                local info = Compat.GetItemInfo(itemID)
                if info and info.name then
                    Engine:Record({ t="item", it=itemID, n=info.name, iq=info.quality,
                        ic=info.icon, rcv=true, v="p" })
                end
            end
        end
    end
end
Engine:RegisterDetector("secret-items", {
    setting = "discovery.loot",
    events = {
        BAG_UPDATE_DELAYED = function() U.Debounce("secret-items", .5, scanSecretItems) end,
        GET_ITEM_INFO_RECEIVED = function(_, _, id, success)
            id = Compat.Safe(id)
            if Compat.Safe(success) and FC.SecretCatalog.items[id] then
                U.Debounce("secret-items", .5, scanSecretItems)
            end
        end,
        PLAYER_ENTERING_WORLD = function() U.Debounce("secret-items", 2, scanSecretItems) end,
    },
})
