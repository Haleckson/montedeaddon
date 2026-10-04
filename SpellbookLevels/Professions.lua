SBL_Professions = {}
function SBL_Professions.Create(lists, Add, SameProf, DetectProfession, PlayerSkill)
local profKnownCache = { ids = {}, names = {}, profession = nil }

-- v2.7.0: Spellbook Levels ships a trimmed Forever copy of LibProfessionDB v1.8.0.
-- The embedded DB owns static recipe facts (spell id, required skill, reagents, crafted item).
-- Blizzard's live C_TradeSkillUI data remains the ONLY authority for whether this character
-- has learned an individual recipe.  Trainer scans can enrich cost/source data at runtime.
local PROFESSION_SKILL_LINE = {
    ["Alchemy"] = 171, ["Blacksmithing"] = 164, ["Cooking"] = 185,
    ["Enchanting"] = 333, ["Engineering"] = 202, ["First Aid"] = 129,
    ["Firstaid"] = 129, ["Fishing"] = 356, ["Leatherworking"] = 165,
    ["Mining"] = 186, ["Tailoring"] = 197,
}

local function EmbeddedProfessionDB()
    if not LibStub then return nil end
    local ok, lib = pcall(LibStub, "LibProfessionDB-1.0", true)
    if ok and lib and lib.IsReady and lib:IsReady() then return lib end
    return nil
end

local mergedProfessions, sourceTextCache = {}, {}
local professionDirty = true
local function ProfessionLookup()
    local ids, names = {}, {}
    for _, e in ipairs(lists.prof) do
        if e.recipeID then ids[e.recipeID] = e end
        if e.prof and e.name then names[e.prof:lower() .. "|" .. e.name:lower()] = e end
    end
    return ids, names
end

local function MergeEmbeddedProfession(prof)
    if mergedProfessions[prof] then return end
    local db = EmbeddedProfessionDB()
    local profID = prof and PROFESSION_SKILL_LINE[prof]
    if not (db and profID and db.GetRecipes) then return end
    local recipes = db:GetRecipes(profID)
    if type(recipes) ~= "table" then return end

    local lookupIDs, lookupNames = ProfessionLookup()
    for recipeID, rec in pairs(recipes) do
        local name = rec.name or (db.GetName and db:GetName(profID, recipeID))
        if name and name ~= "" then
            local existing = lookupIDs[recipeID] or lookupNames[prof:lower() .. "|" .. name:lower()]
            local req = tonumber(rec.requiredSkill or (db.GetRequiredSkill and db:GetRequiredSkill(profID, recipeID)))
            if existing then
                existing.recipeID = recipeID
                existing.prof = prof
                if req then existing.skill = req; existing.requirementKnown = true end
                existing.craftedItemID = existing.craftedItemID or rec.craftedItemId
                existing.recipeItemID = existing.recipeItemID or (db.GetRecipeItem and db:GetRecipeItem(recipeID)) or rec.itemId
                existing.dbSource = "SBL Forever DB"
            else
                Add("prof", {
                    name=name, prof=prof, recipeID=recipeID,
                    skill=req or 0, level=0, cost=0,
                    learned=nil, requirementKnown=req ~= nil,
                    source="Unknown", dbSource="SBL Forever DB",
                    craftedItemID=rec.craftedItemId, recipeItemID=(db.GetRecipeItem and db:GetRecipeItem(recipeID)) or rec.itemId,
                })
            end
        end
    end
    mergedProfessions[prof] = true
end

-- Match merchant inventory by teaching item ID, never by a localized recipe prefix.
-- Merchant indices cover the entire inventory, including pages not currently displayed.
local function ScanMerchant()
    local getInfo = (C_MerchantFrame and C_MerchantFrame.GetItemInfo) or GetMerchantItemInfo
    if not (GetMerchantNumItems and getInfo) then return end
    local db = EmbeddedProfessionDB()
    if not db then return end
    local inventory = {}
    for i = 1, GetMerchantNumItems() do
        local itemID = GetMerchantItemID and GetMerchantItemID(i)
        if not itemID and GetMerchantItemLink then
            local link = GetMerchantItemLink(i)
            itemID = link and tonumber(link:match("item:(%d+)"))
        end
        if itemID then
            local name, icon, price, quantity = getInfo(i)
            -- Newer clients return a structure; Forever may use the tuple API.
            if type(name) == "table" then
                local info = name
                name, icon, price, quantity = info.name, info.texture, info.price, info.stackCount
            end
            inventory[itemID] = { icon=icon, cost=(price or 0) / math.max(quantity or 1, 1) }
        end
    end
    local vendor = UnitName("npc")
    if not vendor then return end
    local zone = GetZoneText and GetZoneText()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local point = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y
    if point then x, y = point:GetXY() end
    for prof, profID in pairs(PROFESSION_SKILL_LINE) do
        if prof ~= "Firstaid" then
            local recipes = db:GetRecipes(profID) or {}
            local found = false
            for recipeID, rec in pairs(recipes) do
                local itemID = (db.GetRecipeItem and db:GetRecipeItem(recipeID)) or rec.itemId
                if itemID and inventory[itemID] then found = true; break end
            end
            if found then
                MergeEmbeddedProfession(prof)
                for _, e in ipairs(lists.prof) do
                    local item = SameProf(e.prof, prof) and inventory[e.recipeItemID]
                    if item then
                        e.source, e.sourceName, e.sourceZone = "Vendor", vendor, zone
                        e.sourceMapID, e.sourceX, e.sourceY = mapID, x and x * 100, y and y * 100
                        e.cost = item.cost
                        -- The scroll icon is not the crafted spell icon.
                    end
                end
            end
        end
    end
end

local function RefreshProfessionCatalog()
    local ids, names = {}, {}
    local prof = DetectProfession()
    if not professionDirty and profKnownCache.profession == prof then return profKnownCache end
    local hasSkill = prof and PlayerSkill(prof)
    if hasSkill then MergeEmbeddedProfession(prof) end
    local lookupIDs, lookupNames = ProfessionLookup()

    pcall(function()
        local C = C_TradeSkillUI
        if not (C and C.GetAllRecipeIDs and C.GetRecipeInfo) then return end

        -- GetAllRecipeIDs is the catalog.  It MUST NOT be interpreted as a learned list.
        -- For the currently open profession, GetRecipeInfo(recipeID).learned is authoritative.
        local all = C.GetAllRecipeIDs() or {}
        for _, recipeID in ipairs(all) do
            local info = C.GetRecipeInfo(recipeID)
            if info and info.name then
                local learned = info.learned and true or false
                if learned then ids[recipeID] = true; names[info.name:lower()] = true end

                local sourceText
                if C.GetRecipeSourceText and sourceTextCache[recipeID] == nil then
                    local ok, value = pcall(C.GetRecipeSourceText, recipeID)
                    if ok then sourceTextCache[recipeID] = (type(value) == "string" and value ~= "") and value or false end
                end

                sourceText = sourceTextCache[recipeID] or nil
                if hasSkill then
                    local existing = lookupIDs[recipeID] or lookupNames[prof:lower() .. "|" .. info.name:lower()]
                    if existing then
                        existing.recipeID = recipeID
                        existing.icon = existing.icon or info.icon
                        -- Always replace stale saved learned state with Blizzard's live per-recipe flag.
                        existing.learned = learned and true or nil
                        if sourceText then
                            if existing.source ~= "Trainer" and existing.source ~= "Vendor" then
                                existing.source = "Source"
                                existing.sourceName = sourceText
                            end
                        end
                    else
                        Add("prof", { name=info.name, prof=prof, recipeID=recipeID, icon=info.icon,
                            learned=learned and true or nil, skill=0, level=0,
                            source=sourceText and "Source" or "Unknown", sourceName=sourceText,
                            requirementKnown=false })
                    end
                end
            end
        end
    end)
    professionDirty = false
    profKnownCache = { ids=ids, names=names, profession=prof }
    return profKnownCache
end

local function KnownProfessionRecipes()
    return RefreshProfessionCatalog()
end

local PROFESSION_RANK_CAP = { apprentice=75, journeyman=150, expert=225, artisan=300 }
local function ProfessionUpgradeCap(e)
    if not e.prof or not e.name then return end
    local function compact(text) return (text or ""):lower():gsub("[%s%p]", "") end
    local name, prof, rank = compact(e.name), compact(e.prof), compact(e.rank)
    for title, cap in pairs(PROFESSION_RANK_CAP) do
        -- Match profession training rows, never recipes containing rank words.
        if (name == prof and rank == title) or name == title .. prof or
            name == prof .. title or name == title then return cap end
    end
end

local function PlayerProfessionCap(prof)
    local result
    pcall(function()
        if GetProfessions and GetProfessionInfo then
            local professions = { GetProfessions() }
            for _, idx in pairs(professions) do
                local name, _, _, maximum = GetProfessionInfo(idx)
                if SameProf(name, prof) and type(maximum) == "number" then result=maximum; return end
            end
        end
        if GetNumSkillLines and GetSkillLineInfo then
            for i=1,GetNumSkillLines() do
                local name, header, _, _, _, _, maximum = GetSkillLineInfo(i)
                if not header and SameProf(name,prof) and type(maximum)=="number" then result=maximum; return end
            end
        end
        if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
            local info=C_TradeSkillUI.GetBaseProfessionInfo()
            if info and SameProf(info.parentProfessionName or info.professionName,prof) then
                result=tonumber(info.maxSkillLevel)
            end
        end
    end)
    return result
end

local function ProfState(e, ctx)
    local upgrade = ProfessionUpgradeCap(e)
    if upgrade then
        ctx.profCaps = ctx.profCaps or {}
        if ctx.profCaps[e.prof] == nil then ctx.profCaps[e.prof] = PlayerProfessionCap(e.prof) or false end
        local cap = ctx.profCaps[e.prof]
        if cap and cap >= upgrade then return "learned" end
        if not cap and e.learned then return "learned" end
    elseif e.learned then return "learned" end
    if ctx.profKnown == nil then ctx.profKnown = KnownProfessionRecipes() end
    if not upgrade then
        if e.recipeID and ctx.profKnown.ids and ctx.profKnown.ids[e.recipeID] then return "learned" end
        if e.name and ctx.profKnown.names and ctx.profKnown.names[e.name:lower()] then return "learned" end
    end
    -- Requirement and acquisition source are independent facts.  If the embedded
    -- Forever DB knows the required skill, classify by that requirement even when
    -- trainer/vendor/quest/drop source is not yet known.  Source discovery only enriches
    -- the row; it is never a prerequisite for Available Now / Not Yet Available.
    if e.requirementKnown == false then return "unknown" end
    if ctx.skills[e.prof] == nil then ctx.skills[e.prof] = PlayerSkill(e.prof) or false end
    local cur = ctx.skills[e.prof]
    local charLvl = e.level or 0
    if cur and cur >= (e.skill or 0) and (charLvl == 0 or ctx.myLevel >= charLvl) then return "avail" end
    return "notyet"
end
local function ProfReq(e)
    if e.requirementKnown == false then
        if e.sourceName and e.sourceName ~= "" then return "Unknown · " .. e.sourceName end
        return "Unknown"
    end
    local s = "Skill " .. (e.skill or 0)
    if (e.level or 0) > 0 then s = s .. "  \194\183  Lvl " .. e.level end
    return s
end


local function Invalidate() professionDirty = true end
return KnownProfessionRecipes, ScanMerchant, ProfState, ProfReq, Invalidate
end
